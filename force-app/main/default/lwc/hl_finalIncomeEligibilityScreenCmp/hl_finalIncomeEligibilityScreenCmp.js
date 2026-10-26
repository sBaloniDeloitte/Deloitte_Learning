import { LightningElement,api,track,wire } from 'lwc';
import getProductDetailsIncome from '@salesforce/apex/Utility_V1.getProductDetailsIncome';
import initiateAPIRequest from '@salesforce/apex/HL_EligibilityApiController.initiateAPIRequest';
import getScoreCardDetails from '@salesforce/apex/HL_EligibilityApiController.getScoreCardDetails';
import getLoanStatus from '@salesforce/apex/HL_EligibilityApiController.getLoanStatus';
import getApplicantsWithMultipleRecordTypes from '@salesforce/apex/Utility_V1.getApplicantsWithMultipleRecordTypes';
// import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import checkTechnicalValidation from '@salesforce/apex/Utility_V1.checkTechnicalValidation';
//HL-Prachi
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated'
//HL-Prachi
// import checkTechnicalValidationHL from '@salesforce/apex/Utility_V1.checkTechnicalValidationHL';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchProductDetails from '@salesforce/apex/FinalEligibilityFieldsController.fetchProductDetails';
import { updateRecord } from "lightning/uiRecordApi";
import fetchPLRValues from '@salesforce/apex/HL_EligibilityApiController.fetchPLRValues';
import updatePLROnProduct from '@salesforce/apex/HL_EligibilityApiController.updatePLROnProduct';
import { fireEvent } from 'c/pubsub';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';

export default class Hl_finalIncomeEligibilityScreenCmp extends LightningElement {
    @api recordId;
    @api showCalculator = false;
    @track productDetails=[];
    @track isHLUser;
    scoreCardList = [];
    errorList=[];
    showError=false;
    prodcutName;
    productId;
    errorFields=false;
    errorDetailsBRE=[];
    eligibilityTypeOptions = [{ label: 'Income Eligibility', value: 'Income Eligibility' },{ label: 'Final Eligibility', value: 'Final Eligibility' }];
    selectedEligibilityType = '';
    disableEligibilityType = true;
    showProductData = false;
    // ___________This Code was generated using GenAI tool : Codify, Please check for accuracy___________
    // Table is only revealed after the user explicitly clicks "Fetch Eligibility".
    eligibilityFetched = false;
    // ___________GenAI: Generated code ends here___________
    isLoading = false;
    // isFlexiLoan = false;
    @api disableActions = false;
    @track fieldDetails;
    @api subProdid;
    plrOptions = [];
    selectedPLR = '';
    selectedMargin = 0;
    @track checkVal = false;
    @wire(CurrentPageReference) pageRef;
    @track activeSections = [];

    connectedCallback(){
        if(this.showCalculator){
            this.checkVal = false;
        }
        else{
            this.checkVal = false;
        }
        this.getProductDetailsIncome();
        this.fetchPLRMaster();

        this.checkIfLoggedInUserIsHLRelated();
        // this.getProductDetails();

        console.log('this.disableActions: '+this.disableActions);
        if(this.disableActions == false){
            this.getLoanStageAndSubStage();
        }
        registerListener("refreshEligibility", this.refresh, this);
    }

    handleSectionToggle(event) {
        this.subProdid = '';
        this.productId = event.detail.openSections;

        this.activeSections = [];
        this.activeSections.push(this.productId);

        // Switching product/section hides the table again until Fetch Eligibility is clicked.
        this.eligibilityFetched = false;

        this.fetchProductDetails();
        this.getApplicantsScoreCardDetails();
    }

    fetchProductDetails() {
        console.log('productId: '+this.productId);
        console.log('checkVal: '+this.checkVal);

        fetchProductDetails({ productId: this.productId, Calculator: this.checkVal })
        .then((result) => {
            console.log('result 73: ' + JSON.stringify(result));

            this.showProductData = this.eligibilityFetched;
            this.fieldDetails = result;

            console.log('fieldDetails: '+JSON.stringify(this.fieldDetails));

            this.calculatePLRMargin(false);

            this.selectedEligibilityType = result[0].isFinalEligibility ? 'Final Eligibility' : 'Income Eligibility';

            const record = this.productDetails.filter(row => row.productId === this.productId);
            this.subProdid = record[0].subProdId;
            console.log('this.subProdid: '+this.subProdid);
        })
        .catch((err) => {
            console.error(err);
        });
    }
    
    // getProductDetails(){
    //     const inputMap = {
    //         oppId : this.recordId
    //     }
    //     getProductDetails({
    //        inputMap:inputMap
    //     })
    //     .then(result => {
    //         console.log('result 112: ',JSON.stringify(result));
    //         this.isFlexiLoan = result.loanProduct == 'Flexi Loan' ? true : false;
    //     })
    //     .catch(error => {
    //         console.log('error',error);
    //     })
    // }

    checkIfLoggedInUserIsHLRelated(){
        checkIfLoggedInUserIsHLRelated()
        .then(result => {
            this.isHLUser = result.isHLRelated;

            console.log('isHLUser-->',this.isHLUser);
        })
        .catch(error => {
            console.log('error',error);
        })
    }

    fetchPLRMaster() {

        fetchPLRValues({ })
        .then((result) => {
            console.log('result 118: ' + JSON.stringify(result));
            
            if(result){
                for(var i=0; i< result.length; i++){
                    var plrRate = parseFloat(result[i].FICO_Code__c).toFixed(2);
                    var option = { label: (result[i].Description__c +' - '+ plrRate), value: plrRate };
                    this.plrOptions.push(option);
                }
            }
            console.log('this.plrOptions: '+ JSON.stringify(this.plrOptions));
        })
        .catch((err) => {
            console.error(err);
        });
    }

    getProductDetailsIncome(){
        const inputMap = {
            oppId : this.recordId
        }
        getProductDetailsIncome({
            inputMap:inputMap
        })
        .then(result => {
            // console.log('result 143: ',JSON.stringify(result));

            this.productDetails = result;
            this.activeSections.push(result[0].productId);
            this.productId = result[0].productId;

            this.fetchProductDetails();
            this.getApplicantsScoreCardDetails();
        })
        .catch(error => {
            console.log('error',error);
        })
    }

    getApplicantsScoreCardDetails() {
        // ___________This Code was generated using GenAI tool : Codify, Please check for accuracy___________
        // Bypass the Apex callout and populate the Score Card table with static data.
        this.scoreCardList = [
            {
                Id: 'staticScoreCard1',
                Name: 'Abhilash Saini',
                Score_Card_Key__c: 'SC-1001',
                Score_Card_Name__c: 'Home Loan Score Card',
                Score_Card_Score__c: '785',
                Risk_Card_Name__c: 'Home Loan Risk Card',
                Risk_Score__c: '62',
                KYC_Risk_Categorisation_Category__c: 'Low Risk'
            }
        ];
        // ___________GenAI: Generated code ends here___________
    }

    handleUserInput(event){
        const fieldName = event.target.dataset.name;
        const labelName = event.target.dataset.label;
        console.log('fieldName: '+fieldName);
        console.log('labelName: '+labelName);

        this.fieldDetails = this.fieldDetails.map(item => {
            
            if(item.userInput.fieldApiName == fieldName && item.fieldLabel == labelName){
                item.userInput.fieldApiVal = event.target.value;
            }

            return item;
        });

        console.log('updated fieldDetails: '+JSON.stringify(this.fieldDetails));

        if(labelName == 'Base Rate / Margin (PLR)'){
            const selectedOption = this.plrOptions.find(option => option.value === event.target.value);
            this.selectedPLR = selectedOption ? selectedOption.label : '';
            console.log('this.selectedPLR: '+this.selectedPLR);

            this.calculatePLRMargin(true);
        }
        else if(labelName == 'Rate of Interest'){
            this.calculatePLRMargin(true);
        }
    }

    calculatePLRMargin(allowUpdate){
        const plrRecord = this.fieldDetails.filter(row => row.fieldLabel === 'Base Rate / Margin (PLR)');
        const roiRecord = this.fieldDetails.filter(row => row.fieldLabel === 'Rate of Interest');
        
        this.fieldDetails = this.fieldDetails.map(item => {

            if(item.fieldLabel == 'Effective Margin' && roiRecord[0].userInput.fieldApiVal && plrRecord[0].userInput.fieldApiVal){
                item.userInput.fieldApiVal = (roiRecord[0].userInput.fieldApiVal - plrRecord[0].userInput.fieldApiVal).toFixed(2);
                this.selectedMargin = item.userInput.fieldApiVal;

                if(allowUpdate){
                    this.updatePLR();
                }
            }

            return item;
        });

        console.log('updated fieldDetails 201: '+JSON.stringify(this.fieldDetails));
    }

    updatePLR() {
        console.log('update called--');
        console.log('this.selectedPLR: '+this.selectedPLR);
        console.log('this.selectedMargin: '+this.selectedMargin);

        updatePLROnProduct({
            loanId: this.recordId,
            plr: this.selectedPLR,
            margin: this.selectedMargin,
            productId: this.productId
        })
        .then(result => {
            console.log('result 227: ', result);

            if(result === 'Success'){
                this.showToast('Success', 'Data saved', 'success');
            }
            else{
                this.showToast('Error', 'Some error in saving data', 'error');
            }
        })
        .catch(error => {
            console.log('error', error);
        });
    }

    handleSaveField(event){
        var enteredVal = 0;
        if(event.target.value){
            if((event.target.dataset.name == 'Final_Loan_Amount__c' || event.target.dataset.name == 'Sanctioned_Tenor__c') && event.target.value.includes('.')){
                this.showToast('Error', 'Please enter valid number!', 'error');
                return;
            }
            
            if ((isNaN(Number(event.target.value)))){
                this.showToast('Error', 'Please enter valid number!', 'error');
                return;
            }

            if(event.target.dataset.name == 'Sanctioned_Loan_Amount__c'){
                let finalLoanWrapper = this.fieldDetails.find(
                    item => item.fieldLabel === 'Final Loan Amount'
                );

                if (finalLoanWrapper) {
                    const breValue = finalLoanWrapper.breOutput?.fieldApiVal;

                    console.log('BRE Output Value: ', breValue);
                    console.log('Sanction Term Output Value: ', event.target.value);

                    if (Number(breValue) < Number(event.target.value)) {
                        event.target.value= breValue;
                        enteredVal = Number(event.target.value);
                        this.showToast('Error', 'Please enter same value as BRE output.', 'error');
                        // return;
                    } else {
                        enteredVal = Number(event.target.value);
                    }
                }
            }
            else{
                enteredVal = Number(event.target.value);
            }
        }

        console.log('event.target.dataset.name=:'+event.target.dataset.name);
        console.log('this.subProdid 189: '+this.subProdid);

        const fields = {};
        fields['Id'] = this.subProdid;
        fields[event.target.dataset.name] = enteredVal;
        const recordInput = { fields };

        updateRecord(recordInput)
        .then((response) => {
            console.log('update response: '+JSON.stringify(response));
            
            this.fetchProductDetails();

            this.showToast('Success', 'Data saved', 'success');
        })
        .catch(error=>{
        })
    }

    getLoanStageAndSubStage(){
        getLoanStatus({
            loanId: this.recordId
        })
        .then(result => {
            console.log('result 235: ',JSON.stringify(result));
            this.selectedEligibilityType = 'Income Eligibility';
            
            if(result[0] == 'Credit Underwriting' && result[1].includes('Credit in-progress')){
                this.disableEligibilityType = false;
            }
        })
        .catch(error => {
            console.log('error', error);
        })
    }

    getApplicantsWithMultipleRecordTypes(){
        this.isLoading = true;

        getApplicantsWithMultipleRecordTypes({
            loanAppId: this.recordId
        })
        .then(result => {
            console.log('result 252: ',JSON.stringify(result));

            if(result.length >0){
                this.isLoading = false;
                this.showError = true;
                this.errorList = result;
            }
            else{
                this.errorDetailsBRE = [];

                //creating map to send in BRE API
                var userValues = {
                    'finalLoanAmount' : 0,
                    'roi' : 0,
                    'tenor' : 0,
                    'additionalFOIR' : 0
                };

                this.fieldDetails.map(item => {

                    switch (item.fieldLabel) {
                        case 'Final Loan Amount':
                            userValues.finalLoanAmount = (item.userInput.fieldApiVal && item.userInput.fieldApiVal > 0) ? item.userInput.fieldApiVal : this.errorDetailsBRE.push('Error: Final Loan Amount is required.');
                            break;
                        case 'Rate of Interest':
                            userValues.roi = (item.userInput.fieldApiVal && item.userInput.fieldApiVal > 0) ? item.userInput.fieldApiVal : this.errorDetailsBRE.push('Error: Rate Of Interest is required.');
                            break;
                        case 'Full EMI Tenure':
                            userValues.tenor = (item.userInput.fieldApiVal && item.userInput.fieldApiVal > 0) ? item.userInput.fieldApiVal : this.errorDetailsBRE.push('Error: Full EMI Tenure is required.');
                            break;
                        case 'Additional FOIR':
                            userValues.additionalFOIR = item.userInput.fieldApiVal ? item.userInput.fieldApiVal : 0;
                            break;
                    }
                });
                /*
                if(this.errorDetailsBRE.length >0){
                    this.errorFields = true;
                    this.isLoading = false;
                    return;
                }
                */
                
                const inputMap = {
                    loanId : this.recordId,
                    productId : this.productId,
                    productName : this.prodcutName,
                    isIncomeFromSales : false,
                    processName : 'Credit Eligibility HL',
                    eligibilityType : this.selectedEligibilityType,
                    callForDeviation : true,
                    userCalValues: JSON.stringify(userValues)
                };

                this.showProductData = false;

                console.log('inputMap: ', JSON.stringify(inputMap));
                initiateAPIRequest({
                    inputMap:inputMap
                })
                .then(result => {
                    console.log('result 278: ',JSON.stringify(result));
                    if(result === 'success'){
                        
                        this.showToast('Success', 'Eligibility feteched successfully!', 'success');
                        
                        this.fetchProductDetails();
                        this.getApplicantsScoreCardDetails();
                        this.isLoading = false;
                    }
                    else{
                        this.errorFields = true;
                        let errorArray = [];
                        if (typeof result === 'string') {
                            errorArray = result.split(/[\n,]+/).map(e => e.trim()).filter(e => e);
                        }

                        this.errorDetailsBRE = errorArray.map(err => ` ${err}`);
                        this.isLoading = false;

                        this.showToast('Error', 'Error fetching eligbility!', 'error');
                    }
                })
                .catch(error => {
                    console.log('error',error);
                    this.isLoading = false;
                    this.showToast('Error', 'Error fetching eligbility!', 'error');
                })
            }
        })
        .catch(error => {
            this.isLoading = false;
            console.log('error', error);
        })
    }

    handleFetchEligibility(event){
        // ___________This Code was generated using GenAI tool : Codify, Please check for accuracy___________
        // Bypass technical validation / BRE initiation calls -- only populate the data table.
        console.log('event.target.dataset: '+JSON.stringify(event.target.dataset));
        this.prodcutName = event.target.dataset.id;
        this.productId = event.target.dataset.name;
        this.eligibilityFetched = true;

        this.fetchProductDetails();
        this.getApplicantsScoreCardDetails();
        // ___________GenAI: Generated code ends here___________
    }

    checkTechnicalValidation(){
        if(this.isHLUser){
            // const inputMap = {
            //     loanId : this.recordId,
            //     productId : this.productId,
            //     eligibilityType : this.selectedEligibilityType
            // };
            // checkTechnicalValidationHL({
            //     inputMap : inputMap
            // })
            // .then(result => {
            //     console.log('result 327: ',JSON.stringify(result));
                
            //     if(result.length>0){
            //         this.showError = true;
            //         this.errorList=[...result];
            //     }
            //     else{
                    this.getApplicantsWithMultipleRecordTypes();
            //     }
            // })
            // .catch(error => {
            //     console.log('error', error);
            //     this.getApplicantsWithMultipleRecordTypes();
            // })
        }else{
            checkTechnicalValidation({
                loanId: this.recordId,
                productId: this.productId
            })
            .then(result => {
                console.log('result 327: ',JSON.stringify(result));
                
                if(result.length>0){
                    this.showError = true;
                    this.errorList=[...result];
                }
                else{
                    this.getApplicantsWithMultipleRecordTypes();
                }
            })
            .catch(error => {
                console.log('error', error);
                this.getApplicantsWithMultipleRecordTypes();
            })
        }
    }

    hideModalBox(){
        this.showError =false;
    }

    hideModalBoxBre(){
        this.errorFields=false;
    }

    onChangeInput(event) {
        this.selectedEligibilityType = event.target.value;
    }
    
    // Show Toast Message
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    refresh(event){
        console.log('504');
        setTimeout(() => {
            console.log('506');
            this.connectedCallback();
        }, 3000);
    }

    handleCheckboxChange(event){
        this.checkVal = event.target.checked;
        console.log('checkVal : '+this.checkVal);
        this.fetchProductDetails();
    }
}