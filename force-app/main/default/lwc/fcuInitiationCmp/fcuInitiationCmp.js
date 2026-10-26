import { LightningElement, api, wire, track } from 'lwc';
import getDocumentsChecklist from '@salesforce/apex/FCUController.getDocumentsChecklist';
import getQueries from '@salesforce/apex/FCUController.getQueries';
import getDocumentScreeningStatus from '@salesforce/apex/FCUController.getDocumentScreeningStatus';
import getObjectName from '@salesforce/apex/FCUController.getObjectName';
//import sendNotificationSendBack from '@salesforce/apex/FCUController.sendNotificationSendBack';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName1';
import getAllDocument from '@salesforce/apex/DocumentViewCmpController.getAllDocumentFCU';
import getFcuStatusAndUpdateLoan from '@salesforce/apex/FCUController.getFcuStatusAndUpdateLoan';
//import sendNotificationToSampler from '@salesforce/apex/FCURecordPageController.sendNotificationToSampler';

import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import getFileAsBase64 from '@salesforce/apex/FCUController.getFileAsBase64';
import { refreshApex } from '@salesforce/apex';
import { createRecord,updateRecord } from "lightning/uiRecordApi";
import fcusamplingConfirm from '@salesforce/label/c.FCU_sampling_confirm'; 

import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';

import Id from '@salesforce/user/Id'; 
import ProfileName from '@salesforce/schema/User.Profile.Name';
import UserName from '@salesforce/schema/User.Name';
import USER_ID from '@salesforce/user/Id'; 
import Name from '@salesforce/schema/User.Name';  
import DOCUMENT_MASTER from "@salesforce/schema/Document_Master__c";
import DOCUMENT_CATEGORY from "@salesforce/schema/Document_Master__c.Document_Category__c";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";

export default class FcuInitiationCmp extends LightningElement {
    @api recordId;
    @track documents = [];
    @track alldocuments = [];
    @track queries = [];
    @track currentIndex = 0;
    @track imageUrl;
    @track showExcel;
    @track showZip;
    @track documentsScreening = [];
    @track pdfUrl;
    @track wiredResult;
    @track modalVisibility = false;
    @track showInitiationCmp = false;
    @track objectName;
    @track spinnerRun = true;
    @track isVendor=false;
    @track isdoclist = false;
    @track docId;
    isTableVisible = false;
    @track extensionType ;
    @api buttonLabel = 'Hold';
    @track totalCount = 0;
    openQueryModule = false;

    @track levelNavList = [];
    // @track completedcount = 0;

    @track showConfirmationScreen = false;

    @track confirmMessage = fcusamplingConfirm;

    @track docTypeOptions = [{ label: 'All application level', value: 'All application level'},
        {label: 'Applicant level', value: 'Applicant level'},
        { label: 'Co-applicant level', value: 'Co-applicant level'},
        { label: 'Guarantor level', value: 'Guarantor level'},
        // { label: 'Collateral evel​', value: 'Collateral level​'},
    ];

    @track docLevellist = ['Application Level', 'Applicant Level', 'Guarantor Level', 'Co-applicant Level'];

    @track docLevelValue = 'Applicant level';
    @track filteredDocuments = [];
    
    @track levelHeader = 'All application level documents';

    @track show5level = false;

    @track showgenericConfirm = false;
    @track showSendBackRemarks=false;
    @track remarks;
    @track userIdCurrent;

    @wire(CurrentPageReference) pageRef;
    /*buttonVisibilityPending = false;
    buttonVisibilityScreened = false;
    buttonVisibilitySampling = false;
    buttonVisibilitySentBack=false;
    buttonVisibilityRecommend=false;
    buttonVisibilityOnhold = false;*/

    profile = {
        'Admin' : false,
        'Sampler' : false
    }
    //currentProfileName;
    //currentUserName;
//sampler true for testing
    isRemarkScreen = false
    isRecommendRemark = false;
    isSampleRemark = false;
    isScreenRemark = false;
    removeQueue = false;
    @track currentProfileName;
    //@track currentUserName;

    @track searchDocuments =[];
    searchInput = false;
    noResults  = false;
    documentCategorySelected;
    @track picklistOptions = [];
    @track allDocuments = [];
    @track filteredDocumentsAsPerCategory = [];
    documentMap = new Map();
    documentsmap = new Map();
    requirementLevelArray = [];
    changeDocOwner;
    changeDocName;
    changeScreenigStatus;
    changeRemarks;
    imageid;
    username;
    noImage = false;
    @track zoomLevel = 1;

    remarkOptions = [
        { label: 'Screened', value: 'Screened' },
        { label: 'Eyeballed', value: 'Eyeballed' },
        { label: 'Other', value: 'Other' }
    ];
    @track showHoldButton = true;
    @track showUnHoldButton = true;
    @track manualRemark = '';
    @track selectedRemark = '';

    @wire(getRecord, { recordId: USER_ID, fields: [Name] })
    wiredUser({ data, error }) {
        if (data) {
            this.username = data.fields.Name.value;
            console.log('user id -->',USER_ID);
            console.log('Username-->',this.username);
        } else if (error) {
            console.error('Error fetching user data', error);
        }
    }
    handleZoomIn() {
        this.zoomLevel = Math.min(this.zoomLevel + 0.1, 2); // Max limit at 2x zoom
        this.updateZoom();
    }

    handleZoomOut() {
        if (this.zoomLevel > 0.5) { // Prevent excessive shrinking
            this.zoomLevel -= 0.1;
            this.updateZoom();
        }
    }

    updateZoom() {
        let docViewer = this.template.querySelector('[data-id="documentViewer"]'); // PDF
        let imgViewer = this.template.querySelector('[data-id="documentImage"]'); // Image

        if (docViewer) {
            docViewer.style.transform = `scale(${this.zoomLevel})`;
            docViewer.style.transformOrigin = "center"; // Ensure zooming happens centrally
        }

        if (imgViewer) {
            imgViewer.style.transform = `scale(${this.zoomLevel})`;
            imgViewer.style.transformOrigin = "center"; // Maintain aspect ratio
        }
    }
    getPicklistOptions(){
        let options = [];
        options.push({label : 'All',
                value : 'All'});
        let docs = [];
        let duplicateCategory = [];
        this.documents.forEach(doc => {
            if(doc.documentCategory && !duplicateCategory.includes(doc.documentCategory)){
                let optionObj = {
                    label : doc.documentCategory,
                    value : doc.documentCategory,
                }
                duplicateCategory.push(doc.documentCategory);
               options.push(optionObj);
            }

            let docObj = {
                label : doc.Name,
                value : doc.Id
            }
            docs.push(docObj);

            this.documentMap.set(doc.Id,doc);
            this.requirementLevelArray.push(doc.requirementLevel);
        });  
        
        this.picklistOptions = options;
        this.filteredDocumentsAsPerCategory = docs;
    }


    handleChange(event){
        let docs = [];
        this.documentCategorySelected = event.target.value;
        this.documents.forEach(doc => {
            if(doc.documentCategory == this.documentCategorySelected || this.documentCategorySelected == 'All'){
                let docObj = {
                    label : doc.Name,
                    value : doc.Id
                }
                docs.push(docObj);
            }
        });
        this.filteredDocumentsAsPerCategory = docs;
    }
    /*handleInputChange(event){
        this.searchInput = true;
        const searchTerm = event.target.value.toLowerCase();
        if (searchTerm) {
            let isDocumentCatSelected = this.documentCategorySelected && !(this.documentCategorySelected == 'None');
            this.searchDocuments = isDocumentCatSelected ? 
            this.documents.filter(document => document.Name.toLowerCase().includes(searchTerm) 
            && document.documentCategory.includes(this.documentCategorySelected)) :
            this.documents.filter(document => document.Name.toLowerCase().includes(searchTerm));
            this.noResults = Object.keys(this.searchDocuments).length == 0;
        } else {
            this.searchDocuments = undefined;
            this.noResults = false;
        }
    }*/

        isZipFolder = false;
        fileUrl = null;

    async handleDocChangeClick(event) {
        this.currentIndex = 0;
        const doccheck = event.target.dataset.id;
        this.documents.forEach(doc => {
            this.documentsmap.set(doc.ContentDocumentId, doc);
        });

            const response = await getAllDocument({
                recordId: this.recordId
            });
    
            this.alldocuments = response;
            console.log('response----' + response);
    
            let currentDoc = null;
            let extensionType = null;

    
            if (doccheck !== '') {
                console.log('isnide if--');
                for (let i = 0; i < this.alldocuments.length; i++) {
                    if (this.alldocuments[i].docContentId === doccheck) {
                        currentDoc = this.alldocuments[i];
                        extensionType = currentDoc.docExtention; 
                        break;
                    }
                }

            } else {
                console.error('Invalid doccheck value:', doccheck);
                return;
            }
    
            if (extensionType === 'pdf') {
                this.isPdf = true;
                const contentDocId = currentDoc.docContentId; 
                //const base64Content = await this.loadFile(contentDocId);
                //console.log('check the pdf url-->',base64Content);
                this.pdfUrl = window.location.origin +'/sfc/servlet.shepherd/document/download/'+ contentDocId;//this.pdfUrl = this.downloadPdf(base64Content);
                console.log('check the pdf url-->',this.pdfUrl);
                this.imageUrl = null;
                this.isZipFolder = false;
            }else if (extensionType === 'zip') {
               console.log('There is a zip file 270...');
                this.isPdf = false;
                this.imageUrl = false;
                this.isZipFolder = true;
                const base = this.getDocDownloadBase();
                const contentDocId = currentDoc.docContentId; 
                this.fileUrl = `${base}/document/download/${contentDocId}?v=${Date.now()}`;
                console.log('this.fileUrl>>>'+this.fileUrl);
                

            } else  {
                this.isZipFolder = false;
                this.isPdf = false;
                console.log('assigning document id?',doccheck);
                this.imageUrl = `/sfc/servlet.shepherd/version/download/${this.documentsmap.get(doccheck).Id}`;
                this.pdfUrl = null;
            } 

        this.levelHeader  = this.documentsmap.get(doccheck).requirementLevel == 'Applicant Level' ? 'Applicant level documents' : 'Application level documents';
        this.changeDocOwner = this.documentsmap.get(doccheck).ownerName;
        this.changeDocName = this.documentsmap.get(doccheck).Name;
        this.changeScreenigStatus = this.documentsmap.get(doccheck).screeningStatus;
        this.changeRemarks=this.documentsmap.get(doccheck).remark;
        console.log('doc header',this.levelHeader);
        if (this.levelHeader === 'Applicant level documents')
        {
            console.log('inside level check');
            this.filteredDocuments = this.documents.filter(doc => doc.requirementLevel === 'Applicant Level').sort((a) => (a.screeningStatus === 'Pending' ? -1 : 1));
            console.log('filtered documents --',JSON.stringify(this.filteredDocuments));
            this.filteredDocuments.filter((itm,index)=>{
                if(itm.ContentDocumentId===doccheck)
                    {
                    this.currentIndex = index;
                    return true;
                    }
            })
            this.totalCount = this.filteredDocuments.length;
        }
        else if(this.levelHeader === 'Applicant level documents'){
            this.filteredDocuments = this.documents.filter(doc => doc.requirementLevel === 'Application Level').sort((a) => (a.screeningStatus === 'Pending' ? -1 : 1));
            console.log('filtered documents --',JSON.stringify(this.filteredDocuments));
            this.filteredDocuments.filter((itm,index)=>{
                console.log('is index available??',index);
                if(itm.ContentDocumentId===doccheck)
                    {
                    this.currentIndex = index;
                    return true;
                    }
            })
            this.totalCount = this.filteredDocuments.length;
        }
            this.buttonVisibilityPendingCheck();
            this.buttonVisibilityScreenedCheck();
            this.buttonVisibilitySamplingCheck();
            this.buttonVisibilityOnHoldCheck();
            this.buttonVisibilitySendBackCheck();
            this.buttonVisibilityRecommendCheck();
            this.handleBackConfirmationTab();
    }
    async handleDocChange(event){
        this.currentIndex = 0;
        let documentId = event.target.value;
        console.log('document id for picklist--',documentId);
        if(this.documentMap.get(documentId).FileExtension === 'pdf'){
            this.isPdf = true;
            const contentDocId = this.documentMap.get(documentId).ContentDocumentId;
            //const base64Content = await this.loadFile(contentDocId);
            this.pdfUrl = window.location.origin +'/sfc/servlet.shepherd/document/download/'+ contentDocId;//this.pdfUrl = this.downloadPdf(base64Content);
            this.imageUrl = null;
        }else{
            this.isPdf = false;
            this.imageUrl = `/sfc/servlet.shepherd/version/download/${documentId}`;
            this.pdfUrl = null;
        }
/*
        this.showApplicationLevel = this.requirementLevelArray.includes('Application Level');
        this.showApplicantLevel = this.requirementLevelArray.includes('Applicant Level');

        this.showApplicationLevelLine = this.showApplicationLevel;
        this.showApplicantLevelLine = this.documentMap.get(documentId).requirementLevel == 'Applicant Level';
        */
        console.log('documentMap==>',this.documentMap);
        //const required = this.documentMap.get(documentId).requirementLevel;
        const required = this.documentMap.get(documentId)?.requirementLevel?.trim();//kalpesh
        console.log('required at?====>>>>',required);
        if(required == 'Applicant Level')
            {
                    console.log('inside level check');
                    this.filteredDocuments = this.documents.filter(doc => doc.requirementLevel === 'Applicant Level').sort((a) => (a.screeningStatus === 'Pending' ? -1 : 1));
                    console.log('filtered documents --',JSON.stringify(this.filteredDocuments));
                    this.filteredDocuments.filter((itm,index)=>{
                         if(itm.ContentDocumentId=== this.documentMap.get(documentId).ContentDocumentId)
                            {
                            this.currentIndex = index;
                            return true;
                            }
                    })
                    this.totalCount = this.filteredDocuments.length;
            }
        this.levelHeader  = this.documentMap.get(documentId).requirementLevel == 'Applicant Level' ? 'Applicant level documents' : 'Application level documents';
        this.changeDocOwner = this.documentMap.get(documentId).ownerName;
        this.changeDocName = this.documentMap.get(documentId).Name;
        this.changeScreenigStatus = this.documentMap.get(documentId).screeningStatus;
        this.changeRemarks=this.documentMap.get(documentId).remark;
        this.buttonVisibilityPendingCheck(); 
        this.buttonVisibilityScreenedCheck();
        this.buttonVisibilitySamplingCheck();
        this.buttonVisibilitySendBackCheck();
        this.buttonVisibilityRecommendCheck();
        
    }

    /*@wire(getRecord, { recordId: Id, fields: [ProfileName,UserName] })
    userDetails({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            if (data.fields.Profile.value != null) {
                let profileName = data.fields.Profile.value.fields.Name.value;
                this.currentProfileName = data.fields.Profile.value.fields.Name.value;
                if(profileName === 'System Administrator'){
                    this.profile.Admin = true;
                }else{
                    this.profile.Sampler = true;
                }
                // }else if(profileName === 'FCU Sampler'||profileName==='Central FCU Sampler'){
                //     this.profile.Sampler = true
                // }
                if (data.fields.Name.value != null) {
                    this.currentUserName = data.fields.Name.value;
                }
            }
        }
    }*/
    @wire(getCurrentUserProfileName)
    wiredProfile({ error, data }) {
        if (error) {
            this.error = error;  // Handle error if any
        } else if (data) {
            this.currentProfileName = data;  // Store the profile name returned by Apex

            // Set the profile flags based on the profile name
            if (this.currentProfileName === 'Admin') {
                this.profile.Admin = true;
            } else if (this.currentProfileName === 'Sampler') {
                this.profile.Sampler = true;
            } /*else if (this.currentProfileName === 'FCU Admin') {
                this.profile.FCU_Admin = true;
            } else if (this.currentProfileName === 'FCU Executive') {
                this.profile.FCU_Executive = true;
            }*/
        }
    }
    getProfileName(){
        getCurrentUserProfileName({
            
        }).then(response=>{
            console.log('response -->'+JSON.stringify(response));
            this.currentProfileName = response;  // Store the profile name returned by Apex
            // Set the profile flags based on the profile name
            if (this.currentProfileName === 'Admin' || this.currentProfileName === 'Credit Manager') {
                this.profile.Admin = true;
            } else if (this.currentProfileName === 'Sampler') {
                this.profile.Sampler = true;
            }
            
        }).catch(error=>{
            console.error('Error getCurrentUserProfileName -->', JSON.stringify(error));
        });
    }

    getObjectName(){
        getObjectName({
            recordId:this.recordId
        }).then(result=>{
            this.objectName = result;
            if(this.objectName=='Vendor__c'){
                this.isVendor=true;
            }
            this.handleRefreshData();
            registerListener("inititedFCUrefreshdata",this.handleRefreshData, this);
        })
    }
    getAllRelatedDocs() {
        getAllDocument({
            recordId: this.recordId
        }).then(response=>{
            //this.alldocuments = response;
            this.alldocuments = this.sortDocumentsByScreeningStatus(response);
            console.log('all related documents -->'+JSON.stringify(this.alldocuments));
        }).catch(error=>{
            console.error('Error allrelateddocuments file -->', JSON.stringify(error));
        });
    }
    wiredGetQueries(){
        getQueries({recordId: this.recordId}).then(response=>{
            console.log('all related queries -->'+response);
            var data= JSON.parse(JSON.stringify(response));
            let i=1;
            data.forEach( ele =>{
                ele.index = i;
                i++;
            })
            this.queries = data;
            console.log('all related queries -->'+JSON.stringify(response));
        }).catch(error=>{
            console.error('Error allrelateddocuments file -->', JSON.stringify(error));
        });
    }
    sortDocumentsByScreeningStatus(documents) {
            const statusOrder = ['Pending', 'Added to sampling queue', 'Recommended For FCU','On Hold','Screened','FCU Initiated',''];
        
            return documents.sort((a, b) => {
                // Default empty string to a high value (or choose where you want empty string items to go)
                const statusA = a.screeningstatus || '';  // Use empty string if screeningstatus is null or undefined
                const statusB = b.screeningstatus || '';  // Use empty string if screeningstatus is null or undefined
        
                // Sorting based on the index in statusOrder
                return statusOrder.indexOf(statusA) - statusOrder.indexOf(statusB);
            });
    }
    wiredDocuments(){
        getDocumentsChecklist({
            recordId: this.recordId
        }).then(response=>{
            this.wiredResult = response;
            this.documents = response;
            console.log('this.documents -->'+JSON.stringify(this.documents));
            this.combineScreeningStatus();
            this.firstImage();
        }).catch(error=>{
            console.error('Error wiredDocuments file -->', JSON.stringify(error));
        });
    }

    wiredDocumentsScreening(){
        getDocumentScreeningStatus({
            recordId: this.recordId
        }).then(response=>{
            this.documentsScreening = response;
            console.log('this.documentsScreening -->'+JSON.stringify(this.documentsScreening));
            this.combineScreeningStatus();
        }).catch(error=>{
            console.error('Error wiredDocumentsScreening file -->', JSON.stringify(error));
        });
    }
    getFcuStatusAndUpdateLoan()
    {
        console.log('inside fcu check',this.recordId);
        getFcuStatusAndUpdateLoan({loanId:this.recordId})
        .then(result => {
            console.log('check the fcu result -->'+result)
        })
    }
/*
    @wire(getDocumentsChecklist, { recordId: '$recordId' })
    wiredDocuments({ error, data }) {
        this.wiredResult = data;
        if (data) {
            this.documents = data;
            console.log('this.documents::', JSON.stringify(this.documents));
            this.combineScreeningStatus();
            this.firstImage();
        } else if (error) {
            console.error('Error retrieving documents:', error);
        }
    }*/

    // @wire(getDocumentScreeningStatus, { recordId: '$recordId' })
    // wiredDocumentsScreening({ error, data }) {
    //     if (data) {
    //         this.documentsScreening = data;
    //         this.combineScreeningStatus();
    //     } else if (error) {
    //         console.error('Error retrieving documents:', error);
    //     }
    // }

    connectedCallback(){
        this.getObjectName();
        this.getProfileName();
        console.log(`the Value of Profile is ${JSON.stringify(this.profile)}`)
        this.buttonVisibilityOnHoldCheck();
    }

    handleRefreshData(){
        this.wiredDocuments();
        this.wiredDocumentsScreening();
        this.getAllRelatedDocs();
        this.wiredGetQueries();
    }

    disconnectedCallback() { 
        unregisterAllListeners(this); 
    }

    async combineScreeningStatus() {
        if (this.documents.length > 0 && this.documentsScreening.length > 0) {
            this.documents = this.documents.map(doc => {
                const matchingScreening = this.documentsScreening.find(screening => screening.Content_Document_Id__c === doc.ContentDocumentId);
                const screeningStatusCheck = matchingScreening ? matchingScreening.Screening_Status__c : null;
                console.log('matchingScreening -->'+JSON.stringify(matchingScreening));
                if(this.isVendor==false){
                    if(matchingScreening.Applicant__c!= null){
                        return {
                            ...doc,
                            remark: matchingScreening.Remarks__c,
                            screeningStatus: matchingScreening ? matchingScreening.Screening_Status__c : null,
                            Name: matchingScreening ? matchingScreening.Name : null,
                        
                            ownerName: matchingScreening.Applicant__r.First_Name__c +' '+ matchingScreening.Applicant__r.Last_Name__c,
                            docCheckListId: matchingScreening ? matchingScreening.Id : null,
                            requirementLevel: matchingScreening ? matchingScreening.Requirement_Level__c : null,
                           // fcuinitiated: matchingScreening ? matchingScreening.FCU_Initiated__c : null,
                            fcuinitiated: (screeningStatusCheck === 'FCU Completed') ? false : (matchingScreening ? matchingScreening.FCU_Initiated__c : null),
                            documentdetails: matchingScreening ? matchingScreening.Document_Details__c : null,
                            documentCategory: matchingScreening && matchingScreening.Document_Master__c!=null ? matchingScreening.Document_Master__r.Document_Category__c : null,
                        };
                    }else{
                        return {
                            ...doc,
                            remark: matchingScreening.Remarks__c,
                            screeningStatus: matchingScreening ? matchingScreening.Screening_Status__c : null,
                            Name: matchingScreening ? matchingScreening.Name : null,
                            ownerName:  null,//'('+matchingScreening.Applicant_Detail__r.Name+')',
                            docCheckListId: matchingScreening ? matchingScreening.Id : null,
                            requirementLevel: matchingScreening ? matchingScreening.Requirement_Level__c : null,
                           // fcuinitiated: matchingScreening ? matchingScreening.FCU_Initiated__c : null,
                            fcuinitiated: (screeningStatusCheck === 'FCU Completed') ? false : (matchingScreening ? matchingScreening.FCU_Initiated__c : null),
                            documentdetails: matchingScreening ? matchingScreening.Document_Details__c : null,
                            documentCategory: matchingScreening && matchingScreening.Document_Master__c!=null? matchingScreening.Document_Master__r.Document_Category__c : null,
                        };
                    }
                }else{
                    if(matchingScreening.Contact__c != null){
                        return {
                            ...doc,
                            remark: matchingScreening.Remarks__c,
                            screeningStatus: matchingScreening ? matchingScreening.Screening_Status__c : null,
                            Name: matchingScreening ? matchingScreening.Name : null,
                            vendorDetailName: matchingScreening ? matchingScreening.Vendor__r?.Name : null,
                            contactDetailName:matchingScreening ? matchingScreening.Contact__r?.Name : null,
                            ownerName:  '('+matchingScreening.Contact__r.Name+')',
                            docCheckListId: matchingScreening ? matchingScreening.Id : null,
                            requirementLevel: matchingScreening ? matchingScreening.Requirement_Level__c : null,
                           // fcuinitiated: matchingScreening ? matchingScreening.FCU_Initiated__c : null,
                            fcuinitiated: (screeningStatusCheck === 'FCU Completed') ? false : (matchingScreening ? matchingScreening.FCU_Initiated__c : null),
                            documentdetails: matchingScreening ? matchingScreening.Document_Details__c : null,
                            documentCategory: matchingScreening && matchingScreening.Document_Master__c!=null ? matchingScreening.Document_Master__r.Document_Category__c : null,
                        };
                    }else{
                        return {
                            ...doc,
                            remark: matchingScreening.Remarks__c,
                            screeningStatus: matchingScreening ? matchingScreening.Screening_Status__c : null,
                            Name: matchingScreening ? matchingScreening.Name : null,
                            vendorDetailName: matchingScreening ? matchingScreening.Vendor__r?.Name : null,
                            contactDetailName:matchingScreening ? matchingScreening.Contact__r?.Name : null,
                            ownerName:  +matchingScreening.Vendor__r.Name,
                            docCheckListId: matchingScreening ? matchingScreening.Id : null,
                            requirementLevel: matchingScreening ? matchingScreening.Requirement_Level__c : null,
                          //  fcuinitiated: matchingScreening ? matchingScreening.FCU_Initiated__c : null,
                            fcuinitiated: (screeningStatusCheck === 'FCU Completed') ? false : (matchingScreening ? matchingScreening.FCU_Initiated__c : null),
                            documentdetails: matchingScreening ? matchingScreening.Document_Details__c : null,
                            documentCategory: matchingScreening && matchingScreening.Document_Master__c!=null ? matchingScreening.Document_Master__r.Document_Category__c : null,
                        };
                    } 
                }
                
            });
            // console.log('Combined documents with screening status:', JSON.stringify(this.documents));
            // console.log('Total docs --> '+this.documents.length);
            if(this.isVendor==false){
            await this.handleSortAndCheckLevel();
            }else{
                await this.handleShowVendorLevel();
            }
            this.getPicklistOptions();
        }
    }

    async handleShowVendorLevel(){
        this.currentIndex = 0;

        this.levelHeader = 'Vendor level documents';
        this.filteredDocuments = this.documents.filter(doc =>( doc.requirementLevel === 'Vendor Level'||doc.requirementLevel === 'Contact Level')).sort((a) => (a.screeningStatus === 'Pending' ? -1 : 1));
        this.totalCount = this.filteredDocuments.length;      
        this.buttonVisibilityPendingCheck(); 
        this.buttonVisibilityScreenedCheck();
        this.buttonVisibilitySamplingCheck();
        this.buttonVisibilitySendBackCheck();
        this.buttonVisibilityRecommendCheck();
        this.modalVisibility = true;
        this.spinnerRun = false;

        if(this.showSentToSmapler){
            console.log('showSampling');
            fireEvent(this.pageRef, "showSampling", "showSampling");
            const valueCloseEvent = new CustomEvent('showsampling', {});
            this.dispatchEvent(valueCloseEvent);
        }else{
            console.log('dontshowSampling');
            fireEvent(this.pageRef, "dontshowSampling", "dontshowSampling");
        }
        await this.firstImage();
    }

    showApplicationLevel = false;
    showApplicantLevel = false;
    showCollateralLevel = false;
    showApplicationLevelLine = false;
    showApplicantLevelLine = false;
    showCollateralLevelLine = false;
    async handleSortAndCheckLevel(){
        var presentDocLevel = [];
        this.docLevellist.forEach(value => {
            if((this.documents.filter(doc => doc.requirementLevel == value).length > 0)){
                presentDocLevel.push(value);
            }
        });

        // if(presentDocLevel.length == 5){
        //     this.show5level = true;
        //     this.handleShowApplicationLevel();
        // }else{
        //     this.show5level = false;
            this.showSize = 12 / presentDocLevel.length;

            presentDocLevel.forEach(value => {
                // if(value == 'Collateral Level'){
                //     this.showCollateralLevel = true;
                // }
                if(value == 'Applicant Level'){
                    this.showApplicantLevel = true;
                }
                if(value == 'Application Level'){
                    this.showApplicationLevel = true;
                }
            });

            if(this.showSize == 12){
                this.showApplicationLevelLine = false;
                this.showApplicantLevelLine = false;
                this.showCollateralLevelLine = false;
                if(this.showApplicationLevel){
                    this.handleShowApplicationLevel();
                }
                if(this.showApplicantLevel){
                    this.handleApplicantLevel();
                }
                if(this.showCollateralLevel){
                    this.handleCollateralLevel();
                }
            }else if(this.showSize == 6){
                if(this.showApplicationLevel && (!this.showApplicantLevel || !this.showCollateralLevel)){
                    this.showApplicationLevelLine = true;
                    this.showApplicantLevelLine = false;
                    this.showCollateralLevelLine = false;
                    this.handleShowApplicationLevel();
                }else if(this.showApplicantLevel && !this.showApplicationLevel && this.showCollateralLevel){
                    this.showApplicationLevelLine = false;
                    this.showApplicantLevelLine = true;
                    this.showCollateralLevelLine = false;
                    this.handleApplicantLevel();
                }
            }else if(this.showSize == 4){
                if(this.showApplicantLevel && this.showApplicationLevel && this.showCollateralLevel){
                    this.showApplicationLevelLine = true;
                    this.showApplicantLevelLine = true;
                    this.showCollateralLevelLine = false;
                    this.handleShowApplicationLevel();
                }
            }
        // }

        this.modalVisibility = true;
        this.spinnerRun = false;

        if(this.showSentToSmapler){
            console.log('showSampling');
            fireEvent(this.pageRef, "showSampling", "showSampling");
            const valueCloseEvent = new CustomEvent('showsampling', {});
            this.dispatchEvent(valueCloseEvent);
        }else{
            console.log('dontshowSampling');
            fireEvent(this.pageRef, "dontshowSampling", "dontshowSampling");
        }
    }

    async handleShowApplicationLevel(){
        this.currentIndex = 0;

        this.levelHeader = 'Application level documents';
        // console.log('All documents -->', JSON.stringify(this.documents));

        this.filteredDocuments = this.documents.filter(doc => doc.requirementLevel === 'Application Level').sort((a) => (a.screeningStatus === 'Pending' ? -1 : 1));
        this.totalCount = this.filteredDocuments.length;        
        await this.firstImage();

        // console.log('Filtered value -->' + JSON.stringify(this.filteredDocuments));
    }
    async handleApplicantLevel(){
        this.currentIndex = 0;

        this.levelHeader = 'Applicant level documents';
        this.filteredDocuments = this.documents.filter(doc => doc.requirementLevel === 'Applicant Level').sort((a) => (a.screeningStatus === 'Pending' ? -1 : 1));
        this.totalCount = this.filteredDocuments.length;

        await this.firstImage();
        // console.log('Filtered value -->' + JSON.stringify(this.filteredDocuments));
    }
    async handleCoapplicantLevel(){

    }
    async handleGuarantorLevel(){

    }
    // async handleCollateralLevel(){
    //     this.currentIndex = 0;

    //     this.levelHeader = 'Collateral level documents';
    //     this.filteredDocuments = this.documents.filter(doc => doc.requirementLevel === 'Collateral Level').sort((a) => (a.screeningStatus === 'Pending' ? -1 : 1));
    //     this.totalCount = this.filteredDocuments.length;

    //     await this.firstImage();
    //     // console.log('Filtered value -->' + JSON.stringify(this.filteredDocuments));
    // }

    docLevelChange(event) {
        this.docLevelValue = event.target.value;
    }

    updateRecordField(recordId, fieldApiName, fieldValue) {
        const fields = {};
        fields['Id'] = recordId;
        fields[fieldApiName] = fieldValue;
        if(this.remarks){
            const now = new Date();
            const formattedDate = now.getFullYear() + '-' +
                      String(now.getMonth() + 1).padStart(2, '0') + '-' +
                      String(now.getDate()).padStart(2, '0') + 'T' +
                      String(now.getHours()).padStart(2, '0') + ':' +
                      String(now.getMinutes()).padStart(2, '0');
            console.log('profile name-->',this.currentProfileName);
            if(this.currentProfileName == 'Sampler'){
                console.log('remarks----'+fieldApiName);
                if(fieldApiName!='Send_back_reason__c' && this.fieldApiName=='Remarks__c'){
                console.log('remarks----'+this.remarks);
                fields['Remarks__c'] = this.remarks+'-'+this.username+'-'+formattedDate;
                this.remarks = this.remarks+'-'+this.username+'-'+formattedDate;
                }else if(fieldApiName=='Send_back_reason__c'){
                    console.log('remarks----'+this.remarks);
                    fields['Send_back_reason__c'] = this.remarks+'-'+this.username+'-'+formattedDate;
                }else if(fieldApiName=='Screening_Status__c' && (this.remarks !=null || this.remarks !='' || this.remarks !=undefined)){
                    fields['Remarks__c'] = this.remarks+'-'+this.username+'-'+formattedDate;
                    fields['Referred_By__c'] = USER_ID;
                    fields['Referred_By_Role__c'] = 'Sampler';
                }
            }
            else if (this.currentProfileName == 'Credit Manager'){
                console.log('remarks----'+fieldApiName);
                if(fieldApiName!='Send_back_reason__c' && this.fieldApiName=='Remarks__c'){
                console.log('remarks----'+this.remarks);
                fields['Remarks__c'] = this.remarks+'-'+this.username+'-'+formattedDate;
                this.remarks = this.remarks+'-'+this.username+'-'+formattedDate;
                }else if(fieldApiName=='Send_back_reason__c'){
                    console.log('remarks----'+this.remarks);
                    fields['Send_back_reason__c'] = this.remarks+'-'+this.username+'-'+formattedDate;
                }else if(fieldApiName=='Screening_Status__c' && (this.remarks !=null || this.remarks !='' || this.remarks !=undefined)){
                    fields['Remarks__c'] = this.remarks+'-'+this.username+'-'+formattedDate;
                    fields['Referred_By__c'] = USER_ID;
                    fields['Referred_By_Role__c'] = 'Credit';
                }
            }
            else{
                console.log('remarks----'+fieldApiName);
                fields['Remarks__c'] = this.remarks+'-'+this.username+'-Credit-'+formattedDate;
                fields['Referred_By__c'] = USER_ID;
                fields['Referred_By_Role__c'] = 'credit'; //this.currentProfileName;
                this.remarks = this.remarks+'-'+this.username+'-'+formattedDate;
            }
            
        }
        else{
            if(this.currentProfileName == 'Sampler'||this.currentProfileName == 'Credit Manager'){
              
                 if(fieldApiName=='Screening_Status__c'){
                   
                    fields['Referred_By__c'] = USER_ID;
                    fields['Referred_By_Role__c'] = 'Sampler';
                }
            }
            else{
                console.log('remarks----'+fieldApiName);
                fields['Remarks__c'] = this.remarks+'-'+this.username+'-Credit-'+formattedDate;
                fields['Referred_By__c'] = USER_ID;
                fields['Referred_By_Role__c'] = 'credit'; //this.currentProfileName;
                this.remarks = this.remarks+'-'+this.username+'-'+formattedDate;
            } 
        }
        
        const recordInput = { fields };
        console.log('record input -->'+JSON.stringify(recordInput));
        updateRecord(recordInput)
            .then(() => {
                this.updateDocumentStatus(recordId, fieldValue);
                this.buttonVisibilityPendingCheck(); 
                this.buttonVisibilityScreenedCheck();
                this.buttonVisibilitySamplingCheck();
                this.buttonVisibilitySendBackCheck();
                this.buttonVisibilityRecommendCheck();
                if(this.remarks!=null){
                    this.filteredDocuments[this.currentIndex].remark = this.remarks
                    this.remarks = null;
                }
                else{
                    this.filteredDocuments[this.currentIndex].remark = null;
                }
                
                this.showToastMessage('Success', 'Status updated successfully!', 'success');
                // this.handleNext();
                if(this.showSentToSmapler){
                    fireEvent(this.pageRef, "showSampling", "showSampling");
                    const valueCloseEvent = new CustomEvent('showsampling', {});
                    this.dispatchEvent(valueCloseEvent);
                }else{
                    console.log("dontshowSampling");
                    fireEvent(this.pageRef, "dontshowSampling", "dontshowSampling");
                    const valueCloseEvent = new CustomEvent('dontshowsampling', {});
                    this.dispatchEvent(valueCloseEvent);
                }
                // fireEvent(this.pageRef, "changescreeningstatus", "changescreeningstatus");
                const valueCloseEvent = new CustomEvent('changescreeningstatus', {});
                this.dispatchEvent(valueCloseEvent);
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                console.log('Error updating record --> '+JSON.stringify(error));
            });
    }

    handleIconClick() {
        // const currentDocCheckListId = this.currentDocCheckListId;
        // this.updateRecordField(currentDocCheckListId, 'Screening_Status__c', 'Screened');
        this.isRemarkScreen = true;
        this.isScreenRemark = true;
    }

    handleHold(event){
        console.log('event.name  '+event.target.name)
        const buttonName = event.target.name
        const currentDocCheckListId = this.currentDocCheckListId;
        if (this.buttonLabel == 'Hold' || buttonName == 'holdButton') {
            // console.log('this.showHoldButton    '+this.showHoldButton );
            // this.buttonLabel = 'Un-Hold'
            // this.showHoldButton = false;
            // console.log('this.showHoldButton    '+this.showHoldButton );
            
        this.openQueryModule = true;
        //this.updateRecordField(currentDocCheckListId, 'Screening_Status__c', 'On Hold');
        }
        if (this.buttonLabel == 'Un-Hold') {
            this.updateRecordField(currentDocCheckListId, 'Screening_Status__c', 'Pending');
            this.buttonLabel = 'Hold'
            this.showHoldButton = true;
        }
    }

    handleUnHold(){
        try {
            const currentDocCheckListId = this.currentDocCheckListId;
            this.showHoldButton = true;
            this.showUnHoldButton = false;
            // this.handleBackConfirmation();
            this.modalVisibility = false;
            this.showConfirmationScreen = true;
            console.log('handleUnHold ');
            this.updateRecordField(currentDocCheckListId, 'Screening_Status__c', 'Pending');
            this.updateRecordField(currentDocCheckListId, 'Verification_Status__c', 'Pending');
        } catch (error) {
            console.log('handleUnHold  error  '+error);
        }
        
    }

    handleSample() {

        this.isRemarkScreen = true;
        this.isSampleRemark = true;
        this.isScreenRemark = false;
    }

    handleRecommend() {
        this.isRemarkScreen = true;
        this.isRecommendRemark = true;
        this.isScreenRemark = false;
        this.isSampleRemark = false;
        //this.updateRecordField(currentDocCheckListId, 'Screening_Status__c', 'Recommended For FCU');
    }

    handleRemoveFromQueue() {
        const currentDocCheckListId = this.currentDocCheckListId;
        console.log('checking id -->',this.currentDocCheckListId);
        setTimeout(() => {
            this.updateRecordField(currentDocCheckListId, 'Screening_Status__c', 'Screened');
        }, 800);
        setTimeout(() => {
            this.remarks = null;
            this.updateRecordField(currentDocCheckListId, 'Remarks__c', '');
        }, 400);
        
    }
    handleSendBack(){
        this.modalVisibility=false;
        this.showSendBackRemarks=true;
        this.docId = this.currentDocCheckListId;
    }

    handleRemoveFromScreened() {
        this.modalVisibility = false;
        this.showConfirmationScreen = true;
    }

    handleBackConfirmation() {
        this.modalVisibility = true;
        this.showConfirmationScreen = false;
    }

    handleYes(){
        const currentDocCheckListId = this.currentDocCheckListId;
        this.updateRecordField(currentDocCheckListId, 'Screening_Status__c', 'Pending');
        this.handleBackConfirmation();
    }

    async handleNext() {
        this.attributesToNull();
        if (this.currentIndex < this.filteredDocuments.length - 1) {
            this.currentIndex++;
            console.log('current index --',this.currentIndex);
        }
        
        await this.firstImage();
    }

    async handlePrevious() {
        this.attributesToNull();
        if (this.currentIndex > 0) {
            this.currentIndex--;
        }
        
        await this.firstImage();
    }
    
    attributesToNull(){
        this.changeDocOwner = '';
        this.changeDocName = '';
        this.changeScreenigStatus = '';
        this.changeRemarks = '';
    }

     getDocDownloadBase() {
    const origin = window.location.origin || '';
    return origin.includes('my.site.com')
        ? `${origin}/losportal/sfc/servlet.shepherd`
        : `${origin}/sfc/servlet.shepherd`;
    }

    async firstImage() {
        if (this.filteredDocuments.length > 0) {
            const currentDoc = this.filteredDocuments[this.currentIndex];
            if (currentDoc.FileExtension === 'pdf') {
                this.isPdf = true;
                const contentDocId = currentDoc.ContentDocumentId;
                //const base64Content = await this.loadFile(contentDocId);
                this.pdfUrl = window.location.origin +'/sfc/servlet.shepherd/document/download/'+ contentDocId;//this.pdfUrl = this.downloadPdf(base64Content);              
                this.imageUrl = null;
                this.isZipFolder = false;
            } else if(currentDoc.FileExtension === 'zip'){
                console.log('There is a zip file 1006...');
                this.isPdf = false;
                this.imageUrl = null;
                 this.pdfUrl = null;
                this.isZipFolder = true;
                const base = this.getDocDownloadBase();
                const contentDocId = currentDoc.ContentDocumentId; 
                this.fileUrl = `${base}/document/download/${contentDocId}?v=${Date.now()}`;
                console.log('this.fileUrl>>>'+this.fileUrl);
                 
            }else {
                this.isZipFolder = false;
                this.isPdf = false;
                this.imageUrl = `/sfc/servlet.shepherd/version/download/${currentDoc.Id}`;
                this.pdfUrl = null;
            }
        }
        this.buttonVisibilityPendingCheck(); 
        this.buttonVisibilityScreenedCheck();
        this.buttonVisibilitySamplingCheck();
        this.buttonVisibilitySendBackCheck();
        this.buttonVisibilityRecommendCheck();
        this.buttonVisibilityOnHoldCheck();
    }

    // loadFile(contentDocId) {
    //     return getFileAsBase64({ contentDocumentId: contentDocId })
    //         .then(base64File => {
    //             console.log('Base64 file content retrieved:', base64File);
    //             return base64File;
    //         })
    //         .catch(error => {
    //             console.error('Error fetching file:', error);
    //             return null;
    //         });
    // }

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
            console.log('url being formed??-->',url);
            return url;
        } catch (error) {
            console.error('Error loading PDF:', error);
            return null;
        }
    }

    updateDocumentStatus(docCheckListId, newStatus) {
        this.filteredDocuments = this.filteredDocuments.map(doc => {
            if (doc.docCheckListId === docCheckListId) {
                if(newStatus != 'Verified')
                {
                if(newStatus == 'Recommended For FCU'){
                    return { ...doc, screeningStatus: 'Recommended For FCU' };
                }
                else{
                    return { ...doc, screeningStatus: newStatus };
                }
            }
            else
            {
            return { ...doc, screeningStatus: 'Screened' };
                }
            }
            return doc;
        });

        this.documents = this.documents.map(doc => {
            if (doc.docCheckListId === docCheckListId) {
                if(newStatus == 'Recommended For FCU'){
                    return { ...doc, screeningStatus: 'Recommended For FCU' };
                }
                else{
                    return { ...doc, screeningStatus: newStatus };
                }
            }
            return doc;
        });
    }
    get currentUserName() {
        return this.filteredDocuments?.length > 0 && this.filteredDocuments[this.currentIndex]?.Vendor__c 
            ? this.filteredDocuments[this.currentIndex]?.Vendor__r?.Name 
            : null;
    }
   
    get currentDocument() {
        return this.filteredDocuments.length > 0 ? this.filteredDocuments[this.currentIndex] : null;
    }

    get currentDocCheckListId() {
        return this.filteredDocuments.length > 0 ? this.filteredDocuments[this.currentIndex].docCheckListId : null;
    }

    get currentReqLevel() {
        return this.filteredDocuments.length > 0 ? this.filteredDocuments[this.currentIndex].requirementLevel : null;
    }
    get setRemarks(){
        return this.changeRemarks ? this.changeRemarks : this.filteredDocuments.length > 0 ? this.filteredDocuments[this.currentIndex].remark : null;
    }
    get currentScreenigStatus() {
        return this.changeScreenigStatus ? this.changeScreenigStatus : this.filteredDocuments.length > 0 ? this.filteredDocuments[this.currentIndex].screeningStatus : null;
    }

    get currentfcuinitiated() {
        return this.filteredDocuments.length > 0 ? this.filteredDocuments[this.currentIndex].fcuinitiated : null;
    }

    get currentDocName() {
        return this.changeDocName ? this.changeDocName : this.filteredDocuments.length > 0 ? this.filteredDocuments[this.currentIndex].Name : null;
    }

    get currentDocOwner() {
        return this.changeDocOwner ? this.changeDocOwner : this.filteredDocuments.length > 0 ? this.filteredDocuments[this.currentIndex].ownerName : null;
    }

    get currentApplDetailName() {
        return this.filteredDocuments?.length > 0 && this.filteredDocuments[this.currentIndex]?.Applicant__c 
            ? this.filteredDocuments[this.currentIndex]?.Applicant__r?.Name 
            : null;
    }

    get disablePrevious() {
        return this.currentIndex === 0;
    }

    get disableNext() {
        return this.currentIndex === this.filteredDocuments.length - 1;
    }

    get showCurrentIndex() {
        return this.currentIndex + 1;
    }

    get completedcount(){
        return this.totalCount - this.filteredDocuments.filter(doc => doc.screeningStatus != 'Pending').length;
    }

    get showApplicationSuccess() {
        if((this.documents.filter(doc => doc.requirementLevel == 'Application Level').length - this.documents.filter(doc => doc.screeningStatus != 'Pending' && doc.requirementLevel == 'Application Level').length) == 0){
            return true;
        }else{
            return false;
        }
    }

    get showApplicantSuccess() {
        if((this.documents.filter(doc => doc.requirementLevel == 'Applicant Level').length - this.documents.filter(doc => doc.screeningStatus != 'Pending' && doc.requirementLevel == 'Applicant Level').length) == 0){
            return true;
        }else{
            return false;
        }
    }

    

    // get showCollateralSuccess() {
    //     if((this.documents.filter(doc => doc.requirementLevel == 'Collateral Level').length - this.documents.filter(doc => doc.screeningStatus != 'Pending' && doc.requirementLevel == 'Collateral Level').length) == 0){
    //         return true;
    //     }else{
    //         return false;
    //     }
    // }

    get showSentToSmapler() {
        if(this.isVendor==false){
        return ((this.showApplicationLevel && this.showApplicationSuccess) || !this.showApplicationLevel) && ((this.showApplicantLevel && this.showApplicantSuccess) || !this.showApplicantLevel);
        }else{
            this.showVendorSuccess();
        }
    }
    get showVendorSuccess() {
        if(this.documents!=undefined){
            if((this.documents.filter(doc => (doc.requirementLevel == 'Vendor Level'||doc.requirementLevel == 'Contact Level')).length - this.documents.filter(doc => doc.screeningStatus != 'Pending' && (doc.requirementLevel == 'Vendor Level'||doc.requirementLevel == 'Contact Level')).length) == 0){
                return true;
            }else{
                return false;
            }
        }
    }

    get buttonVisibilityPending() {
        return (this.filteredDocuments[this.currentIndex].screeningStatus === 'Pending' || this.filteredDocuments[this.currentIndex].screeningStatus === 'FCU Completed');
    }
    get buttonVisibilityScreened() {
        return this.filteredDocuments[this.currentIndex].screeningStatus === 'Screened';
    }
    get buttonVisibilitySampling() {
        return this.filteredDocuments[this.currentIndex].screeningStatus === 'Added to sampling queue';
    }
    get buttonVisibilitySentBack(){
        return this.filteredDocuments[this.currentIndex].screeningStatus === 'Sent Back';
    }
    get buttonVisibilityRecommend(){
        return this.filteredDocuments[this.currentIndex].screeningStatus === 'Recommended For FCU';
    }
    get buttonVisibilityOnhold (){
        return this.filteredDocuments[this.currentIndex].screeningStatus === 'On Hold';
    }
     buttonVisibilityPendingCheck() {
        console.log('index check -->',this.currentIndex);
        console.log('this.filteredDocuments[this.currentIndex]---'+ JSON.stringify(this.filteredDocuments[this.currentIndex]));
        if(this.filteredDocuments[this.currentIndex] != undefined){
            this.buttonVisibilityPending =  this.filteredDocuments[this.currentIndex].screeningStatus === 'Pending' ||
                                            this.filteredDocuments[this.currentIndex].screeningStatus === 'On Hold' || this.filteredDocuments[this.currentIndex].screeningStatus == 'FCU Completed'|| this.filteredDocuments[this.currentIndex].screeningStatus == 'Cancelled'
                                            ? true : false;
        }
        console.log('The Button Pending Value is : '+ JSON.stringify(this.buttonVisibilityPending));
    }
    buttonVisibilityScreenedCheck() {
        if(this.filteredDocuments[this.currentIndex] != undefined){
            this.buttonVisibilityScreened = this.filteredDocuments[this.currentIndex].screeningStatus === 'Screened';
        }
    }
    buttonVisibilitySamplingCheck() {
        if(this.filteredDocuments[this.currentIndex] != undefined){
            this.buttonVisibilitySampling = this.filteredDocuments[this.currentIndex].screeningStatus === 'Added to sampling queue';
        }
    }

    /* Use when confirmed about Hold */
    buttonVisibilityOnHoldCheck() {
        if(this.filteredDocuments[this.currentIndex] != undefined){
            this.buttonVisibilityOnhold = this.filteredDocuments[this.currentIndex].screeningStatus === 'On Hold'? true : false;
            console.log('The button visibility on hold is '+JSON.stringify(this.buttonVisibilityOnhold));
            console.log('On hold --->')
        }
    }

    buttonVisibilitySendBackCheck(){
        if(this.filteredDocuments[this.currentIndex] != undefined){
            this.buttonVisibilitySentBack = this.filteredDocuments[this.currentIndex].screeningStatus === 'Sent Back';
        }
    }

    buttonVisibilityRecommendCheck(){
        if(this.filteredDocuments[this.currentIndex] != undefined){
            this.buttonVisibilityRecommend = this.filteredDocuments[this.currentIndex].screeningStatus === 'Recommended For FCU';
        }
    }

    sentToSampler(){
        this.modalVisibility = false;
        this.showInitiationCmp = true;
    }

    handleprevious(){
        this.modalVisibility = true;
        this.showInitiationCmp = false;
    }

    handleConfirm(){
        this.modalVisibility = false;
        this.showgenericConfirm = true;
    }

    handlePositive(){
        this.modalVisibility = true;
        this.showgenericConfirm = false;
        this.handleIconClick();
    }
    handleNegative(){
        this.modalVisibility = true;
        this.showgenericConfirm = false;
    }

    closeModal(){
        this.modalVisibility = false;
        this.showInitiationCmp = false;
        const valueCloseEvent = new CustomEvent('closeshowdoc', {});
        this.dispatchEvent(valueCloseEvent);
    }

    showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(toastEvent);
    }

    handleSaveRemarksOnChange(event){
        console.log('remarks------', event.target.value);
            this.remarks = event.target.value;
    }
    handleCloseRemarks(){
        this.remarks='';
        this.showSendBackRemarks=false;
        this.modalVisibility=true;
    }
    handleSaveRemarks(event){
       if(this.remarks!=null &&  this.remarks!='' &&  this.remarks!=undefined){
        console.log('----------------------');
        const currentDocCheckListId = this.docId;
        this.userIdCurrent = Id;
        setTimeout(() => {
            this.updateRecordField(currentDocCheckListId, 'Send_back_reason__c', this.remarks);
            this.updateRecordField(currentDocCheckListId, 'Sent_Back_By__c', this.userIdCurrent);
            
        }, 100);
        this.updateRecordField(currentDocCheckListId, 'Status__c', 'Sent Back');
        this.updateRecordField(currentDocCheckListId, 'Back_Content_Id__c', '');
        this.updateRecordField(currentDocCheckListId, 'Content_Id__c', '');
        setTimeout(() => {
            this.updateRecordField(currentDocCheckListId, 'Screening_Status__c', 'Sent Back');
        }, 500);

        console.log('recordId----'+this.recordId);
        console.log('docId----'+this.docId);
        // sendNotificationSendBack({recordId:this.recordId,documentId:this.docId})
        // .then(result=>{

        // })
        this.showSendBackRemarks=false;
        this.modalVisibility=true;
      }else{
        console.log('----------------------');
          this.showToastMessage('Error', 'Please fill the remarks in order to proceed.', 'Error');
      }
      
       
    }
    handleLastNext(){
        this.attributesToNull();
        if(this.levelHeader == 'Application level documents'){
            this.handleApplicantLevel();
        }
        else if(this.levelHeader == 'Applicant level documents'){
            const filteredDocuments = this.documents.filter(doc => doc.requirementLevel === 'Application Level').sort((a) => (a.screeningStatus === 'Pending' ? -1 : 1));
            const totalCount = filteredDocuments.length;
            if(totalCount > 0){
            this.handleShowApplicationLevel();
            }
            else
            {
                this.handleApplicantLevel();
            }
        }
    }

    cancelRemark(){
        this.isRemarkScreen = false;
        this.isScreenRemark = false;
        this.isSampleRemark = false;
    }

    handleRemark(){
        if((this.remarks == undefined || this.remarks == null || this.remarks =='') && !this.isScreenRemark){
            this.showToastMessage('Error', 'Please fill the remarks in order to proceed.', 'Error');
        }
        else{
            this.isRemarkScreen = false;
            console.log(`The Value is ${this.remarks}`);
            if(this.isRecommendRemark){
                this.updateRecordField(this.currentDocCheckListId, 'Screening_Status__c', 'Recommended For FCU');
                this.isRecommendRemark = false;
               //comment to deploye this.sendNotificationToSampler();
            }
            else if(this.isSampleRemark){
                this.updateRecordField(this.currentDocCheckListId, 'Screening_Status__c', 'Added to sampling queue');
                 this.isSampleRemark = false;
            }
            else if(this.isScreenRemark){
            this.updateRecordField(this.currentDocCheckListId, 'Screening_Status__c', 'Screened');
            // this.updateRecordField(this.currentDocCheckListId, 'Verification_Status__c', 'Verified');
            this.isScreenRemark = false;
        }
        }
    }
    sendNotificationToSampler(){
        sendNotificationToSampler({
            loanId:this.recordId,
            docId:this.currentDocCheckListId
        }).then(resp=>{

        }).catch(error=>{

        })
    }
    handleRemarkChanges(evt){
        // this.remarks = this.remarks + ' - '+evt.target.value;

        const field = evt.target.name;
        const value = evt.target.value;
        const values = [];

        if (field === 'manualRemark') {
            this.manualRemark = value;
        }

        if (field === 'selectedRemark') {
            this.selectedRemark = value;
        }


        if (this.selectedRemark) {
            values.push(this.selectedRemark);
        }

        if (this.manualRemark) {
            values.push(this.manualRemark);
        }

        this.remarks = values.join(' - ');

        console.log('Final Remarks:', this.remarks);
        
    }
    handleMenuClick() {
        this.isTableVisible = !this.isTableVisible;

        setTimeout(async () => {
            try {
                const response = await getAllDocument({
                    recordId: this.recordId
                });

                //this.alldocuments = response;
                this.alldocuments = this.sortDocumentsByScreeningStatus(response);
                console.log('Documents refreshed:', JSON.stringify(response));
            } catch (error) {
                console.error('Error fetching documents:', error);
            }
        }, 10);

        console.log('Apex method getAllDocument invoked.');
    }
    handleBackConfirmationTab(){
        this.isTableVisible = false;
    }

    handleCloseModal(){
        this.openQueryModule = false;
    }
    async handleUpdateQueryAssignment() {
        const currentDocCheckListId = this.currentDocCheckListId;
    
        try {

            await this.updateRecordField(currentDocCheckListId, 'Screening_Status__c', 'On Hold');
            
            await new Promise(resolve => setTimeout(resolve, 200)); 
            
            await this.getFcuStatusAndUpdateLoan();
        this.buttonVisibilityOnHoldCheck();

        if (this.buttonLabel == 'Hold') {
            console.log('this.showHoldButton    '+this.showHoldButton );
            this.buttonLabel = 'Un-Hold'
            this.showHoldButton = false;
            console.log('this.showHoldButton    '+this.showHoldButton );
        }
         
        } catch (error) {
            console.error('Error in handleUpdateQueryAssignment:', error);
        }
    }
    openRecordPage(event){
        let recordId = event.target.dataset.id;
        console.log('test====>',recordId);
        let recordUrl = '/lightning/r/Query__c/' + recordId + '/view';
        window.open(recordUrl,'_blank');
    }
    
}