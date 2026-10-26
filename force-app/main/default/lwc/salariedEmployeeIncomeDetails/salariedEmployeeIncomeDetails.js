import { LightningElement, api, track, wire } from 'lwc';
import getSalariedApplicants from '@salesforce/apex/AHL_ApplicantListController.getSalariedApplicants';
import calculateFOIRandCFOIR from '@salesforce/apex/CreditAssessmentController.calculateFOIRandCFOIR';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
export default class salariedEmployeeIncomeDetails extends LightningElement {
  @api recordId;                   // loan application Id
  @track applicants = [];          // array of applicant sObjects
  @track noApplicants = false;
  @api enableDisabled=false;
  wiredAppsResult;
  @track hideButton = false;

  fieldLabelMap = {
    Monthly_Gross_Salary__c: 'Monthly Gross Salary',
    Monthly_Net_Salary__c: 'Monthly Net Salary',
    Variable_Income__c: 'Variable Income',
    Other_Income__c: 'Other Income',
    Rent__c: 'Rent',
    Interest__c: 'Interest',
    Remarks__c: 'Remarks'
  };


  @wire(getSalariedApplicants, { loanAppId: '$recordId' })
  wiredApps(result) {
    this.wiredAppsResult = result;
    const { data, error } = result;
    if (data) {
      this.applicants = data;
      this.noApplicants = data.length === 0;
    } else if (error) {
      this.applicants = [];
      this.noApplicants = true;
    }
  }
  handleInputChange(event) {
    const idx = event.target.dataset.index;
    const field = event.target.dataset.id;   // e.g. "Monthly_Gross_Salary__c"
    const value = event.target.value;
    const record = this.applicants[idx];

    // update local UI
    this.applicants = this.applicants.map((app, i) =>
      i === idx ? { ...app, [field]: value } : app
    );

    // save
    const fields = { Id: record.Id, [field]: value };
    updateRecord({ fields })
      .then(() => {
        const label = this.fieldLabelMap[field] || field;
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Saved',
            message: `${label} updated`,
            variant: 'success'
          })
        );
        this.calculateLTVAndFoir();
        return refreshApex(this.wiredAppsResult);
      })
      .catch(err => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error saving',
            message: err.body?.message || err.message,
            variant: 'error'
          })
        );
      });
  }

calculateLTVAndFoir() {
        calculateFOIRandCFOIR({
          loanId: this.recordId,
        })
          .then((response) => {
            
          })
          .catch((error) => {});
    }

    connectedCallback() {
      this.checkCmpEditability();
    }

     checkCmpEditability() {
    getComponentEditability({ loanId : this.recordId, component : '' })
    .then(result => {
        if(result){
            this.hideButton = result;
            if(this.hideButton) {
              this.enableDisabled = true;
            }
            
            console.log('this.hideButton>>>>'+this.hideButton);
        }
    })
    .catch(error => {
        console.log('Error getComponentEditability:  '+error);
    });
  }

}