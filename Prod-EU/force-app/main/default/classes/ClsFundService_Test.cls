@isTest
public class ClsFundService_Test {
   /* 
     @isTest static void TestOrderCreationAndUpdateCA(){
        Test.startTest();
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Payor', 'Canada')[0];

        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CA Cash'});
        String customPricebookId = customPricebookMap.get('CA Cash');
         
         //payorAccount.Price_Book__c = customPricebookId;
         //update payorAccount;
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'DEX-SHIP-01','FREIGHT CHARGE'});
        
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
         payorAccount.Price_Book__c = customPricebookId;   
         update payorAccount ; 
         
         //Create new Benefit and associate it to the payor
        Benefit__c primaryBenefit = new Benefit__c();
        primaryBenefit.RecordTypeId = caOppRecType;
        primaryBenefit.Account__c = consumerAccts[0].Id;
        primaryBenefit.Member_Id__c = '1789657890';
        primaryBenefit.Payor__c =payorAccount.Id;
        primaryBenefit.Benefit_Hierarchy__c = 'Primary';
        insert primaryBenefit;
        
       Recordtype recType=[select id from recordtype where developername='Purchase_Order'];
        Fund__c Fd = new Fund__c();
        Fd.PO_Reference_Number__c ='87666787';
        Fd.Limit_Type__c ='Quantity';        
        Fd.Payor__c = payorAccount.Id;
        Fd.Amount_Limit__c = 100000;
        Fd.Auth_End_Date__c = Date.today()+10;
        Fd.Auth_Start_Date__c = Date.today();
        Fd.Receiver_Qty_Limit__c = 100; 
        Fd.Sensor_Limit__c = 100; 
        Fd.Transmitter_Qty_Limit__c = 100 ;     
        fd.recordtypeid=recType.id;
       // fd.Is_Fund_Active__c = true;
        insert Fd ;  
  		System.debug('**fd---'+fd);
         
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
         newOrder.Fund__c = fd.Id;
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
            oi.Product_Name__c = 'STK-GF-109' ;
            orderItemList.add(oi);
        }
        insert orderItemList;
        
         ClsFundService.getPONumber(fd.Id);
         clsFundService.checkFundBalance(newOrder.Id);  
         ClsFundService.chargeFund(newOrder.Id);
        Test.stopTest();
    }
	*/
}