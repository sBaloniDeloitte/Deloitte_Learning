import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from "@salesforce/user/Id";
import getAccountsForUser from '@salesforce/apex/Comm_LeadManagementController.getAccountsForUser';
//import stack from '@salesforce/resourceUrl/stack';

export default class WelcomeScreen extends LightningElement {
    name;
    userPhotoUrl;
    loginDate;
    profile;
    @api showGreeting;
    formattedNames = '';
    // Set background image
    renderedCallback() {
        try {
            //this.template.querySelector('.stack-bg').style.backgroundImage = `url(${stack})`;
        }
        catch (error) {
            console.error(error);
        }
    }

    // Get user data
    @wire(getRecord, { recordId: USER_ID, fields: ['User.Name', 'User.LastLoginDate', 'User.MediumPhotoUrl','User.Profile.Name'] })
    userData({ error, data }) {
        if (error) this.error = error;
        else if (data) {
            console.log('User data:', data);
            this.name = data.fields.Name.value;
            this.loginDate = data.fields.LastLoginDate.value;
            this.userPhotoUrl = data.fields.MediumPhotoUrl.value;
            this.profile = data.fields.Profile.value.fields.Name.value;
        }else if (error) {
            console.error('Error fetching User:', error);
        }
    }
   
    @wire(getAccountsForUser, { userId: USER_ID })
    wiredAccounts({ data, error }) {
        if (data) {
            console.log('USER_ID:', USER_ID);
            console.log('profile:', this.profile);
            console.log('data fetching accounts:', data);
            if(this.profile.includes('Partner Community')){
            this.formattedNames = ', '+ data;
            console.log('formattedNames', this.formattedNames);
            }
        } else if (error) {
            console.error('Error fetching accounts:', error);
        }
    }

    get dayTimeMessage() {
        const today = new Date()
        const curHr = today.getHours()
        var dayTimeString ='';

        if(curHr < 12) {
            dayTimeString = 'Good Morning. ';
        }
        else if (curHr < 18) {
            dayTimeString = 'Good Afternoon. ';
        }
        else {
            dayTimeString = 'Good Evening. ';
        }

        return {dayTimeMsg: dayTimeString};
    }

    // Get formatted last login & current date
    get formattedDates() {
        const logDate = this.loginDate ? new Date(this.loginDate) : null;
        const currDate = new Date();
    
        const crOptions = {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        };
    
        // const lastOptions = {
        //     year: "numeric",
        //     month: "2-digit",
        //     day: "numeric",
        //     hour: 'numeric',
        //     minute: 'numeric',
        //     hourCycle: 'h12'
        // };
    
        return {
            
            date: currDate.toLocaleDateString('en-IN', crOptions)
        };
    }
    
}