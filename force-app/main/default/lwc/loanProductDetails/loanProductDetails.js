import { LightningElement, api, track, wire } from 'lwc';
import fetchAllProducts from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.fetchAllProducts';
import getCollateralRecordsByLoanAppId from '@salesforce/apex/COMM_SalesCollateralDetailsController.getCollateralRecordsByLoanAppId';
import getPrimaryApplicant    from '@salesforce/apex/ApplicantController.getPrimaryApplicant';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import { updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD              from '@salesforce/schema/Opportunity.Id';
import ELIGIBLE_PSL_FIELD    from '@salesforce/schema/Opportunity.Loan_Eligible_for_PSL__c';
import FTR_FIELD from '@salesforce/schema/Opportunity.FTR__c';
import CODE_PSL_FIELD        from '@salesforce/schema/Opportunity.PSL_Code__c';
import DESC_PSL_FIELD        from '@salesforce/schema/Opportunity.PSL_Description__c';
import END_USE_FIELD from '@salesforce/schema/Opportunity.End_Use_of_Fund__c';
import TOTAL_DOC_INCOME_FIELD from '@salesforce/schema/Opportunity.Total_document_income__c';
import LOAN_TO_SENIOR_OFFICIAL_FIELD from '@salesforce/schema/Opportunity.Loan_to_senior_official__c';
import INTENDED_USE_FIELD from '@salesforce/schema/Opportunity.Intended_Use_of_Loan__c';
import CRE_TAGGING_FIELD     from '@salesforce/schema/Opportunity.CRE_Tagging__c';
import RES_UNITS_FIELD       from '@salesforce/schema/Opportunity.The_number_of_residential_dwelling_units__c';
//HL-Prachi
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated';
import getSubStageValues from '@salesforce/apex/Utility_V1.getSubStageValues'
//HL-Prachi

import getApplicantsPEP from '@salesforce/apex/AHL_ApplicantListController.getApplicantsPEP';
import APPROVAL_STATUS_FIELD from '@salesforce/schema/Opportunity.Approval_Status__c';

// —— NEW: pull these two fields off of Opportunity ——
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
const OPPORTUNITY_FIELDS = [
  'Opportunity.Sanction_Loan_Amount__c',
  'Opportunity.Requested_Amount__c',
  'Opportunity.Loan_Eligible_for_PSL__c',
  'Opportunity.Household_Income__c',
  CODE_PSL_FIELD,
  DESC_PSL_FIELD,
   FTR_FIELD,
  'Opportunity.Udaan_Loan__c',
  'Opportunity.Women_Entrepreneurship__c',
  'Opportunity.CRE_Tagging__c',
  'Opportunity.The_number_of_residential_dwelling_units__c',
  END_USE_FIELD,
  TOTAL_DOC_INCOME_FIELD,
  LOAN_TO_SENIOR_OFFICIAL_FIELD,
  INTENDED_USE_FIELD
];



export default class loanProductDetails extends LightningElement {
  @api recordId; // Loan_Application__c record Id


  yesNoOptions = [
    { label: 'Yes', value: 'Yes' },
    { label: 'No',  value: 'No'  }
  ];

  // —— UPDATED: give pslData/creData a loanAmount slot up front ——
  @track productList = [];
  @track pslData = {
     // loanProduct:      '',
     // subProduct:       '',
     // repaymentVariant: '',
     // scheme:           '',
     // subVariant:       '',
     // applicantType:    '',
     // loanAmount:       0,  // ← will be set from Opportunity
      propertyPincode:  '',
      addressType: '',
      loanEligibleForPSL:  '',
      ftrValue:'',
      annualHouseholdIncome: '',
      uddan: false,
      aarohi: false,
      creTagging:       '',
      endUseOfFund: '',          // NEW
    totalDocumentIncome: '',
    loanToSeniorOfficial: false,
    applicantName: '',
    gstin: '',
    udyamRegNo: '',
    natureOfBusiness: '',
    sector: '',
    msmeCategory: ''
  };
  @track creData = {
   // loanProduct:      '',
   // subProduct:       '',
   // repaymentVariant: '',
  //  scheme:           '',
   // loanAmount:       0,  // ← will be set from Opportunity
    resUnits: null ,
    propertyType: '',
    intendedUseLoan: '',
    endUseProperty: ''
  };

  @track costData = {
    costOfPlot: '',
    improvementCost: '', 
    agreementValue: '',
    societyChargesInsurance: '', 
    electricityMunicipalCharges: '',
    architectsContractorsEstimate: '', 
    amenitiesAsPerPolicy: '',
    others: '',
    totalPropertyCost: ''
  };

primaryApplicant = null;


  @track productData  = null;
  @track applicantType = '';
  @track error;
  @track oppdataFetched = false;
  //Added By Prachi
  @track isHLUser= false;
  @track loggedInUserFetched = false;
  //Added By Prachi

  // loading flags
  @track productsLoaded   = false;
  @track applicantsLoaded = false;
  @track isRendered = false;

  // accordion state
  @track activeSections = ['PSL','CRE','COST'];
  psvSalesSubStage=false;

  @track appdataPEP = [];
  @track hasDataPEP = false;
  optionsPEP = [
      { label: 'YES', value: 'YES' },
      { label: 'NO', value: 'NO' },
  ];

  get isDisabledLoanApproval() {
        const blocked = new Set([
            'Hard Rejected',
            'Soft Rejected 1',
            'Soft Rejected 2',
            'Submitted',
            'Rejected'
        ]);
        const status = this.approvalStatus;
        return status ? blocked.has(status) : false;
    }

    @wire(getRecord, { recordId: "$recordId", fields: [APPROVAL_STATUS_FIELD] })
    loan;

    get approvalStatus() {
        return getFieldValue(this.loan?.data, APPROVAL_STATUS_FIELD);
    }

  // spinner until both wires finish
  get isLoading() {
    return !(this.productsLoaded && this.applicantsLoaded && this.oppdataFetched && this.loggedInUserFetched);
  }

  get isIndividual() {
    return (this.applicantType || '').toLowerCase() === 'individual';
  }

  get isHlUserRelated() {
    return (this.isHLUser );
  }

  connectedCallback() {
    this.getSubStageValues();
    this.checkIfLoggedInUserIsHLRelated();
    this.loadProducts();
    //this.loadCollaterals();
    this.getAppDetailsPEP();
  }

  getAppDetailsPEP() {
        getApplicantsPEP({
            recordId: this.recordId,
        })
        .then((response) => {
            this.appdataPEP = response;
            if (this.appdataPEP.length > 0) {
                this.hasDataPEP = true;
            }
        })
        .catch((error) => {
        console.log("error in getEmployeeCheckData---", error);
        });
    }

    handleChangePEP(event) {
        const seletedVal = event.target.value;
        const requestId = event.target.dataset.id;
        console.log('seletedVal ',seletedVal ,' requestId ',requestId);

        const fields = {};
        fields['Id'] = requestId;
        fields['PEP__c']=seletedVal;
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
        .then(() => {
            this.showToast("Success", "Updated successfully'", "success");
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
    }

  @wire(getPrimaryApplicant, { loanApplicantionId: '$recordId' })
  wiredApplicants({ data, error }) {
    if (data) {
      this.primaryApplicant = data[0] || null; 
      this.applicantType = data[0]?.Customer_Type__c || '';
    } else if (error) {
      console.error(
        'Error fetching applicants:',
        error?.body?.message || error?.message || error
      );
      this.primaryApplicant = null;
      this.applicantType = '';
    }
     this.applicantsLoaded = true;
    this.processAllData();
  }

  // —— NEW: wire the Opportunity record to fetch loan amounts ——
  @wire(getRecord, { recordId: '$recordId', fields: OPPORTUNITY_FIELDS })
  wiredOpportunity({ data, error }) {
    if (data) {
      const sanction = getFieldValue(data, OPPORTUNITY_FIELDS[0]);
      const requested = getFieldValue(data, OPPORTUNITY_FIELDS[1]);
      const eligible  = getFieldValue(data, OPPORTUNITY_FIELDS[2]) || '';
      const household = getFieldValue(data, OPPORTUNITY_FIELDS[3]) || '';
      const codePick   = getFieldValue(data, OPPORTUNITY_FIELDS[4]) || '';
    const descPick   = getFieldValue(data, OPPORTUNITY_FIELDS[5]) || '';
    const ftrPick = getFieldValue(data, OPPORTUNITY_FIELDS[6]) || '';
      const udaanPick = getFieldValue(data, OPPORTUNITY_FIELDS[7]) || 'No';
      const aarohiPick= getFieldValue(data, OPPORTUNITY_FIELDS[8]) || 'No';
      const crePick   = getFieldValue(data, OPPORTUNITY_FIELDS[9]) || '';
    const resUnits  = getFieldValue(data, OPPORTUNITY_FIELDS[10]) || '';
      const loanAmt = sanction || requested || 0;
      const endUse = getFieldValue(data, END_USE_FIELD) || '';
  const totalDocIncome = getFieldValue(data, TOTAL_DOC_INCOME_FIELD);
  const loanToSeniorOfficial = getFieldValue(data, LOAN_TO_SENIOR_OFFICIAL_FIELD) || false;
  const intendedUse = getFieldValue(data, INTENDED_USE_FIELD) || '';

      // merge into both PSL & CRE
      this.pslData = { ...this.pslData, loanAmount: loanAmt, loanEligibleForPSL: eligible, annualHouseholdIncome: household,
      pslCode: codePick,pslDescription: descPick, ftrValue: ftrPick,
      uddan: udaanPick.toLowerCase() === 'yes', aarohi: aarohiPick.toLowerCase() === 'yes',
      creTagging:  crePick, endUseOfFund: endUse,
    totalDocumentIncome: (totalDocIncome === undefined ? null : totalDocIncome), loanToSeniorOfficial};
      this.creData = { ...this.creData, loanAmount: loanAmt, creTagging:crePick,
     resUnits: resUnits ?? null, intendedUseLoan: intendedUse, endUseProperty: endUse };
    } else if (error) {
      console.error('Error fetching Opportunity amounts', error);
    }
    this.oppdataFetched = true;
     this.processAllData(); 
  }

  @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
  objectInfo;

  showToast(title, message, variant = 'success') {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  getFieldLabel(apiName) {
    return this.objectInfo?.data?.fields?.[apiName]?.label || null;
  }
  prettyName(name) {
    const map = {
      loanEligibleForPSL: 'Loan Eligible for PSL',
      pslCode: 'PSL Code',
      pslDescription: 'PSL Description',
      ftrValue: 'FTR',
      creTagging: 'CRE Tagging',
      resUnits: 'The number of residential dwelling units'
    };
    return map[name] || name;
  }

  
  loadProducts() {
    this.productsLoaded = false;
    fetchAllProducts({ loanId: this.recordId })
      .then((data) => {
        this.productData = data || [];
        this.productList = data || [];
        this.error = undefined;
      })
      .catch((error) => {
        this.error = error;
        console.error(
          "Error fetching products (imperative):",
          error?.body?.message || error?.message || error
        );
      })
      .finally(() => {
        this.productsLoaded = true;
        this.processAllData();   
      });
  }

 
  //Changes Added By Prachi Start
  loadCollaterals() {
    console.log('241---',this.isHLUser);
    getCollateralRecordsByLoanAppId({ loanAppId: this.recordId })
      .then((data) => {
        console.log('data>>'+JSON.stringify(data));
          // be robust about matching "Primary"
          const primary = (data || []).find(
            c => c?.primarySecondary  && c.primarySecondary .toString().trim().toLowerCase() === 'primary'
          );
          const pin = primary?.pincode || '';
          const addType = primary?.addressType || '';
          const propType= primary?.unitType   || ''; 
          //Changes Added By Prachi 
          if(this.isHLUser){
                  // COST (parent level)
                  const parentCost = {
                      costOfPlot: primary?.costOfPlot ?? "",
                      improvementCost: primary?.improvementCost ?? "",
                      agreementValue: primary?.agreementValue ?? "",
                      societyChargesInsurance: primary?.societyCharges ?? "",
                      electricityMunicipalCharges: primary?.electricityMunicipleCharges ?? "",
                      architectsContractorsEstimate: primary?.architectsEstimate ?? "",
                      amenitiesAsPerPolicy: primary?.amenitiesPermitPolicy ?? "",
                      others: primary?.others ?? "",
                      totalPropertyCost: primary?.totalPropertyCost ?? "",
                      documentValue : primary?.docVal ?? ""
                  };
                  

                  // Add display formatted cost values
                  const parentCostDisplay = {
                      costOfPlotDisplay: this.formatINR(parentCost.costOfPlot),
                      improvementCostDisplay: this.formatINR(parentCost.improvementCost),
                      agreementValueDisplay: this.formatINR(parentCost.agreementValue),
                      societyChargesInsuranceDisplay: this.formatINR(parentCost.societyChargesInsurance),
                      electricityMunicipalChargesDisplay: this.formatINR(parentCost.electricityMunicipalCharges),
                      architectsContractorsEstimateDisplay: this.formatINR(parentCost.architectsContractorsEstimate),
                      amenitiesAsPerPolicyDisplay: this.formatINR(parentCost.amenitiesAsPerPolicy),
                      othersDisplay: this.formatINR(parentCost.others),
                      totalPropertyCostDisplay: this.formatINR(parentCost.totalPropertyCost)
                  };

                  // Flatten data into product list
                  this.productList = (this.productList || []).map(prod => {
                      // plfData and creData from product
                      const plf = prod.plfData || {};
                      const cre = prod.creData || {};
                      const cost = parentCost;

                      return {
                          ...prod,

                          // Flatten plfData fields directly into product
                          propertyPincode: pin,
                          addressType: addType,
                          // also flatten any other plfData fields if needed here
                          ...plf,

                          // Flatten creData fields directly into product with 'cre_' prefix (optional)
                          propertyType: propType,
                          ...Object.fromEntries(
                              Object.entries(cre).map(([k, v]) => [`cre_${k}`, v])
                          ),

                          // Flatten costData fields directly into product
                          ...cost,
                          ...parentCostDisplay
                      };
                  });
          }else{
              // merge so we don’t wipe other PSL fields
              this.pslData = { ...this.pslData, propertyPincode: pin, addressType: addType  };
              this.creData = { ...this.creData, propertyType: propType };
              this.costData = {
                costOfPlot: primary?.costOfPlot ?? '',
                improvementCost: primary?.improvmentCost ?? '',
                agreementValue: primary?.agreementValue ?? '',
                societyChargesInsurance: primary?.societyCharges ?? '',
                electricityMunicipalCharges:  primary?.electricityMunicipleCharges ?? '',
                architectsContractorsEstimate:primary?.architectsEstimate ?? '',
                amenitiesAsPerPolicy: primary?.amenitiesPermitPolicy ?? '',
                others: primary?.others ?? '',
                totalPropertyCost: primary?.totalPropertyCost ?? ''
              };
          }
      })
        .catch(err => 
          {
            console.error('err325>>'+err);

          });
  }

  processAllData() {
    // only once both wires have signaled
    if (!(this.productsLoaded && this.applicantsLoaded && this.oppdataFetched && this.loggedInUserFetched)) {
      return;
    }
    const isIndividual = (this.applicantType || "").trim().toLowerCase() === "individual";
    console.log('this.applicantType',this.applicantType);
    console.log('371---HlUser',this.isHLUser);
    let applicantExtras = {};
    //Changes Done By Prachi Start
    if(this.isHLUser){
      console.log('371---');
        delete this.pslData.loanAmount;
        delete this.creData.loanAmount;
      if (!isIndividual && this.primaryApplicant) {
        const a = this.primaryApplicant;

        applicantExtras = {
          applicantName: a.Applicant_Name__c || "",
          gstin: a.GSTIN__c || "",
          udyamRegNo: a.Udhyam_Registration_No__c || "",
          natureOfBusiness: a.Nature_of_Business__c || "",
          sector: a.Sector__c || "",
          msmeCategory: a.MSME_Category__c || ""
        };
      }

      this.productList = (this.productList || []).map(prod => {
        // Base PSL values
        const pslBase = {
          loanProduct: prod.prodName || "",
          subProduct: prod.subProdName || "",
          repaymentVariant: prod.variant || "",
          scheme: prod.schemeProdName || "",
          subVariant: prod.subvariantName || "",
          loanAmount: prod.sanctionedAmount || prod.loanAmoutReq || 0
        };

        // Base CRE values
        const creBase = {
          creLoanProduct: prod.prodName || "",
          creSubProduct: prod.subProdName || "",
          creRepaymentVariant: prod.variant || "",
          creScheme: prod.schemeProdName || "",
          creLoanAmount: prod.loanAmoutReq || 0
        };

        // Flatten creData fields with 'cre' prefix to avoid key collision
        const creFlattened = {};
        Object.entries({
          ...creBase,
          ...(this.creData || {}),
          ...(prod.creData || {})
        }).forEach(([key, val]) => {
          // Add cre_ prefix if not already prefixed
          const newKey = key.startsWith('cre') ? key : `cre_${key}`;
          creFlattened[newKey] = val;
        });

        // Flatten pslData fields without prefix (since no collision expected)
        const pslFlattened = {
          ...pslBase,
          ...applicantExtras,
          ...(this.pslData || {}),
          ...(prod.plfData || {})
        };

        return {
          ...prod,
          labelName: prod.subProdName ? `${prod.prodName} / ${prod.subProdName}` : prod.prodName,
          applicantType: this.applicantType,
          ...pslFlattened,
          ...creFlattened
        };
      });
    }else{
      if (this.productData && this.productData.length) {
        const info = this.productData[0];

        this.pslData = {
          ...this.pslData,
          loanProduct:      info.prodName || '',
          subProduct:       info.subProdName || '',
          repaymentVariant: info.variant || '',
          scheme:           info.schemeProdName || '',
          subVariant:       info.subvariantName || '',
          applicantType:    this.applicantType
          // loanAmount is preserved from wiredOpportunity
        };

        this.creData = {
          ...this.creData,
          loanProduct:      info.prodName || '',
          subProduct:       info.subProdName || '',
          repaymentVariant: info.variant || '',
          scheme:           info.schemeProdName
          // loanAmount is preserved from wiredOpportunity
        };
      }
      if (!isIndividual && this.primaryApplicant) {
        const a = this.primaryApplicant;
        this.pslData = {
          ...this.pslData,
          applicantName:    a.Applicant_Name__c           || '',
          gstin:            a.GSTIN__c                    || '',
          udyamRegNo:       a.Udhyam_Registration_No__c   || '',
          natureOfBusiness: a.Nature_of_Business__c       || '',
          sector:           a.Sector__c                   || '',
          msmeCategory:     a.MSME_Category__c            || ''
        };
      } 
    }
     this.loadCollaterals();
  }

  checkIfLoggedInUserIsHLRelated(){
        checkIfLoggedInUserIsHLRelated()
        .then(result => {
            this.isHLUser = result.isHLRelated;
            if(this.isHLUser && this.isCrif){
                this.isHLUser =false;
             console.log('  this.isHLUser----'+  this.isHLUser);
            }
            console.log('isHLUser-->',this.isHLUser);
        })
        .catch(error => {
            console.log('error-->',error);
        })
        this.loggedInUserFetched = true;
        this.processAllData();
  }
  //Changes Done By Prachi End

  handleFieldChange(event) {
    console.log('handleFieldChange>>>');
    const { name, value, type, checked } = event.target;
    let fieldValue = (type === 'checkbox') ? checked : value;
    console.log('469>>>'+name + '--'+fieldValue);
    if (name === 'resUnits') {
      fieldValue = (value === '' || value == null) ? null : Number(value);
      if (fieldValue !== null && Number.isNaN(fieldValue)) return; // invalid number
    }
    console.log('476>>>');
    if (name === 'totalDocumentIncome') {
      fieldValue = (value === '' || value == null) ? null : Number(value);
      if (fieldValue !== null && Number.isNaN(fieldValue)) return; // invalid number
    }
    console.log('481>>>');

    // Keys to identify which data object to update
    const pslKeys = ['loanEligibleForPSL','pslCode','pslDescription','ftrValue','endUseOfFund','totalDocumentIncome','loanToSeniorOfficial'];
    const creKeys = ['creTagging','resUnits','intendedUseLoan','endUseProperty'];

    // Update local state and sync related fields
    if (pslKeys.includes(name)) {
      this.pslData = { ...this.pslData, [name]: fieldValue };

      if (name === 'endUseOfFund') {
        this.creData = { ...this.creData, endUseProperty: fieldValue };
      }

      this.processAllData(); // Refresh UI data after update

    } else if (creKeys.includes(name)) {
      this.creData = { ...this.creData, [name]: fieldValue };

      if (name === 'endUseProperty') {
        this.pslData = { ...this.pslData, endUseOfFund: fieldValue };
      }
      console.log('502>>>');
      this.processAllData(); // Refresh UI data after update
      console.log('504>>>');
    }

    // If the changed field is one we need to persist to server
    if (pslKeys.concat(creKeys).includes(name)) {
      console.log('509>>');
      const fields = { [ID_FIELD.fieldApiName]: this.recordId };
      let apiName = null;

      switch (name) {
        // PSL Fields
        case 'loanEligibleForPSL':
          apiName = ELIGIBLE_PSL_FIELD.fieldApiName;
          break;
        case 'pslCode':
          apiName = CODE_PSL_FIELD.fieldApiName;
          break;
        case 'pslDescription':
          apiName = DESC_PSL_FIELD.fieldApiName;
          break;
        case 'ftrValue':
          apiName = FTR_FIELD.fieldApiName;
          break;
        case 'endUseOfFund':
          apiName = END_USE_FIELD.fieldApiName;
          break;
        case 'totalDocumentIncome':
          apiName = TOTAL_DOC_INCOME_FIELD.fieldApiName;
          break;
        case 'loanToSeniorOfficial':
          apiName = LOAN_TO_SENIOR_OFFICIAL_FIELD.fieldApiName;
          break;

        // CRE Fields
        case 'creTagging':
          apiName = CRE_TAGGING_FIELD.fieldApiName;
          break;
        case 'resUnits':
          apiName = RES_UNITS_FIELD.fieldApiName;
          break;
        case 'intendedUseLoan':
          apiName = INTENDED_USE_FIELD.fieldApiName;
          break;
        case 'endUseProperty':
          apiName = END_USE_FIELD.fieldApiName;
          break;
      }
      console.log('apiName>>>'+apiName);

      fields[apiName] = fieldValue;
      console.log('fields>>'+ JSON.stringify(fields));

      updateRecord({ fields })
        .then(() => {
          console.log('549>>>');
          const label = this.getFieldLabel(apiName) || this.prettyName(name);
          this.showToast('Saved', `${label} updated successfully.`, 'success');
        })
        .catch(err => {
          console.log('Errror>>'+JSON.stringify(err));
          const msg = err?.body?.message || err?.message || 'Update failed.';
          const label = this.getFieldLabel(apiName) || this.prettyName(name);
          this.showToast('Error saving', `Could not update ${label}: ${msg}`, 'error');
        });
    }
  }
  handleToggleSection(event) {
    this.activeSections = event.detail.openSections;
  }

  get hasError() {
    return !!this.error;
  }
  get errorMessage() {
    return this.error?.body?.message
        || this.error?.message
        || 'An unknown error occurred';
  }

  formatINR(value) {
  if (value === '' || value === null || value === undefined) return '';
  const num = Number(value);
  if (Number.isNaN(num)) return value; // leave as-is if not numeric
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 2
  }).format(num);
}
get costOfPlotDisplay() {
  return this.formatINR(this.costData?.costOfPlot);
}
get improvementCostDisplay() {
  return this.formatINR(this.costData?.improvementCost);
}
get agreementValueDisplay() {
  return this.formatINR(this.costData?.agreementValue);
}
get societyChargesInsuranceDisplay() {
  return this.formatINR(this.costData?.societyChargesInsurance);
}
get electricityMunicipalChargesDisplay() {
  return this.formatINR(this.costData?.electricityMunicipalCharges);
}
get architectsContractorsEstimateDisplay() {
  return this.formatINR(this.costData?.architectsContractorsEstimate);
}
get amenitiesAsPerPolicyDisplay() {
  return this.formatINR(this.costData?.amenitiesAsPerPolicy);
}
get othersDisplay() {
  return this.formatINR(this.costData?.others);
}
get totalPropertyCostDisplay() {
  return this.formatINR(this.costData?.totalPropertyCost);
}

get documentValue(){
  return this.costData?.documentValue;
}

renderedCallback() {
        if (!this.isRendered) {
            // Create and append styles dynamically
            const style = document.createElement("style");
            style.innerText = `
            .bsa-page .slds-accordion__list-item .section-control{
                background: linear-gradient(135deg, #001a5e 0%, #003087 55%, #004db3 100%);
                color: #ffffff;
                margin-left: 0px;
                margin-bottom: 0px;
                margin-right: 0px;
                font-weight: 500;
            }
            .bsa-page .slds-accordion__list-item .section-control .slds-accordion__summary-heading,
            .bsa-page .slds-accordion__list-item .section-control .slds-accordion__summary-action,
            .bsa-page .slds-accordion__list-item .section-control .slds-truncate {
                color: #ffffff !important;
            }
            .bsa-page .slds-accordion__list-item .section-control svg,
            .bsa-page .slds-accordion__list-item .section-control .slds-button__icon {
                fill: #ffffff !important;
            }
            .bsa-page .slds-accordion__summary {
                padding: 10px 0px 0px 0px;
            }
            .bsa-datatable .slds-line-height_reset .slds-cell-fixed .slds-th__action{
                background: #5bb6e3;
                color: white;
            }
            .bsa-datatable .slds-th__action.slds-th__action_form.slds-cell-fixed{
                background: #5bb6e3;
            }
            .bsa-datatable tbody{
                font-weight: 400;
            }
            .bsa-page .slds-accordion__content {
                margin-top: 10px;
                background-color: #12172b;
            }
            .bsa-page .slds-form-element__label {
                color: #ffffff;
            }
            .bsa-page .slds-input,
            .bsa-page .slds-textarea,
            .bsa-page .slds-combobox__input {
                background-color: #1c2238;
                color: #ffffff;
                border-color: #2a2f45;
            }
            .bsa-page .slds-listbox__option,
            .bsa-page .slds-dropdown,
            .bsa-page .slds-dropdown__list {
                background-color: #1c2238;
                color: #ffffff;
            }
        `;
            // Append the styles to the .styleContainer
            this.template.querySelector(".styleContainer")?.appendChild(style);
            // Prevent re-adding styles
            this.isRendered = true;
        }
    }

      getSubStageValues(){
      getSubStageValues({
        loanId: this.recordId
      })
      .then(result=>{
        if(result=='PSV Sales'){
          this.psvSalesSubStage=true;
        }
        else{
          this.psvSalesSubStage=false;
        }

      })
      .catch(err=>{

      })
    }


  
}