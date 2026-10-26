import { LightningElement, track, api,wire } from 'lwc';
import RESEND_OTP_TIMER from '@salesforce/label/c.Resend_OTP_Timer';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { validateVoterIdNumber, validatePassportNumber,panNumberValidation,validateDLNumber} from 'c/utility';
import getTriangulationDataRecord from '@salesforce/apex/COMM_SalesLoanActionsController.getTriangulationDataRecord';
import processCkycFetchRecordAPI from '@salesforce/apex/COMM_CKYCFetchRecordController.processCkycFetchRecordAPI'; 
import processCkycSearchAPI from '@salesforce/apex/COMM_CKYCSearchAPIController.processCkycSearchAPI'; 
import processRefreshOtp from '@salesforce/apex/COMM_CKYCResendOtpController.processCommercialCrifResponse'; 
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import APPLICATION_APPLICANT from '@salesforce/schema/Application_Applicant__c';
import CKYC_DOCUMENT_TYPE_FIELD from '@salesforce/schema/Application_Applicant__c.CKYC_Document_Type__c';

export default class SalesCKYCDetailsCmp extends LightningElement {
    @api recordId;
    @api dobOrdoi;
    @api applicantId;
    @api isCkycInitiated;
    @track idType = '';
    @track idNumber = '';
    @api isNonIndividual;
    @track idValueChanged = false;
    get customerTypeLabel() {
        return this.isNonIndividual ? 'Non Individual' : 'Individual';
    }

    @api isMnrlBlacklisted;
    @track isloading = false;
    @track isModalLoading = false;
    @track apiAlreadyHit = false;
    @track ckycNumber = '';
    @track otpValue = '';
    imageMap;
    imagetypemap;
    @track isFetchButtonDisabled = true;
    @track isIdTypeDisabled = false;
    @track idNumberDisabled = false;
    @track ckycTransactionId = '';
    @track submitDisabled = true;
    @track apiCount;
    @track showModal = false;
    @track isTimerDisabled = true;
    @track hitSearchApi = true;
    @track idTypeOptions =[];
    customerTypeController=[];
    intervalId;
    
    @track isResendDisabled = true;
    @track timerDisplay = '00:00';
    get initiateCkycButtonDisabled() {
        return this.idType === '' || this.idNumber === '' || this.apiAlreadyHit;
    }
    @track idTypeOptions = [
        { label: 'PAN', value: 'PAN' },
        { label: 'Passport', value: 'Passport' },
        { label: 'Voter ID', value: 'Voter ID' }
    ];
    
    @wire(getObjectInfo, { objectApiName: APPLICATION_APPLICANT })
    objectInfo;
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CKYC_DOCUMENT_TYPE_FIELD})
    residentialStatusPickList({ data, error }) {
        console.log('field',CKYC_DOCUMENT_TYPE_FIELD);
        console.log('data',data);
        if (data){
            this.idTypeOptions = data.values;
            this.customerTypeController = data.controllerValues;
           // const label = this.customerTypeLabel;
 
            this.idTypeOptions = this.idTypeOptions.filter(opt => opt.validFor.includes(this.customerTypeController[this.customerTypeLabel]));
        }
    }

    connectedCallback() {
        this.getTriangulationRec();
    }

    /* Line-format restyle for the C-KYC Details fields (ID Type combobox,
       ID Number input) - converts the boxed dark fields to underline-only,
       matching the border/focus colors already established for this
       component (#2a2f45 idle border, #1467eb focus border - same tokens
       already used via the --slds-c-input-color-border / combobox hooks
       in salesCKYCDetailsCmp.css). A plain CSS custom-property hook alone
       does not reach every part of the rendered box (border-radius/
       background), so the style is injected the same proven way already
       used elsewhere in this codebase. This method is fully self-
       contained and does not touch connectedCallback or any other
       lifecycle/data logic. */
    isRendered = false;
    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            const style = document.createElement('style');
            style.innerText = `
                .slds-input,
                .slds-combobox__input {
                    background-color: transparent !important;
                    color: #ffffff !important;
                    border: none !important;
                    border-bottom: 1px solid #2a2f45 !important;
                    border-radius: 0 !important;
                    box-shadow: none !important;
                    outline: none !important;
                    padding: 6px 2px !important;
                }
                .slds-input:hover,
                .slds-input:active,
                .slds-input:disabled,
                .slds-combobox__input:hover,
                .slds-combobox__input:active,
                .slds-combobox__input:disabled {
                    background-color: transparent !important;
                    color: #ffffff !important;
                    border: none !important;
                    border-bottom: 1px solid #2a2f45 !important;
                    box-shadow: none !important;
                }
                .slds-input:focus,
                .slds-combobox__input:focus {
                    background-color: transparent !important;
                    border: none !important;
                    border-bottom: 1px solid #1467eb !important;
                    box-shadow: none !important;
                }
                .slds-form-element__label {
                    color: #ffffff !important;
                }
            `;
            const container = this.template.querySelector('.styleContainer');
            if (container) {
                container.appendChild(style);
            }
        }
    }

    getTriangulationRec(){
        getTriangulationDataRecord({ loanId: this.recordId, applicantId: this.applicantId })
        .then(result => {
            if(result && result.length > 0){
                this.ckycTransactionId = result[0].CKYC_Transaction_Id__c!='' ? result[0].CKYC_Transaction_Id__c: '';
                this.apiCount =  result[0].API_hit_count__c;
                this.idType = result[0].CKYC_Doc_Type__c;
                this.idNumber = result[0].CKYC_Doc_ID__c;
                this.apiAlreadyHit = result[0].CKYC_Number__c && result[0].CKYC_Number__c.trim() !=='' || result[0].CKYC_Reference_Id__c && result[0].CKYC_Reference_Id__c.trim() !=='' ;
                if(this.apiAlreadyHit ==true){
                    this.isIdTypeDisabled = true;
                    this.idNumberDisabled = true;
                }
                
                if (this.apiCount===0 || this.apiCount % 3 === 0) {
                    this.hitSearchApi = true;
                    console.log( 'hitsearchBoolean inside get triangulationdata',this.hitSearchApi);
                }
                else{
                    this.hitSearchApi = false;
                }
            }
            
            console.log('transaction Id>>', this.ckycTransactionId);
        
        })
        .catch(error => {
            console.error('Error fetching getTriangulationRec:', error);
            
        });
    }
    

    handleOtpValueChange(event) {
        this.otpValue = event.target.value;
        const isValidOtp = /^\d{6}$/.test(this.otpValue);
        this.submitDisabled = !isValidOtp;
    }

    handleIdTypeChange(event) {
        this.idType = event.detail.value;
    }

    handleIdNumberChange(event) {
        this.idNumber = event.target.value;
        if(event.target.value && this.apiCount !=0 &&  this.apiCount % 3 !== 0){
            this.apiCount = 0;
            this.hitSearchApi = true; //since ID no changed so API will be hit again.
            this.idValueChanged = true;
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'pester'
        });
        this.dispatchEvent(evt);
    }

    closeModal() {
        this.getTriangulationRec(); //calling this to get the latest api hit number
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = null;
        }
        this.showModal = false;
    }

    startResendTimer() {
        let seconds = parseInt(RESEND_OTP_TIMER, 10);
        this.isResendDisabled = true;
        //this.timerDisplay = `00:${seconds < 10 ? '0' + seconds : seconds}`;
        const formatTime = (secs) => {
            const mins = Math.floor(secs / 60);
            const secsLeft = secs % 60;
            return `${mins}:${secsLeft < 10 ? '0' + secsLeft : secsLeft}`;
        };
    
        this.timerDisplay = formatTime(seconds);
        this.intervalId = setInterval(() => {
            seconds--;
            this.timerDisplay = formatTime(seconds);
            //this.timerDisplay = `00:${seconds < 10 ? '0' + seconds : seconds}`;
            if (seconds <= 0) {
                clearInterval(this.intervalId);
                this.isResendDisabled = false;
            }
        }, 1000);
    }

    validateIdDetails() {
        let isValid = false;
        switch (this.idType) {
            case 'Passport':
                isValid = validatePassportNumber(this.idNumber);
                break;
            case 'Voter ID':
                isValid = validateVoterIdNumber(this.idNumber);
                break;
            case 'PAN':
                isValid = panNumberValidation(this.idNumber);
                break;
            case 'Driving Licence':
                isValid = validateDLNumber(this.idNumber);
                break;           
            default:
                isValid = true; //valid for all other casesss
        }
        return isValid;
    }

    handleInitiateCkyc(){
        const isValid = this.validateIdDetails();
        if (isValid) {
            console.log('inside handleInitiateCkyc');
            //this.showModal = true;
            this.validationError = '';
            this.initiateSearchApi();
            // Notify parent so stage accordions after C-KYC Details can be revealed
            this.dispatchEvent(new CustomEvent('ckycinitiated', {
                detail: { applicantId: this.applicantId }
            }));
        } else {
            console.log('inside handleInitiateCkycelse');
            this.showToast('Invalid ID Number Entered', `Invalid ${this.idType}. Please check and try again.`, 'error');
            //this.validationError = `Invalid ${this.idType}. Please check and try again.`;
            this.showModal = false;
        }
    }

    initiateSearchApi() {
        if(this.hitSearchApi == true){ /*also ek wo scenario handle krle bhai when you click on modal open 
        after much later after cancelling.. so put a filter of lastmodified date on triangulation data*/
            this.isloading = true;
            let inputMap = {
                loanId: this.recordId,
                processName: 'CKYC Search',
                applicantId: this.applicantId,
                idType: this.idType,
                idNumber: this.idNumber,

            };
            processCkycSearchAPI({ inputMap: inputMap})
            .then(response => {
                try {   
                    this.isloading = false;
                    console.log('response>>',response);
                    if (response.toLowerCase().includes('success')) {
                         console.log('this.customerTypeLabel>>',this.customerTypeLabel);
                        if(this.customerTypeLabel =='Individual'){
                            //const parts = response.split(':');
                            //if (parts.length > 1) {
                                this.ckycTransactionId = '123456';
                                this.showToast('Success', 'CKYC initiated successfully', 'success');
                                //console.log('Transaction ID:?>>>>', this.ckycTransactionId);
                                //this.showModal = true;
                               // this.startResendTimer();
                            //}
                        }
                        else{ //Non Indivi
                           // const parts = response.split(':');
                            if (parts.length > 1) {
                                this.ckycTransactionId = '123456';
                                this.showToast('Success', 'API Successfully Initiated for Corporate Applicant', 'success');
                               // this.showModal = true;
                                //this.startResendTimer();
                            }
                        }
                        
                    }
                    else if(response.includes('No record found')){
                        this.showToast('Error', 'CKYC has no data w.r.t to the mentioned ID Type and Number', 'error');
                    }
                    else {
                        this.showToast('Error', response, 'error');
                        console.warn('CKYC API returned non-success status:');
                    }
                        
                    } catch (e) {
                        this.isloading = false;
                        console.error('Error parsing CKYC API response:', e);
                    }
                    this.getTriangulationRec();
            })
            .catch(error => {
                this.isloading = false;
                console.error('Error calling API:', error);
                let errorMessage = error.body ? error.body.message : 'Unknown error';
                this.showToast('Error', errorMessage, 'error');
            });
        }
        else{
            this.showToast('Success', 'CKYC Search API has already been hit! Please enter the OTP Received on your registered Mobile No.', 'success');
            this.getTriangulationRec();
            this.showModal = true;
            //this.startResendTimer();
            this.isResendDisabled = false;
        }

    }
    remainingAttempts;
    handleResendOtp() {
        this.isModalLoading = true;
        let inputMap = {
            loanId: this.recordId,
            processName: 'CKYC ResendOtp',
            applicantId: this.applicantId,
            ckycTransactionID : this.ckycTransactionID
        };
        processRefreshOtp({ inputMap: inputMap})
        .then(response => {
            try {
                if(response){
                    this.isModalLoading = false;
                    //this.showToast('Success', response, 'success');
                    if(response.includes('Success')){
                        const match = response.match(/remaining attempts\s*=\s*(\d+)/);
                        if (match && match[1]) {
                            this.remainingAttempts = parseInt(match[1], 10);
                            console.log('Remaining Attempts:', this.remainingAttempts);
                        }
                        this.showToast('Success', response, 'success');
                        //this.showToast('OTP Sent', 'A new OTP has been sent successfully.', 'success');
                        this.startResendTimer();
                    }
                    else{
                        this.showToast('Error', response, 'error');
                        if(response.includes('Please provide valid CKYCTransactionID')){
                        this.showModal = false;
                        }
                        this.startResendTimer();
                    }
                }
                this.isModalLoading = false;
                } catch (e) {
                    this.isModalLoading = false;
                    console.error('Error parsing processRefreshOtp rec API response:', e);
                }
        })
        .catch(error => {
            this.isModalLoading = false;
            console.error('Error calling processRefreshOtp API:', error);
            let errorMessage = error.body ? error.body.message : 'Unknown error';
            this.showToast('Error', errorMessage, 'error');
        });
       
    }

    callAPI(){
        this.isloading = true;
        this.showModal = false;
        let inputMap = {
            loanId: this.recordId,
            processName: 'CKYC Fetch',
            applicantId: this.applicantId,
            otpNumber : this.otpValue
        };
        processCkycFetchRecordAPI({ inputMap: inputMap})
        .then(response => {
            try {
                if(response){
                    this.isloading = false;
                    if(response.includes('Success')){
                        this.showToast('Success', response, 'success');
                        this.isIdTypeDisabled = true;
                        this.idNumberDisabled = true;
                        this.apiAlreadyHit = true;
                    }
                    else{
                        this.showToast('Error', response, 'error');
                    }
                }
                this.isloading = false;
            } catch (e) {
                this.isloading = false;
                console.error('Error parsing CKYC fetch rec API response:', e);
            }
             this.showModal = false;
        })
        .catch(error => {
            this.isloading = false;
            console.error('Error calling CKYC fetch API:', error);
            let errorMessage = error.body ? error.body.message : 'Unknown error';
            this.showToast('Error', errorMessage, 'error');
            this.showModal = false;
        });
    }

}