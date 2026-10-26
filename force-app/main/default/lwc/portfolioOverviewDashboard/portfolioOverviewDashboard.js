/* _______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________ */
import { LightningElement, wire, track } from 'lwc';
//import getPortfolioMetrics from '@salesforce/apex/PortfolioOverviewController.getPortfolioMetrics';

export default class PortfolioOverviewDashboard extends LightningElement {
    cardMetrics;
    metricsError;

    // Drives which of the four tab panels is visible. Panels are toggled via
    // CSS class ('show'/'hide') on plain divs -- never removed from the DOM
    // with template if:true -- so only one panel is ever visible at a time.
    @track activeTab = 'portfolio'; // 'portfolio' | 'myday' | 'bulkleads' | 'dashboardoverview'

    get portfolioTabClass() {
        return this.activeTab === 'portfolio' ? 'po-tab active' : 'po-tab';
    }
    

    get myDayTabClass() {
        return this.activeTab === 'myday' ? 'po-tab active' : 'po-tab';
    }

    get bulkLeadsTabClass() {
        return this.activeTab === 'bulkleads' ? 'po-tab active' : 'po-tab';
    }

    

    get portfolioPanelClass() {
        return this.activeTab === 'portfolio' ? 'po-tab-panel show' : 'po-tab-panel hide';
    }

    get myDayPanelClass() {
        return this.activeTab === 'myday' ? 'po-tab-panel show' : 'po-tab-panel hide';
    }

    get bulkLeadsPanelClass() {
        return this.activeTab === 'bulkleads' ? 'po-tab-panel show po-bulkleads-panel' : 'po-tab-panel hide';
    }

    

    

    handleTabClick(event) {
        this.activeTab = event.currentTarget.dataset.tab;
    }

    // "Legal Checks Pending" and "Pending Property Valuations" have no backing
    // field/object yet, so they stay static (see PortfolioOverviewController doc).
    

    // Each getter falls back to the reference screenshot value until the
    // wire adapter resolves, avoiding a blank-card flash on first paint.
    get leadLoginConversionRate() {
        return this.cardMetrics?.leadLoginConversion?.metricOneValue ?? '33.8%';
    }

    get leadLoginLoginsCreated() {
        return this.cardMetrics?.leadLoginConversion?.metricTwoValue ?? '412';
    }

    get loginSanctionRate() {
        return this.cardMetrics?.loginSanctionConversion?.metricOneValue ?? '27.2%';
    }

    get loginSanctionSanctions() {
        return this.cardMetrics?.loginSanctionConversion?.metricTwoValue ?? '112';
    }

    get sanctionDisbursementRate() {
        return this.cardMetrics?.sanctionDisbursementRate?.metricOneValue ?? '72.4%';
    }

    get sanctionDisbursements() {
        return this.cardMetrics?.sanctionDisbursementRate?.metricTwoValue ?? '81';
    }

    get disbursementAmount() {
        return this.cardMetrics?.disbursementCurrentMonth?.metricOneValue ?? '₹46.3 Cr';
    }

    get disbursementAvgTicketSize() {
        return this.cardMetrics?.disbursementCurrentMonth?.metricTwoValue ?? '₹18.2 L';
    }

    get creditApprovalsUnderReview() {
        return this.cardMetrics?.pendingCreditApprovals?.metricOneValue ?? '68';
    }

    get creditApprovalsAvgTat() {
        return this.cardMetrics?.pendingCreditApprovals?.metricTwoValue ?? '36 hrs';
    }

    get documentationMissingDocs() {
        return this.cardMetrics?.casesAwaitingDocumentation?.metricOneValue ?? '41';
    }

    get documentationAvgDelay() {
        return this.cardMetrics?.casesAwaitingDocumentation?.metricTwoValue ?? '2.4 Days';
    }

    get kycConsentPending() {
        return this.cardMetrics?.kycConsentIssues?.metricOneValue ?? '22';
    }

    get kycRejection() {
        return this.cardMetrics?.kycConsentIssues?.metricTwoValue ?? '9';
    }

    get tatEfficiencyAvgTat() {
        return this.cardMetrics?.processingTatEfficiency?.metricOneValue ?? '7.4 Days';
    }

    get tatEfficiencySlaBreach() {
        return this.cardMetrics?.processingTatEfficiency?.metricTwoValue ?? '12%';
    }

    handleCardClick(event) {
        const cardKey = event.currentTarget.dataset.key;
        this.dispatchEvent(new CustomEvent('cardselect', { detail: { cardKey } }));
    }

    handleCardKeyDown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleCardClick(event);
        }
    }
}
/* __________________________GenAI: Generated code ends here______________________________ */