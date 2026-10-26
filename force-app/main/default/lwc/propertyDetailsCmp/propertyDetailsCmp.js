import { LightningElement,api,track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import getAllPropertyDetails from '@salesforce/apex/PropertyDetailsController.getAllPropertyDetails';
export default class PropertyDetailsCmp extends LightningElement {
    @api recordId;
    @track collaterals=[];
    @track isCollateralPresent = false;
    connectedCallback() {
        this.getCollateral();
    }

    getCollateral() {
        getAllPropertyDetails({ loanId: this.recordId })
        .then(result => {
          console.log('Result1', result);
          if(result.length > 0) {
            this.collaterals = result;
            this.isCollateralPresent = true;
          }else {
            this.isCollateralPresent = false;
          }
        })
        .catch(error => {
          console.error('Error:', error);
      });
    }

}