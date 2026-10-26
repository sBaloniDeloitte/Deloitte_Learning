import { LightningElement } from 'lwc';

export default class EarlyWarnings extends LightningElement {

    warnings = [
        {
            id: 1,
            title: 'Academic backlog on semester 1',
            subtitle: 'Raised 28 Jun · affects tranche 3 release',
            icon: 'utility:warning',
            iconWrapperClass: 'icon-circle critical'
        },
        {
            id: 2,
            title: 'Co-applicant FOIR crossed 40%',
            subtitle: 'New vehicle loan in Jan 2026',
            icon: 'utility:warning',
            iconWrapperClass: 'icon-circle warning'
        },
        {
            id: 3,
            title: 'Course extension shifts repayment',
            subtitle: 'Six months of extra interest accrual',
            icon: 'utility:warning',
            iconWrapperClass: 'icon-circle warning'
        },
        {
            id: 4,
            title: 'Tranche 3 due in 26 days',
            subtitle: 'Conditions not yet met',
            icon: 'utility:circle',
            iconWrapperClass: 'icon-circle info'
        }
    ];
}