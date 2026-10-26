import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCustomerDetails from '@salesforce/apex/COMM_GetCustomerController.getCustomerDetails';
import getTableHeaders from '@salesforce/apex/COMM_SalesLoanActionsController.getTableHeaders';
import updateCustomerDetails from '@salesforce/apex/SalesCustomerDedupeController.updateApplicantRecords'
import getOfferDetails from '@salesforce/apex/COMM_SalesLoanActionsController.getOfferDetails';
import getExisitingCustOfferDetails from '@salesforce/apex/COMM_SalesLoanActionsController.getExisitingCustOfferDetails';

import getCustId from '@salesforce/apex/COMM_SalesLoanLoginController.getCustId';
import NEGATIVE_LIST_Comment from '@salesforce/schema/Application_Applicant__c.Negative_List_Comment__c';
import sendLoanOfferEmail from '@salesforce/apex/Sales_OTPController.sendLoanOfferEmail';
import getDuplicateCustomerList from '@salesforce/apex/COMM_SalesLoanActionsController.getDuplicateCustomerList';
import getDedupeList from '@salesforce/apex/COMM_SalesLoanActionsController.getDedupeList';
import { NavigationMixin } from 'lightning/navigation';
import existingLoans from '@salesforce/apex/COMM_SalesLoanActionsController.existingLoans';
import getLoanStage from '@salesforce/apex/COMM_SalesLoanActionsController.getLoanStage';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import NEGATIVE_LIST_FIELD from '@salesforce/schema/Application_Applicant__c.Negative_list_dispostion__c';
import updateCustomerDisposition from '@salesforce/apex/COMM_SalesLoanLoginController.updateCustomerDisposition';
import USER_ID from '@salesforce/user/Id'; // Imports current user's ID
import USER_NAME_FIELD from '@salesforce/schema/User.Name';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Application_Applicant__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import FORM_FACTOR from '@salesforce/client/formFactor';

import updateNegativeDedupeRecords from '@salesforce/apex/COMM_SalesLoanActionsController.updateNegativeDedupeRecords';
import updatecustomerOnApplicant from '@salesforce/apex/COMM_SalesLoanActionsController.updatecustomerOnApplicant';
import updateApplicantRecords from '@salesforce/apex/SalesCustomerDedupeController.updateApplicantRecords';
import validateApplicant from '@salesforce/apex/COMM_SalesLoanActionsController.validateApplicant';
import getApplicantsByLoanApplication from "@salesforce/apex/AHL_LoanApplicationActionController.getApplicantsByLoanApplication";
import checkDedupeAtExist from "@salesforce/apex/AHL_LoanApplicationActionController.checkDedupeAtExist";
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName1';
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated';

export default class DeDuplicationScreenCmp extends NavigationMixin(LightningElement) {

    @api dupCustList =[];
    @track dedupList = []
    @track isShowModal = false;
    @track commentValue = '';
    @track viewComments = ''
    @api recordId;
    selectedKey;
    selectedComment = '';
    accountId;
    userName;
    error;

    @track groupedDedupeLists = {};
    @track isSelectAllMap = {};
    @track isDisabledAllMap = {};
    @track selectedValues = {};
    @track selectedComments = {};
    @track hasLoanStagePsvOrDisbursement = false;
    @track applicantName = {};

    @api applicantId;
    @api openPopUp = false;
    tableHeaders = [];
    selectedId;
    tableDataValues=[];
    selectedCustId;
    totalResp;
    showDuplicate = false;
    @api selectedRecordId;
    @api currentAppSeq;
    dedupeParesedResponse  =[];
    showOffersTable  = false;
    offerId;
    offerStatus;
    showLoanInfo;
    selectedLoanNum;
    customerDemographicResp;
    existingLoanId;
    callOptCmp = false;
    showUploadPanCmp = false;
    isOfferRelated
    disableOfferButton  = false;
    showExistingLoans = false;
    existingLoans;
    loginStage  = true;
    showMessageDupCustList = false;
    selectedCustIds =[];
    selectedLoanIds =[];
    showRemarksModal = false;
    panNumber;
    @api custId;
    selectedLoanId =[];
    isloading = false;
    showNegativeList=false;
    //Ishi
    showTopupScreen = false;
    selectedLMSId;
    sourceSystem;
    //Ishi
    @api fromSales= false;
    @track showDedupeButton= true;
    @track applicantList = [];
    @track currentApplicantIndex = 0;
    @track isCredit=false;
    @track isHLUser= false;
    connectedCallback(){
        console.log('de custlist--',this.custId);
        console.log('de applicantiD--',this.applicantId);
        console.log('fromSales in deduplication----', this.fromSales);
        // this.getLoanStage();
        this.checkIfLoggedInUserIsHLRelated();
        
        // this.showOffersTable=false

        setTimeout(() => {
            this.getDedupeList();
        }, 500);
        this.getDuplicateCustomerList();
        this.isloading = true;
    }

    checkIfLoggedInUserIsHLRelated(){
        checkIfLoggedInUserIsHLRelated()
        .then(result => {
            this.isHLUser = result.isHLRelated;
            if(this.isHLUser ){
                getCurrentUserProfileName({
            
                }).then(response=>{
                    console.log('response -->'+JSON.stringify(response));
                    // Set the profile flags based on the profile name
                    if (response === 'Admin' || response === 'Credit Manager' || response == 'Credit Officer') {
                        this.isCredit = true;
                    } 
                    
                }).catch(error=>{
                    console.error('Error getCurrentUserProfileName -->', JSON.stringify(error));
                });
            }
            console.log('isHLUser-->',this.isHLUser);
        })
        .catch(error => {
            console.log('error-->',error);
        })
    }

    get isMobileView() {
        if (FORM_FACTOR == 'Small') {
            return true;
        }
        return false;
    }

    get getButtonDivStyle() {
        if (FORM_FACTOR == 'Small') {
            return "display: flex; justify-content: center; margin-top: 10px;";
        }
        return "display: flex; justify-content: flex-end; margin-top: 10px;";
    }
    getLoanStage() {
        getLoanStage({
            recordId:this.recordId, 
        })
        .then(result =>{
            console.log('result----',JSON.stringify(result))
            if(result=='Sales login'){
                    this.loginStage = true;
                }
            else{
                    this.loginStage = false;
                }

                if(result == 'PSV' || result == 'Disbursement') {
                    this.hasLoanStagePsvOrDisbursement = true;
                }
            })
        .catch(error =>{
        })
    }

    recordTypeId;

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            console.error('Error fetching object info', error);
        }
    }

    @track options = [];
    @track selectedValue = '';
    //isSelectAll = false
    isDisabledAll = false

   @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: NEGATIVE_LIST_FIELD})
    wiredPicklistValues({ error, data }) {
        if (data) {
           console.log('Data--'+JSON.stringify(data));
            this.options = [...data.values.map(item => ({
                label: item.label,
                value: item.value
            }))];
        } else if (error) {
            console.error('Error fetching picklist values', error);
        }
    }

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [USER_NAME_FIELD]
    })
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
            this.error = undefined;
            console.log('Current User Name:', this.userName);
        } else if (error) {
            this.error = error;
            this.userName = undefined;
            console.error('Error fetching user:', error);
        }
    }

    isSubmit = false

    handleChange(event) {

        let key = event.target.dataset.key;
        let selectedValue = event.target.value
        this.selectedKey = key;
        this.commentValue = ''
        this.viewComments = this.selectedComments[key]
          console.log('this.groupedDedupeLists[key]--'+JSON.stringify(this.groupedDedupeLists[key]));

        let anyChecked = this.groupedDedupeLists[key].some(record => record.isSelected);
        console.log('selectedValue: '+selectedValue + ' anyChecked: '+anyChecked);
        if (selectedValue === 'Match found' && anyChecked) {
            console.log('inside if 1');
            let tempLSt = this.groupedDedupeLists[key];
            for (let i = 0;i<tempLSt.length;i++) {
                console.log('key ',tempLSt[i]);
                if(tempLSt[i].isSelected) {
                    if((tempLSt[i].FirstNameMatch != '' && tempLSt[i].FirstNameMatch != 100) || 
                    (tempLSt[i].LastNameMatch != '' && tempLSt[i].LastNameMatch != 100 ) ||
                        (tempLSt[i].MiddleNameMatch != '' && tempLSt[i].MiddleNameMatch != 100) ||
                        (tempLSt[i].MobileMatch != '' && tempLSt[i].MobileMatch != 100) ||
                        (tempLSt[i].AddressMatch != '' && tempLSt[i].AddressMatch != 100)) {
                        this.selectedValues[key] = selectedValue;


                        this.groupedDedupeLists[key] = this.groupedDedupeLists[key].map(record => ({
                            ...record,
                            isDisabled: true
                        }));

                        this.selectedComment = this.selectedComments[key]
                        this.matchFoundOn = true;
                        this.isShowModal = true;
                        this.isDisabledAllMap[key] = true;
                        return;
                    }


                }

            }


            this.selectedValues[key] = selectedValue;

            this.groupedDedupeLists[key] = this.groupedDedupeLists[key].map(record => ({
                ...record,
                isDisabled: true
            }));
            this.isDisabledAllMap[key] = true;
           // this.updateLoanApplicationRecord(key);
            this.updateDeDupeRecords(key);



        } else if (selectedValue === 'Match found' && !anyChecked) {
            console.log('inside if 2');
            this.template.querySelector(`[data-key="${key}"]`).value = this.selectedValues[key];
            this.showToast('Error', 'Kindly select at least one checkbox', 'error');

        } else if (selectedValue === 'Match not found' && anyChecked) {
            console.log('inside if 3');
            let isPanMatched = this.groupedDedupeLists[key].some(record => record.Pan_Match === 100);
            // let isPanMatched = false;
            if(isPanMatched){
                    this.template.querySelector(`[data-key="${key}"]`).value = this.selectedValues[key];

                    this.showToast('Error', 'Please select the record for PAN match', 'error');

            }else{
                console.log('selectedValue@@',selectedValue);
                console.log('key@@',key);
                    this.selectedValues[key] = selectedValue;
                    // this.selectedKey = key;
                console.log('this.selectedValues[key]@@',this.selectedValues[key]);
                this.groupedDedupeLists[key] = this.groupedDedupeLists[key].map(record => ({
                    ...record,
                    isDisabled: true
                }));

                this.selectedComment = this.selectedComments[key]

                this.isShowModal = true;
                this.isDisabledAllMap[key] = true;

            }

        } else if (selectedValue === 'Match not found' && !anyChecked) {
            console.log('inside if 4');
            this.template.querySelector(`[data-key="${key}"]`).value = this.selectedValues[key];
            this.showToast('Error', 'Kindly select at least one checkbox', 'error');

        } else if (selectedValue === '') {
            console.log('inside if 5');

            this.selectedValues[key] = selectedValue;
            this.groupedDedupeLists[key] = this.groupedDedupeLists[key].map(record => ({
                ...record,
                isDisabled: false
            }));
            this.isDisabledAllMap[key] = false;
            // this.updateLoanApplicationRecord(key);
            // this.updateDeDupeRecords(key);
        }
        // setTimeout(() => {
        //     this.getDedupeList();
        // }, 500);
    }

    handleModalSubmit(event) {
        let key = this.selectedKey;
        console.log('key-onsubmit-'+key)
        this.isSubmit = false
        this.isShowModal = false;
        // this.selectedComments[key] = this.commentValue
       // this.updateLoanApplicationRecord(key);
        this.updateDeDupeRecords(key);
        // setTimeout(() => {
        //     this.getDedupeList();
        // }, 1000);
        
    }

    hideModalBox() {
        this.isShowModal = false;
        this.selectedKey = null;
        this.isNeedComments = false
    }

    isNeedComments = false;
    handleViewComment(event){
        this.getDedupeList();
        let key = event.target.dataset.key;
        // console.log('evnet--',JSON.stringify(event))
        this.isNeedComments = true
         console.log('this.selectedComments-11-',JSON.stringify(this.selectedComments));
                  console.log('key-11-',key)

        this.viewComments = this.selectedComments[key]
        this.isShowModal = true;
    }

    handleViewCommentDuplicate(event){
        this.getDuplicateCustomerList();
        let key = event.target.dataset.key;
    }

    handleCommentChange(event){
        let key = this.selectedKey;
          console.log('key@@',key);
                 console.log('this.selectedComments-11-',JSON.stringify(this.selectedComments));

        this.commentValue = event.target.value
         this.selectedComments[key] =  this.commentValue;
    }

    currentDate;
    currentTime;

    get objectEntries() {
        return Object.keys(this.groupedDedupeLists).map(key => ({
            key,
            records: this.groupedDedupeLists[key],
            isSelectAll: this.isSelectAllMap[key],
            isDisabledAll: this.isDisabledAllMap[key],
            selectedValue: this.selectedValues[key],
            comment : this.selectedComments[key],
            appName : this.applicantName[key],
        }));
    }

    getDedupeList() {
        console.log('this.recordId inside getDedupeList>>>>> ',this.recordId);
        getDedupeList({
            loanId: this.recordId,
        })
            .then(result => {
                 console.log('inside result>>>>> ',result);
                if (result.length > 0) {
                    console.log('result ',result);
                    let groupedData = {};
                    let countMap = {};
                    result.forEach((record) => {
                        let appId = record.Application_Applicant__c;
                        let negDisposition = record.Application_Applicant__r.Negative_list_dispostion__c;
                        let comment = record.Application_Applicant__r.Negative_List_Comment__c;
                        let appName = record.Application_Applicant__r.Name;
                        if (!groupedData[appId]) {
                            groupedData[appId] = [];
                            countMap[appId] = 0;
                        }

                        if (!(appId in this.selectedValues)) {
                            if (negDisposition == undefined || negDisposition == '') {
                                negDisposition = ''
                            }
                            this.selectedValues = { ...this.selectedValues, [appId]: negDisposition };
                        }

                        if (!(appId in this.selectedComments)) {
                            if (comment == undefined || comment == '') {
                                comment = ''
                            }
                            this.selectedComments = { ...this.selectedComments, [appId]: comment };
                            this.applicantName ={ ...this.applicantName, [appId]: appName };
                        }
                        

                       
                        groupedData[appId].push({

                            SrNo: ++countMap[appId],
                            id: record.Id,
                            FirstName: record.First_Name__c ? record.First_Name__c + (record.First_Name_Match__c ? ' ('+record.First_Name_Match__c+ '%)' : '') : '',
                            FirstNameMatch: record.First_Name_Match__c ? record.First_Name_Match__c : '',
                            DOB: record.DOB__c ? record.DOB__c.split(' ')[0] + (record.DOB_Match__c ? ' ('+record.DOB_Match__c+ '%)' : '')  : '',
                            DOBMatch: record.DOB_Match__c ? record.DOB_Match__c : '',
                            MiddleName: record.Middle_Name__c ? record.Middle_Name__c + (record.Middle_Name_Match__c ? ' ('+record.Middle_Name_Match__c+ '%)' : '') : '',
                            MiddleNameMatch: record.Middle_Name_Match__c ? record.Middle_Name_Match__c : '',
                            LastName: record.Last_Name__c ? record.Last_Name__c +  (record.Last_Name_Match__c ? ' ('+record.Last_Name_Match__c+ '%)' : '') : '',
                            LastNameMatch: record.Last_Name_Match__c ? record.Last_Name_Match__c : '',
                            Address: record.Address__c ? record.Address__c  + (record.Address_Match__c ? ' ('+record.Address_Match__c+ '%)' : '') : '',
                            AddressMatch: record.Address_Match__c ? record.Address_Match__c : '',
                            MobileNumber: record.Mobile_Number__c ? record.Mobile_Number__c + (record.Mobile_Number_Match__c ? ' ('+record.Mobile_Number_Match__c+ '%)' : '') : '',
                            MobileMatch: record.Mobile_Number_Match__c ? record.Mobile_Number_Match__c : '',
                            Pan: record.PAN__c ? record.PAN__c + (record.Pan_Match__c ? ' ('+record.Pan_Match__c+ '%)' : '')  : '',
                            Pan_Match : record.Pan_Match__c,
                            Rule : record.Rule__c,
                            disposition : record.Match_found__c,
                            // isSelected: record.Match_found__c == 'Match found'?true:false,
                            isDisabled: this.selectedValues[appId] === 'Match found' || this.selectedValues[appId] === 'Match not found' ? true : false,
                            firstNameClass: 'tdBorderHeader slds-cell-wrap ' + (record.First_Name_Match__c >= 80 ? 'red-text' : ''),
                            middleNameClass: 'tdBorderHeader slds-cell-wrap ' + (record.Middle_Name_Match__c >= 80 ? 'red-text' : ''),
                            lastNameClass: 'tdBorderHeader slds-cell-wrap ' + (record.Last_Name_Match__c >= 80 ? 'red-text' : ''),
                            AddressClass: 'tdBorderHeader slds-cell-wrap ' + (record.Address_Match__c >= 80 ? 'red-text' : ''),
                            PanClass: 'tdBorderHeader slds-cell-wrap ' + (record.Pan_Match__c >= 80 ? 'red-text' : ''),
                            DOBClass: 'tdBorderHeader slds-cell-wrap ' + (record.DOB_Match__c >= 80 ? 'red-text' : ''),
                            MobileNumberClass: 'tdBorderHeader slds-cell-wrap ' + (record.Mobile_Number_Match__c >= 80 ? 'red-text' : ''),

                            CIF_Id:record.CIF_Id__c,
                        });
                    
                    });

                    this.groupedDedupeLists = groupedData;
                    Object.keys(groupedData).forEach(appId => {
                        this.isSelectAllMap[appId] = groupedData[appId].every(record => record.isSelected);
                        this.isDisabledAllMap[appId] = this.selectedValues[appId] === 'Match found' || this.selectedValues[appId] === 'Match not found';

                    });
                }
                console.log('this.groupedDedupeLists.length-----', Object.keys(this.groupedDedupeLists).length);
                 console.log('groupedDedupeLists>>>>',this.groupedDedupeLists);
                 if(this.groupedDedupeLists && Object.keys(this.groupedDedupeLists).length > 0){
                    this.showNegativeList = true;
                }
            })
    }

    @track selectedLst = [];
    @track deselectedLst = [];
    @track isSelectAll = false;

    handleSelectAllNegDed(event) {
        let key = event.target.dataset.key;
        let isChecked = event.target.checked;
        this.isSelectAll = isChecked;
        this.isSelectAllMap[key] = isChecked;
        this.groupedDedupeLists[key] = this.groupedDedupeLists[key].map(record => ({
            ...record,
            isSelected: isChecked
        }));
    }

    handleRowSelectionNegativeDedupe(event) {
        let key = event.target.dataset.key;
        let recordId = event.target.dataset.id;
        let isChecked = event.target.checked;
        console.log('key : '+key);
        console.log('recordId : '+recordId);
        console.log('isChecked : '+isChecked);
        if(isChecked){
            this.selectedLst = [...this.selectedLst, recordId];
            const index = this.deselectedLst.indexOf(recordId);
            if (index !== -1) {
                this.deselectedLst.splice(index, 1);
            }
        }else {
            const index = this.selectedLst.indexOf(recordId);
            if (index !== -1) {
                this.selectedLst.splice(index, 1);
            }
            this.deselectedLst = [...this.deselectedLst, recordId];
        }

        this.groupedDedupeLists[key] = this.groupedDedupeLists[key].map(record =>
            record.id === recordId ? { ...record, isSelected: isChecked } : record
        );
        this.isSelectAllMap[key] = this.groupedDedupeLists[key].every(record => record.isSelected);
    }

    updateDeDupeRecords(key) {
        const selectedDropdownValue = this.selectedValues[key]; // Either "Match found" or "Match not found"
        let recordsToUpdate = {};
        const updatedRecordIds = [];
        console.log('selectedDropdownValue : '+selectedDropdownValue);
        this.groupedDedupeLists[key].forEach(record => {
            console.log('record: '+JSON.stringify(record));
            if (record.isSelected) {
                recordsToUpdate[record.id] = { Match_Found__c: selectedDropdownValue };
                updatedRecordIds.push(record.id);
            }
            // Do nothing for unselected records
        });

        console.log('recordsToUpdate--', recordsToUpdate);

        updateNegativeDedupeRecords({ recordsToUpdate: recordsToUpdate })
            .then(() => {
                // Optionally clear selection after update
                this.groupedDedupeLists[key] = this.groupedDedupeLists[key].map(record => {
                    if (updatedRecordIds.includes(record.id)) {
                        return { ...record, isSelected: false };
                    }
                    return record;
                });
                // Optionally show toast
                // this.showToast('Success', 'Records updated successfully', 'success');
                this.getDedupeList();
            })
            .catch(error => {
                console.error('Error updating records:', error);
                this.showToast('Error', 'Failed to update records', 'error');
            });
    }


    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
    getDuplicateCustomerList() {
        this.isloading = true;
        console.log('de dupelist- 689-');
        console.log('this.custId 689--',this.custId);
        console.log('this.applicantId 689--',this.applicantId);
        console.log('this.recordId 689--',this.recordId);
        getDuplicateCustomerList({
            custId: this.custId,
            applicantId: this.applicantId,
            loanId: this.recordId
        })
            .then(result => {
                console.log('de dupelist- 689-', JSON.stringify(result));
                this.isloading = false;
                this.dupCustList = result;

                const panMatchList = this.dupCustList.filter(cust =>
                    
                    cust.matchReason != undefined && cust.matchReason != null && cust.matchReason != '' && cust.matchReason.includes('Pan') && cust.customerId
                );

                var panMatchCount =[];
                var count =0;
                this.dupCustList.forEach(item =>{
                    console.log('panMatchCount=:'+panMatchCount);
                    console.log('item.sourceSystem=:'+item.sourceSystem);
                    console.log('item.customerId=:'+item.customerId);
                    console.log('item.customerId=:'+item.matchReason);
                    if(item.sourceSystem==='PLF' && item.customerId!=null && item.customerId!=undefined && item.customerId!='' && !panMatchCount.includes(item.customerId) && (item.matchReason!=null && item.matchReason!=undefined && item.matchReason!='' && item.matchReason.includes('Pan'))){
                        count ++;
                        panMatchCount.push(item.customerId);
                    }
                    
                })

                // this.dupCustList = this.dupCustList.filter(record =>  record.sourceSystem === 'Salesforce' && record.matchReason === 'Aadhaar');

                console.log('count---536'+count);
                console.log('panMatch---'+JSON.stringify(panMatchList));
                console.log('panMatch---'+panMatchList.length);
                const isSinglePanFromPLF = count===1;
                console.log('this.isSinglePanFromPLF ',isSinglePanFromPLF);
                if (this.dupCustList.length === 0) {
                    this.showMessageDupCustList = true;
                    console.log('this.showMessageDupCustList ', this.showMessageDupCustList);
                }
                else if (this.dupCustList.length === 1) {
                    console.log('this.isSinglePanFromPLF ',isSinglePanFromPLF);
                    this.showMessageDupCustList = false;
                    this.dupCustList = this.dupCustList.map((customer) => {
                        const isDisabled = !customer.customerId;
                        return {
                            customerNumber: customer.customerId,
                            loanNum: customer.loanNum,
                            loanLink: customer.loanLink || '-',
                            loanCreatedDate: customer.loanCreatedDate || '-',
                            loanFromSfdc: customer.loanFromSfdc || false,
                            ucicNumber: customer.ucic,
                            customerName: customer.name,
                            mobileNumber: customer.mobileNumber || '-',
                            panNumber: customer.panNumber || '-',
                            dob: customer.dob || '-',
                            custLink: customer.custLink || '-',
                            matchReason: customer.matchReason || '-',
                            sourceSystem: customer.sourceSystem || '-',
                            gender: customer.gender || '-',
                            isFromSFDC: customer.isFromSFDC || false,
                            loanLink: customer.loanLink || '-',
                            loanFromSfdc: customer.loanFromSfdc || false,
                            product: customer.product || '-',
                            stage: customer.stage || '-',
                            status: customer.status || '-',
                            uniqueCount: customer.uniqueCount,
                            accountId: customer.accId || '-',
                            customerType: customer.customerType || '-',
                            dispositionStatus: customer.dispositionStatus || '-',
                            dispositionRemarks: customer.dispositionRemarks || '-',
                            isSelected: !isDisabled && isSinglePanFromPLF,
                            isDisabled: isDisabled,
                            isCoApplicant:customer.isCoApplicant,
                            custUniqueId:customer.custUniqueId,
                            applicantOptions: customer.applicantOptions ? Object.keys(customer.applicantOptions).map(key => {
                                return {
                                    value: key,      // Id (key of the map)
                                    label: customer.applicantOptions[key] // Name (value of the map)
                                };
                            }):  [],
                            selectedValue: customer.selectedValue || ''
                        };
                    });

                    const selected = this.dupCustList.find(record => !record.isDisabled);
                    if (selected && isSinglePanFromPLF) {
                        this.selectedId = selected.customerNumber;
                        console.log('this.selectedId=:' + this.selectedId);
                    }

                    this.showDuplicate = true;
                    this.fetchTableHeaders();
                    this.getOfferDetails();
                    this.showOffersTable = true;
                }
                else if (this.dupCustList.length > 1) {
                    this.showMessageDupCustList = false;

                    // Prepare list with additional flags
                    this.dupCustList = this.dupCustList.map((customer) => {
                        const matchType = (customer.matchReason || '').split('|')[0] || '';
                        return {
                            customerNumber: customer.customerId,
                            loanNum: customer.loanNum,
                            ucicNumber: customer.ucic,
                            customerName: customer.name,
                            mobileNumber: customer.mobileNumber || '-',
                            panNumber: customer.panNumber || '-',
                            dob: customer.dob || '-',
                            custLink: customer.custLink || '-',
                            matchReason: customer.matchReason || '-',
                            sourceSystem: customer.sourceSystem || '-',
                            gender: customer.gender || '-',
                            isFromSFDC: customer.isFromSFDC || false,
                            loanLink: customer.loanLink || '-',
                            loanCreatedDate: customer.loanCreatedDate || '-',
                            loanFromSfdc: customer.loanFromSfdc || false,
                            product: customer.product || '-',
                            stage: customer.stage || '-',
                            status: customer.status || '-',
                            uniqueCount: customer.uniqueCount,
                            accountId: customer.accId || '-',
                            customerType: customer.customerType || '-',
                            dispositionStatus: customer.dispositionStatus || '-',
                            dispositionRemarks: customer.dispositionRemarks || '-',
                            matchType: matchType,
                            isDisabled: false,
                            isSelected: false,
                            custUniqueId:customer.custUniqueId,
                            isCoApplicant:customer.isCoApplicant,
                            applicantOptions: customer.applicantOptions ? Object.keys(customer.applicantOptions).map(key => {
                                return {
                                    value: key,      // Id (key of the map)
                                    label: customer.applicantOptions[key] // Name (value of the map)
                                };
                            }):  [],
                            selectedValue: customer.selectedValue || ''
                        };
                    });

                    // Check for PAN match from PLF



                    if (this.loginStage && isSinglePanFromPLF) {
                        // Disable all rows
                        this.dupCustList = this.dupCustList.map(record => ({
                            ...record,
                            isDisabled: true,
                            isSelected: true
                        }));
                        //this.selectedId = null;
                        // this.selectedId = '102629';
                        console.log('Inside 638');
                        console.log('this.selectedId ', this.selectedId);
                        console.log('Processed dupCustList:', JSON.stringify(this.dupCustList));

                    } else {
                        // Enable all with valid customerId
                        this.dupCustList = this.dupCustList.map(record => ({
                            ...record,
                            isDisabled: false,
                            isSelected: false
                        }));
                    }

                    console.log('Processed dupCustList:', JSON.stringify(this.dupCustList));
                    this.showDuplicate = true;
                    console.log('P714---dedupe');
                    this.showOffersTable = true;
                    this.fetchTableHeaders();
                    this.getOfferDetails();


                }


            })
            .catch(error => {
                this.isloading = false;
                console.log('error -->' + JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'Error',
                    }),
                )
            })
    }

    fetchTableHeaders() {
        getTableHeaders()
            .then(response => {
                if (!response || response.length === 0) {
                    throw new Error('No headers returned from Apex');
                }
                this.tableHeaders = response.map(label => ({ label }));
            })
            .catch(error => {
                console.error('❌ Error fetching table headers:', JSON.stringify(error));
            });
    }

    getOfferDetails(){
        console.log('this.selectedId=:'+this.selectedId);
        getOfferDetails({
            custId : this.selectedId,

        }).then(response=>{
            console.log('response:', JSON.stringify(response));
            this.tableDataValues = response;
            if(this.tableDataValues.length>0){
                this.showOffersTable=true;
            }
            else{
                this.showOffersTable=false;
            }
        })
    }
    isGHFSelected = false;
    handleRowSelectionFromApi(event) {
    const ds = (event.target && event.target.dataset) || (event.currentTarget && event.currentTarget.dataset) || {};
    console.log('event dataset:', ds);
    console.log('event dataset:', ds.applicant);
    // preserve your original dataset names
    const selectedCustomerId = ds.id;      // data-id
    const accountKey = ds.key || event.target.value; // prefer data-key, fallback to radio value
    const loanNum = ds.loan;               // data-loan
    const uniqueCount = ds.count;          // data-count
    const pan = ds.name;                   // data-name
    const isChecked = event.target.checked; // true when radio selected
    const selectedSource =ds.type;
    const isCoApp= ds.applicant;
    console.log('event dataset:', isCoApp);

    console.log('selectedCustomerId:', selectedCustomerId, 'accountKey:', accountKey, 'loanNum:', loanNum, 'uniqueCount:', uniqueCount, 'isChecked:', isChecked);

    // preserve the same fields you used before
    this.selectedId = isChecked ? selectedCustomerId : null;
    this.selectedLMSId = isChecked ? loanNum : null;
    if(this.selectedLMSId != null && this.selectedLMSId != undefined && this.selectedLMSId.includes('GHF')){
        this.isGHFSelected = true;
    }
    this.panNumber = pan;
    this.accountId = accountKey;
    this.sourceSystem = selectedSource;

    // Find index of clicked row defensively (match by accountId, fallback to customerNumber, fallback to uniqueCount)
    let idx = -1;
    if (accountKey !== undefined && accountKey !== null) {
        idx = this.dupCustList.findIndex(it => String(it.accountId) === String(accountKey));
    }
    if (idx === -1 && selectedCustomerId !== undefined && selectedCustomerId !== null) {
        idx = this.dupCustList.findIndex(it => String(it.customerNumber) === String(selectedCustomerId));
    }
    if (idx === -1 && uniqueCount !== undefined && uniqueCount !== null) {
        idx = this.dupCustList.findIndex(it => String(it.uniqueCount) === String(uniqueCount));
    }

    if (idx === -1) {
        // If we can't find the row, don't accidentally select all — just clear selection safely
        console.warn('Could not find matching row in dupCustList. Check dataset keys and dupCustList structure.');
        this.dupCustList = this.dupCustList.map(it => ({ ...it, isSelected: false }));
        this.selectedCustIds = [];
        this.selectedLoanIds = [];
        this.isCheckboxDisabled = false;
        this.showOffersTable = false;
        this.tableDataValues = '';
        return;
    }

    // Create a new array so LWC reactivity triggers re-render.
    // For radio: mark only the clicked index as selected; others false.
    const newList = this.dupCustList.map((it, i) => {
        return { ...it, isSelected: i === idx };
    });

    this.dupCustList = newList;

    // Maintain single-selection arrays/vars (preserve your variable names)
    if (isChecked) {
        // Keep backward-compatible arrays but only one element
        this.selectedCustIds = [ String(this.dupCustList[idx].accountId || accountKey) ];
        this.selectedLoanIds = [ loanNum ];
        // optional single vars if other code uses them
        this.selectedCustId = this.selectedCustIds[0];
        this.selectedLoanId = this.selectedLoanIds[0];
        console.log('at 870---');
        
        if(isCoApp== 'false'){
            console.log('inside isCoApp---');
            
            this.showTopupScreen = true;
        }else{
            console.log('at 877---');
            
            this.updateCustomerDetails();
        }
        
        // Preserve original behavior: call getOfferDetails and show offers table
        // if (this.getOfferDetails) {
        //     try {
        //          this.getOfferDetails(); 
        //         } 
        //     catch(e){
        //              console.error(e); 
        //              }
        // }
        // this.showOffersTable = true;

        // For consistency with your previous flag naming
        this.isCheckboxDisabled = true; // or keep as true to indicate a selection exists
    } else {
        // Radios normally won't trigger 'unchecked' by user click, but keep logic for programmatic clear
        this.selectedCustIds = [];
        this.selectedLoanIds = [];
        this.selectedCustId = null;
        this.selectedLoanId = null;
        this.selectedId = null;
        this.accountId = null;
        this.panNumber = null;

        this.showOffersTable = false;
        this.tableDataValues = '';
        this.isCheckboxDisabled = false;
    }

    console.log('selectedLoanIds ', this.selectedLoanIds);
}

    resetSelect(event){
        console.log('Inside reset event---', event);
        this.dupCustList = this.dupCustList.map(it => ({ ...it, isSelected: false }));
        this.selectedCustIds = [];
        this.selectedLoanIds = [];
        this.selectedCustId = null;
        this.selectedLoanId = null;
        this.selectedId = null;
        this.accountId = null;
        this.panNumber = null;
        this.showTopupScreen = false;
        this.showOffersTable = false;
        this.tableDataValues = '';
        this.isCheckboxDisabled = false;
    }


    handleCancel(){
        this.showDuplicate = false;
    }
    getCustomerDetails(){
        getCustomerDetails({
        customerId : this.selectedId,
        processName : 'Get Customer',
        intSettingList: null,
        isFromJS: true
    }).then(response=>{
            this.ShowLoader = false;
            var responseData = JSON.parse(response.respBody);
        console.log('response=: 172'+responseData.customerFinanceDetailList);
      if(responseData.customerFinanceDetailList.length > 0){
                //this.showLoanInfo = true;
                this.showDuplicate = false;
                this.customerDemographicResp = responseData.customerFinanceDetailList;
                this.totalResp = responseData;
        }else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                    message: 'Their are no existing loan for the selected customer.' ,
                        variant: 'Error',
                    }),
                );
            }
    }).catch(error=>{
            this.ShowLoader = false;
        console.log('error -->'+error);
        })
    }

    getExisitingCustDetails(event){
        console.log('event.target.dataset.id=:'+event.target.dataset.id);
        console.log('event.target.dataset.status=:,',event.target.value)
        this.offerId = event.target.dataset.id;
        // this.offerStatus = event.target.value;
        getExisitingCustOfferDetails({
            offerId : this.offerId,
            // offerStatus : this.offerStatus
        }).then(response=>{
            this.existingLoanId  = response.laNumber;
            console.log('response= 204:'+JSON.stringify(response));
            if(response.offerStatus ==='Offer Accepted' ){
                // this.showLoanInfo = true;
                this.getCustomerDetails();

            }

        })
        .catch(error=>{
            console.log('error-->'+error);
            })

    }

    convertLoanToTopUp(event){

        convertLoanToTopUp({
            loanId:this.recordId,
            loanAppNum:this.existingLoanId,
            customerDetailString:JSON.stringify(this.totalResp)
        }).then(resp=>{

            this.showLoanInfo = false;
            if(this.openPopUp ==  false){
                // const valueChangeEvent = new CustomEvent("callprimaryinformation", {
                //     detail: { value:this.recordId,name:'Applicant Information',currentAppSeq: this.currentAppSeq }
                // }  );
                //    this.dispatchEvent(valueChangeEvent);
            }
            if(this.openPopUp ==  true){
                const valueChangeEvent = new CustomEvent("callbasicdetails", {
                    detail: { value:this.recordId,name:'Applicant Information',currentAppSeq: this.currentAppSeq }
                });
                //this.dispatchEvent(valueChangeEvent);
            }
        }).catch(error=>{
            this.ShowLoader = false;
            console.log('error -->'+error);
        })
    }
    handleLoanSelection(event){
        if(event.target.checked){
            this.selectedLoanNum = event.target.dataset.id;
        }
        else{
            this.selectedLoanNum = '';
        }
        console.log('this.selectedLoanNum=:'+this.selectedLoanNum);
    }
    get createLoanTopUpVisibility(){
        return this.selectedLoanNum != '' && this.selectedLoanNum != null && this.selectedLoanNum != undefined;
    }

    handleNext(){
        console.log('this.selectedCustIds-----',this.selectedCustIds);
        console.log('this.dupCustList----',this.dupCustList);
        if(this.dupCustList.length > 0 && (this.selectedCustIds == null || this.selectedCustIds == undefined || this.selectedCustIds.length==0)){
            console.log('this.selectedCustIds- 957----',this.selectedCustIds);
              const valueChangeEvent = new CustomEvent("callnextaccordian", {
                detail: { value:this.recordId,name:'Applicant Information',currentAppSeq: this.currentAppSeq ,section: 'Address' }
                });
                this.dispatchEvent(valueChangeEvent);

            // this.dispatchEvent(
            //     new ShowToastEvent({
            //         title: 'Error',
            //         message: 'Please select atleast one customer to proceed forward' ,
            //         variant: 'Error',
            //     }),
            // );
            // return;
        }
        else{
            console.log('this.selectedCustIds- 968----',this.selectedCustIds);
            if(this.selectedCustIds.length>1){
                console.log('this.selectedCustIds- 970----',this.selectedCustIds);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select only one customer to proceed forward.' ,
                        variant: 'Error',
                    }),
                );
                return;
            }
            else{
                console.log('this.selectedCustIds- 981----',this.selectedCustIds);
                // this.selectedId = this.selectedCustIds[0];
                this.getCustId();

                console.log('this.selectedId --',this.selectedId );
            }
        }
    }

        getCustId(){
            getCustId({customerId: this.selectedCustIds[0]})
            .then(result => {
                console.log('result--->'+result);
                this.selectedId = result;
                this.updateCustomerDetails();
            })
            .catch(error => {
                console.error('Error in fetching document name: ', JSON.stringify(error));
            })
    }

    // this.updateCustomerDetails();
    // if(this.selectedRecordId!=null && this.selectedRecordId!=undefined && this.selectedRecordId!=''){

    //     this.saveExistingCustomerDetails();
    // }



    updateCustomerDetails(){
        this.isloading = true;
        console.log('this.selectedId  997--',this.accountId);
        console.log('this.selectedId  997--',this.applicantId );
            let requestWrapper = {
                custId: this.selectedId,
                applicantId: this.applicantId,
                custUniqueId: this.applicantId,   
                accId: this.accountId
            };
        updateCustomerDetails({
            inputStr:JSON.stringify(requestWrapper)
        })
        .then(result =>{
            console.log('tresult-',result);
                this.isloading = false;
            console.log('result--->'+JSON.stringify(result));
                const valueChangeEvent = new CustomEvent("callbasicdetails", {
                detail: { value:this.recordId,name:'Applicant Information',currentAppSeq: this.currentAppSeq }
                });
                this.dispatchEvent(valueChangeEvent);

        })
        .catch(error=>{
                this.isloading = false;
        })
        // updateCustomerDetails({
        //     custId:this.selectedId,
        //     applicantId:this.applicantId,
        //     panNumber:this.panNumber,
        //     custUniqueID:this.applicantId,
        //     accountId:this.accountId
        // })
        // .then(result =>{
        //     console.log('tresult-',result);
        //         this.isloading = false;
        //     console.log('result--->'+JSON.stringify(result));
        //         const valueChangeEvent = new CustomEvent("callbasicdetails", {
        //         detail: { value:this.recordId,name:'Applicant Information',currentAppSeq: this.currentAppSeq }
        //         });
        //         //this.dispatchEvent(valueChangeEvent);

        // }).catch(error=>{
        //         this.isloading = false;
        //     })
    }

    handleNextBasicDetails(){
        // if(this.selectedRecordId!=null && this.selectedRecordId!=undefined && this.selectedRecordId!=''){

        //     this.saveExistingCustomerDetails();
        // }
        const valueChangeEvent = new CustomEvent("callbasicdetails", {
                    detail: { value:this.recordId,name:'Applicant Information',currentAppSeq: this.currentAppSeq }
        });
        //this.dispatchEvent(valueChangeEvent);
    }
    getExistingCustomerDetails(){
        console.log('this.selectedId-',this.selectedId);
        getCustomerDetails({
            customerId : this.selectedId,
            processName : 'Get Customer',
            intSettingList: null,
            isFromJS: true
        }).then(response=>{

            var responseData = JSON.parse(response.respBody);
            console.log('response=:'+JSON.stringify(responseData));
        if(responseData.customerFinanceDetailList.length > 0){
                //this.showLoanInfo = true;
                this.showDuplicate = false;
                this.customerDemographicResp = responseData.customerFinanceDetailList;
                this.totalResp = responseData;
                //this.saveExistingCustomerDetails();
            }else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Their are no existing loan for the selected customer.' ,
                        variant: 'Error',
                    }),
                );
            }
        }).catch(error=>{
            this.ShowLoader = false;
            console.log('error -->'+error);
        })
    }

    saveExistingCustomerDetails() {
        console.log('this.totalResp--304-', this.selectedId)
        saveExistingCustomerDetails({
            loanId: this.recordId,
            customerDemographicDetails: JSON.stringify(this.customerDemographicResp),
            customerId: this.selectedId,
            totalResp: JSON.stringify(this.totalResp),
        })
            .then(response => {
                if (this.offerId != null && this.offerId != undefined && this.offerId != '' && this.isOfferRelated == true) {
                    setTimeout(() => {
                        sendLoanOfferEmail({
                            loanId: this.recordId,
                            applicantId: this.applicantId,
                            offerRelated: this.isOfferRelated,
                            offerId: this.offerId
                        })
                            .then(response => {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Success',
                                        message: 'Offer has been sent to customer, please wait untill the offer is accepted',
                                        variant: 'Success',
                                    }),
                                );

                                this.updateRecords();

                            })
                            .catch(error => {
                            })
                    }, 200)


                }

                //this.getCustDetails();
                //this.convertLoanToTopUp();
            })
            .catch(error => {
                this.ShowLoader = false;
                console.log('error -->' + error);
            })
    }

    handleCloseModal() {
        this.openPopUp = false;
    }
    handleSendOffer(event){

        // }

        this.getExistingCustomerDetails();

        this.offerId = event.target.dataset.id;

        this.offerStatus = 'Offer Sent to Customer';
        this.isOfferRelated =true;

    }

        updateRecords(){
        const fields = {};
        fields['Id'] = this.offerId;

        fields['Offer_Status__c'] = this.offerStatus;
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
            .then(() => {
                // if(this.selectedRecordId!=null && this.selectedRecordId!=undefined && this.selectedRecordId!=''){

                //     this.saveExistingCustomerDetails();
                this.getOfferDetails();

            })
            .catch(error => {
                console.log('Error updating record --> '+JSON.stringify(error));
            });

    }


    handleChangeDisposition(event){
        console.log('this.selectedCustIds'+this.selectedCustIds);
        console.log('this.selectedCustIds.length: '+this.selectedCustIds.length);
        if(this.selectedCustIds == undefined || this.selectedCustIds == null || this.selectedCustIds.length ==0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select atlest one customer',
                    variant: 'Error',
                }),
            );
        }
        else{
            console.log(' event.target.value', event.target.value);
            if(event.target.value == 'Match found'){
                this.showRemarksModal = false;
                try{
                updateCustomerDisposition({
                    selectedIds : this.selectedCustIds,
                    remarks : this.remarks,
                    status: 'Match found',
                    loanId : this.recordId,
                    loanNames : this.selectedLoanIds
                }).then(resp=>{
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Disposition Updated Successfully',
                            variant: 'Success',
                        }),
                    );
                    this.getDuplicateCustomerList();
                    // console.log(' this.dupCustList', this.dupCustList);
                    // this.dupCustList.forEach(record => {
                    //     record.isSelected=false;
                    // });

                    this.selectedCustIds = [];
                    this.selectedLoanIds = [];
                    console.log(' this.dupCustList 158', this.dupCustList);

                }).catch(error=>{
                    this.dupCustList.forEach(record => {
                        record.isSelected=false;
                    });
                    this.selectedCustIds = [];
                    this.selectedLoanIds = [];

                })}catch(e){
                    console.log(' error ', e.message);
                }
            }
            else{
                this.showRemarksModal = true;
            }
        }
    }

    handleSaveRemarks(event){
        console.log('1350------');
        if(this.remarks == null || this.remarks == undefined){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter remarks',
                    variant: 'Error',
                }),
            );
        }
        else{
            console.log('1361------');
            updateCustomerDisposition({
                        selectedIds : this.selectedCustIds,
                        remarks : this.remarks,
                status: 'Match not found',
                loanId : this.recordId,
                loanNames : this.selectedLoanIds
                    }).then(resp=>{
                console.log('1366------');
                this.showRemarksModal = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Disposition Updated Successfully',
                        variant: 'Success',
                    }),
                );
                this.getDuplicateCustomerList();
                // this.dupCustList.forEach(record => {
                //     record.isSelected=false;
                // });
                this.selectedCustIds = [];
                this.selectedLoanIds = [];
                console.log(' this.dupCustList 158', this.dupCustList);
                    }).catch(error=>{
                this.showRemarksModal = false;
                this.dupCustList.forEach(record => {
                            record.isSelected=false;
                });
                this.selectedCustIds = [];
                this.selectedLoanIds = [];
            })
        }
    }

    hideModalBoxCancel(event){
        this.showRemarksModal = false;
    }

    handleRemarksChange(event){
        this.remarks = event.target.value;
    }

    modalOpen = false;
    custIdForCustomer;

    handleViewLoanDetail(event) {
        console.log('Cust Id :', event.target.name);
        if(event.target.name){
            this.custIdForCustomer = event.target.name;
            this.modalOpen = true;
        }else{
            this.showToast('Error', 'Loan details were not found for this customer.', 'error');
        }
    }

    onhandleclose(){
        console.log('On Close');
        this.modalOpen = false;
    }

    handleChangeApplicant(event){
        console.log('event.target.name', event.target.dataset.id);
        console.log('event.target.name', event.target.value);
        console.log('event.target.name', event.target.dataset.name);
        const applicantId= event.target.value;
        const accountId = event.target.dataset.id;
        const custId = event.target.dataset.name;
        var customer = this.dupCustList.find(cust => cust.customerNumber === custId);

        const isDuplicate = this.dupCustList.some(
            cust => cust.selectedValue == applicantId
        );

        if (isDuplicate) {
            this.showToast('Duplicate Selection', 'This applicant is already selected.', 'error');
            event.target.value = '';
            return; 
        }else{
            var inputWrapper = {
                custId: custId,
                applicantId: applicantId,
                loanId:this.recordId,
                custUniqueId: applicantId,
                accId: accountId,
                fromDedupeCmp: true,
                accToBeTagged: {
                    Id: accountId,
                    Duplicate_Customer_Source__c: customer.sourceSystem,
                    Applicant_Identifier__c: customer.custUniqueId
                }
            };
            updateApplicantRecords({
                inputStr: JSON.stringify(inputWrapper)
            })
            .then(resp=>{
                console.log('1239------', resp);
                this.getDuplicateCustomerList();
            })
        }
    }

    fetchDuplicateLoans(){
        getApplicantsByLoanApplication({ loanApplicationId: this.recordId })
        .then((response) => {
            console.log('response app188', JSON.stringify(response));
            if (response && response.length > 0) {
                this.applicantList = response;
                this.callDedupeAPISequentially(); // continue with dedupe process
            } else {
                this.showToast('Info', 'No applicants found for this Loan Application.', 'info');
                this.spinner = false;
            }
        })
        .catch((error) => {
            console.error('Error fetching applicants:', error);
            this.showToast('Error', 'Unable to fetch applicants.', 'error');
            this.spinner = false;
        });
    }

    async callDedupeAPISequentially() {
        if (this.currentApplicantIndex < this.applicantList.length){
            const applicant = this.applicantList[this.currentApplicantIndex];
            console.log('this.currentApplicantIndex ---', this.currentApplicantIndex );
            console.log('this.currentApplicantIndex ---', this.applicantList.length );

            try {
                const response = await checkDedupeAtExist({ applicantId: applicant.Id });
                console.log('response----', response);
                
                if (response == true) {
                    this.modalVisibility = false;
                    this.errorModal = false;
                }

            } catch (error) {
                console.error('Error during Dedupe API call for applicant:', applicant.Id, error);
                this.showToast('Error', `Dedupe failed for applicant ${applicant.Name || applicant.Id}`, 'error');
            } finally {
                this.currentApplicantIndex++;
                setTimeout(() => {
                    this.callDedupeAPISequentially();
                }, 100);
            }
        }else{
            setTimeout(() => {
                this.getDedupeList();
            }, 500);
            this.getDuplicateCustomerList();
        }
    }
}