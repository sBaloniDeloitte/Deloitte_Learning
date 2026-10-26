import { LightningElement,api,wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import INCOME_ASSESSMENT_OBJECT from '@salesforce/schema/Income_Assessment__c';
import getApplicants from '@salesforce/apex/HL_CashProfitController.getApplicants'; 
import getMerNavyIncomeExpenses from '@salesforce/apex/HL_MerchantNavyController.getMerNavyIncomeExpenses';
import saveSailingIncomeAssessment from '@salesforce/apex/HL_MerchantNavyController.saveSailingIncomeAssessment';
import deleteIncomeAssessment from '@salesforce/apex/HL_MerchantNavyController.deleteIncomeAssessment';
import updateSailingDates from '@salesforce/apex/HL_MerchantNavyController.updateSailingDates'; 
import updateParentSailing from '@salesforce/apex/HL_MerchantNavyController.updateParentSailing';
import saveNRIIncomeExpense from '@salesforce/apex/HL_MerchantNavyController.saveNRIIncomeExpense';  
import updateIncomeAssessment from '@salesforce/apex/HL_MerchantNavyController.updateIncomeAssessment'; 
import deleteIncomeOBligation from '@salesforce/apex/HL_MerchantNavyController.deleteIncomeOBligation';
import deleteIncomeExpencesRec from '@salesforce/apex/HL_MerchantNavyController.deleteIncomeExpences';

export default class Hl_merchantNavyScreenCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    spinnerRun = true;
    recordTypeId;
    applicantList;
    applicants = [];
    applicantIds = [];
    dataLoaded = false;
    _picklistData;
    obligationValues = [];
    incomeValues = [];
    sailingValues = [];
    groupedApplicants = [];
    pendingUncheck = { appId: null, checkboxEl: null };
    confirmationScreen = false;
    currencyOptions = [
        { label: 'INR', value: 'INR' },
        { label: 'Foreign', value: 'Foreign' }
    ];
    currentCurrency = '';
    minNormsOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];
    selectedNorm = '';
    addNewSailingRecord;
    recordType;
    diffInDays;
    fromDate;
    toDate;
    isSingleRecord = false;
    confirmationScreen = false;
    recToBeDeletedForApplicants =[];
    recordIdSelected;
    dateFieldChanged = '';
    minDate;
    maxDate;
    addNewRecord;
    particulars;
    foreignAmt;
    exchangeRate;
    inrAmount;
    exchangeRateDisable;
    slectedRecId;
    incOblConfirmationScreen;
    @wire(getObjectInfo, { objectApiName: INCOME_ASSESSMENT_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            const rtis = data.recordTypeInfos;
            const merchantNavy = Object.values(rtis).find(
                rti => rti.name === 'Merchant Navy' || rti.developerName === 'Merchant_Navy'
            );
            if (merchantNavy) {
                this.recordTypeId = merchantNavy.recordTypeId;
            } else {
                console.error('Merchant Navy Record Type not found');
            }
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getPicklistValuesByRecordType,{ objectApiName: INCOME_ASSESSMENT_OBJECT, recordTypeId: '$recordTypeId' })
    picklistHandler({ data, error }) {
        if (data) {
            this._picklistData = data;
            console.log('data => ', data);
            const controllerMap = data.picklistFieldValues.Particulars__c.controllerValues;
            const particulars = data.picklistFieldValues.Particulars__c.values;
            console.log('controllerMap => ', controllerMap);
            console.log('particulars => ', particulars);
            const incomeIndex = controllerMap['Income'];
            const obligationIndex = controllerMap['Obligations'];
            const sailingIndex = controllerMap['Sailings'];
            console.log('incomeIndex => ', incomeIndex);
            console.log('obligationIndex => ', obligationIndex);
            console.log('sailingIndex => ', sailingIndex);
            this.incomeValues = particulars.filter(v => v.validFor.includes(incomeIndex)).map(v => v.value);
            this.obligationValues = particulars.filter(v => v.validFor.includes(obligationIndex)).map(v => v.value);
            this.sailingValues = particulars.filter(v => v.validFor.includes(sailingIndex)).map(v => v.value);
            console.log('Income dependent values => ', this.incomeValues);
            console.log('Obligations dependent values => ', this.obligationValues);
            console.log('sailingValues dependent values => ', this.sailingValues);
        } else if (error) {
            console.error('get picklist'+error);
        }
    }
    
    getIncomeValues() {
        return this.incomeValues;
    }
    
    getObligationValues() {
        return this.obligationValues;
    }

    connectedCallback(){
        console.log('Merchant_Navy_screen_cmp this.recordId: ' + this.recordId);
        const today = new Date();
        this.maxDate = today.toISOString().slice(0, 10); // Today's date in YYYY-MM-DD format
        const futureDate = new Date();
        futureDate.setDate(today.getDate() - 730); // 2 years from today
        this.minDate = futureDate.toISOString().slice(0, 10); 
        setTimeout(() => {
            this.getApplicantsOne();
        }, 500);
    }

    renderedCallback() {
        if (!this.isDarkThemeInjected) {
            this.isDarkThemeInjected = true;
            this.injectDarkThemeStyles();
        }
    }

    injectDarkThemeStyles() {
        const style = document.createElement('style');
        style.innerText = `
            .slds-dropdown,
            .slds-dropdown__list,
            .slds-listbox_vertical {
                background-color: #16283f !important;
                border-color: #33455e !important;
            }
            .slds-listbox__option,
            .slds-listbox__item {
                background-color: #16283f !important;
                color: #ffffff !important;
            }
            .slds-listbox__option:hover,
            .slds-listbox__option:focus,
            .slds-listbox__option.slds-has-focus,
            .slds-listbox__option[aria-selected="true"] {
                background-color: #1589ee !important;
                color: #ffffff !important;
            }
            .slds-select,
            .slds-combobox__input {
                background-color: #16283f !important;
                border: 1px solid #33455e !important;
                color: #ffffff !important;
                height: 2.25rem !important;
            }
        `;
        this.template.querySelector('.styleContainer')?.appendChild(style);
    }

    getApplicantsOne(){
        getApplicants({
            loanId: this.recordId,
            recordTypeName: 'Merchant Navy'
        }).then(response=>{
            this.applicantList = response;
            console.log('this.applicantList: ' + JSON.stringify(this.applicantList));
            this.dataLoaded = true;
            this.applicantIds = this.applicantList.filter(item => item.isDataCreated === true).map(item => item.appId);
            console.log('this.applicantIds: ' + JSON.stringify(this.applicantIds));
            setTimeout(() => {
                this.getIncomeExpenses();
            }, 100);
        }).catch(error=>{
            console.error('getMerchantNavyApplicants error: ' + JSON.stringify(error));
        })
    }
    handleCheckboxChange(event){
        this.spinnerRun = true;
        console.log('event.target.dataset.id: ' + event.target.dataset.id);
        const appId = event.target.dataset.id
        const isChecked = event.target.checked;
        if (isChecked) {
            if (!this.applicantIds.includes(appId)) {
                this.applicantIds.push(appId);
                this.getIncomeExpenses();
                setTimeout(() => {
                    this.dispatchEvent(
                        new CustomEvent('incomeexpenceschanged', {
                            detail: { 
                                change: 'Income Assessment Checked'
                            },
                        })
                    );
                }, 500);
            }
        }
        else{
            console.log('this.applicantIds: ' + JSON.stringify(this.applicantIds));
            console.log('this.recToBeDeletedForApplicants:'+this.recToBeDeletedForApplicants);
            this.spinnerRun = false; 
            this.pendingUncheck = { appId, checkboxEl: event.target };
            this.incOblConfirmationScreen = true;
        }
    }

    getIncomeExpenses() {
        console.log('this.incomeValues ii: ' + this.incomeValues);
        console.log('this.obligationValues ii: ' + this.obligationValues);
        getMerNavyIncomeExpenses({
            loanId: this.recordId,
            applicantIds: this.applicantIds,
            incomeValues: this.incomeValues,
            obligationValues: this.obligationValues,
            sailingValues: this.sailingValues
        })
        .then(result => {
            console.log('getMernavyIncomeExpences result: ' + JSON.stringify(result));
            const mapByApplicant = {};

            result.forEach(rec => {
                if (!mapByApplicant[rec.applicantId]) {
                    mapByApplicant[rec.applicantId] = {
                        applicantId: rec.applicantId,
                        applicantName: rec.applicantName,
                        incomes: [],
                        obligations: [],
                        sailings:[]
                    };
                }

                const recWithFlag = { 
                    ...rec, 
                    isEditing: false,
                    isParent: rec.parentOrChild === 'Parent'
                };

                let bucket;
                if (rec.typeOfAssessment === 'Income') {
                    bucket = mapByApplicant[rec.applicantId].incomes;
                } else if (rec.typeOfAssessment === 'Obligations') {
                    bucket = mapByApplicant[rec.applicantId].obligations;
                }
                else if (rec.typeOfAssessment === 'Sailings'){
                    bucket = mapByApplicant[rec.applicantId].sailings;
                    console.log('BUCKET ITEMS');
                console.log(bucket);
                }
                console.log('BUCKET ITEMS');
                console.log(bucket);

                if (bucket) {
                    if (recWithFlag.isParent) {
                        bucket.push(recWithFlag);
                    } else {
                        bucket.unshift(recWithFlag);
                    }
                }
            });

            this.groupedApplicants = Object.values(mapByApplicant);
            console.log('getMernavyIncomeExpences :: groupedApplicants:Before::  ' + JSON.stringify(this.groupedApplicants));
            
            this.groupedApplicants = this.groupedApplicants.map(applicant => ({
                ...applicant,
                incomes: applicant.incomes.map(inc => ({
                    ...inc,
                    isDisabled: inc.exchangeRate === 1 || inc.isParent,
                    currencyType: inc.exchangeRate === 1 ? 'INR' : 'Foreign'
                })),
                obligations: applicant.obligations.map(obl => ({
                    ...obl,
                    isDisabled: obl.exchangeRate === 1 || obl.isParent,
                    currencyType: obl.exchangeRate === 1 ? 'INR' : 'Foreign'
                })),
                sailings: applicant.sailings.map(sal => ({
                    ...sal,
                    normsMet: sal.minIncomeNormsMet === 'Yes' ? 'Yes' : 'No'
                }))
            }));
            console.log('getMerchantNavyIncomeExpences :: groupedApplicants: : After::' + JSON.stringify(this.groupedApplicants));
            this.spinnerRun = false;
        })
        .catch(error => {
            this.spinnerRun = false;
            console.error('getNRIIncomeExpences error: ' + JSON.stringify(error));
        });
    }

    handleForeignAmtChange(event) {
        const recId = event.target.dataset.id;
        this.slectedRecId = recId;
        const val = parseFloat(event.target.value || 0);
        this.updateField(recId, 'foreignAmt', val);
        this.recalcInr(recId);
        setTimeout(() => {
            this.handleSave();
        }, 500);
    }

    recalcInr(recId) {
        console.log('REACHED HERE');
        this.groupedApplicants = this.groupedApplicants.map(app => {
            ['incomes','obligations'].forEach(type => {
                app[type] = app[type].map(r => {
                    if (r.incomeAssessmentId === recId) {
                        const inr = (r.foreignAmt || 0) * (r.exchangeRate || 0);
                        return { ...r, inrAmt: inr };
                    }
                    return r;
                });
            });
            return app;
        });
    }

    handleCurrencyChange(event){
        console.log('handleCurrencyChange val : ' + event.target.value);
        this.currentCurrency = event.target.value;
        console.log('handleCurrencyChange currentCurrency : ' + this.currentCurrency);
        let value;
        if(this.currentCurrency == 'INR'){
            value = 1;
        }else{
            value = 0;
        }
        const recId = event.target.dataset.id;
        this.slectedRecId = recId;
        this.updateField(recId, 'exchangeRate', value);
        this.recalcInr(recId);
        setTimeout(() => {
            this.handleSave();
        }, 500);
    }
    handleExchangeRateChange(event) {
        const recId = event.target.dataset.id;
        this.slectedRecId = recId;
        const val = parseFloat(event.target.value || 0);
        this.updateField(recId, 'exchangeRate', val);
        this.recalcInr(recId);
        setTimeout(() => {
            this.handleSave();
        }, 500);
    }
    handleInrAmtChange(event) {
        // to filled if disablity removed
    }
    
    addNewSailingRec(event) {
        this.selectedApplicant = event.target.dataset.id;
        this.recordType = 'Sailings';
        this.addNewSailingRecord = true;
    }

    addNewIncomeRecord(event) {
        
        this.selectedApplicant = event.target.dataset.id;
        this.recordType = 'Income';
        this.addNewRecord = true;
        
    }
    
    addNewObligationRecord(event) {
        
        this.selectedApplicant = event.target.dataset.id;
        this.recordType = 'Obligations';
        this.addNewRecord = true;
        
    }

    handleInputChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        if (field === 'recordType') {
            this.particulars = value;
        } else if (field === 'foreignAmout') {
            this.foreignAmt = Number(value);
        } else if (field === 'exchangeRate') {
            this.exchangeRate = Number(value);
        }
        if (field === 'foreignAmout' || field === 'exchangeRate') {
            this.inrAmount = (Number(this.foreignAmt) || 0) * (Number(this.exchangeRate) || 0);
        }
        if (field === 'currentCurrency') {
            this.currentCurrency = value;
            if(value== 'INR'){
                this.exchangeRate = 1;
                this.inrAmount = (Number(this.foreignAmt) || 0) * 1;
                this.exchangeRateDisable = true;
            } else{
                this.exchangeRateDisable = false;
                this.exchangeRate = 0;
            }
        }
    }

    onClickModalSave() {
        if (!this.particulars) {
            alert('Please enter all required fields.');
            return;
        }

        const payload = {
            applicantId: this.selectedApplicant,
            loanId: this.recordId,
            typeOfAssessment: this.recordType,
            particular: this.particulars,
            foreignAmt: this.foreignAmt,
            exchangeRate: this.exchangeRate,
            inrAmt: this.inrAmount
        };

        saveNRIIncomeExpense({ recordData: payload })
            .then(() => {
                this.dispatchEvent(
                    new CustomEvent('recordadded', { detail: payload })
                );
                this.closeAddModal();
            })
            .catch(err => {
                console.error('Error saving record', err);
            });
    }

    closeAddModal() {
        this.resetForm();
        this.addNewRecord = false;
    }

    resetForm() {
        this.selectedApplicant = '';
        this.recordType = '';
        this.particulars = '';
        this.foreignAmt = 0;
        this.exchangeRate = 0;
        this.inrAmount = 0;
        this.getIncomeExpenses();
    }

    handleSailingInputChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        if (field === 'recordType') {
            this.particulars = value;
        } 
        else if (field === 'fromDate') {
            this.fromDate = value;
        } 
        else if (field === 'toDate') {
            this.toDate = value;
        }
        console.log('----------------'+this.fromDate);
        console.log('----------------'+this.toDate);
        if (field === 'fromDate' || field === 'toDate') {
            if (this.fromDate > this.toDate) {
                alert('To date should be greater than from date.');
                //this.fromDate = '';
                //this.toDate = '';
                //this.diffInDays = 0;
            }
            const diffInMs = Math.abs(new Date(this.toDate) - new Date(this.fromDate));
            console.log('diffInMs :  '+diffInMs);
            console.log('this.fromDate :  '+this.fromDate);
            console.log('this.toDate :  '+this.toDate);
            this.diffInDays = Math.ceil(diffInMs / (1000 * 60 * 60 * 24));
            console.log('this.selectedApplicant :  '+this.diffInDays);
        }
    }

    onClickSailingModalSave() {
        
        if (this.fromDate == null || this.toDate == null) {
            alert('Please enter all required fields.');
            return;
        }

        const payload = {
            applicantId: this.selectedApplicant,
            loanId: this.recordId,
            typeOfAssessment: this.recordType,
            particular: this.particulars,
            fromDate: this.fromDate,
            toDate: this.toDate,
            diffInDays: this.diffInDays
        };
        console.log('payload: '+JSON.stringify(payload));
        saveSailingIncomeAssessment({ recordData: payload })
            .then(() => {
                this.dispatchEvent(
                    new CustomEvent('recordadded', { detail: payload })
                );
                this.closeAddSailingModal();
            })
            .catch(err => {
                console.error('Error saving record', err);
            });
    }

    closeAddSailingModal() {
        this.resetSailingForm();
        this.addNewSailingRecord = false;
    }
    
    resetSailingForm() {
        this.selectedApplicant = '';
        this.recordType = '';
        this.particulars = '';
        this.fromDate = '';
        this.toDate = '';
        this.diffInDays = 0;
        this.getIncomeExpenses();
    }

    handleDelete(event) {
        this.recordIdSelected = event.target.dataset.id;
        this.isSingleRecord = true;
        this.confirmationScreen = true;
    }

    handleIncOblDelete(event) {
        this.recordIdSelected = event.target.dataset.id;
        this.isSingleRecord = true;
        this.incOblConfirmationScreen = true;
    }

    onClickIncOblModalNo() {
        if (this.pendingUncheck.checkboxEl) {
            this.pendingUncheck.checkboxEl.checked = true;
        }

        this.incOblConfirmationScreen = false;
        this.pendingUncheck = { appId: null, checkboxEl: null };
        this.recToBeDeletedForApplicants = [];
        this.spinnerRun = false;
        this.recordIdSelected = '';
        this.isSingleRecord = false;
    }

    onClickIncOblModalYes(){
        this.spinnerRun = true;
        const { appId } = this.pendingUncheck;
        this.applicantIds = this.applicantIds.filter(id => id !== appId);
        this.recToBeDeletedForApplicants.push(appId);

        this.incOblConfirmationScreen = false;
        this.pendingUncheck = { appId: null, checkboxEl: null };
        console.log('this.isSingleRecord: '+this.isSingleRecord);
        if (this.isSingleRecord != true) {
            this.deleteIncomeExpences();
        }else{
           this.deleteIncOblRec(); 
        }
    }

    deleteIncOblRec() {
        this.spinnerRun = false;
        const recordId = this.recordIdSelected;
        deleteIncomeOBligation({ recordId })
        .then(() => {
            this.recordIdSelected = '';
            this.groupedApplicants = this.groupedApplicants.map(app => {
                return {
                    ...app,
                    incomes: app.incomes.filter(r => r.incomeAssessmentId !== recordId),
                    obligations: app.obligations.filter(r => r.incomeAssessmentId !== recordId)
                    //sailings: app.sailings.filter(r => r.incomeAssessmentId !== recordId)
                };
            });
            console.log(JSON.stringify(this.groupedApplicants));
        })
        .catch(err => {
            console.error('Delete error: ', err);
        });
    }
    
    removeValue(valueToRemove) {
        console.log('MUHAHAHAHAHAHA'); 
        console.log('MUHAHAHAHAHAHA'+valueToRemove);
        const incomeIndex = this.incomeValues.indexOf(valueToRemove);
        const obligationIndex = this.obligationValues.indexOf(valueToRemove);
        
        if (incomeIndex !== -1) {
            this.incomeValues.splice(incomeIndex, 1);
        }

        if (obligationIndex !== -1) {
            this.obligationValues.splice(obligationIndex, 1);
        }
    }

    onClickModalYes(){
        this.spinnerRun = true;
        const { appId } = this.pendingUncheck;
        this.applicantIds = this.applicantIds.filter(id => id !== appId);
        this.recToBeDeletedForApplicants.push(appId);

        this.confirmationScreen = false;
        this.pendingUncheck = { appId: null, checkboxEl: null };
        if (this.isSingleRecord != true) {
            //
        }else{
           this.deleteIncomeAssRec(); 
        }
    }

    deleteIncomeExpences(){
        deleteIncomeExpencesRec({
            loanId: this.recordId,
            applicantIds: this.recToBeDeletedForApplicants
        }).then(result => {
            this.getIncomeExpenses();
            this.spinnerRun = false;
            this.recToBeDeletedForApplicants = [];
            
            this.dispatchEvent(
                new CustomEvent('incomeexpenceschanged', {
                    detail: { 
                        change: 'Income Assessment Deleted'
                    },
                })
            );
        }).catch(error => {
            this.spinnerRun = false;
            console.error('deleteIncomeExpences error: ' + JSON.stringify(error));
        });
    }

    deleteIncomeAssRec() {
        this.spinnerRun = false;
        const recordId = this.recordIdSelected;
        deleteIncomeAssessment({ recordId })
        .then(() => {
            this.recordIdSelected = '';
            this.groupedApplicants = this.groupedApplicants.map(app => {
                return {
                    ...app,
                    incomes: app.incomes.filter(r => r.incomeAssessmentId !== recordId),
                    obligations: app.obligations.filter(r => r.incomeAssessmentId !== recordId),
                    sailings: app.sailings.filter(r => r.incomeAssessmentId !== recordId)
                };
            });
            this.getIncomeExpenses();
        })
        .catch(err => {
            this.spinnerRun = false;
            console.error('Delete error: ', err);
        });
    }

    onClickModalNo(){
        if (this.pendingUncheck.checkboxEl) {
            this.pendingUncheck.checkboxEl.checked = true;
        }

        this.confirmationScreen = false;
        this.pendingUncheck = { appId: null, checkboxEl: null };
        this.recToBeDeletedForApplicants = [];
        this.spinnerRun = false;
        this.recordIdSelected = '';
        this.isSingleRecord = false;
    }

    handleSailingDateChange(event) {
        const recId = event.target.dataset.id;
        this.slectedRecId = recId;
        const val = event.target.value;
        this.dateFieldChanged = event.target.name;
        if(val<this.minDate) {
            event.target.setCustomValidity('Please select a date within the allowed range.');
        }
        if(val>this.maxDate) {
            event.target.setCustomValidity('Please select a date within the allowed range.');
        }
        else {
            event.target.setCustomValidity('');
            this.updateField(recId, this.dateFieldChanged, val);
            this.recalcDiffInDays(recId);
            setTimeout(() => {
                this.handleSailingSave();
            }, 500);
        }
    }

    recalcDiffInDays(recId) {
        this.groupedApplicants = this.groupedApplicants.map(app => {
            ['incomes','obligations','sailings'].forEach(type => {
                app[type] = app[type].map(r => {
                    if (r.incomeAssessmentId === recId) {
                        const diffInMs = Math.abs(new Date(r.toDate) - new Date(r.fromDate));
                        const diffInDaysCalc = Math.ceil(diffInMs / (1000 * 60 * 60 * 24));
                        return { ...r, diffInDays: diffInDaysCalc };
                    }
                    return r;
                });
            });
            return app;
        });
    }
    
    updateField(recId, field, value) {
        this.groupedApplicants = this.groupedApplicants.map(app => {
            ['incomes','obligations','sailings'].forEach(type => {
                app[type] = app[type].map(r =>
                    r.incomeAssessmentId === recId ? { ...r, [field]: value } : r
                );
            });
            return app;
        });
    }

    handleSailingSave(event) {
        const recId =this.slectedRecId;
        const rec = this.findRecord(recId);
        console.log(JSON.stringify(rec));
        if (!rec) return;
        this.spinnerRun = true;
        let dateFieldType = '';
        let dateFieldVar = '';

        
        
        if(this.dateFieldChanged == 'fromDate') {
            dateFieldVar = rec.fromDate;
            dateFieldType = 'fromDate';
        } else {
            dateFieldVar = rec.toDate;
            dateFieldType = 'toDate';
        }
        updateSailingDates({
            recordId: recId,
            dateType: dateFieldType,
            dateValue: dateFieldVar,
            diffDays: rec.diffInDays
        })
        .then(() => {
            this.toggleEditing(recId, false);
            this.getIncomeExpenses();
            this.spinnerRun = false;
            this.dateFieldChanged = '';
        })
        .catch(err => {
            console.error('Update error: ' + JSON.stringify(err));
            this.spinnerRun = false;
        });
    }

    handleSave(event) {
        const recId =this.slectedRecId; // = event.target.dataset.id;
        const rec = this.findRecord(recId);
        if (!rec) return;
        this.spinnerRun = true;
        updateIncomeAssessment({
            recordId: recId,
            foreignAmt: rec.foreignAmt,
            exchangeRate: rec.exchangeRate,
            inrAmt: rec.inrAmt
        })
        .then(() => {
            this.toggleEditing(recId, false);
            this.getIncomeExpenses();
            this.spinnerRun = false;
        })
        .catch(err => {
            console.error('Update error: ' + JSON.stringify(err));
            this.spinnerRun = false;
        });
    }

    findRecord(recId) {
        for (const app of this.groupedApplicants) {
            const inc = app.incomes.find(r => r.incomeAssessmentId === recId);
            if (inc) return inc;
            const obl = app.obligations.find(r => r.incomeAssessmentId === recId);
            if (obl) return obl;
            const sail = app.sailings.find(r => r.incomeAssessmentId === recId);
            if (sail) return sail;
        }
        return null;
    }

    toggleEditing(recId, val) {
        this.groupedApplicants = this.groupedApplicants.map(app => {
            return {
                ...app,
                incomes: app.incomes.map(r =>
                    r.incomeAssessmentId === recId ? { ...r, isEditing: val } : r
                ),
                obligations: app.obligations.map(r =>
                    r.incomeAssessmentId === recId ? { ...r, isEditing: val } : r
                ),
                sailings: app.sailings.map(r =>
                    r.incomeAssessmentId === recId ? { ...r, isEditing: val } : r
                )
            };
        });
        this.spinnerRun = false;
    }

    handleNormChange(event) {
        this.selectedNorm = event.detail.value;
        const recId = event.target.dataset.id;
        this.slectedRecId = recId;
        this.updateField(recId, 'normsMet', this.selectedNorm);
        setTimeout(() => {
            this.handlesailingParentSave();
        }, 500);
    }

    handleSailingParentChange(event) {
        const recId = event.target.dataset.id;
        this.slectedRecId = recId;
        const val = event.target.value;
        const fieldName = event.target.name;
        this.updateField(recId,fieldName, val);
        this.recalcMNR(recId);
        setTimeout(() => {
            this.handlesailingParentSave();
        }, 500);
    }

    recalcMNR(recId) {
        this.groupedApplicants = this.groupedApplicants.map(app => {
            ['incomes','obligations','sailings'].forEach(type => {
                app[type] = app[type].map(r => {
                    if (r.incomeAssessmentId === recId && r.monthlyGrossRenumeration != null && r.monthlyRenumerationDeductions != null) {
                        const mnr = (r.monthlyGrossRenumeration - r.monthlyRenumerationDeductions);
                        return { ...r, monthlyNetRenumeration: mnr };
                    }
                    return r;
                });
            });
            return app;
        });
    }

    handlesailingParentSave(event) {
        const recId =this.slectedRecId;
        const rec = this.findRecord(recId);
        if (!rec) return;
        this.spinnerRun = true;
        updateParentSailing({
            recordId: recId,
            nriCountry: rec.nriCountry,
            nriCurrency: rec.nriCurrency,
            minIncomeNormsMet: this.selectedNorm,
            monthlyGrossRenumeration: rec.monthlyGrossRenumeration,
            monthlyRenumerationDeductions: rec.monthlyRenumerationDeductions,
            monthlyNetRenumeration: rec.monthlyNetRenumeration
        })
        .then(() => {
            this.toggleEditing(recId, false);
            this.getIncomeExpenses();
            this.spinnerRun = false;
            this.dateFieldChanged = '';
        })
        .catch(err => {
            console.error('Update error: ' + JSON.stringify(err));
            this.spinnerRun = false;
        });
    }
}