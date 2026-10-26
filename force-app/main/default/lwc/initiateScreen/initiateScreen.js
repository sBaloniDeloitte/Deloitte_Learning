import { LightningElement, api, track } from "lwc";
import getCurrentLoanActions from "@salesforce/apex/InitiateScreenController.getCurrentLoanActions";
import isHunterInitiated from "@salesforce/apex/InitiateScreenController.isHunterInitiated";
import isFCUInitiated from "@salesforce/apex/InitiateScreenController.isFCUInitiated";

export default class InitiateScreen extends LightningElement {
  @api recordId;
  @track spinnerRun = false;

  //action handle flags

  @track initiateHunterAction = false;
  @track initiateFCUAction = false;
  @track confirmDocumentAction = false;
  @track initiateFIAction = false;
  //@track initiateHunterAction = false;
  //

  //status of actions
  @track isHunterInitiated = false;
  @track isFCUInitiated = false;

  initiateFICmp = false;
  initiateFCUCmp = false;
  initiateHunterCmp = false;
  generateSanctionLetter = false;
  openGenerateSanctionLetter = false;

  connectedCallback() {
    this.spinnerRun = true;
    getCurrentLoanActions({
      recordId: this.recordId,
    })
      .then((response) => {
        console.log(`The response are: ${JSON.stringify(response)}`);
        response.forEach((button) => {
          console.log(button);
          if (button == "Initiate Hunter") {
            this.initiateHunterAction = true;
            this.checkHunter();
          } else if (button == "Initiate FCU") {
            this.initiateFCUAction = true;
            this.checkFCU();  
          } else if (button == "Confirm Documents") {
            this.confirmDocumentAction = true;
          } else if (button == "Initiate FI") {
            this.initiateFIAction = true;
          }else if (button == "Generate Sanction Letter") {
            this.generateSanctionLetter = true;
          }
        });

        this.spinnerRun = false;
      })
      .catch((error) => {
        this.spinnerRun = false;
        console.error("Error loanstage -->" + JSON.stringify(error));
      });
  }

  checkHunter() {
    isHunterInitiated({
      recordId: this.recordId,
    })
      .then((response) => {
        console.log(`Hunter : ${JSON.stringify(response)}`);
        this.isHunterInitiated = response;
        //this.spinnerRun = false;
      })
      .catch((error) => {
        //this.spinnerRun = false;
        console.error("Error loanstage -->" + JSON.stringify(error));
      });
  }
  checkFCU() {
    isFCUInitiated({
      recordId: this.recordId,
    })
      .then((response) => {
        console.log(`FCU we check : ${JSON.stringify(response)}`);
        this.isFCUInitiated = response;
        console.log('fcu flag is updated?');
        //this.spinnerRun = false;
      })
      .catch((error) => {
        //this.spinnerRun = false;
        console.error("Error loanstage -->" + JSON.stringify(error));
      });
  }

  openModal() {
    this.initiateFICmp = true;
  }

  handleClose() {
    this.initiateFICmp = false;
  }
  openFCUModal() {
    this.initiateFCUCmp = true;
  }
  handleFCUClose() {
    this.initiateFCUCmp = false;
  }
  openHunterModal() {
    this.initiateHunterCmp = true;
  }
  openGenerateSanctionLetterCmp() {
    window.open(`/apex/GenerateSanctionLetter?id=${this.recordId}`, '_blank');
  }
  handleHunterClose() {
    this.initiateHunterCmp = false;
  }
}