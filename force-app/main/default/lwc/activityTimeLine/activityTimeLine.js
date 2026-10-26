import { LightningElement, api, wire } from 'lwc';
import getActivities from '@salesforce/apex/ActivityTimelineControllerNew.getActivities';

export default class ActivityTimeline extends LightningElement {

    @api recordId;
    activities = [];

    @wire(getActivities, { recordId: '$recordId' })
    wiredActivities({ error, data }) {

        const staticActivities = [
            {
                id: 'static1',
                subject: 'Lead Captured',
                description:
                    'Education loan enquiry received successfully and lead record created.',
                type: 'Task',
                activityDate: '2026-08-21T09:00:00'
            },
            {
                id: 'static2',
                subject: 'Branch Assigned',
                description:
                    'Lead has been assigned to the respective branch for further processing.',
                type: 'Call',
                activityDate: '2026-08-21T10:30:00'
            },
            {
                id: 'static3',
                subject: 'Eligibility Assessment Initiated',
                description:
                    'Initial evaluation of applicant profile and loan eligibility has started.',
                type: 'Email',
                activityDate: '2026-08-21T12:00:00'
            }
        ];

        let allActivities = [...staticActivities];

        if (data && data.length > 0) {
            allActivities = [...staticActivities, ...data];
        }

        if (error) {
            console.error(error);
        }

        this.activities = allActivities.map(item => {

            let iconName;
            let iconClass;

            switch (item.type) {

                case 'Call':
                    iconName = 'standard:log_a_call';
                    iconClass = 'icon call';
                    break;

                case 'Email':
                    iconName = 'standard:email';
                    iconClass = 'icon email';
                    break;

                case 'Meeting':
                    iconName = 'standard:event';
                    iconClass = 'icon meeting';
                    break;

                default:
                    iconName = 'standard:task';
                    iconClass = 'icon task';
            }

            return {
                ...item,
                iconName,
                iconClass,
                formattedDate: new Intl.DateTimeFormat(
                    'en-IN',
                    {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                    }
                ).format(new Date(item.activityDate))
            };
        });

        this.activities.sort(
            (a, b) =>
                new Date(b.activityDate) -
                new Date(a.activityDate)
        );
    }

    get activityCount() {
        return this.activities.length;
    }
}