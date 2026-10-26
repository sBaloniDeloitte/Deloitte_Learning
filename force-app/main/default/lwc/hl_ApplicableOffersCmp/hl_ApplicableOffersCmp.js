import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkApplicableCampaigns from '@salesforce/apex/HL_ApplicableOffersController.checkApplicableCampaigns';
import getCampaignOffers from '@salesforce/apex/HL_ApplicableOffersController.getCampaignOffers';
import saveSelectedOffer from '@salesforce/apex/HL_ApplicableOffersController.saveSelectedOffer';
import removeSelectedOffer from '@salesforce/apex/HL_ApplicableOffersController.removeSelectedOffer';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import { publish, MessageContext } from 'lightning/messageService';
// import OFFER_APPLY_CHANNEL from '@salesforce/messageChannel/OfferApplyMessageChannel__c';

import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import SELECTED_CAMPAIGN_FIELD from '@salesforce/schema/Opportunity.HL_Selected_Campaign__c';
import NAME_FIELD from '@salesforce/schema/Campaign.Name';
import DESC_FIELD from '@salesforce/schema/Campaign.Description';
import ROI_FIELD from '@salesforce/schema/Campaign.HL_Impact_on_ROI__c';
import FEE_FIELD from '@salesforce/schema/Campaign.HL_Impact_on_Processing_Fee__c';
import START_DATE_FIELD from '@salesforce/schema/Campaign.HL_Campaign_Start_Date_Time__c';
import END_DATE_FIELD from '@salesforce/schema/Campaign.HL_Campaign_End_Date_Time__c';

const OFFER_COLUMNS = [ 
    { label: 'Offer Name', fieldName: NAME_FIELD.fieldApiName, type: 'text' },
    { label: 'Description', fieldName: DESC_FIELD.fieldApiName, type: 'text', wrapText: true },
    { 
        label: 'Reduction in ROI% Impact', 
        fieldName: 'formattedRoi',
        type: 'text',
        cellAttributes: { alignment: 'center' }
    },
    { 
        label: 'Processing Fee Impact', 
        fieldName: FEE_FIELD.fieldApiName, 
        type: 'number',
        cellAttributes: { alignment: 'center' }
    },
    { 
        label: 'Start Date', 
        fieldName: START_DATE_FIELD.fieldApiName, 
        type: 'date',
        typeAttributes: {
            day: '2-digit', month: '2-digit', year: 'numeric',
            hour: '2-digit', minute: '2-digit', hour12: true
        } 
    },
    { 
        label: 'End Date', 
        fieldName: END_DATE_FIELD.fieldApiName, 
        type: 'date',
        typeAttributes: {
            day: '2-digit', month: '2-digit', year: 'numeric',
            hour: '2-digit', minute: '2-digit', hour12: true
        } 
    },
];

export default class hl_ApplicableOffersCmp extends LightningElement {
    // --- Using private _recordId for setter fix ---
    _recordId;
    @api 
    set recordId(value) {
        this._recordId = value;
        console.log('hl_applicableOffers: recordId SETTER fired. Value =', value);
    }
    get recordId() {
        return this._recordId;
    }
    
    @track offers = [];
    @track columns = OFFER_COLUMNS;
    @track error;
    @track selectedCampaignId = null;
    @track allOffersData = [];
    @track isSaving = false;
    @track selectedRows = [];
    
    isLoading = false;
    showOffersList = false; // This now controls the list visibility for BOTH stages
    currentStage;
    hasApplicableCampaigns = false;
    savedCampaignId = null;

    @wire(MessageContext)
    messageContext;

    // ---- GETTERS FOR DYNAMIC UI ----

    get isSalesLoginStage() {
        return this.currentStage && this.currentStage.trim() === 'Sales login';
    }

    get isPSVStage() {
        return this.currentStage && this.currentStage.trim() === 'PSV';
    }

    /** Show "View" button for both stages, but only if list is hidden. */
    get showViewButton() {
        // --- LOGIC UPDATED ---
        return (this.isPSVStage || this.isSalesLoginStage) && this.hasApplicableCampaigns && !this.showOffersList;
    }

    /** Show "Close" button for both stages, but only if list is visible. */
    get showCloseButton() {
        // --- NEW GETTER ---
        return this.hasApplicableCampaigns && this.showOffersList;
    }

    /** Show the datatable only if the button has been clicked AND we have offers. */
    get showOfferListContainer() {
        // --- LOGIC UPDATED ---
        return this.showOffersList && this.offers.length > 0;
    }

    /** "Apply/Remove" buttons still only show in PSV. */
    get showApplyButton() {
        return this.isPSVStage && this.showOffersList;
    }
    
    /** Disable "Remove" button if nothing is saved. */
    get disableRemoveButton() {
        return this.isSaving || !this.savedCampaignId;
    }

    /** Datatable is read-only in 'Sales login'. */
    get datatableMaxRows() {
        return this.isPSVStage ? '1' : '0';
    }

    // ---- WIRE METHODS ----

    @wire(getRecord, { recordId: '$_recordId', fields: [STAGE_FIELD, SELECTED_CAMPAIGN_FIELD] })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.currentStage = getFieldValue(data, STAGE_FIELD);
            this.savedCampaignId = getFieldValue(data, SELECTED_CAMPAIGN_FIELD);
            
            if (this.savedCampaignId) {
                this.selectedRows = [this.savedCampaignId];
                this.selectedCampaignId = this.savedCampaignId;
            }
            
            // --- REMOVED auto-load logic for Sales Login ---
            
        } else if (error) {
            console.error('Error getting opportunity data:', error);
            this.error = 'Could not load opportunity details.';
        }
    }

    @wire(checkApplicableCampaigns, { opportunityId: '$_recordId' })
    wiredCampaignCheck({ error, data }) {
        if (data === true) {
            this.hasApplicableCampaigns = true;
            // --- REMOVED auto-load logic for Sales Login ---
        } else if (data === false) {
            this.hasApplicableCampaigns = false;
        } else if (error) {
            console.error('Error checking for campaigns:', error);
            this.error = 'Could not check for applicable campaigns.';
        }
    }

    // ---- HANDLER METHODS ----

    handleShowOffersClick() {
    this.error = undefined; // clear previous errors
    this.isLoading = true;  // show spinner

    // Prepare input map for Apex method
    const inputMap = { oppId: this._recordId };

    getProductDetails({ inputMap })
        .then(result => {
            this.isLoading = false; // stop spinner

            if (!result || !result.isHLRelated) {
                // Not a Home Loan product → show error and do not load offers
                this.error = 'Offers can be applied only for Home Loan products.';
                this.showOffersList = false;
                return;
            }

            // Product is Home Loan → proceed
            this.showOffersList = true;
            this.loadOffers();
        })
        .catch(error => {
            this.isLoading = false;
            this.error = 'Product check failed. Please try again.';
            console.error('Error fetching product details:', error);
        });
}

    /** Renamed - Now used by both stages. */
    handleShowOffersClick() {
        this.showOffersList = true; // Flag that button was clicked
        this.loadOffers();
    }

    /** New handler for the "Close List" button. */
    handleCloseOffersClick() {
        this.showOffersList = false;
        this.offers = []; // Clear data to hide table
        this.error = undefined;
        this.isLoading = false;
    }

    /** Re-usable function to fetch offers from Apex. */
    loadOffers() {
        this.isLoading = true;
        this.error = undefined; 

        getCampaignOffers({ opportunityId: this._recordId })
            .then(result => {
                if (result.length > 0) {
                    this.allOffersData = result; 
                    const roiFieldApiName = ROI_FIELD.fieldApiName;
                    
                    let processedOffers = result.map(offer => { 
                        let newOffer = { ...offer }; 
                        const roiValue = newOffer[roiFieldApiName];

                        // Create formatted text for "(-20%)"
                        if (roiValue != null && roiValue > 0) {
                            newOffer.formattedRoi = `(-${roiValue}%)`;
                        } else if (roiValue != null) {
                            newOffer.formattedRoi = `${roiValue}%`;
                        } else {
                            newOffer.formattedRoi = '';
                        }
                        return newOffer;
                    });
                    
                    this.offers = processedOffers;
                    
                    if (this.savedCampaignId) {
                        this.selectedRows = [this.savedCampaignId];
                        this.selectedCampaignId = this.savedCampaignId;
                    }
                } else {
                    this.error = 'No active offers were found for this branch.';
                    this.offers = []; 
                }
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching offers:', error);
                this.error = 'An error occurred while fetching offers.';
                this.isLoading = false; 
            });
    }

    /** (PSV Stage) Stores the selected row ID. */
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.selectedCampaignId = selectedRows[0].Id;
        } else {
            this.selectedCampaignId = null;
        }
    }

    /** (PSV Stage) Saves the offer and PUBLISHES the LMS message. */
    handleApplyOffer() {
        if (!this.selectedCampaignId) {
            this.error = 'Please select an offer to apply.';
            return;
        }
        
        this.isSaving = true;
        this.error = undefined;

        const selectedOffer = this.allOffersData.find(
            offer => offer.Id === this.selectedCampaignId
        );
        if (!selectedOffer) { /* ... (error handling) ... */ return; }

        const roiFieldApiName = ROI_FIELD.fieldApiName;
        const feeFieldApiName = FEE_FIELD.fieldApiName;
        const roiImpactValue = selectedOffer[roiFieldApiName];
        const feeImpactValue = selectedOffer[feeFieldApiName];

        saveSelectedOffer({
            opportunityId: this._recordId,
            campaignId: selectedOffer.Id,
            roiImpact: roiImpactValue,
            feeImpact: feeImpactValue
        })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Offer applied and saved to the loan application.',
                    variant: 'success',
                })
            );

            // Publish message to pricingApproval
            const payload = { 
                roiImpact: roiImpactValue, 
                feeImpact: feeImpactValue 
            };
            // publish(this.messageContext, OFFER_APPLY_CHANNEL, payload);

            this.isSaving = false;
            this.savedCampaignId = this.selectedCampaignId;
            this.selectedRows = [this.selectedCampaignId];
        })
        .catch(error => {
            this.error = 'Error saving offer: ' + (error.body ? error.body.message : error.message);
            this.isSaving = false; 
        });
    }

    /** (PSV Stage) Removes the offer and PUBLISHES a null message. */
    handleRemoveOffer() {
        this.isSaving = true;
        this.error = undefined;

        removeSelectedOffer({ opportunityId: this._recordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Offer removed from the loan application.',
                        variant: 'success',
                    })
                );

                // Publish a "null" message to reset the pricing table
                const payload = { roiImpact: null, feeImpact: null };
                // publish(this.messageContext, OFFER_APPLY_CHANNEL, payload);

                // Reset local state
                this.isSaving = false;
                this.savedCampaignId = null;
                this.selectedCampaignId = null;
                this.selectedRows = [];
            })
            .catch(error => {
                this.error = 'Error removing offer: ' + (error.body ? error.body.message : error.message);
                this.isSaving = false;
            });
    }
}