import { LightningElement, api,track, wire } from 'lwc';

import fetchApplicantsByProfile from '@salesforce/apex/AHL_ApplicantListController.fetchApplicantsByProfile';
import getSalariedApplicants    from '@salesforce/apex/AHL_ApplicantListController.getSalariedApplicants';
import getSepSenpApplicants     from '@salesforce/apex/AHL_ApplicantListController.getSepSenpApplicants';
import getSelfEmployedApplicants from '@salesforce/apex/AHL_ApplicantListController.getSelfEmployedApplicants';
import getAssests from '@salesforce/apex/AHL_ApplicantListController.getAssests';
import getPDs from '@salesforce/apex/AHL_ApplicantListController.getPDs';
import getApplicants from '@salesforce/apex/AHL_ApplicantListController.getApplicants';
import getApplicantsPEP from '@salesforce/apex/AHL_ApplicantListController.getApplicantsPEP';

import { ShowToastEvent } from "lightning/platformShowToastEvent";



import { updateRecord } from 'lightning/uiRecordApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import RISK_FIELD from "@salesforce/schema/Opportunity.Risk_Category__c";
import APPROVAL_STATUS_FIELD from '@salesforce/schema/Opportunity.Approval_Status__c';
import INCOME_APPROVAL_STATUS_FIELD from '@salesforce/schema/Opportunity.Income_Approval_Status__c';

const FIELDS = [RISK_FIELD, APPROVAL_STATUS_FIELD,INCOME_APPROVAL_STATUS_FIELD];

export default class CreditAssessmentCmp extends LightningElement {
    @api recordId; // Opportunity Id passed from the record page
    @track assestsLst=[];
    @track isAssestpresent = false;
@track hasData = false;
    @track appdata = [];
@track hasDataPEP = false;
    @track appdataPEP = [];
    

    @track pdLst=[];
    @track isPdpresent = false;

    @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  loan;

  get selectedValue() {
    return getFieldValue(this.loan.data, RISK_FIELD);
  }
  get approvalStatus() {
    return getFieldValue(this.loan?.data, APPROVAL_STATUS_FIELD);
  }
  get incomeApprovalStatus() {
    return getFieldValue(this.loan?.data, INCOME_APPROVAL_STATUS_FIELD);
  }

  get disableInputs() {
    const blockedMain = new Set([
      'Hard Rejected',
      'Soft Rejected 1',
      'Soft Rejected 2',
      'Submitted',
      'Rejected'
    ]);
    const status = this.approvalStatus;
    const incomeStatus = this.incomeApprovalStatus;
    const mainBlocked = status ? blockedMain.has(status) : false;
    const incomeBlocked = incomeStatus === 'Submitted';

    return mainBlocked || incomeBlocked;
  }
  get isDisabledLoanApproval() {
  const blocked = new Set([
    'Hard Rejected',
    'Soft Rejected 1',
    'Soft Rejected 2',
    'Submitted',
    'Rejected'
  ]);
  const status = this.approvalStatus;
  return status ? blocked.has(status) : false;
}

    
    options = [
        { label: 'High', value: 'High' },
        { label: 'Medium', value: 'Medium' },
        { label: 'Low', value: 'Low' },
    ];

    optionsPEP = [
        { label: 'YES', value: 'YES' },
        { label: 'NO', value: 'NO' },
    ];

    handleChange(event) {
    const seletedVal = event.target.value;
    const requestId = event.target.dataset.id;
    console.log('seletedVal ',seletedVal ,' requestId ',requestId);

    const fields = {};
        fields['Id'] = requestId;
        fields['KYC_Risk_Categorisation_Category__c']=seletedVal;
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
        .then(() => {
            this.showToast("Success", "Updated successfully'", "success");
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
  }
  handleChangePEP(event) {
    const seletedVal = event.target.value;
    const requestId = event.target.dataset.id;
    console.log('seletedVal ',seletedVal ,' requestId ',requestId);

    const fields = {};
        fields['Id'] = requestId;
        fields['PEP__c']=seletedVal;
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
        .then(() => {
            this.showToast("Success", "Updated successfully'", "success");
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
  }

   showToast(title, message, variant) {
      const toastEvent = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
      });
      this.dispatchEvent(toastEvent);
    }
  

    showSalariedDetails = false;
    showSelfEmpDetails = false;
    showSalariedIncome = false;
    showSelfEmpIncome = false;
    @track isRendered = false;

    @wire(fetchApplicantsByProfile, { loanAppId: '$recordId' })
    wiredSalariedDetails({ data, error }) {
        console.log('data',data);
        this.showSalariedDetails = Array.isArray(data) && data.length > 0;
    }

    @wire(getSepSenpApplicants, { loanApplicationId: '$recordId' })
    wiredSelfEmpDetails({ data, error }) {
        console.log('showSelfEmpDetails',data);
        this.showSelfEmpDetails = Array.isArray(data) && data.length > 0;
    }

    @wire(getSalariedApplicants, { loanAppId: '$recordId' })
    wiredSalariedIncome({ data, error }) {
        this.showSalariedIncome = Array.isArray(data) && data.length > 0;
    }

    @wire(getSelfEmployedApplicants, { loanAppId: '$recordId' })
    wiredSelfEmpIncome({ data, error }) {
        this.showSelfEmpIncome = Array.isArray(data) && data.length > 0;
    }
    handleSectionToggle(event) {

    }

    getAssestsLst() {
        
        getAssests({
                  loanAppId: this.recordId,
                })
                  .then((response) => {
                    console.log("customers=:" + JSON.stringify(response));
                    this.assestsLst = response;
                    if(this.assestsLst.length > 0) {
                        this.isAssestpresent = true;
                    }
                  })
                  .catch((error) => {
                  });
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

         getAppDetailsPEP() {
           getApplicantsPEP({
          recordId: this.recordId,
        })
          .then((response) => {
    
            this.appdataPEP = response;
            if (this.appdataPEP.length > 0) {
              this.hasDataPEP = true;
            }
          })
          .catch((error) => {
            console.log("error in getEmployeeCheckData---", error);
          });
        }

    connectedCallback() {
        this.getAssestsLst();
        this.getpdsLst();
        this.getAppDetailsPEP();
        this.getAppDetails();
    }

    getpdsLst() {
        
        getPDs({
                  loanAppId: this.recordId,
                })
                  .then((response) => {
                    console.log("pds=:" + JSON.stringify(response));
                    this.pdLst = response;
                    if(this.pdLst.length > 0) {
                        this.isPdpresent = true;
                    }
                  })
                  .catch((error) => {
                  });
    }
    renderedCallback() {
        if (!this.isRendered) {
            // Create and append styles dynamically
            const style = document.createElement("style");
            style.innerText = `
            .bsa-page .slds-accordion__list-item .section-control{
                background: #c5c5c5;
                color: black;
                margin-left: 0px;
                margin-bottom: 0px;
                margin-right: 0px;
                font-weight: 500;
            }
            .bsa-page .slds-accordion__summary {
                padding: 10px 0px 0px 0px;
            }
            .bsa-datatable .slds-line-height_reset .slds-cell-fixed .slds-th__action{
                background: #5bb6e3;
                color: white;
            }
            .bsa-datatable .slds-th__action.slds-th__action_form.slds-cell-fixed{
                background: #5bb6e3;
            }
            .bsa-datatable tbody{
                font-weight: 400;
            }
            .bsa-page .slds-accordion__content {
                margin-top: 10px;
            }
        `;
            // Append the styles to the .styleContainer
            this.template.querySelector(".styleContainer")?.appendChild(style);
            // Prevent re-adding styles
            this.isRendered = true;
        }
    }
}