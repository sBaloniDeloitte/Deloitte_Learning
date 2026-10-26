import { LightningElement,api,track,wire } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getLiveLoanData from "@salesforce/apex/BsaSelectBankController.getAllBankRecords";
import getCollateralRecordsByLoanAppId from '@salesforce/apex/COMM_SalesCollateralDetailsController.getCollateralRecordsByLoanAppId';
import fetchAllProducts from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.fetchAllProducts';
import deleteApplicant from '@salesforce/apex/COMM_SalesCollateralDetailsController.deleteApplicant';
import PRODUCT_TYPE from '@salesforce/schema/Opportunity.Product__c';
import { getRecord } from 'lightning/uiRecordApi';
import getBuilderSellerApplicants from '@salesforce/apex/COMM_SalesCollateralDetailsController.getBuilderSellerApplicants';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
export default class SalesLoginBuilderSellerDetails extends LightningElement {
    formFactor = FORM_FACTOR;
    deviceType;
    @api isSeller;
    @api recordId;
    @api activeSection;
    currentSection;
    @api passedScreenName ='Builder Details';
    @api formName;
    @api loginChecklist;
    isRendered = false;
    @track applicantsList = [];
    @track hasApplicants = false;
    @track applicantId = null;
    stages = [];
    rerenderCmp;
    isloading = false;
    showAddressAndBank = true;
    showAddress = false;
    showBank = false;
    @track products;
    @track collateralList;
    displayMessage;
    showDisplayMessage = false;
    isReady = false;
    

    handleDelete(event) {
        const recordId = event.target.dataset.id;

        const confirmDelete = window.confirm('Are you sure you want to delete this record?');
        if (!confirmDelete) {
            return;
        }

        deleteApplicant({ applicantId: recordId })
            .then(() => {
                this.showToast('Success', 'Record deleted successfully', 'success');
                this.loadApplicants();
            })
            .catch(error => {
                console.error('Error deleting applicant:', error);
                this.showToast('Error', 'Failed to delete record', 'error');
            });
    }

    async connectedCallback() {
        try {
        console.log('this.recordId-->' + this.recordId);
        await this.loadApplicants();

        // Always show address and bank from the start for both Builder and Seller
            this.showAddress = true;
            this.showBank = true;
        this.showAddressAndBank = true;

        console.log('this.formName-->' + this.formName);
        console.log('loginChecklist in income----', this.loginChecklist);

        await this.fetchAllProducts();
        await this.getCollateral();

        const hasBuilderPurchase = this.products?.some(prod => prod.subProdName === 'HL Builder Purchase' || prod.subProdName != '');
        const hasResalePurchase = this.products?.some(prod => prod.subProdName === 'HL Resale Purchase' || prod.subProdName === 'NHL Commercial Purchase');

        console.log('hasBuilderPurchase>', hasBuilderPurchase);
        console.log('hasResalePurchase>', hasResalePurchase);

        /*if (!hasBuilderPurchase && this.passedScreenName == 'Builder Details') {
            this.displayMessage = 'Builder Details is not applicable for this Loan Application';
            this.showDisplayMessage = true;
        }*/
       
        if (/*! commented by Kunal Bisht*/hasResalePurchase && this.passedScreenName == 'Seller Details') {
            this.displayMessage = 'Seller Details is not applicable for this Loan Application';
            this.showDisplayMessage = true;
        }

        if (this.formName == undefined) {
            this.formName = this.passedScreenName == 'Builder Details' ? 'Builder Details' : 'Seller Details';
        }
        if (this.activeSection == undefined) {
            this.activeSection = { "applicableFor": "Both", "name": this.passedScreenName };
        }

        console.log('this.formName in income--->' + this.formName);
        console.log('this.activeSection--->' + JSON.stringify(this.activeSection));

        this.rerenderCmp = false;
        setTimeout(() => { }, 100);

        this.isloading = true;
        setTimeout(() => {
            this.isloading = false;
        }, 2000);
        } catch (error) {
            console.error('Error in connectedCallback:', error);
            this.displayMessage = 'Something went wrong';
            this.showDisplayMessage = true;
        } finally {
            this.isReady = true;
            console.log('FINAL VALUES →', {
            passedScreenName: this.passedScreenName,
            formName: this.formName,
            activeSection: this.activeSection,
            showDisplayMessage: this.showDisplayMessage
        });
        }
    }
  /*  getSubStageListSubAccordian() {
        console.log('Inside getSub again');
        getSubStageListSubAccordian({
            loanId : this.recordId,
            applicableStage : this.passedScreenName,
            formName : this.formName
        })
        .then(response => {
            this.rerenderCmp = false;
            console.log('Substage response:27---', response);
            this.stages = response;
            console.log('Substage  this.stages: 30',  this.stages); 
            console.log('39----',JSON.stringify(this.activeSection));
            if(this.activeSection!='' && this.activeSection!=null  && this.activeSection!=undefined){
                console.log('Substage  this.stages: 40',  this.stages);
                for(let i =0; i<this.stages.length; i++){
                    if(this.stages[i].name === this.activeSection.name){
                        this.activeSection=this.stages[i] ; 
                        this.currentSection = this.stages[i].name;
                        this.passedScreenName = this.stages[i].name;
                        this.rerenderCmp = true;
                    }
                }
            }else{
                console.log('Substage  this.stages: 52',  this.stages);
                this.rerenderCmp = true;
                this.currentSection = this.stages[0].name;
                this.activeSection = this.stages[0];
                //this.passedScreenName = 'Bank Statement Analysis'
            }
        })
        .catch(error => {
            console.log('Error getting sub stage list:', JSON.stringify(error));
        });
    } */
        
    /* handleAccordionClick(event) {
        event.stopPropagation();
        if(event.target.name != undefined){
            this.rerenderCmp = false;
            const selectedStage = event.target.name;
            console.log('selectedStage',selectedStage)
            if (this.activeSection.name !== selectedStage) {
                for(let i =0; i<this.stages.length; i++){
                    if(this.stages[i].name === selectedStage){
                        this.stages[i].name = selectedStage;
                        this.activeSection = this.stages[i];
                        this.currentSection = this.stages[i].name;
                        this.passedScreenName= this.stages[i].name;
                        this.rerenderCmp = false;
                        console.log('rerenderCmp--',this.rerenderCmp);
                        setTimeout(() => {
                            this.rerenderCmp = true;
                        }, 10);
                        break;
                    }
                }
                console.log('passedScreenName--',this.passedScreenName);
                console.log('passedScreenName--',this.activeSection);
                console.log('activeSection--',this.activeSection.name);
            }
        }
    } */

    handleKeepAccordionOpen(event){
        console.log('this.currentSection=:'+this.currentSection);
    }   

    handleStopPropogation(event){
        event.stopPropagation();
    }
        
    handleRefreshCmp(event) {
        console.log('inside handleRefreshCmp event.detail.loanId=: in main');
        const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
            detail: {
                loanId:loanId,
                screenName: event.detail.screenName
            }
        });
        this.dispatchEvent(valueSelectedEvent);
    }

    getBanks() {
        getLiveLoanData({ recordId: this.recordId})
        .then((response) => {
            console.log("response customer details=: " + JSON.stringify(response));
            this.banksData = response;
            if(this.banksData!= null && this.banksData.length>0){
                this.showStatements=true;
            }
            for(let key in response){
                console.log("inside loop:  getLiveLoanData -> " + response[key].Is_Consider_for_Eligibility__c);
                if(response[key].Is_Consider_for_Eligibility__c) {
                    this.selectedbanks.push(response[key].Id);
                    this.showAnalysisButton = true;
                }
            }
            const eligibleAccounts = this.banksData.filter(
                record => record.Is_Consider_for_Eligibility__c === true
            );
            this.eligibleCount = eligibleAccounts.length;
            const disableOthers = this.eligibleCount >= 3;
            this.banksData = this.banksData.map(record => {
                return {
                ...record,
                disableEligibilityCheckbox: disableOthers && !record.Is_Consider_for_Eligibility__c
                };
            });
            this.spinner = false;
        }).catch((error) => {
            console.error('ERROR: getLiveLoanData -> '+ JSON.stringify(error));
        });
    }

    addedBank(event){
        console.log(event.detail);
        this.getBanks();
    }

    handleNextButton(event) {
        console.log('Inside handleNextButton');
        this.loadApplicants();
    }

    handleAddressNextButton(event) {
        console.log('Inside handleAddressNextButton');
        if (event.detail.value && this.passedScreenName == 'Seller Details') {
            this.isSeller = true;
            }

    }

    async fetchAllProducts() {
        await fetchAllProducts({ loanId: this.recordId })
            .then((result) => {
                console.log('fetchAllProducts: ' + JSON.stringify(result));
                this.products = result;
            })
            .catch((error) => {
                console.error('Error fetching products:', error);
            });
    }
    

    getCollateral() {
        getCollateralRecordsByLoanAppId({ loanAppId: this.recordId })
        .then(result => {
            this.collateralList = result;
            console.log('collateralList>',JSON.stringify(this.collateralList));
            const hasApfValueYes = this.collateralList?.some(c => c.apfValue === "Yes");
            console.log('hasApfValueYes>',hasApfValueYes);
        })
        .catch(error => {
            this.showToast('Error', error.body?.message || 'Failed to load collateral records', 'error');
        });
    }

    loadApplicants() {
        const applicantType = this.passedScreenName === 'Seller Details' ? 'Seller' : 'Builder';
        console.log('Loading applicants for type:', applicantType);

        getBuilderSellerApplicants({
            loanAppId: this.recordId,
            applicantType: applicantType
        })
            .then(result => {
                console.log('Applicants result:', JSON.stringify(result));
                this.applicantsList = result || [];
                this.applicantsList = (result || []).map(app => {
                    return {
                        ...app,
                        disableContactFields: true
                    };
                });
                this.hasApplicants = (this.applicantsList.length > 0);
                console.log('Applicants available:', this.hasApplicants);
                 const addressCmp = this.template.querySelector('c-sales-login-address-details-cmp');
                if (addressCmp) {
                    addressCmp.refreshData();
                }
                const sellerCmp = this.template.querySelector('c-seller-additional-details');
                if (sellerCmp) {
                    sellerCmp.refreshData();
                }
                const bankCmp = this.template.querySelector('c-add-manual-bank-d-a-cmp');
                if (bankCmp) {
                    //bankCmp.refreshData();
                }
            })
            .catch(error => {
                console.error('Error loading applicants:', error);
                this.showToast('Error', 'Failed to load applicants', 'error');
            });
    }

    get isBuilder() {
        return this.passedScreenName === 'Builder Details';
    }

    get isSeller() {
        return this.passedScreenName === 'Seller Details';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
            mode: 'dismissable'
        }));
    }
    handleEdit(event) {

        const recordId = event.currentTarget.dataset.id;

        this.applicantsList = this.applicantsList.map(app => {
            if (app.Id === recordId) {
                return {
                    ...app,
                    isDisabled: false
                    , disableContactFields: app.customerType === 'Individual'
                };
            }
            return app;
        });

    }
    handleFieldChange(event) {
        const recordId = event.target.dataset.id;
        const fieldName = event.target.dataset.field;
        const value = event.target.value;
        const fields = {
            Id: recordId
        };
        fields[fieldName] = value;
        const recordInput = { fields };
            let currentDate = new Date().toJSON().slice(0, 10);
            console.log('todayDate----', new Date());
            console.log('this.fieldName----', fieldName);
        if(fieldName =='DOI__c'){
            if (value >= currentDate) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Date of incorporation cannot be future/current date',
                    variant: 'Error',
                }));
               // this.template.querySelector(`[data-id="${recordId}"]`).value = '';
                return;
            }
        }
         if (fieldName == 'DOB__c') {
            var regexVar = /^([0-9]{2})\/([0-9]{2})\/([0-9]{4})$/;
            var regexDDMMMYYYY = /^(\d{2})-([A-Za-z]{3})-(\d{4})$/;
                let currentDate = new Date().toJSON().slice(0, 10)
                var userBirthDate = new Date(value.replace(regexVar, "$3-$2-$1"));
                var todayYear = (new Date()).getFullYear(); // Always use FullYear!!
                var cutOff19 = new Date(); // should be a Date
                cutOff19.setFullYear(todayYear - 21); // ...  
                console.log('todayDate----', new Date());
                console.log('this.dateofBirth----', value);
                if (value >= currentDate) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Date of birth cannot be future/current date',
                        variant: 'Error',
                    }));
                    return;
                } else if (userBirthDate > cutOff19) {
                    console.log('age----', 18 * 365);
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Age should not be less than 18 years',
                        variant: 'Error',
                    }));
                    return;
                }
        }
        updateRecord(recordInput)
            .then(() => {
                this.showToast('Success', 'Record updated successfully', 'success');
            })
            .catch(error => {
                console.error(error);
            });

    }
}