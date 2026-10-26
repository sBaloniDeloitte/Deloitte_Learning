import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import COVENANT_TYPE from "@salesforce/schema/Covenant_Master__c.covenanttype__c";

import deleteDocIds from '@salesforce/apex/SanctionConditionController.deleteDocIds';
import deleteSanctionIds from '@salesforce/apex/SanctionConditionController.deleteSanctionIds';
import checkExistingSanctions from '@salesforce/apex/SanctionConditionController.checkExistingSanctions';
import createSanctions from '@salesforce/apex/SanctionConditionController.createSanctions';
import getAllSanctionConditions from '@salesforce/apex/SanctionConditionController.getAllSanctionConditions';
import getAllSanctionCheckList from '@salesforce/apex/SanctionConditionController.getAllSanctionCheckList';
import checkdocUploaded from '@salesforce/apex/SanctionConditionController.checkdocUploaded';
import { NavigationMixin } from 'lightning/navigation';
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import createSanctionwithDocs from '@salesforce/apex/SanctionConditionController.createSanctionwithDocs';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import COVENANT_MASTER from "@salesforce/schema/Covenant_Master__c";
import USER_ID from '@salesforce/user/Id';
import covenantApproverValues from '@salesforce/label/c.Covenant_Approver_Values';
import uploadApprovalDisableFor from '@salesforce/label/c.Covenant_Disable_Approval_Upload';
// import getProfileWiseCovenantType from '@salesforce/apex/Utility.getProfileWiseCovenantType';

export default class SanctionConditionConvenantsCmp extends NavigationMixin(LightningElement) {
    @api recordId;

    @track isRendered = false;

    @track allSanctions = [];

    @track allChecklist = [];

    @track showMessage = false;
    @track selectedId = '';
    @track selectedChecklistData = [];
    @track modalVisibility = false;

    @track newsanction = 'Other-';
    @track newDocTable = [];
    @track createdNewDocTable = [];
    @track selectedDocType = '';
    @api disableStatusEdit = false;

    currentUserOppRole = [];
    oppStage = '';
    oppSubStage = '';
    disableAddConditionBtn = false;

    sanctiondocTodelete = '';
    eventName = '';
    showConfirmation = false;
    confirmMessage = 'Are you sure you want to delete these document(s)?';

    sanctionIdtoDelete = '';
    showConfirmationSanctionDelete = false;
    confirmMessageSanction = 'Are you sure you want to delete this sanction condition?';
    optionsList = [];
    @track selectedDocType = '';
    @track isCritical = 'Critical';
    newsanctionId;
    showAddCustom = false;
    newsanctionName;
    userProfile;
    fromSales = false;
    notcredit = false;
    newdocName;
    @track isHomeLoan = false;
    @track showSanctionButton = true;
    @track productFilter= '';
    @track selectedProduct;
    userId = USER_ID;
    docTypeOptions = [
        { label: 'Document', value: 'Document' },
        { label: 'Non-Document', value: 'Non-Document' }
    ];
    label = {
        covenantApproverValues,
        uploadApprovalDisableFor
    };

    get readOnlyStatus() {
        return this.fromSales || this.disableStatusEdit;
    }

    quickDisb;
    qdpStatus = '';
    allowreUpload=false;
    @track disable= false;
    selectedIds = new Set();
    showApprovalButton;
    showApprovalProcess=false;
    isAllSelected=false;

    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, SUBSTAGE_FIELD] })
    opportunity({ error, data }) {
        if(data) {
            this.oppStage = data.fields.StageName.value;
            this.oppSubStage = data.fields.Sub_stage__c.value;

            console.log('this.oppSubStage=---', this.oppSubStage);

            if(this.oppSubStage== 'Ops Author'){
                this.disable = true;
            }
        }
    }

    @wire(getObjectInfo, { objectApiName: COVENANT_MASTER })
    covenantMasterObjectInfo;

    @wire(getPicklistValues, { recordTypeId:'$covenantMasterObjectInfo.data.defaultRecordTypeId', fieldApiName: COVENANT_TYPE })
    getCovenantValues({ data, error }) {
        if(data) {
            console.log('data.values'+ JSON.stringify(data.values));
            this.optionsList = data.values.filter(option => option.value !== 'LOS' && option.value !== 'OTC' && option.value !== 'PDD');
            console.log('optionslisttt----', this.optionsList);

        }
        if(error){
            console.log('error-->',error);
        }
    }


    connectedCallback(){
        getCurrentUserProfileName()
        .then((result) => {
            this.userProfile = result;
            console.log('this.userProfile  '+this.userProfile)
            if(this.userProfile == 'Credit Manager' || this.userProfile == 'Sales' || this.userProfile == 'Credit Officer'){
                this.notcredit = true;
            }
            else{
                this.notcredit = false;
            }
            if(this.userProfile == 'Sales'){
                // this.fromSales = true;
                this.showSanctionButton = false;
            }
            else{
                this.fromSales = false;
            }
        })
        .catch((error) => {
            console.error('Error getCurrentUserProfileName --> '+ error);
        });

        this.fetchSanctions();
        this.checkProductType();
        this.isCritical= 'Critical';
        console.log('User Id:', this.userId);
        this.productFilter = '[Loan_Application__c = ' + this.recordId  + ';RecordType.Name = Product' + ']';

        console.log('this.oppSubStage=---', this.oppSubStage);

        if(this.oppSubStage== 'Ops Author'){
            this.disable = true;
        }
    }

    fetchApplicableValues() {
        getProfileWiseCovenantType({
            inputMap: { objectApiName: 'Sanction_Conditions__c' }
        })
        .then(result => {
            this.applicableValues = result;   // store list of allowed values
            console.log('Applicable values:', this.applicableValues);
        })
        .catch(error => {
            console.error(error);
        });
    }

    checkProductType() {
        const inputMap = {
            oppId: this.recordId,   // or pass related Loan_Application__c if needed
            legalId: null,
            technicalId: null
        };

        getProductDetails({ inputMap })
        .then(result => {
            console.log('Product Details:', result);
                this.isHomeLoan = result?.isHLRelated || false;
                if(this.isHomeLoan){
                    this.showApprovalButton= true;
                }
        })
        .catch(error => {
            console.error('Error fetching product details:', error);
        });
    }

    setPageEditability(){

        console.log('currentUserOppRole: '+this.currentUserOppRole);
        console.log('oppStage: '+this.oppStage);
        console.log('oppSubStage: '+this.oppSubStage);
        console.log('this.userProfile: '+this.userProfile);

        if(this.oppSubStage== 'Ops Author'){
            console.log('inside disableeeee----');

            this.disable = true;
        }

        var disableControls = false;
        if( (this.userProfile == 'Sales' && this.oppStage == 'Credit Underwriting') ||(this.userProfile == 'Sales' && this.oppSubStage == 'PSV Sales') ){
            disableControls = true;
        }

        if(this.isHomeLoan){
            this.allSanctions = this.allSanctions.map(row => {
                var chkListLine;
                console.log('row.Verification----', row.Verification);
                if(row.Verification == 'Received - Checker' || this.oppSubStage == 'Ops Author'){
                    console.log('at 211');

                    if(row.sanctionChecklist){
                        console.log('Checklist item:');
                        chkListLine = row.sanctionChecklist.map(item => {
                            console.log('Checklist item:', item.ddw);
                            let updatedDdw = item.ddw
                                ? {
                                    ...item.ddw,
                                    showUpload: false,
                                    showDelete: false
                                }
                                : {
                                    showUpload: false,
                                    showDelete: false
                                };

                            return {
                                ...item,
                                ddw: updatedDdw,
                                showDelete: true
                            };
                        });
                    }
                    return {
                        ...row,
                        disableStatus: false,
                        showAddDocSection: true,
                        isDefault: true,
                        sanctionChecklist: chkListLine
                    };
                }else{
                    return {
                        ...row,
                        disableStatus: false,
                        showAddDocSection: false,
                        isDefault: false
                    };
                }

            });
        }

        if(disableControls){
            console.log('disable controls--');

            this.disableAddConditionBtn = true;

            this.allSanctions = this.allSanctions.map(row => {

                var chkListLine;

                if(row.sanctionChecklist){
                    console.log('Checklist item:');
                    chkListLine = row.sanctionChecklist.map(item => {
                        console.log('Checklist item:', item.ddw);
                        let updatedDdw = item.ddw
                            ? {
                                ...item.ddw,
                                showUpload: true,
                                showDelete: false
                            }
                            : {
                                showUpload: true,
                                showDelete: false
                            };

                        return {
                            ...item,
                            ddw: updatedDdw,
                            showDelete: false
                        };
                    });
                }

                if (!this.isHomeLoan && this.userProfile == 'Sales' && this.oppSubStage == 'PSV Sales') {
                    return {
                        ...row,
                        disableStatus: true,
                        showAddDocSection: false,
                        isDefault: true,
                        sanctionChecklist: chkListLine
                    };
                }else if (this.isHomeLoan && this.userProfile == 'Sales' && this.oppSubStage == 'PSV Sales') {
                    return {
                        ...row,
                        disableStatus: true,
                        showAddDocSection: true,
                        isDefault: true,
                        sanctionChecklist: chkListLine
                    };
                } else {
                    return {
                    ...row,
                    disableStatus: true,
                    showAddDocSection: true,
                    isDefault: true,
                    sanctionChecklist: chkListLine
                };
                }


            });
        }
    }

    fetchSanctions(){
        getAllSanctionConditions({recordId: this.recordId})
            .then((result) => {
                console.log('this.getAllSanctionConditions-->'+JSON.stringify(result));
                this.allSanctions = result;

                setTimeout(() => {
                    this.setPageEditability();
                }, 800);
            })
            .catch((error) => {
                console.error('Error getAllSanctionConditions --> ', JSON.stringify(error));
            });
    }



    handleldeselectSantion(event){
        this.selectedId = '';
        this.allChecklist = [];
        this.newsanction = 'Other-';
        this.selectedChecklistData = [];
        this.showMessage = false;
        this.showAddCustom = false;
        this.selectedDocType = '';
    }
    handleChecklistselection(event){
        console.log(event.target.checked);
        const selecteddocid = event.target.dataset.id;
        if(event.target.checked){
            this.selectedChecklistData.push(selecteddocid);
        }else{
            let temp = [];
            this.selectedChecklistData.forEach(record => {
                if(record != selecteddocid){
                    temp.push(record);
                }
            });
            this.selectedChecklistData = temp;
        }

        console.log('selectedChecklistData -->'+JSON.stringify(this.selectedChecklistData));
    }
    handleselectSanction(event){
        this.selectedId = event.detail.searchRecord.Id;
        console.log('this.selectedId --->'+this.selectedId);
        console.log('this.101 -->'+ event.detail.searchRecord.Id);
        let recordName = event.detail.searchRecord.Name;
        console.log('this.recordName--> '+event.detail.searchRecord.Name);
        if(recordName == 'Other'){
            this.showMessage = false;
            this.showAddCustom = true;
        }else{
            this.showAddCustom = false;
            this.showMessage = false;
            if(this.selectedId != 'Create New Sanction'){
                checkExistingSanctions({sanctionMaster: this.selectedId, recordId: this.recordId})
                    .then((result) => {
                        console.log('result'+result);
                        if(result){
                            this.showToastMessage('Error', 'Their is an existing sanction created with this condition. Please select another condition.', 'error');
                            this.selectedId = '';
                        }else{
                            getAllSanctionCheckList({recordId: this.selectedId})
                            .then((result) => {
                                console.log('this.getAllSanctionCheckList-->'+JSON.stringify(result));
                                this.allChecklist = result;
                                if(this.allChecklist.length==0 && this.selectedId != null && this.selectedId != '' && this.selectedId != undefined){
                                    this.showMessage = true;
                                }
                            })
                            .catch((error) => {
                                console.error('Error getAllSanctionCheckList --> ', JSON.stringify(error));
                            });
                        }
                    })
                    .catch((error) => {
                        console.error('Error getAllSanctionCheckList --> ', JSON.stringify(error));
                    });
            }else{
                this.newsanction = 'Other-';
            }
        }

    }
    handleDocTypeChange(event){
        this.selectedDocType = event.detail.value;
    }

     handleTypeChange(event){
        this.isCritical = event.detail.value;
    }

    savedDocs = {srNo: '',
        id: '',
        sanctionValue: '',
        documentType: '',
        documentNames: []
    };
    /*Sujit*/
    handleView(event){
            const fileId = event.target.dataset.id;
          /*  this[NavigationMixin.Navigate]({
                type:'standard__namedPage',
                          attributes:{
                    pageName:'filePreview'
                },
                 state:{
                    selectedRecordId: fileId
                }});*/

        }

    handleNewSanctionName(event){
        this.newsanctionName = event.target.value;
    }


    handleCreateNewSanctionName(event) {
        console.log('this.newsanctionName: '+this.newsanctionName);
        if (!this.selectedDocType) {
            this.showToastMessage('Error', 'Please select Document Type.', 'error');
            return;
        }
        if (!this.isCritical) {
            this.showToastMessage('Error', 'Please select Type.', 'error');
            return;
        }
        createSanctions({recordId : this.recordId, checklist : this.selectedChecklistData, sanctionMaster : this.selectedId, newSanctionName : this.newsanctionName, documentType: this.selectedDocType ,sanType:this.isCritical})
        .then(result => {
            console.log('create Samction Letter :'+JSON.stringify(result));
            this.showToastMessage('Success', 'New sanction condition added successfully.', 'success');
            this.showAddCustom = false;
            this.fetchSanctions();
            const srNo = this.createdNewDocTable.length + 1;
            this.savedDocs.srNo = srNo;
            this.savedDocs.id = result.id;
            this.savedDocs.sanctionValue = result.name;
            this.savedDocs.documentType = result.documentType;
            if(result.showChecklist){
                this.savedDocs.showChecklist = true;
                this.savedDocs.documentNames = result.sanctionChecklist;
            }else{
                this.savedDocs.showChecklist = false;
            }

            this.createdNewDocTable = [...this.createdNewDocTable, { ...this.savedDocs }];

            console.log('this.createdNewDocTable -->'+JSON.stringify(this.createdNewDocTable));

            this.allChecklist = [];
            this.selectedId = '';
            this.selectedChecklistData = [];
            this.showMessage = false;
            this.savedDocs.srNo = '';
            this.savedDocs.sanctionValue = [];
            this.savedDocs.documentNames = '';
            this.savedDocs.showChecklist = false;
            this.savedDocs.documentType = '';
            this.newsanction = 'Other-';
            this.newDocTable = [];

            this.refreshLookup = false;
        })
        .catch((error) => {
            console.error('Error createSanctions --> ', JSON.stringify(error));
        });
    }



    handleAddNewDoc(event){
        const sanctionId = event.target.dataset.id;
        if(event.target.dataset.name == 'Main Table'){
            this.allSanctions.forEach(record => {
                if(record.id == sanctionId){
                    record.addnewDoc = true;
                }
            });
        }else{
            this.createdNewDocTable.forEach(record => {
                if(record.id == sanctionId){
                    record.addnewDoc = true;
                }
            });
        }
    }
    handleCancelAddNewDoc(event){
        const sanctionId = event.target.dataset.id;
        console.log('sanctionId '+sanctionId);
        this.allSanctions.forEach(record => {
            if(record.id == sanctionId){
                record.addnewDoc = false;
            }
        });
    }
    handleAddNewDocEdit(event){
        const sanctionId = event.target.dataset.id;
        if(event.target.dataset.name == 'Main Table'){
            this.allSanctions.forEach(record => {
                if(record.id == sanctionId){
                    record.newDocname = event.target.value;
                }
            });
        }else{
            this.createdNewDocTable.forEach(record => {
                if(record.id == sanctionId){
                   this.newdocName =  record.newDocname = event.target.value;
                }
            });
        }
    }
    handleSaveAddNewDoc(event){
        const sanctionId = event.target.dataset.id;
        console.log('sanctionId : '+sanctionId);
        console.log('sanctionId : '+sanctionId);
        console.log('this.newdocName : '+this.newdocName);
        if(event.target.dataset.name == 'Main Table'){
            this.allSanctions.forEach(record => {
                if(record.id == sanctionId){
                    console.log('record.newDocname 500: '+record.newDocname);
                    if(record.newDocname != null && record.newDocname != '' && record.newDocname != undefined){
                        createSanctionwithDocs({docName:record.newDocname,recordId:this.recordId,sanctionId:sanctionId})
                            .then((response) => {
                                console.log(JSON.stringify(response.id));
                                this.showToastMessage('Success', 'Document added successfully to this sanction condition.', 'success');
                                this.fetchSanctions();
                                // this.handleClose();
                                this.template.querySelector('c-search-lookup').handleReset(event);
                                this.refreshLookup = true;
                                const srNo = this.createdNewDocTable.length + 1;
                                this.savedDocs.srNo = srNo;
                                this.savedDocs.id = response.id;
                                this.savedDocs.sanctionValue = record.newDocname;
                                this.savedDocs.documentType = response.documentType;
                                if(result.showChecklist){
                                    this.savedDocs.showChecklist = true;
                                    this.savedDocs.documentNames = record.newDocname;
                                }else{
                                    this.savedDocs.showChecklist = false;
                                }
                                this.createdNewDocTable = [...this.createdNewDocTable, { ...this.savedDocs }];
                                console.log('this.createdNewDocTable -->'+JSON.stringify(this.createdNewDocTable));

                            })
                            .catch((error) => {
                                // this.connectedCallback();
                                console.log('Error createRecord -->'+ JSON.stringify(error));
                            });
                    }else{
                        this.showToastMessage('Error', 'Please add a name for the document to be added into this sanction condition.', 'error');
                    }
                }
            });
        }else{
            if(this.newdocName != null && this.newdocName != '' && this.newdocName != undefined){
                console.log('record.newDocname 537 : '+this.newdocName);
                createSanctionwithDocs({docName:this.newdocName,recordId:this.recordId,sanctionId:sanctionId})
                    .then((response) => {
                        console.log(JSON.stringify(response.id));
                        this.showToastMessage('Success', 'Document added successfully to this sanction condition.', 'success');
                this.fetchSanctions();
                this.template.querySelector('c-search-lookup').handleReset(event);
                this.refreshLookup = true;
                console.log('this.createdNewDocTable.length : '+this.createdNewDocTable.length);
                const srNo = this.createdNewDocTable.length + 1;
                this.createdNewDocTable = [];
                this.newdocName = '';
                this.savedDocs.srNo = srNo;
                this.savedDocs.id = response.id;
                this.savedDocs.sanctionValue = response.name;
                this.savedDocs.documentType = response.documentType;
                if(response.showChecklist){
                    this.savedDocs.showChecklist = true;
                    this.savedDocs.documentNames = response.sanctionChecklist;
                }else{
                    this.savedDocs.showChecklist = false;
                }
                this.createdNewDocTable = [...this.createdNewDocTable, { ...this.savedDocs }];
                console.log('this.createdNewDocTable -->'+JSON.stringify(this.createdNewDocTable));
                    })
                    .catch((error) => {
                        console.log('Error createRecord -->'+ JSON.stringify(error));
                    });
            }else{
                this.showToastMessage('Error', 'Please add a name for the document to be added into this sanction condition.', 'error');
            }
        }
    }

    handleshowgenericConfirm(event){
        this.sanctiondocTodelete = event.target.dataset.id;
        this.eventName = event.target.dataset.name;
        this.newsanctionId = event.target.dataset.sanctionid;
        this.showConfirmation = true;
    }
    handleshowgenericConfirmSanction(event){
        console.log('disable-----', this.disable);

        if(this.disable){

        }else if(this.userProfile == 'Sales' && this.oppSubStage == 'PSV Sales'){

        }else{
            const deleteCond= event.target.dataset.sanctionid;
            if(deleteCond == 'true'){
                this.sanctionIdtoDelete = event.target.dataset.id;
                this.eventName = event.target.dataset.name;
                this.modalVisibility = false;
                this.showConfirmationSanctionDelete = true;
            }else{
                this.showToastMessage('Error', 'You can not delete the sanction condition.', 'error');
            }
        }

    }
    handleNo(){
        this.sanctiondocTodelete = '';
        this.eventName = '';
        this.showConfirmation = false;
        this.sanctionIdtoDelete = '';
        this.showConfirmationSanctionDelete = false;
    }

    handleDeleteNewSanction(){
        if(this.eventName == 'Main Table'){
            deleteSanctionIds({recordId: this.sanctionIdtoDelete})
                .then((result) => {
                    let tempSanctions = [];
                    this.allSanctions.forEach(data => {
                        if(data.id != this.sanctionIdtoDelete){
                            tempSanctions.push(data);
                        }
                    });
                    this.allSanctions = tempSanctions;

                    this.sanctionIdtoDelete = '';
                    this.eventName = '';
                    this.showConfirmationSanctionDelete = false;

                    this.showToastMessage('Success', 'Sanction condition deleted succesfully.', 'success');
                })
                .catch((error) => {
                    console.error('Error deleteSanctionIds --> ', JSON.stringify(error));
                });
        }else{
            deleteSanctionIds({recordId: this.sanctionIdtoDelete})
                .then((result) => {
                    let tempSanctions = [];
                    this.createdNewDocTable.forEach(data => {
                        if(data.id != this.sanctionIdtoDelete){
                            tempSanctions.push(data);
                        }
                    });
                    this.createdNewDocTable = tempSanctions;

                    this.sanctionIdtoDelete = '';
                    this.eventName = '';
                    this.showConfirmationSanctionDelete = false;

                    this.showToastMessage('Success', 'Sanction condition deleted succesfully.', 'success');

                    this.fetchSanctions();
                })
                .catch((error) => {
                    console.error('Error deleteSanctionIds --> ', JSON.stringify(error));
                });
        }
    }

    handleDeleteNewDoc(){
        console.log('this.sanctiondocTodelete -->'+this.sanctiondocTodelete);
        console.log('this.eventName -->'+this.eventName);
        console.log('this.newsanctionId -->'+this.newsanctionId);
        const sanctionId = this.sanctiondocTodelete;
        let toDeleteDocId = [];
        let toNotDeleteDocId = [];
        if(this.eventName == 'Main Table'){
            this.allSanctions.forEach(record => {
                console.log('Processing record:', record.id);
                if(record.id === this.newsanctionId){
                    record.sanctionChecklist.forEach(data => {
                        if(data.id == sanctionId){
                        console.log('Processing checklist item:', data);
                        if(data.selected){
                            toDeleteDocId.push(data.id)
                        }else{
                            toNotDeleteDocId.push(data);
                        }
                    }
                    });
                    console.log('toDeleteDocId:', toDeleteDocId);
                console.log('toNotDeleteDocId:', toNotDeleteDocId);

                    if(toDeleteDocId.length>0){
                        console.log('1st deleted -->',this.toDeleteDocId);
                        deleteDocIds({checklist: toDeleteDocId})
                            .then((result) => {
                                console.log('deleted -->',this.toDeleteDocId);
                                record.sanctionChecklist = toNotDeleteDocId;
                                if(toNotDeleteDocId.length>0){
                                    record.showChecklist = true;
                                }else{
                                    record.showChecklist = false;
                                }
                                this.fetchSanctions();
                                this.showToastMessage('Success', 'Document deleted succesfully.', 'success');

                            })
                            .catch((error) => {
                                console.error('Error deleteDocIds --> ', JSON.stringify(error));
                            });
                    }else{
                        this.showToastMessage('Error', 'Please select a document first to delete.', 'error');
                    }
                }
            });
        }else{
            this.createdNewDocTable.forEach(record => {
                if(record.id == sanctionId){
                    record.documentNames.forEach(data => {
                        if(data.selected){
                            toDeleteDocId.push(data.id)
                        }else{
                            toNotDeleteDocId.push(data);
                        }
                    });

                    if(toDeleteDocId.length>0){
                        deleteDocIds({checklist: toDeleteDocId})
                            .then((result) => {
                                record.documentNames = toNotDeleteDocId;
                                if(toNotDeleteDocId.length>0){
                                    record.showChecklist = true;
                                }else{
                                    record.showChecklist = false;
                                }
                                this.showToastMessage('Success', 'Document deleted succesfully.', 'success');

                                this.fetchSanctions();
                            })
                            .catch((error) => {
                                console.error('Error deleteDocIds --> ', JSON.stringify(error));
                            });
                    }else{
                        this.showToastMessage('Error', 'Please select a document first to delete.', 'error');
                    }
                }
            });
        }

        this.sanctiondocTodelete = '';
        this.eventName = '';
        this.showConfirmation = false;
    }

    get createdRecordsVisibility(){
        return this.createdNewDocTable.length>0;
    }

    get tableVisibility(){
        return this.allChecklist.length > 0;
    }
    get newRecordVisibility(){
        return this.selectedId == 'Create New Sanction' && this.newsanction != '' && this.newsanction != null && this.newsanction != undefined;
    }

    handleNewSanctionCondition(event){
        this.newsanction = event.target.value;
    }
    get newDocumentTable(){
        return this.newsanction != '' && this.newsanction != null && this.newsanction != undefined && this.newsanction != 'Other-';
    }

    newEntry = {srNo: '',
        nameValue: '',
    };


    showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(toastEvent);
    }
    handleChange(event){
        const val = event.target.value;
        const santionId =  event.target.dataset.id;
        console.log('val '+val);
        console.log('santionId '+santionId);
        if(val == 'Cleared'){
            checkdocUploaded({sanctionId : santionId})
            .then((result) => {
                if(result){
                    this.updateRecordField(santionId, 'Condition_Approval__c', val);
                    this.showToastMessage('Success', 'This sanction marked as verified.', 'success');
                    this.fetchSanctions();
                }
                else{
                    this.showToastMessage('Error', 'Please make sure that all the documents are uploaded before marking the sanction record as verified!', 'error');
                    this.template.querySelector()
                    const combobox = this.template.querySelector(`lightning-combobox[data-id="${santionId}"]`);
                    if (combobox) {
                        combobox.value = 'Pending';
                    }
                    this.fetchSanctions();
                }
            })
        }
        else{
            if(this.isHomeLoan && this.profileName=='Ops' && this.splittedApplicableApproverValues.includes(event.target.value ) && ( event.target.dataset.lookupid==null|| event.target.dataset.lookupid==''|| event.target.dataset.lookupid==undefined)){
                console.log(' event.target.dataset.lookupid---'+event.target.dataset.lookupid );
                 this.showToastMessage(
                'Error',
                `Please upload approval email before marking it as complete.`,
                'error'
                );
                return;
            }else{
                this.updateRecordField(santionId, 'Condition_Approval__c', val);
                this.splittedApplicableApproverValues = this.label.covenantApproverValues.split(',');
                if(this.isHomeLoan && this.splittedApplicableApproverValues.includes(val)){
                    this.updateRecordField(santionId, 'HL_Covenant_Approved_By__c', this.userId);
                }
                if(this.isHomeLoan &&  val=='Received - Checker'){
                    this.allowreUpload =true;
                }
                else{
                    this.allowreUpload =false;
                }
                this.fetchSanctions();
            }

        }
    }
    updateRecordField(recordId, fieldApiName, fieldValue) {
        const fields = {};
        fields['Id'] = recordId;
        fields[fieldApiName] = fieldValue;

        const recordInput = { fields };
        updateRecord(recordInput)
        .then(() => {
            console.log('Record updated successfully');
        })
        .catch(error => {
            console.error('Error updating record: ', error);
            console.log('Error updating record --> '+JSON.stringify(error));
        })
    }

    renderedCallback() {
        if (!this.isRendered) {
            const style = document.createElement("style");
            style.innerText = `
                    .slds-form-element .slds-dropdown_left {
                        min-width: 70%;
                    }
                    .sanction-dark-theme lightning-select .slds-select,
                    .sanction-dark-theme lightning-combobox .slds-combobox__input {
                        background-color: #16283f !important;
                        border-color: #33455e !important;
                        color: #ffffff !important;
                        height: 2.25rem !important;
                    }
                    .sanction-dark-theme lightning-textarea .slds-textarea {
                        background-color: #16283f !important;
                        border-color: #33455e !important;
                        color: #ffffff !important;
                    }
                    .sanction-dark-theme lightning-input .slds-input[disabled] {
                        background-color: #0e1c30 !important;
                        color: #8a99b3 !important;
                    }
                    .sanction-dark-theme lightning-select .slds-form-element__label,
                    .sanction-dark-theme lightning-textarea .slds-form-element__label,
                    .sanction-dark-theme lightning-input .slds-form-element__label {
                        color: #cfd8e6 !important;
                    }
                    /* Checkbox dark theme - unstyled faux checkbox otherwise
                       renders as a plain white square against the dark bg. */
                    .sanction-dark-theme lightning-input[type="checkbox"] .slds-checkbox_faux {
                        background-color: #16283f !important;
                        border: 1px solid #33455e !important;
                    }
                    .sanction-dark-theme lightning-input[type="checkbox"] input:checked ~ .slds-checkbox_faux {
                        background-color: #1467eb !important;
                        border-color: #1467eb !important;
                    }
                    .sanction-dark-theme lightning-input[type="checkbox"] input:checked ~ .slds-checkbox_faux::after {
                        border-color: #ffffff !important;
                    }
                `;

            this.template.querySelector(".styleContainer")?.appendChild(style);

            this.isRendered = true;
        }
    }

    refreshMethod(event){
        this.connectedCallback();
    }

    handleSelectedProduct(event){
        const santionId =  event.target.dataset.id;
        console.log('evnt----', JSON.stringify(event.detail));
        console.log('santionId-----', santionId);
        console.log(' event.detail.searchRecord.Id----',  event.detail.searchRecord.Id);

        this.selectedProduct = event.detail.searchRecord.Id;
        this.updateRecordField(santionId, 'HL_Related_Product__c', this.selectedProduct);
        this.fetchSanctions();
    }

    handleSaveRowValue(event){
        const santionId =  event.target.dataset.id;
        const remarks= event.target.value;
        this.updateRecordField(santionId, 'HL_Sales_Remarks__c', remarks);
        this.fetchSanctions();
    }

    handleDeselectProduct(event){
        const santionId =  event.target.dataset.id;
        this.selectedProduct = null;
        this.updateRecordField(santionId, 'HL_Related_Product__c', null);
        this.fetchSanctions();
    }

    handleAddSanction(){
        this.modalVisibility = true;
    }

    handleClose(){
        this.allChecklist = [];
        this.selectedId = '';
        this.selectedChecklistData = [];
        this.showMessage = false;
        this.modalVisibility = false;
        this.savedDocs.srNo = '';
        this.savedDocs.sanctionValue = '';
        this.savedDocs.documentNames = '';
        this.newsanction = 'Other-';
        this.newDocTable = [];
        this.selectedDocType = '';
        this.createdNewDocTable = [];
        this.sanctiondocTodelete = '';
        this.eventName = '';
        this.sanctionIdtoDelete = '';
    }

    handleSave(event){
        if(this.selectedId != null && this.selectedId != '' && this.selectedId != undefined){
            if (!this.selectedDocType) {
                this.showToastMessage('Error', 'Please select Document Type.', 'error');
                return;
            }
             if (!this.isCritical) {
                this.showToastMessage('Error', 'Please select Type.', 'error');
                return;
            }
            if(this.selectedId != 'Create New Sanction'){
                if(this.tableVisibility && this.selectedChecklistData.length >0){
                    createSanctions({recordId : this.recordId, checklist : this.selectedChecklistData, sanctionMaster : this.selectedId, documentType: this.selectedDocType})
                    .then((result) => {
                        this.showToastMessage('Success', 'New sanction condition added successfully.', 'success');
                        this.fetchSanctions();
                        // this.handleClose();
                        this.template.querySelector('c-search-lookup').handleReset(event);
                        this.refreshLookup = true;
                        const srNo = this.createdNewDocTable.length + 1;
                        this.savedDocs.srNo = srNo;
                        this.savedDocs.id = result.id;
                        this.savedDocs.sanctionValue = result.name;
                        this.savedDocs.documentType = result.documentType;
                        if(result.showChecklist){
                            this.savedDocs.showChecklist = true;
                            this.savedDocs.documentNames = result.sanctionChecklist;
                        }else{
                            this.savedDocs.showChecklist = false;
                        }

                        this.createdNewDocTable = [...this.createdNewDocTable, { ...this.savedDocs }];

                        console.log('this.createdNewDocTable -->'+JSON.stringify(this.createdNewDocTable));

                        this.allChecklist = [];
                        this.selectedId = '';
                        this.selectedChecklistData = [];
                        this.showMessage = false;
                        this.savedDocs.srNo = '';
                        this.savedDocs.sanctionValue = [];
                        this.savedDocs.documentNames = '';
                        this.savedDocs.showChecklist = false;
                        this.newsanction = 'Other-';
                        this.newDocTable = [];

                        this.refreshLookup = false;
                        // this.connectedCallback();
                    })
                    .catch((error) => {
                        // this.connectedCallback();
                        console.error('Error getAllSanctionCheckList --> ', JSON.stringify(error));
                    });
                }else{
                    // this.showToastMessage('Error', 'Please select a document for this condition to create a sanction.', 'error');
                    createSanctions({recordId : this.recordId, checklist : this.selectedChecklistData, sanctionMaster : this.selectedId, documentType: this.selectedDocType})
                    .then((result) => {
                        this.showToastMessage('Success', 'New sanction condition added successfully.', 'success');
                        this.fetchSanctions();
                        // this.handleClose();
                        this.template.querySelector('c-search-lookup').handleReset(event);
                        this.refreshLookup = true;
                        const srNo = this.createdNewDocTable.length + 1;
                        this.savedDocs.srNo = srNo;
                        this.savedDocs.id = result.id;
                        this.savedDocs.sanctionValue = result.name;
                        this.savedDocs.documentType = result.documentType;
                        if(result.showChecklist){
                            this.savedDocs.showChecklist = true;
                            this.savedDocs.documentNames = result.sanctionChecklist;
                        }else{
                            this.savedDocs.showChecklist = false;
                        }
                        this.createdNewDocTable = [...this.createdNewDocTable, { ...this.savedDocs }];
                        console.log('this.createdNewDocTable -->'+JSON.stringify(this.createdNewDocTable));
                        this.allChecklist = [];
                        this.selectedId = '';
                        this.selectedChecklistData = [];
                        this.showMessage = false;
                        this.savedDocs.srNo = '';
                        this.savedDocs.sanctionValue = [];
                        this.savedDocs.documentNames = '';
                        this.savedDocs.showChecklist = false;
                        this.newsanction = 'Other-';
                        this.newDocTable = [];
                        this.refreshLookup = false;
                        // this.connectedCallback();
                    })
                    .catch((error) => {
                        // this.connectedCallback();
                        console.error('Error getAllSanctionCheckList --> ', JSON.stringify(error));
                    });
                }
            } else {
                if (!this.selectedDocType) {
                    this.showToastMessage('Error', 'Please select Document Type.', 'error');
                    return;
                }
                if(this.newsanction != '' && this.newsanction != null && this.newsanction != undefined && this.newsanction != 'Other-'){
                    let allNewDocsName = [];
                    this.newDocTable.forEach(data => {
                        if(data.nameValue != '' && data.nameValue != null && data.nameValue != undefined){
                            allNewDocsName.push(data.nameValue);
                        }
                    });
                    createSanctionsNew({recordId : this.recordId, checklist : allNewDocsName, sanctionMaster : this.newsanction, documentType: this.selectedDocType,sanType:this.isCritical})
                    .then((result) => {

                        this.showToastMessage('Success', 'New sanction condition added successfully.', 'success');
                        this.fetchSanctions();

                        const srNo = this.createdNewDocTable.length + 1;
                        this.savedDocs.srNo = srNo;
                        this.savedDocs.id = result.id;
                        this.savedDocs.sanctionValue = this.newsanction;
                        this.savedDocs.documentType = result.documentType;
                        if(result.showChecklist){
                            this.savedDocs.showChecklist = true;
                            this.savedDocs.documentNames = result.sanctionChecklist;
                        }else{
                            this.savedDocs.showChecklist = false;
                        }

                        this.createdNewDocTable = [...this.createdNewDocTable, { ...this.savedDocs }];

                        console.log('this.createdNewDocTable -->'+JSON.stringify(this.createdNewDocTable));

                        this.savedDocs.srNo = '';
                        this.savedDocs.sanctionValue = [];
                        this.savedDocs.documentNames = '';
                        this.savedDocs.showChecklist = false;
                        this.newsanction = 'Other-';
                        this.newDocTable = [];
                    })
                    .catch((error) => {
                        console.error('Error createSanctionsNew --> ', JSON.stringify(error));
                    });
                }else{
                    this.showToastMessage('Error', 'Please add a valid sanction condition.', 'error');
                }
            }
        }else{
            this.showToastMessage('Error', 'Please select an condition to create a sanction.', 'error');
        }
    }
    handleCheckboxChange(event) {
        const docId = event.target.dataset.docid;
        const isChecked = event.target.checked;

        if (isChecked) {
            this.selectedIds.add(docId);
        } else {
            this.selectedIds.delete(docId);
        }

        this.allSanctions = this.allSanctions.map(row => {
            if (row.id == docId) {
                return { ...row, isSelected: isChecked };
            }
            return row;
        });

        this.isAllSelected = this.allSanctions.every(row => row.isAllSelected);
        console.log('Selected IDs → ', this.selectedIds);
    }

    handleSelectAllChange(event) {
        this.isAllSelected = event.target.checked;

        if (this.isAllSelected) {
            this.allSanctions = this.allSanctions.map(row => {
                this.selectedIds.add(row.id);
                return { ...row, isSelected: this.isAllSelected };
            });
        } else {
            this.allSanctions = this.allSanctions.map(row => {
                return { ...row, isSelected: this.isAllSelected };
            });
            this.selectedIds = new Set();
        }

        console.log('Selected IDs → ', this.selectedIds);
    }

    handleCallApprovalProcess(){
        this.showApprovalProcess = true;
    }

    handleCloseApproval(){
          this.showApprovalProcess = false;
    }

}