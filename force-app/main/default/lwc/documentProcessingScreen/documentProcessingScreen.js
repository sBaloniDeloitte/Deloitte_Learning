import { LightningElement, api, wire, track } from 'lwc';
import getDocumentsList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getDocumentsList';
import isForm60Uploaded from '@salesforce/apex/COMM_DocumentDetailsScreenController.isForm60Uploaded';
import getDocumentChecklistRecords from '@salesforce/apex/COMM_DocumentDetailsScreenController.getDocumentChecklistRecords';
import getCustomerList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getCustomerList';
import getDocumentCategoryList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getDocumentCategoryList';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getChecklistMasterIds from '@salesforce/apex/COMM_DocumentDetailsScreenController.getChecklistMasterIds';
import savecreateLoanDetails from '@salesforce/apex/ScreenGenerationController.savecreateLoanDetails';
import getFiStatus from '@salesforce/apex/Credit_FIVerificationController.getFiStatus';
import staticgetAllApplicants from '@salesforce/apex/COMM_DocumentDetailsScreenController.staticgetAllApplicants';
import getfileIds from '@salesforce/apex/COMM_DocumentDetailsScreenController.getfileIds';
import checkApplicableFor from '@salesforce/apex/COMM_DocumentDetailsScreenController.checkApplicableFor';
import createChecklist from '@salesforce/apex/COMM_DocumentDetailsScreenController.createChecklist';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkDocumentChecklistCreated from '@salesforce/apex/COMM_DocumentDetailsScreenController.checkDocumentChecklistCreated';
//import checkDedupe from '@salesforce/apex/COMM_DocumentDetailsScreenController.checkDedupe';
//import getExistingDocChecklist from '@salesforce/apex/COMM_DocumentDetailsScreenController.getExistingDocChecklist';
import processOCRData from '@salesforce/apex/OCRProcessingService.processOCRData';
import canSeeVerifyCheckbox from '@salesforce/apex/AHL_UserAccessController.canSeeVerifyCheckbox';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import LA_STAGE from '@salesforce/schema/Opportunity.StageName';
import ID_FIELD from '@salesforce/schema/Document_Details__c.Id';
import IS_VERIFIED_FIELD from '@salesforce/schema/Document_Details__c.Is_Verified__c';
import getApplicantsWithType from '@salesforce/apex/COMM_DocumentDetailsScreenController.getApplicantsWithType';
import getRelatedDocumentCategory from '@salesforce/apex/COMM_DocumentDetailsScreenController.getRelatedDocumentCategory';
import createChecklistRecord from '@salesforce/apex/COMM_DocumentDetailsScreenController.createChecklistRecord';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";//sanwar(3/12/2025)
import canUserEditRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.canUserEditRecord';//sanwar(3/12/2025)
import getCurrentUserPermissionSets from '@salesforce/apex/Utility_V1.getCurrentUserPermissionSets';
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated';
import getSubStageValues from '@salesforce/apex/Utility_V1.getSubStageValues';
import getDocumentName from '@salesforce/apex/COMM_DocumentDetailsScreenController.getDocumentName';
import SendForFCUField from '@salesforce/schema/Document_Details__c.Send_For_FCU__c';
import FCU_STATUS from '@salesforce/schema/Document_Details__c.Screening_Status__c';

export default class documentProcessingScreen extends LightningElement {
 @track hideButton = false;
 @track isNotOpsAuthor = true;//sanwar(3/12/2025)
 @track oppSubStage = '';//sanwar(3/12/2025)
 @track isFormSixty=false;
 shoButton = true;

    @api set documents(value) {
        this._documents = value;
        if (Array.isArray(value)) {
            const flatDocs = [];

            value.forEach(category => {
                if (Array.isArray(category.documentList)) {
                    category.documentList.forEach(doc => {
                        flatDocs.push({

                            ...doc,
                            id: doc.docChecklistId,
                            name: doc.docMasterName || doc.acDocName || doc.docName || 'NoName',
                            docCategory: category.documentCategory, documentType: doc.category
                        });
                    });
                }
            });

            console.log('Final Flattened Documents for Table:', JSON.stringify(flatDocs, null, 2));
            this.documentList = value;
            this.showNoRecords = value.length === 0;
        }
    }
    get documents() {
        return this._documents;
    }
    get singleDoc() {
        return this.docs && this.docs.length
            ? [this.docs[this.currentIndex]]
            : [];
    }
    @api recordId;
    @api processName;
    @api processObject;                 //to get the object/process name
    @api showWidgetStyle = false        //to show document in widget style
    @api showHeaderFooter = false;      //to show header and footer
    @api headerText = '';
    @api addDocuments = false;          //to show add new document button
    @api showAddBigBtn = false;         //to show add new document big button
    @api docCategory = '';              //to get the document category for which new document will be created
    @api showAccordionStyle = false;
    @api showSummaryStyle = false;
    @api ckyc;
    @api loginChecklist;
    @api fromSales;
    @api isDisabled;
    @wire(CurrentPageReference) pageRef;
    @track docname;
    @track allDocumentsForNavigation = [];
    @track sortedBy = 'Timestamp';  // Default sorting column
    @track sortDirection = 'asc';   // Default sorting direction
    @track modalVisibility = false;
    @track isSpinnerLoading = false;
    @track showApplicantPicker = false;
    @track applicantOptions = [];
    applicantList = [];
    selectedApplicantId = '';
    //selectedApplicantType = '';
    selectedCustomerType = '';
    financialStatus = '';
    @track docCheckList = [];
    @track modalMasterIds = [];
    @track modalMasterDeletes = [];
    _appDetailMap = new Map(); 
    @track showSplitViewModal = false;
    @track showDocumentTable = false;
    @track selectedDocumentId;
    @track selectedDocumentName = '';
    @track selectedContentId = '';
    @track selectedApplicantType = '';
    @track selectedDocumentData;
    @track selectedDocExtension = '';
    @track selectedShowMaskingCheck = false;
    @track selectedIsAcknowledged = false;
    @track selectedOcrApplicable = false;
    @track selectedContentVersion = '';
    @track selectedIsUploaded = false;
    @track docs = [];
    @track canShowVerify = false;
    @track isVerified = false;
    @track isForFCU = false;
    @track disableVerified = false;
    @track currentIndex = 0;
    @track totalDocuments = 0;
    @track editFields = true;
    @track status = '';
    //ckyc = true;
    layoutItemSize = 2;
    cssContainer = 'cssContainer';
    cssMain = 'document-processing-main';
    showNoRecords = false;
    isLoading = false;
    selectedApplicantName;
    applicantPickValOptions = [];
    categoryPickValOptions = [];
    @track categoryVal = 'All';
    @track applicantVal = 'All';
    openAddDocument = false;
    @track docDetaiList;
    @track displayList;
    @track fiStatus = false; // To store FI Status result
    @track allChecklist = [];
    @track selectedChecklistData = [];
    @track showhistory = false;
    @track vcontentId;
    @track fileIds = '';
    @track error = '';
    @track applicant = false;
    @track createdNewDocTable = [];
    @track showOCRProcessing = false;
    showDateAndLoanCol = false;
    isHLReleated = false;
    @track isLead = false;
    stageName = '';
    @track isRendered = false;
    isMobileOrTablet = false;
    isSalesStage = false;
    @track sendForFCU = false;
    @wire(getRecord, { recordId: '$recordId', fields: [LA_STAGE] })
    wiredLoan({ data, error }) {
        if (data) {
            this.stageName = data.fields.StageName.value;
            console.log(' this.stageName -----'+ this.stageName);
            if(this.stageName=='Sales login'){
                this.isSalesStage=true;
            }
        }
    }
    
    get isCUStage() {
        return ((this.stageName || '').toLowerCase() === 'credit underwriting') || ((this.stageName || '').toLowerCase() === 'disbursement') ||  ((this.stageName || '').toLowerCase() === 'psv');
    }
    @api
    openSplitView(documentArray, startIndex) {
        this.docs = documentArray;
        this.currentIndex = startIndex;
        this.totalDocuments = this.docs.length;
        this._showSplitViewModal = true;
        this._updateSelected();
        setTimeout(() => this._refreshSplitViewComponents(), 0);
    }
    _updateSelected() {
        const doc = this.docs[this.currentIndex];
        console.log('Selected document for split view:Kshitiz', JSON.stringify(doc));
        this.selectedApplicantName = doc.custName;
        this.selectedApplicantType = doc.applicantType;
        this.selectedCustomerType = doc.customerType;
        this.financialStatus = doc.financialApplicant;
        this.selectedDocumentId = doc.id;
        this.selectedDocumentName = doc.name;
        this.selectedContentId = doc.contentId;
        this.selectedDocumentData = { ...doc };
        console.log('selectedDocumentData: Kshitiz', JSON.stringify(this.selectedDocumentData));

        this.sendForFCU = false;
        this.showAdditionalDoc();
    }
    @wire(getRecord, {
        recordId: '$selectedDocumentId',
        fields: [IS_VERIFIED_FIELD]
    })
    wiredDoc({ data, error }) {
        if (data) {
            this.isVerified = data.fields.Is_Verified__c.value === true;
            this.disableVerified = false;
        } else if (error) {
            this.disableVerified = true;
        }
    }

    @wire(canSeeVerifyCheckbox)
    wiredVerifyAccess({ data, error }) {
        if (data) {
            console.log('Verify access check:', JSON.stringify(data));
            this.canShowVerify = !!data.allowed;
        } else if (error) {
            console.error('Verify access error:', JSON.stringify(error));
            this.canShowVerify = false;
        }
    }
    get disablePrev() {
        return this.currentIndex <= 0;
    }
    get disableNext() {
        return this.currentIndex >= this.totalDocuments - 1;
    }
    handlePrev() {
        if (!this.disablePrev) {
            this._goToIndex(this.currentIndex - 1);
        }
    }
    handleNext() {
        if (!this.disableNext) {
            this._goToIndex(this.currentIndex + 1);
        }
    }
    _goToIndex(idx) {
        this.currentIndex = idx;
        this._updateSelected();

        setTimeout(() => {
            this._refreshSplitViewComponents();
        }, 0);
    }
    @api
    refreshDocumentDisplay(documentData) {
        if (!documentData) return;
        this.singleDocumentData = documentData;
        this.contentDocId = documentData.contentId;
        this.docname = documentData.name;
        this.extension = documentData.fileType || documentData.extension;
        this.displaySingleDocument();
    }
    @api set filterMasterIds(value) {
        this._filterMasterIds = value || [];
        console.log('filterMasterIds set to:', this._filterMasterIds);
        if (this._filterMasterIds.length > 0 && this.recordId) {
            console.log(' Fetching filtered documents with masterIds:', this._filterMasterIds);
            this.fetchFilteredDocuments();
        }
    }

    get filterMasterIds() {
        return this._filterMasterIds || [];
    }
    fetchFilteredDocuments() {
        console.log('Calling getDocumentChecklistRecords with masterIds:', JSON.stringify(this.filterMasterIds));

        this.showSummaryStyle = true;

        getDocumentChecklistRecords({
            recId: this.recordId,
            processObject: this.processObject || 'Loan Application',
            masterIds: this.filterMasterIds
        }).then(response => {
            console.log('Filtered documents received:', JSON.stringify(response, null, 2));
            const processedResponse = response.map(section => {
                const processedDocs = section.docDetails.map(doc => {
                    console.log('RAW doc:', doc);
                    const addrRec = (doc.Applicant_Address__r || []).length
                        ? doc.Applicant_Address__r[0].Id
                        : null;
                    return {

                        documentType: doc.category,
                        ...doc,
                        isVerified: doc.isVerified === true,
                        addressRecordId: doc.addressRecordId || null,
                        showSplitView: this.stageName!= 'PSV' && this.stageName != 'Disbursement' && doc.contentId && doc.contentId !== null && doc.contentId !== '',
                        Uploadedby: doc.uploadedby || '-',
                        Timestamp: this.formatTimestamp(doc.CreatedDate),
                        financialApplicant: (doc.isFinancialApplicant == 'No')? 'Non-financial Applicant' : 'Financial Applicant',
                        ocrApplicable: doc.ocrApplicable,
                        _debug: {
                            hasContentId: !!doc.contentId,
                            showUpload: doc.showUpload,
                            showView: doc.showView,
                            originalTimestamp: doc.Timestamp,
                            originalUploadedBy: doc.Uploadedby
                        }
                    };
                });

                return {
                    ...section,
                    docDetails: processedDocs
                };
            });
            this.docDetaiList = processedResponse;
            console.log('Processed filtered response:', JSON.stringify(processedResponse, null, 2));
            this.displayList = processedResponse;
            this.showNoRecords = processedResponse.length === 0;
            this.showDocumentTable = processedResponse.length > 0;
            this.showSummaryStyle = true;
            this.showAccordionStyle = false;
            this.showWidgetStyle = false;
            this.handleSearch();

        }).catch(error => {
            console.error('Error fetching filtered documents:', JSON.stringify(error));
            this.showNoRecords = true;
            this.showDocumentTable = false;
        });
    }
    formatTimestamp(timestamp) {
        if (!timestamp) return '';
        try {
            const date = new Date(timestamp);
            if (isNaN(date.getTime())) return timestamp;
            return date.toLocaleString('en-IN', {
                day: '2-digit',
                month: '2-digit',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                hour12: true
            });
        } catch (error) {
            console.error('Error formatting timestamp:', error);
            return timestamp;
        }

    }
    renderedCallback() {
        if (FORM_FACTOR === "Large") { }
        else {
            this.layoutItemSize = 12;
        }
        if (!this.isRendered) {
            // Create and append styles dynamically
            const style = document.createElement('style');
            style.innerText = `
           
                .slds-file-selector__text.slds-medium-show {
              display: none;
            }
            .slds-file-selector__button.slds-button.slds-button_neutral{
                font-size: 0!important;
            }
             svg.slds-button__icon.slds-button__icon_left {
                margin: 0;
            }
            lightning-primitive-file-droppable-zone.slds-file-selector__dropzone {
                border: none;
                padding: 0;
            }
            slds-form-element__label{
                display: none;
            }
   
   
            `;

            // Append the styles to the .styleContainer
            this.template.querySelector('.styleContainer')?.appendChild(style);

            // Prevent re-adding styles
            this.isRendered = true;
        }
    }
    //sanwar(3/12/2025)
    @wire(getRecord, {
        recordId: "$recordId",
        fields: [SUBSTAGE_FIELD]
    })
    oppRecord({ data, error }) {
        if (data) {
            console.log('Data',data);
            this.oppSubStage = data.fields.Sub_stage__c.value;
            console.log("Sub Stage:", this.oppSubStage);
            canUserEditRecord({ recordId: this.recordId })
            .then(result => {
                console.log('At 380');
                if(result && this.oppSubStage == 'Ops Author'){
                    console.log('At 382');
                    this.isNotOpsAuthor = false;
                }
            });
        } else if (error) {
            console.error(error);
        }
    }

    checkAccessToButton(){
         getSubStageValues({loanId : this.recordId}).then(res=>{
            if(res == 'Credit Processing Verification' || res == 'Credit in-progress')
             getCurrentUserPermissionSets().then(data=>{
            if(data.includes('PS_Credit_Manager_HL') || data.includes('PS_Credit_Officer_HL')){
                this.shoButton = true;
            }else{
                this.shoButton = false;
            }

        }).catch(err=>{
            console.log('Error>>>'+JSON.stringify(err));
        })

        }).catch(error=>{
            console.log('Error fetching substage>>'+JSON.stringify(error));
        })
       

    }

    connectedCallback() {
        checkIfLoggedInUserIsHLRelated()
            .then(result => {
                var isHLUser = result.isHLRelated;
                if(isHLUser){
                    this.checkAccessToButton();
                this.isHLReleated = true;
                }
                 this.isMobileOrTablet = FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium';
        console.log('processName 52' + this.processObject);
        this.addEventListener('documentuploaded', this.handleDocumentUploaded.bind(this));
        this.addEventListener('ocrcompleted', this.handleOCRCompleted.bind(this));
        this.addEventListener('ocrready', this.handleOCRReady.bind(this));
        console.log('documentDetailsScreen connectedCallback');
        console.log('filterMasterIds:', this.filterMasterIds);
        console.log('recordId ' + this.recordId);
        if (this.filterMasterIds && this.filterMasterIds.length > 0) {
            console.log('Forcing summary style for filtered documents');
        }
        this.getAllApplicants();
        this.getDocCategories();
        this.getFiStatus();
        if (this.filterMasterIds.length) {
            this.fetchFilteredDocuments();
        } else {
            this.getDocInAccordionForm();
        }
        if (this.processName == 'Lead' || this.processName == 'Application Verification') {
            registerListener("handleRefreshDocument", this.getdocDetails, this);
        }
        else {
            registerListener("handleRefreshDocument", this.getDocInAccordionForm, this);
        }

        if (this.processObject == 'Account') {
            this.showDateAndLoanCol = true;
        }
        if (this.processName == 'Lead') {
            this.isLead = true;
        }
        this.checkCmpEditability();
                
            })
            .catch(error => {
                console.log('error -->', error);
            });
        

        
       
       
    }


    handleDocumentUploaded(event) {
        console.log('Document uploaded in main screen:', event.detail);
        const { documentData, ocrData } = event.detail;
        if (this.showSplitViewModal) {
            console.log('Refreshing split view after upload');
            this.selectedDocumentData = {
                ...this.selectedDocumentData,
                contentId: documentData.contentId || documentData.ContentDocumentId,
                fileType: documentData.fileType || documentData.FileType,
                docDetailId: documentData.docDetailId,
                contentVersionId: documentData.contentVersionId,
                addressRecordId: this.selectedDocumentData.addressRecordId
            };
            const viewCmp = this.template.querySelector('c-document-view-cmp');
            if (viewCmp) {
                viewCmp.refreshAfterUpload(this.selectedDocumentData, ocrData);
            }
            const detailsCmp = this.template.querySelector('c-document-details-update-cmp');
            if (detailsCmp) {
                detailsCmp.addressRecordId = this.selectedDocumentData.addressRecordId;
                detailsCmp.refreshDocumentDetails(
                    this.selectedDocumentData.docDetailId,
                    this.selectedDocumentData
                );
                detailsCmp.makeFieldsEditableNow();
                if (ocrData && Object.keys(ocrData).length) {
                    detailsCmp.populateFieldsFromOCR(ocrData);
                }
            }
        }
        this.refreshDocumentList();
    }
    handleOCRReady(event) {
        console.log('OCR data ready for form population:', event.detail);
        const { ocrMap, docDetailId } = event.detail;
        if (this.showSplitViewModal) {
            const documentDetailsCmp = this.template.querySelector('c-document-details-update-cmp');
            if (documentDetailsCmp) {
                documentDetailsCmp.populateFieldsFromOCR(ocrMap);
            }
        }
    }
    refreshDocumentList() {
        console.log('Refreshing document list');

        // Refresh the document list based on current mode
        if (this.filterMasterIds && this.filterMasterIds.length > 0) {
            this.fetchFilteredDocuments();
        } else if (this.showAccordionStyle || this.showSummaryStyle) {
            this.getDocInAccordionForm();
        } else {
            this.getdocDetails();
        }
    }
    getDocInAccordionForm() {
        console.log('getDocInAccordionForm - filterMasterIds:', this.filterMasterIds);
        this.showSummaryStyle = true;
        this.showAccordionStyle = false;
        this.showWidgetStyle = false;
        this.showDocumentTable = false;
        if (this.filterMasterIds && this.filterMasterIds.length > 0) {
            this.fetchFilteredDocuments();
            return;
        }
        console.log('this.processObject doc list : ' + this.processObject);
        getDocumentChecklistRecords({
            recId: this.recordId,
            processObject: this.processObject
        }).then(response => {
            console.log('RAW sections from server:', JSON.stringify(response, null, 2));
            const processedResponse = response
                .map(section => {
                    const processedDocs = section.docDetails
                        .filter(doc => !doc.name?.includes('Request and Response File'))
                        .map(doc => {
                            console.log('RAW doc:', doc);
                            return {

                                documentType: doc.category,
                                ...doc,
                                isVerified: doc.isVerified === true,
                                addressRecordId: doc.addressRecordId || null,
                                showSplitView: this.stageName!= 'PSV' && this.stageName != 'Disbursement' && (!!doc.contentId || doc.uploadedDateTime),
                                Uploadedby: doc.uploadedby || '-',
                                Timestamp: this.formatTimestamp(doc.uploadedDateTime),
                                ocrApplicable: doc.ocrApplicable
                            };
                        });

                    return {
                        ...section,
                        docDetails: processedDocs
                    };
                })
                .filter(section => section.docDetails.length > 0);
            this.docDetaiList = processedResponse;
            //this.displayList = processedResponse;
            this.handleSearch();
            //this.showDocumentTable = this.shouldShowDocumentTable(processedResponse);
            //this.handleSearch();
        }).catch(error => {
            console.error('error getDocumentChecklistRecords --> ' + JSON.stringify(error));
            this.showDocumentTable = false;
        })
    }
    handleDocumentTableUpdated() {
        getChecklistMasterIds({
            loanAppId: this.recordId,
            applicantId: this.appId
        })
            .then(masters => {
                this.docMasterIdList = masters || [];
                this.showDocumentTable = this.docMasterIdList.length > 0;
            })
            .catch(error => {
                console.error('Error refreshing checklist masters', error);
                this.showToast('Error', 'Could not refresh document list', 'error');
            });
    }
    getAllApplicants() {
        getCustomerList({ loanId: this.recordId })
            .then(response => {
                console.log('getCustomerList response----' + response);
                this.applicantPickValOptions = response;
            }).catch(error => {
                console.error('error getCustomerList --> ' + JSON.stringify(error));
            })
    }

    getDocCategories() {
        getDocumentCategoryList()
            .then(response => {
                console.log('getCustomerList response----' + response);
                this.categoryPickValOptions = response;
            }).catch(error => {
                console.error('error getCustomerList --> ' + JSON.stringify(error));
            })
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    getdocDetails() {
        if (this.recordId && this.processName) {
            this.isLoading = true;
            console.log('this.processName=:' + this.processName);
            console.log('this.recordId=:' + this.recordId);

            getDocumentsList({ recordId: this.recordId, processName: this.processName })
                .then(result => {
                    if (result && result.length > 0) {
                        console.log('Original documentList: ' + JSON.stringify(result));
                        if (this.fiStatus) {
                            result = result.map(doc => {
                                return {
                                    ...doc,
                                    showDelete: false,
                                    showRetake: false,
                                    showUpload: false
                                };
                            });
                        }
                        console.log('Updated documentList:', JSON.stringify(result));

                        this.documentList = result;
                        this.showNoRecords = false;
                    }
                    else {
                        this.showNoRecords = true;
                    }
                    this.isLoading = false;
                })
                .catch(error => {
                    this.showNoRecords = true;
                    this.isLoading = false;
                    console.error('Error fetching document details:', error);
                });
        }
        else {
            this.showNoRecords = true;
            console.error('recordId or processName missing');
        }
    }

    // categoryChange(event) {
    //     this.categoryVal = event.target.value;
    //     this.checkDocumentFilter();
    // }
    categoryChange(event) {
        this.categoryVal = event.target.value;
        this.handleSearch();
    }
    changeDocname(event) {
        this.docname = event.target.value;
        console.log('docname ' + this.docname);
        this.handleSearch();
    }

    // applicantChange(event){
    //     this.applicantVal = event.target.value;
    //     this.checkDocumentFilter();
    // }
    applicantChange(event) {
        this.applicantVal = event.target.value;
        console.log('applicantVal ' + this.applicantVal);
        this.handleSearch();

    }

    openAddDocs(event) {
        console.log('clicked');
        this.openAddDocument = true;
    }

    handleSearch() {
        console.log('this.displayList: ', this.displayList);
        console.log('1019========> ' + this.docname);
        console.log('1020========> ' + this.categoryVal);
        console.log('1021========> ' + this.applicantVal);


        let filteredList = JSON.parse(JSON.stringify(this.docDetaiList));

        filteredList = filteredList.map(section => {
            const filteredDocs = section.docDetails.filter(doc => {
                const matchesName = this.docname ? doc.name?.toLowerCase().includes(this.docname.toLowerCase()) : true;
                const matchesCategory = this.categoryVal && this.categoryVal !== 'All'
                    ? doc.docCategory?.toLowerCase().includes(this.categoryVal.toLowerCase())
                    : true;
                const matchesApplicant = this.applicantVal && this.applicantVal !== 'All'
                    ? doc.applicantId?.includes(this.applicantVal)
                    : true;
                return matchesName && matchesCategory && matchesApplicant;
            });

            return { ...section, docDetails: filteredDocs };
        }).filter(section => section.docDetails.length > 0);

        this.displayList = filteredList;
    }
    getFiStatus() {
        getFiStatus({ recordId: this.recordId })
            .then(result => {
                console.log('FI Status:', result);
                this.fiStatus = result; // Store the FI status result
                // Once FI status is retrieved, call getdocDetails to update accordingly
                //this.getdocDetails();
            })
            .catch(error => {
                console.error('Error fetching FI Status:', error);
            });
    }

    handleSort(event) {
        const fieldName = event.currentTarget.dataset.field;
        if (!fieldName) return;

        this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        this.sortedBy = fieldName;

        const dir = this.sortDirection;
        const norm = v => (v ?? '').toString().toLowerCase();

        const GLOBAL_FIELDS = ['custName', 'docCategory', 'Timestamp'];

        if (GLOBAL_FIELDS.includes(fieldName)) {
            const flat = this.displayList.flatMap(s => s.docDetails);

            flat.forEach(d => {
                if (d._ts === undefined) {
                    const raw = d.CreatedDate || d.uploadedDateTime || d.Timestamp;
                    d._ts = raw ? Date.parse(raw) : 0;
                }
            });

            // 3) sort
            flat.sort((a, b) => {
                if (fieldName === 'Timestamp') {
                    return dir === 'asc' ? (a._ts - b._ts) : (b._ts - a._ts);
                }
                const va = norm(a[fieldName]);
                const vb = norm(b[fieldName]);
                if (va < vb) return dir === 'asc' ? -1 : 1;
                if (va > vb) return dir === 'asc' ? 1 : -1;
                return 0;
            });

            this.displayList = [{ documentCategoryName: 'All', docDetails: flat }];
            this._isFlattened = true;
            return;
        }

        let sorted = JSON.parse(JSON.stringify(this.displayList));
        sorted.forEach(section => {
            section.docDetails.sort((a, b) => {
                let va = a[fieldName] ?? '';
                let vb = b[fieldName] ?? '';
                if (typeof va === 'string') va = va.toLowerCase();
                if (typeof vb === 'string') vb = vb.toLowerCase();

                if (typeof va === 'number' && typeof vb === 'number') {
                    return dir === 'asc' ? va - vb : vb - va;
                }
                return dir === 'asc'
                    ? (va > vb ? 1 : va < vb ? -1 : 0)
                    : (va < vb ? 1 : va > vb ? -1 : 0);
            });
        });
        this.displayList = sorted;
    }
    hanldeDownloadZip(event) {

    }
    handleSelectDocument(event) {
        this.selectedId = event.detail.searchRecord.Id;
        console.log('this.selectedId -->' + this.selectedId);
        console.log('this.101 -->' + event.detail.searchRecord.Id);
        console.log('recordId -->' + this.recordId);
        checkApplicableFor({ docMasterId: this.selectedId })
            .then((result) => {
                console.log('286 ' + result);
                if (result) {
                    this.applicant = true;
                    staticgetAllApplicants({ docMasterId: this.selectedId, loanId: this.recordId })
                        .then((result) => {
                            console.log('this.getAllApplicants-->' + JSON.stringify(result));
                            this.allChecklist = result;
                            if (this.allChecklist && this.allChecklist.length == 0) {
                                this.showToastMessage('Warning', 'Applicants are already added', 'warning')
                                this.selectedId = '';
                                this.template.querySelector('c-search-lookup').handleReset(event);
                            }
                        })
                        .catch((error) => {
                            console.error('Error getAllSanctionCheckList --> ', JSON.stringify(error));
                        });
                }
                else {
                    this.applicant = false;
                    console.log('299 ');
                    checkDocumentChecklistCreated({ docMasterId: this.selectedId, loanId: this.recordId })
                        .then((response) => {
                            if (response) {
                                this.showToastMessage('Warning', 'Document Checklist already created', 'warning');
                                this.template.querySelector('c-search-lookup').handleReset(event);
                            }
                        })
                }
            })
    }
    handleldeselectDocument() {
        this.selectedId = '';
        this.allChecklist = [];
        // this.newsanction = 'Other-';
        // this.selectedChecklistData = [];
        // this.showMessage = false;

    }
    // get tableVisibility(){
    //     return this.allChecklist.length > 0;
    // }
    handleSelectAllChange(event) {
        const shouldSelectAll = event.target.checked;
        this.isAllSelected = shouldSelectAll;
        this.selectedChecklistData = [];

        this.displayList = this.displayList.map(section => {
            const updatedDocs = section.docDetails.map(doc => {
                if (!doc.disabledChk) {
                    doc.selected = shouldSelectAll;
                    if (shouldSelectAll) {
                        this.selectedChecklistData.push(doc.id);
                    }
                }
                return doc;
            });
            return { ...section, docDetails: updatedDocs };
        });

        this.zipIdtoDownload();
    }
    handleCheckboxChange(event) {
        console.log(event.target.checked);
        const selecteddocid = event.target.dataset.id;
        if (event.target.checked) {
            this.selectedChecklistData.push(selecteddocid);
        } else {
            let temp = [];
            this.selectedChecklistData.forEach(record => {
                if (record != selecteddocid) {
                    temp.push(record);
                }
            });
            this.selectedChecklistData = temp;
        }
        console.log('selectedChecklistData -->' + JSON.stringify(this.selectedChecklistData));
        this.zipIdtoDownload();
    }
    handlesave(event) {
        console.log('selectedId ' + this.selectedId);
        console.log('selectedChecklistData ' + this.selectedChecklistData);
        console.log('loanId ' + this.recordId);
        checkDedupe({ docMasterId: this.selectedId, userIds: this.selectedChecklistData, loanId: this.recordId })
            .then((result) => {
                console.log('result ' + result);
                if (result) {
                    console.log('dedupe results found');
                    this.showToastMessage('Warning', 'Documents already added to the checklist. Kindly upload document.', 'warning');
                    getExistingDocChecklist({ docMasterId: this.selectedId, userIds: this.selectedChecklistData, loanId: this.recordId })
                        .then((result) => {
                            this.createdNewDocTable = result;
                            this.getDocInAccordionForm();
                            this.template.querySelector('c-search-lookup').handleReset(event);
                            this.allChecklist = [];
                            this.selectedId = '';
                            this.selectedChecklistData = [];
                            this.getAllApplicants();
                            this.getDocCategories();
                            this.getFiStatus();
                        })
                        .catch((error) => {
                            console.error('Error getExistingDocChecklist --> ', JSON.stringify(error));
                        });
                } else {
                    console.log('No results found');
                    createChecklist({ docMasterId: this.selectedId, userIds: this.selectedChecklistData, loanId: this.recordId })
                        .then((result) => {
                            this.showToastMessage('Success', 'New documents added successfully.', 'success');
                            this.dispatchEvent(new CustomEvent('documentsupdated', {
                                detail: { action: 'uploaded' }
                            }));
                            // this.fetchSanctions();
                            // this.handleClose();
                            console.log('result ' + result);
                            this.createdNewDocTable = result;
                            this.getDocInAccordionForm();
                            this.template.querySelector('c-search-lookup').handleReset(event);
                            console.log('this.createdNewDocTable -->' + JSON.stringify(this.createdNewDocTable));
                            this.allChecklist = [];
                            this.selectedId = '';
                            this.selectedChecklistData = [];
                            this.getAllApplicants();
                            this.getDocCategories();
                            this.getFiStatus();
                        })
                        .catch((error) => {
                            console.error('Error getAllSanctionCheckList --> ', JSON.stringify(error));
                        });
                }
            })
            .catch((error) => {
                console.error('error: Check Dedupe --> ' + JSON.stringify(error));
            })

    }
    get createdRecordsVisibility() {
        return this.createdNewDocTable.length > 0;
    }
    handlehistory(event) {
        console.log('Button clicked, event: ', event);
        this.vcontentId = event.target.dataset.id;  // Correctly fetching the data-id attribute
        console.log('vcontentId: ' + this.vcontentId);
        this.showhistory = true;  // Ensure this triggers the display logic for history
    }
    closeHistory(event) {
        this.showhistory = false;
    }
    zipIdtoDownload() {
        getfileIds({ docIds: this.selectedChecklistData })
            .then(result => {
                let fileDataList = JSON.parse(JSON.stringify(result));
                let fileIdsString = '';
                if (fileDataList) {
                    for (let i in fileDataList) {
                        fileIdsString += fileDataList[i] + '/';
                    }
                }
                if (fileIdsString.length > 0) {
                    fileIdsString = fileIdsString.replace(/.$/, "?");
                }
                this.fileIds = fileIdsString;
                this.error = undefined;
                console.log('fileIds ' + this.fileIds);
            })
            .catch(error => {
                console.log('error : ' + JSON.stringify(error));
                this.error = error;
            });
    } 
    getDownloaLink() {
        console.log('this.fileIds: '+this.fileIds);
        if(this.fileIds != null && this.fileIds != '') {
            const downloadUrl = '/sfc/servlet.shepherd/version/download/' + this.fileIds;
            const anchor = document.createElement('a');
            anchor.href = downloadUrl;
            anchor.setAttribute('download', ''); // This tells the browser to download the file
            document.body.appendChild(anchor);
            anchor.click();
            document.body.removeChild(anchor); // Clean up after the download
        } else{
            this.showToastMessage('Warning','No documents available to download','warning');
        }
    }
    handleChecklistselection(event) {
        console.log(event.target.checked);
        const selecteddocid = event.target.dataset.id;
        if (event.target.checked) {
            this.selectedChecklistData.push(selecteddocid);
        } else {
            let temp = [];
            this.selectedChecklistData.forEach(record => {
                if (record != selecteddocid) {
                    temp.push(record);
                }
            });
            this.selectedChecklistData = temp;
        }

        console.log('selectedChecklistData -->' + JSON.stringify(this.selectedChecklistData));
    }

    showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(toastEvent);
    }
    handleDeleted(event) {
        this.getDocInAccordionForm();
        this.getAllApplicants();
        this.getDocCategories();
        this.getFiStatus();
    }
    refreshMethod(event) {
        this.getDocInAccordionForm();
    }

    handleSplitViewClick(event) {
        event.preventDefault();
        event.stopPropagation();
        try {
            this.selectedDocumentId = event.target.dataset.documentId || event.currentTarget.dataset.documentId;
            this.selectedDocumentName = event.target.dataset.documentName || event.currentTarget.dataset.documentName;
            this.selectedContentId = event.target.dataset.contentId || event.currentTarget.dataset.contentId;
            this.selectedApplicantName = event.target.dataset.appName || event.currentTarget.dataset.appName || '';
            this.financialStatus = event.target.dataset.isFinance || event.currentTarget.dataset.isFinance || '';
            console.log('financial status>', this.financialStatus);
           // console.log('Looking for document ID:', this.selectedDocumentId);

            let foundDoc = null;
            this.displayList.forEach(section => {
                section.docDetails.forEach(doc => {
                    if (doc.id === this.selectedDocumentId) {
                        foundDoc = doc;
                    }
                });
            });
            this.sendForFCU = false;
            this.showAdditionalDoc();
            if (!foundDoc) {
                console.error('Document not found for Split View');
                this.showToastMessage('Error', 'Document data not found', 'error');
                return;
            }
            this.selectedApplicantType = foundDoc.applicantType || 'Primary Applicant';
            this.selectedCustomerType = foundDoc.customerType || 'Individual';
           /* this.selectedApplicantName = foundDoc.custName || '';
            this.financialStatus = foundDoc.isFinancialApplicant || 'Financial';*/
            this.selectedApplicantId = foundDoc.applicantId || '';
            this.selectedDocExtension = foundDoc.fileType || foundDoc.extension || '';
            this.selectedShowMaskingCheck = foundDoc.showMaskingCheck || false;
            this.selectedIsAcknowledged = foundDoc.isAcknowledged || false;
            this.selectedOcrApplicable = foundDoc.ocrApplicable || false;
            this.selectedContentVersion = foundDoc.contentVersion || '';
            this.selectedIsUploaded = !!foundDoc.contentId;
            this.selectedDocumentData = { ...foundDoc, addressRecordId: foundDoc.addressRecordId };
            
            console.log('Split View data prepared:', this.selectedDocumentData);
            this.showSplitViewModal = true;
            this.docs = this.displayList.reduce(
                (acc, section) => acc.concat(section.docDetails),
                []
            );
            this.totalDocuments = this.docs.length;
            this.currentIndex = this.docs.findIndex(d => d.id === this.selectedDocumentId);
            if (this.currentIndex < 0) {
                this.currentIndex = 0;
            }
            this._updateSelected();
            setTimeout(() => {
                this._refreshSplitViewComponents();
            }, 0);
            const ocrMap = this.selectedDocumentData.ocrMap
                || (this.selectedDocumentData.OCR_Extracted_Data__c
                    ? JSON.parse(this.selectedDocumentData.OCR_Extracted_Data__c)
                    : {});

            if (ocrMap && Object.keys(ocrMap).length) {
                const detailsCmp = this.template.querySelector('c-document-details-update-cmp');
                if (detailsCmp) {
                    detailsCmp.populateFieldsFromOCR(ocrMap);
                }
            }
            this.dispatchEvent(new CustomEvent('splitviewopened', {
                detail: {
                    documentId: this.selectedDocumentId,
                    documentName: this.selectedDocumentName,
                    contentId: this.selectedContentId,
                    documentData: foundDoc
                }
            }));

        } catch (error) {
            console.error('Error opening split view:', error);
            this.showToastMessage('Error', 'Failed to open Split View', 'error');
        }
    }

    _refreshSplitViewComponents() {
        console.log('Refreshing split view components');
        const documentViewCmp = this.template.querySelector('c-document-view-cmp');
        if (documentViewCmp) {
            documentViewCmp.refreshAfterUpload(this.selectedDocumentData, {});
        }
        const detailsCmp = this.template.querySelector('c-document-details-update-cmp');
        if (detailsCmp) {
            detailsCmp.addressRecordId = this.selectedDocumentData.addressRecordId;
            detailsCmp.clearScreen();
            detailsCmp.refreshDocumentDetails(
                this.selectedDocumentId,
                this.selectedDocumentData
            );
            detailsCmp.makeFieldsEditableNow();
        }
    }
    handleOCRCompleted(event) {
        console.log('Tiggering handleOCRCompleted');
        const { docDetailId, ocrMap } = event.detail;
        this.selectedDocumentId = docDetailId;
        const detailCmp = this.template.querySelector('c-document-details-update-cmp');
        if (detailCmp) {
            detailCmp.populateFieldsFromOCR(ocrMap);
            detailCmp.makeFieldsEditableNow();
        }
    }
    closeSplitViewModal(event) {
        this.fetchFilteredDocuments();
        
        this.displayList = [...this.displayList];
        console.log('this.displayList>>>>'+JSON.stringify(this.displayList));
        
        event.preventDefault();

        console.log(' Closing Split View modal');
        this.showSplitViewModal = false;
        this.selectedDocumentId = '';
        this.selectedDocumentName = '';
        this.selectedContentId = '';
        this.dispatchEvent(new CustomEvent('splitviewclosed', {
            detail: {
                action: 'closed'
            }
        }));

        
    }

    async handleVerifiedChange(event) {
        if (!this.canShowVerify) return; // not allowed
        const newVal = event.target.checked;
        this.disableVerified = true;
        try {
            await updateRecord({
                fields: {
                    [ID_FIELD.fieldApiName]: this.selectedDocumentId,
                    [IS_VERIFIED_FIELD.fieldApiName]: newVal
                }
            });
            this.isVerified = newVal;
            if (this.docs && this.docs[this.currentIndex]) {
                this.docs[this.currentIndex].Is_Verified__c = newVal;
            }
            
// this.docs = this.docs?.map((doc, idx) =>
//   idx === this.currentIndex
//     ? { ...doc, Is_Verified__c: newVal }
//     : doc
// );

            this.dispatchEvent(new ShowToastEvent({
                title: 'Saved',
                message: `Document is ${newVal ? 'successfully verified' : 'marked as unverified'}.`,
                variant: 'success'
            }));
        } catch (e) {
            this.isVerified = !newVal;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error updating Verified',
                message: e?.body?.message || 'Update failed',
                variant: 'error'
            }));
        } finally {
            this.disableVerified = false;
        }
    }

    @wire(getRecord, {
        recordId: '$selectedDocumentId',
        fields: [SendForFCUField]
    })

    wiredDocSendForFCU({ data, error }) {
        if (data) {
            this.isForFCU = data.fields[SendForFCUField.fieldApiName].value;
        } else if (error) {
            console.error('Error fetching record:', error);
            this.isForFCU = false;
        }
    }

    @wire(getRecord, {
        recordId: '$selectedDocumentId',
        fields: [FCU_STATUS]
    })
    fcustatus({ data, error }) {
        if (data) {
            this.status = data.fields[FCU_STATUS.fieldApiName].value;
        } else if (error) {
            console.error('Error fetching record:', error);
        }
    }
    handleFCUChange(event) {
        const newVal = event.target.checked;

        if (this.status !== 'Pending') {

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'RCU Team has already taken action on this document',
                    variant: 'error'
                })
            );

            // Revert checkbox back to checked
            event.target.checked = true;
            return;
        }
        console.log('newValue', newVal);
        updateRecord({
            fields: {
                [ID_FIELD.fieldApiName]: this.selectedDocumentId,
                [SendForFCUField.fieldApiName]: newVal
            }
        });
    }
    handleAddDocs() {
  console.log('[AddDocs] 1. handleAddDocs ENTER, isCUStage=', this.isCUStage, 'recordId=', this.recordId);
  // Previously a silent no-op when the stage didn't match - clicking the
  // button appeared to do nothing at all (no modal, no feedback), which
  // read as the screen having "frozen". Surfacing a toast here makes the
  // click's outcome visible instead of invisible.
  if (!this.isCUStage) {
      console.log('[AddDocs] EXIT - isCUStage is false');
      this.showToastMessage('Warning', 'Add Documents is only available in Credit Underwriting, PSV or Disbursement stage', 'warning');
      return;
  }

  // Guard against a not-yet-populated recordId - calling the Apex method
  // with a null loanId throws an AuraHandledException ("Loan ID is
  // required") that was still being caught below, but only AFTER the
  // modal/spinner had already opened - surfacing the check before opening
  // the modal avoids showing a spinner that is guaranteed to fail.
  if (!this.recordId) {
      console.log('[AddDocs] EXIT - recordId is falsy');
      this.showToastMessage('Error', 'Unable to load - record is not available yet. Please try again.', 'error');
      return;
  }

  console.log('[AddDocs] 2. resetting state, about to open modal');
  // fresh state
  this.docCheckList = [];
  this.modalMasterIds = [];
  this.modalMasterDeletes = [];
  this.selectedApplicantId = '';
  this.selectedApplicantType = '';
  this.showApplicantPicker = true;

  this.modalVisibility   = true;
  this.isSpinnerLoading  = true;
  console.log('[AddDocs] 3. modalVisibility set true, isSpinnerLoading set true - modal should now be visible with spinner');

  console.log('[AddDocs] 4. calling getApplicantsWithType Apex with loanId=', this.recordId);
  getApplicantsWithType({ loanId: this.recordId })
    .then(wrappers => {
      console.log('[AddDocs] 5. Apex resolved, wrappers=', JSON.stringify(wrappers));
      // An empty result previously left the modal open with a "Pick an
      // Applicant" dropdown that had nothing to pick - no error, no
      // options, no obvious way forward. Closing the modal with a clear
      // message instead of leaving it stuck open in that empty state.
      if (!wrappers || !wrappers.length) {
          console.log('[AddDocs] 6a. wrappers empty - closing modal');
          this.showToastMessage('Warning', 'No applicants found for this application', 'warning');
          this.handleClose();
          return;
      }
      console.log('[AddDocs] 6b. setting applicantList/applicantOptions, count=', wrappers.length);
      this.applicantList = wrappers; // [{id, name, type}]
      this.applicantOptions = wrappers.map(w => ({ label: w.name, value: w.id }));
      console.log('[AddDocs] 7. applicantOptions set:', JSON.stringify(this.applicantOptions));
    })
    .catch(err => {
      console.log('[AddDocs] CATCH - promise rejected:', JSON.stringify(err));
      console.error('load applicants (CU modal) error', err);
      this.showToastMessage('Error','Unable to load applicants','error');
      this.handleClose(); // close modal on failure
    })
    .finally(() => {
      console.log('[AddDocs] 8. FINALLY - clearing spinner');
      this.isSpinnerLoading = false;
      console.log('[AddDocs] 9. DONE - handleAddDocs fully complete');
    });
}

    handleClose() {
        this.modalVisibility = false;
        this.showApplicantPicker = false;
        this.selectedApplicantId = '';
        this.selectedApplicantType = '';
        // optional: clear queues
        this.modalMasterIds = [];
        this.modalMasterDeletes = [];

        // Refresh the main document table/filters after the modal closes
        // (merged from a previously duplicate/dead handleClose definition).
        this.getDocInAccordionForm();
        this.getAllApplicants();
        this.getDocCategories();
        this.getFiStatus();
    }

    async handleApplicantChange(event) {
        this.selectedApplicantId = event.detail.value;
        const sel = this.applicantList.find(a => a.id === this.selectedApplicantId);
        this.selectedApplicantType = sel ? sel.type : '';

        this.showApplicantPicker = false;
        this.isSpinnerLoading = true;

        try {
            await this._loadDocChecklistForApplicant(this.selectedApplicantId, this.selectedApplicantType);
        } finally {
            this.isSpinnerLoading = false;
        }
    }

    // Build docCheckList and _appDetailMap for the chosen applicant
    async _loadDocChecklistForApplicant(applicantId, applicantType) {
        console.log('inside the form 60 filter');
        this.docCheckList = [];
        this.modalMasterIds = [];
        this.modalMasterDeletes = [];
        this._appDetailMap = new Map();

        this.isFormSixty = await isForm60Uploaded({ applicantId: applicantId });

        const wrappers = await getRelatedDocumentCategory({
            identifier: 'fromLoan',
            recordId: this.recordId,
            applicantId: applicantId,
            applicantType: applicantType || ''
        });

        // seed existing applicant-level details into the map
        wrappers.forEach(w =>
            (w.docDetList || []).forEach(dd => {
                this._appDetailMap.set(dd.Document_Master__c, dd.Id);
            })
        );
console.log('inside the form 60 filter');
        // grouped checklist
        this.docCheckList = (wrappers || []).map(w => {
            const existingSet = new Set((w.docDetList || []).map(dd => dd.Document_Master__c));
            const requiredById = new Map((w.docDetList || []).map(dd => [dd.Document_Master__c, dd.Is_Required__c]));
            return {
                docType: w.docType,
                docList: (w.docList || []).map(dm => ({
                    Id: dm.Id,
                    Name: dm.Name,
                    identity: dm.Form_Common_Identifier__c, // enables front/back grouping
                    checked: existingSet.has(dm.Id),
                    isDisabled: requiredById.get(dm.Id) || false
                }))
            };
        });
    if (this.isFormSixty === false) {
        console.log('inside the form 60 filter');
        this.docCheckList = this.docCheckList.map(section => ({
            ...section,
            docList: section.docList.filter(dm => dm.Name !== 'Form 60')
        }));
    } else if (this.isFormSixty === true) {
        this.docCheckList = this.docCheckList.map(section => ({
            ...section,
            docList: section.docList.filter(dm => dm.Name !== 'PAN')
        }));
    }
    }

    // Passport/Aadhaar front/back grouping + queuing masters (exactly like Sales)
    docSelectHandler(event) {
        const masterId = event.currentTarget?.dataset?.id;
        const checked = event.currentTarget?.checked;
        if (!masterId) return;

        const allDocs = this.docCheckList.flatMap(s => s.docList);
        const clicked = allDocs.find(d => d.Id === masterId);
        const group = clicked?.identity
            ? allDocs.filter(d => d.identity === clicked.identity)
            : [clicked].filter(Boolean);

        group.forEach(doc => {
            const exists = this._appDetailMap.has(doc.Id);
            if (checked) {
                if (!this.modalMasterIds.includes(doc.Id)) this.modalMasterIds.push(doc.Id);
                this.modalMasterDeletes = this.modalMasterDeletes.filter(m => m !== doc.Id);
            } else {
                if (exists && !this.modalMasterDeletes.includes(doc.Id)) {
                    this.modalMasterDeletes.push(doc.Id);
                }
                this.modalMasterIds = this.modalMasterIds.filter(m => m !== doc.Id);
            }
        });

        // update UI
        this.docCheckList = this.docCheckList.map(section => ({
            docType: section.docType,
            docList: section.docList.map(doc => ({
                ...doc,
                checked: group.some(g => g.Id === doc.Id) ? checked : doc.checked
            }))
        }));

        console.log('to CREATE (masters) →', [...new Set(this.modalMasterIds)]);
        console.log('to UNCONSIDER (masters) →', [...new Set(this.modalMasterDeletes)]);
    }

    async addDocHandler() {
        if (!this.modalMasterIds.length && !this.modalMasterDeletes.length) {
            return this.showToastMessage('Warning', 'Select at least one document', 'warning');
        }
        this.isSpinnerLoading = true;
        try {
            await createChecklistRecord({
                docMasterIds: this.modalMasterIds,    // set Consider=true / create missing
                recordId: this.recordId,
                applicantId: this.selectedApplicantId,
                docIds: this.modalMasterDeletes // set Consider=false (no hard delete)
            });

            // clear queues and refresh the table the child is already showing
            this.modalMasterIds = [];
            this.modalMasterDeletes = [];
            await this.fetchFilteredDocuments();    // ← your existing method to reload table
            this.modalVisibility = false;

        } catch (e) {
            console.error('addDocHandler (CU modal) error', e);
            this.showToastMessage('Error', 'Could not update documents', 'error');
        } finally {
            this.isSpinnerLoading = false;
        }
    }

    
    updateApplicantsDedupe(event){
        console.log('Ishi 352----',event.detail.value);
        console.log('Ishi 352----',event.detail.valuesChanged);
        const valueChangeEvent2 = new CustomEvent("updatedapplicants", {
            detail: {
                value:event.detail.value ,
                valuesChanged :event.detail.valuesChanged
               
            }
        });
        this.dispatchEvent(valueChangeEvent2);

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
    handleError(event){
       this.fetchFilteredDocuments();
    }
    showAdditionalDoc() {
        getDocumentName({
            docId: this.selectedDocumentId
        })
            .then(result => {
                console.log('result for additional doc>>', result);
                if (result) {
                    this.sendForFCU = true;
                }
            })
            .catch(error => {
                console.error('Something went wrong →', error);
                this.sendForFCU = false;
            })
    }
}