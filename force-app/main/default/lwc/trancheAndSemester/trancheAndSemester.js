import { LightningElement } from 'lwc';

export default class TrancheAndSemester extends LightningElement {

    semesterCards = [
        {
            id: 1,
            label: 'Tranche 1',
            amount: '₹9.5L',
            className: 'semester-card completed'
        },
        {
            id: 2,
            label: 'Tranche 2',
            amount: '₹9.5L',
            className: 'semester-card completed'
        },
        {
            id: 3,
            label: 'Tranche 3',
            amount: '₹9.5L',
            className: 'semester-card due'
        },
        {
            id: 4,
            label: 'Tranche 4',
            amount: '₹9.5L',
            className: 'semester-card upcoming'
        }
    ];

    semesterDetails = [
        {
            id: 1,
            semester: 'Tranche 1',
            amount: '₹9,50,000',
            status: 'Released',
            statusClass: 'status released',
            condition: 'Offer letter, margin proof'
        },
        {
            id: 2,
            semester: 'Tranche 2',
            amount: '₹9,50,000',
            status: 'Released',
            statusClass: 'status released',
            condition: 'Semester 1 results'
        },
        {
            id: 3,
            semester: 'Tranche 3',
            amount: '₹9,50,000',
            status: 'Due 15 Sep',
            statusClass: 'status due-pill',
            condition: 'Results and fee receipt'
        },
        {
            id: 4,
            semester: 'Tranche 4',
            amount: '₹9,50,000',
            status: 'Scheduled',
            statusClass: 'status scheduled',
            condition: 'Results'
        }
    ];
}