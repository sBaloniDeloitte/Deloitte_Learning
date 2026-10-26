import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
import fetchCollateralAHL from '@salesforce/apex/hl_technicalRecordController.fetchCollateralAHL';
//import fetchCollateralId from '@salesforce/apex/hl_technicalRecordController.fetchCollateralId';
import assigneeList from '@salesforce/apex/hl_technicalRecordController.assigneeList';
import checkUser from '@salesforce/apex/hl_technicalRecordController.checkUser';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import getLegalUsers from '@salesforce/apex/Utility.getLegalUsers';
import getInternalTechnicalUsers from '@salesforce/apex/COMM_TechnicalRecordPageController.getInternalTechnicalUsers';
import setDocument from '@salesforce/apex/GenericDocumentInitiateController.setDocument';
//import deleteDocumentCheckList from '@salesforce/apex/GenericDocumentInitiateController.deleteDocumentCheckList';
import insertFileRecord from '@salesforce/apex/GenericDocumentInitiateController.insertFileRecord';
import initiateTechnical from '@salesforce/apex/COMM_TechnicalRecordPageController.initiateTechnical';
import getTechnicalRecords from '@salesforce/apex/COMM_TechnicalRecordPageController.getTechnicalRecords';
import getCollateral from '@salesforce/apex/COMM_TechnicalRecordPageController.getCollateral';
import getTechEvalId from '@salesforce/apex/COMM_TechnicalRecordPageController.getTechEvalId';
import getTechnicalRecordsByCollateral from '@salesforce/apex/COMM_TechnicalRecordPageController.getTechnicalRecordsByCollateral';
import deleteDocumentsWithFiles from '@salesforce/apex/COMM_TechnicalRecordPageController.deleteDocumentsWithFiles';
import FORM_FACTOR from '@salesforce/client/formFactor';
import User_Id from '@salesforce/user/Id';
export default class Hl_technicalRecordTypeSelection extends NavigationMixin(LightningElement) {
    get reportOptions() {
        return [
            { label: 'Internal', value: 'Internal' },
            { label: 'External', value: 'External' },
        ];
    }

    @track progressStep = {
        step1: false,
        step2: false,
        step3: false,
        step4: false,
        step5: false
    }
    showTechnicalTable = false
    isEvaluationSelected = false

    value = '';// No default value is set
    @api showModal;
    @api recordId;
    @api trancheId;
    @track disableLoanReject = false;
    @track options1 = [];
    @track options2 = [];
    @track datatop = [];
    @track datatop1 = [];
    option
    optionTranche
    @track aplicationcolatteral;
    @track tranche;
    @track error;


    @track recordAllocation = false;
    @track technicalrecordId;
    @track objectFields = [];
    @track userList = [];
    optionUser;
    @track optionUser1 = [];
    data;

    @track allocated;

    @track optionsUsers;

    @track userDetails;
    @track error;
    @track checkAddress = false;
    @track checkSpin = false
    @track isTranch = true;
    plotNo;
    buildingName;
    floorNo;
    pincode;
    town;
    tehsil;
    district;
    state;
    // @track reportOptions;
    @track reportType;
    @api genericInitiate;

    @track documents = []
    @track technicals = []
    currentDocId;
    currentIndex;

    assigneeOptions = [];

    assigneeOptions1 = [];

    @track collateralAddress = '';

    @track helptext = '';
   // collateralId = '';
    showConfirmModal = false;
    showConfirmDocModal = false;

    originalCollateral;
    originalAssignee;

    pendingChangeType; // 'collateral' or 'assignee'
    pendingNewValue;
    collApplicationCollIdObject = [];


    get isMobile() {
        return FORM_FACTOR == 'Large' ? 'line slds-align_absolute-center' : 'linemobile slds-align_absolute-center'
    }
    @track profileName;
    @track userId = User_Id;
    @track isOperationProfile = false;
    @track loanStatus;
    @track loanStage;
    @track uploadedFiles = [];
    currentDocId;
    techEvalId;
    docAdded = false;
    loanAmount;
     @track showFlow = false;
    @track inputVariables = [];
    @track collateralRelatedTechnicals = [];
    @track techInitiated=false;//kalpesh

        showErrorToast(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Validation Error',
            message: message,
            variant: 'error',
        }));
    }

        showSuccessToast(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success',
        }));
    }

    handlePreview(event) {
        const contentDocId = event.target.dataset.id;
        //this.filePreviewUrl = event.target.dataset.url + '#toolbar=0';
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: contentDocId
            }
        })
    }




    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg'];
    }

     handleFormFactor() {
        console.log('handleFormFactor: ', this.formFactor);
        if (this.formFactor === "Large") {
            this.deviceType = "Desktop/Laptop";
        } else if (this.formFactor === "Medium") {
            this.deviceType = "Tablet";
        } else if (this.formFactor === "Small") {
            this.deviceType = "Mobile";
        }
    }
    get getProgressBar(){
        if(this.deviceType == 'Mobile'){
            return 'progress-bar-mobile';
        }
        return 'progress-bar';
    }

    get progressStages() {
        return [
            { key: 'step1', label: 'Select Type of Evaluation', completed: this.progressStep?.step1, showLine : true },
            { key: 'step2', label: 'Select Related Collateral', completed: this.progressStep?.step2, showLine : true },
            { key: 'step3', label: 'Select Assignee', completed: this.progressStep?.step3, showLine : true },
            { key: 'step4', label: 'Upload Documents', completed: this.progressStep?.step4, showLine : true },
            { key: 'step5', label: 'Initiate Report', completed: this.progressStep?.step5, showLine : true }
        ];
    }

    @wire(fetchCollateralAHL, { loanId: '$recordId' })
    picklistvalues({ error, data }) {

        if (data) {
            console.log('collateralsdata', data);
            this.datatop = data;
            for (let key in this.datatop) {
                console.log('collaterals', key, this.datatop[key]);
                this.option = {
                    label: this.datatop[key],
                    value: key
                };
                console.log('Option', this.option);
                this.options1 = [...this.options1, this.option]
                this.collApplicationCollIdObject = [...this.collApplicationCollIdObject, ];
                console.log('collaterals----->>', this.options1);


            }
            console.log('Options1', this.options1);
        } else if (error) {
            console.log('rahul is okay');
            window.console.log(error);

        }
    }

 fetchUserProfile() {
        getCurrentUserProfileName()
            .then((data) => {
                if (data) {
                    // Check if the user is a Technical Manager
                  //  if (data === 'Technical Manager') {
                        this.getCollaterals();
                        this.isEvaluationSelected = true;
                        this.isUserSelected = true;
                        this.progressStep.step1 = true;
                        this.progressStep.step2 = true;
                  //  }
                    this.profileName = data;
                    console.log('data :: ', data);
                }
            })
            .catch((error) => {
                console.log('Error while fetching profile name: ', error);
            });
    }    get finaloptions() {
        return [{ label: 'Technical Evaluation', value: 'Technical Evaluation' }];
    }

    connectedCallback() {
        this.fetchUserProfile();
        this.getLegalUser();
        this.setTechRecords();
        this.setAssignee();
        this.originalCollateral = this.aplicationcolatteral;
        this.originalAssignee = this.selectedAssignee;

    }

    getCollaterals() {
        getCollateral({ loanId: this.recordId })
            .then(data => {
                console.log('collateralsdata dd', data);
                this.datatop = data;
                for (let key in this.datatop) {
                    this.option = {
                        label: this.datatop[key],
                        value: key
                    };
                    this.aplicationcolatteral = key;
                    console.log('aplicationcolatteral ID:::', this.aplicationcolatteral);
                }
                // this.getCollateralId();
            }).catch(error => {
                console.error(error)
            })

        getTechEvalId({ loanId: this.recordId })
            .then(data => {
                console.log('Technical Data', data);
                // this.techEvalId = data.Id;
                // this.loanAmount = data.HL_Loan_Application__r.Sanction_Loan_Amount__c;
                 this.techEvalId = data.id;
                this.loanAmount = data.loanAmount;
                console.log('loanAmount', this.loanAmount);

                console.log('techEvalId :: ', this.techEvalId);
            }).catch(error => {
                console.error(error)
            })

    }

    // F(){
    //     console.log('Calling fetchCollateralId with:', this.aplicationcolatteral);

    //     if(this.aplicationcolatteral){
    //     fetchCollateralId({ appCollId:this.aplicationcolatteral })
    //         .then(data => {
    //             this.collateralId = data;
    //             console.log('collateralId', this.collateralId);
    //     }).catch(error => {
    //             console.error(error)
    //     })
    // }

    // }




    setAssignee() {
        assigneeList({ loanId: this.recordId })
            .then((data) => {
                this.assigneeOptions = data;
                if (this.assigneeOptions.length > 0) { this.selectedAssignee = this.assigneeOptions[0].value }
                console.log(`The Value is : ${JSON.stringify(this.selectedAssignee)}`)
            })
            .catch((error) => {
                console.error(`Error : assigneeList : ${JSON.stringify(error)}`);
            });
    }

    getLegalUser() {
        this.assigneeOptions1 = [];
        getLegalUsers({ loanId: this.recordId, type: 'Technical' })
            .then(result => {
                console.log('getLegalUsers result: ', JSON.stringify(result));
                let items = [];
                for (let key in result) {
                    items.push({ label: result[key], value: key });
                }
                this.assigneeOptions1 = JSON.parse(JSON.stringify(items));
                if (this.isTechManager) {
                    this.recordAllocation = true;
                }
                console.log('this.assigneeOptions1 ::  ', this.assigneeOptions1);
            })
            .catch(error => {
                // Handle error
                console.error('Error fetching legal users:', error);
            });
    }


    techRecords;
    handleChange(event) {
        this.progressStep.step1 = true;
        this.isEvaluationSelected = true;
        //event.detail --> action refernce
        //event.detail.value --> get information of the data
        this.techRecords = event.detail.value;
        this.recordAllocation = false;
        console.log('Option selected with value: ' + this.techRecords);
        //let val = getFieldValue(this.techRecords);
    }

    handleCollateralSelection(event) {
    const selectedValue = event.detail.value;
    console.log('selectedValue :: ', selectedValue)
    // fetchCollateralId({ appCollId:selectedValue })
    //         .then(data => {
    //             this.collateralId = data;
    //         }).catch(error => {
    //             console.error(error)
    //         })

    // If value changed and documents exist, ask for confirmation
    if (selectedValue !== this.aplicationcolatteral && this.documents?.length > 0) {
        this.pendingChangeType = 'collateral';
        this.pendingNewValue = selectedValue;
        this.showConfirmDocModal = true;
        return; // stop here, wait for user action
    }

    this.updateCollateral(selectedValue);
}

handleTechType(event){
    const selectedValue = event.detail.value;
    console.log('selectedTechType :: ', selectedValue);
    if (selectedValue == null) {
        return; 
    }
    this.reportType = selectedValue;
    if(this.reportType == 'Internal'){
      this.getInternalTechnicalUsers();
    }else{
        this.getLegalUser();
    }
}

getInternalTechnicalUsers() {
        this.assigneeOptions1 = [];
        getInternalTechnicalUsers({ loanId: this.recordId})
            .then(result => {
                console.log('getInternalTechnicalUsers result: ', JSON.stringify(result));
                let items = [];
                for (let key in result) {
                    items.push({ label: result[key], value: key });
                }
                this.assigneeOptions1 = JSON.parse(JSON.stringify(items));
                console.log('this.assigneeOptions1 Internal::  ', this.assigneeOptions1);
            })
            .catch(error => {
                console.error('Error fetching technical internal users:', error);
            });
}

updateCollateral(value) {
    this.aplicationcolatteral = value;
    this.progressStep.step2 = true;
    this.recordAllocation = true;
    this.isUserSelected = true;
    if (this.documents.length > 0) {
        this.progressStep.step4 = true;
        this.openTable = true;
    }

    this.options1.forEach(record => {
        console.log('this.aplicationcolatteral :: ', this.aplicationcolatteral);
        console.log('record :: ', record);
        if (record.value === value) {
            this.collateralAddress = record.label;
        }
    });

    if (value === '') {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Cannot initiate Technical Evaluation',
            message: 'Collateral is required.',
            variant: 'error',
        }));
    } else {
        this.checkAddress = false;
    }

    if (this.checkAddress === true) {
        getaddressDetails({
            loanId: this.recordId,
            appColId: value
        })
            .then(result => {
                if (result) {
                    this.addressData = result;
                    const addr = result[0];
                    this.plotNo = addr.plotNo;
                    this.buildingName = addr.buildingName;
                    this.floorNo = addr.floorNo;
                    this.pincode = addr.pincode;
                    this.town = addr.town;
                    this.tehsil = addr.tehsil;
                    this.district = addr.district;
                    this.state = addr.state;
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.message,
                    variant: 'error',
                }));
            });
    }
}


    // handleCollateralSelection(event) {
    //     console.log('event :: ', event);
    //     this.aplicationcolatteral = event.detail.value;
    //     this.progressStep.step2 = true;
    //     this.recordAllocation = true;

    //     console.log('value of value line 156', this.value);
    //     //if(this.value!==''){
    //     this.isUserSelected = true;
    //     this.progressStep.step2 = true;
    //     if (this.documents.length > 0) {
    //         this.progressStep.step4 = true;
    //         this.openTable = true
    //         // }
    //     }

    //     console.log('this.options1 -->' + JSON.stringify(this.options1));
    //     this.options1.forEach(record => {
    //         if (record.value == event.detail.value) {
    //             this.collateralAddress = record.label;
    //         }
    //     });
    //     console.log('Application Collateral-->' + this.aplicationcolatteral);
    //     if (this.aplicationcolatteral == '') {
    //         this.dispatchEvent(new ShowToastEvent({
    //             title: 'Cannot initiate Technical Evaluation',
    //             message: error,
    //             variant: 'error',
    //         }));

    //     }
    //     else {
    //         //addressValidated();
    //         this.checkAddress = false;
    //     }
    //     if (this.checkAddress == true) {
    //         console.log('fetching data from coll');
    //         this.showModal = false
    //         getaddressDetails({
    //             loanId: this.recordId,
    //             appColId: this.aplicationcolatteral
    //         })
    //             .then(result => {
    //                 console.log("addressData =>", JSON.stringify(result));
    //                 if (result) {
    //                     this.addressData = JSON.parse(JSON.stringify(result));
    //                     this.plotNo = this.addressData[0].plotNo;
    //                     this.buildingName = this.addressData[0].buildingName;
    //                     this.floorNo = this.addressData[0].floorNo;
    //                     this.pincode = this.addressData[0].pincode
    //                     this.town = this.addressData[0].town;
    //                     this.tehsil = this.addressData[0].tehsil;
    //                     this.district = this.addressData[0].district;
    //                     this.state = this.addressData[0].state;
    //                     //this.dataAdd = this.propData.nearestPropertyAddressList;
    //                     console.log('addressData', this.addressData);
    //                     console.log('plot no', this.addressData[0].plotNo);
    //                     //console.log('landRate-==========>'this.propData.landRate);
    //                     //console.log('result.nearestPropertyAddressList===>',this.propData.nearestPropertyAddressList);
    //                     console.log('gotcha');

    //                 }

    //             })
    //             .catch(error => {
    //                 console.log("error ==> ", error.message);
    //                 this.dispatchEvent(new ShowToastEvent({
    //                     title: 'Error',
    //                     message: error,
    //                     variant: 'error',
    //                 }));
    //             })
    //     }
    // }

    handleLoad(event) {
        console.log(event.type);
        console.log(JSON.stringify(event.detail));
    }

    hanCancel(event) {
        this.recordAllocation = false;
        console.log(event.type);
        console.log(JSON.stringify(event.detail));
    }

    handleSubmit(event) {
        this.recordAllocation = false;
        console.log(event.type);
        console.log(JSON.stringify(event.detail));
    }

    handleSuccess(event) {
        this.recordAllocation = false;
        console.log(event.type);
        console.log(JSON.stringify(event.detail));
    }

    handleError(event) {
        console.log(event.type);
        console.log(JSON.stringify(event.detail));
    }

    handleUserChange(event) {

        console.log('event -->' + JSON.stringify(event));
        if (this.documents.length > 0) 
            { this.progressStep.step4 = true; }
        this.userSelected = event.detail.value;
        this.selectedLabel = event.detail.value;
        if (this.userSelected == '--None--') {
            this.progressStep.step3 = false;
            console.log('Step 2: ' + this.progressStep.step2);
            this.initiateButtonVisibility = false;
        } 
        else {
            this.setDocList(); // or resetDocuments() if you want to refresh > this is being done to refresh the upload doc screen so that it doesnt come after doc selection in add new document
            this.openTable = true;
            this.progressStep.step3 = true;
            console.log('Step 2: ' + this.progressStep.step2);
            this.initiateButtonVisibility = true;
        }


        console.log('User selected is : ' + this.userSelected);
        console.log('User Name is : ' + this.selectedLabel);

        checkUser({ userId: this.userSelected })
            .then((result) => {
                console.log('09', result);
                this.userDetails = result;
                console.log('in get user', this.userDetails);

            });
    }

    openAddDocModal = false;
    openDocumentModal() {
        this.openAddDocModal = true;
    }

    handledoc(event) {
        console.log('Inside handle Doc');
        console.log('Inside handle Doc',event.detail);
        this.docAdded = true;
        this.setDocList();
    }

    closeDocumentModal() {
        this.openAddDocModal = false;
    }

    closeModal() {
        this.openAddDocModal = false;
    }

    resetDocuments() {
        setDocument({
            recordId: this.recordId,
            name: 'Technical Documents',
            applicationColl: this.aplicationcolatteral
        })
            .then(response => {
                console.log('response from reset', response);
                this.documents = response;
                this.closeDocumentModal();
                this.openTable = true;
                console.log('length', this.documents.length, this.documents);
                if (this.documents.length > 0) {
                    this.showDocTable = true;
                    console.log('324');
                } else {
                    this.showDocTable = false;
                    console.log('327');
                }
            })
            .catch(error => {
                console.log(error);
            });
    }
    deleteCheckList(evt){
        let currentId = evt.currentTarget.dataset.id;
        let index = evt.currentTarget.dataset.index;
        console.log(`The Record Id : ${currentId}`);
        deleteRecord(currentId)
        .then(() => {
            if(this.documents.length==1){
                    this.documents = [];
                    this.openTable = false;
                    //this.progressStep.step4 = false;
                }else{
                    this.documents.splice(index, 1);
                    //console.log(`The Serialize Value : ${JSON.stringify(this.documents)}`)
                    for(let indexF = 0;indexF<this.documents.length;indexF++){
                        this.documents[indexF].srno = indexF + 1
                    }
                }
            this.showToastMessage('Success', 'Document deleted successfully!', 'Success');
        })
        .catch(error => {
            this.showToastMessage('Error', 'Document cannot be deleted as it was uploaded by another user', 'error');
            console.error(error)
        })

        /*deleteDocumentCheckList({ recordId: currentId }).then(response => {
            // if(index != null && index != '' && index != undefined){
            if (this.documents.length == 1) {
                this.documents = []
                this.openTable = false;
            } else {
                this.documents.splice(index, 1);
                console.log(`The Serialize Value : ${JSON.stringify(this.documents)}`)
                for (let indexF = 0; indexF < this.documents.length; indexF++) {
                    this.documents[indexF].srno = indexF + 1
                }
            }
            // }

            console.log(`The Record Delete Status : ${response}`)
        }).catch(error => {
            console.error(error)
        })*/
    }

    showToastMessage(title, message, variant) {
    const evt = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
    });
    this.dispatchEvent(evt);
}

    setDocList() {
        setDocument({
            recordId: this.recordId,
            name: 'Technical Documents',
            applicationColl: this.aplicationcolatteral
        })
            .then(response => {
                this.documents = response
                console.log('The Value is documents: ' + response);
            })
            .catch(error => {
                console.log(error);
            });
    }

    setTechRecords() {
        getTechnicalRecords({ recordId: this.recordId }).then(response => {
            this.technicals = response
            if (this.technicals.length > 0) { this.showTechnicalTable = true }
        }).catch(error => {
            console.error(error)
        })
    }

    handleRecordSelection(event) {
        this.checkSpin = true;
        console.log('checking spin status', this.checkSpin);
        //this.reportType = 'External'
        console.log('this.techEvalId :: , ', this.techEvalId);
         console.log('this.loanAmount :: , ', this.loanAmount);
        // if(this.loanAmount==undefined || this.loanAmount ==0 ||  this.loanAmount ==null){
        //     this.dispatchEvent(new ShowToastEvent({
        //             title: 'Error',
        //             message: 'Please enter recommended loan amount for the product',
        //             variant: 'error',
        //         }),
        //     );
        //     return;
        // }
        // if (this.techEvalId == undefined && this.docAdded == true && (!this.documents || this.documents.length == 0)) {
        //     this.dispatchEvent(
        //         new ShowToastEvent({
        //             title: 'Error',
        //             message: 'Please upload Technical Document',
        //             variant: 'error',
        //         }),
        //     );
        //     return;
        // }
        if (this.techRecords && this.aplicationcolatteral && this.reportType && this.userSelected) {
            //Add validation for document upload
            // if (!this.documents || this.documents.length == 0) {
            //     console.log(`11`);
            //     if (this.techEvalId == undefined) {
            //         this.dispatchEvent(
            //             new ShowToastEvent({
            //                 title: 'Error',
            //                 message: 'Please upload Technical Document',
            //                 variant: 'error',
            //             }),
            //         );
            //         return;
            //     }
            // }
            for (let index = 0; index < this.documents.length; index++) {
                if (this.documents[index].isUploaded) {
                    console.log(`13`)
                    if (this.techEvalId == undefined) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'Please Upload all the Technical Documents',
                                variant: 'error',
                            }),
                        );
                        return;
                    }
                } else {
                    this.objectFields.push('OwnerId');
                    console.log('this.objecFields', this.objectFields);
                    this.recordAllocation = true;
                }
            }

            // if(this.genericInitiate && this.openTable){
            //     console.log(`11`)
            //     if(!this.documents || this.documents.length == 0){
            //         this.dispatchEvent(
            //             new ShowToastEvent({
            //                 title: 'Error',
            //                 message: 'Please upload Technical Document',
            //                 variant: 'error',
            //             }),
            //         );
            //         return;
            //     }
            //     for(let index =0;index <this.documents.length;index++){
            //         if(this.documents[index].isUploaded){
            //             console.log(`13`)
            //             this.dispatchEvent(
            //                 new ShowToastEvent({
            //                     title: 'Error',
            //                     message: 'Please Upload all the Technical Documents',
            //                     variant: 'error',
            //                 }),
            //             );
            //             return;
            //         }else{
            //             this.objectFields.push('OwnerId');
            //             console.log('this.objecFields',this.objectFields);
            //             this.recordAllocation=true;
            //         }
            //     }
            // }
            this.objectFields.push('OwnerId');
            console.log('this.objecFields', this.objectFields);
            this.recordAllocation = true;
        } else {
            if (!this.genericInitiate) { this.showModal = true; }
            if (this.techEvalId == undefined) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select type of Technical Valuation',
                        variant: 'error',
                    }),
                );
                return;
            }
        }

        //if(this.checkIfError()){
        if (this.aplicationcolatteral) {

            if (this.techRecords == 'Vetting_Report' && this.userDetails == true) {
                console.log('3', this.techRecords);
                console.log('4', this.userDetails);
                if (this.techEvalId == undefined) {

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error ',
                            message: 'Technical cant be assign to External user',
                            variant: 'error',
                        }),
                    );
                    this.checkSpin = false;
                }
            }
            else {
                console.log('inside then block', this.recordId);
                this.progressStep.step4 = true;
                this.progressStep.step5 = true;
                console.log('this.techEvalId ::: ', this.techEvalId);

                        const techInitiation = {
                      techEvalId: this.techEvalId,
                      loanId: this.recordId,
                      aplicationcolatteral: this.aplicationcolatteral, 
                      Owner: this.userSelected,
                      recordTypeName: this.techRecords,
                      reportType: this.reportType
                       };
                       
                       console.log('techInitiation>>>>',JSON.stringify(techInitiation));
                       const wrapString=JSON.stringify(techInitiation);
                        console.log('wrapString>>>>',wrapString);
                     initiateTechnical({createTechWrapperString: JSON.stringify(techInitiation) })
                // initiateTechnical({ techEvalId: this.techEvalId, recordTypeName: this.techRecords, loanId: this.recordId, aplicationcolatteral: this.aplicationcolatteral, Owner: this.userSelected, trancheId: this.trancheId, reportType: this.reportType })
                    .then((result) => {

                        console.log('inside then block',result);
                        console.log('in success' + JSON.stringify(result));
                        console.log(' this.techEvalId>>>'+ this.techEvalId);
                        console.log(' this.loanAmount>>>'+ this.loanAmount);
                        if(this.loanAmount >= 3000000 && this.profileName === 'Technical Manager'){

                            this.showFlow = true;
                            this.genericInitiate = false;
                        console.log(' this.techEvalId>>>'+ this.techEvalId);
                        console.log(' this.this.option.label>>>'+ this.option.label);
                            this.inputVariables = [
                                    {
                                        name: 'recordId',
                                        type: 'String',
                                        value: this.techEvalId 
                                    },
                                    {
                                        name: 'var_Application_Collateral',
                                        type: 'String',
                                        value: this.option.label
                                    },
                                ];
                        }
                        console.log(' this.inputVariables>>>'+ this.inputVariables);

                        if (result == 'Required Technical Already Initiated') {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: result,
                                    variant: 'error',
                                }),
                            );
                            this.checkSpin = false;
                        }
                        else {
                            this.technicalrecordId = result;

                            this.setTechRecords();
                            this.openTable = false;
                            this.documents = [];
                            this.techInitiated=true;//Kalpesh
                            this.dispatchEvent(new ShowToastEvent({
                                title: 'Success',
                                message: 'Technical initiated successfully!',
                                variant: 'success',
                            }));

                        }

                        this.techRecords = '';
                        setDocument({
                            recordId: this.recordId,
                            name: 'Technical Documents',
                            applicationColl: this.aplicationcolatteral
                        })
                            .then(response => {
                                this.documents = response
                            })
                            .catch(error => {
                                console.log(error);
                            });
                        this.aplicationcolatteral = '';
                        this.progressStep.step1 = false;
                        this.progressStep.step2 = false;
                        this.progressStep.step3 = false;
                        this.progressStep.step4 = false;
                        this.progressStep.step5 = false;
                        this.isEvaluationSelected = false;
                        this.recordAllocation = false;
                        this.isUserSelected = false;
                        //kalpesh start
                        if(this.techInitiated==true){
                            setTimeout(() => {
                                 window.location.reload();
                                }, 1500);
                        }
                        //kalpesh end
                    })
                    .catch((error) => {
    this.error = error;
    console.log('in error:', JSON.stringify(this.error));

    const errorMessage = error?.body?.message || error?.message || 'An unexpected error occurred.';

    this.dispatchEvent(new ShowToastEvent({
        title: 'Technical Evaluation Error',
        message: errorMessage,
        variant: 'error',
    }));

    this.checkSpin = false;
});
            }
        }


      //  initiateTechnical(this.techRecords);
        console.log('on save')

    }

    insertFileRecordToSalesforce(file) {
        insertFileRecord({
            fileName: file.name,
            fileSize: file.size,
            fileContentDocumentId: file.documentId,
            recordId: this.currentDocId,
            loanAppId: this.recordId // Associate with the specific record
        })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'File uploaded and associated with record!',
                        variant: 'success',
                    }),
                );
                this.setDocList();
            })
            .catch((error) => {
            });
    }

    handleFileChange(event) {
        this.progressStep.step4 = true; // whenever files uploaded successfully
        console.log('event-' + event);
        const files = event.detail.files;
        console.log('No. of files uploaded : ' + JSON.stringify(files));
        const recordId = event.target.dataset.id;
        console.log('Id-' + recordId);
        this.currentDocId = recordId;
        files.forEach(file => {
            // For each uploaded file, create an object with necessary details
            this.uploadedFiles.push({
                id: file.documentId,
                name: file.name,
                downloadUrl: file.downloadUrl
            });
        });
        for (var i = 0; i < files.length; i++) {
            this.insertFileRecordToSalesforce(files[i]);
        }
    }

    closeAction() {
        this.showModal = false;
        // console.log('closeModal');
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__recordPage',
        //     attributes: {
        //         recordId: this.recordId,
        //         objectApiName: 'Loan_Application__c',
        //         actionName: 'view'
        //     }
        // })

        // this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(new CustomEvent('close'));
        this.showModal = false;
    }

    get isTechManager() {
        return this.profileName == 'Technical Manager';
    }

     handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.showFlow = false;
            this.genericInitiate = false;
            this.closeAction();
            console.log('Flow completed');
            this.dispatchEvent(new CustomEvent('close'));
        }
    }

async handleShowAction() {
    this.showConfirmModal = true;
    // try {
    //     await this.setTechnicalRecords(); // Wait for records to load

    //     if (this.loanAmount >= 3000000 && this.loanAmount < 7500000 && this.collateralRelatedTechnicals.length < 2) {
    //         console.log("30 Lakhs");
    //         this.showErrorToast('Please select Technical Admin');
    //     } 
    //     else if (this.loanAmount >= 7500000 && this.collateralRelatedTechnicals.length < 3) {
    //         console.log("75 lakhs");
    //         this.showErrorToast('Please select Technical Admin');
    //     }
    //     else {
    //         this.showConfirmModal = true;
    //     }
    // } catch (error) {
    //     console.log('Error in handleShowAction:', error);
    //     this.showErrorToast('Something went wrong while validating technical records.');
    // }
}

// setTechnicalRecords() {
//     console.log('application Collateral', this.aplicationcolatteral);
//     console.log('loan Amount', this.loanAmount);
//     console.log('recordId', this.recordId);

//     return getTechnicalRecordsByCollateral({ collateralId: this.aplicationcolatteral, loanId: this.recordId })
//         .then(result => {
//             this.collateralRelatedTechnicals = result;
//             console.log('collateralRelatedTechnicals', this.collateralRelatedTechnicals);
//         })
//         .catch(error => {
//             console.error('Error fetching technicals:', error);
//             throw error; // re-throw to handle in handleShowAction()
//         });
// }
        closeConfirmModal() {
        this.showConfirmModal = false;
    }

    confirmCloseAction() {
       // this.genericInitiate= false;
        this.showConfirmModal = false;
        console.log('####');
        this.closeAction();
    }

        closeConfirmDocModal() {
        this.showConfirmDocModal = false;
        this.pendingChangeType = null;
        this.pendingNewValue = null;
    }

    confirmDocDeletion() {
        // Clear documents and apply pending change
        //this.documents = [];
        console.log('documents', this.documents);

    const documentIdsToDelete = this.documents.map(doc => doc.docId);
    console.log('documentIdsToDelete', documentIdsToDelete);
    deleteDocumentsWithFiles({ documentDetailIds: documentIdsToDelete })
    .then(() => {
        this.showSuccessToast('Documents deleted successfully');
        this.showConfirmDocModal = false;
        this.openTable = false;
        this.documents = [];
    })
    .catch(error => {
        this.showErrorToast('Deletion failed: ' + error.body.message);
    });
    }



}