import { LightningElement, api, track, wire } from 'lwc';
import { createRecord, updateRecord } from "lightning/uiRecordApi";
import INCOME_ASSESSMENT_OBJECT from '@salesforce/schema/Income_Assessment__c';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import NATUREOFCOMPONENT from '@salesforce/schema/Income_Assessment__c.Nature_Of_Component__c';
import TYPEOFCOMPONENT from '@salesforce/schema/Income_Assessment__c.Type_Of_Component__c';
// import getParticularsList from '@salesforce/apex/HL_SalariedScreenController.getParticularsList';
import deleteYearlyComponent from '@salesforce/apex/HL_SalariedScreenController.deleteYearlyComponent';
import getAllYearlyComponent from '@salesforce/apex/HL_SalariedScreenController.getAllYearlyComponent';
import getAllIncentiveDetails from '@salesforce/apex/HL_SalariedScreenController.getAllIncentiveDetails';
import getSalaryDetails from '@salesforce/apex/HL_SalariedScreenController.getSalaryDetails';
import upsertMonthlyValue from '@salesforce/apex/HL_SalariedScreenController.upsertMonthlyValue';
import deleteParticular from '@salesforce/apex/HL_SalariedScreenController.deleteParticular';
import deleteMonthlyValues from '@salesforce/apex/HL_SalariedScreenController.deleteMonthlyValues';
import saveTotalGross from '@salesforce/apex/HL_SalariedScreenController.saveTotalGross';
import saveNetSalary from '@salesforce/apex/HL_SalariedScreenController.saveNetSalary';
import upsertRentalIncome from '@salesforce/apex/HL_SalariedScreenController.upsertRentalIncome';
import getRentalDetails from '@salesforce/apex/HL_SalariedScreenController.getRentalDetails';
import calculateNetIncome from '@salesforce/apex/HL_SalariedScreenController.calculateNetIncome';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class HL_salariedScreenCmp extends LightningElement {

    @api disableEdit = false;
    @api recordId;
    @api applicantId;
    @api parentId;

    @wire(getObjectInfo, { objectApiName: INCOME_ASSESSMENT_OBJECT})
    INCOME_ASSESSMENT_INFO;

    @track spinnerRun = false;
    @track objSalWrapper={};
    newMonthValue;
    @track newMonthWrapper = [];
    @track newMonthWrapperLess = [];
    boolAddNewMonth = false;
    
    // @track availableParticulars=[];
    @track deleteParticularId = '';

    @track showgenericConfirm = false;
    @track deleteIndex = 0;
    @track confirmMessage = 'Are you sure you want to delete this data?';
    positiveLabel = 'Yes';
    negativelabel = 'No';

    @track showgenericConfirmParticular = false;

    @track addOptions = [];
    @track lessOptions = [];
    @track showADDcmp = false;
    @track showLESScmp = false;
    @track refreshLESS = true;
    @track refreshADD = true;

    @track yearlyComponents = [];
    @track yearlyChildData = [];
    @track addedIndex = 0;

    @track incentiveComponents = [];
    @track incentiveChildData = [];
    @track incentiveAddedIndex = 1;

    @track totalAvgGross = 0;
    @track totalAvgGrossLess = 0;
    @track showADDgross = false;
    @track showLESSgross = false;
    @track natureOfCMPvalues = [];
    @track typeOfCMPvalues = [];
    @track netAvgSalary = 0;
    rentalIncome = 0;
    @track netIncome = 0;
    @track netIncomeMonthly = 0;
    rentalRecId = '';
    isUnsavedIncentRow = false;
    selectedAddRow;
    disableDeleteMonth = false;
    remarks = '';

    frequencyOptions = [
        { label: "BI Monthly", value: "BI Monthly" },
        { label: "Quarterly", value: "Quarterly" },
        { label: "Half Yearly", value: "Half Yearly" },
        { label: "Annually", value: "Annually" }
    ];

    deleteRowSection = ''

    newADDdataWrapper = {
        'Id': null,
        'Nature_Of_Component__c': '',
        'Type_Of_Component__c': ''
    };

    newLESSdataWrapper = {
        'Id': null,
        'Nature_Of_Component__c': '',
        'Type_Of_Component__c': ''
    }

    newEntry = {
        srNo: '',
        yearlyComponent: '',
        grossAmount: '0',
        multiplier: '',
        taxSlab: '',
        netAmount: '',
        frequency: '',
        id: '',
        addRecord: true,
        editRecord: true
    };

    incentiveNewEntry = {
        srNo: '',
        yearlyComponent: '',
        grossAmount: '0',
        multiplier: '',
        taxSlab: '',
        netAmount: '',
        frequency: '',
        id: '',
        addRecord: true,
        editRecord: true
    };

    @wire(getPicklistValues, { recordTypeId: '$INCOME_ASSESSMENT_INFO.data.defaultRecordTypeId', fieldApiName: NATUREOFCOMPONENT})
    natureOfCmp({ data, error }) {
        if (data){
            this.natureOfCMPvalues = data.values;
            //console.log('this.natureOfCMPvalues -->'+JSON.stringify(this.natureOfCMPvalues));
        }else{
            console.log('Nature of comp Error --> '+ error);
        } 
    } 
    
    @wire(getPicklistValues, { recordTypeId: '$INCOME_ASSESSMENT_INFO.data.defaultRecordTypeId', fieldApiName: TYPEOFCOMPONENT})
    typeOfCmp({ data, error }) {
        if (data){
            this.typeOfCMPvalues = data.values;
            //console.log('this.typeOfCMPvalues -->'+JSON.stringify(this.typeOfCMPvalues));
            this.filterPicklistValue();
        }else{
            console.log('Type of comp Error --> '+ error);
        } 
    }

    filterPicklistValue(){
        // getParticularsList({
        //     loanId : this.recordId,
        //     applicantId: this.applicantId,
        //     parentId: this.parentId
        // }).then(response=>{
        //     // console.log('response -->'+JSON.stringify(response));
            this.addOptions = this.typeOfCMPvalues
                .filter(item => item.validFor.includes(0))
                .map(item => ({ label: item.label, value: item.value }))
                // .filter(option => response.availableParticulars.includes(option.value));
            console.log('options--'+JSON.stringify(this.addOptions));
            if(this.addOptions.length > 0){
                this.showADDcmp = true;
            }else{
                this.showADDcmp = false;
            }

            this.lessOptions = this.typeOfCMPvalues
                .filter(item => item.validFor.includes(1))
                .map(item => ({ label: item.label, value: item.value }))
                // .filter(option => response.availableParticulars.includes(option.value));
            if(this.lessOptions.length > 0){
                this.showLESScmp = true;
            }else{
                this.showLESScmp = false;
            }
        //     // console.log('this.addOptions -->'+JSON.stringify(this.addOptions));
        //     // console.log('this.lessOptions -->'+JSON.stringify(this.lessOptions));
        // });
    }

    connectedCallback(){

        this.spinnerRun = true;
        this.getSalaryWrapper();
        this.getAllYearlyData(false);
        this.getAllIncentiveData();
        this.getRentalData();
        this.calculateNetIncome();
        // this.netIncome = ((this?.totalAvgGross - this?.totalAvgGrossLess) * 12) + this?.yearlyComponents?.netAmount + this?.incentiveComponents?.netAmount;
        console.log('this.netIncome',this.netIncome);
        console.log(this.totalAvgGross, 'less',this.totalAvgGrossLess, 'netamt', this.yearlyComponents.netAmount, 'incentivenetamt', this.incentiveComponents.netAmount );
    }

    calculateNetIncome(totalGross, totalGrossLess, bonusNetAmount, incentiveNetAmount){
        // const toNum = v => Number.isFinite(Number(v)) ? Number(v) : 0;
        // console.log('192 totalGross :'+totalGross+' totalGrossLess: '+totalGrossLess+' bonusNetAmount: '+bonusNetAmount+' incentiveNetAmount: '+incentiveNetAmount);
        // this.netIncome = ((toNum(totalGross) - toNum(totalGrossLess)) * 12) + toNum(bonusNetAmount) + toNum(incentiveNetAmount);
        // //this.netIncome = ((totalGross - totalGrossLess) * 12) + bonusNetAmount + incentiveNetAmount;
        // this.netIncomeMonthly = (toNum(totalGross) - toNum(totalGrossLess)) + toNum(bonusNetAmount) + toNum(incentiveNetAmount);
    }

    saveGROSSValue(){
        saveTotalGross({
            parentId : this.parentId,
            value : this.totalAvgGross
        }).then(response=>{

        }).catch(error=>{
            console.log('Error saveTotalGross -->'+JSON.stringify(error));
        });
    }

    saveNetSalary(){
        saveNetSalary({
            parentId : this.parentId,
            value : this.netAvgSalary
        }).then(response=>{
            this.calculateNetIncome();
        }).catch(error=>{
            console.log('Error saveTotalNet -->'+JSON.stringify(error));
        });
    }
    calculateNetIncome(){
        calculateNetIncome({
            loanId: this.recordId,
            appId: this.applicantId,
            parentId : this.parentId
        }).then(response=>{
            this.netIncomeMonthly = response;
            this.netIncome = response*12;
        }).catch(error=>{

        })
    }
    getSalaryWrapper() {
        console.log('this.parentId -->'+this.parentId);
        getSalaryDetails({parentId: this.parentId})
        .then(response => {
            console.log('getSalaryDetails -->'+JSON.stringify(response));
            this.objSalWrapper = response;
            this.disableDeleteMonth = this.objSalWrapper.intMonthsCount <= 1;
            this.remarks = response.remarks;

            var totalAvg = 0;
            if(this.objSalWrapper.lstTotalAmount != null && this.objSalWrapper.lstTotalAmount.length >0){
                this.objSalWrapper.lstTotalAmount.forEach(amount => {
                    totalAvg = totalAvg + amount;
                });
                this.totalAvgGross = (totalAvg / this.objSalWrapper.lstTotalAmount.length).toFixed(0);
                this.showADDgross = true;
            }else{
                this.showADDgross = false;
            }
            this.saveGROSSValue();

            totalAvg = 0;
            if(this.objSalWrapper.lstTotalAmountLess != null && this.objSalWrapper.lstTotalAmountLess.length >0){
                this.objSalWrapper.lstTotalAmountLess.forEach(amount => {
                    totalAvg = totalAvg + amount;
                });
                this.totalAvgGrossLess = (totalAvg / this.objSalWrapper.lstTotalAmountLess.length).toFixed(0);
                this.calculateNetIncome();//(this.totalAvgGross, this.totalAvgGrossLess, this.yearlyComponents.netAmount, this.incentiveComponents.netAmount);
                this.showLESSgross = true;
            }else{
                this.showLESSgross = false;
            }

            this.netAvgSalary = this.totalAvgGross - this.totalAvgGrossLess;
            this.saveNetSalary();

            this.spinnerRun = false;
        })
        .catch(error=>{
            this.spinnerRun = false;            
            console.log('getSalaryDetails -->',error);
            console.log('getSalaryDetails -->'+JSON.stringify(error));
        });
    }

    get showNetSalary(){
        return this.showLESSgross || this.showADDgross;
    }

    addnewinputChanged(event){
        this.newADDdataWrapper[event.target.dataset.id] = event.target.value;
    }

    lessnewinputChanged(event){
        this.newLESSdataWrapper[event.target.dataset.id] = event.target.value;
    }

    get boolIsMonthDataPresent() {
        if(!this.objSalWrapper || !this.objSalWrapper.intMonthsCount || this.objSalWrapper.intMonthsCount == 0) {
            return false;
        } else if(this.boolAddNewMonth) {
            return false;
        }
        return true;
    }

    get amtColSpan() {
        if(this.objSalWrapper.intMonthsColSpanCount) {
            return this.objSalWrapper.intMonthsColSpanCount;
        }
        return 1;
    }

    get earningsDeductionsColSpan() {
        if(this.amtColSpan) {
            return (this.amtColSpan + 4);
        }
        return 5;
    }

    addMonth(event) {
        this.boolAddNewMonth = true;
        this.newMonthValue = '';

        if(this.objSalWrapper.intMonthsCount) {
            this.objSalWrapper.intMonthsCount += 1;
        } else {
            this.objSalWrapper.intMonthsCount = 1;
        }
        if(this.objSalWrapper.intMonthsColSpanCount) {
            this.objSalWrapper.intMonthsColSpanCount += 1;
        } else {
            this.objSalWrapper.intMonthsColSpanCount = 1;
        }
        console.log('add this.objSalWrapper -->'+JSON.stringify(this.objSalWrapper));
    }

    resetMonth(event) {
        this.boolAddNewMonth = false;
        this.newMonthValue = '';

        if(this.objSalWrapper.intMonthsCount) {
            this.objSalWrapper.intMonthsCount -= 1;
        } else {
            this.objSalWrapper.intMonthsCount = 0;
        }
        if(this.objSalWrapper.intMonthsColSpanCount) {
            this.objSalWrapper.intMonthsColSpanCount -= 1;
        } else {
            this.objSalWrapper.intMonthsColSpanCount = 0;
        }
        console.log('del this.objSalWrapper -->'+JSON.stringify(this.objSalWrapper));
    }

    handleRemarksChange(event){
        this.remarks = event.target.value;

        const fields = {};
        fields['Id'] = this.parentId;
        fields['Remarks__c'] = event.target.value;
        const recordInput = { fields };
        updateRecord(recordInput)
        .then((response) => {
            console.log('updateremarks response: '+JSON.stringify(response));
        })
        .catch(error => {
            console.log('Error updateRecord -->'+ JSON.stringify(error));
        });
    }

    inputChanged(event) {
        if(event.target.name == 'newMonthLabel') {
            this.newMonthValue = event.target.value;
        }
        else if(event.target.name == 'newMonthValueAdd') {
            let monthLabel = event.currentTarget.dataset.month;
            let monthVal = event.target.value;
            let num = parseFloat(monthVal);
            if (!isNaN(num)) {
                monthVal = num.toFixed(2);
            } else {
                monthVal = '';
            }
            
            if(this.newMonthWrapper && this.newMonthWrapper.some(objMonth => objMonth.strMonthLabel == monthLabel)) {
                let intIndex = this.newMonthWrapper.findIndex(objMonth => objMonth.strMonthLabel == monthLabel);
                this.newMonthWrapper[intIndex].strMonthValue = monthVal;
            } 
            else {
                this.newMonthWrapper.push({'strMonthLabel' : monthLabel, 'strMonthValue' : monthVal});
            }
        }
        else if(event.target.name == 'addNatureOfValue') {
            this.objSalWrapper.lstEarningsWrapper = this.objSalWrapper.lstEarningsWrapper.map(row => {
                if (row.recordId === event.target.dataset.id) {
                    return { ...row, strNatureOfComponent: event.target.value };
                }
                return row;
            });
        }
        else if(event.target.name == 'addParticular') {
            this.objSalWrapper.lstEarningsWrapper = this.objSalWrapper.lstEarningsWrapper.map(row => {
                if (row.recordId === event.target.dataset.id) {
                    return { ...row, strParticulars: event.target.value };
                }
                return row;
            });
        }
        else if(event.target.name == 'addMonthValue') {
            const parentId = event.target.dataset.parentid

            this.objSalWrapper.lstEarningsWrapper = this.objSalWrapper.lstEarningsWrapper.map(row => {
                if (row.recordId === parentId) {

                    var monthWrp = row.lstAmtWrapper.map(month => {
                        if (month.recordId === event.target.dataset.id) {
                            return { ...month, strMonthValue: event.target.value };
                        }
                        return month;
                    });
                    console.log('add monthWrp: '+JSON.stringify(monthWrp));
                    
                    return { ...row, lstAmtWrapper: monthWrp };
                }
                return row;
            });
        }
        else if(event.target.name == 'newMonthValueless') {
            let monthLabel = event.currentTarget.dataset.month;
            let monthVal = event.target.value;
            let num = parseFloat(monthVal);
            if (!isNaN(num)) {
                monthVal = num.toFixed(2);
            } else {
                monthVal = '';
            }
            if(this.newMonthWrapperLess && this.newMonthWrapperLess.some(objMonth => objMonth.strMonthLabel == monthLabel)) {
                let intIndex = this.newMonthWrapperLess.findIndex(objMonth => objMonth.strMonthLabel == monthLabel);
                this.newMonthWrapperLess[intIndex].strMonthValue = monthVal;
            } else {
                this.newMonthWrapperLess.push({'strMonthLabel' : monthLabel, 'strMonthValue' : monthVal});
            }
        }
        else if(event.target.name == 'lessNatureOfValue') {
            this.objSalWrapper.lstDeductionsWrapper = this.objSalWrapper.lstDeductionsWrapper.map(row => {
                if (row.recordId === event.target.dataset.id) {
                    return { ...row, strNatureOfComponent: event.target.value };
                }
                return row;
            });
        }
        else if(event.target.name == 'lessParticular') {
            this.objSalWrapper.lstDeductionsWrapper = this.objSalWrapper.lstDeductionsWrapper.map(row => {
                if (row.recordId === event.target.dataset.id) {
                    return { ...row, strParticulars: event.target.value };
                }
                return row;
            });
        }
        else if(event.target.name == 'lessMonthValue') {
            const parentId = event.target.dataset.parentid

            this.objSalWrapper.lstDeductionsWrapper = this.objSalWrapper.lstDeductionsWrapper.map(row => {
                if (row.recordId === parentId) {

                    var monthWrp = row.lstAmtWrapper.map(month => {
                        if (month.recordId === event.target.dataset.id) {
                            return { ...month, strMonthValue: event.target.value };
                        }
                        return month;
                    });
                    console.log('less monthWrp: '+JSON.stringify(monthWrp));
                    
                    return { ...row, lstAmtWrapper: monthWrp };
                }
                return row;
            });
        }
    }

    saveNewMonth(event) {
        if(!this.newMonthValue){
            this.showToast('Error', 'Please enter month name.', 'error');
            return;
        }

        if(this.objSalWrapper.lstMonthLabels){
            var count = this.objSalWrapper.lstMonthLabels.filter(month => month == this.newMonthValue).length;
            if(count > 0){
                this.showToast('Error', 'Duplicate month value found.', 'error');
                return;
            }
        }
        else{
            this.objSalWrapper.lstMonthLabels = [];
        }
        
        this.objSalWrapper.lstMonthLabels.push(this.newMonthValue);
        this.objSalWrapper.intMonthsCount = this.objSalWrapper.lstMonthLabels.length;
        this.disableDeleteMonth = this.objSalWrapper.intMonthsCount <= 1;

        var newMonth = {
            strMonthLabel : this.newMonthValue,
            strMonthValue : ''
        };
        
        this.objSalWrapper.lstEarningsWrapper = this.objSalWrapper.lstEarningsWrapper.map(row => {
            row.lstAmtWrapper.push(newMonth);
            return row;
        });

        this.objSalWrapper.lstDeductionsWrapper = this.objSalWrapper.lstDeductionsWrapper.map(row => {
            row.lstAmtWrapper.push(newMonth);
            return row;
        });
        
        this.newMonthValue = '';
        this.boolAddNewMonth = false;
    }
    
    delMonth(event) {
        let strMonth = event.currentTarget.dataset.month;
        console.log('strMonth -->'+strMonth);

        const intIndex = this.objSalWrapper.lstMonthLabels.indexOf(strMonth);
        if(intIndex > -1) {
            this.objSalWrapper.lstMonthLabels.splice(intIndex, 1);
        }
        if(this.objSalWrapper.intMonthsCount > 0) {
            this.objSalWrapper.intMonthsCount -= 1;
        }
        if(this.objSalWrapper.intMonthsColSpanCount > 0) {
            this.objSalWrapper.intMonthsColSpanCount -= 1;
        }

        this.spinnerRun = true; 
        deleteMonthlyValues({parentId: this.parentId, monthdata: strMonth})
        .then(response => {
            console.log('deleteMonthlyValues -->',response);

            this.getSalaryWrapper();
        })
        .catch(error=>{
            this.spinnerRun = false; 
            console.log('deleteMonthlyValues -->',error);
            console.log('deleteMonthlyValues -->'+JSON.stringify(error));
        });
    }

    updateParticularRecord(event) {
        const name = event.target.name;
        console.log('name: '+name);

        var rowType = '';
        var dataWrapper = {};
        var monthWrapper = [];

        if(name === 'update add record'){
            this.objSalWrapper.lstEarningsWrapper.map(row => {
                if (row.recordId === this.selectedAddRow) {
                    var data = {
                        Id : row.recordId,
                        Nature_Of_Component__c : row.strNatureOfComponent,
                        Type_Of_Component__c : row.strParticulars
                    };

                    this.newADDdataWrapper = data;
                    dataWrapper = data;
                    this.newMonthWrapper = row.lstAmtWrapper;
                    monthWrapper = this.newMonthWrapper;
                }
            });

            rowType = 'Add';
        }
        else {
            this.objSalWrapper.lstDeductionsWrapper.map(row => {
                if (row.recordId === this.selectedAddRow) {
                    var data = {
                        Id : row.recordId,
                        Nature_Of_Component__c : row.strNatureOfComponent,
                        Type_Of_Component__c : row.strParticulars
                    };

                    this.newLESSdataWrapper = data;
                    dataWrapper = data;
                    this.newMonthWrapperLess = row.lstAmtWrapper;
                    monthWrapper = this.newMonthWrapperLess;
                }
            });

            rowType = 'Less';
        }

        // console.log('dataWrapper: '+JSON.stringify(dataWrapper));
        // console.log('monthWrapper: '+JSON.stringify(monthWrapper));

        if(!dataWrapper.Type_Of_Component__c){
            this.showToast('Error', 'Please select particular.', 'error');
            return;
        }
        if(monthWrapper.length == 0){
            this.showToast('Error', 'Please add atleast one month values.', 'error');
            return;
        }
        if(monthWrapper.length != this.objSalWrapper.lstMonthLabels.length){
            this.showToast('Error', 'Please add all the month values.', 'error');
            return;
        }

        this.spinnerRun = true;
        this.refreshADD = false;
        this.refreshLESS = false;
        
        const fields = {};
        fields['Id'] = dataWrapper.Id;
        fields['Add_Less__c'] = rowType;
        fields['Loan_Application__c'] = this.recordId,
        fields['Applicant__c'] = this.applicantId,
        fields['Nature_Of_Component__c'] = dataWrapper.Nature_Of_Component__c;
        fields['Type_Of_Component__c'] = dataWrapper.Type_Of_Component__c;
        fields['Parent__c'] = this.parentId;
        fields['RecordTypeId'] = this.objSalWrapper.recordTypeParent;

        const recordInput = { fields };
        console.log('recordInput: '+JSON.stringify(recordInput));

        updateRecord(recordInput)
        .then((response) => {
            console.log('update response -->'+JSON.stringify(response));

            this.newADDdataWrapper.Id = null;
            this.newADDdataWrapper.Nature_Of_Component__c = '';
            this.newADDdataWrapper.Type_Of_Component__c = '';

            this.newLESSdataWrapper.Id = null;
            this.newLESSdataWrapper.Nature_Of_Component__c = '';
            this.newLESSdataWrapper.Type_Of_Component__c = '';

            this.refreshADD = true;
            this.refreshLESS = true;

            upsertMonthlyValue({
                loanId : this.recordId,
                applicantId: this.applicantId,
                childparentId: response.id,
                parentId: this.parentId,
                allChildData: monthWrapper
            }).then(response=>{
                this.newMonthWrapper = [];
                this.newMonthWrapperLess = [];

                this.filterPicklistValue();
                this.getSalaryWrapper();
            }).catch(error=>{
                this.spinnerRun = false; 
            });
            this.calculateNetIncome();//(this.totalAvgGross, this.totalAvgGrossLess, this.yearlyComponents.netAmount, this.incentiveComponents.netAmount);//calling this here to refresh the netrincome
        })
        .catch((error) => {
            this.spinnerRun = false; 
            this.refreshADD = true;
            this.refreshLESS = true;
            console.log('Error createRecord -->'+ JSON.stringify(error));
        });
    }

    createParticularRecord(event) {
        const name = event.target.name;
        console.log('name: '+name);

        var rowType = '';
        var dataWrapper = {};
        var monthWrapper = [];

        if(name === 'create add record'){
            rowType = 'Add';
            dataWrapper = this.newADDdataWrapper;
            monthWrapper = this.newMonthWrapper;
        }
        else{
            rowType = 'Less';
            dataWrapper = this.newLESSdataWrapper;
            monthWrapper = this.newMonthWrapperLess;
        }

        // console.log('dataWrapper: '+JSON.stringify(dataWrapper));
        // console.log('monthWrapper: '+JSON.stringify(monthWrapper));

        if(!dataWrapper.Type_Of_Component__c){
            this.showToast('Error', 'Please select particular.', 'error');
            return;
        }
        if(monthWrapper.length == 0){
            this.showToast('Error', 'Please add atleast one month values.', 'error');
            return;
        }
        if(monthWrapper.length != this.objSalWrapper.lstMonthLabels.length){
            this.showToast('Error', 'Please add all the month values.', 'error');
            return;
        }

        this.spinnerRun = true;
        this.refreshADD = false;
        this.refreshLESS = false;
        
        const fields = {};
        fields['Add_Less__c'] = rowType;
        fields['Loan_Application__c'] = this.recordId,
        fields['Applicant__c'] = this.applicantId,
        fields['Nature_Of_Component__c'] = dataWrapper.Nature_Of_Component__c;
        fields['Type_Of_Component__c'] = dataWrapper.Type_Of_Component__c;
        fields['Parent__c'] = this.parentId;
        fields['RecordTypeId'] = this.objSalWrapper.recordTypeParent;

        const recordInput = { apiName: INCOME_ASSESSMENT_OBJECT.objectApiName, fields };
        console.log('recordInput: '+JSON.stringify(recordInput));

        createRecord(recordInput)
        .then((response) => {
            console.log('response -->'+JSON.stringify(response));

            this.newADDdataWrapper.Id = null;
            this.newADDdataWrapper.Nature_Of_Component__c = '';
            this.newADDdataWrapper.Type_Of_Component__c = '';

            this.newLESSdataWrapper.Id = null;
            this.newLESSdataWrapper.Nature_Of_Component__c = '';
            this.newLESSdataWrapper.Type_Of_Component__c = '';

            this.refreshADD = true;
            this.refreshLESS = true;

            upsertMonthlyValue({
                loanId : this.recordId,
                applicantId: this.applicantId,
                childparentId: response.id,
                parentId: this.parentId,
                allChildData: monthWrapper
            }).then(response=>{
                this.newMonthWrapper = [];
                this.newMonthWrapperLess = [];

                this.filterPicklistValue();
                this.getSalaryWrapper();
            }).catch(error=>{
                this.spinnerRun = false; 
            });
            this.calculateNetIncome();//(this.totalAvgGross, this.totalAvgGrossLess, this.yearlyComponents.netAmount, this.incentiveComponents.netAmount);//calling this here to refresh the netrincome
        })
        .catch((error) => {
            this.spinnerRun = false; 
            this.refreshADD = true;
            this.refreshLESS = true;
            console.log('Error createRecord -->'+ JSON.stringify(error));
        });
    }

    get hideAddithionCmp(){
        return !this.showADDcmp && !this.showLESScmp;
    }

    handleDeleteParticular(event){
        this.deleteParticularId = event.target.dataset.id;
        this.showgenericConfirmParticular = true;
    }

    handleNegativeParticular(){
        this.showgenericConfirmParticular = false;
        this.deleteParticularId = '';
    }

    handlePositiveParticular(){
        deleteParticular({
            recordId: this.deleteParticularId
        }).then(response=>{
            this.showgenericConfirmParticular = false;
            this.handleNegativeParticular();
            this.filterPicklistValue();
            this.getSalaryWrapper();
        }).catch(error=>{
            this.showgenericConfirmParticular = false;
        });
    }

    getAllYearlyData(retainValue){
        console.log('this.parentId609: '+this.parentId);

        getAllYearlyComponent({
            recordId : this.parentId
        }).then(response=>{
            // console.log('response: '+JSON.stringify(response));

            if(retainValue){
                if(response.yearlyChildData[0].addRecord == true){
                    response.yearlyChildData[0].grossAmount = this.yearlyChildData[0].grossAmount;
                    response.yearlyChildData[0].multiplier = this.yearlyChildData[0].multiplier;
                    response.yearlyChildData[0].taxSlab = this.yearlyChildData[0].taxSlab;
                    response.yearlyChildData[0].netAmount = this.yearlyChildData[0].netAmount;
                }
                else if(response.yearlyChildData[1].addRecord == true){
                    response.yearlyChildData[1].grossAmount = this.yearlyChildData[1].grossAmount;
                    response.yearlyChildData[1].multiplier = this.yearlyChildData[1].multiplier;
                    response.yearlyChildData[1].taxSlab = this.yearlyChildData[1].taxSlab;
                    response.yearlyChildData[1].netAmount = this.yearlyChildData[1].netAmount;
                }
            }

            this.yearlyComponents = response;
            this.calculateNetIncome();//(this.totalAvgGross, this.totalAvgGrossLess, this.yearlyComponents.netAmount, this.incentiveComponents.netAmount);
            this.yearlyChildData = [];
            this.addedIndex = 0;
            console.log('yearly response: '+JSON.stringify(response));

            this.yearlyChildData = response.yearlyChildData;
            this.addedIndex = this.yearlyChildData.length;
        }).catch(error=>{
            console.log('Error getAllYearlyComponent -->'+JSON.stringify(error));
        })
    }

    getAllIncentiveData(){
        getAllIncentiveDetails({
            recordId : this.parentId
        }).then(response=>{
            this.incentiveComponents = response;
            this.calculateNetIncome();//(this.totalAvgGross, this.totalAvgGrossLess, this.yearlyComponents.netAmount, this.incentiveComponents.netAmount);
            this.incentiveChildData = response.yearlyChildData;
            const maxRecords = 6;
            if (!this.incentiveChildData || this.incentiveChildData.length === 0) {
                this.incentiveChildData = Array.from({ length: maxRecords }, (_, i) => ({
                    id: `temp_${i + 1}`,
                    srNo: i + 1,
                    yearlyComponent: `Month ${i + 1}`,
                    grossAmount: '0',
                    multiplier: '',
                    taxSlab: '',
                    frequency: '',
                    netAmount: '',
                    addRecord: true,
                    editRecord: true
                }));
            }
            else if (this.incentiveChildData.length < maxRecords) {
                const currentLength = this.incentiveChildData.length;
                for (let i = currentLength; i < maxRecords; i++) {
                    this.incentiveChildData.push({
                        id: `temp_${i + 1}`,
                        srNo: i + 1,
                        yearlyComponent: `Month ${i + 1}`,
                        grossAmount: '0',
                        multiplier: '',
                        taxSlab: '',
                        frequency: '',
                        netAmount: '',
                        addRecord: true,
                        editRecord: true
                    });
                }
            }

            console.log('this.incentiveComponents>>',JSON.stringify(this.incentiveComponents));
            console.log('this.incentiveChildData' + JSON.stringify(this.incentiveChildData));
            this.incentiveAddedIndex = this.incentiveChildData.length;
        }).catch(error=>{
            console.log('Error getAllIncentiveDetails -->'+JSON.stringify(error));
        })
    }

    handleADDRecord(event){
        const cmp = event.target.name;
        this.isUnsavedIncentRow = true;

        this.incentiveAddedIndex = this.incentiveAddedIndex + 1;
        this.incentiveNewEntry.id = this.incentiveAddedIndex;
        this.incentiveNewEntry.srNo = this.incentiveAddedIndex;
        this.incentiveNewEntry.yearlyComponent = 'Month ' + this.incentiveAddedIndex;
        this.incentiveChildData = [...this.incentiveChildData, { ...this.incentiveNewEntry }];
    }

    handleEditParticularRecord(event){
        const cmp = event.target.name;

        if(cmp === 'edit add record'){
            this.objSalWrapper.lstEarningsWrapper = this.objSalWrapper.lstEarningsWrapper.map(row => {
                if (row.recordId === event.target.dataset.id) {
                    this.selectedAddRow = event.target.dataset.id;
                    return { ...row, editRecord: true };
                }
                return row;
            });
        }
        else {
            this.objSalWrapper.lstDeductionsWrapper = this.objSalWrapper.lstDeductionsWrapper.map(row => {
                if (row.recordId === event.target.dataset.id) {
                    this.selectedAddRow = event.target.dataset.id;
                    return { ...row, editRecord: true };
                }
                return row;
            });
        }
    }

    handleEditRecord(event){
        const cmp = event.target.name;

        if(cmp === 'incentive'){
            this.incentiveChildData.forEach(record => {
                if(record.id == event.target.dataset.id){
                    record.editRecord = true;
                }
            });
            
            this.incentiveChildData = this.incentiveChildData.map(row => {
                if (row.id === event.target.dataset.id) {
                    return { ...row, editRecord: true };
                }
                return row;
            });
        }
        else{
            this.yearlyChildData.forEach(record => {
                if(record.id == event.target.dataset.id){
                    record.editRecord = true;
                }
            });
        }
    }

    handleParticularRecordUndo(event){
        const cmp = event.target.name;

        if(cmp === 'undo add record'){
            this.objSalWrapper.lstEarningsWrapper = this.objSalWrapper.lstEarningsWrapper.map(row => {
                if (row.recordId === event.target.dataset.id) {
                    return { ...row, editRecord: false };
                }
                return row;
            });
        }
        else{
            this.objSalWrapper.lstDeductionsWrapper = this.objSalWrapper.lstDeductionsWrapper.map(row => {
                if (row.recordId === event.target.dataset.id) {
                    return { ...row, editRecord: false };
                }
                return row;
            });
        }
    }

    handleYearlyComponentUndo(event){
        const cmp = event.target.name;

        if(cmp === 'incentive'){
            if(this.isUnsavedIncentRow){
                this.incentiveChildData = this.incentiveChildData.slice(0, -1);
                this.incentiveAddedIndex = this.incentiveAddedIndex - 1;
            }
            else{
                this.incentiveChildData.forEach(record => {
                    if(record.id == event.target.dataset.id){
                        record.editRecord = false;
                    }
                });
            }
        }
        else{
            this.yearlyChildData.forEach(record => {
                if(record.id == event.target.dataset.id){
                    record.editRecord = false;
                }
            });
        }

        this.isUnsavedIncentRow = false;
    }

    handleTableInputChange(event){
        this.yearlyChildData.forEach(record => {
            if(record.id == event.target.dataset.id){
                record[event.target.dataset.name] = event.target.value;

                if(record.grossAmount && record.taxSlab){
                    var multi = record.multiplier ? record.multiplier : 1;
                    record.netAmount = ((record.grossAmount * multi) * (1 - (record.taxSlab / 100))).toFixed(2);
                }
            }
        });
    }

    handleIncentiveTableInputChange(event){
        this.incentiveChildData.forEach(record => {
            if(record.id == event.target.dataset.id){
                record[event.target.dataset.name] = event.target.value;

                if(record.grossAmount && record.taxSlab){
                    var multi = record.multiplier ? record.multiplier : 1;
                    record.netAmount = ((record.grossAmount * multi) * (1 - (record.taxSlab / 100))).toFixed(2);
                }
            }
        });
    }

    handleSaveRecord(event){
        const cmp = event.target.name;
        var dataList = [];
        var recordTypeId = '';

        if(cmp === 'incentive'){
            dataList = this.incentiveChildData;
            recordTypeId = this.incentiveComponents.recordId;
        }
        else{
            dataList = this.yearlyChildData;
            recordTypeId = this.yearlyComponents.recordId;
        }
        console.log('dataList: '+JSON.stringify(dataList));

        dataList.forEach(record => {

            if(record.id == event.target.dataset.id && record.addRecord){ 

                if(record.grossAmount != null && record.taxSlab != null && record.multiplier != null && record.grossAmount != undefined && record.taxSlab != undefined && record.multiplier != undefined){
                    const fields = {};

                    fields['Loan_Application__c'] = this.recordId,
                    fields['Applicant__c'] = this.applicantId,
                    fields['Yearly_Component__c'] = record.yearlyComponent;
                    fields['Gross_Amount__c'] = record.grossAmount;
                    fields['Multiplier__c'] = record.multiplier;
                    fields['Tax_Slab__c'] = record.taxSlab;
                    fields['Frequency__c'] = record.frequency;
                    fields['Parent__c'] = this.parentId;
                    fields['RecordTypeId'] = recordTypeId;
                    fields['Net_Amount__c'] = record.netAmount;

                    const recordInput = { apiName: INCOME_ASSESSMENT_OBJECT.objectApiName, fields };
                    // console.log('insert recordInput: '+JSON.stringify(recordInput));

                    createRecord(recordInput)
                    .then((response) => {
                        console.log('create response: '+JSON.stringify(response));

                        record.id = response.id;
                        record.addRecord = false;
                        record.editRecord = false;

                        if(cmp === 'incentive'){
                            getAllIncentiveDetails({ //Arman : calling this here to refresh the gross values without completely refreshing trh UI
                                recordId : this.parentId
                            }).then(response=>{
                                this.incentiveComponents = response;
                            }).catch(error=>{
                                console.log('Error getAllIncentiveDetails -->826>'+JSON.stringify(error));
                            })
                        }
                        else{
                            this.getAllYearlyData(true);
                        }
                    })
                    .catch((error) => {
                        console.log('Error createRecord -->'+ JSON.stringify(error));
                    });
                }else{
                    this.showToast('Error', 'Please fill all the required details.', 'error');
                    return;
                }
            }
            else if(record.id == event.target.dataset.id && record.editRecord){
                
                if(record.grossAmount != null && record.taxSlab != null && record.multiplier != null && record.grossAmount != undefined && record.taxSlab != undefined && record.multiplier != undefined){
                    const fields = {};

                    fields['Loan_Application__c'] = this.recordId,
                    fields['Applicant__c'] = this.applicantId,
                    fields['Id'] = record.id;
                    fields['Yearly_Component__c'] = record.yearlyComponent;
                    fields['Gross_Amount__c'] = record.grossAmount;
                    fields['Multiplier__c'] = record.multiplier;
                    fields['Tax_Slab__c'] = record.taxSlab;
                    fields['Frequency__c'] = record.frequency;
                    fields['Parent__c'] = this.parentId;
                    fields['RecordTypeId'] = recordTypeId;
                    fields['Net_Amount__c'] = record.netAmount;

                    const recordInput = { fields };
                    // console.log('update recordInput: '+JSON.stringify(recordInput));
        
                    updateRecord(recordInput)
                    .then((response) => {
                        console.log('update response: '+JSON.stringify(response));

                        record.addRecord = false;
                        record.editRecord = false;

                        if(cmp === 'incentive'){
                            getAllIncentiveDetails({ //Arman : calling this here to refresh the gross values without completely refreshing trh UI
                                recordId : this.parentId
                            }).then(response=>{
                                this.incentiveComponents = response;
                            }).catch(error=>{
                                console.log('Error getAllIncentiveDetails -->826>'+JSON.stringify(error));
                            })
                        }
                        else{
                            this.getAllYearlyData(true);
                        }
                    })
                    .catch(error => {
                        console.log('Error updateRecord -->'+ JSON.stringify(error));
                    });
                }
                else{
                    this.showToast('Error', 'Please fill all the required details.', 'error');
                    return;
                }
            }
        });
        this.calculateNetIncome();//(this.totalAvgGross, this.totalAvgGrossLess, this.yearlyComponents.netAmount, this.incentiveComponents.netAmount);//calling this here to refresh the netrincome
        this.isUnsavedIncentRow = false;
    }

    handlePositive(event){
        var dataList = [];

        if(this.deleteRowSection === 'incentive'){
            dataList = this.incentiveChildData;
        }
        else{
            dataList = this.yearlyChildData;
        }

        dataList.forEach(record => {
            if(record.id == this.deleteIndex){
                if(!record.addRecord){
                    deleteYearlyComponent({
                        recordId : record.id
                    }).then(response=>{
                        this.showgenericConfirm = false;

                        if(this.deleteRowSection === 'incentive'){
                            this.getAllIncentiveData();
                        }
                        else{
                            this.getAllYearlyData(false);
                        }

                        this.handleNegative();
                    }).catch(error=>{
                        this.showgenericConfirm = false;
                        console.log('Error deleteYearlyComponent -->'+JSON.stringify(error));
                    })
                }
            }
        });
    }

    handleNegative(){
        this.deleteIndex = 0;
        this.showgenericConfirm = false;
        this.deleteRowSection = '';
    }

    handleYearlyComponentDelete(event){
        this.deleteIndex = event.target.dataset.id;
        this.showgenericConfirm = true;
        this.deleteRowSection = event.target.name;
    }

    handleRentalIncomeChange(event) {
        this.rentalIncome = event.target.value;

        upsertRentalIncome({
            'loanId' : this.recordId,
            'applicantId' : this.applicantId,
            'rentalIncome' : this.rentalIncome,
            'recId' : this.rentalRecId
        })
        .then((response) => {
            console.log('response 173: '+response);
            this.getRentalData(); //change by Kunal Bisht for SFHL-1961
            if(response != 'Success'){
                this.showToast('Error', response, 'error');
            }
            this.calculateNetIncome();
        })
        .catch(error => {
            console.log('Error updateRecord -->' + JSON.stringify(error));
        });
    }

    getRentalData() {
        getRentalDetails({
            'loanId' : this.recordId,
            'applicantId' : this.applicantId
        })
        .then((response) => {
            if(response){
                this.rentalRecId = response[0];
                this.rentalIncome = response[1];
            }
        })
        .catch(error => {
            console.log('Error updateRecord -->' + JSON.stringify(error));
        });
    }

    // Show Toast Message
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}