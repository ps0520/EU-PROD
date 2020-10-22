@isTest
public class BclsMICARenewalAndRuleEnd_Test {
	
    @isTest
    static void MIRenewalBatchTest() {
        
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCPB(new List<String>{'CAN G6 SUBSCRIPTION 12MOS Auto Renewal'},'CAD');
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'MTRNTCAGS-12MOS'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(Id productId : mapProduct.values()){
            productIdToPriceMap.put(productId, 10); 
        }
        Map<Id, Id> mapPBE = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, mapPriceBook.get('CAN G6 SUBSCRIPTION 12MOS Auto Renewal'));
        List<PricebookEntry> lstPBE = [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2.Name = 'CAN G6 SUBSCRIPTION 12MOS Auto Renewal'];
        List<Account> accountList= new List<Account>();
        Date renwalDate= date.today().adddays(90);
        Account testAccount = TestUtils.testCAConsumerAccount();
        testAccount.PersonEmail='jane.smith@sundog.net';
        testAccount.Email_Opt_In_Method__c = 'Via Email';
        insert testAccount;
        
        Product2 p = new product2();
        P.Name ='MTRNTCAGS-12MOS';
        //insert p;
        
        //for(Id ids : mapPBE.keySet()){
            SSIP_Rule__c ssip = new SSIP_Rule__c();
            ssip.Account__c=testAccount.Id;
            ssip.Renewal_Date__c=renwalDate;
            ssip.product__c=lstPBE[0].Product2Id;
            ssip.Price_Book__c = lstPBE[0].Pricebook2Id;
            ssip.PriceBookEntryId__c = lstPBE[0].Id;
            ssip.Status__c='Active';
            insert ssip; 
       // }
        
        
        Test.startTest();
        Database.executeBatch(new BclsMarketingInteractionCARenewalBatch(),200); 
        Test.stopTest();
        
        
    }
    @isTest
    static void MIRuleEndBatchTest() {
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCPB(new List<String>{'CAN G6 SUBSCRIPTION 12MOS NO Renewal'},'CAD');
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'MTRNTCAGS-12MOS'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(Id productId : mapProduct.values()){
            productIdToPriceMap.put(productId, 10); 
        }
        Map<Id, Id> mapPBE = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, mapPriceBook.get('CAN G6 SUBSCRIPTION 12MOS NO Renewal'));
        List<PricebookEntry> lstPBE = [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2.Name = 'CAN G6 SUBSCRIPTION 12MOS NO Renewal'];
        List<Account> accountList= new List<Account>();
        Date renwalDate= date.today().adddays(90);
        Account testAccount = TestUtils.testCAConsumerAccount();
        testAccount.PersonEmail='jane.smith@sundog.net';
        testAccount.Email_Opt_In_Method__c = 'Via Email';
        insert testAccount;
        
        Product2 p = new product2();
        P.Name ='MTRNTCAGS-12MOS';
        //insert p;
        
        //for(Id ids : mapPBE.keySet()){
            SSIP_Rule__c ssip = new SSIP_Rule__c();
            ssip.Account__c=testAccount.Id;
            ssip.Rule_End_Date__c =renwalDate;
            ssip.product__c=lstPBE[0].Product2Id;
            ssip.Price_Book__c = lstPBE[0].Pricebook2Id;
            ssip.PriceBookEntryId__c = lstPBE[0].Id;
            ssip.Status__c='Active';
            insert ssip; 
       // }
        
        
        Test.startTest();
        Database.executeBatch(new BclsMarketingInteractionCARuleEndBatch(),200); 
        Test.stopTest();
    }
}