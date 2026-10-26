import { LightningElement,track,api,wire } from 'lwc';

import getTeamMembers from '@salesforce/apex/OTMController.getTeamMembers';

export default class OTMdisplayCmp extends LightningElement {

@api recordId;
oppWrap = [];
    connectedCallback(){
        getTeamMembers({opportunityId: this.recordId})
        .then(result => {
            this.oppWrap = result;
        })
        .catch(error => {
            this.error = error;
        });
    }

    renderedCallback(){
        const rowCells = this.template.querySelectorAll('tbody td');
        rowCells.forEach((cell) => {
            cell.style.background = '#16283f';
        });
    }

}