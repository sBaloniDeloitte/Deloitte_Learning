import { LightningElement, api, track,wire } from 'lwc';
import getSubStageList from '@salesforce/apex/COMM_SalesLoanActionsController.getSubStageList';
import getApplicantList from '@salesforce/apex/COMM_SalesLoanActionsController.getApplicantList';
import checkIfKeyApplicantIsSelected from '@salesforce/apex/COMM_SalesLoanActionsController.checkIfKeyApplicantIsSelected';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLoanDetailsFromStorageObject from '@salesforce/apex/ScreenGenerationController.getLoanDetailsFromStorageObject';
import getFieldDependencies from '@salesforce/apex/ScreenGenerationController.getFieldDependencies';
import getScreenDetails from '@salesforce/apex/ScreenGenerationController.getScreenDetails';
import getPicklistValues from '@salesforce/apex/ScreenGenerationController.getPicklistValues';
import getApplicantValues from '@salesforce/apex/COMM_SalesLoanLoginController.getApplicantValues';
import checkExceptionStatus from '@salesforce/apex/COMM_SalesLoanLoginController.checkExceptionStatus';
import { getRecord } from 'lightning/uiRecordApi';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import LightningConfirm from 'lightning/confirm';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import updateLoanApplicationStage from '@salesforce/apex/COMM_SalesLoanLoginController.updateLoanApplicationStage';
import HL_Eligible_Bureau from '@salesforce/label/c.HL_Eligible_Bureau';
//HL-Ishi-25/09
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated';
//HL-Ishi-25/09
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
//changes by Kunal Bisht for SFHL-1420 - start
import checkIfApplicationVerificationRecordExists from '@salesforce/apex/COMM_SalesLoanActionsController.checkIfApplicationVerificationRecordExists';
import deleteCoAppAndRelatedRecords from '@salesforce/apex/COMM_SalesLoanActionsController.deleteCoAppAndRelatedRecords';
import getLoanApplicationStageByApplicantId from '@salesforce/apex/COMM_SalesLoanActionsController.getLoanApplicationStageByApplicantId';
//changes by Kunal Bisht for SFHL-1420 - end

export default class SalesLoginApplicantInformationCmp extends NavigationMixin(LightningElement) {
    applicantList = [];
    @api recordId;
    @api fromFlow = false;
    @api isNonIndividual;
    @api otherInfo;
    @api loginChecklist;
    @track openSections = [];
    @track openApplicantSections = [];
    @api passedScreenName = 'Applicant Information';
    @track allFieldDetails = [];
    @track fieldDetails;
    loanDetails;
    addressRefreshTrigger
    oppId;
    activeSectionName;
    processedStages = [];
    subStageList = [];
    isRendered = false;
    nextSequence = 1;
    currentStage;
    currentStagePersonalDetails = false;
    selectedApplicantId
    selectedStageName
    isDedupeEvent = false;
    dedupeList;
    isBasicDetails = false;
    isPrimaryDetails = false;
    showPrimaryDetails = false;
    isEmploymentDetails = false;
    activeSection;
    basicStage;
    openInPopUp = false;
    showBasicDetails = false;
    activeSectionToBePassed;
    makeAppCmponentVisible = false;
    @track currentAppSeq = 1;
    showConfBox = false;
    newSeq
    newAppSeq
    applicantSequence;
    custId;
    @api formName;
    confirmationMessage = "Are you sure you want to delete the applicant?";
    sectionName = [];
    isloading = false;
    cuurentAppId;
    @track applicantAccordionState = new Map();
    @track checkname;
    @track formIdentifier ="Loan Login Form";
    screenName = "Applicant's Basic Information";
    basicDetailsfetched = false;
    activeParentSectionName='';
    @wire(CurrentPageReference)
    pageRef;
    param1;
    param2;
    isNewApplicant = false;
    refreshData = false;
    @track isAadharDetails = false;
    @track isAddressDetails = false;
    @track isCKYCDetails = false;
    labelValue = HL_Eligible_Bureau;
    //HL-Ishi-24/09
    showCibil =false;
    showCrif =false;
    isHLUser = false;
    //HL-Ishi-24/09
    @track isHLRelated = false;
    // activeSectionNew = JSON.parse('{"isCompleted":false,"name":"Applicant’s Other Details","sequence":"2"}');
    @api changeMessage(str) {
        console.log('str.detail.name---', str.detail.name)
        this.passedScreenName = str.detail.name;
        setTimeout(() => {
            this.getApplicantList();
        }, 1000);


    }

    // Wire the getRecord method to the loan stage property
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [STAGE_FIELD] 
    })

    showDeleteCoAppBtn = false; //added by Kunal Bisht for SFHL-1420

    checkUserHL(){
        const inputMap = {
                            'oppId': this.recordId,
                        }
        console.log('Input for =: checkUserHL' + JSON.stringify(inputMap));
        getProductDetails({ inputMap: inputMap })
        .then(result => {
            console.log("getProductDetails Response::" + JSON.stringify(result));
            this.isHLRelated = result.isHLRelated;
            console.log("getProductDetails isHLRelated::" + this.isHLRelated);
        })
        .catch(error => {
            console.error('Error checking checkUserHL: ', JSON.stringify(error));
        });
    }

    connectedCallback() {
        this.checkUserHL();
        this.checkIfLoggedInUserIsHLRelated();
        console.log('labelValue----'+this.labelValue);
        if(this.labelValue =='Both'){
            this.showCibil =true;
            this.showCrif =true;
        }
        else if(this.labelValue =='Cibil'){
            this.showCibil =true;
            this.showCrif =false;
        }
        else if(this.labelValue =='Crif'){
            this.showCibil =false;
            this.showCrif =true;
        }
        this.getApplicantList();
        this.checkUserProfile();
        console.log('passedScreen--52 applicant information cmp', this.passedScreenName);
        this.isloading = true;
        setTimeout(() => {
        this.isloading = false;
        }, 2000);
    }

    isFieldDisable = false;
    checkUserProfile() {
        checkExceptionStatus({ loanId: this.recordId })
            .then(result => {
                console.log('Inside Profile true----', result);

                if (result || this.loanDetails.data.fields.StageName.value.toLowerCase() !== 'sales login'.toLowerCase()) {
                    this.isFieldDisable = true;
                }
            })
            .catch(error => {
                console.error('Error in checkExceptionStatus:', error);
            });
    }

    getApplicantList() {
        console.log('response applicantlist123',this.recordId,this.passedScreenName,this.formName);
        console.log('this.currentAppSeq 124-->',this.recordId);
        const urlParams = new URLSearchParams(window.location.search);
        // Assuming the record ID is passed as a parameter named 'id' in the URL
        // e.g., /lightning/n/MyPage?id=a00XXXXXXXXXXXXXXX
        console.log('window.location.search--->',urlParams);
        const id = urlParams.get('id'); 
        console.log('url id--->',id);
        console.log('opp id>',this.oppId);
        const oppIdConst = this.recordId == undefined ? this.oppId : this.recordId;
        getApplicantList({
            loanId: oppIdConst,
            applicableStage: this.passedScreenName,
            formName: this.formName
        }).then(response => {
            try {
                console.log('response getApplicantList Kshitiz console---', JSON.stringify(response));
                const isPrimaryNonIndividual = response.some(app => app.type === 'Primary Applicant' && app.isNonIndividual);
                this.applicantList = response.map((applicant, index) => {
                let stages = (applicant.stages || []).map(stage => ({
                    ...stage,
                    isSelected: false // default false
                }));

                // ✅ Remove Employment Details if profile is SEP or SENP
                // if (applicant.customerProfile === 'SEP' || (applicant.customerProfile === 'SENP' && applicant.isNonIndividual) || applicant.isFinancialApplicant == 'No') {
                //     stages = stages.filter(stage => stage.name !== 'Employment Details');
                // }
                // ✅ Remove Employment Details if primary applicant is non-individual
                // if (isPrimaryNonIndividual && applicant.type !== 'Primary Applicant') {
                //     stages = stages.filter(stage => stage.name !== 'Employment Details');
                // }
                if (applicant.customerProfile === 'SEP' || applicant.customerProfile === 'Non Working' || applicant.customerProfile === 'SENP' || applicant.isFinancialApplicant == 'No') {
                    stages = stages.filter(stage => stage.name !== 'Employment Details');
                }

                return {
                    ...applicant,
                    applicantId: applicant.applicantId,
                    sequence: index + 1,
                    isRemovable: applicant.name.startsWith('Applicant') || false,
                    stages: this.applyCkycStageGating(stages, applicant.isckycinitiated)
                };
                });
                
                console.log('response getApplicantList---', JSON.stringify(response));
               /* response.filter
                this.applicantList = response.map((applicant, index) => ({
                    ...applicant,
                    sequence: index + 1,
                    isRemovable: applicant.name.startsWith('Applicant ') || false,
                    stages: (applicant.stages || []).map(stage => ({
                        ...stage,
                        isSelected: false // Ensure default is false
                    }))
                }));*/
                console.log('applicantlist141',JSON.stringify(this.applicantList));
                console.log('sequence 142 -->',this.sequence);
                
                 this.checkname = this.applicantList.length > 0 ? this.applicantList[0].name : '';
                this.applicantList.forEach((applicant) => {
                    this.applicantAccordionState.set(applicant.sequence, applicant.sequence === 1);
                });
                console.log('checkname 143 -->',this.checkname);
                console.log('145',this.cuurentAppId);
                console.log('178 Applicant List Kshitiz-->',JSON.stringify(this.applicantList));
                if(this.cuurentAppId == null || this.cuurentAppId == undefined || this.currentAppId == ''){
                    this.cuurentAppId = this.applicantList[0].applicantId;
                    console.log('currentAppId =:105'+this.cuurentAppId);      
                    this.isNonIndividual = this.applicantList[0].isNonIndividual; //to pass this in the child component of salesckyc             
                }
                console.log('Initial applicantList:', JSON.stringify(this.applicantList));
                console.log('checknonindividual 147 -->',this.isNonIndividual);

                setTimeout(() => {
                    this.getSubStageList();
                },5000);
                console.log('Full pageRef:', JSON.stringify(this.pageRef));

                if (this.pageRef && this.pageRef.state && this.isNewApplicant==false) {
                    this.isloading = true;
                    setTimeout(() => {
                    this.param1 = this.pageRef.state.c__param1;
                    console.log('this.param1=:'+this.param1);
                
                        if(this.param1 == 'navigateToBasic'){

                  let updatedApplicantList = [...this.applicantList];
             console.log('Updated applicantListcheck before:', JSON.stringify(updatedApplicantList));

                            updatedApplicantList.forEach(iter => {
                                console.log('iter.sequence ',iter.sequence );
                                
                                    iter.stages = iter.stages.map(item => {                         
                                        console.log('item.name',item);
                                        if (item.name === 'Applicant\'s Basic Information') {
                                            console.log('item=:', JSON.stringify(item));
                                            item.isBasicDetails= true;
                                            // Step 1: Remove component from DOM by setting false
                                            this.activeSectionToBePassed = item;
                                            this.activeSectionName = 'Applicant\'s Basic Information';
                                            item.isApplicantCmp = false;
                                            item.isConsent = false;
                                            item.isSwapApplicant = false;
                                            item.isDocument = false;
                                            item.isBureau = false;
                                            item.isCKYCDetails = false;
                                            //HL-Ishi-23/09
                                            item.isCibil =false;
                                            item.isCrif=false;
                                            //HL-Ishi-23/09
                                            item.isApplicantAdditionalInformation = false;
                                            item.isApplicantAddressInformation = false;
                                            item.isPersonalInformation = false;
                                            item.isAddressInformation = false;
                                            item.isEmploymentInformation = false;
                                            item.isCurrentAddressInformation = false;
                                            item.isPermanentAddressInformation = false;
                                            item.isCurrentEmploymentInformation = false;
                                            item.isAnnualIncomeInformation = false;
                                            // setTimeout(()=>{
                                            item.isDeDupeScreen = false;
                    
                                        }
                                        return item;
                                    });
                                
                            });
                            console.log('Updated applicantListcheck:', JSON.stringify(this.applicantList));

                            // if (this.makeAppCmponentVisible) {
                            //     this.setPrimaryAccordian();
                            // }
                            // if (this.isDedupeEvent) {
                            //     this.setDefaultDedupeAccordion();
                            // }
                            // if (this.showBasicDetails) {
                            //     this.setDefaultBasicDetailsAccordian();
                            // }
                            this.isloading = false;
                            console.log(' this.applicantList 1---', JSON.stringify(this.applicantList));
                            this.nextSequence = this.applicantList.length + 1;
                            console.log('applucant list in checklist- 155--', JSON.stringify(this.applicantList));
                            console.log('applucant list in checklist- 155--', JSON.stringify(this.applicantList));
                        
                            // this.otherInfo = true;
                            // this.applicantList = updatedApplicantList;
                            
                            // setTimeout(() => {
                            //     let newApplicantList = [...this.applicantList];
                            //     newApplicantList.forEach(iter => {
                                
                            //             iter.stages = iter.stages.map(item => {
                            //                 if (item.name === 'Applicant\'s Basic Information') {
                    
                            //                     iter.isBasicDetails = true; // Now add it back
                            //                 }
                            //                 this.activeSectionToBePassed = item;
                            //                 this.activeSectionName = 'Applicant\'s Basic Information';
                            //                 item.isApplicantCmp = false;
                            //                 item.isConsent = false;
                            //                 item.isSwapApplicant = false;
                            //                 item.isDocument = false;
                            //                 item.isBureau = false;
                            //                 item.isApplicantAdditionalInformation = false;
                            //                 item.isApplicantAddressInformation = false;
                            //                 item.isPersonalInformation = false;
                            //                 item.isAddressInformation = false;
                            //                 item.isEmploymentInformation = false;
                            //                 item.isCurrentAddressInformation = false;
                            //                 item.isPermanentAddressInformation = false;
                            //                 item.isCurrentEmploymentInformation = false;
                            //                 item.isAnnualIncomeInformation = false;
                            //                 // setTimeout(()=>{
                            //                 item.isDeDupeScreen = false;
                            //                 return item;
                            //             });
                                    
                            //     });
                            //     //this.getApplicantList();
                            //     //this.applicantList = newApplicantList;
                                
                            // }, 10); 
                            
                        }
                        else if(this.param1 == 'navigateToDedupe'){
                            let updatedApplicantList = [...this.applicantList];
                            console.log('Updated applicantList navigatededupe', JSON.stringify(updatedApplicantList));
                            updatedApplicantList.forEach(iter => {
                                console.log('iter.sequencededupe ',iter.sequence );
                                    iter.stages = iter.stages.map(item => {
                                        console.log('item.name ',item.name );
                                        if (item.name === 'Dedupe') {
                                            console.log('item=dedupe:', JSON.stringify(item));
                                            item.isDeDupeScreen = true;
                                        
                                            // Step 1: Remove component from DOM by setting false
                                            this.activeSectionToBePassed = item;
                                            this.activeSectionName = 'Dedupe';
                                            item.isApplicantCmp = false;
                                            item.isConsent = false;
                                            item.isSwapApplicant = false;
                                            item.isDocument = false;
                                            item.isBureau = false;
                                            item.isCibil =false;
                                            item.isCrif=false;
                                            item.isApplicantAdditionalInformation = false;
                                            item.isApplicantAddressInformation = false;
                                            item.isPersonalInformation = false;
                                            item.isAddressInformation = false;
                                            item.isEmploymentInformation = false;
                                            item.isCurrentAddressInformation = false;
                                            item.isPermanentAddressInformation = false;
                                            item.isCurrentEmploymentInformation = false;
                                            item.isAnnualIncomeInformation = false;
                                            item.isBasicDetails= false;
                                            this.isAadharDetails = false;
                                            this.isAddressDetails = false;
                                            this.isCKYCDetails = false;
                                            // setTimeout(()=>{
                                        
                    
                                        }
                                        return item;
                                    });
                                
                            });
                            if (this.makeAppCmponentVisible) {
                                this.setPrimaryAccordian();
                            }
                            if (this.isDedupeEvent) {
                                this.setDefaultDedupeAccordion();
                            }
                            if (this.showBasicDetails) {
                                this.setDefaultBasicDetailsAccordian();
                            }
                            this.isloading = false;
                            console.log(' this.applicantList 2---', JSON.stringify(this.applicantList));
                            this.nextSequence = this.applicantList.length + 1;
                            console.log('applucant list in checklist- 155--', JSON.stringify(this.applicantList));
                        
                        }
                    
                        else{
                            if(this.loginChecklist){
                                console.log('Inside login checklist in applicnat--- 82');
                                this.openApplicantSections = [];
                                this.openSections = [];
                                this.applicantList.forEach(iter => {
                                    console.log('logincheckapplicantlist', JSON.stringify(iter));
                                    this.openApplicantSections.push(iter.name);
                                    if(this.currentAppSeq == iter.sequence){
                                        this.cuurentAppId = iter.applicantId;
                                    }
                                    iter.stages.forEach(item => {
                                        console.log('item 75-', JSON.stringify(item));
                                        this.openSections.push(item.name);
                                        item.isApplicantCmp = false;
                                        item.isConsent = false;
                                        item.isDeDupeScreen = false;
                                        item.isBasicDetails = false;
                                        item.isPanValidation = false;
                                        item.isDocument = false;
                                        item.isBureau = false;
                                        item.isCKYCDetails = false;
                                    //HL-Ishi-23/09
                                    item.isCibil =false;
                                    item.isCrif=false;
                                    //HL-Ishi-23/09
                                        item.isApplicantAdditionalInformation = false;
                                        item.isApplicantAddressInformation = false;
                                        item.isPersonalInformation = false;
                                        item.isAddressInformation = false;
                                        item.isEmploymentInformation = false;
                                        item.isCurrentAddressInformation = false;
                                        item.isPermanentAddressInformation = false;
                                        item.isCurrentEmploymentInformation = false;
                                        item.isAnnualIncomeInformation = false;
                                        if (item.name == 'Personal Information') {
                                            item.isPersonalInformation = true;
                                            this.isAadharDetails = false;
                                            this.isAddressDetails = false;
                                            this.isCKYCDetails = false;
                                        }else if(item.name == 'PAN Validation'){
                                            item.isPanValidation = true;
                                            this.isAadharDetails = false;
                                            this.isAddressDetails = false;
                                            this.isCKYCDetails = false;
                                        }else if(item.name == 'Bureau'){
                                            item.isBureau = true;
                                            this.isAadharDetails = false;
                                            this.isAddressDetails = false;
                                            this.isCKYCDetails = false;
                                        }else if(item.name == 'Address Information'){
                                            // this.formName = 'Address Information';
                                            // this.passedScreenName = 'Address Information';
                                            // this.getSubStageList();
                                            // console.log('at 478--');
                                            item.isApplicantAddressInformation = true;
                                            this.isAadharDetails = false;
                                            this.isAddressDetails = false;
                                            this.isCKYCDetails = false;
                                        }else if (item.name == 'Aadhar Details'){
                                            this.isAadharDetails = true;
                                            item.isAadharDetails = true;
                                            item.isBasicDetails = false;
                                            this.isAddressDetails = false;
                                            this.isCKYCDetails = false;
                                        }
                                        else if (item.name == 'Address Details'){
                                            this.isAddressDetails = true;
                                            item.isAddressDetails = true;
                                            item.isBasicDetails = false;
                                            this.isAadharDetails = false;
                                            this.isCKYCDetails = false;
                                        }else if (item.name == 'C-KYC Details'){
                                            this.isAddressDetails = false;
                                            item.isCKYCDetails = true;
                                            item.isBasicDetails = false;
                                            this.isAadharDetails = false;
                                            this.isCKYCDetails = true;
                                        }
                                        else if (item.name == 'Employment Details'){
                                            item.isEmploymentDetails = true;
                                        }
                                        
                                    })
            
                                })
                                console.log('applucant list in checklist---', JSON.stringify(this.applicantList));
                                console.log('opensections in applicantsss--', JSON.stringify(this.openSections));
                                console.log('openApplicants in applicanrsss--', JSON.stringify(this.openApplicantSections));
                                
                        }else{
                                if(this.trackingScreenName != undefined && this.trackingScreenName != null && this.trackingScreenName != ''){
                                    if(this.trackingScreenName == 'Applicant\'s Basic Information'){
                                        console.log('this.trackingScreenName =:435',this.trackingScreenName );   
                                        this.applicantList.forEach(iter => {
                                            console.log('trackingapplicantlist',JSON.stringify(iter));
                                                iter.stages.forEach(item => {
                                                    console.log('item 76-', item);
                                                    this.activeSectionName = 'Applicant\'s Basic Information';
                                                    
                                                    item.isApplicantCmp = false;
                                                    item.isConsent = false;
                                                    item.isDeDupeScreen = false;
                                                    item.isBasicDetails = false;
                                                    item.isEmploymentDetails = false;
                                                    item.isPanValidation = false;
                                                    item.isDocument = false;
                                                    item.isBureau = false;
                                                    item.isCKYCDetails = false;
                                            //HL-Ishi-23/09
                                            item.isCibil =false;
                                            item.isCrif=false;
                                            //HL-Ishi-23/09
                                                    item.isApplicantAdditionalInformation = false;
                                                    item.isApplicantAddressInformation = false;
                                                    item.isPersonalInformation = false;
                                                    item.isAddressInformation = false;
                                                    item.isEmploymentInformation = false;
                                                    item.isCurrentAddressInformation = false;
                                                    item.isPermanentAddressInformation = false;
                                                    item.isCurrentEmploymentInformation = false;
                                                    item.isAnnualIncomeInformation = false;
                                                    this.isAadharDetails = false;
                                                    this.isAddressDetails = false;
                                                    this.isCKYCDetails = false;
                                                    if (item.name == 'Applicant\'s Basic Information') {
                                                        this.activeSectionToBePassed = item;
                                                        item.isBasicDetails = true;
                                                        this.isAadharDetails = false;
                                                        this.isAddressDetails = false;
                                                        this.isCKYCDetails = false;
                                                    }
                                                    if (item.name == 'Personal Information') {
                                                         this.activeSectionToBePassed = item;
                                                        item.isPersonalInformation = true;
                                                        this.isAadharDetails = false;
                                                        this.isAddressDetails = false;
                                                        this.isCKYCDetails = false;
                                                    }else if(item.name == 'PAN Validation'){
                                                         this.activeSectionToBePassed = item;
                                                        item.isPanValidation = true;
                                                        this.isAadharDetails = false;
                                                        this.isAddressDetails = false;
                                                        this.isCKYCDetails = false;
                                                    }else if(item.name == 'Bureau'){
                                                         this.activeSectionToBePassed = item;
                                                        item.isBureau = true;
                                                        this.isAadharDetails = false;
                                                        this.isAddressDetails = false;
                                                        this.isCKYCDetails = false;
                                                    }else if(item.name == 'Address Information'){
                                                         this.activeSectionToBePassed = item;
                                                        item.isApplicantAddressInformation = true;
                                                        this.isAadharDetails = false;
                                                        this.isAddressDetails = false;
                                                        this.isCKYCDetails = false;
                                                    }
                                                    
                                                })
                                            //}
                    
                                        })
                                    }
                                    else if(this.trackingScreenName == 'Dedupe'){
                                        console.log('this.trackingScreenName =:466',this.trackingScreenName );   
                                        console.log('applicantlistchecking',this.applicantList);
                                        this.applicantList.forEach(iter => {
                                            iter.stages.forEach(item => {
                                                console.log('item 77-', item);
                                                this.activeSectionName = 'Dedupe';
                                                this.activeSectionToBePassed = item;
                                                item.isApplicantCmp = false;
                                                item.isConsent = false;
                                                item.isDeDupeScreen = true;
                                                item.isBasicDetails = false;
                                                item.isPanValidation = false;
                                                item.isDocument = false;
                                                item.isBureau = false;
                                                item.isCKYCDetails = false;
                                            //HL-Ishi-23/09
                                            item.isCibil =false;
                                            item.isCrif=false;
                                            //HL-Ishi-23/09
                                                item.isApplicantAdditionalInformation = false;
                                                item.isApplicantAddressInformation = false;
                                                item.isPersonalInformation = false;
                                                item.isAddressInformation = false;
                                                item.isEmploymentInformation = false;
                                                item.isCurrentAddressInformation = false;
                                                item.isPermanentAddressInformation = false;
                                                item.isCurrentEmploymentInformation = false;
                                                item.isAnnualIncomeInformation = false;
                                                this.isAadharDetails = false;
                                                this.isAddressDetails = false;
                                                this.isCKYCDetails = false;
                                                if (item.name == 'Personal Information') {
                                                    item.isPersonalInformation = true;
                                                    this.isAadharDetails = false;
                                                    this.isAddressDetails = false;
                                                    this.isCKYCDetails = false;
                                                }else if(item.name == 'PAN Validation'){
                                                    item.isPanValidation = true;
                                                    this.isAadharDetails = false;
                                                    this.isAddressDetails = false;
                                                    this.isCKYCDetails = false;
                                                }else if(item.name == 'Bureau'){
                                                    item.isBureau = true;
                                                    this.isAadharDetails = false;
                                                    this.isAddressDetails = false;
                                                    this.isCKYCDetails = false;
                                                }else if(item.name == 'Address Information'){
                                                    item.isApplicantAddressInformation = true;
                                                    this.isAadharDetails = false;
                                                    this.isAddressDetails = false;
                                                    this.isCKYCDetails = false;
                                                }
                                                else if(item.name == 'Aadhar Details'){
                                                    this.isAadharDetails = true;
                                                    this.isAddressDetails = false;
                                                    item.isBasicDetails = false;
                                                    this.isCKYCDetails = false;
                                                }
                                                else if(item.name == 'Address Details'){
                                                    this.isAadharDetails = false;
                                                    this.isAddressDetails = true;
                                                    item.isBasicDetails = false;
                                                    this.isCKYCDetails = false;
                                                }else if(item.name == 'C-KYC Details'){
                                                    this.isAadharDetails = false;
                                                    this.isAddressDetails = false;
                                                    item.isBasicDetails = false;
                                                    this.isCKYCDetails = true;
                                                }
                                            //HL-Ishi-23/09
                                            else if(this.isHLUser && (this.labelValue=='Both'||this.labelValue=='Cibil') &&  item.name == 'Cibil'){
                                                item.isCibil =true;
                                                item.isBureau=false;
                                                this.isAadharDetails = false;
                                                this.isAddressDetails = false;
                                                item.isBasicDetails = false;
                                                this.isCKYCDetails = false;
                                                item.isBureau = false;
                                            }
                                            else if(this.isHLUser && (this.labelValue=='Both'||this.labelValue=='Crif') && item.name == 'Crif'){
                                                item.isCrif =true;
                                                item.isBureau = false;
                                                this.isAadharDetails = false;
                                                this.isAddressDetails = false;
                                                item.isBasicDetails = false;
                                                this.isCKYCDetails = false;
                                            }
                                            //HL-Ishi-23/09
                                                return item;
                                            })
                                            
                                        })
                                    }
                                    else{
                                        this.applicantList.forEach(iter => {
                                            console.log('line no 632',JSON.stringify(iter));
                                            iter.stages.forEach(item => {
                                                console.log('item 78-', item);
                                                this.activeSectionName = 'PAN/Form 60 Details';
                                                this.activeSectionToBePassed = item;
                                                item.isApplicantCmp = true;
                                                item.isConsent = false;
                                                item.isDeDupeScreen = false;
                                                item.isBasicDetails = false;
                                                item.isPanValidation = false;
                                                item.isDocument = false;
                                                item.isBureau = false;
                                                item.isCKYCDetails = false;
                                            //HL-Ishi-23/09
                                            item.isCibil =false;
                                            item.isCrif=false;
                                            //HL-Ishi-23/09
                                                item.isApplicantAdditionalInformation = false;
                                                item.isApplicantAddressInformation = false;
                                                item.isPersonalInformation = false;
                                                item.isAddressInformation = false;
                                                item.isEmploymentInformation = false;
                                                item.isCurrentAddressInformation = false;
                                                item.isPermanentAddressInformation = false;
                                                item.isCurrentEmploymentInformation = false;
                                                item.isAnnualIncomeInformation = false;
                                                item.isAadharDetails = true;
                                                item.isAddressDetails = true;
                                                item.isCKYCDetails = true;
                                                this.isAadharDetails = false;
                                                this.isAddressDetails = false;
                                                this.isCKYCDetails = false;
                                                item.isEmploymentDetails = false;
                                                if (item.name == 'Personal Information') {
                                                    item.isPersonalInformation = true;
                                                    this.isAadharDetails = false;
                                                    this.isAddressDetails = false;
                                                    this.isCKYCDetails = false;
                                                }else if(item.name == 'PAN Validation'){
                                                    item.isPanValidation = true;
                                                    this.isAadharDetails = false;
                                                    this.isAddressDetails = false;
                                                    this.isCKYCDetails = false;
                                                }else if(item.name == 'Bureau'){
                                                    item.isBureau = true;
                                                    this.isAadharDetails = false;
                                                    this.isAddressDetails = false;
                                                    this.isCKYCDetails = false;
                                                }else if(item.name == 'Address Information'){
                                                    item.isApplicantAddressInformation = true;
                                                    this.isAadharDetails = false;
                                                    this.isAddressDetails = false;
                                                    this.isCKYCDetails = false;
                                                }
                                                else if(item.name == 'Aadhar Details'){
                                                    //item.showUploadOrManualScreen = true;
                                                    this.isAadharDetails = true;
                                                    this.isAddressDetails = false;
                                                    item.isApplicantCmp = false;
                                                    this.isCKYCDetails = false;
                                                }
                                                else if(item.name == 'Address Details'){
                                                    this.isAadharDetails = false;
                                                    this.isAddressDetails = true;
                                                    item.isApplicantCmp = false;
                                                    this.isCKYCDetails = false;
                                                } else if(item.name == 'C-KYC Details'){
                                                    this.isAadharDetails = false;
                                                    this.isAddressDetails = false;
                                                    item.isApplicantCmp = false;
                                                    this.isCKYCDetails = true;
                                                }
                                             //HL-Ishi-23/09
                                            else if(this.isHLUser && (this.labelValue=='Both'||this.labelValue=='Cibil') && item.name == 'Cibil'){
                                                item.isCibil =true;
                                                this.isAadharDetails = false;
                                                this.isAddressDetails = false;
                                                item.isBasicDetails = false;
                                                this.isCKYCDetails = false;
                                                item.isBureau = false;
                                            }
                                            else if(this.isHLUser &&(this.labelValue=='Both'||this.labelValue=='Crif') && item.name == 'Crif'){
                                                item.isCrif =true;
                                                item.isBureau = false;
                                                this.isAadharDetails = false;
                                                this.isAddressDetails = false;
                                                item.isBasicDetails = false;
                                                this.isCKYCDetails = false;
                                            }
                                            //HL-Ishi-23/09

                                                
                                            })
                    
                                        })
                                    }
                                }
                                else{
                                    console.log('this.trackingScreenName =:50444',this.trackingScreenName ); 
                                    console.log('this.applicantList =:50444',this.applicantList );  
                                    this.applicantList.forEach(iter => {
                                        console.log('line no 733',JSON.stringify(iter));
                                        iter.stages.forEach(item => {
                                            console.log('item 79-', item);
                                            this.activeSectionName = 'C-KYC Details';
                                            this.activeSectionToBePassed = item;
                                            item.isApplicantCmp = true;
                                            item.isConsent = false;
                                            item.isDeDupeScreen = false;
                                            item.isBasicDetails = false;
                                            item.isPanValidation = false;
                                            item.isDocument = false;
                                            item.isBureau = false;
                                        item.isCKYCDetails = false;
                                        //HL-Ishi-23/09
                                        item.isCibil =false;
                                        item.isCrif=false;
                                        //HL-Ishi-23/09
                                            item.isApplicantAdditionalInformation = false;
                                            item.isApplicantAddressInformation = false;
                                            item.isPersonalInformation = false;
                                            item.isAddressInformation = false;
                                            item.isEmploymentInformation = false;
                                            item.isCurrentAddressInformation = false;
                                            item.isPermanentAddressInformation = false;
                                            item.isCurrentEmploymentInformation = false;
                                            item.isAnnualIncomeInformation = false;
                                            item.isEmploymentDetails = false;
                                            this.isAadharDetails = false;
                                            item.isCKYCDetails = true; //Added by Kshitiz AHL 26/09/2024
                                            this.isAddressDetails = false;
                                            this.isCKYCDetails = false;
                                            if (item.name == 'Personal Information') {
                                                item.isPersonalInformation = true;
                                            item.isCKYCDetails = false;
                                                item.isCKYCDetails = false;
                                                this.isAadharDetails = false;
                                                this.isAddressDetails = false;
                                                this.isCKYCDetails = false;
                                            }else if(item.name == 'PAN Validation'){
                                                item.isPanValidation = true;
                                                item.isCKYCDetails = false;
                                                this.isAadharDetails = false;
                                                this.isAddressDetails = false;
                                                this.isCKYCDetails = false;
                                            }
                                            else if(item.name == 'PAN/Form 60 Details'){
                                                item.isApplicantCmp = true;
                                                item.isCKYCDetails = false;
                                            }
                                            else if(item.name == 'Bureau'){
                                                item.isBureau = true;
                                                this.isAadharDetails = false;
                                                this.isAddressDetails = false;
                                                this.isCKYCDetails = false;
                                            }else if(item.name == 'Address Information'){
                                                item.isApplicantAddressInformation = true;
                                                this.isAadharDetails = false;
                                                this.isAddressDetails = false;
                                                this.isCKYCDetails = false;
                                            }
                                            else if(item.name == 'Aadhar Details'){
                                                item.isCKYCDetails = false;
                                                this.isAadharDetails = true;
                                                this.isAddressDetails = false;
                                                item.isApplicantCmp = false;
                                                this.isCKYCDetails = false;
                                            }
                                            else if(item.name == 'Address Details'){
                                                this.isAadharDetails = false;
                                                this.isAddressDetails = true;
                                                item.isApplicantCmp = false;
                                                this.isCKYCDetails = false;
                                            }else if(item.name == 'C-KYC Details'){
                                                item.isCKYCDetails = true;
                                                this.isAadharDetails = false;
                                                this.isAddressDetails = false;
                                                item.isApplicantCmp = false;
                                                this.isCKYCDetails = true;
                                            }
                                         //HL-Ishi-23/09
                                        else if(this.isHLUser && (this.labelValue=='Both'||this.labelValue=='Cibil') && item.name == 'Cibil'){
                                            item.isCibil =true;
                                            this.isAadharDetails = false;
                                            this.isAddressDetails = false;
                                            item.isBasicDetails = false;
                                            this.isCKYCDetails = false;
                                        }
                                        else if(this.isHLUser && (this.labelValue=='Both'||this.labelValue=='Crif') && item.name == 'Crif'){
                                            item.isCrif =true;
                                            item.isBureau = false;
                                            this.isAadharDetails = false;
                                            this.isAddressDetails = false;
                                            item.isBasicDetails = false;
                                            this.isCKYCDetails = false;
                                        }
                                        //HL-Ishi-23/09
                                                                                    
                                        })
                
                                    })   
                                }
                                // this.applicantList.forEach(iter => {
                                //     iter.stages.forEach(item => {
                                //         console.log('item 75-', item);
                                //         this.activeSectionName = 'PAN Details';
                                //         this.activeSectionToBePassed = item;
                                //         item.isApplicantCmp = true;
                                //         item.isConsent = false;
                                //         item.isDeDupeScreen = false;
                                //         item.isBasicDetails = false;
                                //         item.isPanValidation = false;
                                //         item.isDocument = false;
                                //         item.isBureau = false;
                                //         item.isApplicantAdditionalInformation = false;
                                //         item.isApplicantAddressInformation = false;
                                //         item.isPersonalInformation = false;
                                //         item.isAddressInformation = false;
                                //         item.isEmploymentInformation = false;
                                //         item.isCurrentAddressInformation = false;
                                //         item.isPermanentAddressInformation = false;
                                //         item.isCurrentEmploymentInformation = false;
                                //         item.isAnnualIncomeInformation = false;
                                //         if (item.name == 'Personal Information') {
                                //             item.isPersonalInformation = true;
                                //         }else if(item.name == 'PAN Validation'){
                                //             item.isPanValidation = true;
                                //         }else if(item.name == 'Bureau'){
                                //             item.isBureau = true;
                                //         }else if(item.name == 'Address Information'){
                                //             item.isApplicantAddressInformation = true;
                                //         }
                                        
                                //     })
            
                                // })
                            }
                            
                        // }, 2000)
        
                            // if (this.makeAppCmponentVisible) {
                            //     this.setPrimaryAccordian();
                            // }
                            // if (this.isDedupeEvent) {
                            //     this.setDefaultDedupeAccordion();
                            // }
                            // if (this.showBasicDetails) {
                            //     this.setDefaultBasicDetailsAccordian();
                            // }
                            this.isloading = false;
                            console.log(' this.applicantList 3---', JSON.stringify(this.applicantList));
                            this.nextSequence = this.applicantList.length + 1;
                        }
                        this.isloading = false;
                    },500);
                } 
                else{
                    console.log('this.pageRef =:374'+this.pageRef);   
                    if(this.loginChecklist){
                        console.log('Inside login checklist in applicnat--- 82');
                        this.openApplicantSections = [];
                        this.openSections = [];
                        this.applicantList.forEach(iter => {
                            console.log('line no 895', JSON.stringify(iter));
                            this.openApplicantSections.push(iter.name);
                            if(this.currentAppSeq == iter.sequence){
                                this.cuurentAppId = iter.applicantId;
                            }
                            iter.stages.forEach(item => {
                                console.log('item 80-', JSON.stringify(item));
                                this.openSections.push(item.name);
                                item.isApplicantCmp = false;
                                item.isConsent = false;
                                item.isDeDupeScreen = false;
                                item.isBasicDetails = false;
                                item.isPanValidation = false;
                                item.isDocument = false;
                                item.isBureau = false;
                                item.isCKYCDetails = false;
                                //HL-Ishi-23/09
                                item.isCibil =false;
                                item.isCrif=false;
                                //HL-Ishi-23/09
                                item.isApplicantAdditionalInformation = false;
                                item.isApplicantAddressInformation = false;
                                item.isPersonalInformation = false;
                                item.isAddressInformation = false;
                                item.isEmploymentInformation = false;
                                item.isCurrentAddressInformation = false;
                                item.isPermanentAddressInformation = false;
                                item.isCurrentEmploymentInformation = false;
                                item.isAnnualIncomeInformation = false;
                                if (item.name == 'Personal Information') {
                                    item.isPersonalInformation = true;
                                }else if(item.name == 'PAN Validation'){
                                    item.isPanValidation = true;
                                }else if(item.name == 'Bureau'){
                                    item.isBureau = true;
                                }else if(item.name == 'Address Information'){
                                    // this.formName = 'Address Information';
                                    // this.passedScreenName = 'Address Information';
                                    // this.getSubStageList();
                                    // console.log('at 478--');
                                    item.isApplicantAddressInformation = true;
                                }
                                //HL-Ishi-23/09
                                else if(this.isHLUser && (this.labelValue=='Both'||this.labelValue=='Cibil') && item.name ==' Cibil'){
                                    item.isCibil =true;
                                    item.isBureau = false;
                                }
                                else if(this.isHLUser && (this.labelValue=='Both'||this.labelValue=='Crif') && item.name =='Crif'){
                                    item.isCrif =true;
                                    item.isBureau = false;
                                }
                                //HL-Ishi-23/09
                                
                            })
    
                        })
                        console.log('applucant list in checklist---', JSON.stringify(this.applicantList));
                        console.log('opensections in applicantsss--', JSON.stringify(this.openSections));
                        console.log('openApplicants in applicanrsss--', JSON.stringify(this.openApplicantSections));
                        
                    }else{
                        console.log('this.pageRef =:435');   
                        console.log('this.trackingScreenName=:452=:'+this.trackingScreenName);
                        console.log('Applicant list before trackinscreen',JSON.stringify(this.applicantList));
                        if(this.trackingScreenName != undefined && this.trackingScreenName != null && this.trackingScreenName != ''){
                            if(this.trackingScreenName == 'Applicant\'s Basic Information'){
                                console.log('this.trackingScreenName =:435',this.trackingScreenName );   
                                this.applicantList.forEach(iter => {
                                    console.log('lone no 963',JSON.stringify(iter));
                                    iter.stages.forEach(item => {
                                        console.log('item 81-', item);
                                        this.activeSectionName = 'Applicant\'s Basic Information';
                                        this.activeSectionToBePassed = item;
                                        item.isApplicantCmp = false;
                                        item.isConsent = false;
                                        item.isDeDupeScreen = false;
                                        item.isBasicDetails = true;
                                        item.isEmploymentDetails = true;
                                        item.isPanValidation = false;
                                        item.isDocument = false;
                                        item.isBureau = false;
                                        item.isCKYCDetails = false;
                                        //HL-Ishi-23/09
                                        item.isCibil =false;
                                        item.isCrif=false;
                                        //HL-Ishi-23/09
                                        item.isApplicantAdditionalInformation = false;
                                        item.isApplicantAddressInformation = false;
                                        item.isPersonalInformation = false;
                                        item.isAddressInformation = false;
                                        item.isEmploymentInformation = false;
                                        item.isCurrentAddressInformation = false;
                                        item.isPermanentAddressInformation = false;
                                        item.isCurrentEmploymentInformation = false;
                                        item.isAnnualIncomeInformation = false;
                                        // if (item.name == 'Personal Information') {
                                        //     item.isPersonalInformation = true;
                                        // }else if(item.name == 'PAN Validation'){
                                        //     item.isPanValidation = true;
                                        // }else if(item.name == 'Bureau'){
                                        //     item.isBureau = true;
                                        // }else if(item.name == 'Address Information'){
                                        //     item.isApplicantAddressInformation = true;
                                        // }
                                        // //HL-Ishi-23/09
                                        // else if(item.name=='Cibil'){
                                        //     item.isCibil =true;
                                        // }
                                        // else if(item.name=='Crif'){
                                        //     item.isCrif=true;
                                        // }
                                        // //HL-Ishi-23/09
                                        
                                    })
            
                                })
                            }
                            else if(this.trackingScreenName == 'Dedupe'){
                                console.log('this.trackingScreenName =:466',this.trackingScreenName );   
                                this.applicantList.forEach(iter => {
                                    console.log('line no 1015',JSON.stringify(iter));
                                    iter.stages.forEach(item => {
                                        console.log('item 82-', item);
                                        this.activeSectionName = 'Dedupe';
                                        this.activeSectionToBePassed = item;
                                        item.isApplicantCmp = false;
                                        item.isConsent = false;
                                        item.isDeDupeScreen = true;
                                        item.isBasicDetails = false;
                                        item.isPanValidation = false;
                                        item.isDocument = false;
                                        item.isBureau = false;
                                        item.isCKYCDetails = false;
                                        //Hl-Ishi-23/09
                                        item.isCibil=false;
                                        item.isCrif=false;
                                        //HL-Ishi-23/09
                                        item.isApplicantAdditionalInformation = false;
                                        item.isApplicantAddressInformation = false;
                                        item.isPersonalInformation = false;
                                        item.isAddressInformation = false;
                                        item.isEmploymentInformation = false;
                                        item.isCurrentAddressInformation = false;
                                        item.isPermanentAddressInformation = false;
                                        item.isCurrentEmploymentInformation = false;
                                        item.isAnnualIncomeInformation = false;
                                        this.isAadharDetails = false;
                                         this.isAddressDetails = false;
                                         this.isCKYCDetails = false;
                                        if (item.name == 'Personal Information') {
                                            item.isPersonalInformation = true;
                                            this.isAadharDetails = false;
                                             this.isAddressDetails = false;
                                             this.isCKYCDetails = false;
                                        }else if(item.name == 'PAN Validation'){
                                            item.isPanValidation = true;
                                            this.isAadharDetails = false;
                                             this.isAddressDetails = false;
                                             this.isCKYCDetails = false;
                                        }else if(item.name == 'Bureau'){
                                            item.isBureau = true;
                                            this.isAadharDetails = false;
                                             this.isAddressDetails = false;
                                             this.isCKYCDetails = false;
                                        }else if(item.name == 'Address Information'){
                                            item.isApplicantAddressInformation = true;
                                            this.isAadharDetails = false;
                                             this.isAddressDetails = false;
                                             this.isCKYCDetails = false;
                                        }
                                        else if(item.name == 'Aadhar Details'){
                                            this.isAadharDetails = true;
                                             this.isAddressDetails = false;
                                            item.isApplicantCmp = false;
                                            this.isCKYCDetails = false;
                                        }
                                        else if(item.name == 'Address Details'){
                                            this.isAadharDetails = false;
                                            this.isAddressDetails = true;
                                            item.isApplicantCmp = false;
                                            this.isCKYCDetails = false;
                                        }else if(item.name == 'C-KYC Details'){
                                            this.isAadharDetails = false;
                                            this.isAddressDetails = false;
                                            item.isApplicantCmp = false;
                                            this.isCKYCDetails = true;
                                        }
                                         //HL-Ishi-23/09
                                        else if(item.name=='Cibil'){
                                            item.isCibil =true;
                                            this.isAadharDetails = false;
                                            this.isAddressDetails = false;
                                            item.isApplicantCmp = false;
                                            this.isCKYCDetails = false;
                                        }
                                        else if(item.name=='Crif'){
                                            item.isCrif=true;
                                            this.isAadharDetails = false;
                                            this.isAddressDetails = false;
                                            item.isApplicantCmp = false;
                                            this.isCKYCDetails = false;
                                        }
                                        //HL-Ishi-23/09
                                         return item;
                                    })
                                    
                                })
                            }
                        }
                        else{
                            console.log('this.trackingScreenName =:50444',this.trackingScreenName );   
                            this.applicantList.forEach(iter => {
                                console.log('line no 1107',JSON.stringify(iter));
                                iter.stages.forEach(item => {
                                    console.log('item 83-', item);
                                    this.activeSectionName = 'PAN/Form 60 Details';
                                    this.activeSectionToBePassed = item;
                                    item.isApplicantCmp = true;
                                    item.isConsent = false;
                                    item.isDeDupeScreen = false;
                                    item.isBasicDetails = false;
                                    item.isPanValidation = false;
                                    item.isDocument = false;
                                    item.isBureau = false;
                                    item.isCKYCDetails = false;
                                    //HL-Ishi-23/09
                                    item.isCibil = false;
                                    item.isCrif =false;
                                    //HL-Ishi-23/09
                                    item.isApplicantAdditionalInformation = false;
                                    item.isApplicantAddressInformation = false;
                                    item.isPersonalInformation = false;
                                    item.isAddressInformation = false;
                                    item.isEmploymentInformation = false;
                                    item.isCurrentAddressInformation = false;
                                    item.isPermanentAddressInformation = false;
                                    item.isCurrentEmploymentInformation = false;
                                    item.isAnnualIncomeInformation = false;
                                    item.isEmploymentDetails = false;
                                    this.isAadharDetails = false;
                                     this.isAddressDetails = false;
                                      this.isCKYCDetails = false;
                                    if (item.name == 'Personal Information') {
                                        item.isPersonalInformation = true;
                                        this.isAadharDetails = false;
                                         this.isAddressDetails = false;
                                          this.isCKYCDetails = false;
                                    }else if(item.name == 'PAN Validation'){
                                        item.isPanValidation = true;
                                        this.isAadharDetails = false;
                                         this.isAddressDetails = false;
                                          this.isCKYCDetails = false;
                                    }else if(item.name == 'Bureau'){
                                        item.isBureau = true;
                                        this.isAadharDetails = false;
                                         this.isAddressDetails = false;
                                          this.isCKYCDetails = false;
                                    }else if(item.name == 'Address Information'){
                                        item.isApplicantAddressInformation = true;
                                        this.isAadharDetails = false;
                                         this.isAddressDetails = false;
                                          this.isCKYCDetails = false;
                                    }
                                    else if(item.name == 'Aadhar Details'){
                                        item.isApplicantCmp = false;
                                        this.isAadharDetails = true;
                                         this.isAddressDetails = false;
                                        item.isBasicDetails = false;
                                         this.isCKYCDetails = false;
                                    }
                                     else if(item.name == 'Address Details'){
                                        item.isApplicantCmp = false;
                                        this.isAadharDetails = false;
                                        this.isAddressDetails = true;
                                        item.isBasicDetails = false;
                                         this.isCKYCDetails = false;
                                    } else if(item.name == 'C-KYC Details'){
                                        item.isApplicantCmp = false;
                                        this.isAadharDetails = false;
                                        this.isAddressDetails = false;
                                        item.isBasicDetails = false;
                                         this.isCKYCDetails = true;
                                    }
                                    //HL-Ishi-23/09
                                    else if(item.name == 'Cibil'){
                                        item.isCibil = true;
                                        item.isApplicantCmp = false;
                                        this.isAadharDetails = false;
                                        this.isAddressDetails = false;
                                        item.isBasicDetails = false;
                                         this.isCKYCDetails = false;
                                    }
                                    else if(item.name == 'Crif'){
                                       item.isCibil = true;                                         
                                        item.isApplicantCmp = false;
                                        this.isAadharDetails = false;
                                        this.isAddressDetails = false;
                                        item.isBasicDetails = false;
                                        this.isCKYCDetails = false;
                                    }
                                   
                                    //HL-Ishi-23/09
                                     
                                })
        
                            })   
                        }
                    }
                    
                // }, 2000)

                    if (this.makeAppCmponentVisible) {
                        this.setPrimaryAccordian();
                    }
                    if (this.isDedupeEvent) {
                        this.setDefaultDedupeAccordion();
                    }
                    if (this.showBasicDetails) {
                        this.setDefaultBasicDetailsAccordian();
                    }
                    this.isloading = false;
                    console.log(' this.applicantList 4---', JSON.stringify(this.applicantList));
                    this.nextSequence = this.applicantList.length + 1;

                }
                // this.isloading = true;
                // setTimeout(() => {
                    console.log('response getApplicantList 72---', JSON.stringify(response));
                  
            }
            catch (error) {
                console.log('error =:' + error);
            }


        }).catch(error => {
            console.error('Error fetching applicants:', error);
            this.applicantList = [];
        });
    }

    // Hides stage accordions that come after the C-KYC Details stage until the user clicks "Initiate CKYC"
    applyCkycStageGating(stages, isCkycInitiated) {
        const ckycIndex = stages.findIndex(stage => stage.name === 'C-KYC Details');
        if (ckycIndex === -1) {
            return stages.map(stage => ({ ...stage, showAccordionSection: true }));
        }
        return stages.map((stage, idx) => ({
            ...stage,
            showAccordionSection: idx <= ckycIndex ? true : isCkycInitiated
        }));
    }

    // Fired by c-sales-c-k-y-c-details-cmp when the user clicks "Initiate CKYC".
    // Reveals the stage accordions that come after C-KYC Details for that applicant.
    handleCkycInitiated(event) {
        const applicantId = event.detail.applicantId;
        this.applicantList = this.applicantList.map(applicant => {
            if (applicant.applicantId !== applicantId) {
                return applicant;
            }
                return {
                ...applicant,
                stages: this.applyCkycStageGating(applicant.stages, true)
            };
            
            
        });
    }

    getCurrentApplicantList() {
        console.log('here in getCurrentApplicantList');
        getApplicantList({
            loanId: this.recordId,
            applicableStage: this.passedScreenName
        }).then(response => {
            try {
                console.log('response getApplicantList---', JSON.stringify(response));
                this.getSubStageList();
                this.applicantList = response.map((applicant, index) => ({
                    ...applicant,
                    sequence: index + 1,

                    isRemovable: applicant.name.startsWith('Applicant '),
                    stages: applicant.stages.map(stage => ({
                        ...stage,
                        isSelected: false // Ensure default is false
                    }))
                }));
            }
            catch (error) {

            }
        }).catch(error => {

        })
    }

    // getApplicantList(){
    //     getApplicantList({
    //         loanId:this.recordId,
    //         applicableStage : this.passedScreenName
    //     }).then(response=>{

    //         console.log('response---'+JSON.stringify(response));

    //         this.applicantList = response.map((applicant, index) => ({
    //             ...applicant,
    //             sequence: index + 1,
    //             isRemovable: applicant.name.startsWith('Applicant '),
    //             stages :this.subStageList,
    //             stages: this.subStageList.map(stage => ({
    //                 ...stage,
    //                 isSelected: false // 🔹 Ensure default is false
    //             }))
    //         }));
    //         console.log(' this.applicantList---'+ this.applicantList);
    //         this.nextSequence = this.applicantList.length + 1;

    //     }).catch(error=>{
    //         this.applicantList= [...response]
    //     })

    // }
    async handleAddNewApplicant() {
        console.log('loan stage ::'+ this.loanDetails.data.fields.StageName.value);
        this.isNewApplicant =true;
        console.log('111');
        // const newApplicant = {
        //     name: `Applicant ${this.nextSequence}`,
        //     sequence: this.nextSequence,
        //     isRemovable: true,
        //     stages: this.subStageList.map(stage => ({
        //         ...stage,

            
        //         isApplicantCmp: stage.name === 'PAN Details',
        //         isBasicDetails:false

        //         // isConsent : stage.name === "Consent"
        //     }))
        // };activeParentSectionName

        if(this.loanDetails.data.fields.StageName.value == 'PSV'){
            const result = await LightningConfirm.open({
                message: 'Add Applicant will move loan application stage to Sales Login, Are you sure you want to proceed?',
                theme: 'warning', 
                label: 'Confirmation'
            });

            if (result) {
                console.log('User confirmed',JSON.stringify(result) );            
                updateLoanApplicationStage({loanId : this.recordId})
                    .then(res =>{ 
                            this.isloading = true;
                            this.activeParentSectionName = '';
                            console.log('this.nextSequence=:'+this.nextSequence);
                            var currentApp = `Applicant ${this.nextSequence}`;
                            console.log('currentApp=:'+currentApp);
                            const newApplicant = {
                                name: `Applicant ${this.nextSequence}`,
                                sequence: this.nextSequence,
                                isRemovable: true,
                                // stages: this.subStageList.map(stage => ({
                                //     ...stage,

                                
                                //     isApplicantCmp: stage.name === 'PAN Details',
                                //     isBasicDetails:false

                                //     // isConsent : stage.name === "Consent"
                                // }))
                                
                                stages: this.subStageList
                            
                                    .filter(stage => (stage.name === 'PAN/Form 60 Details' )) 
                                    
                                    .map(stage => ({
                                        ...stage,
                                        isApplicantCmp: true,
                                        isBasicDetails: false
                                          
                                    }))
                                    
                            };
                            console.log('line no 1352', JSON.stringify(stages));
                            console.log(' this.applicantList 1092', this.applicantList);
                            this.applicantList = [...this.applicantList, newApplicant];
                            this.nextSequence++;
                            console.log(' this.applicantList 1095', this.applicantList);
                            console.log('  this.nextSequence 1096', this.nextSequence);
                            console.log('currentApp=:459+'+currentApp);
                            
                            this.applicantList.forEach(iter => {
                                console.log('iter.name=:'+iter.name);
                                if(iter.name == currentApp){
                                    console.log('inside name set');
                                    this.activeParentSectionName = currentApp;
                                }
                                console.log('iter.stages',iter.stages);
                                iter.stages.forEach(item => {
                                    console.log('item 84-', item);
                                    this.activeSectionName = 'PAN/Form 60 Details';
                                    this.activeSectionToBePassed = item;
                                    item.isApplicantCmp = true;
                                    item.isConsent = false;
                                    item.isDeDupeScreen = false;
                                    item.isBasicDetails = false;
                                    item.isPanValidation = false;
                                    item.isDocument = false;
                                    item.isBureau = false;
                                    item.isCKYCDetails = false;
                                    //HL-Ishi-23/09
                                    item.isCibil = false;
                                    item.isCrif = false;
                                    //HL-Ishi-23/09
                                    item.isApplicantAdditionalInformation = false;
                                    item.isApplicantAddressInformation = false;
                                    item.isPersonalInformation = false;
                                    item.isAddressInformation = false;
                                    item.isEmploymentInformation = false;
                                    item.isCurrentAddressInformation = false;
                                    item.isPermanentAddressInformation = false;
                                    item.isCurrentEmploymentInformation = false;
                                    item.isAnnualIncomeInformation = false;
                                    item.isEmploymentDetails = false;
                                    this.isloading = false;
                                })

                            })
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Success',
                                    message: 'Applicant Added Successfully.',
                                    variant: 'success',
                                }),
                            )

                            window.location.reload(true);
                            /*this[NavigationMixin.Navigate]({
                                    type: 'standard__recordPage',
                                    attributes: {
                                        recordId: this.recordId,
                                        objectApiName: 'Opportunity', 
                                        actionName: 'view'
                                    }
                                }, true);*/
                        })
                        .catch(error => {
                            this.isloading = false;
                            console.log(error);
                        })
            } else {
                console.log('User canceled');
            }
        }
        else{
            this.isloading = true;
            this.activeParentSectionName = '';
            console.log('this.nextSequence=:'+this.nextSequence);
            const seq = this.nextSequence;
            var currentApp = `Applicant ${this.nextSequence}`;
            console.log('currentApp=:'+currentApp);
            console.log('1165',this.processedStages)
            this.processedStages = [];
            console.log('1167',this.processedStages);
            const processedStages = [
                    {
                        name: 'C-KYC Details',
                        isCompleted: false,
                        sequence: '1',
                        showLine: false
                    },
                    {
                        name: 'PAN/Form 60 Details',
                        isCompleted: false,
                        sequence: '2',
                        showLine: true
                    },
                    {
                        name: 'Aadhar Details',
                        isCompleted: false,
                        sequence: '3',
                        showLine: true
                    },
                    {
                        name: "Applicant's Basic Information",
                        isCompleted: false,
                        sequence: '4',
                        showLine: true
                    },
                    {
                        name: 'Dedupe',
                        isCompleted: false,
                        sequence: '5',
                        showLine: true
                    }

                ];

                
                this.processedStages = processedStages;
                console.log('1183-->',this.processedStages);

                const firstStage = [
                {
                applicableFor: 'Both',
                name: 'C-KYC Details',
                sequence: '1',
                isCompleted: false,
                processedStages: this.processedStages,
                applicantId: null,
                isApplicantCmp: false,
                //AHL Kshitiz 26-09-2025
                isCKYCDetails: true,
                isAadharDetails: false,
                //AHL Kshitiz 26-09-2025
                isBasicDetails: false,
                isConsent: false,
                isDeDupeScreen: false,
                isPanValidation: false,
                isDocument: false,
                isBureau: false,
                //HL-Ishi-23/09
                isCibil :false,
                isCrif :false,
                //HL-Ishi-23/09
                isApplicantAdditionalInformation: false,
                isApplicantAddressInformation: false,
                isPersonalInformation: false,
                isAddressInformation: false,
                isEmploymentInformation: false,
                isCurrentAddressInformation: false,
                isPermanentAddressInformation: false,
                isCurrentEmploymentInformation: false,
                isAnnualIncomeInformation: false,
                isEmploymentDetails: false
            },
            {
                applicableFor: 'Both',
                name: 'PAN/Form 60 Details',
                sequence: '1',
                isCompleted: false,
                processedStages: this.processedStages,
                applicantId: null,
                isApplicantCmp: true,
                isBasicDetails: false,
                isConsent: false,
                isDeDupeScreen: false,
                isPanValidation: false,
                isDocument: false,
                isBureau: false,
                //AHL Kshitiz 26-09-2025
                isCKYCDetails: false,
                isAadharDetails: false,
                //AHL Kshitiz 26-09-2025
                //HL-Ishi-23/09
                isCibil :false,
                isCrif :false,
                //HL-Ishi-23/09
                isApplicantAdditionalInformation: false,
                isApplicantAddressInformation: false,
                isPersonalInformation: false,
                isAddressInformation: false,
                isEmploymentInformation: false,
                isCurrentAddressInformation: false,
                isPermanentAddressInformation: false,
                isCurrentEmploymentInformation: false,
                isAnnualIncomeInformation: false,
                isEmploymentDetails: false
            },
           /* {
                applicableFor: 'Individual',
                name: 'Aadhar Details',
                sequence: '1',
                isCompleted: false,
                
                processedStages: this.processedStages,
                applicantId: null,
                isApplicantCmp: false,
                //AHL Kshitiz 26-09-2025
                isCKYCDetails: false,
                isAadharDetails: true,
                //AHL Kshitiz 26-09-2025
                isBasicDetails: false,
                isConsent: false,
                isDeDupeScreen: false,
                isPanValidation: false,
                isDocument: false,
                isBureau: false,
                //HL-Ishi-23/09
                isCibil :false,
                isCrif :false,
                //HL-Ishi-23/09
                isApplicantAdditionalInformation: false,
                isApplicantAddressInformation: false,
                isPersonalInformation: false,
                isAddressInformation: false,
                isEmploymentInformation: false,
                isCurrentAddressInformation: false,
                isPermanentAddressInformation: false,
                isCurrentEmploymentInformation: false,
                isAnnualIncomeInformation: false,
                isEmploymentDetails: false
            }*/];

            /* const stagesForNewApplicant = this.subStageList
            .filter(stage => stage.name === 'PAN/Form 60 Details') // keep as you had
            .map(stage => ({
                ...stage,
                // default/reset stage flags for new applicant
                isApplicantCmp: true,
                isBasicDetails: false,
                isConsent: false,
                isDeDupeScreen: false,
                isPanValidation: false,
                isDocument: false,
                isBureau: false,
                isApplicantAdditionalInformation: false,
                isApplicantAddressInformation: false,
                isPersonalInformation: false,
                isAddressInformation: false,
                isEmploymentInformation: false,
                isCurrentAddressInformation: false,
                isPermanentAddressInformation: false,
                isCurrentEmploymentInformation: false,
                isAnnualIncomeInformation: false,
                isEmploymentDetails: false,
                processedStages: []
                // keep name, label etc from original stage
            })); */

            const newApplicant = {
                name: `Applicant ${this.nextSequence}`,
                sequence: this.nextSequence,
                isRemovable: true,
                stages: firstStage,
                processedStages: this.processedStages,
                activeStageName: 'C-KYC Details'
            };
            
        
            console.log(' this.applicantList 122', this.applicantList);
            this.applicantList = [...this.applicantList, newApplicant];
            this.nextSequence++;
            console.log(' this.applicantList 125', this.applicantList);
            console.log('  this.nextSequence 126', this.nextSequence);
            console.log('currentApp=:459+'+currentApp);
            await Promise.resolve();


            this.activeParentSectionName = currentApp;
            
            this.applicantList = this.applicantList.map(a => a.sequence === seq ? { ...a, activeStageName: 'C-KYC Details' } : a);
            console.log('this.applicantList after adding co-applicant:', JSON.stringify(this.applicantList));
            this.isloading = false;

            /*this.applicantList.forEach(iter => {
                console.log('iter.name=:'+iter.name);
                if(iter.name == currentApp){
                    console.log('inside name set');
                    this.activeParentSectionName = currentApp;
                    console.log('this.activeParentSectionName=:'+this.activeParentSectionName);
                }
                console.log('iter.stages',iter.stages);
                iter.stages.forEach(item => {
                    console.log('item 85-', item);
                    this.activeSectionName = 'PAN/Form 60 Details';
                    this.activeSectionToBePassed = item;
                    item.sequence = currentApp;
                    item.isApplicantCmp = false;
                    item.isConsent = false;
                    item.isDeDupeScreen = false;
                    item.isBasicDetails = false;
                    item.isPanValidation = false;
                    item.isDocument = false;
                    item.isBureau = false;
                    item.isApplicantAdditionalInformation = false;
                    item.isApplicantAddressInformation = false;
                    item.isPersonalInformation = false;
                    item.isAddressInformation = false;
                    item.isEmploymentInformation = false;
                    item.isCurrentAddressInformation = false;
                    item.isPermanentAddressInformation = false;
                    item.isCurrentEmploymentInformation = false;
                    item.isAnnualIncomeInformation = false;
                    item.isEmploymentDetails = false;
                    this.isloading = false;
                })

            }) */
            /*this.applicantList.forEach((applicant) => {
                    this.applicantAccordionState.set(applicant.sequence, applicant.sequence === currentApp);
                }); */
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Applicant Added Successfully.',
                    variant: 'success',
                }),
            )
            console.log('before scroll');
             this.scrollToBottom();
        }
    }
    getSubStageList() {
        console.log('this.passedScreenName=: 197' + this.passedScreenName)
        console.log('currentAppId =:630'+this.recordId);
        console.log('currentAppId =:631'+this.cuurentAppId);
        getSubStageList({
            loanId: this.recordId,
            applicableStage: this.passedScreenName,
            formName: this.formName,
            apDetId: this.cuurentAppId
        })
            .then(response => {
                console.log('currentAppId =:1161'+this.cuurentAppId);
                console.log('Substage response: 114', response);
                console.log('checkList',this.loginChecklist);
                console.log('other infor 957 ',this.otherInfo);
                this.subStageList = response;
                // if(this.cuurentAppId == null || this.cuurentAppId == undefined || this.currentAppId == ''){
                //     this.cuurentAppId = this.applicantList[0].applicantId;
                //     console.log('currentAppId =:350'+this.cuurentAppId);                    
                // }
                var currentApplicant = this.applicantList.find(applicant => applicant.applicantId == this.cuurentAppId);
                console.log('Full applicantList:', JSON.stringify(this.applicantList));

                console.log('currentApplicant =:635'+JSON.stringify(currentApplicant));
                console.log('isCurrentAppNonInd: '+currentApplicant.customerProfile);
                  /*  if (currentApplicant.customerProfile == 'SEP' || currentApplicant.customerProfile == 'SENP' ) {
                        console.log('inside isCurrentAppNonInd check');
                        this.subStageList.forEach(stage => {
                            console.log('SubStage name:', stage.name);
                            if (stage.name === 'Employment Details') {
                                console.log('Bureau insights found');
                                const index = this.subStageList.indexOf(stage);
                                this.subStageList.splice(index, 1);
                            }
                        });
                    }*/
                    if (currentApplicant.customerProfile === 'SEP' || currentApplicant.customerProfile === 'SENP') {
                        console.log('inside isCurrentAppNonInd check');
                        this.subStageList = this.subStageList.filter(stage => stage.name !== 'Employment Details');
                    }
                    console.log('final substage list: '+ JSON.stringify(this.subStageList));
                console.log('processedStages: 1158', this.processedStages);
                this.processedStages = this.subStageList.map((stage, index, array) => ({
                    ...stage,
                    showLine: index > 0
                }));
                console.log('processedStages: 1159', this.processedStages);

                if (currentApplicant.isForm60Uploaded === true) {
                    console.log('Removing PAN validation');
                    this.processedStages = this.processedStages.filter(stage => stage.name !== 'PAN validation');
                    console.log('line1718', JSON.stringify(this.processedStages));
                }
                this.isloading = false;

            })
            .catch(error => {
                this.isloading = false;
                console.log('Error getting sub stage list:', JSON.stringify(error));
            });
    }

    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            const style = document.createElement('style');
            style.innerText = `
             .highlights.slds-clearfix.slds-page-header.slds-page-header_record-home.fixed-position{
                    background: #0b367a;
                    border-radius: 24px 25px 0px 0px !important;
                    color: white;
                }

                .entityNameTitle.slds-line-height--reset{
                    color:white;
                }
                .actionsContainer .slds-button-group-list button {
                    background-color: #4CAF50;
                    border-color: #4CAF50;
                    color: white;
                    font-size: 15px;
                    font-weight: 600;
                    border-radius: 16px;
                                }

                                .actionsContainer .slds-button-group-list button:hover:not(:disabled){
                    background: var(--orange-hover);
                    transform: translateY(-1px);
                    box-shadow: 0 6px 18px 4CAF50(196, 26, 18, 0.45);
                }

                lightning-card .slds-card .slds-card__header{
                    padding: 0;
                    margin: 0;
                }
                lightning-card .slds-card__body{
                    margin: 0;
                }
                            .uploadFile .slds-file-selector__text.slds-medium-show {
                display: none;
            }
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
            }
            .uploadFile slds-form-element__label{
            display: none;
            }
            .uploadFile slds-form-element__control{
                margin-left:20%;
            }
            .info-button svg.slds-button__icon.slds-button__icon_left {
                margin: 0;
            }
            .uploaded-view svg.slds-button__icon {
            color: green;
            }
            .inputSize .slds-form-element__label{
                
            }
            .slds-form-element__label {
            color : white;
            }
            .slds-input_faux, .slds-input, .slds-input[disabled]{
                background-color: #16283f !important;
                color: white;
            }
                        
            .navClass .slds-progress-bar__value{
                background: skyblue;
            }
                .instruction-box-nav.slds-progress-bar__value{
                background: skyblue;
            }
            .container .slds-accordion__summary-action{
                background: linear-gradient(135deg, #001a5e 0%, #003087 55%, #004db3 100%);
                color: white !important;
                border-radius: 10px !important;
            }
            .slds-accordion__summary-heading{
            color : white;
            }
            .slds-accordion__list-item{
            border: none !important;
            }
            .button.save-button.slds-button.slds-button_brand.slds-float_left{
                background-color:#1467eb !important;
                border-color: #D3D3D3 !important;
                color: #ffffff !important;
            }
                .slds-dropdown-trigger_click .slds-dropdown, .slds-dropdown-trigger_click:hover .slds-dropdown, .slds-dropdown-trigger--click .slds-dropdown, .slds-dropdown-trigger--click:hover .slds-dropdown{
                background-color: #16283f !important;
                color : white !important;
            }
            .slds-listbox_vertical .slds-listbox__option:focus, .slds-listbox_vertical .slds-listbox__option.slds-has-focus, .slds-listbox--vertical .slds-listbox__option:focus, .slds-listbox--vertical .slds-listbox__option.slds-has-focus{
                background-color: #16283f !important;
                box-shadow : none !important;
                color : white !important;
            }
            .slds-button_neutral , .slds-button_icon-brand{
            color : #fff !important;
            }
            `;
            this.template.querySelector('.styleContainer').appendChild(style);
            this.spinnerClass = 'spinner-medium';
        }
    }
    handleRemoveApplicant(event) {
        const sequenceToRemove = parseInt(event.target.dataset.id, 10);
        //console.log('Removing applicant with sequence:', this.applicantSequence);
        this.applicantList = this.applicantList
            .filter(applicant => applicant.sequence !== sequenceToRemove)
            .map((applicant, index) => ({ ...applicant, sequence: index + 1 })); // Reassign sequence
        this.nextSequence = this.applicantList.length + 1;

        console.log('Updated applicantList:', JSON.stringify(this.applicantList));
        console.log('Next available sequence:', this.nextSequence);
        this.showConfBox = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Applicant Removed Successfully.',
                variant: 'success',
            }),
        )

    }
    handleAccordianChangeStage(event) {
        console.log("Accordion Clicked:1");
        console.log('event.target.dataset.id --> ' + event.detail.value);
        console.log('event.target.id --> ' + event.currentTarget.dataset.applicantid);

        this.currentStage = event.target.value;
        this.getApplicantList();
    }

    // handleAccordionClick(event){
    //     console.log("Accordion Clicked:",event);
    //     console.log("Accordion Clicked name:", event.target.name);
    //     console.log("Accordion Clicked:", event.currentTarget.dataset.applicantid);
    //     this.selectedApplicantId =event.currentTarget.dataset.applicantid; ;
    //     const selectedStage =event.target.name;
    //     this.selectedStageName =event.target.name;
    //     this.applicantList = this.applicantList.map(applicant => {
    //         console.log('(applicant.id === this.selectedApplicantId && stage.name === this.selectedStageName)',applicant.sequence );
    //         console.log('(applicant.id === this.selectedApplicantId && stage.name === this.selectedStageName)',this.selectedApplicantId );

    //         return {
    //             ...applicant,
    //             stages: applicant.stages.map(stage => ({

    //                 ...stage,
    //                 isSelected: (applicant.sequence=== this.selectedApplicantId && stage.name === this.selectedStageName)

    //             }))


    //         };

    //     });
    //     console.log(' this.applicantList---'+JSON.stringify(this.applicantList));
    //     switch(selectedStage){
    //         case "Applicant's Primary Information":
    //           this.currentStagePersonalDetails = true;
    //             break;
    //     }

    // }
    async handleParentAccordionClick(event) { //change by Kunal Bisht for SFHL-1420
        console.log('handleParentAccordionClick=:' + event.currentTarget.dataset.id);
        console.log('handleParentAccordionClick=:' + parseInt(event.currentTarget.dataset.id));
        const datasetId = event.currentTarget.dataset.id;
        const accordionName = event.currentTarget.name;
        console.log('Accordion Name:', accordionName);
        const applicant = this.applicantList.find(iter => iter.name === accordionName);
            this.cuurentAppId = applicant.applicantId;
            this.activeParentSectionName = accordionName;
            console.log('this.activeParentSectionName=:' + this.activeParentSectionName);
            console.log('this.cuurentAppId=:' + this.cuurentAppId);
            console.log('this.checkname', this.checkname);
            console.log('accordionName', accordionName);
            if(this.checkname == accordionName){
                this.checkname = '';
            }
            else{
                this.checkname = accordionName;
            }
            //changes by Kunal Bisht for SFHL-1420 - start
            if(applicant.isRemovable===false){
                
                try {
                    const loanApplicationStage =
                        await getLoanApplicationStageByApplicantId({
                            applicantId: applicant.applicantId
                        });
                    
                    if (
                        loanApplicationStage === 'Sales login' &&
                        accordionName.includes('Co Applicant') &&
                        !accordionName.includes('Primary Applicant')
                    ) {
                        this.showDeleteCoAppBtn = true;
                    } else {
                        this.showDeleteCoAppBtn = false;
                    }
                    
                } catch (error) {
                        console.error('Error fetching loan application stage', error);
                        this.showDeleteCoAppBtn = false;
                } 
            }
            //changes by Kunal Bisht for SFHL-1420 - end
            
        //     if (applicant) {
        //     const sequence = applicant.sequence;
        //     console.log('Applicant Sequence:', sequence);
        //     console.log('applicantAccordionState '+JSON.stringify(this.applicantAccordionState));
        //     // Check the map for the sequence
        //     if (this.applicantAccordionState.has(sequence)) {
        //         const isOpen = this.applicantAccordionState.get(sequence);
        //         console.log('Accordion State:', isOpen);
        //         if (isOpen) {
        //             if (checkname === applicant.name) {
        //                 checkname = '';
        //                 console.log('Checkname cleared');
        //             }
        //         }
        //     } else {
        //         console.log('Sequence not found in map');
        //     }
        // } else {
        //     console.log('Applicant not found');
        // }
        if (datasetId != undefined && datasetId != null) {
            this.getSubStageList();
            this.currentAppSeq = parseInt(datasetId);
            this.applicantList.forEach(iter => {
                iter.stages.forEach(item => {
                    console.log('item 86-', item);
                    this.activeSectionName = 'PAN/Form 60 Details';
                    this.activeSectionToBePassed = item;
                    item.isApplicantCmp = true;
                    item.isConsent = false;
                    item.isDeDupeScreen = false;
                    item.isBasicDetails = false;
                    item.isPanValidation = false;
                    item.isDocument = false;
                    item.isBureau = false;
                    item.isCKYCDetails = false;
                    //HL-Ishi-23/09
                    item.isCibil = false;
                    item.isCrif = false;
                    //HL-Ishi-23/09
                    item.isApplicantAdditionalInformation = false;
                    item.isApplicantAddressInformation = false;
                    item.isPersonalInformation = false;
                    item.isAddressInformation = false;
                    item.isEmploymentInformation = false;
                    item.isCurrentAddressInformation = false;
                    item.isPermanentAddressInformation = false;
                    item.isCurrentEmploymentInformation = false;
                    item.isAnnualIncomeInformation = false;
                    item.isEmploymentDetails = false;
                })

            })
        }
    }
    async handleOpenNextSeqScreen(event) {
        this.refreshData = false;
        console.log('event.detail.screenName= 834-------Applicant:' + event.detail.screenName);
        console.log('event.detail.applicantId= 835-------Applicant:' + event.detail.recordId);
        event.stopPropagation();
        this.getApplicantList();
        //if(event.detail.screenName == 'PAN validation'|| event.detail.screenName == 'Consent' || event.detail.screenName == 'Dedupe'){
            console.log('539');
            this.isloading = true;
             if(event.detail.recordId != undefined && event.detail.recordId != null && event.detail.recordId != ''){
                this.oppId = event.detail.recordId;
            }
            //     setTimeout( ()=>{
               
//      await this.getApplicantList();
//     this.isloading = false; 
//    // },1000);
       // }
        setTimeout(()=>{
            console.log('event.detail.screenName= 846:' + event.detail.screenName);
            this.applicantList.forEach(iter => {
                if (iter.sequence == this.currentAppSeq) {
                    iter.stages.forEach(item => {
                        if (item.name == event.detail.screenName) {
                            console.log('item 87-', item.name);
                            this.activeSectionName = event.detail.screenName;
                            this.activeSectionToBePassed = item;
                            // this.isloading = true;   
                            // setTimeout(()=>{
                            item.isApplicantCmp = false;
                            item.isConsent = false;
                            item.isDeDupeScreen = false;
                            item.isBasicDetails = false;
                            item.isDocument = false;
                            item.isBureau = false;
                            item.isCKYCDetails = false;
                            //HL-Ishi-23/09
                            item.isCibil = false;
                            item.isCrif = false;
                            //HL-Ishi-23/09
                            item.isApplicantAdditionalInformation = false;
                            item.isApplicantAddressInformation = false;
                            item.isPersonalInformation = false;
                            item.isAddressInformation = false;
                            item.isEmploymentInformation = false;
                            item.isCurrentAddressInformation = false;
                            item.isPermanentAddressInformation = false;
                            item.isCurrentEmploymentInformation = false;
                            item.isAnnualIncomeInformation = false;
                            item.isEmploymentDetails = false;
                             item.isAddressDetails = false;
                            if (event.detail.screenName == 'PAN/Form 60 Details') {
                                item.isApplicantCmp = true;
                            }
                            else if (event.detail.screenName == 'Consent') {
                                item.isConsent = true;
                            }
                            else if (event.detail.screenName == 'Dedupe') {
                                item.isDeDupeScreen = true;
                            }
                            else if (event.detail.screenName == 'Applicant\'s Basic Information') {
                                console.log(' this.activeSectionToBePassed = item;=:' + JSON.stringify(this.activeSectionToBePassed));
                                item.isBasicDetails = true;
                            }
                            else if (event.detail.screenName == 'Swap Applicants') {
                                item.isSwapApplicant = true;
                            }
                            else if (event.detail.screenName == 'Documents') {
                                item.isDocument = true;
                            }
                            else if (event.detail.screenName == 'Bureau insights') {
                                item.isBureau = true;
                            }else if(event.detail.screenName=='PAN validation'){
                                item.isPanValidation = true;
                            }
                            else if(event.detail.screenName=='Aadhar Details'){
                                this.isAadharDetails = true;
                                 this.isAddressDetails = false;
                                item.isApplicantCmp = false;
                                item.isBasicDetails = false;
                                 this.isCKYCDetails = false;
                            }
                             else if(event.detail.screenName=='Address Details'){
                                this.isAadharDetails = false;
                                this.isAddressDetails = true;
                                item.isAddressDetails = true;
                                item.isApplicantCmp = false;
                                item.isBasicDetails = false;
                                 this.isCKYCDetails = false;
                            }else if(event.detail.screenName=='C-KYC Details'){
                                this.isAadharDetails = false;
                                this.isAddressDetails = false;
                                item.isApplicantCmp = false;
                                item.isBasicDetails = false;
                                 this.isCKYCDetails = true;
                            }
                            else if(event.detail.screenName == 'Employment Details'){
                                item.isEmploymentDetails = true;
                                item.isBasicDetails = false;
                                //item.isPanValidation = true;
                            }
                            //HL-Ishi-23/09
                            else if( this.isHLUser && (this.labelValue=='Both'||this.labelValue=='Cibil') && event.detail.screenName =='Cibil'){
                                item.isCibil =true;
                                item.isBureau = false;
                            }
                            else if(this.isHLUser && (this.labelValue=='Both'||this.labelValue=='Crif') &&event.detail.screenName =='Crif'){
                                 item.isCrif =true;
                                item.isBureau = false;
                            }
                         //HL-Ishi-23/09
                            this.isloading = false;
                            console.log('Updated Applicant List:', JSON.stringify(this.applicantList));
                        // this.isloading = false;    
                        // },2000)
    
                        }
                    })
                }
            })
            this.refreshData = true;
        },1000);
        this.isloading = false;
       
       
    }
    handleAccordionClick(event) {
        try{
        event.stopPropagation();
        console.log('eventttt---', event);
      
        console.log('event.target.dataset.id=:123' + event.currentTarget.dataset.id);
        // console.log('event.target.dataset.id=:1' + event.target.dataset.id);
       

        // this.applicantList.forEach(item=>{
        //     if(item.)
        // })
        console.log('this.currentAppSeq=:' + this.currentAppSeq);
        this.applicantList.forEach(iter => {
            if (iter.sequence == this.currentAppSeq) {
                iter.stages.forEach(item => {
                    if (item.name == event.currentTarget.dataset.id) {
                        this.activeSectionName = event.currentTarget.dataset.id;
                        this.activeSectionToBePassed = item;
                        console.log('formitem=:' + JSON.stringify(this.activeSectionToBePassed));
                        // this.isloading = true;
                        // setTimeout(()=>{
                        console.log('iter.applicantId '+iter.applicantId);
                        // item.IsBasicCompleted = checkBasicDetailsCaptured(iter.applicantId);
                        item.isApplicantCmp = false;
                        this.isAadharDetails = false;
                        item.isConsent = false;
                        item.isDeDupeScreen = false;
                        item.isBasicDetails = false;
                        item.isPanValidation = false;
                        item.isDocument = false;
                        item.isBureau = false;
                        item.isCKYCDetails = false;
                        //HL-Ishi-23/09
                        item.isCibil =false;
                        item.isCrif =false;
                        //HL-Ishi-23/09
                        item.isApplicantAdditionalInformation = false;
                        item.isApplicantAddressInformation = false;
                        item.isPersonalInformation = false;
                        item.isAddressInformation = false;
                        item.isEmploymentInformation = false;
                        item.isCurrentAddressInformation = false;
                        item.isPermanentAddressInformation = false;
                        item.isCurrentEmploymentInformation = false;
                        item.isAnnualIncomeInformation = false;
                        item.isAadharDetails = false;
                        console.log('event.currentTarget.dataset.id>>',event.currentTarget.dataset.id);
                        if (event.currentTarget.dataset.id == 'PAN/Form 60 Details') {
                            console.log('PAN Details true on handle accordian click');
                            item.isApplicantCmp = true;
                            item.isEmploymentDetails = false;
                            console.log('item.isApplicantCmp=:' + item.isApplicantCmp);
                        }
                        else if (event.currentTarget.dataset.id == 'Consent') {
                            item.isEmploymentDetails = false;
                            item.isConsent = true;
                        }
                        else if (event.currentTarget.dataset.id == 'Dedupe') {
                            console.log('Dedupe true on handle accordian click');
                            item.isEmploymentDetails = false;
                            item.isDeDupeScreen = true;
                        }
                        else if (event.currentTarget.dataset.id == 'Applicant\'s Basic Information') {
                            console.log(' this.activeSectionToBePassed = item;=:' + JSON.stringify(this.activeSectionToBePassed));
                            item.isBasicDetails = true;
                            item.isEmploymentDetails = false;
                        }
                        else if (event.currentTarget.dataset.id == 'Swap Applicants') {
                            item.isEmploymentDetails = false;
                            item.isSwapApplicant = true;
                        }
                        else if (event.currentTarget.dataset.id == 'PAN validation' || event.currentTarget.dataset.id == 'PAN Validation') {
                            item.isPanValidation = true;
                            item.isEmploymentDetails = false;
                        }
                        else if (event.currentTarget.dataset.id == 'Bureau insights' || event.currentTarget.dataset.id == 'Bureau') {
                            item.isBureau = true;
                            item.isEmploymentDetails = false;
                        }
                        else if (event.currentTarget.dataset.id == 'Documents') {
                            console.log('384');
                            item.isDocument = true;
                            item.isEmploymentDetails = false;
                        }
                        else if (event.currentTarget.dataset.id == 'Applicant\'s Additional Information') {
                            item.isEmploymentDetails = false;
                            this.formName = 'Applicant Other Details';
                            item.isApplicantAdditionalInformation = true;
                        }
                        else if (event.currentTarget.dataset.id == 'Applicant\'s Address Information') {
                            item.isApplicantAddressInformation = true;
                            item.isEmploymentDetails = false;
                        }else if (event.currentTarget.dataset.id == 'Personal Information' && this.loginChecklist) {
                            // this.formName = 'Personal Details';
                            item.isPersonalInformation = true;
                            item.isEmploymentDetails = false;
                        }
                        else if (event.currentTarget.dataset.id == 'Personal Information') {
                            this.formName = 'Applicant Details';
                            item.isPersonalInformation = true;
                            item.isEmploymentDetails = false;
                        }
                        else if (event.currentTarget.dataset.id == 'Address Information') {
                            this.formName = 'Address Information';
                            this.passedScreenName = 'Address Information';
                            item.isEmploymentDetails = false;
                            this.getSubStageList();
                            console.log('at 478--');
                            item.isApplicantAddressInformation = true;
                        }
                        else if (event.currentTarget.dataset.id == 'Employment and Income Information') {
                            this.formName = 'Employment and Income Information';
                            this.passedScreenName = 'Employment and Income Information';
                            item.isEmploymentDetails = false;
                            this.getSubStageList();
                            
                            
                            item.isEmploymentInformation = true;
                        }
                        else if (event.currentTarget.dataset.id == 'Current Address') {
                            item.isEmploymentDetails = false;
                            this.formName = 'Address Information';
                            item.isCurrentAddressInformation = true;
                        }
                        else if (event.currentTarget.dataset.id == 'Permanent Address') {
                            item.isEmploymentDetails = false;
                            this.formName = 'Address Information';
                            item.isPermanentAddressInformation = true;
                        }
                        else if (event.currentTarget.dataset.id == 'Current employment information') {
                            item.isEmploymentDetails = false;
                            this.formName = 'Employment and Income Information';
                            item.isCurrentEmploymentInformation = true;
                            item.isEmploymentDetails = false;
                        }
                        else if (event.currentTarget.dataset.id == 'Annual income information') {
                            this.formName = 'Employment and Income Information';
                            item.isEmploymentDetails = false;
                            item.isAnnualIncomeInformation = true;
                            item.isEmploymentDetails = false;
                        }
                        else if (event.currentTarget.dataset.id == 'Aadhar Details') {
                            console.log('Aadhar details true on handle accordian click');
                            item.isApplicantCmp = false;
                            item.isAadharDetails = true;
                            item.isAadharDetails = true;
                            item.isBasicDetails = false;
                            this.isAadharDetails =true;
                            // this.isAddressDetails = false;
                            // this.isCKYCDetails = false;
                            item.isEmploymentDetails = false;
                        }
                         else if (event.currentTarget.dataset.id == 'Address Details') {
                            console.log('Aadhar details true on handle accordian click');
                            item.isApplicantCmp = false;
                            this.isAadharDetails = false;
                            item.isAddressDetails = true;
                            item.isBasicDetails = false;
                            this.isAddressDetails = true;
                            this.isCKYCDetails = false;
                            item.isEmploymentDetails = false;
                        }else if (event.currentTarget.dataset.id == 'C-KYC Details') {
                            console.log('Aadhar details true on handle accordian click');
                            item.isApplicantCmp = false;
                            this.isAadharDetails = false;
                            item.isCKYCDetails = true;
                            item.isBasicDetails = false;
                            this.isAddressDetails = false;
                            this.isCKYCDetails = true;
                            item.isEmploymentDetails = false;
                        }
                        else if (event.currentTarget.dataset.id == 'Employment Details'){
                            item.isEmploymentDetails = true;
                            item.isBasicDetails = false;
                        }
                        //HL-Ishi-23/09
                         else if (event.currentTarget.dataset.id == 'Cibil') {
                            item.isCibil = true;
                            item.isEmploymentDetails = false;
                        }
                        else if (event.currentTarget.dataset.id == 'Crif') {
                            item.isCrif = true;
                            item.isEmploymentDetails = false;
                        }
                        //HL-Ishi-23/09

                        console.log('Updated Applicant List:', JSON.stringify(this.applicantList));
                    //     this.isloading = false;    
                    // },2000)

                    }
                })
            }
        })
        // this.applicantList[0].stages.forEach(item=>{
        //     console.log('item.name=:'+item.name);
        //     if(item.name == event.target.dataset.id){
        //         this.activeSectionName = event.target.dataset.id;
        //         item.isApplicantCmp = false;
        //         item.isConsent = false;
        //         item.isDeDupeScreen = false;
        //         item.isBasicDetails = false;
        //         if(event.target.dataset.id == 'PAN Details'){
        //             item.isApplicantCmp = true;
        //         }
        //         else if(event.target.dataset.id == 'Consent'){
        //             item.isConsent = true;
        //         }
        //         else if(event.target.dataset.id == 'Dedupe'){
        //             item.isDeDupeScreen = true;
        //         }
        //         else if(event.target.dataset.id == 'Applicant\'s Basic Information'){
        //             item.isBasicDetails = true;
        //         }
        //     }
        // })
}
catch(error){
    console.error('Error in handleAccordionClick:', error);
}

    }
     handleCallNextAccordianMethod(event) {
        console.log('Inside handleSaveDeduplist', JSON.stringify(event.detail));
        console.log('Inside handleCallAddressDetailsMethod', event.detail.name);
        this.isloading = true;
        this.recordId = event.detail.value;
        this.cuurentAppId =event.detail.appDetId

        let updatedApplicantList = [...this.applicantList];
        console.log('updatedApplicantList 616',updatedApplicantList);
        console.log('event.detail.currentAppSeq 617',event.detail.currentAppSeq);
        updatedApplicantList.forEach(iter => {
            if (iter.sequence == event.detail.currentAppSeq) {
                console.log('iter.sequence ',iter.sequence );
                iter.stages = iter.stages.map(item => {
                    console.log('item.name ',item.name );
                    if (item.name === 'Address Details') {
                        console.log('item=:', JSON.stringify(item));
                        event.detail.section = 'PAN validation';
                        // Step 1: Remove component from DOM by setting false
                        item.isBasicDetails = false;

                    }
                    return item;
                });
            }
        });
        this.otherInfo = true;
        this.applicantList = updatedApplicantList;
        console.log('applicant list>',JSON.stringify(this.applicantList));
        if(event.detail.section === 'PAN validation') {
                // Check if "Employment Details" exists in applicantList
            const hasEmploymentDetails = this.applicantList.some(applicant =>
                applicant.stages && applicant.stages.some(stage => stage.name === 'Employment Details')
            );
            console.log('hasEmploymentDetails', hasEmploymentDetails);
            if(hasEmploymentDetails) {
                console.log('Overriding section from Consent → Employment Details');
                event.detail.section = 'Employment Details';
            }
        }       

         setTimeout(() => {
            this.applicantList.forEach(iter => {
               //if (iter.sequence == event.detail.currentAppSeq) {
                    console.log('this.applicantList 1124',iter.sequence );
                    console.log('this.applicantList 11248',event.detail.currentAppSeq );
                    iter.stages.forEach(item => {
                        if (item.name == 'Address Details' && event.detail.section == 'Address') {
                            this.activeSectionName = 'Address Details';
                            this.activeSectionToBePassed = item;
                            item.isApplicantCmp = false;
                            item.isConsent = false;
                            item.isDeDupeScreen = false;
                            item.isBasicDetails = false;
                            item.isSwapApplicant = false;
                            item.isDocument = false;
                            item.isBureau = false;
                            item.isCKYCDetails = false;
                            //HL-Ishi-23/09
                            item.isCibil = false;
                            item.isCrif = false;
                            //HL-Ishi-23/09
                            item.isEmploymentDetails = false;
                            item.isAddressDetails = true;
                             this.otherInfo = false
                             this.isloading = false;
                        }else if (item.name == 'Consent' && event.detail.section == 'Consent') {
                            this.activeSectionName = 'Consent';
                            this.activeSectionToBePassed = item;
                            item.isApplicantCmp = false;
                            item.isConsent = true;
                            item.isDeDupeScreen = false;
                            item.isBasicDetails = false;
                            item.isSwapApplicant = false;
                            item.isDocument = false;
                            item.isBureau = false;
                            item.isCKYCDetails = false;
                            //HL-Ishi-23/09
                             item.isCibil = false;
                            item.isCrif = false;
                            //HL-Ishi-23/09
                            item.isEmploymentDetails = false;
                            item.isAddressDetails = false;
                             this.otherInfo = false
                             this.isloading = false;
                        }
                        else if (event.detail.section == 'Employment Details') {
                            console.log('inside employment details if>');
                            console.log('this.applicantList 1885',JSON.stringify(item) );
                            this.activeSectionName = 'Employment Details';
                            if(item.name=='Employment Details'){    
                            this.activeSectionToBePassed = item;}
                            item.isApplicantCmp = false;
                            item.isConsent = false;
                            item.isDeDupeScreen = false;
                            item.isBasicDetails = false;
                            item.isSwapApplicant = false;
                            item.isDocument = false;
                            item.isBureau = false;
                            item.isCKYCDetails = false;
                            //HL-Ishi-23/09
                            item.isCibil = false;
                            item.isCrif = false;
                            //HL-Ishi-23/09
                            item.isEmploymentDetails = true;
                            item.isAddressDetails = false;
                             this.otherInfo = false
                             this.isloading = false;
                        }
                        else if (item.name == 'C-KYC Details' && event.detail.section == 'C-KYC Details') {
                            this.activeSectionName = 'C-KYC Details';
                            this.activeSectionToBePassed = item;
                            item.isApplicantCmp = false;
                            item.isConsent = false;
                            item.isDeDupeScreen = false;
                            item.isBasicDetails = false;
                            item.isSwapApplicant = false;
                            item.isDocument = false;
                            item.isBureau = false;
                            item.isCKYCDetails = false;
                             //HL-Ishi-23/09
                             item.isCibil = false;
                            item.isCrif = false;
                            //HL-Ishi-23/09
                            item.isEmploymentDetails = false;
                            item.isAddressDetails = false;
                            item.isCKYCDetails = true;
                             this.otherInfo = false
                             this.isloading = false;
                        }
                        else if (item.name == 'PAN validation' && event.detail.section == 'PAN validation') {
                            this.activeSectionName = 'PAN validation';
                            this.activeSectionToBePassed = item;
                            item.isApplicantCmp = false;
                            item.isConsent = false;
                            item.isDeDupeScreen = false;
                            item.isBasicDetails = false;
                            item.isSwapApplicant = false;
                            item.isDocument = false;
                            item.isBureau = false;
                            item.isEmploymentDetails = false;
                            item.isPanValidation = true;
                            item.isAddressDetails = false;
                           item.isCKYCDetails = false;
                             this.otherInfo = false
                             this.isloading = false;
                        }
                    })
                //}
            })
            console.log('this.applicantList 1156s',event.detail.currentAppSeq );
            this.isloading = false;
        }, 500)

    }
    handleCallApplicantMethod(event) {
        console.log('Inside handleSaveDeduplist', JSON.stringify(event.detail));
        console.log('Inside handleCallApplicantMethod', event.detail.name);
        this.isloading = true;
        this.recordId = event.detail.value;
        this.cuurentAppId =event.detail.appDetId
        console.log('recordId60',this.cuurentAppId);
        
        // this.passedScreenName = event.detail.name;
        // console.log('Inside handleSaveDeduplist')
        // this.isDedupeEvent = true; // Set flag to true

        // this.dedupeList = event.detail.dedupList;
        // console.log('Inside handleSaveDeduplist',JSON.stringify( this.dedupeList ))
        // this.getApplicantList();

        let updatedApplicantList = [...this.applicantList];
        console.log('updatedApplicantList 616',updatedApplicantList);
        console.log('event.detail.currentAppSeq 617',event.detail.currentAppSeq);
        updatedApplicantList.forEach(iter => {
            if (iter.sequence == event.detail.currentAppSeq) {
                console.log('iter.sequence ',iter.sequence );
                iter.stages = iter.stages.map(item => {
                    console.log('item.name ',item.name );
                    if (item.name === 'Applicant\'s Basic Information') {
                        console.log('item=:', JSON.stringify(item));

                        // Step 1: Remove component from DOM by setting false
                        item.isBasicDetails = false;

                    }
                    return item;
                });
            }
        });
        this.otherInfo = true;
        this.applicantList = updatedApplicantList;
        console.log('this.applicantList 635' + JSON.stringify(this.applicantList));
        // this.getCurrentApplicantList();
        console.log('this.currentAppSeq=:' + event.detail.currentAppSeq);
       // this.getApplicantList();
        setTimeout(() => {
            console.log('Updated Applicant List:2426', JSON.stringify(this.applicantList));
        }, 500)
        setTimeout(() => {
            this.applicantList.forEach(iter => {
                console.log('line no 2428',JSON.stringify(iter));   
                if (iter.sequence == event.detail.currentAppSeq) {
                    console.log('this.applicantList 1124',iter.sequence );
                    console.log('this.applicantList 11248',event.detail.currentAppSeq );
                    iter.stages.forEach(item => {
                        if (item.name == 'Applicant\'s Basic Information') {
                            console.log('this.applicantList 1130',event.detail.currentAppSeq );
                            this.activeSectionName = 'Applicant\'s Basic Information';
                            this.activeSectionToBePassed = item;
                            item.isApplicantCmp = false;
                            item.isConsent = false;
                            item.isDeDupeScreen = false;
                            item.isBasicDetails = true;
                            item.isSwapApplicant = false;
                            item.isDocument = false;
                            item.isBureau = false;
                            item.isCKYCDetails = false;
                            //HL-Ishi-23/09
                             item.isCibil = false;
                            item.isCrif = false;
                            //HL-Ishi-23/09
                            item.isEmploymentDetails = true;
                             this.otherInfo = false
                             this.isloading = false;
                        }
                    })
                }
            })
            console.log('this.applicantList 1156s',event.detail.currentAppSeq );
            this.isloading = false;
        }, 500)

        // this.applicantList[0].stages.forEach(item=>{
        //     if(item.name == 'Dedupe'){
        //         this.activeSectionName = 'Dedupe';
        //         item.isApplicantCmp = false;
        //         item.isConsent = false;
        //         item.isDeDupeScreen = true;
        //         item.isBasicDetails = false;
        //     }
        // })


    }
     handleCallAadharDetailsMethod(event) {
        console.log('Inside handleAadharDetails Method of Applicant Information Component', event.detail.name);
        this.isloading = true;
        this.recordId = event.detail.value;
        this.cuurentAppId =event.detail.appDetId;
        this.currentAppSeq= event.detail.currentAppSeq;
        
        
        let updatedApplicantList = [...this.applicantList];
      

        console.log('updatedApplicantList 616',updatedApplicantList);
        console.log('event.detail.currentAppSeq 617',event.detail.currentAppSeq);
        updatedApplicantList.forEach(iter => {
            if (iter.sequence == this.currentAppSeq) {
                console.log('iter.sequence ',iter.sequence );
                iter.stages = iter.stages.map(item => {
                    console.log('item.name ',item.name );
                    if (item.name === 'Aadhar Details') {
                        console.log('item=:', JSON.stringify(item));

                        // Step 1: Remove component from DOM by setting false
                        item.isAadharDetails = false;

                    }
                    return item;
                });
            }
        });
        //this.otherInfo = true;
        this.applicantList = updatedApplicantList;
        console.log('this.applicantList 635' + JSON.stringify(this.applicantList));
        // this.getCurrentApplicantList();
        console.log('this.currentAppSeq=:' + this.currentAppSeq);
       // this.getApplicantList();
        setTimeout(() => {
            console.log('Updated Applicant List:2509', JSON.stringify(this.applicantList));
        }, 5000)
        setTimeout(() => {
            this.applicantList.forEach(iter => {
                if (iter.sequence == this.currentAppSeq) {
                    console.log('this.applicantList 1124',iter.sequence );
                    console.log('this.applicantList 11248',this.currentAppSeq );
                    iter.stages.forEach(item => {
                        if (item.name == 'Aadhar Details') {
                            console.log('this.applicantList 1130',this.currentAppSeq );
                            this.activeSectionName = 'Aadhar Details';
                            this.activeSectionToBePassed = item;
                            item.isApplicantCmp = false;
                            item.isConsent = false;
                            item.isDeDupeScreen = false;
                            item.isBasicDetails = false;
                            item.isSwapApplicant = false;
                            item.isDocument = false;
                            item.isBureau = false;
                            item.isCKYCDetails = false;
                            //HL-Ishi-23/09
                             item.isCibil = false;
                            item.isCrif = false;
                            //HL-Ishi-23/09
                            item.isAadharDetails = true;
                            item.isEmploymentDetails = false;
                             this.otherInfo = false
                             this.isloading = false;
                        }
                    })
                }
            })
            console.log('this.applicantList 1156s',event.detail.currentAppSeq );
            this.isloading = false;
        }, 500)
  console.log('line no 2539',JSON.stringify(this.applicantList));
        // this.applicantList[0].stages.forEach(item=>{
        //     if(item.name == 'Dedupe'){
        //         this.activeSectionName = 'Dedupe';
        //         item.isApplicantCmp = false;
        //         item.isConsent = false;
        //         item.isDeDupeScreen = true;
        //         item.isBasicDetails = false;
        //     }
        // })


    }
    handleOpenPrimaryScreen(event) {
        this.passedScreenName = event.detail.name;
        this.showPrimaryDetails = true;
        this.applicantList.forEach(iter => {
            if (iter.sequence == event.detail.currentAppSeq) {
                iter.stages.forEach(item => {
                    if (item.name == 'PAN/Form 60 Details') {
                        console.log('item=:' + JSON.stringify(item));
                        this.activeSectionToBePassed = item;
                        this.activeSectionName = 'PAN/Form 60 Details';
                        item.isApplicantCmp = true;
                        item.isConsent = false;
                        item.isDeDupeScreen = false;
                        item.isSwapApplicant = false;
                        item.isDocument = false;
                        item.isBureau = false;
                        item.isCKYCDetails = false;
                        //HL-Ishi-23/09
                        item.isCibil = false;
                        item.isCrif = false;
                        //HL-Ishi-23/09
                        item.isApplicantAdditionalInformation = false;
                        item.isApplicantAddressInformation = false;
                        item.isPersonalInformation = false;
                        item.isAddressInformation = false;
                        item.isEmploymentInformation = false;
                        item.isCurrentAddressInformation = false;
                        item.isPermanentAddressInformation = false;
                        item.isCurrentEmploymentInformation = false;
                        item.isAnnualIncomeInformation = false;
                        item.isEmploymentDetails = false;
                        // setTimeout(()=>{
                        item.isBasicDetails = false;
                        this.isAadharDetails = false;
                        this.isAddressDetails = false;
                         this.isCKYCDetails = false;
                        // },200)
                    }
                    if (item.name == 'Aadhar Details') {
                        console.log('item=:' + JSON.stringify(item));
                        this.activeSectionToBePassed = item;
                        this.activeSectionName = 'Aadhar Details';
                        item.isApplicantCmp = false;
                        item.isConsent = false;
                        item.isDeDupeScreen = false;
                        item.isSwapApplicant = false;
                        item.isDocument = false;
                        item.isBureau = false;
                        item.isCKYCDetails = false;
                        //HL-Ishi-23/09
                        item.isCibil = false;
                        item.isCrif = false;
                        //HL-Ishi-23/09
                        item.isApplicantAdditionalInformation = false;
                        item.isApplicantAddressInformation = false;
                        item.isPersonalInformation = false;
                        item.isAddressInformation = false;
                        item.isEmploymentInformation = false;
                        item.isCurrentAddressInformation = false;
                        item.isPermanentAddressInformation = false;
                        item.isCurrentEmploymentInformation = false;
                        item.isAnnualIncomeInformation = false;
                        // setTimeout(()=>{
                        item.isBasicDetails = false;
                        this.isAadharDetails = true;
                         this.isCKYCDetails = false;
                          this.isAddressDetails = false;
                        // },200)
                    }
                })
            }
        })
    }
    handleOpenCibilCmp(event){
        // let updatedApplicantList = [...this.applicantList];
        //this.getApplicantList();
        // updatedApplicantList.forEach(iter => {
        //     if (iter.sequence == event.detail.currentAppSeq) {
        //         iter.stages = iter.stages.map(item => {
        //             if (item.name === 'Applicant\'s Basic Information') {
        //                 console.log('item=:', JSON.stringify(item));

        //                 // Step 1: Remove component from DOM by setting false
        //                 item.isBasicDetails = false;
        //             }
        //             return item;
        //         });
        //     }
        // });

        // this.applicantList = updatedApplicantList;
        console.log('1182 Applicant',event.detail.name);
      
        // if(event.detail.name == 'Cibil Eligibility'){
        //     setTimeout(()=>{
        //         this.isloading = true; 
        //         this.getApplicantList();
        //     this.isloading = false; 
        //     },100);
        // }
        
            console.log('event.detail.screenName= 846:' + event.detail.name);
            console.log('event.detail.screenName= 846:' +this.currentAppSeq);
            this.applicantList.forEach(iter => {
                if (iter.sequence == this.currentAppSeq) {
                    console.log('event.detail.screenName= 1196:' +this.currentAppSeq);
                    iter.stages.forEach(item => {
                        console.log('event.detail.screenName= 1198:' +event.detail.name);
                        console.log('event.detail.screenName--1199 ', event.detail.screenName);
                        
                        console.log('item.name-----1199 ', item.name);
                        //HL-Ishi-10-10
                        if ((item.name == 'Bureau insights') || ((this.isHLUser && (item.name == 'Cibil' || item.name == 'Crif'))) && event.detail.name == 'Cibil Eligibility') {
                        //HL-Ishi-10-10
                            console.log('event.detail.screenName= 1200:' +item.name);
                            this.activeSectionName = item.name;//'Bureau insights';
                            //this.activeSectionToBePassed = item;
                            // this.isloading = true;   
                            // setTimeout(()=>{
                            item.isApplicantCmp = false;
                            console.log('event.detail.screenName= 1206:' +item.name);
                            item.isConsent = false;
                            item.isDeDupeScreen = false;
                            console.log('event.detail.screenName= 1209:' +item.name);
                            item.isBasicDetails = false;
                            item.isDocument = false;
                            console.log('event.detail.screenName= 1212:' +item.name);
                            item.isBureau = false;
                            item.isCibil =false;
                            item.isCrif=false;
                            item.isCKYCDetails = false;
                           
                            console.log('Updated Applicant List: 1220',event.detail.name);
                            // if (event.detail.name == 'Cibil Eligibility') {
                                console.log('Updated Applicant List:',event.detail.name);
                                if(item.name=='Bureau insights'){
                                     setTimeout(()=>{
                                    item.isBureau = true;
                                    },200);
                                }
                                else if(item.name=='Cibil'){
                                     console.log('Updated Applicant List: 2740',event.detail.name);
                                    item.isCibil = true;
                                }
                                else if(item.name=='Crif'){
                                     setTimeout(()=>{
                                    item.isCrif = true;
                                    },200);
                                }
                               
                            // }
                            
                            console.log('Updated Applicant List:', JSON.stringify(this.applicantList));
                        // this.isloading = false;    
                        // },2000)
    
                        }
                    })
                }
            })
      
       

        // setTimeout(() => {
        //     let newApplicantList = [...this.applicantList];
        //     newApplicantList.forEach(iter => {
        //         if (iter.sequence == event.detail.currentAppSeq) {
        //             iter.stages = iter.stages.map(item => {
        //                 if (item.name === 'Bureau insights') {

        //                     iter.isBureau = false; // Now add it back
        //                 }
        //                 this.activeSectionToBePassed = item;
        //                 this.activeSectionName = 'Bureau insights';
        //                 item.isApplicantCmp = false;
        //                 item.isConsent = false;
        //                 item.isSwapApplicant = false;
        //                 item.isDocument = false;
        //                 item.isBureau = true;
        //                 item.isApplicantAdditionalInformation = false;
        //                 item.isApplicantAddressInformation = false;
        //                 item.isPersonalInformation = false;
        //                 item.isAddressInformation = false;
        //                 item.isEmploymentInformation = false;
        //                 item.isCurrentAddressInformation = false;
        //                 item.isPermanentAddressInformation = false;
        //                 item.isCurrentEmploymentInformation = false;
        //                 item.isAnnualIncomeInformation = false;
        //                 // setTimeout(()=>{
        //                 item.isDeDupeScreen = false;
        //                 return item;
        //             });
        //         }
        //     });
            
        //     this.applicantList = newApplicantList;
        // }, 10);
        this.getSubStageList();
    }
    handleBasicDetailsScreen(event) {
        let updatedApplicantList = [...this.applicantList];
        //this.getApplicantList();
        updatedApplicantList.forEach(iter => {
            if (iter.sequence == event.detail.currentAppSeq) {
                iter.stages = iter.stages.map(item => {
                    if (item.name === 'Applicant\'s Basic Information') {
                        console.log('item=:', JSON.stringify(item));

                        // Step 1: Remove component from DOM by setting false
                        item.isBasicDetails = false;
                    }
                    return item;
                });
            }
        });

        this.applicantList = updatedApplicantList;

        setTimeout(() => {
            let newApplicantList = [...this.applicantList];
            newApplicantList.forEach(iter => {
                if (iter.sequence == event.detail.currentAppSeq) {
                    iter.stages = iter.stages.map(item => {
                        if (item.name === 'Applicant\'s Basic Information') {

                            iter.isBasicDetails = true; // Now add it back
                        }
                        this.activeSectionToBePassed = item;
                        this.activeSectionName = 'Applicant\'s Basic Information';
                        item.isApplicantCmp = false;
                        item.isConsent = false;
                        item.isSwapApplicant = false;
                        item.isDocument = false;
                        item.isBureau = false;
                        item.isCKYCDetails = false;
                        //HL-Ishi-23/09
                        item.isCibil = false;
                        item.isCrif = false;
                        //HL-Ishi-23/09
                        item.isApplicantAdditionalInformation = false;
                        item.isApplicantAddressInformation = false;
                        item.isPersonalInformation = false;
                        item.isAddressInformation = false;
                        item.isEmploymentInformation = false;
                        item.isCurrentAddressInformation = false;
                        item.isPermanentAddressInformation = false;
                        item.isCurrentEmploymentInformation = false;
                        item.isAnnualIncomeInformation = false;
                        item.isEmploymentDetails = true;
                        // setTimeout(()=>{
                        item.isDeDupeScreen = false;
                        return item;
                    });
                }
            });
            this.getApplicantList();
            this.applicantList = newApplicantList;
        }, 10); // Short de
        // this.applicantList[0].stages.forEach(item=>{
        //     if(item.name == 'Applicant\'s Basic Information'){
        //         this.activeSectionName = 'Applicant\'s Basic Information';
        //         item.isApplicantCmp = false;
        //         item.isConsent = false;
        //         item.isDeDupeScreen = false;
        //         item.isBasicDetails = true;
        //     }
        // })
        setTimeout(() => {
            console.log('Updated Applicant List:', JSON.stringify(this.applicantList));
        }, 100)
        // if(this.showBasicDetails ==true){
        //     this.getApplicantList();
        // }
        console.log('Inside handleBasicDetailsScreen camback');
    }


    handleCallDeDupePopUp(event) {
        // console.log(' this.applicantList 415', JSON.stringify(this.applicantList));
        // this.openInPopUp = false;
        // this.otherInfo = true;
        // this.custId = event.detail.custId;
        // console.log('Inside handleBasicDetailsScreen', JSON.stringify(event.detail));
        // this.passedScreenName = event.detail.name;
        // //this.showBasicDetails = true;
        // console.log('this.currentAppSeq=:' + event.detail.currentAppSeq);
       
        // this.recordId = event.detail.value;
        // this.cuurentAppId =event.detail.appDetId
        // let updatedApplicantList = [...this.applicantList];

        // updatedApplicantList.forEach(iter => {
        //     if (iter.sequence == event.detail.currentAppSeq) {
        //         iter.stages = iter.stages.map(item => {
        //             if (item.name === 'Dedupe') {
        //                 console.log('item=:', JSON.stringify(item));

        //                 // Step 1: Remove component from DOM by setting false
        //                 item.isDeDupeScreen = false;
        //             }
        //             return item;
        //         });
        //     }
        // });

        // this.applicantList = updatedApplicantList;

        // // Step 2: Add a small delay before setting it back to true
        // setTimeout(() => {
        //     let newApplicantList = [...this.applicantList];
        //     newApplicantList.forEach(iter => {
        //         console.log('iter.sequence' + event.detail.currentAppSeq);
        //         console.log('iter.sequence 1387-----',iter.sequence);
        //         if (iter.sequence == event.detail.currentAppSeq) {
        //             iter.stages = iter.stages.map(item => {
        //                 console.log(' item.isDeDupeScreen  1499-----', item.name );
        //                 if (item.name == 'Dedupe') {
        //                     item.isDeDupeScreen = true; // Now add it back
        //                     console.log(' item.isDeDupeScreen  1501-----', item.isDeDupeScreen );
        //                 }
        //                 this.activeSectionToBePassed = item;
        //                 this.activeSectionName = 'Dedupe';
        //                 console.log(' item.isDeDupeScreen  1505-----', item.isDeDupeScreen );
        //                 item.isApplicantCmp = false;
        //                 item.isConsent = false;
        //                 item.isSwapApplicant = false;
        //                 item.isDocument = false;
        //                 item.isBureau = false;
        //                 item.isApplicantAdditionalInformation = false;
        //                 item.isApplicantAddressInformation = false;
        //                 console.log(' item.isDeDupeScreen  1512-----', item.isDeDupeScreen );
        //                 this.otherInfo = false
        //                 item.isDeDupeScreen = true; 
        //                 console.log(' item.isDeDupeScreen -----', item.isDeDupeScreen );
        //                 // setTimeout(()=>{
        //                 item.isBasicDetails = false;
        //                 // return item;
        //             });
        //         }
        //     });
        //     this.applicantList = newApplicantList;
        //     console.log(' 1504444-----', this.applicantList );
        //     //this.openInPopUp = true;
        // }, 100); // Short delay to allow DOM update

        console.log('Inside handleSaveDeduplist', JSON.stringify(event.detail));
        console.log('Inside handleCallApplicantMethod', event.detail.name);
        this.isloading = true;
        this.recordId = event.detail.value;
        this.cuurentAppId =event.detail.appDetId
        
        
        // this.passedScreenName = event.detail.name;
        // console.log('Inside handleSaveDeduplist')
        // this.isDedupeEvent = true; // Set flag to true

        // this.dedupeList = event.detail.dedupList;
        // console.log('Inside handleSaveDeduplist',JSON.stringify( this.dedupeList ))
        // this.getApplicantList();

        let updatedApplicantList = [...this.applicantList];

        console.log('updatedApplicantList 616',updatedApplicantList);
        console.log('event.detail.currentAppSeq 617',event.detail.currentAppSeq);
        updatedApplicantList.forEach(iter => {
            if (iter.sequence == event.detail.currentAppSeq) {
                iter.applicantId = event.detail.appDetId;
                console.log('iter.sequence ',iter.sequence );
                iter.stages = iter.stages.map(item => {
                    console.log('item.name ',item.name );
                    if (item.name === 'Dedupe') {
                        console.log('item=:', JSON.stringify(item));

                        // Step 1: Remove component from DOM by setting false
                        item.isDeDupeScreen = false;

                    }
                    return item;
                });
            }
        });
        this.otherInfo = true;
        this.applicantList = updatedApplicantList;
        console.log('this.applicantList 635' + JSON.stringify(this.applicantList));
        // this.getCurrentApplicantList();
        console.log('this.currentAppSeq=:' + event.detail.currentAppSeq);
       // this.getApplicantList();
        setTimeout(() => {
            console.log('Updated Applicant List:2927', JSON.stringify(this.applicantList));
        }, 500)
        setTimeout(() => {
            this.applicantList.forEach(iter => {
                if (iter.sequence == event.detail.currentAppSeq) {
                    iter.applicantId = event.detail.appDetId;
                    console.log('this.applicantList 1124',iter.sequence );
                    console.log('this.applicantList 11248',event.detail.currentAppSeq );
                    iter.stages.forEach(item => {
                        if (item.name == 'Dedupe') {
                            console.log('this.applicantList 1130',event.detail.currentAppSeq );
                            this.activeSectionName = 'Dedupe';
                            this.activeSectionToBePassed = item;
                            item.isApplicantCmp = false;
                            item.isConsent = false;
                            item.isDeDupeScreen = true;
                            item.isBasicDetails = false;
                            item.isSwapApplicant = false;
                            item.isDocument = false;
                            item.isBureau = false;
                            item.isCKYCDetails = false;
                            //HL-Ishi-23/09
                             item.isCibil = false;
                            item.isCrif = false;
                            //HL-Ishi-23/09
                             item.isBasicDetails = false;
                             this.otherInfo = false
                             this.isloading = false;
                             return item;
                        }
                        else{
                            item.isDeDupeScreen = false;
                        }
                        
                    })
                }
            })
            console.log('this.applicantList 1156s',event.detail.currentAppSeq );
            this.isloading = false;
        }, 1000)

        // this.applicantList[0].stages.forEach(item=>{
        //     if(item.name == 'Dedupe'){
        //         this.activeSectionName = 'Dedupe';
        //         item.isApplicantCmp = false;
        //         item.isConsent = false;
        //         item.isDeDupeScreen = true;
        //         item.isBasicDetails = false;
        //     }
        // })
    }


    setDefaultDedupeAccordion() {
        this.isDedupeEvent = false; // Reset flag

        // Find first applicant's `De Dupe` stage
        for (let applicant of this.applicantList) {
            const dedupeStage = applicant.stages.find(stage => stage.name === 'Dedupe');
            if (dedupeStage) {
                this.activeSectionName = dedupeStage.name; // Open 'De Dupe' accordion
                console.log('this.activeSectionName ---', this.activeSectionName)
                break;
            }
        }
    }
    setDefaultBasicDetailsAccordian() {
        this.showBasicDetails = false; // Reset flag

        console.log('Inside default basic details---');
        for (let applicant of this.applicantList) {
            console.log('applicant', JSON.stringify(applicant.stages))
            const basicStage = applicant.stages.find(stage => stage.name === "Applicant's Basic Information");
            console.log('this.activeSectionName ---', JSON.stringify(basicStage));
            if (basicStage) {
                console.log('this.activeSectionName -310--', JSON.stringify(basicStage));
                this.activeSectionName = basicStage.name; // Open 'De Dupe' accordion
                console.log('this.activeSectionName -312--', basicStage.name);
                this.activeSectionToBePassed = basicStage;
                console.log('this.activeSectionName -314--', JSON.stringify(this.activeSectionToBePassed))
                break;
            }
        }
    }
    trackingScreenName;
    handleSaveApplicantId(event) {
        console.log('this.currentAppSeq=: 1483', event.detail.name);
        this.isloading = true;
        
       this.recordId = event.detail.value;
        this.cuurentAppId = event.detail.apDetId;
        this.passedScreenName = 'Applicant Information';//event.detail.name;
        this.trackingScreenName = event.detail.name;
        this.currentAppSeq= event.detail.currentAppSeq;
         this.appIdChild = this.cuurentAppId;
        
         
        // this.getSubStageList();
        setTimeout(()=>{
            this.getApplicantList();
        },200)
        
        // try{
        //     setTimeout(()=>{
        //         //     this.isloading = true;
        //         console.log('event.detail.name=:'+event.detail.name);
        //         if(event.detail.name == 'Applicant\'s Basic Information'){
        //             let updatedApplicantList = [...this.applicantList];
        //             console.log('updatedApplicantList 1500',updatedApplicantList);
        //             console.log('event.detail.currentAppSeq 1501',event.detail.currentAppSeq);
        //             updatedApplicantList.forEach(iter => {
        //                 if (iter.sequence == event.detail.currentAppSeq) {
        //                     console.log('iter.sequence ',iter.sequence );
        //                     iter.stages = iter.stages.map(item => {
        //                         console.log('item.name ',item.name );
        //                         if (item.name === 'Applicant\'s Basic Information') {
        //                             console.log('item=:', JSON.stringify(item));
            
        //                             // Step 1: Remove component from DOM by setting false
        //                             item.isBasicDetails = false;
            
        //                         }
        //                         // return item;
        //                     });
        //                 }
        //             });
        //             this.otherInfo = true;
        //             this.applicantList = updatedApplicantList;
        //             console.log('this.applicantList 635' + JSON.stringify(this.applicantList));
        //             // this.getCurrentApplicantList();
        //             console.log('this.currentAppSeq=:' + event.detail.currentAppSeq);
        //             setTimeout(() => {
        //                 console.log('Updated Applicant List:', JSON.stringify(this.applicantList));
        //             }, 500)
        //             setTimeout(() => {
        //                 this.applicantList.forEach(iter => {
        //                     if (iter.sequence == event.detail.currentAppSeq) {
        //                         iter.stages.forEach(item => {
        //                             if (item.name == 'Applicant\'s Basic Information') {
        //                                 this.activeSectionName = 'Applicant\'s Basic Information';
        //                                 this.activeSectionToBePassed = item;
        //                                 item.isApplicantCmp = false;
        //                                 item.isConsent = false;
        //                                 item.isDeDupeScreen = false;
        //                                 item.isBasicDetails = true;
        //                                 item.isSwapApplicant = false;
        //                                 item.isDocument = false;
        //                                 item.isBureau = false;
        //                                 item.isApplicantAdditionalInformation = false;
        //                                 item.isApplicantAddressInformation = false;
        //                                 item.isPersonalInformation = false;
        //                                 item.isAddressInformation = false;
        //                                 item.isEmploymentInformation = false;
        //                                 item.isCurrentAddressInformation = false;
        //                                 item.isPermanentAddressInformation = false;
        //                                 item.isCurrentEmploymentInformation = false;
        //                                 item.isAnnualIncomeInformation = false;
        //                                 this.otherInfo = false
        //                                 this.isloading = false;
        //                             }
        //                         })
        //                     }
        //                 })
        //             }, 500)
        //             this.isloading = false;
        //         }
        //         else if(event.detail.name == 'Dedupe'){
        //             console.log('this.currentAppSeq=: 1552' + event.detail.currentAppSeq);
        
        //             this.recordId = event.detail.value;
        //             this.cuurentAppId =event.detail.appDetId
        //             let updatedApplicantList = [...this.applicantList];
            
        //             updatedApplicantList.forEach(iter => {
        //                 if (iter.sequence == event.detail.currentAppSeq) {
        //                     iter.stages = iter.stages.map(item => {
        //                         if (item.name === 'Dedupe') {
        //                             console.log('item=: 1562', JSON.stringify(item));
            
        //                             // Step 1: Remove component from DOM by setting false
        //                             item.isDeDupeScreen = false;
        //                         }
        //                         // return item;
        //                     });
        //                 }
        //             });
            
        //             this.applicantList = updatedApplicantList;
            
        //             // Step 2: Add a small delay before setting it back to true
        //             setTimeout(() => {
        //                 let newApplicantList = [...this.applicantList];
        //                 newApplicantList.forEach(iter => {
        //                     console.log('iter.sequence' + event.detail.currentAppSeq);
        //                     console.log('iter.sequence 1579-----',iter.sequence);
        //                     if (iter.sequence == event.detail.currentAppSeq) {
        //                         iter.stages = iter.stages.map(item => {
        //                             if (item.name === 'Dedupe') {
        //                                 item.isDeDupeScreen = true; // Now add it back
        //                                 console.log(' item.isDeDupeScreen -----', item.isDeDupeScreen );
        //                             }
        //                             this.activeSectionToBePassed = item;
        //                             this.activeSectionName = 'Dedupe';
        //                             item.isApplicantCmp = false;
        //                             item.isConsent = false;
        //                             item.isSwapApplicant = false;
        //                             item.isDocument = false;
        //                             item.isBureau = false;
        //                             item.isApplicantAdditionalInformation = false;
        //                             item.isApplicantAddressInformation = false;
        //                             item.isPersonalInformation = false;
        //                             item.isAddressInformation = false;
        //                             item.isEmploymentInformation = false;
        //                             item.isCurrentAddressInformation = false;
        //                             item.isPermanentAddressInformation = false;
        //                             item.isCurrentEmploymentInformation = false;
        //                             item.isAnnualIncomeInformation = false;
        //                             this.otherInfo = false
        //                             console.log(' item.isDeDupeScreen -----', item.isDeDupeScreen );
        //                             // setTimeout(()=>{
        //                             item.isBasicDetails = false;
        //                             // return item;
        //                         });
        //                     }
        //                 });
        //                 this.applicantList = newApplicantList;
        //                 this.openInPopUp = true;
        //             }, 100); // Short delay to allow DOM update
        //             this.isloading = false;
        //         }
        //         this.isloading = false;
        //     },1000)
        // }
        // catch(error){
        //     this.isloading = false;
        //     console.log('error 1628=:'+error);
        //     console.log('error 1628=:'+JSON.stringify(error));
        // }
        
    }
        handleOpenPrimaryScreen(event) {
            this.passedScreenName = event.detail.name;
            this.showPrimaryDetails = true;
            this.applicantList.forEach(iter => {
                if (iter.sequence == event.detail.currentAppSeq) {
                    iter.stages.forEach(item => {
                        if (item.name == 'PAN/Form 60 Details') {
                            console.log('item=:' + JSON.stringify(item));
                            this.activeSectionToBePassed = item;
                            this.activeSectionName = 'PAN/Form 60 Details';
                            item.isApplicantCmp = true;
                            item.isConsent = false;
                            item.isDeDupeScreen = false;
                            item.isSwapApplicant = false;
                            item.isDocument = false;
                            item.isBureau = false;
                            item.isCKYCDetails = false;
                            //HL-Ishi-23/09
                            item.isCibil = false;
                            item.isCrif = false;
                            //HL-Ishi-23/09
                            item.isApplicantAdditionalInformation = false;
                            item.isApplicantAddressInformation = false;
                            item.isPersonalInformation = false;
                            item.isAddressInformation = false;
                            item.isEmploymentInformation = false;
                            item.isCurrentAddressInformation = false;
                            item.isPermanentAddressInformation = false;
                            item.isCurrentEmploymentInformation = false;
                            item.isAnnualIncomeInformation = false;
                            item.isEmploymentDetails = false;
                            // setTimeout(()=>{
                            item.isBasicDetails = false;
                            // },200)
                        }
                        if (item.name == 'Aadhar Details') {
                            console.log('item=:' + JSON.stringify(item));
                            this.activeSectionToBePassed = item;
                            this.activeSectionName = 'Aadhar Details';
                            item.isApplicantCmp = false;
                            item.isConsent = false;
                            item.isDeDupeScreen = false;
                            item.isSwapApplicant = false;
                            item.isDocument = false;
                            item.isBureau = false;
                            item.isCKYCDetails = false;
                            //HL-Ishi-23/09
                            item.isCibil = false;
                            item.isCrif = false;
                            //HL-Ishi-23/09
                            item.isApplicantAdditionalInformation = false;
                            item.isApplicantAddressInformation = false;
                            item.isPersonalInformation = false;
                            item.isAddressInformation = false;
                            item.isEmploymentInformation = false;
                            item.isCurrentAddressInformation = false;
                            item.isPermanentAddressInformation = false;
                            item.isCurrentEmploymentInformation = false;
                            item.isAnnualIncomeInformation = false;
                            // setTimeout(()=>{
                            item.isBasicDetails = false;
                            this.isAadharDetails = true;
                            // },200)
                        }
                    })
                }
            })
        }
      

        // this.newSeq = event.detail.currentAppSeq;
        // this.newAppSeq = event.detail.appSeq;
        // console.log('appseq---', event.detail.appSeq)
        // this.makeAppCmponentVisible = true;


       
            // this.getApplicantList();
      
        

        // this.applicantId = event.detail.applicantId;
    
    setPrimaryAccordian() {
        console.log('appseq-- 585-', JSON.stringify(this.applicantList))
        this.makeAppCmponentVisible = false;
        this.applicantList.forEach(iter => {
            if (iter.sequence == this.newAppSeq) {
                iter.stages.forEach(item => {
                    if (item.sequence == '2') {
                        console.log('appseq-- 590-', this.newSeq)
                        this.activeSectionName = 'Dedupe';
                        this.activeSectionToBePassed = item;
                        item.isApplicantCmp = false;
                        item.isConsent = false;
                        item.isDeDupeScreen = true;
                        item.isBasicDetails = false;
                        item.isSwapApplicant = false;
                        item.isDocument = false;
                        item.isBureau = false;
                        item.isCKYCDetails = false;
                        //HL-Ishi-23/09
                        item.isCibil = false;
                        item.isCrif = false;
                        //HL-Ishi-23/09
                    }

                })

            }

        })

    }

    handleRefreshComponent(){
        console.log('handleRefreshComponent>>>......RIAAAA');
    }
    handleDeleteApplicant(event) {
        this.showConfBox = true;
        this.applicantSequence = event.target.dataset.id;
    }
    closeicon() {
        this.showConfBox = false;
    }
    openPanVal() {
        this.activeSectionName = 'Pan Validation Response';
    }
    previousActionFromCustom(event){
        console.log('1037');
        this.handleCallApplicantMethod(event);
                  
    }

    checkOtherInformationNavigate(event){
        try{
             console.log('Event in checkOtherInformationNavigate-----', JSON.stringify(event));
            this.getCurrentApplicantList();
            
       
        const applicantId= event.detail.applicantId;
        const screenName= event.detail.screenName;
        console.log('screenName at 1134---', screenName);
        
        const currentApplicantIndex = this.applicantList.findIndex(applicant => applicant.applicantId === applicantId);
        console.log('currentApplicantIndex-----', currentApplicantIndex);
        

        

        if (currentApplicantIndex != -1) {
            const prevApplicant = this.applicantList[currentApplicantIndex];
            console.log('prevApplicant-----', JSON.stringify(prevApplicant));

            if(screenName== 'Applicant\'s Additional Information'){
                this.activeSectionName = 'Applicant\'s Address Information';
                prevApplicant.stages.forEach(stage => {
                    if(stage.name== 'Applicant\'s Address Information'){
                        stage.isApplicantAddressInformation = true; 
                        stage.isApplicantCmp=false;
                    }else if(stage.name== 'Applicant\'s Additional Information'){
                        this.formName = 'Applicant Other Details';
                        stage.isApplicantAdditionalInformation = false; 
                        stage.isApplicantCmp=false;
                    }
                    
                });
            }
            else if(screenName== 'Applicant\'s Address Information'){
                prevApplicant.stages.forEach(stage => {
                    if(stage.name== 'Applicant\'s Address Information'){
                        stage.isApplicantAddressInformation = false; 
                        
                    }
                    stage.isApplicantCmp=false;
                });
            }

            this.applicantList[currentApplicantIndex] =  prevApplicant;
            console.log('prevApplicant-----', JSON.stringify(prevApplicant));

            console.log('this.applicantList in event----', JSON.stringify(this.applicantList));
            

            if(screenName == 'Applicant\'s Address Information'){
                const nextApplicant = this.applicantList[currentApplicantIndex + 1];
                console.log('nextApplicant-----', JSON.stringify(nextApplicant));
                if (nextApplicant) {
                    this.activeParentSectionName = nextApplicant.name;
                    this.activeSectionName = 'Applicant\'s Additional Information';
                    this.currentAppSeq = parseInt(nextApplicant.sequence);

                    // this.applicantList.forEach(iter => {
                    //     iter.stages.forEach(item => {
                    //         console.log('item 75-', item);
                    //         this.activeSectionName = 'Applicant\'s Additional Information';
                    //         this.activeSectionToBePassed = item;
                    //         item.isApplicantCmp = true;
                    //         item.isConsent = false;
                    //         item.isDeDupeScreen = false;
                    //         item.isBasicDetails = false;
                    //         item.isPanValidation = false;
                    //         item.isDocument = false;
                    //         item.isBureau = false;
                    //         item.isApplicantAdditionalInformation = false;
                    //         item.isApplicantAddressInformation = false;
                    //         item.isPersonalInformation = false;
                    //         item.isAddressInformation = false;
                    //         item.isEmploymentInformation = false;
                    //         item.isCurrentAddressInformation = false;
                    //         item.isPermanentAddressInformation = false;
                    //         item.isCurrentEmploymentInformation = false;
                    //         item.isAnnualIncomeInformation = false;
                    //     })
        
                    // })
        
                    console.log('this.currentAppSeq in event----', this.currentAppSeq);
                    
                    nextApplicant.stages.forEach(stage => {
                        if(stage.name== 'Applicant\'s Additional Information'){
                            this.formName = 'Applicant Other Details';
                            stage.isApplicantAdditionalInformation = true; 
                            
                        }
                       //  stage.isApplicantCmp=true;
                    });

                    this.applicantList[currentApplicantIndex + 1] =  nextApplicant;
                }else{
                    this.dispatchEvent(new CustomEvent('navigatetonexttab', {
                        detail: 'Application Other Details'
                    }));
                }
                console.log('nextApplicant-----', JSON.stringify(nextApplicant));


            }
            
            console.log('this.applicantList in event neww----', JSON.stringify(this.applicantList));
            
        }
        console.log('3499999 get current applicant list>>.');
        
    }
    catch(error){
        console.log('error in navigateToNextSectionCmp---'+error);
    }
    }

    navigateNext(event){
        console.log('event in navigate next appliant info---');
        
        this.dispatchEvent(new CustomEvent('navigatetonexttab', {
            detail: 'Application Information'
        }));
    }

    // Fired by c-process-journey-cmp when a stage <li> is clicked (same "valuechange" contract
    // used by SalesLoginActionFlowCmp.handleClick). Re-dispatches as navigatetonexttab so the
    // parent c-sales-login-action-flow-cmp opens the matching section, same as clicking its path item.
    handleProcessJourneyNavigate(event){
        const stageName = event.detail && event.detail.name;
        if (!stageName) {
            return;
        }
        // "Applicant Information" is the outer stage this component itself renders for.
        // Dispatching navigatetonexttab for it is a no-op in the parent (isRelatedToApplicantInformation
        // stays true, so nothing re-renders there) - so when the user clicks it to revisit an already
        // completed Applicant Information stage, reset this component's own accordion back to the
        // first applicant instead, so the click has a visible effect.
        if (stageName === 'Applicant Information') {
            this.activeSectionName = '';
            this.activeParentSectionName = (this.applicantList && this.applicantList.length)
                ? this.applicantList[0].name
                : '';
            this.getApplicantList();
            return;
        }
        this.dispatchEvent(new CustomEvent('navigatetonexttab', {
            detail: stageName
        }));
    }
     scrollToBottom() {
            const bottomAnchor = this.template.querySelector('.bottom-anchor');
            if (bottomAnchor) {
                bottomAnchor.scrollIntoView({ behavior: 'smooth', block: 'end' });
            }
        }
        applicantId;
        handleAddAddress(event){
            console.log('handleAddAddress called Kshitiz address---',event.detail);
            try{
                //this.template.querySelector('c-sales-login-address-details-cmp').loadAddresses();
                this.applicantId = event.detail;
                this.addressRefreshTrigger = this.addressRefreshTrigger + 1;
            }
            catch(error){
                console.log('error in handleAddAddress---'+error);
            }
        }
    //HL-Ishi-25/09
    checkIfLoggedInUserIsHLRelated() {
        checkIfLoggedInUserIsHLRelated()
            .then(result => {
                this.isHLUser = result.isHLRelated;
                console.log('isHLUser-->', this.isHLUser);
            })
            .catch(error => {
                console.log('error-->', error);
            })
    }

    //HL-Ishi-25/09

    //below method added by Kunal Bisht for SFHL-1420
    async handleDeleteCoApplicantAndRelatedRecords(event) {
        try {
            const accordionName = event.currentTarget.dataset.id;
            const applicant = this.applicantList.find(iter => iter.name === accordionName);
            this.cuurentAppId = applicant.applicantId;

            const verificationExists =
                await checkIfApplicationVerificationRecordExists({
                    coAppId: this.cuurentAppId
                });

            if (verificationExists) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Application Verification record exists for this Co-Applicant!',
                        variant: 'error',
                    }),
                )
                return;
            }

            const isConfirmed = await LightningConfirm.open({
                message: 'Are you sure you want to delete this record?',
                label: 'Confirm Deletion',
                theme: 'warning'
            });

            if (!isConfirmed) {
                return;
            }

            await deleteCoAppAndRelatedRecords({
                coAppId: this.cuurentAppId
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Co-Applicant deleted successfully!',
                    variant: 'success',
                }),
            )

            setTimeout(() => {
                window.location.reload();
            }, 1000);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Something went wrong',
                    variant: 'error',
                }),
            )
        }
    }

}