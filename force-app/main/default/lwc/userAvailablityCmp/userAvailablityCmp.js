import { LightningElement, track } from 'lwc';
import getUsers from '@salesforce/apex/UserAvailabilityController.getUsers';
import updateAvailability from '@salesforce/apex/UserAvailabilityController.updateAvailability';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const PAGE_SIZE = 10;

export default class UserAvailablityCmp extends LightningElement {
    
    @track allUsers = [];
    @track filteredUsers = [];
    @track users = [];
    pageNumber = 1;
    searchKey = '';

    connectedCallback() {
        this.loadUsers();
    }

    loadUsers() {
        getUsers()
        .then(result => {
            this.allUsers = result;
            this.filteredUsers = result;
            this.pageNumber = 1;
            this.updatePageData();
        });
    }
    
    updatePageData() {
        const start = (this.pageNumber - 1) * PAGE_SIZE;
        const end = start + PAGE_SIZE;
        this.users = this.filteredUsers.slice(start, end);
    }

    handleSearch(event) {
        const value = event.target.value?.toLowerCase();
        this.searchKey = value;
        this.pageNumber = 1;
        if (!value || value.length < 2) {
            this.filteredUsers = this.allUsers;
        } else {
            this.filteredUsers = this.allUsers.filter(user =>
                (user.Name && user.Name.toLowerCase().includes(value)) ||
                (user.Username && user.Username.toLowerCase().includes(value))
            );
        }
        this.updatePageData();
    }

    
    handleNext() {
        this.pageNumber++;
        this.updatePageData();
    }

    handlePrevious() {
        this.pageNumber--;
        this.updatePageData();
    }

    get totalRecords() {
        return this.filteredUsers.length;
    }

    get totalPages() {
        return Math.ceil(this.totalRecords / PAGE_SIZE);
    }

    get disablePrevious() {
        return this.pageNumber <= 1;
    }

    get disableNext() {
        return this.pageNumber >= this.totalPages;
    }

    handleCheckboxChange(event) {
        const userId = event.target.dataset.id;
        const isAvailable = event.target.checked;
        updateAvailability({ userId, isAvailable })
        .then(() => {
            this.showToast('Success', isAvailable ? 'User marked as available for today.' : 'User marked as not available for today.', isAvailable ? 'success' : 'warning');
        })
        .catch(() => {
            event.target.checked = !isAvailable;
            this.showToast('Error', 'Failed to update availability', 'error');
        });
    }
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

}