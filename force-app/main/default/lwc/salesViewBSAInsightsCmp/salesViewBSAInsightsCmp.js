import { api, LightningElement, track, wire } from 'lwc';
import getBankDetails from '@salesforce/apex/SalesViewBSAInsightsCmpController.getBankAccounts';
import updateAccountType from '@salesforce/apex/SalesViewBSAInsightsCmpController.updateAccountType';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import BANK_DETAILS from '@salesforce/schema/Bank_Details__c';
import accountTypeField from '@salesforce/schema/Bank_Details__c.Account_Type__c';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import NOT_ELIGIBLE_ICON from '@salesforce/resourceUrl/RejectIconEligibility';


export default class SalesViewBSAInsightsCmp extends LightningElement {
    @api recordId;
    @track bankAccounts=[];
    @track accountTypeOptions = [];
    showBankTable=false;
    @api showErrorBSA;
     notEligibleIcon;

    @wire(getObjectInfo, { objectApiName: BANK_DETAILS })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: accountTypeField
    })
    wiredPicklist({ error, data }) {
        if (data) {
            this.accountTypeOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
            console.log('picklistValues--', JSON.stringify(this.accountTypeOptions));
            
        } else if (error) {
            console.error('Error fetching picklist values', error);
        }
    }

    connectedCallback(){
        this.notEligibleIcon = NOT_ELIGIBLE_ICON;
        console.log('loanId in connected callback---', this.recordId);
        this.fetchBankRecords();
    }
 
    

    fetchBankRecords(){
        getBankDetails({loanId: this.recordId})
        .then(result => {
        
            console.log('result in getBankDetails--'+JSON.stringify(result));
            if(result) {
                this.bankAccounts = result;
                
                if (this.bankAccounts.length > 0) {
                    this.showBankTable = true;
                     const valueSelectedEvent = new CustomEvent('showbuttons', {
                        detail: {
                            
                        }
                    });
                    this.dispatchEvent(valueSelectedEvent);
                }
                else{
                    this.showBankTable = false;
                     const valueSelectedEvent = new CustomEvent('showerror', {
                        detail: {
                            
                        }
                    });
                    this.dispatchEvent(valueSelectedEvent);
                }
            }
        })
        .catch(error => {
            this.error = error;
            console.log('error in getBankDetails', error);
            
        });   

    }

    handleAccTypeChange(event){
        const selectedBank= event.target.dataset.id;
        var selectedType= event.target.value;

        updateAccountType({
            bankId: selectedBank,
            accountType: selectedType
        })
        .then((response) => {
            console.log('response in update---', response);
            
            if(response == 'success'){
                this.showToastMessage("Success", "Account type saved successfully.", "success");
                this.fetchBankRecords();
                    const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
                        detail: {
                            
                        }
                    });
                    this.dispatchEvent(valueSelectedEvent);
            }else{
                this.showToastMessage("Success", "Please check with admin.", "success");
            }
        })
        .catch((error) => {
            this.showToastMessage("Success", "Please check with admin.", "success");
        });
    }

    showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
        title: title,
        message: message,
        variant: type,
        });
        this.dispatchEvent(toastEvent);
    }
}