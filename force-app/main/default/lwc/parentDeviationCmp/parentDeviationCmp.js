import { LightningElement,api,track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createDeviationRecord from '@salesforce/apex/DeviationRecordPageController.createDeviationRecord';
import deleteDeviation from '@salesforce/apex/DeviationRecordPageController.deleteDeviation';
import fetchCurrScreenDev from '@salesforce/apex/DeviationRecordPageController.fetchCurrScreenDev';
import checkSameDeviationadded from '@salesforce/apex/DeviationRecordPageController.checkSameDeviationadded';
import getApplicantsByLoanId from '@salesforce/apex/DeviationRecordPageController.getApplicantsByLoanId';
import fetchmitigants from '@salesforce/apex/DeviationRecordPageController.fetchmitigants';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import APPROVAL_STATUS from "@salesforce/schema/Opportunity.Approval_Status__c";
import STAGENAME_FIELD from "@salesforce/schema/Opportunity.StageName";
import OWNERID_FIELD from "@salesforce/schema/Opportunity.OwnerId";
import USER_ID from "@salesforce/user/Id";
import PROFILE_LEVEL_DISABLITY from '@salesforce/label/c.Profile_Level_Disablity'; // for disabling label wise
import SUB_STAGE_LEVEL_DISABLITY from '@salesforce/label/c.Sub_Stage_Level_Disability'; // for disabling label wise
import ProfileName from '@salesforce/schema/User.Profile.Name';
import { getRecord } from 'lightning/uiRecordApi';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
import getProduct from '@salesforce/apex/DeviationRecordPageController.getProduct';
import getDeviationMasterList from '@salesforce/apex/DeviationRecordPageController.getDeviationMasterList';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';


export default class ParentDeviationCmp extends LightningElement {
    @api recordId;
    showAdditionScreen = false;
    selectedDeviationId;
    selectedDeviationName;
    mitigantsVal;
    showInputText = false;
    manualDevVal;
    showTable = true;
    showScreenTable = false;
    @track createdDevIds=[];
    @track deviationTable={};
    @track deviationMastersObj=[];
    @track allChecklist = [];
    @track devselected = false;
    @track showRemark = false;
    @track deviationOptions = [];
    @track selectedValue = [];
    @track remarkval;
    @track deletemitigantId;
    @track selectedMitigants = [];
    @track mitigantList;
    @track selectedChecklistData = [];
    showmitigantsList = false;
    selected = false;
    @track hasPsvOrDisbursalStage = false;
    @track isDisabled= false;
    oppSubStage;
    toastvariant = {
        SUCCESS : 'success',
        ERROR : 'error'
    }
    toastTitle = {
        SUCCESS : 'Success',
        ERROR : 'Error'
    }

    toastMessages = {
        DELETE_DEVIATION_SUCESS_MESSAGE : 'Deviation deleted Successfully.',
        DELETE_DEVIATION_FAILURE_MESSAGE : 'Unable to delete the Deviation.',
        DEVIATION_ADDED_SUCCESSFULLY : 'Deviation added Successfully.',
        SOMETHING_WENT_WRONG : 'Something went wrong.',
        Already_Added : 'There is an existing deviation record created with this condition. Please select another deviation condition.',
        Everything_Added : 'Please add the necessary mitigants and the applicable deviation target to proceed.',
        NoMitigants : 'Please select the necessary  mitigant or mitigants in order to proceed.',
        AddMitigants : 'Please add atleast one mitigant.',
    }

    hideButton = false;
    userProfile = '';
    productOptions = [];
    selectedProduct = '';
    deviationMasterList = [];
    isHLRelated = false;
    devSearchText = '';

    @wire(getRecord, { recordId: USER_ID, fields: [ProfileName] })
    userDetails({ error, data }) {
        if(data) {
            this.userProfile = data.fields.Profile.value.fields.Name.value;
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: [SUBSTAGE_FIELD,APPROVAL_STATUS,STAGENAME_FIELD,OWNERID_FIELD] })
    opportunity({ error, data }) {
        if(data) {
            this.oppSubStage = data.fields.Sub_stage__c.value;
            var approvalStatus = data.fields.Approval_Status__c.value;
            var StageName = data.fields.StageName.value;
            var OwnerId = data.fields.OwnerId.value;

            if(StageName === 'Credit Underwriting'){
                console.log('this.userProfile: '+this.userProfile + ' ::OwnerId:: ' +OwnerId +' ::USER_ID:: ' + USER_ID);
                // && OwnerId != USER_ID
                // if(this.userProfile != 'System Administrator'){
                //     this.hideButton = true;
                // }
                if(this.userProfile == 'System Administrator' || (((this.userProfile == 'Credit Officer' || this.userProfile == 'Credit Manager') && this.oppSubStage == 'Credit Processing Verification') ||((this.userProfile == 'Credit Manager'  && this.oppSubStage == 'Credit in-progress')) )){
                    this.hideButton = false;
                }else{
                    this.hideButton = true;
                }
            }

            console.log('approvalStatus>>'+approvalStatus);
            if(this.oppSubStage === 'Disbursed' || ['Hard Rejected', 'Soft Rejected 1', 'Soft Rejected 2'].includes(approvalStatus)) {
                this.hideButton = true;
            }
            if(!this.hideButton){
              this.checkEditability();
            }
        }
    }

    connectedCallback(){
        this.checkEditability();
        this.fetchLoanStage();
        this.fetchProducDetails();
        this.getProductOptions();
        this.getDeviationList();
    }
    @track _darkDropdownApplied = false;
    renderedCallback() {
        if (this._darkDropdownApplied) {
            return;
        }

        const style = document.createElement('style');
        
        style.innerText = `
            .slds-listbox__option,
            .slds-listbox__option-text,
            .slds-media__body,
            .slds-truncate {
                color: #ffffff !important;
            }

            .slds-dropdown {
                background: #16283f !important;
            }

            .slds-listbox__option:hover,
            .slds-listbox__option.slds-has-focus,
            .slds-listbox__option[aria-selected="true"] {
                color: #ffffff !important;
                background: #1b304d !important;
            }
        `;

        this.template.querySelector('.styleContainer')?.appendChild(style);
        this._darkDropdownApplied = true;
    }

    setEditability() {
        const disabledProfiles = PROFILE_LEVEL_DISABLITY.split(';').map(p => p.trim());
        const disabledSubStage = SUB_STAGE_LEVEL_DISABLITY.split(';').map(s => s.trim());
        if (disabledProfiles.includes(this.userProfile) || disabledSubStage.includes(this.oppSubStage)) {
            this.hideButton = true;
        }
    }
    checkEditability() {
        getComponentEditability({ loanId : this.recordId, component : 'parentDeviationCmp' })
        .then(result => {
            if(result){
                this.hideButton = result;
                console.log('Hide Button 120:', this.hideButton);

            }
        })
        .catch(error => {
            console.log('Error getComponentEditability:  '+error);
        });
    }

    fetchProducDetails(){
        var inputMapParam = {
            'oppId': this.recordId
        };

        getProductDetails({inputMap : inputMapParam})
        .then(result =>{
            console.log('result product: '+ JSON.stringify(result));
            this.isHLRelated = result.isHLRelated;
        })
        .catch(error=>{
            console.error('error in getting product: '+ error)
        })
    }

    fetchLoanStage() {
        getLoanStage({ loanId: this.recordId })
        .then(result => {
          console.log('Result1', result);
          if(result == 'PSV' || result == 'Disbursement') {
              this.hasPsvOrDisbursalStage = true;
          } else if (result == 'Credit Underwriting') {
            getCurrentUserProfileName()
            .then((res) => {
                if(res == 'Sales') {
                  this.isDisabled = true;
                }
            })
            .catch((error) => {
                console.error('Error getCurrentUserProfileName --> '+ error);
            });
        }
        })
        .catch(error => {
          console.error('Error:', error);
      });
    }

    handleDeviationChange(event) {//selectedValue
        console.log(event.target.checked);
        // const selecteddocid = event.target.value;
        const selecteddocid = event.target.label;
        // console.log('Selected Deviation:', this.selecteddocid);
        this.showmitigantsList = true;
        this.showRemark = true;
        // const selecteddocid = event.target.dataset.name;
        console.log('selecteddocid '+selecteddocid);
        if(event.target.checked){
            this.selectedValue.push(selecteddocid);
        }else{
            let temp = [];
            this.selectedValue.forEach(record => {
                if(record != selecteddocid){
                    temp.push(record);
                }
            });
            this.selectedValue = temp;
            console.log('selectedChecklistData '+this.selectedValue);
        } 
        console.log('selectedChecklistData '+this.selectedValue);
        
        // this.showRemark = true;
    }

    handleDeviationSelction(event) {
        this.selectedDeviationId = event.detail.searchRecord.Id;
        this.selectedDeviationName = event.detail.searchRecord.Name;
       this.selected = true;
        console.log('Selected deviation ID: ' + this.selectedDeviationId);
        checkSameDeviationadded({ recordId: this.recordId, devmasterId: this.selectedDeviationId, productId: this.selectedProduct })
            .then(response => {
                console.log('Response: ' + response);
                if (response) {
                    this.handletoastEvent(this.toastMessages.Already_Added,this.toastTitle.ERROR,this.toastvariant.ERROR);
                    this.template.querySelector('c-search-lookup').handleReset(event);
                }
                else{
                    this.devselected = true;
                    this.fetchMitigants();
                    getApplicantsByLoanId({ recordId: this.recordId ,devmasterId: this.selectedDeviationId})
                    .then(response => {
                        if (response) {
                            this.deviationOptions = Object.keys(response).map(key => ({
                                label: response[key], // Display name from Apex
                                value: key // Id from Apex
                            }));
                        }
                        console.log('deviationOptions:', JSON.stringify(this.deviationOptions));
                        if (this.deviationOptions.length === 1 && this.deviationOptions[0].value === "Loan Application") {
                            console.log("Only 'Loan Application' is selected!");
                            this.selectedValue = this.deviationOptions[0].value;
                            console.log('this.selectedValue '+this.selectedValue);
                            this.showmitigantsList = true;
                            this.devselected = false;
                            this.showRemark = true;
                        }
                    })
                    .catch(error => {
                        console.error('Error fetching applicants:', JSON.stringify(error));
                    });
                } 
            })
            .catch(error => {
                console.error('Error: ', JSON.stringify(error));
            });
    }
    handleremark(event){
        this.remarkval = event.target.value;
        console.log('remarkval '+this.remarkval);
    }

    handleChangeDeviation(event){
        this.devSearchText = event.target.value;
        this.getDeviationList();
    }

    handleMitigants(event){
        this.mitigantsVal = event.target.value;
        console.log('mitigantsVal '+this.mitigantsVal);
    }

    handleDeviationDeselction(event){
        this.selectedDeviationId = '';
        this.selectedDeviationName = '';
       this.selected = false;
        //this.createdDevIds=[];
    }

    handleAddDeviationRecord(){
        this.showAdditionScreen = true;
    }
    handleMitigantsChange(event){
        this.mitigantsVal = event.target.value;
    }
    /*Need to remove after confirming its not required
    handleDeviationSelected(event){
        console.log('event selected log=:'+JSON.stringify(event.detail));
        this.selectedDeviationId = event.detail.id;
        this.selectedDeviationName = event.detail.Name;
        if(event.detail.Name == 'Others -'){
            this.showInputText = true;
            this.manualDevVal = event.detail.Name;
        }
        else{
            this.showInputText = false;
        }
    }*/
    handleManualDeviationChange(event){
        if(event.target.value){
            this.showInputText = false;
            this.selectedDeviationName = '';
            this.manualDevVal = '';
        }
        else{
            this.manualDevVal = event.target.value;
            this.selectedDeviationName = this.manualDevVal;
        }
    }
    handleDeviationDeselected(event){
        this.selectedDeviationId = '';
        this.selectedDeviationName = '';
    }
    handleClose(){
        this.showScreenTable = false;
        this.deviationTable={};
        this.showAdditionScreen = false;
        this.selectedValue=[];
        this.selectedDeviationId = '';
        this.selectedDeviationName = '';
        this.manualDevVal = ''
        this.mitigantsVal = '';
        this.showInputText = false;
        this.selected = false;
        this.remarkval= '';
        this.selectedProduct = '';
    }

    getDeviationList(){
        getDeviationMasterList({
            searchText : this.devSearchText
        }).then(response =>{ 
            console.log('deviation master: '+ JSON.stringify(response));
            this.deviationMasterList = response;
            
        }).catch(error=>{
            this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG,this.toastTitle.ERROR,this.toastvariant.ERROR);
        });
    }

    handleDeviationSelection(event){
        const Id = event.target.dataset.id;
        const Name = event.target.dataset.name;
        console.log('dev Id: '+Id);

        this.selected = true;
        this.selectedDeviationId = Id;
        this.selectedDeviationName = Name;

        checkSameDeviationadded({ recordId: this.recordId, devmasterId: this.selectedDeviationId, productId: this.selectedProduct })
        .then(response => {
            console.log('Response: ' + response);
            if (response) {
                this.handletoastEvent(this.toastMessages.Already_Added,this.toastTitle.ERROR,this.toastvariant.ERROR);
                this.selectedDeviationId = '';
                this.selectedDeviationName = '';
            }
            else{
                this.devselected = true;
                this.fetchMitigants();
                getApplicantsByLoanId({ recordId: this.recordId ,devmasterId: this.selectedDeviationId})
                .then(response => {
                    if (response) {
                        this.deviationOptions = Object.keys(response).map(key => ({
                            label: response[key], // Display name from Apex
                            value: key // Id from Apex
                        }));
                    }
                    console.log('deviationOptions:', JSON.stringify(this.deviationOptions));
                    if (this.deviationOptions.length === 1 && this.deviationOptions[0].value === "Loan Application") {
                        console.log("Only 'Loan Application' is selected!");
                        this.selectedValue = this.deviationOptions[0].value;
                        console.log('this.selectedValue '+this.selectedValue);
                        this.showmitigantsList = true;
                        this.devselected = false;
                        this.showRemark = true;
                    }
                })
                .catch(error => {
                    console.error('Error fetching applicants:', JSON.stringify(error));
                });
            } 
        })
        .catch(error => {
            console.error('Error: ', JSON.stringify(error));
        });
    }

    handleSave(event){
        if(!this.selectedProduct){
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please select product',
                variant: 'error',
            }));
        }
        else if(!this.selectedDeviationId){
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please fill all the required details',
                variant: 'error',
            }));
        }else if(this.mitigantsVal=='' || this.mitigantsVal == undefined || this.mitigantsVal == null){
            this.handletoastEvent(this.toastMessages.AddMitigants,this.toastTitle.ERROR,this.toastvariant.ERROR);
        }else{
            createDeviationRecord({
                loanId:this.recordId,
                deviationId:this.selectedDeviationId,
                deviationName:this.selectedDeviationName,
                mitigants:this.mitigantsVal,
                deviationCategory:'Manual',
                productId:this.selectedProduct
            }).then(response=>{ 

                /*Need to remove after confirming its not required
                if(this.showInputText == false){
                    console.log('inside input text');
                    this.template.querySelector('c-generic-look-up-cmp').removeMsg(event);
                }*/
                this.template.querySelector('c-deviation-records-cmp').changeMessage(event);
                this.createdDevIds.push(response);
                this.fetchRecords();   
                this.selectedDeviationId = '';
                this.selectedDeviationName = '';
                this.manualDevVal = ''
                this.mitigantsVal = '';
                this.showInputText = false;
                this.showScreenTable = false;
                this.selectedProduct = '';
                this.template.querySelector('c-search-lookup').handleReset(event);
                this.handletoastEvent(this.toastMessages.DEVIATION_ADDED_SUCCESSFULLY,this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);   
            }).catch(error=>{
                this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG,this.toastTitle.ERROR,this.toastvariant.ERROR);
            })

        }
    }
    handleSaveManualDeviation(event){
        console.log('selectedValue '+this.selectedValue);
        console.log('selectedChecklistData '+this.selectedChecklistData);
        console.log('remarks '+this.remarkval);
        if(!this.selectedProduct){
            this.handletoastEvent('Select product',this.toastTitle.ERROR,this.toastvariant.ERROR);
        }
        else if(this.mitigantsVal=='' || this.mitigantsVal == undefined || this.mitigantsVal == null){
            this.handletoastEvent(this.toastMessages.AddMitigants,this.toastTitle.ERROR,this.toastvariant.ERROR);
        }else if(this.selectedValue.length > 0 && this.selectedValue!='' && this.selectedChecklistData ){
            createDeviationRecord({
                sanctionMaster :this.selectedDeviationId , 
                recordId : this.recordId , 
                remark : this.remarkval,
                appIds : this.selectedValue,
                mitigants:this.mitigantsVal,
                productId:this.selectedProduct
            })
            .then(response => {
                console.log('Response: ' + response);
                if (response) {
                    this.mitigantsVal = '';
                    this.fetchRecords(response);
                    this.handletoastEvent(this.toastMessages.DEVIATION_ADDED_SUCCESSFULLY,this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);
                    this.template.querySelector('c-deviation-records-cmp').changeMessage(event);
                    this.template.querySelector('c-search-lookup').handleReset(event);
                }});
        }
        else{
            this.handletoastEvent(this.toastMessages.Everything_Added,this.toastTitle.ERROR,this.toastvariant.ERROR);
        }
                    
    }

    deleteDeviation(event){
        deleteDeviation({
            devId:event.target.dataset.id
        }).then(response=>{
            this.fetchRecords();
            this.template.querySelector('c-deviation-records-cmp').changeMessage(event);
            this.showScreenTable = false;
            this.handletoastEvent(this.toastMessages.DELETE_DEVIATION_SUCESS_MESSAGE,this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);
        }).catch(error=>{
            this.handletoastEvent(this.toastMessages.DELETE_DEVIATION_FAILURE_MESSAGE,this.toastTitle.ERROR,this.toastvariant.ERROR);
        })
    }
    fetchRecords(Ids){
        fetchCurrScreenDev({
            recIds:Ids
        }).then(response=>{
            if(response){
                this.deviationTable = response.map(item => ({
                    ...item,
                    mitigantsArray: item.mitigants ? item.mitigants.split(',').map(m => m.trim()) : []
                }));
                this.showScreenTable = true;
            }
        }).catch(error=>{
            console.error('fetchRecords error : '+JSON.stringify(error));
            this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG,this.toastTitle.ERROR,this.toastvariant.ERROR);
        })
    }

    handleOpenDeviations(event){
        window.open('/'+event.target.dataset.id);
    }

    handletoastEvent(msg,title,variant){
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        }));
    }
    handleCheckboxChange(event) {
        const isChecked = event.target.checked;
        const mitigantName = event.target.label;
        console.log('mitigantName '+mitigantName);
        this.deletemitigantId = event.target.dataset.id;
        console.log('deletemitigantId '+this.deletemitigantId);
        if (!isChecked) {
            // Add the mitigant to the array if it's selected
            if (!this.selectedMitigants.includes(mitigantName)) {
                this.selectedMitigants.push(mitigantName);
                console.log(`Mitigant Selected: ${mitigantName}`);
                // //this.handletoastEvent(`Selected: ${mitigantName}`, 'Success', 'success');
                // this.deleteMitigants();
            }
        } else {
            // Remove the mitigant from the array if it's unselected
            const index = this.selectedMitigants.indexOf(mitigantName);
            if (index > -1) {
                this.selectedMitigants.splice(index, 1);
                console.log(`Mitigant Unselected: ${mitigantName}`);
                //this.handletoastEvent(`Unselected: ${mitigantName}`, 'Warning', 'warning');
            }
        }
        // Log the current list of selected mitigants
        console.log('Selected Mitigants:', this.selectedMitigants);
    }
    deleteMitigants(event){
        if (this.selectedMitigants.length === 0) {
            console.log("No mitigants selected");
            this.handletoastEvent(this.toastMessages.NoMitigants,this.toastTitle.ERROR,this.toastvariant.ERROR);
            // You can display a message or perform other actions if no mitigants are selected
        } else {
            console.log("Selected mitigants:", this.selectedMitigants);
            console.log('Id '+Id);
            removeMitigants({ recordId: this.deletemitigantId , mitigantsToRemove:this.selectedMitigants})
            .then(response => {
                console.log('response '+response);
                this.connectedCallback();
            })
            // Handle the case where there are selected mitigants
        }
    }
    fetchMitigants(){
        fetchmitigants({devmasterId : this.selectedDeviationId})
        .then(response => {
            console.log('Response: ' + response);
            if (response) {
                this.mitigantList = response;
                // this.selected = false;
            }
        })
    }
    handleChecklistselection(event){
        console.log(event.target.checked);
        const selecteddocid = event.target.dataset.name;
        console.log('selecteddocid '+selecteddocid);
        if(event.target.checked){
            this.selectedChecklistData.push(selecteddocid);
        }else{
            let temp = [];
            this.selectedChecklistData.forEach(record => {
                if(record != selecteddocid){
                    temp.push(record);
                }
            });
            this.selectedChecklistData = temp;
            console.log('selectedChecklistData '+this.selectedChecklistData);
        }  
        console.log('selectedChecklistData '+this.selectedChecklistData);          
    }

    showmitigants(event){
        if(this.selectedValue){
        this.showmitigantsList = true;
        }
        else{
            this.handletoastEvent(this.toastMessages.NoMitigants,this.toastTitle.ERROR,this.toastvariant.ERROR); 
        }
    }
    handleRefresh() {
        this.template.querySelector("c-deviation-records-cmp").handleValueChange();
    }

    getProductOptions() {
        getProduct({ loanId : this.recordId })
        .then(result => {
            console.log('getProduct result: '+JSON.stringify(result));
            var options = [];
            
            for(let key in result) {
                options.push({value: result[key], label: key});
            }
            this.productOptions = options;
        })
        .catch(error => {
            console.error('Error getting status options: ', error);
        });
    }
    
    onChangeProduct(event) {
        this.selectedProduct = event.target.value;
    }
}