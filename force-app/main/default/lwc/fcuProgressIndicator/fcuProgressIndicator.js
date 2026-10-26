import { LightningElement,api,track,wire } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';

import setFCUProgress from '@salesforce/apex/FCURecordPageController.setFCUProgress';
import checkIfParentRec from '@salesforce/apex/FCUController.checkIfParentRec';


export default class FcuProgressIndicator extends LightningElement {
    @api recordId
    isLoaded = false;
    @track isParent = false;
    @track progressStep;//={"isApproved":false,"isSubmitted":false,"isDetailPresent":false}

    @wire(CurrentPageReference) pageRef;

    connectedCallback(){
        this.checkIfParentRec();
        this.setStepProgress();
        this.handlePubSub();
    }
    
    checkIfParentRec(){
        checkIfParentRec({
            recId:this.recordId
        }).then(response =>{
            this.isParent = response;
        }).catch(error=>{

        })
    }
    setStepProgress(){
        setFCUProgress({recordId : this.recordId}).then(response=>{
            console.log('parent-->',this.isParent);
            this.progressStep = response
            this.isLoaded = true;
            console.log(this.progressStep.isSubmitted);
            if(this.progressStep.isSubmitted){
                console.log(this.progressStep.isSubmitted);
                fireEvent(this.pageRef, "fcuEnableViewReport", "fcuEnableViewReport");
            }
            if(this.progressStep.isApproved){
                console.log(this.progressStep.isApproved);
                fireEvent(this.pageRef, "fcuApproved", "fcuApproved");
            }
        }).catch(error=>{
            console.error('The Error is '+JSON.stringify(error))
        })
    }

    get isMobile(){
        return FORM_FACTOR == 'Large' ? 'line slds-align_absolute-center' : 'linemobile slds-align_absolute-center'
    }

    handlePubSub(){
        registerListener("fcuDetailCheck",this.handleDetailCheck, this);
        registerListener("fcuSubmitted",this.handleSubmitCheck, this);
        registerListener("fcuApproved",this.handleApprovedCheck, this);
    }

    handleFCUSubmission(){
        // this.progressStep.isSubmitted = true
        if(this.progressStep.isSubmitted){
            console.log(this.progressStep.isSubmitted);
            fireEvent(this.pageRef, "fcuEnableViewReport", "fcuEnableViewReport");
        }
    }

    handleDetailCheck(){
        this.setStepProgress()
    }

    handleSubmitCheck(){
        this.setStepProgress();
        this.handleFCUSubmission();
    }

    handleApprovedCheck(){
        this.setStepProgress(); 
    }

    disconnectedCallback() { 
        unregisterAllListeners(this); 
    }

}