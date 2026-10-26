import { api, LightningElement, wire, track } from 'lwc';
import rejectLoan from '@salesforce/apex/CreditRejectLoanApplicationController.rejectLoan';
import getRejectionReasons from '@salesforce/apex/CreditRejectLoanApplicationController.getRejectionReasons';
import showcomments from '@salesforce/apex/CreditRejectLoanApplicationController.fetchComments';
import getApprovalStatus from '@salesforce/apex/CreditRejectLoanApplicationController.getApprovalStatus';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName1';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';

const columns = [
    { label: 'Approver Name', fieldName: 'Approvedby'},
    { label: 'Comments', fieldName: 'Comments' }
    
    
];

export default class RejectLoanApplicationCmp extends LightningElement {
    _selected = [];
    @api recordId;
    @track reasonPicklist =[];
    @track selectedOptions = [];
    @track showModal= false;
    data = [];
    columns = columns;
    showbox=false;
    detailedReason='';
    

    connectedCallback(){
        console.log('recordId in reject loan---', this.recordId);
        this.checkUserProfile();
        this.getComments();
        
    }
     _hideQuickActionClose = false;
    renderedCallback() {
        if (!this._themeStylesInjected) {
            // Dual-listbox (Available/Selected) and textarea internals
            // render inside the base lightning-dual-listbox/lightning-textarea
            // component's own shadow DOM, which scoped component CSS
            // cannot reach. Injecting a real global <style> tag (not
            // LWC-scoped) is the only way to recolor them. Only colors
            // changed here - open/select/scroll behavior is untouched.
            const style = document.createElement('style');
            style.innerText = `
                .slds-dueling-list__column .slds-listbox,
                .slds-dueling-list__options {
                    background-color: #16283f !important;
                    border: 1px solid #33455e !important;
                    color: #ffffff !important;
                }
                .slds-dueling-list__options .slds-listbox__option {
                    background-color: #16283f !important;
                    color: #ffffff !important;
                }
                .slds-dueling-list__options .slds-listbox__option:hover,
                .slds-dueling-list__options .slds-listbox__option:focus {
                    background-color: #1f3550 !important;
                    color: #ffffff !important;
                }
                .slds-dueling-list__options .slds-listbox__option[aria-selected="true"] {
                    background-color: #8b5cf6 !important;
                    color: #ffffff !important;
                }
                .slds-dueling-list__options::-webkit-scrollbar {
                    width: 8px;
                }
                .slds-dueling-list__options::-webkit-scrollbar-track {
                    background: #16283f !important;
                }
                .slds-dueling-list__options::-webkit-scrollbar-thumb {
                    background: #7a8795 !important;
                    border-radius: 5px;
                }
                .slds-dueling-list__options::-webkit-scrollbar-thumb:hover {
                    background: #9aa7b5 !important;
                }
                .slds-dueling-list__options,
                .slds-dueling-list__column .slds-listbox {
                    scrollbar-color: #7a8795 #16283f !important;
                    scrollbar-width: thin !important;
                }
                textarea.slds-textarea {
                    background-color: #16283f !important;
                    border: 1px solid #33455e !important;
                    color: #ffffff !important;
                }
                textarea.slds-textarea::placeholder {
                    color: #cfd8e6 !important;
                    opacity: 1 !important;
                }
            `;
            this.template.querySelector('.slds-modal__container')?.appendChild(style);
            this._themeStylesInjected = true;
        }
        if (!this._dualListboxHighlightBound) {
            // lightning-dual-listbox renders its options inside its own (native)
            // shadow root, which the <style> tag injected above cannot reach -
            // that's why aria-selected="true" never visibly highlighted. Instead
            // of a stylesheet, we react to the click/keyup that the base
            // component already uses to toggle aria-selected, then paint each
            // option's background directly (inline, !important) to match its
            // own current aria-selected state. Works for multi-select (every
            // option in that list is re-synced, not just the one clicked), and
            // only touches visual background/color - selection itself is still
            // entirely handled by the base component/handleChange as before.
            const dualListbox = this.template.querySelector('lightning-dual-listbox');
            if (dualListbox) {
                const syncOptionHighlight = (event) => {
                    const listEl = event.composedPath().find(
                        (node) => node && node.getAttribute && node.getAttribute('role') === 'listbox'
                    );
                    if (!listEl) {
                        return;
                    }
                    requestAnimationFrame(() => {
                        listEl.querySelectorAll('.slds-listbox__option').forEach((optionEl) => {
                            const isSelected = optionEl.getAttribute('aria-selected') === 'true';
                            if (isSelected) {
                                optionEl.style.setProperty('background-color', '#8b5cf6', 'important');
                                optionEl.style.setProperty('color', '#ffffff', 'important');
                            } else {
                                optionEl.style.removeProperty('background-color');
                                optionEl.style.removeProperty('color');
                            }
                        });
                    });
                };
                dualListbox.addEventListener('click', syncOptionHighlight);
                dualListbox.addEventListener('keyup', syncOptionHighlight);
                this._dualListboxHighlightBound = true;
            }
        }
         if (!this._hideQuickActionClose) {
        const style = document.createElement('style');

        style.innerText = `
            .slds-modal__close {
                display: none !important;
            }
        `;

        document.head.appendChild(style);
        this._hideQuickActionClose = true;
    }
}
    
   
    checkUserProfile() {
        getCurrentUserProfileName()
            .then(result => {
                this.userProfile = result;
                console.log('result test>>'+this.userProfile);
                this.showModal = true;
                if (this.userProfile === 'FCU Admin' || this.userProfile === 'FCU Executive' || this.userProfile === 'FI') {
                    this.showModal = false;
                    this.showToast('Error', 'You do not have the required permission to reject this loan.', 'error');
                    this.closeQuickAction();
                }
            })
            .catch(error => {
                console.error('Error checking user profile: ', error);
                this.showToast('Error', 'An error occurred while checking the user profile.', 'error');
            });
    }

    // Show toast message
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    getComments(){
        showcomments({loanId: this.recordId})
        .then(result => {
            if(result==''||result==null||result==undefined)
            {
                this.showbox=true;

            }
            this.data = result;
        })
        .catch(error => {
            this.error = error;
            console.log("On Loading Data Update ", error);
        });
    }
    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if (currentPageReference) {
            console.log(currentPageReference);
            this.recordId = currentPageReference.attributes.recordId;

            this.recordId = currentPageReference.state.recordId || this.recordId;
            // For debugging:
            console.log('Record Id from URL:', this.recordId);
        }
    }

    @wire(getRejectionReasons) 
    stateData({error, data}){
        console.log('data----->',data);
        if (data) {
            try {
                
                let options = [];  
                console.log('data --' + data);               
                for (var key in data) {
                    console.log('key --' + key);
                    console.log('data[key]' , data[key]);
                    options.push({ label: data[key], value: data[key]  });
                }
                this.reasonPicklist = options;
                console.log('this.reasonPiclist=:' + this.reasonPicklist);
            } catch (error) {
                console.error('check error here', error);
            }
        } else if (error) {
            console.error('check error here', error);
        }
    };


    handleChange(event){    
        console.log('in handle change');
        this.selectedOptions = event.detail.value;
        this._selected = event.detail.value;
        console.log('this.selectedOptions=:' ,this._selected);
    }

    handleChangeReason(event){
        this.detailedReason=event.target.value;
    }

    handleSave(event){
        if(this._selected==null||this._selected.length <=0){
            const event = new ShowToastEvent({
                title: 'Error!!',
                message:'Please select rejection reasons',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
    
        }else if(this.detailedReason==null||this.detailedReason==''|| this.detailedReason== undefined){
            const event = new ShowToastEvent({
                title: 'Error!!',
                message:'Please add detailed rejection reason',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);

        }else{
            console.log('this.selectedOptions====>',this.selectedOptions);
            rejectLoan({ loanId: this.recordId,
                reason:this._selected, 
                detailedReason: this.detailedReason
            })
            .then((result) => {
        
                console.log('inside handle save then block');
                console.log('in success' + JSON.stringify(result));
                
               if (result === 'success') {
            return getApprovalStatus({ loanId: this.recordId })
                .then((status) => {
                    /*this.dispatchEvent(new ShowToastEvent({
                        title: 'Success!!',
                        message: ``,
                        variant: '',
                        mode: 'dismissable'
                    }));*/

                    this.dispatchEvent(new CustomEvent('success', {
                        detail: {
                            status,
                            reasons: this._selected,
                            message: `Loan application has been ${status}`
                        },
                        bubbles: true,
                        composed: true
                    }));

                    this.showModal = false;
                    this.closeQuickAction();

                    // Optional: keep your hard refresh if you want
                    // eslint-disable-next-line no-eval
                    eval("$A.get('e.force:refreshView').fire();");
                });
        }else{
                    const event = new ShowToastEvent({
                        title: 'Error',
                        message: result,
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                    this.closeQuickAction();
                    this.showModal = false;
                }
            
            
                
            })
            .catch((error) => {
                this.error = error;
                console.log('in error' + JSON.stringify(this.error));
        
                const event = new ShowToastEvent({
                    title: 'Error!!',
                    message: JSON.stringify(this.error),
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
        
            });
        
            eval("$A.get('e.force:refreshView').fire();");
        }
    }

    handleClose(){
        this.showModal = false;
        this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
        this.closeQuickAction();
        window.load();
    
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}