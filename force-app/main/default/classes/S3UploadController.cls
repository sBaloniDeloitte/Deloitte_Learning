public class S3UploadController {

    public static String uploadFile(Map<String,String> inputMap){
        try{
            String contentDocId = inputMap.get('contentDocId');
            String processName = inputMap.get('processName'); //'S3 Upload'
            string loanId = inputMap.containsKey('loanId') ? inputMap.get('loanId') : '';
            String returnResp;

            Integration_Master__mdt metadata = [SELECT 
                                                    Process_Name__c,
                                                    Handler_Class__c,
                                                    Endpoint__c,
                                                    Request_Method__c,
                                                    Client_Id__c,
                                                    Client_Secret__c,
                                                    Allowed_Retry__c,
                                                    Gestation_Period__c,
                                                    Refresh_Allowed__c,
                                                    Activity_Name__c,
                                                    Origin__c
                                                FROM Integration_Master__mdt 
                                                WHERE Activity_Name__c = :processName LIMIT 1];
            
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
            
            wrapper.recordId = contentDocId;
            wrapper.loanApplicationId = loanId;
            wrapper.type = processName;
            wrapper.endpoint = metadata.Endpoint__c;
            wrapper.requestMethod = metadata.Request_Method__c;
            wrapper.handlerClass = metadata.Handler_Class__c;
            wrapper.clientId = metadata.Client_Id__c;
            wrapper.clientSecret = metadata.Client_Secret__c;
            wrapper.allowedRetry = metadata.Allowed_Retry__c;
            wrapper.gestationPeriod = metadata.Gestation_Period__c;
            wrapper.activityname = metadata.Activity_Name__c;
            wrapper.refreshallowed = metadata.Refresh_Allowed__c;
            wrapper.handlername = metadata.Handler_Class__c;
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            
            if(respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c = String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.EndPoint__c = metadata.Endpoint__c;
                returnResp = String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
            }
            else{
                // HttpRequest req = new HttpRequest();
                // Http http = new Http();
                // req.setEndpoint('Callout:S3_Upload');
                // req.setMethod('POST');
                // req.setHeader('Content-Type', 'application/json');
                // String bearer = Utility.getAccessToken();
                // req.setHeader('Authorization', 'Bearer ' + bearer);
                // //req.setHeader('Authorization', 'Bearer NGUzOTVlNzMtY2U5OC00ZTRlLWE1N2UtYzlmYjNhOWQ4NjA2OmpSQjhRfmVJNndkVzB2X0x3Umc4VmhKemtxMXVyNGJxRDhmQjlhYW4');
                // req.setHeader('Cookie', 'TS01aad9de=0135ac00a21cc845872dbd6b40e69d1f192fb3987123577a757b86398e629253e45ec2399d8352b6541c9f772253ec21766078011f');

                // //String body = '{"fileId":"068Bi000003HvcsIAC","fileName":"pan.jpg"}';
                // String body = respWrapper.payload;
                // System.debug('body---'+body);
                // req.setBody(body);
                // HttpResponse res = http.send(req);
                // System.debug('res: '+res.getBody());
                // //returnResp=JSON.serialize(res.getBody());

                // Prepare API Request
                Map<String, String> integrationRequestMap = new Map<String, String>();
                integrationRequestMap.put('intSettingName', processName);

                String bearer = Utility.getAccessToken();
                //System.debug('bearer----' + bearer);
                integrationRequestMap.put('bearer', bearer);
                integrationRequestMap.put('requestJSON', respWrapper.payload);
                if(metadata.Origin__c != null){
                integrationRequestMap.put('Origin', metadata.Origin__c);
                }

                HTTPResponse res = Utility.executeAPIRequest(integrationRequestMap);
                //System.debug('res: '+res);
                
                S3ResponseWrapper responseJSON = (S3ResponseWrapper) JSON.deserialize(res.getBody(), S3ResponseWrapper.class);
                returnResp = JSON.serialize(responseJSON.presignedUrl);
            }

            return returnResp;
        }
        catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    public class S3ResponseWrapper {
        public boolean valid;
        public String msg;	//Success
        public String presignedUrl;	//https://s1gne47.s3.ap-south-1.amazonaws.com/pan.jpg?X-Amz-Security-Token=IQoJb3JpZ2luX2VjEO3%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCmFwLXNvdXRoLTEiRjBEAiBsj%2BPQF3h%2FqPvFz%2BLiFO%2F0Ede5dGrJFXNdB9N5pTodeAIgUHacUOB1mv%2BjsUmZPVPLfCeA1ZeTmAweQjZl%2BYi0dukqvgUIRhADGgwwNDY1MDY0MTU2NjciDC34MyiwgKkxRcLDFCqbBcf8%2BOULtRe4KLfeqWv6S4tcXCduK0vFnc6Hg3ERqC77k1f5CaW6TgpLuysgqM8kMzG%2FpKSNp9JcnH1%2FOslQH3M8bdDznNYPuywpnQDe9UrerFKmxq9yvy9l6oGtPJuA%2B%2FE%2FVTcCmUDF2L40LA0oFvI2aVdpmmY%2F7lXQtdcmUdzouTjGFIk9LAd6eP0fwJryGLhuoenrGqLE75VF3LUoCA7JZeX1agosXimMx%2FAvunKYFUFSgq5WoJPvsDN7X4SgCbAPIT5ozQwUqn%2B9hyK3UhhPGmK4sdROOR2NrZqGJc63aD1Ei6bOZATYZsOnd7aGzSScHH5ZpQLVwd9k%2F0SjwqCSj7uDfowUhw5iD1hZF3DXu01Mnlw91CaDOdzO8sq8iJwnJi8CrpMPkfgxlkovDbLIHqejrx%2BFBB1y6tPkKs7BqPf6ppAs%2BfZwoFp2Tll7Ah%2BICUml7UOUdMZj2H3WKraXj791aTkrzQAgURUhrMKnO%2F2UpZqfKGHHQuS6VT%2FrUyymBFyKqMYcYqouaLeT5rz%2BYLoEEq%2B5rgUNjOUh%2FVjjkgwtAWtqi75DP5N5mZWNjADqfRRLdn%2B6j%2BNtiyxgSeXpupqZTyW%2Fknhp8bGSsMY33Ozr23nyHy7jxd4utFxYRB6fiMoo%2BTVi5Stug3%2F8Hfkn9A7oXB8XrAfN7t5nH021%2BF44VlU%2FuZPrCPvb1%2BNw%2Bar8y8nLUGGgKzww%2BdZztUbVh6BMW5de38xm7K8jR2igKMtGo6v8IyoYSbqJ%2FuAmGgagItpK0dqGrr3qqdIXOI1dgnti8KPaDf2dRSQoFVsdPc1VSXJHp%2FkI2pFeEBJI2eLCzUo991i7zCsAuaVrQRuwozPG8NwfuvXbiGj4CFm1q3GVNZoheYgdtuEw4b3gvgY6sgFvcH19yHABl0UJDYrkpQhZSXbqG2bpgrpFW%2BHO04oMGnolHkLMoPoVaf0OJrLnaEYCuxIy4S8bFvAMo%2Fk9%2Bol2b2TjdbmAVGdTOSvuLEZ3w1AW8Sh3MhP5XnAE4raFMa2tQef%2Bq55M8B4RjR3D2SlbHJwgJqGQDJtPsxOtTkm6Xvlbln1N84wbaLKYdx2qpVe7mdF6Zq%2Bn1vzPotURB%2BT1rZdI0JE3SiIaUDEyQViVHoxG&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20250317T132331Z&X-Amz-SignedHeaders=host&X-Amz-Expires=604799&X-Amz-Credential=ASIAQVU77SYZ43QXYAKC%2F20250317%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Signature=4d306f7c638fe11b684bc208167390adac14c43037728a2b7950ce65b018afe0
        public String filename;	//pan.jpg
        public String objectKey;	//pan.jpg
        //public cls_exception exception;
    }
}