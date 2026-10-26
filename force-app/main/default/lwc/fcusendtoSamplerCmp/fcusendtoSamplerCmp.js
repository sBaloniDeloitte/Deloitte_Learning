import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDocumentApplicantCollateralFCU from '@salesforce/apex/FCUController.getDocumentApplicantCollateralFCU';
import getDocumentsChecklist from '@salesforce/apex/FCUController.getDocumentsChecklist';
import getDocumentScreeningStatus from '@salesforce/apex/FCUController.getDocumentScreeningStatus';
import getApplicantsDetailsList from '@salesforce/apex/FCUController.getApplicantsDetailsList';
import getPendingInitiatedStatus from '@salesforce/apex/FCUController.getPendingInitiatedStatus';
import getObjectName from '@salesforce/apex/FCUController.getObjectName';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ADDRESSTYPE from '@salesforce/schema/Application_Verification__c.Address_Type__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import FCU_OBJECT from '@salesforce/schema/Application_Verification__c';
import ADD_ICON_2 from '@salesforce/resourceUrl/AddIcon';
import fcusamplingConfirm from '@salesforce/label/c.FCU_sampling_confirm'; 
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import checkIfParentPresent from '@salesforce/apex/FCUController.checkIfParentPresent';
import initiateFCU from '@salesforce/apex/FCUController.initiateFCU';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import removeFromSamplingQueue from '@salesforce/apex/FCUController.removeFromSamplingQueue';
import Id from '@salesforce/user/Id'; 
import ProfileName from '@salesforce/schema/User.Profile.Name';
import UserName from '@salesforce/schema/User.Name';
import { getRecord } from 'lightning/uiRecordApi';
import getUsersByProfile from '@salesforce/apex/FCUController.getUsersByProfile';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName1';
import CONTENT_VERSION_FIELD from '@salesforce/schema/ContentDocument.FileType';
export default class fcusendtoSamplerCmp extends NavigationMixin(LightningElement) {
    @api recordId;

    // @api showSampling = false;
    @track showSampling = false;
    get acceptedFormats() {
        return ['.png','.jpeg'];
    }
    @track uploadedDocumentsMap = {};
    @api modalVisibility = false;

    @track spinnerRun = true;

    @track documents = [];
    
    @track documentsScreening = '';
    @track filteredDocuments = [];
    @track showDoubleDocSelection = false;

    @track applicantsData = [];
    @track collateralData = [];
    @track vendorData=[];
    @track showApplicantsTable = false;
    @track showCollateralTable = false;
    @track showDocumentsTable = false;
    @track showVendorLocationTable = false;

    @track savedSampler = undefined;

    @track remarksValue = '';

    @track addIcon = '';

    @track selectedRecords = {};
    @track selectedRecordsApplicant = {};
    @track selectedRecordApplicationCollateral = {};
    @track selectedRecordsVendorList = {};
    @track parentFCUchildMap = [];

    @track samplerId = '';
    @track samplerName = '';

    @track isParentCreated = '';

    @track showgenericConfirm = false;

    @track negativelabel = 'No';
    @track positiveLabel = 'Yes';
    @track previousConfirmMessage = fcusamplingConfirm;

    @track addressOptions = [];

    @track documentsSelected = false;
    @track profileSelected = false;
    @track collateralSelected = false;
    @track vendorLocationSelected = false;
    @track objectName;
    @track isVendor=false;
    @track selectedRecordsVendor=[];
    @track documentid;
    @track dataid;
    @track filetype = '';
    @track showupload = false;
    @track showview = true;
    @track showdelete = false;
    @track showreatke = false;
    @track showlocation = false;
    @track showSampling = false;
    @track userOptions = [];
        error;


    @wire(CurrentPageReference) pageRef;

    @wire(getObjectInfo, { objectApiName: FCU_OBJECT })
    fcuInfo;
    @wire(getPicklistValues, { recordTypeId: '$fcuInfo.data.defaultRecordTypeId', fieldApiName: ADDRESSTYPE})
    addressPicklistValues({ data, error }) {
        if (data){
            this.addressOptions = data.values;
        }else{
            console.log('addressPicklistValues Error --> '+ JSON.stringify(error));
        } 
    }
    @api isInitiatedSamplingScreen = false;
    @api fromCollateralTab = false;

    getObjectName(){
        getObjectName({
            recordId:this.recordId
        }).then(result=>{
            this.objectName = result;
            if(this.objectName=='Vendor__c'){
                this.isVendor=true;
            }
            this.handleRefreshData();
     
            registerListener("showSampling",this.handleRefreshData, this);
            registerListener("dontshowSampling",this.handleRefreshDataNeg, this);
            registerListener("changescreeningstatus",this.handleRefreshData, this);
        })
    }


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
            } 
            console.log('this.currentProfileName'+this.currentProfileName);
        }
    }

    wiredDocuments(){
        getDocumentsChecklist({
            recordId: this.recordId
        }).then(response=>{
            this.wiredResult = response;
            this.documents = response;
            this.modalVisibility = true;
            this.spinnerRun = false;
            this.combineScreeningStatus();
        }).catch(error=>{
            console.error('Error wiredDocuments file -->', JSON.stringify(error));
        });
    }

    wiredDocumentsScreening(){
        getDocumentScreeningStatus({
            recordId: this.recordId
        }).then(response=>{
            this.documentsScreening = response;
            this.combineScreeningStatus();
        }).catch(error=>{
            console.error('Error checkIfParentPresent file -->', JSON.stringify(error));
        });
    }

    wiredApplicantData(){
        getApplicantsDetailsList({
            recordId: this.recordId
        }).then(response=>{
            console.log('Response from Apex -->',JSON.stringify(response));
            this.applicantsData = response;
            if(this.isInitiatedSamplingScreen){
                this.applicantsData = this.applicantsData.filter(doc => (doc.fcuStatus == 'FCU Initiated'));
            }
            else{
                this.applicantsData = this.applicantsData.filter(doc => (doc.fcuInitiatedStatus == false ));
            }
            this.applicantsData.forEach(doc => {
                if(doc.fcuStatus == 'FCU Initiated'){
                    const parentData = this.parentFCUchildMap[doc.id];
                    doc.fcuId = parentData.fcuId;
                    doc.fcuName = parentData.name;
                    doc.addressValue = parentData.addressValue;
                }else{
                    doc.addressValue = 'Local';
                }
            });
            console.log('this.applicantsData -->'+JSON.stringify(this.applicantsData));
            if(this.applicantsData.length > 0 && !this.fromCollateralTab){
                this.showApplicantsTable = true;
                this.modalVisibility = true;
            }else{
                this.showApplicantsTable = false;
            }
        }).catch(error=>{
            console.error('Error wiredApplicantData file -->', JSON.stringify(error));
        });
    }

    wiredApplicationCollateralData(){
        getApplicationCollateralList({
            recordId: this.recordId
        }).then(response=>{
            this.collateralData = response;
            if(this.isInitiatedSamplingScreen){
                this.collateralData = this.collateralData.filter(doc => (doc.fcuStatus == 'FCU Initiated'));
            }
            else{
                this.collateralData = this.collateralData.filter(doc => (doc.fcuStatus == 'Pending'));
            }

            console.log('this.collateralData -->'+JSON.stringify(this.collateralData));
            console.log('this.parentFCUchildMap -->'+JSON.stringify(this.parentFCUchildMap));
            this.collateralData.forEach(doc => {
                if(doc.fcuStatus == 'FCU Initiated'){
                    const parentData = this.parentFCUchildMap[doc.id];
                    doc.fcuId = parentData.fcuId;
                    doc.fcuName = parentData.name;
                    doc.addressValue = parentData.addressValue;
                }else{
                    doc.addressValue = 'Local';
                }
            });

            if(this.collateralData.length > 0){
                this.showCollateralTable = true;
                this.modalVisibility = true;
            }
        }).catch(error=>{
            console.error('Error wiredApplicationCollateralData file -->', JSON.stringify(error));
        });
    }

    wiredchecklistApplicantData(){
        console.log('Id to apex is -->',this.recordId);
        getDocumentApplicantCollateralFCU({
            recordId: this.recordId
        }).then(response=>{
            console.log('response -->'+JSON.stringify(response));
            this.parentFCUchildMap = response;
            this.wiredDocuments();
            this.wiredDocumentsScreening();
            this.wiredApplicantData();
        }).catch(error=>{
            console.error('Error checkIfParentPresent file -->', JSON.stringify(error));
        });
    }

    connectedCallback(){
        console.log('objectApiName----'+this.objectApiName);
        this.addIcon=ADD_ICON_2;
        this.getObjectName();
         console.log('check',this.isInitiatedSamplingScreen);

        this.fetchUserData();
        console.log('ProfileName'+ProfileName);
      
    }

    handleRefreshSamplingShow(){
        getPendingInitiatedStatus({
            recordId: this.recordId
        }).then(response=>{

            if(response.initiated > 0){
                this.showSampling = true;
            }else{
                this.showSampling = false;
            }
        }).catch(error=>{
            console.error('Error checkIfParentPresent file -->', JSON.stringify(error));
        });
    }

    fetchUserData() {
        getUsersByProfile({ recordId: this.recordId })
            .then((data) => {
                if (data) {
                    console.log('the new data -->',JSON.stringify(data));
                    this.userOptions = [];
    
                    data.forEach((user) => {
                        let fullName = `${user.name} - (${user.accountName})`;
                        //let fullName = user.Employee_ID__c ? `${user.Name} - ${user.Employee_ID__c}` : user.Name;
                        this.userOptions.push({
                            label: fullName, 
                            value: user.userId
                        });
                    });
                } else {
                    this.userOptions = []; 
                }
            })
            .catch((error) => {
                this.error = error;
                console.error('Error fetching user options:', this.error);
            });
    }

    handleSelectedUser(event) {
        this.samplerId = event.detail.value;
        this.samplerName = event.detail.label;
    }
    handleRefreshDataNeg(){
        this.handleRefreshData();
    }

    handleRefreshData(){
        this.spinnerRun = true;
        this.documentsSelected = false;
        this.profileSelected = false;
        this.collateralSelected = false;
        this.vendorLocationSelected=false;

        this.filteredDocuments = [];
        this.applicantsData = [];
        this.collateralData = [];
        this.vendorData=[];

        // this.showSampling = true;
        this.handleRefreshSamplingShow();

        checkIfParentPresent({
            loanId: this.recordId
        }).then(response=>{
            this.isParentCreated = response;

        }).catch(error=>{
            console.error('Error checkIfParentPresent file -->', JSON.stringify(error));
        });

        this.wiredchecklistApplicantData();

    }

    disconnectedCallback() { 
        unregisterAllListeners(this); 
    }

     combineScreeningStatus() {
        if (this.documents.length > 0 && this.documentsScreening.length > 0) {
            this.documents = this.documents.map(doc => {
                const matchingScreening = this.documentsScreening.find(screening => (screening.Content_Document_Id__c === doc.ContentDocumentId));
                if(this.isVendor==false){
                    if(matchingScreening.Applicant__c != null){
                        console.log('matchingScreening are we in here?-->'+ JSON.stringify(matchingScreening));
                        return {
                            ...doc,
                            screeningStatus: matchingScreening ? matchingScreening.Screening_Status__c : null,
                            Name: matchingScreening ? matchingScreening.Name : null,  
                            ownerName:matchingScreening.Applicant__r.First_Name__c +' '+ matchingScreening.Applicant__r.Last_Name__c,
                            docCheckListId: matchingScreening ? matchingScreening.Id : null,
                            requirementLevel: matchingScreening ? matchingScreening.Requirement_Level__c : null,
                            fcuinitiated: matchingScreening ? matchingScreening.FCU_Initiated__c : null,
                            fcuInitiatedStatus: matchingScreening ? matchingScreening.FCU_Initiated__c : null,
                            fcuCompletedStatus:matchingScreening ? matchingScreening.FCU_Triggered__c : null,
                            remarks: matchingScreening ? matchingScreening.Remarks__c : null,
                            referredBy:matchingScreening?matchingScreening.Referred_By__r?.Name:null,
                            referredByRole:matchingScreening?(matchingScreening.Referred_By_Role__c !== undefined ? `(${matchingScreening.Referred_By_Role__c})` : '') : null,
                        };
                    }else{
                        console.log('matchingScreening are we in here1?-->'+ JSON.stringify(matchingScreening));
                        return {
                            ...doc,
                            screeningStatus: matchingScreening ? matchingScreening.Screening_Status__c : null,
                            Name: matchingScreening ? matchingScreening.Name : null,
                            ownerName:null,
                            docCheckListId: matchingScreening ? matchingScreening.Id : null,
                            requirementLevel: matchingScreening ? matchingScreening.Requirement_Level__c : null,
                            fcuinitiated: matchingScreening ? matchingScreening.FCU_Initiated__c : null,
                            fcuInitiatedStatus: matchingScreening ? matchingScreening.FCU_Initiated__c : null,
                            fcuCompletedStatus:matchingScreening ? matchingScreening.FCU_Triggered__c : null,
                            remarks: matchingScreening ? matchingScreening.Remarks__c : null,
                            referredBy:matchingScreening?matchingScreening.Referred_By__r?.Name:null,
                            referredByRole:matchingScreening?(matchingScreening.Referred_By_Role__c !== undefined ? `(${matchingScreening.Referred_By_Role__c})` : '') : null,
                        };
                    }
                }else{
                    console.log('matchingScreening -->'+matchingScreening.Contact__c);
                    if(matchingScreening.Contact__c != null){
                        return {
                            ...doc,
                            screeningStatus: matchingScreening ? matchingScreening.Screening_Status__c : null,
                            Name: matchingScreening ? matchingScreening.Name : null,
                            vendorDetailName: matchingScreening ? matchingScreening.Vendor__r?.Name : null,
                            contactDetailName:matchingScreening ? matchingScreening.Contact__r?.Name : null,
                            ownerName: matchingScreening.Contact__r.Name,
                            docCheckListId: matchingScreening ? matchingScreening.Id : null,
                            requirementLevel: matchingScreening ? matchingScreening.Requirement_Level__c : null,
                            fcuinitiated: matchingScreening ? matchingScreening.FCU_Initiated__c : null,
                            fcuInitiatedStatus: matchingScreening ? matchingScreening.FCU_Initiated__c : null,
                            remarks: matchingScreening ? matchingScreening.Remarks__c : null,
                            // referredBy:matchingScreening?matchingScreening.Referred_By__r.name:null,
                        };
                    }else{
                        return {
                            ...doc,
                            screeningStatus: matchingScreening ? matchingScreening.Screening_Status__c : null,
                            Name: matchingScreening ? matchingScreening.Name : null,
                            vendorDetailName: matchingScreening ? matchingScreening.Vendor__r?.Name : null,
                            contactDetailName:matchingScreening ? matchingScreening.Contact__r?.Name : null,
                            ownerName: matchingScreening.Vendor__r.Name,
                            docCheckListId: matchingScreening ? matchingScreening.Id : null,
                            requirementLevel: matchingScreening ? matchingScreening.Requirement_Level__c : null,
                            fcuinitiated: matchingScreening ? matchingScreening.FCU_Initiated__c : null,
                            fcuInitiatedStatus: matchingScreening ? matchingScreening.FCU_Initiated__c : null,
                            remarks: matchingScreening ? matchingScreening.Remarks__c : null,
                            // referredBy:matchingScreening?matchingScreening.Referred_By__r.name:null,
                        };
                    } 
                }
                
                
            });
            this.handleGetSentForSampling();

            
        }
    }

    handleGetSentForSampling(){
        console.log('here we check the docs -->',this.isInitiatedSamplingScreen);
        console.log('here we check the docs1 -->',JSON.stringify(this.documents));
        try{         
            if(this.isInitiatedSamplingScreen){
                this.filteredDocuments = this.documents.filter(doc => (doc.requirementLevel === 'Application Level' || doc.requirementLevel === 'Applicant Level' || doc.requirementLevel === 'Collateral Level'||doc.requirementLevel === 'Vendor Level'||doc.requirementLevel === 'Contact Level') && (doc.screeningStatus === 'Added to sampling queue' || doc.screeningStatus == 'Recommended For FCU' || doc.screeningStatus == 'Sent Back' || doc.screeningStatus == 'FCU Completed' || doc.screeningStatus == 'Cancelled') && doc.fcuCompletedStatus);
            }
            else{
                this.filteredDocuments = this.documents.filter(doc => (doc.requirementLevel === 'Application Level' || doc.requirementLevel === 'Applicant Level' || doc.requirementLevel === 'Collateral Level'||doc.requirementLevel === 'Vendor Level'||doc.requirementLevel === 'Contact Level') && (doc.screeningStatus === 'Added to sampling queue' || doc.screeningStatus == 'Recommended For FCU' || doc.screeningStatus == 'Sent Back') && !doc.fcuInitiatedStatus);
            }
            console.log('this.filteredDocuments=:'+this.filteredDocuments.length);
            this.filteredDocuments.forEach(doc => {
                console.log('doc.fcuInitiatedStatus=:'+doc.fcuCompletedStatus);
                if(doc.fcuCompletedStatus){
                    console.log('doc.docCheckListId=:'+doc.docCheckListId);
                
                    if( this.parentFCUchildMap != undefined){
                        console.log('doc.docCheckListId=:'+doc.docCheckListId);

                        const parentData = this.parentFCUchildMap[doc.docCheckListId];
                        console.log('parentData=:'+parentData);
                        if(parentData != undefined){
                            doc.fcuId = parentData.fcuId;
                            doc.fcuName = parentData.name;
                            doc.addressValue = parentData.addressValue;
                        }
                    }
                    else{
                        doc.addressValue = 'Local';
                    }
                }else{
                    doc.addressValue = 'Local';
                }
            });

            console.log('this.filteredDocuments -->'+JSON.stringify(this.filteredDocuments));

            console.log(this.filteredDocuments.length);
            console.log('this.fromCollateralTab=:'+this.fromCollateralTab);
            if(this.filteredDocuments.length > 0 && !this.fromCollateralTab){
                this.showDocumentsTable = true;
                if(this.isInitiatedSamplingScreen){
                    this.showSampling = true;
                }
            }else{
                this.showDocumentsTable = false;
                if(this.isInitiatedSamplingScreen){
                    this.showSampling = false;
                }
            }
        }
        catch(error){
            console.log('err=:'+JSON.stringify(error));
        }
    }

    handleselectionChange(event){
        const selectedId = event.target.dataset.id;
           
        if(event.target.checked){
     
            if (this.collateralSelected) {

                event.target.checked = false;
            }
            else{
                this.filteredDocuments.forEach(doc => {
                    if(doc.docCheckListId == event.target.dataset.id){
                        this.selectedRecords[event.target.dataset.id] = doc.addressValue;
                    }
                });
            }
        }else{
            let selectRecId = {};
            Object.keys(this.selectedRecords).map(key => {
                if(key !== selectedId)
                    selectRecId[key] = this.selectedRecords[key];
            });

            this.selectedRecords = {};
            this.selectedRecords = selectRecId;
        }

        if(Object.keys(this.selectedRecords).length > 0){
            this.documentsSelected = true;
        }else{
            this.documentsSelected = false;
        }
        Object.keys(this.selectedRecords).map(key => {
            console.log(`this.selectedRecords --> ${key}`);
            console.log(`this.selectedRecords Value -->`+this.selectedRecords[key]);
        });
        this.checkUncheckSelectAllCheckbox();
    }

    handleVendorDataChange(event){
        console.log(event.target.dataset.id);
        const selectedId = event.target.dataset.id;
    
        if(event.target.checked){
            
                this.vendorData.forEach(vendor => {
                    if(vendor.id == event.target.dataset.id){
                        console.log(event.target.dataset.id);
                        this.selectedRecordsVendorList[event.target.dataset.id] = vendor.addressValue;
                    }
                });
            
        }else{
            let selectRecId = {};
            Object.keys(this.selectedRecordsVendorList).map(key => {
                if(key !== selectedId)
                    selectRecId[key] = this.selectedRecordsVendorList[key];
            });

            this.selectedRecordsVendorList = {};
            this.selectedRecordsVendorList = selectRecId;
        }

        if(Object.keys(this.selectedRecordsVendorList).length > 0){
            this.vendorLocationSelected = true;
        }else{
            this.vendorLocationSelected = false;
        }
        console.log(`this.selectedRecordsVendorList List -->`+JSON.stringify(this.selectedRecordsVendorList));
        Object.keys(this.selectedRecordsVendorList).map(key => {
            console.log(`this.selectedRecordsVendorList --> ${key}`);
            console.log(`this.selectedRecordsVendorList Value -->`+this.selectedRecordsVendorList[key]);
            
        });
    }

     
    handleselectionChangeApplicant(event){
        if(this.isVendor==false){
 
            const selectedId = event.target.dataset.id;
            if(event.target.checked){ 
               
            if (this.collateralSelected) {
                // If Collateral is checked, immediately deselect the Applicant checkbox
                event.target.checked = false;
            }
            else{
                this.applicantsData.forEach(addr => {
                    if(addr.id == event.target.dataset.id){
                        console.log(event.target.dataset.id);
                        this.selectedRecordsApplicant[event.target.dataset.id] = addr.addressValue;
                    }
                });
            }
                
            }else{
                let selectRecId = {};
                Object.keys(this.selectedRecordsApplicant).map(key => {
                    if(key !== selectedId)
                        selectRecId[key] = this.selectedRecordsApplicant[key];
                });

                this.selectedRecordsApplicant = selectRecId;
            }

            if(Object.keys(this.selectedRecordsApplicant).length > 0){
                this.profileSelected = true;
            }else{
                this.profileSelected = false;
            }
        }else{
            // console.log(event.target.dataset.id);
            const selectedId = event.target.dataset.id;
            if(event.target.checked){ 
                
            if (this.collateralSelected) {

                event.target.checked = false;
            }
            else{
                this.applicantsData.forEach(addr => {
                    if(addr.id == event.target.dataset.id){
                        console.log(event.target.dataset.id);
                        this.selectedRecordsApplicant[event.target.dataset.id] = addr.addressValue;
                    }
                });
            }
                
            }else{
                let selectRecId = {};
                Object.keys(this.selectedRecordsApplicant).map(key => {
                    if(key !== selectedId)
                        selectRecId[key] = this.selectedRecordsApplicant[key];
                });

                this.selectedRecordsApplicant = selectRecId;
            }

            if(Object.keys(this.selectedRecordsApplicant).length > 0){
                this.profileSelected = true;
            }else{
                this.profileSelected = false;
            }
        }
        this.checkUncheckSelectAllCheckbox();
    }

    checkUncheckSelectAllCheckbox(){
        this.template.querySelector('[data-checkbox-type="selectAllCheckbox"]').checked = 
                        Object.keys(this.selectedRecordsApplicant).length == Object.keys(this.applicantsData).length &&
                        Object.keys(this.selectedRecords).length == Object.keys(this.filteredDocuments).length ?
                        true : false;
    }

    handleSelectAllCheckbox(event){
        var documentAllCheckboxes = this.template.querySelectorAll('[data-checkbox-type="documentsCheckbox"]');
        var profileAllCheckboxes = this.template.querySelectorAll('[data-checkbox-type="profileCheckbox"]');
        if(event.target.checked && !this.collateralSelected){
            let profCounter = 0;
            let docCounter = 0;

            this.applicantsData.forEach(addr => {
                    this.selectedRecordsApplicant[addr.id] = addr.addressValue;
                    profileAllCheckboxes[profCounter].checked = true;
                    profCounter++;
            });
            
            this.filteredDocuments.forEach(doc => {
                this.selectedRecords[doc.docCheckListId] = doc.addressValue;
                documentAllCheckboxes[docCounter].checked = true;
                docCounter++;
            });
            this.documentsSelected = Object.keys(this.selectedRecords).length >0;
            this.profileSelected = Object.keys(this.selectedRecordsApplicant).length > 0;
        }else{
            let docCounter = 0;
            let profCounter = 0;
            this.selectedRecordsApplicant = {};
            this.selectedRecords = {};

            this.applicantsData.forEach(addr => {
                    profileAllCheckboxes[profCounter].checked = false;
                    profCounter++;
            });
            
            this.filteredDocuments.forEach(doc => {
                documentAllCheckboxes[docCounter].checked = false;
                docCounter++;
            });
            this.documentsSelected = false;
            this.profileSelected = false;
            this.template.querySelector('[data-checkbox-type="selectAllCheckbox"]').checked = false;
        }
        

    }

    handleselectionChangeApplicantionCollateral(event) {
        const selectedId = event.target.dataset.id;
        const isChecked = event.target.checked;
    
        // Find all checkboxes in the collateral table
        const allCheckboxes = this.template.querySelectorAll('.collateral-checkbox');
    
        if (isChecked) {
            // If the checkbox is checked, deselect all others in the collateral table
            allCheckboxes.forEach((checkbox) => {
                if (checkbox.dataset.id !== selectedId) {
                    checkbox.checked = false;
                }
            });
    
            // Deselect other checkboxes in other tables
            this.deselectOtherCheckboxes('applicant');
            this.deselectOtherCheckboxes('documents');
    
            // Update the selected record with the currently checked checkbox
            this.collateralData.forEach(coll => {
                if (coll.id === selectedId) {
                    this.selectedRecordApplicationCollateral = { [selectedId]: coll.addressValue };
                }
            });
    
            this.collateralSelected = true;
        } else {
            // If the checkbox is unchecked, remove the entry from selectedRecordApplicationCollateral
            const selectRecId = {};
            Object.keys(this.selectedRecordApplicationCollateral).forEach(key => {
                if (key !== selectedId) {
                    selectRecId[key] = this.selectedRecordApplicationCollateral[key];
                }
            });
    
            this.selectedRecordApplicationCollateral = selectRecId;
    
            // Update collateralSelected based on whether selectedRecordApplicationCollateral is empty
            this.collateralSelected = Object.keys(this.selectedRecordApplicationCollateral).length > 0;
        }
    
        // Log the selected records for debugging
        Object.keys(this.selectedRecordApplicationCollateral).forEach(key => {
            console.log(`this.selectedRecordApplicationCollateral --> ${key}`);
            console.log(`this.selectedRecordApplicationCollateral Value -->` + this.selectedRecordApplicationCollateral[key]);
        });
    }
    deselectOtherCheckboxes(type) {
        console.log('inside deselectOtherCheckboxes:: ');
        let checkboxes;
        
        if (type === 'applicant') {
            // Deselect all checkboxes in the Applicant table
            console.log('inside deselectOtherCheckboxes applicant:: ');
            checkboxes = this.template.querySelectorAll('.applicant-checkbox');
        } else if (type === 'collateral') {
            // Deselect all checkboxes in the Collateral table
            checkboxes = this.template.querySelectorAll('.collateral-checkbox');
        } else if (type === 'documents'){
            // Deselect all checkboxes in the Other table
            checkboxes = this.template.querySelectorAll('.documents-checkbox');
        }
        
        checkboxes.forEach(checkbox => {
            checkbox.checked = false;  // Deselect the checkbox
        });
    }
    isCheckboxChecked(type) {
        let checkbox;
    
        if (type === 'applicant') {
            checkbox = this.template.querySelector('.applicant-checkbox');
        } else if (type === 'collateral') {
            checkbox = this.template.querySelector('.collateral-checkbox');
        } else {
            checkbox = this.template.querySelector('.documents-checkbox');
        }

        console.log('checkbox -->'+JSON.stringify(checkbox));
    
        return checkbox ? checkbox.checked : false;
    }

    showWarningToast() {
        const evt = new ShowToastEvent({
            title: 'Warning',
            message: 'Selecting a record in Collateral Sampling will deselect any other selected records.',
            variant: 'warning',
        });
        this.dispatchEvent(evt); // Dispatch the event to show the toast
    }

    handlelookupselected(event){
        // console.log(JSON.stringify(event.detail));
        this.samplerId = event.detail.id;
        this.samplerName = event.detail.name;
    }
    handlelookupdeselected(event){
        // console.log(JSON.stringify(event.detail));
        this.samplerId = event.detail.id;
        this.samplerName = event.detail.name;
    }

    handleremarksChange(event){
        // console.log('remarksValue event.target.value:: '+event.target.value);
        this.remarksValue = event.target.value;
    }

    handleUpload(){

    }
    handleUploadFinished(event){
        console.log('handleUploadFinished');
        const documentId = event.detail.files[0].documentId;
        const dataId = event.target.dataset.id; 
        this.uploadedDocumentsMap[dataId] = documentId;
        //this.getDocumentDetails(documentId);
        console.log('Uploaded Documents Map:', this.uploadedDocumentsMap);
    }
   
    handleAddressTypeChange(event){
        if(event.target.dataset.name == 'document'){
            if(this.selectedRecords[event.target.dataset.id] != null && this.selectedRecords[event.target.dataset.id] != '' && this.selectedRecords[event.target.dataset.id] != undefined){
                this.selectedRecords[event.target.dataset.id] = event.target.value;
            }
            this.filteredDocuments.forEach(doc => {
                if(doc.docCheckListId == event.target.dataset.id){
                    doc.addressValue = event.target.value;
                }
            });
        }
        if(event.target.dataset.name == 'profile'){
            if(this.selectedRecordsApplicant[event.target.dataset.id] != null && this.selectedRecordsApplicant[event.target.dataset.id] != '' && this.selectedRecordsApplicant[event.target.dataset.id] != undefined){
                this.selectedRecordsApplicant[event.target.dataset.id] = event.target.value;
            }
            this.applicantsData.forEach(addr => {
                if(addr.id == event.target.dataset.id){
                    addr.addressValue = event.target.value;
                }
            });
        }
        if(event.target.dataset.name == 'collateral'){
            if(this.selectedRecordApplicationCollateral[event.target.dataset.id] != null && this.selectedRecordApplicationCollateral[event.target.dataset.id] != '' && this.selectedRecordApplicationCollateral[event.target.dataset.id] != undefined){
                this.selectedRecordApplicationCollateral[event.target.dataset.id] = event.target.value;
            }
            this.collateralData.forEach(addr => {
                if(addr.id == event.target.dataset.id){
                    addr.addressValue = event.target.value;
                }
            });
        }
        if(event.target.dataset.name == 'vendor'){
            if(this.selectedRecordsVendorList[event.target.dataset.id] != null && this.selectedRecordsVendorList[event.target.dataset.id] != '' && this.selectedRecordsVendorList[event.target.dataset.id] != undefined){
                this.selectedRecordsVendorList[event.target.dataset.id] = event.target.value;
            }
            this.vendorData.forEach(addr => {
                if(addr.id == event.target.dataset.id){
                    addr.addressValue = event.target.value;
                }
            });
        }
    }

    handleUploadFiles(){
        this.template.querySelector('.hidden-input').click();
    }

    handlePrevious(){
        this.modalVisibility = false;
        this.showgenericConfirm = true;
    }

    handlePositive(){
        this.showgenericConfirm = true;
        const valueCloseEvent = new CustomEvent('previous', {});
        this.dispatchEvent(valueCloseEvent);
    }
    handleNegative(){
        this.modalVisibility = true;
        this.showgenericConfirm = false;
    }

    closeModal(){
        this.modalVisibility = false;
        const valueCloseEvent = new CustomEvent('closeshowdoc', {});
        this.dispatchEvent(valueCloseEvent);
    }

    get enableSamplerSelect(){
        return (this.documentsSelected) || (this.profileSelected) || (this.collateralSelected)||(this.vendorLocationSelected);
    }

    get eneableSampleButton(){
        return this.enableSamplerSelect && this.samplerId != '' && this.samplerId != null;
    }

    handleSample(){
      
            initiateFCU({
                docIds: this.selectedRecords,
                profileIds: this.selectedRecordsApplicant,
                selectedRecordsVendorList:this.selectedRecordsVendorList,
                samplerId: this.samplerId,
                remarks: this.remarksValue,
                loanId: this.recordId,
                flag: this.isParentCreated,
                newdocmap: this.uploadedDocumentsMap
            }).then(response=>{
                console.log('response-->',response);
                if (response.includes('Success')) {
                    this.showToastMessage('Success', 'FCU updated successfully!', 'success');
                } else if (response.includes('Generic')) {
                    this.showToastMessage('Error', 'FCU could not be inititated','error');
                } else if (response.includes('LoanStatus')) {
                    this.showToastMessage('Error', 'FCU could not be inititated , loan status not correct','error');
                }

                fireEvent(this.pageRef, "inititedFCUrefreshdata", "inititedFCUrefreshdata");
                this.savedSampler = undefined;
                this.remarksValue = '';
                this.selectedRecords = {};
                this.selectedRecordsApplicant = {};
                this.selectedRecordApplicationCollateral = {};
                this.isParentCreated = true;
                this.documentsSelected = false;
                this.profileSelected = false;
                this.collateralSelected = false;
                this.selectedRecordsVendorList={};
                
                this.handleRefreshData();
                const valueCloseEvent = new CustomEvent('updatecount', {});
                this.dispatchEvent(valueCloseEvent);

                /*Added to refresh the Initiate FCU tab */
                this.getObjectName();
                this.fetchUserData();
                
            }).catch(error=>{
                console.error('Error handleSample file -->', JSON.stringify(error));
            });
      //  }
        
    }

    navigateToRecord(event) {
        const pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.dataset.id,
                objectApiName: 'Application_Verification__c',
                actionName: 'view'
            }
        };
        this[NavigationMixin.Navigate](pageReference);
    }

    showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(toastEvent);
    }

    handleRemoveFromSamplingQueue(){
        console.log('this.selectedRecords=:'+JSON.stringify(this.selectedRecords));
        console.log('this.selectedRecordsApplicant=:'+JSON.stringify(this.selectedRecordsApplicant));
        console.log('this.selectedRecordApplicationCollateral=:'+JSON.stringify(this.selectedRecordApplicationCollateral));
        if(Object.keys(this.selectedRecords).length === 0 && Object.keys(this.selectedRecordsApplicant).length === 0 && Object.keys(this.selectedRecordApplicationCollateral).length === 0){
            this.showToastMessage('Error','Please select atleast one record','error');
        }
        else{
                removeFromSamplingQueue({
                    docIds: this.selectedRecords,
                    profileIds: this.selectedRecordsApplicant,
                    applicationCollateralIds: this.selectedRecordApplicationCollateral
                }).then(response=>{
                    if(response==true){
                        this.showToastMessage('Error','Items recommended by credit can not be removed from the queue. Please contact with credit to recall them.','error');   
                    }
                    else{
                    this.showToastMessage('Success','Removed from queue successfully','success');
                    fireEvent(this.pageRef, "inititedFCUrefreshdata", "inititedFCUrefreshdata");
                    this.savedSampler = undefined;
                    this.remarksValue = '';
                    this.selectedRecords = {};
                    this.selectedRecordsApplicant = {};
                    this.selectedRecordApplicationCollateral = {};
                    this.isParentCreated = true;
                    this.documentsSelected = false;
                    this.profileSelected = false;
                    this.collateralSelected = false;
                    this.handleRefreshData();
                    }
                }).catch(error=>{
                    console.error('Error removeFromSamplingQueue file -->', JSON.stringify(error));
                })
               
    }

}
@track isRendered = false;
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
        .fcu-table .slds-form-element__label, span.slds-file-selector__text.slds-medium-show{
            display: none;
        }
        .fcu-table span.slds-file-selector__button.slds-button.slds-button_neutral{
            font-size: 0px;
        }
        .fcu-table svg.slds-button__icon.slds-button__icon_left{
            margin: 0px;
        }
        .fcu-table lightning-primitive-file-droppable-zone.slds-file-selector__dropzone{
            border: none;
        }



        `;

        // Append the styles to the .styleContainer
        this.template.querySelector('.styleContainer')?.appendChild(style);

        // Prevent re-adding styles
        this.isRendered = true;
    }
}
}