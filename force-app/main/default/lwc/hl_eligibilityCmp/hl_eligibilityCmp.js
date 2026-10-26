import { LightningElement, api, track, wire } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getApplicants from "@salesforce/apex/Hl_EligibilityController.getApplicants";

import { NavigationMixin } from 'lightning/navigation';

export default class Hl_EligibilityCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    //@api isDisabled = false;
    @track hasData = false;
    @track appdata = [];
    //@api enableDisabled = false;

    _isDisabled = false;
    _enableDisabled = false;

    @api
    set isDisabled(v) { this._isDisabled = v === true || v === 'true'; }
    get isDisabled() { return this._isDisabled; }

    @api
    set enableDisabled(v) { this._enableDisabled = v === true || v === 'true'; }
    get enableDisabled() { return this._enableDisabled; }

    get disabledAll() {
      return this.isDisabled || this.enableDisabled;
    }

    connectedCallback() {
        this.getAppDetails();
    }

    getAppDetails() {
       getApplicants({
      recordId: this.recordId,
    })
      .then((response) => {

        this.appdata = response;
        if (this.appdata.length > 0) {
          this.hasData = true;
        }
      })
      .catch((error) => {
        console.log("error in getEmployeeCheckData---", error);
      });
    }

//this.showToast("Error", "Please check applicant name", "error");
    showToast(title, message, variant) {
    const toastEvent = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
    });
    this.dispatchEvent(toastEvent);
  }

  handleChange(event) {
    const seletedVal = event.target.value;
    const requestId = event.target.dataset.id;
    console.log('seletedVal ',seletedVal ,' requestId ',requestId);

    const fields = {};
        fields['Id'] = requestId;
        fields['Income_Method__c']=seletedVal;
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
        .then(() => {
            this.showToast("Success", "Updated successfully'", "success");
             this.getAppDetails();
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
  }
}