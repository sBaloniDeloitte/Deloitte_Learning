//_______________This Code was generated using GenAI tool: Codify, Please check for accuracy_______________//

import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { getPicklistValues, getObjectInfo }     from 'lightning/uiObjectInfoApi';
import LEAD_OBJECT               from '@salesforce/schema/Lead';
import LEAD_SOURCE_FIELD         from '@salesforce/schema/Lead.LeadSource';
// import getLeadData              from '@salesforce/apex/LeadCreationController.getLeadData';
// import updateLeadBasic          from '@salesforce/apex/LeadCreationController.updateLeadBasic';
// import updateEducationInfo      from '@salesforce/apex/LeadCreationController.updateEducationInfo';
// import updateFundingInfo        from '@salesforce/apex/LeadCreationController.updateFundingInfo';
// import updateCoApplicantInfo    from '@salesforce/apex/LeadCreationController.updateCoApplicantInfo';
// import updateCollateralInfo     from '@salesforce/apex/LeadCreationController.updateCollateralInfo';
// import updateSourcingInfo       from '@salesforce/apex/LeadCreationController.updateSourcingInfo';
// import convertLeadToOpportunity from '@salesforce/apex/LeadCreationController.convertLeadToOpportunity';

const NAV_SECTIONS = [
    { id: 'basic',       icon: '👤', label: 'Basic Information',        step: 1 },
    { id: 'education',   icon: '📚', label: 'Education Information',    step: 2 },
    { id: 'funding',     icon: '💰', label: 'Funding Requirement',      step: 3 },
    { id: 'coapplicant', icon: '👥', label: 'Co-Applicant Information', step: 4 },
    { id: 'collateral',  icon: '🏠', label: 'Property Collateral',      step: 5 },
    { id: 'sourcing',    icon: '📡', label: 'Sourcing Details',         step: 6 },
    { id: 'owner',       icon: '🧑', label: 'Lead Owner',               step: 7 }
];

export default class LeadApplicationShell extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef) {
            console.log('PAGE REFERENCE:', JSON.stringify(pageRef));
            console.log('ATTRIBUTES:', JSON.stringify(pageRef.attributes));
            console.log('STATE:', JSON.stringify(pageRef.state));

            const pageRecordId = pageRef.attributes?.recordId;

            console.log('RECORD ID FROM PAGE REFERENCE:', pageRecordId);

            if (pageRecordId && pageRecordId !== this._recordId) {
                this._recordId = pageRecordId;

                console.log('Loading Lead:', this._recordId);

                this.loadLeadData();
            }
        }
    }
    // ── Public ─────────────────────────────────────────────────────────────────
    //@api recordId; Keshava code start
    _recordId;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;

        if (value) {
            this.loadLeadData();
        }
    }

    //Keshava code ends

    
    showActivityTimeline = false;
    handleActivityTimeline() {
        this.showActivityTimeline = true;
    }
    closeActivityTimeline() {
        this.showActivityTimeline = false;
    }

    showCustomNotes = false;
    handleCustomNotes() {
        this.showCustomNotes = true;
    }
    closeCustomNotes(){
        this.showCustomNotes = false;
    }




    // ── Lead Source picklist from Salesforce schema ───────────────────────────
    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    leadObjectInfo;

    // Derive the default Record Type Id dynamically instead of hardcoding it.
    // A hardcoded/malformed Id (e.g. wrong length) causes getPicklistValues to
    // silently fail, which results in an empty leadSourceOptions list and the
    // <select> never being able to display the currently saved LeadSource value.
    get recordTypeIdForPicklist() {
        return this.leadObjectInfo?.data?.defaultRecordTypeId;
    }

    @wire(getPicklistValues, {
        recordTypeId: '012KY000001E364YAC',
        fieldApiName: LEAD_SOURCE_FIELD
    })
    leadSourcePicklist;

    get leadSourceOptions() {
        const values = this.leadSourcePicklist?.data?.values;
        if (!values) return [];
        return values.map(v => ({ label: v.label, value: v.value }));
    }

    // ── Reactive State ─────────────────────────────────────────────────────────
    @track activeSection = null;     // null → welcome landing shown
    @track isLoading = false;
    @track isSaving  = false;
    @track globalError = '';
    @track saveSuccess = '';
    @track errors = {};

    @track leadScore = 0;
    @track ageEligible = false;
    @track mobileVerified = false;
    @track locationNotCovered = false;
    @track selectedBranchId = '';
    @track selectedBranchName = '';

    // -- Convert to Opportunity State -------------------------------------------
    @track showConvertModal   = false;
    @track isConverting       = false;
    @track convertSuccess     = false;
    @track convertedOppId     = '';
    @track convertedOppName   = '';
    @track convertError       = '';

    @track formData = {
        firstName: '', lastName: '', mobileNumber: '', pincode: '', age: '', email: '',
        currentEducationLevel: '', plannedCountryForStudy: '', plannedCourseForStudy: '',
        courseStartDate: '', admissionStatus: '',
        product: '',
        totalCourseFee: '', tuitionFee: '', hostelCost: '', livingExpenses: '', ownContribution: '',
        requiredLoanAmount: '',
        isCoapplicantAvailable: 'No',
        coapplicantName: '', relationshipWithStudent: '', coapplicantAge: '',
        coapplicantMobile: '', coapplicantOccupation: '', employmentType: '',
        //incomeType: 'Monthly', monthlyAnnualIncome: '',
        incomeRange: '',
        // Collateral
        isCollateralAvailable: 'No',
        propertyType: '',
        collateralUnit: '', collateralCity: '', collateralState: '',
        collateralPincode: '', collateralAddress: '',
        // Sourcing Details
        leadSource: '', subChannel: '', referralName: '',
        // Lead Owner (read-only)
        ownerName: '', ownerId: ''
        
    };

    // ── Lifecycle ──────────────────────────────────────────────────────────────
    connectedCallback() {
        if (this.recordId) {
            this.loadLeadData();
        }
    }

    renderedCallback() {
        // LWC does not reactively apply `value` to native <select> elements after
        // re-renders triggered by object spread. Imperatively sync all selects from formData.
        this._syncSelectValues();
    }

    _syncSelectValues() {
        const selects = this.template.querySelectorAll('select[data-field]');
        selects.forEach(sel => {
            const field = sel.dataset.field;
            const desired = this.formData[field];
            if (desired !== undefined && sel.value !== desired) {
                sel.value = desired;
            }
        });
    }
    
    // async loadLeadData() {
    //     // if (!this._recordId) {
    //     //     console.warn('No Lead Record ID available.');
    //     //     return;
    //     // }

    //     console.log('Calling getLeadData for:', this._recordId);
    //     this.isLoading = true;
    //     this.globalError = '';
    //     // try {
    //     //     //const data = await getLeadData({ leadId: this.recordId });
    //     //     const data = await getLeadData({ leadId: this._recordId });
    //     //     this.formData = {
    //     //         firstName:                data.firstName              || '',
    //     //         lastName:                 data.lastName               || '',
    //     //         mobileNumber:             data.mobileNumber           || '',
    //     //         pincode:                  data.pincode                || '',
    //     //         age:                      data.age                    || '',
    //     //         email:                    data.email                  || '',
    //     //         currentEducationLevel:    data.currentEducationLevel  || '',
    //     //         //plannedCountryForStudy:   data.plannedCountryForStudy || '',
    //     //         plannedCountryForStudy: data.country || data.plannedCountryForStudy || '',
    //     //         plannedCourseForStudy:    data.plannedCourseForStudy  || '',
    //     //         courseStartDate:          data.courseStartDate        || '',
    //     //         admissionStatus:          data.admissionStatus        || '',
    //     //         product:                  data.product                || '',
    //     //         totalCourseFee:           data.totalCourseFee         || '',
    //     //         tuitionFee:               data.tuitionFee             || '',
    //     //         hostelCost:               data.hostelCost             || '',
    //     //         livingExpenses:           data.livingExpenses         || '',
    //     //         ownContribution:          data.ownContribution        || '',
    //     //         requiredLoanAmount: data.requiredLoanAmount || '',
    //     //         isCoapplicantAvailable:   data.isCoapplicantAvailable || 'No',
    //     //         coapplicantName:          data.coapplicantName        || '',
    //     //         relationshipWithStudent:  data.relationshipWithStudent|| '',
    //     //         coapplicantAge:           data.coapplicantAge         || '',
    //     //         coapplicantMobile:        data.coapplicantMobile      || '',
    //     //         coapplicantOccupation:    data.coapplicantOccupation  || '',
    //     //         employmentType:           data.employmentType         || '',
    //     //         // incomeType:               data.incomeType             || 'Monthly',
    //     //         // monthlyAnnualIncome:      data.monthlyAnnualIncome    || '',
    //     //         incomeRange:              data.incomeRange             || '',

    //     //         isCollateralAvailable:    data.isCollateralAvailable  || 'No',
    //     //         propertyType:             data.propertyType             || '',
    //     //         collateralUnit:           data.collateralUnit         || '',
    //     //         collateralCity:           data.collateralCity         || '',
    //     //         collateralState:          data.collateralState        || '',
    //     //         collateralPincode:        data.collateralPincode      || '',
    //     //         collateralAddress:        data.collateralAddress      || '',
    //     //         leadSource:               data.leadSource             || '',
    //     //         subChannel:               data.subChannel             || '',
    //     //         referralName:             data.referralName           || '',
    //     //         ownerName:                data.ownerName              || '',
    //     //         ownerId:                  data.ownerId                || ''
    //     //     };
    //     //     // Compute score from loaded data
    //     //     this._computeScore();
    //     // } catch (err) {
    //     //     this.globalError = this.extractError(err);
    //     // } finally {
    //     //     this.isLoading = false;
    //     // }
    // }
    loadLeadData() {
    console.log('Temporary loadLeadData:', this._recordId);

    this.isLoading = false;
    this.globalError = '';

    // Temporary default values
    this.formData = {
        ...this.formData,

        firstName: '',
        lastName: '',
        mobileNumber: '',
        pincode: '',
        age: '',
        email: '',

        currentEducationLevel: '',
        plannedCountryForStudy: '',
        plannedCourseForStudy: '',
        courseStartDate: '',
        admissionStatus: '',

        product: '',
        totalCourseFee: '',
        tuitionFee: '',
        hostelCost: '',
        livingExpenses: '',
        ownContribution: '',
        requiredLoanAmount: '',

        isCoapplicantAvailable: 'No',
        coapplicantName: '',
        relationshipWithStudent: '',
        coapplicantAge: '',
        coapplicantMobile: '',
        coapplicantOccupation: '',
        employmentType: '',
        incomeRange: '',

        isCollateralAvailable: 'No',
        propertyType: '',
        collateralUnit: '',
        collateralCity: '',
        collateralState: '',
        collateralPincode: '',
        collateralAddress: '',

        leadSource: '',
        subChannel: '',
        referralName: '',

        ownerName: '',
        ownerId: ''
    };

    this._computeScore();
}

    _computeScore() {
        const a = parseInt(this.formData.age, 10);
        const ageOk = !isNaN(a) && a >= 18 && a <= 60;
        const pinOk  = this.formData.pincode && this.formData.pincode.length === 6;
        let score = 40;
        if (ageOk)  score += 20;
        if (pinOk)  score += 20;
        if (this.formData.mobileNumber && this.formData.mobileNumber.length === 10) score += 20;
        this.leadScore        = score;
        this.ageEligible      = ageOk;
        this.mobileVerified   = this.formData.mobileNumber.length === 10;
    }

    // ── Nav ────────────────────────────────────────────────────────────────────
    get navSections() {
        return NAV_SECTIONS.map(s => {
            const isActive = s.id === this.activeSection;
            return {
                ...s,
                itemClass:   isActive ? 'nav-item nav-item-active' : 'nav-item',
                statusClass: isActive ? 'nav-status nav-status-active' : 'nav-status',
                statusText:  isActive ? 'Active' : ''
            };
        });
    }

    handleNavClick(event) {
        const section = event.currentTarget.dataset.section;
        if (!section) return;
        this.activeSection = section;
        this.globalError   = '';
        this.saveSuccess   = '';
        this.errors        = {};
    }

    // ── Section Visibility ─────────────────────────────────────────────────────
    get showBasic()        { return this.activeSection === 'basic'; }
    get showEducation()    { return this.activeSection === 'education'; }
    get showFunding()      { return this.activeSection === 'funding'; }
    get showCoapplicant()  { return this.activeSection === 'coapplicant'; }
    get showCollateral()   { return this.activeSection === 'collateral'; }
    get showSourcing()     { return this.activeSection === 'sourcing'; }
    get showOwner()        { return this.activeSection === 'owner'; }

    // ── Progress ───────────────────────────────────────────────────────────────
    get progressStyle() {
        const stepMap = { basic: 1, education: 2, funding: 3, coapplicant: 4, collateral: 5, sourcing: 6, owner: 7 };
        const step = stepMap[this.activeSection] || 1;
        return `width: ${((step - 1) / 6) * 100}%`;
    }

    _sectionClass(id) {
        const order     = ['basic', 'education', 'funding', 'coapplicant', 'collateral', 'sourcing', 'owner'];
        const activeIdx = order.indexOf(this.activeSection);
        const thisIdx   = order.indexOf(id);
        if (this.activeSection === id) return 'step-item step-active';
        if (activeIdx > thisIdx)       return 'step-item step-done';
        return 'step-item';
    }

    get step1Class() { return this._sectionClass('basic'); }
    get step2Class() { return this._sectionClass('education'); }
    get step3Class() { return this._sectionClass('funding'); }
    get step4Class() { return this._sectionClass('coapplicant'); }
    get step5Class() { return this._sectionClass('collateral'); }
    get step6Class() { return this._sectionClass('sourcing'); }
    get step7Class() { return this._sectionClass('owner'); }

    // ── Computed ───────────────────────────────────────────────────────────────
    get fullName()             { return `${this.formData.firstName} ${this.formData.lastName}`.trim(); }
    get isCoapplicantVisible() { return this.formData.isCoapplicantAvailable === 'Yes'; }
    get isCollateralVisible()  { return this.formData.isCollateralAvailable === 'Yes'; }
    get isReferralVisible()    {
        return this.formData.leadSource === 'Word of mouth'
            || this.formData.leadSource === 'Partner';
    }

    // Lead Owner card helpers
    get ownerDisplayName() { 
        const isCommunity = window.location.hostname.includes('.my.site.com');
                console.log('Current URL:', window.location.href);
                console.log('Hostname:', window.location.hostname);
                console.log('Is Community:', isCommunity);
        if(isCommunity){
            this.formData.ownerName = 'Sid karulkar';
            return  this.formData.ownerName;
        }
        else{
            return this.formData.ownerName || 'Not Assigned'; 
        }
    }
    // get ownerIdDisplay()   { return this.formData.ownerId   || '—'; }
    get ownerInitials() {
        const name = this.formData.ownerName;
        if (!name) return '?';
        const parts = name.trim().split(' ');
        return parts.length >= 2
            ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
            : name[0].toUpperCase();
    }

    get totalEducationCost() {
        const t = parseFloat(this.formData.totalCourseFee)  || 0;
        const h = parseFloat(this.formData.hostelCost)       || 0;
        const l = parseFloat(this.formData.livingExpenses)   || 0;
        return (t + h + l).toFixed(2);
    }
    get requiredLoanAmount() {
        const total = parseFloat(this.totalEducationCost) || 0;
        const own   = parseFloat(this.formData.ownContribution) || 0;
        const r = total - own;
        return r >= 0 ? r.toFixed(2) : '0.00';
    }
    

    // ── Input Handlers ─────────────────────────────────────────────────────────
    handleInput(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.formData = { ...this.formData, [field]: value };
        if (this.errors[field]) {
            const e = { ...this.errors };
            delete e[field];
            this.errors = e;
        }
        this.globalError = '';
        this.saveSuccess = '';
    }

    handleSelectChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.formData = { ...this.formData, [field]: value };
        if (this.errors[field]) {
            const e = { ...this.errors };
            delete e[field];
            this.errors = e;
        }
        this.globalError = '';
        this.saveSuccess = '';
    }

    // ── Update Handlers ────────────────────────────────────────────────────────
    async updateBasic() {
        if (!this.validateBasic()) return;
        this.isSaving = true;
        this.globalError = '';
        this.saveSuccess = '';
        // try {
        //     await updateLeadBasic({
        //         leadId: this.recordId,
        //         basicData: {
        //             firstName:    this.formData.firstName,
        //             lastName:     this.formData.lastName,
        //             mobileNumber: this.formData.mobileNumber,
        //             pincode:      this.formData.pincode,
        //             age:          this.formData.age,
        //             email:        this.formData.email
        //         }
        //     });
        //     this._computeScore();
        //     await this.refs.scoreCard?.refreshScoreCard();

        //     this.saveSuccess = 'Basic information updated successfully.';
        // } catch (err) {
        //     this.globalError = this.extractError(err);
        // } finally {
        //     this.isSaving = false;
        // }
    }

    async updateEducation() {
        if (!this.validateEducation()) return;
        this.isSaving = true;
        this.globalError = '';
        this.saveSuccess = '';
        // try {
        //     await updateEducationInfo({
        //         leadId: this.recordId,
        //         educationData: {
        //             currentEducationLevel:  this.formData.currentEducationLevel,
        //             plannedCountryForStudy: this.formData.plannedCountryForStudy,
        //             plannedCourseForStudy:  this.formData.plannedCourseForStudy,
        //             courseStartDate:        this.formData.courseStartDate,
        //             admissionStatus:        this.formData.admissionStatus
        //         }
        //     });
        //             await this.refs.scoreCard?.refreshScoreCard();

        //     this.saveSuccess = 'Education information updated successfully.';
        // } catch (err) {
        //     this.globalError = this.extractError(err);
        // } finally {
        //     this.isSaving = false;
        // }
    }

    async updateFunding() {
        if (!this.validateFunding()) return;
        this.isSaving = true;
        this.globalError = '';
        this.saveSuccess = '';
        // try {
        //     await updateFundingInfo({
        //         leadId: this.recordId,
        //         fundingData: {
        //             product:         this.formData.product,
        //             totalCourseFee:  this.formData.totalCourseFee,
        //             tuitionFee:      this.formData.tuitionFee,
        //             hostelCost:      this.formData.hostelCost,
        //             livingExpenses:  this.formData.livingExpenses,
        //             ownContribution: this.formData.ownContribution,
        //              requiredLoanAmount: this.requiredLoanAmount
        //         }
        //     });
        //             await this.refs.scoreCard?.refreshScoreCard();

        //     this.saveSuccess = 'Funding information updated successfully.';
        // } catch (err) {
        //     this.globalError = this.extractError(err);
        // } finally {
        //     this.isSaving = false;
        // }
    }

    async updateCoApplicant() {
        if (!this.validateCoApplicant()) return;
        this.isSaving = true;
        this.globalError = '';
        this.saveSuccess = '';
        // try {
        //     await updateCoApplicantInfo({
        //         leadId: this.recordId,
        //         coData: {
        //             isCoapplicantAvailable: this.formData.isCoapplicantAvailable,
        //             coapplicantName:         this.formData.coapplicantName,
        //             relationshipWithStudent: this.formData.relationshipWithStudent,
        //             coapplicantAge:          this.formData.coapplicantAge,
        //             coapplicantMobile:       this.formData.coapplicantMobile,
        //             coapplicantOccupation:   this.formData.coapplicantOccupation,
        //             employmentType:          this.formData.employmentType,
        //             // incomeType:              this.formData.incomeType,
        //             // monthlyAnnualIncome:     this.formData.monthlyAnnualIncome
        //             incomeRange:             this.formData.incomeRange
        //         }
        //     });
        //     await this.refs.scoreCard?.refreshScoreCard();
        //     this.saveSuccess = 'Co-applicant information updated successfully.';
        // } catch (err) {
        //     this.globalError = this.extractError(err);
        // } finally {
        //     this.isSaving = false;
        // }
    }

    async updateCollateral() {
        if (!this.validateCollateral()) return;
        this.isSaving = true;
        this.globalError = '';
        this.saveSuccess = '';
        // try {
        //     await updateCollateralInfo({
        //         leadId: this.recordId,
        //         collateralData: {
        //             isCollateralAvailable: this.formData.isCollateralAvailable,
        //             collateralUnit:        this.formData.collateralUnit,
        //              propertyType:          this.formData.propertyType,
        //             collateralCity:        this.formData.collateralCity,
        //             collateralState:       this.formData.collateralState,
        //             collateralPincode:     this.formData.collateralPincode,
        //             collateralAddress:     this.formData.collateralAddress
        //         }
        //     });
        //     this.saveSuccess = 'Property collateral updated successfully.';
        // } catch (err) {
        //     this.globalError = this.extractError(err);
        // } finally {
        //     this.isSaving = false;
        // }
    }

    async updateSourcing() {
        if (!this.validateSourcing()) return;
        this.isSaving = true;
        this.globalError = '';
        this.saveSuccess = '';
        // try {
        //     await updateSourcingInfo({
        //         leadId: this.recordId,
        //         sourcingData: {
        //             leadSource:   this.formData.leadSource,
        //             subChannel:   this.formData.subChannel,
        //             referralName: this.formData.referralName
        //         }
        //     });
        //     this.saveSuccess = 'Sourcing details updated successfully.';
        // } catch (err) {
        //     this.globalError = this.extractError(err);
        // } finally {
        //     this.isSaving = false;
        // }
    }

    // ── Validation ─────────────────────────────────────────────────────────────
    validateSourcing() {
        const errs = {};
        if (!this.formData.leadSource) errs.leadSource = 'Lead source is required.';
        this.errors = errs;
        return Object.keys(errs).length === 0;
    }

    // -- Convert to Opportunity Handlers ----------------------------------------
    handleOpenConvertModal() {
        this.showConvertModal = true;
        this.convertSuccess   = false;
        this.convertedOppId   = '';
        this.convertedOppName = '';
        this.convertError     = '';
    }

    handleCloseConvertModal() {
        if (this.isConverting) return;
        this.showConvertModal = false;
        this.convertSuccess   = false;
        this.convertError     = '';
    }

    async handleConfirmConvert() {
        this.isConverting = true;
        this.convertError = '';
        // try {
        //     const result = await convertLeadToOpportunity({ leadId: this.recordId });
        //     this.convertedOppId   = result.opportunityId;
        //     this.convertedOppName = result.opportunityName;
        //     this.convertSuccess   = true;
        // } catch (err) {
        //     this.convertError = this.extractError(err);
        // } finally {
        //     this.isConverting = false;
        // }
    }

    handleNavigateToOpportunity() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId:   this.convertedOppId,
                actionName: 'view'
            }
        });
    }

    stopPropagation(event) {
        event.stopPropagation();
    }
    validateBasic() {
        const errs = {};
        const { firstName, lastName, mobileNumber, pincode, age } = this.formData;
        if (!firstName.trim())                                   errs.firstName    = 'First name is required.';
        if (!lastName.trim())                                    errs.lastName     = 'Last name is required.';
        if (!mobileNumber || mobileNumber.length !== 10)         errs.mobileNumber = 'Enter a valid 10-digit mobile number.';
        if (!pincode || pincode.length !== 6 || isNaN(pincode))  errs.pincode      = 'Enter a valid 6-digit pincode.';
        const ageNum = parseInt(age, 10);
        if (!age || isNaN(ageNum) || ageNum < 18 || ageNum > 70) errs.age          = 'Age must be between 18 and 70.';
        this.errors = errs;
        return Object.keys(errs).length === 0;
    }

    validateEducation() {
        const errs = {};
        const { plannedCountryForStudy, plannedCourseForStudy, courseStartDate, admissionStatus } = this.formData;
        if (!plannedCountryForStudy.trim()) errs.plannedCountryForStudy = 'Country for study is required.';
        if (!plannedCourseForStudy.trim())  errs.plannedCourseForStudy  = 'Course for study is required.';
        if (!courseStartDate)               errs.courseStartDate        = 'Course start date is required.';
        if (!admissionStatus)               errs.admissionStatus        = 'Admission status is required.';
        this.errors = errs;
        return Object.keys(errs).length === 0;
    }

    validateFunding() {
        const errs = {};
        const { totalCourseFee, ownContribution } = this.formData;
        if (!totalCourseFee || isNaN(parseFloat(totalCourseFee)))         errs.totalCourseFee  = 'Total course fee is required.';
        if (ownContribution !== '' && isNaN(parseFloat(ownContribution))) errs.ownContribution = 'Enter a valid amount.';
        this.errors = errs;
        return Object.keys(errs).length === 0;
    }

    validateCoApplicant() {
        const errs = {};
        if (this.formData.isCoapplicantAvailable === 'Yes') {
            if (!this.formData.coapplicantName.trim())
                errs.coapplicantName = 'Co-applicant name is required.';
            if (!this.formData.coapplicantMobile || this.formData.coapplicantMobile.length !== 10)
                errs.coapplicantMobile = 'Enter a valid 10-digit mobile.';
            // if (!this.formData.monthlyAnnualIncome || isNaN(parseFloat(this.formData.monthlyAnnualIncome)))
            //     errs.monthlyAnnualIncome = 'Income is required.';
            if (!this.formData.incomeRange || isNaN(parseFloat(this.formData.incomeRange)))
    errs.incomeRange = 'Income range is required.';
        }
        this.errors = errs;
        return Object.keys(errs).length === 0;
    }

    validateCollateral() {
        const errs = {};
        if (this.formData.isCollateralAvailable === 'Yes') {
            if (!this.formData.propertyType)
            errs.propertyType = 'Property Type is required.';

            if (!this.formData.collateralUnit.trim())    errs.collateralUnit    = 'Unit/Floor is required.';
            if (!this.formData.collateralCity.trim())    errs.collateralCity    = 'City is required.';
            if (!this.formData.collateralState.trim())   errs.collateralState   = 'State is required.';
            if (!this.formData.collateralPincode || this.formData.collateralPincode.length !== 6)
                errs.collateralPincode = 'Enter a valid 6-digit pincode.';
            if (!this.formData.collateralAddress.trim()) errs.collateralAddress = 'Address is required.';
        }
        this.errors = errs;
        return Object.keys(errs).length === 0;
    }

    // ── Utilities ──────────────────────────────────────────────────────────────
    extractError(err) {
        if (err && err.body && err.body.message) return err.body.message;
        if (err && err.message)                  return err.message;
        return 'An unexpected error occurred. Please try again.';
    }

    handleBranchSelect(event) {
        this.selectedBranchId   = event.detail.branchId;
        this.selectedBranchName = event.detail.branchName;
    }
}

//__________________________GenAI: Generated code ends here______________________________//