import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getMyLeads from '@salesforce/apex/LeadListViewController.getMyLeads';

const COLUMNS = [
    {
        label: 'Name',
        fieldName: 'leadUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_blank'
        }
    },
    {
        label: 'Lead Number',
        fieldName: 'Lead_Number__c',
        type: 'text'
    },
    {
        label: 'Mobile',
        fieldName: 'MobilePhone',
        type: 'phone'
    },
    {
        label: 'Status',
        fieldName: 'Status',
        type: 'text'
    },
    {
        label: 'Lead Type',
        fieldName: 'Lead_Type__c',
        type: 'text'
    }
];

export default class MyLeadListView extends LightningElement {

    columns = COLUMNS;

    @track leads = [];

    wiredResult;

    @wire(getMyLeads)
    wiredLeads(result) {
        this.wiredResult = result;

        if (result.data) {
            this.leads = result.data.map(row => {
                return {
                    ...row,
                    leadUrl: '/' + row.Id
                };
            });
        }
    }

    async handleRefresh() {
        await refreshApex(this.wiredResult);
    }
}