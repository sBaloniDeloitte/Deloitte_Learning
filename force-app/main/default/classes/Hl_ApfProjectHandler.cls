/*
TO handle APF Project callouts
*/
public without sharing class Hl_ApfProjectHandler{

    public static Set<Id> projectIds;
    public class ProjectCalloutInput {
        @InvocableVariable(label='Operation Type' required=true)
        public String operationType;
        @InvocableVariable(label='Project Record Id' required=true)
        public String projectRecordId;
    }

    @InvocableMethod(label='Initiate Project API Callout')
    public static void initiateCallout(List<ProjectCalloutInput> inputList) {
        if (inputList == null || inputList.isEmpty()) {
            return;
        }

        Map<String, String> inputMap = new Map<String, String>();
        projectIds = new Set<Id>();

        for (ProjectCalloutInput input : inputList) {
            if (input != null && String.isNotBlank(input.projectRecordId) && String.isNotBlank(input.operationType)) {
                inputMap.put('opr', input.operationType); // 'opr' → insert/update
                projectIds.add((Id)input.projectRecordId);
            }
        }

        if (!projectIds.isEmpty()) {
            List<Project__c> projectRecords = [SELECT Id, Name, Builder_Group__c, RecordTypeId, APF_ID__c,Builder_Master__c, Builder_Master__r.Builder_ID__c,APF_No__c,Record_Status__c,Address_Line_1__c,Address_Line_2__c,Address_Line_3__c,Landmark__c,Pincode__c,Pincode__r.City__c,Pincode__r.City__r.City_Code__c,
            Pincode__r.City__r.State__c,Pincode__r.Name,Project_Type__c,Types_Of_APF__c,Total_Units__c,Number_of_Towers__c,Project_Start_Date__c,Project_End_Date__c,Account_Number__c,New_APF_No__c,
            Remarks__c,Total_Plot_Area__c,company_request_Id__c,record_sync__c,Constructed_Area__c,Beneficiary_Name__c,IFSC__c,Project_Id__c,Builder_Master__r.Company_ID__c,Builder_Master__r.record_sync__c FROM Project__c WHERE Id IN :projectIds
            ];
            try{
            if (!projectRecords.isEmpty()) {
                Hl_ApfProjectHandler.initiateApfProjectCallout(inputMap, projectRecords);
            }
            }catch(Exception e){
                Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'Hl_ApfProjectHandler', '', '') });
            }
        }
    }


    /*
    Map<String,String> inputMap = new Map<String,String>{'opr'=> 'insert'};
    List<Project__c> projectList = new List<Project__c>();
    Project__c pro = new Project__c();
    pro.Name = 'Test';
    projectList.add(pro);
    String payload = initiateApfProjectCallout(inputMap, projectList);*/

    public static void initiateApfProjectCallout( Map<String,String> inputMap, List<Project__c> projectList){
        Integration_Settings__c apiAPF = Integration_Settings__c.getValues('update_plf_master');
        Http http = new Http();
        String bearer = Utility.getAccessToken();
        System.debug('Token:::'+bearer);
        HttpRequest httpReq = new  HttpRequest();
        String endpoint = apiAPF.Endpoint__c;
        httpReq.setEndpoint( endpoint );
        httpReq.setMethod( 'POST' );
        httpReq.setHeader( 'Content-Type', 'application/json' );
        httpReq.setHeader('Authorization','Bearer '+bearer);

        
        List<Integration_Details__c> integrationList = new List<Integration_Details__c>();
        Map<String,List<String>> jsonPlusErrorMap =new Map<String,List<String>>();
        jsonPlusErrorMap= projectApexToJson(inputMap, projectList); // 'insert', 'update' builderObjList > ReCordType : COMPANY
        for(Project__c proj:projectList){
        
        List<String> payload = new List<String>();
        if(proj.record_sync__c==true){
            payload = jsonPlusErrorMap.get(proj.Project_Id__c);
        }else{
            payload = jsonPlusErrorMap.get(proj.APF_ID__c);
        }
        HttpResponse httpRes;
        if(payload.size()>0 && String.isNotBlank(payload[0])){
            httpReq.setBody(payload[0]);
            httpReq.setTimeout(100000);
            httpRes = http.send( httpReq );
            System.debug(httpRes.getBody());
        }
       // System.debug(payload[0]);
        System.debug('HttpReq:::'+httpReq);
        
        Integration_Details__c integration = new Integration_Details__c();
        integration.Process_Name__c ='Project ' + inputMap.get('opr');
        integration.Name = 'APF Callout Event - Project ' + inputMap.get('opr');
        integration.Object_Name__c='Builder Project';
        integration.Endpoint__c = endpoint; 
        integration.Related_Record_Id__c = proj.Id; 
        integration.Project_or_Unit__c = proj.Id;
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

    public static Map<String, List<String>> projectApexToJson(Map<String, String> inputMap, List<Project__c> projectList) {
        List<Rows> rowList;
        List<Integration_Details__c> lstIntD = new List<Integration_Details__c>();
        Map<String, List<String>> JsonMap = new Map<String, List<String>>();
        Map<String, String> columnMap = new Map<String, String>{'id' => 'int','name' => 'varchar','builderid' => 'int','apfno' => 'varchar','version' => 'int','lastmntby' => 'int','lastmnton' => 'timestamp','recordstatus' => 'varchar','workflowid' => 'int','addressline1' => 'varchar','addressline2' => 'varchar','addressline3' => 'varchar','landmark' => 'varchar','city' => 'varchar','state' => 'varchar','pincode' => 'varchar','projecttype' => 'varchar','typesofapf' => 'varchar','totalunits' => 'int','numberoftowers' => 'int','projectstartdate' => 'timestamp','projectenddate' => 'timestamp','remarks' => 'varchar','totalplotarea' => 'int','constructedarea' => 'int','beneficiaryname' => 'varchar','ifsc' => 'varchar','accountno' => 'varchar'};
        List<Columns> columnList;

        Map<Id, integration_details__c> latestIntMap = new Map<Id, integration_details__c>();

        List<integration_details__c> intList = [
            SELECT Id, is_sync__c, Process_Name__c, Related_Record_Id__c, CreatedDate
            FROM integration_details__c
            WHERE Related_Record_Id__c IN :projectIds
            AND Process_Name__c = 'Project insert' AND is_sync__c = true
            ORDER BY CreatedDate DESC
        ];

        for (integration_details__c intRec : intList) {
            // Keep only latest record per Project
            if (!latestIntMap.containsKey(intRec.Related_Record_Id__c)) {
                latestIntMap.put(intRec.Related_Record_Id__c, intRec);
            }
        }

        for(Project__c proj : projectList){
            ProjectRequestWrapper project = new ProjectRequestWrapper();
            rowList = new List<Rows>();
            columnList = new List<Columns>();
            project.templateId = 'tid_builderProjcet'; //static
            project.opr = inputMap.get('opr');
            if(!inputMap.isEmpty() && inputMap.get('opr') =='update'){
                  integration_details__c intDet = latestIntMap.get(proj.Id);

                if (intDet != null) {
                    project.opr = (!intDet.is_sync__c) ? 'insert' : 'update';
                } else {
                    project.opr = (proj.record_sync__c) ? 'update' : 'insert';
                }

                inputMap.put('opr', project.opr);
            }
            for(String columnKey : columnMap.keySet()){
                Columns column = new Columns();
                column.columnName = columnKey;
                column.dataType = columnMap.get(columnKey);
                columnList.add(column);
            }
            project.columns = columnList;

                Rows row = new Rows();
                ////////////
                if(proj.record_sync__c==true){
                row.id = String.isNotBlank(proj.Project_Id__c) ? proj.Project_Id__c : '';   //##Identity##
                row.apfno = String.isNotBlank(proj.APF_No__c) ? proj.APF_No__c : '';
                }else{
                row.id = String.isNotBlank(proj.APF_ID__c) ? proj.APF_ID__c : '';   //##Identity##
                row.apfno = String.isNotBlank(proj.New_APF_No__c) ? proj.New_APF_No__c : '';
                }

                if(proj.Builder_Master__r.record_sync__c){
                   row.builderid = proj.Builder_Master__r.Company_ID__c!=null ? proj.Builder_Master__r.Company_ID__c : '';   //##Builder Company ID##

                }else{
                    row.builderid = proj.company_request_Id__c!=null ? proj.company_request_Id__c : '';   //##Builder Company ID##

                }
                row.name = String.isNotBlank(proj.Name) ? proj.Name : '';   //##Project Name##
               
            //  row.apfno = String.isNotBlank(proj.APF_No__c) ? proj.APF_No__c : '';    //##APF No##
                
                row.version = '1';  //1
                row.lastmntby = '1509'; //1509
                row.lastmnton =  String.valueOf(System.now());  //##Submitted Date##
                row.recordstatus = String.isNotBlank(proj.Record_Status__c) ?proj.Record_Status__c : '';    //Approved
                row.workflowid = '0';   //0
                row.addressline1 = String.isNotBlank(proj.Address_Line_1__c) ?proj.Address_Line_1__c : '';  //##Project Address line 1##
                row.addressline2 = String.isNotBlank(proj.Address_Line_2__c) ?proj.Address_Line_2__c : '';//##Project Address line 2##
                row.addressline3 = String.isNotBlank(proj.Address_Line_3__c) ?proj.Address_Line_3__c : '';  //##Project Address line 3##
                row.landmark = String.isNotBlank(proj.Landmark__c) ?proj.Landmark__c : '';  //##Landmark## 
                row.city = proj.Pincode__c!=null && proj.Pincode__r.City__c!=null && String.isNotBlank(proj.Pincode__r.City__r.City_Code__c) ? proj.Pincode__r.City__r.City_Code__c : '';   //##City##
                row.state = proj.Pincode__c!=null && proj.Pincode__r.City__c!=null && String.isNotBlank(proj.Pincode__r.City__r.State__c) ? proj.Pincode__r.City__r.State__c : '';//##State##
                row.pincode = proj.Pincode__c!=null ? proj.Pincode__r.Name : '';    //##Project Pincode##
                row.projecttype =  proj.Project_Type__c!=null ? proj.Project_Type__c : '';  //##Project Type##
                row.typesofapf = proj.Types_Of_APF__c!=null ? String.valueOf(proj.Types_Of_APF__c) : '';    //##APF Type## 
                row.totalunits = proj.Total_Units__c!=null ? String.valueOf(proj.Total_Units__c) : '';  //##Totals Approved Units## 
                row.numberoftowers = proj.Number_of_Towers__c!=null ? String.valueOf(proj.Number_of_Towers__c) : '';    //##Total no of Towers## 
                row.projectstartdate = proj.Project_Start_Date__c!=null ?(proj.Project_Start_Date__c).format('dd-MM-yyyy'):'';
                row.projectenddate = proj.Project_End_Date__c!=null ?(proj.Project_End_Date__c).format('dd-MM-yyyy'):'';
                //row.projectstartdate = proj.Project_Start_Date__c!=null ? DateTime.newInstance(proj.Project_Start_Date__c.year(), proj.Project_Start_Date__c.month(), proj.Project_Start_Date__c.day()).format('MMM dd, yyyy'): ''; //##Project start date## 
                //row.projectenddate = proj.Project_End_Date__c!=null ? DateTime.newInstance(proj.Project_End_Date__c.year(), proj.Project_End_Date__c.month(), proj.Project_End_Date__c.day()).format('MMM dd, yyyy') : '';  //##Project end date##
                row.remarks = String.isNotBlank(proj.Remarks__c) ? proj.Remarks__c : '';    //##Project Remarks##
                row.totalplotarea = proj.Total_Plot_Area__c!=null ? String.valueOf(proj.Total_Plot_Area__c) : '';//##Total Plot Area##
                row.constructedarea = proj.Constructed_Area__c!=null ? String.valueOf(proj.Constructed_Area__c) : '';//##Constructed Area## 
                row.beneficiaryname = String.isNotBlank(proj.Beneficiary_Name__c) ?proj.Beneficiary_Name__c : '';   //##Beneficiary name## 
                row.ifsc =  String.isNotBlank(proj.IFSC__c) ?proj.IFSC__c : ''; //##IFSC code##
                row.accountno = proj.Account_Number__c!=null ? String.valueOf(proj.Account_Number__c) : ''; //##Account Number## 

                ////////////
                rowList.add(row);
                project.rows = rowList;
                JsonMap.put(row.id, new List<String>{ JSON.serialize(project) });
            }
        return JsonMap;
    }
    public class ProjectRequestWrapper{
    public String templateId;   //tid_builderProjcet
    public String opr;  //update
    public Columns[] columns;
    public Rows[] rows;
    }
    class Columns {
        public String columnName;   //id
        public String dataType; //int
    }
    class Rows {
        public String id;   //##Identity##
        public String name; //##Project Name##
        public String builderid;    //##Builder Company ID##
        public String apfno;    //##APF No##
        public String version;  //1
        public String lastmntby;    //1509
        public String lastmnton;    //##Submitted Date##
        public String recordstatus; //Approved
        public String workflowid;   //0
        public String addressline1; //##Project Address line 1##
        public String addressline2; //##Project Address line 2##
        public String addressline3; //##Project Address line 3##
        public String landmark; //##Landmark##
        public String city; //##City##
        public String state;    //##State##
        public String pincode;  //##Project Pincode##
        public String projecttype;  //##Project Type##
        public String typesofapf;   //##APF Type##
        public String totalunits;   //##Totals Approved Units##
        public String numberoftowers;   //##Total no of Towers##
        public String projectstartdate; //##Project start date##
        public String projectenddate;   //##Project end date##
        public String remarks;  //##Project Remarks##
        public String totalplotarea;    //##Total Plot Area##
        public String constructedarea;  //##Constructed Area##
        public String beneficiaryname;  //##Beneficiary name##
        public String ifsc; //##IFSC code##
        public String accountno;    //##Account Number##
    }
    public static ProjectRequestWrapper parse(String json){
        return (ProjectRequestWrapper) System.JSON.deserialize(json, ProjectRequestWrapper.class);
    }
}