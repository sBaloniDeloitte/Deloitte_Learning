/* _______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________ */
import { LightningElement, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import FIRST_NAME_FIELD from '@salesforce/schema/User.FirstName';

// All figures below are static reference-screenshot values. Only the
// greeting name and the header date are dynamic (current user + today).
// Getter names are kept stable so swapping in an Apex @wire later is a
// data-source-only change -- modeled on operationsOverviewDashboard.
const STAT_CARDS = [
    { key: 'assigned', label: 'Assigned Applications', value: 28, trend: 12, direction: 'up', icon: 'doc', accent: 'accent-purple' },
    { key: 'underreview', label: 'Under Review', value: 18, trend: 20, direction: 'up', icon: 'clock', accent: 'accent-blue' },
    { key: 'query', label: 'Query Raised (by me)', value: 8, trend: 14, direction: 'up', icon: 'question', accent: 'accent-red' },
    { key: 'pendingapplicant', label: 'Pending with Applicant', value: 10, trend: 25, direction: 'up', icon: 'hourglass', accent: 'accent-amber' },
    { key: 'recommended', label: 'Recommended', value: 22, trend: 10, direction: 'up', icon: 'check', accent: 'accent-green' },
    { key: 'declined', label: 'Declined', value: 6, trend: 20, direction: 'down', icon: 'cross', accent: 'accent-slate' }
];

const ACTION_REQUIRED = [
    { key: 'awaiting', icon: 'question', accent: 'accent-red', title: 'Applications Awaiting Your Review', description: 'Newly assigned applications pending credit review', count: 12 },
    { key: 'queries', icon: 'hourglass', accent: 'accent-amber', title: 'Applications with Queries (from Sales/Ops)', description: 'Review and provide clarification', count: 6 },
    { key: 'pendingresp', icon: 'people', accent: 'accent-purple', title: 'Pending Applicant Response', description: 'Customer documents/clarifications awaited', count: 5 },
    { key: 'rereview', icon: 'check', accent: 'accent-green', title: 'Re-Review / Exceptions', description: 'Applications requiring senior review or policy exception', count: 3 }
];
const ACTION_REQUIRED_TOTAL = 26;

const QUEUE_TABS = [
    { key: 'all', label: 'All', count: 28 },
    { key: 'underreview', label: 'Under Review', count: 18 },
    { key: 'query', label: 'Query', count: 6 },
    { key: 'pendingapplicant', label: 'Pending with Applicant', count: 5 },
    { key: 'recommended', label: 'Recommended', count: 22 },
    { key: 'declined', label: 'Declined', count: 6 }
];

const QUEUE_ROWS = [
    { key: 'LOS0001267', appNo: 'LOS0001267', customer: 'Amit Kulkarni', product: 'Home Loan', assignedDate: '3 Sep 2026', tat: 2, priority: 'High', priorityColor: 'priority-high', stage: 'Under Review', stageColor: 'stage-blue' },
    { key: 'LOS0001268', appNo: 'LOS0001268', customer: 'Neha Joshi', product: 'LAP', assignedDate: '3 Sep 2026', tat: 1, priority: 'High', priorityColor: 'priority-high', stage: 'Query', stageColor: 'stage-purple' },
    { key: 'LOS0001269', appNo: 'LOS0001269', customer: 'Rakesh Mehta', product: 'Business Loan', assignedDate: '2 Sep 2026', tat: 3, priority: 'Medium', priorityColor: 'priority-medium', stage: 'Pending Applicant', stageColor: 'stage-amber' },
    { key: 'LOS0001270', appNo: 'LOS0001270', customer: 'Sneha Patil', product: 'Home Loan', assignedDate: '2 Sep 2026', tat: 4, priority: 'Medium', priorityColor: 'priority-medium', stage: 'Under Review', stageColor: 'stage-blue' },
    { key: 'LOS0001271', appNo: 'LOS0001271', customer: 'Vikram Rao', product: 'Balance Transfer', assignedDate: '1 Sep 2026', tat: 5, priority: 'Low', priorityColor: 'priority-low', stage: 'Re-Review', stageColor: 'stage-green' }
];
const QUEUE_TOTAL = 28;
const QUEUE_PAGE_SIZE = 5;

const PRODUCT_OPTIONS = ['Product', 'Home Loan', 'LAP', 'Business Loan', 'Balance Transfer'];
const PRIORITY_OPTIONS = ['Priority', 'High', 'Medium', 'Low'];
const ASSIGNED_DATE_OPTIONS = ['Assigned Date', 'Today', 'This Week', 'This Month'];

const TASKS_ALERTS_TOTAL = 6;
const MY_TASKS_TAB_COUNT = 6;
const ALERTS_TAB_COUNT = 5;

const MY_TASKS_ROWS = [
    { key: 'task1', dot: 'high', task: 'Review income documents', appNo: 'LOS0001268', customer: 'Neha Joshi', dueDate: 'Today', priority: 'High', priorityColor: 'priority-high' },
    { key: 'task2', dot: 'high', task: 'Analyze credit report', appNo: 'LOS0001269', customer: 'Rakesh Mehta', dueDate: 'Today', priority: 'High', priorityColor: 'priority-high' },
    { key: 'task3', dot: 'medium', task: 'Verify employment details', appNo: 'LOS0001270', customer: 'Sneha Patil', dueDate: '5 Sep 2026', priority: 'Medium', priorityColor: 'priority-medium' },
    { key: 'task4', dot: 'medium', task: 'Review policy exception', appNo: 'LOS0001272', customer: 'Amit Singh', dueDate: '5 Sep 2026', priority: 'Medium', priorityColor: 'priority-medium' },
    { key: 'task5', dot: 'low', task: 'Re-verify calculations', appNo: 'LOS0001265', customer: 'Kavita Rao', dueDate: '6 Sep 2026', priority: 'Low', priorityColor: 'priority-low' }
];

const ALERT_ITEMS = [
    { key: 'alert1', severity: 'high', text: 'SLA breach risk on 3 applications', appNo: 'LOS0001269', time: '1h ago' },
    { key: 'alert2', severity: 'medium', text: 'Document expiry approaching for 2 applicants', appNo: 'LOS0001270', time: '3h ago' },
    { key: 'alert3', severity: 'medium', text: 'Credit bureau report delayed', appNo: 'LOS0001268', time: '5h ago' },
    { key: 'alert4', severity: 'low', text: 'Policy exception awaiting sign-off', appNo: 'LOS0001272', time: '1d ago' },
    { key: 'alert5', severity: 'low', text: 'Reassignment request pending', appNo: 'LOS0001265', time: '1d ago' }
];

const RECENT_UPDATES = [
    { key: 'update1', icon: 'info', text: 'Credit policy guideline updated', time: '2h ago' },
    { key: 'update2', icon: 'warning', text: '3 applications escalated for management review', time: '4h ago' },
    { key: 'update3', icon: 'info', text: 'New product matrix released', time: '1d ago' },
    { key: 'update4', icon: 'warning', text: 'High FOIR applications increased by 15%', time: '1d ago' },
    { key: 'update5', icon: 'info', text: 'System maintenance scheduled on 6 Sep, 10 PM', time: '2d ago' }
];

// ---- Performance & Insights (Overview tab) reference data ----
const PERFORMANCE_TABS = [
    { key: 'overview', label: 'Overview' },
    { key: 'turnaroundtime', label: 'Turnaround Time' },
    { key: 'riskanalysis', label: 'Risk Analysis' },
    { key: 'productwise', label: 'Product Wise' },
    { key: 'teamcomparison', label: 'Team Comparison' }
];
const PERFORMANCE_RANGE_OPTIONS = ['This Week', 'This Month', 'This Quarter', 'This Year'];

const REVIEW_TREND_DATES = ['1 Sep', '5 Sep', '10 Sep', '15 Sep', '20 Sep', '25 Sep', '30 Sep'];
const REVIEW_TREND_SERIES = {
    reviewed: [15, 22, 28, 25, 32, 40, 50],
    approved: [8, 12, 18, 16, 20, 24, 28]
};
const REVIEW_TREND_MAX = 50;

const PI_DONUT_RADIUS = 70;
const PI_DONUT_CIRCUMFERENCE = 2 * Math.PI * PI_DONUT_RADIUS;

const CREDIT_DECISION_CATEGORIES = [
    { label: 'Approved', count: 22, percent: 46, color: '#3fcf8e' },
    { label: 'Pending', count: 10, percent: 21, color: '#f0a93b' },
    { label: 'Recommended for Decline', count: 8, percent: 17, color: '#e2586b' },
    { label: 'Declined', count: 6, percent: 12, color: '#8b6ff0' },
    { label: 'Referred', count: 2, percent: 4, color: '#8b93ab' }
];
const CREDIT_DECISION_TOTAL = 48;

const TAT_BARS = [
    { key: 'creditanalysis', label: 'Credit Analysis', value: 2.1, color: '#4aa3ff' },
    { key: 'policyexception', label: 'Policy Exception', value: 3.4, color: '#8b6ff0' },
    { key: 'managementreview', label: 'Management Review', value: 4.2, color: '#f0a93b' },
    { key: 'totaltat', label: 'Total TAT', value: 2.8, color: '#3fcf8e' }
];
const TAT_MAX = 6;

const PRODUCT_BARS = [
    { key: 'homeloan', label: 'Home Loan', value: 28, color: '#4aa3ff' },
    { key: 'lap', label: 'LAP', value: 16, color: '#8b6ff0' },
    { key: 'businessloan', label: 'Business Loan', value: 8, color: '#f0a93b' },
    { key: 'balancetransfer', label: 'Balance Transfer', value: 6, color: '#3fcf8e' },
    { key: 'others', label: 'Others', value: 4, color: '#e2586b' }
];
const PRODUCT_BARS_MAX = 30;

const REJECTION_REASONS = [
    { key: 'insufficientincome', label: 'Insufficient Income', percent: 28, color: '#e2586b' },
    { key: 'highfoir', label: 'High FOIR', percent: 22, color: '#4aa3ff' },
    { key: 'creditbureauissues', label: 'Credit Bureau Issues', percent: 18, color: '#f0a93b' },
    { key: 'incompletedocuments', label: 'Incomplete Documents', percent: 14, color: '#8b6ff0' },
    { key: 'policynoncompliance', label: 'Policy Non-Compliance', percent: 10, color: '#3fcf8e' },
    { key: 'others', label: 'Others', percent: 8, color: '#8b93ab' }
];

const ICON_COLORS = {
    'accent-purple': '#8b6ff0',
    'accent-blue': '#4aa3ff',
    'accent-amber': '#f0a93b',
    'accent-green': '#3fcf8e',
    'accent-red': '#e2586b',
    'accent-slate': '#8b93ab'
};

export default class CreditReviewSummaryDashboard extends LightningElement {
    @track userFirstName;
    @track overviewRange = 'This Week';
    @track activeTab = 'all';
    @track currentPage = 1;
    @track searchTerm = '';
    @track productFilter = 'Product';
    @track priorityFilter = 'Priority';
    @track assignedDateFilter = 'Assigned Date';
    @track isQueueExpanded = false;
    @track isPerformanceExpanded = false;
    @track isTasksExpanded = false;
    @track performanceActiveTab = 'overview';
    @track performanceRange = 'This Month';
    @track tasksActiveTab = 'mytasks';
    @track openDropdown = null; // 'overview' | 'product' | 'priority' | 'assigneddate' | 'performancerange' | null

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

    get currentTimeFormatted() {
        return new Date().toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    // ---- My Overview stat strip ----
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
                isQuestion: card.icon === 'question',
                isHourglass: card.icon === 'hourglass',
                isCheck: card.icon === 'check',
                isCross: card.icon === 'cross'
            };
        });
    }

    get overviewDropdownOptions() {
        return ['Today', 'This Week', 'This Month', 'This Quarter'];
    }

    get isOverviewDropdownOpen() {
        return this.openDropdown === 'overview';
    }

    handleOverviewDropdownToggle() {
        this.toggleDropdown('overview');
    }

    handleOverviewOptionSelect(event) {
        this.overviewRange = event.currentTarget.dataset.value;
        this.openDropdown = null;
    }

    // ---- Action Required ----
    get actionRequiredTotal() {
        return ACTION_REQUIRED_TOTAL;
    }

    get actionRequiredItems() {
        return ACTION_REQUIRED.map((item) => {
            const glyphColor = ICON_COLORS[item.accent] || '#4aa3ff';
            return {
                ...item,
                iconClass: `ar-icon ${item.accent}`,
                glyphStyle: `fill:${glyphColor}`,
                isQuestion: item.icon === 'question',
                isHourglass: item.icon === 'hourglass',
                isPeople: item.icon === 'people',
                isCheck: item.icon === 'check'
            };
        });
    }

    handleViewAllActionRequired() {
        this.dispatchEvent(new CustomEvent('viewallactionrequired'));
    }

    handleActionRowClick(event) {
        const rowKey = event.currentTarget.dataset.key;
        this.dispatchEvent(new CustomEvent('actionrowclick', { detail: { rowKey } }));
    }

    // ---- My Application Queue ----
    get queueTabs() {
        return QUEUE_TABS.map((tab) => ({
            ...tab,
            tabClass: `queue-tab ${this.activeTab === tab.key ? 'queue-tab-active' : ''}`
        }));
    }

    handleTabClick(event) {
        this.activeTab = event.currentTarget.dataset.key;
        this.currentPage = 1;
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    get productOptions() {
        return PRODUCT_OPTIONS;
    }

    get priorityOptions() {
        return PRIORITY_OPTIONS;
    }

    get assignedDateOptions() {
        return ASSIGNED_DATE_OPTIONS;
    }

    get isProductDropdownOpen() {
        return this.openDropdown === 'product';
    }

    get isPriorityDropdownOpen() {
        return this.openDropdown === 'priority';
    }

    get isAssignedDateDropdownOpen() {
        return this.openDropdown === 'assigneddate';
    }

    handleProductDropdownToggle() {
        this.toggleDropdown('product');
    }

    handlePriorityDropdownToggle() {
        this.toggleDropdown('priority');
    }

    handleAssignedDateDropdownToggle() {
        this.toggleDropdown('assigneddate');
    }

    handleProductOptionSelect(event) {
        this.productFilter = event.currentTarget.dataset.value;
        this.openDropdown = null;
    }

    handlePriorityOptionSelect(event) {
        this.priorityFilter = event.currentTarget.dataset.value;
        this.openDropdown = null;
    }

    handleAssignedDateOptionSelect(event) {
        this.assignedDateFilter = event.currentTarget.dataset.value;
        this.openDropdown = null;
    }

    handleResetFilters() {
        this.searchTerm = '';
        this.productFilter = 'Product';
        this.priorityFilter = 'Priority';
        this.assignedDateFilter = 'Assigned Date';
        this.openDropdown = null;
    }

    get queueRows() {
        return QUEUE_ROWS.map((row) => ({
            ...row,
            priorityClass: `priority-badge ${row.priorityColor}`,
            stageClass: `stage-badge ${row.stageColor}`
        }));
    }

    get queueTotal() {
        return QUEUE_TOTAL;
    }

    get queueShowingLabel() {
        const start = (this.currentPage - 1) * QUEUE_PAGE_SIZE + 1;
        const end = Math.min(this.currentPage * QUEUE_PAGE_SIZE, QUEUE_TOTAL);
        return `Showing ${start}-${end} of ${QUEUE_TOTAL} applications`;
    }

    get queuePageNumbers() {
        const totalPages = Math.ceil(QUEUE_TOTAL / QUEUE_PAGE_SIZE);
        const pages = [];
        for (let i = 1; i <= totalPages; i++) {
            pages.push({ key: `page-${i}`, value: i, pageClass: `queue-page-num ${this.currentPage === i ? 'queue-page-active' : ''}` });
        }
        return pages;
    }

    get isPrevDisabled() {
        return this.currentPage <= 1;
    }

    get isNextDisabled() {
        return this.currentPage >= Math.ceil(QUEUE_TOTAL / QUEUE_PAGE_SIZE);
    }

    handlePrevPage() {
        if (!this.isPrevDisabled) {
            this.currentPage -= 1;
        }
    }

    handleNextPage() {
        if (!this.isNextDisabled) {
            this.currentPage += 1;
        }
    }

    handlePageNumberClick(event) {
        this.currentPage = Number(event.currentTarget.dataset.page);
    }

    handleReviewClick(event) {
        const appNo = event.currentTarget.dataset.appno;
        this.dispatchEvent(new CustomEvent('reviewapplication', { detail: { appNo } }));
    }

    handleViewAllQueue() {
        this.dispatchEvent(new CustomEvent('viewallqueue'));
    }

    // ---- Collapsible sections ----
    get queueChevronClass() {
        return `crs-chevron ${this.isQueueExpanded ? 'crs-chevron-open' : ''}`;
    }

    get performanceChevronClass() {
        return `crs-chevron ${this.isPerformanceExpanded ? 'crs-chevron-open' : ''}`;
    }

    get tasksChevronClass() {
        return `crs-chevron ${this.isTasksExpanded ? 'crs-chevron-open' : ''}`;
    }

    get tasksAlertsCount() {
        return TASKS_ALERTS_TOTAL;
    }

    // ---- My Tasks & Alerts (expanded body) ----
    get taskAlertTabs() {
        return [
            { key: 'mytasks', label: 'My Tasks', count: MY_TASKS_TAB_COUNT },
            { key: 'alerts', label: 'Alerts', count: ALERTS_TAB_COUNT }
        ].map((tab) => ({
            ...tab,
            tabClass: `queue-tab ${this.tasksActiveTab === tab.key ? 'queue-tab-active' : ''}`
        }));
    }

    get isMyTasksTab() {
        return this.tasksActiveTab === 'mytasks';
    }

    handleTasksTabClick(event) {
        this.tasksActiveTab = event.currentTarget.dataset.key;
    }

    get myTasksRows() {
        return MY_TASKS_ROWS.map((row) => ({
            ...row,
            dotClass: `task-dot task-dot-${row.dot}`,
            priorityClass: `priority-badge ${row.priorityColor}`
        }));
    }

    get alertItems() {
        return ALERT_ITEMS.map((item) => ({
            ...item,
            dotClass: `task-dot task-dot-${item.severity}`
        }));
    }

    get recentUpdates() {
        return RECENT_UPDATES.map((update) => ({
            ...update,
            isInfo: update.icon === 'info',
            isWarning: update.icon === 'warning',
            iconClass: `ta-update-icon ${update.icon === 'warning' ? 'ta-update-icon-warning' : 'ta-update-icon-info'}`
        }));
    }

    handleTaskRowOpenClick(event) {
        const appNo = event.currentTarget.dataset.appno;
        this.dispatchEvent(new CustomEvent('opentask', { detail: { appNo } }));
    }

    handleToggleQueue() {
        this.isQueueExpanded = !this.isQueueExpanded;
    }

    handleTogglePerformance() {
        this.isPerformanceExpanded = !this.isPerformanceExpanded;
    }

    handleToggleTasks() {
        this.isTasksExpanded = !this.isTasksExpanded;
    }

    // ---- Performance & Insights (Overview tab) ----
    get performanceTabs() {
        return PERFORMANCE_TABS.map((tab) => ({
            ...tab,
            tabClass: `pi-tab ${this.performanceActiveTab === tab.key ? 'pi-tab-active' : ''}`
        }));
    }

    get isPerformanceOverviewTab() {
        return this.performanceActiveTab === 'overview';
    }

    handlePerformanceTabClick(event) {
        this.performanceActiveTab = event.currentTarget.dataset.key;
    }

    get performanceDropdownOptions() {
        return PERFORMANCE_RANGE_OPTIONS;
    }

    get isPerformanceRangeDropdownOpen() {
        return this.openDropdown === 'performancerange';
    }

    handlePerformanceRangeDropdownToggle(event) {
        event.stopPropagation();
        this.toggleDropdown('performancerange');
    }

    handlePerformanceRangeOptionSelect(event) {
        event.stopPropagation();
        this.performanceRange = event.currentTarget.dataset.value;
        this.openDropdown = null;
    }

    get reviewTrendDates() {
        return REVIEW_TREND_DATES;
    }

    get reviewTrendSeries() {
        const buildPoints = (values) =>
            values.map((val, index) => {
                const x = Math.round((index / (REVIEW_TREND_DATES.length - 1)) * 100);
                const y = Math.round(100 - (val / REVIEW_TREND_MAX) * 100);
                return { x, y };
            });

        const toPolyline = (points) => points.map((p) => `${p.x},${p.y}`).join(' ');

        const series = [
            { key: 'reviewed', label: 'Reviewed', color: '#4aa3ff', values: REVIEW_TREND_SERIES.reviewed },
            { key: 'approved', label: 'Approved', color: '#3fcf8e', values: REVIEW_TREND_SERIES.approved }
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

    get creditDecisionTotal() {
        return CREDIT_DECISION_TOTAL;
    }

    get creditDecisionSegments() {
        return this.buildPiDonutSegments(CREDIT_DECISION_CATEGORIES);
    }

    buildPiDonutSegments(categories) {
        let cumulativePercent = 0;
        return categories.map((cat) => {
            const arcLength = (cat.percent / 100) * PI_DONUT_CIRCUMFERENCE;
            const dashArray = `${arcLength} ${PI_DONUT_CIRCUMFERENCE - arcLength}`;
            const dashOffset = PI_DONUT_CIRCUMFERENCE * (1 - cumulativePercent / 100);
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

    get tatBars() {
        return TAT_BARS.map((bar) => ({
            ...bar,
            barStyle: `height:${Math.min(100, (bar.value / TAT_MAX) * 100)}%;background:${bar.color}`
        }));
    }

    get productBars() {
        return PRODUCT_BARS.map((bar) => ({
            ...bar,
            barStyle: `height:${Math.min(100, (bar.value / PRODUCT_BARS_MAX) * 100)}%;background:${bar.color}`
        }));
    }

    get rejectionReasons() {
        return REJECTION_REASONS.map((reason) => ({
            ...reason,
            barWidthStyle: `width:${reason.percent}%;background:${reason.color}`,
            percentLabel: `${reason.percent}%`
        }));
    }

    toggleDropdown(name) {
        this.openDropdown = this.openDropdown === name ? null : name;
    }
}
/* __________________________GenAI: Generated code ends here______________________________ */