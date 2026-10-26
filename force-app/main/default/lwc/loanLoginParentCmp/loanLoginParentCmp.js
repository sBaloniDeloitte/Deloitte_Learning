import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated';

const FIELDS = ['Opportunity.Is_Top_Up__c'];

export default class LoanLoginParentCmp extends LightningElement {
    @api recordId;
    @api screenName;
    @track showTopUpModal = false;
    callApplicantScreen = true;
    nextScreenName= '';
    // form-name required by c-sales-login-applicant-information-cmp (previously supplied
    // by SalesLoginActionFlowCmp's own "formName" field when it hosted that component).
    formName = 'Loan Login Form';
    //HL-Ishi-31/10
    isHLUser;
    topUp
    //HL-Ishi-31/10
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredOpportunity({ data, error }) {
        if (data) {
            this.topUp = data.fields.Is_Top_Up__c.value;
         
            
        } else if (error) {
            console.error('Error fetching Is_Top_Up__c:', error);
        }
    }

    connectedCallback(){
        try{
            this.checkIfLoggedInUserIsHLRelated();
            
            console.log('this.recordId -->'+ this.recordId);
            console.log('this 7 -->',this.showTopUpModal);
        }catch(e){
            Console.log('Exception in connectedcallback: '+e);
        }
    }
    handleValueChange(event) {
        try{
            console.log('event name in value change', event.detail.name);
    
            if (event.detail.name === 'Applicant Information') {
                console.log('Inside Applicant');
                this.callApplicantScreen = true;
        
                // // Ensure the component exists before calling changeMessage
                // Promise.resolve().then(() => {
                //     const applicantCmp = this.template.querySelector('c-sales-login-applicant-information-cmp');
                //     if (applicantCmp) {
                //         applicantCmp.changeMessage(event);
                //     }
                // });
        
            } else {
                this.callApplicantScreen = false;
        
                // Ensure the component exists before calling changeMessage
                Promise.resolve().then(() => {
                    const genericCmp = this.template.querySelector('c-sales-loan-login-main-cmp');
                    if (genericCmp) {
                        genericCmp.changeMessage(event);
                    }
                });
            }
        }
        catch(error){
            console.log('error parent 40 =:'+error);
        }
        
    }
    
    // handleValueChange(event){
    //     console.log('event',event.detail.name)
    //     if(event.detail.name == 'Applicant Information'){
    //        console.log('Inside Applicant');
    //         this.template.querySelector('c-sales-login-applicant-information-cmp').changeMessage(event);
    //         this.callApplicantScreen = true;
           
    //     }else{
    //         this.callApplicantScreen = false;
    //         this.template.querySelector('c-sales-loan-login-generic-screen-cmp').changeMessage(event);
    //     }
            
       
    // }
    renderedCallback() {
        console.log('in parent rendered callback');
        
        // this.template.querySelector("c-sales-login-action-flow-cmp").changeMessage(this.nextScreenName);
    }

    // No top-level journey/action-flow component is hosted here anymore - the journey
    // panel already lives inside c-sales-loan-login-main-cmp (its own side column) and
    // inside c-sales-login-applicant-information-cmp (its own onvaluechange wiring), so
    // this helper routes a stage name directly to whichever of those two is the active
    // screen, mirroring handleValueChange's own routing logic.
    callActiveScreen(stageName) {
        if (!stageName) {
            return;
        }
        if (stageName === 'Applicant Information') {
            this.callApplicantScreen = true;
            return;
        }
        this.callApplicantScreen = false;
        Promise.resolve().then(() => {
            const genericCmp = this.template.querySelector('c-sales-loan-login-main-cmp');
            if (genericCmp) {
                genericCmp.changeMessage({ detail: { name: stageName } });
            }
        });
    }

    handleRefreshCmp(event){
        this.recordId = event.detail.loanId;
        // if(event.detail.screenName== 'Loan Details---', event.detail.screenName== 'Loan Details'){
        //     console.log('event.detail.loanId scrennnnName', event.detail.screenName);
        
        // }
        console.log('event.detail.loanId scrennnnName', event.detail.screenName);
        this.nextScreenName= event.detail.screenName;
        console.log('event.detail.loanId nextScreenName', this.nextScreenName);
        this.callActiveScreen(this.nextScreenName);
    }
    handleSubProductChange(event){
        console.log('inside handle subProduct>');
        console.log('event.detail.subProduct---', event.detail.subProductName);
        const stageName = event.detail.subProductName == 'HL Builder Purchase' ? 'Builder Details' : 'Seller Details';
        this.callActiveScreen(stageName);
    }
    handleHighLightScreen(event){
        this.screenName = event.detail.screenName;
        console.log(' parent this.screenName ---', this.screenName )
        // No standalone journey component to highlight against anymore - the currently
        // active screen already reflects this.screenName via callActiveScreen/handleValueChange.
        console.log(' this.screenName ---', this.screenName )
    }

    navigateNext(event){
        console.log('inside parent event----', event.detail);
        this.callActiveScreen(event.detail);
    }

    handleRefreshCmpFinal(event){
        console.log('event in culprit main handleRefreshCmpFinal---',JSON.stringify(event));
        this.screenName = event.detail.screenName;
        console.log(' parent this.screenName ---', this.screenName );
        this.callActiveScreen(this.screenName);
    }

    refreshaction(event){
        const sectionName= event.detail.name;
        console.log('Inside refresh action----', event.detail.name);
        
        Promise.resolve().then(() => {
            const genericCmp = this.template.querySelector('c-sales-loan-login-main-cmp');
            if (genericCmp) {
                genericCmp.getSubStageList();
            }
        });
    }

        //HL-Ishi-31/10/2025
        checkIfLoggedInUserIsHLRelated(){
            checkIfLoggedInUserIsHLRelated()
            .then(result => {
                this.isHLUser = result.isHLRelated;
                console.log('isHLUser-->',this.isHLUser);
                  if(this.isHLUser){
                    this.showTopUpModal=false;
                this.callApplicantScreen=true;
                }
                else{
                    this.showTopUpModal = false; // (this.topUp != null && this.topUp != '') ? false : true;
                }
                    
            })
            .catch(error => {
                console.log('error-->',error);
            })
        }
       //HL-Ishi-31/10/2025

}