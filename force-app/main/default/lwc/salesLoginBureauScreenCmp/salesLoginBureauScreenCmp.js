import { LightningElement,api,track } from 'lwc';
import getSubStageListSubAccordian from '@salesforce/apex/COMM_SalesLoanActionsController.getSubStageListSubAccordian';
import getPanResp from '@salesforce/apex/COMM_SalesLoanActionsController.getPanResp';
import initiateAPIRequest from '@salesforce/apex/COMM_CRIFAPIController.initiateAPIRequest';
import initiateCommercialAPIRequest from '@salesforce/apex/COMM_CRIFAPIControllerCommercial.initiateAPIRequest';
import checkIntegrationRecord from '@salesforce/apex/COMM_CRIFAPIControllerCommercial.checkIntegrationRecord';
import processCommercialCrifResponse from '@salesforce/apex/COMM_CommercialCrifGetData.processCommercialCrifResponse';
import getApplicantValues from '@salesforce/apex/COMM_SalesLoanLoginController.getApplicantValues';
import initiateGenAI from '@salesforce/apex/GenAiController.initiateAPIRequest';
import checkCibilFetched from '@salesforce/apex/SalesDocumentCmpController.checkApiHit';
import NOT_ELIGIBLE_ICON from '@salesforce/resourceUrl/RejectIconEligibility';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkApplicantAddress from '@salesforce/apex/COMM_CRIFAPIController.checkApplicantAddress';
import getCustomerType from '@salesforce/apex/ScreenGenerationController.getCustomerTypeApp';
import FORM_FACTOR from '@salesforce/client/formFactor';
import initiateGenAIScore from '@salesforce/apex/ScoreSummarizationController.initiateAPIRequest';
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated'
import checkApplicantAddressHL from '@salesforce/apex/CibilAPIController.checkApplicantAddress';
import initiateAPIRequestCiblHL from '@salesforce/apex/CibilAPIController.initiateAPIRequest';
import initiateAPIRequestSegment from '@salesforce/apex/AHL_ScorecardController.initiateAPIRequest';
import isScoreSegmentMissing from '@salesforce/apex/AHL_ScorecardController.isScoreSegmentMissing';

export default class SalesLoginBureauScreenCmp extends LightningElement {
    isTrue = false;
    @api recordId;
    @track customerType;
    @api appId;
    @track showGetDataButton = false;
    @track showRefetchScoreButton = false;
    activeSection = 'Crif One View';
    @api passedScreenName = 'Crif One View'
    @api formName = 'Bureau insights';
    @api loginChecklist;
    @api isMnrlBlacklisted;
    @api currentAppSeq;
    disableInitiateButton = false;
    viewCibilIsights = false;
    cibilOneView = false;
    isConsentAccepted = true;
    showErrorListBureau=false;
    notEligibleIcon;
    isRendered = false;
    stages = [];
    rerenderCmp ;
    showErrors;
    errorList= 'The system was unable to fetch CRIF report with the provided document.';
    errorListLoginCheckList= 'Bureau has not been fetched for the applicant.';
    isloading = true;
    onLoadButton = false;
    showApplicantAddress= false;
    isSmall = false;
    isHLUser= false;
    @api isCrif;
    @api isCibil

    renderedCallback() {
        if (!this.isRendered && this.isSmall) {
            this.isRendered = true;
            const style = document.createElement('style');
            style.innerText = `
                .accordionClass .slds-accordion__list-item {
                    margin:0px;
                }
                    .slds-is-open > .slds-accordion__summary{
                    margin-bottom: 10px !important;
                    }
            `;
            this.template.querySelector('.styleContainer').appendChild(style);
        }
    }

    connectedCallback() {

        if(this.isCibil){
            this.checkIfLoggedInUserIsHLRelated();
            this.activeSection ='Cibil One View';
            this.passedScreenName='Cibil One View';
        }
        if(this.isHLUser && this.isCrif){
            this.isHLUser =false;
            console.log('  this.isHLUser----'+  this.isHLUser);
        }
        console.log('isCrif----'+this.isCrif);
        if (FORM_FACTOR == 'Small') {
            this.isSmall = true;
        } else {
            this.isSmall = false;
        }
        setTimeout(() => {
            if(!this.isHLUser){
                this.getApplicantValues();
                this.getCustomerType()
                .then(() => {
                    console.log('appId-----' + this.appId);
                    console.log('customerType in bureau---', this.customerType);
                    this.notEligibleIcon = NOT_ELIGIBLE_ICON;

                    return checkCibilFetched({
                        recordId: this.recordId,
                        appId: this.appId,
                        name: 'Loan CRIF'
                    });
                })
                .then(res => {
                    console.log('ress----bureau', res);

                    if (res) {
                        if (this.loginChecklist) {
                            console.log('loginChecklist is true');
                            this.showErrorListBureau = true;
                            this.errorList = this.errorListLoginCheckList;
                            this.onLoadButton = false;
                            this.isloading = false;
                            return Promise.resolve();
                        } else {
                            console.log('loginChecklist is false, checking applicant address');
                            return checkApplicantAddress({ applicantId: this.appId })
                                .then(response => {
                                    console.log('checkApplicantAddress', response);

                                    if (response) {
                                        this.isloading = false;
                                        this.checkScoreSegment();
                                        if (this.customerType === 'Non Individual') {
                                            return this.checkIntegrationRecordExistence()
                                                .then(exists => {
                                                    if (exists) {
                                                        this.showGetDataButton = true;
                                                        this.onLoadButton = false;
                                                    } else {
                                                        this.onLoadButton = true;
                                                        this.showGetDataButton = false;
                                                    }
                                                })
                                                .catch(error => {
                                                    console.error('Error checking integration record:', error);
                                                    this.onLoadButton = true;
                                                    this.showGetDataButton = false;
                                                });
                                        } else {
                                            this.onLoadButton = true;
                                            return Promise.resolve();
                                        }
                                    } else {
                                        this.showErrorListBureau = true;
                                        this.showApplicantAddress = true;
                                        this.isloading = false;
                                        this.errorList = 'We are unable to fetch the CIBIL report as the residence pincode is missing for the applicant. Please contact your system admin.';
                                        return Promise.reject('Missing residence pincode');
                                    }
                                });
                        }
                    } else {
                        this.onLoadButton = false;
                        if (this.loginChecklist) {
                            this.showErrorListBureau = true;
                            this.errorList = this.errorListLoginCheckList;
                            this.isloading = false;
                            return Promise.resolve();
                        } else {
                            console.log('CIBIL not fetched, calling getSubStageListSubAccordian');
                            this.getSubStageListSubAccordian();
                            this.checkScoreSegment();
                        }
                    }
                })
                .catch(error => {
                    console.error('Error in connectedCallback processing:', error);
                });

            }
            else{
                console.log('appId-----'+this.appId);
                console.log('formName in bureau---', this.formName);
                this.notEligibleIcon = NOT_ELIGIBLE_ICON;
                checkCibilFetched({
                    recordId: this.recordId,
                    appId: this.appId,
                    name : 'Loan CIBIL'
                })
                .then(res => {
                    console.log('ress----bureau', res );

                    if (res) {
                        if (this.loginChecklist) {
                            this.showErrorListBureau = true;
                            this.errorList = this.errorListLoginCheckList;
                            this.onLoadButton = false;
                            this.isloading = false;
                        } else {
                            checkApplicantAddress({applicantId: this.appId})
                            .then(response => {
                                console.log('checkApplicantAddress----Gen AI', response );
                                if(response){
                                    this.onLoadButton = true;
                                    this.isloading = false;
                                }
                                else{
                                    this.showErrorListBureau = true;
                                    this.showApplicantAddress = true;
                                    this.isloading = false;
                                    this.errorList = 'We are unable to fetch the CIBIL report as the residence pincode is missing for the applicant. Please contact you system admin.';
                                }
                            })
                        }
                    }
                    else {
                        this.onLoadButton = false;
                        if (this.loginChecklist) {
                            this.showErrorListBureau = true;
                            this.errorList = this.errorListLoginCheckList;
                            this.isloading = false;
                        } else {
                            console.log('Inside 94');
                            this.showErrors = false;
                            checkCibilFetched({
                                recordId: this.recordId,
                                appId: this.appId,
                                name : 'Gen AI'
                            })
                            .then(response => {
                                console.log('60----Gen AI', response );
                                if(response){
                                    console.log('response');
                                    const genMap ={
                                        'loanId':this.recordId,
                                        'applicantId':this.appId,
                                        'processName':'Gen AI',
                                    }
                                    initiateGenAI({
                                        inputMap:genMap
                                    })
                                    .then(response=>{
                                        this.getSubStageListSubAccordian();
                                        console.log('Gen AI hit succesfully',JSON.stringify(response))
                                    })
                                    .catch(error => {
                                        console.log('Error in fetching document GEN AI name: ', JSON.stringify(error));
                                    })
                                }
                                else{
                                    this.getSubStageListSubAccordian();
                                    console.log('GEN AI Already fetched');
                                }
                            })
                        }
                    }
                })
            }
        }, 1000);

        this.rerenderCmp = false;
    }

    checkIfLoggedInUserIsHLRelated(){
        checkIfLoggedInUserIsHLRelated()
        .then(result => {
            this.isHLUser = result.isHLRelated;
            if(this.isHLUser && this.isCrif){
                this.isHLUser =false;
                console.log('  this.isHLUser----'+  this.isHLUser);
            }
            console.log('isHLUser-->',this.isHLUser);
        })
        .catch(error => {
            console.log('error-->',error);
        })
    }

    checkScoreSegment() {
        if (this.isHLUser) {
            return;
        }
        isScoreSegmentMissing({ applicantId: this.appId, loanId: this.recordId })
        .then(result => {
            console.log('isScoreSegmentMissing----', result);
            this.showRefetchScoreButton = result;
        })
        .catch(error => {
            console.log('Error checking score segment: ', JSON.stringify(error));
            this.showRefetchScoreButton = false;
        });
    }

    handleRefetchScoreSegment() {
        this.isloading = true;
        const segmentMap = {
            'loanId': this.recordId,
            'applicantId': this.appId,
            'processName': 'AHL Scorecard'
        };
        initiateAPIRequestSegment({ inputMap: segmentMap })
        .then(response => {
            console.log('Re-fetched segment score: ', JSON.stringify(response));
            this.isloading = false;
            if (response && response.includes('Error:')) {
                this.showToast('Error', response.replace('Error:', '').trim(), 'error');
            } else {
                this.showRefetchScoreButton = false;
                this.showToast('Success', 'Score segment fetched successfully.', 'success');
                this.getSubStageListSubAccordian();
            }
        })
        .catch(error => {
            this.isloading = false;
            console.log('Error in re-fetching segment score: ', JSON.stringify(error));
            this.showToast('Error', 'The system was unable to fetch the score segment.', 'error');
        });
    }

    getApplicantValues(){
        this.isloading = true;
        const inputMap ={
            'applicantId':this.appId
        }
        getApplicantValues({
            inputMap:inputMap
        })
        .then(response => {
            console.log('response 42---',JSON.stringify(response));
            this.isConsentAccepted = response[0].isConsentAccepted;
        })
        .catch(error => {
            this.isloading = false;
            console.error('Error fetching applicant values:', error);
        });
    }

    checkIntegrationRecordExistence() {
        return checkIntegrationRecord({
            loanId: this.recordId,
            applicantId: this.appId
        });
    }

    callAPI() {
       this.callCibilAPI();
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    getSubStageListSubAccordian(){
        this.onLoadButton = false;
        console.log('this.passedScreenName=:'+this.passedScreenName);
        console.log('this.formName=:'+this.formName);
        getSubStageListSubAccordian({
            loanId : this.recordId,
            applicableStage : this.passedScreenName,
            formName : this.formName
        })
        .then(response => {
            console.log('Substage response:27---', response);
            this.stages = response;
            console.log('Substage  this.stages: 30',  this.stages);
            console.log('this.activeSection:',  this.activeSection);
            console.log('this.loginChecklist:',  this.loginChecklist);
            if(this.activeSection!='' && this.activeSection!=null  && this.activeSection!=undefined && !this.loginChecklist){
                for(let i =0; i<this.stages.length; i++){
                    if(this.stages[i].name === this.activeSection){
                        this.activeSection=this.stages[i] ;
                        this.passedScreenName = this.stages[i].name;
                        setTimeout(() => {
                            this.isloading = false;
                        }, 2000);
                    }
                }
            }
            else
            {
                this.activeSection = this.stages[0];
                this.passedScreenName = 'Crif One View';
                setTimeout(() => {
                    this.isloading = false;
                }, 2000);
                console.log('passedScreenName--'+this.passedScreenName);
            }

            this.viewCibilIsights = false;
            this.cibilOneView = true;
            console.log('this.viewCibilIsights:',  this.viewCibilIsights);
            console.log('this.cibilOneView:',  this.cibilOneView);
        })
        .catch(error => {
            console.log('Error getting sub stage list:', JSON.stringify(error));
        });
        this.isloading = false;
    }

    handleAccordionClick(event) {
        event.stopPropagation();

        const selectedStage = event.target.name;
        console.log('selectedStage',selectedStage)
        console.log('stages--',JSON.stringify(this.stages));
        if (selectedStage != undefined && this.activeSection.name !== selectedStage) {
            this.rerenderCmp = false;
            for(let i =0; i<this.stages.length; i++){
                if(this.stages[i].name === selectedStage){
                    this.stages[i].name = selectedStage;
                    this.activeSection = this.stages[i];
                    this.passedScreenName= this.stages[i].name;
                    console.log('rerenderCmp--',this.rerenderCmp);
                }
            }
            if(!this.isHLUser){
                if(selectedStage == 'View Crif Insights'){
                    this.viewCibilIsights = true;
                    this.cibilOneView = false;
                }else if(selectedStage == 'Crif One View'){
                    this.viewCibilIsights = false;
                    this.cibilOneView = true;
                }
            }

            console.log('passedScreenName--',this.passedScreenName);
            console.log('passedScreenName--',this.activeSection);
        }
    }

 
    callCibilAPI(){
        this.isloading = true;
        const inputMap ={
            'loanId':this.recordId,
            'applicantId':this.appId,
            'processName':'Loan CIBIL',

        }
        initiateAPIRequest({
            inputMap:inputMap
        })
            .then(response=>{
                console.log('result 83 Cibil API---',JSON.stringify(response))
                if(response.includes('Error:')){
                    // console.log('response--',response.split(':')[1]);
                    // var temp = response.split(':')[1];
                    // console.log('temp--'+temp);
                    // this.errorList =response;
                    console.log('errorList--'+this.errorList);
                    this.showErrorListBureau = true;
                    this.isloading = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'The system was unable to fetch CIBIL report with the provided document.',
                            variant: 'error',
                        }),
                    );
                }
                else{
                    this.isloading = false;
                    console.log('Inside 94 new');
                    this.getSubStageListSubAccordian();
                    /*this.showErrorListBureau = false;
                    const genMap ={
                        'loanId':this.recordId,
                        'applicantId':this.appId,
                        'processName':'Gen AI',
                    }
                    initiateGenAI({
                        inputMap:genMap
                    })
                        .then(response=>{
                            console.log('Gen AI hit succesfully',JSON.stringify(response));
                            this.getSubStageListSubAccordian();
                        })
                        .catch(error => {
                            this.isloading = false;
                            console.log('Error in fetching document GEN AI name: ', JSON.stringify(error));
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'The system was unable to fetch Gen AI report with the provided document.',
                                    variant: 'error',
                                }),
                            );
                            this.ShowLoader =false;
                        })*/
                }
            }).catch(error => {
                console.log('Error in fetching document cibil name: ', JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'The system was unable to fetch Gen AI report with the provided document.',
                        variant: 'error',
                    }),
                );
                this.ShowLoader =false;
            })
    }
    callIndividualAPI() {
        const inputMap = {
            loanId: this.recordId,
            applicantId: this.appId,
            processName: 'Loan CRIF',
        };

        initiateAPIRequest({inputMap:inputMap})
        .then(response=>{
            console.log('result 83 Cibil API---',JSON.stringify(response))
            if(response.includes('Error:')){
                console.log('errorList--'+this.errorList);
                this.showErrorListBureau = true;
                this.isloading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'The system was unable to fetch CRIF',
                        variant: 'error',
                    }),
                );
            }
            else{
                console.log('Inside 94');
                this.isloading =false;
                this.getSubStageListSubAccordian();
                this.showErrorListBureau = false;
                const genMap ={
                    'loanId':this.recordId,
                    'applicantId':this.appId,
                    'processName':'Score Segment',
                }
                initiateGenAIScore({
                    inputMap:genMap
                })
                .then(response=>{
                    console.log('Gen AI hit succesfully',JSON.stringify(response));
                    this.getSubStageListSubAccordian();
                })
                .catch(error => {
                    this.isloading = false;
                    console.log('Error in fetching document GEN AI name: ', JSON.stringify(error));
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'The system was unable to fetch Gen AI report with the provided document.',
                            variant: 'error',
                        }),
                    );
                    this.ShowLoader =false;
                })
                const segmentMap ={
                    'loanId':this.recordId,
                    'applicantId':this.appId,
                    'processName':'AHL Scorecard',
                }
                initiateAPIRequestSegment({
                    inputMap:segmentMap
                }).then(response=>{
                    console.log('Fetched  segment score: ', JSON.stringify(response));
                    this.checkScoreSegment();
                })
                .catch(error => {
                    console.log('Error in fetching segment score: ', JSON.stringify(error));
                    this.checkScoreSegment();
                })
            }
        }).catch(error => {
            this.isloading = false;
            console.log('Error in fetching document crif name: ', JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'The system was unable to fetch CRIF',
                    variant: 'error',
                }),
            );
        })
    }

    callCommercialAPI() {
        const inputMap = {
            loanId: this.recordId,
            applicantId: this.appId,
            processName: 'Loan Crif Commercial',
        };

        initiateCommercialAPIRequest({inputMap:inputMap})
        .then(response=>{
            console.log('result 83 Cibil API---',JSON.stringify(response))
            if(response.includes('Error:')){
                console.log('errorList--'+this.errorList);
                this.showErrorListBureau = true;
                this.isloading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'The system was unable to fetch CRIF',
                        variant: 'error',
                    }),
                );
            }
            else{
                console.log('Inside 94');
                this.isloading = false;
                this.onLoadButton = false;
                this.showGetDataButton = true;
                this.showErrorListBureau = false;
            }

        }).catch(error => {
            this.isloading = false;
            console.log('Error in fetching document crif name: ', JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'The system was unable to fetch CRIF',
                    variant: 'error',
                }),
            );
        })
    }

    handleCrifCommercialResponse(response) {
        this.isloading = true;
        const inputMap = {
            loanId: this.recordId,
            applicantId: this.appId,
            processName: 'Loan Crif Commercial'
        };

        processCommercialCrifResponse({ inputMap: inputMap })
        .then(finalResponse => {
            if (finalResponse.includes('Error:')) {
                console.log('errorList--' + this.errorList);
                this.showErrorListBureau = true;
                this.isloading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'The system was unable to fetch CRIF report.',
                        variant: 'error',
                    }),
                );
            } else {
                console.log('Inside 94');
                this.isloading =false;
                this.getSubStageListSubAccordian();
                this.showErrorListBureau = false;
                const genMap ={
                    'loanId':this.recordId,
                    'applicantId':this.appId,
                    'processName':'Score Segment',
                }
                initiateGenAIScore({
                    inputMap:genMap
                })
                .then(response=>{
                    console.log('Gen AI hit succesfully',JSON.stringify(response));
                    this.getSubStageListSubAccordian();
                })
                .catch(error => {
                    this.isloading = false;
                    console.log('Error in fetching document GEN AI name: ', JSON.stringify(error));
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'The system was unable to fetch Gen AI report with the provided document.',
                            variant: 'error',
                        }),
                    );
                    this.ShowLoader =false;
                })

                this.showGetDataButton = false;
            }
        })
        .catch(error => {
            console.error('Error in processCommercialCrifResponse:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Something went wrong while processing the commercial CRIF response.',
                    variant: 'error',
                })
            );
            this.isloading = false;
        });
    }

    getCustomerType() {
        return getCustomerType({ appId: this.appId })
        .then(response => {
            console.log('response=: partner' + JSON.stringify(response));
            this.customerType = response.customerType;
            return response.customerType;
        })
        .catch(error => {
            console.log('Error in fetching customer type', error);
            return null;
        });
    }

    handleNext(){
        console.log('this.selectedCustIds-----',this.selectedCustIds);
        const valueChangeEvent = new CustomEvent("callnextaccordian", {
            detail: { value:this.recordId,name:'Applicant Information',currentAppSeq: this.currentAppSeq,section: 'C-KYC Details'}
        });
        this.dispatchEvent(valueChangeEvent);
    }

    callCIBILAPIHL(){
        console.log('Inside 762');
        this.isloading = true;
        const inputMap ={
            'loanId':this.recordId,
            'applicantId':this.appId,
            'processName':'Loan CIBIL',
        }
        console.log('Inside inputMap'+JSON.stringify(inputMap));
        initiateAPIRequestCiblHL({
            inputMap:inputMap
        })
        .then(response=>{
            console.log('result 83 Cibil API---',JSON.stringify(response))
            if (response.includes('PreReqError:')) {
                console.log('PreReqError--' + response);
                this.isloading = false;

                let errorMessage = response.split('PreReqError:')[1]?.trim();

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: errorMessage,
                        variant: 'error',
                    }),
                );
                return;
            }
            if(response.includes('Error:')){
                console.log('errorList--'+this.errorList);
                this.showErrorListBureau = true;
                this.isloading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'The system was unable to fetch CIBIL report with the provided document.',
                        variant: 'error',
                    }),
                );
            }
            else{
                console.log('Inside 94');
                this.showErrorListBureau = false;
                const genMap ={
                    'loanId':this.recordId,
                    'applicantId':this.appId,
                    'processName':'Gen AI',
                }
                initiateGenAI({
                    inputMap:genMap
                })
                .then(response=>{
                    console.log('Gen AI hit succesfully',JSON.stringify(response));
                    this.getSubStageListSubAccordian();
                })
                .catch(error => {
                    this.isloading = false;
                    console.log('Error in fetching document GEN AI name: ', JSON.stringify(error));
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'The system was unable to fetch Gen AI report with the provided document.',
                            variant: 'error',
                        }),
                    );
                    this.ShowLoader =false;
                })
            }
        }).catch(error => {
            console.log('Error in fetching document cibil name: ', JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'The system was unable to fetch Gen AI report with the provided document.',
                    variant: 'error',
                }),
            );
            this.ShowLoader =false;
        })
    }

    callCibilAPIFirst(){
        this.callCIBILAPIHL();
    }

}