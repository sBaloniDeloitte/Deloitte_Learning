public with sharing class GetExistingLoanDetailsController {
    @AuraEnabled
    public static String getExistingLoanDetails(String loanId) {
        try {
            Integration_Details__c integrationDetail = new Integration_Details__c();
             List<Integration_Settings__c> intSettingList = [
                SELECT Client_Id__c, Message_Id__c, Entity_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                FROM Integration_Settings__c
                WHERE Name = 'Get Loan Details'
                LIMIT 1
            ];
            system.debug('loanId--12--'+loanId);
            Integration_Settings__c intSetting = intSettingList[0];
            Map<String,String> integrationRequestMap = new Map<String,String>();
            String endpoint  = intSetting.Endpoint__c+'/'+loanId;
            integrationRequestMap.put('intSettingName','Get Loan Details');
            integrationRequestMap.put('endPoint',endpoint);
            integrationRequestMap.put('serviceName','getFinance');
            integrationRequestMap.put('MESSAGEID', intSetting.Message_Id__c);
            integrationRequestMap.put('ENTITYID', intSetting.Entity_Id__c);
            integrationRequestMap.put('ServiceVersion','1');
            integrationRequestMap.put('RequestTime', String.valueof(DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss')));
            integrationRequestMap.put('Language','ENG');
            String bearer = Utility.getAccessToken();
            System.debug('bearer----'+bearer);
            integrationRequestMap.put('bearer',bearer);
            //  String jsonResponse =		'{'+
            //  '    "finReference": "GFL3001BD0014530",'+
            //  '    "stp": true,'+
            //  '    "financeSchedule": {'+
            //  '        "financeDetail": {'+
            //  '            "applicationNo": "",'+
            //  '            "finType": "BD",'+
            //  '            "finCcy": "INR",'+
            //  '            "finBranch": "3001",'+
            //  '            "finReference": "GFL3001BD0014530",'+
            //  '            "profitDaysBasis": "A/A_365L",'+
            //  '            "finAmount": 30000000,'+
            //  '            "finAssetValue": 1000000000,'+
            //  '            "downPayBank": 0,'+
            //  '            "downPaySupl": 0,'+
            //  '            "finRepayMethod": "NACH",'+
            //  '            "finStartDate": "2044-03-15T00:00:00",'+
            //  '            "allowGrcPeriod": false,'+
            //  '            "tdsApplicable": false,'+
            //  '            "manualSchedule": false,'+
            //  '            "planDeferCount": 0,'+
            //  '            "stepFinance": false,'+
            //  '            "alwManualSteps": false,'+
            //  '            "stepPolicy": "",'+
            //  '            "stepType": "#",'+
            //  '            "grcTerms": 0,'+
            //  '            "grcPeriodEndDate": "2044-03-15T00:00:00",'+
            //  '            "grcRateBasis": "#",'+
            //  '            "grcPftRate": 0.000000000,'+
            //  '            "grcMargin": 0.000000000,'+
            //  '            "grcPftFrq": "",'+
            //  '            "grcPftRvwFrq": "",'+
            //  '            "grcCpzFrq": "",'+
            //  '            "allowGrcRepay": false,'+
            //  '            "grcSchdMthd": "PFT",'+
            //  '            "grcMinRate": 0.000000000,'+
            //  '            "grcMaxRate": 0.000000000,'+
            //  '            "grcMaxAmount": 0,'+
            //  '            "grcAdvPftRate": 0.000000000,'+
            //  '            "grcAdvMargin": 0.000000000,'+
            //  '            "numberOfTerms": 24,'+
            //  '            "reqRepayAmount": 0,'+
            //  '            "repayRateBasis": "R",'+
            //  '            "repayPftRate": 16.960000000,'+
            //  '            "repayBaseRate": "GFLPLRBL",'+
            //  '            "repayMargin": 0.000000000,'+
            //  '            "scheduleMethod": "PFT",'+
            //  '            "repayFrq": "M0026",'+
            //  '            "nextRepayDate": "2044-04-26T00:00:00",'+
            //  '            "repayPftFrq": "M0026",'+
            //  '            "nextRepayPftDate": "2044-04-26T00:00:00",'+
            //  '            "repayRvwFrq": "M0026",'+
            //  '            "nextRepayRvwDate": "2044-04-26T00:00:00",'+
            //  '            "repayCpzFrq": "",'+
            //  '            "nextRepayCpzDate": "2046-03-26T00:00:00",'+
            //  '            "maturityDate": "2046-03-26T00:00:00",'+
            //  '            "finRepayPftOnFrq": false,'+
            //  '            "repayAdvPftRate": 0.000000000,'+
            //  '            "repayAdvMargin": 0.000000000,'+
            //  '            "supplementRent": 0,'+
            //  '            "increasedCost": 0,'+
            //  '            "rolloverFrq": "",'+
            //  '            "finContractDate": "2044-03-15T00:00:00",'+
            //  '            "finPurpose": "BEXP",'+
            //  '            "finLimitRef": "",'+
            //  '            "finCommitmentRef": "",'+
            //  '            "repayAccountId": "",'+
            //  '            "depreciationFrq": "",'+
            //  '            "accountsOfficer": 0,'+
            //  '            "salesDepartment": "",'+
            //  '            "referralId": "",'+
            //  '            "employeeName": "",'+
            //  '            "quickDisb": false,'+
            //  '            "unPlanEMIHLockPeriod": 0,'+
            //  '            "unPlanEMICpz": false,'+
            //  '            "reAgeCpz": false,'+
            //  '            "maxUnplannedEmi": 0,'+
            //  '            "maxReAgeHolidays": 0,'+
            //  '            "alwBpiTreatment": true,'+
            //  '            "dftBpiTreatment": "S",'+
            //  '            "bpiPftDaysBasis": "A/A_365L",'+
            //  '            "planEMIHAlw": false,'+
            //  '            "planEMIHAlwInGrace": false,'+
            //  '            "planEMIHMethod": " ",'+
            //  '            "planEMIHMaxPerYear": 0,'+
            //  '            "planEMIHMax": 0,'+
            //  '            "planEMIHLockPeriod": 0,'+
            //  '            "planEMICpz": false,'+
            //  '            "alwUnplanPRIHoliday": false,'+
            //  '            "unplanPRIHLockPeriod": 0,'+
            //  '            "maxUnPlannedPRI": 0,'+
            //  '            "planPRIHAlw": false,'+
            //  '            "planPRIHMethod": " ",'+
            //  '            "planPRIHMaxPerYear": 0,'+
            //  '            "planPRIHMax": 0,'+
            //  '            "planPRIHLockPeriod": 0,'+
            //  '            "availedUnPlanPri": 0,'+
            //  '            "firstDisbDate": "2044-03-15T00:00:00",'+
            //  '            "lastDisbDate": "2044-03-15T00:00:00",'+
            //  '            "stage": "",'+
            //  '            "status": "Approved",'+
            //  '            "advEMITerms": 0,'+
            //  '            "fixedRateTenor": 0,'+
            //  '            "fixedTenorRate": 0.000000000,'+
            //  '            "eligibilityMethod": 0,'+
            //  '            "connector": 0,'+
            //  '            "legalRequired": false,'+
            //  '            "reqLoanAmt": 1000000000,'+
            //  '            "reqLoanTenor": 60,'+
            //  '            "offerProduct": "",'+
            //  '            "offerAmount": 0,'+
            //  '            "custSegmentation": "",'+
            //  '            "baseProduct": "",'+
            //  '            "processType": "",'+
            //  '            "bureauTimeSeries": "",'+
            //  '            "campaignName": "",'+
            //  '            "existingLanRefNo": "",'+
            //  '            "leadSource": "",'+
            //  '            "poSource": "",'+
            //  '            "rsa": false,'+
            //  '            "sourChannelCategory": "#",'+
            //  '            "offerId": "",'+
            //  '            "noOfSteps": 0,'+
            //  '            "noOfGrcSteps": 0,'+
            //  '            "rpyDueFrq": "M0006",'+
            //  '            "nextRpyDueFrqDate": "2044-05-06T00:00:00",'+
            //  '            "grcPftDueFrq": "",'+
            //  '            "version": 1,'+
            //  '            "sourcingBranch": "3001",'+
            //  '            "calMaturity": "2046-03-26T00:00:00",'+
            //  '            "recalType": "",'+
            //  '            "productCategory": "CONV",'+
            //  '            "elasticCrLine": true,'+
            //  '            "elasticCrLineType": "P",'+
            //  '            "elasticCrLineDropCalOn": "S",'+
            //  '            "appliedLoanAmt": 0,'+
            //  '            "alwGrcAdj": false,'+
            //  '            "npa": false,'+
            //  '            "limitBlock": true'+
            //  '        },'+
            //  '        "repayInstruction": ['+
            //  '            {'+
            //  '                "repayDate": "2044-04-26T00:00:00",'+
            //  '                "repayAmount": 0,'+
            //  '                "repaySchdMethod": "PFT",'+
            //  '                "version": 0'+
            //  '            }'+
            //  '        ],'+
            //  '        "rateInstruction": [],'+
            //  '        "fees": ['+
            //  '            {'+
            //  '                "feeCategory": "FC",'+
            //  '                "feeCode": "PROCFEE",'+
            //  '                "feeAmount": 999900,'+
            //  '                "waiverAmount": 0,'+
            //  '                "paidAmount": 999900,'+
            //  '                "feeMethod": "DISB",'+
            //  '                "scheduleTerms": 0,'+
            //  '                "feeBalance": 0,'+
            //  '                "version": 1,'+
            //  '                "finFeeReceipts": []'+
            //  '            },'+
            //  '            {'+
            //  '                "feeCategory": "FC",'+
            //  '                "feeCode": "STFRCHG",'+
            //  '                "feeAmount": 200000,'+
            //  '                "waiverAmount": 0,'+
            //  '                "paidAmount": 200000,'+
            //  '                "feeMethod": "DISB",'+
            //  '                "scheduleTerms": 0,'+
            //  '                "feeBalance": 0,'+
            //  '                "version": 1,'+
            //  '                "finFeeReceipts": []'+
            //  '            }'+
            //  '        ],'+
            //  '        "feeDues": [],'+
            //  '        "step": [],'+
            //  '        "schedules": ['+
            //  '            {'+
            //  '                "schDate": "2044-03-15T00:00:00",'+
            //  '                "pftAmount": 0,'+
            //  '                "schdPft": 0,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 0,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2044-04-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2044-03-26T00:00:00",'+
            //  '                "pftAmount": 153000,'+
            //  '                "schdPft": 153000,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 153000,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2044-04-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2044-04-26T00:00:00",'+
            //  '                "pftAmount": 430900,'+
            //  '                "schdPft": 430900,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 430900,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2044-05-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2044-05-26T00:00:00",'+
            //  '                "pftAmount": 417100,'+
            //  '                "schdPft": 417100,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 417100,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2044-06-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2044-06-26T00:00:00",'+
            //  '                "pftAmount": 430900,'+
            //  '                "schdPft": 430900,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 430900,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2044-07-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2044-07-26T00:00:00",'+
            //  '                "pftAmount": 417100,'+
            //  '                "schdPft": 417100,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 417100,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2044-08-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2044-08-26T00:00:00",'+
            //  '                "pftAmount": 430900,'+
            //  '                "schdPft": 430900,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 430900,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2044-09-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2044-09-26T00:00:00",'+
            //  '                "pftAmount": 431000,'+
            //  '                "schdPft": 431000,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 431000,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2044-10-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2044-10-26T00:00:00",'+
            //  '                "pftAmount": 417000,'+
            //  '                "schdPft": 417000,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 417000,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2044-11-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2044-11-26T00:00:00",'+
            //  '                "pftAmount": 431000,'+
            //  '                "schdPft": 431000,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 431000,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2044-12-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2044-12-26T00:00:00",'+
            //  '                "pftAmount": 417000,'+
            //  '                "schdPft": 417000,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 417000,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2045-01-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2045-01-26T00:00:00",'+
            //  '                "pftAmount": 432200,'+
            //  '                "schdPft": 432200,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 432200,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2045-02-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2045-02-26T00:00:00",'+
            //  '                "pftAmount": 432100,'+
            //  '                "schdPft": 432100,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 432100,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2045-03-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2045-03-26T00:00:00",'+
            //  '                "pftAmount": 390300,'+
            //  '                "schdPft": 390300,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 390300,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2045-04-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2045-04-26T00:00:00",'+
            //  '                "pftAmount": 432100,'+
            //  '                "schdPft": 432100,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 432100,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2045-05-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2045-05-26T00:00:00",'+
            //  '                "pftAmount": 418200,'+
            //  '                "schdPft": 418200,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 418200,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2045-06-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2045-06-26T00:00:00",'+
            //  '                "pftAmount": 432100,'+
            //  '                "schdPft": 432100,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 432100,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2045-07-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2045-07-26T00:00:00",'+
            //  '                "pftAmount": 418200,'+
            //  '                "schdPft": 418200,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 418200,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2045-08-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2045-08-26T00:00:00",'+
            //  '                "pftAmount": 432200,'+
            //  '                "schdPft": 432200,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 432200,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2045-09-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2045-09-26T00:00:00",'+
            //  '                "pftAmount": 432100,'+
            //  '                "schdPft": 432100,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 432100,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2045-10-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2045-10-26T00:00:00",'+
            //  '                "pftAmount": 418200,'+
            //  '                "schdPft": 418200,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 418200,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2045-11-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2045-11-26T00:00:00",'+
            //  '                "pftAmount": 432100,'+
            //  '                "schdPft": 432100,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 432100,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2045-12-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2045-12-26T00:00:00",'+
            //  '                "pftAmount": 418200,'+
            //  '                "schdPft": 418200,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 418200,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2046-01-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2046-01-26T00:00:00",'+
            //  '                "pftAmount": 432200,'+
            //  '                "schdPft": 432200,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 432200,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2046-02-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2046-02-26T00:00:00",'+
            //  '                "pftAmount": 432100,'+
            //  '                "schdPft": 432100,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 0,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 432100,'+
            //  '                "endBal": 30000000,'+
            //  '                "limitDrop": 0,'+
            //  '                "dropLineLimit": 1000000000,'+
            //  '                "availableLimit": 970000000,'+
            //  '                "dueDate": "2046-03-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            },'+
            //  '            {'+
            //  '                "schDate": "2046-03-26T00:00:00",'+
            //  '                "pftAmount": 390300,'+
            //  '                "schdPft": 390300,'+
            //  '                "schdPftPaid": 0,'+
            //  '                "schdPri": 30000000,'+
            //  '                "schdPriPaid": 0,'+
            //  '                "feeSchd": 0,'+
            //  '                "tDSAmount": 0,'+
            //  '                "totalAmount": 30390300,'+
            //  '                "endBal": 0,'+
            //  '                "limitDrop": 1000000000,'+
            //  '                "dropLineLimit": 0,'+
            //  '                "availableLimit": 0,'+
            //  '                "dueDate": "2046-04-06T00:00:00",'+
            //  '                "version": 0'+
            //  '            }'+
            //  '        ],'+
            //  '        "overdue": {'+
            //  '            "applyODPenalty": true,'+
            //  '            "odIncGrcDays": true,'+
            //  '            "odGraceDays": 7,'+
            //  '            "odChargeType": "D",'+
            //  '            "odChargeCalOn": "STOT",'+
            //  '            "odChargeAmtOrPerc": 24,'+
            //  '            "odAllowWaiver": true,'+
            //  '            "odMaxWaiverPerc": 100.00'+
            //  '        },'+
            //  '        "planEMIHmonths": [],'+
            //  '        "planEMIHDates": [],'+
            //  '        "planPRIHDates": [],'+
            //  '        "planPRIHMonths": [],'+
            //  '        "overdueCharges": ['+
            //  '            {'+
            //  '                "odDate": "2044-03-26T00:00:00",'+
            //  '                "odAmount": 153000,'+
            //  '                "odCharge": 7000,'+
            //  '                "odChargePaid": 0,'+
            //  '                "odPft": 0,'+
            //  '                "odPftPaid": 0,'+
            //  '                "chargeType": "D"'+
            //  '            },'+
            //  '            {'+
            //  '                "odDate": "2044-04-26T00:00:00",'+
            //  '                "odAmount": 430900,'+
            //  '                "odCharge": 11100,'+
            //  '                "odChargePaid": 0,'+
            //  '                "odPft": 0,'+
            //  '                "odPftPaid": 0,'+
            //  '                "chargeType": "D"'+
            //  '            },'+
            //  '            {'+
            //  '                "odDate": "2044-05-26T00:00:00",'+
            //  '                "odAmount": 417100,'+
            //  '                "odCharge": 2200,'+
            //  '                "odChargePaid": 0,'+
            //  '                "odPft": 0,'+
            //  '                "odPftPaid": 0,'+
            //  '                "chargeType": "D"'+
            //  '            }'+
            //  '        ],'+
            //  '        "summary": {'+
            //  '            "effectiveRateOfReturn": 18.369918468,'+
            //  '            "totalGracePft": 0,'+
            //  '            "totalGraceCpz": 0,'+
            //  '            "totalGrossGrcPft": 0,'+
            //  '            "totalCpz": 0,'+
            //  '            "totalProfit": 10318500,'+
            //  '            "totalRepayAmt": 40318500,'+
            //  '            "feeChargeAmount": 2399800,'+
            //  '            "numberOfTerms": 24,'+
            //  '            "loanTenor": 24,'+
            //  '            "maturityDate": "2046-03-26T00:00:00",'+
            //  '            "firstDisbDate": "2044-03-15T00:00:00",'+
            //  '            "lastDisbDate": "2044-03-15T00:00:00",'+
            //  '            "firstEmiAmount": 430900,'+
            //  '            "nextSchDate": "2044-06-26T00:00:00",'+
            //  '            "nextRepayAmount": 430900,'+
            //  '            "futureInst": 22,'+
            //  '            "futureTenor": 21,'+
            //  '            "firstInstDate": "2044-04-26T00:00:00",'+
            //  '            "paidTotal": 0,'+
            //  '            "paidPri": 0,'+
            //  '            "paidPft": 0,'+
            //  '            "lastRepayDate": "2044-05-26T00:00:00",'+
            //  '            "outstandingTotal": 40318500,'+
            //  '            "outstandingPri": 30000000,'+
            //  '            "outstandingPft": 10318500,'+
            //  '            "overdueTotal": 1001000,'+
            //  '            "overduePri": 0,'+
            //  '            "overduePft": 1001000,'+
            //  '            "overdueInst": 3,'+
            //  '            "overDueCharges": 20300,'+
            //  '            "overdueTotalIncludeCharges": 1021300,'+
            //  '            "overdueCharges": ['+
            //  '                {'+
            //  '                    "odDate": "2044-03-26T00:00:00",'+
            //  '                    "odAmount": 153000,'+
            //  '                    "odCharge": 7000,'+
            //  '                    "odChargePaid": 0,'+
            //  '                    "odPft": 0,'+
            //  '                    "odPftPaid": 0,'+
            //  '                    "chargeType": "D"'+
            //  '                },'+
            //  '                {'+
            //  '                    "odDate": "2044-04-26T00:00:00",'+
            //  '                    "odAmount": 430900,'+
            //  '                    "odCharge": 11100,'+
            //  '                    "odChargePaid": 0,'+
            //  '                    "odPft": 0,'+
            //  '                    "odPftPaid": 0,'+
            //  '                    "chargeType": "D"'+
            //  '                },'+
            //  '                {'+
            //  '                    "odDate": "2044-05-26T00:00:00",'+
            //  '                    "odAmount": 417100,'+
            //  '                    "odCharge": 2200,'+
            //  '                    "odChargePaid": 0,'+
            //  '                    "odPft": 0,'+
            //  '                    "odPftPaid": 0,'+
            //  '                    "chargeType": "D"'+
            //  '                }'+
            //  '            ],'+
            //  '            "advPaymentAmount": 0,'+
            //  '            "finActiveStatus": "A",'+
            //  '            "fullyDisb": false,'+
            //  '            "limitBalance": 0,'+
            //  '            "billedAmount": 0,'+
            //  '            "unbilledAmount": 0,'+
            //  '            "DPDDays": 69,'+
            //  '            "dueDate": "",'+
            //  '            "dueAmount": 0,'+
            //  '            "limitDrop": 0,'+
            //  '            "currentDroplineLimit": 1000000000,'+
            //  '            "utilisation": 30000000,'+
            //  '            "availableLimit": 970000000,'+
            //  '            "graceInst": 0,'+
            //  '            "graceTenor": 0,'+
            //  '            "futureGraceInst": 0,'+
            //  '            "futureGraceTenor": 2,'+
            //  '            "totalRevisedTenure": 0,'+
            //  '            "revisedLastStepTerms": 0'+
            //  '        },'+
            //  '        "vas": [],'+
            //  '        "outstandingPri": 0,'+
            //  '        "isUpfrontAuto": false,'+
            //  '        "excessAmount": 0,'+
            //  '        "disbursements": ['+
            //  '            {'+
            //  '                "disbParty": "CS",'+
            //  '                "disbType": "NEFT",'+
            //  '                "disbDate": "2044-03-15T00:00:00",'+
            //  '                "disbAmount": 28800100,'+
            //  '                "bankCode": "176",'+
            //  '                "branchBankName": "RATNAKAR BANK LTD",'+
            //  '                "branchCode": "0000114",'+
            //  '                "ifsc": "RATN0000114",'+
            //  '                "accountNo": "7865432456",'+
            //  '                "acHolderName": "gfdsa",'+
            //  '                "partnerBankId": 154,'+
            //  '                "partnerbankCode": "106",'+
            //  '                "phoneNumber": "",'+
            //  '                "remarks": "",'+
            //  '                "favourName": "",'+
            //  '                "payableLoc": "",'+
            //  '                "printingLoc": "",'+
            //  '                "chequeNo": "",'+
            //  '                "version": 1,'+
            //  '                "vasReference": "#"'+
            //  '            }'+
            //  '        ]'+
            //  '    },'+
            //  '    "customer": {'+
            //  '        "cif": "102629",'+
            //  '        "coreBankID": "",'+
            //  '        "categoryCode": "RETAIL",'+
            //  '        "defaultBranch": "3000",'+
            //  '        "baseCurrency": "INR",'+
            //  '        "primaryRelationOfficer": 791,'+
            //  '        "personalInfo": {'+
            //  '            "firstName": "raj",'+
            //  '            "middleName": "",'+
            //  '            "lastName": "",'+
            //  '            "salutation": "13",'+
            //  '            "shortName": "raj",'+
            //  '            "motherName": "pooja",'+
            //  '            "language": "EN",'+
            //  '            "dateofBirth": "2024-12-03T00:00:00",'+
            //  '            "countryofBirth": "IN",'+
            //  '            "nationality": "IN",'+
            //  '            "residentialSts": "RE",'+
            //  '            "gender": "OTH",'+
            //  '            "maritalStatus": "M",'+
            //  '            "numofDependents": 0,'+
            //  '            "type": "21",'+
            //  '            "sector": "11",'+
            //  '            "subSector": "SBS12345",'+
            //  '            "segment": "OTHER",'+
            //  '            "industry": "01",'+
            //  '            "groupID": 0,'+
            //  '            "parentCountry": "IN",'+
            //  '            "riskCountry": "IN",'+
            //  '            "staff": false,'+
            //  '            "staffID": "",'+
            //  '            "saleAgent": "",'+
            //  '            "emiCardEligibilityAmt": 0,'+
            //  '            "subCategory": "SEP",'+
            //  '            "caste": 40,'+
            //  '            "religion": 13,'+
            //  '            "fatherName": "simran",'+
            //  '            "custCRCPR": "SUYSU8272U",'+
            //  '            "version": 10,'+
            //  '            "marginDeviation": false,'+
            //  '            "applicationNo": "",'+
            //  '            "qualification": "GD"'+
            //  '        },'+
            //  '        "dedupReq": false,'+
            //  '        "blackListReq": false,'+
            //  '        "customerGstLists": [],'+
            //  '        "custCardSales": []'+
            //  '    },'+
            //  '    "disbursement": ['+
            //  '        {'+
            //  '            "disbParty": "CS",'+
            //  '            "disbType": "NEFT",'+
            //  '            "disbDate": "2044-03-15T00:00:00",'+
            //  '            "disbAmount": 28800100,'+
            //  '            "bankCode": "176",'+
            //  '            "branchBankName": "RATNAKAR BANK LTD",'+
            //  '            "branchCode": "0000114",'+
            //  '            "ifsc": "RATN0000114",'+
            //  '            "accountNo": "7865432456",'+
            //  '            "acHolderName": "gfdsa",'+
            //  '            "partnerBankId": 154,'+
            //  '            "partnerbankCode": "106",'+
            //  '            "phoneNumber": "",'+
            //  '            "remarks": "",'+
            //  '            "favourName": "",'+
            //  '            "payableLoc": "",'+
            //  '            "printingLoc": "",'+
            //  '            "chequeNo": "",'+
            //  '            "version": 1,'+
            //  '            "vasReference": "#"'+
            //  '        }'+
            //  '    ],'+
            //  '    "mandateDetail": {'+
            //  '        "cif": "102629",'+
            //  '        "finReference": "GFL3001BD0014530",'+
            //  '        "useExisting": true,'+
            //  '        "mandateID": 3151,'+
            //  '        "mandateRef": "",'+
            //  '        "mandateType": "NACH",'+
            //  '        "bankCode": "485",'+
            //  '        "branchCode": "0000207",'+
            //  '        "ifsc": "KKBK0000207",'+
            //  '        "micr": "",'+
            //  '        "accType": "12",'+
            //  '        "accNumber": "4545465656545656",'+
            //  '        "accHolderName": "yhtgrfdes",'+
            //  '        "jointAccHolderName": "",'+
            //  '        "openMandate": false,'+
            //  '        "startDate": "2044-04-16T00:00:00",'+
            //  '        "expiryDate": "2060-12-18T00:00:00",'+
            //  '        "maxLimit": 3000000000,'+
            //  '        "periodicity": "M0001",'+
            //  '        "phoneNumber": "",'+
            //  '        "status": "NEW",'+
            //  '        "active": true,'+
            //  '        "totEMIAmount": 430900,'+
            //  '        "barCodeNumber": "",'+
            //  '        "entityCode": "GFL",'+
            //  '        "swap": false,'+
            //  '        "partnerBankId": 0,'+
            //  '        "version": 1,'+
            //  '        "reason": "",'+
            //  '        "defaultMandate": false,'+
            //  '        "documentName": ""'+
            //  '    },'+
            //  '    "coApplicants": ['+
            //  '        {'+
            //  '            "cif": "120836",'+
            //  '            "shortName": "jinkya Daduuu More",'+
            //  '            "includeRepay": false,'+
            //  '            "authoritySignatory": false,'+
            //  '            "sequence": 0,'+
            //  '            "version": 1,'+
            //  '            "catOfcoApplicant": "MOTHER",'+
            //  '            "includeIncome": false'+
            //  '        }'+
            //  '    ],'+
            //  '    "guarantors": [],'+
            //  '    "documents": ['+
            //  '        {'+
            //  '            "finReference": "GFL3001BD0014530",'+
            //  '            "docCategory": "CAM",'+
            //  '            "docName": "GFL3001BD0014530_CAM.pdf",'+
            //  '            "docFormat": "PDF",'+
            //  '            "version": 1,'+
            //  '            "docTypeId": 0'+
            //  '        },'+
            //  '        {'+
            //  '            "finReference": "GFL3001BD0014530",'+
            //  '            "docCategory": "DM",'+
            //  '            "docName": "GFL3001BD0014530_Disbursal Memo.pdf",'+
            //  '            "docFormat": "PDF",'+
            //  '            "docRefId": "65921",'+
            //  '            "version": 1,'+
            //  '            "docTypeId": 0'+
            //  '        },'+
            //  '        {'+
            //  '            "finReference": "GFL3001BD0014530",'+
            //  '            "docCategory": "BLCAM",'+
            //  '            "docName": "GFL3001BD0014530_BLCAM.pdf",'+
            //  '            "docFormat": "PDF",'+
            //  '            "docRefId": "65744",'+
            //  '            "version": 1,'+
            //  '            "docTypeId": 0'+
            //  '        }'+
            //  '    ],'+
            //  '    "collaterals": [],'+
            //  '    "fees": ['+
            //  '        {'+
            //  '            "feeCategory": "FC",'+
            //  '            "feeCode": "PROCFEE",'+
            //  '            "feeAmount": 999900,'+
            //  '            "waiverAmount": 0,'+
            //  '            "paidAmount": 999900,'+
            //  '            "feeMethod": "DISB",'+
            //  '            "scheduleTerms": 0,'+
            //  '            "feeBalance": 0,'+
            //  '            "version": 1,'+
            //  '            "finFeeReceipts": []'+
            //  '        },'+
            //  '        {'+
            //  '            "feeCategory": "FC",'+
            //  '            "feeCode": "STFRCHG",'+
            //  '            "feeAmount": 200000,'+
            //  '            "waiverAmount": 0,'+
            //  '            "paidAmount": 200000,'+
            //  '            "feeMethod": "DISB",'+
            //  '            "scheduleTerms": 0,'+
            //  '            "feeBalance": 0,'+
            //  '            "version": 1,'+
            //  '            "finFeeReceipts": []'+
            //  '        }'+
            //  '    ],'+
            //  '    "transactions": [],'+
            //  '    "extendedDetails": ['+
            //  '        {'+
            //  '            "extendedFields": ['+
            //  '                {'+
            //  '                    "fieldName": "instructionuid",'+
            //  '                    "fieldValue": 733232'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "stpstatus",'+
            //  '                    "fieldValue": "GREEN"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "testdeci",'+
            //  '                    "fieldValue": 0'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "sap_cpc",'+
            //  '                    "fieldValue": "09876589013763"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "ghfrm",'+
            //  '                    "fieldValue": "2057302"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "ghfam",'+
            //  '                    "fieldValue": "33224"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "vsjsource",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "loan_in_ghf",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "loanstartdate",'+
            //  '                    "fieldValue": "2044-03-15T00:00:00"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "psl",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "borrowertype",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "pep",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "lendingtype",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "propertyidentified",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "riskcategorization",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "finalfoir",'+
            //  '                    "fieldValue": 0.00'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "finalltv",'+
            //  '                    "fieldValue": 0.00'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "sblmet",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "gblmet",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "stageofconstruct",'+
            //  '                    "fieldValue": 0.00'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "endusagefunds",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "creexposure",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "selfemployedrisk",'+
            //  '                    "fieldValue": 0'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "selfempyrisksegmt",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "gplflag",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "dedecision",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "tvapproved",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "reasonforstpsta",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "recommendedpdtype",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "luwapproved",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "typeofpd",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "digidocketstatus",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "natureofbusiness",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "subproduct",'+
            //  '                    "fieldValue": "SEP"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "lanhunterstatus",'+
            //  '                    "fieldValue": "NO-MATCH"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "retrigger",'+
            //  '                    "fieldValue": false'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "ftr",'+
            //  '                    "fieldValue": "NO"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "queryresolved",'+
            //  '                    "fieldValue": "2044-03-15T00:00:00"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "eligibilitymethod",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "docket_ftr",'+
            //  '                    "fieldValue": "NO"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "ovd",'+
            //  '                    "fieldValue": "NO"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "nameoffininstitute",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "schememoratoriu",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "consolidatedltv",'+
            //  '                    "fieldValue": 0.00'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "currentoccofprop",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "endusefortopup",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "ficoreason",'+
            //  '                    "fieldValue": "java.lang.StringIndexOutOfBoundsException: start -1, end -1, length 69"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "ficostatus",'+
            //  '                    "fieldValue": "Failed"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "luc_waiver",'+
            //  '                    "fieldValue": 0'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "min_utiliztion_amt",'+
            //  '                    "fieldValue": "25.00"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "amc_waiver",'+
            //  '                    "fieldValue": 0'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "amc_revised_percnt",'+
            //  '                    "fieldValue": "0.3"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "keyperson",'+
            //  '                    "fieldValue": 0'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "legaldeviation",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "approvaluploaded",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "bttopup",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "topuptype",'+
            //  '                    "fieldValue": "#"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "ftnrreason",'+
            //  '                    "fieldValue": "tets"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "dsatype",'+
            //  '                    "fieldValue": "VELVETEEN"'+
            //  '                },'+
            //  '                {'+
            //  '                    "fieldName": "csd_tagging",'+
            //  '                    "fieldValue": "#"'+
            //  '                }'+
            //  '            ]'+
            //  '        }'+
            //  '    ],'+
            //  '    "returnStatus": {'+
            //  '        "returnCode": "0000",'+
            //  '        "returnText": "Success"'+
            //  '    },'+
            //  '    "receiptId": 0,'+
            //  '    "interfaceDetailList": [],'+
            //  '    "disbStp": false,'+
            //  '    "maxPPAmount": 0,'+
            //  '    "maxPPPercentage": 0,'+
            //  '    "covenantDetails": [],'+
            //  '    "collateralDetails": []'+
            //  '}';
           HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
           system.debug('resp.getBody()---'+resp.getBody());
            if(resp.getStatusCode() == 200){
                GetExistingLoanDetailsWrapper  responseJSON = (GetExistingLoanDetailsWrapper) JSON.deserialize(resp.getBody(), GetExistingLoanDetailsWrapper.class);


                       return JSON.serialize(responseJSON);
            }
//String jsonResponse = '{"finReference":"GHF1001HL0005419","stp":true,"financeSchedule":{"financeDetail":{"applicationNo":"","finType":"HL","finCcy":"INR","finBranch":"1001","finReference":"GHF1001HL0005419","profitDaysBasis":"30E/360I","finAmount":10000000,"finAssetValue":20000000,"downPayBank":0,"downPaySupl":0,"finRepayMethod":"NACH","finStartDate":"2038-03-10T00:00:00","allowGrcPeriod":false,"tdsApplicable":false,"manualSchedule":false,"planDeferCount":0,"stepFinance":false,"alwManualSteps":false,"stepPolicy":"","stepType":"#","grcTerms":0,"grcPeriodEndDate":"2038-03-10T00:00:00","grcRateBasis":"#","grcPftRate":0,"grcMargin":0,"grcPftFrq":"","grcPftRvwFrq":"","grcCpzFrq":"","allowGrcRepay":false,"grcSchdMthd":"PRI_PFT","grcMinRate":0,"grcMaxRate":0,"grcMaxAmount":0,"grcAdvPftRate":0,"grcAdvMargin":0,"numberOfTerms":15,"reqRepayAmount":0,"repayRateBasis":"R","repayPftRate":17.25,"repayBaseRate":"GHFPLR","repayMargin":0,"scheduleMethod":"EQUAL","repayFrq":"M0006","nextRepayDate":"2038-11-06T00:00:00","repayPftFrq":"M0006","nextRepayPftDate":"2038-11-06T00:00:00","repayRvwFrq":"M0006","nextRepayRvwDate":"2038-11-06T00:00:00","repayCpzFrq":"","nextRepayCpzDate":"2039-07-06T00:00:00","maturityDate":"2039-07-06T00:00:00","finRepayPftOnFrq":false,"repayAdvPftRate":0,"repayAdvMargin":0,"supplementRent":0,"increasedCost":0,"rolloverFrq":"","finContractDate":"2038-03-10T00:00:00","finPurpose":"BR","allowOCR":false,"parentLoanReference":"","finLimitRef":"","finCommitmentRef":"","repayAccountId":"","depreciationFrq":"","dsaCode":"","accountsOfficer":0,"salesDepartment":"","dmaCode":"","referralId":"","employeeName":"","quickDisb":false,"unPlanEMIHLockPeriod":0,"unPlanEMICpz":true,"reAgeCpz":false,"maxUnplannedEmi":20,"maxReAgeHolidays":0,"alwBpiTreatment":false,"dftBpiTreatment":"N","planEMIHAlw":true,"planEMIHAlwInGrace":false,"planEMIHMethod":"F","planEMIHMaxPerYear":1,"planEMIHMax":3,"planEMIHLockPeriod":0,"planEMICpz":true,"alwUnplanPRIHoliday":true,"unplanPRIHLockPeriod":0,"maxUnPlannedPRI":999,"planPRIHAlw":true,"planPRIHMethod":"F","planPRIHMaxPerYear":4,"planPRIHMax":6,"planPRIHLockPeriod":0,"availedUnPlanPri":0,"firstDisbDate":"2038-03-10T00:00:00","lastDisbDate":"2038-03-10T00:00:00","stage":"","status":"Approved","advEMITerms":0,"fixedRateTenor":0,"fixedTenorRate":0,"eligibilityMethod":0,"connector":0,"legalRequired":false,"reqLoanAmt":20000000,"reqLoanTenor":42,"offerProduct":"","offerAmount":0,"custSegmentation":"","baseProduct":"","processType":"","bureauTimeSeries":"","campaignName":"","existingLanRefNo":"","leadSource":"","poSource":"","rsa":false,"sourChannelCategory":"DSA","offerId":"6990","noOfSteps":0,"noOfGrcSteps":0,"rpyDueFrq":"","grcPftDueFrq":"","version":1,"sourcingBranch":"1001","calMaturity":"2039-07-06T00:00:00","recalType":"","productCategory":"CONV","elasticCrLine":false,"elasticCrLineType":"#","elasticCrLineDropCalOn":"#","appliedLoanAmt":0,"alwGrcAdj":false,"npa":true,"limitBlock":false},"feeDues":[],"step":[],"overdue":{"applyODPenalty":true,"odIncGrcDays":true,"odGraceDays":5,"odChargeType":"D","odChargeCalOn":"STOT","odChargeAmtOrPerc":24,"odAllowWaiver":true,"odMaxWaiverPerc":100,"oDTDSReq":false},"planEMIHmonths":[{"holidayMonth":8}],"planEMIHDates":[],"planPRIHDates":[],"planPRIHMonths":[{"priHolidayMonth":12}],"overdueCharges":[{"odDate":"2038-05-06T00:00:00","odAmount":868500,"odCharge":92700,"odChargePaid":0,"odPft":59400,"odPftPaid":0,"chargeType":"D"},{"odDate":"2038-06-06T00:00:00","odAmount":868500,"odCharge":75300,"odChargePaid":0,"odPft":59000,"odPftPaid":0,"chargeType":"D"},{"odDate":"2038-07-06T00:00:00","odAmount":868500,"odCharge":58000,"odChargePaid":0,"odPft":46000,"odPftPaid":0,"chargeType":"D"},{"odDate":"2038-09-06T00:00:00","odAmount":868500,"odCharge":23200,"odChargePaid":0,"odPft":18700,"odPftPaid":0,"chargeType":"D"},{"odDate":"2038-10-06T00:00:00","odAmount":868500,"odCharge":5800,"odChargePaid":0,"odPft":4800,"odPftPaid":0,"chargeType":"D"}]},"customer":{"cif":"100012","coreBankID":"","categoryCode":"RETAIL","defaultBranch":"1001","baseCurrency":"INR","primaryRelationOfficer":791,"personalInfo":{"firstName":"do not use ops data","middleName":"","lastName":"","salutation":"1","shortName":"do not use ops data","motherName":"Sria","language":"EN","dateofBirth":"1991-05-09T00:00:00","countryofBirth":"IN","nationality":"IN","residentialSts":"RE","gender":"M","maritalStatus":"M","numofDependents":0,"type":"21","sector":"OTH","subSector":"SBS12345","segment":"SEG4","industry":"PRF","groupID":0,"parentCountry":"IN","riskCountry":"IN","staff":false,"staffID":"","saleAgent":"","emiCardEligibilityAmt":0,"subCategory":"SALARIED","caste":40,"religion":13,"fatherName":"Santhosh","custCRCPR":"DNVPP1267K","version":11,"marginDeviation":false,"applicationNo":"","qualification":"BHMS"},"dedupReq":false,"blackListReq":false,"customerGstLists":[],"custCardSales":[],"version":0},"coApplicants":[{"cif":"120836","shortName":"jinkya Daduuu More","includeRepay":false,"authoritySignatory":false,"sequence":0,"version":1,"catOfcoApplicant":"MOTHER","includeIncome":false}],"guarantors":[{"cif":"120836","shortName":"jinkya Daduuu More","includeRepay":false,"authoritySignatory":false,"sequence":0,"version":1,"catOfcoApplicant":"MOTHER","includeIncome":false}],"collaterals":[{"collateralRef":"CT3807000004","assignPerc":1,"version":1,"seq":0}],"fees":[{"feeCategory":"FC","feeCode":"PROCFEE","netAmountOriginal":1000000,"netAmountGST":180000,"netAmount":1180000,"paidAmountOriginal":847400,"paidAmountGST":152600,"paidAmount":1180000,"feeBalance":0,"netTDS":0,"paidTDS":0,"remTDS":0,"waiverAmount":0,"feeMethod":"DISB","scheduleTerms":0,"version":1,"finFeeReceipts":[],"refundAmount":0,"feeAmount":1180000},{"feeCategory":"FC","feeCode":"STFRCHG","netAmountOriginal":169400,"netAmountGST":30600,"netAmount":200000,"paidAmountOriginal":169400,"paidAmountGST":30600,"paidAmount":200000,"feeBalance":0,"netTDS":0,"paidTDS":0,"remTDS":0,"waiverAmount":0,"feeMethod":"DISB","scheduleTerms":0,"version":1,"finFeeReceipts":[],"refundAmount":0,"feeAmount":200000}],"returnStatus":{"returnCode":"0000","returnText":"Success"},"version":0,"receiptId":0,"interfaceDetailList":[],"disbStp":false,"maxPPAmount":0,"maxPPPercentage":0,"createPLMGroup":false,"existingGroup":false,"finReceiptHeaders":[],"covenantDetails":[],"collateralDetails":[],"plmHeaderList":[]}';
 
            return resp.getBody();

        }
        catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }


    public class GetExistingLoanDetailsWrapper{
        public String finReference;	//GFL3001BD0014530
        public boolean stp;
        public cls_financeSchedule financeSchedule;
        public cls_customer customer;
        public cls_disbursement[] disbursement;
        public cls_mandateDetail mandateDetail;
        public cls_coApplicants[] coApplicants;
        public cls_guarantors[] guarantors;
        public cls_documents[] documents;
        public cls_collaterals[] collaterals;
        public cls_fees[] fees;
        public cls_transactions[] transactions;
        public cls_extendedDetails[] extendedDetails;
        public cls_returnStatus returnStatus;
        public Decimal receiptId;	//0
        public cls_interfaceDetailList[] interfaceDetailList;
        public boolean disbStp;
        public Decimal maxPPAmount;	//0
        public Decimal maxPPPercentage;	//0
        public cls_covenantDetails[] covenantDetails;
        public cls_collateralDetails[] collateralDetails;
    }
    public class cls_financeSchedule {
        public cls_financeDetail financeDetail;
        public cls_repayInstruction[] repayInstruction;
        public cls_rateInstruction[] rateInstruction;
        public cls_fees[] fees;
        public cls_feeDues[] feeDues;
        public cls_step[] step;
        public cls_schedules[] schedules;
        public cls_overdue overdue;
        public cls_planEMIHmonths[] planEMIHmonths;
        public cls_planEMIHDates[] planEMIHDates;
        public cls_planPRIHDates[] planPRIHDates;
        public cls_planPRIHMonths[] planPRIHMonths;
        public cls_overdueCharges[] overdueCharges;
        public cls_summary summary;
        public cls_vas[] vas;
        public Decimal outstandingPri;	//0
        public boolean isUpfrontAuto;
        public Decimal excessAmount;	//0
        public cls_disbursements[] disbursements;
    }
    public class cls_financeDetail {
        public String applicationNo;	//
        public String finType;	//BD
        public String finCcy;	//INR
        public String finBranch;	//3001
        public String finReference;	//GFL3001BD0014530
        public String profitDaysBasis;	//A/A_365L
        public Decimal finAmount;	//30000000
        public Decimal finAssetValue;	//1000000000
        public Decimal downPayBank;	//0
        public Decimal downPaySupl;	//0
        public String finRepayMethod;	//NACH
        public String finStartDate;	//2044-03-15T00:00:00
        public boolean allowGrcPeriod;
        public boolean tdsApplicable;
        public boolean manualSchedule;
        public Decimal planDeferCount;	//0
        public boolean stepFinance;
        public boolean alwManualSteps;
        public String stepPolicy;	//
        public String stepType;	//#
        public Decimal grcTerms;	//0
        public String grcPeriodEndDate;	//2044-03-15T00:00:00
        public String grcRateBasis;	//#
        public Decimal grcPftRate;	//0
        public Decimal grcMargin;	//0
        public String grcPftFrq;	//
        public String grcPftRvwFrq;	//
        public String grcCpzFrq;	//
        public boolean allowGrcRepay;
        public String grcSchdMthd;	//PFT
        public Decimal grcMinRate;	//0
        public Decimal grcMaxRate;	//0
        public Decimal grcMaxAmount;	//0
        public Decimal grcAdvPftRate;	//0
        public Decimal grcAdvMargin;	//0
        public Decimal numberOfTerms;	//24
        public Decimal reqRepayAmount;	//0
        public String repayRateBasis;	//R
        public Double repayPftRate;	//16.96
        public String repayBaseRate;	//GFLPLRBL
        public Decimal repayMargin;	//0
        public String scheduleMethod;	//PFT
        public String repayFrq;	//M0026
        public String nextRepayDate;	//2044-04-26T00:00:00
        public String repayPftFrq;	//M0026
        public String nextRepayPftDate;	//2044-04-26T00:00:00
        public String repayRvwFrq;	//M0026
        public String nextRepayRvwDate;	//2044-04-26T00:00:00
        public String repayCpzFrq;	//
        public String nextRepayCpzDate;	//2046-03-26T00:00:00
        public String maturityDate;	//2046-03-26T00:00:00
        public boolean finRepayPftOnFrq;
        public Decimal repayAdvPftRate;	//0
        public Decimal repayAdvMargin;	//0
        public Decimal supplementRent;	//0
        public Decimal increasedCost;	//0
        public String rolloverFrq;	//
        public String finContractDate;	//2044-03-15T00:00:00
        public String finPurpose;	//BEXP
        public String finLimitRef;	//
        public String finCommitmentRef;	//
        public String repayAccountId;	//
        public String depreciationFrq;	//
        public Decimal accountsOfficer;	//0
        public String salesDepartment;	//
        public String referralId;	//
        public String employeeName;	//
        public boolean quickDisb;
        public Decimal unPlanEMIHLockPeriod;	//0
        public boolean unPlanEMICpz;
        public boolean reAgeCpz;
        public Decimal maxUnplannedEmi;	//0
        public Decimal maxReAgeHolidays;	//0
        public boolean alwBpiTreatment;
        public String dftBpiTreatment;	//S
        public String bpiPftDaysBasis;	//A/A_365L
        public boolean planEMIHAlw;
        public boolean planEMIHAlwInGrace;
        public String planEMIHMethod;	// 
        public Decimal planEMIHMaxPerYear;	//0
        public Decimal planEMIHMax;	//0
        public Decimal planEMIHLockPeriod;	//0
        public boolean planEMICpz;
        public boolean alwUnplanPRIHoliday;
        public Decimal unplanPRIHLockPeriod;	//0
        public Decimal maxUnPlannedPRI;	//0
        public boolean planPRIHAlw;
        public String planPRIHMethod;	// 
        public Decimal planPRIHMaxPerYear;	//0
        public Decimal planPRIHMax;	//0
        public Decimal planPRIHLockPeriod;	//0
        public Decimal availedUnPlanPri;	//0
        public String firstDisbDate;	//2044-03-15T00:00:00
        public String lastDisbDate;	//2044-03-15T00:00:00
        public String stage;	//
        public String status;	//Approved
        public Decimal advEMITerms;	//0
        public Decimal fixedRateTenor;	//0
        public Decimal fixedTenorRate;	//0
        public Decimal eligibilityMethod;	//0
        public Decimal connector;	//0
        public boolean legalRequired;
        public Decimal reqLoanAmt;	//1000000000
        public Decimal reqLoanTenor;	//60
        public String offerProduct;	//
        public Decimal offerAmount;	//0
        public String custSegmentation;	//
        public String baseProduct;	//
        public String processType;	//
        public String bureauTimeSeries;	//
        public String campaignName;	//
        public String existingLanRefNo;	//
        public String leadSource;	//
        public String poSource;	//
        public boolean rsa;
        public String sourChannelCategory;	//#
        public String offerId;	//
        public Decimal noOfSteps;	//0
        public Decimal noOfGrcSteps;	//0
        public String rpyDueFrq;	//M0006
        public String nextRpyDueFrqDate;	//2044-05-06T00:00:00
        public String grcPftDueFrq;	//
        public Decimal version;	//1
        public String sourcingBranch;	//3001
        public String calMaturity;	//2046-03-26T00:00:00
        public String recalType;	//
        public String productCategory;	//CONV
        public boolean elasticCrLine;
        public String elasticCrLineType;	//P
        public String elasticCrLineDropCalOn;	//S
        public Decimal appliedLoanAmt;	//0
        public boolean alwGrcAdj;
        public boolean npa;
        public boolean limitBlock;
    }
    public class cls_repayInstruction {
        public String repayDate;	//2044-04-26T00:00:00
        public Decimal repayAmount;	//0
        public String repaySchdMethod;	//PFT
        public Decimal version;	//0
    }
    public class cls_rateInstruction {
    }
    public class cls_fees {
        public String feeCategory;	//FC
        public String feeCode;	//PROCFEE
        public Decimal feeAmount;	//999900
        public Decimal waiverAmount;	//0
        public Decimal paidAmount;	//999900
        public String feeMethod;	//DISB
        public Decimal scheduleTerms;	//0
        public Decimal feeBalance;	//0
        public Decimal version;	//1
        public cls_finFeeReceipts[] finFeeReceipts;
    }
    public class cls_finFeeReceipts {
    }
    public class cls_feeDues {
    }
    public class cls_step {
    }
    public class cls_schedules {
        public String schDate;	//2044-03-15T00:00:00
        public Decimal pftAmount;	//0
        public Decimal schdPft;	//0
        public Decimal schdPftPaid;	//0
        public Decimal schdPri;	//0
        public Decimal schdPriPaid;	//0
        public Decimal feeSchd;	//0
        public Decimal tDSAmount;	//0
        public Decimal totalAmount;	//0
        public Decimal endBal;	//30000000
        public Decimal limitDrop;	//0
        public Decimal dropLineLimit;	//1000000000
        public Decimal availableLimit;	//970000000
        public String dueDate;	//2044-04-06T00:00:00
        public Decimal version;	//0
    }
    public class cls_overdue {
        public boolean applyODPenalty;
        public boolean odIncGrcDays;
        public Decimal odGraceDays;	//7
        public String odChargeType;	//D
        public String odChargeCalOn;	//STOT
        public Decimal odChargeAmtOrPerc;	//24
        public boolean odAllowWaiver;
        public Decimal odMaxWaiverPerc;	//100
    }
    public class cls_planEMIHmonths {
    }
    public class cls_planEMIHDates {
    }
    public class cls_planPRIHDates {
    }
    public class cls_planPRIHMonths {
    }
    public class cls_overdueCharges {
        public String odDate;	//2044-03-26T00:00:00
        public Decimal odAmount;	//153000
        public Decimal odCharge;	//7000
        public Decimal odChargePaid;	//0
        public Decimal odPft;	//0
        public Decimal odPftPaid;	//0
        public String chargeType;	//D
    }
    public class cls_summary {
        public Double effectiveRateOfReturn;	//18.369918468
        public Decimal totalGracePft;	//0
        public Decimal totalGraceCpz;	//0
        public Decimal totalGrossGrcPft;	//0
        public Decimal totalCpz;	//0
        public Decimal totalProfit;	//10318500
        public Decimal totalRepayAmt;	//40318500
        public Decimal feeChargeAmount;	//2399800
        public Decimal numberOfTerms;	//24
        public Decimal loanTenor;	//24
        public String maturityDate;	//2046-03-26T00:00:00
        public String firstDisbDate;	//2044-03-15T00:00:00
        public String lastDisbDate;	//2044-03-15T00:00:00
        public Decimal firstEmiAmount;	//430900
        public String nextSchDate;	//2044-06-26T00:00:00
        public Decimal nextRepayAmount;	//430900
        public Decimal futureInst;	//22
        public Decimal futureTenor;	//21
        public String firstInstDate;	//2044-04-26T00:00:00
        public Decimal paidTotal;	//0
        public Decimal paidPri;	//0
        public Decimal paidPft;	//0
        public String lastRepayDate;	//2044-05-26T00:00:00
        public Decimal outstandingTotal;	//40318500
        public Decimal outstandingPri;	//30000000
        public Decimal outstandingPft;	//10318500
        public Decimal overdueTotal;	//1001000
        public Decimal overduePri;	//0
        public Decimal overduePft;	//1001000
        public Decimal overdueInst;	//3
        public Decimal overDueChargesVal;	//20300
        public Decimal overdueTotalIncludeCharges;	//1021300
        public cls_overdueCharges[] overdueChargesSummary;
        public Decimal advPaymentAmount;	//0
        public String finActiveStatus;	//A
        public boolean fullyDisb;
        public Decimal limitBalance;	//0
        public Decimal billedAmount;	//0
        public Decimal unbilledAmount;	//0
        public Decimal DPDDays;	//69
        public String dueDate;	//
        public Decimal dueAmount;	//0
        public Decimal limitDrop;	//0
        public Decimal currentDroplineLimit;	//1000000000
        public Decimal utilisation;	//30000000
        public Decimal availableLimit;	//970000000
        public Decimal graceInst;	//0
        public Decimal graceTenor;	//0
        public Decimal futureGraceInst;	//0
        public Decimal futureGraceTenor;	//2
        public Decimal totalRevisedTenure;	//0
        public Decimal revisedLastStepTerms;	//0
    }
    public class cls_vas {
    }
    public class cls_disbursements {
        public String disbParty;	//CS
        public String disbType;	//NEFT
        public String disbDate;	//2044-03-15T00:00:00
        public Decimal disbAmount;	//28800100
        public String bankCode;	//176
        public String branchBankName;	//RATNAKAR BANK LTD
        public String branchCode;	//0000114
        public String ifsc;	//RATN0000114
        public String accountNo;	//7865432456
        public String acHolderName;	//gfdsa
        public Decimal partnerBankId;	//154
        public String partnerbankCode;	//106
        public String phoneNumber;	//
        public String remarks;	//
        public String favourName;	//
        public String payableLoc;	//
        public String printingLoc;	//
        public String chequeNo;	//
        public Decimal version;	//1
        public String vasReference;	//#
    }
    public class cls_customer {
        public String cif;	//119808
        public String coreBankID;	//
        public String categoryCode;	//RETAIL
        public String defaultBranch;	//3000
        public String baseCurrency;	//INR
        public Decimal primaryRelationOfficer;	//791
        public cls_personalInfo personalInfo;
        public boolean dedupReq;
        public boolean blackListReq;
        public cls_customerGstLists[] customerGstLists;
        public cls_custCardSales[] custCardSales;
    }
    public class cls_personalInfo {
        public String firstName;	//raj
        public String middleName;	//
        public String lastName;	//
        public String salutation;	//13
        public String shortName;	//raj
        public String motherName;	//pooja
        public String language;	//EN
        public String dateofBirth;	//2024-12-03T00:00:00
        public String countryofBirth;	//IN
        public String nationality;	//IN
        public String residentialSts;	//RE
        public String gender;	//OTH
        public String maritalStatus;	//M
        public Decimal numofDependents;	//0
        public String type;	//21
        public String sector;	//11
        public String subSector;	//SBS12345
        public String segment;	//OTHER
        public String industry;	//01
        public Decimal groupID;	//0
        public String parentCountry;	//IN
        public String riskCountry;	//IN
        public boolean staff;
        public String staffID;	//
        public String saleAgent;	//
        public Decimal emiCardEligibilityAmt;	//0
        public String subCategory;	//SEP
        public Decimal caste;	//40
        public Decimal religion;	//13
        public String fatherName;	//simran
        public String custCRCPR;	//SUYSU8272U
        public Decimal version;	//10
        public boolean marginDeviation;
        public String applicationNo;	//
        public String qualification;	//GD
    }
    public class cls_customerGstLists {
    }
    public class cls_custCardSales {
    }
    public class cls_disbursement {
        public String disbParty;	//CS
        public String disbType;	//NEFT
        public String disbDate;	//2044-03-15T00:00:00
        public Decimal disbAmount;	//28800100
        public String bankCode;	//176
        public String branchBankName;	//RATNAKAR BANK LTD
        public String branchCode;	//0000114
        public String ifsc;	//RATN0000114
        public String accountNo;	//7865432456
        public String acHolderName;	//gfdsa
        public Decimal partnerBankId;	//154
        public String partnerbankCode;	//106
        public String phoneNumber;	//
        public String remarks;	//
        public String favourName;	//
        public String payableLoc;	//
        public String printingLoc;	//
        public String chequeNo;	//
        public Decimal version;	//1
        public String vasReference;	//#
    }
    public class cls_mandateDetail {
        public String cif;	//119808
        public String finReference;	//GFL3001BD0014530
        public boolean useExisting;
        public Decimal mandateID;	//3151
        public String mandateRef;	//
        public String mandateType;	//NACH
        public String bankCode;	//485
        public String branchCode;	//0000207
        public String ifsc;	//KKBK0000207
        public String micr;	//
        public String accType;	//12
        public String accNumber;	//4545465656545656
        public String accHolderName;	//yhtgrfdes
        public String jointAccHolderName;	//
        public boolean openMandate;
        public String startDate;	//2044-04-16T00:00:00
        public String expiryDate;	//2060-12-18T00:00:00
        public Decimal maxLimit;	//3000000000
        public String periodicity;	//M0001
        public String phoneNumber;	//
        public String status;	//NEW
        public boolean active;
        public Decimal totEMIAmount;	//430900
        public String barCodeNumber;	//
        public String entityCode;	//GFL
        public boolean swap;
        public Decimal partnerBankId;	//0
        public Decimal version;	//1
        public String reason;	//
        public boolean defaultMandate;
        public String documentName;	//
    }
    public class cls_coApplicants {
		public String cif;	//120836
		public String shortName;	//jinkya Daduuu More
		public boolean includeRepay;
		public boolean authoritySignatory;
		public Integer sequence;	//0
		public Integer version;	//1
		public String catOfcoApplicant;	//MOTHER
		public boolean includeIncome;
	}
    public class cls_guarantors {
        public String cif;	//120836
		public String shortName;	//jinkya Daduuu More
		public boolean includeRepay;
		public boolean authoritySignatory;
		public Integer sequence;	//0
		public Integer version;	//1
		public String catOfcoApplicant;	//MOTHER
		public boolean includeIncome;
    }
    public class cls_documents {
        public String finReference;	//GFL3001BD0014530
        public String docCategory;	//CAM
        public String docName;	//GFL3001BD0014530_CAM.pdf
        public String docFormat;	//PDF
        public Decimal version;	//1
        public Decimal docTypeId;	//0
    }
    public class cls_collaterals {
        public String collateralRef;
        public Decimal assignPerc;
        public Integer version;
        public Integer seq;
    }

    public class cls_transactions {
    }
    public class cls_extendedDetails {
        public cls_extendedFields[] extendedFields;
    }
    public class cls_extendedFields {
        public String fieldName;	//instructionuid
        public String fieldValue;	//733232
    }
    public class cls_returnStatus {
        public String returnCode;	//0000
        public String returnText;	//Success
    }
    public class cls_interfaceDetailList {
    }
    public class cls_covenantDetails {
    }
    public class cls_collateralDetails {
    }
}