import { LightningElement,track , api, wire} from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getOcrRecordsByOcrId from '@salesforce/apex/Hl_OcrDetailsController.getOcrRecordsByOcrId';
import upsertLoanTransaction from '@salesforce/apex/Hl_OcrDetailsController.upsertLoanTransaction';
import getOcrLoanTransaction from '@salesforce/apex/Hl_OcrDetailsController.getOcrLoanTransaction';
import createChildLoanTransactions from '@salesforce/apex/Hl_OcrDetailsController.createChildLoanTransactions';
import getOcrRecordsTransactionalByOcrId from '@salesforce/apex/Hl_OcrDetailsController.getOcrRecordsTransactionalByOcrId';
import getOpportunityTeamMembers from '@salesforce/apex/AHL_LoanDetailsController.getOpportunityTeamMembers';
import { getRecord } from "lightning/uiRecordApi";
import USERID_FIELD from "@salesforce/user/Id";
import ProfileName from '@salesforce/schema/User.Profile.Name';
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import LOAN_HIERARCHY_FIELD from '@salesforce/schema/Opportunity.Loan_Hierarchy__c';
import SPLIT_LOAN_FIELD from '@salesforce/schema/Opportunity.Split_Parent_Loan_Application__c';

export default class OcrDetails extends LightningElement {
    @api recordId;
    @track calculatedReceivable;
    isLoading = false;
    @track activeSections = [];
    @track showapplicablefor = false;
    firstTimeLoaded = true;
    @track selectedId;
    steps = [];
    @track isDisable = true;
    //@track originalSteps;
    @track ocrId;
    @track parentOcrId ='';
    @track saveButtonDisabled = true;
    @track ocrDescriptionDefault='';
    @track ocrType;
    @track isOcrEditable = true;
    @track ocrDefinitionFields = [
        { label: 'OCR Description', fieldName: 'ocrDescription',fieldValue:'', type: 'text', disabled : true, isRequired : false},
        { label: 'Customer Portion (%)', fieldName: 'customerPortion',fieldValue:'', type: 'number', step:'0.01', disabled : true, isRequired : false },
        { label: 'OCR Type', fieldName: 'ocrType', fieldValue:'', type: 'text',disabled : true, isRequired : false},
        { label: 'Total Cost of Property', fieldName: 'totalDemand',fieldValue:'', type: 'number', step:'0.01',disabled : true,isRequired : true },
        { label: 'Total OCR Receivable', fieldName: 'totalReceivable',fieldValue:'', type: 'number', step:'0.01',disabled : true, isRequired : false},
        { label: 'Total Demand Received (Include Current Receipt)', fieldName: 'totalDemandReceived', fieldValue:'', type: 'number',step:'0.01', disabled : true, isRequired : false},
        { label: 'Total OCR Received (Include Current Receipt)', fieldName: 'totalOcrReceived',fieldValue:'', type: 'number',step:'0.01', disabled : true, isRequired : false}
    ];
    oppStage = '';
    oppSubStage = '';
    currentUserOppRole = [];
    ocrDefinition = {};
    userId = USERID_FIELD;
    userProfileName;

    connectedCallback() {
        // Start with one blank row
        // canUserEditRecord({recordId: this.recordId})
        //         .then(result => {
        //             console.log('change 2');
        //             if(result){
        //                 console.log('change 1');
        //                 this.isDisable = true;
        //                 this.ocrDefinitionFields = this.ocrDefinitionFields.map(field => {
        //                     return {
        //                         ...field,
        //                         disabled: true
        //                     };
        //                 });
        //             }
        //         });
        this.getOcrLoan(); //calling the default ocrdefiniton here
        //this.steps = [{ index:1, customer: null, financer: null, makeCustomerDisabled: false, makeFinancerDisabled:false, contributor :'' }]; //already getting instance in the getOcrLoan method
        //this.originalSteps = [...this.steps];
    }
    @wire(getRecord, { recordId: USERID_FIELD, fields: [ ProfileName] })
    userDetails({ error, data }) {
        if (data) {
            if (data.fields.Profile.value != null) {
                this.userProfileName = data.fields.Profile.value.fields.Name.value;
            }
        }
    }

    //Sanwar - Start
    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, SUBSTAGE_FIELD,LOAN_HIERARCHY_FIELD,SPLIT_LOAN_FIELD] })
    opportunity({ error, data }) {
        if(data) {
            this.oppStage = data.fields.StageName.value;
            this.oppSubStage = data.fields.Sub_stage__c.value;
            const loanHierarchy = data.fields.Loan_Hierarchy__c.value;
            const splitLoanApp = data.fields.Split_Parent_Loan_Application__c.value;
            if(splitLoanApp && loanHierarchy =='Child'){
                this.isOcrEditable = false;
                this.ocrDefinitionFields = this.ocrDefinitionFields.map(field => {
                    return { ...field, disabled: true };
                });
            }
            else{
                this.isOcrEditable = true;
            }
            console.log('isOcrEditable' , this.isOcrEditable);
            console.log('Opp sub stage' , this.oppSubStage);
            setTimeout(() => {
                this.handleVisibility();
            }, 1000);
        }
    }

    @wire(getOpportunityTeamMembers, {
            loanId: "$recordId",
        })
        getOppTeamMembers({
            data,
            error
        }) {
            if (data) {
                console.log('data ',data);
                data.forEach(item => {
                    console.log('User Data');
                    console.log('user id',item.UserId);
                    if(item.UserId == USERID_FIELD){
                        this.currentUserOppRole.push(item.TeamMemberRole);    
                    }
                })
                console.log('Current user role ',this.currentUserOppRole);
            } else if (error) {
                this.handleError(error, 'gotLoanFields');
                this.showToast(this.toastTitle.ERROR, this.toastMessages.SOMETHING_WENT_WRONG, this.toastVariant.ERROR);
            }
        }
    
    handleVisibility(){
        console.log('Stage', this.oppStage);
        console.log(' Sub stage', this.oppSubStage);
        if((this.oppStage == 'Disbursement' && this.oppSubStage == 'Ops Maker' && (this.currentUserOppRole.includes('OPS Maker') || this.currentUserOppRole.includes('Credit Officer'))) || 
            (this.oppStage == 'PSV' && this.oppSubStage == 'PSV Sales' && this.currentUserOppRole.includes('Sales'))){ //|| this.userProfileName =='System Administrator'
            this.isDisable = false;
            //putting filter of custportion ocrDes and totalRec to be always disabled even for admin ?? who removed this filter and left the comments
            this.ocrDefinitionFields = this.ocrDefinitionFields.map(field => {
                if (field.fieldName === 'ocrType' || field.fieldName === 'customerPortion' || field.fieldName === 'ocrDescription' || field.fieldName === 'totalReceivable') {
                    return { ...field, disabled: true };
                }
                else{
                    return { ...field, disabled: false };
                }
            });
        }
    }//Sanwar End

   handleAddRow(event) {
        const index = parseInt(event.target.dataset.index, 10);
        //const index = this.steps &&  this.steps.length ? this.steps.length : 1;
        const newIndex = this.steps[index].index + 1;
         console.log('inex',index);
        const newStep = {
            index: newIndex,
            customer: null,
            financer: null,
            makeCustomerDisabled: false,
            makeFinancerDisabled: false
        };

        this.steps.splice(index + 1, 0, newStep);
        //this.originalSteps.splice(index + 1, 0, newStep);

        // Optional: reindex if needed
        this.steps = this.steps.map((step, i) => ({ ...step, index: i + 1 }));
        //this.originalSteps = this.originalSteps.map((step, i) => ({ ...step, index: i + 1 }));
        console.log('this.steps',this.steps);
    }

    handleDeleteRow(event) {
        if (this.steps.length === 1) {
            this.showToastMessage('Action Denied', 'At least one step is required.', 'warning');
            return;
        }

        const index = parseInt(event.target.dataset.index, 10);

        this.steps.splice(index, 1);
        //this.originalSteps.splice(index, 1);

        // Optional: reindex if needed
        this.steps = this.steps.map((step, i) => ({ ...step, index: i + 1 }));
       // this.originalSteps = this.originalSteps.map((step, i) => ({ ...step, index: i + 1 }));
        console.log('this.steps delete',this.steps);
    }
        
    handleInputChange(event) {
        if(event.target){
            this.saveButtonDisabled = false;
        }
        else{
            this.saveButtonDisabled = true;
        }
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.ocrDefinition[field] = value;//maps withthe value
        
        this.ocrDefinitionFields = this.ocrDefinitionFields.map(f => {
            return f.fieldName === field ? { ...f, fieldValue: value } : f;
            });
        
        // If ocrReceivable is changed, recalculate totalOcrPaid
        
        if (field === 'totalDemand') {
            this.demandTotal = parseFloat(value);
            this.customerPortion = parseFloat(this.ocrDefinition.customerPortion);
            console.log(this.customerPortion);
            if(this.customerPortion == null || isNaN(this.customerPortion)){
                this.showToastMessage(
                    'Error',
                    'Please select the OCR ID first',
                    'error');
            }

            console.log('this.demandTotal 212>>>>'+this.demandTotal);

            if (!isNaN(this.demandTotal) && !isNaN(this.customerPortion) && this.customerPortion !== 0) {
                this.calculatedReceivable = (this.customerPortion / 100) * this.demandTotal;
                //this.ocrDefinition.totalReceivable = calculatedReceivable.toFixed(2); //2 decimals rounding
                this.ocrDefinition.totalReceivable = this.calculatedReceivable;

                // Update the field value in the UI
                this.ocrDefinitionFields = this.ocrDefinitionFields.map(f =>
                    f.fieldName === 'totalReceivable' ? { ...f, fieldValue: this.ocrDefinition.totalReceivable } : f
                );
            }
        }
  

        
        console.log('ocrDef',JSON.stringify(this.ocrDefinition));
        
        console.log('field>>',event.target.dataset.field);
        console.log('dataset>>',JSON.stringify(event.target.dataset));
        
    }

    handleCustomerChange(event) {
        if(event.target){
            this.saveButtonDisabled = false;
        }
        else{
            this.saveButtonDisabled = true;
        }
        const index = parseInt(event.target.dataset.index, 10);
        const value = event.target.value;
        this.steps[index].customer = value;
        if (value !== '') {
            this.steps[index].financer = null;
            this.steps[index].makeFinancerDisabled = true;
            this.steps[index].contributor = 'Customer';
        }
        else{
            this.steps[index].makeFinancerDisabled = false;
        }
        this.steps = [...this.steps];
    }

    handleFinancerChange(event) {
        if(event.target){
            this.saveButtonDisabled = false;
        }
        else{
            this.saveButtonDisabled = true;
        }
        const index = parseInt(event.target.dataset.index, 10);
        const value = event.target.value;
        this.steps[index].financer = value;
        if (value !== '') {
            this.steps[index].customer = null;
            this.steps[index].makeCustomerDisabled = true;
            this.steps[index].contributor = 'Financer';
        }
        else{
            this.steps[index].makeCustomerDisabled = false
        }
        this.steps = [...this.steps];
    }
    fieldValues; //converted it into a property since took logic to a differnt method

    handleSave() {
        
        if (!this.selectedId) {
            this.showToastMessage('Missing OCR ID', 'Please select an OCR ID before saving.', 'warning');
            return;
        }
        if(!this.ocrDefinition.totalDemand){
            this.showToastMessage('REQUIRED FIELD', 'Total Cost of Property cannot be Empty.', 'error');
            return;
        }

        let totalCustomer = 0;
        let totalFinancer = 0;
        console.log('steps',this.steps);
        // this.steps.forEach(step => {
        //     totalCustomer += parseFloat(step.customer || 0);
        //     totalFinancer += parseFloat(step.financer || 0);
        // });
        for (let i = 0; i < this.steps.length; i++) {
            const step = this.steps[i];
            const customerValue = parseFloat(step.customer) || 0;
            const financerValue = parseFloat(step.financer) || 0;
            if (customerValue === 0 && financerValue === 0) {
                this.showToastMessage('Action Denied', `Customer and Financer cannot both be zero or blank in row ${i + 1}.`, 'warning');
                return;  // stop saving
            }
            totalCustomer += customerValue;
            totalFinancer += financerValue;
        }

        this.fieldValues = {
           OCR_Description__c: this.ocrDefinition.ocrDescription,
            Customer_Portion__c: parseFloat(this.ocrDefinition.customerPortion) || 0,
            OCR_Type__c: this.ocrDefinition.ocrType,
            OCR_ID__c: this.ocrId,
            OCR_Master__c : this.selectedId,
            Total_Demand__c: parseFloat(this.ocrDefinition.totalDemand) || 0,
            Total_OCR_Receivable__c: parseFloat(this.ocrDefinition.totalReceivable) || 0,
            Total_Demand_Received__c: parseFloat(this.ocrDefinition.totalDemandReceived) || 0,
            Total_OCR_Received__c: parseFloat(this.ocrDefinition.totalOcrReceived) || 0
        };
        console.log('fieldvalues',this.fieldValues);

        const total = totalCustomer + totalFinancer;
        if (total.toFixed(2) !== '100.00') {
            //alert(`Total must be 100%. Current total: ${total.toFixed(2)}%`);
            //let message =  '`Total must be 100%. Current total: ${total.toFixed(2)}%`';
            this.showToastMessage('Invalid Total',`Total must be 100%. Current total: ${total.toFixed(2)}%`, 'error');
        } 
        else {
            console.log('Saved:', JSON.stringify(this.steps));
            //this.isLoading= true; //spinner
            this.upsertLoanOcrParentAndCreateSteps();
        }
    }

    upsertLoanOcrParentAndCreateSteps() {
        console.log('inside upsert loan ocr');
        this.isLoading = true;

        upsertLoanTransaction({ fieldValues: this.fieldValues, recordId: this.recordId, recordTypeDevName: 'OCR' })
            .then((result) => {
                console.log('result', result);
                if (result) {
                    this.parentOcrId = result;
                }

                const transactions = this.steps.map(step => ({
                    Step_Sequence__c: step.index,
                    Customer_Contribution__c: step.customer,
                    Financer_Contribution__c: step.financer,
                    OCR_Definition__c: this.parentOcrId,
                    OCR_ID__c: this.ocrId,
                    OCR_Master__c: this.selectedId,
                    Loan_Application__c: this.recordId,
                    Contributor__c: step.contributor
                }));

                return createChildLoanTransactions({ transactions, recordId: this.recordId });
            })
            .then(() => {
                console.log('inside child transaction');
                this.showToastMessage('Success', 'Record Saved Successfully', 'success');
            })
            .catch(error => {
                console.log('error in transaction', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    getOcrLoan(){
        getOcrLoanTransaction({ recordId: this.recordId})
        .then(result => {
            if (result) {
                
                this.selectedId = result.OCR_Master__c; //used to autopopulate the OCR Id in case it exists in the backenddd
                this.ocrId = result.OCR_ID__c;// TODO : CHANGE it : >>>changed it.
        
                console.log('this.selectedId in OcrDetail', this.selectedId);
                console.log('result', result);
                this.ocrDefinition = {
                    ocrDescription: result.OCR_Description__c,
                    customerPortion: result.Customer_Portion__c,
                    ocrType: result.OCR_Type__c,
                    totalDemand: result.Total_Demand__c,
                    totalReceivable: result.Total_OCR_Receivable__c,
                    totalDemandReceived: result.Total_Demand_Received__c,
                    totalOcrReceived: result.Total_OCR_Received__c
                };
                this.ocrDefinitionFields = this.ocrDefinitionFields.map(field => {
                    return {
                        ...field,
                        fieldValue: this.ocrDefinition[field.fieldName] || ''
                    };
                });
               this.getOcrStepsInTransaction(); //calling this to get default steps from transaction obj and in case they dont exist then fetch from master
            }
            else{
                this.ocrDefinition = {
                    ocrDescription: '',
                    customerPortion: '',
                    ocrType: '',
                    totalDemand: '',
                    totalReceivable: '',
                    totalDemandReceived: '',
                    totalOcrReceived: ''
                }
            }
            
        })
        .catch(error => {
            console.error('Error fetching OCR Loan Transaction:', error);
        });
    }
    getOcrStepsInTransaction(){
        getOcrRecordsTransactionalByOcrId({ocrId : this.ocrId, recordId : this.recordId})
        .then(result => {
            if(result && result.length >0){
                const mappedSteps = result.map(record => ({
                    id: record.Id,
                    index: record.Step_Sequence__c,
                    customer: record.Customer_Contribution__c || '',
                    financer: record.Financer_Contribution__c || '',
                    makeCustomerDisabled: !!record.Financer_Contribution__c,
                    makeFinancerDisabled: !!record.Customer_Contribution__c,
                    contributor : record.Contributor__c
                }));
                this.steps = [...mappedSteps];

            }
            else{
                //calling this only if no steps in transactional obj exist
                 this.getOcrSteps(); //using this to get default OCR steps from master >> need to indulge it to get OCR steps in transaction obj in case already existing.
            }
        })
    }

    getOcrSteps(){
        getOcrRecordsByOcrId({ ocrId: this.ocrId })
        .then(result => {
            console.log('ocrresult',result);
            if (result && result.length > 0) {
                const firstRecord = result[0];
                console.log('firstRecord>>>'+JSON.stringify(firstRecord));

                console.log('ocrDefinitionFields>>>'+JSON.stringify(this.ocrDefinitionFields));


                // Populate parent fields from child.. since all the data in these child fields is samme
                this.ocrDefinition.ocrType = firstRecord.OCR_Type__c;
                this.ocrDefinition.customerPortion = firstRecord.Customer_Portion__c;
                this.ocrDefinition.ocrDescription = firstRecord.OCR_Description__c;

                // Update UI fields
                this.ocrDefinitionFields = this.ocrDefinitionFields.map(field => {
                    if (field.fieldName === 'ocrType') {
                        return { ...field, fieldValue: firstRecord.OCR_Type__c, disabled: true };
                    }
                    if (field.fieldName === 'customerPortion') {
                        return { ...field, fieldValue: firstRecord.Customer_Portion__c, disabled: true };
                    }
                    if (field.fieldName === 'ocrDescription') {
                        return { ...field, fieldValue: firstRecord.OCR_Description__c, disabled: true };
                    }
                    if (field.fieldName === 'totalReceivable') {
                        return { ...field, fieldValue: firstRecord.Total_OCR_Receivable__c, disabled: true };
                    }
                    if(field.fieldName == 'totalDemand'){
                        this.demandTotal = field.fieldValue;
                    }
                    return field;
                });

                console.log('this.demandTotal>>>'+ this.demandTotal);
          

                this.ocrDefinitionFields = this.ocrDefinitionFields.map(field => {
                    if (field.fieldName === 'totalReceivable') {
                          this.calculatedReceivable = (firstRecord.Customer_Portion__c / 100) *  this.demandTotal;
                        console.log('calculatedReceivable>>>'+this.calculatedReceivable); ;
                        return { ...field, fieldValue: this.calculatedReceivable, disabled: true };
                    }
                    
                    return field;
                });

                  console.log('ocrDefinitionFields after>>>'+JSON.stringify(this.ocrDefinitionFields));


               this.ocrDefinition = {...this.ocrDefinition};
               this.ocrDefinitionFields = [...this.ocrDefinitionFields];


                const mappedSteps = result.map(record => ({
                    id: record.Id,
                    index: record.Step_Sequence__c,
                    customer: record.Customer_Contribution__c || '',
                    financer: record.Financer_Contribution__c || '',
                    makeCustomerDisabled: !!record.Financer_Contribution__c,
                    makeFinancerDisabled: !!record.Customer_Contribution__c,
                    contributor : record.Contributor__c
                }));
                this.steps = [...mappedSteps];
                //this.originalSteps = [...mappedSteps]; // keep a reference
            } else {
                const defaultStep = {
                    //id: Date.now(),
                    index: 1,
                    customer: null,
                    financer: null,
                    makeCustomerDisabled: false,
                    makeFinancerDisabled: false
                };
                this.steps = [defaultStep];
                //this.originalSteps = [defaultStep];
            }
            this.isLoading = false;
        })
        .catch(error => {
            console.error('Error fetching charges:', error);
            this.isLoading = false;
            this.showToastMessage('Error', 'Failed to fetch OCR details', 'error');
        });
    }
    

    /*comment for now.. no logic to put cancel there.
    handleCancel() {
        this.steps = [];
    }*/

    handleSelectedOcr(event){
        console.log('504 calling handle Selected Ocr');
        this.showapplicablefor = false;
        this.selectedId = event.detail.searchRecord.Id;
        console.log('selectedIDINOCrDetail',this.selectedId);
        this.ocrId = event.detail.searchRecord.OCR_ID__c;
        this.isLoading = true; //spinner
        this.getOcrSteps(); //steps will come from the master level of whatever OCR ID selected.
        console.log('511>>> '+ JSON.stringify( this.ocrDefinition));
        
    }
    
    handledeselectedOcr(){
         this.selectedId = '';
         this.steps = [{ index:1, customer: null, financer: null, makeCustomerDisabled: false, makeFinancerDisabled:false }];

         
        this.ocrDefinition = {
            ocrDescription: '',
            customerPortion: '',
            ocrType: '',
            totalDemand: '',
            totalReceivable: '',
            totalDemandReceived: '',
            totalOcrReceived: ''
        };
        
        this.ocrDefinitionFields = this.ocrDefinitionFields.map(field => {
            if (field.fieldName === 'ocrType' || field.fieldName === 'customerPortion' || field.fieldName ==='ocrDescription' || field.fieldName ==='totalReceivable') {
                return { ...field, fieldValue: '', disabled: true };
            }
            /*
            else{
                return { ...field, fieldValue: '', disabled: false };
            }*/
            return field;
        });
         this.saveButtonDisabled = true;
         //this.allChecklist = [];
    }
    handleaddNew(event){
        this.template.querySelector('c-search-lookup').handleReset(event);
        this.showapplicablefor = true;
    }
     handleOcrSaved(event) {
       // this.recordId = event.detail.recordId;
       const txnComp = this.template.querySelector('c-ocr-transaction-details');
       console.log('txnComp>>>>'+txnComp);
        if (txnComp) {
            txnComp.refreshData();
        }
    }

    handleAccordionBtn() {
        this.refs.btnTag.classList.toggle('save-button')
        this.refs.btnTag.classList.toggle('close-button');
        if (this.refs.btnTag.innerText == 'Open All') {
            let accordionNameList = [];
            Array.from(this.template.querySelectorAll('lightning-accordion-section')).forEach(item => {
                accordionNameList.push(item.name);
            });
            this.activeSections = [...accordionNameList];
            this.refs.btnTag.innerText = 'Close All';
        } else {
            this.activeSections = [];
            this.refs.btnTag.innerText = 'Open All';
        }

    }

    showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: type,
        });
        this.dispatchEvent(toastEvent);
    }

    renderedCallback() {
        if (this.firstTimeLoaded) {
            this.refs.btnTag.innerText = 'Open All';
            this.firstTimeLoaded = false;

            const style = document.createElement("style");
            style.innerText = `
            .slds-accordion__list-item .section-control {
                background: #c5c5c5;
                color: black;
                margin-left: 0px;
                margin-bottom: 0px;
                margin-right: 0px;
                font-weight: 500;
            }
            .slds-accordion__summary {
                padding: 10px 0px 10px 0px;
            }
            /* Hide border and apply bottom border only */
            .hideInput .slds-input {
                border: none !important; /* Remove all default borders */
                border-bottom: 1px solid black !important; /* Add only bottom border */
                background-color: transparent;
                outline: none;
                box-shadow: none;
                border-radius: 0 !important; /* Remove curved edges */
                padding: 4px; /* Adjust padding if necessary */
            }
            .removeborder .slds-combobox__input {
                border: none !important;  /* Remove border */
                box-shadow: none !important;  /* Remove any shadow */
                background-color: transparent;  /* Ensure no background color */
                 border-bottom: 1px solid black !important; /* Add only bottom border */
                 border-radius: 0 !important; /* Remove curved edges */
                 padding:5px

            }

            `;

            this.template.querySelector(".styleContainer")?.appendChild(style);
        }
    }
}