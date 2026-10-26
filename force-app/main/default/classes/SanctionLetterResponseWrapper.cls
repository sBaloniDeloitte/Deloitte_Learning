public class SanctionLetterResponseWrapper {
    public String message;
    public Response response;

    public class Response {
        public String exceptionMessage;
        public String batchNo;
        public Integer sequenceNo;
        public String base64StringForPDF;
        public String message;
        public String base64StringForAppForm;
        public Boolean status;
    }
}