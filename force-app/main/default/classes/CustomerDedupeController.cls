/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-20-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

public without sharing class CustomerDedupeController {  

    @AuraEnabled
    public static CustomerDedupeWrapper getDuplicateCustomerList(CustomerDedupeWrapper custWrap) {
        String requestJSON = JSON.serialize(custWrap, true);

        CustomerDedupeWrapper duplicateCustList = new CustomerDedupeWrapper();

        // if(requestJSON != null){
        //     HTTPResponse res = Utility.executeAPIRequest(Constants.LEAD_DEDUPE_API, '', requestJSON, '', '');
        //     String responseBody = res.getBody();
        //     String cleanedResponse = Utility.cleanResponse(responseBody);
        //     try {
        //         if(res.getStatusCode() == 200){
        //             // String resp ='{"Data":{"TransactionStatus":[{"IsOverriden":"false","ReplyCode":"0","SpReturnValue":"0","ExternalReferenceNo":"46t7uxhb926x","IsServiceChargeApplied":"false","ErrorCode":"0","ExtendedReply":{},"FCYHangeHandlingApplied":false}],"CustomerDetails":[{"CustomerNumber":320809486,"AadhaarNumber":"0523","MobileNumber":8972787552,"FullName":"UMUMA ARARMAKAR","BirthDate":"19930202","MotherName":"MITHU","Address1":"KBIDEV KENDULI JOYDEV KENDULI LAND MARK","Address2":"LBLI MANDIR DIST-BIRBHUM","Address3":"!","City":"ILLAMBAZAR","State":"West Bengal","Pincode":"731124","Country":"INDIA","BlockStatus":"N","EmailId":"chandrima.dutta@bandhanbank.com","FirstName":"UMUMA","LastName":"ARARMAKAR","CKYCID":"40039478582000","IcType":"Individual","CustIc":"320809486"},{"CustomerNumber":326382176,"PANNumber":"AGDPJ8853D","AadhaarNumber":"9293","MobileNumber":8972787552,"FullName":"WEHWETA ILWAPNIL NTANT","BirthDate":"19830606","MotherName":"MEGHONA","Address1":"796 SAI TOWER CWING FL NO 101 AWARD","Address2":"OS 8 NO SCHOOL SHIVAJI DIST-KOIHAPUR","Address3":"--,NR 8 NO SCHOOL SHIVAJI  PITH","City":"KARVIR","State":"Maharashtra","Pincode":"416012","BlockStatus":"N","EmailId":"tapas.pramanik@bandhanbank.com","FirstName":"WEHWETA","MiddleName":"ILWAPNIL","LastName":"NTANT","CKYCID":"10090390175000","IcType":"Individual","CustIc":"326382176"},{"CustomerNumber":400059765,"PANNumber":"COFPP1835M","AadhaarNumber":"4765","MobileNumber":8972787552,"FullName":"TAPAS  PRAMANIK","BirthDate":"19910315","MotherName":"JHUMKI PRAMANIK","Address1":"S/O: DILIP KUMAR PRAMANIK","Address2":"SANKATI","Address3":"ATGHARIA","City":"BARDDHAMAN","State":"West Bengal","Pincode":"713405","BlockStatus":"N","EmailId":"Mailmetapas90@gmail.com","FirstName":"TAPAS","LastName":"PRAMANIK","IcType":"Individual","CustIc":"400059765"}]}}';
        //             // duplicateCustList = (CustomerDedupeWrapper) JSON.deserialize(resp, CustomerDedupeWrapper.class);
        //             // duplicateCustList.StatusCode = res.getStatusCode();

        //             duplicateCustList = (CustomerDedupeWrapper) JSON.deserialize(cleanedResponse, CustomerDedupeWrapper.class);
        //             duplicateCustList.StatusCode = res.getStatusCode();
        //         }else{
        //             if(cleanedResponse.contains(Constants.LEAD_DEDUPE_NTB_CHECK)){
        //                 duplicateCustList.StatusCode = 200;
        //             }else{
        //                 duplicateCustList.StatusCode = res.getStatusCode();
        //             }

        //             if(res.getStatusCode() == 500 ){
        //                 duplicateCustList.StatusCode = 200;
        //             }
        //         }
        //     } catch(Exception exp){
        //         Utility.generateException(exp, Constants.LEAD_OBJECT_NAME, Constants.LEAD_CLASS_4);
        //     }
        // }
       
        return duplicateCustList;
    }

    public class DuplicateCustomerInfo{
        @AuraEnabled public Integer StatusCode;
        @AuraEnabled public Boolean freshCustomer;
        @AuraEnabled public Boolean activeLoan;
        @AuraEnabled public String integrationInfId;
        @AuraEnabled public Boolean softDedupe;
        @AuraEnabled public List<DuplicateCustomerDetails> dupDetails;
        @AuraEnabled public List<ExitingLoanDetails> exisitngLoanList;
        @AuraEnabled public Boolean duplicateCustFromApi;
    }
    public class DuplicateCustomerDetails{
        @AuraEnabled public String customerName;
        @AuraEnabled public Integer customerNumber;
        @AuraEnabled public String panNumber;
        @AuraEnabled public String mobileNumber;
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public Date dateOfBirth;
        @AuraEnabled public String maskedMobileNumber;
        @AuraEnabled public String maskedPanNumber;
        @AuraEnabled public String Id; 
    }
    public class ExitingLoanDetails{
        @AuraEnabled public String productName;
        @AuraEnabled public String loanAccId;
        @AuraEnabled public String status;
    }
}