import { LightningElement,api,track } from 'lwc';
import getApplicants from '@salesforce/apex/HL_GrossMarginController.getApplicants';
import deleteCamRecords from '@salesforce/apex/HL_GrossMarginController.deleteCamRecords';
import createCamRecordsOnLoad from '@salesforce/apex/HL_GrossMarginController.createCamRecordsOnLoad';
export default class Hl_grossMarginCmp extends LightningElement {
    @api recordId;
    applicantList;
    dataLoaded = false;
    tabList;
    showTab = false;
    spinnerRun = false;
    confirmationScreen = false;
    pendingUncheck = { appId: null, checkboxEl: null };
    recToBeDeletedForApplicants =[];
    applicantIds = [];

    connectedCallback() {
        this.getApplicants();
    }

    getApplicants(){
        getApplicants({
            loanId: this.recordId,
            recordTypeName: 'Gross Margin'
        }).then(response=>{
            console.log('Gross Margin: getApplicants : ' +  JSON.stringify(response));
            this.applicantList = response;
            this.dataLoaded = true;
            if(this.applicantList != undefined && this.applicantList != null && this.applicantList.length>0){
                this.tabList = this.applicantList.filter(item => {
                    return item.isDataCreated == true;
                });
                if(this.tabList != undefined && this.tabList != null && this.tabList.length >0){
                    this.showTab = true;
                }
            }
            console.log('Gross Margin: getApplicants : ' +  this.showTab + ' ::: ' +  this.tabList);
        }).catch(error=>{
            console.error('Error getApplicants : ' +  JSON.stringify(error));
        })
    }

    handleCheckboxChange(event){
        console.log('Gross Margin: handleCheckboxChange : ' + event.target.dataset.id + ' ::: '+  event.target.checked);
        const appId = event.target.dataset.id
        if(event.target.checked){
            this.spinnerRun = true;
            if (!this.applicantIds.includes(appId)) {
                this.applicantIds.push(appId);
                createCamRecordsOnLoad({
                    loanId: this.recordId,
                    apDetId: event.target.dataset.id
                }).then(response=>{
                    console.log('Gross Margin: handleCheckboxChange : ' +  JSON.stringify(response));
                    this.spinnerRun = false;
                    this.getApplicants();
                    setTimeout(() => {
                        this.dispatchEvent(
                            new CustomEvent('incomeexpenceschanged', {
                                detail: { 
                                    change: 'Income Assessment Checked'
                                },
                            })
                        );
                    }, 500);
                }).catch(error=>{
                    this.spinnerRun = false;
                     console.error('Error handleCheckboxChange : ' +  JSON.stringify(error));
                })
            }
        }
        else{
            console.log('Inside else 72');
            this.spinnerRun = false; 
            this.pendingUncheck = { appId, checkboxEl: event.target };
            console.log('Inside else 75');
            this.confirmationScreen = true;
        }
    }

    onClickModalYes(){
        this.spinnerRun = true;
        const { appId } = this.pendingUncheck;
        this.applicantIds = this.applicantIds.filter(id => id !== appId);
        this.recToBeDeletedForApplicants.push(appId);

        this.confirmationScreen = false;
        this.pendingUncheck = { appId: null, checkboxEl: null };
        setTimeout(() => {
            this.deleteCamRecords();
        }, 100);
       
    }

    onClickModalNo(){
        if (this.pendingUncheck.checkboxEl) {
            this.pendingUncheck.checkboxEl.checked = true;
        }

        this.confirmationScreen = false;
        this.pendingUncheck = { appId: null, checkboxEl: null };
        this.spinnerRun = false;
    }

    deleteCamRecords(){
        console.log('recToBeDeletedForApplicants----'+this.recToBeDeletedForApplicants);
          deleteCamRecords({
                loanId: this.recordId,
                applicantIds: this.recToBeDeletedForApplicants
            }).then(response=>{
                 console.log('response----'+this.response);
                this.spinnerRun = false;
                this.getApplicants();
                this.dispatchEvent(
                new CustomEvent('incomeexpenceschanged', {
                    detail: { 
                        change: 'Income Assessment Deleted'
                    },
                })
            );
            }).catch(error=>{
                this.spinnerRun = false;
            })
    }
}