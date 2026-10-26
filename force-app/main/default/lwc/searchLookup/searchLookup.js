import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import searchRecords from '@salesforce/apex/SearchLookupController.getSearchRecords';
import recentRecords from '@salesforce/apex/SearchLookupController.getRecentRecords';
import searchSalesUsersForBranch from '@salesforce/apex/SearchLookupController.searchSalesUsersForBranch';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class SearchLookup extends NavigationMixin(LightningElement) {

    @api label = '';
    @api required = false;
    @api showLabel = false;
    @api fieldLevelHelp = '';
    @api selectedId = '';
    @api selectedName = '';
    @api placeholder = 'Search...';
    @api objectName = '';
    @api searchFields = [];
    @api returnFields = ['Id', 'Name'];
    //@api filterCriteria = '';
    _filterCriteria;
    @api maxResults = 5;
    @api sortColumn = 'CreatedDate';
    @api sortOrder = 'DESC';
    @api disabled = false;
    @api showAddNew = false;
    @api addNewTitle = 'Add new record';
    @api product;
    @api borderLess = false;
    @api opportunityId;
    @api branchLookup;
    @api branchId;
    isRendered = false;
    valueSelected = false;
    searchText = '';
    showProgress = false;
    searchResults = [];
    showResult = false;
    selectedCss = 'slds-input_faux slds-combobox__input';

    connectedCallback(){
        // event.stopPropagation();
        console.log('inside conn call');
        console.log('this.selectedId=:'+this.selectedId);
        console.log('this.selectedName=:'+this.selectedName);
        console.log('filter criteria>'+this._filterCriteria);
        // this.label = 'Pincode';
        // this.showLabel = true;
        // this.placeholder = 'Search pincode';
        // this.objectName = 'Bank_Branch_Master__c';
        // this.filterCriteria = '[recordType.Name= Branch;]';
        // //this.returnFields = ['Id', 'Name', 'Town_and_Post_Office__c', 'Is_Pincode_Servicable__c'];

        if(this.selectedId && this.selectedName) {
            this.valueSelected = true;

            if(this.disabled){
                this.selectedCss = 'slds-input_faux slds-combobox__input slds-is-disabled';
            }
        }

        setTimeout(() => {

            if(this.selectedId && this.selectedName) {
                this.valueSelected = true;
    
                if(this.disabled){
                    this.selectedCss = 'slds-input_faux slds-combobox__input slds-is-disabled';
                }
            }
            
        }, 2000);
    }
    @api
    get filterCriteria(){
        console.log('filterCriteriagetter##'+this._filterCriteria);
        return this._filterCriteria
    }
    set filterCriteria(value) {
        console.log('filterCriteriasetter##'+value);
        this._filterCriteria = value;
         this.getSearchResult();
    }
    handleNewRecord(event) {
        console.log('---add new');

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectName,
                actionName: 'new'
            },
        })
        .then(newRecord => {
            this.getRecentRecord(event);
        })
        .catch(error => {
            console.log('Error creating new record: ' + JSON.stringify(error));
        });
    }

    @api handleReset(event) {
        //console.log('---reset');

        if(this.disabled == false) {
            this.valueSelected = false;
            this.searchText = '';
            this.selectedName = '';
            this.selectedId = '';
            this.dispatchEvent(new CustomEvent('lookupdeselected', {}));
        }
    }

    handleSelect(event) {
        console.log('selectId searchLookup: '+event.currentTarget.dataset.recordid);
        console.log('selectId searchLookup: '+event.currentTarget.dataset.recordname);

        if(event.currentTarget.dataset.recordid == '0') {
            this.selectedName = '';
            this.selectedId = '';
            this.dispatchEvent(new CustomEvent('lookupdeselected', {}));
        }
        else{
            this.selectedName = event.currentTarget.dataset.recordname;
            this.selectedId = event.currentTarget.dataset.recordid;
            this.valueSelected = true;

            var searchRecord;
            this.searchResults.every(result => {
                console.log('---- res '+JSON.stringify(result));

                if(result.id == this.selectedId) {
                    console.log('result.id --> '+result.id);
                    console.log('this.selectedId --> '+this.selectedId);
                    console.log('result.searchRecord --> '+JSON.stringify(result.searchRecord));
                    searchRecord = result.searchRecord;
                     console.log('searchRecord --> '+searchRecord);
                    return false;
                }

                return true;
            });
            setTimeout(() => {
                this.dispatchEvent(new CustomEvent('lookupselected', { detail: { searchRecord } }));
            }, 100);
            
        }
        console.log('selectId searchLookup: 142 '+event.currentTarget.dataset.recordid);
        this.showResult = false;
        console.log('selectId searchLookup:143 '+event.currentTarget.dataset.recordid);
        this.searchResults = [];
        console.log('selectId searchLookup:146 '+event.currentTarget.dataset.recordid);
    }

    handleBlur(event) {
        //console.log('-----Blur '+ event.target.value);
        // event.stopPropagation();
        this.searchText = event.target.value;
        this.showResult = false;
        this.searchResults = [];
    }

    handleFocus(event) {
        //console.log('-----Focus '+ event.target.value);
        // event.stopPropagation();
        this.searchText = event.target.value;

        this.getRecentRecord();
    }

    handleChange(event) {

        // event.stopPropagation();
        if (this.objectName == 'Pincode_Master__c') {

            let inputValue = event.target.value;
            // if ((!/^\d*$/.test(inputValue)) || inputValue.length > 6) {
            //     inputValue = inputValue.slice(0, -1);
            //     this.dispatchEvent(
            //     new ShowToastEvent({
            //         title: 'Error',
            //         message: 'Please enter valid pincode. ',
            //         variant: 'error',
            //     }),
            // );
            // }

            // if (inputValue.length > 6) {
            //     inputValue = inputValue.slice(0, 6);
            // }
            console.log('Change##' + inputValue);
            console.log('objectName##' + this.objectName);
            console.log('inputValue##' + inputValue);

            this.searchText = inputValue;
            event.target.value = inputValue; // Update the input field with the corrected value


        }
        this.searchText = event.target.value;
        console.log('objectName##' + this.objectName);
        if(this.searchText && this.searchText.length >= 3){
            this.getSearchResult(event);
        }
        else{
            this.searchResults = [
                {"iconName": "utility:info", "id": "0", "primaryValue": "No record found!"}
            ];
        }
    }

    getSearchResult(event) {
        console.log('-----this.searchText ' + this.searchText);
        // event.stopPropagation();
        if (this.objectName === 'User' &&  this.branchLookup && this.opportunityId) {
            this.showProgress = true;
            searchSalesUsersForBranch({
                loanId: this.opportunityId,
                searchText: this.searchText,
                maxResults: this.maxResults,
                branchId: this.branchId
            })
                .then(results => {
                    if (results && results.length > 0) {
                        this.searchResults = results;
                        this.showResult = true;
                    } else {
                        this.searchResults = [{ iconName: 'utility:info', id: '0', primaryValue: 'No record found!' }];
                        this.showResult = true;
                    }
                    this.showProgress = false;
                })
                .catch(error => {
                    this.showProgress = false;
                    this.showResult = false;
                    console.error('[Branch User Lookup] error:', JSON.stringify(error));
                });
            return; 
        }
        if(this.objectName && this.searchText) {
            this.showProgress = true;
            console.log('Inside getSearchResult');
            console.log('filter criteria>'+this._filterCriteria);
            console.log('searchFields>'+this.searchFields);
            console.log('returnFields>'+this.returnFields);
            console.log('sortColumn>'+this.sortColumn);
            console.log('searchText>'+this.searchText);
            searchRecords({ objectName: this.objectName, searchText: this.searchText, filterCriteria: this._filterCriteria, searchFields: this.searchFields, returnFields: this.returnFields, sortColumn: this.sortColumn, sortOrder: this.sortOrder, maxResults: this.maxResults })
            .then(results => {
                //console.log('searchRecords: '+JSON.stringify(results));
                
                if(results && results.length > 0){
                    console.log('result found---');

                    this.searchResults = results;
                    this.showResult = true;
                }
                else{
                    console.log('inside else>');
                    this.searchResults = [
                        {"iconName": "utility:info", "id": "0", "primaryValue": "No record found!"}
                    ];
                }

                this.showProgress = false;
            })
            .catch(error => {
                this.showProgress = false;
                this.showResult = false;
                console.log('Error fetching search results: ', JSON.stringify(error));
            })
        }

    }

    getRecentRecord(event) {  
        // event.stopPropagation();
        if (this.objectName === 'User' && this.branchLookup && this.opportunityId) {
            this.showProgress = true;
            searchSalesUsersForBranch({
                loanId: this.opportunityId,
                searchText: '',
                maxResults: this.maxResults,
                branchId: this.branchId
            })
                .then(results => {
                    this.searchResults = (results && results.length)
                        ? results
                        : [{ iconName: 'utility:info', id: '0', primaryValue: 'No record found!' }];
                    this.showResult = true;
                })
                .catch(error => {
                    this.showResult = false;
                    console.error('[Branch User Lookup][recent] error:', JSON.stringify(error));
                })
                .finally(() => { this.showProgress = false; });
            return; 
        }
        if(!this.searchText) {
            this.showProgress = true;
    
            recentRecords({ objectName: this.objectName, filterCriteria: this._filterCriteria, returnFields: this.returnFields, maxResults: this.maxResults })
            .then(results => {
                //console.log('recentRecords: '+JSON.stringify(results));

                if(results && results.length > 0){
                    console.log('result found---');

                    this.searchResults = results;
                    this.showResult = true;
                }

                this.showProgress = false;
            })
            .catch(error => {
                this.showProgress = false;
                this.showResult = false;
                console.error('Error fetching recent results: ', JSON.stringify(error));
            })
        }
    }
    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            const style = document.createElement('style');
            style.innerText = `
       
            /* Hide border and apply bottom border only */
            .hideInput .slds-input {
                border: none !important; /* Remove all default borders */
                border-bottom: 1px solid black !important; /* Add only bottom border */
                background-color: transparent;
                outline: none;
                box-shadow: none;
                border-radius: 0 !important; /* Remove curved edges */
                padding: 5px; /* Adjust padding if necessary */
            }
            .removeborder slds-combobox__input {
                border: none !important;  /* Remove border */
                box-shadow: none !important;  /* Remove any shadow */
                background-color: transparent;  /* Ensure no background color */
                 border-bottom: 1px solid black !important; /* Add only bottom border */
                 border-radius: 0 !important; /* Remove curved edges */
                  padding: 5px;
            }
            .removecombo slds-combobox_container{
                border: none !important;  /* Remove border */
                box-shadow: none !important;  /* Remove any shadow */
                background-color: transparent;  /* Ensure no background color */
                 border-bottom: 1px solid black !important; /* Add only bottom border */
                 border-radius: 0 !important; /* Remove curved edges */
            }
            .hideBox slds-combobox__form-element slds-input-has-icon slds-input-has-icon_right{
                border: none !important;  /* Remove border */
                box-shadow: none !important;  /* Remove any shadow */
                background-color: transparent;  /* Ensure no background color */
                 border-bottom: 1px solid black !important; /* Add only bottom border */
                 border-radius: 0 !important; /* Remove curved edges */
            }
            .hideborder slds-combobox__input{
                border: none !important;  /* Remove border */
                box-shadow: none !important;  /* Remove any shadow */
                background-color: transparent;  /* Ensure no background color */
                 border-bottom: 1px solid black !important; /* Add only bottom border */
                 border-radius: 0 !important; /* Remove curved edges */
                 padding: 5px;
        }
          
            
            `;
            this.template.querySelector('.styleContainer').appendChild(style);
            this.spinnerClass = 'spinner-medium';
        }
    }
}