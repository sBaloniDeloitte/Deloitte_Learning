import { LightningElement, wire } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import USER_NAME from '@salesforce/schema/User.Name';
import HOME_IMG from '@salesforce/resourceUrl/home';

const USER_FIELDS = [USER_NAME];

export default class SalesDashboard extends LightningElement {

    userName = 'User';

    @wire(getRecord, {
        recordId: USER_ID,
        fields: USER_FIELDS
    })
    wiredUser({ data, error }) {
        if (data) {
            this.userName = data.fields.Name.value;
        } else if (error) {
            console.error('Error fetching user:', error);
        }
    }

    get currentDate() {
        const today = new Date();

        return today.toLocaleDateString('en-US', {
            weekday: 'short',
            month: 'short',
            day: 'numeric',
            year: 'numeric'
        });
    }

    get footerStyle() {
        return `background-image: linear-gradient(90deg, rgba(10, 21, 36, 0.55), rgba(10, 21, 36, 0.25)), url(${HOME_IMG}); background-size: cover; background-position: center; background-repeat: no-repeat; filter: brightness(1.35) contrast(1.05) saturate(1.15);`;
    }

    get greeting() {
        const hour = new Date().getHours();

        if (hour < 12) {
            return 'Good Morning';
        } else if (hour < 17) {
            return 'Good Afternoon';
        } else {
            return 'Good Evening';
        }
    }

    // Static data for UI only.
    // Later these values will come from Apex/Salesforce data.

    actionItems = [
        {
            id: 1,
            label: 'Query Related Applications',
            description: 'Applications with open queries from credit/operations',
            count: 8,
            type: 'query',
            icon: 'utility:question'
        },
        {
            id: 2,
            label: 'Completed Applications Due for Sanction',
            description: 'Applications ready for sanction',
            count: 10,
            type: 'sanction',
            icon: 'utility:hourglass'
        },
        {
            id: 3,
            label: 'Sanctioned & Undisbursed',
            description: 'Approved but not yet disbursed',
            count: 14,
            type: 'approved',
            icon: 'utility:approval'
        },
        {
            id: 4,
            label: 'Completed Applications',
            description: 'Applications completed in the selected period',
            count: 18,
            type: 'completed',
            icon: 'utility:success'
        }
    ];

    kpiCards = [
        {
            id: 1,
            title: 'New Leads',
            value: '52',
            change: '+18%',
            icon: 'utility:adduser',
            iconClass: 'kpi-icon kpi-icon-blue'
        },
        {
            id: 2,
            title: 'Applications Created',
            value: '36',
            change: '+12%',
            icon: 'utility:file',
            iconClass: 'kpi-icon kpi-icon-purple'
        },
        {
            id: 3,
            title: 'Applications Submitted',
            value: '28',
            change: '+27%',
            icon: 'utility:send',
            iconClass: 'kpi-icon kpi-icon-blue'
        },
        {
            id: 4,
            title: 'Applications Approved',
            value: '12',
            change: '+33%',
            icon: 'utility:success',
            iconClass: 'kpi-icon kpi-icon-green'
        },
        {
            id: 5,
            title: 'Due for Sanction',
            value: '10',
            change: '+25%',
            icon: 'utility:hourglass',
            iconClass: 'kpi-icon kpi-icon-orange'
        },
        {
            id: 6,
            title: 'Sanctioned & Undisbursed',
            value: '14',
            change: '+33%',
            icon: 'utility:coin',
            iconClass: 'kpi-icon kpi-icon-purple'
        },
        {
            id: 7,
            title: 'Potential Loan Value',
            value: '₹12.4 Cr',
            change: '+28%',
            icon: 'utility:moneybag',
            iconClass: 'kpi-icon kpi-icon-green'
        }
    ];

    // =========================================================
    // COLLAPSIBLE SECTIONS — My Application Pipeline,
    // Performance & Insights, My Tasks & Alerts
    // =========================================================

    isPipelineOpen = false;
    isPerformanceOpen = false;
    isTasksOpen = false;

    togglePipeline() {
        this.isPipelineOpen = !this.isPipelineOpen;
    }

    togglePerformance() {
        this.isPerformanceOpen = !this.isPerformanceOpen;
    }

    toggleTasks() {
        this.isTasksOpen = !this.isTasksOpen;
    }

    get pipelineSectionClass() {
        return 'dashboard-section collapsible-section' + (this.isPipelineOpen ? ' collapsible-section-open' : '');
    }

    get performanceSectionClass() {
        return 'dashboard-section collapsible-section' + (this.isPerformanceOpen ? ' collapsible-section-open' : '');
    }

    get tasksSectionClass() {
        return 'dashboard-section collapsible-section' + (this.isTasksOpen ? ' collapsible-section-open' : '');
    }

    get pipelineArrowClass() {
        return 'collapse-arrow' + (this.isPipelineOpen ? ' collapse-arrow-open' : '');
    }

    get performanceArrowClass() {
        return 'collapse-arrow' + (this.isPerformanceOpen ? ' collapse-arrow-open' : '');
    }

    get tasksArrowClass() {
        return 'collapse-arrow' + (this.isTasksOpen ? ' collapse-arrow-open' : '');
    }

    // =========================================================
    // PERFORMANCE & INSIGHTS — static UI data
    // =========================================================

    selectedPerformanceTab = 'Applications';

    performanceTabs = [
        { id: 1, label: 'Applications', value: 'Applications' },
        { id: 2, label: 'Conversion', value: 'Conversion' },
        { id: 3, label: 'Loan Value', value: 'Loan Value' },
        { id: 4, label: 'Products', value: 'Products' }
    ];

    get performanceTabItems() {
        return this.performanceTabs.map((tab) => ({
            ...tab,
            itemClass: 'performance-tab' + (tab.value === this.selectedPerformanceTab ? ' performance-tab-active' : '')
        }));
    }

    get isApplicationsTab() {
        return this.selectedPerformanceTab === 'Applications';
    }

    handlePerformanceTabClick(event) {
        this.selectedPerformanceTab = event.currentTarget.dataset.value;
    }

    // =========================================================
    // MY TASKS & ALERTS — static UI data
    // =========================================================

    selectedTaskFilter = 'All';
    selectedAlertFilter = 'All';

    taskFilters = [
        { id: 1, label: 'All (8)', value: 'All' },
        { id: 2, label: 'Today (3)', value: 'Today' },
        { id: 3, label: 'This Week (4)', value: 'This Week' },
        { id: 4, label: 'Overdue (1)', value: 'Overdue' }
    ];

    alertFilters = [
        { id: 1, label: 'All (5)', value: 'All' },
        { id: 2, label: 'SLA (2)', value: 'SLA' },
        { id: 3, label: 'System (2)', value: 'System' },
        { id: 4, label: 'Product Updates (1)', value: 'Product Updates' }
    ];

    get taskFilterItems() {
        return this.taskFilters.map((filter) => ({
            ...filter,
            itemClass: 'performance-tab' + (filter.value === this.selectedTaskFilter ? ' performance-tab-active' : '')
        }));
    }

    get alertFilterItems() {
        return this.alertFilters.map((filter) => ({
            ...filter,
            itemClass: 'performance-tab' + (filter.value === this.selectedAlertFilter ? ' performance-tab-active' : '')
        }));
    }

    handleTaskFilterClick(event) {
        this.selectedTaskFilter = event.currentTarget.dataset.value;
    }

    handleAlertFilterClick(event) {
        this.selectedAlertFilter = event.currentTarget.dataset.value;
    }

    tasks = [
        {
            id: 1,
            name: 'Follow up for income documents',
            relatedTo: 'LOS0001257',
            dueDate: 'Today',
            priority: 'High',
            priorityClass: 'priority-badge priority-high',
            dotClass: 'pipeline-dot pipeline-dot-red'
        },
        {
            id: 2,
            name: 'Collect property documents',
            relatedTo: 'LOS0001258',
            dueDate: 'Today',
            priority: 'High',
            priorityClass: 'priority-badge priority-high',
            dotClass: 'pipeline-dot pipeline-dot-red'
        },
        {
            id: 3,
            name: 'Update NACH details',
            relatedTo: 'LOS0001260',
            dueDate: '5 Sep 2026',
            priority: 'Medium',
            priorityClass: 'priority-badge priority-medium',
            dotClass: 'pipeline-dot pipeline-dot-orange'
        },
        {
            id: 4,
            name: 'Schedule customer meeting',
            relatedTo: 'LOS0001261',
            dueDate: '5 Sep 2026',
            priority: 'Medium',
            priorityClass: 'priority-badge priority-medium',
            dotClass: 'pipeline-dot pipeline-dot-orange'
        },
        {
            id: 5,
            name: 'Call for clarification on query',
            relatedTo: 'LOS0001256',
            dueDate: '6 Sep 2026',
            priority: 'Low',
            priorityClass: 'priority-badge priority-low',
            dotClass: 'pipeline-dot pipeline-dot-green'
        }
    ];

    alerts = [
        {
            id: 1,
            message: '3 applications pending customer documents',
            time: '1h ago',
            icon: 'utility:warning',
            iconClass: 'alert-icon alert-icon-red'
        },
        {
            id: 2,
            message: '1 application at risk of SLA breach',
            time: '2h ago',
            icon: 'utility:warning',
            iconClass: 'alert-icon alert-icon-red'
        },
        {
            id: 3,
            message: 'Home Loan interest rate updated',
            time: '4h ago',
            icon: 'utility:info',
            iconClass: 'alert-icon alert-icon-orange'
        },
        {
            id: 4,
            message: 'New product feature released',
            time: '6h ago',
            icon: 'utility:info',
            iconClass: 'alert-icon alert-icon-blue'
        },
        {
            id: 5,
            message: 'Scheduled system maintenance on 6 Sep, 10 PM – 2 AM',
            time: '1d ago',
            icon: 'utility:info',
            iconClass: 'alert-icon alert-icon-blue'
        }
    ];

    // =========================================================
    // MY APPLICATION PIPELINE — static UI data
    // =========================================================

    searchTerm = '';
    selectedPipelineFilter = 'All';

    pipelineFilters = [
        { id: 1, label: 'All', count: 128, value: 'All', dotClass: 'pipeline-dot pipeline-dot-blue' },
        { id: 2, label: 'In Progress', count: 32, value: 'In Progress', dotClass: 'pipeline-dot pipeline-dot-blue' },
        { id: 3, label: 'Under Review', count: 28, value: 'Under Review', dotClass: 'pipeline-dot pipeline-dot-purple' },
        { id: 4, label: 'Approved', count: 22, value: 'Approved', dotClass: 'pipeline-dot pipeline-dot-green' },
        { id: 5, label: 'Sanctioned', count: 14, value: 'Sanctioned', dotClass: 'pipeline-dot pipeline-dot-orange' },
        { id: 6, label: 'Disbursed', count: 8, value: 'Disbursed', dotClass: 'pipeline-dot pipeline-dot-teal' },
        { id: 7, label: 'Rejected', count: 12, value: 'Rejected', dotClass: 'pipeline-dot pipeline-dot-red' }
    ];

    get pipelineFilterItems() {
        return this.pipelineFilters.map((filter) => ({
            ...filter,
            itemClass: 'pipeline-filter' + (filter.value === this.selectedPipelineFilter ? ' pipeline-filter-active' : '')
        }));
    }

    handlePipelineFilterClick(event) {
        this.selectedPipelineFilter = event.currentTarget.dataset.value;
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    applications = [
        {
            id: 1,
            appNo: 'LOS0001256',
            customerName: 'Vikram Rao',
            product: 'Home Loan',
            appDate: '3 Sep 2026',
            stage: 'In Progress',
            stageClass: 'stage-badge stage-inprogress',
            sla: '2'
        },
        {
            id: 2,
            appNo: 'LOS0001257',
            customerName: 'Pooja Iyer',
            product: 'LAP',
            appDate: '3 Sep 2026',
            stage: 'Under Review',
            stageClass: 'stage-badge stage-underreview',
            sla: '1'
        },
        {
            id: 3,
            appNo: 'LOS0001258',
            customerName: 'Arjun Nair',
            product: 'Home Loan',
            appDate: '2 Sep 2026',
            stage: 'Approved',
            stageClass: 'stage-badge stage-approved',
            sla: '2'
        },
        {
            id: 4,
            appNo: 'LOS0001259',
            customerName: 'Rakesh Gupta',
            product: 'Business Loan',
            appDate: '2 Sep 2026',
            stage: 'Sanctioned',
            stageClass: 'stage-badge stage-sanctioned',
            sla: '3'
        },
        {
            id: 5,
            appNo: 'LOS0001260',
            customerName: 'Meera Sinha',
            product: 'LAP',
            appDate: '1 Sep 2026',
            stage: 'Disbursed',
            stageClass: 'stage-badge stage-disbursed',
            sla: '-'
        }
    ];
}