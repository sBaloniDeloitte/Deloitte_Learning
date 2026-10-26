public with sharing class OwnerLogUtil {
    private static final String INITIAL_PREFIX = 'INITIAL|'; // INITIAL|<UserId>|<ProfileName>|<ISO-8601>
    private static final String CURR_PREFIX    = 'CURR|';    // CURR|<Stage>|<SubStage>|<UserId>|<ProfileName>|<ISO-8601>

    public class InitialInfo {
        @AuraEnabled public String userId;
        @AuraEnabled public String profile;
        @AuraEnabled public String tsIso;
        public InitialInfo(String userId, String profile, String tsIso) {
            this.userId = userId; this.profile = profile; this.tsIso = tsIso;
        }
    }

    public static Boolean hasInitialLine(String existing) {
        if (String.isBlank(existing)) return false;
        for (String l : existing.split('\\r?\\n')) {
            if (l.startsWith(INITIAL_PREFIX)) return true;
        }
        return false;
    }

    public static InitialInfo parseInitial(String existing) {
        if (String.isBlank(existing)) return null;
        for (String l : existing.split('\\r?\\n')) {
            if (l.startsWith(INITIAL_PREFIX)) {
                List<String> p = l.split('\\|');
                if (p.size() >= 4) return new InitialInfo(p[1], p[2], p[3]);
            }
        }
        return null;
    }

    /**
     * Returns true if the running user is the initial owner (Sales profile) for the given Owner_History__c string.
     */
    @AuraEnabled
    public static Boolean isRunningUserInitialSales(String ownerHistory) {
        InitialInfo init = parseInitial(ownerHistory);
        if (init == null) return false;
        if (init.userId != UserInfo.getUserId()) return false;
        // Defensive: check profile contains 'sales' (case-insensitive)
        return (init.profile != null && init.profile.toLowerCase().contains('sales'));
    }

    public static String composeInitial(Id userId, String profile, String tsIso) {
        return INITIAL_PREFIX + String.valueOf(userId) + '|' + safe(profile) + '|' + safe(tsIso);
    }

    public static String replaceInitial(String existing, Id userId, String profile, String tsIso) {
        String line = composeInitial(userId, profile, tsIso);
        if (String.isBlank(existing)) return line;
        List<String> lines = new List<String>(existing.split('\\r?\\n'));
        Boolean replaced = false;
        for (Integer i = 0; i < lines.size(); i++) {
            if (lines[i].startsWith(INITIAL_PREFIX)) { lines[i] = line; replaced = true; break; }
        }
        if (!replaced) lines.add(0, line);
        return String.join(lines, '\n');
    }

    public static String upsertCurrent(String existing, String stage, String subStage, Id userId, String profile, String tsIso) {
        String line = CURR_PREFIX
            + safe(stage) + '|' + safe(subStage) + '|' + String.valueOf(userId) + '|' + safe(profile) + '|' + safe(tsIso);
        if (String.isBlank(existing)) return line;
        List<String> lines = new List<String>(existing.split('\\r?\\n'));
        Boolean replaced = false;
        for (Integer i = 0; i < lines.size(); i++) {
            if (lines[i].startsWith(CURR_PREFIX)) { lines[i] = line; replaced = true; break; }
        }
        if (!replaced) lines.add(line);
        return String.join(lines, '\n');
    }

    private static String safe(String s) { return (s == null ? '' : s.replace('\n', ' ').replace('\r', ' ')); }
}