import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class Hl_incomeAssessmentTabsRenderingCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @api tabValue;
    @api showCalculator = false;
    isSalariedIndividual = false;
    isCashProfit = false;
    isSalariedNri = false;
    isSepMultiplier = false;
    isdirectorRenumeration = false;
    isFinalAssessment= false;
    isUndefined = false;
    isBanking = false;
    isGrossMargin = false;
    isRentalIncome = false;
    isMerchantNavy = false;
    liquidIncomeProgram = false;
    isLowLtv= false;
    //changes by Kunal Bisht for SFHL-1647 - start
    isMixedRental = false;
    isAssessedIncomeProgram = false;
    //changes by Kunal Bisht for SFHL-1647 - end

    connectedCallback() {
        console.log('recordId: ' + this.recordId);
        console.log('tabValue: ' + this.tabValue);

        const normalizedTabValue = this.tabValue?.replace(/\s+/g, ' ').trim();

        this.isSalariedIndividual = false;
        this.isSalariedNri = false;
        this.isCashProfit = false;
        this.isFinalAssessment =false;
        this.isUndefined = false;
        this.isGrossMargin = false;
        this.isRentalIncome = false;
        this.isMerchantNavy = false;
        this.liquidIncomeProgram = false;
        this.isBanking=false;
        this.isLowLtv=false;
        //changes by Kunal Bisht for SFHL-1647 - start
        this.isMixedRental = false;
        this.isAssessedIncomeProgram = false;
        //changes by Kunal Bisht for SFHL-1647 - end

        if (this.tabValue === 'Cash Profit') {
            this.isCashProfit = true;
        } else if (this.tabValue === 'Salaried NRI') {
            this.isSalariedNri = true;
        } else if (this.tabValue === 'Salaried Individual') {
            this.isSalariedIndividual = true;
        }else if(this.tabValue === 'Sep Multiplier'){
            this.isSepMultiplier = true;
        }
        // else if(this.tabValue === 'Director Renumeration'){
        //      this.isdirectorRenumeration = true;
        // }
        else if(this.tabValue === 'Banking'){
             this.isBanking = true;
        }else if(this.tabValue === 'Gross Margin'){
             this.isGrossMargin = true;
        }else if(this.tabValue === 'Bank Rental Income'){ //change by Kunal Bisht for SFHL-1647
             this.isRentalIncome = true;
        }
        else if(this.tabValue === 'Final Assessment'){
            this.isFinalAssessment = true;
        }
        else if(this.tabValue === 'Merchant Navy'){
            this.isMerchantNavy = true;
        }
        else if(this.tabValue === 'Liquid Income Program'){
            this.liquidIncomeProgram = true;
        }
        else if(this.tabValue === 'Low LTV Program'){
            this.isLowLtv = true;
        }
        //changes by Kunal Bisht for SFHL-1647 - start
        else if(this.tabValue === 'Mixed Rental'){
            this.isMixedRental = true;
        }
        else if(this.tabValue === 'Assessed Income Program'){
            this.isAssessedIncomeProgram = true;
        }
        else if(normalizedTabValue == 'Director Renumeration'){
            this.isdirectorRenumeration = true;
        }
        //changes by Kunal Bisht for SFHL-1647 - end
        // else {
        //     this.isUndefined = true;
        // }
    }

    handleIncomeExpencesLoaded(event) {
        console.log('Child event received:', event.detail.change);
        this.dispatchEvent(
            new CustomEvent('incomeexpenceschanged', {
                detail: { change: event.detail.change }
            })
        );
    }
}