public  class LoanSchedulerQueuueable implements Queueable, Database.AllowsCallouts{

    Map<String, String> apiInputMap;
    List<Opportunity> oppList;

    public LoanSchedulerQueuueable(Map<String, String> apiInputMap, List<Opportunity> oppList) {
        this.apiInputMap = apiInputMap;
        this.oppList= oppList;

    }

    public void execute(QueueableContext context) {

        String resp = COMM_LoanSchedulerContoller.initiateAPIRequestForMultiProd(apiInputMap, oppList, 'Charges API Invocation');

    }
}