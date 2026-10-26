import { LightningElement, track, api, wire } from 'lwc';
import updateInternalBSAToggle from '@salesforce/apex/COMM_ManualBankingController.updateInternalBSAToggle';
import getApplicantDetails from '@salesforce/apex/COMM_SalesLoginIncomeController.getApplicantDetails';
import ELIGIBLE_ICON from '@salesforce/resourceUrl/SuccessIconEligibility';
import uploadFile from '@salesforce/apex/COMM_SalesLoanLoginController.uploadFile';
import NOT_ELIGIBLE_ICON from '@salesforce/resourceUrl/RejectIconEligibility';
import getDocumentsList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getDocumentsList';
import createAccountAggregatorDocumentChecklist from '@salesforce/apex/COMM_SalesLoginIncomeController.createAccountAggregatorDocumentChecklist';
import sendAccountAggrequest from '@salesforce/apex/COMM_AccountAggregatorController.sendAccountAggrequest';
import checkLoanFacility from '@salesforce/apex/COMM_SalesLoanLoginController.checkLoanFacility';
import callNetBankingAPI from '@salesforce/apex/COMM_NetBankingController.initateNetBanking';
import initiateBSA from '@salesforce/apex/COMM_BankStatementAnalysisController.initiateBSA';
import initiateBSA1 from '@salesforce/apex/COMM_ManualBankingController.initiateBSA';

import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ACCOUNT_TYPE from '@salesforce/schema/Opportunity.Account_Type__c';
import checkAAStatus from '@salesforce/apex/COMM_SalesLoanLoginController.checkAAStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import checkExceptionStatus from '@salesforce/apex/COMM_SalesLoanLoginController.checkExceptionStatus';
import createDocumentDetailsRequest from '@salesforce/apex/COMM_SalesLoanActionsController.createDocumentDetailsRequest';
import { NavigationMixin } from 'lightning/navigation';
import deleteContentDoctId from '@salesforce/apex/COMM_SalesLoanLoginController.deleteContentDoctId';
import getErrorMessage from '@salesforce/apex/COMM_SalesLoanLoginController.getErrorMessage';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import byPassStageForWhitelisting from '@salesforce/apex/COMM_SalesLoanLoginController.byPassStageForWhitelisting';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import getNonInitiatedFiles from '@salesforce/apex/COMM_DocumentDetailsScreenController.getNonInitiatedFiles';
import isInitiatedBSA from '@salesforce/apex/COMM_BankStatementAnalysisController.isInitiatedBSA';

import resendAAConsentLink from '@salesforce/apex/COMM_AccountAggregatorController.resendAAConsentLink';

const AVI_COLORS = ['blue', 'violet', 'teal', 'rose'];

const BSA_STATUS_MAP = {
    success:   'spill spill--emerald',
    completed: 'spill spill--emerald',
    initiated: 'spill spill--amber',
    pending:   'spill spill--slate',
    error:     'spill spill--rose',
};

const AA_STATUS_MAP = {
    consent_approved:        'spill spill--emerald',
    'consent approved':      'spill spill--emerald',
    'consent received':      'spill spill--emerald',
    delivered:               'spill spill--emerald',
    'data ready':            'spill spill--emerald',
    completed:               'spill spill--emerald',
    consent_rejected:        'spill spill--rose',
    'consent rejected':      'spill spill--rose',
    'consent revoked':       'spill spill--rose',
    'consent expired':       'spill spill--rose',
    'partial ready':         'spill spill--amber',
    'partial data received': 'spill spill--amber',
    pending:                 'spill spill--amber',
    'partially pending':     'spill spill--amber',
    'consent sent':          'spill spill--amber',
};

function bsaCls(s) {
    if (!s) return 'spill spill--slate';
    return BSA_STATUS_MAP[s.toLowerCase()] || 'spill spill--slate';
}

function aaCls(s) {
    if (!s) return 'spill spill--slate';
    return AA_STATUS_MAP[s.toLowerCase()] || 'spill spill--slate';
}

function formatTimestamp(isoString) {
    if (!isoString) return '—';
    try {
        const d = new Date(isoString);
        const day   = String(d.getDate()).padStart(2, '0');
        const month = String(d.getMonth() + 1).padStart(2, '0');
        const year  = d.getFullYear();
        const hrs   = String(d.getHours()).padStart(2, '0');
        const mins  = String(d.getMinutes()).padStart(2, '0');
        return `${day}/${month}/${year} ${hrs}:${mins}`;
    } catch (e) {
        return isoString;
    }
}

function toInitials(name) {
    if (!name) return '?';
    const p = name.trim().split(/\s+/);
    return p.length > 1 ? (p[0][0] + p[1][0]).toUpperCase() : name.substring(0, 2).toUpperCase();
}

// ____GenAI: Generated code starts here - whitelist filter for the manual
// BSA statements table: only documents whose bank name / file name matches
// "Kotak 2 2" are shown. Scoped, exact-match filter per explicit request -
// not a general bank-statement detector.____
function isKotak22Doc(d) {
    const candidates = [
        d.bankName,
        d.name,
        ...((d.uploadedFiles || []).map(f => f.fileName)),
    ];
    return candidates.some(c => (c || '').toLowerCase().includes('kotak 2 2'));
}
// ____GenAI: Generated code ends here____

function maskAccountNumber(accNo) {
    if (!accNo) return null;
    const s = String(accNo).replace(/\s/g, '');
    if (s.length <= 4) return s;
    return '\u2022\u2022\u2022\u2022' + s.slice(-4);
}

function safeParseDate(s) {
    if (!s) return null;
    const normalized = typeof s === 'string' && s.indexOf('T') === -1
        ? s.replace(' ', 'T')
        : s;
    const t = new Date(normalized).getTime();
    return Number.isNaN(t) ? null : t;
}

const RESEND_WINDOW_MS = 24 * 60 * 60 * 1000;

export default class SalesLoginBSAScreenCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @api deviceType;
    @api activeSectionName;

    notEligibleIcon;
    eligibleIcon;

    @track selectedMethod = '';
    @track isAccountAggregator = false;
    @track isNetBanking = false;
    @track isManual = false;
    /* Custom "Statement method" dropdown open state. lightning-combobox was
       replaced with plain light-DOM markup for this field only, so its
       hover/text colors can be styled with normal CSS (the base component
       renders its listbox in native shadow DOM here, which blocks external
       CSS from reaching option text color). */
    @track isMethodOpen = false;

    loanFacility;
    allBsaInitiated = false;
    allBsaChecked = true;
    
    selectedDocIds = [];
    selectedManualDocIds = [];
    selectedDocList = [];
    hideBSAButton = false;
    passWord;
    bankDetails;

    @track passwordType = 'password';
    selectedId;
    selectedName;
    options = [];
    applicantList;
    documentList = [];

    showNoRecords = false;
    isRendered = false;
    openBSApopup = false;
    manualAA;
    aaResponse = {};
    showView = false;
    bsaResponse = {};
    showSpinner = false;
    openUploadPopup = false;
    openBSA = false;
    docId;
    showErrorListAA = false;
    openBankAccountModal = false;
    showNetBakingError = false;

    @track password = '';
    ShowLoader = false;
    recordTypeId;
    loanFacilityOptions = [];

    @track mobileNumber = '';
    @track eyeIcon = 'utility:hide';
    @track showData = false;

    errorList;
    errorListBSA;
    showErrorList = false;
    @track displayManualBank = true;
    showErrorBSA = false;
    renameButtonNetBanking = false;
    renameButtonAA = false;
    isAAComplete = false;
    isbSASuccess = false;
    showOD = false;
    showCC = false;
    sanctionLimit;
    drawingPower;
    disableLoanFacility = false;
    @track hasAAMobileNumber = false;
    accountType;
    contentDocId;

    showErrorMessageCallBack = false;
    channelName = '/event/Refresh_Event__e';
    subscription = {};
    isSmall = false;
    multipleDocumentChecklistId;
    isHit = false;
    isFieldDisable = false;

    perfiosErrorMessage;
    showPerfiosError = false;
    isFromCredit = false;
    showCreditPopUp = false;
    scannedCopy = false;
    uploadedFileNames = [];
    docMode = false;
    manualClick = false;

    // ---- one-time AA auto-trigger guard ----
    // Session-level latch. Even if the flow somehow re-enters the trigger path
    // in the same session, this prevents a second call. Persistence across
    // sessions is handled by _hasAAForApplicant() against server data.
    _aaAutoTriggered = false;

    _accState = {};
    _triggerState = {};

    @track groupedApplicants = [];

    methodOptions = [
        { label: 'Account Aggregator', value: 'Account Aggregator' },
        { label: 'Upload', value: 'Manual' },
    ];

    /* Display label for the custom "Statement method" dropdown trigger. */
    get selectedMethodLabel() {
        const found = this.methodOptions.find(o => o.value === this.selectedMethod);
        return found ? found.label : 'Select method';
    }

    /* methodOptions decorated with a per-row CSS class so the selected
       option can be highlighted without any deep-shadow selectors. */
    get decoratedMethodOptions() {
        return this.methodOptions.map(o => ({
            ...o,
            isSelected: o.value === this.selectedMethod,
            optionClass: 'method-select__option'
                + (o.value === this.selectedMethod ? ' method-select__option--selected' : ''),
        }));
    }

    scannedOptions = [
        { label: 'Yes', value: 'true' },
        { label: 'No', value: 'false' },
    ];

    get getClassByDeviceType() {
        return this.deviceType === 'Mobile' ? '' : 'custom-width';
    }

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    objectInfo({ data, error }) {
        if (data) this.recordTypeId = data.defaultRecordTypeId;
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: ACCOUNT_TYPE })
    wiredPicklistValues({ data, error }) {
        if (data) {
            this.loanFacilityOptions = [
                { label: 'Select an option', value: '' },
                ...data.values.map(i => ({ label: i.label, value: i.value })),
            ];
        }
    }

    connectedCallback() {
        this.isSmall = FORM_FACTOR === 'Small';
        this.notEligibleIcon = NOT_ELIGIBLE_ICON;
        this.eligibleIcon = ELIGIBLE_ICON;
        this.ShowLoader = true;
        setTimeout(() => { this.ShowLoader = false; }, 2000);
        this.getLoanStageData();
        // getdocDetails first, so documentList/docMode are populated before we
        // decide whether to auto-trigger AA in getApplicantDetailsData.
        this.getdocDetails(false).then(() => { this.getApplicantDetailsData(); });
        this.checkUserProfile();
        this.subscribeToPlatformEvent();
        this.getErrorMessageData();
        this.getNonInitiatedFilesData();
        this.checkIfAlreadyInitiated();
        document.addEventListener('click', this.handleMethodDocumentClick);
    }

    disconnectedCallback() {
        document.removeEventListener('click', this.handleMethodDocumentClick);
    }

    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            const style = document.createElement('style');
            style.innerText = `.forceContentModalPreviewPlayer .toolbar button,.forceContentModalPreviewPlayer .toolbar .previewerActionLink{display:none;}
            /* Line-format restyle for the Applicant / Contact number /
               Account type / Sanction limit / Scanned copy fields -
               converts the boxed dark fields to underline-only, matching
               the same conversion already applied elsewhere in the
               sales-login screens. Idle uses this screen's own border
               token color (#33455e), focus uses this screen's own blue
               accent (#2563EB) - only the box shape/border is changed,
               nothing else. */
            .slds-input,
            .slds-combobox__input {
                background-color: transparent !important;
                color: #ffffff !important;
                border: none !important;
                border-bottom: 1px solid #33455e !important;
                border-radius: 0 !important;
                box-shadow: none !important;
                outline: none !important;
                padding: 6px 2px !important;
                transition: none !important;
            }
            .slds-input:hover,
            .slds-input:active,
            .slds-input:disabled,
            .slds-combobox__input:hover,
            .slds-combobox__input:active,
            .slds-combobox__input:disabled {
                background-color: transparent !important;
                color: #ffffff !important;
                border: none !important;
                border-bottom: 1px solid #33455e !important;
                box-shadow: none !important;
            }
            .slds-input:focus,
            .slds-combobox__input:focus {
                background-color: transparent !important;
                border: none !important;
                border-bottom: 1px solid #2563EB !important;
                box-shadow: none !important;
            }
            .slds-form-element__label {
                color: #ffffff !important;
            }`;
            this.template.querySelector('.styleContainer')?.appendChild(style);
        }
    }

    getLoanStageData() {
        getLoanStage({ loanId: this.recordId }).catch(e => console.error(e));
    }

    subscribeToPlatformEvent() {
        subscribe(this.channelName, -1, () => { this.initialMethodCall(); })
            .then(r => { this.subscription = r; });
    }

    getErrorMessageData() {
        getErrorMessage({ recordId: this.recordId })
            .then(result => {
                if (result && result.length > 0) {
                    this.errorMessageCallBackList = result;
                    this.showErrorMessageCallBack = true;
                }
            })
            .catch(e => console.error(e));
    }

    checkUserProfile() {
        checkExceptionStatus({ loanId: this.recordId })
            .then(result => { if (result) this.isFieldDisable = true; })
            .catch(e => console.error(e));
    }

    checkIfAlreadyInitiated() {
        isInitiatedBSA({ recordId: this.recordId })
            .then(result => {
                if (result) {
                    this.openBSA = true;
                    this.showData = true;
                    this.isAccountAggregator = true;
                    this.selectedMethod = 'Account Aggregator';
                }
                this.isHit = false;
            })
            .catch(e => console.error(e));
    }

    initialMethodCall() {
        this.getLoanStageData();
        // Refresh docs FIRST, then applicant details. Previously these ran in
        // parallel, which allowed getApplicantDetailsData() to evaluate the
        // auto-trigger condition against stale documentList/docMode and
        // re-fire the AA request on every platform event.
        this.getdocDetails(false).then(() => { this.getApplicantDetailsData(); });
        this.checkUserProfile();
        this.getErrorMessageData();
        this.getNonInitiatedFilesData();
    }

    getNonInitiatedFilesData() {
        getNonInitiatedFiles({ loanId: this.recordId })
            .then(result => { this.uploadedFileNames = result; })
            .catch(() => {});
    }

    /**
     * True if the given applicant already has any Account Aggregator document
     * on the server. Used to guarantee AA auto-trigger happens at most once
     * in the entire lifetime of the loan for the primary applicant.
     */
    _hasAAForApplicant(applicantId) {
        if (!applicantId || !this.documentList || this.documentList.length === 0) {
            return false;
        }
        return this.documentList.some(d =>
            d.applicantId === applicantId
            && d.manualAA
            && d.manualAA.toLowerCase().includes('aa')
        );
    }

    getApplicantDetailsData() {
        getApplicantDetails({ recordId: this.recordId })
            .then(response => {
                this.applicantList = response;
                let primary = null;
                if (response && response.length > 0) {
                    this.options = response.map(a => ({ label: a.Applicant_Name__c, value: a.Id }));
                    primary = response.find(a => a.Applicant_Type__c === 'Primary Applicant');
                    if (primary) {
                        this.selectedId = primary.Id;
                        this.selectedName = primary.Applicant_Name__c;
                        this.mobileNumber = primary.Mobile_Number__c;
                    }
                }
                this._buildGrouped();

                // ---- one-time AA auto-trigger for the PRIMARY applicant ----
                // Guards, in order:
                //   1. Primary applicant exists.
                //   2. Session latch not already set (no re-fire this session).
                //   3. docMode is false — no doc is already in Automatic trigger mode.
                //   4. Primary has no existing AA document on the server
                //      (covers all prior sessions -> "once in entire life").
                //   5. Not in explicit docMode workflow.
                if (
                    primary
                    && !this._aaAutoTriggered
                    && !this.docMode
                    && !this._hasAAForApplicant(primary.Id)
                ) {
                    this._aaAutoTriggered = true; // latch BEFORE calling, to prevent races
                    this.initiateAA();
                }
            })
            .catch(e => console.error(e));
    }

    getdocDetails(fromCheckBSAStatus) {
        return getDocumentsList({ recordId: this.recordId, processName: 'Bank Statement' })
            .then(result => {
                if (result && result.length > 0) {
                    const pdfMap = new Map();
                    const nonPdf = [];

                    result.forEach(doc => {
                        const isPdf = doc.docName && doc.docName.toLowerCase().includes('pdf');
                        if (isPdf && doc.contentId) {
                            pdfMap.set(doc.contentId, doc.id);
                        } else {
                            nonPdf.push(doc);
                        }
                    });

                    nonPdf.forEach(doc => {
                        if (doc.fileType && doc.fileType.toLowerCase() === 'xml' && doc.aaContentDoc) {
                            let k = doc.aaContentDoc;
                            if (k.startsWith('[') && k.endsWith(']')) k = k.slice(1, -1);
                            doc.bankStatementPdfDocId = pdfMap.get(k) || doc.id;
                            
                            doc.bankStatementPreviewContentId = k;
                        } else {
                            doc.bankStatementPdfDocId = doc.id;
                            
                            doc.bankStatementPreviewContentId = doc.contentId;
                        }
                        doc.showButton = false;
                    });

                    this.documentList = nonPdf.filter(doc =>
                        !doc.uploadedFiles?.some(f => (f.fileName || '').toLowerCase().includes('json'))
                    );

                    const validIds = new Set(this.documentList.map(d => d.contentVersionId).filter(Boolean));
                    this.selectedDocIds = (this.selectedDocIds || []).filter(id => validIds.has(id));
                    this.selectedDocList = [];
                    this.allBsaInitiated = true;
                    this.hasAAMobileNumber = false;

                    this.documentList.forEach(item => {
                        this.allBsaChecked = false;
                        if (item.aaMobileNumber && item.aaMobileNumber.trim() !== '') this.hasAAMobileNumber = true;
                        if (!item.bsaInitated) { this.allBsaInitiated = false; this.allBsaChecked = true; }
                        item.isSelected = this.selectedDocIds.includes(item.contentVersionId);
                        item.toggleOn = item.internalBSA === 'yes';
                        item.toggleDisabled = item.bsaInitated || !item.internalBSA;
                        if (item.triggerMode === 'Automatic') this.docMode = true;
                    });

                    this.hideBSAButton = false;
                    this.showNoRecords = this.documentList.length > 0;

                    if (result.some(d => d.errorList && d.errorList.length > 0)) {
                        this.dispatchEvent(new CustomEvent('showbsaerror', { detail: {} }));
                    }

                    if (fromCheckBSAStatus && this.documentList.some(
                        d => d.bsaStatus === 'Initiated' && !(d.errorList && d.errorList.length > 0))) {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Info',
                            message: 'BSA response not available yet. Please try again.',
                            variant: 'warning',
                        }));
                    }

                    this._buildGrouped();
                } else {
                    this.showNoRecords = false;
                }
                this.ShowLoader = false;
            })
            .catch(e => { this.ShowLoader = false; this.showNoRecords = false; console.error(e); });
    }

    _buildGrouped() {
        if (!this.applicantList) return;

        const grouped = this.applicantList.map((applicant, idx) => {
            const allDocs = (this.documentList || []).filter(d => d.applicantId === applicant.Id);

            const manualDocs = allDocs
                .filter(d => !d.manualAA || !d.manualAA.toLowerCase().includes('aa'))
                // .filter(d => isKotak22Doc(d))
                .map((d, i) => ({ ...this._enrichDoc(d), sno: i + 1 }));

            // const manualSelectableIds = manualDocs
            //     .filter(d => !d.checkboxDisabled)
            //     .map(d => d.contentVersionId)
            //     .filter(Boolean);
            // const manualHasSelectable = manualSelectableIds.length > 0;
            // const manualAllSelected = manualHasSelectable
            //     && manualSelectableIds.every(id => this.selectedDocIds.includes(id));
            const manualSelectableIds = manualDocs
                .filter(d => !d.checkboxDisabled)
                .map(d => d.id)
                .filter(Boolean);

            const manualHasSelectable = manualSelectableIds.length > 0;

            const manualAllSelected = manualHasSelectable
                && manualSelectableIds.every(id => this.selectedManualDocIds.includes(id));
            const aaDocs = allDocs.filter(d => d.manualAA && d.manualAA.toLowerCase().includes('aa'));

            const triggerMap = new Map();
            aaDocs.forEach(d => {
                const key = d.perfiosTransactionId || d.id;
                if (!triggerMap.has(key)) triggerMap.set(key, []);
                triggerMap.get(key).push(d);
            });

            const triggerGroups = [];
            triggerMap.forEach((tdocs, handle) => {
                const filteredDocs = tdocs.length > 1
                    ? tdocs.filter(d => d.linkedReference && d.linkedReference.trim() !== '')
                    : tdocs;
                const docsToUse = filteredDocs.length > 0 ? filteredDocs : tdocs;
                const enriched = docsToUse.map((d, i) => ({ ...this._enrichDoc(d), sno: i + 1 }));
                const overall = this._overallAAStatus(enriched);
                const mobile = tdocs[0]?.aaMobileNumber || tdocs[0]?.applicantMobile || '—';
                const bankName = docsToUse[0]?.bankName || tdocs[0]?.bankName || '—';
                const hasErr = enriched.some(d => d.errorList && d.errorList.length > 0);
                const errCount = enriched.reduce((s, d) => s + (d.errorList ? d.errorList.length : 0), 0);
                const aaInitiatedDate = tdocs[0]?.aaInitiatedDate || null;

                const selectableIds = enriched
                    .filter(d => !d.checkboxDisabled)
                    .map(d => d.contentVersionId)
                    .filter(Boolean);
                const hasSelectable = selectableIds.length > 0;
                const allSelected = hasSelectable
                    && selectableIds.every(id => this.selectedDocIds.includes(id));

                

                const initiatedMs = safeParseDate(aaInitiatedDate);
                const withinResendWindow = initiatedMs != null
                    && (Date.now() - initiatedMs) <= RESEND_WINDOW_MS;
                const canResend = overall === 'Consent Sent'
                    && withinResendWindow
                    && mobile
                    && mobile !== '\u2014'; 

                triggerGroups.push({
                    consentHandle: handle,
                    bankName,
                    count: tdocs.length,
                    hasErrors: hasErr,
                    errorCount: errCount,
                    overallStatus: overall,
                    overallStatusCls: aaCls(overall),
                    mobileNumber: mobile,
                    aaInitiatedDate,
                    triggerTimestamp: aaInitiatedDate ? formatTimestamp(aaInitiatedDate) : '\u2014',
                    docs: enriched,
                    hasSelectable,
                    allSelected,
                    canResend,
                });
            });

            triggerGroups.sort((a, b) => {
                if (!a.aaInitiatedDate && !b.aaInitiatedDate) return 0;
                if (!a.aaInitiatedDate) return 1;
                if (!b.aaInitiatedDate) return -1;
                return new Date(b.aaInitiatedDate) - new Date(a.aaInitiatedDate);
            });

            
            
            const total = triggerGroups.length;
            triggerGroups.forEach((tg, i) => {
                const labelNum = total - i;             
                const colorIdx = Math.min(i + 1, 4);    
                tg.label = `Trigger ${labelNum}`;
                tg.labelCls = `trigger-label-t${colorIdx}`;
                const isOpen = this._triggerState[tg.consentHandle] !== undefined
                    ? this._triggerState[tg.consentHandle]
                    : i === 0;
                tg.isOpen     = isOpen;
                tg.headerCls  = isOpen ? 'trigger-header--open' : 'trigger-header';
                tg.chevronCls = isOpen ? 'chevron-icon--open' : 'chevron-icon';
            });

            const aaLinked = aaDocs.some(d =>
                d.acagregatorStatus && d.acagregatorStatus.toLowerCase().includes('consent_approved'));
            const bsaDone = allDocs.some(d => d.bsaInitated);

            const state = this._accState[applicant.Id];
            const isOpen = state ? state.isOpen : idx === 0;
            const activeTab = state ? state.activeTab : 'manual';
            const color = AVI_COLORS[idx % AVI_COLORS.length];

            return {
                applicantId: applicant.Id,
                applicantName: applicant.Applicant_Name__c,
                applicantType: applicant.Applicant_Type__c,
                initials: toInitials(applicant.Applicant_Name__c),
                colorKey: color,
                aaLinked,
                bsaDone,
                manualCount: manualDocs.length,
                aaCount: aaDocs.length,
                manualDocs,
                manualHasSelectable,
                manualAllSelected,
                triggerGroups,
                isOpen,
                activeTab,
                showManual: isOpen && activeTab === 'manual',
                showAA: isOpen && activeTab === 'aa',
                headerCls: isOpen ? 'appl-header--open' : 'appl-header',
                manualTabCls: activeTab === 'manual' ? 'tab-btn--active' : 'tab-btn',
                aaTabCls: activeTab === 'aa' ? 'tab-btn--active' : 'tab-btn',
                chevronCls: isOpen ? 'chevron-icon--open' : 'chevron-icon',
            };
        });

        this.groupedApplicants = grouped;
    }

    _enrichDoc(doc) {
        const aaRaw = (doc.acagregatorStatus || '').toLowerCase();
        const isAA = doc.manualAA && doc.manualAA.toLowerCase().includes('aa');
        const hasErrors = !!(doc.errorList && doc.errorList.length > 0);

        let bankStatusLabel, bankStatusCls;
        if (isAA) {
            if (aaRaw.includes('consent_approved') || aaRaw.includes('consent approved')) {
                bankStatusLabel = 'Verified'; bankStatusCls = 'spill spill--emerald';
            } else if (aaRaw.includes('rejected')) {
                bankStatusLabel = 'Rejected'; bankStatusCls = 'spill spill--rose';
            } else if (aaRaw.includes('delivered') || aaRaw.includes('data ready')) {
                bankStatusLabel = 'Delivered'; bankStatusCls = 'spill spill--emerald';
            } else {
                bankStatusLabel = 'Consent Sent'; bankStatusCls = 'spill spill--amber';
            }
        } else {
            bankStatusLabel = doc.bsaInitated ? 'Verified' : 'Pending';
            bankStatusCls = doc.bsaInitated ? 'spill spill--emerald' : 'spill spill--amber';
        }

        let resolvedBankName = doc.bankName;
        if (!resolvedBankName && doc.uploadedFiles && doc.uploadedFiles.length > 0) {
            const fn = doc.uploadedFiles[0].fileName || '';
            resolvedBankName = fn.replace(/\.[^.]+$/, '').trim() || null;
        }
        if (!resolvedBankName && doc.name) {
            resolvedBankName = doc.name;
        }
        resolvedBankName = resolvedBankName || '—';

        const maskedAccNo = maskAccountNumber(doc.MaskedAccountNumber);
        const hasMaskedAccNo = isAA && !!maskedAccNo;

        const hasUploadedFiles = !!(doc.uploadedFiles && doc.uploadedFiles.length > 0);
        const hasAAView = isAA && !!doc.showViewAA;
        const canView = hasUploadedFiles || hasAAView;

        const hasFile = hasUploadedFiles || !!doc.showViewAA;
        const checkboxDisabled = doc.bsaInitated || !hasFile;

        const isSelected = !!(doc.contentVersionId && this.selectedDocIds.includes(doc.contentVersionId));

        return {
            ...doc,
            isManualSelected: !!(
    doc.id &&
    this.selectedManualDocIds.includes(doc.id)
),
            bankName: resolvedBankName,
            maskedAccNo,
            hasMaskedAccNo,
            bankStatusLabel,
            bankStatusCls,
            bsaStatusCls: bsaCls(doc.bsaStatus),
            aaStatusLabel: doc.acagregatorStatus || 'Consent Sent',
            aaStatusCls: aaCls(doc.acagregatorStatus),
            hasErrors,
            canView,
            checkboxDisabled,
            isSelected,
        };
    }

    _overallAAStatus(docs) {
        if (!docs || docs.length === 0) return 'Consent Sent';
        const total = docs.length;

        const isDelivered = d => !!(d.uploadedFiles && d.uploadedFiles.length > 0) || !!d.showViewAA;

        const statuses = docs.map(d => (d.acagregatorStatus || '').toLowerCase().trim());
        const anyHas  = s => statuses.some(v => v.includes(s));

        if (anyHas('revoked'))  return 'Consent Revoked';
        if (anyHas('expired'))  return 'Consent Expired';

        const allApproved = statuses.every(s => s.includes('consent_approved') || s.includes('consent approved'));
        const allRejected = statuses.every(s => s.includes('consent_rejected') || s.includes('consent rejected'));
        if (allApproved) return 'Consent Received';
        if (allRejected) return 'Consent Rejected';

        const doneStatuses = ['ready', 'delivered', 'denied', 'timeout'];
        const isDone  = d => isDelivered(d) || doneStatuses.some(v => (d.acagregatorStatus || '').toLowerCase().includes(v));
        const isPending = d => !isDone(d);

        const pendingCount = docs.filter(isPending).length;
        const doneCount    = docs.filter(isDone).length;

        if (pendingCount === total) {
            return total > 1 ? 'Pending' : 'Consent Sent';
        }
        if (doneCount === total) return 'Completed';
        if (pendingCount > 0)    return 'Partially Pending';

        if (statuses.every(s => s === statuses[0]) && statuses[0]) {
            return statuses[0].charAt(0).toUpperCase() + statuses[0].slice(1);
        }
        const freq = {};
        statuses.forEach(s => { freq[s] = (freq[s] || 0) + 1; });
        const majority = Object.entries(freq).sort((a, b) => b[1] - a[1])[0][0];
        const label = majority.charAt(0).toUpperCase() + majority.slice(1);
        return `Partially ${label}`;
    }

    toggleApplicantAcc(event) {
        const id = event.currentTarget.dataset.id;
        const cur = this._accState[id] || { isOpen: false, activeTab: 'manual' };
        this._accState[id] = { ...cur, isOpen: !cur.isOpen };
        this._buildGrouped();
    }

    switchTab(event) {
        const id = event.currentTarget.dataset.id;
        const tab = event.currentTarget.dataset.tab;
        this._accState[id] = { isOpen: true, activeTab: tab };
        this._buildGrouped();
    }

    toggleTriggerAcc(event) {
        const handle = event.currentTarget.dataset.id;
        const cur = this._triggerState[handle] !== undefined ? this._triggerState[handle] : true;
        this._triggerState[handle] = !cur;
        this._buildGrouped();
    }

    

    _syncSelectionToDocs() {
        this.documentList = this.documentList.map(doc => ({
            ...doc,
            isSelected: this.selectedDocIds.includes(doc.contentVersionId),
        }));
    }

    handleCheckboxChange(event) {
        const vid = event.target.dataset.id;
        const isChecked = event.target.checked;

        event.stopPropagation();

        if (isChecked) {
            if (vid && !this.selectedDocIds.includes(vid)) {
                this.selectedDocIds = [...this.selectedDocIds, vid];
            }
        } else {
            this.selectedDocIds = this.selectedDocIds.filter(id => id !== vid);
        }
        this._syncSelectionToDocs();
        this._buildGrouped();
    }

    handleManualCheckboxChange(event) {
    const docId = event.target.dataset.id;
    const checked = event.target.checked;

    if (checked) {
        this.selectedManualDocIds = [
            ...this.selectedManualDocIds.filter(id => id !== docId),
            docId
        ];
    } else {
        this.selectedManualDocIds =
            this.selectedManualDocIds.filter(id => id !== docId);
    }

    this._buildGrouped();
}
    // handleSelectAllManual(event) {
    //     event.stopPropagation();
    //     const applicantId = event.currentTarget.dataset.applicant;
    //     const checked = event.target.checked;
    //     const app = this.groupedApplicants.find(a => a.applicantId === applicantId);
    //     if (!app) return;

    //     const selectableIds = app.manualDocs
    //         .filter(d => !d.checkboxDisabled)
    //         .map(d => d.contentVersionId)
    //         .filter(Boolean);

    //     if (checked) {
    //         const merged = new Set([...this.selectedDocIds, ...selectableIds]);
    //         this.selectedDocIds = Array.from(merged);
    //     } else {
    //         const toRemove = new Set(selectableIds);
    //         this.selectedDocIds = this.selectedDocIds.filter(id => !toRemove.has(id));
    //     }
    //     this._syncSelectionToDocs();
    //     this._buildGrouped();
    // }

    handleSelectAllManual(event) {
    event.stopPropagation();

    const applicantId = event.currentTarget.dataset.applicant;
    const checked = event.target.checked;

    const app = this.groupedApplicants.find(
        a => a.applicantId === applicantId
    );

    if (!app) return;

    const selectableIds = app.manualDocs
        .filter(d => !d.checkboxDisabled)
        .map(d => d.id)
        .filter(Boolean);

    if (checked) {
        const merged = new Set([
            ...this.selectedManualDocIds,
            ...selectableIds
        ]);

        this.selectedManualDocIds = Array.from(merged);
    } else {
        const toRemove = new Set(selectableIds);

        this.selectedManualDocIds =
            this.selectedManualDocIds.filter(
                id => !toRemove.has(id)
            );
    }

    this._buildGrouped();
}

    handleSelectAllTrigger(event) {
        event.stopPropagation();
        const consentHandle = event.currentTarget.dataset.trigger;
        const applicantId = event.currentTarget.dataset.applicant;
        const checked = event.target.checked;

        const app = this.groupedApplicants.find(a => a.applicantId === applicantId);
        if (!app) return;
        const trigger = app.triggerGroups.find(t => t.consentHandle === consentHandle);
        if (!trigger) return;

        const selectableIds = trigger.docs
            .filter(d => !d.checkboxDisabled)
            .map(d => d.contentVersionId)
            .filter(Boolean);

        if (checked) {
            const merged = new Set([...this.selectedDocIds, ...selectableIds]);
            this.selectedDocIds = Array.from(merged);
        } else {
            const toRemove = new Set(selectableIds);
            this.selectedDocIds = this.selectedDocIds.filter(id => !toRemove.has(id));
        }
        this._syncSelectionToDocs();
        this._buildGrouped();
    }

    handleInternalBSAToggle(event) {
        const isChecked = event.target.checked;
        const docId = event.target.dataset.id;
        updateInternalBSAToggle({ documentId: docId, toggleValue: isChecked ? 'yes' : 'no' })
            .catch(e => console.error(e));
    }

    handleMethodChange(event) {
        event.stopPropagation();
        this.selectedMethod = event.detail.value;
        this.isAccountAggregator = this.selectedMethod === 'Account Aggregator';
        this.isNetBanking = this.selectedMethod === 'Net Banking';
        this.isManual = this.selectedMethod === 'Manual';
        this.openBSA = !!(this.isAccountAggregator || this.isManual || this.isNetBanking);
        this.showData = !!this.selectedMethod;
        if (this.isManual) this.checkLoanFacility();
    }

    /* Opens/closes the custom "Statement method" dropdown. */
    toggleMethodDropdown(event) {
        event.stopPropagation();
        if (this.isFieldDisable) return;
        this.isMethodOpen = !this.isMethodOpen;
    }

    /* Fires the same handleMethodChange logic the base lightning-combobox
       used to trigger via onchange, with a synthetic event carrying the
       same detail.value shape so no downstream logic needed to change. */
    selectMethod(event) {
        event.stopPropagation();
        const value = event.currentTarget.dataset.value;
        this.isMethodOpen = false;
        this.handleMethodChange({ stopPropagation: () => {}, detail: { value } });
    }

    /* Closes the dropdown when the user clicks anywhere outside it. */
    handleMethodDocumentClick = (event) => {
        if (!this.isMethodOpen) return;
        const container = this.template.querySelector('.method-select');
        if (container && !container.contains(event.target)) {
            this.isMethodOpen = false;
        }
    };

    handleChange(event) {
        event.stopPropagation();
        this.selectedId = event.detail.value;
        this.selectedName = event.detail.label;
        const app = this.applicantList?.find(a => a.Id === this.selectedId);
        if (app) this.mobileNumber = app.Mobile_Number__c;
        this.renameButtonAA = false;
        this.showErrorListAA = false;
        console.log ('renameButtonAA>>',renameButtonAA);
    }

    handleMobileNumberChange(event) {
        event.stopPropagation();
        this.mobileNumber = event.target.value;
    }

    initiateAA(event) {
        if (event) { this.manualClick = true; //event.stopPropagation(); 
            }
        if (this.mobileNumber) {
            this.sendAccountAggRequest();
        } else {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error', message: 'Please fill mobile number to proceed', variant: 'error',
            }));
        }
    }

    sendAccountAggRequest() {
        this.ShowLoader = true;
        const inputMap1 = {
            applicantId: this.selectedId,
            recordId: this.recordId,
            docId: this.docId,
            mobileNumber: this.mobileNumber,
            processName: 'Loan Applicant Account Aggregator',
            manualClick: this.manualClick,
        };
        sendAccountAggrequest({ inputMap1 })
            .then(result => {
                this.ShowLoader = false;
                if (result && result.includes('Error:')) {
                    this.showErrorListAA = true;
                    this.errorList = result;
                    this.renameButtonAA = false;
                } else {
                    this.renameButtonAA = true;
                    this.showErrorListAA = false;
                    this.getdocDetails(false);
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success', message: 'Account Aggregator initiated successfully', variant: 'success',
                    }));
                }
            })
            .catch(e => {
                this.ShowLoader = false;
                this.showErrorListAA = true;
                this.errorList = e?.body?.message || 'Error sending AA request';
            });
    }

    handleInitiateBSA1() {

    if (!this.selectedManualDocIds || this.selectedManualDocIds.length === 0) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: 'Please select a bank statement first.',
            variant: 'error'
        }));
        return;
    }

    const documentId = this.selectedManualDocIds[0];

    console.log('Document Details Id:', documentId);

    initiateBSA1({
        documentId: documentId
    })
    .then(() => {

        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'BSA initiated successfully.',
            variant: 'success'
        }));

        // Clear selection
        this.selectedManualDocIds = [];

        // Refresh table
        return this.getdocDetails(false);
    })
    .catch(error => {

        console.error('Initiate BSA Error:', error);

        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: error?.body?.message || 'Failed to initiate BSA.',
            variant: 'error'
        }));
    });
}
    handleInitiateBSA(event) {
        this.showErrorBSA = false;
        this.errorListBSA = '';
        if (event) event.stopPropagation();

        if (!this.selectedDocIds || this.selectedDocIds.length === 0) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error', message: 'Please select at least one statement to proceed', variant: 'error',
            }));
            return;
        }

        if (!this.isFromCredit) {
            this.ShowLoader = true;
            this._initiateBSAForSelectedDocs();
        } else {
            this.showCreditPopUp = true;
        }
    }

    _initiateBSAForSelectedDocs() {
        
        const docIds = [...this.selectedDocIds];

        const runs = docIds.map(id => this._runBSAForSingleDoc(id));

        Promise.all(runs)
            .then(results => {
                this.ShowLoader = false;

                const successful = results.filter(r => r.success);
                const failed = results.filter(r => !r.success);

                if (failed.length === 0) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: `BSA initiated successfully for ${successful.length} statement(s)`,
                        variant: 'success',
                    }));
                } else if (successful.length === 0) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: `BSA initiation failed for all ${failed.length} statement(s)`,
                        variant: 'error',
                    }));
                    this.showErrorBSA = true;
                    this.errorListBSA = failed
                        .map(f => f.error)
                        .filter(Boolean)
                        .join(' | ') || 'BSA initiation failed';
                } else {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Partial Success',
                        message: `BSA initiated for ${successful.length} statement(s), failed for ${failed.length}`,
                        variant: 'warning',
                        mode: 'sticky',
                    }));
                    this.showErrorBSA = true;
                    this.errorListBSA = failed
                        .map(f => f.error)
                        .filter(Boolean)
                        .join(' | ');
                }

                const perfios = results.find(r => !r.success && r.perfios);
                if (perfios) {
                    this.showPerfiosError = true;
                    this.perfiosErrorMessage = perfios.error;
                }

                this.selectedDocIds = [];
                this.getdocDetails(false);
                if (this.isManual) this.checkLoanFacility();
            })
            .catch(e => {

                this.ShowLoader = false;
                this.showErrorBSA = true;
                this.errorListBSA = e?.body?.message || 'Unexpected error occurred';
            });
    }

    _runBSAForSingleDoc(contentVersionId) {
        return createDocumentDetailsRequest({
            documentChecklistId: JSON.stringify([contentVersionId]),
            recordId: this.recordId,
        })
            .then(result => {
                const inputMap = {
                    recordId: this.recordId,
                    applicantId: this.selectedId,
                    processName: 'Loan Applicant Bank Statement Analysis',
                    selectedDocList: JSON.stringify([contentVersionId]),
                    drawingPower: this.drawingPower,
                    newDocumentDetails: JSON.stringify(result),
                    scannedCopy: this.scannedCopy,
                };
                return initiateBSA({ inputMap });
            })
            .then(result => {
                if (!result) {
                    return { success: true, docId: contentVersionId };
                }
                if (result.includes && result.includes('Perfios Error:')) {
                    return {
                        success: false,
                        docId: contentVersionId,
                        perfios: true,
                        error: result.replace('Perfios Error:', '').trim(),
                    };
                }
                if (result.includes && result.includes('Error:')) {
                    return {
                        success: false,
                        docId: contentVersionId,
                        error: result.replace('Error:', '').trim(),
                    };
                }
                return { success: true, docId: contentVersionId };
            })
            .catch(e => ({
                success: false,
                docId: contentVersionId,
                error: e?.body?.message || 'Unexpected error occurred',
            }));
    }

    handleConfirm() {
        this.showCreditPopUp = false;
        this.ShowLoader = true;
        this._initiateBSAForSelectedDocs();
    }

    checkLoanFacility() {
        checkLoanFacility({ loanId: this.recordId })
            .then(result => {
                if (!result) return;
                if (result.bsaInitiated === 'false') {
                    this.disableLoanFacility = true;
                    this.loanFacility = result.loanFacility;
                    this.sanctionLimit = result.sanctionLimit;
                    this.showOD = ['CC', 'OD'].includes(this.loanFacility);
                    const opt = this.loanFacilityOptions.find(o => o.value === this.loanFacility);
                    this.accountType = opt ? opt.label : null;
                    this.template.querySelector('c-add-bank-account-cmp')?.changeAccountType(this.accountType);
                } else {
                    this.disableLoanFacility = false;
                    this.showOD = false;
                    this.loanFacility = '';
                    this.sanctionLimit = '';
                }
            })
            .catch(e => console.error(e));
    }

    handleLoanFacility(event) {
        this.loanFacility = event.detail.value;
        const opt = this.loanFacilityOptions.find(o => o.value === this.loanFacility);
        if (opt) {
            this.accountType = opt.label;
            this.template.querySelector('c-add-bank-account-cmp')?.changeAccountType(this.accountType);
        }
        this.showOD = ['CC', 'OD'].includes(this.loanFacility);
    }

    handleSanctionLimitChange(event) { this.sanctionLimit = event.target.value; }

    openCamera(event) {
        if (!this.loanFacility) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error', message: 'Please select loan facility to proceed', variant: 'error',
            }));
            return;
        }
        this.fromDate = event.detail.fromDate;
        this.toDate = event.detail.toDate;
        this.passWord = event.detail.passWord;
        this.drawingPower = event.detail.drawingPower;
        this.multipleDocumentChecklistId = event.detail.documentChecklistId;
        this.manualAA = 'Manual';
        this.bankDetails = event.detail.bankdetail;
        if (this.isManual) this.checkLoanFacility();
        this.handleUpload();
    }

    handleUpload() {
        const uploadParam = {
            loanid: this.recordId,
            docName: '12 months bank statement',
            otherDocName: '',
            docRequiredFor: 'Income Bank Statement',
            docCategory: 'Banking',
            docLinkRecodId: this.selectedId,
            contentDocId: this.contentDocId,
            manualAA: this.manualAA,
            bank: this.selectedBank,
            password: this.passWord,
            toDate: this.toDate,
            fromDate: this.fromDate,
            bankDetails: this.bankDetails,
            drawingPower: this.drawingPower,
            multipleFilesDocumentId: this.multipleDocumentChecklistId,
            sanctionLimit: this.sanctionLimit,
            accountType: this.accountType,
        };
        uploadFile({ uploadParam })
            .then(() => {
                this.openUploadPopup = false;
                this.passWord = '';
                this.fromDate = '';
                this.toDate = '';
                this.bankDetails = '';
                this.contentDocId = '';
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success', message: 'Statement uploaded successfully', variant: 'success',
                }));
                this.checkLoanFacility();
                this.template.querySelector('c-add-bank-account-cmp')
                    ?.refreshComponent(this.selectedId, this.selectedName, this.isManual);
                this.initialMethodCall();
            })
            .catch(e => { this.openUploadPopup = false; console.error(e); });
    }

    handleView(event) {
        const fileId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: { pageName: 'filePreview' },
            state: { selectedRecordId: fileId },
        });
    }

    handleDeleteDoc() { this.getdocDetails(false); }

    checkAAStatus(event) {
        const docId = event.currentTarget.dataset.docid;
        this.ShowLoader = true;
        const matchedDoc = this.documentList.find(d => d.id === docId);
        const applicantId = matchedDoc ? matchedDoc.applicantId : this.selectedId;
        const inputMap = { recordId: this.recordId, applicantId, docId };
        checkAAStatus({ inputMap })
            .then(result => {
                this.ShowLoader = false;
                this.isAAComplete = result.isAACompleted;
                if (result.recordFound) {
                    if (this.isAAComplete) {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Success',
                            message: 'Account Aggregator Consent has been received. Please wait while the files are being received.',
                            variant: 'success',
                        }));
                    } else if (result.statusAA && result.statusAA.toLowerCase() !== 'pending') {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Status',
                            message: 'Account Aggregator Status: ' + result.statusAA,
                            variant: 'warning',
                        }));
                    } else {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Notice',
                            message: 'Account Aggregator consent is pending from the customer. Please ask the customer to complete the consent to proceed.',
                            variant: 'warning',
                        }));
                    }
                } else {
                    this.getdocDetails(false);
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: 'Account Aggregator completed successfully',
                        variant: 'success',
                    }));
                }
            })
            .catch(e => {
                this.ShowLoader = false;
                console.error(e);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Something went wrong while checking AA status',
                    variant: 'error',
                }));
            });
    }

    checkBSAStatus() { this.getdocDetails(true); }

    handleRefreshData(event) {
        event.stopPropagation();
        this.ShowLoader = true;
        this.getdocDetails(false);
    }

    handleConfirmError() {
        byPassStageForWhitelisting({ loanId: this.recordId })
            .then(() => {
                this.showPerfiosError = false;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success', message: 'Journey continued', variant: 'success',
                }));
            })
            .catch(e => console.error(e));
    }

    
    
    handleResendLink(event) {
        event.stopPropagation();

        const applicantId = event.currentTarget.dataset.applicant;
        const mobileNumber = event.currentTarget.dataset.mobile;
        const consentHandle = event.currentTarget.dataset.trigger;

        if (!mobileNumber || mobileNumber === '\u2014') {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Mobile number is not available for this trigger',
                variant: 'error',
            }));
            return;
        }

        this.ShowLoader = true;
        resendAAConsentLink({
            recordId: this.recordId,
            applicantId,
            mobileNumber,
            consentHandle,
        })
            .then(result => {
                this.ShowLoader = false;
                if (result && typeof result === 'string' && result.startsWith('Error:')) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Unable to resend',
                        message: result.replace('Error:', '').trim(),
                        variant: 'error',
                    }));
                } else {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: 'Consent link has been resent to the customer',
                        variant: 'success',
                    }));
                    
                    this.getdocDetails(false);
                }
            })
            .catch(e => {
                this.ShowLoader = false;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: e?.body?.message || 'Failed to resend consent link',
                    variant: 'error',
                }));
            });
    }

    handleChooseScannedCopy(event) { this.scannedCopy = event.detail.value === 'true'; }

    modalClose() { this.showCreditPopUp = false; }

    handleStopPropgation(event) { event.stopPropagation(); }

    handleNavigateNext() { this.dispatchEvent(new CustomEvent('navigatenext')); }

    closeBankAccount() { this.openBankAccountModal = false; }
}