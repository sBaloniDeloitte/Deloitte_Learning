import { LightningElement, api, track } from 'lwc';
import searchBankBranches from '@salesforce/apex/SearchLookupController.searchBankBranches';
import updateIFSCCode from '@salesforce/apex/SearchLookupController.updateIFSCCode';
import fetchIFSCCode from '@salesforce/apex/SearchLookupController.fetchIFSCCode';
import { updateRecord } from 'lightning/uiRecordApi';
export default class CustomIfscSearchLookup extends LightningElement {
    @api label = 'Bank Branch';
    @api placeholder = 'Search Bank Branch by IFSC';
    @api disabled = false;
    @api selectedRecordId;
    @track searchKey = '';
    @track records = [];
    @track showRecords = false;
    connectedCallback () {
        // if (this.selectedRecordId) {
            console.log('selectedRecord for ifsc : '+this.selectedRecordId);
            fetchIFSCCode({bankId : this.selectedRecordId})
            .then((result) => {
                console.log('updateIFSCCode Sucess : '+result);
                if(result != 'Not Found') {
                    this.searchKey = result;
                }
            })
            .catch(error => {
                console.error('Error in updateIFSCCode:', error);
            });

        // }
    }
    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
        if (!this.searchKey) {
            // input cleared
            this.handleRemovePill();
        }
        if (this.searchKey.length >= 2) {
            searchBankBranches({ searchTerm: this.searchKey })
                .then(result => {
                    this.records = result;
                    this.showRecords = true;
                    setTimeout(() => {
                        const input = this.template.querySelector('lightning-input');
                        const dropdown = this.template.querySelector('.floating-dropdown');

                        if (input && dropdown) {
                            const rect = input.getBoundingClientRect();

                            dropdown.style.top = rect.bottom + 'px';
                            dropdown.style.left = rect.left + 'px';
                            dropdown.style.width = rect.width + 'px';
                        }
                    }, 0);
                })
                .catch(error => {
                    console.error('Error in search:', error);
                    this.records = [];
                    this.showRecords = false;
                });
        } else {
            this.records = [];
            this.showRecords = false;
        }
    }

    handleSelect(event) {
        const selectedId = event.currentTarget.dataset.id;
        const selectedRecord = this.records.find(r => r.Id === selectedId);
        console.log('selectedRecord-----',JSON.stringify(selectedRecord));
        this.searchKey = selectedRecord.IFSC__c;
        this.showRecords = false;
        this.dispatchEvent(new CustomEvent('lookupselected', {
            detail: { record: selectedRecord,bankid:this.selectedRecordId}
        }));
        this.records = [];
        updateIFSCCode({bankId : this.selectedRecordId, ifscCode : selectedRecord.IFSC__c,branchId:selectedRecord.Id})
        .then(() => {
            console.log('updateIFSCCode Sucess : ');
        })
        .catch(error => {
            console.error('Error in updateIFSCCode:', error);
        });
    }
    handleRemovePill(event){
        console.log('inside removal');
        let fields = {};
        fields['Id'] = this.selectedRecordId;
        fields['Bank_Master__c'] = null;
        const recordInput = { fields };
        updateRecord(recordInput)
        .then(resp=>{
            this.searchKey = null;
        }).catch(error=>{
            
        })
    }
}