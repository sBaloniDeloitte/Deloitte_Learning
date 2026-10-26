import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import getApprovalSataus from '@salesforce/apex/Utility.getApprovalSataus';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
export default class ApplicationVerifcationActionsCMp extends LightningElement {
    @api recordId;

    
  @api initiateHunterAction = false;
  @api initiateFCUAction = false;
  @api initiateFIAction = false;
  @api initiatePDAction = false;

  initiateFICmp = false;
  initiateFCUCmp = false;
  initiateHunterCmp = false;
  initiatePDFCmp = false;
  isHideButton = false;

  isHLRelated = false;

  connectedCallback(){
    this.fetchProducDetails();
    
  }

  fetchProducDetails(){
        var inputMapParam = {
            'oppId': this.recordId
        };

        getProductDetails({inputMap : inputMapParam})
        .then(result =>{
            console.log('result product: '+ JSON.stringify(result));
            this.isHLRelated = result.isHLRelated;
            console.log('this.isHLRelated>>'+this.isHLRelated);
            this.fetchLoanStage();
            if(this.isHLRelated){
                
            }
        })
        .catch(error=>{
            console.error('error in getting product: '+ error)
        })
    }

  fetchLoanStage() {
    getLoanStage({ loanId: this.recordId })
      .then(result => {
        console.log('Result1', result);
        if (result == 'Credit Underwriting' || result == 'PSV' || result == 'Disbursement') {
            getCurrentUserProfileName()
            .then((res) => {
                if(res == 'Sales' || res == 'Ops') {
                    this.isHideButton = true;
                }else if(!this.isHLRelated && (res == 'Credit Manager' || res == 'Credit Officer')) {
                    this.isHideButton = true;
                

                }
            })
            .catch((error) => {
                console.error('Error getCurrentUserProfileName --> '+ error);
            });
        } else {
          getCurrentUserProfileName()
            .then((res) => {
                if(res == 'Sales' || res == 'Ops' || res == 'Credit Manager') {
                    this.isHideButton = true;
                }
            })
            .catch((error) => {
                console.error('Error getCurrentUserProfileName --> '+ error);
            });
        }
      })
      .catch(error => {
        console.error('Error:', error);
    });
  }

  openPDModal(){
      this.initiatePDFCmp = true;
  }

  openModal() {
    this.initiateFICmp = true;
  }

  handleClose() {
    this.initiateFICmp = false;
  }
  openFCUModal() {
    console.log('FCU Modal Opened');
     getApprovalSataus({ loanId: this.recordId })
                .then((res) => {
                    console.log('res>>>'+res);
                    if(res == 'Soft Rejected 1' || res == 'Soft Rejected 2' ||res =='Hard Rejected') {
                    this.dispatchEvent(
                    new ShowToastEvent({
                    title: 'Error',
                    message: 'Verification cannot be initiated because the loan application status is Rejected',
                    variant: 'Error'
                })
                )
                  this.initiateFCUCmp = false;
                return;
                    }
                })
                .catch((error) => {
                    console.error('Error getCurrentUserProfileName --> '+ error);
                });
    this.initiateFCUCmp = true;
  }
  handleFCUClose() {
    this.initiateFCUCmp = false;
  }
  openHunterModal() {
    this.initiateHunterCmp = true;
  }
  handleHunterClose() {
    this.initiateHunterCmp = false;
  }
}