import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getApplicants from "@salesforce/apex/COMM_ItrScreenController.getApplicants";
import getApplicantDetails from "@salesforce/apex/ITRCmpController.getApplicantDetails";
import getItrDoc from "@salesforce/apex/ITRCmpController.getItrDoc";
import initiateAPIRequest from "@salesforce/apex/ITROnlineController.initiateAPIRequest";
import initiateUploadAPIRequest from "@salesforce/apex/ITRUploadController.initiateAPIRequest";
import getItrvInfoUsingWrapper from "@salesforce/apex/ITRCmpController.getItrvInfoUsingWrapper";
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
import checkIfRequestInitiated from "@salesforce/apex/ITRCmpController.checkIfRequestInitiated";


export default class ItrCmp extends LightningElement {
    @api recordId;
    @track selectedMethod = '';
    isFieldDisable = false;
    @track applicantValue = '';
    @track options = [];
    @track isManual = false;
    @track panNumber = '';
    @track dob;
    @track password = '';
    @track isApplicantSeleted = false;
    @track fileId;
    @track docPresent = false;
    @track acceptedFormats = ['.pdf'];
    @track applicantname;
    @track contentId;
    @track iframeSrc;
    @track isDataPresent = false;
    @track itrvInfoList = [];
    
  @track hideButton = false;
  @track msg = '';

/*
    methodOptions = [
        { label: 'Online', value: 'Online' },
        { label: 'Upload', value: 'Manual' }
    ];*/

    methodOptions = [
        { label: 'Upload', value: 'Manual' }
    ];

    get getClassByDeviceType(){
        if(this.deviceType =='Mobile'){
            return '';
        }
        return 'custom-width';
    }
    get hasItrvInfo() {
  return Array.isArray(this.itrvInfoList) && this.itrvInfoList.length > 0;
}

    handleMethodChange(event) {
        this.selectedMethod = event.detail.value;
        
        if(this.selectedMethod == 'Manual') {
            this.isManual = true;
        }else {
            this.isManual = false;
        }
        this.showData = true;
        this.panNumber = '';
        this.dob = null;
        this.getApplicantPickList();
    }

    handleApplicantChange(event) {
        this.applicantValue = event.target.value;
        //this.spinner = true;
        this.isApplicantSeleted = true;

        this.docPresent = false;
              this.contentId = '';
              this.applicantname ='';
              this.isDataPresent = false;
        this.getApplicantDetailsJS();
        this.fetchItrvInfo();
        this.checkIfAlreadyHit();
    }

    getApplicantPickList() {
        this.spinner = true;
        this.options = [];
        getApplicants({
          recordId: this.recordId,
        })
          .then((response) => {
            console.log("customers=:" + JSON.stringify(response));
            for (let key in response) {
              this.options = [
                ...this.options,
                {
                  label: response[key],
                  value: key,
                },
              ];
            }
            this.spinner = false;
          })
          .catch((error) => {
            this.spinner = false;
            this.showToast('Error', 'Please fetching applicants.', 'error');
          });
    }
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
          title: title,
          message: message,
          variant: variant,
        });
        this.dispatchEvent(toastEvent);
    }

    checkIfAlreadyHit() {
        this.spinner = true;
        //
        checkIfRequestInitiated({
          applicantId: this.applicantValue,
        })
          .then((response) => {
            console.log("doc res=:" + JSON.stringify(response));
            if(response == 'Request is in progress!.') {
              this.msg = response;
              
            }
            this.spinner = false;
          })
          .catch((error) => {
            this.spinner = false;
            this.showToast('Error', 'Please fetching applicant details.', 'error');
          });


        //
        
    }

    getApplicantDetailsJS() {
        this.spinner = true;
        //
        getItrDoc({
          applicantId: this.applicantValue,
        })
          .then((response) => {
            console.log("doc res=:" + JSON.stringify(response));
            if(response!=null) {
              this.docPresent = true;
              this.contentId = response.Content_Document_Id__c;
              this.applicantname = response.Applicant__r.Applicant_Name__c;
              this.isDataPresent = true;
              
            }else {
               getApplicantDetails({
                applicantId: this.applicantValue,
                })
                .then((response) => {
                  console.log("customers=:" + JSON.stringify(response));
                  if(response!=null) {
                    if(response.DOB__c != null) {
                      this.dob = response.DOB__c;
                    }if(response.PAN_Number__c != null) {
                      this.panNumber = response.PAN_Number__c;
                    }
                    
                  }else {
                    this.showToast('Error', 'Please fetching applicant details.', 'error');
                  }
                  this.spinner = false;
                })
                .catch((error) => {
                  this.spinner = false;
                  this.showToast('Error', 'Please fetching applicant details.', 'error');
                });
            }
            this.spinner = false;
          })
          .catch((error) => {
            this.spinner = false;
            this.showToast('Error', 'Please fetching applicant details.', 'error');
          });


        //
        
    }

    handleUploadFinished(event) {
      const uploadedFiles = event.detail.files;
      this.fileId = uploadedFiles[0].documentId;
      //alert('No. of files uploaded : ' + uploadedFiles.length);
    }

    handleInitiate() {
      this.spinner = true;
      
        if(this.panNumber == '' || this.panNumber == null) {
          this.showToast('Error', 'PAN number is missing.', 'error');
          this.spinner = false;
          return;
        }
        if(this.dob == '' || this.dob == null) {
          this.showToast('Error', 'DOB is missing.', 'error');
          this.spinner = false;
          return;
        }
        if(this.isManual == true && (this.fileId == '' || this.fileId == null)) {
          this.showToast('Error', 'Please upload file.', 'error');
          this.spinner = false;
          return;
        }
        console.log(this.isManual,' --- ',this.fileId);
        if(!this.isManual) {
          this.initiateApi();
        }else{
          this.initiateUploadApi();
        }

      
    }

    initiateApi(){
      this.spinner = true;
      const inputMap ={
            'loanId':this.recordId,
            'applicantId':this.applicantValue,
            'processName':'ITR Online',
            'panNumber': this.panNumber,
            'dob' : this.dob
           
        }
        initiateAPIRequest({
            inputMap:inputMap
            })
            .then(response=>{
                console.log('result 83 Cibil API---',JSON.stringify(response))
                if(response.includes('Error:')){
                    // console.log('response--',response.split(':')[1]);
                    // var temp = response.split(':')[1];
                    // console.log('temp--'+temp);
                    // this.errorList =response;
                    console.log('errorList--'+this.errorList);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: response,
                            variant: 'error',
                        }),
                    );
                }
                else if(response == 'success'){
                     this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Successfully submitted for ITR.',
                        variant: 'success',
                    }),
                );
                }else {
                  this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'API execiution fail.',
                        variant: 'error',
                    }),
                );
                }
                this.spinner = false;
            }).catch(error => {
                console.log('Error in fetching document cibil name: ', JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error,
                        variant: 'error',
                    }),
                );
                this.spinner = false;
            })
    }

    initiateUploadApi(){
      this.spinner = true;
      const inputMap ={
            'loanId':this.recordId,
            'applicantId':this.applicantValue,
            'processName':'ITR Upload',
            'panNumber': this.panNumber,
            'password': this.password,
            'docId': this.fileId,
           
        }
        initiateUploadAPIRequest({
            inputMap:inputMap
            })
            .then(response=>{
                console.log('result 83 Cibil API---',JSON.stringify(response))
                if(response.includes('Error:')){
                    // console.log('response--',response.split(':')[1]);
                    // var temp = response.split(':')[1];
                    // console.log('temp--'+temp);
                    // this.errorList =response;
                    console.log('errorList--'+this.errorList);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: response,
                            variant: 'error',
                        }),
                    );
                }
                else if(response == 'success'){
                     this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Successfully submitted for ITR.',
                        variant: 'success',
                    }),
                );
                }else {
                  this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'API execiution fail.',
                        variant: 'error',
                    }),
                );
                }
                this.spinner = false;
            }).catch(error => {
                console.log('Error in fetching document cibil name: ', JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error,
                        variant: 'error',
                    }),
                );
                this.spinner = false;
            })
    }
    handleDownload(event) {
      const docId = event.currentTarget.dataset.id;
      console.log('docId',docId);
        if (docId) {
            // Construct the download URL using the ContentDocumentId
            const downloadUrl = `/sfc/servlet.shepherd/document/download/${docId}`;
            console.log('downloadUrl',downloadUrl);
            // Open the URL in a new window/tab to trigger the download
            window.open(downloadUrl, '_blank');
        }
    }
    fetchItrvInfo() {
  if (!this.applicantValue) { this.itrvInfoList = []; return; }

  getItrvInfoUsingWrapper({ applicantId: this.applicantValue })
    .then(list => {
      const safe = Array.isArray(list) ? list : [];
      // add a stable key per card for the template
      this.itrvInfoList = safe.map((x, i) => ({
        ...x,
        _key: x.acknowledgementNumber || x.assessmentYear || `${i}`
      }));
      console.log('[ITR] typed list len:', this.itrvInfoList.length);
      this.msg = '';
    })
    .catch(err => {
      console.error('[ITR] getItrvInfoUsingWrapper error:', err);
      this.itrvInfoList = [];
    });
}

    checkCmpEditability() {
    getComponentEditability({ loanId : this.recordId, component : '' })
    .then(result => {
        if(result){
            this.hideButton = result;
            console.log('this.hideButton>>>>'+this.hideButton);
        }
    })
    .catch(error => {
        console.log('Error getComponentEditability:  '+error);
    });
  }
 connectedCallback() {
        this.checkCmpEditability();
    }

}