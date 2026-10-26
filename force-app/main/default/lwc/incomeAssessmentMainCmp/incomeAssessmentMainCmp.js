import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAllApplicants from '@salesforce/apex/Utility.getAllApplicants';
import getAllIncomeAssesmentRecords from '@salesforce/apex/HL_SalariedScreenController.getAllIncomeAssesmentRecords';
import Income_Assessment_Categorization from '@salesforce/label/c.Income_Assessment_Categorization';

export default class IncomeAssessmentMainCmp extends NavigationMixin(LightningElement) {
    @api recordId;
@api showCalculator = false;
    incomeAssessmentOptions = [];
    incomeAssessmentSelectedValues = [];
    incomeAssessmentData = {};
    // rightColumnOptions = [];
    // leftColumnOptions = [];
    midpoint;
    connectedCallback() {
        this.incomeAssessmentOptions = Income_Assessment_Categorization.split(';').map(item => ({ label: item.trim(), checked: false }));
        console.log('incomeAssessmentOptions Records: ', JSON.stringify(this.incomeAssessmentOptions));
        this.getApplicants();
    }

    handleIncomeExpencesLoaded(event) {
        console.log('Child event received hl_incomeAssessmentTabsRenderingCmp:', event.detail.change);
        this.getApplicants();
    }

    getApplicants() {
        getAllApplicants({ loanId: this.recordId })
        .then(() => {
            this.fetchIncomeAssesmentRecords();
        })
        .catch(error => console.error('getAllApplicants Error:', error));
    }

    fetchIncomeAssesmentRecords() {
        getAllIncomeAssesmentRecords({ loanId: this.recordId })
        .then(result => {
            console.log('IncomeAss Records: ', JSON.stringify(result));
            this.incomeAssessmentData = result;

            const alreadySelected = new Set(result?.availableParticulars || []);
            this.incomeAssessmentSelectedValues = [...alreadySelected];

            this.incomeAssessmentOptions = this.incomeAssessmentOptions.map(opt => ({
                label: opt.label,
                checked: alreadySelected.has(opt.label),
                disabled: alreadySelected.has(opt.label)
            }));
            console.log('incomeAssessmentOptions Records: ', JSON.stringify(this.incomeAssessmentOptions));
        })
        .catch(error => {
            console.error('getAllIncomeAssesmentRecords Error:', error);
        });
    }
    get leftColumnOptions() {
        // First 6 options
        return this.incomeAssessmentOptions.slice(0, 7); //change by Kunal Bisht for SFHL-1647
    }

    get rightColumnOptions() {
        // Remaining options after first 6
        return this.incomeAssessmentOptions.slice(7); //change by Kunal Bisht for SFHL-1647
    }

    handleCheckboxChange(event) {
        const { value, checked } = event.target;
        if (checked && !this.incomeAssessmentSelectedValues.includes(value)) {
            this.incomeAssessmentSelectedValues = [...this.incomeAssessmentSelectedValues,value];
        } else if (!checked) {
            this.incomeAssessmentSelectedValues =
                this.incomeAssessmentSelectedValues.filter(v => v !== value);
        }

        this.incomeAssessmentOptions = this.incomeAssessmentOptions.map(opt => ({
            ...opt,
            checked: this.incomeAssessmentSelectedValues.includes(opt.label)
        }));

        console.log('Selected Values: ', JSON.stringify(this.incomeAssessmentSelectedValues));
    }

    get tableRows() {
        const rows = [];
        const recMap = this.incomeAssessmentData.recValMap || {};
        for (const applicant in recMap) {
            const uniqueRecordTypes = [...new Set(recMap[applicant] || [])];
            rows.push({
                applicant,
                recordTypes: uniqueRecordTypes.join(', ')
            });
        }
        return rows;
    }
}