import { LightningElement, track, api } from "lwc";

import getLiveLoanData from "@salesforce/apex/BsaSelectBankController.getAllBankRecords";
import LightningConfirm from "lightning/confirm";
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import getAccountTypePicklistValues from "@salesforce/apex/BsaSelectBankController.getAccountTypePicklistValues";
import selectDefault from "@salesforce/apex/BsaSelectBankController.selectDefault";
import bankValidation from '@salesforce/label/c.Bank_Name_Validation';
import accountHolderNameValidation from '@salesforce/label/c.Account_Holder_Name_Validation';
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class BsaSelectBankCmp extends LightningElement {
  @api recordId;
  isBankValidation = bankValidation;
  isAccountHolderNamerValidation = accountHolderNameValidation;
  @track perfiosTableEditable = false;
  @track accOptions = [];
  @track spinner = true;
  @track showAnalysisButton = false;
  @track selectedbanks = [];
  @track showAddMoreAcc = false;
  @track banksData = [];
  @track isRendered = false;
  @track showStatements=false;
  @api fromSales= false;
  @api hasLoanStagePsvOrDisbursement = false;

  connectedCallback() {
    this.getAccountTypePickListVal();
    setTimeout(() => {
      //alert(this.recordId);
      this.spinner = false;
    }, 1000);
    //this.getBanks();
    this.profileAndStageCheck();
  }

  handleChildChange(event) {
    let tenmp = event.target.dataset.id;
    
    if (event.target.checked) {
        if (tenmp != undefined && !this.selectedbanks.includes(tenmp)) {
            this.selectedbanks.push(tenmp);
        }
    } else {
      
        console.log("temp=:" + tenmp);
        const index = this.selectedbanks.indexOf(tenmp);
        if (index > -1) { 
           this. selectedbanks.splice(index, 1);
        }
    }
    console.log("selectedbanks=:" + this.selectedbanks);
    if (this.selectedbanks.length > 0) {
      this.showAnalysisButton = true;
    }
  }
  handleAnalysisClick() {

    this.dispatchEvent(new CustomEvent('handleanalysisclick', {detail:{'bankIds':this.selectedbanks}}));
  }
  handleAddMoreClick() {
    this.showAddMoreAcc = true;
  }
  hideModalBox() {  
    this.showAddMoreAcc = false;
  }

  profileAndStageCheck() {
      getLoanStage ({loanId : this.recordId})
      .then((result) =>{
        console.log('getLoanStage -- result : '+result);
        if (result && (result === 'Credit Underwriting'|| result === 'PSV')) {
          if(result=='PSV'){
            this.hasLoanStagePsvOrDisbursement = true;
          }
            getCurrentUserProfileName()
            .then((res) =>{
                console.log('getCurrentUserProfileName -- res : '+res);
                if (res && (res === 'Credit Manager' || res === 'Credit Officer') ) {
                    console.log('getCurrentUserProfileName -- Inside If');
                    this.perfiosTableEditable = true;
                } else {
                    console.log('getCurrentUserProfileName -- Inside else');
                    this.perfiosTableEditable = false;
                }
                // this.perfiosTableEditable = (res === 'Credit Manager');
            }).catch ((err) => {
                console.error('getCurrentUserProfileName error '+ err);
                this.perfiosTableEditable = false;
            })
        } else {
            this.perfiosTableEditable = false;
        }   
        setTimeout(() => {
          this.getBanks();
        }, 100);
    }).catch ((error) => {
        console.error('getLoanStage error '+ error);
        this.perfiosTableEditable = false;
    }) 
  }

  getAccountTypePickListVal() {
    getAccountTypePicklistValues()
        .then((result) => {
            this.accOptions = result.map(val => ({
                label: val,
                value: val
            }));
        })
        .catch((error) => {
            this.error = error;
            console.error('Error fetching picklist values', error);
        });
  }

  changeBankName(event) {
    const inputVal = event.target.value;
    const bankId = event.target.dataset.id;
    console.log('inputVal ',inputVal);
    console.log('bankId ',bankId);
    const regex = /^[a-zA-Z0-9 ._]+$/;
    console.log('isBankValidation ',this.isBankValidation);
    if (!regex.test(inputVal) && this.isBankValidation=='true') {
      this.showToastMessage('Invalid Input', 'Bank name cannot contain special characters except "."" or "_".', 'error');
      //event.target.value = '';
    } else {
      const fields = {};
           fields['Id'] = bankId;
           fields['Name']=inputVal;
           const recordInput = { fields };
           console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
           updateRecord(recordInput)
           .then(() => {
               this.showToastMessage('Success', 'Record updated successfully', 'success');
           })
           .catch(error => {
               console.log('Error updating record --> '+JSON.stringify(error));
           });
    }
  }

  handleChange(event){
    let value = event.detail.value;
    let fieldName = event.target.name;
    const bankId =  event.target.dataset.id;
    console.log('bankId', bankId);
    console.log('index', JSON.stringify(event.detail));
    const fields = {};
    fields['Id'] = bankId;
    fields['Account_Type__c']=value;
    const recordInput = { fields };
    console.log(`The Update Record : ${JSON.stringify(recordInput)}`);
    updateRecord(recordInput)
    .then(() => {
      this.dispatchEvent(new CustomEvent('handlerefresh', {}));
      this.getBanks();
      this.showToastMessage('Success', 'Record updated successfully', 'success');
    })
    .catch(error => {
        console.log('Error updating record --> '+JSON.stringify(error));
    });
  }

  handleAccountNumberChange(event) {
      const inputField = event.target;
      const recordId = inputField.dataset.id;
      const newValue = inputField.value;

      // Validate immediately
      this.validateAccountNumber(inputField, newValue);

      // Update only local variable — no save
      this.banksData = this.banksData.map(record => {
          return record.Id === recordId
              ? { ...record, Account_Number__c: newValue }
              : record;
      });
  }

  handleAccountNumberBlur(event) {
      const inputField = event.target;
      const recordId = inputField.dataset.id;
      const newValue = inputField.value;

      // Validate again
      if (!this.validateAccountNumber(inputField, newValue)) {
          return; // ❌ Invalid → do not save
      }

      // ✔ Valid → save via LDS
      const recordInput = {
          fields: {
              Id: recordId,
              Account_Number__c: newValue
          }
      };

      updateRecord(recordInput)
          .then(() => {
              console.log("Account number updated successfully");
          })
          .catch(error => {
              console.error("Error updating record:", error);
          });
  }

  validateAccountNumber(inputField, value) {
      const invalidRegex = /[^0-9]|x/i; // special chars OR X

      if (invalidRegex.test(value)) {
          inputField.setCustomValidity(
              "Invalid format, special characters not allowed."
          );
          inputField.reportValidity();
          return false;
      }
      inputField.setCustomValidity("");
      inputField.reportValidity();
      return true;
  }
  changeAccHolder(event) {
    const inputVal = event.target.value;
    const regex = /^[a-zA-Z0-9 ._]+$/;

    if (!regex.test(inputVal) && this.isAccountHolderNamerValidation == 'true') {
      this.showToastMessage('Invalid Input', 'Account holder name cannot contain special characters except "."" or "_".', 'error');
      //event.target.value = '';
    } else {
      this.changeAcc = inputVal;
    }
  }

  validateInput(event) {
    try {
        const inputVal = event.target.value?.trim() || '';
        const bankId = event.target.dataset.id;

        console.log('inputVal:', inputVal);
        console.log('Record Id:', bankId);

        if (!bankId) {
            console.error('Missing recordId from dataset.');
            return;
        }

        const regex = /^[a-zA-Z0-9 ._]+$/;
        if (!regex.test(inputVal) && this.isAccountHolderNamerValidation == 'true') {
          event.target.setCustomValidity('Account holder name cannot contain special characters except "."" or "_".');
        } else {
          event.target.setCustomValidity('');
          const fields = {
              Id: bankId,
              Account_Holder_Name__c: inputVal
          };
          const recordInput = { fields };
          updateRecord(recordInput)
          .then(() => {
              this.getBanks();
              this.showToastMessage('Success', 'Record updated successfully', 'success');
          })
          .catch(error => {
              console.error('Error updating record:', error);
              this.showToastMessage('Error', 'Failed to update record', 'error');
          });
        }
        event.target.reportValidity();
      } catch (err) {
          console.error('Unexpected error in validateInput:', err);
      }
  }

  getBanks() {
    getLiveLoanData({
      recordId: this.recordId,
    })
      .then((response) => {
        console.log("response customer details=:" + JSON.stringify(response));
        this.banksData = response;
        
        if(this.banksData!= null && this.banksData.length>0){
          this.showStatements=true;
        }
        for(let key in response){
            console.log("loop " + response[key].Is_Consider_for_Eligibility__c);
            if(response[key].Is_Consider_for_Eligibility__c) {
                this.selectedbanks.push(response[key].Id);
                this.showAnalysisButton = true;
            }
            
        }
        const eligibleAccounts = this.banksData.filter(
          record => record.Is_Consider_for_Eligibility__c === true
        );
        this.eligibleCount = eligibleAccounts.length;

        const disableOthers = this.eligibleCount >= 3;

        this.banksData = this.banksData.map(record => {
          return {
            ...record,
            disableEligibilityCheckbox: disableOthers && !record.Is_Consider_for_Eligibility__c
          };
        });
        this.spinner = false;
      })
      .catch((error) => {});
  }
  @track selectedbankId = '';
  @track selectefieldName = '';
  @track selectefieldValue = false;

  handleChildExistingChange(event) {
    this.selectedbankId = event.target.dataset.id;
    this.selectefieldName = event.target.name;
      //this.recordData 
      if(event.target.checked){
        this.selectefieldValue = true;
        this.handleConfirmClick();

      }else{
        this.selectefieldValue = false;
        this.handleConfirmClick();
      }
  }
  async handleConfirmClick() {
    const result = await LightningConfirm.open({
        message: "Are you sure you want to change this.",
        label: "Confirmation Screen",
        className: "custom-confirm-header" 
    });

    //Confirm has been closed

    //result is true if OK was clicked
    if (result) {
      this.spinner = true;
      selectDefault({
        recordId: this.recordId,
        bankId:this.selectedbankId,
        fieldName:this.selectefieldName,
        fieldValue:this.selectefieldValue
      })
        .then((response) => {
          console.log("response customer details=:" + JSON.stringify(response));
          setTimeout(() => {
            this.getBanks();
            this.showToastMessage('Success', 'Data updated successfully!', 'success');
            this.spinner = false;
          }, 200);
          // this.showToastMessage('Success', 'Data updated successfully!', 'success');
          // this.spinner = false;
        })
        .catch((error) => {});
    } else {
      this.spinner = true;
      this.banksData = [];
      this.selectedbankId = '';
      this.selectefieldName = '';
      this.selectefieldValue = false;
      setTimeout(() => {
        this.getBanks();
      }, 200);
      
    }
}
renderedCallback() {
  if (!this.isRendered) {
    // Create and append styles dynamically
    const style = document.createElement("style");
    style.innerText = `
    .custom-confirm-header .slds-modal__header {
      background: #1467eb !important;
    }

    .slds-modal_prompt .slds-modal__container .slds-modal__footer .slds-button_neutral{
      width: 90px;
      background-color: #db2929;
      font-weight: 500;
      border: none;
      padding: 1px 0px;
      color: #ffffff;
  }
  .slds-modal_prompt .slds-modal__container .slds-modal__footer .slds-button_brand{
      width: 90px;
      background-color: #1467eb;
      font-weight: 500;
      border: none;
      padding: 1px 0px;
      color: #ffffff;
  }
      .slds-modal_prompt .slds-modal__container .slds-modal__footer{
      background: #1467eb;
      }
      .slds-modal_prompt .slds-modal__container .slds-modal__header{
      background: #1467eb;
      }
  .slds-modal_prompt .slds-modal__container .slds-modal__content{
    background-color: #0e1c30;
    color: #ffffff;
  }
  .slds-modal_prompt .slds-modal__container .slds-modal__content p{
    text-align: center;
    color: #ffffff;
  }
  .slds-accordion {
    background-color: #0a1524;
  }
  .slds-accordion__list-item {
    background-color: #0e1c30 !important;
    margin-bottom: 10px;
    border-radius: 10px;
    overflow: hidden;
    border: 1px solid #33455e;
  }
  .slds-accordion__summary {
    padding: 10px 0px 10px 0px;
  }
  .slds-accordion__summary-action {
    background: linear-gradient(135deg, #001a5e 0%, #003087 55%, #004db3 100%) !important;
    border-radius: 10px !important;
    padding: 14px 16px !important;
    margin: 0px;
    font-weight: 500;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.35);
  }
  .slds-accordion__summary-action,
  .slds-accordion__summary-action * {
    color: #ffffff !important;
  }
  .slds-accordion__summary-action-icon,
  .slds-accordion__summary-action-icon svg {
    fill: #ffffff !important;
    color: #ffffff !important;
  }
  .slds-accordion__section {
    background-color: #0e1c30 !important;
    border-color: #33455e !important;
    color: #ffffff !important;
  }
      `;

    // Append the styles to the .styleContainer
    this.template.querySelector(".styleContainer")?.appendChild(style);

    // Prevent re-adding styles
    this.isRendered = true;
  }
}
  showToastMessage(title, message, type) {
    const toastEvent = new ShowToastEvent({
        title: title,
        message: message,
        variant: type
    });
    this.dispatchEvent(toastEvent);
  }

  addedBank(event){
    console.log('Inside add bank account---');
    console.log(event.detail);
    this.getBanks();
    
  }
  
  handleSelectDocument(event) {
    const selectedRecord = event.detail.record;
    console.log('Selected Bank Branch:', selectedRecord);
    const branchId = selectedRecord.Id;
    const ifscCode = selectedRecord.IFSC__c;
    let micr = '';
    if (selectedRecord?.MICR__c && selectedRecord.MICR__c !== 'NA') {
        micr = selectedRecord.MICR__c;
    }
    console.log('Branch ID:', branchId);
    console.log('IFSC Code:', ifscCode);
    
    this.selectedBranchId = branchId;
    this.selectedIfsc = ifscCode;
    const bankId = event.detail.bankid;
    for(var i=0;i<this.banksData.length;i++){
      if(this.banksData[i].Id == bankId){
        if (!this.banksData[i].Bank_Master__r) {
          this.banksData[i].Bank_Master__r = {}; 
        }
        if(micr != '' && micr != null && micr != undefined) {
          this.banksData[i].Bank_Master__c = this.selectedIfsc;
         this.banksData[i].Bank_Master__r.MICR__c = micr;
        }
      }
    }
  }

}