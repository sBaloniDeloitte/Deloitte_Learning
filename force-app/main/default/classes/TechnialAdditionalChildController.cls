public class TechnialAdditionalChildController {
    @AuraEnabled
    public static DataWrapper getAllChildRecords(String techId) {
        DataWrapper mainWrap = new DataWrapper();
        List<Technical_Evaluation__c> techRec = [SELECT id,Area_Government__c,Area_Fair_Market__c,Area_Post_Completion__c,
                                                 Rate_Government__c,Rate_Fair_Market__c,Rate_Post_Completion__c,Market_Value_in_Rs_Fair_Market__c,
                                                 Market_Value_in_Rs_Post_Completion__c ,DLC_Value_in_Rs__c,Total_Value_of_As_of_Date__c,QSV_Distress_Value__c,QSV_Distress_Value_PC__c,
                                                 Others_Government__c,Others_Present_Fair__c,Others_POST_COMPLETION__c FROM Technical_Evaluation__c WHERE id=:techId]; 
        List<Technical_Detail__c> allChild = [SELECT id,Technical_Evaluation__c,Technical_Evaluation__r.Area_Government__c,
                                              Technical_Evaluation__r.Area_Fair_Market__c, Technical_Evaluation__r.Area_Post_Completion__c,
                                              Technical_Evaluation__r.Rate_Government__c, Technical_Evaluation__r.Rate_Fair_Market__c,
                                              Technical_Evaluation__r.Rate_Post_Completion__c,Technical_Evaluation__r.Market_Value_in_Rs_Fair_Market__c,
                                              Technical_Evaluation__r.Market_Value_in_Rs_Post_Completion__c ,Technical_Evaluation__r.DLC_Value_in_Rs__c,
                                              Area__c,Area_Fair_Market_Value__c,Area_Post_Completion__c,Rate__c,Rate_Fair_Market_Value__c,Rate_Post_Completion__c,
                                              Market_Value_in_Rs__c,Market_Value_in_Rs_Government__c,Market_Value_Post_Completion__c,Floor__c
                                              FROM Technical_Detail__c WHERE Technical_Evaluation__c =:techId AND Sections__c = 'Property Details'];
        Decimal govtotal = 0;
        Decimal markettotal = 0;
        Decimal completiontotal = 0;
        if(techRec.size() > 0) {
            InnerSubWrapper govv = new InnerSubWrapper();
            List<InnerWrapper> govLst = new List<InnerWrapper>();
            InnerWrapper govInner = new InnerWrapper();
            govInner.Id = techRec[0].id;
            govInner.mainLabel = 'Value of land Sq. FT';
            govInner.subLabel = 'DLC Value in Rs.';
            govInner.area = techRec[0].Area_Government__c;
            govInner.fieldApiNameArea = 'Area_Government__c';
            govInner.fieldApiNameRate = 'Rate_Government__c';
            govInner.rate = techRec[0].Rate_Government__c;
            
            govInner.value = techRec[0].DLC_Value_in_Rs__c;
            govLst.add(govInner);
            govtotal = govtotal + (techRec[0].DLC_Value_in_Rs__c != null ? techRec[0].DLC_Value_in_Rs__c : 0);
            
            
            
            InnerSubWrapper market = new InnerSubWrapper();
            List<InnerWrapper> marketLst = new List<InnerWrapper>();
            InnerWrapper marketInner = new InnerWrapper();
            marketInner.Id = techRec[0].id;
            marketInner.mainLabel = 'Value of land Sq. FT';
            marketInner.subLabel = 'Market Rate';
            marketInner.fieldApiNameArea = 'Area_Fair_Market__c';
            marketInner.fieldApiNameRate = 'Rate_Fair_Market__c';
            marketInner.area = techRec[0].Area_Fair_Market__c;
            marketInner.rate = techRec[0].Rate_Fair_Market__c;
            marketInner.value = techRec[0].Market_Value_in_Rs_Fair_Market__c;
            marketLst.add(marketInner);
            markettotal = markettotal + (techRec[0].Market_Value_in_Rs_Fair_Market__c != null ? techRec[0].Market_Value_in_Rs_Fair_Market__c : 0);
            
            
            InnerSubWrapper completion = new InnerSubWrapper();
            List<InnerWrapper> completionLst = new List<InnerWrapper>();
            InnerWrapper completionInner = new InnerWrapper();
            completionInner.Id = techRec[0].id;
            completionInner.mainLabel = 'Value of land Sq. FT';
            completionInner.subLabel = 'Market Rate';
            completionInner.fieldApiNameArea = 'Area_Post_Completion__c';
            completionInner.fieldApiNameRate = 'Rate_Post_Completion__c';
            completionInner.area = techRec[0].Area_Post_Completion__c;
            completionInner.rate = techRec[0].Rate_Post_Completion__c;
            completionInner.value = techRec[0].Market_Value_in_Rs_Post_Completion__c;
            completionLst.add(completionInner);
            completiontotal = completiontotal + (techRec[0].Market_Value_in_Rs_Post_Completion__c != null ? techRec[0].Market_Value_in_Rs_Post_Completion__c : 0);
            
            
            if(allChild.size() > 0) {
                for(Technical_Detail__c iterChild : allChild) {
                    InnerWrapper govInnerr = new InnerWrapper();
                    govInnerr.Id = iterChild.id;
                    govInnerr.mainLabel = 'Value of Const/ Flat/ Shop/ Office. on '+iterChild.Floor__c+' in Sq. Ft';
                    govInnerr.subLabel = 'Market Value in Rs.';
                    govInnerr.fieldApiNameArea = 'Area__c';
            		govInnerr.fieldApiNameRate = 'Rate__c';
                    govInnerr.area = iterChild.Area__c;
                    govInnerr.rate = iterChild.Rate__c;
                    govInnerr.value = iterChild.Market_Value_in_Rs_Government__c;
                    govLst.add(govInnerr);
                    govtotal = govtotal + (iterChild.Market_Value_in_Rs_Government__c != null ? iterChild.Market_Value_in_Rs_Government__c : 0);
                    
                    
                    InnerWrapper marketInnerr = new InnerWrapper();
                    marketInnerr.Id = iterChild.id;
                    marketInnerr.mainLabel = 'Value of Const/ Flat/ Shop/ Office. on '+iterChild.Floor__c+' in Sq. Ft';
                    marketInnerr.subLabel = 'Market Value in Rs.';
                    marketInnerr.fieldApiNameArea = 'Area_Fair_Market_Value__c';
            		marketInnerr.fieldApiNameRate = 'Rate_Fair_Market_Value__c';
                    marketInnerr.area = iterChild.Area_Fair_Market_Value__c;
                    marketInnerr.rate = iterChild.Rate_Fair_Market_Value__c;
                    marketInnerr.value = iterChild.Market_Value_in_Rs__c;
                    marketLst.add(marketInnerr);
                    markettotal = markettotal + (iterChild.Market_Value_in_Rs__c != null ? iterChild.Market_Value_in_Rs__c : 0);
                    
                    InnerWrapper completionInnerr = new InnerWrapper();
                    completionInnerr.Id = iterChild.id;
                    completionInnerr.mainLabel = 'Value of Const/ Flat/ Shop/ Office. on '+iterChild.Floor__c+' in Sq. Ft';
                    completionInnerr.subLabel = 'Market Value in Rs.';
                    completionInnerr.fieldApiNameArea = 'Area_Post_Completion__c';
            		completionInnerr.fieldApiNameRate = 'Rate_Post_Completion__c';
                    completionInnerr.area = iterChild.Area_Post_Completion__c;
                    completionInnerr.rate = iterChild.Rate_Post_Completion__c;
                    completionInnerr.value = iterChild.Market_Value_Post_Completion__c;
                    completionLst.add(completionInnerr);
                    completiontotal = completiontotal + (iterChild.Market_Value_Post_Completion__c != null ? iterChild.Market_Value_Post_Completion__c : 0);
                }
            }
            if(techRec[0].Others_Government__c != null && govtotal != null) {
                govtotal = govtotal + techRec[0].Others_Government__c;
            }
            if(techRec[0].Others_Present_Fair__c != null && markettotal != null) {
                markettotal = markettotal + techRec[0].Others_Present_Fair__c;
            }
            if(techRec[0].Others_POST_COMPLETION__c != null && completiontotal != null) {
                completiontotal = completiontotal + techRec[0].Others_POST_COMPLETION__c;
            }
            govv.records = govLst;
            govv.total = govtotal;
            
            market.records = marketLst;
            market.total = markettotal;
            
            completion.records = completionLst;
            completion.total = completiontotal;
            
            
            
            mainWrap.gov = govv;
            mainWrap.market = market;
            mainWrap.complition = completion;
            mainWrap.totalValueAsOnDate = techRec[0].Total_Value_of_As_of_Date__c;
            mainWrap.qsvDistress = techRec[0].QSV_Distress_Value__c;
            mainWrap.qsvDistressPC = techRec[0].QSV_Distress_Value_PC__c;
            
            mainWrap.otherGovValue = techRec[0].Others_Government__c;
            mainWrap.otherPresentValue = techRec[0].Others_Present_Fair__c;
            mainWrap.otherPostCompValue = techRec[0].Others_POST_COMPLETION__c;
        }
        return mainWrap;
    }
    
    @AuraEnabled
    public static List<String> checkForMandatoryDoc(String techId) {
        List<String> msg = new List<String>();
        boolean checkSign=DigitalSignatureController.checkSigned(techId);
        if(checkSign==false){
            msg.add('Your digital signature is not available in the system. Please contact the administrator to have it set up before signing the technical report.');
            return msg;
        }
        List<Technical_Evaluation__c> techList=[SELECT Id,Is_Signature_Generated__c,Engineer_Name__c,Valuer_Name__c FROM Technical_Evaluation__c WHERE Id =:techId];
        if(techList.size()>0 && (techList[0].Engineer_Name__c==null ||techList[0].Valuer_Name__c==null)){
            msg.add('Engineer name and valuer name are mandatory.');
            return msg;
        }
        List<Document_Details__c> docLst = [SELECT Id,Name,Is_Uploaded__c FROM Document_Details__c WHERE Technical__c =: techId 
                                            AND Name = 'Google Earth Screen Shot'];
        if(docLst.size() > 0) {
            if(docLst[0].Is_Uploaded__c) {
                Technical_Evaluation__c techEvalToUpdate=[SELECT Id, Name, HL_Loan_Application__c,Date_of_Technical_Request_Receipt__c FROM Technical_Evaluation__c WHERE Id = :techId LIMIT 1];
                techEvalToUpdate.Date_of_Technical_Request_Receipt__c=Date.ValueOf(System.now());
                update techEvalToUpdate;
            }else {
                msg.add('Upload Google Earth Screen Shot to generate report.');
            }
        }
        return msg;
    }
    
    
    public class DataWrapper {
        @AuraEnabled public InnerSubWrapper gov;
        @AuraEnabled public InnerSubWrapper market;
        @AuraEnabled public InnerSubWrapper complition;

        
        @AuraEnabled public Decimal totalValueAsOnDate;
        @AuraEnabled public Decimal qsvDistress;
        @AuraEnabled public Decimal qsvDistressPC;
        
        @AuraEnabled public Decimal otherGovValue;
        @AuraEnabled public Decimal otherPresentValue;
        @AuraEnabled public Decimal otherPostCompValue;

    }
    public class InnerSubWrapper {
        @AuraEnabled public List<InnerWrapper> records;
        @AuraEnabled public Decimal total; 
        @AuraEnabled public Decimal manualTotal; 
    }
    
    public class InnerWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String mainLabel;
        @AuraEnabled public String subLabel;   
        @AuraEnabled public Decimal area; 
        @AuraEnabled public Decimal rate;
        @AuraEnabled public Decimal value;
        @AuraEnabled public String fieldApiNameArea;
        @AuraEnabled public String fieldApiNameRate;
    }
    @AuraEnabled
    public static void generateRefreshEvent(String techId) {
          Refresh_Event__e event = new Refresh_Event__e(
                Technial__c = techId
            );
            EventBus.publish(event);
    }
    @AuraEnabled
    public static void calculatemMrketValue(String techId) {
        List<Technical_Detail__c> allChild = [SELECT id,Area__c,Area_Fair_Market_Value__c,Area_Post_Completion__c,Rate__c,Rate_Fair_Market_Value__c,Rate_Post_Completion__c,
                                              Market_Value_in_Rs__c,Market_Value_in_Rs_Government__c,Market_Value_Post_Completion__c,Floor__c
                                              FROM Technical_Detail__c WHERE Technical_Evaluation__c =:techId AND Sections__c = 'Property Details'];
        List<Technical_Evaluation__c> techRec = [SELECT id,Area_Government__c,Area_Fair_Market__c,Area_Post_Completion__c,
                                                 Rate_Government__c,Rate_Fair_Market__c,Rate_Post_Completion__c,Market_Value_in_Rs_Fair_Market__c,
                                                 Others_Government__c,Others_Present_Fair__c,Others_POST_COMPLETION__c,
                                                 Market_Value_in_Rs_Post_Completion__c ,DLC_Value_in_Rs__c,Construction_Stage_Percentage__c,Construction_Status__c FROM Technical_Evaluation__c WHERE id=:techId]; 
        if(techRec.size() > 0) {
            Boolean isUpdate = false;
            
            if(techRec[0].Area_Government__c != null && techRec[0].Rate_Government__c != null) {
                techRec[0].DLC_Value_in_Rs__c = techRec[0].Area_Government__c * techRec[0].Rate_Government__c;
                isUpdate = true;
            }
            if(techRec[0].Area_Fair_Market__c != null && techRec[0].Rate_Fair_Market__c != null) {
                techRec[0].Market_Value_in_Rs_Fair_Market__c = techRec[0].Area_Fair_Market__c * techRec[0].Rate_Fair_Market__c;
                isUpdate = true;
            }
            if(techRec[0].Area_Post_Completion__c != null && techRec[0].Rate_Post_Completion__c != null) {
                techRec[0].Market_Value_in_Rs_Post_Completion__c = techRec[0].Area_Post_Completion__c * techRec[0].Rate_Post_Completion__c;
                isUpdate = true;
            }
            if(isUpdate) {
                update techRec;
            }
        }
        if(allChild.size() > 0) {
            Boolean isUpdate = false;
            for (Technical_Detail__c iterChild : allChild) {
                if(iterChild.Area__c != null && iterChild.Rate__c != null) {
                    iterChild.Market_Value_in_Rs_Government__c = iterChild.Area__c * iterChild.Rate__c;
                    isUpdate = true;
                }else{
                    iterChild.Market_Value_in_Rs_Government__c=0;
                    isUpdate = true;
                }
                if(iterChild.Area_Fair_Market_Value__c != null && iterChild.Rate_Fair_Market_Value__c != null) {
                    iterChild.Market_Value_in_Rs__c = iterChild.Area_Fair_Market_Value__c * iterChild.Rate_Fair_Market_Value__c;
                    isUpdate = true;
                }else{
                    iterChild.Market_Value_in_Rs__c = 0;
                    isUpdate = true;
                }
                if(iterChild.Area_Post_Completion__c != null && iterChild.Rate_Post_Completion__c != null) {
                    iterChild.Market_Value_Post_Completion__c = iterChild.Area_Post_Completion__c * iterChild.Rate_Post_Completion__c;
                    isUpdate = true;
                }else{
                    iterChild.Market_Value_Post_Completion__c =0;
                    isUpdate = true;
                }
                if(techRec[0].Construction_Status__c =='Under Construction' && iterChild.Area_Post_Completion__c != null && iterChild.Rate_Post_Completion__c != null && ((iterChild.Area_Fair_Market_Value__c == 0 && iterChild.Rate_Fair_Market_Value__c == 0)||(iterChild.Area_Fair_Market_Value__c ==null && iterChild.Rate_Fair_Market_Value__c == null))){
                iterChild.Market_Value_in_Rs__c =  (iterChild.Area_Post_Completion__c * iterChild.Rate_Post_Completion__c) * (techRec[0].Construction_Stage_Percentage__c/100);
                isUpdate = true;
            }
            }
            if(isUpdate) {
                update allChild;
            }
        }
    }
    
    
}