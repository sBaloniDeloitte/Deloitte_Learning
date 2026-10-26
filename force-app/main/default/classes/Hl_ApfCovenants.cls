public with sharing class Hl_ApfCovenants {

    public class CovenantCalloutInput {
        @InvocableVariable(label='Operation Type' required=true)
        public String operationType;
        @InvocableVariable(label='Covenant Record Id' required=true)
        public String covenantRecordId;
    }
    
    @InvocableMethod(label='Initiate Create Covenants API Callout')
    public static void initiateCovenantCallout(List<CovenantCalloutInput> inputList) {
        Map<String, String> inputMap = new Map<String, String>();
        Set<Id> covenantIds = new Set<Id>();

        for (CovenantCalloutInput input : inputList) {
            if (input != null && String.isNotBlank(input.covenantRecordId) && String.isNotBlank(input.operationType)) {
                inputMap.put('opr', input.operationType); 
                covenantIds.add((Id)input.covenantRecordId);
            }
        }
        List<Builder_Project_Document__c> covenantDetailsRecords = [SELECT Id, Name,Project__c, Project__r.APF_ID__c, Covenant_Type__c,version__c,Covenant_Master__r.name, Last_Modified_By__c,Last_Modified_On__c, Covenant_Master__r.recordstatus__c, Covenant_Master__r.rolecode__c,Covenant_Master__r.nextrolecode__c, Covenant_Master__r.taskid__c , Covenant_Master__r.nexttaskid__c, Covenant_Master__r.workflowid__c, Covenant_Master__r.recordtype__c, Remarks__c FROM Builder_Project_Document__c where ID IN :covenantIds];
        Hl_ApfCovenants.initiateApfCovenantsCallout(inputMap,covenantDetailsRecords);
    }
    
    public static string initiateApfCovenantsCallout(Map<String,String> inputMap, List<Builder_Project_Document__c> covenantDetailsRecords)
    { 
        List<String> payload = new List<String>();
        HttpResponse httpRes=null;
        if (!covenantDetailsRecords.isEmpty()) {
            
            Integration_Settings__c apiAPF = Integration_Settings__c.getValues('APF_Covenants');
            
            if(apiAPF!=null){
                Http http = new Http();
                HttpRequest httpReq = new  HttpRequest();
                String endpoint = apiAPF.Endpoint__c;
                String bearer = Utility.getAccessToken();
                httpReq.setHeader('Authorization','Bearer '+bearer);
                httpReq.setEndpoint( endpoint );
                httpReq.setMethod( 'POST' );
                httpReq.setHeader( 'Content-Type', 'application/json' );
                Map<String,List<String>> jsonPlusErrorMap = covenantApexToJson(inputMap, covenantDetailsRecords); // 'insert', 'update' builderObjList > ReCordType : COMPANY
                payload = jsonPlusErrorMap.get('json');
                System.debug('Payload :'+payload[0]);
                if(String.isNotBlank(payload[0])){
                    httpReq.setBody(payload[0]);
                    httpReq.setTimeout(100000);
                    httpRes = http.send( httpReq );
                    System.debug('Response Body:'+httpRes.getBody());
                }
                // Added by Anand Walimbe
                List<Integration_Details__c> integrationList = new List<Integration_Details__c>();
                Integration_Details__c integration = new Integration_Details__c();
                integration.Name = 'APF - Project Covenant Document - ' +inputMap.get('opr');
                integration.Process_Name__c ='CovenantDocument-'+inputMap.get('opr');
                integration.Object_Name__c='Project Covenant Document';
                integration.Endpoint__c = endpoint; 
                integration.Related_Record_Id__c = covenantDetailsRecords[0].id; 
                integration.Project_Covenant_Document__c = covenantDetailsRecords[0].id;
                integration.Communication_Status__c = 'Published';
                integration.Request_JSON__c = payload[0];
                integration.Response_JSON__c = httpRes!=null && httpRes.getBody() !=null ? httpRes.getBody() :'';
                integration.Is_Sync__c =(httpRes.getBody().contains('Rows inserted :1') || httpRes.getBody().contains('Rows updated :1'));
                integrationList.add(integration);
                insert integrationList;
                // End
                System.debug(payload[0]);
                System.debug('Integration List:'+integrationList);
            }
            return payload.size()>0 ? payload[0] : 'payload Empty';
        }
        return 'payload Empty';
    }

    
    public static Map<String, List<String>> covenantApexToJson(Map<String, String> inputMap, List<Builder_Project_Document__c> covenantDocuments) {
        CreateCovenantWrapper covenan = new CreateCovenantWrapper();
        List<Integration_Details__c> lstIntD = new List<Integration_Details__c>();
        covenan.templateId = 'tid_builderPrjCvntTypes'; 
        covenan.opr = inputMap.get('opr');
         if(!inputMap.isEmpty() && inputMap.get('opr') =='update'){
            lstIntD = [Select id,is_sync__c,Process_Name__c from integration_details__c where Related_Record_Id__c =:covenantDocuments[0].id and Process_Name__c ='CovenantDocument-insert' order by createddate DESC limit 1];
            if(!lstIntD.isEmpty()){
                covenan.opr = (!lstIntD[0].is_sync__c)?'insert':'update';
                inputMap.put('opr',covenan.opr);
            }else{
                covenan.opr = 'insert';
                inputMap.put('opr',covenan.opr);
            }
        }
        Map<String, String> columnMap = new Map<String, String>{'id' => 'int','builderprjid' => 'int','covenanttypeid' => 'int','version' => 'Int','lastmntby' => 'int','lastmnton' => 'timestamp','recordstatus' => 'varchar','workflowid' => 'int','rolecode' => 'varchar','nextrolecode' => 'varchar','nexttaskid' => 'int','recordtype' => 'int','remarks' => 'varchar'};
        
        List<Columns> columnList = new List<Columns>();
        for(String columnKey : columnMap.keySet()){
            Columns column = new Columns();
            column.columnName = columnKey;
            column.dataType = columnMap.get(columnKey);
            columnList.add(column);
        }
        covenan.columns = columnList;

        List<Rows> rowList = new List<Rows>();
        for (Builder_Project_Document__c docsObj : covenantDocuments) {
            Rows row = new Rows();
            row.id = String.isNotBlank(docsObj.Name) ? docsObj.Name : '';   
            row.builderprjid = String.isNotBlank(docsObj.Project__r.APF_ID__c) ? docsObj.Project__r.APF_ID__c : '';   
            row.covenanttypeid =  docsObj.Covenant_Master__r.name!= null ? docsObj.Covenant_Master__r.name : ''; 
            row.version = String.valueOf(docsObj.Version__c);  
            row.lastmntby = '1000';//docsObj.Last_Modified_By__c; 
            row.lastmnton = String.valueof(system.now());   
            row.recordstatus =  String.isNotBlank(docsObj.Covenant_Master__r.recordstatus__c) ?docsObj.Covenant_Master__r.recordstatus__c : 'Approved';   
            row.rolecode = String.isNotBlank(docsObj.Covenant_Master__r.rolecode__c)?docsObj.Covenant_Master__r.rolecode__c:'0';  
            row.nextrolecode = String.isNotBlank(docsObj.Covenant_Master__r.nextrolecode__c)?docsObj.Covenant_Master__r.nextrolecode__c:'0';//docsObj.Covenant_Master__r.nextrolecode__c;  
            row.taskid = String.isNotBlank(docsObj.Covenant_Master__r.taskid__c)?docsObj.Covenant_Master__r.taskid__c:'0';//docsObj.Covenant_Master__r.taskid__c;   
            row.nexttaskid = String.isNotBlank(docsObj.Covenant_Master__r.nexttaskid__c)?docsObj.Covenant_Master__r.nexttaskid__c:'0';//docsObj.Covenant_Master__r.nexttaskid__c;   
            row.recordtype = String.isNotBlank(docsObj.Covenant_Master__r.recordtype__c)?docsObj.Covenant_Master__r.recordtype__c:'0';//docsObj.Covenant_Master__r.recordtype__c;   
            row.workflowid = (String.valueOf(docsObj.Covenant_Master__r.workflowid__c) != null)?String.valueOf(docsObj.Covenant_Master__r.workflowid__c):'0';//String.valueOf(docsObj.Covenant_Master__r.workflowid__c);  
            row.remarks = String.isNotBlank(docsObj.Remarks__c)?(String.valueOf(docsObj.Remarks__c)):'';
            
            rowList.add(row);
        }

        covenan.rows = rowList;

        return new Map<String, List<String>> {'json' => new List<String> { JSON.serialize(covenan) }
        };
    }
    

    public class CreateCovenantWrapper{
        public String templateId;   //tid_builderPrjCvntTypes
        public String opr;  //insert
        public columns[] columns;
        public rows[] rows;
    }
    class Columns {
            public String columnName;   //id
            public String dataType; //int
    }
    class Rows {
            public String id;   //153
            public String builderprjid; //60
            public String covenanttypeid;   //23
            public String version;  //1
            public String lastmntby;    //1509
            public String lastmnton;    //30/08/2025
            public String recordstatus; //Approved
            public String rolecode; //
            public String nextrolecode; //
            public String taskid;   //
            public String nexttaskid;   //
            public String recordtype;   //
            public String workflowid;   //0
            public String remarks;  //Test Aditya
    }
}