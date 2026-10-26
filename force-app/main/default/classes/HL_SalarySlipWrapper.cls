public class HL_SalarySlipWrapper {
    @AuraEnabled
    public Integer intMonthsCount {
        get {
            if(this.lstMonthLabels != null && !this.lstMonthLabels.isEmpty()) {
                return this.lstMonthLabels.size();
            }
            return 0;
        }
        set;
    }

    @AuraEnabled
    public Integer intMonthsColSpanCount {
        get {
            if(this.intMonthsCount != null) {
                if(this.intMonthsCount == 0) {
                    return (this.intMonthsCount + 1);
                } else {
                    return this.intMonthsCount;
                }
            }
            return 1;
        }
    }

    @AuraEnabled
    public List<SalarySlipComponentWrapper> lstEarningsWrapper {get; set;}
    @AuraEnabled  
    public List<SalarySlipComponentWrapper> lstDeductionsWrapper {get; set;}

    @AuraEnabled  
    public List<String> lstMonthLabels {
        get {
            Set<String> setMonthLabel = new Set<String>();
            
            if(this.lstEarningsWrapper != null && !this.lstEarningsWrapper.isEmpty()) {
                for(SalarySlipComponentWrapper objComp : lstEarningsWrapper) {
                    if(objComp.lstAmtWrapper != null){
                        for(MonthlyValueWrapper objMonthWrapper : objComp.lstAmtWrapper) {
                            setMonthLabel.add(objMonthWrapper.strMonthLabel);
                        }
                    }
                }
            }
            if(this.lstDeductionsWrapper != null && !this.lstDeductionsWrapper.isEmpty()) {
                for(SalarySlipComponentWrapper objComp : lstDeductionsWrapper) {
                    if(objComp.lstAmtWrapper != null){
                        for(MonthlyValueWrapper objMonthWrapper : objComp.lstAmtWrapper) {
                            setMonthLabel.add(objMonthWrapper.strMonthLabel);
                        }
                    }
                }
            }
            return new List<String>(setMonthLabel);
        }
        set;
    }

    @AuraEnabled public List<Decimal> lstTotalAmount {
        get {
            List<Decimal> setGrossLabel = new List<Decimal>();
            
            if(this.lstEarningsWrapper != null && !this.lstEarningsWrapper.isEmpty()) {
                Map<String, List<Decimal>> allMonthlyData = new Map<String, List<Decimal>>();

                for(SalarySlipComponentWrapper objComp : lstEarningsWrapper) {
                    if(objComp.lstAmtWrapper != null){
                        for(MonthlyValueWrapper objMonthWrapper : objComp.lstAmtWrapper) {
                            List<Decimal> tempMonthData = new List<Decimal>();
                            if(allMonthlyData.containsKey(objMonthWrapper.strMonthLabel)){
                                tempMonthData = allMonthlyData.get(objMonthWrapper.strMonthLabel);
                            }
                            tempMonthData.add(objMonthWrapper.strMonthValue);
                            allMonthlyData.put(objMonthWrapper.strMonthLabel, tempMonthData);
                        }
                    }
                }

                for(String monthLabel : allMonthlyData.keySet()){
                    List<Decimal> tempData = allMonthlyData.get(monthLabel);
                    Decimal tempMonthData = 0;
                    for(Decimal iterData : tempData){
                        tempMonthData += iterData;
                    }
                    setGrossLabel.add(tempMonthData);
                }
            }

            return setGrossLabel;
        }
        set;
    }

    @AuraEnabled public List<Decimal> lstTotalAmountLess {
        get {
            List<Decimal> setGrossLabel = new List<Decimal>();
            
            if(this.lstDeductionsWrapper != null && !this.lstDeductionsWrapper.isEmpty()) {
                Map<String, List<Decimal>> allMonthlyData = new Map<String, List<Decimal>>();

                for(SalarySlipComponentWrapper objComp : lstDeductionsWrapper) {
                    if(objComp.lstAmtWrapper != null){
                        for(MonthlyValueWrapper objMonthWrapper : objComp.lstAmtWrapper) {
                            List<Decimal> tempMonthData = new List<Decimal>();
                            if(allMonthlyData.containsKey(objMonthWrapper.strMonthLabel)){
                                tempMonthData = allMonthlyData.get(objMonthWrapper.strMonthLabel);
                            }
                            tempMonthData.add(objMonthWrapper.strMonthValue);
                            allMonthlyData.put(objMonthWrapper.strMonthLabel, tempMonthData);
                        }
                    }
                }

                for(String monthLabel : allMonthlyData.keySet()){
                    List<Decimal> tempData = allMonthlyData.get(monthLabel);
                    Decimal tempMonthData = 0;
                    for(Decimal iterData : tempData){
                        tempMonthData += iterData;
                    }
                    setGrossLabel.add(tempMonthData);
                }
            }

            return setGrossLabel;
        }
        set;
    }

    @AuraEnabled public List<Decimal> netSalary {
        get {
            List<Decimal> setSalary = new List<Decimal>();
            if(this.lstTotalAmount.size() == this.lstTotalAmountLess.size()){
                for(Integer i = 0; i < this.lstTotalAmount.size(); i++){
                    setSalary.add(this.lstTotalAmount[i] - this.lstTotalAmountLess[i]);
                }
            }
            else {
                setSalary.addAll(this.lstTotalAmount);
            }
            return setSalary;
        }
        set;
    }

    @AuraEnabled public String recordTypeChild {get; set;}
    @AuraEnabled public String recordTypeParent {get; set;}
    @AuraEnabled public String remarks {get; set;}

    public class SalarySlipComponentWrapper {
        @AuraEnabled public String recordId {get; set;}
        @AuraEnabled public String strNatureOfComponent {get; set;}
        @AuraEnabled public String strParticulars {get; set;}
        @AuraEnabled public List<MonthlyValueWrapper> lstAmtWrapper {get; set;}
        @AuraEnabled public Decimal strAverage {get; set;}
        @AuraEnabled public Boolean editRecord {get; set;}
    }
    
    public class MonthlyValueWrapper {
        @AuraEnabled public String recordId {get; set;}
        @AuraEnabled public String strMonthLabel {get; set;}
        @AuraEnabled public Decimal strMonthValue {get; set;}
    }
}