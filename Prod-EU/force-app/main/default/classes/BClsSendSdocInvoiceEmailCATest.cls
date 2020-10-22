/*
@Author        : Kumar Navneet
@Date Created    : 22/04/2020
@Description    : Test class for BClsSendSdocInvoiceEmailCA Batch class 
****************************************************************************************/
@isTest()
private class BClsSendSdocInvoiceEmailCATest {
    @isTest static void TestOrderCreation(){
         //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
         Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Payor', 'Canada')[0];
 		payorAccount.Email_Invoice_Opt_In__c = true;
        update payorAccount;
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CA Cash'});
        String customPricebookId = customPricebookMap.get('CA Cash');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'DEX-SHIP-01'});
        
        //Update the virtual sku productIdToPbeId
        Product2 virtualProd = [SELECT Id, Is_Virtual_Product__c FROM Product2 WHERE NAME = 'DEX-SHIP-01'];
        virtualProd.Is_Virtual_Product__c = true;
        update virtualProd;
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet()){
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
        
        Id caOppRecType = Schema.SObjectType.Benefit__c.getRecordTypeInfosByDeveloperName().get('CA_Benefit').getRecordTypeId();
           // [Select Id from RecordType where isActive = true AND SobjectType = 'Benefit__c' and DeveloperName = 'CA_Benefit'].Id;
        
         //Create new Benefit and associate it to the payor
        Benefit__c primaryBenefit = new Benefit__c();
        primaryBenefit.RecordTypeId = caOppRecType;
        primaryBenefit.Account__c = consumerAccts[0].Id;
        primaryBenefit.Member_Id__c = '1789657890';
       // primaryBenefit.Payor__c = accts[2].Id;
        primaryBenefit.Benefit_Hierarchy__c = 'Primary';
        insert primaryBenefit;
        
        //Create Order record
        ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = consumerAccts[0].Id;
        newOrder.Payor__c = payorAccount.Id;
        newOrder.RecordtypeId = caOrderRecdTypeId;
        newOrder.Type = 'CA STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;
        newOrder.Pricebook2Id = customPricebookId; 
        newOrder.Status = 'Draft';
        newOrder.Invoice_Email_Status__c = 'Pending';
        newOrder.Invoice_Number__c = '12415534';
       // newOrder.Email_Invoice_Opt_In__c = true;
        insert newOrder;        
        newOrder.Pricebook2Id = customPricebookId; 
        update newOrder;
        
        //List order line items
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values()){
            OrderItem oi = new OrderItem();
            oi.OrderId = newOrder.Id;
            oi.PricebookEntryId = pbeId;
            oi.Quantity = 1;
            oi.UnitPrice = 125.00;
            oi.Tracking_Number__c = '12345';
            oi.Product_Name__c = 'STK-GF-109' ;
            orderItemList.add(oi);
        }
        insert orderItemList;
        
        
        test.startTest();
      //  ClsSendContractForGBIEOpp sh1 = new ClsSendContractForGBIEOpp(newOppIE.id, 'IE');
      //    String sch = '0 0 23 * * ?'; system.schedule('Test Check', sch, sh1); 
        List<String> orderid = new List<String>();
        orderid.add(newOrder.Id);
        DataBase.executeBatch(new BClsSendSdocInvoiceEmailCA('CA' , orderid),1);
        test.stopTest();
        
        
        
    }
}