import { LightningElement, api, track } from 'lwc';
import getAllApplicants from "@salesforce/apex/LegalEntityCheckController.getAllApplicants";
import getLegalEntityCheckdata from "@salesforce/apex/LegalEntityCheckController.getLegalEntityCheckdata";
import createInputMap from "@salesforce/apex/LegalEntityCheckController.createInputMap";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';

export default class LegalEntityCheckView extends LightningElement {
    @api recordId;
    @track applicants = [];
    @track leiList = [];
    @track selectedLeiData = null;
    @track showModal = false;
    @track spinner = false;
    hideButton = false;

    connectedCallback(){
        this.checkCmpEditability();

        this.getAllApplicants();
    }

    checkCmpEditability() {
    getComponentEditability({ loanId : this.recordId, component : 'videoPDCmp' })
    .then(result => {
        if(result){
            //this.isNotEditable = result;
            this.hideButton = result;
            console.log('this.hideButton>>>>'+this.hideButton);
           // this.editability = result;
        }
    })
    .catch(error => {
        console.log('Error getComponentEditability:  '+error);
    });
  }

    getAllApplicants(){
        getAllApplicants({
            loanId: this.recordId
        })
        .then(response => {
            this.applicants = response;
            console.log('getAllApplicants result : '+JSON.stringify(this.applicants));
            this.getLegalEntityCheckdataList();
        })
        .catch(error => {
            console.error('Error getAllApplicants : ', JSON.stringify(error));
        });
    }
    
    getLegalEntityCheckdataList(){
        getLegalEntityCheckdata({loanId: this.recordId})
        .then(response => {
            this.leiList = response;
            console.log('Response getLegalEntityCheckdata', JSON.stringify(this.leiList));
            this.applicants = this.applicants.map(applicant => {
                const match = this.leiList.find(item => item.applicantId === applicant.applicantId);
                const returnedLei = match?.result?.entityRecordDetail?.registeredEntityDetails?.lei;
                const isEmptyOrDash = !applicant.legalEntityNumber || applicant.legalEntityNumber === '-';
                return {
                    ...applicant,
                    matchedLei: returnedLei,
                    // showGenerate: !applicant.legalEntityNumber || applicant.legalEntityNumber !== returnedLei
                    showGenerate: isEmptyOrDash || applicant.legalEntityNumber !== returnedLei
                };
            });
        }).catch(error => {
            console.error('Error getLegalEntityCheckdata : ' + JSON.stringify(error));
        });
    }

    handleViewLei(event) {
        this.spinner = true;
        const applicantId = event.target.dataset.id;
        console.log('applicantId : '+applicantId);
        const match = this.leiList.find(lei => lei.applicantId === applicantId);
        setTimeout(() => {
            if (match) {
                this.selectedLeiData = match;
                console.log('selectedLeiData : '+JSON.stringify(this.selectedLeiData));
                console.log('this.selectedLeiData.result.entityRecordDetail.entityIdentifiers.entityStatus : '+ this.selectedLeiData.result.entityRecordDetail.entityIdentifiers.entityStatus);
                setTimeout(() => {
                    this.setVisibility();
                }, 1000);
            }
        }, 500);
    }

    handleGenerate(event) {
        this.spinner = true;
        const applicantId = event.target.dataset.id;
        console.log('handleGenerate applicantId : '+applicantId);

        const applicant = this.applicants.find(app => app.applicantId === applicantId);
        const isEmptyOrDash = !applicant?.legalEntityNumber || applicant.legalEntityNumber === '-';
        if (!applicant || isEmptyOrDash) {
            this.spinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Legal Entity Number not found for this applicant. Please update and try again.',
                    variant: 'error'
                })
            );
            return;
        }

        createInputMap({loanId : this.recordId, processName : 'Loan Legal Entity', appId : applicantId})
        .then(response => {
            if (response == 'success') {
                // this.getLegalEntityCheckdataList();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'LEI Generated successfully.',
                        variant: 'success'
                    })
                );
                setTimeout(() => {
                    this.getLegalEntityCheckdataList();
                    // this.handleViewLei(event);
                    this.spinner = false;
                }, 200);
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Something went wrong. Please try again in sometime.',
                        variant: 'error'
                    })
                );
                setTimeout(() => {
                    this.getLegalEntityCheckdataList();
                    this.spinner = false;
                }, 200);
            }
        }).catch(error => {
            console.error('Error handleGenerate : ' + JSON.stringify(error));
            this.spinner = false;
        });
    }

    setVisibility() {
        console.log('this.selectedLeiData.result : '+ JSON.stringify(this.selectedLeiData.result));
        console.log('this.selectedLeiData.result.registeredEntityDetails.lei : ' +this.selectedLeiData.result.entityRecordDetail.registeredEntityDetails.lei);
        setTimeout(() => {
            this.showModal = true;
            this.spinner = false;
        }, 1000);
    }

    closeModal() {
        this.showModal = false;
        this.selectedLeiData = null;
        this.spinner = false;
    }
}