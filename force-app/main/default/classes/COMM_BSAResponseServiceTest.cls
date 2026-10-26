@isTest
private class COMM_BSAResponseServiceTest {

    @isTest
    static void testBSAResponseDeserialization() {
          COMM_BSAResponseService result1 =  new COMM_BSAResponseService();
        result1.status = true;
        result1.message = 'tes';
       String json1 = '{"status":false,"message":"Failed to analyze bank statement due to missing data."}';
        String jsonResponse = '{' +
            '"success": true,' +
            '"message": "Analysis completed",' +
            '"data": {' +
                '"analysis_id": "ANL12345",' +
                '"summary": {' +
                    '"average_balance": 42000.75,' +
                    '"total_credits": 800000.50,' +
                    '"total_debits": 760000.25,' +
                    '"closing_balance": 42000.75' +
                '},' +
                '"customer_info": {' +
                    '"name": "John Doe",' +
                    '"email": "john@example.com",' +
                    '"mobile": "9876543210",' +
                    '"pan": "ABCDE1234F",' +
                    '"gst": "27ABCDE1234F1Z5"' +
                '},' +
                '"analysis": [' +
                    '{' +
                        '"account": {' +
                            '"account_holder": "John Doe",' +
                            '"account_number": "1234567890",' +
                            '"ifsc": "HDFC0001234",' +
                            '"bank_name": "HDFC Bank",' +
                            '"account_type": "Savings",' +
                            '"statement_from": "2023-01-01",' +
                            '"statement_to": "2023-12-31"' +
                        '},' +
                        '"metrics": {' +
                            '"total_transactions": 200,' +
                            '"credit_transactions": 120,' +
                            '"debit_transactions": 80,' +
                            '"average_monthly_balance": 35000.00,' +
                            '"highest_balance": 60000.00,' +
                            '"lowest_balance": 10000.00' +
                        '},' +
                        '"transactions": [' +
                            '{' +
                                '"txn_date": "2023-06-10",' +
                                '"narration": "Salary Credit",' +
                                '"txn_type": "CREDIT",' +
                                '"amount": 75000.00,' +
                                '"balance": 82000.00' +
                            '},' +
                            '{' +
                                '"txn_date": "2023-06-12",' +
                                '"narration": "ATM Withdrawal",' +
                                '"txn_type": "DEBIT",' +
                                '"amount": 5000.00,' +
                                '"balance": 77000.00' +
                            '}' +
                        ']' +
                    '}' +
                ']' +
            '}' +
        '}';

        // Act
        COMM_BSAResponseService result = (COMM_BSAResponseService) JSON.deserialize(json1, COMM_BSAResponseService.class);

      
    }
}