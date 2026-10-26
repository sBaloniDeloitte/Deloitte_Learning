import { LightningElement, track } from 'lwc';
import getObjectFieldsApex   from '@salesforce/apex/DataImportController.getObjectFields';
import getQueryableObjectsApex from '@salesforce/apex/DataImportController.getQueryableObjects';
import importRecordsApex     from '@salesforce/apex/DataImportController.importRecords';

const OPERATIONS = [
    { value: 'insert', label: 'Insert' },
    { value: 'update', label: 'Update' },
    { value: 'upsert', label: 'Upsert' },
    { value: 'delete', label: 'Delete' },
];

export default class dataImporterCmp extends LightningElement {

    // ── Step 1 state ─────────────────────────────────────────────────
    @track objectName      = '';
    @track operation       = 'insert';
    @track externalIdField = '';
    @track objSuggestions  = [];
    @track showObjSuggestions = false;

    // ── Step 2 state ─────────────────────────────────────────────────
    @track csvFileName  = '';
    @track csvRowCount  = 0;
    @track csvColCount  = 0;
    @track isDragging   = false;

    // ── Step 3 state ─────────────────────────────────────────────────
    @track fieldMappings = [];
    @track previewRows   = [];
    @track previewHeaders = [];

    // ── Step 4 / Results state ────────────────────────────────────────
    @track isImporting   = false;
    @track importResults = [];
    @track errorMsg      = '';

    // Internal raw data
    _csvHeaders  = [];
    _csvData     = [];
    _objectFields = [];
    _objTimer    = null;

    // ─────────────────────────────────────────────────────────────────
    // COMPUTED GETTERS
    // ─────────────────────────────────────────────────────────────────

    get isUpsert()        { return this.operation === 'upsert'; }
    get hasFieldMappings(){ return this.fieldMappings.length > 0; }
    get hasPreviewRows()  { return this.previewRows.length > 0; }
    get hasResults()      { return this.importResults.length > 0; }
    get hasFailures()     { return this.importResults.some(r => !r.success); }

    get dropZoneClass() {
        return 'drop-zone' + (this.isDragging ? ' drop-zone_active' : '')
                           + (this.csvFileName ? ' drop-zone_filled' : '');
    }

    get operationOptions() {
        return OPERATIONS.map(op => ({
            ...op,
            cssClass: 'op-btn' + (this.operation === op.value ? ' op-btn_active' : '')
        }));
    }

    get runBtnLabel() {
        const op = this.operation.charAt(0).toUpperCase() + this.operation.slice(1);
        return `${op} ${this.csvRowCount} Records`;
    }

    get mappedCount()   { return this.fieldMappings.filter(f => f.mapped && f.included).length; }
    get unmappedCount() { return this.fieldMappings.filter(f => !f.mapped).length; }
    get skippedCount()  { return this.fieldMappings.filter(f => f.mapped && !f.included).length; }
    get totalColumns()  { return this.fieldMappings.length; }

    get successCount()  { return this.importResults.filter(r => r.success).length; }
    get failCount()     { return this.importResults.filter(r => !r.success).length; }
    get totalCount()    { return this.importResults.length; }

    get progressBarStyle() {
        const pct = this.totalCount > 0
            ? Math.round((this.successCount / this.totalCount) * 100) : 0;
        return `width:${pct}%`;
    }

    // ─────────────────────────────────────────────────────────────────
    // STEP 1 — Object name autocomplete
    // ─────────────────────────────────────────────────────────────────

    handleObjectInput(event) {
        this.objectName = event.target.value;
        this.fieldMappings = [];
        this.importResults = [];
        clearTimeout(this._objTimer);
        if (this.objectName.length < 2) { this.showObjSuggestions = false; return; }
        this._objTimer = setTimeout(() => {
            getQueryableObjectsApex({ prefix: this.objectName })
                .then(res => {
                    this.objSuggestions = res || [];
                    this.showObjSuggestions = this.objSuggestions.length > 0;
                })
                .catch(() => { this.showObjSuggestions = false; });
        }, 250);
    }

    selectObject(event) {
        this.objectName = event.currentTarget.dataset.value;
        this.showObjSuggestions = false;
        if (this._csvHeaders.length > 0) this._buildMappings();
    }

    hideObjSuggestions() {
        // Small delay so click on suggestion registers first
        setTimeout(() => { this.showObjSuggestions = false; }, 200);
    }

    selectOperation(event) {
        this.operation = event.currentTarget.dataset.value;
    }

    handleExternalIdInput(event) {
        this.externalIdField = event.target.value;
    }

    // ─────────────────────────────────────────────────────────────────
    // STEP 2 — CSV Upload
    // ─────────────────────────────────────────────────────────────────

    handleDragOver(event) { event.preventDefault(); this.isDragging = true; }
    handleDragLeave()     { this.isDragging = false; }

    handleDrop(event) {
        event.preventDefault();
        this.isDragging = false;
        const file = event.dataTransfer.files[0];
        if (file) this._readFile(file);
    }

    handleFileUpload(event) {
        const file = event.target.files[0];
        if (file) this._readFile(file);
    }

    _readFile(file) {
        if (!file.name.match(/\.(csv|txt)$/i)) {
            this.errorMsg = 'Please upload a CSV file.'; return;
        }
        this.csvFileName = file.name;
        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const { headers, rows } = this._parseCSV(e.target.result);
                this._csvHeaders = headers;
                this._csvData    = rows;
                this.csvRowCount = rows.length;
                this.csvColCount = headers.length;
                this.errorMsg    = '';
                this._buildPreview();
                if (this.objectName) this._buildMappings();
            } catch(err) {
                this.errorMsg = 'CSV parse error: ' + err.message;
            }
        };
        reader.readAsText(file, 'UTF-8');
    }

    _parseCSV(text) {
        // Normalise line endings
        const lines = text.replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n')
                          .filter(l => l.trim() !== '');
        if (lines.length < 2) throw new Error('CSV must have at least a header row and one data row.');

        const headers = this._splitLine(lines[0]);
        const rows = [];
        for (let i = 1; i < lines.length; i++) {
            const vals = this._splitLine(lines[i]);
            const row = {};
            headers.forEach((h, idx) => { row[h] = vals[idx] !== undefined ? vals[idx] : ''; });
            rows.push(row);
        }
        return { headers, rows };
    }

    _splitLine(line) {
        const result = []; let cur = '', inQ = false;
        for (let i = 0; i < line.length; i++) {
            const ch = line[i];
            if (ch === '"') {
                if (inQ && line[i+1] === '"') { cur += '"'; i++; }
                else inQ = !inQ;
            } else if (ch === ',' && !inQ) {
                result.push(cur.trim()); cur = '';
            } else { cur += ch; }
        }
        result.push(cur.trim());
        return result;
    }

    _buildPreview() {
        this.previewHeaders = this._csvHeaders;
        this.previewRows = this._csvData.slice(0, 5).map((row, i) => ({
            _key  : String(i),
            cells : this._csvHeaders.map(h => ({ col: h, val: row[h] || '' }))
        }));
    }

    // ─────────────────────────────────────────────────────────────────
    // STEP 3 — Field Mapping
    // ─────────────────────────────────────────────────────────────────

    _buildMappings() {
        getObjectFieldsApex({ objectName: this.objectName })
            .then(fields => {
                this._objectFields = fields;

                // Build lookup by API name (lowercase)
                const sfMap = {};
                fields.forEach(f => { sfMap[f.apiName.toLowerCase()] = f; });

                this.fieldMappings = this._csvHeaders.map(col => {
                    const sf      = sfMap[col.toLowerCase()];
                    const mapped  = !!sf;
                    const included = mapped; // auto-include mapped, exclude unmapped

                    return {
                        csvCol   : col,
                        sfField  : mapped ? sf.apiName  : '⚠ Not found in ' + this.objectName,
                        sfLabel  : mapped ? sf.label    : '',
                        sfType   : mapped ? sf.type     : '',
                        required : mapped && sf.required === 'true' ? '●' : '',
                        mapped,
                        included,
                        rowClass : mapped ? '' : 'row-unmapped',
                        sfClass  : mapped ? 'col-sf-ok' : 'col-sf-bad'
                    };
                });
            })
            .catch(err => {
                this.errorMsg = 'Failed to load fields: ' +
                    (err?.body?.message || err?.message || 'Unknown error');
            });
    }

    toggleMapping(event) {
        const col     = event.target.dataset.col;
        const checked = event.target.checked;
        this.fieldMappings = this.fieldMappings.map(fm =>
            fm.csvCol === col ? { ...fm, included: checked } : fm
        );
    }

    // ─────────────────────────────────────────────────────────────────
    // STEP 4 — Run Import
    // ─────────────────────────────────────────────────────────────────

    runImport() {
        // Validate
        if (!this.objectName.trim()) { this.errorMsg = 'Please enter an object name.';  return; }
        if (!this._csvData.length)   { this.errorMsg = 'Please upload a CSV file.';     return; }
        if (this.isUpsert && !this.externalIdField.trim()) {
            this.errorMsg = 'External ID field is required for Upsert.'; return;
        }

        const includedMappings = this.fieldMappings
            .filter(fm => fm.included && fm.mapped);

        if (!includedMappings.length) {
            this.errorMsg = 'No valid field mappings to import.'; return;
        }

        // Build records from included fields only
        const records = this._csvData.map(row => {
            const rec = {};
            includedMappings.forEach(fm => {
                const val = row[fm.csvCol];
                rec[fm.sfField] = (val === '' || val === undefined) ? null : val;
            });
            return rec;
        });

        this.isImporting  = true;
        this.importResults = [];
        this.errorMsg     = '';

        importRecordsApex({
            objectName      : this.objectName.trim(),
            operation       : this.operation,
            externalIdField : this.externalIdField.trim(),
            records,
            batchSize       : 200
        })
        .then(res => {
            const base = window.location.origin;
            this.importResults = res.map((r, i) => {
                const success = r.success === 'true';
                const hasId   = success && r.id;
                return {
                    row       : i + 1,
                    success,
                    status    : success ? '✓ Success' : '✗ Failed',
                    id        : r.id || '',
                    error     : r.error || '',
                    isLink    : hasId,
                    href      : hasId ? `${base}/${r.id}` : '',
                    rowClass  : success ? 'row-success' : 'row-fail',
                    statusClass: success ? 'badge-success' : 'badge-fail'
                };
            });
        })
        .catch(err => {
            this.errorMsg = 'Import failed: ' +
                (err?.body?.message || err?.message || 'Unknown error');
        })
        .finally(() => { this.isImporting = false; });
    }

    // ─────────────────────────────────────────────────────────────────
    // DOWNLOAD ERROR LOG
    // ─────────────────────────────────────────────────────────────────

    downloadErrorLog() {
        const failed = this.importResults.filter(r => !r.success);
        if (!failed.length) return;

        // Include original CSV data alongside error
        const headers = ['Row', 'Error', ...this._csvHeaders];
        const rows    = failed.map(r => {
            const origRow = this._csvData[r.row - 1] || {};
            const vals    = this._csvHeaders.map(h => this._esc(origRow[h] || ''));
            return [r.row, this._esc(r.error), ...vals].join(',');
        });

        const csv    = '\uFEFF' + [headers.join(','), ...rows].join('\r\n');
        const anchor = this.template.querySelector('.dl-anchor');
        anchor.setAttribute('href', 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv));
        anchor.setAttribute('download', `import_errors_${this.objectName}_${this._ts()}.csv`);
        anchor.click();
    }

    _esc(val) { return '"' + String(val == null ? '' : val).replace(/"/g, '""') + '"'; }
    _ts()     { return new Date().toISOString().slice(0,19).replace(/[T:]/g,'-'); }

    // ─────────────────────────────────────────────────────────────────
    // RESET / CLEAR
    // ─────────────────────────────────────────────────────────────────

    resetAll() {
        this.objectName = ''; this.operation = 'insert'; this.externalIdField = '';
        this.csvFileName = ''; this.csvRowCount = 0; this.csvColCount = 0;
        this.fieldMappings = []; this.previewRows = []; this.previewHeaders = [];
        this.importResults = []; this.errorMsg = '';
        this._csvHeaders = []; this._csvData = []; this._objectFields = [];
        this.showObjSuggestions = false; this.isDragging = false;
    }

    clearError() { this.errorMsg = ''; }
}