import { LightningElement, track } from 'lwc';
import initiateFetchDate from '@salesforce/apex/FetchApplicationDateController.initiateFetchDate';
import getFetchAppDateIntDetails from '@salesforce/apex/FetchApplicationDateController.getFetchAppDateIntDetails';
export default class FetchApplicationDateCmp extends LightningElement {
    @track applicationDate;
    @track isLoading = false;
    connectedCallback(){
        this.fetchAppDateIntDetails();
    }

    callFetchAppDateApi(){
        this.isLoading = true;
        initiateFetchDate()
        .then(response => {
            this.isLoading = false;
            console.log('Response initiate fetch date: '+JSON.stringify(response));
            this.fetchAppDateIntDetails();
        })
        .catch(error => {
            this.isLoading = false;
            console.error('Error initiating Fetch Date :', JSON.stringify(error));
        });
    }

    fetchAppDateIntDetails(){
        getFetchAppDateIntDetails()
        .then(response => {
            console.log('Response initiate fetch date: '+JSON.stringify(response));
            this.applicationDate = response;
        })
        .catch(error => {
            console.error('Error getting Fetch App Date Int Details :', JSON.stringify(error));
        });
    }
}