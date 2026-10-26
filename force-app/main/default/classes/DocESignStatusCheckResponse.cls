public with sharing class DocESignStatusCheckResponse {
    public boolean status;
    public Data data;
    public String message;	//Success
    public String statusCode;	//200 OK
    public string traceId;

    public class Data {
        public String status;	//Completed
        public List<signerDetailsList> signerDetailsList;
    }

    public class signerDetailsList {
        public String signerDetails;	//Rani Jah
        public String emailorPhonenumber;	//9325139789
        public String signedStatus;	//signed
        public string sigendlink;
    }
}