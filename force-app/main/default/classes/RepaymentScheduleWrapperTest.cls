@IsTest
public class RepaymentScheduleWrapperTest {

    @IsTest
    static void testFullCoverage() {
        // ---- Fee ----
        RepaymentScheduleWrapper.Fee fee = new RepaymentScheduleWrapper.Fee();
        fee.feeCategory = 'Processing';
        fee.feeCode = 'PROC001';
        fee.feeAmount = 500.00;
        fee.waiverAmount = 0;
        fee.paidAmount = 500.00;
        fee.feeMethod = 'Flat';
        fee.scheduleTerms = 12;
        fee.feeBalance = 0;
        fee.version = 1;
        fee.finFeeReceipts = new List<Object>{'Receipt1'};

        // ---- Schedule ----
        RepaymentScheduleWrapper.Schedule schedule = new RepaymentScheduleWrapper.Schedule();
        schedule.schDate = '2025-10-16';
        schedule.pftAmount = 150.50;
        schedule.schdPft = 200;
        schedule.schdPftPaid = 100;
        schedule.schdPri = 5000;
        schedule.schdPriPaid = 1000;
        schedule.feeSchd = 100;
        schedule.tDSAmount = 50;
        schedule.totalAmount = 5250.50;
        schedule.endBal = 9000;
        schedule.limitDrop = 200;
        schedule.dropLineLimit = 50000;
        schedule.availableLimit = 48000;
        schedule.dueDate = '2025-11-15';
        schedule.version = 1;
        schedule.instNumber = 1;
        schedule.bpiAmount = 50;
        schedule.specifier = 'Monthly';

        // ---- Step ----
        RepaymentScheduleWrapper.Step step = new RepaymentScheduleWrapper.Step();
        step.stepNumber = 1;
        step.tenorSplitPerc = 50;
        step.emiSplitPerc = 50;
        step.installments = 12;
        step.steppedEMI = 10000;
        step.stepSpecifier = 'Step1';
        step.autoCal = true;
        step.version = 1;

        // ---- ReturnStatus ----
        RepaymentScheduleWrapper.ReturnStatus status = new RepaymentScheduleWrapper.ReturnStatus();
        status.returnCode = '200';
        status.returnText = 'Success';

        // ---- Summary ----
        RepaymentScheduleWrapper.Summary summary = new RepaymentScheduleWrapper.Summary();
        summary.effectiveRateOfReturn = 9.5;
        summary.totalGracePft = 100;
        summary.totalGraceCpz = 50;
        summary.totalGrossGrcPft = 150;
        summary.totalCpz = 80;
        summary.totalProfit = 1200;
        summary.totalRepayAmt = 12000;
        summary.feeChargeAmount = 100;
        summary.numberOfTerms = 12;
        summary.loanTenor = 12;
        summary.maturityDate = '2026-10-16';
        summary.firstEmiAmount = 1000;
        summary.nextSchDate = '2025-11-01';
        summary.nextRepayAmount = 1000;
        summary.futureInst = 5;
        summary.futureTenor = 5;
        summary.firstInstDate = '2025-10-01';
        summary.paidTotal = 2000;
        summary.paidPri = 1500;
        summary.paidPft = 500;
        summary.lastRepayDate = '2025-09-15';
        summary.outstandingTotal = 8000;
        summary.outstandingPri = 7000;
        summary.outstandingPft = 1000;
        summary.overdueTotal = 100;
        summary.overduePri = 50;
        summary.overduePft = 50;
        summary.overdueInst = 1;
        summary.overDueCharges1 = 10;
        summary.overdueTotalIncludeCharges = 110;
        summary.overdueCharges = new List<Object>{'Charge1'};
        summary.advPaymentAmount = 200;
        summary.finActiveStatus = 'Active';
        summary.fullyDisb = true;
        summary.limitBalance = 25000;
        summary.billedAmount = 500;
        summary.unbilledAmount = 100;
        summary.DPDDays = 5;
        summary.dueDate = '2025-10-20';
        summary.dueAmount = 1000;
        summary.limitDrop = 200;
        summary.currentDroplineLimit = 100000;
        summary.utilisation = 70;
        summary.availableLimit = 30000;
        summary.graceInst = 1;
        summary.graceTenor = 1;
        summary.futureGraceInst = 0;
        summary.futureGraceTenor = 0;
        summary.totalRevisedTenure = 12;
        summary.revisedLastStepTerms = 12;

        // ---- Wrapper ----
        RepaymentScheduleWrapper wrapper = new RepaymentScheduleWrapper();
        wrapper.finReference = 'FIN12345';
        wrapper.fees = new List<RepaymentScheduleWrapper.Fee>{fee};
        wrapper.schedules = new List<RepaymentScheduleWrapper.Schedule>{schedule};
        wrapper.step = new List<RepaymentScheduleWrapper.Step>{step};
        wrapper.returnStatus = status;
        wrapper.summary = summary;
        wrapper.isUpfrontAuto = true;
        wrapper.outstandingPri = 8000;
        wrapper.version = 1;
        wrapper.excessAmount = 100;
        wrapper.vas = new List<Object>{'VAS1'};
        wrapper.feeDues = new List<Object>{'FeeDue1'};
        wrapper.insurance = new List<Object>{'Insurance1'};
        wrapper.planEMIHmonths = new List<Object>{'EMIHM1'};
        wrapper.planEMIHDates = new List<Object>{'EMIHD1'};
        wrapper.planPRIHDates = new List<Object>{'PRIH1'};
        wrapper.planPRIHMonths = new List<Object>{'PRIHMonth1'};
        wrapper.overdueCharges = new List<Object>{'OverdueCharge1'};
        wrapper.intervalFee = new List<Object>{'IntervalFee1'};
        wrapper.disbursements = new List<Object>{'Disb1'};

        // ---- Assertions ----
        System.assertEquals('FIN12345', wrapper.finReference);
        System.assertEquals('Processing', wrapper.fees[0].feeCategory);
        System.assertEquals('Monthly', wrapper.schedules[0].specifier);
        System.assertEquals('200', wrapper.returnStatus.returnCode);
        System.assertEquals(true, wrapper.isUpfrontAuto);
        System.assertEquals(1, wrapper.step.size());
        System.assertEquals(30000, wrapper.summary.availableLimit);
        System.assertEquals(1, wrapper.version);
        System.assertEquals('Success', wrapper.returnStatus.returnText);
        System.assertNotEquals(null, wrapper.fees);
    }
}