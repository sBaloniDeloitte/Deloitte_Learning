import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import callStageChangeAPEX from '@salesforce/apex/AHL_LoanApplicationActionController.callStageChangeAPI';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
/*import upsertCustomer            from '@salesforce/apex/AHL_LoanApplicationActionController.initiateAPIRequest';
import getLoanTransactionDetails from '@salesforce/apex/AHL_LoanApplicationActionController.getLoanTxnDetails';
import validateQDPPaymentRec     from '@salesforce/apex/AHL_LoanApplicationActionController.validateQDPPaymentRec';
import getCurrentUserRole        from '@salesforce/apex/Hl_CovenantsDetailFormController.getCurrentUserRole';
import getProductDetails         from '@salesforce/apex/Utility_V1.getProductDetails';

import getInitialData          from '@salesforce/apex/PushToLMS.getInitialData';
import upsertApplicant         from '@salesforce/apex/PushToLMS.upsertApplicant';
import handleExistingCIFUpdate from '@salesforce/apex/PushToLMS.handleExistingCIFUpdate';
import processCollateral       from '@salesforce/apex/PushToLMS.processCollateral';
import callCreateFinanceAPEX   from '@salesforce/apex/PushToLMS.callCreateFinance';
import getUseLmsNewLogic       from '@salesforce/apex/PushToLMS.getUseLmsNewLogic';
*/
export default class OpportunityAction extends LightningElement {

   // _recordId;
    @api recordId;
    @track isLoading        = false;
    @track displayButton    = true;
    @track isError          = false;
    //@track isQDP            = false;
    @track losRefNumber     = '';
   // @track firstDisbAmt     = 0;
   // @track isHLUser         = false;   // true = HL product; drives flow routing
   // @track useLmsNewLogic   = false;   // true = lms_settings__c.use_new_logic__c

    errorData = [];

   /* @api
    get recordId() {
        return this._recordId;
    }
    /*set recordId(value) {
        this._recordId = value;
        if (value) {
            getCurrentUserRole({ recordId: this.recordId })
                .then(roleResult => {
                    if (roleResult) {
                        return Promise.all([
                            getLoanTransactionDetails({ loanId: this.recordId }),
                            this._fetchProductDetails(),
                            this._fetchUseLmsNewLogic()
                        ]);
                    } else {
                        this.isError       = true;
                        this.displayButton = false;
                        const errorMessage =
                            'You don\'t have permission to push to LMS. ' +
                            'Only Ops Author can perform this action.';
                        this.errorData.push({ 'Id': 1, 'Message': errorMessage });
                        return null;
                    }
                })
                .then(results => {
                    if (results && results[0]) {
                        const txn         = results[0];
                        this.isQDP        = txn.Quick_Disbursement__c;
                        this.losRefNumber = txn.Loan_Application__r.LMS_Loan_Reference__c;
                        this.firstDisbAmt = txn.First_Disbursement_Amount__c;
                    }
                })
                .catch(error => {
                    console.error(
                        'OpportunityAction: Error during initialisation:', error);
                });
        }
    }

    _fetchProductDetails() {
        const inputMapParam = { 'oppId': this.recordId };
        return getProductDetails({ inputMap: inputMapParam })
            .then(result => {
                this.isHLUser = result.isHLRelated;
                console.log('isHLUser-->', this.isHLUser);
            })
            .catch(error => {
                console.error('getProductDetails error-->', error);
                this.isHLUser = false;
            });
    }

    _fetchUseLmsNewLogic() {
        return getUseLmsNewLogic()
            .then(result => {
                this.useLmsNewLogic = result;
                console.log('useLmsNewLogic-->', this.useLmsNewLogic);
            })
            .catch(error => {
                console.error('getUseLmsNewLogic error-->', error);
                this.useLmsNewLogic = false;
            });
    }
*/
  /*  handleButtonValidation() {
        console.log(
            'handleButtonValidation isQDP:', this.isQDP,
            '| isHLUser:', this.isHLUser,
            '| useLmsNewLogic:', this.useLmsNewLogic
        );

        if (this.isQDP === true) {
            validateQDPPaymentRec({
                loanId: this.recordId,
                firstDisbAmt: this.firstDisbAmt
            })
                .then(result => {
                    if (result === true && this.losRefNumber !== '') {
                        this._callStageChangeAPI();
                        this.closeModal();
                    } else {
                        this.showToastMessage(
                            'Error',
                            'Data push failed, please create rejected disbursement instructions',
                            'Error'
                        );
                    }
                })
                .catch(error => {
                    console.error('validateQDPPaymentRec error:', error);
                });

        } else if (!this.useLmsNewLogic) {
            this._handleClick();

        } else {
            this._handlePushToLMSMultiTransaction();
        }
    }


    async _handlePushToLMSMultiTransaction() {
        this.isLoading = true;

        try {
            let initialData;
            try {
                initialData = await getInitialData({
                    loanApplicationId: this.recordId
                });
            } catch (err) {
                this._showErrors([
                    this._extractMessage(err, 'Failed to retrieve loan data.')
                ]);
                this.isLoading = false;
                return;
            }

            const lmsIdMap         = {};   // { customerId : lmsId }
            let   primaryCif       = '';
            let   successCount     = 0;
            const errors           = [];
            const existingCustMsgs = [];

            const apResultsRaw = await Promise.all(
                initialData.applicants.map(applicant =>
                    upsertApplicant({
                        loanApplicationId : this.recordId,
                        applicantId       : applicant.applicantId
                    }).catch(err => ({
                        _isError      : true,
                        applicantId   : applicant.applicantId,
                        errorMessage  :
                            'Create/Update Customer Error: ' +
                            this._extractMessage(err)
                    }))
                )
            );

            for (const apResult of apResultsRaw) {
                if (apResult._isError) {
                    errors.push(apResult.errorMessage);

                } else if (apResult.existingCustMsg) {
                    existingCustMsgs.push(apResult.existingCustMsg);

                } else if (apResult.success) {
                    successCount++;
                    if (apResult.lmsId) {
                        lmsIdMap[apResult.customerId] = apResult.lmsId;
                    }
                    if (apResult.applicantType === 'Primary Applicant'
                            && apResult.lmsId) {
                        primaryCif = apResult.lmsId;
                    }

                } else {
                    errors.push(
                        apResult.errorMessage || 'Create/Update Customer Error'
                    );
                }
            }

            if (existingCustMsgs.length > 0) {
                try {
                    const updated = await handleExistingCIFUpdate({
                        messages: existingCustMsgs
                    });
                    if (updated) {
                        errors.push(
                            'Some existing Customers were found and updated in ' +
                            'the system. Kindly Push to LMS again.'
                        );
                    }
                } catch (err) {
                    console.error('handleExistingCIFUpdate error:', err);
                    errors.push(
                        'Error processing existing customers: ' +
                        this._extractMessage(err)
                    );
                }
            }

            if (errors.length > 0) {
                this._showErrors(errors);
                this.isLoading = false;
                return;
            }

            // Only runs when all applicants succeeded.
            if (successCount === initialData.applicants.length) {

                const colRefMap = {};   // { appColId : colRef }
                let   callCf    = false;

                // that require the Create-Collateral API.
                const collateralsNeedingAPI = [];
                for (const collateral of initialData.collaterals) {
                    if (collateral.plfId) {
                        // Already registered – no API call required
                        colRefMap[collateral.appColId] = collateral.plfId;
                        callCf = true;
                    } else {
                        collateralsNeedingAPI.push(collateral);
                    }
                }

                if (collateralsNeedingAPI.length > 0) {
                    const colResultsRaw = await Promise.all(
                        collateralsNeedingAPI.map(collateral =>
                            processCollateral({
                                loanApplicationId : this.recordId,
                                appColId          : collateral.appColId,
                                primaryCif        : primaryCif
                            }).catch(err => ({
                                _isError       : true,
                                appColId       : collateral.appColId,
                                collateralName : collateral.collateralName,
                                errorMessage   : this._extractMessage(err)
                            }))
                        )
                    );

                    for (let i = 0; i < colResultsRaw.length; i++) {
                        const collateral = collateralsNeedingAPI[i];
                        const colResult  = colResultsRaw[i];

                        if (colResult._isError) {
                            errors.push(
                                'For Collateral ' + collateral.collateralName +
                                ': ' + colResult.errorMessage
                            );
                            colRefMap[collateral.appColId] = '';

                        } else {
                            colRefMap[collateral.appColId] =
                                colResult.colRef || '';

                            if (colResult.success) {
                                callCf = true;
                            } else {
                                errors.push(
                                    'For Collateral ' +
                                    collateral.collateralName + ' ' +
                                    colResult.errorMessage
                                );
                            }
                        }
                    }
                }

                if (errors.length > 0) {
                    this._showErrors(errors);
                    this.isLoading = false;
                    return;
                }

                // Mirror original condition: callCf || childLoan || no collaterals
                if (callCf || initialData.childLoan
                        || initialData.collaterals.length === 0) {
                    try {
                        const finResult = await callCreateFinanceAPEX({
                            loanApplicationId : this.recordId,
                            isQdp             : this.isQDP,
                            colRefMapJSON     : JSON.stringify(colRefMap),
                            lmsIdMapJSON      : JSON.stringify(lmsIdMap),
                            childLoan         : initialData.childLoan
                        });

                        if (finResult.success) {
                            this.showToastMessage(
                                'Success',
                                'Loan has been pushed to LMS with the LMS ' +
                                'Ref Number: ' + finResult.finReference,
                                'Success'
                            );
                            this.closeModal();
                        } else {
                            this._showErrors([finResult.errorMessage]);
                        }

                    } catch (err) {
                        console.error('callCreateFinance error:', err);
                        this._showErrors([
                            'Create Finance Error: ' +
                            this._extractMessage(err)
                        ]);
                    }
                }
            }

        } catch (err) {
            console.error(
                '_handlePushToLMSMultiTransaction unexpected error:', err);
            this._showErrors([
                'An unexpected error occurred: ' + this._extractMessage(err)
            ]);
        } finally {
            this.isLoading = false;
        }
    }


    _callStageChangeAPI() {
        callStageChangeAPEX({
            losRefNumber: this.losRefNumber,
            loanId      : this.recordId
        })
            .then(result => {
                if (result === 'Success') {
                    console.log('callStageChangeAPI executed successfully');
                    this.showToastMessage('Success', 'Stage changed successfully', 'Success');
                }
                else{
                    this.showToastMessage('Error', 'Stage changed failed!', 'Error');
                }
            })
            .catch(error => {
                console.error('Error callStageChangeAPI::', error);
                this.showToastMessage(
                    'Error', 'Stage changed failed!', 'Error');
            });
    }

    _handleClick() {
        console.log('record Id ::::::: 123' + this.recordId);
        this.isLoading = true;
        upsertCustomer({ loanApplicationId: this.recordId, isQdp: false })
            .then(result => {
                console.log(result);
                this.isLoading    = false;
                const successResp = result.success;
                const errorResp   = result.error;

                if (successResp.length > 0) {
                    this.showToastMessage('Success', successResp[0], 'Success');
                    this.closeModal();
                } else if (errorResp.length > 0) {
                    for (let i = 0; i < errorResp.length; i++) {
                        this.errorData.push({
                            'Id'      : i + 1,
                            'Message' : errorResp[i]
                        });
                    }
                    console.log('@@@@ print');
                    console.log(this.errorData);
                    this.isError       = true;
                    this.displayButton = false;
                }
            })
            .catch(error => {
                console.log(error);
                this.isLoading = false;
            });
    }


    _showErrors(errors) {
        let nextId = this.errorData.length + 1;
        for (const msg of errors) {
            this.errorData.push({ 'Id': nextId++, 'Message': msg });
        }
        this.isError       = true;
        this.displayButton = false;
    }

    _extractMessage(err, fallback = 'Unknown error') {
        if (!err) return fallback;
        if (err.body && err.body.message) return err.body.message;
        if (err.message) return err.message;
        return String(err);
    }
*/
handleButtonValidation() {
callStageChangeAPEX({
        loanId      : this.recordId
    })
        .then(result => {
            
                console.log('callStageChangeAPI executed successfully');
                 //this.showToastMessage('Success', 'Stage changed successfully', 'Success');
                //window.location.reload();
                    return notifyRecordUpdateAvailable([
            { recordId: this.recordId }
        ]);
        })
        .catch(error => {
            console.error('Error callStageChangeAPI::', error);
        
        });


    this.showToastMessage('Success', 'Data pushed to LMS successfully!', 'Success');
    //window.location.reload();
    this.closeModal();
}
    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToastMessage(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}