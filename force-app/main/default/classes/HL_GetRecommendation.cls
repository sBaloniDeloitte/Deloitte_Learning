public with sharing class HL_GetRecommendation {
     @AuraEnabled(cacheable=false)
    public static String getRecommendations(Id opportunityId) {

        // ✅ Fetch Opportunity
        Opportunity opp = [
            SELECT Id,
                   Requested_ROI__c,
                   FOIR__c,
                   Final_Amount__c,
                   Sanction_Loan_Amount__c,
                   Co_lending__c,
                   Final_Tenure__c,
                   Score_Segment__c,
                   Negotiated_Loan_Amount__c,
                   Negotiated_Rate_Of_Interest__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        // ✅ Fetch Insurance Premium (related object)
        Decimal insurancePremium = 0;
        Decimal ltvPercentage = 0;
        Decimal finalltv = 0;
        Decimal maximumLTV = 0;
        Decimal finalFoir = 0;
        
        List<Charges_Insurance__c> insList = [
            SELECT Id, Name, Insurance_Premium__c
            FROM Charges_Insurance__c
            WHERE Loan_Application__c = :opportunityId
            AND VAS_Type__c = 'Insurance'
            LIMIT 1
        ];

        if (!insList.isEmpty() && insList[0].Insurance_Premium__c != null) {
            insurancePremium = insList[0].Insurance_Premium__c;
        }
        
        //fetch LTV from product 
        List<product2> prodList = [SELECT Id,LTV__c,Combined_LTV__c,HL_Final_LTV__c,HL_Final_FOIR__c,HL_Maximum_LTV__c,RecordType.name 
                                              FROM product2 where Loan_Application__c = :opportunityId
                                              and RecordType.Name = 'Sub Product' LIMIT 1];
        
         if (!prodList.isEmpty() && prodList[0].LTV__c != null) {
            ltvPercentage = prodList[0].LTV__c;
        }
        if (!prodList.isEmpty() && prodList[0].HL_Final_LTV__c != null) {
             finalltv = prodList[0].HL_Final_LTV__c;
        }
        if (!prodList.isEmpty() && prodList[0].HL_Maximum_LTV__c != null) {
             maximumLTV = prodList[0].HL_Maximum_LTV__c;
        }
         if (!prodList.isEmpty() && prodList[0].HL_Final_FOIR__c != null) {
             finalFoir = prodList[0].HL_Final_FOIR__c;
        }
        
        String plrCode = '';
        
        // Fetch all matching records
        List<Loan_Transaction__c> loanTxnList = [
            SELECT Id, RecordType.Name, PLR_Code__c, PLR_Value__c
            FROM Loan_Transaction__c
            WHERE Loan_Application__c = :opportunityId
            AND RecordType.Name = 'Transaction Details'
        ];
        
         // fetch PLR_Code__c     
        if (!loanTxnList.isEmpty() && loanTxnList[0].PLR_Code__c != null) {
            plrCode = loanTxnList[0].PLR_Code__c;
        }


        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('Callout:HL_Colending_Recommendation');

        // request.setEndpoint('https://uat-hl-sf.godrejhf.com/predict');
        request.setMethod('POST');

        request.setHeader('Content-Type', 'application/json');
       // request.setHeader('Authorization', 'Bearer token'); // Replace
        //request.setHeader('OrgId', '67b7169fc39cf3bec8b8da05');

        // Request Body with Insurance
        // Map<String, Object> body = new Map<String, Object>{
        //     //'addltv' => 0,
        //     'addltv' => ltvPercentage,
        //     'collateral_existing_exposure' => 0,
        //     'confidence_threshold' => 0.6,
        //     'cross_obligation_amt' => 0,
        //     'ficostatus' => 'Success',

        //     'finalfoir' => 28.49,//opp.FOIR__c,
        //     'loanamtoffr' => opp.Final_Amount__c != null 
        //                         ? opp.Final_Amount__c 
        //                         : opp.Sanction_Loan_Amount__c,
        //     'loantenu' => opp.Final_Tenure__c,

        //     'rointr' => opp.Negotiated_Rate_Of_Interest__c != null 
        //                     ? opp.Negotiated_Rate_Of_Interest__c 
        //                     : opp.Requested_ROI__c,
        //     'hl_segmentation' => opp.Score_Segment__c != null ? opp.Score_Segment__c : opp.Score_Segment__c,           

        //     // ✅ Added Insurance Premium
        //     'insurance_premium_amt' => insurancePremium,
        //  'finalltv' => finalltv,
        //     'maxltv' => maximumLTV,
        //     'repaybaserate' => plrCode,
        //     // Static fields
        //     //'finalltv' => 51.27, 
        //     //'hl_segmentation' => 'Gold',
        //     'maxloeliginc' => 22530042.64,
        //     'maxloeligltv' => 8425977.59,
        //     //'maxltv' => 80,
        //     //'repaybaserate' => 'REPOIPLR', 
        //     'systemdecision' => 'DEVIATION'
        // };
 // Request Body with Insurance
        Map<String, Object> body = new Map<String, Object>{
            //'addltv' => 0,
            'addltv' => ltvPercentage,
            'collateral_existing_exposure' => 0,
            'confidence_threshold' => 0.6,
            'cross_obligation_amt' => 0,
            'ficostatus' => 'Success',

            // 'finalfoir' => opp.FOIR__c != null ? opp.FOIR__c : 28.49 ,
             'finalfoir' => finalFoir,
            // 'loanamtoffr' => opp.Final_Amount__c != null 
            //                 ? opp.Final_Amount__c 
            //                 : opp.Sanction_Loan_Amount__c,
            'loanamtoffr' => (opp.Final_Amount__c != null && opp.Final_Amount__c != 0)
                            ? opp.Final_Amount__c 
                            : 0,
            // 'loantenu' => opp.Final_Tenure__c,

            // 'rointr' => opp.Negotiated_Rate_Of_Interest__c != null 
            //             ? opp.Negotiated_Rate_Of_Interest__c 
            //             : opp.Requested_ROI__c,
            'loantenu' => (opp.Final_Tenure__c != null && opp.Final_Tenure__c != 0)
                        ? opp.Final_Tenure__c 
                        : 0,

            'rointr' => (opp.Negotiated_Rate_Of_Interest__c != null && opp.Negotiated_Rate_Of_Interest__c != 0)
                        ? opp.Negotiated_Rate_Of_Interest__c 
                        :0,
            'hl_segmentation' => opp.Score_Segment__c != null ? opp.Score_Segment__c : opp.Score_Segment__c,           

            // ✅ Added Insurance Premium
            'insurance_premium_amt' => insurancePremium,
            'finalltv' => finalltv,
            'maxltv' => maximumLTV,
            'repaybaserate' => plrCode,
            // Static fields
            //'finalltv' => 51.27,  
            //'hl_segmentation' => 'Gold',
            'maxloeliginc' => 22530042.64,
            'maxloeligltv' => 8425977.59,
            //'maxltv' => 80,
            //'repaybaserate' => 'REPOIPLR', 
            'systemdecision' => 'DEVIATION'
        };
        request.setBody(JSON.serialize(body));

        HttpResponse response = http.send(request);
        System.debug('Response: ' + response.getBody());
        return response.getBody();
    }
}