import { LightningElement, track } from 'lwc';
import getRecordAllData  from '@salesforce/apex/ShowAllDataController.getRecordAllData';
import updateFieldValue  from '@salesforce/apex/ShowAllDataController.updateFieldValue';
import analyzeFieldUsage from '@salesforce/apex/ShowAllDataController.analyzeFieldUsage';

const FILTER = { ALL: 'all', EDITABLE: 'editable', FORMULA: 'formula', BLANK: 'blank' };
const SORT   = { LABEL: 'label', API: 'api' };

export default class ShowAllData extends LightningElement {

    @track recordData     = null;
    @track _fields        = [];
    @track searchTerm     = '';
    @track activeFilter   = FILTER.ALL;
    @track sortField      = SORT.LABEL;
    @track sortAsc        = true;
    @track isLoading      = false;
    @track isSaving       = false;
    @track errorMessage   = '';
    @track inputRecordId  = '';
    @track showUsageModal = false;
    @track usageLoading   = false;
    @track usageData      = null;
    @track toast          = { visible: false, message: '', cssClass: '' };

    // ── NO connectedCallback — user always enters ID manually ──

    get totalFieldCount()  { return this._fields.length; }
    get editableCount()    { return this._fields.filter(f => f.isUpdateable && !f.isFormula).length; }
    get formulaCount()     { return this._fields.filter(f => f.isFormula).length; }
    get blankCount()       { return this._fields.filter(f => !f.hasValue).length; }
    get dirtyCount()       { return this._fields.filter(f => f.isDirty).length; }
    get isDirty()          { return this.dirtyCount > 0; }
    get isNotDirty()       { return this.dirtyCount === 0; }
    get noResults()        { return this.filteredFields.length === 0 && !this.isLoading && this.recordData; }
    get sortArrow()        { return this.sortAsc ? '↑' : '↓'; }
    get sortByLabelActive(){ return this.sortField === SORT.LABEL; }
    get sortByApiActive()  { return this.sortField === SORT.API; }
    get filterAllClass()      { return this._filterClass(FILTER.ALL); }
    get filterEditableClass() { return this._filterClass(FILTER.EDITABLE); }
    get filterFormulaClass()  { return this._filterClass(FILTER.FORMULA); }
    get filterBlankClass()    { return this._filterClass(FILTER.BLANK); }

    _filterClass(f) {
        return `sad-filter-btn ${this.activeFilter === f ? 'sad-filter-active' : ''}`;
    }

    get filteredFields() {
        let list = [...this._fields];
        if (this.activeFilter === FILTER.EDITABLE) list = list.filter(f => f.isUpdateable && !f.isFormula);
        else if (this.activeFilter === FILTER.FORMULA) list = list.filter(f => f.isFormula);
        else if (this.activeFilter === FILTER.BLANK)   list = list.filter(f => !f.hasValue);
        if (this.searchTerm.trim()) {
            const term = this.searchTerm.toLowerCase();
            list = list.filter(f =>
                f.label.toLowerCase().includes(term) ||
                f.apiName.toLowerCase().includes(term) ||
                (f.displayValue && f.displayValue.toLowerCase().includes(term))
            );
        }
        list = list.sort((a, b) => {
            const key = this.sortField === SORT.LABEL ? 'label' : 'apiName';
            const cmp = (a[key] || '').localeCompare(b[key] || '');
            return this.sortAsc ? cmp : -cmp;
        });
        return list;
    }

    get usageBarStyle() {
        if (!this.usageData) return '';
        return `width: ${this.usageData.percentageFilled}%`;
    }

    handleIdInput(e)   { this.inputRecordId = e.target.value; }
    handleSearch(e)    { this.searchTerm = e.target.value; }
    clearSearch()      { this.searchTerm = ''; }
    handleIdKeyDown(e) { if (e.key === 'Enter') this.handleLoad(); }

    handleLoad() {
        const rid = this.inputRecordId.trim();
        if (!rid) { this.errorMessage = 'Please enter a Record ID.'; return; }
        this.loadRecord(rid);
    }

    async loadRecord(rid) {
        this.isLoading    = true;
        this.errorMessage = '';
        this.recordData   = null;
        this._fields      = [];
        try {
            const data = await getRecordAllData({ recordId: rid });
            this.recordData = data;
            this._fields = data.fields.map(f => this._hydrateField(f));
        } catch (err) {
            this.errorMessage = this._extractError(err);
        } finally {
            this.isLoading = false;
        }
    }

    _hydrateField(f) {
        const hasValue = f.value !== null && f.value !== undefined && f.displayValue !== '';
        return {
            ...f,
            hasValue,
            isEditing  : false,
            isDirty    : false,
            editValue  : f.displayValue,
            rowClass   : this._rowClass(f),
            valueClass : hasValue ? 'sad-value' : 'sad-value sad-value-null',
        };
    }

    _rowClass(f) {
        if (f.isDirty)       return 'sad-row sad-row-dirty';
        if (f.isFormula)     return 'sad-row sad-row-formula';
        if (!f.isUpdateable) return 'sad-row sad-row-readonly';
        return 'sad-row';
    }

    handleFilter(e)  { this.activeFilter = e.currentTarget.dataset.filter; }
    sortByLabel()    { if (this.sortField === SORT.LABEL) this.sortAsc = !this.sortAsc; else { this.sortField = SORT.LABEL; this.sortAsc = true; } }
    sortByApi()      { if (this.sortField === SORT.API)   this.sortAsc = !this.sortAsc; else { this.sortField = SORT.API;   this.sortAsc = true; } }

    handleDblClick(e) {
        const apiName = e.currentTarget.dataset.field;
        const field   = this._getField(apiName);
        if (!field || !field.isUpdateable) return;
        this._setField(apiName, { isEditing: true, editValue: field.displayValue });
    }

    handleEditClick(e) {
        const apiName = e.currentTarget.dataset.field;
        const field   = this._getField(apiName);
        if (!field) return;
        this._setField(apiName, { isEditing: true, editValue: field.displayValue });
    }

    handleEditInput(e)   { this._setField(e.currentTarget.dataset.field, { editValue: e.target.value }); }
    handleEditBlur(e)    { this._commitEdit(e.currentTarget.dataset.field); }
    handleEditKeyDown(e) {
        if (e.key === 'Enter')  this._commitEdit(e.currentTarget.dataset.field);
        if (e.key === 'Escape') this._cancelEdit(e.currentTarget.dataset.field);
    }

    _commitEdit(apiName) {
        const field = this._getField(apiName);
        if (!field) return;
        const newVal  = field.editValue;
        const changed = newVal !== field.displayValue;
        this._setField(apiName, {
            isEditing   : false,
            displayValue: newVal,
            hasValue    : newVal !== null && newVal !== '',
            isDirty     : changed,
            rowClass    : changed ? 'sad-row sad-row-dirty' : this._rowClass(field),
        });
    }

    _cancelEdit(apiName) {
        const field = this._getField(apiName);
        if (!field) return;
        this._setField(apiName, { isEditing: false, editValue: field.displayValue });
    }

    async handleSaveAll() {
        this.isSaving = true;
        const dirtyFields = this._fields.filter(f => f.isDirty);
        const errors = [];
        for (const f of dirtyFields) {
            try {
                await updateFieldValue({
                    recordId     : this.recordData.recordId,
                    objectApiName: this.recordData.objectApiName,
                    fieldApiName : f.apiName,
                    newValue     : f.displayValue,
                });
                this._setField(f.apiName, { isDirty: false, rowClass: 'sad-row' });
            } catch (err) {
                errors.push(`${f.label}: ${this._extractError(err)}`);
            }
        }
        this.isSaving = false;
        if (errors.length) this._showToast('error', `Save failed: ${errors.join(' | ')}`);
        else this._showToast('success', `${dirtyFields.length} field(s) saved successfully.`);
    }

    handleDiscardChanges() {
        this._fields = this._fields.map(f => {
            if (f.isDirty) return { ...f, isDirty: false, displayValue: f.value != null ? String(f.value) : '', rowClass: this._rowClass({...f, isDirty: false}) };
            return f;
        });
    }

    handleCopyId()    { this._copyToClipboard(this.recordData.recordId, 'Record ID copied!'); }
    handleCopyValue(e){ this._copyToClipboard(e.currentTarget.dataset.value || '', 'Value copied!'); }

    handleOpenSetup() {
        window.open(`/lightning/setup/ObjectManager/${this.recordData.objectApiName}/FieldsAndRelationships/view`, '_blank');
    }

    handleOpenFieldSetup(e) {
        window.open(`/lightning/setup/ObjectManager/${e.currentTarget.dataset.object}/FieldsAndRelationships/${e.currentTarget.dataset.field}/view`, '_blank');
    }

    async handleAnalyzeUsage(e) {
        this.showUsageModal = true;
        this.usageLoading   = true;
        this.usageData      = null;
        try {
            this.usageData = await analyzeFieldUsage({
                objectApiName: e.currentTarget.dataset.object,
                fieldApiName : e.currentTarget.dataset.field
            });
        } catch (err) {
            this._showToast('error', this._extractError(err));
            this.showUsageModal = false;
        } finally {
            this.usageLoading = false;
        }
    }

    closeUsageModal() { this.showUsageModal = false; this.usageData = null; }
    handleToggleSave() {}

    _getField(apiName)       { return this._fields.find(f => f.apiName === apiName); }
    _setField(apiName, patch){ this._fields = this._fields.map(f => f.apiName === apiName ? { ...f, ...patch } : f); }

    _copyToClipboard(text, successMsg) {
        if (navigator.clipboard) {
            navigator.clipboard.writeText(text)
                .then(() => this._showToast('success', successMsg))
                .catch(() => this._showToast('error', 'Copy failed.'));
        } else {
            const ta = document.createElement('textarea');
            ta.value = text;
            document.body.appendChild(ta);
            ta.select();
            document.execCommand('copy');
            document.body.removeChild(ta);
            this._showToast('success', successMsg);
        }
    }

    _showToast(type, message) {
        const typeMap = { success: 'sad-toast sad-toast-success', error: 'sad-toast sad-toast-error' };
        this.toast = { visible: true, message, cssClass: typeMap[type] || 'sad-toast' };
        setTimeout(() => { this.toast = { ...this.toast, visible: false }; }, 3500);
    }

    _extractError(err) {
        if (typeof err === 'string') return err;
        return err?.body?.message || err?.message || 'An unexpected error occurred.';
    }
}