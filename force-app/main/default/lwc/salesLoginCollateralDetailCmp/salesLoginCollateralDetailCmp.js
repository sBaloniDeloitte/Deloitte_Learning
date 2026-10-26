import { LightningElement, track, wire, api } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import COLLATERAL_OBJECT from '@salesforce/schema/Collateral__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import APF_FIELD from '@salesforce/schema/Collateral__c.APF__c';
import ADDRESS_TYPE_FIELD from '@salesforce/schema/Collateral__c.Address_Type__c';
import CONSTRUCTION_STAGE_FIELD from '@salesforce/schema/Collateral__c.Construction_Stage__c';
import MORTGAGE_TYPE_FIELD from '@salesforce/schema/Collateral__c.Mortgage_Type__c';
import ASSET_TYPE_FIELD from '@salesforce/schema/Collateral__c.Asset_Collateral__c';
import UNIT_PROPERTY_TYPE_FIELD from '@salesforce/schema/Collateral__c.Unit_Property_Type__c';
import PROPERTY_USAGE_FIELD from '@salesforce/schema/Collateral__c.Property_Usage__c';
import GPL_FLAG_FIELD from '@salesforce/schema/Collateral__c.GPL_Flag__c';

import INSURANCE_FLAG_FIELD from '@salesforce/schema/Collateral__c.Property_Insurance_Flag__c';
import OCCUPANCY_SINCE_FIELD from '@salesforce/schema/Collateral__c.Occupancy_Since__c';
import COLLATERAL_TYPE_FIELD from '@salesforce/schema/Collateral__c.Collateral_Type__c';
import CURRENT_USAGE_FIELD from '@salesforce/schema/Collateral__c.Current_Usage__c';
import getApplicants from "@salesforce/apex/Utility.getApplicant";
const FIELDS = ['Opportunity.Requested_Amount__c', 'Opportunity.StageName'];
import getPincodeDetails from '@salesforce/apex/COMM_SalesCollateralDetailsController.getPincodeDetails';
import getCollateralRecordsByLoanAppId from '@salesforce/apex/COMM_SalesCollateralDetailsController.getCollateralRecordsByLoanAppId';
import upsertCollateralAndApplicationCollateral from '@salesforce/apex/COMM_SalesCollateralDetailsController.upsertCollateralAndApplicationCollateral';
import getBuilderProjects from '@salesforce/apex/COMM_SalesCollateralDetailsController.getBuilderProjects';
import getUnitsByProjectAndSearch from '@salesforce/apex/COMM_SalesCollateralDetailsController.getUnitsByProjectAndSearch';
import hasBuildingsForProject from '@salesforce/apex/COMM_SalesCollateralDetailsController.hasBuildingsForProject';
import getBuildingsByProjectId from '@salesforce/apex/COMM_SalesCollateralDetailsController.getBuildingsByProjectId';
import initiateAPIRequest from '@salesforce/apex/COMM_CollateralDedupFindAllcteController.initiateAPIRequest';
import initiateAssignUPIDRequest from '@salesforce/apex/COMM_CollateralDeduAssignUPIDController.initiateAPIRequest';
import getUserRole from '@salesforce/apex/Hl_CovenantsDetailFormController.getUserRole';
import createDocumentDetails from '@salesforce/apex/COMM_SalesCollateralDetailsController.createDocumentDetails';
import createContentVersion from '@salesforce/apex/COMM_SalesCollateralDetailsController.createContentVersion';
import { createRecord, updateRecord, getRecord } from "lightning/uiRecordApi";
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
//HL-Ishi-10/10
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import delinkCollateral from '@salesforce/apex/COMM_SalesCollateralDetailsController.delinkCollateral';
import checkDelinkAccess from '@salesforce/apex/COMM_SalesCollateralDetailsController.checkDelinkAccess';

import IS_PROPERTY_IDENTIFIED from '@salesforce/schema/Opportunity.Is_Property_Identified__c';

//HL-Ishi--10/10
import downloadDocumentDetails from '@salesforce/apex/COMM_SalesCollateralDetailsController.downloadDocumentDetails';

import initiateDummyAPIRequest from '@salesforce/apex/COMM_CollateralDedupFindAllcteController.initiateDummyAPIRequest';
export default class SalesLoginCollateralDetailsCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isloading = false;
    @track towerName = '';
    @track hasBuildings = false;
    @track isDedupeLoading = false;
    @track reason = '';
    @track msgScreen = true;
    @track showNext = false;
    @track collateralList = [];
    @track filteredProjectList = [];
    @track filteredPincodeList = [];
    @track isEditMode = false;
    @track editingCollateralId = null;
    @track projectSearchKey = '';
    @track filteredProjectList = [];
    @track unitSearchKey = '';
    @track filteredUnitList = [];
    @track upid = null;
    @track records = [];
    @track error = null;
    @track selectedUpid = null;
    @track showCollateralMatchesScreen = false;
    @track modalHeader = '';
    @track showConfirmation = false;
    @track collateralBackup = {};
    @track isReasonDisabled = false;
    @track uniqueRequestId = '';
    @track externalId = '';
    @track plfId = '';
    @track selectedExternalId = '';
    @track towerSearchKey = '';
    @track filteredTowerList = [];
    @track towerId = '';
    @track unitSearchKey = '';
    @track filteredUnitList = [];
    @track showUnitField = false;
    @track creditStage = false;
    @track collateral = {
        Id: null,
        appAddId: null,
        projId: null,
        devId: null,
        unitId: null,
        name: '',
        address1: '',
        address2: '',
        address3: '',
        plfId: '',
        city: '',
        state: '',
        country: '',
        pincode: '',
        assignPercentage: '',
        // assignedCollateralValue:'',
        assignPercentageMatch: '',
        addressType: '',
        block: '',
        projName: '',
        devName: '',
        projectId: '',
        developerId: '',
        unitType: '',
        towerName: '',
        floor: '',
        unitNumber: null,
        constructionStage: '',
        allowMultiAssignment: false,
        allowThirdPartyAssignment: false,
        ownershipType: '',
        occupancyType: '',
        occupancySince: '',
        propertyUsage: '',
        currentUsage: '',
        reraEndDate: null,
        estimatedValue: null,
        marketValue: null,
        areaOfPlot: null,
        carpetArea: null,
        addPincode: '',
        reraRegNumber: '',
        plotNumber: '',
        housePlotNo: '',
        surveyNumber: '',
        mortgageType: '',
        assetType: '',
        pocket: '',
        streetName: '',
        buildingName: '',
        gplFlag: '',
        insuranceFlag: '',

        apfValue: '',
        unitName: '',
        collateralType: '',
        primarySecondary: '',
        upid: '',
        reason: '',
        loanId: '',
        matchFound: '',
        apfNumber: '',
        costOfPlot: null,
        improvementCost: null,
        agreementValue: null,
        societyCharges: null,
        electricityMunicipleCharges: null,
        architectsEstimate: null,
        amenitiesPermitPolicy: null,
        others: null,
        totalPropertyCost: null,
        docVal: null
    };
    acceptedFormats = ".png,.jpeg,.jpg,.pdf,.xlsx,.msg,.docx,.zip";


    showConfirmation1 = false;
    delinkRowId = '';
    showDelinkButton = false;
    @track isModalOpen = false;
    @track showReraEndDate = false;
    @track totalRequestedLoanAmount;
    @track isVisible = true;
    @track showAPFSelection = true;
    @track showDedupeAPI = false;
    @track showAssignUPID = false;
    @track showFieldSections = false;
    @track applicantOptions = [];
    @track selectedApplicants = [];
    @track showApplicantList = false;
    @track selectedApplicants = [];

    @track apfOptions = [];
    @track propertyUsageOptions = [];
    @track collateralTypeOptions = [];
    @track currentUsageOptions = [];
    @track addressTypeOptions = [];
    @track mortgageTypeOptions = [];
    @track assetTypeOptions = [];
    @track constructionStageOptions = [];
    @track gplFlagOptions = [];

    @track insuranceFlagOptions = [];
    @track occupancySinceOptions = [];
    @track propertyTypeOptions = [];
    @track projectOptions = [];
    @track projectValue;
    @track showAPFFields = false;
    @track showAPFReraEndDate = false;
    @track isPropertyIdentified = true;
    @track isPropertyIdentifiedVal;

    @track recordTypeId;
    //HL-Ishi
    documentList = [];
    showDocumentList = false;
    selectedDocId;
    showUploadModal;
    showPreviewModal;
    selectedDocName;
    contentVersionId;
    contentDocId;
    uploadedDocs = '';
    dataType;
    fileName;
    prodName;
    //HL-Ishi-25/9/2025
    isHLUser = false;
    isFlexiLoan = false;
    //HL-Ishi-25/9/2025
    //HL-Ishi
    @track disabledCmp = false;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [IS_PROPERTY_IDENTIFIED]
    })
    wiredOpp({ error, data }) {
        if (data) {
            this.isPropertyIdentifiedVal = data.fields.Is_Property_Identified__c.value;
            console.log('isPropertyIdentifiedVal:', this.isPropertyIdentifiedVal);

            // If property is already identified, skip the "Is Property Identified?" screen
            if (this.isPropertyIdentifiedVal === 'Yes') {
                this.isPropertyIdentified = false;
                this.showAPFSelection = true;
            }
        } else if (error) {
            console.error('Error:', error);
        }
    }

    @wire(getObjectInfo, { objectApiName: COLLATERAL_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            console.error('Error loading object info:', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: APF_FIELD })
    wiredAPF({ error, data }) {
        console.log('recordTypeId -->', this.recordTypeId);
        console.log('data -->', JSON.stringify(data));
        console.log('apfOptions -->', JSON.stringify(data?.values));
        console.log('error -->', JSON.stringify(error));

        if (data) {
            console.log('OUTPUT 247: ', data);
            this.apfOptions = data.values;
            console.log('OUTPUT 249: ', this.apfOptions);
        } else if (error) {
            console.error('Error loading APF picklist values:', error);
            console.error('ERROR', error);
            console.error('ERROR BODY', error.body);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: PROPERTY_USAGE_FIELD })
    wiredPROPERTY({ error, data }) {
        if (data) {
            this.propertyUsageOptions = data.values;
        } else if (error) {
            console.error('Error loading Property picklist values:', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: MORTGAGE_TYPE_FIELD })
    wiredMORTGAGE({ error, data }) {
        if (data) {
            this.mortgageTypeOptions = data.values;
        } else if (error) {
            console.error('Error loading Property picklist values:', error);
        }
    }


    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: ASSET_TYPE_FIELD })
    wiredASSET({ error, data }) {
        if (data) {
            this.assetTypeOptions = data.values;
        } else if (error) {
            console.error('Error loading Property picklist values:', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: CURRENT_USAGE_FIELD })
    wiredCURRENT({ error, data }) {
        if (data) {
            let options = data.values;
            console.log('Original Current Usage options', options);
            console.log('isHLUser value', this.isHLUser);
            // If not HL user, filter out the two values
            if (!this.isHLUser) {
                options = options.filter(opt =>
                    opt.value !== 'SELLER OCCUPIED' && opt.value !== 'SELF OCCUPIED RESIDENTIAL'
                );
            }
            this.currentUsageOptions = options;
            console.log('Filtered Current Usage options', options);
        } else if (error) {
            console.error('Error loading Current Usage picklist values:', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: COLLATERAL_TYPE_FIELD })
    wiredCOLLATERAL({ error, data }) {
        if (data) {
            this.collateralTypeOptions = data.values;
        } else if (error) {
            console.error('Error loading Collateral Type picklist values:', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: OCCUPANCY_SINCE_FIELD })
    wiredOccupancySince({ error, data }) {
        if (data) {
            this.occupancySinceOptions = data.values;
        } else if (error) {
            console.error('Error loading occupancySinceOptions picklist values:', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: ADDRESS_TYPE_FIELD })
    wiredAddressType({ error, data }) {
        if (data) {
            this.addressTypeOptions = data.values;
        } else if (error) {
            console.error('Error loading Address Type picklist values:', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: CONSTRUCTION_STAGE_FIELD })
    wiredConstructionStage({ error, data }) {
        if (data) {
            this.constructionStageOptions = data.values;
        } else if (error) {
            console.error('Error loading Construction Stage picklist values:', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: GPL_FLAG_FIELD })
    wiredGPLFlag({ error, data }) {
        if (data) {
            this.gplFlagOptions = data.values;
        } else if (error) {
            console.error('Error loading GPL Flag picklist values:', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: INSURANCE_FLAG_FIELD })
    wiredInsuranceFlag({ error, data }) {
        if (data) {
            this.insuranceFlagOptions = data.values;
        } else if (error) {
            console.error('Error loading Insurance Flag picklist values:', error);
        }
    }


    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: UNIT_PROPERTY_TYPE_FIELD })
    wiredPropertyType({ error, data }) {
        if (data) {
            this.propertyTypeOptions = data.values;
        } else if (error) {
            console.error('Error loading Occupancy Since picklist values:', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredOpportunity({ data, error }) {
        if (data) {
            if (data.fields.Requested_Amount__c) {
                this.totalRequestedLoanAmount = data.fields.Requested_Amount__c.value;
            }
            if (data.fields.StageName) {
                this.creditStage = data.fields.StageName.value == 'Credit Underwriting' ? true : false;
            }
            console.log('this.totalRequestedLoanAmount---', this.totalRequestedLoanAmount);
        } else if (error) {
            console.error('Error fetching loan record:', error);
        }
    }


    isProphandleInputChange(event) {

        let value = (event.detail && event.detail.value !== undefined) ? event.detail.value : event.target.value;
        console.log(value);
        try {
            if (value == 'Yes') {


                this.isPropertyIdentifiedVal = value;
                console.log(this.isPropertyIdentifiedVal);
                const fields = {};
                fields['Id'] = this.recordId;
                fields['Is_Property_Identified__c'] = this.isPropertyIdentifiedVal;

                const recordInput = { fields };

                updateRecord(recordInput)
                    .then(() => {
                        console.log('✅ Record updated successfully');
                        /*
                        // Optional: show toast
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Property field updated',
                                variant: 'success'
                            })
                        );*/
                    })
                    .catch(error => {
                        console.error('Error updating record', error);
                    });



                this.showAPFSelection = true;
                this.isPropertyIdentified = false;

            } else {
                this.isPropertyIdentifiedVal = value;

                const fields = {};
                fields['Id'] = this.recordId;
                fields['Is_Property_Identified__c'] = this.isPropertyIdentifiedVal;

                const recordInput = { fields };

                updateRecord(recordInput)
                    .then(() => {
                        console.log('✅ Record updated successfully');
                        /*
                        // Optional: show toast
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Property field updated',
                                variant: 'success'
                            })
                        );*/
                    })
                    .catch(error => {
                        console.error('Error updating record', error);
                    });

                this.isModalOpen = false;
                this.showAPFSelection = false;
            }
        }
        catch (e) {
            console.log(e.message);
        }
    }
    connectedCallback() {
        if (this.recordId != null) {
            this.getCollateral();
            this.getProductDetails();
            this.createDocumentDetails();
        }

        getUserRole({ recordId: this.recordId })
            .then(result => {
                if (result) {
                    this.isVisible = false;
                }
            })

        checkDelinkAccess({ loanId: this.recordId })
            .then(result => {
                this.showDelinkButton = result;
            })
        this.checkCmpEditability();
    }

    checkCmpEditability() {
        getComponentEditability({ loanId: this.recordId, component: '' })
            .then(result => {
                if (result) {
                    this.disabledCmp = result;
                    console.log('this.hideButton>>>>' + this.hideButton);
                }
            })
            .catch(error => {
                console.log('Error getComponentEditability:  ' + error);
            });
    }

    renderedCallback() {
        if (this.isModalOpen) {
            setTimeout(() => {
                const modal = this.template.querySelector('.slds-modal__container');
                if (modal) {
                    modal.scrollIntoView({ behavior: 'smooth', block: 'center' });
                } else {
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                }
            }, 300);
        }
        const style = document.createElement('style');
        style.innerText = `
            .uploadFile .slds-file-selector__text.slds-medium-show {
              display: none;
          }
          .uploadFile .slds-file-selector__button.slds-button.slds-button_neutral{
            font-size: 0!important;
          }
          .uploadFile svg.slds-button__icon.slds-button__icon_left {
              margin: 0;
          }
        .uploadFile lightning-primitive-file-droppable-zone.slds-file-selector__dropzone {
              border: none;
          }
          .uploadFile slds-form-element__label{
            display: none;
            }
            .uploadFile slds-form-element__control{
                margin-left:20%;
            }
            .info-button svg.slds-button__icon.slds-button__icon_left {
              margin: 0;
          }
          .uploaded-view svg.slds-button__icon {
            color: green;
        }
            .inputSize .slds-form-element__label{
               
            }
            .navClass .slds-progress-bar__value{
                background: #1589ee;
            }
                .instruction-box-nav.slds-progress-bar__value{
                background: #1589ee;
            }

            /* Dark theme for nested Lightning base components, scoped to this component only.
               Input/combobox fill+border are handled by the :host SLDS styling hooks and
               ::part(input) rules in the .css file - only cover what those hooks don't
               reach (icons, disabled state, edit/delink buttons, file upload, accordion). */
            .collateral-dark-theme lightning-input .slds-input[disabled],
            .collateral-dark-theme lightning-combobox .slds-input[disabled] {
                background-color: #0e1c30 !important;
                color: #8a99b3 !important;
            }
            .collateral-dark-theme lightning-combobox .slds-icon,
            .collateral-dark-theme lightning-input .slds-icon {
                fill: #cfd8e6 !important;
            }
            .collateral-dark-theme lightning-button.edit-cta .slds-button_neutral {
                background-color: transparent !important;
                border-color: #ffffff !important;
                color: #ffffff !important;
                border-radius: 1.25rem !important;
                font-weight: 600 !important;
            }
            .collateral-dark-theme lightning-button.delink-cta .slds-button_neutral {
                background-color: transparent !important;
                border-color: #ffffff !important;
                color: #ffffff !important;
                border-radius: 1.25rem !important;
                font-weight: 600 !important;
            }
            .collateral-dark-theme lightning-file-upload .slds-file-selector__dropzone {
                background-color: #0e1c30 !important;
                border-color: #33455e !important;
            }
            .collateral-dark-theme lightning-file-upload .slds-file-selector__body,
            .collateral-dark-theme lightning-file-upload .slds-form-element__label {
                color: #ffffff !important;
            }
            .collateral-dark-theme lightning-accordion-section .slds-accordion__summary-heading,
            .collateral-dark-theme lightning-accordion-section .slds-accordion__summary-content {
                color: #ffffff !important;
            }
            .collateral-dark-theme lightning-accordion-section .slds-accordion__section {
                background-color: #0e1c30 !important;
                border-color: #1589ee !important;
            }

            /* lightning-combobox/lightning-select internals - ::part() support for
               these varies by base component version, so fall back to reaching
               their shadow-rendered markup directly, same technique used on
               covenantsDetailForm_hl. Covers both the closed input and the open
               dropdown listbox, which otherwise renders with the SLDS default
               white background. */
            .collateral-dark-theme lightning-select .slds-select,
            .collateral-dark-theme lightning-combobox .slds-combobox__input {
                background-color: #16283f !important;
                border-color: #33455e !important;
                color: #ffffff !important;
                height: 2.25rem !important;
            }
            .collateral-dark-theme lightning-combobox .slds-dropdown,
            .collateral-dark-theme lightning-combobox .slds-dropdown__list,
            .collateral-dark-theme lightning-combobox .slds-listbox_vertical {
                background-color: #16283f !important;
                border-color: #33455e !important;
            }
            .collateral-dark-theme lightning-combobox .slds-listbox__option,
            .collateral-dark-theme lightning-combobox .slds-listbox__item {
                background-color: #16283f !important;
                color: #ffffff !important;
            }
            .collateral-dark-theme lightning-combobox .slds-listbox__option:hover,
            .collateral-dark-theme lightning-combobox .slds-listbox__option:focus,
            .collateral-dark-theme lightning-combobox .slds-listbox__option.slds-has-focus,
            .collateral-dark-theme lightning-combobox .slds-listbox__option[aria-selected="true"] {
                background-color: #1f3550 !important;
                color: #ffffff !important;
            }
            `;
        this.template.querySelector('.styleContainer').appendChild(style);
        this.spinnerClass = 'spinner-medium';
    }


    handleNavigateNext() {
        console.log('218');
        this.dispatchEvent(new CustomEvent('navigatetonexttab', {
            detail: 'Other Information'
        }));
    }

    handleAddNewCollateral() {

        console.log('recordTypeId', this.recordTypeId);
        console.log('apfOptions', this.apfOptions);

        this.isModalOpen = true;
        const cleanedCollateral = this.cleanCollateralForApex();
        const collateralJson = JSON.stringify(cleanedCollateral);
        console.log('Final Collateral JSON -->', collateralJson);
        this.createDocumentDetails();
        this.showAPFSelection = true;
        this.showApplicantList = false;
        this.showFieldSections = false;
        this.showDedupeAPI = false;
        this.showAssignUPID = false;
        this.showAPFFields = false;
        this.msgScreen = false;
        this.isEditMode = false;
        this.showCollateralMatchesScreen = false;
        this.modalHeader = 'Add New Collateral';
        this.showNext = false;
        this.filteredTowerList = [];

        const isFirstRecord = this.collateralList.length === 0;

        // ✅ Initialize collateral with ALL fields
        this.collateral = {
            Id: null,
            appAddId: null,
            projId: null,
            devId: null,
            unitId: null,
            name: '',
            address1: '',
            address2: '',
            address3: '',
            city: '',
            state: '',
            country: '',
            pincode: '',
            addPincode: '',
            addressType: '',
            plfId: '',
            block: '',
            projName: '',
            devName: '',
            unitType: '',
            towerName: '',
            assignPercentage: '',
            assignPercentageMatch: '',
            //assignedCollateralValue:'',
            plotNumber: '',
            housePlotNo: '',
            surveyNumber: '',
            mortgageType: '',
            assetType: '',
            pocket: '',
            streetName: '',
            buildingName: '',
            floor: '',
            unitNumber: null,
            constructionStage: '',
            allowMultiAssignment: false,
            allowThirdPartyAssignment: false,
            ownershipType: '',
            occupancyType: '',
            occupancySince: '',
            propertyUsage: '',
            currentUsage: '',
            reraEndDate: '',
            estimatedValue: null,
            marketValue: null,
            areaOfPlot: null,
            carpetArea: null,
            reraRegNumber: '',
            gplFlag: '',

            collateralType: '',
            insuranceFlag: '',
            apfValue: '',
            upid: '',
            loanId: '',
            reason: '',
            matchFound: '',
            apfNumber: '',
            unitName: '',
            externalId: '',
            primarySecondary: isFirstRecord ? 'Primary' : 'Secondary',
            costOfPlot: null,
            improvementCost: null,
            agreementValue: null,
            societyCharges: null,
            electricityMunicipleCharges: null,
            architectsEstimate: null,
            amenitiesPermitPolicy: null,
            others: null,
            totalPropertyCost: null
        };

        this.collateralBackup = JSON.parse(JSON.stringify(this.collateral));
    }

    handleBlur(event) {
        const field = event.target.dataset.field;
        let value = event.target.value;

        if (event.target.type === 'number' && value) {
            value = parseFloat(value).toFixed(2); // force 2 decimals
            this.collateral = { ...this.collateral, [field]: value };
            event.target.value = value; // update UI
        }
        this.calculateTotalPropertyCost();
    }
    // Handle change for inputs and picklists
    handleInputChange(event) {
        const field = event.target.dataset.field;
        let value;
        if (field === 'buildingName' || field === 'streetName' || field === 'pocket' || field === 'plotNumber' || field === 'housePlotNo' || field === 'surveyNumber') {
            // Allow all characters, but must not start with a special character
            value = event.target.value;
            // Remove leading special characters automatically
            if (value) {
                const newValue = value.replace(/^([^a-zA-Z0-9]+)/, '');
                if (newValue !== value) {
                    event.target.value = newValue;
                    value = newValue;
                    event.target.setCustomValidity('Must not start with a special character');
                } else {
                    event.target.setCustomValidity('');
                }
            } else {
                event.target.setCustomValidity('');
            }
            if (/[:"]/g.test(value)) {
                event.target.setCustomValidity('Colon (:) and double quotes (") are not allowed');
            }
            event.target.reportValidity();
        } else if (field == 'reraEndDate' || field == 'docVal' || field == 'estimatedValue' || field == 'unitType' || field == 'areaOfPlot') {
            value = event.target.value;
        } else {
            // For other fields, sanitize input
            event.target.value = event.target.value.replace(/[^a-zA-Z0-9 ]/g, '');
            value = event.target.value;
        }
        console.log('field--', field);
        console.log('value(before trim)--', value);

        // Trim for string fields
        if (typeof value === 'string') {
            value = value.trim();
        }
        if (field === 'docVal') {
            // Remove commas
            value = value.replace(/,/g, '');
            // Optional: allow only numbers and one decimal point
            value = value.replace(/[^0-9.]/g, '');
            const parts = value.split('.');
            if (parts.length > 2) {
                value = parts[0] + '.' + parts.slice(1).join('');
            }
            event.target.value = value;
        }
        // Update collateral object safely
        this.collateral = { ...this.collateral, [field]: value };

        // --- Inline validations ---
        const minTwoCharFields = ['address1', 'address2', 'address3', 'projName', 'devName'];
        if (minTwoCharFields.includes(field)) {
            if (!value || value.length < 2) {
                event.target.setCustomValidity('Minimum 2 characters required');
            } else if (['address1', 'address2', 'address3'].includes(field) && value.length > 50) {
                event.target.setCustomValidity('Maximum 50 characters allowed');
            } else {
                event.target.setCustomValidity('');
            }
            event.target.reportValidity();
        }

        if (field === 'carpetArea') {
            const carpetAreaRegex = /^\d+(\.\d{1,2})?$/;
            if (value && !carpetAreaRegex.test(value)) {
                event.target.setCustomValidity('Enter positive number with up to 2 decimal places');
            } else {
                event.target.setCustomValidity('');
            }
            event.target.reportValidity();
        }

        if (field === 'surveyNumber') {

            const regex = /^[a-zA-Z0-9 ]+$/;

            if (!regex.test(value)) {
                event.target.setCustomValidity('Special characters are not allowed');
            } else {
                event.target.setCustomValidity('');
            }
            event.target.reportValidity();
        }

        if (field === 'reraRegNumber') {
            const reraRegex = /^[a-zA-Z0-9]{15,20}$/;
            if (value && !reraRegex.test(value)) {
                event.target.setCustomValidity('RERA Registration Number must be 15-20 alphanumeric characters');
            } else {
                event.target.setCustomValidity('');
            }
            event.target.reportValidity();
        }

        if (field === 'apf') {
            console.log('APF change detected');
            const prevValue = this.collateral.apfValue;
            this.collateral.apfValue = value;
            this.collateral.reraEndDate = null;
            this.collateral.buildingName = '';
            // Show/hide APF fields based on value
            this.showAPFFields = (value === 'Yes');
            this.showAPFReraEndDate = (value === 'Yes' && this.isHLUser);
            console.log('showAPFReraEndDate----', this.showAPFReraEndDate);
            // If APF value changed, reset other fields
            if (prevValue !== value) {
                for (let key in this.collateral) {
                    if (key !== 'apfValue' && key !== 'primarySecondary') {
                        this.collateral[key] = '';
                    }
                }
            }
        }

        if (field === 'occupancySince') {
            const currentYear = new Date().getFullYear();
            const numericValue = parseInt(value, 10);

            if (numericValue > currentYear) {
                event.target.setCustomValidity(`Year cannot be greater than ${currentYear}`);
            } else {
                event.target.setCustomValidity('');
            }
            event.target.reportValidity();
        }

        if (field === 'assignPercentage') {
            const percentageVal = parseFloat(value);
            if (!value) {
                event.target.setCustomValidity('Assign Percentage is required');
            } else if (isNaN(percentageVal) || percentageVal < 0 || percentageVal > 100) {
                event.target.setCustomValidity('Assign Percentage must be a number between 0 and 100');
            } else {
                event.target.setCustomValidity('');
            }
            event.target.reportValidity();
        }
        if (field === 'constructionStage') {
            this.showReraEndDate = (value.toLowerCase() == 'under construction' && this.isHLUser && this.collateral?.apfValue === 'No');
        }
    }

    calculateTotalPropertyCost() {
        const costFields = [
            'costOfPlot',
            'improvmentCost',
            'agreementValue',
            'societyCharges',
            'electricityMunicipleCharges',
            'architectsEstimate',
            'amenitiesPermitPolicy',
            'others'
        ];

        let total = 0;
        costFields.forEach(field => {
            const val = parseFloat(this.collateral[field]);
            if (!isNaN(val)) {
                total += val;
            }
        });

        // ✅ Always store with 2 decimal places
        this.collateral = {
            ...this.collateral,
            totalPropertyCost: total.toFixed(2)
        };
    }

    handlePincodeChange(event) {
        const searchKey = event.detail.value;
        this.collateral.pincode = searchKey;

        if (searchKey.length >= 3) {
            getPincodeDetails({ pinCodeFragment: searchKey })
                .then(result => {
                    this.filteredPincodeList = result || [];
                })
                .catch(error => {
                    console.error('Pincode search error', error);
                    this.filteredPincodeList = [];
                });
        } else {
            this.filteredPincodeList = [];
        }
    }

    handlePincodeSelect(event) {
        const selectedId = event.target.dataset.id;
        const selectedPincode = this.filteredPincodeList.find(pin => pin.Id === selectedId);

        if (selectedPincode) {
            this.collateral.city = selectedPincode.City__r?.Name || '';
            this.collateral.state = selectedPincode.City__r?.State__c || '';
            this.collateral.country = selectedPincode.City__r?.Country__c || '';
            this.collateral.addPincode = selectedPincode.Id;
            this.collateral.pincode = selectedPincode.Name;
            this.filteredPincodeList = [];
        }
    }

    handleNext() {
        console.log('350', this.collateral.apfValue);

        if (!this.collateral.apfValue) {
            const apfDropdown = this.template.querySelector('lightning-combobox[name="apf"]');
            if (apfDropdown) {
                apfDropdown.setCustomValidity('Please select an option');
                apfDropdown.reportValidity();
            }
            return;
        }

        if (this.collateral.apfValue === 'No') {
            this.showFieldSections = true;
            this.showAssignUPID = false;
            this.showAPFFields = false;
            this.showAPFSelection = false;
            this.showDedupeAPI = true;
        }
        else if (this.collateral.apfValue === 'Yes') {
            if (!this.validateAllFields()) {
                return;
            }
            console.log('368', this.isEditMode);
            console.log('369', this.collateral.projName);
            console.log('370', this.collateral.unitNumber);
            console.log('372');

            this.showFieldSections = true;
            this.showAssignUPID = false;
            this.showAPFSelection = false;

            // ✅ If edit mode → skip dedupe API
            this.showDedupeAPI = true;
            this.createDocumentDetails();
        }

        this.showNext = !!this.collateral.upid;
    }

    handleBack() {
        if (this.collateral.apfValue === 'No') {
            if (this.showApplicantList) {
                this.collateralBackup = JSON.parse(JSON.stringify(this.collateral));
                this.showApplicantList = false;
                this.showFieldSections = true;
                this.showCollateralMatchesScreen = this.collateral.matchFound === 'Yes' ? true : false;
                this.showDedupeAPI = true;
                this.showAssignUPID = false;
                this.showNext = true;
                this.showAPFSelection = false;
            } else if (this.showFieldSections) {
                this.showFieldSections = false;
                this.showDedupeAPI = false;
                this.showCollateralMatchesScreen = false;
                this.showAssignUPID = false;
                this.showAPFSelection = true;
                this.showNext = false;
                this.showApplicantList = false;
            }
        } else if (this.collateral.apfValue === 'Yes') {
            if (this.showApplicantList) {
                this.showFieldSections = true;
                this.showDedupeAPI = true;
                this.showAssignUPID = false;
                this.showAPFFields = true;
                this.showAPFSelection = false;
                this.showApplicantList = false;
                this.showNext = true;
                this.showCollateralMatchesScreen = this.collateral.matchFound === 'Yes' ? true : false;
            } else if (this.showAPFFields) {
                this.showAPFFields = true;
                this.showApplicantList = false;
                this.showFieldSections = false;
                this.showDedupeAPI = false;
                this.showAssignUPID = false;
                this.showAPFSelection = true;
                this.showCollateralMatchesScreen = false;
                this.showNext = false;
            }
        } else {
            this.showAPFSelection = true;
            this.showFieldSections = false;
            this.showDedupeAPI = false;
            this.showAssignUPID = false;
            this.showAPFFields = false;
            this.showApplicantList = false;
            this.showCollateralMatchesScreen = false;
            this.showNext = false;
        }
        console.log('this.showAPFSelection325', this.showAPFSelection);
    }

     getApplicantList() {     
         getApplicants({ recordId: this.recordId })
             .then(response => {
                 this.applicantOptions = response.map(applicant => ({
                     label: applicant.Name,
                     value: applicant.Id,
                     checked: this.selectedApplicants.includes(applicant.Id)
                 }));
                 console.log('applicantOptions----'+this.applicantOptions);
                 console.log('applicantOptions----'+JSON.stringify(this.applicantOptions));
                 this.showApplicantList = true;
                 this.showNext = false;
             })
             .catch(error => {
                 console.error('Error fetching applicants:', error);
             });
     }

    handleCheckboxChange(event) {
        const value = event.target.dataset.value; // record Id or key
        const checked = event.target.checked;

        // Find the corresponding record in applicantOptions
        const selectedRecord = this.applicantOptions.find(opt => opt.value === value);

        if (checked) {
            if (!this.selectedApplicants.includes(value)) {
                this.selectedApplicants = [...this.selectedApplicants, value];
            }
        } else {
            this.selectedApplicants = this.selectedApplicants.filter(v => v !== value);
            // Remove or nullify the mapping when deselected
        }

        // Update applicantOptions checked state
        this.applicantOptions = this.applicantOptions.map(opt => ({
            ...opt,
            checked: this.selectedApplicants.includes(opt.value)
        }));
    }

    validateAllFields() {
        let allValid = true;
        let errorMessages = [];

        console.log('🚀 Starting validation...');
        console.log('🔍 Current collateral object:', JSON.parse(JSON.stringify(this.collateral)));

        // --- Minimum 2 characters fields ---
        const minTwoCharFields = ['address1', 'address2', 'address3', 'projName', 'devName'];
        minTwoCharFields.forEach(field => {
            const inputCmp = this.template.querySelector(`[data-field="${field}"]`);
            const value = this.collateral[field];
            console.log(`Checking ${field}:`, value);

            if (inputCmp) {
                if (!value || String(value).trim().length < 2) {
                    errorMessages.push(`${field} must have at least 2 characters`);
                    inputCmp.setCustomValidity('Minimum 2 characters required');
                    inputCmp.reportValidity();
                    allValid = false;
                    console.warn(`❌ Validation failed for ${field}`);
                } else {
                    inputCmp.setCustomValidity('');
                    inputCmp.reportValidity();
                    console.log(`✅ Validation passed for ${field}`);
                }
            }
        });

        // --- Carpet Area validation ---
        const carpetAreaCmp = this.template.querySelector('[data-field="carpetArea"]');
        const carpetAreaVal = this.collateral.carpetArea;
        console.log('Checking Carpet Area:', carpetAreaVal);
        const carpetAreaRegex = /^\d+(\.\d{1,2})?$/;
        if (carpetAreaCmp && carpetAreaVal !== null && carpetAreaVal !== undefined && carpetAreaVal !== '') {
            if (!carpetAreaRegex.test(String(carpetAreaVal))) {
                errorMessages.push('Carpet Area: Enter positive number with up to 2 decimal places');
                carpetAreaCmp.setCustomValidity('Enter positive number with up to 2 decimal places');
                carpetAreaCmp.reportValidity();
                allValid = false;
                console.warn('❌ Carpet Area validation failed');
            } else {
                carpetAreaCmp.setCustomValidity('');
                carpetAreaCmp.reportValidity();
                console.log('✅ Carpet Area validation passed');
            }
        }

        // --- RERA validation ---
        const reraCmp = this.template.querySelector('[data-field="reraRegNumber"]');
        const reraVal = this.collateral.reraRegNumber;
        const reraRegex = /^[a-zA-Z0-9]{15,20}$/;
        console.log('Checking RERA:', reraVal);
        if (reraCmp && reraVal) {
            if (!reraRegex.test(reraVal)) {
                errorMessages.push('RERA Registration Number must be 15–20 alphanumeric characters');
                reraCmp.setCustomValidity('RERA Registration Number must be 15–20 alphanumeric characters');
                reraCmp.reportValidity();
                allValid = false;
                console.warn('❌ RERA validation failed');
            } else {
                reraCmp.setCustomValidity('');
                reraCmp.reportValidity();
                console.log('✅ RERA validation passed');
            }
        }

        // --- Pincode validation ---
        const pincodeCmp = this.template.querySelector('[data-field="pincode"]');
        const pincodeVal = this.collateral.pincode;
        const pincodeRegex = /^\d{6}$/;
        console.log('Checking Pincode:', pincodeVal);
        if (pincodeCmp) {
            if (!pincodeVal) {
                errorMessages.push('Pincode is required');
                pincodeCmp.setCustomValidity('Pincode is required');
                pincodeCmp.reportValidity();
                allValid = false;
                console.warn('❌ Pincode is missing');
            } else if (!pincodeRegex.test(String(pincodeVal))) {
                errorMessages.push('Pincode must be exactly 6 digits');
                pincodeCmp.setCustomValidity('Pincode must be exactly 6 digits');
                pincodeCmp.reportValidity();
                allValid = false;
                console.warn('❌ Invalid Pincode format');
            } else {
                pincodeCmp.setCustomValidity('');
                pincodeCmp.reportValidity();
                console.log('✅ Pincode validation passed');
            }
        }

        const assetTypeCmp = this.template.querySelector('[data-field="assetType"]');
        const assetTypeVal = this.collateral.assetType;
        if (assetTypeCmp) {
            if (!assetTypeVal) {
                errorMessages.push('Asset Type is required.');
                assetTypeCmp.setCustomValidity('Asset Type is required.');
                assetTypeCmp.reportValidity();
                allValid = false;
                console.warn('❌ Asset Type is missing');

            }
        }

        const gplCmp = this.template.querySelector('[data-field="gplFlag"]');
        const gplVal = this.collateral.gplFlag;
        if (gplCmp) {
            if (!gplVal) {
                errorMessages.push('GPL Flag is required.');
                gplCmp.setCustomValidity('GPL Flag is required.');
                gplCmp.reportValidity();
                allValid = false;
                console.warn('❌ GPL Flag is missing');

            }
        }

        // --- surveyNumber validation ---
        const surveyNumberCmp = this.template.querySelector('[data-field="surveyNumber"]');
        const surveyNumberVal = this.collateral.surveyNumber;
        const surRegex = /^[a-zA-Z0-9 ]+$/;
        console.log('Checking surveyNumberVal:', surveyNumberVal);
        if (surveyNumberCmp) {
            // if (!surveyNumberVal) {
            //     errorMessages.push('Survey Number / Gat No.# is required.');
            //     surveyNumberCmp.setCustomValidity('Survey Number / Gat No.# is required.');
            //     surveyNumberCmp.reportValidity();
            //     allValid = false;
            //     console.warn('❌ Survey Number / Gat No.# is missing');
            // } else
            if (surveyNumberVal && !surRegex.test(String(surveyNumberVal))) {
                errorMessages.push('Survey Number / Gat No.# : Special characters are not allowed');
                surveyNumberCmp.setCustomValidity('Special characters are not allowed');
                surveyNumberCmp.reportValidity();
                allValid = false;
                console.warn('❌ Invalid Survey Number format');
            } else {
                surveyNumberCmp.setCustomValidity('');
                surveyNumberCmp.reportValidity();
                console.log('✅ Survey Number validation passed');
            }
        }

        // --- APF Flow: Tower / Unit ---
        if (this.collateral.apfValue === 'Yes') {
            console.log('APF Flow → Checking Tower/Unit');

            if (this.hasBuildings) {
                const towerCmp = this.template.querySelector('[data-field="towerNumber"]');
                console.log('Tower Name:', this.towerName);
                if (towerCmp) {
                    if (!this.towerName || String(this.towerName).trim() === '') {
                        errorMessages.push('Tower is required when building exists');
                        towerCmp.setCustomValidity('Tower is required');
                        towerCmp.reportValidity();
                        allValid = false;
                        console.warn('❌ Tower validation failed');
                    } else {
                        towerCmp.setCustomValidity('');
                        towerCmp.reportValidity();
                        console.log('✅ Tower validation passed');
                    }
                }
            }

            const unitCmp = this.template.querySelector('[data-field="unitNumber"]');
            const unitVal = this.collateral.unitNumber;
            if (unitCmp) {
                if (unitVal === null || unitVal === undefined || String(unitVal).trim().length < 1) {
                    errorMessages.push('Unit is required');
                    unitCmp.setCustomValidity('Unit is required');
                    unitCmp.reportValidity();
                    allValid = false;
                    console.warn('❌ Unit validation failed');
                } else {
                    unitCmp.setCustomValidity('');
                    unitCmp.reportValidity();
                    console.log('✅ Unit validation passed');
                }
            }
        }

        // --- Assign Percentage ---
        /* const assignCmp = this.template.querySelector('[data-field="assignPercentage"]');
         const assignVal = this.collateral.assignPercentage;
         if (assignCmp) {
             if (assignVal === null || assignVal === undefined || String(assignVal).trim() === '') {
                 errorMessages.push('Assign Percentage is required');
                 assignCmp.setCustomValidity('Assign Percentage is required');
                 assignCmp.reportValidity();
                 allValid = false;
                 console.warn('❌ Assign Percentage validation failed');
             } else {
                 assignCmp.setCustomValidity('');
                 assignCmp.reportValidity();
                 console.log('✅ Assign Percentage validation passed');
             }
         }*/
        // If Under Construction + HL user → RERA End Date required
        if ((this.collateral.constructionStage === 'UNDER CONSTRUCTION' || this.collateral.apfValue == 'Yes') && this.isHLUser) {
            const reraEndCmp = this.template.querySelector('[data-field="reraEndDate"]');
            const reraEndValue = this.collateral.reraEndDate;

            if (reraEndCmp) {
                if (!reraEndValue) {
                    reraEndCmp.setCustomValidity('RERA End Date is required');
                    reraEndCmp.reportValidity();
                    allValid = false;
                    errorMessages.push('RERA End Date is required');
                } else {
                    reraEndCmp.setCustomValidity('');
                    reraEndCmp.reportValidity();
                }
            }
        }

        // --- Estimated Value validation ---
        const estCmp = this.template.querySelector('[data-field="estimatedValue"]');
        const estVal = this.collateral.estimatedValue;
        console.log('Checking Estimated Value:', estVal);

        if (estCmp) {
            const estStr = estVal !== null && estVal !== undefined ? String(estVal).trim() : '';

            if (estStr === '') {
                errorMessages.push('Estimated Value is required');
                estCmp.setCustomValidity('Estimated Value is required');
                estCmp.reportValidity();
                allValid = false;
                console.warn('❌ Estimated Value is missing');
            } else if (!/^\d+(\.\d{1,2})?$/.test(estStr)) {
                errorMessages.push('Estimated Value must be a positive number with up to 2 decimal places');
                estCmp.setCustomValidity('Estimated Value must be a positive number with up to 2 decimal places');
                estCmp.reportValidity();
                allValid = false;
                console.warn('❌ Estimated Value format invalid');
            } else if (isNaN(parseFloat(estStr)) || parseFloat(estStr) <= 0) {
                errorMessages.push('Estimated Value must be a positive number');
                estCmp.setCustomValidity('Estimated Value must be a positive number');
                estCmp.reportValidity();
                allValid = false;
                console.warn('❌ Estimated Value must be positive number');
            } else {
                estCmp.setCustomValidity('');
                estCmp.reportValidity();
                console.log('✅ Estimated Value validation passed');
            }
        }

        if (this.isHLUser && this.creditStage) {
            // --- Document Value validation ---
            const docCmp = this.template.querySelector('[data-field="docVal"]');
            const docVal = this.collateral.docVal;
            console.log('Checking Document Value:', docVal);
            if (docCmp) {
                if (docVal === null || docVal === undefined || String(docVal).trim() === '') {
                    errorMessages.push('Document Value is required');
                    docCmp.setCustomValidity('Document Value is required');
                    docCmp.reportValidity();
                    allValid = false;
                    console.warn('❌ Document Value is missing');
                } else if (isNaN(docVal) || parseFloat(docVal) <= 0) {
                    errorMessages.push('Document Value must be a positive number');
                    docCmp.setCustomValidity('Document Value must be a positive number');
                    docCmp.reportValidity();
                    allValid = false;
                    console.warn('❌ Document Value must be positive number');
                } else {
                    docCmp.setCustomValidity('');
                    docCmp.reportValidity();
                    console.log('✅ Document Value validation passed');
                }
            }
        }

        // --- Area Of Plot (Build up area) validation ---
        const areaCmp = this.template.querySelector('[data-field="areaOfPlot"]');
        const areaVal = this.collateral.areaOfPlot;
        console.log('Checking Build up area:', areaVal);
        if (areaCmp && areaVal !== null && areaVal !== undefined && String(areaVal).trim() !== '') {
            const areaStr = String(areaVal).trim();

            // allow positive number with up to 2 decimal places
            if (!/^\d+(\.\d{1,2})?$/.test(areaStr)) {
                errorMessages.push('Build up area must be a positive number with up to 2 decimal places');
                areaCmp.setCustomValidity('Build up area must be a positive number with up to 2 decimal places');
                areaCmp.reportValidity();
                allValid = false;
                console.warn('❌ Build up area format invalid');
            } else if (isNaN(parseFloat(areaStr)) || parseFloat(areaStr) <= 0) {
                errorMessages.push('Build up area must be greater than 0');
                areaCmp.setCustomValidity('Build up area must be greater than 0');
                areaCmp.reportValidity();
                allValid = false;
                console.warn('❌ Build up area must be greater than 0');
            } else {
                areaCmp.setCustomValidity('');
                areaCmp.reportValidity();
                console.log('✅ Build up area validation passed');
            }
        }

        // --- Market Value validation ---
        /* const marketCmp = this.template.querySelector('[data-field="marketValue"]');
         const marketVal = this.collateral.marketValue;
         console.log('Checking Market Value:', marketVal);
         if (marketCmp) {
             if (marketVal === null || marketVal === undefined || String(marketVal).trim() === '') {
                 errorMessages.push('Market Value is required');
                 marketCmp.setCustomValidity('Market Value is required');
                 marketCmp.reportValidity();
                 allValid = false;
                 console.warn('❌ Market Value is missing');
             } else if (isNaN(marketVal) || parseFloat(marketVal) <= 0) {
                 errorMessages.push('Market Value must be a positive number');
                 marketCmp.setCustomValidity('Market Value must be a positive number');
                 marketCmp.reportValidity();
                 allValid = false;
                 console.warn('❌ Market Value must be a positive number');
             } else {
                 marketCmp.setCustomValidity('');
                 marketCmp.reportValidity();
                 console.log('✅ Market Value validation passed');
             }
         }*/

        // --- Required Fields: constructionStage, unitType, currentUsage, collateralType ---
        let requiredFields = ['constructionStage', 'unitType', 'currentUsage', 'collateralType'];

        // --- Add extra required fields only if creditStage is true ---
        if (this.creditStage && !this.isHLUser) {
            requiredFields = requiredFields.concat([
                'plotNumber',
                'housePlotNo',
                'surveyNumber',
                'pocket',
                'mortgageType',
                'buildingName',
                'streetName'
            ]);
            if (this.isHLUser) {
                requiredFields = requiredFields.concat(['assetType']);
            }
        }
        requiredFields.forEach(field => {
            const inputCmp = this.template.querySelector(`[data-field="${field}"]`);
            const value = this.collateral[field];
            if (inputCmp) {
                if (!value || String(value).trim() === '') {
                    errorMessages.push(`${field} is required`);
                    inputCmp.setCustomValidity(`${field} is required`);
                    inputCmp.reportValidity();
                    allValid = false;
                    console.warn(`❌ Validation failed for ${field}`);
                } else {
                    inputCmp.setCustomValidity('');
                    inputCmp.reportValidity();
                    console.log(`✅ Validation passed for ${field}`);
                }
            }
        });

        // --- Estimated vs Market Value vs Loan Amount validation ---
        if (this.collateral.estimatedValue && this.collateral.marketValue && this.totalRequestedLoanAmount) {
            const estValNum = parseFloat(this.collateral.estimatedValue);
            // const marketValNum = parseFloat(this.collateral.marketValue);
            const loanAmtNum = parseFloat(this.totalRequestedLoanAmount);

            if (estValNum <= loanAmtNum) {
                errorMessages.push('Estimated Value must be greater than Total Requested Loan Amount');
                const estCmp = this.template.querySelector('[data-field="estimatedValue"]');
                if (estCmp) {
                    estCmp.setCustomValidity('Estimated Value must be greater than Total Requested Loan Amount');
                    estCmp.reportValidity();
                }
                allValid = false;
                console.warn('❌ Estimated Value not greater than Loan Amount');
            }

            /* if (marketValNum <= loanAmtNum) {
                 errorMessages.push('Market Value must be greater than Total Requested Loan Amount');
                 const marketCmp = this.template.querySelector('[data-field="marketValue"]');
                 if (marketCmp) {
                     marketCmp.setCustomValidity('Market Value must be greater than Total Requested Loan Amount');
                     marketCmp.reportValidity();
                 }
                 allValid = false;
                 console.warn('❌ Market Value not greater than Loan Amount');
             }*/
        }

        console.log('✅ Validation complete. All valid:', allValid);

       /* if (!allValid && errorMessages.length > 0) {
            console.error('Validation errors:', errorMessages);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: errorMessages.join(' | '),
                    variant: 'error',
                    mode: 'dismissable'
                })
            );
        }*/

        return allValid;
    }

    handleClose() {
        this.isModalOpen = false;
        this.showAPFSelection = true;
        this.showApplicantList = false;
        this.showFieldSections = false;
        this.showDedupeAPI = false;
        this.showAssignUPID = false;
        this.showAPFFields = false;
        this.msgScreen = false;
        this.isEditMode = true;
        this.showNext = false;
        this.hasBuildings = false;
        this.showUnitField = false;
        this.isPropertyIdentified = true;
        //this.isPropertyIdentifiedVal = '';
    }

    cleanCollateralForApex() {
        return {
            Id: this.collateral.Id || null,
            oldColId: this.collateral.Id || null,
            appAddId: this.collateral.appAddId || null,
            projId: this.collateral.projId || null,
            devId: this.collateral.devId || null,
            unitId: this.collateral.unitId || null,
            name: this.collateral.name || '',
            address1: this.collateral.address1 || '',
            address2: this.collateral.address2 || '',
            address3: this.collateral.address3 || '',
            city: this.collateral.city || '',
            state: this.collateral.state || '',
            plotNumber: this.collateral.plotNumber || '',
            housePlotNo: this.collateral.housePlotNo || '',
            surveyNumber: this.collateral.surveyNumber || '',
            mortgageType: this.collateral.mortgageType || '',
            assetType: this.collateral.assetType || '',
            pocket: this.collateral.pocket || '',
            streetName: this.collateral.streetName || '',
            buildingName: this.collateral.buildingName || '',
            country: this.collateral.country || '',
            pincode: this.collateral.pincode || '',
            addPincode: this.collateral.addPincode || '',
            addressType: this.collateral.addressType || '',
            plfId: this.plfId != '' ? this.plfId : this.collateral.plfId,
            block: this.collateral.block || '',
            projName: this.collateral.projName || '',
            devName: this.collateral.devName || '',
            unitType: this.collateral.unitType || '',
            towerName: this.collateral.towerName || '',
            assignPercentage: this.collateral.assignPercentage || 0,
            assignPercentageMatch: this.collateral.assignPercentageMatch || 0,
            // assignedCollateralValue: this.collateral.assignedCollateralValue || 0,
            floor: this.collateral.floor || '',
            unitNumber: this.collateral.unitNumber || null,
            constructionStage: this.collateral.constructionStage || '',
            allowMultiAssignment: this.collateral.allowMultiAssignment || false,
            allowThirdPartyAssignment: this.collateral.allowThirdPartyAssignment || false,
            ownershipType: this.collateral.ownershipType || '',
            occupancyType: this.collateral.occupancyType || '',
            occupancySince: this.collateral.occupancySince || '',
            propertyUsage: this.collateral.propertyUsage || '',
            currentUsage: this.collateral.currentUsage || '',
            reraEndDate: this.collateral.reraEndDate || null,
            estimatedValue: this.collateral.estimatedValue || null,
            marketValue: this.collateral.marketValue || null,
            areaOfPlot: this.collateral.areaOfPlot || null,
            carpetArea: this.collateral.carpetArea || null,
            reraRegNumber: this.collateral.reraRegNumber || '',
            gplFlag: this.collateral.gplFlag || '',

            collateralType: this.collateral.collateralType || '',
            insuranceFlag: this.collateral.insuranceFlag || '',
            apfValue: this.collateral.apfValue || '',
            upid: this.collateral.upid || '',
            loanId: this.recordId,
            reason: this.collateral.reason || '',
            matchFound: this.collateral.matchFound || '',
            apfNumber: this.collateral.apfNumber || '',
            externalId: this.externalId,
            primarySecondary: this.collateral.primarySecondary || '',
            costOfPlot: this.collateral.costOfPlot || null,
            improvementCost: this.collateral.improvementCost || null,
            agreementValue: this.collateral.agreementValue || null,
            societyCharges: this.collateral.societyCharges || null,
            electricityMunicipleCharges: this.collateral.electricityMunicipleCharges || null,
            architectsEstimate: this.collateral.architectsEstimate || null,
            amenitiesPermitPolicy: this.collateral.amenitiesPermitPolicy || null,
            others: this.collateral.others || null,
            totalPropertyCost: this.collateral.totalPropertyCost || null,
            docVal: this.collateral.docVal || null
        };
    }

    handleSave() {
        console.log('this.selectedApplicants-----'+this.selectedApplicants);
        this.isloading = true;
        if (!this.isHLUser || (this.isHLUser && this.collateral.apfValue === 'No')) {
            if (!this.selectedApplicants || this.selectedApplicants.length === 0) {
                this.isloading = false;
                this.showToast('Error', 'Select the Property Owner', 'error');
                return;
            }
        }

        /*if (this.selectedUpid) {
            // Find the selected record
            const selectedRecord = this.records.find(rec => rec.upid === this.selectedUpid);
            console.log('selectedRecord in save-----'+this.selectedRecord);
            if (selectedRecord) {
                const selectedAssignPercent = parseFloat(selectedRecord.ASSIGNMENT_PERCENTAGE) || 0;
                const remainingPercent = 100 - selectedAssignPercent;
                this.collateral.assignPercentage = remainingPercent;
                this.collateral.assignPercentageMatch = 100;

                // Set market value from selected record (if available)
                this.collateral.marketValue = selectedRecord.marketValue ? parseFloat(selectedRecord.marketValue) : 0;
            }
        } else {*/
            // No record selected → assign 100% and set marketValue = 0
            this.collateral.assignPercentage = 100;
            this.collateral.marketValue = 0;
            this.collateral.assignPercentageMatch = 100;
        //}

        const cleanedCollateral = this.cleanCollateralForApex();
        const collateralJson = JSON.stringify(cleanedCollateral);

        upsertCollateralAndApplicationCollateral({
            recordId: this.recordId,
            selectedApplicants: this.selectedApplicants,
            collateralJson: collateralJson,
            collateralId: this.collateral.Id,
            reason: this.reason
        })
            .then(result => {
                this.isloading = false;
                this.showToast('Success', 'Collateral saved successfully', 'success');
                this.getCollateral();
                this.isEditMode = false;
                this.editingCollateralId = null;
                console.log('Result:', result);
            })
            .catch(error => {
                this.isloading = false;
                this.showToast('Error', error.body?.message || 'Unknown error', 'error');
                console.error('Error:', error);
            });
    }


    getCollateral() {
        getCollateralRecordsByLoanAppId({ loanAppId: this.recordId })
            .then(result => {
                this.collateralList = result;
                console.log('Result:', JSON.stringify(result));
                this.isModalOpen = false;

                if (result.length > 0) {
                    this.selectedApplicants = result[0].ownerApplicantIds || [];
                } else {
                    this.selectedApplicants = [];
                }

                this.applicantOptions = this.applicantOptions.map(opt => ({
                    ...opt,
                    checked: this.selectedApplicants.includes(opt.value)
                }));
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Failed to load collateral records', 'error');
                this.collateralList = [];
                this.selectedApplicants = [];
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
            mode: 'dismissable'
        }));
    }

    handleDelink(event) {
        this.showConfirmation = true;
        this.delinkRowId = event.target.dataset.id;
        console.log('this.delinkRowId: ' + this.delinkRowId);
    }

    handleNegative() {
        this.showConfirmation = false;
        this.delinkRowId = '';
    }

    handlePositive(event) {

        delinkCollateral({
            collateralId: this.delinkRowId
        }).then(response => {
            if (response == 'success') {
                this.showConfirmation = false;
                this.delinkRowId = '';
                this.showToast('Success', 'Collateral delinked successfully.', 'success');

                this.getCollateral();
            }
            else {
                this.showToast('Error', 'Some error in delinking the collateral.', 'error');
            }
        }).catch(error => {
            console.log('Error delink collateral -->' + JSON.stringify(error));
        })
    }
    handleEdit(event) {
        this.modalHeader = 'Update Collateral';
        const recordId = event.target.dataset.id;
        const recordToEdit = this.collateralList.find(collateral => collateral.Id === recordId);
        this.collateral = recordToEdit;
        this.collateralBackup = this.collateral;
        console.log('this.collateral:', this.collateral);
        console.log('this.collateralBackup:', this.collateralBackup);

        if (recordToEdit) {
            this.collateral = { ...recordToEdit };
            this.towerName = this.collateral.towerName;
            this.isModalOpen = true;

            // Skip the "Is Property Identified?" first screen when it's already Yes
            if (this.isPropertyIdentifiedVal === 'Yes') {
                this.isPropertyIdentified = false;
            } else {
                this.isPropertyIdentified = true;
            }

            this.showAPFSelection = true;
            this.showApplicantList = false;
            this.showFieldSections = false;
            this.showDedupeAPI = false;
            this.showAssignUPID = false;
            this.showAPFFields = false;
            this.msgScreen = false;
            this.isEditMode = true;
            this.showCollateralMatchesScreen = false;

            if (this.collateral.apfValue == 'Yes') {
                this.showAPFFields = true;
                this.showAPFReraEndDate = this.isHLUser;
                this.showUnitField = true;
            }

            if (this.collateral.constructionStage &&
                this.collateral.constructionStage.toLowerCase() === 'under construction' &&
                this.isHLUser && this.collateral?.apfValue === 'No') {
                this.showReraEndDate = true;
            } else {
                this.showReraEndDate = false;
            }
        }
    }
    handleProjectSearch(event) {
        this.projectSearchKey = event.target.value;

        if (this.projectSearchKey.length === 0) {
            //Clear project + dependent fields
            this.collateral.projName = '';
            this.collateral.projId = '';
            this.collateral.devName = '';
            this.collateral.devId = '';
            this.collateral.apfNumber = '';
            this.collateral.address1 = '';
            this.collateral.address2 = '';
            this.collateral.address3 = '';
            this.collateral.assignPercentage = '';
            this.collateral.assignPercentageMatch = 0;
            this.filteredProjectList = [];

            // Reset tower/unit
            this.hasBuildings = false;
            this.towerId = '';
            this.towerName = '';
            this.filteredTowerList = [];
            this.istowerDisabled = true;

            this.collateral.unitId = '';
            this.collateral.unitName = '';
            this.collateral.unitType = '';
            this.collateral.unitNumber = '';
            this.collateral.towerName = '';
            this.collateral.floor = '';
            this.collateral.carpetArea = '';
            this.filteredUnitList = [];
            this.showUnitField = false;
            return;
        }

        if (this.projectSearchKey.length >= 2) {
            getBuilderProjects({ searchKey: this.projectSearchKey })
                .then(result => {
                    this.filteredProjectList = result;
                })
                .catch(error => {
                    console.error('Project search error', error);
                    this.filteredProjectList = [];
                });
        } else {
            this.filteredProjectList = [];
        }
    }

    handleProjectSelect(event) {
        this.collateral.projName = event.target.dataset.name;
        this.collateral.projId = event.target.dataset.id;
        this.collateral.devName = event.target.dataset.devname;
        this.collateral.devId = event.target.dataset.devid;
        this.collateral.apfNumber = event.target.dataset.apfno;
        this.collateral.address1 = event.currentTarget.dataset.addr1;
        this.collateral.address2 = event.currentTarget.dataset.addr2;
        this.collateral.address3 = event.currentTarget.dataset.addr3;

        const selectedProject = this.filteredProjectList.find(project => project.Id === this.collateral.projId);

        if (selectedProject) {
            this.collateral.city = selectedProject.Pincode__r?.City__r?.Name || '';
            this.collateral.state = selectedProject.Pincode__r?.City__r?.State__c || '';
            this.collateral.country = selectedProject.Pincode__r?.City__r?.Country__c || '';
            this.collateral.addPincode = selectedProject.Pincode__r?.Id;
            this.collateral.pincode = selectedProject.Pincode__r?.Name;
            this.collateral.reraEndDate = selectedProject.RERA_validity__c;//RERA_End_Date__c;
        }

        this.filteredProjectList = [];
        this.istowerDisabled = false;

        this.towerSearchKey = '';
        this.filteredTowerList = [];

        if (!this.collateral.projId) {
            // If projectId is blank or null, reset hasBuildings flag and return early
            this.hasBuildings = false;
            this.showUnitField = false;
            return;
        }

        hasBuildingsForProject({ projectId: this.collateral.projId })
            .then(result => {
                this.hasBuildings = result;
                if (this.hasBuildings) {
                    this.showUnitField = false;
                } else {
                    this.showUnitField = true;
                }
            })
            .catch(error => {
                console.error('Error checking buildings:', error);
                this.hasBuildings = false;
            });
    }

    handleTowerSearch(event) {
        this.towerSearchKey = event.target.value;

        if (this.towerSearchKey.length === 0) {
            // Clear tower + unit
            this.towerId = '';
            this.towerName = '';
            this.filteredTowerList = [];

            this.collateral.unitId = '';
            this.collateral.unitName = '';
            this.collateral.unitType = '';
            this.collateral.unitNumber = '';
            this.collateral.floor = '';
            this.collateral.carpetArea = '';
            this.filteredUnitList = [];

            this.showUnitField = false;
            return;
        }

        getBuildingsByProjectId({ projectId: this.collateral.projId, searchKey: this.towerSearchKey })
            .then(result => {
                this.filteredTowerList = result;
            })
            .catch(error => {
                console.error('Building search error', error);
                this.filteredTowerList = [];
            });
    }

    handleTowerSelect(event) {
        this.towerId = event.target.dataset.id;
        this.towerName = event.target.dataset.name;
        if (!this.towerId) {
            this.showUnitField = false;
            return;
        }

        this.filteredTowerList = [];
        this.showUnitField = true;

        this.unitSearchKey = '';
        this.filteredUnitList = [];
    }

    handleUnitSearch(event) {
        this.unitSearchKey = event.target.value;
        const referenceId = this.hasBuildings ? this.towerId : this.collateral.projId;

        if (this.unitSearchKey.length === 0) {
            // Clear unit only
            this.collateral.unitId = '';
            this.collateral.unitName = '';
            this.collateral.unitType = '';
            this.collateral.unitNumber = '';
            this.collateral.floor = '';
            this.collateral.reraEndDate = null;
            this.collateral.carpetArea = '';
            this.filteredUnitList = [];
            return;
        }

        if (!referenceId) {
            this.filteredUnitList = [];
            this.isUnitDisabled = true;
            return;
        }

        if (this.unitSearchKey.length >= 2) {
            getUnitsByProjectAndSearch({ projectId: referenceId, searchKey: this.unitSearchKey, useBuilding: this.hasBuildings })
                .then(result => {
                    this.filteredUnitList = result;
                })
                .catch(error => {
                    console.error('Unit search error', error);
                    this.filteredUnitList = [];
                });
        } else {
            this.filteredUnitList = [];
        }
    }

    handleUnitSelect(event) {
        console.log('649filteredUnitList', JSON.stringify(this.filteredUnitList));
        const selectedId = event.target.dataset.id;
        const selectedUnit = this.filteredUnitList.find(unit => unit.Id === selectedId);
        if (selectedUnit) {
            this.filteredUnitList = [];
            this.collateral.unitId = selectedUnit.Id;
            this.collateral.unitName = selectedUnit.Name;
            this.collateral.unitType = selectedUnit.Unit_Type__c;
            this.collateral.unitNumber = selectedUnit.Name;
            this.collateral.towerName = selectedUnit.Project_Building__r.Name;
            this.collateral.floor = selectedUnit.Floor_Number__c;
            this.collateral.carpetArea = selectedUnit.Carpet_Area__c;
            this.collateral.areaOfPlot = selectedUnit.Super_Builtup_Area__c;
            this.collateral.buildingName = selectedUnit.Building__r?.Name || '';
        }
    }


    handleDedupe() {
        this.isloading = true;
        this.showConfirmation1 = true;
        this.isDedupeLoading = true;
        if (!this.validateAllFields()) {
            this.isloading = false;
            this.isDedupeLoading = false;
            return;
        }

        const original = this.collateralBackup;
        const current = this.collateral;

        let isAddressChanged = false;

        if (this.collateral.apfValue === 'No') {
            if (current.address1 && current.address2 && current.address3 && current.pincode) {
                isAddressChanged =
                    original.address1 !== current.address1 ||
                    original.address2 !== current.address2 ||
                    original.address3 !== current.address3 ||
                    original.pincode !== current.pincode;
            }
        } else if (this.collateral.apfValue === 'Yes') {
            if (current.apfNumber && current.towerName && current.floor && current.unitNumber) {
                isAddressChanged =
                    original.apfNumber !== current.apfNumber ||
                    original.towerName !== current.towerName ||
                    original.floor !== current.floor ||
                    original.unitNumber !== current.unitNumber;
            }
        }

        if (isAddressChanged) {
            this.callCollateralDedupeAPI();
        } else if (
            (this.records && this.records.length > 0) ||
            (this.collateral.upid && this.collateral.upid.trim() !== '')
        ) {
            this.isloading = false;
            this.isDedupeLoading = false;
            this.showConfirmation1 = true;
        } else {
            this.isloading = true;
            this.isDedupeLoading = true;
            this.callCollateralDedupeAPI();
        }
    }

    handleConfirmYes() {
        this.showConfirmation1 = false;
        this.isloading = true;
        this.isDedupeLoading = true;
        this.callCollateralDedupeAPI();
    }

    handleConfirmNo() {
        this.showConfirmation1 = false;
    }

    get showBackButton() {
        return !this.showAPFSelection && !this.msgScreen;
    }

    callCollateralDedupeAPI() {
        this.isloading = true;
        this.isDedupeLoading = true;
        const cleanedCollateral = this.cleanCollateralForApex();

        const inputMap = {
            loanId: this.recordId,
            processName: 'Collateral Dedupe F&A',
            collateralJson: JSON.stringify(cleanedCollateral)
        };

        console.log('📤 Sending inputMap:', JSON.stringify(inputMap, null, 2));

       // initiateAPIRequest({ inputMap })
       initiateDummyAPIRequest({ inputMap })
            .then(result => {
                this.error = null;

                console.log(' Raw API Response:', result);

                if (typeof result === 'string') {
                    const parsed = JSON.parse(result);

                    if (parsed.Response && parsed.Response.Status === 'E') {
                        this.isloading = false;
                        this.isDedupeLoading = false;

                        console.error('API returned error:', parsed.Response.Message);
                        this.showToast('API Error', `Error: ${parsed.Response.Message}`, 'error');
                        this.showCollateralMatchesScreen = false;
                        return;
                    }
                }

                const response = JSON.parse(result);  // no try-catch
                console.log(' Parsed API Response:', response);

                if (response.Status && response.Status.toLowerCase() === 'no match found') {
                    this.collateral.allowMultiAssignment = true;
                    this.collateral.allowThirdPartyAssignment = true;
                    console.log(' No match found. UPID:', response.UPID);
                    this.collateral.upid = response.UPID;
                    this.collateralBackup = JSON.parse(JSON.stringify(this.collateral));
                    this.showCollateralMatchesScreen = false;
                    this.uniqueRequestId = response.UNIQUEREQUEST_ID;
                    this.externalId = response.EXTERNAL_ID;
                    this.showFieldSections = false;
                    this.showDedupeAPI = false;
                    this.msgScreen = true;
                    this.isloading = false;
                    this.showNext = true;
                    this.showApplicantList = false;
                    this.isDedupeLoading = false;
                    this.collateral.matchFound = 'No';

                } else if (response.status && response.status.toLowerCase() === 'matches found') {
                    console.log('Matches found:', response.records);

                    let rawRecords = response.records || [];

                    // Filter out records without UPID
                    rawRecords = rawRecords.filter(rec => rec.upid && rec.upid !== '');

                    // Deduplicate by UPID with preference
                    const uniqueRecordsMap = new Map();

                    rawRecords.forEach(rec => {
                        if (!uniqueRecordsMap.has(rec.upid)) {
                            uniqueRecordsMap.set(rec.upid, rec);
                        } else {
                            const existing = uniqueRecordsMap.get(rec.upid);

                            const currentHasAssign = rec.ASSIGNMENT_PERCENTAGE != null && rec.ASSIGNMENT_PERCENTAGE !== '';
                            const existingHasAssign = existing.ASSIGNMENT_PERCENTAGE != null && existing.ASSIGNMENT_PERCENTAGE !== '';

                            if (currentHasAssign && !existingHasAssign) {
                                uniqueRecordsMap.set(rec.upid, rec);
                            } else if (!currentHasAssign && existingHasAssign) {
                                // keep existing
                            } else {
                                // Both have or both don't have ASSIGNMENT_PERCENTAGE, compare MATCHPERCENTAGE
                                const currentMatch = rec.cscore ? parseFloat(rec.cscore) : 0;
                                const existingMatch = existing.cscore ? parseFloat(existing.cscore) : 0;

                                if (currentMatch > existingMatch) {
                                    uniqueRecordsMap.set(rec.upid, rec);
                                }
                                // else keep existing
                            }
                        }
                    });

                    // Convert map back to array and add isSelected flag
                    this.records = Array.from(uniqueRecordsMap.values()).map(rec => ({
                        ...rec,
                        isSelected: false
                    }));

                    // Reset other UI state
                    this.selectedUpid = null;
                    this.showDedupeAPI = true;
                    this.showFieldSections = true;
                    this.showAPFFields = this.collateral.apfValue === 'Yes';
                    this.showCollateralMatchesScreen = true;
                    this.showAssignUPID = true;
                    this.collateral.upid = '';
                    this.collateral.matchFound = 'Yes';
                    this.showNext = false;
                    this.isloading = false;
                    this.isDedupeLoading = false;
                    this.collateralBackup = JSON.parse(JSON.stringify(this.collateral));
                    this.uniqueRequestId = response.UNIQUEREQUEST_ID;
                    this.externalId = response.EXTERNAL_ID;

                    console.log('869--', this.uniqueRequestId);
                    console.log('869--', this.externalId);
                }
                else {
                    console.warn(' Unexpected response format:', response);
                    this.showToast('Unexpected Response', 'Unexpected Response received from API try again or Contact GC IT team.', 'error');
                    this.showCollateralMatchesScreen = false;
                    this.isloading = false;
                    this.isDedupeLoading = false;
                }
            })
            .catch(error => {
                this.isloading = false;
                this.showDedupeAPI = true;
                this.isDedupeLoading = false;
                //this.showAssignUPID = true;
                this.error = error.body ? error.body.message : error.message;
                console.error('API Callout Error:', this.error);
                this.showToast('Callout Failed', 'API is not working.Try again or Contact GC IT team.', 'error');
                this.showCollateralMatchesScreen = false;
            });

        this.isloading = false;
    }

    handleRadioClickUPID(event) {
        const clickedUpid = event.target.value;

        const deselectRecord = () => {
            this.selectedUpid = null;
            this.plfId = null;
            this.collateral.assignPercentageMatch = 0;
            this.records = this.records.map(rec => ({
                ...rec,
                isSelected: false
            }));
            event.target.checked = false;
        };

        if (this.selectedUpid === clickedUpid) {
            // --- unselect logic ---
            deselectRecord();
            this.reason = '';
            this.isReasonDisabled = false;
        } else {
            const selectedRecord = this.records.find(rec => rec.upid === clickedUpid);

            if (selectedRecord) {
                const assignPercentUsed = parseFloat(selectedRecord.ASSIGNMENT_PERCENTAGE) || 0;
                const marketValue = parseFloat(selectedRecord.marketValue) || 0;
                const collateralAssignPercent = parseFloat(this.collateral.assignPercentage) || 0;

                // 🚨 1. Validation: block if record is already 100%
                if (assignPercentUsed === 100) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Validation Error',
                            message: 'Cannot select record which is already 100% used',
                            variant: 'error',
                            mode: 'dismissable'
                        })
                    );
                    deselectRecord();
                    return;
                }

                // 🚨 2. Validation: block if sum exceeds 100%
                /* if ((assignPercentUsed + collateralAssignPercent) > 100) {
                     this.dispatchEvent(
                         new ShowToastEvent({
                             title: 'Validation Error',
                             message: `Total assigned percentage (${assignPercentUsed + collateralAssignPercent}%) cannot exceed 100%.`,
                             variant: 'error',
                             mode: 'dismissable'
                         })
                     );
                     deselectRecord();
                     return;
                 }
 
                 // 🚨 3. Validation: check required vs remaining market value
                 const remainingValue = marketValue - (marketValue * assignPercentUsed / 100);
                 const requiredValue = (collateralAssignPercent / 100) * marketValue;
 
                 if (requiredValue > remainingValue) {
                     this.dispatchEvent(
                         new ShowToastEvent({
                             title: 'Validation Error',
                             message: `Remaining market value (${remainingValue}) cannot cover required ${collateralAssignPercent}% of market value (${requiredValue}).`,
                             variant: 'error',
                             mode: 'dismissable'
                         })
                     );
                     deselectRecord();
                     return;
                 }*/

                // ✅ valid selection
                this.selectedUpid = clickedUpid;
                this.records = this.records.map(rec => ({
                    ...rec,
                    isSelected: rec.upid === clickedUpid
                }));

                this.collateral.assignPercentageMatch = assignPercentUsed;

                this.plfId = (selectedRecord.externalId && selectedRecord.externalId.startsWith('CT'))
                    ? selectedRecord.externalId
                    : null;
            }

            this.reason = '';
            this.isReasonDisabled = true;
        }

        if (
            (this.collateral.upid != null && this.collateral.upid !== '' && this.selectedUpid !== this.collateral.upid) ||
            this.collateral.upid === '' || this.collateral.upid == null
        ) {
            this.showNext = false;
            this.showAssignUPID = true;
        } else {
            this.showNext = true;
            this.showAssignUPID = false;
        }

        console.log('Selected UPID:', this.selectedUpid);
        console.log('Assignment Percent Match:', this.collateral.assignPercentageMatch);
        console.log('PLF Id:', this.plfId);
    }

    handleFinalNext() {
        console.log('1289--');
        if ((this.showCollateralMatchesScreen === true && this.msgScreen === false) || (this.isEditMode == true && this.msgScreen === false) || (this.collateral.upid != null && this.collateral.upid != '')) {
            console.log('1291--');
            if (this.checkDataChanged()) {
                console.log('1293--');
                this.showCollateralMatchesScreen = false;
                this.showFieldSections = false;
                this.showAPFFields = false;
                this.showDedupeAPI = false;
                this.msgScreen = false;
                if (this.isHLUser && this.collateral.apfValue === 'Yes') {
                    this.handleSave();
                } else {
                    this.getApplicantList();
                }
            }
        } else {
            this.msgScreen = false;
            if (this.isHLUser && this.collateral.apfValue === 'Yes') {
                this.handleSave();
            } else {
                  this.getApplicantList();
            }
        }
    }

    checkDataChanged() {
        console.log('1309--');
        if (this.collateral.apfValue === 'No') {
            const original = this.collateralBackup;
            const current = this.collateral;

            const isAddressChanged = original.address1 !== current.address1 || original.address2 !== current.address2 || original.address3 !== current.address3 || original.pincode !== current.pincode;

            if (isAddressChanged) {
                console.log('1316--');
                this.showToast('Details Updated', 'Please check for duplicate before proceeding.', 'warning');
                return false;
            }
        } else if (this.collateral.apfValue === 'Yes') {
            const original = this.collateralBackup;
            const current = this.collateral;

            const isApfDetailsChanged = original.apfNumber !== current.apfNumber || original.towerName !== current.towerName || original.floor !== current.floor || original.unitNumber !== current.unitNumber;

            if (isApfDetailsChanged) {
                this.showToast('Details Updated', 'Please check for duplicate before proceeding.', 'warning');
                return false;
            }
        }


        if (!this.validateAllFields()) {
            return false;
        }

        if ((!this.selectedUpid || this.selectedUpid.trim() === '') && (!this.reason || this.reason.trim() === '') && (this.collateral.upid == '' || this.collateral.upid == null)) {
            this.showToast('Validation Error', 'Please select either UPID or reason for not selecting UPID.', 'error');
            return false;
        }

        return true;
    }

    handleAssignUPID() {
        if (!this.checkDataChanged()) {
            return;
        }
        this.callAssignUPID();
    }

    callAssignUPID() {
        this.isloading = true;
        this.collateral.upid = this.selectedUpid;
        const cleanedCollateral = this.cleanCollateralForApex();
        console.log('1000---', this.collateral.upid);
        console.log('869--', this.uniqueRequestId);
        console.log('869--', this.externalId);

        const inputMap = {
            loanId: this.recordId,
            processName: 'Collateral Dedupe Assign UPID',
            collateralJson: JSON.stringify(cleanedCollateral),
            uniqueReqId: this.uniqueRequestId,
            externalId: this.externalId
        };


        if (this.collateral.upid == '' || this.collateral.upid == undefined || this.collateral.upid == null) {
            this.collateral.matchFound = 'No';
            this.collateral.allowMultiAssignment = true;
            this.collateral.allowThirdPartyAssignment = true;
        } else {
            this.collateral.matchFound = 'Yes';
            this.collateral.allowMultiAssignment = false;
            const selectedRecord = this.records.find(rec => rec.upid === this.selectedUpid);
            if (selectedRecord) {
                const marketValue = parseFloat(selectedRecord.marketValue) || 0;
                this.collateral.marketValue = marketValue;
            }
            this.collateral.allowThirdPartyAssignment = false;
            /*this.collateral.assignPercentage = (this.assignmentPercent !== null && this.assignmentPercent !== undefined && this.assignmentPercent !== '') 
        ? this.assignmentPercent 
        : this.collateral.assignPercentage;*/
        }

        console.log('Sending Input Map:', JSON.stringify(inputMap, null, 2));

        //initiateAssignUPIDRequest({ inputMap })
        initiateDummyAPIRequest({ inputMap })
        //console.log('result-------'+result);
            .then(result => {
                console.log('result-------'+result);
                this.error = null;
                this.isloading = false;
                if (typeof result === 'string' && result.startsWith('Error:')) {
                    console.error('UPID assignment failed:', result);
                    this.showToast('UPID Assignment Failed', 'UPID Assignment Failed.Try again.', 'error');
                    return;
                }

                // ✅ UPID successfully assigned
                this.collateral.upid = result;
                this.collateral.reason = this.reason;

                // Determine matchFound based on UPID
                this.collateral.matchFound = result ? 'Yes' : 'No';

                // Update UI flags
                this.showCollateralMatchesScreen = false;
                this.showFieldSections = false;
                this.showAPFFields = false;
                this.showDedupeAPI = false;
                this.showAssignUPID = false;
                this.msgScreen = true;
                this.showNext = true;

                console.log('UPID assigned:', this.collateral.upid);

            })
            .catch(error => {
                console.log('result-------'+result);
                this.isloading = false;
                console.error('Error in callAssignUPID:', error);
                this.error = 'Failed to assign UPID. Please try again.';
                this.showToast('Callout Error', this.error, 'error');
            });
        this.isloading = false;
    }

    get showProjectName() {
        return this.collateralList.some(item => item.apfValue !== 'No');
    }

    handleReasonChange(event) {
        this.reason = event.target.value;
    }

    get messageContainerClass() {
        return this.error ? 'modal-body-message-container error' : 'modal-body-message-container success';
    }
    //HL-Ishi
    createDocumentDetails() {
        const inputMap = {
            loanId: this.recordId,
            projectId: this.collateral.projId,
            isApf: false
        }
        console.log('inputMap==>', JSON.stringify(inputMap));
        createDocumentDetails({ inputMap })
            .then(result => {
                console.log('result==>', JSON.stringify(result));
                if (result != null && result != undefined && result != '') {
                    this.documentList = [...result];
                    if (this.documentList.length > 0) {
                        this.showDocumentList = true;
                    }
                }
                else {
                    console.log('Inside doc');
                }
            })
            .catch(error => {
                console.log('error==>', error);
            });
    }
    handleUploadFinished(event) {
        this.selectedDocId = event.target.dataset.id;
        console.log('file.type 1773:' + this.selectedDocId);
        const file = event.detail.files[0];
        console.log('file.type 1773:', file);
        const fields = {};
        fields['Id'] = this.selectedDocId;
        fields['Content_Document_Id__c'] = file.documentId;
        fields['Status__c'] = 'Uploaded';
        const recordInput = { fields };
        updateRecord(recordInput).then(() => {
            this.contentVersionId = file.contentVersionId;
            this.contentDocId = file.documentId;
            this.createDocumentDetails();
        }).catch(error => {

        })
        // const reader = new FileReader();
        // reader.onload = () => {
        //     this.fileName = file.name;
        //     this.uploadedDocs = reader.result; // Base64 string
        //     // this.contentDocId = this.uploadedAadharUrl.split(',')[1];
        //     setTimeout(() => {
        //         this.createContentVersion();
        //     }, 500);


        //     console.log('file.type:', file.type);

        //     // this.isImage = file.type.startsWith('image');
        //     // this.isPDF = file.type === 'application/pdf';
        //     this.dataType = file.type;
        // };

        // reader.readAsDataURL(file);
    }

    previewHandler(event) {
        console.log('event.target.dataset.id>>>>>' + event.target.dataset.id);
        console.log('event.target.dataset.id>>>>>', event);
        if (event.target.dataset.id == '' || event.target.dataset.id == null || event.target.dataset.id == undefined) {
            console.log('inside if empty file>>>>>' + event.target.dataset.id);
            const dataset = event.currentTarget.dataset;
            console.log('Description:', dataset.description);
            let fileId;
            const inputMap = {
                fileName: dataset.description,
                projectId: this.collateral.projId,
                docId: dataset.documentid,
                loanId: this.recordId
            }
            console.log('inputMap==>', JSON.stringify(inputMap));
            downloadDocumentDetails({ inputMap })
                .then(result => {
                    console.log('result==>', JSON.stringify(result));
                    if (result != null && result != undefined && result != '') {
                        fileId = result;
                        // this.showPreview=true;
                        // this.contentDocLink ='/sfc/servlet.shepherd/document/download/'+fileId;
                        // this.filePreviewUrl = '/sfc/servlet.shepherd/document/download/'+fileId + '#toolbar=0';
                        console.log('fileId==>', fileId);
                        this[NavigationMixin.Navigate]({
                            type: 'standard__namedPage',
                            attributes: {
                                pageName: 'filePreview'
                            },
                            state: {
                                selectedRecordId: fileId
                            }
                        })
                    }
                    else {
                        console.log('Inside doc');
                    }
                })
                .catch(error => {
                    console.log('error==>', error);
                });


            this.showToastMethod('Error', 'No file uploaded', 'Error');
        }
        else {
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview'
                },
                state: {
                    selectedRecordId: event.target.dataset.id
                }
            })
        }
    }

    createContentVersion() {
        console.log('freader:1804');
        const base64Data = this.uploadedDocs.split(',')[1];
        this.base64Data = this.uploadedDocs.split(',')[1];
        console.log('base64Data--', base64Data);
        const inputMap = {
            base64Data: base64Data,
            fileName: this.fileName,
            loanId: this.recordId,
            docId: this.selectedDocId,
            fileType: this.dataType
        }
        createContentVersion({
            inputMap: inputMap
        })
            .then(result => {
                console.log('result: 1819', result);
                this.contentVersionId = result.contentDocId;
                this.contentDocId = result.contentVerId;
            })
            .catch(error => {
                console.log('error:', JSON.stringify(error));
            })
    }

    getProductDetails() {
        const inputMap = { oppId: this.recordId }

        getProductDetails({
            inputMap: inputMap
        })
            .then(result => {
                if (result.isHLRelated) {
                    this.isHLUser = true;
                }
                if (result.product == 'Flexi Loan') {
                    this.isFlexiLoan = true;
                }
            })
            .catch(error => {
                console.log('error-->', error);
            })
    }
}