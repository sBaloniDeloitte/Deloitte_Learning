import { LightningElement, api, track } from "lwc";
import parseMultipleResponses from "@salesforce/apex/FSSAITableData.parseMultipleResponses";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getApplicants from "@salesforce/apex/COMM_ItrScreenController.getApplicants";
//Added by Prachi 
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated'
import initiateMCAAPIRequest from "@salesforce/apex/FetchMCAController.initiateAPIRequest";
import getMCARecords from "@salesforce/apex/FetchMCAController.getMCARecords";
import getApplicantsForMCA from "@salesforce/apex/FetchMCAController.getApplicantsForMCA";
//Added By Prachi
import getApplicantData from "@salesforce/apex/COMM_VideoPDController.getApplicantData";
import initiateEmployeeCheck from "@salesforce/apex/EmployeeVerificationController.initiateEmployeeCheck";
import getEmployeeCheckData from "@salesforce/apex/EmployeeVerificationController.getEmployeeCheckData";
import checkIfAlreadyFetch from "@salesforce/apex/FSSAITableData.checkIfAlreadyFetch";
import initiateAPIRequest from "@salesforce/apex/FSSAIAPIController.initiateAPIRequest";
import getAreaCodes from "@salesforce/apex/ShopAndEstablishmentCheckController.getAreaCodes";
import checkIfAlreadyFetchShop from "@salesforce/apex/ShopAndEstablishmentCheckController.checkIfAlreadyFetch";
import getShopExistingData from "@salesforce/apex/ShopAndEstablishmentCheckController.getShopExistingData";
import initiateAPIRequestShop from "@salesforce/apex/ShopAndEstablishmentCheckController.initiateAPIRequest";

export default class OtherIntegrations extends LightningElement {
  hscode = "";
  @api recordId;
  @api hideFssaiControls = false;
  @api hideShopControls = false;
  table;
  @track jsonData = "";
  @track tableData = [];
  @track applicantValue = "";
  @track showEmployeeData = false;
  @track options = [];
  @track applicantName;
  @track applicantMobileNumber;
  @track applicantEmail = "";
  @track employeedetails = [];
  @track selectedUanData = [];
  @track selectedEPFData = [];
  @track formattedUanData = [];
  @track selectedEmployerData = [];
  @track showUAN = false;
  @track showEPF = false;

  @track fssaiNumber = "";
  @track hasFssaiData = false;
  @track areaCodes = [];
  @track shopAndEstNumber = "";
  @track hasShopAndEstData = false;
  @track areaCode = "";
  @track shopAndEstData = [];
  @api hideActions = false;

  //Added by Prachi
   @track applicantOptions = [];
    @track selectedApplicantId;
    @track cinNumber = '';
    @track showFields = false;
    @track mcaData = [];
    @track message = '';
    @track isHLUser= false;
    @track isloading = false;
    @track showInputFields = true;
    //Added by Prachi
  
  connectedCallback() {
    this.getApplicantData();
    this.getEmployeeCheckData();
    this.triggerFssaiAPI();
    this.getAreaCodesList();
    this.getShopData();
    this.checkIfLoggedInUserIsHLRelated();
    this.loadApplicants();
  }
  // --- Cahnges By Prachi Start ---
  get hasApplicants() {
      return this.applicantOptions && this.applicantOptions.length > 0;
  }

  get hasMCAData() {
      return this.mcaData && this.mcaData.length > 0;
  }

  // --- Load Applicants ---
  loadApplicants() {
      getApplicantsForMCA({ loanId: this.recordId })
          .then(result => {
              const data = JSON.parse(result);
              if (data.Applicants && data.Applicants.length > 0) {
                  this.applicantOptions = data.Applicants;
                  this.message = '';
              } else {
                  this.applicantOptions = [];
                  this.message = data.message || 'No Non-Individual Applicant Found.';
              }
          })
          .catch(error => {
              console.error('Error fetching applicants:', error);
              this.applicantOptions = [];
              this.message = 'Error loading applicants.';
          });
  }

// --- Handle Applicant Change ---
  handleApplicantChangeMCA(event) {
      this.selectedApplicantId = event.detail.value;
      this.mcaData = [];
      this.showTable = false;
      this.showFields = true;

      if (this.selectedApplicantId) {
          const selectedApp = this.applicantOptions.find(app => app.value === this.selectedApplicantId);
          this.cinNumber = selectedApp ? selectedApp.CIN : '';
          this.loadMCARecords(); // 🔁 Load data for the selected applicant
      }
  }

  // --- Load MCA Records ---
  loadMCARecords() {
      getMCARecords({
          loanId: this.recordId,
          processName: 'Loan MCA Verification',
          applicantId: this.selectedApplicantId
      })
      .then((result) => {
          const parsed = JSON.parse(result);

          if (parsed.error) {
              this.showToast('Error', parsed.error, 'error');
              this.mcaData = [];
              return;
          }

          // ✅ If data found, show both fields + table
          if (parsed.MCA_Result && parsed.MCA_Result.length > 0) {
              this.mcaData = parsed.MCA_Result;
              this.showToast('Success', 'MCA Data Loaded Successfully', 'success');
          } else {
              this.mcaData = [];
              this.showToast('Info', 'No MCA Data Found for selected applicant.', 'info');
          }
      })
      .catch((error) => {
          console.error('⚠️ Error fetching MCA records:', error);
          this.showToast('Error', 'Error fetching MCA records: ' + error.body?.message, 'error');
          this.mcaData = [];
      });
  }

  // --- Handle CIN Input ---
  handleCINChange(event) {
      this.cinNumber = event.target.value.trim();
      const pattern = /^[LU][0-9]{5}[A-Z]{2}[0-9]{4}[A-Z]{3}[0-9]{6}$/;

      // Check pattern validity
      if (this.cinNumber && !pattern.test(this.cinNumber)) {
          event.target.setCustomValidity('Please enter a valid CIN (e.g., L12345MH2020PLC012345)');
      } else {
          event.target.setCustomValidity(''); // clear previous error
      }

      event.target.reportValidity(); // show error immediately
  }

  // --- Handle Fetch MCA Button ---
  handleFetchMCA() {
      this.isloading = true;

      const inputMap = {
          applicantId: this.selectedApplicantId,
          cinNumber: this.cinNumber ? this.cinNumber.trim() : '',
          loanId: this.recordId,
          processName: 'Loan MCA Verification'
      };

      initiateMCAAPIRequest({ inputMap })
          .then(result => {
              this.isloading = false;

              // Parse response safely
              let response = typeof result === 'string' ? JSON.parse(result) : result;
              console.log('MCA API Response:', JSON.parse(JSON.stringify(response)));

              this.mcaData = [];
              const statusCode = response['status-code'] || response.status_code || response.status || '';

              switch (statusCode) {
                  case '101':
                      // --- Normalize result fields ---
                      if (response.result && Array.isArray(response.result)) {
                          this.mcaData = response.result.map(item => {
                              const normalizedItem = {};
                              Object.keys(item).forEach(key => {
                                  // Convert special chars like '/', spaces, and '-' to underscores
                                  const safeKey = key.replace(/[\/\s-]/g, '_');
                                  normalizedItem[safeKey] = item[key];
                              });
                              return normalizedItem;
                          });
                      } else if (response.result && typeof response.result === 'object') {
                          // Handle single object case
                          const normalizedItem = {};
                          Object.keys(response.result).forEach(key => {
                              const safeKey = key.replace(/[\/\s-]/g, '_');
                              normalizedItem[safeKey] = response.result[key];
                          });
                          this.mcaData = [normalizedItem];
                      }

                      this.showToast('Success', 'MCA data fetched successfully.', 'success');
                      break;

                  case '102':
                      this.showToast('Error', 'Invalid ID number or combination of inputs.', 'error');
                      break;

                  case '103':
                      this.showToast('Warning', 'No records found for the given ID or combination of inputs.', 'warning');
                      break;

                  case '104':
                      this.showToast('Error', 'Maximum retries exceeded. Please try again later.', 'error');
                      break;

                  case '105':
                      this.showToast('Error', 'Missing consent for MCA check.', 'error');
                      break;

                  case '106':
                      this.showToast('Warning', 'Multiple records exist for the given details.', 'warning');
                      break;

                  case '107':
                      this.showToast('Warning', 'This request type is not supported by MCA service.', 'warning');
                      break;

                  case '108':
                      this.showToast('Error', 'Internal resource unavailable. Please try again later.', 'error');
                      break;

                  case '109':
                      this.showToast('Warning', 'Too many records found for the given details.', 'warning');
                      break;

                  default:
                      if (response.status === 'error') {
                          this.showToast('Error', response.message || 'Error returned from MCA API.', 'error');
                      } else {
                          this.showToast('Warning', 'Unexpected MCA response received.', 'warning');
                      }
                      break;
              }

              console.log('Normalized MCA Data:', JSON.parse(JSON.stringify(this.mcaData)));
          })
          .catch(error => {
              this.isloading = false;
              console.error('Error fetching MCA:', error);
              this.mcaData = [];
              this.showToast('Error', 'Error fetching MCA data.', 'error');
          });
  }

    // --- Toast Utility ---
  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  checkIfLoggedInUserIsHLRelated(){
        checkIfLoggedInUserIsHLRelated()
        .then(result => {
            this.isHLUser = result.isHLRelated;
            console.log('isHLUser-->',this.isHLUser);
        })
        .catch(error => {
            console.log('error-->',error);
        })
  }

    //Changes Added By Prachi End


  handleShopCodeChange(event) {
    this.shopAndEstNumber = event.target.value;
  }

  handlefssaiCodeChange(event) {
    this.fssaiNumber = event.target.value;
  }

  getFSSAIData() {
    if (this.fssaiNumber == "" || this.fssaiNumber == null) {
      this.showToast("Error", "Please enter licence number.", "error");
      return;
    }

    checkIfAlreadyFetch({
      loanId: this.recordId,
      fssaiNumber: this.fssaiNumber,
    })
      .then((result) => {
        if (result) {
          this.showToast(
            "Error",
            "You have already fetched this firm information.",
            "error"
          );
          return;
        } else {
          const inputMap = {
            loanId: this.recordId,
            processName: "FSSAI",
            registrationNumber: this.fssaiNumber,
          };
          console.log("inputMap initiateAPIRequestPanValidation-->" +JSON.stringify(inputMap));
          initiateAPIRequest({
            inputMap: inputMap,
          })
            .then((response) => {
              console.log('response----', response);
              
              if(response == 'success') {
                this.showToast(
                  "Success",
                  "API executed successfully!.",
                  "success"
                );
                this.triggerFssaiAPI();
                return;
              }else {
                this.showToast(
                  "Error",
                  response,
                  "error"
                );
                this.triggerFssaiAPI();
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
                this.triggerFssaiAPI();
              }
            })
            .catch((error) => {
              console.error(
                "error initiateAPIRequestPanValidation --> " +
                  JSON.stringify(error)
              );
            });
        }
      })
      .catch((error) => {
        this.showToast("Error", error, "error");
        console.error("Error calling Apex:", error);
      });
  }

  triggerFssaiAPI() {
    parseMultipleResponses({ loanId: this.recordId, Name: "FSSAI" })
      .then((result) => {
        console.log('resulttt----', result);
        console.log('resultJSON---', JSON.stringify(result));
        
        
        if (result.length > 0) {
          this.hasFssaiData = true;
          this.tableData = result; // Store response in tableData
        } else {
          this.hasFssaiData = false;
          //this.showToast("Error", "No data found.", "error");
        }
      })
      .catch((error) => {
        this.showToast("Error", error, "error");
        console.error("Error calling Apex:", error);
      });
  }
  handleAreaCodeChange(event) {
    this.areaCode = event.detail.value;
    console.log("areaCode", this.areaCode);
  }

  fetchShopDataAPI() {
    if (this.shopAndEstNumber == "" || this.shopAndEstNumber == null) {
      this.showToast("Error", "Please enter s number.", "error");
      return;
    }
    if (this.areaCode == "" || this.areaCode == null) {
      this.showToast("Error", "Please select area.", "error");
      return;
    }
    checkIfAlreadyFetchShop({
      loanId: this.recordId,
      shopAndEstNumber: this.shopAndEstNumber,
    })
      .then((result) => {
        if (result) {
          this.showToast(
            "Error",
            "You have already fetched this firm information.",
            "error"
          );
          return;
        } else {
          const inputMap = {
            loanId: this.recordId,
            processName: "Shop & Establishment",
            registrationNumber: this.shopAndEstNumber,
            areaCode: this.areaCode,
          };
          console.log("inputMap initiateAPIRequestPanValidation-->" +JSON.stringify(inputMap));
          initiateAPIRequestShop({
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
                this.getShopData();
                return;
              }else {
                this.showToast(
                  "Error",
                  response,
                  "error"
                );
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
                this.getShopData();
              }
            })
            .catch((error) => {
              console.error(
                "error initiateAPIRequestPanValidation --> " +
                  JSON.stringify(error)
              );
            });
        }
      })
      .catch((error) => {
        this.showToast("Error", error, "error");
        console.error("Error calling Apex:", error);
      });
  }

  getShopData() {
    getShopExistingData({ loanId: this.recordId, name: "Shop & Establishment" })
      .then((result) => {
        if (result.length > 0) {
          this.hasShopAndEstData = true;
          this.shopAndEstData = result; // Store response in tableData
          console.log('this.shopAndEstData--',JSON.stringify(this.shopAndEstData));
        } else {
          this.hasShopAndEstData = false;
          //this.showToast("Error", "No data found.", "error");
        }
      })
      .catch((error) => {
        this.showToast("Error", error, "error");
        console.error("Error calling Apex:", error);
      });
  }

  getAreaCodesList() {
    getAreaCodes({ activityName : 'Shop & Establishment'})
      .then((response) => {
        for (let key in response) {
          this.areaCodes = [
            ...this.areaCodes,
            {
              label: response[key],
              value: key,
            },
          ];
        }
      })
      .catch((error) => {});
  }

  get hasData() {
    return this.tableData.length > 0;
  }
  showToast(title, message, variant) {
    const toastEvent = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
    });
    this.dispatchEvent(toastEvent);
  }

  getEmployeeCheckData() {
    getEmployeeCheckData({
      loanId: this.recordId,
    })
      .then((response) => {

        this.employeedetails = response;
        if (this.employeedetails.length > 0) {
          this.showEmployeeData = true;
        }
      })
      .catch((error) => {
        console.log("error in getEmployeeCheckData---", error);
      });
  }
  getApplicantData() {
    getApplicants({
      recordId: this.recordId,
    })
      .then((response) => {
        //this.options = [... this.options,{label:'All',value:'All'}];
        for (let key in response) {
          this.options = [
            ...this.options,
            {
              label: response[key],
              value: key,
            },
          ];
        }
        this.applicantValue = this.options[0].value;
        this.getApplicantRecord();
      })
      .catch((error) => {});
  }

  getApplicantRecord() {
    getApplicantData({
      applicantId: this.applicantValue,
    })
      .then((response) => {
        console.log("getItrRecords CY " + JSON.stringify(response));
        this.applicantName = response.applicantName;
        this.applicantMobileNumber = response.applicantMobileNumber;
      })
      .catch((error) => {});
  }

  handleApplicantChange(event) {
    this.applicantValue = event.target.value;
    this.getApplicantRecord();
  }

  handleApplicantMobileChange(event) {
    console.log("event in handleApplicantMobileChange" + event.target.value);
    this.applicantMobileNumber = event.target.value;
  }

  handleApplicantEmailChange(event) {
    console.log("event in handleApplicantEmailChange" + event.target.value);
    this.applicantEmail = event.target.value;
  }

  handleEmployeeClick() {
    if (
      this.applicantName == null ||
      this.applicantName == "" ||
      this.applicantName == undefined
    ) {
      this.showToast("Error", "Please check applicant name", "error");
      return;
    }

    if (this.applicantMobileNumber.length != 10) {
      this.showToast("Error", "Please check applicant mobile number", "error");
      return;
    }

    const wrapperData = {
      loanId: this.recordId,
      applicantId: this.applicantValue,
      applicantName: this.applicantName,
      applicantEmail: this.applicantEmail,
      applicantMobile: this.applicantMobileNumber,
      processName: "Loan Employment Check",
    };

    const inputMap = new Map(Object.entries(wrapperData));

    initiateEmployeeCheck({
      inputMap: JSON.stringify(wrapperData),
    })
      .then((response) => {
        if (response == "success") {
          this.getEmployeeCheckData();
        } else {
          this.showToast("Error", "Please check with the admin", "error");
        }
      })
      .catch((error) => {
        this.showToast("Error", "Please check with the admin", "error");
      });
  }

  openUANPopup(event) {
    const requestId = event.target.dataset.id;
    const selectedEmployee = this.employeedetails.find(
      (emp) => emp.request_id === requestId
    );


    if (selectedEmployee?.result?.uan) {
      // this.selectedUanData = selectedEmployee.result.uan;
      // this.processUanData();
      this.selectedEmployerData = selectedEmployee.result.employerList;
    }
    this.showUAN = true;
  }

  processUanData() {
   
    let formattedList = [];
    if (this.selectedUanData) {
      this.selectedUanData.forEach((uanRecord) => {
        let employerList = uanRecord.employer;
        let firstEntry = true;

        employerList.forEach((emp) => {
          formattedList.push({
            key: `${uanRecord.uan}-${emp.memberId}`,
            uan: uanRecord.uan,
            name: emp.name,
            isNameExact: emp.isNameExact,
            nameConfidence: emp.nameConfidence,
            uanNameMatch: emp.uanNameMatch,
            showUAN: firstEntry, // Show UAN only for the first employer
            rowspan: employerList.length, // Rowspan for UAN column
          });
          firstEntry = false; // Set to false after first entry
        });
      });
    }
    this.formattedUanData = formattedList;
    
  }

  openEPFPopup(event) {
    const requestId = event.target.dataset.id;

    const selectedEmployee = this.employeedetails.find(
      (emp) => emp.request_id === requestId
    );

    if (selectedEmployee?.result?.uan) {
      this.selectedEPFData = selectedEmployee.result.nameLookup.epfHistory;
      this.showEPF = true;
    }
  }

  closePopup() {
    this.showUAN = false;
    this.showEPF = false;
  }
}