/*****************************************************************************************
@Description    : Scheduler class for Clinical Email Invoice Automation
****************************************************************************************/
global class SClsCLINICALSendSdocInvoiceEmail implements Schedulable {
    global void execute(SchedulableContext SC) {
        BClsSendSdocInvoiceEmailIntlClinical sch = new BClsSendSdocInvoiceEmailIntlClinical('CLINICAL');
        Database.executebatch(sch, 1);
    }
}