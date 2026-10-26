import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import LightningConfirm from "lightning/confirm";
import { NavigationMixin,CurrentPageReference } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import holdCase from "@salesforce/apex/AHL_HoldUnHoldController.holdCase";

export default class Ahl_OnHoldAndReleaseCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @track comment = '';
    @track isRendered = false;
    @track spinner = false;

    @track buttonname;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            
            this.buttonname = currentPageReference.attributes.apiName;
            console.log('buttonname:', this.buttonname);
            this.recordId = currentPageReference?.attributes?.recordId;
            if(this.buttonname.includes('Unhold')) {
                this.buttonname = 'UnHold';
            }else {
                this.buttonname = 'Hold'
            }
            console.log('buttonname:', this.buttonname);
            console.log('recordId:', this.recordId);

           
        }
    }

   

    connectedCallback() {
        
    }
    hasRendered = false;



    handleCommentChange(event) {
        console.log('comment in handle change----',  event.target.value);
        const value = event.target.value;
        const invalidPattern = /(%%-|&&-)/;
        if (invalidPattern.test(value)) {
            event.target.value = '';
            this.handletoastEvent('Invalid characters %%- and &&-.', 'Error', 'error');
            return;
        } else {
            this.comment = event.target.value;
            console.log('this.comment---', this.comment);
        }

    }

    handletoastEvent(msg, title, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        }));
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    hanldeInitaite() {
        console.log('this.comment----', this.comment);
        if (this.comment == '') {
            this.handletoastEvent('Please enter the comments', 'Error', 'error');
            return;
        }
       
        this.putOnHold();
    }

    renderedCallback() {
        if (!this.isRendered) {
            // Create and append styles dynamically
            const style = document.createElement('style');
            style.innerText = `
            .slds-modal__header{
                background-color: skyblue;
                color: black;
                font-weight: 500;
                padding: 5px;
            }

            .save-button,
            .cancel-button {
                color: white;
                font-weight: 400;
                border: none;
            }
            .slds-modal__footer{
                background-color: skyblue;
            }
    
    
            `;
    
            // Append the styles to the .styleContainer
            this.template.querySelector('.styleContainer')?.appendChild(style);
    
            // Prevent re-adding styles
            this.isRendered = true;
        }
    }

    putOnHold() {
        this.spinner = true;
        console.log('recordId: ' + this.recordId);
        holdCase({
          recordId: this.recordId,
          remarks : this.comment,
          actionName : this.buttonname
        })
          .then((response) => {
            console.log("customers=:" + JSON.stringify(response));
            if(response == 'success') {
                this.handletoastEvent('Case is put '+this.buttonname+' successfully!.', 'Success', 'success');
                this.closeModal();
                
            }else if(response == 'fail') {
                this.handletoastEvent('Unexpected error occured, contact your admin.', 'Error', 'error');            
            }else{
                this.handletoastEvent(response, 'Error', 'error');   
            }
            setTimeout(() => {
                window.location.reload();
            }, 500); // 3000 milliseconds = 3 seconds
            this.spinner = false;
          })
          .catch((error) => {
            this.spinner = false;
            console.log(JSON.stringify(error));
            this.handletoastEvent(error.message, 'Error', 'error');   
          });
    }

}