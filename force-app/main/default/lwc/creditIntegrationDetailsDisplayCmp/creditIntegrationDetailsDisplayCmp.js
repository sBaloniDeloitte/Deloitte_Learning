import { api, LightningElement, track } from 'lwc';
import getDoctorCheckData from '@salesforce/apex/DoctorCheckController.getDoctorCheckData';
import getCACheckdata from '@salesforce/apex/CADegreeCheckController.getCACheckdata';
import getLegalEntityCheckdata from '@salesforce/apex/LegalEntityCheckController.getLegalEntityCheckdata';
import getUdhyamCheckdata from '@salesforce/apex/UdhyamRegistartionCheckController.getUdhyamCheckdata';
export default class CreditIntegrationDetailsDisplayCmp extends LightningElement {
    @api recordId;
    @api processName;

    @track showDoctorFields=false;
    @track showCAFields= false;
    @track showLegalEntityFields= false;
    @track showUdhyamFields= false;
    @track doctorList = [];
    @track caList = [];
    @track leiList = [];
    @track udhyamList = [];
    @track showQualifications = false;
    @track showSuspensios = false;
    @track showIndustry = false;
    @track qualifications = [];
    @track suspensions = [];
    @track industries = [];

    connectedCallback(){
        console.log('processName----', this.processName);
        if(this.processName== 'Loan Doctor Membership Authentication'){
            this.showDoctorFields = true;
        }else if(this.processName=='Loan CA Membership Authentication'){
            this.showCAFields = true;
        }else if(this.processName=='Loan Udhyam'){
            this.showUdhyamFields = true;
        }else if(this.processName=='Loan Legal Entity'){
            this.showLegalEntityFields = true;
        }
        this.getDoctorCheckData();
        this.getCACheckDataList();
        this.getLegalEntityCheckdataList();
        this.getUdhyamCheckdataList();
    }

    getDoctorCheckData(){
        getDoctorCheckData({loanId: this.recordId})
        .then(response=>{
            console.log('responsee---doctorList', JSON.stringify(response));
            
            this.doctorList = response;

        }).catch(error=>{

        })
    }
    get hasdoctorList(){
        return this.doctorList.length > 0 ;
    }

    getCACheckDataList(){
        getCACheckdata({loanId: this.recordId})
        .then(response=>{
            console.log('responsee---caList', JSON.stringify(response));
            
            this.caList = response;

        }).catch(error=>{

        })
    }
    get hascaList(){
        return this.caList.length > 0 ;
    }

    getLegalEntityCheckdataList(){
        getLegalEntityCheckdata({loanId: this.recordId})
        .then(response=>{
            console.log('responsee---getLegalEntityCheckdata', JSON.stringify(response));
            
            this.leiList = response;

            console.log('responsee---getLegalEntityCheckdata', JSON.stringify(this.leiList));
        }).catch(error=>{

        })
    }
    get haslieList(){
        return this.leiList.length > 0 ;
    }

    getUdhyamCheckdataList(){
        getUdhyamCheckdata({loanId: this.recordId})
        .then(response=>{
            console.log('responsee---udhyamList', JSON.stringify(response));
            
            this.udhyamList = response;

        }).catch(error=>{

        })
    }
    get hasudhyamList(){
        return this.udhyamList.length > 0 ;
    }


    openQualificationsPopup(event) {
        const doctorId = event.target.dataset.id;
        const doctor = this.doctorList.find(doc => doc.result.doctorId === doctorId);
        this.qualifications = doctor.result.additionalQualifications || [];
        this.showQualifications = true;
    }

    openSuspensionsPopup(event) {
        const doctorId = event.target.dataset.id;
        const doctor = this.doctorList.find(doc => doc.result.doctorId === doctorId);
        this.suspensions = doctor.result.suspensions || [];
        this.showSuspensios = true;
    }

    openIndustriesPopup(event) {
        const udhyamId = event.target.dataset.id;
        const udhyam = this.udhyamList.find(doc => doc.result.udyamRegistrationNo === udhyamId);
        this.industries = udhyam.result.industry || [];
        this.showIndustry = true;
    }

    closePopup() {
        this.showQualifications = false;
        this.showSuspensios = false;
        this.showIndustry = false;
    }
    get containerClass() {
        return this.hasdoctorList || this.hascaList || this.hasudhyamList || this.hasleiList ? 'min-height' : '';
    }

}