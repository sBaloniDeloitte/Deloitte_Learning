import { LightningElement } from 'lwc';

export default class AiSalesInsight extends LightningElement {

    description1 = 'Praveen is a 22-year-old undergraduate admitted to a US university. Since no co-applicant is currently planned, assess parent/guardian availability and repayment capacity.';

    description2 = 'Confirm funding requirement, fee-payment timeline, and co-applicant/collateral options.';

    typedDescription1 = '';
    typedDescription2 = '';

    showNextAction = false;

    showLocation = false;
    showActionPoints = false;

    showPoint1 = false;
    showPoint2 = false;
    showPoint3 = false;
    showPoint4 = false;

    connectedCallback() {
        this.startAnimation();
    }

    startAnimation() {
        let index = 0;

        const interval1 = setInterval(() => {
            this.typedDescription1 =
                this.description1.substring(0, index);

            index++;

            if (index > this.description1.length) {
                clearInterval(interval1);

                setTimeout(() => {
                    this.showNextAction = true;
                    this.showLocation = true;
                    let secondIndex = 0;
                    
                    setTimeout(() => {
                        this.showActionPoints = true;
                        this.showPoint1 = true;
                    }, 400);
                
                    setTimeout(() => {
                        this.showPoint2 = true;
                    }, 800);
                
                    setTimeout(() => {
                        this.showPoint3 = true;
                    }, 1200);
                
                    setTimeout(() => {
                        this.showPoint4 = true;
                    }, 1600);
                    const interval2 = setInterval(() => {

                        this.typedDescription2 =
                            this.description2.substring(0, secondIndex);

                        secondIndex++;

                        if (secondIndex > this.description2.length) {
                            clearInterval(interval2);
                        }

                    }, 20);

                }, 500);
            }

        }, 20);
    }

    zoomLevel = 15; // Adjusted zoom for coordinates accuracy
    
    mapMarkers = [
        {
            location: {
                Street: '1st Floor, All Cargo House, CST Road, Kolivery Village, Vidya Nagari, Kalina, Santacruz East',
                City: 'Mumbai',
                State: 'Maharashtra',
                PostalCode: '400098',
                Country: 'India'
            },
            title: 'Credila Financial Services Limited',
            description: '1st Floor, All Cargo House'
        }
    ];
}