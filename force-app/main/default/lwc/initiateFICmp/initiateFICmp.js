import { api, LightningElement, track } from 'lwc';

export default class InitiateFICmp extends LightningElement {
    @api recordId;
    @track initiateFI=true;
}