import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import callAPIButtonClicked from '@salesforce/apex/LoanExposureController.callAPIButtonClicked';
import getSalesforceExposure from '@salesforce/apex/LoanExposureController.getSalesforceExposure';
import getExposureFromIntegrationDetails from '@salesforce/apex/LoanExposureController.getExposureFromIntegrationDetails';
import getSFExposure from '@salesforce/apex/LoanExposureController.getSFExposure';
import getTotalExposure from '@salesforce/apex/LoanExposureController.getTotalExposure';


export default class BankingDetailsMain extends LightningElement {

    @api recordId;
    @api processObject;                 //to get the object/process name
    @track responseData;

    @track bankingData = {};
    @api showButton = false;
    @track spinner = false;
    // Extracted values from API response
    @track returnCode;
    @track returnText;

    @track totalExposure;
    @track totalExposureGhfHfc;
    @track totalExposureGflNbfc;
    @track totalExposureGc;

    @track exposureGhfWipLoan;
    @track exposureGhfDisburstLoan;
    @track exposureGfl = null;

    @track existingLoans = [];
    @track linkedLoans = [];
    @track linkedLoansCombined = [];

    @track totalWipLoanSalesforce;
    @track totalDisbursedLoanSalesforce;

    @track totalExposureNew;

    
// @wire(getExposureFromIntegrationDetails, { opportunityId: '$recordId', processObject: this.processObject })

//     wiredData({ data, error }) {
//         console.log('this.processObject: '+this.processObject);

//         if (data) {
//             let parsedResponse;
//             if(data != 'notfound')
//             {
//                 try {
//                     // First, check if response is already an object
//                     if (typeof data === "string") {
//                         parsedResponse = JSON.parse(data);
//                     } else {
//                         parsedResponse = data;
//                     }

//                     console.log("✅ Properly Parsed Response:", parsedResponse);
//                     if (typeof parsedResponse === "string") {
//                         parsedResponse = JSON.parse(parsedResponse);
//                     }
//                     console.log("Parsed Response Type:", typeof parsedResponse);
//                     console.log("Parsed Response Keys:", Object.keys(parsedResponse)); // Should show actual keys like "returnStatus"

//                         this.assignValuesFromResponse(parsedResponse);
//                 } catch (error) {
//                     console.error("❌ Error parsing JSON:", error);
//                     return;
//                 }
//             }
                
//             this.fetchSalesforceExposure();
//         } else if (error) {

//             console.error(error);

//         }
//     }

    connectedCallback(){
        this.getExposureData();
    }

    getExposureData(){
        console.log('this.processObject: '+this.processObject);

        getExposureFromIntegrationDetails({
            recordId: this.recordId, 
            processObject: this.processObject
        })
        .then(response=>{
            
            if(response) {
                let parsedResponse;
                if(response != 'notfound')
                {
                    try {
                        // First, check if response is already an object
                        if (typeof response === "string") {
                            parsedResponse = JSON.parse(response);
                        } else {
                            parsedResponse = response;
                        }
    
                        console.log("✅ Properly Parsed Response:", parsedResponse);
                        if (typeof parsedResponse === "string") {
                            parsedResponse = JSON.parse(parsedResponse);
                        }
                        console.log("Parsed Response Type:", typeof parsedResponse);
                        console.log("Parsed Response Keys:", Object.keys(parsedResponse)); // Should show actual keys like "returnStatus"
    
                        this.assignValuesFromResponse(parsedResponse);
                    } catch (error) {
                        console.error("❌ Error parsing JSON:", error);
                        return;
                    }
                }else {
                    this.showButton = false;
                }
                this.fetchSalesforceExposureNew();
                this.fetchTotalExposureNew();
                //this.fetchSalesforceExposure();
            } else if (error) {
                console.error(error);
            }
        })
        .catch(error=>{
            console.error('error getDocumentChecklistRecords --> '+JSON.stringify(error));
        })
    }

    fetchSalesforceExposure() {
        getSalesforceExposure({ recordId: this.recordId, processObject: this.processObject })
        .then(data => {
            this.salesforceResponseData = JSON.parse(data);
            console.log('✅ salesforceResponseData:', this.salesforceResponseData);
            this.totalWipLoanSalesforce = this.salesforceResponseData?.totalWIPLoan || null;
            this.totalDisbursedLoanSalesforce = this.salesforceResponseData?.totalDisbursedLoan || null;

        })
        .catch(error => {
            console.error('salesforceExposure error'+error);
        });
    }

    fetchSalesforceExposureNew() {
        getSFExposure({ loanId: this.recordId, processObject: this.processObject })
        .then(data => {
            
            console.log('✅ salesforceResponseData:', data);
            this.totalWipLoanSalesforce = data;

        })
        .catch(error => {
            console.error('salesforceExposure error'+error);
        });
    }
    fetchTotalExposureNew() {
        getTotalExposure({ loanId: this.recordId})
        .then(data => {
            
            console.log('✅ salesforceResponseData:', data);
            this.totalExposureNew = data;

        })
        .catch(error => {
            console.error('salesforceExposure error'+error);
        });
    }

    handleClick() {
        this.spinner = true;
        console.log('spinner true');
        
        callAPIButtonClicked({ recordId: this.recordId, processObject: this.processObject })
        .then(response => {
            console.log('Raw Response:', response);

            this.responseData = JSON.parse(response);
            // 🔥 Check if returnText is not "Success"
            this.returnText = this.responseData?.returnStatus?.returnText || 'N/A';

            this.fetchSalesforceExposureNew();
            this.fetchTotalExposureNew();

            if (this.returnText.toLowerCase() !== 'success') {
                this.showToast('Error', `API Error: ${this.returnText}`, 'error');
                this.spinner = false;
                return; // Stop execution if there's an error
            }

            this.assignValuesFromResponse(this.responseData);
            this.showToast('Success', 'Data fetched successfully!', 'success');
            this.spinner = false;
            console.log('spinner false');
        })
        .catch(error => {
            this.fetchSalesforceExposureNew();
                this.fetchTotalExposureNew();
            console.error('Error fetching data:', error);
            this.showToast('Error', 'Failed to parse API response.', 'error');
            this.spinner = false;
            console.log('spinner false');
        });
    }

     // ✅ Toast function remains unchanged
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    get hasData() {
        return this.bankingData !== undefined;
    }

    assignValuesFromResponse(jsonResponse)
    {
         if (jsonResponse) {
            console.log('✅ responseData:', jsonResponse);
            if (typeof jsonResponse === "string") {
                try {
                    jsonResponse = JSON.parse(jsonResponse);
                    console.log('✅ responseData after:', jsonResponse);
                } catch (error) {
                    console.error("Error parsing JSON:", error);
                }
            }

            this.returnCode = jsonResponse?.returnStatus?.returnCode || 'N/A';
            this.returnText = jsonResponse?.returnStatus?.returnText || 'N/A';
            console.log('✅ returnStatus:', jsonResponse?.returnStatus);
            
            // if(this.processObject != 'Account'){
            //     this.showButton = false;
            // }

            const formatIndianNumber = (num) => {
                if (num == null) return null;
                return num.toLocaleString('en-IN');
            };
                
            this.totalExposure = formatIndianNumber(jsonResponse?.bankingDetails?.totalExposure || null);
            this.totalExposureGhfHfc = formatIndianNumber(jsonResponse?.bankingDetails?.totalExposureGHF_HFC || null);
            this.totalExposureGflNbfc = formatIndianNumber(jsonResponse?.bankingDetails?.totalExposureGFL_NBFC || null);
            this.totalExposureGc = formatIndianNumber(jsonResponse?.bankingDetails?.totalExposureGC || null);

            this.exposureGhfWipLoan = formatIndianNumber(jsonResponse?.summaryExposure?.exposureGHF?.disburstLoan || null);
            this.exposureGhfDisburstLoan = formatIndianNumber(jsonResponse?.summaryExposure?.exposureGHF?.disburstLoan || null);
            this.exposureGfl = formatIndianNumber(jsonResponse?.summaryExposure?.exposureGFL || null); // Keep as an object
            // this.existingLoans = jsonResponse?.existingLoans || [];
            this.existingLoans = (jsonResponse?.existingLoans || []).map(loan => ({
                ...loan,
                original_amount_formatted: formatIndianNumber(loan.original_amount),
                undisbursed_amount_formatted: formatIndianNumber(loan.undisbursed_amount),
                installment_amount_formatted: formatIndianNumber(loan.installment_amount),
                outstanding_amount_formatted: formatIndianNumber(loan.outstanding_amount)
            }));
            this.linkedLoans = jsonResponse?.linklanDetails?.linkedLoans || {};
            this.linkedLoansCombined = Object.values(this.linkedLoans).flat();
        }
    }
}