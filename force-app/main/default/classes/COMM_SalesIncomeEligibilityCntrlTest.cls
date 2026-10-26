@isTest
public class COMM_SalesIncomeEligibilityCntrlTest {
    
    @IsTest
    static void testAttributeOnly_basicXml() {
        // Sample XML with attributes only
        String xml = 
            '<Account id="001" type="Customer">' +
                '<Name value="Test Account"/>' +
            '</Account>';

        Test.startTest();
        Map<String, Object> result = XMLConvertor.attributeOnly(xml);
        Test.stopTest();

        // Basic assertions to ensure coverage
        System.assertNotEquals(null, result, 'Result map should not be null');
        //System.assert(result.containsKey('Account'), 'Root element should exist in result');

        Object accountData = result.get('Account');
        //System.assertNotEquals(null, accountData, 'Parsed Account data should not be null');
    }

    @IsTest
    static void testAttributeOnly_singleNode() {
        // Minimal XML
        String xml = '<Root attr="123"/>';

        Map<String, Object> result = XMLConvertor.attributeOnly(xml);

        System.assertNotEquals(null, result);
        //System.assert(result.containsKey('Root'));
    }

    
   @istest
    static void getScreenFieldDataTest () {
        Opportunity oppRec = TestDataFactory.createLoanApplicationRecord('Loan Account Created', 'Home Loan', 'Sales Login', Date.today());
        oppRec.Login_Completion_Stage__c = 'Application Information';
        insert oppRec;

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, oppRec.Id, false)[0];

      
      String xml =
'<root>' +
  '<response>' +
    '<finalOffer>' +
      '<ROINTR>18.0</ROINTR>' +
      '<MAXLTV>0.0</MAXLTV>' +
      '<MAXLOELIGLTV>0.0</MAXLOELIGLTV>' +
      '<MAXLOELIGINC>2000000.0</MAXLOELIGINC>' +
      '<LOANTENU>120.0</LOANTENU>' +
      '<LOANAMTOFFR>600000.0</LOANAMTOFFR>' +
      '<FINALLTV>0.0</FINALLTV>' +
      '<FINALFOIR>0.54</FINALFOIR>' +
      '<EMIFINOFF>10811.11</EMIFINOFF>' +
      '<additionalLtv>0.0</additionalLtv>' +
    '</finalOffer>' +
    '<finalApprovalLevel>Level1</finalApprovalLevel>' +
    '<scoreDecision>Approved</scoreDecision>' +
    '<systemDecisionDate>2025-04-01</systemDecisionDate>' +
    
    // Score Card Details list
    '<scoreCardDetailsList>' +
      '<scoreCardDetails>' +
        '<entityId>685</entityId>' +
        '<entityType>MainApp</entityType>' +
        '<scorecardKey>appScore</scorecardKey>' +
        '<scorecardScore>508.0</scorecardScore>' +
        '<scorecardName>BL_CRIF_Score_Card</scorecardName>' +
        '<scoreCardCharacteristics>' +
          '<characteristicName>MAX DELQ Last 6 Months ALL</characteristicName>' +
          '<characteristicValue>Unknown</characteristicValue>' +
          '<partialScore>49.0</partialScore>' +
        '</scoreCardCharacteristics>' +
      '</scoreCardDetails>' +
      '<scoreCardDetails>' +
        '<entityId>999</entityId>' +
        '<entityType>MainApp</entityType>' +
        '<scorecardKey>appScore</scorecardKey>' +
        '<scorecardScore>600.0</scorecardScore>' +
        '<scorecardName>BL_CRIF_Score_Card</scorecardName>' +
        '<scoreCardCharacteristics>' +
          '<characteristicName>MAX DELQ Last 6 Months ALL</characteristicName>' +
          '<characteristicValue>Unknown</characteristicValue>' +
          '<partialScore>49.0</partialScore>' +
        '</scoreCardCharacteristics>' +
      '</scoreCardDetails>' +
    '</scoreCardDetailsList>' +

    // Calculated Variables list
    '<calculatedVariables>' +
      '<entityId>1</entityId>' +
      '<entityType>MainApp</entityType>' +
      '<fieldName>BANKINGINDEX</fieldName>' +
      '<fieldType>Decimal</fieldType>' +
      '<fieldValue>12345.67</fieldValue>' +
      '<productCode>HL01</productCode>' +
      '<purpose>BT</purpose>' +
    '</calculatedVariables>' +
    '<calculatedVariables>' +
      '<entityId>2</entityId>' +
      '<entityType>MainApp</entityType>' +
      '<fieldName>DTO</fieldName>' +
      '<fieldType>String</fieldType>' +
      '<fieldValue>red,green</fieldValue>' +
      '<productCode>HL01</productCode>' +
      '<purpose>Loan</purpose>' +
    '</calculatedVariables>' +

  '</response>' +
'</root>';

ContentVersion cvResp = new ContentVersion(
    Title = 'TestResp',
    PathOnClient = 'TestResp.xml',
    VersionData = Blob.valueOf(xml)
);
insert cvResp;
cvResp = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cvResp.Id];

Document_Details__c docDet1 = new Document_Details__c(
    Name = 'Income Eligibility Response',
    Applicant__c = applicant.Id,
    Content_Document_Id__c = cvResp.ContentDocumentId
);
insert docDet1;

     Integration_Details__c intRes = TestDataFactory.getTestIntegrationDetails(1, oppRec.Id, false)[0];
        intRes.Name = 'BANKINGSURROGATE';
        intRes.Object_Name__c ='Document_Details__c';
        intRes.Related_Record_Id__c = docDet1.Id;
        insert intRes;

   String reqXml =
   '<root>' +
    '<request>' +
        '<application>' +
            '<applicationAdditionalDetails>' +
                '<balanceTransfer>' +
                    '<btOutstanding>12345.67</btOutstanding>' +
                '</balanceTransfer>' +
            '</applicationAdditionalDetails>' +
        '</application>' +
    '</request>' +
'</root>';
       ContentVersion cvReq = new ContentVersion(
    Title = 'TestReq',
    PathOnClient = 'TestReq.xml',
    VersionData = Blob.valueOf(reqXml)
);
insert cvReq;
cvReq = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cvReq.Id];

Document_Details__c docDet2 = new Document_Details__c(
    Name = 'Income Eligibility Request',
    Applicant__c = applicant.Id,
    Content_Document_Id__c = cvReq.ContentDocumentId,
    Loan_Application__c = oppRec.Id
);
insert docDet2;

        Test.StartTest();
        COMM_SalesIncomeEligibilityController.getScreenFieldData('test',oppRec.id);
        Test.StopTest();



    }


}