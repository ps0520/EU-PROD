@isTest
global class ClsEBSTaxCalculator_Test {
     @isTest static void TestOrderCreationAndUpdateCA(){
       
       // Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator1(200));
      
         //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        Id caAddRecType = Schema.SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
         Address__c a = new Address__c();
         a.RecordTypeId = caAddRecType;
         a.Account__c = consumerAccts[0].Id;
         a.Type__c = 'Ship To';
         a.Address_Line_1__c = '10 Main Street';
         a.City__c = 'Victoria';
         a.Postal_Code__c = 'V5Z 2M9';
         a.State__c = 'British Columbia';
         a.Primary_Flag__c = true;
         a.Country__c = 'Canada';
         insert a;
        
        Address__c billTo = [Select id,name,Account__c,type__c from Address__c where Account__c=:consumerAccts[0].Id and type__c=:'Bill To' ]; 
         System.debug('*billTo--'+billTo);
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CA Cash'});
        String customPricebookId = customPricebookMap.get('CA Cash');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004','FREIGHT CHARGE'});//Freght Chag
                
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet()){
            productIdToPriceMap.put(products.get(productName), 125.00);            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
       
        
        //Create Order record
         ClsOrderTriggerStaticClass.isExecuting = false;
         Order newOrder = new Order();
         newOrder.AccountId = consumerAccts[0].Id;
         newOrder.RecordtypeId = caOrderRecdTypeId;
         newOrder.Type = 'CA STANDARD';
         newOrder.EffectiveDate = System.today();
         newOrder.Price_Book__c = customPricebookId;
         newOrder.Pricebook2Id = customPricebookId; 
         newOrder.Status = 'Draft';
         newOrder.CurrencyIsoCode ='CAD';
         newOrder.Customer_Ship_To_Address__c = a.Id;
         newOrder.Customer_Bill_To_Address__c = billTo.Id;
         
        insert newOrder;        
        
        //List order line items
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values()){
            OrderItem oi = new OrderItem();
            oi.OrderId = newOrder.Id;
            oi.PricebookEntryId = pbeId;
            oi.Quantity = 1;
            oi.UnitPrice = 125.00;
            oi.Tracking_Number__c = '12345';
            oi.Product_Name__c = 'STK-GF-013' ;
            orderItemList.add(oi);
        }
        insert orderItemList;
        
         Order ord = [SELECT TotalAmount, Type, Shipping_Charges__c, Id, Count_of_Order_Line_Items__c, Need_To_Calculate_Tax__c, Tax_Exempt__c, Tax_Registration_Number__c, Payor__c, Payor_Bill_To_Address__c,
                   Customer_Bill_To_Address__r.Account__c, Customer_Bill_To_Address__c, Customer_Ship_To_Address__r.Account__c, Customer_Ship_To_Address__c,
                   Customer_Ship_To_Address__r.Country__c, Warehouse__c, CurrencyIsoCode, OrderNumber, Payor__r.Tax_Registration_Number__c, Payor__r.Tax_Exempt__c,
                   Payor_Bill_To_Address__r.Country__c,Customer_Bill_To_Address__r.CurrencyIsoCode, CA_GST_Tax_Rate__c,CA_PST_Tax_Rate__c, 
                   System_Of_Origin__c,Customer_Ship_To_Address__r.State__c,Customer_Ship_To_Address__r.CurrencyIsoCode,
                   (SELECT Id, Unitprice, Quantity,Product_Name__c,CA_GST_Tax_Amount__c,CA_PST_Tax_Amount__c,Parent_Order_Line_Id__c,
                    TotalPrice FROM OrderItems) 
                   FROM Order WHERE Id = :newOrder.Id];
         String JsonRequest=Json.serialize(new ClsCAEBSReqTaxCalculation.RequestWrapper(ord), true).replace('"CurrencyCode"','"Currency"');
         Map<String,String> mapHeader = new Map<String,String>();
         mapHeader.put('Content-Type', 'application/json');
         String OrderLineId =String.valueOf(orderItemList[0].Id);
         ClsTestCATaxMockService mock = new ClsTestCATaxMockService(200, 'OK', JsonRequest,mapHeader,OrderLineId);
	     Test.setMock(HttpCalloutMock.class, mock);         
        Test.startTest();
         ClsOUSTaxCalculator.calculateTax(newOrder.Id);
        Test.stopTest();
    }
     @isTest static void TestEBSException(){
       
       // Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator1(200));
      
         //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        Id caAddRecType = Schema.SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
         Address__c a = new Address__c();
         a.RecordTypeId = caAddRecType;
         a.Account__c = consumerAccts[0].Id;
         a.Type__c = 'Ship To';
         a.Address_Line_1__c = '10 Main Street';
         a.City__c = 'Victoria';
         a.Postal_Code__c = 'V5Z 2M9';
         a.State__c = 'British Columbia';
         a.Primary_Flag__c = true;
         a.Country__c = 'Canada';
         insert a;
        
        Address__c billTo = [Select id,name,Account__c,type__c from Address__c where Account__c=:consumerAccts[0].Id and type__c=:'Bill To' ]; 
         System.debug('*billTo--'+billTo);
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CA Cash'});
        String customPricebookId = customPricebookMap.get('CA Cash');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004','FREIGHT CHARGE'});//Freght Chag
                
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet()){
            productIdToPriceMap.put(products.get(productName), 125.00);            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
       
        
        //Create Order record
         ClsOrderTriggerStaticClass.isExecuting = false;
         Order newOrder = new Order();
         newOrder.AccountId = consumerAccts[0].Id;
         newOrder.RecordtypeId = caOrderRecdTypeId;
         newOrder.Type = 'CA STANDARD';
         newOrder.EffectiveDate = System.today();
         newOrder.Price_Book__c = customPricebookId;
         newOrder.Pricebook2Id = customPricebookId; 
         newOrder.Status = 'Draft';
         newOrder.CurrencyIsoCode ='CAD';
         newOrder.Customer_Ship_To_Address__c = a.Id;
         newOrder.Customer_Bill_To_Address__c = billTo.Id;
         
        insert newOrder;        
        
        //List order line items
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values()){
            OrderItem oi = new OrderItem();
            oi.OrderId = newOrder.Id;
            oi.PricebookEntryId = pbeId;
            oi.Quantity = 1;
            oi.UnitPrice = 125.00;
            oi.Tracking_Number__c = '12345';
            oi.Product_Name__c = 'STK-GF-013' ;
            orderItemList.add(oi);
        }
        insert orderItemList;
        
         Order ord = [SELECT TotalAmount, Type, Shipping_Charges__c, Id, Count_of_Order_Line_Items__c, Need_To_Calculate_Tax__c, Tax_Exempt__c, Tax_Registration_Number__c, Payor__c, Payor_Bill_To_Address__c,
                   Customer_Bill_To_Address__r.Account__c, Customer_Bill_To_Address__c, Customer_Ship_To_Address__r.Account__c, Customer_Ship_To_Address__c,
                   Customer_Ship_To_Address__r.Country__c, Warehouse__c, CurrencyIsoCode, OrderNumber, Payor__r.Tax_Registration_Number__c, Payor__r.Tax_Exempt__c,
                   Payor_Bill_To_Address__r.Country__c,Customer_Bill_To_Address__r.CurrencyIsoCode, CA_GST_Tax_Rate__c,CA_PST_Tax_Rate__c, 
                   System_Of_Origin__c,Customer_Ship_To_Address__r.State__c,Customer_Ship_To_Address__r.CurrencyIsoCode,
                   (SELECT Id, Unitprice, Quantity,Product_Name__c,CA_GST_Tax_Amount__c,CA_PST_Tax_Amount__c,Parent_Order_Line_Id__c,
                    TotalPrice FROM OrderItems) 
                   FROM Order WHERE Id = :newOrder.Id];
         String JsonRequest=Json.serialize(new ClsCAEBSReqTaxCalculation.RequestWrapper(ord), true).replace('"CurrencyCode"','"Currency"');
         Map<String,String> mapHeader = new Map<String,String>();
         mapHeader.put('Content-Type', 'application/json');
         String OrderLineId =String.valueOf(orderItemList[0].Id);
        // HttpMockFactory mock = new HttpMockFactory(200, 'OK', JsonRequest,mapHeader,OrderLineId);
         ClsTestCATaxMockService mockFail = new ClsTestCATaxMockService(200, 'OK', JsonRequest,mapHeader,OrderLineId,'');
	     Test.setMock(HttpCalloutMock.class, mockFail);         
        Test.startTest();
         ClsOUSTaxCalculator.calculateTax(newOrder.Id);
        Test.stopTest();
    }
}