import { api, LightningElement, track, wire } from 'lwc';
import getScreenDetails from '@salesforce/apex/ScreenGenerationController.getScreenDetails';
import getPicklistValues from '@salesforce/apex/ScreenGenerationController.getPicklistValues';
import getLoanDetailsFromStorageObject from '@salesforce/apex/ScreenGenerationController.getLoanDetailsFromStorageObject';
import upsertCersaiRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.upsertCersaiRecord';
import getCurrentUserRole from '@salesforce/apex/Hl_CovenantsDetailFormController.getCurrentUserRole';
import getTechnicalEvaluation from '@salesforce/apex/Hl_CovenantsDetailFormController.getTechnicalEvaluation';
import getUserRole from '@salesforce/apex/Hl_CovenantsDetailFormController.getUserRole';
import OPPORTUNITY_FIELD from '@salesforce/schema/Application_Collateral__c.HL_Loan_Application__c';
import { getRecord } from 'lightning/uiRecordApi';
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";//Sanwar(4/12/2025)

export default class Hl_cersaiDetailForm extends LightningElement {
    // @track fieldDetailsCersai = []; // Fields with actual values
    // @track screenFieldsCersai = []; // Fields from Screen_Field__c
    cersaiDetailUpdate = {};
    @api recordId;
    @api formName = 'CERSAI'; // Did the changes
    @track fieldDetails;
    @track showCersaiModal = false;
    disableDocField = false;
    loadLookUps = true;// Did the changes
    technicalEvaluationId;
    opportunityId;
    oppSubStage = '';//Sanwar(4/12/2025)
    oppIdLoaded = false;//Sanwar(4/12/2025)
    subStageLoaded = false;//Sanwar(4/12/2025)

    @wire(getRecord, { recordId: '$recordId', fields: [OPPORTUNITY_FIELD] })
    wiredRecord({ data, error }) {
        if (data) {
            this.opportunityId = data.fields.HL_Loan_Application__c.value;
            this.oppIdLoaded = true;//Sanwar(4/12/2025)
            this.runIfReady();//Sanwar(4/12/2025)
        }  else if (error) {
            console.error('Error fetching Opportunity Id:', error);
        }
    }
    //Sanwar(4/12/2025)
    @wire(getRecord, { recordId: "$opportunityId", fields: [SUBSTAGE_FIELD] })
    opportunity({ error, data }) {
        if(data) {
            this.oppSubStage = data.fields.Sub_stage__c.value;
            this.subStageLoaded = true;
            this.runIfReady();
        }
    }
    //Sanwar(4/12/2025)
    runIfReady() {
        if (this.oppIdLoaded && this.subStageLoaded) {
            this.getScreenDetailsFromApex();
        }
    }

    connectedCallback(){ // async removed - Anish SFHL-1573
        console.log('recordId in ScreenFieldsUpdateCmp----', this.recordId);
        getTechnicalEvaluation({recordId :this.recordId }) // async removed - Anish SFHL-1573
        .then(result => {
            console.log('getTechnicalEvaluation Result ',result);
            if(result){
                console.log('result ',this.result);
                this.technicalEvaluationId = result;
                console.log('Technical Evaluation Id ',this.technicalEvaluationId);
                this.getLoanDetails(); // to ensure it is called after this.technicalEvaluationId is fetched - Anish SFHL-1573
                this.showCersaiModal = true;
            }
            else{
                this.showCersaiModal = false;
            }
        })


        // this.getScreenDetailsFromApex();//Sanwar(4/12/2025)
    }
    //Sanwar - Start
    renderedCallback() {
        const style = document.createElement("style");
        style.innerText = `
            .slds-accordion__list-item .section-control {
                background: #c5c5c5;
                color: black;
                margin-left: 0px;
                margin-bottom: 0px;
                margin-right: 0px;
                font-weight: 500;
            }
            .slds-accordion__summary {
                padding: 10px 0px 10px 0px;
            }
        `;

        this.template.querySelector(".styleContainer")?.appendChild(style);
    }
    //Sanwar - End


    getScreenDetailsFromApex() {
        console.log('this.formIdentifier ' + this.formName);
        this.fieldDetails = [];
        getScreenDetails({
            formIdentifier: 'CERSAI',
            loanId: this.recordId
        })
        .then(result => {
            if (result) {
                this.fieldDetails = result;
                console.log('field ', this.fieldDetails);
                this.fieldDetails.forEach(async item => {
                    if (item.Field_Type__c === 'Picklist') {
                        item.picklistOptions  = await this.getPicklistOptionsFromApex(true, item.Storage_Object__c, item.Storage_Field__c);
                        item.isPicklist = false;
                    }
                });

                this.getLoanDetails();
                console.log('At 85');
                getCurrentUserRole({recordId : this.recordId}).then(data => {
                    this.disableDocField = data;
                    console.log('At 120');
                    this.fieldDetails = this.fieldDetails.map(row => { return { ...row, Is_Disabled__c: true }; });
                    getUserRole({recordId : this.opportunityId})//sanwar (4/12/2025)
                    .then(data => {
                        console.log('AT 93',data);
                        console.log('At 117',this.oppSubStage);
                        if(data && this.oppSubStage == 'Ops Maker'){//Sanwar(4/12/2025)
                            console.log('AT 92');
                            this.fieldDetails = this.fieldDetails.map(row => { return { ...row, Is_Disabled__c: false }; });
                        }
                    });
                });
                console.log('90');
            }
        }).catch(error => {
            console.error('error getScreenDetails: ' + JSON.stringify(error));
        });
    }

    async getPicklistOptionsFromApex(isPicklist, storageObject, storageField) {
        if (isPicklist) {
            const result = await getPicklistValues({
                storageObject: storageObject,
                storageField: storageField
            });
            let picklistOptions = result.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });
            return picklistOptions;
        }
    }

    handleInputChange(event){
        this.cersaiDetailUpdate = {};
        console.log('event ',event.target.value);
        const apiName = event.currentTarget.dataset.name;
        console.log(event.target.dataset.id);
        this.cersaiDetailUpdate[apiName] = event.target.value;
        this.cersaiDetailUpdate['Id'] = this.technicalEvaluationId;
        console.log('fieldDetails: ',this.fieldDetails);        
        console.log('api name ', apiName);
    }

    handleOnblur(event){
        console.log('Cersai detail ', this.cersaiDetailUpdate);
         if (JSON.stringify(this.cersaiDetailUpdate) !== '{}'){
            console.log('this field detail', this.cersaiDetailUpdate);
            upsertCersaiRecord({fieldDetails : this.cersaiDetailUpdate})
            .then(result => {
                this.cersaiDetailUpdate = {};
                this.getLoanDetails();
            })
            .catch(error => {
                console.error('error upsertCersaiRecord ::',error);
            });
        }
        else{
            console.log('detail not completed');
        }
    }

    getLoanDetails() {
        try {
            // if(this.selectedRecordId== null || this.selectedRecordId == '' || this.selectedRecordId == undefined){
            //     this.selectedRecordId= this.recordId;
            // }
            // console.log('780 '+this.selectedRecordId);
            console.log('782 ' + this.screenName);
            setTimeout(() => {
                console.log('at 796');
                console.log('form name ',this.formName);
                getLoanDetailsFromStorageObject({
                    screenName: this.formName,
                    loanId: this.recordId,
                    formIdentifier: this.formName,
                    technicalEvaluationId: this.technicalEvaluationId, //change 
                    recordId: this.technicalEvaluationId, // this.recordId Changed to this.technicalEvaluationId as called from AppCollateral Record page - Anish SFHL-1573
                    did: ''
                }).then(result => {
                    console.log('result[0].fieldId : '+result[0].fieldId);
                    console.log('detailsWrapperList from getLoanDetailsFromStorageObject--> ' + JSON.stringify(result));
                    console.log('fieldDetails-> ' + JSON.stringify(this.fieldDetails));
                    if (this.fieldDetails) {
                        this.technicalEvaluationId = result[0].fieldId;
                        result.forEach(item => {
                            this.fieldDetails.forEach(record => {
                                console.log('item.fieldApiName at 810---', item.fieldApiName);
                                console.log('item.fieldValue at 180----', item.fieldValue);
                                console.log('record. id==', record.Id);
                                console.log('record.Storage_Field__c----', item.Storage_Field__c);
                                console.log('item id' ,item.fieldId);
                                record.Id = item.fieldId;

                                if (item.fieldApiName == record.Storage_Field__c && record.is_Lookup__c) {
                                    record.savedName = item.fieldValue; //item.lookUpfieldValue;
                                    record.value = item.lookUpfieldValue;
                                    console.log('record -->' + JSON.stringify(record));
                                } else if (item.fieldApiName == record.Storage_Field__c) {
                                    record.value = item.fieldValue;
                                }
                                if (record.Field_Type__c === 'Picklist') {
                                    record.isPicklist = true;
                                }
                            });
                        });

                        console.log('this.fieldDetails at 108---', JSON.stringify(this.fieldDetails));
                        
                        // setTimeout(() => {
                        //     this.fieldDetails.forEach(record => {
                        //         console.log('record.Visibility_Controlled_By__c=:' + record.Visibility_Controlled_By__c);
                        //         console.log('record.Storage_Field__c=:' + record.Storage_Field__c);
                        //         record.hideField = false;
                        //         if (record.Visibility_Controlled_By__c != null && record.Visibility_Controlled_By__c != '' && record.Visibility_Controlled_By__c != undefined) {
                        //             const dependentField = this.fieldDetails.find(item => item.Id == record.Visibility_Controlled_By__c);
                        //             console.log('dependentField=:' + JSON.stringify(dependentField));
                        //             const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                        //             console.log('arrDependentControlledValue=:' + arrDependentControlledValue);
                        //             if (dependentField.value != null && dependentField.value != '' && dependentField.value && dependentField.value != undefined) {
                        //                 if (arrDependentControlledValue.find(element => element == dependentField.value.toLowerCase())) {
                                            
                        //                     setTimeout(() => {
                        //                         if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                        //                             this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                        //                         }                                                
                        //                     }, 1000)

                        //                 } else {
                        //                     try {
                        //                     record.hideField = true;
                        //                     setTimeout(() => {
                        //                             console.log('record.Id----', record.Id);
                                                    
                        //                             if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                        //                                 console.log('In if condition');
                                                        
                        //                                 this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                        //                             }
                                                    
                        //                     }, 1000)
                        //                     } catch (error) {
                        //                         console.log('errorrr---', error);
                                                
                        //                     }
                                            
                        //                 }
                        //             }
                        //             else {
                        //                 record.hideField = true;
                        //                 setTimeout(() => {
                        //                     if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                        //                     this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                        //                     }
                                            
                        //                 }, 1000)
                        //             }

                        //         }
                        //         if (record.Is_Controlling_Picklist__c) {
                        //             getFieldDependencies({
                        //                 objectName: record.Storage_Object__c,
                        //                 controllingField: record.Storage_Field__c,
                        //                 dependentField: record.Dependent_Picklist__c
                        //             }).then(result => {
                        //                 console.log('Dependent picklist values: in connected callbackkk---record.Dependent_Picklist__c', record.value, '--', JSON.stringify(result), '= ', record.Dependent_Picklist__c);
                        //                 const dependentPicklistOptions = result[record.value];
                        //                 console.log('dependentPicklistOptions----', dependentPicklistOptions);

                        //                 // const targetField = this.fieldDetails.find(item => item.Storage_Field__c === record.Dependent_Picklist__c);

                        //                 const targetField = this.fieldDetails.find(item => {
                        //                     const isStorageFieldMatch = item.Storage_Field__c === record.Dependent_Picklist__c;
                        //                     return isStorageFieldMatch;
                                            
                        //                 });


                        //                 if (targetField) {
                        //                     console.log('Inside target field---', targetField.Id);
                        //                     if(this.template.querySelector(`[data-id="${targetField.Id}"]`)){
                        //                         this.template.querySelector(`[data-id="${targetField.Id}"]`).options = dependentPicklistOptions;
                        //                     }
                                            
                        //                 }
                        //             }).catch(error => {
                        //                 if (error != undefined && error.body != undefined && error.body.message != undefined) {
                        //                     this.dispatchEvent(
                        //                         new ShowToastEvent({
                        //                             title: 'Error',
                        //                             message: error.body.message,
                        //                             variant: 'error',
                        //                         }),
                        //                     );
                        //                 }
                        //             });
                        //         }
                        //     });

                        // }, 1500);
                    }
                }).catch(error => {
                    console.error('getLoanDetailsFromStorageObject ERROR:  ',error);
                })
            }, 1000);
        } catch (error) {
            console.log('error=:860generic' + error);
            console.log('error=:860generic' + JSON.stringify(error));
        }

    }

    
}