import { LightningElement,api,track,wire } from 'lwc';
import fetchProductDetails from '@salesforce/apex/FinalEligibilityFieldsController.fetchProductDetails';
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class Hl_finalEligibilityFieldsCmp extends LightningElement {
    @api loanId;
    @api productId;
    @api productName;
    @track fieldDetails;
    @track dataLoaded = false; 
    @api subProdid;
    @api disableActions = false;

    connectedCallback() {
        console.log('15 disableActions: '+this.disableActions);
        this.fetchProductDetails(); 
    }
    /*fetchProductDetails(){
        fetchProductDetails({
            productId: this.productId
        }).then((result) => {
            console.log('result=:'+JSON.stringify(result));
            this.fieldDetails = result;
            this.dataLoaded = true;
        }).catch((err) => {
            
        });
    }*/
    fetchProductDetails() {
        fetchProductDetails({ productId: this.productId })
            .then((result) => {
                console.log('result=:' + JSON.stringify(result));

                this.fieldDetails = result.map(item => {
                    let newItem = JSON.parse(JSON.stringify(item));

                    // Skip rounding for these labels
                    const skipRounding = newItem.fieldLabel === 'Rate of Interest';

                    if (!skipRounding && newItem.breOutput?.fieldApiVal) {
                        newItem.breOutput.fieldApiVal =
                            this.roundCustom(newItem.breOutput.fieldApiVal);
                    }

                    if (!skipRounding && newItem.sanctionTermOutput?.fieldApiVal) {
                        newItem.sanctionTermOutput.fieldApiVal =
                            this.roundCustom(newItem.sanctionTermOutput.fieldApiVal);
                    }

                    return newItem;
                });

                this.dataLoaded = true;
            })
            .catch((err) => {
                console.error(err);
            });
    }

    roundCustom(value) {
        if (!value) return value;

        let num = parseFloat(value);
        let decimalPart = Math.floor((num % 1) * 100);  // first two digits of decimal

        let base = Math.floor(num); // integer part

        if (decimalPart < 50) {
            return Math.floor(base / 10) * 10; // round down
        } else {
            return Math.ceil(base / 10) * 10; // round up
        }
    }

    handleSaveField(event){
        var enteredVal = 0;
        if(event.target.value != null && event.target.value != undefined && event.target.value != ''){
            if ((isNaN(Number(event.target.value)))){
                this.showToast('Error', 'Please enter valid number!', 'error');
                return;
            }
            else{
                enteredVal = Number(event.target.value);
            }
        }
        console.log('event.target.dataset.name=:'+event.target.dataset.name);
        console.log('this.productId=:'+this.subProdid);
        const fields = {};
        fields['Id'] = this.subProdid;
        fields[event.target.dataset.name] = enteredVal;
        const recordInput = { fields };
        updateRecord(recordInput)
        .then(() => {
            this.showToast('Success', 'Data saved', 'success');
        }).catch(error=>{

        })
    }
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}