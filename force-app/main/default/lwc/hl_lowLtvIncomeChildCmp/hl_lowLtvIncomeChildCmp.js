import { LightningElement,api } from 'lwc';
import getScreenData from '@salesforce/apex/HL_LowLtvIncomeController.getScreenData';
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class Hl_lowLtvIncomeChildCmp extends LightningElement {;

@api loanId;
@api applicantId;
bankingData=[];
averageBankBalance;
fieldAPIName;
recordIdToUpdate;
loadTable = false;

connectedCallback() {
console.log('recordId: ' + this.loanId);
this.getScreenData();

}
getScreenData(){
getScreenData({
    loanId: this.loanId,
    apDetId: this.applicantId
}).then(response=>{
    console.log('response: ' + JSON.stringify(response));
    this.bankingData =[...response];
    // this.averageBankBalance  = response.avgBankBalance;
    // this.recordIdToUpdate =response.incomerecordId;
    // this.fieldAPIName =response.fieldAPIName;
    this.loadTable = true;
})
}

// handleBankBalanceChange(event){
//     var enteredVal = 0;
//     if(event.target.value != null && event.target.value != undefined && event.target.value != ''){
//         if ((isNaN(Number(event.target.value)))){
//             this.showToast('Error', 'Please enter valid number!', 'error');
//             return;
//         }
//         else{
//             enteredVal = Number(event.target.value);
//         }
//     }
//     const fields = {};
//     fields['Id'] = this.recordIdToUpdate;
//     fields[event.target.dataset.name] = enteredVal;
//     const recordInput = { fields };

//     updateRecord(recordInput)
//     .then(() => {
//         this.showToast('Success', 'Data saved', 'success');
//     }).catch(error=>{

//     })
// }

handleBankBalanceChange(event) {
const enteredVal = event.target.value ? Number(event.target.value) : 0;

if (isNaN(enteredVal)) {
    this.showToast('Error', 'Please enter a valid number!', 'error');
    return;
}

const recordId = event.target.dataset.recordid;
const fieldAPI = event.target.dataset.name;

const fields = {};
fields['Id'] = recordId;
fields[fieldAPI] = enteredVal;

const recordInput = { fields };

updateRecord(recordInput)
    .then(() => {
        this.showToast('Success', 'Data saved successfully', 'success');
    })
    .catch(error => {
        console.error('Error saving data', error);
        this.showToast('Error', 'Failed to save data', 'error');
    });
}

showToast(title, message, variant) {
this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
}



}