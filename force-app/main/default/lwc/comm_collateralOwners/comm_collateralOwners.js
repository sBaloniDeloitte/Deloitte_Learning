import { LightningElement, api, track } from 'lwc';
import getApplicants from '@salesforce/apex/Utility.getApplicants';
import createCollateralOwner from '@salesforce/apex/CreateCollateralController.createCollateralOwner';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Comm_collateralOwners extends LightningElement {
    @api recordId;
    @track isMultiSelect = false;
    applicantNames = [];
    picklistValueSelected = false;
    @track selectedOptionList;

    connectedCallback() {
        this.fetchApplicants();
    }

    fetchApplicants() {
        getApplicants({ applicationCollateralId: this.recordId })
            .then(result => {
                this.applicantNames = result.map(applicant => ({
                    label: applicant.Name,
                    value: applicant
                }));

            })
            .catch(error => {
                console.error('Error fetching applicants:', error);
            });
    }
    
    handleMultiPicklistSelection(event) {
        console.log('event.detail:', JSON.stringify(event.detail));
        let tempSelectedValues  = [];
        this.selectedOptionList = event.detail.selectedList;
        console.log('selectedList 637:', this.selectedOptionList);
    
        if (this.selectedOptionList.length > 0) {
            this.picklistValueSelected = true;
            this.isMultiSelect = true;
            console.log('tempSelectedValues------',tempSelectedValues);
            for(let i=0; i<this.selectedOptionList.length; i++){
                    console.log('tempSelectedValues-----',tempSelectedValues);
                    tempSelectedValues.push(this.selectedOptionList[i])
                    console.log('tempSelectedValues------',JSON.stringify(tempSelectedValues));
            }
        }
        else{
            this.picklistValueSelected = false;
        }
    }

    onOwnerButtonClick(){
        console.log('selectedOptionList:', JSON.stringify(this.selectedOptionList));    
        createCollateralOwner({applicantList: this.selectedOptionList, appColId: this.recordId})
        .then(result => {
            console.log('result:', result);
            if(result && result.includes('All collateral owners selected already exist for this Collateral')){
                this.showToast('All Collateral Owner Already Exist!', 'error', 'All collateral owners selected already exist for this Collateral');
            }
            else if(result && result.includes('already exist as collateral owner.')){
                this.showToast('Some Owners already exist and Rest Inserted', 'warning', result);
            }
            else if(result && result.includes('Inserted')){
                this.showToast('Collateral Owner Created Successfully', 'success', 'Collateral Owner Created Successfully');
            }
        }).catch(error => {
            console.error('Error creating collateral owner:', error);
        });
    }

    showToast(title, variant, message){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

}