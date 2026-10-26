import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import Document_Details_Obj from "@salesforce/schema/Document_Details__c";
import Status_Field from "@salesforce/schema/Document_Details__c.Status__c";
import getCovenantDetail from '@salesforce/apex/Hl_CovenantsDetailFormController.getCovenantDetail';
import getDocumentDetailRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.getDocumentDetailRecord';
import upsertDocumentDetailsBatch from '@salesforce/apex/Hl_CovenantsDetailFormController.upsertDocumentDetailsMulti';
import deletedocumentIds from '@salesforce/apex/Hl_CovenantsDetailFormController.deletedocumentIds';
import getCurrentUserRole from '@salesforce/apex/Hl_CovenantsDetailFormController.getCurrentUserRole';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchDocDetailPicklistValue from '@salesforce/apex/Hl_CovenantsDetailFormController.fetchDocDetailPicklistValue';
import deleteDocumentDetailRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.deleteDocumentDetailRecord';
import getCovenantNameValues from '@salesforce/apex/Hl_CovenantsDetailFormController.getCovenantNameValues';
import getDocumentMasterRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.getDocumentMasterRecord';
import getProductData from '@salesforce/apex/Hl_CovenantsDetailFormController.getProductData';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import COVENANT_MASTER from "@salesforce/schema/Covenant_Master__c";
import COVENANT_CATEGORY from "@salesforce/schema/Covenant_Master__c.category__c";
import COVENANT_TYPE from '@salesforce/schema/Covenant_Master__c.covenanttype__c';
import getCovenantNameValuesHL from '@salesforce/apex/Hl_CovenantsDetailFormController.getCovenantNameValuesHL';
import getCovenantDocNameValuesHL from '@salesforce/apex/Hl_CovenantsDetailFormController.getCovenantDocNameValuesHL';
import userId from '@salesforce/user/Id';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/User.Name';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
// import getProfileWiseCovenantType from '@salesforce/apex/Utility.getProfileWiseCovenantType';
import covenantApproverValues from '@salesforce/label/c.Covenant_Approver_Values';
import uploadApprovalDisableFor from '@salesforce/label/c.Covenant_Disable_Approval_Upload';
import getStartDate from '@salesforce/apex/Hl_CovenantsDetailFormController.getStartDate';
const FIELDS = [NAME_FIELD, PROFILE_NAME_FIELD];

export default class CovenantsDetailForm_hl extends LightningElement {
    @api recordId;
    isLoading = false;
    showNoRecords = false;
    disableDocField = false;
    showSummaryStyle = true;
    showConfirmation = false;
    isRendered = false;

    @track displayList;
    @track detailRecord = [];
    @track pendingRows = [];
    @track editedRowIds = new Set();
    @track modifiedRows = new Map();

    docNameOptions = [];
    @track productOptions = [];
    @track covCategoryHL = [];
    @track covTypeHL = [];
    rawCovenantPicklistOptions;
    rawCovenantTypePicklistOptions;

    currentUserId = userId;
    userName;
    profileName;
    salesProfile = false;

    @track isHomeLoan = false;
    loanStartDate;
    addedCovenantIds = [];

    selectedDocIds = new Set();
    isAllSelected = false;
    showApprovalButton = false;
    showApprovalProcess = false;

    label = {
        covenantApproverValues,
        uploadApprovalDisableFor
    };
    splittedApplicableApproverValues = [];
    applicableValues = [];

    confirmMessage = 'Are you sure you want to delete these document(s)?';
    sanctiondocTodelete;

    rowCounter = 0;

    statusOptions = [
        { label: '-- Select Status --', value: '' },
        { label: 'Pending', value: 'Pending' },
        { label: 'Mandatory', value: 'Mandatory' },
        { label: 'Waiver', value: 'Waiver' }
    ];

    approvalStatusOptions = [
        { label: '-- Select Status --', value: '' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Rejected', value: 'Rejected' }
    ];

    approvalLevelOptions = [
        { label: '-- Select Level --', value: '' },
        { label: 'L1', value: 'L1' },
        { label: 'L2', value: 'L2' },
        { label: 'L3', value: 'L3' },
        { label: 'L4', value: 'L4' },
        { label: 'L5', value: 'L5' }
    ];

    typeOptions = [
        { label: '-- Select Type --', value: '' },
        { label: 'Critical', value: 'Critical' },
        { label: 'Non-Critical', value: 'Non-Critical' }
    ];

    nodOptions = [
        { label: '-- Select Option --', value: '' },
        { label: 'Original', value: 'Original' },
        { label: 'Photocopy', value: 'Photocopy' },
        { label: 'Certified copy', value: 'Certified copy' },
        { label: 'Others', value: 'Others' }
    ];

    covCategory = [
        { label: '-- Select Category --', value: '' },
        { label: 'LEGXT', value: 'LEGXT' },
        { label: 'CREDIT', value: 'CREDIT' },
        { label: 'OTH', value: 'OTH' }
    ];

    covType = [
        { label: '-- Select Name --', value: '' },
        { label: 'OTC', value: 'OTC' },
        { label: 'PDD', value: 'PDD' },
        { label: 'LOS', value: 'LOS' }
    ];

    get hasUnsavedChanges() {
        return this.pendingRows.length > 0 || this.modifiedRows.size > 0;
    }

    get showSaveButton() {
        return this.hasUnsavedChanges;
    }

    get combinedRecords() {
        const existingWithEditState = this.detailRecord.map(category => ({
            ...category,
            documentList: category.documentList.map(doc => ({
                ...doc,
                isEditing: this.editedRowIds.has(doc.documentDetailId),
                isExisting: true,
                rowKey: doc.documentDetailId
            }))
        }));
        return existingWithEditState;
    }

    @wire(getRecord, { recordId: USER_ID, fields: FIELDS })
    userDetails({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
            this.profileName = data.fields.Profile.value.fields.Name.value;
            this.salesProfile = this.profileName === 'Sales';
        } else if (error) {
            console.error('Error fetching user details:', error);
        }
    }

    @wire(getObjectInfo, { objectApiName: COVENANT_MASTER })
    covenantMasterObjectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$covenantMasterObjectInfo.data.defaultRecordTypeId',
        fieldApiName: COVENANT_CATEGORY
    })
    getCovenantValues({ data, error }) {
        if (data) {
            this.rawCovenantPicklistOptions = data.values;
            this.covCategoryHL = this.rawCovenantPicklistOptions;
            this.initializeDefaultCategory();
        }
        if (error) {
            console.error('Error fetching covenant categories:', error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$covenantMasterObjectInfo.data.defaultRecordTypeId',
        fieldApiName: COVENANT_TYPE
    })
    getCovenantValuesType({ data, error }) {
        if (data) {
            this.rawCovenantTypePicklistOptions = data.values;
            this.covTypeHL = this.rawCovenantTypePicklistOptions;
            this.covTypeHL = this.rawCovenantTypePicklistOptions.filter(
                option => !['LOS', 'OTC', 'PDD'].includes(option.value)
            );
            if(this.covTypeHL == null||this.covTypeHL ==undefined||this.covTypeHL =='' ){
                this.typeValue='Pending';
                this.docDetail['Document_Type__c'] ='Pending';
            }
        }
        if (error) {
            console.error('Error fetching covenant types:', error);
        }
    }

    connectedCallback() {
        this.getCovenantDetails();
        this.loadProducts();
        this.checkProductType();
        this.fetchDocDetailPicklistValue();
        // this.fetchApplicableValues();
    }

    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            this.injectCustomStyles();
        }
    }

    initializeDefaultCategory() {
        const inputMap = { documentCategory: 'Credit' };
        getCovenantNameValuesHL({ inputMap })
        .then(result => {
            this.docNameOptions = [
                { label: 'Select Options', value: '' },
                ...result.map(item => ({
                    label: `${item.code__c}: ${item.description__c}`,
                    value: item.Id
                }))
            ];
        })
        .catch(error => console.error('Error loading covenant names:', error));
    }

    checkProductType() {
        const inputMap = {oppId: this.recordId, legalId: null, technicalId: null};
        getProductDetails({ inputMap })
        .then(result => {
            this.isHomeLoan = result?.isHLRelated || false;
            if (this.isHomeLoan) {
                this.fetchStartDate();
            }
        })
        .catch(error => console.error('Error fetching product details:', error));
    }

    fetchStartDate() {
        getStartDate({ loanId: this.recordId })
        .then(result => {
            if (result) {
                this.loanStartDate = result;
            }
        })
        .catch(error => console.error('Error fetching start date:', error));
    }

    loadProducts() {
    getProductData({ RecordId: this.recordId })
        .then(result => {
            this.productOptions = result.map(prod => ({
                label: prod.Name,
                value: prod.Id,
                Name: prod.Name,
                Id: prod.Id
            }));
        })
        .catch(error => console.error('Error fetching products:', error));
    }

    fetchDocDetailPicklistValue() {
        fetchDocDetailPicklistValue({})
        .then(result => {
            result.forEach(item => {
                this.docNameOptions.push({ label: item, value: item });
            });
        })
        .catch(error => console.error('Error fetching picklist values:', error));
    }

    fetchApplicableValues() {
        getProfileWiseCovenantType({inputMap: { objectApiName: 'Document_Details__c' }})
        .then(result => {
            this.applicableValues = result;
        })
        .catch(error => console.error('Error fetching applicable values:', error));
    }

    getCovenantDetails() {
        getCurrentUserRole({ recordId: this.recordId })
            .then(data => {
                this.disableDocField = data;
            });

        getCovenantDetail({ recordId: this.recordId })
        .then(data => {
            this.displayList = data;
            return getDocumentDetailRecord({
                documentMasterId: data.Id,
                recordId: this.recordId
            });
        })
        .then(result => {
            this.detailRecord = result.map(category => ({
                ...category,
                documentList: category.documentList.map(doc => ({
                    ...doc,
                    isEditing: false,
                    isExisting: true,
                    rowKey: doc.documentDetailId
                }))
            }));

            if (this.isHomeLoan && this.detailRecord.length > 0) {
                this.showApprovalButton = true;
                this.addedCovenantIds = this.detailRecord.flatMap(
                    record => record.documentList.map(doc => doc.covenantId)
                );
            }
        })
        .catch(error => console.error('Error fetching covenant details:', error));
    }

    handleAddRow() {
        const newRow = this.createEmptyRow();
        this.pendingRows = [...this.pendingRows, newRow];
    }
    createEmptyRow() {
        this.rowCounter++;
        return {
            rowKey: `new-${this.rowCounter}`,
            Document_Category__c: 'Credit',
            Document_Type__c: '',
            Document_Name__c: '',
            Covenant_Master__c: '',
            Name: '',
            Description__c: '',
            Product__c: '',
            Type__c: '',
            Status__c: '',
            Remarks__c: '',
            Target_Date__c: null,
            Document_Date_of_Receipt__c: null,
            Nature_of_Document__c: '',
            Approval_Level__c: '',
            Covenant_Approval_Status__c: '',
            docNameOptions: [{ label: 'Select Options', value: '' }],
            isNew: true,
            isEditing: true
        };
    }

    handleRemovePendingRow(event) {
        const rowKey = event.target.dataset.rowkey;
        this.pendingRows = this.pendingRows.filter(row => row.rowKey !== rowKey);
    }

    handleEditRow(event) {
        const docId = event.target.dataset.docid;
        this.editedRowIds.add(docId);
        this.detailRecord = this.detailRecord.map(category => ({
            ...category,
            documentList: category.documentList.map(doc => ({
                ...doc,
                isEditing: this.editedRowIds.has(doc.documentDetailId)
            }))
        }));
    }

    handleCancelEdit(event) {
        const docId = event.target.dataset.docid;
        this.editedRowIds.delete(docId);
        this.modifiedRows.delete(docId);
        this.getCovenantDetails();
    }

    async handlePendingRowChange(event) {
        const rowKey = event.target.dataset.rowkey;
        const fieldName = event.target.name;
        const value = event.target.value;
        const rows = [...this.pendingRows];
        const rowIndex = rows.findIndex(r => r.rowKey === rowKey);
        if (rowIndex === -1) return;

        let row = { ...rows[rowIndex] };
        if (fieldName === 'Document_Category__c') {
            row.Document_Category__c = value;
            // Resetting dependent fields
            row.Document_Name__c = '';
            row.Covenant_Master__c = '';
            row.Name = '';
            row.Description__c = '';
            row.Covenant_Approval_Status__c = '';
            try {
                const result = await getCovenantNameValuesHL({inputMap: { documentCategory: value }});
                row.docNameOptions = [
                    { label: 'Select Options', value: '' },
                    ...result.map(item => ({
                        label: `${item.code__c}: ${item.description__c}`,
                        value: item.Id
                    }))
                ];
            } catch (e) {
                console.error('Error fetching covenant names', e);
            }
        }
        else if (fieldName === 'Document_Name__c') {
            row.Document_Name__c = value;
            try {
                const result = await getCovenantDocNameValuesHL({inputMap: { documentId: value }});
                if (result && result.length > 0) {
                    const record = result[0];
                    // Duplicate check
                    if (this.addedCovenantIds.includes(record.Name)) {
                        this.showToastMessage('Error', 'The covenant already exists. You cannot add a duplicate record.','error');
                        row.Document_Name__c = '';
                    } else {
                        row.Covenant_Master__c = value;
                        row.Name = record.code__c;
                        row.Description__c = record.description__c;
                        row.Covenant_Id__c = record.Name;
                        row.Covenant_Doc_Type__c = record.doctype__c;

                        if (record.covenanttype__c === 'PDD') {
                            row.Document_Type__c = 'PDD-Approved';
                            row.Covenant_Approval_Status__c = 'Approved';
                        }
                    }
                }
            } catch (e) {
                console.error('Error fetching covenant detail', e);
            }
        }
        else if (fieldName === 'Document_Type__c') {
            row.Document_Type__c = value;
            this.splittedApplicableApproverValues = this.label.covenantApproverValues.split(',');
            if (value == 'Received - Checker') {
                row.Covenant_Approval_Status__c = 'Approved';
            }
            else if (this.splittedApplicableApproverValues.includes(value)) {
                row.Covenant_Approval_Status__c = 'Approved';
            } else {
                row.Covenant_Approval_Status__c = '';
            }
        }
        else if (fieldName === 'Target_Date__c' && this.isHomeLoan) {
            if (this.loanStartDate && value < this.loanStartDate) {
                this.showToastMessage('Error','Target Date cannot be less than Loan Start Date.','error');
            } else {
                row.Target_Date__c = value;
            }
        }
        else {
            row[fieldName] = value;
        }
        rows[rowIndex] = row;
        this.pendingRows = rows;
    }

    handleExistingRowChange(event) {
        const docId = event.target.dataset.docid;
        const fieldName = event.target.name;
        const value = event.target.value;
        if (fieldName === 'Document_Type__c' && !this.applicableValues.includes(value)) {
            this.showToastMessage('Error', `The value "${value}" is not applicable for your profile.`, 'error');
            return;
        }
        if (this.isHomeLoan && fieldName === 'Target_Date__c' && value < this.loanStartDate) {
            this.showToastMessage(
                'Error',
                'Target Date cannot be less than Loan Start Date.',
                'error'
            );
            return;
        }
        let approvalStatusToSet;
        if (this.isHomeLoan && fieldName === 'Document_Type__c') {
            this.splittedApplicableApproverValues = this.label.covenantApproverValues.split(',');
            if (value === 'Received - Checker') {
                approvalStatusToSet = 'Approved';
            }
            else if (this.splittedApplicableApproverValues.includes(value)) {
                approvalStatusToSet = 'Approved';
            }
            else {
                approvalStatusToSet = null;
            }
        }

        const existingMod = this.modifiedRows.get(docId) || { Id: docId };
        existingMod[fieldName] = value;
        if (approvalStatusToSet !== undefined) {
            existingMod.Covenant_Approval_Status__c = approvalStatusToSet;
        }

        this.modifiedRows.set(docId, existingMod);

         // Updatinggg UI
        this.detailRecord = this.detailRecord.map(category => ({
            ...category,
            documentList: category.documentList.map(doc => {
                if (doc.documentDetailId === docId) {
                    return { ...doc, [this.mapFieldToDisplayProp(fieldName)]: value,
                        ...(approvalStatusToSet !== undefined
                            ? { covenantApprovalStatus: approvalStatusToSet }
                            : {})
                    };
                }
                return doc;
            })
        }));
    }

    mapFieldToDisplayProp(fieldName) {
        const mapping = {
            'Document_Type__c': 'covenantType',
            'Type__c': 'docType',
            'Status__c': 'status',
            'Remarks__c': 'remarks',
            'Target_Date__c': 'targetDate',
            'Document_Date_of_Receipt__c': 'documentDateOfReceipt',
            'Nature_of_Document__c': 'natureOfDocument',
            'Approval_Level__c': 'approvalLevel',
            'Product__c': 'productId'
        };
        return mapping[fieldName] || fieldName;
    }

    async updateDocNameOptionsForRow(row, category) {
        try {
            const inputMap = { documentCategory: category };
            const result = await getCovenantNameValuesHL({ inputMap });
            row.docNameOptions = [
                { label: 'Select Options', value: '' },
                ...result.map(item => ({
                    label: `${item.code__c}: ${item.description__c}`,
                    value: item.Id
                }))
            ];
            // Clear dependent fields
            /*if ( category) {
                row.Document_Name__c = '';
                row.Name = '';
                row.Description__c = '';
                row._lastCategory = category;
            }*/
        } catch (error) {
            console.error('Error updating doc name options:', error);
        }
    }

    async populateCovenantDetails(row, covenantMasterId) {
        try {
            const inputMap = { documentId: covenantMasterId };
            const result = await getCovenantDocNameValuesHL({ inputMap });
            if (result && result.length > 0) {
                const record = result[0];
                                if (this.addedCovenantIds.includes(record.Name)) {
                    this.showToastMessage('Error', 'The covenant already exists. You cannot add a duplicate record.', 'error');
                    row.Covenant_Master__c = '';
                    return;
                }

                row.Name = record.code__c;
                row.Description__c = record.description__c;
                row.Covenant_Id__c = record.Name;
                row.Covenant_Doc_Type__c = record.doctype__c;
                row.Covenant_Master__c = covenantMasterId;

                if (record.covenanttype__c === 'PDD') {
                    row.Document_Type__c = 'PDD-Approved';
                    row.Covenant_Approval_Status__c = 'Approved';
                }
            }
        } catch (error) {
            console.error('Error populating covenant details:', error);
        }
    }

    // Save methods
    async handleSaveAll() {
        for (const row of this.pendingRows) {
            if (!this.validateRow(row)) {
                return;
            }
        }
        this.isLoading = true;
        try {
            const recordsToUpsert = [];
            for (const row of this.pendingRows) {
                const record = this.prepareRecordForSave(row);
                recordsToUpsert.push(record);
            }
            for (const [docId, modifications] of this.modifiedRows) {
                recordsToUpsert.push({ Id: docId, ...modifications });
            }

            await upsertDocumentDetailsBatch({
                documentDetailsList: recordsToUpsert,
                recordId: this.recordId
            });
            this.showToastMessage('Success', 'All records saved successfully.', 'success');
            // Reset state
            this.pendingRows = [];
            this.editedRowIds.clear();
            this.modifiedRows.clear();
            // Refreshhh
            this.getCovenantDetails();

        } catch (error) {
            console.error('Error saving records:', error);
            this.showToastMessage('Error', error.body?.message || 'Error saving records', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    validateRow(row) {
        const requiredFields = ['Document_Category__c', 'Document_Type__c', 'Name', 'Type__c', 'Remarks__c'];
        for (const field of requiredFields) {
            if (!row[field]) {
                this.showToastMessage('Error', 'Please fill all required fields.', 'error');
                return false;
            }
        }
        if (row.Document_Type__c === 'CSD - Requested' && !row.Target_Date__c) {
            this.showToastMessage('Error', 'Target Date is required for CSD - Requested type.', 'error');
            return false;
        }
        return true;
    }

    prepareRecordForSave(row) {
        return {
            Document_Category__c: row.Document_Category__c,
            Document_Type__c: row.Document_Type__c,
            Covenant_Master__c: row.Covenant_Master__c,
            Name: row.Name,
            Product__c: row.Product__c,
            Type__c: row.Type__c,
            Status__c: row.Status__c,
            Remarks__c: row.Remarks__c,
            Target_Date__c: row.Target_Date__c,
            Document_Date_of_Receipt__c: row.Document_Date_of_Receipt__c,
            Nature_of_Document__c: row.Nature_of_Document__c,
            Approval_Level__c: row.Approval_Level__c,
            Covenant_Id__c: row.Covenant_Id__c,
            Covenant_Doc_Type__c: row.Covenant_Doc_Type__c,
            Covenant_Approval_Status__c: row.Covenant_Approval_Status__c,
            Requirement_At__c: 'Collateral Level'
        };
    }

    handleCancelAll() {
        this.pendingRows = [];
        this.editedRowIds.clear();
        this.modifiedRows.clear();
        this.getCovenantDetails();
    }

    // Delete
    handleDeleteRecord(event) {
        const docId = event.target.dataset.docid;
        this.isLoading = true;

        deleteDocumentDetailRecord({ docDetailId: docId })
            .then(() => {
                this.showToastMessage('Success', 'Document deleted successfully.', 'success');
                this.getCovenantDetails();
            })
            .catch(error => {
                console.error('Error deleting record:', error);
                this.showToastMessage('Error', 'Document not deleted.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleshowgenericConfirm(event) {
        this.sanctiondocTodelete = event.target.dataset.id;
        this.showConfirmation = true;
    }

    handleNo() {
        this.sanctiondocTodelete = '';
        this.showConfirmation = false;
    }

    handleDocDelete() {
        deletedocumentIds({ recordId: this.sanctiondocTodelete })
            .then(() => {
                this.getCovenantDetails();
                this.showToastMessage('Success', 'Document deleted successfully.', 'success');
                this.showConfirmation = false;
            })
            .catch(error => {
                console.error('Error deleting document:', error);
            });
    }

    // Selection
    handleCheckboxChange(event) {
        const docId = event.target.dataset.docid;
        const isChecked = event.target.checked;

        this.splittedApplicableApproverValues = this.label.covenantApproverValues.split(',');

        // Find the document
        let targetDoc = null;
        for (const record of this.detailRecord) {
            targetDoc = record.documentList.find(doc => doc.documentDetailId === docId);
            if (targetDoc) break;
        }
        if (this.splittedApplicableApproverValues.includes(targetDoc?.covenantType)) {
            event.target.checked = false;
            this.showToastMessage('Error', `Records with type "${targetDoc.covenantType}" cannot be sent for approval.`, 'error');
            return;
        }
        if (isChecked) {
            this.selectedDocIds.add(docId);
        } else {
            this.selectedDocIds.delete(docId);
        }
        this.updateSelectionState(docId, isChecked);
    }

    handleSelectAllChange(event) {
        this.splittedApplicableApproverValues = this.label.covenantApproverValues.split(',');
        this.isAllSelected = event.target.checked;
        this.detailRecord.forEach(record => {
            record.documentList.forEach(doc => {
                if (!this.splittedApplicableApproverValues.includes(doc.covenantType)) {
                    doc.isSelected = this.isAllSelected;
                    if (this.isAllSelected) {
                        this.selectedDocIds.add(doc.documentDetailId);
                    } else {
                        this.selectedDocIds.delete(doc.documentDetailId);
                    }
                }
            });
        });
    }

    updateSelectionState(docId, isSelected) {
        this.detailRecord = this.detailRecord.map(record => ({
            ...record,
            documentList: record.documentList.map(doc => {
                if (doc.documentDetailId === docId) {
                    return { ...doc, isSelected };
                }
                return doc;
            })
        }));
        this.isAllSelected = this.detailRecord.every(record =>
            record.documentList.every(doc =>
                this.splittedApplicableApproverValues.includes(doc.covenantType) || doc.isSelected
            )
        );
    }
    handleCallApprovalProcess() {
        this.showApprovalProcess = true;
    }
    handleCloseApproval() {
        this.showApprovalProcess = false;
        this.getCovenantDetails();
    }
    showToastMessage(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    updateDocumentDetails(event) {
        if (event?.detail?.docId) {
            const docId = event.detail.docId;
            const today = new Date().toISOString().slice(0, 10);

            const existingMod = this.modifiedRows.get(docId) || { Id: docId };
            existingMod.Document_Date_of_Receipt__c = today;
            this.modifiedRows.set(docId, existingMod);
        }
    }

    injectCustomStyles() {
        const style = document.createElement('style');
        style.innerText = `
            .uploadFile .slds-file-selector__text.slds-medium-show {
                display: none;
            }
            .uploadFile .slds-file-selector__button.slds-button.slds-button_neutral {
                font-size: 0 !important;
            }
            .uploadFile svg.slds-button__icon.slds-button__icon_left {
                margin: 0;
            }
            .uploadFile lightning-primitive-file-droppable-zone.slds-file-selector__dropzone {
                border: none;
                padding: 0;
            }
            .info-button svg.slds-button__icon.slds-button__icon_left {
                margin: 0;
            }
            .class-file-upload .slds-form-element__label:empty {
                margin: 0;
                display: none;
            }
            .uploaded-view svg.slds-button__icon.slds-button__icon_left,
            .uploaded-view svg.slds-button__icon {
                color: green;
            }
            .uploaded-view svg.slds-button__icon.slds-button__icon_left {
                margin-top: 2%;
            }
            .uploaded-view-disabled svg.slds-button__icon.slds-button__icon_left,
            .uploaded-view-disabled svg.slds-button__icon {
                color: grey;
            }
            .edit-icon {
                cursor: pointer;
                color: #0070d2;
            }
            .edit-icon:hover {
                color: #005fb2;
            }
            .covenant-dark-theme lightning-button.positive-cta .slds-button,
            .covenant-dark-theme lightning-button[variant="brand"] .slds-button {
                background-color: #8b5cf6 !important;
                border-color: #8b5cf6 !important;
                color: #ffffff !important;
                border-radius: 6px !important;
            }
            .covenant-dark-theme lightning-button.positive-cta .slds-button:hover,
            .covenant-dark-theme lightning-button[variant="brand"] .slds-button:hover {
                background-color: #7c3aed !important;
                border-color: #7c3aed !important;
            }
            /* Add-type action CTAs (Add, Add Row, etc.) - Blue, per theme rule. */
            .covenant-dark-theme lightning-button.add-cta .slds-button {
                background-color: #1467eb !important;
                border-color: #1467eb !important;
                color: #ffffff !important;
                border-radius: 6px !important;
            }
            .covenant-dark-theme lightning-button.cancel-cta .slds-button {
                background-color: #16283f;
border-color: #8b5cf6 !important;
                color: #ffffff !important;
                border-radius: 6px !important;
            }

            /* lightning-select/lightning-textarea internals - ::part() support for
               these varies by base component version, so fall back to reaching
               their shadow-rendered markup directly, same technique already used
               above for the upload/edit-icon rules. */
            .covenant-dark-theme lightning-select .slds-select,
            .covenant-dark-theme lightning-combobox .slds-combobox__input {
                background-color: #16283f !important;
                border-color: #33455e !important;
                color: #ffffff !important;
                height: 2.25rem !important;
            }
            /* lightning-select renders a native <select> with <option> children.
               The open options popover is OS/browser-rendered chrome, but
               Chromium-based browsers do honor background-color/color set on
               the <select> and its <option> elements, plus color-scheme to
               theme the native scrollbar/UI - use that to match the dark
               theme instead of the white default. */
            .covenant-dark-theme lightning-select .slds-select {
                color-scheme: dark;
            }
            .covenant-dark-theme lightning-select .slds-select option {
                background-color: #16283f !important;
                color: #ffffff !important;
            }
            .covenant-dark-theme lightning-select .slds-select option:checked,
            .covenant-dark-theme lightning-select .slds-select option:hover {
                background-color: #1589ee !important;
                color: #ffffff !important;
            }
            /* lightning-combobox open dropdown listbox - the select's native
               popover is styled by the browser, but the combobox's SLDS listbox
               needs explicit dark-theme rules or it falls back to white. */
            .covenant-dark-theme lightning-combobox .slds-dropdown,
            .covenant-dark-theme lightning-combobox .slds-dropdown__list,
            .covenant-dark-theme lightning-combobox .slds-listbox_vertical {
                background-color: #16283f !important;
                border-color: #33455e !important;
            }
            .covenant-dark-theme lightning-combobox .slds-listbox__option,
            .covenant-dark-theme lightning-combobox .slds-listbox__item {
                background-color: #16283f !important;
                color: #ffffff !important;
            }
            .covenant-dark-theme lightning-combobox .slds-listbox__option:hover,
            .covenant-dark-theme lightning-combobox .slds-listbox__option:focus,
            .covenant-dark-theme lightning-combobox .slds-listbox__option.slds-has-focus,
            .covenant-dark-theme lightning-combobox .slds-listbox__option[aria-selected="true"] {
                background-color: #1589ee !important;
                color: #ffffff !important;
            }
            .covenant-dark-theme lightning-textarea .slds-textarea {
                background-color: #16283f !important;
                border-color: #33455e !important;
                color: #ffffff !important;
            }
            .covenant-dark-theme lightning-input .slds-input[disabled] {
                background-color: #0e1c30 !important;
                color: #8a99b3 !important;
            }
            .covenant-dark-theme lightning-select .slds-form-element__label,
            .covenant-dark-theme lightning-textarea .slds-form-element__label,
            .covenant-dark-theme lightning-input .slds-form-element__label {
                color: #cfd8e6 !important;
            }
        `;
        this.template.querySelector('.styleContainer')?.appendChild(style);
    }
}