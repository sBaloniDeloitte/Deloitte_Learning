import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getApplicantInformation from "@salesforce/apex/AMLCheckController.getApplicantInformation";
import initiateAMLCheck from "@salesforce/apex/AMLCheckController.initiateAMLCheck";
import {NavigationMixin} from 'lightning/navigation';
import { updateRecord } from "lightning/uiRecordApi";
import checkUserHavePsFcuSamplerPermissionSet from '@salesforce/apex/Utility.checkUserHavePsFcuSamplerPermissionSet';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';

export default class AmlCheckCmp extends NavigationMixin(LightningElement) {
    @api recordId;
      @track isRendered = false;
      @track spinner = false;
      @track selectedApplicants = []; 
      @track showInitiateButton = false;
      @track applicantAMLCheckRecords = [];
      @track userHavePsFcuSamplerPermissionSet = false;
      @track showAMLCheck = true;
      @track hideButton = false;
    
      get dispositionOptions() {
        return [
          { label: "DP1", value: "DP1" },
          { label: "DP2", value: "DP2" },
        ];
      }
    
      handleChange(event) {
        let val = event.detail.value;
        let index = event.target.dataset.id;
        let id = event.target.id;
        var recId = id.split('-');
        console.log('val =',val,', dataid =',index,', id =',recId[0]);
        
        const fields = {};
            fields['Id'] = recId[0];
            fields['Disposition__c']=val;
            const recordInput = { fields };
            console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
            updateRecord(recordInput)
            .then(() => {
                this.showToastMessage('Success', 'Record updated successfully', 'success');
                this.getAMLCheckRecords();
            })
            .catch(error => {
                console.log('Error updating record --> '+JSON.stringify(error));
            });
    
      }
    
      connectedCallback() {
        this.getAMLCheckRecords();
        this.handleCheckUserHavePsFcuSamplerPermissionSet();
        this.fetchLoanStage();
        this.checkCmpEditability();
      }

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

      handleCheckUserHavePsFcuSamplerPermissionSet() {
        checkUserHavePsFcuSamplerPermissionSet()
          .then(result => {
            console.log('Result2', result);
            this.userHavePsFcuSamplerPermissionSet = result;
          })
          .catch(error => {
            console.error('Error:', error);
        });
      }
    
      showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
          title: title,
          message: message,
          variant: type,
        });
        this.dispatchEvent(toastEvent);
      }
    
      getAMLCheckRecords() {
        this.spinner = true;
        getApplicantInformation({
          recordId: this.recordId,
        })
          .then((response) => {
            console.log("applicantAMLCheckRecords" + JSON.stringify(response));
            this.applicantAMLCheckRecords = response;
    
            this.spinner = false;
          })
          .catch((error) => {});
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
    
      downloadAMLReport(event) {
        let index = event.target.dataset.id;
        console.log("index ", index);
        let name = 'B';
        const combo = this.template.querySelectorAll(`[data-id="${index}"]`);
        console.log('combo ',combo);
        for(var i = 0; i < combo.length; i++ ){
            combo[i].disabled = false;
        }
    
        
    
        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: event.target.dataset.id
            }
        })
        
      }
    
      handleChildExistingChange(event) {
        let index = event.target.dataset.id;
        console.log("index ", index);
          const boxes = this.template.querySelectorAll('lightning-input');
        for (var i = 0; i < boxes.length; i++) {
          console.log(boxes[i].dataset.id);
            if (boxes[i].type == 'checkbox' && boxes[i].dataset.id != index) {
                boxes[i].checked = false;
            }
        }


         this.selectedApplicants = [];

        //this.recordData
        if (event.target.checked) {
          this.selectedApplicants.push(index);
        } else {
           this.selectedApplicants = [];
        }
        if (this.selectedApplicants.length > 0) {
            this.showInitiateButton = true;
          }
          else {
            this.showInitiateButton = false;
          }
      }
    
      hanldeInitaite() {
        this.spinner = true;
        initiateAMLCheck({
            applicantIds: this.selectedApplicants,
            recordId:this.recordId
        })
          .then((response) => {
            console.log('response in initaitee---', response);
            
            if(response== 'success'){
              this.hanldeRefresh();
              this.showToastMessage('Success','AML check initiated successfully!.','success');
            }else{
              this.showToastMessage('Error',response,'error');
            }

            this.spinner = false;

          })
          .catch((error) => {
            console.log('error in initaitee---', error);
          });
    
      }
      hanldeRefresh() {
    
        this.getAMLCheckRecords();
        this.showInitiateButton = false;
        this.selectedApplicants = [];
      }

        fetchLoanStage() {
    getLoanStage({ loanId: this.recordId })
      .then(result => {
        console.log('Result1', result);
        if (result == 'Credit Underwriting' || result == 'PSV' || result == 'Disbursement') {
            getCurrentUserProfileName()
            .then((res) => {
                console.log('res: '+res);
                if(res == 'Sales' || res == 'Ops') {
                    this.showAMLCheck = false;
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
}