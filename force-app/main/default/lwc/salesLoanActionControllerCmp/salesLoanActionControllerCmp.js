import { LightningElement,api,track,wire } from 'lwc';
import { fireEvent } from 'c/pubsub'; 
import { NavigationMixin } from "lightning/navigation";
import { CurrentPageReference } from 'lightning/navigation'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { registerListener, unregisterAllListeners } from 'c/pubsub';

import getActionList from '@salesforce/apex/COMM_SalesLoanActionsController.getActionList';
import getCompletionStatus from '@salesforce/apex/LoanActionController.getCompletionStatus';
import changeLoanStage from '@salesforce/apex/LoanActionController.changeLoanStage';

export default class SalesLoanActionControllerCmp extends LightningElement {
     @api recordId;
        @wire(CurrentPageReference) pageRef; 
        @api loanid;
        
        isRendered = false;
    
        @track actionList;
        @track showcmp;
        @track coApplicantAdded;
        @track assetAdded;
        @track bankAdded;
        @track imdCollected;
        @track showAppScore=false;
        @track showCoApp = false;
        @track allcommplete=false;
        @track openConfirm = false;
        
        @api changeMessage(str) {
            console.log('Inside LoanLoginActionFlowCmp Refresh');
            this.getActions();
            //this.getActionStatus();
        }
        @api highlightScreen(str) {
            console.log('str=:'+str);
            console.log('Inside Highlight login');
            console.log('this.actionList=:39'+JSON.stringify(this.actionList));
            this.getActions();
            setTimeout(()=>{
                this.actionList.forEach(item => {
                    if(item.name == str){
                        item.isActive = true;
                    }
                    else{
                        item.isActive = false;
                    }
                });
            },1500)
            // this.getActionStatus();
        }
            
        renderedCallback(){
            console.log('recordId --> '+ this.recordId);
            console.log('IN CHILD RENDER CALL BACK');
            if(!this.isRendered){
                console.log('Inside if condition');
                this.isRendered = true;
                const style = document.createElement('style');
                style.innerText = `
                .uploadFile .slds-path__item:before, 
                .slds-path__item:after {
                    left: 1.125rem;
                    background:#9bbf56 ;
                }
                .disableFile .slds-path__item:before, 
                .slds-path__item:after {
                    left: 1.125rem;
                    background:lightgray ;
                }
                .activeBtn .slds-path__item:before, 
                .slds-path__item:after {
                    left: 1.125rem;
                    background: #dc387e;
                }
                .normalFile.slds-path__item:before, 
                .slds-path__item:after {
                    left: 1.125rem;
                    background:white ;
                }
                .uploadFile .slds-button {
                    // color: white;
                    // background: green;
                    // border-color: black;
                    width: 75%;
                    // font-size: smaller;
                    // padding: 0px 8px; /* Adjust padding as needed */
                    // display: inline-block;
                    text-align: center;
                    // border-radius: 20px; /* Adjust border-radius to control the button's curvature */
                    background-color:#9bbf56 ;
                    color: white;
                    font-size: 13px;
                    font-weight: bold;
                    align-content: center;
                    cursor: pointer; /* Cursor style */
                    transition: background-color 0.3s ease; /* Smooth transition effect */
                    box-shadow: 0 7px 5px rgba(0, 0, 0, 0.4);
                    --slds-c-button-brand-color-background-hover: #ee6421;
                }
                    .disableFile .slds-button {
                    // color: white;
                    // background: green;
                    // border-color: black;
                    width: 75%;
                    // font-size: smaller;
                    // padding: 0px 8px; /* Adjust padding as needed */
                    // display: inline-block;
                    text-align: center;
                    // border-radius: 20px; /* Adjust border-radius to control the button's curvature */
                    background-color:lightgray ;
                    color: #113451;
                    font-size: 13px;
                    font-weight: bold;
                    align-content: center;
                    cursor: pointer; /* Cursor style */
                    transition: background-color 0.3s ease; /* Smooth transition effect */
                    box-shadow: 0 7px 5px rgba(0, 0, 0, 0.4);
                    --slds-c-button-brand-color-background-hover: #ee6421;
                }
                .normalFile .slds-button {
                    // color: black;
                    // background: white;
                    // border-color: black;
                    width: 75%;
                    padding: 0px 8px; /* Adjust padding as needed */
                    display: inline-block;
                    text-align: center;
                    // border-radius: 20px; /* Adjust border-radius to control the button's curvature */
                    background-color:white ;
                    color: #113451;
                    font-size: 13px;
                    font-weight: bold;
                    align-content: center;
                    cursor: pointer; /* Cursor style */
                    transition: background-color 0.3s ease; /* Smooth transition effect */
                    box-shadow: 0 7px 5px rgba(0, 0, 0, 0.4);
                  }
                    .activeBtn .slds-button {
                        background-color: #dc387e;
                        width: 77%;
                        height:40px;
                        color: white;
                        display: inline-block;
                        font-size: 13px;
                        font-weight: bold;
                        text-align: center;
                        align-content: center;
                        text-decoration: none;
                        transition-duration: 0.2s;
                        cursor: pointer;
                        transition: background-color 0.3s ease; /* Smooth transition effect */
                        box-shadow: 0 7px 5px rgba(0, 0, 0, 0.4);
                        --slds-c-button-brand-color-background-hover: #ee6421;
                    }
                .labelFontClass .slds-form-element__label{
                    font-size:large;
                }
                `;
                this.template.querySelector('.styleContainer').appendChild(style);
            }
        }
    
        connectedCallback(){
            console.log('this.loanid --> loan action flow'+ this.loanid);
            console.log('this.recordId -->'+ this.recordId);
    
            if(this.recordId != undefined){
                this.showcmp = true;
                this.loanid=this.recordId;
            }
    
            console.log('Inside LoanLoginActionFlowCmp');
    
            this.getActions();
            this.getActionStatus();
            setTimeout(()=>{
                this.actionList.forEach(item => {
                    if(item.name == this.applicableStage){
                        item.isActive = true;
                    }
                    else{
                        item.isActive = false;
                    }
                });
            },1500)
           
        }
    
        getActions(){
            console.log('this.recordId -->'+this.recordId);
            getActionList({
                loanId : this.loanid
            }).then(response=>{
                console.log('response(getAction) for Login button -->'+JSON.stringify(response));
                this.actionList = response;
                this.actionList.forEach(item => {
                    if (item.name == 'Income Eligibility') {
                        item.name = 'Eligibility';
                    }
                });
                console.log('response(getAction) for Login button -->'+JSON.stringify(this.actionList));
                // if(response != undefined && response.length>0){
                //     this.allcommplete = response[0].isAllComplete;
                // }
                this.showcmp = true;
            }).catch(error=>{
    
            })
        }
        getActionStatus(){
            console.log('this.recordId=:'+this.recordId);
            getCompletionStatus({
                loanId : this.loanid
            }).then(response=>{
                console.log('response=:'+JSON.stringify(response));
                if(response.coApplicantAdded){
                    this.coApplicantAdded = 'font-size: 20px;color: green;'
                }
                else{
                    this.coApplicantAdded = 'font-size: 20px;color: green;'
                }
    
                if(response.imdCollected){
                    this.imdCollected = 'font-size: 20px;color: green;'
                }
                else{
                    this.imdCollected = 'font-size: 20px;color: green;'
                }
    
                if(response.bankAdded){
                    this.bankAdded = 'font-size: 20px;color: green;'
                }
                else{
                    this.bankAdded = 'font-size: 20px;color: green;'
                }
    
                if(response.assetAdded){
                    this.assetAdded = 'font-size: 20px;color: green;'
                }
                else{
                    this.assetAdded = 'font-size: 20px;color: green;'
                }
            }).catch(error=>{
    
            })
        }
        handleClick(event){
            console.log('event.currentTarget.dataset.id --> '+event.currentTarget.dataset.id);
            const value = '';
            this.actionList.forEach(item => {
                if(item.name == event.currentTarget.dataset.id){
                    item.isActive = true;
                }
                else{
                    item.isActive = false;
                }
               
            });
            const name = event.currentTarget.dataset.id;
            const valueChangeEvent = new CustomEvent("valuechange", {
                detail: { value,name }
            });
        this.dispatchEvent(valueChangeEvent);
    }
    loginLoan(){
        this.openConfirm=true;
        const scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
    }

    // handleYes(){
    //     console.log('this.loanid --> '+this.loanid);
    //     changeLoanStage({
    //         loanid : this.loanid
    //     }).then(response=>{
    //         this[NavigationMixin.Navigate]({
    //             type: 'standard__recordPage',
    //             attributes: {
    //                 recordId: this.loanid,
    //                 actionName: 'view' // Use 'view' for viewing the record
    //             }
    //         });
    //     }).catch(error=>{
    //         console.log('error login Loan Handle Yes - > '+JSON.stringify(error));
    //         console.error('error login Loan Handle Yes - > '+JSON.stringify(error));
    //     })
    // }

    handleCancel(){
        this.openConfirm=false;
    }

    hideDiscrepancyBox(){
        this.openConfirm=false;
    }

    handlecloseovd(){
        this.openOVDCmp= false;
        this.showcmp = true;
    }

}