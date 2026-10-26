import { LightningElement,track,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import applicantDetails from '@salesforce/apex/LoanLoginChangeApplicantTypeController.applicantDetails';
import saveApplicantDetails from '@salesforce/apex/LoanLoginChangeApplicantTypeController.saveApplicantDetails';
import executeMapping from '@salesforce/apex/COMM_DocumentDetailsScreenController.executeMapping';
import checkPanAndBureau from '@salesforce/apex/COMM_SalesLoanLoginController.checkPanAndBureau';
import checkifbureauisfetched from '@salesforce/apex/LoanLoginChangeApplicantTypeController.checkifbureauisfetched'
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getApplicantsByLoanApplication from "@salesforce/apex/AHL_LoanApplicationActionController.getApplicantsByLoanApplication";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import APPLICATION_APPLICANT_OBJECT from '@salesforce/schema/Application_Applicant__c';
import APPLICANT_TYPE from '@salesforce/schema/Application_Applicant__c.Applicant_Type__c';
import { updateRecord } from "lightning/uiRecordApi";
import FORM_FACTOR from '@salesforce/client/formFactor';
import ApplicantLovs from '@salesforce/label/c.LOVs_for_Key_Applicant_Cmp';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import updateScoreForKeyApplicant from '@salesforce/apex/AHL_ScorecardController.updateScoreForKeyApplicant';
export default class SalesLoginSwapApplicant extends LightningElement {
    @track openConfirmationScreen = true;
    @api loginChecklist;
    @track applicantList = [];
    @track coApplicantList = [];
    @track ToggleDefault = false;
    @api recordId;
    @api applicantId;
    @api isHomeTab;
    @track showCoApplicantList = false;
    @track applicantTypeOptions = [];
    currentApplicantIndex  = 0;
    @track cibilScoreLow=false;
    @track showExceptionConfirmation=false;
    @track cibilExceptionconfirmationMessage= 'CIBIL score of the selected key applicant is lower than the decided threshold and would require additional approval. Please confirm the same.';
    selectedCoApplicantId;
    saveandnext = "Save & Next";
    @track refreshComponent = false;
    isloading = false;
    @wire(getObjectInfo, { objectApiName: APPLICATION_APPLICANT_OBJECT })
    applicantDetailsInfo;
    refreshData;
    isMobileOrTablet = false;
    isDesktop = FORM_FACTOR === 'Large';
    //
    isBureauMissing=false;
    applicantLovsStr = ApplicantLovs;
    showHLRelatedData=false;
    product;
    //

    @api get refreshCmp() {
        console.log('get data');
        return this.refreshData;
    }
    set refreshCmp(value) {
        console.log('set data',value);
        this.setAttribute('refreshCmp', value);
        this.fetchApplicants();
    }
    /*
    @wire(getPicklistValues, { recordTypeId: '$applicantDetailsInfo.data.defaultRecordTypeId', fieldApiName: APPLICANT_TYPE})
    applicantTypePickList({ data, error }) {
        if (data){
        console.log('data.values Error --> '+ JSON.stringify(data.values));
            this.applicantTypeOptions = data.values;
        }else{
            console.log('residentialStatusPickList Error --> '+ error);
        } 
    }*/

    connectedCallback() {
        this.getProductDetails();
        this.isMobileOrTablet = FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium';
        console.log('SalesLoginSwapApplicant: deviceType: ', this.isMobileOrTablet);
        console.log('this.recordId:: ' + this.recordId);
        console.log('this.isHomeTab:: ' + this.isHomeTab);
        let appOptions = this.applicantLovsStr.split(';');
        this.applicantTypeOptions = appOptions.map(val => ({
            label: val,
            value: val
        }));
        this.fetchApplicants();
        this.isloading = true;
        setTimeout(() => {
        this.isloading = false;
        }, 2000);
    }

    fetchApplicants(){
        applicantDetails({recordId : this.recordId})
        .then(result => {
            console.log('result:: ' + JSON.stringify(result));
            this.applicantList = [...result];
           this.applicantList = this.applicantList.map(applicant => {
            return {
                ...applicant,
                isDisabled: this.showHLRelatedData ? true : applicant.disableApplicantType
            };
        });
        })
    }

    handleToggleChange(event) {
        this.ToggleDefault = event.target.checked;
        if (this.ToggleDefault) {
            this.showCoApplicantList = true;
            this.openConfirmationScreen = false;
        } else {
            this.showCoApplicantList = false;
            this.openConfirmationScreen = true;
        }
    }
    handleApplicantTypeChange(event){
        for(var i=0;i<this.applicantList.length;i++){
            if(this.applicantList[i].applicantId == event.target.dataset.id){
                this.applicantList[i].applicantType = event.target.value;
                break;
            }
        }
    }
   async validateSaveAndNext(){
        console.log('this.applicantList=:'+JSON.stringify(this.applicantList));
        var count = 0;
        var keyApplicantCount = 0;
        var financialApplicantCount = 0;
        var isnonind= false;
        var isCibilFetchedCount=0;
        var isnonindCount=0;
        var isCibilFetched=true;
        const isValid = await this.checkPanAndBureau();
        console.log('isValid=='+isValid);
        if(!isValid){
            return;
        }
        for(var i=0;i<this.applicantList.length;i++){
            if(this.applicantList[i].isCibilFetched==false){
                isCibilFetched==false;
                isCibilFetchedCount ++;
            }
            if(this.applicantList[i].disableApplicantType){
                isnonind = true;
                isnonindCount++;
            }
            if(this.applicantList[i].applicantType == 'Primary Applicant'){
                count++;
            }
             if(this.applicantList[i].isKeyApplicant==true){
                 keyApplicantCount++;
         }
            if(this.applicantList[i].isFinancialApplicant){
                financialApplicantCount++;
            }
        }
        console.log('count===='+isCibilFetchedCount);
        console.log('Inside 128---'+this.applicantList.length);
        var applicantListCount =this.applicantList.length;
        console.log('Inside 129---'+applicantListCount-isnonindCount);
        var finalCount = applicantListCount-isnonindCount;
        console.log('finalCount'+finalCount);
        if(!isnonind && !isCibilFetched &&  (isCibilFetchedCount<=finalCount)){
            console.log('finalCount'+finalCount);
            this.showToast('Error', 'Please fetch Cibil for all applicants', 'error');
            return;
        }
         if(keyApplicantCount== 0){
            this.showToast('Error', 'There should be one key applicant', 'error');
             return;
         }
        else if(financialApplicantCount==0){
            console.log('finalCount'+finalCount);
            this.showToast('Error', 'There should be one Financial applicant', 'error');
            return;
        }
        if(!isnonind){
            console.log('finalCount 149'+count);
        if(count == 0){
                console.log('finalCount 151'+count);
            this.showToast('Error', 'There should be atleast one primary applicant', 'error');
            return;
        }
        else if(count > 1){
                console.log('finalCount 156'+count);
            this.showToast('Error', 'Primary applicant cannot be more than one', 'error');
            return;
        }
            else{
                  console.log('finalCount Inside----'+finalCount);
            this.saveApplicantDetails();
            this.getApplicantsByLoanApplication();
            }
        }
        else{
            console.log('finalCount Inside----'+finalCount);
            this.saveApplicantDetails();
            this.getApplicantsByLoanApplication();
        }
        //this.checkPanAndBureau();
         
        
    }
      async checkPanAndBureau(){
        try{
       const response = await checkPanAndBureau({
            applicantList : JSON.stringify(this.applicantList), 
            recordId : this.recordId,
        })
       
            console.log('response swap Kshitiz=',response);
           /* if(response== 'AllDetailsBlank'){
                 this.showToast('Error', 'Please validate/Verify PAN details or initate bureau for all  applicants.', 'error');
                return;
            }
            else if(response== 'PanStatusBlank'){
                 this.showToast('Error', 'Please validate/Verify PAN details for all applicants.', 'error');
                return;
            }*/
            //else{
            if(response != ''){
                this.showToast('Error', response, 'error');
                return false;
            }
            return true;
              /*  this.cibilScoreLow=false;
                    for(var i=0;i<this.applicantList.length;i++){
                        if(this.applicantList[i].applicantId == this.selectedApplicantId && this.applicantList[i].iscibilLow==true){
                            this.cibilScoreLow=true;
                        }
                }
                if(this.cibilScoreLow){
                    this.showExceptionConfirmation= true;
                }
                else{
                    this.saveApplicantDetails();
                    this.getApplicantsByLoanApplication();

                    
                }*/
           // }
    }
    catch(error){
        return false;
    }
    }


    saveApplicantDetails(){
        saveApplicantDetails({
            applicantList : JSON.stringify(this.applicantList), 
            cibilScoreLow: this.cibilScoreLow, 
            recordId : this.recordId
        }).then(response=>{
           
            this.showToast('Success', 'Applicant type changed successfully.', 'success');
            this.showCoApplicantList = false;
            this.openConfirmationScreen = false;
            this.fetchApplicants();
            console.log('insdie eventttt swapApplicant-- 144---');
             this.getApplicantsByLoanApplication();
            
            this.dispatchEvent(new CustomEvent('navigatetonexttab', {
                detail: true
            }));
            const valueSelectedEvent = new CustomEvent('skipchange', { detail: {} });
            this.dispatchEvent(valueSelectedEvent);
        }).catch(error=>{
            this.getApplicantsByLoanApplication();
            console.log('error swap Kshitiz 2=',error);
            this.showToast('Error', 'Failed to change applicant type.', 'error');
        })
    }

    SkipChange() {
        this.showCoApplicantList = false;
        this.openConfirmationScreen = false;
        const valueSelectedEvent = new CustomEvent('skipchange', { detail: {} });
        this.dispatchEvent(valueSelectedEvent);
    }
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
    handleApplicantSelection(event) {
        this.selectedApplicantId = event.target.dataset.name;
        console.log('Selected Applicant ID:', this.selectedApplicantId);
        checkifbureauisfetched({appId :this.selectedApplicantId })
        .then(response=>{
            console.log('response '+response);
            if(response == ''){ //== ''
                for(var i=0;i<this.applicantList.length;i++){
                    if(this.applicantList[i].applicantId == this.selectedApplicantId){
                        this.applicantList[i].isKeyApplicant = true;
                    }else{
                        this.applicantList[i].isKeyApplicant = false;
                    }
                }
                console.log('applicantList:',JSON.stringify(this.applicantList));
                this.updateRecords();
            }
            else{
                const radioButton = this.template.querySelector(`input[data-name="${this.selectedApplicantId}"]`);
                if (radioButton) {
                    radioButton.checked = false;
                }
                this.isBureauMissing=true;
                this.selectedApplicantId = null;
                this.showToast('Error', response, 'error');
            }
        })
        
        // this.updateRecords();
    }
    updateRecords(){
        const fields = {};
        fields['Id'] = this.selectedApplicantId;
       
        fields['Is_Key_Applicant__c'] = true;
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
        .then(() => {
            updateScoreForKeyApplicant({appId :this.selectedApplicantId,loanId:this.recordId })
        .then(response=>{
            console.log('Segment updated');
        }).catch(error=>{
            console.log('Segment update fail',error);
        })

        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
       

    }

    closeExceptionModal(){
        this.showExceptionConfirmation= false;
    }

    updateException(){

        this.saveApplicantDetails();
        this.showExceptionConfirmation= false;

    }

      createDocumentsForLoan(){
            for(var i=0; i<this.applicantList.length; i++){
                console.log('create documentssss- 168--');
               
                console.log('Processing applicant 234:', this.applicantList[i].Id);
                executeMapping({
                    identifier:'fromLoan',
                    recordId:this.recordId,
                    applicantId: this.applicantList[i].Id,
                    applicantType:'Primary Applicant'
    
                }).then(response=>{
                    console.log('response=: partner'+JSON.stringify(response));
                    


    
                
                }).catch(error=>{
    
                })
            }
                
              
                
            }

            getApplicantsByLoanApplication(){
                getApplicantsByLoanApplication({ loanApplicationId: this.recordId })
                .then(response => {
                    console.log('response app188 ', JSON.stringify(response));
                    this.applicantList = response;
                    // for(var i=0; i<this.applicantList.length; i++){
                        //this.createDocumentsForLoan(); 
                        
                    // }
                   
                })
                .catch (error => {
                    console.error('Error fetching applicants: ', error);
                    this.showToastMessage('Error', 'Documents not created please open pan validation accordian.', 'error');
                    this.spinner = false;
                })
            }

     //HL
    getProductDetails(){
        const inputMap = {
            'oppId': this.recordId
        };
        getProductDetails({inputMap: inputMap})
        .then(response => {
            this.product = response.loanProduct;
            console.log('Product Details: '+JSON.stringify(this.productDetails));
            if(this.product == 'Home Loan'||this.product=='Non Home Loan'||this.product=='Flexi Loan'){
                this.showHLRelatedData = true;
            }
        })
        .catch(error => {
            console.log(error);
        });
    }

           
    
}