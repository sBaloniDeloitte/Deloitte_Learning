/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-12-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class HL_EligibilityApiController {
    
    @AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap){
        try {
            Boolean isIncomeFromSales = false; 
            Integration_Details__c integrationDetails = new Integration_Details__c();
            String loanId = inputMap.get('loanId');
            String productName = inputMap.get('productName');
            Id productId = inputMap.get('productId');
            String processName = inputMap.get('processName');   //FICO Cibil And Income Eligibility
            String eligibilityType = inputMap.get('eligibilityType');   //Banking Method - HT Program
            Boolean callForDeviation = false;
            Boolean showCalculator = inputMap.containsKey('calculator') ? Boolean.valueOf((String) inputMap.get('calculator')) : false;
            boolean checkTest = System.Test.isRunningTest();

            if(inputMap.containsKey('callForDeviation')){
                callForDeviation = Boolean.valueOf(inputMap.get('callForDeviation')) == true ? true : false;
            }

            String adb = inputMap.containsKey('adb') ? inputMap.get('adb') : '';
            if(inputMap.containsKey('isIncomeFromSales')){
                isIncomeFromSales = Boolean.valueOf(inputMap.get('isIncomeFromSales')) == true ? true : false;
            }
            
            String returnResp;
            String resultMessage;
            /*
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
                                                Activity_Name__c
                                                FROM Integration_Master__mdt 
                                                WHERE Activity_Name__c =: processName LIMIT 1];

            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
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
            wrapper.eligibilityType = eligibilityType;
            wrapper.productName = productName;
            wrapper.adb = adb;
            wrapper.isIncomeFromSales = isIncomeFromSales;
            wrapper.callForDeviation = callForDeviation;
            wrapper.userCalValues = inputMap.get('userCalValues');
            wrapper.showCalculator = showCalculator;
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            if(checkTest){
                respWrapper.prerequisiteError = null;
                respWrapper.payload = '{"message":{"response":{"systemDecisionDateTime":"","systemDecisionDate":"","systemDecision":"","strategyUsed":"","scoreDecision":"","scoreCardDetails":{"scorecardScore":"0","scorecardName":"","scorecardKey":"","scoreCardCharacteristics":{"partialScore":"","characteristicValue":"","characteristicName":""},"purpose":"","entityType":"","entityId":"","characteristicCount":"0"},"responseDeviations":{"ruleName":"","ruleLevel":"","ruleId":"","ruleDescription":"","ruleCategory":"","ruleAction":"","recommendationText":"","reasonText":"","entityType":"","entityId":"","deviationType":"","approvalLevel":"","accountNo":""},"finalApprovalLevel":"","errorResponse":{"errorType":"","errorText":"","errorName":"","errorId":"","errorCode":"","errorAction":""},"calculatedVariables":{"purpose":"","productCode":"","fieldValue":"","fieldType":"","fieldName":"","entityType":"","entityId":""}},"request":{"application":{"verifications":{"tvInitiation":{"verificationCategory":0,"tv":0,"remark":"","reason":0,"lastVerificationDate":"","lastVerficationAgency":"","lastStatus":"","depositName":"Sarthak Kasture","depositCif":"0015537","collatarelType":"","agency":""},"rcuInitiation":[],"pdInitiation":[],"lvWaiver":{"verificationdate":"","status":"0","remark":"","reason":0,"documentType":"0","decision":"","collatarel":""},"lvInitiation":{"verificationdate":"2026-03-30 07:01:07","status":"Assigned to Admin","remark":"","decision":null,"collatarel":"APPCOL - 0000301","agency":"AARATIE SHINDE & CO"},"fiInitiation":[]},"tvApproval":{"finalValuationAmount":{"finalValAmount":0,"collateralReference":""}},"step":{"stepapplicableornot":null},"source":"GHF","score":{"experianScoreType":"","experianScoreRequired":"","appScoreRequired":""},"schedule":{"preemiapplicableornot":null,"preemiamount":0,"preamitenure":0,"moratoriumtenure":0,"moratoriumappliableornot":null,"maturityDate":"2027-12-30","loanType":"","loanReference":"","loanAmount":10000000,"installmentroi":0,"graceperiodroi":10,"firstdisbursementdate":"2026-03-30+00:00","emitenure":0,"emiholidayepplicableornot":null,"emiamount":0,"currencyRemove":"INR"},"pdDoneBy":"Romesh Somani","ocrdetails":{"totalocrreceivable":0,"totaldemand":0,"parentloanreferencenumber":"","ocrtype":"","ocrid":"","ocrdescription":"","ocrapplicableornot":null,"customerportionpercentage":0},"loanBasicDetail":{"sourcingDetails":{"sourcingOfficer":"0","sourcingChannelCategory":"","sourcingBranch":"","salesDepartment":"0.0","refferalId":"","purposeOfLoan":"BR","loanBranch":"1001","employeeName":"","dmaCode":"","directSalesAgent":"","buffer4":"0","buffer3":"","buffer2":"0.0","buffer1":"0","asmName":"0.00"},"productCategory":"CONV","paymentDetails":{"unplannedEMIHolidayLockPeriod":0,"scheduleMethod":"EQUAL","paymentFrequency":"0","paymentAmount":0.0,"numberOfInstallments":20,"nextPaymentFreqDate":"2026-03-30+00:00","nextInterestReviewFreqDate":"2026-03-30+00:00","nextInterestFreqDate":"2026-03-30+00:00","minInterestRate":0.0,"maxUnplannedEMIHolidays":0,"maxInterestRate":0.0,"maturityDate":"2027-12-30","interestReviewFrequency":"M0003","interestRateType":"","interestFrequency":"M0003","fixedRate":0.0,"bpiTreatment":"No BPI","baseRate":"20.00","allowPlannedEMIHolidayGrace":null,"allowPlannedEMIHoliday":null,"allowBPI":false,"actualInterestRate":0.0},"loanType":"","loanReference":"LA-000000746","leadId":"","keyDetails":{"totalDisbursements":0.0,"tdsApplicable":null,"stepLoan":null,"parentLoanReference":"","netLoanAmount":0,"loanStartDate":"2025-12-30+00:00","loanAmount":100000,"firstDisbursementAmount":0.0,"eligibilityMethod":"","applicationRequestDate":"2025-12-30+00:00","allowOCR":null,"allowLoanSplit":null,"allowGrace":null},"interestDaysBasis":null,"division":"RETAIL","businessVertical":"","applicationNo":"LA-000000746"},"entity":"PLF","collateral":{"property":[{"propertyType":"APARTMENT","projectName":"","markertValue":0,"documentedValue":0,"developerName":"CEAT Company","constructionType":"UNDER CONSTRUCTION","collateralUsage":"UNDER CONSTRUCTION","collateralType":"RESIDENTIAL","collateralReference":"","carpetArea":0,"buffer5":"","buffer4":"","buffer3":"","buffer2":"","buffer1":""}]},"coAppAndGuarantors":{"guarantorsDetails":{"worstStatus":"","status":"","idType":"","idProof":"","id":"","gurantee":0,"guarantorsName":"","exposureSolePrimary":0,"exposureGuarantor":0,"exposureCoapplicant":0,"contactNumber":""},"coApplicantDetails":{"worstStatus":"","status":"","exposureSolePrimary":0,"exposureCoapplicant":0,"customerName":"","customerCif":"","authoritySignatory":null}},"applicationAdditionalDetails":{"sourcingDetail":{"schemeCode":"","refCode6":"","refCode5":"","refCode4":"","refCode3":"","refCode2":"","refCode1":"","ghfRm":"","ghfAsm":"","employeeCode":"","channelPartnerCode":""},"selfEmployedRiskSegment":0,"selfEmployedRiskScore":0,"remark1":"","referenceDetails":{"reference2":{"state":"","relationshipWithApplicant":"","pincode":"638462","mobileNo":"8686868686","lastName":"Singh","firstName":"Satyam","city":"","address":"Test"},"reference1":{"state":"","relationshipWithApplicant":"","pincode":"500080","mobileNo":"8787878787","lastName":"Awasthi","firstName":"Neeti","city":"","address":"Test"},"givenGuaranteeToLoan":null},"other":{"stageOfConstruction":"","sblMet":"","riskCategorization":"","rentalIncomeProgram":"","psl":"","propertyIdentified":"","pep":"","lendingType":"","gblMet":"","finalLtvPercentage":0,"finalLoanAmount":0,"finalFoirPercentage":0,"eligibilityMethod":"","creExposure":null,"cinNo":"","buffer9":"","buffer8":"","buffer7":"","buffer6":"","buffer5":"0","buffer4":"","buffer3":"","buffer25":"","buffer24":"","buffer23":"","buffer22":"","buffer21":"","buffer20":"","buffer2":"","buffer19":"","buffer18":"","buffer17":"","buffer16":"","buffer15":"","buffer14":"","buffer13":"","buffer12":"","buffer11":"UNDER CONSTRUCTION","buffer10":"","buffer1":"","borrowerType":""},"lanHunterStatus":"","hunterStatus":"","hunterRemark":"","hunterRcuStatus":"","finalOffer":{"ROINTR":"","MAXLTV":"","MAXLOELIGLTV":"","MAXLOELIGINC":"","LOANTENU":"","LOANAMTOFFR":"","FINALLTV":"","FINALFOIR":"","EMIFINOFF":"","additionalLtv":""},"buffer9":"","buffer8":"","buffer7":"","buffer6":"","buffer5":"","buffer4":"","buffer3":"","buffer2":"","buffer10":"","buffer1":"","balanceTransfer":{"topUpLanNo":"","topUpAmount":0,"specifyOtherEndUse":"","nameOfOtherFinancialInst":"","nameOfFinancialInstitute":"","moratoriumSchemeFlagging":null,"endUseForTopUp":"","currentOccupancyOfProperty":"","consolidatedLtv":"","btOutstanding":0.0,"btMob":0,"btLoanLanNo":0.0}},"applicants":[{"subSegment":"","subSector":"SBSC3575","segment":"","sector":"SAL9","residentialStatus":"Resident","qualification":"PG","posidex":"","panNumber":"AIFPP5729A","numOfDependents":0,"natureOfBusiness":"","maritalStatus":"Single","kycDetails":{"phoneDetails":{"priority":"5","phoneTypeCode":"","phoneNumber":"7722094699","customerCif":"0015537"},"emailDetails":{"priority":"5","emailType":"","email":"sakasture@deloitte.com","customerCif":"0015537"},"customerIds":[{"remarks":"","issuedOn":"","issuedCountry":"IN","idType":"POA","idNumber":"666001902375","expiryDate":"","documentName":"Aadhaar Back","customerCif":"0015537"},{"remarks":"","issuedOn":"","issuedCountry":"IN","idType":"POA","idNumber":"","expiryDate":"","documentName":"Job card issued by NREGA","customerCif":"0015537"},{"remarks":"","issuedOn":"","issuedCountry":"IN","idType":"POA","idNumber":"666001902375","expiryDate":"","documentName":"Aadhaar Front","customerCif":"0015537"}],"addressDetails":[{"priority":4,"pinCodeServicability":true,"pinCode":"400079","locality":"","landmark":null,"city":"Telanagana","addressType":"PRIRES"},{"priority":5,"pinCodeServicability":true,"pinCode":"400079","locality":"","landmark":null,"city":"Telanagana","addressType":"ALTRESI"}]},"employmentType":"SALARIED","dsaCode":null,"dateOfIncorporation":"","dateOfBirth":"1966-11-05","customerCif":"0015537","customerCategory":"","customerBranch":"1001","creditBureauReports":"<CreditReport><Header><SegmentTag>TUEF</SegmentTag><Version>12</Version><ReferenceNumber>3720679591</ReferenceNumber><MemberCode>HF64228888_CIRC2CNPE          </MemberCode><SubjectReturnCode>1</SubjectReturnCode><EnquiryControlNumber>010714510619</EnquiryControlNumber><DateProcessed>19032026</DateProcessed><TimeProcessed>232830</TimeProcessed></Header><NameSegment><Length>03</Length><SegmentTag>N01</SegmentTag><ConsumerName1FieldLength>05</ConsumerName1FieldLength><ConsumerName1>SUNIL</ConsumerName1><ConsumerName3FieldLength>06</ConsumerName3FieldLength><ConsumerName3>AJMANI</ConsumerName3><DateOfBirthFieldLength>08</DateOfBirthFieldLength><DateOfBirth>31071955</DateOfBirth><GenderFieldLength>01</GenderFieldLength><Gender>1</Gender></NameSegment><IDSegment><Length>03</Length><SegmentTag>I01</SegmentTag><IDType>01</IDType><IDNumberFieldLength>10</IDNumberFieldLength><IDNumber>AITPA9314J</IDNumber><EnrichedThroughEnquiry>Y</EnrichedThroughEnquiry></IDSegment><IDSegment><Length>03</Length><SegmentTag>I02</SegmentTag><IDType>06</IDType><IDNumberFieldLength>12</IDNumberFieldLength><IDNumber>XXXXXXXXXXXX</IDNumber><EnrichedThroughEnquiry>Y</EnrichedThroughEnquiry></IDSegment><TelephoneSegment><Length>03</Length><SegmentTag>T01</SegmentTag><TelephoneNumberFieldLength>10</TelephoneNumberFieldLength><TelephoneNumber>9217590630</TelephoneNumber><TelephoneType>01</TelephoneType><EnrichedThroughEnquiry>Y</EnrichedThroughEnquiry></TelephoneSegment><ScoreSegment><Length>10</Length><ScoreName>CIBILTUSC3</ScoreName><ScoreCardName>08</ScoreCardName><ScoreCardVersion>10</ScoreCardVersion><ScoreDate>19032026</ScoreDate><Score>000-1</Score><BureauCharacterstics></BureauCharacterstics></ScoreSegment><Address><AddressSegmentTag>PA</AddressSegmentTag><Length>03</Length><SegmentTag>A01</SegmentTag><AddressLine1FieldLength>24</AddressLine1FieldLength><AddressLine1>T60 THIRD FLOOR BLOOK  T</AddressLine1><AddressLine2FieldLength>27</AddressLine2FieldLength><AddressLine2>JANTA MARKET RAJOURI GRADEN</AddressLine2><AddressLine5FieldLength>09</AddressLine5FieldLength><AddressLine5>NEW DELHI</AddressLine5><StateCode>07</StateCode><PinCodeFieldLength>06</PinCodeFieldLength><PinCode>110027</PinCode><AddressCategory>01</AddressCategory><ResidenceCode>01</ResidenceCode><DateReported>18022026</DateReported><EnrichedThroughEnquiry>Y</EnrichedThroughEnquiry></Address><Enquiry><Length>04</Length><SegmentTag>I001</SegmentTag><DateOfEnquiryFields>07032026</DateOfEnquiryFields><EnquiringMemberShortNameFieldLength>13</EnquiringMemberShortNameFieldLength><EnquiringMemberShortName>NOT DISCLOSED</EnquiringMemberShortName><EnquiryPurpose>02</EnquiryPurpose><EnquiryAmountFieldLength>08</EnquiryAmountFieldLength><EnquiryAmount>10100000</EnquiryAmount></Enquiry><Enquiry><Length>04</Length><SegmentTag>I002</SegmentTag><DateOfEnquiryFields>18022026</DateOfEnquiryFields><EnquiringMemberShortNameFieldLength>13</EnquiringMemberShortNameFieldLength><EnquiringMemberShortName>NOT DISCLOSED</EnquiringMemberShortName><EnquiryPurpose>06</EnquiryPurpose><EnquiryAmountFieldLength>05</EnquiryAmountFieldLength><EnquiryAmount>49500</EnquiryAmount></Enquiry><Enquiry><Length>04</Length><SegmentTag>I003</SegmentTag><DateOfEnquiryFields>18022026</DateOfEnquiryFields><EnquiringMemberShortNameFieldLength>13</EnquiringMemberShortNameFieldLength><EnquiringMemberShortName>NOT DISCLOSED</EnquiringMemberShortName><EnquiryPurpose>02</EnquiryPurpose><EnquiryAmountFieldLength>08</EnquiryAmountFieldLength><EnquiryAmount>10000000</EnquiryAmount></Enquiry><End><SegmentTag>ES07</SegmentTag><TotalLength>0000585</TotalLength></End></CreditReport>","companyCategory":"","caste":"General","bankingDetails":[{"typeOfBanks":"","salaryAccount":null,"repaymentFrom":"","phoneNumber":"7722094699","numOfMonthsBanking":1,"monthAndYearDayBalance":"","iwOwRatio":"0","externalLiabilities":[{"trackCheckFrom":0,"totalTenure":0,"status":"","sourceOfInfo":0,"securityDetails":"","roi":"","repaymentFrom":"","repaymentBankAccNo":"","remarks":"","product":"","pos":"","ownerShip":"","overdue":"","outstandingBalance":"","otherFinancialInstitute":"","originalAmount":"0.0","noOfBouncesL6m":0,"noOfBouncesL3m":0,"noOfBouncesL12m":0,"mob":0,"loanDate":"2025-12-30+00:00","liabilitySequence":0,"last6Months":0,"last3Months":0,"last24Months":0,"installmentAmount":{"amount":0},"imputedEmi":"","endUseOfFunds":"","emiConsideredForFoir":true,"consideredRtrBasedLoan":null,"bankName":"","balanceTenure":0}],"documentName":"NONOD","customerCif":"0015537","ccLimit":null,"bankName":"","bankBranch":"1001","addToBeneficiary":null,"accountType":"","accountOpenDate":"2026-03-30+00:00","accountNo":"1234567778747","accountBehaviourDetails":{"salaryOrIncome":0,"returnCount":0,"returnChequeAmount":0,"remarks":"","paymentCheques":0,"monthAndYear":"","debits":0,"customerCif":"0015537","chequeSequence":0},"accHolderName":"Sarthak Kasture"}],"applicantType":"MainApp","applicantAdditionalDetails":{"sepEligibility":{"MAXFOIRSEP":"","isGrowthSustainable":"","INCMG":"","GROWANNRC":"","grossAnnualRecieptsPreviousYear":0.0,"grossAnnualRecieptsLatestYear":0.0,"additionalMultiplier":0.0,"additionalFoir":0},"senpRiskScoreEligibility":{"processBelowRiskCutOff":"","debtEquityRatio":0.0,"ccOdUtilization":"","abbEmiRatio":0.0},"senpPreviousYearEligibility":{"turnover":0.0,"salaryPartner":0.0,"otherIncome":0.0,"oneTimeIncome":0.0,"oneTimeExpense":0.0,"netPbt":0.0,"interestRelative":0.0,"interestPartner":0.0,"interestBank":0.0,"grossProfit":0.0,"depreciation":0.0,"CASHPROFPREV":""},"senpLatestYearEligibility":{"turnover":0.0,"salaryPartner":0.0,"otherIncome":0.0,"oneTimeIncome":0.0,"oneTimeExpense":0.0,"netPbt":0.0,"interestRelative":0.0,"interestPartner":0.0,"interestBank":0.0,"grossProfit":0.0,"depreciation":0.0,"CASHPROFLAST":""},"senpGrowthPercentageEligibility":{"TURNGROPER":"","isTurnoverGrowthSutainable":"","isGrossProfitGrowthSutainable":null,"isCashProfitGrowthSutainable":"","GRPRGRPER":"","CASFPRGPER":""},"salariedEligibility":{"processCaseRiskCutoff":"","previousYearBonus":0.0,"MAXFOIRSAL":"","latestYearBonus":0.0,"incentiveMonth6":0.0,"incentiveMonth5":0.0,"incentiveMonth4":0.0,"incentiveMonth3":0.0,"incentiveMonth2":0.0,"incentiveMonth1":0.0,"buffer9":"","buffer8":"","buffer7":"","buffer6":"","buffer5":"","buffer4":"","buffer3":"","buffer2":"","buffer10":"","buffer1":"100","additionalFoir":0},"poaHolderDetails":{"subDistrict":"","state":"","relationWithApplicant":"","poBox":"","pinCode":"","photoIdType":"","photoIdNo":"","mobileNo":"","locality":"","landmark":"","fullName":"","district":"","country":"","city":"","addressType":"","addressIdType":"","addressIdNo":""},"otherSenpInputEligibility":{"processBelowRiskCutOff":"","overrideAbbEmiRatio":0.0,"MAXGROSSENP":"","MAXFOIRSENP":"","maxAbbEmiRatioAllowed":"","industryMarginCRISIL":0.0,"incomeProgram":"","ELIMAXLA":"","avgMonthlyBalancePerfios":0.0,"annulisedSalaryDirector":0.0,"additionalGrossMargin":0.0,"additionalFoir":0},"occupationCategory":"","nriIncomeDetails":{"workExperienceAbroadMonths":"","rateOfConversion":0.0,"monthlyNetSalaryForeignCurrency":"","dateOfConversion":"","currencyRemove":""},"natureOfEmployment":"","leadSquaredLeadId":"","GROWPER":"","digitalData":{"perfiosObligation":"","perfiosIncome":"","bureauObligation":""},"customerSep":{"typeOfService":"","totalWorkExperience":10,"product":"","industry":""},"customerSenp":{"totalWorkExperience":10,"senp":"","dateOfCommencement":null},"customerSelfEmployedProfesional":{"rentalIncome":0,"profession":0,"otherIncome":0,"grossTurnOver":0,"grossReceiptFromBusiness":0},"customerSalaried":{"totalWorkExperience":10,"ifSalaried":"","idType":"","employerName":"","emailIdOfficial":"","designation":"","currentWorkExperience":0.0},"customerNonIndividual":{"profession":0.0,"otherIncome":0.0,"netProfitFromBusiness":0.0},"customerIndividualSalaried":{"rentalIncome":0.0,"otherIncome":0.0,"grossAnnualSalaryIncome":180000.0},"customerEntityType":{"pinCode":0,"landmark":"","businessOrProffessional":""},"customerAreaName":{"state":"","district":"","city":""},"cibil":{"writeOffNonCredit":"","writeOffCredit":"","writeOff":"","timeProcessed":"23:28:30","settle":"","scoreName":"CIBILTUSC3","scorecardVersion":"10","scorecardName":"08","score":"000-1","restructured":"","recentLoans":0,"plus60DpdL3m":0,"plus30PdpL6m":0,"plus30DpdL12m":0,"panNumber":"AIFPP5729A","noInquiryL3m":0,"noInquiryL1m":0,"noAccountsDeliquentL6m":0,"noAccounts30DpdL12m":0,"memberReferenceNo":"HF64228888_CIRC2CNPE","liveUsedCardLoanEmi":0.0,"liveUsedCardLoan":0.0,"liveSecuredCardOutstanding":0.0,"liveSecuredAndEmi":0.0,"livePlLoanAmount":0.0,"livePersonalLoanEmi":0.0,"liveLoanOnCreditCardEmi":0.0,"liveLoanOnCreditCard":0.0,"liveHlOrLapLoanEmi":0.0,"liveHlOrLapLoanAmount":0.0,"liveEducationLoanEmi":0.0,"liveEducationLoanAmount":0.0,"liveCreditCardOutstanding":0.0,"liveCreditCardEmi":0.0,"liveConsumerLoanEmi":0.0,"liveConsumerLoan":0.0,"liveCommercialVehicleLoanEmi":0.0,"liveCommercialVehicleLoan":0.0,"liveBusinessLoanEmi":0.0,"liveBlLoanAmount":0.0,"liveAutoLoanEmi":0.0,"liveAutoLoanAmount":0.0,"live2WheelerLoanEmi":0.0,"live2WheelerLoanAmount":0.0,"executionResponse":"","emiBouncesL6m":0,"emiBouncesL3m":0,"emiBounceL3m":0,"emiBounceL12m":0,"derog":"","dateProcessed":"19/03/2026","customerName":"Sarthak Kasture","creditCardOverdueAmount":0.0,"creditAmountOverdue":"","anyDpdL12m":0},"buffer9":"","buffer8":"","buffer7":"","buffer6":"","buffer5":"","buffer4":"","buffer3":"","buffer20":"","buffer2":"","buffer19":"","buffer18":"","buffer17":"","buffer16":"","buffer15":"","buffer14":"","buffer13":"","buffer12":"","buffer11":"","buffer10":"","buffer1":"","associatedCompanies":{"associatedCompanyName5":"","associatedCompanyName4":"","associatedCompanyName3":"","associatedCompanyName2":"","associatedCompanyName1":""},"additionalDetail":{"purposeOfLoanOthers":"BR","netBonus":0.0,"netAnnual":180000.0,"buffer5":"0","buffer4":"","buffer3":"","buffer2":"","buffer1":""}},"addressOwnershipType":null}]}},"invocation":{"version":"","serviceexecute":"FICO","responseStatus":"","decisionService":"HL","decisionPointAction":"BUTTON","decisionPoint":"HL_CREDIT","applicationNumber":"LA-000000746","applicationDate":"2025-12-30+00:00"}}}';
            }

            
			
            if(respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name = processName;
                integrationDetail.Object_Name__c = 'Opportunity';
                resultMessage = String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                //System.debug('resultMessage: '+resultMessage);
                returnResp = resultMessage;
            }*/
            Integration_Details__c integrationDetail = new Integration_Details__c();
            String xmlRespStr = '{"message":{"response":{"systemDecisionDateTime":"","systemDecisionDate":"","systemDecision":"","strategyUsed":"","scoreDecision":"","scoreCardDetails":{"scorecardScore":"0","scorecardName":"","scorecardKey":"","scoreCardCharacteristics":{"partialScore":"","characteristicValue":"","characteristicName":""},"purpose":"","entityType":"","entityId":"","characteristicCount":"0"},"responseDeviations":{"ruleName":"","ruleLevel":"","ruleId":"","ruleDescription":"","ruleCategory":"","ruleAction":"","recommendationText":"","reasonText":"","entityType":"","entityId":"","deviationType":"","approvalLevel":"","accountNo":""},"finalApprovalLevel":"","errorResponse":{"errorType":"","errorText":"","errorName":"","errorId":"","errorCode":"","errorAction":""},"calculatedVariables":{"purpose":"","productCode":"","fieldValue":"","fieldType":"","fieldName":"","entityType":"","entityId":""}},"request":{"application":{"verifications":{"tvInitiation":{"verificationCategory":0,"tv":0,"remark":"","reason":0,"lastVerificationDate":"","lastVerficationAgency":"","lastStatus":"","depositName":"Sarthak Kasture","depositCif":"0015537","collatarelType":"","agency":""},"rcuInitiation":[],"pdInitiation":[],"lvWaiver":{"verificationdate":"","status":"0","remark":"","reason":0,"documentType":"0","decision":"","collatarel":""},"lvInitiation":{"verificationdate":"2026-03-30 07:01:07","status":"Assigned to Admin","remark":"","decision":null,"collatarel":"APPCOL - 0000301","agency":"AARATIE SHINDE & CO"},"fiInitiation":[]},"tvApproval":{"finalValuationAmount":{"finalValAmount":0,"collateralReference":""}},"step":{"stepapplicableornot":null},"source":"GHF","score":{"experianScoreType":"","experianScoreRequired":"","appScoreRequired":""},"schedule":{"preemiapplicableornot":null,"preemiamount":0,"preamitenure":0,"moratoriumtenure":0,"moratoriumappliableornot":null,"maturityDate":"2027-12-30","loanType":"","loanReference":"","loanAmount":10000000,"installmentroi":0,"graceperiodroi":10,"firstdisbursementdate":"2026-03-30+00:00","emitenure":0,"emiholidayepplicableornot":null,"emiamount":0,"currencyRemove":"INR"},"pdDoneBy":"Romesh Somani","ocrdetails":{"totalocrreceivable":0,"totaldemand":0,"parentloanreferencenumber":"","ocrtype":"","ocrid":"","ocrdescription":"","ocrapplicableornot":null,"customerportionpercentage":0},"loanBasicDetail":{"sourcingDetails":{"sourcingOfficer":"0","sourcingChannelCategory":"","sourcingBranch":"","salesDepartment":"0.0","refferalId":"","purposeOfLoan":"BR","loanBranch":"1001","employeeName":"","dmaCode":"","directSalesAgent":"","buffer4":"0","buffer3":"","buffer2":"0.0","buffer1":"0","asmName":"0.00"},"productCategory":"CONV","paymentDetails":{"unplannedEMIHolidayLockPeriod":0,"scheduleMethod":"EQUAL","paymentFrequency":"0","paymentAmount":0.0,"numberOfInstallments":20,"nextPaymentFreqDate":"2026-03-30+00:00","nextInterestReviewFreqDate":"2026-03-30+00:00","nextInterestFreqDate":"2026-03-30+00:00","minInterestRate":0.0,"maxUnplannedEMIHolidays":0,"maxInterestRate":0.0,"maturityDate":"2027-12-30","interestReviewFrequency":"M0003","interestRateType":"","interestFrequency":"M0003","fixedRate":0.0,"bpiTreatment":"No BPI","baseRate":"20.00","allowPlannedEMIHolidayGrace":null,"allowPlannedEMIHoliday":null,"allowBPI":false,"actualInterestRate":0.0},"loanType":"","loanReference":"LA-000000746","leadId":"","keyDetails":{"totalDisbursements":0.0,"tdsApplicable":null,"stepLoan":null,"parentLoanReference":"","netLoanAmount":0,"loanStartDate":"2025-12-30+00:00","loanAmount":100000,"firstDisbursementAmount":0.0,"eligibilityMethod":"","applicationRequestDate":"2025-12-30+00:00","allowOCR":null,"allowLoanSplit":null,"allowGrace":null},"interestDaysBasis":null,"division":"RETAIL","businessVertical":"","applicationNo":"LA-000000746"},"entity":"PLF","collateral":{"property":[{"propertyType":"APARTMENT","projectName":"","markertValue":0,"documentedValue":0,"developerName":"CEAT Company","constructionType":"UNDER CONSTRUCTION","collateralUsage":"UNDER CONSTRUCTION","collateralType":"RESIDENTIAL","collateralReference":"","carpetArea":0,"buffer5":"","buffer4":"","buffer3":"","buffer2":"","buffer1":""}]},"coAppAndGuarantors":{"guarantorsDetails":{"worstStatus":"","status":"","idType":"","idProof":"","id":"","gurantee":0,"guarantorsName":"","exposureSolePrimary":0,"exposureGuarantor":0,"exposureCoapplicant":0,"contactNumber":""},"coApplicantDetails":{"worstStatus":"","status":"","exposureSolePrimary":0,"exposureCoapplicant":0,"customerName":"","customerCif":"","authoritySignatory":null}},"applicationAdditionalDetails":{"sourcingDetail":{"schemeCode":"","refCode6":"","refCode5":"","refCode4":"","refCode3":"","refCode2":"","refCode1":"","ghfRm":"","ghfAsm":"","employeeCode":"","channelPartnerCode":""},"selfEmployedRiskSegment":0,"selfEmployedRiskScore":0,"remark1":"","referenceDetails":{"reference2":{"state":"","relationshipWithApplicant":"","pincode":"638462","mobileNo":"8686868686","lastName":"Singh","firstName":"Satyam","city":"","address":"Test"},"reference1":{"state":"","relationshipWithApplicant":"","pincode":"500080","mobileNo":"8787878787","lastName":"Awasthi","firstName":"Neeti","city":"","address":"Test"},"givenGuaranteeToLoan":null},"other":{"stageOfConstruction":"","sblMet":"","riskCategorization":"","rentalIncomeProgram":"","psl":"","propertyIdentified":"","pep":"","lendingType":"","gblMet":"","finalLtvPercentage":0,"finalLoanAmount":0,"finalFoirPercentage":0,"eligibilityMethod":"","creExposure":null,"cinNo":"","buffer9":"","buffer8":"","buffer7":"","buffer6":"","buffer5":"0","buffer4":"","buffer3":"","buffer25":"","buffer24":"","buffer23":"","buffer22":"","buffer21":"","buffer20":"","buffer2":"","buffer19":"","buffer18":"","buffer17":"","buffer16":"","buffer15":"","buffer14":"","buffer13":"","buffer12":"","buffer11":"UNDER CONSTRUCTION","buffer10":"","buffer1":"","borrowerType":""},"lanHunterStatus":"","hunterStatus":"","hunterRemark":"","hunterRcuStatus":"","finalOffer":{"ROINTR":"","MAXLTV":"","MAXLOELIGLTV":"","MAXLOELIGINC":"","LOANTENU":"","LOANAMTOFFR":"","FINALLTV":"","FINALFOIR":"","EMIFINOFF":"","additionalLtv":""},"buffer9":"","buffer8":"","buffer7":"","buffer6":"","buffer5":"","buffer4":"","buffer3":"","buffer2":"","buffer10":"","buffer1":"","balanceTransfer":{"topUpLanNo":"","topUpAmount":0,"specifyOtherEndUse":"","nameOfOtherFinancialInst":"","nameOfFinancialInstitute":"","moratoriumSchemeFlagging":null,"endUseForTopUp":"","currentOccupancyOfProperty":"","consolidatedLtv":"","btOutstanding":0.0,"btMob":0,"btLoanLanNo":0.0}},"applicants":[{"subSegment":"","subSector":"SBSC3575","segment":"","sector":"SAL9","residentialStatus":"Resident","qualification":"PG","posidex":"","panNumber":"AIFPP5729A","numOfDependents":0,"natureOfBusiness":"","maritalStatus":"Single","kycDetails":{"phoneDetails":{"priority":"5","phoneTypeCode":"","phoneNumber":"7722094699","customerCif":"0015537"},"emailDetails":{"priority":"5","emailType":"","email":"sakasture@deloitte.com","customerCif":"0015537"},"customerIds":[{"remarks":"","issuedOn":"","issuedCountry":"IN","idType":"POA","idNumber":"666001902375","expiryDate":"","documentName":"Aadhaar Back","customerCif":"0015537"},{"remarks":"","issuedOn":"","issuedCountry":"IN","idType":"POA","idNumber":"","expiryDate":"","documentName":"Job card issued by NREGA","customerCif":"0015537"},{"remarks":"","issuedOn":"","issuedCountry":"IN","idType":"POA","idNumber":"666001902375","expiryDate":"","documentName":"Aadhaar Front","customerCif":"0015537"}],"addressDetails":[{"priority":4,"pinCodeServicability":true,"pinCode":"400079","locality":"","landmark":null,"city":"Telanagana","addressType":"PRIRES"},{"priority":5,"pinCodeServicability":true,"pinCode":"400079","locality":"","landmark":null,"city":"Telanagana","addressType":"ALTRESI"}]},"employmentType":"SALARIED","dsaCode":null,"dateOfIncorporation":"","dateOfBirth":"1966-11-05","customerCif":"0015537","customerCategory":"","customerBranch":"1001","creditBureauReports":"<CreditReport><Header><SegmentTag>TUEF</SegmentTag><Version>12</Version><ReferenceNumber>3720679591</ReferenceNumber><MemberCode>HF64228888_CIRC2CNPE          </MemberCode><SubjectReturnCode>1</SubjectReturnCode><EnquiryControlNumber>010714510619</EnquiryControlNumber><DateProcessed>19032026</DateProcessed><TimeProcessed>232830</TimeProcessed></Header><NameSegment><Length>03</Length><SegmentTag>N01</SegmentTag><ConsumerName1FieldLength>05</ConsumerName1FieldLength><ConsumerName1>SUNIL</ConsumerName1><ConsumerName3FieldLength>06</ConsumerName3FieldLength><ConsumerName3>AJMANI</ConsumerName3><DateOfBirthFieldLength>08</DateOfBirthFieldLength><DateOfBirth>31071955</DateOfBirth><GenderFieldLength>01</GenderFieldLength><Gender>1</Gender></NameSegment><IDSegment><Length>03</Length><SegmentTag>I01</SegmentTag><IDType>01</IDType><IDNumberFieldLength>10</IDNumberFieldLength><IDNumber>AITPA9314J</IDNumber><EnrichedThroughEnquiry>Y</EnrichedThroughEnquiry></IDSegment><IDSegment><Length>03</Length><SegmentTag>I02</SegmentTag><IDType>06</IDType><IDNumberFieldLength>12</IDNumberFieldLength><IDNumber>XXXXXXXXXXXX</IDNumber><EnrichedThroughEnquiry>Y</EnrichedThroughEnquiry></IDSegment><TelephoneSegment><Length>03</Length><SegmentTag>T01</SegmentTag><TelephoneNumberFieldLength>10</TelephoneNumberFieldLength><TelephoneNumber>9217590630</TelephoneNumber><TelephoneType>01</TelephoneType><EnrichedThroughEnquiry>Y</EnrichedThroughEnquiry></TelephoneSegment><ScoreSegment><Length>10</Length><ScoreName>CIBILTUSC3</ScoreName><ScoreCardName>08</ScoreCardName><ScoreCardVersion>10</ScoreCardVersion><ScoreDate>19032026</ScoreDate><Score>000-1</Score><BureauCharacterstics></BureauCharacterstics></ScoreSegment><Address><AddressSegmentTag>PA</AddressSegmentTag><Length>03</Length><SegmentTag>A01</SegmentTag><AddressLine1FieldLength>24</AddressLine1FieldLength><AddressLine1>T60 THIRD FLOOR BLOOK  T</AddressLine1><AddressLine2FieldLength>27</AddressLine2FieldLength><AddressLine2>JANTA MARKET RAJOURI GRADEN</AddressLine2><AddressLine5FieldLength>09</AddressLine5FieldLength><AddressLine5>NEW DELHI</AddressLine5><StateCode>07</StateCode><PinCodeFieldLength>06</PinCodeFieldLength><PinCode>110027</PinCode><AddressCategory>01</AddressCategory><ResidenceCode>01</ResidenceCode><DateReported>18022026</DateReported><EnrichedThroughEnquiry>Y</EnrichedThroughEnquiry></Address><Enquiry><Length>04</Length><SegmentTag>I001</SegmentTag><DateOfEnquiryFields>07032026</DateOfEnquiryFields><EnquiringMemberShortNameFieldLength>13</EnquiringMemberShortNameFieldLength><EnquiringMemberShortName>NOT DISCLOSED</EnquiringMemberShortName><EnquiryPurpose>02</EnquiryPurpose><EnquiryAmountFieldLength>08</EnquiryAmountFieldLength><EnquiryAmount>10100000</EnquiryAmount></Enquiry><Enquiry><Length>04</Length><SegmentTag>I002</SegmentTag><DateOfEnquiryFields>18022026</DateOfEnquiryFields><EnquiringMemberShortNameFieldLength>13</EnquiringMemberShortNameFieldLength><EnquiringMemberShortName>NOT DISCLOSED</EnquiringMemberShortName><EnquiryPurpose>06</EnquiryPurpose><EnquiryAmountFieldLength>05</EnquiryAmountFieldLength><EnquiryAmount>49500</EnquiryAmount></Enquiry><Enquiry><Length>04</Length><SegmentTag>I003</SegmentTag><DateOfEnquiryFields>18022026</DateOfEnquiryFields><EnquiringMemberShortNameFieldLength>13</EnquiringMemberShortNameFieldLength><EnquiringMemberShortName>NOT DISCLOSED</EnquiringMemberShortName><EnquiryPurpose>02</EnquiryPurpose><EnquiryAmountFieldLength>08</EnquiryAmountFieldLength><EnquiryAmount>10000000</EnquiryAmount></Enquiry><End><SegmentTag>ES07</SegmentTag><TotalLength>0000585</TotalLength></End></CreditReport>","companyCategory":"","caste":"General","bankingDetails":[{"typeOfBanks":"","salaryAccount":null,"repaymentFrom":"","phoneNumber":"7722094699","numOfMonthsBanking":1,"monthAndYearDayBalance":"","iwOwRatio":"0","externalLiabilities":[{"trackCheckFrom":0,"totalTenure":0,"status":"","sourceOfInfo":0,"securityDetails":"","roi":"","repaymentFrom":"","repaymentBankAccNo":"","remarks":"","product":"","pos":"","ownerShip":"","overdue":"","outstandingBalance":"","otherFinancialInstitute":"","originalAmount":"0.0","noOfBouncesL6m":0,"noOfBouncesL3m":0,"noOfBouncesL12m":0,"mob":0,"loanDate":"2025-12-30+00:00","liabilitySequence":0,"last6Months":0,"last3Months":0,"last24Months":0,"installmentAmount":{"amount":0},"imputedEmi":"","endUseOfFunds":"","emiConsideredForFoir":true,"consideredRtrBasedLoan":null,"bankName":"","balanceTenure":0}],"documentName":"NONOD","customerCif":"0015537","ccLimit":null,"bankName":"","bankBranch":"1001","addToBeneficiary":null,"accountType":"","accountOpenDate":"2026-03-30+00:00","accountNo":"1234567778747","accountBehaviourDetails":{"salaryOrIncome":0,"returnCount":0,"returnChequeAmount":0,"remarks":"","paymentCheques":0,"monthAndYear":"","debits":0,"customerCif":"0015537","chequeSequence":0},"accHolderName":"Sarthak Kasture"}],"applicantType":"MainApp","applicantAdditionalDetails":{"sepEligibility":{"MAXFOIRSEP":"","isGrowthSustainable":"","INCMG":"","GROWANNRC":"","grossAnnualRecieptsPreviousYear":0.0,"grossAnnualRecieptsLatestYear":0.0,"additionalMultiplier":0.0,"additionalFoir":0},"senpRiskScoreEligibility":{"processBelowRiskCutOff":"","debtEquityRatio":0.0,"ccOdUtilization":"","abbEmiRatio":0.0},"senpPreviousYearEligibility":{"turnover":0.0,"salaryPartner":0.0,"otherIncome":0.0,"oneTimeIncome":0.0,"oneTimeExpense":0.0,"netPbt":0.0,"interestRelative":0.0,"interestPartner":0.0,"interestBank":0.0,"grossProfit":0.0,"depreciation":0.0,"CASHPROFPREV":""},"senpLatestYearEligibility":{"turnover":0.0,"salaryPartner":0.0,"otherIncome":0.0,"oneTimeIncome":0.0,"oneTimeExpense":0.0,"netPbt":0.0,"interestRelative":0.0,"interestPartner":0.0,"interestBank":0.0,"grossProfit":0.0,"depreciation":0.0,"CASHPROFLAST":""},"senpGrowthPercentageEligibility":{"TURNGROPER":"","isTurnoverGrowthSutainable":"","isGrossProfitGrowthSutainable":null,"isCashProfitGrowthSutainable":"","GRPRGRPER":"","CASFPRGPER":""},"salariedEligibility":{"processCaseRiskCutoff":"","previousYearBonus":0.0,"MAXFOIRSAL":"","latestYearBonus":0.0,"incentiveMonth6":0.0,"incentiveMonth5":0.0,"incentiveMonth4":0.0,"incentiveMonth3":0.0,"incentiveMonth2":0.0,"incentiveMonth1":0.0,"buffer9":"","buffer8":"","buffer7":"","buffer6":"","buffer5":"","buffer4":"","buffer3":"","buffer2":"","buffer10":"","buffer1":"100","additionalFoir":0},"poaHolderDetails":{"subDistrict":"","state":"","relationWithApplicant":"","poBox":"","pinCode":"","photoIdType":"","photoIdNo":"","mobileNo":"","locality":"","landmark":"","fullName":"","district":"","country":"","city":"","addressType":"","addressIdType":"","addressIdNo":""},"otherSenpInputEligibility":{"processBelowRiskCutOff":"","overrideAbbEmiRatio":0.0,"MAXGROSSENP":"","MAXFOIRSENP":"","maxAbbEmiRatioAllowed":"","industryMarginCRISIL":0.0,"incomeProgram":"","ELIMAXLA":"","avgMonthlyBalancePerfios":0.0,"annulisedSalaryDirector":0.0,"additionalGrossMargin":0.0,"additionalFoir":0},"occupationCategory":"","nriIncomeDetails":{"workExperienceAbroadMonths":"","rateOfConversion":0.0,"monthlyNetSalaryForeignCurrency":"","dateOfConversion":"","currencyRemove":""},"natureOfEmployment":"","leadSquaredLeadId":"","GROWPER":"","digitalData":{"perfiosObligation":"","perfiosIncome":"","bureauObligation":""},"customerSep":{"typeOfService":"","totalWorkExperience":10,"product":"","industry":""},"customerSenp":{"totalWorkExperience":10,"senp":"","dateOfCommencement":null},"customerSelfEmployedProfesional":{"rentalIncome":0,"profession":0,"otherIncome":0,"grossTurnOver":0,"grossReceiptFromBusiness":0},"customerSalaried":{"totalWorkExperience":10,"ifSalaried":"","idType":"","employerName":"","emailIdOfficial":"","designation":"","currentWorkExperience":0.0},"customerNonIndividual":{"profession":0.0,"otherIncome":0.0,"netProfitFromBusiness":0.0},"customerIndividualSalaried":{"rentalIncome":0.0,"otherIncome":0.0,"grossAnnualSalaryIncome":180000.0},"customerEntityType":{"pinCode":0,"landmark":"","businessOrProffessional":""},"customerAreaName":{"state":"","district":"","city":""},"cibil":{"writeOffNonCredit":"","writeOffCredit":"","writeOff":"","timeProcessed":"23:28:30","settle":"","scoreName":"CIBILTUSC3","scorecardVersion":"10","scorecardName":"08","score":"000-1","restructured":"","recentLoans":0,"plus60DpdL3m":0,"plus30PdpL6m":0,"plus30DpdL12m":0,"panNumber":"AIFPP5729A","noInquiryL3m":0,"noInquiryL1m":0,"noAccountsDeliquentL6m":0,"noAccounts30DpdL12m":0,"memberReferenceNo":"HF64228888_CIRC2CNPE","liveUsedCardLoanEmi":0.0,"liveUsedCardLoan":0.0,"liveSecuredCardOutstanding":0.0,"liveSecuredAndEmi":0.0,"livePlLoanAmount":0.0,"livePersonalLoanEmi":0.0,"liveLoanOnCreditCardEmi":0.0,"liveLoanOnCreditCard":0.0,"liveHlOrLapLoanEmi":0.0,"liveHlOrLapLoanAmount":0.0,"liveEducationLoanEmi":0.0,"liveEducationLoanAmount":0.0,"liveCreditCardOutstanding":0.0,"liveCreditCardEmi":0.0,"liveConsumerLoanEmi":0.0,"liveConsumerLoan":0.0,"liveCommercialVehicleLoanEmi":0.0,"liveCommercialVehicleLoan":0.0,"liveBusinessLoanEmi":0.0,"liveBlLoanAmount":0.0,"liveAutoLoanEmi":0.0,"liveAutoLoanAmount":0.0,"live2WheelerLoanEmi":0.0,"live2WheelerLoanAmount":0.0,"executionResponse":"","emiBouncesL6m":0,"emiBouncesL3m":0,"emiBounceL3m":0,"emiBounceL12m":0,"derog":"","dateProcessed":"19/03/2026","customerName":"Sarthak Kasture","creditCardOverdueAmount":0.0,"creditAmountOverdue":"","anyDpdL12m":0},"buffer9":"","buffer8":"","buffer7":"","buffer6":"","buffer5":"","buffer4":"","buffer3":"","buffer20":"","buffer2":"","buffer19":"","buffer18":"","buffer17":"","buffer16":"","buffer15":"","buffer14":"","buffer13":"","buffer12":"","buffer11":"","buffer10":"","buffer1":"","associatedCompanies":{"associatedCompanyName5":"","associatedCompanyName4":"","associatedCompanyName3":"","associatedCompanyName2":"","associatedCompanyName1":""},"additionalDetail":{"purposeOfLoanOthers":"BR","netBonus":0.0,"netAnnual":180000.0,"buffer5":"0","buffer4":"","buffer3":"","buffer2":"","buffer1":""}},"addressOwnershipType":null}]}},"invocation":{"version":"","serviceexecute":"FICO","responseStatus":"","decisionService":"HL","decisionPointAction":"BUTTON","decisionPoint":"HL_CREDIT","applicationNumber":"LA-000000746","applicationDate":"2025-12-30+00:00';
           	if(true){
                /*
                //System.debug('request JSON '+respWrapper.payload);
                while(respWrapper.payload.contains('currencyRemove')){     respWrapper.payload = respWrapper.payload.replace('currencyRemove','currency');    }

                String xmlRespStr = JSONXMLConvertor.convertJsonToXml(respWrapper.payload, '');
                respWrapper = null;

                while(xmlRespStr.contains('&lt;')){     xmlRespStr = xmlRespStr.replace('&lt;', '<');    }
                while(xmlRespStr.contains('&gt;')){     xmlRespStr = xmlRespStr.replace('&gt;', '>');    }
                while(xmlRespStr.contains('\n')){     xmlRespStr = xmlRespStr.replace('\n', '');    }
                while(xmlRespStr.contains('\t')){     xmlRespStr = xmlRespStr.replace('\t', '');    }
                while(xmlRespStr.contains('\r')){     xmlRespStr = xmlRespStr.replace('\r', '');    }

                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName','Loan FICO API');
                integrationRequestMap.put('requestJSON', xmlRespStr);
                // System.debug('xmlRespStr: '+xmlRespStr);
                
                String bearer = Utility.getAccessToken();
                //System.debug('bearer----'+bearer);
                integrationRequestMap.put('bearer', bearer);
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                // System.debug('resp: '+resp);
                // System.debug('resp.getBody(): '+resp.getBody());

                //releasing the memory
                bearer = '';
				*/
                
                if(true) {
                    returnResp = 'success';
                    
                    ContentVersion cv = [SELECT Id,ContentDocumentId,VersionNumber,Title,VersionData 
                                         FROM ContentVersion WHERE ContentDocumentId = '069dN000006jRyHQAU' AND IsLatest = TRUE LIMIT 1];
                    
                    //String apiResponse = resp.getBody();
                    String apiResponse = cv.VersionData.toString();
                    Integer startIndex = apiResponse.indexOf('<response>');
                    Integer endIndex = apiResponse.indexOf('</response>');
                    endIndex = endIndex + ('</response>'.length());
                    string responseTag = apiResponse.substring(startIndex, endIndex);
                    // system.debug('responseTag: '+responseTag);
                    
                    startIndex = apiResponse.indexOf('<finalOffer>');
                    endIndex = apiResponse.indexOf('</finalOffer>');
                    endIndex = endIndex + ('</finalOffer>'.length());
                    string finalOffer = apiResponse.substring(startIndex, endIndex);
                    System.debug('finalOffer----'+finalOffer);

                    apiResponse = responseTag + finalOffer;

                    Opportunity loanObj = [SELECT Id, Risk_Segment__c, Sanction_Loan_Amount__c, Quick_Sanction_Response__c, Is_Applicable_for_Quick_Sanction__c FROM Opportunity WHERE id =: loanId];

                    //create request file
                    ContentVersion content = new ContentVersion();
                    content.Title = 'IncomeEligibility_Response.txt';
                    content.PathOnClient = 'IncomeEligibility_Response.txt';
                    content.VersionData = Blob.valueOf((apiResponse));
                    content.IsMajorVersion = true;
                    insert content;

                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: content.Id LIMIT 1].ContentDocumentId;
                    
                    // Create Document_Details__c record
                    Document_Details__c checklist = new Document_Details__c();
                    checklist.Content_Document_Id__c = cdl.ContentDocumentId;
                    checklist.Loan_Application__c = loanid;
                    checklist.Name = 'Income Eligibility Response';
                    insert checklist;
                    
                    cdl.LinkedEntityId = checklist.id ; // Temp link to User so ContentDocument exists
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';
                    insert cdl;
                    
                    //create request file
                    ContentVersion contentReq = new ContentVersion();
                    contentReq.Title = 'IncomeEligibility_Request.txt';
                    contentReq.PathOnClient = 'IncomeEligibility_Request.txt';
                    contentReq.VersionData = Blob.valueOf((xmlRespStr));
                    contentReq.IsMajorVersion = true;
                    insert contentReq;

                    xmlRespStr = '';

                    ContentDocumentLink cdlReq = new ContentDocumentLink();
                    cdlReq.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentReq.Id LIMIT 1].ContentDocumentId;
                    
                    // Create Document_Details__c record
                    Document_Details__c checklistRew = new Document_Details__c();
                    checklistRew.Content_Document_Id__c = cdlReq.ContentDocumentId;
                    checklistRew.Loan_Application__c = loanid;
                    checklistRew.Name = 'Income Eligibility Request';
                    insert checklistRew;
                    
                    cdlReq.LinkedEntityId = checklistRew.id ; // Temp link to User so ContentDocument exists
                    cdlReq.ShareType = 'V';
                    cdlReq.Visibility = 'AllUsers';
                    insert cdlReq;
                    
                    integrationDetail.Calling_Source__c = 'Mock'; 
                    integrationDetail.Request_JSON__c = ''; 
                    integrationDetail.Response_JSON__c = apiResponse;
                    integrationDetail.Status__c = String.valueof(200); 
                    integrationDetail.Method_Type__c = 'POST';
                    integrationDetail.EndPoint__c = 'NA' ;
                    integrationDetail.Name = eligibilityType; 
                    integrationDetail.Loan_Application__c = loanid;
                    integrationDetail.Object_Name__c = 'Document_Details__c';
                    integrationDetail.Related_Record_Id__c = checklist.Id;
                    insert integrationDetail;
                    
                    apiResponse = '';

                    String finalResponse = JSON.serialize(XMLConvertor.xmlToMap(responseTag));
                    // System.debug('finalResponse '+finalResponse);
                    
                    Boolean isDeviation = false;
                    Boolean scorecardmore = false;
                    Boolean errormore = false;
                    Boolean scoreCardCharacteristicsMore = false;
                    
                    if(countTagOccurrences(responseTag, 'responseDeviations') >1) {
                        isDeviation = true;
                    }
                    else {
                        finalResponse = finalResponse.replaceALL('responseDeviations', 'responseDeviation');
                        List<Application_Deviation__c> deviationDeleted = [SELECT Id FROM Application_Deviation__c 
                                                                            WHERE Loan_Application__c =: loanId AND Deviation_Category__c = 'Automatic' 
                                                                            AND Approval_Status__c = 'Pending' And HL_Product__c =: productId];
                        if(!deviationDeleted.isEmpty()) {
                            delete deviationDeleted;
                        }
                    }
                     scorecardmore = true;
                    errormore = true;
                    scoreCardCharacteristicsMore = true;
					/*
                    if(countTagOccurrences(responseTag, 'scoreCardDetails') >1){
                        scorecardmore = true;
                    }
                    else{
                        finalResponse = finalResponse.replaceALL('scoreCardDetails', 'scoreCardDetailsSingle');
                    }

                    if(countTagOccurrences(responseTag, 'errorResponse') >1){
                        errormore = true;
                    }
                    else{
                        finalResponse = finalResponse.replaceALL('errorResponse', 'errorResponseSingle');
                    }

                    if(countTagOccurrences(responseTag, 'scoreCardCharacteristics') >1){
                        scoreCardCharacteristicsMore = true;
                    }
                    else{
                        //finalResponse = finalResponse.replaceALL('scoreCardCharacteristics', 'scoreCardCharacteristicsSingle');
                    }*/
                  	System.debug(countTagOccurrences(responseTag, 'calculatedVariables'));
                    FICOResponse ficoResponse = (FICOResponse) JSON.deserialize(finalResponse, FICOResponse.class);

                    Map<string, Application_Applicant__c> customerIdToApplicantMap = new Map<string, Application_Applicant__c>();
                    for(Application_Applicant__c rec : [SELECT Id, Score_Card_Name__c, Score_Card_Score__c, Score_Card_Key__c, Risk_Score__c, Risk_Card_Name__c,
                                                        KYC_Risk_Categorisation_Category__c, Customer__r.SF_Customer_ID__c 
                                                        FROM Application_Applicant__c WHERE Loan_Application__c =: loanId And Applicant_Type__c In ('Primary Applicant', 'Co Applicant') 
                                                        And Customer__r.SF_Customer_ID__c != null]){

                        String customerId = rec.Customer__r.SF_Customer_ID__c;
                        String numericCustomerId = customerId.replaceAll('\\D', '');
                        String finalCustomerId = String.valueOf(Integer.valueOf(numericCustomerId));

                        customerIdToApplicantMap.put(finalCustomerId, rec);
                    }

                    if(callForDeviation && isDeviation) {
                        List<Application_Deviation__c> deleteDev = new List<Application_Deviation__c>();
                        Map<String, Application_Deviation__c> devaitionMap = new Map<String, Application_Deviation__c>();
                        
                        for(Application_Deviation__c iterDev : [SELECT Id, Approval_Status__c, Deviation_Code__c FROM Application_Deviation__c 
                                                                WHERE Loan_Application__c =: loanId AND Deviation_Category__c = 'Automatic' 
                                                                And HL_Product__c =: productId]) {

                            if(iterDev.Approval_Status__c != 'Pending') {
                                devaitionMap.put(iterDev.Deviation_Code__c.toLowerCase(), iterDev);
                            }else {
                                deleteDev.add(iterDev);
                            }
                        }

                        List<Application_Deviation__c> lstDeviations = new List<Application_Deviation__c>();
                        for(FICOResponse.cls_responseDeviations deviationIter : ficoResponse.response.responseDeviations) {
                            
                            if(String.isNotBlank(deviationIter.ruleId) && !devaitionMap.containsKey(deviationIter.ruleId.toLowerCase())) {
                                Application_Deviation__c iterDeviation = new Application_Deviation__c();
                                iterDeviation.Loan_Application__c = loanId;
                                iterDeviation.Deviation_Category__c = 'Automatic';
                                iterDeviation.Deviation_Applicable_For__c = 'Loan Application';
                                iterDeviation.Deviation__c = deviationIter.ruleDescription;
                                iterDeviation.Deviation_Code__c = deviationIter.ruleId;
                                iterDeviation.HL_Product__c = productId;
                                
                                if(customerIdToApplicantMap.containsKey(deviationIter.entityId)){
                                    iterDeviation.Applicant__c = customerIdToApplicantMap.get(deviationIter.entityId).Id;
                                    iterDeviation.Deviation_Applicable_For__c = 'Applicant';
                                }
                                
                                if(String.isNotBlank(deviationIter.approvalLevel)) {
                                    String level = deviationIter.approvalLevel.split(',')[0];
                                    String s2 = level.remove('L');
                                    iterDeviation.Approving_Authority__c = s2;
                                }

                                lstDeviations.add(iterDeviation);
                            }
                        }

                        devaitionMap.clear();

                        if(!deleteDev.isEmpty()) {
                            delete deleteDev;       deleteDev.clear();
                        }

                        if(!lstDeviations.isEmpty()) {
                            insert lstDeviations;       lstDeviations.clear();
                        }
                    }
                    //Added by Suhrit

                    List<Application_Applicant__c> ap = new List<Application_Applicant__c>();
                    Map<Id, Application_Applicant__c> applicantMap = new Map<Id, Application_Applicant__c>();

                    //Product wise offer details.
                    List<Product2> prodDetails = [Select id,HL_Maximum_Loan_Eligibility_basis_LTV__c,HL_Rate_of_Interest__c,HL_Tenor_in_months__c, HL_Maximum_LoanEligibility_LTV_st__c,
                                                    HL_Final_EMI__c,HL_Final_FOIR__c,HL_Final_LTV__c,HL_Maximum_Loan_Eligibility_basis_Income__c,Final_Loan_Amount__c,HL_Total_Eligible_Income__c,
                                                    HL_Final_FOIRSanctioned_Terms__c,HL_Final_LTVSanctioned_Terms__c,HL_Total_Eligible_IncomeST__c,HL_Maximum_LTV__c,Product_Type__c,
                                                    HL_Maximum_Loan_EligibilityIncomeSt__c,Sanctioned_Loan_Amount__c,Sanctioned_Tenor__c,Sanctioned_ROI__c,EMI_Amount__c,HL_FINAL_EMI_INCOME_CALCULATOR__c,
                                                    HL_Rate_of_Interest_Income_Calculator__c,HL_Final_Foir_Income_Calculator__c,HL_Final_LTV_Income_Calculator__c,HL_Final_LTVSanctioned_Terms_Income_Calc__c,
                                                    Final_Loan_Amount_Income_Calculator__c,HL_Tenor_in_months_Calculator__c,HL_Total_Eligible_Income_Calculator__c,HL_Maximum_Loan_Eligibility_LTV_Calc__c,
                                                    HL_Maximum_LTV_Income_Calculator__c,EMI_Amount_Income_Calculator__c,Sanctioned_ROI_Income_Calculator__c,HL_Final_FOIRSanctioned_Terms_Income_Cal__c,
                                                    HL_Maximum_Loan_EligibilityIncomeStCalc__c,Sanctioned_Loan_Amount_Income_Calculator__c,Sanctioned_Tenor_Income_Calculator__c,HL_Maximum_Loan_Eligibility_Income_Calc__c,
                                                    HL_Total_Eligible_IncomeST_Income_Calc__c,HL_Maximum_LoanEligibility_LTV_Income_C__c,Is_Final_Eligibility__c,Product__r.Name, Additional_Foir__c
                                                    From Product2 where Product__c =: productId and RecordType.Name = 'Sub Product' and Loan_Application__c =: loanId LIMIT 1];
                    
                    if(!isIncomeFromSales && scorecardmore){
                        for(FICOResponse.cls_scoreCardDetails scoreCardIter : ficoResponse.response.scoreCardDetails) {
                            if(scoreCardIter.scorecardName.contains('Experian_Score_Card')) {
                                String entityId = scoreCardIter.entityId;

                                if(customerIdToApplicantMap.containsKey(entityId)) {
                                    Application_Applicant__c applicant = customerIdToApplicantMap.get(entityId);  applicant.Score_Card_Name__c = scoreCardIter.scorecardName; applicant.Score_Card_Score__c = scoreCardIter.scorecardScore;
                                    applicant.Score_Card_Key__c = scoreCardIter.scorecardKey; applicantMap.put(applicant.Id, applicant);
                                }
                            }
                            else if(scoreCardIter.scorecardName.contains('Risk_Score_Card')) {
                                String entityId = scoreCardIter.entityId;

                                if(customerIdToApplicantMap.containsKey(entityId)) {
                                    Application_Applicant__c applicant = customerIdToApplicantMap.get(entityId); applicant.Risk_Card_Name__c = scoreCardIter.scorecardName;  applicant.Risk_Score__c = scoreCardIter.scorecardScore;
                                    applicantMap.put(applicant.Id, applicant);
                                }

                                loanObj.Risk_Segment__c = scoreCardIter.scorecardName; loanObj.Risk_Score__c = scoreCardIter.scorecardScore;
                            }
                        }
                    }
                    else{
                        if(!isIncomeFromSales && ficoResponse.response.scoreCardDetailsSingle != null){
                            FICOResponse.cls_scoreCardDetails scoreCardIter = ficoResponse.response.scoreCardDetailsSingle;
                            if(scoreCardIter.scorecardName.contains('Experian_Score_Card')) {
                                String entityId = scoreCardIter.entityId;

                                if(customerIdToApplicantMap.containsKey(entityId)) {
                                    Application_Applicant__c applicant = customerIdToApplicantMap.get(entityId);  applicant.Score_Card_Name__c = scoreCardIter.scorecardName;  applicant.Score_Card_Score__c = scoreCardIter.scorecardScore;
                                    applicant.Score_Card_Key__c = scoreCardIter.scorecardKey; applicantMap.put(applicant.Id, applicant);
                                }
                            }
                            else if(scoreCardIter.scorecardName.contains('Risk_Score_Card')) {
                                String entityId = scoreCardIter.entityId;

                                if(customerIdToApplicantMap.containsKey(entityId)) {
                                    Application_Applicant__c applicant = customerIdToApplicantMap.get(entityId); applicant.Risk_Card_Name__c = scoreCardIter.scorecardName;
                                    applicant.Risk_Score__c = scoreCardIter.scorecardScore;  applicantMap.put(applicant.Id, applicant);
                                }

                                loanObj.Risk_Segment__c = scoreCardIter.scorecardName;
                                loanObj.Risk_Score__c = scoreCardIter.scorecardScore;
                            }
                        }
                    }

                    for(FICOResponse.cls_calculatedVariables calcatedVars : ficoResponse.response.calculatedVariables){
                        if(calcatedVars.fieldName == 'RISKCATEGORIZATION' && calcatedVars.entityId != null){
                            String entityId = calcatedVars.entityId;

                            if(customerIdToApplicantMap.containsKey(entityId)) {
                                Application_Applicant__c applicant = customerIdToApplicantMap.get(entityId);
                                applicant.KYC_Risk_Categorisation_Category__c = calcatedVars.fieldValue;
                                
                                applicantMap.put(applicant.Id, applicant);
                            }
                        }
                        else if(calcatedVars.fieldName == 'MAXABBEMIRATIOALWD' && !prodDetails.isEmpty()){
                            prodDetails[0].Max_ABB_EMI_Ratio_Allowed__c = calcatedVars.fieldValue;
                        }
                        else if(calcatedVars.fieldName == 'QuickSanction'){
                            if(calcatedVars.fieldValue != null && calcatedVars.fieldValue.containsIgnoreCase('true')){
                                loanObj.Quick_Sanction_Response__c = 'You are eligibile for quick sanction';
                                loanObj.Is_Applicable_for_Quick_Sanction__c = true;
                                returnResp = 'success-You are eligibile for quick sanction';
                            }
                            else{
                                loanObj.Quick_Sanction_Response__c = 'You are not eligibile for quick sanction';
                                loanObj.Is_Applicable_for_Quick_Sanction__c = false;
                                returnResp = 'success-You are not eligibile for quick sanction';
                            }
                        }
                        //Quick Sanction
                    }
                    
                    if(!isIncomeFromSales && !prodDetails.isEmpty()) {
                        Map<String, Object> xmlConvertedRespoffer = XMLConvertor.xmlToMap(finalOffer);
                        FICOResponse ficoResponseOffer = (FICOResponse) JSON.deserialize(JSON.serialize(xmlConvertedRespoffer), FICOResponse.class);
                        xmlConvertedRespoffer.clear();

                        decimal EMIFINOFF = ficoResponseOffer.finalOffer.EMIFINOFF != null ? ficoResponseOffer.finalOffer.EMIFINOFF.setScale(2) : 0;
                        decimal MAXLOELIGLTV = prodDetails[0].Product__r.Name != 'Flexi Loan' && ficoResponseOffer.finalOffer.MAXLOELIGLTV != null ? ficoResponseOffer.finalOffer.MAXLOELIGLTV.setScale(2) : 0;
                        decimal ROINTR = ficoResponseOffer.finalOffer.ROINTR != null ? ficoResponseOffer.finalOffer.ROINTR.setScale(2) : 0;
                        decimal FINALFOIR = ficoResponseOffer.finalOffer.FINALFOIR != null ? ficoResponseOffer.finalOffer.FINALFOIR.setScale(2) : 0;
                        decimal MAXLOELIGINC = ficoResponseOffer.finalOffer.MAXLOELIGINC != null ? ficoResponseOffer.finalOffer.MAXLOELIGINC.setScale(2) : 0;
                        decimal MAXLOEELIGINC = ficoResponseOffer.finalOffer.MAXLOEELIGINC != null ? ficoResponseOffer.finalOffer.MAXLOEELIGINC.setScale(2) : 0;
                        decimal FINALLTV = prodDetails[0].Product__r.Name != 'Flexi Loan' && ficoResponseOffer.finalOffer.FINALLTV != null ? ficoResponseOffer.finalOffer.FINALLTV.setScale(2) : 0;
                        decimal MAXLTV = ficoResponseOffer.finalOffer.MAXLTV != null ? ficoResponseOffer.finalOffer.MAXLTV.setScale(2) : 0;
                        decimal LOANAMTOFFR = ficoResponseOffer.finalOffer.LOANAMTOFFR != null ? ficoResponseOffer.finalOffer.LOANAMTOFFR.setScale(2) : 0;
                        Decimal LOANTENU = ficoResponseOffer.finalOffer.LOANTENU != null ? ficoResponseOffer.finalOffer.LOANTENU.setScale(0) : 0;
                        LOANAMTOFFR = 50000000;
						loanObj.Sanction_Loan_Amount__c = LOANAMTOFFR;
                    loanObj.Sanction_Rate_Of_Interest__c = ROINTR;
                    loanObj.Sanction_Tenure__c = LOANTENU;
                        if(!showCalculator){
                            System.debug('420');
                            prodDetails[0].HL_Final_EMI__c = String.valueof(EMIFINOFF);
                            prodDetails[0].HL_Rate_of_Interest__c = ROINTR;
                            prodDetails[0].HL_Final_FOIR__c = FINALFOIR;
                            prodDetails[0].HL_Final_LTV__c = FINALLTV;
                            prodDetails[0].HL_Maximum_Loan_Eligibility_basis_Income__c = String.valueof(MAXLOELIGINC);
                            prodDetails[0].Final_Loan_Amount__c = LOANAMTOFFR;
                            prodDetails[0].HL_Tenor_in_months__c = LOANTENU;
                            prodDetails[0].HL_Total_Eligible_Income__c = MAXLOEELIGINC;
                            prodDetails[0].HL_Maximum_Loan_Eligibility_basis_LTV__c = MAXLOELIGLTV;
                            prodDetails[0].HL_Maximum_LTV__c = MAXLTV;
                            //Sanctioned Terms
                            prodDetails[0].EMI_Amount__c = EMIFINOFF;
                            prodDetails[0].Sanctioned_ROI__c = ROINTR;
                            prodDetails[0].HL_Final_FOIRSanctioned_Terms__c = FINALFOIR;
                            prodDetails[0].HL_Final_LTVSanctioned_Terms__c = FINALLTV;
                            prodDetails[0].HL_Maximum_Loan_EligibilityIncomeSt__c = String.valueof(MAXLOELIGINC);
                            prodDetails[0].Sanctioned_Loan_Amount__c = LOANAMTOFFR;
                            prodDetails[0].Sanctioned_Tenor__c = LOANTENU;
                            prodDetails[0].HL_Total_Eligible_IncomeST__c = MAXLOEELIGINC;
                            prodDetails[0].HL_Maximum_LoanEligibility_LTV_st__c = MAXLOELIGLTV;
                            prodDetails[0].Is_Final_Eligibility__c = eligibilityType == 'Final Eligibility';

                            string userCalValues = inputMap.get('userCalValues');
                            if(String.isNotBlank(userCalValues)){
                                Map<string, string> userValuesMap = (Map<String,String>)JSON.deserialize(userCalValues, Map<String, String>.class);
                                prodDetails[0].Additional_Foir__c = userValuesMap.containsKey('additionalFOIR') ? Decimal.valueOf((String)userValuesMap.get('additionalFOIR')) : 0;
                            }

                            update prodDetails;

                            if(prodDetails[0].Product_Type__c == 'Parent'){ loanObj.Sanction_Loan_Amount__c = LOANAMTOFFR;
                            }
                        }
                        else{
                            System.debug('450');
                            prodDetails[0].HL_FINAL_EMI_INCOME_CALCULATOR__c = String.valueof(EMIFINOFF);
                            prodDetails[0].HL_Rate_of_Interest_Income_Calculator__c = ROINTR;
                            prodDetails[0].HL_Final_Foir_Income_Calculator__c = FINALFOIR;
                            prodDetails[0].HL_Final_LTV_Income_Calculator__c = FINALLTV;
                            prodDetails[0].HL_Maximum_Loan_Eligibility_Income_Calc__c = String.valueof(MAXLOELIGINC);
                            prodDetails[0].Final_Loan_Amount_Income_Calculator__c = LOANAMTOFFR;
                            prodDetails[0].HL_Tenor_in_months_Calculator__c = LOANTENU;
                            prodDetails[0].HL_Total_Eligible_Income_Calculator__c = MAXLOEELIGINC;
                            prodDetails[0].HL_Maximum_Loan_Eligibility_LTV_Calc__c = MAXLOELIGLTV;
                            prodDetails[0].HL_Maximum_LTV_Income_Calculator__c = MAXLTV;
                            //Sanctioned Terms
                            prodDetails[0].EMI_Amount_Income_Calculator__c = EMIFINOFF;
                            prodDetails[0].Sanctioned_ROI_Income_Calculator__c = ROINTR;
                            prodDetails[0].HL_Final_FOIRSanctioned_Terms_Income_Cal__c = FINALFOIR;
                            prodDetails[0].HL_Final_LTVSanctioned_Terms_Income_Calc__c = FINALLTV;
                            prodDetails[0].HL_Maximum_Loan_EligibilityIncomeStCalc__c = String.valueof(MAXLOELIGINC);
                            prodDetails[0].Sanctioned_Loan_Amount_Income_Calculator__c = LOANAMTOFFR;
                            prodDetails[0].Sanctioned_Tenor_Income_Calculator__c = LOANTENU;
                            prodDetails[0].HL_Total_Eligible_IncomeST_Income_Calc__c = MAXLOEELIGINC;
                            prodDetails[0].HL_Maximum_LoanEligibility_LTV_Income_C__c = MAXLOELIGLTV;
                            update prodDetails;
                        }
                    }
                    //Product wise offer details.
					
                    // update parent;
                    update loanObj;

                    update applicantMap.values();
                }
                else {
                    returnResp = 'Error : 400';
                }
            }
            return returnResp; 
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static Integer countTagOccurrences(String xmlContent, String tagName) {
        Integer count = 0;
        String searchTag = '<' + tagName;
        if(tagName == 'Account'){
            searchTag = searchTag + '>';
        }
        Integer index = xmlContent.indexOf(searchTag);

        while(index != -1) {
            count++;
            index = xmlContent.indexOf(searchTag, index + searchTag.length());
        }

        return count;
    }

    @AuraEnabled
    public static string updatePLROnProduct(string loanId, string plr, string margin, string productId){
        List<Product2> subprod = [Select Id, PLR_Code__c, PLR_Value__c, Margin__c From Product2
                                   Where Loan_Application__c =: loanId 
                                    And Product__c =: productId And RecordType.Name = 'Sub Product' Limit 1];

        List<Product2> variantprod = [Select Id, PLR_Code__c, PLR_Value__c, Margin__c From Product2 Where Loan_Application__c =: loanId 
                                        And Product__c =: subprod[0].Id And RecordType.Name = 'Variant' Limit 1];

        List<string> plrVal = plr.split(' - ');
        List<Product2> finalList = new List<Product2>();
        subprod[0].PLR_Code__c = plrVal[0];
        subprod[0].PLR_Value__c = Decimal.valueOf(plrVal[1]);
        subprod[0].Margin__c = Decimal.valueOf(margin);
        finalList.addAll(subprod);

        if(!variantprod.isEmpty()){
            variantprod[0].PLR_Code__c = plrVal[0];
            variantprod[0].PLR_Value__c = Decimal.valueOf(plrVal[1]);
            variantprod[0].Margin__c = Decimal.valueOf(margin);
            finalList.addAll(variantprod);
        }

        update finalList;

        System.debug('plrVal[0]>>>>>'+plrVal[0]);
        PLF_Master__c selectedPlfMaster = [SELECT Id, Co_lending__c, Co_Lending_partner_Bank__c FROM PLF_Master__c WHERE Master_Type__c = 'PLR Master' 
                                            AND Description__c =: plrVal[0] LIMIT 1];
                                            
        Opportunity loan = new Opportunity();
        loan.Id = loanId;
        loan.Co_lending__c = selectedPlfMaster.Co_lending__c ? 'Yes' : 'No';
        loan.Co_Lending_partner_Bank__c = selectedPlfMaster.Co_Lending_partner_Bank__c;
        update loan;
        
        return 'Success';
    }

    @AuraEnabled
    public static List<Application_Applicant__c> getScoreCardDetails(string loanId){
        return [SELECT Id, Name, Score_Card_Name__c, Score_Card_Score__c, Score_Card_Key__c, KYC_Risk_Categorisation_Category__c, Risk_Card_Name__c, Risk_Score__c
                FROM Application_Applicant__c WHERE Loan_Application__c =: loanId And Applicant_Type__c In ('Primary Applicant', 'Co Applicant') Order By Id];
    }

    @AuraEnabled
    public static List<PLF_Master__c> fetchPLRValues(){
        return [Select Id, Description__c, FICO_Code__c From PLF_Master__c Where Master_Type__c = 'PLR Master' Order By Description__c];
    }

    @AuraEnabled
    public static List<string> getLoanStatus(string loanId){
        List<string> result = new List<string>();
        List<Opportunity> opp = [Select StageName, Sub_stage__c From Opportunity Where Id =: loanId];
        result.add(opp[0].StageName);
        result.add(opp[0].Sub_stage__c);

        return result;
    }
}