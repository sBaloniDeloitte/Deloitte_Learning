import { LightningElement, track, api } from "lwc";
import saveFile from "@salesforce/apex/BulkUpsertRecordScreenController.saveFile";
import getSampleCSV from "@salesforce/apex/BulkUpsertRecordScreenController.getSampleCSV";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class BulkUpsertRecordScreen extends LightningElement {
  @track isShowModal = true;
  @track fileId;
  @track isSpinner = false;
  @api objectName = "Lead";
  columnHeader = [
    "SF Case Id",
    "Origin",
    "Case Source",
    "Case Category",
    "Case Type",
    "LMS Loan Number",
  ];
  get acceptedFormats() {
    return [".csv"];
  }

  isRendered = false;

  hideModalBox() {
    const valueSelectedEvent = new CustomEvent("closeevent", {});
    this.dispatchEvent(valueSelectedEvent);
  }

  downloadSampleCSV() {}

  submitCsv() {
    if (this.fileId) {
      this.isSpinner = true;
      this.isShowModal = false;
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
            // All records succeeded
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'All records processed successfully.',
                    variant: 'success'
                })
            );
            this.downloadResultCSV(response);
            this.isSpinner = false;
            this.isShowModal = true;
        } else if (successCount > 0 && failureCount > 0) {
            // Some succeeded, some failed
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Partial Success',
                    message: `${successCount} records succeeded, ${failureCount} failed.`,
                    variant: 'warning'
                })
            );
            this.downloadResultCSV(response);
            this.isSpinner = false;
            this.isShowModal = true;
        } else {
            // All records failed
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Failure',
                    message: 'All records failed to process.',
                    variant: 'error'
                })
            );
            this.downloadResultCSV(response);
            this.isSpinner = false;
            this.isShowModal = true;
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

          this.isSpinner = false;
          this.isShowModal = true;
        });
    } else {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: "Please upload csv.",
          variant: "error",
        })
      );
      this.isSpinner = false;
      return;
    }
  }

  handleUploadFinished(event) {
    // Get the list of uploaded files
    const uploadedFiles = event.detail.files;
    console.log("data" + JSON.stringify(uploadedFiles));
    this.fileId = uploadedFiles[0].documentId;
  }

  renderedCallback() {
    console.log("IN CHILD RENDER CALL BACK");
    if (!this.isRendered) {
      console.log("Inside if condition");
      this.isRendered = true;
      const style = document.createElement("style");
      style.innerText = `
            .fileCSV .slds-form-element__label {
                display: none;
            }
            `;
      this.template.querySelector(".styleContainer").appendChild(style);
    }
  }
  @track cTemplateList = {};
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
          downloadElement.download = "Sample_Data.csv";
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
}