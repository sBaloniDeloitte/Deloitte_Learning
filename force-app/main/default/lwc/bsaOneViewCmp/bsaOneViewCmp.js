import {
    LightningElement,
    track,
    api
} from "lwc";

//import getLiveLoanData from "@salesforce/apex/CamScreenController.getLiveLoanData";
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';

export default class BsaOneViewCmp extends LightningElement {
    @api recordId;

    @track activeTab = 'Select Bank';

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
    @track fromSales = false;
    @track profileName= '';
    @track hasLoanStagePsvOrDisbursement = false;
    @track hideButton = false;

    connectedCallback() {
        console.log("Inside connectedCallback");
        
        getCurrentUserProfileName({})
        .then((response) => {
            console.log("response in getCurrentUserProfileName=:" + response);
            this.profileName = response;
           /* if(this.profileName == 'Sales'){
                this.fromSales=true;
            }*/
            this.checkCmpEditability();

            console.log('profileName : '+this.profileName);
            console.log('fromSales : '+this.fromSales);
            
        })
        
        .catch((error) => {});
        //this.getLiveAndClosedLoanData();
        

        this.fetchLoanStage();
    }


    
        checkCmpEditability() {
        getComponentEditability({ loanId : this.recordId, component : '' })
        .then(result => {
            if(result){
                this.hideButton = result;
                if(this.hideButton) {
                   this.fromSales = true; 
                }
                console.log('this.hideButton>>>>'+this.hideButton);
            }
        })
        .catch(error => {
            console.log('Error getComponentEditability:  '+error);
        });
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
            if(result == 'Disbursement') {
                this.fromSales = true;
                this.hasLoanStagePsvOrDisbursement = true;
            }
          })
          .catch(error => {
            console.error('Error:', error);
        });
    }

    

    
    renderedCallback() {
        if (!this.isRendered) {
            // Create and append styles dynamically
            const style = document.createElement("style");
            style.innerText = `
            .main-tab .slds-tabs_default__nav{
                display: flex;
                align-items: center;
                justify-content: center;
                background: #0e1c30;
                border-bottom: 1px solid #33455e;
            }
            .main-tab .slds-tabs_default__link{
                color: rgba(255, 255, 255, 0.7) !important;
            }
            .main-tab .slds-tabs_default__item.slds-is-active .slds-tabs_default__link{
                color: #ffffff !important;
                border-bottom-color: #1467eb !important;
            }
            .main-tab .slds-tabs_default__content{
                background: #0a1524;
                color: #ffffff;
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
        this.value = event.detail.value;
    }
    @track selectedBanksId = [];
    handleAnalysisButtonClick(event) {
        console.log('inside handleAnalysisButtonClick',JSON.stringify(event.detail.bankIds));
        this.selectedBanksId = event.detail.bankIds;
        console.log('inside selectedBanksId',JSON.stringify(this.selectedBanksId));    
        this.activeTab = 'BSA';
    }
}