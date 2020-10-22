/********************************************************************************
@Description    : Test CH QR Bill Functionality
*********************************************************************************/
@isTest
private class ClsTestBClsGenerateQRBill {
    @isTest static void TestOrderCreationAndUpdateCH(){
        Test.startTest();
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CH Consumer', 'Switzerland');
        //Populate the Account Number
        consumerAccts[0].AccountNumber = '123456';
        update consumerAccts[0];
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
        newOrder.Generate_QR_Bill__c = true;
        newOrder.Invoice_Number__c = '1234567';
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
        
        //Update tracking number information
        ClsOrderTriggerStaticClass.isExecuting = false;
        OrderItem newOrderItem = [SELECT Id, Tracking_Number__c,Product_Name__c FROM OrderItem WHERE Id = : orderItemList[0].Id];
        system.debug('********product name is ' +newOrderItem.Product_Name__c);
        newOrderItem.Tracking_Number__c = '123456|10';
        newOrderItem.Serial_Number__c = 'SM1236547';
        update newOrderItem;
        Test.SetMock(HttpCallOutMock.class, new ClsMockQRCodeGenerator());
        BClsGenerateQRBill batchClass = new BClsGenerateQRBill('SELECT Id, Preferred_Language__c, Total_Gross_Price__c, CurrencyIsoCode, Payor__r.Name, Account.Name, Account.AccountNumber, AccountId, BillingStreet, BillingCity, BillingPostalCode, BillingCountryCode, Invoice_Number__c, Invoice_Date__c, Payor__c, Customer_Bill_To_Address__r.Address_Line_2__c, Format_Total_Gross_Price__c FROM Order Where Generate_QR_Bill__c = true');
        Database.executebatch(batchClass, 1);
        Test.stopTest();       
    }
}