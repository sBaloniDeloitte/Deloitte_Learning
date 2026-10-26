import { LightningElement, api, track } from 'lwc';

export default class ConfirmationScreen extends LightningElement {
    
    @api confirmMessage;
    @api negativeLabel;
    @api positiveLabel;
    @api headerTitle = 'Confirmation Screen';
    @api widthPercentage = '';      //pass the value in number only

    @track modalVisibility = false;

    cssContainer = 'slds-modal__container';

    renderedCallback(){

        switch(this.widthPercentage) {
            case '60':
                this.cssContainer = 'slds-modal__container width-60';
                break;
            case '70':
                this.cssContainer = 'slds-modal__container width-70';
                break;
            case '80':
                this.cssContainer = 'slds-modal__container width-80';
                break;
            case '90':
                this.cssContainer = 'slds-modal__container width-90';
                break;
            case '95':
                this.cssContainer = 'slds-modal__container width-95';
                break;
        }
    }

    connectedCallback(){
        this.modalVisibility = true;
    }

    handleNegative(){
        this.modalVisibility = false;
        const valueCloseEvent = new CustomEvent('negativeclick', {});
        this.dispatchEvent(valueCloseEvent);
    }

    handlePositive(){
        const valueCloseEvent = new CustomEvent('positiveclick', {});
        this.dispatchEvent(valueCloseEvent);
    }
}