public class CalculateGSTQueueable implements Queueable, Database.AllowsCallouts{
   private Id loanApplicationId;

    public CalculateGSTQueueable(Id loanApplicationId) {
        this.loanApplicationId = loanApplicationId;
    }

    public void execute(QueueableContext context){
        List<Charges_Insurance__c> chargesRecords = [
            SELECT Id, Name, Product__c, Requested_Amount_INR__c
            FROM Charges_Insurance__c
            WHERE Loan_Application__c = :loanApplicationId
        ];

        Boolean stopProcessing = false;
        for (Charges_Insurance__c record : chargesRecords) {

            if (stopProcessing) break;

            Decimal amt = record.Requested_Amount_INR__c;
            if (amt == null || amt == 0) {
                continue; // same as JS skip
            }

            Map<String, String> inputMap = new Map<String, String>{
                'loanId' => loanApplicationId,
                'processName' => 'CalculateGST',
                'productName' => record.Product__c,
                'feeType' => record.Name,
                'isWaiverAmountCalc' => 'false'
            };

            if(!Test.isrunningTest()){
                String result = AHL_CalculateGstController.initiateAPIRequest(inputMap);

                // Same as: result.includes('Error')
                if (result != null && result.contains('Error')) {
                    stopProcessing = true;

                    // Optional: log error on Loan / Charges
                    System.debug('GST Error: ' + result);
                    break;
                }
            }
            
        }

        // Only update total charges if no error
        if (!stopProcessing) {
            COMM_SalesLoginFeeController.updateTotalCharges(loanApplicationId);
        }
    }
}