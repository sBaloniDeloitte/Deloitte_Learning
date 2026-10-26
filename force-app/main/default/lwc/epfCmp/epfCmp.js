import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getApplicants from "@salesforce/apex/COMM_ItrScreenController.getApplicants";
import getUANNumber from "@salesforce/apex/EPFController.getUANNumber";
import checkAndHitApi from "@salesforce/apex/EPFController.checkAndHitApi";
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
export default class FdaCmp extends LightningElement {
    @api recordId;
    @track options = [];
    @track applicantValue = '';
    @track hasData = false;
    @track uanNumber = '';
    @track spinner = false;
    @track jsonData = {};
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
   

    connectedCallback(){
        this.getApplicantPickList();
        this.checkCmpEditability();

        //c/addBankAccountCmp

        //this.showToast("Error", "Please enter licence number.", "error");
    }


    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
          title: title,
          message: message,
          variant: variant,
        });
        this.dispatchEvent(toastEvent);
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
        this.getUAN();
    }

    getUAN() {
        getUANNumber({
            applicantId: this.applicantValue,
        })
          .then((response) => {
            console.log("customer details=:" + JSON.stringify(response));
            if(response != null) {
                this.uanNumber = response;
                this.spinner = false;
            }else {
                this.showToast("Error", "Applicant UAN number is blank.", "error");
                this.spinner = false;
            }
            this.hasData = false;
          })
          .catch((error) => {
            this.showToast("Error", error, "error");
            this.spinner = false;
          });
    }

    fetchShopDataAPI() {
        this.spinner = true;
        if (this.uanNumber == "" || this.uanNumber == null) {
            this.showToast("Error", "Please enter UAN number of selected applicant..", "error");
             return;
        }
        checkAndHitApi({
            recordId : this.recordId,
            uanNumber : this.uanNumber,
            applicantId: this.applicantValue,
        })
          .then((response) => {
            console.log("customer details=:" + JSON.stringify(response));
            if(response != null) {
                this.jsonData = response;
                this.employers = this.jsonData.result.employers.map(emp => ({
                    ...emp,
                    city: emp.address.city,
                    state: emp.address.state,
                    pincode: emp.address.pincode
                }));
                this.spinner = false;
                this.hasData = true;
            }else {
                this.showToast("Error", response, "error");
                this.spinner = false;
            }
            
          })
          .catch((error) => {
            this.showToast("Error", error, "error");
            this.spinner = false;
          });
    }

    
}