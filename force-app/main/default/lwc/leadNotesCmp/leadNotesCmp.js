/*
 * @description : Static "Notes" popup - lets a sales agent add and browse
 *                 conversation/follow-up notes for a Home Loan lead (visual
 *                 only, no Apex/DB write). Themed to match the dark
 *                 navy/purple leadCustomHeader gradient.
 * @author       : ChangeMeIn@UserSettingsUnder.SFDoc
 */
import { LightningElement } from 'lwc';

const MAX_LENGTH = 500;

export default class LeadNotesCmp extends LightningElement {
    noteText = '';
    maxLength = MAX_LENGTH;

    /* ____GenAI: static Home Loan themed notes matching the reference
       screenshot's layout (author, timestamp, note text) - content adapted
       from the education-loan reference to a home-loan conversation
       context____ */
    notes = [
        {
            id: 'n1',
            author: 'Abhilash Saini',
            date: 'Today, 10:59',
            text: "Called the co-applicant to confirm the July salary slip discrepancy. He is checking with HR and will revert tomorrow."
        },
        {
            id: 'n2',
            author: 'Abhilash Saini',
            date: '16 Aug 2026, 10:59',
            text: "First discovery call done. Customer is looking for a home loan against a resale flat in Dadar, sanction letter target end of month. Good lead."
        }
    ];

    get charCount() {
        return `${this.noteText.length}/${this.maxLength}`;
    }

    get isSaveDisabled() {
        return !this.noteText || !this.noteText.trim();
    }

    /* ____GenAI: Clear button is only enabled when there is text in the
       textarea - mirrors the same "only enabled when text exists" rule
       already used for Save Note____ */
    get isClearDisabled() {
        return !this.noteText || !this.noteText.trim();
    }

    handleNoteChange(event) {
        this.noteText = event.target.value;
    }

  handleClear() {
    this.noteText = '';

    const textarea = this.template.querySelector('.notes-textarea');
    if (textarea) {
        textarea.value = '';
    }
}

    handleSave() {
        if (this.isSaveDisabled) {
            return;
        }
        const newNote = {
            id: 'n' + Date.now(),
            author: 'Akash Sharma',
            date: 'Just now',
            text: this.noteText.trim()
        };
        this.notes = [newNote, ...this.notes];
        this.noteText = '';
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    // stop clicks inside the card from bubbling to the backdrop and closing the modal
    handleModalClick(event) {
        event.stopPropagation();
    }
}