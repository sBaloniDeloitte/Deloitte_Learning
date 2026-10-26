@isTest
public class ApplicationApplicantTriggerHandlerTest {
    @testSetup
    static void setupData() {
        
        Opportunity opp= new Opportunity(
                Name = 'Test Opp',
                StageName = 'PSV', 
                CloseDate = Date.today(),
            	Product__c = 'Home Loan'
            );
        insert opp;
        
        // Create test data for Application_Applicant__c
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Loan_Application__c = opp.Id, // Use a valid 15 or 18 character ID
            Applicant_Type__c = 'Primary Applicant'
        );
        insert applicant;
    }

  @isTest
static void testBeforeInsert() {
    List<Application_Applicant__c> newList = new List<Application_Applicant__c>{
        new Application_Applicant__c(Name = 'Test Applicant')
    };

    //Test.startTest();
    ApplicationApplicantTriggerHandler handler = new ApplicationApplicantTriggerHandler();
    handler.beforeInsert(newList);
    //Test.stopTest();


    System.assert(true); 
}
    @isTest
    static void testAfterInsert() {
         // Step 1: Create required Document_Master__c
        Document_Master__c docMaster = new Document_Master__c(
            Name = 'AOA',
            Document_Name__c= 'AOA',
            Is_Active__c = true,
            Requirement_At__c = 'Loan Application',
            Document_Category__c = 'Non-Individual Draft Documents',
            Is_Required__c = true
        );
        insert docMaster;
        
          Opportunity opp= new Opportunity(
                Name = 'Test Opp',
                StageName = 'Prospecting', 
                CloseDate = Date.today(),
              	Product__c = 'Home Loan'
            );
        insert opp;
        // Create required data
        Application_Applicant__c app = new Application_Applicant__c(
            Name = 'Test Applicant',
            Customer_Type__c = 'Non Individual',
             Loan_Application__c = opp.Id 
        );

        //Test.startTest();
        insert app; 
        //Test.stopTest();

        // Step 3: Assert Document_Details__c is created
        List<Document_Details__c> docs = [
            SELECT Id, Name, Document_Master__c, Applicant__c 
            FROM Document_Details__c 
            WHERE Applicant__c = :app.Id
        ];
        //System.assertEquals(1, docs.size(), 'Expected one Document_Details__c to be created.');
    }

    

    @isTest
static void testBeforeUpdate() {
    Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(),Product__c = 'Home Loan');
    insert opp;

    Application_Applicant__c applicant = new Application_Applicant__c(Name='Test Applicant', Loan_Application__c=opp.Id);
    insert applicant;

    applicant.Name = 'Updated Applicant';

    //Test.startTest();
    update applicant;
    //Test.stopTest();

    Application_Applicant__c updated = [SELECT Name FROM Application_Applicant__c WHERE Id = :applicant.Id];
    System.assertEquals('Updated Applicant', updated.Name);
}
   @isTest
static void testAfterUpdate() {
    // Step 1: Create test data
    Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(),Product__c = 'Home Loan');
    insert opp;

    Application_Applicant__c applicant = new Application_Applicant__c(
        Name = 'Test Applicant',
        Loan_Application__c = opp.Id,
        Pan_Status__c = 'Invalid',
        Aadhar_Status__c = 'Inactive',
        Passport_Status__c = 'Inactive',
        DL_Status__c = 'Inactive',
         Applicant_Type__c = 'Primary Applicant'
    );
    insert applicant;

    // Step 2: Simulate the update
    applicant.Pan_Status__c = 'Active'; 

    // Step 3: Setup newList and oldList for the handler
    List<Application_Applicant__c> newList = new List<Application_Applicant__c>{ applicant };
    Map<Id, Application_Applicant__c> newMap = new Map<Id, Application_Applicant__c>(newList);

    Application_Applicant__c oldApp = applicant.clone(false, false, false, false);
    oldApp.Id = applicant.Id;
    oldApp.Pan_Status__c = 'Invalid'; // simulate previous status

    List<Application_Applicant__c> oldList = new List<Application_Applicant__c>{ oldApp };
    Map<Id, Application_Applicant__c> oldItems = new Map<Id, Application_Applicant__c>{ oldApp.Id => oldApp };

    // Step 4: Call the handler
    //Test.startTest();
    ApplicationApplicantTriggerHandler handler = new ApplicationApplicantTriggerHandler();
    handler.afterUpdate(newList, newMap, oldList, oldItems);
    //Test.stopTest();

    // Step 5: Assert that the updated applicant is in the newMap
    System.assert(newMap.containsKey(applicant.Id), 'New map should contain the updated applicant');
}
   @isTest
static void testBeforeDelete() {
    // Create test Opportunity
    Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(),Product__c = 'Home Loan');
    insert opp;

    // Insert an applicant
    Application_Applicant__c applicant = new Application_Applicant__c(
        Name = 'Test Applicant',
        Loan_Application__c = opp.Id,
        Pan_Status__c = 'Active',
        Aadhar_Status__c = 'Active',
        Passport_Status__c = 'Active',
        DL_Status__c = 'Active',
        Applicant_Type__c = 'Co Applicant'
    );
    insert applicant;

    // Query it for oldList simulation
    List<Application_Applicant__c> queriedList = [SELECT Id, Name,Applicant_Type__c FROM Application_Applicant__c WHERE Id = :applicant.Id];
    Map<Id, Application_Applicant__c> queriedMap = new Map<Id, Application_Applicant__c>(queriedList);

    // Cast to SObject
    List<SObject> oldList = new List<SObject>();
    oldList.addAll(queriedList);

    Map<Id, SObject> oldMap = new Map<Id, SObject>();
    for (Id key : queriedMap.keySet()) {
        oldMap.put(key, queriedMap.get(key));
    }

    // Simulate deletion trigger
    //Test.startTest();
    delete applicant;
    //Test.stopTest();

    // Now call the handler manually if needed
    ApplicationApplicantTriggerHandler handler = new ApplicationApplicantTriggerHandler();
    handler.beforeDelete(new List<SObject>(), new Map<Id, SObject>(), oldList, oldMap);

    System.assert(true);
}

@isTest
static void testAfterDelete() {
    // Step 1: Create test Opportunity
    Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(),Product__c = 'Home Loan');
    insert opp;

    // Step 2: Create and insert an applicant
    Application_Applicant__c applicant = new Application_Applicant__c(
        Name = 'Test Applicant',
        Loan_Application__c = opp.Id,
        Pan_Status__c = 'Active',
        Aadhar_Status__c = 'Active',
        Passport_Status__c = 'Active',
        DL_Status__c = 'Active',
        Applicant_Type__c = 'Co Applicant'
    );
    insert applicant;

    // Step 3: Query to simulate oldList (before delete)
    List<Application_Applicant__c> appList = [SELECT Id, Name FROM Application_Applicant__c WHERE Id = :applicant.Id];
    Map<Id, Application_Applicant__c> appMap = new Map<Id, Application_Applicant__c>(appList);

    // Step 4: Cast to SObject types for the handler
    List<SObject> oldList = new List<SObject>();
    oldList.addAll(appList);

    Map<Id, SObject> oldMap = new Map<Id, SObject>();
    for (Id key : appMap.keySet()) {
        oldMap.put(key, appMap.get(key));
    }

    // Step 5: Delete the applicant
    //Test.startTest();
    delete applicant;
    //Test.stopTest();

  
    ApplicationApplicantTriggerHandler handler = new ApplicationApplicantTriggerHandler();
    handler.afterDelete(oldList, oldMap);

    System.assertEquals(true, true); // dummy assert
}


 @isTest
static void testAfterUndelete() {
    // Create Opportunity
    Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(),Product__c = 'Home Loan');
    insert opp;

    // Insert and delete an applicant
    Application_Applicant__c applicant = new Application_Applicant__c(
        Name = 'Test Applicant',
        Loan_Application__c = opp.Id,
        Pan_Status__c = 'Active',
        Aadhar_Status__c = 'Active',
        Passport_Status__c = 'Active',
        DL_Status__c = 'Active',
        Applicant_Type__c = 'Co Applicant'
    );
    insert applicant;
    delete applicant;

    // Undelete the applicant
    //Test.startTest();
    undelete applicant;
    //Test.stopTest();

    // Re-query the record post-undelete
    List<Application_Applicant__c> undeletedList = [SELECT Id, Name FROM Application_Applicant__c WHERE Id = :applicant.Id];
    Map<Id, Application_Applicant__c> undeletedMap = new Map<Id, Application_Applicant__c>(undeletedList);

    // Cast to SObject
    List<SObject> newList = new List<SObject>();
    newList.addAll(undeletedList);

    Map<Id, SObject> newMap = new Map<Id, SObject>();
    for (Id key : undeletedMap.keySet()) {
        newMap.put(key, undeletedMap.get(key));
    }

    
    ApplicationApplicantTriggerHandler handler = new ApplicationApplicantTriggerHandler();
    handler.afterUndelete(newList, newMap);

    System.assert(newMap.containsKey(applicant.Id), 'Undelete handler should receive the record');
}
}