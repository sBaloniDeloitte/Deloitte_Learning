import { api, LightningElement, track } from 'lwc';
import getApplicants from '@salesforce/apex/HL_CashProfitController.getApplicants';
import createCamRecordsOnLoad from '@salesforce/apex/HL_SalariedScreenController.createCamRecordsOnLoad';
import deleteCamRecords from '@salesforce/apex/HL_SalariedScreenController.deleteCamRecords';

export default class HL_salariedScreenMainCmp extends LightningElement {

    @api recordId;
    @api disableEdit = false;
    @track applicantList = [];
    showTab = false;
    spinnerRun = false;
    confirmMessage = 'Are you sure you want to uncheck this applicant, this will delete all the data?';
    showgenericConfirm = false;
    deleteAppId = '';
    @api showCalculator = false;

    connectedCallback(){
        this.getApplicants();
    }

    getApplicants(){
        console.log('recordId: '+this.recordId);
        this.applicantList = [];

        getApplicants({
            loanId: this.recordId,
            recordTypeName: 'Salaried Individual'
        }).then(response=>{
            this.applicantList = response;
            console.log('48 response: '+JSON.stringify(response));
            
            this.showTab = false;

            if(this.applicantList){
                this.tabList = this.applicantList.filter(item => {
                    return item.isDataCreated == true;
                });

                if(this.tabList && this.tabList.length >0){
                    this.showTab = true;
                }
            }
        }).catch(error=>{

        })
    }

    handleCheckboxChange(event){
        if(event.target.checked){
            this.spinnerRun = true;
            createCamRecordsOnLoad({
                loanId: this.recordId,
                apDetId: event.target.dataset.id
            }).then(response=>{
                this.spinnerRun = false;
                this.getApplicants();
            }).catch(error=>{
                this.spinnerRun = false;
            })
        }
        else{
            this.showgenericConfirm = true;
            this.deleteAppId = event.target.dataset.id;
        }

        this.dispatchEvent(
            new CustomEvent('incomeexpenceschanged', {
                detail: { change: 'Salaried Individual' }
            })
        );
    }

    handlePositive(event){
        this.spinnerRun = true;

        deleteCamRecords({
            loanId: this.recordId,
            apDetId: this.deleteAppId
        }).then(response=>{
            this.spinnerRun = false;
            
            this.handleNegative();
        }).catch(error=>{
            this.spinnerRun = false;
            this.showgenericConfirm = false;
        });
    }

    handleNegative(){
        this.showgenericConfirm = false;
        this.getApplicants();
        
        this.deleteAppId = '';
    }
}