import { LightningElement, track, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getApplicants from "@salesforce/apex/COMM_ItrScreenController.getApplicants";
import saveManualPd from "@salesforce/apex/Comm_ManualPdController.saveManualPd";
import {NavigationMixin} from 'lightning/navigation';
import { updateRecord, getRecord } from "lightning/uiRecordApi";
import checkUserHavePsFcuSamplerPermissionSet from '@salesforce/apex/Utility.checkUserHavePsFcuSamplerPermissionSet';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";//sanwar(4/12/2025)
import canUserEditRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.canUserEditRecord';//sanwar(4/12/2025)

export default class MainPdCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @track activeSactions = ['Personal Discussion','Video PD','Tele PD','PD Summary'];
    @track isRendered = false;
    @track refresh = false;
    @track userHavePsFcuSamplerPermissionSet = false;
    @track oppSubStage = '';//sanwar(4/12/2025)
    @track hideButton = false;

    /* ____GenAI: Generated code starts here - hand-built accordion state.
       lightning-accordion-section renders its header inside its own fully
       encapsulated shadow root in this org: neither the SLDS custom-property
       styling hooks (--slds-c-accordion-color-background, etc.) nor external
       tag/class selectors with !important could repaint it (verified by
       deploying and hard-refreshing - zero visual change both times). The
       base component is replaced below with plain divs driven by this
       tracked state, matching the same pattern already used successfully in
       losPersonalDiscussion for its own accordion header.____ */
    @track physicalPdOpen = true;
    @track videoPdOpen = true;
    @track telePdOpen = true;

    get physicalPdIcon() {
        return this.physicalPdOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }
    get videoPdIcon() {
        return this.videoPdOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }
    get telePdIcon() {
        return this.telePdOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }

    togglePhysicalPd() {
        this.physicalPdOpen = !this.physicalPdOpen;
    }
    toggleVideoPd() {
        this.videoPdOpen = !this.videoPdOpen;
    }
    toggleTelePd() {
        this.telePdOpen = !this.telePdOpen;
    }
    /* ____GenAI: Generated code ends here____ */

    checkCmpEditability() {
    getComponentEditability({ loanId : this.recordId, component : '' })
    .then(result => {
        if(result){
            this.hideButton = result;
            console.log('this.hideButton>>>>'+this.hideButton);
        }
    })
    .catch(error => {
        console.log('Error getComponentEditability:  '+error);
    });
  }

    connectedCallback() {
        this.handleCheckUserHavePsFcuSamplerPermissionSet();
        this.checkCmpEditability();
        this.refresh = false;
    }

    //4/12/2025
    @wire(getRecord, {
        recordId: "$recordId",
        fields: [SUBSTAGE_FIELD]
    })
    oppRecord({ data, error }) {
        if (data) {
            console.log('Data',data);
            this.oppSubStage = data.fields.Sub_stage__c.value;
            console.log("Sub Stage:", this.oppSubStage);
            canUserEditRecord({ recordId: this.recordId })
            .then(result => {
                console.log('At 380');
                if(result && this.oppSubStage == 'Ops Author'){
                    console.log('At 382');
                    this.hideButton = true;
                }
            });
        } else if (error) {
            console.error(error);
        }
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
                padding: 10px 0px 10px 0px;
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
        `;

            // Append the styles to the .styleContainer
            this.template.querySelector(".styleContainer")?.appendChild(style);

            
            // Prevent re-adding styles
            this.isRendered = true;
        }
    }
    
    handleRefresh(event) {
       
        //this.template.querySelector("c-pd-summary-cmp").refreshCmp();
       
    }

    handleCheckUserHavePsFcuSamplerPermissionSet() {
        checkUserHavePsFcuSamplerPermissionSet()
          .then(result => {
            console.log('Result', result);
            this.userHavePsFcuSamplerPermissionSet = result;
          })
          .catch(error => {
            console.error('Error:', error);
        });
    }
}