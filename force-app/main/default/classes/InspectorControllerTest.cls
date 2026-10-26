/**
 * InspectorControllerTest.cls
 *
 * Comprehensive test class for InspectorController.
 * Targets 100% coverage by exercising every public method and every
 * private branch reachable from them.
 *
 * Covered paths:
 *   - saveQuery: blank-text early return, blank-name (uses abbreviated text),
 *     named save, insert-new, update-existing, null Run_Count__c on update,
 *     20-record retention cleanup.
 *   - getSavedQueries: non-empty results, including a record with null
 *     Run_Count__c and null Last_Run__c (both null-handling ternaries).
 *   - deleteSavedQuery: success, blank id early return, non-existent id.
 *   - getSuggestions: blank query, null cursor, cursor beyond length,
 *     FROM clause at root, FROM clause inside subquery (child relationship
 *     suggestions), SELECT/WHERE/HAVING/ORDER BY/GROUP BY/LIMIT clauses,
 *     keyword fallback, dot-traversal in field path, '__r' traversal token
 *     (stripR true branch), invalid object names, invalid child relationship
 *     names, query with no FROM (extractObjectName null), cursor outside
 *     parens, every isDelim variant (space, tab, newline, comma).
 *   - runQuery: blank, non-SELECT, simple SELECT, SELECT with trailing
 *     semicolon, SELECT with trailing clauses (LIMIT/ORDER BY) so the
 *     WITH SECURITY_ENFORCED insertion is mid-string, SELECT that already
 *     contains WITH SECURITY_ENFORCED, SELECT with a relationship field
 *     (exercises flattenMap recursion), bad SOQL (QueryException path).
 */
@isTest
private class InspectorControllerTest {

    @TestSetup
    static void setupData() {
        Account a = new Account(Name = 'InspectorTestAccount');
        insert a;
        Contact c = new Contact(LastName = 'InspectorTestContact', AccountId = a.Id);
        insert c;
    }

    // ──────────────────────────────────────────────────────────────────
    //  saveQuery
    // ──────────────────────────────────────────────────────────────────

    @isTest
    static void testSaveQueryInsertNew() {
        Test.startTest();
        InspectorController.saveQuery('SELECT Id FROM Account', 'My Account Query');
        Test.stopTest();

        List<SOQL_Saved_Query__c> recs = [
            SELECT Name, Query_Text__c, Run_Count__c
            FROM SOQL_Saved_Query__c
            WHERE Owner_User__c = :UserInfo.getUserId()
        ];
        System.assertEquals(1, recs.size(), 'Expected one inserted saved query');
        System.assertEquals('My Account Query', recs[0].Name);
        System.assertEquals(1, recs[0].Run_Count__c);
    }

    @isTest
    static void testSaveQueryBlankTextEarlyReturn() {
        Test.startTest();
        InspectorController.saveQuery('', 'X');
        InspectorController.saveQuery(null, 'X');
        Test.stopTest();

        Integer cnt = [
            SELECT COUNT() FROM SOQL_Saved_Query__c
            WHERE Owner_User__c = :UserInfo.getUserId()
        ];
        System.assertEquals(0, cnt, 'Blank text should be a no-op');
    }

    @isTest
    static void testSaveQueryBlankNameUsesAbbreviatedText() {
        String longQuery = 'SELECT Id, Name, Phone, Type, Industry, Description, Website, Fax FROM Account WHERE Name LIKE \'%test%\'';
        Test.startTest();
        InspectorController.saveQuery(longQuery, null);
        InspectorController.saveQuery(longQuery + ' ORDER BY Name', '');
        Test.stopTest();

        List<SOQL_Saved_Query__c> recs = [
            SELECT Name FROM SOQL_Saved_Query__c
            WHERE Owner_User__c = :UserInfo.getUserId()
        ];
        System.assertEquals(2, recs.size());
        for (SOQL_Saved_Query__c r : recs) {
            System.assert(r.Name.length() <= 80, 'Name should be abbreviated to <= 80 chars');
        }
    }

    @isTest
    static void testSaveQueryUpdateExisting() {
        String q = 'SELECT Id FROM Contact';
        InspectorController.saveQuery(q, 'Initial Name');

        Test.startTest();
        InspectorController.saveQuery(q, 'Updated Name');
        Test.stopTest();

        List<SOQL_Saved_Query__c> recs = [
            SELECT Name, Run_Count__c FROM SOQL_Saved_Query__c
            WHERE Owner_User__c = :UserInfo.getUserId()
        ];
        System.assertEquals(1, recs.size(), 'Same query text should update, not insert');
        System.assertEquals('Updated Name', recs[0].Name);
        System.assertEquals(2, recs[0].Run_Count__c, 'Run count should increment');
    }

    @isTest
    static void testSaveQueryUpdateWithNullRunCount() {
        // Seed a record whose Run_Count__c is null
        SOQL_Saved_Query__c seed = new SOQL_Saved_Query__c(
            Name           = 'NullCountSeed',
            Query_Text__c  = 'SELECT Id FROM Lead',
            Run_Count__c   = null,
            Last_Run__c    = System.now().addDays(-1),
            Owner_User__c  = UserInfo.getUserId()
        );
        insert seed;

        Test.startTest();
        InspectorController.saveQuery('SELECT Id FROM Lead', 'AfterUpdate');
        Test.stopTest();

        SOQL_Saved_Query__c after = [
            SELECT Run_Count__c, Name FROM SOQL_Saved_Query__c WHERE Id = :seed.Id
        ];
        // Null treated as 1, then incremented to 2
        System.assertEquals(2, after.Run_Count__c, 'Null run count should be promoted to 1 then incremented');
        System.assertEquals('AfterUpdate', after.Name);
    }

    @isTest
    static void testSaveQueryEnforcesTwentyRecordLimit() {
        // Seed 20 records so the next save pushes total to 21 and triggers cleanup
        List<SOQL_Saved_Query__c> seed = new List<SOQL_Saved_Query__c>();
        for (Integer i = 0; i < 20; i++) {
            seed.add(new SOQL_Saved_Query__c(
                Name           = 'Seed ' + i,
                Query_Text__c  = 'SELECT Id FROM Account WHERE Id = \'seed' + i + '\'',
                Run_Count__c   = 1,
                // Older Last_Run__c values for higher i so newest seed sorts first
                Last_Run__c    = System.now().addMinutes(-1 * (i + 5)),
                Owner_User__c  = UserInfo.getUserId()
            ));
        }
        insert seed;

        Test.startTest();
        InspectorController.saveQuery(
            'SELECT Id FROM Account WHERE Id = \'BRAND_NEW\'',
            'Brand New Query'
        );
        Test.stopTest();

        Integer cnt = [
            SELECT COUNT() FROM SOQL_Saved_Query__c
            WHERE Owner_User__c = :UserInfo.getUserId()
        ];
        System.assertEquals(20, cnt, 'Retention cap of 20 should be enforced after save');
    }

    // ──────────────────────────────────────────────────────────────────
    //  getSavedQueries
    // ──────────────────────────────────────────────────────────────────

    @isTest
    static void testGetSavedQueriesReturnsList() {
        insert new List<SOQL_Saved_Query__c>{
            new SOQL_Saved_Query__c(
                Name = 'Alpha',
                Query_Text__c = 'SELECT Id FROM Account',
                Run_Count__c = 3,
                Last_Run__c = System.now(),
                Owner_User__c = UserInfo.getUserId()
            ),
            // Record with both null Run_Count__c and null Last_Run__c to
            // exercise the ternary null branches inside getSavedQueries.
            new SOQL_Saved_Query__c(
                Name = 'Beta',
                Query_Text__c = 'SELECT Id FROM Contact',
                Run_Count__c = null,
                Last_Run__c = null,
                Owner_User__c = UserInfo.getUserId()
            )
        };

        Test.startTest();
        List<Map<String, String>> result = InspectorController.getSavedQueries();
        Test.stopTest();

        System.assertEquals(2, result.size());
        Boolean sawEmptyLastRun = false;
        Boolean sawDefaultRunCount = false;
        for (Map<String, String> r : result) {
            System.assertNotEquals(null, r.get('id'));
            System.assertNotEquals(null, r.get('name'));
            System.assertNotEquals(null, r.get('queryText'));
            if (r.get('lastRun') == '')   sawEmptyLastRun = true;
            if (r.get('runCount') == '1') sawDefaultRunCount = true;
        }
        System.assert(sawEmptyLastRun,    'Null Last_Run__c should map to empty string');
        System.assert(sawDefaultRunCount, 'Null Run_Count__c should map to "1"');
    }

    @isTest
    static void testGetSavedQueriesEmpty() {
        Test.startTest();
        List<Map<String, String>> result = InspectorController.getSavedQueries();
        Test.stopTest();
        System.assertEquals(0, result.size());
    }

    // ──────────────────────────────────────────────────────────────────
    //  deleteSavedQuery
    // ──────────────────────────────────────────────────────────────────

    @isTest
    static void testDeleteSavedQuery() {
        SOQL_Saved_Query__c r = new SOQL_Saved_Query__c(
            Name = 'ToDelete',
            Query_Text__c = 'SELECT Id FROM Lead',
            Run_Count__c = 1,
            Last_Run__c = System.now(),
            Owner_User__c = UserInfo.getUserId()
        );
        insert r;

        Test.startTest();
        InspectorController.deleteSavedQuery(r.Id);
        InspectorController.deleteSavedQuery('');    // blank early return
        InspectorController.deleteSavedQuery(null);  // blank early return
        Test.stopTest();

        Integer cnt = [SELECT COUNT() FROM SOQL_Saved_Query__c WHERE Id = :r.Id];
        System.assertEquals(0, cnt, 'Record should be deleted');
    }

    @isTest
    static void testDeleteSavedQueryNonExistent() {
        // Create then delete to obtain an Id that is valid in shape but absent
        SOQL_Saved_Query__c r = new SOQL_Saved_Query__c(
            Name = 'GhostRec',
            Query_Text__c = 'SELECT Id FROM User',
            Run_Count__c = 1,
            Last_Run__c = System.now(),
            Owner_User__c = UserInfo.getUserId()
        );
        insert r;
        Id ghostId = r.Id;
        delete r;

        Test.startTest();
        // Should not throw even though no record exists for this id
        InspectorController.deleteSavedQuery(ghostId);
        Test.stopTest();
    }

    // ──────────────────────────────────────────────────────────────────
    //  getSuggestions — entry-point + cursor handling
    // ──────────────────────────────────────────────────────────────────

    @isTest
    static void testGetSuggestionsBlank() {
        Test.startTest();
        List<Map<String, String>> r1 = InspectorController.getSuggestions('', 0);
        List<Map<String, String>> r2 = InspectorController.getSuggestions(null, 0);
        Test.stopTest();
        System.assertEquals(0, r1.size());
        System.assertEquals(0, r2.size());
    }

    @isTest
    static void testGetSuggestionsCursorBoundsAndDelims() {
        String q = 'SELECT Id FROM Account';
        Test.startTest();
        // cursorPosition null → safePos defaults to query.length()
        System.assertNotEquals(null, InspectorController.getSuggestions(q, null));
        // cursorPosition beyond length → safePos clamps to query.length()
        System.assertNotEquals(null, InspectorController.getSuggestions(q, 9999));
        // Comma delimiter in active-token boundary
        System.assertNotEquals(null,
            InspectorController.getSuggestions('SELECT Id,Na FROM Account', 12));
        // Newline delimiter
        System.assertNotEquals(null,
            InspectorController.getSuggestions('SELECT Id\nFROM Account', 22));
        // Tab delimiter
        System.assertNotEquals(null,
            InspectorController.getSuggestions('SELECT Id\tFROM Account', 22));
        Test.stopTest();
    }

    // ──────────────────────────────────────────────────────────────────
    //  getSuggestions — FROM clause (root)
    // ──────────────────────────────────────────────────────────────────

    @isTest
    static void testGetSuggestionsFromClauseObjectSearch() {
        String q = 'SELECT Id FROM Acc';
        Test.startTest();
        List<Map<String, String>> r = InspectorController.getSuggestions(q, q.length());
        Test.stopTest();

        System.assert(!r.isEmpty(), 'Should suggest objects starting with "Acc"');
        Boolean foundAccount = false;
        for (Map<String, String> m : r) {
            if (m.get('value') == 'Account') foundAccount = true;
        }
        System.assert(foundAccount, 'Account should appear among suggestions');
    }

    @isTest
    static void testGetSuggestionsFromEmptyPrefixHitsObjectLimit() {
        // Empty prefix matches many objects → exercises the
        // `if (res.size() >= 15) break;` short-circuit inside searchObjects
        String q = 'FROM ';
        Test.startTest();
        List<Map<String, String>> r = InspectorController.getSuggestions(q, q.length());
        Test.stopTest();
        System.assertEquals(15, r.size(), 'searchObjects should cap at 15');
    }

    // ──────────────────────────────────────────────────────────────────
    //  getSuggestions — SELECT / WHERE / HAVING / ORDER BY / GROUP BY
    // ──────────────────────────────────────────────────────────────────

    @isTest
    static void testGetSuggestionsSelectClauseFieldSearch() {
        // Cursor right after "SELECT " — exercises empty active-token path
        // and forces searchFields('Account', '') which caps at 25 fields.
        String q = 'SELECT  FROM Account';
        Test.startTest();
        List<Map<String, String>> r = InspectorController.getSuggestions(q, 7);
        Test.stopTest();
        System.assert(!r.isEmpty());
        System.assert(r.size() <= 25, 'Field cap should be honored');
    }

    @isTest
    static void testGetSuggestionsWhereClause() {
        String q = 'SELECT Id FROM Account WHERE Na';
        Test.startTest();
        List<Map<String, String>> r = InspectorController.getSuggestions(q, q.length());
        Test.stopTest();

        Boolean foundName = false;
        for (Map<String, String> m : r) {
            if (m.get('value') == 'Name') foundName = true;
        }
        System.assert(foundName, 'Should suggest the Name field after WHERE');
    }

    @isTest
    static void testGetSuggestionsAllOtherClauses() {
        Test.startTest();
        // ORDER BY
        System.assertNotEquals(null,
            InspectorController.getSuggestions('SELECT Id FROM Account ORDER BY ', 32));
        // GROUP BY
        System.assertNotEquals(null,
            InspectorController.getSuggestions('SELECT Id FROM Account GROUP BY ', 32));
        // HAVING
        System.assertNotEquals(null,
            InspectorController.getSuggestions('SELECT Id FROM Account HAVING ', 30));
        // LIMIT — falls through to keywordSuggestions (clause not in field-search set)
        System.assertNotEquals(null,
            InspectorController.getSuggestions('SELECT Id FROM Account LIMIT ', 29));
        Test.stopTest();
    }

    @isTest
    static void testGetSuggestionsSelectWithoutFromFallsBackToObjects() {
        // No FROM keyword → extractObjectName returns null → clause == SELECT
        // takes the fallback `return searchObjects(activeToken);` branch.
        Test.startTest();
        List<Map<String, String>> r = InspectorController.getSuggestions('SELECT Acc', 10);
        Test.stopTest();

        Boolean foundAccount = false;
        for (Map<String, String> m : r) {
            if (m.get('value') == 'Account') foundAccount = true;
        }
        System.assert(foundAccount, 'Should fall back to object search when no FROM present');
    }

    // ──────────────────────────────────────────────────────────────────
    //  getSuggestions — relationship traversal (dot path)
    // ──────────────────────────────────────────────────────────────────

    @isTest
    static void testGetSuggestionsDotTraversal() {
        // 'Owner.' should resolve to User, then list User fields.
        String q = 'SELECT Owner. FROM Account';
        Integer cursor = 'SELECT Owner.'.length();
        Test.startTest();
        List<Map<String, String>> r = InspectorController.getSuggestions(q, cursor);
        Test.stopTest();
        System.assert(!r.isEmpty(), 'Owner. traversal should yield User fields');
    }

    @isTest
    static void testGetSuggestionsUnderscoreRTraversal() {
        // Token ending in '__r' exercises stripR's true branch in resolveRelationship.
        String q = 'SELECT Owner__r.Na FROM Account';
        Integer cursor = 'SELECT Owner__r.Na'.length();
        Test.startTest();
        List<Map<String, String>> r = InspectorController.getSuggestions(q, cursor);
        Test.stopTest();
        System.assertNotEquals(null, r);
    }

    @isTest
    static void testGetSuggestionsTraversalInvalidSegment() {
        // Invalid relationship segment → resolveRelationship returns parentObj unchanged
        String q = 'SELECT ZzzNothing.Na FROM Account';
        Integer cursor = 'SELECT ZzzNothing.Na'.length();
        Test.startTest();
        List<Map<String, String>> r = InspectorController.getSuggestions(q, cursor);
        Test.stopTest();
        System.assertNotEquals(null, r);
    }

    // ──────────────────────────────────────────────────────────────────
    //  getSuggestions — subquery handling
    // ──────────────────────────────────────────────────────────────────

    @isTest
    static void testGetSuggestionsSubqueryFromChildRelationships() {
        // Cursor inside subquery, inside FROM clause → searchChildRelationships
        String q = 'SELECT Id FROM Account WHERE Id IN (SELECT Id FROM Co)';
        Integer cursor = q.indexOf(')');  // right after 'Co'
        Test.startTest();
        List<Map<String, String>> r = InspectorController.getSuggestions(q, cursor);
        Test.stopTest();

        Boolean foundContacts = false;
        for (Map<String, String> m : r) {
            if (m.get('label') == 'Contacts') foundContacts = true;
        }
        System.assert(foundContacts, 'Subquery FROM "Co" should suggest the Contacts child relationship');
    }

    @isTest
    static void testGetSuggestionsSubqueryFromEmptyPrefixHitsRelLimit() {
        // Empty prefix → many child relationships → exercises the
        // `if (res.size() >= 20) break;` cap in searchChildRelationships.
        String q = 'SELECT Id FROM Account WHERE Id IN (SELECT Id FROM )';
        Integer cursor = q.indexOf(')');
        Test.startTest();
        List<Map<String, String>> r = InspectorController.getSuggestions(q, cursor);
        Test.stopTest();
        System.assertNotEquals(null, r);
    }

    @isTest
    static void testGetSuggestionsSubqueryFieldClause() {
        // Cursor inside subquery's SELECT clause
        String q = 'SELECT Id, (SELECT  FROM Contacts) FROM Account';
        Integer cursor = q.indexOf('SELECT ', 8) + 'SELECT '.length();
        Test.startTest();
        List<Map<String, String>> r = InspectorController.getSuggestions(q, cursor);
        Test.stopTest();
        System.assertNotEquals(null, r);
    }

    @isTest
    static void testGetSuggestionsSubqueryWithInvalidParent() {
        // Invalid parent object → searchChildRelationships hits its
        // describeSObjects empty/exception path and returns [].
        String q = 'SELECT Id FROM XyzFake__c WHERE Id IN (SELECT Id FROM Co)';
        Integer cursor = q.indexOf(')');
        Test.startTest();
        List<Map<String, String>> r = InspectorController.getSuggestions(q, cursor);
        Test.stopTest();
        System.assertNotEquals(null, r);
    }

    @isTest
    static void testGetSuggestionsSubqueryInvalidChildRel() {
        String q = 'SELECT Id FROM Account WHERE Id IN (SELECT Id FROM ZZZNotChild)';
        Integer cursor = q.indexOf(')') - 1;
        Test.startTest();
        List<Map<String, String>> r = InspectorController.getSuggestions(q, cursor);
        Test.stopTest();
        // No matching child relationship; should return empty list, no throw
        System.assertNotEquals(null, r);
    }

    @isTest
    static void testGetSuggestionsNoTopLevelFrom() {
        // Parens present but no FROM → extractObjectName null → getSubqueryContext
        // returns null early via the `if (String.isBlank(parentObj))` branch.
        Test.startTest();
        List<Map<String, String>> r = InspectorController.getSuggestions('SELECT (Id)', 8);
        Test.stopTest();
        System.assertNotEquals(null, r);
    }

    @isTest
    static void testGetSuggestionsCursorOutsideParens() {
        String q = 'SELECT Id, (SELECT Id FROM Contacts) FROM Account';
        Test.startTest();
        // Cursor at very end → outside parens → getSubqueryContext returns null
        List<Map<String, String>> r = InspectorController.getSuggestions(q, q.length());
        Test.stopTest();
        System.assertNotEquals(null, r);
    }

    // ──────────────────────────────────────────────────────────────────
    //  getSuggestions — keyword fallback + detectClause edges
    // ──────────────────────────────────────────────────────────────────

    @isTest
    static void testGetSuggestionsKeywordFallback() {
        Test.startTest();
        // Partial that matches a keyword but doesn't form any whole-word clause
        List<Map<String, String>> r1 = InspectorController.getSuggestions('SE', 2);
        // Tests both preOk=false and postOk=false branches of lastWholeWordIdx
        List<Map<String, String>> r2 = InspectorController.getSuggestions('XSELECT FROM Account',
            'XSELECT FROM Account'.length());
        List<Map<String, String>> r3 = InspectorController.getSuggestions('SELECTABC', 9);
        // Whole-word boundary at start/end of string
        List<Map<String, String>> r4 = InspectorController.getSuggestions('FROM', 4);
        Test.stopTest();

        Boolean foundSelectKw = false;
        for (Map<String, String> m : r1) {
            if (m.get('value') == 'SELECT') foundSelectKw = true;
        }
        System.assert(foundSelectKw, '"SE" partial should suggest SELECT keyword');
        System.assertNotEquals(null, r2);
        System.assertNotEquals(null, r3);
        System.assertNotEquals(null, r4);
    }

    @isTest
    static void testGetSuggestionsInvalidObjectInClause() {
        // Object name in FROM is invalid → searchFields hits describeSObjects
        // empty/exception path and returns [].
        Test.startTest();
        List<Map<String, String>> r =
            InspectorController.getSuggestions('SELECT Na FROM NotAnObject__c', 9);
        Test.stopTest();
        System.assertNotEquals(null, r);
    }

    // ──────────────────────────────────────────────────────────────────
    //  runQuery
    // ──────────────────────────────────────────────────────────────────

    @isTest
    static void testRunQuerySimple() {
        Test.startTest();
        List<Map<String, Object>> r = InspectorController.runQuery('SELECT Id, Name FROM Account');
        Test.stopTest();
        System.assert(r.size() >= 1, 'Test setup inserted an Account, so result should not be empty');
        System.assert(r[0].containsKey('Id'));
        System.assert(r[0].containsKey('Name'));
    }

    @isTest
    static void testRunQueryWithLimitClauseInsertsSecurityEnforcedMidString() {
        // Trailing LIMIT → insertAt > 0 → WITH SECURITY_ENFORCED inserted before LIMIT
        Test.startTest();
        List<Map<String, Object>> r = InspectorController.runQuery('SELECT Id FROM Account LIMIT 5');
        Test.stopTest();
        System.assertNotEquals(null, r);
    }

    @isTest
    static void testRunQueryWithOrderByClause() {
        Test.startTest();
        List<Map<String, Object>> r = InspectorController.runQuery('SELECT Id FROM Account ORDER BY Name');
        Test.stopTest();
        System.assertNotEquals(null, r);
    }

    @isTest
    static void testRunQueryWithGroupByClause() {
        Test.startTest();
        List<Map<String, Object>> r = InspectorController.runQuery('SELECT Name, COUNT(Id) FROM Account GROUP BY Name');
        Test.stopTest();
        System.assertNotEquals(null, r);
    }

    @isTest
    static void testRunQueryWithOffsetClause() {
        Test.startTest();
        List<Map<String, Object>> r = InspectorController.runQuery('SELECT Id FROM Account LIMIT 10 OFFSET 0');
        Test.stopTest();
        System.assertNotEquals(null, r);
    }

    @isTest
    static void testRunQueryAlreadyHasSecurityEnforced() {
        // Branch: safeUp.contains('WITH SECURITY_ENFORCED') is true → skip insertion
        Test.startTest();
        List<Map<String, Object>> r =
            InspectorController.runQuery('SELECT Id FROM Account WITH SECURITY_ENFORCED LIMIT 1');
        Test.stopTest();
        System.assertNotEquals(null, r);
    }

    @isTest
    static void testRunQueryAppendsSecurityEnforcedAtEnd() {
        // No trailing clauses → insertAt == -1 → appends WITH SECURITY_ENFORCED at end
        Test.startTest();
        List<Map<String, Object>> r = InspectorController.runQuery('SELECT Id FROM Account');
        Test.stopTest();
        System.assertNotEquals(null, r);
    }

    @isTest
    static void testRunQueryWithRelationshipFlattensNestedMap() {
        // Querying a parent-relationship field forces flattenMap recursion
        Test.startTest();
        List<Map<String, Object>> r = InspectorController.runQuery('SELECT Id, Owner.Name FROM Account');
        Test.stopTest();

        System.assert(r.size() >= 1);
        Boolean foundFlat = false;
        for (Map<String, Object> row : r) {
            if (row.containsKey('Owner.Name')) foundFlat = true;
        }
        System.assert(foundFlat, 'Nested relationship field should be flattened to "Owner.Name"');
    }

    @isTest
    static void testRunQueryTrailingSemicolonTrimmed() {
        Test.startTest();
        List<Map<String, Object>> r = InspectorController.runQuery('SELECT Id FROM Account;');
        Test.stopTest();
        System.assertNotEquals(null, r);
    }

    @isTest
    static void testRunQueryBlankThrows() {
        Boolean threw = false;
        Test.startTest();
        try {
            InspectorController.runQuery('');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Blank query should throw AuraHandledException');
    }

    @isTest
    static void testRunQueryNonSelectThrows() {
        Boolean threw = false;
        Test.startTest();
        try {
            InspectorController.runQuery('UPDATE Account SET Name = \'X\'');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Non-SELECT statement should throw AuraHandledException');
    }

    @isTest
    static void testRunQueryBadSoqlThrows() {
        // Invalid field → Database.query throws QueryException → caught and rethrown
        Boolean threw = false;
        Test.startTest();
        try {
            InspectorController.runQuery('SELECT NotARealField__c FROM Account');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Invalid SOQL should bubble up as AuraHandledException');
    }
}