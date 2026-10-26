/**
 * InspectorController.cls
 * Includes saved query persistence via SOQL_Saved_Query__c custom object.
 */
public with sharing class InspectorController {

    private static Map<String, Schema.SObjectType> gd;
    private static Map<String, Schema.SObjectType> globalDescribe() {
        if (gd == null) gd = Schema.getGlobalDescribe();
        return gd;
    }

    // ─────────────────────────────────────────────────────────────────
    //  SAVED QUERY METHODS
    // ─────────────────────────────────────────────────────────────────

    @AuraEnabled
    public static void saveQuery(String queryText, String queryName) {
        if (String.isBlank(queryText)) return;
        String userId = UserInfo.getUserId();
        String nameToSave = String.isBlank(queryName)
            ? queryText.abbreviate(80)
            : queryName;

        // Long Text Area fields cannot be used in WHERE clause filters.
        // So we fetch all saved queries for the user and do duplicate
        // detection in Apex by comparing Query_Text__c in memory.
        List<SOQL_Saved_Query__c> allExisting = [
            SELECT Id, Name, Query_Text__c, Run_Count__c, Last_Run__c
            FROM SOQL_Saved_Query__c
            WHERE Owner_User__c = :userId
            ORDER BY Last_Run__c DESC
        ];

        SOQL_Saved_Query__c matchRec = null;
        for (SOQL_Saved_Query__c rec : allExisting) {
            if (rec.Query_Text__c == queryText) { matchRec = rec; break; }
        }

        if (matchRec != null) {
            matchRec.Run_Count__c = (matchRec.Run_Count__c == null ? 1 : matchRec.Run_Count__c) + 1;
            matchRec.Last_Run__c  = System.now();
            matchRec.Name         = nameToSave;
            update matchRec;
        } else {
            insert new SOQL_Saved_Query__c(
                Name           = nameToSave,
                Query_Text__c  = queryText,
                Run_Count__c   = 1,
                Last_Run__c    = System.now(),
                Owner_User__c  = userId
            );
        }

        // ALWAYS enforce 20-record limit after every save (insert or update).
        // Re-query after DML to get the latest accurate order.
        List<SOQL_Saved_Query__c> allForUser = [
            SELECT Id FROM SOQL_Saved_Query__c
            WHERE Owner_User__c = :userId
            ORDER BY Last_Run__c DESC
        ];
        if (allForUser.size() > 20) {
            List<SOQL_Saved_Query__c> toDelete = new List<SOQL_Saved_Query__c>();
            for (Integer i = 20; i < allForUser.size(); i++) toDelete.add(allForUser[i]);
            delete toDelete;
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getSavedQueries() {
        String userId = UserInfo.getUserId();
        List<SOQL_Saved_Query__c> records = [
            SELECT Id, Name, Query_Text__c, Run_Count__c, Last_Run__c
            FROM SOQL_Saved_Query__c
            WHERE Owner_User__c = :userId
            ORDER BY Last_Run__c DESC
            LIMIT 20
        ];
        List<Map<String, String>> result = new List<Map<String, String>>();
        for (SOQL_Saved_Query__c rec : records) {
            result.add(new Map<String, String>{
                'id'        => rec.Id,
                'name'      => rec.Name,
                'queryText' => rec.Query_Text__c,
                'runCount'  => String.valueOf(rec.Run_Count__c == null ? 1 : rec.Run_Count__c.intValue()),
                'lastRun'   => rec.Last_Run__c == null ? '' : String.valueOf(rec.Last_Run__c)
            });
        }
        return result;
    }

    @AuraEnabled
    public static void deleteSavedQuery(String recordId) {
        if (String.isBlank(recordId)) return;
        List<SOQL_Saved_Query__c> toDelete = [
            SELECT Id FROM SOQL_Saved_Query__c
            WHERE Id = :recordId AND Owner_User__c = :UserInfo.getUserId() LIMIT 1
        ];
        if (!toDelete.isEmpty()) delete toDelete;
    }

    // ─────────────────────────────────────────────────────────────────
    //  GET SUGGESTIONS
    // ─────────────────────────────────────────────────────────────────

    @AuraEnabled
    public static List<Map<String, String>> getSuggestions(String query, Integer cursorPosition) {
        if (String.isBlank(query)) return new List<Map<String, String>>();

        Integer safePos = (cursorPosition != null && cursorPosition <= query.length())
                          ? cursorPosition : query.length();

        Integer tokenStart = safePos;
        while (tokenStart > 0) {
            String ch = query.substring(tokenStart - 1, tokenStart);
            if (ch == ' ' || ch == ',' || ch == '\n' || ch == '\t') break;
            tokenStart--;
        }
        String activeToken = query.substring(tokenStart, safePos).trim();

        SubqueryContext ctx = getSubqueryContext(query, safePos);
        Boolean inSubquery  = (ctx != null);

        String textToCursor;
        if (inSubquery) {
            Integer relCursor = Math.min(safePos - ctx.startIdx, ctx.subqueryText.length());
            textToCursor = ctx.subqueryText.substring(0, relCursor);
        } else {
            textToCursor = query.substring(0, safePos);
        }
        String clause = detectClause(textToCursor.toUpperCase());

        if (clause == 'FROM') {
            if (inSubquery) return searchChildRelationships(ctx.parentObjName, activeToken);
            return searchObjects(activeToken);
        }

        if (clause == 'SELECT' || clause == 'WHERE' || clause == 'HAVING'
                || clause == 'ORDER BY' || clause == 'GROUP BY') {
            String obj = inSubquery ? ctx.childObjName : extractObjectName(query);
            if (String.isNotBlank(obj)) return searchFields(obj, activeToken);
            if (clause == 'SELECT') return searchObjects(activeToken);
        }

        return keywordSuggestions(activeToken);
    }

    // ─────────────────────────────────────────────────────────────────
    //  SubqueryContext
    // ─────────────────────────────────────────────────────────────────

    private class SubqueryContext {
        Integer startIdx;
        Integer endIdx;
        String  subqueryText;
        String  parentObjName;
        String  childRelName;
        String  childObjName;
    }

    private static SubqueryContext getSubqueryContext(String query, Integer cursorPos) {
        String parentObj = extractObjectName(query);
        if (String.isBlank(parentObj)) return null;

        Integer depth = 0, subStart = -1;
        for (Integer i = 0; i < query.length(); i++) {
            String ch = query.substring(i, i + 1);
            if (ch == '(') {
                depth++;
                if (depth == 1) subStart = i;
            } else if (ch == ')') {
                if (depth == 1 && subStart >= 0) {
                    if (cursorPos > subStart && cursorPos <= i) {
                        String subText = query.substring(subStart + 1, i);
                        SubqueryContext ctx = new SubqueryContext();
                        ctx.startIdx      = subStart + 1;
                        ctx.endIdx        = i;
                        ctx.subqueryText  = subText;
                        ctx.parentObjName = parentObj;
                        String childRel   = extractObjectName(subText);
                        ctx.childRelName  = childRel;
                        if (String.isNotBlank(childRel))
                            ctx.childObjName = resolveChildRelationship(parentObj, childRel);
                        return ctx;
                    }
                    subStart = -1;
                }
                depth--;
            }
        }
        return null;
    }

    private static String resolveChildRelationship(String parentObj, String relName) {
        Schema.DescribeSObjectResult parentDesc;
        try {
            List<Schema.DescribeSObjectResult> dl = Schema.describeSObjects(new List<String>{ parentObj });
            if (dl == null || dl.isEmpty()) return relName;
            parentDesc = dl[0];
        } catch (Exception e) { return relName; }
        String relLower = relName.toLowerCase();
        for (Schema.ChildRelationship cr : parentDesc.getChildRelationships()) {
            if (cr.getRelationshipName() == null) continue;
            if (cr.getRelationshipName().toLowerCase() == relLower)
                return cr.getChildSObject().getDescribe().getName();
        }
        return relName;
    }

    private static List<Map<String, String>> searchChildRelationships(String parentObj, String prefix) {
        List<Map<String, String>> res = new List<Map<String, String>>();
        String lp = prefix == null ? '' : prefix.toLowerCase();
        Schema.DescribeSObjectResult parentDesc;
        try {
            List<Schema.DescribeSObjectResult> dl = Schema.describeSObjects(new List<String>{ parentObj });
            if (dl == null || dl.isEmpty()) return res;
            parentDesc = dl[0];
        } catch (Exception e) { return res; }
        for (Schema.ChildRelationship cr : parentDesc.getChildRelationships()) {
            if (cr.getRelationshipName() == null) continue;
            if (!cr.getRelationshipName().toLowerCase().startsWith(lp)) continue;
            res.add(new Map<String, String>{
                'value'  => cr.getRelationshipName(),
                'label'  => cr.getRelationshipName(),
                'type'   => 'OBJ',
                'detail' => cr.getChildSObject().getDescribe().getName()
            });
            if (res.size() >= 20) break;
        }
        return res;
    }

    // ─────────────────────────────────────────────────────────────────
    //  RUN QUERY
    // ─────────────────────────────────────────────────────────────────

    @AuraEnabled
    public static List<Map<String, Object>> runQuery(String query) {
        if (String.isBlank(query)) throw new AuraHandledException('Query cannot be empty.');
        String up = query.trim().toUpperCase();
        if (!up.startsWith('SELECT')) throw new AuraHandledException('Only SELECT queries are permitted.');

        String safe = query.trim().removeEnd(';');
        String safeUp = safe.toUpperCase();

        if (!safeUp.contains('WITH SECURITY_ENFORCED')) {
            Integer fromPos    = lastWholeWordIdx(safeUp, 'FROM');
            Integer searchFrom = (fromPos >= 0) ? fromPos : 0;
            List<String> trailing = new List<String>{ 'GROUP BY', 'ORDER BY', 'LIMIT', 'OFFSET' };
            Integer insertAt = -1;
            for (String tc : trailing) {
                Integer relPos = lastWholeWordIdx(safeUp.substring(searchFrom), tc);
                if (relPos >= 0) {
                    Integer absPos = searchFrom + relPos;
                    if (insertAt == -1 || absPos < insertAt) insertAt = absPos;
                }
            }
            safe = (insertAt > 0)
                ? safe.substring(0, insertAt) + ' WITH SECURITY_ENFORCED ' + safe.substring(insertAt)
                : safe + ' WITH SECURITY_ENFORCED';
        }

        List<SObject> records;
        try {
            records = Database.query(safe);
        } catch (QueryException qe) {
            throw new AuraHandledException('Query error: ' + qe.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException('Unexpected error: ' + ex.getMessage());
        }

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (SObject rec : records) {
            Map<String, Object> flat = new Map<String, Object>();
            flattenSObject(rec, '', flat);
            result.add(flat);
        }
        return result;
    }

    private static void flattenSObject(SObject rec, String prefix, Map<String, Object> out) {
        Map<String, Object> asMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(rec));
        flattenMap(asMap, prefix, out);
    }

    private static void flattenMap(Map<String, Object> m, String prefix, Map<String, Object> out) {
        for (String key : m.keySet()) {
            if (key == 'attributes') continue;
            String fullKey = prefix == '' ? key : prefix + '.' + key;
            Object val = m.get(key);
            if (val instanceof Map<String, Object>) {
                flattenMap((Map<String, Object>) val, fullKey, out);
            } else {
                out.put(fullKey, val);
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────
    //  Helpers
    // ─────────────────────────────────────────────────────────────────

    private static String detectClause(String upperTextToCursor) {
        List<String> clauses = new List<String>{
            'SELECT','FROM','WHERE','ORDER BY','GROUP BY','HAVING','LIMIT','OFFSET'
        };
        String winner = 'UNKNOWN'; Integer winPos = -1;
        for (String kw : clauses) {
            Integer pos = lastWholeWordIdx(upperTextToCursor, kw);
            if (pos > winPos) { winPos = pos; winner = kw; }
        }
        return winner;
    }

    private static Integer lastWholeWordIdx(String upper, String kw) {
        Integer result = -1, search = 0, klen = kw.length();
        while (search + klen <= upper.length()) {
            Integer idx = upper.indexOf(kw, search);
            if (idx == -1) break;
            Boolean preOk  = (idx == 0) || isDelim(upper.substring(idx - 1, idx));
            Boolean postOk = (idx + klen >= upper.length())
                           || isDelim(upper.substring(idx + klen, idx + klen + 1));
            if (preOk && postOk) result = idx;
            search = idx + 1;
        }
        return result;
    }

    private static Boolean isDelim(String ch) {
        return ch == ' ' || ch == '\t' || ch == '\n' || ch == ',' || ch == '(' || ch == ')';
    }

    private static List<Map<String, String>> searchObjects(String prefix) {
        List<Map<String, String>> res = new List<Map<String, String>>();
        String lp = prefix == null ? '' : prefix.toLowerCase();
        for (String apiName : globalDescribe().keySet()) {
            if (!apiName.toLowerCase().startsWith(lp)) continue;
            Schema.DescribeSObjectResult d = globalDescribe().get(apiName).getDescribe();
            if (!d.isQueryable()) continue;
            res.add(new Map<String, String>{
                'value'=>d.getName(),'label'=>d.getName(),'type'=>'OBJ','detail'=>d.getLabel()
            });
            if (res.size() >= 15) break;
        }
        return res;
    }

    private static List<Map<String, String>> searchFields(String objectName, String prefix) {
        List<Map<String, String>> res = new List<Map<String, String>>();
        String targetObj = objectName;
        String lp = prefix == null ? '' : prefix.toLowerCase();
        Boolean inTraversal = false;

        if (prefix != null && prefix.contains('.')) {
            inTraversal = true;
            Integer dotIdx   = prefix.indexOf('.');
            String relPart   = prefix.substring(0, dotIdx);
            String childPart = prefix.substring(dotIdx + 1);
            String curObj    = objectName;
            for (String seg : relPart.split('\\.')) {
                if (String.isNotBlank(seg)) curObj = resolveRelationship(curObj, seg);
            }
            targetObj = curObj;
            lp        = childPart.toLowerCase();
        }

        Schema.DescribeSObjectResult objDesc;
        try {
            List<Schema.DescribeSObjectResult> dl = Schema.describeSObjects(new List<String>{ targetObj });
            if (dl == null || dl.isEmpty()) return res;
            objDesc = dl[0];
        } catch (Exception e) { return res; }

        Map<String, Schema.SObjectField> fieldMap = objDesc.fields.getMap();
        for (String fn : fieldMap.keySet()) {
            Schema.DescribeFieldResult f = fieldMap.get(fn).getDescribe();
            if (!f.isAccessible()) continue;
            String relName    = f.getRelationshipName();
            Boolean matchField = fn.toLowerCase().startsWith(lp);
            Boolean matchRel   = String.isNotBlank(relName) && relName.toLowerCase().startsWith(lp);
            if (!matchField && !matchRel) continue;
            if (matchRel && !inTraversal)
                res.add(new Map<String, String>{
                    'value'=>relName+'.','label'=>relName,'type'=>'OBJ',
                    'detail'=>'lookup → ' + safeResolve(targetObj, relName)
                });
            if (matchField)
                res.add(new Map<String, String>{
                    'value'=>f.getName(),'label'=>f.getName(),'type'=>'FLD',
                    'detail'=>String.valueOf(f.getType()).toLowerCase()
                });
            if (res.size() >= 25) break;
        }
        return res;
    }

    private static String resolveRelationship(String parentObj, String relToken) {
        Schema.DescribeSObjectResult parentDesc;
        try {
            List<Schema.DescribeSObjectResult> dl = Schema.describeSObjects(new List<String>{ parentObj });
            if (dl == null || dl.isEmpty()) return parentObj;
            parentDesc = dl[0];
        } catch (Exception e) { return parentObj; }
        String tokenBase = stripR(relToken.toLowerCase());
        for (Schema.SObjectField f : parentDesc.fields.getMap().values()) {
            Schema.DescribeFieldResult fd = f.getDescribe();
            String rel = fd.getRelationshipName();
            if (String.isBlank(rel)) continue;
            if (stripR(rel.toLowerCase()).equals(tokenBase)) {
                List<Schema.SObjectType> refs = fd.getReferenceTo();
                if (!refs.isEmpty()) return refs[0].getDescribe().getName();
            }
        }
        return parentObj;
    }

    private static String safeResolve(String parentObj, String relName) {
        try { return resolveRelationship(parentObj, relName); } catch (Exception e) { return '?'; }
    }

    private static String stripR(String s) {
        return s != null && s.endsWith('__r') ? s.substring(0, s.length() - 3) : s;
    }

    private static String extractObjectName(String query) {
        if (String.isBlank(query)) return null;
        Matcher m = Pattern.compile('(?i)\\bFROM\\s+(\\w+)').matcher(query);
        return m.find() ? m.group(1) : null;
    }

    private static List<Map<String, String>> keywordSuggestions(String partial) {
        List<String[]> kws = new List<String[]>{
            new String[]{'SELECT','KW',''}, new String[]{'FROM','KW',''}, new String[]{'WHERE','KW',''},
            new String[]{'ORDER BY','KW',''}, new String[]{'GROUP BY','KW',''}, new String[]{'HAVING','KW',''},
            new String[]{'LIMIT','KW',''}, new String[]{'OFFSET','KW',''}, new String[]{'AND','KW',''},
            new String[]{'OR','KW',''}, new String[]{'NOT','KW',''}, new String[]{'LIKE','KW',''},
            new String[]{'IN','KW',''}, new String[]{'NOT IN','KW',''}, new String[]{'NULL','KW',''},
            new String[]{'TRUE','KW',''}, new String[]{'FALSE','KW',''}, new String[]{'ASC','KW',''}, new String[]{'DESC','KW',''},
            new String[]{'COUNT()','FN','aggregate'}, new String[]{'COUNT(Id)','FN','aggregate'},
            new String[]{'SUM()','FN','aggregate'}, new String[]{'AVG()','FN','aggregate'},
            new String[]{'MIN()','FN','aggregate'}, new String[]{'MAX()','FN','aggregate'},
            new String[]{'COUNT_DISTINCT()','FN','aggregate'},
            new String[]{'TODAY','DATE','date literal'}, new String[]{'YESTERDAY','DATE','date literal'},
            new String[]{'THIS_MONTH','DATE','date literal'}, new String[]{'THIS_YEAR','DATE','date literal'},
            new String[]{'LAST_WEEK','DATE','date literal'}, new String[]{'LAST_MONTH','DATE','date literal'},
            new String[]{'LAST_N_DAYS:','DATE','date literal'}, new String[]{'LAST_N_MONTHS:','DATE','date literal'},
            new String[]{'WITH SECURITY_ENFORCED','KW','FLS enforcement'}
        };
        List<Map<String, String>> res = new List<Map<String, String>>();
        String lp = partial == null ? '' : partial.toLowerCase();
        for (String[] kw : kws) {
            if (kw[0].toLowerCase().startsWith(lp))
                res.add(new Map<String, String>{
                    'value'=>kw[0],'label'=>kw[0],'type'=>kw[1],'detail'=>kw[2]
                });
        }
        return res;
    }
}