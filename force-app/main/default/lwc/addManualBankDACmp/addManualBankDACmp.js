import {LightningElement,track,api,wire} from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import manualDerivedAnalysis from "@salesforce/apex/COMM_BsaCmpController.manualDerivedAnalysis";
import createMonthlyRecs from "@salesforce/apex/COMM_BsaCmpController.createMonthlyRecs";
import removeMonthltRec from "@salesforce/apex/COMM_BsaCmpController.removeMonthltRec";
import getApplicationApplicants from '@salesforce/apex/COMM_ManualBankingController.getApplicationApplicants';
import getBankList from '@salesforce/apex/COMM_ManualBankingController.getBankList';
import createBankDetail from '@salesforce/apex/COMM_ManualBankingController.createBankDetail';
import fetchBankDetails from '@salesforce/apex/COMM_ManualBankingController.fetchBankDetails';
import updateBankDetails from '@salesforce/apex/COMM_ManualBankingController.updateBankDetails';
import createBSArecord from '@salesforce/apex/COMM_ManualBankingController.createBSArecord';
import fetchBSARecords from '@salesforce/apex/COMM_ManualBankingController.fetchBSARecords';
import deleteDocumentDetail from '@salesforce/apex/COMM_ManualBankingController.deleteDocumentDetails';
import getApplicants from '@salesforce/apex/CaptureMandateController.getApplicants';
import fetchContentDocumentIdofBdRecord from '@salesforce/apex/COMM_ManualBankingController.fetchContentDocumentIdofBdRecord';
import createDocumentDetailBankAnalytic from '@salesforce/apex/COMM_ManualBankingController.createDocumentDetailBankAnalytic';
import { NavigationMixin } from 'lightning/navigation';
import { updateRecord } from "lightning/uiRecordApi";



export default class AddManualBankDACmp extends NavigationMixin(LightningElement) {
  bdColumns = [
        { label: 'Applicant Name', fieldName: 'applicantName',editable: true },
        { label: 'Account Type', fieldName: 'bankAccountType',editable: true },
        { label: 'Account No', fieldName: 'bankAccountNumber',editable: true },
        { label: 'Bank', fieldName: 'bank',editable: true },
        { label: 'Month', fieldName: 'month',editable: true },
        { label: 'Year', fieldName: 'year',editable: true }
  ]
  @track bdData = [];           // Holds the rows for the datatable
  @track showBDTable=false;
  @track draftValues = [];    // Holds inline edited values
  @api fromSales= false;
  @api fromBuilderSeller= false;
  @api formIdentifier;
  @track isRendered = false;
  @track showBankStoredValue = true;//sanawr 28/11/2025
  maxResults = 10;//sanawr 28/11/2025-
  applicantSelectedRecordId
  monthMapping = {
    january: 1,
    february: 2,
    march: 3,
    april: 4,
    may: 5,
    june: 6,
    july: 7,
    august: 8,
    september: 9,
    october: 10,
    november: 11,
    december: 12
  };


  // Modal field values
  applicantValue = '';
  accountTypeValue = '';
  accountNoValue = '';       // For Account No
  bankValue = '';
  monthValue = '';
  yearValue = '';
  isPreview
  showModal = false
  currentYear = new Date().getFullYear();
  applicants = []
  bankList = []
  applicantOptions = []
  monthOptions = [
      { label: 'January', value: 'January' },
      { label: 'February', value: 'February' },
      { label: 'March', value: 'March' },
      { label: 'April', value: 'April' },
      { label: 'May', value: 'May' },
      { label: 'June', value: 'June' },
      { label: 'July', value: 'July' },
      { label: 'August', value: 'August' },
      { label: 'September', value: 'September' },
      { label: 'October', value: 'October' },
      { label: 'November', value: 'November' },
      { label: 'December', value: 'December' }
    ];
  yearOptions = [];
  accountTypeOptions = [
    { label: 'Saving', value: 'Saving' },
    { label: 'Current', value: 'Current' },
    { label: 'CC/Overdraft', value: 'CC/Overdraft' },
    { label: 'CC', value: 'CC' },  
    { label: 'Overdraft', value: 'Overdraft' },
    { label: 'Salary', value: 'Salary' }   
  ];
  openBankAccountModal
  bsaRecordId
  bdRecordId
  @api recordId;
  @track daRecords = {};
  @track isAdd = false;
  applicantrecordId
  selectedApplicant;
  showBsaTable =false ;
  bsaBoolean = true;
  selectedBank;
  connectedCallback(){
    this.bsaBoolean = true 
    this.isPreview = true ;
    this.isAdd = true;   
    if(this.fromBuilderSeller) {
      this.showApplicantName = false;
    }
    if(this.fromBuilderSeller){
      this.fetchApplicants();
    }
     //Sanwar 29/11/2025
     getBankList({
      recordId:this.recordId
    })
    .then(data => {
      this.bankList = data.map(bank => {
        // console.log("applicant " + JSON.stringify(applicant));
        return { label: bank.Name, value: bank.Id };
      });
      console.log("this.bankList--->>", JSON.stringify(this.bankList));
    })
    .catch(error => {
      console.error('Error fetching bank list:', error);
    })

    this.fetchBankDetails();
    this.openBankAccountModal = false
    this.showModal = false 
    this.yearOptions = Array.from({ length: 21 }, (_, index) => {
      const year = this.currentYear - index;
      return { label: year.toString(), value: year.toString() };
    });
  }

  closeBankAccount(){
    this.openBankAccountModal = false;
  }

  handleComboboxChange(event) {
    const fieldName = event.target.name;  //need id here 
    if(fieldName === 'applicantName'){
        // this.applicantValue = event.detail.label;
        this.applicantrecordId = event.detail.value;
        const selectedValue = event.detail.value;
        const selectedOption = this.applicants.find(app => app.value === selectedValue);
        if (selectedOption) {
            this.applicantValue = selectedOption.label;
        }
    } else if(fieldName === 'accountType'){
        this.accountTypeValue = event.detail.value;
    } else if(fieldName === 'bank'){
        this.bankValue = event.detail.value;
    } else if(fieldName === 'month'){
        this.monthValue = event.detail.value;
    } else if(fieldName === 'year'){
        this.yearValue = event.detail.value;
    }
  }

  handleInputChange(event) {
    if(event.target.name === 'accountNo'){
        this.accountNoValue = event.target.value;
    }
  }

  handleSubmit() {
    console.log('---debug manraj ---') ;
    console.log(this.applicantValue) ;
    console.log(this.applicantrecordId) ;
    // console.log('' + this.accountType) ;
    // this.applicantValue = 'Xyz'
    console.log(this.accountTypeValue) ;
    console.log(this.bankValue) ;
    console.log(this.monthValue) ;
    console.log(this.yearValue) ;
    // this.bankValue= 'a0QBi00000CvIcTMAV'
    createBankDetail({ 
        applicant: this.applicantrecordId, 
        accountHolderName: this.applicantValue , 
        accountType: this.accountTypeValue, 
        accountNo: this.accountNoValue, 
        bank: this.bankValue,
        month: this.monthValue,
        year: this.yearValue,
        recordId : this.recordId
    })
    .then(result => {
      console.log(126);
      this.fetchBankDetails();

      // console.log(JSON.stringify(result)) 
      // console.log('Record Created --manraj')
      // this.applicantValue = result.applicantName 
      // this.accountTypeValue = result.accountType 
      // this.accountNoValue = result.accountNo 
      // this.bankValue = result.bank 
      // this.month = result.month 
      // this.year = result.year 

        // Create a new row for the datatable with the returned Id
      //   const newRow1 = {
      //     id: result, // Ensure your key field is defined (e.g., id)
      //     applicantName: 'harish',
      //     bankAccountType: 'Savings',
      //     bankAccountNumber: '78778',
      //     bank: '58745',
      //     month: '12',
      //     year: '2025'
      // };
      // console.log('-- row Data -- ' + JSON.stringify(newRow1) ) ;        
      console.log('--debug11' + this.applicantValue)
        //   const newRow = {
        //     id: result.id,
        //     applicantName: result.applicantName,
        //     bankAccountType: result.accountType,
        //     bankAccountNumber: result.accountNo,
        //     bank: result.bank,
        //     month: this.monthValue, // Or result.month if it's part of the wrapper
        //     year: this.yearValue   // Or result.year if it's part of the wrapper
        // };
        // console.log('-- row Data -- ' + JSON.stringify(newRow) ) ;
        // this.bdData = [...this.bdData, newRow];
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Record created',
                variant: 'success'
            })
        );
    })
    .catch(error => {
      console.log(error) 
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error creating record',
                message: error.body.message,
                variant: 'error'
            })
        );
    });

      // Clear the modal fields and close the modal
      this.applicantValue = '';
      this.accountTypeValue = '';
      this.accountNoValue = '';
      this.bankValue = '';
      this.monthValue = '';
      this.yearValue = '';
      this.showModal=false;
  }
  //  monthSelected
  //  yearSelected
  handleEditRow(event) {
    this.showBankStoredValue = false;//sanawr 28/11/2025
     console.log(event.target.dataset.id);
     console.log(event.target.dataset.id);
     console.log('this.fromBuilderSeller---', this.fromBuilderSeller);  
     if(this.fromBuilderSeller){
       this.showBsaTable =  false ;
     }
     else{
      this.showBsaTable =  true ;
     }
     //this.showBsaTable =  this.fromBuilderSeller === true ? true : false ;
     console.log('this.showBsaTable---', this.showBsaTable);
     const rowId = event.target.dataset.id; // get the id once
     this.selectedBank=rowId;
     console.log(' this.selectedBank in rowEdit---',  this.selectedBank);
     
        this.bdData.forEach((row, index) => {
          console.log("handleEditRow");
          console.log(JSON.stringify(rowId));
          console.log(JSON.stringify(row.id));
          this.fetchBSArecord(rowId);
          if (row.id === rowId) {
            // Update the specific row by replacing it with a new object
            this.bdData[index] = { ...row, isEditable: false };
          }
          else
          {
            this.bdData[index] = { ...row, isEditable: true };
          }
          console.log('this.bdData----',JSON.stringify(this.bdData));
        });    

    //use record id to fetch BSA details and populate in Da records 
    // createBSArecord({bdRecordId:rowId})
    // .then(result => {
    //   console.log("created BSA record " );
      
    //   this.fetchBSArecord(rowId)
    //   if(result===true)
    //   window.location.reload();
      
    // })
    // .catch(error => {
    //   console.log(error)
    // })
    
    
    // .then()
    // .catch() 

    
  }

  handleDeleteDocAnalysis(event) {
 const rowId = event.target.dataset.id; 
    deleteDocumentDetail({bankDetailRecord:rowId,isAnalysis:true})
    .then(result => {
      console.log("deleted DD record " );
      this.fetchBankDetails();
      
    })
      .catch(error => {
        console.log(error) 
      this.dispatchEvent(
          new ShowToastEvent({
              title: 'Error deleting record',
              message: error.body.message,
              variant: 'error'
          })
      );

  })
  }
  handleDeleteDoc(event){
    const rowId = event.target.dataset.id; 
    deleteDocumentDetail({bdRecordId:rowId,isAnalysis:false})
    .then(result => {
      console.log("deleted DD record " );
      
      this.bdData.forEach((row, index) => {
        // console.log("handleEditRow");
        // console.log(JSON.stringify(rowId));
        // console.log(JSON.stringify(row.id));

        if (row.id === rowId) {
          // Update the specific row by replacing it with a new object
          console.log('21') ;
          console.log(JSON.stringify(this.bdData[index])) ;
          this.bdData[index] = { ...row, isPreview: false, isReUpload: true };
          console.log(JSON.stringify(this.bdData[index])) ;
        }
        
        // console.log(JSON.stringify(this.bdData));
      }); 
    })
      .catch(error => {
        console.log(error) 
      this.dispatchEvent(
          new ShowToastEvent({
              title: 'Error deleting record',
              message: error.body.message,
              variant: 'error'
          })
      );

  })
  }
  handleReUpload(event){      
    const rowId = event.target.dataset.id;
    //make preview visible again
    this.bdData.forEach((row, index) => {
      // console.log("handleEditRow");
      // console.log(JSON.stringify(rowId));
      // console.log(JSON.stringify(row.id));

      if (row.id === rowId) {
        // Update the specific row by replacing it with a new object
        this.bdData[index] = { ...row, isPreview: true,isReUpload: false };        
      }
      
      // console.log(JSON.stringify(this.bdData));
    }); 

  }

  handleReUploadAnalytic(event) {
    const rowId = event.target.dataset.id;
    const uploadedFiles = event.detail.files;
    this.fileId = uploadedFiles[0].documentId;
    
    createDocumentDetailBankAnalytic({ recordId: this.recordId,docId:uploadedFiles[0].documentId,bankId:rowId })
      .then(result => {
        this.fetchBankDetails();

      })

      .catch(error => {
        console.error('Error fetching applicants:', error);
      });
  }
  renderedCallback() {
    if (!this.isRendered) {
        // Create and append styles dynamically
        const style = document.createElement('style');
        style.innerText = `
        p, h1, h2, h3, h4, h5, a, .slds-button{
            font-family: Arial;
        }
        .cancel-button{
            text-wrap-mode: nowrap;
        }
        .custom-table .slds-form-element__label, span.slds-file-selector__text.slds-medium-show{
            display: none;
        }
        .custom-table span.slds-file-selector__button.slds-button.slds-button_neutral{
            font-size: 0px;
        }
        .custom-table svg.slds-button__icon.slds-button__icon_left{
            margin: 0px;
        }
        .custom-table lightning-primitive-file-droppable-zone.slds-file-selector__dropzone{
            border: none;
        }
        .custom-table lightning-primitive-file-droppable-zone.slds-file-selector__dropzone{
            background-color: #16283f !important;
            border: 1px solid #33455e !important;
            border-radius: 6px !important;
        }
        .custom-table .slds-textarea{
            min-height: 200px;
        }
        .custom-table{
            font-weight: 400;
        }
        .custom-table .slds-file-selector__button {
            background-color: #16283f !important;
            border: 1px solid #33455e !important;
            color: #ffffff !important;
        }
        .custom-table lightning-combobox {
            --slds-c-combobox-input-color-background: #16283f;
            --slds-c-combobox-input-color-border: #33455e;
            --slds-c-combobox-input-text-color: #ffffff;
        }
        .custom-table .slds-combobox__input {
            background-color: #16283f !important;
            color: #ffffff !important;
            border: 1px solid #33455e !important;
        }
        
        `;

        // Append the styles to the .styleContainer
        this.template.querySelector('.styleContainer')?.appendChild(style);

        // Prevent re-adding styles
        this.isRendered = true;
    }
  }
  handlePreview(event) {
    const bdRecordId = event.target.dataset.id;
    var contentDocumentIdtemp = event.target.dataset.name;

    // fetchContentDocumentIdofBdRecord({bdRecordId:bdRecordId})
    // .then(result => {
    //   console.log('result is '+result) ;
    //   contentDocumentIdtemp = result;
      this[NavigationMixin.Navigate]({
          type: 'standard__namedPage',
          attributes: {
              pageName: 'filePreview'
          },
          state: {
              // Pass the content document ID so that the file preview page knows which file to show
              selectedRecordId: contentDocumentIdtemp,
              // recordIds: contentDocumentIdtemp
          }
      });
    // })
  }
//sanawr 28/11/2025-
  handleSelectDocument(event){
    console.log('event in lookuppp---', JSON.stringify(event));
    this.ifscvalue= event.detail.searchRecord.Id;
    console.log('ifscvalue in lookup----', this.ifscvalue);
    console.log('ifscvalue in lookup----', this.ifscvalue);  
    const rowId = event.target.dataset.id;
    console.log('At 446',rowId);
    const fieldName = event.target.name;
    const newValue = event.target.value;
    console.log('At 478',fieldName);
    updateBankDetails({
      recordId:rowId,
      fieldName:fieldName,
      newValue:this.ifscvalue

    }).then( result =>{

      this.showBankStoredValue = true;//sanawr 28/11/2025
      this.fetchBankDetails();
    //   this.dispatchEvent(
    //     new ShowToastEvent({
    //         title: 'Success',
    //         message: 'Record update',
    //         variant: 'success'
    //     })
    // );

    }).catch(error => {
      this.dispatchEvent(
        new ShowToastEvent({
            title: 'Error updating record',
            message: error.body.message,
            variant: 'error'
        })
    )});
  }

  handleldeselectDocument(){
    console.log('At 448');
  }
  //sanawr 28/11/2025-

  fetchBSArecord(rowId) {     
    fetchBSARecords({bdRecordId:rowId})
    .then(result => {
      console.log('fetch BSA records') ;
      console.log(JSON.stringify(result)) ;
      this.daRecords = result ;
    })
    .catch(error => {
      console.log(error) 
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error bsa record ',
                message: error.body.message,
                variant: 'error'
            })
        );
    });
  }
    

    handleBDUpdate(event) {
      const rowId = event.target.dataset.id;
      const fieldName = event.target.name;
      const newValue = event.target.value;

      console.log('value123'+newValue) ;
      console.log('value22'+rowId) ;
      console.log(fieldName) ;
      updateBankDetails({
        recordId:rowId,
        fieldName:fieldName,
        newValue:newValue

      }).then( result =>{

        this.fetchBankDetails();
      //   this.dispatchEvent(
      //     new ShowToastEvent({
      //         title: 'Success',
      //         message: 'Record update',
      //         variant: 'success'
      //     })
      // );
      this.showBankStoredValue = true;//sanawr 28/11/2025

      }).catch(error => {
        this.dispatchEvent(
          new ShowToastEvent({
              title: 'Error updating record',
              message: error.body.message,
              variant: 'error'
          })
      );
        console.log('bd update fail') ;
        console.log(error) ;
      }

      )

    }


   fetchBankDetails(){
    fetchBankDetails({
      recordId:this.recordId
    })
    .then(result =>{
        console.log("bank details " + JSON.stringify(result));
        //   this.bdData = thisbdData.map(row => {
        //     result.map((row) => (
        //      {return { ...thisbdData, row })
        //     return { ...row,  };
        // });
        console.log('1234' ) 
        //   this.bdData = this.bdData.map((row, index) => {
        //     console.log('index' + index) 
        //     console.log('row' + row) 
        //     return { ...row, ...result[index] };
        // });
        // this.bdData = [...result,this.bdData];
        if (this.fromBuilderSeller && result && result.length > 0 && this.selectedApplicant && this.selectedApplicant.value) {//sanwar(28/11/2025)
            let bdlist = [];
            result.forEach(currentItem => {
              if(this.selectedApplicant.value === currentItem.applicantId){
                bdlist.push(currentItem);
              }
            });
            this.bdData =bdlist;
        } else {
        this.bdData = [...result];
        }

        if(this.bdData!= null && this.bdData.length >0){
          this.showBDTable= true;
        }
        console.log("this.bdData---", JSON.stringify(this.bdData));
    }).catch(error => {
        console.error('Error fetching banks:', error);
      });
  
    //Sanwar 29/11/2025
    getBankList({
      recordId:this.recordId
    })
    .then(data => {
      this.bankList = data.map(bank => {
        // console.log("applicant " + JSON.stringify(applicant));
        return { label: bank.Name, value: bank.Id };
      });
      console.log("this.bankList--->>", JSON.stringify(this.bankList));
    })
    .catch(error => {
      console.error('Error fetching bank list:', error);
    })
  }
    

  @wire(getApplicationApplicants, { oppId: '$recordId' })
    wiredApplicants({ error, data }) {
        if (data) {
          console.log("applicants " + JSON.stringify(data));
          
            // Transform the returned records into combobox options
            this.applicants = data.map(applicant => {
                console.log("applicant " + JSON.stringify(applicant));
                // applicantSelectedRecordId = applicant.Id;
                return { label: applicant.Name, value: applicant.Id };
            });
        } else if (error) {
            console.error('Error fetching applicants:', error);
        }
    }
    //sanwar(28/11/2025)add recordId
    // @wire(getBankList, {recordId: '$recordId'})
    // wiredfetchBankList({ error, data }) {
    //     if (data) {
    //       // console.log("applicants " + JSON.stringify(data));
          
    //         // Transform the returned records into combobox options
    //         this.bankList = data.map(bank => {
    //             // console.log("applicant " + JSON.stringify(applicant));
    //             return { label: bank.Name, value: bank.Id };
    //         });
    //         console.log("this.bankList---", JSON.stringify(this.bankList));
    //     } else if (error) {
    //         console.error('Error fetching bank list:', error);
    //     }
    // }
    handleApplicantChange(event) {
        this.applicantrecordId = event.detail.value;
    }
  handleAddBankDetailsClick(){
      console.log("handle add bank account clicked ") ;
      this.showModal = true 
      this.openBankAccountModal = true 
  }
  hideModal()
  {
      this.showModal = false; 
  }
  //  this.bsaRecordId
    getData() {
      console.log('bsarecordId' + this.bdRecordId) 
        manualDerivedAnalysis({
            recordId: 'a0hBi000000YkurIAC',
            isAdd : this.isAdd
          })
            .then((response) => {
              console.log("manual bank " + JSON.stringify(response));
              this.daRecords = response;
              
              //this.spinner = false;
            })
            .catch((error) => {
              console.log("manualDerived")
              console.log(error)
            });
    }
    handleSave() {
        console.log("this.daRecords" + JSON.stringify(this.daRecords));
    }
    handleFieldChange(event) {
        console.log('on blur name',event.target.name);
        console.log('event.target.value=:'+event.target.value);
        console.log('data id=:'+event.target.dataset.id);
        const fields = {};
        fields['Id'] = event.target.dataset.id;
        fields[event.target.name]=event.target.value;
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
        .then(() => {
          console.log('BSA Data updated---');
          console.log('this.selectedBank-----', this.selectedBank);
          
          this.fetchBSArecord(this.selectedBank);
            // this.showToastMessage('Success', 'Record updated successfully', 'success');
            // this.getData();
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
    }
  showToastMessage(title, message, type) {
    const toastEvent = new ShowToastEvent({
        title: title,
        message: message,
        variant: type
    });
    this.dispatchEvent(toastEvent);
  }
  addMonth() {
    createMonthlyRecs({
      recordId: 'a0hBi000000YkurIAC'
    })
    .then((response) => {
      console.log("manual bank " + JSON.stringify(response));
      this.getData();
      
      //this.spinner = false;
    })
    .catch((error) => {});
  }
  removeMonth() {
    removeMonthltRec({
      recordId: 'a0hBi000000YkurIAC'
    })
    .then((response) => {
      console.log("manual bank " + JSON.stringify(response));
      this.getData();
      
      //this.spinner = false;
    })
    .catch((error) => {});
  }

  handleAccountSave(event){
    console.log('event-----', JSON.stringify(event));
    var rowId = event.detail;
    this.selectedBank=rowId;
    console.log('rowId-----', JSON.stringify(rowId));
    console.log("handleAccountSave" + JSON.stringify(this.accountDetails));
    
    this.fetchBankDetails();
    setTimeout(() => {
      this.bdData.forEach((row, index) => {
        console.log("handleEditRow");
        console.log(JSON.stringify(rowId));
        console.log(JSON.stringify(row.id));

        if (row.id === rowId) {
          // Update the specific row by replacing it with a new object
          this.bdData[index] = { ...row, isEditable: false };
        }
        else
        {
          this.bdData[index] = { ...row, isEditable: true };
        }
        console.log('this.bdData----',JSON.stringify(this.bdData));
        const valueEvent2 = new CustomEvent('addedbank', {detail:rowId});
        this.dispatchEvent(valueEvent2);
      });  
      // this.bdData[this.bdData.length-1].isEditable= true;
      
      this.fetchBSArecord(rowId);
      if(this.fromBuilderSeller){
       this.showBsaTable =  false ;
     }
     else{
      this.showBsaTable =  true ;
     }
    }, 500);

  }

  handleDataSave(){
    if(this.fromBuilderSeller){
       this.showBsaTable =  false ;
     }
     else{
      this.showBsaTable =  true ;
     }
    this.fetchBankDetails();
    this.bdData.forEach((row, index) => {
        this.bdData[index] = { ...row, isEditable: false };
      console.log('this.bdData----',JSON.stringify(this.bdData));
    });
    
    this.dispatchEvent(
      new ShowToastEvent({
          title: 'Success',
          message: 'Data saved successfully.',
          variant: 'success'
      })
    );
  }
  fetchApplicants() {
          console.log('this.recordId:: '+this.recordId);
          getApplicants({ loanApplicationId: this.recordId })
              .then(result => {
                  console.log('this.result:: '+JSON.stringify(result));
                  this.applicants = result.map(applicant => ({
                      label: applicant.Name,
                      value: applicant.Id,
                      customerType: applicant.Applicant_Type__c
                  }));
                  console.log('applicants:: '+JSON.stringify(this.applicants));
                  console.log('this.formIdentifier:: '+this.formIdentifier);
                  const fieldApiNameToFind = this.formIdentifier == 'Builder Details' ? 'Builder' :'Seller';
                    const fieldValue = this.applicants.find(item => item.customerType === fieldApiNameToFind)
                    console.log('fieldValue:: '+JSON.stringify(fieldValue));
                    this.selectedApplicant = fieldValue;
                    this.fetchBankDetails();
              })
              .catch(error => {
                  console.error('Error fetching applicants:', error);
              });
      }
}