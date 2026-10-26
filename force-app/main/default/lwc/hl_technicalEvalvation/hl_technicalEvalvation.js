import { LightningElement,api,track, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import getTechnicalOptions from '@salesforce/apex/COMM_TechnicalRecordPageController.getTechnicalOptions';
import getTechnicalRecords from '@salesforce/apex/COMM_TechnicalRecordPageController.getTechnicalRecords';
import getTechnicalEvluationStatusGrid from '@salesforce/apex/COMM_TechnicalRecordPageController.getTechnicalEvluationStatusGrid';
import checkUserHavePsFcuSamplerPermissionSet from '@salesforce/apex/Utility.checkUserHavePsFcuSamplerPermissionSet';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';//updated Ayushi
import checkCurrentUserPermissionSet from '@salesforce/apex/Utility_V1.getCurrentUserPermissionSets';
import getApprovalSataus from '@salesforce/apex/Utility.getApprovalSataus';
import updateCollateral from '@salesforce/apex/COMM_TechnicalRecordPageController.updateCollateral';
import UpdateCol from '@salesforce/apex/COMM_TechnicalRecordPageController.UpdateCol';
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";//sanwar(4/12/2025)
import canUserEditRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.canUserEditRecord';//sanwar(4/12/2025)
import { updateRecord, getRecord } from "lightning/uiRecordApi";//sanwar(4/12/2025)
import checkOTM from '@salesforce/apex/COMM_TechnicalRecordPageController.checkOTM';
import checkDelinkAccess from '@salesforce/apex/COMM_TechnicalRecordPageController.checkTechnicalDelinkAccess';
import delinkTechnical from '@salesforce/apex/COMM_TechnicalRecordPageController.delinkTechnical';


export default class Hl_technicalEvalvation extends NavigationMixin(LightningElement) {
    @api recordId;
     showDelinkButton = false;
      @track showConfirmation = false;
    @api activeSection = [];
    @api isModalOpen = false;
    @track disabledCmp = false;
    showTechnicalTable = false;
    @track technicals = [];
    @track userHavePsFcuSamplerPermissionSet = false;
    @track showTechnicalEvaluation = true;
    isHomeLoanProduct = false;
    technicalMasterGrid = [];
    groupedTechnicals = [];
    @track oppSubStage = '';//sanwar(4/12/2025)
    isHLUser = false;
    @track mortgageTypeOptions = [];
    @track newOptions = {}; // <-- MUST be object (map)
    _poller = null;
    @track showConfirmationPopup = false;
    confirmationMessage = 'Please Enter Remarks';
    @track colvalue;
    @track colkey;
    @track showVal = false;
    @api notce = false;
    @api isOneVie= false;
    @track techincalManager = false;
    @track creditManager = false;
    @track others = false;
    delinkRowId = '';


    

       handleDelink(event){
        this.showConfirmation = true;
        this.delinkRowId = event.target.dataset.id;
        console.log('this.delinkRowId: '+this.delinkRowId);
    }

    handleNegative(){
        this.showConfirmation = false;
        this.delinkRowId = '';
    }

     showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
            mode: 'dismissable'
        }));
    }

    handlePositive(event){

        delinkTechnical({
            technicalId : this.delinkRowId
        }).then(response=>{
            console.log('response>>>'+response);
            console.log('response == success>>'+(response == 'success'));

            if(response == 'success'){
                this.showConfirmation = false;
                this.delinkRowId = '';
                this.showToast('Success', 'Technical delinked successfully.', 'success');
                
                this.setTechRecords();
                this.getTechnicalMasterGridData();
            }
            else{
                this.showToast('Error', 'Some error in delinking the technical.', 'error');
            }
        }).catch(error=>{
            console.log('Error delink technical -->'+JSON.stringify(error));
        })
    }
    openModal(){this.isModalOpen = true;}

    handleMainButton(){
         getApprovalSataus({ loanId: this.recordId })
                .then((res) => {
                    console.log('res>>>'+res);
                    if(res == 'Soft Rejected 1' || res == 'Soft Rejected 2' ||res =='Hard Rejected') {
                    this.isModalOpen = false;
                    this.dispatchEvent(
                    new ShowToastEvent({
                    title: 'Error',
                    message: 'Verification cannot be initiated because the loan application status is Rejected',
                    variant: 'Error'
                })
                )
                return;
                    }
                })
                .catch((error) => {
                    console.error('Error getCurrentUserProfileName --> '+ error);
                });
        this.isModalOpen = true;
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
    
    connectedCallback() {
        this.handleCheckUserHavePsFcuSamplerPermissionSet();
        this.checkIfLoggedInUserIsHLRelated();//updated Ayushi
        this.fetchProducDetails();//updated Ayushi
        //this.setTechRecords();
        this.fetchLoanStage();
        this.getCurrentProfile();//updated Ayushi
        // Load options first, then records
        this.setMap()
            .then(() => {
                // once options loaded, load records
                this.setTechRecords();
                // remove/avoid tight polling — if you need periodic refresh, use 10s+
                // this._poller = setInterval(() => this.setTechRecords(), 10000);
            })
            .catch(err => {
                console.error('setMap failed in connectedCallback:', err);
                // still attempt to load records if options failed
                this.setTechRecords();
            });
        setInterval(() => {
            this.setTechRecords();
        }, 1000);
        this.checkCmpEditability();
        checkDelinkAccess({loanId: this.recordId})
        .then(result => {
            this.showDelinkButton = result;
        }).catch(error => {
            console.error('checkDelinkAccess error:', error);
        })
    }

     checkCmpEditability() {
    getComponentEditability({ loanId : this.recordId, component : '' })
    .then(result => {
        if(result){
            this.disabledCmp = result;
            console.log('this.hideButton>>>>'+this.hideButton);
        }
    })
    .catch(error => {
        console.log('Error getComponentEditability:  '+error);
    });
  }

    //4/12/2025
    @wire(getRecord, {
        recordId: "$recordId",
        fields: [SUBSTAGE_FIELD]
    })
    oppRecord({ data, error }) {
        if (data) {
            console.log('Data',data);
            this.oppSubStage = data.fields.Sub_stage__c.value;
            console.log("Sub Stage:", this.oppSubStage);
            canUserEditRecord({ recordId: this.recordId })
            .then(result => {
                console.log('At 380');
                if(result && this.oppSubStage == 'Ops Author'){
                    console.log('At 382');
                    this.disabledCmp = false;
                }
            });
        } else if (error) {
            console.error(error);
        }
    }

    handleCheckUserHavePsFcuSamplerPermissionSet() {
        checkUserHavePsFcuSamplerPermissionSet()
        .then(result => {
            console.log('Result2', result);
            this.userHavePsFcuSamplerPermissionSet = result;
        })
        .catch(error => {
            console.error('Error:', error);
        });
    }

    closeModal(event){
        this.isModalOpen = false;

        if(event && event.detail && event.detail == 'Refresh List'){
            console.log('refresh the list');
            this.setTechRecords();
            this.getTechnicalMasterGridData();
        }

        const valueCloseEvent = new CustomEvent('closechecksmodal', {});
        this.dispatchEvent(valueCloseEvent);
    }

    getTechnicalMasterGridData(){
        getTechnicalEvluationStatusGrid({ loanId: this.recordId })
        .then(result => {
            console.log('Result1 grid: ', result);
            this.technicalMasterGrid = result;
        })
        .catch(error => {
            console.error('Error: ', error);
        });
    }

    fetchLoanStage() {
        getLoanStage({ loanId: this.recordId })
        .then(result => {
            console.log('Result1', result);
            if (result == 'Credit Underwriting' || result == 'PSV' || result == 'Disbursement') {

                getCurrentUserProfileName()
                .then((res) => {
                    console.log('res: '+res);
                    console.log('res.includes(Technical)>>>'+res.includes('Technical'));
                    if(res == 'Sales' || res == 'Ops') {
                        this.showTechnicalEvaluation = false;
                    }else if(!this.isHLUser && ((res.includes('Credit') || res.includes('Technical')) && (result == 'PSV' || result == 'Disbursement'))){
                        console.log('showTechnicalEvaluation>>>'+this.showTechnicalEvaluation);
                        this.showTechnicalEvaluation = false;
                    }else if(this.isHLUser ){
                        checkCurrentUserPermissionSet()
                        .then(pm => {

                            console.log('pm>>>>'+JSON.stringify(pm));
                            if(pm.includes('PS_Credit_Manager_HL')){
                                this.showTechnicalEvaluation = true;
                            }else if(pm.includes('PS_Technical_Manager_HL')){
                                checkOTM({loanId : this.recordId})
                                .then(result => {
                                    console.log('result>>>'+result);
                                    if(result){
                                        this.showTechnicalEvaluation = true;
                                    }else{
                                        this.showTechnicalEvaluation = false;
                                    }
                                    
                                });
                                // this.showTechnicalEvaluation = true;
                            }else{
                                this.showTechnicalEvaluation = false;
                            }

                            if(pm.includes('PS_Technical_Manager_HL')){
                                this.techincalManager = true;
                                this.creditManager = false;
                                this.others= false;
                            }
                        });
                    }
                    console.log('showTechnicalEvaluation 193>>>'+this.showTechnicalEvaluation);
                })
                .catch((error) => {
                    console.error('Error getCurrentUserProfileName --> '+ error);
                });
            }
            if(result == 'Credit Underwriting'){
                this.showVal = true;
            }
            else{
                this.notce = true;
            }
        })
        .catch(error => {
            console.error('Error:', error);
        });
    }
    //updated Ayushi
    getCurrentProfile(){
        getCurrentUserProfileName()
    .then((res) => {
        if(res == 'Technical Manager' || res == 'System Administrator'  ) {
            this.techincalManager = true;
            this.creditManager = false;
            this.others= false;
        }
        else if(res == 'Credit Manager' || res == 'Credit Office'){
            this.creditManager = true;
        }
        else{
            this.others = true;
        }
    })
    .catch((error) => {
        console.error('Error getCurrentUserProfileName --> '+ error);
    });
            }

    fetchProducDetails(){
        var inputMapParam = { 'oppId': this.recordId };

        getProductDetails({inputMap : inputMapParam})
        .then(result =>{
            if(result.loanProduct === 'Home Loan'){
                this.isHomeLoanProduct = true;
                this.getTechnicalMasterGridData();
            }
        })
        .catch(error=>{
            console.error('error in getting product: '+ error)
        })
    }
    //end updated
    setTechRecords(){
        getTechnicalRecords({recordId : this.recordId}).then(response=>{
            this.groupTechnicalsByCollateral(response);
        }).catch(error=>{
            console.error(error)
        })
    }

    groupTechnicalsByCollateral(records) {
        const grouped = {};

        records.forEach((rec) => {
        // Prefer collateralId if available, else use collateralType (display)
        const rawKey = rec.collateralId || rec.collateralType;
        if(!rawKey) return;

        const key = String(rawKey).trim();
        if (!grouped[key]) grouped[key] = [];
            grouped[key].push(rec);
        });

        // helper to find best matching key from server newOptions
        const optionKeys = Object.keys(this.newOptions || {});
        const findBestMatchKey = (groupKey) => {
            if(!groupKey) return null;
            const g = String(groupKey).trim();

            // 1) exact match
            if (optionKeys.includes(g)) return g;

            // 2) strip trailing parentheses (e.g., "COL-00362 (Primary Asset)" -> "COL-00362")
            const withoutParen = g.split(' (')[0].trim();
            if (optionKeys.includes(withoutParen)) return withoutParen;

            // 3) startsWith or optionKey startsWith groupKey (covers small variations)
            for (const ok of optionKeys) {
                if (g.startsWith(ok) || ok.startsWith(g)) return ok;
            }

            // 4) try numeric / code matching: check if optionKey appears inside groupKey
            for (const ok of optionKeys) {
                if (g.indexOf(ok) !== -1 || ok.indexOf(g) !== -1) return ok;
            }

            // 5) last resort: return null (no match)
            return null;
        };

        // debug logs
        console.log('DEBUG grouped keys from records:', Object.keys(grouped));
        console.log('DEBUG newOptions keys from server:', Object.keys(this.newOptions || {}));

        this.groupedTechnicals = Object.keys(grouped).map(collateralKey => {
            const group = grouped[collateralKey];

            // display label (human) from first record
            const displayLabel = group[0].collateralType || group[0].collateralName || collateralKey;

            // find best match key that exists in newOptions
            const matchedOptionKey = findBestMatchKey(collateralKey);

            // debug for each group
            console.log('DEBUG match for group key:', collateralKey, ' => matchedOptionKey:', matchedOptionKey);
            
            return {
                collateral: displayLabel,                // shown in UI
                collateralKey: collateralKey,            // original group key (display-ish)
                lookupKey: matchedOptionKey || collateralKey, // the key we will use to lookup options & pass to UpdateCol
                rowspan: group.length + 1,
                remarks: group[0].remarks,//updated Ayushi
                mortgageTypeOptions: this.newOptions?.[matchedOptionKey] || [],  
                records: group.map((r, i) => ({
                    ...r,
                    marketVal: r.marketVal !== null && r.marketVal !== undefined
                    ? Number(r.marketVal).toFixed(2)
                    : null,
                    srno: i + 1,
                        isFirst: i === 0,
                    isLast: i === (group.length - 1),//updated Ayushi
                    styleClass: i === 0 
                        ? 'padding-left:20px; margin-left:3px;border-left: 1px solid #d8dde6;'
                        : 'padding-left:20px; border-left: 1px solid #d8dde6;'
                }))
            };
        });

        this.showTechnicalTable = this.groupedTechnicals.length > 0;
    }

    navigateToRecord(event) {
        const recordId = event.target.dataset.id;

        if (recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: 'Technical_Evaluation__c', 
                    actionName: 'view'
                }
            });
        }
    }

    handleSectionToggle(event){
        if(event.target.name != undefined && event.target.name != '' && event.target.name != null){
            this.activeSection = event.target.name;
        }
    }
    handleRowSelection(event){
        if(event.target.checked){
            if(event.target.dataset.status != 'Approved'){
                event.target.checked = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Technical is not yet approved. Please get it approved first',
                        variant: 'error'
                    })
                );
                this.setTechRecords();
            }
            else{
                this.groupedTechnicals.forEach(item=>{
                    item.records.forEach(iter=>{
                        if(iter.collId != event.target.dataset.name){
                            iter.isValuationSelected = false;
                        }
                        else{
                            iter.isValuationSelected = true;
                            updateCollateral({
                                collId: iter.collId,
                                val: 'selected',
                                techId: event.target.dataset.id,
                                valuation: event.target.dataset.val
                            }).then(response=>{
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Success',
                                        message: 'Valuation selected successfully.',
                                        variant: 'success'
                                    })
                                );
                                this.setTechRecords();
                            }).catch(error=>{
                                console.log('inside error>>>',error);
                            })
                        }
                    })
                })
            }
        }
        else{
            updateCollateral({
                collId: event.target.dataset.name,
                val: 'unselected',
                techId: event.target.dataset.id,
                valuation: null
            }).then(response=>{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Valuation deselected successfully.',
                        variant: 'success'
                    })
                );
                this.setTechRecords();
            }).catch(error=>{

            })
        }
    }
    
    setMap(){
        console.log('setMap - loading newOptions for loanId :', this.recordId);
        return getTechnicalOptions({ loanId: this.recordId })
            .then(result => {
                // result should be a map: { "key": [ {label,value}, ... ], ... }
                this.newOptions = result || {};
                console.log('setMap - newOptions (server):', JSON.stringify(this.newOptions));
            })
            .catch(error => {
                console.error('setMap error:', error);
                throw error;
            });
    }

    handlecheckValue(event){
        const key = event.target.dataset.id;
        const value = event.target.value;
        console.log('handlecheckValue - key:', key, ' value:', value);
        this.colkey = event.target.dataset.id;
        this.colvalue = event.target.value;
        this.showConfirmationPopup = true;
    }
    handleCloseConfimationPopup(event){
        this.showConfirmationPopup = false;
    }
        handleCallDedupe(event){
        const remarks = event.detail
        console.log('remarks : '+remarks);
        UpdateCol({ name: this.colkey, value: this.colvalue+';'+this.recordId,remarks :remarks })
        .then(result=>{
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Value updated successfully.',
                variant: 'success'
            }));
            this.showConfirmationPopup = false;
            // refresh options & records after update (if needed)
            this.setMap().then(()=> this.setTechRecords());
        })
        .catch(err => {
            console.error('UpdateCol error', err);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Could not update value',
                variant: 'error'
            }));
        });
    }
}