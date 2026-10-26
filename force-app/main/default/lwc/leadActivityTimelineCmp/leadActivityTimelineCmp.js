/*
 * @description : Static "Activity Timeline" popup - shows a read-only feed
 *                 of recent customer interactions for a Home Loan lead
 *                 (visual only, no Apex/DB read). Themed to match the dark
 *                 navy/purple leadCustomHeader / leadNotesCmp gradient.
 * @author       : ChangeMeIn@UserSettingsUnder.SFDoc
 */
import { LightningElement } from 'lwc';

export default class LeadActivityTimelineCmp extends LightningElement {

    /* ____GenAI: static Home Loan themed activity feed matching the
       reference screenshot's card layout (icon, title, description,
       timestamp), most recent activity first____ */
    activities = [
        {
            id: 'act1',
            title: 'Disposition Updated',
            description: 'Lead disposition marked as Documents Pending, pending final verification from the applicant.',
            date: '14 Sept 2026, 03:15 pm',
            icon: 'utility:flag',
            iconClass: 'lat-icon-circle lat-icon-circle_purple'
        },
        {
            id: 'act2',
            title: 'Documents Uploaded',
            description: 'Applicant uploaded income proof and KYC documents required for home loan processing.',
            date: '14 Sept 2026, 02:15 pm',
            icon: 'utility:file',
            iconClass: 'lat-icon-circle lat-icon-circle_blue'
        },
        {
            id: 'act3',
            title: 'WhatsApp - Branch Assignment',
            description: "WhatsApp message sent successfully. Message Type: BRANCH_CHANGE Recipient: 8780790973 Message: Hi Abhilash Saini - A lead has been assigned to you. Lead details are as below. Lead Name: Gaurav Kumar Mobile number: 9823421265 Lead priority: Hot.",
            date: '14 Sept 2026, 12:34 pm',
            icon: 'utility:chat',
            iconClass: 'lat-icon-circle lat-icon-circle_green'
        },
        {
            id: 'act4',
            title: 'Eligibility Assessment Initiated',
            description: 'Initial evaluation of applicant profile and home loan eligibility has started.',
            date: '21 Aug 2026, 12:00 pm',
            icon: 'utility:preview',
            iconClass: 'lat-icon-circle lat-icon-circle_blue'
        },
        {
            id: 'act5',
            title: 'Branch Assigned',
            description: 'Lead has been assigned to the respective branch for further processing.',
            date: '21 Aug 2026, 10:30 am',
            icon: 'utility:company',
            iconClass: 'lat-icon-circle lat-icon-circle_green'
        },
        {
            id: 'act6',
            title: 'Lead Captured',
            description: 'Home loan enquiry received successfully and lead record created.',
            date: '21 Aug 2026, 09:00 am',
            icon: 'utility:add',
            iconClass: 'lat-icon-circle lat-icon-circle_purple'
        }
    ];

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    // stop clicks inside the card from bubbling to the backdrop and closing the modal
    handleModalClick(event) {
        event.stopPropagation();
    }
}