import { LightningElement, api, track } from 'lwc';
import checkMasterData from '@salesforce/apex/SalesLoanLoginIntegrationDetailsCheck.checkMasterData';
import getIntegrationDetails from '@salesforce/apex/SalesLoanLoginIntegrationDetailsCheck.getIntegrationDetails';
import getClassAndMethodName from '@salesforce/apex/SalesLoanLoginIntegrationDetailsCheck.getClassAndMethodName';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getApplicants from "@salesforce/apex/COMM_ItrScreenController.getApplicants";
export default class SalesLoanLoginIntegrationDetailsCheckCmp extends LightningElement {
    @api fromStage;
     @api hideActions = false;
    @track calledCredit = false;
    @track data = [];
    showIntegrationData = false;
    integrationCalled = false; 
    isLoading = false;
    loginCheck = true;
    _loaded = false;
    _recordId;
    _stageFrom;

    @api
    set recordId(v){
    this._recordId = v;
    this._bootIfReady();
    }
    get recordId(){ return this._recordId; }

    @api
    set stageFrom(v){
    if (this._initialized && (v === undefined || v === null || v === '')) return;

    this._stageFrom = v;
    if (!this._initialized && v != null) {
        const isCreditish = String(v).toLowerCase().startsWith('credit');
        this.calledCredit = isCreditish;
        this.fromStage   = v;
        this._initialized = true;
    }
    this._bootIfReady();
    }
    get stageFrom(){ return this._stageFrom; }

    _bootIfReady(){
    if (this._loaded || !this._recordId) return;
    if (this._initialized && !this.calledCredit) {
        console.warn('[SalesLoanLoginIntegrationDetailsCheckCmp] Skipping: not in Credit stage.');
        return;
    }

    this._loaded = true;
    //this.checkDomain();
    this.handleValidationsCheck();
    this.getAllApplicants(); 
    }
    connectedCallback() {

    }

    handleValidationsCheck() {
        checkMasterData({ loanId: this.recordId, stage: this.fromStage })
        .then(result => {
            console.log('checkMasterData result: '+JSON.stringify(result));
            
            let filteredData = result.filter(record => record.viewWrapper === true);
            let filtered = filteredData.filter(record => {
            if (record.label === "Pan To CIN") {
                // if applicantWrappers is empty, keep the record
                if (!record.applicantWrappers || record.applicantWrappers.length === 0) {
                    return true;
                }

                // check how many are Individual
                let total = record.applicantWrappers.length;
                let individualCount = record.applicantWrappers.filter(app => app.customerType === "Individual").length;

                if (individualCount === total) {
                    // ✅ all are Individual → remove the whole record
                    return false;
                } else if (individualCount > 0) {
                    // ✅ some are Individual → remove only those applicants
                    record.applicantWrappers = record.applicantWrappers.filter(app => app.customerType !== "Individual");
                    return true;
                }
            }
         return true; // keep all other records
        });

        console.log(filtered);

           filteredData = filtered;
            console.log('Filtered Data after Pan to CIN check:', JSON.stringify(filtered));
            filteredData.forEach(record => {
                record.applicantWrappers = record.applicantWrappers?.filter(applicant => applicant.viewApplicant === true) || [];
            });

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
                // this.showIntegrationData = false;
                this.data = [];
                this.getAllApplicants();
            }
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

            // Map of Related_Record_Id__c → integration records
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
            console.log('successMap:', JSON.stringify(successMap));
            // Build `this.data` with enriched applicant info
            console.log('filteredData:', JSON.stringify(filteredData));
            this.data = filteredData.map(record => {
                let updatedApplicants = record.applicantWrappers.length > 0 
                    ? record.applicantWrappers.map((applicant, index) => {
                        let successEntries = successMap.get(applicant.applicantId) || [];
                        let matchedEntry = successEntries.find(entry => entry.activityName === record.activityName);
                        console.log('matchedEntry:', JSON.stringify(matchedEntry));
                       
                        return {
                            ...applicant,
                            isSuccess: matchedEntry ? matchedEntry.isSuccess : false,
                            isFirst: index === 0,
                            viewApplicant: applicant.viewApplicant !== false // default  to true if not false
                        };
                    })
                    : [/*{
                        applicantId: 'N/A',
                        applicantName: 'API is based on Loan Level Data.',
                        applicantType: '',
                        isSuccess: false,
                        isFirst: true,
                        viewApplicant: true
                    }*/];
                
                return {
                    ...record,
                    isSuccess: updatedApplicants.some(applicant => applicant.isSuccess),
                    applicantWrappers: updatedApplicants
                };
            });

            if (!this.integrationCalled) {
                //this.callApi();
            }

            console.log('Updated Data with isSuccess:', JSON.stringify(this.data));
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
                        isFirst: index === 0,
                        viewApplicant: applicant.viewApplicant !== false
                    }))
                    : [{
                        applicantId: 'N/A',
                        applicantName: 'No Applicant Available',
                        applicantType: '',
                        isSuccess: false,
                        isFirst: true,
                        viewApplicant: true
                    }]
            }));
        });

        setTimeout(() => {
            console.log('this.calledCredit: ' + this.calledCredit);
            console.log('this.fromStage: ' + this.fromStage);
            if (this.stageFrom === 'Credit') {
                console.log('this.stageFrom === Credit');
                this.getAllApplicants();
            }
        }, 500);
    }

    getAllApplicants() {
        getApplicants({ recordId: this.recordId })
            .then((response) => {
                console.log("customer details getAllApplicants=: " + JSON.stringify(response));
                this.customerDetailsMap = response;
                this.updateApplicantNames();
            })
            .catch((error) => {
                console.error('Error fetching applicants:', error);
            });
    }

    updateApplicantNames() {
        if (!this.customerDetailsMap) return;

        const groupedMap = new Map();

        // Step 1: Populate all applicants from customerDetailsMap (ensures PAN always shows)
        Object.entries(this.customerDetailsMap).forEach(([applicantId, applicantName]) => {
            groupedMap.set(applicantId, {
                applicantId,
                applicantName,
                hasVisibleRecords: false, // will be updated below if KYC data exists
                records: []
            });
        });

        // Step 2: Add KYC records from this.data
        if (this.data) {
            this.data.forEach(record => {
                record.applicantWrappers.forEach(applicant => {
                    const applicantId = applicant.applicantId;
                    const applicantName = this.customerDetailsMap[applicantId] || applicant.applicantName;

                    // Initialize if not yet added (for robustness)
                    if (!groupedMap.has(applicantId)) {
                        groupedMap.set(applicantId, {
                            applicantId,
                            applicantName,
                            hasVisibleRecords: false,
                            records: []
                        });
                    }

                    if (applicant.viewApplicant) {
                        groupedMap.get(applicantId).records.push({
                            activityName: record.activityName,
                            label: record.label,
                            masterDataId: record.masterDataId,
                            isSuccess: applicant.isSuccess,
                            rowKey: `${record.masterDataId}-${applicantId}`
                        });
                        groupedMap.get(applicantId).hasVisibleRecords = true;
                    }
                });
            });
        }
         const nonce = Date.now();
        const next = Array.from(groupedMap.values()).map(a => ({
            ...a,
            sectionKey: `${a.applicantId}-${nonce}`
        }));
        
       this.showIntegrationData = false;
        Promise.resolve().then(() => {
            this.groupedApplicants = next;
            this.showIntegrationData = true;

            console.log('[updateApplicantNames] rows per applicant:',
            this.groupedApplicants.map(x => ({ id: x.applicantId, rows: x.records.length })));
        });
    }



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
    
                        let promise = getClassAndMethodName({
                            masterId: record.masterDataId,
                            loanId: this.recordId,
                            apiName: record.activityName,
                            appId: applicant.applicantId
                        })
                        .then(result => {
                            console.log(`Result for ${record.masterDataId} - ${applicant.applicantId}:`, result);
                        })
                        .catch(error => {
                            console.error(`Error for ${record.masterDataId} - ${applicant.applicantId}:`, error);
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
    
    

    rehitApi(event) {
        let mastId = event.target.dataset.masterid;
        console.log('data id rehitApi: ' + mastId);
        let apiName = event.target.dataset.name;
        console.log('dataName rehitApi: ' + apiName);
        let applicantId = event.target.dataset.id;
        console.log('applicantId rehitApi: ' + applicantId);
        this.isLoading = true;
        getClassAndMethodName({ masterId: mastId, loanId: this.recordId, apiName: apiName, appId: applicantId })
        .then(result => {
            console.log('result --> ' + result);
            if (result && result.startsWith('Error')) {
                this.showToast('Error', result, 'error');
                this.isLoading = false;
                return;
            }
            this.integrationCalled = true;
            this.handleValidationsCheck();
            this.isLoading = false;
        })
        .catch(error => {
            this.isLoading = false;
            console.error('Error fetching getClassAndMethodName:', error);
        });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
}