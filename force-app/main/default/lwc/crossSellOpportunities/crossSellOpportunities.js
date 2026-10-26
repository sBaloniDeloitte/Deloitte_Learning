/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
import { LightningElement, track } from 'lwc';

const ALL_RECORDS = [
    {
        id: '1',
        applicationId: 'EL-APP-100241',
        household: 'Menon household',
        applicantName: 'Aditya Menon',
        productCategory: 'forex',
        productLabel: 'Forex card',
        badgeClass: 'badge badge-forex',
        whyNow: [
            { icon: '✈', text: 'Departure to Toronto in 12 days' },
            { icon: '✓', text: 'Sanction includes living expense component' }
        ],
        estValue: '—',
        actioned: false,
        actionLabel: 'Offer forex card'
    },
    {
        id: '2',
        applicationId: 'EL-APP-100241',
        household: 'Menon household',
        applicantName: 'Aditya Menon',
        productCategory: 'travel',
        productLabel: 'Travel & health insurance',
        badgeClass: 'badge badge-travel',
        whyNow: [
            { icon: '✈', text: 'Departure to Toronto in 12 days' },
            { icon: '⚠', text: 'No travel/health insurance recorded on file' }
        ],
        estValue: '₹18,000',
        actioned: false,
        actionLabel: 'Offer insurance'
    },
    {
        id: '3',
        applicationId: 'EL-APP-100288',
        household: 'Shaikh household',
        applicantName: 'Zoya Shaikh',
        productCategory: 'forex',
        productLabel: 'Forex card',
        badgeClass: 'badge badge-forex',
        whyNow: [
            { icon: '✈', text: 'Semester 2 tranche released this week' },
            { icon: '✓', text: 'First disbursement to a foreign account' }
        ],
        estValue: '—',
        actioned: false,
        actionLabel: 'Offer forex card'
    },
    {
        id: '4',
        applicationId: 'EL-APP-099187',
        household: 'Vaidya household',
        applicantName: 'Meera Vaidya',
        productCategory: 'sibling',
        productLabel: 'Sibling education loan',
        badgeClass: 'badge badge-sibling',
        whyNow: [
            { icon: '👪', text: 'Younger sibling logged an enquiry on the counsellor portal' },
            { icon: '✓', text: 'Existing loan conduct is clean — zero missed EMIs' }
        ],
        estValue: '₹22,00,000',
        actioned: false,
        actionLabel: 'Route sibling lead to sales'
    },
    {
        id: '5',
        applicationId: 'EL-APP-098650',
        household: 'Iqbal household',
        applicantName: 'Sana Iqbal',
        productCategory: 'repeat',
        productLabel: 'Repeat / next-degree loan',
        badgeClass: 'badge badge-repeat',
        whyNow: [
            { icon: '🎓', text: 'Course completes in 2 months — UG in Data Science' },
            { icon: '✓', text: 'Academic record strong, no backlogs' }
        ],
        estValue: '₹15,00,000',
        actioned: false,
        actionLabel: 'Start next-degree conversation'
    },
    {
        id: '6',
        applicationId: 'EL-APP-100112',
        household: 'Rao household',
        applicantName: 'Devika Rao',
        productCategory: 'topup',
        productLabel: 'Top-up / enhancement',
        badgeClass: 'badge badge-topup',
        whyNow: [
            { icon: '📝', text: 'Institute fee revised upward for year 2' },
            { icon: '✓', text: 'Already flagged in the enhancement worklist' }
        ],
        estValue: '₹5,20,000',
        actioned: false,
        actionLabel: 'Open enhancement case'
    },
    {
        id: '7',
        applicationId: 'EL-APP-100055',
        household: 'Ahluwalia household',
        applicantName: 'Kabir Ahluwalia',
        productCategory: 'travel',
        productLabel: 'Travel & health insurance',
        badgeClass: 'badge badge-travel',
        whyNow: [
            { icon: '📅', text: 'Visa renewal completed this month' },
            { icon: '⚠', text: 'Original travel insurance expires in 30 days' }
        ],
        estValue: '₹14,000',
        actioned: false,
        actionLabel: 'Offer insurance renewal'
    },
    {
        id: '8',
        applicationId: 'EL-APP-097740',
        household: 'Kulkarni household',
        applicantName: 'Aryan Kulkarni',
        productCategory: 'sibling',
        productLabel: 'Sibling education loan',
        badgeClass: 'badge badge-sibling',
        whyNow: [
            { icon: '👪', text: "Second child's admission enquiry logged 3 days ago" },
            { icon: '✓', text: 'Household bureau profile refreshed and clean' }
        ],
        estValue: '₹18,00,000',
        actioned: false,
        actionLabel: 'Route sibling lead to sales'
    }
];

const PRODUCT_OPTIONS = [
    { label: 'All products', value: 'All' },
    { label: 'Forex card', value: 'forex' },
    { label: 'Top-up / enhancement', value: 'topup' },
    { label: 'Sibling education loan', value: 'sibling' },
    { label: 'Repeat / next-degree loan', value: 'repeat' },
    { label: 'Travel & health insurance', value: 'travel' }
];

const LEGEND_ITEMS = [
    { key: 'forex', label: 'Forex card', dotClass: 'cso-legend-dot cso-dot-forex' },
    { key: 'topup', label: 'Top-up / enhancement', dotClass: 'cso-legend-dot cso-dot-topup' },
    { key: 'sibling', label: 'Sibling education loan', dotClass: 'cso-legend-dot cso-dot-sibling' },
    { key: 'repeat', label: 'Repeat / next-degree loan', dotClass: 'cso-legend-dot cso-dot-repeat' },
    { key: 'travel', label: 'Travel & health insurance', dotClass: 'cso-legend-dot cso-dot-travel' }
];

// Maps a why-now glyph to a semantic color class so confirmed / missing / informational
// lines render in distinct colors, matching the approved screenshot.
const ICON_TYPE_MAP = {
    '✓': 'cso-icon-success',
    '⚠': 'cso-icon-warning'
};

function getIconClass(icon) {
    return `cso-why-icon ${ICON_TYPE_MAP[icon] || 'cso-icon-info'}`;
}

// Insurance offers render as a secondary (muted) CTA; all other cross-sell actions
// use the primary bright-blue CTA, matching the approved screenshot.
function getActionBtnClass(productCategory) {
    return productCategory === 'travel' ? 'cso-action-btn cso-action-btn-secondary' : 'cso-action-btn';
}

function decorateRecord(rec) {
    return {
        ...rec,
        actionBtnClass: getActionBtnClass(rec.productCategory),
        whyNow: rec.whyNow.map((line) => ({ ...line, iconClass: getIconClass(line.icon) }))
    };
}

export default class CrossSellOpportunities extends LightningElement {
    @track searchTerm = '';
    @track selectedProduct = 'All';
    @track allRecords = ALL_RECORDS.map(decorateRecord);
    @track showToast = false;
    toastMessage = '';
    toastTimeoutId;

    productOptions = PRODUCT_OPTIONS;
    legendItems = LEGEND_ITEMS;

    handleAction(event) {
        const recId = event.target.dataset.id;
        const rec = this.allRecords.find((r) => r.id === recId);
        if (!rec || rec.actioned) {
            return;
        }
        const originalLabel = rec.actionLabel;
        this.allRecords = this.allRecords.map((r) =>
            r.id === recId ? { ...r, actioned: true, actionLabel: 'Actioned' } : r
        );
        this.showToastMessage(`${originalLabel} — logged against ${rec.applicationId}`);
    }

    showToastMessage(message) {
        this.toastMessage = message;
        this.showToast = true;
        if (this.toastTimeoutId) {
            clearTimeout(this.toastTimeoutId);
        }
        this.toastTimeoutId = setTimeout(() => {
            this.showToast = false;
        }, 3000);
    }

    handleSearchChange(event) {
        this.searchTerm = (event.target.value || '').toLowerCase();
    }

    handleProductChange(event) {
        this.selectedProduct = event.target.value;
    }

    handleRefresh() {
        this.searchTerm = '';
        this.selectedProduct = 'All';
        const searchInput = this.template.querySelector('.search-input');
        if (searchInput) {
            searchInput.value = '';
        }
        const productSelect = this.template.querySelector('.product-select');
        if (productSelect) {
            productSelect.value = 'All';
        }
    }

    get filteredRecords() {
        const term = this.searchTerm;
        const product = this.selectedProduct;
        return this.allRecords.filter((rec) => {
            const matchesProduct = product === 'All' || rec.productCategory === product;
            const matchesSearch =
                !term ||
                rec.household.toLowerCase().includes(term) ||
                rec.applicantName.toLowerCase().includes(term) ||
                rec.applicationId.toLowerCase().includes(term);
            return matchesProduct && matchesSearch;
        });
    }

    get hasRecords() {
        return this.filteredRecords.length > 0;
    }

    get resultCount() {
        return this.filteredRecords.length;
    }
}
/*__________________________GenAI: Generated code ends here______________________________*/