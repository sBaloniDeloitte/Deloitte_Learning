import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from "lightning/navigation";
import UserId from '@salesforce/user/Id';
import UserName from '@salesforce/schema/User.Name';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getUniqueDocumentTypes from '@salesforce/apex/ChecklistController.getUniqueDocumentTypes';
import saveChecklistRecords from '@salesforce/apex/ChecklistController.saveChecklistRecords';
import getDisbursmentChecklistRecords from '@salesforce/apex/ChecklistController.getDisbursmentChecklistRecords';
import USERID_FIELD from "@salesforce/user/Id";
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import getOpportunityTeamMembers from '@salesforce/apex/AHL_LoanDetailsController.getOpportunityTeamMembers';
import getLoanTransactionDetails from '@salesforce/apex/AHL_LoanDetailsController.getLoanTransactionDetails';
import getUserRole from '@salesforce/apex/Hl_CovenantsDetailFormController.getUserRole'; //Sanwar

export default class ChecklistCmp extends NavigationMixin(LightningElement) {
  @api recordId;
  @track statusValue = '';
  @track showSaveButton = false;
  @track time = Date.now();
  @track userId = UserId;
  @track currentUserName;
  @track isTextareaRequired = false;
  @track textareaValue = '';
  @track tabList = [];
  @track activeTab = 'All';//comment
  @track checklistRecords = [];
  recordMap = new Map();
  @track recordObj = [];
  @track keysOfMap = [];
  firstTimeLoaded = true;
  @track currentTime = Date(this.time);
  wiredChecklistData; // Store wired data response
  @track picklistOptions = []; //changing tabs to pickist
  @track isModalOpen = false; // Controls modal visibility
  @track selectedRemarkHistory = ''; // Stores remark history text
  @track allRecords = [];
  value = 'All';
  textareaErr;

  currentUserOppRole = [];
  oppStage = '';
  oppSubStage = '';

  quickDisb;
  qdpStatus = '';

  @wire(getLoanTransactionDetails, {
        loanId: "$recordId",
    })
    getLoanTxnDetails({
        data,
        error
    }){
        if (data) {
            console.log('getLoanTxnDetails   ', data)
            this.qdpStatus = data.QDP_Status__c ?? 'N/A';   
            this.quickDisb = data.Quick_Disbursement__c ?? false;
            console.log('this.qdpStatus is '+this.qdpStatus+'  and this.quickDisb is '+this.quickDisb)
        } else if(error) {
            this.handleError(error, 'gotLoanFields');
            this.showToast(this.toastTitle.ERROR, this.toastMessages.SOMETHING_WENT_WRONG, this.toastVariant.ERROR);
        }
    }

    async setPageEditability(){

        console.log('currentUserOppRole: '+this.currentUserOppRole);
        console.log('oppStage: '+this.oppStage);
        console.log('oppSubStage: '+this.oppSubStage);

        const isQDP = this.quickDisb === true && this.qdpStatus === 'QDP-ONHOLD';

        var disableControls = false;
        if(this.oppSubStage == 'Disbursed'){
            //dont allow edit
            disableControls = true;
        }
        else if(this.oppStage == 'Disbursement'){
            if(this.oppSubStage == 'Ops Maker'){ //&& (this.currentUserOppRole.includes('OPS Maker') || this.currentUserOppRole.includes('Credit Officer'))){
                //allow edit
                disableControls = false;
            }
            else {
                //dont allow edit
                disableControls = true;
            }
        } 
        if(this.oppStage != 'Disbursement'){
          disableControls = true;
        }
        
        if (isQDP) {
          disableControls = true;
        }
        
        if(disableControls){
            console.log('disable controls--');
            
            this.recordObj = this.recordObj.map(row => { 
              
              console.log('row: '+JSON.stringify(row));
              
                var chkListLine;

                if(row.fieldList){
                    chkListLine = row.fieldList.map(item => { 
                        return { 
                            ...item, 
                            isStatusDisabled: true,
                            isRemarksDisabled: true
                        }; 
                    });
                }
                
                return { 
                    ...row, 
                    fieldList: chkListLine
                }; 
            });
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, SUBSTAGE_FIELD] })
    opportunity({ error, data }) {
        if(data) {
            this.oppStage = data.fields.StageName.value;
            this.oppSubStage = data.fields.Sub_stage__c.value;
        }
    }

    @wire(getOpportunityTeamMembers, {
        loanId: "$recordId",
    })
    getOppTeamMembers({
        data,
        error
    }) {
        if (data) {
            data.forEach(item => {
                if(item.UserId == USERID_FIELD){
                    this.currentUserOppRole.push(item.TeamMemberRole);    
                }
            })
        } else if (error) {
          console.log('error fetching Opp Team Members: '+error);
        }
    }

  //get tabs based on Document Type
  @wire(getUniqueDocumentTypes, {
    loanAppId: '$recordId'
  })
  wiredDocumentTypes({
    error,
    data
  }) {
    if (data) {
      let tempAllRecords = [];
      data.forEach(currentItem => {
        if (this.recordMap.has(currentItem.Category__c)) {
          let tempObj = {
            // Label : currentItem.Label,
            Id: currentItem.Id,
            Document_Type__c: currentItem.Document_Type__c,
            Description__c: currentItem.Description__c,
            Product__c: currentItem.Product__c,
            Category__c: currentItem.Category__c,
            Status__c: '',
            Remarks__c: '',
            Remark_History__c: '',
          };
          this.recordMap.get(currentItem.Category__c).push(tempObj);
          tempAllRecords.push(tempObj);
        } else {
          let tempList = [];
          let tempObj = {
            // Label : currentItem.Label,
            Id: currentItem.Id,
            Document_Type__c: currentItem.Document_Type__c,
            Description__c: currentItem.Description__c,
            Product__c: currentItem.Product__c,
            Category__c: currentItem.Category__c,
            Status__c: '',
            Remarks__c: '',
            Remark_History__c: '',
          };
          tempList.push(tempObj);
          this.recordMap.set(currentItem.Category__c, tempList);
          tempAllRecords.push(tempObj);
        }

      });

      let tempArr = [];
      tempArr.push({
        label: 'All',
        value: 'All',
      })
      
      Array.from(this.recordMap.keys()).forEach(item => {
        tempArr.push({
          label: item,
          value: item,
        })
        this.recordObj.push({ //changing tabs to pickist
          label: item,
          fieldList: this.recordMap.get(item),
          isActive : false,
        })
      })
      this.recordObj.push({
        label : 'All',
        fieldList : tempAllRecords,
        isActive : true,
      })
      this.picklistOptions = [...tempArr]; //changing tabs to pickist
      this.createRecordOnLoad();
      // refreshApex(this.wiredChecklistData); 
    } else if (error) {
      console.error('Error fetching document types:', error);
    }
  }


  getChecklistData() {
    console.log('get checklist data');
    getDisbursmentChecklistRecords({
        recordId: this.recordId
      })
      .then(result => {
        console.log('result ', result);
        console.log('this.recordObj : ', this.recordObj);
        result.forEach(item => {
          for (let recObj of this.recordObj) {
            if (recObj.label == item.Category__c) {
              for (let rec of recObj.fieldList) {
                if (rec.Description__c == item.Description__c && rec.Document_Type__c == item.Document_Type__c) {
                  rec.Status__c = item.Status__c;
                  //rec.Remarks__c = item.Remarks__c;
                  rec.Remarks__c = item.Remarks__c;
                  rec.Remark_History__c = item.Remark_History__c;
                  // Apply styles and disable fields if status is "Completed"
                  if (rec.Status__c === 'Completed') {
                    rec.isRemarksDisabled = true;
                      //rec.isStatusDisabled = true;
                      rec.rowStyle = "background-color: #C7F6C7; color: black;";
                  }else if (rec.Status__c === 'Pending') {
                    rec.isRemarksDisabled = false;
                      //rec.isStatusDisabled = true;
                      rec.rowStyle = "background-color: #F6C7C7; color: black;";
                  }
                   else {
                      rec.isRemarksDisabled = false;
                      //rec.isStatusDisabled = false;
                      rec.rowStyle = "";
                    }                  
                  break;
                }
              }
              break;
            }
          }
        });
        console.log('check editability before calling');
        this.setPageEditability();
        console.log('check editability after calling');
        this.applyTabColors(); // **Update tab colors when data is loaded**
      })
      .catch(error => {
        console.error('Error fetching checklist records:', error);
      })
  }


  //get current user
  @wire(getRecord, {
    recordId: UserId,
    fields: [UserName]
  })
  currentUserInfo({
    error,
    data
  }) {
    if (data) {
      this.currentUserName = data.fields.Name.value;
    } else if (error) {
      this.error = error;
    }
  }

  toastvariant = {
    SUCCESS: 'success',
    ERROR: 'error'
  }
  toastTitle = {
    SUCCESS: 'Success',
    ERROR: 'Error'
  }

  toastMessages = {
    DATA_UPDATED_SUCESS_MESSAGE: 'Data Updated Successfully.',
    REMARKS_ERROR_MESSAGE: 'Please add remarks.'

  }

  get options() {
    return [{
        label: '  Pending',
        value: 'Pending'
      },
      {
        label: '  Completed',
        value: 'Completed'
      },
      {
        label: '  Not Applicable',
        value: 'Not Applicable'
      }
    ];
  }

  connectedCallback() {
   
  }

  renderedCallback() {
    if (this.firstTimeLoaded) {
      this.firstTimeLoaded = false;
      this.textareaErr = document.createElement("style");
      this.textareaErr.innerText = `
            .slds-form-element__control .slds-grow .textarea-container{
                  border: red 2px solid;
              }
            `;
    }
  }


  handleTabClick(event) {
    let index = event.target.dataset.index;
    this.recordObj.forEach((tab, i) => {
      tab.isActive = i == index;

    });
  }

  handleCategorySelected(event) {
    //let selectedValue = event.target.value;
    this.activeTab = event.detail.value;
      this.recordObj.forEach((tab) => {
        tab.isActive = tab.label == this.activeTab;
      });


  }

  applyTabColors() {
    this.recordObj.forEach(tab => {
      let allCompleted = true;
      let somePending = false;

      tab.fieldList.forEach(record => {
        if (record.Status__c === 'Completed') {
          allCompleted = true;
        } else if (record.Status__c !== 'Completed') {
          allCompleted = false;
        }
      });

      // ✅ Assign colors dynamically
      if (allCompleted) {
        tab.tabStyle = "background-color: #9bbf56; color: white;"; // Green
        // } else if (somePending) {
        //     tab.tabStyle = "background-color: #e74c3c; color: white;"; // Orange
      } else {
        tab.tabStyle = "background-color: #dc387e; color: white;"; // Red
      }
    });
  }


  // **Ensure Salesforce applies the colors correctly**
  updateTabStyles() {
    setTimeout(() => {
      this.recordObj.forEach(tab => {
        let tabElement = this.template.querySelector(`lightning-tab[label="${tab.label}"]`);
        if (tabElement) {
          tabElement.classList.remove("tab-green", "tab-red");
          tabElement.classList.add(tab.tabClass);
        }
      });
    }, 100); // Delay ensures LWC updates correctly
  }

  handleTextareaChange(event) {
    this.showSaveButton = true;
    const tabIndex = event.target.dataset.tabindex;
    const recIndex = event.target.dataset.recindex;
    let currentRemarks = event.target.value;
    this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["Remarks__c"] = currentRemarks;
    this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["isChanged"] = true;
  }

  handleStatusChange(event) {
    this.showSaveButton = true;
    const tabIndex = event.target.dataset.tabindex;
    const recIndex = event.target.dataset.recindex;
    let selectedValuesArr = event.target.value.split(',');
    let statusValue;
    if(selectedValuesArr.length > 1){
      selectedValuesArr.splice(selectedValuesArr.indexOf(this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["Status__c"]) , 1);
      statusValue = selectedValuesArr[0];
    }else{
      statusValue = event.target.value;
    }
    if(this.recordObj[parseInt(tabIndex)].isSaved != undefined){
      let isStatusChangedAndSaved = this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["Status__c"] != statusValue && this.recordObj[parseInt(tabIndex)].isSaved;
      this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)].isFilled = isStatusChangedAndSaved && statusValue == 'Pending' ? false : true;
    }
    
    this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["Status__c"] = statusValue;
    this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["isChanged"] = true;
    this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["Remarks__c"] ='';

    // ✅ Disable remarks and status if status is "Completed"
    if (statusValue === 'Completed') {
        this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["isRemarksDisabled"] = true;  //disable remarks once completed
        //this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["isStatusDisabled"] = true; // Lock status selection
        this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["rowStyle"] = "background-color: #C7F6C7; color: black;"; // Apply green color
    }else if (statusValue === 'Pending') {
        this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["isRemarksDisabled"] = false;  //enable remarks once completed
        //this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["isStatusDisabled"] = true; // Lock status selection
        this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["rowStyle"] = "background-color: #F6C7C7; color: black;"; // Apply red color
    }else {
        this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["isRemarksDisabled"] = false;
        //this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["isStatusDisabled"] = false;
        this.recordObj[parseInt(tabIndex)].fieldList[parseInt(recIndex)]["rowStyle"] = '';
    }


  }

  handleViewHistory(event) {
    // this.getChecklistData(); 
    console.log('event ',event.target.tab);
    const tabIndex = event.target.dataset.tabindex;
    console.log('tab index', tabIndex);
    const recIndex = event.target.dataset.recindex;
    console.log('Rec index', recIndex);
    console.log('Record Object ', this.recordObj);
    let selectedRecord = this.recordObj[parseInt(tabIndex)]?.fieldList[parseInt(recIndex)];

    console.log('Selected Record History:', selectedRecord); // ✅ Debugging Log

    // ✅ Fetch the latest Remark History
    this.selectedRemarkHistory = selectedRecord.Remark_History__c ?  selectedRecord.Remark_History__c  : 'No history available';
    console.log('Remark History ', this.selectedRemarkHistory);

    // ✅ Open the modal
    this.isModalOpen = true;

  }

  closeModal() {
    this.isModalOpen = false;
    this.selectedRemarkHistory = ''; // Reset history when closing
  }

  saveRecord(event) {
    let recordsToSave = [];
    let invalidRecords = [];
    const tabIndex = event.target.dataset.tabindex;

    // Create a copy of the records so changes trigger reactivity
    this.recordObj = this.recordObj.map((tab, tIndex) => {
        if (tIndex === parseInt(tabIndex, 10)) {
            return {
                ...tab,
                fieldList: tab.fieldList.map(record => {
                    let newRecord = { ...record };

                    // Validation: Ensure Remarks__c is not blank if Status__c is "Pending"
                    if (((newRecord.Status__c === 'Pending') && (!newRecord.Remarks__c || newRecord.Remarks__c.trim() === '')) && !newRecord.isFilled) {
                        newRecord.hasError = true; // Mark as error
                        newRecord.rowClass = 'row-error';
                        newRecord.inputClass = 'input-error';
                        invalidRecords.push(newRecord.Description__c);
                        //this.template.querySelector(".textAreaErrClass")?.appendChild(this.textareaErr);
                    } else if (newRecord.isChanged) {
                        // Remove error styling
                        newRecord.hasError = false;
                        newRecord.rowClass = '';
                        newRecord.inputClass = '';
                        newRecord.isChanged = false;
                        newRecord.isFilled = true;

                        let previousHistory = newRecord.Remark_History__c ? newRecord.Remark_History__c + '\n\n' : '';
                        let newHistoryEntry = `<strong>Status:</strong> ${newRecord.Status__c || ''} 
                                               <br><strong>User:</strong> ${this.currentUserName} 
                                               <br><strong>Admin Remarks:</strong> ${newRecord.Remarks__c || ''} 
                                               <br><strong>Time:</strong> ${new Date().toLocaleString()}
                                               <hr>`;

                        let updatedHistory = previousHistory + newHistoryEntry;
                        recordsToSave.push({
                            Description__c: newRecord.Description__c,
                            Document_Type__c: newRecord.Document_Type__c,
                            Status__c: newRecord.Status__c || '',
                            Remarks__c: newRecord.Remarks__c || '',
                            Remark_History__c: updatedHistory,
                            Loan_Application__c: this.recordId,
                            Category__c: newRecord.Category__c,
                            Product__c: newRecord.Product__c,
                        });

                        newRecord.Remark_History__c = updatedHistory; // Update UI immediately
                         newRecord.Remarks__c = ''; //reset remark after save
                    } 
                    return newRecord;
                })
            ,isSaved : true};
        }
        return {...tab,isSaved : false} ;
    });

    let updatedRecords = [];
    this.recordObj.forEach(tab => {
        if (tab.label !== 'All') {
            updatedRecords = [...updatedRecords, ...tab.fieldList];
        }
    });
    this.recordObj = this.recordObj.map(tab => {
        if (tab.label === 'All') {
            return {
                ...tab,
                fieldList: updatedRecords
            };
        }
        return tab;
    });

    // Show a toast for missing remarks
    if (invalidRecords.length > 0) {
        this.handletoastEvent(
            `Remarks for some of the items are missing, please enter those remarks`,
            this.toastTitle.ERROR,
            this.toastvariant.ERROR
        );
    }

    // Proceed only if there are valid records to save
    if (recordsToSave.length > 0) {
        saveChecklistRecords({ records: recordsToSave, onload: false })
            .then(() => {
                this.showSaveButton = false;
                this.handletoastEvent(this.toastMessages.DATA_UPDATED_SUCESS_MESSAGE, this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                this.getChecklistData(); // Refresh checklist data
            })
            .then(() => {
                this.applyTabColors();
            })
            .catch(error => {
                console.error('Error saving records:', error);
                this.handletoastEvent('Error saving records: ' + (error.body ? error.body.message : error.message), this.toastTitle.ERROR, this.toastvariant.ERROR);
            });
    }
}

  createRecordOnLoad() {
    let recordsToSave = [];
    console.log('recordObj ---' + this.recordObj);
    this.recordObj.forEach(tab => {
      if(tab.label != 'All'){
        tab.fieldList.forEach(record => {
          // Prepare records for saving
          recordsToSave.push({
            Description__c: record.Description__c,
            Document_Type__c: record.Document_Type__c,
            Category__c: record.Category__c,
            Status__c: '',
            Remarks__c: '',
            Remark_History__c: '',
            Loan_Application__c: this.recordId,
            Product__c: record.Product__c,
            isRemarksDisabled: false, 
            isStatusDisabled: false, 
            rowStyle: "", 
          });
        });
      }
    });

    // Save records to Apex
    saveChecklistRecords({
        records: recordsToSave,
        onload: true
      })
      .then(() => {
        this.showSaveButton = false;
        //    this.handletoastEvent(this.toastMessages.DATA_UPDATED_SUCESS_MESSAGE, this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
        // **Refresh the screen without reloading the page**
        this.getChecklistData();
        // return refreshApex(this.wiredChecklistData);
      })
      .then(() => {
        this.applyTabColors(); // ✅ Apply tab colors AFTER save
      })
      .catch(error => {
        console.error('Error saving records:', error);
        this.handletoastEvent('Error saving records: ' + (error.body ? error.body.message : error.message), this.toastTitle.ERROR, this.toastvariant.ERROR);
      });
  }

  handletoastEvent(msg, title, variant) {
    this.dispatchEvent(new ShowToastEvent({
      title: title,
      message: msg,
      variant: variant,
    }));
  }

}