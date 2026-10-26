import { LightningElement,track,api } from 'lwc';
import NOT_ELIGIBLE_ICON from '@salesforce/resourceUrl/RejectIconEligibility';
import getScreenFieldData from '@salesforce/apex/COMM_SalesIncomeEligibilityController.getScreenFieldData';
//import initiateAPIRequest from '@salesforce/apex/EligibilityApiController.initiateAPIRequest';
export default class SalesLoginEligibilityCmp extends LightningElement {
    @api loanid;
    @track screenName = 'Income Eligibility Screen';
    @track tableData = [];
    @api applicantDetailId;
    @track isDetailsVisible = false;
    @track showInEligibility = false;
    notEligibleIcon;
    @track spinner = false;

    connectedCallback(){
        this.notEligibleIcon = NOT_ELIGIBLE_ICON;
       
        this.callEligibility();
    }
    callEligibility(){
        this.spinner = true;
        const inputMap = {
            'loanId': this.loanid,
            'isIncomeFromSales':'true',
            'processName':'Credit Eligibility',
            'adb':'',
            'eligibilityType':'BANKINGSURROGATE'
        }
       /* initiateAPIRequest({
            inputMap:inputMap
        })
        .then(result => {
            this.spinner = false;
            console.log('result0-----',JSON.stringify(result));
             this.loadScreenFields();
        })
        .catch(error => {
            this.spinner = false;
        })*/
    }
    loadScreenFields() {
        this.spinner = true;
        getScreenFieldData({ screenName: this.screenName, loanId:this.loanid })
            .then((result) => {
                this.spinner = false;
                if(result != undefined && result != null && result.length != 0){
                    this.tableData = result;
                    console.log('this.tableData -->'+JSON.stringify(this.tableData));
                    this.isDetailsVisible = true;
                }
                else{
                    this.showInEligibility = true;
                }
            })
            .catch((error) => {
                this.spinner = false;
                console.error('Error fetching screen fields:', error);
            });
    }
}