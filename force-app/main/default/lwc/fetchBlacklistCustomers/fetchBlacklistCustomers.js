import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import fetchBlackListCustomers from '@salesforce/apex/BlacklistCustomerController.fetchBlackListCustomers';
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import APPROVAL_STATUS from "@salesforce/schema/Opportunity.Approval_Status__c";
import STAGENAME_FIELD from "@salesforce/schema/Opportunity.StageName";
import OWNERID_FIELD from "@salesforce/schema/Opportunity.OwnerId";
import USER_ID from "@salesforce/user/Id";
import ProfileName from '@salesforce/schema/User.Profile.Name';
import { getRecord } from "lightning/uiRecordApi";

export default class FetchBlacklistCustomers extends LightningElement {


    @api recordId;
    isLoading = false;
    isDisabled = true;
    firstTimeLoaded = true;

    toastTitle = {
        SUCCESS: "Success",
        ERROR: 'Error'
    }
    toastVariant = {
        SUCCESS: "success",
        ERROR: "error"
    }
    toastMessages = {
        RECORDS_RETRIVAL_SUCCESSFULL : "Matching Record(s) retrieved Successfully.",
        RECORDS_RETRIVAL_UNSUCCESSFULL : "Error occured during retrieval of one or more applicant(s).",
        SOMETHING_WENT_WRONG : "Something went wrong. Please try later."
    }
    hideButton = false;
    userProfile = '';
    isNotEditable = false;

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
            var approvalStatus = data.fields.Approval_Status__c.value;
            var StageName = data.fields.StageName.value;
            var OwnerId = data.fields.OwnerId.value;

            if(StageName === 'Credit Underwriting'){
                console.log('this.userProfile: '+this.userProfile);
                if(this.userProfile != 'System Administrator' && OwnerId != USER_ID){
                    this.hideButton = true;
                }
            }

            // console.log('approvalStatus>>'+approvalStatus);
            // if(oppSubStage === 'Disbursed' || ['Hard Rejected', 'Soft Rejected 1', 'Soft Rejected 2'].includes(approvalStatus)) {
            //     this.hideButton = true;
            // }
        }
    }

    connectedCallback(){
       // this.checkEditability();
    }

   

    renderedCallback() {
        if(this.firstTimeLoaded){
            console.log(this.firstTimeLoaded);
            this.firstTimeLoaded = false;
        }
     }


    async fetchDuplicateCustomers(){
        this.isLoading = true;
        try{
           const result = await fetchBlackListCustomers({  loanId : this.recordId });
            console.log(result);
            if(result.length > 1){
                this.showToast(this.toastTitle.ERROR, this.toastMessages.RECORDS_RETRIVAL_UNSUCCESSFULL, this.toastVariant.ERROR);
            }else{
                this.showToast(this.toastTitle.SUCCESS, this.toastMessages.RECORDS_RETRIVAL_SUCCESSFULL, this.toastVariant.SUCCESS);
            }
            this.isLoading = false;
        }catch(error){
            this.isLoading = false;
            this.showToast(this.toastTitle.ERROR, this.toastMessages.SOMETHING_WENT_WRONG, this.toastVariant.ERROR);
        }
        
    }

    showToast(title, msg, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: msg,
                variant: variant,
            }),
        )
    }

}