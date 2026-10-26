import { LightningElement, api, wire } from 'lwc';
import updateRemark from '@salesforce/apex/ShowRemarksController.updateRemark';
import getRemarksDetails from '@salesforce/apex/ShowRemarksController.getRemarksDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { registerListener } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation'; 

export default class ShowRemarks extends LightningElement {
                  
    @api recordId;
    @api processName ='';
    @api showHeaderFooter = false;
    @api headerText = '';
    @api allowCreation = false;
    @api showInline = false;

    newNote ='';
    existingNotes;
    notes;
    hasRemarks = false;
    cssContainer = '';
    cssContainerChild = 'cssContainer-child';
    cssMain = '';
    showExistingHeader = false;
    isDisabled = false;

    @wire(CurrentPageReference) pageRef;

    connectedCallback(){

        if(this.showHeaderFooter == true){
            this.cssMain = 'border-field';
            this.cssContainer = 'slds-modal__content slds-p-around_medium';
            this.cssContainerChild = 'cssContainer-child-no-padding';
        }
        else{
            this.showHeaderFooter = false;
        }

        if(this.processName == 'Lead Remarks') {
            this.showExistingHeader = true;
        }
        
        this.getRemarksData();

        registerListener("closeLead", this.updateleaddetails, this);
    }

    updateleaddetails(){
        this.getRemarksData();
    }

    getRemarksData() {
        getRemarksDetails({ recordId: this.recordId, processName: this.processName })
        .then(result => {
            console.log('Remarks: '+JSON.stringify(result.remarks));
            if(result) {
                this.existingNotes = result.remarks;
                console.log('Remarks: '+JSON.stringify(this.existingNotes));
                if(this.processName == 'Lead Remarks') {
                    this.allowCreation = result.allowCreation;
                }

                //Call notes history function
                this.notesHistory();
            }
        })
        .catch(error => {
            console.error('Error fetching remarks details:', error);
        });
    }

    notesHistory() {
        console.log('this.existingNotes: ' + this.existingNotes);
    
        if (this.existingNotes) {
            var hstry = [];
            var remrkHstr = this.existingNotes.split('<br>');
            
            for (var i = 0; i < remrkHstr.length; i++) {
                let rmTmp;
                let tmp;
    
                
                if (this.processName != 'FI Remarks') {
                    // Split only if processName is not 'FI Remarks'
                    rmTmp = remrkHstr[i].split('m:');
                    tmp = {
                        id: 'tr_' + i,
                        key: rmTmp[0] + 'm:',
                        value: rmTmp[1]
                    };
                } else {
                    
                    tmp = {
                        id: 'tr_' + i,
                        key: remrkHstr[i], 
                        value: ''
                    };
                }
                console.log('tmp: '+tmp);
                hstry.push(tmp);
            }
    
            this.hasRemarks = true;
            console.log('hstry: '+hstry);
            this.notes = hstry;
            console.log('this.notes: '+this.notes);
        }
    }
    

    notesEntered(event){
        this.newNote = event.target.value;
    }

    submitNotes(event){
        this.handleUpdateLead();
    }

    handleUpdateLead() {
        console.log('this.newNote update: '+this.newNote);

        if(this.newNote){

            updateRemark({ recordId: this.recordId, remark: this.newNote, processName: this.processName })
            .then(result => {
                console.log('NotePad: '+result);

                this.existingNotes = result;
                this.newNote ='';
                
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Remarks updated sucessfully',
                    variant: 'success'
                }));

                this.notesHistory();
            })
            .catch(error => {
                console.log('update Notepad error: '+JSON.stringify(error));
                
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error,
                    variant: 'error'
                }));
            });
        }
        else{
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please enter remarks.',
                variant: 'Error'
            }));
        }
    }
}