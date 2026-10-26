import { LightningElement,api,track,wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import RELATIONSHIP_FIELD from '@salesforce/schema/Application_Verification__c.Relationship_Son_Daughter__c';
import CURRENT_STATUS from '@salesforce/schema/Application_Verification__c.Current_Status_Studying_Working__c';
import HIGHEST_LEVEL_OF_EDUCATION from '@salesforce/schema/Application_Verification__c.Highest_Level_of_Education__c';
import APPLICATION_VERIFICATION_OBJECT from '@salesforce/schema/Application_Verification__c';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkIfMobileNumber from "@salesforce/apex/Comm_ManualPdController.checkIfMobileNumber";
import deleteRefData from "@salesforce/apex/COMM_ItrScreenController.deleteRefData";

export default class CreditPdFormTable extends LightningElement {
    @api parentAvId;
    @api loanAppId;
    @api sectionTypeChildren;
    @api sectionTypeTradeRef;
    @api sectionTypeAsset;
    @api tradeRefListFromParent;
    @api assetListFromParent;
    @api childrenListFromParent;
    
    referenceRecordTypeId;
    showTable = true;
    wiredResult;
    recordTypeId;
    isAssetRow;
    @track finalListToReturn=[];
    isChildrenDetailsRow;
    @track relationshipOptions = [];
    @track currentStatusOptions = [];
    @track highestLevelOfEducationOptions = [];
     deleting = false;

    showErrorToast(message) {
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Validation Error',
            message: message,
            variant: 'error'
        })
    );
}



    @wire(getObjectInfo, { objectApiName: APPLICATION_VERIFICATION_OBJECT })
    objectInfo(result) {
        this.wiredResult = result;
        
        if (result.data) {
            const rtMap = result.data.recordTypeInfos;
            for (let key in rtMap) {
                const name = rtMap[key].name;
                if (name === 'Trade Reference') {
                    this.referenceRecordTypeId = key;
                    continue;
                }
                if (name === 'Asset') {
                    this.assetRecordTypeId = key;
                    continue;
                }
                if (name === 'Children Details') {
                    this.childrenRecordTypeId = key;
                    continue;
                }
            }
        }
    }
    @wire(getPicklistValues, {
  recordTypeId: '$childrenRecordTypeId',
  fieldApiName: RELATIONSHIP_FIELD
})
relationshipOptions({ data, error }) {
  if (data) {
    this.relationshipOptions = data.values.map(o => ({ label: o.label, value: o.value }));
  } else if (error) {
    console.error('Error Fetching Picklist Values:', error);
  }
}

@wire(getPicklistValues, {
  recordTypeId: '$childrenRecordTypeId',
  fieldApiName: CURRENT_STATUS
})
currentStatusOptions({ data, error }) {
  if (data) {
    this.currentStatusOptions = data.values.map(o => ({ label: o.label, value: o.value }));
  } else if (error) {
    console.error('Error Fetching Picklist Values:', error);
  }
}

@wire(getPicklistValues, {
  recordTypeId: '$childrenRecordTypeId',
  fieldApiName: HIGHEST_LEVEL_OF_EDUCATION
})
highestLevelOfEducationOptions({ data, error }) {
  if (data) {
    this.highestLevelOfEducationOptions = data.values.map(o => ({ label: o.label, value: o.value }));
  } else if (error) {
    console.error('Error Fetching Picklist Values:', error);
  }
}


    @track tradeReferenceList = [];
    @track assetList = [];
    @track childrenList = [];
    
    get isChildrenDetails(){
        console.log('inside childrendetails getter',this.sectionTypeChildren);
        return (this.sectionTypeChildren === 'Children'? true : false);
    }
    get isTradeReference(){
        console.log('inside trade reference getter',this.sectionTypeTradeRef);
        return (this.sectionTypeTradeRef === 'TradeReference'?true : false);
    }
    get isAsset(){
        console.log('inside asset getter',this.sectionTypeAsset);

        return (this.sectionTypeAsset === 'Asset'?true : false);
    }
    
    async connectedCallback() {
       
        console.log('connectedCallback');
        console.log('this.loanAppId',this.loanAppId);
        console.log('this.parentAvId',this.parentAvId);
        
           await refreshApex(this.wiredResult);
         console.log('this.ref in connected>',this.referenceRecordTypeId);
        this.isAssetRow = true;
        this.isChildrenDetailsRow = true;
        if(this.tradeRefListFromParent && this.tradeRefListFromParent.length > 0) {
            console.log('inside if');
            this.tradeReferenceList = [...this.tradeRefListFromParent];
            console.log('this.tradeReferenceList',this.tradeReferenceList);
        }
        else{
            this.tradeReferenceList = [

                {
                Loan_Application__c :this.loanAppId,
                Parent_FCU__c : this.parentAvId,
                Trade_Reference_Mobile_Number__c : '',
                Trade_Reference_Name__c : '',
                Trade_Reference_Relationship__c : '',
                Trade_Reference_Remarks__c : '',
                RecordTypeId: 'Trade Reference'
                }
            ];
        }
        console.log('tradeRefDetails in table>',JSON.stringify(this.tradeReferenceList));
        if(this.assetListFromParent && this.assetListFromParent.length > 0) {
            console.log('inside if assetListFromParent');
            this.assetList = [...this.assetListFromParent];
            console.log('this.assetList',this.assetList);
        }
        else{
            this.assetList = [
                {
                Loan_Application__c :this.loanAppId,
                Parent_FCU__c : this.parentAvId,
                Type_of_Asset__c : '',
                Year_of_Purchase__c:'',
                Name_of_the_Asset_Owner__c:'',
                Amount_of_Investment__c :'',
                Proof__c:'',
                RecordTypeId: 'Asset'
                }
            ]
        }
        if(this.childrenListFromParent && this.childrenListFromParent.length > 0) {
            console.log('inside if childrenListFromParent');
            this.childrenList = [...this.childrenListFromParent];
            console.log('this.childrenList',this.childrenList);
        }
        else{
        this.childrenList = [
            {
            Loan_Application__c :this.loanAppId,
            Parent_FCU__c : this.parentAvId,
            Child_Name__c : '',
            Relationship_Son_Daughter__c:'',
            Child_Age__c : '',
            Current_Status_Studying_Working__c : '',
            Highest_Level_of_Education__c:'',
            Occupation_Details__c : '',
            RecordTypeId: 'Children Details'
            }
        ]
    }
    }
    @api
    handleAddRow(sectionName) {
        if(sectionName === 'TradeReference'){
            console.log('inside trade reference');
            this.tradeReferenceList = [
                ...this.tradeReferenceList,
                {
                Loan_Application__c :this.loanAppId,
                Parent_FCU__c : this.parentAvId,
                Trade_Reference_Mobile_Number__c : '',
                Trade_Reference_Name__c : '',
                Trade_Reference_Relationship__c : '',
                Trade_Reference_Remarks__c : '',
                RecordTypeId: 'Trade Reference'
                }
            ];
        }
        else if(sectionName === 'Asset'){
            console.log('inside asset');
            this.isAssetRow = true;
            this.assetList = [
                ...this.assetList,
                {
                    Id:Date.now().toString(),
                    Loan_Application__c :this.loanAppId,
                    Parent_FCU__c : this.parentAvId,
                    Type_of_Asset__c : '',
                    Year_of_Purchase__c:'',
                    Name_of_the_Asset_Owner__c:'',
                    Amount_of_Investment__c :'',
                    Proof__c:'',
                    RecordTypeId: 'Asset'
                }
            ]
        }
        else if(sectionName === 'Children'){
            console.log('inside children');
            this.isChildrenDetailsRow = true;
            this.childrenList = [
                ...this.childrenList,
                 {
                    Loan_Application__c :this.loanAppId,
                    Parent_FCU__c : this.parentAvId,
                    Child_Name__c : '',
                    Relationship_Son_Daughter__c:'',
                    Child_Age__c : '',
                    Current_Status_Studying_Working__c : '',
                    Highest_Level_of_Education__c:'',
                    Occupation_Details__c : '',
                    RecordTypeId: 'Children Details'
                 }
            ]
        }
    }

    
    handleChange(event) {
        try{
       // const index = event.target.dataset.index;
        const fieldName = event.target.dataset.id;
        const index = event.target.dataset.index;
        const sectionName = event.target.dataset.name;

        console.log('loanappid',this.loanAppId);
        console.log('avId',this.parentAvId);
        console.log('sectionName',sectionName);
        console.log('original array>',JSON.stringify(this.tradeReferenceList));
        const value = (event.detail && event.detail.value !== undefined) ? event.detail.value : event.target.value;

        if(sectionName == 'TradeReference' && fieldName === 'Trade_Reference_Mobile_Number__c') {
            const mobileRegex = /^\d{10}$/; // Exactly 10 digits
            if (!mobileRegex.test(value)) {
                this.showErrorToast('Please enter valid mobile number.');
                return false;
            }
            //
            
            checkIfMobileNumber({
                 recordId: this.loanAppId,
                 appVeriId : this.parentAvId,
                 mobileNumer :value
             })
                .then((response) => {
                    if(response) {
                        this.showErrorToast('Mobile number already exists.');
                        const inputEl = this.template.querySelector('lightning-input[data-id="Trade_Reference_Mobile_Number__c"]');
                        if (inputEl) {
                            inputEl.value = '';  // Clear the input value
                        }
                        return false;
                    }else {

                    }
                })
                .catch((error) => {

                });

            //
        }

          if (sectionName === 'Children' && fieldName === 'Child_Age__c') {
            if (value.length > 2) {
             event.target.value = value.slice(0, 2);
                    this.showErrorToast('Age cannot be more than 2 digits');
              return;
            } 
             const updatedRow = {
        ...this.childrenList[index],
        [fieldName]: value,
        isRowAdded: true
    };
            this.childrenList[index] = updatedRow;
            this.finalListToReturn = [...this.childrenList];
        }
        else if (sectionName === 'Children') {
            const updatedRow = { ...this.childrenList[index], [fieldName]: value, isRowAdded: true };
            this.childrenList[index] = updatedRow;
            this.finalListToReturn = [...this.childrenList];
        }
         else if (sectionName === 'TradeReference') {
            let updatedRow = { ...this.tradeReferenceList[index] };
            updatedRow[fieldName] = value;
            updatedRow.isRowAdded = true;
            this.tradeReferenceList[index] = updatedRow;
            this.finalListToReturn = [...this.tradeReferenceList];
        } 
        else if (sectionName === 'Asset') {
            let updatedRow = { ...this.assetList[index] };
            updatedRow[fieldName] = value;
            updatedRow.isRowAdded = true;
            this.assetList[index] = updatedRow;
            this.finalListToReturn = [...this.assetList];
        }
       /* if(sectionName === 'TradeReference') {
            let updatedRow = {...this.tradeReferenceList[index]};
            updatedRow[fieldName] = value;
            //this.tradeReferenceList[index][fieldName] = value;
            updatedRow.isRowAdded = true;
            this.tradeReferenceList[index] = updatedRow;
            this.finalListToReturn = [
                ...this.tradeReferenceList
            ];
        } else if (sectionName === 'Asset') {
             let updatedRow = {...this.assetList[index]};
            updatedRow[fieldName] = value;
             updatedRow.isRowAdded = true;
            this.assetList[index] = updatedRow;
            
             this.finalListToReturn = [
                ...this.assetList
            ];
        } else if (sectionName === 'Children') {
            this.childrenList[index][fieldName] = value;
            this.childrenList[index].isRowAdded = true;
             this.finalListToReturn = [
                ...this.childrenList
            ];
        }*/
        console.log('tradeRefDetails in table>',JSON.stringify(this.tradeReferenceList));
        console.log('assetList>',JSON.stringify(this.assetList));
        console.log('childrenList>',JSON.stringify(this.childrenList));
        // Final clean list for Apex
       /* this.finalListToReturn = [
        ...(this.tradeReferenceList[0]?.isRowAdded ? this.tradeReferenceList : []),
        ...(this.assetList[0]?.isRowAdded ? this.assetList : []),
        ...(this.childrenList[0]?.isRowAdded ? this.childrenList : [])
        ];*/
       /* this.finalListToReturn = [
            ...this.tradeReferenceList,
            ...this.assetList,
            ...this.childrenList
        ];
        console.log('finalListToReturn =>', JSON.stringify(this.finalListToReturn));*/


       // this.finalListToReturn = [...this.tradeReferenceList,...this.assetList,...this.childrenList];
        console.log('finalListToReturn>',JSON.stringify(this.finalListToReturn));
        console.log('finalListToReturn>',this.finalListToReturn);
        console.log('tradeRefDetails in table>',JSON.stringify(this.tradeReferenceList));
        
       /* this.dispatchEvent(
            new CustomEvent('changeinput', {
                detail: {
                    pdChildDetailsList: this.finalListToReturn
                }
            }))*/
    }
    catch(error) {
        console.error('Error in handleChange:', error);
    }
}
    @api
    pdChildDetailsList() {
        return this.finalListToReturn;
    }
    async handleDeleteRow(event) {
    const idx  = Number(event.currentTarget.dataset.index);
    const id   = event.currentTarget.dataset.id;    // may be undefined for unsaved rows
    const sect = event.currentTarget.dataset.name;

    // If there’s no server Id yet, just drop it from the UI.
    if (!id) {
      this.removeRowLocally(sect, idx);
      return;
    }

    // Delete on server first, then update UI.
    try {
      this.deleting = true;
      await deleteRefData({ ids: [id] });

      this.removeRowLocally(sect, idx);

      this.dispatchEvent(new ShowToastEvent({
        title: 'Deleted',
        message: 'Row deleted successfully.',
        variant: 'success'
      }));

      // (Optional) If you want the parent to refresh its data:
      this.dispatchEvent(new CustomEvent('rowdeleted', { detail: { section: sect, id } }));
    } catch (e) {
      this.dispatchEvent(new ShowToastEvent({
        title: 'Delete failed',
        message: e?.body?.message || e.message,
        variant: 'error'
      }));
    } finally {
      this.deleting = false;
    }
  }

  removeRowLocally(sect, idx) {
    if (sect === 'Asset') {
      if (this.assetList.length === 1) {
        this.dispatchEvent(new CustomEvent('delete', { detail: { tableName: 'Asset' } }));
        return;
      }
      this.assetList = this.assetList.filter((_, i) => i !== idx);
    } else if (sect === 'Children') {
      if (this.childrenList.length === 1) {
        this.dispatchEvent(new CustomEvent('delete', { detail: { tableName: 'Children' } }));
        return;
      }
      this.childrenList = this.childrenList.filter((_, i) => i !== idx);
    } else if (sect === 'TradeReference') {
      if (this.tradeReferenceList.length === 1) {
        this.dispatchEvent(new CustomEvent('delete', { detail: { tableName: 'TradeReference' } }));
        return;
      }
      this.tradeReferenceList = this.tradeReferenceList.filter((_, i) => i !== idx);
    }

    // keep the combined list in sync if you rely on it elsewhere
    this.finalListToReturn = [
      ...this.tradeReferenceList,
      ...this.assetList,
      ...this.childrenList
    ];
  }




}