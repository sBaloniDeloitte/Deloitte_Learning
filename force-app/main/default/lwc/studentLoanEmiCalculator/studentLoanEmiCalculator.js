/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
import { LightningElement, api, track } from 'lwc';

export default class StudentLoanEmiCalculator extends LightningElement {

    // When true, this component renders only the modal (no built-in
    // trigger button) so a parent component can open it programmatically
    // via the exposed openModal() method.
    @api hideTrigger = false;

    @track isModalOpen = false;

    @track loanAmount = 100000;
    @track tenure = 60;
    @track interestRate = 7;

    @track emi = 0;
    @track principal = 0;
    @track interestAmount = 0;
    @track totalPayment = 0;
    @track principalPercent = 0;

    // -----------------------------
    // Modal open / close
    // -----------------------------
    @api
    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    // -----------------------------
    // Input Handlers
    // -----------------------------
    handleLoanAmount(event) {
        this.loanAmount = Number(event.target.value);
    }

    handleTenure(event) {
        this.tenure = Number(event.target.value);
    }

    handleInterest(event) {
        this.interestRate = Number(event.target.value);
    }

    // -----------------------------
    // EMI Calculation
    // -----------------------------
    calculateEmi() {
        const P = this.loanAmount;
        const n = this.tenure;
        const r = this.interestRate / (12 * 100);

        const emi =
            (P * r * Math.pow(1 + r, n)) /
            (Math.pow(1 + r, n) - 1);

        const totalPayment = emi * n;
        const interestAmount = totalPayment - P;

        this.emi = Math.round(emi);
        this.principal = Math.round(P);
        this.interestAmount = Math.round(interestAmount);
        this.totalPayment = Math.round(totalPayment);

        this.principalPercent =
            totalPayment > 0
                ? (P / totalPayment) * 100
                : 0;
    }

    // -----------------------------
    // Reset
    // -----------------------------
    handleReset() {
        this.loanAmount = 100000;
        this.tenure = 60;
        this.interestRate = 7;

        this.emi = 0;
        this.principal = 0;
        this.interestAmount = 0;
        this.totalPayment = 0;
        this.principalPercent = 0;
    }

    // -----------------------------
    // Validation
    // -----------------------------
    get isCalculateDisabled() {
        return !(
            this.loanAmount >= 100000 &&
            this.loanAmount <= 10000000 &&
            this.tenure >= 60 &&
            this.tenure <= 180 &&
            this.interestRate >= 7 &&
            this.interestRate <= 15
        );
    }

    // -----------------------------
    // Formatting
    // -----------------------------
    formatCurrency(value) {
        return new Intl.NumberFormat('en-IN').format(
            Math.round(value || 0)
        );
    }

    get formattedLoanAmount() {
        return this.formatCurrency(this.loanAmount);
    }

    get formattedEmi() {
        return this.formatCurrency(this.emi);
    }

    get formattedPrincipal() {
        return this.formatCurrency(this.principal);
    }

    get formattedInterest() {
        return this.formatCurrency(this.interestAmount);
    }

    get formattedTotalPayment() {
        return this.formatCurrency(this.totalPayment);
    }

    get chartStyle() {
        return `
            background:
            conic-gradient(
                #3B82F6 0% ${this.principalPercent}%,
                #0F1729 ${this.principalPercent}% 100%
            );
        `;
    }
}
/*__________________________GenAI: Generated code ends here______________________________*/