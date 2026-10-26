import { LightningElement, api, wire, track } from 'lwc';
import getCollateralValuations from '@salesforce/apex/Comm_LoanCollateralValuationController.getCollateralValuations';
import updateCollateralValuations from '@salesforce/apex/Comm_LoanCollateralValuationController.updateCollateralValuations';

export default class CreditTechnicalValuationCmp extends LightningElement {
@api recordId;
@api disabledCmp = false;
@track collateralData = [];
@track valuationMatrix = [];
@track showSuccess = false;
overallTotalValuation;
@track hasCollateralData = false;
grandTotal;


/*
@wire(getCollateralValuations, { loanAppId: '$recordId' })
    wiredData({ data, error }) {
        
        if (data) {
          
            console.log('collateral data', JSON.stringify(data));
            
            this.grandTotal = data[0].totalValueLoanApp;
            // Filter out items with empty valuations array
            const filteredData = data
            .filter(coll => coll.valuations && coll.valuations.length > 0)
            .map(coll => {
            const valuationsWithTag = coll.valuations.map((v, index) => ({
            ...v,
            label: `Technical Valuation ${index + 1}`
            }));

            // Identify lowest value
            const minVal = Math.min(...valuationsWithTag.map(v => v.value || 0));
            valuationsWithTag.forEach(v => {
            v.isLowest = v.value === minVal;
            });

            return {
            ...coll,
            valuations:valuationsWithTag     
            };
            });
              
            console.log('filtered data>'+JSON.stringify(filteredData));
           if (filteredData.length > 0) {
         
            this.collateralData = filteredData;
          

             console.log('collateral data in wire>'+JSON.stringify(this.collateralData));
            this.hasCollateralData = this.collateralData && this.collateralData.length > 0;
             
           }else {
            
         this.collateralData = [];
         this.hasCollateralData = false;
        }  
            this.constructValuationMatrix();    
        
        }  else {
            console.error('Error ', error);
           
           
        }
        
        
    } */
     
    

    

get grandTotalFormatted() {
    return new Intl.NumberFormat('en-IN').format(this.grandTotal || 0);
}
computeGrandTotal() {
    // add only if estimate has a value; totalValuation = lowest + estimate
    this.grandTotal = this.collateralData.reduce((sum, c) => {
        const hasEstimate =
        c?.estimate !== null &&
        c?.estimate !== undefined &&
        c?.estimate !== '' &&
        !isNaN(parseFloat(c.estimate));
        return hasEstimate ? sum + (parseFloat(c.totalValuation) || 0) : sum;
    }, 0);
}
/*handleEstimateBlur(event) {
    try {
    const value = parseFloat(event.target.value) || 0;
    const id = event.target.dataset.id;

    const index = this.collateralData.findIndex(c => c.collateralId === id);
    if (index === -1) return;

    const coll = this.collateralData[index];
    coll.estimate = value;

    // lowest across this collateral’s valuations
    const lowest = Math.min(...(coll.valuations || []).map(v => parseFloat(v.value) || 0));
    coll.totalValuation = lowest + (parseFloat(coll.estimate) || 0);

    // recompute grand total (all collaterals)
    this.computeGrandTotal();

    // (optional) keep your Apex update for the collateral itself
    updateCollateralValuations({
    collateralId: id,
    estimate: coll.estimate,
    totalValuation: coll.totalValuation
    })
    .then(() => {
    console.log('Updated successfully');
    })
    .catch(err => console.error('Error updating collateral:', err));
    } catch (e) {
    console.error(e);
    }
}*/

// wherever you initially load collateralData, call:
// this.computeGrandTotal();




constructValuationMatrix() {
    const rows = [];

    const maxValuations = Math.max(
    ...this.collateralData.map(coll => (coll.valuations || []).length)
    );

    // Valuation rows (Technical Valuation 1...n)
    for (let i = 0; i < maxValuations; i++) {
    const row = {
        type: 'valuation',
        values: this.collateralData.map(coll => {
        const val = coll.valuations[i];
        return {
        label: val ? val.label : '',
        value: val ? val.value : '',
        isLowest: val ? val.isLowest : false,
        isInput: false,
        isTotal : false,
        collateralId: coll.collateralId
        };
    })
    };
    rows.push(row);
    }

    // Construction Estimate row
    rows.push({
        type: 'construction',
        values: this.collateralData.map(coll => ({
        label: 'Construction / R&R Estimate',
        value: coll.estimate || '',
        isLowest: false,
        isInput: true,
        isTotal : false,
        collateralId: coll.collateralId
    }))
    });

    // Total Valuation row
    /*rows.push({
        type: 'total',
        values: this.collateralData.map(coll => ({
        label: 'Total Valuation',
        value: coll.totalValue || '',
        isLowest: false,
        isInput: false,
        isTotal : true,
        collateralId: coll.collateralId
        }))
    });*/

    this.valuationMatrix = rows;
    console.log(
    'valuation matrix',
    JSON.stringify(this.valuationMatrix));
}

/*handleEstimateBlur(event) {
        //const id = event.target.dataset.id;
        console.log('inside estimate blur');
        try{
        const value = parseFloat(event.target.value) || 0;
        const id = event.target.dataset.id;
        const coll = this.collateralData.find(c => c.collateralId === id);
         
    const index = this.collateralData.findIndex(c => c.collateralId === id);
    if (index !== -1) {
    const estimate = parseFloat(event.target.value) || 0;
    
    const lowest = Math.min(...this.collateralData[index].valuations.map(v => v.value || 0));
    const total = estimate + lowest;
        if (coll) {
        coll.estimate = value;

        const minVal = Math.min(...(coll.valuations || []).map(v => v.value || 0));
        coll.totalValuation = minVal + value;
        }
         updateCollateralValuations({
            collateralId: id,
            estimate: estimate,
            totalValuation: total
            })
            .then(() => {
            console.log('Updated successfully');
            })
            .catch(error => {
            console.error('Error updating collateral:', error);
            });
        }
        this.constructValuationMatrix();
    }
    catch(error) {
        console.log(error);
    }
    }*/
handleEstimateBlur(event) {
    try {
        const value = parseFloat(event.target.value) || 0;
        const id = event.target.dataset.id;

        const index = this.collateralData.findIndex(c => c.collateralId === id);
        if (index === -1) return;

        // Update the estimate for this collateral
        let coll = this.collateralData[index];
        coll.estimate = value;

        // Find the lowest valuation for this collateral
        const lowest = Math.min(...(coll.valuations.map(v => v.value || 0)));
        coll.totalValue = lowest + coll.estimate;
        console.log('collateral estimate: '+coll.estimate+' lowest: '+lowest+' total: '+coll.totalValue);
        // ✅ Calculate total valuation across all collaterals
        console.log('collateral data in handle blur>'+JSON.stringify(this.collateralData));
        this.grandTotal = this.collateralData.reduce((sum, c) => {
        if (c.estimate || c.estimate == 0) { // only add if estimate has a value
            console.log('inside estimate>'+c.estimate);
            return sum + (c.totalValue || 0);
        }
        return sum;
        }, 0);
        console.log(
        'Grand total valuation:',
        this.grandTotal);
        // Call Apex to update (if needed)
        updateCollateralValuations({
        collateralId: id,
        estimate: coll.estimate,
        loanId : this.recordId,
        grandTotal: this.grandTotal
        })
        .then(() => {
        console.log('Updated successfully');
       // console.log('Grand Total Valuation:', grandTotal); // You can pass this to parent
        })
        .catch(error => {
        console.error('Error updating collateral:', error);
        });

    } catch (error) {
    console.error(error);
    }
}



handleSave() {
    updateCollateralValuations({ wrapperList: this.collateralData })
    .then(() => {
    this.showSuccess = true;
    setTimeout(() => this.showSuccess = false, 3000);
    })
    .catch(error => {
    console.error('Save error', error);
    });
    }

    connectedCallback() {
        this.getData();
    }

    getData() {
        getCollateralValuations({ loanAppId: this.recordId })
            .then(result => {
                console.log('collateral data', JSON.stringify(result));
                this.grandTotal = result[0].totalValueLoanApp;
                // Filter out items with empty valuations array
                const filteredData = result
                    .filter(coll => coll.valuations && coll.valuations.length > 0)
                    .map(coll => {
                        const valuationsWithTag = coll.valuations.map((v, index) => ({
                            ...v,
                            label: `Technical Valuation ${index + 1}`
                        }));

                        // Identify lowest value
                        const minVal = Math.min(...valuationsWithTag.map(v => v.value || 0));
                        valuationsWithTag.forEach(v => {
                            v.isLowest = v.value === minVal;
                        });
                        return {
                            ...coll,
                            valuations:valuationsWithTag     
                        };
                    });
                console.log('filtered data>' + JSON.stringify(filteredData));
                if (filteredData.length > 0) {
                    this.collateralData = filteredData;
                    console.log('collateral data in wire>' + JSON.stringify(this.collateralData));
                    this.hasCollateralData = this.collateralData && this.collateralData.length > 0;

                } else {
                    this.collateralData = [];
                    this.hasCollateralData = false;
                }
                this.constructValuationMatrix();
            })
            .catch(error => {
                console.error('Error:', error);
            });
    }

}