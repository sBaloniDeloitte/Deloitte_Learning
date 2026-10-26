import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from "@salesforce/user/Id";
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import NewLeadIcon from '@salesforce/resourceUrl/NewLeadIcon'; // Import the resource file
//import CreateNewLoan from '@salesforce/resourceUrl/CreateNewLoan'; //Import the resource file for Loan Creation
import leadReport from '@salesforce/resourceUrl/leadReport'; // Import the resource file
import bulkImport from '@salesforce/resourceUrl/Bulk_Import';
//import getReportId from '@salesforce/apex/Utility.getReportIdByName';
import getSampleCSV from "@salesforce/apex/BulkUpsertRecordScreenController.getSampleCSV";
import getConstants from '@salesforce/apex/BulkUpsertRecordScreenController.getConstants';
import saveFile from "@salesforce/apex/BulkUpsertRecordScreenController.saveFile";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
//import basePath from '@salesforce/community/basePath';

import fetchUserProfile  from '@salesforce/apex/BulkUpsertRecordScreenController.getCurrentUserProfileName'; 
export default class BulkUploadHome extends NavigationMixin(LightningElement) {

    @api appName = '';
    @track fileId;
    @track showSubmitButton = false;
    @track showHomeDownloadbutton = true;
    @track showHomeUploadbutton = false;
    @track isRendered = false;
    uProfile;
    userName;
    constants;
    NewLeadIcon = NewLeadIcon;
    buttonText = 'Start Journey';
    //CreateNewLoan = CreateNewLoan;
    //buttonTextLoan = 'Create New Loan Application';
    showBulkImportBtn = false;
    showExportBtn = false;
    showleadpage = false;
    isMobile = false;
    isDesktop = false;
    //@track showLoanButton = true;
    bulkImports = false;
    reportId;
    LeadReportICON = leadReport;
    bulkLeadImport = bulkImport;
    objectName = "Lead";
    showDownloadButton = false;
    // // Get user data
    @wire(getRecord, { recordId: USER_ID, fields: ['User.Name'] })
    userData({ error, data }) {
        if(error) this.error = error;
         else if(data) {
        console.log('data',data);
        this.userName = data.fields.Name.value;
       }
     }

    // @wire(getReportId, { reportName: 'Leads Report Test'})
    // report({ data, error }){
    //     if(error) this.error = error;
    //     else if(data){
    //         this.reportId = data;
    //     }
    // }
    get acceptedFormats() {
        return [".csv"];
    }

    renderedCallback() {
        if (!this.isRendered) {
            // Create and append styles dynamically
            const style = document.createElement('style');
            style.innerText = `
            .red-button button{
      background-color: #007ACC;
      border-radius: 8px;
      border: 1px solid rgba(255,255,255,0.15);
      box-shadow: 0 2px 8px rgba(0,0,0,0.25);
      transition: transform 0.2s ease, box-shadow 0.2s ease, filter 0.2s ease;
}
.red-button button:hover{
      transform: translateY(-2px);
      box-shadow: 0 6px 16px rgba(0,122,204,0.45);
      filter: brightness(1.08);
}
.red-button button.slds-button
{
        background-color: #007ACC;
    padding: 0px 25px;
    border-radius: 8px;
    border: 1px solid rgba(255,255,255,0.15);
    box-shadow: 0 2px 8px rgba(0,0,0,0.25);
    color: white;
    font-weight: 500;
    transition: transform 0.2s ease, box-shadow 0.2s ease, filter 0.2s ease;
}
.red-button button.slds-button:hover
{
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(0,122,204,0.45);
    filter: brightness(1.08);
}
.back-button button{
    
    padding: 0px 25px;
    border-radius: 8px;
    font-weight: 500;
}

            `;
    
            // Append the styles to the .styleContainer
            this.template.querySelector('.styleContainer')?.appendChild(style);
    
            // Prevent re-adding styles
            this.isRendered = true;
        }
    }

      handleUploadFinished(event) {
    // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        console.log("data" + JSON.stringify(uploadedFiles));
        this.fileId = uploadedFiles[0].documentId;
        this.bulkImports = false;
        this.showSubmitButton = true;
  }

    nextAction(){
       this.showHomeDownloadbutton = false;
       this.showHomeUploadbutton = true;
    }

    backAction(){
       this.showHomeDownloadbutton = true;
       this.showHomeUploadbutton = false;
    }

    submitCsv() {
        if (this.fileId) {
        // this.isSpinner = true;
        // this.isShowModal = false;
        saveFile({
            fileID: this.fileId,
            objectName: this.objectName,
        })
            .then((response) => {
            console.log("stage response: " + response);
            try {
                if(response != null && response != '' ){
                let successCount = 0;
                let failureCount = 0;
                response.forEach(response => {
                if (response.includes('Success')) {
                    successCount++;
                } else {
                    failureCount++;
                }
            });
            if (successCount === response.length) {

                //show the success modal poup and on click of next of popup redirect to lead list page
                const isCommunity = window.location.hostname.includes('.my.site.com');
                console.log('Current URL:', window.location.href);
                console.log('Hostname:', window.location.hostname);
                console.log('Is Community:', isCommunity);

                if (isCommunity) {
                    //window.location.assign(`${basePath}/lead`); 
                    window.location.href = 'https://de1756698904067--demo.sandbox.my.site.com/EducationLoanForm/lead/Lead'; 
                    //https://de1756698904067--demo.sandbox.my.site.com/EducationLoanForm/lead/Lead              
                }else {
                    this.navigateToLeads();               
                }



                // All records succeeded
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Success',
                //         message: 'All records processed successfully.',
                //         variant: 'success'
                //     })
                // );
                //this.downloadResultCSV(response);
                //this.isSpinner = false;
                //this.isShowModal = true;
            } else if (successCount > 0 && failureCount > 0) {
                // Some succeeded, some failed
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Partial Success',
                //         message: `${successCount} records succeeded, ${failureCount} failed.`,
                //         variant: 'warning'
                //     })
                // );
                //this.downloadResultCSV(response);
                //this.isSpinner = false;
                //this.isShowModal = true;
            } else {
                // All records failed
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Failure',
                //         message: 'All records failed to process.',
                //         variant: 'error'
                //     })
                // );
                //this.downloadResultCSV(response);
                //this.isSpinner = false;
                //this.isShowModal = true;
            }
            
                }
            } catch (e) {
                console.log("error " + e.message);
            }
            })
            .catch((error) => {
            console.log("error " + JSON.stringify(error));
            if (error.body.message.startsWith("Too many")) {
                this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message:
                    "Can not process this amount of data at the moment. Please reduce the number of records and try again.",
                    variant: "error",
                })
                );
            } else {
                this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: error.body.message,
                    variant: "error",
                })
                );
            }

            //this.isSpinner = false;
            //this.isShowModal = true;
            });
        } else {
        this.dispatchEvent(
            new ShowToastEvent({
            title: "Error",
            message: "Please upload csv.",
            variant: "error",
            })
        );
        //this.isSpinner = false;
        return;
        }
    }

    navigateToLeads() {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Lead',
                    actionName: 'list'
                },
            terName: 'Recent'
                })
        }

    downloadResultCSV(response) {
    // Prepare a html table
    let doc = "<table>";
    doc += "<style>";
    doc += "table, th, td {";
    doc += "    border: 1px solid black;";
    doc += "    border-collapse: collapse;";
    doc += "}";
    doc += "</style>";
    doc += "<tr>";
    doc += "<th>External Id</th>";
    doc += "<th>Id</th>";
    doc += "<th>Status</th>";
    doc += "<th>Message</th>";
    doc += "</tr>";
    for (let i = 0; i < response.length; i++) {
      doc += "<tr>";
      const myArray = response[i].split(",");
      if(myArray.length == 2) {

        doc += "<th>" + myArray[0] + "</th>";
        doc += "<th></th><th></th>";
        doc += "<th>" + myArray[1] + "</th>";
      }else if(myArray.length == 4) {
        doc += "<th>" + myArray[0] + "</th>";
        doc += "<th>" + myArray[1] + "</th>";
        doc += "<th>" + myArray[2] + "</th>";
        doc += "<th>" + myArray[3] + "</th>";
      }
      
      doc += "</tr>";
    }

    doc += "</table>";
    var element = "data:application/vnd.ms-excel," + encodeURIComponent(doc);
    let downloadElement = document.createElement("a");
    downloadElement.href = element;
    downloadElement.target = "_self";
    // use .csv as extension on below line if you want to export data as csv
    downloadElement.download = "Result.xls";
    document.body.appendChild(downloadElement);
    downloadElement.click();
  }

    connectedCallback(){
        console.log('The device form factor is: ' + FORM_FACTOR);
        this.getConstantsData();
        if(FORM_FACTOR === "Large") { 
            this.isDesktop = true;
        }
        else { 
            this.isMobile = true;
        }
        
       /* if(this.appName == 'Direct Business Hub'){
            this.showBulkImportBtn = true;
            this.showExportBtn = true;
            this.showDownloadButton = true;
        }*/
        this.fetchUserDetails();
    }
     getConstantsData(){
        getConstants({})
        .then(result => {
            this.constants = result;
            console.log('constants: ', this.constants);
        })
    }
    fetchUserDetails(){
        fetchUserProfile({})
        .then(result => {
            this.uProfile = result;
            console.log('User Profile: ', this.uProfile);
        //    if(this.uProfile == 'System Administrator')
        //       this.systemAdmin = true
            // Delay the execution of the switch statement logic
            setTimeout(() => {
                switch (this.uProfile) {
                    case this.constants.Tele_Sales_User_Profile:
                       
                       this.showBulkImportBtn = false;
                        this.showExportBtn = false;
                        this.showDownloadButton = false;

                        break;
    
                    case this.constants.Tele_Sales_Manager_Profile:
                        console.log('348');
                        this.showBulkImportBtn = true;
                        this.showExportBtn = true;
                        this.showDownloadButton = true;
                        break;
                    case this.constants.System_Admin_Profile:
                        console.log('inside admin case');
                        this.showBulkImportBtn = true;
                        this.showExportBtn = true;
                        this.showDownloadButton = true;
                        break;
                    default:
                        console.log('default');
                        this.showBulkImportBtn = true;
                        this.showExportBtn = true;
                        this.showDownloadButton = true;
                }
            }, 1000); // Delay of 1 second (1000 milliseconds)
        })
        .catch(error => {
            console.error('Error fetching user profile:', error);
        });
    }
    showModalBox() {
        // Implement your modal box logic here
        console.log('Create Lead button clicked');

        // if(this.isDesktop){
            console.log('71');
            this.showleadpage = true;
       // }
        /*else{console.log('73');
            if(this.appName == 'LOS Portal' || this.appName == 'Direct Business Hub'){
                console.log('75');
                this[NavigationMixin.Navigate]({
                    type: 'standard__navItemPage',
                    attributes: {
                        apiName: 'Lead_Creation_Page' // The API Name of your custom Lightning Page
                    },
                });
            }
            else{
                console.log('83');
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: '/losportal/s/leadmobile'
                    }
                });
            }
        }*/
    }

    closeLead(event){
        this.showleadpage = false;
    }

    // handleNewLoanCreation(){
    //     //invoked when clicked on create new loan application.
    //     if(this.small){
    //         var url=this.orgDomainUrl;
    //         url=url+'/lightning/n/Create_Loan_Application_Mobile';
    //         window.open(url, "_blank");
    //     }
    //     else{
    //         var url=this.orgDomainUrl;
    //         url=url+'/lightning/n/Create_New_Loan_Application';
    //         window.open(url, "_blank");
    //     }
    // }

    showModalBoxExport() {
        console.log('Open report in new TAB');
        //try{
            window.open('/lightning/r/Report/'+this.reportId+'/view','_blank');
        // }
        // catch(e){
        //     console.log(e);
        // }
    }
 
    openbulkImport(){
        this.bulkImports = true;
        this.showExportBtn = false;
    }

    handlebulkClose(event){
        console.log('41');
        this.bulkImports = false;
    }
     downloadSampleCSV() {
    //this.isSpinner = true;
    getSampleCSV({
      objectName: this.objectName,
    })
      .then((response) => {
        console.log("stage response: " + response);
        if (response[0].startsWith("Please")) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error",
              message: response[0],
              variant: "error",
            })
          );
          //this.isSpinner = false;
          return;
        } else {
          //
          let doc = "<table>";
          doc += "<style>";
          doc += "table, th, td {";
          doc += "    border: 1px solid black;";
          doc += "    border-collapse: collapse;";
          doc += "}";
          doc += "</style>";
          doc += "<tr>";
          const myheaders = response[0].split(",");
          for (let i = 0; i < myheaders.length; i++) {
            doc += "<th>" + myheaders[i] + "</th>";
          }
          doc += "</tr>";
          doc += "<tr>";
          const myArray = response[1].split(",");
          for (let i = 0; i < myArray.length; i++) {
            doc += "<th>" + myArray[i] + "</th>";
          }

          doc += "</tr>";
          doc += "</table>";

          var csvHeader = '';
          for (let i = 0; i < myheaders.length; i++) {
            csvHeader = csvHeader + '"' + myheaders[i]+ '",';
          }
          csvHeader = csvHeader.replace(/,\s*$/, "\n");
          for (let i = 0; i < myArray.length; i++) {
            csvHeader = csvHeader + '"' + myArray[i]+ '",';
          }
          csvHeader = csvHeader.replace(/,\s*$/, "\n");

          //var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
         // var element = "data:application/vnd.ms-excel," + encodeURIComponent(doc);
            var element = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvHeader);
          let downloadElement = document.createElement("a");
          downloadElement.href = element;
          downloadElement.target = "_self";
          // use .csv as extension on below line if you want to export data as csv
          const now = new Date();
          const formattedDateTime = now.toLocaleString("en-GB", {
          year: "numeric",
          month: "2-digit",
          day: "2-digit",
          hour: "2-digit",
          minute: "2-digit",
          second: "2-digit",
          }).replace(/[/,: ]+/g, "_");
          //const sanitizedUserName = this.userName.replace(/\s+/g, "_").replace(/[^\w\-]/g, "");
          const sanitizedUserName = 'Lead upload template';
          const fileName = `${sanitizedUserName}.csv`;
          downloadElement.download = fileName;
          document.body.appendChild(downloadElement);
          downloadElement.click();

          //
          //this.isSpinner = false;
        }
      })
      .catch((error) => {
        console.log("error " + JSON.stringify(error));

        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: error.body.message,
            variant: "error",
          })
        );
        //this.isSpinner = false;
      });

    // Prepare a html table

    var csvHeader =
      '"SF Case Id","Origin","Case Source","Case Category","Case Type","LMS Loan Number"\n';
    csvHeader +=
      '"5009H000008WCFzQAO","Email","Customer","Complaint","Deliverables","LNABH00317-180061308"\n';
  }
}