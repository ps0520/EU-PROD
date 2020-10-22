@isTest
public class ClsTrgCRMAttachmentEvent_Test{
    
    @testSetup static void setup() {
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCPB(new List<String>{'CH Cash','DE Netto-Preis Cash'}, 'CHF');        
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'Product-01', 'Product-02', 'Product-03', 'DEX-SHIP-01'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>{mapProduct.values()[0] => 10, mapProduct.values()[1] => 0, mapProduct.values()[2] => 0 };
        Map<Id, Id> mapPBE = ClsTestDataFactory.CreateCPBEntries(productIdToPriceMap, mapPriceBook.get('CH Cash'), 'CHF');
    }
    
    @isTest public static void TestAttchment(){
          
        GoogleStorage__c supportConfig = GoogleStorage__c.getOrgDefaults();
        system.debug('Custom Setting Before: ' + supportConfig);
        supportConfig.Name = 'Test';
        supportConfig.AccessToken__c = 'ya29.c.Ko8B1QcDgdGnI7_zCMVY7d518kmkLCHyqtgONAkFjF3P0r5SXMSoWtkv9tp5a4_Wik74_KIzI30VJEXA_UNuO0GjWEsrM5tyjrMm73RgECReXSllCUBKpNiVHQiEachrxfT6aTwn6Bb-1YlbVte__xtwJc67nzOLUXyqIJd_ogW4yQgNsYd-VQ7pMT7HbC229nk';
        Long timeSince = System.now().getTime();
        Long longIssueTime = timeSince;
        String expTime = String.valueOf(longIssueTime + 3600000); // 1 hr
        supportConfig.Expiration_Time__c = expTime;
        upsert supportConfig;
        
        Id chOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CH_Sales_Order').getRecordTypeId();
        
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CH Consumer', 'Switzerland')[0];
        payorAccount.Subscription_Pending_Payments__c = 1;
        update payorAccount;
            List<Account> lstAccount = [SELECT Id, Name,Credit_Hold__c FROM Account where Subscription_Pending_Payments__c >0];
            
            List<Product2> lstProduct = [SELECT Id, Name FROM Product2];  
            List<Address__c> lstAddress = new List<Address__c>{
                new Address__c(Account__c = lstAccount[0].Id,Type__c = 'Bill To', Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                    new Address__c(Account__c = lstAccount[0].Id,Type__c = 'Ship To',Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                    new Address__c(Account__c = payorAccount.Id,Type__c = 'Bill To', Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                    new Address__c(Account__c = payorAccount.Id,Type__c = 'Ship To',Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = ' W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                    };
                        insert lstAddress;
            
            Id rtIdFDCC = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
            Finance_Detail__c fd1= new Finance_Detail__c(Account__c=payorAccount.Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='CHF',
                                                         Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=lstAddress[0].id, RecordTypeId=rtIdFDCC);
            insert fd1;
            List<PricebookEntry> lstPBE = [SELECT Id,Name, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2.Name = 'CH Cash'];
            Order objOrder = new Order(AccountId = payorAccount.Id, EffectiveDate = Date.today(), Status = 'Draft', Type = 'CH STANDARD', 
                                       Pricebook2Id = lstPBE[0].Pricebook2Id,
                                       Payment_Terms__c = 'net30',
                                       Finance_Detail__c = fd1.Id,
                                       RecordTypeId = chOrderRecdTypeId, CurrencyISOCode = 'CHF');
            insert objOrder;
            List<OrderItem> lstOrderItem = new List<OrderItem>();
            lstOrderItem.add(new OrderItem(PricebookEntryId = lstPBE[0].Id, OrderId = objOrder.Id, Quantity = 1, UnitPrice = 10));
            insert lstOrderItem;
            
            order ord = [Select id,OrderNumber from Order where Id=:objOrder.Id];
            System.debug('**objOrder--'+ord.Id+'**--ordNumber--'+ord.OrderNumber); 
            
            
            CRM_Attachment_Event__e crmAttachObj = new CRM_Attachment_Event__e(version__c='3.0',eventDate__c='2020-04-22T23=14=07.943Z',
                                                                               entityType__c='attachment',eventSource__c='3pl',eventSourceID__c='JVGL06093702501486166029',operation__c='create',
                                                                               stage__c='confirmed',systemOfOrigin__c='crm',systemOfOriginID__c='01200020',parentSystemOfOriginID__c=null,author__c=null,
                                                                               metadata__c='',classification__c='proofOfDelivery',referenceNumberName__c='orderNumber',
                                                                               referenceNumberValue__c=ord.OrderNumber,name__c='ePod-JVGL06093702501486166029',type__c='pdf',
                                                                               content__c='gcp=eu.attachment.3pl.raw/content/5f9ce630-9bab-4d10-aa03-7517e0d5aa1f');
         
        Database.SaveResult sr = EventBus.publish(crmAttachObj);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGoogleStorage());
        //System.enqueueJob(new PEClsHandleAttachmentEvents.LoadFileQueuable(ord.OrderNumber,crmAttachObj.content__c,
                                                                          // crmAttachObj.name__c,crmAttachObj.eventSource__c, crmAttachObj.eventSourceID__c, ord.Id));
        
        Test.stopTest();
        
    }
    
     @isTest public static void TestAttchment2(){
          
        GoogleStorage__c supportConfig = GoogleStorage__c.getOrgDefaults();
        system.debug('Custom Setting Before: ' + supportConfig);
        supportConfig.Name = 'Test';
        //supportConfig.AccessToken__c = 'ya29.c.Ko8B1QcDgdGnI7_zCMVY7d518kmkLCHyqtgONAkFjF3P0r5SXMSoWtkv9tp5a4_Wik74_KIzI30VJEXA_UNuO0GjWEsrM5tyjrMm73RgECReXSllCUBKpNiVHQiEachrxfT6aTwn6Bb-1YlbVte__xtwJc67nzOLUXyqIJd_ogW4yQgNsYd-VQ7pMT7HbC229nk';
       
        upsert supportConfig;
        
        Id chOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CH_Sales_Order').getRecordTypeId();
        
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CH Consumer', 'Switzerland')[0];
        payorAccount.Subscription_Pending_Payments__c = 1;
        update payorAccount;
            List<Account> lstAccount = [SELECT Id, Name,Credit_Hold__c FROM Account where Subscription_Pending_Payments__c >0];
            
            List<Product2> lstProduct = [SELECT Id, Name FROM Product2];  
            List<Address__c> lstAddress = new List<Address__c>{
                new Address__c(Account__c = lstAccount[0].Id,Type__c = 'Bill To', Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                    new Address__c(Account__c = lstAccount[0].Id,Type__c = 'Ship To',Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                    new Address__c(Account__c = payorAccount.Id,Type__c = 'Bill To', Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                    new Address__c(Account__c = payorAccount.Id,Type__c = 'Ship To',Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = ' W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                    };
                        insert lstAddress;
            
            Id rtIdFDCC = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
            Finance_Detail__c fd1= new Finance_Detail__c(Account__c=payorAccount.Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='CHF',
                                                         Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=lstAddress[0].id, RecordTypeId=rtIdFDCC);
            insert fd1;
            List<PricebookEntry> lstPBE = [SELECT Id,Name, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2.Name = 'CH Cash'];
            Order objOrder = new Order(AccountId = payorAccount.Id, EffectiveDate = Date.today(), Status = 'Draft', Type = 'CH STANDARD', 
                                       Pricebook2Id = lstPBE[0].Pricebook2Id,
                                       Payment_Terms__c = 'net30',
                                       Finance_Detail__c = fd1.Id,
                                       RecordTypeId = chOrderRecdTypeId, CurrencyISOCode = 'CHF');
            insert objOrder;
            List<OrderItem> lstOrderItem = new List<OrderItem>(); 
            lstOrderItem.add(new OrderItem(PricebookEntryId = lstPBE[0].Id, OrderId = objOrder.Id, Quantity = 1, UnitPrice = 10));
            insert lstOrderItem;
            
            order ord = [Select id,OrderNumber from Order where Id=:objOrder.Id]; 
            CRM_Attachment_Event__e crmAttachObj = new CRM_Attachment_Event__e(version__c='3.0',eventDate__c='2020-04-22T23=14=07.943Z',
                                                                               entityType__c='attachment',eventSource__c='3pl',eventSourceID__c='JVGL06093702501486166029',operation__c='create',
                                                                               stage__c='confirmed',systemOfOrigin__c='crm',systemOfOriginID__c='01200020',parentSystemOfOriginID__c=null,author__c=null,
                                                                               metadata__c='',classification__c='proofOfDelivery',referenceNumberName__c='orderNumber',
                                                                               referenceNumberValue__c=ord.OrderNumber,name__c='ePod-JVGL06093702501486166029',type__c='pdf',
                                                                               content__c='gcp=eu.attachment.3pl.raw/content/5f9ce630-9bab-4d10-aa03-7517e0d5aa1f');
            
        
         Test.startTest();
         Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGoogleStorage());
         EventBus.publish(crmAttachObj);
         Test.stopTest();
        
    } 
}