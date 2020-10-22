@isTest
public class ClsSSIPRuleRenewal_Test {
    
    @isTest static void TestOrderCreationAndUpdateCA(){
        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        System.debug('**consumerAccts--'+consumerAccts);
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CA Cash'});
        String customPricebookId = customPricebookMap.get('CA Cash');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'MTLYCHARGE', 'STT-GF-006', 'DEX-SHIP-02'});
        
        //Update the virtual sku productIdToPbeId
        Product2 virtualProd = [SELECT Id, Is_Virtual_Product__c FROM Product2 WHERE NAME = 'MTLYCHARGE'];
        virtualProd.Is_Virtual_Product__c = true;
        update virtualProd;
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet()){
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
        Id caSSIPRecdTypeId = Schema.SObjectType.SSIP_Rule__c.getRecordTypeInfosByDeveloperName().get('CA_SSIP_Rule').getRecordTypeId();
        Id CASAddreRedTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = consumerAccts[0].Id,RecordtypeId=CASAddreRedTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Victoria', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = 'V5Z 2M9', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = consumerAccts[0].Id,RecordtypeId=CASAddreRedTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Victoria', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = 'V5Z 2M9', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                // new Address__c(Account__c = payorAccount.Id,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                //new Address__c(Account__c = payorAccount.Id,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = ' W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                };
                    insert lstAddress;
        
        List<PricebookEntry> lstPBE = [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2.Name = 'CA Cash'];
        System.debug('lstPBE--'+lstPBE.size());
        List<SSIP_Rule__c> lstSSIPRule = new List<SSIP_Rule__c>();
        
        Date firstDayOfMonth = System.today().toStartOfMonth();
        Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
        Integer counter = 0;
        //for(PricebookEntry pbe : lstPBE){
        for(Integer i =0 ;i<3;i++){
            lstSSIPRule.add(new SSIP_Rule__c(Account__c = consumerAccts[0].Id,  Schedule_Count__c = 3, Frequency_In_Days__c = 30, //First_Order__c = null,
                                             First_Repeat_Order_Lead_Days__c = 7, Price_Book__c = lstPBE[i].Pricebook2Id, PriceBookEntryId__c = lstPBE[i].Id,
                                             First_Shipment_Date__c = Date.today(),Rule_Re_schedule_Date__c = Date.today()+1,RecordTypeId=caSSIPRecdTypeId,
                                             Country__c = 'Canada',
                                             Product__c = lstPBE[i].Product2Id, Quantity__c = 1, Shipping_Address__c = null, Status__c = 'Active'));
        }
        
        
        
        //}
        Test.startTest();
        insert lstSSIPRule;
        //System.debug('**Date--'+;
        for(SSIP_Rule__c ssipRule : lstSSIPRule){
            ssipRule.Rule_End_Date__c = Date.today()+100;
        }
        
        List<SSIP_Schedule__c> lstSSIPSchedule2 = [SELECT Id,Account__c FROM SSIP_Schedule__c where Account__c=:consumerAccts[0].Id Limit 2];
        for(SSIP_Schedule__c ssipSchedule : lstSSIPSchedule2){
            ssipSchedule.Status__c = 'In Progress';
            
        }
        System.debug('====lstSSIPSchedule2===='+lstSSIPSchedule2);
        update lstSSIPSchedule2;
        
        
        //update lstSSIPRule;
        List<SSIP_Schedule__c> lstSSIPSchedule = [SELECT Id,Account__c FROM SSIP_Schedule__c where Account__c=:consumerAccts[0].Id limit 1];
        for(SSIP_Schedule__c ssipSchedule : lstSSIPSchedule){
            ssipSchedule.Status__c = 'Open';
            
        }
        System.debug('====lstSSIPSchedule===='+lstSSIPSchedule);
        update lstSSIPSchedule;
        
        for(SSIP_Rule__c ssipRule : lstSSIPRule){
            ssipRule.Rule_End_Date__c = Date.today()+100;
        }
        update lstSSIPRule;
        
        test.stopTest();
    }
    @isTest static void TestOrderCreationAndUpdateCA2(){        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        System.debug('**consumerAccts--'+consumerAccts);
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CA Cash'});
        String customPricebookId = customPricebookMap.get('CA Cash');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'MTLYCHARGE', 'STT-GF-006', 'DEX-SHIP-02'});
        
        //Update the virtual sku productIdToPbeId
        Product2 virtualProd = [SELECT Id, Is_Virtual_Product__c FROM Product2 WHERE NAME = 'MTLYCHARGE'];
        virtualProd.Is_Virtual_Product__c = true;
        update virtualProd;
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet()){
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
        Id caSSIPRecdTypeId = Schema.SObjectType.SSIP_Rule__c.getRecordTypeInfosByDeveloperName().get('CA_SSIP_Rule').getRecordTypeId();
        Id CASAddreRedTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = consumerAccts[0].Id,RecordtypeId=CASAddreRedTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Victoria', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = 'V5Z 2M9', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = consumerAccts[0].Id,RecordtypeId=CASAddreRedTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Victoria', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = 'V5Z 2M9', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                // new Address__c(Account__c = payorAccount.Id,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                //new Address__c(Account__c = payorAccount.Id,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = ' W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                };
                    insert lstAddress;
        
        List<PricebookEntry> lstPBE = [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2.Name = 'CA Cash'];
        System.debug('lstPBE--'+lstPBE.size());
        List<SSIP_Rule__c> lstSSIPRule = new List<SSIP_Rule__c>();
        
        Date firstDayOfMonth = System.today().toStartOfMonth();
        Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
        Integer counter = 0;
        //for(PricebookEntry pbe : lstPBE){
        for(Integer i =0 ;i<3;i++){
            lstSSIPRule.add(new SSIP_Rule__c(Account__c = consumerAccts[0].Id,  Schedule_Count__c = 3, Frequency_In_Days__c = 30, //First_Order__c = null,
                                             First_Repeat_Order_Lead_Days__c = 7, Price_Book__c = lstPBE[i].Pricebook2Id, PriceBookEntryId__c = lstPBE[i].Id,
                                             First_Shipment_Date__c = Date.today(),Rule_Re_schedule_Date__c = Date.today()+1,RecordTypeId=caSSIPRecdTypeId,
                                             Country__c = 'Canada',
                                             Product__c = lstPBE[i].Product2Id, Quantity__c = 1, Shipping_Address__c = null, Status__c = 'Active'));
        }
        
        
        
        //}
        Test.startTest();
        insert lstSSIPRule;
        //System.debug('**Date--'+;
        for(SSIP_Rule__c ssipRule : lstSSIPRule){
            ssipRule.Rule_End_Date__c = Date.today()+100;
        }
        
        List<SSIP_Schedule__c> lstSSIPSchedule2 = [SELECT Id,Account__c FROM SSIP_Schedule__c where Account__c=:consumerAccts[0].Id Limit 3];
        for(SSIP_Schedule__c ssipSchedule : lstSSIPSchedule2){
            ssipSchedule.Status__c = 'In Progress';
            
        }
        System.debug('====lstSSIPSchedule2===='+lstSSIPSchedule2);
        update lstSSIPSchedule2;
        
        
        
        for(SSIP_Rule__c ssipRule : lstSSIPRule){
            ssipRule.Rule_End_Date__c = Date.today()+100;
        }
        update lstSSIPRule;
        
        test.stopTest();
    }  
   /* @isTest static void TestOrderCreationAndUpdateCA3(){        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        System.debug('**consumerAccts--'+consumerAccts);
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CA Cash'});
        String customPricebookId = customPricebookMap.get('CA Cash');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'MTLYCHARGE', 'STT-GF-006', 'DEX-SHIP-02'});
        
        //Update the virtual sku productIdToPbeId
        Product2 virtualProd = [SELECT Id, Is_Virtual_Product__c FROM Product2 WHERE NAME = 'MTLYCHARGE'];
        virtualProd.Is_Virtual_Product__c = true;
        update virtualProd;
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet()){
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
        Id caSSIPRecdTypeId = Schema.SObjectType.SSIP_Rule__c.getRecordTypeInfosByDeveloperName().get('CA_SSIP_Rule').getRecordTypeId();
        Id CASAddreRedTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = consumerAccts[0].Id,RecordtypeId=CASAddreRedTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Victoria', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = 'V5Z 2M9', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = consumerAccts[0].Id,RecordtypeId=CASAddreRedTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Victoria', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = 'V5Z 2M9', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                // new Address__c(Account__c = payorAccount.Id,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                //new Address__c(Account__c = payorAccount.Id,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = ' W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                };
                    insert lstAddress;
        
        List<PricebookEntry> lstPBE = [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2.Name = 'CA Cash'];
        System.debug('lstPBE--'+lstPBE.size());
        List<SSIP_Rule__c> lstSSIPRule = new List<SSIP_Rule__c>();
        
        Date firstDayOfMonth = System.today().toStartOfMonth();
        Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
        Integer counter = 0;
        //for(PricebookEntry pbe : lstPBE){
        for(Integer i =0 ;i<1;i++){
            Date cd = System.today();
            date d = Date.newInstance(cd.year(),cd.month(),29);
            lstSSIPRule.add(new SSIP_Rule__c(Account__c = consumerAccts[0].Id,  Schedule_Count__c = 3, Frequency_In_Days__c = 30, //First_Order__c = null,
                                             First_Repeat_Order_Lead_Days__c = 7, Price_Book__c = lstPBE[i].Pricebook2Id, PriceBookEntryId__c = lstPBE[i].Id,
                                             First_Shipment_Date__c = d,RecordTypeId=caSSIPRecdTypeId,
                                             Country__c = 'Canada',
                                             Product__c = lstPBE[i].Product2Id, Quantity__c = 1, Shipping_Address__c = null, Status__c = 'Active'));
        }
        
        
        
        //}
        Test.startTest();
        insert lstSSIPRule;
        //System.debug('**Date--'+;
        for(SSIP_Rule__c ssipRule : lstSSIPRule){
            ssipRule.Rule_End_Date__c = Date.today()+100;
        }
        
        List<SSIP_Schedule__c> lstSSIPSchedule2 = [SELECT Id,Account__c,Schedule_Date__c FROM SSIP_Schedule__c where Account__c=:consumerAccts[0].Id Limit 3];
        for(SSIP_Schedule__c ssipSchedule : lstSSIPSchedule2){
            ssipSchedule.Status__c = 'In Progress';
            Integer dayofMonth = ssipSchedule.Schedule_Date__c.day();
            if(dayofMonth<28){
                Date cd = System.today();
                date d = Date.newInstance(cd.year(),cd.month(),29);
                ssipSchedule.Schedule_Date__c = d;
            }
            System.debug('--CA3ssipSchedule---'+ssipSchedule.Schedule_Date__c);
            
        }
        System.debug('====lstSSIPSchedule2===='+lstSSIPSchedule2);
        update lstSSIPSchedule2;
        
        
        
        for(SSIP_Rule__c ssipRule : lstSSIPRule){
            ssipRule.Rule_End_Date__c = Date.today()+100;
        }
        update lstSSIPRule;
        
        test.stopTest();
    } */
    @isTest static void TestOrderCreationCH(){        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CH Consumer', 'Switzerland');
        System.debug('**consumerAccts--'+consumerAccts);
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CH Cash'});
        String customPricebookId = customPricebookMap.get('CH Cash');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STT-GF-013', 'STT-GF-006', 'DEX-SHIP-02'});
        
        //Update the virtual sku productIdToPbeId
        Product2 virtualProd = [SELECT Id, Is_Virtual_Product__c FROM Product2 WHERE NAME = 'STT-GF-006'];
        virtualProd.Is_Virtual_Product__c = true;
        update virtualProd;
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet()){
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        //Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
        Id CHSSIPRecdTypeId = Schema.SObjectType.SSIP_Rule__c.getRecordTypeInfosByDeveloperName().get('CH_SSIP_Rule').getRecordTypeId();
        Id CHSAddreRedTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CH_Address').getRecordTypeId();
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = consumerAccts[0].Id,RecordtypeId=CHSAddreRedTypeId,Type__c = 'Bill To', Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = consumerAccts[0].Id,RecordtypeId=CHSAddreRedTypeId,Type__c = 'Ship To',Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                //new Address__c(Account__c = consumerAccts[0].Id,Type__c = 'Bill To', Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                //new Address__c(Account__c = consumerAccts[0].Id,Type__c = 'Ship To',Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = ' W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                };
                    insert lstAddress;
        
        List<PricebookEntry> lstPBE = [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2.Name = 'CH Cash'];
        System.debug('lstPBE--'+lstPBE.size());
        List<SSIP_Rule__c> lstSSIPRule = new List<SSIP_Rule__c>();
        
        Date firstDayOfMonth = System.today().toStartOfMonth();
        Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
        Integer counter = 0;
        
        for(Integer i =0 ;i<3;i++){
            lstSSIPRule.add(new SSIP_Rule__c(Account__c = consumerAccts[0].Id,  Schedule_Count__c = 3, Frequency_In_Days__c = 30, //First_Order__c = null,
                                             First_Repeat_Order_Lead_Days__c = 7, Price_Book__c = lstPBE[i].Pricebook2Id, PriceBookEntryId__c = lstPBE[i].Id,
                                             First_Shipment_Date__c = Date.today(),Rule_Re_schedule_Date__c = Date.today()+1,RecordTypeId=CHSSIPRecdTypeId,
                                             Country__c = 'Switzerland',
                                             Product__c = lstPBE[i].Product2Id, Quantity__c = 1, Shipping_Address__c = null, Status__c = 'Active'));
        }
        Test.startTest();
        insert lstSSIPRule;
        
        
        List<SSIP_Schedule__c> lstSSIPSchedule = [SELECT Id,Account__c FROM SSIP_Schedule__c where Account__c=:consumerAccts[0].Id Limit 2];
        for(SSIP_Schedule__c ssipSchedule : lstSSIPSchedule){
            ssipSchedule.Status__c = 'Open';             
        }
        System.debug('====lstSSIPSchedule===='+lstSSIPSchedule);
        update lstSSIPSchedule; 
        
        List<SSIP_Schedule__c> lstSSIPSchedule2 = [SELECT Id,Account__c FROM SSIP_Schedule__c where Account__c=:consumerAccts[0].Id Limit 2];
        for(SSIP_Schedule__c ssipSchedule : lstSSIPSchedule2){
            ssipSchedule.Status__c = 'In Progress';             
        }
        System.debug('====lstSSIPSchedule2===='+lstSSIPSchedule2);
        update lstSSIPSchedule2;
        
        for(SSIP_Rule__c ssipRule : lstSSIPRule){
            ssipRule.Rule_End_Date__c = Date.today()+100;
        }
        update lstSSIPRule;
        
        test.stopTest();
    }
    @isTest static void TestOrderCreationCH2(){        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CH Consumer', 'Switzerland');
        System.debug('**consumerAccts--'+consumerAccts);
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CH Cash'});
        String customPricebookId = customPricebookMap.get('CH Cash');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STT-GF-013', 'STT-GF-006', 'DEX-SHIP-02'});
        
        //Update the virtual sku productIdToPbeId
        Product2 virtualProd = [SELECT Id, Is_Virtual_Product__c FROM Product2 WHERE NAME = 'STT-GF-006'];
        virtualProd.Is_Virtual_Product__c = true;
        update virtualProd;
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet()){
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        //Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
        Id CHSSIPRecdTypeId = Schema.SObjectType.SSIP_Rule__c.getRecordTypeInfosByDeveloperName().get('CH_SSIP_Rule').getRecordTypeId();
        Id CHSAddreRedTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CH_Address').getRecordTypeId();
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = consumerAccts[0].Id,RecordtypeId=CHSAddreRedTypeId,Type__c = 'Bill To', Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = consumerAccts[0].Id,RecordtypeId=CHSAddreRedTypeId,Type__c = 'Ship To',Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                //new Address__c(Account__c = consumerAccts[0].Id,Type__c = 'Bill To', Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                //new Address__c(Account__c = consumerAccts[0].Id,Type__c = 'Ship To',Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = ' W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                };
                    insert lstAddress;
        
        List<PricebookEntry> lstPBE = [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2.Name = 'CH Cash'];
        System.debug('lstPBE--'+lstPBE.size());
        List<SSIP_Rule__c> lstSSIPRule = new List<SSIP_Rule__c>();
        
        Date firstDayOfMonth = System.today().toStartOfMonth();
        Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
        Integer counter = 0;
        
        for(Integer i =0 ;i<3;i++){
            lstSSIPRule.add(new SSIP_Rule__c(Account__c = consumerAccts[0].Id,  Schedule_Count__c = 3, Frequency_In_Days__c = 30, //First_Order__c = null,
                                             First_Repeat_Order_Lead_Days__c = 7, Price_Book__c = lstPBE[i].Pricebook2Id, PriceBookEntryId__c = lstPBE[i].Id,
                                             First_Shipment_Date__c = Date.today(),Rule_Re_schedule_Date__c = Date.today()+1,RecordTypeId=CHSSIPRecdTypeId,
                                             Country__c = 'Switzerland',
                                             Product__c = lstPBE[i].Product2Id, Quantity__c = 1, Shipping_Address__c = null, Status__c = 'Active'));
        }
        Test.startTest();
        insert lstSSIPRule;
        
        
        List<SSIP_Schedule__c> lstSSIPSchedule = [SELECT Id,Account__c FROM SSIP_Schedule__c where Account__c=:consumerAccts[0].Id Limit 2];
        for(SSIP_Schedule__c ssipSchedule : lstSSIPSchedule){
            ssipSchedule.Status__c = 'Open';             
        }
        System.debug('====lstSSIPSchedule===='+lstSSIPSchedule);
        //update lstSSIPSchedule; 
        
        List<SSIP_Schedule__c> lstSSIPSchedule2 = [SELECT Id,Account__c FROM SSIP_Schedule__c where Account__c=:consumerAccts[0].Id Limit 3];
        for(SSIP_Schedule__c ssipSchedule : lstSSIPSchedule2){
            ssipSchedule.Status__c = 'In Progress';             
        }
        System.debug('====lstSSIPSchedule2===='+lstSSIPSchedule2);
        update lstSSIPSchedule2;
        
        for(SSIP_Rule__c ssipRule : lstSSIPRule){
            ssipRule.Rule_End_Date__c = Date.today()+100;
        }
        update lstSSIPRule;
        
        test.stopTest();
    }
    
}