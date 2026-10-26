public class HL_QuickSanctionController {
    public class InputWrapper{
        @AuraEnabled public String loanId {get;set;}
        @AuraEnabled public Boolean fromSalesToCredit {get;set;}
    }
    @AuraEnabled
    public static ResultMessage checkQuickSanction(String inputWrapStr){
        Boolean isNonIndPrimaryApplant=false;
        InputWrapper inputWrap = (InputWrapper)JSON.deserialize(inputWrapStr, InputWrapper.class);
        ResultMessage result = new ResultMessage();
        result.isQuickSanctionValid = true;
        result.errorList = new List<String>();
        String loanId = inputWrap.loanId;
        Boolean fromSalesToCredit =inputWrap.fromSalesToCredit;
        if(fromSalesToCredit==null){
            fromSalesToCredit=false;
        }
        Integer countFinancial =0;
        List<Application_Applicant__c> appList = [Select Id, Is_Financial_applicant__c, Cibil_Score__c, Customer_Type__c,Monthly_Salary__c, Customer_Profile__c, Sub_Employment_Type_Non_Individual__c, Applicant_Name__c,Applicant_Type__c from Application_Applicant__c where Loan_Application__c =: loanId AND Applicant_Type__c != 'Builder'];
        if(!appList.isEmpty()){
            for(Application_Applicant__c app : appList){
                if(app.Is_Financial_applicant__c=='Yes'){
                    countFinancial ++;
                }
                if(app.Applicant_Type__c=='Primary Applicant' && app.Customer_Type__c == 'Non Individual'){
                    isNonIndPrimaryApplant=true;
                }
                
                
            }
            if(countFinancial==0 && !fromSalesToCredit){
                result.isQuickSanctionValid = false;
                result.errorList.add('• No financial applicant present in this loan. So cannot proceed for quick sanction.');
            }
            else{
                if(!isNonIndPrimaryApplant){
                    Double totalSalary=0;
                    List<String> restrictedEmpCategory = Label.Quick_Sanction_Employer_Category.split(',');
                    for(Application_Applicant__c app : appList){
                        if(app.Customer_Type__c == 'Indiviudal' && app.Cibil_Score__c == null  /*|| app.Cibil_Score__c <= Integer.valueOf(Label.Quick_Sanction_Cibil_Threshold)*/){
                            result.isQuickSanctionValid = false;
                            result.errorList.add('• '+ app.Applicant_Name__c+' - Please fetch CIBIL Score to meet the criteria for quick sanction.');
                        }
                        if(String.isBlank(app.Sub_Employment_Type_Non_Individual__c)){
                            result.isQuickSanctionValid = false;
                            result.errorList.add('• '+ app.Applicant_Name__c+' - Please add sub employment type to meet the criteria for quick sanction.');
                        }
                        if(app.Customer_Type__c!= 'Non Individual'&&  app.Applicant_Type__c=='Primary Applicant' && app.Customer_Profile__c=='Salaried Indian' && app.Monthly_Salary__c == null ){
                            result.isQuickSanctionValid = false;
                            result.errorList.add('• '+ app.Applicant_Name__c+' - Please add monthly salary to meet the criteria for quick sanction.');
                        }
                    }
                    
                    List<Applicant_Address__c> addrList = [Select Id, Pincode__r.Is_Pincode_Servicable__c, Applicant__c from Applicant_Address__c where Applicant__c in: appList AND Applicant__r.Customer_Type__c = 'Individual' and Address_Type__c = 'Current' and Address_Source__c = 'Aadhaar'];
                    if(!addrList.isEmpty()){
                        Map<String,Applicant_Address__c> appToAddrMap = new Map<String,Applicant_Address__c>();
                        for(Applicant_Address__c addr: addrList){
                            appToAddrMap.put(addr.Applicant__c,addr);
                        }
                        if(!fromSalesToCredit){
                        for(Application_Applicant__c app : appList){
                            if( app.Customer_Type__c == 'Individual' && !appToAddrMap.containsKey(app.Id) || appToAddrMap.get(app.Id) == null){
                                result.isQuickSanctionValid = false;
                                result.errorList.add('• '+ app.Applicant_Name__c+' - Please add address to meet the criteria.');
                                }
                            }
                        }
                    }
                    else{
                        if(!fromSalesToCredit){
                        result.isQuickSanctionValid = false;
                        result.errorList.add('• Please add current address for all the applicants in order to meet the criteria.');
                    }
                   
                    }
                    List<Opportunity> oppList = [Select Id, Property_Type__c,Product__c from Opportunity where Id =: loanId];
                    if(!oppList.isEmpty()){
                        List<String> propertyTypeVal = Label.Quick_Sanction_Property_Type.split(',');
                        if(oppList[0].Property_Type__c == null && (oppList[0].Product__c=='Home Loan'||oppList[0].Product__c=='Non Home Loan')/*|| !propertyTypeVal.contains(oppList[0].Property_Type__c)*/){
                            result.isQuickSanctionValid = false;
                            result.errorList.add('• Please add property type in order to meet the criteria');
                        }
                    }
                }
            }
        }
       
        
        return result;
    }
    public class ResultMessage{
        @AuraEnabled public Boolean isQuickSanctionValid;
        @AuraEnabled public List<String> errorList;
    }
    @AuraEnabled
    public static LoanDetailsWrapper getLoanDetails(String loanId){
        LoanDetailsWrapper result = new LoanDetailsWrapper();
        List<Product2> prodList = [Select id, Name from Product2 where Loan_Application__c =: loanId /*and Product_Type__c = 'Parent'*/ limit 1];
        if(!prodList.isEmpty()){
            result.productName = prodList[0].Name;
            result.productId = prodList[0].Id;
        }
        else{
            result.errorList = new list<String>{'• Please add product details.'};
                }
        return result;
    }
    public class LoanDetailsWrapper{
        @AuraEnabled public String productName;
        @AuraEnabled public String productId;
        @AuraEnabled public List<String> errorList;
    }
}