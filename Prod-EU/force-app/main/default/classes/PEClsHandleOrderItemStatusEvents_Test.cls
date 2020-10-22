@isTest
private class PEClsHandleOrderItemStatusEvents_Test {
    public static id TestOrderCreationAndUpdate(){
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');

        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CA Cash'});
        String customPricebookId = customPricebookMap.get('CA Cash');

        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'VIRTUAL_SKU', 'DEX-SHIP-01'});
        
        //Update the virtual sku productIdToPbeId
        Product2 virtualProd = [SELECT Id, Is_Virtual_Product__c FROM Product2 WHERE NAME = 'DEX-SHIP-01'];
        virtualProd.Is_Virtual_Product__c = true;
        update virtualProd;
        
        //Update the virtual sku productIdToPbeId
        virtualProd = [SELECT Id, Is_Virtual_Product__c FROM Product2 WHERE NAME = 'VIRTUAL_SKU'];
        virtualProd.Is_Virtual_Product__c = true;
        update virtualProd;
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
        {
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, customPricebookId);
        
        //Create Order record
        ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = consumerAccts[0].Id;
        newOrder.Type = 'CA STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;
        //newOrder.Pricebook2Id = customPricebookId;//added by Shailendra to resolve the issue..
        newOrder.Status = 'Draft';
        newOrder.CurrencyIsoCode = 'EUR';
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
        return orderItemList[0].Id;
    }
    @isTest 
    private static void testPositiveOIUpdate() {
        Id oid = TestOrderCreationAndUpdate();
        ClsOrderTriggerStaticClass.isExecuting = false;
        OrderItem newOrderItem = [SELECT Id, Tracking_Number__c,Product_Name__c FROM OrderItem WHERE Id = : oid];
        system.debug('********product name is ' +newOrderItem.Product_Name__c);
        CRM_OrderItemStatus_Event__e  ae = new CRM_OrderItemStatus_Event__e( );
        ae.version__c = '1.0';
        ae.eventDate__c =  String.valueOf(System.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        ae.entityType__c = 'orderItemStatus';
        ae.eventSource__c = 'oms';
        ae.eventSourceID__c = newOrderItem.Id;
        ae.operation__c = 'update';
        ae.stage__c = 'pending';
        //ae.systemOfOrigin__c = a.order.System_Of_Origin__c;
        //ae.systemOfOriginID__c = a.order.System_Of_Origin_Id__c;
        //ae.parentSystemOfOriginID__c = '';   
        //ae.author__c = a.LastModifiedBy.Name;
        ae.status__c = 'shipped';
        //ae.orderNumber__c = a.order.OrderNumber;
        ae.itemID__c = newOrderItem.Id;
        ae.trackingNumber__c = '123456|10';
        //ae.deliveryNumber__c = a.Delivery_Number__c;
        //ae.shippedDate__c = String.valueOf(a.Actual_Ship_Date__c);
        //ae.shippedQuantity__c = a.Shipped_Qty__c;
        ae.serialNumbers__c = 'SM1236547';
        //ae.lotNumber__c = a.Lot_Number__c;
        //ae.lotExpirationDate__c = a.Lot_Expiration_Date__c;
        
        Test.startTest();
            // Publish test event
            Database.SaveResult sr = EventBus.publish(ae);
        Test.stopTest();
       // acts = [SELECT Id FROM Account where middlename = 'New'];
        //System.assertEquals(1, acts.size());
        OrderItem oir = [Select Id, Tracking_Number__c, Serial_Number__c from OrderItem where id = :newOrderItem.Id Limit 1];
        system.debug('Org Tracking Number: 123456|10, Result: ' + oir.Tracking_Number__c + ', Original Serial Number: SM1236547, Result: ' + oir.Serial_Number__c);
        system.assertEquals('123456|10', oir.Tracking_Number__c);
        system.assertEquals('SM1236547', oir.Serial_Number__c);

    }
    @isTest 
    private static void testSelfOIUpdate() {
        Id oid = TestOrderCreationAndUpdate();
        ClsOrderTriggerStaticClass.isExecuting = false;
        OrderItem newOrderItem = [SELECT Id, Tracking_Number__c,Product_Name__c FROM OrderItem WHERE Id = : oid];
        system.debug('********product name is ' +newOrderItem.Product_Name__c);
        CRM_OrderItemStatus_Event__e  ae = new CRM_OrderItemStatus_Event__e( );
        ae.version__c = '1.0';
        ae.eventDate__c =  String.valueOf(System.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        ae.entityType__c = 'orderItemStatus';
        ae.eventSource__c = 'crm';
        ae.eventSourceID__c = newOrderItem.Id;
        ae.operation__c = 'update';
        ae.stage__c = 'pending';
        //ae.systemOfOrigin__c = a.order.System_Of_Origin__c;
        //ae.systemOfOriginID__c = a.order.System_Of_Origin_Id__c;
        //ae.parentSystemOfOriginID__c = '';   
        //ae.author__c = a.LastModifiedBy.Name;
        ae.status__c = 'shipped';
        //ae.orderNumber__c = a.order.OrderNumber;
        ae.itemID__c = newOrderItem.Id;
        ae.trackingNumber__c = '123456|10';
        //ae.deliveryNumber__c = a.Delivery_Number__c;
        //ae.shippedDate__c = String.valueOf(a.Actual_Ship_Date__c);
        //ae.shippedQuantity__c = a.Shipped_Qty__c;
        ae.serialNumbers__c = 'SM1236547';
        //ae.lotNumber__c = a.Lot_Number__c;
        //ae.lotExpirationDate__c = a.Lot_Expiration_Date__c;
        
        Test.startTest();
            // Publish test event
            Database.SaveResult sr = EventBus.publish(ae);
        Test.stopTest();
       // acts = [SELECT Id FROM Account where middlename = 'New'];
        //System.assertEquals(1, acts.size());
        OrderItem oir = [Select Id, Tracking_Number__c, Serial_Number__c from OrderItem where id = :newOrderItem.Id Limit 1];
        system.assertEquals('12345', oir.Tracking_Number__c);
        system.assertEquals(null, oir.Serial_Number__c);
    }
    @isTest 
    private static void testIncorrectSourceOIUpdate() {
        Id oid = TestOrderCreationAndUpdate();
        ClsOrderTriggerStaticClass.isExecuting = false;
        OrderItem newOrderItem = [SELECT Id, Tracking_Number__c,Product_Name__c FROM OrderItem WHERE Id = : oid];
        system.debug('********product name is ' +newOrderItem.Product_Name__c);
        CRM_OrderItemStatus_Event__e  ae = new CRM_OrderItemStatus_Event__e( );
        ae.version__c = '1.0';
        ae.eventDate__c =  String.valueOf(System.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        ae.entityType__c = 'orderItemStatus';
        ae.eventSource__c = 'ts';
        ae.eventSourceID__c = newOrderItem.Id;
        ae.operation__c = 'update';
        ae.stage__c = 'pending';
        //ae.systemOfOrigin__c = a.order.System_Of_Origin__c;
        //ae.systemOfOriginID__c = a.order.System_Of_Origin_Id__c;
        //ae.parentSystemOfOriginID__c = '';   
        //ae.author__c = a.LastModifiedBy.Name;
        ae.status__c = 'shipped';
        //ae.orderNumber__c = a.order.OrderNumber;
        ae.itemID__c = newOrderItem.Id;
        ae.trackingNumber__c = '123456|10';
        //ae.deliveryNumber__c = a.Delivery_Number__c;
        //ae.shippedDate__c = String.valueOf(a.Actual_Ship_Date__c);
        //ae.shippedQuantity__c = a.Shipped_Qty__c;
        ae.serialNumbers__c = 'SM1236547';
        //ae.lotNumber__c = a.Lot_Number__c;
        //ae.lotExpirationDate__c = a.Lot_Expiration_Date__c;
        
        Test.startTest();
            // Publish test event
            Database.SaveResult sr = EventBus.publish(ae);
        Test.stopTest();
       // acts = [SELECT Id FROM Account where middlename = 'New'];
        //System.assertEquals(1, acts.size());
        OrderItem oir = [Select Id, Tracking_Number__c, Serial_Number__c from OrderItem where id = :newOrderItem.Id Limit 1];
        system.assertEquals('12345', oir.Tracking_Number__c);
        system.assertEquals(null, oir.Serial_Number__c);
    }
    @isTest 
    private static void testNullIdOIUpdate() {
        Id oid = TestOrderCreationAndUpdate();
        ClsOrderTriggerStaticClass.isExecuting = false;
        OrderItem newOrderItem = [SELECT Id, Tracking_Number__c,Product_Name__c FROM OrderItem WHERE Id = : oid];
        system.debug('********product name is ' +newOrderItem.Product_Name__c);
        CRM_OrderItemStatus_Event__e  ae = new CRM_OrderItemStatus_Event__e( );
        ae.version__c = '1.0';
        ae.eventDate__c =  String.valueOf(System.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        ae.entityType__c = 'orderItemStatus';
        ae.eventSource__c = 'oms';
        ae.eventSourceID__c = newOrderItem.Id;
        ae.operation__c = 'update';
        ae.stage__c = 'pending';
        //ae.systemOfOrigin__c = a.order.System_Of_Origin__c;
        //ae.systemOfOriginID__c = a.order.System_Of_Origin_Id__c;
        //ae.parentSystemOfOriginID__c = '';   
        //ae.author__c = a.LastModifiedBy.Name;
        ae.status__c = 'shipped';
        //ae.orderNumber__c = a.order.OrderNumber;
        ae.itemID__c = 'null';
        ae.trackingNumber__c = '123456|10';
        //ae.deliveryNumber__c = a.Delivery_Number__c;
        //ae.shippedDate__c = String.valueOf(a.Actual_Ship_Date__c);
        //ae.shippedQuantity__c = a.Shipped_Qty__c;
        ae.serialNumbers__c = 'SM1236547';
        //ae.lotNumber__c = a.Lot_Number__c;
        //ae.lotExpirationDate__c = a.Lot_Expiration_Date__c;
        
        Test.startTest();
            // Publish test event
            Database.SaveResult sr = EventBus.publish(ae);
        Test.stopTest();
       // acts = [SELECT Id FROM Account where middlename = 'New'];
        //System.assertEquals(1, acts.size());
        OrderItem oir = [Select Id, Tracking_Number__c, Serial_Number__c from OrderItem where id = :newOrderItem.Id Limit 1];
        system.assertEquals('12345', oir.Tracking_Number__c);
        system.assertEquals(null, oir.Serial_Number__c);
    }
    @isTest 
    private static void testIncorrectIdOIUpdate() {
        Id oid = TestOrderCreationAndUpdate();
        ClsOrderTriggerStaticClass.isExecuting = false;
        OrderItem newOrderItem = [SELECT Id, Tracking_Number__c,Product_Name__c FROM OrderItem WHERE Id = : oid];
        system.debug('********product name is ' +newOrderItem.Product_Name__c);
        CRM_OrderItemStatus_Event__e  ae = new CRM_OrderItemStatus_Event__e( );
        ae.version__c = '1.0';
        ae.eventDate__c =  String.valueOf(System.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        ae.entityType__c = 'orderItemStatus';
        ae.eventSource__c = 'oms';
        ae.eventSourceID__c = newOrderItem.Id;
        ae.operation__c = 'update';
        ae.stage__c = 'pending';
        //ae.systemOfOrigin__c = a.order.System_Of_Origin__c;
        //ae.systemOfOriginID__c = a.order.System_Of_Origin_Id__c;
        //ae.parentSystemOfOriginID__c = '';   
        //ae.author__c = a.LastModifiedBy.Name;
        ae.status__c = 'shipped';
        //ae.orderNumber__c = a.order.OrderNumber;
        ae.itemID__c = '8019E0000015Ye9QAE';
        ae.trackingNumber__c = '123456|10';
        //ae.deliveryNumber__c = a.Delivery_Number__c;
        //ae.shippedDate__c = String.valueOf(a.Actual_Ship_Date__c);
        //ae.shippedQuantity__c = a.Shipped_Qty__c;
        ae.serialNumbers__c = 'SM1236547';
        //ae.lotNumber__c = a.Lot_Number__c;
        //ae.lotExpirationDate__c = a.Lot_Expiration_Date__c;
        
        Test.startTest();
            // Publish test event
            Database.SaveResult sr = EventBus.publish(ae);
        Test.stopTest();
       // acts = [SELECT Id FROM Account where middlename = 'New'];
        //System.assertEquals(1, acts.size());
        OrderItem oir = [Select Id, Tracking_Number__c, Serial_Number__c from OrderItem where id = :newOrderItem.Id Limit 1];
        system.assertEquals('12345', oir.Tracking_Number__c);
        system.assertEquals(null, oir.Serial_Number__c);
    }   
     @isTest 
    private static void testIncorrectOrderIdOIUpdate() {
        Id oid = TestOrderCreationAndUpdate();
        ClsOrderTriggerStaticClass.isExecuting = false;
        OrderItem newOrderItem = [SELECT Id, Tracking_Number__c,Product_Name__c FROM OrderItem WHERE Id = : oid];
        system.debug('********product name is ' +newOrderItem.Product_Name__c);
        CRM_OrderItemStatus_Event__e  ae = new CRM_OrderItemStatus_Event__e( );
        ae.version__c = '1.0';
        ae.eventDate__c =  String.valueOf(System.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        ae.entityType__c = 'orderItem';
        ae.eventSource__c = 'oms';
        ae.eventSourceID__c = newOrderItem.Id;
        ae.operation__c = 'update';
        ae.stage__c = 'pending';
        //ae.systemOfOrigin__c = a.order.System_Of_Origin__c;
        //ae.systemOfOriginID__c = a.order.System_Of_Origin_Id__c;
        //ae.parentSystemOfOriginID__c = '';   
        //ae.author__c = a.LastModifiedBy.Name;
        ae.status__c = 'shipped';
        ae.orderNumber__c = '8019E0000015Ye9QAE';
        ae.itemID__c = newOrderItem.Id;
        ae.trackingNumber__c = '123456|10';
        //ae.deliveryNumber__c = a.Delivery_Number__c;
        //ae.shippedDate__c = String.valueOf(a.Actual_Ship_Date__c);
        //ae.shippedQuantity__c = a.Shipped_Qty__c;
        ae.serialNumbers__c = 'SM1236547';
        //ae.lotNumber__c = a.Lot_Number__c;
        //ae.lotExpirationDate__c = a.Lot_Expiration_Date__c;
        
        Test.startTest();
            // Publish test event
            Database.SaveResult sr = EventBus.publish(ae);
        Test.stopTest();
       // acts = [SELECT Id FROM Account where middlename = 'New'];
        //System.assertEquals(1, acts.size());
        OrderItem oir = [Select Id, Tracking_Number__c, Serial_Number__c from OrderItem where id = :newOrderItem.Id Limit 1];
        system.assertEquals('123456|10', oir.Tracking_Number__c);
        system.assertEquals('SM1236547', oir.Serial_Number__c);
    }
        @isTest 
    private static void testItemStatusPublish() {
        Id oid = TestOrderCreationAndUpdate();
        ClsOrderTriggerStaticClass.isExecuting = false;
        PEClsHandleBatchOrderItemStatusEvents.publishOrderItemUpdate(new Set<Id>{oid}, 'update');
    }
}