import { LightningElement,track,api } from 'lwc';
import getAllDocument from '@salesforce/apex/DocumentViewCmpController.getAllDocumentFCU';

export default class FcuDocuments extends LightningElement {
     @api recordId;
     @track alldocuments = [];
     @track isScreened = false;
     connectedCallback() {
        if (this.recordId) {
            this.getAllRelatedDocs();
        }
    }
     getAllRelatedDocs() {
            getAllDocument({
                recordId: this.recordId
            }).then(response=>{
                const updatedDocs = response.map(doc => {
                    return {
                        ...doc,
                        isScreened: doc.screeningstatus === 'Screened'
                    };
                });
                this.alldocuments = this.sortDocumentsByScreeningStatus(updatedDocs);
                console.log('all related documents -->'+JSON.stringify(this.alldocuments));
                console.log('all related documents -->'+this.isScreened);
            }).catch(error=>{
                console.error('Error allrelateddocuments file -->', JSON.stringify(error));
            });
        }
        sortDocumentsByScreeningStatus(documents) {
            const statusOrder = ['Pending', 'Added to sampling queue', 'Recommended For FCU','On Hold','Screened','FCU Initiated','FCU Completed','Cancelled',''];
        
            return documents.sort((a, b) => {
                
                const statusA = a.screeningstatus || '';  
                const statusB = b.screeningstatus || '';  
                // Sorting based on the index in statusOrder
                return statusOrder.indexOf(statusA) - statusOrder.indexOf(statusB);
            });
    }
}