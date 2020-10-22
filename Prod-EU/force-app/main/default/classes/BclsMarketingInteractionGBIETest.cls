@isTest()
public class BclsMarketingInteractionGBIETest {
@isTest
    static void testHourlyEmailScheduledJob() {
        //insert TestDataBuilder.testURLExpiryVal();

        List<Account> accountList= new List<Account>();
        Date tenDate= date.today().adddays(10);
        Account testAccount = TestUtils.testGBConsumerAccount();
        testAccount.PersonEmail='jane.smith@sundog.net';
        testAccount.Email_Opt_In_Method__c = 'Via Email';
        
            
        insert testAccount;

         //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'UK G6 SUBSCRIPTION 12MOS'});
        String customPricebookId = customPricebookMap.get('UK G6 SUBSCRIPTION 12MOS');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'MTRNTG612MOS'});

        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        productIdToPriceMap.put(products.get('MTRNTG612MOS'), 125.00);
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, customPricebookId);

        SSIP_Rule__c ssip = new SSIP_Rule__c();
        ssip.Account__c=testAccount.Id;
        ssip.Renewal_Date__c=tenDate;
        ssip.Price_Book__c = customPricebookId;
        ssip.product__c=products.get('MTRNTG612MOS');
        ssip.Status__c='Active';
        insert ssip;
        
        Test.startTest();
        String jobId = System.schedule('testScheduled', '0 0 0 3 9 ? 2052', new SclsMarketingInteractionGBIEScheduled());
        
        BclsMarketingInteractionGBIEBatch sbatch = new BclsMarketingInteractionGBIEBatch();
        Id batchInstanceId = Database.executeBatch(sbatch, 1);
        
        Test.stopTest();
        
        List<marketing_interaction__c> m= [SELECT id, Account__c FROM marketing_interaction__c WHERE account__c = :testAccount.Id 
                                           AND Communication_Type__c='UKIE - Subscription Renewal - G6'];
        
        System.assertEquals(1, m.size());
        
    }
        
        
}