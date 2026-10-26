import { LightningElement,api,track } from 'lwc';
import getAllVersionDocument from '@salesforce/apex/COMM_DocumentDetailsScreenController.getAllVersionDocumentHistory'

export default class ViewDocumentHistory extends LightningElement {
    @api recordId;
    @track documentHistory;
    @track modalVisibility = false;
    @track isRendered = false;
    timestampOptions = [
        { label: 'Ascending', value: 'asc' },
        { label: 'Descending', value: 'desc' }
    ];
    selectedTimestamp='asc';

    connectedCallback(){
        this.getDocumentHistory();
    }

    getDocumentHistory(){
        console.log('this.recordId: '+this.recordId);
        getAllVersionDocument({recordId:this.recordId})
        .then(result => {
            const rows = Array.isArray(result) ? result : [];
            this.selectedTimestamp = 'asc';
            this.documentHistory   = this.sortDocuments(rows, 'asc');
            console.log('documentHistory '+JSON.stringify(this.documentHistory));
            if(this.documentHistory && this.documentHistory.length > 0){
                this.modalVisibility = true;
            } else {
                this.modalVisibility = false;
            }
        })
        .catch(error => {
            console.log(error);
        });
    }
    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
    handleTimestampChange(event) {
        this.selectedTimestamp = event.detail.value;
        this.documentHistory = this.sortDocuments(this.documentHistory, this.selectedTimestamp);
    }
    sortDocuments(docs, order = 'asc') {
        const dir = order === 'asc' ? 1 : -1;
        return [...docs].sort((a, b) => {
            const ta = typeof a.timestampEpochMs === 'number'
            ? a.timestampEpochMs
            : (a.Timestamp ? new Date(a.Timestamp).getTime() : 0);
            const tb = typeof b.timestampEpochMs === 'number'
            ? b.timestampEpochMs
            : (b.Timestamp ? new Date(b.Timestamp).getTime() : 0);

            if (ta !== tb) return (ta - tb) * dir;
            const va = typeof a.versionNumber === 'number' ? a.versionNumber : 0;
            const vb = typeof b.versionNumber === 'number' ? b.versionNumber : 0;
            return (va - vb) * dir;
        });
    }
    renderedCallback() {
        if (!this.isRendered) {
          // Create and append styles dynamically
          const style = document.createElement("style");
          style.innerText = `
          .slds-form-element .slds-dropdown_container  {
            min-width: 40%;
        }
            `;
          // Append the styles to the .styleContainer
          this.template.querySelector(".styleContainer")?.appendChild(style);
          // Prevent re-adding styles
          this.isRendered = true;
        }
      }
}