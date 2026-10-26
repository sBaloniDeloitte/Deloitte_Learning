import { LightningElement, api, track } from 'lwc'; 
import getRecommendations from '@salesforce/apex/HL_GetRecommendation.getRecommendations';
import sendLoanApplication from '@salesforce/apex/loanApplicationCallout.sendLoanApplication';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class CheckColendingStatus extends LightningElement {
    @api recordId;
    @track apiData;
   @track recommendationLines = [];
   @track alternativeLine;
    @track recommendationTitle;
      @track spinnerRun = false;
    partnerBankOptions = [
        { label: 'ICICI Private LTD', value: 'ICICI Private ltd' },
        { label: 'South Indian Bank', value: 'South Indian Bank' },
        { label: 'Bajaj finance ltd', value: 'Bajaj finance ltd' },
    ];

    handlePartnerBankChange(event) {
        this.selectedPartnerBank = event.detail.value;
    }

    handleSendToColending() {
        // Use this.selectedPartnerBank along with apiData
        sendLoanApplication({ opportunityId: this.recordId , partnerBank: this.selectedPartnerBank })
            .then(result => {
                console.log('sent to Co-lending:', result);
            if(JSON.parse(result).statusCode == 400 || JSON.parse(result).statusCode == 500){
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Error : '+JSON.parse(result).message,
                    variant: 'Error',
                }));
            }else{
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Application Sent to Co-lending Partner',
                    variant: 'Success',
                }));
            }
        this.dispatchEvent(new CustomEvent('closemodal'));
        this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                System.debug('The following exception has occurred: ' + e.getMessage() + ' Error :' + e.getStackTraceString());
                console.error('Error:', error);
                  this.dispatchEvent(new CustomEvent('closemodal'));
        this.dispatchEvent(new CloseActionScreenEvent());
            });
        console.log('Sending recommendation to:', this.selectedPartnerBank);
    }

    handleClick() {
        this.spinnerRun = true;
        console.log(this.spinnerRun)
        getRecommendations({ opportunityId: this.recordId })
            .then(result => {
                console.log('Raw Apex result:', result);
                 this.spinnerRun = false;
                // If Apex returns a JSON string, parse it
                this.apiData = typeof result === 'string' ? JSON.parse(result) : result;

                console.log('Parsed apiData:', this.apiData);
                // Split recommendation into lines by \n
                if (this.apiData.recommendation) {
                    const lines = this.apiData.recommendation
                        .split('\n')
                        .map(line => line.trim())
                        .filter(line => line.length > 0);

                    // First line is the title
                    this.recommendationTitle = lines.shift();

                    // Last line is the alternative
                    this.alternativeLine = lines.pop();

                    // Remaining lines are the main recommendations
                    this.recommendationLines = lines;
                }
            })
            .catch(error => {
                console.error('Error:', error);
            });
    }
}