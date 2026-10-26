import { LightningElement } from 'lwc';

export default class MayDay extends LightningElement {

    metricCards = [
        {
            id: 1,
            label: 'ACTIVE LEADS',
            value: '42',
            subtitle: '+12% this week',
            subtitleClass: 'metric-subtitle metric-subtitle-trend'
        },
        {
            id: 2,
            label: 'PENDING TASKS',
            value: '8',
            subtitle: '3 due today',
            subtitleClass: 'metric-subtitle'
        },
        {
            id: 3,
            label: 'MEETINGS TODAY',
            value: '3',
            subtitle: '2 completed',
            subtitleClass: 'metric-subtitle'
        },
        {
            id: 4,
            label: 'PIPELINE VALUE',
            value: '₹ 3.2 Cr',
            subtitle: 'High-value deals',
            subtitleClass: 'metric-subtitle'
        },
        {
            id: 5,
            label: 'NEW APPLICATIONS',
            value: '14',
            subtitle: 'Last 24 hrs',
            subtitleClass: 'metric-subtitle'
        },
        {
            id: 6,
            label: 'APPROVALS PENDING',
            value: '6',
            subtitle: 'Needs RM action',
            subtitleClass: 'metric-subtitle'
        }
    ];

    handleCardClick(event) {
        const cardId = event.currentTarget.dataset.id;

        console.log('Card clicked:', cardId);
    }

    handleActionClick(event) {
        const action = event.currentTarget.dataset.action;

        console.log('Action clicked:', action);
    }
}