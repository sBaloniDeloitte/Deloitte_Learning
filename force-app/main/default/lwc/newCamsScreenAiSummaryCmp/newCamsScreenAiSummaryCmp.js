/**
 * @description       : Standalone AI Summary panel for the newCamsScreen component.
 *                       Renders a static, AI-styled summary card for every section
 *                       that exists on newCamsScreen (Sourcing, FCU, Property, Eligibility,
 *                       Obligation, Sanction Conditions, Covenant, Income Assessment,
 *                       Technical Evaluation, Integration, Approval, etc.).
 *                       Data shown here is static text only -- this component does not
 *                       read from or write to newCamsScreen in any way.
 * @author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @last modified on   : 09-17-2026
 * @last modified by   : ChangeMeIn@UserSettingsUnder.SFDoc
 */
import { LightningElement, api } from 'lwc';

export default class NewCamsScreenAiSummaryCmp extends LightningElement {
    // Optional -- kept for future record-context use, not required for the static summary.
    @api recordId;

    // Static, AI-styled summary content for every section present on newCamsScreen.
    sectionSummaries = [
        {
            name: 'Sourcing Details',
            icon: 'utility:money',
            accent: '#8b5cf6',
            summary:
                'Captures how and where the loan was originated -- channel, DSA/branch, sourcing user and application source -- giving a quick read on lead origination quality.'
        },

        {
            name: 'Applicant Details',
            icon: 'utility:user',
            accent: '#22c1c3',
            summary:
                'Abhilash Saini is the Primary Applicant, aged 36, with a salaried employment profile at Deloitte Shared Services India LLP. He is a male applicant with an MBBS qualification, Salaried Indian constitution, and a CIBIL score of 800.'
        },

        {
            name: 'Address Details',
            icon: 'utility:location',
            accent: '#34d399',
            summary:
                'Address details capture the applicant’s residential and contact address information relevant to the loan application.'
        },
        {
            name: 'Product Details',
            icon: 'utility:package',
            accent: '#22c1c3',
            summary:
                'Summarizes the selected loan product, sub-product and scheme configuration, highlighting the commercial terms driving this application.'
        },
        {
            name: 'Personal Discussion Details',
            icon: 'utility:comments',
            accent: '#a78bfa',
            summary:
                'A manual personal discussion is recorded for Abhilash Saini, who is the Primary Applicant. The discussion status and additional notes are currently not specified in the available record.'
        },

        {
            name: 'Field Investigations',
            icon: 'utility:search',
            accent: '#60a5fa',
            summary:
                'A field investigation has been initiated for Abhilash Saini at the recorded Mumbai, Maharashtra address (400001). The visit is categorized as Reactive Verification, while no remarks have been recorded yet.'
        },

        {
            name: 'FCU',
            icon: 'utility:shield',
            accent: '#f87171',
            summary:
                'FCU screening covers three documents for Abhilash Saini: Address Proof, PAN, and Bank Analysis. The screening and verification status for all three documents are currently Pending.'
        },
        {
            name: 'Technical Evaluation',
            icon: 'utility:settings',
            accent: '#60a5fa',
            summary:
                'One technical evaluation is required for the application, while no technical evaluation has been initiated yet.'
        },

        {
            name: 'Legal',
            icon: 'utility:legal',
            accent: '#a78bfa',
            summary:
                'Legal processing is recorded for collateral COL-000000 associated with Abhilash Saini. The case is linked to Test Branch and is currently at the Assigned to Admin stage.'
        },

        {
            name: 'Property Details',
            icon: 'utility:home',
            accent: '#60a5fa',
            summary:
                'The application includes a residential property at Test121 Test121 Test121, classified under a Rural address type. The construction stage is recorded as Ready Property, while the property usage is marked as Under Construction; documented value, approved valuation, and technical remarks are currently not specified.'
        },
        {
            name: 'Integration Details',
            icon: 'utility:connected_apps',
            accent: '#22c1c3',
            summary:
                'For Primary Applicant Abhilash Saini, KYC validation shows No Match for Name and DOB, the record is marked Non Duplicate, and the PAN status is Invalid. The PAN Aadhaar Link, PAN Validation, and Image Compression APIs are currently Unable to Verify, with the same three API activities reflected under Triggered APIs.'
        },
        {
            name: 'Obligation Details',
            icon: 'utility:record',
            accent: '#fb923c',
            summary:
                'The application has five recorded obligations, with a total monthly obligation of ₹68,800 and an annual obligation of ₹8,25,600. The obligations include ₹3,50,000 of unsecured exposure and ₹3,90,000 of secured exposure, with ₹45,000 in credit card exposure and a 35% credit card max-out. The recorded DTI is 28%, while unsecured ETD stands at 18% and overall ETD at 32%.'
        },
        {
            name: 'Deviations',
            icon: 'utility:warning',
            accent: '#facc15',
            summary:
                'The application has five recorded deviations, of which two are Approved and three are Pending. The approved deviations relate to the financial applicant age and loan maturity age, while the pending items cover additional FOIR for self-employed borrowers and a waiver of the Probated Will requirement for the specified N-1, N-2 and N-3 transactions. The approved deviations have mitigants recorded as "okk".'
        },
        {
            name: 'Sanction Conditions',
            icon: 'utility:contract',
            accent: '#a78bfa',
            summary:
                'One sanction condition is currently recorded for the Home Loan product, with the condition listed as "Test" and the status shown as "Rece". No fulfilment documents, document attachments, or remarks are currently recorded for this condition.'
        },
        {
            name: 'Income Assessment Details',
            icon: 'utility:currency',
            accent: '#34d399',
            summary:
                'Income assessment for Abhilash Saini includes Cash Profit, Salaried Individual, Banking, Merchant Navy and Gross Margin evaluations, along with the Final Assessment. The Cash Profit assessment records cash profit of 310 for the latest year, compared with 302 and 318 in the previous two years, while the Gross Margin assessment records turnover of 22 and gross profit of 111 for the latest year. Banking assessment shows an average bank balance of 0.00 and an ABB EMI ratio of 8.00, while the Merchant Navy assessment records monthly gross remuneration of 6. The Final Assessment reflects a final loan amount of 81,900 at 10% interest for a 240-month tenure, with a final EMI of 790.35, FOIR of 0.02 and LTV of 0.82.'
        },
        {
            name: 'Covenant',
            icon: 'utility:contract',
            accent: '#a78bfa',
            summary:
                'The application has a PDD-Approved covenant under the OTH category, with the covenant "NO_CLAIM_CERTIFICATE_3_GENERAL" marked as Critical and currently Pending. The recorded remark is "ASAS", with no target date specified. The related document has a receipt date of 10-Oct-2026 and is classified as Others, while no uploaded document, level, or fulfilment status is currently recorded.'
        },
        {
            name: 'Approval',
            icon: 'utility:check',
            accent: '#8b5cf6',
            summary:
                'The approval section is associated with the Home Loan product. No specific approval details or approval status are currently recorded in the available application data.'
        }
    ];
}