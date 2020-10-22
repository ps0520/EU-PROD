/*
@Author        : Kumar Navneet
@Date Created    : 22/04/2020
@Description    : Test class for BClsSendSdocInvoiceEmailIntlClinical Batch class 
****************************************************************************************/
@isTest()
private class BClsSendSdocInvoiceEmailIntlClinicalTest {
    @isTest static void TestOrderCreation(){
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'INTL Clinical', 'Korea');
        consumerAccts[0].Email_Invoice_Opt_In__c = true;
        update consumerAccts;
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'Pricebook'});
        String customPricebookId = customPricebookMap.get('Pricebook');

        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'MT21255', 'STS-GS-002', 'DEX-SHIP-01'});
               
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
        {
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, customPricebookId);
		Id chOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('International_Clinic_Sales_Order').getRecordTypeId();
        //Create Order record
		ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = consumerAccts[0].Id;
		newOrder.RecordtypeId = chOrderRecdTypeId;
        newOrder.Type = 'CLINICAL NON-COMMERCIAL';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;       
        newOrder.Status = 'Draft';
        newOrder.Invoice_Email_Status__c = 'Pending';
        newOrder.Invoice_Number__c = '123456787';
        newOrder.Warehouse__c = 'HLUK';
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
            oi.Product_Name__c = 'STS-GS-002' ;
            orderItemList.add(oi);
        }
        insert orderItemList;
        
        
        test.startTest();    
              
        DataBase.executeBatch(new BClsSendSdocInvoiceEmailIntlClinical('CLINICAL'),1);
        
        test.stopTest();
        
        
        
    }
}