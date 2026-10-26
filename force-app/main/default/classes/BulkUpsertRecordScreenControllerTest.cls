@isTest
public class BulkUpsertRecordScreenControllerTest {
    
    public static final string contentVersionProperDoc = 'contentVersionProperDocCreation';
    public static final string contentVersionErrorDoc = 'contentVersionErrorDocCreation';
    public static final string pathOnClient = 'test.csv';
    public static final string TriggerSettingName = 'Trigger Settings';
    public static final string LeadObjectName = 'Lead';
    
    @Testsetup
    static void dataSetup(){ 
        
        List<ContentVersion> cvList = new List<ContentVersion>();
        
        ContentVersion cv=FITestDataFactory.getContentVersion ( pathOnClient,  contentVersionProperDoc ,  false );
      
        cv.versiondata =Blob.valueOf('"First Name","Middle Name","Last Name","Mobile Number","External Id","Date of Birth","Requested Loan Amount"\n"Lead","Test","Management","9087654332","123456789","1990-01-01","20"');
        cvList.add(cv);
        
ContentVersion cvSaveError = FITestDataFactory.getContentVersion ( pathOnClient,  'Save Error Doc' ,  false );
        cvSaveError.versiondata =Blob.valueOf('"First Name","Middle Name","Last Name","Mobile Number","External Id","Date of Birth","Requested Loan Amount","Product"\n"Lead","Test","Management","9087654332","123456789","1990-01-01","20","My Product"');
        cvList.add(cvSaveError);
        
        ContentVersion cverror=  FITestDataFactory.getContentVersion ( pathOnClient,  contentVersionErrorDoc ,  false );

        cverror.versiondata = Blob.valueOf('"First Name","Middle Name","Last Name","Mobile Number","External Id","Date of Birth","Turnover (Yearly)"\n"Lead,","Test345","Management","",""');
        cvList.add(cverror);
        
        ContentVersion cvInvalidColumn = FITestDataFactory.getContentVersion ( pathOnClient,  'Invalid Column Doc' ,  false );
        cvInvalidColumn.versiondata = Blob.valueOf('"Invalid Column","First Name","Mobile Number","Last Name","External Id"\n"","","","",""');
        cvList.add(cvInvalidColumn);
        insert cvList;
        
        Trigger_Settings__c triggerLead = new Trigger_Settings__c();
        triggerLead.Name = TriggerSettingName;
        triggerLead.Lead_Trigger__c = false;
        insert triggerLead;
    }
    
    
    @isTest
    public static void saveFileTestSuccessMethod(){
        
        ContentVersion content = [SELECT Id,contentDocumentId FROM ContentVersion WHERE title=:contentVersionProperDoc LIMIT 1];
        Test.startTest();
        List<String> result = BulkUpsertRecordScreenController.saveFile(content.contentDocumentId,LeadObjectName);
        Test.stopTest();
        System.assert(result.size()>0);
    }
    
        @isTest
    public static void saveFileTestErrorMethod(){
        
        ContentVersion content = [SELECT Id,contentDocumentId FROM ContentVersion WHERE title=:contentVersionErrorDoc LIMIT 1];
        Test.startTest();
         List<String> result = BulkUpsertRecordScreenController.saveFile(content.contentDocumentId,LeadObjectName);
        Test.stopTest();
        
        System.assert(result.size()>0);
    }
	
    @isTest
    public static void saveFileTestInvalidColumnMethod(){
        
        ContentVersion content = [SELECT Id,contentDocumentId FROM ContentVersion WHERE title='Invalid Column Doc' LIMIT 1];
        Test.startTest();
        List<String> result = BulkUpsertRecordScreenController.saveFile(content.contentDocumentId,LeadObjectName);
        Test.stopTest();
        
        System.assert(result.size()>0);
        System.assert(result.contains('Invalid Column Invalid Column'));
    }
    
    @isTest
    public static void saveFileTestSaveErrorMethod(){
        
        ContentVersion content = [SELECT Id,contentDocumentId FROM ContentVersion WHERE title='Save Error Doc' LIMIT 1];
        Test.startTest();
        List<String> result = BulkUpsertRecordScreenController.saveFile(content.contentDocumentId,LeadObjectName);
        Test.stopTest();
        
        System.assert(result.size()>0);
    }
    
    @isTest
    public static void getSampleCSVTestMethodPositive(){
        Test.startTest();
        List<String> result = BulkUpsertRecordScreenController.getSampleCSV(LeadObjectName);
        Test.stopTest();
        System.assert(result.size()>0);
    }
    
    @isTest
    public static void getSampleCSVTestMethodNegative(){
        Test.startTest();
        List<String> result = BulkUpsertRecordScreenController.getSampleCSV('SomeObject__a');
        Test.stopTest();
        
        System.assert(result.size()>0);
    }
    
}