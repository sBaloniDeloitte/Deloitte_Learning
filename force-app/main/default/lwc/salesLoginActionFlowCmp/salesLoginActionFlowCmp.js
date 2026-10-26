import { LightningElement,api,track,wire } from 'lwc';
import { fireEvent } from 'c/pubsub'; 
import { NavigationMixin } from "lightning/navigation";
import { CurrentPageReference } from 'lightning/navigation'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getActionList from '@salesforce/apex/COMM_SalesLoanActionsController.getActionList';
import getCompletionStatus from '@salesforce/apex/LoanActionController.getCompletionStatus';
import getSubStageList from '@salesforce/apex/COMM_SalesLoanActionsController.getSubStageList';
import exceptionCheck from '@salesforce/apex/COMM_SalesLoanActionsController.exceptionCheck';
import getCollateralRecordsByLoanAppId from '@salesforce/apex/COMM_SalesCollateralDetailsController.getCollateralRecordsByLoanAppId';
import fetchAllProducts from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.fetchAllProducts';

export default class SalesLoginActionFlowCmp extends LightningElement {
    @api recordId;
    @wire(CurrentPageReference) pageRef; 
    @api loanid;
    subStageList = [];
    isRendered = false;
    processedStages  = [];
    @track actionList;
    @track showcmp;
    @track coApplicantAdded;
    @track assetAdded;
    @track bankAdded;
    @track imdCollected;
    @track showAppScore=false;
    @track showCoApp = false;
    @track allcommplete=false;
    @track openConfirm = false;
    @track collateralList = [];
    isLoaded = false;
    formName;
    applicableStage = 'Applicant Information';
    isRelatedToApplicantInformation = true;
    
    @api changeMessage(str) {
        console.log('this.loanid --> loan action flow'+ this.loanid);
        console.log('this.recordId -->'+ this.recordId);
        console.log('Inside LoanLoginActionFlowCmp Refresh', str);
        if(str =='Login Fees'){
            this.applicableStage ='Income Eligibility'
        }
        console.log('Inside LoanLoginActionFlowCmp Refresh 42', str);
        this.isLoaded = true;
        setTimeout(() => {
            console.log('before get action 1');
            this.getActions();
            this.isLoaded = false;
        },500)
        //this.getActionStatus();
        const screenNAme= str;
        if(this.recordId == undefined || this.recordId == null || this.recordId == ''){
            if(this.loanid != null && this.loanid != undefined){
                this.recordId = this.loanid;
            }
        }
        console.log('screenANme--', screenNAme);
        var newStage;
        if(screenNAme == 'Application Information'){
            newStage = 'Income Eligibility';
        }
        if(screenNAme =='Select Income Eligibility'){
            newStage = 'Document Details';
        }
        if(screenNAme =='Exception Approval'){
            newStage = 'Login Checklist';
        }
        else if(screenNAme=='Document Details'){
            newStage = 'Collateral';
        }
        if(screenNAme =='Additional Information'){
            console.log('recordId in actionfloe---', this.loanid);
            newStage = 'Other Information';
           /* exceptionCheck({
                loanId : this.loanid
            }).then(response=>{
                console.log('Inside exception check response----', response);
                if(response== true){
                    newStage = 'Exception Flow';
                }else{
                    newStage = 'Other Information';
                }
            }).catch(error=>{
                console.log('Inside exception check error----', error);
                
            })*/
            // newStage = 'Document Details';
        }
        console.log('newStageeee----', newStage);
        
        setTimeout(() => {
            console.log('Isndeu timeoutjjj');
            
            if(newStage){
                this.actionList?.forEach(item => {
                    console.log('item.name---', item.name);
                    
                    if(item.name == newStage){
                        item.isActive = true;
                    }
                    else{
                        item.isActive = false;
                    }
    
                    const value = '';
                    const name = newStage;
                    console.log('event.currentTarget.dataset.id -245-> '+newStage);
                    const valueChangeEvent = new CustomEvent("valuechange", {
                        detail: { value,name }
                    });
                    console.log('event.currentTarget 261-> '+newStage);
                    this.dispatchEvent(valueChangeEvent);
                    // console.log('item.name --> '+item.name);
                    // console.log('item.id --> '+item.id);)
                });
                console.log('this.actionListin change message ----', JSON.stringify(this.actionList));
            }
           
            
        },1500)
    }
    @api changeMessageFinal(str) {
        console.log('this.loanid --> loan action flow'+ this.loanid);
        console.log('this.recordId -->'+ this.recordId);
        console.log('Inside LoanLoginActionFlowCmp Refresh 42', str);
        this.isLoaded = true;
        setTimeout(() => {
             console.log('before get action 2');
            this.getActions();
            this.isLoaded = false;
        },500)
        //this.getActionStatus();
        const screenNAme= str;
        if(this.recordId == undefined || this.recordId == null || this.recordId == ''){
            if(this.loanid != null && this.loanid != undefined){
                this.recordId = this.loanid;
            }
        }
        var newStage;
        if(screenNAme =='Additional Information'){
            console.log('recordId in actionfloe---', this.loanid);
            
            exceptionCheck({
                loanId : this.loanid
            }).then(response=>{
                console.log('Inside exception check response----', response);
                if(response== true){
                    newStage = 'Exception Flow';
                }else{
                    newStage = 'Other Information';
                }
            }).catch(error=>{
                console.log('Inside exception check error----', error);
                
            })
            // newStage = 'Document Details';
        }
        console.log('newStageeee----', newStage);
        
        setTimeout(() => {
            console.log('Isndeu timeoutjjj');
            
            if(newStage){
                this.actionList?.forEach(item => {
                    console.log('item.name---', item.name);
                    
                    if(item.name == newStage){
                        item.isActive = true;
                    }
                    else{
                        item.isActive = false;
                    }
    
                    const value = '';
                    const name = newStage;
                    // console.log('item.name --> '+item.name);
                    // console.log('item.id --> '+item.id);)
                });
                console.log('this.actionListin change message ----', JSON.stringify(this.actionList));
            }
           
            
        },1500)
    }
    @api changeColor(newStage){
        console.log('Inside LoanLoginActionFlowCmp changeColor', newStage);
        setTimeout(() => {
            console.log('Isndeu timeoutjjj');
            setTimeout(() => {
                 console.log('before get action 3');
                this.getActions();
                this.isLoaded = false;
            },500)
            this.actionList?.forEach(item => {
                if(item.name == newStage){
                    item.isActive = true;
                }
                else{
                    item.isActive = false;
                }

                // const value = '';
                // const name = newStage;
                // console.log('event.currentTarget.dataset.id -245-> '+newStage);
                // const valueChangeEvent = new CustomEvent("valuechange", {
                //     detail: { value,name }
                // });
                // console.log('event.currentTarget 261-> '+newStage);
                // this.dispatchEvent(valueChangeEvent);
                // console.log('item.name --> '+item.name);
                // console.log('item.id --> '+item.id);)
            });
            console.log('this.actionListin change message ----', JSON.stringify(this.actionList));
            
        },1500)
    }
    @api highlightScreen(str) {
        console.log('this.loanid --> loan action flow'+ this.loanid);
        console.log('this.recordId -->'+ this.recordId);
        console.log('str=:'+str);
        console.log('Inside Highlight login');
        console.log('this.actionList=:39'+JSON.stringify(this.actionList));
         console.log('before get action 4');
        this.getActions();
        if(this.recordId == undefined || this.recordId == null || this.recordId == ''){
            if(this.loanid != null && this.loanid != undefined){
                this.recordId = this.loanid;
            }
        }
        setTimeout(()=>{
            this.actionList?.forEach(item => {
                if(item.name == str){
                    item.isActive = true;
                }
                else{
                    item.isActive = false;
                }
            });
        },1500)
        // this.getActionStatus();
    }
    @api refreshActions(str){
         console.log('before get action 5');
        this.getActions();
    }
    get isMobile() {
        return FORM_FACTOR === 'Large' ? 'line slds-align_absolute-center' : 'linemobile slds-align_absolute-center';
    }
    // get processedStages() {
    //     return this.subStageList.map((stage, index) => ({
    //         ...stage,
    //         showLine: index !== this.subStageList.length - 1 
    //     }));
    // }
                
    

    async connectedCallback(){
        try{
            await this.fetchAllProducts();
            await this.getCollateral();
             console.log('before get action 6');
            
            console.log('this.loanid --> loan action flow'+ this.loanid);
            console.log('this.recordId -->'+ this.recordId);
            
            if(this.recordId == undefined || this.recordId == null || this.recordId == ''){
                if(this.loanid != null && this.loanid != undefined){
                    this.recordId = this.loanid;
                }
            }
            if(this.applicableStage == 'Applicant Information'){
                this.isRelatedToApplicantInformation = true;
                this.formName = 'Loan Login Form';
                console.log('this.loanid --> loan action flow'+ this.loanid);
                console.log('action List=>',JSON.stringify(this.actionList));
                setTimeout(()=>{
                    this.actionList?.forEach(item => {
                        console.log('376',item.name)
                        console.log('377',this.applicableStage);
                        if(item.name == this.applicableStage){
                            item.isActive = true;
                        }
                        else{
                            item.isActive = false;
                        }
                    });
                },1500)
                // const name = 'Applicant Information'
                // const value ='';
                // const valueChangeEvent = new CustomEvent("valuechange", {
                //     detail: { value,name }
                // });
                // this.dispatchEvent(valueChangeEvent);
                 this.getActions();
            }
            else{
                this.isRelatedToApplicantInformation = false;
                
                    this.getSubStageList();
                
                
                
                
                
            }
            
            if(this.recordId != undefined){
                this.showcmp = true;
                
                this.loanid=this.recordId;
            }
        
            console.log('Inside LoanLoginActionFlowCmp');
        
            registerListener("refreshLoanActions", this.getSubStageList, this);
        
            //this.getActionStatus();
        }catch(e){
            Console.log('Exception in connectedcallback: '+e);
        }
    }

    disconnectedCallback() { 
        unregisterAllListeners(this); 
    }


    /*getActions(){
        console.log('this.recordId --342>'+this.recordId);
        getActionList({
            loanId : this.loanid
        }).then(response=>{
            console.log('response(getAction) for Login button -346- loan Action>'+JSON.stringify(response));
            console.log('products in get actions>>'+JSON.stringify(this.products));
            this.actionList = response;
            this.actionList?.forEach(item => {
                if(item.name == 'Income Eligibility'){
                    item.name = 'Eligibility';
                }
            });
            setTimeout(() => {
                this.getSubStageList()
            },10);
            // if(response != undefined && response.length>0){
            //     this.allcommplete = response[0].isAllComplete;
            // }
            this.showcmp = true;
        }).catch(error=>{

        })
    }*/
   getActions() {
        console.log('this.recordId -342>' + this.recordId);
        console.log('this.products -343>' + this.loanid);
        getActionList({
            loanId: this.loanid
        }).then(response => {
            console.log('response(getAction) for Login button -346- loan Action' + JSON.stringify(response));
            console.log('products in get actions>>' + JSON.stringify(this.products));

            // Step 1: Check for sub-product presence
            const hasBuilderPurchase = this.products?.some(prod => prod.subProdName === 'HL Builder Purchase');
            const hasResalePurchase = this.products?.some(prod => prod.subProdName === 'HL Resale Purchase');
            console.log('hasBuilderPurchase>', hasBuilderPurchase);
            console.log('hasResalePurchase>', hasResalePurchase);
            // Step 2: Check if any collateral has apfValue === "No"
            const hasApfValueYes = this.collateralList?.some(c => c.apfValue === "Yes");
            console.log('hasApfValueYes>',hasApfValueYes);
            // Step 3: Filter response based on above
            const filteredResponse = response.filter(action => {
           /* if (!hasApfValueNo) {
            // Remove both Builder and Seller Details if apfValue != "No" for all
            return (action.name !== 'Builder Details' && action.name !== 'Seller Details');
            }*/

            if (action.name === 'Builder Details' && (!hasBuilderPurchase || !hasApfValueYes)) {
             return false;
            }

            if (action.name === 'Seller Details' && (!hasResalePurchase || !hasApfValueYes)) {
             return false;
            }

             return true;
            });

            // Step 4: Save to component
            this.actionList = filteredResponse;

            // Step 5: Rename "Income Eligibility" to "Eligibility"
            this.actionList?.forEach(item => {
            if (item.name === 'Income Eligibility') {
            item.name = 'Eligibility';
            }
            });

            setTimeout(() => {
                this.getSubStageList();
            }, 10);

            this.showcmp = true;
        }).catch(error => {
            console.error(error);
        });
    }


    // getActionStatus(){
    //     console.log('this.recordId=:'+this.recordId);
    //     getCompletionStatus({
    //         loanId : this.loanid
    //     }).then(response=>{
    //         console.log('response=:'+JSON.stringify(response));
    //         if(response.coApplicantAdded){
    //             this.coApplicantAdded = 'font-size: 20px;color: green;'
    //         }
    //         else{
    //             this.coApplicantAdded = 'font-size: 20px;color: green;'
    //         }

    //         if(response.imdCollected){
    //             this.imdCollected = 'font-size: 20px;color: green;'
    //         }
    //         else{
    //             this.imdCollected = 'font-size: 20px;color: green;'
    //         }

    //         if(response.bankAdded){
    //             this.bankAdded = 'font-size: 20px;color: green;'
    //         }
    //         else{
    //             this.bankAdded = 'font-size: 20px;color: green;'
    //         }

    //         if(response.assetAdded){
    //             this.assetAdded = 'font-size: 20px;color: green;'
    //         }
    //         else{
    //             this.assetAdded = 'font-size: 20px;color: green;'
    //         }
    //     }).catch(error=>{

    //     })
    // }
    handleClick(event){
            console.log('event.currentTarget.dataset.id --> '+event.currentTarget.dataset.id);
            this.applicableStage = event.currentTarget.dataset.id;
            if(this.applicableStage == 'Applicant Information'){
                this.isRelatedToApplicantInformation = true;
            }
            else{
                this.isRelatedToApplicantInformation = false;
                 console.log('before get action 7');
                //this.getActions();
                this.getSubStageList();
                
                
            }
            const value = '';
            const name = event.currentTarget.dataset.id;
            this.actionList?.forEach(item => {
                if(item.name == event.currentTarget.dataset.id){
                    console.log('item.name --> '+item.name);
                    item.isActive = true;
                }
                else{
                    item.isActive = false;
                }
                
            });
            
            console.log('event.currentTarget.dataset.id -245-> '+event.currentTarget.dataset.id);
            const valueChangeEvent = new CustomEvent("valuechange", {
                detail: { value,name }
            });
            console.log('event.currentTarget 261-> '+event.currentTarget.dataset.id);
        this.dispatchEvent(valueChangeEvent);
            
    }
    loginLoan(){
        this.openConfirm=true;
        const scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
    }
    
    // handleYes(){
    //     console.log('this.loanid --> '+this.loanid);
    //     changeLoanStage({
    //         loanid : this.loanid
    //     }).then(response=>{
    //         this[NavigationMixin.Navigate]({
    //             type: 'standard__recordPage',
    //             attributes: {
    //                 recordId: this.loanid,
    //                 actionName: 'view' // Use 'view' for viewing the record
    //             }
    //         });
    //     }).catch(error=>{
    //         console.log('error login Loan Handle Yes - > '+JSON.stringify(error));
    //         console.error('error login Loan Handle Yes - > '+JSON.stringify(error));
    //     })
    // }
    
    handleCancel(){
        this.openConfirm=false;
    }

    hideDiscrepancyBox(){
        this.openConfirm=false;
    }

    handlecloseovd(){
        this.openOVDCmp= false;
        this.showcmp = true;
    }

    getSubStageList(){
        this.subStageList = null;
        console.log('this.recordId 404=:'+this.recordId);
        console.log('this.recordId 404=:'+this.loanid);
        console.log('this.applicableStage 404=:'+this.applicableStage);
        console.log('this.formName 404=:'+this.formName);
    
        getSubStageList({
            loanId : this.loanid,
            applicableStage : this.applicableStage,
            formName:this.formName
        })
        .then(response => {
            console.log('Substage response: loan action flow577', response);
            this.subStageList = response;  // Ensure subStageList is updated
    
            this.processedStages = this.subStageList.map((stage, index, array) => ({
                ...stage,
                showLine: index > -1 
                
                // showLine: index > -1  // Show line between icons, but not before the first icon
            }));
            
            console.log('this.processedStages---', JSON.stringify(this.processedStages));
            
            
        })
        .catch(error => {
            console.log('Error getting sub stage list:', JSON.stringify(error));
        });
    }
    @api
    navigateNext(event){
        console.log('inside parent actionn event----', event.detail);

        this.applicableStage = event.detail;

        console.log(this.applicableStage, 'fcgvhbj');
        
        if(this.applicableStage == 'Applicant Information'){
            this.isRelatedToApplicantInformation = true;
        }
        else{
            this.isRelatedToApplicantInformation = false;
            this.getSubStageList();
            
            
        }
        const value = '';
        const name = this.applicableStage;
        this.actionList?.forEach(item => {
            if(item.name == this.applicableStage){
                item.isActive = true;
            }
            else{
                item.isActive = false;
            }
            
        });
        
        console.log('event.currentTarget.dataset.id -245-> '+this.applicableStage);
        const valueChangeEvent = new CustomEvent("valuechange", {
            detail: { value,name }
        });
        console.log('event.currentTarget 261-> '+this.applicableStage);
        this.dispatchEvent(valueChangeEvent);
    }
    async fetchAllProducts(){
        await fetchAllProducts({ loanId: this.recordId })
            .then((result) => {
                console.log('fetchAllProducts: '+JSON.stringify(result));
                this.products = result;
                
            })
            .catch((error) => {
                console.error('Error fetching products:', error);
            });
        }
        async getCollateral() {
           await getCollateralRecordsByLoanAppId({ loanAppId: this.recordId })
                .then(result => {
                    this.collateralList = result;
                    console.log('Result:', JSON.stringify(result));
                })
                .catch(error => {
                    //this.showToast('Error', error.body?.message || 'Failed to load collateral records', 'error');
                });
        }
        }