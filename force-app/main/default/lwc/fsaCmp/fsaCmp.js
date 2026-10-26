import {LightningElement, wire,track,api} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getApplicants from "@salesforce/apex/COMM_ItrScreenController.getApplicants";
import getFSARecords from "@salesforce/apex/FsaController.getFSARecords";
import saveFSARecord from "@salesforce/apex/FsaController.saveFSARecord";
import getFsaRecordTypeId from "@salesforce/apex/FsaController.getFsaRecordTypeId";
import uploadFileToContent from "@salesforce/apex/FsaController.uploadFileToContent";
import getDocumentDetails from '@salesforce/apex/FsaController.getDocumentDetails';
import reUploadFileToContent from '@salesforce/apex/FsaController.reUploadFileToContent'
import checkFiletype from '@salesforce/apex/FsaController.checkFiletype';
import checkExceptionStatus from '@salesforce/apex/COMM_SalesLoanLoginController.checkExceptionStatus';
import {refreshApex} from '@salesforce/apex';
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import APPROVAL_STATUS from "@salesforce/schema/Opportunity.Approval_Status__c";
import STAGENAME_FIELD from "@salesforce/schema/Opportunity.StageName";
import OWNERID_FIELD from "@salesforce/schema/Opportunity.OwnerId";
import USER_ID from "@salesforce/user/Id";
import ProfileName from '@salesforce/schema/User.Profile.Name';
import { getRecord } from "lightning/uiRecordApi";
import {NavigationMixin} from 'lightning/navigation';
import {updateRecord} from "lightning/uiRecordApi";
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
export default class FsaCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @track options = [];
    @track yearOptions = [];
    @track applicantValue = '';
    @track yearCY = '';

    @track yearPY = '';

    @track fsaCY = {};
    @track fsaPY = {};

    @track fsaRecordTypeId;
    @track isRendered = false;
    @track isConsolidated = false;

    @track spinner = false;
    @track documentUrl;
    @track documentDetails;
    @track showImage = false;
    @track pdfURL;
    @track imageURL;
    @track fileType;
    @track hasLoanStagePsvOrDisbursement = false;
    @track maxDate;
    @track isDisabledFSA;
    hideButton = false;
    // get getClass3OutOf12(){
    //     if(this.deviceType =='Mobile'){
    //         //return "slds-col slds-size_1-of-12";
    //         return '';
    //     }
    //     return "slds-col slds-size_3-of-12";
    // }

    // get getClass10OutOf12(){
    //     if(this.deviceType =='Mobile'){
    //         return "slds-col slds-size_12-of-12";
    //     }
    //     return "slds-col slds-size_6-of-12";
    // }

    // get getSizeByDevice(){
    //     if(this.deviceType =='Mobile'){
    //         return "12";
    //     }
    //     return "4";
    // }

    userProfile = '';

    @wire(getRecord, { recordId: USER_ID, fields: [ProfileName] })
    userDetails({ error, data }) {
        if(data) {
            this.userProfile = data.fields.Profile.value.fields.Name.value;
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: [SUBSTAGE_FIELD,APPROVAL_STATUS,STAGENAME_FIELD,OWNERID_FIELD] })
    opportunity({ error, data }) {
        if(data) {
            var oppSubStage = data.fields.Sub_stage__c.value;
            var approvalStatus = data.fields.Approval_Status__c.value;
            var StageName = data.fields.StageName.value;
            var OwnerId = data.fields.OwnerId.value;

            if(StageName === 'Credit Underwriting'){
                console.log('this.userProfile: '+this.userProfile);
                if(this.userProfile != 'System Administrator' && OwnerId != USER_ID){
                    this.hideButton = true;
                    this.isDisabledFSA = true;
                }
                else if(this.userProfile == 'Sales') {
                    this.isDisabledFSA = true;
                }
            }
            else if(StageName == 'PSV' || StageName == 'Disbursement') {
                this.hasLoanStagePsvOrDisbursement = true;
            }

            console.log('approvalStatus>>'+approvalStatus);
            if(oppSubStage === 'Disbursed' || ['Hard Rejected', 'Soft Rejected 1', 'Soft Rejected 2'].includes(approvalStatus)) {
                this.hideButton = true;
                this.isFieldDisable = true;
            }
        }
    }

    connectedCallback() {
        var currentTime = new Date()
        this.maxDate = currentTime.toISOString().split('T')[0];
        var currYear = currentTime.getFullYear();
        var previousYear = currYear - 2;
        this.yearCY = (currYear - 1).toString();
        this.yearPY = previousYear.toString();
        this.getApplicantPickList();
        this.getFSARecTypeId();
        this.getYearOptions();
        this.checkUserProfile();
        setTimeout(() => {
            this.fetchDocumentDetails();
        }, 200);
        //this.fetchLoanStage();
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

    // fetchLoanStage() {
    //     getLoanStage({ loanId: this.recordId })
    //       .then(result => {
    //         console.log('Result1', result);
    //         if(result == 'PSV' || result == 'Disbursement') {
    //             this.hasLoanStagePsvOrDisbursement = true;
    //         } else if (result == 'Credit Underwriting') {
    //             getCurrentUserProfileName()
    //             .then((res) => {
    //                 console.log('res: '+res);
    //                 if(res == 'Sales') {
    //                     this.isDisabledFSA = true;
    //                 }
    //             })
    //             .catch((error) => {
    //                 console.error('Error getCurrentUserProfileName --> '+ error);
    //             });
    //         }
    //       })
    //       .catch(error => {
    //         console.error('Error:', error);
    //     });
    // }

    isFieldDisable = false;
    checkUserProfile() {
        checkExceptionStatus({ loanId: this.recordId })
            .then(result => {
                console.log('Inside Profile true----', result);

                if (result) {
                    this.isConsolidated = true;
                    this.isFieldDisable = true;
                }
            })
            .catch(error => {
                console.error('Error in checkExceptionStatus:', error);
            });
    }

    getApplicantPickList() {
        getApplicants({
                recordId: this.recordId,
            })
            .then((response) => {
                console.log("customer details=:" + JSON.stringify(response));
                this.options = [... this.options,{label:'Consolidated',value:'Consolidated'}];
                for (let key in response) {
                    console.log("customer details=:" + response[key]);
                    this.options = [
                        ...this.options,
                        {
                            label: response[key],
                            value: key,
                        },
                    ];
                }
                this.applicantValue = this.options[0].value;
                console.log("applicantValue" + this.applicantValue);
                this.isConsolidated = true;
                this.getFSADataCY();
                this.getFSADataPY();
            })
            .catch((error) => {});
    }

    getFSADataCY() {
        this.spinner = true;
        getFSARecords({
            loanId : this.recordId,
                applicantId: this.applicantValue,
                year: this.yearCY
            })
            .then((response) => {
                console.log("getItrRecords CY " + JSON.stringify(response));
                
                if (response) {
                    this.spinner = false;
                    
                    if (Object.keys(response).length === 0 || response == undefined || response == null) {
                        console.log("null CY ");
                        //this.idCY = null;
                        this.fsaCY.id = null;
                        this.fsaCY.Year__c = this.yearCY;
                    } else {
                       
                        console.log("valueCy",response);
                        this.fsaCY = {};
                        this.fsaCY = response;
                        
                    }
                    
                } else {
                    this.spinner = false;
                    console.log("null CY out els");
                    setTimeout(() => {
                        const inputs = this.template.querySelectorAll('.currYearId lightning-input-field');
        
                        // Loop through each input field and set its value to empty
                        inputs.forEach(input => {
                            input.value = '';
                        });
                    }, 500);
                   
                    this.fsaCY.id = null;

                    this.fsaCY.Year__c = this.yearCY;
                   
                }
                
                

            })
            .catch((error) => {});
    }

    getFSADataPY() {
        //this.spinner = true;
        getFSARecords({
                loanId : this.recordId,
                applicantId: this.applicantValue,
                year: this.yearPY
            })
            .then((response) => {
                console.log("getItrRecords PY " + JSON.stringify(response));
                if (response) {
                    this.spinner = false;
                    if (Object.keys(response).length === 0 || response === undefined || response === null) {
                        this.fsaPY.id = null;
                        this.fsaPY.Year__c = this.yearPY;
                    } else {
                        console.log("valye pY",response);
                        this.fsaPY = response;

                    }
                } else {
                   // this.spinner = false;
                    const fil = this.template.querySelectorAll('.preYearId lightning-input-field');
        
        // Loop through each input field and set its value to empty
        fil.forEach(inp => {
            inp.value = '';
        });
                    this.fsaPY.id = null;
                    this.fsaPY.Year__c = this.yearPY;
                }
            
            })
            .catch((error) => {});
    }
    getFSARecTypeId() {
        getFsaRecordTypeId({})
            .then((response) => {
                console.log("getItrRecords CY " + JSON.stringify(response));
                this.fsaRecordTypeId = response;


            })
            .catch((error) => {});
    }

    handleSuccess(event) {
        event.stopPropagation();
        console.log('onsuccess event recordEditForm', event.detail.id);
        if (event.detail.id) {
            this.showToastMessage("Success", "Record updated successfully", "success");
            this.spinner = false;
            //this.refreshLoanDetails();
        } else {
            
            this.showToastMessage("Error", "Something went wrong !!", "error");
            this.spinner = false;
        }
        this.getFSADataCY();
        this.getFSADataPY();
    }
    handleSubmit(event) {
        event.stopPropagation();
        this.spinner = true;
        event.preventDefault();
        console.log('event.detail.fields',JSON.stringify(event.detail.fields));
        console.log('event.detail',JSON.stringify(event.detail));
        const fields = event.detail.fields;
        fields.Application_Applicant__c = this.applicantValue;
        fields.Loan_Application__c = this.recordId;
        fields.Year__c = this.yearCY;
        fields.RecordTypeId = this.fsaRecordTypeId;
        fields.Id = this.fsaCY.Id;
        //this.template.querySelector('lightning-record-edit-form').submit(fields);
        saveFSARecord({
            applicantId:this.applicantValue,
            expObj: fields,
            isCurrentYear: true,
            recordId:this.recordId
        })
            .then((response) => {
                console.log("saveFSARecord " + JSON.stringify(response));
                this.showToastMessage("Success", "Record updated successfully", "success");
                this.spinner = false;
                this.getFSADataCY();
                this.getFSADataPY();
                
            })
            .catch((error) => {
                // this.showToastMessage("Error", "Something went wrong !!", "error");
                console.error('saveFSARecord error: ', JSON.stringify(error));
                if (error?.body?.fieldErrors?.ITR_Filling_date__c && error.body.fieldErrors.ITR_Filling_date__c.length > 0) {
                    let errorMessage = error.body.fieldErrors.ITR_Filling_date__c[0].message;
                    this.showToastMessage("Invalid Input", errorMessage, "error");
                }
                this.spinner = false;
            });
           

        /*
        if (Number(this.cagrVal) == 0 || Number(this.cagrVal) < 0) {
            event.preventDefault();
            this.handleToastMsg('Error', 'Error', 'Please enter CAGR greater than zero.');
        }
        */
    }
    showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
          title: title,
          message: message,
          variant: type,
        });
        this.dispatchEvent(toastEvent);
      }
      getYearOptions() {
        var date = new Date();
        var year = date.getFullYear();
        for (var i = year - 4; i <= year + 3; i++) {
            this.yearOptions = [
                ...this.yearOptions,
                {
                  label: i.toString(),
                  value: i.toString(),
                },
            ];  
        }
      }
      handleSuccessPY(event) {
        event.stopPropagation();
        console.log('onsuccess event recordEditForm', event.detail.id);
        if (event.detail.id) {
            this.showToastMessage("Success", "Record updated successfully", "success");
            
            //this.refreshLoanDetails();
        } else {
            this.showToastMessage("Error", "Something went wrong !!", "error");
        }
        this.getFSADataCY();
        this.getFSADataPY();
    }
    handleSubmitPY(event) {
        //event.stopPropagation();
        event.preventDefault();
        const fields = event.detail.fields;
        fields.Application_Applicant__c = this.applicantValue;
        fields.Loan_Application__c = this.recordId;
        fields.Year__c = this.yearPY;
        fields.RecordTypeId = this.fsaRecordTypeId;
        fields.Id = this.fsaPY.Id;
        //this.template.querySelector('lightning-record-edit-form').submit(fields);
        saveFSARecord({
            applicantId:this.applicantValue,
            expObj: fields,
            isCurrentYear: false,
            recordId:this.recordId
        })
            .then((response) => {
                console.log("saveFSARecord " + JSON.stringify(response));
                this.showToastMessage("Success", "Record updated successfully", "success");
                this.getFSADataCY();
                this.getFSADataPY();
            })
            .catch((error) => {
                this.showToastMessage("Error", "Something went wrong !!", "error");
            });
           
    }

    renderedCallback() {
        if (!this.isRendered) {
            // Create and append styles dynamically
            const style = document.createElement('style');
            style.innerText = `
            .fsa .slds-input{
                padding-left: 10px;
            }
                .slds-has-error .slds-input__icon {
    display: none;
}
            .slds-tabs_default__nav {
                background: #1c2238;
                border-bottom: 1px solid #2a2f45;
            }
            .slds-tabs_default__link {
                color: rgba(255, 255, 255, 0.7) !important;
            }
            .slds-tabs_default__item.slds-is-active .slds-tabs_default__link {
                color: #ffffff !important;
                border-bottom-color: #1467eb !important;
            }
            .slds-tabs_default__content {
                background: #12172b;
                color: #ffffff;
            }
            `;
    
            // Append the styles to the .styleContainer
            this.template.querySelector('.styleContainer')?.appendChild(style);
    
            // Prevent re-adding styles
            this.isRendered = true;
        }
    }
    handleApplicantChange(event) {
        event.stopPropagation();
        this.applicantValue = event.detail.value;
        if(event.detail.value == 'Consolidated' || this.hasLoanStagePsvOrDisbursement) {
            this.isConsolidated = true;
        }else {
            this.isConsolidated = false;
        }
        this.getFSADataCY();
        // this.getFSADataPY();
        setTimeout(() => {
            this.fetchDocumentDetails();
        }, 200);
        
    }

    handleActive(event){
        event.stopPropagation();
        if(event.target.value == 'PY') {
            this.getFSADataPY();
           // alert('event.target.value');
        }
    }

    handleStopPropagation(event) {
        event.stopPropagation();
    }

    handleBlur() {
        const inputCmp = this.template.querySelector('[data-id="itrFilingDatePy"]');
        
        const internalInput = inputCmp.shadowRoot.querySelector('input');
        const value = internalInput?.value;

        console.log('Fetched value:', value);

        if (value) {
            const selectedDate = new Date(value);
            const today = new Date();
            today.setHours(0, 0, 0, 0);

            if (selectedDate > today) {
                this.showToastMessage('Invalid Input', 'ITR Filling Date cannot be a future date.', 'error');
                internalInput.value = '';
            }
        }
    }      

    fetchDocumentDetails() {
        getDocumentDetails({ recordId: this.recordId, applicant: this.applicantValue })
        .then((data) => {
            if (data) {
                this.documentDetails = data;
                this.documentId = data.Content_Document_Id__c;
                this.documentUrl = data.Document_URL__c;
            }
        })
        .catch((error) => {
            console.error('Error fetching document details:', error);
            this.documentDetails = null;
        });
    }

    openCamera() {
        console.log('this.applicantValue: '+this.applicantValue);
        const fileInput = document.createElement('input');
        fileInput.type = 'file';
        fileInput.accept = 'image/*,application/pdf'; // application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel
        fileInput.style.display = 'none';

        fileInput.addEventListener('change', (event) => {
            const file = event.target.files[0];
            if (file) {
                console.log('Selected File:', file.name);
                const reader = new FileReader();
                reader.onload = () => {
                    const base64 = reader.result.split(',')[1];
                    this.uploadFile(file.name, base64, file.type, this.applicantValue);
                };
                reader.readAsDataURL(file);
            }
        });

        document.body.appendChild(fileInput);
        fileInput.click();
        document.body.removeChild(fileInput);
    }

    uploadFile(fileName, base64Data, fileType, appValue) {
        console.log('fileType: '+fileType);
        if (fileType != 'EXCEL_X') {
            uploadFileToContent({
                fileName: fileName,
                base64Data: base64Data,
                fileType: fileType,
                recordId: this.recordId,
                applicant: appValue
            })
            .then((result) => {
                console.log('File uploaded successfully:', result);
                this.documentUrl = result; 
                this.showToastMessage("Success", "Image uploaded successfully", "success");
                this.fetchDocumentDetails(); 
                
            })
            .catch((error) => {
                console.error('Error uploading file:', error);
                this.showToastMessage("Error", "Image upload failed!", "error");
            });
        } else{
            this.showToastMessage("Error", "Excel cannot be uploaded!", "success");
        }
    }

    // handleDelete() {
    //     if (!this.documentId) {
    //         console.error('No document found to delete.');
    //         return;
    //     }
    //     console.log('this.documentId: '+this.documentId);
    //     deleteDocument({ recordId:this.recordId, contId: this.documentId })
    //     .then(() => {
    //         console.log('Document deleted successfully');

    //         // Clear UI after deletion
    //         this.documentDetails = null;
    //         this.documentUrl = null;
    //         this.documentId = null;

    //         // Refresh document details
    //         this.fetchDocumentDetails();
    //     })
    //     .catch((error) => {
    //         console.error('Error deleting document:', error);
    //     });
    // }

    handleView() {
        console.log('applicantValue:'+this.applicantValue);
        console.log('handle view');
        checkFiletype({recordId: this.recordId, applicant: this.applicantValue})
        .then((result) => {
            this.fileType = result;
            console.log('this.fileType: '+this.fileType);
            console.log('this.documentUrl: '+this.documentUrl);
            if(this.fileType == 'PDF') {
                this.pdfURL = this.documentUrl;
            } else {
                this.imageURL = this.documentUrl;
            }
            setTimeout(() => {
                this.showImage = true;
            }, 200);
            
        })
        .catch((error) => {
            console.log('error fileType: '+error);
        })
    }
    handleClose() {
        this.showImage = false;
    }
    reUploadFile() {
        const fileInput = document.createElement('input');
        fileInput.type = 'file';
        fileInput.accept = 'image/*,application/pdf'; // ,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel
        fileInput.style.display = 'none';

        fileInput.addEventListener('change', (event) => {
            const file = event.target.files[0];
            if (file) {
                console.log('Selected File:', file.name);
                const reader = new FileReader();
                reader.onload = () => {
                    const base64 = reader.result.split(',')[1];
                    this.reUploadDoc(file.name, base64, file.type, this.applicantValue);
                };
                reader.readAsDataURL(file);
            }
        });

        document.body.appendChild(fileInput);
        fileInput.click();
        document.body.removeChild(fileInput);
    }
    reUploadDoc(fileName, base64Data, fileType, appValue) {
        this.documentUrl = '';
        console.log('fileType: '+fileType);
        if (fileType != 'EXCEL_X') {
            reUploadFileToContent({
                fileName: fileName,
                base64Data: base64Data,
                fileType: fileType,
                recordId: this.recordId,
                applicant: appValue
            })
            .then((result) => {
                console.log('File uploaded successfully:', result);
                this.fileType = '';
                this.pdfURL = '';
                this.imageURL = '';
                this.showImage = false;
                setTimeout(() => {
                    this.documentUrl = result; 
                    this.fetchDocumentDetails();
                    setTimeout(() => {
                        this.handleView();
                        this.showToastMessage("Success", "Image uploaded successfully", "success");
                    }, 200);
                }, 200);
                
                
            })
            .catch((error) => {
                console.error('Error uploading file:', error);
                this.showToastMessage("Error", "Image upload failed!", "success");
            });
        } else{
            this.showToastMessage("Error", "Excel cannot be uploaded!", "success");
        }
    }
}