import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import INCOME_ASSESSMENT_OBJECT from '@salesforce/schema/Income_Assessment__c';
import getNRIIncomeExpences from '@salesforce/apex/HL_SalariedScreenController.getNRIIncomeExpences';
import updateIncomeAssessment from '@salesforce/apex/HL_SalariedScreenController.updateIncomeAssessment';
import saveNRIIncomeExpense from '@salesforce/apex/HL_SalariedScreenController.saveNRIIncomeExpense';
import deleteIncomeAssessment from '@salesforce/apex/HL_SalariedScreenController.deleteIncomeAssessment';
import getApplicants from '@salesforce/apex/HL_CashProfitController.getApplicants';
import deleteIncomeExpences from '@salesforce/apex/HL_SalariedScreenController.deleteIncomeExpences';
export default class Hl_salariedNRIScreenCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    spinnerRun = true;
    applicants = [];
    applicantIds = [];
    recordTypeId;
    _picklistData;
    obligationValues = [];
    incomeValues = [];
    groupedApplicants = [];
    recordType;
    addNewRecord;
    selectedApplicant;
    particulars;
    foreignAmt;
    exchangeRate;
    inrAmount;
    applicantList;
    tabList;
    recToBeDeletedForApplicants =[];
    dataLoaded = false;
    showTab = false;
    slectedRecId;
    confirmationScreen = false;
    pendingUncheck = { appId: null, checkboxEl: null };
    isSingleRecord = false;
    recordIdSelected;

    @wire(getObjectInfo, { objectApiName: INCOME_ASSESSMENT_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            const rtis = data.recordTypeInfos;
            const salariedNRI = Object.values(rtis).find(
                rti => rti.name === 'Salaried NRI' || rti.developerName === 'Salaried_NRI'
            );
            if (salariedNRI) {
                this.recordTypeId = salariedNRI.recordTypeId;
            } else {
                console.error('Salaried NRI record type not found');
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
            console.log('incomeIndex => ', incomeIndex);
            console.log('obligationIndex => ', obligationIndex);
            this.incomeValues = particulars.filter(v => v.validFor.includes(incomeIndex)).map(v => v.value);
            this.obligationValues = particulars.filter(v => v.validFor.includes(obligationIndex)).map(v => v.value);
            console.log('Income dependent values => ', this.incomeValues);
            console.log('Obligations dependent values => ', this.obligationValues);
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
        console.log('hl_salaried__n_r_i_screen_cmp this.recordId: ' + this.recordId);
        setTimeout(() => {
            this.getApplicantsOne();
        }, 500);
    }

    getApplicantsOne(){
        getApplicants({
            loanId: this.recordId,
            recordTypeName: 'Salaried NRI'
        }).then(response=>{
            this.applicantList = response;
            console.log('this.applicantList: ' + JSON.stringify(this.applicantList));
            this.dataLoaded = true;
            this.applicantIds = this.applicantList.filter(item => item.isDataCreated === true).map(item => item.appId);
            console.log('this.applicantIds: ' + JSON.stringify(this.applicantIds));
            setTimeout(() => {
                this.getIncomeExpences();
            }, 100);
        }).catch(error=>{
            console.error('getNRIApplicants error: ' + JSON.stringify(error));
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
                this.getIncomeExpences();
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
            // this.applicantIds = this.applicantIds.filter(id => id !== appId);
            // this.recToBeDeletedForApplicants.push(appId);
            console.log('this.applicantIds: ' + JSON.stringify(this.applicantIds));
            console.log('this.recToBeDeletedForApplicants:'+this.recToBeDeletedForApplicants);
            // setTimeout(() => {
            //     if(this.recToBeDeletedForApplicants.length>0){
            //         this.deleteIncomeExpences();
            //     }
            // }, 100);
            this.spinnerRun = false; 
            this.pendingUncheck = { appId, checkboxEl: event.target };
            this.confirmationScreen = true;
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
            this.deleteIncomeExpences();
        }else{
           this.deleteIncomeAssRec(); 
        }
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

    deleteIncomeExpences(){
        deleteIncomeExpences({
            loanId: this.recordId,
            applicantIds: this.recToBeDeletedForApplicants
        }).then(result => {
            this.getIncomeExpences();
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
                    obligations: app.obligations.filter(r => r.incomeAssessmentId !== recordId)
                };
            });
            // this.fireIncomeExpencesLoaded();
        })
        .catch(err => {
            console.error('Delete error: ', err);
        });
    }

    getIncomeExpences() {
        console.log('this.incomeValues:', this.incomeValues);
        console.log('this.obligationValues:', this.obligationValues);
        this.spinnerRun = true;
        getNRIIncomeExpences({
            loanId: this.recordId,
            applicantIds: this.applicantIds,
            incomeValues: this.incomeValues,
            obligationValues: this.obligationValues
        })
        .then(result => {
            console.log('getNRIIncomeExpences result:', JSON.stringify(result));
            const mapByApplicant = {};
            result.forEach(rec => {
                const applicantId = rec.applicantId;
                if (!mapByApplicant[applicantId]) {
                    mapByApplicant[applicantId] = {
                        applicantId: applicantId,
                        applicantName: rec.applicantName,
                        incomes: [],
                        obligations: []
                    };
                }
                const recWithFlag = { 
                    ...JSON.parse(JSON.stringify(rec)),
                    isEditing: false,
                    isParent: rec.parentOrChild === 'Parent'
                };
                if (rec.typeOfAssessment === 'Income') {
                    if (recWithFlag.isParent) {
                        mapByApplicant[applicantId].incomes.push(recWithFlag);
                    } else {
                        mapByApplicant[applicantId].incomes.unshift(recWithFlag);
                    }
                } 
                else if (rec.typeOfAssessment === 'Obligations') {
                    if (recWithFlag.isParent) {
                        mapByApplicant[applicantId].obligations.push(recWithFlag);
                    } else {
                        mapByApplicant[applicantId].obligations.unshift(recWithFlag);
                    }
                }
            });
            this.groupedApplicants = Object.values(mapByApplicant);
            this.spinnerRun = false;
            console.log('Final groupedApplicants:', JSON.stringify(this.groupedApplicants, null, 2));
        })
        .catch(error => {
            this.spinnerRun = false;
            console.error('getNRIIncomeExpences error:', JSON.stringify(error));
        });
    }

    // fireIncomeExpencesLoaded() {
    //     try{
    //     const event = new CustomEvent('incomeexpencesloaded', {
    //         detail: { groupedApplicants: this.groupedApplicants },
    //         bubbles: true,
    //         composed: true
    //     });
    //     this.dispatchEvent(event);
    //     } catch(ex) {
    //         console.error('Error in fireIncomeExpencesLoaded: '+ex);
    //     }
    // }


    handleEdit(event) {
        const recId = event.target.dataset.id;
        this.spinnerRun = true;
        console.log('Edit recId: '+recId);
        this.toggleEditing(recId, true);
    }

    cancelEdit(event) {
        const recId = event.target.dataset.id;
        this.toggleEditing(recId, false);
        this.getIncomeExpences();
    }

    toggleEditing(recId, val) {
        console.log('toggleEditing recId : '+recId);
        console.log('toggleEditing val : '+val);
        this.groupedApplicants = this.groupedApplicants.map(app => {
            return {
                ...app,
                incomes: app.incomes.map(r =>
                    r.incomeAssessmentId === recId ? { ...r, isEditing: val } : r
                ),
                obligations: app.obligations.map(r =>
                    r.incomeAssessmentId === recId ? { ...r, isEditing: val } : r
                )
            };
        });
        this.spinnerRun = false;
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

    recalcInr(recId) {
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

    updateField(recId, field, value) {
        this.groupedApplicants = this.groupedApplicants.map(app => {
            ['incomes','obligations'].forEach(type => {
                app[type] = app[type].map(r =>
                    r.incomeAssessmentId === recId ? { ...r, [field]: value } : r
                );
            });
            return app;
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
            this.getIncomeExpences();
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
        }
        return null;
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

    closeAddModal() {
        this.resetForm();
        this.addNewRecord = false;
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
    }

    onClickModalSave() {
        console.log('this.particulars : '+this.particulars);
        console.log('this.recordType : '+this.recordType);
        console.log('this.selectedApplicant :  '+this.selectedApplicant);
        
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
    resetForm() {
        this.selectedApplicant = '';
        this.recordType = '';
        this.particulars = '';
        this.foreignAmt = 0;
        this.exchangeRate = 0;
        this.inrAmount = 0;
        this.getIncomeExpences();
    }

    handleDelete(event) {
        this.recordIdSelected = event.target.dataset.id;
        // if (!recordId) return;
        // if (!confirm('Are you sure you want to delete this record?')) {
        //     return;
        // }
        this.isSingleRecord = true;
        this.confirmationScreen = true;
    }
}