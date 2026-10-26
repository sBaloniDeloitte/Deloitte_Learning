public class APFLetterController {
    List<Project__c> objProject = new List<Project__c>();
    String projectID {get; set;}
	@testVisible void APFLetterController()
    {	
        projectID = Apexpages.currentPage().getParameters().get('proID');
        objProject=[select name, Address_Line_1__c,Address_Line_2__c,Other_Terms_and_Conditions__c, Project_Specific_T_C__c, Convenants_For_Retail_Notes__c, Address_Line_3__c, Landmark__c, City__c, State__c, Pincode__r.name, Builder_Master__r.name, APF_No__c, Builder_Master__r.Request_ID__c, Builder_Master__r.Inserted_Date__c from Project__c where RecordType.name='project' and id=:projectID];
    }
    
    public List<Project__c> getApfLetterDetails()
    {
        projectID = Apexpages.currentPage().getParameters().get('proID');
        objProject=[select name, Address_Line_1__c,Other_Terms_and_Conditions__c, Project_Specific_T_C__c, Convenants_For_Retail_Notes__c, Address_Line_2__c, Address_Line_3__c, Landmark__c, City__c, State__c, Pincode__r.name, Builder_Master__r.name, APF_No__c, Builder_Master__r.Request_ID__c, Builder_Master__r.Inserted_Date__c from Project__c where RecordType.name='project' and id=:projectID];
        return objProject;
    }
}