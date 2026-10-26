import { LightningElement } from 'lwc';

export default class PrintPage extends LightningElement {
    renderedCallback() {
        const container = this.template.querySelector('.print-container');
        const content = sessionStorage.getItem('printContent');
        console.log('content ',content);
        if (content && container) {
 const decoded = decodeURIComponent(escape(atob(content)));
        container.innerHTML = decoded;

        }
    }
}