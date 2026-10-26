import { LightningElement, api } from 'lwc';
import getRecordList from '@salesforce/apex/ShowRecordTableController.getRecordList';

export default class ShowRecordTable extends LightningElement {

    @api recordId;
    @api processName;
    @api filter = '';                   //to add some filter criteria to soql
    @api showHeaderFooter = false;
    @api headerText = '';
    @api theme = 'light';                //visual theme only ('light' default, 'dark' for modern dark hosts like recordAssignmentV2 — no functional impact
    
    headerColumns=[];
    recordList=[];
    showNoRecords = false;
    cssContainer = '';
    cssMain = '';

    connectedCallback() {
    
        //testing data -----------------------
        // if(!this.recordId){
        //     this.recordId = '00QBi00000Cbo2CMAR';
        //     this.processName = 'Linked Lead';
        //     this.showHeaderFooter = true;
        //     this.headerText = 'Header Title';
        // }
        //-------------------------
        //console.log('recordId '+this.recordId);

        const containerClasses = ['table-scroll-container'];

        if(this.showHeaderFooter == true){
            this.cssMain = 'border-field';
            containerClasses.push('slds-modal__content', 'slds-p-around_medium');
        }
        else{
            this.showHeaderFooter = false;
        }

        if(this.theme === 'dark') {
            containerClasses.push('theme-dark');
        }
        else if(this.theme === 'skyblue') {
            containerClasses.push('theme-skyblue');
        }

        this.cssContainer = containerClasses.join(' ');

        this.getRecordDetails();
    }

    @api reloadDetails(param) {
        this.recordId = param;

        this.getRecordDetails();
    }

    @api getRecordDetails(){
    
        console.log('recordId  49'+this.recordId);
        console.log('processName 51 '+this.processName);
 console.log('this.filter '+this.filter);

        if(this.recordId && this.processName){

            getRecordList({ recordId: this.recordId, processName: this.processName, filter: this.filter })
            .then(result => {
                console.log('recordList:57 ', JSON.stringify(result));
                if(result && result.recordList && result.recordList.length >0){
                    console.log('recordList: ', JSON.stringify(result));

                    this.recordList = result.recordList;
                    this.headerColumns = result.headerColumns;
                    this.showNoRecords = false;
                }
                else{
                    this.showNoRecords = true;
                }
            })
            .catch(error => {
                this.showNoRecords = true;
                console.error('Error fetching record details:', error);
            });
        }
        else{
            this.showNoRecords = true;
            console.error('recordId or processName missing');
        }
    }

    handleRadioSelect(event) {
        console.log('radio Id: '+ event.target.dataset.id);

        this.dispatchEvent(new CustomEvent('tableselectedid', { detail: event.target.dataset.id }));
    }

    handleCheckboxChange(event){
        console.log('checkbox name: '+ event.target.dataset.name);

        const isChecked = event.target.checked;
        var selectedIds = [];

        if(event.target.dataset.name == 'mainToggle') {

            const toggleList = this.template.querySelectorAll('[data-name="toggle"]');
            toggleList.forEach(toggleElement => {
                toggleElement.checked = isChecked;
                selectedIds.push(toggleElement.dataset.id);
            });
        }
        else {
            console.log('checkbox Id: '+ event.target.dataset.id);

            if(!isChecked){
                var mainCheckbox = this.template.querySelectorAll('[data-name="mainToggle"]');
                if(mainCheckbox.length >0) {
                    mainCheckbox[0].checked = isChecked;
                }
            }

            selectedIds = [];
            const toggleList = this.template.querySelectorAll('[data-name="toggle"]');
            toggleList.forEach(toggleElement => {
                if(toggleElement.checked) {
                    selectedIds.push(toggleElement.dataset.id);
                }
            });
        }

        console.log('selectedIds: '+selectedIds);
        this.dispatchEvent(new CustomEvent('tableselectedid', { detail: { selectedIds } }));
    }
}