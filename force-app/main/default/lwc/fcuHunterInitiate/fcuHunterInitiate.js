import { LightningElement , api , track} from 'lwc';
import initiateHunter from '@salesforce/apex/HunterController.initiateHunter';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
export default class FcuHunterInitiate extends LightningElement {
    isModalOpen = false;
    selectedOption = '';
    isInitiateVisible = true;
    spinner = false;
    showToastMethod ='';
    @api recordId;

    radioOptions = [
        { label: 'Yes', value: 'yes' },
        { label: 'No', value: 'no' }
    ];

    openModal() {
        this.isModalOpen = true;
    }

    closeModal(event) {
        this.isModalOpen = false;
        this.dispatchEvent(new CustomEvent('handleclose', {}));
        this.dispatchEvent(new RefreshEvent());
    }

    handleRadioChange(event) {
        this.selectedOption = event.target.value;
        this.isInitiateVisible = this.selectedOption === 'yes'?false:true;
    }

    handleBack() {
        this.closeModal();
    }

    handleInitiateHunter() {
        //sppiner = true;
        this.spinner = true;
        initiateHunter({
            inputMap: {
                'recordId': this.recordId,
                'processName': 'Loan Applicant Hunter'
            }
        })
        .then((response) => {
            console.log('Hunter Initiated:', response);

            if (response && response.includes("Error")) {
                setTimeout(() => {
                this.spinner = false;
                this.showToastMessage('Error', response, 'error');  
                this.closeModal();
                },3000);
            } else {
                setTimeout(() => {
                    this.spinner = false;
                    this.showToastMessage('Success', 'Hunter initiated successfully.', 'success');
                    this.closeModal();
                }, 3000);
            }
        })
            .catch((error) => {
                console.error('Error initiating hunter:', error);
                this.spinner = false;
                this.showToastMessage('Error', 'An unexpected error occurred.', 'error');
                this.closeModal();
            });  
    
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