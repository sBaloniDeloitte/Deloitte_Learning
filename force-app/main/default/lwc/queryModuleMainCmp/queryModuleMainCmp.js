import { LightningElement,api ,track,wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from "lightning/navigation";


export default class QueryModuleMainCmp extends NavigationMixin (LightningElement)  {
    @api recordId
    isModalOpen= false;
      @track headerTitle= 'Assign Query';
      cssContainer = 'slds-modal__container width-70';
    cssContainerAssignModal =  'slds-modal__container width-70';

    @wire(CurrentPageReference)
        getPageReference(pageRef) {
            console.log('pageReference state', pageRef);
            if (pageRef.state.recordId || pageRef.attributes.recordId) {
                console.log('pageReference state', pageRef.attributes.recordId);
                // Check the state for the recordId parameter.
                this.recordId = pageRef.state.recordId || this.recordId || pageRef.attributes.recordId;
                console.log('RecordId', this.recordId);
                // For debugging:
                console.log('Record Id from URL:', this.recordId);
            }
        }
    connectedCallback() {
        this.isModalOpen = true;
        console.log('recordId in connected', this.recordId);
    }
    handleCloseModal(){
        this.isModalOpen = false;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
       
        
    }
    renderedCallback() {
        // Select and hide the close button
        const closeButton = this.template.querySelector('.slds-modal__close');
        if (closeButton) {
            closeButton.style.display = 'none';
        }
    }
}