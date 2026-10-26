import { LightningElement, track, api,wire } from "lwc";
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import getLiveLoanData from "@salesforce/apex/COMM_LiveAndClosedLoansController.getLiveLoanData";
import getApplicants from "@salesforce/apex/COMM_LiveAndClosedLoansController.getApplicants";
import updateCreditRemarks from "@salesforce/apex/COMM_LiveAndClosedLoansController.updateCreditRemarks";
import { getRecord } from 'lightning/uiRecordApi';
const FIELDS = ['Application_Applicant__c.Name'];
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LiveAndClosedLoansCmp extends LightningElement {
  @api recordId;
 @api type = "live";
  @api appId;
  @api isDisabled = false;
  isHLRelated = false;

  @track recordData = [];
  @track applicantName;
  @track allRecordData = [];
  @track accordionKey = 0;
  @track isAccordionReady = false;
  @track fieldDetails = [];
  @track activeSections = [];
  @api fromSales = false;

  @track disableEdit = false;

  @track showGeneratedReport = false;

  @track error = "";

  @track leadDetails = "";
  @track allSectionNames = [];
  @track customerDetails = {};
  @track isRendered = false;
  @track options = [];

  /* ____GenAI: static dummy data per explicit request - when
     Income_Expense_Obligation__c has no rows for a given loan application,
     the real Apex response (getLiveLoanData) comes back as an empty list and
     the whole table (headers included) disappears, because the template's
     "if:true={recordData.length}" check fails. The two dynamic Apex methods
     below are kept in the file and only their CALLS are commented out (per
     explicit request - do not remove methods), replaced with these static
     arrays so the table always shows the SAME sample rows for every loan
     application, regardless of recordId. Field names/shape match the Apex
     "LiveAndClosedLoanDataWrapper" exactly, so no template binding changed____ */
  dummyLiveLoanData = [
    { docCount: 1, customerName: 'Abhilash Saini', customerType: 'Applicant', accountType: 'Two-Wheeler Loan', loanAmount: '40,000', balanceTenure: '12', currentBalance: '25,000', overdue: 'No', ownership: 'Individual', startDate: '11/11/2020', lastPaymentDate: '10/09/2023', dpdTradeline: 'No', dpd: '0', securedUnsecured: 'Secured', reportedDate: '11/11/2024', intDetRecordId: 'DUMMY-LIVE-001', isLiveLoan: true, isDPDRed: false, creditRemarks: 'Regular payments' },
    { docCount: 2, customerName: 'Abhilash Saini', customerType: 'Co-applicant', accountType: 'Personal Loan', loanAmount: '1,50,000', balanceTenure: '24', currentBalance: '95,000', overdue: 'Yes', ownership: 'Individual', startDate: '05/03/2021', lastPaymentDate: '02/08/2023', dpdTradeline: 'Yes', dpd: '15', securedUnsecured: 'Unsecured', reportedDate: '11/11/2024', intDetRecordId: 'DUMMY-LIVE-002', isLiveLoan: true, isDPDRed: true, creditRemarks: '' },
    { docCount: 3, customerName: 'Abhilash Saini', customerType: 'Applicant', accountType: 'Business Loan', loanAmount: '5,00,000', balanceTenure: '36', currentBalance: '3,20,000', overdue: 'No', ownership: 'Individual', startDate: '15/06/2022', lastPaymentDate: '05/10/2023', dpdTradeline: 'No', dpd: '0', securedUnsecured: 'Secured', reportedDate: '11/11/2024', intDetRecordId: 'DUMMY-LIVE-003', isLiveLoan: true, isDPDRed: false, creditRemarks: 'No delays' },
    { docCount: 4, customerName: 'Abhilash Saini', customerType: 'Co-applicant', accountType: 'Credit Card', loanAmount: '2,00,000', balanceTenure: '0', currentBalance: '45,000', overdue: 'Yes', ownership: 'Individual', startDate: '20/01/2021', lastPaymentDate: '18/07/2023', dpdTradeline: 'Yes', dpd: '30', securedUnsecured: 'Unsecured', reportedDate: '11/11/2024', intDetRecordId: 'DUMMY-LIVE-004', isLiveLoan: true, isDPDRed: true, creditRemarks: '' },
    { docCount: 5, customerName: 'Abhilash Saini', customerType: 'Guarantor', accountType: 'Gold Loan', loanAmount: '3,50,000', balanceTenure: '18', currentBalance: '1,80,000', overdue: 'No', ownership: 'Individual', startDate: '10/02/2022', lastPaymentDate: '12/09/2023', dpdTradeline: 'No', dpd: '0', securedUnsecured: 'Secured', reportedDate: '11/11/2024', intDetRecordId: 'DUMMY-LIVE-005', isLiveLoan: true, isDPDRed: false, creditRemarks: 'Regular payments' }
  ];

  dummyClosedLoanData = [
    { docCount: 1, customerName: 'Abhilash Saini', customerType: 'Applicant', accountType: 'Home Loan', loanAmount: '25,00,000', balanceTenure: '0', currentBalance: '0', overdue: 'No', ownership: 'Individual', startDate: '01/01/2015', lastPaymentDate: '01/01/2020', dpdTradeline: 'No', dpd: '0', securedUnsecured: 'Secured', reportedDate: '01/01/2020', intDetRecordId: 'DUMMY-CLOSED-001', isLiveLoan: false, isDPDRed: false, creditRemarks: 'Closed on time' },
    { docCount: 2, customerName: 'Abhilash Saini', customerType: 'Co-applicant', accountType: 'Auto Loan', loanAmount: '6,00,000', balanceTenure: '0', currentBalance: '0', overdue: 'No', ownership: 'Individual', startDate: '01/06/2016', lastPaymentDate: '01/06/2019', dpdTradeline: 'No', dpd: '0', securedUnsecured: 'Secured', reportedDate: '01/06/2019', intDetRecordId: 'DUMMY-CLOSED-002', isLiveLoan: false, isDPDRed: false, creditRemarks: '' },
    { docCount: 3, customerName: 'Abhilash Saini', customerType: 'Applicant', accountType: 'Personal Loan', loanAmount: '1,20,000', balanceTenure: '0', currentBalance: '0', overdue: 'No', ownership: 'Individual', startDate: '10/03/2017', lastPaymentDate: '10/03/2019', dpdTradeline: 'No', dpd: '0', securedUnsecured: 'Unsecured', reportedDate: '10/03/2019', intDetRecordId: 'DUMMY-CLOSED-003', isLiveLoan: false, isDPDRed: false, creditRemarks: 'Closed on time' },
    { docCount: 4, customerName: 'Abhilash Saini', customerType: 'Co-applicant', accountType: 'Two-Wheeler Loan', loanAmount: '80,000', balanceTenure: '0', currentBalance: '0', overdue: 'No', ownership: 'Individual', startDate: '05/05/2018', lastPaymentDate: '05/05/2020', dpdTradeline: 'No', dpd: '0', securedUnsecured: 'Secured', reportedDate: '05/05/2020', intDetRecordId: 'DUMMY-CLOSED-004', isLiveLoan: false, isDPDRed: false, creditRemarks: '' },
    { docCount: 5, customerName: 'Abhilash Saini', customerType: 'Guarantor', accountType: 'Business Loan', loanAmount: '4,50,000', balanceTenure: '0', currentBalance: '0', overdue: 'No', ownership: 'Individual', startDate: '18/07/2019', lastPaymentDate: '18/07/2021', dpdTradeline: 'No', dpd: '0', securedUnsecured: 'Secured', reportedDate: '18/07/2021', intDetRecordId: 'DUMMY-CLOSED-005', isLiveLoan: false, isDPDRed: false, creditRemarks: 'Closed on time' }
  ];

  dummyApplicantOptions = [
    { label: 'All', value: 'All' },
    { label: 'Akash Sharma (Applicant)', value: 'Akash Sharma' },
    { label: 'Yash Mehta (Co-applicant)', value: 'Yash Mehta' },
    { label: 'Ravi Kumar (Applicant)', value: 'Ravi Kumar' },
    { label: 'Priya Nair (Co-applicant)', value: 'Priya Nair' },
    { label: 'Sanjay Verma (Guarantor)', value: 'Sanjay Verma' }
  ];

   @wire(getRecord, { recordId: '$appId', fields: FIELDS })
    wiredApllicant({ data, error }) {
        if (data) {
            if(data.fields.Name){
                this.applicantName = data.fields.Name.value;
            }
            console.log('this.totalRequestedLoanAmount---',this.applicantName);
        } else if (error) {
            console.error('Error fetching loan record:', error);
        }
    }

    fetchProducDetails(){
      var inputMapParam = {
          'oppId': this.recordId
      };

      getProductDetails({inputMap : inputMapParam})
      .then(result =>{
          console.log('result product: '+ JSON.stringify(result));
          this.isHLRelated = result.isHLRelated;
      })
      .catch(error=>{
          console.error('error in getting product: '+ error)
      })
  }

  connectedCallback() {
     this.fetchProducDetails();
    console.log("Inside connectedCallback", this.type);
    console.log("Inside recordId", this.fromSales);
    this.getLiveAndClosedLoanData();
    this.getApplicantPickList();
  }
  getLiveAndClosedLoanData() {
    console.log('this.type----'+this.type);
    console.log('OUTPUT recordId:74 ',this.recordId);
    /* ____GenAI: dynamic Apex fetch commented out per explicit request - kept
       here (not removed) so it can be restored later. Replaced below with
       static dummy data so the table always renders, identical for every
       loan application, instead of disappearing when Apex returns no rows.
    getLiveLoanData({
      recordId: this.recordId,
      loanType: this.type,
    })
      .then((response) => {
        console.log("response customer details=:" + JSON.stringify(response));
        this.recordData = response;
        this.allRecordData = response;
        if(this.fromSales){
           console.log("test:");
            var tempList = [];
            this.allRecordData.forEach((record) => {
              if (this.applicantName == record.customerName) {
                tempList.push(record);
              }
            });
          this.recordData = tempList;
          console.log("response customer recordData=:" + JSON.stringify(this.recordData));
         }
      })
      .catch((error) => {});
    */
    var dummyResponse = this.type === 'closed' ? this.dummyClosedLoanData : this.dummyLiveLoanData;
    this.recordData = dummyResponse;
    this.allRecordData = dummyResponse;
  }
  getApplicantPickList() {
    /* ____GenAI: dynamic Apex fetch commented out per explicit request - kept
       here (not removed) so it can be restored later. Replaced below with the
       static dummy applicant options that match the dummy data above.
    getApplicants({
      recordId: this.recordId,
    })
      .then((response) => {
        console.log("customer details=:" + JSON.stringify(response));
        this.options = [... this.options,{label:'All',value:'All'}];
        for(let key in response){
            console.log("customer details=:" + response[key]);
            this.options = [...this.options, { label : response[key], value : key } ];
        }
      })
      .catch((error) => {});
    */
    this.options = this.dummyApplicantOptions;
  }

  renderedCallback() {
    if (!this.isRendered) {
      // Create and append styles dynamically
      const style = document.createElement("style");
      style.innerText = `
            .sub-tab-div .slds-tabs_default__nav{
                display: flex;
                align-items: flex-start;
                justify-content: flex-start;
                border-bottom: 1px solid;
            
            }
        `;

      // Append the styles to the .styleContainer
      this.template.querySelector(".styleContainerDiv")?.appendChild(style);

      // Prevent re-adding styles
      this.isRendered = true;
    }
  }

  //c/aadharLoginFormUpdated
  value = "All";
/*
  get options() {
    return [
      { label: "All", value: "All" },
      { label: "Akash Sharma (Applicant)", value: "Akash Sharma" },
      { label: "Yash (Co-applicant)", value: "Yash" },
    ];
  }*/

  handleChange(event) {
    if(this.fromSales ==true ){
      event.stopPropagation();
   }
    this.value = event.detail.value;
    var tempList = [];
    if (event.target.value == "All") {
      tempList = this.allRecordData;
    } else {
      this.allRecordData.forEach((record) => {
        if (record.customerName == event.target.value) {
          tempList.push(record);
        }
      });
    }
    this.recordData = tempList;
  }

  statusValue = "inProgress";

  get statusOptions() {
    return [
      { label: "Live", value: "Live" },
      { label: "Group Exposure", value: "Group Exposure" },
      { label: "Gurantor", value: "Gurantor" },
      { label: "Close in 6 months", value: "Close in 6 months" },
      { label: "Close", value: "Close" },
      { label: "Duplicate", value: "Duplicate" },
    ];
  }

  handleStatusChange(event) {
    this.statusValue = event.detail.value;
  }
  handleInputFocus(event) {
    console.log(event.target.value);
    console.log(event.target.dataset.id);
    if(event.target.value.length > 0) {
        updateCreditRemarks({
            recordId: event.target.dataset.id,
            remarks: event.target.value
          })
            .then((response) => {
              console.log("customer details=:" + JSON.stringify(response));
              if(response == 'success') {
                  this.showToastMessage('Success', 'Credit remarks is updated!.', 'success');
              }else {
                  this.showToastMessage('Error', 'Something went wrong. Please connect your admin.', 'error');
              }
            })
            .catch((error) => {});
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
}