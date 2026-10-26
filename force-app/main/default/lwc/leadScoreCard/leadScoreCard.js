//_______________This Code was generated using GenAI tool: Codify, Please check for accuracy_______________//
        import { LightningElement, api, wire } from 'lwc';
        import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
        import { refreshApex } from '@salesforce/apex';

        const FIELDS = [
            'Lead.Age__c',
            'Lead.Income_Range__c',
            //'Lead.Education_Profile__c',
            'Lead.Required_loan_amount__c',
            'Lead.Panned_Country_for_Study__c'
        ];

        export default class LeadScoreCard extends LightningElement {

            @api recordId;

            age;
            incomeRange;
           // education;
            requestedAmount;
             requiredLoanAmount;
            country;
            wiredLeadResult;

            // ── Wire: get Lead record ────────────────────────────────────────────────
            @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
            wiredLead(result) {
                this.wiredLeadResult = result;

                const { data, error } = result;
                if (data) {
                    this.age = getFieldValue(data, 'Lead.Age__c');
                    this.incomeRange = getFieldValue(data, 'Lead.Income_Range__c');
                    //this.education = getFieldValue(data, 'Lead.Education_Profile__c');
                    //this.requestedAmount = getFieldValue(data, 'Lead.Requested_amount__c');
                    this.requiredLoanAmount = getFieldValue(
                        data,
                        'Lead.Required_loan_amount__c'
                    );
                    this.country = getFieldValue(data, 'Lead.Panned_Country_for_Study__c');
                } else if (error) {
                    console.error('LeadScoreCard wiredLead error:', error);
                }
            }

            @api
            refreshScoreCard() {
                return refreshApex(this.wiredLeadResult);
            }

            // ── Individual scores ────────────────────────────────────────────────────
            get ageScore() { return this.age ? 10 : 0; }
            get incomeScore() { return this.incomeRange ? 10 : 0; }
          //  get educationScore() { return this.education ? 10 : 0; }
            // get requestedAmountScore() { return this.requestedAmount ? 10 : 0; }
            get requiredLoanAmountScore() {
                return this.requiredLoanAmount ? 10 : 0;
            }
            get countryScore() { return this.country ? 10 : 0; }

            // ── Total ────────────────────────────────────────────────────────────────
            // get score() {
            //     return this.ageScore + this.incomeScore + this.educationScore
            //         + this.requiredLoanAmountScore + this.countryScore;
            // }
            get score() {
                return this.ageScore
                    + this.incomeScore
                    + this.requiredLoanAmountScore
                    + this.countryScore;
            }

            // ── Completed count ──────────────────────────────────────────────────────
            get completedParameters() {
                let c = 0;
                if (this.age) c++;
                if (this.incomeRange) c++;
               // if (this.education) c++;
                //if (this.requestedAmount) c++;
                if (this.requiredLoanAmount) c++;

                if (this.country) c++;
                return c;
            }

            // ── Percentage ───────────────────────────────────────────────────────────
            get percentage() {
                return (this.completedParameters / 4) * 100;
            }

            // ── SVG ring progress ────────────────────────────────────────────────────
            get progressStyle() {
                const r = 50;
                const circ = 2 * Math.PI * r;
                const offset = circ - (this.percentage / 100) * circ;
                // Colour the ring: green ≥ 60%, amber ≥ 20%, red otherwise
                const strokeColour = this.percentage >= 60
                    ? '#2e7d32'
                    : this.percentage >= 20
                        ? '#e65100'
                        : '#d32f2f';
                return `stroke-dasharray:${circ};stroke-dashoffset:${offset};stroke:${strokeColour};`;
            }

            // ── Score number colour (mirrors ring colour) ────────────────────────────
            get scoreNumberStyle() {
                const colour = this.percentage >= 60
                    ? '#2e7d32'
                    : this.percentage >= 20
                        ? '#e65100'
                        : '#d32f2f';
                return `color:${colour};`;
            }

            // ── Grade text + badge CSS ────────────────────────────────────────────────
            get gradeText() {
                if (this.completedParameters === 4) return '✅ Complete';
                if (this.completedParameters >= 3) return '👍 Good';
                if (this.completedParameters >= 1) return '⚡ Partial';
                return '⭕ Incomplete';
            }

            get gradeBadgeClass() {
                if (this.completedParameters === 4) return 'grade-badge grade-badge--complete';
                if (this.completedParameters >= 3) return 'grade-badge grade-badge--good';
                if (this.completedParameters >= 1) return 'grade-badge grade-badge--partial';
                return 'grade-badge grade-badge--incomplete';
            }

            // ── Per-factor icon + class helpers ──────────────────────────────────────
            get ageIcon() { return this.age ? '↑' : '↓'; }
            get ageIconClass() { return this.age ? 'icon-positive' : 'icon-negative'; }
            get agePointsClass() { return this.age ? 'points-positive' : 'points-negative'; }

            get incomeIcon() { return this.incomeRange ? '↑' : '↓'; }
            get incomeIconClass() { return this.incomeRange ? 'icon-positive' : 'icon-negative'; }
            get incomePointsClass() { return this.incomeRange ? 'points-positive' : 'points-negative'; }

            get educationIcon() { return this.education ? '↑' : '↓'; }
            get educationIconClass() { return this.education ? 'icon-positive' : 'icon-negative'; }
            get educationPointsClass() { return this.education ? 'points-positive' : 'points-negative'; }

            get requestedAmountIcon() { return this.requiredLoanAmount ? '↑' : '↓'; }
            get requestedAmountIconClass() { return this.requiredLoanAmount ? 'icon-positive' : 'icon-negative'; }
            get requestedAmountPointsClass() { return this.requiredLoanAmount ? 'points-positive' : 'points-negative'; }

            get countryIcon() { return this.country ? '↑' : '↓'; }
            get countryIconClass() { return this.country ? 'icon-positive' : 'icon-negative'; }
            get countryPointsClass() { return this.country ? 'points-positive' : 'points-negative'; }
        }
        //__________________________GenAI: Generated code ends here______________________________//