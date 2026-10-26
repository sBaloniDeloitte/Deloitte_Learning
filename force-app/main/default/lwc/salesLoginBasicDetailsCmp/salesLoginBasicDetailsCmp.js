import { LightningElement,api} from 'lwc';
import getSubStageList from '@salesforce/apex/COMM_SalesLoanActionsController.getSubStageList'

export default class SalesLoginBasicDetailsCmp extends LightningElement {
    @api recordId;
    showBasicDetails= false;
    selectedRecordId;
    @api applicantId;
    @api activeSection;
    @api currentAppSeq;
    loanId;
    passedScreenName = 'Applicant Information';
    isloading = false;
    connectedCallback() {
        try{
            console.log('recordId=:'+this.recordId);
            console.log('selectedRecordId=:'+this.selectedRecordId);
            console.log('applicantId=:'+this.applicantId);
            console.log('activeSection=:'+this.activeSection);
            console.log('currentAppSeq=:19'+this.currentAppSeq)
            this.showBasicDetails = true;
            console.log('inside cmp');
            this.getSubStageList();
        }
        catch(error){
            console.log('error=:'+error);
        }
        this.isloading = true;
        setTimeout(() => {
        this.isloading = false;
        }, 2000); 
    }
     getSubStageList(){
        console.log('Substage response:177');
        getSubStageList({
            loanId : this.recordId,
            applicableStage : this.passedScreenName
        })
        .then(response => {
            this.rerenderCmp = true;
            console.log('Substage response:177', response);
            this.stages = response;
            
                // this.activeSection = this.stages[0];
                console.log('Substage response:181s',   this.activeSection );
            
        })
        .catch(error => {
            console.log('Error getting sub stage list:', JSON.stringify(error));
        });
    }
    handleOpenNextScreen(event){
        const valueSelectedEvent = new CustomEvent('opennextscreen', { detail: {screenName:event.detail.screenName} });
        this.dispatchEvent(valueSelectedEvent);
    }
}