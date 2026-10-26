import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class SearchUserPicker extends NavigationMixin(LightningElement) {

    isfocus = false 
    @api isSelected = false;
    isChanged = false;
    @api disabled = false;
    @api value = ''
    @api index;
    @api paramId;
    @api paramName;
    @api selectedVal;
   

    @api options = []
    @track searchOptions = []
    @api selectOption = {
        'label':'',
        'value': ''
    }

    // get updateValue(){
    //     this.isSelected = true;
    //     this.selectOption = this.options[this.options.findIndex(this.value)]
    // }

    renderedCallback(){
        // console.log(`The vlaue is : ${this.value}`)
        // console.log(`The vlaue is : ${this.index}`)
        // if(!this.value){return;}
        // else{this.getSelectedOption(this.value)}
    }

    connectedCallback(){
        console.log('options =:', this.options);
        console.log('selectOption=:'+JSON.stringify(this.selectOption));
        console.log('isSelected=:'+this.selectedVal);
        //this.selectedVal = this.selectOption.label;
    
        for(let i=0; i<this.options.length ; i++){
            if(i>4){break;}
            this.searchOptions.push(this.options[i])
        }
        //this.getSelectedOption(this.value)
    }
    openSelection(){
        this.isSelected = false;
    }
    get inputClassName(){
        return this.isfocus ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    }

    handleFocus(evt){
        this.isfocus = true;
    }

    handleSearch(evt){
        let text = evt.target.value 
        this.isChanged = true;
        this.searchOptions = this.options.filter(option=>{
            return option.label.toLowerCase().includes(text.toLowerCase())
        })
        this.isChanged = false;
    }

    handleFocusOut(){
        if(!this.isfocus){return;}
        setTimeout(() => {
            if(!this.isSelected){this.isfocus = false};
          }, 100);
    }

    handleSelection(evt){
        console.log('isSelected=:'+this.isSelected);
        console.log('ayush');
        this.isSelected = true;
        console.log('evt.currentTarget.dataset.value=:'+evt.currentTarget.dataset.value);
        console.log('evt.currentTarget.dataset.ayush=:'+evt.currentTarget.dataset.label);
        console.log('this.paramId=:'+this.paramId);
        console.log('this.paramName=:'+this.paramName);
        this.selectedVal = evt.currentTarget.dataset.label;
        // this.selectOption.value = evt.currentTarget.dataset.value;
        
        // console.log('this.selectOption.value=:'+this.selectOption.value);
        const valueSelectedEvent = new CustomEvent('select', {detail:{
                                        id: this.paramId,
                                        name: this.paramName,
                                        value : evt.currentTarget.dataset.value
                                    }});
        this.dispatchEvent(valueSelectedEvent);
        var teamArr = {'label' : evt.currentTarget.dataset.label , 'value' :evt.currentTarget.dataset.value};
        // this.selectOption.label = evt.currentTarget.dataset.label;
        this.selectedOption = {...teamArr};
  
        console.log('isSelected=:'+this.isSelected);

    }

    handleRemove(){
        console.log('inside remove');
        this.isSelected = false
        this.isfocus = false
        this.searchOptions = []
        for(let i=0; i<this.options.length ; i++){
            if(i>4){break;}
            this.searchOptions.push(this.options[i])
        }
    }

    getSelectedOption(value){
        console.log('value=:'+value);
        // console.log(`the this.selectOption : ${JSON.stringify(this.selectOption)}`)
        let pickedOption = this.searchOptions.filter(option=>{return option.value === value});
        console.log('pickedOption=:'+pickedOption);
        this.selectOption = pickedOption[0]
        this.isSelected  = true;
    }

    sendEvent(){
        const customEvent = new CustomEvent('select', {
            detail: { 
                id: this.paramId,
                name: this.paramName,
                value : this.selectOption.value
            }
        });
        this.dispatchEvent(customEvent);
    }

    @api 
    updateValue(){
        if(this.disabled){return}
        this.getSelectedOption(this.value)
    }

}