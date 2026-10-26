/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class QuickActionsPanel extends NavigationMixin(LightningElement) {

    // -----------------------------
    // Button 1: opens the Student Loan EMI Calculator modal
    // -----------------------------
    handleCalculateEmi() {
        const calculator = this.template.querySelector(
            'c-student-loan-emi-calculator'
        );
        if (calculator) {
            calculator.openModal();
        }
    }

    // -----------------------------
    // "Create Lead" button: notify the host page/flow via CustomEvent
    // and navigate to the "Lead_Creation_New" Lightning Page (FlexiPage)
    // so users land on the dedicated lead creation experience.
    // -----------------------------
    // handleCreateLead() {
    //     this.dispatchEvent(new CustomEvent('createlead'));
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__navItemPage',
    //         attributes: {
    //             apiName: 'Lead_Creation_New'
    //         }
    //     });
    // }
    handleCreateLead() {
    window.open('/lightning/n/Lead_Creation', '_blank');
}

    handleStartApplication() {
        this.dispatchEvent(new CustomEvent('startapplication'));
    }

    handleCreateTask() {
        this.dispatchEvent(new CustomEvent('createtask'));
    }

    handleScheduleMeeting() {
        this.dispatchEvent(new CustomEvent('schedulemeeting'));
    }
}
/*__________________________GenAI: Generated code ends here______________________________*/