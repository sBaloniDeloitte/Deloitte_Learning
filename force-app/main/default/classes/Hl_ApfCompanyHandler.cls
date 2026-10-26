/*
TO handle APF company callouts
*/
public without sharing class Hl_ApfCompanyHandler{

    public class CompanyCalloutInput {
        @InvocableVariable(label='Operation Type' required=true)
        public String operationType;
        @InvocableVariable(label='Builder Record Id' required=true)
        public String builderRecordId;
    }

    @InvocableMethod(label='Initiate Company API Callout')
    public static void initiateCallout(List<CompanyCalloutInput> inputList) {
        if (inputList == null || inputList.isEmpty()) {
            return;
        }

        Map<String, String> inputMap = new Map<String, String>();
        Set<Id> builderIds = new Set<Id>();

        for (CompanyCalloutInput input : inputList) {
            if (input != null && String.isNotBlank(input.builderRecordId) && String.isNotBlank(input.operationType)) {
                inputMap.put('opr', input.operationType); // 'opr' → insert/update
                builderIds.add((Id)input.builderRecordId);
            }
        }

        if (!builderIds.isEmpty()) {
            List<Builder__c> builderRecords = [SELECT Id, Name,entity_type__c,record_sync__c, Req_ID__c,RecordTypeId,Builder_ID__c, Builder_Group_ID__c, Segmentation__c, Builders_Group__c, Builders_Group__r.Builder_ID__c,Builders_Group__r.record_sync__c ,Record_Status__c, Email__c, Address_1__c, Address_2__c, Address_3__c, Pincode_Master__c, Pincode_Master__r.Name, Pincode_Master__r.City__c, Pincode_Master__r.City__r.City_Code__c, Pincode_Master__r.City__r.State__c, Approved__c, Remarks__c, Beneficiary_Name__c, Account_Number__c, Limit_on_Amount__c, Limit_on_Unit__c, Current_Exposure_Units__c, Current_Exposure_Amount__c, Date_of_Incorporation__c, Experience_in_Business__c, Recommendation__c, Active__c, No_of_Projects__c, Magnitude_in_lacs__c,Group_Id__c,Company_ID__c,Builders_Group__r.Group_Id__c FROM Builder__c WHERE Id IN :builderIds
            ];
            System.debug('Record::'+builderRecords);
            try{
            if (!builderRecords.isEmpty()) {
                Hl_ApfCompanyHandler.initiateApfCompanyCallout(inputMap, builderRecords);
            }
             }catch(Exception e){
                Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'Hl_ApfCompanyHandler', '', '') });
            }
        }
    }
    /*
    Map<String,String> inputMap = new Map<String,String>{'opr'=> 'insert'};
    List<Builder__c> builderList = new List<Builder__c>();
    Builder__c bui = new Builder__c();
    bui.Name = 'Test';
    builderList.add(bui);
    String payload = initiateApfCompanyCallout(inputMap, builderList);*/

    public static void initiateApfCompanyCallout(Map<String,String> inputMap, List<Builder__c> builderObjList){
        Integration_Settings__c apiAPF = Integration_Settings__c.getValues('update_plf_master');
        Http http = new Http();
        HttpRequest httpReq = new  HttpRequest();
        String bearer = Utility.getAccessToken();
        System.debug('Token:::'+bearer);
        String endpoint = apiAPF.Endpoint__c;
        httpReq.setEndpoint( endpoint );
        httpReq.setMethod( 'POST' );
        httpReq.setHeader( 'Content-Type', 'application/json' );
        httpReq.setHeader('Authorization','Bearer '+bearer);
        List<Integration_Details__c> integrationList = new List<Integration_Details__c>();
        Map<String,List<String>> jsonPlusErrorMap =new Map<String,List<String>>();
        jsonPlusErrorMap = companyApexToJson(inputMap, builderObjList); // 'insert', 'update' builderObjList > ReCordType : Group
        for (Builder__c builderObj : builderObjList) {
            List<String> payload = new List<String>();
            if(builderObj.record_sync__c==true){
                payload = jsonPlusErrorMap.get(builderObj.Company_ID__c);
            }else{
                payload = jsonPlusErrorMap.get(builderObj.Req_ID__c);
            }
        HttpResponse httpRes;
            if(String.isNotBlank(payload[0])){
                httpReq.setBody(payload[0]);
                httpReq.setTimeout(100000);
                httpRes = http.send( httpReq );
                System.debug(httpRes.getBody());
            }
            System.debug(payload[0]);
            
            Integration_Details__c integration = new Integration_Details__c();
            integration.Name = 'APF Callout Event - Company ' + inputMap.get('opr');
            integration.Process_Name__c ='Company ' + inputMap.get('opr');
            integration.Object_Name__c='Builder Company';
            integration.Endpoint__c = endpoint; 
            integration.Related_Record_Id__c = builderObjList[0].Id; 
            integration.Group_or_Company__c = builderObjList[0].Id;
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

    public static Map<String, List<String>> companyApexToJson(Map<String, String> inputMap, List<Builder__c> BuilderList) {
        List<Integration_Details__c> lstIntD = new List<Integration_Details__c>();
        List<Rows> rowList;
        List<Columns> columnList;
        Map<String, String> columnMap = new Map<String, String>{'id' => 'int','name' => 'varchar','segmentation' => 'varchar','groupid' => 'int','version' => 'Int','lastmntby' => 'int','lastmnton' => 'timestamp','recordstatus' => 'varchar','rolecode' => 'varchar','nextrolecode' => 'varchar','taskid' => 'varchar','nexttaskid' => 'varchar','recordtype' => 'varchar','workflowid' => 'int','custid' => 'int','apftype' => 'int','pedevid' => 'varchar','entitytype' => 'varchar','emailid' => 'varchar','citytype' => 'varchar','address1' => 'varchar','address2' => 'varchar','address3' => 'varchar','city' => 'varchar','code' => 'varchar','devavailablity' => 'int','magnitude' => 'int','absavailablity' => 'int','totalproj' => 'int','approved' => 'varchar','remarks' => 'varchar','pandetails' => 'varchar','benfname' => 'varchar','accountno' => 'varchar','bankbranchid' => 'int','limitonamt' => 'int','limitonunits' => 'int','currentexpuni' => 'int','currentexpamt' => 'int','dateofincop' => 'timestamp','asshlplayers' => 'int','ongoingproj' => 'int','expinbusiness' => 'int','recommendation' => 'varchar','active' => 'int','noofprojcons' => 'int','noofproj' => 'int','magintudeinlacs' => 'int','state' => 'varchar'};
        Map<String, List<String>> JsonMap = new Map<String, List<String>>();
         for (Builder__c builderObj : BuilderList) {
            BuilderCompanyRequestWrapper company = new BuilderCompanyRequestWrapper();
            rowList = new List<Rows>();
            columnList = new List<Columns>();
        company.templateId = 'tid_builderCompany'; //static
        company.opr = inputMap.get('opr');
         if(!inputMap.isEmpty() && inputMap.get('opr') =='update'){
            lstIntD = [Select id,is_sync__c,Process_Name__c from integration_details__c where Related_Record_Id__c =:builderList[0].id and is_sync__c = true order by createddate DESC limit 1];
            if(!lstIntD.isEmpty()){
                company.opr = (!lstIntD[0].is_sync__c && lstIntD[0].Process_Name__c =='Company insert')?'insert':'update';
            }else{
                 company.opr = (builderList[0].record_sync__c)?'update':'insert';
                inputMap.put('opr',company.opr);
            }
            
        }
        for(String columnKey : columnMap.keySet()){
            Columns column = new Columns();
            column.columnName = columnKey;
            column.dataType = columnMap.get(columnKey);
            columnList.add(column);
        }
        company.columns = columnList;

       
            Rows row = new Rows();
            if(builderObj.record_sync__c==true){
                row.id = String.isNotBlank(String.valueOf(builderObj.Company_ID__c)) ? String.valueOf(builderObj.Company_ID__c) : '';   //##Identity## 
            //row.groupid = builderObj.Builders_Group__r.Group_Id__c!=null && String.isNotBlank(builderObj.Builders_Group__r.Group_Id__c) ? builderObj.Builders_Group__r.Group_Id__c : '';    //##Builder Group Identity##
            }else{
                row.id = String.isNotBlank(String.valueOf(builderObj.Req_ID__c)) ? String.valueOf(builderObj.Req_ID__c) : ''; 
            }  //##Identity## 
            if(builderObj.Builders_Group__r.record_sync__c==true){
                row.groupid = builderObj.Builders_Group__r.Group_Id__c!=null && String.isNotBlank(builderObj.Builders_Group__r.Group_Id__c) ? builderObj.Builders_Group__r.Group_Id__c : '';    //##Builder Group Identity##
            }else{
                row.groupid = builderObj.Builders_Group__r.Builder_ID__c!=null && String.isNotBlank(builderObj.Builders_Group__r.Builder_ID__c) ? builderObj.Builders_Group__r.Builder_ID__c : '';    //##Builder Group Identity##
            }
            
            row.name = String.isNotBlank(builderObj.Name) ? builderObj.Name : '';   //##Builder Company Name##
            row.segmentation =  builderObj.Segmentation__c!= null ? builderObj.Segmentation__c : ''; //##Segmentation##
            //row.groupid = builderObj.Builder_Group_ID__c!=null && String.isNotBlank(builderObj.Builder_Group_ID__c) ? builderObj.Builder_Group_ID__c : '';    //##Builder Group Identity##
            row.version = '1';  //1
            row.lastmntby = '1509'; //1509
            row.lastmnton = String.valueOf(System.now());   //2021-06-23 19:01:06
            row.recordstatus =  String.isNotBlank(builderObj.Record_Status__c) ?builderObj.Record_Status__c : '';   //Approved
            row.rolecode = '';  //
            row.nextrolecode = '';  //
            row.taskid = '';    //
            row.nexttaskid = '';    //
            row.recordtype = '';    //
            row.workflowid = '0';   //0
            row.custid = '0';   //0
            row.apftype= '0';   //0
            row.pedevid=''; //
            row.entitytype = String.isNotBlank(builderObj.entity_type__c) ?builderObj.entity_type__c : '';    //LLP
            row.emailid = String.isNotBlank(builderObj.Email__c) ?builderObj.Email__c : ''; //
            row.citytype = '';  // City_Type__c
            row.address1 =  String.isNotBlank(builderObj.Address_1__c) ?builderObj.Address_1__c : '';   //##Address Line1##
            row.address2 = String.isNotBlank(builderObj.Address_2__c) ?builderObj.Address_2__c : '';    //##Address Line2##
            row.address3 = String.isNotBlank(builderObj.Address_3__c) ?builderObj.Address_3__c : '';    //##Address Line3##
            row.city = builderObj.Pincode_Master__c!=null && builderObj.Pincode_Master__r.City__c!=null && String.isNotBlank(builderObj.Pincode_Master__r.City__r.City_Code__c) ? builderObj.Pincode_Master__r.City__r.City_Code__c : '';   //##City##
            //row.pincode = builderObj.Pincode_Master__c!=null && builderObj.Pincode_Master__r.City__c!=null && String.isNotBlank(builderObj.Pincode_Master__r.City__r.City_Code__c) ? builderObj.Pincode_Master__r.City__r.City_Code__c : '';   //##Pincode##
            row.devavailablity ='0';    //0
            row.magnitude ='0'; //0
            row.absavailablity ='0';    //0
            row.totalproj ='0'; //0
            row.approved = builderObj.Approved__c!=null && builderObj.Approved__c == 'Yes' ?  'Y' : 'N';//Y 
            row.remarks = String.isNotBlank(builderObj.Remarks__c) ?builderObj.Remarks__c : ''; // 
            row.pandetails =''; //
            row.benfname = String.isNotBlank(builderObj.Beneficiary_Name__c) ?builderObj.Beneficiary_Name__c : ''; // 
            row.accountno = builderObj.Account_Number__c!=null ?  String.valueOf(builderObj.Account_Number__c) : '';//
            row.bankbranchid = '0'; //0
            row.limitonamt = builderObj.Limit_on_Amount__c!=null ?  String.valueOf(builderObj.Limit_on_Amount__c) : '0';    //0 
            row.limitonunits = builderObj.Limit_on_Unit__c!=null ?  String.valueOf(builderObj.Limit_on_Unit__c) : '0';  //0 
            row.currentexpuni = builderObj.Current_Exposure_Units__c!=null ?  String.valueOf(builderObj.Current_Exposure_Units__c) : '0';//0 
            row.currentexpamt = builderObj.Current_Exposure_Amount__c!=null ?  String.valueOf(Utility.addTwoZeros(builderObj.Current_Exposure_Amount__c)) : '0';//0
            row.dateofincop = builderObj.Date_of_Incorporation__c!=null ?  String.valueOf(builderObj.Date_of_Incorporation__c) : '';//2021-06-23 19:01:06
            row.asshlplayers = '0'; //0
            row.ongoingproj = '0';  //0
            row.expinbusiness = builderObj.Experience_in_Business__c!=null ?  String.valueOf(builderObj.Experience_in_Business__c) : '0'; //0 
            row.recommendation = String.isNotBlank(builderObj.Recommendation__c) ?builderObj.Recommendation__c : '';    //
            row.active = builderObj.Active__c!=null ?  String.valueOf(builderObj.Active__c) : '1';  //1
            row.noofprojcons = '0'; //0
            row.noofproj = builderObj.No_of_Projects__c!=null ?  String.valueOf(builderObj.No_of_Projects__c) : '0';    //0
            row.magintudeinlacs = builderObj.Magnitude_in_lacs__c!=null ? String.valueOf(builderObj.Magnitude_in_lacs__c) : '0';    //0
            row.state = builderObj.Pincode_Master__c!=null && builderObj.Pincode_Master__r.City__c!=null && String.isNotBlank(builderObj.Pincode_Master__r.City__r.State__c) ? builderObj.Pincode_Master__r.City__r.State__c : '';  //##State##
            row.code = builderObj.Pincode_Master__c!=null && String.isNotBlank(builderObj.Pincode_Master__r.Name) ? builderObj.Pincode_Master__r.Name : '';
            rowList.add(row);
            company.rows = rowList;
            JsonMap.put(row.id, new List<String>{ JSON.serialize(company) });
        }
        return JsonMap;
    }
       
    public class BuilderCompanyRequestWrapper{
    public String templateId;   //tid_builderCompany
    public String opr;  //insert
    public Columns[] columns;
    public Rows[] rows;
    }
    class Columns {
        public String columnName;   //id
        public String dataType; //int
    }
    class Rows {
        public String id;   //##Identity##
        public String name; //##Builder Company Name##
        public String segmentation; //##Segmentation##
        public String groupid;  //##Builder Group Identity##
        public String version;  //1
        public String lastmntby;    //1509
        public String lastmnton;    //2021-06-23 19:01:06
        public String recordstatus; //Approved
        public String rolecode; //
        public String nextrolecode; //
        public String taskid;   //
        public String nexttaskid;   //
        public String recordtype;   //
        public String workflowid;   //0
        public String custid;   //0
        public String apftype;  //0
        public String pedevid;  //
        public String entitytype;   //LLP
        public String emailid;  //
        public String citytype; //
        public String address1; //##Address Line1##
        public String address2; //##Address Line2##
        public String address3; //##Address Line3##
        public String city; //##City##
        //public String pincode; //##Pincode##
        public String devavailablity;   //0
        public String magnitude;    //0
        public String absavailablity;   //0
        public String totalproj;    //0
        public String approved; //Y
        public String remarks;  //
        public String pandetails;   //
        public String benfname; //
        public String accountno;    //
        public String bankbranchid; //0
        public String limitonamt;   //0
        public String limitonunits; //0
        public String currentexpuni;    //0
        public String currentexpamt;    //0
        public String dateofincop;  //2021-06-23 19:01:06
        public String asshlplayers; //0
        public String ongoingproj;  //0
        public String expinbusiness;    //0
        public String recommendation;   //
        public String active;   //1
        public String noofprojcons; //0
        public String noofproj; //0
        public String magintudeinlacs;  //0
        public String state;    //##State##
        public string code;
        //public string explmtonamt;
        public string explmtonnoofunits ;    
    }
    public static BuilderCompanyRequestWrapper parse(String json){
        return (BuilderCompanyRequestWrapper) System.JSON.deserialize(json, BuilderCompanyRequestWrapper.class);
    }
}