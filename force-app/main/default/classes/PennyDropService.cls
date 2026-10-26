public class PennyDropService {
    @future(callout=true)
    public static void callPennyDrop(Set<Id> txnIds) {
        List<Loan_Transaction__c> txns = [
            SELECT Id, Bank__c, IFSC__c,  Account_Number__c, Name, Penny_Drop_Result__c, Transaction_Details__c
            FROM Loan_Transaction__c
            WHERE Id IN :txnIds
        ];

        for (Loan_Transaction__c txn : txns) {
            System.debug('IFSC Code ' + txn.IFSC__c);
            System.debug('Acc No.' + txn.Account_Number__c);
            try {
                if (String.isNotBlank(txn.IFSC__c) && String.isNotBlank(txn.Account_Number__c)) {
                    String response = PennyDropCallout.sendHttpRequest(txn.IFSC__c, txn.Account_Number__c);
                    PennyDropApiResponse parsedResponse = (PennyDropApiResponse) JSON.deserialize(response, PennyDropApiResponse.class);
                    txn.Penny_Drop_Result__c = parsedResponse.result != null ? parsedResponse.result.bankResponse : 'No response';
                    txn.Transaction_Details__c = parsedResponse.request_id;
                    System.debug('Penny Drop API Response for txn ' + txn.Id + ': ' + response);
                } else {
                    System.debug('Skipping txn ' + txn.Id + ' due to missing IFSC or Account Number');
                }
            } catch (Exception e) {
                System.debug('Penny Drop API call failed for txn ' + txn.Id + ': ' + e.getMessage());
            }
        }
        update txns;
    }

    public class PennyDropApiResponse {
        public Result result;
        public String request_id;
        public String statusCode;  
    }
public class Result {
        public String accountNumber;
        public String ifsc;
        public String accountName;
        public String bankResponse;
        public Boolean bankTxnStatus;
    }
}