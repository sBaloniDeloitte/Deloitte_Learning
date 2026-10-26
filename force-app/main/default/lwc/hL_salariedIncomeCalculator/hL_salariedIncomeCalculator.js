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
// import createMonthlyValue from '@salesforce/apex/HL_SalariedScreenController.createMonthlyValue';
import deleteParticular from '@salesforce/apex/HL_SalariedScreenController.deleteParticular';
import deleteMonthlyValues from '@salesforce/apex/HL_SalariedScreenController.deleteMonthlyValues';
import saveTotalGross from '@salesforce/apex/HL_SalariedScreenController.saveTotalGross';
import saveNetSalary from '@salesforce/apex/HL_SalariedScreenController.saveNetSalary';
import upsertRentalIncome from '@salesforce/apex/HL_SalariedScreenController.upsertRentalIncome';
import getRentalDetails from '@salesforce/apex/HL_SalariedScreenController.getRentalDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import initiateAPIRequest from '@salesforce/apex/HL_EligibilityApiController.initiateAPIRequest';
import fetchProductId from '@salesforce/apex/HL_SalariedScreenController.fetchProductId';
import { fireEvent } from 'c/pubsub';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
// import getTenureProduct from '@salesforce/apex/Utility.getTenureProduct';
import getObligationsRecords from "@salesforce/apex/COMM_ObligationsController.getObligationsRecords";
export default class HL_salariedIncomeCalculator extends LightningElement {

    @api disableEdit = false;
    @api recordId;
    @api applicantId;
    @api parentId;
    @api showCalculator = false;
    @wire(getObjectInfo, { objectApiName: INCOME_ASSESSMENT_OBJECT})
    INCOME_ASSESSMENT_INFO;
    @track tenureProduct = {};;
    @track spinnerRun = false;
    @track objSalWrapper={};
    newMonthValue;
    newNatureOfComponent;
    newParticulars;
    @track newMonthWrapper = [];
    @track newMonthWrapperLess = [];
    newPercentAllocated;
    boolAddNewMonth = false;
    debounceTimeout;
    @track availableParticulars=[];
    @track deleteParticularId = '';

    @track showgenericConfirm = false;
    @track deleteIndex = 0;
    @track confirmMessage = 'Are you sure you want to delete this data?';
    positiveLabel = 'Yes';
    negativelabel = 'No';

    @track showgenericConfirmParticular = false;
    @track netTenure;
    @track addOptions = [];
    @track lessOptions = [];
    @track showADDcmp = false;
    @track showLESScmp = false;
    @track refreshLESS = true;
    @track refreshADD = true;

    @track yearlyComponents = [];
    @track yearlyChildData = [];
    @track addedIndex = 0;
    @track firstTimeLoad = true;

    @track incentiveComponents = [];
    @track incentiveChildData = [];
    @track incentiveAddedIndex = 1;
 @wire(CurrentPageReference) pageRef;
    @track totalAvgGross = 0;
    @track totalAvgGrossLess = 0;
    @track showADDgross = false;
    @track showLESSgross = false;
    @track natureOfCMPvalues = [];
    @track typeOfCMPvalues = [];
    @track netAvgSalary = 0;
    productId;
    rentalIncome = 0;
    rentalRecId = '';
    isUnsavedIncentRow = false;
    frequencyOptions = [
        { label: "BI Monthly", value: "BI Monthly" },
        { label: "Quarterly", value: "Quarterly" },
        { label: "Half Yearly", value: "Half Yearly" },
        { label: "Annually", value: "Annually" }
    ];

    deleteRowSection = ''

    newADDdataWrapper = {
        'index': null,
        'Nature_Of_Component__c': '',
        'Type_Of_Component__c': ''
    };

    newLESSdataWrapper = {
        'index': null,
        'Nature_Of_Component__c': '',
        'Type_Of_Component__c': ''
    }

    newEntry = {
        srNo: '',
        yearlyComponent: '',
        grossAmount: '',
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
        grossAmount: '',
        multiplier: '',
        taxSlab: '',
        netAmount: '',
        frequency: '',
        id: '',
        addRecord: true,
        editRecord: true
    };
    @track filteredList = [];
    @track allData;
    @track recordData = [];
    @track totalData = {};
    @track newmap = {
    'grossSalary' : '',
    'totalDeductions' : '',
    'previousYearBonus' : '',
    'latestYearBonus' : '',
    'month1Net' : '',
    'month2Net' : '',
    'month3Net' : '',
    'month4Net' : '',
    'month5Net' : '',
    'month6Net' : '',
    'rentalIncome' : '',
    'TotalObligation' : '',
    'docmarketVal' : '',
    'finalLoanAmount' : '',
    'roi' : '',
    'tenor' : '',
    'additionalFOIR' : ''
    }

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
        //this.getTenureProduct();
        this.getobligations();
        if(this.parentId){
            this.getAllYearlyData();
            this.getAllIncentiveData();
            this.getRentalData();
        }
        setTimeout(() => {
        this.newmap.grossSalary = this.totalAvgGross;
        this.newmap.totalDeductions = this.totalAvgGrossLess;
        console.log('totalAvgGross : '+this.totalAvgGross);
        console.log('totalAvgGrossLess : '+this.totalAvgGrossLess);
        console.log('yearlyComponents.netAmount : '+this.yearlyComponents.netAmount);
        console.log('incentiveComponents.netAmount : '+this.incentiveComponents.netAmount);
        }, 4000);
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

        }).catch(error=>{
            console.log('Error saveTotalNet -->'+JSON.stringify(error));
        });
    }

    getSalaryWrapper() {
        console.log('this.parentId -->'+this.parentId);
        getSalaryDetails({parentId: this.parentId})
        .then(response => {
            console.log('getSalaryDetails -->'+JSON.stringify(response));
            this.objSalWrapper = response;

            var totalAvg = 0;
            if(this.objSalWrapper.lstTotalAmount != null && this.objSalWrapper.lstTotalAmount.length >0){
                this.objSalWrapper.lstTotalAmount.forEach(recordId => {
                    totalAvg = totalAvg + recordId;
                });
                this.totalAvgGross = (totalAvg / this.objSalWrapper.lstTotalAmount.length).toFixed(0);
                this.showADDgross = true;
            }else{
                this.showADDgross = false;
            }
            this.saveGROSSValue();

            totalAvg = 0;
            if(this.objSalWrapper.lstTotalAmountLess != null && this.objSalWrapper.lstTotalAmountLess.length>0){
                this.objSalWrapper.lstTotalAmountLess.forEach(recordId => {
                    totalAvg = totalAvg + recordId;
                });
                this.totalAvgGrossLess = (totalAvg / this.objSalWrapper.lstTotalAmountLess.length).toFixed(0);
                this.showLESSgross = true;
            }else{
                this.showLESSgross = false;
            }

            if(this.showLESSgross && this.showADDgross){
                this.netAvgSalary = this.totalAvgGross - this.totalAvgGrossLess;
                
                this.saveNetSalary();
            }
            console.log('netAvgSalary--'+this.netAvgSalary);
            this.spinnerRun = false;
        })
        .catch(error=>{
            this.spinnerRun = false;            
            console.log('getSalaryDetails -->',error);
            console.log('getSalaryDetails -->'+JSON.stringify(error));
        });
    }

    get disableAdditionOfMonth() {
        return this.showLESSgross || this.showADDgross || this.boolAddNewMonth;
    }

    get showNetSalary(){
        return this.showLESSgross && this.showADDgross;
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

    inputChanged(event) {
        if(event.target.name == 'newMonthLabel') {
            this.newMonthValue = event.target.value;
        } else if(event.target.name == 'newComponentNature') {
            this.newNatureOfComponent = event.target.value;
        } else if(event.target.name == 'newParticulars') {
            this.newParticulars = event.target.value;
        } else if(event.target.name == 'newMonthValue') {
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
            } else {
                this.newMonthWrapper.push({'strMonthLabel' : monthLabel, 'strMonthValue' : monthVal});
            }
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
        }else if(event.target.name == 'newPercentAllocated') {
            this.newPercentAllocated = event.target.value;
        }
        
        console.log('newMonthWrapper -->'+JSON.stringify(this.newMonthWrapper));
        console.log('newMonthWrapperLess -->'+JSON.stringify(this.newMonthWrapperLess));
    }

    saveNewMonth(event) {
        if(!this.newMonthValue){
            this.showToast('Error', 'Please enter month name.', 'error');
            return;
        }

        var count = this.objSalWrapper.lstMonthLabels.filter(month => month == this.newMonthValue).length;
        if(count > 0){
            this.showToast('Error', 'Duplicate monthly value found.', 'error');
            return;
        }

        if(!this.objSalWrapper.lstMonthLabels) {
            this.objSalWrapper.lstMonthLabels = [];
        }
        this.objSalWrapper.lstMonthLabels.push(this.newMonthValue);
        this.objSalWrapper.intMonthsCount = this.objSalWrapper.lstMonthLabels.length;
        this.boolAddNewMonth = false;
        this.newMonthValue = '';
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
            console.log('deleteMonthlyValues -->'+JSON.stringify(response));
            this.objSalWrapper = response;
            console.log('deleteMonthlyValues -->'+JSON.stringify(this.objSalWrapper));

            var totalAvg = 0;
            if(this.objSalWrapper.lstTotalAmount != null && this.objSalWrapper.lstTotalAmount.length>0){
                this.objSalWrapper.lstTotalAmount.forEach(recordId => {
                    totalAvg = totalAvg + recordId;
                });
                this.totalAvgGross = (totalAvg / this.objSalWrapper.lstTotalAmount.length).toFixed(0);
                this.showADDgross = true;
            }else{
                this.showADDgross = false;
            }
            this.saveGROSSValue();

            totalAvg = 0;
            if(this.objSalWrapper.lstTotalAmountLess != null && this.objSalWrapper.lstTotalAmountLess.length>0){
                this.objSalWrapper.lstTotalAmountLess.forEach(recordId => {
                    totalAvg = totalAvg + recordId;
                });
                this.totalAvgGrossLess = (totalAvg / this.objSalWrapper.lstTotalAmountLess.length).toFixed(0);
                this.showLESSgross = true;
            }else{
                this.showLESSgross = false;
            }

            this.spinnerRun = false;
        })
        .catch(error=>{
            this.spinnerRun = false; 
            console.log('deleteMonthlyValues -->',error);
            console.log('deleteMonthlyValues -->'+JSON.stringify(error));
        });
    }

    addNewEarningsParticular(event) {
        // if(!this.newADDdataWrapper.Nature_Of_Component__c){
        //     this.showToast('Error', 'Please add nature of component.', 'error');
        //     return;
        // }
        if(!this.newADDdataWrapper.Type_Of_Component__c){
            this.showToast('Error', 'Please add the type of salary component.', 'error');
            return;
        }
        if(this.newMonthWrapper.length == 0){
            this.showToast('Error', 'Please add atleast one monthly values.', 'error');
            return;
        }
        if(this.newMonthWrapper.length != this.objSalWrapper.lstMonthLabels.length){
            this.showToast('Error', 'Please add all the monthly values.', 'error');
            return;
        }

        this.spinnerRun = true; 
        this.refreshADD = false;
        
        const fields = {};
        fields['Add_Less__c'] = 'Add';
        fields['Loan_Application__c'] = this.recordId,
        fields['Applicant__c'] = this.applicantId,
        fields['Nature_Of_Component__c'] = this.newADDdataWrapper.Nature_Of_Component__c;
        fields['Type_Of_Component__c'] = this.newADDdataWrapper.Type_Of_Component__c;
        fields['Parent__c'] = this.parentId;
        fields['RecordTypeId'] = this.objSalWrapper.recordTypeParent;

        const recordInput = { apiName: INCOME_ASSESSMENT_OBJECT.objectApiName, fields };

        createRecord(recordInput)
        .then((response) => {
            console.log('response -->'+JSON.stringify(response));
            this.newADDdataWrapper.Nature_Of_Component__c = '';
            this.newADDdataWrapper.Type_Of_Component__c = '';
            console.log('this.newMonthWrapper -->'+JSON.stringify(this.newMonthWrapper));
            this.refreshADD = true;

            createMonthlyValue({
                loanId : this.recordId,
                applicantId: this.applicantId,
                childparentId: response.id,
                parentId: this.parentId,
                allChildData: this.newMonthWrapper
            }).then(response=>{
                this.newMonthWrapper = [];
                this.filterPicklistValue();
                this.getSalaryWrapper();
            }).catch(error=>{
                this.spinnerRun = false; 
            });
        })
        .catch((error) => {
            this.spinnerRun = false; 
            this.refreshADD = true;
            console.log('Error createRecord -->'+ JSON.stringify(error));
        });
    }

    lessNewEarningsParticular(){
        // if(!this.newLESSdataWrapper.Nature_Of_Component__c){
        //     this.showToast('Error', 'Please add nature of component.', 'error');
        //     return;
        // }
        if(!this.newLESSdataWrapper.Type_Of_Component__c){
            this.showToast('Error', 'Please add the type of salary component.', 'error');
            return;
        }
        if(this.newMonthWrapperLess.length == 0){
            this.showToast('Error', 'Please add atleast one monthly values.', 'error');
            return;
        }

        if(this.newMonthWrapperLess.length != this.objSalWrapper.lstMonthLabels.length){
            this.showToast('Error', 'Please add atleast one monthly salary values to proceed.', 'error');
            return;
        }

        this.spinnerRun = true; 
        this.refreshLESS = false;

        const fields = {};
        fields['Add_Less__c'] = 'Less';
        fields['Loan_Application__c'] = this.recordId,
        fields['Applicant__c'] = this.applicantId,
        fields['Nature_Of_Component__c'] = this.newLESSdataWrapper.Nature_Of_Component__c;
        fields['Type_Of_Component__c'] = this.newLESSdataWrapper.Type_Of_Component__c;
        fields['Parent__c'] = this.parentId;
        fields['RecordTypeId'] = this.objSalWrapper.recordTypeParent;

        const recordInput = { apiName: INCOME_ASSESSMENT_OBJECT.objectApiName, fields };

        createRecord(recordInput)
        .then((response) => {
            console.log('response -->'+JSON.stringify(response));
            this.newLESSdataWrapper.Nature_Of_Component__c = '';
            this.newLESSdataWrapper.Type_Of_Component__c = '';
            console.log('this.newMonthWrapper -->'+JSON.stringify(this.newMonthWrapperLess));
            this.refreshLESS = true;

            createMonthlyValue({
                loanId : this.recordId,
                applicantId: this.applicantId,
                childparentId: response.id,
                parentId: this.parentId,
                allChildData: this.newMonthWrapperLess
            }).then(response=>{
                this.newMonthWrapperLess = [];
                this.filterPicklistValue();
                this.getSalaryWrapper();
            }).catch(error=>{
                this.spinnerRun = false; 
            });
        })
        .catch((error) => {
            this.spinnerRun = false; 
            this.refreshLESS = true;
            console.log('Error createRecord -->'+ JSON.stringify(error));
        });
    }

    clearNewValueRow() {
        this.newNatureOfComponent = '';
        this.newParticulars = '';
        this.newMonthWrapper = [];
        this.newPercentAllocated = '';
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

    getAllYearlyData(){
        console.log('this.parentId609: '+this.parentId);
        getAllYearlyComponent({
            recordId : this.parentId
        }).then(response=>{
            this.yearlyComponents = response;
            this.yearlyChildData = [];
            this.addedIndex = 0;
            console.log('yearly response: '+JSON.stringify(response));
            this.yearlyChildData = response.yearlyChildData;
            this.yearlyChildData.forEach(record => {
                if (record.yearlyComponent === 'Latest Year Bonus') {
                    this.newmap.latestYearBonus = record.netAmount || 0;
                }
                if (record.yearlyComponent === 'Previous Year Bonus') {
                    this.newmap.previousYearBonus = record.netAmount || 0;
                }
            });
            console.log('Updated newmap with yearly bonus:', JSON.stringify(this.newmap));
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
            this.incentiveChildData = response.yearlyChildData;
            const maxRecords = 6;
            if (!this.incentiveChildData || this.incentiveChildData.length === 0) {
                this.incentiveChildData = Array.from({ length: maxRecords }, (_, i) => ({
                    id: `temp_${i + 1}`,
                    srNo: i + 1,
                    yearlyComponent: `Month ${i + 1}`,
                    grossAmount: '',
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
                        grossAmount: '',
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
            this.incentiveChildData.forEach(record => {
            const label = record.yearlyComponent;   // Example: "Month 1"
            const net = record.netAmount || 0;
            if (label.startsWith('Month ')) {
                const monthIndex = label.split(' ')[1]; // "1" from "Month 1"
                const key = `month${monthIndex}Net`;    // month1Net, month2Net ...
                this.newmap[key] = net;
            }
});
        }).catch(error=>{
            console.log('Error getAllIncentiveDetails -->'+JSON.stringify(error));
        })
    }

    handleADDRecord(event){
        const cmp = event.target.name;
        this.isUnsavedIncentRow = true;

        // if(cmp === 'incentive'){
            this.incentiveAddedIndex = this.incentiveAddedIndex + 1;
            this.incentiveNewEntry.id = this.incentiveAddedIndex;
            this.incentiveNewEntry.srNo = this.incentiveAddedIndex;
            this.incentiveNewEntry.yearlyComponent = 'Month ' + this.incentiveAddedIndex;
            this.incentiveChildData = [...this.incentiveChildData, { ...this.incentiveNewEntry }];
        // }
        // else{
        //     this.addedIndex = this.addedIndex + 1;
        //     this.newEntry.id = this.addedIndex;
        //     this.newEntry.srNo = this.addedIndex;
        //     this.yearlyChildData = [...this.yearlyChildData, { ...this.newEntry }];
        // }
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
    const recordId = event.target.dataset.id;
    const fieldName = event.target.dataset.name;
    const fieldValue = parseFloat(event.target.value); //
    const yearlyComponent = event.target.dataset.yearlyComponent;
    console.log('786 recordId: '+recordId);
    console.log('786 yearlyComponent: '+yearlyComponent);
    console.log('786 fieldName: '+fieldName);
    console.log('786 fieldValue: '+fieldValue);
        this.yearlyChildData.forEach(record => {
            if(record.id == event.target.dataset.id){
                record[event.target.dataset.name] = event.target.value;
console.log('record.taxSlab : '+record.taxSlab);
console.log('record.grossAmount : '+record.grossAmount);
                if(record.grossAmount && record.taxSlab){
                    var multi = record.multiplier ? record.multiplier : 1;
                    record.netAmount = ((record.grossAmount * multi) * (1 - (record.taxSlab / 100))).toFixed(2);
                    if(yearlyComponent == 'Latest Year Bonus'){
                        this.newmap.latestYearBonus = record.netAmount;
                    }
                    else if(yearlyComponent == 'Previous Year Bonus'){
                        this.newmap.previousYearBonus = record.netAmount;
                    }
                }
            }
        });
    }

    handleIncentiveTableInputChange(event){
        const month =event.target.dataset.incentive;
        console.log('month '+month);
        this.incentiveChildData.forEach(record => {
            if(record.id == event.target.dataset.id){
                record[event.target.dataset.name] = event.target.value;

                if(record.grossAmount && record.taxSlab){
                    var multi = record.multiplier ? record.multiplier : 1;
                    record.netAmount = ((record.grossAmount * multi) * (1 - (record.taxSlab / 100))).toFixed(2);
                    if(month == 'Month 1'){
                    this.newmap.month1Net = record.netAmount;
                    }
                    else if(month == 'Month 2'){
                    this.newmap.month2Net = record.netAmount;
                    }
                    else if(month == 'Month 3'){
                    this.newmap.month3Net = record.netAmount;
                    }
                    else if(month == 'Month 4'){
                    this.newmap.month4Net = record.netAmount;
                    }
                    else if(month == 'Month 5'){
                    this.newmap.month5Net = record.netAmount;
                    }
                    else if(month == 'Month 6'){
                    this.newmap.month6Net = record.netAmount;
                    }
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
                if(record.grossAmount && record.taxSlab && record.multiplier){
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
                           // this.getAllIncentiveData(); removinf this for now to stop the refresh UI.
                        }
                        else{
                            this.getAllYearlyData();
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
                if(record.grossAmount && record.taxSlab && record.multiplier){
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
                            //this.getAllIncentiveData(); //removing this right now to stop UI refresh
                        }
                        else{
                            this.getAllYearlyData();
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
                            this.getAllYearlyData();
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
        this.newmap.rentalIncome = event.target.value;
        if(!this.showCalculator){
        upsertRentalIncome({
            'loanId' : this.recordId,
            'applicantId' : this.applicantId,
            'rentalIncome' : this.rentalIncome,
            'recId' : this.rentalRecId
        })
        .then((response) => {
            console.log('response 173: '+response);

            if(response != 'Success'){
                this.showToast('Error', response, 'error');
            }
        })
        .catch(error => {
            console.log('Error updateRecord -->' + JSON.stringify(error));
        });
    }
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
                this.newmap.rentalIncome = response[1];
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
    handleInputChange1(event){
    this.newmap.grossSalary = event.target.value;
    }
    handleInputChange2(event){
    this.newmap.totalDeductions = event.target.value;
    }
    handleTotalObligation(event){
    this.newmap.TotalObligation = event.target.value;
    }
    handledocmarkVal(event){
    this.newmap.docmarketVal = event.target.value;
    }
    hanldeFOIR(event){
    this.newmap.additionalFOIR = event.target.value;
    }
    handleRequestedLoanAmt(event){
    this.newmap.finalLoanAmount = event.target.value
    }
    handleRoi(event){
    this.newmap.roi = event.target.value;
    }
    handleTenure(event){
        console.log( 'event.target.value 1099:'+ event.target.value);
    this.newmap.tenor = event.target.value;
    }
    fetchEligibility(){
    console.log('newmap 1100 :'+this.newmap);
    console.log('newmap 1101 :'+ JSON.stringify(this.newmap));
    console.log('recordId 1100 :'+this.recordId);
    this.spinnerRun = true;
fetchProductId({ recordId: this.recordId })
.then(result => {
    console.log('Product Id:', result);  // <-- Do NOT convert to number
    this.productId = result;
    const inputMap = {
    loanId : this.recordId,
    productId :  this.productId,
    productName : 'Home Loan',
    isIncomeFromSales : false,
    processName : 'Credit Eligibility',
    eligibilityType : 'Income Eligibility',
    callForDeviation : true,
    userCalValues: JSON.stringify(this.newmap),
    calculator : this.showCalculator
};
console.log('inputMap: ', JSON.stringify(inputMap));
initiateAPIRequest({
    inputMap:inputMap
})
.then(result => {
    console.log('result 278: ',JSON.stringify(result));
    if(result === 'success'){
        fireEvent(this.pageRef, "refreshEligibility", "Breed-Labrador");
        this.showToast('Success', 'Eligibility feteched successfully!Please check Final Assesment Tab for the result', 'success');
        this.isLoading = false;
        this.spinnerRun = false;
    }
    else{
        this.isLoading = false;
        this.spinnerRun = true;
        this.showToast('Error', 'Error fetching eligbility!', 'error');
    }
})
.catch(error => {
    this.spinnerRun = false;
    console.log('error',error);
    this.isLoading = false;
    this.showToast('Error', 'Error fetching eligbility!', 'error');
})
    
})
}
get getNetAmount() {
    return ((this.newmap.grossSalary - this.newmap.totalDeductions) * 12)
        + this.yearlyComponents.netAmount
        + this.incentiveComponents.netAmount;
}
getTenureProduct(){
    getTenureProduct({
        'loanId' : this.recordId
    })
    .then((response) => {
            this.tenureProduct = response;
            this.netTenure = this.tenureProduct.totalTenure - this.tenureProduct.hybridtenure;
            console.log('tenureProduct :'+JSON.stringify(this.tenureProduct));
            console.log('netTenure :'+this.netTenure);
        })
}
handleHybridTenure(event){
this.tenureProduct.hybridtenure = event.detail.value;
this.netTenure = this.tenureProduct.totalTenure - this.tenureProduct.hybridtenure;
}
handletotalTenure(event){
this.tenureProduct.totalTenure = event.detail.value;
this.netTenure = this.tenureProduct.totalTenure - this.tenureProduct.hybridtenure;
}
getobligations(){
    getObligationsRecords({
      recordId: this.recordId,
      isOneView:'false',
    })
      .then((response) => {
        console.log("obligations details=:" + JSON.stringify(response));
          if(Object.keys(response).length === 0) {
            this.isNoObligationRecordsFound = this.isOneView;
          }
          else{
            console.log('1183');
            this.isNoObligationRecordsFound = false;
            this.allData = response;
            this.recordData = response.lstOblRec;
            this.totalData = response.totalWrap;
            this.newmap.TotalObligation = this.totalData.totalMonthlyObligation;
            this.filteredList = this.recordData;
            var index = 1;
            this.filteredList.forEach((record) => {
              record.srNo = index;
              
              index = index + 1;
            });
            
          }
          console.log('fromSales',this.fromSales);
        this.spinner = false;
      })
      .catch((error) => {});
      console.log('isNoObligationRecordsFound229',this.isNoObligationRecordsFound);
  }
}