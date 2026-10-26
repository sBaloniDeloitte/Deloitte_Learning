import { LightningElement,api,track,wire } from 'lwc';
import getCustomerList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getCustomerList';
import checkDocumentChecklistCreated from '@salesforce/apex/COMM_DocumentDetailsScreenController.checkDocumentChecklistCreated';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createChecklist from '@salesforce/apex/COMM_DocumentDetailsScreenController.createChecklist';
import removeDocumentDetailsFromCompletionStage from '@salesforce/apex/COMM_SalesLoanLoginController.removeDocumentDetailsFromCompletionStage';
import checkMasterData from '@salesforce/apex/SalesLoanLoginIntegrationDetailsCheck.checkMasterData';
import getIntegrationDetails from '@salesforce/apex/SalesLoanLoginIntegrationDetailsCheck.getIntegrationDetails';
import validateMandatoryFields  from '@salesforce/apex/SalesDocumentValidationChecklist.validateMandatoryFields';
import validateConsideredDocs from '@salesforce/apex/SalesDocumentValidationChecklist.validateConsideredDocs';
import callDedupe from '@salesforce/apex/COMM_SalesLoanLoginController.callDedupeAPI';
import validateMandatoryDocuments from '@salesforce/apex/SalesDocumentValidationChecklist.validateMandatoryDocuments';
import getClassAndMethodName from '@salesforce/apex/SalesLoanLoginIntegrationDetailsCheck.getClassAndMethodName';
import getApplicants from '@salesforce/apex/COMM_DocumentDetailsScreenController.getApplicantsWithType';
import FORM_FACTOR from '@salesforce/client/formFactor';
import checkExceptionStatus from '@salesforce/apex/COMM_SalesLoanLoginController.checkExceptionStatus';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import updateDocumentCompletion from '@salesforce/apex/COMM_SalesLoanLoginController.updateDocumentCompletion';
//HL-Ishi-24-09
import checkCustomerDedupe from '@salesforce/apex/SalesCustomerDedupeController.checkCustomerDedupe' 	
import validateAddressLines from '@salesforce/apex/SalesDocumentValidationChecklist.validateAddresses';
import deleteWithoutAddressTypeDoc from '@salesforce/apex/SalesDocumentValidationChecklist.deleteWithoutAddressTypeDoc';
import checkAddressType from '@salesforce/apex/SalesDocumentValidationChecklist.checkAddressType'
//HL-Ishi-24-09

export default class SalesAllDocumentsLoan extends LightningElement {


@api recordId;
applicantPickValOptions = [];
@track openSections = [];
loanapplication = 'Application';
loan = true;
notloan = false;
modalVisibility = false;
loandocument = false;
@api loginChecklist;
@track allChecklist = [];
@track selectedChecklistData = [];
@track createdNewDocTable = [];
@track selectedApplicantId =[];
@track applicantDocument=false;
@track modalAPIVisibility=false;
@track defaultApplicantId;
nsave = false;
openAccordian= false;
isloading = false;
requirementFilter='';
processObject = 'Sales add document';
@track data = [];
showDedupeDetails= false;
showIntegrationData = false;
applicantsForDedupeList = [];
@wire(CurrentPageReference) pageRef;
showDedupeSpinner = false;
isRendered= false;
groupedDocs = [];
showMissingDocs= false;
errorfield;
showMissingFields= false;
applicantType;
errorModal;
@track errorLst = [];
errorModalAddressMissing=false;
errorLstAddressMissing=[];

    connectedCallback(){
        console.log('recordId '+this.recordId);
        console.log('loginChecklist in document---', this.loginChecklist);
        this.getAllApplicants();
        this.checkUserProfile();
        this.getApplicants();
        this.isloading = true;
        setTimeout(() => {
        this.isloading = false;
        }, 5000);
        registerListener("handleRefreshDocument", this.getDoccheckImageUploadedstatus, this);
    }

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

    getAllApplicants(){
        getCustomerList({loanId: this.recordId })
        .then(response=>{
            console.log('getCustomerList response----'+JSON.stringify(response));
            this.applicantPickValOptions = response.filter(applicant => applicant.value !== 'All');
            if(this.loginChecklist){
                console.log('at 34 document');
                
                this.openSections = [...this.applicantPickValOptions.map(section => section.value), 'Application'];
                if(this.openSections){
                    this.openAccordian = true;
                }
            }
            console.log('this.openSections in documentss---', JSON.stringify(this.openSections));
            
            console.log('Filtered Response:', JSON.stringify(this.applicantPickValOptions));
            if (this.applicantPickValOptions && this.applicantPickValOptions.length > 0) {
                this.defaultApplicantId = this.applicantPickValOptions[0].value; // or however your list is structured
            }
        }).catch(error=>{
            console.error('error getCustomerList --> '+JSON.stringify(error));
        })
    }

    addDocument(event){
        console.log('event.detail.applicantId in accordian click---',  event.target.dataset.applicantId);
        
        this.selectedApplicantId=  event.target.dataset.applicantId;
        console.log('addDocument event---'+event);
        const applicantId = event.target.dataset.applicantId;
        if(applicantId){
            this.applicantDocument= true;
            this.loandocument=false;
            this.requirementFilter = '[Requirement_At__c = Applicant Level]';
        }else{
            this.loandocument=true;
            this.applicantDocument= false;
            this.requirementFilter = '[Requirement_At__c = 	Loan Application]';
        }
        console.log('Clicked Add Document for Applicant ID:', applicantId);
        this.modalVisibility = true;
    }
    handleSelectDocument(event){
        event.stopPropagation();
        this.selectedId = event.detail.searchRecord.Id;
        console.log('this.selectedId -->'+this.selectedId);
        console.log('this.101 -->'+ event.detail.searchRecord.Id);
        console.log('recordId -->'+ this.recordId);
        if(this.loandocument){
            checkDocumentChecklistCreated({docMasterId :  this.selectedId , loanId: this.recordId})
            .then((response) => {
             if(response){
                this.showToastMessage('Warning','Document Checklist already created','warning');
                this.template.querySelector('c-search-lookup').handleReset(event);
             }
            })
        }
    }
    handleClose(event){
        event.stopPropagation();
        if(this.nsave){
            this.applicantPickValOptions = null;
            this.modalVisibility = false;
            this.connectedCallback();
        }
        else{
            this.modalVisibility = false;
        }
    }
    handleldeselectDocument(event){
        event.stopPropagation();
        this.selectedId = '';
        this.allChecklist = [];
}
    showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(toastEvent);
    }
    handlesave(event){
        event.stopPropagation();
        console.log('selectedId '+this.selectedId);
        this.selectedChecklistData.push(this.selectedApplicantId);
        console.log('selectedChecklistData '+this.selectedChecklistData);
        console.log('loanId '+this.recordId);
            createChecklist({docMasterId : this.selectedId, userIds : this.selectedChecklistData, loanId : this.recordId, processName: 'Sales'})
            .then((result) => {
                this.showToastMessage('Success', 'New documents added successfully.', 'success');
                // this.fetchSanctions();
                // this.handleClose();
                console.log('result '+result);
                this.nsave = true;
                this.createdNewDocTable = result;
                this.template.querySelector('c-search-lookup').handleReset(event);
                console.log('this.createdNewDocTable -->'+JSON.stringify(this.createdNewDocTable));
                this.allChecklist = [];
                this.selectedId = '';
                this.selectedChecklistData = [];
                this.selectedApplicantId = '';
            })
            .catch((error) => {
                console.error('Error getAllSanctionCheckList --> ', JSON.stringify(error));
            });  
    }
    get createdRecordsVisibility(){
        return this.createdNewDocTable.length>0;
    }
    handleaccordianClick(event){
        event.stopPropagation();
    }
    reload(event){
        this.applicantPickValOptions = null;
        this.connectedCallback();
    }
    getDoccheckImageUploadedstatus(event){
        console.log('132');
        this.modalVisibility = false;
        this.createdNewDocTable.length = 0;
        this.modalVisibility = true;
    }
    nextButton(event){
        console.log('in next buttonnnn');
        this.isFieldDisable = false;
        //this.handleValidationsCheck();
        this.deleteWithoutAddressTypeDoc();
        //this.validateDocuments();
     }
     deleteWithoutAddressTypeDoc(){
         deleteWithoutAddressTypeDoc({
            recordId: this.recordId
        })
            .then(result => {
                console.log('result: ' + JSON.stringify(result));
                this.validateDocuments();
            })
            .catch(error => {
                console.log('error: ' + JSON.stringify(error));
            });
    }
    
     
    // nextButton(event){
    //     console.log('in next buttonnnn');
    //     if(this.showDedupeDetails ){
    //         this.callDedupe();
    //     }
    //     else{
    //         const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
    //             detail: {
    //                 loanId: this.recordId,
    //                 screenName: 'Document Details',
    //                 //applicantId:this.selectedRecordId
    //             }
    //         });
    //         this.dispatchEvent(valueSelectedEvent);

    //     }
    
    // validateDocuments(){
    //     console.log('Inside document')
    //     validateMandatoryDocuments({
    //         recordId:this.recordId
    //     })
    //     .then(result => {
    //         console.log('Inside result 195',JSON.stringify(result));
    //         if(result != null && result != undefined && result.length>0){
    //             this.showMissingDocs = true;
    //             this.groupedDocs = result;
    //             return removeDocumentDetailsFromCompletionStage({ recordId: this.recordId })
    //             .then(() => {
    //                 console.log('Removed Document Details from multi-picklist');
    //             })
    //             .catch(error => {
    //                 console.error('Error updating picklist:', error);
    //             })
    //             .finally(() => { this.isFieldDisable = false; });
    //         }
    //         else{
    //             // this.callDedupe();
    //             // console.log('in next buttonnnn');
    //             // this.updateCompletionStage();
    //             return this.validateMandatoryFields();
              
    //         }
    //         // let map = new Map();

    //         // result.forEach(item => {
    //         //     if (!map.has(item.applicantName)) {
    //         //         map.set(item.applicantName, []);
    //         //     }
    //         //     map.get(item.applicantName).push(item.documentType);
    //         // });

    //         // this.groupedDocs = Array.from(map, ([applicant, documents]) => ({
    //         //     applicant,
    //         //     documents
    //         // }));
    //         // console.log('Inside result 209', this.groupedDocs );
    //         // if(this.groupedDocs.length>0){
    //         //     this.showMissingDocs =  true;
    //         // }
    //         // else{
    //         //     this.callDedupe();
    //         //     console.log('in next buttonnnn');
    //         //     this.updateCompletionStage();
                
    //         //     // else{
    //         //     //     console.log('in next buttonnnn');
    //         //     //     this.modalAPIVisibility= true;
    //         //     // }
    //         // }
    //     })
    //     .catch(error => {
    //         console.error('Error loading missing documents:', error);
    //         console.log('in next buttonnnn');
    //         //this.updateCompletionStage();
    //         this.isFieldDisable = false;
    //         // else{
    //         //     console.log('in next buttonnnn');
    //         //     this.modalAPIVisibility= true;
    //         // }
    //     });

      
    // }


    validateDocuments() {
        console.log('Inside document')
        validateMandatoryDocuments({
            recordId: this.recordId
        })
        .then(result => {
            console.log('Inside result 195', JSON.stringify(result));
            if (result != null && result != undefined && result.length > 0) {
                this.showMissingDocs = true;
                this.groupedDocs = result;
                removeDocumentDetailsFromCompletionStage({ recordId: this.recordId })
                    .then(() => {
                        console.log('Removed Document Details from multi-picklist');
                    })
                    .catch(error => {
                        console.error('Error updating picklist:', error);
                    })
            } else {
                this.checkAddressType();
                //this.validateMandatoryFields();
            }
        })
        .catch(error => {
            console.error('Error loading missing documents:', error);
            console.log('in next buttonnnn');
            this.updateCompletionStage();
        });
    }
    
    updateCompletionStage(){
        return updateDocumentCompletion({loanId: this.recordId})
        .then(res => {
            const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
                detail: {
                    loanId: this.recordId,
                    screenName: 'Document Details',
                    //applicantId:this.selectedRecordId
                }
            });
            this.dispatchEvent(valueSelectedEvent);
            return res;
        })
        .catch(error => {
            console.error('updateDocumentChecklist error -->' + JSON.stringify(error));
            throw error;
        });
    }
    handleCloseDoc(){
        this.showMissingDocs =  false;
    }
    loadDocsForAll() {
    getDocs({ recordId: this.recordId })
      .then(docs => {
        this.groupByApplicantAndCategory(docs);
      });
    }
    groupByApplicantAndCategory(docs) {
        this.documentsByApplicant = {}; // reset
        docs.forEach(doc => {
        const aid = doc.Applicant__c;
        if (!this.documentsByApplicant[aid]) {
            // initialize each category to empty array
            this.documentsByApplicant[aid] = this.categories.reduce((m,c) => {
            m[c.key] = []; return m;
            }, {});
        }
        const cat = this.pickCategory(doc);
        this.documentsByApplicant[aid][cat].push(doc);
        });
    }
    pickCategory(doc) {
    // you can change this logic to read a field on the doc record
        const t = doc.MasterCategory__c;
        if (/poi/i.test(t))   return 'POI';
        if (/poa/i.test(t))   return 'POA';
        if (/por/i.test(t))   return 'POR';
        return 'Others';
    }
    // navToNext() {
    //     this.handleValidationsCheck();
    // }

    //  handleValidationsCheck() {
    //     checkMasterData({ loanId: this.recordId })
    //     .then(result => {
    //          let filteredData = result.filter(record => record.viewWrapper === true);

    //         filteredData.forEach(record => {
    //              record.applicantWrappers = record.applicantWrappers?.filter(applicant => applicant.viewApplicant === true) || [];
    //          });

    //         let masterDataNames = filteredData.map(record => record.activityName);
    //         let applicantIds = new Set();

    //         filteredData.forEach(record => {
    //             record.applicantWrappers.forEach(applicant => {
    //                 applicantIds.add(applicant.applicantId);
    //             });
    //         });

    //         if (filteredData.length > 0) {
    //             console.log('Fetched Data:', JSON.stringify(filteredData));
    //             this.showIntegrationData = true;
                
    //             this.fetchIntegrationDetails(filteredData, masterDataNames, Array.from(applicantIds));
    //         } else {
    //             this.showIntegrationData = false;
    //             this.data = [];
    //             console.log('Inside cmp----',this.recordId)
    //             const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
    //                             detail: {
    //                                 loanId: this.recordId,
    //                                 screenName: 'Document Details',
    //                                 //applicantId:this.selectedRecordId
    //                             }
    //                         });
    //                         this.dispatchEvent(valueSelectedEvent);
    //         // else{
    //         //     console.log('in next buttonnnn');
    //         //     this.modalAPIVisibility= true;
    //         // }
    //                     }

      
    // }
       
    // }

    // navToNext() {
    //     this.handleValidationsCheck();
    // }

    handleValidationsCheck() {
        checkMasterData({ loanId: this.recordId })
        .then(result => {
            console.log('handleValidationsCheck:', 'result:', JSON.stringify(result), 'this.recordId:', this.recordId);
            let filteredData = result; 
            if(this.applicantType == 'Individual' || this.applicantType == 'Salaried'){
                filteredData = result.filter(record => record.activityName != 'Loan PAN To CIN');
            }
           // let filteredData = result.filter(record => record.viewWrapper === true);
            console.log(
                'handleValidationsCheck:',
                JSON.stringify(filteredData));
            // //filteredData.forEach(record => {
            //     record.applicantWrappers = record.applicantWrappers?.filter(applicant => applicant.viewApplicant === true) || [];
            // });

            let masterDataNames = filteredData.map(record => record.activityName);
            let applicantIds = new Set();

            filteredData.forEach(record => {
                record.applicantWrappers.forEach(applicant => {
                    applicantIds.add(applicant.applicantId);
                });
            });

            if (filteredData.length > 0) {
                console.log('Fetched Data:', JSON.stringify(filteredData));
                this.showIntegrationData = true;
                
                this.fetchIntegrationDetails(filteredData, masterDataNames, Array.from(applicantIds));
            } else {
                this.showIntegrationData = false;
                this.data = [];
                console.log('Inside cmp----',this.recordId)
                const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
                    detail: {
                        loanId: this.recordId,
                        screenName: 'Document Details',
                        //applicantId:this.selectedRecordId
                    }
                });
                this.dispatchEvent(valueSelectedEvent);
            }
            /* this.dispatchEvent(new CustomEvent('navigatetonexttab', {
                detail: true
            }));*/
        })
        .catch(error => {
            console.error('Error fetching master data:', error);
            this.data = [];
        });
    }


    fetchIntegrationDetails(filteredData, masterDataNames, applicantIds) {
        console.log('filteredData:', JSON.stringify(filteredData));
        console.log('masterDataNames:', JSON.stringify(masterDataNames));
        console.log('applicantIds:', JSON.stringify(applicantIds));
    
        getIntegrationDetails({ masterDataNames: masterDataNames, loanId: this.recordId, applicantIds: applicantIds })
        .then(integrationResults => {
            console.log('integrationResults:', JSON.stringify(integrationResults));
    
            // Create a map of success entries by Related_Record_Id__c
            let successMap = new Map();
            integrationResults.forEach(rec => {
                if (!successMap.has(rec.Related_Record_Id__c)) {
                    successMap.set(rec.Related_Record_Id__c, []);
                }
                successMap.get(rec.Related_Record_Id__c).push({
                    isSuccess: rec.Is_Success_Response__c,
                    activityName: rec.Name
                });
            });
    
            // Process filteredData
            this.data = filteredData.map(record => {
                let updatedApplicants = record.applicantWrappers.length > 0 
                    ? record.applicantWrappers.map((applicant, index) => {
                        let successEntries = successMap.get(applicant.applicantId) || [];
    
                        // Find a matching success entry based on activityName
                        let matchedEntry = successEntries.find(entry => entry.activityName === record.activityName);
    
                        return {
                            ...applicant,
                            isSuccess: matchedEntry ? matchedEntry.isSuccess : false,
                            isFirst: index === 0
                        };
                    })
                    : [{
                        applicantId: 'N/A',
                        applicantName: 'API is based on Loan Level Data.',
                        applicantType: '',
                        isSuccess: false,
                        isFirst: true
                    }];
                
                return {
                    ...record,
                    isSuccess: updatedApplicants.some(applicant => applicant.isSuccess), // Wrapper level success check
                    applicantWrappers: updatedApplicants
                };
            });
    
            if (this.data) {
                // this.modalAPIVisibility= true;
                const hasFailures = this.data.some(record => !record.isSuccess);
                const allSuccess = this.data.every(record => record.isSuccess);

                if (allSuccess) {
                    this.showToastMessage('Success', 'All integrations were successful.', 'success');
                    this.modalAPIVisibility= false;
                    const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
                        detail: {
                            loanId: this.recordId,
                            screenName: 'Document Details',
                            //applicantId:this.selectedRecordId
                        }
                    });
                    this.dispatchEvent(valueSelectedEvent);
                } else if (hasFailures) {
                    this.modalAPIVisibility= false;
                    this.showToastMessage('Warning', 'Some integrations failed. Please check the results.', 'warning');
                    if (!this.integrationCalled) {
                         this.callApi();
                    }
                    /*const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
                        detail: {
                            loanId: this.recordId,
                            screenName: 'Document Details',
                            //applicantId:this.selectedRecordId
                        }
                    });
                    this.dispatchEvent(valueSelectedEvent);*/
                }
            }else{
                console.log('Inside cmp----',this.recordId)
                const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
                    detail: {
                        loanId: this.recordId,
                        screenName: 'Document Details',
                        //applicantId:this.selectedRecordId
                    }
                });
                this.dispatchEvent(valueSelectedEvent);
            }
    
            console.log('Updated Data with isSuccess:', JSON.stringify(this.data));
             this.dispatchEvent(new CustomEvent('navigatetonexttab', {
                detail: 'Collateral'
            }));
        })
        .catch(error => {
            console.error('Error fetching integration details:', error);
            this.data = filteredData.map(record => ({
                ...record,
                isSuccess: false,
                applicantWrappers: record.applicantWrappers.length > 0
                    ? record.applicantWrappers.map((applicant, index) => ({
                        ...applicant,
                        isSuccess: false,
                        isFirst: index === 0
                    }))
                    : [{
                        applicantId: 'N/A',
                        applicantName: 'No Applicant Available',
                        applicantType: '',
                        isSuccess: false,
                        isFirst: true
                    }]
            }));
        });
    }

    handleCloseAPI(){
        this.modalAPIVisibility= false;
    }

    updateApplicantsDedupe(event) {
        const newId = event.detail.value;
        console.log('344 Ishioo-----', newId);
        console.log('applicantsForDedupeList--- 355--',this.applicantsForDedupeList);
        // Check if ID already exists
        if (!this.applicantsForDedupeList.includes(newId)) {
            console.log('applicantsForDedupeList--- 358-',this.applicantsForDedupeList);
            this.applicantsForDedupeList.push(newId);
            console.log('applicantsForDedupeList--- 360--',this.applicantsForDedupeList);
            if(this.applicantsForDedupeList.length>0){
                this.showDedupeDetails=true;
                console.log(' this.showDedupeDetails--- 360--',this.showDedupeDetails);
            }
        } 
    }
    // callDedupe() {
    //     this.showDedupeSpinner =true;
    //     let completed = 0;

    //     this.applicantsForDedupeList.forEach(applicantId => {
    //         callDedupe({ applicantId:applicantId ,loanId:this.recordId})
    //             .then(result => {
                  
    //                 console.log(`Dedupe success for applicantId: ${applicantId}`, result);
    //                 completed++;
    //                 if (completed === this.applicantsForDedupeList.length) {
    //                     this.showDedupeSpinner =false;
    //                     this.modalAPIVisibility = true;
    //                 }
    //             })
    //             .catch(error => {
    //                 console.error(`Error in dedupe for applicantId: ${applicantId}`, error);
    //                 completed++;
    //                 if (completed === this.applicantsForDedupeList.length) {
    //                     this.showDedupeSpinner =false;
    //                     this.modalAPIVisibility = true;
    //                 }
    //             });
    //     });
    // }
    callApi() {
            if (!this.data || this.data.length === 0) {
                console.warn('No data available for API call.');
                return;
            }
            console.log('Inside callApi');
        
            this.isLoading = true;
            let promises = [];
        
            let recordsToProcess = this.data.filter(record => 
                record.applicantWrappers.some(applicant => !applicant.isSuccess)
            );
            console.log('recordsToProcess', JSON.stringify(recordsToProcess));
            if (recordsToProcess.length === 0) {
                console.log('No records found with unsuccessful applicants. Skipping API calls.');
                this.isLoading = false;
                return;
            }
        
            recordsToProcess.forEach(record => {
                if (record.applicantWrappers.length > 0) {
                    record.applicantWrappers.forEach(applicant => {
                        if (!applicant.isSuccess) { // Call API only if isSuccess is false
                            console.log(`Calling API for masterId: ${record.masterDataId}, activityName: ${record.activityName}, applicantId: ${applicant.applicantId}`);
                           /* tasks.push(() => {
                            return getClassAndMethodName({
                                masterId: record.masterDataId,
                                loanId: this.recordId,
                                apiName: record.activityName,
                                appId: applicant.applicantId
                                 });
                             });*/
            
                            let promise = getClassAndMethodName({
                                masterId: record.masterDataId,
                                loanId: this.recordId,
                                apiName: record.activityName,
                                appId: applicant.applicantId
                            })
                            .then(result => {
                                console.log(`Result for ${record.masterDataId} - ${applicant.applicantId} -Activity Name ${record.activityName}:`, result);
                            })
                            .catch(error => {
                                console.error(`Error for ${record.masterDataId} - ${applicant.applicantId} -Activity Name ${record.activityName}:`, error);
                            });
        
                            promises.push(promise);
                        }
                    });
                } else {
                    // Loan level API calls where no applicant is present
                    console.log(`Calling API for Loan Level masterId: ${record.masterDataId}, activityName: ${record.activityName}`);
        
                    let promise = getClassAndMethodName({
                        masterId: record.masterDataId,
                        loanId: this.recordId,
                        apiName: record.activityName,
                        appId: null
                    })
                    .then(result => {
                        console.log(`Result for ${record.masterDataId} (Loan level API):`, result);
                    })
                    .catch(error => {
                        console.error(`Error for ${record.masterDataId} (Loan level API):`, error);
                    });
        
                    promises.push(promise);
                }
            });
        
            Promise.all(promises)
                .then(() => {
                    console.log('All API calls completed. Refreshing data...');
                    this.handleValidationsCheck();
                    this.integrationCalled = true;
                })
                .finally(() => {
                    this.isLoading = false;
                });
        }
//         callApi() {
//             this.isLoading = true;

//             getSortedApiMetadata()
//             .then((metadataList) => {
//             const tasks = [];

//             metadataList.forEach((meta) => {
//             // Wrap each API call as a deferred task
//                 tasks.push(() => {
//                 return getClassAndMethodName({
//                 className: meta.Class_Name__c,
//                 methodName: meta.Method_Name__c,
//                 masterId: this.masterId,
//                 loanId: this.recordId,
//                 activityName: meta.API_Name__c
//                 });
//                 });
//             });

//             return this.executeApiBatches(tasks, 2); // execute 2 at a time
//             })
//             .then(() => {
//             console.log('API batch execution completed.');
//             this.handleValidationCheck();
//             this.integrationCallDone = true;
//             this.isLoading = false;
//             })
//             .catch((error) => {
//             console.error('Error during API batch execution:', error);
//             this.isLoading = false;
//             });
// }

// async executeApiBatches(allTasks, batchSize) {
//         let successfulCalls = 0;

//         for (let i = 0; i < allTasks.length; i += batchSize) {
//         const currentBatch = allTasks.slice(i, i + batchSize);
//         const batchPromises = currentBatch.map((task) => task());

//         try {
//         const results = await Promise.allSettled(batchPromises);

//         results.forEach((res, idx) => {
//         if (res.status === 'fulfilled' && res.value?.status === 'SUCCESS') {
//         successfulCalls++;
//         console.log(`API Call Success [Batch ${i / batchSize + 1}]`);
//         } else {
//         console.warn(`API Call Failed [Batch ${i / batchSize + 1}]`, res.reason || res.value);
//         }
//         });

//         if (successfulCalls >= 2) {
//         console.log('✅ Two successful API calls completed. Halting further calls.');
//         break;
//         }

//         } catch (err) {
//         console.error('Unexpected error during batch:', err);
//         // Continue to next batch even if something goes wrong
//         }
//     }
// }

    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            const style = document.createElement('style');
            style.innerText = `
            .uploadFile .slds-file-selector__text.slds-medium-show {
              display: none;
          }
          .uploadFile .slds-file-selector__button.slds-button.slds-button_neutral{
            font-size: 0!important;
          }
          .uploadFile svg.slds-button__icon.slds-button__icon_left {
              margin: 0;
          }
        .uploadFile lightning-primitive-file-droppable-zone.slds-file-selector__dropzone {
              border: none;
          }
          .uploadFile slds-form-element__label{
            display: none;
            }
            .uploadFile slds-form-element__control{
                margin-left:20%;
            }
            .info-button svg.slds-button__icon.slds-button__icon_left {
              margin: 0;
          }
          .uploaded-view svg.slds-button__icon {
            color: green;
        }
            .inputSize .slds-form-element__label{
               
            }
            .navClass .slds-progress-bar__value{
                background: #113451;
            }
                .instruction-box-nav.slds-progress-bar__value{
                background: #113451;
            }
           
            `;
            this.template.querySelector('.styleContainer').appendChild(style);
            this.spinnerClass = 'spinner-medium';
        }
 
       
    }
    handleCloseDoc(){
        this.showMissingDocs =  false;
    }
    prepareFlatList(groupedDocs) {
        this.flatDocList = [];
        groupedDocs.forEach(group => {
            group.documents.forEach(doc => {
                this.flatDocList.push({
                    applicant: group.applicant,
                    doc: doc
                });
            });
        });
    }

//     validateMandatoryFields(){
//         return validateMandatoryFields({loanId:this.recordId})
//         .then(result => {
//             if(result!='Success'){
//                 /*
//           this.errorfield = 
//             "• Address Line 1 is mandatory.\n" +
//             "• Address Line 2 is mandatory.\n" +
//             "• Pincode is mandatory.\n" +
//             "• Address Type is mandatory.\n" +
//             "• Ensure there is no space at the beginning of the address.\n" +
//             "• If an address does not have an Address Type because the same type was already used, please delete the corresponding document.";
//     this.showToastMessage(
//         'Error',
//         "Data is missing for some of the uploaded documents. Address Line 1, Address Line 2, Pincode, and Address Type are mandatory. " +
//         "Kindly ensure there is no space at the beginning of the address. " +
//         "If any address does not have an Address Type because the same type was already used, please delete the corresponding documents.",
//         'error'
//     );
//     */
//     const GENERIC_MSG = 'Mandatory Document fields cannot be Blank';
//     console.warn('validateMandatoryFields non-success:', result);
//      this.errorfield = GENERIC_MSG;

//                 // show in toast
//                 this.showToastMessage('Error', GENERIC_MSG, 'error');

// //this.showMissingDocs = false;

//                 this.showMissingDocs =  false;
//                 this.showMissingFields = true;
//                 return removeDocumentDetailsFromCompletionStage({ recordId: this.recordId })
//                 .then(() => {
//                     console.log('Removed Document Details from multi-picklist');
//                 })
//                 .catch(error => {
//                     console.error('Error updating picklist:', error);
//                 })
//                 .finally(() => { this.isFieldDisable = false; });
//             }
//             else{
//                 this.showMissingDocs =  false;
//                 this.showMissingFields = false;
//                 const maybeDedupe = Promise.resolve(
//                     typeof this.callDedupe === 'function' ? this.callDedupe() : null
//                 );

//                 return maybeDedupe
//                     .then(() => this.updateCompletionStage())
//                     .then(() => this.handleValidationsCheck())
//                     .finally(() => { this.isFieldDisable = false; });
//             }
//         })
//         .catch(error => {
//             console.error('validateMandatoryFields error:', error);
//             this.isFieldDisable = false;
        
          
//         });

//     }
        validateMandatoryFields() {
        validateMandatoryFields({ loanId: this.recordId })
            .then(result => {
                console.log('result: ' + JSON.stringify(result));
                if (result.length > 0) {
                    this.errorfield = result;
                    this.showMissingDocs = false;
                    this.showMissingFields = true;
                    removeDocumentDetailsFromCompletionStage({ recordId: this.recordId })
                        .then(() => {
                            console.log('Removed Document Details from multi-picklist');
                        })
                        .catch(error => {
                            console.error('Error updating picklist:', error);
                        })
                }
                else{
                     
                    this.validateAddresses();
                
                }
            })
            .catch(error => {
            });

    }
    validateAddresses() {
        validateAddressLines({ loanId: this.recordId })
            .then(result => {
                if (result.length > 0) {
                    this.errorModal = true;
                    this.errorLst = result;
                    removeDocumentDetailsFromCompletionStage({ recordId: this.recordId })
                        .then(() => {
                            console.log('Removed Document Details from multi-picklist');
                        })
                        .catch(error => {
                            console.error('Error updating picklist:', error);
                        })
                }
                else {
                    this.showMissingDocs = false;
                    this.showMissingFields = false;
                    this.errorMsg = false;
                    this.callDedupe();
                    console.log('in next buttonnnn');
                    this.updateCompletionStage();
                    
                }

            })
            .catch(error => {


            });
    }
    updateStage() {
        removeDocumentDetailsFromCompletionStage({ recordId: this.recordId })
    }

    handleClosefields(){
        this.showMissingDocs =  false;
        this.showMissingFields = false;
    }
    getApplicants(){
        getApplicants({loanId:this.recordId})
        .then(result => {
            console.log('Applicants for Dedupe:', JSON.stringify(result));
            this.applicantType = result[0].customerType;
        })
        .catch(error => {
            console.error('Error fetching applicants for dedupe:', error);
        });
    }
      hideModalBox() {
        this.errorModal = false;
    }
    /*
    validateDocuments() {
        console.log('Inside validateDocuments (temporary considered-docs check)');
        validateConsideredDocs({ recordId: this.recordId })
            .then(result => {
                console.log('Missing considered docs:', JSON.stringify(result));

                if (result && result.length > 0) {
                    // Show modal with missing documents
                    this.showMissingDocs = true;
                    this.groupedDocs = result;

                    // Retract "Document Details" from completion stage
                    return removeDocumentDetailsFromCompletionStage({ recordId: this.recordId })
                        .then(() => console.log('Removed Document Details from multi-picklist'))
                        .catch(error => console.error('Error updating picklist:', error))
                        .finally(() => { this.isFieldDisable = false; });
                }

                // Nothing missing → proceed (skip validateMandatoryFields for now)
                const maybeDedupe = Promise.resolve(
                    typeof this.callDedupe === 'function' ? this.callDedupe() : null
                );

                return maybeDedupe
                    .then(() => this.updateCompletionStage())
                    .then(() => this.handleValidationsCheck())
                    .finally(() => { this.isFieldDisable = false; });
            })
            .catch(error => {
                console.error('validateConsideredDocs error:', error);
                this.isFieldDisable = false;
            });
    }*/

    //  callDedupe() {
    //     this.showDedupeSpinner = true;
    //     let completed = 0;

    //     this.applicantsForDedupeList.forEach(applicantId => {
    //         let wrapperObj = {
    //             appId: applicantId,  // example Applicant Id
    //             loanId: this.recordId,      // example Loan Id
    //         };
           
    //         checkCustomerDedupe({inputStr : JSON.stringify(wrapperObj)})
    //             .then(result => {

    //                 console.log(`Dedupe success for applicantId: ${applicantId}`, result);
    //                 completed++;
    //                 if (completed === this.applicantsForDedupeList.length) {
    //                     this.showDedupeSpinner = false;
    //                     //this.modalAPIVisibility = true;
    //                 }
    //             })
    //             .catch(error => {
    //                 console.error(`Error in dedupe for applicantId: ${applicantId}`, error);
    //                 completed++;
    //                 if (completed === this.applicantsForDedupeList.length) {
    //                     this.showDedupeSpinner = false;
    //                     //this.modalAPIVisibility = true;
    //                 }
    //             });
    //     });
    // }


    callDedupe() {
        console.log('inside dedupe documents----');
        this.showDedupeSpinner =true;
        let completed = 0;
        console.log('this.applicantsForDedupeList'+JSON.stringify(this.applicantsForDedupeList));
        this.applicantsForDedupeList.forEach(applicantId => {
             console.log('this.applicantsForDedupeList'+applicantId);
            callDedupe({ applicantId:applicantId ,loanId:this.recordId})
                .then(result => {
                   console.log('Inside respinse document'+JSON.stringify(result));
                    console.log(`Dedupe success for applicantId: ${applicantId}`, result);
                    completed++;
                    if (completed === this.applicantsForDedupeList.length) {
                        this.showDedupeSpinner =false;
                        this.modalAPIVisibility = true;
                    }
                })
                .catch(error => {
                    console.error(`Error in dedupe for applicantId: ${applicantId}`, error);
                    completed++;
                    if (completed === this.applicantsForDedupeList.length) {
                        this.showDedupeSpinner =false;
                        this.modalAPIVisibility = true;
                    }
                });
        });
    }

    checkAddressType(){
        checkAddressType({
            loanId:this.recordId
        })
        .then(result => {
            console.log('result: ' + JSON.stringify(result));
            if(result != null && result != undefined && result.length > 0){
                this.errorModalAddressMissing = true;
                this.errorLstAddressMissing= result;

                removeDocumentDetailsFromCompletionStage({ recordId: this.recordId })
                    .then(() => {
                        console.log('Removed Document Details from multi-picklist');
                    })
                    .catch(error => {
                        console.error('Error updating picklist:', error);
                    })
            }
            else{
                this.validateMandatoryFields();
            }
        })
        .catch(error => {
            console.error('Error in checkAddressType:', error);
        });
    }
    hideModalBoxAddress(){
        this.errorModalAddressMissing =false;
    }

    
}