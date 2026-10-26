import { LightningElement, api, track} from 'lwc';
import LightningConfirm from 'lightning/confirm';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import calculateGST from '@salesforce/apex/AHL_CalculateGstController.initiateAPIRequest';
import calculateUpfronFee from '@salesforce/apex/upfrontFeeController.initiateAPIRequest';
import getUpfrontFeeRecords from '@salesforce/apex/upfrontFeeController.getUpfrontFeeRecords';


export default class UpfrontFeeCollectionCmp extends NavigationMixin(LightningElement) {
    subReceiptModeOptions = [
    { label: 'IMPS', value: 'IMPS' },
    { label: 'NEFT', value: 'NEFT' },
    { label: 'RTGS', value: 'RTGS' },
    { label: 'WALLET', value: 'WALLET' },
    { label: 'ESCROW', value: 'ESCROW' },
    { label: 'UPI', value: 'UPI' },
    { label: 'GATEWAY', value: 'GATEWAY' }
    ];
    @api recordId;
    _losRows =[];
    @track upfrontFeeTable =[];
    @api
    get losRows() {
        return this._losRows;
    }
    
    set losRows(value) {
        this._losRows = Array.isArray(value) ? value : [];

        this.displayRows = this._losRows.filter(r => {
            return r.productType.trim().toLowerCase() === 'parent';
        }).map((r, idx) => {         
            return {
                id: r.id,
                productName: r.productName,
                productId: r.productId,
                name: r.name,
                productType: r.productType,
                finalAmount: r.finalAmount,
                tobeCollectedExTax: r.tobeCollectedExTax ?? null,
                gstAmount: r.gstAmount ?? 0,
                tobeCollectedInTax: r.tobeCollectedInTax ?? 0,
                calcLoading: false,
                lastCalculatedExTax: r.lastCalculatedExTax ?? null
            };
        });
    }
    nextId = 0;
    
    @track displayRows = [];
    @track upfrontRows = []; 

    
    updateRow(id, patch) {
        this.displayRows = this.displayRows.map(r => (r.id === id ? { ...r, ...patch } : r));
    }


    connectedCallback() {
        this.getUpfrontFee();
        //this.addRow(); Arman : cant put a getter setter here from parent.. also,  need to get the default amount in the first row so no able to do that in conn callback 
    }

    getUpfrontFee(){
        getUpfrontFeeRecords({loanApplicationId : this.recordId})
        .then((records) => {
            this.upfrontRows = (records || []).map((rec, idx) => ({
                id: String(this.nextId++),
                item: idx + 1,
                actualFee: rec.Final_Amount_INR__c ?? null,
                subReceiptMode: rec.Sub_Receipt_Mode__c || '',
                receiptNo: rec.Receipt_No__c || '',
                transactionRef: rec.Transaction_Reference__c || '',
                remarks: rec.Remarks__c || '',
                status: 'Success',
                isdisabled: true,
                files: []
            }));

        })
        .catch(error => {
            console.log('error in getUpfront',error);
        })
    }
    
    get feeLines() {
        return this.displayRows.map(r => ({
            id: r.id,
            productName: r.productName,
            chargeType: r.name,
            finalAmount: r.finalAmount,
            amountExcludingTax: Number(r.tobeCollectedExTax || 0),
            gstAmount: Number(r.gstAmount || 0),
            totalIncludingTax: Number(r.tobeCollectedInTax || 0)
        }));
    }

    buildUpfrontObj(receiptRow) {
        const processing = this.processingFeeInclTax;
        const stamping = this.stampingFrankingInclTax;
        const final = Number((processing + stamping).toFixed(2));
        const gstTotal = this.totalGstSum;
        const exclTotal = this.totalExcludingTaxSum;
        const inclTotal = this.totalIncludingTaxSum; // Armann : this should be same as final but let see .. we'll check basis User reactions on this 

        const primaryLos = this.displayRows[0]; //need to check this basis the productt.. will check for the variable in parent which fetches the product__r.product type 
        const upfrontObj = {
            Loan_Application__c: this.recordId,
            Product__c: primaryLos?.productId,
            Charge_Type__c: 'Upfront Fee',
            Processing_Fee_Inc_Tax_Upfront__c: processing,
            Stamp_Fee_Inc_Tax_Upfront__c: stamping,
            Final_Amount_INR__c: final,
            Sub_Receipt_Mode__c: receiptRow.subReceiptMode || '',
            Receipt_No__c: receiptRow.receiptNo || '',
            Transaction_Reference__c: receiptRow.transactionRef || '',
            Remarks__c: receiptRow.remarks || ''
        };
        return upfrontObj;
    }

    get processingFeeInclTax() {
        return Number(
            (this.displayRows || [])
                .filter(r => (r.name || '').trim().toLowerCase() === 'processing fee')
                .reduce((sum, r) => sum + Number(r.tobeCollectedInTax || 0), 0)
                .toFixed(2)
        );
    }

    get stampingFrankingInclTax() {
        const target = 'stamping_franking charges';
        return Number(
            (this.displayRows || [])
            .filter(r => {
                const n = (r.name || '').trim().toLowerCase();
                return target.includes(n);
            })
            .reduce((sum, r) => sum + Number(r.tobeCollectedInTax || 0), 0)
            .toFixed(2)
        );
    }
    
    clearUpperTable() {
        this.displayRows = (this.displayRows || []).map(r => ({
            ...r,
            tobeCollectedInTax: 0,
            tobeCollectedExTax: 0,
            gstAmount: 0,
            calcLoading: false,
            lastCalculatedInTax: null,
            lastCalculatedExTax: null
        }));
    }


    async handleAmountBlur(event) {
        const id = event.target.dataset.id;
        const rawValue = event.target.value;
        const amount = Number(rawValue);

        if (isNaN(amount) || amount < 0) {
            this.showToast('Validation', 'Please enter a valid non-negative amount.', 'warning');
            return;
        }
        
        const row = this.displayRows.find(r => r.id === id);
        if (!row) {
            console.error('Row not found for id:', id);
            return;
        }
        
        if (amount > Number(row.finalAmount)) {
            this.updateRow(id, {
                tobeCollectedInTax: 0, //making it zeroo
                calcLoading: false
            });
            this.showToast('Error', 'The entered amount cannot be greater than the Remaining Amount.', 'error');
            return;
        }


        if (row.lastCalculatedInTax === amount) { // this was done to stop extra GST HIT >> just chekcs if amount is same and skips the api part
            const totalExclusive = Number((amount - Number(row.gstAmount || 0.00)).toFixed(2));
            this.updateRow(id, { tobeCollectedInTax: amount, tobeCollectedExTax: totalExclusive });
            return;
        }    

        console.log('rowNamee',row.name);
         this.updateRow(id, { tobeCollectedInTax: amount, calcLoading: true });
        if(row.name =='Processing Fee'){
            if(amount == 0){
                this.updateRow(id, { tobeCollectedInTax: 0,gstAmount:0, tobeCollectedExTax: 0, lastCalculatedExTax: 0, calcLoading: false });
                return;
            }
            const inputMap = {
                loanId: this.recordId,
                processName: 'CalculateGST',
                productName: row.Product__c,
                feeType: row.name,
                gstAmountForApi: amount,
                isWaiverAmountCalc: 'false'
            };
            
            try {
                const result = await calculateGST({ inputMap });
                if (result && typeof result === 'string' && result.includes('Success:')) {  // Armann : Expecting "Success:<amount>"
                    const gstStr = result.split(':')[1];
                    const gstNum = Number(gstStr);
                    if (isNaN(gstNum)) {
                        throw new Error('GST parse error: ' + gstStr);
                    }
                    const gstRounded = Number(gstNum.toFixed(2)); //so basically to Fixedd moves the vlaue to two decimals in string form and Number converts it to Decimal form :: GPT ne sikhaya yejh
                    const totalExclusive = Number((amount - gstRounded).toFixed(2));

                    this.updateRow(id, {
                        gstAmount: gstRounded,
                        tobeCollectedInTax: amount,
                        tobeCollectedExTax: totalExclusive,
                        calcLoading: false,
                        lastCalculatedExTax: totalExclusive 
                    });

                    this.showToast('Success', 'GST calculation completed.', 'success'); 
                } else {
                    // Handle non-success scenarios gracefully
                    this.updateRow(id, { calcLoading: false });
                    this.showToast('Error', 'GST API returned an unexpected response.', 'error');
                    console.error('GST API response:', result);
                }
            } catch (err) {
                this.updateRow(id, { calcLoading: false });
                this.showToast('Error', (err?.body?.message || err?.message || JSON.stringify(err)) || 'GST calculation failed.', 'error');
                console.error('GST API error:', err);
            }
        }
        else{
            this.updateRow(id, {
                gstAmount: 0,
                tobeCollectedInTax: amount,
                tobeCollectedExTax:amount,
                calcLoading: false,
                lastCalculatedExTax: amount,
                lastCalculatedInTax: amount
            });
        }
        this.syncPendingWithTotal();
        console.log('Finalrow>>',JSON.stringify(row));
    }
    handleAddRow() {
        const idx = this.getLatestPendingIndex();
        if (idx >= 0) {
            const total = Number((this.totalIncludingTaxSum || 0).toFixed(2));
            this.upfrontRows = this.upfrontRows.map((r, i) =>
                i === idx ? { ...r, actualFee: total } : r
            );
            this.showToast('Info', 'You cannot add another row while one remains pending.', 'info');
            return;
        }
        this.addRow();
    }

    addRow() {
        const total = Number((this.totalIncludingTaxSum || 0).toFixed(2));
        const latestPendingIndex = this.getLatestPendingIndex();
        if (latestPendingIndex >= 0) {
            this.upfrontRows = this.upfrontRows.map((r, i) =>
                i === latestPendingIndex ? { ...r, actualFee: total } : r
            );
            return;
        }
        const id = String(this.nextId++);
        const newRow = {
            id,
            item: this.upfrontRows.length + 1,
            actualFee: total,
            subReceiptMode: '',
            receiptNo: '',
            transactionRef: '',
            remarks: '',
            status: 'Pending',
            isdisabled: false,
            files: []
        };
        this.upfrontRows = [...this.upfrontRows, newRow];
    }

    /*handleAddRow(){
        this.addRow();
    }

    addRow() {
        if (this.upfrontRows.length > 0) {
            const lastRow = this.upfrontRows[this.upfrontRows.length - 1];
            if (lastRow.status !== 'Success') {
                this.showToast(
                    'Action blocked',
                    'The first transaction should be done successfully before adding a new row.',
                    'error'
                );
                return;
            }
            //this.clearUpperTable(); commenting this as it was clearing the entered data when we were adding row after calculator data enteringg
        }

        const id = String(this.nextId++);
        console.log('length',this.upfrontRows.length)
            const row = {
            id,
            item: this.upfrontRows.length + 1,
            actualFee: this.upfrontRows.length ==0 ? this.totalIncludingTaxSum :null,
            subReceiptMode: '',
            receiptNo: '',
            transactionRef: '',
            remarks: '',
            status: 'Pending',
            isdisabled : false,
            files:[]
        };
        this.upfrontRows = [...this.upfrontRows, row];
    }*/

    
    get totalIncludingTaxSum() {
        return Number(
            (this.displayRows || [])
                .reduce((sum, r) => sum + Number(r.tobeCollectedInTax || 0), 0)
                .toFixed(2)
        );
    }
    
    get totalExcludingTaxSum() {
        return Number(
            (this.displayRows || [])
                .reduce((sum, r) => sum + Number(r.tobeCollectedExTax || 0), 0)
                .toFixed(2)
        );
    }

    get totalGstSum() {
        return Number(
            (this.displayRows || [])
                .reduce((sum, r) => sum + Number(r.gstAmount || 0), 0)
                .toFixed(2)
        );
    }


    
    resequenceItems() {
        this.upfrontRows = this.upfrontRows.map((r, idx) => ({ ...r, item: idx + 1 }));
    }

    handleCellChange(event) {
        const id = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.detail?.value ?? event.target.value;
        this.upfrontRows = this.upfrontRows.map(r => (r.id === id ? { ...r, [field]: value } : r));
    }
    
    async handleInitiateApi(event) {
        const id = event.target.dataset.id;
        let currentobj;

        this.upfrontRows = this.upfrontRows.map(r => {
            if (r.id === id) {
                currentobj = r;
                return { ...r, isdisabled: true, status: 'Initiated' };
            }
            return r;
        });

        try {
            const upfrontFeeObj = this.buildUpfrontObj(currentobj);
            console.log('upfrontFeeObj>>',upfrontFeeObj);
            const inputMap = {
                loanId: this.recordId,
                processName: 'Upfront fee',
                upfrontFeeObj: JSON.stringify(upfrontFeeObj)
            };
            if(this.totalIncludingTaxSum ==0){
                this.showToast('Error', 'Enter some amount in the calculator first.', 'error');
                this.upfrontRows = this.upfrontRows.map(r =>
                    r.id === id ? { ...r, isdisabled: false, status: 'Pending' } : r
                );
                return;
            }

            const result = await calculateUpfronFee({ inputMap });
            console.log('Upfront API result:', result);

            if (result && typeof result === 'string' && result.includes('Success')) {
                this.upfrontRows = this.upfrontRows.map(r =>
                    r.id === id ? { ...r, status: 'Success' } : r
                );
                this.showToast('Success', 'Upfront fee recorded successfully.', 'success');
               // this.addRow(); commentinh this as user will create row herself
                const refreshEvent = new CustomEvent('chargesrefresh', {
                    detail: { isRefresh: true }
                });
                this.dispatchEvent(refreshEvent);
            } else {
                this.showToast('Error',result, 'error');
                throw new Error(result || 'Unexpected response from API');
            }
        } catch (err) {
            console.error('Upfront API error:', err);
            this.upfrontRows = this.upfrontRows.map(r =>
                r.id === id ? { ...r, isdisabled: false, status: 'Pending' } : r
            );
            this.showToast('Error', (err?.body?.message || err?.message || 'API call failed'), 'error');
        }
    }

    
    handleUploadFinished(event) {
        console.log('event.target.dataset.recordId ',event.target.dataset.recordId);
        const rowIndex = parseInt(event.target.dataset.recordId, 10);
         console.log('rowIndex ',rowIndex);
         console.log('this.upfrontRows.length ',this.upfrontRows.length);
         console.log('rowIndex ',isNaN(rowIndex));
        if (isNaN(rowIndex) || rowIndex < 0 || rowIndex >= this.upfrontRows.length) {
            console.error('Invalid step index:', rowIndex);
            this.showToast('Error', 'Invalid step index for file upload.', 'error');
            return;
        }

        const uploadedFiles = event.detail.files;
        const itrRow = this.upfrontRows[rowIndex];

        if (!itrRow.files) {
            itrRow.files = [];
        }

        uploadedFiles.forEach(file => { //variables to array
            itrRow.files.push({
                fileName: file.name,
                contentDocId: file.documentId,
                contentDocLink: `/lightning/r/ContentDocument/${file.documentId}/view`
            });
        });

        //itrRow.files.push(...uploadedFiles); //array to array
        console.log(`Files for itrRow ${rowIndex}:`, JSON.stringify(itrRow.files));
        this.showToast('Success', 'Document uploaded successfully.', 'success');
    }

    handlePreview(event) {
        const contentDocId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: contentDocId
            }
        })
    }
    
    async handleDelete(event) {
        const id = event.target.dataset.id;
        const confirmed = await LightningConfirm.open({
            message: 'Are you sure you want to delete this row?',
            theme: 'warning',
            label: 'Confirm Delete'
        });
        if (confirmed) {
            this.upfrontRows = this.upfrontRows.filter(r => r.id !== id);
            this.resequenceItems();
        }
    }

    showToast(title, message, variant = 'info') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    
    getLatestPendingIndex() {//gpt se tried fetching the latest rowww
        for (let i = this.upfrontRows.length - 1; i >= 0; i--) {
            const s = this.upfrontRows[i].status;
            if (s !== 'Success' && s !== 'Initiated') return i;
        }
        return -1;
    }
    
    syncPendingWithTotal() {
        const idx = this.getLatestPendingIndex();
        if (idx < 0) return;
        const total = Number((this.totalIncludingTaxSum || 0).toFixed(2));
        const r = this.upfrontRows[idx];
        if (Number(r.actualFee || 0) !== total) {
            this.upfrontRows = this.upfrontRows.map((row, i) =>
                i === idx ? { ...row, actualFee: total } : row
            );
        }
    }
}