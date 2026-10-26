//_______________This Code was generated using GenAI tool: Codify, Please check for accuracy_______________//
import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import SF_CUSTOMER_ID from '@salesforce/schema/Account.SF_Customer_ID__c';
import CUSTOMER_TYPE from '@salesforce/schema/Account.Customer_Type__c';
import ACCOUNT_TYPE from '@salesforce/schema/Account.Type';

function getInitials(name) {
    if (!name) {
        return 'CU';
    }

    return name
        .split(' ')
        .map(part => part.charAt(0))
        .join('')
        .substring(0, 2)
        .toUpperCase();
}

export default class Customer360 extends NavigationMixin(LightningElement) {

    @api recordId;

    activeTab = 'overview';

    // Temporary demo data
    // Later this can come from Apex using recordId
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [ACCOUNT_NAME, SF_CUSTOMER_ID, CUSTOMER_TYPE, ACCOUNT_TYPE]
    })
    account;

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Contacts',
        fields: ['Contact.Id', 'Contact.Name', 'Contact.Title']
    })
    relatedContacts;

    get customerName() {
        return getFieldValue(this.account.data, ACCOUNT_NAME);
    }

    get accountNumber() {
        return getFieldValue(this.account.data, SF_CUSTOMER_ID);
    }

    get customerType() {
        return getFieldValue(this.account.data, CUSTOMER_TYPE);
    }

    get accountType() {
        return getFieldValue(this.account.data, ACCOUNT_TYPE);
    }

    get initials() {
        return getInitials(this.customerName);
    }

    get relatedContactCards() {
        const records = this.relatedContacts?.data?.records;

        if (!records) {
            return [];
        }

        return records.map(record => {
            const name = record.fields.Name.value;
            const title = record.fields.Title.value;

            return {
                id: record.id,
                name,
                title: title || 'Related contact',
                initials: getInitials(name)
            };
        });
    }

    get isOverview() {
        return this.activeTab === 'overview';
    }

    get isLoans() {
        return this.activeTab === 'loans';
    }

    get isRisk() {
        return this.activeTab === 'risk';
    }

    get overviewTabClass() {
        return this.getTabClass('overview');
    }

    get loansTabClass() {
        return this.getTabClass('loans');
    }

    get riskTabClass() {
        return this.getTabClass('risk');
    }

    getTabClass(tabName) {
        return this.activeTab === tabName
            ? 'main-tab active'
            : 'main-tab';
    }

    handleTabChange(event) {
        this.activeTab = event.currentTarget.dataset.tab;
    }

    handleNewContact() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Contact',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: this.recordId
                    ? `AccountId=${this.recordId}`
                    : undefined
            }
        });
    }

    handleNewOpportunity() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: this.recordId
                    ? `AccountId=${this.recordId}`
                    : undefined
            }
        });
    }
}
//__________________________GenAI: Generated code ends here______________________________//