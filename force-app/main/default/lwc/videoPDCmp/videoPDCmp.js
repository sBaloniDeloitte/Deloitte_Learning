import { LightningElement, track, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getApplicants from "@salesforce/apex/COMM_ItrScreenController.getApplicants";
import getApplicantData from "@salesforce/apex/COMM_VideoPDController.getApplicantData";
import getApplicantsInformation from '@salesforce/apex/COMM_VideoPDController.getApplicantsInformation';
import initiateVideoPD from '@salesforce/apex/COMM_VideoPDController.initiateVideoPD';
import initiateTelePD  from '@salesforce/apex/Comm_TelePDController.initiateTelePD';
import sendSMSForVPD  from '@salesforce/apex/COMM_VideoPDController.sendSMSForVPD';
import sendMailForVPD  from '@salesforce/apex/COMM_VideoPDController.sendMailForVPD';
import savePDNotes from '@salesforce/apex/COMM_VideoPDController.savePDNotes';
import Application_Verification from '@salesforce/schema/Application_Verification__c';
import dispositionOptions from '@salesforce/schema/Application_Verification__c.VPD_CM_Disposition__c';
import DispositionField from '@salesforce/schema/Application_Verification__c.Disposition__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import saveCMDispostion from '@salesforce/apex/COMM_VideoPDController.saveCMDispostion';
import checkVideoPD from '@salesforce/apex/GetVideoPDResponseController.checkVideoPD';
import getVedioPdResponse from '@salesforce/apex/GetVideoPDResponseController.getVedioPdResponse';
import getDocs from '@salesforce/apex/GetVideoPDResponseController.getDocs';
import getDocuments from '@salesforce/apex/GetVideoPDResponseController.getDocuments';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import getPicklistValuesForDisposition from '@salesforce/apex/COMM_VideoPDController.getPicklistValuesForDisposition';
import {NavigationMixin} from 'lightning/navigation';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import APPROVAL_STATUS from "@salesforce/schema/Opportunity.Approval_Status__c";
import STAGENAME_FIELD from "@salesforce/schema/Opportunity.StageName";
import OWNERID_FIELD from "@salesforce/schema/Opportunity.OwnerId";
import USER_ID from "@salesforce/user/Id";
import ProfileName from '@salesforce/schema/User.Profile.Name';
import { updateRecord,getRecord } from "lightning/uiRecordApi";
import getVPDLink from '@salesforce/apex/GetVideoPDResponseController.getVPDLink';
import checkIfAlreadyInitiatedPd from '@salesforce/apex/Comm_ManualPdController.checkIfAlreadyInitiatedPd';

export default class VideoPDCmp extends NavigationMixin(LightningElement) {
  @api recordId;
  @api disabledCmp = false;
  channelName = '/event/Refresh_Event__e';
  subscription = {};
  @api isTelePd;
  @track telePD;
  @track pdType;
  @track spinner = false;
  @track isShowModal = false;
  @track isShowModalTPD = false;
  @track applicantValue = '';
  @track options = [];

  @track applicantName = '';
  @track cmEmail = '';
  @track applicantMobileNumber = '';
  @track applicantEmail = '';
  @track cmMobileNumber = '';
  @track cmName = '';
  @track applicantInformation=[];
  @track selectedVerification='';
  @track showPDNotes=false;
  @track pdNotes;
  @track picklistValues= [];
  @track showTable=false;
  @track videoPd;
  @track videoPDDocuments = [];
  @track showDocs = false;
  @track fromRetriger = false;
  @track isDisabledInitiation;
  hideButton = false;
  showTriggerPD = true;
  @track OppSubStageVal;
  @wire(getObjectInfo, { objectApiName: Application_Verification })
      objectInfo;

   userProfile = '';

    @wire(getRecord, { recordId: USER_ID, fields: [ProfileName] })
    userDetails({ error, data }) {
        if(data) {
            this.userProfile = data.fields.Profile.value.fields.Name.value;
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: [SUBSTAGE_FIELD,APPROVAL_STATUS,STAGENAME_FIELD,OWNERID_FIELD] })
    opportunity({ error, data }) {
        if(data) {
            var oppSubStage = data.fields.Sub_stage__c.value;
            this.OppSubStageVal = data.fields.Sub_stage__c.value;
            var approvalStatus = data.fields.Approval_Status__c.value;
            var StageName = data.fields.StageName.value;
            var OwnerId = data.fields.OwnerId.value;

            if(StageName === 'Credit Underwriting'){
                console.log('this.userProfile: '+this.userProfile);
                if(this.userProfile != 'System Administrator' && OwnerId != USER_ID){
                    this.hideButton = true;
                }
                if(this.userProfile == 'System Administrator') {
                    this.hideButton = false;
                }
            }

            console.log('approvalStatus>>'+approvalStatus);
            if(oppSubStage === 'Disbursed' || oppSubStage === 'Hold' || oppSubStage === 'Rejected' || ['Hard Rejected', 'Soft Rejected 1', 'Soft Rejected 2'].includes(approvalStatus)) {
                this.hideButton = true;
            }
        }
    }
  
  // @wire(getPicklistValues, {
  //     fieldApiName: DispositionField,
  //     // recordTypeId: '$recordTypeId'
  // })
  // picklistData({ data, error }) {
  //     if (data) {
  //         this.picklistValues = data.values;
  //         this.error = undefined;
  //         console.log('picklistValues-->', JSON.stringify(this.picklistValues));
  //     } else if (error) {
  //         this.error = error;
  //         this.picklistValues = [];
  //         console.error('error: '+error);
  //     }
  // }

  // get recordTypeId() {
  //   console.log('recordTypeId--',this.objectInfo.data.recordTypeInfos);   
  //   const recordTypes = this.objectInfo.data.recordTypeInfos;
  //   const recordTypeInfo = Object.values(recordTypes).find(rt => rt.name === 'Personal Discussion');
  //   return recordTypeInfo.recordTypeId;
  // }

  get dispositionOptionsForTele() {
    return this.picklistValues;
  }

  showToastMessage(title, message, type) {
    const toastEvent = new ShowToastEvent({
      title: title,
      message: message,
      variant: type,
    });
    this.dispatchEvent(toastEvent);
  }

  connectedCallback() {
    console.log('userProfile ',this.userProfile);
    this.registerErrorListener();
    this.subscribeToPlatformEvent();
    getPicklistValuesForDisposition()
    .then((result) => {
        this.picklistValues = result.map(val => ({
            label: val,
            value: val
        }));
    })
    .catch((error) => {
        this.error = error;
        console.error('Error fetching picklist values', error);
    });
    
    this.getApplicantPickList();
    console.log('pdType----' + this.isTelePd);
    if(this.isTelePd== 'true'){
      this.telePD = true;
      this.pdType = 'Tele PD';
    }else{
      this.telePD = false;
      this.pdType = 'Video PD';
    }
    console.log('telePD----' + this.telePD);
    this.getAllApplicants();
    this.fetchLoanStage();
    
    //this.showToastMessage("Success", "Record updated successfully", "success");
  }

  subscribeToPlatformEvent() {
    console.log('Platform event received, refreshing...');
    subscribe(this.channelName, -1, (response) => {
        const updatedRecordId = response.data.payload.Loan_Application_Id__c;
        if (updatedRecordId === this.recordId) {
            
            this.getAllApplicants();
        }
    }).then((response) => {
        this.subscription = response;
        console.log('Subscribed to platform event:', response.channel);
    });
}

  registerErrorListener() {
      onError((error) => {
          console.error('EMP API error: ', error);
      });
  }

  disconnectedCallback() {
      unsubscribe(this.subscription, (response) => {
          console.log('Unsubscribed: ', response);
      });
  }

  fetchLoanStage() {
    getLoanStage({ loanId: this.recordId })
      .then(result => {
        console.log('Result1', result);
        if (result == 'Credit Underwriting' || result == 'PSV' || result == 'Disbursement') {
            getCurrentUserProfileName()
            .then((res) => {
                console.log('res: '+res);
                if(res == 'Sales' || res == 'Ops' || res == 'Credit Officer' || res == 'Sales') {
                    this.isDisabledInitiation = true;
                    this.showTriggerPD = false;
                    if(this.OppSubStageVal == 'Credit in-progress' && result == 'Credit Underwriting') {
                      this.showTriggerPD = true;
                      this.isDisabledInitiation = false;
                    }
                }
            })
            .catch((error) => {
                console.error('Error getCurrentUserProfileName --> '+ error);
            });
        } else {
          getCurrentUserProfileName()
            .then((res) => {
                console.log('res: '+res);
                if(res == 'Sales' || res == 'Ops' || res == 'Credit Manager') {
                    this.isDisabledInitiation = true;
                }
            })
            .catch((error) => {
                console.error('Error getCurrentUserProfileName --> '+ error);
            });
        }
      })
      .catch(error => {
        console.error('Error:', error);
    });
  }

  getAllApplicants(){
    console.log('Inside getAllApplicants---');
    console.log('this.pdType----', this.pdType);
    
    getApplicantsInformation({
      recordId: this.recordId,
      pdType: this.pdType
    })
    .then((response) => {
      console.log("customer details=:" + JSON.stringify(response));
      if(response && response.length > 0){
        this.applicantInformation = response;
        this.showTable=true;
      }
      else{
        var staticRecord;
        staticRecord.applicantId = '3456';
        staticRecord.applicantName = 'Ishi';
        staticRecord.applicantType = 'Primary';
        staticRecord.pdStatus = 'Pending';

        this.applicantInformation.push(staticRecord);
      }
      if(this.pdType == 'Video PD'){
        // this.handlePDsummaryRefresh();
      }
      

    })
    .catch((error) => {
      console.log('Error in getAllApplicants' + JSON.stringify(error));
    });
  }
  handleApplicantChange(event) {
    this.applicantValue = event.target.value;
    this.getApplicantRecord();
  }
  handleNavigateToForm(event){
          console.log('this.recordId>'+this.recordId);
          //console.log('this.applicantId>'+this.applicantId);
          const appVerifId = event.target.dataset.id;
         // const appVerifId = event.target.dataset.id;
          console.log('appVerifId => ' + appVerifId);

          // Build absolute URL to your Lightning page
          const baseUrl = window.location.origin; 
          const url = `${baseUrl}/lightning/n/Credit_PD_Form_Page?c__recordId=${this.recordId}&c__appVerifId=${appVerifId}`;

          // Open in new browser tab
          window.open(url, '_blank');

          console.log('this.recordId>' + this.recordId);
          console.log('this.applicantId>' + this.applicantId);
          console.log('appVerifId: '+appVerifId);
        /*  const pageref = {
              type: 'standard__navItemPage',
              attributes: {
                  apiName:'Credit_PD_Form_Page',
                  recordId:this.recordId,
                  appVerifId :appVerifId,
                  objectApiName: 'Opportunity',
              },
              state:{
                  c__recordId:this.recordId,
                  c__appVerifId: appVerifId,
              }
          };
          this[NavigationMixin.Navigate](pageref);*/
         

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
        this.applicantValue = this.options[0].value;
        console.log("applicantValue" + this.applicantValue);
        this.getApplicantRecord();
      })
      .catch((error) => {});
  }

  triggerVPD() {
    this.getApplicantRecord();
    this.isShowModal = true;
  }
  triggerTPD() {
    this.getApplicantRecord();
    this.isShowModalTPD = true;
  }
  hideModalBox() {
    this.isShowModal = false;
  }
  hideModalBoxTPD() {
    this.isShowModalTPD = false;
  }

  hidePDNotes(){
    this.showPDNotes= false;
  }

  handlePDNotes(event){
    this.pdNotes= event.target.value;
  }
  handleInitiate() {
    console.log('initiate vpd');
    this.spinner = true;
    //this.isShowModal=false;

    checkIfAlreadyInitiatedPd({
      loanId: this.recordId,
      applicantId: this.applicantValue,
      pdType: 'Video PD'
  }).then((response) => {
      if (response) {
          this.showToastMessage('Error', 'PD is already initiated!.', 'error');
          this.showAddRowbutton = true;
      } else {
        initiateVideoPD({
          applicantId: this.applicantValue,
          loanId: this.recordId,
          applicantEmail: this.applicantEmail
  
      })
        .then((response) => {
          if(response == 'success') {
            //`this.getAllApplicants();
            this.sendSmsFOrVPD();
  
            //this.showToastMessage('Success','Video PD initiated successfully!.','success');
          }else {
            this.showToastMessage('Error',response,'error');
          }
          
          this.hideModalBox();
          this.spinner = false;
        })
        .catch((error) => {
          this.spinner = false;
          this.showToastMessage('Error',error,'error');
        });
      }

  })
  .catch(error => {
      console.log('Error saving record -->', error);
  })

    
    
  }

  sendSmsFOrVPD () {
    this.spinner = true;
    sendSMSForVPD({
      applicantId: this.applicantValue,
      loanId: this.recordId

  })
    .then((response) => {
      if(response == 'success') {
        this.getAllApplicants();
        if(this.fromRetriger) {
          this.showToastMessage('Success','Re-send link to customer successfully!','success');
          this.fromRetriger = false;
        }else {
          this.showToastMessage('Success','Video PD initiated successfully!.','success');
        }
        
        
      }else {
        this.showToastMessage('Error',response,'error');
      }
      
      this.hideModalBox();
      this.spinner = false;
    })
    .catch((error) => {});
  }

  sendMailFOrVPD () {
    this.spinner = true;
    sendMailForVPD({
      applicantId: this.applicantValue,
      loanId: this.recordId,
      applicantEmail: this.applicantEmail

  })
    .then((response) => {
      if(response == 'success') {
        this.sendSmsFOrVPD();
        
        //this.showToastMessage('Success','Re-send link to customer successfully!','success');
      }else {
        this.showToastMessage('Error',response,'error');
      }
      
      this.hideModalBox();
      this.spinner = false;
    })
    .catch((error) => {});
  }

  handleInitiateTPD(){
    if (this.applicantMobileNumber.length != 10) {
      this.showToastMessage("Error", "Please check applicant mobile number", "error");     
      return;
    }

    if (this.cmMobileNumber.length != 10) {
      this.showToastMessage("Error", "Please check CM mobile number", "error");
      return;
    }

    checkIfAlreadyInitiatedPd({
          loanId: this.recordId,
          applicantId: this.applicantValue,
          pdType: 'Tele PD'
      }).then((response) => {
          if (response) {
              this.showToastMessage('Error', 'PD is already initiated!.', 'error');
              this.showAddRowbutton = true;
          } else {
            initiateTelePD({
              recordId: this.recordId,
              applicantId: this.applicantValue,
              toMobileNumber: this.applicantMobileNumber,
              fromMobileNumber: this.cmMobileNumber
            })
            .then((response) => {
              console.log("response in telePd" + response);
              if(response=='success'){
                this.getAllApplicants();
                this.showToastMessage("Success", "Tele PD initiated successfully", "success");
                this.hideModalBoxTPD();
              }else{
                this.showToastMessage("Error", "Please contact your admin.", "error");
              }
        
            })
            .catch((error) => {
              console.log('Error in initiateTelePD' + JSON.stringify(error));
              this.showToastMessage("Error", "Please check with the admin", "error");
            });
          }

      })
      .catch(error => {
          console.log('Error saving record -->', error);
      })

    
  }
  getApplicantRecord() {
    getApplicantData({
      applicantId: this.applicantValue
    })
      .then((response) => {
        console.log("getItrRecords CY " + JSON.stringify(response));
          this.applicantName = response.applicantName;
          this.cmEmail = response.cmEmail;
          this.applicantMobileNumber = response.applicantMobileNumber;
          this.applicantEmail = response.applicantEmail;
          this.cmName = response.cmName;
          this.cmMobileNumber = response.cmMobileNumber;
      })
      .catch((error) => {});
  }
  joinChat() {

  }
  resendLink(event) {
    const applicantId= event.target.dataset.id;
    this.applicantValue = applicantId;
    this.spinner = true;
    this.fromRetriger = true;
    this.sendMailFOrVPD();

    
  }
  handleApplicantMobileChange(event){
    console.log('event in handleApplicantMobileChange' + event.target.value);
    this.applicantMobileNumber = event.target.value;
    

  }
  handleCMMobileChange(event){
    console.log('event in handleCMMobileChange' + event.target.value);
    this.cmMobileNumber = event.target.value;
  }
  viewImage(event) {
    const applicantId= event.target.dataset.id;
    console.log('applicantId----> '+applicantId);
    console.log('loanId----> '+this.recordId);
    this.spinner = true;
    checkVideoPD({
      loanId: this.recordId,
      appId: applicantId
    })
    .then((response) => {
      console.log('checkVideoPDData: ' + response);
      this.videoPd = response;
      if(this.videoPd === 'The Application has not been verifed.') {
        this.spinner = false;
        // this.showToastMessage("Error", this.videoPd, "error");
        const inputMap ={
          'recordId':applicantId,
          'loanId':this.recordId,
          'processName':'Get Video PD'
        }

        getVedioPdResponse({
          inputMap: inputMap
        })
        .then((response) => {
          console.log('responseData:', JSON.stringify(response));
        
          const docPromises = response.map((doc) => {
            const payload = {
              url: doc.url,
              fileName: doc.fileName
            };
        
            return getDocs({ docDetails: payload, loanId: this.recordId, appId: applicantId })
              .then((result) => {
                console.log('Integration success for', doc.fileName, '=>', result);
                return { fileName: doc.fileName, status: 'success', result };
              })
              .catch((error) => {
                console.error('Integration failed for', doc.fileName, '=>', error);
                return { fileName: doc.fileName, status: 'error', error };
              });
          });
        
          return Promise.all(docPromises);
        })
        .then((results) => {
          console.log('All integrations complete:', results);
        })
        .catch((error) => {
          console.error('Error in getVedioPdResponse or integration:', JSON.stringify(error));
        })
        .finally(() => {
          this.spinner = false;
          this.viewDocs(applicantId,this.recordId);
        });
      } else {
        this.spinner = false;
        // this.showToastMessage("Success", "Required Api call by admin.", "success");
        this.viewDocs(applicantId,this.recordId);
      }
    })
    .catch((error) => {
      console.error('Error in checkVideoPDData: ' + error);
      this.spinner = false;
      this.showToastMessage("Error", "Please contact your admin.", "error");
    });
  //   setTimeout(() => {
  //     this.spinner = false;
  //     this.showToastMessage("Error", "Please contact your admin.", "error");
  // }, 2000);

  }
  viewDocs(applicantId,loanId){
    console.log('viewDocs applicantId: ' + applicantId);
    console.log('viewDocs loanId: ' + loanId);
    getDocuments({ appId: applicantId, loanId: loanId })
    .then((result) => {
      this.videoPDDocuments = result;
      console.log('this.videoPDDocuments: ' + JSON.stringify(this.videoPDDocuments));
      this.showDocs = true;
    })
    
  }
  handleDocViewClose(){
    this.showDocs = false;
  }

  getCallRecording(event){
    const applicantId= event.target.dataset.id;
    this.spinner = true;
    checkVideoPD({
      loanId: this.recordId,
      appId: applicantId
    })
    .then((response) => {
      console.log('checkVideoPDData: ' + response);
      this.videoPd = response;
      if(this.videoPd === 'The Application has not been verifed.') {
        this.spinner = false;
        // this.showToastMessage("Error", this.videoPd, "error");
        const inputMap ={
          'recordId':applicantId,
          'loanId':this.recordId,
        }

        getVPDLink({
          inputMap: inputMap
        })
        .then((response) => {
          console.log('response for getVPDLink', response);
          if(response == 'No link found'){
            this.showToastMessage("Error", "No link found", "error");
          }else{
            return response;
          }
        })
        .then((results) => {
          console.log('All integrations complete:', results);
        })
        .catch((error) => {
          console.error('Error in getVedioPdResponse:', JSON.stringify(error));
        });
      } else {
        this.spinner = false;
        this.showToastMessage("Error", "The Application has not been verifed.", "error");
      }
    })
    .catch((error) => {
      console.error('Error in checkVideoPDData: ' + error);
      this.spinner = false;
      this.showToastMessage("Error", "Please contact your admin.", "error");
    });
  }

  handleEditClick(event){
    console.log('Inside handleEditClick');
    console.log('Inside handleEditClick event---', event.target.dataset.id);

    this.selectedVerification= event.target.dataset.id;
    this.applicantInformation.forEach(customerinTable => {
      console.log('ccustomerinTable0----', JSON.stringify(customerinTable));
      
      if(customerinTable.verifId === this.selectedVerification ){
          this.pdNotes= customerinTable.pdNotes;
          console.log('Inside tryuuuu---');
          console.log('this.pdNotes----in tru',this.pdNotes);
          
          
      }
  });
    
    this.showPDNotes= true;
  }

  handleDispChange(event){
    const selectedVerifId= event.target.dataset.id;
    var selectedDisp= event.target.value;
    console.log('selectedDisp----',selectedDisp);
    console.log('selectedVerifId---',selectedVerifId);

    saveCMDispostion({
      appVerifId: selectedVerifId,
      cmDisposition: selectedDisp
    })
      .then((response) => {
        if(response){
          this.showToastMessage("Success", "Disposition save successfully.", "success");
          this.getAllApplicants();
        }else{
          this.showToastMessage("Success", "Please check with admin.", "success");
        }
      })
      .catch((error) => {
        this.showToastMessage("Success", "Please check with admin.", "success");
      });
    
  }

  savePDNotes(){
    this.showPDNotes= false;
    savePDNotes({
      appVerifId: this.selectedVerification,
      notes: this.pdNotes
    })
      .then((response) => {
        if(response){
          this.showToastMessage("Success", "PD notes save successfully.", "success");
          this.showPDNotes= false;
          this.getAllApplicants();
        }else{
          this.showToastMessage("Success", "Please check with admin.", "success");
        }
      })
      .catch((error) => {
        this.showToastMessage("Success", "Please check with admin.", "success");
      });
  }
  handlePDsummaryRefresh() {
       
    this.dispatchEvent(new CustomEvent('handlechange', {}));
   
  }
  handleApplicantEmail(event) {
    this.applicantEmail = event.target.value;
  }
  viewImageTable(event){
    let apId = event.target.dataset.id;
    this.appVerificationId = apId;
    console.log('apid',apId);
    
    getAllDocConIds({
        appVerId: apId
      })
      .then(result => {
          if(result.length <= 0) {
              this.showToastMessage('Error', 'No Images are uploaded.', 'erroe');
              this.showImages = false;   
              return;
          }
          
          this.viewdocIds = result;
          this.getuploadedDocsView();
          this.showImages = true;   

      })
      .catch(error => {
          this.docIds = [];
      });
  }

  hanldeRefresh(){
    this.getAllApplicants();
  }
}