/*
@Author        : Kumar Navneet
@Date Created    : 22/01/2020
@Description    : Test class for BClsFutureOrders Batch class 
****************************************************************************************/
@isTest()
private class BClsFutureOrderHandlerTest {
    @isTest static void TestOrderCreation(){
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CH Consumer', 'Switzerland');
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CH Cash'});
        String customPricebookId = customPricebookMap.get('CH Cash');
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String>{'Product-01', 'Product-02', 'Product-03', 'DEX-SHIP-01'});        
        //Update the virtual sku productIdToPbeId
        Product2 virtualProd = [SELECT Id, Is_Virtual_Product__c FROM Product2 WHERE NAME = 'DEX-SHIP-01'];
        virtualProd.Is_Virtual_Product__c = true;
        update virtualProd;        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
        {
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCH(productIdToPriceMap, customPricebookId);
        Id chOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CH_Sales_Order').getRecordTypeId();
        //Create Order record
        ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = consumerAccts[0].Id;
        newOrder.RecordtypeId = chOrderRecdTypeId;
        newOrder.Type = 'CH STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId; 
        newOrder.Pricebook2Id = customPricebookId; 
        newOrder.payment_Terms__c = 'net30';
        newOrder.Future_Order__c = true ;
        newOrder.Status = 'Draft';
        newOrder.Tax_Exempt__c = true;
        insert newOrder; 
        
        //List order line items
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values())
        {
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
        
        Set<Id> OrdIDSet;
        Set<String> OrdNoSet;
        Date sdt = Date.today();
        Date edt = Date.today();
        new BClsFutureOrderHandler();
        test.startTest();
        
        DataBase.executeBatch(new BClsFutureOrderHandler(sdt, edt, 'CH', OrdIDSet, OrdNoSet),1);
        
        order o = [SELECT id, EffectiveDate, payment_terms__c, total_gross_Price__c, type, Account.RecordType.Name, accountId , Account.Subscription_Pending_Payments__c, Count_of_Order_Line_Items__c from order limit 1] ;
        System.enqueueJob(new SSIPScheduleJobUtiltiy.CalculateTaxQueueable(String.valueof(o.Id), o.payment_terms__c, o.Account.RecordType.Name.substring(0,2), (Integer) o.Count_of_Order_Line_Items__c , (Integer) o.Account.Subscription_Pending_Payments__c , o.accountId, false));
        System.enqueueJob(new SSIPScheduleJobUtiltiy.AuthorizeAndSettlePaymentQueueable(String.valueof(o.Id), 'CH', (Integer) o.Count_of_Order_Line_Items__c , (Integer) o.Account.Subscription_Pending_Payments__c , o.accountId, false));

        test.stopTest();
        
        
        
    }
}