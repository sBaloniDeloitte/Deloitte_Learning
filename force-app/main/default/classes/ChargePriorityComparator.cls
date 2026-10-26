public class ChargePriorityComparator implements System.Comparator<Charges_Insurance__c> {
    public Integer compare(Charges_Insurance__c c1, Charges_Insurance__c c2) {
        // Priority mapping
        Map<String, Integer> priorityMap = new Map<String, Integer>{
            'PROCFEE' => 1,
            'ADMINFEE' => 2,
            'STFRCHG' => 3
        };

        Integer p1 = priorityMap.containsKey(c1.Name) ? priorityMap.get(c1.Name) : 999;
        Integer p2 = priorityMap.containsKey(c2.Name) ? priorityMap.get(c2.Name) : 999;

        if (p1 == p2) return 0;
        return p1 < p2 ? -1 : 1;
    }

}