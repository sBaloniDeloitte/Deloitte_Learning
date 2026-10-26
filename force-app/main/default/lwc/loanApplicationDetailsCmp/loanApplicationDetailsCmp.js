/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getLoanApplicationDetails from '@salesforce/apex/LoanApplicationDetailsController.getLoanApplicationDetails';

export default class LoanApplicationDetailsCmp extends NavigationMixin(LightningElement) {
    @api recordId;

    sectionsData = [];
    openMap = {};
    error;

    @wire(getLoanApplicationDetails, { recordId: '$recordId' })
    wiredDetails({ data, error }) {
        if (data) {
            this.sectionsData = data.map((section) => ({
                sectionName: section.sectionName,
                fields: (section.fields || []).map((field, index) => ({
                    key: section.sectionName + field.label + index,
                    label: field.label,
                    value: field.value != null && field.value !== '' ? field.value : '—',
                    isLink: Boolean(field.isLink && field.linkId),
                    recordId: field.linkId,
                    objectApiName: field.linkObjectName,
                    columnPosition: field.columnPosition
                }))
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.sectionsData = [];
        }
    }

    get sections() {
        return this.sectionsData.map((section, index) => {
            const isOpen = this.openMap[section.sectionName] !== false;
            return {
                key: section.sectionName + index,
                sectionName: section.sectionName,
                iconName: isOpen ? 'utility:chevrondown' : 'utility:chevronright',
                bodyClass: isOpen ? 'section-body' : 'section-body slds-hide',
                leftFields: section.fields.filter((field) => field.columnPosition !== 'Right'),
                rightFields: section.fields.filter((field) => field.columnPosition === 'Right')
            };
        });
    }

    toggleSection(event) {
        const sectionName = event.currentTarget.dataset.section;
        const isCurrentlyOpen = this.openMap[sectionName] !== false;
        this.openMap = { ...this.openMap, [sectionName]: !isCurrentlyOpen };
    }

    handleLinkClick(event) {
        event.preventDefault();
        const linkId = event.currentTarget.dataset.id;
        const objectApiName = event.currentTarget.dataset.object;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: linkId,
                objectApiName,
                actionName: 'view'
            }
        });
    }
}
/*__________________________GenAI: Generated code ends here______________________________*/