import { LightningElement, api } from 'lwc';

export default class WaiverHistory extends LightningElement {
    @api waivers; // receives waiverRecords from parent
}