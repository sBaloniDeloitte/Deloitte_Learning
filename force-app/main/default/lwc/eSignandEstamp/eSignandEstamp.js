import { LightningElement,track,api,wire } from 'lwc';
import getDocumentChecklistRecords from '@salesforce/apex/COMM_DocumentDetailsScreenController.getDocumentChecklistRecords';
import checkApplicableFor from '@salesforce/apex/COMM_DocumentDetailsScreenController.checkApplicableFor';
import staticgetAllApplicants from '@salesforce/apex/COMM_DocumentDetailsScreenController.staticgetAllApplicants';
import createChecklist from '@salesforce/apex/COMM_DocumentDetailsScreenController.createChecklist';
import getDocumentsList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getDocumentsList';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import RL from '@salesforce/schema/Document_Master__c.Requirement_Level__c'
import ess from '@salesforce/schema/Opportunity.E_seal_Shape__c'
import esc from '@salesforce/schema/Opportunity.E_seal_Colour__c'
import Document_Master from "@salesforce/schema/Document_Master__c";
import Opportunity from "@salesforce/schema/Opportunity";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import getAllStamps from '@salesforce/apex/COMM_DocumentDetailsScreenController.getAllStamps';
import parseEsignResponse from '@salesforce/apex/COMM_DocumentDetailsScreenController.parseEsignResponse';
import checkValidationBeforeGenerateEsignDoc from '@salesforce/apex/COMM_DocumentDetailsScreenController.checkValidationBeforeGenerateEsignDoc';
import postDocGenAPI from '@salesforce/apex/DocGenerationAPICallout.postDocGenAPI'
import initiateESignAPI from '@salesforce/apex/DocGenerationAPICallout.initiateESignAPI'
import getESignedDocumentStatus from '@salesforce/apex/DocGenerationAPICallout.getESignedDocumentStatus'
import downLoadESignedDocument from "@salesforce/apex/DocGenerationAPICallout.downLoadESignedDocument"
import getAuthorizedSignatories from '@salesforce/apex/COMM_DocumentDetailsScreenController.getAuthorizedSignatories';
import updateStatus from '@salesforce/apex/COMM_DocumentDetailsScreenController.updateStatus';
import updateStatusNonMand from '@salesforce/apex/COMM_DocumentDetailsScreenController.updateStatusNonMand';
import returnStatus from '@salesforce/apex/COMM_DocumentDetailsScreenController.returnStatus';
import returnStatusNonMand from '@salesforce/apex/COMM_DocumentDetailsScreenController.returnStatusNonMand'
import { updateRecord } from "lightning/uiRecordApi";
import checkSignatureType from '@salesforce/apex/COMM_DocumentDetailsScreenController.checkSignatureType';
import cancelESignedDocument from "@salesforce/apex/DocGenerationAPICallout.cancelESignedDocument";
import saveStampData from '@salesforce/apex/COMM_DocumentDetailsScreenController.saveStampData';
import checkOpportunity from '@salesforce/apex/DocGenerationAPICallout.checkOpportunity';
import getselectedDocId from '@salesforce/apex/DocGenerationAPICallout.getselectedDocId';
import saveEsignSequence from '@salesforce/apex/DocGenerationAPICallout.saveEsignSequence';
import checkOtherDoc from '@salesforce/apex/DocGenerationAPICallout.checkOtherDoc';
import opportunityDetails from '@salesforce/apex/DocGenerationAPICallout.opportunityDetails';
import syncContentDocumentIds from '@salesforce/apex/DocGenPreviewRequestWrapper.syncContentDocumentIds';
import getLoanDocuments from '@salesforce/apex/COMM_DocumentDetailsScreenController.getLoanDocuments';


// import canUserEditMandate from '@salesforce/apex/CaptureMandateController.canUserEditMandate';
import fetchAuthorizedSignatory from '@salesforce/apex/DocGenerationAPICallout.fetchAuthorizedSignatory';
import { CurrentPageReference } from 'lightning/navigation';
import initiateAPIRequest from '@salesforce/apex/eSealApiController.initiateAPIRequest';
import fetchNewEseal from '@salesforce/apex/DocGenerationAPICallout.fetchNewEseal';
import getNonManDocuments from '@salesforce/apex/DocGenerationAPICallout.getNonManDocuments';
import createNonManDocumentDetails from '@salesforce/apex/DocGenerationAPICallout.createNonManDocumentDetails';
import checkLatestDoc from '@salesforce/apex/DocGenerationAPICallout.checkLatestDoc';
import createOrGetDocumentDetail from '@salesforce/apex/COMM_DocumentDetailsScreenController.createOrGetDocumentDetail';
import uploadMandAndNonMandFile from '@salesforce/apex/COMM_DocumentDetailsScreenController.uploadMandAndNonMandFile';//kalpesh


export default class ESignandEstamp extends LightningElement {
@track displayList = [];
@track nonMandatoryDisplayList = [];
@api recordId;
processObject = 'E-sign';
nextprocessObject = 'E-signed';
showSummaryStyle = false;
@track selectedChecklistData = [];
@track selectedapplicants = [];
@track modalVisibility = false;
@track selectedId;
@track allChecklist = [];
@track showDropdown = false;
@track applicant = false;
@track createdNewDocTable = [];
@track showapplicablefor = false;
@track documentRequiredforOptions;
@track selectedValue;
@track esignResponse = [];
@track esignDocDetail = [];
selectedCategory;
applicants = false;
timestampOptions = [
    { label: 'E-Signature', value: 'E-Signature' },
    { label: 'Wet-Signature', value: 'Wet-Signature' }
];
showGeneratedDocs = false;
showGeneratedDoc = false;
showMandatorydata = false;
authorizedName;
searchTerm = '';
assingedUsers=[];
showTable = false;
selectedStamps = [];
documents;
documentsNonMand;
@track masterLabelList = [];
@track formattedOptions = [];
@track stampWrapperList = [];
@track totalCharges = 0;
@track stampChargeMap = new Map();
@track showEsignChecklist = false;
esignStatusOptions= [
    { label: 'Pending', value: 'Pending' },
    { label: 'Completed', value: 'Completed' }
];
esignedChecklist = [];
reuploadifnotuploaded = true;
estampdocId = 'a0VBi000001ywyEMAQ';
showhistory = false;
wsign = false;
esign = false;
validationErrors = [];
showError = false;
@track selectedDocumentIDs = [];
@track esignStatus;
initialValue;
userOptions = [ { label: 'Akash Sharma', value: 'Akash Sharma' }];
@track isLoading = false;
esigncompleted = false;
showaddandgen = true;
showesignProceed = true;
selectedUserId;
isEditableUser = false;
disableAddDocBtn = true;
disableGenerateDocBtn = true;
@track enableEdit = false;
@track disableWetSignStatus;
@track editChecklist = true;
@wire(CurrentPageReference) pageRef;
@track esealactiveSection;
@track colourOptions = [];
@track shapeOptions = [];
@track imageUrl;
@track isESealRequired = false;
@track esealDetails = {};
@track selectedColour;
@track selectedShape;
@track innerName;
@track outerName;
@track esealgenerated = false;
@track esealContent;

//Non Mandatory
@track showNonMandatoryAccordion = false;
@track nonMandatoryDocOptions = [];
@track selectedNonManDocs = [];
@track nonmandatoryModalVisibility = false;
@track isAddButtonDisabled = true;
@track selectedChecklistDataNonMand = [];
@track selectedDocumentIDsNonMand = [];
@track showGeneratedDocsNonMand = false;
@track showGeneratedDocNonMand = false;
@track showMandatorydataNonMand = false;
@track showEsignChecklistNonMand = false;
@track showSummaryStyleNonMand = false;
@track editChecklistNonMand = true;
@track showaddandgenNonMand = true;
@track showesignProceedNonMand = true;
@track esigncompletedNonMand = false;

//Wet Signature
@track vcontentId;
@track selectedSignatureStatus;

    @wire(getObjectInfo, { objectApiName: Document_Master })
    objectInfo;
    @wire(getObjectInfo, { objectApiName: Opportunity })
    objectOppInfo;

    @wire(getPicklistValues, { recordTypeId:'$objectInfo.data.defaultRecordTypeId', fieldApiName: RL })
    byHandF8ieldInfo({ data, error }) {
        if(data) {
            this.documentRequiredforOptions = data.values;
        }
    }
    @wire(getPicklistValues, { recordTypeId:'$objectOppInfo.data.defaultRecordTypeId', fieldApiName: ess })
    byHandF9ieldInfo({ data, error }) {
        if(data) {
          this.shapeOptions = data.values;
        }
    }
    @wire(getPicklistValues, { recordTypeId:'$objectOppInfo.data.defaultRecordTypeId', fieldApiName: esc })
    byHandF6ieldInfo({ data, error }) {
        if(data) {
            this.colourOptions = data.values;
        }
    }

    @wire(getNonManDocuments, { filterValue: 'Non-Mandatory Template' }) 
    wiredDocs({ error, data }) {
        if (data) {
            this.nonMandatoryDocOptions = data.map(doc => ({
                label: doc.Name,
                value: doc.Id,
                checked: false,
                isDisabled: false
            }));
        } else if (error) {
            console.error(error);
        }
    }

    hanldrefreshTable(event){
        this.getDocInAccordionForm();
    }

    handleAddNonManDocs(){
        this.nonmandatoryModalVisibility = true;
    }

    handleNonManChange(event) {
        const checkbox = event.target;
        const docId = checkbox.dataset.id;
        const docName = checkbox.dataset.name;
        const isChecked = checkbox.checked;

        console.log('Doc ID:', docId);
        console.log('Doc Name:', docName);
        console.log('Is Checked:', isChecked);

        this.nonMandatoryDocOptions = this.nonMandatoryDocOptions.map(opt =>
            opt.value === docId ? { ...opt, checked: isChecked } : opt
        );

        
        if (isChecked) {
            // Add the selected doc to the array
            if (!this.selectedNonManDocs.includes(docId)) {
                // this.selectedNonManDocs = [...(this.selectedNonManDocs || []), docId];
                this.selectedNonManDocs = [...this.selectedNonManDocs, docId];
            }
        } else {
            // Remove if unchecked
            // this.selectedNonManDocs = (this.selectedNonManDocs || []).filter(id => id !== docId);
            this.selectedNonManDocs = this.selectedNonManDocs.filter(id => id !== docId);
        }
        this.isAddButtonDisabled = this.selectedNonManDocs.length === 0;
        console.log('Updated selectedNonManDocs:', JSON.stringify(this.selectedNonManDocs));
    }


    async addSelectedNonManDocs(){
        try {
            if (this.selectedNonManDocs.length > 0) {
            await createNonManDocumentDetails({ selectedDocMasterIds: this.selectedNonManDocs, loanId : this.recordId });

            // Disable selected checkboxes
            this.nonMandatoryDocOptions = this.nonMandatoryDocOptions.map(opt => {
                if (this.selectedNonManDocs.includes(opt.value)) {
                    return { ...opt, checked: true, isDisabled: true };
                }
                return opt;
            });

            this.handleCloseNonMand();
        }
        } catch (error) {
            console.log('addSelectedNonManDocs error  '+error)
        }
        
    }

    handleCloseNonMand(){
        this.nonmandatoryModalVisibility = false;
        this.selectedNonManDocs = [];
        this.isAddButtonDisabled = true;

        this.nonMandatoryDocOptions = this.nonMandatoryDocOptions.map(opt => {
            if (!opt.isDisabled) {
                return { ...opt, checked: false };
            }
            return opt;
        });

        this.getDocInAccordionForm('Non-Mandatory');
    }

connectedCallback(){
    this.loadDocuments();
    console.log('imageUrl : '+this.imageUrl);
    checkOpportunity({loanId : this.recordId})
    .then(result =>{
        if(result){
            this.enableEdit = true;
        }
        else{
            this.enableEdit = false;
        }
        this.disableWetSignStatus = !this.enableEdit;
    })
    this.checkStatus();
    this.getDocInAccordionForm('Non-Mandatory');
    // this.getAuthorizedSignatory();
    this.opportunityDetails();
    // registerListener("handleRefreshDocument", this.getdocDetails, this);
}

// testingBypass(){
//     this.showGeneratedDocs = true; //Testing purpose
//     this.showGeneratedDoc = true; //Testing purpose
//     this.showMandatorydata = true; //Testing purpose
//     this.showEsignChecklist = true; //Testing purpose
// }

loadDocuments(){
        getLoanDocuments({
            loanApplicationId: this.recordId
            })
            .then(result => {
                console.log('Result', JSON.stringify(result));
                this.documents = result;
                this.showGeneratedDocs = true;
                this.showGeneratedDoc = true;
                this.showSummaryStyle = true;
                this.displayList = [{
                    docDetails: result.map(doc => {
                        return {
                            id: doc.Id,
                            contentId: doc.Content_Document_Id__c,
                            docName: 'Loan Agreement Form',
                            fileType: 'PDF',
                            showUpload: false,
                            showView: true,
                            showDelete: false,
                            showRetake: false,
                            showLocation: false,
                            lattitude: '',
                            longitude: '',
                            generatedBy: 'Integration User'
                        };
                    })
                }];

                console.log('Display List', JSON.stringify(this.displayList));

            })
            .catch(error => {
                console.error('Error loading documents', error);
            });
    }

getdocDetails(event){
    console.log('82');
    getDocumentChecklistRecords({
        recId: this.recordId,
        processObject:'UpdatedEsign'
    }).then(response=>{
        this.esignedChecklist = response;
        this.documents = response;
        console.log('this.documents -->'+JSON.stringify(this.esignedChecklist));
        this.showEsignChecklist = true;
        this.showEsignChecklistNonMand = true;
        this.showGeneratedDocs = true;
        this.showGeneratedDocsNonMand = true;
        this.showGeneratedDoc = true
        this.showGeneratedDocNonMand = true;
        console.log('response----'+JSON.stringify(response));
    }).catch(error=>{
        console.error('error getDocumentChecklistRecords! --> '+JSON.stringify(error));
    })
}
    getDocInAccordionForm(templateType){
        if (templateType == 'Mandatory') {
            getDocumentChecklistRecords({
                recId: this.recordId,
                processObject:this.processObject
            }).then(response=>{
                // this.displayList = response;
                this.displayList = response.map(parentItem => {
                    parentItem.docDetails = parentItem.docDetails.map(iterDet => {
                        iterDet.isCheckboxChecked = iterDet.mntEsign;
                        if (iterDet.isCheckboxChecked) {
                            this.selectedChecklistData.push(iterDet.id);
                            this.selectedDocumentIDs.push(iterDet.id);
                        }

                        // iterDet.mntEsign = this.isEditableUser;
                        return iterDet;
                    });
                    return parentItem;
                });
                this.showSummaryStyle = true;
                console.log('response----'+JSON.stringify(response));
                console.log('selectedChecklistData---- '+this.selectedChecklistData);
            }).catch(error=>{
                console.error('error getDocumentChecklistRecords --> '+JSON.stringify(error));
            })
        }

        if (templateType == 'Non-Mandatory') {
            getDocumentChecklistRecords({
                recId: this.recordId,
                processObject:'Non-Mand E-sign'
            }).then(response=>{
                // this.displayList = response;
                this.nonMandatoryDisplayList = response.map(parentItem => {
                    parentItem.docDetails = parentItem.docDetails.map(iterDet => {
                        iterDet.isCheckboxChecked = iterDet.mntEsign;
                        if (iterDet.isCheckboxChecked) {
                            this.selectedChecklistData.push(iterDet.id);
                            this.selectedDocumentIDs.push(iterDet.id);
                        }

                        // iterDet.mntEsign = this.isEditableUser;
                        return iterDet;
                    });
                    return parentItem;
                });
                this.showSummaryStyleNonMand = true;
                console.log('response non mand----'+JSON.stringify(response));
                console.log('selectedChecklistData---- '+this.selectedChecklistData);
            }).catch(error=>{
                console.error('error getDocumentChecklistRecords --> '+JSON.stringify(error));
            })
        }
        
    }
    getAllStamps(){
        getAllStamps({})
        .then(response=>{
            this.selectedStamps = response;
            console.log('selectedStamps '+JSON.stringify(this.selectedStamps));
            if (this.selectedStamps && this.selectedStamps.length > 0) {
                this.masterLabelList = this.selectedStamps.map(option => option.MasterLabel);
                this.formattedOptions = this.masterLabelList.map(option => ({
                    label: option,
                    value: option.toLowerCase().replace(/\s+/g, ''),
                    checked: false
                }));
                console.log('masterLabelList', JSON.stringify(this.masterLabelList));
                // if (this.selectedStamps && Array.isArray(this.selectedStamps)) {
                    console.log('selectedStamps:', JSON.stringify(this.selectedStamps));
                    this.selectedStamps.forEach(stamp => {
                        if (stamp.MasterLabel && stamp.Stamp_Charge__c !== undefined) {
                            this.stampChargeMap.set(stamp.MasterLabel, stamp.Stamp_Charge__c);
                            console.log(`Added to map: ${stamp.MasterLabel} -> ${stamp.Stamp_Charge__c}`);
                        } else {
                            console.error('Invalid stamp object:', stamp);
                        }
                    });
        
                } else {
                    console.error('selectedStamps is not defined or not an array!');
                }
            console.log('Final 104 Stamp Charge Map:', this.stampChargeMap);
        })
        console.log('Final Stamp Charge Map:', this.stampChargeMap);
    }
    // handleCheckboxChange(event){
    //     console.log(event.target.checked);
    //     const selecteddocid = event.target.dataset.id;
        
    //     // if(event.target.checked){
    //     //     this.selectedChecklistData.push(selecteddocid);
    //     //     this.selectedDocumentIDs.push(selecteddocid);
    //     // }else{
    //     //     let temp = [];
    //     //     this.selectedChecklistData.forEach(record => {
    //     //         if(record != selecteddocid){
    //     //             temp.push(record);
    //     //         }
    //     //     });
    //     //     this.selectedChecklistData = temp;
    //     //     this.selectedDocumentIDs = temp;
    //     // }

    //     if (event.target.checked) {
    //         if (!this.selectedChecklistData.includes(selecteddocid)) {
    //             this.selectedChecklistData.push(selecteddocid);
    //         }
    //         if (!this.selectedDocumentIDs.includes(selecteddocid)) {
    //             this.selectedDocumentIDs.push(selecteddocid);
    //         }
    //     } else {
    //         this.selectedChecklistData = this.selectedChecklistData.filter(id => id !== selecteddocid);
    //         this.selectedDocumentIDs = this.selectedDocumentIDs.filter(id => id !== selecteddocid);
    //     }

    //     console.log('selectedChecklistData final '+this.selectedChecklistData);
    // }
    handleCheckboxChange(event) {
        const selectedDocId = event.target.dataset.id;
        const isChecked = event.target.checked;
    
        // Update the checkbox state in displayList
        if(isChecked){
            this.displayList = this.displayList.map(parentItem => {
                return {
                    ...parentItem,
                    docDetails: parentItem.docDetails.map(doc => {
                        if (doc.id === selectedDocId) {
                            return {
                                ...doc,
                                isCheckboxChecked: isChecked
                            };
                        }
                        return doc;
                    })
                };
            });
        }
        else {
            getselectedDocId({ docId: selectedDocId })
                .then((result) => {
                    // result is expected to be the original number (e.g., seq)
                    this.displayList = this.displayList.map(parentItem => {
                        return {
                            ...parentItem,
                            docDetails: parentItem.docDetails.map(doc => {
                                if (doc.id === selectedDocId) {
                                    return {
                                        ...doc,
                                        isCheckboxChecked: false,
                                        seq: result // restoring original value
                                    };
                                }
                                return doc;
                            })
                        };
                    });
                })
                .catch(error => {
                    console.error('Error fetching original sequence:', error);
                });
        }

    
        // Update selectedChecklistData and selectedDocumentIDs
        if (isChecked) {
            if (!this.selectedChecklistData.includes(selectedDocId)) {
                this.selectedChecklistData.push(selectedDocId);
            }
            if (!this.selectedDocumentIDs.includes(selectedDocId)) {
                this.selectedDocumentIDs.push(selectedDocId);
            }
        } else {
            this.selectedChecklistData = this.selectedChecklistData.filter(id => id !== selectedDocId);
            this.selectedDocumentIDs = this.selectedDocumentIDs.filter(id => id !== selectedDocId);
        }
    
        console.log('selectedChecklistData'+ JSON.stringify(this.selectedChecklistData));
        console.log('selectedDocumentIDs'+ JSON.stringify(this.selectedDocumentIDs));
    }

    handleNonMandCheckboxChange(event) {
        const selectedDocId = event.target.dataset.id;
        const isChecked = event.target.checked;
    
        // Update the checkbox state in nonMandatoryDisplayList
        if(isChecked){
            this.nonMandatoryDisplayList = this.nonMandatoryDisplayList.map(parentItem => {
                return {
                    ...parentItem,
                    docDetails: parentItem.docDetails.map(doc => {
                        if (doc.id === selectedDocId) {
                            return {
                                ...doc,
                                isCheckboxChecked: isChecked
                            };
                        }
                        return doc;
                    })
                };
            });
        }
        else {
            getselectedDocId({ docId: selectedDocId })
                .then((result) => {
                    // result is expected to be the original number (e.g., seq)
                    this.nonMandatoryDisplayList = this.nonMandatoryDisplayList.map(parentItem => {
                        return {
                            ...parentItem,
                            docDetails: parentItem.docDetails.map(doc => {
                                if (doc.id === selectedDocId) {
                                    return {
                                        ...doc,
                                        isCheckboxChecked: false,
                                        seq: result // restoring original value
                                    };
                                }
                                return doc;
                            })
                        };
                    });
                })
                .catch(error => {
                    console.error('Error fetching original sequence:', error);
                });
        }

    

        // Update selectedChecklistDataNonMand and selectedDocumentIDsNonMand
        if (isChecked) {
            if (!this.selectedChecklistDataNonMand.includes(selectedDocId)) {
                this.selectedChecklistDataNonMand.push(selectedDocId);
            }
            if (!this.selectedDocumentIDsNonMand.includes(selectedDocId)) {
                this.selectedDocumentIDsNonMand.push(selectedDocId);
            }
        } else {
            this.selectedChecklistDataNonMand = this.selectedChecklistDataNonMand.filter(id => id !== selectedDocId);
            this.selectedDocumentIDsNonMand = this.selectedDocumentIDsNonMand.filter(id => id !== selectedDocId);
        }
    
        console.log('selectedChecklistDataNonMand  '+ JSON.stringify(this.selectedChecklistDataNonMand));
        console.log('selectedDocumentIDsNonMand   '+ JSON.stringify(this.selectedDocumentIDsNonMand));
    }

handlegeneratedDocsNonMand() {
    if (this.selectedUserId != null && this.selectedUserId !== '' && this.selectedUserId !== undefined) {
            this.isLoading = true;
            //check validation of previous tabs are completed
            console.log('this.recordId checkvalidation: '+this.recordId);
            this.showError = false;
            this.validationErrors = [];

        try {
            syncContentDocumentIds({ documentIds: this.selectedDocumentIDsNonMand })
                .then(() => {
                    return postDocGenAPI({ 
                        documentId: this.selectedDocumentIDsNonMand, 
                        loanId: this.recordId, 
                        docType: 'Non-Mandatory' 
                    });
                })
                .then((response) => {
                    if (response === 'Success') {
                        this.UpdateDocGenStatusNonMand('DocGen Initiated');
                        this.showToastMessage(
                            'Success', 
                            'DocGen has been initiated. Please wait for sometime before proceeding for esigning', 
                            'success'
                        );
                        this.isLoading = false;
                        return getDocumentsList({ recordId: this.recordId, processName: 'GeneratedDoc' });
                    } else {
                        alert('Error in generating document');
                        this.isLoading = false;
                    }
                })
                        .then((result) => {
                    if (result) {
                            this.documentsNonMand = result;
                            console.log('this.documentsNonMand --> 1 '+JSON.stringify(this.documentsNonMand));
                            this.showGeneratedDocsNonMand = true;
                            this.showGeneratedDocNonMand = true;
                        this.isLoading = false;
                    }
                })
                .catch(error => {
                    this.isLoading = false;
                    console.error('Error in sync/postDocGen flow: ' + JSON.stringify(error));
                });
            } catch (error) {
            this.isLoading = false;
            console.error('Unexpected error: ' + JSON.stringify(error));
            }
    } else {
        this.showToastMessage(
            'Error', 
            'Please select authorized signatory in order to proceed for Document Generation.', 
            'error'
        );
        }
    }
    
    handleAddDocs(){
        this.modalVisibility = true;
    }
        handleSelectDocument(event){
            this.showapplicablefor = false;
            this.applicants = false;
            this.selectedId = event.detail.searchRecord.Id;
            console.log('this.selectedId -->'+this.selectedId);
            console.log('this.101 -->'+ event.detail.searchRecord.Id);
            console.log('recordId -->'+ this.recordId);
            checkApplicableFor({docMasterId :  this.selectedId})
            .then((result) => {
                console.log('286 '+result);
                if(result){
                    this.applicants = true;
                    staticgetAllApplicants({docMasterId :  this.selectedId , loanId: this.recordId})
                    .then((result) => {
                        console.log('this.getAllApplicants-->'+JSON.stringify(result));
                        this.allChecklist = result;
                        if(this.allChecklist && this.allChecklist.length == 0){
                        this.showToastMessage('Warning','Applicants are already added','warning');
                            this.selectedId = '';
                            this.template.querySelector('c-search-lookup').handleReset(event);
                        }
                    })
                    .catch((error) => {
                        console.error('Error getAllSanctionCheckList --> ', JSON.stringify(error));
                    });
                }
                else{
                    this.applicant = false;
                    console.log('299 ');
                    checkDocumentChecklistCreated({docMasterId :  this.selectedId , loanId: this.recordId})
                    .then((response) => {
                     if(response){
                        this.showToastMessage('Warning','Document Checklist already created','warning');
                        this.template.querySelector('c-search-lookup').handleReset(event);
                     }
                    })
                }
            })
        }
        handleldeselectDocument(){
                this.selectedId = '';
                this.allChecklist = [];
            
        }
        get tableVisibility(){
            return this.allChecklist.length > 0;
        }
        handleClose(){
            this.modalVisibility = false;
            this.getDocInAccordionForm('Mandatory');
        }

        
            handlesave(event){
                console.log('selectedId '+this.selectedId);
                console.log('selectedChecklistData '+this.selectedapplicants);
                console.log('selectedChecklistData length'+this.selectedapplicants.length);
                console.log('loanId '+this.recordId);
                if(this.applicants){
                if (this.selectedapplicants.length > 0) {
                        this.createChecklist(event);
                    }
                    else{
                        this.showToastMessage('Error', 'Please select the Applicant or Applicants to proceed.', 'error');
                    }
                }
                else{
                    if(this.selectedId){
                        this.createChecklist(event);
                    }
                    else{
                        this.showToastMessage('Error', 'Please select Document', 'error');
                    }
                }
                
            }
            fillMandatoryDetails(event){
                console.log('this.selectedCategory  '+this.selectedCategory)
                console.log('event name '+event.target.name);
                let docType = event.target.name
                
                if (this.selectedCategory == 'Wet-Signature') {
                    this.showEsignChecklist = true;
                    this.showEsignChecklistNonMand = true;
                    this.showMandatorydata = false;
                    this.showMandatorydataNonMand = false;
                    this.esign = false;
                    this.wsign = true;
                    this.checkAndCreateDocumentDetail(docType);

                } else if(this.selectedCategory == 'E-Signature'){
                    this.showMandatorydata = true;
                    this.showMandatorydataNonMand = true;
                    this.showEsignChecklist = false;
                    this.showEsignChecklistNonMand = false;
                }
                else{
                    this.showToastMessage('Error', 'Please select mode of signature', 'error');
                }
                console.log('esignedChecklist  '+JSON.stringify(esignedChecklist))
                console.log('this.wsign   '+this.wsign );
                console.log('this.esign   '+this.esign );
                
            }

            async checkAndCreateDocumentDetail(docType) {
                console.log('this.recordId >>>>> ' + this.recordId);
                console.log('docType >>>>> ' + docType);
                try {
                    const data = await createOrGetDocumentDetail({ recId: this.recordId, docType: docType });
                    console.log('data >> ' + JSON.stringify(data));

                    this.esignedChecklist = [data];  // Wrap in array
                    console.log('this.esignedChecklist >>>>> ' + JSON.stringify(this.esignedChecklist));

                    this.vcontentId = data.id;  // Directly use data.id
                    console.log('this.vcontentId >>>>> ' + this.vcontentId);
                } catch (error) {
                    console.log('Error >> ' + JSON.stringify(error));
                }
            }

            handlesignatureStatus(event){
                this.selectedSignatureStatus = event.target.value;
                let docType = event.target.name;
                console.log('handlesignatureStatus  docType  '+docType);
                
                if(this.selectedSignatureStatus == 'Completed'){
                    const fields = {};
                    fields['Id'] = this.recordId;
                    if (docType == 'MandStatus') {
                        fields['DocGen_Status__c']= 'Esign Completed';
                    }

                    if (docType == 'NonMandStatus') {
                        fields['Non_Mandatory_DocGen_Status__c']= 'Esign Completed';
                    }
                    
                    const recordInput = { fields };
                    console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
                    updateRecord(recordInput)
                        .then(() => {
                            this.showToastMessage('Success', 'E-sign completed successfully!!', 'success');
                            this.disableStatus = true;
                            this.connectedCallback();
                            
                        })
                        .catch(error => {
                            console.log('Error updating record --> '+JSON.stringify(error));
                        });
                }
            }
                showToastMessage(title, message, type) {
                    const toastEvent = new ShowToastEvent({
                        title: title,
                        message: message,
                        variant: type
                    });
                    this.dispatchEvent(toastEvent);
                }
                get createdRecordsVisibility(){
                    return this.createdNewDocTable.length>0;
                }
                handleaddNew(event){
                    this.template.querySelector('c-search-lookup').handleReset(event);
                    this.showapplicablefor = true;
                }
                handleDocumentChange(event){
                    this.selectedValue = event.detail.value;
                    console.log('this.selectedId -->'+this.selectedValue);
                    if(this.selectedValue == 'Applicant Level'){
                        this.applicants = true;
                        staticgetAllApplicants({docMasterId :  this.selectedId , loanId: this.recordId})
                    .then((result) => {
                        console.log('this.getAllApplicants-->'+JSON.stringify(result));
                        this.allChecklist = result;
                    })
                    .catch((error) => {
                        console.error('Error getAllSanctionCheckList --> ', JSON.stringify(error));
                    });
                    }
                    else{
                        this.applicants = false;
                        this.allChecklist = [];
                    }
                }
                handleselectApplicants(event){
                    console.log(event.target.checked);
                    const selecteddocid = event.target.dataset.id;
                    if(event.target.checked){
                        this.selectedapplicants.push(selecteddocid);
                    }else{
                        let temp = [];
                        this.selectedapplicants.forEach(record => {
                            if(record != selecteddocid){
                                temp.push(record);
                            }
                        });
                        this.selectedapplicants = temp;
                    }
                    console.log('selectedapplicants -->'+JSON.stringify(this.selectedapplicants));
                }

                createChecklist(event){
                    createChecklist({docMasterId : this.selectedId, userIds : this.selectedapplicants, loanId : this.recordId ,processName:this.processObject})
                    .then((result) => {
                        this.showToastMessage('Success', 'New documents added successfully.', 'success');
                        // this.fetchSanctions();
                        // this.handleClose();
                        console.log('result '+result);
                        this.createdNewDocTable = result;
                        this.getDocInAccordionForm('Mandatory')
                        this.template.querySelector('c-search-lookup').handleReset(event);
                        console.log('this.createdNewDocTable -->'+JSON.stringify(this.createdNewDocTable));
                        this.allChecklist = [];
                        this.selectedId = '';
                        this.selectedChecklistData = [];
                    })
                    .catch((error) => {
                        console.error('Error getAllSanctionCheckList --> ', JSON.stringify(error));
                    });
                }

                // handleRequestFromUsers(event) {
                //     let userList = event.detail.selectedList;
                //     if (userList.length > 0) {
                //         userList.forEach(user => {
                //             let existingStamp = this.selectedStamps.find(stamp => stamp.value === user.value);
                //             if (!existingStamp) {
                //                 this.selectedStamps = [...this.selectedStamps, { label: user.label, value: user.value, count: 0 }];
                //             }
                //         });
                //         this.showTable = true;
                //     }
                // }
                
                handlegeneratedDocs(){
                    if(this.selectedUserId!=null && this.selectedUserId!='' && this.selectedUserId!=undefined){
                    this.isLoading = true;
                    //check validation of previous tabs are completed
                    console.log('this.recordId checkvalidation: '+this.recordId);
                    this.showError = false;
                    this.validationErrors = [];

                    var params = { 'loanId' : this.recordId };

                            try {
                                console.log('postDocGenAPI initiating... ');
                                
                                console.log('postDocGenAPI this.selectedDocumentIDs: '+this.selectedDocumentIDs);
                                console.log('postDocGenAPI this.recordId '+this.recordId);
                                
            // first syncContentDocumentIds call
            syncContentDocumentIds({ documentIds: this.selectedDocumentIDs })
                .then(() => {
                    return postDocGenAPI({ documentId: this.selectedDocumentIDs, loanId: this.recordId, docType: 'Mandatory' });
                })
                                .then((response) => {
                                    console.log('postDocGenAPI Post Response: '+response);
                                    if (response === 'Success') {
                                        this.UpdateDocGenStatus('DocGen Initiated');
                                        this.showToastMessage('Success', 'DocGen has been initiated. Please wait for sometime before proceeding for esigning', 'success');
                                        this.isLoading = false;
                                        getDocumentsList({recordId : this.recordId, processName : 'GeneratedDoc'})
                                        .then((result) => {
                                            this.documents = result;
                                            console.log('this.documents --> 1 '+JSON.stringify(this.documents));
                                            this.showGeneratedDocs = true;
                                            this.showGeneratedDoc = true;
                                            this.isLoading = false;
                                        })
                                    } else {
                                        alert('Error in generating document');
                                        this.isLoading = false;
                                    }
                                })
                                .catch(error => {
                                    this.isLoading = false;
                                    console.log('postDocGenAPI Post Error: '+JSON.stringify(error));
                                });
                            } catch (error) {
                                
                            }
                        }
                        else{
                              this.showToastMessage('Error', 'Please select authorized signatory in order to proceed for Document Generation.', 'error');
                        }
                    //     }
                    // })
                }


                handleRequestFromUsers(event){
                    try {
                        // event.detail=:{"selectedList":["dd-100"]}
                        console.log('event.detail=:'+JSON.stringify(event.detail));
                        var userList = event.detail.selectedList;
                        console.log('userList=:'+userList);
                        console.log('userList.length=:'+userList.length);
                        if(userList.length>0){
                            for(var i=0;i<userList.length;i++){
                                this.assingedUsers.push(userList[i]);
                                this.showTable = true;
                            }

                            
                            this.formattedOptions = this.formattedOptions.map(option => ({
                                ...option,
                                checked: userList.includes(option.value) 
                            }));

                        } 
                        this.handleSelectedStamps(userList);
                        // this.formattedOptions = userList;
                        console.log('this.formattedOptions  '+JSON.stringify(this.formattedOptions));
                    } catch (error) {
                        console.log('error handleRequestFromUsers   '+error);
                    }
                   
                    
                    
            }
            
            handleSelectedStamps(userList) {
                console.log('userList '+userList);
                if (userList && userList.length > 0) {
                    if (this.stampWrapperList.length === 0) {
                        this.stampWrapperList = userList.map(stamp => ({
                            name: stamp, 
                            count: 0 // Initialize count to 0
                        }));
                    } else{
                        const userSet = new Set(userList);

                        this.stampWrapperList = this.stampWrapperList.filter(wrapper => userSet.has(wrapper.name));

                        userList.forEach(stamp => {
                            if (!this.stampWrapperList.some(wrapper => wrapper.name === stamp)) {
                                this.stampWrapperList.push({
                                    name: stamp,
                                    count: 0 // Initialize count to 0
                                });
                            }
                        });
                    }
                    console.log('Stamp Wrapper:', JSON.stringify(this.stampWrapperList));

                    setTimeout(() => {
                        console.log('handleSelectedStamps After update:  ', JSON.stringify(this.stampWrapperList));
                        this.calculateTotalStampCharges();
                    }, 500); // Delay of 2 seconds
                }
            }

            handleIncrement(event) {
                const stampName = event.target.dataset.name;
                console.log('Before update:', JSON.stringify(this.stampWrapperList));
                // Create a new array reference so LWC detects the change
                this.stampWrapperList = [...this.stampWrapperList].map(stamp => {
                    if (stamp.name === stampName) {
                        return { ...stamp, count: stamp.count + 1 };
                    }
                    return { ...stamp }; // Ensure all objects are restructured for reactivity
                });
                console.log('handleIncrement After update:  ', JSON.stringify(this.stampWrapperList));
                setTimeout(() => {
                    console.log('After update:', JSON.stringify(this.stampChargeMap));
                    this.calculateTotalStampCharges();
                }, 500); // Delay of 2 seconds
            }
            
            handleDecrement(event) {
                const stampName = event.target.dataset.name;
                console.log('Before update:', JSON.stringify(this.stampWrapperList));
                this.stampWrapperList = [...this.stampWrapperList].map(stamp => {
                    if (stamp.name === stampName && stamp.count > 0) {
                        return { ...stamp, count: stamp.count - 1 };
                    }
                    return { ...stamp }; // Ensuring reactivity
                });
            
                console.log('handleDecrement After update:  ', JSON.stringify(this.stampWrapperList));
                setTimeout(() => {
                    console.log('After update:', JSON.stringify(this.stampChargeMap));
                    this.calculateTotalStampCharges();
                }, 500); // Delay of 2 seconds
            }
            

            // calculateTotalStampCharges() {
            //     console.log('Sending to Apex:', JSON.stringify(this.stampWrapperList));
            //     calculateStampCharges({ stampList: this.stampWrapperList })
            //         .then(result => {
            //             console.log('Total Stamp Charges:', result);
            //             this.totalCharges = result; // Use different property name
            //         })
            //         .catch(error => {
            //             console.error('Error calculating stamp charges:', error);
            //         });
            // }
        //     calculateTsssotalStampCharges() {
        //         let stampChargeMapss = this.population();
        //         console.log('stampChargeMapss '+JSON.stringify(stampChargeMapss));
        //         if (!this.stampChargeMap || this.stampChargeMap.size === 0) {
        //             console.error('Stamp Charge Map is not initialized or empty!');
        //             return;
        //         }
        //         else{
        //         console.log('stampChargeMap '+JSON.stringify(this.stampChargeMap));
        //         console.log('stampWrapperList '+JSON.stringify(this.stampWrapperList));
        //         let totalCharge = 0;
        //         this.stampWrapperList.forEach(stamp => {
        //             const charge = this.stampChargeMap.get(stamp.name); // Get charge from Map
        //             if (charge !== undefined) {
        //                 totalCharge += charge * stamp.count;
        //             } else {
        //                 console.warn(`No charge found for ${stamp.name}`);
        //             }
        //         });
            
        //         console.log('Total Stamp Charges:', totalCharge);
        //         this.totalCharges = totalCharge; // Update property
        //     }
        // }
        calculateTotalStampCharges() {
            let totalCharge = 0;
            // Initialize the stampChargeObject
            this.stampChargeObject = {};
            if (Array.isArray(this.selectedStamps) && this.selectedStamps.length > 0) {
                this.selectedStamps.forEach(stamp => {
                    if (stamp.MasterLabel && stamp.Stamp_Charge__c !== undefined) {
                        let key = stamp.MasterLabel.toLowerCase(); // Standardize to lowercase
                        this.stampChargeObject[key] = stamp.Stamp_Charge__c;
                    } else {
                        console.error('Invalid stamp object:', stamp);
                    }
                });
                console.log('Stamp Charge Object:', JSON.stringify(this.stampChargeObject));
            } else {
                console.error('selectedStamps is not defined or empty!');
                return;
            }
            // Calculate total charges
            if (Array.isArray(this.stampWrapperList) && this.stampWrapperList.length > 0) {
                this.stampWrapperList.forEach(stamp => {
                    let key = stamp.name.toLowerCase(); // Standardize to lowercase
                    const charge = this.stampChargeObject[key];
        
                    if (charge !== undefined) {
                        totalCharge += charge * stamp.count;
                    } else {
                        console.warn(`No charge found for ${key}`);
                    }
                });
            } else {
                console.error('stampWrapperList is not defined or empty!');
            }
        
            console.log('Total Stamp Charges:', totalCharge);
            this.totalCharges = totalCharge;
            
        }

        createEsignChecklist(){
            this.UpdateDocGenStatus('Esign Initiated');
            this.editChecklist = false;
            this.editChecklistNonMand = false;
            this.showaddandgen = false;
            this.showaddandgenNonMand = false;
            this.showesignProceed = false;
            this.showesignProceedNonMand = false;
            this.showToastMessage('Success', 'Esign has been initiated.', 'success');



            // this.isLoading = true;
            // checkLatestDoc({loanId: this.recordId})
            // .then(result => {
            //     console.log('Checking latest doc.. ');
            //     if (result) {
            //         console.log('latest doc generated.. ');
            //         saveStampData({loanId: this.recordId, stampCharges: JSON.stringify(this.stampWrapperList), totalCharges: this.totalCharges})
            //         .then(result => {
            //             if (result === true) {
            //                 console.log('Saved stamp data successfully');
            //                 try {
            //                     console.log('initiateESignAPI initiating.. ');
            //                     // this.isLoading = true;
            //                     initiateESignAPI({loanId: this.recordId})
            //                         .then(result => {
            //                             console.log('result --> '+JSON.stringify(result));
            //                             // result = 'Success' //Testing purpose
            //                             if(result == 'Success'){
            //                                 this.showEsignChecklist = true;
            //                                 this.showEsignChecklistNonMand = true;
                                            
            //                                 if (this.showNonMandatoryAccordion == true) {
            //                                     this.UpdateDocGenStatusNonMand('Esign Initiated')
            //                                 } else{
            //                                     this.UpdateDocGenStatus('Esign Initiated');
            //                                 }
            //                                 this.editChecklist = false;
            //                                 this.editChecklistNonMand = false;
            //                                 this.showaddandgen = false;
            //                                 this.showaddandgenNonMand = false;
            //                                 this.showesignProceed = false;
            //                                 this.showesignProceedNonMand = false;
            //                                 this.showToastMessage('Success', 'Esign has been initiated.', 'success');
            //                                 if(this.esign){
            //                                     this.handleCheckStatus();
            //                                 }
            //                             }
            //                             else{
            //                                 this.isLoading = false;
            //                                 if(result == 'Failure'){
            //                                 this.showToastMessage('Error', 'Something went wrong. Please try again later.', 'error');
            //                                 }
            //                                 else{
            //                                 this.showToastMessage('Error', result, 'error');
            //                                 }
                                        
            //                             }
            //                         })
            //                         .catch(error => {
            //                             this.isLoading = false;
            //                             this.showToastMessage('Error', 'Something went wrong. Please try again later.', 'error');
            //                             console.log('error --> '+JSON.stringify(error));
            //                         })
            //                 } catch (error) {
            //                     console.log(' try catch error --> '+error);
            //                     this.isLoading = false;
            //                 }
            //             } else {
            //                 console.log('Error while saving stamp data');
            //             }
            //         })
            //         .catch(error => {
            //             console.log('Error while saving stamp data  '+JSON.stringify(error));
            //             this.isLoading = false;
            //         })
            //     } else {
            //         this.showToastMessage('Warning', 'Please wait till latest document is generated', 'warning');
            //         this.isLoading = false;
            //         console.log('latest doc not generated.. ');
            //     }
            // })
            // .catch(error =>{
            //     console.log('Error while checking latest document generation  '+JSON.stringify(error));
            //     this.isLoading = false;
            // })

            
        }  
        async handlehistory(event) {
            console.log('History >>>'+event.target.dataset.id);
            console.log('Before await');
            console.log('event name '+event.target.name);
            let docType = event.target.name
            await this.checkAndCreateDocumentDetail(docType);
            console.log('Button clicked, event: ', event);
            // this.vcontentId = event.target.dataset.id;  // Correctly fetching the data-id attribute
            console.log('After await, vcontentId: ' + this.vcontentId);
            this.showhistory = true;  // Ensure this triggers the display logic for history
        }          
        
        closeHistory(){
            this.showhistory = false;
        }
        hanldeEsignType(event){
            this.selectedCategory = event.detail.value;
            if(this.selectedCategory == 'E-Signature'){
                this.esign = true;
                this.wsign = false;
                console.log('this.esign  '+this.esign);
                this.updateRecordField(this.recordId, 'Type_of_Signature__c',this.selectedCategory);
            }else{
                this.esign = false;
                this.wsign = true;
                console.log('this.esign  '+this.esign);
                console.log('this.wsign  '+this.wsign);
                this.updateRecordField(this.recordId, 'Type_of_Signature__c',this.selectedCategory);
            }

        }
        parseEsign(doctype){
            this.esignResponse = []
            this.esignDocDetail = []
            parseEsignResponse({loanId : this.recordId})
            .then((result) => {
                console.log('633 '+JSON.stringify(result));
                this.esignResponse.push(result);
                let docObj = {
                    docData: [ 
                        {
                            finalStatus: result.finalStatus,
                            documentName: result.documentName
                        }
                    ]
                };
                this.esignDocDetail.push(docObj);
                console.log('result.finalStatus : ' + result.finalStatus);
                if(result.finalStatus == 'Completed'){
                    if (doctype == 'Mandatory') {
                        this.esigncompleted = true;
                        this.editChecklist = false;
                        this.UpdateDocGenStatus('Esign Completed');
                        this.showNonMandatoryAccordion = true;
                    } else if(doctype == 'Non-Mandatory'){
                        this.esigncompletedNonMand = true;
                        this.editChecklistNonMand = false;
                        this.UpdateDocGenStatusNonMand('Esign Completed')
                    }
                    
                    this.showToastMessage('Success', 'Esign has been completed', 'success');
                    
                }
                else{
                    this.showToastMessage('Warning', 'Esign is still pending', 'warning');
                    if (doctype == 'Mandatory') {
                        this.esigncompleted = false;
                        // this.showNonMandatoryAccordion = false;
                    }
                    if (doctype == 'Non-Mandatory') {
                        this.esigncompletedNonMand = false;
                    }
                    
                    
                }
                // this.showEsignResponse = true;
            })
        }

        handleCheckStatus(){
            console.log('getESignedDocumentStatus initiating..');
            getESignedDocumentStatus({loanId : this.recordId})
            .then((result) =>{
                console.log('getESignedDocumentStatus  ',result);
                if (result === 'Pending' || result === 'Completed') {
                    this.parseEsign('Mandatory');
                    this.esignStatus = true;
                    this.isLoading = false;
                    this.editChecklist = false;
                    this.editChecklistNonMand = false;
                } else {
                    this.esignStatus = true; //Testing Purpose
                    this.isLoading = false;
                }
            })
            .catch((error) => {
                console.error('Error in checkStatus:', error);
                this.isLoading = false;
               });
        }

        handleCheckStatusNonMand(){
            console.log('getESignedDocumentStatus non mand initiating..');
            getESignedDocumentStatus({loanId : this.recordId})
            .then((result) =>{
                console.log('getESignedDocumentStatus non mand  ',result);
                if (result === 'Pending' || result === 'Completed') {
                    this.parseEsign('Non-Mandatory');
                    this.esignStatus = true;
                    this.isLoading = false;
                    this.editChecklistNonMand = false;
                } else {
                    this.esignStatus = true; //Testing Purpose
                    this.isLoading = false;
                }
            })
            .catch((error) => {
                console.error('Error in checkStatus non mand:', error);
                this.isLoading = false;
               });
        }

        handleDownloadDocument(){
            console.log('downLoadESignedDocument initiating..');
            this.isLoading = false;
            downLoadESignedDocument({loanId : this.recordId})
            .then((result) =>{
                console.log('downLoadESignedDocument  ',result);
                this.isLoading = false;
                this.downloadDocument(result);
            })
            .catch((error) => {
                 console.error('Error in downLoadESignedDocument:', error);
                 this.isLoading = false;
                });
        }

        handleRecordChange(event){
            this.initialValue = event.detail.value;
        }

        captureAuthorizedUsers(){
            getAuthorizedSignatories({ loanId: this.recordId })
            .then((result) => {
                console.log('users : '+result);
                //this.userOptions = result;
            })
            .catch((error) => {
                console.error('Error loading users:', error);
            });
        }

        UpdateDocGenStatus(status){
            updateStatus({loanId : this.recordId, status : status})
            .then((result) =>{
                console.log('updateStatus  ',result);
                if(status == 'Esign Cancelled'){
                    this.connectedCallback();
                }
            })
        }

        UpdateDocGenStatusNonMand(status){
            updateStatusNonMand({loanId : this.recordId, status : status})
            .then((result) =>{
                console.log('updateStatusNonMand  ',result);
                if(status == 'Esign Cancelled'){
                    this.connectedCallback();
                }
            })
        }
        
        checkStatus() {
            returnStatus({ loanId: this.recordId })
                .then((result) => {
                    this.isLoading = true;
                    console.log('returnStatus', result);
                    this.currPage = result;
                    this.selectedSignatureStatus = (result == 'Esign Completed')?'Completed' : 'Pending';
                    this.captureAuthorizedUsers();
                    this.getAllStamps();
                    this.showGeneratedDocs = false; //Testing purpose
                    this.showGeneratedDoc = false; //Testing purpose
                    this.showMandatorydata = false; //Testing purpose
                    this.showEsignChecklist = false;
                    this.showSummaryStyle = false;
                    this.showNonMandatoryAccordion = false;
                    // Use switch case to handle different statuses
                    switch (result) {
                        case 'DocGen Not-Initiated':
                            // Handle DocGen Not-Initiated status
                            console.log('Document Generation Not Initiated');
                            this.getDocInAccordionForm('Mandatory');
                            this.editChecklist = true;
                            this.isLoading = false;
                            this.showNonMandatoryAccordion = false;
                            break;
                        case 'DocGen Initiated':
                            // Handle DocGen Initiated status
                            console.log('Document Generation Initiated');
                            this.getDocInAccordionForm('Mandatory');
                            this.getGeneratedDocument('Mandatory');
                            this.editChecklist = true;
                            this.isLoading = false;
                            this.showNonMandatoryAccordion = false;
                            break;
                        case 'Esign Initiated':
                            // Handle Esign Initiated status
                            this.showaddandgen = false;
                            this.showesignProceed = false;
                            this.showNonMandatoryAccordion = false;
                            console.log('E-signature Initiated');
                            this.getDocInAccordionForm('Mandatory');
                            this.getGeneratedDocument('Mandatory');
                            this.editChecklist = false;
                            checkSignatureType({loanId : this.recordId})
                            .then((result) => {
                            this.selectedCategory = result; 
                            this.showEsignChecklist  = true;
                            if(this.selectedCategory == 'E-Signature'){
                                this.esign = true;
                                this.wsign = false;
                                this.parseEsign('Mandatory');
                                this.isLoading = false;
                            }
                            else if(this.selectedCategory == 'Wet-Signature'){
                                this.esign = false;
                                this.wsign = true;
                                this.isLoading = false;
                                this.checkAndCreateDocumentDetail('Mandatory');
                            }
                            })
                            .catch((error) => {
                                this.isLoading = false;
                            })
                            break;
                        case 'Esign Cancelled':
                            this.showNonMandatoryAccordion = false;
                            // Handle Esign Cancelled status
                            console.log('E-signature Cancelled');
                            console.log('Document Generation Initiated');
                            this.getDocInAccordionForm('Mandatory');
                            this.getGeneratedDocument('Mandatory');
                            this.isLoading = false;
                            break;
                        case 'Esign Completed':
                            this.showNonMandatoryAccordion = true;
                            // Handle Esign Completed status
                            this.esigncompleted = true;
                            this.showesignProceed = false;
                            this.showaddandgen = false;
                            console.log('E-signature Completed');
                            this.getDocInAccordionForm('Mandatory');
                            this.getGeneratedDocument('Mandatory');
                            this.editChecklist = false;
                            checkSignatureType({loanId : this.recordId})
                            .then((result) => {
                            this.selectedCategory = result; 
                            this.showEsignChecklist  = true;
                            if(this.selectedCategory == 'E-Signature'){
                                this.esign = true;
                                this.wsign = false;
                                this.parseEsign('Mandatory');
                                this.isLoading = false;
                            }
                            else if(this.selectedCategory == 'Wet-Signature'){
                                this.esign = false;
                                this.wsign = true;
                                this.isLoading = false;
                                this.checkAndCreateDocumentDetail('Mandatory');
                            }
                            })
                            break;
                        default:
                            this.getDocInAccordionForm('Mandatory');
                            console.log('Unknown status');
                            this.isLoading = false;
                            break;
                    }
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('Error in returnStatus:', error);
                });

            returnStatusNonMand({ loanId: this.recordId})
                .then((result) => {
                    this.isLoading = true;
                    console.log('returnStatus', result);
                    this.currPage = result;
                    this.captureAuthorizedUsers();
                    this.getAllStamps();
                    this.showGeneratedDocsNonMand = false; //Testing purpose
                    this.showGeneratedDocNonMand = false; //Testing purpose
                    this.showMandatorydataNonMand = false; //Testing purpose
                    this.showEsignChecklistNonMand = false;
                    this.showSummaryStyleNonMand = false;
                    // this.showNonMandatoryAccordion = false;
                    // Use switch case to handle different statuses
                    switch (result) {
                        case 'DocGen Not-Initiated':
                            // Handle DocGen Not-Initiated status
                            console.log('Document Generation Not Initiated');
                            this.getDocInAccordionForm('Non-Mandatory');
                            this.editChecklistNonMand = true;
                            this.isLoading = false;
                            // this.showNonMandatoryAccordion = false;
                            break;
                        case 'DocGen Initiated':
                            // Handle DocGen Initiated status
                            console.log('Document Generation Initiated');
                            this.getDocInAccordionForm('Non-Mandatory');
                            this.getGeneratedDocument('Non-Mandatory');
                            this.editChecklistNonMand = true;
                            this.isLoading = false;
                            // this.showNonMandatoryAccordion = false;
                            break;
                        case 'Esign Initiated':
                            // Handle Esign Initiated status
                            this.showaddandgenNonMand = false;
                            this.showesignProceedNonMand = false;
                            // this.showNonMandatoryAccordion = false;
                            console.log('E-signature Initiated');
                            this.getDocInAccordionForm('Non-Mandatory');
                            this.getGeneratedDocument('Non-Mandatory');
                            this.editChecklistNonMand = false;
                            checkSignatureType({loanId : this.recordId})
                            .then((result) => {
                            this.selectedCategory = result; 
                            this.showEsignChecklistNonMand  = true;
                            if(this.selectedCategory == 'E-Signature'){
                                this.esign = true;
                                this.wsign = false;
                                this.parseEsign('Non-Mandatory');
                                this.isLoading = false;
                            }
                            else if(this.selectedCategory == 'Wet-Signature'){
                                this.esign = false;
                                this.wsign = true;
                                this.isLoading = false;
                                this.checkAndCreateDocumentDetail('Non-Mandatory');
                            }
                            })
                            .catch((error) => {
                                this.isLoading = false;
                            })
                            break;
                        case 'Esign Cancelled':
                            // this.showNonMandatoryAccordion = false;
                            // Handle Esign Cancelled status
                            console.log('E-signature Cancelled');
                            console.log('Document Generation Initiated');
                            this.getDocInAccordionForm('Non-Mandatory');
                            this.getGeneratedDocument('Non-Mandatory');
                            this.isLoading = false;
                            break;
                        case 'Esign Completed':
                            this.showNonMandatoryAccordion = true;
                            // Handle Esign Completed status
                            this.esigncompletedNonMand = true;
                            this.showesignProceedNonMand = false;
                            this.showaddandgenNonMand = false;
                            console.log('E-signature Completed');
                            this.getDocInAccordionForm('Non-Mandatory');
                            this.getGeneratedDocument('Non-Mandatory');
                            this.editChecklistNonMand = false;
                            checkSignatureType({loanId : this.recordId})
                            .then((result) => {
                            this.selectedCategory = result; 
                            this.showEsignChecklistNonMand  = true;
                            if(this.selectedCategory == 'E-Signature'){
                                this.esign = true;
                                this.wsign = false;
                                this.parseEsign('Non-Mandatory');
                                this.isLoading = false;
                            }
                            else if(this.selectedCategory == 'Wet-Signature'){
                                this.esign = false;
                                this.wsign = true;
                                this.isLoading = false;
                                this.checkAndCreateDocumentDetail('Non-Mandatory');
                            }
                            })
                            break;
                        default:
                            this.getDocInAccordionForm('Non-Mandatory');
                            console.log('Unknown status');
                            this.isLoading = false;
                            break;
                    }
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('Error in returnStatus:', error);
                });
        }
        getGeneratedDocument(documentType){
            let docType = documentType;
            let processName = ''

            if (docType == 'Mandatory') {
                processName = 'GeneratedDoc'
            } else if (docType == 'Non-Mandatory') {
                processName = 'GeneratedDocNonMand'
            }

            getDocumentsList({recordId : this.recordId, processName : processName})
            .then((result) => {
                if (docType == 'Mandatory') {
                    this.documents = result;
                    console.log('this.documents --> 2 '+JSON.stringify(this.documents));
                } else if (docType == 'Non-Mandatory') {
                    this.documentsNonMand = result;
                    console.log('this.documentsNonMand --> 2 '+JSON.stringify(this.documentsNonMand));
                }
                this.showGeneratedDocs = true;
                this.showGeneratedDocsNonMand = true
                this.showGeneratedDoc = true;
                this.showGeneratedDocNonMand = true;
                this.showSummaryStyle = true;
                this.showSummaryStyleNonMand = true;
            })
        }
        updateRecordField(recordId, fieldApiName, fieldValue) {
            const fields = {};
            fields['Id'] = recordId;
            fields[fieldApiName] = fieldValue;
            const recordInput = { fields };
            updateRecord(recordInput)
            .then(() => {
                console.log('Record updated successfully');
            })
            .catch(error => {
                console.error('Error updating record: ', error);
                console.log('Error updating record --> '+JSON.stringify(error));
            })
        }
        

        downloadDocument(contentVersionId) {
             const url = '/sfc/servlet.shepherd/version/download/' + contentVersionId;
             window.open(url, '_blank');
            }

            
 get isDisabled() {
     return !this.showesignProceed;
}

get isDisabled(){
    return !this.showesignProceedNonMand;
}
cancelEsign(){
    cancelESignedDocument({loanId : this.recordId})
    .then((result) => {
        console.log('cancelESignedDocument -->'+JSON.stringify(result));
        if(result == 'Success'){
            this.showToastMessage('Success', 'E-signature Cancelled', 'success');
            if (!this.showNonMandatoryAccordion) {
                this.UpdateDocGenStatus('Esign Cancelled');
            } else {
                this.UpdateDocGenStatusNonMand('Esign Cancelled');
            }
            
        }
        else{
            this.showToastMessage('Error', 'Error in canceling the document', 'error');}
        })
    .catch((error) => {
        console.error('Error in cancelEsign:', error);
    });
      
 }

 handleChange(event){
    this.selectedUserId = event.target.value;
    //this.updateRecordField( this.recordId, 'Authorized_Signatory__c', this.selectedUserId);
    }
    handleSequenceChange(event) {
        const changedId = event.target.dataset.id;
        const newValue = event.target.value;
        // Find and update the esignSequence for the matching item in displayList
        this.displayList = this.displayList.map(parentItem => {
            return {
                ...parentItem,
                docDetails: parentItem.docDetails.map(detail => {
                    if (detail.id === changedId) {
                        return { ...detail, esignSequence: newValue };
                    }
                    return detail;
                })
            };
        });
    }
    handleSaveSequence(event) {
        const recordId = event.currentTarget.dataset.id;
        console.log('recordId : 1104 ->'+recordId);
        let updatedRecord;
    
        this.displayList.forEach(parentItem => {
            parentItem.docDetails.forEach(detail => {
                if (detail.id === recordId) {
                    updatedRecord = detail;
                }
            });
        });
    
        if (updatedRecord) {
            checkOtherDoc({recordId :this.recordId,sequence: updatedRecord.esignSequence})        
            .then(result => {
            console.log('checkOtherDoc -->'+JSON.stringify(result));
            if(result){
            saveEsignSequence({
                recordId:recordId,
                sequence: updatedRecord.esignSequence
            })
            .then(() => {
                this.showToastMessage('Success', 'Sequence updated successfully', 'success');
            })
            .catch(error => {
                console.error('Error saving sequence:', error);
                this.showToastMessage('Error', 'Failed to update sequence', 'error');
            });
        }
        else{
            this.showToastMessage('Error', 'The sequence cannot be updated because another document is already using this sequence. Please update the sequence of that document first to avoid a conflict.', 'error');
            getselectedDocId({ docId: recordId })
            .then((result) => {
                // result is expected to be the original number (e.g., seq)
                this.displayList = this.displayList.map(parentItem => {
                    return {
                        ...parentItem,
                        docDetails: parentItem.docDetails.map(doc => {
                            if (doc.id === recordId) {
                                return {
                                    ...doc,
                                    // isCheckboxChecked: false,
                                    seq: result // restoring original value
                                };
                            }
                            return doc;
                        })
                    };
                });
            })
            .catch(error => {
                console.error('Error fetching original sequence:', error);
            });
        }
    })
}
    }
    getdocDetails(event){
        this.connectedCallback();

    }
    getAuthorizedSignatory(){
        fetchAuthorizedSignatory({loanId : this.recordId})
        .then((result) => {
            this.selectedUserId = result;
            console.log('selectedUserId : '+this.selectedUserId);
        })
        .catch((error) => {
            console.error('Error getAuthorizedSignatory:', JSON.stringify(error));
    })
}
    opportunityDetails(){
        opportunityDetails({loanId : this.recordId})
        .then((result) => {
            console.log('1178 opp details : '+JSON.stringify(result));
            this.esealDetails = result;
            this.isESealRequired = this.esealDetails.isRequired;
            this.selectedColour = this.esealDetails.selectedColour;
            this.selectedShape = this.esealDetails.selectedShape;
            this.innerName = this.esealDetails.innerName;
            this.outerName = this.esealDetails.outerName;
            this.esealgenerated = this.esealDetails.esealgenerated;
            this.selectedUserId = this.esealDetails.authsign;
            if(this.esealgenerated){
                fetchNewEseal({loanId : this.recordId})
                    .then((result) => {
                        console.log('1228 opp details: '+JSON.stringify(result));
                            if(result.contentDocId!=null && result.contentDocId!='' && result.docId!=null && result.docId!=''){
                                this.imageUrl = `/sfc/servlet.shepherd/document/download/${result.contentDocId} `;
                                this.isLoading = false;
                                this.esealContent = result.docId;
                                console.log('1216 '+ this.esealContent );
                                this.esealgenerated = true;
                                    // if (!this.selectedChecklistData.includes(result.docId)) {
                                    //     this.selectedChecklistData.push(result.docId);
                                    //     this.selectedDocumentIDs.push(result.docId);
                                    // }
                            }
                })
            }
        })
        .catch((error) => {
            console.error('Error fetchEsealDetails:', JSON.stringify(error));
    })
    }
        get eSealSectionLabel() {
        return this.isESealRequired ? 'E-seal Details *' : 'E-seal Details';
        }

        handlegeneratedEseal(event) {
            this.isLoading = true;
            if (this.outerName && this.innerName && this.selectedColour && this.selectedShape) {
                        const inputMap ={
                        'loanId':this.recordId,
                        'processName':'Eseal'
                        }
                initiateAPIRequest({ inputMap:inputMap })
                    .then((result) => {
                        console.log('1212 opp details: ' + JSON.stringify(result));
                        if(result == 'Success'){
                            this.showToastMessage('Success', 'E-seal generated successfully', 'success');
                            fetchNewEseal({loanId : this.recordId})
                            .then((result) => {
                                console.log('1228 opp details: '+JSON.stringify(result));
                                if(result.contentDocId!=null && result.contentDocId!='' && result.docId!=null && result.docId!=''){
                                    this.imageUrl = `/sfc/servlet.shepherd/document/download/${result.contentDocId} `;
                                    this.esealgenerated = true;
                                     this.isLoading = false;
                                    //   if (!this.selectedChecklistData.includes(result.docId)) {
                                    //         this.selectedChecklistData.push(result.docId);
                                    //         this.selectedDocumentIDs.push(result.docId);
                                    //     }
                                    //     if(this.esealContent!=null && this.esealContent!='' && this.selectedChecklistData.includes(this.esealContent)){
                                    //     this.selectedChecklistData = this.selectedChecklistData.filter(id => id !== this.esealContent);
                                    //     this.selectedDocumentIDs = this.selectedDocumentIDs.filter(id => id !== this.esealContent);
                                    //     console.log('selectedChecklistData : '+this.selectedChecklistData);
                                    //     console.log('selectedDocumentIDs : '+this.selectedDocumentIDs);
                                    //     this.isLoading = false;
                                    //     }
                                }
                            })
                        }
                        this.isLoading = false;
                    })
                    .catch((error) => {
                        console.error('E-seal generation failed:', error);
                        this.showToastMessage('Error', 'Failed to generate E-seal.Please try again after sometime', 'error');
                        this.isLoading = false;
                    });
            } else {
                this.showToastMessage('Error','Please fill all the mandatory fields to generate E-seal','error');
                this.isLoading = false;
            }
        }

        handleOuterNameChange(event){
            this.outerName = event.target.value;
              this.updateRecordField( this.recordId, 'E_Seal_Outer_Name__c', this.outerName);
        }
        handleInnerNameChange(event){
            this.innerName = event.target.value;
              this.updateRecordField( this.recordId, 'E_seal_Inner_Name__c', this.innerName);
        }
        handleColourChange(event){
            this.selectedColour = event.target.value;
              this.updateRecordField( this.recordId, 'E_seal_Colour__c', this.selectedColour);
        }
        handleShapeChange(event){
            this.selectedShape = event.target.value;
              this.updateRecordField( this.recordId, 'E_seal_Shape__c', this.selectedShape);
        }
         //kalpesh start
        handleUpload(event) {
            const uploadedFiles = event.detail.files;
            const fileName=event.target.name;
             console.log('fileName>>>',fileName);
              console.log('uploadedFiles>>',uploadedFiles);
            if (uploadedFiles && uploadedFiles.length > 0) {
                const contentDocumentId = uploadedFiles[0].documentId;
                console.log('Uploaded ContentDocumentId:', contentDocumentId);
                uploadMandAndNonMandFile({ loanAppId: this.recordId, contentDocumentId: contentDocumentId,fileDescription:fileName
                })
               .then((result) => {
                if(result=='success'){
                    console.log('File ',result);
                    this.showToastMessage('Success', 'Document has been uploaded successfully.', 'success');
                }else{
                     console.log('File ',result);
                    this.showToastMessage('Error', 'Error', 'error');
                }

                })
                .catch(error => {
                    console.error('Error tagging file:', error);
                    this.showToastMessage('Error', 'Error', 'error');
                });
            this.getGeneratedDocument(fileName);
        }
    }
    //kalpesh end
     getDocument() {
        getDocumentsList({ recordId: this.recordId, processName: 'GeneratedDoc' })
            .then((result) => {
                this.documents = result;
                console.log('results --> 1 ' + JSON.stringify(result));
                console.log('this.documents --> 1 ' + JSON.stringify(this.documents));
                this.isLoading = false;
            })
    }
}