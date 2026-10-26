import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getUserHierarchy from '@salesforce/apex/WaiverController.getUserHierarchy';
import getLoggedInUser from '@salesforce/apex/WaiverController.getLoggedInUser';
import saveWaiver from '@salesforce/apex/WaiverController.saveWaiver';
import searchLegalRecords from '@salesforce/apex/WaiverController.searchLegalRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getWaiverDetail from '@salesforce/apex/WaiverController.getWaiverDetail';  //Added on 10-11-2025

export default class WaiverCreate extends LightningElement {
    @track waiverFor = 'Legal';
    @track waiverBy;
    @track waiverFrom;
    @track remarks;
    @track latestRemarks;
    @api recordId;

    @track waiverForOptions = [{ label: 'Legal', value: 'Legal' }];
    @track waiverFromOptions = [];

    // Lookup-related
    @track searchOptions = []; // { label, value }
    @track searchKey = '';
    @track selectedRecordId = null;
    @track selectedRecordLabel = '';
    @track showDropdown = false;
    @track isSaving = false;
    waiverByOptions = [];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log(' currentPageReference.state : ', currentPageReference);
            this.recordId = currentPageReference.attributes.recordId;
        }
    }

    debounceTimer;

    // computed display value shown inside the single input
    get displayValue() {
        return this.selectedRecordLabel || this.searchKey || '';
    }

    get noResults() {
        return (this.searchKey && this.searchOptions.length === 0);
    }

    //Modified on 10-11-2025
    async connectedCallback() {
        this.loadUserDetails();
        await this.loadLegalRecords();
    }

    async loadUserDetails() {
        try {
            const user = await getLoggedInUser();
            this.waiverBy = user.Name;
            const hierarchyUsers = await getUserHierarchy({ requestedBy: this.waiverBy, loanAppId: this.recordId });
            this.waiverFromOptions = hierarchyUsers.map(u => ({ label: u, value: u }));
            this.waiverByOptions = [
                {
                    label: user.Name,
                    value: user.Name
                }
            ];
        } catch (error) {
            console.error('Error loading user hierarchy:', error);
        }
    }

    async handleChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
        console.log('OUTPUT : ',event.target.name,event.target.value);
    }

    onLookupInput(event) {
        // user typed - clear selected record if user edits
        const val = event.target.value;
        if (this.selectedRecordId) {
            // If user changes input after selection, clear the existing selection
            this.selectedRecordId = null;
            this.selectedRecordLabel = '';
        }
        this.searchKey = val;
        this.showDropdown = true;
        this.debounceSearch();
    }

    onLookupFocus() {
        // show dropdown when focusing (if there is a searchKey)
        if (this.searchKey && this.searchKey.length >= 1) {
            this.showDropdown = true;
            this.debounceSearch();
        }
    }

    onLookupBlur() {
        // small delay to allow click on dropdown items before hiding
        setTimeout(() => {
            this.showDropdown = false;
        }, 200);
    }

    preventBlur(event) {
        // prevent blur when clicking inside dropdown (mousedown)
        event.preventDefault();
    }

    debounceSearch() {
        if (this.debounceTimer) clearTimeout(this.debounceTimer);
        // wait 300ms after typing stops
        this.debounceTimer = setTimeout(() => {
            this.performSearch();
        }, 300);
    }

    async performSearch() {
        const key = this.searchKey;
        if (!key || key.length < 1) {
            this.searchOptions = [];
            return;
        }
        try {
            const res = await searchLegalRecords({ searchTerm: key, loanAppId: this.recordId });
            this.searchOptions = res.map(r => ({ label: r.Name, value: r.Id }));
        } catch (err) {
            console.error('Search error', err);
            this.searchOptions = [];
        }
    }

    selectRecord(event) {
        const id = event.currentTarget.dataset.id;
        const option = this.searchOptions.find(o => o.value === id);
        if (option) {
            this.selectedRecordId = option.value;
            this.selectedRecordLabel = option.label;
            this.searchKey = '';
            this.searchOptions = [];
            this.showDropdown = false;
        }
    }

    clearSelection() {
        this.selectedRecordId = null;
        this.selectedRecordLabel = '';
        this.searchKey = '';
        this.searchOptions = [];
    }

    async handleSubmit() {
        this.isSaving = true;
        try {
            const waiverRecord = {
                Waiver_Requested_For__c: this.waiverFor,
                Waiver_Requested_By__c: this.waiverBy,
                Waiver_Requested_From__c: this.waiverFrom,
                Remarks__c: this.remarks,
              /*  Latest_Remarks_History__c: this.latestRemarks, */
                Loan_Application__c: this.recordId,
                Status__c: 'Submitted',
                // pass selected Legal Id (null if creating new)
                Search_Report__c: this.selectedRecordId
            };

            await saveWaiver({ waiver: waiverRecord, recordId:this.recordId  });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Waiver submitted successfully!',
                    variant: 'success'
                })
            );

            this.handleCancel();
        } catch (error) {
            console.error('Error saving waiver:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: (error?.body?.message) || 'An error occurred while saving the waiver.',
                    variant: 'error'
                })
            );
        } finally {
            this.isSaving = false;
        }

        this.loadUserDetails();
        await this.loadLegalRecords();
    }

    handleCancel() {
        this.waiverFor = null;
        this.searchKey = '';
        this.selectedRecordId = null;
        this.selectedRecordLabel = '';
        this.waiverFrom = null;
        this.remarks = '';
        this.latestRemarks = '';
        this.searchOptions = [];
        this.showDropdown = false;
    }

    //Added on 10-11-2025

    handleSearchChange(event) {
        this.selectedRecordId = event.target.value;
        const selectedOption = this.searchOptions.find(opt => opt.value === this.selectedRecordId);
        this.selectedRecordLabel = selectedOption ? selectedOption.label : '';
        // this.handleViewRemarks();
         getWaiverDetail({waiverId: this.selectedRecordId})
        .then(res=>{
            console.log('res ',res);
            if(res) {
                
                this.isShowHistoryField = true;
            }else {
                this.isShowHistoryField = false;
            }
        }).catch(error=>{
            console.log('Error ',error);
        })
    }

    async loadLegalRecords() {
        try {
            const res = await searchLegalRecords({ searchTerm: '', loanAppId: this.recordId });
            console.log('res ',res);
            this.searchOptions = res.map(r => ({ label: r.Name, value: r.Id }));
        } catch (error) {
            console.error('Error loading legal records:', error);
        }
    }
    isOpenWaiver = false;
    waiverName = '';
    isShowHistoryField = false;
    handleViewRemarks(event) {
        console.log('event.target',event.target.label);
        getWaiverDetail({waiverId: this.selectedRecordId})
        .then(res=>{
            if(res) {
                console.log('res.......... ',res);
                console.log('remarksd ',res.Remarks__c);
                this.isOpenWaiver = true;
                this.waiverName = res.Remarks__c;
            }
        }).catch(error=>{
            console.log('Error ',error);
        })

    }

    hideModalBox() {
        this.isOpenWaiver = false;
    }

}