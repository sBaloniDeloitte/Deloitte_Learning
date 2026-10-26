/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
import { LightningElement, api, wire } from 'lwc';
import getHunterVerifications from '@salesforce/apex/HunterAccordionController.getHunterVerifications';

/**
 * @description Dark-themed replacement for the standard "Application Verifications"
 *              related list (Dynamic Related List) that used to sit inside the
 *              Hunter Check accordion section, so its background/border/typography
 *              matches the Field Investigation Initiation dark theme
 *              (creditFIInitiationCmp / documentProcessingScreen ".doc-table").
 */
export default class HunterAccordionCmp extends LightningElement {
    @api recordId;

    verifications = [];

    @wire(getHunterVerifications, { recordId: '$recordId' })
    wiredVerifications({ data, error }) {
        if (data) {
            this.verifications = data.map((rec) => ({
                Id: rec.Id,
                name: rec.Name,
                applicantName: rec.Applicant__r ? rec.Applicant__r.Name : '',
                hunterDecision: rec.Hunter_Decision__c,
                hunterMatch: rec.Hunter_Match__c
            }));
        } else if (error) {
            this.verifications = [];
        }
    }

    get hasVerifications() {
        return this.verifications && this.verifications.length > 0;
    }
}
/*__________________________GenAI: Generated code ends here______________________________*/