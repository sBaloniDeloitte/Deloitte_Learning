import { LightningElement,api,track } from 'lwc';
import getIncomeTableData from '@salesforce/apex/IncomeEligibilityCalculatorController.getIncomeTableData';
export default class IncomeEligibilityCalculator extends LightningElement {
    @api recordId;
    @track tableInfo;
    @api tableName;
    @track showTable = false;

    connectedCallback() {
        this.getTableData();
    }
    getTableData(){
        getIncomeTableData({
            loanId: this.recordId,
            tableName: this.tableName
        }).then(resp=>{
            this.showTable = true;
            this.tableInfo = resp;
        }).catch(error=>{

        })
    }
}