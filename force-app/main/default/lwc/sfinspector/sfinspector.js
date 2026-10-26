import { LightningElement, track } from 'lwc';
import getSuggestions    from '@salesforce/apex/InspectorController.getSuggestions';
import runSoqlQuery      from '@salesforce/apex/InspectorController.runQuery';
import saveQueryApex     from '@salesforce/apex/InspectorController.saveQuery';
import getSavedQueriesApex from '@salesforce/apex/InspectorController.getSavedQueries';
import deleteSavedQueryApex from '@salesforce/apex/InspectorController.deleteSavedQuery';

const BADGE_CLASS = {
    FLD  : 'sug-badge sug-badge-fld',
    OBJ  : 'sug-badge sug-badge-obj',
    KW   : 'sug-badge sug-badge-kw',
    FN   : 'sug-badge sug-badge-fn',
    DATE : 'sug-badge sug-badge-date',
};

export default class SoqlInspector extends LightningElement {

    @track suggestions   = [];
    @track columns       = [];
    @track rows          = [];
    @track isRunning     = false;
    @track errorMessage  = '';
    @track resultSummary = '';

    @track debugInfo   = true;
    @track debugClause = '—';
    @track debugToken  = '—';
    @track debugCursor = 0;
    @track debugObject = '—';

    // Saved queries state
    @track showSavedPanel = false;
    @track savedQueries   = [];

    _query         = '';
    _cursorPos     = 0;
    _selectedIndex = -1;
    _typingTimer   = null;

    // ─────────────────────────────────────────────────────────────────
    // LIFECYCLE
    // ─────────────────────────────────────────────────────────────────

    connectedCallback() {
        // Load saved queries when component mounts
        this._loadSavedQueries();
    }

    renderedCallback() {
        const ta = this._ta();
        if (ta && ta.value !== this._query) ta.value = this._query;
    }

    _ta() { return this.template.querySelector('textarea'); }

    // ─────────────────────────────────────────────────────────────────
    // SAVED QUERIES
    // ─────────────────────────────────────────────────────────────────

    get savedQueryBtnLabel() {
        const count = this.savedQueries.length;
        return `Saved Queries${count > 0 ? ' (' + count + ')' : ''}`;
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
                    ...sq,
                    lastRunFormatted : sq.lastRun ? this._formatDate(sq.lastRun) : ''
                }));
            })
            .catch(err => console.error('[SoqlInspector] getSavedQueries error:', err));
    }

    _formatDate(dtStr) {
        if (!dtStr) return '';
        try {
            const d = new Date(dtStr);
            return d.toLocaleDateString() + ' ' + d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        } catch(e) { return dtStr; }
    }

    // Called after a successful query run — auto-saves query
    _autoSaveQuery(queryText) {
        saveQueryApex({ queryText, queryName: '' })
            .then(() => this._loadSavedQueries())
            .catch(err => console.error('[SoqlInspector] saveQuery error:', err));
    }

    // Load a saved query into the editor
    loadSavedQuery(event) {
        const id = event.currentTarget.dataset.id;
        const sq = this.savedQueries.find(q => q.id === id);
        if (!sq) return;

        this._query = sq.queryText;
        this._cursorPos = sq.queryText.length;
        this.showSavedPanel = false;
        this.suggestions = [];

        const ta = this._ta();
        if (ta) {
            ta.value = sq.queryText;
            ta.setSelectionRange(this._cursorPos, this._cursorPos);
            ta.focus();
        }
    }

    // Delete a saved query
    deleteSavedQuery(event) {
        event.stopPropagation(); // prevent loadSavedQuery from firing
        const id = event.currentTarget.dataset.id;
        deleteSavedQueryApex({ recordId: id })
            .then(() => {
                this.savedQueries = this.savedQueries.filter(q => q.id !== id);
            })
            .catch(err => console.error('[SoqlInspector] deleteSavedQuery error:', err));
    }

    // ─────────────────────────────────────────────────────────────────
    // INPUT HANDLERS
    // ─────────────────────────────────────────────────────────────────

    handleInput(event) {
        const ta = event.target;
        this._query     = ta.value;
        this._cursorPos = ta.selectionStart;
        this._selectedIndex = -1;
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

    // ─────────────────────────────────────────────────────────────────
    // KEYBOARD NAV
    // ─────────────────────────────────────────────────────────────────

    handleKeyDown(event) {
        const hasSugs = this.suggestions.length > 0;
        if (event.key === 'Escape') { this.suggestions = []; this._selectedIndex = -1; return; }
        if (!hasSugs) {
            if (event.key === 'Enter' && (event.ctrlKey || event.metaKey)) {
                event.preventDefault(); this.runQuery();
            }
            return;
        }
        if (event.key === 'Tab' && !event.shiftKey) { event.preventDefault(); this._move(1);  return; }
        if (event.key === 'Tab' &&  event.shiftKey) { event.preventDefault(); this._move(-1); return; }
        if (event.key === 'ArrowRight') { event.preventDefault(); this._move(1);  return; }
        if (event.key === 'ArrowLeft')  { event.preventDefault(); this._move(-1); return; }
        if (event.key === 'Enter' && this._selectedIndex >= 0) {
            event.preventDefault(); this._applyByIndex(this._selectedIndex);
        }
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

    _itemClass(active) {
        return `suggestion-item${active ? ' suggestion-item_active' : ''}`;
    }

    // ─────────────────────────────────────────────────────────────────
    // FETCH SUGGESTIONS
    // ─────────────────────────────────────────────────────────────────

    _fetchSuggestions() {
        const q = this._query, pos = this._cursorPos;
        if (!q || !q.trim()) { this.suggestions = []; this._resetDebug(); return; }

        const { clause, token, objectName } = this._localContext(q, pos);
        this.debugClause = clause;
        this.debugToken  = token  || '(empty)';
        this.debugCursor = pos;
        this.debugObject = objectName || '(not found)';

        getSuggestions({ query: q, cursorPosition: pos })
            .then(res => {
                this.suggestions = (res || []).map((raw, i) => this._shape(raw, i));
            })
            .catch(err => {
                console.error('[SoqlInspector] getSuggestions error:', JSON.stringify(err));
                this.suggestions = [];
            });
    }

    _localContext(q, pos) {
        const textBeforeCursor = q.substring(0, pos);
        return {
            clause     : this._detectClause(textBeforeCursor.toUpperCase()),
            token      : this._activeToken(q, pos),
            objectName : this._extractObject(q)
        };
    }

    _detectClause(upperText) {
        const clauses = ['SELECT','FROM','WHERE','ORDER BY','GROUP BY','HAVING','LIMIT','OFFSET'];
        let winner = 'UNKNOWN', winPos = -1;
        for (const kw of clauses) {
            const p = this._lastWholeWord(upperText, kw);
            if (p > winPos) { winPos = p; winner = kw; }
        }
        return winner;
    }

    _lastWholeWord(upperText, kw) {
        let pos = -1, start = 0;
        while (true) {
            const idx = upperText.indexOf(kw, start);
            if (idx === -1) break;
            const pre  = idx === 0 || /[\s,\n\t(]/.test(upperText[idx - 1]);
            const post = (idx + kw.length >= upperText.length) || /[\s,\n\t(]/.test(upperText[idx + kw.length]);
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

    _extractObject(q) {
        const m = q.match(/\bFROM\s+(\w+)/i);
        return m ? m[1] : null;
    }

    // ─────────────────────────────────────────────────────────────────
    // SHAPE
    // ─────────────────────────────────────────────────────────────────

    _shape(raw, i) {
        const value  = typeof raw === 'string' ? raw : (raw.value  || '');
        const label  = typeof raw === 'string' ? raw : (raw.label  || value);
        const type   = typeof raw === 'string' ? 'FLD' : (raw.type || 'FLD');
        const detail = typeof raw === 'string' ? ''    : (raw.detail || '');
        return {
            key        : value + '_' + i,
            value, label, type, detail,
            badgeClass : BADGE_CLASS[type] || 'sug-badge',
            cssClass   : this._itemClass(i === this._selectedIndex)
        };
    }

    // ─────────────────────────────────────────────────────────────────
    // APPLY SUGGESTION
    // ─────────────────────────────────────────────────────────────────

    applySuggestion(event) {
        event.preventDefault();
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        this._applyByIndex(isNaN(idx) ? 0 : idx);
    }

    _applyByIndex(idx) {
        const s = this.suggestions[idx];
        if (!s) return;
        const { newQuery, newCursor } = this._buildNewQuery(this._query, s.value, this._cursorPos);
        this._query = newQuery; this._cursorPos = newCursor;
        this.suggestions = []; this._selectedIndex = -1;
        const ta = this._ta();
        if (ta) { ta.value = newQuery; ta.setSelectionRange(newCursor, newCursor); ta.focus(); }
        clearTimeout(this._typingTimer);
        this._typingTimer = setTimeout(() => this._fetchSuggestions(), 80);
    }

    _buildNewQuery(q, value, cursor) {
        // Left-walk: stop at whitespace OR comma (dot is NOT a stop char)
        let tokenStart = cursor;
        while (tokenStart > 0 && !/[\s,\n\t]/.test(q[tokenStart - 1])) tokenStart--;

        // Right-walk: stop at whitespace OR comma
        let tokenEnd = cursor;
        while (tokenEnd < q.length && !/[\s,\n\t]/.test(q[tokenEnd])) tokenEnd++;

        const activeToken = q.substring(tokenStart, cursor); // e.g. "Loan_Application__r.Stage"
        const suffix      = q.substring(cursor, tokenEnd);   // e.g. "Name"
        const fullToken   = activeToken + suffix;             // e.g. "Loan_Application__r.StageName"
        const clause      = this._detectClause(q.substring(0, cursor).toUpperCase());
        const prefix      = q.substring(0, tokenStart);      // e.g. "SELECT id,"

        // KEY FIX: if activeToken has a dot (relationship traversal) and the
        // suggestion value is just a plain field name (no dot), we must
        // reconstruct the full "RelName.FieldName" so the relationship prefix
        // is NOT wiped out on selection.
        //
        // Example:
        //   activeToken = "Loan_Application__r.Stage"   lastDot = 20
        //   value       = "StageName"
        //   relPrefix   = "Loan_Application__r."
        //   inserted    = "Loan_Application__r.StageName"  ✓

        const lastDot = activeToken.lastIndexOf('.');
        let inserted;

        if (value.endsWith('.')) {
            // Relationship suggestion e.g. "Loan_Application__r." — cursor after dot
            inserted = value;
        } else if (lastDot >= 0 && !value.includes('.')) {
            // Child field selected — prepend the relationship prefix
            const relPrefix = activeToken.substring(0, lastDot + 1);
            inserted = relPrefix + value;
        } else if (clause === 'FROM') {
            inserted = value + ' ';
        } else if (['SELECT','WHERE','ORDER BY','GROUP BY','HAVING'].includes(clause)) {
            inserted = value;
        } else {
            inserted = value + ' ';
        }

        // When a dot is present, always consume the full token (tokenStart→tokenEnd)
        // so the old "Stage" suffix doesn't remain after "StageName" is inserted.
        // For plain fields, only consume suffix when it matches the suggestion.
        let rest;
        if (lastDot >= 0) {
            rest = q.substring(tokenEnd);
        } else {
            const consumeSuffix = value.toUpperCase() === fullToken.toUpperCase()
                               || value.toUpperCase().startsWith(fullToken.toUpperCase())
                               || fullToken.toUpperCase().startsWith(value.toUpperCase());
            rest = q.substring(consumeSuffix ? tokenEnd : cursor);
        }

        return { newQuery: prefix + inserted + rest, newCursor: prefix.length + inserted.length };
    }

    // ─────────────────────────────────────────────────────────────────
    // RUN QUERY
    // ─────────────────────────────────────────────────────────────────

    runQuery() {
        const q = this._query.trim();
        if (!q) { this.errorMessage = 'Please enter a SOQL query.'; return; }

        this.isRunning = true; this.errorMessage = ''; this.resultSummary = '';
        this.columns = []; this.rows = [];

        runSoqlQuery({ query: q })
            .then(res => {
                this._processResults(res);
                // Auto-save the query after successful run
                this._autoSaveQuery(q);
            })
            .catch(err => {
                this.errorMessage = 'Query failed: ' +
                    (err?.body?.message || err?.message || 'Unknown error');
            })
            .finally(() => { this.isRunning = false; });
    }

    _processResults(records) {
        if (!records || records.length === 0) {
            this.resultSummary = '0 records returned.'; return;
        }
        const colSet = new Set();
        records.forEach(rec => Object.keys(rec).forEach(k => colSet.add(k)));
        const excluded = new Set(['attributes']);
        this.columns = [...colSet].filter(k => !excluded.has(k));
        const base = window.location.origin;
        this.rows = records.map((rec, ri) => ({
            _key  : rec['Id'] || String(ri),
            cells : this.columns.map(col => {
                const v   = rec[col];
                const str = v == null ? '' : String(v);
                const isId = col === 'Id' && typeof v === 'string' && v.length === 18;
                return { col, value: str, isLink: isId, href: isId ? `${base}/${v}` : null };
            })
        }));
        this.resultSummary = `${records.length} record${records.length !== 1 ? 's' : ''} returned.`;
    }

    // ─────────────────────────────────────────────────────────────────
    // DOWNLOAD EXCEL
    // ─────────────────────────────────────────────────────────────────

    downloadExcel() {
        if (!this.columns.length || !this.rows.length) {
            this.errorMessage = 'No results to download.'; return;
        }

        // Build CSV with UTF-8 BOM so Excel opens special chars correctly
        const esc      = val => '"' + String(val == null ? '' : val).replace(/"/g, '""') + '"';
        const header   = this.columns.map(esc).join(',');
        const dataRows = this.rows.map(row => row.cells.map(c => esc(c.value)).join(','));
        const csv      = '\uFEFF' + [header, ...dataRows].join('\r\n');

        const objMatch  = this._query.match(/\bFROM\s+(\w+)/i);
        const ts        = new Date().toISOString().slice(0, 19).replace(/[T:]/g, '-');
        const fileName  = (objMatch ? objMatch[1] : 'results') + '_' + ts + '.csv';

        try {
            // PRIMARY: use hidden anchor already in template
            // revokeObjectURL must be DEFERRED (setTimeout) — calling it synchronously
            // cancels the blob before the browser downloads it
            const blob   = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
            const url    = URL.createObjectURL(blob);
            const anchor = this.template.querySelector('.download-anchor');
            anchor.setAttribute('href', url);
            anchor.setAttribute('download', fileName);
            anchor.click();
            // Revoke after a short delay to ensure browser has processed the click
            setTimeout(() => URL.revokeObjectURL(url), 2000);
        } catch(e) {
            // FALLBACK: use data URI (no blob URL needed, works in all browsers)
            const encoded  = encodeURIComponent(csv);
            const dataUri  = 'data:text/csv;charset=utf-8,' + encoded;
            const anchor   = this.template.querySelector('.download-anchor');
            anchor.setAttribute('href', dataUri);
            anchor.setAttribute('download', fileName);
            anchor.click();
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // FORMAT / CLEAR
    // ─────────────────────────────────────────────────────────────────

    formatQuery() {
        if (!this._query.trim()) return;
        const CLAUSES = ['SELECT','FROM','WHERE','ORDER BY','GROUP BY','HAVING','LIMIT','OFFSET'];
        let q = this._query.trim().replace(/\s+/g, ' ');
        CLAUSES.forEach(kw => {
            q = q.replace(new RegExp(`\\b${kw}\\b`, 'gi'), '\n' + kw.toUpperCase());
        });
        this._query = q.trimStart();
        const ta = this._ta();
        if (ta) ta.value = this._query;
    }

    clearAll() {
        this._query = ''; this._cursorPos = 0; this._selectedIndex = -1;
        this.suggestions = []; this.columns = []; this.rows = [];
        this.errorMessage = ''; this.resultSummary = '';
        this._resetDebug();
        const ta = this._ta();
        if (ta) { ta.value = ''; ta.focus(); }
    }

    clearError() { this.errorMessage = ''; }

    _resetDebug() {
        this.debugClause = '—'; this.debugToken = '—';
        this.debugCursor = 0;   this.debugObject = '—';
    }

    get hasSuggestions() { return this.suggestions && this.suggestions.length > 0; }
    get hasResults()     { return this.rows && this.rows.length > 0; }
}