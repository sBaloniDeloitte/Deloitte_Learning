import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCustomerList from '@salesforce/apex/COMM_SalesLoanLoginController.getApplicantDetailsForOtpConsent';
import otpMsg from '@salesforce/label/c.OTP_valid';
import FORM_FACTOR from '@salesforce/client/formFactor'
//import getVerifiedConsentLink from '@salesforce/apex/fetchleaddetails.getVerifiedConsentLink';
import getLoanAndApplicantDetails from '@salesforce/apex/COMM_SalesLoanLoginController.getLoanAndApplicantDetails';
import checkOTPVerified from '@salesforce/apex/COMM_SalesLoanLoginController.checkOTPVerified';
import checkconsentVerified from '@salesforce/apex/COMM_SalesLoanLoginController.checkconsentVerified';
import otpReceived from '@salesforce/apex/COMM_SalesLoanLoginController.otpReceived';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
//import Loanack from '@salesforce/label/c.Loan_Ack_URL';
import UpdateMode from '@salesforce/apex/COMM_SalesLoanLoginController.updateMode';
//import UpdateModOTP from '@salesforce/apex/Sales_LoanLoginController.updateModOTP';
//import UpdatChangeMode from '@salesforce/apex/Sales_LoanLoginController.updatChangeMode';
import encodeRecordId from '@salesforce/apex/Utility.encodeRecordId';
import getApplicantValues from '@salesforce/apex/COMM_SalesLoanLoginController.getApplicantValues';
// import initiateAPIRequest from '@salesforce/apex/IntegrationHandler.initiateAPIRequest';
import sendLoanOfferEmail from '@salesforce/apex/SalesOTPController.sendLoanOfferEmail';
import getNextScreenDetails from '@salesforce/apex/COMM_SalesLoanActionsController.getNextScreenDetails';
import initiateWhatsAppRequest from '@salesforce/apex/WhatsAppController.initiateWhatsAppRequest';
import whatsappConsentSms from '@salesforce/label/c.whatsapp_consent_sms';
import termsLink from '@salesforce/label/c.TermsLink';



export default class SalesOtpConsent extends NavigationMixin(LightningElement) {

    label = {
        otpMsg
    };
    /*label2={
        Loanack  
    }; */

    @api recordId;
    @api loginChecklist;
    @api isShowModal;
    @api parentScreen;
    //parentScreen = 'Lead Screen'; // Added by Kshitiz for lead Module.
    @api isOfferRelated = false;
    @track showConsentModal = false;
    checkSpinner = false;
    sendOtpLabel = 'Send OTP';
    sendconsentLink = 'Send Consent Link';
    showSendOtp;
    sendOtpButtons;
    @track consentStatus ='';
    isDesktop;
    isMobile;
    @api offerId;
    @api loanApplicationId;
    @track custOptions = [];
    mobileNumber;
    applicantType;
    recordApplicationId;
    enteredOtp;
    disableVerifyOtp = true;
    @track showConsentverify = false;
    verifiyconsentcodes = false;
    resendlinks = false;
    @track otpSessionId;
    consentSent;
    columns = [
        { label: 'Name', fieldName: 'applicantName' },
        { label: 'Applicant type', fieldName: 'applicantType' },
        { label: 'Mobile number', fieldName: 'mobileNumber' },
        { label: 'Consent', fieldName: 'otpVerified' }
    ];
    next = 0;
    dropdownOptions = [
        { label: 'OTP Based', value: 'sendOtp' },
        { label: 'Consent Link Based', value: 'sendConsentLink' }
    ];
    showtable = false;
    changemodebutton = 'Change Mode';
    showSendConsent = false;
    isDropdownDisabled = false;
    selectedAction = null; // Default null - user must explicitly choose a mode via the dropdown before the table/functionality is forced
    //showConsentverify = false;
    resendlinks = false;
    saveandnext = "Check Bureau Health";
    customers;
    showdropdown = true;
    orgDomainName;
    orgDomainName2;
    @track countdown;
    @track showTimer = false;
    timer;
    @track timerValue = '00:00';
    @track otpsended = false;
    @track comboboxClass = 'inputSize inputSize-with-margin';
    @track originalMobileNumber;
    @track customerEmail;
    @api applicantDetId;
    @track encodedId;
    @api currentAppSeq;
    @api isdisable;
    @api leadId;

    get isConsentDisabled() {
        return this.isdisable === true || this.isdisable === 'true';
    }

    get isConsentAccepted() {
        return !!(this.custOptions && this.custOptions.length > 0 && this.custOptions[0].otpVerified);
    }

    isloading = false;
    showNextButton = false;
    pendingStatus = 'Pending';
    consentLinkMode = 'Consent Link';
    otpMode = 'OTP';
    _pageRef;
    @wire(CurrentPageReference)
    wiredPgeRef(v) {
        this._pageRef = v;
    }

    get effectiveRecordId() {
        // Try standard Lightning URL
        let lightningId = window.location.href.match(/\/lightning\/r\/\w+\/([a-zA-Z0-9]{15,18})\/view/)?.[1];
        // Try community URL: /losportal/s/opportunity/{recordId}/...
        let communityId = window.location.href.match(/\/opportunity\/([a-zA-Z0-9]{15,18})\//)?.[1];
        return (
            this.recordId ??
            this._pageRef?.state?.recordId ??
            this._pageRef?.state?.c__recordId ??
            this._pageRef?.state?.id ??
            lightningId ??
            communityId ??
            null
        );
    }
    connectedCallback() {
        console.log('in connectedCallback' + this.recordId);
        console.log('in connectedCallback leadID' + this.leadId);
        this.orgDomainName = window.location.origin;
        //this.orgDomainName2 = this.label2.Loanack;
        console.log('applicantDetId -->' + this.applicantDetId);
        console.log('orgDomainName 1' + this.orgDomainName);
        // console.log('orgDomainName '+this.orgDomainName);
        if (FORM_FACTOR === "Large") {  //  // this.deviceType = "Desktop/Laptop";
            this.isDesktop = true;
            console.log(' this.isDesktop--' + this.isDesktop);
        } else if (FORM_FACTOR === "Medium") { //  this.deviceType = "Tablet";
            this.isMobile = true;
        } else if (FORM_FACTOR === "Small") {  //this.deviceType = "Mobile";
            this.isMobile = true;
        }
        this.getCustomerDetails();
        this.getApplicantDetailrecords();
        this.getApplicantValues();
        this.checkSpinner = true;
        setTimeout(() => {
            this.checkSpinner = false;
        }, 2000);
    }

    // ---- Client-side consent verification flag (JS-only fix) ----
    // Apex hardcodes otpVerified=true/status='Accepted' for new records in
    // several branches of getApplicantDetailsForOtpConsent(). Since Apex
    // cannot be modified, we track real verification locally so a brand new
    // consent starts blank/Pending until the user actually completes OTP or
    // Consent Link verification. Lead Screen branch is excluded because it
    // already reads real backend fields and is trustworthy as-is.
    isLocallyVerified(recordId) {
        if (!recordId) {
            return false;
        }
        try {
            return window.localStorage.getItem('slc_consentVerified_' + recordId) === 'true';
        } catch (e) {
            return false;
        }
    }

    markLocallyVerified(recordId) {
        if (!recordId) {
            return;
        }
        try {
            window.localStorage.setItem('slc_consentVerified_' + recordId, 'true');
        } catch (e) {
            // storage unavailable, ignore
        }
    }

    // Tracks that the user has clicked "Yes" to actually send the consent
    // link for this record - distinct from real verification. Lets us show
    // "Pending" (link sent, awaiting verification) instead of blank (never sent).
    isConsentLinkSentLocally(recordId) {
        if (!recordId) {
            return false;
        }
        try {
            return window.localStorage.getItem('slc_consentSent_' + recordId) === 'true';
        } catch (e) {
            return false;
        }
    }

    markConsentLinkSentLocally(recordId) {
        if (!recordId) {
            return;
        }
        try {
            window.localStorage.setItem('slc_consentSent_' + recordId, 'true');
        } catch (e) {
            // storage unavailable, ignore
        }
    }

    applyConsentOverride(list) {
        if (!list) {
            return list;
        }
        if (this.parentScreen === 'Lead Screen') {
            // Lead Screen already reads real backend fields - just attach the
            // display text for the table, no override of otpVerified.
            return list.map(opt => (opt ? { ...opt, displayStatus: opt.otpVerified ? 'Accepted' : (opt.status === 'Pending' ? 'Pending' : '') } : opt));
        }
        return list.map(opt => {
            if (!opt) {
                return opt;
            }
            const verified = this.isLocallyVerified(opt.recordApplicationId);
            const sent = this.isConsentLinkSentLocally(opt.recordApplicationId);
            return {
                ...opt,
                otpVerified: verified,
                displayStatus: verified ? 'Accepted' : (sent ? 'Pending' : '')
            };
        });
    }

    getApplicantValues() {
        console.log('this.leadId>>', this.leadId);
        const inputMap = {
            'applicantId': this.applicantDetId,
            'leadId': this.leadId
        }
        getApplicantValues({ inputMap: inputMap, parentScreen: this.parentScreen })
            .then(result => {
                console.log('result  127-->' + JSON.stringify(result));
                // Client-side override: Apex hardcodes consentStatus='Accepted' for
                // new records on non-Lead-Screen branches. Treat as not-accepted
                // until this browser has actually seen a real verification succeed.
                if (this.parentScreen !== 'Lead Screen' && result[0].consentStatus === 'Accepted' && !this.isLocallyVerified(result[0].applicantId)) {
                    // Not really verified yet - decide blank (never sent) vs Pending
                    // (link sent, awaiting verification) using the local "sent" flag.
                    result[0].consentStatus = this.isConsentLinkSentLocally(result[0].applicantId) ? 'Pending' : '';
                    result[0].isConsentAccepted = false;
                }
                if (this.parentScreen != 'Lead Screen') {
                    this.showNextButton = result[0].isConsentAccepted;
                    this.showPreviousButton = true;
                }

                // this.consentSent= result[0].consentSent;
                // if(this.consentSent==false){
                //      this.showConsentverify = true;
                //      this.resendlinks = true;
                //      this.showSendConsent = false;
                // }
                console.log('result[0].consentStatus', result[0].consentStatus);
                if (result[0].consentStatus == 'Accepted') {
                    this.showSendConsent = false;
                    this.showConsentverify = false;
                    this.resendlinks = false;
                }
                else if (result[0].consentStatus == 'Pending') {
                    this.showSendConsent = false;
                    this.showConsentverify = true;
                    this.resendlinks = true;
                    console.log('result  127-->' + JSON.stringify(result));
                }
                else {
                    console.log('inside 151');
                    this.showSendConsent = true;
                    this.showConsentverify = false;
                    this.resendlinks = false;
                }
                // Guard: prevent this delayed call from re-showing Resend Link/Verify
                // or the initial Send Consent Link button when verification has
                // already succeeded (race condition fix).
                if (this.custOptions && this.custOptions[0] && this.custOptions[0].otpVerified) {
                    this.showConsentverify = false;
                    this.resendlinks = false;
                    this.showSendConsent = false;
                }
            })
    }

    getCustomerDetails() {
        console.log('loan id--' + this.loanApplicationId);
        console.log('parent screen>', this.parentScreen);
        let params = {
            loanId: this.loanApplicationId,
            applicantId: this.applicantDetId,
            leadId: this.leadId,
            next: this.next,
            parentScreen: this.parentScreen
        };
        if (this.parentScreen == 'Co Applicant' || this.parentScreen == 'Lead Screen') {
            getCustomerList({ params: params })
                .then(result => {
                    console.log('getCustomerList result--' + result);
                    console.log('getCustomerList result--' + JSON.stringify(result));
                    console.log('getCustomerList result.applicantDetails--' + result.applicantDetails);
                    console.log('getCustomerList result.applicantDetails--' + JSON.stringify(result.applicantDetails));
                    // Decide table/dropdown visibility from Apex's RAW signal (unchanged
                    // behavior), then apply the local-verification override only to what
                    // is displayed (status text / checkmark / Send Consent Link button).
                    const rawApplicantDetails1 = result.applicantDetails;
                    if (rawApplicantDetails1 && rawApplicantDetails1[0] && rawApplicantDetails1[0].otpVerified) {
                        this.showtable = true;
                        this.showdropdown = false;
                        this.sendOtpLabel = 'Send OTP';
                        this.otpsended = false;
                        this.showTimer = false;
                        // this.showConsentverify = false;
                    }
                    else {
                        this.showtable = false;
                        this.showdropdown = true;
                        this.sendOtpLabel = 'Send OTP';
                        this.otpsended = false;
                        this.showTimer = false;
                        // this.showConsentverify = false;
                        this.comboboxClass = 'inputSize inputSize-with-margin';
                        if (this.selectedAction == 'sendConsentLink') {
                            this.showSendOtp = false;
                            // this.showSendConsent = true;
                            this.showtable = true;
                            this.isDropdownDisabled = true;
                        }
                    }
                    this.custOptions = this.applyConsentOverride(rawApplicantDetails1);
                    this.originalMobileNumber = this.custOptions[0].originalMobileNumber;
                    this.customerEmail = this.custOptions[0].email;
                    // added for testing
                    this.isShowModal = true;
                    if (this.parentScreen == 'Lead Screen') {
                        console.log('inside 202');
                        this.dispatchStatus();
                    }
                })
                .catch(error => {
                    //this.error = error;
                    console.log('error in getcustomerdetails>', JSON.stringify(error));
                });
        } else {
            params.applicantId = '';
            getCustomerList({ params: params })
                .then(result => {
                    console.log('getCustomerList result--' + result);
                    console.log('getCustomerList result--' + JSON.stringify(result));
                    console.log('getCustomerList result.applicantDetails--' + result.applicantDetails);
                    console.log('getCustomerList result.applicantDetails--' + JSON.stringify(result.applicantDetails));
                    // Decide table/dropdown visibility from Apex's RAW signal (unchanged
                    // behavior), then apply the local-verification override only to what
                    // is displayed (status text / checkmark / Send Consent Link button).
                    // NOTE: this is the Primary Applicant branch - previously missing the
                    // override entirely, which is why the false "Accepted" status persisted.
                    const rawApplicantDetails2 = result.applicantDetails;
                    if (rawApplicantDetails2 && rawApplicantDetails2[0] && rawApplicantDetails2[0].otpVerified) {
                        this.showtable = true;
                        this.showdropdown = false;
                        this.sendOtpLabel = 'Send OTP';
                        this.otpsended = false;
                        this.showTimer = false;
                        this.showConsentverify = false;
                    }
                    else {
                        this.showtable = false;
                        this.showdropdown = true;
                        this.sendOtpLabel = 'Send OTP';
                        this.otpsended = false;
                        this.showTimer = false;
                        //this.showConsentverify = false;
                        this.comboboxClass = 'inputSize inputSize-with-margin';
                        if (this.selectedAction == 'sendConsentLink') {
                            this.showSendOtp = false;
                            // this.showSendConsent = true;
                            this.showtable = true;
                            this.isDropdownDisabled = true;
                        }
                    }
                    this.custOptions = this.applyConsentOverride(rawApplicantDetails2);
                    this.originalMobileNumber = this.custOptions[0].originalMobileNumber;
                    this.customerEmail = this.custOptions[0].email;
                    // Keep Send Consent Link button visible when this record has not
                    // actually been verified locally, even though showConsentverify was
                    // set true above based on Apex's raw (possibly hardcoded) signal.
                    if (!this.custOptions[0].otpVerified) {
                        this.showConsentverify = false;
                        this.resendlinks = false;
                    }
                    // added for testing
                    this.isShowModal = true;
                })
                .catch(error => {
                    this.error = error;
                    console.log('error', JSON.parse(JSON.stringify(error)));
                });
        }


    }

    dispatchStatus() {
        console.log('this.custOptions[0].status', this.custOptions[0].status);
        // Dispatch custom event with status
        const statusEvent = new CustomEvent('sendstatus', {
            detail: { status: this.custOptions[0].status }
        });
        this.dispatchEvent(statusEvent);
    }

    handleInputChange(event) {
        this.showSendOtp = true;
        console.log('event.target.dataset.id : ' + event.target.dataset.id);
        for (let i = 0; i < this.custOptions.length; i++) {
            console.log('cust option Id--' + this.custOptions[i].recordApplicationId);
            if (this.custOptions[i].recordApplicationId == event.target.dataset.id) {
                this.mobileNumber = this.custOptions[i].mobileNumber;
                this.applicantType = this.custOptions[i].applicantType;
                this.recordApplicationId = this.custOptions[i].recordApplicationId;
                this.originalMobileNumber = this.custOptions[i].originalMobileNumber;
                console.log('recordApplicationId ' + this.recordApplicationId);
            }
        }
    }


    handleOtpChange(event) {

        console.log('event.target.dataset.id : ' + event.target.value);
        if (isNaN(Number(event.target.value))) {
            event.target.value = this.enteredOtp;
            // this.showToastMethod('Warning', 'Please enter valid six digit OTP', 'Warning');
            return;
        }
        else {
            this.enteredOtp = event.target.value;
            // Remove non-numeric characters using regular expression
            this.enteredOtp = this.enteredOtp.replace(/[^0-9]/g, '');

            this.disableVerifyOtp = true;
            console.log('enteredOtp-- ' + this.enteredOtp.length);
            if (this.enteredOtp.length == 6) {
                this.disableVerifyOtp = false;
            }
            if (this.enteredOtp.length == 7) {
                // this.showToastMethod('Warning', 'Please enter valid six digit OTP', 'Warning');
            }
        }
    }


    //bypassing the callGenerateOTPApiEmailMobile method since we do not have the API
    /*callSendOTP(){
        this.checkSpinner=true;
        this.sendOtpButtons=true;
        this.checkSpinner=false;
        this.showSendOtp=true;
        this.sendOtpLabel='Resend OTP';
        this.enteredOtp='';
        this.otpsended = true;
        callGenerateOTPApiEmailMobile({
            mobileNo : this.originalMobileNumber,
            customerEmail : this.customerEmail
        }).then(response=>{
            if(response.Status){
                this.otpSessionId = response.SessionId;
                UpdateModOTP({recordId:this.custOptions[0].recordApplicationId,next:this.next})
                .then(result =>{
                    this.loadTable();
                    this.startTimer(25);
                })
            }
        }).catch(error => {
            this.error = error;
            console.log('error', JSON.parse(JSON.stringify(error)));
        });
    }*/
    //making a mock response for OTP
    callSendOTP() {
        this.checkSpinner = true;
        this.sendOtpButtons = true;
        this.checkSpinner = false;
        this.showSendOtp = true;
        this.sendOtpLabel = 'Resend OTP';
        this.enteredOtp = '';
        this.otpsended = true;

        // Simulate API behavior with hardcoded or dynamic mock data
        let response = {
            Status: true,
            SessionId: '1234567890', // Mock Session ID
            OTP: '123456' // static 6-digit OTP
        };

        // Simulate the success condition
        if (response.Status) {
            this.otpSessionId = response.SessionId;
            console.log('Generated OTP:', response.OTP); // Log for debugging or display

            let params = {
                recordId: this.custOptions[0].recordApplicationId,
                leadId: this.leadId,
                next: this.next,
                parentScreen: this.parentScreen,
                mode: this.otpMode,
                status: this.pendingStatus
            };
            // Call UpdateModOTP to simulate server-side updates
            updateMode({ params: params })
                .then(result => {
                    this.loadTable();
                    this.startTimer(25);
                })
                .catch(error => {
                    console.error('Error updating OTP session:', error);
                });
        }
    }


    /*initiateVerifyOtp(event) {
        try {
            this.checkSpinner = true;
            console.log('in success');
            callValidateOTPApiEmailMobile({
                sessionId: this.otpSessionId, otpValue: this.enteredOtp, mobileNo: this.originalMobileNumber
            }).then(response=>{
                if(response.Status == 200){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Mobile No verified.',
                            variant: 'success',
                        }),
                    );
                    checkOTPVerified({ recordId: this.custOptions[0].recordApplicationId, next: this.next })
                        .then(result => {
                            this.checkSpinner = false;
                            if (result) {
                                otpReceived({ recordId: this.custOptions[0].recordApplicationId })
                                    .then(() => {
                                        this.showToastMethod('Verified', 'OTP verified successfully', 'success');
                                        getCustomerList({ loanId: this.loanApplicationId, applicantId: this.custOptions[0].recordApplicationId, next: this.next })
                                            .then(result => {
                                                console.log('getCustomerList result--' + JSON.stringify(result));
                                                this.custOptions = result.applicantDetails;
                                                if (this.custOptions && this.custOptions.length > 0 && this.custOptions[0].otpVerified) {
                                                    this.showtable = true;
                                                    this.showdropdown = false;
                                                    this.sendOtpButtons = false;
                                                    this.showSendOtp = false;
                                                }
                                            });
                                    });
                            } else {
                                this.checkSpinner = false;
                                this.showToastMethod('Not Verified', 'Incorrect OTP', 'error');
                                this.showtable = false;
                                this.showdropdown = true;
                                this.sendOtpButtons = true;
                            }
                        })
                        .catch(error => {
                            console.error('Error in initiateVerifyOtp:', error);
                            this.checkSpinner = false;
                        });
                    // Reset UI states and variables
                    this.sendOtpLabel = 'Send Otp';
                    this.isShowModal = false;
                    this.sendOtpButtons = false;
                    this.enteredOtp = '';
                    this.mobileNumber = '';
                    this.applicantType = '';
                    this.recordApplicationId = '';
                    console.log('recordApplicationId => ' + this.recordApplicationId);
            
                }else if(response.Status == 400 && response.MessageValue == 'Authentication failed.'){
                    this.checkSpinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'The entered OTP was expired. Please resend OTP.',
                            variant: 'error',
                        }),
                    );
                }
                else if(response.Status == 400 && response.MessageValue == 'Additional credentials required.'){
                    this.checkSpinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'The entered OTP value does not match. Please try again.',
                            variant: 'error',
                        }),
                    );
                }
                else if(response.Status == 500){
                    this.checkSpinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: response.MessageValue,
                            variant: 'error',
                        }),
                    );
                }
            }).catch(error=>{
                this.checkSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Unable to validate the OTP. Please try again.',
                        variant: 'error',
                    }),
                );
            });
        } catch (error) {
            console.error('Error in initiateVerifyOtp:', error);
            this.checkSpinner = false;
        }
    }*/

    initiateVerifyOtp(event) {
        try {
            this.checkSpinner = true;
            console.log('in success');

            // Mock API response instead of calling callValidateOTPApiEmailMobile
            let response = {
                Status: 200, // Simulate success response
                MessageValue: 'OTP validated successfully'
            };

            // Process the mocked response
            if (response.Status === 200) {
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Success',
                //         message: 'Mobile No verified.',
                //         variant: 'success',
                //     }),
                // );
                let checkOTPVerifiedparams = {
                    recordId: this.custOptions[0].recordApplicationId,
                    leadId: this.leadId,
                    next: this.next,
                    parentScreen: this.parentScreen
                };
                checkOTPVerified({ checkOTPVerifiedparams: checkOTPVerifiedparams })
                    .then(result => {
                        this.checkSpinner = false;
                        if (result) {
                            // Real OTP verification confirmed by backend - remember it
                            // locally so this consent stays Accepted on future loads.
                            this.markLocallyVerified(this.custOptions[0].recordApplicationId);
                            otpReceived({ recordId: this.custOptions[0].recordApplicationId, leadId: this.leadId, parentScreen: this.parentScreen })
                                .then(() => {
                                    // this.showToastMethod('Verified', 'OTP verified successfully', 'success');
                                    let params = {
                                        loanId: this.loanApplicationId,
                                        applicantId: this.custOptions[0].recordApplicationId,
                                        leadId: this.leadId,
                                        next: this.next,
                                        parentScreen: this.parentScreen
                                    };
                                    getCustomerList({ params: params })
                                        .then(result => {
                                            console.log('getCustomerList result--' + JSON.stringify(result));
                                            this.custOptions = this.applyConsentOverride(result.applicantDetails);
                                            if (this.custOptions && this.custOptions.length > 0 && this.custOptions[0].otpVerified) {
                                                this.showtable = true;
                                                this.showdropdown = false;
                                                this.sendOtpButtons = false;
                                                this.showSendOtp = false;
                                            }
                                        });
                                });
                        } else {
                            this.checkSpinner = false;
                            // this.showToastMethod('Not Verified', 'Incorrect OTP', 'error');
                            this.showtable = false;
                            this.showdropdown = true;
                            this.sendOtpButtons = true;
                        }
                    })
                    .catch(error => {
                        console.error('Error in initiateVerifyOtp:', error);
                        this.checkSpinner = false;
                    });

                // Reset UI states and variables
                this.sendOtpLabel = 'Send Otp';
                this.isShowModal = false;
                this.sendOtpButtons = false;
                this.enteredOtp = '';
                this.mobileNumber = '';
                this.applicantType = '';
                this.recordApplicationId = '';
                console.log('recordApplicationId => ' + this.recordApplicationId);
            } else if (response.Status === 400 && response.MessageValue === 'Authentication failed.') {
                this.checkSpinner = false;
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Error',
                //         message: 'The entered OTP was expired. Please resend OTP.',
                //         variant: 'error',
                //     }),
                // );
            } else if (response.Status === 400 && response.MessageValue === 'Additional credentials required.') {
                this.checkSpinner = false;
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Error',
                //         message: 'The entered OTP value does not match. Please try again.',
                //         variant: 'error',
                //     }),
                // );
            } else if (response.Status === 500) {
                this.checkSpinner = false;
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Error',
                //         message: response.MessageValue,
                //         variant: 'error',
                //     }),
                // );
            }
        } catch (error) {
            console.error('Error in initiateVerifyOtp:', error);
            this.checkSpinner = false;
        }
    }

    showToastMethod(toastTitle, toastMessage, toastVariant) {
        const evt = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }


    closeModal() {
        this.isShowModal = false;
        const value = 'false';
        const valueChangeEvent = new CustomEvent("valuechange", {
            detail: { value }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    handleActionChange(event) {
        this.selectedAction = event.target.value;
        console.log(' this.selectedAction ' + this.selectedAction);
        this.showtable = true;
        this.isDropdownDisabled = true;
        this.comboboxClass = 'inputSize inputSize-no-margin';
        if (this.selectedAction == 'sendOtp') {
            this.showSendOtp = true;
            this.showSendConsent = false;
        }
        else if (this.selectedAction == 'sendConsentLink') {
            this.showSendOtp = false;
            // this.showSendConsent = true;
        }
        else {
            this.showSendOtp = false;
            this.showSendConsent = false;
        }
    }
    ChangeMode() {
        this.isDropdownDisabled = false;
        this.sendOtpButtons = false;
        this.selectedAction = null;
        this.showSendOtp = false;
        this.sendOtpLabel = 'Send OTP';
        this.showSendConsent = false;
        this.showtable = false;
        this.otpsended = false;
        this.showTimer = false;
        this.showConsentverify = false;
        this.comboboxClass = 'inputSize inputSize-with-margin';
        let params = {
            recordId: this.custOptions[0].recordApplicationId,
            leadId: this.leadId,
            next: this.next,
            parentScreen: this.parentScreen,
            mode: '',
            status: ''
        };
        updateMode({ params: params })
            .then(result => {
                this.loadTable();
            })
    }

    /*SendConsentLink(){
        this.resendlinks = false;
        console.log('this.custOptions.applicantType '+this.custOptions[0].applicantType);
        UpdateMode({recordId:this.custOptions[0].recordApplicationId,next:this.next})
        .then(result => {
            console.log('working');
            if(this.consenttimeout){
                console.log('502');
                clearTimeout(this.consenttimeout);
            }
            this.loadTable();
            this.showSendConsent = false;
            this.showConsentverify = true;
            setTimeout(() => {
                if (!this.verifiyconsentcodes) {
                    this.resendlinks = true;
                    this.resetTimeoutforConsent();
                }
            }, 25000);

        //this.encodeId(this.custOptions[0].recordApplicationId); 
        encodeRecordId({ recordId: this.custOptions[0].recordApplicationId })
            .then((result) => {
                this.encodedId = result;
                console.log('encoded Id:', this.encodedId);
                // Perform further processing with the decoded ID
            })
            .catch((error) => {
                console.error('Error decoding the record ID:', error);
            });   
        this.navigateToLoanAckPage(this.encodedId,this.orgDomainName2);
        })
    }*/

    handleSendConsentLink() {
        console.log('694');
        if (this.isConsentDisabled) {
            return;
        }
        this.showConsentModal = true;
    }
    handleNo() {
        this.showConsentModal = false;
    }

    async SendConsentLink() {
        this.showConsentModal = false;
        // User confirmed "Yes" - the consent link is now actually being sent.
        // Mark it locally so the table shows "Pending" (no tick) instead of
        // blank, until the user completes real verification.
        this.markConsentLinkSentLocally(this.custOptions[0].recordApplicationId);

        // Update the displayed row immediately. Merely writing to localStorage does
        // not trigger an LWC rerender, so create a new array/object reference.
        this.custOptions = this.custOptions.map((item, index) =>
            index === 0
                ? { ...item, otpVerified: false, displayStatus: this.pendingStatus }
                : item
        );

        console.log('this.custOptions.applicantType ' + this.custOptions[0].applicantType);
        console.log('this.loanApplicationId ' + this.loanApplicationId);
        console.log('this.applicantDetId::: ' + this.applicantDetId);
        console.log('this.offerId::: ' + this.offerId);

        // Build the consent link once.
        const orgDomain = window.location.origin;
        let baseUrl = orgDomain.replace('lightning.force.com', 'my.site.com');
        baseUrl = baseUrl.replace('my.salesforce.com', 'my.site.com') + '/consent/';
        const idForLink = this.applicantDetId || this.leadId;
        const consentLink = `${baseUrl}?applicantDetId=${idForLink}&offerRelated=false&offerId=${this.offerId}`;

        const mobileNumber =
            this.originalMobileNumber ||
            (this.custOptions && this.custOptions[0] && this.custOptions[0].mobileNumber);

        // ---- EMAIL — fire in parallel, own toast ----
        sendLoanOfferEmail({
            loanId: this.loanApplicationId,
            applicantId: this.applicantDetId,
            leadId: this.leadId,
            offerRelated: false,
            offerId: this.offerId
        })
            .then(() => {
                // this.showToastMethod('Success', 'Consent email sent successfully.', 'success');
            })
            .catch(err => {
                console.error('sendLoanOfferEmail failed:', err);
                // this.showToastMethod('Error', 'Failed to send consent email.', 'error');
            });

        // ---- WHATSAPP — fire in parallel, own toast ----
        if (mobileNumber) {
            initiateWhatsAppRequest({
                inputMap: {
                    loanId: this.loanApplicationId,
                    applicantId: this.applicantDetId || this.leadId,
                    processName: 'whatsappSMS',
                    to: '91' + mobileNumber,
                    templateName: whatsappConsentSms,
                    params: consentLink + ',' + termsLink
                }
            })
                .then(() => {
                    // this.showToastMethod('Success', 'Consent WhatsApp sent successfully.', 'success');
                })
                .catch(err => {
                    console.error('initiateWhatsAppRequest failed:', err);
                    // this.showToastMethod('Error', 'Failed to send consent WhatsApp.', 'error');
                });
        } else {
            console.warn('SendConsentLink: no mobile number — skipping WhatsApp.');
            // this.showToastMethod('Warning', 'No mobile number available for WhatsApp.', 'warning');
        }

        // ---- Proceed immediately — do not wait for either integration ----
        const updateParams = {
            recordId: this.custOptions[0].recordApplicationId,
            leadId: this.leadId,
            next: this.next,
            parentScreen: this.parentScreen,
            mode: this.consentLinkMode,
            status: this.pendingStatus
        };

        UpdateMode({ params: updateParams })
            .then(() => {
                console.log('working');
                if (this.consenttimeout) {
                    console.log('502');
                    clearTimeout(this.consenttimeout);
                }
                this.loadTable();
                this.showSendConsent = false;
                this.showConsentverify = true;
                this.resendlinks = true;
                return encodeRecordId({ recordId: this.leadId });
            })
            .then(encoded => {
                this.encodedId = encoded;
                console.log('encoded Id:', this.encodedId);
                this.navigateToLoanAckPage(this.encodedId, this.parentScreen, this.applicantDetId);
            })
            .catch(error => {
                console.error('Error in UpdateMode / encodeRecordId chain:', error);
            });
    }

    navigateToLoanAckPage(recordId, parentScreen, applicantDetId) {
        //console.log('this.parentScreen::: '+this.parentScreen);
        console.log('this.applicantDetId::: ' + this.isOfferRelated);

        let fullUrl = `https://godrejfinanceservicecloud--gflsit.sandbox.my.site.com/consent/?applicantDetId=${applicantDetId}&offerRelated=${this.isOfferRelated}&offerId=${this.offerId}`;
        console.log('fullUrl: ' + fullUrl);
        /*if (this.parentScreen) {
            fullUrl += `&parentScreen=${parentScreen}`;
        }

        if (this.parentScreen === 'Co Applicant' && this.applicantDetId) {
            fullUrl += `&applicantDetId=${applicantDetId}`;
        }*/

        // initiateAPIRequest({
        //     inputMap: {
        //         's3link': fullUrl,
        //         'recordId': this.loanApplicationId,
        //         'processName': 'Loan URL Shortening Service',
        //     }
        // }).then((response) => {
        //     console.log('response s3link -->' + response);
        //     try {

        //     } catch (error) {
        //         console.error('Error deserializing the response:', error);
        //         this.dispatchEvent(
        //             new ShowToastEvent({
        //                 title: 'Error',
        //                 message: 'Error while parsing the response. Please try again later.',
        //                 variant: 'error',
        //             }),
        //         );
        //     }
        //     this.ShowLoader = false;
        // }).catch(error => {
        //     this.ShowLoader = false;
        //     console.log('error navigateToLoanAckPage -->' + error);
        //     console.error('error navigateToLoanAckPage-->' + JSON.stringify(error));
        // });

        // console.log('fullUrl ' + fullUrl);
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__webPage',
        //     attributes: {
        //         url: fullUrl
        //     }
        // });
        // Single toast shown to the user for the "Send Consent Link" flow.
        this.showToastMethod('Success', 'Consent verification sent', 'success');
        if (this.parentScreen == 'Lead Screen') {
            console.log('inside 802');
            this.dispatchStatus();
        }
    }

    encodeId(recordId) {
        encodeRecordId({ recordId: recordId })
            .then((result) => {
                this.encodedId = result;
                console.log('encoded Id:', this.encodedId);
                // Perform further processing with the decoded ID
            })
            .catch((error) => {
                console.error('Error decoding the record ID:', error);
            });
    }

    resetTimeoutforConsent() {
        console.log('1848 ');
        this.consenttimeout = setTimeout(() => {
            if (!this.verifiyconsentcodes) {
                // this.showConsentverify = false;
                // this.showSendConsent = true;
                this.showConsentverify = false;

            }
        }, 20000);
    }

    @track showBureauHealthButton = false;
    verifiyconsentcode(event) {
        let checkconsentverifiedparams = {
            recordId: this.custOptions[0].recordApplicationId,
            leadId: this.leadId,
            next: this.next,
            parentScreen: this.parentScreen
        };
        checkconsentVerified({ checkconsentverifiedparams: checkconsentverifiedparams })
            .then(result => {
                // Real consent verification confirmed by backend - remember it
                // locally so this consent stays Accepted on future loads.
                if (result) {
                    this.markLocallyVerified(this.custOptions[0].recordApplicationId);
                }
                let params = {
                    loanId: this.loanApplicationId,
                    applicantId: this.custOptions[0].recordApplicationId,
                    leadId: this.leadId,
                    next: this.next,
                    parentScreen: this.parentScreen
                };
                getCustomerList({ params: params })
                    .then(result => {
                        this.custOptions = this.applyConsentOverride(result.applicantDetails);
                        if (this.custOptions[0].otpVerified) {
                            this.showToastMethod('Success', 'Consent Verified Successfully', 'success');
                            this.showtable = true;
                            this.showdropdown = false;
                            this.sendOtpButtons = false;
                            this.showSendOtp = false;
                            this.resendlinks = false;
                            this.showConsentverify = false;
                            this.verifiyconsentcodes = true;
                            this.showBureauHealthButton = true;
                            // this.refreshRecordPage();
                            setTimeout(() => {
                                this.getApplicantValues();
                                if (this.parentScreen == 'Lead Screen') {
                                    console.log('inside 809');
                                    this.dispatchStatus();
                                } else {
                                    const valueSelectedEvent = new CustomEvent('opennextscreen', {
                                        detail: {
                                            screenName: result
                                        }
                                    });
                                    this.dispatchEvent(valueSelectedEvent);
                                }

                            }, 100);



                        }
                        else if (this.custOptions[0].status == 'Declined') {
                            // this.showToastMethod('Not Verified', 'Consent declined.', 'error');
                            this.showtable = true;
                            this.showdropdown = true;
                            this.sendOtpButtons = false;
                            this.showSendOtp = false;
                            this.verifiyconsentcodes = true;
                            this.showConsentverify = false;
                            // this.showSendConsent = true;
                            this.showBureauHealthButton = true;
                        }
                        else if (this.custOptions[0].status == 'Pending') {
                            // this.showToastMethod('Not Verified', 'Consent is not received.', 'error');
                            this.showtable = true;
                            this.showdropdown = true;
                            this.sendOtpButtons = false;
                            this.showSendOtp = false;
                            this.showBureauHealthButton = true;
                            this.showSendConsent = false;
                        }
                    })
            })


    }
    getApplicantDetailrecords() {
        
        getLoanAndApplicantDetails({ leadId: this.leadId,
            loanId: this.loanApplicationId,
            parentScreen: this.parentScreen })
            .then(result => {
                // Handle the result
                console.log(' this.customers ' + JSON.stringify(result));
                this.customers = JSON.stringify(result);
                console.log('this.customers ' + this.customers);
                const customersArray = JSON.parse(this.customers);
                console.log('total Size: ' + Object.keys(customersArray).length);
            })
    }
    validateSaveAndNext() {
        this.showSendOtp = false;
        this.showSendConsent = false;
        this.sendOtpButtons = false;
        this.next = this.next + 1;

        console.log('recordId' + this.recordId);
        console.log('this.next=:' + this.next + ' ' + this.parentScreen);
        console.log('this.customers:: ' + JSON.stringify(this.customers));
        const customersArray = JSON.parse(this.customers);
        console.log('Object.keys(customersArray).length=:' + Object.keys(customersArray).length);

        if (this.next > 0 && this.next <= Object.keys(customersArray).length - 1) {
            console.log('inside 1st');
            const id = customersArray[this.next];
            console.log('applicantId:', id);
            console.log('next ' + this.next);
            this.custOption = null;

            // initiateAPIRequest({
            //     inputMap: {
            //         'recordId': this.loanApplicationId,
            //         'applicantType': this.parentScreen,
            //         'applicantId': customersArray[this.next],
            //         'processName': 'Loan CIBIL',
            //     }
            // }).then((response) => {
            //     console.log('response Loan CIBIL -->' + response);
            //     console.log('response CIBIL -->'+response.cibilresponse);
            //     try {

            //     } catch (error) {
            //         console.error('Error deserializing the response:', error);
            //         this.dispatchEvent(
            //             new ShowToastEvent({
            //                 title: 'Error',
            //                 message: 'Error while parsing the response. Please try again later.',
            //                 variant: 'error',
            //             }),
            //         );
            //     }
            //     this.ShowLoader = false;
            // }).catch(error => {
            //     this.ShowLoader = false;
            //     console.log('error validateSaveAndNext-->' + error);
            //     console.error('error validateSaveAndNext-->' + JSON.stringify(error));
            // });
            let params = {
                loanId: this.loanApplicationId,
                applicantId: id,
                leadId: this.leadId,
                next: this.next,
                parentScreen: this.parentScreen
            };
            getCustomerList({ params: params })
                .then(result => {
                    console.log('result:: ' + JSON.stringify(result));
                    this.custOptions = result.applicantDetails;
                    if (this.custOptions[0].otpVerified) {
                        this.showtable = true;
                        this.showdropdown = false;
                        this.showConsentverify = false;
                        this.sendOtpButtons = false;
                        this.showSendOtp = false;
                        this.showSendConsent = false;
                        this.sendOtpLabel = 'Send OTP';
                        this.otpsended = false;
                        this.showTimer = false;
                        this.showConsentverify = false;
                        if (this.parentScreen == 'Co Applicant') {
                            console.log('inside coapp1');
                            //const eventToSendcoApp1 = new CustomEvent('coappnextscreen');
                            //console.log('eventToSendcoApp1::: '+JSON.stringify(eventToSendcoApp1));
                            //this.dispatchEvent(eventToSendcoApp1);{
                            try {
                                const eventToSendcoApp = new CustomEvent('coappnext', {
                                    detail: { message: 'Navigating to Co-Applicant', apDetId: id },
                                    bubbles: true,
                                    composed: true
                                });
                                this.dispatchEvent(eventToSendcoApp);
                                console.log('coappnext event dispatched successfully');
                            } catch (error) {
                                console.error('Error dispatching coappnext event:', error);
                            }
                        }
                    }
                    else {
                        this.showtable = false;
                        this.showdropdown = true;
                        this.showConsentverify = false;
                        this.sendOtpButtons = false;
                        this.showSendOtp = false;
                        this.showSendConsent = false;
                        this.isDropdownDisabled = false;
                        this.selectedAction = null;
                        this.sendOtpLabel = 'Send OTP';
                        this.otpsended = false;
                        this.showTimer = false;
                        this.showConsentverify = false;
                        this.comboboxClass = 'inputSize inputSize-with-margin';
                    }
                })
                .catch(error => {
                    this.error = error;
                    console.log('error', JSON.parse(JSON.stringify(error)));
                });
        }
        else if ((this.next > Object.keys(customersArray).length - 1)) {
            console.log('inside next screen ' + this.parentScreen);
            if (this.parentScreen == 'Co Applicant') {
                console.log('inside coapp');
                const eventToSendcoApp = new CustomEvent('coappnext');
                this.dispatchEvent(eventToSendcoApp);
            }
            else {
                const eventToSend = new CustomEvent('next');
                this.dispatchEvent(eventToSend);
            }


            /*getLoanDetails({
                loanId:this.loanApplicationId
            }).then(response=>{
                console.log('inside getLoanDetails');
                const eventToSend = new CustomEvent('refreshmenu');
                this.dispatchEvent(eventToSend);
            }).catch(error=>{

            })*/
        }
    }

    refreshRecordPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Opportunity', // change if your object is different
                actionName: 'view'
            }
        }, true); // true replaces history, avoids extra back step
    }
    previousAction(event) {
        console.log('912  ' + this.currentAppSeq);
        const valueChangeEvent = new CustomEvent("previous", {
            detail: { value: this.leadId, name: 'Applicant Information', currentAppSeq: 1 }
        });
        this.dispatchEvent(valueChangeEvent);
        // this.showSendOtp=false;
        // this.showSendConsent = false;
        // this.sendOtpButtons = false;
        // this.next = this.next - 1;
        // if (this.next > 0 && this.next <= Object.keys(customersArray).length){
        // const id = customersArray[this.next]; 
        // console.log('applicantId:', id);
        // console.log('next '+this.next);
        // this.custOption = null;
        // getCustomerList({loanId:this.loanApplicationId,applicantId:id,next:this.next})
        // .then(result => {
        //     console.log('getCustomerList result--'+result);
        //     console.log('getCustomerList result--'+JSON.stringify(result));
        //     console.log('getCustomerList result.applicantDetails--'+result.applicantDetails);
        //     console.log('getCustomerList result.applicantDetails--'+JSON.stringify(result.applicantDetails));
        //     this.custOptions=result.applicantDetails;
        //     if(this.custOptions[0].otpVerified){
        //         this.showtable = true;
        //         this.showdropdown = false;
        //         this.showConsentverify = false;
        //         this.sendOtpButtons = false;
        //         this.showSendOtp = false;
        //         this.showSendConsent = false;
        //         this.sendOtpLabel = 'Send OTP';
        //         this.otpsended = false;
        //         this.showTimer = false;
        //         this.showConsentverify = false;
        //     }
        //     else{
        //         this.showtable = false;
        //         this.showdropdown = true;
        //         this.showConsentverify = false;
        //         this.sendOtpButtons = false;
        //         this.showSendOtp = false;
        //         this.showSendConsent = false;
        //         this.isDropdownDisabled = false;
        //         this.selectedAction = null;
        //         this.sendOtpLabel = 'Send OTP';
        //         this.otpsended = false;
        //         this.showTimer = false;
        //         this.showConsentverify = false;
        //         this.comboboxClass = 'inputSize inputSize-with-margin';
        //     }
        // })
        // .catch(error => {
        //     this.error = error;
        //     console.log('error', JSON.parse(JSON.stringify(error)));
        // });
        // }
        // else if(this.next == 0){
        //     this.custOption = null;
        //     this.getCustomerDetails();
        // }
        // else if(this.next < 0){
        //     const eventToSend = new CustomEvent('previous');
        //     this.dispatchEvent(eventToSend);
        // } 
        // if(this.parentScreen == 'Primary Applicant'){
        //     const eventToSend = new CustomEvent('previous', {detail:{recordId: this.recordId}});
        //     this.dispatchEvent(eventToSend);
        // }
        // if(this.parentScreen == 'Co Applicant'){
        //     const eventToSend = new CustomEvent('previous', {detail:{recordId: this.recordId, applicantDetId:this.applicantDetId}});
        //     this.dispatchEvent(eventToSend);
        // }
    }
    /*navigateToLoanAckPage(recordId, orgDomainName){
        // Construct the dynamic URL using the provided parameters
        const fullUrl = `${orgDomainName}/?id=${recordId}&timer=MjAyNC0wOC0yMFQxMDozMjowMy4zNTFa`;
        console.log('fullUrl '+fullUrl);
        // Use the NavigationMixin to navigate to the URL
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
            url: fullUrl
            }
        });
    }*/

    nextAction() {
        console.log('this.next ' + this.currentAppSeq);
        console.log('this.selectedCustIds-----', this.selectedCustIds);
        console.log('this.recordId-----', this.recordId);
        /* const valueChangeEvent = new CustomEvent("callnextaccordian", {
             detail: { value:this.recordId,name:'Applicant Information',currentAppSeq: this.currentAppSeq,section: 'Employment Details',selectedCustIds : this.selectedCustIds }
             });
             this.dispatchEvent(valueChangeEvent);*/
        getNextScreenDetails({
            currentAppSeq: this.currentAppSeq,
            activeSectionName: '',
            formIdentifier: ''
        })
            .then(result => {
                console.log('result-----635', result);
                const valueSelectedEvent = new CustomEvent('opennextscreen', {
                    detail: {
                        screenName: result,
                        recordId: this.effectiveRecordId
                    }
                });
                this.dispatchEvent(valueSelectedEvent);
            })
            .catch(error => {
                console.log(error);
            })
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
            this.timerValue = `${minutes < 10 ? '0' : ''}${minutes}:${seconds < 10 ? '0' : ''}${seconds}`;
            if (this.countdown === 0) {
                clearInterval(this.timer);
                this.showTimer = false;
                this.isButtonDisabled = false;
            }
        }, 1000);
    }
    disconnectedCallback() {
        clearInterval(this.timer);
    }
    loadTable() {
        let params = {
            loanId: this.loanApplicationId,
            applicantId: this.custOptions[0].recordApplicationId,
            leadId: this.leadId,
            next: this.next,
            parentScreen: this.parentScreen
        };
        getCustomerList({ params: params })
            .then(result => {
                console.log('getCustomerList result--' + result);
                console.log('getCustomerList result--' + JSON.stringify(result));
                console.log('getCustomerList result.applicantDetails--' + result.applicantDetails);
                console.log('getCustomerList result.applicantDetails--' + JSON.stringify(result.applicantDetails));
                // Preserve the Pending display after the server refresh.
                this.custOptions = this.applyConsentOverride(result.applicantDetails);
            })
    }
    UpdateStatus() {
        otpReceived({ recordId: this.custOptions[0].recordApplicationId, leadId: this.leadId, parentScreen: this.parentScreen })
            .then(result => {
                console.log('result' + result);
            })
    }
}