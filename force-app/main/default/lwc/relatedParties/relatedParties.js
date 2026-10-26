//_______________This Code was generated using GenAI tool: Codify, Please check for accuracy_______________//

import { LightningElement } from 'lwc';

export default class RelatedParties extends LightningElement {

    parties = [
        {
            id: 1,
            name: 'Bright Future Counsellors',
            meta: 'Sourcing channel · 14 leads this year'
        },
        {
            id: 2,
            name: 'University of Toronto',
            meta: 'Institute · tier 1 · approved'
        },
        {
            id: 3,
            name: 'Andheri East branch',
            meta: 'Servicing branch · BR-MUM-014'
        },
        {
            id: 4,
            name: 'Infotech Solutions Pvt Ltd',
            meta: 'Co-applicant employer · category A'
        }
    ];

    handleOpen(event) {
        const id = event.currentTarget.dataset.id;
        console.log('Open party id:', id);
    }
}

//__________________________GenAI: Generated code ends here______________________________//