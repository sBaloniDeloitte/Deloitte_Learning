public without sharing class CreateFinanceResponseWrapper{
	public String finReference;	//GHF1001HL0005309
	public FinanceSchedule financeSchedule;
	public Disbursement[] disbursement;
	public ReturnStatus returnStatus;
	public class FinanceSchedule {
		public Summary summary;
	}
	public class Summary {
		public Double effectiveRateOfReturn;	//7.026288585
	}
	public class Disbursement {
		public String remarks; // "",
		public Integer paymentId; // 6166,
	}
	public class ReturnStatus {
		public String returnCode;	//0000
		public String returnText;	//Success
	}
	public static CreateFinanceResponseWrapper parse(String json){
		return (CreateFinanceResponseWrapper) System.JSON.deserialize(json, CreateFinanceResponseWrapper.class);
	}
}