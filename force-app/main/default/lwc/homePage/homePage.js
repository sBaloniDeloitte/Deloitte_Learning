import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from "@salesforce/user/Id";
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import NewLeadIcon from '@salesforce/resourceUrl/NewLeadIcon'; // Import the resource file
//import CreateNewLoan from '@salesforce/resourceUrl/CreateNewLoan'; //Import the resource file for Loan Creation
import leadReport from '@salesforce/resourceUrl/leadReport'; // Import the resource file
import bulkImport from '@salesforce/resourceUrl/Bulk_Import';
import getReportId from '@salesforce/apex/Utility.getReportIdByName';
import getSampleCSV from "@salesforce/apex/BulkUpsertRecordScreenController.getSampleCSV";
import getConstants from '@salesforce/apex/Comm_LeadManagementController.getConstants';
import fetchUserProfile  from '@salesforce/apex/Utility.getCurrentUserProfileName'; 
export default class HomePage extends NavigationMixin(LightningElement) {

    @api appName = '';
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

    @wire(getReportId, { reportName: 'Leads Report Test'})
    report({ data, error }){
        if(error) this.error = error;
        else if(data){
            this.reportId = data;
        }
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
                        this.showBulkImportBtn = false;
                        this.showExportBtn = false;
                        this.showDownloadButton = false;
                }
            }, 1000); // Delay of 1 second (1000 milliseconds)
        })
        .catch(error => {
            console.error('Error fetching user profile:', error);
        });
    }

    showModalBox() {
    console.log('Create Lead button clicked');

    this[NavigationMixin.GenerateUrl]({
        type: 'standard__navItemPage',
        attributes: {
            apiName: 'Lead_Creation_New'
        }
    })
    .then(url => {
        console.log('Lead Creation URL:', url);
        window.open(url, '_blank');
    })
    .catch(error => {
        console.error('Error opening Lead Creation Page:', error);
    });
}
    // showModalBox() {
    //     // Implement your modal box logic here
    //     console.log('Create Lead button clicked');

    //     // if(this.isDesktop){
    //         console.log('71');
    //         this.showleadpage = true;
    //    // }
    //     /*else{console.log('73');
    //         if(this.appName == 'LOS Portal' || this.appName == 'Direct Business Hub'){
    //             console.log('75');
    //             this[NavigationMixin.Navigate]({
    //                 type: 'standard__navItemPage',
    //                 attributes: {
    //                     apiName: 'Lead_Creation_Page' // The API Name of your custom Lightning Page
    //                 },
    //             });
    //         }
    //         else{
    //             console.log('83');
    //             this[NavigationMixin.Navigate]({
    //                 type: 'standard__webPage',
    //                 attributes: {
    //                     url: '/losportal/s/leadmobile'
    //                 }
    //             });
    //         }
    //     }*/
    // }

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
    }

    handlebulkClose(event){
        console.log('41');
        this.bulkImports = false;
    }
     downloadSampleCSV() {
    this.isSpinner = true;
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
          this.isSpinner = false;
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
          const sanitizedUserName = this.userName.replace(/\s+/g, "_").replace(/[^\w\-]/g, "");
          const fileName = `${sanitizedUserName}_${formattedDateTime}.csv`;
          downloadElement.download = fileName;
          document.body.appendChild(downloadElement);
          downloadElement.click();

          //
          this.isSpinner = false;
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
        this.isSpinner = false;
      });

    // Prepare a html table

    var csvHeader =
      '"SF Case Id","Origin","Case Source","Case Category","Case Type","LMS Loan Number"\n';
    csvHeader +=
      '"5009H000008WCFzQAO","Email","Customer","Complaint","Deliverables","LNABH00317-180061308"\n';
  }
}