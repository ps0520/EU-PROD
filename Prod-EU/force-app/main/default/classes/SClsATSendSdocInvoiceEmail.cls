/*****************************************************************************************
@Description    : Scheduler class for AT Email Invoice Automation
****************************************************************************************/
global class SClsATSendSdocInvoiceEmail implements Schedulable {
    global void execute(SchedulableContext SC) {
        BClsSendSdocInvoiceEmailAT sch = new BClsSendSdocInvoiceEmailAT('AT');
        Database.executebatch(sch, 1);
    }
}