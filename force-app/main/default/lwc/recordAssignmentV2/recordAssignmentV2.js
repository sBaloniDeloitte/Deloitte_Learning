/* _______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________ */
import { LightningElement, api, wire } from "lwc";
import assignLead from "@salesforce/apex/RecordAssignmentController.assignLead";
import fetchLeadDetails from '@salesforce/apex/RecordAssignmentController.fetchLeadDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import hasDSAPermission from '@salesforce/customPermission/CP_DSA_Executive';
import getAccountTeamMembers from '@salesforce/apex/RecordAssignmentController.fetchAccountTeamRecords';
import currentUserId from '@salesforce/user/Id';
import { CurrentPageReference } from 'lightning/navigation'; 
import { fireEvent } from 'c/pubsub';
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated'

export default class RecordAssignmentV2 extends LightningElement {
  
    @api recordId;
    @api processName;
    @api showHeaderFooter = false;
    @api headerText = '';
    @api assignBtnTitle = 'Assign';
    filterCriteria = "And TeamMemberRole In ('Sales')";
    cssMain = '';
    showLeadSection = false;
    selectedName = '';
    selectedId = '';
    searchDisabled = false;
    currentAssignedUser = '';
    selectedUserId = '';
    showUserList = false;
    showAssignBtn = false;
    isLoading = false;
    selectedBranchCode = '';
    _pendingBranchReload = false;
    branchQueryFilter="[RecordType.Name = Branch;]";
    @wire(CurrentPageReference) pageRef;
    isHLUser;
    showConfigError = false;

     checkIfLoggedInUserIsHLRelated(){
        checkIfLoggedInUserIsHLRelated()
        .then(result => {
            this.isHLUser = result.isHLRelated;
            if(this.isHLUser){
                this.filterCriteria = "And TeamMemberRole In ('Sales')";
                this.branchQueryFilter = "[RecordType.Name = 'Branch';Branch_Type__c = HUB;ParentId = null;Account.Vertical1__c INCLUDES ('HL')]";
            }else{
                this.branchQueryFilter = "[RecordType.Name = 'Branch';Account.Vertical1__c INCLUDES ('AHL')]";
            }
           
        })
        .catch(error => {
            console.log('error-->',error);
        })
    }

    connectedCallback(){
        console.log('recordId '+this.recordId);
        this.checkIfLoggedInUserIsHLRelated();

        
        
        if(this.showHeaderFooter == true){
            this.cssMain = 'border-field';
        }
        else{
            this.showHeaderFooter = false;
        }

        switch((this.processName || '').trim()) {
            case 'Assign Lead':
                this.showLeadSection = true;

                this.getLeadDetailsData();
                break;
            default:
                console.warn('RecordAssignmentV2: unrecognized processName "' + this.processName + '". Set the "Process Name" property to "Assign Lead" in the page property panel.');
                this.showConfigError = true;
        }
        if(hasDSAPermission){
            this.getAccountTeamMembers();
        }
        registerListener("closeLead", this.updateleaddetails, this);
        registerListener("closeLeadfromedit", this.updateleaddetails, this);
        registerListener("branchReset", this.handleBranchDeselectedFromLead, this);
    }

    handleBranchSelected(event) {
        //console.log('event.detail pincode: '+ JSON.stringify(event.detail));

        const branchRecord = event.detail.searchRecord;

        this.selectedId = branchRecord.Id;
        this.selectedName = branchRecord.Name;
        this.selectedBranchCode = branchRecord.Branch_Code__c;
        this.filterCriteria =  "And TeamMemberRole In ('Sales')"
        this.showUserList = true;
        this.showAssignBtn = false;

        // showUserList just flipped to true, so c-show-record-table has not been
        // rendered into the DOM yet in this synchronous execution. Querying for it
        // here always returns null on the first selection, silently skipping
        // reloadDetails(). Defer the lookup to renderedCallback, once the child
        // element actually exists.
        this._pendingBranchReload = true;
    }

    renderedCallback() {
        if (this._pendingBranchReload) {
            const childComponent = this.template.querySelector('c-show-record-table');

            if (childComponent) {
                childComponent.reloadDetails(this.selectedId);
                this._pendingBranchReload = false;
            }
        }
    }

    getLeadDetailsData() {

        this.isLoading = true;

        return fetchLeadDetails({ leadId: this.recordId, processName: this.processName })
        .then(result => {
            
            if(result) {
                //console.log('Lead result: ', JSON.stringify(result));

                this.currentAssignedUser = result.assignedUserName;
                this.nearestBranchName = result.nearestBranch;
                this.selectedId = result.branchId;
                this.selectedName = result.branchName;
                this.selectedBranchCode = result.branchCode;
                  this.showUserList = true;
                
                if(this.currentAssignedUser){
                    //this.showUserList = false;
                    this.showAssignBtn = false;
                }

                if(result.status == 'Closed'){
                    this.searchDisabled = true;
                }
            }

            this.isLoading = false;
        })
        .catch(error => {
            console.log('leadInfo details error: ' + JSON.stringify(error));
            this.isLoading = false;
        });
    }

    handleBranchDeselected(event) {
        this.selectedId = '';
        this.selectedName = '';
        this.selectedBranchCode = '';
        this.showUserList = false;
        this.showAssignBtn = false;
    }
    handleBranchDeselectedFromLead(){
        this.template.querySelector('c-search-lookup').handleReset();
    }
    handleTableSelected(event) {
        console.log('table selected Id: '+event.detail);

        this.selectedUserId = event.detail;
        this.showAssignBtn = true;
    }

    assignRecord(event) {
        
        this.isLoading = true;

        switch(this.processName) {

            case 'Assign Lead':

                assignLead({ recordId: this.recordId, userId: this.selectedUserId, branchId: this.selectedId })
                .then(result => {
                    
                    if(result) {
                        console.log('assign rec: '+ JSON.stringify(result));
    
                        const event= new ShowToastEvent({
                            title: 'Success!',
                            message: 'Lead assigned successfully!',
                            variant: 'success',
                        });
                        this.dispatchEvent(event);

                        this.showUserList = false;
                        this.showAssignBtn = false;

                        this.getLeadDetailsData().then(() => {
                            fireEvent(this.pageRef, 'leadAssignmentStatus', { isAssigned: false });
                        });
                    }

                    this.isLoading = false;
                })
                .catch(error => {
                    console.log('changeOwner error: '+JSON.stringify(error));
                    this.isLoading = false;
    
                    const event= new ShowToastEvent({
                        title: 'Error!',
                        message: 'Error Occured!',
                        variant: 'error',
                    });
                    this.dispatchEvent(event);
                });
                break;
        }

        this.isLoading = false;
    }

    updateleaddetails(){
        this.getLeadDetailsData();
    }
    getAccountTeamMembers(){
        getAccountTeamMembers({userId: currentUserId })
        .then(result=>
            {
                console.log('accountTeamMembers: '+JSON.stringify(result));
                this.accountIds = result;
//                 var condition;
//                 if(this.isHLUser){
//                      condition = " And Account.Vertical__c= HL '";
                  
//                 }else{
// condition = " And Account.Vertical__c!= HL '";
//                 }

//                  this.branchQueryFilter = "[RecordType.Name = Branch;Id =" +this.accountIds +"]"+condition; 
let condition;

if (this.isHLUser) {
    this.branchQueryFilter =
    "[RecordType.Name = 'Branch';Account.Vertical1__c INCLUDES ('HL');Id = " + this.accountIds + "]";
} else {
     this.branchQueryFilter =
    "[RecordType.Name = 'Branch';Account.Vertical1__c INCLUDES ('AHL');Id = " + this.accountIds + "]";
}


                
                console.log('accountTeamMembers: '+JSON.stringify(result));})
        .catch(error=>
           {
            console.log('error=>',JSON.stringify(error));
           })
        
    }
    disconnectedCallback() { 
        unregisterAllListeners(this); 
    }
}
/* __________________________GenAI: Generated code ends here______________________________ */