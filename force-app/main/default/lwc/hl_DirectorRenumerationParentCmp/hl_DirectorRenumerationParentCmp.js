import { LightningElement,api,track } from 'lwc';
// import getApplicants from '@salesforce/apex/HL_directorRenumaration.getApplicants';
import getApplicants from '@salesforce/apex/HL_CashProfitController.getApplicants';
import deleteCamRecords from '@salesforce/apex/HL_directorRenumaration.deleteCamRecords';
import createCamRecordsOnLoad from '@salesforce/apex/HL_directorRenumaration.createCamRecordsOnLoad';

export default class Hl_DirectorRenumerationParentCmp extends LightningElement {
@api recordId;
applicantList;
dataLoaded = false;
tabList;
showTab = false;
spinnerRun = false;

connectedCallback(){
 this.getApplicants();
}
        getApplicants(){
            getApplicants({
                loanId: this.recordId,
                recordTypeName: 'Director Renumeration'
            }).then(response=>{
                this.spinnerRun = false;
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
                this.spinnerRun = false;
            })
        }
                handleCheckboxChange(event){
                    if(event.target.checked){
                        this.spinnerRun = true;
                        createCamRecordsOnLoad({
                            loanId: this.recordId,
                            apDetId: event.target.dataset.id
                        }).then(response=>{
                            console.log('response: '+response);
                            this.getApplicants();
                            setTimeout(() => {
                                let newchild = this.template.querySelector('c-hl-director-renumeration');
                                if (newchild) {
                                    this.spinnerRun = false;
                                    newchild.callConnected();
                                }
                            }, 1000);
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
                           setTimeout(() => {
                            let newchild = this.template.querySelector('c-hl-director-renumeration');
                            if (newchild) {
                                this.spinnerRun = false;
                                newchild.callConnected();
                            }
                        }, 1000);
                            this.showTab = true;
                        }).catch(error=>{
                            this.spinnerRun = false;
                        })
                    }
                }
}