import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import studentPhoto from '@salesforce/resourceUrl/studentphoto';

import NAME_FIELD from '@salesforce/schema/Account.Name';
import FIRST_NAME_FIELD from '@salesforce/schema/Account.First_Name__c';
import MIDDLE_NAME_FIELD from '@salesforce/schema/Account.Middle_Name__c';
import LAST_NAME_FIELD from '@salesforce/schema/Account.Last_Name__c';
import DOB_FIELD from '@salesforce/schema/Account.Date_of_Birth__c';
import GENDER_FIELD from '@salesforce/schema/Account.Gender__c';
import MOBILE_FIELD from '@salesforce/schema/Account.Mobile_Number__c';
import PHONE_FIELD from '@salesforce/schema/Account.Phone';
import PAN_FIELD from '@salesforce/schema/Account.PAN_Number__c';
import AADHAAR_FIELD from '@salesforce/schema/Account.Aadhaar_Number__c';
import PASSPORT_FIELD from '@salesforce/schema/Account.Passport_File_Number__c';
import PHOTO_URL_FIELD from '@salesforce/schema/Account.PhotoUrl';
import ADDRESS_LINE_1_FIELD from '@salesforce/schema/Account.Address_Line_1__c';
import ADDRESS_LINE_2_FIELD from '@salesforce/schema/Account.Address_Line_2__c';
import ADDRESS_LINE_3_FIELD from '@salesforce/schema/Account.Address_Line_3__c';
import CITY_FIELD from '@salesforce/schema/Account.City__c';
import STATE_FIELD from '@salesforce/schema/Account.State__c';
import COUNTRY_FIELD from '@salesforce/schema/Account.Country__c';
import BILLING_STREET_FIELD from '@salesforce/schema/Account.BillingStreet';
import BILLING_CITY_FIELD from '@salesforce/schema/Account.BillingCity';
import BILLING_STATE_FIELD from '@salesforce/schema/Account.BillingState';
import BILLING_POSTAL_CODE_FIELD from '@salesforce/schema/Account.BillingPostalCode';
import BILLING_COUNTRY_FIELD from '@salesforce/schema/Account.BillingCountry';
import SHIPPING_STREET_FIELD from '@salesforce/schema/Account.ShippingStreet';
import SHIPPING_CITY_FIELD from '@salesforce/schema/Account.ShippingCity';
import SHIPPING_STATE_FIELD from '@salesforce/schema/Account.ShippingState';
import SHIPPING_POSTAL_CODE_FIELD from '@salesforce/schema/Account.ShippingPostalCode';
import SHIPPING_COUNTRY_FIELD from '@salesforce/schema/Account.ShippingCountry';

const NOT_AVAILABLE = 'Not available';

const FIELDS = [
    NAME_FIELD,
    FIRST_NAME_FIELD,
    MIDDLE_NAME_FIELD,
    LAST_NAME_FIELD,
    DOB_FIELD,
    GENDER_FIELD,
    MOBILE_FIELD,
    PHONE_FIELD,
    PAN_FIELD,
    AADHAAR_FIELD,
    PASSPORT_FIELD,
    PHOTO_URL_FIELD,
    ADDRESS_LINE_1_FIELD,
    ADDRESS_LINE_2_FIELD,
    ADDRESS_LINE_3_FIELD,
    CITY_FIELD,
    STATE_FIELD,
    COUNTRY_FIELD,
    BILLING_STREET_FIELD,
    BILLING_CITY_FIELD,
    BILLING_STATE_FIELD,
    BILLING_POSTAL_CODE_FIELD,
    BILLING_COUNTRY_FIELD,
    SHIPPING_STREET_FIELD,
    SHIPPING_CITY_FIELD,
    SHIPPING_STATE_FIELD,
    SHIPPING_POSTAL_CODE_FIELD,
    SHIPPING_COUNTRY_FIELD
];

function joinParts(parts) {
    const clean = parts.filter(part => !!part);
    return clean.length ? clean.join(', ') : NOT_AVAILABLE;
}

function maskValue(value) {
    if (!value) {
        return NOT_AVAILABLE;
    }
    if (value.length <= 4) {
        return value;
    }
    const visibleStart = value.slice(0, 2);
    const visibleEnd = value.slice(-2);
    return `${visibleStart}${'•'.repeat(value.length - 4)}${visibleEnd}`;
}

function formatDateOfBirth(dobString) {
    if (!dobString) {
        return NOT_AVAILABLE;
    }

    const dob = new Date(dobString);
    if (Number.isNaN(dob.getTime())) {
        return dobString;
    }

    const today = new Date();
    let age = today.getFullYear() - dob.getFullYear();
    const monthDiff = today.getMonth() - dob.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
        age--;
    }

    const formatted = dob.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
    return `${formatted} (${age} yrs)`;
}

export default class Customer360DemographicCmp extends LightningElement {

    @api recordId;

    isUnmasked = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    account;

    get profilePhoto() {
        return getFieldValue(this.account.data, PHOTO_URL_FIELD) || studentPhoto;
    }

    get fullName() {
        const composed = [
            getFieldValue(this.account.data, FIRST_NAME_FIELD),
            getFieldValue(this.account.data, MIDDLE_NAME_FIELD),
            getFieldValue(this.account.data, LAST_NAME_FIELD)
        ]
            .filter(part => !!part)
            .join(' ');

        return composed || getFieldValue(this.account.data, NAME_FIELD) || NOT_AVAILABLE;
    }

    get dateOfBirth() {
        return formatDateOfBirth(getFieldValue(this.account.data, DOB_FIELD));
    }

    get sex() {
        return getFieldValue(this.account.data, GENDER_FIELD) || NOT_AVAILABLE;
    }

    get primaryMobile() {
        return getFieldValue(this.account.data, MOBILE_FIELD) || NOT_AVAILABLE;
    }

    get alternateMobile() {
        return getFieldValue(this.account.data, PHONE_FIELD) || NOT_AVAILABLE;
    }

    get currentAddress() {
        return joinParts([
            getFieldValue(this.account.data, ADDRESS_LINE_1_FIELD),
            getFieldValue(this.account.data, ADDRESS_LINE_2_FIELD),
            getFieldValue(this.account.data, ADDRESS_LINE_3_FIELD),
            getFieldValue(this.account.data, CITY_FIELD),
            getFieldValue(this.account.data, STATE_FIELD),
            getFieldValue(this.account.data, COUNTRY_FIELD)
        ]);
    }

    get permanentAddress() {
        return joinParts([
            getFieldValue(this.account.data, BILLING_STREET_FIELD),
            getFieldValue(this.account.data, BILLING_CITY_FIELD),
            getFieldValue(this.account.data, BILLING_STATE_FIELD),
            getFieldValue(this.account.data, BILLING_POSTAL_CODE_FIELD),
            getFieldValue(this.account.data, BILLING_COUNTRY_FIELD)
        ]);
    }

    get communicationAddress() {
        return joinParts([
            getFieldValue(this.account.data, SHIPPING_STREET_FIELD),
            getFieldValue(this.account.data, SHIPPING_CITY_FIELD),
            getFieldValue(this.account.data, SHIPPING_STATE_FIELD),
            getFieldValue(this.account.data, SHIPPING_POSTAL_CODE_FIELD),
            getFieldValue(this.account.data, SHIPPING_COUNTRY_FIELD)
        ]);
    }

    get displayPan() {
        const pan = getFieldValue(this.account.data, PAN_FIELD);
        return this.isUnmasked ? (pan || NOT_AVAILABLE) : maskValue(pan);
    }

    get displayAadhaar() {
        const aadhaar = getFieldValue(this.account.data, AADHAAR_FIELD);
        return this.isUnmasked ? (aadhaar || NOT_AVAILABLE) : maskValue(aadhaar);
    }

    get displayPassport() {
        const passport = getFieldValue(this.account.data, PASSPORT_FIELD);
        return this.isUnmasked ? (passport || NOT_AVAILABLE) : maskValue(passport);
    }

    get unmaskLabel() {
        return this.isUnmasked ? 'Mask IDs' : 'Unmask IDs';
    }

    handleUnmask() {
        this.isUnmasked = !this.isUnmasked;
    }
}