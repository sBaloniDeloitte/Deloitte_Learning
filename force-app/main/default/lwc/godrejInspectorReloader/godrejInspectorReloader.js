//test
import { LightningElement, track } from 'lwc';

// ── Data Export (SOQL) imports ──
import getSuggestions       from '@salesforce/apex/InspectorController.getSuggestions';
import runSoqlQuery         from '@salesforce/apex/InspectorController.runQuery';
import saveQueryApex        from '@salesforce/apex/InspectorController.saveQuery';
import getSavedQueriesApex  from '@salesforce/apex/InspectorController.getSavedQueries';
import deleteSavedQueryApex from '@salesforce/apex/InspectorController.deleteSavedQuery';

// ── Data Import imports ──
import getObjectFieldsApex     from '@salesforce/apex/DataImportController.getObjectFields';
import getQueryableObjectsApex from '@salesforce/apex/DataImportController.getQueryableObjects';
import importRecordsApex       from '@salesforce/apex/DataImportController.importRecords';

// ── Show All Data imports ──
import getRecordAllData  from '@salesforce/apex/ShowAllDataController.getRecordAllData';
import updateFieldValue  from '@salesforce/apex/ShowAllDataController.updateFieldValue';

// ── Constants ──
const TABS = { EXPORT: 'export', IMPORT: 'import', SHOW: 'show' };

const BADGE_CLASS = {
    FLD: 'sug-badge sug-badge-fld', OBJ: 'sug-badge sug-badge-obj',
    KW : 'sug-badge sug-badge-kw',  FN : 'sug-badge sug-badge-fn',
    DATE: 'sug-badge sug-badge-date',
};

const OPERATIONS = [
    { value: 'insert', label: 'Insert' },
    { value: 'update', label: 'Update' },
    { value: 'upsert', label: 'Upsert' },
    { value: 'delete', label: 'Delete' },
];

const FILTER = { ALL: 'all', EDITABLE: 'editable', FORMULA: 'formula', BLANK: 'blank' };
const SORT   = { LABEL: 'label', API: 'api' };

export default class GodrejInspector extends LightningElement {

    // ── Tab state ─────────────────────────────────────────────────────
    @track activeTab = TABS.EXPORT;

    get isExport() { return this.activeTab === TABS.EXPORT; }
    get isImport() { return this.activeTab === TABS.IMPORT; }
    get isShow()   { return this.activeTab === TABS.SHOW; }

    get tabExportClass() { return this._tabClass(TABS.EXPORT); }
    get tabImportClass() { return this._tabClass(TABS.IMPORT); }
    get tabShowClass()   { return this._tabClass(TABS.SHOW); }

    _tabClass(tab) {
        return `gi-tab${this.activeTab === tab ? ' gi-tab_active' : ''}`;
    }

    switchTab(event) {
        this.activeTab = event.currentTarget.dataset.tab;
    }

    // ══════════════════════════════════════════════════════════════════
    // DATA EXPORT — SOQL INSPECTOR
    // ══════════════════════════════════════════════════════════════════

    @track suggestions   = [];
    @track columns       = [];
    @track rows          = [];
    @track isRunning     = false;
    @track errorMessage  = '';
    @track resultSummary = '';
    @track debugInfo     = true;
    @track debugClause   = '—';
    @track debugToken    = '—';
    @track debugCursor   = 0;
    @track debugObject   = '—';
    @track showSavedPanel = false;
    @track savedQueries   = [];

    _query = ''; _cursorPos = 0; _selectedIndex = -1; _typingTimer = null;

    connectedCallback() { this._loadSavedQueries(); }

    renderedCallback() {
        const ta = this._ta();
        if (ta && ta.value !== this._query) ta.value = this._query;
    }

    _ta() { return this.template.querySelector('textarea'); }

    // Saved queries
    get savedQueryBtnLabel() {
        const c = this.savedQueries.length;
        return `Saved Queries${c > 0 ? ' (' + c + ')' : ''}`;
    }
    get savedQueryCount() { return this.savedQueries.length; }
    get hasSavedQueries() { return this.savedQueries.length > 0; }

    toggleSavedPanel() {
        this.showSavedPanel = !this.showSavedPanel;
        if (this.showSavedPanel) this._loadSavedQueries();
    }

    _loadSavedQueries() {
        getSavedQueriesApex()
            .then(res => {
                this.savedQueries = (res || []).map(sq => ({
                    ...sq, lastRunFormatted: sq.lastRun ? this._fmtDate(sq.lastRun) : ''
                }));
            })
            .catch(err => console.error('getSavedQueries:', err));
    }

    _fmtDate(dtStr) {
        try {
            const d = new Date(dtStr);
            return d.toLocaleDateString() + ' ' +
                   d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        } catch(e) { return dtStr; }
    }

    _autoSaveQuery(queryText) {
        saveQueryApex({ queryText, queryName: '' })
            .then(() => this._loadSavedQueries())
            .catch(err => console.error('saveQuery:', err));
    }

    loadSavedQuery(event) {
        const sq = this.savedQueries.find(q => q.id === event.currentTarget.dataset.id);
        if (!sq) return;
        this._query = sq.queryText;
        this._cursorPos = sq.queryText.length;
        this.showSavedPanel = false;
        this.suggestions = [];
        const ta = this._ta();
        if (ta) { ta.value = sq.queryText; ta.setSelectionRange(this._cursorPos, this._cursorPos); ta.focus(); }
    }

    deleteSavedQuery(event) {
        event.stopPropagation();
        const id = event.currentTarget.dataset.id;
        deleteSavedQueryApex({ recordId: id })
            .then(() => { this.savedQueries = this.savedQueries.filter(q => q.id !== id); })
            .catch(err => console.error('deleteSavedQuery:', err));
    }

    // Input handlers
    handleInput(event) {
        const ta = event.target;
        this._query = ta.value; this._cursorPos = ta.selectionStart; this._selectedIndex = -1;
        clearTimeout(this._typingTimer);
        if (!this._query.trim()) { this.suggestions = []; this._resetDebug(); return; }
        this._typingTimer = setTimeout(() => this._fetchSuggestions(), 180);
    }

    handleKeyUp(event) {
        const ta = event.target;
        if (this._cursorPos !== ta.selectionStart) {
            this._cursorPos = ta.selectionStart;
            clearTimeout(this._typingTimer);
            this._typingTimer = setTimeout(() => this._fetchSuggestions(), 180);
        }
    }

    handleCursorMove(event) {
        this._cursorPos = event.target.selectionStart;
        clearTimeout(this._typingTimer);
        this._typingTimer = setTimeout(() => this._fetchSuggestions(), 180);
    }

    handleKeyDown(event) {
        const hasSugs = this.suggestions.length > 0;
        if (event.key === 'Escape') { this.suggestions = []; this._selectedIndex = -1; return; }
        if (!hasSugs) {
            if (event.key === 'Enter' && (event.ctrlKey || event.metaKey)) { event.preventDefault(); this.runQuery(); }
            return;
        }
        if (event.key === 'Tab' && !event.shiftKey) { event.preventDefault(); this._move(1);  return; }
        if (event.key === 'Tab' &&  event.shiftKey) { event.preventDefault(); this._move(-1); return; }
        if (event.key === 'ArrowRight') { event.preventDefault(); this._move(1);  return; }
        if (event.key === 'ArrowLeft')  { event.preventDefault(); this._move(-1); return; }
        if (event.key === 'Enter' && this._selectedIndex >= 0) { event.preventDefault(); this._applyByIndex(this._selectedIndex); }
    }

    _move(dir) {
        const total = this.suggestions.length;
        if (!total) return;
        this._selectedIndex = (this._selectedIndex + dir + total) % total;
        this._refreshCssClasses();
    }

    _refreshCssClasses() {
        this.suggestions = this.suggestions.map((s, i) => ({
            ...s, cssClass: this._itemClass(i === this._selectedIndex)
        }));
    }

    _itemClass(active) { return `suggestion-item${active ? ' suggestion-item_active' : ''}`; }

    _fetchSuggestions() {
        const q = this._query, pos = this._cursorPos;
        if (!q || !q.trim()) { this.suggestions = []; this._resetDebug(); return; }
        const { clause, token, objectName } = this._localContext(q, pos);
        this.debugClause = clause; this.debugToken = token || '(empty)';
        this.debugCursor = pos;   this.debugObject = objectName || '(not found)';
        getSuggestions({ query: q, cursorPosition: pos })
            .then(res => { this.suggestions = (res || []).map((raw, i) => this._shape(raw, i)); })
            .catch(() => { this.suggestions = []; });
    }

    _localContext(q, pos) {
        const before = q.substring(0, pos);
        return { clause: this._detectClause(before.toUpperCase()), token: this._activeToken(q, pos), objectName: this._extractObject(q) };
    }

    _detectClause(upper) {
        const clauses = ['SELECT','FROM','WHERE','ORDER BY','GROUP BY','HAVING','LIMIT','OFFSET'];
        let winner = 'UNKNOWN', winPos = -1;
        for (const kw of clauses) {
            const p = this._lastWholeWord(upper, kw);
            if (p > winPos) { winPos = p; winner = kw; }
        }
        return winner;
    }

    _lastWholeWord(upper, kw) {
        let pos = -1, start = 0;
        while (true) {
            const idx = upper.indexOf(kw, start);
            if (idx === -1) break;
            const pre  = idx === 0 || /[\s,\n\t(]/.test(upper[idx - 1]);
            const post = (idx + kw.length >= upper.length) || /[\s,\n\t(]/.test(upper[idx + kw.length]);
            if (pre && post) pos = idx;
            start = idx + 1;
        }
        return pos;
    }

    _activeToken(q, pos) {
        let start = pos;
        while (start > 0 && !/[\s,\n\t]/.test(q[start - 1])) start--;
        return q.substring(start, pos);
    }

    _extractObject(q) { const m = q.match(/\bFROM\s+(\w+)/i); return m ? m[1] : null; }

    _shape(raw, i) {
        const value  = typeof raw === 'string' ? raw : (raw.value  || '');
        const label  = typeof raw === 'string' ? raw : (raw.label  || value);
        const type   = typeof raw === 'string' ? 'FLD' : (raw.type || 'FLD');
        const detail = typeof raw === 'string' ? ''   : (raw.detail || '');
        return { key: value + '_' + i, value, label, type, detail, badgeClass: BADGE_CLASS[type] || 'sug-badge', cssClass: this._itemClass(i === this._selectedIndex) };
    }

    applySuggestion(event) {
        event.preventDefault();
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        this._applyByIndex(isNaN(idx) ? 0 : idx);
    }

    _applyByIndex(idx) {
        const s = this.suggestions[idx]; if (!s) return;
        const { newQuery, newCursor } = this._buildNewQuery(this._query, s.value, this._cursorPos);
        this._query = newQuery; this._cursorPos = newCursor;
        this.suggestions = []; this._selectedIndex = -1;
        const ta = this._ta();
        if (ta) { ta.value = newQuery; ta.setSelectionRange(newCursor, newCursor); ta.focus(); }
        clearTimeout(this._typingTimer);
        this._typingTimer = setTimeout(() => this._fetchSuggestions(), 80);
    }

    _buildNewQuery(q, value, cursor) {
        let tokenStart = cursor;
        while (tokenStart > 0 && !/[\s,\n\t]/.test(q[tokenStart - 1])) tokenStart--;
        let tokenEnd = cursor;
        while (tokenEnd < q.length && !/[\s,\n\t]/.test(q[tokenEnd])) tokenEnd++;
        const activeToken = q.substring(tokenStart, cursor);
        const suffix      = q.substring(cursor, tokenEnd);
        const fullToken   = activeToken + suffix;
        const clause      = this._detectClause(q.substring(0, cursor).toUpperCase());
        const prefix      = q.substring(0, tokenStart);
        const lastDot     = activeToken.lastIndexOf('.');
        let inserted;
        if (value.endsWith('.')) { inserted = value; }
        else if (lastDot >= 0 && !value.includes('.')) { inserted = activeToken.substring(0, lastDot + 1) + value; }
        else if (clause === 'FROM') { inserted = value + ' '; }
        else if (['SELECT','WHERE','ORDER BY','GROUP BY','HAVING'].includes(clause)) { inserted = value; }
        else { inserted = value + ' '; }
        let rest;
        if (lastDot >= 0) { rest = q.substring(tokenEnd); }
        else {
            const consume = value.toUpperCase() === fullToken.toUpperCase() || value.toUpperCase().startsWith(fullToken.toUpperCase()) || fullToken.toUpperCase().startsWith(value.toUpperCase());
            rest = q.substring(consume ? tokenEnd : cursor);
        }
        return { newQuery: prefix + inserted + rest, newCursor: prefix.length + inserted.length };
    }

    runQuery() {
        const q = this._query.trim();
        if (!q) { this.errorMessage = 'Please enter a SOQL query.'; return; }
        this.isRunning = true; this.errorMessage = ''; this.resultSummary = '';
        this.columns = []; this.rows = [];
        runSoqlQuery({ query: q })
            .then(res => { this._processResults(res); this._autoSaveQuery(q); })
            .catch(err => { this.errorMessage = 'Query failed: ' + (err?.body?.message || err?.message || 'Unknown error'); })
            .finally(() => { this.isRunning = false; });
    }

    _processResults(records) {
        if (!records || records.length === 0) { this.resultSummary = '0 records returned.'; return; }
        const colSet = new Set();
        records.forEach(rec => Object.keys(rec).forEach(k => colSet.add(k)));
        this.columns = [...colSet].filter(k => k !== 'attributes');
        const base = window.location.origin;
        this.rows = records.map((rec, ri) => ({
            _key : rec['Id'] || String(ri),
            cells: this.columns.map(col => {
                const v = rec[col]; const str = v == null ? '' : String(v);
                const isId = col === 'Id' && typeof v === 'string' && v.length === 18;
                return { col, value: str, isLink: isId, href: isId ? `${base}/${v}` : null };
            })
        }));
        this.resultSummary = `${records.length} record${records.length !== 1 ? 's' : ''} returned.`;
    }

    downloadExcel() {
        if (!this.columns.length || !this.rows.length) { this.errorMessage = 'No results to download.'; return; }
        const esc      = val => '"' + String(val == null ? '' : val).replace(/"/g, '""') + '"';
        const header   = this.columns.map(esc).join(',');
        const dataRows = this.rows.map(row => row.cells.map(c => esc(c.value)).join(','));
        const csv      = '\uFEFF' + [header, ...dataRows].join('\r\n');
        const objMatch = this._query.match(/\bFROM\s+(\w+)/i);
        const ts       = new Date().toISOString().slice(0,19).replace(/[T:]/g,'-');
        const fileName = (objMatch ? objMatch[1] : 'results') + '_' + ts + '.csv';
        try {
            const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
            const url  = URL.createObjectURL(blob);
            const a    = this.template.querySelector('.download-anchor');
            a.setAttribute('href', url); a.setAttribute('download', fileName); a.click();
            setTimeout(() => URL.revokeObjectURL(url), 2000);
        } catch(e) {
            const a = this.template.querySelector('.download-anchor');
            a.setAttribute('href', 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv));
            a.setAttribute('download', fileName); a.click();
        }
    }

    formatQuery() {
        if (!this._query.trim()) return;
        const CLAUSES = ['SELECT','FROM','WHERE','ORDER BY','GROUP BY','HAVING','LIMIT','OFFSET'];
        let q = this._query.trim().replace(/\s+/g, ' ');
        CLAUSES.forEach(kw => { q = q.replace(new RegExp(`\\b${kw}\\b`, 'gi'), '\n' + kw.toUpperCase()); });
        this._query = q.trimStart();
        const ta = this._ta(); if (ta) ta.value = this._query;
    }

    clearAll() {
        this._query = ''; this._cursorPos = 0; this._selectedIndex = -1;
        this.suggestions = []; this.columns = []; this.rows = [];
        this.errorMessage = ''; this.resultSummary = ''; this._resetDebug();
        const ta = this._ta(); if (ta) { ta.value = ''; ta.focus(); }
    }

    clearExportError() { this.errorMessage = ''; }

    _resetDebug() { this.debugClause = '—'; this.debugToken = '—'; this.debugCursor = 0; this.debugObject = '—'; }

    get hasSuggestions() { return this.suggestions && this.suggestions.length > 0; }
    get hasResults()     { return this.rows && this.rows.length > 0; }

    // ══════════════════════════════════════════════════════════════════
    // DATA IMPORT
    // ══════════════════════════════════════════════════════════════════

    @track objectName         = '';
    @track operation          = 'insert';
    @track externalIdField    = '';
    @track objSuggestions     = [];
    @track showObjSuggestions = false;
    @track csvFileName        = '';
    @track csvRowCount        = 0;
    @track csvColCount        = 0;
    @track isDragging         = false;
    @track fieldMappings      = [];
    @track previewRows        = [];
    @track previewHeaders     = [];
    @track isImporting        = false;
    @track importResults      = [];
    @track importErrorMsg     = '';

    _csvHeaders = []; _csvData = []; _objectFields = []; _objTimer = null;

    get isUpsert()         { return this.operation === 'upsert'; }
    get hasFieldMappings() { return this.fieldMappings.length > 0; }
    get hasPreviewRows()   { return this.previewRows.length > 0; }
    get hasImportResults() { return this.importResults.length > 0; }
    get hasFailures()      { return this.importResults.some(r => !r.success); }

    get dropZoneClass() {
        return 'drop-zone' + (this.isDragging ? ' drop-zone_active' : '') + (this.csvFileName ? ' drop-zone_filled' : '');
    }

    get operationOptions() {
        return OPERATIONS.map(op => ({ ...op, cssClass: 'op-btn' + (this.operation === op.value ? ' op-btn_active' : '') }));
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
        const pct = this.totalCount > 0 ? Math.round((this.successCount / this.totalCount) * 100) : 0;
        return `width:${pct}%`;
    }

    handleObjectInput(event) {
        this.objectName = event.target.value; this.fieldMappings = []; this.importResults = [];
        clearTimeout(this._objTimer);
        if (this.objectName.length < 2) { this.showObjSuggestions = false; return; }
        this._objTimer = setTimeout(() => {
            getQueryableObjectsApex({ prefix: this.objectName })
                .then(res => { this.objSuggestions = res || []; this.showObjSuggestions = this.objSuggestions.length > 0; })
                .catch(() => { this.showObjSuggestions = false; });
        }, 250);
    }

    selectObject(event) { this.objectName = event.currentTarget.dataset.value; this.showObjSuggestions = false; if (this._csvHeaders.length > 0) this._buildMappings(); }
    hideObjSuggestions() { setTimeout(() => { this.showObjSuggestions = false; }, 200); }
    selectOperation(event) { this.operation = event.currentTarget.dataset.value; }
    handleExternalIdInput(event) { this.externalIdField = event.target.value; }

    handleDragOver(event)  { event.preventDefault(); this.isDragging = true; }
    handleDragLeave()      { this.isDragging = false; }
    handleDrop(event)      { event.preventDefault(); this.isDragging = false; const f = event.dataTransfer.files[0]; if (f) this._readFile(f); }
    handleFileUpload(event){ const f = event.target.files[0]; if (f) this._readFile(f); }

    _readFile(file) {
        if (!file.name.match(/\.(csv|txt)$/i)) { this.importErrorMsg = 'Please upload a CSV file.'; return; }
        this.csvFileName = file.name;
        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const { headers, rows } = this._parseCSV(e.target.result);
                this._csvHeaders = headers; this._csvData = rows;
                this.csvRowCount = rows.length; this.csvColCount = headers.length;
                this.importErrorMsg = '';
                this._buildPreview();
                if (this.objectName) this._buildMappings();
            } catch(err) { this.importErrorMsg = 'CSV parse error: ' + err.message; }
        };
        reader.readAsText(file, 'UTF-8');
    }

    _parseCSV(text) {
        const lines = text.replace(/\r\n/g,'\n').replace(/\r/g,'\n').split('\n').filter(l => l.trim() !== '');
        if (lines.length < 2) throw new Error('CSV must have at least a header row and one data row.');
        const headers = this._splitLine(lines[0]);
        const rows = [];
        for (let i = 1; i < lines.length; i++) {
            const vals = this._splitLine(lines[i]); const row = {};
            headers.forEach((h, idx) => { row[h] = vals[idx] !== undefined ? vals[idx] : ''; });
            rows.push(row);
        }
        return { headers, rows };
    }

    _splitLine(line) {
        const result = []; let cur = '', inQ = false;
        for (let i = 0; i < line.length; i++) {
            const ch = line[i];
            if (ch === '"') { if (inQ && line[i+1] === '"') { cur += '"'; i++; } else inQ = !inQ; }
            else if (ch === ',' && !inQ) { result.push(cur.trim()); cur = ''; }
            else { cur += ch; }
        }
        result.push(cur.trim()); return result;
    }

    _buildPreview() {
        this.previewHeaders = this._csvHeaders;
        this.previewRows = this._csvData.slice(0,5).map((row,i) => ({ _key: String(i), cells: this._csvHeaders.map(h => ({ col: h, val: row[h] || '' })) }));
    }

    _buildMappings() {
        getObjectFieldsApex({ objectName: this.objectName })
            .then(fields => {
                this._objectFields = fields;
                const sfMap = {};
                fields.forEach(f => { sfMap[f.apiName.toLowerCase()] = f; });
                this.fieldMappings = this._csvHeaders.map(col => {
                    const sf = sfMap[col.toLowerCase()]; const mapped = !!sf;
                    return { csvCol: col, sfField: mapped ? sf.apiName : '⚠ Not found in ' + this.objectName, sfLabel: mapped ? sf.label : '', sfType: mapped ? sf.type : '', required: mapped && sf.required === 'true' ? '●' : '', mapped, included: mapped, rowClass: mapped ? '' : 'row-unmapped', sfClass: mapped ? 'col-sf-ok' : 'col-sf-bad' };
                });
            })
            .catch(err => { this.importErrorMsg = 'Failed to load fields: ' + (err?.body?.message || err?.message || 'Unknown error'); });
    }

    toggleMapping(event) {
        const col = event.target.dataset.col; const checked = event.target.checked;
        this.fieldMappings = this.fieldMappings.map(fm => fm.csvCol === col ? { ...fm, included: checked } : fm);
    }

    runImport() {
        if (!this.objectName.trim()) { this.importErrorMsg = 'Please enter an object name.'; return; }
        if (!this._csvData.length)   { this.importErrorMsg = 'Please upload a CSV file.';    return; }
        if (this.isUpsert && !this.externalIdField.trim()) { this.importErrorMsg = 'External ID field is required for Upsert.'; return; }
        const includedMappings = this.fieldMappings.filter(fm => fm.included && fm.mapped);
        if (!includedMappings.length) { this.importErrorMsg = 'No valid field mappings to import.'; return; }
        const records = this._csvData.map(row => { const rec = {}; includedMappings.forEach(fm => { const val = row[fm.csvCol]; rec[fm.sfField] = (val === '' || val === undefined) ? null : val; }); return rec; });
        this.isImporting = true; this.importResults = []; this.importErrorMsg = '';
        importRecordsApex({ objectName: this.objectName.trim(), operation: this.operation, externalIdField: this.externalIdField.trim(), records, batchSize: 200 })
            .then(res => {
                const base = window.location.origin;
                this.importResults = res.map((r, i) => {
                    const success = r.success === 'true'; const hasId = success && r.id;
                    return { row: i+1, success, status: success ? '✓ Success' : '✗ Failed', id: r.id || '', error: r.error || '', isLink: hasId, href: hasId ? `${base}/${r.id}` : '', rowClass: success ? 'row-success' : 'row-fail', statusClass: success ? 'badge-success' : 'badge-fail' };
                });
            })
            .catch(err => { this.importErrorMsg = 'Import failed: ' + (err?.body?.message || err?.message || 'Unknown error'); })
            .finally(() => { this.isImporting = false; });
    }

    downloadErrorLog() {
        const failed = this.importResults.filter(r => !r.success); if (!failed.length) return;
        const headers = ['Row','Error',...this._csvHeaders];
        const rows    = failed.map(r => { const orig = this._csvData[r.row-1]||{}; return [r.row, this._esc(r.error), ...this._csvHeaders.map(h => this._esc(orig[h]||''))].join(','); });
        const csv     = '\uFEFF' + [headers.join(','), ...rows].join('\r\n');
        const a = this.template.querySelector('.dl-anchor');
        a.setAttribute('href', 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv));
        a.setAttribute('download', `import_errors_${this.objectName}_${this._ts()}.csv`);
        a.click();
    }

    _esc(val) { return '"' + String(val==null?'':val).replace(/"/g,'""') + '"'; }
    _ts()     { return new Date().toISOString().slice(0,19).replace(/[T:]/g,'-'); }

    resetAll() {
        this.objectName=''; this.operation='insert'; this.externalIdField='';
        this.csvFileName=''; this.csvRowCount=0; this.csvColCount=0;
        this.fieldMappings=[]; this.previewRows=[]; this.previewHeaders=[];
        this.importResults=[]; this.importErrorMsg='';
        this._csvHeaders=[]; this._csvData=[]; this._objectFields=[];
        this.showObjSuggestions=false; this.isDragging=false;
    }

    clearImportError() { this.importErrorMsg = ''; }

    // ══════════════════════════════════════════════════════════════════
    // SHOW ALL DATA
    // ══════════════════════════════════════════════════════════════════

    @track recordData      = null;
    @track _fields         = [];
    @track searchTerm      = '';
    @track activeFilter    = FILTER.ALL;
    @track sortField       = SORT.LABEL;
    @track sortAsc         = true;
    @track isLoadingRecord = false;
    @track isSaving        = false;
    @track sadErrorMessage = '';
    @track inputRecordId   = '';   // user types here — NO auto-fetch
    @track toast           = { visible: false, message: '', cssClass: '' };

    // No connectedCallback auto-load — user must press Load Record

    get totalFieldCount()   { return this._fields.length; }
    get editableCount()     { return this._fields.filter(f => f.isUpdateable && !f.isFormula).length; }
    get formulaCount()      { return this._fields.filter(f => f.isFormula).length; }
    get blankCount()        { return this._fields.filter(f => !f.hasValue).length; }
    get dirtyCount()        { return this._fields.filter(f => f.isDirty).length; }
    get isDirty()           { return this.dirtyCount > 0; }
    get noResults()         { return this.filteredFields.length === 0 && !this.isLoadingRecord && !!this.recordData; }
    get sortArrow()         { return this.sortAsc ? '↑' : '↓'; }
    get sortByLabelActive() { return this.sortField === SORT.LABEL; }
    get sortByApiActive()   { return this.sortField === SORT.API; }

    get filterAllClass()      { return this._filterClass(FILTER.ALL); }
    get filterEditableClass() { return this._filterClass(FILTER.EDITABLE); }
    get filterFormulaClass()  { return this._filterClass(FILTER.FORMULA); }
    get filterBlankClass()    { return this._filterClass(FILTER.BLANK); }

    _filterClass(f) { return `sad-filter-btn${this.activeFilter === f ? ' sad-filter-active' : ''}`; }

    get filteredFields() {
        let list = [...this._fields];
        if (this.activeFilter === FILTER.EDITABLE) list = list.filter(f => f.isUpdateable && !f.isFormula);
        else if (this.activeFilter === FILTER.FORMULA) list = list.filter(f => f.isFormula);
        else if (this.activeFilter === FILTER.BLANK)   list = list.filter(f => !f.hasValue);
        if (this.searchTerm.trim()) {
            const term = this.searchTerm.toLowerCase();
            list = list.filter(f => f.label.toLowerCase().includes(term) || f.apiName.toLowerCase().includes(term) || (f.displayValue && f.displayValue.toLowerCase().includes(term)));
        }
        return list.sort((a,b) => {
            const key = this.sortField === SORT.LABEL ? 'label' : 'apiName';
            const cmp = (a[key]||'').localeCompare(b[key]||'');
            return this.sortAsc ? cmp : -cmp;
        });
    }

    handleIdInput(e)   { this.inputRecordId = e.target.value; }
    handleSearch(e)    { this.searchTerm = e.target.value; }
    clearSearch()      { this.searchTerm = ''; }
    handleFilter(e)    { this.activeFilter = e.currentTarget.dataset.filter; }

    handleIdKeyDown(e) { if (e.key === 'Enter') this.handleLoad(); }

    handleLoad() {
        const rid = this.inputRecordId.trim();
        if (!rid) { this.sadErrorMessage = 'Please enter a Record ID.'; return; }
        this._loadRecord(rid);
    }

    async _loadRecord(rid) {
        this.isLoadingRecord = true; this.sadErrorMessage = ''; this.recordData = null; this._fields = [];
        try {
            const data = await getRecordAllData({ recordId: rid });
            this.recordData = data;
            this._fields = data.fields.map(f => this._hydrateField(f));
        } catch(err) {
            this.sadErrorMessage = err?.body?.message || err?.message || 'An unexpected error occurred.';
        } finally { this.isLoadingRecord = false; }
    }

    _hydrateField(f) {
        const hasValue = f.value !== null && f.value !== undefined && f.displayValue !== '';
        return { ...f, hasValue, isEditing: false, isDirty: false, editValue: f.displayValue, rowClass: this._rowClass(f), valueClass: hasValue ? 'sad-value' : 'sad-value sad-value-null' };
    }

    _rowClass(f) {
        if (f.isDirty)       return 'sad-row sad-row-dirty';
        if (f.isFormula)     return 'sad-row sad-row-formula';
        if (!f.isUpdateable) return 'sad-row sad-row-readonly';
        return 'sad-row';
    }

    sortByLabel() { if (this.sortField === SORT.LABEL) this.sortAsc = !this.sortAsc; else { this.sortField = SORT.LABEL; this.sortAsc = true; } }
    sortByApi()   { if (this.sortField === SORT.API)   this.sortAsc = !this.sortAsc; else { this.sortField = SORT.API;   this.sortAsc = true; } }

    handleDblClick(e)   { const n = e.currentTarget.dataset.field; const f = this._getField(n); if (!f || !f.isUpdateable) return; this._setField(n, { isEditing: true, editValue: f.displayValue }); }
    handleEditClick(e)  { const n = e.currentTarget.dataset.field; const f = this._getField(n); if (!f) return; this._setField(n, { isEditing: true, editValue: f.displayValue }); }
    handleEditInput(e)  { this._setField(e.currentTarget.dataset.field, { editValue: e.target.value }); }
    handleEditKeyDown(e){ const n = e.currentTarget.dataset.field; if (e.key==='Enter') this._commitEdit(n); if (e.key==='Escape') this._cancelEdit(n); }
    handleEditBlur(e)   { this._commitEdit(e.currentTarget.dataset.field); }

    _commitEdit(apiName) {
        const field = this._getField(apiName); if (!field) return;
        const newVal = field.editValue; const changed = newVal !== field.displayValue;
        this._setField(apiName, { isEditing: false, displayValue: newVal, hasValue: newVal !== null && newVal !== '', isDirty: changed, rowClass: changed ? 'sad-row sad-row-dirty' : this._rowClass(field) });
    }

    _cancelEdit(apiName) { const f = this._getField(apiName); if (!f) return; this._setField(apiName, { isEditing: false, editValue: f.displayValue }); }

    async handleSaveAll() {
        this.isSaving = true;
        const dirty = this._fields.filter(f => f.isDirty); const errors = [];
        for (const f of dirty) {
            try {
                await updateFieldValue({ recordId: this.recordData.recordId, objectApiName: this.recordData.objectApiName, fieldApiName: f.apiName, newValue: f.displayValue });
                this._setField(f.apiName, { isDirty: false, rowClass: 'sad-row' });
            } catch(err) { errors.push(`${f.label}: ${err?.body?.message || err?.message}`); }
        }
        this.isSaving = false;
        if (errors.length) this._showToast('error', 'Save failed: ' + errors.join(' | '));
        else this._showToast('success', `${dirty.length} field(s) saved successfully.`);
    }

    handleDiscardChanges() {
        this._fields = this._fields.map(f => f.isDirty ? { ...f, isDirty: false, displayValue: f.value != null ? String(f.value) : '', rowClass: this._rowClass({...f, isDirty:false}) } : f);
    }

    handleCopyValue(e) {
        const val = e.currentTarget.dataset.value || '';
        if (navigator.clipboard) { navigator.clipboard.writeText(val).then(() => this._showToast('success','Value copied!')).catch(() => this._showToast('error','Copy failed.')); }
        else { const ta = document.createElement('textarea'); ta.value=val; document.body.appendChild(ta); ta.select(); document.execCommand('copy'); document.body.removeChild(ta); this._showToast('success','Value copied!'); }
    }

    _getField(apiName)       { return this._fields.find(f => f.apiName === apiName); }
    _setField(apiName, patch) { this._fields = this._fields.map(f => f.apiName === apiName ? { ...f, ...patch } : f); }

    _showToast(type, message) {
        const map = { success: 'sad-toast sad-toast-success', error: 'sad-toast sad-toast-error' };
        this.toast = { visible: true, message, cssClass: map[type] || 'sad-toast' };
        setTimeout(() => { this.toast = { ...this.toast, visible: false }; }, 3500);
    }
}