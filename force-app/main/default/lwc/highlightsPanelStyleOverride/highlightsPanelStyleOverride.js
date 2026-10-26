/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
import { LightningElement } from 'lwc';

/**
 * Style-only component. Renders no visible markup of its own — its single
 * responsibility is to inject a global <style> override (via renderedCallback)
 * that recolors the standard record-home Highlights Panel and a few other
 * shared SLDS elements on the page. The raw <style> tag is appended outside
 * LWC's scoped-CSS pipeline so its rules can reach standard/base Salesforce
 * markup that this component does not itself render (e.g. the Highlights
 * Panel), matching the technique already used in loanProductDetails.js.
 */
export default class HighlightsPanelStyleOverride extends LightningElement {
    isRendered = false;

    renderedCallback() {
        if (this.isRendered) {
            return;
        }
        this.isRendered = true;

        const style = document.createElement('style');
        style.innerText = `
            /* Highlights Panel — outer wrapper plus the nested SLDS structural
               containers that each carry their own default background, so the
               dark-blue fill covers the panel entirely instead of just the
               outer <div>. */
            .highlights.slds-clearfix.slds-page-header.slds-page-header_record-home.fixed-position,
            .slds-page-header_record-home,
            .slds-page-header_record-home .slds-page-header__row,
            .slds-page-header_record-home .slds-page-header__col-title,
            .slds-page-header_record-home .slds-page-header__col-details,
            .slds-page-header_record-home .slds-page-header__col-actions,
            .slds-page-header_record-home .slds-page-header__name-meta,
            .slds-page-header_record-home .slds-media,
            .slds-page-header_record-home .slds-media__figure,
            .slds-page-header_record-home .slds-media__body,
            .slds-page-header_record-home .slds-page-header__detail-row,
            .slds-page-header_record-home slot.slds-grid.slds-page-header__detail-row {
                background: linear-gradient(135deg, #001a5e 0%, #003087 55%, #004db3 100%) !important;
                color: #ffffff;
            }

            .slds-page-header_record-home .slds-page-header__detail-row *,
            .slds-page-header_record-home slot.slds-grid.slds-page-header__detail-row * {
                background: transparent !important;
                color: #ffffff !important;
            }
         

            .highlights.slds-clearfix.slds-page-header.slds-page-header_record-home.fixed-position {
                border-radius: 24px 25px 0px 0px !important;
            }

            .entityNameTitle.slds-line-height--reset,
            .slds-page-header__title,
            .slds-page-header__name-title,
            .slds-page-header__meta-text {
                color: #ffffff !important;
            }

            .actionsContainer .slds-button-group-list button,
            .actionsContainer button {
                background-color: #1467EB !important;
                border-color: #1467EB !important;
                color: #ffffff !important;
                font-size: 15px;
                font-weight: 600;
                border-radius: 4px !important;
                padding: 0 1rem !important;
                min-width: auto;
                height: 2rem;
                line-height: 2rem;
            }

            .actionsContainer .slds-button-group-list button:hover:not(:disabled),
            .actionsContainer button:hover:not(:disabled) {
                background: #1467EB !important;
                transform: translateY(-1px);
                box-shadow: 0 6px 18px rgba(76, 175, 80, 0.45);
            }

            lightning-card .slds-card .slds-card__header {
                padding: 0;
                margin: 0;
            }
            lightning-card .slds-card__body {
                margin: 0;
            }

            .uploadFile .slds-file-selector__text.slds-medium-show {
                display: none;
            }
            .uploadFile .slds-file-selector__button.slds-button.slds-button_neutral {
                font-size: 0 !important;
            }
            .uploadFile svg.slds-button__icon.slds-button__icon_left {
                margin: 0;
            }
            .uploadFile lightning-primitive-file-droppable-zone.slds-file-selector__dropzone {
                border: none;
            }
            .uploadFile .slds-form-element__label {
                display: none;
            }
            .uploadFile .slds-form-element__control {
                margin-left: 20%;
            }

            .info-button svg.slds-button__icon.slds-button__icon_left {
                margin: 0;
            }
            .uploaded-view svg.slds-button__icon {
                color: green;
            }

            .slds-form-element__label {
                color: #ffffff;
            }
            .slds-input_faux,
            .slds-input,
            .slds-input[disabled] {
                background-color: #16283f;
                color: #ffffff;
            }

            .navClass .slds-progress-bar__value,
            .instruction-box-nav.slds-progress-bar__value {
                background: skyblue;
            }

            .container .slds-accordion__summary-action {
                background: linear-gradient(135deg, #001a5e 0%, #003087 55%, #004db3 100%);
                color: #ffffff !important;
                border-radius: 10px !important;
            }
            .slds-accordion__summary-heading {
                color: #ffffff;
            }
            .slds-accordion__list-item {
                border: none !important;
                background-color: #0e1c30;
            }

            .slds-card{
                background-color: #0e1c30;
            } 

            button.save-button.slds-button.slds-button_brand.slds-float_left {
                background-color: #1467eb !important;
                border-color: #d3d3d3 !important;
                color: #ffffff !important;
            }
            .slds-tabs_card, .slds-tabs_card.slds-tabs_card {
                background: #0e1c30;
            }
            .slds-tabs_default__link, .slds-tabs--default__link {
                color: #ffffff;
            }  

             /* Active tab text color */
            .slds-tabs_default__item.slds-is-active .slds-tabs_default__link,
            .slds-tabs--default__item.slds-is-active .slds-tabs--default__link {
                color: #ffffff !important;
            }

            /* Active tab indicator */
            .slds-tabs_default__item.slds-is-active:after,
            .slds-tabs--default__item.slds-is-active:after {
                background-color: #ffffff !important;
            }

            /* More dropdown menu */
            .slds-dropdown {
                background: #0e1c30 !important;
                border: 1px solid #294061 !important;
            }

            /* Menu items */
            .slds-dropdown__item > a,
            .slds-dropdown__item > span,
            .slds-dropdown a {
                color: #ffffff !important;
                background: #0e1c30 !important;
            }

            /* Hover / Focus */
            .slds-dropdown__item:hover,
            .slds-dropdown__item.slds-has-focus,
            .slds-dropdown__item:hover > a,
            .slds-dropdown__item.slds-has-focus > a {
                /*background: #1467eb !important;*/
                color: #ffffff !important;
            }

            /* Selected item */
            .slds-dropdown__item.slds-is-selected > a {
                color: #ffffff !important;
                /*background: #1467eb !important;*/
            }

            /* "More" tab link */
            .slds-tabs_default__nav .slds-dropdown-trigger_click > a,
            .slds-tabs_default__nav .slds-dropdown-trigger > a {
                color: #ffffff !important;
            }


            .simpleRecordHomeTemplate .region-header .flexipageComponent:not(:empty),
            .forceStyle.desktop .simpleRecordHomeTemplate .region-header flexipage-component2:not(:empty) {
                margin-bottom: 0px;
                background: linear-gradient(135deg, #001a5e 0%, #003087 55%, #004db3 100%) !important;
            }
        `;

        const container = this.template.querySelector('.styleContainer');
        if (container) {
            container.appendChild(style);
        }
    }
}
/*__________________________GenAI: Generated code ends here______________________________*/