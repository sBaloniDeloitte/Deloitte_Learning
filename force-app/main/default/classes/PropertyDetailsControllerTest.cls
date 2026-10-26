@isTest
public class PropertyDetailsControllerTest {
   @TestSetup
    static void makeData(){
        Account acc = new Account(name = 'Test Account',Branch_Address__c ='Test Address');
        insert acc;
        // Create Loan Application (assuming Opportunity)
        Opportunity loanApp = new Opportunity(
            Name = 'Test Loan',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(5),
            Status__c = 'In Progress',                
            Product__c = 'Affordable Home Loan' ,
            Branch_Master__c =     acc.id
        );
        insert loanApp;
         
        Collateral__c col = new Collateral__c(Plot_Number__c = '1234',Building_Street_Name__c = 'rvm street', Landmark__c = 'ICICI Bank', State__c = 'KA',Asset_Collateral__c = 'Collateral');
        insert col;
        
        Application_Collateral__c ac = new Application_Collateral__c(
            Collateral__c = col.id,
            HL_Loan_Application__c = loanApp.Id
        );
    insert ac;

    }
    @isTest
    static void getAllPropertyDetailsTest() {
        Opportunity loanApp =[Select Id from Opportunity Limit 1];
        PropertyDetailsController.getAllPropertyDetails(loanApp.Id);
        
    }

}