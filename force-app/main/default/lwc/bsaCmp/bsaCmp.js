import {
    LightningElement,
    track,
    api,
    wire
} from "lwc";
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import {
    NavigationMixin
} from 'lightning/navigation';
import getAllBankXnsRecords from "@salesforce/apex/COMM_BsaCmpController.getAllBankXnsRecords";
import updateCategory from "@salesforce/apex/COMM_BsaCmpController.updateCategory";
import getDerivedAnalysisRecords from "@salesforce/apex/COMM_BsaCmpController.getDerivedAnalysisRecords";
import getDerivedAnalysisRecordsAccWise from "@salesforce/apex/COMM_BsaCmpController.getDerivedAnalysisRecordsAccWise";
import getEligibleBankIds from "@salesforce/apex/COMM_BsaCmpController.getEligibleBankIds";
import getAllBankXnsBounceRecords from "@salesforce/apex/COMM_BsaCmpController.getAllBankXnsBounceRecords";
import getAllBankXnsRecordsFiltered from "@salesforce/apex/COMM_BsaCmpController.getAllBankXnsRecordsFiltered";
import calculateUtilization from "@salesforce/apex/COMM_BsaCmpController.calculateUtilization";
import getAllRelatedBanks from "@salesforce/apex/COMM_BsaCmpController.getAllRelatedBanks";
import getAllCategories from "@salesforce/apex/COMM_BsaCmpController.getAllCategories";
import getAllRelatedBanksAccountNumber from "@salesforce/apex/COMM_BsaCmpController.getAllRelatedBanksAccountNumber";
import STAGENAME_FIELD from "@salesforce/schema/Opportunity.StageName";
import OWNERID_FIELD from "@salesforce/schema/Opportunity.OwnerId";
import USER_ID from "@salesforce/user/Id";
import ProfileName from '@salesforce/schema/User.Profile.Name';
import { getRecord } from "lightning/uiRecordApi";
import { updateRecord } from "lightning/uiRecordApi";


export default class BsaCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @api selectedBanks = [];
    @api hasPsvOrDisbursalStage = false;
    @track isRendered = false;
    @track selectedRecords = [];
    @track updateCategoryButton = false;
    @track isShowModal = false;
    @track mainAccordianActiveSactions = ['XNS Consolidated'];
    @track consolidatedAccordianActiveSactions = ['CA Consolidated'];
    @track showOpenAll = true;
    @track spinner = false;
    @track daRecords = {};
    @track daSavingsRecords = [];
    @track daCurrentRecords = [];
    @track daOverdraftRecords = [];

    @track daCCODRecords = {};
    @track daSBRecords = {};

    @track bankOptions = [];
    @track categoryOptions = [];
    @track hasxnsData = false;

    options = [{
            label: "Non business transaction",
            value: "Non business transaction"
        },
        {
            label: "Transfer from self",
            value: "Transfer from self"
        },
        {
            label: "Loan disbursed",
            value: "Loan disbursed"
        },
        {
            label: "Cash deposit",
            value: "Cash deposit"
        },
        {
            label: "Cash withdrawl",
            value: "Cash withdrawl"
        },
        {
            label: "I/W cheque",
            value: "I/W cheque"
        },
        {
            label: "I/W return",
            value: "I/W return"
        },
        {
            label: "O/W return",
            value: "O/W return"
        },
        {
            label: "Interest charges",
            value: "Interest charges"
        },
        {
            label: "Circular Transaction",
            value: "Circular Transaction"
        },
        {
            label: "EMI",
            value: "EMI"
        },
        {
            label: "Business Credit",
            value: "Business Credit"
        },
        {
            label: "Business Debit",
            value: "Business Debit"
        },
        {
            label: "Utilities",
            value: "Utilities"
        },
        {
            label: "Transfer from self",
            value: "Transfer from self"
        },
        {
            label: "Transfer to self",
            value: "Transfer to self"
        }
    ];

    @track columns = [{
            label: 'Tic',
            fieldName: 'tic',
            sortable: true,
            initialWidth: 500
        },
        {
            label: 'Sep-23',
            fieldName: 'sep23',
            type: 'text',
            sortable: true
        },
        {
            label: 'Oct-23',
            fieldName: 'oct23',
            type: 'text',
            sortable: true
        },
        {
            label: 'Nov-23',
            fieldName: 'nov23',
            type: 'text',
            sortable: true
        },
        {
            label: 'Dec-23',
            fieldName: 'Dec23',
            type: 'text',
            sortable: true
        },
        {
            label: 'Jan-24',
            fieldName: 'jan24',
            type: 'text',
            sortable: true
        },
        {
            label: 'Feb-24',
            fieldName: 'feb24',
            type: 'text',
            sortable: true
        },
        {
            label: 'Mar-24',
            fieldName: 'mar24',
            type: 'text',
            sortable: true
        },
        {
            label: 'Apr-24',
            fieldName: 'apr24',
            type: 'text',
            sortable: true
        },
        {
            label: 'May-24',
            fieldName: 'may24',
            type: 'text',
            sortable: true
        }
    ];

    @track xnsColumns = [{
            label: 'Sl. No.',
            fieldName: 'slNo',
            sortable: true,
            initialWidth: 100
        },
        {
            label: 'Bank Name',
            fieldName: 'bankName',
            type: 'text',
            sortable: true,
            initialWidth: 200
        },
        {
            label: 'Account No.',
            fieldName: 'accountNo',
            type: 'text',
            sortable: true,
            initialWidth: 200
        },
        {
            label: 'Date',
            fieldName: 'dateOf',
            type: 'text',
            sortable: true,
            initialWidth: 100
        },
        {
            label: 'Cheque No.',
            fieldName: 'chequeNo',
            type: 'text',
            sortable: true,
            initialWidth: 100
        },
        {
            label: 'Description',
            fieldName: 'description',
            type: 'text',
            sortable: true,
            initialWidth: 500
        },
        {
            label: 'Amount',
            fieldName: 'amount',
            type: 'text',
            sortable: true,
            initialWidth: 100
        },
        {
            label: 'Balance',
            fieldName: 'balance',
            type: 'text',
            sortable: true,
            initialWidth: 150
        },
        {
            label: 'Category (Auto)',
            fieldName: 'category',
            type: 'text',
            sortable: true,
            initialWidth: 200
        },
        {
            label: 'Perfios Category',
            fieldName: 'perfiosCategory',
            type: 'text',
            sortable: true,
            initialWidth: 200
        },
        {
            label: 'Txn Category (Manual)',
            fieldName: 'manualTxnCategory',
            type: 'text',
            sortable: true,
            initialWidth: 200
        }
    ];

    @track xnsBounceColumns = [{
            label: 'Sl. No.',
            fieldName: 'slNo',
            initialWidth: 100
        }, /* sortable: true, */
        {
            label: 'Bank Name',
            fieldName: 'bankName',
            type: 'text',
            sortable: true,
            initialWidth: 200
        },
        {
            label: 'Account No.',
            fieldName: 'accountNo',
            type: 'text',
            sortable: true,
            initialWidth: 200
        },
        {
            label: 'Date',
            fieldName: 'dateOf',
            type: 'text',
            sortable: true,
            initialWidth: 100
        },
        {
            label: 'Cheque No.',
            fieldName: 'chequeNo',
            type: 'text',
            sortable: true,
            initialWidth: 100
        },
        {
            label: 'Description',
            fieldName: 'description',
            type: 'text',
            sortable: true,
            initialWidth: 500
        },
        {
            label: 'Amount',
            fieldName: 'amount',
            type: 'text',
            sortable: true,
            initialWidth: 100
        },
        {
            label: 'Balance',
            fieldName: 'balance',
            type: 'text',
            sortable: true,
            initialWidth: 150
        },
        {
            label: 'Category (Auto)',
            fieldName: 'category',
            type: 'text',
            sortable: true,
            initialWidth: 200
        },
        {
            label: 'Perfios Category',
            fieldName: 'perfiosCategory',
            type: 'text',
            sortable: true,
            initialWidth: 200
        }
    ];

    @track xnsData = [];
    @track xnsDataRecs = [];
    @track xnsBounceData = [];



    @track data = [{
            tic: 'Total No. of Self & Related Party Credit Transactions',
            sep23: '0',
            oct23: '0',
            nov23: '0',
            Dec23: '0',
            jan24: '1',
            feb24: '0',
            mar24: '1',
            apr24: '2',
            may24: '2'
        },
        {
            tic: 'Total Amount of Self & Related Party Credit Transactions Total No of Business Credits',
            sep23: '0',
            oct23: '0',
            nov23: '0',
            Dec23: '0',
            jan24: '1',
            feb24: '0',
            mar24: '1',
            apr24: '2',
            may24: '2'
        },
        {
            tic: 'Total Amount of Business Credits',
            sep23: '34324324.00',
            oct23: '232323.00',
            nov23: '3432434.00',
            Dec23: '6832434.00',
            jan24: '7632434.00',
            feb24: '5452434.00',
            mar24: '6632434.00',
            apr24: '8732434.00',
            may24: '8932434.00'
        },
        {
            tic: 'Total No. of Self & Related Party Debit Transactions',
            sep23: '0',
            oct23: '0',
            nov23: '0',
            Dec23: '0',
            jan24: '1',
            feb24: '0',
            mar24: '1',
            apr24: '2',
            may24: '2'
        },
        {
            tic: 'Total Amount of Self & Related Party Debit Transactions',
            sep23: '0',
            oct23: '0',
            nov23: '0',
            Dec23: '0',
            jan24: '1',
            feb24: '0',
            mar24: '1',
            apr24: '2',
            may24: '2'
        },
        {
            tic: 'Total No of Business Debits',
            sep23: '15',
            oct23: '33',
            nov23: '6',
            Dec23: '76',
            jan24: '47',
            feb24: '88',
            mar24: '1',
            apr24: '88',
            may24: '90'
        },
        {
            tic: 'Total Amount of Business Debits',
            sep23: '765869.00',
            oct23: '1005869.00',
            nov23: '995869.00',
            Dec23: '935869.00',
            jan24: '655869.00',
            feb24: '245869.00',
            mar24: '545869.00',
            apr24: '445869.00',
            may24: '2765869.00'
        },
        {
            tic: 'Cash Deposit to Total Credit',
            sep23: '0',
            oct23: '0',
            nov23: '0',
            Dec23: '0',
            jan24: '1',
            feb24: '0',
            mar24: '1',
            apr24: '2',
            may24: '2'
        }

    ];

    @track originalData = [];
    @track accountNumberOptions = [];
    @track monthOptions = [];
    @track sortedBy;
    @track sortedDirection = 'asc';
    @track showXNSBounce = false;
    hideButton = false;
    userProfile = '';

    @wire(getRecord, { recordId: USER_ID, fields: [ProfileName] })
    userDetails({ error, data }) {
        if(data) {
            this.userProfile = data.fields.Profile.value.fields.Name.value;
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: [STAGENAME_FIELD,OWNERID_FIELD] })
    opportunity({ error, data }) {
        if(data) {
            var StageName = data.fields.StageName.value;
            var OwnerId = data.fields.OwnerId.value;

            if(StageName === 'Credit Underwriting'){
                console.log('this.userProfile: '+this.userProfile);
                if(this.userProfile != 'System Administrator' && OwnerId != USER_ID){
                    this.hideButton = true;
                }
            }
        }
    }

    connectedCallback() {
        this.getAccountNumberOptions();
        this.getBankOptions();
        this.getCategoryOptions();
        this.getMonthYearOptions();
        //console.log('selectedbanks ',this.selectedBanks);
        //console.log('loanId ',this.recordId);
        if (this.selectedBanks.length > 0) {

            this.getAllXnsRecords();
            this.getAllXnsRecordsFil();
            this.getDACurrentRecords();
            this.getSavingsDARecords();
            this.getCurrentDARecords();
            this.getOverdraftDARecords();
            this.getSBDARecords();
            this.getDACCODRecords();
            // this.getAllXnsBounceRecords();
            this.getAllCurrentBounceRecords();
            this.getAllSavingsBounceRecords();
            this.getAllCCODBounceRecords();
        } else {
            this.getAllXnsRecords();
            this.getAllXnsRecordsFil();
            this.getDACurrentRecords();
            this.getSavingsDARecords();
            this.getCurrentDARecords();
            this.getOverdraftDARecords();
            this.getSBDARecords();
            this.getDACCODRecords();
            // this.getAllXnsBounceRecords();
            this.getAllCurrentBounceRecords();
            this.getAllSavingsBounceRecords();
            this.getAllCCODBounceRecords();

            //this.getEligibleBanks();
            console.log('else  ', this.recordId);
        }

    }

    handleRefeshClick(event) {
        this.getAccountNumberOptions();
        this.getBankOptions();
        this.getCategoryOptions();
        this.getMonthYearOptions();
        if (this.selectedBanks.length > 0) {
            this.getAllXnsRecords();
            this.getAllXnsRecordsFil();
            this.getDACurrentRecords();
            this.getSavingsDARecords();
            this.getCurrentDARecords();
            this.getOverdraftDARecords();
            this.getSBDARecords();
            this.getDACCODRecords();
            this.getAllCurrentBounceRecords();
            this.getAllSavingsBounceRecords();
            this.getAllCCODBounceRecords();
        } else {
            this.getAllXnsRecords();
            this.getAllXnsRecordsFil();
            this.getDACurrentRecords();
            this.getSavingsDARecords();
            this.getCurrentDARecords();
            this.getOverdraftDARecords();
            this.getSBDARecords();
            this.getDACCODRecords();
            this.getAllCurrentBounceRecords();
            this.getAllSavingsBounceRecords();
            this.getAllCCODBounceRecords();
            console.log('else  ', this.recordId);
        }
    }


    getMonthYearOptions() {
        try {
            var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            var today = new Date();
            var d;
            var month;
            var year;

            for (var i = 6; i > 0; i -= 1) {
                d = new Date(today.getFullYear(), today.getMonth() - i, 1);
                month = monthNames[d.getMonth()];
                year = d.getFullYear();
                console.log(month);
                console.log(year);
                var ye = year.toString().substr(-2);
                this.monthOptions = [
                    ...this.monthOptions,
                    {
                        label: month.toString() + '-' + ye,
                        value: month.toString() + '-' + ye,
                    },
                ];

            }
        } catch (e) {
            console.log('month error ', e.message);
        }
    }

    @track sortBy;
    @track sortDirection;

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.data));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.data = parseData;
    }
    renderedCallback() {
        if (!this.isRendered) {
            // Create and append styles dynamically
            const style = document.createElement("style");
            style.innerText = `
            .bsa-page .slds-accordion__summary {
                padding: 10px 0px 10px 0px;
            }
            .bsa-page .slds-accordion__list-item {
                background-color: #0e1c30 !important;
                margin-bottom: 10px;
                border-radius: 10px;
                overflow: hidden;
                border: 1px solid #33455e;
            }
            .bsa-page .slds-accordion {
                background-color: #0a1524;
            }
            .bsa-page .slds-accordion__summary-action {
                background: linear-gradient(135deg, #001a5e 0%, #003087 55%, #004db3 100%) !important;
                border-radius: 10px !important;
                padding: 14px 16px !important;
                margin: 0px;
                font-weight: 500;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.35);
            }
            .bsa-page .slds-accordion__summary-action,
            .bsa-page .slds-accordion__summary-action * {
                color: #ffffff !important;
            }
            .bsa-page .slds-accordion__summary-action-icon,
            .bsa-page .slds-accordion__summary-action-icon svg {
                fill: #ffffff !important;
                color: #ffffff !important;
            }
            .bsa-page .slds-accordion__section {
                background-color: #0e1c30 !important;
                border-color: #33455e !important;
                color: #ffffff !important;
            }
            .bsa-datatable thead tr,
            .bsa-datatable thead th,
            .bsa-datatable .slds-line-height_reset .slds-cell-fixed .slds-th__action,
            .bsa-datatable .slds-th__action.slds-th__action_form.slds-cell-fixed,
            .bsa-datatable .slds-th__action {
                background: #0e1c30 !important;
                background-color: #0e1c30 !important;
                color: #ffffff !important;
                border-color: #33455e !important;
            }
            .bsa-datatable thead .slds-icon_container svg,
            .bsa-datatable thead svg {
                fill: #ffffff !important;
            }
            .bsa-datatable tbody{
                font-weight: 400;
            }
            .bsa-datatable .slds-table,
            .bsa-datatable td,
            .bsa-datatable th {
                background-color: #0e1c30 !important;
                color: #ffffff !important;
                border-color: #33455e !important;
            }
            /* lightning-datatable draws its row/column divider lines with
               box-shadow rather than a plain border, so border-color alone
               (above) doesn't repaint them - reset that box-shadow to the
               theme border color directly on every cell. */
            .bsa-datatable table.slds-table tbody tr td,
            .bsa-datatable table.slds-table tbody tr th,
            .bsa-datatable table.slds-table thead tr th {
                box-shadow: inset 0 -1px 0 0 #33455e !important;
            }
            .bsa-datatable table.slds-table_col-bordered tbody tr td,
            .bsa-datatable table.slds-table_col-bordered tbody tr th,
            .bsa-datatable table.slds-table_col-bordered thead tr th {
                box-shadow: inset 1px 0 0 0 #33455e, inset 0 -1px 0 0 #33455e !important;
            }
            .main-tab .slds-tabs_default__nav {
                background: #0e1c30;
                border-bottom: 1px solid #33455e;
            }
            .main-tab .slds-tabs_default__link {
                color: rgba(255, 255, 255, 0.7) !important;
            }
            .main-tab .slds-tabs_default__item.slds-is-active .slds-tabs_default__link {
                color: #ffffff !important;
                border-bottom-color: #1467eb !important;
            }
            .main-tab .slds-tabs_default__content {
                background: #0a1524;
                color: #ffffff;
            }
            .inputNumber .slds-input{
                text-align: right;
            }
            .seacrpills .slds-m-top_x-small.slds-grid{
                display: none;
            }
            .seacrpills .slds-dropdown{
                font-size: 10px;
            }
        `;

            // Append the styles to the .styleContainer
            this.template.querySelector(".styleContainer")?.appendChild(style);


            // Prevent re-adding styles
            this.isRendered = true;
        }
    }
    getSelectedRecords(event) {
        //console.log('getSelectedRecords');
        const selectedRows = event.detail.selectedRows;

        if (selectedRows.length > 0) {
            this.selectedRecords = [];
            for (let i = 0; i < selectedRows.length; i++) {


                this.selectedRecords.push(selectedRows[i].xnsRecId);
            }

        } else {
            this.selectedRecords = [];
        }

        console.log('Total Selected Records: ' + JSON.stringify(this.selectedRecords));
        if (this.selectedRecords.length > 0) {
            this.updateCategoryButton = true;
        } else {
            this.updateCategoryButton = false;
        }
    }
    handleRowActions() {
        console.log('handleRowActions');
    }
    handleChangeCategoryClick() {
        this.isShowModal = true;
    }
    @track categoryValue;
    handleCategoryChange(event) {
        this.categoryValue = event.target.value;
    }
    hideModalBox() {
        this.isShowModal = false;
    }
    saveRows() {
        console.log('this.categoryValue ' + this.categoryValue);
        if (!this.categoryValue) {
            this.showToastMessage('Error', 'Please select category.', 'error');
            return;
        }
        this.updateBulkRec();
        /*
        try{
            let temp = [];

        for ( let i = 0; i < this.xnsData.length; i++ ){       
            
            for ( let j = 0; j < this.selectedRecords.length; j++ ){    
                if(this.xnsData[i].slNo == this.selectedRecords[j]) {
                    this.xnsData[i].manualTxnCategory = this.categoryValue;
                    
                }
            }
            temp.push(this.xnsData[i]);
           }
           this.xnsData = temp;
           this.showToastMessage('Success', 'Record(s) updated successfully.', 'success');
           console.log('this.xnsData '+JSON.stringify(this.xnsData));
           this.hideModalBox();
        }catch(e){
            console.log('error '+e.message);
        }*/


    }
    showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(toastEvent);
    }
    handleExpandAllClick() {
        this.showOpenAll = false;
        this.mainAccordianActiveSactions = ['Consolidated Derived Analysis', 'XNS Consolidated', 'Current Account', 'CC/Overdraft', 'Savings Account'];
        this.consolidatedAccordianActiveSactions = ['CA Consolidated', 'CC/OD Derived Analysis (Account level)', 'SB Consolidated'];
    }
    handleCloseAllClick() {
        this.showOpenAll = true;
        this.mainAccordianActiveSactions = [];
        this.consolidatedAccordianActiveSactions = [];
    }

    @track searchBankName = [];
    @track searchAccNo = [];
    @track searchLoanAmount;
    @track searchDes;
    @track category = [];
    @track daRecPresent = false;
    @track daCCODRecPresent = false;
    @track daSBRecordsPresent = false;
    @track xnsCurrentBounceData = [];
    @track xnsSavingBounceData = [];
    @track xnsCCODBounceData = [];
    searchBank(event) {
        this.searchBankName = event.target.value;
        if (this.searchBankName.length >= 3) {
            this.getAllXnsRecordsFil();
        } else {
            this.searchBankName = null;
            this.getAllXnsRecordsFil();
        }

    }
    searchAccountNo(event) {
        this.searchAccNo = event.target.value;
        if (this.searchAccNo.length >= 3) {
            this.getAllXnsRecordsFil();
        } else {
            this.searchAccNo = null;
            this.getAllXnsRecordsFil();
        }
    }
    searchLoanAmt(event) {
        this.searchLoanAmount = event.target.value;
        if (this.searchLoanAmount.length >= 3) {
            this.getAllXnsRecordsFil();
        } else {
            this.searchLoanAmount = null;
            this.getAllXnsRecordsFil();
        }
    }
    searchdescription(event) {
        this.searchDes = event.target.value;
        if (this.searchDes.length >= 3) {
            this.getAllXnsRecordsFil();
        } else {
            this.searchDes = null;
            this.getAllXnsRecordsFil();
        }
    }

    searchCategory(event) {
        this.category = event.target.value;
        if (this.category.length >= 3) {
            this.getAllXnsRecordsFil();
        } else {
            this.category = null;
            this.getAllXnsRecordsFil();
        }

    }
    searchInLst() {
        try {
            let temp = [];
            for (let i = 0; i < this.originalData.length; i++) {
                var isPresent = false;
                if (this.searchDes) {
                    if (this.originalData[i].description.toLowerCase().includes(this.searchDes.toLowerCase())) {
                        //temp.push(this.originalData[i]);
                        isPresent = true;
                    } else {
                        isPresent = false;
                        continue;
                    }
                }
                if (this.searchAccNo) {
                    if (this.originalData[i].accountNo.toLowerCase().includes(this.searchAccNo.toLowerCase())) {
                        //temp.push(this.originalData[i]);
                        isPresent = true;
                    } else {
                        isPresent = false;
                        continue;
                    }
                }
                if (this.searchLoanAmount) {
                    if (this.originalData[i].amount.toLowerCase().includes(this.searchLoanAmount.toLowerCase())) {
                        //temp.push(this.originalData[i]);
                        isPresent = true;
                    } else {
                        isPresent = false;
                        continue;
                    }
                }
                if (this.searchBankName) {
                    if (this.originalData[i].bankName.toLowerCase().includes(this.searchBankName.toLowerCase())) {
                        //temp.push(this.originalData[i]);
                        isPresent = true;
                    } else {
                        isPresent = false;
                        continue;
                    }
                }
                if (isPresent) {
                    temp.push(this.originalData[i]);
                }

            }
            this.xnsData = temp;
            if (!this.searchDes && !this.searchBankName && !this.searchAccNo && !this.searchLoanAmount) {
                this.xnsData = this.originalData;
            }
        } catch (e) {
            console.log('errpr ', e.message);
        }


    }
    getAllXnsRecords() {
        this.spinner = true;
        getAllBankXnsRecords({
                recordIds: this.selectedBanks,
                recordId: this.recordId
            })
            .then((response) => {
                console.log("response customer details all=:" + JSON.stringify(response));
                this.originalData = response;
                this.xnsDataRecs = response;

                this.spinner = false;
            })
            .catch((error) => {});
    }

    downloadExcel() {
        // const data = this.xnsData;
        const data = this.xnsDataRecs;
        if (!data || data.length === 0) {
            console.warn('No data to export');
            return;
        }

        const headers = [{
                label: 'Sl No.',
                field: 'slNo'
            },
            {
                label: 'Bank Name',
                field: 'bankName'
            },
            {
                label: 'Account No.',
                field: 'accountNo'
            },
            {
                label: 'Date',
                field: 'dateOf'
            },
            {
                label: 'Cheque No.',
                field: 'chequeNo'
            },
            {
                label: 'Description',
                field: 'description'
            },
            {
                label: 'Amount',
                field: 'amount'
            },
            {
                label: 'Balance',
                field: 'balance'
            },
            {
                label: 'Category (Auto)',
                field: 'category'
            }
            // { label: 'Record ID', field: 'xnsRecId' }
        ];

        let csvContent = headers.map(h => h.label).join(',') + '\n';

        data.forEach(row => {
            csvContent += headers
                .map(h => `"${(row[h.field] || '').toString().replace(/"/g, '""')}"`)
                .join(',') + '\n';
        });

        try {
            const blob = new Blob(["\uFEFF" + csvContent], {
                type: 'application/octet-stream'
            });
            const url = URL.createObjectURL(blob);

            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', 'xns_data.csv');
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(url);
        } catch (error) {
            console.error('Download error:', error);
        }
    }



    getAllXnsRecordsFil() {
        this.spinner = true;
        getAllBankXnsRecordsFiltered({
                recordId: this.recordId,
                searchBankName: this.searchBankName,
                searchAccNo: this.searchAccNo,
                searchLoanAmount: this.searchLoanAmount,
                searchDes: this.searchDes,
                category: this.category

            })
            .then((response) => {
                console.log("xns data" + JSON.stringify(response));
                console.log("xns data length " + JSON.stringify(response.length));
                this.originalData = response;
                this.xnsData = response;
                if(response.length > 0) {
                    this.hasxnsData = true;
                } else {
                    this.hasxnsData = false;
                }
                this.spinner = false;
            })
            .catch((error) => {
                console.error('error : getAllXnsRecords :', JSON.stringify(error));
                this.spinner = false;
            });
    }

    @track showCurrentXNSBounce = false;
    getAllCurrentBounceRecords() {
        this.spinner = true;
        getAllBankXnsBounceRecords({
                recordIds: this.selectedBanks,
                recordId: this.recordId,
                accType: 'Current'
            })
            .then((response) => {
                console.log("response Current XNS=:" + JSON.stringify(response));
                //this.originalData = response;
                this.xnsCurrentBounceData = response;
                if (this.xnsCurrentBounceData.length > 0) {
                    this.showCurrentXNSBounce = true;
                } else {
                    this.showCurrentXNSBounce = false;
                }

                this.spinner = false;
            })
            .catch((error) => {});
    }

    @track showSavingXNSBounce = false;
    getAllSavingsBounceRecords() {
        this.spinner = true;
        getAllBankXnsBounceRecords({
                recordIds: this.selectedBanks,
                recordId: this.recordId,
                accType: 'Saving'
            })
            .then((response) => {
                console.log("response saving XNS=:" + JSON.stringify(response));
                //this.originalData = response;
                this.xnsSavingBounceData = response;
                if (this.xnsSavingBounceData.length > 0) {
                    this.showSavingXNSBounce = true;
                } else {
                    this.showSavingXNSBounce = false;
                }

                this.spinner = false;
            })
            .catch((error) => {});
    }
    @track showCCODXNSBounce = false;
    getAllCCODBounceRecords() {
        this.spinner = true;
        getAllBankXnsBounceRecords({
                recordIds: this.selectedBanks,
                recordId: this.recordId,
                accType: 'CCOD'
            })
            .then((response) => {
                console.log("response CC/OD XNS=:" + JSON.stringify(response));
                //this.originalData = response;
                this.xnsCCODBounceData = response;
                if (this.xnsCCODBounceData.length > 0) {
                    this.showCCODXNSBounce = true;
                } else {
                    this.showCCODXNSBounce = false;
                }

                this.spinner = false;
            })
            .catch((error) => {});
    }


    updateBulkRec() {
        this.spinner = true;
        updateCategory({
                recordIds: this.selectedRecords,
                categoryMan: this.categoryValue
            })
            .then((response) => {
                console.log("response customer details=:" + JSON.stringify(response));
                if (response == 'success') {
                    this.showToastMessage('Success', 'Data updated successfully!', 'success');


                    //this.getAllXnsRecords(); 
                    this.getAllXnsRecordsFil();
                    this.getDACurrentRecords();
                    this.getSavingsDARecords();
                    this.getCurrentDARecords();
                    this.getOverdraftDARecords();
                    this.getSBDARecords();
                    this.getDACCODRecords();
                    //this.getAllXnsBounceRecords();
                }


                this.spinner = false;
                this.hideModalBox();
            })
            .catch((error) => {});
    }

    getDACurrentRecords() {
        this.spinner = true;
        getDerivedAnalysisRecords({
                recordIds: this.selectedBanks,
                recordId: this.recordId,
                accountType: 'Current'
            })
            .then((response) => {
                console.log("Current DA" + JSON.stringify(response));
                this.daRecords = response;
                if (this.daRecords && Object.keys(this.daRecords).length > 0) {
                    console.log('daRecords present');
                    this.daRecPresent = true;
                } else {
                    console.log('daRecords not present');
                    this.daRecPresent = false;
                }

                this.spinner = false;
            })
            .catch((error) => {});
    }

    getSBDARecords() {
        this.spinner = true;
        getDerivedAnalysisRecords({
                recordIds: this.selectedBanks,
                recordId: this.recordId,
                accountType: 'Saving'
            })
            .then((response) => {
                console.log("Saving DA" + JSON.stringify(response));
                this.daSBRecords = response;
                if (this.daSBRecords && Object.keys(this.daSBRecords).length > 0) {
                    this.daSBRecordsPresent = true;
                } else {
                    this.daSBRecordsPresent = false;
                }
                this.spinner = false;
            })
            .catch((error) => {});
    }
    getDACCODRecords() {
        this.spinner = true;
        getDerivedAnalysisRecords({
                recordIds: this.selectedBanks,
                recordId: this.recordId,
                accountType: 'Overdraft'
            })
            .then((response) => {
                console.log("Overdraft DA" + JSON.stringify(response));
                this.daCCODRecords = response;
                if (this.daCCODRecords && Object.keys(this.daCCODRecords).length > 0) {
                    this.daCCODRecPresent = true;
                } else {
                    this.daCCODRecPresent = false;
                }

                this.spinner = false;
            })
            .catch((error) => {});
    }

    //
    getSavingsDARecords() {
        this.spinner = true;
        getDerivedAnalysisRecordsAccWise({
                recordIds: this.selectedBanks,
                recordId: this.recordId,
                accountType: 'Saving'
            })
            .then((response) => {
                //console.log("daSavingsRecords =:" + JSON.stringify(response));
                this.daSavingsRecords = response;

                this.spinner = false;
            })
            .catch((error) => {});
    }

    getCurrentDARecords() {
        this.spinner = true;
        getDerivedAnalysisRecordsAccWise({
                recordIds: this.selectedBanks,
                recordId: this.recordId,
                accountType: 'Current'
            })
            .then((response) => {
                // console.log("daCurrentRecords =:" + JSON.stringify(response));
                this.daCurrentRecords = response;

                this.spinner = false;
            })
            .catch((error) => {});
    }
    getOverdraftDARecords() {
        this.spinner = true;
        getDerivedAnalysisRecordsAccWise({
                recordIds: this.selectedBanks,
                recordId: this.recordId,
                accountType: 'Overdraft'
            })
            .then((response) => {
                console.log("Overdraft =:" + JSON.stringify(response));
                this.daOverdraftRecords = response;
                this.daOverdraftRecords = [...this.daOverdraftRecords];
                this.spinner = false;
            })
            .catch((error) => {});
    }

    getEligibleBanks() {
        this.spinner = true;
        getEligibleBankIds({
                recordId: this.recordId
            })
            .then((response) => {

                if (response.length > 0) {
                    this.selectedBanks = response;
                    this.getAllXnsRecordsFil();
                    //this.getAllXnsRecords(); 
                    this.getDACurrentRecords();
                    this.getSavingsDARecords();
                    this.getCurrentDARecords();
                    this.getOverdraftDARecords();
                    this.getSBDARecords();
                    this.getAllXnsBounceRecords();
                } else {
                    this.showToastMessage('Error', 'No eligible banks found', 'error');
                }



                this.spinner = false;
            })
            .catch((error) => {});
    }

    // handleFieldChange(event) {
    //     console.log('on blur name',event.target.name);
    //     console.log('event.target.value=:'+event.target.value);
    //     console.log('data id=:'+event.target.dataset.id);
    //     const fields = {};
    //     fields['Id'] = event.target.dataset.id;
    //     fields[event.target.name]=event.target.value;
    //     const recordInput = { fields };
    //     console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
    //     updateRecord(recordInput)
    //     .then(() => {
    //         this.showToastMessage('Success', 'Record updated successfully', 'success');
    //         this.getData();
    //     })
    //     .catch(error => {
    //         console.log('Error updating record --> '+JSON.stringify(error));
    //     });
    // }

    // Modified by Anish for Santion Limitation
 handleFieldChange(event) {
        console.log('on blur name:', event.target.name);
        console.log('event.target.value=:', event.target.value);
        console.log('data id=:', event.target.dataset.id);
        let isValid = true;
        if (event.target.name === 'Sanction_Limit__c') {
            let inputValue = event.target.value;
            inputValue = inputValue.replace(/[^0-9.]/g, '');
            if (inputValue.length > 9) {
                isValid = false;
            }
            let numericValue = parseFloat(inputValue);
            if (isNaN(numericValue) || numericValue > 1000000000) {
                isValid = false;
            }
            if (!isValid) {
                this.showToastMessage('Error', 'Invalid input! Enter up to 9 digits and max 100 Cr.', 'error');
                //event.target.value = 0; 
                return;
            }
            event.target.value = numericValue;
        }

        const fields = {};
        console.log('event.target.name', event.target.name);
        fields['Id'] = event.target.dataset.id;
        fields[event.target.name] = event.target.value;

        const recordInput = {
            fields
        };

        let bsdaId = event.target.dataset.id;
        console.log('bsdaId', bsdaId);
        updateRecord(recordInput)
            .then(() => {

                this.spinner = true;
                calculateUtilization({
                        bsaDaId: bsdaId
                    })
                    .then((response) => {
                        console.log("calculateUtilization =:" + JSON.stringify(response));
                        this.getOverdraftDARecords();
                        this.getDACCODRecords();

                        this.showToastMessage('Success', 'Record updated successfully', 'success');
                        this.spinner = false;
                        //
                    })
                    .catch((error) => {

                        this.spinner = false;
                    });


            })
            .catch(error => {
                console.log('Error updating record --> ' + JSON.stringify(error));
            });
    }

    handleSort(event) {
        const {
            fieldName: sortedBy
        } = event.detail;
        this.sortedDirection = this.sortedBy === sortedBy && this.sortedDirection === 'asc' ? 'desc' : 'asc';
        this.sortedBy = sortedBy;

        let sortedData = [...this.xnsBounceData];

        sortedData.sort((a, b) => {
            let valueA = a[sortedBy] ? a[sortedBy].toString().toLowerCase() : '';
            let valueB = b[sortedBy] ? b[sortedBy].toString().toLowerCase() : '';
            if (!isNaN(parseFloat(valueA)) && !isNaN(parseFloat(valueB))) {
                valueA = parseFloat(valueA);
                valueB = parseFloat(valueB);
            }
            let comparison = valueA > valueB ? 1 : valueA < valueB ? -1 : 0;
            return this.sortedDirection === 'asc' ? comparison : -comparison;
        });

        this.xnsBounceData = sortedData;
    }
    @api
    refreshCmp() {
        this.getAllXnsRecords();
        this.getAllXnsRecordsFil();
        this.getDACurrentRecords();
        this.getSavingsDARecords();
        this.getCurrentDARecords();
        this.getOverdraftDARecords();
        this.getSBDARecords();
        this.getDACCODRecords();
        //this.getAllXnsBounceRecords();
    }

    async callRefresh() {
        this.getAllXnsRecords();
        this.getAllXnsRecordsFil();
        this.getDACurrentRecords();
        this.getSavingsDARecords();
        this.getCurrentDARecords();
        this.getOverdraftDARecords();
        this.getSBDARecords();
        this.getDACCODRecords();
        // this.getAllXnsBounceRecords();
        this.getAllCurrentBounceRecords();
        this.getAllSavingsBounceRecords();
        this.getAllCCODBounceRecords();
    }

    getBankOptions() {
        getAllRelatedBanks({
            loanId: this.recordId
            })
            .then((response) => {
                this.bankOptions = response.map(item => ({
                    label: item,
                    value: item
                }));
               
            })
            .catch((error) => {

                this.spinner = false;
            });

    }

    getCategoryOptions() {
        getAllCategories({
            loanId: this.recordId
            })
            .then((response) => {
                this.categoryOptions = response.map(item => ({
                    label: item,
                    value: item
                }));
               
            })
            .catch((error) => {

                this.spinner = false;
            });

    }
    getAccountNumberOptions() {
        getAllRelatedBanksAccountNumber({
            loanId: this.recordId
            })
            .then((response) => {
                this.accountNumberOptions = response.map(item => ({
                    label: item,
                    value: item
                }));
               
            })
            .catch((error) => {

                this.spinner = false;
            });

    }
    

    //

    handleMultiPicklistSelection(event) {
        let tempSelectedValues = [];
        let picklistOptions;
        let selectedList = event.detail.selectedList;

        if (selectedList.length > 0) {
            this.searchBankName = selectedList;
            this.getAllXnsRecordsFil();
        }else{
            this.searchBankName = null;
            this.getAllXnsRecordsFil();
        }
        console.log(selectedList);
    }
    handleMultiPicklistSelectionCategory(event) {
        let tempSelectedValues = [];
        let picklistOptions;
        let selectedList = event.detail.selectedList;

        if (selectedList.length > 0) {
            this.category = selectedList;

        this.getAllXnsRecordsFil();
        } else {
            this.category = null;
            this.getAllXnsRecordsFil();
        }
        console.log(selectedList);
    }

    handleMultiPicklistSelectionAccount(event){
        let tempSelectedValues = [];
        let picklistOptions;
        let selectedList = event.detail.selectedList;

        if (selectedList.length > 0) {
            this.searchAccNo = selectedList;

        this.getAllXnsRecordsFil();
        } else {
            this.searchAccNo = null;
            this.getAllXnsRecordsFil();
        }
        console.log(selectedList);
    }
}