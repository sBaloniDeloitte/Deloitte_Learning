import { LightningElement,api,track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpportunitiesForLWC from '@salesforce/apex/COMM_LoanSchedulerContoller.getOpportunitiesForLWC';
import initiateAPIRequest from '@salesforce/apex/COMM_LoanSchedulerContoller.initiateAPIRequest';
import fetchSchedule from "@salesforce/apex/COMM_RepaymentScheduleController.fetchSchedule";
import saveOppStageChange from "@salesforce/apex/COMM_RepaymentScheduleController.saveOppStageChange";
import checkRepaymentScheduleAPI from "@salesforce/apex/COMM_RepaymentScheduleController.checkRepaymentScheduleAPI";
import getProductNameForLoan from "@salesforce/apex/COMM_RepaymentScheduleController.getProductNameForLoan";
import canUserEdit from '@salesforce/apex/COMM_RepaymentScheduleController.canUserEdit';
import { getRecord } from 'lightning/uiRecordApi';
const FIELDS = [
    'Opportunity.Variant__c',
    'Opportunity.Sub_stage__c',
    'Opportunity.StageName'

];

export default class RepaymentScheduleCmp extends LightningElement {
@api recordId;
@track isRendered = false;
@track spinner = false;
showInitiateButton = true;
@track schedules = [];
variantValue;
@track sanctionedLoanAmount;
isVariantValueBD = false;
isVariantValueTermLoan = false;
@track isLoading=false;
@track showRefreshButton = false;
@track regenerateSchedule = false;
disableGenerateSch = false;
@track showGenerateButton = false;
loanStage='';
dontShowForOps = false;
@track disableForDisbursement = false;
isButtonVisible = true;

@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
wiredRecord({ error, data }) {
    if (data) {
        if(data.fields.Sub_stage__c.value == 'Ops Author'){
            this.dontShowForOps = true;
        }
        if(data.fields.StageName.value == 'Disbursement'){
            this.disableForDisbursement = true;
        }
        if(data.fields.Sub_stage__c.value == 'PSV Credit'){
            this.isButtonVisible = false;
        }
    } else if (error) {
        console.error('Error fetching record:', error);
    }
}

/*@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
wiredRecord({ error, data }) {
    if (data) {
        this.variantValue = data.fields.Variant__c.value;
        if(this.variantValue === 'Overdraft'){
        this.isVariantValueBD = true;
        this.isVariantValueTermLoan = false;
        }
        else if(this.variantValue === 'Term Loan'){
        this.isVariantValueTermLoan = true;
        this.isVariantValueBD = false;
        }
    } else if (error) {
        console.error('Error fetching record:', error);
    }
}*/
      
connectedCallback() {
    /*canUserEdit({ opportunityId: this.recordId })
        .then(result => {
            this.disableGenerateSch = !result;
        })
        .catch(error => {
            this.disableGenerateSch = true;
        });*/

    // Always show Generate button in Test Env
    

    this.fetchVariantBasedOnProduct();
}
hanldeGenerate(event) {

    this.showGenerateButton = false;
    this.regenerateSchedule = true;

    this.invokeLoanScheduleAPI();
}

fetchVariantBasedOnProduct() {
    getProductNameForLoan({ oppId: this.recordId })
        .then(variantRec => {
            console.log('Fetched Variant Record:', JSON.stringify(variantRec));
            const variantName = (variantRec?.Name || '').trim().toLowerCase();
            if (variantName === 'term loan') {
                this.variantValue = 'Term Loan';
                this.isVariantValueTermLoan = true;
                this.isVariantValueBD = false;
            } else if (variantName === 'flexi funds' || variantName === 'overdraft') {
                this.variantValue = 'Overdraft';
                this.isVariantValueBD = true;
                this.isVariantValueTermLoan = false;
                console.log('this.isVariantValueBD:: ' + this.isVariantValueBD);
            } else {
                this.variantValue = '';
                this.isVariantValueBD = false;
                this.isVariantValueTermLoan = false;
            }
            this.sanctionedLoanAmount = variantRec?.Product__r?.Sanctioned_Loan_Amount__c ?? null;
            this.handleLoanScheduleAPI();
        })
        .catch(error => {
            console.error('Error fetching product variant record:', error);
            this.variantValue = '';
            this.isVariantValueBD = false;
            this.isVariantValueTermLoan = false;
        });
}



@track isLoanRescheduleAPIInvoked = false;
@track showMessage = false;

@track infoMessage = ''; // For displaying approval in progress message
async handleLoanScheduleAPI() {
    try {
        const response = await checkRepaymentScheduleAPI({ recordId: this.recordId });
        console.log('API Response:', JSON.stringify(response));
        // Reset states
        this.infoMessage = '';
        this.showGenerateButton = false;
        // Handle response
        if (response.shouldHitAPI) {
            // Show Generate button when API needs to be hit
            this.showGenerateButton = true;
            this.isLoanRescheduleAPIInvoked = false;
        }else {
            console.log('response.message----'+response.message);
            // If shouldHitAPI is false, either approval is pending or schedule exists
            if (response.message) {
                this.infoMessage = response.message;
                this.showGenerateButton = false;
                this.isLoanRescheduleAPIInvoked = false; // No schedule yet, approval pending
                this.showMessage = true;
            } else {
                console.log('response.message----'+response.message);

                this.showGenerateButton = false;
                this.regenerateSchedule = true;
                this.isLoanRescheduleAPIInvoked = true;

                this.loadSchedules();
            }
        }
    } catch (error) {
        this.showToast('Error', error.body.message, 'error');
    }
}

invokeLoanScheduleAPI() {
    this.isLoading = true; // Show spinner when API call starts
    let inputMap = {
        loanId: this.recordId,
        processName: 'Loan Scheduler Create Charges'
    };

    // Query Opportunity Records
    getOpportunitiesForLWC({ recordId: this.recordId })
        .then(oppList => {
            if (oppList.length === 0) {
                this.showToast('Error', 'No Opportunities found', 'error');
                return;
            }

            // Call Apex API with retrieved opportunities
            initiateAPIRequest({ inputMap: inputMap, oppList: oppList, invocationType: 'RepaymentLWC'})
                .then(response => {
                    console.log('API Response 1:', response);
                    //this.showToast('API Response', response, 'info');
                    if (response && response === 'Success') {
                        this.showToast('Success', 'API executed successfully!', 'success');
                        this.isLoanRescheduleAPIInvoked = true;
                        this.showGenerateButton = false;
                        this.regenerateSchedule = true;
                        this.loadSchedules();
                    } else {
                        let errorMessage = response;
                        this.showToast('Error', errorMessage, 'error');
                        this.isLoanRescheduleAPIInvoked = false;
                        this.showGenerateButton = true;
                    }
                    this.isLoading = false;
                })
                .catch(error => {
                    console.error('Error calling API:', error);
                    let errorMessage = error.body ? error.body.message : 'Unknown error';
                    this.showToast('Error', errorMessage, 'error');
                    this.isLoanRescheduleAPIInvoked = false;
                    this.isLoading = false;
                });
        })
        .catch(error => {
            console.error('Error fetching Opportunities:', error);
            this.showToast('Error', 'Failed to fetch Opportunities', 'error');
            this.isLoading = false;
        });
}

formatDate(dateStr) {
    const dateObj = new Date(dateStr);
    const day = String(dateObj.getDate()).padStart(2, '0');
    const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    const month = monthNames[dateObj.getMonth()];
    const year = dateObj.getFullYear();
    return `${day}-${month}-${year}`;
}

loadSchedules() {
    console.log('response.message 281');
    fetchSchedule({ recordId: this.recordId })
        .then(result => {
            if (result){
                console.log('this.schedules ------'+JSON.stringify(result));
                //this.spinner = false;
                const endBalCheck = result.find(s => s?.specifier === 'E');
                if (endBalCheck) {
                    const endBal = Number(endBalCheck.endBal ?? 0);
                    const sanctioned = Number(this.sanctionedLoanAmount ?? 0);
                    if ( endBal > sanctioned) {
                        this.schedules = [];
                        this.showToast('Error',`Kindly note that that the Ending balance (${endBal}) at Grace end terms is greater than the sanctioned loan amount (${sanctioned}). Please edit the first disbursement amount accordingly.`,'error');
                        return;
                    }
                    else{
                        this.schedules = result.map((item, index) => {
                        return {...item,
                        schDateFormatted: this.formatDate(item.schDate),
                        schDueDateFormatted: index === 0 || !item.dueDate ? null : this.formatDate(item.dueDate)
                        };
                        });
                        console.log('this.schedules ------'+JSON.stringify(this.schedules));
                    }
                }
                else{
                    this.schedules = result.map((item, index) => {
                    return {...item,
                    schDateFormatted: this.formatDate(item.schDate),
                    schDueDateFormatted: index === 0 || !item.dueDate ? null : this.formatDate(item.dueDate)
                    };
                    });
                    console.log('this.schedules ------'+JSON.stringify(this.schedules));
                }

                this.showToast('Success', 'Records Fetched Successfully', 'success');
                console.log('result==>', JSON.stringify(this.schedules, null, 2));
            }
            else{
                this.showToast('Error', 'No RPS Found. Kindly generate again. In case of issues, Contact the Admin please!', 'error');
            }

        })
        .catch(error => {
            //this.spinner = false;
            console.error('Error fetching schedules:', error);
            this.showToast('Error', 'Error in fetching Records'+error.body.message, 'error');
        });
    }

changeStage(event){
    this.loanStage='Disbursement';
    saveOppStageChange({ recordId: this.recordId,loanStage: this.loanStage})
    .then(() => {
    this.showToast('Success', 'Send to Ops Maker', 'success');
    window.location.reload()
    })
    .catch(error => {
    console.error('Error saving records:', error);
    this.showToast('Error', 'Error in changing stage'+error.body.message, 'error');
    });
}

showToast(title, message, variant) {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant, // Accepts 'success', 'info', 'warning', or 'error'
        mode: 'pester' // Can be 'dismissable', 'pester', or 'sticky'
    });
    this.dispatchEvent(event);
}

}