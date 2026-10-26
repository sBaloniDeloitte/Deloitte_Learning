import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, createRecord, updateRecord } from "lightning/uiRecordApi";
import DOCUMENT_CHECKLIST_OBJECT from '@salesforce/schema/Document_Details__c';

import deleteDocIds from '@salesforce/apex/SanctionConditionController.deleteDocIds';
import deleteSanctionIds from '@salesforce/apex/SanctionConditionController.deleteSanctionIds';
import createSanctionsNew from '@salesforce/apex/SanctionConditionController.createSanctionsNew';
import checkExistingSanctions from '@salesforce/apex/SanctionConditionController.checkExistingSanctions';
import createSanctions from '@salesforce/apex/SanctionConditionController.createSanctions';
import getAllSanctionConditions from '@salesforce/apex/SanctionConditionController.getAllSanctionConditions';
import getAllSanctionCheckList from '@salesforce/apex/SanctionConditionController.getAllSanctionCheckList';
import checkdocUploaded from '@salesforce/apex/SanctionConditionController.checkdocUploaded';
import { NavigationMixin } from 'lightning/navigation';
import USERID_FIELD from "@salesforce/user/Id";
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import getOpportunityTeamMembers from '@salesforce/apex/AHL_LoanDetailsController.getOpportunityTeamMembers';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import createSanctionwithDocs from '@salesforce/apex/SanctionConditionController.createSanctionwithDocs';
import getLoanTransactionDetails from '@salesforce/apex/AHL_LoanDetailsController.getLoanTransactionDetails';
import canUserEditRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.canUserEditRecord';
import checkEditableOrNot from '@salesforce/apex/Hl_CovenantsDetailFormController.checkEditableOrNot';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import COVENANT_MASTER from "@salesforce/schema/Covenant_Master__c";
import COVENANT_TYPE from "@salesforce/schema/Covenant_Master__c.covenanttype__c";
import getProfileWiseCovenantType from '@salesforce/apex/Utility.getProfileWiseCovenantType';
import getOthersanctionconditionMaster from '@salesforce/apex/SanctionConditionController.getOthersanctionconditionMaster';
import checkPermissionsONPSVCredit from '@salesforce/apex/SanctionConditionController.checkPermissionsONPSVCredit';

export default class SanctionConditionsCmp extends NavigationMixin(LightningElement) {
    @api recordId;

    @track isRendered = false;

    @track allSanctions = [];

    @track allChecklist = [];
    @track showSanctionButton = true;

    @track showMessage = false;
    @track selectedId = '';
    @track selectedChecklistData = [];
    @track modalVisibility = false;
    @track modalVisibilityEdit = false;

    @track newsanction = 'Other-';
    @track newDocTable = [];
    @track createdNewDocTable = [];
    @track selectedDocType = '';
    @track applicableValues = [];
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
    @track showConfirmationSanctionDelete = false;
    confirmMessageSanction = 'Are you sure you want to delete this sanction condition?';
    optionsList = [
        { label: 'Cleared', value: 'Cleared' },
        { label: 'Pending', value: 'Pending' },
        { label: 'OTC', value: 'OTC' },
        { label: 'PDD', value: 'PDD' }
    ];
    @track selectedDocType = '';
    docTypeOptions = [
        { label: 'Document', value: 'Document' },
        { label: 'Non-Document', value: 'Non-Document' }
    ];
    typeOption = [
        { label: 'Critical', value: 'Critical' },
        { label: 'Non-Critical', value: 'Non-Critical' }
    ];
    @track isCritical = 'Critical';
    newsanctionId;
    showAddCustom = false;
    newsanctionName;
    userProfile;
    fromSales = false;
    notcredit = false;
    newdocName;
    sanctionConditionFilterCriteria = '[RecordType.Name = Sanction Conditions;]';
    checkLastSelected = false;
    get readOnlyStatus() {
        return this.fromSales || this.disableStatusEdit;
    }

    quickDisb;
    qdpStatus = '';

    @track disabledCmp = false;
    @track isHomeLoan=false;
    @track productFilter= '';
    @track selectedProduct;
    @track sanctionIdtoEdit;
    @track selectedName;
    @track newRemark;
    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, SUBSTAGE_FIELD] })
    opportunity({ error, data }) {
        if(data) {
            this.oppStage = data.fields.StageName.value;
            this.oppSubStage = data.fields.Sub_stage__c.value;
        }
    }

    @wire(getObjectInfo, { objectApiName: COVENANT_MASTER })
    covenantMasterObjectInfo;

    @wire(getPicklistValues, { recordTypeId:'$covenantMasterObjectInfo.data.defaultRecordTypeId', fieldApiName: COVENANT_TYPE })
    getCovenantValues({ data, error }) {
        if(data && this.isHomeLoan) {
            console.log('data.values'+ JSON.stringify(data.values));
            this.optionsList = data.values.filter(option => option.value !== 'LOS' && option.value !== 'OTC' && option.value !== 'PDD');
            console.log('optionslisttt----', this.optionsList);
            
        }
        if(error){
            console.log('error-->',error);
        }
    }

    @wire(getOpportunityTeamMembers, {
        loanId: "$recordId",
    })
    getOppTeamMembers({
        data,
        error
    }) {
        if (data) {
            data.forEach(item => {
                if(item.UserId == USERID_FIELD){
                    console.log('user present');
                    this.currentUserOppRole.push(item.TeamMemberRole);    
                }
                console.log('data of user',this.currentUserOppRole );
            })
        } else if (error) {
            console.log('error getting opp team: ', error);
        }
        console.log(' Role name ',this.currentUserOppRole);
    }

    @wire(getLoanTransactionDetails, {
        loanId: "$recordId",
    })
    getLoanTxnDetails({
        data,
        error
    }){
        if (data) {
            console.log('getLoanTxnDetails   ', data)
            this.qdpStatus = data.QDP_Status__c ?? 'N/A';   
            this.quickDisb = data.Quick_Disbursement__c ?? false;
            console.log('this.qdpStatus is '+this.qdpStatus+'  and this.quickDisb is '+this.quickDisb)
        } else if(error) {
            this.handleError(error, 'gotLoanFields');
            this.showToast(this.toastTitle.ERROR, this.toastMessages.SOMETHING_WENT_WRONG, this.toastVariant.ERROR);
        }
    }

    connectedCallback(){
        this.fetchProducDetails();
        
        this.fetchSanctions();
        this.checkCmpEditability();
        this.productFilter = '[Loan_Application__c = ' + this.recordId  + ';RecordType.Name = Product' + ']';
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

    fetchProducDetails(){
        var inputMapParam = {
            'oppId': this.recordId
        };

        getProductDetails({inputMap : inputMapParam})
        .then(result =>{
            console.log('result product: '+ JSON.stringify(result));
            this.isHLRelated = result.isHLRelated;
            
            if(result.isHLRelated){
                this.sanctionConditionFilterCriteria = '[RecordType.Name = Sanction Conditions; Product_Name__c = Home Loan]';
                this.isHomeLoan= true;

                // this.selectedId = 'a0L9H0000027N2lUAE';
                this.selectedName = 'Other';
                this.showMessage = false;
                this.showAddCustom = true;
                this.checkLastSelected = true;

                getOthersanctionconditionMaster({})
                .then(result => {
                    if(result){
                        this.selectedId = result;
                    }
                })

            }

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
                    this.showSanctionButton = false; //New Sub stage changes
                }
                else{
                    this.fromSales = false;
                }

                if(!this.isHLRelated && this.userProfile == 'Credit Officer') {
                this.showSanctionButton = false;
                }
                if(this.userProfile == 'Ops'){
                    this.showSanctionButton = false;
                }
                this.fetchApplicableValues();
                this.isCritical = 'Critical';
            })
            .catch((error) => {
                console.error('Error getCurrentUserProfileName --> '+ error);
            });

            canUserEditRecord({recordId: this.recordId})
            .then(result => {
                if(result){
                    this.showSanctionButton = false;
                }
            })

            checkEditableOrNot({ recordId: this.recordId })
            .then(result => {
                if(result){
                    this.showSanctionButton = false;
                }
            })
        })
        .catch(error=>{
            console.error('error in getting product: '+ error)
        })
    }

    customerProfile = '';
    checkCmpEditability() {
        getComponentEditability({ loanId : this.recordId, component : '' })
        .then(result => {
            
                this.disabledCmp = result;
                 console.log(' this.disabledCmp>>>'+ this.disabledCmp);
                checkPermissionsONPSVCredit({loanId : this.recordId}).then(data=>{
                    console.log('data>>'+data);
                    this.customerProfile = data;
                    if(data.Customer_Profile__c != 'SEP' && data.Customer_Profile__c != 'SENP'){
                        this.disabledCmp = false;
                        //this.showSanctionButton = true;
            }
                    
                })
            
        })
        .catch(error => {
            console.log('Error getComponentEditability:  '+error);
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
        const isQDP = this.quickDisb === true && this.qdpStatus === 'QDP-ONHOLD';
        console.log('isQDP   '+isQDP)

        var disableControls = false;
        if(this.currentUserOppRole.includes('OPS Maker') || this.currentUserOppRole.includes('OPS Author') || this.currentUserOppRole.includes('Sales') || (this.userProfile == 'Sales' && this.oppStage == 'Credit Underwriting') || (this.userProfile == 'Sales' && this.oppSubStage == 'PSV Sales') || isQDP){
            disableControls = true;
        }

        if(this.isHomeLoan){
            this.allSanctions = this.allSanctions.map(row => {  
                var chkListLine;
                console.log('row.Verification----', row.Verification);
                if(row.Verification == 'Received - Checker' || 
                   this.oppSubStage == 'Ops Author'  || 
                   ((this.customerProfile == 'SEP'|| this.customerProfile == 'SENP') && this.oppSubStage == 'Ops Maker')){ //adding the maker condition after disc with Neeti on19th Jan
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

        console.log('this.allSanctions----at 296-', JSON.stringify(this.allSanctions));
        
        
        
        if(disableControls){
            console.log('disable controls--');

            this.disableAddConditionBtn = true;

            this.allSanctions = this.allSanctions.map(row => { 
                
                var chkListLine;

                if(row.sanctionChecklist){
                    chkListLine = row.sanctionChecklist.map(item => {
                        console.log('Checklist item:', item.ddw);
                        let updatedDdw = item.ddw
                            ? {
                                ...item.ddw,
                                showUpload: true,
                                showDelete: true
                            }
                            : {
                                showUpload: true,
                                showDelete: true
                            };
            
                        return {
                            ...item,
                            ddw: updatedDdw,
                            showDelete: true
                        };
                    });
                    // chkListLine = row.sanctionChecklist.map(item => { 
                    //     return { 
                    //         ...item, 
                    //         showDelete: true
                    //     }; 
                    // });
                }

                if (this.userProfile == 'Sales' && this.oppSubStage == 'PSV Sales') {
                    
                    return { 
                        ...row, 
                        disableStatus: true,
                        showAddDocSection: true,
                        isDefault: true,
                        sanctionChecklist: chkListLine
                    }; 
                }else if(this.isHomeLoan && this.userProfile == 'Ops' && (this.customerProfile != 'SEP'|| this.customerProfile != 'SENP')){
                    return { 
                        ...row, 
                        disableStatus: this.disabledCmp,
                        showAddDocSection: !this.disabledCmp,
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
            console.log('conditions at 403---', JSON.stringify(this.allSanctions));
            
        }
         if(this.oppSubStage == 'PSV Credit'){
            this.showSanctionButton = false;
        }
        console.log('At 251');
        if((this.oppStage == 'Disbursement' && this.oppSubStage == 'Ops Maker' && (this.currentUserOppRole.includes('OPS Maker') || this.currentUserOppRole.includes('Credit Officer'))) || 
            (this.oppStage == 'PSV' && this.oppSubStage == 'PSV Sales' && this.currentUserOppRole.includes('Sales'))){
                this.showSanctionButton = false;
                this.disableAddConditionBtn = false;
                console.log('AT 255');
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
    get hasSanctions() {
        return this.allSanctions.length > 0;
    }

    handleselectionChange(event){
        const sanctionId = event.target.dataset.name;
        const docId = event.target.dataset.id;
        this.allSanctions.forEach(record => {
            if(record.id == sanctionId){
                record.sanctionChecklist.forEach(data => {
                    if(data.id == docId){
                        data.selected = event.target.checked;
                    }
                });
            }
        });

        console.log('this.allSanctions -->'+JSON.stringify(this.allSanctions));
    }

    handleAddSanction(){
        if(this.isHomeLoan){
            getOthersanctionconditionMaster({})
            .then(result => {
                if(result){
                    this.selectedId = result;
                }
            })
        }
        this.modalVisibility = true;
        this.showAddCustom = false;
        this.newsanctionName = '';
        this.selectedDocType = '';
    }

    handleldeselectSantion(event){
        console.log('409');
        this.selectedId = '';
        this.allChecklist = [];
        this.newsanction = 'Other-';
        this.selectedChecklistData = [];
        this.showMessage = false;
        this.showAddCustom = false;
        this.selectedDocType = '';
    }

    handleldeselectSantionEdit(event){
        this.selectedId = '';
        this.allChecklist = [];
        this.newsanction = 'Other-';
        this.selectedChecklistData = [];
        this.showMessage = false;
        this.showAddCustom = false;
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
        this.selectedName = event.detail.searchRecord.Name;
        console.log('this.recordName--> '+event.detail.searchRecord.Name);
        if(recordName == 'Other'){
            this.showMessage = false;
            this.showAddCustom = true;
            this.checkLastSelected = true;
        }else{
            this.checkLastSelected = false;
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
        if(this.checkLastSelected){
        this.showAddCustom = true;
        }
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
        createSanctions({sanctionMaster : this.selectedId, recordId : this.recordId, checklist : this.selectedChecklistData, newSanctionName : this.newsanctionName, documentType : this.selectedDocType, sanType : this.isCritical})
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
            if(!this.checkLastSelected){
            this.selectedId = '';
            }
            this.selectedChecklistData = [];
            this.showMessage = false;
            this.savedDocs.srNo = '';
            this.savedDocs.sanctionValue = [];
            this.savedDocs.documentNames = '';
            this.savedDocs.showChecklist = false;
            this.savedDocs.documentType = '';
            this.newsanction = 'Other-';
            this.newDocTable = [];
            if(!this.checkLastSelected){
            this.handleldeselectSantion();
            }
            else{
            this.selectedDocType = '';
            }
            this.newsanctionName = '';
            this.refreshLookup = false;
        })
        .catch((error) => {
            console.error('Error createSanctions --> ', JSON.stringify(error));
        });
    }

     /*Sujit*/
    handleSave(event){
        console.log('575 selectedId : '+this.selectedId);
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
                    createSanctions({sanctionMaster : this.selectedId, recordId : this.recordId, checklist : this.selectedChecklistData, newSanctionName : this.newsanctionName, documentType : this.selectedDocType, sanType : this.isCritical})
                    // createSanctions({sanctionMaster : this.selectedId, recordId : this.recordId, checklist : this.selectedChecklistData, documentType: this.selectedDocType})
                    .then((result) => {
                        this.showToastMessage('Success', 'New sanction condition added successfully.', 'success');
                        this.fetchSanctions();
                        // this.handleClose();
                        // this.template.querySelector('c-search-lookup').handleReset(event);
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
                        if(!this.checkLastSelected){
                        this.selectedId = '';
                        }
                        this.selectedChecklistData = [];
                        this.showMessage = false;
                        this.savedDocs.srNo = '';
                        this.savedDocs.sanctionValue = [];
                        this.savedDocs.documentNames = '';
                        this.savedDocs.showChecklist = false;
                        this.newsanction = 'Other-';
                        this.newDocTable = [];
                        this.selectedDocType = '';
                        this.showAddCustom = false;
                        this.newsanctionName = '';

                        this.refreshLookup = false;
                        // this.connectedCallback();
                    })
                    .catch((error) => {
                        // this.connectedCallback();
                        console.error('Error getAllSanctionCheckList --> ', JSON.stringify(error));
                    });
                }else{
                    // this.showToastMessage('Error', 'Please select a document for this condition to create a sanction.', 'error');
                    createSanctions({sanctionMaster : this.selectedId, recordId : this.recordId, checklist : this.selectedChecklistData, newSanctionName : this.newsanctionName, documentType : this.selectedDocType, sanType : this.isCritical})
                    // createSanctions({sanctionMaster : this.selectedId, recordId : this.recordId, checklist : this.selectedChecklistData, documentType: this.selectedDocType})
                    .then((result) => {
                        this.showToastMessage('Success', 'New sanction condition added successfully.', 'success');
                        this.fetchSanctions();
                        // this.handleClose();
                        // this.template.querySelector('c-search-lookup').handleReset(event);
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
                        // this.selectedId = '';
                        this.selectedChecklistData = [];
                        this.showMessage = false;
                        this.savedDocs.srNo = '';
                        this.savedDocs.sanctionValue = [];
                        this.savedDocs.documentNames = '';
                        this.savedDocs.showChecklist = false;
                        this.newsanction = 'Other-';
                        this.newDocTable = [];
                        this.refreshLookup = false;
                        this.selectedDocType = '';
                        this.showAddCustom = false;
                        this.newsanctionName = '';
                        if(!this.checkLastSelected){
                        this.selectedId = '';
                        }
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
                        this.selectedDocType = '';
                        this.showAddCustom = false;
                        this.newsanctionName = '';
                        if(!this.checkLastSelected){
                        this.selectedId = '';
                        }
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
        this.modalVisibility = false;
        this.showConfirmation = true;
    }
    handleshowgenericConfirmSanction(event){
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
        if(this.eventName != 'Main Table'){
            this.modalVisibility = true;
        }
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
                    this.modalVisibility = true;
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

                                // this.fetchSanctions();
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
        if(this.eventName != 'Main Table'){
            this.modalVisibility = true;
        }
        this.eventName = '';
        this.showConfirmation = false;
    }

    handleselectionChangeModal(event){
        const sanctionId = event.target.dataset.name;
        const docId = event.target.dataset.id;
        this.createdNewDocTable.forEach(record => {
            if(record.id == sanctionId){
                record.documentNames.forEach(data => {
                    if(data.id == docId){
                        data.selected = event.target.checked;
                    }
                });
            }
        });

        console.log('this.createdNewDocTable -->'+JSON.stringify(this.createdNewDocTable));
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
    handleAddDocument(){
        const srNo = this.newDocTable.length + 1;
        this.newEntry.srNo = srNo;
        this.newDocTable = [...this.newDocTable, { ...this.newEntry }];
    }
    handleNewDocName(event){
        const srNo = event.target.dataset.id;
        this.newDocTable.forEach(data => {
            if(data.srNo == srNo){
                data.nameValue = event.target.value;
            }
        });
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

    handleCloseEdit(){
        this.allChecklist = [];
        this.selectedId = '';
        this.selectedChecklistData = [];
        this.showMessage = false;
        this.modalVisibilityEdit= false;
        this.savedDocs.srNo = '';
        this.savedDocs.sanctionValue = '';
        this.savedDocs.documentNames = '';
        this.newDocTable = [];
        this.selectedDocType = '';
        this.createdNewDocTable = [];
        this.sanctiondocTodelete = '';
        this.eventName = '';
        this.sanctionIdtoDelete = '';
        this.sanctionIdtoEdit = '';
    }
    

    handleEditSanction(event){
        console.log('insoide editttt');
        console.log('event----', event.target.dataset.sanctionid);
        console.log('event----', event.target.dataset.id); 
        if(this.userProfile == 'Sales' && this.oppSubStage == 'PSV Sales' && !this.isHomeLoan){

        }else{
            const conId =  event.target.dataset.id;
            this.sanctionIdtoEdit = event.target.dataset.id;
            this.modalVisibilityEdit = true;
            var condition= this.allSanctions.find(cust => cust.id === conId);
            this.selectedDocType = condition.documentType;
            this.selectedId = condition.master;
            this.selectedName = condition.masterName;
            this.newRemark = condition.remarks;
            if(condition.masterName== 'Other' || isHomeLoan){
                this.showAddCustom = true;
                this.checkLastSelected = true;
                this.newsanctionName = condition.name;
            }else{
                this.showAddCustom = false;
                this.checkLastSelected = false;
            }
        }      
    }

    handleUpdateCondition(){
        const fields = {};
        fields['Id'] = this.sanctionIdtoEdit;
        fields['Deviation_Mitigant_Master__c'] = this.selectedId;
        if(this.selectedName== 'Other'){
            fields['Condition_Name__c'] = this.newsanctionName;
        }else{
            fields['Condition_Name__c'] = this.selectedName;
        }
        fields['Document_Type__c'] = this.selectedDocType;
        fields['HL_Sales_Remarks__c'] = this.newRemark;
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                this.fetchSanctions();
                this.handleCloseEdit();
                this.showToastMessage('Success', 'Sanction condition updated successfully.', 'success');
            })
            .catch(error => {
                this.showToastMessage('Error updating record', error.message, 'error');
                console.log('Error updating record --> '+JSON.stringify(error));
            });
    }

    handleRefresh(event){
        this.allChecklist = [];
        this.selectedId = '';
        this.newsanction = 'Other-';
        this.selectedDocType = '';
        this.template.querySelector('c-search-lookup').handleReset(event);
    }

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
        if(this.isHomeLoan){
            if (!this.applicableValues.includes(val)) {
                this.showToastMessage(
                    'Error',
                    `The value "${val}" is not applicable for your profile.`,
                    'error'
                );
                const combobox = this.template.querySelector(`lightning-combobox[data-id="${santionId}"]`);
                        if (combobox) {
                            combobox.value = 'Pending';
                        }
                return;
            }else{
                this.updateRecordField(santionId, 'Condition_Approval__c', val);
                this.fetchSanctions();
            }
        }else{
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
                this.updateRecordField(santionId, 'Condition_Approval__c', val);
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
          // Create and append styles dynamically
          const style = document.createElement("style");
          style.innerText = `
            .slds-form-element .slds-dropdown_left {
                min-width: 70%;
            }

            .slds-dropdown,
            .slds-listbox,
            .slds-listbox_vertical {
                background: #16283f !important;
            }

            .slds-listbox__option {
                background: #16283f !important;
                color: #ffffff !important;
            }

            .slds-listbox__option:hover,
            .slds-listbox__option.slds-has-focus,
            .slds-listbox__option[aria-selected="true"] {
                background: #1b304d !important;
                color: #ffffff !important;
            }

            .slds-media__body,
            .slds-listbox__option-text {
                color: #ffffff !important;
            }
        `;
    
          // Append the styles to the .styleContainer
          this.template.querySelector(".styleContainer")?.appendChild(style);
    
          // Prevent re-adding styles
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

    handleDeselectProduct(event){
        const santionId =  event.target.dataset.id;
        this.selectedProduct = null;
        this.updateRecordField(santionId, 'HL_Related_Product__c', null);
        this.fetchSanctions();
    }
    handleRemarkChange(event){
        this.newRemark = event.target.value;
    }
}