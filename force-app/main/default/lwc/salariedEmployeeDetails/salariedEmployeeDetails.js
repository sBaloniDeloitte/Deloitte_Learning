import { LightningElement, api, wire } from 'lwc';
import fetchApplicantsByProfile from '@salesforce/apex/AHL_ApplicantListController.fetchApplicantsByProfile';

export default class salariedEmployeeDetails extends LightningElement {
  @api recordId;
  applicants;
  error;

  @wire(fetchApplicantsByProfile, { loanAppId: '$recordId' })
  wiredApps({ error, data }) {
    if (data) {
      this.applicants = data.map(a => ({
      ...a,
      employerName: a?.Employer_Name__r?.Employer_Name__c || ''}));
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.applicants = undefined;
    }
  }

  get noData() {
    return Array.isArray(this.applicants) && this.applicants.length === 0;
  }
}