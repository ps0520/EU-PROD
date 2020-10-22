/*****************************************************************************************
@Description    : Scheduler class for IE Email Invoice Automation
****************************************************************************************/
global class SClsIESendSdocInvoiceEmail implements Schedulable {
    global void execute(SchedulableContext SC) {
        BClsSendSdocInvoiceEmail sch = new BClsSendSdocInvoiceEmail('IE');
        Database.executebatch(sch, 1);
    }
}