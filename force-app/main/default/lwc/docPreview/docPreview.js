import { LightningElement, api } from 'lwc';
export default class DocPreview extends LightningElement {
  @api isImage;
  @api isPdf;
  @api imageUrl;
  @api pdfUrl;
}