import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getApplicantsAndLoanData from "@salesforce/apex/COMM_ItrScreenController.getApplicantAndLoanAppData";
import insertRefData from '@salesforce/apex/COMM_ItrScreenController.insertRefData';
import { updateRecord } from 'lightning/uiRecordApi';
import getPicklistValuesForDisposition from '@salesforce/apex/COMM_VideoPDController.getPicklistValuesForDisposition';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import DESIGNATION_FIELD from '@salesforce/schema/Application_Verification__c.Designation__c';
import APPLICATION_VERIFICATION_OBJECT from '@salesforce/schema/Application_Verification__c';
import TYPE_OF_ADDRESS_FIELD from '@salesforce/schema/Application_Verification__c.Type_of_Address__c';
import { IsConsoleNavigation, getFocusedTabInfo, closeTab, getEnclosingTabId } from 'lightning/platformWorkspaceApi';
import upsertDocDetailContentId from '@salesforce/apex/CreditPDFormController.upsertDocDetailContentId';
import getLatestDocumentDetails from '@salesforce/apex/CreditPDFormController.fetchLatestDocumentDetails';
import createDocDetailForAV from '@salesforce/apex/CreditPDFormController.createDocDetailForAV';
import getAVDocs from '@salesforce/apex/CreditPDFormController.getAVDocs';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';

export default class CreditPdForm extends NavigationMixin(LightningElement) {
    recordId;
    referenceRecordTypeId;
    appVerifId;
    applicantAndLoanDetails;
    typeOfEntity;
    natureOfBusinessDetails;
    otherAddresses;
    familyDetails;
    additionalFamilyDetails;
    dateOfCommencement;
    annualIncome;
    interviewerName;
    interviewComment;
    ownershipOfBusiness;
    proofOfBusiness;
    employees;
    designationS;
    detailsOfPreviousOrganisation;
    ocrDetails;
    remainingAgeOfRetirement;
    marketValue;
    registryValue;
    additionalDetail1;
    additionalDetail2;
    strength;
    concerns;
    comments;
    dispositionValue;
    showRefTable;
    showAssetTable;
    showChildrenTable;
    sectionName;
    picklistValuesDisposition;
    @track tradeReferenceList = [];
    @track coApplicantList = [];
    @wire(IsConsoleNavigation)
    isConsoleNavigation;
    primaryApplicantCustomerProfile;
    primaryApplicantId;
    typeOfAddress;
    typeOfAddressOptions = [];
    designationPicklistOptions = [];
    addressOfBusiness;
    detailsOfCompany;
    addressOfCompany;
    anyOtherAssetDetails;
    detailsOfOtherOwnedProperty;
    stabilityInYears;
    loanAmountRequired;
    propertyRegisteredOnName;
    endUseOfFund;
    bankingDetails;
    additionalNote;
    businessVintage;
    natureOfBusiness;
    @track spinner = false;

    isUploadModalOpen = false;
    isLoadingDocs = false;
    docRows = [];
    acceptedFormats = ['.pdf', '.jpg', '.jpeg', '.png'];
    isHLRelated = false;

    get hasDocs() {
        return Array.isArray(this.docRows) && this.docRows.length > 0;
    }

    get showTypeOfEntity() {
        return !!(this.typeOfEntity && String(this.typeOfEntity).trim().length);
    }

    @wire(getObjectInfo, { objectApiName: APPLICATION_VERIFICATION_OBJECT })
    objectInfo(result) {
        this.wiredResult = result;

        if (result.data) {
            const rtMap = result.data.recordTypeInfos;
            for (let key in rtMap) {
                if (rtMap[key].name === 'Personal Discussion AHL') {
                    this.referenceRecordTypeId = key;
                    console.log('ref recordtype>', this.referenceRecordTypeId);
                    break;
                }
            }
        }
    }

    get effectiveRtId() {
        return this.referenceRecordTypeId || this.wiredResult?.data?.defaultRecordTypeId || null;
    }

    @wire(CurrentPageReference)
    wiredPageRef(pageref) {
        console.log('pageRef', pageref);

        if (pageref) {
            const state = pageref.state;
            console.log('state:', JSON.stringify(state));
            this.recordId = state.c__recordId;
            this.appVerifId = pageref.state.appVerifId;
            console.log('recordId>', this.recordId);
            console.log('appVerifId>', this.appVerifId);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: "$effectiveRtId",
        fieldApiName: DESIGNATION_FIELD
    })
    designationOptionsWire({ data, error }) {
        if (data) {
            console.log('Designation Picklist', JSON.stringify(data.values));
            this.designationPicklistOptions = data.values.map(option => {
                return { label: option.label, value: option.value };
            });
        } else if (error) {
            console.error('Error fetching picklist values:', error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$effectiveRtId',
        fieldApiName: TYPE_OF_ADDRESS_FIELD
    })
    typeOfAddressOptionsWire({ data, error }) {
        if (data) {
            this.typeOfAddressOptions = data.values.map(o => ({ label: o.label, value: o.value }));
            console.log('Type_of_Address options:', JSON.stringify(this.typeOfAddressOptions));
        } else if (error) {
            console.error('Type_of_Address__c picklist error:', JSON.stringify(error));
        }
    }

    connectedCallback() {
        this.fetchProducDetails();
        console.log('recordId in CN>', this.recordId);
        console.log('appVerifId in CN>', this.appVerifId);

        if (this.recordId != undefined && this.appVerifId != undefined) {
            const url = new URL(window.location.href);
            url.searchParams.set('c__recordId', this.recordId);
            url.searchParams.set('c__appVerifId', this.appVerifId);
            window.history.replaceState({}, '', url.toString());
        }
        console.log('Updated URL:', window.location.href);
        this.getApplicantAndLoanDetails();
        getPicklistValuesForDisposition()
            .then((result) => {
                this.picklistValuesDisposition = result.map(val => ({
                    label: val,
                    value: val
                }));
            })
            .catch((error) => {
                this.error = error;
                console.error('Error fetching picklist values', JSON.stringify(error));
            });
    }

    get dispositionOptionsForTele() {
        return this.picklistValuesDisposition;
    }

    getApplicantAndLoanDetails() {
        if (this.recordId === undefined || this.appVerifId === undefined) {
            const url = new URL(window.location.href);
            this.recordId = url.searchParams.get('c__recordId');
            this.appVerifId = url.searchParams.get('c__appVerifId');
        }
        getApplicantsAndLoanData({
            loanAppId: this.recordId,
            avId: this.appVerifId
        })
            .then((response) => {
                console.log("customer details=:" + JSON.stringify(response));
                this.applicantAndLoanDetails = response;
                const verificationRecords = this.applicantAndLoanDetails.avDetails;

                // Group by RecordType.Name
                this.verificationByRecordType = verificationRecords.reduce((acc, record) => {
                    const recordTypeName = record.RecordType?.Name;
                    if (recordTypeName) {
                        if (!acc[recordTypeName]) {
                            acc[recordTypeName] = [];
                        }
                        acc[recordTypeName].push(record);
                    }
                    return acc;
                }, {});
                console.log('verificationByRecordType', JSON.stringify(this.verificationByRecordType));

                this.tradeRefOnLoad = this.verificationByRecordType['Trade Reference'];
                this.tradeReferenceList = this.verificationByRecordType['Trade Reference'];
                this.showRefTable = this.tradeReferenceList && this.tradeReferenceList.length > 0;
                console.log('tradeReferenceList', JSON.stringify(this.tradeReferenceList));

                this.assetOnLoad = this.verificationByRecordType['Asset'];
                this.showAssetTable = this.assetOnLoad && this.assetOnLoad.length > 0;
                console.log('assetOnLoad', JSON.stringify(this.assetOnLoad));

                this.childrenOnLoad = this.verificationByRecordType['Children Details'];
                this.showChildrenTable = this.childrenOnLoad && this.childrenOnLoad.length > 0;
                console.log('childrenOnLoad', JSON.stringify(this.childrenOnLoad));

                const primaryApplicant = this.applicantAndLoanDetails.applicantList.find(
                    applicant => applicant.Applicant_Type__c === 'Primary Applicant'
                );
                this.primaryApplicantName = primaryApplicant ? primaryApplicant.Name : '';
                const primaryBT = primaryApplicant?.Business_Type__c && String(primaryApplicant.Business_Type__c).trim();
                this.primaryApplicantId = primaryApplicant ? primaryApplicant.Id : null;
                this.primaryApplicantCustomerProfile = primaryApplicant?.Customer_Profile__c || '';
                console.log('PrimaryApplicant BT:', primaryApplicant?.Business_Type__c);

                const coApplicants = this.applicantAndLoanDetails.applicantList.filter(
                    applicant => applicant.Applicant_Type__c === 'Co Applicant'
                );
                this.coApplicantList = coApplicants.map((applicant, index) => {
                    return {
                        label: `Co Applicant ${index + 1}`,
                        value: applicant.Name
                    };
                });
                console.log('coApplicantList: ' + JSON.stringify(this.coApplicantList));

                // ---- Find the correct PD record by Id (NOT by index) ----
                const avForForm =
                    (this.applicantAndLoanDetails?.avDetails || []).find(r => r.Id === this.appVerifId) ||
                    this.applicantAndLoanDetails?.avDetails?.[0];

                if (!avForForm) {
                    console.warn('No matching Application Verification record found for appVerifId:', this.appVerifId);
                    return;
                }

                // Type of Entity resolution (unchanged logic, just sourced from avForForm)
                const typeFromThisAV = avForForm?.Applicant__r?.Business_Type__c;
                const typeFromAnyAV = (this.applicantAndLoanDetails?.avDetails || [])
                    .map(r => r?.Applicant__r?.Business_Type__c)
                    .find(v => v && String(v).trim().length > 0);

                this.typeOfEntity =
                    (primaryBT) ||
                    (typeFromThisAV && String(typeFromThisAV).trim()) ||
                    (typeFromAnyAV && String(typeFromAnyAV).trim()) ||
                    '';

                // ---- All field bindings now read from avForForm (the correct PD record) ----
                this.typeOfAddress                  = avForForm.Type_of_Address__c || '';
                this.designationS                   = avForForm.Designation__c || '';
                this.natureOfBusiness               = avForForm.Nature_Sector_of_Business__c;
                this.businessVintage                = avForForm.Vintage_of_Company__c;
                this.familyDetails                  = avForForm.Family_Details__c;
                this.additionalFamilyDetails        = avForForm.Additional_Family_Details__c;
                this.otherAddresses                 = avForForm.Other_Addresses__c;
                this.interviewerName                = avForForm.Interviewer_Name__c;
                this.interviewComment               = avForForm.Interviewer_Comments__c;
                this.employees                      = avForForm.Employees__c;
                this.detailsOfPreviousOrganisation  = avForForm.Details_of_previous_organisation__c;
                this.ocrDetails                     = avForForm.OCR_Details__c;
                this.marketValue                    = avForForm.Market_Value__c;
                this.registryValue                  = avForForm.Registry_Value__c;
                this.additionalDetail1              = avForForm.Additional_Details_1__c;
                this.additionalDetail2              = avForForm.Additional_Details_2__c;
                this.strength                       = avForForm.Strength__c;
                this.concerns                       = avForForm.Concerns__c;
                this.comments                       = avForForm.Comments__c;
                this.dispositionValue               = avForForm.Crime_Check_Status__c;
                this.addressOfBusiness              = avForForm.Address_of_Business_Employment__c;
                this.dateOfCommencement             = avForForm.Date_of_Commencement_of_Business__c;
                this.detailsOfCompany               = avForForm.Details_of_Company__c;
                this.addressOfCompany               = avForForm.Address_of_Company__c;
                this.anyOtherAssetDetails           = avForForm.Any_Other_Asset_Details__c;
                this.detailsOfOtherOwnedProperty    = avForForm.Details_of_Other_Owned_Property__c;
                this.stabilityInYears               = avForForm.Stability_in_years__c;
                this.annualIncome                   = avForForm.Annual_Income__c;
                this.remainingAgeOfRetirement       = avForForm.Remaining_Age_of_Retirement__c;
                this.loanAmountRequired             = avForForm.Loan_Amount_Required__c;
                this.endUseOfFund                   = avForForm.End_use_of_fund__c;
                this.propertyRegisteredOnName       = avForForm.Property_Registered_On_Name__c;
                this.natureOfBusinessDetails        = avForForm.Nature_of_Business_Details__c;
                this.ownershipOfBusiness            = avForForm.Ownership_of_business__c;
                this.proofOfBusiness                = avForForm.Proof_of_Business__c;
                this.bankingDetails                 = avForForm.Banking_Details__c;
                this.additionalNote                 = avForForm.Additional_Note__c;
            })
            .catch((error) => {
                console.log("error details=:" + JSON.stringify(error));
            });
    }

    closeTabHandler() {
        console.log('closeTabHandler called');
        console.log('isConsoleNavigation:', this.isConsoleNavigation);
        window.location.replace('/lightning/o/Opportunity/list?filterName=Recent');
        getEnclosingTabId()
            .then((tabId) => {
                console.log('Enclosing Tab ID:', tabId);
                closeTab(tabId);
            })
            .catch(error => {
                console.log('Error occurred while closing tabs:', error);
            });
    }

    formData = {};

    handleOnChange(event) {
        const field = event.target.dataset.id;
        const value = event.target.value;
        this.formData[field] = value;
        console.log('formData:', this.formData);
    }

    async handleSave() {
        if (this.isHLRelated && !this.formData['Type_of_Address__c'] && !this.typeOfAddress) {
            this.showToastMessage('Error', 'Type of address is required', 'error');
            return;
        }
        this.spinner = true;
        console.log('handleSave called');
        try {
            await this.handleCreateRecords();
            const fields = {
                Id: this.appVerifId,
                ...this.formData
            };

            const recordInput = { fields };
            console.log('recordInput:', JSON.stringify(recordInput));
            console.log('fields to save:', JSON.stringify(fields));

            await updateRecord(recordInput);
            console.log('Record updated successfully!');
            // Clear local edits so re-render reflects the saved server values
            this.formData = {};
            await this.getApplicantAndLoanDetails();
            await this.sleep(800);
            this.showToastMessage('Success', 'Record updated successfully!', 'success');
        }
        catch (error) {
            console.error('Error in handleSave:', JSON.stringify(error));
            const errorMessage = error?.body?.message || error?.message || 'An unexpected error occurred while saving.';
            this.showToastMessage('Error', errorMessage, 'error');
        }
        finally {
            this.spinner = false;
        }
    }

    sleep(ms) { return new Promise(res => setTimeout(res, ms)); }

    addRow(event) {
        event.target.dataset.id === 'TradeReference' ?
            this.showRefTable = true : event.target.dataset.id === 'Asset' ?
                this.showAssetTable = true : event.target.dataset.id === 'Children' ?
                    this.showChildrenTable = true : this.showChildrenTable = false;
        this.sectionName = event.target.dataset.id;
        console.log('event.target.dataset.id:', event.target.dataset.id);
        console.log('showRefTable:', this.showRefTable);
        console.log('showAssetTable:', this.showAssetTable);
        console.log('showChildrenTable:', this.showChildrenTable);
        if (this.sectionName == 'TradeReference') {
            this.showRefTable = true;
            this.refs.tradeRef.handleAddRow(this.sectionName);
        }
        if (this.sectionName == 'Asset') {
            this.showAssetTable = true;
            this.refs.asset.handleAddRow(this.sectionName);
        }
        if (this.sectionName == 'Children') {
            this.showChildrenTable = true;
            this.refs.children.handleAddRow(this.sectionName);
        }
        console.log('sectionName:', this.sectionName);
    }

    async handleCreateRecords() {
        this.spinner = true;
        try {
            let tradeReferenceList = [];
            let assetList = [];
            let childrenList = [];
            if (this.refs.tradeRef != null && this.refs.tradeRef != undefined) {
                tradeReferenceList = this.refs.tradeRef.pdChildDetailsList();
                console.log('tradeReferenceList:', JSON.stringify(tradeReferenceList));
            }
            if (this.refs.asset != null && this.refs.asset != undefined) {
                assetList = this.refs.asset.pdChildDetailsList();
                console.log('assetList:', JSON.stringify(assetList));
            }
            if (this.refs.children != null && this.refs.children != undefined) {
                childrenList = this.refs.children.pdChildDetailsList();
                console.log('childrenList:', JSON.stringify(childrenList));
            }
            const finalListToInsert = [...tradeReferenceList, ...assetList, ...childrenList];
            console.log('finalListToInsert:', JSON.stringify(finalListToInsert));
            await insertRefData({ pdDetailsList: finalListToInsert })
                .then(() => {
                    console.log('Inserted with RT');
                })
                .catch(error => {
                    console.error('Error:', JSON.stringify(error));
                });
            await this.getApplicantAndLoanDetails?.();
            await this.sleep(800);
        }
        catch (error) {
            console.error('Error in handleCreateRecords:', (error));
        }
        finally {
            this.spinner = false;
        }
    }

    showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: type,
        });
        this.dispatchEvent(toastEvent);
    }

    handleRowDeleted() {
        this.getApplicantAndLoanDetails();
    }

    handleOpenUploadModal() {
        this.isUploadModalOpen = true;
        this.fetchDocs();
    }

    handleCloseUploadModal() {
        this.isUploadModalOpen = false;
    }

    fetchDocs() {
        this.isLoadingDocs = true;

        getAVDocs({ avId: this.appVerifId })
            .then(rows => {
                this.docRows = (rows || []).map(r => {
                    const hasFile = !!r.contentDocumentId;

                    return {
                        ...r,
                        showUpload: !hasFile,
                        showView: hasFile,
                        showDelete: hasFile,
                        showRetake: hasFile,
                        requiredClass: r.required ? 'slds-badge slds-theme_success' : 'slds-badge',
                        requiredLabel: r.required ? 'Required' : 'Optional',
                        statusClass:
                            r.status === 'Uploaded' ? 'slds-badge slds-theme_success' :
                                r.status === 'Pending' ? 'slds-badge' : 'slds-badge slds-theme_warning',
                        showPreview: hasFile,
                        docDetailId: r.docDetailId,
                        documentName: r.documentName,
                        contentDocumentId: r.contentDocumentId,
                        fileType: (r.fileType || '').toUpperCase()
                    };
                });
            })
            .catch(err => this.showError('Error loading documents', err))
            .finally(() => { this.isLoadingDocs = false; });
    }

    handleUploadSuccess() {
        this.fetchDocs();
    }

    async handlePreview(event) {
        const docDetailId = event.currentTarget.dataset.docDetailId;
        if (!docDetailId) return;

        try {
            const latest = await getLatestDocumentDetails({ docDetailId });
            if (!latest || !latest.contentDocumentId) {
                this.showError('Preview unavailable', 'No file attached to this document.');
                return;
            }
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: { pageName: 'filePreview' },
                state: { selectedRecordId: latest.contentDocumentId }
            });
        } catch (err) {
            this.showError('Preview failed', err);
        }
    }

    safeMessage(err) {
        if (typeof err === 'string') return err;
        return err?.body?.message || err?.message || 'Unexpected error';
    }

    showError(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message: this.safeMessage(message), variant: 'error' })
        );
    }

    handleUploadFinished(event) {
        const docDetailId = event.target.dataset.docDetailId;
        const files = event.detail?.files || [];
        if (!files.length) return;

        const contentDocumentId = files[0].documentId;

        this.docRows = (this.docRows || []).map(d =>
            d.docDetailId === docDetailId
                ? { ...d, status: 'Uploaded', contentDocumentId, showPreview: true }
                : d
        );

        upsertDocDetailContentId({ docDetailId, contentDocumentId, unlinkOld: true })
            .then(() => this.fetchDocs())
            .catch(err => this.showError('Could not save file to document', err));
    }

    get documentList() {
        return (this.docRows || []).map(r => ({
            id: r.docDetailId,
            name: r.documentName,
            docName: r.documentName,
            isRequired: !!r.required,
            titleClass: r.required ? 'doc-title required' : 'doc-title',
            contentId: r.contentDocumentId || null,
            showUpload: r.showUpload,
            showView: r.showView,
            showDelete: r.showDelete,
            showRetake: r.showRetake,
            showLatLong: false,
            lattitude: r.lattitude,
            longitude: r.longitude,
            fileType: r.fileType
        }));
    }

    handleNewDocNameChange(e) {
        this.newDocName = e.target.value?.trim();
    }

    handleAddDocument() {
        if (!this.newDocName) return;
        createDocDetailForAV({
            avId: this.appVerifId,
            docName: this.newDocName,
            isRequired: false
        })
            .then(() => {
                this.newDocName = '';
                this.fetchDocs();
                this.showToast('Success', 'Document added.', 'success');
            })
            .catch(err => this.showError('Could not add document', err));
    }

    handleDeletedDoc(event) {
        const deletedId = event.detail?.docDetailId || event.detail?.docId;
        if (!deletedId) return;
        this.docRows = (this.docRows || []).filter(r => r.docDetailId !== deletedId);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    fetchProducDetails() {
        var inputMapParam = {
            'oppId': this.recordId
        };
        console.log('recordid----' + this.recordId);
        getProductDetails({ inputMap: inputMapParam })
            .then(result => {
                console.log('result product: ' + JSON.stringify(result));
                this.isHLRelated = result.isHLRelated;
            })
            .catch(error => {
                console.error('error in getting product: ' + JSON.stringify(error));
            });
    }
}