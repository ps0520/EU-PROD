global class SClsCHQRBillGeneratorSchedule implements Schedulable {
    global void execute(SchedulableContext SC) {
        BClsGenerateQRBill batchClass = new BClsGenerateQRBill('SELECT Id, Preferred_Language__c, Total_Gross_Price__c, CurrencyIsoCode, Payor__r.Name, Account.Name, Account.AccountNumber, AccountId, BillingStreet, BillingCity, BillingPostalCode, BillingCountryCode, Invoice_Number__c, Invoice_Date__c, Payor__c, Customer_Bill_To_Address__r.Address_Line_2__c, Format_Total_Gross_Price__c FROM Order Where Generate_QR_Bill__c = true');
        Database.executebatch(batchClass, 1);
    }
}