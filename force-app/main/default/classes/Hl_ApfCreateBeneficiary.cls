public with sharing class Hl_ApfCreateBeneficiary {

    public class CalloutInputWrapper {
        @InvocableVariable(required=true)
        public String BeneficiaryId;
    
        @InvocableVariable(required=true)
        public String Operation;
    }
    
    @InvocableMethod(label='Initiate Create Beneficiary API Callout')
    public static void initiateCallout(List<CalloutInputWrapper> inputList) {
    try{
        for(CalloutInputWrapper input : inputList) {
            Hl_ApfCreateBeneficiary.initiateApfCreateBeneficiary(
                new List<String>{ input.BeneficiaryId },
                input.Operation
            );
        }
    }catch(Exception e){
        Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'Hl_ApfCreateBeneficiary', '', '') });
    }
    }

    /*@InvocableMethod(label='Initiate Create Beneficiary API Callout')
    public static void initiateCallout(List<String> BeneficiaryId, String Operation) {
        Hl_ApfCreateBeneficiary.initiateApfCreateBeneficiary(BeneficiaryId,Operation);
    }*/
    
    
    public static string initiateApfCreateBeneficiary(List<String> BeneficiaryId, string action){ //project would be the parent obj of beneficiary and we'll fetch and write it the same way 
        List<String> payload = new List<String>();
        HttpResponse httpRes=null;
        Integration_Master__mdt metadata;
        
        if(action == 'create'){
         metadata = [SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, Client_Id__c, 
                    Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt 
                WHERE Activity_Name__c = 'Create Beneficiary'
                LIMIT 1];
         }else{
          
          metadata =  [SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, Client_Id__c, 
                    Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt 
                WHERE Activity_Name__c = 'Inactive Beneficiary'
                LIMIT 1];
         
         }

        if(metadata!=null){
            Http http = new Http();
            HttpRequest httpReq = new  HttpRequest();
            String endpoint = metadata.Endpoint__c;
            String bearer = Utility.getAccessToken();
            System.debug('Token:::'+bearer);
            httpReq.setEndpoint( endpoint );
            httpReq.setMethod( 'POST' );
            httpReq.setHeader('MESSAGEID','167036797111');
            httpReq.setHeader('Content-Type', 'application/json' );
            httpReq.setHeader('Authorization','Bearer '+bearer);
            httpReq.setHeader('ENTITYID','14589954555');
            String servicename = (action == 'create')? 'createBuilderBeneficiary': 'inActiveBuilderBeneficiary';
            httpReq.setHeader('ServiceName',servicename);
            httpReq.setHeader('RequestTime','2025-11-07T00:00:00');
            httpReq.setHeader('ServiceVersion','1');
            httpReq.setHeader('Language','ENG');
            //httpReq.setHeader('Authorization','79Nwl3B+WTrUnQ4rbcxqEz0p6R/hOamJW5kUYYGF2AuCGwqeU3w64pnj25Q=');
            Map<String,List<String>> jsonPlusErrorMap;
            List<Integration_Details__c> intdet = new List<Integration_Details__c>();
            List<Bank_Details__c> bankDetail = new List<Bank_Details__c>();
            if(action == 'create'){
                jsonPlusErrorMap = beneficiaryApexToJson(BeneficiaryId[0]);
                payload = jsonPlusErrorMap.get('json');
            }else{
                DeleteBeneficiaryWrapper beneficiary = new DeleteBeneficiaryWrapper();
                intdet = [Select customer_Id__c from integration_details__c where Bank_Details__c = :BeneficiaryId[0] and is_sync__c = true limit 1];
                bankDetail=[select id,Beneficiary_ID__c from Bank_Details__c where Id=:BeneficiaryId[0]];
                  if(!intdet.isEmpty()){
				   beneficiary.beneficiaryID = (String.isNotBlank(intdet[0].Customer_Id__c))?intdet[0].Customer_Id__c:'';
                }else{
				   beneficiary.beneficiaryID = (String.isNotBlank(bankDetail[0].Beneficiary_ID__c))?bankDetail[0].Beneficiary_ID__c:'';
                }
                jsonPlusErrorMap =  new Map<String, List<String>> {'json' => new List<String> { JSON.serialize(beneficiary) }};
                payload = jsonPlusErrorMap.get('json');
            } // 'insert', 'update' builderObjList > ReCordType : COMPANY
            
            System.debug('Payload :'+payload[0]);
            if(payload!=null && String.isNotBlank(payload[0])){
                httpReq.setBody(payload[0]);
                httpReq.setTimeout(120000);
                httpRes = http.send( httpReq );
                System.debug('Response Body:'+httpRes.getBody());
            }
            // Added by Anand Walimbe
            List<Integration_Details__c> integrationList = new List<Integration_Details__c>();
            Integration_Details__c integration = new Integration_Details__c();
            if(action == 'create'){
                integration.Name = 'APF Callout Event - CreateBeneficiary ' ;
                integration.Process_Name__c ='CreateBeneficiary ';
            }
              else{
                integration.Name = 'APF Callout Event - DeleteBeneficiary ' ;
                integration.Process_Name__c ='DeleteBeneficiary ';
            }
                integration.Endpoint__c = endpoint; 
                integration.Object_Name__c='Project Beneficiary';
                integration.Related_Record_Id__c = BeneficiaryId[0]; 
                integration.Bank_Details__c = BeneficiaryId[0];
                integration.Communication_Status__c = 'Published';
                integration.Request_JSON__c = payload[0];
                String body = httpRes.getBody();
                Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(body);
                Boolean isSuccess=false;
                if(action == 'create'){
                    Map<String, Object> returnStatus = (Map<String, Object>) res.get('returnStatus');
                    if (returnStatus != null) {
                    isSuccess = returnStatus.get('returnText') == 'Success';
                    integration.Customer_Id__c   = (isSuccess && action =='create')?String.valueOf(res.get('beneficiaryID')):'';
                    }
                    integration.Is_Sync__c = isSuccess;
                }else{
					integration.Is_Sync__c = ((String) res.get('returnText')) == 'Success';
				}
                integration.Response_JSON__c = httpRes!=null && httpRes.getBody() !=null ? httpRes.getBody() :'';
                integrationList.add(integration);
            
            insert integrationList;
            // End
            System.debug(payload[0]);
        }
        return payload.size()>0 ? payload[0] : 'payload Empty';
    }

    public static Map<String, List<String>> beneficiaryApexToJson(String BeneficiaryId) {
        List<Bank_Details__c> banksToBeInserted =  [SELECT Id,Project_Name__c,Project_Name__r.APF_ID__c,Bank_Master__c,Bank_Master__r.IFSC__c,Bank_Master__r.Bank_Code__c,Bank_Master__r.Branch_Code__c,
        Account_Holder_Name__c, Account_Number__c,Project_Name__r.record_sync__c,Project_Name__r.Project_Id__c  FROM Bank_Details__c WHERE id =:BeneficiaryId ];
        
        CreateBeneficiaryWrapper beneficiary = new CreateBeneficiaryWrapper();
        if(banksToBeInserted.size()>0){
            for(Bank_Details__c bank : banksToBeInserted){
                if(bank.Project_Name__r.record_sync__c==true){
                    beneficiary.projectId = bank.Project_Name__c!=null ? bank.Project_Name__r.Project_Id__c  :'';
                }else{
                    beneficiary.projectId = bank.Project_Name__c!=null ? bank.Project_Name__r.APF_ID__c  :'';
                }
                beneficiary.ifsc = bank.Bank_Master__c!=null ? String.isNotBlank(bank.Bank_Master__r.IFSC__c) ?  bank.Bank_Master__r.IFSC__c : '' : '';
                beneficiary.bankCode = bank.Bank_Master__c!=null ? String.isNotBlank(bank.Bank_Master__r.Bank_Code__c) ?  bank.Bank_Master__r.Bank_Code__c : '' : '';
                beneficiary.branchCode = bank.Bank_Master__c!=null ? String.isNotBlank(bank.Bank_Master__r.Branch_Code__c) ?  bank.Bank_Master__r.Branch_Code__c : '' : '';
                beneficiary.acHolderName = String.isNotBlank(bank.Account_Holder_Name__c) ? bank.Account_Holder_Name__c : '';
                beneficiary.accountNo = String.isNotBlank(bank.Account_Number__c) ? bank.Account_Number__c : ''; 
            }
        }
        
        return new Map<String, List<String>> {'json' => new List<String> { JSON.serialize(beneficiary) }};
     }    

    public class CreateBeneficiaryWrapper{
        public String projectId;    //##GFL Identity##
        public String ifsc; //##IFSC code##
        public String bankCode; //##Bank Code##
        public String branchCode;   //
        public String acHolderName; //##Beneficiary name##
        public String accountNo;    //##Account Number##
    
    }
    public class DeleteBeneficiaryWrapper{
        public String beneficiaryID;
    }
    public static CreateBeneficiaryWrapper parse(String json){
        return (CreateBeneficiaryWrapper) System.JSON.deserialize(json, CreateBeneficiaryWrapper.class);
    }
    /*public static DeleteBeneficiaryWrapper parse(String json){
        return (DeleteBeneficiaryWrapper) System.JSON.deserialize(json, DeleteBeneficiaryWrapper.class);
    }*/
    
   
}