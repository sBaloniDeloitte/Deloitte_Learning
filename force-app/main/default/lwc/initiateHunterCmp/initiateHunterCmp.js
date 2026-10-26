import { LightningElement, track, api } from 'lwc';

export default class InitiateHunterCmp extends LightningElement {
    @api recordId;
    @track initiateHunter=true;
}