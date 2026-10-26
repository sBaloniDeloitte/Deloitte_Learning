@IsTest
private class OwnerLogUtilTest {
    static String testUserId = UserInfo.getUserId();
    static String testProfile = 'Sales';
    static String testTs = '2026-03-11T12:00:00Z';

    @IsTest
    static void test_composeInitial_and_parseInitial() {
        String initial = OwnerLogUtil.composeInitial(testUserId, testProfile, testTs);
        System.assert(initial.startsWith('INITIAL|'), 'Should start with INITIAL|');
        OwnerLogUtil.InitialInfo info = OwnerLogUtil.parseInitial(initial);
        System.assertEquals(testUserId, info.userId, 'UserId parsed');
        System.assertEquals(testProfile, info.profile, 'Profile parsed');
        System.assertEquals(testTs, info.tsIso, 'Timestamp parsed');
    }

    @IsTest
    static void test_hasInitialLine() {
        String initial = OwnerLogUtil.composeInitial(testUserId, testProfile, testTs);
        System.assert(OwnerLogUtil.hasInitialLine(initial), 'Should detect initial line');
        System.assert(!OwnerLogUtil.hasInitialLine('CURR|stage|sub|id|profile|ts'), 'Should not detect initial line');
        System.assert(!OwnerLogUtil.hasInitialLine(null), 'Null returns false');
        System.assert(!OwnerLogUtil.hasInitialLine(''), 'Blank returns false');
    }

    @IsTest
    static void test_replaceInitial() {
        String initial1 = OwnerLogUtil.composeInitial('005000000000000AAA', 'Prof1', '2026-01-01T00:00:00Z');
        String replaced = OwnerLogUtil.replaceInitial(initial1, testUserId, testProfile, testTs);
        OwnerLogUtil.InitialInfo info = OwnerLogUtil.parseInitial(replaced);
        System.assertEquals(testUserId, info.userId, 'UserId replaced');
        System.assertEquals(testProfile, info.profile, 'Profile replaced');
        System.assertEquals(testTs, info.tsIso, 'Timestamp replaced');
        // If no initial line, should add
        String noInitial = 'CURR|stage|sub|id|profile|ts';
        String withInitial = OwnerLogUtil.replaceInitial(noInitial, testUserId, testProfile, testTs);
        System.assert(OwnerLogUtil.hasInitialLine(withInitial), 'Should add initial line if missing');
    }

    @IsTest
    static void test_upsertCurrent() {
        String existing = null;
        String stage = 'Sales Login';
        String sub = 'Login in-progress';
        String profile = 'Sales';
        String ts = '2026-03-11T12:00:00Z';
        String upserted = OwnerLogUtil.upsertCurrent(existing, stage, sub, testUserId, profile, ts);
        System.assert(upserted.startsWith('CURR|'), 'Should start with CURR|');
        // Add a current, then upsert again
        String up2 = OwnerLogUtil.upsertCurrent(upserted, 'Stage2', 'Sub2', testUserId, profile, ts);
        System.assert(up2.contains('Stage2|Sub2'), 'Should update current line');
        // If no current, should add
        String noCurr = 'INITIAL|' + testUserId + '|Sales|' + ts;
        String withCurr = OwnerLogUtil.upsertCurrent(noCurr, stage, sub, testUserId, profile, ts);
        System.assert(withCurr.contains('CURR|'), 'Should add current line if missing');
    }

    @IsTest
    static void test_isRunningUserInitialSales() {
        String initial = OwnerLogUtil.composeInitial(testUserId, 'Sales', testTs);
        System.assert(OwnerLogUtil.isRunningUserInitialSales(initial), 'Should be true for running user and sales profile');
        String notSales = OwnerLogUtil.composeInitial(testUserId, 'Other', testTs);
        System.assert(!OwnerLogUtil.isRunningUserInitialSales(notSales), 'Should be false for non-sales profile');
        String otherUser = OwnerLogUtil.composeInitial('005000000000000', 'Sales', testTs);
        System.assert(!OwnerLogUtil.isRunningUserInitialSales(otherUser), 'Should be false for other user');
        System.assert(!OwnerLogUtil.isRunningUserInitialSales(null), 'Null returns false');
    }
}