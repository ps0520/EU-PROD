/*
@Author        : Kumar Navneet
@Date Created    : 22/04/2020
@Description    : Test class for BClsSendSdocInvoiceEmail Batch class 
****************************************************************************************/
@isTest()
private class BClsSendSdocInvoiceEmailTest {
    @isTest static void TestOrderCreation(){
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'IE Consumer', 'Ireland');
        consumerAccts[0].Email_Invoice_Opt_In__c = true;
        update consumerAccts;
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'IE Pricebook'});
        String customPricebookId = customPricebookMap.get('IE Pricebook');

        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'MT21255', 'STS-GS-002', 'DEX-SHIP-01'});
               
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
        {
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, customPricebookId);
		Id chOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('IE_Sales_Order').getRecordTypeId();
        //Create Order record
		ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = consumerAccts[0].Id;
		newOrder.RecordtypeId = chOrderRecdTypeId;
        newOrder.Type = 'IE STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;       
        newOrder.Status = 'Draft';
        newOrder.Invoice_Email_Status__c = 'Pending';
        newOrder.Invoice_Number__c = '123456787';
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
        
        Id oppRecTypeIE = [Select Id from RecordType Where isActive = true AND DeveloperName = 'IE_Opportunity'].id;
        Opportunity newOppIE = new Opportunity();
        newOppIE.RecordTypeId = oppRecTypeIE;
        newOppIE.Name = 'New Opportunity For Testing';
        newOppIE.CurrencyIsoCode = 'EUR';
        newOppIE.AccountId = consumerAccts[0].Id;
        newOppIE.Type = 'New';
        newOppIE.Contact_Letter_Sent__c = true;
        newOppIE.Contact_Doc_Received__c = true;
        newOppIE.Insurance_Doc_Received__c = true;
        newOppIE.Hard_Copy_Out__c = true;
        newOppIE.Hard_Copy_In__c = true;
        newOppIE.Training_Letter_Sent__c = true;
        newOppIE.Training_Letter_Sent_Date__c = Date.Today();
        newOppIE.StageName = 'New Opportunity';
        newOppIE.Training_Date__c = Date.today()+3;
        newOppIE.Doc_Collection_Status__c = 'Docs On File - Pending' ;        
        newOppIE.Email_Stage__c = null ; 
        newOppIE.DexTracker_Email__c = 'Yes';
        newOppIE.Consumer_Email__c = 'Tesdt@gmail.com';     
        newOppIE.CloseDate = Date.Today().addDays(30);
        newOppIE.Pricebook2Id = customPricebookId;
        insert newOppIE;
        
        test.startTest();
      //  ClsSendContractForGBIEOpp sh1 = new ClsSendContractForGBIEOpp(newOppIE.id, 'IE');
      //    String sch = '0 0 23 * * ?'; system.schedule('Test Check', sch, sh1); 
              
        DataBase.executeBatch(new BClsSendSdocInvoiceEmail('IE'),1);
        test.stopTest();
        
        
        
    }
}