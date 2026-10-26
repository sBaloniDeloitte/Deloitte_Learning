@IsTest
public class HL_SalarySlipWrapperTest {

    @IsTest
    static void testSalarySlipCalculations() {

        HL_SalarySlipWrapper.MonthlyValueWrapper janEarning = 
            new HL_SalarySlipWrapper.MonthlyValueWrapper();
        janEarning.strMonthLabel = 'Jan';
        janEarning.strMonthValue = 10000;

        HL_SalarySlipWrapper.MonthlyValueWrapper febEarning = 
            new HL_SalarySlipWrapper.MonthlyValueWrapper();
        febEarning.strMonthLabel = 'Feb';
        febEarning.strMonthValue = 12000;

        HL_SalarySlipWrapper.MonthlyValueWrapper janDeduction = 
            new HL_SalarySlipWrapper.MonthlyValueWrapper();
        janDeduction.strMonthLabel = 'Jan';
        janDeduction.strMonthValue = 2000;

        HL_SalarySlipWrapper.MonthlyValueWrapper febDeduction = 
            new HL_SalarySlipWrapper.MonthlyValueWrapper();
        febDeduction.strMonthLabel = 'Feb';
        febDeduction.strMonthValue = 2500;

        // -----------------------------
        // Earnings Component
        // -----------------------------
        HL_SalarySlipWrapper.SalarySlipComponentWrapper earningComp =
            new HL_SalarySlipWrapper.SalarySlipComponentWrapper();
        earningComp.strNatureOfComponent = 'Earning';
        earningComp.lstAmtWrapper = new List<HL_SalarySlipWrapper.MonthlyValueWrapper>{
            janEarning, febEarning
        };

        // -----------------------------
        // Deduction Component
        // -----------------------------
        HL_SalarySlipWrapper.SalarySlipComponentWrapper deductionComp =
            new HL_SalarySlipWrapper.SalarySlipComponentWrapper();
        deductionComp.strNatureOfComponent = 'Deduction';
        deductionComp.lstAmtWrapper = new List<HL_SalarySlipWrapper.MonthlyValueWrapper>{
            janDeduction, febDeduction
        };

        // -----------------------------
        // Main Wrapper
        // -----------------------------
        HL_SalarySlipWrapper wrapper = new HL_SalarySlipWrapper();
        wrapper.lstEarningsWrapper = new List<HL_SalarySlipWrapper.SalarySlipComponentWrapper>{
            earningComp
        };
        wrapper.lstDeductionsWrapper = new List<HL_SalarySlipWrapper.SalarySlipComponentWrapper>{
            deductionComp
        };

        // -----------------------------
        // Assertions
        // -----------------------------

        // Month labels
        System.assertEquals(2, wrapper.lstMonthLabels.size(), 'Month labels count mismatch');

        // Month count
        System.assertEquals(2, wrapper.intMonthsCount, 'Month count incorrect');

        // Col span count
        System.assertEquals(2, wrapper.intMonthsColSpanCount, 'Colspan count incorrect');

        // Earnings total
        List<Decimal> totalEarnings = wrapper.lstTotalAmount;
    
      
        // Deductions total
        List<Decimal> totalDeductions = wrapper.lstTotalAmountLess;
    
        // Net Salary
        List<Decimal> netSalary = wrapper.netSalary;
  
    }

    @IsTest
    static void testEmptyDataScenario() {

        HL_SalarySlipWrapper wrapper = new HL_SalarySlipWrapper();
        wrapper.lstEarningsWrapper = new List<HL_SalarySlipWrapper.SalarySlipComponentWrapper>();
        wrapper.lstDeductionsWrapper = new List<HL_SalarySlipWrapper.SalarySlipComponentWrapper>();

       
    }
}