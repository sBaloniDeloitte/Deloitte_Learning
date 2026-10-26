import { LightningElement, wire, api } from 'lwc';
import getAllApplicants from '@salesforce/apex/Sales_FetchIntegartionDetails.getAllApplicants';
import getApplicantsIntegrationInfo from '@salesforce/apex/Sales_FetchIntegartionDetails.getApplicantsIntegrationInfo';
export default class SalesLoginIntegrationDetails extends LightningElement {
    @api recordId;
    applicantOptions = [];
    selctedCustomer;
    tableData = [];
    disableTable = false;

    @wire(getAllApplicants, { loanId: '$recordId' })
    wiredApplicants({ error, data }) {
        if (data) {
            this.applicantOptions = data.customerPickList.map(app => ({
                label: app.label,
                value: app.value
            }));
            console.log('applicantOptions:'+ JSON.stringify(this.applicantOptions));
            if (this.applicantOptions.length > 0) {
                this.selectedCustomer = this.applicantOptions[0].value;
                this.selctedCustomer = this.applicantOptions[0].value;
                console.log('Default Applicant Selected:'+ this.selectedCustomer);
                this.fetchIntegrationDetails();
            }
        } else if (error) {
            console.error('Error fetching applicants:', error);
        }
    }

    fetchIntegrationDetails() {
        if (!this.selectedCustomer) {
            console.warn('No applicant selected, skipping fetchIntegrationDetails.');
            return;
        }
    
        getApplicantsIntegrationInfo({ loanId: this.recordId, appId: this.selectedCustomer })
            .then(data => {
                console.log('Apex Data:', JSON.stringify(data));
    
                if (!data || data.length === 0) {
                    console.warn('No integration details returned.');
                    this.tableData = [];
                    this.disableTable = true;
                    return;
                }
    
                this.tableData = data.map(param => ({
                    ...param,
                    sources: (param.sources || []).map((source, index) => ({
                        ...source,
                        isFirst: index === 0
                    }))
                }));
                this.disableTable = this.tableData.every(param => 
                    param.sources.every(source => !source.idNo || source.idNo.trim() === "")
                );
        
                console.log('Table Disabled:', this.disableTable);
            })
            .catch(error => {
                console.error('Error fetching integration details:'+ error);
                this.tableData = [];
                this.disableTable = true;
            });
    }

    connectedCallback(){
        console.log('this.recordId connectedCallback:'+ this.recordId);
    }

    handleApplicantChange(event) {
        this.selectedCustomer = event.detail.value;
        console.log('Selected Applicant Id:'+ this.selectedCustomer);
        this.fetchIntegrationDetails();
    }

}