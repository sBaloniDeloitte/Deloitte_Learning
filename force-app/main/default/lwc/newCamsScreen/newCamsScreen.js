import {
    LightningElement,
    api,
    track, wire
} from 'lwc';
import getScreenDetails from '@salesforce/apex/ScreenGenerationController.getScreenDetails';
import getLoanDetailsFromStorageObject from '@salesforce/apex/OneView.getLoanDetailsFromStorageObject';
import getPicklistValues from '@salesforce/apex/ScreenGenerationController.getPicklistValues';
import getFieldDependencies from '@salesforce/apex/ScreenGenerationController.getFieldDependencies';
import getSourcingDetailsFields from '@salesforce/apex/OneView.getSourcingDetailsFields';
import checkIfPDFExists from '@salesforce/apex/OneView.checkIfPDFExists';
import getTechnicalRecords from '@salesforce/apex/COMM_TechnicalRecordPageController.getTechnicalRecords';
import getAllPropertyDetails from '@salesforce/apex/PropertyDetailsController.getAllPropertyDetails';
import fetchAllProducts from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.fetchAllProducts';
import getCovenantDetail from '@salesforce/apex/Hl_CovenantsDetailFormController.getCovenantDetail';
import getLoanApprovalDetails from '@salesforce/apex/HL_LoanApplicationApprovalController.getLoanApprovalDetails';
import getSalaryDetails from '@salesforce/apex/OneView.getSalaryDetails';
import getRecoNotesDetails from '@salesforce/apex/OneView.getRecoNotesDetails';
import html2canvasLib from '@salesforce/resourceUrl/html2canvas';
import jsPDFLib from '@salesforce/resourceUrl/jsPDF';
import { loadScript } from 'lightning/platformResourceLoader';
import jsPDFResource from '@salesforce/resourceUrl/jsPDF';
import jsPDFAutoTableResource from '@salesforce/resourceUrl/jsPDFAutoTable';
import getObligationsRecords from "@salesforce/apex/COMM_ObligationsController.getObligationsRecords";
import getAllSanctionConditions from '@salesforce/apex/SanctionConditionController.getAllSanctionConditions';
import getApprovalDetails from '@salesforce/apex/Hl_LoanApprovalController.getApprovalDetails';
import uploadPDF from '@salesforce/apex/OneView.uploadPDF';
import getApplicants from "@salesforce/apex/Hl_EligibilityController.getApplicants";
import getProductsByOpportunity from '@salesforce/apex/ProductTableController.getProductsByOpportunity';
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";
import { getRecord } from "lightning/uiRecordApi";
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import getSubProductDetails from '@salesforce/apex/Utility_V1.getSubProductDetails';
import getAllDocument from '@salesforce/apex/DocumentViewCmpController.getAllDocumentFCU';
import getDocumentDetailRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.getDocumentDetailRecord';
import FCU_STATUS_FIELD from "@salesforce/schema/Opportunity.FCU_Status__c";
import OVERALL_FCU_FIELD from "@salesforce/schema/Opportunity.Overall_FCU_Verification__c";

export default class NewCamsScreen extends LightningElement {
    @track formIdentifier;
    @api recordId;
    @track isAccordionReady = false;
    @track isRendered = false;
    @track fieldDetails;
    @track allIndexs = [];
    @track filteredScreenDetails;
    @track allFieldDetails = [];
    @track mainAccordianActiveSactions = [];
    @track showOpenAll = true;
    @track allfieldLabels = [];
    screenName;
    screenObject;
    currentScreenSequence = 1;
    currentSeq = 0;
    @track tableHeaders = [];
    @track tableValues = [];
    @track filteredList = [];
    @track recordData = [];
    @track allData;
    @track totalData = {};
    @track isNoObligationRecordsFound;
    @track allSanctions = [];
    @track approvalData = {};
    @track sourcingData = [];
    @track appdata = [];
    @track products = [];
    libsLoaded = false;
    jsLibInitialized = false;
    showPDF = false;
    oppStage;
    @track spinner = false;
    isHLRelated = false;
    alldocuments = [];
    technicalRecords= [];
    propertyRecords = [];
    productTableRecs = [];
    covernantData = [];
    subProductDetails = [];
    fcuStatus= '';
    ovreAllFcuStatus = '';
    isFCU = false;
    salaryDetails = [];
    recoNoteDetails = [];

    @wire(getRecord, { recordId: '$recordId', fields: [STAGE_FIELD,FCU_STATUS_FIELD,OVERALL_FCU_FIELD] })
    wiredRecord({ data, error }) {
        if (data) {
            const stage = data.fields.StageName.value;
            this.fcuStatus= data.fields.FCU_Status__c.value;
            this.ovreAllFcuStatus = data.fields.Overall_FCU_Verification__c.value;
            if (stage === 'PSV') {
                this.handleAutoPDF();
            }
        } else if (error) {
            console.error('Error fetching stage:', error);
        }
    }

    async handleAutoPDF() {
        try {
            const alreadyExists = await checkIfPDFExists({ loanId: this.recordId });
            console.log('PDF exists:', alreadyExists);
            if (!alreadyExists) {
                console.log('No PDF found. Generating automatically...');
                await this.generatePDF();
            } else {
                console.log('PDF already exists. Skipping generation.');
            }
        } catch (error) {
            console.error('Error checking/creating PDF:', error);
        }
    }

    async getScreenDetailsFromApex() {
        try {
            console.log('this.isHLRelated>>>'+this.isHLRelated);
            if(this.isHLRelated){
                this.formIdentifier = 'HL CAM Details';
            }
            console.log('this.formIdentifier>>>>'+ this.formIdentifier);
            const fetchedScreenData = await getScreenDetails({
                formIdentifier: this.formIdentifier,
                loanId: this.recordId
            });
            console.log('fetchedScreenData -->' + JSON.stringify(fetchedScreenData));
            if (fetchedScreenData.length > 0) {
                let dummyFetchDetails = [];
                this.fieldDetails = fetchedScreenData.map(item => {
                    if(this.isHLRelated && item.Parent_Screen__r.Master_Screen_Name__c == 'Recommendation & Eligibility'){
                        return item;
                    }
                    else{
                        dummyFetchDetails.push({
                            label: item.Parent_Screen__r.Screen_Sequence__c,
                            name: item.Parent_Screen__r.Master_Screen_Name__c
                        });
                        return {
                            ...item,
                            isDisabled: (item.is_Lookup__c == true || item.Is_Fromula_Feild__c == true || this.disableEdit == true) ? true : false,
                            isTextArea: item.Field_Type__c == 'textarea' ? true : false,
                        }
                    }
                });
                await this.getCurrentScreenFieldDetails();
                console.log('41 getCurrentScreenFieldDetails -->', JSON.stringify(this.fieldDetails));
                var uniqueItems = Array.from(new Set(dummyFetchDetails.map(item => JSON.stringify(item)))).map(item => JSON.parse(item));
                uniqueItems = uniqueItems.sort((a, b) => a.label - b.label);
                uniqueItems.forEach(item => {
                    var tempDummyFetch = [];
                    this.fieldDetails.forEach(subitem => {
                        if (subitem.Parent_Screen__r.Screen_Sequence__c == item.label) {
                            tempDummyFetch.push(subitem);
                        }
                    });
                    item.value = tempDummyFetch;
                });
                this.fieldDetails = uniqueItems;
                await this.fetchRecordDetails();
                this.allIndexs = uniqueItems.map(resp => resp.label);
                this.isAccordionReady = true;
            }
        } catch (error) {
            console.log('Error getScreenDetailsFromApex -->' + JSON.stringify(error));
        }
    }

    connectedCallback() {
        loadScript(this, jsPDFLib)
            .then(() => {
                console.log('jsPDFLib loaded successfully');
            })
            .catch(error => {
                console.error('Error loading jsPDFLib', JSON.stringify(error));
            });
        this.fetchProducDetails();
        setTimeout(() => {
            this.handlePassAllSections();
        }, 2000);
    }

    getSalaryData(){
        getSalaryDetails({loanId: this.recordId})
        .then(response => {
            console.log('getSalaryDetails: '+JSON.stringify(response));
            this.salaryDetails = response;
        })
        .catch(error=>{
            console.log('getSalaryDetails -->',error);
        });
    }

    getRecoNoteData(){
        getRecoNotesDetails({loanId: this.recordId})
        .then(response => {
            console.log('getRecoNotesDetails: '+JSON.stringify(response));
            this.recoNoteDetails = response;
        })
        .catch(error=>{
            console.log('getSalaryDetails -->',error);
        });
    }

    getDocumentDetailsForFCU(){
        getAllDocument({recordId: this.recordId}).then(data=>{
            this.alldocuments = data;
        }).catch(error=>{
            console.log('Some error fetching docs>>'+JSON.stringify(error));
        })
    }

    getTechnicalData(){
        getTechnicalRecords({
            'recordId' : this.recordId
        }).then(result=>{
            this.technicalRecords = result;
            console.log('this.technicalRecords >>>'+JSON.stringify(this.technicalRecords));
        }).catch(error=>{
            console.log('There is error fetching technical records>>'+JSON.stringify(error));
        })
    }

    getPropertyData(){
        getAllPropertyDetails({'loanId' : this.recordId}).then(res=>{
            this.propertyRecords = res;
        }).catch(error=>{
            console.log('There is error fetching property records>>'+JSON.stringify(error));
        })
    }

    getProductTableDetails(){
        fetchAllProducts({ loanId: this.recordId })
        .then((result) => {
            this.productTableRecs = result;
            console.log('this.productTableRecs>>>>>'+JSON.stringify(this.productTableRecs));
            this.productTableRecs.forEach(product => {
                product.prodType = (product.productType === 'Parent') ? 'Primary' : 'Secondary';
            });
        }).catch(err=>{
            console.log('Err>>>'+JSON.stringify(err));
        })
    }

    getCovenantData(){
        getCovenantDetail({ recordId: this.recordId }).then(data=>{
            getDocumentDetailRecord({ documentMasterId: data.Id, recordId: this.recordId })
                .then(result => {
                    this.covernantData = result;
                    console.log('Isnide 326 covernantData---'+JSON.stringify(this.covernantData));
                })
                .catch(error => {
                    console.log('error ::', error);
                });
        }).catch(err=>{
            console.log('Err>>>'+JSON.stringify(err));
        })
    }

    fetchSubProduct(){
        getSubProductDetails({loanId : this.recordId}).then(data=>{
            this.subProductDetails = data;
            console.log(' this.subProductDetails>>>>'+JSON.stringify( this.subProductDetails));
        }).catch(error=>{
            console.lod('errr in subproduct>>'+JSON.stringify(error));
        })
    }

    fetchProducDetails(){
        var inputMapParam = {
            'oppId': this.recordId
        };
        getProductDetails({inputMap : inputMapParam})
        .then(result =>{
            console.log('result product: '+ JSON.stringify(result));
            this.isHLRelated = result.isHLRelated;
            console.log('this.isHLRelated>>'+this.isHLRelated);
            if(this.isHLRelated){
                this.formIdentifier = 'HL CAM Details';
                this.getSalaryData();
                this.getRecoNoteData();
            }else{
                this.formIdentifier = 'CAM Details';
            }
            console.log('this.formIdentifier 237>>>>>'+this.formIdentifier);
            this.getSourcingDetails();
            this.getScreenDetailsFromApex();
            this.getDocumentDetailsForFCU();
            this.getTechnicalData();
            this.getPropertyData();
            this.fetchSanctions();
            this.getObligationData();
            console.log('call approvakl detail 331');
            this.getLoanApprovalDetails();
            console.log('end approvakl detail 331');
            this.getAppDetails();
            this.getProductTableDetails();
            this.fetchSubProduct();
            this.getCovenantData();
            this.hanldeRefresh();
        })
        .catch(error=>{
            console.error('error in getting product: '+ error)
        })
    }

    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD] })
    opportunity({ error, data }) {
        if (data) {
            this.oppStage = data.fields.StageName.value;
        }
    }

    handleSectionToggle(event) {
        const activeSections = event.detail.openSections;
        this.mainAccordianActiveSactions = activeSections;
    }

    async getCurrentScreenFieldDetails() {
        const promises = this.fieldDetails.map(async (item) => {
            item.picklistOptions = await this.getPicklistOptionsFromApex(item.Is_Picklist__c, item.Storage_Object__c, item.Storage_Field__c);
        });
        await Promise.all(promises);
    }

    async getFilteredPicklistValues(picklistValues) {
        var tempVal = picklistValues.split(',');
        let picklistOptions = [];
        for (var i = 0; i < tempVal.length; i++) {
            let doc = {
                label: tempVal[i],
                value: tempVal[i]
            };
            picklistOptions.push(doc);
        }
        return picklistOptions;
    }

    async getPicklistOptionsFromApex(isPicklist, storageObject, storageField) {
        if (isPicklist) {
            const result = await getPicklistValues({
                storageObject: storageObject,
                storageField: storageField
            });
            let picklistOptions = result.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });
            return picklistOptions;
        }
    }

    async fetchRecordDetails() {
        try {
            const promises = this.fieldDetails.map(async (record) => {
                console.log('record.name>>'+record.name);
                if (record.name == 'Sourcing Details') {
                    record.sourcingDetails = true
                }
                else {
                    record.sourcingDetails = false
                }
                if(record.name == 'Product Details'){
                    record.productDetailsScreen = true;
                }else{
                    record.productDetailsScreen = false;
                }
                if(record.name == 'Technical Evaluation'){
                    record.technicalEvaluationScreen = true;
                }else{
                    record.technicalEvaluationScreen = false;
                }
                if(record.name == 'FCU'){
                    record.fcuScreen = true;
                }else{
                    record.fcuScreen = false;
                }
                if(record.name == 'Covenant'){
                    record.covenantScreen = true;
                }else{
                    record.covenantScreen = false;
                }
                if(record.name == 'Income Assessment Details'){
                    record.incomeAssessmentScreen = true;
                }else{
                    record.incomeAssessmentScreen = false;
                }
                if(record.name == 'Approval'){
                    record.approvalScreen = true;
                }else{
                    record.approvalScreen = false;
                }
                if (record.name == 'Sanction Conditions') {
                    record.SanctionConditionsScreen = true
                } else {
                    record.SanctionConditionsScreen = false
                }
                if (record.name == 'Obligation Details') {
                    record.ObligationScreen = true
                } else {
                    record.ObligationScreen = false
                }
                if (record.name == 'Property Details') {
                    console.log('472>>>>> Property Cmp');
                    record.propertyCmp = true
                } else {
                    record.propertyCmp = false
                }
                if (record.name == 'Integration Details') {
                    record.IntegrationScreen = true;
                } else {
                    record.IntegrationScreen = false;
                }
                if (record.name == 'Eligibility') {
                    record.EligibilityScreen = true;
                } else {
                    record.EligibilityScreen = false;
                }
                const result = await getLoanDetailsFromStorageObject({
                    screenName: record.name,
                    loanId: this.recordId,
                    formIdentifier: this.formIdentifier
                });
                console.log('result 352>>'+JSON.stringify(result));
                const formFieldsMap = new Map();
                result.forEach(pair => {
                    if (!formFieldsMap.has(pair.fieldApiName)) {
                        formFieldsMap.set(pair.fieldApiName, []);
                    }
                    formFieldsMap.get(pair.fieldApiName).push(...pair.fieldValue);
                });
                const updatedValues = record.value.map(fieldDetail => {
                    return {
                        ...fieldDetail,
                        value: formFieldsMap.get(fieldDetail.Read_Field_Name__c) || ['--']
                    };
                });
                record.value = updatedValues;
                if (record.name === 'Loan Application Details') {
                    this.loadLookUps = true;
                }
            });
            await Promise.all(promises);
        } catch (error) {
            console.error('Error fetching details:', error);
        }
    }

    handlePassAllSections() {
        this.mainAccordianActiveSactions = this.fieldDetails.map(item => item.name);
        this.mainAccordianActiveSactions = [...this.mainAccordianActiveSactions, 'Income Method'];
        this.mainAccordianActiveSactions = [...this.mainAccordianActiveSactions, 'Approval'];
        this.mainAccordianActiveSactions = [...this.mainAccordianActiveSactions, 'Product'];
        this.mainAccordianActiveSactions = [...this.mainAccordianActiveSactions, 'Covenant'];
        this.mainAccordianActiveSactions = [...this.mainAccordianActiveSactions, 'Technical Evaluation'];
        this.mainAccordianActiveSactions = [...this.mainAccordianActiveSactions, 'FCU'];
        this.mainAccordianActiveSactions = [...this.mainAccordianActiveSactions, 'Income Assessment Details'];
        this.showOpenAll = false;
        console.log('oppStage>>>>', this.oppStage);
        if (this.oppStage == 'PSV') {
            this.showPDF = false;
        } else {
            this.showPDF = true;
        }
    }

    handleCloseAllSections() {
        this.showOpenAll = true;
        this.mainAccordianActiveSactions = [];
    }

    loadScriptFromCDN(src) {
        try {
            return new Promise((resolve, reject) => {
                const script = document.createElement('script');
                script.src = src;
                script.onload = resolve;
                script.onerror = reject;
                document.body.appendChild(script);
            });
        } catch (e) {
            console.log('error ', e.message);
        }
    }

    renderedCallback() {
        if (!this.libsLoaded) {
            this.libsLoaded = true;
            loadScript(this, html2canvasLib)
                .then(() => {
                    console.log('html2canvas loaded successfully');
                })
                .catch(error => {
                    console.error('Error loading html2canvas', error);
                });
        }
        if (!this.isRendered) {
            const style = document.createElement("style");
            style.innerText = `
            .bsa-page .slds-accordion__list-item .section-control{
               
                background: linear-gradient(135deg, #02133f 0%,#00215e 55%, #002d67 100%);
                color: #ffffff;
                margin-left: 0px;
                margin-bottom: 0px;
                margin-right: 0px;
                font-weight: 500;
            }
            .bsa-page .slds-accordion__summary {
                padding: 10px 0px 0px 0px;
            }
            .bsa-datatable .slds-line-height_reset .slds-cell-fixed .slds-th__action{
                background: #5bb6e3;
                color: white;
            }
            .bsa-datatable .slds-th__action.slds-th__action_form.slds-cell-fixed{
                background: #5bb6e3;
            }
            .bsa-datatable tbody{
                font-weight: 400;
            }
            .bsa-page .slds-accordion__content {
                margin-top: 10px;
            }
        `;
            this.template.querySelector(".styleContainer")?.appendChild(style);
            this.isRendered = true;
        }
        if (this.jsLibInitialized) {
            return;
        }
        this.jsLibInitialized = true;
        Promise.all([
            loadScript(this, jsPDFResource).then(() => {
                return loadScript(this, jsPDFAutoTableResource);
            })
        ])
            .then(() => {
                console.log('jsPDF and autoTable loaded');
            })
            .catch(error => {
                console.error('Error loading libraries: ', error);
            });
    }

    getSourcingDetails() {
        getSourcingDetailsFields({
            loanId: this.recordId
        })
            .then((result) => {
                this.sourcingData = result;
            })
            .catch((error) => {
                console.error("sourcingDataerror :- ", error);
            });
    }

    getAppDetails() {
        getApplicants({
            recordId: this.recordId,
        })
            .then((response) => {
                this.appdata = response;
                if (this.appdata.length > 0) {
                    this.hasData = true;
                }
            })
            .catch((error) => {
                console.log("error in getEmployeeCheckData---", error);
            });
    }

    getObligationData() {
        getObligationsRecords({
            recordId: this.recordId,
            isOneView: this.isHLRelated ? false : true,
        })
        .then((response) => {
            if (Object.keys(response).length === 0) {
                this.isNoObligationRecordsFound = true;
            } else {
                this.isNoObligationRecordsFound = false;
                this.allData = response;
                this.recordData = response.lstOblRec;
                this.totalData = response.totalWrap;
                this.filteredList = this.recordData;
            }
            this.spinner = false;
        });
    }

    fetchSanctions() {
        getAllSanctionConditions({ recordId: this.recordId })
            .then((result) => {
                console.log('this.getAllSanctionConditions-->' + JSON.stringify(result));
                this.allSanctions = result;
            })
            .catch((error) => {
                console.error('Error getAllSanctionConditions --> ', JSON.stringify(error));
            });
    }

    hanldeRefresh() {
        getProductsByOpportunity({
            loanApplicationId: this.recordId,
        })
            .then((response) => {
                if (response) {
                    console.log('products: ' + JSON.stringify(response));
                    this.products = response;
                }else {
                    console.log('No products returned from Apex.');
                }
            })
            .catch((error) => { });
    }

    getLoanApprovalDetails() {
        console.log('730>>>');
        if(!this.isHLRelated){
            getApprovalDetails({
                recordId: this.recordId
            })
                .then((result) => {
                    console.log('result in getLoanApprovalDetails::::', result);
                    if (result) {
                        this.approvalData = result;
                        console.log('this.approvalData---', JSON.stringify(this.approvalData));
                    }
                })
                .catch((error) => {
                    this.spinner = false;
                    console.log('errror--- in getLoanApprovalDetails', error);
                });
        }else{
            getLoanApprovalDetails({
                loanId: this.recordId,
                approvalType : 'Loan Approval'
            }).then(result=>{
                console.log('RESULT 755>>'+JSON.stringify(result));
                this.approvalData = result;
            }).catch(err=>{
                console.log('errror--- in getLoanApprovalDetails', err);
            })
        }
    }

    generatePDF() {
        this.spinner = true;
        const { jsPDF } = window.jspdf;
        const doc = new jsPDF('l', 'mm', 'a4');
        let yPos = 15;
        doc.setFontSize(16);
        doc.text('ONE VIEW', doc.internal.pageSize.getWidth() / 2, yPos, { align: 'center' });
        yPos += 10;
        //Sourcing Details
        if (this.sourcingData?.length) {
            const sectionHeaderHeight = 8;
            const verticalPadding = 2;
            const tableMargin = { left: 15, right: 15 };
            const rectWidth = doc.internal.pageSize.getWidth() - tableMargin.left - tableMargin.right;
            doc.setFillColor(200, 200, 200);
            doc.rect(tableMargin.left, yPos, rectWidth, sectionHeaderHeight, 'F');
            doc.setFont('helvetica', 'bold');
            doc.setFontSize(12);
            doc.setTextColor(0);
            doc.text(
                'Sourcing Details',
                tableMargin.left + 2,
                yPos + verticalPadding + (sectionHeaderHeight - 2 * verticalPadding) / 2 + 1
            );
            yPos += sectionHeaderHeight;
            const tableBody = this.sourcingData.map(rowWrapper => {
                const row = [];
                rowWrapper.tableData.forEach(col => {
                    row.push(col.header || '--');
                    row.push(col.value || '--');
                });
                return row;
            });
            const numColumns = Math.max(...tableBody.map(r => r.length));
            const tableHeaders = Array(numColumns).fill('');
            doc.autoTable({
                startY: yPos,
                margin: tableMargin,
                body: tableBody,
                theme: 'grid',
                styles: {
                    fontSize: 9,
                    cellPadding: 2,
                    halign: 'center',
                    valign: 'middle',
                    overflow: 'linebreak'
                },
                didParseCell: function (data) {
                    if (data.column.index % 2 === 0 && data.cell.section === 'body') {
                        data.cell.styles.fillColor = [91, 182, 227];
                        data.cell.styles.fontStyle = 'bold';
                        data.cell.styles.textColor = 0;
                    } else {
                        data.cell.styles.fillColor = [255, 255, 255];
                        data.cell.styles.fontStyle = 'normal';
                    }
                },
                columnStyles: Array.from({ length: numColumns }, (_, i) => ({
                    cellWidth: 'wrap'
                })).reduce((acc, val, i) => {
                    acc[i] = val;
                    return acc;
                }, {})
            });
            yPos = doc.lastAutoTable.finalY + 10;
        }

        // Income Method Details
        if(!this.isHLRelated){
            if (this.appdata.length > 0) {
                const sectionHeaderHeight = 8;
                const verticalPadding = 2;
                const rectWidth = doc.internal.pageSize.getWidth() - 30;
                doc.setFillColor(200, 200, 200);
                doc.rect(15, yPos, rectWidth, sectionHeaderHeight, 'F');
                doc.setFont('helvetica', 'bold');
                doc.setFontSize(12);
                doc.setTextColor(0);
                const textWidth = doc.getTextWidth('Income Method');
                doc.text(
                    'Income Method',
                    15 + rectWidth / 2 - textWidth / 2,
                    yPos + verticalPadding + (sectionHeaderHeight - 2 * verticalPadding) / 2 + 1
                );
                yPos += sectionHeaderHeight;
                const incomeHeaders = ['Application & Applicant', 'Select Income Method'];
                const incomeRows = this.appdata.map(record => [
                    record.appName || '--',
                    record.selectedValue || '--'
                ]);
                doc.autoTable({
                    startY: yPos,
                    head: [incomeHeaders],
                    body: incomeRows,
                    theme: 'grid',
                    styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                    headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                    alternateRowStyles: { fillColor: [245, 245, 245] },
                    columnStyles: incomeHeaders.reduce((acc, h, i) => { acc[i] = { cellWidth: 'wrap' }; return acc; }, {}),
                    didParseCell: function (data) {
                        if (data.row.index === incomeRows.length - 1) {
                            data.cell.styles.fillColor = [200, 200, 200];
                            data.cell.styles.fontStyle = 'bold';
                        }
                    }
                });
                yPos = doc.lastAutoTable.finalY + 10;
            }
        }

        // Other screen field section
        this.fieldDetails?.forEach(section => {
            console.log('section-->', section.name);
            if(section.name == 'FCU'){
                const sectionHeaderHeight = 8;
                const verticalPadding = 2;
                const rectWidth = doc.internal.pageSize.getWidth() - 30;
                doc.setFillColor(200, 200, 200);
                doc.rect(15, yPos, rectWidth, sectionHeaderHeight, 'F');
                doc.setFont('helvetica', 'bold');
                doc.setFontSize(12);
                doc.setTextColor(0);
                const textWidth = doc.getTextWidth('FCU');
                doc.text(
                    'FCU',
                    15 + rectWidth / 2 - textWidth / 2,
                    yPos + verticalPadding + (sectionHeaderHeight - 2 * verticalPadding) / 2 + 1
                );
                yPos += sectionHeaderHeight;
                if(!this.isHLRelated) {
                    try{
                        const fcuheader = ['FCU Status','Overall FCU Verification'];
                        let rows = [
                            {
                                fcuStatus: this.fcuStatust || '--',
                                overallFcuStatus: this.ovreAllFcuStatus || '--'
                            }
                        ];
                        const ffnRows = rows.map(record => [
                            record.fcuStatus || '--',
                            record.overallFcuStatus || '--',
                        ]);
                        doc.autoTable({
                            startY: yPos,
                            head: [fcuheader],
                            body: ffnRows,
                            theme: 'grid',
                            styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                            headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                            alternateRowStyles: { fillColor: [245, 245, 245] },
                            columnStyles: fcuheader.reduce((acc, h, i) => { acc[i] = { cellWidth: 'wrap' }; return acc; }, {}),
                        });
                        yPos = doc.lastAutoTable.finalY + 10;
                    }catch(err) {
                        console.log('errre ----',err.message);
                    }
                }
                const obligationHeaders = ['Sr. No.','Document Name','Screening Status','Verification Status'];
                const obligationRows = this.alldocuments.map(record => [
                    record.docCount || '--',
                    record.docName || '--',
                    record.screeningstatus || 'FCU Initiated',
                    record.Status || '--',
                ]);
                doc.autoTable({
                    startY: yPos,
                    head: [obligationHeaders],
                    body: obligationRows,
                    theme: 'grid',
                    styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                    headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                    alternateRowStyles: { fillColor: [245, 245, 245] },
                    columnStyles: obligationHeaders.reduce((acc, h, i) => { acc[i] = { cellWidth: 'wrap' }; return acc; }, {}),
                });
                yPos = doc.lastAutoTable.finalY + 10;
            }

            if(section.name == 'Income Assessment Details'){
                const sectionHeaderHeight = 8;
                const verticalPadding = 2;
                const rectWidth = doc.internal.pageSize.getWidth() - 30;
                doc.setFillColor(200, 200, 200);
                doc.rect(15, yPos, rectWidth, sectionHeaderHeight, 'F');
                doc.setFont('helvetica', 'bold');
                doc.setFontSize(12);
                doc.setTextColor(0);
                const textWidth = doc.getTextWidth('Income Assessment Details');
                doc.text(
                    'Income Assessment Details',
                    15 + rectWidth / 2 - textWidth / 2,
                    yPos + verticalPadding + (sectionHeaderHeight - 2 * verticalPadding) / 2 + 1
                );
                yPos += sectionHeaderHeight;
                const obligationHeaders = [
                    'Product','PLR Code','Margin','Sanctioned ROI','Sanctioned Loan Amount',
                    'Sanctioned Tenor','Final EMI','Final FOIR','Final LTV Sanctioned Terms',
                    'Maximum Loan Eligibility Basis Income'
                ];
                const obligationRows = this.subProductDetails.map(record => [
                    record.Product__r.Name || '--',
                    record.PLR_Code__c || '--',
                    record.Margin__c || '--',
                    record.Sanctioned_ROI__c || '--',
                    record.Sanctioned_Loan_Amount__c || '--',
                    record.Sanctioned_Tenor__c || '--',
                    record.HL_Final_EMI__c || '--',
                    record.HL_Final_FOIR__c || '--',
                    record.HL_Final_LTVSanctioned_Terms__c || '--',
                    record.HL_Maximum_Loan_Eligibility_basis_Income__c || '--'
                ]);
                console.log('obligationRows 1026>>> '+JSON.stringify(obligationRows));
                doc.autoTable({
                    startY: yPos,
                    head: [obligationHeaders],
                    body: obligationRows,
                    theme: 'grid',
                    styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                    headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                    alternateRowStyles: { fillColor: [245, 245, 245] },
                    columnStyles: obligationHeaders.reduce((acc, h, i) => { acc[i] = { cellWidth: 'wrap' }; return acc; }, {})
                });
                yPos = doc.lastAutoTable.finalY +10;

                if(this.salaryDetails){
                    for(var key in this.salaryDetails){
                        var userData = this.salaryDetails[key];
                        var salaryData = userData[0];
                        var salHeaders = ['Type','Nature of Component','Particulars'];
                        var salRows = [];
                        var grossEarningRow = ['','',{ content: 'Gross Earnings Per Month', styles: { fontStyle: 'bold' } }];
                        var grossDeductionRow = ['','',{ content: 'Gross Deduction Per Month', styles: { fontStyle: 'bold' } }];
                        for(var i=0; i< salaryData.lstMonthLabels.length; i++){
                            salHeaders.push(salaryData.lstMonthLabels[i]);
                            grossEarningRow.push({ content: (salaryData.lstTotalAmount.length >0 ? salaryData.lstTotalAmount[i] : '0'), styles: { fontStyle: 'bold' } });
                            grossDeductionRow.push({ content: (salaryData.lstTotalAmountLess.length >0 ? salaryData.lstTotalAmountLess[i] : '0'), styles: { fontStyle: 'bold' } });
                        }
                        salHeaders.push('Average Amount');
                        var avgGrossEarning = 0;
                        for(var i=0; i< salaryData.lstEarningsWrapper.length; i++){
                            var row = salaryData.lstEarningsWrapper[i];
                            var data = ['Earning'];
                            data.push(row.strNatureOfComponent);
                            data.push(row.strParticulars);
                            for(var j=0; j< row.lstAmtWrapper.length; j++){
                                data.push(row.lstAmtWrapper[j].strMonthValue);
                            }
                            data.push(row.strAverage);
                            avgGrossEarning += parseFloat(row.strAverage);
                            salRows.push(data);
                        }
                        grossEarningRow.push({ content: avgGrossEarning, styles: { fontStyle: 'bold' } });
                        salRows.push(grossEarningRow);
                        var avgGrossDeduction = 0;
                        for(var i=0; i< salaryData.lstDeductionsWrapper.length; i++){
                            var row = salaryData.lstDeductionsWrapper[i];
                            var data = ['Deducation'];
                            data.push(row.strNatureOfComponent);
                            data.push(row.strParticulars);
                            for(var j=0; j< row.lstAmtWrapper.length; j++){
                                data.push(row.lstAmtWrapper[j].strMonthValue);
                            }
                            data.push(row.strAverage);
                            avgGrossDeduction += parseFloat(row.strAverage);
                            salRows.push(data);
                        }
                        grossDeductionRow.push({ content: avgGrossDeduction, styles: { fontStyle: 'bold' } });
                        salRows.push(grossDeductionRow);
                        console.log('salRows: '+JSON.stringify(salRows));
                        const earningHeaders = [[{ content: key, colSpan: (salaryData.lstMonthLabels.length +4), styles: { halign: 'center', fillColor: [22, 160, 133] } }]];
                        earningHeaders.push(salHeaders);
                        const earningRows = salRows;
                        doc.autoTable({
                            startY: yPos,
                            head: earningHeaders,
                            body: earningRows,
                            theme: 'grid',
                            styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                            headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                            alternateRowStyles: { fillColor: [245, 245, 245] }
                        });
                        yPos = doc.lastAutoTable.finalY +10;

                        var bonusData = userData[1];
                        var bonHeaders = [['Sr.No.','Bonus','Gross Amount','Multiplier','I-Tax Slab','Net Amount']];
                        var bonRows = [];
                        for(var i=0; i< bonusData.yearlyChildData.length; i++){
                            var row = bonusData.yearlyChildData[i];
                            var data = [];
                            data.push(row.srNo);
                            data.push(row.yearlyComponent);
                            data.push(row.grossAmount);
                            data.push(row.multiplier);
                            data.push(row.taxSlab);
                            data.push(row.netAmount ? row.netAmount : '0');
                            bonRows.push(data);
                        }
                        var avgBonusRow = ['',{ content: 'Average Bonus', styles: { fontStyle: 'bold' } }];
                        avgBonusRow.push({ content: (bonusData.averageGrossAmount ? bonusData.averageGrossAmount : '0'), styles: { fontStyle: 'bold' } },'','');
                        avgBonusRow.push({ content: (bonusData.averageNetAmount ? bonusData.averageNetAmount : '0'), styles: { fontStyle: 'bold' } });
                        bonRows.push(avgBonusRow);
                        var totalBonusRow = ['',{ content: 'Total Bonus', styles: { fontStyle: 'bold' } }];
                        totalBonusRow.push({ content: bonusData.grossAmount, styles: { fontStyle: 'bold' } },'','');
                        totalBonusRow.push({ content: bonusData.netAmount, styles: { fontStyle: 'bold' } });
                        bonRows.push(totalBonusRow);
                        console.log('bonRows: '+JSON.stringify(bonRows));
                        const bonusHeaders = bonHeaders;
                        const bonusRows = bonRows;
                        doc.autoTable({
                            startY: yPos,
                            head: bonusHeaders,
                            body: bonusRows,
                            theme: 'grid',
                            styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                            headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                            alternateRowStyles: { fillColor: [245, 245, 245] }
                        });
                        yPos = doc.lastAutoTable.finalY +10;

                        var incentiveData = userData[2];
                        var incHeaders = [['Sr.No.','Incentive','Frequency','Gross Amount','Multiplier','I-Tax Slab','Net Amount']];
                        var incRows = [];
                        for(var i=0; i< incentiveData.yearlyChildData.length; i++){
                            var row = incentiveData.yearlyChildData[i];
                            var data = [];
                            data.push(row.srNo);
                            data.push(row.yearlyComponent);
                            data.push(row.frequency);
                            data.push(row.grossAmount);
                            data.push(row.multiplier);
                            data.push(row.taxSlab);
                            data.push(row.netAmount ? row.netAmount : '0');
                            incRows.push(data);
                        }
                        var avgIncentiveRow = ['',{ content: 'Average Incentive', styles: { fontStyle: 'bold' } },''];
                        avgIncentiveRow.push({ content: (incentiveData.averageGrossAmount ? incentiveData.averageGrossAmount : '0'), styles: { fontStyle: 'bold' } },'','');
                        avgIncentiveRow.push({ content: (incentiveData.averageNetAmount ? incentiveData.averageNetAmount : '0'), styles: { fontStyle: 'bold' } });
                        incRows.push(avgIncentiveRow);
                        var totalIncentiveRow = ['',{ content: 'Total Incentive', styles: { fontStyle: 'bold' } },''];
                        totalIncentiveRow.push({ content: incentiveData.grossAmount, styles: { fontStyle: 'bold' } },'','');
                        totalIncentiveRow.push({ content: incentiveData.netAmount, styles: { fontStyle: 'bold' } });
                        incRows.push(totalIncentiveRow);
                        console.log('incRows: '+JSON.stringify(incRows));
                        const incentiveHeaders = incHeaders;
                        const incentiveRows = incRows;
                        doc.autoTable({
                            startY: yPos,
                            head: incentiveHeaders,
                            body: incentiveRows,
                            theme: 'grid',
                            styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                            headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                            alternateRowStyles: { fillColor: [245, 245, 245] }
                        });
                        yPos = doc.lastAutoTable.finalY +10;

                        var rentalData = userData[3];
                        var rentalRows = [];
                        var row = [];
                        row.push({ content: 'Rental Income Yearly', styles: { fontStyle: 'bold', halign: 'left' } });
                        row.push({ content: rentalData ? rentalData : '0.00', styles: { halign: 'left' } });
                        rentalRows.push(row);
                        doc.autoTable({
                            startY: yPos,
                            head: [],
                            body: rentalRows,
                            theme: 'grid',
                            styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                            headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                            alternateRowStyles: { fillColor: [245, 245, 245] }
                        });
                        yPos = doc.lastAutoTable.finalY +10;
                    }
                }
            }

            if(section.name == 'Technical Evaluation'){
                const sectionHeaderHeight = 8;
                const verticalPadding = 2;
                const rectWidth = doc.internal.pageSize.getWidth() - 30;
                doc.setFillColor(200, 200, 200);
                doc.rect(15, yPos, rectWidth, sectionHeaderHeight, 'F');
                doc.setFont('helvetica', 'bold');
                doc.setFontSize(12);
                doc.setTextColor(0);
                const textWidth = doc.getTextWidth('Technical Evaluation');
                doc.text(
                    'Technical Evaluation',
                    15 + rectWidth / 2 - textWidth / 2,
                    yPos + verticalPadding + (sectionHeaderHeight - 2 * verticalPadding) / 2 + 1
                );
                yPos += sectionHeaderHeight;
                const obligationHeaders = [
                    'Sr. No.','Stage','Assigned To Admin','Initiated By','Initiated On','Address','Status','Valuation','Final Valuation'
                ];
                const obligationRows = this.technicalRecords.map(record => [
                    record.srno || '--',
                    record.status || '--',
                    record.assignedToAdmin || '--',
                    record.initiatedBy || '--',
                    record.initiatedOn || '--',
                    record.collateralAddress || '--',
                    record.finalStatus || '--',
                    record.valuation || '--',
                    record.marketVal || '--',
                ]);
                doc.autoTable({
                    startY: yPos,
                    head: [obligationHeaders],
                    body: obligationRows,
                    theme: 'grid',
                    styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                    headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                    alternateRowStyles: { fillColor: [245, 245, 245] },
                    columnStyles: obligationHeaders.reduce((acc, h, i) => { acc[i] = { cellWidth: 'wrap' }; return acc; }, {}),
                });
                yPos = doc.lastAutoTable.finalY + 10;
            }

            if(section.name == 'Product Details' ){
                const sectionHeaderHeight = 8;
                const verticalPadding = 2;
                const rectWidth = doc.internal.pageSize.getWidth() - 30;
                doc.setFillColor(200, 200, 200);
                doc.rect(15, yPos, rectWidth, sectionHeaderHeight, 'F');
                doc.setFont('helvetica', 'bold');
                doc.setFontSize(12);
                doc.setTextColor(0);
                const textWidth = doc.getTextWidth('Product Details');
                doc.text(
                    'Product Details',
                    15 + rectWidth / 2 - textWidth / 2,
                    yPos + verticalPadding + (sectionHeaderHeight - 2 * verticalPadding) / 2 + 1
                );
                yPos += sectionHeaderHeight;
                const obligationHeaders = [
                    'Product Name','Sub Product','Loan Purpose',
                    'Repayment Variant','Sub Variant',
                    'Interest Only Tenure','Loan Facility','Scheme Name',
                    'Requested Loan Amount','Requested ROI(%)',
                    'Primary/Secondary','Full EMI Tenure','Total Tenure'
                ];
                const obligationRows = this.productTableRecs.map(record => [
                    record.prodName || '--',
                    record.subProdName || '--',
                    record.loanPurpose || '--',
                    record.variant || '--',
                    record.subvariantName || '--',
                    record.hybridTenureName || '--',
                    record.loanFacility || '--',
                    record.schemeProdName || '--',
                    record.loanAmoutReq || '--',
                    record.requestedROI || '--',
                    record.prodType || '--',
                    record.fullEMI || '--',
                    record.totalTenure|| '--'
                ]);
                doc.autoTable({
                    startY: yPos,
                    head: [obligationHeaders],
                    body: obligationRows,
                    theme: 'grid',
                    styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                    headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                    alternateRowStyles: { fillColor: [245, 245, 245] },
                    columnStyles: obligationHeaders.reduce((acc, h, i) => { acc[i] = { cellWidth: 'wrap' }; return acc; }, {}),
                });
                yPos = doc.lastAutoTable.finalY + 10;
            }

            if(section.name == 'Covenant'){
                const leftMargin = 15;
                const rightMargin = 15;
                const sectionHeaderHeight = 8;
                const verticalPadding = 2;
                const rectWidth = doc.internal.pageSize.getWidth() - leftMargin - rightMargin;
                doc.setFillColor(200, 200, 200);
                doc.rect(leftMargin, yPos, rectWidth, sectionHeaderHeight, 'F');
                doc.setFont('helvetica', 'bold');
                doc.setFontSize(12);
                doc.setTextColor(0);
                const title = 'Covenant Details';
                const titleWidth = doc.getTextWidth(title);
                doc.text(
                    title,
                    leftMargin + rectWidth / 2 - titleWidth / 2,
                    yPos + verticalPadding + (sectionHeaderHeight - 2 * verticalPadding) / 2 + 1
                );
                yPos += sectionHeaderHeight;
                let colWidths = [20, 20, 20, 20, 20, 50, 20, 20, 20, 20, 20, 20, 20];
                const obligationHeaders = [
                    'Category','Covenant Type','Covenant Approval Status','Name','Product','Description',
                    'Type','Remarks','Target Date','Document Date of Receipt','Nature of Document','Requestor Name','Approver Name',
                ];
                const scaleWidthsTo = (widths, target) => {
                    const sum = widths.reduce((a, b) => a + b, 0);
                    if (sum === 0) return widths.map(() => target / widths.length);
                    const scaled = widths.map(w => (w / sum) * target);
                    const totalScaled = scaled.reduce((a, b) => a + b, 0);
                    const diff = target - totalScaled;
                    if (Math.abs(diff) > 0.001) { scaled[5] += diff; }
                    return scaled;
                };
                colWidths = scaleWidthsTo(colWidths, rectWidth);
                const columnStyles = {};
                colWidths.forEach((w, i) => { columnStyles[i] = { cellWidth: w }; });
                columnStyles[0].halign  = 'left';
                columnStyles[1].halign  = 'left';
                columnStyles[2].halign  = 'center';
                columnStyles[3].halign  = 'left';
                columnStyles[4].halign  = 'left';
                columnStyles[5].halign  = 'left';
                columnStyles[6].halign  = 'center';
                columnStyles[7].halign  = 'left';
                columnStyles[8].halign  = 'center';
                columnStyles[9].halign  = 'center';
                columnStyles[10].halign = 'left';
                columnStyles[11].halign = 'left';
                columnStyles[12].halign = 'left';
                const fmt = v => (v ?? '--');
                let obligationRows = [];
                const hasData = Array.isArray(this.covernantData) &&
                                this.covernantData.length > 0 &&
                                this.covernantData[0] &&
                                Array.isArray(this.covernantData[0].documentList) &&
                                this.covernantData[0].documentList.length > 0;
                if (hasData) {
                    obligationRows = this.covernantData[0].documentList.map(record => {
                        const category   = record?.covenantCategory ?? '--';
                        const covType    = record?.covenantType ?? '--';
                        const apprStatus = record?.covenantApprovalStatus ?? '--';
                        const name       = record?.covenantName ?? '--';
                        const product    = record?.productName ?? '--';
                        const desc       = record?.description ?? '--';
                        const type       = record?.docType ?? '--';
                        const remarks    = record?.remarks ?? '--';
                        const tgtDate    = fmt(record?.targetDate);
                        const dor        = fmt(record?.documentDateOfReceipt);
                        const nature     = record?.natureOfDocument ?? '--';
                        const reqName    = record?.requestorsName ?? '--';
                        const apprName   = record?.approversName ?? '--';
                        return [ category, covType, apprStatus, name, product, desc, type, remarks, tgtDate, dor, nature, reqName, apprName ];
                    });
                } else {
                    obligationRows = [[ 'No covenant records available', '', '', '', '', '', '', '', '', '', '', '', '' ]];
                }
                doc.autoTable({
                    startY: yPos,
                    head: [obligationHeaders],
                    body: obligationRows,
                    theme: 'grid',
                    margin: { left: leftMargin, right: rightMargin },
                    tableWidth: rectWidth,
                    styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                    headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                    alternateRowStyles: { fillColor: [245, 245, 245] },
                    columnStyles,
                    didParseCell: (data) => {
                        if (data.section === 'head') {
                            const len = (data.cell.text || []).join(' ').length;
                            if (len > 28) data.cell.styles.fontSize = 8.5;
                        }
                        if (data.section === 'body') {
                            const txtLen = (data.cell.text || []).join(' ').length;
                            if (txtLen > 300) data.cell.styles.fontSize = 8.5;
                        }
                    }
                });
                yPos = doc.lastAutoTable.finalY + 10;
            }

            if (section.name === 'Property Details') {
                const sectionHeaderHeight = 8;
                const verticalPadding = 2;
                const rectWidth = doc.internal.pageSize.getWidth() - 30;
                const leftMargin = 15;
                doc.setFillColor(200, 200, 200);
                doc.rect(leftMargin, yPos, rectWidth, sectionHeaderHeight, 'F');
                doc.setFont('helvetica', 'bold');
                doc.setFontSize(12);
                doc.setTextColor(0);
                const textWidth = doc.getTextWidth(section.name);
                doc.text(
                    section.name,
                    leftMargin + rectWidth / 2 - textWidth / 2,
                    yPos + verticalPadding + (sectionHeaderHeight - 2 * verticalPadding) / 2 + 1
                );
                yPos += sectionHeaderHeight + 2;
                const headers = [
                    'Property Address','Collateral Type','Address Type','Construction Stage',
                    'Property Usage','Documented Value','Approved Valuation','Technical Remarks'
                ];
                const colWidths = [55, 30, 22, 25, 45, 30, 30, 35];
                const toWrapped = (value, widthMm) => {
                    const text = (value ?? '--').toString();
                    return doc.splitTextToSize(text, widthMm);
                };
                const rows = this.propertyRecords.map(r => ([
                    toWrapped(r.propertyDetails,      colWidths[0]),
                    toWrapped(r.propertyType,         colWidths[1]),
                    toWrapped(r.addressType,          colWidths[2]),
                    toWrapped(r.constructionStage,    colWidths[3]),
                    toWrapped(r.propertyUsage,        colWidths[4]),
                    toWrapped(r.documentedValue,      colWidths[5]),
                    toWrapped(r.approvedValuation,    colWidths[6]),
                    toWrapped(r.technicalRemarks,     colWidths[7]),
                ]));
                const columnStyles = colWidths.reduce((acc, w, i) => {
                    acc[i] = { cellWidth: w };
                    return acc;
                }, {});
                doc.autoTable({
                    startY: yPos,
                    margin: { left: leftMargin, right: 15 },
                    tableWidth: 'wrap',
                    head: [headers],
                    body: rows,
                    theme: 'grid',
                    styles: { font: 'helvetica', fontSize: 9, halign: 'center', valign: 'middle', cellPadding: 2, overflow: 'linebreak' },
                    headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                    alternateRowStyles: { fillColor: [245, 245, 245] },
                    columnStyles,
                    didParseCell(data) {
                        data.cell.styles.minCellHeight = 8;
                    }
                });
                yPos = doc.lastAutoTable.finalY + 10;
            }

            if (section.name == 'Obligation Details' && !this.isNoObligationRecordsFound && this.filteredList?.length) {
                const leftMargin = 15;
                const rightMargin = 15;
                const sectionHeaderHeight = 8;
                const verticalPadding = 2;
                const rectWidth = doc.internal.pageSize.getWidth() - leftMargin - rightMargin;
                doc.setFillColor(200, 200, 200);
                doc.rect(leftMargin, yPos, rectWidth, sectionHeaderHeight, 'F');
                doc.setFont('helvetica', 'bold');
                doc.setFontSize(12);
                doc.setTextColor(0);
                const title = 'Obligation Details';
                const titleWidth = doc.getTextWidth(title);
                doc.text(
                    title,
                    leftMargin + rectWidth / 2 - titleWidth / 2,
                    yPos + verticalPadding + (sectionHeaderHeight - 2 * verticalPadding) / 2 + 1
                );
                yPos += sectionHeaderHeight;
                const obligationHeaders = [
                    'Customer Name', 'Customer Type', 'Start Date', 'Loan Type', 'Loan Amount',
                    'Outstanding Balance', 'Consider for FOIR', 'Imputed EMI', 'Security Type',
                    'Banking', 'EMI Bounce', 'Balance Tenure', 'Remarks'
                ];
                const fmtCurrency = v => {
                    if (v === null || v === undefined || v === '') return '--';
                    const num = Number(String(v).toString().replace(/,/g, ''));
                    return isNaN(num) ? String(v) : num.toLocaleString('en-IN');
                };
                const fmtDate = v => (v || '--');
                let colWidths = [24, 18, 16, 18, 20, 22, 20, 18, 18, 14, 16, 18, 38];
                const scaleWidthsTo = (widths, target) => {
                    const sum = widths.reduce((a, b) => a + b, 0);
                    if (sum <= 0) return widths.map(() => target / widths.length);
                    const scaled = widths.map(w => (w / sum) * target);
                    const total = scaled.reduce((a, b) => a + b, 0);
                    const diff = target - total;
                    if (Math.abs(diff) > 0.001) scaled[12] += diff;
                    return scaled;
                };
                colWidths = scaleWidthsTo(colWidths, rectWidth);
                const columnStyles = {};
                colWidths.forEach((w, i) => { columnStyles[i] = { cellWidth: w }; });
                columnStyles[0].halign  = 'left';
                columnStyles[3].halign  = 'left';
                columnStyles[8].halign  = 'left';
                columnStyles[12].halign = 'left';
                columnStyles[2].halign  = 'center';
                columnStyles[6].halign  = 'center';
                columnStyles[9].halign  = 'center';
                columnStyles[10].halign = 'center';
                columnStyles[11].halign = 'center';
                const data = Array.isArray(this.recordData) ? this.recordData : [];
                const obligationRows = data.map(record => ([
                    record.customerName || '--',
                    record.customerType || '--',
                    fmtDate(record.startDate),
                    record.loanType || '--',
                    fmtCurrency(record.loanAmount),
                    fmtCurrency(record.outstandingBalance),
                    (record.isObligation ? 'Yes' : 'No'),
                    fmtCurrency(record.emi),
                    record.securityType || '--',
                    record.isBanking ? '\u2714' : '\u2717',
                    record.emiBounce || '--',
                    record.balanceTenure || '--',
                    record.remarks || '--'
                ]));
                obligationRows.push([
                    'Total', '', '', '',
                    fmtCurrency(this.totalData?.totalLoanAmount) || '--',
                    fmtCurrency(this.totalData?.totalOutstandingBalance) || '--',
                    '',
                    fmtCurrency(this.totalData?.totalEmi) || '--',
                    '', '', '', '', ''
                ]);
                doc.autoTable({
                    startY: yPos,
                    head: [obligationHeaders],
                    body: obligationRows,
                    theme: 'grid',
                    margin: { left: leftMargin, right: rightMargin },
                    tableWidth: rectWidth,
                    styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                    headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                    alternateRowStyles: { fillColor: [245, 245, 245] },
                    columnStyles,
                    didParseCell: (data) => {
                        if (data.row.index === obligationRows.length - 1) {
                            data.cell.styles.fillColor = [200, 200, 200];
                            data.cell.styles.fontStyle = 'bold';
                        }
                        if (data.section === 'body' && (data.cell.text?.join('') || '').length > 250) {
                            data.cell.styles.fontSize = 8.5;
                            data.cell.styles.valign = 'top';
                            if (data.column.index === 12 || data.column.index === 0) {
                                data.cell.styles.halign = 'left';
                            }
                        }
                    }
                });
                yPos = doc.lastAutoTable.finalY + 10;
            }

            console.log('allSanctions-->', this.allSanctions.length);
            if (section.name === 'Sanction Conditions' && this.allSanctions?.length) {
                const leftMargin = 15, rightMargin = 15;
                const sectionHeaderHeight = 8;
                const verticalPadding = 2;
                const rectWidth = doc.internal.pageSize.getWidth() - leftMargin - rightMargin;
                const colWidths = [10, 55, 22, 25, 25, 20];
                const sumCol = colWidths.reduce((a, b) => a + b, 0);
                const remainder = Math.max(0, rectWidth - sumCol);
                colWidths[1] += remainder;
                const columnStyles = {};
                colWidths.forEach((w, i) => { columnStyles[i] = { cellWidth: w }; });
                columnStyles[0].halign = 'center';
                columnStyles[1].halign = 'left';
                columnStyles[2].halign = 'center';
                columnStyles[3].halign = 'left';
                columnStyles[4].halign = 'left';
                columnStyles[5].halign = 'left';
                doc.setFillColor(200, 200, 200);
                doc.rect(leftMargin, yPos, rectWidth, sectionHeaderHeight, 'F');
                doc.setFontSize(12);
                doc.setTextColor(0);
                doc.setFont('helvetica', 'bold');
                const title = 'Sanction Condition';
                const titleWidth = doc.getTextWidth(title);
                doc.text(
                    title,
                    leftMargin + rectWidth / 2 - titleWidth / 2,
                    yPos + verticalPadding + (sectionHeaderHeight - 2 * verticalPadding) / 2 + 1
                );
                yPos += sectionHeaderHeight;
                const sanctionHeaders = [
                    'Sr No.', 'Sanction Condition', 'Status', 'Document Type', 'Fulfilment Document(s)', 'Documents View/Delete'
                ];
                const toWrapped = (value, widthMm) => doc.splitTextToSize((value ?? '--').toString(), widthMm);
                const sanctionRows = (this.allSanctions || []).map((record, index) => {
                    const srNo = (record.srno ?? (index + 1)).toString();
                    const condition = record.name || '--';
                    const status = record.Verification || '--';
                    const docType = record.documentType || '--';
                    const fulfilmentList = Array.isArray(record.sanctionChecklist) && record.sanctionChecklist.length
                        ? record.sanctionChecklist.map(c => `${c.srno}. ${c.name}`).join('\n')
                        : '--';
                    const viewDeleteList = Array.isArray(record.sanctionChecklist) && record.sanctionChecklist.length
                        ? record.sanctionChecklist.map(c => (c.ddw?.docName || '--')).join('\n')
                        : '--';
                    return [ srNo, toWrapped(condition), status, docType, fulfilmentList, toWrapped(viewDeleteList, colWidths[5]) ];
                });
                doc.autoTable({
                    startY: yPos,
                    head: [sanctionHeaders],
                    body: sanctionRows,
                    theme: 'grid',
                    margin: { left: leftMargin, right: rightMargin },
                    tableWidth: rectWidth,
                    styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                    headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                    alternateRowStyles: { fillColor: [245, 245, 245] },
                    columnStyles,
                    didParseCell: (data) => {
                        if (data.section === 'body' && (data.cell.text?.join('').length || 0) > 250) {
                            data.cell.styles.fontSize = 8.5;
                        }
                    }
                });
                yPos = doc.lastAutoTable.finalY + 10;
            }

            if (section.name === 'Eligibility' && this.products?.length) {
                const sectionHeaderHeight = 8;
                const verticalPadding = 2;
                const rectWidth = doc.internal.pageSize.getWidth() - 30;
                doc.setFillColor(200, 200, 200);
                doc.rect(15, yPos, rectWidth, sectionHeaderHeight, 'F');
                const textWidth = doc.getTextWidth('Eligibility');
                doc.setFontSize(12);
                doc.setTextColor(0);
                doc.setFont('helvetica', 'bold');
                doc.text(
                    'Eligibility',
                    15 + rectWidth / 2 - textWidth / 2,
                    yPos + verticalPadding + (sectionHeaderHeight - 2 * verticalPadding) / 2 + 1
                );
                yPos += sectionHeaderHeight;
                const prodHeaders = [
                    'Product', 'Sub Product', 'Recommended Loan Amount', 'Recommended Tenure', 'Recommended ROI (%)', 'EMI Amount',
                    'Monthly Obligation', 'Monthly Income', 'Exposure', 'Valuation', 'Total Cost of Property', 'FOIR (%)', 'Combined FOIR (%)',
                    'LTV (%)', 'Combined LTV (%)'
                ];
                const prodRows = this.products.map((record, index) => [
                    record.prodName || '--',
                    record.subProdName || '--',
                    record.sanctionedLoanAmount || '--',
                    record.sanctionedTenor || '--',
                    record.sanctionedROI || '--',
                    record.emiAmount || '--',
                    record.monthlyObligation || '--',
                    record.monthlyGrossIncome || '--',
                    record.exposure || '--',
                    record.valuation || '--',
                    record.costOfProperty || '--',
                    record.foir || '--',
                    record.cFoir || '--',
                    record.ltv || '--',
                    record.cLtv || '--'
                ]);
                doc.autoTable({
                    startY: yPos,
                    head: [prodHeaders],
                    body: prodRows,
                    theme: 'grid',
                    styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                    headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                    alternateRowStyles: { fillColor: [245, 245, 245] },
                    columnStyles: prodHeaders.reduce((acc, h, i) => { acc[i] = { cellWidth: 'wrap' }; return acc; }, {})
                });
                yPos = doc.lastAutoTable.finalY + 10;
            }

            if (!section.sourcingDetails && section.value?.length && section.name !== 'Obligation Details' && section.name !== 'Sanction Conditions' && section.name !== 'Eligibility'
                && section.name != 'FCU' && section.name != 'Technical Evaluation' && section.name != 'Property Details' && section.name!= 'Integration Details' && section.name!= 'Product Details'
                && section.name!= 'Approval'  && section.name!= 'Covenant' && section.name!= 'Income Assessment Details') {
                const tableMargin = { left: 15, right: 15 };
                const sectionHeaderHeight = 8;
                const rectWidth = doc.internal.pageSize.getWidth() - tableMargin.left - tableMargin.right;
                doc.setFillColor(200, 200, 200);
                doc.rect(tableMargin.left, yPos, rectWidth, sectionHeaderHeight, 'F');
                const verticalPadding = 2;
                doc.setTextColor(0);
                doc.setFontSize(12);
                doc.setFont('helvetica', 'bold');
                const headerText = section?.name ?? '--';
                const textWidth = doc.getTextWidth(headerText);
                doc.text(
                    headerText,
                    tableMargin.left + rectWidth / 2 - textWidth / 2,
                    yPos + verticalPadding + (sectionHeaderHeight - 2 * verticalPadding) / 2 + 1
                );
                yPos += sectionHeaderHeight;
                const fields = Array.isArray(section?.value) ? section.value : [];
                const tableHeaders = fields.length
                    ? fields.map(f => f?.Field_Label__c || '--')
                    : ['--'];
                const getRowCount = () => {
                    if (!fields.length) return 1;
                    const lens = fields.map(f => Array.isArray(f?.value) ? f.value.length : (f?.value != null ? 1 : 1));
                    return Math.max(...lens, 1);
                };
                const maxRows = getRowCount();
                const tableRows = [];
                for (let r = 0; r < maxRows; r++) {
                    const row = tableHeaders.map((_, cIdx) => {
                        const f = fields[cIdx];
                        if (!f) return '--';
                        const vArr = Array.isArray(f.value) ? f.value : [f.value];
                        const v = vArr[r] ?? vArr[0] ?? '--';
                        return (v == null || v === '') ? '--' : v;
                    });
                    tableRows.push(row);
                }
                const evenColWidth = rectWidth / tableHeaders.length;
                const columnStylesFixed = tableHeaders.reduce((acc, _, i) => {
                    acc[i] = { cellWidth: evenColWidth };
                    return acc;
                }, {});
                const applyAlignments = (styles) => {
                    tableHeaders.forEach((h, i) => {
                        const label = (h || '').toLowerCase();
                        const lefty = ['remarks', 'description', 'address', 'name', 'comments'];
                        if (lefty.some(k => label.includes(k))) {
                            styles[i].halign = 'left';
                        } else {
                            styles[i].halign = styles[i].halign || 'center';
                        }
                    });
                    return styles;
                };
                let columnStyles = applyAlignments(columnStylesFixed);
                const splitIfUnbroken = (text, width) => {
                    const s = (text ?? '--').toString();
                    if (s.length > 25 && !/\s/.test(s)) {
                        return doc.splitTextToSize(s, width);
                    }
                    return s;
                }
                tableRows.forEach(row => {
                    row.forEach((cell, i) => {
                        const w = columnStyles[i]?.cellWidth || evenColWidth;
                        row[i] = splitIfUnbroken(cell, w);
                    });
                });
                doc.autoTable({
                    startY: yPos,
                    head: [tableHeaders],
                    body: tableRows,
                    theme: 'grid',
                    margin: tableMargin,
                    tableWidth: rectWidth,
                    styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                    headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                    alternateRowStyles: { fillColor: [245, 245, 245] },
                    columnStyles,
                    didParseCell: (data) => {
                        if (data.section === 'head') {
                            const txt = (data.cell.text || []).join(' ');
                            if (txt.length > 28) data.cell.styles.fontSize = 8.5;
                        }
                        if (data.section === 'body') {
                            const txtLen = (data.cell.text || []).join('').length;
                            if (txtLen > 300) {
                                data.cell.styles.fontSize = 8.5;
                                data.cell.styles.valign = 'top';
                            }
                        }
                    },
                    rowPageBreak: 'auto',
                });
                yPos = doc.lastAutoTable.finalY + 10;
            }

        });

        if (this.approvalData) {
            const sectionHeaderHeight = 8;
            const verticalPadding = 2;
            const rectWidth = doc.internal.pageSize.getWidth() - 30;
            doc.setFillColor(200, 200, 200);
            doc.rect(15, yPos, rectWidth, sectionHeaderHeight, 'F');
            const textWidth = doc.getTextWidth('Approval Status');
            doc.setFontSize(12);
            doc.setTextColor(0);
            doc.text(
                'Approval Status',
                15 + rectWidth / 2 - textWidth / 2,
                yPos + verticalPadding + (sectionHeaderHeight - 2 * verticalPadding) / 2 + 1
            );
            yPos += sectionHeaderHeight;
            const approvalHeaders = ['Current Approval Status', 'Approving Authority', 'Current Approver'];
            console.log(' this.approvalData>>>'+ JSON.stringify(this.approvalData));
            const approvalRows = [[
                this.approvalData.currentStatus || '--',
                this.approvalData.finalAuthority || '--',
                this.approvalData.currentApprover || '--'
            ]];
            console.log('approvalRows>>>'+approvalRows);
            doc.autoTable({
                startY: yPos,
                head: [approvalHeaders],
                body: approvalRows,
                theme: 'grid',
                styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                alternateRowStyles: { fillColor: [245, 245, 245] },
                columnStyles: approvalHeaders.reduce((acc, h, i) => { acc[i] = { cellWidth: 'wrap' }; return acc; }, {})
            });
            yPos = doc.lastAutoTable.finalY + 10;

            console.log('recoNoteDetails>>>',this.recoNoteDetails)
            //Approval reco notes
            if(this.isHLRelated){
                if(this.recoNoteDetails){
                    for(var i=0; i< this.recoNoteDetails.length; i++){
                        var salaryData = this.recoNoteDetails[i];
                        var salRows = [];
                        for(var j=0; j< salaryData.statusHistory.length; j++){
                            var historyRow = salaryData.statusHistory[j];
                            var row = [];
                            row.push({ content: 'Timestamp', styles: { fontStyle: 'bold', halign: 'left' } });
                            row.push({ content: historyRow.timeStamp, styles: { halign: 'left' } });
                            row.push({ content: 'User', styles: { fontStyle: 'bold', halign: 'left' } });
                            row.push({ content: historyRow.user, styles: { halign: 'left' } });
                            salRows.push(row);
                            row = [];
                            row.push({ content: 'Status', styles: { fontStyle: 'bold', halign: 'left' } });
                            row.push({ content: historyRow.status, styles: { halign: 'left' } });
                            row.push({ content: 'Type', styles: { fontStyle: 'bold', halign: 'left' } });
                            row.push({ content: historyRow.approvalType, styles: { halign: 'left' } });
                            salRows.push(row);
                            row = [];
                            row.push({ content: 'Remarks', styles: { fontStyle: 'bold', halign: 'left' } });
                            row.push({ content: historyRow.remarks, colSpan: 3, styles: { halign: 'left' } });
                            salRows.push(row);
                            row = [];
                            row.push({ content: '', colSpan: 4 });
                            salRows.push(row);
                        }
                        const earningHeaders = [[{ content: salaryData.productName, colSpan: 4, styles: { halign: 'center', fillColor: [22, 160, 133] } }]];
                        const earningRows = salRows;
                        doc.autoTable({
                            startY: yPos,
                            head: earningHeaders,
                            body: earningRows,
                            theme: 'grid',
                            styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                            headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                            alternateRowStyles: { fillColor: [245, 245, 245] }
                        });
                        yPos = doc.lastAutoTable.finalY +10;
                    }
                }
            }else{
                //Approval History table (NON-HL loans only)
                if(this.approvalData.statusHistory && this.approvalData.statusHistory.length > 0){
                    const leftMargin = 15;
                    const rightMargin = 15;
                    const histHeaderHeight = 8;
                    const histVerticalPadding = 2;
                    const histRectWidth = doc.internal.pageSize.getWidth() - leftMargin - rightMargin;
                    doc.setFillColor(200, 200, 200);
                    doc.rect(leftMargin, yPos, histRectWidth, histHeaderHeight, 'F');
                    doc.setFont('helvetica', 'bold');
                    doc.setFontSize(12);
                    doc.setTextColor(0);
                    const histTitle = 'Approval History';
                    const histTitleWidth = doc.getTextWidth(histTitle);
                    doc.text(
                        histTitle,
                        leftMargin + histRectWidth / 2 - histTitleWidth / 2,
                        yPos + histVerticalPadding + (histHeaderHeight - 2 * histVerticalPadding) / 2 + 1
                    );
                    yPos += histHeaderHeight;
                    const historyHeaders = [
                        'Sr. No.', 'Date & Time', 'Approver / Requestor', 'Approval Status', 'Remarks'
                    ];
                    let histColWidths = [14, 34, 34, 30, 55];
                    const scaleHistWidths = (widths, target) => {
                        const sum = widths.reduce((a, b) => a + b, 0);
                        if (sum <= 0) return widths.map(() => target / widths.length);
                        const scaled = widths.map(w => (w / sum) * target);
                        const total = scaled.reduce((a, b) => a + b, 0);
                        const diff = target - total;
                        if (Math.abs(diff) > 0.001) scaled[4] += diff;
                        return scaled;
                    };
                    histColWidths = scaleHistWidths(histColWidths, histRectWidth);
                    const histColumnStyles = {};
                    histColWidths.forEach((w, i) => { histColumnStyles[i] = { cellWidth: w }; });
                    histColumnStyles[0].halign = 'center';
                    histColumnStyles[1].halign = 'center';
                    histColumnStyles[2].halign = 'left';
                    histColumnStyles[3].halign = 'center';
                    histColumnStyles[4].halign = 'left';
                    const formatTimeStamp = (ts) => {
                        if (!ts) return '--';
                        try {
                            const d = new Date(ts);
                            if (isNaN(d.getTime())) return ts;
                            const dd = String(d.getDate()).padStart(2, '0');
                            const mm = String(d.getMonth() + 1).padStart(2, '0');
                            const yyyy = d.getFullYear();
                            const hh = String(d.getHours()).padStart(2, '0');
                            const min = String(d.getMinutes()).padStart(2, '0');
                            return `${dd}/${mm}/${yyyy} ${hh}:${min}`;
                        } catch (e) {
                            return ts;
                        }
                    };
                    const historyRows = this.approvalData.statusHistory.map((record, index) => {
                        let remarks = (record.remarks || '--').toString().trim();
                        remarks = remarks.replace(/\n{2,}/g, '\n');
                        return [
                            String(index + 1),
                            formatTimeStamp(record.timeStamp),
                            record.requestor || '--',
                            record.status || '--',
                            remarks
                        ];
                    });
                    doc.autoTable({
                        startY: yPos,
                        head: [historyHeaders],
                        body: historyRows,
                        theme: 'grid',
                        margin: { left: leftMargin, right: rightMargin },
                        tableWidth: histRectWidth,
                        styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                        headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                        alternateRowStyles: { fillColor: [245, 245, 245] },
                        columnStyles: histColumnStyles,
                        didParseCell: (data) => {
                            if (data.section === 'body' && data.column.index === 4) {
                                const len = (data.cell.text || []).join(' ').length;
                                if (len > 200) {
                                    data.cell.styles.fontSize = 8.5;
                                    data.cell.styles.valign = 'top';
                                }
                            }
                        },
                        rowPageBreak: 'auto'
                    });
                    yPos = doc.lastAutoTable.finalY + 10;
                }

                //Eligibility table (NON-HL loans only)
                if(this.products && this.products.length > 0){
                    const eligLeftMargin = 15;
                    const eligRightMargin = 15;
                    const eligHeaderHeight = 8;
                    const eligVerticalPadding = 2;
                    const eligRectWidth = doc.internal.pageSize.getWidth() - eligLeftMargin - eligRightMargin;
                    doc.setFillColor(200, 200, 200);
                    doc.rect(eligLeftMargin, yPos, eligRectWidth, eligHeaderHeight, 'F');
                    doc.setFont('helvetica', 'bold');
                    doc.setFontSize(12);
                    doc.setTextColor(0);
                    const eligTitle = 'Eligibility';
                    const eligTitleWidth = doc.getTextWidth(eligTitle);
                    doc.text(
                        eligTitle,
                        eligLeftMargin + eligRectWidth / 2 - eligTitleWidth / 2,
                        yPos + eligVerticalPadding + (eligHeaderHeight - 2 * eligVerticalPadding) / 2 + 1
                    );
                    yPos += eligHeaderHeight;
                    const prodHeaders = [
                        'Product', 'Sub Product', 'Recommended Loan Amount', 'Recommended Tenure', 'Recommended ROI (%)', 'EMI Amount',
                        'Monthly Obligation', 'Monthly Income', 'Exposure', 'Valuation', 'Total Cost of Property', 'FOIR (%)', 'Combined FOIR (%)',
                        'LTV (%)', 'Combined LTV (%)'
                    ];
                    const prodRows = this.products.map((record) => [
                        record.prodName || '--',
                        record.subProdName || '--',
                        record.sanctionedLoanAmount || '--',
                        record.sanctionedTenor || '--',
                        record.sanctionedROI || '--',
                        record.emiAmount || '--',
                        record.monthlyObligation || '--',
                        record.monthlyGrossIncome || '--',
                        record.exposure || '--',
                        record.valuation || '--',
                        record.costOfProperty || '--',
                        record.foir || '--',
                        record.cFoir || '--',
                        record.ltv || '--',
                        record.cLtv || '--'
                    ]);
                    doc.autoTable({
                        startY: yPos,
                        head: [prodHeaders],
                        body: prodRows,
                        theme: 'grid',
                        margin: { left: eligLeftMargin, right: eligRightMargin },
                        styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                        headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                        alternateRowStyles: { fillColor: [245, 245, 245] },
                        columnStyles: prodHeaders.reduce((acc, h, i) => { acc[i] = { cellWidth: 'wrap' }; return acc; }, {})
                    });
                    yPos = doc.lastAutoTable.finalY + 10;
                }

                
                if(this.productTableRecs.length > 0 ){
                const sectionHeaderHeight = 8;
                const verticalPadding = 2;
                const rectWidth = doc.internal.pageSize.getWidth() - 30;
                doc.setFillColor(200, 200, 200);
                doc.rect(15, yPos, rectWidth, sectionHeaderHeight, 'F');
                doc.setFont('helvetica', 'bold');
                doc.setFontSize(12);
                doc.setTextColor(0);
                const textWidth = doc.getTextWidth('Product Details');
                doc.text(
                    'Product Details',
                    15 + rectWidth / 2 - textWidth / 2,
                    yPos + verticalPadding + (sectionHeaderHeight - 2 * verticalPadding) / 2 + 1
                );
                yPos += sectionHeaderHeight;
                const obligationHeaders = [
                    'Product Name','Sub Product','Loan Purpose',
                    'Repayment Variant','Sub Variant',
                    'Interest Only Tenure','Loan Facility','Scheme Name',
                    'Requested Loan Amount','Requested ROI(%)',
                    'Primary/Secondary','Full EMI Tenure','Total Tenure'
                ];
                const obligationRows = this.productTableRecs.map(record => [
                    record.prodName || '--',
                    record.subProdName || '--',
                    record.loanPurpose || '--',
                    record.variant || '--',
                    record.subvariantName || '--',
                    record.hybridTenureName || '--',
                    record.loanFacility || '--',
                    record.schemeProdName || '--',
                    record.loanAmoutReq || '--',
                    record.requestedROI || '--',
                    record.prodType || '--',
                    record.fullEMI || '--',
                    record.totalTenure|| '--'
                ]);
                doc.autoTable({
                    startY: yPos,
                    head: [obligationHeaders],
                    body: obligationRows,
                    theme: 'grid',
                    styles: { fontSize: 9, halign: 'center', valign: 'middle', overflow: 'linebreak', cellPadding: 2 },
                    headStyles: { fillColor: [91, 182, 227], fontStyle: 'bold', textColor: [0, 0, 0] },
                    alternateRowStyles: { fillColor: [245, 245, 245] },
                    columnStyles: obligationHeaders.reduce((acc, h, i) => { acc[i] = { cellWidth: 'wrap' }; return acc; }, {}),
                });
                yPos = doc.lastAutoTable.finalY + 10;
            }
            }
        }

        const pageCount = doc.getNumberOfPages();
        for (let i = 1; i <= pageCount; i++) {
            doc.setPage(i);
            doc.setFontSize(8);
            doc.text(
                `Page ${i} of ${pageCount}`,
                doc.internal.pageSize.getWidth() - 20,
                doc.internal.pageSize.getHeight() - 10,
                { align: 'right' }
            );
        }
        console.log('pdf create');
        doc.save('ApplicationSummary.pdf');
        const pdfBase64 = btoa(doc.output());
        this.uploadToSalesforce(pdfBase64);
        this.spinner = false;
    }

    uploadToSalesforce(base64Data) {
        uploadPDF({ base64Data: base64Data, loanId: this.recordId })
            .then(() => {
                console.log('PDF uploaded successfully');
            })
            .catch(error => {
                console.error('Error uploading PDF', error);
            });
    }

}