@isTest
public class InstrumentMandateHandlerTest {
    
    private static void createTestData() {
        Opportunity loanApp = new Opportunity(Name = 'Test Loan Application', Product__c = 'Affordable Home Loan');
        insert loanApp;
        Id rtVariant = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
Id rtProduct = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();

// Main product row (fills productNameMap)
insert new Product2(
    Name = loanApp.Product__c,          // important: should match checks: Affordable Home Loan / Flexi Loan etc
    Loan_Application__c = loanApp.Id,
    RecordTypeId = rtProduct
);

// Variant row (fills subproductNameMap via Product__r.Name)
Product2 parentProd = new Product2(Name = 'Parent Product', RecordTypeId = rtProduct);
insert parentProd;

insert new Product2(
    Name = 'Some Variant',
    Loan_Application__c = loanApp.Id,
    RecordTypeId = rtVariant,
    Product__c = parentProd.Id
);


        Bank_Branch_Master__c bankMaster = new Bank_Branch_Master__c(Name = 'ICICI Bank', Bank_Name__c = 'ICICI Bank',Bank_Code__c ='001' );
        insert bankMaster;

        Bank_Details__c bankDetails = new Bank_Details__c(
            Account_Number__c = '123456789',
            Account_Holder_Name__c = 'Test Holder',
            Bank_Master__c = bankMaster.Id
        );
        insert bankDetails;

        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            First_Name__c = 'John',
            Middle_Name__c = 'M',
            Last_Name__c = 'Doe',
            Reference_Phone_1__c = '123-456-78',
            Email__c = 'john.doe@example.com',
            PAN_Number__c = 'ABCDE1234F'
        );
        insert applicant;

       
	List<Loan_Transaction__c> loanTransactions = new List<Loan_Transaction__c>();

for(String freq : new List<String>{'M','Y','H','Q'}) {
    loanTransactions.add(new Loan_Transaction__c(
        Loan_Application__c = loanApp.Id,
        Interest_Frequency__c = freq,
        Yearly_Selection__c = '01',
        Half_Yearly_Selection__c = '01',
        Quarterly_Selection__c = '01',
        Interest_Due_date__c = '03',
        Next_First_Payment_Date__c = Date.today().addDays(30)
    ));
}

insert loanTransactions;

        Instrument_Mandate__c mandate = new Instrument_Mandate__c(
            Loan_Application__c = loanApp.Id,
            Mandate_Type__c = 'Repayment Mandate',
            Application_Applicant__c = applicant.Id,
            Start_Date__c = Date.today(), 
            End_Date__c = Date.today().addYears(1), 
            Periodicity__c = 'Monthly',
            ENACH_Ext_ID__c = 'ENACH123',
            Type_of_Instrument_Record__c = 'Child',
            Bank_Details__c = bankDetails.Id
        );
        insert mandate;
    }

    @isTest
    static void testHandleAfterInsert() {
        createTestData();
        
        List<Instrument_Mandate__c> mandates = [SELECT Id, Loan_Application__c, Mandate_Type__c, 
                                                 Application_Applicant__c, 
                                                 Start_Date__c, End_Date__c,
                                                 Periodicity__c, ENACH_Ext_ID__c, Bank_Details__c 
                                                 FROM Instrument_Mandate__c];
        
        Test.startTest();
        InstrumentMandateHandler.handleAfterInsert(mandates);
        InstrumentMandateHandler.reHitEnach(mandates[0].Id);
        Test.stopTest();
        List<Integration_Details__c> integrationDetailsList = [SELECT Id, Name, Loan_Application__c, Endpoint__c 
                                                               FROM Integration_Details__c];
       // System.assertEquals(1, integrationDetailsList.size(), 'One Integration_Details record should be created');
        delete mandates[0];
    }
    @isTest
static void testHandleAfterDelete_DeletesParentWhenNoChildren() {
    Opportunity loanApp = new Opportunity(Name='LA', Product__c='Affordable Home Loan');
    insert loanApp;

    Instrument_Mandate__c parent = new Instrument_Mandate__c(
        Loan_Application__c = loanApp.Id,
        Mandate_Type__c = 'Repayment Mandate',
        Type_of_Instrument_Record__c = 'Parent'
    );
    insert parent;

    Instrument_Mandate__c child = new Instrument_Mandate__c(
        Loan_Application__c = loanApp.Id,
        Mandate_Type__c = 'Repayment Mandate',
        Type_of_Instrument_Record__c = 'Child',
        Instrument_Mandate__c = parent.Id
    );
    insert child;

    // Delete child -> handler should delete parent if no other children remain
    Test.startTest();
    try{

    
    delete child; // trigger should call handleAfterDelete, but to be safe you can call handler directly too
    InstrumentMandateHandler.handleAfterDelete(new List<Instrument_Mandate__c>{child});
    Test.stopTest();
    }
    catch(Exception e)
    {
        
    }

    System.assertEquals(
        0,
        [SELECT count() FROM Instrument_Mandate__c WHERE Id = :parent.Id],
        'Parent should be deleted when last child is deleted'
    );
}

}