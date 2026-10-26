import { LightningElement, track, api  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchDirectorDetails from '@salesforce/apex/HL_DirectorDetailsController.fetchDirectorDetails';
import saveDirectorDetails from '@salesforce/apex/HL_DirectorDetailsController.saveDirectorDetails';
import isDirectorDetailsApplicable from '@salesforce/apex/HL_DirectorDetailsController.isDirectorDetailsApplicable';
import deleteDirectorDetails from '@salesforce/apex/HL_DirectorDetailsController.deleteDirectorDetails';
import getPicklistValues from '@salesforce/apex/ScreenGenerationController.getPicklistValues';
import getLoanStage from '@salesforce/apex/COMM_SalesLoanActionsController.getLoanStage';
import getScreenFieldsBasisComponentName from '@salesforce/apex/Utility.getScreenFieldsBasisComponentName';
import Max_Director_Details_Records from '@salesforce/label/c.Max_Director_Details_Records';
import updateDirectorDetails from '@salesforce/apex/HL_DirectorDetailsController.updateDirectorDetails';
import { validateOnlyAlphabetsAndSpaces, validateDecimalNumber, isNotFutureDate } from 'c/utility';
export default class DirectorDetailsCmp extends LightningElement {


    @track isSalesOrCreditStage = false;
    @api recordId;
    @track details;
    @track showAddRefModal = false;
    @track allFieldDetails = {};
    @track showAddButton = false;
    @track directorDetailRecordsCount;
    @track screenFieldList = [];
    @track directorDetailsToBeShown = false;
    @track isLoading = true;
    @track isEditDetail = false;
    @track recordIdToEdit;
    @track isSaving = false;

    connectedCallback() {
        console.log('recordId--', this.recordId);
        this.fetchScreenFields();
        this.isDirectorDetailToBeShown();
        this.fetchDirectorDetails();
    }
    fetchScreenFields() {
        getScreenFieldsBasisComponentName({
            componentName: 'Director Details'
        })
        .then(result => {
            console.log('result----', result);

            const promises = result.map(item => {
                let updatedItem = {
                    ...item,
                    isPicklist: item.Field_Type__c === 'Picklist',
                    isDate: item.Field_Type__c === 'Date'
                };

                if (updatedItem.isPicklist) {
                    return getPicklistValues({
                        storageObject: updatedItem.Storage_Object__c,
                        storageField: updatedItem.Storage_Field__c
                    })
                    .then(optionsResult => {
                        updatedItem.picklistOptions = optionsResult.map(option => ({
                            label: option.label,
                            value: option.value
                        }));
                        console.log('Picklist options: ', updatedItem.picklistOptions);
                        console.log('Updated item: ', updatedItem)
                        return updatedItem;
                    });
                } else {
                    return Promise.resolve(updatedItem);
                }
            });

            return Promise.all(promises);
        })
        .then(finalResult => {
            this.screenFieldList = finalResult;
            console.log('Final screenFieldList:', this.screenFieldList);
        })
        .catch(error => {
            console.error('Error while fetching screen fields:', error);
        });
    }

        async fetchDirectorDetails() {
            try {
                this.isLoading = true;
                this.details = await fetchDirectorDetails({ loanId: this.recordId });
                await this.getLoanStage();
        
                const maxRecords = parseInt(Max_Director_Details_Records, 10);
                console.log('this.details.length-----', this.details.length);
                console.log('Max_Director_Details_Records: ', maxRecords);
                console.log('this.isSalesOrCreditStage: ', this.isSalesOrCreditStage);

                if (this.details.length < maxRecords && this.isSalesOrCreditStage) {
                    console.log('this.details.length-----', this.details.length);
                    console.log('isSalesOrCreditStage-----', this.isSalesOrCreditStage);
                    this.showAddButton = true;
                } else {
                    this.showAddButton = false;
                }
            } catch (error) {
                console.log('Error: ' + error);
            } finally {
                this.isLoading = false;
            }
        }

        handleDelete(event) {
            let detId = event.target.dataset.name;
            console.log('detId :-- ' + detId);

            deleteDirectorDetails({ refId: detId })
                .then(result => {
                    console.log('result---', result);
                    this.showToast('Success', 'Director Detail deleted successfully', 'success');
                    this.allFieldDetails = {};
                    this.fetchDirectorDetails();
                })
                .catch(error => {
                    console.log('Error: ' + error);
                });
        }

        handleEdit(event) {
            console.log('Inside handleEdit: ', event);
            this.recordIdToEdit = event.target.dataset.id;
            console.log('detId :-- ' + this.recordIdToEdit);
        
            fetchDirectorDetails({ loanId: this.recordId }) 
                .then(result => {
                    console.log("Result: ", result);
                    const recordToEdit = result.find(item => item.Id === this.recordIdToEdit);
                    console.log("recordToEdit: ", recordToEdit);
                    if (recordToEdit) {
                        this.screenFieldList = this.screenFieldList.map(item => {
                            item.value = recordToEdit ? recordToEdit[item.Storage_Field__c] : '';
                            return item;
                        });

                        console.log('Prefilled details:', JSON.stringify(this.allFieldDetails));
                        this.showAddRefModal = true;
                        this.isEditDetail = true;
                    } else {
                        this.showToast('Error', 'Record not found for editing', 'error');
                    }
                })
                .catch(error => {
                    console.log('Error fetching record for edit:', error);
                    this.showToast('Error', 'Unable to fetch record details', 'error');
                });
        }
            


        showAddDirectorModal() {
            this.screenFieldList.map(item => {
                item.value = '';
                return item;
            })
            this.showAddRefModal = true;
            this.isEditDetail = false;
        }

        hideAddDirectorModal() {
            this.showAddRefModal = false;
        }

        addDirectorDetails(event) {
            if (this.isSaving) {
                return;
            }
            console.log("Director details -> ", event);
            console.log('all field details in add---', JSON.stringify(this.allFieldDetails));

            const validationError = this.validateDirectorDetails();
            if (validationError) {
                this.showToast('Error', validationError, 'error');
                return;
            }

            this.isSaving = true;
            this.saveDirectorDetails();
        }

        validateDirectorDetails() {
            //const DIN_NUMBER_LENGTH = 8;
            const MAX_SHAREHOLDING_PERCENTAGE = 100;

            if (!this.isValidField(this.allFieldDetails.Director_Name__c) ||
                !validateOnlyAlphabetsAndSpaces(this.allFieldDetails.Director_Name__c)) {
                return 'Please add valid Director Name.';
            }

            if (!this.isValidField(this.allFieldDetails.Director_DIN_Number__c)) {
                return 'Please add DIN Number.';
            }
            /*
            if (this.allFieldDetails.Director_DIN_Number__c.length !== DIN_NUMBER_LENGTH) {
                return 'DIN Number must consist of 8 digits.';
            }
            */

            if (!this.isValidField(this.allFieldDetails.Percentage_of_Shareholding__c) ||
                parseFloat(this.allFieldDetails.Percentage_of_Shareholding__c) > MAX_SHAREHOLDING_PERCENTAGE ||
                !validateDecimalNumber(this.allFieldDetails.Percentage_of_Shareholding__c)) {
                return 'Please add valid Percentage of Shareholding.';
            }

            if (!this.isValidField(this.allFieldDetails.Director_Designation__c)) {
                return 'Please add Director Designation.';
            }

            if (!this.isValidField(this.allFieldDetails.Date_of_Appointment__c) ||
                !isNotFutureDate(this.allFieldDetails.Date_of_Appointment__c)) {
                return 'Please add Date of Appointment.';
            }

            if (!this.isValidField(this.allFieldDetails.Address_Section__c)) {
                return 'Please add Address Section.';
            }

            return null;
        }

        isValidField(fieldValue) {
            return fieldValue != null && fieldValue !== undefined && fieldValue !== '';
        }

        async saveDirectorDetails() {
            console.log('inside saveDirectorDetails');
            try {
                const result = await saveDirectorDetails({
                    inputMap: this.allFieldDetails,
                    loanId: this.recordId
                });

                console.log('result from saveDirectorDetails: ', result);
                this.allFieldDetails = {};

                if (result === 'success') {
                    this.hideAddDirectorModal();
                    this.fetchDirectorDetails();
                    this.showToast('Success', 'Director Details have been added successfully', 'success');
                } else {
                    this.showToast('Error', 'Error while adding Director Details', 'error');
                }
            } catch (error) {
                console.log('Error: ' + error);
                this.showToast('Error', 'Error adding director details', 'error');
            } finally {
                this.isSaving = false;
            }
        }

        handleInputChange(event) {
            console.log('event: ', event);
            if (event.target.dataset.name && event.target.value){
            const currentField = event.target.dataset.name;
            const currentValue = event.target.value;
            console.log('currentField--', currentField);
            console.log('currentValue--', currentValue);

            this.allFieldDetails[currentField] = currentValue;
            console.log('this.fieldDetails-----' + JSON.stringify(this.allFieldDetails));
            }
        }


        showToast(title, message, variant) {
            const event = new ShowToastEvent({
                title,
                message,
                variant
            });
            this.dispatchEvent(event);
        }

        async getLoanStage() {
            console.log('inside getloanstage');
            try {
                const result = await getLoanStage({
                    recordId: this.recordId,
                });
                console.log('stage result----', JSON.stringify(result));
        
                if (result == 'Credit Underwriting' || result == 'Sales login') {
                    this.isSalesOrCreditStage = true;
                } else {
                    this.isSalesOrCreditStage = false;
                }
            } catch (error) {
                console.log('Error in getLoanStage:', error);
                this.isSalesOrCreditStage = false;
            }
        }

        isDirectorDetailToBeShown() {
            isDirectorDetailsApplicable({
                loanId : this.recordId
            }).then(result => {
                console.log('result from isDirectorDetailsApplicable: ', JSON.stringify(result));
                console.log('result == consition: ', JSON.stringify(result) == 'true');

                if (JSON.stringify(result) == 'true') {
                    this.directorDetailsToBeShown = true;
                } else {
                    this.directorDetailsToBeShown = false;
                }
            })
            .catch(error => {
                console.log('Error in isDirectorDetailToBeShown: ' + error);
                this.showToast('Error', 'Error while fetching Director Details', 'error');
            })
    }

    validateEditedFields() {
        const DIN_NUMBER_LENGTH = 8;
        const MAX_SHAREHOLDING_PERCENTAGE = 100;

        if ('Director_Name__c' in this.allFieldDetails) {
            if (!this.isValidField(this.allFieldDetails.Director_Name__c) ||
                !validateOnlyAlphabetsAndSpaces(this.allFieldDetails.Director_Name__c)) {
                return 'Please add valid Director Name.';
            }
        }

        if ('Director_DIN_Number__c' in this.allFieldDetails) {
            if (!this.isValidField(this.allFieldDetails.Director_DIN_Number__c)) {
                return 'Please add DIN Number.';
            }
            /*
            if (this.allFieldDetails.Director_DIN_Number__c.length !== DIN_NUMBER_LENGTH) {
                return 'DIN Number must consist of 8 digits.';
            }
            */
        }

        if ('Percentage_of_Shareholding__c' in this.allFieldDetails) {
            if (!this.isValidField(this.allFieldDetails.Percentage_of_Shareholding__c) ||
                parseFloat(this.allFieldDetails.Percentage_of_Shareholding__c) > MAX_SHAREHOLDING_PERCENTAGE ||
                !validateDecimalNumber(this.allFieldDetails.Percentage_of_Shareholding__c)) {
                return 'Please add valid Percentage of Shareholding.';
            }
        }

        if ('Director_Designation__c' in this.allFieldDetails) {
            if (!this.isValidField(this.allFieldDetails.Director_Designation__c)) {
                return 'Please add Director Designation.';
            }
        }

        if ('Date_of_Appointment__c' in this.allFieldDetails) {
            if (!this.isValidField(this.allFieldDetails.Date_of_Appointment__c) ||
                !isNotFutureDate(this.allFieldDetails.Date_of_Appointment__c)) {
                return 'Please add Date of Appointment.';
            }
        }

        if ('Address_Section__c' in this.allFieldDetails) {
            if (!this.isValidField(this.allFieldDetails.Address_Section__c)) {
                return 'Please add Address Section.';
            }
        }

        return null;
    }

    editDirectorDetails() {
        if (this.isSaving) {
            return;
        }
        const validationError = this.validateEditedFields();
        if (validationError) {
            this.showToast('Error', validationError, 'error');
            return;
        }
        this.isSaving = true;
        updateDirectorDetails({
            directorRecord: { ...this.allFieldDetails, Id: this.recordIdToEdit }
        })
            .then(result => {
                console.log('result---', result);
                if (result == true) {
                    this.showToast('Success', 'Director Details have been updated successfully', 'success');
                    this.fetchDirectorDetails();
                    this.showAddRefModal = false;
                    this.isEditDetail = false;
                } else {
                    this.showToast('Error', 'Error while updating Director Details', 'error');
                }
            })
            .catch(error => {
                console.log('Error: ' + error);
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

}