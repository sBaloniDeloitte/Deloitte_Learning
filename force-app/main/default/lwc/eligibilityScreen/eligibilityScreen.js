import {LightningElement,track,wire,api} from 'lwc';
import checkEligibility from '@salesforce/apex/EligibilityCriteriaController.checkEligibility';
import getAllApplicableEligibilities from '@salesforce/apex/EligibilityCriteriaController.getAllApplicableEligibilities';
import getIntegrationDataByLoanId from '@salesforce/apex/EligibilityCriteriaController.getIntegrationDataByLoanId';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import { RefreshEvent } from "lightning/refresh";
import { getRecord } from 'lightning/uiRecordApi';
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";
import REQUESTED_AMOUNT from "@salesforce/schema/Opportunity.Requested_Amount__c";
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import insertIntegrationDetails from '@salesforce/apex/EligibilityCriteriaController.insertIntegrationDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class EligibilityScreen extends LightningElement {
  @api recordId;
  @track showButton = false;
  @track spinner = false;
  @track masterRecordId ='';

  // Commented By Prachi not needed Start
  /* @track isShowModal = false;
  @track adb;
  */
  // Commented By Prachi not needed End

  @track criteriaRecords = [];
  @track records = [];

  // Commented By Prachi not needed Start
  /* @track statusRecords = []; */
  // Commented By Prachi not needed End

  // Commented By Prachi not needed Start
  /* @track errorList = [];
  @track selectedData;
  @track isRadio = false;
  @track abdVal;
  */
  // Commented By Prachi not needed End

  @api fromsales = false;
  @track hasPsvOrDisbursalStage = false;
  @track isRendered = false;
  @api isDisabled;
  @track oppStage;
  @track oppSubStage;
  @track oppRequestedAmount;
  @track userProfile;
  @track setDefaultCheckFalse = false;

  @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, SUBSTAGE_FIELD, REQUESTED_AMOUNT] })
  opportunity({ error, data }) {
      if(data) {
          this.oppStage = data.fields.StageName.value;
          this.oppSubStage = data.fields.Sub_stage__c.value;
          this.oppRequestedAmount = data.fields.Requested_Amount__c.value;
      }
  }

  connectedCallback() {
      this.getEligibilitydata();
      this.fetchLoanStage();
      // Removed old populateIntegrationAmounts() call from connectedCallback
      // because it depends on this.records, which is set asynchronously in getEligibilitydata()
      // Instead, we moved the populateIntegrationAmounts call inside getEligibilitydata's then block
  }

  fetchLoanStage() {
      getLoanStage({ loanId: this.recordId })
        .then(result => {
          console.log('Result1', result);
          if(result == 'PSV' || result == 'Disbursement') {
              this.hasPsvOrDisbursalStage = true;
          } else if (result == 'Credit Underwriting') {
            getCurrentUserProfileName()
            .then((res) => {
                if(res == 'Sales') {
                  this.isDisabled = true;
                }
            })
            .catch((error) => {
                console.error('Error getCurrentUserProfileName --> '+ error);
            });
        }
        })
        .catch(error => {
          console.error('Error:', error);
      });
  }

  getEligibilitydata() {
      this.spinner = true;
      getAllApplicableEligibilities({
        recordId: this.recordId,
        setDefaultCheckboxFalse : this.setDefaultCheckFalse
      })
        .then((response) => {
          console.log("customer details=:" + JSON.stringify(response));
          this.records = response;
          this.spinner = false;

          this.populateIntegrationAmounts();
        })
        .catch((error) => {
          this.spinner = false;
          console.error('Error in getEligibilitydata:', error);
        });
    }
 
  populateIntegrationAmounts() {
    console.log('populateIntegrationAmounts called');

    const eligibleFicoNamesList = this.records.map(rec => rec.eligibilityTypeFicoName).filter(name => !!name);


    getIntegrationDataByLoanId({ 
      loanId: this.recordId, 
      eligibleFicoNamesList: eligibleFicoNamesList 
    })
      .then(result => {
        console.log('Integration data from Apex:', JSON.stringify(result));

        if (result && result.length > 0) {
          let updatedRecords = [...this.records];

          for (const integration of result) {
            const index = updatedRecords.findIndex(rec => rec.eligibilityTypeFicoName === integration.name);

            if (index !== -1) {
              updatedRecords[index] = { ...updatedRecords[index], eligibleLoanAmount: integration.eligibleLoanAmount };
            } 
          }

          this.records = updatedRecords;
        } 
      })
      .catch(error => {
        console.error('Error in populateIntegrationAmounts: ', error);
      });
  }

  handleLoanAmountChange(event) {
      const recordKey = event.target.dataset.id; // now using eligibilityType
      const value = parseFloat(event.target.value);

      this.records = this.records.map((rec) => {
          if (rec.eligibilityType === recordKey) {
              return { ...rec, eligibleLoanAmount: value }; // update only this row
          }
          return rec; // others unchanged
      });
  }

 onClickAddButton(event) {
    this.masterRecordId = event.currentTarget.dataset.id;

    const selectedRecord = this.records.find(record => record.eligibilityTypeFicoName === this.masterRecordId);
    console.log('this.selectedRecord---', selectedRecord);

    if (!selectedRecord) return;

    const enteredAmount = selectedRecord.eligibleLoanAmount;

    if (enteredAmount === null || enteredAmount === undefined || enteredAmount === '') {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Validation Error',
          message: 'Please enter a valid Eligible Loan Amount',
          variant: 'error'
        })
      );
      return;  
    }

    if (enteredAmount > this.oppRequestedAmount) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Validation Error',
          message: 'Eligible Loan Amount should not exceed Requested Loan Amount',
          variant: 'error'
        })
      );
      return;
    }

    // Call Apex to insert Integration_Details__c
    insertIntegrationDetails({
        loanId: this.recordId,
        eligibleAmount: enteredAmount,
        masterRecordId: this.masterRecordId
    })
    .then(result => {
        this.dispatchEvent(new RefreshEvent());
        this.showToastMessage('Success', 'Integration details created successfully.', 'success');
    })
    .catch(error => {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error creating record',
                message: error.body.message,
                variant: 'error'
            })
        );
    });
}

  handleNavigateNext(){
        console.log('218');
        this.dispatchEvent(new CustomEvent('navigatetonexttab', {
                detail: 'Document Details'
            }));
    }


  // Commented By Prachi not needed Start
  /* 
  onClickAddButton(event) { // Commented right now dont have api created another handler
    this.masterRecordId = '';
      let index = event.target.dataset.id;
      console.log('Name ',index);
      this.masterRecordId = index;
      //this.isShowModal = true;
      this.setDefaultCheckFalse = true;
      console.log('this.records: '+JSON.stringify(this.records));
      this.records = this.records.map(record => {
        console.log('inside if record');
        console.log('record.eligibilityTypeFicoName : '+record.eligibilityTypeFicoName);
        if (record.eligibilityTypeFicoName === index) {
            console.log('inside if record.eligibilityTypeFicoName : '+record.eligibilityTypeFicoName);
            console.log('record.consideredEligibility : '+record.consideredEligibility);
            return { ...record, consideredEligibility: false };
        }
        return { ...record }; 
      });
      this.handleInitiate();
  }
  */
  // Commented By Prachi not needed End

  // Commented By Prachi not needed Start
  /*
  hideModalBox() {
      this.isShowModal = false;
      this.adb = null;
  }

  handleInitiate() {
    this.adb = 0;
    this.spinner = true;
    this.callAPI();
  }

  handleInputChange(event) {
      let value = event.target.value;
      const regex = /^[0-9]+$/;
      if(regex.test(value)){
          this.adb = value;
      }else {
          this.showToastMessage('Error', 'Please enter correct value.', 'error');
          return;
      }
  }

  async callAPI() {
    this.abdVal = this.adb;
    this.hideModalBox();
    checkEligibility({
      recordId: this.recordId,
      eligibilityName:this.masterRecordId,
      adb:this.abdVal,
      isCallForDeviation:false,
      fromSales : this.fromsales
    })
      .then((response) => {
        console.log("customer details=:" + JSON.stringify(response));
        if (response.startsWith("Error")) {
            response = response.replaceAll(', ','\n');
            const toastEvent = new ShowToastEvent({
            title: 'Error',
            message: response,
            variant: 'error',
            mode:'sticky'
            });
            this.dispatchEvent(toastEvent);
            this.abdVal = null;
            this.spinner = false;
        }else if(response == 'success'){
          if(!this.fromsales) {
            this.callForDeviation();
          }else {
            this.getEligibilitydata();
            this.showToastMessage('Success', 'Eligibility fetched successfully!.', 'success');
            this.spinner = false;
          }
        }else {
          this.abdVal = null;
          this.showToastMessage('Error',response , 'error');
          this.spinner = false;
        }
        this.spinner = false;
      })
      .catch((error) => {
          this.showToastMessage('Error', 'Not able to fetch eligibility, Please check all required data.', 'error');
        this.spinner = false;
      });
  }

  async callForDeviation() {
    checkEligibility({
      recordId: this.recordId,
      eligibilityName:this.masterRecordId,
      adb:this.abdVal,
      isCallForDeviation:true,
      fromSales : this.fromsales
    })
      .then((response) => {
        if (response.startsWith("Error")) {
            var temp = response.split(':')[1];
            this.errorList = temp.split(',');
            this.showToastMessage('Error',response , 'error');
            this.spinner = false;
        }else if(response == 'success'){
            this.getEligibilitydata();
            this.dispatchEvent(new RefreshEvent());
            this.showToastMessage('Success', 'Eligibility fetched successfully!.', 'success');
            this.abdVal = null;
        }else {
            this.showToastMessage('Error',response , 'error');
            this.abdVal = null;
        }
        this.spinner = false;
      })
      .catch((error) => {
        this.showToastMessage('Error', 'Not able to fetch eligibility, Please contect your admin.', 'error');
        this.spinner = false;
      });
  }
  */
  // Commented By Prachi not needed End

  showToastMessage(title, message, variant) {
      const evt = new ShowToastEvent({
          title: title,
          message: message,
          variant: variant
      });
      this.dispatchEvent(evt);
  }

}