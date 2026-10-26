import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getApplicants from "@salesforce/apex/COMM_ItrScreenController.getApplicants";
import checkIfAlreadyFetched from "@salesforce/apex/GSTAuthenticationController.checkIfAlreadyFetched";
import getIfAlreadyFetched from "@salesforce/apex/GSTAuthenticationController.getIfAlreadyFetched";
import getGSTNumbers from "@salesforce/apex/GSTAuthenticationController.getGSTNumbers";
import initiateAPIRequest from "@salesforce/apex/GSTAuthenticationController.initiateAPIRequest";
import initiateAPIRequestSearch from "@salesforce/apex/GSTSearchController.initiateAPIRequest";
import getPanNumber from "@salesforce/apex/GSTAuthenticationController.getPanNumber";
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';


export default class FdaCmp extends LightningElement {
    @api recordId;
    @track options = [];
    @track applicantValue = '';
    @track hasData = false;
    @track gstNumber = '';
    @track spinner = false;
    @track jsonData = {};
    @track gstOptions = [];
    @track adadr = [];
    @track pradr = [];
    @track isGSTNumber = true;
    @track panNumber = '';
    @track hideButton = false;

   

    connectedCallback(){
        this.getApplicantPickList();
        this.checkCmpEditability();
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
            //this.applicantValue = this.options[0].value;
            //console.log("applicantValue" + this.applicantValue);
            //this.getApplicantRecord();
          })
          .catch((error) => {});
    }

    handleApplicantChange(event) {
        this.applicantValue = event.target.value;
        this.spinner = true;
        this.getGSTs();
    }

    handleGSTChange(event) {
        this.gstNumber = event.target.value;
    }
    getGSTs() {
        getGSTNumbers({
          recordId: this.recordId,
          applicantId : this.applicantValue
        })
          .then((response) => {
            console.log("gst res wrap" + JSON.stringify(response));
            if(response.isGSTPresent) {
                if(response.gstOptions.length > 0) {
                    for (let key in response.gstOptions) {
                        console.log("customer details=:" + response[key]);
                        this.gstOptions = [
                            ...this.gstOptions,
                            {
                                label: response.gstOptions[key],
                                value: response.gstOptions[key],
                            },
                        ];
                    }
                    console.log("gstOptions" + this.gstOptions);
                    this.isGSTNumber = true;
                    this.gstNumber = this.gstOptions[0].value;
                    this.spinner = false;
                }else {
                    this.isGSTNumber = true;
                    this.showToast("Error", "NO GST number found for this applicant.", "error");
                    this.spinner = false;
                }
            }else {
                getPanNumber({
                    applicantId : this.applicantValue
                  })
                    .then((response) => {
                      console.log("pan response" + JSON.stringify(response));
                      if(response == 'Fail') {
                        this.showToast("Error", "NO PAN number found for this applicant.", "error");
                        this.panNumber = '';
                      }else {
                        this.panNumber = response;
                      }
                    })
                    .catch((error) => {
                        console.log("error pan response" + JSON.stringify(error));
                    });
                this.isGSTNumber = false;
            }
            
            this.spinner = false;
            
          })
          .catch((error) => {
            console.log("gst error=:" + JSON.stringify(error));
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

    fetchShopDataAPI() {
        this.spinner = true;
        if (this.gstNumber == "" || this.gstNumber == null) {
            this.showToast("Error", "Please select gst number.", "error");
            return;
        }
        if(this.applicantValue == "" || this.applicantValue == null) {
            this.showToast("Error", "Please select applicant.", "error");
            return;
        } 
        this.isAlreadyFetched();
    }

    isAlreadyFetched() {
        checkIfAlreadyFetched({
            recordId: this.recordId,
            applicantId : this.applicantValue,
            gstinNumber : this.gstNumber
          })
            .then((response) => {
              console.log("is getched" + JSON.stringify(response));
              if(response == true) {
                this.showToast("Error", "Data already fetched.", "error");
                this.getDataIfAlreadyFetched();
              }else {
                this.initiateAPIRequest();
              }
            })
            .catch((error) => {

            });
    }
    getDataIfAlreadyFetched() {
        getIfAlreadyFetched({
            recordId: this.recordId,
            applicantId : this.applicantValue,
            gstinNumber : this.gstNumber
          })
            .then((response) => {
              console.log("is getched" + JSON.stringify(response)); 
              if(response != null) {
                try{
                this.jsonData = response; 
                this.adadr = this.jsonData.result.adadr;
                console.log('this.adadr ',this.adadr);
                this.adadr.forEach(item => {
                    if (!('addr' in item)) {
                        item['addr'] = ''; // Assign empty string if property doesn't exist
                    }
                    if (!('lastUpdatedDate' in item)) {
                        item['lastUpdatedDate'] = ''; // Assign empty string if property doesn't exist
                    }
                });
               
                
            }catch(e) {
                console.log(e.message)
            }
                    
                this.spinner = false;
                this.hasData = true;
              }else {
                this.spinner = false;
                this.hasData = false;
                this.showToast("Error", "No information fetched.", "error");
              }
             
            })
            .catch((error) => {
                this.showToast("Error", error, "error");
            });
    }
    initiateAPIRequest() {
        const inputMap = {
            loanId: this.recordId,
            processName: "GST Authentication",
            applicantId: this.applicantValue,
            gstNumber: this.gstNumber
          };
          console.log("inputMap initiateAPIRequestPanValidation-->" +JSON.stringify(inputMap));
          initiateAPIRequest({
            inputMap: inputMap,
          })
            .then((response) => {
             console.log(response);
              if(response == 'success') {
                this.showToast(
                  "Success",
                  "API executed successfully!.",
                  "success"
                );
                this.getDataIfAlreadyFetched();
                return;
              }else {
                this.showToast(
                  "Error",
                  response,
                  "error"
                );
                this.spinner = false;
                this.hasData = false;
                return;
              }
              if (response.includes("Error:")) {
                console.log("response--", response.split(":")[1]);
                var temp = response.split(":")[1];
                this.errorList = temp.split(",");
                this.showToast("Error", this.errorList, "error");
              } else {
                this.showToast(
                  "Success",
                  "API executed successfully!.",
                  "success"
                );
              }
            })
            .catch((error) => {
              console.error(
                "error initiateAPIRequestPanValidation --> " +
                  JSON.stringify(error)
              );
            });
    }

    getGSTNumber() {
        this.spinner = true;
        if (this.panNumber == "" || this.panNumber == null) {
            this.showToast("Error", "No PAN number found for this applicant.", "error");
            this.spinner = false;
            return;
        }
        if (this.applicantValue == "" || this.applicantValue == null) {
            this.showToast("Error", "Please select applicant.", "error");
            this.spinner = false;
            return;
        }

        //
        const inputMap = {
            loanId: this.recordId,
            processName: "GST Search",
            applicantId: this.applicantValue,
            panNumber: this.panNumber
        };
        console.log("inputMap initiateAPIRequestgstsearch-->" + JSON.stringify(inputMap));
        initiateAPIRequestSearch({
                inputMap: inputMap,
            })
            .then((response) => {
                console.log(response);
                if (response == 'success') {
                    this.showToast(
                        "Success",
                        "API executed successfully!.",
                        "success"
                    );
                    this.getGSTs();
                    this.spinner = false;
                    return;
                } else {
                    this.showToast(
                        "Error",
                        response,
                        "error"
                    );
                    this.spinner = false;

                    return;
                }
                if (response.includes("Error:")) {
                    console.log("response--", response.split(":")[1]);
                    var temp = response.split(":")[1];
                    this.errorList = temp.split(",");
                    this.showToast("Error", this.errorList, "error");
                } else {
                    this.showToast(
                        "Success",
                        "API executed successfully!.",
                        "success"
                    );
                }
            })
            .catch((error) => {
                this.spinner = false;
                console.error(
                    "error initiateAPIRequestPanValidation --> " +
                    JSON.stringify(error)
                );
            });
    }

}