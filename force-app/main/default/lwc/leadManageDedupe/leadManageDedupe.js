import { LightningElement, track,api,wire } from 'lwc';
import USER_ID from "@salesforce/user/Id";
import FORM_FACTOR from '@salesforce/client/formFactor';
import pushNotification from '@salesforce/apex/LeadService.pushNotification';
import createTask from '@salesforce/apex/Comm_LeadUtility.createTask';
import { updateRecord } from "lightning/uiRecordApi";
import fetchLeadDetails from '@salesforce/apex/Comm_LeadUtility.fetchLeadDetails';
import { NavigationMixin } from 'lightning/navigation';
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated';

export default class LeadManageDedupe extends  NavigationMixin(LightningElement){

    @api dialogTitle = 'Existing lead found';
    @api leadname;
    @api recordId;
    @api leadId;
    @api dialogMessage;
    @api dialogMessageNonDuplicateUser;
    @api messageNonDuplicateUser;
    @api type;
    @track small=false;
    isHLLead = false; //added by Kunal Bisht for SFHL-980
    @api selectedProduct; //added by Kunal Bisht for SFHL-980

    recordpage = false;
    recordIdpresentandmob=false;
    referenceleadId;
    currentUser;
    activeLeadInfo;
    lead;
    message;
    userMatched = false;
    line;
    teleSales = true;
    teleSalesUser;
    salesUser;
    isHLUser= false;

    connectedCallback() {
        this.checkIfLoggedInUserIsHLRelated();
        if (FORM_FACTOR == 'Small') {
            this.small = true;
        }

        console.log('leadId ' + this.leadId);
        console.log('recordId ' + this.recordId);
        console.log('USER_ID '+USER_ID);
        this.currentUser = USER_ID;
        console.log('leadname ' + this.leadname);
        this.getActiveLeadDetailsData();
        console.log('recordpage - connected callback ' + this.recordpage);
        console.log('type - connected callback' + this.type);
        //changes by Kunal Bisht for SFHL-980 - start
        if(this.selectedProduct === 'Home Loan'){
            this.isHLLead = true;
        }
        //changes by Kunal Bisht for SFHL-980 - end
    }

    checkIfLoggedInUserIsHLRelated(){
        checkIfLoggedInUserIsHLRelated()
        .then(result => {
            this.isHLUser = result.isHLRelated;
        })
        .catch(error => {
            console.log('error-->',error);
        })
    }

    getActiveLeadDetailsData() {
        fetchLeadDetails({ leadId: this.recordId, processName: 'ManageDedupe' })
        .then(result => {
            console.log('ManageDedupe: ', result);

            if (result) {
                const leadData = result[0];
                this.salesUser = leadData.Assigned_Sales_User__c;
                this.owner = leadData.OwnerId;
                this.lead = leadData.Lead_Number__c;

                // Check if current user matches any of the roles
                if ([this.salesUser, this.owner].includes(this.currentUser)) {
                    console.log('User matched with assigned roles.');
                    this.userMatched = true;
                }
                else {
                    console.log('User did not match. Sending notification and creating task.');
                    this.sendNotificationAndTask();
                }

                console.log('recordpage ' + this.recordpage);
                this.dialogMessage = 'You already have an existing lead'+'  ';
                this.dialogMessageNonDuplicateUser = 'We’re unable to create a new lead as an active lead already exists.'+' ';
                this.messageNonDuplicateUser = 'lead already exists.'
                this.message = ','+' '+ 'click on the button below to navigate to the lead.';
                
                this.line = ' to navigate.';
            } 
            else {
                console.log('No lead details found for the provided record ID.');
            }
        })
        .catch(error => {
            console.error('Error fetching lead details:', error);
        });
    }
    
    sendNotificationAndTask() {
        const userIdToNotify = this.salesUser || this.owner;
    
        if (userIdToNotify) {
            pushNotification({ leadId: this.recordId, userId: userIdToNotify })
            .then(() => {
                console.log(`Notification sent to user: ${userIdToNotify}`);
                return createTask({ leadId: this.recordId });
            })
            .then(() => {
                console.log('Task created successfully.');
            })
            .catch(error => {
                console.error('Error during notification or task creation:', error);
            });
        }
        else {
            console.log('No user available to notify.');
        }
    }
    
    handleOK() {
        console.log('leadId ' + this.leadId);
        console.log('28 referenceleadId ' + this.referenceleadId);
        const okEvent = new CustomEvent('ok');
        this.dispatchEvent(okEvent);
    }
    
    handleYes(event){
        const yesEvent = new CustomEvent('yes');
        this.dispatchEvent(yesEvent);
    }
    navigateToActiveLead() {
        if (this.recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Lead', // Replace 'Lead' with your object API name if different
                    actionName: 'view' // Opens the record in view mode
                }
            });
        } else {
            console.error('No recordId is provided for navigation.');
        }
    }
    updateRecordField(recordId, fieldApiName, fieldValue) {
        const fields = {};
        fields['Id'] = recordId;
        fields[fieldApiName] = fieldValue;
        
        const recordInput = { fields };
        updateRecord(recordInput)
        .then(() => {
            console.log('Record updated successfully');
        })
        .catch(error => {
            console.error('Error updating record: ', error);
            console.log('Error updating record --> '+JSON.stringify(error));
        })
    }

    sendApproval(){
        console.log('Inside send approval');
        
        const yesEvent = new CustomEvent('sendapproval');
        this.dispatchEvent(yesEvent);
    }

    //below method added by Kunal Bisht for SFHL-980
    get showButtons() {
        return this.isHLUser && this.isHLLead;
    }

}