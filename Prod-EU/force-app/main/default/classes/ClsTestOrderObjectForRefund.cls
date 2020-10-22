@isTest
public class ClsTestOrderObjectForRefund {
	
     @isTest static void TestOrderCreationAndUpdateStndRefund(){
        
        Test.startTest();
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CH Consumer', 'Switzerland');
        //
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CH Cash'});
        String customPricebookId = customPricebookMap.get('CH Cash');
        
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
        
        Id rtIdFDCC = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
        Finance_Detail__c fd1= new Finance_Detail__c(Account__c=consumerAccts[0].Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='CHF',
                                                     Expiry_Date__c='1112/21', Primary__c=true,  RecordTypeId=rtIdFDCC);//CC_Address__c=lstAddress[0].id,
        insert fd1;
        
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
        newOrder.Status = 'Draft';
        newOrder.CC_Auth_Amount__c = 20;
        newOrder.Payment_Terms__c = 'net0';
        newOrder.Settlement_Id__c = '567899937227';
        newOrder.Finance_Detail__c = fd1.Id;
        insert newOrder;
        
        newOrder.Pricebook2Id = customPricebookId; 
        update newOrder;
        
        
        
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
        
        newOrder.Order_Cancellation_Reason__c = 'Cancelled in Fusion';       
        newOrder.Status = 'CANCELLED';
        update newOrder;
        test.stopTest();
        
        
    }
   
    @isTest static void TestOrderCreationAndUpdateRGARefund(){
                Test.startTest();
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CH Consumer', 'Switzerland');
        //
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CH Cash'});
        String customPricebookId = customPricebookMap.get('CH Cash');
        
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
        
        Id rtIdFDCC = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
        Finance_Detail__c fd1= new Finance_Detail__c(Account__c=consumerAccts[0].Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='CHF',
                                                     Expiry_Date__c='1112/21', Primary__c=true,  RecordTypeId=rtIdFDCC);//CC_Address__c=lstAddress[0].id,
        insert fd1;
        

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
        newOrder.Status = 'Draft';
        newOrder.CC_Auth_Amount__c = 20;
        newOrder.Payment_Terms__c = 'net0';
        newOrder.Settlement_Id__c = '567899937227';
        newOrder.Finance_Detail__c = fd1.Id;
        insert newOrder;
        
        newOrder.Pricebook2Id = customPricebookId; 
        update newOrder;
        
        
        
        //List order line items
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values()){
            OrderItem oi = new OrderItem();
            oi.OrderId = newOrder.Id;
            oi.PricebookEntryId = pbeId;
            oi.Quantity = 2;
            oi.UnitPrice = 225.00;
            oi.Tracking_Number__c = '12345';
            oi.Product_Name__c = 'STK-GF-109' ;
            orderItemList.add(oi);
        }
        insert orderItemList;
        
        //newOrder.Order_Cancellation_Reason__c = 'Cancelled in Fusion';       
        newOrder.Status = 'CLOSED';
        update newOrder;
        Test.stopTest();
        Order childOrder = new Order();
        childOrder.AccountId = consumerAccts[0].Id;
        childOrder.Type = 'CH RETURN & CREDIT';
        childOrder.Parent_Order__c =newOrder.Id;
        //childOrder.TotalAmount = 100;
        childOrder.Status = 'Draft';
        childOrder.RecordtypeId = chOrderRecdTypeId;
        childOrder.EffectiveDate = System.today();
        childOrder.Price_Book__c = customPricebookId;  
        childOrder.CC_Auth_Amount__c = 0;
        childOrder.Payment_Terms__c = 'net0';
        childOrder.Settlement_Id__c = '5367499937227';
        childOrder.Finance_Detail__c = fd1.Id;
         childOrder.Pricebook2Id = customPricebookId;
        insert childOrder;
        
       // update childOrder;
        List<OrderItem> childorderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values()){
            OrderItem oi = new OrderItem();
            oi.OrderId = childOrder.Id;
            oi.PricebookEntryId = pbeId;
            oi.Quantity = -2;
            oi.UnitPrice = 225.00;
            oi.Return_Reason__c = 'Customer did not order the item';
            oi.Tracking_Number__c = '12345';
            oi.Product_Name__c = 'STK-GF-109' ;
            childorderItemList.add(oi);
        }
        insert childorderItemList;
        childOrder.Status = 'CLOSED';
        update childOrder;
        
    }

}