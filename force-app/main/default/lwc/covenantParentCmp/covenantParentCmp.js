import { LightningElement,api,wire } from 'lwc';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

export default class CovenantParentCmp extends LightningElement {
    isHLRelated=false;
    @api recordId;
     
    @wire(CurrentPageReference)
        getStateParameters(currentPageReference) {
        if (currentPageReference) {
                  console.log('Record Id from URL:', currentPageReference);
                this.recordId = currentPageReference?.attributes?.recordId;
              
            }
        }
    
    connectedCallback(){
        this.fetchProducDetails();
    }

    fetchProducDetails(){

         console.log('this recordId----'+this.recordId);
        var inputMapParam = {
            'oppId': this.recordId
        };

        getProductDetails({inputMap : inputMapParam})
        .then(result =>{
            console.log('result product: '+ JSON.stringify(result));
            this.isHLRelated = result.isHLRelated;
        })
        .catch(error=>{
            console.error('error in getting product: '+ JSON.stringify(error))
        })
    }
}