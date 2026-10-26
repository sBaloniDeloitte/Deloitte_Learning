import { LightningElement, api, track } from 'lwc';
import getCustomerList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getCustomerList';
import getApplicantsWithType from '@salesforce/apex/COMM_DocumentDetailsScreenController.getApplicantsWithType';
import executeMapping from '@salesforce/apex/COMM_DocumentDetailsScreenController.executeMapping';

export default class GenericDocumentUploadAndView extends LightningElement {
  @api recordId;
  @track ready = false;
  _hasBootstrapped = false;

  connectedCallback() {
    this.bootstrapMapping();
  }

  async bootstrapMapping() {
    if (this._hasBootstrapped || !this.recordId) {
      this.ready = true;
      return;
    }

    try {
      const customers = await getCustomerList({ loanId: this.recordId });
      const applicantIds = (customers || [])
        .map(c => c.value)
        .filter(id => id && id !== 'All');

      if (!applicantIds.length) {
        this.ready = true;
        this._hasBootstrapped = true;
        return;
      }

      const applicantInfos = await getApplicantsWithType({ loanId: this.recordId });
      const typeById = (applicantInfos || []).reduce((m, info) => {
        m[info.id] = info.type;
        return m;
      }, {});

      for (const aid of applicantIds) {
        await executeMapping({
          identifier: 'fromLoan',
          recordId: this.recordId,
          applicantId: aid,
          applicantType: typeById[aid] || ''
        });
      }
    } catch (e) {
      console.error('executeMapping bootstrap failed:', e);
    } finally {
      this._hasBootstrapped = true;
      this.ready = true;
    }
  }
}