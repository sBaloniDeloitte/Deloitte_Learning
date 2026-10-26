public without sharing class Hl_ApfUnitHandler {
    public static Set<Id> projectIds;

    public class UnitCalloutInput {
        @InvocableVariable(label='Operation Type' required=true)
        public String operationType;
        @InvocableVariable(label='Project Record Id' required=true)
        public String projectRecordId;
    }

    @InvocableMethod(label='Initiate Unit API Callout')
    public static void initiateCallout(List<UnitCalloutInput> inputList) {
        if (inputList == null || inputList.isEmpty()) {
            return;
        }

        Map<String, String> inputMap = new Map<String, String>();
        projectIds = new Set<Id>();

        for (UnitCalloutInput input : inputList) {
            if (input != null && String.isNotBlank(input.projectRecordId) && String.isNotBlank(input.operationType)) {
                inputMap.put('opr', input.operationType); // 'opr' → insert/update
                projectIds.add((Id)input.projectRecordId);
            }
        }

        if (!projectIds.isEmpty()) {
            List<Project__c> projectRecords = [SELECT Id, Name,New_Price__c,record_sync__c, RecordTypeId,Unit_Project_ID__c, Unit_ID__c, Unit_Type__c, Tower__c,Project_Building__r.Name, Floor_Number__c, Rate__c, Price__c, Other_Charges__c, New_Total_Price_Excluding_GST__c, Plot_Area__c, Project__c,Project__r.APF_ID__c, Rate_Considered__c, Carpet_Area__c, Unit_Built_Up_Area__c, Super_Builtup_Area__c, Floor_Rise_Charges__c, Open_Car_Parking_Charges__c, GST__c, Remarks__c,Project_Building__r.Project__r.APF_ID__c,Project__r.Project_Id__c,UnitId__c,Project__r.record_sync__c FROM Project__c WHERE Id IN :projectIds
            ];
            try{
            if (!projectRecords.isEmpty()) {
                Hl_ApfUnitHandler.initiateApfUnitCallout(inputMap, projectRecords);
            }
            }catch(Exception e){
                Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'Hl_ApfUnitHandler', '', '') });
            }
        }
    }

    public static void initiateApfUnitCallout( Map<String,String> inputMap, List<Project__c> projectList){
        Integration_Settings__c apiAPF = Integration_Settings__c.getValues('update_plf_master');
        Http http = new Http();
        HttpRequest httpReq = new  HttpRequest();
        String endpoint = apiAPF.Endpoint__c; //'https://uat-hl-sf.godrejhf.com/v1/updateplfmaster'
        String bearer = Utility.getAccessToken();
        System.debug('Token:::'+bearer);
        httpReq.setEndpoint( endpoint );
        httpReq.setHeader('Authorization','Bearer '+bearer);
        httpReq.setMethod( 'POST' );
        httpReq.setHeader( 'Content-Type', 'application/json' );
        List<Integration_Details__c> integrationList = new List<Integration_Details__c>();
        Map<String,List<String>> jsonPlusErrorMap = new Map<String,List<String>>();
        jsonPlusErrorMap = unitApexToJson(inputMap, projectList); 
        // 'insert', 'update' builderObjList > ReCordType : Group
        for(Project__c proj:projectList){
        List<String> payload = new List<String>();
        //payload = jsonPlusErrorMap.get(proj.name);
         if(proj.record_sync__c==true){
            payload = jsonPlusErrorMap.get(proj.UnitID__c);
        }else{
            payload = jsonPlusErrorMap.get(proj.Unit_ID__c);
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
        integration.Name = 'APF Callout Event - Unit ' + inputMap.get('opr');
        integration.Process_Name__c ='Unit ' + inputMap.get('opr');
        integration.Endpoint__c = endpoint; 
        integration.Related_Record_Id__c = proj.Id; 
        integration.Communication_Status__c = 'Published';
        integration.Request_JSON__c = payload[0];
        integration.Project_or_Unit__c = proj.Id;
        integration.Response_JSON__c = httpRes!=null && httpRes.getBody() !=null ? httpRes.getBody() :'';
        integration.Is_Sync__c =(httpRes.getBody().contains('Rows inserted :1') || httpRes.getBody().contains('Rows updated :1'));
        integrationList.add(integration);
        payload.clear();
        }
        insert integrationList;
        //return payload[0];
    }
      

    public static Map<String, List<String>> unitApexToJson(Map<String, String> inputMap, List<Project__c> projectList) {
        List<Rows> rowList;
		Map<String, List<String>> JsonMap = new Map<String, List<String>>();
        List<Integration_Details__c> lstIntD = new List<Integration_Details__c>();
        Map<String, String> columnMap = new Map<String, String>{'unitid' => 'int','unitnumber' => 'varchar','unittype' => 'varchar','tower' => 'varchar','floornumber' => 'varchar','rate' => 'int','price' => 'int','othercharges' => 'int','totalprice' => 'int','unitplotarea' => 'int','projectid' => 'int','version' => 'int','lastmntby' => 'int','lastmnton' => 'timestamp','recordstatus' => 'varchar','workflowid' => 'int','rateconsidered' => 'varchar','carpetarea' => 'int','unitbuiltuparea' => 'int','unitsuperbuiltup' => 'int','floorrisecharges' => 'int','opencarparkingcharges' => 'int','gst' => 'int','remarks' => 'varchar'};
        List<Columns> columnList;
         Map<Id, integration_details__c> latestIntMap = new Map<Id, integration_details__c>();

        List<integration_details__c> intList = [
            SELECT Id, is_sync__c, Process_Name__c, Related_Record_Id__c, CreatedDate
            FROM integration_details__c
            WHERE Related_Record_Id__c IN :projectIds
            AND Process_Name__c = 'Unit insert' AND is_sync__c = true
            ORDER BY CreatedDate DESC
        ];
         for (integration_details__c intRec : intList) {
            // Keep only latest record per Project
            if (!latestIntMap.containsKey(intRec.Related_Record_Id__c)) {
                latestIntMap.put(intRec.Related_Record_Id__c, intRec);
            }
        }

        for(Project__c proj : projectList){
            UnitRequestWrapper unit = new UnitRequestWrapper();
            rowList = new List<Rows>();
            columnList = new List<Columns>();
            unit.templateId = 'tid_projectunits'; //static
            unit.opr = inputMap.get('opr');
            if(!inputMap.isEmpty() && inputMap.get('opr') =='update'){
                 integration_details__c intDet = latestIntMap.get(proj.Id);
                if (intDet != null) {
                    unit.opr = (!intDet.is_sync__c) ? 'insert' : 'update';
                } else {
                    unit.opr = (proj.record_sync__c) ? 'update' : 'insert';
                }

                inputMap.put('opr', unit.opr);
            }
           
            for(String columnKey : columnMap.keySet()){
                Columns column = new Columns();
                column.columnName = columnKey;
                column.dataType = columnMap.get(columnKey);
                columnList.add(column);
            }
            unit.columns = columnList;
            
            
            //for (Project__c proj : projectList) {
                Rows row = new Rows();
                //row.id = String.isNotBlank(proj.Unit_ID__c) ? proj.Unit_ID__c : '';
                
                if(proj.record_sync__c==true){
                    row.unitid = String.isNotBlank(proj.UnitID__c) ? proj.UnitID__c : '';
                //row.projectid = proj.Project_Building__r.Project__r.Project_Id__c !=null ? String.isNotBlank(proj.Project_Building__r.Project__r.Project_Id__c) ? proj.Project_Building__r.Project__r.Project_Id__c : '' : '';
                }else{
                    row.unitid = String.isNotBlank(proj.Unit_ID__c) ? proj.Unit_ID__c : '';
                }
                if(proj.Project__r.record_sync__c==true){
                    row.projectid = proj.Project__r.Project_Id__c !=null ? String.isNotBlank(proj.Project__r.Project_Id__c) ? proj.Project__r.Project_Id__c : '' : '';
                }else{
                    row.projectid = proj.Unit_Project_ID__c !=null ? String.isNotBlank(proj.Unit_Project_ID__c) ? proj.Unit_Project_ID__c : '' : '';
                }
                
                row.unittype = proj.Unit_Type__c!=null ? proj.Unit_Type__c : '';
                row.tower = String.isNotBlank(proj.Project_Building__r.Name) ? proj.Project_Building__r.Name : '';
                row.floornumber = String.isNotBlank(proj.Floor_Number__c) ? proj.Floor_Number__c : '';
                row.unitnumber = String.isNotBlank(proj.Name) ? proj.Name : '';
                row.rate = proj.Rate__c!=null ? String.valueOf(proj.Rate__c) : '';
                row.price = proj.New_Price__c!=null ? String.valueOf(proj.New_Price__c) : '';
                row.othercharges =  proj.Other_Charges__c!=null ? String.valueOf(proj.Other_Charges__c) : '';
                row.totalprice = proj.New_Total_Price_Excluding_GST__c!=null ? String.valueOf(proj.New_Total_Price_Excluding_GST__c) : '';
                row.unitplotarea = proj.Plot_Area__c!=null ? String.valueOf(proj.Plot_Area__c) : '';
               
                row.version = '1';
                row.lastmntby = '1509';
                row.lastmnton = String.valueOf(System.now());
                row.recordstatus = 'Approved';
                row.workflowid = '0';
                row.rateconsidered = String.isNotBlank(proj.Rate_Considered__c) ? proj.Rate_Considered__c : '';
                row.carpetarea =  proj.Carpet_Area__c!=null ? String.valueOf(proj.Carpet_Area__c) : '';
                row.unitbuiltuparea =  proj.Unit_Built_Up_Area__c!=null ? String.valueOf(proj.Unit_Built_Up_Area__c) : '';
                row.unitsuperbuiltup = proj.Super_Builtup_Area__c!=null ? String.valueOf(proj.Super_Builtup_Area__c) : '';
                row.floorrisecharges = proj.Floor_Rise_Charges__c!=null ? String.valueOf(proj.Floor_Rise_Charges__c) : '';
                row.opencarparkingcharges = proj.Open_Car_Parking_Charges__c!=null ? String.valueOf(proj.Open_Car_Parking_Charges__c) : '';
                row.gst = proj.GST__c!=null ? String.valueOf(proj.GST__c) : '';
                row.remarks = String.isNotBlank(proj.Remarks__c) ? proj.Remarks__c : '';
                rowList.add(row);
            	unit.rows = rowList;
                
               JsonMap.put(row.unitid, new List<String>{ JSON.serialize(unit) });
            //}
           }

       

        return JsonMap;
    }

    public class UnitRequestWrapper {
        public String templateId;
        public String opr;
        public Columns[] columns;
        public Rows[] rows;
    }

    public class Columns {
        public String columnName;
        public String dataType;
    }

    public class Rows {
        //public String id;
        public String unitid;
        public String unittype;
        public String tower;
        public String floornumber;
        public String unitnumber;
        public String rate;
        public String price;
        public String othercharges;
        public String totalprice;
        public String unitplotarea;
        public String projectid;
        public String version;
        public String lastmntby;
        public String lastmnton;
        public String recordstatus;
        public String workflowid;
        public String rateconsidered;
        public String carpetarea;
        public String unitbuiltuparea;
        public String unitsuperbuiltup;
        public String floorrisecharges;
        public String opencarparkingcharges;
        public String gst;
        public String remarks;
    }
}