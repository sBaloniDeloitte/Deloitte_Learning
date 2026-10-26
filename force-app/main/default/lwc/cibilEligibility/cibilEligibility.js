import { LightningElement,track, api,wire } from 'lwc';
import ELIGIBLE_ICON from '@salesforce/resourceUrl/SuccessIconEligibility';
import getScreenFieldData from '@salesforce/apex/COMM_CibilEligibilityController.getScreenFieldData';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import LOAN_APPLICATION_OBJECT from "@salesforce/schema/Opportunity";
import { getObjectInfo } from 'lightning/uiObjectInfoApi'
import program from '@salesforce/schema/Opportunity.Program__c';
import { updateRecord } from "lightning/uiRecordApi";
import applicantDetails from '@salesforce/apex/LoanLoginChangeApplicantTypeController.applicantDetails'
//import initiateFICO from '@salesforce/apex/Sales_FICOController.initiateFICO'
// import Exception_confirmation from '@salesforce/label/c.Exception_confirmation';
import NOT_ELIGIBLE_ICON from '@salesforce/resourceUrl/RejectIconEligibility';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CibilEligibility extends LightningElement {

    @api screenName = 'Bureau Health Screen'; // Dynamic screen name
    @track tableData = [];
    @api applicantDetailId;
    @api parentScreen;
    @api loanid;
    @track isDetailsVisible = false;
    @api showChangeProgramButton= false;
    openProgramchangePop=false;
    @track programOptions;
    selectedProgram;
    @api fromSales = false;
    cibilScoreLow= false;
    @api recordId;
    showError = false;
    errorList= [];
    isloading= false;
    
    /*@track tableData = [
        {
            id: '1',
            name: 'Bureau Parameters for Key Applicant',
            rows: [
                { id: '1.1', key: 'CRIF Segment', value: 'Low Risk', isFirstRow: true, colorClass: 'highlight-color' },
                { id: '1.2', key: 'No. of unsecured loans availed in last 6m', value: '1', isFirstRow: false },
                { id: '1.3', key: 'CIBIL Score', value: '780', isFirstRow: false, colorClass: 'highlight-color' },
                { id: '1.4', key: 'No. of enquiries in last 3m', value: '1', isFirstRow: false },
            ],
        }
    ];*/
      fetchApplicants(){
            applicantDetails({recordId : this.recordId})
            .then(result => {
                console.log('result:: 42 ' + JSON.stringify(result));
                this.applicantList = [...result];
                
                for(var i=0;i<this.applicantList.length;i++){
                    console.log('this.applicantDetailId----',this.applicantDetailId);
                    if(this.applicantList[i].applicantId == this.applicantDetailId && this.applicantList[i].iscibilLow==true){
                        this.cibilScoreLow=true;
                        console.log('this.cibilScoreLow----',this.cibilScoreLow);
                        break;
                    }
                }
        
                if(this.cibilScoreLow){
                    this.showExceptionConfirmation= true;
                }
            })
        }
    


    @track showEligibleTemplate = true;
    eligibleIcon;

    
    @wire(getObjectInfo, { objectApiName: LOAN_APPLICATION_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: program })
    getProductOptions({ data, error }) {
        if(data) {
            this.programOptions = data.values;
            console.log('programOptions:  '+this.programOptions);
        }
    }

    connectedCallback(){
        this.notEligibleIcon = NOT_ELIGIBLE_ICON;
        this.eligibleIcon = ELIGIBLE_ICON;
       // this.initiateFICO();

        
      
        this.fetchApplicants();
        
    }

    initiateFICO(){
        this.isloading = true;
        const inputMap ={
                'processName':'FICO Cibil And Income Eligibility',
                 'recordId': this.recordId,
                  'applicantId': this.applicantDetailId

        }
        initiateFICO({inputMap: inputMap})
        .then(result => {
            this.isloading = false;
            console.log('result::');
            console.log(JSON.stringify(result));
              if(result.includes('Error:')){
                               this.errorList = result
                                console.log('errorList--'+this.errorList);
                                this.showError = true;
                                this.showEligibleTemplate = false;
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: 'The system was unable to fetch FICO Since Cibil hasnt been triggered',
                                        variant: 'error',
                                    }),
                                );
                }
                else{
                   console.log(JSON.stringify(result));
                    this.showEligibleTemplate = true;
                    this.showError = false;
                    console.log('Show Eligigi');
                    this.loadScreenFields();
                }


            })
        .catch((error) => {
            console.error('Error fetching screen fields:', error);
            this.isloading = false;
        });


    }
    
    @track buttonLabel = 'Show More Details';  // Initial button label
    // Method to toggle the visibility
    toggleDetails(event) {
        event.stopPropagation();
        this.isDetailsVisible = !this.isDetailsVisible;
        // Update button label based on the visibility of the details section
        this.buttonLabel = this.isDetailsVisible ? 'Hide Details' : 'Show More Details';
    }

    handleStopPropogation(event){
        event.stopPropagation();
    }

    loadScreenFields() {
        console.log('Show Eligigi-------- 151',this.screenName);
        getScreenFieldData({ screenName: this.screenName, applicantId:this.applicantDetailId })
            .then((result) => {
                this.tableData = result;
                console.log('this.tableData 155 -->'+JSON.stringify(this.tableData));
            })
            .catch((error) => {
                console.error('Error fetching screen fields:', error);
            });
    }

    formatTableData(screenFields) {
        let rows = screenFields.map((field, index) => ({
            id: field.Field_Sequence__c,
            key: field.Field_Label__c,
            value: field.Read_Field_Name__c,
            isFirstRow: index === 0,
            colorClass: field.Condition__c === 'highlight' ? 'highlight-color' : ''
        }));

        return [
            {
                id: '1',
                name: 'Bureau Parameters for Key Applicant',
                rows: rows
            }
        ];
    }

    handleYesConfirmation(event){
        event.stopPropagation();
        this.dispatchEvent(new CustomEvent('changescreen', {
            detail: {
            }
        }));
        if(this.parentScreen == 'Co Applicant'){
            this.dispatchEvent(new CustomEvent('changescreen', {
                detail: {applicantDetailId:this.applicantDetailId, recordId:this.loanid
                }
            }));
        }
    }
    handleProgramChange(event){
        event.stopPropagation();
        this.openProgramchangePop=true;
        // this.dispatchEvent(new CustomEvent('changescreenaa', {
        //     detail: {
        //     }
        // }));
    }
    handleSelectedProgram(event){
        event.stopPropagation();
        this.selectedProgram=event.target.value;
       

    }
    handleChangeProgram(event){
        event.stopPropagation();
        const fields = {};
        fields['Id'] = this.loanid;
        fields['Program__c'] = this.selectedProgram;
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
        .then(() => {
            console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
            this.openProgramchangePop=false;
            const valueChangeEvent = new CustomEvent("screenchangeitr", {
                detail: { }
            });
            this.dispatchEvent(valueChangeEvent);
            
                 
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
    }
    handleCancel(event){
        event.stopPropagation();
        this.openProgramchangePop=false;
    }

}