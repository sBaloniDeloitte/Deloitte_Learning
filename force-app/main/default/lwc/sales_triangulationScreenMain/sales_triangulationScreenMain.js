import { LightningElement, api, track } from 'lwc';
import getApplicants from "@salesforce/apex/COMM_ItrScreenController.getApplicants";

export default class Sales_triangulationScreenMain extends LightningElement {
    @api recordId;
    @track options=[];

    connectedCallback(){
        console.log('recordId: ', this.recordId);
        this.getAllApplicants();
    }

    getAllApplicants(){
        getApplicants({
            recordId: this.recordId,
        })
        .then((response) => {
            console.log("customer details=: " + JSON.stringify(response));
            //this.options = [... this.options,{label:'All',value:'All'}];
            for (let key in response) {
                console.log("customer details=:" + response[key]);
                this.options = [
                    ...this.options,
                    {
                        label: response[key],
                        value: key,
                    },
                ];
            }
        })
        .catch((error) => {});

    }
}