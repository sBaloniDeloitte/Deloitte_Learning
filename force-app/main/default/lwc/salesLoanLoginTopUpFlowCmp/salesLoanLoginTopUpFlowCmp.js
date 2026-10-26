import { LightningElement, track,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import findAccountByCIF from '@salesforce/apex/COMM_SalesLoanLoginTopUpFlowController.getOpportunities';
import updateOpportunity from '@salesforce/apex/COMM_SalesLoanLoginTopUpFlowController.updateOpportunity';
import getCustomerAPI from '@salesforce/apex/COMM_GetCustomerController.getCustomerDetails';
import getExistingLoanDetails from '@salesforce/apex/GetExistingLoanDetailsController.getExistingLoanDetails';
import checkLoanApplicationInSFDC from '@salesforce/apex/COMM_SalesLoanLoginTopUpFlowController.checkLoanApplicationInSFDC';
import createRelatedRecords from '@salesforce/apex/COMM_SalesLoanLoginTopUpFlowController.createRelatedRecords';
import checkDeduplicate from '@salesforce/apex/COMM_SalesLoanLoginTopUpFlowController.checkDeduplicate';
import getCustomerFinances from '@salesforce/apex/COMM_GetFinanceDetailsByUCICController.getCustomerFinances';
import cloneLoanApplication from '@salesforce/apex/COMM_SalesLoanLoginTopUpFlowController.cloneLoanApplication';
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated';

export default class SalesLoanLoginTopUpFlowCmp extends LightningElement {
    @api recordId;
    @track isloading = false;
    @track isModalOpen = false; 
    @track isTopUpLoan = null;
    @track showFormFields = false;
    @track topUpValue = '';
    @track hasFinanceRecords = false;
    @track hasDuplicateRecords = false;
    @track customerFinanceDetailList = [];
    @track showRecords = false;
    @track duplicateCustomers = []; 
    @track showDuplicateRecords = false;
    @track showNext = true;
    @track customerName = '';
    @track cifNumber = '';
    @track formData = {
        cif: '',
        lmsLoanNo: '',
        loanAppNo: '',
        name: '',
        mobile: '',
        dob: '',
        pan: '',
        aadharNumber: '',
        dl: '',
        voterId: '',
        passport: ''  
    };
    @api fromDedupe = false;
    @api selectedCif;
    @api selectedLoan;
    @api sourceSystem;
    @api isGhfLoan = false;

    topUpOptions = [
        { label: 'Yes', value: 'Yes', checked: false },
        { label: 'No', value: 'No', checked: false }
    ];
    topUpOptionsLead = [
        { label: 'Yes', value: 'Yes', checked: true }
       
    ];
    existingCustSelectedOption = [
        { label: 'Yes', value: 'Yes', checked: false },
        { label: 'No', value: 'No', checked: false }
    ];
    existingCustSelctedVal;
    showExistOption = false;
    modalHeader = 'Sales Loan Login / Top-Up Flow';
    //HL-Ishi-31/10
    @api fromLead=false;
    customerLmsId;
    custLmsId;
    //HL-Ishi-31-10
    isHLUser;
    connectedCallback() {
        console.log('25'+this.selectedCif);
        console.log('25'+this.selectedLoan);
        console.log('26'+this.sourceSystem);
        this.isModalOpen = true;
        this.showTopupQuestion = true;
        this.checkIfLoggedInUserIsHLRelated();
        if(this.fromDedupe){
            this.formData.cif = this.selectedCif;
        }
    }
    checkIfLoggedInUserIsHLRelated(){
        checkIfLoggedInUserIsHLRelated()
        .then(result => {
            this.isHLUser = result.isHLRelated;
            
             console.log('  this.isHLUser----'+  this.isHLUser);
            
            console.log('isHLUser-->',this.isHLUser);
        })
        .catch(error => {
            console.log('error-->',error);
        })
        //HL-Ishi-10/10
    }
    handleCheckboxChange(event) {
        const selectedValue = event.target.dataset.value;
        let isSameSelected = false;

        this.topUpOptions.forEach(option => {
            if (option.value === selectedValue && option.checked) {
                isSameSelected = true;
            }
        });

        this.topUpOptions = this.topUpOptions.map(option => {
            if (isSameSelected) {
                option.checked = false; // Deselect all
            } else {
                option.checked = (option.value === selectedValue); 
            }
            return option;
        });

        // Set topUpValue only if new selection is made
        this.topUpValue = isSameSelected ? null : selectedValue;
        if(this.topUpValue == 'No'/* && !this.fromLead*/ && this.isHLUser) {
            this.showExistOption = true;
        }
        // else if(this.topUpValue == 'No' && this.fromLead){
        //     this.showExistOption=false;
        //     this.handleClose();
        // }
        else{
            this.showExistOption = false;
        }
    }
    handleExistingCustCheckboxChange(event) {
        const selectedValue = event.target.dataset.value;
        let isSameSelected = false;

        this.existingCustSelectedOption.forEach(option => {
            if (option.value === selectedValue && option.checked) {
                isSameSelected = true;
            }
        });
        console.log('selectedValue=:'+selectedValue);
        console.log('isSameSelected=:'+isSameSelected);
        this.existingCustSelectedOption = this.existingCustSelectedOption.map(option => {
            if (isSameSelected) {
                option.checked = false; // Deselect all
            } else {
                console.log('option.value=:'+option.value);
                option.checked = (option.value === selectedValue); 
            }
            return option;
        });
        console.log('this.existingCustSelectedOption=:'+JSON.stringify(this.existingCustSelectedOption));
        // Set topUpValue only if new selection is made
        this.existingCustSelctedVal = isSameSelected ? null : selectedValue;

    }

    handleInputChange(event) {
        const { name, value } = event.target;
        this.formData[name] = value;
    }

    handleNext() {
      if (this.topUpValue == 'No') {
        if((this.existingCustSelctedVal == null || this.existingCustSelctedVal == undefined || this.existingCustSelctedVal == '') && this.isHLUser){
            this.showToast('Error', 'Please select if you want to update customer details', 'error');
            return;
        }
        if(this.existingCustSelctedVal == 'Yes'){
            updateOpportunity({
                oppId: this.recordId
            })
            .then(() => {
                console.log('Inside Yes for tagging');
                 this.showToast('Success', 'Opportunity updated successfully', 'success');
                const valueChangeEvent = new CustomEvent("updatecustomerdetails", {
                detail: { value:this.recordId }
                });
                this.dispatchEvent(valueChangeEvent);
                this.showExistOption=false;
            })
            .catch(error => {
                this.showToast('Error', 'Error updating Opportunity', 'error');
                 const valueChangeEvent = new CustomEvent("updatecustomerdetails", {
                detail: { value:this.recordId }
                });
                this.dispatchEvent(valueChangeEvent);
                this.showExistOption=false;
            });

           
            //call updateCustomer
            // call update opportunity
        }
        else{
            updateOpportunity({
                oppId: this.recordId
            })
            .then(() => {
                this.showToast('Success', 'Opportunity updated successfully', 'success');
                window.location.reload();
            })
            .catch(error => {
                this.showToast('Error', 'Error updating Opportunity', 'error');
            });
        }
      } else {
        console.log('duplicateCustomers-----'+this.duplicateCustomers.length);
          if ((!this.isGhfLoan)/*&& (this.fromLead && (this.duplicateCustomers.length == 0))*/) {
              if (this.showTopupQuestion) {
                  this.showTopupQuestion = false;
                  this.showFormFields = true;
                  this.showNext = false;
              } else if (this.showFormFields) {
                  console.log('89');
                  this.showFormFields = false;

                  // If there are duplicate records, show them first
                  if (this.duplicateCustomers?.length > 0) {
                      console.log('94');
                      this.showDuplicateRecords = true;
                      this.showRecords = false;
                  }
                  // Otherwise, show finance records if available
                  else if (this.customerFinanceDetailList?.length > 0) {
                      console.log('100');
                      this.showRecords = true;
                      this.showDuplicateRecords = false;
                  }
                  // If neither exists, fallback to form fields
                  else {
                      console.log('106');
                      this.showFormFields = true;
                      this.showRecords = false;
                      this.showDuplicateRecords = false;
                  }
              } else if (this.showRecords) {
                  console.log('112');
                  const selectedRecord = this.customerFinanceDetailList.find(rec => rec.isSelected);
                  console.log('114', JSON.parse(JSON.stringify(selectedRecord)));
                  if (!selectedRecord) {
                      this.showToast('Error', 'Please select one record.', 'error');
                      return;
                  }
                  if(this.fromLead){
                    console.log('inside next lead');
                    this.isModalOpen=false;
                    this.showDuplicateRecords=false;
                    this.showRecords=false;
                    const valueChangeEvent = new CustomEvent("resultfromflexi", {
                        detail: { 
                            selectedRecord:selectedRecord,
                        }
                    });
                    this.dispatchEvent(valueChangeEvent);
                    const selectedRecordNew = this.duplicateCustomers.find(rec => rec.isSelected);
                    console.log('114------', JSON.stringify(selectedRecordNew));
                    this.customerLmsId = selectedRecordNew.cif;
                        console.log('116-------', JSON.parse(JSON.stringify(selectedRecordNew)));
                        const valueChangeEvent2 = new CustomEvent("passleaddetails", {
                        detail: { custLmsId:selectedRecordNew.cif,
                            sourcesystem:selectedRecordNew.sourceSystem,
                            accId:selectedRecordNew.accId,
                            name:selectedRecordNew.name,
                            dob:selectedRecordNew.dob,
                            customerType:selectedRecordNew.customerType

                        }
                        });
                        this.dispatchEvent(valueChangeEvent2);
                  }
                  else{
                    if (selectedRecord.source === 'LMS' || selectedRecord.source === 'UCIC') {
                        console.log('120');
                        // Call LMS API
                        this.handleCreateRelatedRecords(selectedRecord);
                    } else if (selectedRecord.source === 'SF') {
                        console.log('124');
                        // Call SFDC check method
                        this.handleCloneOppRecord(selectedRecord);
                    } else {
                        this.showToast('Error', 'Invalid record source.', 'error');
                    }
                  }
              } else if (this.showDuplicateRecords) {
                  const selectedRecord = this.duplicateCustomers.find(rec => rec.isSelected);
                  if (!selectedRecord) {
                      this.showToast('Error', 'Please select one record.', 'error');
                      return;
                  }
                  console.log('Selected Record:', JSON.stringify(selectedRecord, null, 2));
                  this.handleFindAccountByCIF(selectedRecord.cif, selectedRecord.ucic, selectedRecord.accId);
              }
          }
          else if((this.duplicateCustomers?.length > 0) && this.fromLead){
                console.log('112----');
                  const selectedRecord = this.duplicateCustomers.find(rec => rec.isSelected);
                  console.log('114------', JSON.stringify(selectedRecord));
                    if (!selectedRecord) {
                      this.showToast('Error', 'Please select one record.', 'error');
                      return;
                  }
                this.customerLmsId = selectedRecord.cif;
                console.log('116-------', JSON.parse(JSON.stringify(selectedRecord)));
                const valueChangeEvent = new CustomEvent("passleaddetails", {
                detail: { custLmsId:selectedRecord.cif,
                    sourcesystem:selectedRecord.sourceSystem,
                    accId:selectedRecord.accId,
                    name:selectedRecord.name,
                    dob:selectedRecord.dob,
                    customerType:selectedRecord.customerType

                 }
                });
                this.dispatchEvent(valueChangeEvent);
                // this.showDuplicateRecords=false;
                // this.isModalOpen=false;
          }
          else {
              this.callGetFinanceByUCIC(this.selectedCif);
          }
      }

  }

    handleCloneOppRecord(selectedRecord) {
        this.isloading = true;
        console.log('selectedRecord.opportunityId--143--',selectedRecord.opportunityId);
        cloneLoanApplication({ 
            sourceOppId: selectedRecord.opportunityId , 
            recordId: this.recordId 
        })
        .then(result => {
             this.isloading = false;
            this.showToast('Success', 'Loan Application cloned successfully', 'success');
             window.location.reload();
            // refresh view or handle UI update here if needed
        })
        .catch(error => {
             this.isloading = false;
            console.error('Error cloning opportunity:', error);
            this.showToast('Error', 'Error while cloning Loan Application', 'error');
        });
    }

    handleCustomerSelection(event) {
        console.log('event.target.dataset.id---'+event.target.dataset.id)
        const selectedId = event.target.dataset.id;   // use dataset.id instead of value
       
        this.duplicateCustomers = this.duplicateCustomers.map(cust => {
            return {
                ...cust,
                isSelected: cust.cif === selectedId || cust.ucic === selectedId || cust.accId === selectedId
            };
        });
       
    }

    handlePrevious() {
        if (this.duplicateCustomers && this.duplicateCustomers.length > 0 && this.fromLead) {
            this.duplicateCustomers =[];
            this.showFormFields = true;
            this.showRecords = false;
            this.showDuplicateRecords = false;

        }
        if (this.duplicateCustomers && this.duplicateCustomers.length > 0 && this.showRecords) {
            this.showDuplicateRecords = true;
            this.showFormFields = false;
            this.showRecords = false;
        } 
         else if(this.showFormFields){
            this.showFormFields = false;
            this.showTopupQuestion = true;
            this.showNext = true;
        }
        else {
            this.showFormFields = true;
            this.showRecords = false;
            this.showDuplicateRecords = false;
        }
    }

    handleClose() {
        this.isModalOpen = false;
        this.isTopUpLoan = null;
        this.showFormFields = false;
        this.formData = {
            cif: '',
            lmsLoanNo: '',
            loanAppNo: '',
            name: '',
            mobile: '',
            dob: '',
            pan: '',
            aadharNumber: '',
            dl: '',
            voterId: '',
            passport: ''
        };
        if(this.fromLead){
              const valueChangeEvent = new CustomEvent("resetproduct", {
                detail: { custLmsId:this.customerLmsId,
                 }
                });
                this.dispatchEvent(valueChangeEvent);
        }
        if(!this.fromLead){
            const valueChangeEvent = new CustomEvent("resetcustomer");
            this.dispatchEvent(valueChangeEvent);
        }
    }

    showToast(title, message, variant = 'info') {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(toastEvent);
    }

    handleSearch() {
        this.customerFinanceDetailList = [];
        this.duplicateCustomers = [];
        const cif = this.formData.cif ? this.formData.cif.trim() : null;
        const lmsLoanNo = this.formData.lmsLoanNo ? this.formData.lmsLoanNo.trim() : null;
        const loanAppNo = this.formData.loanAppNo ? this.formData.loanAppNo.trim() : null;
        const firstName = this.formData.firstName ? this.formData.firstName.trim() : null;
        const lastName = this.formData.lastName ? this.formData.lastName.trim() : null;
        const dob = this.formData.dob ? this.formData.dob.trim() : null;
        const pan = this.formData.pan ? this.formData.pan.trim() : null;
        const aadhar = this.formData.aadhar ? this.formData.aadhar.trim() : null;
        const dl = this.formData.drivingLicense ? this.formData.drivingLicense.trim() : null;
        const voterId = this.formData.voterId ? this.formData.voterId.trim() : null;
        const passport = this.formData.passport ? this.formData.passport.trim() : null;
        const mobileNumber = this.formData.mobileNumber ? this.formData.mobileNumber.trim() : null;
        console.log('this.formData'+this.formData);
        console.log('this.formData'+JSON.stringify(this.formData));
       if (cif) {
            this.cifNumber = cif;
            this.isloading = true;
            this.handleFindAccountByCIF(cif,null,null);
        }
        else if(lmsLoanNo){
             this.isloading = true;
             this.handleLoanAppNo(lmsLoanNo, true)
        }
        else if(loanAppNo){
            this.isloading = true;
             this.handleLoanAppNo(loanAppNo, false);
        }
        else if (firstName || lastName || dob || pan || aadhar || dl || voterId || passport) {
            // Validate mandatory fields for this search method:
            if (!firstName || !lastName || !dob) {
                this.showToast('Error', 'Please provide both Name and Date of Birth.', 'error');
                return;
            }

            // Check at least one ID field is filled:
            if (!pan && !aadhar && !dl && !voterId && !passport) {
                this.showToast('Error', 'Please provide at least one ID: PAN, Aadhar, Driving License, Voter ID or Passport.', 'error');
                return;
            }

            this.handleNameDobIdSearch({ firstName, lastName, dob,mobileNumber, pan, aadhar, dl, voterId, passport });

        } else {
            this.showToast('Error', 'Please select any one parameter for search.', 'error');
        }
                
    }

    handleFindAccountByCIF(cif, ucic, accId) {
        findAccountByCIF({ cif: cif, ucic: ucic, accId: accId })
            .then(result => {
                if (result && result.length > 0) {
                    // Map finance detail records with disabled flag
                    this.customerFinanceDetailList = result.map(rec => {
                        return {
                            ...rec,
                            isDisabled: rec.finStatus === 'Cancelled' || rec.finStatus === 'Rejected'
                        };
                    });

                    // If customerName is present in result
                    if (result[0] && result[0].customerName) {
                        this.customerName = result[0].customerName;
                    }

                   console.log('Finance records found:', JSON.parse(JSON.stringify(this.customerFinanceDetailList)));

                    // Call external API only if accId is null
                    if (!accId ) {
                        this.callExternalCustomerAPI(cif);
                    }
                    else if(cif!=null && cif!='' && cif!=undefined && this.fromLead){
                         this.callExternalCustomerAPI(cif);
                    }
                    else{
                    this.isloading = false;
                    this.showRecords = true;
                    this.showNext = true;
                    this.showFormFields = false;
                    this.showDuplicateRecords = false;
                    }
                } else {
                    // No finance records in Salesforce → call external API only if accId is null
                    if (!accId) {
                        this.callExternalCustomerAPI(cif);
                    }
                }
            })
            .catch(error => {
                this.isloading = false;
                console.error('Error in handleFindAccountByCIF:', error);
            });
    }

    callExternalCustomerAPI(cif) {
        console.log('319---')
        getCustomerAPI({ customerId: cif, processName: 'Get Customer' })
            .then(finalResp => {
                 console.log('3191----');
                const responseObj = JSON.parse(finalResp.respBody);
                console.log('3191---',responseObj);
                    // Initialize finance list if not already
                    if (!this.customerFinanceDetailList) {
                        this.customerFinanceDetailList = [];
                    }

                    if (responseObj && responseObj.returnStatus && responseObj.returnStatus.returnCode === '0000') {
                        // Only then read personalInfo and call finance API
                        if (responseObj.personalInfo) {
                            this.customerName = `${responseObj.personalInfo.firstName || ''} ${responseObj.personalInfo.lastName || ''}`.trim();
                        }

                        // Call finance API
                        this.callGetFinanceByUCIC(cif);

                    }
                     else {
                        this.isloading = false;
                        // Only show toast if finance list is empty
                        if (!this.customerFinanceDetailList || this.customerFinanceDetailList.length === 0) {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'Customer not found',
                                    variant: 'error',
                                })
                            );
                        }
                    }

            })
            .catch(error => {
                this.isloading = false;
                // Optionally, show toast if finance list is empty
                    this.dispatchEvent(new ShowToastEvent({title: 'Error',message: error,variant: 'error', }));
                
            });
    }

    callGetFinanceByUCIC(cif) {
        //this.isloading = true;
        console.log('cif---',cif);
        getCustomerFinances({ customerId: cif, processName: 'Get Customer By UCIC' })
            .then(result => {
                const financeList = result;
                if (financeList && financeList.length > 0) {
                    const lmsRecords = financeList.map(record => ({
                        ...record,
                        source: 'LMS'
                    }));
                    console.log('financeList---',financeList);

                    this.customerFinanceDetailList = [...this.customerFinanceDetailList, ...lmsRecords];
                    this.customerFinanceDetailList = this.customerFinanceDetailList.map(rec => ({
                        ...rec,
                        isDisabled: rec.finStatus === 'Cancelled' || rec.finStatus === 'Rejected' || rec.finType === 'FL' || rec.finType === 'FT'
                    }));
                    this.isloading = false;
                    if (!this.isGhfLoan) {
                        this.showRecords = true;
                        this.showNext = true;
                        this.showFormFields = false;
                        this.showDuplicateRecords = false;
                    }
                    else{
                        var selectedRec;
                        this.customerFinanceDetailList.forEach(item=>{
                            if(item.finReference == this.selectedLoan){
                                if(item.isDisabled){
                                    this.dispatchEvent(new ShowToastEvent({title: 'Error',message: 'Selected loan is inactive. Cannot procced with this.',variant: 'error', }));
                                }
                                else{
                                    selectedRec = item;
                                    console.log('this.selectedLoan=:'+this.selectedLoan);
                                    this.handleCreateRelatedRecords(item);
                                }
                            }
                        })
                    }
                }
            })
            .catch(error => {
                this.isloading = false;
                console.error('Error in getCustomerFinances: ' + (error.body ? error.body.message : error.message));
            });
    }


    handleFinanceSelection(event) {
        const selectedRef = event.target.value;
        this.customerFinanceDetailList = this.customerFinanceDetailList.map(rec => {
            return {
                ...rec,
                isSelected: rec.finReference === selectedRef
            };
        });
    }

    callGetLoanAPI(finReference) {
        this.isloading = true;
        console.log('finReference--',finReference);
        getExistingLoanDetails({ finReference: finReference })
            .then(loanResponse => {
                console.log('Loan API Response--', loanResponse);

                // Parse response if it's a string
                let loanResponseObj = typeof loanResponse === 'string' ? JSON.parse(loanResponse) : loanResponse;
                const returnCode = loanResponseObj?.returnStatus?.returnCode;
                console.log('returnCode--', returnCode);

                if (returnCode === '0000' && loanResponseObj.customer && loanResponseObj.customer.cif) {
                    this.cifNumber = loanResponseObj.customer.cif;
                    console.log('cifNumber--', this.cifNumber);

                    // Merge first, middle, last name from customer.personalInfo
                    const personalInfo = loanResponseObj.customer.personalInfo || {};
                    const fullName = [personalInfo.firstName, personalInfo.middleName, personalInfo.lastName]
                        .filter(name => name && name.trim() !== '')
                        .join(' ');
                    this.customerName = fullName;
                    console.log('customerName--', this.customerName);

                    // Map only financeDetail fields needed for table
                    if (loanResponseObj.financeSchedule && loanResponseObj.financeSchedule.financeDetail) {
                        const fd = loanResponseObj.financeSchedule.financeDetail;
                        const lmsRecord = {
                            finReference: fd.finReference || '',
                            finType: fd.finType || '',
                            finStatus: fd.status || '',
                            finAmount: fd.finAmount || 0,
                            outstandingBal: (fd.finAmount || 0) - (fd.paidPri || 0),
                            source: 'LMS',
                            isDisabled: fd.status === 'Cancelled' || fd.status === 'Rejected'
                        };

                        this.customerFinanceDetailList = [
                            ...this.customerFinanceDetailList,
                            lmsRecord
                        ];
                    }
                    if (!this.isGhfLoan)
                    {
                        this.showRecords = true;
                        this.showNext = true;
                        this.showFormFields = false;
                        this.showDuplicateRecords = false;
                        this.isloading = false;
                    }
                    else{
                        this.createRelatedRecords(this.customerFinanceDetailList)
                    }
                    
                   
                }
                else {
                    this.isloading = false;
                    this.showToast('Warning', 'No Loan Details found with this loan number', 'warning');
                }
            })
            .catch(error => {
                this.isloading = false;
                console.error('Loan API Error:', error);
            });
    }

    // separate handler for record creation
    handleCreateRelatedRecords(selectedRecord) {
        this.isloading = true;
        var loanNum;
        if (!this.isGhfLoan) {
            console.log('496----'+this.selectedLoan)
           loanNum =selectedRecord.finReference
            
        }
        else{
            loanNum =this.selectedLoan
        }
        
        
        createRelatedRecords({loanNumber:loanNum , recordId: this.recordId })
            .then(() => {
                this.isloading = false;
                this.showToast('Success', 'Loan details processed and related records created successfully', 'success');
                 window.location.reload();
            })
            .catch(error => {
                this.isloading = false;
                this.showToast('Error', 'Failed to create related records', 'error');
            });
    }

    get showPrevious() {
        return this.showDuplicateRecords || this.showRecords || this.showFormFields;
    }

    handleLoanAppNo(loanAppNo, lmsNo) {
        this.isloading = true;
        checkLoanApplicationInSFDC({ loanAppNo: loanAppNo, lmsNo: lmsNo })
            .then(result => {
                if (result && result.length > 0) {
                    // Map result to add isDisabled flag
                    this.customerFinanceDetailList = result.map(rec => {
                        return {
                            ...rec,
                            isDisabled: rec.finStatus === 'Cancelled' || rec.finStatus === 'Rejected'
                        };
                    });
                    this.customerName = result.customerName;

                     this.callGetLoanAPI(loanAppNo);
                } else {
                    // No records found
                    if (!lmsNo) {
                        this.isloading = false;
                        this.showToast('Warning', 'No records found with this Loan Application Number', 'error');
                    } else {
                        // If lmsNo is true, call GetLoan API
                        this.callGetLoanAPI(loanAppNo);
                    }
                }
            })
            .catch(error => {
                this.isloading = false;
                console.error('Error in handleLoanAppNo:', error);
                this.showToast('Error', 'Unexpected error occurred', 'error');
            });
    }

    handleNameDobIdSearch({ firstName, lastName, dob, mobileNumber, pan, aadhar, dl, voterId, passport }) {
        this.isloading = true;
        const panName = `${firstName || ''} ${lastName || ''}`.trim();
        const inputMap = {
            firstName: firstName || '',
            lastName: lastName || '',
            dob: dob || '',
            mobileNumber: mobileNumber || '',
            panNumber: pan || '',
            aadharNumber: aadhar || '',
            dlNumber: dl || '',
            voterNumber: voterId || '',
            passportNumber: passport || '',
            loanId: this.recordId || '',
            processName: 'UCIC De Dupe Check',
            panName: panName,
            fromLead:this.fromLead||''
        };
        console.log('inputMap-----'+inputMap);
        checkDeduplicate({ inputMap })
            .then(result => {
                if (!result || result.length === 0) {
                    this.isloading = false;
                    this.showToast('Info', 'No duplicate records found', 'info');
                    this.duplicateCustomers = [];
                } else {
                    // Add disabled property for UI
                    this.duplicateCustomers = result.map(cust => {
                        return {
                            ...cust,
                            isDisabled: !cust.disable  
                        };
                    });

                    this.customerFinanceDetailList = [];
                    this.showDuplicateRecords = true;
                    this.showRecords = false;
                    this.showNext = true;
                    this.showFormFields = false;
                    this.isloading = false;

                    console.log('Duplicate records found. Response:', this.duplicateCustomers);
                }
            })
            .catch(error => {
                const message = error.body ? error.body.message : error.message;
                this.showToast('Error', message, 'error');
                this.duplicateCustomers = [];
                this.isloading = false;
            });
    }

}