import { LightningElement,track,api,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import checkQuickSanction from '@salesforce/apex/HL_QuickSanctionController.checkQuickSanction';
import getLoanDetails from '@salesforce/apex/HL_QuickSanctionController.getLoanDetails';
import initiateAPIRequest from '@salesforce/apex/HL_EligibilityApiController.initiateAPIRequest';
export default class Hl_QuickSanctionCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @track showErrorList = false;
    @track errorList = [];
    showLoader = false;
    showMessage;
    showSuccessMessage;
    @api checkBreApi = false;
    cssStyle='max-width: 100%;min-width:100%';
    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef) {
            this.recordId = pageRef.state.recordId || this.recordId;
            console.log('Record Id from URL:', this.recordId);
        }
    }
    connectedCallback() {
        console.log('inside bre');
        if(this.checkBreApi){
            this.cssStyle = 'max-width: 1%;min-width:40%'
        }
        this.checkQuickSanction();
    }
    checkQuickSanction(){
         console.log('inside bre 22');
        this.showLoader = true;
        const inputWrap={
            'loanId': this.recordId,
            'fromSalesToCredit':this.checkBreApi
        }
        checkQuickSanction({
            inputWrapStr : JSON.stringify(inputWrap)
        }).then((result) => {
            console.log('result---', result);
            
            if(result.isQuickSanctionValid){
                //call bre api
                getLoanDetails({
                    loanId: this.recordId
                }).then(result=>{
                    console.log('result----', result);
                    
                    if(result.productName != null && result.productName != undefined && result.productName != ''){
                        console.log('at 51');
                        
                        const inputmap={
                            'loanId' : this.recordId,
                            'productId' : result.productId,
                            'productName':result.productName,
                            'isIncomeFromSales':'true',
                            'processName':'Credit Eligibility HL',
                        }
                        initiateAPIRequest({
                            inputMap: inputmap
                        }).then(result=>{
                             console.log('inside bre 22'+JSON.stringify(result));
                            if(result.includes('success')){
                                this.showLoader = false;
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Success',
                                        message: 'BRE triggered successfully',
                                        variant: 'success',
                                    }),
                                );
                                this.showMessage = "Please click on Proceed to continue";
                                this.showSuccessMessage =true;
                                // setTimeout(()=>{
                                //     this[NavigationMixin.Navigate]({
                                //         type: 'standard__recordPage',
                                //         attributes: {
                                //             recordId: this.recordId,
                                //             objectApiName: 'Opportunity',
                                //             actionName: 'view'
                                //         }
                                //     });
                                // },1000)
                            }
                            else{
                                this.showLoader = false;
                                // this.dispatchEvent(
                                //     new ShowToastEvent({
                                //         title: 'Error',
                                //         message: result,
                                //         variant: 'error',
                                //     }),
                                // );
                                
                                let errorArray = [];
                                if (typeof result === 'string') {
                                    errorArray = result.split(/[\n,]+/).map(e => e.trim()).filter(e => e);
                                }
                                this.errorList = errorArray.map(err => ` ${err}`);
                                this.showErrorList=true;
                            }
                        }).catch(error=>{
                            this.showLoader = false;
                            console.log('errorr--', error);
                            
                        })
                    }
                    else{
                        this.showLoader = false;
                        this.errorList = result.errorList;
                        this.showErrorList = true;
                    }
                }).catch(error=>{
                    this.showLoader = false;
                })
            }
            else{
                this.showLoader = false;
                this.errorList = result.errorList;
                this.showErrorList = true;
            }
        }).catch((err) => {
            this.showLoader = false;
        });
    }
    handleClose(){
        if(!this.checkBreApi){
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Opportunity',
                    actionName: 'view'
                }
            });
        }
        else{
            const screenChangeEvent = new CustomEvent('closescreen', {
                detail: { }
            });
            this.dispatchEvent(screenChangeEvent);
        }
    }
    handleCloseSuccess(){
        this.showSuccessMessage=false;
        if(!this.checkBreApi){
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Opportunity',
                    actionName: 'view'
                }
            });  
        }  
        else{
            const screenChangeEvent = new CustomEvent('closescreen', {
                detail: { }
            });
            this.dispatchEvent(screenChangeEvent);
        }                  
    }
    handleProceed(event){
        const screenChangeEvent = new CustomEvent('handleproceed', {
            detail: { }
        });
        this.dispatchEvent(screenChangeEvent);
    }
}