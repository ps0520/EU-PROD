/*******************************************************************************************
@Author        : kumar navneet
@Date Created    : 04/23/2020
@Description    : Test class to test the ClsOrderBasedAutomation

*********************************************************************************************/
@isTest
private class ClsOrderBasedAutomationTest {
    
    
    @isTest static void TestOrder(){
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'International Distributor', 'Netherlands');

        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebookDIST(new List <String>{'DIST Pricebook', 'DIST Pricebook1'});        
        String customPricebookId1 = customPricebookMap.get('DIST Pricebook1');
        String customPricebookId = customPricebookMap.get('DIST Pricebook');

        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'MT21255', 'STS-GS-002', 'DEX-SHIP-01'});
               
        //Create Pricebook EntryPair    
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
        {
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesDIST(productIdToPriceMap, customPricebookId);
        ClsTestDataFactory.createCustomPricebookEntriesDIST(productIdToPriceMap, customPricebookId1);
		Id chOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('DIST_Sales_Order').getRecordTypeId();
        
        List<PriceBook2> currentPBList = new List<PriceBook2>();
        for(Pricebook2 p2:[Select Id,Name, Future_Order_Gap__c, Future_Order_Price_Book__c from PriceBook2 ]){
            if(p2.Name == 'DIST Pricebook')
            {
                p2.Future_Order_Gap__c = 1 ;
                p2.Future_Order_Price_Book__c = 'DIST Pricebook1' ;                
                
                currentPBList.add(p2);                
            }            
        }
        update currentPBList ;
        
        List<PriceBookEntry> cuPBList = new List<PriceBookEntry>();
        for(PriceBookEntry pb:[Select Id, Pricebook2Id, Optional_Subscription_Item__c  from PriceBookEntry ]){
            pb.Optional_Subscription_Item__c =false ; 
            pb.SSIP_Periodic_Order_Quantity__c = 1;
            pb.SSIP_Next_Order_In_Days__c = 1 ;
            cuPBList.add(pb);
        }
        update cuPBList ; 
        
        
        //Create Order record
		ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = consumerAccts[0].Id;
		newOrder.RecordtypeId = chOrderRecdTypeId;
        newOrder.Type = 'DIST STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;       
        newOrder.Status = 'Draft';
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
            oi.Product_Name__c = 'STS-GS-002' ;
            orderItemList.add(oi);
        }
        insert orderItemList;

        List<order> ordList = new List<order>();
        ordList.add(newOrder);
        Test.startTest();
       
        ClsOrderBasedAutomation.createFutureOrderAndSSIPRules(ordList);     
        
        
       
        Test.stopTest();
        
        
    }
    
    
}