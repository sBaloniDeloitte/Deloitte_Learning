import { LightningElement,track,api } from 'lwc';
import getPanResp from '@salesforce/apex/COMM_SalesLoanActionsController.getPanResp';
import getApplicantValues from '@salesforce/apex/COMM_SalesLoanLoginController.getApplicantValues';
import initiateAPIRequestPanValidation from '@salesforce/apex/PANStatusCheckController.initiateAPIRequest'
import updateApplicantVerification from '@salesforce/apex/COMM_SalesLoanActionsController.updateApplicantVerification'
import documentCheckListUpdation from '@salesforce/apex/COMM_SalesLoanActionsController.documentCheckListUpdation'
import NOT_ELIGIBLE_ICON from '@salesforce/resourceUrl/RejectIconEligibility';
import executeMapping from '@salesforce/apex/COMM_DocumentDetailsScreenController.executeMapping';
import FORM_FACTOR from '@salesforce/client/formFactor';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
export default class SalesLoginPanValidationResponseCmp extends LightningElement {
    @api recordId;
    formFactor = FORM_FACTOR;
    @api applicantId;
    @track panResponse = {};
    @api loginChecklist= false;
    showTable = false;
    isloading = false;
    @api currentAppSeq
    panNumber;
    dobOrdoi;
    showValidateButton = true;
    errorList = [];
    customerType;
    isConsentAccepted = false;
    isIndividual = true;
    showError= false;
    panValidated = false;
    isMNRLBlacklisted = false;
    disableValidateButton = false;
    connectedCallback() {
        this.isloading = true;
        this.notEligibleIcon = NOT_ELIGIBLE_ICON;
        console.log('this.loginChecklist in pan validation--', this.loginChecklist);
        
        setTimeout(() => {
            this.isloading = false;
        }, 2000);
        if(!this.loginChecklist){
             this.getApplicantValues();
        }else if(this.loginChecklist){
            this.getPanResp();
        }
       
    }
    get getScrollInMobile(){
        if(this.formFactor=='Small'){
            return "overflow: scroll;"
        }
    }
    get getNextByMobile(){
        if(this.formFactor=='Small'){
            return "font-size: 11px; width: auto; background-color:#9bbf56; color: white; border-color: #9bbf56; font-weight: 500;";
        }
        return "font-size: 11px; width: 140px; background-color:#9bbf56; color: white; border-color: #9bbf56; font-weight: 500;";
    }
    getApplicantValues(){
        this.isloading = true;
        const inputMap ={
            'applicantId':this.applicantId
        }
        getApplicantValues({
            inputMap:inputMap
        })
        .then(response => {
            console.log('response 42---',JSON.stringify(response));
            this.isloading = false;
            this.panNumber = response[0].panNumber;
            this.dobOrdoi = response[0].dobORDoi;
            this.panValidated  = response[0].isPanValidated;
            this.customerType = response[0].customerType;
            this.isMNRLBlacklisted = response[0].isMNRLBlacklisted;
            this.isConsentAccepted = response[0].isConsentAccepted;
            if(this.isMNRLBlacklisted){
                this.disableValidateButton = true;
            }
            if(this.customerType == 'Individual'){
                this.isIndividual = true;
            }
            else{
                this.isIndividual = false;
            }
            if(this.panValidated == false){
                 this.isloading = true;
                setTimeout(() => {
                    //this.callPanValidationApi();
                }, 500);
            }
            else{
                this.isloading = true;
                if(this.disableValidateButton == false){
                this.getPanResp();
                }
                this.createDocumentsForLoan();
            }
          
           
        })
        .catch(error => {
            this.isloading = false;
            console.error('Error fetching applicant values:', error);
        });
    }
    callPanValidationApi() {
        this.isloading = true;
            console.log('548');
            const inputMap = {
                'loanId': this.recordId,
                'applicantId': this.applicantId, // this.selectedRecordId,
                'processName': 'Loan Applicant PAN Validation',
                'panNum': this.panNumber,
                'dob': this.dobOrdoi // '1977-03-22'
            }
            console.log('inputMap initiateAPIRequestPanValidation-->' + JSON.stringify(inputMap));
            initiateAPIRequestPanValidation({
                    inputMap: inputMap
                })
                .then(response => {
                    this.isloading = false;
                    console.log('response initiateAPIRequestPanValidation 95-- ' + (response));
                    if (response.includes('Error:')) {
                        this.errorList = [response];
                        this.showTable = false;
                        this.showError= true;
                        this.createDocumentsForLoan();
                        // console.log('response--', response.split(':')[1]);
                        // var temp = response.split(':')[1];
                        // console.log('temp--' + temp);
                        // this.errorList = temp.split(',');
                        // console.log('errorList--' + this.errorList);
                    } else {
                        console.log('in else');
                        this.panVerif = JSON.parse(response);
                        console.log('errorList- 569-' + JSON.stringify(this.panVerif));
                        //if(this.panVerif.result.status!=null){ -- Alika Removed
                        // let parsedResponse = JSON.parse(response);
                            // let dobMatch = this.panVerif.result.dobMatch;
                            // let nameMatch = this.panVerif.result.nameMatch;
                            // let statusActive = this.panVerif.result.status;
                            // let duplicateCheck = this.panVerif.result.duplicate;
                            
        
                            // this.updateApplicantRecord(dobMatch, nameMatch, statusActive, duplicateCheck);
                            if(this.panVerif.response_Code == '1'){//Alika
                            this.updateApplicantRecord(this.panVerif.outputData[0].dob, this.panVerif.outputData[0].name, this.panVerif.outputData[0].pan_status,this.panVerif.outputData[0].seeding_status,this.panVerif.outputData[0].pan_status_description,this.panVerif.outputData[0].seeding_status_description,this.panVerif.outputData[0].fathername);//Alika
                        }else if(this.panVerif.error){
                            this.errorList = [this.panVerif.error];
                            this.showTable = false;
                            this.showError= true;
                            this.createDocumentsForLoan();
                        }
                        else{
                            this.errorList = ['Error: We are currently unable to validate your PAN. Kindly try opening this section after some time.'];
                            this.showTable = false;
                            this.showError= true;
                            this.createDocumentsForLoan();
                            this.showToast('Validation Error', 'We are currently unable to validate your PAN. Please try after Some Time or Recheck PAN Number', 'error');

                        }
                        
                        //this.callCkyc();
                    }
    
                })
                .catch(error => {
                    this.isloading = false;
                    this.errorList = ['Error: We are currently unable to validate your PAN. Kindly try opening this section after some time.'];
                    this.showTable = false;
                    this.showError= true;
                    // console.error('error initiateAPIRequestPanValidation --> ' + JSON.stringify(error));
                    this.createDocumentsForLoan();
                })
        }
    
        updateApplicantRecord(dobMatch, nameMatch,statusActive,seeding_status,pan_description,seeding_status_description,fathername) {//Alika-Start
            updateApplicantVerification({
                    applicantId: this.applicantId,
                    dobMatch: dobMatch,
                    nameMatch: nameMatch,
                    statusActive: statusActive,
                    seeding_status: seeding_status,
                    pan_description : pan_description,
                    seeding_status_description :  seeding_status_description,
                    fathername : fathername   
                })
                //Alika-End
                .then(() => {
                    console.log('Application_Applicant__c record updated successfully.');
                    this.getPanResp();
                    this.createDocumentsForLoan();
                })
                .catch(error => {
                    console.error('Error updating Application_Applicant__c --> ', JSON.stringify(error));
                });
        }
    
        createDocumentsForLoan(){
            /*
            console.log('create documentssss---');
            executeMapping({
                identifier:'fromLoan',
                recordId:this.recordId,
                applicantId:this.applicantId,
                applicantType:'Primary Applicant'

            }).then(response=>{
                console.log('response=: partner'+JSON.stringify(response));

            
            }).catch(error=>{

            })
            */
            
        }

       /* callCkyc() {
            const inputMap = {
                'loanId': this.recordId,
                'applicantId': this.applicantId, // this.selectedRecordId,
                'processName': 'Loan Applicant CKYC',
                'panNum': this.panNumber, // 'BTQPP1549D',
                'dob': this.dobOrdoi // '1999-03-22'
            }
            console.log('inputMap -->' + JSON.stringify(inputMap));
            initateCKYC({
                    inputMap: inputMap
                })
                .then(response => {
                    console.log('initateCKYC response -->' + response);
                    this.ckycResp = JSON.parse(response);
                    if (this.ckycResp) {
                        console.log('initateCKYC success');
                        const images = this.ckycResp?.PID_DATA?.IMAGE_DETAILS?.IMAGE;
                        this.imageMap = images.reduce((acc, image) => {
                            if (!acc[image.IMAGE_CODE]) {
                                acc[image.IMAGE_CODE] = []; // Initialize array if not present
                            }
                            acc[image.IMAGE_CODE].push(image.IMAGE_DATA); // Push image data into array
                            return acc;
                        }, {});
                        this.imagetypemap =  this.ckycResp?.PID_DATA?.IMAGE_DETAILS?.IMAGE?.reduce((acc, image) => {
                            acc[image.IMAGE_CODE] = image.IMAGE_TYPE;
                            return acc;
                        },{});
                        console.log('Extracted imageMap -->', this.imageMap);
                        console.log('Extracted imageMap -->', JSON.stringify(this.imageMap));
                        console.log('Extracted imagetypemap -->', this.imagetypemap);
                        console.log('Extracted imagetypemap -->', JSON.stringify(this.imagetypemap));
                        this.updateDocumentChecklist();
                    } else {
                        console.log('else initateCKYC error');
                    }
                })
                .catch(error => {
                    console.error('initateCKYC error -->' + JSON.stringify(error));
                })
        }*/
    
    updateDocumentChecklist() {
        if (this.imageMap != null) {
            documentCheckListUpdation({
                    documentMap: this.imageMap,
                    imagetypeMap : this.imagetypemap,
                    loanId: this.recordId,
                    applicantId: this.appId,
                    documentType: 'CKYC'
                })
                .then(res => {
                    console.log('updateDocumentChecklist success -->' + JSON.stringify(res));
                })
                .catch(error => {
                    console.error('updateDocumentChecklist error -->' + JSON.stringify(error));
                });
        } else {
            console.log('No imageMap found');
            this.fetchagain = false;
        }
    }
    getPanResp(){
        this.isloading = true;
        getPanResp({
            loanId: this.recordId,
            apDetId: this.applicantId
        })
        .then(response => {
            this.isloading = false;
            this.showTable = true;
            this.panResponse = response;
            if(this.loginChecklist && (this.panResponse== null || this.panResponse == '' || this.panResponse.length ==0)){
                this.errorList = 'PAN Validation is pending as of now.';
                this.showTable = false;
                this.showError= true;
            }
        })
        .catch(error => {
            this.isloading = false;
            console.error('Error fetching PAN response:', error);
        });
        //this.isloading = true;
       
    }
  
    get nameMatchClass() {
        return this.isPositive(this.panResponse.nameMatch) ? 'positive' : 'negative';
    }

    get dobMatchClass() {
        return this.isPositive(this.panResponse.dobMatch) ? 'positive' : 'negative';
    }

    get duplicateClass() {
        return this.isPositive(this.panResponse.duplicate) ? 'positive' : 'negative';
    }

    get statusClass() {
        return this.isPositive(this.panResponse.status) ? 'positive' : 'negative';
    }

    isPositive(value) {
        return value && (value.includes('Match') || value.includes('Non Duplicate') || value.includes('Valid'));
    }

    handleNext(event){
        event.stopPropagation();
        
        const valueChangeEvent2 = new CustomEvent("callcibileligibilitcmp", {
         detail: {
             value: this.recordId,
             name: 'Cibil Eligibility',
             currentAppSeq: this.currentAppSeq
         }
     });
     this.dispatchEvent(valueChangeEvent2);
    }
    validatePAN() {
    this.showError = true;
    this.showTable = false;

    this.errorList = [
        'We have performed an PAN check, and this customer is eligible for availing a Housing Loan. Kindly proceed to the next steps.'
    ];
    this.showValidateButton = false;
}

    showToast(title, message, variant) {
    this.dispatchEvent(
        new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        })
    );
}
}