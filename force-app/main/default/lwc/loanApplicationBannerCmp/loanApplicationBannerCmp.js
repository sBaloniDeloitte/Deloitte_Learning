/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue, updateRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import NAME_FIELD from '@salesforce/schema/Opportunity.Name';
import ID_FIELD from '@salesforce/schema/Opportunity.Id';
import BRANCH_ID_FIELD from '@salesforce/schema/Opportunity.Branch_Master__c';
import BRANCH_NAME_FIELD from '@salesforce/schema/Opportunity.Branch_Master__r.Name';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import SUBSTAGE_FIELD from '@salesforce/schema/Opportunity.Sub_stage__c';
import INCOME_APPROVAL_FIELD from '@salesforce/schema/Opportunity.Income_Approval_Status__c';
import LOAN_STATUS_FIELD from '@salesforce/schema/Opportunity.Approval_Status__c';
import TOGGLE_HOME_FIELD from '@salesforce/schema/Opportunity.toggleHomePage__c';

// Name of the "Raise a Query" screen Flow used behind the Quick Action of the same name
// on the standard Opportunity page layout (Setup > Object Manager > Loan Application >
// Buttons, Links, and Actions > Raise A Query).
const RAISE_A_QUERY_FLOW_API_NAME = 'Raise_a_Query_Quick_Action_button';

// Fields fetched via the wire service for reactive, cache-friendly record data (LWC guideline: use wire for reactive data fetching)
const OPPORTUNITY_FIELDS = [
    NAME_FIELD,
    BRANCH_ID_FIELD,
    BRANCH_NAME_FIELD,
    STAGE_FIELD,
    SUBSTAGE_FIELD,
    INCOME_APPROVAL_FIELD,
    LOAN_STATUS_FIELD,
    TOGGLE_HOME_FIELD
];

export default class LoanApplicationBannerCmp extends NavigationMixin(LightningElement) {
    @api recordId;

    // Controls which quick-action screen is currently mounted. Only one of these is
    // ever true at a time, driven purely by the corresponding button click handler.
    @track showReassignModal = false;
    @track showRejectModal = false;
    @track showQueryModal = false;
    @track showSendBackModal = false;
    @track showAssignToCmModal = false;
    @track showMarkCompleteModal = false;
    @track showPushToLmsModal = false;

    @wire(getRecord, { recordId: '$recordId', fields: OPPORTUNITY_FIELDS })
    loanApplication;

    get loanName() {
        return getFieldValue(this.loanApplication.data, NAME_FIELD) || '--';
    }

    get branchId() {
        return getFieldValue(this.loanApplication.data, BRANCH_ID_FIELD);
    }

    get branchName() {
        return getFieldValue(this.loanApplication.data, BRANCH_NAME_FIELD) || '--';
    }

    get stage() {
        return getFieldValue(this.loanApplication.data, STAGE_FIELD) || '--';
    }

    get subStage() {
        return getFieldValue(this.loanApplication.data, SUBSTAGE_FIELD) || '--';
    }

    get incomeApprovalStatus() {
        return getFieldValue(this.loanApplication.data, INCOME_APPROVAL_FIELD) || '--';
    }

    get loanApplicationStatus() {
        return getFieldValue(this.loanApplication.data, LOAN_STATUS_FIELD) || '--';
    }

    // Plain white text, no colored pill/badge - status values render the same
    // way as every other field value in this banner (Branch Master, Stage, etc.).
    get incomeStatusClass() {
        return 'loan-banner__field-value';
    }

    get loanStatusClass() {
        return 'loan-banner__field-value';
    }

    // Quick-action buttons (Reassign / Detail Screen / Reject Loan / Raise a Query) are shown
    // only while the Loan Application is in a Sales stage. Click handlers are placeholders for
    // now -- the target component/behavior for each action will be wired in a follow-up change.
    get showSalesStageActions() {
        const currentStage = this.stage;
        return !!currentStage && currentStage !== '--' && currentStage.toLowerCase().includes('sales');
    }

    // True while the record is showing the "Detail Screen" (toggleHomePage__c = true),
    // in which case the Detail Screen button is swapped for "Continue Journey" so the
    // user has a way back to the main Process Journey screen.
    get isOnDetailScreen() {
        return getFieldValue(this.loanApplication.data, TOGGLE_HOME_FIELD) === true;
    }

    // "Send Back" and "Assign To CM" are shown only while the Loan Application is in
    
    get showCreditStageActions() {
        return this.stage === 'Credit Underwriting';
    }

    // Assign To CM is further restricted to only the "Credit Processing Verification"
    // sub stage - not shown for any other Sub Stage value even within Credit Underwriting.
    get showAssignToCmButton() {
        return this.showCreditStageActions && this.subStage === 'Credit Processing Verification';
    }

    // PSV stage shows a different button set entirely: Reassign, Mark As Complete,
    // Send Back, Raise A Query - no Reject Loan, no Assign To CM.
    get isPsvStage() {
        return this.stage === 'PSV';
    }

    // Disbursement stage, "Ops Maker" sub stage shows the same restricted button set as
    // PSV: Reassign, Mark As Complete, Send Back, Raise A Query - no Reject Loan, no
    // Assign To CM, and not shown for any other Disbursement sub stage.
    // NOTE: the org's actual StageName picklist value is spelled "Disbursment" (no
    // middle "e") - matching against "Disbursement" never fired. Checking both spellings
    // keeps this working regardless of which one is actually configured on the picklist.
    get isDisbursementOpsMakerStage() {
        const currentStage = this.stage;
        const isDisbursementStage = currentStage === 'Disbursement' || currentStage === 'Disbursment';
        return isDisbursementStage && this.subStage === 'Ops Maker';
    }

    // Disbursement stage, "Ops Author" sub stage shows a further-restricted button set:
    // Reassign, Send Back, Raise A Query, Push to LMS - no Reject Loan, no Assign To CM,
    // no Mark As Complete, and not shown for any other Disbursement sub stage. Uses the
    // same dual-spelling stage check as Ops Maker above (org value is "Disbursment").
    get isDisbursementOpsAuthorStage() {
        const currentStage = this.stage;
        const isDisbursementStage = currentStage === 'Disbursement' || currentStage === 'Disbursment';
        return isDisbursementStage && this.subStage === 'Ops Author';
    }

    // Gates whether the shared action row renders at all - true for any of the stages
    // this banner has action buttons for.
    get showCommonStageActions() {
        return this.showSalesStageActions || this.showCreditStageActions || this.isPsvStage
            || this.isDisbursementOpsMakerStage || this.isDisbursementOpsAuthorStage;
    }

    // Reject Loan is only for Sales / Credit Underwriting - explicitly excluded on PSV
    // and on Disbursement (Ops Maker / Ops Author).
    get showRejectLoanButton() {
        return this.showSalesStageActions || this.showCreditStageActions;
    }

    // Send Back appears on Credit Underwriting, PSV, and Disbursement (Ops Maker / Ops Author).
    get showSendBackButton() {
        return this.showCreditStageActions || this.isPsvStage || this.isDisbursementOpsMakerStage || this.isDisbursementOpsAuthorStage;
    }

    // Push to LMS is Disbursement (Ops Author) only.
    get showPushToLmsButton() {
        return this.isDisbursementOpsAuthorStage;
    }

    // Mark As Complete appears on PSV and Disbursement (Ops Maker).
    get showMarkCompleteButton() {
        return this.isPsvStage || this.isDisbursementOpsMakerStage;
    }

    // ---- Reassign -> mirrors the standard "Reassign" Quick Action, which is the
    // Lightning Web Component `loanReassignmentScreen`. That component owns its own
    // modal chrome (slds-modal) and self-closes by firing `closemodal`.
    handleReassignClick(event) {
        event.stopPropagation();
        this.showReassignModal = true;
    }

    handleCloseReassignModal() {
        this.showReassignModal = false;
    }

    // ---- Detail Screen -> mirrors the standard "Detail screen" Quick Action, which is
    // the non-screen (headless) Lightning Web Component `homeToggleContinueCmp`. That
    // component has no markup of its own -- it only sets Opportunity.toggleHomePage__c
    // to true and closes. We reproduce that same field update directly here.
    handleDetailScreenClick(event) {
        event.stopPropagation();
        this.setToggleHomePage(true, 'Failed to open the detail screen.');
    }

    // ---- Continue Journey -> only shown once toggleHomePage__c is true (i.e. the user
    // is currently on the Detail Screen). Sets the same field back to false so whatever
    // visibility logic switches screens based on it returns the user to the main
    // Process Journey screen, and swaps this button back to "Detail Screen".
    handleContinueJourneyClick(event) {
        event.stopPropagation();
        this.setToggleHomePage(false, 'Failed to continue the journey.');
    }

    setToggleHomePage(toggleValue, errorMessage) {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[TOGGLE_HOME_FIELD.fieldApiName] = toggleValue;

        updateRecord({ fields })
            .then(() => {
                getRecordNotifyChange([{ recordId: this.recordId }]);
            })
            .catch((error) => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: (error && error.body && error.body.message) || errorMessage,
                    variant: 'error'
                }));
            });
    }

    // ---- Reject Loan -> mirrors the standard "Reject Loan" Quick Action, which is the
    // Lightning Web Component `rejectLoanApplicationCmp`. That component owns its own
    // modal chrome and fires `close` (cancel) or `success` (rejected) when done.
    handleRejectLoanClick(event) {
        event.stopPropagation();
        this.showRejectModal = true;
    }

    handleCloseRejectModal() {
        this.showRejectModal = false;
    }

    handleRejectSuccess() {
        this.showRejectModal = false;
    }

    // ---- Raise a Query -> mirrors the standard "Raise A Query" Quick Action, which
    // launches the screen Flow `Raise_a_Query_Quick_Action_button`. Flows don't render
    // their own modal chrome, so we wrap it in our own slds-modal here.
    handleRaiseQueryClick(event) {
        event.stopPropagation();
        this.showQueryModal = true;
    }

    handleCloseQueryModal() {
        this.showQueryModal = false;
    }

    handleQueryFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            this.showQueryModal = false;
        }
    }

    // ---- Send Back -> mirrors the standard "Send Back" Quick Action, which is the
    // Lightning Web Component `homeQuickAction` (Screen Action, quickActionName
    // "Send_Back"). That component owns its own modal chrome and fires `closemodal`
    // when done (same close-event convention as `loanReassignmentScreen`).
    handleSendBackClick(event) {
        event.stopPropagation();
        this.showSendBackModal = true;
    }

    handleCloseSendBackModal() {
        this.showSendBackModal = false;
    }

    // ---- Mark As Complete (PSV stage only) -> mirrors the standard "Mark As Complete"
    // Quick Action, which is the SAME Lightning Web Component `homeQuickAction` as
    // Send Back, just invoked with a different quickActionName ("Mark_As_Complete1").
    // The component itself already branches on that name internally (confirmation
    // text, validations), so no changes were needed there beyond the actionName prop.
    handleMarkAsCompleteClick(event) {
        event.stopPropagation();
        this.showMarkCompleteModal = true;
    }

    handleCloseMarkCompleteModal() {
        this.showMarkCompleteModal = false;
    }

    // ---- Assign To CM -> mirrors the standard "Assign To CM" Quick Action, which is
    // the Lightning Web Component `assignToCMCmp`. That component owns its own modal
    // chrome and fires a `close` event when done.
    handleAssignToCmClick(event) {
        event.stopPropagation();
        this.showAssignToCmModal = true;
    }

    handleCloseAssignToCmModal() {
        this.showAssignToCmModal = false;
    }

    // ---- Push to LMS (Disbursement stage, "Ops Author" sub stage only) -> mirrors the
    // other reused Quick Action LWCs on this banner. Launches `checkLmsPushCmp`, which
    // owns its own modal chrome, updates the loan's Sub Stage to "Disbursed" on
    // confirmation, and refreshes the LDS cache via getRecordNotifyChange -- so the
    // Sub Stage shown in this banner's @wire updates immediately, no page refresh needed.
    handlePushToLmsClick(event) {
        event.stopPropagation();
        this.showPushToLmsModal = true;
    }

    handleClosePushToLmsModal() {
        this.showPushToLmsModal = false;
    }

    get raiseQueryFlowApiName() {
        return RAISE_A_QUERY_FLOW_API_NAME;
    }

    get queryFlowInputVariables() {
        return [{ name: 'recordId', type: 'String', value: this.recordId }];
    }

    handleBranchClick(event) {
        event.preventDefault();
        if (!this.branchId) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.branchId,
                actionName: 'view'
            }
        });
    }
}
/*__________________________GenAI: Generated code ends here______________________________*/