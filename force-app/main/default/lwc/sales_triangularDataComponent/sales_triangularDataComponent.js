import { api, LightningElement, track } from 'lwc';
import getLoanDetailsFromReadObject from '@salesforce/apex/ScreenGenerationController.getLoanDetailsFromStorageObject';
import getScreenDetails from '@salesforce/apex/ScreenGenerationController.getScreenDetails';

export default class Sales_triangularDataComponent extends LightningElement {
    @api recordId;
    @api applicantId;
    @track groupedDocumentData = [];
    @track tableHeaders = [];
    @track allFieldDetails = [];
    @track showData = false;

    connectedCallback() {
        // this.tableHeaders = Array.from(labelSet);
        // this.headerColSpan = this.tableHeaders.length + 1;
        this.getScreenDetailsFromApex();
    }

    getScreenDetailsFromApex() {
        getScreenDetails({ formIdentifier: 'Sales Triangular Screen', loanId: this.recordId })
        .then(result => {
            if (result) {
                this.allFieldDetails = result;
                this.getLoanDetailsFromReadObject();
            }
        })
        .catch(error => {
            console.error('Error in getScreenDetails:', error);
        });
    }  
    
    // getLoanDetailsFromReadObject() {
    //     console.log('this.applicantId: ' + this.applicantId);
    //     getLoanDetailsFromReadObject({
    //         screenName: 'Sales Triangular Screen',
    //         loanId: this.recordId,
    //         formIdentifier: 'Sales Triangular Screen',
    //         recordId: this.applicantId
    //     }).then(result => {
    //         console.log('detailsWrapperList from getLoanDetailsFromReadObject: ' + JSON.stringify(result));
    //         const groupedMap = {};
    //         const labelSet = new Set();
    
    //         result.forEach(item => {
    //             const docTypeMatch = item.fieldLabel.match(/\((.*?)\s*-\s*(.*?)\)/);
    //             if (docTypeMatch && docTypeMatch.length >= 3) {
    //                 const docType = docTypeMatch[1]?.trim() || '';
    //                 const sourceType = docTypeMatch[2]?.trim() || '';
    //                 const key = `${docType}__${sourceType}`;
    
    //                 if (!groupedMap[key]) {
    //                     groupedMap[key] = {
    //                         documentType: docType,
    //                         sourceType: sourceType,
    //                         fieldMap: {}
    //                     };
    //                 }
    
    //                 if (item.fieldApiName !== 'Document_Type__c') {
    //                     const labelWithoutBrackets = item.fieldLabel.split('(')[0].trim();
    //                     if (labelWithoutBrackets !== 'Source Type') {
    //                         groupedMap[key].fieldMap[labelWithoutBrackets] = item.fieldValue;
    //                         labelSet.add(labelWithoutBrackets);
    //                     }
    //                 }
    //             }
    //         });
    
    //         const groupedByDocType = {};
    //         Object.values(groupedMap).forEach(row => {
    //             if (!groupedByDocType[row.documentType]) {
    //                 groupedByDocType[row.documentType] = {
    //                     documentType: row.documentType,
    //                     rows: []
    //                 };
    //             }
    
    //             const cells = [];
    //             labelSet.forEach(label => {
    //                 cells.push({
    //                     label,
    //                     value: row.fieldMap[label] || ''
    //                 });
    //             });
    
    //             groupedByDocType[row.documentType].rows.push({
    //                 sourceType: row.sourceType,
    //                 cells
    //             });
    //         });
    
    //         this.groupedDocumentData = Object.values(groupedByDocType);
    //         this.tableHeaders = Array.from(labelSet);
    //         this.headerColSpan = this.tableHeaders.length + 1;
    //         this.hasData = this.groupedDocumentData.length > 0;
    //     }).catch(error => {
    //         console.error('Error in getLoanDetailsFromReadObject:', error);
    //     });
    // }

    getLoanDetailsFromReadObject() {
        console.log('this.applicantId: ' + this.applicantId);
    
        getLoanDetailsFromReadObject({
            screenName: 'Sales Triangular Screen',
            loanId: this.recordId,
            formIdentifier: 'Sales Triangular Screen',
            recordId: this.applicantId
        }).then(result => {
            console.log('detailsWrapperList from getLoanDetailsFromReadObject: ' + JSON.stringify(result));
            
            const groupedMap = {};
            const labelSet = new Set();
    
            // Group fields by document type and source type
            result.forEach(item => {
                const docTypeMatch = item.fieldLabel.match(/\((.*?)\s*-\s*(.*?)\)/);
                if (docTypeMatch && docTypeMatch.length >= 3) {
                    const docType = docTypeMatch[1]?.trim() || '';
                    const sourceType = docTypeMatch[2]?.trim() || '';
                    const key = `${docType}__${sourceType}`;
    
                    if (!groupedMap[key]) {
                        groupedMap[key] = {
                            documentType: docType,
                            sourceType: sourceType,
                            fieldMap: {}
                        };
                    }
    
                    if (item.fieldApiName !== 'Document_Type__c') {
                        const labelWithoutBrackets = item.fieldLabel.split('(')[0].trim();
                        if (labelWithoutBrackets !== 'Source Type') {
                            groupedMap[key].fieldMap[labelWithoutBrackets] = item.fieldValue;
                            labelSet.add(labelWithoutBrackets);
                        }
                    }
                }
            });
    
            // Organize grouped data by document type
            const groupedByDocType = {};
            Object.values(groupedMap).forEach(row => {
                if (!groupedByDocType[row.documentType]) {
                    groupedByDocType[row.documentType] = {
                        documentType: row.documentType,
                        rows: []
                    };
                }
    
                const cells = [];
                labelSet.forEach(label => {
                    const rawValue = row.fieldMap[label];
                    const displayValue = rawValue === undefined || rawValue === null || rawValue === '' ? '-' : rawValue;
                    cells.push({
                        label,
                        value: displayValue
                    });
                });
    
                groupedByDocType[row.documentType].rows.push({
                    sourceType: row.sourceType,
                    cells
                });
            });
    
            // Final assignments for rendering
            this.groupedDocumentData = Object.values(groupedByDocType);
            this.tableHeaders = Array.from(labelSet);
            this.headerColSpan = this.tableHeaders.length + 1; // +1 for Source Type column
            this.hasData = this.groupedDocumentData.length > 0;
        }).catch(error => {
            console.error('Error in getLoanDetailsFromReadObject:', error);
        });
    }
    
    

    get hasData() {
        return this.groupedDocumentData && this.groupedDocumentData.length > 0;
    }

}