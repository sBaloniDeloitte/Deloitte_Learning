import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import initiateAPIRequest from '@salesforce/apex/COMM_SanctionLetterController.initiateAPIRequest';
import initiateAPRAPIRequest from '@salesforce/apex/COMM_APRController.initiateAPRAPIRequest';
import getExistingSanctionLetter from '@salesforce/apex/COMM_SanctionLetterController.getExistingSanctionLetter';
import canUserGenerateSanctionLetter from '@salesforce/apex/COMM_CreditChargesTableController.canUserGenerateSanctionLetter';

export default class SanctionLetter extends LightningElement {
    @track isLoading = false;
    @track errorMessage = '';
    @track pdfUrl = '';  // Stores the Blob URL for PDF
    @track displayGenerateSanctionLetter = false; 
    @track infoMessage = ''; // New property to store the approval in progress message   
    @track showMessage = false;   
    @track isEditableUser = true;
    @api recordId;

    connectedCallback() {
        canUserGenerateSanctionLetter({ opportunityId: this.recordId })
        .then(result => {
            this.isEditableUser = result;
            console.log('Is editable user:', this.isEditableUser);
        })
        .catch(error => {
            console.error('Error checking user access for VAS:', error);
            this.isEditableUser = false; // Default to read-only if error
        });
        this.checkExistingSanctionLetter(); 
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant, // Accepts 'success', 'info', 'warning', or 'error'
            mode: 'dismissable' // Can be 'dismissable', 'pester', or 'sticky'
        });
        this.dispatchEvent(event);
    }

    checkExistingSanctionLetter() {
        this.isLoading = true;
        this.errorMessage = '';
        this.infoMessage = '';
        
        getExistingSanctionLetter({ loanId: this.recordId })
            .then(response => {
                // Handle the Map response
                if (response.existingDocument) {
                    // If there's an existing document, render it
                    this.renderPDF(response.existingDocument);
                } else if (response.shouldHitAPI) {
                    // If API call is needed, you can trigger it here
                    //this.handleGensancLett(); // Auto-generate if API is needed
                    this.displayGenerateSanctionLetter = true;
                }
                if (response.message) {
                    this.infoMessage = response.message;
                    this.showMessage = true;
                }
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error checking existing sanction letter:', error);
                this.errorMessage = 'Error checking existing sanction letter.';
                this.isLoading = false;
            });
    }

    handleGensancLett() {
        this.isLoading = true;
        this.errorMessage = '';
        this.pdfUrl = '';
        let params = {
            loanId: this.recordId,
            processName: 'Loan APR Calculation'
        };
        if(this.needToHitApr){
             // const resp = await initiateAPRAPIRequest({ inputMap: params })
            initiateAPRAPIRequest({ inputMap: params })
            .then(resp => {
                try {
                    console.log('APR response:: '+resp);

                    if(resp === 'Success'){
                        params = {
                            loanId: this.recordId,
                            processName: 'Sanction Letter Generation'
                        };
                    
                        initiateAPIRequest({ inputMap: params })
                        .then(response => {
                            setTimeout(() => {
                                try {
                                    console.log('response:: '+JSON.stringify(response));
                                    // if(JSON.stringify(response).includes('Error:')){
                                    //     this.errorMessage = JSON.stringify(response);
                                    //     //this.showToast('Error', JSON.stringify(response), 'error');
                                    //     this.needToHitApr = false;
                                    //     this.isLoading = false;
                                    //     return;
                                    // }
                                    //let parsed = JSON.parse(response);
                                    this.needToHitApr = true;
                    
                                    // Case 1: Proper Success
                                    // if (
                                    //     parsed?.response?.status === true &&
                                    //     parsed?.response?.base64StringForPDF
                                    // ) {
                                        this.displayGenerateSanctionLetter = false;
                                        this.showMessage = false;
                                        this.renderPDF(response);
                                    //} 
                                    // Case 2: API returned error with message
                                    // else if (parsed?.message) {
                                    //     this.errorMessage = parsed.message;
                                    //     console.error('API Error Message:', parsed.message);
                                    // } 
                                    // // Case 3: Generic fallback
                                    // else {
                                    //     this.errorMessage = 'Unexpected response from API.';
                                    //     console.error('Unknown API response:', parsed);
                                    // }
                                    this.isLoading = false;
                                } catch (e) {
                                    this.errorMessage = 'Error parsing API response.';
                                    console.error('Parsing Exception:', e);
                                    this.isLoading = false;
                                }
                            }, 30000);
                            
                        })
                        .catch(error => {
                            console.error('JS/Network error:', error);
                            this.errorMessage = 'Sanction letter generation failed.';
                            this.isLoading = false;
                        });
                    }
                    else{
                        this.errorMessage = resp;
                        this.isLoading = false;
                    }
                } 
                catch (e) {
                    this.errorMessage = 'Error APR API response.';
                    console.error('Parsing Exception:', e);
                    this.isLoading = false;
                } 
            })
            .catch(error => {
                console.error('JS/Network error:', error);
                this.errorMessage = 'Sanction letter generation failed.';
                this.isLoading = false;
            });
        }
        else{
            params = {
                loanId: this.recordId,
                processName: 'Sanction Letter Generation'
            };
        
            initiateAPIRequest({ inputMap: params })
            .then(response => {
                setTimeout(() => {
                    try {
                        console.log('response:: '+JSON.stringify(response));
                        // if(JSON.stringify(response).includes('Error:')){
                        //     this.errorMessage = JSON.stringify(response);
                        //     //this.showToast('Error', JSON.stringify(response), 'error');
                        //     this.needToHitApr = false;
                        //     this.isLoading = false;
                        //     return;
                        // }
                        //let parsed = JSON.parse(response);
                        this.needToHitApr = true;
        
                        // Case 1: Proper Success
                        // if (
                        //     parsed?.response?.status === true &&
                        //     parsed?.response?.base64StringForPDF
                        // ) {
                            this.displayGenerateSanctionLetter = false;
                            this.showMessage = false;
                            this.renderPDF(response);
                        //} 
                        // Case 2: API returned error with message
                        // else if (parsed?.message) {
                        //     this.errorMessage = parsed.message;
                        //     console.error('API Error Message:', parsed.message);
                        // } 
                        // // Case 3: Generic fallback
                        // else {
                        //     this.errorMessage = 'Unexpected response from API.';
                        //     console.error('Unknown API response:', parsed);
                        // }
                        this.isLoading = false;
                    } catch (e) {
                        this.errorMessage = 'Error parsing API response.';
                        console.error('Parsing Exception:', e);
                        this.isLoading = false;
                    }
                }, 30000);
                
            })
            .catch(error => {
                console.error('JS/Network error:', error);
                this.errorMessage = 'Sanction letter generation failed.';
                this.isLoading = false;
            });
        }
       
    }
    @track needToHitApr = true;

    handleRegenerateSanctionLetter() {
        this.isLoading = true;
        this.errorMessage = '';
        this.pdfUrl = '';
        let params = {
            loanId: this.recordId,
            processName: 'Loan APR Calculation'
        };

        // const resp = await initiateAPRAPIRequest({ inputMap: params })
        if(this.needToHitApr){
            initiateAPRAPIRequest({ inputMap: params })
            .then(resp => {
                try {
                    console.log('APR response:: '+resp);

                    if(resp === 'Success'){
                        params = {
                            loanId: this.recordId,
                            processName: 'Sanction Letter Generation',
                            isRegenerate: true
                        };
                    
                        initiateAPIRequest({ inputMap: params })
                        .then(response => {
                            setTimeout(() => {
                                try {
                                    console.log('response:: '+JSON.stringify(response));
                                    // if(JSON.stringify(response).includes('Error:')){
                                    //     this.errorMessage = JSON.stringify(response);
                                    //     //this.showToast('Error', JSON.stringify(response), 'error');
                                    //     this.isLoading = false;
                                    //     this.needToHitApr = false;
                                    //     return;
                                    // }
                                    //let parsed = JSON.parse(response);
                                    this.needToHitApr = true;
                                    // Case 1: Proper Success
                                    // if (
                                    //     parsed?.response?.status === true &&
                                    //     parsed?.response?.base64StringForPDF
                                    // ) {
                                        this.displayGenerateSanctionLetter = false;
                                        this.showMessage = false;
                                        this.renderPDF(response);
                                    //} 
                                    // Case 2: API returned error with message
                                    // else if (parsed?.message) {
                                    //     this.errorMessage = parsed.message;
                                    //     console.error('API Error Message:', parsed.message);
                                    // } 
                                    // // Case 3: Generic fallback
                                    // else {
                                    //     this.errorMessage = 'Unexpected response from API.';
                                    //     console.error('Unknown API response:', parsed);
                                    // }
                                    this.isLoading = false;
                                } catch (e) {
                                    this.errorMessage = 'Error parsing API response.';
                                    console.error('Parsing Exception:', e);
                                    this.isLoading = false;
                                }
                            }, 30000);
                            
                        })
                        .catch(error => {
                            console.error('JS/Network error:', error);
                            this.errorMessage = 'Sanction letter generation failed.';
                            this.isLoading = false;
                        });
                    }
                    else{
                        this.errorMessage = resp;
                        this.isLoading = false;
                    }
                } 
                catch (e) {
                    this.errorMessage = 'Error APR API response.';
                    console.error('Parsing Exception:', e);
                    this.isLoading = false;
                } 
            })
            .catch(error => {
                console.error('JS/Network error:', error);
                this.errorMessage = 'Sanction letter generation failed.';
                this.isLoading = false;
            });
        }
        else{
            params = {
                loanId: this.recordId,
                processName: 'Sanction Letter Generation',
                isRegenerate: true
            };
        
            initiateAPIRequest({ inputMap: params })
            .then(response => {
                setTimeout(() => {
                    try {
                        console.log('response:: '+JSON.stringify(response));
                        // if(JSON.stringify(response).includes('Error:')){
                        //     this.errorMessage = JSON.stringify(response);
                        //     //this.showToast('Error', JSON.stringify(response), 'error');
                        //     this.isLoading = false;
                        //     this.needToHitApr = false;
                        //     return;
                        // }
                        //let parsed = JSON.parse(response);
                        this.needToHitApr = true;
                        // Case 1: Proper Success
                        // if (
                        //     parsed?.response?.status === true &&
                        //     parsed?.response?.base64StringForPDF
                        // ) {
                            this.displayGenerateSanctionLetter = false;
                            this.showMessage = false;
                            this.renderPDF(response);
                        //} 
                        // Case 2: API returned error with message
                        // else if (parsed?.message) {
                        //     this.errorMessage = parsed.message;
                        //     console.error('API Error Message:', parsed.message);
                        // } 
                        // // Case 3: Generic fallback
                        // else {
                        //     this.errorMessage = 'Unexpected response from API.';
                        //     console.error('Unknown API response:', parsed);
                        // }
                        this.isLoading = false;
                    } catch (e) {
                        this.errorMessage = 'Error parsing API response.';
                        console.error('Parsing Exception:', e);
                        this.isLoading = false;
                    }
                }, 20000);
                
            })
            .catch(error => {
                console.error('JS/Network error:', error);
                this.errorMessage = 'Sanction letter generation failed.';
                this.isLoading = false;
            });
        }   
    }

    renderPDF(base64String) {
        try {
            let byteCharacters = atob(base64String);
            let byteNumbers = new Array(byteCharacters.length);
            for (let i = 0; i < byteCharacters.length; i++) {
                byteNumbers[i] = byteCharacters.charCodeAt(i);
            }
            let byteArray = new Uint8Array(byteNumbers);
            let file = new Blob([byteArray], { type: 'application/pdf' });

            this.pdfUrl = URL.createObjectURL(file);  // Create a Blob URL for PDF
        } catch (error) {
            console.error('Error rendering PDF:', error);
            this.errorMessage = 'Error rendering PDF.';
        }
    }
}