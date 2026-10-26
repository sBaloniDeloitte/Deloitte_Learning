import { LightningElement,api,track,wire } from 'lwc';
import getDocumentNames from '@salesforce/apex/GenericInitiateController.getDocumentNames';
import insertDocumentCheckList from '@salesforce/apex/GenericInitiateController.insertDocumentCheckList';
import getDocumentMasterList from '@salesforce/apex/GenericInitiateController.getDocumentMasterList';
import getSalesUploadedDocuments from '@salesforce/apex/GenericInitiateController.getSalesUploadedDocuments';
export default class DocumentChecklistModal extends LightningElement {
    @api recordId;
    @api type;
    @api applicationCollId;
    @track options = []
    @track value;
    @track selectedOptions = new Set()
    @track fixedOptions = []
    searchValue = '';
    showOptions = false;
    docChecklistObj = {};
    //HL-Ishi-1/9/25
    showAddedCollDocuments = false;
    product;
    @track uploadedDocOptions = [];
    showHLOptions = false;
    searchValueHL = '';
    @track selectedOptionsHL = new Set()
    //HL-Ishi-1/9/25
    connectedCallback(){
        console.log('adddocrecordId', this.recordId);
        this.handleDocumentChecklist();
        this.getSalesUploadedDocuments();
    }

    handleChange(evt){
        this.value = evt.detail.value;
        //console.log(JSON.stringify(this.value))
    }

    closeModal(){
        this.dispatchEvent(new CustomEvent('closemodal'));
    }

    handleDocumentChecklist(){
        if(this.type == 'Legal_Scrutiny_Report'){
            this.type= 'Legal Scrutiny Document'
            this.showAddedCollDocuments= true;
        }else if(this.type == 'Legal_Search_Report'){
            this.type = 'Legal Search Document'
            this.showAddedCollDocuments= true;
        }else if(this.type == 'Legal_Vetting_Report'){
            this.type = 'Legal Vetting Document'
            this.showAddedCollDocuments= true;
        }
        else if(this.type == 'Legal_Scrutiny_Report_With_Title_Search'){
            this.type = 'Legal Scrutiny Report With Title Search'
            this.showAddedCollDocuments= true;
        }
        if(this.type && this.type.includes('Legal')) {
            console.log('document category',this.type);;
            getDocumentMasterList({objectType : 'Legal', docCategoryType: this.type, recordId : this.recordId,applicationCollId : this.applicationCollId})     
            .then((response) => {
                console.log('document#####', response);
                this.options = response;
                this.showOptions = true;
            }).catch(error=>{
                console.error('legalDocumentList--> '+error)
            })
        }
        else if(this.type === 'Technical Documents'){
            getDocumentMasterList({objectType : 'Technical',docCategoryType: this.type, recordId : this.recordId, applicationCollId : this.applicationCollId})
            .then((response) => {
                console.log('document', response);
                this.options = response;
                this.showOptions = true;
                this.showAddedCollDocuments= true;
            }).catch(error=>{
                console.error('technicalDocumentList--> '+error)
            })
        }
    }

    searchKeyword(event){
        //this.searchDocument(evt.target.value); this is too clumsy no need to do this bro.
        this.searchValue = event.target.value;
    }

    
    get filteredOptions() {
        if (!this.searchValue) {
            //if(this.showHLRelatedData){
                return this.options.slice(0, 5);
            //}
            /*else{
                return this.options;
            }*/
        }
        const key = this.searchValue.toLowerCase();
        return this.options.filter(option =>
            option.label.toLowerCase().includes(key)
        );
    }


    selectDocumentName(evt){
       /* this.selectedOptions.add(evt.currentTarget.dataset.value)
        this.fixedOptions = Array.from(this.selectedOptions)
       */
        const value = evt.currentTarget.dataset.value;
        if (evt.currentTarget.checked) {
            this.selectedOptions.add(value);
        } else {
            this.selectedOptions.delete(value);
        }
        this.fixedOptions = Array.from(this.selectedOptions); //did this to handle the bug >> checked value was remaining checked even after uncheck of box
    }

    searchDocument(name){
        getDocumentNames({docName:name})
        .then((response) => {
            this.showOptions = false;
            this.options = response
            this.showOptions = true;
        }).catch(error=>{
            console.error(error)
        })
    }
    
    addNewDocument(){
        //console.log('this.fixedOptions -->'+JSON.stringify(this.fixedOptions));
        //this.dispatchEvent(new CustomEvent('handledocadded', {detail:{'docadded':true}}));
        //changing a logic >>Armani :  instead of calling apex >> I am sending the params to the parent obj and will call the method before legal/tech record creation
        //deferred for now >
        this.docChecklistObj = {
            recordId : this.recordId,
            docNames : this.fixedOptions,
            applicationCollId : this.applicationCollId,
            type: this.type,
            requirementAt : 'Collateral Level'
        };
       /* this.dispatchEvent(new CustomEvent('handledoccreation', {
            detail: this.docChecklistObj
        }));*/
        insertDocumentCheckList({
            recordId : this.recordId,
            docNames : this.fixedOptions,
            type   : this.type,
            applicationColl   : this.applicationCollId,
            requirementAt : 'Collateral Level'
        }).then(newlyCreatedDocs => { // <-- 1. Catch the new documents from Apex updated-Ayushi
            console.log('newlyCreatedDocs----'+JSON.stringify(newlyCreatedDocs));
        // 2. Fire a new event with the documents in the 'detail'
        this.dispatchEvent(new CustomEvent('documentsadded', {
            detail: newlyCreatedDocs 
        }
        )); 
        // 3. Close this modal (this calls your existing closeModal function)
        this.closeModal();

    }).catch(error=>{
        console.error(error)
    })
        /*.then(response=>{
            console.log('Successss')
            this.dispatchEvent(new CustomEvent('reset'));
        }).catch(error=>{
            console.error(error)
        })*/
    }
     //HL
    /*getProductDetails(){
        const inputMap = {
            'oppId': this.recordId
        };
        getProductDetails({inputMap: inputMap})
        .then(response => {
            console.log('response.loanProduct=:'+response.loanProduct);
            this.product = response.loanProduct;
            if(this.product == 'Home Loan'){
                this.showHLRelatedData = true;
            }
        })
        .catch(error => {
            console.log(error);
        });
    }*/
    getSalesUploadedDocuments(){
        console.log('inside HL doc');
        getSalesUploadedDocuments({
            objectType : 'Legal', 
            docCategoryType: this.type, 
            recordId : this.recordId,
            applicationCollId : this.applicationCollId
        }).then(response=>{
            console.log('documentHL', response);
            this.uploadedDocOptions = response;
            this.showHLOptions = true;
        }).catch(error=>{

        })
    }
    searchKeywordHL(event){
        //this.searchDocument(evt.target.value); this is too clumsy no need to do this bro.
        this.searchValueHL = event.target.value;
    }
    get filteredOptionsHL() {
        if (!this.searchValueHL) {
            return this.uploadedDocOptions;
        }
        const key = this.searchValueHL.toLowerCase();
        return this.uploadedDocOptions.filter(option =>
            option.label.toLowerCase().includes(key)
        );
    }
    selectDocumentNameHL(evt){
        this.showHLOptions = false;
     
        const value = evt.currentTarget.dataset.value;
        if (evt.currentTarget.checked) {
            this.selectedOptionsHL.add(value);
        } else {
            this.selectedOptionsHL.delete(value);
        }

         this.showHLOptions = true;
            this.fixedOptionsHL = Array.from(this.selectedOptionsHL); 
        /*setTimeout(() => {
           
        }, 100);*/
        
      //did this to handle the bug >> checked value was remaining checked even after uncheck of box
        console.log('fixedOptionsHL=:'+JSON.stringify(this.fixedOptionsHL))
    }
}