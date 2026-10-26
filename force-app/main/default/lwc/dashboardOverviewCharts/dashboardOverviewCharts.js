/* _______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________ */
import { LightningElement, api } from 'lwc';

// DECISION (interim phase): all three dashboards below use static/mock
// values. The Apex controller (DashboardOverviewController) that will
// replace these with live SOQL aggregations is deferred until the
// Lead.Status / Opportunity.StageName bucket mapping is confirmed with
// business. See project decision record for details. Getter names below
// are kept stable so swapping to @wire later is a data-source change only.
//
// Charts are rendered with plain SVG + CSS (no Chart.js wrapper library)
// so this component has zero LWC dependencies beyond base lightning-*.
// Radius enlarged (70 -> 76) and stroke-width reduced (see .html, 30 -> 18)
// to match the thinner ring proportions from the previously shared
// dashboard version -- a bigger hole relative to the ring band.
const DONUT_RADIUS = 76;
const DONUT_CIRCUMFERENCE = 2 * Math.PI * DONUT_RADIUS;

export default class DashboardOverviewCharts extends LightningElement {
    // Visibility contract: a parent tab container sets isHidden to true to
    // hide this component when a different tab is active. Boolean @api
    // properties must default to false per LWC lint rules, and false here
    // means "visible" -- so the component still renders by default when
    // dropped directly onto a Lightning page without a parent wiring it in.
    @api isHidden = false;

    // ---- Dashboard 1: Loan Applications (staircase bar funnel) ----
    leadsGenerated = 842;
    applicationsSubmitted = 476;
    sanctionsApproved = 298;

    // Shared helper -- formats a ratio as a one-decimal percentage string,
    // used by both dashboard 1's step/footer badges and dashboard 2's
    // "Converted" center pill.
    formatPct(numerator, denominator) {
        if (!denominator) {
            return '0.0%';
        }
        return `${((numerator / denominator) * 100).toFixed(1)}%`;
    }

    get totalLeadsBadge() {
        return `${this.leadsGenerated} TOTAL LEADS`;
    }

    get overallConversionPct() {
        return this.formatPct(this.sanctionsApproved, this.leadsGenerated);
    }

    // Width-only steps (no per-step indent) -- each bar is centered on the
    // same axis via CSS (margin: 0 auto against a full-width line), so
    // steps 2 and 3 stay perfectly synchronized with step 1's center line
    // regardless of their narrower width.
    get loanAppSteps() {
        return [
            {
                key: 'step1',
                num: '01',
                label: 'Leads Generated',
                value: this.leadsGenerated,
                barStyle: 'width: 100%;',
                percentBadge: null,
                // showConnector renders the down-arrow between this bar and
                // the next one -- true for steps 1 and 2, omitted (falsy)
                // for the last step since there is nothing below it.
                showConnector: true
            },
            {
                key: 'step2',
                num: '02',
                label: 'Applications Submitted',
                value: this.applicationsSubmitted,
                barStyle: 'width: 73%;',
                percentBadge: this.formatPct(this.applicationsSubmitted, this.leadsGenerated),
                showConnector: true
            },
            {
                key: 'step3',
                num: '03',
                label: 'Sanctions Approved',
                value: this.sanctionsApproved,
                barStyle: 'width: 50%;',
                percentBadge: this.formatPct(this.sanctionsApproved, this.applicationsSubmitted),
                showConnector: false
            }
        ];
    }

    // ---- Dashboard 2: Lead Conversion Status (donut with satellite stats) ----
    leadConvertCount = 145;
    leadNotConvertCount = 95;
    inProgressCount = 120;
    rejectedCount = 60;

    get donutTotal() {
        return this.leadConvertCount + this.leadNotConvertCount + this.inProgressCount + this.rejectedCount;
    }

    get donutTotalLeadsBadge() {
        return `${this.donutTotal} LEADS`;
    }

    get convertedPct() {
        return this.formatPct(this.leadConvertCount, this.donutTotal);
    }

    get donutSegments() {
        // Colors form a single smooth blue gradient across Converted -> In
        // Progress -> Not Converted (light to medium blue) so the ring
        // reads as one continuous band, with Rejected as the sole dark
        // navy wedge -- matching the reference dashboard's look where
        // only the rejected segment stands out from the rest of the ring.
        const categories = [
            { label: 'Converted', count: this.leadConvertCount, color: '#8ec7f7' },
            { label: 'Not Converted', count: this.leadNotConvertCount, color: '#3f7fe0' },
            { label: 'In Progress', count: this.inProgressCount, color: '#5b9bf5' },
            { label: 'Rejected', count: this.rejectedCount, color: '#0b1a3a' }
        ];
        const total = this.donutTotal;
        let cumulativePercent = 0;

        return categories.map((cat) => {
            const percent = total > 0 ? (cat.count / total) * 100 : 0;
            const arcLength = (percent / 100) * DONUT_CIRCUMFERENCE;
            const dashArray = `${arcLength} ${DONUT_CIRCUMFERENCE - arcLength}`;
            const dashOffset = DONUT_CIRCUMFERENCE * (1 - cumulativePercent / 100);
            cumulativePercent += percent;

            return {
                key: cat.label,
                label: cat.label,
                count: cat.count,
                color: cat.color,
                pathStyle: `stroke: ${cat.color}`,
                dashArray,
                dashOffset,
                swatchStyle: `background: ${cat.color}`
            };
        });
    }

    // Four corner stat circles placed around the donut ring -- position
    // classes hook the absolute CSS placement (NW/NE/SW/SE).
    get satelliteStats() {
        return [
            { key: 'rejected', value: this.rejectedCount, label: 'Rejected', positionClass: 'satellite satellite-nw' },
            { key: 'converted', value: this.leadConvertCount, label: 'Converted', positionClass: 'satellite satellite-ne' },
            { key: 'inprogress', value: this.inProgressCount, label: 'In Progress', positionClass: 'satellite satellite-sw' },
            { key: 'notconverted', value: this.leadNotConvertCount, label: 'Not Converted', positionClass: 'satellite satellite-se' }
        ];
    }

    // ---- Dashboard 3: Application Status with Stages (bar + line, pure SVG/CSS) ----
    get stageLabels() {
        return ['Login', 'Credit Check', 'Sanction', 'Disbursement'];
    }

    get stageCounts() {
        return [68, 54, 41, 29];
    }

    get maxStageCount() {
        return Math.max(...this.stageCounts);
    }

    // Header pill, e.g. "68 ACTIVE" -- always keyed off the first stage's
    // count (the funnel's entry volume).
    get stageActiveBadge() {
        return `${this.stageCounts[0]} ACTIVE`;
    }

    // Bars are scaled to a MAX_HEIGHT_PERCENT ceiling (not a full 100%) so
    // the tallest bar always leaves headroom inside .bar-line-track for
    // its value label above it -- without this cap, the tallest bar's
    // label+bar combined height overflowed the track and rendered above
    // the container, out of alignment with the other bars' labels.
    get stageChartBars() {
        const max = this.maxStageCount;
        // Height increased 10% (78 -> 86) per design spec, still leaving
        // headroom above the tallest bar for its value label.
        const MAX_HEIGHT_PERCENT = 86;

        return this.stageLabels.map((label, index) => {
            const value = this.stageCounts[index];
            const heightPercent = max > 0 ? Math.round((value / max) * MAX_HEIGHT_PERCENT) : 0;
            // Stage-over-stage retention badge (e.g. "79.4%") shown inside
            // the bar -- omitted for the first stage since there is no
            // prior stage to compare against, matching the reference
            // dashboard.
            // First stage (largest bar) has no prior stage to compare
            // against for a calculated ratio, so a manual percentage value
            // is supplied here per business request instead of leaving it
            // blank.
            const percentBadge = index > 0 ? this.formatPct(value, this.stageCounts[index - 1]) : '94%';

            return {
                key: label,
                // Zero-padded serial number ("01", "02"...) rendered below
                // each column alongside its label, per the reference
                // dashboard layout.
                num: String(index + 1).padStart(2, '0'),
                label,
                value,
                barStyle: `height: ${heightPercent}%`,
                percentBadge
            };
        });
    }
}
/* __________________________GenAI: Generated code ends here______________________________ */