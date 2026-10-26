import { LightningElement,api,track, wire } from 'lwc';
import getLegalRecordTypes from '@salesforce/apex/Hl_LegalRecordPageController.getLegalRecordTypes';
//import sendEmailByUserId from '@salesforce/apex/LegalRecordPageController.sendEmailByUserId';
import fetchCollateral from '@salesforce/apex/Hl_LegalRecordPageController.fetchCollateral';
import getLegalUsers from '@salesforce/apex/Utility.getLegalUsers';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createLegalRecord from '@salesforce/apex/Hl_LegalRecordPageController.createLegalRecord';
//import deleteLegalDocument from '@salesforce/apex/Hl_LegalRecordPageController.deleteLegalDocument';
import { deleteRecord,updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from "lightning/navigation";
import setDocumentBasedOnRecord from '@salesforce/apex/GenericDocumentInitiateController.setDocumentBasedOnRecord';
import setDocument from '@salesforce/apex/GenericDocumentInitiateController.setDocument';
import insertFileRecord from '@salesforce/apex/GenericDocumentInitiateController.insertFileRecord';
import getLegalRecords from '@salesforce/apex/Hl_LegalRecordPageController.getLegalRecords';
//import checkLegalValidationInitiation from '@salesforce/apex/Utility.checkLegalValidationInitiation';
//import uploadFile from '@salesforce/apex/Utility.uploadFile';
//import checkVisibility from '@salesforce/apex/Utility.checkVisibility';
import getMorgateDocuments from '@salesforce/apex/Hl_LegalRecordPageController.getMorgateDocuments';
import insertDocumentCheckList from '@salesforce/apex/GenericInitiateController.insertDocumentCheckList';
import deleteDocumentsWithFiles from '@salesforce/apex/COMM_TechnicalRecordPageController.deleteDocumentsWithFiles';
/*import deleteContent from '@salesforce/apex/GenericDocumentInitiateController.deleteContent';
import resetDocData from '@salesforce/apex/UploadDocumentsController.resetDocData';*/
import { CloseActionScreenEvent } from 'lightning/actions';
import FORM_FACTOR from '@salesforce/client/formFactor';
//HL
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import deleteLegalDocuments from  '@salesforce/apex/GenericDocumentInitiateController.deleteLegalDocuments';
//HL

export default class Hl_InitiateLegalChild extends NavigationMixin(LightningElement) {
    formFactor = FORM_FACTOR;
    deviceType;
    @api recordId ;
    @track disableLoanReject = false;
    
    @track showModal = false;
    @track options =[];
    @track selectedValue;
    @track selectedValueCollateral;
    @track optionsList =[];
    @track optionsListCollateral = [];
    @track value;
    @track checkLoan;
    @track spin = false;
    @track legalIdToPass;
    @api genericInitiate
    @track documents = []
    @track selectedAddress = '';
    currentDocId;
    currentIndex;

    @track spinnerRun = false;
    @track legalSearchReportYears = false;
    @track optionsLegalYears =[];
    @track selectedLegalYears;
    @track oldCollateralIdForDeletion;//updated Ayushi

    // @track showMorgateDocTable = false;
    @track allMorgateDocuments = [];
    @track allSelectedMorgate = [];

    @track showDocTable = false;
    mappedName;
    showConfirmDocModal = false;
    showConfirmModal = false;
    //HL
    product
    showHLRelatedData = false;
    assigneeMap = {}; 
   @track isDisableAssignee=false;
    //HL

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


    @api progressStep ={
        step1 : false,
        step2 : false,
        step3 : false,
        step4 : false,
        step5 : false
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
            return 'progress-bar-mobile;';
        }
        return 'progress-bar';
    }

    get progressStages() {
        return [
            { key: 'step1', label: 'Select Type of Evaluation', completed: this.progressStep?.step1, showLine : true, sequence: 1 },
            { key: 'step2', label: 'Select Related Collateral', completed: this.progressStep?.step2, showLine : true, sequence: 2 },
            { key: 'step3', label: 'Select Assignee', completed: this.progressStep?.step3, showLine : true, sequence: 3 },
            { key: 'step4', label: 'Upload Documents', completed: this.progressStep?.step4, showLine : true, sequence: 4 },
            { key: 'step5', label: 'Initiate Report', completed: this.progressStep?.step5, showLine : true, sequence: 5 }
        ];
    }

    showLegalTable = false
    @track legals = []
    isCollateralSelected = false;

    allowProceedInitiation = false;
    currentDocId;
    @track uploadedFiles=[];

    connectedCallback(){
        if(this.showHLRelatedData){
            this.setDocList();
        }
        this.getLegalRecord();
        this.fetchCollateral();
        this.getLegalUser();
        this.setLegalRecords();
        setTimeout(() => {
            this.setLegalRecords();
        }, 500);//updated-Ayushi
        /*setInterval(() => {
            this.setLegalRecords();
        }, 1000);*/
        this.showModal = !this.genericInitiate;
        this.fetchLegalSearchYears();
        /* Commented out - Utility.checkVisibility does not exist in Utility.cls,
           which blocked deployment of this component. */
        // checkVisibility({
        //     recordId: this.recordId,
        //     fromLoan: true,
        //     objectName: 'Legal'
        // })
        // .then(response => {
        //     this.disableLoanReject = response;
        // })
        // .catch(error => {
        //     console.log(error);
        // });
        //HL
        this.getProductDetails();
        //HL
    }

    
    groupLegalsByCollateral(records) {
        const grouped = {};

        records.forEach((rec) => {
            if(!rec.collateralType) return;
            const collateral = rec.collateralType;

            if (!grouped[collateral]) {
                grouped[collateral] = [];
            }

            grouped[collateral].push(rec);
        });

        this.groupedLegals = Object.keys(grouped).map(collateral => {
            const group = grouped[collateral];

            return {
                collateral,
                rowspan: group.length,
                records: group.map((r, i) => ({
                    ...r,
                    srno: i + 1, //  reset srno for each collateral
                    isFirst: i === 0,
                    styleClass: i === 0 
                    ? 'padding-left:20px; margin-left:3px;border-left: 1px solid #d8dde6;'
                    : 'padding-left:20px; border-left: 1px solid #d8dde6;'
                }))
            };
        });

        this.showLegalTable = this.groupedLegals.length > 0;
    }

    setDocList(){
    console.log('Record ID:', this.recordId);
    console.log('name (this.value):', this.value);
    console.log('Collateral ID In setDocList:', this.selectedValueCollateral);
    if (this.value === 'Legal_Scrutiny_Report') {
        this.mappedName = 'Legal Scrutiny Document';
    } else if (this.value === 'Legal_Search_Report') {
        this.mappedName = 'Legal Search Document';
    } else if (this.value === 'Legal_Vetting_Report') {
        this.mappedName = 'Legal Vetting Document';
    } else if (this.value === 'Legal_Scrutiny_Report_With_Title_Search') {
        this.mappedName = 'Legal Scrutiny Report With Title Search';}
    console.log('Mapped name for Apex:', this.mappedName);
        setDocument({
            recordId: this.recordId,
            name:this.mappedName,
            applicationColl:this.selectedValueCollateral
        })
        .then(response => {
            this.documents = response;
            console.log('Documents####');
            
            if(this.documents.length > 0){
                this.showDocTable = true;
            }else{
                this.showDocTable = false;
            }
            console.log('The Value is : '+response);
        })
        .catch(error => {
            console.log(error);
        });
    }
    
    insertFileRecordToSalesforce(file) {
        this.spinnerRun = true;
        insertFileRecord({
            fileContentDocumentId: file.documentId,
            recordId: this.currentDocId, // Associate with the specific record
            loanAppId: this.recordId//HL_Ayushi-15/10
        })
        .then(() => {
            this.spinnerRun = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'File uploaded and associated with record!',
                    variant: 'success',
                }),
            );
            this.progressStep.step4 = true;
            this.setDocList();
        })
        .catch((error) => {
            this.spinnerRun = false;
        });
    }

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg'];
    }

    handleFileChange(event) {
        const files = event.detail.files;
        console.log('No. of files uploaded : ' + JSON.stringify(files));
        const recordId = event.target.dataset.id;
        this.currentDocId = recordId;
        files.forEach(file => {
            // For each uploaded file, create an object with necessary details
            this.uploadedFiles.push({
                id: file.documentId,
                name: file.name,
                downloadUrl: file.downloadUrl
            });
        });

        const allowedExtensions = this.acceptedFormats.map(ext => ext.replace('.', '').toLowerCase());
        for (let file of files) {
            const extension = file.name.split('.').pop().toLowerCase();
            if (!allowedExtensions.includes(extension)) {
                this.showToast(`Invalid file type: ${extension}. Allowed types are ${this.acceptedFormats.join(', ')}`, 'error');
                return;
            }
        }

        for(var i=0;i<files.length;i++){
            this.insertFileRecordToSalesforce(files[i]);
        }
    }
    resetData(event){
        this.spinnerRun = true;
        resetDocData({
            docId:event.target.dataset.id
        }).then(response=>{
            this.spinnerRun = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'File deleted successfully',
                    variant: 'success',
                }),
            );
            this.setDocList();
        }).catch(error=>{
            this.spinnerRun = false;
        })
    }
    handlePreview(event){
        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: event.target.dataset.id
            }
        })
    }

    fetchMorgateDoc(){
        getMorgateDocuments({
            recordId: this.recordId,
            applicationCollateral: this.selectedValueCollateral
        })
        .then(response => {
            this.allMorgateDocuments = response;
            this.allMorgateDocuments.forEach(record =>{
                if(record.Content_Document_Id__c != null && record.Content_Document_Id__c != '' && record.Content_Document_Id__c != undefined){
                    record.isUploaded = true;
                }else{
                    record.isUploaded = false;
                }
            });
        })
        .catch(error => {
            console.log(error);
        });
    }
    
    getLegalUser(){
        getLegalUsers({ loanId: this.recordId , type : 'Legal'})
        .then(result => {
            let items = [];
                for (let key in result) {
                    items.push({ label: result[key], value: key  });
                }
            this.options = JSON.parse(JSON.stringify(items))
        })
        .catch(error => {
            console.error('Error fetching legal users:', error);
        });
    }
    
    getLegalRecord(){
        getLegalRecordTypes({ loanId: this.recordId })
            .then(result => {
                let groupValues = [];
                for (let key in result) {
                    groupValues.push({ label: key, value: result[key] });
                }
                this.optionsList = JSON.parse(JSON.stringify(groupValues));
                this.optionsList.sort((a, b) => {
                    if (a.label < b.label) return -1;
                    if (a.label > b.label) return 1;
                    return 0;
                });
                //console.log('optionList--', JSON.stringify(this.optionsList));
            })
            .catch(error => {
                console.error('Error fetching legal record types:', error);
            });
    }

    fetchCollateral() {
        fetchCollateral({ loanId: this.recordId })
            .then(result => {
                //console.log('fetchCollateral result : ',result);
                let groupValuesCollateral = [];
                for (let key in result) {
                    groupValuesCollateral.push({ label: result[key], value: key });
                }
                this.optionsListCollateral = JSON.parse(JSON.stringify(groupValuesCollateral));
                //console.log('optionListCollateral -- ', this.optionsListCollateral);
                //console.log('optionListCollateral.length -- ', this.optionsListCollateral.length);
            })
            .catch(error => {
                console.error('Error fetching collateral:', error);
            });
    }

    fetchLegalSearchYears(){
        let startValue = 1;
        let endValue = 30;
        let groupValuesYearList = [];
        groupValuesYearList.push({ label: '30+', value: '30+' });
        groupValuesYearList.push({ label: '13', value: '13' });
        groupValuesYearList.push({ label: '30', value: '30' });
        for (let i = startValue; i <= endValue; i++) {
            // groupValuesYearList.push({ label: i.toString(), value: i.toString() });
            if (i === 13 || i === 30) {
                continue; // Skip 13 and 30 since they are already added
            }
            groupValuesYearList.push({ label: i.toString(), value: i.toString() });
        }
        this.optionsLegalYears = JSON.parse(JSON.stringify(groupValuesYearList));
        //console.log('this.optionsLegalYears --> '+JSON.stringify(this.optionsLegalYears));

    }

    closeModal() {
        this.showModal = false;
    }

    openAddDocModal = false;
    openDocumentModal(){
        this.openAddDocModal = true;
    }

    closeDocumentModal(){
        this.openAddDocModal = false;
    }

    resetDocuments(){
        console.log(`Record ID:`, this.recordId);
        console.log(`name (this.value):`, this.value);   
        console.log(`Collateral ID:`, this.selectedValueCollateral);
    if (this.value === 'Legal_Scrutiny_Report') {
        this.mappedName = 'Legal Scrutiny Document';
    } else if (this.value === 'Legal_Search_Report') {
        this.mappedName = 'Legal Search Document';
    } else if (this.value === 'Legal_Vetting_Report') {
        this.mappedName = 'Legal Vetting Document';
    } else if (this.value === 'Legal_Scrutiny_Report_With_Title_Search') {
        this.mappedName = 'Legal Scrutiny Report With Title Search';}
             
        setDocument({
            recordId: this.recordId,
            name: this.mappedName,
            applicationColl:this.selectedValueCollateral
        })
        .then(response => {
            //console.log('response from reset',response);
            this.documents = response;
            this.closeDocumentModal();
            this.openTable = true;
            //console.log('length',this.documents.length,this.documents);
            if(this.documents.length > 0){
                this.showDocTable = true;
            }else{
                this.showDocTable = false;
            }
        })
        .catch(error => {
            console.log(error);
        });
    }

    closeAction(){
        this.showConfirmModal = true;
        //this.dispatchEvent(new CloseActionScreenEvent());
    }

    closeConfirmModal(){
         this.showConfirmModal = false;
    }

    confirmCloseAction(){
        this.showModal = false;
        this.dispatchEvent(new CustomEvent('close',{}));

    }

    createLegalNonVetCase() {
        if(!this.selectedValue){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please update the Fields',
                    variant: 'error',
                }),
            );
            return;
        }
        if(this.genericInitiate){
            for(let index =0;index <this.documents.length;index++){
                if(this.documents[index].isUploaded){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please upload All Legal Documents',
                            variant: 'error',
                        }),
                    );
                    return;
                }else{
                    // this.createLegalRecordData();
                    // this.sendMailToAssignee();
                }
            }
            // return;
        }
        this.createLegalRecordData();
        // this.sendMailToAssignee();
        //this.legalIdToPass
    }

    handleMortgagteselecteion(event){
        if(event.target.checked){
            this.allSelectedMorgate.push(event.target.dataset.id);
        }else{
            var tempIds = [];
            this.allSelectedMorgate.forEach(record => {
                if(record != event.target.dataset.id){
                    tempIds.push(record);
                }
            });
            this.allSelectedMorgate = tempIds;
        }
    }

    createLegal() {
        //--->confirmed by Suchitra that there will be no validations to the initiation of reports on each other
        if (!this.validateInputs()) {
            return;
        }
        this.createLegalRecordData();
    }

    validateInputs() {
        if (!this.selectedValue) {
            this.showToast('Error', 'Please update the Fields', 'error');
            return false;
        }

        if (this.genericInitiate) {
            for(let index =0;index <this.documents.length;index++){
                if(this.documents[index].isUploaded){
                    this.showToast( 'Error','Please upload All Legal Documents','error')
                    return false;
                }
            }
        }

        return true;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
    
    handleSelectedValue(event) {
        this.selectedValue = event.target.value;
        //console.log('SelectedValue::', this.selectedValue);
        this.progressStep.step3 = true;
        this.isUserSelected = true;
        //console.log(this.documents.length);
         console.log('this.selectedValue>>>>>',this.selectedValue);
           console.log('this.selectedValueCollateral>>>>>',this.selectedValueCollateral);
         if (this.selectedValueCollateral) {
        this.assigneeMap[this.selectedValueCollateral] = this.selectedValue;
        }
        if(this.documents.length>0){this.progressStep.step4 = true;}
        if(this.showHLRelatedData){
            this.resetDocuments();
        }
    }
    handleselectedValueCollateral(event){
        //console.log('optionsListCollateral -->'+JSON.stringify(this.optionsListCollateral));
        //console.log('this.selectedValueCollateral -->'+event.target.value);
       this.selectedAddress = this.optionsListCollateral.find(f => f.value == event.target.value).label;
        const selectedCollateral = event.target.value;
        if(this.selectedValueCollateral && selectedCollateral != this.selectedValueCollateral){
            this.oldCollateralIdForDeletion = this.selectedValueCollateral;//updated Ayushi
            this.showConfirmDocModal = true;
        }
        this.selectedValueCollateral = selectedCollateral;
        this.progressStep.step2 = true;
        this.isCollateralSelected = true;
        if(this.selectedValueCollateral && this.selectedValueCollateral != selectedCollateral){
            this.selectedValue = '';
            this.isUserSelected = false;
             this.isDisableAssignee=false;
        }
        console.log('this.assigneeMap>>>>>',this.assigneeMap);
         console.log('this.selectedCollateral>>>>>',selectedCollateral);
        if (this.assigneeMap[selectedCollateral]) {
            console.log('this.this.assigneeMap[selectedCollateral]>>>>>',this.assigneeMap[selectedCollateral].id);
            this.selectedValue = this.assigneeMap[selectedCollateral].id;
             console.log('this.selectedValue>>>>>',this.selectedValue);
            this.isUserSelected = true;
            //this.isDisableAssignee=true;
            this.isDisableAssignee=false;//updated
            // updated-Ayushi
        if(this.showHLRelatedData) {
            this.resetDocuments(); 
        }
        } else {
            this.selectedValue = '';
            this.isUserSelected = false;
            this.isDisableAssignee=false;
        }
       this.fetchMorgateDoc();
        console.log('this.selectedValue222>>>>>',this.selectedValue);
    }

    closeConfirmDocModal(){
        this.showConfirmDocModal = false;
    }

    /*confirmDocDeletion(){
            
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
    }*/
    //updated Ayushi
    async confirmDocDeletion() {
    this.spinnerRun = true;
    const deletionPromises = [];
    
    // Get the mapped report type name [cite: 223-226]
    let mappedName = '';
    if (this.value === 'Legal_Scrutiny_Report') {
        mappedName = 'Legal Scrutiny Document';
    } else if (this.value === 'Legal_Search_Report') {
        mappedName = 'Legal Search Document';
    } else if (this.value === 'Legal_Vetting_Report') {
        mappedName = 'Legal Vetting Document';
    } else if (this.value === 'Legal_Scrutiny_Report_With_Title_Search') {
        mappedName = 'Legal Scrutiny Report With Title Search';
    }

    // Loop through all documents in the table and create a deletion promise for each
    this.documents.forEach(doc => {
        const inputMap = {
            'documentId': doc.docId,
            'reportType': mappedName,
            'collateralId': this.oldCollateralIdForDeletion // <-- Use the stored OLD ID
        };
        // Add the correct Apex call to the list of promises
        deletionPromises.push(deleteLegalDocuments({ inputMap: inputMap }));
    });

    try {
        // Wait for all "soft-delete" or "hard-delete" operations to complete
        await Promise.all(deletionPromises);

        this.showSuccessToast('Documents cleared successfully');
        this.showConfirmDocModal = false;
        this.openTable = false;
        this.documents = []; // Clear the table
        this.spinnerRun = false;
        this.oldCollateralIdForDeletion = null; // Clear the temp ID
        this.resetDocuments();
    } catch (error) {
        this.spinnerRun = false;
        this.oldCollateralIdForDeletion = null; // Clear the temp ID
        this.showErrorToast('Deletion failed: ' + (error.body ? error.body.message : error.message));
    }
}
//end updated
    
    handleValueChange(event){
        const valuationType = event.target.value;
        if(this.value && this.value != valuationType){
            this.showConfirmDocModal = true;
        }
        this.value = event.target.value;
        //console.log('this.value --> '+this.value);
        if(event.target.value){ //to handle in case combobox value changes
            this.selectedValueCollateral = '';
            this.isCollateralSelected = false;
            this.isUserSelected = false;
            this.selectedValue = '';
            this.progressStep.step2 = false;
            this.progressStep.step3 = false;
            this.progressStep.step4 = false;
        }
        this.documents = [];
        if (this.value == 'Legal_Search_Report' || this.value == 'Legal_Scrutiny_Report_With_Title_Search') {
            //console.log('Legal_Search_Report Selected');
            this.legalSearchReportYears = true;
            if (this.selectedLegalYears !=null) {
                this.progressStep.step1 = true;
                this.checkLoan = true;
            } else {
                this.progressStep.step1 = false;
                this.checkLoan = false;
            }
        }
        else {
            this.progressStep.step1 = true;
            this.checkLoan = true;
            this.legalSearchReportYears = false;
        } 
        
        setDocumentBasedOnRecord({
            recordId: this.recordId,
            name:this.value,
            recordName:this.value
        })
        .then(response => {
            this.documents = response;
            if(this.documents.length > 0){
                this.showDocTable = true;
            }else{
                this.showDocTable = false;
            }
            //console.log('The Value is setDocumentBasedOnRecord: '+response);
        })
        .catch(error => {
            console.log(error);
        });
    }

    // get showMorgateDocTable(){
    //     return this.value == 'Legal_Vetting_Report' && this.allMorgateDocuments.length > 0;
    // }

    handleselectedLegalYears(event) {
        this.selectedLegalYears = event.target.value;
        this.progressStep.step1 = true;
        this.checkLoan = true;
    }
    // this is most probably a mail to vendor >>>>check 
    // sendMailToAssignee() {
    //     sendEmailByUserId({ userId: this.selectedValue, recordId: this.legalIdToPass })
    //         .then(() => {
    //             this.showToastMessage('Success', 'Email sent successfully!', 'success', 'dismissible');
    //         })
    //         .catch(error => {
    //             this.showToastMessage('Error', error.body.message, 'Error', 'dismissible');
    //         });
    // }

    /*handleDocumentCreation(event){ //park it for now created this to fetch from child components and insert doc detail later
        const documentObj = event.detail;
        insertDocumentCheckList({documentObj})
        .then(response=>{
            console.log('response from doc creation',response);
                    this.resetDocuments();
                }).catch(error=>{
                    console.error(error)
                })
    }*/

    // Add this new function updated-Ayushi
handleDocumentsAdded(event) {
    const newlyCreatedDocs = event.detail; // Get the docs from the modal

    if (!newlyCreatedDocs || newlyCreatedDocs.length === 0) {
        this.closeDocumentModal();
        return;
    }

    // Manually build the wrapper for the new docs
    const newDocWrappers = newlyCreatedDocs.map((newDoc, i) => ({
        srno: this.documents.length + i + 1,
        docId: newDoc.Id,
        contentId: null, // It's new, so no content ID
        docName: newDoc.Name,
        isUploaded: true, // It's new
        isUploadNeeded: false, // It needs an upload
        uploadedFiles: [],
        isRequired: false
        // Add any other properties your table needs
    }));

    // Add the new documents to the *existing* list
    this.documents = [...this.documents, ...newDocWrappers];

    // If this is the first document, show the table
    if (!this.showDocTable) {
        this.showDocTable = true;
    }

    // We don't need this, the modal closes itself. 
    // You can also have the modal dispatch 'closemodal'
    // this.closeDocumentModal(); 
}//end updated

    //this.value have to set
    createLegalRecordData() {
        this.spinnerRun = true;
        //console.log('selectedValue Id : ', this.selectedValue);
        var recordTypeValue = this.value;
        //console.log('Selected collateral is : ', this.selectedValueCollateral);
        if (!recordTypeValue || recordTypeValue == null || typeof recordTypeValue == 'undefined') {
            this.showToastMessage('Error', 'Please Select Evaluation Type', 'Error', 'dismissible');
            this.spin = false;
            this.spinnerRun = false;
            return;
        }
        //console.log('this.value createLegalRecordData--> '+this.value);
        //console.log('this.allSelectedMorgate -->'+JSON.stringify(this.allSelectedMorgate));
        
        const legalDetailsObj = {
            loanId: this.recordId,
            ownerId: this.selectedValue,
            recordType: this.value,
            applicationCollateral: this.selectedValueCollateral,
            collateralAddress: this.selectedAddress,
            legalYears: this.selectedLegalYears,
            docCategory: this.mappedName,
            documentIds: this.documents.map(doc => doc.docId)//updated-Ayushi
        };
        console.log(JSON.stringify(legalDetailsObj));

        createLegalRecord({createLegalWrapperString: JSON.stringify(legalDetailsObj), vettingReportList: this.allSelectedMorgate})
        .then(result => {
            console.log('Result: ', result);
            this.spinnerRun = false;
            this.setLegalRecords();

            if (result.startsWith('Success')) {
                //console.log('The result string starts with "Success"');
                let successString = 'Success';
            
                let legalRecordId = result.substring(successString.length).trim();
                this.legalIdToPass = legalRecordId;
                //console.log('Success String:', successString);
                //console.log('Record ID:', legalRecordId);
                this.progressStep.step5 = true;
                this.showToastMessage('Success', 'Legal Initiated Successfully', 'Success');
            } else if (result === 'fail') {
                this.spin = false;
                this.showToastMessage('Error', 'Please select a collateral before initiating Legal Report', 'Error');
            } else if (result === 'legalRecords') {
                this.spin = false;
                this.showToastMessage('Error', 'You have already initiated a Scrutiny Report for the selected collateral.', 'Error');
            } else if (result === 'docUploadBt') {
                this.spin = false;
                this.showToastMessage('Error', 'Please upload Foreclosure letter and Original List Of Documents (LOD) to initiate BT Transaction Report.', 'Error');
            } else if (result === 'auditProfile') {
                this.spin = false;
                this.showToastMessage('Error', 'You are not allowed to create legal report.', 'Error');
            }/* else if(result === 'lsrlegalRecords not initiated'){ >> removing this as not required
                this.spin = false;
                this.showToastMessage('Error', 'Please initate a Legal Scrutiny report for this collateral to initiate vetting/search report.', 'Error');
            }*/
            else if(result.includes('Legal already exists!')){
                this.showToastMessage('Error', 'Legal already initiated for this collateral. Please initate for a different one.', 'Error');
            }
            else {
                this.showToastMessage('Error', result, 'Error');
                this.showModal = false;
                this.spin = false;
            }
            this.showDocTable = false; //adding this to remove iniitate button in case status goes to failure
            setDocument({
                recordId: this.recordId,
                name:this.value,
                applicationColl:this.selectedValueCollateral
            })
            .then(response => {
                this.documents = response;
                if(this.documents.length > 0){
                    this.showDocTable = true;
                }else{
                    this.showDocTable = false;
                }
            })
            .catch(error => {
                console.log(error);
            });
            this.progressStep.step1 = false;
            this.progressStep.step2 = false;
            this.progressStep.step3 = false;
            this.progressStep.step4 = false;
            this.progressStep.step5 = false;
            this.value = '';
            this.checkLoan = false;
            this.selectedValueCollateral = '';
            this.isCollateralSelected = false;
            this.selectedValue = '';
            this.isUserSelected = false;
            this.legalSearchReportYears = false;
            this.selectedLegalYears = '';
            this.allMorgateDocuments = [];
            this.allSelectedMorgate = [];
            //HL
            if(this.showHLRelatedData){
                const valueChangeEvent = new CustomEvent("getlegalrecords", {
                    detail: { value: this.recordId }
                    });
                this.dispatchEvent(valueChangeEvent);
            }
             //HL
           
            //this.dispatchEvent(new CustomEvent('close',{}));
        })
        .catch(error => {
            this.showToastMessage('Error', error.body, 'Error');
            this.showModal = false;
            this.spin = false;
            this.spinnerRun = false;
        });
    }

    navigateToRecord(event) {
        window.open(`/${event.currentTarget.dataset.id}`, '_blank');
    }

    setLegalRecords(){
        getLegalRecords({recordId : this.recordId}).then(response =>{
            this.groupLegalsByCollateral(response);
            /*if(this.progressStep.step4){this.progressStep.step5 = true;}
            this.legals = response;
            //console.log('legal records',response);
            
            if(this.legals.length>0){
                this.showLegalTable = true;
            }
            this.getLegalUser();*/
            console.log('legal records',response);
            this.assigneeMap = {};
            response.forEach(legal => {
                if (legal.collateralId && legal.assignedTo) {
                    this.assigneeMap[legal.collateralId] = {
                        id: legal.assignedToId,
                        name: legal.assignedTo
                    };
                }
            });

            console.log('Assignee Map:', JSON.stringify(this.assigneeMap));
        }).catch(error=>{
            console.error(error)
        })
    }

    showToastMessage(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }

    viewDocument(evt){
        let contentId = evt.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: contentId
            }
        })
    }
    
    handleUpload(evt){
        const file = evt.target.files[0]
        var reader = new FileReader()
        reader.onloadend = async () => {
            const base64Data = reader.result.split(',')[1]; // Extract base64 data
            const fileName = file.name;
            const fileType = file.type;
            /* Commented out - Utility.uploadFile does not exist in Utility.cls,
               which blocked deployment of this component. */
            // const result = await uploadFile({ base64Data, fileName, fileType });
            // this.updateContentId(result);
        }
        reader.readAsDataURL(file)

    }

    updateContentId(value){
        const fields = {};
        fields['Id'] = this.currentDocId;
        fields['Content_Document_Id__c'] = value;

        const recordInput = { fields };
        updateRecord(recordInput)
        .then(() => {
            if(this.currentIndex != null && this.currentIndex != '' && this.currentIndex != undefined){
                this.documents[this.currentIndex].isUploaded = false;
                this.documents[this.currentIndex].contentId = value;
                this.progressStep.step4 = true;
            }else{
                this.allMorgateDocuments.forEach(record => {
                    if(record.Id == this.currentDocId){
                        record.isUploaded = true;
                        record.Content_Document_Id__c = value;
                    }
                });
            }

            this.showToastMessage('Success', 'Document uploaded successfully!', 'Success');
            
            this.template.querySelector('.genericFileUpload').value = null;
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
    }

    uploadDocument(evt){
        this.currentDocId = evt.currentTarget.dataset.id;
        this.currentIndex = evt.currentTarget.dataset.index;
        this.template.querySelector('.genericFileUpload2').click();
    }

    handleDelete() {
    deleteRecord(this.recordId)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Document record deleted successfully',
                    variant: 'success'
                })
            );
            // Optionally, fire event or refresh data
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error deleting record',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
}

    deleteCheckList(evt){
        let currentId = evt.currentTarget.dataset.id;
        let index = evt.currentTarget.dataset.index;
        console.log(`The Record Id : ${currentId}`)
        
         if(this.showHLRelatedData){
            const inputMap = {
                'recordId': this.recordId,
                'documentId': evt.currentTarget.dataset.id,
                'reportType': this.mappedName, // updated-Ayushi
                'collateralId': this.selectedValueCollateral//updated-Ayushi
            }
           deleteLegalDocuments({
              inputMap : inputMap
            })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Document record deleted successfully',
                        variant: 'success'
                    })
                );
                this.setDocList();
                // Optionally, fire event or refresh data
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error deleting record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            }); 
        }
        else{
            deleteRecord(currentId)
            .then(() => {
            if(this.documents.length==1){
                    this.documents = [];
                    this.openTable = false;
                    this.showDocTable = false; //adding this to remove the header of doc table
                    this.progressStep.step4 = false;
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
        }
        //using standard uiRecordApi now
        /*deleteDocumentCheckList({recordId : currentId}).then(response=>{
                if(this.documents.length==1){
                    this.documents = [];
                    this.openTable = false;
                    this.showDocTable = false; //adding this to remove the header of doc table
                    this.progressStep.step4 = false;
                }else{
                    this.documents.splice(index, 1);
                    //console.log(`The Serialize Value : ${JSON.stringify(this.documents)}`)
                    for(let indexF = 0;indexF<this.documents.length;indexF++){
                        this.documents[indexF].srno = indexF + 1
                    }
                }
            this.showToastMessage('Success', 'Document deleted successfully!', 'Success');
        }).catch(error=>{
            this.showToastMessage('Error', 'Document cannot be deleted as it was uploaded by another user', 'error');
            console.error(error)
        })*/
    }

    deleteDocument(evt){
        let currentId = evt.currentTarget.dataset.id;
        let curIndex = evt.currentTarget.dataset.index;
        //console.log('currentId -->'+currentId);
        deleteContent({contentId: currentId,recordId: this.recordId})
        .then(response => {
            if(curIndex != null && curIndex != '' && curIndex != undefined){
                this.documents[curIndex].isReqired = false;
                this.documents[curIndex].isUploaded = true;
            }else{
                this.allMorgateDocuments.forEach(record => {
                    if(record.Content_Document_Id__c == currentId){
                        record.isUploaded = false;
                        record.Content_Document_Id__c = null;
                    }
                });
            }
            this.showToastMessage('Success', 'Document deleted successfully!', 'Success');

        }).catch(error => {
            console.log(error)
        })
    }
    //HL
    getProductDetails(){
        const inputMap = {
            'oppId': this.recordId
        };
        getProductDetails({inputMap: inputMap})
        .then(response => {
            this.product = response.loanProduct;
            console.log('Product Details: '+JSON.stringify(this.productDetails));
            if(this.product == 'Home Loan'){
                this.showHLRelatedData = true;
            }
        })
        .catch(error => {
            console.log(error);
        });
    }
}