import { LightningElement,api,wire,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import getSubStageList from '@salesforce/apex/COMM_SalesLoanActionsController.getSubStageList';
import getCustomerType from '@salesforce/apex/ScreenGenerationController.getCustomerType';
import getApplicants from '@salesforce/apex/AHL_LoanApplicationActionController.getApplicantsByLoanApplication';

export default class SalesLoanLoginMainCmp extends LightningElement {
    @api recordId;
    activeSection = {};
    @api passedScreenName = '';
    @track openSections = [];
    @track checkloginchecklist = [];
    allSections=[];
    isRendered = false;
    @track screenName = '';
    stages = [];
    rerenderCmp;
    otherInformation = false;
    applicationOtherDetails = false;
    applicantOtherDetails = false;
    loginChecklist =false;
    isLoginCheckList=false;
    showdoc = false;
    showFSA = false;
    showException = false;
    applicantDetails = false;
    showApplicantOtherInfo = false;
    showBSA = false;
    showGSTScreen = false;
    showITRScreen = false;
    showIncomeAssessment = false;
    showdocchecklist=false;
    showBuilderSellerDetails = false;
    showIncomeEligibility=false;
    showCollateral= false;
    showDirectorsDetails =false;
    @api formName;
    showOpenAll=false;
    showCloseAll=true;
    @track customerType;
    dataLoaded = false;
    @track applicantList = [];
    @api changeMessage(str) {
        console.log('str.detail.name---', str.detail.name)
        //this.activeSection = '';
        this.passedScreenName = str.detail.name;
        
        console.log('-----------------------------121', this.passedScreenName);
        setTimeout(() => {
            this.getSubStageList();
            if(this.passedScreenName== 'Login Checklist'){
                this.isLoginCheckList=true;
                // this.openAllSections();
            }else{
                this.isLoginCheckList=false;
            }
        }, 100)


    }
    connectedCallback() {
        this.rerenderCmp = false;
        // this.closeAllSections();
        this.getCustomerType();
        this.getApplicants();
        setTimeout(() => {
            this.getSubStageList();
            if(this.passedScreenName== 'Login Checklist'){
                this.isLoginCheckList=true;
                this.openAllSections();
            }else{
                this.isLoginCheckList=false;
            }
        }, 100)
    }
      getApplicants() {
        getApplicants({
            loanApplicationId: this.recordId
        }).then(response => {
            console.log('response=: partner 1' + JSON.stringify(response));
            this.applicantList = response;
            this.applicantList.forEach(applicant => {   
                console.log('applicant.Customer_Type__c 1---> ' + applicant.Customer_Type__c);
                if(applicant.Customer_Type__c == 'Non Individual'){
                    this.nonIndiFlag = true;
                }
            });

        }).catch(error => {
            console.log('Error in fetching customer type', error);
        })
      }
    getCustomerType() {
        getCustomerType({
            loanId: this.recordId
        }).then(response => {
            console.log('response=: partner' + JSON.stringify(response));
            this.customerType = response.customerType;
            
        }).catch(error => {
            console.log('Error in fetching customer type', error);
        })
    }

    openAllSections() {
        console.log('Inside open allll---');
        this.showOpenAll=false;
        this.showCloseAll=true;
        this.openSections = this.stages.map(section => section.name);
        this.checkloginchecklist = this.openSections;
        console.log('checkloginchecklist '+this.checkloginchecklist);
        this.allSections = this.stages.map(section => section.name);
        this.stages = this.stages.map(stage => {
            let newParams = {}; // Object to store new parameters

            // Check the name and add new properties dynamically
            console.log('stage.name in openAll----', stage.name);
            switch (stage.name) {
                
                
                case "Loan Data Summary":
                    newParams.showIncomeEligibility = false;
                    newParams.showCollateral = false;
                    newParams.showdocchecklist = false;
                    newParams.loginChecklist = false;
                    newParams.showLoanSummary = true;
                    newParams.showApplicantSummary=false;
                    newParams.passedScreenName= stage.name;
                    break;

                case "Applicant Data Summary":
                    newParams.showIncomeEligibility = false;
                    newParams.showdocchecklist = false;
                    newParams.loginChecklist = true;
                    newParams.showLoanSummary = false;
                    newParams.showApplicantSummary=false;
                    newParams.showCollateral = false;
                    newParams.passedScreenName= 'Login Checklist';
                    break;

                case "Document Summary":
                    newParams.showIncomeEligibility = false;
                    newParams.showdocchecklist = true;
                    newParams.loginChecklist = false;
                    newParams.rerenderCmp = false;
                    newParams.showLoanSummary = false;
                    newParams.showApplicantSummary=false;
                    newParams.showCollateral = false;
                    newParams.passedScreenName= stage.name;
                    break;

                case "Income Eligibility":
                    newParams.showIncomeEligibility = true;
                    newParams.showdocchecklist = false;
                    newParams.loginChecklist = false;
                    newParams.rerenderCmp = false;
                    newParams.showLoanSummary = false;
                    newParams.showCollateral = false;
                    newParams.passedScreenName= stage.name;
                    newParams.showApplicantSummary=false;
                    break;

                case "Collateral":
                    newParams.showIncomeEligibility = false;
                    newParams.showCollateral = false;
                    newParams.showdocchecklist = false;
                    newParams.loginChecklist = false;
                    newParams.rerenderCmp = false;
                    newParams.showLoanSummary = false;
                    newParams.passedScreenName= stage.name;
                    newParams.showApplicantSummary=false;
                    break;

                default:
                    newParams.showIncomeEligibility = false;
                    newParams.showdocchecklist = false;
                    newParams.showCollateral = false;
                    newParams.loginChecklist = false;
                    newParams.rerenderCmp = true;
                    newParams.showLoanSummary = false;
                    newParams.passedScreenName= stage.name;
                    newParams.showApplicantSummary=false;
                    break;
            }

            // Return the updated object with original + new properties
            return {
                ...stage,  // Keep all original properties
                // Add new property
                ...newParams  // Merge dynamically created properties
            };
        });
        console.log('this.openSections----', JSON.stringify(this.openSections));
        console.log('this.openSections---stagesss-', JSON.stringify(this.stages));
    }

    handleOpenProductDet(event){
        event.stopPropagation();
        this.screenName = event.detail.screenName;
        this.activeSection = '';
        console.log('inside open product det');
        // this.rerenderCmp = false;
        setTimeout(()=>{
            // this.rerenderCmp=true;
            this.passedScreenName = 'Application Information';
            setTimeout(()=>{
                this.getSubStageList();
            },100)
        },100)

    }

    closeAllSections() {
        this.openSections = [];
        this.checkloginchecklist = [];
        this.showOpenAll=true;
        this.showCloseAll=false;
    }
    // Exposed so LoanLoginParentCmp.refreshaction can trigger a refresh on the active
    // screen now that there's no standalone journey/action-flow component to route
    // refreshActions through (mirrors changeMessage already being @api here for the
    // same cross-component reason).
    @api
    getSubStageList() {
        try {
            this.rerenderCmp = false;
            this.showdoc = false;
            this.showException = false;
            this.showGSTScreen = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
            this.applicantOtherDetails = false;
            this.loginChecklist=false;
            this.showApplicantOtherInfo = false;
            this.showBSA = false;
            this.formName = null;
            this.showCollateral = false;
            this.showBuilderSellerDetails = false;
            if(this.passedScreenName == 'Eligibility'){
                this.passedScreenName = 'Income Eligibility';
            }

            console.log('this.passedScreenName=:' + this.passedScreenName);
            getSubStageList({
                loanId: this.recordId,
                applicableStage: this.passedScreenName,
                formName:this.formName
            })
                .then(response => {
                    console.log('Substage response: 66', response);
                console.log('customerType578', this.customerType);
                    response.forEach(element => {
                        if(element.name == 'GST' || element.name == 'Financial Statement Analysis'){
                            this.gstFlag = true;
                        }
                    });
                    if(!this.gstFlag || !this.nonIndiFlag){
                    response = response.filter(subStage => 
                        (subStage.applicableFor === this.customerType || subStage.applicableFor === 'Both') 
                        );
                    }
                    this.stages = response;
                console.log('Substage  this.stages: 68', JSON.stringify(this.stages));
                console.log('this.activeSection getSubStageList=: 69' + this.activeSection);
                console.log('this.activeSection getSubStageList =:' + JSON.stringify(this.activeSection));
                    console.log('this.activeSection.name 234---> ' + this.activeSection.name);
                console.log('this.activeSection.name 234---> ' + this.screenName);
                   // if (this.activeSection != '' && this.activeSection != null && this.activeSection != undefined && this.activeSection.length >0) {
                if(this.activeSection?.name != 'PMAY Eligibility' && this.screenName != 'Loan Details'){
                        
                    if (this.activeSection != '' && this.activeSection != null && this.activeSection != undefined && this.activeSection.length >0) {
                        console.log('inside if 44');
                        for (let i = 0; i < this.stages.length; i++) {
                            if (this.stages[i].name === this.activeSection) {
                                this.stages[i].name = this.activeSection;
                            }
                        }
                        }else {
                        this.activeSection = this.stages[0];
                    }
                }
                    console.log('inside else 68', this.activeSection.name);
                if(this.activeSection?.name == 'PMAY Eligibility' && this.screenName == 'Loan Details'){
                    this.activeSection.name = 'Loan Details';
                    this.rerenderCmp = true;
                    this.applicantOtherDetails = false;
                    this.showApplicantOtherInfo = false;
                    this.showCollateral =false;
                    this.showBuilderSellerDetails = false;
                    this.loginChecklist=false;
                    this.showdoc = false;
                    this.showException = false;
                    this.applicantDetails = false;
                    this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    this.passedScreenName = "Loan Details";
                    this.formName = 'Loan Login Form';
                    this.showIncomeEligibility= false;
                    this.showdocchecklist = false;
                        this.showFSA = false;
                    }else if (this.activeSection.name == 'Application Other Details') {
                    console.log('inside if button');
                    console.log('inside else 71', this.applicantOtherDetails);
                    //this.applicationOtherDetails = true;
                    this.showApplicantOtherInfo = true;

                    this.showdoc = false;
                    this.showException = false;
                    this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    this.showCollateral = false;
                         this.showFSA = false;
                    this.showBuilderSellerDetails = false;
                    this.passedScreenName = 'Application Other Details'
                    this.formName = 'Application Other Details';
                    } else if (this.activeSection?.name == 'Applicant Other Details') {
                    console.log('inside else 71', this.applicantOtherDetails);
                    this.applicantOtherDetails = true;
                    this.loginChecklist=false;
                    this.rerenderCmp = false;
                    this.showApplicantOtherInfo = false;
                    this.showdoc = false;
                        this.showFSA = false;
                    this.showException = false;
                    this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    this.passedScreenName = "Applicant Other Details";
                    this.formName = 'Applicant Other Details';
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                }
                else if (this.activeSection?.name == 'Login Fees') {
                    console.log('inside else 255');
                    this.applicantOtherDetails = true;
                    this.loginChecklist=false;
                    this.rerenderCmp = false;
                    this.showApplicantOtherInfo = false;
                    this.showdoc = false;
                        this.showFSA = false;
                    this.showException = false;
                    this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    this.passedScreenName = "Login Fees";
                    this.formName = 'Login Fees';
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                    }else if (this.activeSection?.name == 'Applicant Details') {
                    console.log('inside else 71', this.applicantOtherDetails);
                    this.applicantDetails = true;
                    this.rerenderCmp = false;
                    this.applicantOtherDetails = false;
                    this.loginChecklist=false;
                    this.showApplicantOtherInfo = false;
                    this.showdoc = false;
                    this.showException = false;
                        this.showFSA = false;
                    this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                    this.passedScreenName = "Applicant Details";
                    // this.formName = 'Applicant Details';
                    } else if (this.activeSection?.name == 'Document details') {
                    this.showdoc = true;
                    this.rerenderCmp = false;
                    this.showException = false;
                        this.showFSA = false;
                    this.applicantOtherDetails = false;
                    this.loginChecklist=false;
                    this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                    this.passedScreenName = this.activeSection.name;
                    this.showDirectorsDetails = false;
                    // this.formName = this.activeSection.name;
                    } else if (this.activeSection?.name == 'Exception Flow') {
                    this.showException = true;
                    this.rerenderCmp = false;
                    this.showdoc = false;
                        this.showFSA = false;
                    this.applicantOtherDetails = false;
                    this.loginChecklist=false;
                    this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                    this.passedScreenName = this.activeSection.name;
                    // this.formName = this.activeSection.name;
                } 
                else if(this.activeSection?.name == 'Bank Statement Analysis'){
                    this.showBSA = true;
                    this.rerenderCmp = false;
                    this.applicantOtherDetails = false;
                    this.loginChecklist=false;
                    this.showApplicantOtherInfo = false;
                        this.showFSA = false;
                    this.showdoc = false;
                    this.showException = false;
                    this.applicantDetails = false;
                    this.showGSTScreen = false;
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    this.passedScreenName = "Bank Statement Analysis";
                    this.formName = 'Bank Statement Analysis';
                }
                else if(this.activeSection?.name == 'Financial Statement Analysis'){
                    console.log('Inside 140');
                    // this.showBSA = true;
                    this.rerenderCmp = false;
                    this.applicantOtherDetails = false;
                    this.loginChecklist=false;
                    this.showApplicantOtherInfo = false;
                    this.showdoc = false;
                    this.showException = false;
                    this.applicantDetails = false;
                    this.showGSTScreen = false;
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    this.passedScreenName = "Financial Statement Analysis";
                    this.formName = 'Financial Statement Analysis';
                        this.showBSA = false;
                        this.showFSA = true;
                    console.log('I this.showBSA ', this.showBSA );
                }
                else if(this.activeSection?.name == 'GST'){
                    console.log('Inside 140');
                    // this.showBSA = true;
                    this.rerenderCmp = false;
                    this.applicantOtherDetails = false;
                    this.loginChecklist=false;
                    this.showApplicantOtherInfo = false;
                    this.showdoc = false;
                    this.showException = false;
                        this.showFSA = false;
                    this.applicantDetails = false;
                    this.showGSTScreen = true;
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    this.passedScreenName = "GST";
                    this.formName = 'GST';
                    this.showBSA = false;
                    this.showDirectorsDetails = false;
                    console.log('I this.showBSA ', this.showBSA );
                }
                else if(this.activeSection?.name == 'ITR'){
                    console.log('Inside 140');
                    // this.showBSA = true;
                    this.rerenderCmp = false;
                        this.showFSA = false;
                    this.applicantOtherDetails = false;
                    this.loginChecklist=false;
                    this.showApplicantOtherInfo = false;
                    this.showdoc = false;
                    this.showException = false;
                    this.applicantDetails = false;
                    this.showGSTScreen = false;
                    this.showITRScreen = true;
                    this.showIncomeAssessment = false;
                    this.passedScreenName = "ITR";
                    this.formName = 'ITR';
                    this.showBSA = false;
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                    console.log('I this.showBSA ', this.showBSA );
                }
                else if(this.activeSection?.name == 'Income Assessment'){
                    console.log('Inside 140');
                    // this.showBSA = true;
                    this.rerenderCmp = false;
                    this.applicantOtherDetails = false;
                    this.loginChecklist=false;
                    this.showApplicantOtherInfo = false;
                    this.showdoc = false;
                    this.showException = false;
                    this.applicantDetails = false;
                    this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = true;
                    this.passedScreenName = "Income Assessment";
                    this.formName = 'Income Assessment';
                    this.showBSA = false;
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                    console.log('I this.showBSA ', this.showBSA );
                }
                else if(this.activeSection?.name == 'Income Eligibility'){
        
                    this.rerenderCmp = false;
                    this.applicantOtherDetails = false;
                    this.showApplicantOtherInfo = false;
                    this.loginChecklist=false;
                    this.showdoc = false;
                    this.showException = false;
                    this.applicantDetails = false;
                    this.showBSA = false;
                    this.showGSTScreen = false;
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    setTimeout(()=>{
                        
                        this.showIncomeEligibility=true;
                    },500)
                
                }
                else if(this.activeSection?.name == 'Applicant Data Summary'){
                    console.log('Inside 154');
                    // this.showBSA = true;
                    this.rerenderCmp = false;
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                    this.showApplicantOtherInfo = false;
                    this.showdoc = false;
                    this.showException = false;
                        this.showFSA = false;
                    this.applicantDetails = false;
                    this.passedScreenName = "Login Checklist";
                    this.formName = 'Login Checklist';
                    this.applicantOtherDetails = false;
                    this.loginChecklist=true;
                        this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    console.log('I this.showBSA ', this.showBSA );
                }
                else if (this.activeSection?.name == 'Document Summary') {
                    console.log('At 177');
                    
                    this.applicationDetails = true;
                        this.showFSA = false;
                    this.rerenderCmp = false;
                    this.showException = false;
                    this.rerenderCmp = false;
                    this.showdocchecklist = true;
                    this.applicantOtherDetails = false;
                    this.loginChecklist=false;
                    this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                    this.showApplicantOtherInfo = false;
                    this.passedScreenName = "Document details";
                    this.showDirectorsDetails = false;
                    // this.formName = 'Document details';
                }
                else if (this.activeSection?.name == 'Collateral') {
                    console.log('At 177');
                        this.showFSA = false;
                    this.applicationDetails = false;
                    this.rerenderCmp = false;
                    this.showException = false;
                    this.rerenderCmp = false;
                    this.showdocchecklist = false;
                    this.applicantOtherDetails = false;
                    this.loginChecklist=false;
                        this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    this.showCollateral = true;
                    this.showBuilderSellerDetails = false;
                    this.showApplicantOtherInfo = false;
                    this.passedScreenName = "Collateral";
                    // this.formName = 'Document details';
                }
                else if(this.activeSection?.name == 'Builder Details' || this.activeSection?.name == 'Seller Details'){
                        this.applicationDetails = false;
                    this.rerenderCmp = false;
                        this.showFSA = false;
                    this.showException = false;
                    this.rerenderCmp = false;
                    this.showdocchecklist = false;
                    this.applicantOtherDetails = false;
                    this.loginChecklist=false;
                        this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    this.showCollateral = false;
                    this.showApplicantOtherInfo = false;
                    this.showBuilderSellerDetails = true;
                    this.passedScreenName = this.activeSection.name == "Builder Details" ? "Builder Details" : "Seller Details";
                    this.formName = this.activeSection.name == "Builder Details" ? "Builder Details" : "Seller Details";
                }
                else if (this.activeSection.name == "Director's Details") {
                        console.log('inside Director\'s Details check for active section');
                        this.applicantOtherDetails = false;
                        this.loginChecklist=false;
                        this.rerenderCmp = false;
                        this.showApplicantOtherInfo = false;
                        this.showdoc = false;
                        this.showException = false;
                         this.showFSA = false;
                        this.applicantDetails = false;
                        this.showGSTScreen = false;
                        this.showCollateral = false;
                        this.showBuilderSellerDetails = false;
                        this.showITRScreen = false;
                        this.showIncomeAssessment = false;
                        this.showBSA = false;
                        this.passedScreenName = "Director's Details";
                        this.formName = "Director's Details";
                        this.showDirectorsDetails = true;

                }
                else {
                        this.showFSA = false;
                    this.rerenderCmp = true;
                    this.applicantOtherDetails = false;
                    this.applicantDetails = false;
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                    // this.formName = 'Loan Login Form';
                }


                if(this.passedScreenName== 'Login Checklist'){
                    // this.isLoginCheckList=true;
                    this.openAllSections();
                }
               // }
            })
            .catch(error => {
                    console.log('Error getting sub stage list:', JSON.stringify(error));
            });
        } catch (error) {
            console.log('error=:144 main' + error);
            console.log('error=:144 main' + JSON.stringify(error))
        }

    }

    handleAccordianClickFocus(event){
        event.stopPropagation();
    }

    handleAccordionClick(event) {
       
        event.stopPropagation();
        try {
            if(this.isLoginCheckList){
                console.log('before event>',event.currentTarget);
                const activeSectionName = event.currentTarget.name; // Assuming event.detail.name contains the name of the clicked section
                console.log('Clicked section name:', activeSectionName);
                console.log('opensections in handleAccordionClick 1', JSON.stringify(this.checkloginchecklist));
                var containsSection=  this.checkloginchecklist.includes(activeSectionName);
                if(containsSection){
                    this.checkloginchecklist = this.openSections.filter(section => section != activeSectionName);
                    this.showOpenAll= true;
                    this.showCloseAll=false;
                }else{
                    this.checkloginchecklist.push(activeSectionName);
                    if(this.checkloginchecklist.length == this.openSections.length){
                        this.showCloseAll= true;
                    }
                }
                this.checkloginchecklist = this.openSections.filter(section => section !== activeSectionName);
                console.log('opensections in handleAccordionClick 2', JSON.stringify(this.checkloginchecklist))
            }
            
            console.log('event--Kshitiz>');
            console.log('name--129', event.currentTarget.name);
            const selectedStage = event.currentTarget.name;
            if (selectedStage== undefined || selectedStage == this.activeSection.name) {
                console.log('Preventing unnecessary re-render');
                return;
            }

            this.rerenderCmp = false;
            this.formName = null;
            this.showBSA = false;
            //this.getSubStageList();
            // this.activeSection.name = '';
            

            console.log('this.passedScreenName at 338----', this.passedScreenName);
            console.log('this.activeSection.name at 338----', this.activeSection.name);
            
            
            
            // if(this.activeSection.name == 'Applicant Other Details') {
            //     console.log('inside app other dets');
            //     selectedStage = 'Applicant Other Details';
            // }
            console.log('selectedStage', selectedStage);
            console.log('stages--', JSON.stringify(this.stages));
            if (this.activeSection.name !== selectedStage) {
                for (let i = 0; i < this.stages.length; i++) {
                    if (this.stages[i].name === selectedStage) {
                        this.stages[i].name = selectedStage;
                        this.activeSection = this.stages[i];
                        console.log('rerenderCmp--', this.rerenderCmp);
                      
                    }
                }
                console.log('passedScreenName--', this.passedScreenName);
                console.log('activeSection-- Accordian Click ', this.activeSection);
            }
            if (this.activeSection.name == 'Applicant Other Details') {
                console.log('inside else 71', this.applicantOtherDetails);
                this.applicantOtherDetails = true;
                this.loginChecklist=false;
                this.rerenderCmp = false;
                this.showApplicantOtherInfo = false;
                this.showdoc = false;
                this.showException = false;
                this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                this.passedScreenName = "Applicant Other Details";
                 this.formName = 'Applicant Other Details';
                 this.showIncomeEligibility= false;
                 this.showdocchecklist = false;
                 this.showDirectorsDetails = false;
            } else if (this.activeSection.name == 'Application Other Details') {
                console.log('inside else 1971', this.applicantOtherDetails);
                this.showApplicantOtherInfo = true;
                this.applicantOtherDetails = false;
                this.applicantOtherDetails = false;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                    this.showCollateral = false;
                    this.showBuilderSellerDetails = false;
                this.passedScreenName = 'Application Other Details'
                 this.formName = 'Application Other Details';
                 this.showIncomeEligibility= false;
                 this.showdocchecklist = false;
                 this.showDirectorsDetails = false;
            } else if (this.activeSection.name == 'Applicant Details') {
                this.applicantDetails = true;
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.loginChecklist=false;
                this.showCollateral = false;
                this.showBuilderSellerDetails = false;
                this.showApplicantOtherInfo = false;
                this.showdoc = false;
                this.showException = false;
                this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                this.passedScreenName = "Applicant Details";
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                this.showDirectorsDetails = false;
                // this.formName = 'Applicant Details';
            } else if (this.activeSection.name == 'Exception Flow') {
                this.applicationDetails = true;
                this.rerenderCmp = false;
                this.showCollateral = false;
                this.showBuilderSellerDetails = false;
                this.showException = true;
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.loginChecklist=false;
                this.showApplicantOtherInfo = false;
                this.showdoc = false;
                this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                this.passedScreenName = "Exception Flow";
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                this.showDirectorsDetails = false;
                // this.formName = 'Exception Flow';
            } else if (this.activeSection.name == 'Document details') {
                this.applicationDetails = true;
                this.rerenderCmp = false;
                this.showCollateral = false;
                this.showBuilderSellerDetails = false;
                this.showException = false;
                this.rerenderCmp = false;
                this.showdoc = true;
                this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                this.applicantOtherDetails = false;
                this.loginChecklist=false;
                this.showApplicantOtherInfo = false;
                this.passedScreenName = "Document details";
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                this.showDirectorsDetails = false;
                // this.formName = 'Document details';
            }else if (this.activeSection.name == 'Document Summary') {
                console.log('At 290');
                
                this.applicationDetails = true;
                this.showCollateral = false;
                this.showBuilderSellerDetails = false;
                this.rerenderCmp = false;
                this.showException = false;
                this.rerenderCmp = false;
                this.showdocchecklist = true;
                this.applicantOtherDetails = false;
                this.loginChecklist=false;
                this.showApplicantOtherInfo = false;
                this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                this.passedScreenName = "Document details";
                this.showIncomeEligibility= false;
                this.showDirectorsDetails = false;
                // this.formName = 'Document details';
            } else if(this.activeSection.name == 'Bank Statement Analysis'){
                
                this.rerenderCmp = false;
                this.showCollateral = false;
                this.showBuilderSellerDetails = false;
                this.applicantOtherDetails = false;
                this.showApplicantOtherInfo = false;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                this.passedScreenName = "Bank Statement Analysis";
                this.formName = 'Bank Statement Analysis';
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                this.showDirectorsDetails = false;
                setTimeout(()=>{
                    this.showBSA = true;
                },100)
             }
             else if(this.activeSection.name == 'Financial Statement Analysis'){
                
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.showCollateral = false;
                this.showBuilderSellerDetails = false;
                this.showApplicantOtherInfo = false;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                this.showGSTScreen = false;
                    this.showITRScreen = false;
                    this.showIncomeAssessment = false;
                this.passedScreenName = "Financial Statement Analysis";
                this.formName = 'Financial Statement Analysis';
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                this.showDirectorsDetails = false;
                setTimeout(()=>{
                    this.showBSA = true;
                },100)
                
             }
             /*START----Added the code for AHL not used in BL */
             else if(this.activeSection.name == 'GST'){
                
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.showApplicantOtherInfo = false;
                this.showCollateral = false;
                this.showBuilderSellerDetails = false;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                this.passedScreenName = "GST";
                this.formName = 'GST';
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                    this.showGSTScreen = true;
                    this.showITRScreen = false;
                this.showIncomeAssessment = false;
                this.showDirectorsDetails = false;
             }
             else if (this.activeSection.name == "Director's Details") {
                this.rerenderCmp = false;
                this.showApplicantOtherInfo = false;
                this.showCollateral = false;
                this.showBuilderSellerDetails = false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                 this.formName = "Director's Details";
                this.applicantOtherDetails = false;
                this.showdocchecklist = false;
                this.loginChecklist=false;
                this.showIncomeEligibility= false;
                this.passedScreenName = "Director's Details";
                this.showGst = false;
                this.showDirectorsDetails = true;
             }
             else if(this.activeSection.name == 'ITR'){
                console.log('Inside 772 Kshitiz');
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.showApplicantOtherInfo = false;
                this.showCollateral = false;
                this.showBuilderSellerDetails = false;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                this.passedScreenName = "ITR";
                this.formName = 'ITR';
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                    this.showITRScreen = true;
                    this.showIncomeAssessment = false;
                    this.showGSTScreen = false;
                    this.showDirectorsDetails = false;
                
             }
             else if(this.activeSection.name == 'Income Assessment'){
                console.log('Inside 772 Kshitiz');
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.showApplicantOtherInfo = false;
                this.showCollateral = false;
                this.showBuilderSellerDetails = false;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                this.passedScreenName = "Income Assessment";
                this.formName = 'Income Assessment';
                this.showIncomeAssessment = true;
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                    this.showITRScreen = false;
                    this.showGSTScreen = false;
                    this.showDirectorsDetails = false;
                
             }
              /*END----Added the code for AHL not used in BL */
             else if(this.activeSection.name == 'Income Eligibility'){
                
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.showApplicantOtherInfo = false;
                this.loginChecklist=false;
                this.showCollateral = false;
                this.showBuilderSellerDetails = false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                this.showBSA = false;
                 this.showGSTScreen = false;
                this.showITRScreen = false;
                this.showIncomeAssessment = false;
                this.showdocchecklist = false;
                this.showDirectorsDetails = false;
                setTimeout(()=>{
                    this.showIncomeEligibility= true;
                },100)
                
             }
             else if(this.activeSection.name == 'Applicant Data Summary'){
                console.log('Inside 154');
               // this.showBSA = true;
                this.rerenderCmp = false;
                this.showApplicantOtherInfo = false;
                this.showCollateral = false;
                this.showBuilderSellerDetails = false;
                this.showdoc = false;
                this.showException = false;
                 this.showGSTScreen = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
                this.applicantDetails = false;
                this.passedScreenName = 'Login Checklist';
                 this.formName = 'Login Checklist';
                this.applicantOtherDetails = false;
                this.showdocchecklist = false;
                this.loginChecklist=true;
                this.showIncomeEligibility= false;
                this.showDirectorsDetails = false;
                console.log('I this.showBSA ', this.showBSA );
             }
             else if(this.activeSection.name == 'Applicant Data Summary'){
                console.log('Inside 154');
               // this.showBSA = true;
                this.rerenderCmp = false;
                this.showApplicantOtherInfo = false;
                this.showCollateral = true;
                this.showBuilderSellerDetails = false;
                this.showdoc = false;
                this.showException = false;
                 this.showGSTScreen = false;
                this.showITRScreen = false;
                this.showIncomeAssessment = false;
                this.applicantDetails = false;
                this.passedScreenName = 'Collateral';
                this.applicantOtherDetails = false;
                this.showdocchecklist = false;
                this.loginChecklist=false;
                this.showIncomeEligibility= false;
                this.showDirectorsDetails = false;
             }
            else {
                console.log('handle accordian click else');
                this.applicantDetails = false;
                setTimeout(() => {
                    this.rerenderCmp = true;
                }, 100);
                this.applicantOtherDetails = false;
                this.loginChecklist=false;
                this.showApplicantOtherInfo = false;
                this.showCollateral = false;
                this.showBuilderSellerDetails = false;
                this.showdoc = false;
                 this.showGSTScreen = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
                this.showException = false;
                this.showBSA = false;
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;

            }
            // if(this.activeSection.name == 'Applicant’s Other Details') {
            //     this.hideSF = true;
            //     this.rerenderCmp = false;
            // } else {
            //     this.hideSF = false;
            //     this.rerenderCmp = true;
            // }
        } catch (error) {
            console.log('error=:218 main' + error);
            console.log('error=:219 main' + JSON.stringify(error))
        }

    }

    handleRefreshCmp(event) {
        console.log('inside handleRefreshCmp event.detail.loanId=: in main');
        
        // this.recordId = event.detail.loanId;
        // this.template.querySelector('c-sales-login-action-flow-cmp').changeMessage(event);
        console.log('event.detail.screenName---handleRefreshCmp', event.detail.screenName);
        const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
            detail: {
                loanId: event.detail.loanId, 
                screenName: event.detail.screenName
            }
        });
        this.dispatchEvent(valueSelectedEvent);
    }
    handleHighLightScreen(event) {
        console.log('main event.detail.screenName=:' + event.detail.screenName);
        // this.screenName = event.detail.screenName;
        const valueSelectedEvent = new CustomEvent('highlightactivescreen', {
            detail: {
                screenName: event.detail.screenName
            }
        });
        this.dispatchEvent(valueSelectedEvent);
        // console.log(' this.screenName ---', this.screenName )
        // this.template.querySelector('c-sales-login-action-flow-cmp').highlightScreen(this.screenName);
        // console.log(' this.screenName ---', this.screenName )
    }

    handleAddAddress(event) {
        console.log('inside handleAddAddress');
        this.addAddress = true;
    }
    renderedCallback() {
        if (!this.isRendered) {
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
            .navClass .slds-progress-bar__value{
                background: skyblue;
            }
                .instruction-box-nav.slds-progress-bar__value{
                background: skyblue;
            }
            `;
            this.template.querySelector('.styleContainer').appendChild(style);
            this.spinnerClass = 'spinner-medium';
        }
    }

    navigateNext(event){
        console.log('Inside event in main amppppp', event.detail);
        const screenName= event.detail;
        if(screenName== 'Application Other Details'){
            console.log('screenName in navigate nexttt---', screenName);
            for (let i = 0; i < this.stages.length; i++) {
                if (this.stages[i].name === screenName) {
                    this.stages[i].name = screenName;
                    this.activeSection = this.stages[i];
                    console.log('rerenderCmp at 675--', this.rerenderCmp);
                  
                }
            }
            this.showApplicantOtherInfo = true;
            this.applicantOtherDetails = false;
            this.applicantOtherDetails = false;
            this.loginChecklist=false;
            this.showdoc = false;
            this.showException = false;
            this.passedScreenName = "Application Other Details";
            this.formName = 'Application Other Details';
            this.showIncomeEligibility= false;
            this.showdocchecklist = false;
             this.showGSTScreen = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
            this.showCollateral = false;
            this.showDirectorsDetails = false;
                 
        }else{
            console.log('screenName in navigate nexttt---', screenName);
            this.dispatchEvent(new CustomEvent('navigatetonexttab', {
                detail: screenName,
    
            }));
        }
        
    }
    navToOtherDetails(event) {
        console.log('Inside event in main amppppp', event.detail);
    }

    // Fired by c-process-journey-cmp when a stage <li> is clicked (same "valuechange"
    // contract used by SalesLoginActionFlowCmp path clicks). This component doesn't own
    // the stage-switching decision itself - it re-dispatches as "navigatetonexttab" using
    // the same convention every sibling screen (itrScreenCmp, incomeAssessmentMainCmp,
    // salesLoginCollateralDetailCmp, etc.) already uses to bubble a stage name up to
    // loanLoginParentCmp.navigateNext, which routes it through
    // c-sales-login-action-flow-cmp.navigateNext so the click has the same effect as
    // clicking that stage's path item, including revisiting an earlier/completed stage.
    handleProcessJourneyNavigate(event) {
        const stageName = event.detail && event.detail.name;
        if (!stageName) {
            return;
        }
        this.dispatchEvent(new CustomEvent('navigatetonexttab', {
            detail: stageName
        }));
    }

    callLoanDetails(event){
        event.stopPropagation();
        console.log('Inside event callLoanDetails', event.detail);
        
        const selectedStage = event.detail.name;
        this.rerenderCmp = false;
        this.showdoc = false;
        this.showException = false;
        this.applicantOtherDetails = false;
         this.showGSTScreen = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
        this.loginChecklist=false;
        this.showApplicantOtherInfo = false;
        this.showBSA = false;
        this.formName = null;
        this.showCollateral =false;
        this.showBuilderSellerDetails = false;
        this.activeSection = '';
        setTimeout(() => {
            console.log('selectedStage in callLoanDetails', selectedStage);
            console.log('stages--in callLoanDetails', JSON.stringify(this.stages));
            if (this.activeSection.name !== selectedStage) {
                for (let i = 0; i < this.stages.length; i++) {
                    if (this.stages[i].name === selectedStage) {
                        this.stages[i].name = selectedStage;
                        this.activeSection = this.stages[i];
                        console.log('rerenderCmp--', this.rerenderCmp);
                      
                    }
                }
                console.log('passedScreenName--', this.passedScreenName);
                console.log('activeSection-- Accordian Click in callLoanDetails', this.activeSection);
            }
            if (this.activeSection.name == 'Applicant Other Details') {
                console.log('inside else 71', this.applicantOtherDetails);
                this.applicantOtherDetails = true;
                this.loginChecklist=false;
                this.rerenderCmp = false;
                this.showApplicantOtherInfo = false;
                this.showdoc = false;
                this.showException = false;
                this.showGSTScreen = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
                this.passedScreenName = "Applicant Other Details";
                 this.formName = 'Applicant Other Details';
                 this.showIncomeEligibility= false;
                 this.showCollateral =false;
                 this.showBuilderSellerDetails = false;
                 this.showdocchecklist = false;
                  this.showDirectorsDetails = false;
            } else if (this.activeSection.name == 'Application Other Details') {
                console.log('inside else 1971', this.applicantOtherDetails);
                this.showApplicantOtherInfo = true;
                this.applicantOtherDetails = false;
                this.applicantOtherDetails = false;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.showGSTScreen = false;
                this.showCollateral =false;
                this.showBuilderSellerDetails = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
                this.passedScreenName = 'Application Other Details'
                 this.formName = 'Application Other Details';
                 this.showIncomeEligibility= false;
                 this.showdocchecklist = false;
                  this.showDirectorsDetails = false;
            } else if (this.activeSection.name == 'Applicant Details') {
                this.applicantDetails = true;
                this.showCollateral =false;
                this.showBuilderSellerDetails = false;
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.loginChecklist=false;
                this.showApplicantOtherInfo = false;
                this.showdoc = false;
                this.showException = false;
                this.showGSTScreen = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
                this.passedScreenName = "Applicant Details";
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                 this.showDirectorsDetails = false;
                // this.formName = 'Applicant Details';
            } else if (this.activeSection.name == 'Exception Flow') {
                this.applicationDetails = true;
                this.showCollateral =false;
                this.showBuilderSellerDetails = false;
                this.rerenderCmp = false;
                this.showException = true;
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.loginChecklist=false;
                this.showApplicantOtherInfo = false;
                this.showGSTScreen = false;
            this.showITRScreen = false;
                this.showdoc = false;
                this.showIncomeAssessment = false;
                this.passedScreenName = "Exception Flow";
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                 this.showDirectorsDetails = false;
                // this.formName = 'Exception Flow';
            } else if (this.activeSection.name == 'Document details') {
                this.applicationDetails = true;
                this.showCollateral =false;
                this.showBuilderSellerDetails = false;
                this.rerenderCmp = false;
                this.showException = false;
                this.rerenderCmp = false;
                this.showdoc = true;
                this.applicantOtherDetails = false;
                this.loginChecklist=false;
                this.showApplicantOtherInfo = false;
                this.showGSTScreen = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
                this.passedScreenName = "Document details";
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                 this.showDirectorsDetails = false;
                // this.formName = 'Document details';
            }else if (this.activeSection.name == 'Document Summary') {
                console.log('At 290');
                
                this.applicationDetails = true;
                this.showCollateral =false;
                this.showBuilderSellerDetails = false;
                this.rerenderCmp = false;
                this.showException = false;
                this.rerenderCmp = false;
                this.showdocchecklist = true;
                this.applicantOtherDetails = false;
                this.loginChecklist=false;
                this.showApplicantOtherInfo = false;
                this.showGSTScreen = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
                this.passedScreenName = "Document details";
                this.showIncomeEligibility= false;
                 this.showDirectorsDetails = false;
                // this.formName = 'Document details';
            } else if(this.activeSection.name == 'Bank Statement Analysis'){
                
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.showCollateral =false;
                this.showBuilderSellerDetails = false;
                this.showApplicantOtherInfo = false;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                this.showGSTScreen = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
                this.passedScreenName = "Bank Statement Analysis";
                this.formName = 'Bank Statement Analysis';
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                 this.showDirectorsDetails = false;
                setTimeout(()=>{
                    this.showBSA = true;
                },100)
             }
             else if(this.activeSection.name == 'Financial Statement Analysis'){
                
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.showCollateral =false;
                this.showBuilderSellerDetails = false;
                this.showApplicantOtherInfo = false;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                this.showGSTScreen = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
                this.passedScreenName = "Financial Statement Analysis";
                this.formName = 'Financial Statement Analysis';
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                 this.showDirectorsDetails = false;
                setTimeout(()=>{
                    this.showBSA = true;
                },100)
                
             }
             else if(this.activeSection.name == 'GST'){
                
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.showApplicantOtherInfo = false;
                this.showCollateral =false;
                this.showBuilderSellerDetails = false;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                 this.showGSTScreen = true;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
                this.passedScreenName = "GST";
                this.formName = 'GST';
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                 this.showDirectorsDetails = false;
             }
             else if(this.activeSection.name == 'ITR'){
                
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.showApplicantOtherInfo = false;
                this.showCollateral =false;
                this.showBuilderSellerDetails = false;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                this.showGSTScreen = false;
                this.showITRScreen = true;
                this.showIncomeAssessment = false;
                this.passedScreenName = "ITR";
                this.formName = 'ITR';
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                 this.showDirectorsDetails = false;
             }
             else if(this.activeSection.name == 'Income Assessment'){
                
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.showApplicantOtherInfo = false;
                this.showCollateral =false;
                this.showBuilderSellerDetails = false;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                this.showGSTScreen = false;
                this.showITRScreen = false;
                this.showIncomeAssessment = true;
                this.passedScreenName = "Income Assessment";
                this.formName = 'Income Assessment';
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                 this.showDirectorsDetails = false;
             }
             else if(this.activeSection.name == 'PMAY Eligibility'){
                
                this.rerenderCmp = true;
                this.applicantOtherDetails = false;
                this.showApplicantOtherInfo = false;
                this.showCollateral =false;
                this.showBuilderSellerDetails = false;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                this.showGSTScreen = false;
                this.showITRScreen = false;
                this.showIncomeAssessment = false;
                this.passedScreenName = "PMAY Eligibility";
                this.formName = 'Loan Login Form';
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                 this.showDirectorsDetails = false;
             }
             else if(this.activeSection.name == 'Collateral'){
                
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.showApplicantOtherInfo = false;
                this.showCollateral =true;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                this.showGSTScreen = false;
                this.showITRScreen = false;
                this.showIncomeAssessment = false;
                this.passedScreenName = "Collateral";
                this.formName = 'Collateral';
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                 this.showDirectorsDetails = false;
             }
              else if(this.activeSection.name == 'Builder Details' || this.activeSection.name == 'Seller Details'){
                this.showBuilderSellerDetails = true;
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.showApplicantOtherInfo = false;
                this.showCollateral =false;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                 this.showGSTScreen = false;
                this.showITRScreen = false;
                this.showIncomeAssessment = false;
                this.passedScreenName = this.activeSection.name == "Builder Details" ? "Builder Details" : "Seller Details";
                this.formName = this.activeSection.name == "Builder Details" ? "Builder Details" : "Seller Details";
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                 this.showDirectorsDetails = false;
             }
             else if(this.activeSection.name == 'Income Eligibility'){
                
                this.rerenderCmp = false;
                this.applicantOtherDetails = false;
                this.showCollateral =false;
                this.showBuilderSellerDetails = false;
                this.showApplicantOtherInfo = false;
                this.loginChecklist=false;
                this.showdoc = false;
                this.showException = false;
                this.applicantDetails = false;
                this.showGSTScreen = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
                this.showBSA = false;
                this.showdocchecklist = false;
                 this.showDirectorsDetails = false;
                setTimeout(()=>{
                    this.showIncomeEligibility= true;
                },100)
                
             }
             else if(this.activeSection.name == 'Applicant Data Summary'){
                console.log('Inside 154');
               // this.showBSA = true;
                this.rerenderCmp = false;
                this.showApplicantOtherInfo = false;
                this.showdoc = false;
                this.showException = false;
                this.showCollateral =false;
                this.showBuilderSellerDetails = false;
                this.applicantDetails = false;
                this.passedScreenName = 'Login Checklist';
                 this.formName = 'Login Checklist';
                this.applicantOtherDetails = false;
                this.showdocchecklist = false;
                this.loginChecklist=true;
                this.showIncomeEligibility= false;
                this.showGSTScreen = false;
                 this.showDirectorsDetails = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
                console.log('I this.showBSA ', this.showBSA );
             }
             else if (this.activeSection.name == "Director's Details") {
                this.rerenderCmp = false;
                this.showApplicantOtherInfo = false;
                this.showdoc = false;
                this.showException = false;
                this.showCollateral =false;
                this.showBuilderSellerDetails = false;
                this.applicantDetails = false;
                this.passedScreenName = "Director's Details";
                 this.formName = 'Loan Login Form';
                this.applicantOtherDetails = false;
                this.showdocchecklist = false;
                this.loginChecklist=false;
                this.showIncomeEligibility= false;
                this.showGSTScreen = false;
                 this.showDirectorsDetails = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
             this.showDirectorsDetails = true;
            }
            
            else {
                console.log('handle accordian click else');
                this.applicantDetails = false;
                setTimeout(() => {
                    this.rerenderCmp = true;
                }, 100);
                this.applicantOtherDetails = false;
                this.loginChecklist=false;
                this.showApplicantOtherInfo = false;
                this.showdoc = false;
                this.showGSTScreen = false;
            this.showITRScreen = false;
            this.showIncomeAssessment = false;
                this.showException = false;
                this.showBSA = false;
                this.showIncomeEligibility= false;
                this.showdocchecklist = false;
                this.showDirectorsDetails = false;

            }

            console.log('revencmp in eventttt---', this.rerenderCmp);
        }, 100);
            // if(this.activeSection.name == 'Applicant Other Details') {
            //     console.log('inside app other dets');
            //     selectedStage = 'Applicant Other Details';
            // }
            
            
    }
    // get showOpenAll() {
    //     return this.checkloginchecklist.length === 0;
    // }
    // get closeall() {
    //     return this.checkloginchecklist.length > 0;
    // }
    
    handleNextApplicantOther(){
        console.log('Inside handleNextApplicantOther---');
        
    }

    handleRefreshCmpFinal(event){
        console.log('event in culprit main handleRefreshCmpFinal---',JSON.stringify(event));
        const valueSelectedEvent = new CustomEvent('refreshmenucmpfinal', {
            detail: {
                screenName: event.detail.screenName
            }
        });
        this.dispatchEvent(valueSelectedEvent);
    }

    refreshaction(event){
        console.log('Inside refresh action----', event.detail.name);
        
        const valueChangeEvent = new CustomEvent("refreshactions", {
            detail: { value: this.recordId, name: event.detail.name, currentAppSeq: '2' }
        });
        this.dispatchEvent(valueChangeEvent);
    }

}