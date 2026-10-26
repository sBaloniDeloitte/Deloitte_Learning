import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getApplicants from "@salesforce/apex/Utility.getApplicant";
import getItrRecords from "@salesforce/apex/COMM_ItrScreenController.getItrRecords";
import saveItrRecord from "@salesforce/apex/COMM_ItrScreenController.saveItrRecord";
import initiateAPIRequest from '@salesforce/apex/COMM_ItrScreenController.initiateAPIRequest';
import insertFileRecord from '@salesforce/apex/COMM_SalesLoanLoginController.insertFileRecord';
import deleteContentDoctIdLoginFee from '@salesforce/apex/COMM_SalesLoginFeeController.deleteContentDoctIdLoginFee';
import createDocumentChecklistForSales from '@salesforce/apex/COMM_SalesLoanLoginController.createDocumentChecklistForSales';
import getDocumentsList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getDocumentsList';
import { NavigationMixin } from 'lightning/navigation';

export default class ItrScreenCmp extends NavigationMixin(LightningElement) {
  @api recordId;
  @track options = [];
  @track yearOptions = [];
  @track applicantValue = '';
  @track yearCY = '';

  @track idCY;
  @track incomeAsPerPolicyCY = '';
  @track ackNumberCY = '';
  @track assMentYearCY = '';
  @track itrfillingDateCY;
  @track isSmall= false;

  @track yearPY = '';

  @track idPY;
  @track incomeAsPerPolicyPY = '';
  @track ackNumberPY = '';
  @track assMentYearPY = '';
  @track itrfillingDatePY;

  @track rowObjectCY = {};
  @track rowObjectPY = {};

  @track selectedMethod = 'Manual';
  @track isUpload = false;
  @track isManual = true;
  //@track isAPI = false;

   @track contentDocumentId;
   passWord;
   passWordPY;
    showDocumentNameCY= false;
    showDocumentNamePY= false;
    uploadedFileNameCY= [];
    uploadedFileNamePY= [];
    uploadedFilesSalesCY= [];
    uploadedFilesSalesPY= [];
    countOfDocumentCY =0;
    countOfDocumentPY =0;

     documentList = [];
selectedDocIds = [];
selectedDocList = [];
salesReturnedDocumentId;
 uploadedFilesListCY= [];
 uploadedFilesListPY= [];
 showRecords = false;

   methodOptions = [
        { label: 'Manual', value: 'Manual' },
        //{ label: 'Upload', value: 'Upload' },
       // { label: 'API', value: 'API' }
    ];
  

  connectedCallback() {
    this.countOfDocumentCY =0;
     this.countOfDocumentPY =0;
    console.log('gst component');
    var currentTime = new Date()
    var currYear = currentTime.getFullYear();
    var previousYear = currYear - 1;
    this.yearCY = currYear.toString();
    this.yearPY = previousYear.toString();
    this.getYearOptions();
    this.getApplicantPickList();
    this.getdocDetails();
  }


  getApplicantPickList() {
    getApplicants({
      recordId: this.recordId,
    })
      .then((response) => {
        console.log("customer details=:" + JSON.stringify(response));
        //this.options = [... this.options,{label:'All',value:'All'}];
        for (let key in response) {
          console.log("customer details=:" + response[key]);
          this.options = [
            ...this.options,
            {
              label: response[key],
              value: key,
            },
          ];
        }
        console.log("this.options[0].value" + this.options[0].value);
        this.applicantValue = this.options[0].value;
        console.log("applicantValue" + this.applicantValue);
        this.getItrDataCY();
        this.getItrDataPY();

      })
      .catch((error) => {});
  }

   get getClassByDeviceType(){
        if(this.deviceType =='Mobile'){
            return '';
        }
        return 'custom-width';
    }

  handleApplicantChange(event) {
    this.applicantValue = event.target.value;
    this.getItrDataCY();
    this.getItrDataPY();
  }

 // handleMethodChange(event) {
      //  event.stopPropagation();
      //  this.selectedMethod = event.detail.value;
       // this.isAPI = this.selectedMethod === 'API';
       // this.isManual = this.selectedMethod === 'Manual';
        // if(this.isUpload){
       //   this.getdocDetails();
       // }
   // }

  handleYearChange(event) {
    var name = event.target.name;
    var value = event.target.value;
    console.log("name=" + name + " value=" + value);
    this.assMentYearcY = value;
    console.log("assMentYearcY" + this.assMentYearcY);
   
  }

  getYearOptions() {
    var date = new Date();
    var year = date.getFullYear();
    for (var i = year - 4; i <= year + 3; i++) {
        this.yearOptions = [
            ...this.yearOptions,
            {
              label: i.toString(),
              value: i.toString(),
            },
        ];  
    }
  }

  onBlurInputField(event) {
    var name = event.target.name;
    var value = event.target.value;
    console.log("name=" + name + " value=" + value);
    if(name == 'incomeAsPerPolicyCY') {
      if (/^\d+\.\d+$/.test(value)) {
        this.showToastMessage('Error', 'Please enter a valid number.', 'error');
        return;
      }
      this.incomeAsPerPolicyCY = value;
    }
    else if (name == 'itrfillingDateCY') {
      this.itrfillingDateCY = value;
    }
    else if (name == 'ackNumberCY') {
      this.ackNumberCY = value;
    }
    else if (name == 'assMentYearCY') {
      this.assMentYearCY = value;
    }
  }

  handleSaveClick() {
    this.rowObjectCY.recId = this.idCY;
    this.rowObjectCY.year = this.yearCY;
    this.rowObjectCY.busineeIncome = this.incomeAsPerPolicyCY;
    this.rowObjectCY.fillingDate = this.itrfillingDateCY;
    this.rowObjectCY.acknolegmentNumber = this.ackNumberCY;
    this.rowObjectCY.assessmentYear = this.assMentYearCY;

    if(this.rowObjectCY.busineeIncome == null || this.rowObjectCY.fillingDate == null || this.rowObjectCY.acknolegmentNumber == null || this.rowObjectCY.assessmentYear == null)  {
      this.showToastMessage('Error', 'Please fill all fields.', 'error');
    }

     const hasCY = this.documentList && this.documentList.length > 0 ? this.documentList.some(doc => doc.year && doc.year.toUpperCase() === 'CY'): false;

    /*if (!hasCY) {
        if (!this.uploadedFilesSalesCY || this.uploadedFilesSalesCY.length === 0) {
            console.log('bsa--- 220--' + this.uploadedFilesSales);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please upload document to proceed further.',
                    variant: 'error'
                })
            );
            return;
        }
    }*/


    console.log("customer details=:" + JSON.stringify(this.rowObjectCY));

    saveItrRecord({
      applicantId:this.applicantValue,
      res: JSON.stringify(this.rowObjectCY)
    })
      .then((response) => {
        console.log("upsertItrRecords CY " + JSON.stringify(response));
        if(this.uploadedFilesSalesCY != null || this.uploadedFilesSalesCY != undefined ){
        this.handleSaveUploadClickCY();
        }
        this.showToastMessage('Success', 'Record is updated!.', 'success');
      })
      .catch((error) => {});
  }
 
  getItrDataCY() {
    getItrRecords({
      applicantId: this.applicantValue,
      year : this.yearCY
    })
      .then((response) => {
        console.log("getItrRecords CY " + JSON.stringify(response));
        if(Object.keys(response).length === 0) {
        // Commented to remove alert from screen //alert('empty val CY');
          this.idCY = null;
        }else {
          this.idCY = response.recId;
          this.incomeAsPerPolicyCY = response.busineeIncome;
          this.itrfillingDateCY = response.fillingDate;
          this.ackNumberCY = response.acknolegmentNumber;
          this.assMentYearCY = response.assessmentYear;

        }
        
        
      })
      .catch((error) => {});
  }

 
  getItrDataPY() {
    getItrRecords({
      applicantId: this.applicantValue,
      year : this.yearPY
    })
      .then((response) => {
        console.log("getItrRecords PY " + JSON.stringify(response));
        if(Object.keys(response).length === 0) {
          this.idPY = null;
        }else {
          this.idPY = response.recId;
          this.incomeAsPerPolicyPY = response.busineeIncome;
          this.itrfillingDatePY = response.fillingDate;
          this.ackNumberPY = response.acknolegmentNumber;
          this.assMentYearPY = response.assessmentYear;

        }
        
      })
      .catch((error) => {});
  }
  

  handleSaveClickPY() {
    this.rowObjectPY.recId = this.idPY;
    this.rowObjectPY.year = this.yearPY;
    this.rowObjectPY.busineeIncome = this.incomeAsPerPolicyPY;
    this.rowObjectPY.fillingDate = this.itrfillingDatePY;
    this.rowObjectPY.acknolegmentNumber = this.ackNumberPY;
    this.rowObjectPY.assessmentYear = this.assMentYearPY;

    console.log("customer details=:" + JSON.stringify(this.rowObjectPY));
    if(this.rowObjectPY.busineeIncome == null || this.rowObjectPY.fillingDate == null || this.rowObjectPY.acknolegmentNumber == null || this.rowObjectPY.assessmentYear == null)  {
      this.showToastMessage('Error', 'Please fill all fields.', 'error');
    }
     const hasPY = this.documentList && this.documentList.length > 0 ? this.documentList.some(doc => doc.year && doc.year.toUpperCase() === 'PY'): false;

     /* if (!hasPY) {

      if(this.uploadedFilesSalesPY == null || this.uploadedFilesSalesPY == undefined || this.uploadedFilesSalesPY.length==0){
                  console.log('bsa--- 220--'+this.uploadedFilesSales)
                  this.dispatchEvent(
                      new ShowToastEvent({
                          title: 'Error',
                          message: 'Please upload document to proceed further.',
                          variant: 'error'
                      })
                  );
                  return;
              }
    }*/

    saveItrRecord({
      applicantId:this.applicantValue,
      res: JSON.stringify(this.rowObjectPY)
    })
      .then((response) => {
        console.log("upsertItrRecords PY " + JSON.stringify(response));
        if(this.uploadedFilesSalesPY != null || this.uploadedFilesSalesPY != undefined ){
        this.handleSaveUploadClickPY();
        }
        this.showToastMessage('Success', 'Record is updated!.', 'success');
      })
      .catch((error) => {});
  }
  handleCancelClickPY() {
    this.rowObjectPY.recId = this.idPY;
    this.rowObjectPY.year = this.yearPY;
    this.rowObjectPY.busineeIncome = this.incomeAsPerPolicyPY;
    this.rowObjectPY.fillingDate = this.itrfillingDatePY;
    this.rowObjectPY.acknolegmentNumber = this.ackNumberPY;
    this.rowObjectPY.assessmentYear = this.assMentYearPY;

    console.log("customer details=:" + JSON.stringify(this.rowObjectCY));

    saveItrRecord({
      applicantId:this.applicantValue,
      res: JSON.stringify(this.rowObjectCY)
    })
      .then((response) => {
        console.log("upsertItrRecords CY " + JSON.stringify(response));
        this.showToastMessage('Success', 'Record is updated!.', 'success');
      })
      .catch((error) => {});
  }
  onBlurInputFieldPY(event) {
    var name = event.target.name;
    var value = event.target.value;
    console.log("name=" + name + " value=" + value);
    if(name == 'incomeAsPerPolicyPY') {
      if (isNaN(Number(value))) {
        this.showToastMessage('Error', 'Please enter a valid number.', 'error');
        return;
      }
      this.incomeAsPerPolicyPY = value;
    }
    else if (name == 'itrfillingDatePY') {
      this.itrfillingDatePY = value;
    }
    else if (name == 'ackNumberPY') {
      this.ackNumberPY = value;
    }
    else if (name == 'assMentYearPY') {
      this.assMentYearPY = value;
    }
  }
  handleYearChangePY(event) {
    var name = event.target.name;
    var value = event.target.value;
    console.log("name=" + name + " value=" + value);
   this.assMentYearPY = value;
   
  }
  showToastMessage(title, message, type) {
    const toastEvent = new ShowToastEvent({
        title: title,
        message: message,
        variant: type
    });
    this.dispatchEvent(toastEvent);
}

    handleUploadFinishedCY(event) {
        this.countOfDocument=0;
        const uploadedFiles = event.detail.files;
        
        this.showDocumentName = false;
        const validNamePattern = /^[a-zA-Z0-9. ]+$/;

             for(var i=0;i<uploadedFiles.length;i++){ 
                 console.log('fileName-----',JSON.stringify(event.detail.files[i]))
                  if (!validNamePattern.test(event.detail.files[i].name)) {
                     console.log('fileName- 702----',JSON.stringify(event.detail.files[i]))
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Invalid File Name',
                                message: 'File name contains special characters.',
                                variant: 'error',
                            })
                        );
                        return;
                }
                else{
                     this.uploadedFilesSalesCY.push(event.detail.files[i]); 
                    console.log('fileName-----',JSON.stringify(event.detail.files[i]))
                    this.uploadedFileNameCY.push(event.detail.files[i].name);
                    this.showDocumentNameCY = true;
                }
                  console.log('this.uploadedFilesSales : ' + JSON.stringify(this.uploadedFilesSalesCY));
            // this.showToastMethod('Success', 'Document uploaded successfully.', 'success');		                  
			}   
    }

      handleUploadFinishedPY(event) {
        this.countOfDocumentPY=0;
        const uploadedFiles = event.detail.files;
        
        this.showDocumentNamePY = false;
        const validNamePattern = /^[a-zA-Z0-9. ]+$/;

             for(var i=0;i<uploadedFiles.length;i++){ 
                 console.log('fileName-----',JSON.stringify(event.detail.files[i]))
                  if (!validNamePattern.test(event.detail.files[i].name)) {
                     console.log('fileName- 702----',JSON.stringify(event.detail.files[i]))
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Invalid File Name',
                                message: 'File name contains special characters.',
                                variant: 'error',
                            })
                        );
                        return;
                }
                else{
                     this.uploadedFilesSalesPY.push(event.detail.files[i]); 
                    console.log('fileName-----',JSON.stringify(event.detail.files[i]))
                    this.uploadedFileNamePY.push(event.detail.files[i].name);
                    this.showDocumentNamePY = true;
                }
                  console.log('this.uploadedFilesSalesPY : ' + JSON.stringify(this.uploadedFilesSalesPY));
             //this.showToastMethod('Success', 'Document uploaded successfully.', 'success');		                  
			}   
    }

      handlePasswordChange(event){
        this.passWord = event.target.value;
    }

      handlePasswordChangePY(event){
        this.passWordPY = event.target.value;
    }

      showToastMethod(toastTitle, toastMessage, toastVariant){
        const evt = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

       handleSaveUploadClickCY(event){
            if(this.uploadedFilesSalesCY == null || this.uploadedFilesSalesCY == undefined || this.uploadedFilesSalesCY.length==0){
                console.log('bsa--- 220--'+this.uploadedFilesSales)
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please upload document to proceed further.',
                        variant: 'error'
                    })
                );
                return;
            }
            
        this.createDocumentChecklistForSalesCY();
        
    }

    handleSaveUploadClickPY(event){
      
            if(this.uploadedFilesSalesPY== null || this.uploadedFilesSalesPY== undefined || this.uploadedFilesSalesPY.length==0){
                console.log('bsa--- 220--'+this.uploadedFilesSales)
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please upload document to proceed further.',
                        variant: 'error'
                    })
                );
                return;
            }

        this.createDocumentChecklistForSalesPY();        
    }

   createDocumentChecklistForSalesCY(){
        console.log('applicantValue- 676-----',this.applicantValue);
        const uploadParam = {
                'loanid': this.recordId,
                'docName': 'Perfios ITR',
                'docRequiredFor': 'ITR',
                'docCategory': 'Banking',
                'manualAA': 'Manual',
                'applicantId':this.applicantValue,
                'year':'CY'
            };
        createDocumentChecklistForSales({
            uploadParam : uploadParam
        })
        .then(result =>{
            console.log('result0-----',result)
            if(result!=null && result!='' && result!=undefined){
                console.log('472');
                this.salesReturnedDocumentId =result;
                this.uploadedFilesSalesCY.forEach(file => {
                    this.uploadedFilesListCY.push({
                    id: file.documentId,
                    name: file.name,
                    downloadUrl: file.downloadUrl
                });
            });
            console.log('483');
            for(var i=0;i<this.uploadedFilesSalesCY.length;i++){
                this.countOfDocumentCY = this.countOfDocumentCY+1;
                  console.log('   this.countOfDocumentCY ',this.countOfDocumentCY );
                this.insertFileRecordToSalesforce(this.uploadedFilesSalesCY[i]);
             }

            }
        })
        .catch(error => {
            console.error('Error in checkExceptionStatus:', error);
        });
        
    
    }
     createDocumentChecklistForSalesPY(){
        console.log('applicantValue- 676-----',this.applicantValue);
        const uploadParam = {
                'loanid': this.recordId,
                'docName': 'Perfios ITR',
                'docRequiredFor': 'ITR',
                'docCategory': 'Banking',
                'manualAA': 'Manual',
                'applicantId':this.applicantValue,
                'year':'PY'

            };
        createDocumentChecklistForSales({
            uploadParam : uploadParam
        })
        .then(result =>{
            console.log('result0-----',result)
            if(result!=null && result!='' && result!=undefined){
                console.log('472');
                this.salesReturnedDocumentId =result;
                this.uploadedFilesSalesPY.forEach(file => {
                    this.uploadedFilesListPY.push({
                    id: file.documentId,
                    name: file.name,
                    downloadUrl: file.downloadUrl
                });
            });
            for(var i=0;i<this.uploadedFilesSalesPY.length;i++){
                this.countOfDocumentPY = this.countOfDocumentPY+1;
                console.error('this.uploadedFilesSales294 ',JSON.stringify(this.uploadedFilesSalesPY));
                this.insertFileRecordToSalesforce(this.uploadedFilesSalesPY[i]);
             }

            }
        })
        .catch(error => {
            console.error('Error in checkExceptionStatus:', error);
        });
        
    
    }
    insertFileRecordToSalesforce(file) {
      console.log('537');
        insertFileRecord({
            fileName: file.name,
            fileSize: file.size,
            fileContentDocumentId: file.documentId,
            recordId: this.salesReturnedDocumentId
        })
        .then(() => {
          console.log('Document Inserted Seccessfully');
          this.uploadedFilesSalesPY = [];
          this.uploadedFilesSalesCY = [];
          this.uploadedFileNamePY = [];
          this.uploadedFileNameCY = [];
           this.getdocDetails();
        })
        .catch((error) => {
             console.log('Error in Inserted Document---', error);
        });
    }

       getdocDetails() {
        console.log('86',this.recordId);
        getDocumentsList({ recordId: this.recordId, processName: 'ITR' })
            .then(result => {
                if (result && result.length > 0) {
                    console.log('Original documentList:', JSON.stringify(result));
                    this.hideNext = false;
                    // Assign the full document list (including bsaInitated documents)
                    this.documentList = result;
                    this.showRecords = true;
                    // Reset selected document lists
                    this.selectedDocIds = [];
                    this.selectedDocList = [];

                    this.documentList.forEach(item => {
                            item.isSelected = true;
                            if (!this.selectedDocIds.includes(item.contentVersionId)) {
                                this.selectedDocIds.push(item.contentVersionId);
                                this.selectedDocList.push(item);
                          //  }
                        }
                        // if (!item.bsaInitated) {
                        //     item.isSelected = false;
                        //     this.allBsaInitiated = false; 

                        // }
                        // else{
                        //     item.isSelected = true;

                        // }

                    });

                    console.log('379--')
                    console.log('380docsize--',this.documentList.length);
                    this.showRecords = this.documentList.length > 0;
                    console.log('382--');
                  
                } else {
                    this.showRecords = false;
                }
            })
            .catch(error => {
                 this.ShowLoader = false;
                this.showRecords = false;
                console.error('Error fetching document details:', error);
            });
    }

    handleView(event){
        console.log('event323--',event.target.dataset.id);
        const documentId = event.target.dataset.id; 
        console.log('documentId---324--',documentId);
        if(window.location.origin.includes('my.site.com')){
            console.log('327if');
            this.url = window.open(window.location.origin+'/losportal/sfc/servlet.shepherd/document/download/'+documentId);
            
        }else{
             console.log('331else');
            if(documentId) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__namedPage',
                    attributes: {
                        pageName:'filePreview'
                    },
                    state:{ 
                        selectedRecordId:documentId
                    }
                });
            }
            else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'No file available for preview.',
                        variant: 'error',
                    }),
                );
            
            }
        }
        
        
    }

    handleDelete(event){
            console.log('event-------',event.target.dataset.id);
            console.log('event-2------',event.target.dataset.doc);
            const contentDocumentLinkId = event.target.dataset.id;
            const docChecklistId  = event.target.dataset.doc;
            deleteContentDoctIdLoginFee({
                docId: docChecklistId,
                cdLId:contentDocumentLinkId
            }).then(result => {
                 console.log('result----',result);
                if(result){
                 this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Document delete Successfully.',
                    variant: 'Success',
                }),
            );
                console.log('result--->',result);
                this.getdocDetails();
                }
              
            })
            .catch(error => {
                console.log('error-->',error);
            })
            
            
    }
    handleNavigateNext(){
        console.log('218');
        this.dispatchEvent(new CustomEvent('navigatetonexttab', {
                detail: 'Document Details'
            }));
    }
  initiateITRApi() {
      if (!this.applicantValue) {
          this.showToast('Error', 'Please select an applicant before proceeding.', 'error');
          return; // stop further execution
      }

      const inputMap = {
          loanId: this.recordId,
          applicantId: this.applicantValue,
          processName: 'Laon PAN ITR Search'
      };

      initiateAPIRequest({ inputMap })
          .then(result => {
              this.showToast('Success', 'ITR API called successfully.', 'success');
              console.log('API response:', result);
          })
          .catch(error => {
              const message = error?.body?.message || 'Unknown error occurred';
              this.showToast('Error', message, 'error');
          });
  }
    
}