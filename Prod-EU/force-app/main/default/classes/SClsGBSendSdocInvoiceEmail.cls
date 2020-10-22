/*****************************************************************************************
@Description    : Scheduler class for GB Email Invoice Automation
****************************************************************************************/
global class SClsGBSendSdocInvoiceEmail implements Schedulable {
    global void execute(SchedulableContext SC) {
        BClsSendSdocInvoiceEmail sch = new BClsSendSdocInvoiceEmail('GB');
        Database.executebatch(sch, 1);
    }
}