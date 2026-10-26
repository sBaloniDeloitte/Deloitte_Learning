import { LightningElement, api, wire } from 'lwc';
import getSepSenpApplicants from '@salesforce/apex/AHL_ApplicantListController.getSepSenpApplicants';

export default class selfEmployedDetails extends LightningElement {
  @api recordId;      // Loan Application Id
  applicants;
  error = false;

  @wire(getSepSenpApplicants, { loanApplicationId: '$recordId' })
  wiredApps({ error, data }) {
    if (data) {
      this.applicants = data;
      this.error = data.length === 0;
    } else if (error) {
      this.error = true;
      this.applicants = undefined;
    }
  }
}