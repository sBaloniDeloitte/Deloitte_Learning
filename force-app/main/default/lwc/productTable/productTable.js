import { LightningElement, api, wire, track } from 'lwc';
import getProductsByOpportunity from '@salesforce/apex/ProductTableController.getProductsByOpportunity';
import fillRecommondedLoanAmount from '@salesforce/apex/ProductTableController.fillRecommondedLoanAmount';
import getNegotiatedDetails from '@salesforce/apex/ProductTableController.getNegotiatedDetails';


import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ProductTable extends LightningElement {
    @api recordId;
    //@api isOneView = false;
    @track products = [];
    noProducts = false;
    @track isResanction = false;
    @track negoProducts = [];
    //@api enableDisabled=false;
    @api disabledCmp = false;
    ativeSections = ['Eligibility', 'Negotiated Details'];

    _isOneView = false;
    _enableDisabled = false;

    @api
    set isOneView(v) { this._isOneView = v === true || v === 'true'; }
    get isOneView() { return this._isOneView; }

    @api
    set enableDisabled(v) { this._enableDisabled = v === true || v === 'true'; }
    get enableDisabled() { 
        if(this.disabledCmp) {
            return true;
        }
        return this._enableDisabled; 
    }

    get disabledAll() {
        return this.isOneView || this.enableDisabled || this.disabledCmp;
    }

    /*
    @wire(getProductsByOpportunity, { loanApplicationId: '$recordId' })
    wiredProducts({ error, data }) {
        if (data) {
            console.log('products: ' + JSON.stringify(data));
            this.products = data;
            if(this.products.length == 0){
                this.noProducts = true;
            }
           
            }else if(error) {
            console.error('Error fetching products:', error);
            this.noProducts = true;
        }
    }*/

     connectedCallback(){
        console.log('opportunityId: ' + this.recordId);
        this.hanldeRefresh();
        this.hanldeRefreshNegotiated();
    }
    
    handleInputChange(event) {
    const index = event.target.dataset.index;
    const value = event.target.value;
    const fieldName = event.target.dataset.id;
    const currentValue = this.products[index][fieldName];
    if (!event.target.checkValidity()) {
        console.log('Invalid input detected. Skipping update.');
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Invalid Input',
                message: 'Please enter a valid value.',
                variant: 'error'
            })
        );
        return;
    }
    if (value == currentValue) {
        console.log('No change detected. Skipping update.');
        return;
    }
    const fields = {
        Id: this.products[index]['Id'],
        [fieldName]: value 
    }
    console.log('fields: ' + JSON.stringify(fields));
    
    const recordInput = { fields };

    updateRecord(recordInput)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Record updated successfully',
                    variant: 'success'
                })
            );
            if(fieldName == 'Sanctioned_Loan_Amount__c' || fieldName == 'EMI_Amount__c' || fieldName == 'Sanctioned_Tenor__c' || fieldName == 'Sanctioned_ROI__c') {
                this.fillSantionAmtOnLoan();
            }
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating record',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });

        /*try{
        const fieldName = event.target.dataset.id;
        const index = event.target.dataset.index;
        const value = event.target.value;

        console.log('value', value);
        console.log('index', index);

        let updatedProducts = JSON.parse(JSON.stringify(this.products));

        updatedProducts[index][fieldName] = value;

        this.products = updatedProducts;

        console.log('Updated products:', JSON.stringify(this.products));

        }catch(e){
            console.log('Error: '+e.message);
        }*/
       
    }

    /*handleSave() {
        console.log('Payload being sent:', JSON.stringify(this.products));

        saveProductData({ products: this.products })
            .then(() => {
                console.log('Data saved successfully');
            })
            .catch(error => {
                console.error('Error saving data:', error);
            });
    }*/

    hanldeRefresh() {
        getProductsByOpportunity({
          loanApplicationId: this.recordId,
        })
          .then((response) => {
            if (response) {
            console.log('products: ' + JSON.stringify(response));
            this.products = response;
            if(this.products.length == 0){
                this.noProducts = true;
            }
           
            }else if(error) {
            console.error('Error fetching products:', error);
            this.noProducts = true;
        }
          })
          .catch((error) => {});
    }

    hanldeRefreshNegotiated() {
        getNegotiatedDetails({
          recordId: this.recordId,
        })
          .then((response) => {
            if (response) {
            console.log('products: ' + JSON.stringify(response));
            this.negoProducts = response;
            if(this.negoProducts.length > 0 && this.negoProducts[0].Loan_Application__r.Resanction__c){
                this.isResanction = true;
            }
           
            }else if(error) {
            console.error('Error fetching products:', error);
           
        }
          })
          .catch((error) => {});
    }

    fillSantionAmtOnLoan() {
        fillRecommondedLoanAmount({
          recordId: this.recordId,
        })
          .then((response) => {
            this.hanldeRefresh();
          })
          .catch((error) => {});
    }
}