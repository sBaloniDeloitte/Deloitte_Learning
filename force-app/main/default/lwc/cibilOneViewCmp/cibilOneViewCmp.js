import {LightningElement,track,api,wire} from "lwc";
//import getLiveLoanData from "@salesforce/apex/CamScreenController.getLiveLoanData";
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
//import getApprovalStatus from '@salesforce/apex/Utility.getApprovalStatus';
import { getRecord } from 'lightning/uiRecordApi';
import APPROVAL_STATUS from '@salesforce/schema/Opportunity.Approval_Status__c';
const FIELDS = [APPROVAL_STATUS];
export default class CibilOneViewCmp extends LightningElement {
    @api recordId;
    @api appId;
    @api fromSales = false;

    @track recordData = [];
    @track accordionKey = 0;
    @track isAccordionReady = false;
    @track fieldDetails = [];
    @track activeSections = [];

    @track disableEdit = false;

    @track showGeneratedReport = false;

    @track error = "";

    @track leadDetails = "";
    @track allSectionNames = [];
    @track customerDetails = {};
    @track isRendered = false;
    @track profileName= '';
    @track isDisabled = false;
    @track enableTab= true;
    @api isSeller=false;
    isCrifDisabled = true;
    fromSalesCrif = true;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredOpportunity({ data, error }) {
        if (data) {
            if(data.fields.Approval_Status__c.value == 'Hard Rejected' || data.fields.Approval_Status__c.value == 'Soft Rejected 1' || data.fields.Approval_Status__c.value == 'Soft Rejected 2' || data.fields.Approval_Status__c.value == 'Rejected'){
                console.log('new disabled');
                this.isDisabled = true;
            }
        } else if (error) {
            console.error(error);
        }
    }

    connectedCallback() {
        console.log("Inside connectedCallback----31 cili cmp",this.fromSales);
        this.fetchLoanStage();
        //this.fetchApprovalStatus();
        //this.getLiveAndClosedLoanData();
        getCurrentUserProfileName({
        })
        .then((response) => {
            console.log("response in getCurrentUserProfileName=:" + response);
            this.profileName = response;
            if(this.profileName == 'Sales'){
                //this.fromSales=true;
            }
        })
        
        .catch((error) => {});

        console.log("Inside connectedCallback----48 cili cmp",this.fromSales);
        
    }
    getLiveAndClosedLoanData() {
        getLiveLoanData({
                loanId: this.recordId,
            })
            .then((response) => {
                console.log("response customer details=:" + JSON.stringify(response));
                this.recordData = response;
            })
            .catch((error) => {});
    }

    fetchLoanStage() {
        getLoanStage({ loanId: this.recordId })
          .then(result => {
            console.log('Result1', result);
            if(result == 'PSV' || result == 'Disbursement') {
                this.fromSales = true;
            }
          })
          .catch(error => {
            console.error('Error:', error);
        });
    }

    /*fetchApprovalStatus() {
        getApprovalStatus({ loanId: this.recordId })
          .then(result => {
            console.log('Result2', result);
            if(result == 'Hard Rejected'){
                this.enableTab = false;
            }
            else{
                this.enableTab = true;
            }
          })
        }*/
    renderedCallback() {
        if (!this.isRendered) {
            // Create and append styles dynamically
            const style = document.createElement("style");
            style.innerText = `
            .main-tab .slds-tabs_default__nav{
                display: flex;
                border:none;
            
            }
                .slds-dropdown-trigger_click .slds-dropdown, .slds-dropdown-trigger_click:hover .slds-dropdown, .slds-dropdown-trigger--click .slds-dropdown, .slds-dropdown-trigger--click:hover .slds-dropdown{
                background-color: #16283f !important;
                color : white !important;
            }
            .slds-listbox_vertical .slds-listbox__option:focus, .slds-listbox_vertical .slds-listbox__option.slds-has-focus, .slds-listbox--vertical .slds-listbox__option:focus, .slds-listbox--vertical .slds-listbox__option.slds-has-focus{
                background-color: #16283f !important;
                box-shadow : none !important;
                color : white !important;
            }
            .slds-button_brand , .slds-button_brand :hover{
            background-color: #1467eb !important;
            }
        `;

            // Append the styles to the .styleContainer
            this.template.querySelector(".styleContainer")?.appendChild(style);

            // Prevent re-adding styles
            this.isRendered = true;
        }
    }

    //c/aadharLoginFormUpdated
    value = 'Yash';

    get options() {
        return [
            { label: 'Akash', value: 'Akash' },
            { label: 'Yash', value: 'Yash' },
            { label: 'Vijaya', value: 'Vijaya' },
        ];
    }

    handleChange(event) {
         if(this.fromSales ==true ){
            event.stopPropagation();
            this.value = event.detail.value;
        }
        else{
            this.value = event.detail.value;
        }
     
    }
    handleTabClick(event){
        console.log("tab clicked" + this.fromSales);
      
            event.stopPropagation();
        
    }
}