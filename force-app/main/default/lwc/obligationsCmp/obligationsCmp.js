import { LightningElement, track,api,wire } from "lwc";
import getObligationsRecords from "@salesforce/apex/COMM_ObligationsController.getObligationsRecords";
import getApplicants from "@salesforce/apex/COMM_LiveAndClosedLoansController.getApplicants";
import upsertObligationRec from "@salesforce/apex/COMM_ObligationsController.upsertObligationRec";
import getAccountTypePicklist from "@salesforce/apex/COMM_ObligationsController.getAccountTypePicklist";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { textValidation} from 'c/utility';
import { updateRecord,getRecord, getFieldValue  } from "lightning/uiRecordApi";
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import APPROVAL_STATUS from "@salesforce/schema/Opportunity.Approval_Status__c";
import INCOME_APPROVAL_STATUS from '@salesforce/schema/Opportunity.Income_Approval_Status__c';
import deleteObligation from '@salesforce/apex/COMM_ObligationsController.deleteObligation';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import savemonthHead from "@salesforce/apex/COMM_ObligationsController.savemonthHead";
import saveMonthValue from "@salesforce/apex/COMM_ObligationsController.saveMonthValue";


export default class ObligationsCmp extends LightningElement {
  @api recordId;
  @api isOneView = false;
  @track disabledCmp = false;
  @api isDisabled = false;
  channelName = '/event/Refresh_Event__e';
  maxDate;
  /*
  options = [
    { label: "All", value: "All" },
    { label: "Akash", value: "Akash" },
    { label: "Yash", value: "Yash" },
  ];*/

  @track options = [];

  loanTypeOptions = [];
  @track applicantValue = "All";
  securityTypeOptions = [
    { label: "All", value: "All" },
    { label: "Unsecured", value: "Unsecured" },
    { label: "Secured", value: "Secured" },
  ];
  @track securityType = "All";
  applicantTypeOptions = [
    { label: "All", value: "All" },
    { label: "Applicant", value: "Primary Applicant" },
    { label: "Co-applicant", value: "Co Applicant" },
  ];
  @track applicantType = "All";
  @track filteredList = [];
  @track addNewList = [];
  @track isRendered = false;
  @track recordData = [];
  @track allData;
  @track totalData = {};
  @track spinner = true;
  selectedRecords = [];
    loanType = 'All';
showDropdown = false;

loanTypeOptionsFiltered = [];
  isNewRow = false;
  @api fromSales= false;
  remarksOptions = [
    { label: 'Obligated', value: 'Obligated' },
    { label: 'Balance Transfer Loan', value: 'Balance Transfer Loan' },
    { label: 'Closure from Disbursement', value: 'Closure from Disbursement' },
    { label: 'Closure proof to be provided', value: 'Closure proof to be provided' },
    { label: 'Less than 12 EMI pending', value: 'Less than 12 EMI pending' },
    { label: 'Duplicate in Bureau', value: 'Duplicate in Bureau' },
    { label: 'Guarantor to Loan', value: 'Guarantor to Loan' },
    { label: 'Closed Loan', value: 'Closed Loan' },
    { label: 'Paid by third party', value: 'Paid by third party' },
    { label: 'Paid by a co-applicant', value: 'Paid by a co-applicant' }
  ];

  @track customerName = [];
  @track isNoObligationRecordsFound = false;
  customerType = [
    { label: "Applicant", value: "Applicant" },
    { label: "Co-applicant", value: "Co-applicant" }
  ];
  financer= [
    { label: "SBI", value: "SBI" },
    { label: "Axis", value: "Axis" }
  ];
  loanTypeOp=[];
  securityTypeOp = [
    { label: "Unsecured", value: "Unsecured" },
    { label: "Secured", value: "Secured" }
  ];
   hideButton = false;
      
  //Mobile-Ishi
  isSmall = false;
  //isRendered = false;
  //Mobile-Ishi
  isHLRelated = false;
 @track monthDateHeaders;

  /* ____GenAI: static dummy data per explicit request - the live
     Income_Expense_Obligation__c query (getObligationsRecords) can come back
     empty for a given loan application, making the whole obligations table
     disappear. The dynamic Apex-calling methods below are kept in the file
     and only their CALLS are commented out (per explicit request - do not
     remove methods), replaced with these static arrays so both the standard
     table and the Home-Loan month-wise table always show the SAME sample
     rows, regardless of recordId. Field names/shape match exactly what the
     existing template already binds to (record.srNo, record.customerName,
     etc.) so no HTML/CSS or handler logic needed to change____ */
  dummyObligationRecords = [
    { srNo: 1, customerName: 'Abhilash Saini', customerType: 'Applicant', ownership: 'Individual', startDate: '15/01/2024', loanType: 'Personal Loan', loanAmount: 150000, outstandingBalance: 95000, emi: 8500, isEMIUpdated: false, securityType: 'Unsecured', isSecurityUpdated: false, isBanking: false, isObligation: true, emiBounce: '0', balanceTenure: '12', remarks: 'Obligated', intDetRecordId: 'DUMMY-OBL-001', isRemovable: true },
    { srNo: 2, customerName: 'Abhilash Saini', customerType: 'Co-applicant', ownership: 'Individual', startDate: '20/03/2023', loanType: 'Two-Wheeler Loan', loanAmount: 60000, outstandingBalance: 32000, emi: 3200, isEMIUpdated: false, securityType: 'Secured', isSecurityUpdated: false, isBanking: true, isObligation: true, emiBounce: '0', balanceTenure: '10', remarks: 'Obligated', intDetRecordId: 'DUMMY-OBL-002', isRemovable: true },
    { srNo: 3, customerName: 'Abhilash Saini', customerType: 'Applicant', ownership: 'Individual', startDate: '05/06/2022', loanType: 'Business Loan', loanAmount: 500000, outstandingBalance: 320000, emi: 15000, isEMIUpdated: true, securityType: 'Secured', isSecurityUpdated: false, isBanking: false, isObligation: true, emiBounce: '0', balanceTenure: '30', remarks: 'Balance Transfer Loan', intDetRecordId: 'DUMMY-OBL-003', isRemovable: true },
    { srNo: 4, customerName: 'Abhilash Saini', customerType: 'Co-applicant', ownership: 'Individual', startDate: '18/01/2021', loanType: 'Credit Card', loanAmount: 200000, outstandingBalance: 45000, emi: 4500, isEMIUpdated: false, securityType: 'Unsecured', isSecurityUpdated: false, isBanking: true, isObligation: true, emiBounce: '1', balanceTenure: '0', remarks: 'Closure proof to be provided', intDetRecordId: 'DUMMY-OBL-004', isRemovable: true },
    { srNo: 5, customerName: 'Abhilash Saini', customerType: 'Applicant', ownership: 'Individual', startDate: '10/02/2022', loanType: 'Gold Loan', loanAmount: 350000, outstandingBalance: 180000, emi: 17100, isEMIUpdated: false, securityType: 'Secured', isSecurityUpdated: true, isBanking: false, isObligation: true, emiBounce: '0', balanceTenure: '18', remarks: 'Obligated', intDetRecordId: 'DUMMY-OBL-005', isRemovable: true }
  ];

  dummyMonthDateHeaders = [
    { apiName: 'Month1Value__c', dateValue: 'Jan-2024', isEditing: false },
    { apiName: 'Month2Value__c', dateValue: 'Feb-2024', isEditing: false },
    { apiName: 'Month3Value__c', dateValue: 'Mar-2024', isEditing: false }
  ];

  dummyObligationRecordsHL = [
    { srNo: 1, customerName: 'Akash Sharma', customerType: 'Applicant', ownership: 'Individual', startDate: '15/01/2024', loanType: 'Home Loan', loanAmount: 2500000, outstandingBalance: 1950000, emi: 22500, isEMIUpdated: false, securityType: 'Secured', isSecurityUpdated: false, isBanking: false, isObligation: true, remarks: 'Obligated', intDetRecordId: 'DUMMY-OBL-HL-001', isRemovable: true, monthLabelValueList: [{ label: 'Jan-2024', value: '22,500' }], monthValues: [ { value: '22,500', apiName: 'Month1Value__c', key: 'DUMMY-OBL-HL-001-0' }, { value: '22,500', apiName: 'Month2Value__c', key: 'DUMMY-OBL-HL-001-1' }, { value: '22,500', apiName: 'Month3Value__c', key: 'DUMMY-OBL-HL-001-2' } ] },
    { srNo: 2, customerName: 'Yash Mehta', customerType: 'Co-applicant', ownership: 'Individual', startDate: '20/03/2023', loanType: 'Personal Loan', loanAmount: 150000, outstandingBalance: 95000, emi: 8500, isEMIUpdated: false, securityType: 'Unsecured', isSecurityUpdated: false, isBanking: true, isObligation: true, remarks: 'Obligated', intDetRecordId: 'DUMMY-OBL-HL-002', isRemovable: true, monthLabelValueList: [{ label: 'Jan-2024', value: '8,500' }], monthValues: [ { value: '8,500', apiName: 'Month1Value__c', key: 'DUMMY-OBL-HL-002-0' }, { value: '8,500', apiName: 'Month2Value__c', key: 'DUMMY-OBL-HL-002-1' }, { value: '8,500', apiName: 'Month3Value__c', key: 'DUMMY-OBL-HL-002-2' } ] },
    { srNo: 3, customerName: 'Ravi Kumar', customerType: 'Applicant', ownership: 'Individual', startDate: '05/06/2022', loanType: 'Business Loan', loanAmount: 500000, outstandingBalance: 320000, emi: 15000, isEMIUpdated: true, securityType: 'Secured', isSecurityUpdated: false, isBanking: false, isObligation: true, remarks: 'Balance Transfer Loan', intDetRecordId: 'DUMMY-OBL-HL-003', isRemovable: true, monthLabelValueList: [{ label: 'Jan-2024', value: '15,000' }], monthValues: [ { value: '15,000', apiName: 'Month1Value__c', key: 'DUMMY-OBL-HL-003-0' }, { value: '15,000', apiName: 'Month2Value__c', key: 'DUMMY-OBL-HL-003-1' }, { value: '15,000', apiName: 'Month3Value__c', key: 'DUMMY-OBL-HL-003-2' } ] },
    { srNo: 4, customerName: 'Priya Nair', customerType: 'Co-applicant', ownership: 'Individual', startDate: '18/01/2021', loanType: 'Credit Card', loanAmount: 200000, outstandingBalance: 45000, emi: 4500, isEMIUpdated: false, securityType: 'Unsecured', isSecurityUpdated: false, isBanking: true, isObligation: true, remarks: 'Closure proof to be provided', intDetRecordId: 'DUMMY-OBL-HL-004', isRemovable: true, monthLabelValueList: [{ label: 'Jan-2024', value: '4,500' }], monthValues: [ { value: '4,500', apiName: 'Month1Value__c', key: 'DUMMY-OBL-HL-004-0' }, { value: '4,500', apiName: 'Month2Value__c', key: 'DUMMY-OBL-HL-004-1' }, { value: '4,500', apiName: 'Month3Value__c', key: 'DUMMY-OBL-HL-004-2' } ] },
    { srNo: 5, customerName: 'Sanjay Verma', customerType: 'Applicant', ownership: 'Individual', startDate: '10/02/2022', loanType: 'Gold Loan', loanAmount: 350000, outstandingBalance: 180000, emi: 17100, isEMIUpdated: false, securityType: 'Secured', isSecurityUpdated: true, isBanking: false, isObligation: true, remarks: 'Obligated', intDetRecordId: 'DUMMY-OBL-HL-005', isRemovable: true, monthLabelValueList: [{ label: 'Jan-2024', value: '17,100' }], monthValues: [ { value: '17,100', apiName: 'Month1Value__c', key: 'DUMMY-OBL-HL-005-0' }, { value: '17,100', apiName: 'Month2Value__c', key: 'DUMMY-OBL-HL-005-1' }, { value: '17,100', apiName: 'Month3Value__c', key: 'DUMMY-OBL-HL-005-2' } ] }
  ];

  dummyTotalData = {
    totalLoanAmount: 1360000,
    totalOutstandingBalance: 852000,
    totalEmi: 68800,
    totalNumberMonthlyObligation: 5,
    totalMonthlyObligation: '68,800',
    totalNumberMonthlyObligationForBanking: 2,
    totalMonthlyObligationForBanking: '11,700',
    totalNumberAnnualObligation: 5,
    totalAnnualObligation: '8,25,600',
    totalNumberUnsecuredObligation: 2,
    totalUnsecuredObligation: '3,50,000',
    totalNumberSecuredObligation: 3,
    totalSecuredObligation: '9,10,000',
    creditCardMax: '35%',
    totalNumberOfcreditCardMax: 1,
    creditCardExposure: '45,000',
    DTO: '28%',
    ETO: '18%',
    overallETO: '32%'
  };

  dummyApplicantOptions = [
    { label: 'Akash Sharma', value: 'Akash Sharma' },
    { label: 'Yash Mehta', value: 'Yash Mehta' },
    { label: 'Ravi Kumar', value: 'Ravi Kumar' },
    { label: 'Priya Nair', value: 'Priya Nair' },
    { label: 'Sanjay Verma', value: 'Sanjay Verma' }
  ];

  dummyLoanTypeOptions = [
    { label: 'Personal Loan', value: 'Personal Loan' },
    { label: 'Two-Wheeler Loan', value: 'Two-Wheeler Loan' },
    { label: 'Business Loan', value: 'Business Loan' },
    { label: 'Credit Card', value: 'Credit Card' },
    { label: 'Gold Loan', value: 'Gold Loan' },
    { label: 'Home Loan', value: 'Home Loan' }
  ];
  

  
sortByLoanAmountAsc() {
  this.filteredList = [...this.filteredList].sort((a, b) => Number(a.loanAmount) - Number(b.loanAmount));
}

sortByLoanAmountDesc() {
  this.filteredList = [...this.filteredList].sort((a, b) => Number(b.loanAmount) - Number(a.loanAmount));
}


  sortByStartDateAsc(){
    this.filteredList = [...this.filteredList].sort((a, b) => {
      const dateA = a.startDate ? new Date(a.startDate) : new Date(0);
      const dateB = b.startDate ? new Date(b.startDate) : new Date(0);
      return dateA - dateB;
    });

  }

  sortByStartDateDesc(){
    this.filteredList = [...this.filteredList].sort((a, b) => {
            const dateA = a.startDate ? new Date(a.startDate) : new Date(0);
            const dateB = b.startDate ? new Date(b.startDate) : new Date(0);
            return dateB - dateA;
        });

  }
      
    @wire(getRecord, { recordId: "$recordId", fields: [SUBSTAGE_FIELD,APPROVAL_STATUS] })
              opportunity({ error, data }) {
                  if(data) {
                      var oppSubStage = data.fields.Sub_stage__c.value;
                      console.log('data.fields.Approval_Status__c.value>>'+data.fields.Approval_Status__c.value);
                      if (oppSubStage === 'Disbursed' ||
                          ['Hard Rejected', 'Soft Rejected 1', 'Soft Rejected 2'].includes(data.fields.Approval_Status__c.value)) {
                              this.hideButton = true;
                              
                          }
                     
                  }
              }
    @track disableInputsFlag = false; // ← stored property you can use in template or pass to children

  @wire(getRecord, { recordId: '$recordId', fields: [APPROVAL_STATUS, INCOME_APPROVAL_STATUS] })
  setDisableInputs({ error, data }) {
    if (data) {
      const status = getFieldValue(data, APPROVAL_STATUS);
      const incomeStatus = getFieldValue(data, INCOME_APPROVAL_STATUS);

      const blockedMain = new Set([
        'Hard Rejected',
        'Soft Rejected 1',
        'Soft Rejected 2',
        'Submitted',
        'Rejected'
      ]);

      const mainBlocked = status ? blockedMain.has(status) : false;
      const incomeBlocked = incomeStatus === 'Submitted';

      this.disableInputsFlag = mainBlocked || incomeBlocked;
    } else if (error) {
      this.disableInputsFlag = false;
      console.error('Disable flag wire error', JSON.stringify(error));
    }
  }

  get disableInputs() {
    return this.disableInputsFlag;
              }

  connectedCallback() {
    console.log('oneview-----', this.isOneView);
    this.fetchProducDetails();
    this.registerErrorListener();
    this.subscribeToPlatformEvent();
    setTimeout(() => {
          this.getObligationData();
    }, 2000);
    this.getApplicantPickList();
    this.getAccountTypePicklistVal();
    const today = new Date();
        this.maxDate = today.toISOString().split('T')[0];
    if (FORM_FACTOR == 'Small') {
        this.isSmall = true;
    }
    else{
      this.isSmall = false;
    }
    this.checkCmpEditability();
  }

  checkCmpEditability() {
    getComponentEditability({ loanId : this.recordId, component : '' })
    .then(result => {
        if(result){
            this.disabledCmp = result;
            console.log('this.hideButton>>>>'+this.hideButton);
        }
    })
    .catch(error => {
        console.log('Error getComponentEditability:  '+error);
    });
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

  @api handleReset(){
    this.getObligationData();
    this.getApplicantPickList();
    this.getAccountTypePicklistVal();
  }

  getAccountTypePicklistVal() {
    /* ____GenAI: dynamic Apex fetch commented out per explicit request - kept
       here (not removed) so it can be restored later. Replaced below with
       the static dummy loan-type options that match the dummy obligation
       rows above, so the "Select Loan Type" filter / Add Row dropdown keeps
       working the same way against the dummy data.
    getAccountTypePicklist({
      
    })
      .then((response) => {
        console.log("loan-type0details=:" + JSON.stringify(response));
        this.loanTypeOptions = [... this.loanTypeOptions,{label:'All',value:'All'}];
        for(let key in response){
            console.log("loan type details=:" + response[key]);
            this.loanTypeOptions = [...this.loanTypeOptions, { label : response[key], value : response[key] } ];
            this.loanTypeOp = [...this.loanTypeOp, { label : response[key], value : response[key] } ];
            
        }
      })
      .catch((error) => {});
    */
    this.loanTypeOptions = [{ label: 'All', value: 'All' }, ...this.dummyLoanTypeOptions];
    this.loanTypeOp = [...this.dummyLoanTypeOptions];
  }

  getApplicantPickList() {
    /* ____GenAI: dynamic Apex fetch commented out per explicit request - kept
       here (not removed) so it can be restored later. Replaced below with
       the static dummy applicant options that match the dummy obligation
       rows above, so the "Select Applicant" filter / Add Row applicant
       dropdown keeps working the same way against the dummy data.
    getApplicants({
      recordId: this.recordId,
    })
      .then((response) => {
        console.log("customer details=:" + JSON.stringify(response));
        this.options = [... this.options,{label:'All',value:'All'}];
        for(let key in response){
            console.log("customer details=:" + response[key]);
            this.options = [...this.options, { label : response[key], value : key } ];
            this.customerName = [...this.customerName, { label : response[key], value : key } ];
        }
      })
      .catch((error) => {});
    */
    this.options = [{ label: 'All', value: 'All' }, ...this.dummyApplicantOptions];
    this.customerName = [...this.dummyApplicantOptions];
  }

  handleApplicantChange(event) {
    this.applicantValue = event.target.value;
    /*
    var tempList = [];
    if (event.target.value == "All") {
      tempList = this.recordData;
    } else {
      this.recordData.forEach((record) => {
        if (record.customerName == event.target.value && (this.loanType != 'All' && record.loanType == this.loanType) &&
        (this.securityType != 'All' && record.securityType == this.applicantType) && 
        (this.applicantType != 'All' && record.customerType == this.applicantType) ) {
          tempList.push(record);
        }
      });
    }

    this.filteredList = tempList;
    var index = 1;
    this.filteredList.forEach((record) => {
      record.srNo = index;
      index = index + 1;
    });*/
  }
  renderedCallback() {
    if (!this.isRendered) {
      // Create and append styles dynamically
      const style = document.createElement("style");
      style.innerText = `
            .obligation-div .slds-accordion__list-item .section-control{
                background: #9bbf56;
                color: white;
                margin-left: 0px;
                margin-bottom: 0px;
                margin-right: 0px;
                margin-top: 5px;
            }
            /* Start Date calendar (datepicker) - dark theme, matches the
               rest of this table. Only colors changed; open/close and
               date-selection behavior untouched. Injected globally (not
               module-scoped CSS) because the calendar popup renders
               inside the base lightning-input's own internals, which
               scoped component CSS cannot reach. */
            .slds-datepicker {
                background-color: #16283f !important;
                border: 1px solid #33455e !important;
                color: #ffffff !important;
            }
            .slds-datepicker .slds-datepicker__filter,
            .slds-datepicker .slds-datepicker__filter_month,
            .slds-datepicker .slds-datepicker__filter_year {
                background-color: #16283f !important;
                color: #ffffff !important;
            }
            .slds-datepicker select,
            .slds-datepicker .slds-select {
                background-color: #16283f !important;
                color: #ffffff !important;
                border-color: #33455e !important;
            }
            .slds-datepicker table {
                background-color: #16283f !important;
            }
            .slds-datepicker th,
            .slds-datepicker th abbr {
                background-color: #16283f !important;
                color: #ffffff !important;
                border-color: #33455e !important;
            }
            .slds-datepicker td {
                background-color: #16283f !important;
                border-color: #33455e !important;
            }
            .slds-datepicker .slds-day {
                color: #ffffff !important;
            }
            .slds-datepicker td.slds-disabled-text .slds-day {
                color: #647895 !important;
            }
            .slds-datepicker td:hover .slds-day,
            .slds-datepicker td:focus .slds-day {
                background-color: #1f3550 !important;
                color: #ffffff !important;
            }
            .slds-datepicker .slds-is-selected .slds-day {
                background-color: #8b5cf6 !important;
                color: #ffffff !important;
            }
            .slds-datepicker .slds-is-today .slds-day {
                border: 1px solid #8b5cf6 !important;
            }
            .slds-datepicker__filter_month button,
            .slds-datepicker__filter_month .slds-button {
                color: #ffffff !important;
                fill: #ffffff !important;
            }
            /* Loan Type dropdown (Add Row) - scrollbar recolored to
               blue/grey to match the app theme. Only scrollbar color
               changed; opening/searching/selecting is untouched. Also
               injected globally for the same shadow-DOM reason as above. */
            .obligation-div lightning-combobox .slds-listbox,
            .obligation-div .slds-dropdown {
                scrollbar-color: #7a8795 #16283f !important;
                scrollbar-width: thin !important;
            }
            .obligation-div lightning-combobox .slds-listbox::-webkit-scrollbar,
            .obligation-div .slds-dropdown::-webkit-scrollbar {
                width: 8px;
            }
            .obligation-div lightning-combobox .slds-listbox::-webkit-scrollbar-track,
            .obligation-div .slds-dropdown::-webkit-scrollbar-track {
                background: #16283f !important;
            }
            .obligation-div lightning-combobox .slds-listbox::-webkit-scrollbar-thumb,
            .obligation-div .slds-dropdown::-webkit-scrollbar-thumb {
                background: #7a8795 !important;
                border-radius: 5px;
            }
            .obligation-div lightning-combobox .slds-listbox::-webkit-scrollbar-thumb:hover,
            .obligation-div .slds-dropdown::-webkit-scrollbar-thumb:hover {
                background: #9aa7b5 !important;
            }
        `;

      // Append the styles to the .styleContainer
      this.template.querySelector(".styleContainer")?.appendChild(style);

      // Prevent re-adding styles
      this.isRendered = true;
    }
  }

  getObligationData() {
    /* ____GenAI: dynamic Apex fetch commented out per explicit request - kept
       here (not removed) so it can be restored later. Replaced below with
       static dummy data so both the standard obligations table and the
       Home-Loan month-wise table always render the SAME sample rows,
       instead of disappearing when Income_Expense_Obligation__c has no rows
       for a given loan application.
    if(!this.isHLRelated){
      getObligationsRecords({
        recordId: this.recordId,
        isOneView:this.isOneView,
      })
        .then((response) => {
          console.log("obligations details=:" + JSON.stringify(response));
            if(Object.keys(response).length === 0) {
              this.isNoObligationRecordsFound = this.isOneView;
            }
            else{
              this.isNoObligationRecordsFound = false;
              this.allData = response;
              this.recordData = response.lstOblRec;
              this.totalData = response.totalWrap;
              this.filteredList = this.recordData;
              var index = 1;
              this.filteredList.forEach((record) => {
                record.srNo = index;
                
                index = index + 1;
              
                // if(this.fromSales) {
                //   record.isObligation = false;
                // }
              });
              
            }
            console.log('fromSales',this.fromSales);
            // if(this.fromSales) {
            //   this.isOneView = true;
            // }
          
          this.spinner = false;
        })
        .catch((error) => {});
        console.log('isNoObligationRecordsFound229',this.isNoObligationRecordsFound);
    }
    else{
       getObligationsRecords({ recordId: this.recordId, isOneView: this.isOneView })
        .then(response => {
            // result.lstOblRec expected

            if(Object.keys(response).length === 0) {
              this.isNoObligationRecordsFound = this.isOneView;
              this.filteredList = [];
              this.monthHeaders = [];
            }
            else{
              this.isNoObligationRecordsFound = false;
              this.allData = response;
              this.recordData = response.lstOblRec;
              this.totalData = response.totalWrap;
              this.filteredList = response.lstOblRec.map((r, i) => {
                    // r.monthLabelValueList is already an ordered list from Apex
                    // sometimes LWC receives plain objects; copying to new object helps reactivity
                    const monthVals = (r.monthValues || []).map((val, idx) => {
                    return {
                        value: val,
                        apiName: `Month${idx+1}Value__c`,
                        key: `${r.intDetRecordId || r.docCount}-${idx}` // stable key
                      };
                  });
                  return {
                      ...r,
                      srNo: (r.docCount || (i + 1)),
                      // ensure monthLabelValueList exists
                        monthValues: monthVals
                    //  monthValues: r.monthValues ? r.monthValues : []
                  };
                });
                // get headers from the first record (they're ordered by label in Apex)
                this.monthDateHeaders = (response.monthDateHeaders) ? response.monthDateHeaders : [];
                console.log('monthDateHeaders : '+this.monthDateHeaders);
                if (this.filteredList.length > 0 && this.filteredList[0].monthLabelValueList.length > 0) {
                    this.monthHeaders = this.filteredList[0].monthLabelValueList;
                    console.log('272 : '+ JSON.stringify(this.monthHeaders));
                } else {
                    this.monthHeaders = [];
                }
            }

              this.totalData = response.totalWrap;
              this.spinner = false;
        })
        .catch(error => {
            // handle error (toast or console)
              this.spinner = false;
            console.error('Error loading obligations: ', error);
            this.filteredList = [];
            this.monthHeaders = [];
        });
      }
    */
    this.isNoObligationRecordsFound = false;
    if(!this.isHLRelated){
      this.allData = { lstOblRec: this.dummyObligationRecords, totalWrap: this.dummyTotalData };
      this.recordData = this.dummyObligationRecords;
      this.totalData = this.dummyTotalData;
      this.filteredList = this.recordData;
      var index = 1;
      this.filteredList.forEach((record) => {
        record.srNo = index;
        index = index + 1;
      });
    }
    else{
      this.allData = { lstOblRec: this.dummyObligationRecordsHL, totalWrap: this.dummyTotalData };
      this.recordData = this.dummyObligationRecordsHL;
      this.totalData = this.dummyTotalData;
      this.filteredList = this.dummyObligationRecordsHL.map((r, i) => {
        const monthVals = (r.monthValues || []).map((val) => ({ ...val }));
        return {
          ...r,
          srNo: (r.srNo || (i + 1)),
          monthValues: monthVals
        };
      });
      this.monthDateHeaders = this.dummyMonthDateHeaders;
      if (this.filteredList.length > 0 && this.filteredList[0].monthLabelValueList && this.filteredList[0].monthLabelValueList.length > 0) {
        this.monthHeaders = this.filteredList[0].monthLabelValueList;
      } else {
        this.monthHeaders = [];
      }
    }
    this.spinner = false;
  }
  

    get statusOptions() {
        return [
            { label: 'Value 1', value: 'Value 1' },
            { label: 'Value 2', value: 'Value 2' },
            { label: 'Value 3', value: 'Value 3' }
        ];
    }


    openList() {
        this.showDropdown = true;
        this.loanTypeOptionsFiltered = [...this.loanTypeOptions];
    }

    handleSearch(event) {
        this.loanType = event.target.value.toLowerCase();

        this.loanTypeOptionsFiltered = this.loanTypeOptions.filter(opt =>
            opt.label.toLowerCase().includes(this.loanType)
        );

        this.showDropdown = true;
    }

    selectOption(event) {
        const val = event.currentTarget.dataset.value;
        this.loanType = val;
        this.showDropdown = false;
    }
    openList() {
        this.showDropdown = true;
    }

    handleLoanTypeChange(event) {
      if(this.fromSales ==true ){
        event.stopPropagation();
      }
        this.loanType = event.target.value;
        console.log(this.loanType);
        /*
        var tempList = [];
        if (event.target.value == "All") {
          tempList = this.recordData;
        } else {
          this.recordData.forEach((record) => {
            if (record.loanType == event.target.value && (this.applicantValue != 'All' && record.customerName == this.applicantValue) &&
            (this.securityType != 'All' && record.securityType == this.securityType) &&
            (this.applicantType != 'All' && record.customerType == this.applicantType)) {
              tempList.push(record);
            }
          });
        }
    
        this.filteredList = tempList;
        var index = 1;
        this.filteredList.forEach((record) => {
          record.srNo = index;
          index = index + 1;
        });*/
    }


    handleSecurityTypeChange(event) {
      if(this.fromSales ==true ){
        event.stopPropagation();
      }
        this.securityType = event.target.value;
        /*
        var tempList = [];
        if (event.target.value == "All") {
          tempList = this.recordData;
        } else {
          this.recordData.forEach((record) => {
            if (record.securityType == event.target.value && (this.applicantValue != 'All' && record.customerName == this.applicantValue) &&
            (this.applicantType != 'All' && record.customerType == this.applicantType) &&
            (this.loanType != 'All' && record.loanType == this.loanType) ) {
              tempList.push(record);
            }
          });
        }
    
        this.filteredList = tempList;
        var index = 1;
        this.filteredList.forEach((record) => {
          record.srNo = index;
          index = index + 1;
        });*/
    }
    handleApplicantTypeChange(event) {
      if(this.fromSales ==true ){
        event.stopPropagation();
      }
        this.applicantType = event.target.value;
        /*
        var tempList = [];
        if (event.target.value == "All") {
          tempList = this.recordData;
        } else {
          this.recordData.forEach((record) => {
            if (record.customerType == event.target.value && (this.loanType != 'All' && record.loanType == this.loanType) &&
            (this.applicantValue != 'All' && record.customerName == this.applicantValue) && 
            (this.securityType != 'All' && record.securityType == this.securityType)) {
              tempList.push(record);
            }
          });
        }
    
        this.filteredList = tempList;
        var index = 1;
        this.filteredList.forEach((record) => {
          record.srNo = index;
          index = index + 1;
        });*/
    }
    handleSelectALLChange(event) {
      if(this.fromSales ==true ){
        event.stopPropagation();
      }
        const toggleList =  this.template.querySelectorAll(".comboBoxSelect");
        console.log('toggleList len =:'+toggleList.length);
        for (const toggleElement of toggleList) {
            let temp = toggleElement.id;
            if(event.target.checked){
                toggleElement.checked = true;
                if(!this.selectedRecords.includes(temp)){
                    this.selectedRecords.push(temp);
                }
            }
            else{
                toggleElement.checked = false;
                this.selectedRecords = [];
            }
        }
        if(event.target.checked){
          for(let i = 0;i<this.recordData.length;i++){
            this.recordData[i].isObligation = true;
          }
          for(let i = 0;i<this.addNewList.length;i++){
            this.addNewList[i].isObligation = true;
          }
        }else {
          for(let i = 0;i<this.recordData.length;i++){
            this.recordData[i].isObligation = false;
          }
          for(let i = 0;i<this.addNewList.length;i++){
            this.addNewList[i].isObligation = false;
          }
        }
        
        console.log('selectedRecords  ',this.selectedRecords);
    }
    handleAddRwClick(event) {
      if(this.fromSales ==true ){
        event.stopPropagation();
      }
        this.createRow(this.filteredList);
    }
    
    handlefilterClick(event){
      if(this.fromSales ==true ){
        event.stopPropagation();
      }
        console.log('this.applicantType ',this.applicantType);
        console.log('this.securityType ',this.securityType);
        console.log('this.loanType ',this.loanType);
        console.log('this.applicantValue ',this.applicantValue);
      try{
        var tempList = [];
        var currentlst = this.recordData;
        if(this.applicantType != 'All') {
            currentlst.forEach((record) => {
                if (record.customerType == this.applicantType ) {
                  tempList.push(record);
                }
              });
              currentlst = tempList;
              tempList = [];
        }
        if(this.securityType != 'All') {
            currentlst.forEach((record) => {
                if (record.securityType == this.securityType ) {
                  tempList.push(record);
                }
              });
              currentlst = tempList;
              tempList = [];
        }
        if(this.loanType != 'All') {
            currentlst.forEach((record) => {
                if (record.loanType == this.loanType ) {
                  tempList.push(record);
                }
              });
              currentlst = tempList;
              tempList = [];
        }
        if(this.applicantValue != 'All') {
            console.log('inside applicantvalue ',currentlst);
            currentlst.forEach((record) => {
                console.log('inside record ',record);
                if (record.customerName == this.applicantValue ) {
                  tempList.push(record);
                }
              });
              console.log('inside tempList ',tempList);
              currentlst = tempList;
              tempList = [];
        }
        console.log('outside currentlst ',currentlst);
        this.filteredList = currentlst;
        var index = 1;
        var totalLoanAmount = 0;
        var totalOutstandingBalance = 0;
        var totalEmi = 0;
        this.filteredList.forEach((record) => {
          record.srNo = index;
          totalLoanAmount = totalLoanAmount + record.loanAmount;
          totalOutstandingBalance = totalOutstandingBalance + record.outstandingBalance;
          totalEmi = totalEmi + record.emi;
          index = index + 1;
        });
        this.totalData.totalLoanAmount = totalLoanAmount;
        this.totalData.totalOutstandingBalance = totalOutstandingBalance;
        this.totalData.totalEmi = totalEmi;
    }catch(e){
        console.log('error message ',e.message);
    }
       
        

        

    }
    handleResetClick() {
      if(this.fromSales ==true ){
        event.stopPropagation();
       }
        this.applicantType = 'All';
        this.securityType = 'All';
        this.loanType = 'All';
        this.applicantValue = 'All';
        console.log('recordid ',this.recordId);
        this.getObligationData();
    }

    createRow(listOfRecords) {
        let rowObject = {};
        if(listOfRecords.length > 0) {
            rowObject.srNo = listOfRecords[listOfRecords.length - 1].srNo + 1;
        } else {
            rowObject.srNo = 1;
        }
        if(this.addNewList.length > 0) {
            rowObject.srNo = rowObject.srNo + this.addNewList.length;
        }
        rowObject.startDate = null;
        rowObject.financer = null;
        rowObject.loanType = null;
        rowObject.loanAmount = null;
        rowObject.outstandingBalance = null;
        rowObject.emi = null;
        rowObject.tenure = null;
        rowObject.repaymentBank = null;
        rowObject.balanceTenure = null;
        rowObject.remarks = null;
        rowObject.reClasificationReason = null;
        rowObject.isBanking = false;
        rowObject.isObligation = true;
        rowObject.securityType = null;
        rowObject.customerName = null;
        rowObject.customerType = null;
        rowObject.intDetRecordId = null;
        rowObject.emiBounce = null;
        this.addNewList.push(rowObject);
        this.isNewRow = true;
    }
    handleInputChange(event) {
      if(this.fromSales ==true ){
        event.stopPropagation();
      }
        let index = event.target.dataset.id;
        let fieldName = event.target.name;
        let value = event.target.value;
        let date = new Date();
        console.log('date ',value);
        console.log('today ',this.maxDate);
        if(fieldName == 'startDate') {
          if(value > this.maxDate) {
            this.showToastMessage('Error', 'Please select current or past date.', 'error');
            event.target.value = '';
            return;
          }
         
        }

        for(let i = 0; i < this.addNewList.length; i++) {
            if(this.addNewList[i].srNo === parseInt(index)) {
                this.addNewList[i][fieldName] = value;
            }
        }
    }

    handleChildChange(event) {
      if(this.fromSales ==true ){
        event.stopPropagation();
      }
      let index = event.target.dataset.id;
      let fieldName = event.target.name;
      let value = '';
      console.log('index ',index);
      console.log('this.filteredList: '+this.filteredList);

      if(event.target.checked){
        value = 'Obligated';

        for(let i = 0; i < this.addNewList.length; i++) {
          
          if(this.addNewList[i].srNo == index) {
              console.log('553');
              this.addNewList[i][fieldName] = true;
              this.addNewList[i]['remarks'] = value;
            }
        }
        // this.filteredList[index-1].isObligation = true;
      }
      else{
        value = '';

        for(let i = 0; i < this.addNewList.length; i++) {
          
          if(this.addNewList[i].srNo == index) {
              console.log('565');
              this.addNewList[i][fieldName] = false;
              this.addNewList[i]['remarks'] = value;
          }
        }
        // this.filteredList[index-1].isObligation = false;
      }
    }

    handleStatusChange(event) {
      if(this.fromSales ==true ){
        event.stopPropagation();
      }
      this.statusValue = event.detail.value;
      console.log(event.target.dataset.id);
  }
    //
    handleChildExistingChange(event) {
      if(this.fromSales ==true ){
        event.stopPropagation();
      }
      let index = event.target.dataset.id;
      let fieldName = event.target.name;
      let value = '';
      console.log('index ',index);
      //this.recordData 
      if(event.target.checked){
        value = 'Obligated';

        for(let i = 0; i < this.recordData.length; i++) {
          if(this.recordData[i].intDetRecordId === index) {
              this.recordData[i][fieldName] = true;
              this.recordData[i]['remarks'] = value;
          }
        }
      }else{
        value = '';

        for(let i = 0; i < this.recordData.length; i++) {
          if(this.recordData[i].intDetRecordId === index) {
              this.recordData[i][fieldName] = false;
              this.recordData[i]['remarks'] = value;
          }
        }
      }

      const fields = {};
        fields['Id'] = index;
        fields['Credit_Remarks__c']=value;
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
        .then(() => {
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });

    }

    handleStatusChangeExisting(event) {
      if(this.fromSales ==true ){
        event.stopPropagation();
    }
      let value = event.detail.value;
      let index = event.target.dataset.id;
      let fieldName = event.target.name;
      for(let i = 0; i < this.recordData.length; i++) {
        if(this.recordData[i].intDetRecordId === index) {
            this.recordData[i][fieldName] = value;
        }
    }

      console.log('value ',value ,' index ',index ,' field name ',fieldName);
  }
  handleInputFocus(event) {
    if(this.fromSales ==true ){
      event.stopPropagation();
    }
    console.log(event.target.value);
    let value = event.target.value;
      let index = event.target.dataset.id;
      let fieldName = event.target.name;
      console.log('value ',value ,' index ',index ,' field name ',fieldName);
      for(let i = 0; i < this.recordData.length; i++) {
        if(this.recordData[i].intDetRecordId === index) {
          console.log(this.recordData[i]);
            this.recordData[i][fieldName] = value;
        }
    }
  }
  //
    handleSaveClick(event) {
      if(this.fromSales ==true ){
        event.stopPropagation();
       }
        console.log('existing lst ',JSON.stringify(this.recordData));
        console.log('new lst ',JSON.stringify(this.addNewList)); 
       
        if(this.addNewList.length > 0) {
          for(let i = 0; i < this.addNewList.length; i++) {
            if(this.addNewList[i].startDate == null || this.addNewList[i].startDate == '') {
                this.showToastMessage('Error', 'Please enter start date.', 'error');
                return;
            }
            // else if(this.addNewList[i].startDate != null){
            //   if(this.addNewList[i].startDate > this.maxDate) {
            //     this.showToastMessage('Error', 'Please select current or past date.', 'error');
            //     return;
            //   }
            // }
            else if(this.addNewList[i].customerName == null || this.addNewList[i].customerName == '') {
              this.showToastMessage('Error', 'Please select applicant.', 'error');
              return;
            }
            else if(this.addNewList[i].loanType == null || this.addNewList[i].loanType == '') {
              this.showToastMessage('Error', 'Please select loan type.', 'error');
              return;
            }
            else if(this.addNewList[i].loanAmount == null || this.addNewList[i].loanAmount == '') {
              this.showToastMessage('Error', 'Please fill correct loan amount.', 'error');
              return;
            }
            else if(this.addNewList[i].outstandingBalance == null || this.addNewList[i].outstandingBalance == '') {
              this.showToastMessage('Error', 'Please fill correct outstanding balance.', 'error');
              return;
            }
            else if(this.addNewList[i].emi == null || this.addNewList[i].emi == '') {
              this.showToastMessage('Error', 'Please fill correct emi.', 'error');
              return;
            }
            else if(this.addNewList[i].securityType == null || this.addNewList[i].securityType == '') {
              this.showToastMessage('Error', 'Please select select security type', 'error');
              return;
            }
            // else if(this.addNewList[i].repaymentBank == null || this.addNewList[i].repaymentBank == '') {
            //   this.showToastMessage('Error', 'Please fill repayment bank.', 'error');
            //   return;
            // }
            if(this.addNewList[i].repaymentBank != null || this.addNewList[i].repaymentBank != '') {
              if(!textValidation(this.addNewList[i].repaymentBank)){
                this.showToastMessage('Error', 'Bank name can not be numeric.', 'error');
                return;
              }
            }
            else if(this.addNewList[i].emiBounce == null || this.addNewList[i].emiBounce == '') {
              this.showToastMessage('Error', 'Please fill correct emi bounce.', 'error');
              return;
            }
            else if(this.addNewList[i].balanceTenure == null || this.addNewList[i].balanceTenure == '') {
              this.showToastMessage('Error', 'Please fill correct balance tenure.', 'error');
              return;
            }
        }
        }
        this.upsertRecords();
    }

    upsertRecords() {
      upsertObligationRec({
        recordId: this.recordId,
        existingLst:JSON.stringify(this.recordData),
        newLst:JSON.stringify(this.addNewList)
      })
        .then((response) => {
          console.log("customer details=:" + JSON.stringify(response));
          this.getObligationData();
          this.addNewList = [];
          this.showToastMessage('Success', 'Obligation(s) is updated!.', 'success');
          
        })
        .catch((error) => {});
    }
    showToastMessage(title, message, type) {
      const toastEvent = new ShowToastEvent({
          title: title,
          message: message,
          variant: type
      });
      this.dispatchEvent(toastEvent);
   }
    
   handleBlurEMI(event) {
    let value = event.target.value;
    let index = event.target.dataset.id;
    let fieldName = event.target.name;
    console.log('value ',value ,' index ',index ,' field name ',fieldName);
    const fields = {};
        fields['Id'] = index;
        fields['Imputed_EMI__c']=value;
        fields['EMI_Updated__c']=true;
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
        .then(() => {
          this.getObligationData();
          this.showToastMessage('Success', 'Record updated successfully', 'success');
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
   }
   handleStatusChangeExistingSecurity(event) {
    


        let value = event.target.value;
    let index = event.target.dataset.id;
    let fieldName = event.target.name;
    console.log('value ',value ,' index ',index ,' field name ',fieldName);
    const fields = {};
    fields['Id'] = index;
    fields['Secured_Unsecured__c']=value;
    fields['Security_Type_Updated__c']=true;
    const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
        .then(() => {
          this.getObligationData();
             this.showToastMessage('Success', 'Record updated successfully', 'success');
            // this.getData();
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
   }

   handleChangeRemarks(event) {
        let value = event.target.value;
        let index = event.target.dataset.id;
        let recordType = event.target.dataset.recordtype;
        let fieldName = event.target.name;
        console.log('value ',value ,' index ',index ,' field name ',fieldName);

        if(recordType == 'existing'){
          for(let i = 0; i < this.recordData.length; i++) {
            if(this.recordData[i].intDetRecordId == index) {
                this.recordData[i]['remarks'] = value;
                console.log('recordData updated for existing:', index, value);
            }
        }
          const fields = {};
          fields['Id'] = index;
          fields['Credit_Remarks__c']=value;
          const recordInput = { fields };
          console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
          updateRecord(recordInput)
              .then(() => {
          })
          .catch(error => {
              console.log('Error updating record --> '+JSON.stringify(error));
          });
        }
        else{
            for(let i = 0; i < this.addNewList.length; i++) {
              
              if(this.addNewList[i].srNo == index) {
                  console.log('979');
                  this.addNewList[i]['remarks'] = value;
                }
            }
        }
   }

    handleDeleteDoc(event){
      // if(this.addNewList.includes(event.target.dataset.key)){
      //     this.addNewList.pop(event.target.dataset.key);
      // }

      const srno= event.target.dataset.id;
      console.log('srno---', srno);
      
       this.addNewList = this.addNewList.filter(item =>
            item.srNo != srno
        );
    }

    handleDeleteDocOblig(event){
      const obligationId = event.target.dataset.id;
      deleteObligation({obligationId: obligationId})
      .then(() => {

        this.getObligationData();
        this.showToastMessage('Success', 'Obligation deleted successfully', 'success');
        // this.getData();
      })
      .catch(error => {
          console.log('Error deleting record --> '+JSON.stringify(error));
      });
    }

    subscribeToPlatformEvent() {
      console.log('Platform event received, refreshing...');
      subscribe(this.channelName, -1, (response) => {
          const updatedRecordId = response.data.payload.Loan_Application_Id__c;
          if (updatedRecordId === this.recordId) {
              
            this.getObligationData();
          }
      }).then((response) => {
          this.subscription = response;
          console.log('Subscribed to platform event:', response.channel);
      });
  }
  
    registerErrorListener() {
        onError((error) => {
            console.error('EMP API error: ', error);
        });
    }
  
    disconnectedCallback() {
        unsubscribe(this.subscription, (response) => {
            console.log('Unsubscribed: ', response);
        });
    }
    handleHeaderInput(event) {
    const api = event.currentTarget.dataset.api;
    const newValue = event.target.value;

    this.monthDateHeaders = this.monthDateHeaders.map(h => {
        if (h.apiName === api) {
            return { ...h, dateValue: newValue };
        }
        return h;
    });
}
handleHeaderInput(event) {
    const api = event.currentTarget.dataset.api;
    const newValue = event.target.value;

    this.monthDateHeaders = this.monthDateHeaders.map(h => {
        if (h.apiName === api) {
            return { ...h, dateValue: newValue };
        }
        return h;
    });
}
handleSaveHeader(event) {
    const api = event.currentTarget.dataset.api;
    console.log('api ',api);
    // Switch off edit mode
    this.monthDateHeaders = this.monthDateHeaders.map(h => {
        if (h.apiName === api) {
            this.saveMonthHeader(api, h.dateValue);
            return { ...h, isEditing: false };
        }
        return h;
    });

    // TODO: Call Apex to save later
    console.log("Saved updated month header:", api);
}
saveMonthHeader(api, dateValue) {
    console.log('api ',api);
    console.log('dateValue ',dateValue);
    savemonthHead({
      loanId : this.recordId,
      apiName : api,
      dateValue : dateValue
    })
    .then(result => {
     if(result){
       this.showToastMessage('Success', 'Record updated successfully', 'success')
     }
    })
}
handleMonthValueInput(event) {
    const api = event.target.dataset.api;
    const recId = event.target.dataset.record;
    const newVal = event.target.value;
    console.log('api ',api);
    console.log('recId ',recId);
    console.log('newVal ',newVal);
    saveMonthValue({ recordId: recId, apiName: api, newValue: newVal })
        .then(() => {
           console.log('Record updated successfully : '+api+' '+newVal);
        })
        .catch(err => {
        });
}
handleMonthValueChange(event) {
    const input = event.target;
    let value = input.value;
    if (value && value.length > 22) {
        // Trim back to 30
        input.value = value.substring(0, 22);
        // Toast message
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Limit Exceeded',
                message: 'Character Limit Exceeded!',
                variant: 'error'
            })
        );
    }
}
   handleEditHeader(event) {
    const api = event.currentTarget.dataset.api;

    // Clone array to trigger reactivity
    this.monthDateHeaders = this.monthDateHeaders.map(h => {
        if (h.apiName === api) {
            return { ...h, isEditing: true };
        }
        return h;
    });
}
    
}