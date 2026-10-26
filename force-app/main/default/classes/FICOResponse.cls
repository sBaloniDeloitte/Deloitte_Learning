public with sharing class FICOResponse {
   
    public cls_response response;
	public cls_finalOffer finalOffer;
	public cls_request request;
    
    public class cls_response {
		public cls_scoreCardDetails[] scoreCardDetails;
        public cls_scoreCardDetails scoreCardDetailsSingle;
		public cls_calculatedVariables[] calculatedVariables;
		public cls_errorResponse[] errorResponse;
		public cls_errorResponse errorResponseSingle;
		public String finalApprovalLevel;	//
		public cls_responseDeviations[] responseDeviations;
		public cls_responseDeviations responseDeviation;
		public String scoreDecision;	//
		public String strategyUsed;	//
		public String systemDecision;	//DEVIATION
		public String systemDecisionDate;	//
		public String systemDecisionDateTime;	//2025-04-01T15:55:18.605+05:30
	}
	public class cls_scoreCardDetails {
		public String entityId;	//685
		public String entityType;	//MainApp
		public String purpose;	// Too new to Rate_-1,Inactive_-2
		public String scorecardKey;	//appScore
		public String characteristicCount;	//11
		public String scorecardScore;	//508.0
		public String scorecardName;	//BL_CRIF_Score_Card,SCORE REJECT
		public cls_scoreCardCharacteristics[] scoreCardCharacteristics;
		//public cls_scoreCardCharacteristics scoreCardCharacteristicsSingle;
	}
	public class cls_scoreCardCharacteristics {
		public String characteristicValue;	//Unknown
		public String partialScore;	//49.0
		public String characteristicName;	//MAX DELQ Last 6 Months ALL
	}
	public class cls_calculatedVariables {
		public String entityId;	//
		public String entityType;	//
		public String fieldName;	//
		public String fieldType;	//
		public String fieldValue;	//
		public String productCode;	//
		public String purpose;	//
	}
	public class cls_errorResponse {
		public String errorAction;	//
		public String errorCode;	//
		public String errorId;	//
		public String errorName;	//
		public String errorText;	//
		public String errorType;	//
	}
	public class cls_responseDeviations {
		public String accountNo;	//
		public String approvalLevel;	//
		public String deviationType;	//
		public String entityId;	//
		public String entityType;	//
		public String reasonText;	//
		public String recommendationText;	//
		public String ruleAction;	//
		public String ruleCategory;	//
		public String ruleDescription;	//
		public String ruleId;	//
		public String ruleLevel;	//
		public String ruleName;	//
	
}
public class cls_finalOffer {
		public Decimal ROINTR;	//0
		public Decimal MAXLTV;	//100
		public Decimal MAXLOELIGLTV;	//35000000
		public Decimal MAXLOELIGINC;	//0
		public Decimal LOANTENU;	//240
		public Decimal LOANAMTOFFR;	//0
		public Decimal FINALLTV;	//0
		public Decimal FINALFOIR;	//0
		public Decimal EMIFINOFF;	//0
		public String additionalLtv;	//
		public Decimal MAXLOEELIGINC;	//35000000
}


	public class cls_request {
        public cls_application application;
    }

    public class cls_application {
        
        public cls_applicationAdditionalDetails applicationAdditionalDetails;
        
    }
	 public class cls_applicationAdditionalDetails {
       
        public cls_other other;
        
    }

   

   
    public class cls_other {
        public String psl;	//#TurnoverasperFinancialsCur
        public String pep;	//#GrossProfitCur
        public String borrowerType;	//#PATCur
        public String lendingType;	//#DepreciationCur
        public String propertyIdentified;	//#SalaryPaidtoPartnerCur
        public String riskCategorization;	//#InterestPaidtoPartnerCur
        public String cinNo;	//#DirectorsRenumerationCur
        public Integer finalFoirPercentage;	//#NonOperatingExpenseCur
        public Integer finalLtvPercentage;	//#OtherIncomeCur
        public Integer finalLoanAmount;	//#OtherExpenseCur
        public String eligibilityMethod;	//#NonOperatingIncomeCur
        public String sblMet;	//#TurnoverasperGSTCur
        public String gblMet;	//#SumofBusinessCreditfor12months
        public String stageOfConstruction;	//#MonthlyAverageBankBalancefor12months
        public Boolean creExposure;	//#TotalMonthlyObligationforBankingSurrogateMethod
        public String rentalIncomeProgram;	//#FinalLoanAmount
        //public String endusageoffunds;	//#EligibilityMethod
        public String buffer1;
        public String buffer2;	//#RequestedLoanAmount
        public String buffer3;
        public String buffer4;	//#TurnoverasperFinancialsprev
        public String buffer5;	//#GrossProfitprev
        public String buffer6;	//#PATprev
        public String buffer7;	//#Depreciationprev
        public String buffer8;	//#SalaryPaidtoPartnerprev
        public String buffer9;	//#InterestPaidtoPartnerprev
        public String buffer10;	//#DirectorsRenumerationprev
        public String buffer11;
        public String buffer12;	//#NonOperatingExpenseprev
        public String buffer13;	//#OtherIncomeprev
        public String buffer14;	//#OtherExpenseprev
        public String buffer15;	//#TotalMonthlyObligationforIncomeandGSTMethod
        public String buffer16;	//#TotalAnnualObligation
        public String buffer17;	//#GreatestIndividualcontributionper
        public String buffer18;	//#ITRFillingDateprev
        public String buffer19;	//#TypeofFinancialsCur
        public String buffer20;	//#TypeofFinancialsprev
        public String buffer21;	//#ITRFillingDateCur
        public String buffer22;
        public String buffer23;	//#TotalincomeCur
        public String buffer24;	//#Totalincomeprev
        public String buffer25;	//#NonOperatingIncomeprev
    }


    

}