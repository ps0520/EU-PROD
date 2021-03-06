@isTest
public class BClsSendDistributorSOAAtt_Test {
   @isTest static void TestOrderCreation(){
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'International Distributor', 'Korea');
        consumerAccts[0].Country__c = 'Korea';
        update consumerAccts;
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebookDIST(new List <String>{'DIST Pricebook'});
        String customPricebookId = customPricebookMap.get('DIST Pricebook');

        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'MT21255', 'STS-GS-002', 'DEX-SHIP-01'});
               
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet()){
            productIdToPriceMap.put(products.get(productName), 125.00);
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesDIST(productIdToPriceMap, customPricebookId);
		Id chOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('DIST_Sales_Order').getRecordTypeId();
        //Create Order record
		ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = consumerAccts[0].Id;
		newOrder.RecordtypeId = chOrderRecdTypeId;
        newOrder.Type = 'DIST STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;       
        newOrder.Status = 'Draft';
        newOrder.CurrencyIsoCode = 'USD';
        //newOrder.Invoice_Email_Status__c = 'Pending';
        //newOrder.Invoice_Number__c = '123456787';
        //newOrder.Warehouse__c = 'HLUK';
        insert newOrder;
       newOrder.Pricebook2Id = customPricebookId; 
       update newOrder;
            
         System.debug('**Curr--'+newOrder.CurrencyIsoCode);
       System.debug('**PB--'+productIdToPbeId.values());
        //List order line items
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values()) {
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
        newOrder.Status = 'Closed';
        update newOrder;
        test.startTest();    
              
        DataBase.executeBatch(new BClsSendDistributorSOAAtt(),1);
        
        test.stopTest();
        
        
        
    }
}