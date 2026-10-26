@RestResource(urlMapping='/sanctionLetterPayload/*')
global without sharing class COMM_SanctionLetterRest {
@HttpGet
    global static String getSanctionLetterpayload(){
    try{
        // Get the LA from the URL after /sanctionLetterPayload/
        RestRequest req = RestContext.request;
        String loanNumber = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);

        if(String.isEmpty(loanNumber)){
            return 'Loan Number is required';
        }
        // Query the Opportunity
        opportunity opp = [SELECT Id, Name FROM opportunity WHERE name = :loanNumber LIMIT 1];

        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.recordId = '';
        //wrapper.loanApplicationId = '006Bg00000HcyhJIAR';  
        wrapper.loanApplicationId = opp.Id; 
        wrapper.type = 'Sanction Letter Generation';


        IntHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
        System.debug('Payload:: ' + respWrapper.payload);
        Utility.publishCommunicationEvent(respWrapper.payload, wrapper.loanApplicationId, 'SLSF');
        return respWrapper.payload;
      }catch(Exception e) {
            System.debug('Error: ' + e);
            System.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            return 'FAIL';
        }    
    }
}