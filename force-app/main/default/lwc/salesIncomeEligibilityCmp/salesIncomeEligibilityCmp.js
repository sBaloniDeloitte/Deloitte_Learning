import { LightningElement,api } from 'lwc';
import getSubStageListSubAccordian from '@salesforce/apex/COMM_SalesLoanActionsController.getSubStageListSubAccordian';

export default class SalesIncomeEligibilityCmp extends LightningElement {
    @api recordId;
    @api activeSection;
    currentSection;
    @api passedScreenName 
    @api formName ;
    @api loginChecklist;
    isRendered = false;
    stages = [];
    rerenderCmp ;
    isloading = false;
    connectedCallback(){
        console.log('this.recordId- Income cmp-->' + this.recordId);
        console.log('this.passedScreenName--->' + this.passedScreenName);
        console.log('this.formanmae Income--->' + this.formName);
        console.log('loginChecklist in income----', this.loginChecklist);
        
        console.log('this.activeSection--->' + JSON.stringify(this.activeSection));
        this.rerenderCmp = false;
        this.getSubStageListSubAccordian();
        setTimeout(() => {
            
        }, 100)
       
        this.isloading = true;
        setTimeout(() => {
        this.isloading = false;
        }, 2000);
        // if(this.activeSection =='Bank Statement Analysis' && !this.rerenderCmp ){
        //     this.rerenderCmp= true;
        // }
    }
    getSubStageListSubAccordian(){
        console.log('Inside getSub again',this.formName);
        getSubStageListSubAccordian({
            loanId : this.recordId,
            applicableStage : this.passedScreenName,
            formName : this.formName
        })
        .then(response => {
            this.rerenderCmp = false;
            console.log('Substage response:27---', response);
            this.stages = response;
            console.log('Substage  this.stages: 30',  this.stages); 
            console.log('39----',JSON.stringify(this.activeSection));
            if(this.activeSection!='' && this.activeSection!=null  && this.activeSection!=undefined){
                console.log('Substage  this.stages: 40',  this.stages);
                for(let i =0; i<this.stages.length; i++){
                    if(this.stages[i].name === this.activeSection.name){
                        this.activeSection=this.stages[i] ; 
                        this.currentSection = this.stages[i].name;
                        this.passedScreenName = this.stages[i].name;
                        this.rerenderCmp = true;
                    }
                }
            }else{
                console.log('Substage  this.stages: 52',  this.stages);
                this.rerenderCmp = true;
                this.currentSection = this.stages[0].name;
                this.activeSection = this.stages[0];
               // this.passedScreenName = 'Bank Statement Analysis'
            }
            
            
        })
        .catch(error => {
            console.log('Error getting sub stage list:', JSON.stringify(error));
        });
    }
    
    handleAccordionClick(event) {
        event.stopPropagation();
        if(event.target.name != undefined){
            this.rerenderCmp = false;
            const selectedStage = event.target.name;
            console.log('selectedStage',selectedStage)
            // console.log('stages--',JSON.stringify(this.stages));
            // for(let i =0; i<this.stages.length; i++){
            //     if(this.stages[i].name == selectedStage){
            //         this.activeSection=this.stages[i] ; 
            //         this.currentSection = this.stages[i].name;
            //         this.passedScreenName = this.stages[i].name;
            //         this.rerenderCmp = true;
            //         break;
            //     }
            // }
            if (this.activeSection.name !== selectedStage) {
                for(let i =0; i<this.stages.length; i++){
                    if(this.stages[i].name === selectedStage){
                        this.stages[i].name = selectedStage;
                        this.activeSection = this.stages[i];
                        this.currentSection = this.stages[i].name;
                        this.passedScreenName= this.stages[i].name;
                        this.rerenderCmp = false;
                        console.log('rerenderCmp--',this.rerenderCmp);
                        setTimeout(() => {
                            this.rerenderCmp = true;
                        }, 10);
                        break;
                    }
                }
                console.log('passedScreenName--',this.passedScreenName);
                console.log('passedScreenName--',this.activeSection);
                console.log('activeSection--',this.activeSection.name);
            }
            //  if(selectedStage== 'Financial Statement Analysis'){
            //     this.passedScreenName = "Financial Statement Analysis";
            //     this.formName = 'Financial Statement Analysis';
            //     setTimeout(() => {
            //     this.getSubStageListSubAccordian();
            //     },100);
            //  }
        }
        
    }
    handleKeepAccordionOpen(event){
        console.log('this.currentSection=:'+this.currentSection);
        // setTimeout(()=>{
        //     this.rerenderCmp = true;
        // },200)
        // this.activeSection = this.currentSection;
    }   

    handleStopPropogation(event){
        event.stopPropagation();
    }
    
    handleRefreshCmp(event) {
        console.log('inside handleRefreshCmp event.detail.loanId=: in main');
        
        // this.recordId = event.detail.loanId;
        // this.template.querySelector('c-sales-login-action-flow-cmp').changeMessage(event);
        const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
            detail: {
                loanId:loanId,
                screenName: event.detail.screenName
            }
        });
        this.dispatchEvent(valueSelectedEvent);
    }
}