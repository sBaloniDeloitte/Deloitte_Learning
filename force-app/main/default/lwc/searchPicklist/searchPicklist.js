import { LightningElement, api, track } from 'lwc';

export default class SearchPicklist extends LightningElement {

    @track searchTerm = ''; // User input in the search field
    @track filteredOptions = []; // Filtered options based on the search term
    @track isDropdownOpen = false; // Controls the visibility of the dropdown
    @track isLoading = false; // Whether data is being loaded
    @track selectedOption = null; // Store the selected option { label, value }
    
    @api options = []; // The parent component will pass the options
    @api disabled = false; // To disable the combobox if necessary

    // Getter for input value (either selected option or search term)
    get inputLabel() {
        return this.selectedOption ? this.selectedOption.label : this.searchTerm;
    }

    // Load options when the input field is clicked
    handleFocus() {
        this.isDropdownOpen = true;
        this.filteredOptions = [...this.options]; // Load all options on focus
    }

    // Handle input change (search term)
    handleSearch(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.filterOptions();
    }

    // Filter the options based on search term
    filterOptions() {
        if(this.searchTerm === '') {
            this.filteredOptions = [...this.options]; // If search is empty, show all options
        }
        else {
            this.filteredOptions = this.options.filter(option => 
                option.label.toLowerCase().includes(this.searchTerm) || 
                option.value.toLowerCase().includes(this.searchTerm) // Include both Name and Employee ID
            );
        }

        this.isDropdownOpen = this.filteredOptions.length > 0; // Show dropdown if there are options
    }

    // Handle selection of an option from the dropdown
    handleSelection(event) {
        const selectedValue = event.currentTarget.dataset.value;
        const selectedLabel = event.currentTarget.dataset.label;

        this.selectedOption = { value: selectedValue, label: selectedLabel };
        this.searchTerm = selectedLabel; // Set search term to selected label
        this.isDropdownOpen = false; // Close dropdown after selection

        // Dispatch event to parent component
        this.dispatchEvent(new CustomEvent('selected', {
            detail: { value: selectedValue, label: selectedLabel },
            bubbles: true, // Allows the event to bubble up
            composed: true // Allows the event to cross the shadow DOM boundary
        }));
    }

    // Remove selected value (clear selection)
    handleRemove() {
        this.selectedOption = null; // Clear selected option
        this.searchTerm = ''; // Clear search term
        this.isDropdownOpen = false; // Close the dropdown
    }

    // Close the dropdown when input field loses focus
    handleBlur() {
        setTimeout(() => {
            if (!this.shadowRoot.activeElement || !this.shadowRoot.activeElement.closest('.slds-combobox__container')) {
                this.isDropdownOpen = false;
            }
        }, 200); // Delay to account for click on list items
    }

    // Get styles for the dropdown to make it visible when there are filtered options
    get dropdownStyle() {
        return this.isDropdownOpen ? 'display:block; max-height: 200px; overflow-y: auto;' : 'display:none;';
    }

    /*get isDropdownOpen(){
        return this.isDropdownOpen === true; 
    }*/
}