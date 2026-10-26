/* _______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________ */
import { LightningElement, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import FIRST_NAME_FIELD from '@salesforce/schema/User.FirstName';

const DONUT_RADIUS = 70;
const DONUT_CIRCUMFERENCE = 2 * Math.PI * DONUT_RADIUS;

// All figures below are static reference-screenshot values. Only the
// greeting name and the header date are dynamic (current user + today).
// Swap the getters that read STAT_CARDS / DONUT_CATEGORIES / TREND_SERIES /
// PENDING_APPROVALS / TASKS_ALERTS for an Apex @wire later -- getter names
// are kept stable so that is a data-source-only change.
const STAT_CARDS = [
    { key: 'total', label: 'Total Applications', value: 248, trend: 12, direction: 'up', icon: 'doc', accent: 'accent-purple' },
    { key: 'review', label: 'Under Review', value: 96, trend: 8, direction: 'up', icon: 'clock', accent: 'accent-blue' },
    { key: 'pending', label: 'Pending Approval', value: 62, trend: 15, direction: 'up', icon: 'hourglass', accent: 'accent-amber' },
    { key: 'approved', label: 'Approved', value: 78, trend: 20, direction: 'up', icon: 'check', accent: 'accent-green' },
    { key: 'declined', label: 'Declined', value: 10, trend: 5, direction: 'down', icon: 'cross', accent: 'accent-red' },
    { key: 'reassigned', label: 'Reassigned', value: 12, trend: 14, direction: 'up', icon: 'people', accent: 'accent-purple' }
];

const TREND_WEEKS = ['27 Jul', '3 Aug', '10 Aug', '17 Aug', '24 Aug', '31 Aug'];
const TREND_SERIES = {
    received: [70, 110, 140, 150, 170, 190],
    approved: [20, 45, 60, 65, 75, 90],
    declined: [10, 15, 20, 22, 25, 30]
};
const TREND_MAX = 200;

const DONUT_CATEGORIES = [
    { label: 'Home Loan', count: 28, percent: 36, color: '#4aa3ff' },
    { label: 'LAP', count: 16, percent: 21, color: '#8b6ff0' },
    { label: 'Business Loan', count: 14, percent: 18, color: '#f0a93b' },
    { label: 'Balance Transfer', count: 12, percent: 15, color: '#3fcf8e' },
    { label: 'Others', count: 8, percent: 10, color: '#e2586b' }
];
const DONUT_APPROVED_TOTAL = 78;

const PENDING_APPROVALS = [
    { key: 'LOS0001267', appNo: 'LOS0001267', customer: 'Amit Kulkarni', product: 'Home Loan', tat: 2, priority: 'High' },
    { key: 'LOS0001268', appNo: 'LOS0001268', customer: 'Neha Joshi', product: 'LAP', tat: 1, priority: 'High' },
    { key: 'LOS0001270', appNo: 'LOS0001270', customer: 'Rakesh Mehta', product: 'Business Loan', tat: 3, priority: 'Medium' },
    { key: 'LOS0001272', appNo: 'LOS0001272', customer: 'Sneha Patil', product: 'Home Loan', tat: 2, priority: 'Medium' },
    { key: 'LOS0001275', appNo: 'LOS0001275', customer: 'Vikram Rao', product: 'Balance Transfer', tat: 4, priority: 'Low' }
];
const PENDING_APPROVALS_TOTAL = 62;

const TASKS_ALERTS = [
    { key: 'risk', text: 'Review high risk applications', count: '5', date: 'Today', severity: 'high' },
    { key: 'exceptions', text: 'Approve policy exceptions', count: '3', date: 'Today', severity: 'high' },
    { key: 'escalation', text: 'Team escalation – TAT breach', count: '2', date: '1 Sep 2026', severity: 'medium' },
    { key: 'reassignment', text: 'Reassignment requests', count: '1', date: '1 Sep 2026', severity: 'medium' },
    { key: 'policy', text: 'Updated credit policy guidelines', count: '-', date: '31 Aug 2026', severity: 'low' }
];
const TASKS_ALERTS_TOTAL = 8;

const WEEK_DROPDOWN_OPTIONS = ['Today', 'This Week', 'This Month', 'This Quarter'];
const TREND_DROPDOWN_OPTIONS = ['Last 4 Weeks', 'Last 6 Weeks', 'Last 12 Weeks'];

export default class CreditPortfolioOverviewDashboard extends LightningElement {
    @track userFirstName;
    @track portfolioRange = 'This Week';
    @track trendRange = 'Last 6 Weeks';
    @track decisionsRange = 'This Week';
    @track openDropdown = null; // 'portfolio' | 'trend' | 'decisions' | null

    @wire(getRecord, { recordId: USER_ID, fields: [FIRST_NAME_FIELD] })
    wiredUser({ data, error }) {
        if (data) {
            this.userFirstName = data.fields.FirstName.value;
        } else if (error) {
            this.userFirstName = undefined;
        }
    }

    // ---- Header: dynamic name / date, static quote ----
    get greetingName() {
        return this.userFirstName || 'User';
    }

    get greetingPrefix() {
        const hour = new Date().getHours();
        if (hour < 12) {
            return 'Good Morning';
        }
        if (hour < 17) {
            return 'Good Afternoon';
        }
        return 'Good Evening';
    }

    get greetingText() {
        return `${this.greetingPrefix}, ${this.greetingName}!`;
    }

    get todayFormatted() {
        return new Date().toLocaleDateString('en-US', {
            weekday: 'short',
            day: 'numeric',
            month: 'short',
            year: 'numeric'
        });
    }

    // ---- Credit Portfolio Overview stat strip ----
    // Each accent maps to the glyph color used inline on the SVG paths below --
    // kept as explicit fill/stroke (not currentColor) since SVG children do not
    // reliably inherit CSS color through the light DOM in this org.
    get statCards() {
        const ICON_COLORS = {
            'accent-purple': '#8b6ff0',
            'accent-blue': '#4aa3ff',
            'accent-amber': '#f0a93b',
            'accent-green': '#3fcf8e',
            'accent-red': '#e2586b'
        };
        return STAT_CARDS.map((card) => {
            const glyphColor = ICON_COLORS[card.accent] || '#4aa3ff';
            return {
                ...card,
                trendLabel: `${card.direction === 'up' ? '▲' : '▼'} ${card.trend}%`,
                trendClass: card.direction === 'up' ? 'trend-up' : 'trend-down',
                iconClass: `stat-icon ${card.accent}`,
                glyphStyle: `fill:${glyphColor}`,
                glyphStrokeStyle: `stroke:${glyphColor}`,
                isDoc: card.icon === 'doc',
                isClock: card.icon === 'clock',
                isHourglass: card.icon === 'hourglass',
                isCheck: card.icon === 'check',
                isCross: card.icon === 'cross',
                isPeople: card.icon === 'people'
            };
        });
    }

    // ---- Applications Trend line chart ----
    get trendWeeks() {
        return TREND_WEEKS;
    }

    get trendChartSeries() {
        const buildPoints = (values) =>
            values
                .map((val, index) => {
                    const x = Math.round((index / (TREND_WEEKS.length - 1)) * 100);
                    const y = Math.round(100 - (val / TREND_MAX) * 100);
                    return { x, y, value: val };
                });

        const toPolyline = (points) => points.map((p) => `${p.x},${p.y}`).join(' ');

        const series = [
            { key: 'received', label: 'Received', color: '#4aa3ff', values: TREND_SERIES.received },
            { key: 'approved', label: 'Approved', color: '#3fcf8e', values: TREND_SERIES.approved },
            { key: 'declined', label: 'Declined', color: '#e2586b', values: TREND_SERIES.declined }
        ];

        return series.map((s) => {
            const points = buildPoints(s.values);
            return {
                key: s.key,
                label: s.label,
                color: s.color,
                dotStyle: `background:${s.color}`,
                lineStyle: `stroke:${s.color}`,
                polyline: toPolyline(points),
                markers: points.map((p, idx) => ({ key: `${s.key}-${idx}`, cx: p.x, cy: p.y, style: `fill:${s.color}` }))
            };
        });
    }

    // ---- Credit Decisions by Product donut ----
    get donutApprovedTotal() {
        return DONUT_APPROVED_TOTAL;
    }

    get donutSegments() {
        let cumulativePercent = 0;
        return DONUT_CATEGORIES.map((cat) => {
            const arcLength = (cat.percent / 100) * DONUT_CIRCUMFERENCE;
            const dashArray = `${arcLength} ${DONUT_CIRCUMFERENCE - arcLength}`;
            const dashOffset = DONUT_CIRCUMFERENCE * (1 - cumulativePercent / 100);
            cumulativePercent += cat.percent;
            return {
                key: cat.label,
                label: cat.label,
                count: cat.count,
                percent: cat.percent,
                dashArray,
                dashOffset,
                pathStyle: `stroke:${cat.color}`,
                swatchStyle: `background:${cat.color}`
            };
        });
    }

    // ---- Pending Approvals table ----
    get pendingApprovalsCount() {
        return PENDING_APPROVALS_TOTAL;
    }

    get pendingApprovals() {
        return PENDING_APPROVALS.map((row) => ({
            ...row,
            priorityClass: `priority-badge priority-${row.priority.toLowerCase()}`
        }));
    }

    // ---- My Tasks & Alerts ----
    get tasksAlertsCount() {
        return TASKS_ALERTS_TOTAL;
    }

    get tasksAlerts() {
        return TASKS_ALERTS.map((task) => ({
            ...task,
            dotClass: `task-dot task-dot-${task.severity}`
        }));
    }

    // ---- Dropdown behaviour (Portfolio / Trend / Decisions range pickers) ----
    get portfolioDropdownOptions() {
        return WEEK_DROPDOWN_OPTIONS;
    }

    get trendDropdownOptions() {
        return TREND_DROPDOWN_OPTIONS;
    }

    get decisionsDropdownOptions() {
        return WEEK_DROPDOWN_OPTIONS;
    }

    get isPortfolioDropdownOpen() {
        return this.openDropdown === 'portfolio';
    }

    get isTrendDropdownOpen() {
        return this.openDropdown === 'trend';
    }

    get isDecisionsDropdownOpen() {
        return this.openDropdown === 'decisions';
    }

    toggleDropdown(name) {
        this.openDropdown = this.openDropdown === name ? null : name;
    }

    handlePortfolioDropdownToggle() {
        this.toggleDropdown('portfolio');
    }

    handleTrendDropdownToggle() {
        this.toggleDropdown('trend');
    }

    handleDecisionsDropdownToggle() {
        this.toggleDropdown('decisions');
    }

    handlePortfolioOptionSelect(event) {
        this.portfolioRange = event.currentTarget.dataset.value;
        this.openDropdown = null;
    }

    handleTrendOptionSelect(event) {
        this.trendRange = event.currentTarget.dataset.value;
        this.openDropdown = null;
    }

    handleDecisionsOptionSelect(event) {
        this.decisionsRange = event.currentTarget.dataset.value;
        this.openDropdown = null;
    }

    // ---- Row actions (dispatched up for a parent to wire into navigation) ----
    handleReviewClick(event) {
        const appNo = event.currentTarget.dataset.appno;
        this.dispatchEvent(new CustomEvent('reviewapplication', { detail: { appNo } }));
    }

    handleViewAllApprovals() {
        this.dispatchEvent(new CustomEvent('viewallapprovals'));
    }

    handleViewAllTasks() {
        this.dispatchEvent(new CustomEvent('viewalltasks'));
    }
}
/* __________________________GenAI: Generated code ends here______________________________ */