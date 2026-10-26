/*
 * @description : Static AI Sales Insight card for an individual Home Loan
 *                 applicant lead. All applicant/action content is hardcoded
 *                 (no Apex / wire calls) - purely a display card themed to
 *                 match the dark/purple LMV2 design language.
 * @author       : ChangeMeIn@UserSettingsUnder.SFDoc
 */
import { LightningElement } from 'lwc';

export default class AiSalesInsightHomeLoanCmp extends LightningElement {
    // static applicant summary content
    applicantSummary =
        'Abhilash Saini is applying individually for a home loan with a salaried applicant profile. ' +
        'Assess eligibility and repayment capacity based on the available applicant details.';

    nextBestAction =
        'Confirm income documents, property valuation, and co-applicant options.';

    // static map embed for Deloitte India - Mumbai (no API key required)
    mapEmbedUrl =
        'https://maps.google.com/maps?q=Deloitte%20India%2C%20One%20International%20Center%2C%20Mumbai&t=&z=15&ie=UTF8&iwloc=&output=embed';
    mapMarkers = [
        {
            location: {
                Street: 'One International Center',
                City: 'Mumbai',
                State: 'Maharashtra',
                Country: 'India'
            },
            title: 'Deloitte India',
            description: 'Lead capture location'
        }
    ];
    // static Sales Agent Action Points
    actionPoints = [
        {
            id: 'highIntent',
            icon: 'utility:success',
            iconClass: 'action-icon action-icon_success',
            label: 'High intent lead:',
            text: 'Income documents verified - Prioritize outreach.'
        },
        {
            id: 'coApplicant',
            icon: 'utility:people',
            iconClass: 'action-icon action-icon_people',
            label: 'Co-applicant:',
            text: 'No co-applicant currently added - assess spouse/family co-applicant availability and repayment capacity.'
        },
        {
            id: 'riskCheck',
            icon: 'utility:warning',
            iconClass: 'action-icon action-icon_warning',
            label: 'Risk check:',
            text: "Explore property valuation and applicant's credit profile."
        },
        {
            id: 'nextBestAction',
            icon: 'utility:forward',
            iconClass: 'action-icon action-icon_forward',
            label: 'Next Best Action:',
            text: 'Qualify loan eligibility and co-applicant position, then recommend the most suitable loan amount and tenure.'
        }
    ];

    handleViewApplication() {
        // static card - dispatched for parent/container to optionally handle
        this.dispatchEvent(new CustomEvent('viewapplication'));
    }

    handleConvertToOpportunity() {
        // static card - dispatched for parent/container to optionally handle
        this.dispatchEvent(new CustomEvent('converttoopportunity'));
    }
}