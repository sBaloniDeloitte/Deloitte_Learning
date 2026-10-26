//_______________This Code was generated using GenAI tool: Codify, Please check for accuracy_______________//
import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Hardcoded target Lead record — replace with a real Lead Id from your org.
const HARDCODED_LEAD_ID = '00QdN00000GF4QHUA1';

export default class MostActiveLeadCard extends NavigationMixin(LightningElement) {

    isLoading = false;

    // ── Static "Most Active Lead Today" highlight data ──────────────────────
    headerSubtitle  = 'Highest engagement activity';
    avatarInitials  = 'SK';
    leadName        = 'Siddharth Karulkar';
    leadSubtitle    = 'Home Loan';
    HighestAmount    = 700000;
    engagementScore = 83;
    leadScore       = 82;
    lastActivity    = 'Last 6 hrs';
    updatedAgo      = '6 min ago';
    asOf            = 'As of just now';
    footerNote      = 'High engagement opportunity';

    // ── SVG ring progress (engagement score) ─────────────────────────────────
    get progressStyle() {
        const r = 50;
        const circ = 2 * Math.PI * r;
        const offset = circ - (this.engagementScore / 100) * circ;
        return `stroke-dasharray:${circ};stroke-dashoffset:${offset};`;
    }

    // ── Open lead: land on the hardcoded Lead record page ────────────────────
    handleOpenLead() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId:      HARDCODED_LEAD_ID,
                objectApiName: 'Lead',
                actionName:    'view'
            }
        });
    }
}
//__________________________GenAI: Generated code ends here______________________________//