import { LightningElement,api } from 'lwc';
export default class Hl_LegalRecordPagecmp extends LightningElement {
@api recordId;

 _processObject;
    @api
    get processObject() {
        return this._processObject;
    }
    set processObject(value) {
        this._processObject = value;
        console.log('line 77 (from setter)-->>', value);

        
        if (value) {
            console.log('line 83-->>');
        }
    }

}