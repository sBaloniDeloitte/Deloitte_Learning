/**
 * @description       : 
 * @author            : Aarya Tiwari
 * @group             : 
 * @last modified on  : 18-05-2026
 * @last modified by  : Aarya Tiwari
**/
export const FIELD_API_NAME = Object.freeze({
    DISABILITY: 'Disability__c',
    DISABILITY_PERCENT: 'Disability_Percent__c',
});

export const SCREEN_FIELD_LABEL = Object.freeze({
    DISABILITY_PERCENT: 'Disability Percent (as per certificate of disability)',
    DISABILITY: 'Disability',
});

export const DISABILITY_TYPE = Object.freeze({
    NOT_APPLICABLE: 'Not Applicable',
    VISUALLY_CHALLENGED: 'Visually Challenged',
    PHYSICALLY_CHALLENGED: 'Physically Challenged',
    OTHER_DISABILITY: 'Other Disability',
});

export const FIELD_STEP = Object.freeze({
    DISABILITY_PERCENT: '0.01'
});

export const CHANNEL_OPTIONS = Object.freeze({
    DSA: { value: 'DSA', label: 'DSA' },
    DIRECT: { value: 'Direct', label: 'Direct' },
    ONLINE: { value: 'Online', label: 'Online' }
});

export const PRODUCT = Object.freeze({
    BUSINESS_LOAN: { value: 'Business Loan', label: 'Business Loan' }
});