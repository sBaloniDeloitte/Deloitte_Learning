import updateEligibilityAmount from '@salesforce/apex/HL_directorRenumaration.updateEligibilityAmount';
import getEligibilityAmount from '@salesforce/apex/HL_directorRenumaration.getEligibilityAmount';
import { LightningElement, api, track, wire } from 'lwc';
import checkCustomerType from '@salesforce/apex/HL_directorRenumaration.checkCustomerType';
import fetchdirectorList from '@salesforce/apex/HL_directorRenumaration.fetchDirectors';
import createorCheckAlreadyCreated from '@salesforce/apex/HL_directorRenumaration.createorCheckAlreadyCreated';
import fetchChildrows from '@salesforce/apex/HL_directorRenumaration.fetchChildrows';
import addRow from '@salesforce/apex/HL_directorRenumaration.addRow';
import fetchTotal from '@salesforce/apex/HL_directorRenumaration.fetchTotals';
import fetchAverages from '@salesforce/apex/HL_directorRenumaration.fetchAverages';
import fetchTotalAfterDeleting from '@salesforce/apex/HL_directorRenumaration.fetchTotalAfterDeleting';
import deleteMonth from '@salesforce/apex/HL_directorRenumaration.deleteHighestMonth';
import checkandUpdateTotal from '@salesforce/apex/HL_directorRenumaration.checkandUpdateTotal';
import { NavigationMixin } from "lightning/navigation";
import { updateRecord } from "lightning/uiRecordApi";
import updateMonthNameChildrows from '@salesforce/apex/HL_directorRenumaration.updateMonthNameChildrows';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class HlDirectorRenumeration extends NavigationMixin(LightningElement) {

    @api recordId;
    @track showcomp = false;
    @track directorNames;
    @track rows;
    @track totalRowKey = 'totalRow1';
    @track totals;
    @track averages;
    showTotal = false;
    showAverage = true;
    @track isLoading = false;
    @track eligibilityData;
    @track showEligibility = false;
    @track averageAmount;
    @track columnCount
    @api connectedCallback() {
        this.showcomp = false;
        console.log('recordId', this.recordId);
                    fetchdirectorList({ recordId: this.recordId })
                        .then(result => {
                            console.log('directorNames : ', result);
                            this.directorNames = result;
                            if(this.directorNames.length>0){
                            this.showcomp = true;
                            fetchChildrows({ recordId: this.recordId })
                                .then(result => {
                                    console.log('rows : ', result);
                                    console.log('rows json: ', JSON.stringify(result));
                                    this.rows = result;
                                    fetchTotal({ recordId: this.recordId })
                                        .then(result => {
                                            console.log('totals : ', JSON.stringify(result));
                                            this.totals = result;
                                            this.columnCount = this.totals.length;
                                            this.showTotal = true;
                                            this.showAverage = true;
                                            this.calculateAverageSalary(this.recordId);
                                        })
                                    fetchAverages({ recordId: this.recordId })
                                        .then(result => {
                                            this.averages = result;
                                            console.log('average: ' + JSON.stringify(this.averages));

                                            this.showAverage = true;
                                        });
                                })  
                }
                else {
                    this.showcomp = false;
                }
            })
        getEligibilityAmount({ recordId: this.recordId })
            .then(result => {
                this.eligibilityData = result;
                console.log('eligibility amount: ' + JSON.stringify(this.eligibilityData));
                this.showEligibility = true;
            })
            .catch(error => {
                console.log('Error fetching eligibility data:', error);
            });
    }

    calculateAverageSalary() {
        if (!this.totals || this.totals.length === 0) {
            this.averageAmount = 0;
            return;
        }

        let sum = 0;

        for (const total of this.totals) {
            if (typeof total.totalSalary === 'number') {
                sum += total.totalSalary;
            }
        }

        this.averageAmount = sum / this.totals.length;
    }

    handleInputChangeAmount(event) {
        const recordId = event.target.dataset.recordid;
        const newAmount = event.target.value;

        updateEligibilityAmount({ recordId, newAmount })
            .then(() => {
                console.log(`Updated record ${recordId} with amount ${newAmount}`);
            })
            .catch(error => {
                console.error('Error updating eligibility amount:', error);
            });
    }


    addRow(event) {
        console.log('47 : ');
        addRow({ recordId: this.recordId })
            .then(result => {
                console.log('result : ', result);
                fetchChildrows({ recordId: this.recordId })
                    .then(result => {
                        console.log('rows : ', result);
                        this.rows = result;
                    })
            })
    }

    handleInputChangeMonthName(event) {
        console.log('handleInputChangeMonthName: event : '+  event);
        const monthName = event.target.value;
        const month = parseInt(event.target.dataset.id, 10);
        console.log('month : ' + month + ' ::: ' + monthName);
        this.rows = this.rows.map(row =>
            row.month === month ? { ...row, monthName: monthName } : row
        );
        console.log('handleInputChangeMonthName: event : ' + JSON.stringify(this.rows));
    }

    handleSaveMonthName(event) {
        console.log('handleSaveMonthName: event : '+  event);
        const month = parseInt(event.target.dataset.id, 10);
        console.log('handleSaveMonthName : month : ' + month);
    
        const selectedMonth = this.rows.find(row => row.month === month);
        console.log('handleSaveMonthName: event : ' + JSON.stringify(selectedMonth));
        if (selectedMonth) {
            const monthName = selectedMonth.monthName;
            if(!monthName){
                this.showToast('Error', 'Please enter month and year.', 'error');
                return;
            }
            console.log('handleSaveMonthName : monthName : ' + monthName);
            updateMonthNameChildrows({ recordId: this.recordId, monthNumber:month, monthName: monthName})
            .then(() => {
                console.log(`handleSaveMonthName : Updated record ${this.recordId} with monthname ${monthName}`);
                fetchChildrows({ recordId: this.recordId })
                    .then(result => {
                        console.log('rows : ', result);
                        this.rows = result;
                    })
            })
        }
    }
    
    handleInputChange(event) {
        console.log('event : ', event);
        const month = event.target.dataset.month;
        const directorName = event.target.dataset.id;
        const salary = event.target.value;
        const childId = event.target.dataset.childid;
        const previousValue = event.target.dataset.prvalue;
        console.log('month : ', month);
        console.log('directorName : ', directorName);
        console.log('salary : ', salary);
        console.log('childId : ', childId);
        console.log('previousValue : ', previousValue);
        this.updateRecordField(childId, 'Salary_For_Month__c', salary);
        const delta = (parseFloat(salary) || 0) - (parseFloat(previousValue) || 0);
        setTimeout(() => {
            this.totals = this.totals.map(row => {
                if (row.directorName == directorName) {
                    checkandUpdateTotal({ parentId: row.parentId, previousValue: previousValue, salary: salary })
                        .then(result => {
                            row.totalSalary = result;

                        })
                }
                this.calculateAverageSalary();
                fetchAverages({ recordId: this.recordId })
                    .then(result => {
                        this.averages = result;
                        this.showAverage = true;
                    })
                    .catch(error => {
                        console.error('Error fetching averages:', error);
                    });
                return row;
            });
        }, 300);
    }
    updateRecordField(recordId, fieldApiName, fieldValue) {
        console.log('recoedId-----'+recordId);
        console.log('fieldApiName-----'+fieldApiName);
        console.log('fieldValue-----'+fieldValue);
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
                console.log('Error updating record --> ' + JSON.stringify(error));
            })
    }
    handleDeleteRow(event) {
        console.log('event : ', event);
        const month = event.target.dataset.month;
        console.log('month : ', month);
        this.isLoading = true;
        deleteMonth({ recordId: this.recordId })
            .then(result => {
                console.log('result : ', result);
                fetchChildrows({ recordId: this.recordId })
                    .then(result => {
                        console.log('rows : ', result);
                        console.log('rows json: ', JSON.stringify(result));
                        this.rows = result;
                        fetchTotalAfterDeleting({ recordId: this.recordId })
                            .then(result => {
                                console.log('totals : ', result);
                                this.totals = result;
                                this.showTotal = true;
                                this.isLoading = false;
                            })
                        fetchAverages({ recordId: this.recordId }) // ✅ NEW
                            .then(result => {
                                this.averages = result;
                                this.showAverage = true;
                            });
                    })
            })
            .catch(error => {
                console.log('error : ', error);
                this.isLoading = false;
            })
    }
    // renderedCallback() {
    //   // Select all lightning-input elements inside your template
    //   const inputs = this.template.querySelectorAll('lightning-input');

    //   inputs.forEach(input => {
    //     // Set style properties dynamically
    //     input.style.width = '50%';  // width as percentage
    //     input.style.setProperty('--lwc-input-height', '24px');  // height custom property
    //     input.style.fontSize = '0.75rem';

    //     // To center align, wrap the input in a div with text-align:center (easier in HTML)
    //     // Or, alternatively, you can center the input with margin auto:
    //     input.style.display = 'block';
    //     input.style.marginLeft = 'auto';
    //     input.style.marginRight = 'auto';
    //   });
    // }
    @api callConnected(event){
        this.showcomp = false;
        this.connectedCallback();
    }

    handleAdditonalFoirChange(event){
        console.log('Inside value change')
        const parentId=event.target.dataset.parentid;
        const additionalFoir=event.target.value;
        console.log('additionalFoir : ', additionalFoir)
        console.log('parentId : ', parentId)
        console.log('event : ', event)
        console.log('event.target :')
        this.updateRecordField(parentId,'HL_Additional_FOIR__c', additionalFoir);
    }
}