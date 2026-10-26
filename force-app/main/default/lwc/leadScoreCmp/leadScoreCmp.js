/*
 * @description : Static "Lead Score" eligibility snapshot card for a Home
 *                 Loan individual applicant lead (visual only, no Apex/wire).
 *                 Themed to match the dark/purple leadManagementV2 (LMV2)
 *                 design used by aiSalesInsightHomeLoanCmp / leadPriorityCmp.
 * @author       : ChangeMeIn@UserSettingsUnder.SFDoc
 */
import { LightningElement } from 'lwc';

export default class LeadScoreCmp extends LightningElement {
    // static eligibility snapshot content, adapted for a Home Loan applicant
    scoreValue = 30;
    scoreMax = 40;
    statusLabel = 'Good';
    parametersFilled = 3;
    parametersTotal = 4;
    modelInfo = 'Model: Lead Score v1 \u00b7 Updated dynamically';

    scoreBreakdown = [
        { id: 'age', label: 'Age', value: '10/10', met: true },
        { id: 'income', label: 'Income Range', value: '10/10', met: true },
        { id: 'loanAmount', label: 'Required Loan Amount', value: '10/10', met: true },
        { id: 'coApplicant', label: 'Co-Applicant Availability', value: '0/10', met: false }
    ];

    get scorePercent() {
        return Math.round((this.scoreValue / this.scoreMax) * 100);
    }

    get ringStyle() {
        const percent = this.scorePercent;
        return 'background: conic-gradient(#1467eb 0% ' + percent + '%, #8fa1b8 ' + percent + '% 100%);';
    }

    get parametersFilledLabel() {
        return this.parametersFilled + ' / ' + this.parametersTotal + ' parameters filled';
    }

    get scoreRows() {
        return this.scoreBreakdown.map((row) => ({
            ...row,
            rowClass: 'ls-row ' + (row.met ? 'ls-row_met' : 'ls-row_unmet'),
            arrowIcon: row.met ? 'utility:arrowup' : 'utility:arrowdown',
            valueClass: row.met ? 'ls-row-value ls-row-value_met' : 'ls-row-value ls-row-value_unmet'
        }));
    }
}