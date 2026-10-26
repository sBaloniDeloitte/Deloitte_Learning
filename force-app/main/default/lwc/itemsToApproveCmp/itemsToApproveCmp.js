import { LightningElement, track } from 'lwc';
import getItemsToApprove from "@salesforce/apex/ItemsToApproveController.getItemsToApprove";
import getCurrentUserRole from "@salesforce/apex/ItemsToApproveController.getCurrentUserRole";

export default class ItemsToApproveCmp extends LightningElement {

    @track approvalType;
    @track approvalData=[];
    @track showApprovalTable=false;
    @track isSales;

    /*
    filterOptions = [
        { label: 'Pricing', value: 'Pricing'},
        { label: 'Exception', value: 'Exception'},
        { label: 'None', value: 'None'},
    ];

    handleApprovalChange(event){
        console.log('selected approval type----', event.target.value);
        this.approvalType= event.target.value;
    }
    */
    

    connectedCallback(){
        this.getApprovalRecords();
        this.getUserRole();
    }

    getApprovalRecords(){
        getItemsToApprove({approvalType: this.approvalType})
        .then((response) => {
            console.log("response getItemsToApprove" + JSON.stringify(response));
            this.approvalData = response;
            if(this.approvalData!= null && this.approvalData.length>0){
                this.showApprovalTable= true;
            }
        })
        .catch((error) => {});
    }

    navigateToRecord(event) {
        window.open(`/${event.currentTarget.dataset.id}`, '_blank');
    }

    getUserRole(){
        getCurrentUserRole({})
        .then((response) => {
            console.log("response getCurrentUserRole" + response);
            if(response!= 'Credit'){
                this.isSales = true;
            }else if(response == 'Credit'){
                this.isSales = false;
            }
        })
        .catch((error) => {
            console.log("Error in getUserRole" + error);
        });
    }

}