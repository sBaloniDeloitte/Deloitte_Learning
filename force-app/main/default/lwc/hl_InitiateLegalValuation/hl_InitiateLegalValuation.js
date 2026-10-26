import { LightningElement,api,track, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { deleteRecord,updateRecord, getRecord} from 'lightning/uiRecordApi';
import getLegalRecords from '@salesforce/apex/Hl_LegalRecordPageController.getLegalRecords';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import getApprovalSataus from '@salesforce/apex/Utility.getApprovalSataus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";//sanwar(4/12/2025)
import canUserEditRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.canUserEditRecord';//sanwar(4/12/2025)

//import setDocument from '@salesforce/apex/GenericInitiateController.setDocument';
//import deleteContent from '@salesforce/apex/GenericInitiateController.deleteContent';
//import uploadFile from '@salesforce/apex/FieldInvestigationController.uploadFile';

export default class Hl_InitiateLegalValuation extends NavigationMixin(LightningElement) {
     @api recordId;
    @api activeSection = [];
    @api isModalOpen = false;
    @api objectName = 'Legal__c'
    @track documents = []
    @track disabledCmp = false;
    @track oppSubStage = '';//sanwar(4/12/2025)
    currentDocId;
    currentIndex;
    rendered = false;
    showLegalTable = false
    @track showInitiateLegal = true;
    //HL
    product
    showHLRelatedData = false;
    //HL

    openModal(){this.isModalOpen = true;}

    handleMainButton(){
        console.log('inside block>>>');
         getApprovalSataus({ loanId: this.recordId })
                .then((res) => {
                    console.log('res>>>'+res);
                    if(res == 'Soft Rejected 1' || res == 'Soft Rejected 2' ||res =='Hard Rejected') {
                    this.dispatchEvent(
                    new ShowToastEvent({
                    title: 'Error',
                    message: 'Verification cannot be initiated because the loan application status is Rejected',
                    variant: 'Error'
                })
                )
                this.isModalOpen = false;
                return;
                    }
                })
                .catch((error) => {
                    console.error('Error getCurrentUserProfileName --> '+ error);
                });
        this.isModalOpen = true;
    }

    connectedCallback(){
        this.setLegalRecords();
        this.fetchLoanStage();
        //HL
        this.getProductDetails();
        //HL
        this.checkCmpEditability();
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

    closeModal(){
        this.isModalOpen = false;
        const valueCloseEvent = new CustomEvent('closechecksmodal', {});
        this.dispatchEvent(valueCloseEvent);
    }

    renderedCallback(){
        
    }

    viewDocument(evt){
        let contentId = evt.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: contentId
            }
        })
    }

    setLegalRecords(){
        getLegalRecords({recordId : this.recordId}).then(response =>{
            this.groupLegalsByCollateral(response);
            /*if(this.progressStep.step4){this.progressStep.step5 = true;}
            this.legals = response;
            //console.log('legal records',response);
            
            if(this.legals.length>0){
                this.showLegalTable = true;
            }
            this.getLegalUser();*/
        }).catch(error=>{
            console.error(error)
        })
    }

    groupLegalsByCollateral(records) {
        const grouped = {};

        records.forEach((rec) => {
            if(!rec.collateralType) return;
            const collateral = rec.collateralType;

            if (!grouped[collateral]) {
                grouped[collateral] = [];
            }

            grouped[collateral].push(rec);
        });

        this.groupedLegals = Object.keys(grouped).map(collateral => {
            const group = grouped[collateral];

            return {
                collateral,
                rowspan: group.length,
                records: group.map((r, i) => ({
                    ...r,
                    srno: i + 1, //  reset srno for each collateral
                    isFirst: i === 0,
                    styleClass: i === 0 
                    ? 'padding-left:20px; margin-left:3px;border-left: 1px solid #d8dde6;'
                    : 'padding-left:20px; border-left: 1px solid #d8dde6;'
                }))
            };
        });

        this.showLegalTable = this.groupedLegals.length > 0;
        console.log('this.showLegalTable>>>'+this.showLegalTable)
    }
    
    // handleUpload(evt){
    //     const file = evt.target.files[0]
    //     var reader = new FileReader()
    //     reader.onloadend = async () => {
    //         const base64Data = reader.result.split(',')[1]; // Extract base64 data
    //         const fileName = file.name;
    //         const fileType = file.type;
    //         const result = await uploadFile({ base64Data, fileName, fileType });
    //         console.log('the content Id : '+result)
    //         this.updateContentId(result);
    //     }
    //     reader.readAsDataURL(file)

    // }

    updateContentId(value){
        const fields = {};
        fields['Id'] = this.currentDocId;
        fields['Content_Document_Id__c'] = value;

        const recordInput = { fields };
        updateRecord(recordInput)
        .then(() => {
            this.documents[this.currentIndex].isUploaded = false;
            this.documents[this.currentIndex].contentId = value;
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
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
                    if(res == 'Sales' || res == 'Ops') {
                        this.showInitiateLegal = false;
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

    uploadDocument(evt){
        this.currentDocId = evt.currentTarget.dataset.id;
        this.currentIndex = evt.currentTarget.dataset.index;
        this.template.querySelector('.genericFileUpload').click();
    }
    // deleteDocument(evt){
    //     let currentId = evt.currentTarget.dataset.id;
    //     let curIndex = evt.currentTarget.dataset.index;
    //     deleteContent({contentId: currentId,recordId: this.recordId})
    //     .then(response => {
    //         this.documents[curIndex].isReqired = false;
    //         this.documents[curIndex].isUploaded = true;
    //     }).catch(error => {
    //         console.log(error)
        
    //      })
    // }

    // connectedCallback(){
    //     setDocument({
    //         recordId: this.recordId
    //     })
    //     .then(response => {
    //         this.documents = response
    //         console.log('The Value is : '+response);
    //     })
    //     .catch(error => {
    //         console.log(error);
    //     });

    // }

    handleSectionToggle(event){
        if(event.target.name != undefined && event.target.name != '' && event.target.name != null){
            this.activeSection = event.target.name;
        }
        
    }
    //HL
    getProductDetails(){
        const inputMap = {
            'oppId': this.recordId
        };
        getProductDetails({inputMap: inputMap})
        .then(response => {
            console.log('214---',JSON.stringify(response));
            this.product = response.loanProduct;
            if(this.product == 'Home Loan'){
                this.showHLRelatedData = true;
            }
        })
        .catch(error => {
            console.log(error);
        });
    }
    
    navigateToRecord(event) {
        window.open(`/${event.currentTarget.dataset.id}`, '_blank');
    }
    //HL


}