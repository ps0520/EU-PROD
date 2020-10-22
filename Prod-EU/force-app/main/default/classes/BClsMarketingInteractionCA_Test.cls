@isTest
public class BClsMarketingInteractionCA_Test {
    
    @isTest static void MIRuleEndDateBatch(){
        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CAN G6 SUBSCRIPTION 12MOS NO Renewal'});
        String customPricebookId = customPricebookMap.get('CAN G6 SUBSCRIPTION 12MOS NO Renewal');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'MTRNTCAGS-12MOS'});
        
        //Update the virtual sku productIdToPbeId
        Product2 virtualProd = [SELECT Id, Is_Virtual_Product__c FROM Product2 WHERE NAME = 'MTRNTCAGS-12MOS'];
        virtualProd.Is_Virtual_Product__c = true;
        update virtualProd;
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet()){
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        List<PricebookEntry> lstPBE = [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2.Name = 'CAN G6 SUBSCRIPTION 12MOS NO Renewal'];
        Id caRecdTypeId = Schema.SObjectType.SSIP_Rule__c.getRecordTypeInfosByDeveloperName().get('CA_SSIP_Rule').getRecordTypeId();
        Date tenDate= date.today().adddays(90);
        SSIP_Rule__c ssip = new SSIP_Rule__c();
        ssip.RecordTypeId=caRecdTypeId;
        ssip.Account__c=consumerAccts[0].Id;
        ssip.Rule_End_Date__c =tenDate;
        ssip.Country__c='Canada';
        ssip.Price_Book__c = customPricebookId;
        ssip.PriceBookEntryId__c =lstPBE[0].id;
        ssip.product__c=products.get('MTRNTCAGS-12MOS');
        ssip.Status__c='Active';
        insert ssip;
        
        Marketing_interaction__c mi = new Marketing_interaction__c();
        mi.Account__c = consumerAccts[0].Id;
        mi.Communication_Type__c = 'CA - Subscription Renewal - Signature';
        mi.Country__c = 'Canada';
        mi.CurrencyIsoCode = 'CAD';
        mi.Source_Record_Id__c = ssip.Id;
        mi.Related_Information__c = String.valueOf(ssip.Rule_End_Date__c);
        insert mi;
        Datetime beforeSixMon = Datetime.now().addDays(-98);
        Test.setCreatedDate(mi.Id, beforeSixMon);
        Test.startTest();
        BclsMarketingInteractionCARuleEndBatch sbatch = new BclsMarketingInteractionCARuleEndBatch();
        Id batchInstanceId = Database.executeBatch(sbatch, 1);
        
        Test.stopTest();
    }
     @isTest static void MIRenewalDateBatch(){
        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CAN G6 SUBSCRIPTION 12MOS Auto Renewal'});
        String customPricebookId = customPricebookMap.get('CAN G6 SUBSCRIPTION 12MOS Auto Renewal');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'MTRNTCAGS-12MOS'});
        
        //Update the virtual sku productIdToPbeId
        Product2 virtualProd = [SELECT Id, Is_Virtual_Product__c FROM Product2 WHERE NAME = 'MTRNTCAGS-12MOS'];
        virtualProd.Is_Virtual_Product__c = true;
        update virtualProd;
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet()){
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        List<PricebookEntry> lstPBE = [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2.Name = 'CAN G6 SUBSCRIPTION 12MOS Auto Renewal'];
        Id caRecdTypeId = Schema.SObjectType.SSIP_Rule__c.getRecordTypeInfosByDeveloperName().get('CA_SSIP_Rule').getRecordTypeId();
        Date tenDate= date.today().adddays(60);
        SSIP_Rule__c ssip = new SSIP_Rule__c();
        ssip.RecordTypeId=caRecdTypeId;
        ssip.Account__c=consumerAccts[0].Id;
        ssip.Renewal_Date__c  =tenDate;
        ssip.Country__c='Canada';
        ssip.Price_Book__c = customPricebookId;
        ssip.PriceBookEntryId__c =lstPBE[0].id;
        ssip.product__c=products.get('MTRNTCAGS-12MOS');
        ssip.Status__c='Active';
        insert ssip;
        
        Marketing_interaction__c mi = new Marketing_interaction__c();
        mi.Account__c = consumerAccts[0].Id;
        mi.Communication_Type__c = 'CA - Subscription Renewal - Auto';
        mi.Country__c = 'Canada';
        mi.CurrencyIsoCode = 'CAD';
        mi.Source_Record_Id__c = ssip.Id;
        mi.Related_Information__c = String.valueOf(ssip.Renewal_Date__c);
        insert mi;
        Datetime beforeSixMon = Datetime.now().addDays(-98);
        Test.setCreatedDate(mi.Id, beforeSixMon);
        Test.startTest();
        BclsMarketingInteractionCARenewalBatch sbatch = new BclsMarketingInteractionCARenewalBatch();
        Id batchInstanceId = Database.executeBatch(sbatch, 1);
        
        Test.stopTest();
    }
}