import { LightningElement, track, api, wire } from 'lwc';
import getImageId from '@salesforce/apex/COMM_ApplicantPhotoController.getImageId';

export default class ApplicantPhotoCmp extends LightningElement {
    imageUrl;
    @api recordId;

    @wire(getImageId, { recordId: '$recordId' })
    wiredFiles({ error, data }) {
        if (data) {
            console.log('data',data);
            const versionId = data;
            this.imageUrl = `/sfc/servlet.shepherd/version/download/${versionId}`;
        } else if (error) {
            console.error(error);
        }
    }
}