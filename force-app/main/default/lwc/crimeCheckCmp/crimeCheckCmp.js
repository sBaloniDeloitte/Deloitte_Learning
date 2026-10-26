import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getAllApplicantsInfo from "@salesforce/apex/CrimeCheckController.getAllApplicantsInfo";
import initiateCrimeCheck from "@salesforce/apex/CrimeCheckController.initiateCrimeCheck";
import updateIsClicked from "@salesforce/apex/CrimeCheckController.updateIsClicked";
import {NavigationMixin} from 'lightning/navigation';
import { updateRecord } from "lightning/uiRecordApi";
import checkUserHavePsFcuSamplerPermissionSet from '@salesforce/apex/Utility.checkUserHavePsFcuSamplerPermissionSet';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import createCrimeCheckFile from "@salesforce/apex/CrimeCheckController.createCrimeCheckFile";
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';

export default class CrimeCheckCmp extends NavigationMixin(LightningElement) {
  @api recordId;
  @track disabledCmp = false;
  //@track appVerifId;
  @track isRendered = false;
  @track spinner = false;
  @track selectedApplicants = []; 
  @track showInitiateButton = false;
  @track refresh = false;
  @track sectionOpen = ['Crime Check Individual','Crime Check Non-individual'];
//@track isOpened= false;
  @track applicantCrimeCheckRecords = [];
  @track userHavePsFcuSamplerPermissionSet = false;
  showCrimeCheck = true;
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
            this.getCrimeCheckRecords();
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });

  }

  connectedCallback() {
    this.getCrimeCheckRecords();
    this.handleCheckUserHavePsFcuSamplerPermissionSet();
    this.fetchLoanStage();
    this.checkCmpEditability();
  }
  checkCmpEditability() {
    getComponentEditability({ loanId : this.recordId, component : '' })
    .then(result => {
        if(result){
            this.disabledCmp = result;
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
            console.log('Result1', result);
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

  getCrimeCheckRecords() {
    this.spinner = true;
    getAllApplicantsInfo({
      recordId: this.recordId,
    })
      .then((response) => {
        console.log("applicantCrimeCheckRecords" + JSON.stringify(response));
        this.applicantCrimeCheckRecords = response.map((item) => {
          const isOpen = this.sectionOpen.includes(item.applicantType);
          return {
            ...item,
            isOpen,
            chevronIcon: isOpen ? 'utility:chevrondown' : 'utility:chevronright',
          };
        });
       /*  
      this.isOpened = response.some(wrapper => 
        wrapper.applicantInfo.some(info => info.isClicked)
      );
      
      this.appVerifId = response.some(wrapper => 
        wrapper.applicantInfo.some(info => info.appvId)
      );
      this.updateIsClickedField(this.appVerifId, this.isOpened); 
      */

        if(this.refresh) {
          for (let key in this.applicantCrimeCheckRecords) {
           if(this.applicantCrimeCheckRecords[key].callbackNotReceived != '' && this.applicantCrimeCheckRecords[key].callbackNotReceived != null) {
            this.showToastMessage('Error',this.applicantCrimeCheckRecords[key].callbackNotReceived,'error');
           }
          }
        }
        this.refresh = false;
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

  downloadCrimeReport(event) {
    
    let index = event.target.dataset.id;
    let id = event.target.id;
    // const docPresent = event.target.dataset.present === 'true';
    const docPresent = event.target.dataset.present;
    const docLink = event.target.dataset.link;
    console.log('docPresent : '+docPresent);
    console.log('docLink : '+docLink);
    console.log("index ", index);
    
    updateIsClicked({ recordId: index })
    .then(() => {
      console.log('isClicked__c field updated successfully');
    })
    .catch((error) => {
      console.error('Error updating isClicked__c field:', error);
    });

    let name = 'B';
    const combo = this.template.querySelectorAll(`[data-id="${index}"]`);
    console.log('combo ',combo);
    for(var i = 0; i < combo.length; i++ ){
        combo[i].disabled = false;
    }

    
    if (docPresent == 'true') {
      console.log('inside docPresent --> '+index);
      this[NavigationMixin.Navigate]({ 
          type:'standard__namedPage',
          attributes:{ 
              pageName:'filePreview'
          },
          state:{ 
              selectedRecordId: index
          }
      })
    } else {
      this.createCrimeCheckDocument(docLink, id);
    }
    
  }

createCrimeCheckDocument(docLink, id) {
    this.spinner = true;
    createCrimeCheckFile({
        docLink: docLink,
        recordId: id
    })
    .then((response) => {
      this.spinner = false; 
      let contDoc = response;
      if (contDoc != null && contDoc != undefined && contDoc != '') {
        this[NavigationMixin.Navigate]({ 
          type:'standard__namedPage',
          attributes:{ 
              pageName:'filePreview'
          },
          state:{ 
              selectedRecordId: contDoc
          }
        })
      }
    })
    .catch((error) => {
      console.log('Error creating Crime Check file:', error);
      this.spinner = false;
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
     //this.selectedApplicants = [];
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
    initiateCrimeCheck({
        applicantIds: this.selectedApplicants,
        recordId:this.recordId
    })
      .then((response) => {
        if(response == 'success') {
          this.showToastMessage('Success','Crime check initiated successfully!.','success');
          this.getCrimeCheckRecords();
        }else {
          //this.showToastMessage('Error','Something went wrong. Please contact your admin.','error');
          this.showToastMessage('Error',response,'error');
          
        }
        
        this.spinner = false;
      })
      .catch((error) => {});

  }
  toggleSection(event) {
    const name = event.currentTarget.dataset.name;
    this.applicantCrimeCheckRecords = this.applicantCrimeCheckRecords.map((item) => {
      if (item.applicantType === name) {
        const isOpen = !item.isOpen;
        return { ...item, isOpen, chevronIcon: isOpen ? 'utility:chevrondown' : 'utility:chevronright' };
      }
      return item;
    });
  }
  hanldeRefresh() {
    this.refresh = true;
    this.getCrimeCheckRecords();
    this.showInitiateButton = false;
    this.selectedApplicants = [];
  }
  //sujit
  
    fetchLoanStage() {
    getLoanStage({ loanId: this.recordId })
      .then(result => {
        console.log('Result1', result);
        if (result == 'Credit Underwriting' || result == 'PSV' || result == 'Disbursement') {
            getCurrentUserProfileName()
            .then((res) => {
                console.log('res: '+res);
                if(res == 'Sales' || res == 'Ops') {
                    this.showCrimeCheck = false;
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