import { LightningElement, track,api,wire } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getLeadCurrectStage from '@salesforce/apex/Comm_LeadManagementController.getLeadCurrectStage';
import { CurrentPageReference } from 'lightning/navigation';

export default class LeadStagePath extends LightningElement {
    @api recordId;
    @track value = 'Lead created';
    @track classname = '';
    @track progressStatusClass = 'slds-progress-bar__value oneCol'; 
    @track liClassNae = 'slds-progress__item slds-is-active';
    @track stepOneClass = 'slds-progress__item';
    @track steptwoClass = 'slds-progress__item';
    @track stepthreeClass = 'slds-progress__item';
    @track stepfourClass = 'slds-progress__item';
    @track dynamicCss = 'slds-progress-bar';
    @track leadSubStatus = 'Unsaved';
    @track showStatus = true;
    @track progressValue = 0;
    get options() {
        return [
            { label: 'Lead created', value: 'Lead created' },
            { label: 'Consent received', value: 'Consent received' },
            { label: 'Eligibility established', value: 'Eligibility established' },
            { label: 'Lead converted', value: 'Lead converted' },
        ];
    }
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('currentPageReference: ' + JSON.stringify(currentPageReference));
        console.log('currentPageReference.attributes.recordId: ' + JSON.stringify(currentPageReference.attributes.recordId));
        if (currentPageReference && !this.recordId) {
            this.recordId = currentPageReference.attributes.recordId;
        }
    }

    connectedCallback() {
        console.log('inside connected callback', this.recordId);
        if(this.recordId) {
            console.log('inside 30');
            this.loanLeadStage();
        }
        else{
            this.progressStatusClass = 'slds-progress-bar__value oneCol';
        }
        
        if(FORM_FACTOR === 'Large') {
            this.dynamicCss = 'slds-progress-bar';
        }
        else{
            this.dynamicCss = 'slds-progress-bar mobile';
        }
    }

    // loanLeadStage() {
    //     getLeadCurrectStage({ leadId: this.recordId })
    //     .then(result => {
    //         this.value = result;
    //         this.leadSubStatus = this.value['Lead_Sub_Status__c'];
    //         console.log('value: ' + JSON.stringify(this.value));
    //         console.log('status '+this.value.Status);
    //         console.log('Lead_Sub_Status__c '+this.value['Lead_Sub_Status__c']);
    //         if(this.leadSubStatus = 'Qualified'){
    //            this.showStatus = false;
    //         }
    //         if(this.value.Status == 'Open') {
    //             this.progressStatusClass = 'slds-progress-bar__value';
    //             this.stepOneClass = 'slds-progress__item slds-is-active';
    //         }
    //         else if(this.value.Status == 'Closed') {
    //             console.log('53 '+this.value);
    //             this.progressStatusClass = 'slds-progress-bar__value fourCom';
    //             this.stepOneClass = 'slds-progress__item';
    //             this.steptwoClass = 'slds-progress__item slds-is-active';
    //             this.stepthreeClass = 'slds-progress__item slds-is-active';
    //             this.stepfourClass = 'slds-progress__item slds-is-active';
    //         }

    //     })
    //     .catch(error => {
    //         console.error('Error loading lead status:', error);
    //     });
    // }
    loanLeadStage() {
    getLeadCurrectStage({ leadId: this.recordId })
        .then(result => {
            this.value = result;

            this.leadSubStatus = this.value['Lead_Sub_Status__c'];

            console.log('Lead Status:', this.value.Status);
            console.log('Lead Sub Status:', this.leadSubStatus);

            // Fix assignment bug
            if (this.leadSubStatus === 'Qualified') {
                this.showStatus = false;
            } else {
                this.showStatus = true;
            }

            // Reset everything first
            this.stepOneClass = 'slds-progress__item';
            this.stepfourClass = 'slds-progress__item';

            // OPEN STATE
            if (this.value.Status === 'Open') {
                this.progressValue = 0;

                this.stepOneClass =
                    'slds-progress__item slds-is-active';

                this.stepfourClass =
                    'slds-progress__item';

                // NO progress fill when lead is Open
                this.progressStatusClass =
                    'slds-progress-bar__value open-progress';

            }

            // CLOSED STATE
            else if (this.value.Status === 'Closed' || this.value.Status === 'Closed - Converted') {
                this.progressValue = 100;
                this.stepOneClass =
                    'slds-progress__item';

                this.stepfourClass =
                    'slds-progress__item slds-is-active';

                // FULL progress only when Lead is actually Closed
                this.progressStatusClass =
                    'slds-progress-bar__value closed-progress';

            }

            // Any other / unknown state
            else {

                this.stepOneClass =
                    'slds-progress__item';

                this.stepfourClass =
                    'slds-progress__item';

                this.progressStatusClass =
                    'slds-progress-bar__value open-progress';
            }
        })
        .catch(error => {
            console.error('Error loading lead status:', error);
        });
}

    isMobileDevice(){
        const userAgent = window.navigator.userAgent;
        return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(userAgent);
    }
    
    @api refreshChild(parentParam){
        console.log('from parent ',parentParam);
        this.recordId = parentParam.recordId;
        this.loanLeadStage();
    }
}