import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getAreaCodes from "@salesforce/apex/ShopAndEstablishmentCheckController.getAreaCodes";
import checkIfAlreadyFetchShop from "@salesforce/apex/FDAController.checkIfAlreadyFetch";
import initiateAPIRequestShop from "@salesforce/apex/FDAController.initiateAPIRequest";
import getFDAData from "@salesforce/apex/FDAController.getFDADataDummy";
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
export default class FdaCmp extends LightningElement {
    @api recordId;
    @track licenceNumber = '';
    @track areaCode = '';
    @track hasData = false;
    @track shopAndEstData = [];
    @track areaCodes = [];


     @track hideButton = false;

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
        this.getAreaCodesList();
        this.getFDAInfo();
        this.checkCmpEditability();
    }

    /* Line-format restyle for the Licence Number / State fields - converts
       the boxed dark fields (and the boxed red error state) to
       underline-only. The pure-CSS ::part()/custom-property attempts
       already in fdaCmp.css were not reliably reaching this org's
       rendering, so the style is injected the same proven way already
       used on the other sales-login screens. This method is fully
       self-contained and does not touch connectedCallback or any other
       lifecycle/data logic. */
    isRendered = false;
    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            const style = document.createElement('style');
            style.innerText = `
                .fda-field .slds-input,
                .fda-field .slds-combobox__input {
                    background-color: transparent !important;
                    color: #ffffff !important;
                    border: none !important;
                    border-bottom: 1px solid #33455e !important;
                    border-radius: 0 !important;
                    box-shadow: none !important;
                    outline: none !important;
                    padding: 6px 20px 6px 2px !important;
                    transition: none !important;
                }
                .fda-field .slds-input:hover,
                .fda-field .slds-input:active,
                .fda-field .slds-combobox__input:hover,
                .fda-field .slds-combobox__input:active {
                    background-color: transparent !important;
                    border: none !important;
                    border-bottom: 1px solid #33455e !important;
                    box-shadow: none !important;
                }
                .fda-field .slds-input:focus,
                .fda-field .slds-combobox__input:focus {
                    background-color: transparent !important;
                    border: none !important;
                    border-bottom: 1px solid #60a5fa !important;
                    box-shadow: none !important;
                }
                /* Error/required-not-filled state - SLDS draws this as a
                   full red box by default; keep it a red underline only. */
                .fda-field.slds-has-error .slds-input,
                .fda-field.slds-has-error .slds-combobox__input {
                    background-color: transparent !important;
                    border: none !important;
                    border-bottom: 2px solid #ff4d6d !important;
                    box-shadow: none !important;
                }
                .fda-field .slds-form-element__label {
                    color: #ffffff !important;
                }
                .fda-field .slds-required {
                    color: #ff4d6d !important;
                }
            `;
            const container = this.template.querySelector('.styleContainer');
            if (container) {
                container.appendChild(style);
            }
        }
    }

    getAreaCodesList() {
        getAreaCodes({activityName:"FDA"})
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

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
          title: title,
          message: message,
          variant: variant,
        });
        this.dispatchEvent(toastEvent);
      }

      handleShopCodeChange(event) {
        this.licenceNumber = event.target.value;
      }

      handleAreaCodeChange(event){
        this.areaCode = event.detail.value;
      }

      fetchShopDataAPI(event) {
        if (this.licenceNumber == "" || this.licenceNumber == null) {
          this.showToast("Error", "Please enter licence number.", "error");
          return;
        }
        if (this.areaCode == "" || this.areaCode == null) {
          this.showToast("Error", "Please select state.", "error");
          return;
        }
        checkIfAlreadyFetchShop({
          loanId: this.recordId,
          licenceNumber: this.licenceNumber,
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
                processName: "FDA",
                registrationNumber: this.licenceNumber,
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
                    this.getFDAInfo();
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

      getFDAInfo() {
        getFDAData({ loanId: this.recordId, name: "FDA" })
          .then((result) => {
            if (result.length > 0) {
              this.hasData = true;
              this.shopAndEstData = result; // Store response in tableData
              console.log('this.shopAndEstData--',JSON.stringify(this.shopAndEstData));
            } else {
              this.hasData = false;
              this.showToast("Error", "No data found.", "error");
            }
          })
          .catch((error) => {
            this.showToast("Error", error, "error");
            console.error("Error calling Apex:", error);
          });
      }
}