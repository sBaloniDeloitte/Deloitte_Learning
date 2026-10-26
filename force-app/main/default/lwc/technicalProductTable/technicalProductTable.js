import { LightningElement, api, track } from 'lwc';
import fetchAllProducts from '@salesforce/apex/TechnicalEvaluationPDFController.fetchAllProducts';

export default class TechnicalProductTable extends LightningElement {
    @api recordId;   
    @track showAllProducts = false;
    @track products = [];

    connectedCallback() {
        console.log('recordId: ', this.recordId);
        this.loadProducts();
    }

    loadProducts() {
        fetchAllProducts({ loanId: this.recordId })
            .then((result) => {
                this.products = result;
                this.showAllProducts = this.products.length > 0;
            })
            .catch((error) => {
                console.error('Error fetching products:', error);
            });
    }
}