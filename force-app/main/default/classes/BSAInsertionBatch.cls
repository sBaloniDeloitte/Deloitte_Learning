public class BSAInsertionBatch implements Database.Batchable<SObject> {
    private List<SObject> recordsToProcess;
    public BSAInsertionBatch(List<SObject> records) {
        this.recordsToProcess = records;
    }
    public Iterable<SObject> start(Database.BatchableContext context) {
        return recordsToProcess;
    }
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        try {
            insert scope;
        } catch (DmlException e) {
            System.debug('Error inserting records: ' + e.getMessage());
        }
    }
    public void finish(Database.BatchableContext context) {
        System.debug('Batch process complete. Total records processed: ' + recordsToProcess.size());
    }
}