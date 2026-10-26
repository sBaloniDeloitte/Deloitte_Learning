import { LightningElement,api,wire,track } from 'lwc';
import fetchLeadDetails from '@salesforce/apex/Comm_LeadManagementController.fetchLeadDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation'; 
import { registerListener, unregisterAllListeners } from 'c/pubsub';

export default class LeadShowDialerDetails extends LightningElement {
    @track count;
    @api recordId;
    @track previouscount;
    
    showConfirmation = false;
    showDisposition = false;
    showbox = true;
    confirmMessage = 'Are you sure you want to continue or you want to close this Lead? '
    open = false;
    showClosereason = false;
    lastDisposition;
    showlastdisposition = false;
    isLoading = false;
    notes;
    hasRemarks = false;

    @wire(CurrentPageReference) pageRef;
    
    connectedCallback(){
        console.log('recordId 20'+this.recordId);
        this.getLeadDetailsData();

        registerListener("closeLead", this.updateleaddetails, this);
        registerListener("closeLeadfromedit", this.updateleaddetails, this);
    }

    disconnectedCallback() { 
        unregisterAllListeners(this); 
    }

    updateleaddetails(){
        this.getLeadDetailsData();
    }

    handleIncrement(){
        this.count = this.count +1 ;
        if((this.count > this.previouscount + 1)){
            this.count = this.previouscount;
            this.showToast('error', 'Call Count can only increase by 1 each time', 'error');
            return;
        }
        else{
            this.showbox = false;
            console.log('46 '+ this.showDisposition);
            this.showDisposition = true;
            console.log('48 '+ this.showDisposition);
        }
        
        // if(this.count == 3){
        //     this.showConfirmation = true;
        //     this.showbox = false;
        // }
        console.log('1205 count '+this.count);
    }

    notesHistory(){
        console.log('this.existingNotes: '+this.existingNotes);

        if(this.existingNotes){
            var hstry =[];
            var remrkHstr = this.existingNotes.split('<br>');
            //console.log('remrkHstr.length --> '+remrkHstr);
    
            for(var i=0; i< remrkHstr.length; i++){
                var rmTmp = remrkHstr[i].split('m:');
                const tmp = {
                    id: 'tr_'+i,
                    key: rmTmp[0] +'m:',
                    value: rmTmp[1]
                };
                
                hstry.push(tmp);
            }

            this.hasRemarks = true;

            this.notes = hstry;
            console.log('this.notes-->',this.notes);
        }
    }

    getLeadDetailsData(){
        console.log('88 '+this.recordId);

        fetchLeadDetails({ leadId : this.recordId, processName: 'DialerRemarks' })
        .then(result => {
            console.log('DialerRemarks: '+ result);

            if(result) {
                this.existingNotes = result[0].Dialer_History__c; 
                this.previouscount = this.count = result[0].Call_Count__c;
    
                if(this.count > 0){
                    this.showlastdisposition = true;
                    this.lastDisposition = result[0].Dialer_Disposition__c;
                }
                
                if(result[0].Status == 'Open'){
                    this.open = true;
                }
                else{
                    this.open = false;
                }
    
                console.log('open '+this.open);
                console.log('count '+this.count);
                this.notesHistory();
            }
        })
        .catch(error=>{
            console.log('error=: '+error);
            console.log('error=: '+JSON.stringify(error));
        }); 
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });

        this.dispatchEvent(toastEvent);
    }

    handleYes(event){
        this.showConfirmation = false;
        this.showbox = true;
    }

    handleNo(event){
        this.isLoading = true;
        this.showConfirmation = false;
        this.showbox = true;
        this.isLoading = false;
        this.showClosereason = true;
    }

    handleClose(event){
        console.log('128');
        this.showClosereason = false;
        this.showDisposition = false;
        this.connectedCallback();
    }
}