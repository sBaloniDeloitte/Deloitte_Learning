import { LightningElement,api,track } from 'lwc';
import getDocChecklistRecords from '@salesforce/apex/FCUController.getDocChecklistRecords';
import getMetaDataVales from '@salesforce/apex/FCUController.getMetaDataVales';
import getDataRecordValues from '@salesforce/apex/FCUController.getDataRecords';


export default class VettingDocumentsCmp extends LightningElement {
    @track pdfUrl;
    @api recordId;
    @track docList;
    @track currentImageUrl;
    @track showImage;
    @track showPdfModal;
    @track tabList;
    activeValueTab

    connectedCallback(){
        this.pdfUrl = `/apex/FCULoanApplicationform?id=`+this.recordId;
        //this.getDocRecords();
        this.getMetaDataRecord();
    }
    renderedCallback() {
        console.log('IN CHILD RENDER CALL BCK');
        const style = document.createElement('style');
        style.innerText = `.tabStickChild .slds-tabs_default__nav{
                            position: fixed;
                            top: 220px;
                            z-index: 4;
                            background: #12172b;
                            width: 48.2%;
                        }
                        .tabStickChild .slds-tabs_default__item{
                            padding-top:11px;
                        }
                        #tab-6__item[aria-selected="true"], #tab-7__item[aria-selected="true"], #tab-8__item[aria-selected="true"] {
                            background-color: #9bbf56 !important;
                            color: white !important;
                        } 
                        #tab-9__item[aria-selected="true"], #tab-10__item[aria-selected="true"], #tab-11__item[aria-selected="true"] {
                            background-color: #9bbf56 !important;
                            color: white !important;
                        } 
                        #tab-12__item[aria-selected="true"], #tab-13__item[aria-selected="true"], #tab-14__item[aria-selected="true"], #tab-15__item[aria-selected="true"] {
                            background-color: #9bbf56 !important;
                            color: white !important;
                        }`;
        this.template.querySelector('.styleContainer').appendChild(style);
    }
    getDocRecords(){
        getDocChecklistRecords({
            loanId : this.recordId
        }).then(response=>{
            console.log('doc Lis====>',response);
            this.docList = response;
        }).catch(error=>{

        })
    }
    getMetaDataRecord(){
        getMetaDataVales({}).then(response=>{
            var tabData = response;
            tabData.forEach(ele => {
                if(ele.Field_Value__c.includes(' ')){
                    ele.Field_Value__c = ele.Field_Value__c.replace(/ /g, '_');
                }
            });
            this.tabList = response;
            console.log('doc Lis====>',this.tabList);


        }).catch(error=>{
        })
    }
    openFullImage(event){
        this.currentImageUrl = event.target.dataset.id;
        this.showImage = true;
    }
    openPdfModal(event) {
        this.pdfUrl = event.currentTarget.dataset.src;
        console.log('vvvvv',event.currentTarget.dataset); 
        console.log('pdfurl',this.pdfUrl); // Get the PDF URL from the clicked iframe
        this.showPdfModal = true;
    }
    resetClick(){
        this.currentImageUrl = '';
        this.showImage = false;
    }
    resetPdfClick(){
        this.pdfUrl = '';
        this.showPdfModal = false;
    }
    handleActive(event) {
       console.log('Test===',event.target.value);
       console.log('id===',event.target.id);

       this.activeValueTab  = event.target.value;
       const style = document.createElement('style');

        // Apply styles dynamically based on the selected tab
        style.innerText = `
            .tabStickChild .slds-tabs_default__nav {
                position: fixed;
                top: 220px;
                z-index: 4;
                background: #12172b;
                width: 48.2%;
            }
            .tabStickChild .slds-tabs_default__item {
                padding-top: 11px;
            }
            #${event.target.value}__item[aria-selected="true"] {
                background-color: #9bbf56 !important;
                color: white !important;
            }
        `;
    // Append the style tag to the style container
    this.template.querySelector('.styleContainer').appendChild(style);
       this.getDataRecord();

    }

    getDataRecord(){
        getDataRecordValues({
            loanId : this.recordId,
            documentCategory : this.activeValueTab.includes('_') ? this.activeValueTab.replace(/_/g, ' '): this.activeValueTab
        }).then(response=>{
            console.log('doc Lis===response=>',response);
            this.docList = response;
        }).catch(error=>{

        })
    }
}