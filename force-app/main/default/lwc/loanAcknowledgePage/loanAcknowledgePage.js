import { LightningElement,wire,track,api} from 'lwc';
//import { CurrentPageReference } from 'lightning/navigation';
import 	Godrej from '@salesforce/resourceUrl/Godrej';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import otpMsg from '@salesforce/label/c.OTP_valid';
import GU_Mobile_Ver_Msg from '@salesforce/label/c.GU_Mobile_Ver_Msg';
import getExisitingCustOfferDetails from '@salesforce/apex/COMM_SalesLoanActionsController.getExisitingCustOfferDetails'; 
import FORM_FACTOR from '@salesforce/client/formFactor';
import saveOfferDetails from '@salesforce/apex/COMM_SalesLoanActionsController.saveOfferDetails'; 
import updateConsentFields from '@salesforce/apex/Utility.updateConsentFields';
import getCustomerDetails from '@salesforce/apex/Utility.getCustomerDetails';
import USER_ID from '@salesforce/user/Id';
import { updateRecord } from 'lightning/uiRecordApi';
import getExistingLoanDetails from '@salesforce/apex/GetExistingLoanDetailsController.getExistingLoanDetails'
import initiateAPIRequest from '@salesforce/apex/OTPAPIController.initiateGenerateOTPValidation';
import initiateVerifyAPIRequest from '@salesforce/apex/OTPAPIController.initiateOTPValidation';
import consentFromAppDet from '@salesforce/apex/COMM_SalesLoanActionsController.checkConsentAppdetails';
import consentFromStatusCheck from '@salesforce/apex/COMM_SalesLoanActionsController.checkConsentStatus';
import {isValidMobileNumber} from 'c/utility';

//const THANK_YOU_SITE  = `${window.location.origin}/loanack/thankyou`;

export default class LoanAcknowledgeForm extends LightningElement {
    consentReceived = false;
    currentDate = new Date();
    @api recordId;
    expireTime = '';
    ackMap = '';
    isLinkExpired = false;
    isNotLinkExpired = true;
    isRendered=false;
    isModeChanged = false;
    imageURL = 	Godrej;
    label = {
        otpMsg,
        GU_Mobile_Ver_Msg,
    };
    userId = USER_ID;
    showMobileOtpVer = true;
    //leadId = '00QBi00000CPz4cMAD';
    data; 
    @track timerValue = '00';
    isShowcode = true;
    isMobile = false;
    verificationOTP = true;
    verifCode;
    showBox = true;
    reset = 'Resend OTP';
    @track countdown;
    @track shownonresend = true;
    resend = false;
    showverif = true;
    showverify = false;
    optverif = false;
    decodedId;
    @track applicantDetId;
    @track parentScreen;
    offerRelated
    @track toastKey;
    @track toastTitle;
    @track toastMessage;
    @track toastVariant;
    @track showTostTrue=false;
    customerDetails = {};
    @api applicantId;
    @track showVerifiedOTP = false;
    offerId;
    @api showConsent;
    @api leadId;
    loanAmount;
    loanTenure;
    loanROI;
    loanValidTill;
    uploadDoc;
    offerRelatedBoolean = false;
    @track selectedOptions = {
        changeAddress: false,
        changeLoanAmount: false,
        changeStructure: false
    };

    @track isAcceptOfferSelected = false;
    @track inputValues = {};
    @track hideView = false;
    @track showTNCSubmit = false;
    @track isNonIndividual = false;
    @track confirmationMessage= '';
    @track disableCheckBox = false;
    @track disableSendButton = false;
    @track privacyPolicy="https://housingfinance.godrejcapital.com/information_and_policies/content/ghfl/ghfl-privacy-note-2025.pdf";
    loanNumber;
    existingloanDetails;
    isSenpCustomer;

    connectedCallback(){
        console.log('inside connected callback::'+this.userId);
        console.log('showMobileOtpVer '+this.showMobileOtpVer);
        console.log('lead Id>'+this.leadId);
        if (FORM_FACTOR == 'Large') {
            this.isMobile = false;
        } else {
            this.isMobile = true;
        }
        
        //this.getCustomerDetails();
        
        
        console.log('URL:', window.location.href); // Log the URL for debugging
        console.log('URLsearch:', window.location.search);
        // Extract the `id` parameter from the URL
        const urlParams = new URLSearchParams(window.location.search);
        // const urlParams = new URLSearchParams(window.location.href);
        console.log('urlParams -->'+JSON.stringify(urlParams));
        console.log('url parems --:',urlParams);
        const encodedId = urlParams.get('id');
        this.parentScreen = urlParams.get('parentScreen');
        this.applicantDetId = urlParams.get('applicantDetId');

        this.offerRelated= urlParams.get('offerRelated');
        // this.offerRelated = Boolean(this.offerRelated);
        if (this.offerRelated == 'true') {
            this.offerRelatedBoolean = true;
        } else {
            this.offerRelatedBoolean = false;
        }
        this.offerId= urlParams.get('offerId');
        console.log('Encoded ID from URL:', encodedId);
        console.log('this.parentScreen:', this.parentScreen);
        console.log('this.applicantDetId:', this.offerRelated);
        console.log('this.offerId:', this.offerId);
        if(this.showConsent == 'Not Required') {
            this.showVerifiedOTP = true;
            this.hideView = true;
        } else {
            console.log('inside else');
            this.hideView = false;
            if(this.applicantId == null) {
                this.applicantId = this.applicantDetId;
            }
            this.checkConsentFromAppdet();
            this.checkConsentStatus();
            this.getExisitingCustOfferDetails();
            
        }
        console.log('recordId',this.recordId);
        if (encodedId) {
            // Decode the encoded ID locally
            this.decodedId = this.decodeBase64(encodedId);
            console.log('Decoded ID: ayush', this.decodedId);
            console.log('this.applicantId found new--> '+this.applicantId);
            // this.getCustDet();
            this.getCustDetFromappId();
        }else if(this.applicantId != null || this.leadId !=null) {
            console.log('this.applicantId found --> '+this.applicantId);
            
            this.getCustDetFromappId();
        } else {
            console.error('No "id" parameter found in the URL');
        }
        // this.getExisitingCustOfferDetails();
    }
    getExisitingCustOfferDetails(){
        console.log('this.offerId: 126', this.offerId);
        getExisitingCustOfferDetails({offerId:this.offerId})
        .then(result => {
            console.log('result 118---',JSON.stringify(result));
            this.loanAmount = result.laAmount;
            this.loanTenure = result.loanTenure;
            this.loanROI = result.loanROI;
            this.loanValidTill = result.validTill;
        
            })
        .catch (error => {
        })
    }
    checkConsentFromAppdet(){
        console.log('this.applicantId',this.applicantId);
        consentFromAppDet({appDet : this.applicantId})
        .then(result => {
            console.log('result from checkConsentFromAppdet'+result);
            this.showVerifiedOTP = result;
        }).catch(error=>{
            console.error('consentFromAppDet error'+JSON.stringify(error));
        })
    }
    checkConsentStatus(){
        console.log('this.applicantId',this.applicantId);
        consentFromStatusCheck({appDet : this.applicantId})
        .then(result => {
            console.log('result from checkConsentStatus'+result);
            this.isNotLinkExpired = !result;
        }).catch(error=>{
            console.error('consentFromAppDet error'+JSON.stringify(error));
        })
    }
    getCustDet(){
        console.log('inside cust info');
        console.log('this.decodedId --> '+this.decodedId);
        // console.log('this.applicantDetId getCustDet --> '+this.applicantDetId)
        getCustomerDetails({ recordId: this.decodedId })
        // getCustomerDetails({ recordId: this.applicantDetId })
        .then((result) => {
            this.customerDetails = result;
            console.log('getCustDet this.customerDetails.custType: '+this.customerDetails.custType);
            if(this.customerDetails.custType == 'Non Individual') {
                this.isNonIndividual = true;
            } else {
                this.isNonIndividual = false;
            }
            if(this.customerDetails.customerProfile == 'SENP'){
                this.isSenpCustomer = true;
            }else{
                this.isSenpCustomer = false;
            }
            console.log('customerDetails : ', this.customerDetails);
        }).catch(error=>{
            console.error('getCustomerDetails error'+JSON.stringify(error));
        })
    }

    getCustDetFromappId(){
        console.log('this.applicantId getCustDetFromappId --> '+this.applicantId);
        console.log('leadId id>'+this.leadId);
        let recordId = (this.leadId === null || this.leadId === '' || this.leadId === undefined) ? this.applicantId : this.leadId;
        //let recordId = (this.recordId === null || this.recordId === '') ? this.applicantId : this.recordId;
        
        console.log('recordId>',recordId);
        getCustomerDetails({ recordId: recordId })
        .then((result) => {
            this.customerDetails = result;
            console.log('getCustDetFromappId this.customerDetails.custType: '+this.customerDetails.custType);
            if(this.customerDetails.custType == 'Non Individual') {
                this.isNonIndividual = true;
            } else {
                this.isNonIndividual = false;
            }
            if(this.customerDetails.customerProfile == 'SENP'){
                this.isSenpCustomer = true;
            }else{
                this.isSenpCustomer = false;
            }
            this.confirmationMessage = 'Please verify your mobile number '+this.customerDetails.mobileNumberMasked + ' in order to proceed with your digital loan application.';
            console.log('getCustDetFromappId : ', this.customerDetails);
        }).catch(error=>{
            console.error('getCustomerDetails from appId error'+JSON.stringify(error));
        })
    }
    decodeBase64(encodedString) {
        try {
            // Decode Base64 to string
            return atob(encodedString);
        } catch (error) {
            console.error('Error decoding Base64:', error);
            return null;
        }
    }
    
   
    linkIsExpired(){
        this.isLinkExpired = this.currentDate > this.expireTime
    }

    
    init(){
        validateLoanAgreement({recordId:this.recordId}).then(response=>{
            this.isLinkExpired = response
            this.isNotLinkExpired = !response
        }).catch(error=>{
            console.error(JSON.stringify(error))
        })
    }

    clickAcknowledge(evt){
        this.consentReceived = evt.currentTarget.dataset.name
        this.sendAcknowledge()
    }

    sendAcknowledge(){
        this.setAckMap()
        this.isLinkExpired = false
        this.isNotLinkExpired = false
        acknowledgeLoan({inputMap : this.ackMap}).then(response=>{
            console.log(JSON.stringify(response))
            if(response.expiredLink){
                this.isModeChanged = true
            }else if(response.success){
                setTimeout(() => { this.isLinkExpired = true}, 2000);
                this.openResonpsePage()
            }
        }).catch(error=>{
            console.error(JSON.stringify(error));
        })
    }

    setAckMap(){
        this.ackMap = {
            'consentReceived' : this.consentReceived,
            'recordId' : this.recordId
        }
    }

    /*openResonpsePage(){
        window.open(THANK_YOU_SITE,"_self");
    }*/
    
    
    showToastMethod(toastTitle, toastMessage, toastVariant) {
        const evt = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    // get disableOTP() {
    //     var otpno = /^\d{6}$/;
    //     return this.verifCode != '' && this.verifCode != null && this.verifCode.match(otpno) && !this.disableOTPtimer;
    // }

    handleVerificationCodeChange(event) {
        const inputValue = event.target.value;
        if(!isValidMobileNumber(inputValue)){
            this.showTostTrue=true;
            this.showToast('error', 'Error!', 'Please fill the verification code in the correct format.');
            setTimeout(() => { this.showTostTrue=false;}, 5000);
            const scrollOptions = {
                left: 0,
                top: 0,
                behavior: 'smooth'
            }
            window.scrollTo(scrollOptions)
        }
        else {
            this.verifCode = event.target.value;
        }
    }

    sendVerCode(event) {
        this.verif = '';
        if(this.mytimeout){
            console.log('502');
            clearTimeout(this.mytimeout);
        }
        this.isShowcode = true;
        this.showBox = false;
        this.optverifs = true;
        this.showverify = true;
        this.otpnotverified=false;
        this.startTimer(30);
        this.showTostTrue=true;
        this.showToast('success', 'Success!', 'Verification Code sent successfully.');
        setTimeout(() => { this.showTostTrue=false;}, 5000);
        const scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
        // this.showToast('Success', 'Verification Code sent successfully', 'success');
            setTimeout(() => {
            // Check if the button has not been clicked
            if (!this.isVerifyCodeClicked) {
                this.resend = true;
                console.log('resend ' + this.resend);
                if (!this.shownewbox) { // Only proceed if shownewbox is still true
                    this.resentTimeout();
                }
            }
        }, this.otpTimeout);
    }
    
    resentTimeout() {
        this.mytimeout =  setTimeout(() => {
            console.log('521 ');
            this.optverifs = false;
            this.showverify = false;
            this.shownewbox = false; // Set shownewbox to false after the timeout
        }, this.otpTimeout);
    }

    startTimer(seconds) {
        this.showTimer = true;
        console.log('453 ' + seconds);
        this.countdown = seconds;
        this.isButtonDisabled = true;
        clearInterval(this.timer);
        this.timer = setInterval(() => {
            this.countdown -= 1;
            const minutes = Math.floor(this.countdown / 60);
            const seconds = this.countdown % 60;
            // Update timerValue to display only seconds
            //this.timerValue = `${seconds < 10 ? '0' : ''}${seconds}`;
            this.timerValue = `${minutes}:${seconds.toString().padStart(2,'0')}`;
            console.log('timerValue ' + this.timerValue);
            //this.timerValue = this.countdown;
            this.reset = 'Resend in ' + this.timerValue + ' seconds';
            console.log('reset ' + this.reset);
            this.shownonresend = true;
            console.log('this.countdown ' + this.countdown);
            if (this.countdown == 0) {
                console.log('this.countdown In loop ');
                clearInterval(this.timer);
                this.reset = 'Resend OTP';
                this.resend = true;
                this.shownonresend = false;
            }
        }, 1000);
    }
     
    disconnectedCallback(){
        clearInterval(this.timer);
    }

    SendConsentLink(){
        console.log('SendConsentLink recId'+this.recordId);
        console.log('SendConsentLink this.applicantId --> '+this.applicantId);
        this.disableSendButton = true;
        // this.showTostTrue=true;
        // this.showToast('success', 'Success!', 'OTP generated successfully.');
        // setTimeout(() => { this.showTostTrue=false;}, 5000);
        initiateAPIRequest({
            inputMap: {
                'processName': 'Loan Generate OTP',
                'sObjId':this.applicantId
            }
        }).then((response) => {
            console.log('response -->' + JSON.stringify(response));
            try {
                if(JSON.parse(response).status){
                    this.showTostTrue=true;
                    this.showToast('success', 'Success!', 'Verification code generated successfully.');
                    setTimeout(() => { this.showTostTrue=false;}, 5000);
                    const scrollOptions = {
                        left: 0,
                        top: 0,
                        behavior: 'smooth'
                    }
                    window.scrollTo(scrollOptions);
                    // this.dispatchEvent(
                    //     new ShowToastEvent({
                    //         title: 'Success',
                    //         message: 'OTP generated successfully.',
                    //         variant: 'success',
                    //     }),
                    // );

                    this.showverif = false;
                    this.showverify = true;
                    this.showBox = false;
                    this.disableSendButton = false;
                    this.startTimer(119);
                }else{
                    this.showTostTrue=true;
                    this.showToast('Error', 'Error!', 'Error while generating verification code. Please try again later.');
                    setTimeout(() => { this.showTostTrue=false;}, 5000);
                    const scrollOptions = {
                        left: 0,
                        top: 0,
                        behavior: 'smooth'
                    }
                    window.scrollTo(scrollOptions);
                    // this.dispatchEvent(
                    //     new ShowToastEvent({
                    //         title: 'Error',
                    //         message: 'Error while generating OTP. Please try again later.',
                    //         variant: 'error',
                    //     }),
                    // );
                }
            } catch (error) {
                console.error('Error deserializing the response:', error);
                this.showTostTrue=true;
                this.showToast('Error', 'Error!', 'Error while parsing the response. Please try again later.');
                setTimeout(() => { this.showTostTrue=false;}, 5000);
                const scrollOptions = {
                    left: 0,
                    top: 0,
                    behavior: 'smooth'
                }
                window.scrollTo(scrollOptions);
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Error',
                //         message: 'Error while parsing the response. Please try again later.',
                //         variant: 'error',
                //     }),
                // );
            }
            this.ShowLoader = false;
        }).catch(error => {
            this.ShowLoader = false;
            console.log('error -->' + error);
            console.error('error -->' + JSON.stringify(error));
        });
    }

    verifiycode(event){
        // this.verifCode = event.target.value;
        this.verifyCode();
    }

    // verifyCode() {
    //     const verificationCode = '123456'
    //     this.dispatchEvent(
    //         new ShowToastEvent({
    //             title: 'Success',
    //             message: 'OTP vaidated successfully.',
    //             variant: 'success',
    //         }),
    //     );
    //     this.showverify = false;
    //     this.showBox = false;
    //     this.optverif = true;
    //     // this.isNotLinkExpired = false;
    //     this.showMobileOtpVer = false;
    //     this.showVerifiedOTP = true;
    // 
    //     this.updateConsent();
    // }

    verifyCode() {
        console.log('verifCode',this.verifCode);
        if(!this.verifCode){
            this.showTostTrue=true;
            this.showToast('error', 'Error!', 'Please fill the verification code.');
            setTimeout(() => { this.showTostTrue=false;}, 5000);
            const scrollOptions = {
                left: 0,
                top: 0,
                behavior: 'smooth'
            }
            window.scrollTo(scrollOptions);
        }else if(this.verifCode && this.verifCode.length != 6){
            this.showTostTrue=true;
            this.showToast('error', 'Error!', 'Please fill the verification code in the correct format.');
            setTimeout(() => { this.showTostTrue=false;}, 5000);
            const scrollOptions = {
                left: 0,
                top: 0,
                behavior: 'smooth'
            }
            window.scrollTo(scrollOptions)
        }else if(this.verifCode && this.verifCode == '000000'){
            this.showTostTrue=true;
            this.showToast('error', 'Error!', 'Wrong verification code entered.');
            setTimeout(() => { this.showTostTrue=false;}, 5000);
            const scrollOptions = {
                left: 0,
                top: 0,
                behavior: 'smooth'
            }
            window.scrollTo(scrollOptions)

        }else{
            console.log('this.verifCode --> '+this.verifCode);
            console.log('this.applicantId'+this.applicantId);
            initiateVerifyAPIRequest({
                inputMap: {
                    'processName': 'Loan Validate OTP',
                    'generatedOTP': this.verifCode,
                    'applicantId':this.applicantId
                }
            }).then((response) => {
                console.log('response -->' + JSON.stringify(response));
                try {
                    if(JSON.parse(response).status){
                        /* this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'OTP vaidated successfully.',
                                variant: 'success',
                             }),
                        ); */
    
                        // this.showverify = false;
                        // this.showBox = false;
                        // this.optverif = true;
                        // this.isNotLinkExpired = false;
                        this.showverify = false;
                        this.showBox = false;
                        this.optverif = true;
                        this.showMobileOtpVer = false;
                        this.showVerifiedOTP = true;
    
                        
                        //this.saveOfferDetails();
                    }else if(!JSON.parse(response).status){
                        if(JSON.parse(response).message.includes('message')){
                            this.showTostTrue=true;
                            this.showToast('Error', 'Error!', 'Wrong verification code entered.');
                            setTimeout(() => { this.showTostTrue=false;}, 5000);
                            const scrollOptions = {
                                left: 0,
                                top: 0,
                                behavior: 'smooth'
                            }
                            window.scrollTo(scrollOptions);
                        }else{
                            this.showTostTrue=true;
                            this.showToast('Error', 'Error!', JSON.parse(response).message);
                            setTimeout(() => { this.showTostTrue=false;}, 5000);
                            const scrollOptions = {
                                left: 0,
                                top: 0,
                                behavior: 'smooth'
                            }
                            window.scrollTo(scrollOptions);
                        }
                        
                    }else{
                        this.showTostTrue=true;
                        this.showToast('Error', 'Error!', 'Error while validating verfication code. Please try again later.');
                        setTimeout(() => { this.showTostTrue=false;}, 5000);
                        const scrollOptions = {
                            left: 0,
                            top: 0,
                            behavior: 'smooth'
                        }
                        window.scrollTo(scrollOptions);
                    }
                } catch (error) {
                    console.error('Error deserializing the response:', error);
                    this.showTostTrue=true;
                    this.showToast('Error', 'Error!', 'Error while parsing the response. Please try again later.');
                    setTimeout(() => { this.showTostTrue=false;}, 5000);
                    const scrollOptions = {
                        left: 0,
                        top: 0,
                        behavior: 'smooth'
                    }
                    window.scrollTo(scrollOptions);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Error while parsing the response. Please try again later.',
                            variant: 'error',
                        }),
                    );
                }
                this.ShowLoader = false;
            }).catch(error => {
                this.ShowLoader = false;
                console.log('error -->' + error);
                console.log('error -->' + JSON.stringify(error));
            });
        }
        
    }
         
    updateConsent() {
         console.log('this.applicantId update consent--> '+this.applicantId)
        updateConsentFields({ recordId: this.applicantId })
        .then(() => {
            this.showTNCSubmit= false;
            console.log('Consent fields updated successfully');
            this.showTostTrue=true;
            this.showToast('success', 'Success!', 'Consent updated successfully');
            this.isNotLinkExpired = false;
            this.showVerifiedOTP = false;
            setTimeout(() => { this.showTostTrue=false;}, 5000);
            const scrollOptions = {
                left: 0,
                top: 0,
                behavior: 'smooth'
            }
            window.scrollTo(scrollOptions);
            // this.checkConsentFromAppdet();
            //this.showToast('Success', 'Consent updated successfully.', 'success');
        })
        .catch(error => {
            console.error('Error updating consent fields:', error);
            //this.showToast('Error', 'Failed to update consent fields.', 'error');
        });    
    }
    showToast(variant, title, message) {
        this.toastKey = Date.now();
        this.toastTitle = title;
        this.toastMessage = message;
        this.toastVariant = variant;
    }

    // handleCheckboxChange(event) {
    //     const { value, checked } = event.target;

    //     if (value === 'acceptOffer') {
    //         this.isAcceptOfferSelected = checked;
    //         if (checked) {
    //             this.selectedOptions = { changeAddress: false, changeLoanAmount: false, changeStructure: false };
    //             this.inputValues = {}; // Clear input values when accepting offer
    //         }
    //     } else {
    //         this.selectedOptions = { ...this.selectedOptions, [value]: checked };
    //     }
    // }

    // handleInputChange(event) {
    //     const field = event.target.dataset.field;
    //     this.inputValues = { ...this.inputValues, [field]: event.target.value };
    // }

    handleCheckboxChange(event) {
        console.log('Checkbox checked:', event.target.checked);
        if(event.target.checked){
            this.showTNCSubmit = true;
        }else{
            this.showTNCSubmit = false;
        }
        // this.isNotLinkExpired = false;
        
    }

    validateSaveAndNext(){
        if(!this.showTNCSubmit){
            this.showTostTrue=true;
            this.showToast('error', 'Error!', 'Please check the terms & conditions to proceed.');
            setTimeout(() => { this.showTostTrue=false;}, 5000);
            const scrollOptions = {
                left: 0,
                top: 0,
                behavior: 'smooth'
            }
            window.scrollTo(scrollOptions);
        } else if (this.customerDetails.consentStatus == 'Accepted') {
            this.showTostTrue = true;
            this.showToast('Success', 'Success!', 'Consent is already updated successfully');
            console.log('inside');
            this.isNotLinkExpired = false;
            this.showVerifiedOTP = false;
            setTimeout(() => { this.showTostTrue = false; }, 5000);
            const scrollOptions = {
                left: 0,
                top: 0,
                behavior: 'smooth'
            }
            window.scrollTo(scrollOptions);
            this.disableCheckBox = true;
            this.showTNCSubmit = false;
        } else {
            this.updateConsent();
            this.disableCheckBox = true;
        }
    }
    handleConfrim(event){
        console.log('Checkbox checked:', event.target.checked);
        
        // this.showVerifiedOTP = false;
    }
    handleCheckboxChangeOffer(event) {
        const { value, checked } = event.target;

        if (value === 'acceptOffer') {
            this.isAcceptOfferSelected = checked;

            if (checked) {
                // Uncheck and disable all other checkboxes
                this.selectedOptions = { changeAddress: false, changeLoanAmount: false, changeStructure: false };
                this.inputValues = {}; // Clear stored text inputs
            }
        } else {
            if (!this.isAcceptOfferSelected) {
                // Allow selection only if "Accept Offer" is not checked
                this.selectedOptions = { ...this.selectedOptions, [value]: checked };
            }
        }
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this.inputValues = { ...this.inputValues, [field]: event.target.value };
    }
    saveOfferDetails() {
        
        let status;
        let addRemarks  = this.selectedOptions.changeAddress ? this.inputValues.changeAddress : '';
        let loanAmount = this.selectedOptions.changeLoanAmount ? this.inputValues.changeLoanAmount : '';
        let structure = this.selectedOptions.changeStructure ? this.inputValues.changeStructure : '';
        if(this.isAcceptOfferSelected){
            status  = 'Offer Accepted';
        }
        else{
            status = 'Change Requested';
        }
        const inputMap = {
            offerId:this.offerId,
            status:status,
            addressRemarks :addRemarks,
            loanAmount:loanAmount,
            structure:structure,
            // 'base64': this.uploadDoc.split(',')[1],
        };
        

        alert('inputMap :'+JSON.stringify(inputMap))
      
        
        saveOfferDetails({
            inputMap: inputMap
        })
        .then(result =>{
            // alert('inputMap :'+result)
            if(result!=null && result!='' && result!=undefined){
                this.isNotLinkExpired = false;
                this.loanNumber = result;
                console.log(' this.loanNumber----', this.loanNumber);
                if(this.loanNumber!=null && this.loanNumber!='' && this.loanNumber!=undefined){
                    this.getExistingLoanDetails();
                }

            }
            else{
               
            }

         })
        .catch(error => {
                console.error('Error updating offer:', error);
               
            });
    }
    
    // showToast(title, message, variant) {
    //     const event = new ShowToastEvent({
    //         title: title,
    //         message: message,
    //         variant: variant,
    //         mode: 'dismissable'
    //     });
    //     this.dispatchEvent(event);
    // }

     renderedCallback(){
        console.log('IN CHILD RENDER CALL BACK');
        if(!this.isRendered){
            console.log('Inside if condition');
            this.isRendered = true;
            const style = document.createElement('style');
            style.innerText = `
            .uploadFile .slds-file-selector__text.slds-medium-show {
              display: none;
            }
            .uploadFile .slds-file-selector__button.slds-button.slds-button_neutral{
                font-size: 0!important;
            }
            .uploadFile svg.slds-button__icon.slds-button__icon_left {
                margin: 0;
            }
            .uploadFile lightning-primitive-file-droppable-zone.slds-file-selector__dropzone {
                border: none;
                padding: 0;
            }
            .uploadFile slds-form-element__label{
                display: none;
            }
            .info-button svg.slds-button__icon.slds-button__icon_left {
                margin: 0;
            }
            .class-file-upload .slds-form-element__label:empty {
                margin: 0;
                display: none;
            }
            .uploaded-view svg.slds-button__icon.slds-button__icon_left {
                color: green;
            }
            .uploaded-view svg.slds-button__icon.slds-button__icon_left {
                margin-top: 2%;
            }
            .uploaded-view svg.slds-button__icon {
                color: green;
            }
                .uploaded-view-disabled svg.slds-button__icon.slds-button__icon_left {
                color: grey;
            }
            .uploaded-view-disabled svg.slds-button__icon {
                color: grey;
            }
            `;
            this.template.querySelector('.styleContainer').appendChild(style);
        }
    }
    handleFileUpload() {
        this.template.querySelector('input[type="file"]').click();
    }
    handleUploadFinished(event) {
        const file = event.target.files[0];
        if (!file) return;
        
        const reader = new FileReader();
        reader.onload = () => {
            this.fileName = file.name;
            this.uploadDoc = reader.result; // Base64 string
            setTimeout(() => {
                this.createContentVersion();
            }, 500);
            
            console.log('this.uploadDoc:', this.uploadDoc);
            console.log('file.type:', file.type);
            
            this.isImage = file.type.startsWith('image');
            this.isPDF = file.type === 'application/pdf';
        };
        
        reader.readAsDataURL(file);
        this.saveDetails();
    }

    submitTC(event) {
        // this.showTNCSubmit = true;
        this.isNotLinkExpired = false;
    }
    getExistingLoanDetails(){
        console.log('Inside appdetails loan detailso00000');
        getExistingLoanDetails({loanNumber:this.loanNumber})
        .then(result => {
            console.log('result',JSON.stringify(result));
            if(result!=null && result!='' && result!=undefined){
                this.existingloanDetails= result;
                console.log(' this.existingloanDetails', this.existingloanDetails);
            }
            if( this.existingloanDetails!=null &&  this.existingloanDetails!='' &&  this.existingloanDetails!=undefined){
                this.tagLoanDetailsOnExistingLoan();
                console.log(' this.existingloanDetails', this.existingloanDetails);
            }

            
           
        })
        .catch(error => {
            console.log('error:',error);
            this.isNotLinkExpired = false;
        })
    }

    
}