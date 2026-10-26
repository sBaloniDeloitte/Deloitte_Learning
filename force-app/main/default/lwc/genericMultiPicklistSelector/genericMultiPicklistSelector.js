import { LightningElement,api,wire } from 'lwc';

export default class GenericMultiPicklistSelector extends LightningElement {
    placeholder = '';
    showDD=false;
    init = false;
    isExpanded = false;
    isSelectAll = false;

    branchId = '';

    _options;
    filteredOptions;

    @api
    get options(){
        return this._options;
    }

    set options(values){
        this._options = JSON.parse(JSON.stringify(values));
    }



    //@api options=[];    
    @api label;
    @api required;
    @api showpills;
    @api ifedit = false;

    connectedCallback(){

        console.log('inside connectedCallback')
        // console.log('options on connCalllback---', this.options);
        console.log('options on connCalllbackk---', this.options);
        this.filteredOptions = this.options;
        //const selectedList = this.options.filter((element) => element.checked).map((element) => element.value);
        // this.dispatchEvent(new CustomEvent('branchid', {
        //     detail: { branchId }
        // }));
    }

    renderedCallback() {
        console.log('ifedit '+ this.ifedit)
        if(!this.init) {
            this.template.querySelector('.cmpl-input').addEventListener('click', (event) => {
                if(this.showDD) {
                    // this.showDD = !this.showDD;
                } else {
                    let opts = this.options ? this.options.filter((element) => element.show).length : 0;
                    // this.showDD =  this.options ? this.options.filter((element) => element.show).length : 0;
                    this.showDD = opts > 0;

                }
                event.stopPropagation();
            });
            this.template.addEventListener('click', (event) => {
                event.stopPropagation();
            });
            document.addEventListener('click', () => {
                // this.showDD = false;
            });
            this.init=true;
        }
        if (this.options && this.options.some((option) => option.checked)) {
            // const checkedOptionsCount = this.options.filter(option => option.checked).length;


            this.postSelect();
            setTimeout(() => {
                const checkedOptionsCount = this.options.filter((option) => option.checked).length;

                if (checkedOptionsCount > 1 && !(this.ifedit)) {
                    console.log('inside if')
                    // If more than one option is checked, call showMore directly
                    this.showLess();
                    this.showMore();

                    // Optionally hide the "more" button (uncomment if needed)
                    // const moreButton = this.template.querySelector('[role="more"]');
                    // if (moreButton) {
                    //     moreButton.classList.add('slds-hide');
                    // }
                }
            }, 300);

        }
    }

    onSearch(event) {
        if(event.detail.value == undefined || event.detail.value == null || event.detail.value.length == 0 || event.detail.value == ''){
            this.filteredOptions = this.options;
        }
        else{
            this.options.forEach(option => {
                option.show = option.label.toLowerCase().startsWith(event.detail.value.toLowerCase());
            });
            let filteredopts = this.options.filter((element) => element.show);
            this.showDD = false;
            if(filteredopts.length > 0) {
                this.showDD = true;
                this.filteredOptions = filteredopts;
            }
        }
    }
    currentSelectedValue;
    onSelect(event) {
        console.log('event.target.value=:'+event.target.value);
        this.currentSelectedValue = event.target.value;
        if(event.target.value == 'SelectAll') {
            this.options.forEach(option => {
                option.checked = event.target.checked;
            });
        } else {
            this.options.find(option => option.label === event.target.value).checked = event.target.checked;
        }
        this.postSelect();
        console.log('inside select');
        this.getSelectedList();
        // setTimeout(()=>{
        //     if(event.target.value != 'SelectAll') {
        //         this.showDD = true;
        //     }
        // },400)
    }

    onRemove(event) {
        this.options.find(option => option.label === event.detail.name).checked = false;
        this.postSelect();
        this.getSelectedList();
    }

    postSelect() {
        let count = this.options.filter((element) => element.checked).length;
        this.placeholder = count > 0 ? count+ ' Item(s) Selected' : '';
        this.isSelectAll = (count == this.options.length);
        if(this.showpills) {
            let evnt = setInterval(() => {
                if(count > 1){
                    if (this.template.querySelector('[role="listbox"]') && (this.template.querySelector('[role="listbox"]').getBoundingClientRect().height >
                        (this.template.querySelectorAll('[role="pill"]')[0].getBoundingClientRect().height+10))) {
                        if( this.template.querySelector('[role="more"]')) this.template.querySelector('[role="more"]')?.classList.remove('slds-hide');
                        console.log('inside post')
                    } else {
                       if( this.template.querySelector('[role="more"]')) this.template.querySelector('[role="more"]')?.classList.add('slds-hide');
                    }
                }
                clearInterval(evnt);
            }, 200);
        }
        if(this.required) {
            if(count == 0) {
                this.template.querySelector('.cmpl-input').setCustomValidity('Please select item(s)');
            } else {
                this.template.querySelector('.cmpl-input').setCustomValidity('');
            }
            this.template.querySelector('.cmpl-input').reportValidity();
        }

    }

    get showPillView() {
        if(this.showpills) {
            let count = this.options ? this.options.filter((element) => element.checked).length : 0;
            return this.showpills && count > 0;
        }
        return false;
    }

    showMore() {
        console.log('inside more')
        this.template.querySelector('.slds-listbox_selection-group').classList.add('slds-listbox_expanded');
       if( this.template.querySelector('[role="more"]')) this.template.querySelector('[role="more"]').classList.add('slds-hide');
       if( this.template.querySelector('[role="less"]')) this.template.querySelector('[role="less"]').classList.remove('slds-hide');
    }

    showLess() {
        console.log('inside less')
        this.template.querySelector('.slds-listbox_selection-group').classList.remove('slds-listbox_expanded');
       if( this.template.querySelector('[role="less"]')) this.template.querySelector('[role="less"]').classList.add('slds-hide');
       if( this.template.querySelector('[role="more"]')) this.template.querySelector('[role="more"]').classList.remove('slds-hide');
    }
    
    @api
    getSelectedList() {
        const currVal = this.currentSelectedValue;
        const selectedList = this.options.filter((element) => element.checked).map((element) => element.value);
        this.dispatchEvent(new CustomEvent('selectedvalueschange', {
            detail: { selectedList, currVal }
        }));
        return selectedList.join(';');
        return this.options.filter((element) => element.checked).map((element) => element.label).join(';');
    }

    @api
    setSelectedList(selected) {
        selected?.split(';').forEach(name => {
            this.options.find(option => option.label === name).checked = true;
        });
        this.postSelect();
    }

    @api
    setOptions(opts) {
        this.options = opts.map(opt => {return {"label": opt.label, "value": opt.value, "show": true, "checked":false}});
    }

    @api
    isValid() {
        if(this.required) {
            let count = this.options ? this.options.filter((element) => element.checked).length : 0;
            if(count == 0) {
                this.template.querySelector('.cmpl-input').setCustomValidity('Please select item(s)');
                this.template.querySelector('.cmpl-input').reportValidity();
                return false;
            }
        }
        return true;
    }

    handleFocus(){
        this.dispatchEvent(new CustomEvent('adjustheight', {
            detail: {  }
        }));
        this.filteredOptions = this.options;
        // if(this.showDD == true){
        //     this.showDD = false
        // }
        // else{
        this.showDD = true;
        // }

    }
    handleBlur(){
        console.log('Inside blur');
        this.dispatchEvent(new CustomEvent('reduceheight', {
            detail: {  }
        }));
        // setTimeout(() => {
        //     this.showDD = false;
        // }, 200);
        // console.log('Inside blur',this.showDD);
        // this.showDD = false;
    }
    handleCloseList(){
        setTimeout(()=>{
            this.showDD = false;
        },300)
    }
}