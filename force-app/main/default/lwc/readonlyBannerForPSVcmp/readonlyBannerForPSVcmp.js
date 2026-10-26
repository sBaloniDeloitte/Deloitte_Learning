import { LightningElement, track } from 'lwc';

export default class ReadonlyBannerForPSVcmp extends LightningElement {
    @track message

    connectedCallback(){
        this.message = 'This screen is read-only for your profile.';
    }
}