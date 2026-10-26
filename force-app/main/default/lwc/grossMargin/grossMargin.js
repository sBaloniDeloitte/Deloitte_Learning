import { LightningElement, api } from 'lwc';

export default class GrossMargin extends LightningElement {

  @api
  details = {
    months: [{ id: 'm1', label: 'Jan 2025' }],

    revenue: {
      netSales: [0],
      otherIncome: [0]
    },

    cogs: {
      openingStock: [0],
      purchases: [0],
      directExpenses: [0],
      closingStock: [0]
    },

    isMonthModalOpen: false,
    monthDraft: ''
  };

  /* ================= MONTH HANDLING ================= */

  openMonthModal = () => {
    this.details.isMonthModalOpen = true;
    this.refresh();
  };

  closeMonthModal = () => {
    this.details.isMonthModalOpen = false;
    this.refresh();
  };

  handleMonthDraftChange = (e) => {
    this.details.monthDraft = e.target.value;
  };

  confirmAddMonth = () => {
    const label = this.details.monthDraft || `Month ${this.details.months.length + 1}`;

    this.details.months.push({
      id: `m_${Date.now()}`,
      label
    });

    Object.values(this.details.revenue).forEach(arr => arr.push(0));
    Object.values(this.details.cogs).forEach(arr => arr.push(0));

    this.details.monthDraft = '';
    this.details.isMonthModalOpen = false;
    this.refresh();
  };

  handleMonthLabelChange = (e) => {
    const idx = Number(e.target.dataset.index);
    this.details.months[idx].label = e.target.value;
    this.refresh();
  };

  /* ================= VALUE CHANGE ================= */

  handleValueChange = (e) => {
    const { section, field, index } = e.target.dataset;
    this.details[section][field][index] = Number(e.target.value) || 0;
    this.refresh();
  };

  refresh() {
    this.details = JSON.parse(JSON.stringify(this.details));
    this.dispatchEvent(new CustomEvent('update', { detail: this.details }));
  }

  /* ================= CALCULATIONS ================= */

  avg(arr) {
    if (!arr.length) return 0;
    return Math.round(arr.reduce((a, b) => a + b, 0) / arr.length);
  }

  get revenuePerMonth() {
    return this.details.revenue.netSales.map(
      (v, i) => v + this.details.revenue.otherIncome[i]
    );
  }

  get cogsPerMonth() {
    const c = this.details.cogs;
    return c.openingStock.map(
      (v, i) => v + c.purchases[i] + c.directExpenses[i] - c.closingStock[i]
    );
  }

  get grossProfitPerMonth() {
    return this.revenuePerMonth.map(
      (r, i) => r - this.cogsPerMonth[i]
    );
  }

  get grossMarginPerMonth() {
    return this.details.revenue.netSales.map((r, i) =>
      r > 0 ? Math.round((this.grossProfitPerMonth[i] / r) * 100) : 0
    );
  }

  /* ================= AVERAGES ================= */

  get avgNetSales() {
    return this.avg(this.details.revenue.netSales);
  }

  get avgOtherIncome() {
    return this.avg(this.details.revenue.otherIncome);
  }

  get avgGrossProfit() {
    return this.avg(this.grossProfitPerMonth);
  }

  get avgGrossMargin() {
    return this.avg(this.grossMarginPerMonth);
  }

  /* ================= VIEW MODELS ================= */

  get cogsRows() {
    const c = this.details.cogs;
    return [
      { key: 'os', label: 'Opening Stock', field: 'openingStock', values: c.openingStock, avg: this.avg(c.openingStock) },
      { key: 'p',  label: 'Purchases', field: 'purchases', values: c.purchases, avg: this.avg(c.purchases) },
      { key: 'de', label: 'Direct Expenses', field: 'directExpenses', values: c.directExpenses, avg: this.avg(c.directExpenses) },
      { key: 'cs', label: 'Closing Stock (Less)', field: 'closingStock', values: c.closingStock, avg: this.avg(c.closingStock) }
    ];
  }

  get grossMarginView() {
    return this.grossMarginPerMonth.map(v => {
      let cssClass = 'success';
      if (v < 10) cssClass = 'danger';
      else if (v < 20) cssClass = 'warning';
      return { value: v, cssClass };
    });
  }

  get avgGrossMarginView() {
    const v = this.avgGrossMargin;
    let cssClass = 'success';
    if (v < 10) cssClass = 'danger';
    else if (v < 20) cssClass = 'warning';
    return { value: v, cssClass };
  }
}