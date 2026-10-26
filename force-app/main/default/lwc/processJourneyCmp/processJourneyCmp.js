/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
import { LightningElement, api } from 'lwc';
import getProcessJourney from '@salesforce/apex/ProcessJourneyController.getProcessJourney';
import getApplicantSummary from '@salesforce/apex/ProcessJourneyController.getApplicantSummary';

const STATUS_CLASS_MAP = {
    Completed: 'is-completed',
    'In Progress': 'is-active',
    Pending: 'is-pending'
};

const STATUS_ICON_MAP = {
    Completed: 'utility:check',
    'In Progress': 'utility:threedots',
    Pending: 'utility:threedots'
};

export default class ProcessJourneyCmp extends LightningElement {
    @api recordId;

    isLoading = true;
    // Raw, undecorated stages as returned by Apex - kept separate from the
    // rendered "stages" list so activeStageName can be re-applied without
    // compounding CSS classes on every re-render (mirrors actionList being
    // the single source of truth in SalesLoginActionFlowCmp).
    rawStages = [];
    stages = [];
    leadNumber;
    customerName;
    // Mirrors the exclusive "isActive" click behavior in SalesLoginActionFlowCmp.handleClick:
    // only one section is open at a time, and clicking a header makes it the active one.
    activeSection = 'journey';
    // Mirrors SalesLoginActionFlowCmp.applicableStage / actionList[].isActive: the single
    // stage currently highlighted as active, set either by a direct click or by one of the
    // @api methods a parent component calls (changeMessage, highlightScreen, etc.).
    activeStageName;

    connectedCallback() {
        this.loadProcessJourney();
        this.loadApplicantSummary();
    }

    @api
    refresh() {
        this.loadProcessJourney();
        this.loadApplicantSummary();
    }

    // Same name/contract as SalesLoginActionFlowCmp.refreshActions: lets a parent
    // component force this panel to reload without knowing the internal method name.
    @api
    refreshActions() {
        this.loadProcessJourney();
        this.loadApplicantSummary();
    }

    // Mirrors SalesLoginActionFlowCmp.changeMessage: maps the screen a parent just
    // finished with to the next stage that should be highlighted, then activates it
    // after the same 1.5s delay (gives the backend completion status time to update).
    @api
    changeMessage(str) {
        let newStage;
        if (str === 'Application Information') {
            newStage = 'Income Eligibility';
        }
        if (str === 'Select Income Eligibility') {
            newStage = 'Document Details';
        }
        if (str === 'Exception Approval') {
            newStage = 'Login Checklist';
        } else if (str === 'Document Details') {
            newStage = 'Collateral';
        }
        if (str === 'Additional Information') {
            newStage = 'Other Information';
        }
        setTimeout(() => {
            this.refresh();
            if (newStage) {
                this.setActiveStage(newStage, true);
            }
        }, 1500);
    }

    // Mirrors SalesLoginActionFlowCmp.changeMessageFinal: same "Additional Information"
    // to next-stage mapping, without re-dispatching valuechange (matches the original,
    // which builds newStage but never fires the event off of it).
    @api
    changeMessageFinal(str) {
        let newStage;
        if (str === 'Additional Information') {
            newStage = 'Other Information';
        }
        setTimeout(() => {
            this.refresh();
            if (newStage) {
                this.setActiveStage(newStage, false);
            }
        }, 1500);
    }

    // Mirrors SalesLoginActionFlowCmp.changeColor: sets the active stage silently
    // (no valuechange dispatch) and refreshes the underlying data after the delay.
    @api
    changeColor(newStage) {
        setTimeout(() => {
            this.setActiveStage(newStage, false);
            this.refresh();
        }, 1500);
    }

    // Mirrors SalesLoginActionFlowCmp.highlightScreen: reloads the data immediately,
    // then marks the given stage active after the same 1.5s delay.
    @api
    highlightScreen(str) {
        this.refresh();
        setTimeout(() => {
            this.setActiveStage(str, false);
        }, 1500);
    }

    // Mirrors SalesLoginActionFlowCmp.navigateNext: accepts the stage name via
    // event.detail, activates it and re-dispatches valuechange, same as a direct click.
    @api
    navigateNext(event) {
        const stageName = event && event.detail;
        if (!stageName) {
            return;
        }
        this.setActiveStage(stageName, true);
    }

    loadProcessJourney() {
        if (!this.recordId) {
            return;
        }
        this.isLoading = true;
        getProcessJourney({ loanId: this.recordId })
            .then((result) => {
                this.rawStages = result || [];
                this.applyActiveState();
            })
            .catch((error) => {
                this.logError('getProcessJourney', error);
                this.rawStages = [];
                this.stages = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    loadApplicantSummary() {
        if (!this.recordId) {
            return;
        }
        getApplicantSummary({ loanId: this.recordId })
            .then((result) => {
                this.leadNumber = result ? result.leadNumber : null;
                this.customerName = result ? result.customerName : null;
            })
            .catch((error) => {
                this.logError('getApplicantSummary', error);
            });
    }

    // Same pattern as SalesLoginActionFlowCmp.handleClick's actionList.forEach: sets the
    // clicked/targeted stage as the single active one and re-decorates the rendered list.
    setActiveStage(stageName, dispatchChange) {
        this.activeStageName = stageName;
        this.applyActiveState();
        if (dispatchChange) {
            const valueChangeEvent = new CustomEvent('valuechange', {
                detail: { value: '', name: stageName }
            });
            this.dispatchEvent(valueChangeEvent);
        }
    }

    applyActiveState() {
        this.stages = this.rawStages.map((stage) => this.decorateStage(stage));
    }

    decorateStage(stage) {
        const backendStatus = STATUS_CLASS_MAP[stage.status] ? stage.status : 'Pending';
        const hasManualActive = !!this.activeStageName;
        // Without a manual click/API override yet, the backend's own "In Progress" stage
        // (the first incomplete master stage) is the active one. Once a stage has been
        // explicitly selected, ONLY that stage is active - this stops the backend's
        // "In Progress" stage from ALSO rendering purple alongside a manually selected
        // stage that isn't actually the current one (two active-looking stages at once).
        const isActive = hasManualActive
            ? this.activeStageName === stage.name
            : backendStatus === 'In Progress';
        const displayStatus = isActive
            ? 'In Progress'
            : (hasManualActive && backendStatus === 'In Progress' ? 'Pending' : backendStatus);
        return {
            ...stage,
            key: stage.sequence + '-' + stage.name,
            itemClass: 'journey-item ' + STATUS_CLASS_MAP[displayStatus],
            numberClass: 'journey-number ' + STATUS_CLASS_MAP[displayStatus],
            statusClass: 'journey-status ' + STATUS_CLASS_MAP[displayStatus],
            connectorClass: 'journey-connector ' + STATUS_CLASS_MAP[backendStatus],
            statusIcon: STATUS_ICON_MAP[displayStatus],
            // Always show the stage's sequence number, even when Completed - no checkmark icon.
            showCheckIcon: false,
            status: displayStatus
        };
    }

    // Same pattern as SalesLoginActionFlowCmp.handleClick: clicking a stage sets it as the
    // single active stage and dispatches a "valuechange" event carrying the stage name so
    // the hosting component can open/navigate to the matching section, exactly like clicking
    // a path item does there.
    handleStageClick(event) {
        const stageName = event.currentTarget.dataset.name;
        if (!stageName) {
            return;
        }
        this.setActiveStage(stageName, true);
    }

    // Same pattern as SalesLoginActionFlowCmp.handleClick: clicking a header sets it as the
    // single active section (exclusive open) rather than independently toggling booleans.
    toggleJourney() {
        this.activeSection = 'journey';
    }

    toggleSummary() {
        this.activeSection = 'summary';
    }

    get isJourneyOpen() {
        return this.activeSection === 'journey';
    }

    get isSummaryOpen() {
        return this.activeSection === 'summary';
    }

    get journeyChevron() {
        return this.isJourneyOpen ? 'utility:chevronup' : 'utility:chevrondown';
    }

    get summaryChevron() {
        return this.isSummaryOpen ? 'utility:chevronup' : 'utility:chevrondown';
    }

    logError(source, error) {
        const message = (error && error.body && error.body.message) || (error && error.message) || 'Unknown error';
        // eslint-disable-next-line no-console
        console.error('ProcessJourneyCmp.' + source + ' - ' + message);
    }
}
/*__________________________GenAI: Generated code ends here______________________________*/