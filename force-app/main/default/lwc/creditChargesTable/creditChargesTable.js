import { LightningElement, track, api, wire } from 'lwc';
import getChargesRecords from '@salesforce/apex/COMM_CreditChargesTableController.getChargesRecords';
import getPicklistValues1 from '@salesforce/apex/COMM_CreditChargesTableController.getPicklistValues';
import getVASOnlyOppDetails from '@salesforce/apex/AHL_ChargesInsuranceCmpController.getVASOnlyOppDetails';
import updateChargesRecords from '@salesforce/apex/COMM_CreditChargesTableController.updateChargesRecords';
import upsertLoginFeeRecord from '@salesforce/apex/COMM_CreditChargesTableController.upsertLoginFeeRecord';
import getMetadataValue from '@salesforce/apex/COMM_PricingApprovalController.getMetadataValue';
import initiateAPIRequest from '@salesforce/apex/COMM_LoanSchedulerContoller.upsertChargesForMultiProd';
import calculateGST from '@salesforce/apex/AHL_CalculateGstController.initiateAPIRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpportunitiesForLWC from '@salesforce/apex/COMM_LoanSchedulerContoller.getOpportunitiesForLWC';
import updateTotalCharges from '@salesforce/apex/COMM_CreditChargesTableController.updateTotalCharges';
import checkLoanTransaction from '@salesforce/apex/COMM_CreditChargesTableController.checkLoanTransaction';
import createLoanTransaction from '@salesforce/apex/COMM_CreditChargesTableController.createLoanTransaction';
import checkChargesAPI from '@salesforce/apex/COMM_CreditChargesTableController.checkChargesAPI';
import checkPricingApprovalStatus from '@salesforce/apex/COMM_CreditChargesTableController.checkPricingApprovalStatus';
import canUserEditChargesPricing from '@salesforce/apex/COMM_CreditChargesTableController.canUserEditChargesPricing';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import PRICINGAPPROVAL from '@salesforce/schema/Opportunity.Pricing_Approval_Status__c';//Sanwar
import WAIVEDCHARGES from '@salesforce/schema/Charges_Insurance__c.Waived_Charge_Amount__c';//Sanwar
import { fireEvent } from 'c/pubsub';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from "lightning/uiRecordApi";
import getLoginFee from '@salesforce/apex/COMM_CreditChargesTableController.getLoginFee';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import SUB_RECEIPT_FIELD from '@salesforce/schema/Charges_Insurance__c.Sub_Receipt_Mode_PSV__c';
import getUserRole from '@salesforce/apex/Hl_CovenantsDetailFormController.getUserRole';
import getUserRoleAndSubStage from '@salesforce/apex/Hl_CovenantsDetailFormController.getUserRoleAndSubStage';
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import canUserEditRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.canUserEditRecord';//Kalpesh
import getMetadataRecords from '@salesforce/apex/COMM_CreditChargesTableController.getMetadataRecords';
import getLoanProductRecords from '@salesforce/apex/COMM_PricingApprovalController.getLoanProductRecords';//sanwar(23/12/2025)
import deletecontentDocumentAndDocFile from '@salesforce/apex/COMM_SalesLoginFeeController.deletecontentDocumentAndDocFile'; //Armann
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import insertFileRecord from '@salesforce/apex/COMM_SalesLoanLoginController.insertFileRecord';
import getDocumentsList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getDocumentsList';
import createDocumentChecklistForSales from '@salesforce/apex/COMM_SalesLoanLoginController.createDocumentChecklistForSales';
import deleteContentDoctIdLoginFee from '@salesforce/apex/COMM_SalesLoginFeeController.deleteContentDoctIdLoginFee';
import checkeSignStatus from '@salesforce/apex/Utility_V1.checkeSignStatus';

const LOAN_FIELDS = ['Opportunity.StageName', 'Opportunity.Sub_stage__c'];

// FIX: helper to safely parse numbers that may arrive as comma-formatted strings
const toNumber = (val) => {
    if (val === null || val === undefined || val === '') return 0;
    const n = parseFloat(String(val).replace(/,/g, ''));
    return isNaN(n) ? 0 : n;
};

export default class CreditChargesTable extends NavigationMixin(LightningElement) {
    @api recordId;
    @track rows = [];
    @track lMSrows = [];
    @track loSrows = [];
    @track insuranceRows = [];
    @track totalRecordRows = [];
    @track showDocumentName = false;
    @track uploadedFilesSales = [];
    @track showRecords = false;
    uploadedFileName = [];
    subReceiptMode = '';
    receiptValue = '';
    transactionRefNoValue = '';
    Remarks = '';
    salesReturnedDocumentId;
    uploadedFilesList = [];
    @track countOfDocument = 0;
    @track documentList = [];
    @track logFeeObj = {};
    selectedDocIds = [];
    selectedDocList = [];
    @track loginFeeId;
    isDisable = false;
    receiptOptions = [];
    @track picklistMap = {}; // Store API Name -> Label Mapping
    @track feeMethodOptions = []; // Picklist options for Fee Method
    @track mainAccordianActiveSection = [];
    @track showOpenAll = true;
    totalFeeChargeRecord = {};
    totalFeeChargeRecordAHL = {};
    totalFeeChargeRecordAHLChild = {};
    totalFeeChargeRecordFL = {};
    totalFeeChargeRecordANHL = {};
    totalFeeChargeRecordANHLChild = {};
    @track consolidatedTotalFeeChargeRows = [];
    excludingText;
    @track isLoading = false;
    @track showRefreshButton = true;
    @track showNonEditable = false;
    @track refreshTrigger = false; // Trigger variable
    @track isEditableUser = true;
    @track taxAmount;
    @track hitGstMan = false;
    isRoiChanged = false;//sanwar(23/12/2025)
    loginFee;
    loginFeeDeducted = false;
    oppSubStage = '';
    oppStage = '';
    @track isEnableApprovalHis = false;
    @track balanceFeesAHL;
    @track balanceFeesAHLChild;
    @track balanceFeesANHL;
    @track balanceFeesANHLChild;
    @track balanceFeesFL;
    @track balanceFees;
    @track balanceFeesStmpAHL;
    @track balanceFeesStmpAHLChild;
    @track balanceFeesStmpANHL;
    @track balanceFeesStmpANHLChild;
    @track balanceFeesStmpFL;
    @track balanceFeesStmp;
    @track metadataRows = [];
    @track isHLUser = false;
    @track esignStatus;
    @track showConfirmation = false;
    @track confirmation = false;
    @track isGenerate = false;
    prodwiseMaxProcFeeAmtObj;

    // FIX: re-entrancy guards to stop the infinite spinner / GST-reload storm
    isGstInProgress = false;        // true while a batch of GST calcs is running
    isLoadingCharges = false;       // prevents concurrent loadChargesRecords runs
    _gstAttemptKeys = new Set();    // charge keys already attempted in this cycle (breaks true-zero loops)

    @api runCheckMethod() {//Sanwar
        this.checkStatus();
    }

    @wire(CurrentPageReference) pageRef;
    @track actualerror = false;

    @wire(getRecord, {
        recordId: "$recordId",
        fields: LOAN_FIELDS,
    })
    gotLoanFields({ data, error }) {
        if (data) {
            this.loanStage = data.fields.StageName.value;
            this.loanSubStage = data.fields.Sub_stage__c.value;
        } else if (error) {
            console.error('Error fetching INFO:', error);
        }
    }

    @wire(getPicklistValues, { fieldApiName: SUB_RECEIPT_FIELD, recordTypeId: '012000000000000AAA' })
    wiredReceiptOptions({ data, error }) {
        if (data) {
            this.receiptOptions = data.values;
        } else if (error) {
            console.error('Error loading receipt options', error);
        }
    }

    connectedCallback() {
        this.fetchProducDetails();
        console.log('In connected callback');
        this.fetchLoginFee();

        getMetadataRecords({})
            .then(result => {
                console.log('metadata result:', JSON.stringify(result));
                this.metadataRows = result;
            })
            .catch(error => {
                console.error('Error in getMetadataRecords', error);
            });

        canUserEditChargesPricing({ opportunityId: this.recordId })
            .then(result => {
                this.isEditableUser = result;
                if (!this.isEditableUser && !this.isHLUser) {
                    this.showNonEditable = true;
                }
                console.log('Is editable user:', this.isEditableUser);
                console.log('this.showNonEditable:', this.showNonEditable);
            })
            .catch(error => {
                console.error('Error checking user access for VAS:', error);
                this.isEditableUser = false; // Default to read-only if error
            });

        this.loadPicklistValues();
        this.refreshTrigger = !this.refreshTrigger;
        if (this.isEditableUser) {
            this.checkStatus();
        }
        getVASOnlyOppDetails({ parentLoanAppId: this.recordId })
            .then(result => {
                this.isVASOnlyOpp = result;
            })
            .catch(error => {
                console.error('Error fetching metadata:', error);
            });
    }

    fetchLoginFee() {
        getLoginFee({ recordId: this.recordId })
            .then(result => {
                console.log('Apex Response:', result);
                this.loginFeeId = result.Id;
                this.loginFee = result.loginFee || '';
                this.receiptValue = result.receiptNo || '';
                this.Remarks = result.remarks || '';
                this.subReceiptMode = result.subReceiptMode || '';
                this.transactionRefNoValue = result.transactionRef || '';
            })
            .catch(error => {
                console.error('Error fetching login details:', error);
            });
        this.getdocDetails();
    }

    fetchProducDetails() {
        var inputMapParam = {
            'oppId': this.recordId
        };

        getProductDetails({ inputMap: inputMapParam })
            .then(result => {
                console.log('result product: ' + JSON.stringify(result));
                this.isHLUser = result.isHLRelated;
            })
            .catch(error => {
                console.error('error in getting product: ' + error)
            })
    }

    checkeSignStatus() {
        checkeSignStatus({ loanId: this.recordId })
            .then(res => {
                console.log('result product: ' + res);
                this.esignStatus = res;
                this.initializeLoanTransaction();
            })
            .catch(error => {
                console.error('error in getting product: ' + error)
            })
    }

    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, SUBSTAGE_FIELD] })
    opportunity({ error, data }) {
        if (data) {
            this.oppStage = data.fields.StageName.value;
            this.oppSubStage = data.fields.Sub_stage__c.value;
            console.log('Opp sub stage', this.oppSubStage);
            setTimeout(() => {
                this.handleVisibility();
            }, 1000);
        }
    }

    handleVisibility() {
        console.log('Stage', this.oppStage);
        console.log(' Sub stage At 238', this.oppSubStage);
        getUserRoleAndSubStage({ recordId: this.recordId })
            .then(result => {
                this.isEditableUser = true;
            })
            .catch(error => {
                console.error('Error in getUserRoleAndSubStage:', error);
            });
    }

    renderedCallback() {
        console.log('rendered callback called');
        registerListener('refreshCharges', this.handlePricingRefresh, this);
        const style = document.createElement("style");
        style.innerText = `
        /* Reduce row height */
        tr {
            min-height: 15px !important; /* Further reduces row height */
        }
        td {
            padding: 1px !important; /* Further reduces padding */
        }

        /* Hide input border and apply bottom border only */
        .hideInput .slds-input {
            border: none !important;
            border-bottom: 1px solid #33455e !important;
            background-color: #16283f;
            color: #ffffff !important;
            .hideInput .slds-input
            outline: none;
            box-shadow: none;
            border-radius: 0 !important;
            padding: 1px 3px !important; /* Minimal padding */
            font-size: 12px !important; /* Reduce font size */
            min-height: 12px !important; /* Reduce height */
            line-height: 12px !important;
        }

        /* Reduce height of combobox */
        .removeborder .slds-combobox__input {
            border: none !important;
            box-shadow: none !important;
            background-color: #16283f;
            .hideInput .slds-input
            border-bottom: 1px solid #33455e !important;
            border-radius: 0 !important;
            padding: 1px 3px !important; /* Minimal padding */
            font-size: 12px !important; /* Reduce font size */
            min-height: 15px !important; /* Reduce height */
            line-height: 15px !important;
        }
    `;

        // Append the styles to the .styleContainer
        this.template.querySelector(".styleContainer")?.appendChild(style);
    }

    handlePricingRefresh() {
        console.log('Pubsub Event received: refreshing PricingApproval');
        this.checkStatus();
        this.loadPicklistValues();
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    @wire(getMetadataValue, { metadataName: 'Charge_Screen_Total_Remark' })
    wiredText({ error, data }) {
        if (data) {
            this.excludingText = data;
        } else if (error) {
            console.error('Error fetching constant:', error);
            this.excludingText = '* Excluding Part-Payment and Foreclosure Charges'; // Fallback text
        }
    }

    checkStatus() {
        canUserEditChargesPricing({ opportunityId: this.recordId })
            .then(result => {
                this.isEditableUser = result;
                console.log('this.isEditableUser2:: ', this.isEditableUser);
                if (this.isEditableUser && !this.isHLUser) {
                    checkPricingApprovalStatus({ loanApplicationId: this.recordId })
                        .then(result => {
                            console.log('Pricing Approval Status Check:', result);
                            if (result) {
                                this.showNonEditable = true;
                            } else {
                                this.showNonEditable = false;
                            }
                        })
                        .catch(error => {
                            console.error('Error:', error);
                        });
                }
            })
            .catch(error => {
                console.error('Error checking user access for VAS:', error);
                this.isEditableUser = false; // Default to read-only if error
            });
        console.log('inside', this.recordId);
        console.log('this.isEditableUser1:: ', this.isEditableUser);
    }

    handleyes(event) {
        this.confirmation = true;
        this.showConfirmation = false;
        if (this.isGenerate) {
            this.initializeLoanTransaction();
        }
    }

    handleClose(event) {
        this.showConfirmation = false;
    }

    async initializeLoanTransaction() {
        console.log('inside async initialize method');
        this.isGenerate = true;
        if (this.isHLUser && this.esignStatus == 'Esign Completed' && this.confirmation) {
            this.isLoading = true;
            this.dispatchLoadingEvent();
            try {
                const loanTransactionExists = await checkLoanTransaction({ loanApplicationId: this.recordId });
                console.log('loanTransactionExists:: ' + loanTransactionExists);
                if (!loanTransactionExists) {
                    this.showToast('Error', 'Transactional Loan Record Not Available', 'Error');
                    this.handleChargesAPI();
                } else {
                    this.handleChargesAPI();
                }
            } catch (error) {
                this.isLoading = false;                 // FIX: clear loading on failure
                this.dispatchLoadingEvent();
                this.showToast('Error', error?.body?.message || error, 'error');
            }
        } if (this.isHLUser && this.esignStatus == 'Esign Completed' && !this.confirmation) {
            this.showConfirmation = true;
        } else if (!this.isHLUser || this.esignStatus != 'Esign Completed') {
            this.isLoading = true;
            this.dispatchLoadingEvent();
            try {
                const loanTransactionExists = await checkLoanTransaction({ loanApplicationId: this.recordId });
                console.log('loanTransactionExists:: ' + loanTransactionExists);
                if (!loanTransactionExists) {
                    this.showToast('Error', 'Transactional Loan Record Not Available', 'Error');
                    this.handleChargesAPI();
                } else {
                    this.handleChargesAPI();
                }
            } catch (error) {
                this.isLoading = false;                 // FIX: clear loading on failure
                this.dispatchLoadingEvent();
                this.showToast('Error', error?.body?.message || error, 'error');
            }
        }
    }

    @track isChargesAPIInvoked = false;
    async handleChargesAPI() {
        try {
            const chargesAPIHit = await checkChargesAPI({ recordId: this.recordId });
            this.isChargesAPIInvoked = chargesAPIHit;
            console.log('chargesAPIHit:: ' + chargesAPIHit);
            this.refreshAPI();
            this.loadPicklistValuesOnly();
            this.dispatchLoadingEvent();
            if (this.isHLUser) {
                const fields = {
                    Id: this.recordId,
                    DocGen_Status__c: 'DocGen Not-Initiated'
                };
                this.updateRecordField(fields);
            }
        } catch (error) {
            this.isLoading = false;                     // FIX: clear loading on failure
            this.dispatchLoadingEvent();
            this.showToast('Error', error?.body?.message || error, 'error');
        }
    }

    refreshAPI() {
        console.log('inside refresh API:: ');
        this.isLoading = true;
        this.dispatchLoadingEvent();
        let inputMap = {
            loanId: this.recordId,
            processName: 'Loan Scheduler Create Charges',
            stageName: 'PSV',
            loginFee: this.loginFee
        };

        getOpportunitiesForLWC({ recordId: this.recordId })
            .then(oppList => {
                if (oppList.length === 0) {
                    this.showToast('Error', 'No Opportunities found', 'error');
                    this.isLoading = false;             // FIX: clear loading on early return
                    this.dispatchLoadingEvent();
                    return;
                }

                initiateAPIRequest({ inputMap: inputMap, oppList: oppList, invocationType: 'Charges API Invocation' })
                    .then(response => {
                        console.log('API Response:', response);
                        if (response && response === 'Success') {
                            this.showToast('Success', 'Charges generated successfully!', 'success');
                            this.loadChargesRecords();
                            this.isChargesAPIInvoked = true;
                        } else {
                            let errorMessage = response;
                            this.showToast('Error', errorMessage, 'error');
                            this.isChargesAPIInvoked = false;
                        }
                        this.isLoading = false;
                        this.dispatchLoadingEvent();
                    })
                    .catch(error => {
                        console.error('Error calling API:', error);
                        let errorMessage = error.body ? error.body.message : 'Unknown error';
                        this.showToast('Error', errorMessage, 'error');
                        this.isChargesAPIInvoked = false;
                        this.isLoading = false;
                        this.dispatchLoadingEvent();
                    });
            })
            .catch(error => {
                console.error('Error fetching Opportunities:', error);
                this.showToast('Error', 'Failed to fetch Opportunities', 'error');
                this.isLoading = false;
                this.dispatchLoadingEvent();
            });
    }

    dispatchLoadingEvent() {
        const loadingEvent = new CustomEvent('loadingchange', {
            detail: { isLoading: this.isLoading }
        });
        this.dispatchEvent(loadingEvent);
    }

    // Fetch Picklist Values for Charge Name (Charges_Fee_Type__c)
    loadPicklistValues() {
        getPicklistValues1()
            .then((data) => {
                this.picklistMap = data;
                getChargesRecords({ opportunityId: this.recordId })
                    .then((data) => {
                        const stage = data[0]?.Loan_Application__r?.StageName;
                        const subStage = data[0]?.Loan_Application__r?.Sub_stage__c;
                        if (stage === 'Disbursement' || subStage == 'PSV Credit' || subStage == 'PSV Sales') {
                            this.loadChargesRecords();
                        }
                    })
                    .catch((error) => {
                        console.error('Error fetching charge records in loadPicklistValues:', JSON.stringify(error));
                    });
            })
            .catch((error) => {
                console.error('Error fetching picklist values:', JSON.stringify(error));
            });

        // Fee Method Picklist Values (Static Options)
        this.feeMethodOptions = [
            { label: 'Deduct from Disbursement', value: 'DISB' },
            { label: 'Self funded', value: 'Self funded' }
        ];
    }

    // Fetch Picklist Values only and not load charges
    loadPicklistValuesOnly() {
        getPicklistValues1()
            .then((data) => {
                this.picklistMap = data;
            })
            .catch((error) => {
                console.error('Error fetching picklist values:', JSON.stringify(error));
            });

        this.feeMethodOptions = [
            { label: 'Deduct from Disbursement', value: 'DISB' }
        ];
    }

    /**
     * Function to load charges record on load of screen including LOS, LMS & Insurance charges
     * and update the backend.
     *
     * FIX: GST is no longer recalculated recursively from inside the .map(). Instead we
     * collect every charge that needs GST into `gstRowsToProcess`, then fire them once as a
     * batch (guarded by isGstInProgress) and reload exactly once when the batch completes.
     * This removes the AHL parent+child reload storm that left the spinner stuck.
     */
    loadChargesRecords() {
        console.log('inside charges record:: ');

        // FIX: prevent concurrent/recursive runs from piling up
        if (this.isLoadingCharges) {
            console.log('loadChargesRecords already running - skipping re-entry');
            return;
        }
        this.isLoadingCharges = true;

        this.feeMethodOptions = [
            { label: 'Deduct from Disbursement', value: 'DISB' },
            { label: 'Self funded', value: 'Self funded' }
        ];

        const gstRowsToProcess = []; // FIX: collected here, processed once after the map

        getChargesRecords({ opportunityId: this.recordId })
            .then((data) => {
                console.log('Test===allRecord==>', data);
                this.rows = [];

                this.rows = data
                    .filter(record => record.RecordType.Name !== 'Insurance' && (record.Category__c == 'LOS' || record.Category__c == 'LMS' || record.Category__c == 'Insurance'))
                    .map((record) => {
                        console.log('record.Id-->', record.Id);
                        const taxPercentage = record.Tax__c ? parseFloat(record.Tax__c) / 100 : 0;
                        const rawTaxAmount = toNumber(record.Requested_Amount_INR__c) * taxPercentage;

                        if (record.Name == 'PROCFEE') {
                            if ((record.Product_Name__c == 'Affordable Home Loan' || record.Product_Name__c == 'Home Loan') && record.Product__r.Product_Type__c == 'Parent') {
                                this.balanceFeesAHL = toNumber(record.Balance_Fees__c);
                            } else if ((record.Product_Name__c == 'Affordable Home Loan' || record.Product_Name__c == 'Home Loan') && record.Product__r.Product_Type__c == 'Child') {
                                this.balanceFeesAHLChild = toNumber(record.Balance_Fees__c);
                            } else if ((record.Product_Name__c == 'Affordable Non-Home Loan' || record.Product_Name__c == 'Non Home Loan') && record.Product__r.Product_Type__c == 'Parent') {
                                this.balanceFeesANHL = toNumber(record.Balance_Fees__c);
                            } else if ((record.Product_Name__c == 'Affordable Non-Home Loan' || record.Product_Name__c == 'Non Home Loan') && record.Product__r.Product_Type__c == 'Child') {
                                this.balanceFeesANHLChild = toNumber(record.Balance_Fees__c);
                            } else if (record.Product_Name__c == 'Flexi Loan') {
                                this.balanceFeesFL = toNumber(record.Balance_Fees__c);
                            }
                        }
                        if (record.Name == 'STFRCHG') {
                            if ((record.Product_Name__c == 'Affordable Home Loan' || record.Product_Name__c == 'Home Loan') && record.Product__r.Product_Type__c == 'Parent') {
                                this.balanceFeesStmpAHL = toNumber(record.Balance_Fees__c);
                            } else if ((record.Product_Name__c == 'Affordable Home Loan' || record.Product_Name__c == 'Home Loan') && record.Product__r.Product_Type__c == 'Child') {
                                this.balanceFeesStmpAHLChild = toNumber(record.Balance_Fees__c);
                            } else if ((record.Product_Name__c == 'Affordable Non-Home Loan' || record.Product_Name__c == 'Non Home Loan') && record.Product__r.Product_Type__c == 'Parent') {
                                this.balanceFeesStmpANHL = toNumber(record.Balance_Fees__c);
                            } else if ((record.Product_Name__c == 'Affordable Non-Home Loan' || record.Product_Name__c == 'Non Home Loan') && record.Product__r.Product_Type__c == 'Child') {
                                this.balanceFeesStmpANHLChild = toNumber(record.Balance_Fees__c);
                            } else if (record.Product_Name__c == 'Flexi Loan') {
                                this.balanceFeesStmpFL = toNumber(record.Balance_Fees__c);
                            }
                        }

                        // FIX: instead of calling calculateGST() + loadChargesRecords() inline (recursive storm),
                        // collect the rows that still need a GST value and process them once after the map.
                        let gstMetadata = this.metadataRows.filter(acc => acc.Charge_Name__c == record.Name);
                        const gstApplicable = gstMetadata && gstMetadata.length > 0 && gstMetadata[0]?.Is_GST_Applicable__c;
                        const balanceNonZero = record.Balance_Fees__c != null && toNumber(record.Balance_Fees__c) != 0;
                        // FIX: only trigger when tax is genuinely unset (null/empty). Do NOT treat 0 as "needs recalc"
                        // because a legitimately-zero GST would otherwise loop forever.
                        const taxUnset = record.Tax_INR__c === null || record.Tax_INR__c === undefined || record.Tax_INR__c === '';
                        // FIX: per-cycle attempt key so the same charge isn't re-queued endlessly within one reload chain
                        const attemptKey = `${record.Product__c}_${record.Name}`;

                        if (gstApplicable && balanceNonZero && taxUnset && !this._gstAttemptKeys.has(attemptKey)) {
                            this._gstAttemptKeys.add(attemptKey);
                            gstRowsToProcess.push({
                                loanId: this.recordId,
                                processName: 'CalculateGST',
                                productName: record.Product__c,
                                feeType: record.Name,
                                isWaiverAmountCalc: 'false'
                            });
                        }

                        this.taxAmount = record.Tax_INR__c;
                        const finalAmount = toNumber(record.Requested_Amount_INR__c) + toNumber(this.taxAmount);
                        console.log('PROCFEE EDITABLE CHECK  ' + record.Charges_Fee_Type__c + '  AND  ' + this.isHLUser);

                        return {
                            id: record.Id,
                            originalName: record.Name,
                            picklistApiValue: record.Charges_Fee_Type__c ? record.Charges_Fee_Type__c : 'NA',
                            productName: record.Product_Name__c ? record.Product_Name__c : 'NA',
                            productId: record.Product__c ? record.Product__c : 'NA',
                            productType: record.Product__r.Product_Type__c ? record.Product__r.Product_Type__c : 'NA',
                            name: record.Category__c == 'LOS' ? this.picklistMap[record.Charges_Fee_Type__c] || record.Charges_Fee_Type__c :
                                record.Category__c == 'LMS' ? this.picklistMap[record.Charges_Fee_Type__c] || record.Charges_Fee_Type__c :
                                    record.Category__c == 'Insurance' ? record.VAS_Code__c : 'NA',

                            defaultAmount: record.Category__c == 'LOS' ? record.Allocated_Amount__c :
                                record.Category__c == 'LMS' ? record.Default_Percentage__c :
                                    record.Category__c == 'Insurance' ? record.Total_VAS_Amount__c : '0',
                            stampedit: (record.Charges_Fee_Type__c === 'STFRCHG') ? true : false,
                            loginFee: record.Category__c == 'LOS' ? record.Adjusted_Login_Fee__c : 'NA',
                            balanceFees: record.Category__c == 'LOS' ? record.Balance_Fees__c :
                                record.Category__c == 'LMS' ? record.Requested_Percentage__c :
                                    record.Category__c == 'Insurance' ? record.Total_VAS_Amount__c : '0',
                            requestedAmount: record.Category__c == 'LOS' ? record.Waived_Charge_Amount__c :
                                record.Category__c == 'LMS' ? record.Waived_Charge_Amount__c :
                                    record.Category__c == 'Insurance' ? '' : '0',

                            tax: record.Category__c == 'LOS' && this.taxAmount ? this.taxAmount :
                                record.Category__c == 'LMS' ? 'NA' :
                                    record.Category__c == 'Insurance' ? 0 : '0',

                            finalAmount: record.Category__c == 'LOS' && record.Final_Amount_INR__c ? record.Final_Amount_INR__c :
                                record.Category__c == 'LMS' && record.Final_Amount_INR__c ? record.Final_Amount_INR__c :
                                    record.Category__c == 'Insurance' && record.Total_VAS_Amount__c ? toNumber(record.Total_VAS_Amount__c) : '0',

                            feeMethod: record.Category__c == 'LMS' ? 'NA' : (this.isVASOnlyOpp && this.loanStage === 'PSV' && record.Category__c == 'LOS') ? 'POSP' : record.Fee_Method__c,
                            min: record.Min_Percent__c ? record.Min_Percent__c : 0,
                            max: record.Max_Percent__c ? record.Max_Percent__c : 0,
                            Category: record.Category__c ? record.Category__c : '',
                            Loan_Application: record.Loan_Application__c,
                            isDisabled: !(
                                this.metadataRows.find(meta => meta.Charge_Name__c === record.Name && meta.Is_Waiver__c === true)
                            ),//sanwar
                            isBalanceFeeDisabled: !(
                                this.metadataRows.find(meta => meta.Charge_Name__c === record.Name && meta.Is_Balance_Fee_Editable__c === true)
                            ),//sanwar
                            isFeeMethodDisabled: false,
                            isProcFee: record.Charges_Fee_Type__c === 'PROCFEE' && !this.isHLUser,
                            isAmountChangedByUser: false,
                            notprocfee: (record.Charges_Fee_Type__c != 'PROCFEE' && record.Charges_Fee_Type__c != 'STFRCHG') ? true : false,
                            chargesWaived: record?.Is_Charges_waived__c, //sanwar
                            isAccruedAmountDisabled: !(
                                this.metadataRows.find(meta => meta.Charge_Name__c === record.Name && meta.Is_Accrued_Amount_Editable__c === true)
                            ),
                            isCollectedFeesDisabled: !(
                                this.metadataRows.find(meta => meta.Charge_Name__c === record.Name && meta.Is_Collected_Fees_Editable__c === true)
                            ),
                        };
                    });

                let lsm = [];
                let los = [];
                let insuranceRows = [];

                this.rows.forEach(ele => {
                    if (ele.Category === 'LOS') {
                        los.push(ele);
                    } else if (ele.Category === 'LMS') {
                        lsm.push(ele);
                    } else {
                        insuranceRows.push(ele);
                    }
                });

                let totalFeeChargeRecord = {};
                let totalFeeChargeRecordAHL = {};
                let totalFeeChargeRecordAHLChild = {};
                let totalFeeChargeRecordFL = {};
                let totalFeeChargeRecordANHL = {};
                let totalFeeChargeRecordANHLChild = {};
                data.forEach(ele => {
                    if (!ele.Charges_Insurance__c && ele.Name.includes('Total Charges')) {
                        totalFeeChargeRecord = {
                            ...ele,
                            Total_Charges__c: ele.Total_Charges__c,
                            Total_Fee_to_be_deducted__c: ele.Total_Fee_to_be_deducted__c
                        };

                        if ((ele.Product_Name__c == 'Affordable Home Loan' || ele.Product_Name__c == 'Home Loan') && ele.Product__r.Product_Type__c == 'Parent') {
                            totalFeeChargeRecordAHL = {
                                ...ele,
                                Total_Charges__c: ele.Total_Charges__c,
                                Total_Fee_to_be_deducted__c: ele.Total_Fee_to_be_deducted__c
                            };
                        }
                        if ((ele.Product_Name__c == 'Affordable Home Loan' || ele.Product_Name__c == 'Home Loan') && ele.Product__r.Product_Type__c == 'Child') {
                            totalFeeChargeRecordAHLChild = {
                                ...ele,
                                Total_Charges__c: ele.Total_Charges__c,
                                Total_Fee_to_be_deducted__c: ele.Total_Fee_to_be_deducted__c
                            };
                        }
                        else if ((ele.Product_Name__c == 'Affordable Non-Home Loan' || ele.Product_Name__c == 'Non-Home Loan') && ele.Product__r.Product_Type__c == 'Parent') {
                            totalFeeChargeRecordANHL = {
                                ...ele,
                                Total_Charges__c: ele.Total_Charges__c,
                                Total_Fee_to_be_deducted__c: ele.Total_Fee_to_be_deducted__c
                            };
                        }
                        else if ((ele.Product_Name__c == 'Affordable Non-Home Loan' || ele.Product_Name__c == 'Non-Home Loan') && ele.Product__r.Product_Type__c == 'Child') {
                            totalFeeChargeRecordANHLChild = {
                                ...ele,
                                Total_Charges__c: ele.Total_Charges__c,
                                Total_Fee_to_be_deducted__c: ele.Total_Fee_to_be_deducted__c
                            };
                        }
                        else if (ele.Product_Name__c == 'Flexi Loan') {
                            totalFeeChargeRecordFL = {
                                ...ele,
                                Total_Charges__c: ele.Total_Charges__c,
                                Total_Fee_to_be_deducted__c: ele.Total_Fee_to_be_deducted__c
                            };
                        }
                    }
                });

                this.totalFeeChargeRecord = totalFeeChargeRecord;
                this.totalFeeChargeRecordAHL = totalFeeChargeRecordAHL;
                this.totalFeeChargeRecordAHLChild = totalFeeChargeRecordAHLChild;
                this.totalFeeChargeRecordFL = totalFeeChargeRecordFL;
                this.totalFeeChargeRecordANHL = totalFeeChargeRecordANHL;
                this.totalFeeChargeRecordANHLChild = totalFeeChargeRecordANHLChild;
                this.lMSrows = lsm;
                this.loSrows = los;
                this.insuranceRows = insuranceRows;

                this.recalculateTotalCharges();

                // FIX: process the collected GST rows once, then reload a single time.
                this.processPendingGst(gstRowsToProcess);
            })
            .catch((error) => {
                console.error('Error fetching records:', JSON.stringify(error));
            })
            .finally(() => {
                this.isLoadingCharges = false; // FIX: always release the load guard
            });
    }

    /**
     * FIX: batch GST processing. Runs all pending GST calcs concurrently, then reloads
     * exactly once. Guarded by isGstInProgress so a reload triggered by GST cannot
     * re-enter this method and start a second storm.
     */
    processPendingGst(gstRowsToProcess) {
        if (!gstRowsToProcess || gstRowsToProcess.length === 0) {
            return;
        }
        if (this.isGstInProgress) {
            console.log('GST batch already in progress - skipping');
            return;
        }
        this.isGstInProgress = true;
        this.isLoading = true;
        this.dispatchLoadingEvent();

        const calls = gstRowsToProcess.map(inputMap =>
            calculateGST({ inputMap })
                .then(data => ({ ok: data === 'Success: GST calculation completed.', data }))
                .catch(error => {
                    console.error('GST calc failed for', JSON.stringify(inputMap), error);
                    return { ok: false, error };
                })
        );

        Promise.all(calls)
            .then(results => {
                const anyFailed = results.some(r => !r.ok);
                if (anyFailed) {
                    this.hitGstMan = true;
                    this.showToast('Error', 'GST calculation failed for one or more charges. Please enter tax amount manually.', 'error');
                }
                this.isGstInProgress = false;
                this.isLoading = false;
                this.dispatchLoadingEvent();
                // FIX: single reload after the whole batch finishes.
                this.loadChargesRecords();
            })
            .catch(error => {
                console.error('Unexpected error in GST batch:', error);
                this.isGstInProgress = false;
                this.isLoading = false;
                this.dispatchLoadingEvent();
            });
    }

    handleInputChange(event) {
        try {
            const rowId = event.target.dataset.id;
            const field = event.target.dataset.field;
            const value = event.target.value;
            console.log('value:: ' + value);
            console.log('field:: ' + field);

            this.rows = this.rows.map((row) => {
                if (row.id === rowId) {
                    if (field === 'requestedAmount' && row.Category === 'LOS') {
                        if (row.originalName != 'PROCFEE' && PRICINGAPPROVAL == 'Approved') {//sanwar
                            console.log('line 512--', row.finalAmount);
                        }
                        else if (PRICINGAPPROVAL == 'Approved') {//sanwar
                            let balance = toNumber(row.balanceFees);
                            let waiver = toNumber(row.requestedAmount);
                            let taxAmount = toNumber(row.tax);
                        }
                    }
                    if (field === 'requestedAmount' && row.Category === 'LMS') {
                        console.log('requestedAmount:: ' + row.requestedAmount);
                    }
                    if (field === 'balanceFees' && row.Category === 'LOS') {
                        row.balanceFees = value;
                    } if (field === 'requestedAmount') {
                        const requested = toNumber(value);
                        const originalFinal = toNumber(row.originalFinalAmount || row.finalAmount);
                        if (!row.originalFinalAmount) {
                            row.originalFinalAmount = originalFinal;
                        }
                        row.finalAmount = row.originalFinalAmount - requested;
                        console.log('Correct finalAmount:', row.finalAmount);
                    }
                    row.minPercent = row.min ? parseFloat(row.min) / 100 : 0;
                    row.maxPercent = row.max ? parseFloat(row.max) / 100 : 0;
                    console.log('row:: ' + JSON.stringify(row));
                }
                return row;
            });
        } catch (error) {
            console.error('Raw error:', JSON.stringify(error));
            const message =
                error.body?.message ||
                error.body?.pageErrors?.[0]?.message ||
                error.message ||
                'Unknown error';
            console.error('Parsed error message:', message);
        }
    }

    /**
     * FIX: keystroke validation rewritten.
     *  - control/navigation keys are allowed
     *  - copy/paste/cut/select shortcuts (Ctrl/Cmd) are allowed
     *  - maxLimit is parsed AFTER stripping commas (a comma-formatted balanceFees no longer
     *    collapses to 1 or 0 and falsely blocks valid input)
     *  - if there is no real limit (maxLimit <= 0) the limit check is skipped instead of
     *    blocking everything above 0
     *  - validity is always cleared on a good key
     */
    handleNumberValidation(event) {
        const key = event.key;
        const input = event.target;
        const field = input.dataset.field;
        const rowId = input.dataset.id;
        const row = this.rows.find(r => r.id === rowId);

        // Allow control / navigation keys
        const allowedKeys = ['Backspace', 'Tab', 'ArrowLeft', 'ArrowRight',
            'ArrowUp', 'ArrowDown', 'Delete', 'Home', 'End', 'Enter', 'Escape'];
        if (allowedKeys.includes(key)) {
            input.setCustomValidity('');
            return;
        }

        // Allow copy / paste / cut / select-all and any modifier combo
        if (event.ctrlKey || event.metaKey) {
            input.setCustomValidity('');
            return;
        }

        // Beyond this point only single printable characters should remain.
        // Reject anything that is not a digit or a single dot.
        if (key.length > 1 || !/[0-9.]/.test(key)) {
            event.preventDefault();
            input.setCustomValidity('Only numeric values are allowed.');
            input.reportValidity();
            return;
        }

        if (key === '.' && input.value.includes('.')) {
            event.preventDefault();
            input.setCustomValidity('Only one decimal point is allowed.');
            input.reportValidity();
            return;
        }

        // FIX: strip commas before parsing the limit and the prospective value.
        const maxLimit = row ? toNumber(row.balanceFees) : 0;
        const potentialValue = toNumber(input.value + key);

        if (field !== 'balanceFees' && field !== 'defaultAmount' && field !== 'loginFee'
            && maxLimit > 0 && !isNaN(potentialValue) && potentialValue > maxLimit) {
            event.preventDefault();
            input.setCustomValidity(`Value cannot exceed ${maxLimit}.`);
            input.reportValidity();
            return;
        }

        input.setCustomValidity('');
        input.reportValidity();
    }

    /**
     * FIX (optional but recommended): validate pasted values too, since paste never fires
     * individual keydown events. Wire this with onpaste in the HTML if you want it.
     */
    handlePaste(event) {
        const input = event.target;
        const pasted = (event.clipboardData || window.clipboardData).getData('text');
        const cleaned = pasted.replace(/,/g, '');
        if (!/^\d*\.?\d*$/.test(cleaned)) {
            event.preventDefault();
            input.setCustomValidity('Only numeric values are allowed.');
            input.reportValidity();
            return;
        }
        input.setCustomValidity('');
    }

    handleBlur(event) {
        if (this.isHLUser && this.esignStatus == 'Esign Completed' && !this.confirmation) {
            this.showConfirmation = true;
        } if (this.isHLUser && this.esignStatus == 'Esign Completed' && this.confirmation) {
            this._applyBlurUpdate(event);
        } else if (!this.isHLUser || this.esignStatus != 'Esign Completed') {
            this._applyBlurUpdate(event);
        }
    }

    /**
     * FIX: the two near-identical blur branches in the original were collapsed into one
     * shared method to remove duplication and the divergent behaviour between them.
     */
    _applyBlurUpdate(event) {
        if (this.actualerror) {
            return;
        }
        getLoanProductRecords({ opportunityId: this.recordId })
            .then((data) => {
                data.forEach((row) => {
                    if (row.Final_ROI__c != row.Negotiated_ROI__c) {
                        this.isRoiChanged = true;
                    }
                });
            })
            .catch((error) => {
                console.error('Error fetching loan product records:', error);
            });

        this.isLoading = true;
        const rowId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;
        console.log('value:: ' + value);

        this.rows = this.rows.map((row) => {
            if (row.id === rowId) {
                row[field] = field === 'requestedAmount' ? toNumber(value) : value;
                console.log('row.originalName : ' + row.originalName);

                if (field === 'requestedAmount' && (row.Category === 'LOS' || row.Category === 'LMS')) {
                    if (value == 0 || value == null) {
                        row.chargesWaived = false;//sanwar
                    } else {
                        if (this.isHLUser) { // Arman: handle waiver amt in balance fees for HL
                            row.isAmountChangedByUser = true;
                            row.balanceFees = toNumber(row.balanceFees) - toNumber(value);
                            row.tax = 0;
                            row.chargesWaived = false;
                        } else {
                            row.chargesWaived = true;//sanwar
                        }
                    }
                }

                if (field === 'balanceFees' && row.Category === 'LOS') {
                    row.balanceFees = value;
                    row.isAmountChangedByUser = true;
                    row.tax = 0;
                }

                if (field === 'defaultAmount' && row.Category === 'LOS') {
                    if (!this.isHLUser && row.originalName == 'PROCFEE' && row.Category === 'LOS' &&
                        (row.productName == 'Affordable Home Loan' || row.productName == 'Affordable Non-Home Loan')) {
                        const maxProcFeeAmount = this.prodwiseMaxProcFeeAmtObj ? this.prodwiseMaxProcFeeAmtObj[row.productId] : undefined;
                        console.log('maxProcFeeAmount', maxProcFeeAmount);
                        if (maxProcFeeAmount !== undefined && toNumber(value) > toNumber(maxProcFeeAmount)) {
                            this.showToastMethod('Error', 'Please enter amount less than the max amount ' + maxProcFeeAmount, 'error');
                            this.isLoading = false;
                            this.loadChargesRecords();
                            return row;
                        } else {
                            row.defaultAmount = value;
                            row.isAmountChangedByUser = true;
                            row.balanceFees = toNumber(value) - toNumber(row.loginFee);
                            row.tax = 0;
                        }
                    } else {
                        row.defaultAmount = value;
                        row.isAmountChangedByUser = true;
                        row.balanceFees = toNumber(value) - toNumber(row.loginFee);
                        row.tax = 0;
                    }
                }

                if (field === 'loginFee' && row.Category === 'LOS') {
                    row.loginFee = value;
                    row.isAmountChangedByUser = true;
                    row.balanceFees = toNumber(row.defaultAmount) - toNumber(value);
                    row.tax = 0;
                    row.requestedAmount = 0;
                }

                row.minPercent = row.min ? parseFloat(row.min) / 100 : 0;
                row.maxPercent = row.max ? parseFloat(row.max) / 100 : 0;
                this.updateSingleChargeRecord(row);
            }
            return row;
        });

        setTimeout(() => {
            let isChargesWaivedonUI = (this.rows.find(item => item.chargesWaived) || this.isRoiChanged) ? true : false;//sanwar(23/12/2025)
            if (!this.isHLUser) { // Arman (6 Jan 2026): bypass approval initiation for HL during waiver
                const fields = {};
                fields['Id'] = this.recordId;
                fields['Is_Pricing_Approval_Required__c'] = isChargesWaivedonUI;
                this.updateRecordField(fields);
            } else {
                isChargesWaivedonUI = false;
            }
            console.log('isChargesWaivedonUI', isChargesWaivedonUI);
            this.dispatchEvent(new CustomEvent('enableapproval', {
                detail: { 'isChargesWaived': isChargesWaivedonUI }
            }));//Sanwar
        }, 1500);

        this.isLoading = false;
        console.log('updated row:: ' + JSON.stringify(this.rows));
    }

    /**
     * Recalculate total charges for every product bucket and persist.
     */
    recalculateTotalCharges() {
        this.consolidatedTotalFeeChargeRows = [];

        const buildBucket = (matchFn, targetRecord) => {
            let totalLOS = 0;
            let totalInsurance = 0;
            this.rows.forEach((row) => {
                if (matchFn(row)) {
                    if (row.Category === 'LOS') {
                        totalLOS += toNumber(row.finalAmount);
                    }
                    if (row.Category === 'Insurance') {
                        totalInsurance += toNumber(row.finalAmount);
                    }
                }
            });
            const unrounded = totalLOS + totalInsurance;
            const decimalPart = unrounded % 1;
            const rounded = decimalPart < 0.5 ? Math.floor(unrounded) : Math.ceil(unrounded);

            let updated = targetRecord;
            if (targetRecord) {
                updated = {
                    ...targetRecord,
                    Total_Charges__c: rounded,
                    Total_Fee_to_be_deducted__c: rounded
                };
                if (updated.Id) {
                    this.consolidatedTotalFeeChargeRows.push(updated);
                }
            }
            return { rounded, updated };
        };

        const ahl = buildBucket(
            r => (r.productName == 'Affordable Home Loan' || r.productName == 'Home Loan') && r.productType == 'Parent',
            this.totalFeeChargeRecordAHL
        );
        this.totalFeeChargeRecordAHL = ahl.updated;

        const ahlChild = buildBucket(
            r => (r.productName == 'Affordable Home Loan' || r.productName == 'Home Loan') && r.productType == 'Child',
            this.totalFeeChargeRecordAHLChild
        );
        this.totalFeeChargeRecordAHLChild = ahlChild.updated;

        const fl = buildBucket(
            r => r.productName == 'Flexi Loan',
            this.totalFeeChargeRecordFL
        );
        this.totalFeeChargeRecordFL = fl.updated;

        const anhl = buildBucket(
            r => (r.productName == 'Affordable Non-Home Loan' || r.productName == 'Non Home Loan') && r.productType == 'Parent',
            this.totalFeeChargeRecordANHL
        );
        this.totalFeeChargeRecordANHL = anhl.updated;

        const anhlChild = buildBucket(
            r => (r.productName == 'Affordable Non-Home Loan' || r.productName == 'Non Home Loan') && r.productType == 'Child',
            this.totalFeeChargeRecordANHLChild
        );
        this.totalFeeChargeRecordANHLChild = anhlChild.updated;

        const roundedTotalCharges = ahl.rounded + ahlChild.rounded + fl.rounded + anhl.rounded + anhlChild.rounded;

        if (this.totalFeeChargeRecord) {
            this.totalFeeChargeRecord = {
                ...this.totalFeeChargeRecord,
                Total_Charges__c: roundedTotalCharges,
                Total_Fee_to_be_deducted__c: roundedTotalCharges
            };
        }
        console.log('Updated Total Charges:', this.totalFeeChargeRecord);

        if (this.consolidatedTotalFeeChargeRows.length > 0) {
            this.updateTotalChargesInBackend();
        }
    }

    updateTotalChargesInBackend() {
        updateTotalCharges({
            totalChargesRecord: this.consolidatedTotalFeeChargeRows
        })
            .then(() => {
                console.log('Total Charges updated successfully in Salesforce');
            })
            .catch((error) => {
                console.error('Error updating Total Charges:', JSON.stringify(error));
            });
    }

    // Update a single Charge Record in Salesforce
    updateSingleChargeRecord(row) {
        console.log('updater--');
        console.log('row:: ' + JSON.stringify(row));
        this.actualerror = false;
        this.isLoading = true;

        const updatedRecord = {
            Id: row.id,
            Charges_Fee_Type__c: row.picklistApiValue,
            Loan_Application__c: row.Loan_Application,
            Max_Percent__c: row.max,
            Min_Percent__c: row.min,
            Category__c: row.Category
        };

        if (row.Category === 'LMS') {
            updatedRecord.Waived_Charge_Amount__c = row.requestedAmount;
            updatedRecord.Is_Charges_waived__c = row.chargesWaived;
        } else {
            let feeMethod = row.feeMethod == 'Deduct from Disbursement' ? 'DISB' : row.feeMethod;
            updatedRecord.Fee_Method__c = feeMethod;
            updatedRecord.Waived_Charge_Amount__c = row.requestedAmount;
            updatedRecord.Tax_INR__c = row.tax;
            if (row.isAmountChangedByUser) {
                updatedRecord.Final_Amount_INR__c = row.balanceFees;
                updatedRecord.Adjusted_Login_Fee__c = row.loginFee;
                updatedRecord.Allocated_Amount__c = row.defaultAmount;
            } else {
                updatedRecord.Final_Amount_INR__c = row.finalAmount;
            }
            updatedRecord.Is_Charges_waived__c = row.chargesWaived;//sanwar
            updatedRecord.Balance_Fees__c = row.balanceFees;//sanwar
        }
        console.log('updatedRecord:: ' + JSON.stringify(updatedRecord));

        if ((row.productName == 'Affordable Home Loan' || row.productName == 'Home Loan') && row.productType == 'Parent') {
            if (row.originalName == 'PROCFEE') this.balanceFees = this.balanceFeesAHL;
            else if (row.originalName == 'STFRCHG') this.balanceFees = this.balanceFeesStmpAHL;
        } else if ((row.productName == 'Affordable Home Loan' || row.productName == 'Home Loan') && row.productType == 'Child') {
            if (row.originalName == 'PROCFEE') this.balanceFees = this.balanceFeesAHLChild;
            else if (row.originalName == 'STFRCHG') this.balanceFees = this.balanceFeesStmpAHLChild;
        } else if (row.productName == 'Affordable Non-Home Loan' && row.productType == 'Parent') {
            if (row.originalName == 'PROCFEE') this.balanceFees = this.balanceFeesANHL;
            else if (row.originalName == 'STFRCHG') this.balanceFees = this.balanceFeesStmpANHL;
        } else if (row.productName == 'Affordable Non-Home Loan' && row.productType == 'Child') {
            if (row.originalName == 'PROCFEE') this.balanceFees = this.balanceFeesANHLChild;
            else if (row.originalName == 'STFRCHG') this.balanceFees = this.balanceFeesStmpANHLChild;
        } else if (row.productName == 'Flexi Loan') {
            if (row.originalName == 'PROCFEE') this.balanceFees = this.balanceFeesFL;
            else if (row.originalName == 'STFRCHG') this.balanceFees = this.balanceFeesStmpFL;
        }
        console.log('this.balanceFees' + JSON.stringify(this.balanceFees));

        updateChargesRecords({ updatedRecords: [updatedRecord], productId: row.productId, balanceFees: this.balanceFees })
            .then(() => {
                this.isLoading = false;
                this.showToast('Success', 'Record updated successfully', 'success');
                if (row.isAmountChangedByUser) {
                    let gstMetadata = this.metadataRows.filter(acc => acc.Charge_Name__c == row.originalName);
                    if (gstMetadata && gstMetadata.length > 0 && gstMetadata[0]?.Is_GST_Applicable__c) {
                        this.callGSTAPI(row);
                    } else {
                        this.loadChargesRecords();
                    }
                }
            })
            .catch((error) => {
                this.isLoading = false;
                console.log('Complete Error Object:', JSON.stringify(error));
                if (error.body && error.body.message) {
                    this.showToast('Error', error.body.message, 'error');
                    this.actualerror = true;
                } else {
                    this.showToast('Error', 'Failed to update record', 'error');
                    this.actualerror = true;
                }
                console.error('Error updating record:', JSON.stringify(error));
            });
    }

    handlePassAllSections() {
        this.mainAccordianActiveSection = ['Charges', 'LoandDetails', 'ApprovalHistory', 'SanctionLetter'];
        console.log('Active Accordion Sections:', this.mainAccordianActiveSection);
        this.showOpenAll = false;
    }

    handleCloseAllSections() {
        this.showOpenAll = true;
        this.mainAccordianActiveSection = [];
    }

    get showSelfFundedSection() {
        const allRows = [
            ...this.loSrows,
            ...this.insuranceRows,
            ...this.lMSrows
        ];
        return allRows.some(r => r.feeMethod === 'Self funded');
    }

    handleInputChangePSV(event) {
        const fieldName = event.target.name;
        const value = event.target.value;

        switch (fieldName) {
            case 'subReceiptMode':
                this.subReceiptMode = value;
                break;
            case 'receiptNumber':
                this.receiptValue = value;
                break;
            case 'transactionRefNumber':
                this.transactionRefNoValue = value;
                break;
            case 'remarks':
                this.Remarks = value;
                break;
        }
    }

    async handleSave() {
        let isValid = true;
        if (!this.Remarks || this.Remarks.trim() === '' || !this.transactionRefNoValue || this.transactionRefNoValue.trim() === '' || !this.subReceiptMode || this.subReceiptMode.trim() === '') {
            isValid = false;
        }
        const hasDocuments = this.documentList && this.documentList.length > 0;

        if (!hasDocuments && (this.uploadedFilesSales == null || this.uploadedFilesSales == undefined || !this.uploadedFilesSales || this.uploadedFilesSales.length === 0)) {
            console.log('933');
            this.showToastMethod('Error', 'Please upload the receipt.', 'error');
        }
        if (!isValid) {
            this.showToastMethod('Error', 'Please fill all required fields.', 'error');
            return;
        }

        console.log('line 273-->>', this.uploadedFilesSales.length);
        if ((this.uploadedFilesSales == null || this.uploadedFilesSales == undefined || !this.uploadedFilesSales || this.uploadedFilesSales.length === 0) && (!this.documentList || this.documentList.length === 0)) {
            this.showToastMethod('Error', 'Please upload the fee receipt.', 'error');
            return;
        }

        this.logFeeObj = {
            recordId: this.loginFeeId,
            loanId: this.recordId,
            receiptNo: this.receiptValue,
            transactionRef: this.transactionRefNoValue,
            subReceiptMode: this.subReceiptMode,
            remarks: this.Remarks
        };
        console.log('inputWrapper--160--', JSON.stringify(this.logFeeObj));

        try {
            await upsertLoginFeeRecord({ input: JSON.stringify(this.logFeeObj) });
            if (this.uploadedFilesSales && this.uploadedFilesSales.length >= 1) {
                await this.createDocumentChecklistForSales();
                this.uploadedFilesSales = [];
            }
            this.showToastMethod('Success', 'Record inserted Successfully.', 'success');
            this.showSaveButton = true;
            this.showRecords = true;
            this.hideAPIButton = true;
            this.hideNext = true;
        } catch (error) {
            this.showToastMethod('Error', error?.body?.message || error, 'error');
        }
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

    createDocumentChecklistForSales() {
        console.log('loanId- 676-----', this.recordId);
        const uploadParam = {
            'loanid': this.recordId,
            'docName': 'Upfront Charges Login Fee',
            'docRequiredFor': 'Self Funded',
            'docCategory': 'Additional Documents',
            'manualAA': 'Manual',
        };
        return createDocumentChecklistForSales({ uploadParam: uploadParam })
            .then(result => {
                if (result != null && result != '' && result != undefined) {
                    this.salesReturnedDocumentId = result;
                    this.uploadedFilesSales.forEach(file => {
                        this.uploadedFilesList.push({
                            id: file.documentId,
                            name: file.name,
                            downloadUrl: file.downloadUrl
                        });
                    });
                    for (var i = 0; i < this.uploadedFilesSales.length; i++) {
                        this.countOfDocument = this.countOfDocument + 1;
                        console.log('this.uploadedFilesSales294 ', JSON.stringify(this.uploadedFilesSales));
                        this.insertFileRecordToSalesforce(this.uploadedFilesSales[i]);
                    }
                }
            })
            .catch(error => {
                console.error('Error in createDocumentChecklistForSales:', error);
            });
    }

    async insertFileRecordToSalesforce(file) {
        await insertFileRecord({
            fileName: file.name,
            fileSize: file.size,
            fileContentDocumentId: file.documentId,
            recordId: this.salesReturnedDocumentId
        })
            .then(() => {
                this.getdocDetails();
                console.log('Document Inserted Successfully');
            })
            .catch((error) => {
                console.log('Error in inserting document--', error);
            });
    }

    handleView(event) {
        console.log('event323--', event.target.dataset.id);
        const documentId = event.target.dataset.id;
        console.log('documentId---324--', documentId);
        if (window.location.origin.includes('my.site.com')) {
            console.log('327if');
            this.url = window.open(window.location.origin + '/losportal/sfc/servlet.shepherd/document/download/' + documentId);
        } else {
            console.log('331else');
            if (documentId) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__namedPage',
                    attributes: { pageName: 'filePreview' },
                    state: { selectedRecordId: documentId }
                });
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'No file available for preview.',
                        variant: 'error',
                    }),
                );
            }
        }
    }

    /**
     * FIX: there were TWO handleDelete methods in the original file. The second silently
     * overrode the first, so the first (deleteContentDoctIdLoginFee path) never ran.
     * They have been merged into a single, consistent delete handler below using
     * deletecontentDocumentAndDocFile.
     */
    handleDelete(event) {
        console.log('event-------', event.target.dataset.id);
        console.log('event-2------', event.target.dataset.doc);
        const contentDocumentLinkId = event.target.dataset.id;
        const docChecklistId = event.target.dataset.doc;
        const fileName = event.target.dataset.name;
        console.log('line 470-->>', fileName);
        console.log('line 471-->>', contentDocumentLinkId);
        console.log('line 472-->>', docChecklistId);

        deletecontentDocumentAndDocFile({
            docId: docChecklistId,
            cdLId: contentDocumentLinkId
        }).then(result => {
            console.log('549 result----', result);
            if (result) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Document deleted Successfully.',
                        variant: 'success',
                    }),
                );

                this.uploadedFilesSales = this.uploadedFilesSales.filter(
                    file => file.documentId !== contentDocumentLinkId
                );
                this.uploadedFileName = this.uploadedFilesSales.map(file => file.name);

                console.log('line 576', JSON.stringify(this.uploadedFileName));
                console.log('line 577', JSON.stringify(this.uploadedFilesSales));
                this.isDisable = false;
                this.showDocumentName = false;
                this.showSaveButton = true;
                this.showRetryButton = false;

                // Also drop it from the rendered document list
                this.documentList = this.documentList.filter(r => r.contentId !== contentDocumentLinkId);

                if (this.uploadedFilesSales == null || this.uploadedFilesSales.length == 0) {
                    if (!this.documentList || this.documentList.length === 0) {
                        this.documentList = [];
                        this.showRecords = false;
                    }
                } else {
                    this.getdocDetails();
                }
            }
        })
            .catch(error => {
                console.log('error-->', error);
                this.showToastMethod('Error', error?.body?.message || 'Delete failed', 'error');
            });
    }

    getdocDetails() {
        console.log('86');
        getDocumentsList({ recordId: this.recordId, processName: 'Upfront Charges Login Fee' })
            .then(result => {
                if (result && result.length > 0) {
                    console.log('Original documentList:', JSON.stringify(result));
                    this.documentList = result;
                    this.isDisable = true;
                    this.selectedDocIds = [];
                    this.selectedDocList = [];

                    this.documentList.forEach(item => {
                        item.isSelected = true;
                        if (!this.selectedDocIds.includes(item.contentVersionId)) {
                            this.selectedDocIds.push(item.contentVersionId);
                            this.selectedDocList.push(item);
                        }
                    });

                    this.showRecords = this.documentList.length > 0;
                    console.log('382--');
                } else {
                    this.showRecords = false;
                }
            })
            .catch(error => {
                this.ShowLoader = false;
                this.showRecords = false;
                console.error('Error fetching document details:', error);
            });
    }

    handleUploadFinished(event) {
        this.countOfDocument = 0;
        const uploadedFiles = event.detail.files;
        this.UploadedFilesLength = uploadedFiles.length;

        const newRows = uploadedFiles.map(f => ({
            id: f.documentId, name: f.name, contentId: f.documentId, docName: 'Upfront Charges Login Fee'
        }));

        this.documentList = [...this.documentList, ...newRows];
        this.showRecords = this.documentList.length > 0;
        this.uploadedFilesSales = [...this.uploadedFilesSales, ...uploadedFiles];
        this.uploadedFileName = [...this.uploadedFileName, ...uploadedFiles.map(f => f.name)];
        this.showDocumentName = this.uploadedFileName.length > 0;
        this.showToastMethod('Success', 'Document uploaded successfully.', 'success');
        this.isDisable = true;
    }

    /**
     * FIX: added .catch and always clears loading; previously a rejected GST call left
     * isLoading stuck and showed no error.
     */
    callGSTAPI(row) {
        let gstMetadata = this.metadataRows.filter(acc => acc.Charge_Name__c == row.originalName);
        if (gstMetadata && gstMetadata.length > 0 && gstMetadata[0]?.Is_GST_Applicable__c) {
            const inputMap = {
                'loanId': this.recordId,
                'processName': 'CalculateGST',
                'productName': row.productId,
                'feeType': row.originalName,
                'isWaiverAmountCalc': 'false'
            };
            calculateGST({ inputMap: inputMap })
                .then((data) => {
                    console.log('data==>', data);
                    if (data == 'Success: GST calculation completed.') {
                        this.showToast('Success', 'GST calculation completed.', 'success');
                        this.isLoading = false;
                        this.loadChargesRecords();
                    } else {
                        console.log('line 549-->>');
                        this.hitGstMan = true;
                        this.showToast('Error', 'GST calculation failed. Please enter tax amount manually.', 'error');
                        this.isLoading = false;
                    }
                })
                .catch((error) => {
                    console.error('GST API error:', error);
                    this.hitGstMan = true;
                    this.showToast('Error', 'GST calculation failed. Please enter tax amount manually.', 'error');
                    this.isLoading = false;
                });
        } else {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    handleDefaultChange(event) {
        const rowId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;
        console.log('value:: ' + value);
        console.log('rowId:: ' + rowId);
        console.log('field:: ' + field);

        let los = [];
        this.rows.forEach(ele => {
            if (ele.Category === 'LOS') {
                if (ele.id == rowId) {
                    ele.defaultAmount = value;
                    ele.requestedAmount = value;
                    ele.finalAmount = value;
                }
                los.push(ele);
            }
        });

        this.loSrows = los;
        console.log('this.loSrows: ' + JSON.stringify(this.loSrows));
        this.recalculateTotalCharges();

        const fields = {};
        fields['Id'] = rowId;
        fields['Default_Amount_INR__c'] = value;
        fields['Requested_Amount_INR__c'] = value;
        fields['Final_Amount_INR__c'] = value;

        this.updateRecordField(fields);
    }

    updateRecordField(fields) {
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                console.log('Record updated successfully');
            })
            .catch(error => {
                console.error('Error updating record: ', error);
                console.log('Error updating record --> ' + JSON.stringify(error));
            });
    }

    handleTaxAmountChange(event) {
        try {
            const rowId = event.target.dataset.id;
            const field = event.target.dataset.field;
            const value = event.target.value;
            console.log('value:: ' + value);
            console.log('field:: ' + field);
            console.log('rowId:: ' + rowId);
            console.log('loSrows:: ' + JSON.stringify(this.loSrows));
            this.loSrows = this.loSrows.map((row) => {
                if (row.id === rowId) {
                    const oldTax = toNumber(row.tax);
                    const newTax = toNumber(value);
                    row.tax = value;
                    const baseAmount = toNumber(row.finalAmount) - oldTax;
                    row.finalAmount = baseAmount + newTax;
                    console.log('line 822--', row.finalAmount);
                    const fields = {};
                    fields['Id'] = rowId;
                    fields['Tax_INR__c'] = value;
                    fields['Final_Amount_INR__c'] = row.finalAmount;
                    this.updateRecordField(fields);
                }
                this.recalculateTotalCharges();
                return row;
            });
        } catch (error) {
            console.log('error', error);
        }
    }
}