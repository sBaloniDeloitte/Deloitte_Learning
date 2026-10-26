import { LightningElement,api,wire,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import getSubStageList from '@salesforce/apex/COMM_SalesLoanActionsController.getSubStageList';
import getNextScreenDetails from '@salesforce/apex/Sales_LoanLoginDetailsController.getNextScreenDetails';
import getScreenDetails from '@salesforce/apex/ScreenGenerationLoginChecklistController.getScreenDetails';
import getPicklistValues from '@salesforce/apex/ScreenGenerationLoginChecklistController.getPicklistValues';
import savecreateLoanDetails from '@salesforce/apex/ScreenGenerationLoginChecklistController.savecreateLoanDetails';
import getFieldDependencies from '@salesforce/apex/ScreenGenerationLoginChecklistController.getFieldDependencies';;
import getLoanDetailsFromReadObject from '@salesforce/apex/ScreenGenerationLoginChecklistController.getLoanDetailsFromReadObject';
import getLoanDetailsFromStorageObject from '@salesforce/apex/ScreenGenerationLoginChecklistController.getLoanDetailsFromStorageObject';
import saveUploadedAddressProof from '@salesforce/apex/ScreenGenerationLoginChecklistController.saveUploadedAddressProof';
import customLoadStyles from '@salesforce/resourceUrl/stylingForCurrentAddressProofButton';
import customReLoadStyles from '@salesforce/resourceUrl/reUploadAddressProofButton';
import { loadStyle } from 'lightning/platformResourceLoader';
import createCurrentAddressRecord from '@salesforce/apex/ScreenGenerationLoginChecklistController.createCurrentAddressRecord';
import getCustomerType from '@salesforce/apex/ScreenGenerationLoginChecklistController.getCustomerType';


export default class SalesLoanLoginChecklistGenericScreenCmp extends LightningElement {
    @api recordId;
    // allFieldDetails = [];
     @api activeSection = '';
     @api passedScreenName
     @api item; // Accepts data dynamically
     @track isDropdownOpen = false;
     @track selectedValue = '';
     @track selectedLabel = 'Select an option';
     
     //isDropdownOpen = false;
     @track fieldDetails;
     @track filteredScreenDetails;
     @track allFieldDetails =[];
     // @track screenName = 'Enter PAN Details';
     @track screenName = 'Personal Information';
     @track screenObject;
     @track PANPage = false; // was false before
     @track currentScreenSequence = 0;
     @track showIMDScreen = false;
     @track showAccAg = false;
     @track showUploadDocuments = false;
     @track showLoginConfirm = false;
     @track showbasicCustomerDetails = true;
     @track showCollateralScreen = false;
     @track showConsentScreen = false;
     @track showCaptureApplicantPhotoScreen = false;
     @track showSalesLoginPrimaryApplicantInfoScreen = false;
     @track showDocScreen = false;
     @track isCustomCmp = false;
     @track fromCreateNewLoan = true;
     @track customCmpName;
     currentSeq = 0;
     onePage = false;
     @api selectedRecordId;
     picklistOptionsFromApex;
     saveandnext = "Next";
     cmpNameCheck;
     
     @track completionVal = 0;
     logoicon
     isRendered = false;
     @track showBankScreen = false;
     @track aadharPage = false;
     @track showProductScreen = false;
     @track showCoApplicantScreen = false;
     @track showGurantorScreen = false;
     @track showBusinessAddressScreen = false;
     @track showBOScreen = false;
     @track showChangeApplicantScreen = false;
     @track showEligibilityScreen = false;
     @track small = false;
     @track pincodeRecordId;
     @track showAccAg=false;
     openDropdown = null;
     showPincodeCmp=false;
     showEligibilityScreen = false;
     showEligibilityScreenAA = false;
     @api formIdentifier = 'Login Checklist';
     @track showParentSave = false;
     @track showSpinner = false;
     @track custype;
     @track customerType;
     @track empType;
     @track showPermanentAdr = false;
     get picklistOptions() {
         return [
             { label: 'Yes', value: 'Yes' },
             { label: 'No', value: 'No' }
         ];
     }
     @track mainApplicantId;
     @track spinnerClass;
     @track showLoader;
     @track loadLookUps = true;
     @track firstLoad = true;
 
     @track permanentAddressFilled = false;
     stages = [];
     @track aadharPage = false;
     @track ovdPage = false;
     //@track businessAddressScreen = false;
     @track showSkipForBusinessAddress = false;
     @track showScreenFieldLoginAppFields = true;
     @track uploadButtonLabel;
     @track isNonIndividual = false;
     @track showITRCmp=false;
     @track showGSTCmp=false;
     @track showComparisonScreen = false;
     @wire(CurrentPageReference) pageRef;
     showIncomeScreen = false;
     showBSAScreen = false;
     showPrimaryApplicantInfoScreen = false;
     @api currentAppSeq;
     showAddressDetails = false;
     cibilOneView= false;
     showCibilEligibility = false;
    //  showBranchMasterLookup = false;
    //  showLeadChannelLookup = false;
    handleNavigationClick(event) {
        const valueSelectedEvent = new CustomEvent('opennavigationmenu', { detail: {} });
        this.dispatchEvent(valueSelectedEvent);
    }
    getCustomerType(){
        getCustomerType({
            loanId:this.recordId
        }).then(response=>{
            console.log('response=: partner'+JSON.stringify(response));
            this.customerType = response.customerType;
            this.empType = response.empType;
            this.mainApplicantId = response.applicantId;
        }).catch(error=>{

        })
    }

   
     
    connectedCallback() {
        this.allFieldDetails = null;
        document.addEventListener('click', this.handleClickOutside.bind(this));
        console.log('currentAppSeq=:142'+this.currentAppSeq);
        console.log('connectedCallback');
        var detail = {};
        detail["isPullToRefreshEnabled"] = false;
        var updateScrollSettingsEvent = new CustomEvent("updateScrollSettings", {   detail: detail,
                                                                                    bubbles: true,
                                                                                    composed: true
                                                                                });
        dispatchEvent(updateScrollSettingsEvent);
        console.log('this.recordId -->' + this.recordId);
        console.log('activeSection--157-',JSON.stringify(this.activeSection));
        console.log('passedScreenName--158-1',this.passedScreenName)
        this.getScreenDetailsFromApex();

        //this.getCompletionPercent();
        this.getCustomerType();
        if (FORM_FACTOR == 'Small') {
            this.small = true;
            this.addEventListeners();
        }
        Promise.all([
            loadStyle(this, customLoadStyles )
                ]).then(() => {
                }).catch( (error) => {
                })
        Promise.all([
            loadStyle(this, customReLoadStyles )
        ]).then(() => {
        }).catch( (error) => {
        })
        
    }
    createChecklist(){
        executeMapping({
            identifier:'fromLoan',
            recordId:this.recordId,
            applicantId:this.mainApplicantId,
            applicantType:'Primary Applicant'

        }).then(response=>{
            console.log('response=: partner'+JSON.stringify(response));
        
        }).catch(error=>{

        })
    }
    get picklistOptions() {
        return this.item?.picklistOptions || [];
    }

    disconnectedCallback() {
        document.removeEventListener('click', this.handleClickOutside.bind(this));
    }
    addEventListeners() {
        window.addEventListener('touchmove', this.preventPullToRefresh, { passive: false });
        window.addEventListener('touchstart', this.preventPullToRefresh, { passive: false });
    }

    preventPullToRefresh(event) {
        // Add logic to detect and prevent pull-to-refresh
        if (event.touches.length > 1) {
            // If more than one touch point, prevent default
            event.preventDefault();
        }
    }

    disconnectedCallback() {
        unregisterAllListeners(this); 
        window.removeEventListener('touchmove', this.preventPullToRefresh);
        window.removeEventListener('touchstart', this.preventPullToRefresh);
    }

    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
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
                background: skyblue;
            }
                .instruction-box-nav.slds-progress-bar__value{
                background: skyblue;
            }
            /* Hide border and apply bottom border only */
            .hideInput .slds-input {
                border: none !important; /* Remove all default borders */
                border-bottom: 1px solid black !important; /* Add only bottom border */
                background-color: transparent;
                outline: none;
                box-shadow: none;
                border-radius: 0 !important; /* Remove curved edges */
                padding: 4px; /* Adjust padding if necessary */
            }
            .removeborder .slds-combobox__input {
                border: none !important;  /* Remove border */
                box-shadow: none !important;  /* Remove any shadow */
                background-color: transparent;  /* Ensure no background color */
                 border-bottom: 1px solid black !important; /* Add only bottom border */
                 border-radius: 0 !important; /* Remove curved edges */
                 padding:5px

            }
              .removelookup .slds-combobox__input {
                border: none !important;
                box-shadow: none !important;
                 border-bottom: 1px solid black !important; /* Add only bottom border */
                 padding:5px
            }
          
            
            `;
            this.template.querySelector('.styleContainer').appendChild(style);
            this.spinnerClass = 'spinner-medium';
        }

        if(this.fieldDetails) {
            this.fieldDetails.forEach(item => {
                if(item.Is_Hidden__c) {
                    item.hideField = true;
                    this.template.querySelector(`[data-id="${item.Id}"]`).classList.add('slds-hide');
                }
                else if(this.firstLoad == true && this.isCustomCmp == false && (this.recordId == null || this.recordId == '' || this.recordId == undefined) && item.Visibility_Controlled_By__c != null && item.Visibility_Controlled_By__c != '' && item.Visibility_Controlled_By__c != undefined){
                    item.hideField = false;
                    this.template.querySelector(`[data-id="${item.Id}"]`).classList.add('slds-hide');
                }
            });
        }
    }

    get previousVisibility(){
        return this.currentScreenSequence > 1;
    }
    get showSaveVisibility(){
        return this.currentScreenSequence == 15;
    }
    getScreenDetailsFromApex() {
             console.log('this.formIdentifier 1'+this.formIdentifier);
             this.allFieldDetails = [];
             this.fieldDetails = null;
             getScreenDetails({formIdentifier: this.formIdentifier, loanId: this.recordId})
             .then(result => {
                 if(result) {
                    console.log('result for personal details1', result);
                     this.allFieldDetails = result;
                     console.log('result for personal details this.allFieldDetails ', this.allFieldDetails );
                     this.getCurrentScreenFieldDetails();
                 }
             }).catch(error => {
                 console.error('error getScreenDetails: ' + error);
             });
    }
    getCurrentScreenFieldDetails() {
        console.log('this.allFieldDetails --> ');
        console.log('this.allFieldDetails --> ' + JSON.stringify(this.allFieldDetails));      
        setTimeout(() => {
        this.screenObject = null;
        this.fieldDetails = null;
        this.screenName = null;
        this.isCustomCmp = false;
        this.showIncomeScreen = false;
        this.showBSAScreen = false;
        this.showSalesLoginPrimaryApplicantInfoScreen = false;
        this.cibilOneView= false;
        this.showPrimaryApplicantInfoScreen = false;
        this. showCibilEligibility = false;
        //this.showGurantorScreen = false;
        
        console.log('this.allFieldDetails --> ' + JSON.stringify(this.allFieldDetails));
        
        console.log('this.passedScreenName 326',JSON.stringify(this.activeSection));
        this.onePage = true;
        this.allFieldDetails.forEach(item => {
            console.log('this.passedScreenName 329',item.Parent_Screen__r.Master_Screen_Name__c);
            if(item.Parent_Screen__r.Master_Screen_Name__c == this.activeSection.name){
                console.log('this.passedScreenName 326',this.activeSection.name);
            }
        });
            
        console.log('this.activeSection.name=:'+this.activeSection.name);
        if (this.activeSection && this.activeSection.name) {
            this.filteredScreenDetails = this.allFieldDetails.filter(item => 
                item.Parent_Screen__r.Master_Screen_Name__c === this.activeSection.name
            );
        }
        console.log('Filtered Screen Details for Active Section:', this.filteredScreenDetails);

        // Assign current screen sequence
        this.filteredScreenDetails.forEach(item => {
            this.currentSeq = item.Parent_Screen__r.Screen_Sequence__c;
        });
        this.currentScreenSequence = this.currentSeq;

        console.log('this.currentScreenSequence -->', this.currentScreenSequence);
        this.filteredScreenDetails.forEach(element => { this.cmpNameCheck = element.Custom_Component_Name__c });
            console.log('this.filteredScreenDetails -->'+JSON.stringify(this.filteredScreenDetails));
        console.log('this.cmpNameCheck -->'+JSON.stringify(this.cmpNameCheck));

        if(this.cmpNameCheck !== undefined) {
           
            this.onePage = false;

            this.filteredScreenDetails.forEach(item => { this.screenName = item.Parent_Screen__r.Master_Screen_Name__c; });
            this.filteredScreenDetails.forEach(item => { this.customCmpName = item.Custom_Component_Name__c });
            console.log('customCmpName --> ', JSON.stringify(this.customCmpName));
            console.log('filteredScreenDetails --> ', JSON.stringify(this.filteredScreenDetails));
            const valueSelectedEvent = new CustomEvent('highlightactivescreen', { detail: {screenName: this.passedScreenName} });
            this.dispatchEvent(valueSelectedEvent);
            this.showCustomCmp(this.customCmpName);
        }
        else {
            //only in case of non-custom component
            this.PANPage = false;
            this.aadharPage = false;
            this.showCoApplicantScreen = false;
            this.showGurantorScreen = false;
            this.showBusinessAddressScreen = false;
            this.showBOScreen = false;
            this.showChangeApplicantScreen = false;
            this.showEligibilityScreen = false;
            this.showEligibilityScreenAA = false;
            this.onePage = true;
            this.filteredScreenDetails.forEach(item => { this.screenName = item.Parent_Screen__r.Master_Screen_Name__c; });
            this.filteredScreenDetails.forEach(item => { this.screenObject = item.Storage_Object__c; });
            this.fieldDetails = this.filteredScreenDetails;
            if(this.fieldDetails == undefined || this.fieldDetails == null){
                this.currentScreenSequence = this.currentScreenSequence + 1;
                this.getCurrentScreenFieldDetails();
            }
            console.log('this.fieldDetails::: '+JSON.stringify(this.fieldDetails));
            const valueSelectedEvent = new CustomEvent('highlightactivescreen', { detail: {screenName: this.passedScreenName} });
            this.dispatchEvent(valueSelectedEvent);
            this.fieldDetails.forEach(item => {
                //item.isPicklist = item.Field_Type__c === 'Picklist';
                item.isCheckBox = item.Field_Type__c === 'Boolean';

                if(item.is_Lookup__c){
                    console.log('inside item.is_Lookup__c --> item.Storage_Field__c --> '+ item.Storage_Field__c);
                    if(item.Storage_Field__c.includes('Branch__')){
                        item.showBranchLookup = true;
                    }
                    else if(item.Storage_Field__c.includes('Pincode__')){
                        item.showPinCodeLookup = true;
                    }
                    else if(item.Storage_Field__c.includes('Branch_Master__')){
                        item.showBranchMasterLookup = true
                    }
                    else if(item.Storage_Field__c.includes('Lead__r.Channel__c')){
                        item.showLeadChannelLookup = true
                    }
                }

                if(item.Parent_Screen__r.Master_Screen_Name__c == `Personal Information`){
                    this.ovdPage = false;
                    //this.showPermanentAdr = true;
                    this.showScreenFieldLoginAppFields = true;
                }
            });

            this.fieldDetails.forEach(async item => {
                if(item.Field_Type__c === 'Picklist') {
                    item.isPicklist = true;
                    item.picklistOptions = await this.getPicklistOptionsFromApex(item.isPicklist, item.Storage_Object__c, item.Storage_Field__c);
                }
            });
            

            if(this.isCustomCmp == false && this.recordId != null && this.recordId != '' && this.recordId != undefined /*&& !this.businessAddressScreen*/) {
                this.getLoanDetails();
            }

            console.log('fieldDetails getCurrentScreenFieldDetails --> ', JSON.stringify(this.fieldDetails));
        }

        //this.passedScreenName = null;
        this.filteredScreenDetails = null;
        
        }, 1000);
    
    }
     
         async getPicklistOptionsFromApex(isPicklist, storageObject, storageField) {
             if(isPicklist) {
                 const result = await getPicklistValues({ storageObject: storageObject, storageField: storageField });
                 let picklistOptions = result.map(option => {
                     return {
                         label: option.label,
                         value: option.value
                     };
                 });
                 return picklistOptions;
             }
         }
     
         validateSaveAndNext() {
            // console.log('business address screen:: ' + this.businessAddressScreen);
             if(this.PANPage === true) {
                 this.PANPage = false;
                 this.onePage = true;
                 this.currentScreenSequence = this.currentScreenSequence + 1;
                 this.getCurrentScreenFieldDetails();
             }
             else {
                 this.showLoader = true;
                 // var isSaveLoanDetails = true;
                 var isSaveLoanDetails = true;
                 var fieldsAndMandatoryMap = {};
     
                 var objectDataMap = {};
                 objectDataMap['Application_Applicant__c'] = {};
                 objectDataMap['Opportunity'] = {};
                 objectDataMap['Applicant_Address__c'] = {};
     
                 console.log('this.fieldDetails -->'+JSON.stringify(this.fieldDetails));
     
                 if(this.createCurrentAddressSameAsPermanentAddress){
                     this.createCurrentAddress();
                 }
     
                 if(this.fieldDetails) {
                     this.fieldDetails.forEach(record => {
                         var tempfieldDataMap = {};
                         
                         if(!record.Is_Formula_Feild__c){
                             if(record.Is_Mandatory__c){
                                 console.log('this.customerType=:'+this.customerType);
                                 console.log('record.Applicable_For__c=:'+record.Applicable_For__c);
                                 console.log('record.Storage_Object__c=:'+record.Storage_Object__c);
                                 console.log('record.Storage_Field__c=:'+record.Storage_Field__c);
                                 if(record.Visibility_Controlled_By__c != null && record.Visibility_Controlled_By__c != '' && record.Visibility_Controlled_By__c != undefined){
                                     const dependentField = this.fieldDetails.find(item => item.Id == record.Visibility_Controlled_By__c);
                                     console.log('this.dependent -->'+JSON.stringify(dependentField));
                                     const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                                     console.log('arrDependentControlledValue'+ arrDependentControlledValue);
                                     console.log('record.value '+ record.value );
                                     console.log(' this.empType'+ this.empType );
                                     if (arrDependentControlledValue.find(element => element == dependentField.value.toLowerCase())  && (record.value == null || record.value == '' || record.value == undefined)) {
                                         console.log('this.arrDependentControlledValue -->');
                                         if(this.customerType != undefined && (record.Applicable_For__c == 'Both' || record.Applicable_For__c == 'Individual-Both' || record.Applicable_For__c == 'Non Individual-Both' || record.Applicable_For__c == (this.customerType+'-'+this.empType) )){
                                             console.log('tthis.customerType ->'+this.customerType );
                                             console.log(' record.Applicable_For__c >'+ record.Applicable_For__c );
                                             console.log('record.Storage_Field__c=:'+record.Storage_Field__c);
                                             this.showLoader = false;
                                             this.showErrorMessage('Please fill all the mandatory fields in order to proceed 1');
                                             isSaveLoanDetails = false;
                                             return;
                                         }
                                     }
                                     else if (this.customerType != undefined && (record.Applicable_For__c == 'Both' || record.Applicable_For__c == 'Individual-Both' || record.Applicable_For__c == 'Non Individual-Both' || record.Applicable_For__c == (this.customerType+'-'+this.empType) ) && arrDependentControlledValue.find(element => element == dependentField.value.toLowerCase())  && (record.value != null || record.value != '' || record.value != undefined)) {
                                         tempfieldDataMap =  objectDataMap[record.Storage_Object__c];
                                         tempfieldDataMap[record.Storage_Field__c] = record.value;
                                         objectDataMap[record.Storage_Object__c] = tempfieldDataMap;
                                     }
                                 }
                                 else{
                                     console.log('record.value::: '+record.value + record.Storage_Field__c);
                                     /*if(record.value == null || record.value == ''){
                                         this.showLoader = false;
                                         this.showErrorMessage('Please fill all the mandatory fields in order to proceed 2');
                                         isSaveLoanDetails = false;
                                         return;
                                     }else{*/
                                     if(this.customerType != undefined && (record.Applicable_For__c == 'Both' || record.Applicable_For__c == 'Individual-Both' || record.Applicable_For__c == 'Non Individual-Both' || record.Applicable_For__c ==(this.customerType+'-'+this.empType) )){
                                         console.log('record.Storage_Field__c=:'+record.Storage_Field__c);
                                         tempfieldDataMap =  objectDataMap[record.Storage_Object__c];
                                         tempfieldDataMap[record.Storage_Field__c] = record.value;
                                         objectDataMap[record.Storage_Object__c] = tempfieldDataMap;
                                     }
                                     //}
                                 }
                             }
                             /*else if (record.Storage_Field__c === 'Current_Address_Proof__c') {
                                 // Find the value of "Is_Current_Address_Same_As_Permanent__c"
                                 const isAddressSameField = this.fieldDetails.find(
                                     field => field.Storage_Field__c === 'Is_Current_Address_Same_As_Permanent__c'
                                 );
                             
                                 // Validate only if "Is_Current_Address_Same_As_Permanent__c" is "No" and the current field is empty
                                 if (isAddressSameField && isAddressSameField.value === 'No' && (!record.value || record.value.trim() === '')) {
                                     console.log('Validation triggered: Documents for Current Address Proof is mandatory.');
                                     this.showLoader = false;
                                     this.showErrorMessage('Please upload Documents for Current Address Proof.');
                                     isSaveLoanDetails = false;
                                     return;
                                 }
                             }*/
                             else{
                                 tempfieldDataMap =  objectDataMap[record.Storage_Object__c];
                                 tempfieldDataMap[record.Storage_Field__c] = record.value;
                                 objectDataMap[record.Storage_Object__c] = tempfieldDataMap;
                             }
                         }
                     });
                 }
                 console.log('objectDataMap -->'+JSON.stringify(objectDataMap));
                 if (isSaveLoanDetails) {
                     if (objectDataMap != {}) {
                        console.log('this.selectedRecordId---c/additionalFileUploadComponent 549',this.selectedRecordId)
                             savecreateLoanDetails({
                                 fieldsDataMap: JSON.stringify(objectDataMap),
                                 loanId: this.recordId,
                                 formIdentifier: this.formIdentifier,
                                 applicantDetId: this.selectedRecordId
                             }).then(response => {
                                 // console.log('response --> ', JSON.stringify(response));
                                 
                                 if(this.recordId != null && this.recordId != '' && this.recordId != undefined){
                                     this.dispatchEvent(
                                         new ShowToastEvent({
                                             title: 'Success',
                                             message: 'Data saved successfully',
                                             variant: 'success',
                                         }),
                                     );
                                 }else{
                                     this.dispatchEvent(
                                         new ShowToastEvent({
                                             title: 'Success',
                                             message: 'Data saved successfully',
                                             variant: 'success',
                                         }),
                                     );
                                 }
                                 this.getNextScreenDetails();
                                 
                                 this.recordId = response.loanId;
                                 this.mainApplicantId = response.applicantId;
         
                                //  if(this.showPermanentAdr){
                                //      this.savePermanentAddress();
                                //  }
         
                                 if(!this.showSaveVisibility){
                                     if (this.currentScreenSequence < 20) {
                                         this.currentScreenSequence = this.currentScreenSequence + 1;
             
                                         this.getCurrentScreenFieldDetails();
                     
                                         if (this.isCustomCmp == false) {
                                             console.log('inside here customcmp false 2::');
                                             this.getLoanDetails();
                                         }
                                     }
                                     else {
                                         this.currentScreenSequence = this.currentScreenSequence - 1;
                                     }
                                 }
                                 
                                 const valueSelectedEvent = new CustomEvent('refreshmenucmp', { detail: {loanId: this.recordId} });
                                 this.dispatchEvent(valueSelectedEvent);
                                 this.getScreenDetailsFromApex();
                                 //this.getCompletionPercent();
                             }).catch(error => {
                                 this.showLoader = false;
                                 this.dispatchEvent(
                                     new ShowToastEvent({
                                         title: 'Error',
                                         message: error.body.message,
                                         variant: 'error',
                                     }),
                                 );
                             })
                     }
                     else {
                         if (this.currentScreenSequence < 20) {
                             this.getCurrentScreenFieldDetails();
                             const valueSelectedEvent = new CustomEvent('refreshmenucmp', { detail: {loanId: this.recordId} });
                             this.dispatchEvent(valueSelectedEvent);
                             if (this.isCustomCmp == false) {
                                 this.getLoanDetails();
                             }
                             this.getNextScreenDetails();
                         }
                         else {
                             this.showLoader = false;
                             this.currentScreenSequence = this.currentScreenSequence - 1;
                         }
                     }                
                 }
             }
         }

         getNextScreenDetails(){
            console.log('this.currentAppseq--- 635',this.currentAppSeq);
            getNextScreenDetails({currentAppSeq:this.currentAppSeq,activeSectionName:this.activeSection.name,formIdentifier:this.formIdentifier})
            .then(result => {
                console.log('result-----635',result);
                const valueSelectedEvent = new CustomEvent('opennextscreen', { detail: {screenName:result} });
                this.dispatchEvent(valueSelectedEvent);
            })
            .catch(error => {
                console.log(error);
            })
         }
         previousAction() {
             this.showPermanentAdr = true;//was false before
             this.currentScreenSequence = this.currentScreenSequence - 1;
     
             this.loadLookUps = false;
     
             if (this.currentScreenSequence > 0) {
                 this.getCurrentScreenFieldDetails();
     
                 if (this.isCustomCmp == false && this.recordId != null && this.recordId != '' && this.recordId != undefined) {
                     this.getLoanDetails();
                 }
             }
         }
     
         previousActionFromCustom(event){
             console.log('event -->'+JSON.stringify(event));
             if(event.detail.recordId != null && event.detail.recordId != '' && event.detail.recordId != undefined){
                 this.recordId = event.detail.recordId;
             }
     
             this.showPermanentAdr = true; //was false before
             this.currentScreenSequence = this.currentScreenSequence - 1;
     
             this.loadLookUps = false;
     
             if (this.currentScreenSequence > 0) {
                 this.getCurrentScreenFieldDetails();
     
                 if (this.isCustomCmp == false && this.recordId != null && this.recordId != '' && this.recordId != undefined) {
                     this.getLoanDetails();
                 }
             }
         }
     
         getLoanDetails() {
            console.log('this.selectedRecordId---c/additionalFileUploadComponent',this.selectedRecordId)
             getLoanDetailsFromStorageObject({
                 screenName: this.screenName,
                 loanId: this.recordId,
                 formIdentifier: this.formIdentifier,
                 recordId: this.selectedRecordId
             }).then(result => {
                 this.showLoader = false;
                 this.loadLookUps = false;
                 var isFetchFromReadObject = true;
                 console.log('detailsWrapperList from getLoanDetailsFromStorageObject--> ' + JSON.stringify(result));
                 console.log('fieldDetails-> ' + this.fieldDetails);
                 if(this.fieldDetails){
                     result.forEach(item => {
                         isFetchFromReadObject = false;
                         if(item.fieldApiName == 'Is_Current_Address_Same_As_Permanent__c' && item.fieldValue == 'No'){
                             this.showPermanentAdr = true;
                             this.showUploadCurrentAddressProofDoc = true;
                         }
                         /*if(item.fieldApiName == 'Permanent_Address_Same_As_Current_Addres__c' && item.fieldValue == 'No'){
                             this.showPermanentAdr = true;
                             this.permanentAddressFilled = true;
                         }*/
     
                         /*if(item.fieldApiName == 'Is_Permanent_Address_Not_Same_As_Current__c' && item.fieldValue){
                             this.showPermanentAdr = true;
                             this.permanentAddressFilled = true;
                         }*/
     
                         this.fieldDetails.forEach(record => {
                             if(item.fieldApiName == record.Storage_Field__c && record.is_Lookup__c){
                                 record.savedName = item.fieldValue;//item.lookUpfieldValue;
                                 record.value = item.lookUpfieldValue;
                                 console.log('record -->'+JSON.stringify(record));
                             }else if(item.fieldApiName == record.Storage_Field__c){
                                 record.value = item.fieldValue;
                             }
                         });
                     });      
                     
                     setTimeout(() => {
                         this.loadLookUps = true;
                         this.fieldDetails.forEach(record => {
                             console.log('record.Visibility_Controlled_By__c=:'+record.Visibility_Controlled_By__c);
                             console.log('record.Storage_Field__c=:'+record.Storage_Field__c);
                             
                             if(record.Visibility_Controlled_By__c != null && record.Visibility_Controlled_By__c != '' && record.Visibility_Controlled_By__c != undefined){
                                 const dependentField = this.fieldDetails.find(item => item.Id == record.Visibility_Controlled_By__c);
                                 console.log('dependentField=:'+JSON.stringify(dependentField));
                                 const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                                 console.log('arrDependentControlledValue=:'+arrDependentControlledValue);
                                 if(dependentField.value != null && dependentField.value != '' && dependentField.value && dependentField.value != undefined){
                                     if(arrDependentControlledValue.find(element => element == dependentField.value.toLowerCase())){
                                         record.hideField = false;
                                         this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                                     }
                                     else {
                                         record.hideField = true;
                                         this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                                     }
                                 }else{
                                     record.hideField = true;
                                     this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                                 }
                             }
                             // else{
                             //     record.hideField = false;
                             //     this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                             // }
                         });
                         
                     }, 1500);
                 }
                 if(this.customerType != undefined){
                     if(this.customerType == 'Non Individual'){
                         setTimeout(() => {
                             this.fieldDetails.forEach(item => { 
                                 if(item.Applicable_For__c == 'Both' || item.Applicable_For__c == 'Non Individual-Both' || item.Applicable_For__c == undefined || item.Applicable_For__c == (this.customerType+'-'+this.empType) ){
                                     item.hideField = false;
                                     // if(this.small== false){
                                         this.template.querySelector(`[data-id="${item.Id}"]`).classList.remove('slds-hide');
                                     // }
                                 }
                                 else{
                                     item.hideField = true;
                                     // if(this.small== false){
                                         this.template.querySelector(`[data-id="${item.Id}"]`).classList.add('slds-hide');
                                     // }
                                 }
                             });
                         },2000);
                     }
                     else{
                         setTimeout(() => {
                             console.log('this.customerType 656=:'+this.customerType);
                             console.log('this.fieldDetails---683'+this.fieldDetails);
                             this.fieldDetails.forEach(item => { 
                                 console.log('item.Applicable_For__c=:746'+item.Applicable_For__c);
                                 console.log('item.Storage_Field__c=:747'+item.Storage_Field__c);
                                 if(item.Applicable_For__c == 'Both' || item.Applicable_For__c == 'Individual-Both' || item.Applicable_For__c == 'Non Individual-Both' || item.Applicable_For__c == undefined || item.Applicable_For__c == (this.customerType+'-'+this.empType)){
                                     item.hideField = false;
                                     
                                     // if(this.small== false){
                                         this.template.querySelector(`[data-id="${item.Id}"]`).classList.remove('slds-hide');
                                     // }
                                 }
                                 else{
                                     item.hideField = true;
                                     // if(this.small== false){
                                         this.template.querySelector(`[data-id="${item.Id}"]`).classList.add('slds-hide');
                                     // }
                                 }
                             });
                         },2000);
                     }
                 }
     
                 return ({ isFetchFromReadObject: isFetchFromReadObject });
             }).then(res => {
                 if (res.isFetchFromReadObject) {
                     this.getLoanDetailsFromReadObject();
                 }else{
                     
                 }
             }).catch(error => {
                 this.showLoader = false;
                 this.dispatchEvent(
                     new ShowToastEvent({
                         title: 'Error',
                         message: error.body.message,
                         variant: 'error',
                     }),
                 );
             })
         }
     
         getLoanDetailsFromReadObject() {
             getLoanDetailsFromReadObject({
                 screenName: this.screenName,
                 loanId: this.recordId,
                 formIdentifier: this.formIdentifier,
                 recordId:this.selectedRecordId
             }).then(result => {
                 console.log('detailsWrapperList from getLoanDetailsFromReadObject-->' + JSON.stringify(result));
                 
                 if(this.fieldDetails){
                     result.forEach(item => {
                         isFetchFromReadObject = false;
                         if(this.screenName == `Confirm Applicant's Basic Details`){
                             if(item.fieldApiName == 'Is_Current_Address_Same_As_Permanent__c' && (item.fieldValue == 'Yes'||item.fieldValue == Yes)){
                                 console.log('Inside----735' + JSON.stringify(result));
                                 this.showPermanentAdr = true;
                             }
                         }
     
                         this.fieldDetails.forEach(record => {
                             if(record.Read_Field_Name__c == 'Branch_Name__c' && item.fieldApiName == record.Storage_Field__c){
                                 record.savedName = item.fieldValue;
                             }
                             else if(item.fieldApiName == record.Storage_Field__c){
                                 record.value = item.fieldValue;
                             }
                         });
                     });
                 
                     setTimeout(() => {
                         this.fieldDetails.forEach(record => {
                             if(record.Visibility_Controlled_By__c != null && record.Visibility_Controlled_By__c != '' && record.Visibility_Controlled_By__c != undefined){
                                 const dependentField = this.fieldDetails.find(item => item.Id == record.Visibility_Controlled_By__c);
                                 const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                                 if(arrDependentControlledValue.find(element => element == dependentField.value.toLowerCase())){
                                     record.hideField = false;
                                     this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                                 }
                                 else {
                                     record.hideField = true;
                                     this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                                 }
                             }
                         });
                     }, 1000);
                 }
             }).catch(error => {
                 console.log(error);
             })
         }
     
         handlePreview(event) {
             const documentId = event.target.dataset.id; // Fetch ContentDocumentId
             if (documentId) {
                 this[NavigationMixin.Navigate]({
                     type: 'standard__namedPage',
                     attributes: {
                         pageName:'filePreview'
                     },
                     state:{ 
                         selectedRecordId:documentId
                     }
                 });
             } else {
                 this.showToast('Error', 'No file available for preview.', 'error');
             }
         }
     
        //  async mapPermanentAddressToCurrentAddress() {
        //      const permanentAddressCmp = this.template.querySelector('c-loan-login-permanent-address-cmp');
        //      if(permanentAddressCmp) {
        //          try {
        //              const permanentAddressData = await permanentAddressCmp.fetchPermanentAddress();
        //              console.log('Fetched Permanent Address:', permanentAddressData);
         
        //              this.loadLookUps = false; // Initially set to false
         
        //              this.fieldDetails = this.fieldDetails.map(field => {
        //                  const mappedValue = permanentAddressData[field.Storage_Field__c];
        //                  const lookupName = permanentAddressData[field.Storage_Field__c + '_Name']; // Name
         
        //                  if (field.is_Lookup__c) {
        //                      console.log('Fetched Permanent Address insidepermanentAddressCmp:', JSON.stringify(permanentAddressData));
        //                      return {
        //                          ...field,
        //                          savedName: lookupName || '', // Display Name for the lookup
        //                          value: mappedValue || '', // Actual lookup ID
        //                      };
        //                  } else {
        //                      return {
        //                          ...field,
        //                          value: mappedValue !== undefined ? mappedValue : field.value,
        //                      };
        //                  }
        //              });
         
        //              console.log('Updated fieldDetails:', JSON.stringify(this.fieldDetails));
         
        //              // Introduce a 2-second delay before setting loadLookUps to true
        //              await new Promise(resolve => setTimeout(resolve, 2000));
        //              this.loadLookUps = true;
         
        //          } catch (error) {
        //              console.error('Error fetching permanent address:', error);
        //              this.showErrorMessage('Failed to fetch permanent address. Please try again.');
        //          }
        //      } else {
        //          console.error('Permanent Address Component not found.');
        //          this.showErrorMessage('Permanent Address Component not found.');
        //      }
        //  }
         
     
         @track contentDocIdCurrentAddressProof;
         @track isUploaded = false;
         async handleUploadAddressProof(event) {
             try {
                 console.log('recordId ' + this.recordId);
                 const uploadedFiles = event.detail.files;
                 this.contentDocIdCurrentAddressProof = uploadedFiles[0].documentId;
         
                 // Save the uploaded file
                 const result = await saveUploadedAddressProof({
                     loanId: this.recordId,
                     applicantType: 'Primary Applicant',
                     contentDocId: this.contentDocIdCurrentAddressProof
                 });
         
                 if (result) {
                     this.isUploaded = true;
                     this.mapPermanentAddressToCurrentAddress();
                     this.dispatchEvent(
                         new ShowToastEvent({
                             title: 'Success',
                             message: 'Address proof uploaded and saved successfully.',
                             variant: 'success'
                         })
                     );
                 }
             } catch (error) {
                 console.error('Error in handleUploadAddressProof:', error);
                 this.dispatchEvent(
                     new ShowToastEvent({
                         title: 'Error',
                         message: 'Failed to save uploaded address proof. Please try again.',
                         variant: 'error'
                     })
                 );
             }
         }
     
         clearCurrentAddressFields() {
             // Identify address-related fields dynamically based on their labels, types, or any identifiable properties
             const addressRelatedKeywords = ['Floor', 'Plot' , 'Street' , 'Town', 'State', 'Pincode', 'Landmark','District','Post']; // Common keywords in address fields
     
             if (!this.fieldDetails || this.fieldDetails.length === 0) {
                 console.error('fieldDetails is empty or undefined.');
                 return;
             }
     
             // Dynamically clear fields that match the keywords
             this.fieldDetails = this.fieldDetails.map(field => {
                 console.log('field.label:: '+field.label);
                 const isAddressField = addressRelatedKeywords.some(keyword =>
                     field.label?.toLowerCase().includes(keyword.toLowerCase()) || // Check field label
                     field.Storage_Field__c?.toLowerCase().includes(keyword.toLowerCase()) // Check API name
                 );
     
                 if (isAddressField) {
                     console.log(`Clearing field: ${field.Storage_Field__c || field.label}`);
                     return { ...field, value: '' }; // Clear the value
                 }
                 return field; // Retain other fields
             });
     
             console.log('Updated fieldDetails after clearing dynamic address fields:', JSON.stringify(this.fieldDetails));
         }
     
         @track createCurrentAddressSameAsPermanentAddress = false;
         handleChildValueChange(event) {
             // Capture the values passed from the child component
             this.showUploadCurrentAddressProofDoc = event.detail.showUploadCurrentAddressProofDoc;
             this.showScreenFieldLoginAppFields = event.detail.showScreenFieldLoginAppFields;
             this.uploadButtonLabel = event.detail.uploadButtonLabel;
             this.createCurrentAddressSameAsPermanentAddress = event.detail.createCurrentAddressSameAsPermanentAddress;
     
             console.log('Updated showUploadCurrentAddressProofDoc:', this.showUploadCurrentAddressProofDoc);
             console.log('Updated showScreenFieldLoginAppFields:', this.showScreenFieldLoginAppFields);
             console.log('Updated createCurrentAddressSameAsPermanentAddress:', this.createCurrentAddressSameAsPermanentAddress);
         }
     
         createCurrentAddress(){
             createCurrentAddressRecord({
                 loanId: this.recordId,
             }).then(result => {
                 console.log('createCurrentAddressRecord-->' + JSON.stringify(result));
             }).catch(error => {
                 console.log(error);
             })
         }
         
         @track showUploadCurrentAddressProofDoc = false;
      
         handleFocus(event) {
             const target = event.target;
             if (!target.firstChild) {
                 target.textContent = "";
             }
             this.lastValue = target.textContent; // Store initial value
         }
     
        //  handleInputChange(event) {
        //     event.stopPropagation();
        //     const target = event.target;
        //     const selection = window.getSelection();
        //     const range = document.createRange();
    
        //     // **Save Cursor Position**
        //     let cursorPos = selection.anchorOffset;
    
        //     const currentId = target.dataset.id;
        //     const currentField = target.dataset.name;
        //     let currentValue = target.textContent;
    
        //     console.log('currentId -->', currentId);
        //     console.log('currentField -->', currentField);
        //     console.log('currentValue -->', currentValue);
    
        //     // **Fix for Space Duplication Issue**
        //     if (event.inputType === "insertText" && event.data === " ") {
        //         event.preventDefault();
        //         let textNode = target.firstChild;
        //         if (textNode) {
        //             let text = textNode.nodeValue || "";
        //             let beforeCursor = text.slice(0, cursorPos);
        //             let afterCursor = text.slice(cursorPos);
        //             textNode.nodeValue = beforeCursor + " " + afterCursor;
        //             cursorPos += 1;
        //         }
        //     }
    
        //     // **Prevent Enter Key from Moving Cursor**
        //     if (event.inputType === "insertParagraph") {
        //         event.preventDefault();
        //     }
    
        //     // **Prevent Duplication Issue**
        //     if (this.lastValue === currentValue) {
        //         return;
        //     }
        //     this.lastValue = currentValue;
    
        //     // **Debounce Update to Avoid Unnecessary Rerenders**
        //     clearTimeout(this.inputTimeout);
        //     this.inputTimeout = setTimeout(() => {
        //         let recordIndex = this.fieldDetails.findIndex(record => record.Id === currentId && record.Storage_Field__c === currentField);
        //         if (recordIndex !== -1) {
        //             if (this.fieldDetails[recordIndex].value !== currentValue) {
        //                 this.fieldDetails[recordIndex] = { ...this.fieldDetails[recordIndex], value: currentValue };
        //                 this.fieldDetails = [...this.fieldDetails];
        //             }
        //         }
        //     }, 300);
    
        //     // **Restore Cursor Position**
        //     setTimeout(() => {
        //         if (target.firstChild) {
        //             let newCursorPos = Math.min(cursorPos, target.textContent.length);
        //             range.setStart(target.firstChild, newCursorPos);
        //             range.collapse(true);
        //             selection.removeAllRanges();
        //             selection.addRange(range);
        //         }
        //     }, 0);
        //  }
     
         handleKeyDown(event) {
             // Prevent Enter key from adding new lines
             if (event.key === "Enter") {
                 event.preventDefault();
             }
         }
         showToast(title, message, variant) {
             this.dispatchEvent(new ShowToastEvent({
                 title: title,
                 message: message,
                 variant: variant,
             }));
         }
         
     
         handleInputChangeCheckbox(event){
            event.stopPropagation();
            const currentId = event.target.dataset.id;
            const currentField = event.target.dataset.name;
            const isChecked = event.target.checked;
            console.log('currentId --> ' + currentId);
            console.log('currentField --> ' + currentField);
            console.log('isChecked --> ' + isChecked);
    
            this.fieldDetails.forEach(record => {
                if(record.Id == currentId && record.Storage_Field__c == currentField){
                    record.value = isChecked;
                    console.log('handleInputChange -->'+JSON.stringify(record));
                }
            });
         }
     
         handlebranchlookupselected(event){
             console.log('event -->'+JSON.stringify(event));
             this.fieldDetails.forEach(record => {
                 if(record.Storage_Field__c == 'Branch__c'){
                     record.savedName = event.detail.Name;
                     record.value = event.detail.id;
                 }
             });
         }
     
         handlebranchlookupdeselected(event){
             this.fieldDetails.forEach(record => {
                 if(record.Storage_Field__c == 'Branch__c'){
                     record.value = '';
                     record.savedName = '';
                 }
             });
         }
     
         handlepincodelookupselected(event){
            try{
                console.log('inside search');
                console.log('event.detail=:'+JSON.stringify(event.detail));
                this.fieldDetails.forEach(record => {
                    if(record.Read_Field_Name__c.includes('Pincode__') && record.Storage_Field__c.includes('Pincode__')){
                    console.log('event.detail.searchRecord.Name=:'+event.detail.searchRecord.Name);
                    console.log('event.detail.searchRecord.Id=:'+event.detail.searchRecord.Id);
                    record.savedName = event.detail.searchRecord.Name;
                    record.value = event.detail.searchRecord.Id;
                    console.log('record.value: '+record.value);
                    }
                    // else if(record.Read_Field_Name__c == 'Town__c' && record.Storage_Field__c == 'Town__c'){
                    //     record.value = event.detail.searchRecord.Town__c;
                    // }
                    // else if(record.Read_Field_Name__c == 'District__c' && record.Storage_Field__c == 'District__c'){
                    //     record.value = event.detail.searchRecord.District__c;
                    // }
                    // else if(record.Read_Field_Name__c == 'State__c' && record.Storage_Field__c == 'State__c'){
                    //     record.value = event.detail.searchRecord.State__c;
                    // }
                    // else if(record.Read_Field_Name__c == 'Post_Office__c' && record.Storage_Field__c == 'Post_Office__c'){
                    //     record.value = event.detail.searchRecord.Post_Office__c;
                    // }
                });
            }
            catch(error){
                // console.log('error catch =:'+JSON.stringify(error))
            }
            
         }
     
         handlepincodelookupdeselected(event){
            try{
                setTimeout(()=>{
                    this.fieldDetails.forEach(record => {
                        if(record.Read_Field_Name__c.includes('Pincode__') && record.Storage_Field__c.includes('Pincode__')){
                            record.value = '';
                            record.savedName = '';
                        }
                        else if(record.Read_Field_Name__c == 'Town__c' && record.Storage_Field__c == 'Town__c'){
                            record.value = '';
                        }
                        else if(record.Read_Field_Name__c == 'District__c' && record.Storage_Field__c == 'District__c'){
                            record.value = '';
                        }
                        else if(record.Read_Field_Name__c == 'State__c' && record.Storage_Field__c == 'State__c'){
                            record.value = '';
                        }
                        else if(record.Read_Field_Name__c == 'Post_Office__c' && record.Storage_Field__c == 'Post_Office__c'){
                            record.value = '';
                        }
                    });
                },100)
                
            }
            catch(error){
                // console.log('error catch =:'+JSON.stringify(error))
            }
         }
     
         @track permanentAddressData = {};
         confirmpermanentfilled(event){
             this.permanentAddressFilled = true;
             console.log('this.permanentAddressData -->'+JSON.stringify(event.detail));
             this.permanentAddressData = event.detail;
             console.log('this.permanentAddressData -->'+JSON.stringify(this.permanentAddressData));
         }
     
         showErrorMessage(message) {
             this.dispatchEvent(
                 new ShowToastEvent({
                     title: 'Error',
                     message: message,
                     variant: 'error',
                 })
             );
         }
     
        
     
        
     
         skipAction(){
             this.currentScreenSequence = this.currentScreenSequence + 1;
             if (this.currentScreenSequence < 20) {
                 this.getCurrentScreenFieldDetails();
                 //this.getCompletionPercent();
     
                 const valueSelectedEvent = new CustomEvent('refreshmenucmp', { detail: {loanId: this.recordId} });
                 this.dispatchEvent(valueSelectedEvent);
     
                 this.getScreenDetailsFromApex();
                 //this.getCompletionPercent();
             }
             else {
                 this.currentScreenSequence = this.currentScreenSequence - 1;
             } 
         }
     
         
     
         saveAndNext(event) {
             this.currentScreenSequence = this.currentScreenSequence + 1;
             if (this.currentScreenSequence < 20) {
                 this.getCurrentScreenFieldDetails();
                 //this.getCompletionPercent();
     
                 const valueSelectedEvent = new CustomEvent('refreshmenucmp', { detail: {loanId: this.recordId} });
                 this.dispatchEvent(valueSelectedEvent);
     
                 this.getScreenDetailsFromApex();
                 //this.getCompletionPercent();
             }
             else {
                 this.currentScreenSequence = this.currentScreenSequence - 1;
             }
           
         }
         handleAANext(){
             this.showSpinner=true;
             setTimeout(() => {
                 this.showSpinner=false;
             }, 10000);
             this.currentScreenSequence = this.currentScreenSequence +1;
             this.getCurrentScreenFieldDetails();
         }
         
         handleBlur(event) {
            event.stopPropagation();
             let itemId = event.target.dataset.id;
             let newValue = event.target.textContent.trim();
         
             // Ensure max length is respected
             let maxLength = event.target.dataset.maxlength;
             if (maxLength && newValue.length > maxLength) {
                 newValue = newValue.substring(0, maxLength);
                 event.target.textContent = newValue;
             }
         
             // Update the list with the new value
             this.items = this.items.map(item => {
                 if (item.Id === itemId) {
                     return { ...item, value: newValue };
                 }
                 return item;
             });
         }
     
     
         lastValue = ""; // Store the last entered value
     
         handleFocus(event) {
             const target = event.target;
             if (!target.textContent.trim()) {
                 target.textContent = ""; // Ensure field starts empty to avoid duplication
             }
             this.lastValue = target.textContent; // Store initial value to compare
         }
     
        // handleInputChange(event) {
        //     event.stopPropagation();
        //     const target = event.target;
        //     const selection = window.getSelection();
        //     const range = document.createRange();
        //     let currentValue = target.textContent;
        //     this.updateFieldDetails(target.dataset.id, target.dataset.name, currentValue);
        // }
     
         handleKeyDown(event) {
             // **Prevent Enter Key from Adding New Lines**
             if (event.key === "Enter") {
                 event.preventDefault();
             }
         }
     
         handleBlur(event) {
             const target = event.target;
             if (!target.textContent.trim()) {
                 target.textContent = ""; // Avoid duplication issues
             }
         }
     
         updateFieldDetails(id, field, value) {
             let recordIndex = this.fieldDetails.findIndex(record => record.Id === id && record.Storage_Field__c === field);
             if (recordIndex !== -1) {
                 if (this.fieldDetails[recordIndex].value !== value) {
                     this.fieldDetails[recordIndex] = { ...this.fieldDetails[recordIndex], value };
                     // this.fieldDetails = [...this.fieldDetails]; // Ensure LWC reactivity
                 }
             }
         }
     
         handleBlur(event) {
             const fieldName = event.target.dataset.name;
             const value = event.target.textContent.trim();
             for (let i = 0; i < this.fieldDetails.length; i++) {
                 if(this.fieldDetails[i].Id === event.target.dataset.id) {
                      this.fieldDetails[i].value = value;
                 }
                 
                 
             }
             
             console.log(`Field: ${fieldName}, Value: ${value}`);
             console.log('fieldDetailsails',JSON.stringify(this.fieldDetails));
             // Save or update logic here
         }
     
         handleInputChange(event) {
            event.stopPropagation();
            const currentId = event.target.dataset.id;
            const currentField = event.target.dataset.name;
            const currentValue = event.target.value;
            console.log('currentId --> ' + currentId);
            console.log('currentField --> ' + currentField);
            console.log('currentValue --> ' + currentValue);
    
            this.firstLoad = false;
    
            if(currentField == 'DOB__c'){
                var regexVar = /^([0-9]{2})\/([0-9]{2})\/([0-9]{4})$/;
        
                let currentDate = new Date().toJSON().slice(0, 10)
                var userBirthDate = new Date(currentValue.replace(regexVar, "$3-$2-$1"));  
                var todayYear = (new Date()).getFullYear(); // Always use FullYear!!
                var cutOff19 = new Date(); // should be a Date
                cutOff19.setFullYear(todayYear - 21); // ...  
                console.log('todayDate----',new Date());
                console.log('this.dateofBirth----',currentValue);
            
                if(this.currentValue>=currentDate){
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Date of birth cannot be future/current date',
                        variant: 'Error',
                    }));
                    this.template.querySelector(`[data-id="${currentId}"]`).value='';
                    return;
                }
                else if (userBirthDate > cutOff19){
                    console.log('age----',18*365);
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Age should not be less than 18years',
                        variant: 'Error',
                    }));
                    this.template.querySelector(`[data-id="${currentId}"]`).value='';
                    return;
                }
                else{
                    this.fieldDetails.forEach(record => {
                        if(record.Id == currentId && record.Storage_Field__c == currentField){
                            record.value = currentValue;
                            // console.log('handleInputChange -->'+JSON.stringify(record));
                        }
                    });
                }
            }
            
            else if(currentField == 'Mobile_Number__c'){
                if(isNaN(Number(event.target.value)) || event.target.value ==''){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter in correct format',
                            variant: 'error',
                        }),
                    );
                    if(this.template.querySelector(`[data-id="${currentId}"]`).value != undefined){
                        this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                    }
                    else{
                        this.template.querySelector(`[data-id="${currentId}"]`).value='';
                    }
                    return;
                }
                else{
                    this.fieldDetails.forEach(record => {
                        if(record.Id == currentId && record.Storage_Field__c == currentField){
                            record.value = currentValue;
                            console.log('handleInputChange -->'+JSON.stringify(record));
                        }
                    });
                }
            }
            else{
                if(this.screenName == `Confirm Applicant's Basic Details`){
                    if(currentField == 'Is_Current_Address_Same_As_Permanent__c' && (currentValue== 'No')){
                        console.log('Inside----735' );
                        this.showPermanentAdr = true;
                        this.permanentAddressFilled = true;
                        this.showUploadCurrentAddressProofDoc = true;
                    }
                    else{
                        this.showPermanentAdr = false;
                        this.permanentAddressFilled = false;
                        this.showUploadCurrentAddressProofDoc = false;
                    }
                }
            
                var textreg = /^[A-Za-z]*$/;
                var numregex = '^[0-9]*$';
                if(event.target.name == 'Text' && this.screenName != 'Confirm Address Information' && this.screenName != 'Reference Details'){
                    if(/*currentId == 'CIN__c' || */ currentField == 'Reference_Phone_1__c' || currentField == 'Reference_Phone_2__c' || currentField == 'Mobile_Number__c' || currentField == 'Floor_Number__c'){
                        if(isNaN(Number(event.target.value ))){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'Please enter in correct format.',
                                    variant: 'error',
                                }),
                            );
                            // this.fieldsDataMap[currentId] ='';
                            // str.replace(/.$/, '')
                            if(this.template.querySelector(`[data-id="${currentId}"]`).value != undefined){
                                this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                            }
                            else{
                                this.template.querySelector(`[data-id="${currentId}"]`).value='';
                            }
                            // this.template.querySelector(`[data-id="${currentId}"]`).value=lastval;
                            return;
                        }
                    }
                    else{
                        if(!currentValue.match(textreg)){
                            if(currentField != 'Floor_Number__c' && currentField != 'Registration_Number__c' && currentField != 'Udhyam_Registration_No__c' 
                                && currentField != 'Landmark__c' && currentField != 'Reference_Address_1__c' && currentField != 'Plot_Number__c' && currentField != 'Company__c' 
                                && currentField != 'Reference_Address_2__c' && currentField != 'CIN_LLPIN_number__c'){
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: 'Please enter in correct format.',
                                        variant: 'error',
                                    }),
                                );
                                if(this.template.querySelector(`[data-id="${currentId}"]`).value != undefined){
                                    this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                                }
                                else{
                                    this.template.querySelector(`[data-id="${currentId}"]`).value='';
                                }
                                // this.template.querySelector(`[data-id="${currentId}"]`).value=lastval;
                                return;
                            }
                        }
                    }
                    
                }
                else if(event.target.name == 'Number' && this.screenName != 'Confirm Address Information' && this.screenName != 'Reference Details'){
                    console.log('inside number');
                    if(isNaN(Number(currentValue)) || event.target.value ==''){
                        console.log('pattern mismatch');
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'Please enter in correct format.',
                                variant: 'error',
                            }),
                        );
                        this.fieldsDataMap[currentId] ='';
                        if(this.template.querySelector(`[data-id="${currentId}"]`).value != undefined){
                            this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                        }
                        else{
                            this.template.querySelector(`[data-id="${currentId}"]`).value='';
                        }
                        return;
                    }
                }
                // console.log('currentField -->'+currentField);
    
                const currentFieldDetails = this.fieldDetails.find(item => item.Storage_Field__c == currentField);
                // console.log('currentFieldDetails -->'+JSON.stringify(currentFieldDetails));
    
                this.fieldDetails.forEach(record => {
                    if(record.Id == currentId && record.Storage_Field__c == currentField){
                        record.value = currentValue;
                        console.log('handleInputChange -->'+JSON.stringify(record));
                    }
                });
    
                //For handling visibility for dependent item
                this.fieldDetails.forEach(record => {
                    if(record.Visibility_Controlled_By__c == currentId && record.Id != currentId){
                        const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                        if (arrDependentControlledValue.find(element => element == currentValue.toLowerCase())) {
                            console.log('inside show');
                            record.hideField = false;
                            this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                        }
                        else {
                            console.log('inside hide');
                            // record.value = '';
                            record.hideField = true;
                            this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                        }
                    }
                });
    
                //For handling controlling and dependent picklist values
                if (currentFieldDetails.Is_Controlling_Picklist__c) {
                    getFieldDependencies({
                        objectName: currentFieldDetails.Storage_Object__c,
                        controllingField: currentFieldDetails.Storage_Field__c,
                        dependentField: currentFieldDetails.Dependent_Picklist__c
                    }).then(result => {
                        console.log('dependent picklist values List=:' + JSON.stringify(result));
                        const dependentPicklistOptions = result[currentValue];
                        const targetId = this.fieldDetails.find(item => item.Storage_Field__c == currentFieldDetails.Dependent_Picklist__c);
                        this.template.querySelector(`[data-id="${targetId.Id}"]`).options = dependentPicklistOptions;
                    }).catch(error => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: error.body.message,
                                variant: 'error',
                            }),
                        );
                    })
                }
            }
         }

         handleDropdownClick(event) {
            event.stopPropagation(); // Prevents dropdown from closing immediately
            let recordId = event.currentTarget.dataset.id;
        
            this.records = this.records.map(record => ({
                ...record,
                isDropdownOpen: record.Id === recordId ? !record.isDropdownOpen : false
            }));
        
            // Close dropdown when clicking outside
            document.addEventListener("click", this.closeDropdown);
        }
        
        handleSelection(event) {
            let recordId = event.currentTarget.dataset.id;
            let fieldName = event.currentTarget.dataset.name;
            let fieldValue = event.currentTarget.dataset.value;
        
            // Update the selected value and close the dropdown
            this.records = this.records.map(record => {
                if (record.Id === recordId) {
                    return { ...record, [fieldName]: fieldValue, isDropdownOpen: false };
                }
                return record;
            });
        
            // Save only the modified field
            this.saveFieldUpdate(recordId, fieldName, fieldValue);
        
            // Remove event listener after selection
            document.removeEventListener("click", this.closeDropdown);
        }
        
        closeDropdown = (event) => {
            if (!event.target.closest(".editable-field")) {
                this.records = this.records.map(record => ({ ...record, isDropdownOpen: false }));
                document.removeEventListener("click", this.closeDropdown);
            }
        };
        
        saveFieldUpdate(recordId, fieldName, fieldValue) {
            console.log(`Saving ${fieldName} for ${recordId} with value: ${fieldValue}`);
            // Call Apex method to save field
        }

        toggleDropdown() {
            this.isDropdownOpen = !this.isDropdownOpen;
        }
    
        handleSelect(event) {
            this.selectedValue = event.currentTarget.dataset.value;
            this.selectedLabel = this.options.find(opt => opt.value === this.selectedValue).label;
            this.isDropdownOpen = false; // Close dropdown after selection
        }
    
        handleClickOutside(event) {
            if (!this.template.contains(event.target)) {
                this.isDropdownOpen = false;
            }
        }
        toggleDropdown(event) {
            console.log('Inside 1590---',event.target.dataset.id)
          
            // this.isDropdownOpen = !this.isDropdownOpen;
            this.fieldDetails.forEach(record => {
                console.log('Inside 1594---',record.Id)
                console.log('Inside 1595---',event.currentTarget.dataset.id)
                if (record.Id === event.currentTarget.dataset.id) {
                    record.isDropdownOpen = !record.isDropdownOpen;
                    console.log('Inside 1595---',event.currentTarget.dataset.id)
                }
                else{
                    record.isDropdownOpen = false;
                }
            });
        }
    
        handleSelect(event) {
            console.log('handleSelect triggered');
        
            // Retrieve selected values from dataset
            const currentId = event.target.dataset.id;
            const currentField = event.target.dataset.name;
            const currentValue = event.target.dataset.value;
        
            console.log('currentId --> ' + currentId);
            console.log('currentField --> ' + currentField);
            console.log('currentValue --> ' + currentValue);
        
            // Ensure fieldDetails exist
            if (!this.fieldDetails || this.fieldDetails.length === 0) {
                console.error('fieldDetails is empty or undefined');
                return;
            }
        
            // Find the selected field details
            const currentFieldDetails = this.fieldDetails.find(item => item.Storage_Field__c === currentField);
            if (!currentFieldDetails) {
                console.error('No matching field found for:', currentField);
                return;
            }
        
            // Update the field's value
            this.fieldDetails = this.fieldDetails.map(record => {
                if (record.Id === currentId && record.Storage_Field__c === currentField) {
                    return { ...record, value: currentValue };
                
                }
                return record;
            });
            this.fieldDetails.forEach(record => {
                record.isDropdownOpen = false;
            });
            console.log('Dropdown closed');

        
            console.log('Updated fieldDetails:', JSON.stringify(this.fieldDetails));
        
            // Handling dependent fields (show/hide logic)
            this.fieldDetails.forEach(record => {
                if (record.Visibility_Controlled_By__c === currentId && record.Id !== currentId) {
                    const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                    if (arrDependentControlledValue.includes(currentValue.toLowerCase())) {
                        console.log('inside show');
                        record.hideField = false;
                        this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                    } else {
                        console.log('inside hide');
                        record.hideField = true;
                        this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                    }
                }
            });
        
            // Handle controlling & dependent picklists
            if (currentFieldDetails.Is_Controlling_Picklist__c) {
                getFieldDependencies({
                    objectName: currentFieldDetails.Storage_Object__c,
                    controllingField: currentFieldDetails.Storage_Field__c,
                    dependentField: currentFieldDetails.Dependent_Picklist__c
                }).then(result => {
                    console.log('Dependent picklist values:', JSON.stringify(result));
                    const dependentPicklistOptions = result[currentValue];
                    const targetField = this.fieldDetails.find(item => item.Storage_Field__c === currentFieldDetails.Dependent_Picklist__c);
        
                    if (targetField) {
                        this.template.querySelector(`[data-id="${targetField.Id}"]`).options = dependentPicklistOptions;
                    }
                }).catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: error.body.message,
                            variant: 'error',
                        }),
                    );
                });
            }
        
            // Update UI for selected value
          
        }
        
        handleFocusOut(event) {
            setTimeout(() => {
                this.fieldDetails.forEach(record => {
                    record.isDropdownOpen = false;
                });
            } , 100);
           
        }
        handleBlur(event) {
            setTimeout(() => {
                this.fieldDetails.forEach(record => {
                    record.isDropdownOpen = false;
                });
            } , 100);
        }

        
    showCustomCmp(cmpName) {
        this.onePage = false;
        this.showIncomeScreen = false;
        this.showBSAScreen = false;
        this.showSalesLoginPrimaryApplicantInfoScreen = false;
        this.cibilOneView= false;
        this. showCibilEligibility = false;
        this.showPrimaryApplicantInfoScreen = false;
        this.showAddressDetails = false;
        console.log('cmpName:::: '+cmpName);
        switch (cmpName) {
          
            case 'SalesIncomeEligibilityCmp':
                this.showIncomeScreen = true;
              
                break;
            case 'SalesLoginBSAScreenCmp':
                this.showBSAScreen = true;
                break;
            case 'SalesLoanLoginAddressDetails':
                this.showAddressDetails = true;
                break;
            case 'CibilOneViewCmp':
               this.cibilOneView = true;
                break;
            case 'CibilEligibility':
                this.showCibilEligibility = true;
                break;
            case 'SalesLoginPrimaryApplicantInfoCmp':
                this.showSalesLoginPrimaryApplicantInfoScreen = true;
                break;
            default:
              
                
        }
    }
    handleFocus(event){
        event.stopPropagation();
    }
    handleKeepAccordionOpen(event){
        this.dispatchEvent(new CustomEvent('keepaccordionopen', {
            bubbles: true,
            composed: true
        }));
    } 
        
        
        


  
}