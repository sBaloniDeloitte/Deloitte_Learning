/* _______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________ */
import { LightningElement, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import FIRST_NAME_FIELD from '@salesforce/schema/User.FirstName';

const DONUT_RADIUS = 70;
const DONUT_CIRCUMFERENCE = 2 * Math.PI * DONUT_RADIUS;

// All figures below are static reference-screenshot values. Only the
// greeting name and the header date are dynamic (current user + today).
// Getter names are kept stable so swapping in an Apex @wire later is a
// data-source-only change -- see creditPortfolioOverviewDashboard for the
// sibling component this was modeled on.
const STAT_CARDS = [
    { key: 'total', label: 'Total Applications in Pipeline', value: 512, trend: 8, direction: 'up', icon: 'doc', accent: 'accent-purple' },
    { key: 'inprogress', label: 'In Progress', value: 186, trend: 12, direction: 'up', icon: 'clock', accent: 'accent-purple' },
    { key: 'pendingops', label: 'Pending with Ops', value: 92, trend: 15, direction: 'down', icon: 'warning', accent: 'accent-amber' },
    { key: 'completed', label: 'Completed Today', value: 198, trend: 20, direction: 'up', icon: 'check', accent: 'accent-green' },
    { key: 'exceptions', label: 'Exceptions', value: 24, trend: 9, direction: 'up', icon: 'cross', accent: 'accent-red' },
    { key: 'reassignments', label: 'Reassignments', value: 6, trend: 50, direction: 'up', icon: 'people', accent: 'accent-purple' }
];

const TREND_DATES = ['21 Aug', '22 Aug', '23 Aug', '24 Aug', '25 Aug', '26 Aug', '27 Aug', '28 Aug', '29 Aug', '30 Aug', '31 Aug', '1 Sep', '2 Sep', '3 Sep', '4 Sep'];
const TREND_SERIES = {
    received: [90, 95, 105, 115, 125, 135, 145, 150, 160, 170, 180, 190, 205, 220, 250],
    processed: [70, 75, 85, 90, 100, 108, 115, 120, 128, 136, 145, 152, 162, 172, 182],
    completed: [40, 44, 48, 52, 57, 62, 66, 70, 75, 80, 85, 90, 96, 102, 108]
};
const TREND_MAX = 250;

const STAGE_CATEGORIES = [
    { label: 'Application Entry', count: 96, percent: 19, color: '#4aa3ff' },
    { label: 'Document Verification', count: 128, percent: 25, color: '#8b6ff0' },
    { label: 'Credit Assessment', count: 102, percent: 20, color: '#f0a93b' },
    { label: 'Approval', count: 74, percent: 14, color: '#3fcf8e' },
    { label: 'Disbursal', count: 58, percent: 11, color: '#e2586b' },
    { label: 'On Hold', count: 30, percent: 6, color: '#d9a441' },
    { label: 'Others', count: 24, percent: 5, color: '#c0392b' }
];
const STAGE_TOTAL = 512;

const SLA_CATEGORIES = [
    { label: 'Within SLA', count: 402, percent: 78, color: '#3fcf8e' },
    { label: 'Breached', count: 76, percent: 15, color: '#e2586b' },
    { label: 'At Risk', count: 34, percent: 7, color: '#f0a93b' }
];
const SLA_ON_TIME_PERCENT = '78%';

const PENDING_OPS = [
    { key: 'LOS0001267', appNo: 'LOS0001267', customer: 'Amit Kulkarni', product: 'Home Loan', pendingSince: '2 days', stage: 'Document Verification', stageColor: 'stage-purple' },
    { key: 'LOS0001268', appNo: 'LOS0001268', customer: 'Neha Joshi', product: 'LAP', pendingSince: '1 day', stage: 'Data Correction', stageColor: 'stage-amber' },
    { key: 'LOS0001270', appNo: 'LOS0001270', customer: 'Rakesh Mehta', product: 'Business Loan', pendingSince: '3 days', stage: 'Pending with Ops', stageColor: 'stage-red' },
    { key: 'LOS0001272', appNo: 'LOS0001272', customer: 'Sneha Patil', product: 'Home Loan', pendingSince: '2 days', stage: 'KYC Verification', stageColor: 'stage-amber' },
    { key: 'LOS0001275', appNo: 'LOS0001275', customer: 'Vikram Rao', product: 'Balance Transfer', pendingSince: '4 days', stage: 'Discrepancy', stageColor: 'stage-red' }
];
const PENDING_OPS_TOTAL = 92;

const TASKS_ALERTS = [
    { key: 'discrepancies', text: 'Resolve document discrepancies', count: '5', date: 'Today', severity: 'high' },
    { key: 'reconciliations', text: 'Review failed reconciliations', count: '3', date: 'Today', severity: 'high' },
    { key: 'slabreach', text: 'Clear SLA breaches', count: '4', date: '1 Sep 2026', severity: 'medium' },
    { key: 'bulkdata', text: 'Validate bulk data updates', count: '2', date: '1 Sep 2026', severity: 'medium' },
    { key: 'reassignreq', text: 'Process reassignment requests', count: '-', date: '2 Sep 2026', severity: 'low' }
];
const TASKS_ALERTS_TOTAL = 12;

const INSIGHT_CARDS = [
    { key: 'avgtat', label: 'Average TAT', value: '3.2 Days', trend: 18, direction: 'down', icon: 'doc', accent: 'accent-blue' },
    { key: 'stp', label: 'Straight Through Processing', value: '96%', trend: 5, direction: 'up', icon: 'refresh', accent: 'accent-green' },
    { key: 'errorrate', label: 'Error Rate', value: '2.1%', trend: 0.5, direction: 'up', icon: 'people', accent: 'accent-purple' },
    { key: 'slascore', label: 'Internal SLA Score', value: '4.6', trend: 12, direction: 'up', icon: 'star', accent: 'accent-amber' }
];

const WEEK_DROPDOWN_OPTIONS = ['Today', 'This Week', 'This Month', 'This Quarter'];
const TREND_DROPDOWN_OPTIONS = ['Last 1 Week', 'Last 2 Weeks', 'Last 4 Weeks'];

const ICON_COLORS = {
    'accent-purple': '#8b6ff0',
    'accent-blue': '#4aa3ff',
    'accent-amber': '#f0a93b',
    'accent-green': '#3fcf8e',
    'accent-red': '#e2586b'
};

export default class OperationsOverviewDashboard extends LightningElement {
    @track userFirstName;
    @track statsRange = 'This Week';
    @track trendRange = 'Last 2 Weeks';
    @track stageRange = 'This Week';
    @track slaRange = 'This Week';
    @track insightsRange = 'This Month';
    @track openDropdown = null; // 'trend' | 'stage' | 'sla' | 'insights' | null

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

    // ---- Stat strip ----
    get statCards() {
        return STAT_CARDS.map((card) => {
            const glyphColor = ICON_COLORS[card.accent] || '#4aa3ff';
            return {
                ...card,
                trendLabel: `${card.direction === 'up' ? '▲' : '▼'} ${card.trend}%`,
                trendClass: card.direction === 'up' ? 'trend-up' : 'trend-down',
                iconClass: `stat-icon ${card.accent}`,
                glyphStyle: `fill:${glyphColor}`,
                isDoc: card.icon === 'doc',
                isClock: card.icon === 'clock',
                isWarning: card.icon === 'warning',
                isCheck: card.icon === 'check',
                isCross: card.icon === 'cross',
                isPeople: card.icon === 'people'
            };
        });
    }

    // ---- Application Processing Trend line chart ----
    get trendDates() {
        return TREND_DATES;
    }

    get trendChartSeries() {
        const buildPoints = (values) =>
            values.map((val, index) => {
                const x = Math.round((index / (TREND_DATES.length - 1)) * 100);
                const y = Math.round(100 - (val / TREND_MAX) * 100);
                return { x, y, value: val };
            });

        const toPolyline = (points) => points.map((p) => `${p.x},${p.y}`).join(' ');

        const series = [
            { key: 'received', label: 'Received', color: '#4aa3ff', values: TREND_SERIES.received },
            { key: 'processed', label: 'Processed', color: '#3fcf8e', values: TREND_SERIES.processed },
            { key: 'completed', label: 'Completed', color: '#8b6ff0', values: TREND_SERIES.completed }
        ];

        return series.map((s) => {
            const points = buildPoints(s.values);
            return {
                key: s.key,
                label: s.label,
                dotStyle: `background:${s.color}`,
                lineStyle: `stroke:${s.color}`,
                polyline: toPolyline(points),
                markers: points.map((p, idx) => ({ key: `${s.key}-${idx}`, cx: p.x, cy: p.y, style: `fill:${s.color}` }))
            };
        });
    }

    // ---- Stage-wise Application Count donut ----
    get stageTotal() {
        return STAGE_TOTAL;
    }

    get stageSegments() {
        return this.buildDonutSegments(STAGE_CATEGORIES);
    }

    // ---- SLA Compliance donut ----
    get slaOnTimePercent() {
        return SLA_ON_TIME_PERCENT;
    }

    get slaSegments() {
        return this.buildDonutSegments(SLA_CATEGORIES);
    }

    buildDonutSegments(categories) {
        let cumulativePercent = 0;
        return categories.map((cat) => {
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

    // ---- Pending with Operations table ----
    get pendingOpsCount() {
        return PENDING_OPS_TOTAL;
    }

    get pendingOps() {
        return PENDING_OPS.map((row) => ({
            ...row,
            stageClass: `stage-badge ${row.stageColor}`
        }));
    }

    // ---- Operational Tasks & Alerts ----
    get tasksAlertsCount() {
        return TASKS_ALERTS_TOTAL;
    }

    get tasksAlerts() {
        return TASKS_ALERTS.map((task) => ({
            ...task,
            dotClass: `task-dot task-dot-${task.severity}`
        }));
    }

    // ---- Operations Insights mini cards ----
    get insightCards() {
        return INSIGHT_CARDS.map((card) => {
            const glyphColor = ICON_COLORS[card.accent] || '#4aa3ff';
            return {
                ...card,
                trendLabel: `${card.direction === 'up' ? '▲' : '▼'} ${card.trend}% vs last month`,
                trendClass: card.direction === 'up' ? 'trend-up' : 'trend-down',
                iconClass: `insight-icon ${card.accent}`,
                glyphStyle: `fill:${glyphColor}`,
                isDoc: card.icon === 'doc',
                isRefresh: card.icon === 'refresh',
                isPeople: card.icon === 'people',
                isStar: card.icon === 'star'
            };
        });
    }

    // ---- Dropdown behaviour ----
    get trendDropdownOptions() {
        return TREND_DROPDOWN_OPTIONS;
    }

    get stageDropdownOptions() {
        return WEEK_DROPDOWN_OPTIONS;
    }

    get slaDropdownOptions() {
        return WEEK_DROPDOWN_OPTIONS;
    }

    get insightsDropdownOptions() {
        return WEEK_DROPDOWN_OPTIONS;
    }

    get isTrendDropdownOpen() {
        return this.openDropdown === 'trend';
    }

    get isStageDropdownOpen() {
        return this.openDropdown === 'stage';
    }

    get isSlaDropdownOpen() {
        return this.openDropdown === 'sla';
    }

    get isInsightsDropdownOpen() {
        return this.openDropdown === 'insights';
    }

    toggleDropdown(name) {
        this.openDropdown = this.openDropdown === name ? null : name;
    }

    handleTrendDropdownToggle() {
        this.toggleDropdown('trend');
    }

    handleStageDropdownToggle() {
        this.toggleDropdown('stage');
    }

    handleSlaDropdownToggle() {
        this.toggleDropdown('sla');
    }

    handleInsightsDropdownToggle() {
        this.toggleDropdown('insights');
    }

    handleTrendOptionSelect(event) {
        this.trendRange = event.currentTarget.dataset.value;
        this.openDropdown = null;
    }

    handleStageOptionSelect(event) {
        this.stageRange = event.currentTarget.dataset.value;
        this.openDropdown = null;
    }

    handleSlaOptionSelect(event) {
        this.slaRange = event.currentTarget.dataset.value;
        this.openDropdown = null;
    }

    handleInsightsOptionSelect(event) {
        this.insightsRange = event.currentTarget.dataset.value;
        this.openDropdown = null;
    }

    // ---- Row / list actions (dispatched up for a parent to wire into navigation) ----
    handleTakeActionClick(event) {
        const appNo = event.currentTarget.dataset.appno;
        this.dispatchEvent(new CustomEvent('takeaction', { detail: { appNo } }));
    }

    handleTaskOpenClick(event) {
        const taskKey = event.currentTarget.dataset.key;
        this.dispatchEvent(new CustomEvent('opentask', { detail: { taskKey } }));
    }

    handleViewAllPendingOps() {
        this.dispatchEvent(new CustomEvent('viewallpendingops'));
    }

    handleViewAllTasks() {
        this.dispatchEvent(new CustomEvent('viewalltasks'));
    }
}
/* __________________________GenAI: Generated code ends here______________________________ */