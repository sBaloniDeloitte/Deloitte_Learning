import { LightningElement, api, track, wire } from 'lwc';
import getSelfEmployedApplicants from '@salesforce/apex/AHL_ApplicantListController.getSelfEmployedApplicants';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';

export default class selfEmployedIncomeDetails extends LightningElement {
  @api recordId;
  @track applicants = [];
  @track noApplicants = false;
  @api enableDisabled=false;
  @track hideButton = false;

  fieldLabelMap = {
  Sales: 'Sales',
  Expenses: 'Expenses',
  Operating_Income : 'Operating Income',
  Net_Earnings: 'Net Earnings',
  Other_Income: 'Other Income',
  Rent: 'Rent',
  Interest: 'Interest',
  Total_Income: 'Total Income'
};

  wiredAppsResult;

    get isFieldDisabled() {
      console.log('this.disabledCmp', this.disabledCmp);
        if(this.disabledCmp) {
            return true;
        }else {
          return this.enableDisabled;
        }
       
    }

  /*
  @wire(getSelfEmployedApplicants, { loanAppId: '$recordId' })
  wiredApps({ data, error }) {
    if (data) {
      this.applicants = data.map(app => ({
        ...app,

        annualKey:  `${app.Id}-annual`,
        monthlyKey: `${app.Id}-monthly`
      }));
      this.noApplicants = data.length === 0;
    } else if (error) {
      this.applicants = [];
      this.noApplicants = true;
      // handle error as needed
    }
  }
  /*
  @wire(getSelfEmployedApplicants, { loanAppId: '$recordId' })
  wiredApps(result) {
    this.wiredAppsResult = result;
    const { data, error } = result;
    if (data) {
      this.applicants  = data.map(app => ({
        ...app,
        Annual_Sales__c:             app.Annual_Sales__c || 0,
        Monthly_Sales__c:            app.Monthly_Sales__c || 0,
        Annual_Expenses__c:          app.Annual_Expenses__c || 0,
        Monthly_Expenses__c:         app.Monthly_Expenses__c || 0,
        Annual_Net_Earnings__c:      app.Annual_Net_Earnings__c || 0,
        Monthly_Net_Earnings__c:     app.Monthly_Net_Earnings__c || 0,
        Annual_Other_Income__c:      app.Annual_Other_Income__c || 0,
        Monthly_Other_Income__c:     app.Monthly_Other_Income__c || 0,
        Annual_Rent__c:              app.Annual_Rent__c || 0,
        Monthly_Rent__c:             app.Monthly_Rent__c || 0,
        Annual_Interest__c:          app.Annual_Interest__c || 0,
        Monthly_Interest__c:         app.Monthly_Interest__c || 0,
        Annual_Others__c:            app.Annual_Others__c || 0,
        Monthly_Others__c:           app.Monthly_Others__c || 0,
        Annual_Total_Income__c:      app.Annual_Total_Income__c || 0,
        Monthly_Total_Income__c:     app.Monthly_Total_Income__c || 0
      }));
      this.noApplicants = data.length === 0;
    } else if (error) {
      this.applicants  = [];
      this.noApplicants = true;
    }
  }
  */

  @wire(getSelfEmployedApplicants, { loanAppId: '$recordId' })
wiredApps(result) {
  this.wiredAppsResult = result;
  const { data, error } = result;
  if (data) {
    this.applicants  = data.map(app => ({
      ...app,
      annualKey:  `${app.Id}-annual`,
      monthlyKey: `${app.Id}-monthly`
    }));
    this.noApplicants = data.length === 0;
  }
  else if (error) {
      this.applicants  = [];
      this.noApplicants = true;
    }
  }

  handleBlur(event) {
    const idx     = parseInt(event.target.dataset.index, 10);
    const rowType = event.target.dataset.row;    // "annual" or "monthly"
    const field   = event.target.dataset.field;  // e.g. "Sales", "Expenses", etc.
    const rawVal  = parseFloat(event.target.value);
    const val     = isNaN(rawVal) ? 0 : rawVal;

    // base names in your schema: Annual_Sales__c, Monthly_Sales__c, etc.
    const annualFieldName  = `Annual_${field}__c`;
    const monthlyFieldName = `Monthly_${field}__c`;

    // update local state
    this.applicants = this.applicants.map((app, i) => {
      if (i !== idx) return app;
      const updated = { ...app };
      if (rowType === 'annual') {
        updated[annualFieldName]  = val;
        updated[monthlyFieldName] = parseFloat((val / 12).toFixed(2));
      } else {
        updated[monthlyFieldName] = val;
        updated[annualFieldName]  = parseFloat((val * 12).toFixed(2));
      }
      return updated;
    });

    // now push both fields to server in one call
    const recordToUpdate = this.applicants[idx];
    const fields = {
      Id: recordToUpdate.Id,
      [annualFieldName]:  recordToUpdate[annualFieldName],
      [monthlyFieldName]: recordToUpdate[monthlyFieldName]
    };

    updateRecord({ fields })
  .then(() => {
    const scopeLabel = rowType === 'annual' ? 'Annual' : 'Monthly';
    const pretty = this.fieldLabelMap[field] 
      || field.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());

    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Saved',
        message: `${scopeLabel} ${pretty} updated`,
        variant: 'success'
      })
    );

    return refreshApex(this.wiredAppsResult);
  })
      .catch(error => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error saving',
            message: error.body?.message || error.message,
            variant: 'error'
          })
        );
      });
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