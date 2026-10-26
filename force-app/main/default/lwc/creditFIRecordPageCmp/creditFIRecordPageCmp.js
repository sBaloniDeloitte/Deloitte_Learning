import { LightningElement,track, api, wire  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getScreenDetails from '@salesforce/apex/ScreenGenerationController.getScreenDetails';
import getPicklistValues from '@salesforce/apex/ScreenGenerationController.getPicklistValues';
import FORM_FACTOR from '@salesforce/client/formFactor';
import USERID_FIELD from "@salesforce/user/Id";
import STAGE_FIELD from "@salesforce/schema/Application_Verification__c.Stage__c";
import { getRecord } from "lightning/uiRecordApi";
import saveLoanDetails from '@salesforce/apex/ScreenGenerationController.saveLoanDetails';
import getFieldDependencies from '@salesforce/apex/ScreenGenerationController.getFieldDependencies';
import getLoanDetailsFromReadObject from '@salesforce/apex/ScreenGenerationController.getLoanDetailsFromReadObject';
import getLoanDetailsFromStorageObject from '@salesforce/apex/ScreenGenerationController.getLoanDetailsFromStorageObject';
import getFiStatus from '@salesforce/apex/Credit_FIVerificationController.getFiStatus';
import recordTypeId from '@salesforce/apex/Credit_FIVerificationController.recordTypeId';
import updateDocumentChecklist from '@salesforce/apex/Credit_FIVerificationController.updateDocumentChecklist';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getLatestDocumentUrl from '@salesforce/apex/Credit_FIVerificationController.getLatestDocumentUrl';
import samplePDF from '@salesforce/resourceUrl/FI_PDF';
import { updateRecord } from "lightning/uiRecordApi";
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import customLoadStyles from '@salesforce/resourceUrl/waiverDoc';
import { loadStyle } from 'lightning/platformResourceLoader';
import getOpportunityTeamMembers from '@salesforce/apex/Credit_FIVerificationController.getOpportunityTeamMembers';
import FI_OBJECT from '@salesforce/schema/Application_Verification__c';



export default class CreditFIRecordPageCmp extends LightningElement {
    @api recordId;
    @track fieldDetails;
    @track filteredScreenDetails;
    @track allFieldDetails =[];
    @track screenName;
    @track screenObject;
    @track PANPage = false;
    @track fieldsDataMap = {};
    @track fieldsObjectMap = {};
    @track isCustomCmp = false;
    @track customCmpName;
    currentSeq = 0;
    onePage = false;
    picklistOptionsFromApex;
    saveandnext = "Save & Next";
    cmpNameCheck;
    @track passedScreenName;
    isRendered = false;
    @track formIdentifier;
    @track showSpinner = false;
    @track detailsList;
    @track currentScreenSequence=1;
    @track small=false;
    @track disableButton=false;
    @track pdfURL;
    @track showPDF=false;
    @track showDetailsFilledData=false;
    @track showImageCapture=false;
    @track showNextButton;
    @track disableUpload=false;
    sfdcBaseURL;
    @wire(CurrentPageReference) pageRef;
    samplePDF=samplePDF;
    recordTypeName
    currentUserOppRole=[];
    oppStage = '';
    oppSubStage = '';

    get acceptedFormats() {
        return ['.pdf'];
    }

 @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD] })
    opportunity({ error, data }) {
        if(data) {
            console.log('inside data>>>',data)
            this.oppStage = data.fields.Stage__c.value;
        }
    }
  
    connectedCallback(){
        this.recordTypeId();
        this.getPDFURL();
        if (FORM_FACTOR == 'Small') {
                this.small = true;
                this.addEventListeners();
            }
            Promise.all([
                loadStyle(this, customLoadStyles )
            ]).then(() => {
                console.log('Upload success')
            }).catch( (error) => {
                console.error(error);
            })
             setTimeout(() => {
            this.setPageEditability();
        }, 3000);
    }
     async setPageEditability(){

        console.log('currentUserOppRole: '+this.currentUserOppRole);
        console.log('oppStage: '+this.oppStage);
        console.log('oppSubStage: '+this.oppSubStage);

        if(this.currentUserOppRole.includes('Credit')){
             if(this.fieldDetails){
                    this.fieldDetails.forEach(item => {
                        console.log('inside disable')
                        item.Is_Disabled__c=true;
                        this.disableUpload=true;
                    })
                }
        }
     }
    recordTypeId(){
        recordTypeId({recordId:this.recordId})
        .then(result=>{
            console.log('recordTypeName--'+this.recordTypeName);
            if(this.recordTypeName=='Residence Verification' || this.recordTypeName=='Collateral Verification'){
                this.formIdentifier='Field Investigation Form';
            }else{
                this.formIdentifier='Field Investigation Form Business';
            }

            if(result!=null && (result=='Residence Verification' || result =='Collateral Verification')){
                this.formIdentifier='Field Investigation Form';
            }else{
                this.formIdentifier='Field Investigation Form Business';
            }
            this.getFiStatus();
            var detail = {};
            detail["isPullToRefreshEnabled"] = false;
            var updateScrollSettingsEvent = new CustomEvent("updateScrollSettings", {
            detail: detail,
            bubbles: true,
            composed: true
            });
            dispatchEvent(updateScrollSettingsEvent);
            console.log('saveAndNext=:' + this.recordId);
            this.getScreenDetailsFromApex();
        })
    }
    recordTypeId(){
        recordTypeId({recordId:this.recordId})
        .then(result=>{
            console.log('recordTypeId--'+result);
            if(result!=null && result== 'Personal Discussion AHL'){
                this.formIdentifier='Vendor PD';
            }else if(result!=null && (result=='Residence Verification' || result =='Collateral Verification')){
                this.formIdentifier='Field Investigation Form';
            }else{
                this.formIdentifier='Field Investigation Form Business';
            }
            this.getFiStatus();
            var detail = {};
            detail["isPullToRefreshEnabled"] = false;
            var updateScrollSettingsEvent = new CustomEvent("updateScrollSettings", {
            detail: detail,
            bubbles: true,
            composed: true
            });
            dispatchEvent(updateScrollSettingsEvent);
            console.log('saveAndNext=:' + this.recordId);
            this.getScreenDetailsFromApex();
        })
    }
    getFiStatus(){
        getFiStatus({recordId:this.recordId})
        .then(result => {
            console.log('result-102---'+result);
            if(result!=null && result==true){
                if(this.fieldDetails){
                    this.fieldDetails.forEach(item => {
                        item.Is_Disabled__c=true;
                        this.disableUpload=true;
                    })
                }
            }
        })
        .catch(error => {
        })
    }
    //added by kalpesh
     @wire(getOpportunityTeamMembers, {
        loanId: "$recordId",
    })
    getOppTeamMembers({data,error}) {
        if (data) {
            console.log('data ',data);
            data.forEach(item => {
                console.log('User Data',USERID_FIELD);
                console.log('user id',item.UserId);
                if(item.UserId == USERID_FIELD){
                    console.log('inside user match');
                    this.currentUserOppRole.push(item.TeamMemberRole);    
                }
            })
            console.log('Current user role ',this.currentUserOppRole);
        } else if (error) {
            this.handleError(error, 'gotLoanFields');
            this.showToast(this.toastTitle.ERROR, this.toastMessages.SOMETHING_WENT_WRONG, this.toastVariant.ERROR);
        }
    }
    
    addEventListeners() {
        window.addEventListener('touchmove', this.preventPullToRefresh, { passive: false });
        window.addEventListener('touchstart', this.preventPullToRefresh, { passive: false });
    }
    preventPullToRefresh(event) {
        if (event.touches.length > 1) {
            event.preventDefault();
        }
    }

    disconnectedCallback() {
        window.removeEventListener('touchmove', this.preventPullToRefresh);
            window.removeEventListener('touchstart', this.preventPullToRefresh);
    }
    getScreenDetailsFromApex() {
        console.log('form identifier>'+this.formIdentifier);
        console.log('loan id>'+this.recordId);
        getScreenDetails({formIdentifier: this.formIdentifier, loanId:this.recordId})
            .then(result => {
                if (result) {
                    this.allFieldDetails = result;
                    console.log('inside screen seq getScrrefromapex=:'+this.currentScreenSequence);
                    console.log('getScreenDetailsFromApex allFieldDetails=:'+JSON.stringify(this.allFieldDetails));
                    this.getCurrentScreenFieldDetails();
                }
            }).catch(error => {
                console.log('error : ' + error);
            });
         
    }
    getCurrentScreenFieldDetails() {
        this.screenObject = null;
        this.fieldDetails = null;
        this.screenName = null;
        this.isCustomCmp = false;
        console.log('this.allFieldDetails=:' + JSON.stringify(this.allFieldDetails));
 
 
        if (this.passedScreenName) {
            this.filteredScreenDetails = this.allFieldDetails.filter(item => item.Parent_Screen__r.Master_Screen_Name__c == this.passedScreenName);
            console.log('filteredScreenDetails : ', JSON.stringify(this.filteredScreenDetails));
            this.filteredScreenDetails.forEach(item => { this.currentSeq = item.Parent_Screen__r.Screen_Sequence__c; });
            console.log('currentSeq : ', this.currentSeq);
            this.currentScreenSequence = this.currentSeq;
        }
        console.log('this.currentScreenSequence=:'+this.currentScreenSequence);
        this.filteredScreenDetails = this.allFieldDetails.filter(item => item.Parent_Screen__r.Screen_Sequence__c == this.currentScreenSequence && item.Form_Name__c  == this.formIdentifier);
 
        this.filteredScreenDetails.forEach(element => { this.cmpNameCheck = element.Custom_Component_Name__c });
        console.log('this.filteredScreenDetails -->'+JSON.stringify(this.filteredScreenDetails));
        console.log('this.cmpNameCheck -->'+JSON.stringify(this.cmpNameCheck));
        this.onePage = true;
        this.filteredScreenDetails.forEach(item => { this.screenName = item.Parent_Screen__r.Master_Screen_Name__c; });
            this.filteredScreenDetails.forEach(item => { this.screenObject = item.Storage_Object__c; });
            this.fieldDetails = this.filteredScreenDetails;
 
            this.fieldDetails.forEach(item => {
                item.isPicklist = item.Field_Type__c === 'Picklist';
            });
 
            this.fieldDetails.forEach(async item => {
                if(item.Picklist_Dependent_On_RecordType__c){
                    console.log('item.Filtered_Picklist_Values__c=:'+JSON.stringify(item.Filtered_Picklist_values__c));
                    item.picklistOptions = await this.getFilteredPicklistValues(item.Filtered_Picklist_values__c);
                }
                else{
                    item.picklistOptions = await this.getPicklistOptionsFromApex(item.isPicklist, item.Storage_Object__c, item.Storage_Field__c);
                }
                // item.picklistOptions = await this.getPicklistOptionsFromApex(item.isPicklist, item.Storage_Object__c, item.Storage_Field__c);
                
            });
            console.log('fieldDetails : ', JSON.stringify(this.fieldDetails));
            this.passedScreenName = null;
            setTimeout(() => {
                this.getFIDetails();
                this.getFiStatus();
            }, 1000);
    }
    getFIDetails(){
        getLoanDetailsFromStorageObject({
            screenName: this.screenName,
            loanId: this.recordId,
            formIdentifier: this.formIdentifier,
            recordId:this.recordId
        }).then(result => {
            this.showLoader = false;
            var isFetchFromReadObject = true;
            if(this.fieldDetails){
                result.forEach(item => {
                    isFetchFromReadObject = false;
                    console.log(' this.fieldDetails----- 21333'+ JSON.stringify(this.fieldDetails));
                    this.fieldDetails.forEach(record => {
                        if(item.fieldApiName == record.Storage_Field__c && record.is_Lookup__c==true){
                            record.savedName = item.fieldValue;
                            record.value = item.fieldValue;
                            console.log('record -->'+JSON.stringify(record));
                        }else if(item.fieldApiName == record.Storage_Field__c){
                            record.value = item.fieldValue;
                        }
                    });
                });      
                
                
                setTimeout(() => {
                    this.fieldDetails.forEach(record => {
                        if(record.Visibility_Controlled_By__c != null && record.Visibility_Controlled_By__c != '' && record.Visibility_Controlled_By__c != undefined){
                            
                            const dependentField = this.fieldDetails.find(item => item.Id == record.Visibility_Controlled_By__c);
                            console.log('dependentField=:'+JSON.stringify(dependentField));
                            const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                            console.log('arrDependentControlledValue=:'+JSON.stringify(arrDependentControlledValue));
                            if(dependentField.value != null && dependentField.value != '' && dependentField.value && dependentField.value != undefined){
                                console.log('inside if');
                                if(arrDependentControlledValue.find(element => element == dependentField.value.toLowerCase())){
                                    record.hideField = false;
                                    this.template.querySelector(`[data-id="${record.Storage_Field__c}"]`).classList.remove('slds-hide');
                                }
                                else {
                                    record.hideField = true;
                                    console.log('inside hide');
                                    this.template.querySelector(`[data-id="${record.Storage_Field__c}"]`).classList.add('slds-hide');
                                }
                            }else{
                                record.hideField = false;
                                console.log('inside else');
                                this.template.querySelector(`[data-id="${record.Storage_Field__c}"]`).classList.add('slds-hide');
                            }
                        }
                        else{
                            record.hideField = false;
                        }
                    });
                }, 1000);
            }

            return ({ isFetchFromReadObject: isFetchFromReadObject });
        }).then(res => {
            if (res.isFetchFromReadObject) {
                // this.getLoanDetailsFromReadObject();
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
            formIdentifier: this.formIdentifier
        }).then(result => {
            console.log('detailsWrapperList -->' + JSON.stringify(result));
            
            if(this.fieldDetails){
                result.forEach(item => {
                    isFetchFromReadObject = false;
                    
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
                                this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                            }
                            else {
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
    async getFilteredPicklistValues(picklistValues){
        console.log('picklistValues=:'+picklistValues);
        var tempVal = picklistValues.split(',');
        console.log('tempVal=:'+tempVal);
        let picklistOptions=[];
        for(var i=0;i<tempVal.length;i++){
            let doc = { label: tempVal[i], value: tempVal[i] };
            picklistOptions.push(doc);
            // var opt = {label: tempVal,value: tempVal};
            // picklistOptions.push(opt);
        }
        console.log('picklistOptions=:'+picklistOptions);
        return picklistOptions;
    }
    async getPicklistOptionsFromApex(isPicklist, storageObject, storageField) {
        if (isPicklist) {
            const result = await getPicklistValues({storageObject: storageObject, storageField: storageField });
            console.log('success!', JSON.stringify(result));
            let picklistOptions = result.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });
            console.log('picklistOptions!', JSON.stringify(picklistOptions));
            return picklistOptions;
        }
    }

    validateSaveAndNext() {
        console.log('Inside 297');
        if (this.PANPage === true) {
            this.PANPage = false;
            this.onePage = true;
            this.currentScreenSequence = this.currentScreenSequence + 1;
            this.getCurrentScreenFieldDetails();
        } else {
            console.log('Inside 304');
            this.showLoader = true;
            var isSaveLoanDetails = true;
            var fieldsAndMandatoryMap = {};

            if (this.fieldDetails) {
                console.log('Inside 310'+JSON.stringify(this.fieldDetails));
                this.fieldDetails.forEach(record => {
                    var tempfieldDataMap = {};
                    if(!record.Is_Formula_Feild__c){
                        if(record.Is_Mandatory__c){
                            console.log('Inside 315'+record.Is_Mandatory__c);
                            console.log('record.Visibility_Controlled_By__c--'+record.Visibility_Controlled_By__c);
                            if(record.Visibility_Controlled_By__c != null && record.Visibility_Controlled_By__c != '' && record.Visibility_Controlled_By__c != undefined){
                                console.log('record---'+record.value);
                                const dependentField = this.fieldDetails.find(item => item.Id == record.Visibility_Controlled_By__c);
                                console.log('dependentField----'+dependentField);
                                const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                                console.log('arrDependentControlledValue----'+arrDependentControlledValue);
                                if (arrDependentControlledValue.find(element => element == dependentField.value.toLowerCase())  && (record.value == null || record.value == '' || record.value == undefined)) {
                                    this.showLoader = false;
                                    this.dispatchEvent(
                                        new ShowToastEvent({
                                            title: 'Error',
                                            message: 'Please fill all the mandatory fields in order to proceed',
                                            variant: 'Error',
                                        }),
                                    );
                                   
                                    isSaveLoanDetails = false;
                                    return;
                                }
                            }
                            else{
                                console.log('record.value 339-'+record.value);
                                console.log('record.value 339-'+record.Storage_Field__c);
                                if(record.value == null || record.value == '' || record.value == undefined){
                                    console.log('record.value 343-'+record.Storage_Field__c);
                                    this.showLoader = false;
                                    this.dispatchEvent(
                                        new ShowToastEvent({
                                            title: 'Error',
                                            message: 'Please fill all the mandatory fields in order to proceed',
                                            variant: 'Error',
                                        }),
                                    );
                                   
                                    isSaveLoanDetails = false;
                                    return;
                                }
                            }
                        }
                    }
                });
            }
            if (isSaveLoanDetails) {
                this.saveAndNext();
            }
        }
    }
    saveAndNext(event) {
        console.log('fieldsDataMap - ', JSON.stringify(this.fieldsDataMap));
        console.log('this.recordId=:'+this.recordId);
        if (JSON.stringify(this.fieldsDataMap) != '{}') {
            saveLoanDetails({
                fieldsDataMap: JSON.stringify(this.fieldsDataMap),
                storageObject: this.screenObject,
                loanId: this.recordId,
                fieldsObjectMap : JSON.stringify(this.fieldsObjectMap),
                screenName: this.screenName
            }).then(response => {
                console.log('this.screenObject=:'+this.screenObject);
                console.log('response - ', JSON.stringify(response));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Data saved successfully.',
                        variant: 'success',
                    }),
                );
                location.reload();
                this.fieldsDataMap = {};
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
    }
    handleInputChange(event) {
        console.log('event.target.value=:'+event.target.value);
        console.log('event.target.name=:'+event.target.name);
        const currentId = event.currentTarget.dataset.id;
        const currentValue = event.target.value;
        const currentObject = event.target.dataset.name;
    
        console.log('currentId=:'+currentId);
        console.log('currentValue=:'+currentValue);
        if(currentId=='Details_Filled__c' && event.target.checked){
            this.showDetailsFilledData=true;
        }
        if(currentId=='Images_Captured__c' && event.target.checked){
            this.showImageCapture=true;
        }
        if(this.showDetailsFilledData &&  this.showImageCapture ){
            this.showNextButton=true;
        }
        if(event.target.name=='Checkbox'){
            console.log('event.target.checked=:'+event.target.checked);
            if(event.target.checked){
                this.fieldsDataMap[currentId] = true;
                this.fieldsObjectMap[currentId] = currentObject;
                this.fieldDetails.forEach(item => {
                    console.log('item.Field_Label__c=:'+item.Storage_Field__c);
                    if(item.Storage_Field__c == event.target.dataset.label){
                        console.log('inside true');
                        item.value=true;
                    }
                })
            }
            else{
                this.fieldsDataMap[currentId] = false;
                this.fieldsObjectMap[currentId] = currentObject;
                this.fieldDetails.forEach(item => {
                    if(item.Storage_Field__c == event.target.dataset.label){
                        item.value=false
                    }
                });
            }
        }
        else if(currentId == 'Pin__c'){
            this.fieldDetails.forEach(item => {
                if(item.Storage_Field__c == event.target.dataset.label){
                    item.value=currentValue
                }
            });            
            this.fieldsDataMap['Pin__c'] = currentValue;
            this.fieldsObjectMap['Pin__c'] = currentObject;
            console.log('event.target.value=:'+event.target.value);
            if(event.target.value != undefined && event.target.value.length >=6){
                this.pincodeval = event.target.value;
                this.showPincodeCmp = true;
                const scrollOptions = {
                    left: 0,
                    top: 0,
                    behavior: 'smooth'
                }
                window.scrollTo(scrollOptions);
            }
        }
        else if(currentId == 'Number_of_months_at_this_address__c'){
            if(currentValue > 11){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Number of months cannot be more than 11',
                        variant: 'error',
                    }),
                );
                this.template.querySelector(`[data-id="${currentId}"]`).value='';
            }
            else{
                this.fieldsDataMap[currentId] = currentValue;
                this.fieldsObjectMap[currentId] = currentObject;
                this.fieldDetails.forEach(item => {
                    if(item.Storage_Field__c == event.target.dataset.label){
                        item.value=currentValue
                    }
                });
            }
        }
        else if(currentId == 'Permanent_Address_same_as_Current__c'){
            this.fieldsDataMap[currentId] = currentValue;
            this.fieldsObjectMap[currentId] = currentObject;
            this.fieldDetails.forEach(item => {
                if(item.Storage_Field__c == event.target.dataset.label){
                    item.value=currentValue
                }
            });
            if(currentValue == 'Yes'){
                this.showPermanentAdr = false;
            }
            else{
                this.showPermanentAdr = true;
            }
        }
     
        else if(currentId == 'Date_of_Birth__c'){
            var regexVar = /^([0-9]{2})\/([0-9]{2})\/([0-9]{4})$/;
            let currentDate = new Date().toJSON().slice(0, 10)
            console.log('daye---'+currentDate);
            var userBirthDate = new Date(currentValue.replace(regexVar, "$3-$2-$1")); 
            console.log('daye---'+currentDate);
            var todayYear = (new Date()).getFullYear();
            var cutOff19 = new Date(); 
            cutOff19.setFullYear(todayYear - 18);
            console.log('todayDate----',new Date());
            console.log('this.dateofBirth----',currentValue);
           
            //this.dateofBirth=event.target.value;
            if(this.currentValue>=currentDate)
            {
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
            else
            {
                this.fieldsDataMap[currentId] = currentValue;
                this.fieldsObjectMap[currentId] = currentObject;
                this.fieldDetails.forEach(item => {
                    if(item.Storage_Field__c == event.target.dataset.label){
                        item.value=currentValue
                    }
                });
            }
        }
        else {
            var textreg = /^[A-Za-z\s]*$/; 
            var numregex = '^[0-9]*$';
            console.log('currentValue=:regex' + currentValue);
            console.log('event.target.name=;' + event.target.name);
            console.log('currentValue=:regex' + currentId);
            console.log('currentValue=:regessssx' + currentId);
            if ((event.target.name == 'Text')  && (currentId != 'Interior_Conditions__c' && currentId!='Gate_Door_Color_Bldg_Color__c')) {
                console.log('currentValue=:regessssx' + currentId);
                if (!currentValue.match(textreg)) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter in correct format',
                            variant: 'error',
                        }),
                    );
        
                    if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                        this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                    } else {
                        this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    }
                    return;
                }
            }
            console.log('currentId=:'+currentId);
            this.fieldsDataMap[currentId] = currentValue;
            this.fieldsObjectMap[currentId] = currentObject;
            this.fieldDetails.forEach(item => {
                if(item.Storage_Field__c == event.target.dataset.label){
                    item.value=currentValue
                }
            });
            console.log('currentId------'+currentId)
            const currentFieldDetails = this.fieldDetails.find(item => item.Storage_Field__c == currentId);
            console.log('currentFieldDetails------'+JSON.stringify(currentFieldDetails));
            const dependentField = this.fieldDetails.find(item => item.Visibility_Controlled_By__c == currentFieldDetails.Id);
            console.log('dependentField---'+dependentField);
            if (dependentField) {
                const arrDependentControlledValue = dependentField.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                console.log('arrDependentControlledValue---'+arrDependentControlledValue);
                if (arrDependentControlledValue.find(element => element == currentValue.toLowerCase())) {
                    console.log('inside show');
                    this.template.querySelector(`[data-id="${dependentField.Storage_Field__c}"]`).classList.remove('slds-hide');
                }
                else {
                    console.log('inside hide');
                    console.log('arrDependentControlledValue---'+arrDependentControlledValue);
                    this.template.querySelector(`[data-id="${dependentField.Storage_Field__c}"]`).classList.add('slds-hide');
                }
            }
            if (currentFieldDetails.Is_Controlling_Picklist__c) {
                getFieldDependencies({
                    objectName: currentFieldDetails.Storage_Object__c,
                    controllingField: currentFieldDetails.Storage_Field__c,
                    dependentField: currentFieldDetails.Dependent_Picklist__c
                }).then(result => {
                    console.log('dependent picklist values List=:' + JSON.stringify(result));
                    const dependentPicklistOptions = result[currentValue];
                    this.template.querySelector(`[data-id="${currentFieldDetails.Dependent_Picklist__c}"]`).options = dependentPicklistOptions;
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

    handleReportUpload(event){
        const uploadedFiles = event.detail.files;
        let fiId = event.target.dataset.id;
        console.log('uploadedFiles --> '+JSON.stringify(uploadedFiles));
        this.frontId = uploadedFiles[0].documentId;
        this.contentDocIWaiver= uploadedFiles[0].documentId;
        this.showSpinner = true;
        this.showPDF=true;
        console.log('uploadedFiles[0].documentId----'+uploadedFiles[0].documentId);
        if(window.location.origin.includes('my.site.com')){
            this.pdfURL=window.location.origin+'/losportal/sfc/servlet.shepherd/document/download/'+uploadedFiles[0].documentId;
            console.log(' this.pdfURL---'+ this.pdfURL);
            this.showPDF=true
        }else{
            this.pdfURL=window.location.origin+'/sfc/servlet.shepherd/document/download/'+uploadedFiles[0].documentId;
            this.showPDF=true
        }
        console.log('this.pdfURL'+this.pdfURL);
       
        this.updateDocumentChecklist();
      

    }
    updateDocumentChecklist(){
        updateDocumentChecklist({fiId:this.recordId,reportId:this.contentDocIWaiver})
        .then(result => {
            console.log('result-721->'+JSON.stringify(result));
            this.showSpinner = false;
        })
        .catch(error => {
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                })
            );
        }); 
    }

    getPDFURL(){
        console.log('this.recordId---'+this.recordId);
        getLatestDocumentUrl({recordId:this.recordId}) 
        .then(response => {
            console.log('result-738--'+response);
            if(response!=null)
            if(window.location.origin.includes('my.site.com')){
            
                this.pdfURL=window.location.origin+'/losportal/sfc/servlet.shepherd/document/download/'+response;
                console.log(' this.pdfURL---'+ this.pdfURL);
                this.showPDF=true
            }else{
                
                    this.pdfURL=window.location.origin+'/sfc/servlet.shepherd/document/download/'+response;
                    this.showPDF=true
                
            }
        })
    }

    downloadPdf(base64fContent) {
        if (!base64fContent) {
            console.error('No base64 content available for PDF');
            return null;
        }
 
        try {
            const byteCharacters = atob(base64fContent);
            const byteNumbers = new Array(byteCharacters.length);
   
            for (let i = 0; i < byteCharacters.length; i++) {
                byteNumbers[i] = byteCharacters.charCodeAt(i);
            }
   
            const byteArray = new Uint8Array(byteNumbers);
            const blob = new Blob([byteArray], { type: 'application/pdf' });
            const url = URL.createObjectURL(blob);
            return url;
        } catch (error) {
            console.error('Error loading PDF:', error);
            return null;
        }
    }

    handleFocusOut(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
        const recordId = event.target.dataset.id;
        saveFieldData(recordId, fieldName, fieldValue);
    }


    updateRecords(event){
        console.log('event.target.value--'+event.target.value);
        console.log('event.target.dataset.id'+event.target.dataset.id);
        const fields = {};
        fields['Id'] = this.recordId;
        fields[event.target.dataset.id] = event.target.value;
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
        .then(() => {
            
            fireEvent(this.pageRef, "fiCheckSubmit", "fiCheckSubmit");
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
    }



}