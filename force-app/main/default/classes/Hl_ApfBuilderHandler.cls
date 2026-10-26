/*
Description : TO handle Create Update callout for Builder Group in APF
*/
public without sharing class Hl_ApfBuilderHandler {

    
    public class BuilderCalloutInput {
        @InvocableVariable(label='Operation Type' required=true)
        public String operationType;
        @InvocableVariable(label='Builder Record Id' required=true)
        public String builderRecordId;
    }

    @InvocableMethod(label='Initiate Builder API Callout')
    public static void initiateCallout(List<BuilderCalloutInput> inputList) {
        if (inputList == null || inputList.isEmpty()) {
            return;
        }

        Map<String, String> inputMap = new Map<String, String>();
        Set<Id> builderIds = new Set<Id>();

        for (BuilderCalloutInput input : inputList) {
            if (input != null && String.isNotBlank(input.builderRecordId) && String.isNotBlank(input.operationType)) {
                inputMap.put('opr', input.operationType); // 'opr' → insert/update
                builderIds.add((Id)input.builderRecordId);
            }
            system.debug('####1:'+builderIds);
        }

        if (!builderIds.isEmpty()) {
            List<Builder__c> builderRecords = [SELECT Id, Name,record_sync__c, RecordTypeId,Builder_Group_ID__c, Sync_Error__c, Builder_ID__c, Segmentation__c, Record_Status__c, Exposure_Limit_On_Amount__c, Exposure_Limit_On_No_Of_Units__c, Pincode_Master__c, Pincode_Master__r.Name, Pincode_Master__r.City__c, Pincode_Master__r.City__r.City_Code__c, Pincode_Master__r.City__r.State__c,Group_Id__c FROM Builder__c WHERE Id IN :builderIds
            ];
            try{
            if (!builderRecords.isEmpty()) {
                Hl_ApfBuilderHandler.initiateApfBuilderCallout(inputMap, builderRecords);
            }
            }catch(Exception e){
                Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'Hl_ApfBuilderHandler', '', '') });
            }
        }
    }



    /*Map<String,String> inputMap = new Map<String,String>{'opr'=> 'insert'};
    List<Builder__c> builderList = new List<Builder__c>();
    Builder__c bui = new Builder__c();
    bui.Name = 'Test';
    builderList.add(bui);
    String payload = initiateApfBuilderCallout(inputMap, builderList);*/
    
    public static void initiateApfBuilderCallout( Map<String,String> inputMap, List<Builder__c> builderObjList){
        Integration_Settings__c apiAPF = Integration_Settings__c.getValues('update_plf_master');
        Http http = new Http();
        HttpRequest httpReq = new  HttpRequest();
        String endpoint = apiAPF.Endpoint__c; //'https://uat-hl-sf.godrejhf.com/v1/updateplfmaster'
        String bearer = Utility.getAccessToken();
        System.debug('Token:::'+bearer);
        httpReq.setEndpoint( endpoint );
        httpReq.setMethod( 'POST' );
       // httpReq.setHeader('Cookie', apiAPF.Cookie__c);
        httpReq.setHeader( 'Content-Type', 'application/json' );
        httpReq.setHeader('Authorization','Bearer '+bearer);
        List<Integration_Details__c> integrationList = new List<Integration_Details__c>();
        Map<String,List<String>> jsonPlusErrorMap =new Map<String,List<String>>();
        jsonPlusErrorMap = builderApexToJson(inputMap, builderObjList); // 'insert', 'update' builderObjList > ReCordType : Group
        for (Builder__c builderObj : builderObjList) {
        List<String> payload = new List<String>();
        if(builderObj.record_sync__c==true){
            payload = jsonPlusErrorMap.get(builderObj.Group_Id__c);
        }else{
            payload = jsonPlusErrorMap.get(builderObj.Builder_Group_ID__c);
        }
        HttpResponse httpRes;
        System.debug('Opr::'+inputMap.get('opr'));
        if(String.isNotBlank(payload[0])) 
        {
            httpReq.setBody(payload[0]);
            httpReq.setTimeout(100000);
            httpRes = http.send( httpReq );
            System.debug('Response:'+httpRes.getBody());
                                                  
        }
        System.debug(payload[0]);
        
        Integration_Details__c integration = new Integration_Details__c();
        integration.Process_Name__c ='Group ' + inputMap.get('opr');
        integration.Name = 'APF Callout Event - Group ' + inputMap.get('opr');
        integration.Endpoint__c = endpoint; 
        integration.Object_Name__c = 'BuilderGroup';
        integration.Related_Record_Id__c = builderObj.Id; 
        integration.Group_or_Company__c = builderObj.Id;
        integration.Communication_Status__c = 'Published';
        integration.Request_JSON__c = payload[0];
        integration.Response_JSON__c = httpRes!=null && httpRes.getBody() !=null ? httpRes.getBody() :'';
        integration.Is_Sync__c =(httpRes.getBody().contains('Rows inserted :1') || httpRes.getBody().contains('Rows updated :1'));
        integrationList.add(integration);
        payload.clear();
        }
        insert integrationList;
        
        //return payload[0];
    }
    
    public static Map<String, List<String>> builderApexToJson(Map<String, String> inputMap, List<Builder__c> builderList) {
        
        List<Rows> rowList;
        List<Integration_Details__c> lstIntD = new List<Integration_Details__c>();
        Map<String, List<String>> JsonMap = new Map<String, List<String>>();
        Map<String, String> columnMap = new Map<String, String>{'id' => 'int','name' => 'varchar','segmentation' => 'varchar','version' => 'Int','lastmntby' => 'int', 'lastmnton' => 'timestamp', 'recordstatus' => 'varchar', 'workflowid' => 'int', 'city' => 'varchar', 'province' => 'varchar', 'pincodeid' => 'int', 'explmtonamt' => 'int', 'explmtonnoofunits' => 'int'};
        List<Columns> columnList;
        for (Builder__c builderObj : builderList) {
            BuilderGroupRequestWrapper unit = new BuilderGroupRequestWrapper();
             rowList = new List<Rows>();
            columnList = new List<Columns>();
            unit.templateId = 'tid_builderGrp'; //static
            unit.opr = inputMap.get('opr');
            if(!inputMap.isEmpty() && inputMap.get('opr') =='update'){
                lstIntD = [Select id,is_sync__c,Process_Name__c from integration_details__c where (Related_Record_Id__c =:builderList[0].id and Process_Name__c ='Group insert' and is_sync__c = true) order by createddate DESC limit 1];
                if(!lstIntD.isEmpty()){
                    unit.opr = (!lstIntD[0].is_sync__c)?'insert':'update';
                    inputMap.put('opr',unit.opr);
                }else{
                    unit.opr = (builderList[0].record_sync__c)?'update':'insert';
                    inputMap.put('opr',unit.opr);
                }
            }

        
            for(String columnKey : columnMap.keySet()){
                Columns column = new Columns();
                column.columnName = columnKey;
                column.dataType = columnMap.get(columnKey);
                columnList.add(column);
            }
            unit.columns = columnList;

        
            Rows row = new Rows();
            if(builderObj.record_sync__c==true){
            row.id = String.isNotBlank(builderObj.Group_Id__c) ? builderObj.Group_Id__c : '';
            }else{
            row.id = String.isNotBlank(builderObj.Builder_Group_ID__c) ? builderObj.Builder_Group_ID__c : '';
            }
            row.name = String.isNotBlank(builderObj.Name) ? builderObj.Name :'';
            row.segmentation = String.isNotBlank(builderObj.Segmentation__c) ? builderObj.Segmentation__c : '';
            row.version  = '1';
            row.lastmntby = '1';
            row.lastmnton = '';
            row.recordstatus =String.isNotBlank(builderObj.Record_Status__c) ?builderObj.Record_Status__c : '';
            row.workflowid = '0';
            row.city = builderObj.Pincode_Master__c!=null && builderObj.Pincode_Master__r.City__c!=null && String.isNotBlank(builderObj.Pincode_Master__r.City__r.City_Code__c) ? builderObj.Pincode_Master__r.City__r.City_Code__c : '';
            row.province = builderObj.Pincode_Master__c!=null && builderObj.Pincode_Master__r.City__c!=null && String.isNotBlank(builderObj.Pincode_Master__r.City__r.State__c) ? builderObj.Pincode_Master__r.City__r.State__c : '';
            row.pincodeid = builderObj.Pincode_Master__c!=null && String.isNotBlank(builderObj.Pincode_Master__r.Name) ? builderObj.Pincode_Master__r.Name : '';
            row.explmtonamt = builderObj.Exposure_Limit_On_Amount__c!=null ? String.valueOf(Utility.addTwoZeros(Decimal.valueOf(builderObj.Exposure_Limit_On_Amount__c))) : '';
            row.explmtonnoofunits = builderObj.Exposure_Limit_On_No_Of_Units__c!=null ? String.valueOf(builderObj.Exposure_Limit_On_No_Of_Units__c) : '';
            rowList.add(row);
             unit.rows = rowList;
                JsonMap.put(row.id, new List<String>{ JSON.serialize(unit) });
        }
        return JsonMap;
    }
       

    public class BuilderGroupRequestWrapper{
    public String templateId;   //tid_builderGrp
    public String opr;  //insert
    public Columns[] columns;
    public Rows[] rows;
    }
    class Columns {
        public String columnName;   //id
        public String dataType; //int
    }
    class Rows {
        public String id;   //##ID##
        public String name; //##Builder Group Name##
        public String segmentation; //##Segmentation##
        public String version;  //1
        public String lastmntby;    //1509
        public String lastmnton;    //##Date##
        public String recordstatus; //Approved
        public String workflowid;   //0
        public String city; //##City##
        public String province; //##State##
        public String pincodeid;    //##Pincode ID##
        public String explmtonamt;  //##Exposure Amount Invisible##
        public String explmtonnoofunits;    //##Exposure Limit (Units)##
    }
}