import { LightningElement, api, wire, track } from 'lwc';
import getDocumentsList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getDocumentsList';
import getDocumentChecklistRecords from '@salesforce/apex/COMM_DocumentDetailsScreenController.getDocumentChecklistRecords';
import getCustomerList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getCustomerList';
import getDocumentCategoryList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getDocumentCategoryList';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
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
export default class DocumentDetailsScreen extends LightningElement {

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
                            docCategory: category.documentCategory
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
    @track sortedBy = 'Timestamp';  // Default sorting column
    @track sortDirection = 'asc';   // Default sorting direction
    @track modalVisibility = false;
    @track showSplitViewModal = false;
    @track selectedDocumentId = '';
    @track selectedDocumentName = '';
    @track selectedContentId = '';
    @track selectedCustomerType = '';
    documentList = [];
    //ckyc = true;
    layoutItemSize = 2;
    cssContainer = '';
    cssMain = '';
    showNoRecords = false;
    isLoading = false;
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
    showDateAndLoanCol = false;
    @track isLead = false;


    @api set filterMasterIds(value) {
        this._filterMasterIds = value || [];
        console.log('📋 filterMasterIds set to:', this._filterMasterIds);

        // If we have masterIds and recordId, fetch filtered data
        if (this._filterMasterIds.length > 0 && this.recordId) {
            console.log('🔍 Fetching filtered documents with masterIds:', this._filterMasterIds);
            this.fetchFilteredDocuments();
        }
    }

    get filterMasterIds() {
        return this._filterMasterIds || [];
    }
    fetchFilteredDocuments() {
        console.log('Calling getDocumentChecklistRecords with masterIds:', this.filterMasterIds);

        this.showSummaryStyle = true;

        getDocumentChecklistRecords({
            recId: this.recordId,
            processObject: this.processObject || 'Loan Application',
            masterIds: this.filterMasterIds
        }).then(response => {
            console.log('Filtered documents received:', JSON.stringify(response, null, 2));
            /*
            response.forEach((section, sectionIndex) => {
                console.log(` Section ${sectionIndex}:`, section.documentCategoryName);
                section.docDetails.forEach((doc, docIndex) => {
                    console.log(` Document ${docIndex}:`, {
                        name: doc.name,                    
                        docCategory: doc.docCategory,
                        docIdNumber: doc.docIdNumber,
                        showUpload: doc.showUpload, 
                        custName: doc.custName,    
                        customerType: doc.customerType
                    });
                });
            });
            */
            const processedResponse = response.map(section => {
                const processedDocs = section.docDetails.map(doc => {
                    return {
                        ...doc,
                        // ✅ Show Split View button only if document has been uploaded
                        showSplitView: doc.contentId && doc.contentId !== null && doc.contentId !== '',

                        // Debug info
                        _debug: {
                            hasContentId: !!doc.contentId,
                            showUpload: doc.showUpload,
                            showView: doc.showView
                        }
                    };
                });

                return {
                    ...section,
                    docDetails: processedDocs
                };
            });
        
        console.log('✅ Processed response with showSplitView:', JSON.stringify(processedResponse, null, 2));

            this.docDetaiList = processedResponse;
            this.displayList = processedResponse;
            this.showNoRecords = processedResponse.length === 0;

            this.showSummaryStyle = true;
            this.showAccordionStyle = false;
            this.showWidgetStyle = false;

            // Apply any existing search filters
            this.handleSearch();

        }).catch(error => {
            console.error('❌ Error fetching filtered documents:', JSON.stringify(error));
            this.showNoRecords = true;
        });
    }
    renderedCallback() {

        //console.log('FORM_FACTOR: '+FORM_FACTOR);
        if (FORM_FACTOR === "Large") { }
        else {
            this.layoutItemSize = 12;
        }
    }

    connectedCallback() {

        console.log('processName 52' + this.processObject);
        //testing data -----------------------
        // if(!this.recordId){
        //     this.recordId = 'a0gBi000000DLeXIAW';   //'00QBi00000Cbo2CMAR';
        //     this.processName = 'FI';    //'Lead';
        //     this.showWidgetStyle = true;
        // }
        //-------------------------
        console.log('🔗 documentDetailsScreen connectedCallback');
        console.log('📊 filterMasterIds:', this.filterMasterIds);
        console.log('recordId ' + this.recordId);
        if (this.filterMasterIds && this.filterMasterIds.length > 0) {
            console.log('🎯 Forcing summary style for filtered documents');
            this.showSummaryStyle = true;
            this.showAccordionStyle = false;
            this.showWidgetStyle = false;
        }
        if (!this._documents) {

            this.getAllApplicants();
            this.getDocCategories();
            this.getFiStatus();


            if (this.showHeaderFooter == true) {
                this.cssMain = 'border-field';
                this.cssContainer = 'slds-modal__content slds-p-around_medium no-padding';
            }
            else {
                this.showHeaderFooter = false;
            }
            if (this.filterMasterIds && this.filterMasterIds.length > 0) {
                console.log('🔍 Using filterMasterIds to fetch specific documents');
                this.fetchFilteredDocuments();
            } else {
                console.log('📡 No filterMasterIds, fetching all documents');

                if (this.showAccordionStyle || this.showSummaryStyle) {
                    this.getDocInAccordionForm();
                } else {
                    this.getdocDetails();
                }
            }
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
    }

    getDocInAccordionForm() {
        console.log('📡 getDocInAccordionForm - filterMasterIds:', this.filterMasterIds);

        if (this.filterMasterIds && this.filterMasterIds.length > 0) {
            this.fetchFilteredDocuments();
            return;
        }
        console.log('this.processObject doc list : ' + this.processObject);
        getDocumentChecklistRecords({
            recId: this.recordId,
            processObject: this.processObject
        }).then(response => {

            /*
            this.docDetaiList = response;
            this.displayList = response;
            console.log('this.displayList----' + JSON.stringify(this.displayList));
            this.handleSearch();

            */
            const processedResponse = response.map(section => {
                const processedDocs = section.docDetails.map(doc => {
                    return {
                        ...doc,
                        showSplitView: doc.contentId && doc.contentId !== null && doc.contentId !== ''
                    };
                });

                return {
                    ...section,
                    docDetails: processedDocs
                };
            });

            this.docDetaiList = processedResponse;
            this.displayList = processedResponse;
            this.handleSearch();
        }).catch(error => {
            console.error('error getDocumentChecklistRecords --> ' + JSON.stringify(error));
        })
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

                        // If FI status is true, update the documentList
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

    // handleSearch(){
    //     // this.displayList = this.docDetaiList;
    //     console.log('this.displayList: '+this.displayList);
    //     console.log('1019========> '+ this.docname);
    //     console.log('1020========> '+ this.categoryVal);
    //     console.log('1021========> '+ this.applicantVal);
    //     if(this.docname != '' && this.docname != undefined){
    //         this.displayList = this.displayList.filter(doc => doc.name.toLowerCase().includes(this.docname.toLowerCase()));
    //     }
    //     if(this.categoryVal != '' && this.categoryVal != 'All' && this.categoryVal != undefined){
    //         this.displayList = this.displayList.filter(doc => doc.docCategory.toLowerCase().includes(this.categoryVal.toLowerCase()));
    //     }
    //     if(this.applicantVal != '' && this.applicantVal != 'All' && this.applicantVal != undefined){
    //         this.displayList = this.displayList.filter(doc => doc.applicantId.includes(this.applicantVal));    
    //     }
    // }

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
        const fieldName = event.target.dataset.field;
        if (!fieldName) {
            console.log('No field to sort');
            return;
        }

        this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        this.sortedBy = fieldName;

        let sortedList = JSON.parse(JSON.stringify(this.displayList));

        sortedList.forEach(section => {
            section.docDetails.sort((a, b) => {
                let valA = a[fieldName] || '';
                let valB = b[fieldName] || '';

                if (typeof valA === 'string') valA = valA.toLowerCase();
                if (typeof valB === 'string') valB = valB.toLowerCase();

                if (typeof valA === 'number' && typeof valB === 'number') {
                    return this.sortDirection === 'asc' ? valA - valB : valB - valA;
                }

                if (this.sortDirection === 'asc') {
                    return valA > valB ? 1 : valA < valB ? -1 : 0;
                } else {
                    return valA < valB ? 1 : valA > valB ? -1 : 0;
                }
            });
        });

        this.displayList = sortedList;
    }


    handleAddDocs(event) {
        this.modalVisibility = true;
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
    handleClose() {
        this.modalVisibility = false;
        this.getDocInAccordionForm();
        this.getAllApplicants();
        this.getDocCategories();
        this.getFiStatus();

        // this.createdNewDocTable = null;
        // this.modalVisibility = false;
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
    /*  
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
    */
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
        this.selectedDocumentId = event.target.dataset.documentId || event.currentTarget.dataset.documentId;
        this.selectedDocumentName = event.target.dataset.documentName || event.currentTarget.dataset.documentName;
        this.selectedContentId = event.target.dataset.contentId || event.currentTarget.dataset.contentId;

        let foundDoc = null;
        this.displayList.forEach(section => {
            section.docDetails.forEach(doc => {
                if (doc.id === this.selectedDocumentId) {
                    foundDoc = doc;
                }
            });
        });

        if (foundDoc) {
            this.selectedCustomerType = foundDoc.customerType || '';
        }
        console.log('Split View clicked for:', {
            documentId: this.selectedDocumentId,
            documentName: this.selectedDocumentName,
            contentId: this.selectedContentId,
            customerType: this.selectedCustomerType

        });
        this.showSplitViewModal = true;
        this.dispatchEvent(new CustomEvent('splitviewopened', {
            detail: {
                documentId: this.selectedDocumentId,
                documentName: this.selectedDocumentName,
                contentId: this.selectedContentId
            }
        }));
    }
    closeSplitViewModal(event) {
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
    
}