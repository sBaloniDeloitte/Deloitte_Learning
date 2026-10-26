import { api, LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import FORM_FACTOR from '@salesforce/client/formFactor';
import ADD_ICON_2 from '@salesforce/resourceUrl/AddIcon';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { createRecord, updateRecord } from "lightning/uiRecordApi";
import TIME_ZONE from '@salesforce/i18n/timeZone';
import ADDRESSTYPE from '@salesforce/schema/Application_Verification__c.Address_Type__c';
import VERIFICATION_STATUS from '@salesforce/schema/Application_Verification__c.Verification_Status__c';
import OGL from '@salesforce/schema/Application_Verification__c.OGL__c';
import VERIFICATION_FLAG from '@salesforce/schema/Application_Verification__c.Verification_Flag__c';
import STAGE from '@salesforce/schema/Application_Verification__c.Stage__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import FCU_OBJECT from '@salesforce/schema/Application_Verification__c';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName1';
import createNotesRecords from '@salesforce/apex/Utility.createNotesRecords';
import createNewChecklist from '@salesforce/apex/FCUController.createNewChecklist';
import deleteNewChecklist from '@salesforce/apex/FCUController.deleteNewChecklist';
import updateSendBackRemark from '@salesforce/apex/FCUController.updateSendBackRemark';
import uploadFile from '@salesforce/apex/FCUController.uploadFile';
import storeContent from '@salesforce/apex/FCUController.storeContent';
//import reassignSelectedFCU from '@salesforce/apex/FCUController.reassignSelectedFCU';
import getDynamicFieldLayout from '@salesforce/apex/FCURecordPageController.getDynamicFieldLayout';
import getParentRecordRelatedObject from '@salesforce/apex/FCUController.getParentRecordRelatedObject';
// import getFCUStatus from '@salesforce/apex/FCURecordPageController.getFCUStatus';
import fetchParentDetails from '@salesforce/apex/FCUController.fetchParentDetails';
import getChildData from '@salesforce/apex/FCUController.getChildData';
//import updateParentStatus from '@salesforce/apex/FCUController.updateParentStatus';
//import updateAcceptRec from '@salesforce/apex/FCUController.updateAcceptRec';
import checkIfParentRec from '@salesforce/apex/FCUController.checkIfParentRec';
import updateNotAcceptRec from '@salesforce/apex/FCUController.updateNotAcceptRec';
import checkIfIsVendorRelated from '@salesforce/apex/FCUController.checkIfIsVendorRelated';
import getContentVersion from '@salesforce/apex/FCUController.getContentVersion';
import getRecordTypeName from '@salesforce/apex/RecordActionButtonController.getRecordTypeName';
import UserId from '@salesforce/user/Id';
import SHORT_REASON from '@salesforce/schema/Application_Verification__c.Short_Reason__c';
import BROAD_REASON from '@salesforce/schema/Application_Verification__c.Broad_Reason__c';
import { getRecord } from "lightning/uiRecordApi";


export default class fcuDocumentUploadCmp extends NavigationMixin(LightningElement) {
    @api recordId;

    @track spinnerRun = true;

    @track geoCordinates = '';
    @track latitude = '';
    @track longitude = '';

    @track addIcon = '';
    @track isMobile = false;
    @track selecteddocCheckId = '';

    @track activeSections = [];

    @track clustersChecklist = [];

    @track selecteddocCheckId = '';

    @track remarksList = [];

    @track sentbackText = '';
    @track selectedsentBackId = '';
    @track showSendBackScreen = false;

    @track childData = [];

    @track parentDetails = [];

    @track selectedRecords = [];
    @track selectedRecordsApplicant = [];
    @track samplerId = '';
    @track remarks = '';
    @track samplerName = '';
    @track showreAssignScreen = false;
    //@track savedSampler = undefined;
    @track remarksValue = '';

    @track selectedFCUId = '';

    @track addressOptions = [];
    @track flagOptions = [];
    @track oglOptions = [];
    //@track addressValue = '';
    @track isrelatedtovendor = false;
    @track isVendorChildRelated = false;
    @track filteredAddressOptions = [];
    @track disableverificationflag = true;
    @track disablereason = true;
    @track disableOgl = true;
    allBroadReasonOptions = [];
    shortReasonOptions = [];
    broadReasonOptions = [];
    selectedShortReason = '';
    selectedBroadReason = '';
    selectedVerificationStatus = '';
    shortReasonControllerValues = {};
    isExecutive = false;
    @track flagOptions = [
        { label: 'Approved', value: 'Clear' },
        { label: 'Not Approved', value: 'Not Clear' }
    ];
    @track oglOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];
    selectedFlag = '';
    selectedOgl = '';
    @wire(getObjectInfo, { objectApiName: FCU_OBJECT })
    fcuInfo;


    userId = UserId;

    @wire(getRecord, { recordId: '$userId', fields: ["User.Name", "User.Id"] })
    currentUser;


    @wire(getPicklistValues, { recordTypeId: '$fcuInfo.data.defaultRecordTypeId', fieldApiName: VERIFICATION_STATUS })
    addressPicklistValues({ data, error }) {
        console.log('RecordTypeId used --> ', this.fcuInfo?.data?.defaultRecordTypeId);

        if (data) {
            this.addressOptions = data.values;
            // this.filterAddressOptions();
            //this.addressValue = 'Local';
        } else {
            console.log('addressPicklistValues Error --> ' + JSON.stringify(error));
        }
    }
    // Fetch picklist values for Short Reason
    @wire(getPicklistValues, { recordTypeId: '$fcuInfo.data.defaultRecordTypeId', fieldApiName: SHORT_REASON })
    shortReasonPicklistValues({ data, error }) {
        if (data) {
            console.log('Short reason options fetched:', data);
            this.allShortReasonOptions = data.values;
            this.shortReasonControllerValues = data.controllerValues;
            this.shortReasonOptions = this.filterShortReasonOptions();
        } else if (error) {
            console.error('Error fetching Short Reason picklist values:', error);
        }
    }
    // Fetch picklist values for Broad Reason based on Short Reason selection
    @wire(getPicklistValues, { recordTypeId: '$fcuInfo.data.defaultRecordTypeId', fieldApiName: BROAD_REASON })
    broadReasonPicklistValues({ data, error }) {
        if (data) {
            console.log('broad reason options fetched');
            this.allBroadReasonOptions = data.values;
            this.controllerValues = data.controllerValues;
            this.broadReasonOptions = this.filterBroadReasonOptions();
            console.log('check avialable broad reason', this.broadReasonOptions);
        } else if (error) {
            console.error('Error fetching Broad Reason picklist values:', error);
        }
    }
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [SHORT_REASON, BROAD_REASON, VERIFICATION_STATUS]
    })
    wiredRecord({ data, error }) {
        if (data) {
            this.selectedVerificationStatus = data.fields.Verification_Status__c?.value || '';
            this.selectedShortReason = data.fields.Short_Reason__c?.value;
            this.selectedBroadReason = data.fields.Broad_Reason__c?.value;
            console.log('selected options -->', this.selectedShortReason);
            console.log('selected options -->', this.selectedBroadReason);

            if (Array.isArray(this.allBroadReasonOptions) && this.allBroadReasonOptions.length > 0) {
                this.broadReasonOptions = this.filterBroadReasonOptions();
            } else if (Array.isArray(this.allShortReasonOptions) && this.allShortReasonOptions.length > 0) {
                this.shortReasonOptions = this.filterShortReasonOptions();
            }
        } else if (error) {
            console.error('Error loading record fields:', error);
        }
    }
    filterShortReasonOptions() {
        if (!this.selectedVerificationStatus || !this.shortReasonControllerValues || !this.allShortReasonOptions) {
            return [];
        }

        const controllingKey = this.shortReasonControllerValues[this.selectedVerificationStatus];
        if (controllingKey === undefined) {
            return [];
        }

        return this.allShortReasonOptions.filter(option =>
            option.validFor.includes(controllingKey)
        );
    }
    // Method to filter Broad Reason options based on the selected Short Reason
    filterBroadReasonOptions() {
        if (!this.selectedShortReason || !this.controllerValues || !this.allBroadReasonOptions) {
            return [];
        }

        const controllingKey = this.controllerValues[this.selectedShortReason];
        if (controllingKey === undefined) {
            return [];
        }

        return this.allBroadReasonOptions.filter(option =>
            option.validFor.includes(controllingKey)
        );
    }


    // Handle change in Short Reason selection
    handleShortReasonChange(event) {
        this.selectedShortReason = event.detail.value;
        console.log('short reason value', this.selectedShortReason);
        this.updateRecordField(this.recordId, SHORT_REASON.fieldApiName, this.selectedShortReason);
        // Refresh Broad Reason options based on new Short Reason selection
        this.broadReasonOptions = this.filterBroadReasonOptions();
    }

    // Handle change in Broad Reason selection
    handleBroadReasonChange(event) {
        this.selectedBroadReason = event.detail.value;
        console.log('short reason value', this.selectedBroadReason);
        this.updateRecordField(this.recordId, BROAD_REASON.fieldApiName, this.selectedBroadReason);
    }
    get classAccordion() {
        return this.isMobile ? 'acc' : 'acc accordion'
    }

    @wire(CurrentPageReference) pageRef;
    @track openReassignModal = false;
    @track selectedRecId;
    @track isParentRec;
    @track isProfileRec = false;
    @track selectedChildId;
    @track isRemarkScreen = false;
    @track remarks;
    @track isVendorRelated = false;
    @wire(getCurrentUserProfileName)
    getProfileName() {
        getCurrentUserProfileName({

        }).then(response => {
            console.log('response -->' + JSON.stringify(response));
            this.currentProfileName = response;
            if (this.currentProfileName === 'FCU Executive' || this.currentProfileName === 'FCU Admin') {
                this.isExecutive = true;
            }

        }).catch(error => {
            console.error('Error getCurrentUserProfileName -->', JSON.stringify(error));
        });
    }
    connectedCallback() {
        this.addIcon = ADD_ICON_2;
        if (FORM_FACTOR == 'Large') {
            this.isMobile = false;
        } else {
            this.isMobile = true;
        }

        console.log('recordId -->' + this.recordId);

        this.checkIfIsVendorRelated();

        // After the flag is set, continue the other logic
        this.fetchParentDetailsMain();
        this.fetchChildOnParentDetails();
        this.getUserLocationCordinates();
        this.setDynamicFieldLayout();
        this.getParentRecordRelatedObject();
        this.getProfileName();
        //this.getChildRecordRelatedObject();
        this.checkIfParentRec();
        registerListener("fcuApproved", this.fetchParentDetailsMain, this);

    }
    checkIfParentRec() {
        checkIfParentRec({
            recId: this.recordId
        }).then(response => {
            this.isParentRec = response;
        }).catch(error => {

        })
    }
    fetchParentDetailsMain() {
        fetchParentDetails({
            recordId: this.recordId
        }).then(response => {
            this.parentDetails = response;
            if (response != undefined) {
                this.isProfileRec = response.isProfileRecord;
            }
            console.log(`The parentDetails are: ${JSON.stringify(response)}`)
        }).catch(error => {
            console.error('Error fetchParentDetails -->' + JSON.stringify(error));
        });
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }


    @track dymanicFormList = []
    isDymanicFormListLoaded = false;
    setDynamicFieldLayout() {
        getDynamicFieldLayout({
            recordId: this.recordId
        }).then(response => {
            this.dymanicFormList = response.records[this.recordId];
            console.log(`The Values are 1: ${JSON.stringify(response)}`)
            console.log(`The Values are 2: ${JSON.stringify(response.records[this.recordId])}`)
            this.isDymanicFormListLoaded = true
        }).catch(error => {
            console.error('Error getDynamicFieldLayout -->' + JSON.stringify(error));
        });
    }

    updateParentRecord(evt) {
        console.log('DynamicForm')
        this.dymanicFormList[0].Value = evt.detail.value
        console.log(`The Values are 1: ${JSON.stringify(this.dymanicFormList)}`)
    }


    updateRecordField(recordId, fieldApiName, fieldValue) {
        const fields = {};
        fields['Id'] = recordId;
        fields[fieldApiName] = fieldValue;
        console.log('fieldApiName=:184' + fieldApiName);
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                console.log('fieldApiName=:188' + fieldApiName);
                // if(fieldApiName == 'Verification_Remarks__c'){
                //     this.showToastMethod('Remarks updated successfully!', 'Success', 'success');
                //     // this.template.querySelector('c-record-action-button').changeMessage(fieldApiName);
                // }
                if (fieldApiName == 'Approval_Status__c') {
                    this.showToastMethod('Status updated successfully!', 'Success', 'success');
                }

                if (fieldApiName == 'Verification_Status__c') {
                    this.showToastMethod('Verification Status updated successfully!', 'Success', 'success');
                    console.log(`I am here`);
                    // this.template.querySelector('c-record-action-button').changeMessage();
                    this.updateParentStatus()
                }
                if (fieldApiName == 'Short_Reason__c') {
                    this.showToastMethod('Short Reason updated successfully!', 'Success', 'success');
                }
                if (fieldApiName == 'Broad_Reason__c') {
                    this.showToastMethod('Broad Reason updated successfully!', 'Success', 'success');
                }

                this.fetchChildOnParentDetails();
                fireEvent(this.pageRef, "fcuEnableSubmit", "fcuEnableSubmit");
                fireEvent(this.pageRef, "fcuDetailCheck", "fcuDetailCheck");
            })
            .catch(error => {
                console.log('Error updating record --> ' + JSON.stringify(error));
            });
    }

    editClicked(event) {
        console.log(event.target.dataset.id);
        this.childData.forEach(docData => {
            console.log(JSON.stringify(docData));
            if (event.target.dataset.id == docData.fcuId) {
                docData.isEditClicked = true;
            }
        });
    }

    cancelEdit(event) {
        console.log(event.target.dataset.id);
        this.childData.forEach(docData => {
            if (event.target.dataset.id == docData.fcuId) {
                docData.isEditClicked = false;
                docData.temp = docData.remark;
                docData.isValueChanged = false;
            }
        });
    }

    handleOnchange(event) {
        //console.log(event.target.dataset.id);
        //console.log(event.target.value);

        var enteredRemark = event.target.value;
        this.childData.forEach(docData => {
            if (event.target.dataset.id == docData.fcuId && enteredRemark.length > 0) {
                docData.isValueChanged = true;
                docData.temp = enteredRemark;
            } else if (event.target.dataset.id == docData.fcuId && enteredRemark.length == 0) {
                docData.isValueChanged = false;
                docData.temp = enteredRemark;
            }
        });
    }
    handleSave(event) {
        //console.log(event.target.dataset.id);
        // this.childData.forEach(docData => {
        //     if(event.target.dataset.id == docData.fcuId && docData.isValueChanged){
        //         this.updateRecordField(event.target.dataset.id, 'Verification_Remarks__c', docData.temp);
        //         // window.location.reload();
        //     }
        // });

        let remarksMap = {};
        let recordIds = [];
        let title = 'Verification_Remarks__c';
        console.log('child data '+ JSON.stringify(this.childData));
        

        this.childData.forEach(docData => {
            if (event.target.dataset.id === docData.fcuId && docData.isValueChanged) {
                console.log('fcuId ' + docData.fcuId);
                
                remarksMap[docData.fcuId] = docData.temp;
                console.log('remarksMap ' + remarksMap);               
                recordIds.push(docData.fcuId);
                console.log('Docdata ' + docData);
                
                console.log('recordIds ' + recordIds);
                console.log('title ' + title);
                
            }
        });

        if (recordIds.length > 0) {
                console.log('remarksMap ' + JSON.stringify(remarksMap));
                console.log('recordIds ' + recordIds);
                console.log('title ' + title);
            createNotesRecords({title: title, remarksMap: remarksMap })
                .then(() => {
                    this.showToastMethod('Remarks Note created successfully!', 'Success', 'success');
                    this.fetchChildOnParentDetails(); // Optional if refresh is needed
                })
                .catch(error => {
                    console.error('Error creating remarks note:', JSON.stringify(error));
                });
        }
    }

    handleApprove(event) {
        this.updateRecordField(event.target.dataset.id, 'Approval_Status__c', 'Approved');
        // window.location.reload();
    }

    handleReAssign(event) {
        this.showreAssignScreen = true;
        this.selectedFCUId = event.target.dataset.id;
    }

    handlelookupselected(event) {
        console.log(JSON.stringify(event.detail));

        this.samplerId = event.detail.searchRecord.User__c;
        this.samplerName = event.detail.searchRecord.User__r.Name;
        console.log(this.samplerId);
    }

    handlelookupdeselected(event) {

        this.samplerId = '';
        this.samplerName = '';
    }

    handleremarksChange(event) {
        this.remarksValue = event.target.value;
    }

    handlecloseReAssign(event) {
        this.showreAssignScreen = false;
        this.samplerId = '';
        this.samplerName = '';
        this.remarksValue = '';
    }
    handleReAssignYes(event) {
        reassignSelectedFCU({
            samplerId: this.samplerId,
            remarks: this.remarksValue,
            recordId: this.selectedFCUId
        }).then(response => {
            this.showToastMethod('Success', 'FCU reassigned successfully.', 'success');
            this.updateRecordField(this.selectedFCUId, 'Approval_Status__c', 'Re-Assigned');
            this.handlecloseReAssign();
            // window.location.reload();
        }).catch(error => {
            this.spinnerRun = false;
            console.error('Error reassignSelectedFCU -->', JSON.stringify(error));
        });
    }
    get reassignVisibility() {
        return this.remarksValue != null && this.remarksValue != '' && this.remarksValue != undefined && this.samplerId != null && this.samplerId != '' && this.samplerId != undefined;
    }

    handleReject(event) {
        this.updateRecordField(event.target.dataset.id, 'Approval_Status__c', 'Rejected');
        // window.location.reload();
    }

    handleSentBack(event) {
        this.selectedsentBackId = event.target.dataset.id;
        this.showSendBackScreen = true;
        // 
    }
    handlecloseSentBackScreen() {
        this.sentbackText = '';
        this.selectedsentBackId = '';
        this.showSendBackScreen = false;
    }
    handleOnchangeSentBackRemark(event) {
        this.sentbackText = event.target.value;
    }
    handleSentBackToSampler(event) {
        this.updateRecordField(event.target.dataset.id, 'Approval_Status__c', 'Sent Back');
        this.handlecloseSentBackScreen();
        updateSendBackRemark({
            data: this.sentbackText,
            recordId: event.target.dataset.id
        }).then(responsesentback => {
            // window.location.reload();
        }).catch(error => {
            this.spinnerRun = false;
            console.error('Error fetchChildOnParentDetails -->', JSON.stringify(error));
        });

    }
    get sentBackVisibility() {
        return this.sentbackText != null && this.sentbackText != '' && this.sentbackText != undefined;
    }

    fetchChildOnParentDetails() {
        this.getProfileName();
        getChildData({
            recordId: this.recordId
        }).then(response => {
            console.log(`The childDetails are: ${JSON.stringify(response)}`)
            this.childData = response;
            //console.log(`The childDetails are: ${JSON.stringify(response)}`)
            this.childData.forEach(group => {
                // !this.isMobile &&
                if (group.verificationflag) {
                    this.selectedFlag = group.verificationflag;
                }
                if (group.showCheckList) {
                    let docCheckListNew = [...group.docChecklist];
                    var tempClusterList = [];

                    let clusterId = 1;
                    let clusterSize = 3;
                    if (this.isMobile) {
                        clusterSize = 2;
                    }
                    while (docCheckListNew.length > 0) {
                        let cluster = docCheckListNew.splice(0, clusterSize);
                        tempClusterList.push({ 'id': clusterId, 'data': cluster });
                        clusterId++;
                    }
                    group.docChecklist = tempClusterList;
                }

                if (group.approvalStatus == 'Sent for Approval' || group.approvalStatus == 'Accepted' || group.approvalStatus == 'Approved' || group.approvalStatus == 'Cancelled') {//|| group.approvalStatus == 'Complete'){
                    group.approvalInitiated = true;
                } else if (group.approvalStatus == 'Draft' || group.approvalStatus == 'Accepted By Admin') {
                    group.approvalNotInitiated = true;
                } else if (group.approvalStatus == 'Approved 1' || group.approvalStatus == 'Approved 2' || group.approvalStatus == 'Approved 3') {
                    group.approvalApproved = true;
                } else if (group.approvalStatus == 'Sent Back' || group.approvalStatus == 'Sent Back By Admin' || group.approvalStatus == 'Sent Back By Area Manager') {
                    group.approvalSentBack = true;
                } else if (group.approvalStatus == 'Rejected') {
                    group.approvalRejected = true;
                } else if (group.approvalStatus == 'Re-Assigned') {
                    group.approvalReAssigned = true;
                }

                if (group.approvalNotInitiated || group.approvalSentBack) {
                    group.disableAllEdit = false;
                } else if (group.approvalInitiated || group.approvalApproved || group.approvalReAssigned || group.approvalRejected) {
                    group.disableAllEdit = true;
                }
                if (group.disableOnNotAccept) {
                    group.disableAllEdit = true;
                }
                group.isValueChanged = false;
                if (group.remark) {
                    group.showRemark = true;
                }
                if (group.remarkHistory) {
                    group.showRemarkHistory = true;
                }
                if (group.sentBackRemark) {
                    group.showSentBack = true;
                }
                group.isEditClicked = false;
                //console.log('check if we have profile name here--'.this.currentProfileName);
                if (group.approvalStatus == 'Assigned To Executive' && this.currentProfileName === 'FCU Admin') {
                    group.disableAllEdit = false;//kalpesh
                }
                if ((group.approvalStatus == 'Complete' || group.approvalStatus == 'Initiated') && this.currentProfileName === 'FCU Executive') {
                    group.disableAllEdit = true;
                }
                if ((group.approvalStatus == 'Complete' || group.approvalStatus == 'Initiated') && this.currentProfileName === 'FCU Admin') {
                    group.editverificationremarks = true;
                }
                if (group.approvalStatus == 'Approved' && this.currentProfileName === 'Sampler') {
                    group.editverificationremarks = true;
                }
                if (group.approvalStatus == 'Assigned To Executive' && this.currentProfileName === 'FCU Executive') {
                    this.disablereason = false;
                    this.disableOgl = false;
                }
                if ((group.approvalStatus == 'Initiated' || group.approvalStatus == 'Complete') && this.currentProfileName === 'FCU Admin') {
                    this.disablereason = false;
                }
                if (group.approvalStatus == 'Assigned To Executive' && (this.currentProfileName === 'FCU Executive' || this.currentProfileName === 'FCU Admin')) {
                    group.editverificationremarks = true;
                }
                if (this.currentProfileName === 'Sampler' && group.approvalStatus == 'Approved') {
                    this.disableverificationflag = false;
                }
                if (this.currentProfileName === 'Credit Manager' || this.currentProfileName === 'Sampler') {
                    group.disableAllEdit = true;
                }
            });

            // this.activeSections = this.childData.map(resp=>resp.fcuName);

            this.selecteddocCheckId = '';

            this.showAccordian = true;
            this.spinnerRun = false;

            // console.log('response childData -->' + JSON.stringify(this.childData));
        }).catch(error => {
            this.spinnerRun = false;
            console.error('Error fetchChildOnParentDetails -->', JSON.stringify(error));
        });
    }

    openCamera(event) {
        this.selecteddocCheckId = event.target.dataset.id;
        //console.log('this.selecteddocCheckId -->' + this.selecteddocCheckId);
        this.template.querySelector('.hidden-input').click();
    }

    handleUpload(event) {
        //console.log(JSON.stringify(event));
        const file = event.target.files[0];
        //console.log('file -->'+file);

        if (file) {
            this.spinnerRun = true;

            //console.log('file --> '+JSON.stringify(file));

            this.compressImage(file).then(compressedFile => {
                const originalSize = file.size;
                const fileName = file.name;
                const fileType = file.type;
                const compressedReader = new FileReader();
                const compressedSize = compressedFile.size;

                compressedReader.onload = async () => {
                    const compressedUrl = compressedReader.result;
                    const base64Data = compressedUrl.split(',')[1];


                    try {
                        const result = await uploadFile({ base64Data, fileName, fileType });
                        //console.log('result uploadFile -->'+result);
                        if (result != 'Error in uploading documents') {
                            storeContent({
                                recordId: this.recordId,
                                contentId: result,
                                docId: this.selecteddocCheckId
                            }).then(response => {
                                console.log('response -->' + response);
                                this.fetchChildOnParentDetails();
                                fireEvent(this.pageRef, "fcuEnableSubmit", "fcuEnableSubmit");

                            }).catch(error => {
                                console.error('Error storeContent file -->', JSON.stringify(error));
                            });
                            this.showToastMethod('Success', 'Image uploaded successfully', 'success');
                        }
                        this.spinnerRun = false;
                    } catch (error) {
                        this.spinnerRun = false;
                        this.showToastMethod('Error', 'File upload failed.', 'error');
                        console.error('Error uploading file -->', JSON.stringify(error));
                    }
                };
                compressedReader.readAsDataURL(compressedFile);
            });
        }
        this.template.querySelector('.hidden-input').value = null;
    }

    compressImage(file) {
        return new Promise((resolve, reject) => {
            const img = document.createElement('img');
            const reader = new FileReader();

            reader.onload = (e) => {
                img.src = e.target.result;
                img.onload = () => {
                    const canvas = document.createElement('canvas');
                    const ctx = canvas.getContext('2d');
                    let newCompressionRatio = (file.size / 4000000)
                    this.compressionRatio = newCompressionRatio > 1.5 ? newCompressionRatio : 1.5
                    const scaleFactor = 1 / this.compressionRatio; // 150% 
                    const width = img.width * scaleFactor;
                    const height = img.height * scaleFactor;
                    canvas.width = width;
                    canvas.height = height;

                    ctx.drawImage(img, 0, 0, width, height);
                    ctx.fillStyle = "#113451";
                    ctx.font = "50px bold Arial";
                    const currentDateTime = new Date().toLocaleString('default', { timeZone: TIME_ZONE });
                    const textToFill = this.geoCordinates + '     ' + currentDateTime;
                    ctx.fillText(textToFill, 60, 100);
                    // PNG issue, can convert to JPEG
                    const outputFormat = file.type === 'image/png' ? 'image/jpeg' : file.type;

                    canvas.toBlob((blob) => {
                        if (blob.size < file.size) {
                            resolve(new File([blob], file.name, { type: outputFormat }));
                        } else {
                            console.log('Compressed image is larger than the original, reducing quality further');
                            canvas.toBlob((blob) => {
                                resolve(new File([blob], file.name, { type: outputFormat }));
                            }, outputFormat, 0.5);
                        }
                    }, outputFormat, 1);
                };
            };

            reader.onerror = (e) => reject(e);
            reader.readAsDataURL(file);
        });
    }

    handleRetake(event) {
        this.selecteddocCheckId = event.target.dataset.id;
        console.log('this.selecteddocCheckId -->' + this.selecteddocCheckId);
        this.template.querySelector('.hidden-input').click();
    }

    showImage(event) {
        console.log('ContentId -->' + event.target.dataset.id);
        console.log('ContentId -->' + event.target.dataset.name);
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: event.target.dataset.name
            }
        })
    }

    getUserLocationCordinates() {
        //get user's geo-cordinates
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition((position) => {
                var latitude = position.coords.latitude;;
                var longitude = position.coords.longitude;
                var longitude = position.coords.longitude;
                this.latitude = latitude;
                this.longitude = longitude;
                this.geoCordinates = '(' + latitude.toFixed(4) + ',' + longitude.toFixed(4) + ')';
                console.log('this.geoCordinates1 : ', this.geoCordinates);
            },
                (e) => {
                    //this.strError = e.message;
                },
                {
                    enableHighAccuracy: true,
                }
            );
        }
    }

    handleAddressTypeChange(event) {
        //this.updateRecordField(event.target.dataset.id, 'Address_Type__c', event.target.value);
        this.selectedVerificationStatus = event.detail.value;
        this.updateRecordField(event.target.dataset.id, 'Verification_Status__c', event.target.value);
        this.updateRecordField(event.target.dataset.id, 'Short_Reason__c', '');
        this.updateRecordField(event.target.dataset.id, 'Broad_Reason__c', '');
        // this.selectedShortReason = '';
        this.shortReasonOptions = this.filterShortReasonOptions();
        this.broadReasonOptions = this.filterBroadReasonOptions();

    }

    navigateToRecord() {
        console.log('Hi');
    }

    showToastMethod(toastTitle, toastMessage, toastVariant) {
        const evt = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
    @track viewFileModal = false;
    @track imageURL = '';

    viewReport() {
        /*console.log('ContentId -->' + event.target.dataset.id);
        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: event.target.dataset.id
            }
        })*/
        /* const documentImage = document.getElementById('documentImage');
         console.log('are we able to get doc id?'+documentImage);
         if(window.location.origin.includes('my.site.com')){
             this.imageURL = window.location.origin +'/losportal/sfc/servlet.shepherd/document/download/'+ event.target.dataset.id;
         }
         else{
             this.imageURL = window.location.origin +'/sfc/servlet.shepherd/document/download/'+ event.target.dataset.id;
         }
         //this.imageURL = URL.createObjectURL(blob);
         documentImage.src = this.imageURL;
         documentImage.style.display = 'block'; 
 
         this.viewFileModal = true;
         /*
         getContentVersion({
             recordId : event.target.dataset.id,
             
         }).then((result)=>{
             console.log('result -->'+JSON.stringify(result));
             const byteCharacters = atob(result.versionData);
             const byteNumbers = new Array(byteCharacters.length);
    
             for (let i = 0; i < byteCharacters.length; i++) {
                 byteNumbers[i] = byteCharacters.charCodeAt(i);  
             }
    
             const byteArray = new Uint8Array(byteNumbers);
             const blob = new Blob([byteArray], { type: 'image/png' });
             https://godrejfinanceservicecloud--gcdev2.sandbox.my.site.com/losportal/sfc/servlet.shepherd/document/download/069Bi00000317aPIAQ
             this.imageURL = URL.createObjectURL(blob);
             this.viewFileModal = true;
             console.log('URL.createObjectURL(blob) ',URL.createObjectURL(blob));
 
             
         }).catch(errorsavePanDetails=>{
             console.log('errorsavePanDetails -->'+ JSON.stringify(errorsavePanDetails.message));
         });*/

    }
    closeViewModal() {
        this.imageURL = '';
        this.viewFileModal = false;
    }

    handleAddDocuement(event) {
        createNewChecklist({
            recordId: event.target.dataset.id
        }).then(response => {
            this.showToastMethod('Success', 'New document added successfully!', 'success');
            this.fetchChildOnParentDetails();
        }).catch(error => {
            console.error('Error createNewChecklist -->', JSON.stringify(error));
        });
    }

    handleDeleteDocuement(event) {
        deleteNewChecklist({
            recordId: event.target.dataset.id
        }).then(response => {
            this.showToastMethod('Success', 'Document deleted successfully!', 'success');
            this.fetchChildOnParentDetails();
        }).catch(error => {
            console.error('Error deleteNewChecklist -->', JSON.stringify(error));
        });
    }

    getParentRecordRelatedObject() {
        getParentRecordRelatedObject({ recordId: this.recordId })
            .then(result => {
                this.isrelatedtovendor = result;
            })
    }

    handleAcceptRecord(event) {
        this.spinnerRun = true;
        // updateAcceptRec({
        //     recId:event.target.dataset.id
        // }).then(resp=>{
        //     this.spinnerRun = false;
        //     this.fetchChildOnParentDetails();
        // }).catch(error=>{
        //     this.spinnerRun = false;
        // })
        // // this.updateRecordField(event.target.dataset.id, 'Stage__c', 'Accepted By Admin');
    }
    handleNotAcceptRecord(event) {
        console.log('inside not accept');
        this.isRemarkScreen = true;
        this.selectedChildId = event.target.dataset.id;
    }
    cancelRemark() {
        this.isRemarkScreen = false;
    }

    handleRemark() {
        if (this.remarks == undefined || this.remarks == null || this.remarks == '') {
            this.showToastMessage('Error', 'Please fill the remarks in order to proceed.', 'Error');
        }
        else {
            this.spinnerRun = true;
            this.isRemarkScreen = false;
            console.log(`The Value is ${this.remarks}`);
            updateNotAcceptRec({
                recId: this.selectedChildId,
                remarks: this.remarks
            }).then(resp => {
                this.fetchChildOnParentDetails();
                this.spinnerRun = false;
            }).catch(error => {
                this.spinnerRun = false;
            })
        }
    }

    handleRemarkChanges(evt) {
        this.remarks = evt.target.value;
    }
    handleReassignRecord(event) {
        this.selectedRecId = event.target.dataset.id;
        this.openReassignModal = true;
    }
    closeReassingModal() {
        this.openReassignModal = false;
    }
    handleChildRefresh() {
        this.fetchChildOnParentDetails();
    }
    checkIfIsVendorRelated() {
        checkIfIsVendorRelated({ fcuId: this.recordId })
            .then(result => {
                this.isrelatedtovendor = result;
                this.filterAddressOptions();
                console.log('Is Vendor Related: ' + this.isrelatedtovendor);
            })
            .catch(error => {
                console.error('Error in checkLoanApplicationNull: ' + JSON.stringify(error));
            });
    }
    filterAddressOptions() {
        if (this.isrelatedtovendor) {
            // If isVendorRelated is true, filter out certain options
            console.log('addressOptions--' + JSON.stringify(this.addressOptions));
            this.filteredAddressOptions = this.addressOptions.filter(option =>
                option.label !== 'Screened' &&
                option.label !== 'RTC' &&
                option.label !== 'RTC-CNV');
            console.log('filteredAddressOptions--' + JSON.stringify(this.filteredAddressOptions));
        } else {
            // If not vendor-related, show all options
            this.filteredAddressOptions = this.addressOptions.filter(option =>
                option.label !== 'Referred');
            console.log('filteredAddressOptions--' + JSON.stringify(this.filteredAddressOptions));
        }
    }
    handleflagchange(event) {
        this.selectedFlag = event.target.value;
        const fcuid = event.target.dataset.id;
        console.log('Selected Flag:', this.selectedFlag);
        console.log('Record Id:', fcuid);
        this.updateflagvalue(fcuid, this.selectedFlag);
    }
    handleOglChange(event) {
        this.selectedOgl = event.target.value;
        const fcuid = event.target.dataset.id;
        console.log('Selected Flag:', this.selectedOgl);
        console.log('Record Id:', fcuid);
        this.updateoglvalue(fcuid, this.selectedOgl);
    }

    updateoglvalue(fcuid, flag) {

        //let verficationFlagUpdatedBy =`${this.currentUser.data.fields.Name.value} - ${this.formatDate(new Date())}` ;

        const fields = {
            Id: fcuid,
            OGL__c: flag,
        };

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.showToastMethod('Success', 'Record updated successfully!', 'success');
            })
            .catch(error => {
                console.error('Error updating the record -->', JSON.stringify(error));
            });
    }

    formatDate(date) {
        const month = String(date.getMonth() + 1).padStart(2, '0');
        let hours = date.getHours();
        const minutes = date.getMinutes();
        const ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12;
        hours = hours ? hours : 12; // the hour
        return `${date.getDate()}/${month}/${date.getFullYear()}, ${hours}:${date.getMinutes()} ${ampm}`;
    }
}