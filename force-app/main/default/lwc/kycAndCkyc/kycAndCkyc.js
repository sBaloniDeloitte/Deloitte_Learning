import { LightningElement } from 'lwc';

export default class KycAndCkyc extends LightningElement {

    items = [
        {
            id: 1,
            title: 'Rajesh Kumar — CKYC 60123456789012',
            subtitle: 'Re-KYC due Mar 2027',
            status: 'Complete',
            badgeClass: 'status-pill complete'
        },
        {
            id: 2,
            title: 'Praveen Verma — CKYC 60987654321098',
            subtitle: 'Re-KYC due Aug 2028',
            status: 'Complete',
            badgeClass: 'status-pill complete'
        },
        {
            id: 3,
            title: 'FATCA declaration',
            subtitle: 'Not applicable · neither party is NRI',
            status: 'N/A',
            badgeClass: 'status-pill na'
        }
    ];
}