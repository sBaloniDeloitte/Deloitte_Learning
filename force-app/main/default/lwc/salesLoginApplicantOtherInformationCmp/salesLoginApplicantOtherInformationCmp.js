import { LightningElement,api } from 'lwc';
import getSubStageList from '@salesforce/apex/COMM_SalesLoanActionsController.getSubStageList';
import getSubStageListApplicationInforamtion from '@salesforce/apex/COMM_SalesLoanActionsController.getSubStageListApplicationInforamtion';


export default class SalesLoginApplicantOtherInformationCmp extends LightningElement {
    @api recordId;
    @api passedScreenName;
    @api formName
    isRendered  = false;  
    activeSectionName;
    processedStages =[];
    subStageList =[];
    //isRendered  = false;
    nextSequence = 1;
    currentStage;
    currentStagePersonalDetails = false;
    selectedApplicantId
    selectedStageName
    rerenderCmp = false;
    actualStage=[];
    @api activeSection;

    connectedCallback(){
        //this.getApplicantList();
        
            this.getSubStageList();
            this.getSubStageListApplicationInforamtion();
        
        
    }

     getSubStageList(){
            console.log('this.passedScreenName=: 197'+this.passedScreenName)
            getSubStageList({
                loanId : this.recordId,
                applicableStage : this.passedScreenName,
                formName: this.formName
            })
            .then(response => {
                console.log('Substage response: 114', response);
                this.subStageList = response;  
                console.log('Substage response: 115', response);
                this.processedStages = this.subStageList.map((stage, index, array) => ({
                    ...stage,
                    showLine: index > 0  
                }));
                console.log('Substage response: 116', response);
                
                
            })
            .catch(error => {
                console.log('Error getting sub stage list:', JSON.stringify(error));
            });
        }


        getSubStageListApplicationInforamtion(){
            console.log('this.passedScreenName=: 65'+this.passedScreenName)
            getSubStageListApplicationInforamtion({
                loanId : this.recordId,
                applicableStage : this.passedScreenName,
                formName: this.formName
            })
            .then(response => {
                // this.rerenderCmp = true;
                console.log('Substage response: 73', JSON.stringify(response));
                this.actualStage = response;  
                console.log('Substage response: 75', response);
                this.actualStage = this.actualStage.map((stage, index, array) => ({
                    ...stage,
                    showLine: index > 0  
                }));
                setTimeout(() => {
                    for(let i =0; i<this.actualStage.length; i++){
                        if(this.actualStage[i].name === 'Additional Information'){
                            this.actualStage[i].name = 'Additional Information';
                            console.log('this.actualStage[i];---',this.actualStage[i])
                            this.activeSection = this.actualStage[i];
                            console.log('rerenderCmp--',this.rerenderCmp);
                            this.passedScreenName = this.activeSection.name;
                            console.log('this.activeSection.name 148 ',this.activeSection.name );
                            setTimeout(() => {
                                this.rerenderCmp = true;
                            }, 500);
                            break;
                        }
                    }
                }, 500);
                console.log('Substage response: 96', response);
                
                
            })
            .catch(error => {
                console.log('Error getting sub stage list:', JSON.stringify(error));
            });
        }

        handleAccordionClick(event){
            event.stopPropagation();
             console.log('name--101 other infro',event.currentTarget.name);
            const selectedStage = event.currentTarget.name;
              console.log('name--103 other infro',event.currentTarget.name);
            if (selectedStage== undefined || selectedStage == this.activeSection.name) {
                console.log('Preventing unnecessary re-render');
                return;
            }
            try{
                this.rerenderCmp = false;
                if(event.currentTarget.name=='Additional Information'){
                    selectedStage = 'Additional Information';
                }
                // console.log('name--129 other infro',event.currentTarget.name);
                
                for(let i =0; i<this.actualStage.length; i++){
                    if(this.actualStage[i].name === selectedStage){
                        this.actualStage[i].name = selectedStage;
                        this.activeSection = this.actualStage[i];
                        console.log('rerenderCmp--',this.rerenderCmp);
                        this.passedScreenName = this.activeSection.name;
                        console.log('this.activeSection.name 120 ',JSON.stringify(this.activeSection) );
                        setTimeout(() => {
                            this.rerenderCmp = true;
                        }, 1500);
                        break;
                    }
                }
            }
            catch(error){
                console.log('error 135 other=:'+error);
                console.log('error 136 other=:'+JSON.stringify(error));
            }
        }
          

        handleRefreshCmp(event){
            console.log('mil gya culprit---');
            console.log('event in culprit---',JSON.stringify(event));
            const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
                detail: {
                    loanId:event.detail.loanId,
                    screenName: event.detail.screenName
                }
            });
            this.dispatchEvent(valueSelectedEvent);
        }
         
        handleRefreshCmpFinal(event){
            console.log('event in culprit handleRefreshCmpFinal---',JSON.stringify(event));
            const valueSelectedEvent = new CustomEvent('refreshmenucmpfinal', {
                detail: {
                    screenName: event.detail.screenName
                }
            });
            this.dispatchEvent(valueSelectedEvent);
        }
           
    }