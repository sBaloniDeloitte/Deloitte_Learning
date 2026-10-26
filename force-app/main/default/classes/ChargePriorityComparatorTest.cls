@isTest
public class ChargePriorityComparatorTest {

    @isTest
    static void testComparatorWithPriorities() {
        Charges_Insurance__c procFee = new Charges_Insurance__c(Name = 'PROCFEE');
        Charges_Insurance__c adminFee = new Charges_Insurance__c(Name = 'ADMINFEE');
        Charges_Insurance__c stfChg = new Charges_Insurance__c(Name = 'STFRCHG');

        ChargePriorityComparator comparator = new ChargePriorityComparator();

        // PROCFEE (1) < ADMINFEE (2)
        System.assertEquals(-1, comparator.compare(procFee, adminFee));

        // STFRCHG (3) > ADMINFEE (2)
        System.assertEquals(1, comparator.compare(stfChg, adminFee));

        // ADMINFEE (2) vs ADMINFEE (2) → Equal
        System.assertEquals(0, comparator.compare(adminFee, adminFee));
    }

    @isTest
    static void testComparatorWithUnknownNames() {
        Charges_Insurance__c unknown1 = new Charges_Insurance__c(Name = 'XYZ');
        Charges_Insurance__c unknown2 = new Charges_Insurance__c(Name = 'ABC');

        ChargePriorityComparator comparator = new ChargePriorityComparator();

        // Both unknown → equal (999 vs 999)
        System.assertEquals(0, comparator.compare(unknown1, unknown2));

        // Known vs Unknown → PROCFEE (1) should come before XYZ (999)
        Charges_Insurance__c procFee = new Charges_Insurance__c(Name = 'PROCFEE');
        System.assertEquals(-1, comparator.compare(procFee, unknown1));
        System.assertEquals(1, comparator.compare(unknown1, procFee));
    }

    @isTest
    static void testSortingListOfCharges() {
        List<Charges_Insurance__c> charges = new List<Charges_Insurance__c>{
            new Charges_Insurance__c(Name = 'XYZ'),
            new Charges_Insurance__c(Name = 'STFRCHG'),
            new Charges_Insurance__c(Name = 'PROCFEE'),
            new Charges_Insurance__c(Name = 'ADMINFEE')
        };

        charges.sort(new ChargePriorityComparator());

        // After sorting: PROCFEE → ADMINFEE → STFRCHG → XYZ
        System.assertEquals('PROCFEE', charges[0].Name);
        System.assertEquals('ADMINFEE', charges[1].Name);
        System.assertEquals('STFRCHG', charges[2].Name);
        System.assertEquals('XYZ', charges[3].Name);
    }
}