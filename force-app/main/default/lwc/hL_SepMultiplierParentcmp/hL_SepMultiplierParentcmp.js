import { LightningElement,api,track } from 'lwc';
    import getApplicants from '@salesforce/apex/HL_sepMultiplier.getApplicants';
    import deleteCamRecords from '@salesforce/apex/HL_sepMultiplier.deleteCamRecords';
    import createCamRecordsOnLoad from '@salesforce/apex/HL_sepMultiplier.createCamRecordsOnLoad';

export default class HL_SepMultiplierParentcmp extends LightningElement {
@api recordId;
applicantList;
dataLoaded = false;
tabList;
showTab = false;
spinnerRun = false;
        connectedCallback() {
            this.getApplicants();
        }
        getApplicants(){
            getApplicants({
                loanId: this.recordId,
                recordTypeName : 'Sep Multiplier'
            }).then(response=>{
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
                this.spinnerRun = true;
                deleteCamRecords({
                    loanId: this.recordId,
                    apDetId: event.target.dataset.id
                }).then(response=>{
                    this.spinnerRun = false;
                    this.getApplicants();
                }).catch(error=>{
                    this.spinnerRun = false;
                })
            }
        }
    
}