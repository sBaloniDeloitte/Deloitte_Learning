import { LightningElement, track, api } from 'lwc';

export default class InitiateFCUCmp extends LightningElement {
    @api recordId;
    @track initiateFCU=true;
    
}