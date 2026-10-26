import { LightningElement,wire,api,track } from 'lwc';
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import FORM_FACTOR from '@salesforce/client/formFactor';
import getQueryTypes from '@salesforce/apex/QueryModuleController.getQueryTypes';
import getCurrentUserName from '@salesforce/apex/QueryModuleController.getCurrentUserName';
import getRequestedFromUsers from '@salesforce/apex/QueryModuleController.getRequestedFromUsers';
import getQueryCategory from '@salesforce/apex/QueryModuleController.getQueryCategory';
import setRecordButtons from '@salesforce/apex/QueryModuleController.setRecordButtons';
import sendNotification from '@salesforce/apex/QueryModuleController.sendNotification';
import getDocumentChecklist from '@salesforce/apex/QueryModuleController.getDocumentChecklist';
import getRequirementLevelOptions from '@salesforce/apex/QueryModuleController.getRequirementLevelOptions'
import assignQueryRecord from '@salesforce/apex/QueryModuleController.assignQueryRecord'
import getQueuesForOpportunity from  '@salesforce/apex/QueryModuleController.getQueuesForOpportunity'
import getPreCreatedDocumentChecklist from '@salesforce/apex/QueryModuleController.getPreCreatedDocumentChecklist'
import getLoanId  from '@salesforce/apex/QueryModuleController.getLoanId';
import { NavigationMixin } from "lightning/navigation";
import { CurrentPageReference } from 'lightning/navigation';
import assignDocQueryRecord from '@salesforce/apex/QueryModuleController.assignDocQueryRecord'
import getallApplicants  from '@salesforce/apex/QueryModuleController.getallApplicants'; 
import checkdocrequiredfor  from '@salesforce/apex/QueryModuleController.checkdocrequiredfor';
import createchecklistrecord  from '@salesforce/apex/QueryModuleController.createchecklistrecord';
import sendQueryEmail from '@salesforce/apex/QueryModuleController.sendQueryEmail';
import initiateAPIRequest from '@salesforce/apex/EmailController.initiateAPIRequest';

export default class QueryModuleChildCmp extends NavigationMixin (LightningElement){
    @api recordId;
    headerTitle= 'Assign Query';
    selectedQueryType;
    queryTypeOptions = [];
    requestedFromUsers =[];
    showMultiSelect = false;
    queryCategoryOptions= [];
    assingedUsers=[];
    selectedQueryCategory;
    showQueryCategory = false;
    remarks = ''; 
    showRemarksError = false;
    status = 'Open';
    fieldAPIName;
    objectAPIName;
    fieldValue;
    previousFieldValue;
    isMobile=false;
    buttonTrackers = []
    showdocumentChecklist  = false;
    documentOptions = [];
    selectedDocument = false;;
    documentChecklist = [];
    showRequirementLevelField = false;
    requirementLevel = '';
    currentUserId;
    showDropdown = false;
    isLoaded= false;
    requirementLevelList  = [];
    selectedRequirementLevel;
    addedDocList=[];
    queueFromOpportunity =[];
    selectedDocMasterName;
    isRendered=false;
    queueListUsers =[];
    selectedUsers = [];
    loanId;
     @api widthPercentage = '100'
    @api documentChecklistId;
    @api moduleName = 'Document Module';
    headerTitle = 'Assign Query';
    assignedUsersMap = {};
    docremarks;
    inputValuesMap = {};
    assignedQueueMap = {};
    applicantOptions = [];
    showApplicants = false;
    dmId;
    selectedappId = [];
    @track fcu = false;
    acceptedFormats = ['.pdf', '.jpg', '.jpeg', '.png'];
    openModal()             {this.isModalOpen = true}
    closeModal()            {this.isModalOpen = false}
    loadComponent()         {this.isLoaded = true}
    setFormFactor()         {this.isMobile =  FORM_FACTOR == 'Large' ? false : true}
    @wire(CurrentPageReference)
        getPageReference(pageRef) {
            if (pageRef) {
                // Check the state for the recordId parameter.
                this.recordId = pageRef.state.recordId || this.recordId;
                // For debugging:
                console.log('Record Id from URL:', this.recordId);
            }
        }
  
     init(){
        console.log('before init the record id---',this.recordId);
        if(this.loanId != undefined && this.loanId != null && this.loanId!= ''){ 
            this.recordId = this.loanId;
        }
        setRecordButtons({recordId : this.recordId}).then(response=>{
            console.log('response ',JSON.stringify(response));
            this.setResponse(response);
            this.loadComponent();
          
        }).catch(error=>{
            console.error(`The Error in setRecordButtons method is : ${JSON.stringify(error)}`);
            this.isLoaded = false;
        })
    }
   
    connectedCallback() {
        console.log('Legal Record Id', this.recordId);
        console.log('recordId---'+this.moduleName);
        if(this.moduleName == 'FCU Module'){
            this.fcu = true;
        }
        else{
            this.fcu = false;
        }
        this.getLoanId();
        this.fetchQueryTypes(this.moduleName);
        console.log('recordId---'+this.widthPercentage);
        this.init();
       this.fillApplicantOptions();
        
        // this.handleOutsideClick = this.handleOutsideClick.bind(this);
    }
    getPreCreatedDocumentChecklist(documentChecklistId){
        console.log('Inside 101----',documentChecklistId)
        console.log('Inside 101----',this.documentChecklistId)
        getPreCreatedDocumentChecklist({documentChecklist:documentChecklistId,recordId:this.recordId,loanId:this.loanId})
        .then(result => {
            console.log('result--104--',result);
            this.addedDocList = [...result];
            if(this.addedDocList && this.addedDocList.length > 0){
                this.selectedDocument = true;
                this.showdocumentChecklist = true;
                this.selectedQueryType ='Document';
            }
            else{
                this.selectedDocument = false;
            }
        })
        .catch(error => {
        })
    }

    getLoanId(){
        console.log('145 get loan Id');
        getLoanId({
            recordValue:this.recordId
            
        })
        .then(result => {
            this.loanId = result;
            
            console.log('154 get loan Id');
            this.getCurrentUser();
            this.fetchRequestedFromUsers();
            
            this.fetchQueue();
            this.fetchQueryCategroy(this.moduleName);
            if(this.documentChecklistId != null && this.documentChecklistId != undefined && this.documentChecklistId != ''){
                this.getPreCreatedDocumentChecklist(this.documentChecklistId);
            }
           
        })
        .catch(error => {
            console.log('165 get loan Id');
        })

    }
  
    fetchQueryTypes(moduleName) {
        getQueryTypes({ moduleName })
            .then(result => {
                this.queryTypeOptions = result.map(item => ({
                    label: item,
                    value: item
                }));
            })
            .catch(error => {
                console.error('Error fetching query types 1:', error);
            });
    }
    fetchQueryCategroy(moduleName){
        getQueryCategory({ moduleName })
        .then(result => {
            this.queryCategoryOptions = result.map(item => ({
                label: item,
                value: item
            }));
        })
        .catch(error => {
            console.error('Error fetching query types 2:', error);
        });

    }
    fetchRequestedFromUsers() {
        // console.log('this.loanId----',this.loanId)
        // if(this.loanId != undefined && this.loanId != null && this.loanId!= ''){ 
        //     this.recordId = this.loanId;
        // }
        console.log('recordId -->', this.recordId);
        getRequestedFromUsers({
            recordValue:this.recordId
        })
        .then(result => {
            console.log('Result requested Users', result);
            this.requestedFromUsers = result.map(item => ({
                label: item.userName,
                value: item.userId
            }));
            this.showMultiSelect=true;
            console.log('requestedFromUsers----'+JSON.stringify(this.requestedFromUsers));            
        })
        .catch(error => {
            console.error('Error fetching query types 3:', error);
        });
    }

    fetchQueue(){
        // console.log('this.loanId----',this.loanId)
        // if(this.loanId != undefined && this.loanId != null && this.loanId!= ''){ 
        //     this.recordId = this.loanId;
        // }
        getQueuesForOpportunity({
            recordId:this.recordId
        })
        .then(result => {
            console.log('result', result);
            if(result != null){
            this.queueFromOpportunity = result.map(item => ({
                label: item.queueName,
                value: item.queueId
            }));
            this.show=true;
            console.log('queueFromOpportunity----'+JSON.stringify(this.queueFromOpportunity));

            }
            
        })
        .catch(error => {
            console.error('Error fetching query types 4:', error);
        });
    }

    handleQueryTypeChange(event) {
        this.selectedQueryType = event.detail.value;
        this.showQueryCategory = false;
        console.log('Selected Query Type:', this.selectedQueryType);
        if(this.selectedQueryType =='Document'){
           if( this.documentChecklistId != null && this.documentChecklistId != undefined && this.documentChecklistId != ''){
            this.showDocumentChecklist=false;
            this.selectedDocument = true;
            this.getPreCreatedDocumentChecklist(this.documentChecklistId );
           }
           else{
            this.showdocumentChecklist= true;
            this.showQueryCategory = false;
            this.queryCategoryOptions = '' ;
           }
        }else{
            this.showdocumentChecklist= false;
            this.showQueryCategory = true;
            this.selectedDocument = false;
            console.log('moduleName : '+this.moduleName);
            this.fetchQueryCategroy(this.moduleName);
            if( this.documentChecklistId != null && this.documentChecklistId != undefined && this.documentChecklistId != ''){
                this.showDocumentChecklist=false;
                this.selectedDocument = false;
                //this.getPreCreatedDocumentChecklist(this.documentChecklistId );
               }
        }
      
      
        
    }
    handleQueryCategoryChange(event) {
        this.selectedQueryCategory = event.detail.value;
    }
    getCurrentUser() {
        getCurrentUserName()
            .then((result) => {

              this.currentUserName = result.userName;
              this.currentUserId=result.userId;
            })
            .catch((error) => {
                console.error('Error fetching user name', error);
            });
    }
handleRequestFromUsersDoc(event) {
    const docId = event.target.dataset.id;
    console.log('docId:', docId);
    console.log('event.detail:', JSON.stringify(event.detail));

    const selectedList = event.detail.selectedList;
    console.log('selectedList:', selectedList);

    // Initialize map if needed
    if (!this.assignedUsersMap) {
        this.assignedUsersMap = {};
    }

    // Get current list for the docId, or start fresh
    const currentList = this.assignedUsersMap[docId] || [];

    // Create a new list with only the selected users (removing any unselected)
    const updatedList = [];

    selectedList.forEach(user => {
        if (!updatedList.includes(user)) {
            updatedList.push(user); // Avoid duplicates
        }
    });

    // Update or delete the entry based on whether list is empty
    if (updatedList.length > 0) {
        this.assignedUsersMap[docId] = updatedList;
    } else {
        delete this.assignedUsersMap[docId]; // Clean up if empty
    }

    console.log('Updated assignedUsersMap:', JSON.stringify(this.assignedUsersMap));
}

    handleRequestFromUsers(event){
        let docId = event.target.dataset.id;
        console.log('docId '+docId);
        console.log('event.detail=:'+JSON.stringify(event.detail));
        var userList = event.detail.selectedList;
        console.log('userList=:'+userList);
        console.log('userList.length=:'+userList.length);
        this.assingedUsers = [];
        if(userList.length>0){
            for(var i=0;i<userList.length;i++){
                this.assingedUsers.push(userList[i]);
            }
        }
        
    }
    handleQueueChange(event) {
        console.log('event.detail=:', JSON.stringify(event.detail));
        let queueList = event.detail.selectedList;
        console.log('queueList=:', queueList);
        console.log('queueList.length=:', queueList.length);
    
        if (queueList.length > 0) {
            queueList.forEach(queueUser => {
                // Check if the user already exists in the list
              
                    this.queueListUsers.push(queueUser);
                
            });
        }
    
        console.log('Updated queueListUsers:', this.queueListUsers);
    }
    handleInputChange(event) {
        let docId = event.target.dataset.id;
        let inputValue = event.target.value;
        console.log('docId:', docId, 'Input Value:', inputValue);
        // Store the input value against the docId
        this.inputValuesMap[docId] = inputValue;
        console.log('Updated inputValuesMap:', JSON.stringify(this.inputValuesMap));
    }
    handleDocQueueChange(event){
        console.log('event.detail:', JSON.stringify(event.detail));
        let queueId = event.target.dataset.id;  // Assuming each queue has a unique ID
        let queueList = event.detail.selectedList;
        console.log('queueId:', queueId);
        console.log('queueList:', queueList);
        // Ensure `assignedQueueMap` is initialized
        if (!this.assignedQueueMap) {
            this.assignedQueueMap = {};
        }
        if (queueList.length > 0) {
            // Initialize queueId in the map if not present
            if (!this.assignedQueueMap[queueId]) {
                this.assignedQueueMap[queueId] = [];
            }
            // Append users ensuring uniqueness
            queueList.forEach(queueUser => {
                if (!this.assignedQueueMap[queueId].includes(queueUser)) {
                    this.assignedQueueMap[queueId].push(queueUser);
                }
            });
        }
        console.log('Updated assignedQueueMap:', JSON.stringify(this.assignedQueueMap));
    }
    
    
    
    handleRemarksChange(event) {
        this.remarks = event.target.value;
        if (this.remarks) {
            this.showRemarksError = false;
        }
        console.log('Remarks:', this.remarks);  
    }

    handleRemarksBlur() {
        this.showRemarksError = !this.remarks;
    }

    get remarksContainerClass() {
        return this.showRemarksError
            ? 'remarks-field-container slds-form-element slds-has-error'
            : 'remarks-field-container slds-form-element';
    }

    setResponse(response) {
        console.log('Response button tracker--- '+ JSON.stringify(response));
        
        this.buttonTrackers = response.buttons.map(button => {
            let buttonClass = 'button-green'; 
            if (button.name === 'Assign Query') {
                buttonClass = 'button-green';
            } else if (button.name === 'Re-assign Query') {
                buttonClass = 'button-red';
            }
            // }else if (button.name === 'Approve') {
            //     buttonClass = 'button-green';
            // }
            // else if (button.name === 'Reassign') {
            //     buttonClass = 'button-green';
            // }
            // else if(button.name=='Underwriters Disposition'){
            //     buttonClass='button-green';
            // }
    
            return {
                ...button,
                buttonClass,
            };
        });
        if(this.buttonTrackers.length>0){
            if(this.buttonTrackers[0].name == 'Assign Query'){
                this.assignButtonlabel = 'Assign Query';
                this.assignHeader = 'Assign Query';
                this.greenColour=true;
                console.log('button----'+   this.greenColour);
            }else if(this.buttonTrackers[0].name == 'Re-assing Query'){
                console.log('button----'+   this.greenColour);
                 this.greenColour=false;
            }
        }
      
       
        
        this.fieldAPIName = response.fieldAPIName;
        this.objectAPIName = response.objectAPIName;
        this.fieldValue = response.fieldValue;
        this.previousFieldValue = response.previousFieldValue;
       
    }

    get buttonClass() {
        return this.greenColour ? 'button-green' : 'button-red';
    }
    
    // updateRecordStatus(evt){
    //     this.buttonValue = evt.target.value;
    //     setTimeout(()=>{
    //         console.log('this.objectAPIName::'+this.objectAPIName);
    //         console.log('this.buttonValue'+this.buttonValue);
    //         console.log('this.showButtons'+this.showButtons);
    //         console.log('this.buttonValue -->'+this.buttonValue);
    //         console.log('this.recordif-->',this.recordId);
    //         switch (this.buttonValue) {
    //             case 'Assign Query':
    //                 console.log('Sent Back By Area Manager ------');
    //                 // this.openRemarkModal()
    //                 break
              
    //             case 'Re-assign Qeury':
    //                 this.openReassingModal()
    //                 break
    //             default:
    //                 this.updateRecords()
    //         }
    //     },1000)
    // }

    // updateRecords(){
    //     const fields = {};
    //     fields['Id'] = this.recordId;
    //     fields[this.fieldAPIName] = this.buttonValue
    //     console.log('field api -->',this.fieldAPIName);
    //      const recordInput = { fields };
    //     console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
    //     updateRecord(recordInput)
    //     .then(() => {
    //          this.performAction()
    //          this.init();
    //             this.sendToastMessage('Success','Record assigned successfully.','success');
    //             this.performAction()
    //             fireEvent(this.pageRef, "handleRecordrefresh", "handleRecordrefresh");
               
           
    //     })
    //     .catch(error => {
    //         console.log('Error updating record --> '+JSON.stringify(error));
    //     });
    // }

    updateRecordStatus(event){
        console.log('Button Clicked');
        this.buttonValue = event.target.value;
        console.log('this.buttonValue----',this.buttonValue);
        console.log('Updated queueListUsers:', this.queueListUsers);
        console.log('this.loanId :',this.loanId);
        console.log('this.addedDocList updateRecordStatus: '+JSON.stringify(this.addedDocList));
        console.log('selectedQueryType: ', this.selectedQueryType);
        console.log('assingedUsers: ', this.assingedUsers);
        if(this.loanId != undefined && this.loanId != null && this.loanId!= ''){ 
            this.recordId = this.loanId;
        }
        console.log('Updated queueListUsers: 388', this.queueListUsers);
        
        if(this.selectedQueryType){
            if(this.selectedQueryType !='Document'){
                if(this.remarks && this.assingedUsers.length > 0 && this.selectedQueryCategory){
                    assignQueryRecord({
                        recordId: this.recordId,
                        buttonValue: this.buttonValue,
                        requestedFromUsers:this.assingedUsers,
                        docWrapper:JSON.stringify(this.addedDocList),
                        remarks:this.remarks,
                        queryTypeOptions:this.selectedQueryType,
                        queryCategoryOptions:this.selectedQueryCategory,
                        queue: this.queueListUsers
                    })
                    .then(response => {
                        console.log('response assignQueryRecord-----', response);
                        this.querryId = response;
                        this.sendEmail(this.querryId);
                        if( this.documentChecklistId != null && this.documentChecklistId != undefined && this.documentChecklistId != ''){
                            console.log('response-----', response);
                            this.buttonValue='';
                            this.requestedFromUsers = [];
                            this.docWrapper= '';
                            this.remarks = '';
                            this.queryTypeOptions = '';
                            this.queryCategoryOptions='';
                            this.showdocumentChecklist=false;
                            this.addedDocList = [];
                            this.selectedDocument = false;
                            this.sendToastMessage('Success','Record assigned successfully.','success');
                            this.dispatchEvent(new CustomEvent('closemodal'));
                            this.dispatchEvent(new CustomEvent('assignedquery'));
                            
                        }
                        else{
                        //this.performAction();
                        this.buttonValue='';
                        this.requestedFromUsers = [];
                        this.docWrapper= '';
                        this.remarks = '';
                        this.queryTypeOptions = '';
                        this.queryCategoryOptions='';
                        this.showdocumentChecklist=false;
                        this.addedDocList = [];
                        this.selectedDocument = false;
                        this.sendToastMessage('Success','Record assigned successfully.','success');
                        this.dispatchEvent(new CustomEvent('closemodal'));
                        

                        console.log('response===>'+JSON.stringify(response));
                        }
                    
                    
                    })
                    .catch(error => {
                    })
                }
                else{
                    this.sendToastMessage('Error','Please ensure that a query category is selected, users are added, and remarks are provided.', 'error');
                    return;
                }
            }
            else{
                console.log('this.addedDocList :: ', this.addedDocList);
                if(this.addedDocList && this.addedDocList.length > 0){
                    let allDocsHaveAssignedUsers = true;
                    for (let doc of this.addedDocList) {
                        if (!this.assignedUsersMap[doc.docId]) {
                            console.log(`No assigned users found for document ID: ${doc.docId}`);
                            this.sendToastMessage('Error','Please ensure users are assigned for all the documents' , 'error');
                            allDocsHaveAssignedUsers = false;
                            return;
                        }
                    }
                    for (let doc of this.addedDocList) {
                        if (!this.inputValuesMap[doc.docId]) {
                            console.log(`No remarks found for document ID: ${doc.docId}`);
                            this.sendToastMessage('Error','Please ensure remarks is added for all the documents', 'error');
                            allDocsHaveRemarks = false;
                            return;
                        }
                    }
                    console.log('assign ::' , {
                        recordId: this.recordId,
                        buttonValue: this.buttonValue,
                        docWrapper:JSON.stringify(this.addedDocList),
                        queryTypeOptions:this.selectedQueryType,
                        requestedFromUsers :this.assignedUsersMap,
                        queryCategoryOptions:this.selectedQueryCategory,
                        queue : this.assignedQueueMap,
                        remarks :  this.inputValuesMap
                    });
                    assignDocQueryRecord({
                        recordId: this.recordId,
                        buttonValue: this.buttonValue,
                        docWrapper:JSON.stringify(this.addedDocList),
                        queryTypeOptions:this.selectedQueryType,
                        requestedFromUsers :this.assignedUsersMap,
                        queryCategoryOptions:this.selectedQueryCategory,
                        queue : this.assignedQueueMap,
                        remarks :  this.inputValuesMap
                    })
                    .then(response=>{
                        console.log('response-----', response);
                        this.querryId = response;
                        this.sendEmail(this.querryId);  
                        this.buttonValue='';
                        this.requestedFromUsers = [];
                        this.docWrapper= '';
                        this.remarks = '';
                        this.queryTypeOptions = '';
                        this.queryCategoryOptions='';
                        this.showdocumentChecklist=false;
                        this.addedDocList = [];
                        this.selectedDocument = false;
                        this.sendToastMessage('Success','Record assigned successfully.','success');
                        this.dispatchEvent(new CustomEvent('closemodal'));
                        this.dispatchEvent(new CustomEvent('assignedquery'));
                    })
                    .catch(error => {
                        console.log('error :: ', error)
                    })
                }
                else{
                    this.sendToastMessage('Error','Please ensure that at least one document is selected and that remarks are provided for it.','error');
                }
            }
        }
        else if(!this.selectedQueryType){
            this.sendToastMessage('Error','Please select the type of query.','error');
            return;
        }
    }

    sendEmail(querryId){
        console.log('querryId----',querryId);
        console.log('this.recordId: '+this.recordId);
        sendQueryEmail({ loanId: this.recordId, queryId: querryId, event: 'assigned' })
        .then(inputMaps => {
            console.log('inputMaps: '+JSON.stringify(inputMaps));
            const promises = inputMaps.map(map => {
                console.log('map: '+JSON.stringify(map));
                // return initiateAPIRequest(map)
                return initiateAPIRequest({ inputMap: map })
                .then(() => {
                    console.log('Email sent to:', map.email);
                    return { email: map.email, status: 'success' };
                })
                .catch(error => {
                    console.error('Failed for', map.email, error);
                    return { email: map.email, status: 'error', error };
                });
            });
            return Promise.all(promises);
        })
        .then(results => {
            console.log('All email results:', results);
        })
        .catch(error => {
            console.error('Error initiating query email process:', error);
        });
    }
    
    performAction(){
        console.log(`The Value is : ${this.buttonValue}  ${this.objectAPIName}`)
        if(this.buttonValue==='Assigned'){
            console.log(`The Value is : ${this.buttonValue}  ${this.objectAPIName}`)
            this.sendNotification(this.assingedUsers);
        }
    }
    sendNotification(assignedUsers){
        console.log('this.loanId----',this.loanId)
        if(this.loanId != undefined && this.loanId != null && this.loanId!= ''){ 
            this.recordId = this.loanId;
        }
        sendNotification({recordId : this.recordId,status:this.buttonValue,assignedUserIds:assignedUsers}).then(response=>{
        }).catch(error=>{
            console.error(`The Error is : ${JSON.stringify(error)}`)
        })
    }

    sendToastMessage(title,message,variant){
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        }));
    }
    handleFocus() {
        console.log('Enters Focus');
        this.fetchDocumentChecklist('');
    }

    handleDocumentSearch(event) {
        this.searchTerm = event.detail.value;

        if (this.searchTerm.length >= 2) {
            this.fetchDocumentChecklist(this.searchTerm);
        }
    }
    fetchDocumentChecklist(searchTerm) {
        console.log('this.loanId----',this.loanId)
        if(this.loanId != undefined && this.loanId != null && this.loanId!= ''){ 
            this.recordId = this.loanId;
        }
        console.log('this.recordId 695----',this.recordId)
        console.log('this.currentUserId 695----',this.currentUserId)
        getDocumentChecklist({ recordId: this.recordId, searchTerm: searchTerm,requestedByUser:this.currentUserId})
            .then(result => {
                console.log('result----'+JSON.stringify(result));
              
                this.showDropdown = true;
                // document.addEventListener('click', this.handleOutsideClick);
                this.documentChecklist = result.map(doc => ({
                    label: doc.documentName,
                    value: doc.documentName,
                    requirementLevel: doc.requirementLevel,
                    showPreview: doc.showPreview,
                    documentDescription: doc.documentDescription,
                    documentRecievedFrom:doc.fromDocMaster,
                    docContentId:doc.documentContentId,
                    docId:doc.docId
                }));
                console.log('documentChecklist=:'+JSON.stringify(this.documentChecklist));
             
           })
            .catch(error => {
                console.error('Error fetching document checklist:', error);
            });
    }
    // handleDocumentSearch(event) {
    //     const searchTerm = event.detail.value;
    //     this.fetchDocumentChecklist(searchTerm);
    // }

  
    // handleRequirementLevelChange(event) {
    //     this.requirementLevel = event.detail.value;
    // }
    handleDocumentSelection(event) {
        const selectedValue = event.target.value;
        console.log('selectedValue '+selectedValue);
        console.log('addedDocList '+this.addedDocList);
        const isAlreadyAdded = this.addedDocList.some(doc => doc.value === selectedValue);
        if (isAlreadyAdded) {
            this.sendToastMessage('Error', 'Document Already Added', 'error');
            return;
        }
        else{
            const selectedDoc = this.documentChecklist.find(doc => doc.value === selectedValue);
            console.log('selectedDoc.documentRecievedFrom---',selectedDoc)
            if(selectedDoc){
                console.log('selectedDoc.documentRecievedFrom---',selectedDoc.documentRecievedFrom)
                if(selectedDoc.documentRecievedFrom == false && event.target.value!='' && event.target.value!= null && event.target.value!=undefined){
                    console.log('selectedDoc.documentRecievedFrom-320--',selectedDoc.documentRecievedFrom);
                    var maxSeq;
                    if(this.addedDocList == undefined || this.addedDocList == [] || this.addedDocList == '' || this.addedDocList==null || this.addedDocList.length == 0){
                        maxSeq = 1;
                    }
                    else{
                        maxSeq = this.addedDocList[this.addedDocList.length - 1].sequence + 1;
                    }
                    selectedDoc.sequence = maxSeq;
                    this.addedDocList.push(selectedDoc);
                    console.log('this.addedDocList=:'+JSON.stringify(this.addedDocList));
                    this.selectedDocument = true;
                }
                else if(selectedDoc.documentRecievedFrom==true){
                    console.log('selectedDoc.documentRecievedFrom--324-',selectedDoc.documentRecievedFrom);
                    this.addedDocList.push(selectedDoc);
                    this.selectedDocMasterName = selectedValue;
                    console.log('selectedDoc.docId : '+selectedDoc.docId);
                    this.dmId = selectedDoc.docId;
                    checkdocrequiredfor({docId:selectedDoc.docId})
                    .then(response => {
                        console.log('637 '+response);
                        if(response){
                            this.showApplicants = true;
                            this.fillApplicantOptions();
                        }
                        else{
                            this.showApplicants = false;
                            this.handleSave();
                        }
                    })  
                    // this.getRequirementLevelOptions(selectedDoc.requirementLevel,this.recordId);
                    console.log('selectedDoc.documentRecievedFrom---',selectedDoc.documentRecievedFrom);
                }
                else{

                }
                this.showDropdown = false;
                // document.removeEventListener('click', this.handleOutsideClick);
            }
            this.showDropdown = false;
        }
    }
    
    handleCloseListDocuments(){
        this.showDropdown = false;
    }
    handleEdit(){
        this.openEditModal= true;
    }
   
    handleDelete(event) {
        const docToDelete = event.target.dataset.id;
        console.log('docToDelete----',docToDelete)
   
        var tempList = [];
       
        for( var i=0;i<this.addedDocList.length;i++){
            if(this.addedDocList[i].docId != docToDelete){
                tempList.push(this.addedDocList[i]);
            }
        }
        this.addedDocList = tempList;
        //this.addedDocList = this.addedDocList.filter(doc => doc.sequence !== docToDelete);
        console.log(' this.addedDocList----', JSON.stringify(this.addedDocList));
    }
     
    get isAddedDocListNotEmpty() {
        return this.addedDocList && this.addedDocList.length > 0;
    }


    getRequirementLevelOptions(requirementLevel,recordId) {
        getRequirementLevelOptions({requirementLevel:requirementLevel, recordId:this.recordId})
        .then(result => {
            console.log('result-------',result)
            this.requirementLevelList = result.map(item => ({
                label: item.label,
                value: item.value
            }));
            this.showRequirementLevelField=true;
            
        })
        .catch(error => {
            console.error('Error fetching requirement level options:', error);
        });
    }
    handleRequirementLevelChange(event) {
        this.requirementLevel = event.detail.value;
        console.log('this.requirementLevel -----',this.requirementLevel );
        const selectedDoc = this.documentChecklist.find(doc => doc.value === this.selectedDocMasterName);
        var maxSeq;
        if(this.addedDocList == undefined || this.addedDocList == [] || this.addedDocList == '' || this.addedDocList==null || this.addedDocList.length == 0){
            maxSeq = 1;
        }
        else{
            maxSeq = this.addedDocList[this.addedDocList.length - 1].sequence + 1;
        }
        selectedDoc.sequence = maxSeq;
        this.addedDocList.push(selectedDoc);
        console.log('this.addedDocList=:'+JSON.stringify(this.addedDocList));
        this.selectedDocument = true;
        // this.showRequirementLevelField= false; 
    }

    handlePreview(event){
        const contentDocumentId = event.target.dataset.id;
        console.log('File Preview::' , event.target.dataset.id);
        if(event.target.dataset.id == '' || event.target.dataset.id == null || event.target.dataset.id == undefined){
            this.showToastMethod('Error', 'No file uploaded', 'Error');
            return;
        }
         const isCommunity = window.location.href.includes('/s/');

    if (isCommunity) {
        // For Experience Cloud users
        const baseUrl = window.location.origin + '/losportal/sfc/servlet.shepherd/document/download/' + contentDocumentId;
        console.log('Community Preview URL:', baseUrl);
        window.open(baseUrl); // Open in a new tab
    }
         else{
                
                this[NavigationMixin.Navigate]({
                    type:'standard__namedPage',
                    attributes:{
                        pageName:'filePreview'
                    },
                    state:{
                        selectedRecordId: event.target.dataset.id
                    }
                })
            }
        // else{
        //     console.log('File Preview ::' , event.target.dataset.id);
        //     window.open(`/${event.currentTarget.dataset.id}`, '_blank');
        // }
    }
    cssContainer = 'slds-modal__container';
    renderedCallback(){
        console.log('IN CHILD RENDER CALL BACK');
        switch(this.widthPercentage) {
            case '60':
                this.cssContainer = 'slds-modal__container width-60';
                break;
            case '70':
                this.cssContainer = 'slds-modal__container width-70';
                break;
            case '80':
                this.cssContainer = 'slds-modal__container width-80';
                break;
            case '90':
                this.cssContainer = 'slds-modal__container width-90';
                break;
            case '95':
                this.cssContainer = 'slds-modal__container width-95';
                break;
            case '100':
                    console.log('widthpercentage',this.widthPercentage)
                    this.cssContainer = 'slds-modal__container width-100';
                    break;
        }
        if(!this.isRendered){
            console.log('Inside if condition');
            this.isRendered = true;
            const style = document.createElement('style');
            style.innerText = `
            .uploadFile .slds-file-selector__text.slds-medium-show {
              display: none;
            }
            .uploadFile .slds-file-selector__button.slds-button.slds-button_neutral{
                font-size: 0!important;
            }
            .uploadFile svg.slds-button__icon.slds-button__icon_left {
                margin: 0;
            }
            .uploadFile lightning-primitive-file-droppable-zone.slds-file-selector__dropzone {
                border: none;
                padding: 0;
            }
            .uploadFile slds-form-element__label{
                display: none;
            }
            .info-button svg.slds-button__icon.slds-button__icon_left {
                margin: 0;
            }
            .class-file-upload .slds-form-element__label:empty {
                margin: 0;
                display: none;
            }
            .uploaded-view svg.slds-button__icon.slds-button__icon_left {
                color: green;
            }
            .uploaded-view svg.slds-button__icon {
                color: green;
            }
            `;
            this.template.querySelector('.styleContainer').appendChild(style);
        }
    }
    handleCloseModal(){
        this.dispatchEvent(new CustomEvent('closemodal'));
        
    }
    handleCloseDropdown(){
        this.showDropdown = false;
    }
    handleEmptyList(){
        // this.documentChecklist = [];
    }
    closeDropDown(){
        console.log('inside close dropdown');
        setTimeout(() => {
            this.showDropdown = false;
        }, 1000);
       
    }
    // handleOutsideClick = (event) => {
    //     if (!this.template.querySelector('.dropdown-container')?.contains(event.target)) {
    //         this.isOpen = false;
    //         document.removeEventListener('click', this.handleOutsideClick);
    //     }
    // };
    // disconnectedCallback() {
    //     document.removeEventListener('click', this.handleOutsideClick);
    // }

    get selectedUserNames() {
        return this.selectedUsers.map(user => user.label).join(', ');
    }

    handleUserSelection(event) {
        const userId = event.currentTarget.dataset.id;
        const userIndex = this.requestedFromUsers.findIndex(user => user.value === userId);

        if (userIndex !== -1) {
            this.requestedFromUsers[userIndex].selected = !this.requestedFromUsers[userIndex].selected;
        }

        this.selectedUsers = this.requestedFromUsers.filter(user => user.selected);
    }

    preventClose(event) {
        event.preventDefault(); // Prevents dropdown from closing when clicking inside
    }

    handleBlur(event) {
        const fieldName = event.target.dataset.field;
        const value = event.target.textContent.trim();
        
        console.log(`Field: ${fieldName}, Value: ${value}`);
        
        // Save or update logic here
    }

    fillApplicantOptions(){
        getallApplicants({loanId:this.recordId})
        .then(response => {
            this.applicantOptions = response;
            console.log('applicantOptions '+JSON.stringify(this.applicantOptions));
        })   
    }
    handleselectapplicant(event){
        console.log(event.target.checked);
        const selecteddocid = event.target.dataset.id;
        if(event.target.checked){
            this.selectedappId.push(selecteddocid);
        }else{
            let temp = [];
            this.selectedappId.forEach(record => {
                if(record != selecteddocid){
                    temp.push(record);
                }
            });
            this.selectedappId = temp;
        }

        console.log('selectedappId -->'+JSON.stringify(this.selectedappId));
    }
    handleSave(){
        console.log('960 this.selectedQueryType : '+this.selectedQueryType);
        if(this.selectedQueryType =='Document'){
            if(this.showApplicants){
                console.log('inside this.showApplicants:');
                if(this.selectedappId.length == 0){
                    this.sendToastMessage('Error', 'Please select at least one applicant', 'Error');
                    return;
                }
                else{
                    console.log('inside this.selectedappId.length > 0');
                    this.checkListCreation();
                }
            } else {
                console.log('inside this.showApplicants: else');
                this.checkListCreation();
            }
        }
    }

    checkListCreation(){
        createchecklistrecord({appIds : this.selectedappId, loanId: this.recordId,docMasterId : this.dmId})
        .then(result => {
            console.log('createchecklistrecord result----',result);
            console.log('this.addedDocList : ' + this.addedDocList);
            if(this.addedDocList!=null){
                this.addedDocList.push(...result);
            }
            else{
                this.addedDocList = [...result];
            }
            this.dmId = null;
            this.selectedappId = [];
            this.selectedDocument = true;
            this.showApplicants = false;
        }).catch(error => {
            console.error('Error createchecklistrecord:', error);
        });
    }

    handleFileUpload(event) {
        const docMasterId = event.target.dataset.id;
        console.log('docMasterId: '+docMasterId);
        // const uploadedFiles = event.detail.files;
        // console.log('uploadedFiles:', uploadedFiles);
        // uploadedFiles.forEach(file => {
        //     console.log('ContentDocumentId:', file.documentId);
        //     console.log('File Name:', file.name);
        // });
        const uploadedFile = event.detail.files[0];
        const contentDocumentId = uploadedFile.documentId;
        const fileName = uploadedFile.name;
        console.log('ContentDocumentId:', contentDocumentId);
        console.log('File Name:', fileName);
        this.addedDocList = this.addedDocList.map(doc => {
            if (doc.docId === docMasterId) {
                return {
                    ...doc,
                    showPreview: true,
                    docContentId: contentDocumentId
                };
            }
            return doc;
        });
        console.log('addedDocList: handleFile --> ' + JSON.stringify(this.addedDocList));
    }
}