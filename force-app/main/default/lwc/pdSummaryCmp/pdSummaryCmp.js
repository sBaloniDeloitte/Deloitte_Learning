import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getPdSummaryRecords from "@salesforce/apex/PdSummaryController.getPdSummaryRecords";
import {NavigationMixin} from 'lightning/navigation';
import { updateRecord } from "lightning/uiRecordApi";

export default class PdSummaryCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @track apRecords = [];

    @api
    refreshCmp() {
      this.getPdSummaryRec();
    }


    connectedCallback() {
        this.getPdSummaryRec();
    }

    getPdSummaryRec() {
        getPdSummaryRecords({
          recordId: this.recordId,
        })
          .then((response) => {
            console.log("Ap rec" + JSON.stringify(response));
            this.apRecords = response;
          })
          .catch((error) => {});
      }
}