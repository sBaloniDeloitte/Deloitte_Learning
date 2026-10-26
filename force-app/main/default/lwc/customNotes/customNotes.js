import { LightningElement, track } from 'lwc';

export default class customNotes extends LightningElement {

    noteText = '';

    @track notes = [
        {
            id: 1,
            author: 'Akash Sharma',
            date: 'Today, 10:59',
            message: 'Called the co-applicant to confirm the July salary slip discrepancy. He is checking with HR and will revert tomorrow.',
            isNew: false
        },
        {
            id: 2,
            author: 'Akash Sharma',
            date: '16 Aug 2026, 10:59',
            message: 'First discovery call done. Family is set on Fall 2026 intake, offer letter already in hand. Good lead.',
            isNew: false
        }
    ];

    handleChange(event) {
        this.noteText = event.target.value;
    }

    handleClear() {
        this.noteText = '';
    }

    handleSave() {

        const value = this.noteText?.trim();

        if (!value) {
            return;
        }

        this.notes = this.notes.map(note => ({
            ...note,
            isNew: false
        }));

        const now = new Date();

        const newNote = {
            id: Date.now(),
            author: 'Akash Sharma',
            date: now.toLocaleString('en-IN', {
                day: 'numeric',
                month: 'short',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            }),
            message: value,
            isNew: true
        };

        this.notes = [newNote, ...this.notes];

        this.noteText = '';
    }

    get charCount() {
        return this.noteText ? this.noteText.length : 0;
    }
}