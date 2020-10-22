/*****************************************************************************************
@Description    : Scheduler class for SI Email Invoice Automation
****************************************************************************************/
global class SClsSISendSdocInvoiceEmail implements Schedulable {
    global void execute(SchedulableContext SC) {
      //  BClsSendSdocInvoiceEmailSI sch = new BClsSendSdocInvoiceEmailSI('SI');
         BClsSendSdocInvoiceEmailSI sch = new BClsSendSdocInvoiceEmailSI('BE');         
        Database.executebatch(sch, 1);
    }
}