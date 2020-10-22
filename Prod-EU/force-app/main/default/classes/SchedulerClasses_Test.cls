@isTest()
private class SchedulerClasses_Test {
	@testSetup static void setup() {
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCPB(new List<String>{'DE Netto-Preis Cash', 'DE Return Replace', 'Barmer'}, 'CHF');
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'Product-01', 'Product-02', 'Product-03', 'DEX-SHIP-01'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>{mapProduct.values()[0] => 10, mapProduct.values()[1] => 10, mapProduct.values()[2] => 10 };
        Map<Id, Id> mapPBE = ClsTestDataFactory.CreateCPBEntries(productIdToPriceMap, mapPriceBook.get('DE Netto-Preis Cash'), 'CHF');
        Account objAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Consumer', 'Germany')[0];
    }
    @isTest private static void test(){ 
		Id rtId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('CH Sales Order').getRecordTypeId();        
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Payor', 'Germany')[0];
        List<Account> lstAccount = [SELECT Id, Name FROM Account];
        List<PEClsHandleOrderEvents.OrderLineItem> lstOLI = new List<PEClsHandleOrderEvents.OrderLineItem>();
        for(Product2 product : [SELECT Id, Name FROM Product2]){
            lstOLI.add(new PEClsHandleOrderEvents.OrderLineItem(product.Id, 1, 10));
        }
        List<Product2> lstProduct = [SELECT Id, Name FROM Product2];
        List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Account__c = lstAccount[0].Id,Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = lstAccount[0].Id,Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = payorAccount.Id,Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = payorAccount.Id,Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                                                          };
        insert lstAddress;
        List<PricebookEntry> lstPBE = [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2.Name = 'DE Netto-Preis Cash'];
        Order objOrder = new Order(AccountId = lstAccount[0].Id, EffectiveDate = Date.today(), Status = 'Draft', Type = 'CH STANDARD', Payor__c = payorAccount.Id, Pricebook2Id = lstPBE[0].Pricebook2Id,
                                   RecordTypeId = rtId, CurrencyISOCode = 'CHF');
        insert objOrder;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        lstOrderItem.add(new OrderItem(PricebookEntryId = lstPBE[0].Id, OrderId = objOrder.Id, Quantity = 1, UnitPrice = 10));
        insert lstOrderItem;
        
        List<SSIP_Rule__c> lstSSIPRule = new List<SSIP_Rule__c>();
        for(PricebookEntry pbe : lstPBE){
            lstSSIPRule.add(new SSIP_Rule__c(Account__c = lstAccount[0].Id, First_Order__c = objOrder.Id, Schedule_Count__c = 1, Frequency_In_Days__c = 30,
                                             First_Repeat_Order_Lead_Days__c = 7, Price_Book__c = pbe.Pricebook2Id, PriceBookEntryId__c = pbe.Id,
                                             Product__c = pbe.Product2Id, Quantity__c = 1, Shipping_Address__c = lstAddress[1].Id, Status__c = 'Active'));
        }
        
        insert lstSSIPRule;
        for(SSIP_Rule__c ssipRule : lstSSIPRule){
            ssipRule.First_Shipment_Date__c = Date.today();
            ssipRule.Rule_Re_schedule_Date__c = Date.today()+1;
        }
        update lstSSIPRule;
        
        List<SSIP_Schedule__c> lstSSIPSchedule = [SELECT Id FROM SSIP_Schedule__c];
        for(SSIP_Schedule__c ssipSchedule : lstSSIPSchedule){
            ssipSchedule.Rescheduled_Shipment_Date__c = Date.today();
        }
        System.debug('====lstSSIPSchedule===='+lstSSIPSchedule);
        update lstSSIPSchedule;
        
        test.startTest();
         Record_Updater__c ReUp = new Record_Updater__c();
        ReUp.Id__c = lstAddress[1].Id ;
        ReUp.Name = 'Address__c';
        ReUp.Action__c = 'Update';
        ReUp.FieldName__c = 'IsLocked__c';
        ReUp.Field_Type__c = 'Checkbox';
        ReUp.Value__c = 'true';
        ReUp.Acted_On__c = false;
        insert ReUp;        
        
         System.schedule('test1', '0 0 0 3 9 ? 2052', new SClsAddressLocker());
        System.schedule('test2', '0 0 0 3 9 ? 2052', new SClsCHSSIPBatchScheduler());
        System.schedule('test3', '0 0 0 3 9 ? 2052', new SClsGBFutureOrderScheduler());
        System.schedule('test4', '0 0 0 3 9 ? 2052', new SClsGBSSIPBatchScheduler());
        System.schedule('test5', '0 0 0 3 9 ? 2052', new SClsGBSendSdocInvoiceEmail());        
        System.schedule('test6', '0 0 0 3 9 ? 2052', new SClsIEFutureOrderScheduler());
        System.schedule('test7', '0 0 0 3 9 ? 2052', new SClsIESendSdocInvoiceEmail());
        System.schedule('test8', '0 0 0 3 9 ? 2052', new SClsIESSIPBatchScheduler());        
        System.schedule('test9', '0 0 0 3 9 ? 2052', new SClsRecordUpdaterPurger());
        System.schedule('test10', '0 0 0 3 9 ? 2052', new SClsSendContractForGBIEOppScheduler());
        System.schedule('test11', '0 0 0 3 9 ? 2052', new SClsSSIPBatchScheduler());
        System.schedule('test12', '0 0 0 3 9 ? 2052', new SClsSSIPRuleDeactivate());
    
 
        
        DataBase.executeBatch(new BClsAddressLocker());
        DataBase.executeBatch(new BClsSSIPSchedule());
        DataBase.executeBatch(new BClsRecordUpdaterPurger());
        DemoAccountAddressupdateScript.updateAccountAddress();
        
        test.stopTest();
    }
}