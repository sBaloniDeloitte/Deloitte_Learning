import { LightningElement, track, api , wire} from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getApplicants from "@salesforce/apex/COMM_ItrScreenController.getApplicants";
import saveManualPd from "@salesforce/apex/Comm_ManualPdController.saveManualPd";
import saveAppVerifPd from '@salesforce/apex/Comm_ManualPdController.saveApplicationVerificationPd';
import getDocuments from "@salesforce/apex/Comm_ManualPdController.getDocuments";
import getAllManualPds from "@salesforce/apex/Comm_ManualPdController.getAllManualPds";
import getAllDocConIds from "@salesforce/apex/Comm_ManualPdController.getAllDocConIds";
import saveDocsOnAV from "@salesforce/apex/Comm_ManualPdController.saveDocsOnAV";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Application_Verification from '@salesforce/schema/Application_Verification__c';
import DispositionField from '@salesforce/schema/Application_Verification__c.Disposition__c';
import getCurrentUserInfo from '@salesforce/apex/Comm_ManualPdController.getCurrentUserInfo';
import deleteDocument from "@salesforce/apex/Comm_ManualPdController.deleteDocument";
import updatePdPerformedBy from "@salesforce/apex/Comm_ManualPdController.updatePdPerformedBy";
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import getPicklistValuesForDisposition from '@salesforce/apex/COMM_VideoPDController.getPicklistValuesForDisposition';
import checkIfAlreadyInitiatedPd from '@salesforce/apex/Comm_ManualPdController.checkIfAlreadyInitiatedPd';
import LOAN_SUB_STAGE from '@salesforce/schema/Opportunity.Sub_Stage_To_Display__c';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

const FIELDS = [LOAN_SUB_STAGE];



import {NavigationMixin} from 'lightning/navigation';
import { updateRecord } from "lightning/uiRecordApi";

export default class ManualPdCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @track disposition='';
    @track applicantValue='';
    @track note = '';
    @track options = [];
    @track isRendered = false;
    @track showImages = false;
    @track imageUrl;
    @track pdfUrl;
    @track currentIndex = 0;
    @track documents = [];
    @track docIds = [];
    @track showImagebutton = false;
    @track manualPds = [];
    @track showManualPds=false;
    @track viewdocIds = [];
    @track docIdsHIs = [];
    @track showAddRowbutton = true;
    @track appVerificationId;
    picklistValues = [];
    applicantId;
    appVerifId;
    userInfo;
    error;
    showNextButton = false;
    @track pdPerformedBy;
    @track editpdPerformedBy = false;
    @track changingId;
    @track isDisableInitiation;
    @track showAddPD = true;
    @api disabledCmp = false;

    // Fetch object info for the custom object
    @wire(getObjectInfo, { objectApiName: Application_Verification })
    objectInfo;

    // Fetch picklist values based on field and record type
    // @wire(getPicklistValues, {
    //     fieldApiName: DispositionField,
    //     // recordTypeId: '$recordTypeId'
    // })
    // picklistData({ data, error }) {
    //     if (data) {
    //         this.picklistValues = data.values;
    //         this.error = undefined;
    //         console.log('picklistValues-->', this.picklistValues);
    //     } else if (error) {
    //         console.error('picklistData error: '+picklistData);
    //         this.error = error;
    //         this.picklistValues = [];
    //     }
    // }

    // Fetch record type ID and pass it to the picklist wire adapter
    // get recordTypeId() {
    //     console.log('recordTypeId--',this.objectInfo.data.recordTypeInfos);   
    //     const recordTypes = this.objectInfo.data.recordTypeInfos;
    //     const recordTypeInfo = Object.values(recordTypes).find(rt => rt.name === 'Personal Discussion');
    //     return recordTypeInfo.recordTypeId;
    // }
    @wire(getCurrentUserInfo)
    wiredUserInfo({ error, data }) {
        if (data) {
            this.userInfo = data;  // Store the returned string
        } else if (error) {
            this.userInfo = 'Error retrieving user information';  // Handle error
        }
    }

    get disableNext() {
        return this.currentIndex === this.documents.length - 1;
    }
    get previous() {
        return this.currentIndex == 0;
    }
    get documentName() {
        return this.documents.length > 0 ? this.documents[this.currentIndex].docName : null;
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    OppRec;

    // get dispositionOptions() {
    //     return [
    //       { label: "DP1", value: "DP1" },
    //       { label: "DP2", value: "DP2" },
    //     ];
    // }
    get dispositionOptions() {
        return this.picklistValues;
    }


    get acceptedFormats() {
        return ['.pdf', '.png','.jpeg','.jpg'];
    }
    connectedCallback() {
        getPicklistValuesForDisposition()
        .then((result) => {
            this.picklistValues = result.map(val => ({
                label: val,
                value: val
            }));
        })
        .catch((error) => {
            this.error = error;
            console.error('Error fetching picklist values', error);
        });
        this.getApplicantPickList();
        this.getAllManualPdsRec();
        this.fetchLoanStage();
    }
    fetchLoanStage() {
        getLoanStage({ loanId: this.recordId })
          .then(result => {
            console.log('Result1', result);
            if (result == 'Credit Underwriting' || result == 'PSV' || result == 'Disbursement') {
                getCurrentUserProfileName()
                .then((res) => {
                    if(res == 'Sales' || res == 'Ops' || res == 'Credit Officer' || res == 'Sales') {
                        this.isDisableInitiation = true;
                        this.showAddPD = false;

                        
                        const paramField1 = getFieldValue(this.OppRec.data, LOAN_SUB_STAGE);
                        console.log('paramField1: ',paramField1);
                        if(paramField1 == 'Credit in-progress' && result == 'Credit Underwriting') {
                            this.showAddPD = true;
                        }
                        
                    }
                    
                })
                .catch((error) => {
                    console.error('Error getCurrentUserProfileName --> '+ error);
                });
            } else {
                getCurrentUserProfileName()
                .then((res) => {
                    console.log('res: '+res);
                    if(res == 'Sales' || res == 'Ops' || res == 'Credit Manager') {
                        this.isDisabledInitiation = true;
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
    handleApplicantChange(event) {
        this.applicantValue = event.target.value;
        const matchedOption = this.options.find(
          option => option.value === this.applicantValue
        );
        console.log('matchedOption: '+matchedOption);
        console.log('matched option value>'+matchedOption.value);
        this.applicantId = matchedOption.value;
    }
    

    getApplicantPickList() {
        getApplicants({
          recordId: this.recordId,
        })
          .then((response) => {
            console.log("customer details=:" + JSON.stringify(response));
            //this.options = [... this.options,{label:'All',value:'All'}];
            for (let key in response) {
              console.log("customer details=:" + response[key]);
              console.log('key: '+key);
              this.options = [
                ...this.options,
                {
                  label: response[key],
                  value: key,
                },
              ];
            }
          })
          .catch((error) => {});
      }
    handleChange(event){
        this.disposition = event.detail.value;
        this.hanldeSave();
        this.showAddRowbutton = true;
    }
    onClickAddButton(){
        this.showAddRowbutton = !this.showAddRowbutton;
    }

    openPdForm(event) {
        console.log('event.target.dataset.id  ' + event.target.dataset.id );
        //if (event.target.dataset.id == null || event.target.dataset.id == '') {
            const baseUrl = window.location.origin; 
            const url = `${baseUrl}/lightning/n/Credit_PD_Form_Page?c__recordId=${this.recordId}&c__appVerifId=${event.target.dataset.id}`;

            // Open in new browser tab
            window.open(url, '_blank');
       // }
    }
    async handleInitiate(event) {
       // if (event.target.dataset.id == null || event.target.dataset.id == '') {
            checkIfAlreadyInitiatedPd({
                loanId: this.recordId,
                    applicantId: this.applicantId,
                    pdType: 'Manual'
                }).then((response) => {
                    if (response) {
                        this.showToastMessage('Error', 'PD is already initiated!.', 'error');
                        this.showAddRowbutton = true;
                    } else {
                        saveAppVerifPd({
                                loanAppId: this.recordId,
                                applicantId: this.applicantId,
                            }).then((response) => {
                                console.log('response: ' + JSON.stringify(response));
                                this.appVerifId = response;
                                this.showToastMessage('Success', 'Credit PD initiated successfully', 'success');
                                console.log('this.recordId => ' + this.recordId);
                                console.log('this.applicantId => ' + this.applicantId);

                                const appVerifId = event.target.dataset.id;
                                console.log('appVerifId => ' + appVerifId);

                                // Build absolute URL to your Lightning page
                                const baseUrl = window.location.origin; 
                                const url = `${baseUrl}/lightning/n/Credit_PD_Form_Page?c__recordId=${this.recordId}&c__appVerifId=${this.appVerifId}`;

                                // Open in new browser tab
                                window.open(url, '_blank');

                                console.log('this.recordId>' + this.recordId);
                                console.log('this.applicantId>' + this.applicantId);
                               /* const appVerifId = (event.target.dataset.id != null && event.target.dataset.id != '') ? event.target.dataset.id : this.appVerifId;
                                console.log('appVerifId: ' + appVerifId);
                                const pageref = {
                                    type: 'standard__navItemPage',
                                    attributes: {
                                        apiName: 'Credit_PD_Form_Page',
                                        recordId: this.recordId,
                                        appVerifId: appVerifId,
                                        objectApiName: 'Opportunity',
                                    },
                                    state: {
                                        recordId: this.recordId
                                    }
                                };
                                this[NavigationMixin.Navigate](pageref);*/
                            })
                            .catch(error => {
                                console.log('Error saving record -->', error);
                            })
                    }

                })
                .catch(error => {
                    console.log('Error saving record -->', error);
                })






       // }

    }
    hanldeSave() {
        if(!this.disposition) {
            this.showToastMessage('Error', 'Please select dispostion', 'erroe');
            return;
        }else if(!this.note) {
            this.showToastMessage('Error', 'Please fill pd notes.', 'erroe');
            return;
        } else if(!this.pdPerformedBy) {
            this.showToastMessage('Error', 'Please fill Pd Performed By.', 'error');
            return;
        }
this.saveManualPdRec();

    
    }
    saveManualPdRec() {
        saveManualPd({
          recordId: this.recordId,
          docIds: this.docIds,
          remarks: this.note,
          disposition: this.disposition,
          pdPerformedBy: this.pdPerformedBy
        })
          .then((response) => {
            console.log("save res" + JSON.stringify(response));
           if(response == 'success') {
                this.showToastMessage('Success','Record inserted successfully!.','success');
                this.applicantValue = null;
                this.note = null;
                this.disposition = null;
                this.docIds = [];
                this.showImagebutton = false;
                this.getAllManualPdsRec();
                
           }else {
                this.showToastMessage('Error','Something went wrong, please contact your system admin.','errpe');
           }
            
          })
          .catch((error) => {});
      }
    handleTextNote(event) {
        this.note = event.target.value;
    }
    showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(toastEvent);
    }
    handleUploadFinished(event){
        const uploadedFiles = event.detail.files;
        console.log('uploadedFiles ',uploadedFiles.length);
        //this.docIds = [];
        for(var i = 0; i < uploadedFiles.length; i++ ) {
            this.docIds.push(uploadedFiles[i].documentId);
        }
        console.log('this.docIds ',this.docIds);
        this.showImagebutton = true;
    }

    
renderedCallback() {
    if (!this.isRendered) {
        // Create and append styles dynamically
        const style = document.createElement('style');
        style.innerText = `
        p, h1, h2, h3, h4, h5, a, .slds-button{
            font-family: Arial;
        }
        .cancel-button{
            text-wrap-mode: nowrap;
        }
        .custom-table .slds-form-element__label, span.slds-file-selector__text.slds-medium-show{
            display: none;
        }
        .custom-table span.slds-file-selector__button.slds-button.slds-button_neutral{
            font-size: 0px;
        }
        .custom-table svg.slds-button__icon.slds-button__icon_left{
            margin: 0px;
        }
        .custom-table lightning-primitive-file-droppable-zone.slds-file-selector__dropzone{
            border: none;
        }
        .custom-table .slds-textarea{
            min-height: 200px;
        }
        .custom-table{
            font-weight: 400;
        }


        `;

        // Append the styles to the .styleContainer
        this.template.querySelector('.styleContainer')?.appendChild(style);

        // Prevent re-adding styles
        this.isRendered = true;
    }
    }
    getuploadedDocs() {
        getDocuments({
            condocIds: this.docIds,
        })
          .then((response) => {
            console.log("documents details=:" + JSON.stringify(response));
            this.documents = response;
            this.firstImage();
          })
          .catch((error) => {});
    }

    async handleNext() {
        console.log('this.currentIndex : '+this.currentIndex);
        if (this.currentIndex < this.documents.length - 1) {
            this.currentIndex++;
        }
        await this.firstImage();
    }

    async handlePrevious() {
    console.log('this.currentIndex 268 : '+this.currentIndex);
        if (this.currentIndex > 0) {
            this.currentIndex--;
        }
        await this.firstImage();
    }

    async firstImage() {
        if(this.documents.length == 1) {
            this.showNextButton = false;
        }else {
            this.showNextButton = true;
        }
        if (this.documents.length > 0) {
            const currentDoc = this.documents[this.currentIndex];
            if (currentDoc.docExt === 'pdf') {
                this.pdfUrl = this.downloadPdf(currentDoc.docVersiondata);
                this.imageUrl = null;
            } else {
                this.imageUrl = `/sfc/servlet.shepherd/document/download/${currentDoc.docContDocId}`;
                this.pdfUrl = null;
            }
        }else {

        }
        
    }

    downloadPdf(base64fContent) {
        if (!base64fContent) {
            console.error('No base64 content available for PDF');
            return null;
        }

        try {
            const byteCharacters = atob(base64fContent);
            const byteNumbers = new Array(byteCharacters.length);
    
            for (let i = 0; i < byteCharacters.length; i++) {
                byteNumbers[i] = byteCharacters.charCodeAt(i);
            }
    
            const byteArray = new Uint8Array(byteNumbers);
            const blob = new Blob([byteArray], { type: 'application/pdf' });
            const url = URL.createObjectURL(blob);
            return url;
        } catch (error) {
            console.error('Error loading PDF:', error);
            return null;
        }
    }
    viewImage() {
        this.getuploadedDocs(this.docIds);
     this.showImages = true;   
    }
    handleClose() {
        this.documents = [];
        this.currentIndex = 0;
        this.showImages = false;
        this.appVerificationId = '';
    }

    getAllManualPdsRec() {
        getAllManualPds({
            recordId: this.recordId
            })
            .then(result => {
                this.manualPds = result;
                console.log('manual PDs',JSON.stringify(this.manualPds));
                if (this.manualPds.length <= 0) {
                    this.showManualPds = false;
                } else {
                    this.showManualPds = true;
                }
                this.handlePDsummaryRefresh();
            })
            .catch(error => {
                console.log('Error getting documents',JSON.stringify(error));
                this.manualPds = [];
            });
    }
    handleTextNoteTable(event) {
        console.log(event.target.dataset.id);
        const fields = {};
        fields['Id'] = event.target.dataset.id;
        fields['Any_Remarks_Reasons__c']=event.target.value;
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
        .then(() => {
            this.showToastMessage('Success', 'Record updated successfully', 'success');
            this.handlePDsummaryRefresh();
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
    }
    viewImageTable(event){
        let apId = event.target.dataset.id;
        this.appVerificationId = apId;
        console.log('apid',apId);
        
        getAllDocConIds({
            appVerId: apId
            })
            .then(result => {
                if(result.length <= 0) {
                    this.showToastMessage('Error', 'No Images are uploaded.', 'erroe');
                    this.showImages = false;   
                    return;
                }
                
                this.viewdocIds = result;
                this.getuploadedDocsView();
                this.showImages = true;   

            })
            .catch(error => {
                this.docIds = [];
            });
    }
    getuploadedDocsView() {
        getDocuments({
            condocIds: this.viewdocIds,
        })
          .then((response) => {
            console.log("documents details=:" + JSON.stringify(response));
            this.documents = response;
            this.firstImage();
          })
          .catch((error) => {});
    }
    handleChangeHis(event) {
        const fields = {};
        fields['Id'] = event.target.dataset.id;
        fields['Disposition__c']=event.target.value;
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
        .then(() => {
            this.showToastMessage('Success', 'Record updated successfully', 'success');
            this.handlePDsummaryRefresh();
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
    }
    handleUploadFinishedHIs(event) {
        const uploadedFiles = event.detail.files;
        console.log('uploadedFiles ',uploadedFiles.length);
        this.docIdsHIs = [];
        for(var i = 0; i < uploadedFiles.length; i++ ) {
            this.docIdsHIs.push(uploadedFiles[i].documentId);
        }
        console.log('this.docIdsHIs ',this.docIdsHIs);

        saveDocsOnAV({
            condocIds: this.docIdsHIs,
            appVerId: event.target.dataset.id,
            recordId: this.recordId,
          })
            .then((response) => {
              console.log("save res" + JSON.stringify(response));
             if(response == 'success') {
                  this.showToastMessage('Success','Images Uploaded successfully!.','success');
                  this.this.docIdsHIs = [];
                  this.getAllManualPdsRec();
                  
             }else {
                  this.showToastMessage('Error','Something went wrong, please contact your system admin.','errpe');
             }
              
            })
            .catch((error) => {});
    }
    handlePDsummaryRefresh() {
       
        this.dispatchEvent(new CustomEvent('handlechange', {}));
       
    }

    handledelete() {
        console.log(this.documents[this.currentIndex].docContDocId);

        
        deleteDocument({
            contentDocId: this.documents[this.currentIndex].docContDocId,
          })
            .then((response) => {
              console.log("save res" + JSON.stringify(response));
             if(response == 'success') {
                  this.showToastMessage('Success','Images deleted successfully!.','success');
                  this.checkIdImage();
                  
             }else {
                  this.showToastMessage('Error','Something went wrong, please contact your system admin.','errpe');
             }
              
            })
            .catch((error) => {});
    }

    checkIdImage() {
        getAllDocConIds({
            appVerId: this.appVerificationId
            })
            .then(result => {
                if(result.length <= 0) {
                    this.showToastMessage('Error', 'No Images are uploaded.', 'erroe');
                    this.showImages = false;   
                    return;
                }
                
                this.viewdocIds = result;
                this.getuploadedDocsView();
                this.showImages = true;   

            })
            .catch(error => {
                this.docIds = [];
            });
    }

    handleSelectedUser(event) {
        const selectedUser = event.detail.searchRecord;
        this.pdPerformedBy = selectedUser?.Id;
        console.log('this.pdPerformedBy: ', this.pdPerformedBy);
        this.hanldeSave();

    }
    handlelDeselectedUser(event) {
        this.showToastMessage('Required', 'This field is required for Manual PD', 'error');
        // const fields = {};
        // fields['Id'] = event.target.dataset.id;
        // fields['PD_Performed_By__c']=event.target.value;
        // const recordInput = { fields };
        // console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        // updateRecord(recordInput)
        // .then(() => {
        //     this.showToastMessage('Success', 'Record updated successfully', 'success');
        //     this.handlePDsummaryRefresh();
        // })
        // .catch(error => {
        //     console.log('Error updating record --> '+JSON.stringify(error));
        // });
    }
    editPdPerformedBy(event) { 
        const appVeriId = event.target.dataset.id;
        this.changingId = appVeriId;
        console.log('appVeriId: '+appVeriId);
        this.manualPds = this.manualPds.map(item => {
            return {
                ...item,
                editMode: item.appVeriId === appVeriId // only the selected row enters edit mode
            };
        });
    }

    updateSelectedUser(event) {
        const appVeriId = event.target.dataset.id;
        const selectedUser = event.detail.searchRecord;
        console.log('selectedUser: ', selectedUser.Id);
        console.log('appVeriId: ', appVeriId);
        console.log('this.changingId: ', this.changingId);

        updatePdPerformedBy({ appVeriId: this.changingId, userId: selectedUser.Id })
        .then(() => {
            this.manualPds = this.manualPds.map(item => {
                if (item.appVeriId === appVeriId) {
                    return {
                        ...item,
                        pdPerformedBy: selectedUser.Name,
                        selectedId: selectedUser.Id,
                        editMode: false
                    };
                }
                return item;
            });

            this.showToastMessage('Success', 'Updated successfully.', 'success');
        })
        .catch(error => {
            console.error('Error updating user:', error);
            this.showToastMessage('Error', 'Failed to update user.', 'error');
        });
    }

    updateDeselectedUser(event){
        this.showToastMessage('Required', 'This field is required for Manual PD', 'error');
    }
}