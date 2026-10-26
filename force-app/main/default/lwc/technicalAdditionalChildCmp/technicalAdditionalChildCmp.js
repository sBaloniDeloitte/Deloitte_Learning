import { LightningElement, api, track,wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { updateRecord } from 'lightning/uiRecordApi';
import getAllChildRecords from '@salesforce/apex/TechnialAdditionalChildController.getAllChildRecords';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import calculatemMrketValue from '@salesforce/apex/TechnialAdditionalChildController.calculatemMrketValue';


export default class TechnialAdditionalChildCmp extends LightningElement {

    @api recordId;
    @track market = [];
    @track gov = [];
    @track complition = [];
    @track childData = {};
    @track govTotal;
    @track marketTotal;
    @track complitionTotal;
    @track totalValueAsOnDate;
    @track qsvDistress;
    @track qsvDistressPC;  

    channelName = '/event/Refresh_Event__e';
    subscription = {};

    connectedCallback() {
        this.getChileData();
        this.registerErrorListener();
    this.subscribeToPlatformEvent();
    }

    getChileData() {
        getAllChildRecords({ techId: this.recordId }).then(result => {
            this.childData = result;
            this.totalValueAsOnDate = result.totalValueAsOnDate;
            this.qsvDistress = result.qsvDistress;
            this.qsvDistressPC = result.qsvDistressPC;
            this.govTotal = result.gov.total;
            this.marketTotal = result.market.total;
            this.complitionTotal = result.complition.total;

            this.otherGovValue = result.otherGovValue;
            this.otherPresentValue = result.otherPresentValue;
            this.otherPostCompValue = result.otherPostCompValue;
           
            this.market = result.market.records;
            this.gov = result.gov.records;
            this.complition = result.complition.records;
            console.log('gov', JSON.stringify(this.gov));
            console.log('market', JSON.stringify(this.market));
            console.log('complition', JSON.stringify(this.complition));
        }).catch(error => {
            console.log('error', error);
        });
    }

    calculateValue() {
        calculatemMrketValue({ techId: this.recordId }).then(result => {
            this.getChileData();
        }).catch(error => {
            console.log('error', error);
        });
    }

    
handleChange(event) {
    let value = event.target.value;
     console.log('value000>>>',value);
    if (!/^\d*$/.test(value)) {
        console.log('value111>>>',value);
        value = value.replace(/[^\d]/g, '');
        event.target.value = value; // update UI as well
        console.log('event.target.value111>>>',event.target.value);
    }
    if (value === '') {
        console.log('value222>>>',value);
        value=null;
    }
    const fields = {};
        fields['Id'] = event.target.dataset.id;
        console.log('event.target.dataset.field ',event.target.dataset.field);
        console.log('event.target.dataset.id ',event.target.dataset.id);
        console.log('event.target.value ',event.target.value);
        fields[event.target.dataset.field]=event.target.value;
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
        .then(() => {
            this.calculateValue();
          this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Updated!',
                        variant: 'success'
                    })
                );
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });


        }

        subscribeToPlatformEvent() {
    console.log('Platform event received, refreshing...');
    subscribe(this.channelName, -1, (response) => {
        const updatedRecordId = response.data.payload.Technial__c;
        if (updatedRecordId === this.recordId) {
            
           this.getChileData();
        }
    }).then((response) => {
        this.subscription = response;
        console.log('Subscribed to platform event:', response.channel);
    });
}

  registerErrorListener() {
      onError((error) => {
          console.error('EMP API error: ', error);
      });
  }

  disconnectedCallback() {
      unsubscribe(this.subscription, (response) => {
          console.log('Unsubscribed: ', response);
      });
  }
}