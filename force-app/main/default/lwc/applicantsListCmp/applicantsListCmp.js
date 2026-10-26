/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getApplicants from '@salesforce/apex/ApplicantsListController.getApplicants';

export default class ApplicantsListCmp extends NavigationMixin(LightningElement) {
    @api recordId;

    applicants = [];
    error;

    @wire(getApplicants, { loanApplicationId: '$recordId' })
    wiredApplicants({ data, error }) {
        if (data) {
            this.applicants = data.map((row) => ({
                Id: row.Id,
                Name: row.Name,
                applicantType: row.Applicant_Type__c,
                mobileNumber: row.Mobile_Number__c,
                customerProfile: row.Customer_Profile__c,
                cibilScore: row.CIBIL_Score__c,
                isKeyApplicant: row.Is_Key_Applicant__c
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.applicants = [];
        }
    }

    get applicantCount() {
        return this.applicants.length;
    }

    get hasApplicants() {
        return this.applicants.length > 0;
    }

    handleNameClick(event) {
        event.preventDefault();
        const applicantId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: applicantId,
                objectApiName: 'Application_Applicant__c',
                actionName: 'view'
            }
        });
    }
}
/*__________________________GenAI: Generated code ends here______________________________*/