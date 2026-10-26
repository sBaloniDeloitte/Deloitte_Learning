import { LightningElement, api, track } from 'lwc';
import getAllDocument from '@salesforce/apex/SalesDocumentCmpController.getAllDocumentSales';
import isForm60Uploaded from '@salesforce/apex/COMM_DocumentDetailsScreenController.isForm60Uploaded';
import getApplicantsWithType from '@salesforce/apex/COMM_DocumentDetailsScreenController.getApplicantsWithType';
import getDocumentChecklistRecords from '@salesforce/apex/COMM_DocumentDetailsScreenController.getDocumentChecklistRecords';
import checkCKYCfetched from '@salesforce/apex/SalesDocumentCmpController.checkApiHit';
import getPanandDob from '@salesforce/apex/SalesDocumentCmpController.getPanandDob';
// import uploadFile from '@salesforce/apex/SalesDocumentCmpController.uploadFile';
import getCustomerList from '@salesforce/apex/COMM_DocumentDetailsScreenController.getCustomerList';
import createChecklistRecord from '@salesforce/apex/COMM_DocumentDetailsScreenController.createChecklistRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import initateCKYC from '@salesforce/apex/CKYCIndividualController.initiateAPIRequest'
import executeMapping from '@salesforce/apex/COMM_DocumentDetailsScreenController.executeMapping';
import getChecklistMasterIds from '@salesforce/apex/COMM_DocumentDetailsScreenController.getChecklistMasterIds';
import documentCheckListUpdation from '@salesforce/apex/COMM_SalesLoanActionsController.documentCheckListUpdation';
import getRelatedDocumentCategory from '@salesforce/apex/COMM_DocumentDetailsScreenController.getRelatedDocumentCategory';
export default class SalesDocumentCmp extends LightningElement {
  @api recordId; // Get the current record id
  @track documents = [];
  @track isFormSixty=false;
  @track pairedDocs = [];
  @api isDisabled;
  @track isZoomed = false;
  @track zoomedImage = '';
  @track showDocumentTable = false;
  @track selectedDocumentsForTable = [];
  @track showSummaryStyle = true;
  @track panels = [];
  file;
  fileName;
  @track currentPage = 1;
  pageSize = 2;

  _appId;
  @api
  set appId(value) {
    this._appId = value;
    console.log('appId set →', value);
    this._tryInitialize();
  }
  get appId() {
    return this._appId;
  }

  @api loginChecklist;
  ckyc = true;
  @track paginatedDocuments = [];
  showdoc = true;
  @track isSpinnerLoading = false;
  @api loan = false;
  fetchagain = false;
  panNo;
  dateOfBirth;
  imageMap;
  imagetypemap;
  documentTypes = [];
  docCategory = [];
  showDocSelection = false;
  showCategorySelection = true;
  @track modalVisibility = false;
  @track docCheckList = [];
  docMasterIdList = [];
  _masterMap = new Map();
  docMasterIdDelList = [];
  _hasInitialized = false;
  @track showApplicantPicker = false;
  @track applicantOptions = [];
  applicantList = [];
  selectedApplicantId = '';
  _hasRunMapping = false;
  @track modalMasterIds = [];
  @track modalMasterDeletes = [];
  selectedApplicantType = '';
  _perApplicantState = new Map();
  _appDetailMap = new Map();
  _loanDetailMap = new Map();

  connectedCallback() {
    if (!this.loan) {
      this.checkCKYCfetched();
    }
  }

  renderedCallback() {
    if (this.modalVisibility) {
        setTimeout(() => {
            // Try to find the modal container
            const modal = this.template.querySelector('.slds-modal__container');
            if (modal) {
                modal.scrollIntoView({ behavior: 'smooth', block: 'center' });
            } else {
                // Fallback: scroll to top
                window.scrollTo({ top: 0, behavior: 'smooth' });
            }
        }, 300); // Slight delay for DOM render
    }
    this._tryInitialize();
  }

  _tryInitialize() {
    if (!this._hasInitialized && this.recordId && this._appId) {
      this._hasInitialized = true;
      console.log('Initializing refreshAllData with', {
        recordId: this.recordId,
        appId: this._appId
      });
      this.refreshAllData();
    }
  }

  async refreshAllData() {
    this.isSpinnerLoading = true;
    try {
      const customers = await getCustomerList({ loanId: this.recordId });
      const applicantIds = customers
        .map(c => c.value)
        .filter(id => id && id !== 'All');

      const applicantInfos = await getApplicantsWithType({ loanId: this.recordId });
      const typeById = applicantInfos.reduce((m, info) => {
        m[info.id] = info.type;
        return m;
      }, {});

      if (!this._hasRunMapping) {
        for (const aid of applicantIds) {
          console.log(`executeMapping for applicant ${aid}`);
          await executeMapping({
            identifier: 'fromLoan',
            recordId: this.recordId,
            applicantId: aid,
            applicantType: typeById[aid] || ''
          });
        }
        this._hasRunMapping = true;
      }
      const allMasterArrays = await Promise.all(
        applicantIds.map(aid =>
          getChecklistMasterIds({ loanAppId: this.recordId, applicantId: aid })
        )
      );
      this.docMasterIdList = Array.from(
        new Set(allMasterArrays.flat())
      );
      const allWrapperLists = await Promise.all(
        applicantIds.map(aid =>
          getRelatedDocumentCategory({
            identifier: 'fromLoan',
            recordId: this.recordId,
            applicantId: aid,
            applicantType: 'Primary Applicant'
          })
        )
      );
      this._masterMap.clear();
      allWrapperLists
        .flat()
        .forEach(w => {
          w.docList.forEach(doc => {
            this._masterMap.set(doc.Id, {
              name: doc.Name,
              category: w.docType,
              isRequired: doc.isDisabled
            });
          });
        });
      const allDocsArrays = await Promise.all(
        applicantIds.map(aid =>
          getAllDocument({
            recordId: this.recordId,
            catg: 'Sales',
            appId: aid,
            loan: this.loan
          })
        )
      );
      const allDocs = allDocsArrays.flat();

      const actualRows = allDocs.map(d => ({
        id: d.Id,
        masterId: d.Document_Master__c,
        name: d.Name,
        contentId: d.docContentId,
        isRequired: d.Is_Required__c,
        docCategory: d.Document_Category__c
      }));
      const existing = new Set(actualRows.map(r => r.masterId));
      const placeholderRows = this.docMasterIdList
        .filter(mid => !existing.has(mid))
        .map(mid => {
          const m = this._masterMap.get(mid) || {};
          return {
            id: `ph-${mid}`,
            masterId: mid,
            name: m.name || '—',
            contentId: null,
            isRequired: m.isRequired || false,
            docCategory: m.category || ''
          };
        });

      const rows = [...actualRows, ...placeholderRows];
      this.selectedDocumentsForTable = this.formatDocumentsForTable(rows);
      this.showDocumentTable = rows.length > 0;

    } catch (e) {
      console.error('refreshAllData error', e);
      this.showDocumentTable = false;
    } finally {
      this.isSpinnerLoading = false;
    }
  }
  get hasDocs() {
    return Array.isArray(this.docCheckList) && this.docCheckList.length > 0;
  }

  getAllRelatedDocs() {
    this.isSpinnerLoading = true;
    return getChecklistMasterIds({
      loanAppId: this.recordId,
      applicantId: this.appId
    })
      .then(masters => {
        this.docMasterIdList = masters || [];
        this.showDocumentTable = this.docMasterIdList.length > 0;
        return getRelatedDocumentCategory({
          identifier: 'fromLoan',
          recordId: this.recordId,
          applicantId: this.appId,
          applicantType: 'Primary Applicant'
        });
      })
      .then(categoryWrappers => {
        this._masterMap = new Map();
        categoryWrappers.forEach(wrapper => {
          wrapper.docList.forEach(doc => {
            this._masterMap.set(doc.Id, {
              name: doc.Name,
              category: wrapper.docType,
              isRequired: doc.isDisabled
            });
          });
        });
        return getAllDocument({
          recordId: this.recordId,
          catg: 'Sales',
          appId: this.appId,
          loan: this.loan
        });
      })
      .then(docs => {
        const actualRows = docs.map(d => ({
          id: d.Id,
          masterId: d.Document_Master__c,
          name: d.Name,
          contentId: d.docContentId,
          isRequired: d.Is_Required__c,
          docCategory: d.Document_Category__c,
          showUpload: !d.docContentId,
          showView: !!d.docContentId,
          showDelete: true,
          showRetake: !!d.docContentId
        }));
        const existing = new Set(actualRows.map(r => r.masterId));
        const placeholderRows = this.docMasterIdList
          .filter(mid => !existing.has(mid))
          .map(mid => {
            const m = this._masterMap.get(mid) || {};
            return {
              id: `ph-${mid}`,
              masterId: mid,
              name: m.name || '—',
              contentId: null,
              isRequired: m.isRequired || false,
              docCategory: m.category || '',
              showUpload: true,
              showView: false,
              showDelete: true,
              showRetake: false
            };
          });

        const rows = [...actualRows, ...placeholderRows];
        this.selectedDocumentsForTable = this.formatDocumentsForTable(rows);
        this.showDocumentTable = rows.length > 0;
      })
      .catch(err => {
        console.error('Error in getAllRelatedDocs:', err);
        this.showDocumentTable = false;
      })
      .finally(() => {
        this.isSpinnerLoading = false;
      });
  }

  async fileupload(event) {
    event.stopPropagation();
    this.showdoc = false;
    await this.refreshAllData();
  }

  callCkyc() {
    getPanandDob({ appId: this.appId })
      .then(res => {
        this.panNo = res.pan;
        this.dateOfBirth = res.dob;
        const inputMap = {
          loanId: this.recordId,
          applicantId: this.appId,
          processName: 'Loan Applicant CKYC',
          panNum: this.panNo,
          dob: this.dateOfBirth
        };
        console.log('inputMap -->' + JSON.stringify(inputMap));
        //return initateCKYC({ inputMap: inputMap });
        return null;
      })
      .then(response => {
        //console.log('initateCKYC response -->' + response);
        if (response && response !== 'Api server failure') {
          this.ckycResp = JSON.parse(response);
          if (this.ckycResp.PID_DATA) {
            //console.log('initateCKYC success');
            const images = this.ckycResp.PID_DATA.IMAGE_DETAILS.IMAGE;
            this.imageMap = images.reduce((acc, image) => {
              if (!acc[image.IMAGE_CODE]) {
                acc[image.IMAGE_CODE] = [];
              }
              acc[image.IMAGE_CODE].push(image.IMAGE_DATA);
              return acc;
            }, {});
            this.imagetypemap = images.reduce((acc, image) => {
              acc[image.IMAGE_CODE] = image.IMAGE_TYPE;
              return acc;
            }, {});
            console.log('Extracted imageMap -->', this.imageMap);
            console.log('Extracted imageMap -->', JSON.stringify(this.imageMap));
            console.log('Extracted imagetypemap -->', this.imagetypemap);
            console.log('Extracted imagetypemap -->', JSON.stringify(this.imagetypemap));
            this.showToast('success', 'Document fetched successfully.', 'Success');
            this.updateDocumentChecklist();
          } else {
            this.fetchagain = false;
            //console.log('else initateCKYC error');
            this.showToast('error', 'CKYC number not available. Please proceed with manual docs upload.', 'Error');
          }
        } else {
          this.fetchagain = false;
          this.showToast('error', 'CKYC number not available. Please proceed with manual docs upload.', 'Error');
        }
      })
      .catch(error => {
        //console.error('initateCKYC error -->' + JSON.stringify(error));
        this.fetchagain = false;
        this.showToast('error', 'CKYC number not available. Please proceed with manual docs upload.', 'Error');
      });
  }

  updateDocumentChecklist() {
    if (this.imageMap != null) {
      documentCheckListUpdation({
        documentMap: this.imageMap,
        imagetypeMap: this.imagetypemap,
        loanId: this.recordId,
        applicantId: this.appId,
        documentType: 'CKYC'
      })
        .then(res => {
          console.log('updateDocumentChecklist success -->' + JSON.stringify(res));
          this.dispatchEvent(new CustomEvent('checklistupdated'));
        })
        .catch(error => {
          console.error('updateDocumentChecklist error -->' + JSON.stringify(error));
        });
    } else {
      console.log('No imageMap found');
      this.fetchagain = false;
    }
  }
  checkCKYCfetched() {
    console.log('recordId 105' + this.recordId);
    console.log('appId 106' + this.appId);
    checkCKYCfetched({
      recordId: this.recordId,
      appId: this.appId,
      name: 'Loan Applicant CKYC'
    })
      .then(res => {
        //this.isSpinnerLoading = false;
        this.fetchagain = res;
        console.log('updateDocumentChecklist success -->' + JSON.stringify(res));
        if (!this.loginChecklist) {
          if (this.fetchagain) {
            getPanandDob({ appId: this.appId })
              .then(res => {
                this.panNo = res.pan;
                this.dateOfBirth = res.dob;
              })
          }
        } else if (this.loginChecklist) {
          if (this.fetchagain) {
            this.showToast('error', 'Please note that CKYC documents are not fetched yet.', 'Error');
            this.isSpinnerLoading = false;
          }
        }

      }).catch(error => {
        console.error('checkCKYCfetchedt error -->' + JSON.stringify(error));
      });

  }
  addDoc() {
    this.docMasterIdList = [];
    this.docMasterIdDelList = [];
    this.selectedDocumentsForTable = [];
    this.selectedApplicantId = null;
    this.selectedApplicantType = '';
    this.showApplicantPicker = true;

    this.modalVisibility = true;
    this.isSpinnerLoading = true;

    getApplicantsWithType({ loanId: this.recordId })
      .then(wrappers => {
        this.applicantList = wrappers;
        this.applicantOptions = wrappers.map(w => ({
          label: w.name,
          value: w.id
        }));
      })
      .catch(error => {
        console.error('Error loading applicants', error);
        this.showToast('Error', 'Unable to load applicants', 'error');
        this.handleClose();
      })
      .finally(() => {
        this.isSpinnerLoading = false;
      });
  }
  handleClose() {
    this.modalVisibility = false;
    this.showApplicantPicker = false;
    this.selectedApplicantId = '';
    this.selectedApplicantType = '';
    this.isApplicantDropdownOpen = false;
  }

  get selectedApplicantLabel() {
    const found = (this.applicantOptions || []).find(opt => opt.value === this.selectedApplicantId);
    return found ? found.label : 'Select an applicant';
  }

  toggleApplicantDropdown() {
    this.isApplicantDropdownOpen = !this.isApplicantDropdownOpen;
  }

  handleApplicantOptionClick(event) {
    const value = event.currentTarget.dataset.value;
    this.isApplicantDropdownOpen = false;
    this.handleApplicantChange({ detail: { value } });
  }

  async handleApplicantChange(event) {
    this.selectedApplicantId = event.detail.value;
    const sel = this.applicantList.find(a => a.id === this.selectedApplicantId);
    this.selectedApplicantType = sel ? sel.type : null;

    this.showApplicantPicker = false;
    this.isSpinnerLoading = true;
    try {
      await this.getRelatedDocumentCategory(this.selectedApplicantId);
    } finally {
      this.isSpinnerLoading = false;
    }
  }

  // /** Processes document URLs for images and PDFs */
  // processDocumentUrls() {
  //     this.documents = this.documents.map(doc => ({
  //         ...doc, // Keep all original properties
  //         isPdf: doc.docExtension === 'pdf',
  //         fileUrl: `https://${window.location.hostname}/sfc/servlet.shepherd/document/download/${doc.docContentId}`
  //     }));

  //     console.log('Processed Documents with file URLs:', JSON.stringify(this.documents, null, 2));
  //     console.log('fileUrl', doc.fileUrl);
  // }

  // updatePaginatedDocuments() {
  //     const start = (this.currentPage - 1) * this.pageSize;
  //     const end = start + this.pageSize;
  //     this.paginatedDocuments = [...this.documents.slice(start, end)];
  // }

  // get totalPages() {
  //     return Math.ceil(this.documents.length / this.pageSize);
  // }

  // get isFirstPage() {
  //     return this.currentPage === 1;
  // }

  // get isLastPage() {
  //     return this.currentPage >= this.totalPages;
  // }

  // handlePrevious() {
  //     if (this.currentPage > 1) {
  //         this.currentPage--;
  //         this.updatePaginatedDocuments();
  //     }
  // }

  // handleNext() {
  //     if (this.currentPage < this.totalPages) {
  //         this.currentPage++;
  //         this.updatePaginatedDocuments();
  //     }
  // }

  // /** Zoom image */
  // zoomImage(event) {
  //     this.zoomedImage = event.target.src;
  //     this.isZoomed = true;
  // }

  // /** Close zoomed image */
  // closeZoomedImage() {
  //     this.isZoomed = false;
  // }

  //    // Open file dialog when the button is clicked
  //    openFileDialog(event) {
  //     const docContentId = event.target.dataset.docId;
  //     this.template.querySelector(`input[data-doc-id="${docContentId}"]`).click();
  // }

  // /** Handle file selection */


  // // Handle file selection
  // handleFileChange(event) {
  //     const file = event.target.files[0];
  //     if (file) {
  //         console.log('File Name:', file.name);
  //         console.log('File Type:', file.type);
  //         console.log('File Size:', file.size);

  //         // Validate file type
  //         const supportedTypes = ['image/jpeg', 'image/png', 'application/pdf'];
  //         if (!supportedTypes.includes(file.type)) {
  //             this.dispatchEvent(
  //                 new ShowToastEvent({
  //                     title: 'Error',
  //                     message: 'Unsupported file type. Please upload a JPEG, PNG, or PDF file.',
  //                     variant: 'error',
  //                 }),
  //             );
  //             return;
  //         }

  //         // Validate file size (e.g., 3 MB limit)
  //         const maxSize = 3 * 1024 * 1024; // 5 MB
  //         if (file.size > maxSize) {
  //             this.dispatchEvent(
  //                 new ShowToastEvent({
  //                     title: 'Error',
  //                     message: 'File size exceeds the limit of 3 MB.',
  //                     variant: 'error',
  //                 }),
  //             );
  //             return;
  //         }

  //         this.file = file;
  //         this.fileName = file.name;
  //         this.uploadFileToServer();
  //     }
  // }
  // /** Upload file to server using Apex */
  // uploadFileToServer(docContentId) {
  //     const reader = new FileReader();
  //     reader.onload = () => {
  //         const base64 = reader.result.split(',')[1]; // Get base64 data
  //         uploadFile({ base64Data: base64, fileName: this.fileName, docContentId: docContentId })
  //             .then(() => {
  //                 this.dispatchEvent(
  //                     new ShowToastEvent({
  //                         title: 'Success',
  //                         message: 'File uploaded successfully',
  //                         variant: 'success',
  //                     }),
  //                 );


  //                 // Refresh the document list to display the updated image
  //                 this.getAllRelatedDocs();
  //             })
  //             .catch(error => {
  //                 this.dispatchEvent(
  //                     new ShowToastEvent({
  //                         title: 'Error',
  //                         message: error.body.message,
  //                         variant: 'error',
  //                     }),
  //                 );
  //             });
  //     };
  //     reader.readAsDataURL(this.file); // Read file as base64
  // }

  showToast(title, message, variant) {
    const toastEvent = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(toastEvent);
  }

  updateApplicantsDedupe(event) {
    console.log('Ishi 352-- 773--', event.detail.value);
    console.log('Ishi 352--- 604-', event.detail.valuesChanged);
    const valueChangeEvent2 = new CustomEvent("updatedapplicants", {
      detail: {
        value: event.detail.value,
        valuesChanged: event.detail.valuesChanged

      }
    });
    this.dispatchEvent(valueChangeEvent2);
  }
async getRelatedDocumentCategory(applicantOverride) {
  const applicantIdToUse = applicantOverride || this.selectedApplicantId || this.appId;
  const applicantTypeToUse = this.selectedApplicantType || '';

  this.docCheckList = [];
  this.modalMasterIds = [];
  this.modalMasterDeletes = [];
  this._appDetailMap = new Map();
  this._loanDetailMap = new Map();
  this._masterMap = new Map();
  this.isSpinnerLoading = true;

  try {
    // check Form 60 status
    this.isFormSixty = await isForm60Uploaded({ applicantId: applicantIdToUse });

    const wrappers = await getRelatedDocumentCategory({
      identifier: 'fromLoan',
      recordId: this.recordId,
      applicantId: applicantIdToUse,
      applicantType: applicantTypeToUse
    });

    wrappers.forEach(w =>
      w.docDetList.forEach(dd => {
        this._appDetailMap.set(dd.Document_Master__c, dd.Id);
      })
    );

    const tempList = wrappers.map(w => {
      const existing = new Set(w.docDetList.map(dd => dd.Document_Master__c));
      const requiredMap = new Map(w.docDetList.map(dd => [dd.Document_Master__c, dd.Is_Required__c]));
      return {
        docType: w.docType,
        docList: w.docList.map(dm => ({
          Id: dm.Id,
          Name: dm.Name,
          identity: dm.Form_Common_Identifier__c,
          checked: existing.has(dm.Id),
          isDisabled: requiredMap.get(dm.Id)
        }))
      };
    });

    const masterIdsForModal = tempList.flatMap(s => s.docList.map(d => d.Id));
    const loanSections = await getDocumentChecklistRecords({
      recId: this.recordId,
      processObject: this.processObject || 'Loan Application',
      masterIds: masterIdsForModal
    });

    wrappers.forEach(w =>
      w.docDetList.forEach(dd =>
        this._appDetailMap.set(dd.Document_Master__c, dd.Id)
      )
    );

    loanSections
      .flatMap(sec => sec.docDetails)
      .filter(dd =>
        !dd.applicantId
        || dd.applicantId === applicantIdToUse
      )
      .forEach(dd => {
        this._appDetailMap.set(dd.masterId, dd.id);
      });

    const consideredMasterIds = new Set(
      (wrappers || []).flatMap(w => w.docDetList || []).map(dd => dd.Document_Master__c)
    );

    this.docCheckList = tempList.map(section => ({
      docType: section.docType,
      docList: section.docList.map(doc => ({
        ...doc,
        checked: consideredMasterIds.has(doc.Id)
      }))
    }));

    if (this.isFormSixty === false) {
      console.log('Filtering out Form 60 since not uploaded');
      this.docCheckList = this.docCheckList.map(section => ({
        ...section,
        docList: section.docList.filter(dm => dm.Name !== 'Form 60')
      }));
    } else if (this.isFormSixty === true) {
      console.log('Filtering out PAN since Form 60 is uploaded');
      this.docCheckList = this.docCheckList.map(section => ({
        ...section,
        docList: section.docList.filter(dm => dm.Name !== 'PAN')
      }));
    }

    this.docCheckList.forEach(sec => {
      sec.docList.forEach(doc => {
        const detailId = this._appDetailMap.get(doc.Id);
        if (doc.checked && !detailId) {
          if (!this.modalMasterIds.includes(doc.Id)) {
            this.modalMasterIds.push(doc.Id);
          }
        } else if (!doc.checked && detailId) {
          if (!this.modalMasterDeletes.includes(doc.Id)) {
            this.modalMasterDeletes.push(doc.Id);
          }
        }
      });
    });

    this.docCheckList.forEach(sec =>
      sec.docList.forEach(doc =>
        this._masterMap.set(doc.Id, {
          name: doc.Name,
          category: sec.docType,
          isRequired: doc.isDisabled
        })
      )
    );

  } catch (e) {
    console.error('getRelatedDocumentCategory error', e);
  } finally {
    this.isSpinnerLoading = false;
    console.log('docCheckList →', this.docCheckList);
    console.log('will CREATE →', this.modalMasterIds);
    console.log('will DELETE →', this.modalMasterDeletes);
  }
}


  docSelectHandler(event) {
    const masterId = event.currentTarget?.dataset?.id;
    const checked = event.currentTarget.checked;
    if (!masterId) return;
    const allDocs = this.docCheckList.flatMap(s => s.docList);
    const clicked = allDocs.find(d => d.Id === masterId);
    const group = clicked?.identity
      ? allDocs.filter(d => d.identity === clicked.identity)
      : [clicked].filter(Boolean);

    group.forEach(doc => {
      const detailIdExists = this._appDetailMap.has(doc.Id);

      if (checked) {
        if (!this.modalMasterIds.includes(doc.Id)) this.modalMasterIds.push(doc.Id);
        this.modalMasterDeletes = this.modalMasterDeletes.filter(m => m !== doc.Id);
      } else {
        if (detailIdExists && !this.modalMasterDeletes.includes(doc.Id)) {
          this.modalMasterDeletes.push(doc.Id);
        }
        this.modalMasterIds = this.modalMasterIds.filter(m => m !== doc.Id);
      }
    });
    this.docCheckList = this.docCheckList.map(section => ({
      docType: section.docType,
      docList: section.docList.map(doc => ({
        ...doc,
        checked: group.some(g => g.Id === doc.Id) ? checked : doc.checked
      }))
    }));

    console.log('to CREATE (masters) →', [...new Set(this.modalMasterIds)]);
    console.log('to UNCONSIDER (masters) →', [...new Set(this.modalMasterDeletes)]);
  }

  async addDocHandler() {
    if (!this.modalMasterIds.length && !this.modalMasterDeletes.length) {
      return this.showToast('Warning', 'Select at least one document', 'warning');
    }
    this.isSpinnerLoading = true;
    const applicantIdToUse = this.selectedApplicantId || this.appId;

    try {
      await createChecklistRecord({
        docMasterIds: this.modalMasterIds,
        recordId: this.recordId,
        applicantId: applicantIdToUse,
        docIds: this.modalMasterDeletes
      });

      // clear and refresh
      this.modalMasterIds = [];
      this.modalMasterDeletes = [];
      await this.refreshAllData(applicantIdToUse);
      this.modalVisibility = false;

    } catch (error) {
      console.error('addDocHandler error:', error);
      this.showToast('Error', 'Could not update documents', 'error');
    } finally {
      this.isSpinnerLoading = false;
    }
  }

  formatDocumentsForTable(selectedDocs) {
    const documentsByCategory = {};

    // Group documents by category
    selectedDocs.forEach(doc => {
      const category = doc.docCategory;
      if (!documentsByCategory[category]) {
        documentsByCategory[category] = {
          documentCategoryName: category,
          docDetails: []
        };
      }

      documentsByCategory[category].docDetails.push({
        id: doc.id,
        name: doc.name,
        contentId: doc.contentId,
        isRequired: doc.isRequired,
        showUpload: true,
        showView: false,
        showDelete: true,
        showRetake: true,
        showLocation: false,
        lattitude: null,
        longitude: null,
        category: doc.category,
        docName: doc.docName,
        docCategory: doc.docCategory,
        custName: doc.custName || 'Primary Applicant',
        applicantId: doc.applicantId,
        customerType: doc.customerType || 'Primary Applicant',
        reqLevel: doc.reqLevel || 'Applicant Level',
        selected: false,
        disabledChk: false,
        fileType: doc.fileType || '',
        Uploadedby: doc.Uploadedby || doc.uploadedBy || '',
        Timestamp: doc.Timestamp || new Date().toLocaleDateString('en-GB', {
          day: '2-digit',
          month: '2-digit',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit',
          hour12: true
        }),
        password: '',
        docURI: '',
        documentStatus: false,
        docIdNumber: ''
      });
    });

    // Convert to array format expected by documentDetailsScreen
    return Object.values(documentsByCategory);
  }


  async handleDocumentTableUpdated(event) {
    console.log('Document table updated:', event.detail);

    // Refresh the main document list if needed
    await this.refreshAllData();

    // Optionally hide the table after successful upload
    const { action } = event.detail;
    if (action === 'uploaded') {
      // You can choose to hide the table or keep it visible
      // this.showDocumentTable = false;
    }
  }

  hideDocumentTable() {
    this.showDocumentTable = false;
    this.selectedDocumentsForTable = [];
  }
}