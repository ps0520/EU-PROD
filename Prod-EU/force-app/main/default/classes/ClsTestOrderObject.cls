/********************************************************************************
@Author         : Jagan Periyakaruppan
@Date Created   : 03/07/2018
@Description    : Test class to test the Order Functionality
*********************************************************************************/
@isTest
private class ClsTestOrderObject {
    @isTest static void TestOrderCreationAndUpdate(){
         
        Test.startTest();
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Consumer', 'Germany'); 
        
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'DE Netto-Preis Cash'});
        String customPricebookId = customPricebookMap.get('DE Netto-Preis Cash');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'DEX-SHIP-01'});
        
        //Update the virtual sku productIdToPbeId
        Product2 virtualProd = [SELECT Id, Is_Virtual_Product__c FROM Product2 WHERE NAME = 'DEX-SHIP-01'];
        virtualProd.Is_Virtual_Product__c = true;
        update virtualProd;
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet()) {
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, customPricebookId);
        Id deOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('DE_Sales_Order').getRecordTypeId();
        //Create Order record
        ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = consumerAccts[0].Id;
        newOrder.RecordtypeId = deOrderRecdTypeId;
        newOrder.Type = 'DE STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;
        newOrder.Pricebook2Id = customPricebookId; //added by Shailendra to resolve the issue..
        newOrder.Status = 'Draft';
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
        
        //Update tracking number information
        ClsOrderTriggerStaticClass.isExecuting = false;
        OrderItem newOrderItem = [SELECT Id, Tracking_Number__c,Product_Name__c FROM OrderItem WHERE Id = : orderItemList[0].Id];
        system.debug('********product name is ' +newOrderItem.Product_Name__c);
        newOrderItem.Tracking_Number__c = '123456|10';
        newOrderItem.Serial_Number__c = 'SM1236547';
        update newOrderItem;
        delete orderItemList;
        Test.stopTest();
    }
    @isTest static void TestOrderCreationAndUpdateCA(){
        Test.startTest();
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'CA Cash'});
        String customPricebookId = customPricebookMap.get('CA Cash');
        
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
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
        
        Id caOppRecType = Schema.SObjectType.Benefit__c.getRecordTypeInfosByDeveloperName().get('CA_Benefit').getRecordTypeId();
           // [Select Id from RecordType where isActive = true AND SobjectType = 'Benefit__c' and DeveloperName = 'CA_Benefit'].Id;
        
         //Create new Benefit and associate it to the payor
        Benefit__c primaryBenefit = new Benefit__c();
        primaryBenefit.RecordTypeId = caOppRecType;
        primaryBenefit.Account__c = consumerAccts[0].Id;
        primaryBenefit.Member_Id__c = '1789657890';
       // primaryBenefit.Payor__c = accts[2].Id;
        primaryBenefit.Benefit_Hierarchy__c = 'Primary';
        insert primaryBenefit;
        
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
        List<Order> caOrders = new List<Order>() ;
        caOrders.add(newOrder);
        
        BPClsOrderHandler bpOrd = new BPClsOrderHandler();
      //  bpOrd.populateSubscriptionOrderItems(newOrder, PriceBook2 pbook) ;        
         bpOrd.tryToMatchAndUpdateOpportunities(caOrders);
        system.debug('********product name is ' +newOrderItem.Product_Name__c);
        newOrderItem.Tracking_Number__c = '123456|10';
        newOrderItem.Serial_Number__c = 'SM1236547';
        update newOrderItem;
        delete orderItemList;
        
        Test.stopTest();
    }
    @isTest static void TestOrderCreationAndUpdateCH(){
        Test.startTest();
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CH Consumer', 'Switzerland');
        
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
        delete orderItemList;
        Test.stopTest();
        
    }
    @isTest static void TestOrderCreationAndUpdateCH2(){
        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CH Consumer', 'Switzerland');
          Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CH Payor', 'Switzerland')[0];
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
            
            List<Address__c> lstAddress = new List<Address__c>{ 
                new Address__c(Account__c =consumerAccts[0].Id,Type__c = 'Bill To', Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                    new Address__c(Account__c = consumerAccts[0].Id,Type__c = 'Ship To',Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                    //new Address__c(Account__c = payorAccount.Id,Type__c = 'Bill To', Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                    // new Address__c(Account__c = payorAccount.Id,Type__c = 'Ship To',Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = ' W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                    };
                        insert lstAddress;
                        
                        Set<id> adSet=new Set<id>();
                        for(Address__c a:lstAddress){
                           adSet.add(a.id);
                        }
            
            Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCH(productIdToPriceMap, customPricebookId);
            Id rtIdFDCC = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
            Finance_Detail__c fd1= new Finance_Detail__c(Account__c=consumerAccts[0].Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='CHF',
                                                         Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=lstAddress[0].id, RecordTypeId=rtIdFDCC);
            insert fd1;
         Test.startTest();
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
            newOrder.Payment_Terms__c = 'net0';
            newOrder.Need_To_Calculate_Tax__c = 'false';
            
            insert newOrder;
            
            newOrder.Pricebook2Id = customPricebookId; 
            update newOrder;
        
            //List order line items
            List<SSIP_Rule__c> lstSSIPRule = new List<SSIP_Rule__c>();
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
        Test.stopTest();
        for(Id pbeId : productIdToPbeId.KeySet()){
            lstSSIPRule.add(new SSIP_Rule__c(Account__c = consumerAccts[0].Id, First_Order__c = newOrder.Id, Schedule_Count__c = 1, Frequency_In_Days__c = 30,
                                             First_Repeat_Order_Lead_Days__c = 7, Price_Book__c = customPricebookId, PriceBookEntryId__c = productIdToPbeId.get(pbeId),
                                             First_Shipment_Date__c = Date.today(),Rule_Re_schedule_Date__c = Date.today()+1,
                                             Product__c = pbeId, Quantity__c = 1, Shipping_Address__c = lstAddress[1].Id, Status__c = 'Active'));
            
        }
        
        //insert lstSSIPRule;
        //Update tracking number information
        ClsOrderTriggerStaticClass.isExecuting = false;
        OrderItem newOrderItem = [SELECT Id, Tracking_Number__c,Product_Name__c FROM OrderItem WHERE Id = : orderItemList[0].Id];
        system.debug('********product name is ' +newOrderItem.Product_Name__c);
        newOrderItem.Tracking_Number__c = '123456|10';
        newOrderItem.Serial_Number__c = 'SM1236547';
        update newOrderItem;
        // Temp Solution Provided - 
        List<Order> ordlst = new List<Order>();
        ordlst.add(newOrder);
        BPClsOrderHandler.autoCreateOppsOnOrderActivation(ordlst);
        // Temp Solution Provided End-
        newOrder.Payment_Id__c = '1234567';
        newOrder.CC_Auth_Amount__c = 1;
        
        newOrder.Status = 'Activated'; 
        update newOrder;
        BPClsOrderHandler.lockAddressesTiedToOrder(adSet);
        
    }
    @isTest static void TestOrderCreationAndUpdateDE(){
        
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCustomPricebook(new List<String>{'DE Netto-Preis Cash', 'DE Return Replace', 'Barmer'});
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'Product-01', 'Product-02', 'DEX-SHIP-01'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(Id productId : mapProduct.values()){
            productIdToPriceMap.put(productId, 10);
        }
        Map<Id, Id> mapPBE = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, mapPriceBook.get('DE Netto-Preis Cash'));
        Account objAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Consumer', 'Germany')[0];
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Payor', 'Germany')[0];
        Account payorAccount2 = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Payor', 'Germany')[0];
        
        Id AddId=[Select Id from RecordType Where sObjectType='Address__c' AND Name='DE Address' Limit 1].Id;
        
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = objAccount.Id,RecordTypeId = AddId, Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true),
                new Address__c(Account__c = objAccount.Id,RecordTypeId = AddId, Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = AddId, Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = AddId, Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true)
                };
                    insert lstAddress;
        Benefit__c primaryBenefit = new Benefit__c(Account__c = objAccount.Id, Member_Id__c = '1789657890', Payor__c = payorAccount.Id, Benefit_Hierarchy__c = 'Primary');
        insert primaryBenefit;
        Test.startTest();
        Opportunity newOpp = new Opportunity(Name = 'New Opportunity For Testing', AccountId = objAccount.Id, Benefit__c = primaryBenefit.Id,Type = 'Reorder', Consumer_Email__c = 'test@gmail.com',
                                             Payor__c = payorAccount.Id, Pricebook2Id = mapPriceBook.get('Barmer'), CloseDate = Date.Today().addDays(30),
                                             Contact_Letter_Sent__c = true, Contact_Doc_Received__c = true, Insurance_Doc_Received__c = true, Hard_Copy_Out__c = true,
                                             Hard_Copy_In__c = true, Training_Letter_Sent__c = true, Training_Letter_Sent_Date__c = Date.Today(), StageName = 'New Opportunity');
        insert newOpp;
        
        insert new BP_Process_Builder_Customization__c(Name = 'DE_Sales_Order', PriceBook__c = mapPriceBook.get('DE Return Replace'));
        Id deOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('DE_Sales_Order').getRecordTypeId();
        
        Order objOrder = new Order(AccountId = objAccount.Id,OpportunityId =newOpp.Id ,RecordtypeId=deOrderRecdTypeId, EffectiveDate = Date.today(), Status = 'Draft',Tech_Support_Order_Type__c = 'TECH REPLACE', Type = 'DE TECH RETURN', Payor__c = payorAccount.Id);
        insert objOrder;
        Test.stopTest();
    }
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
  
  
    @isTest static void TestOrderCreationAndUpdateCH2Exception(){
        
        Test.startTest();
        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CH Consumer', 'Switzerland');
        //Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CH Payor', 'Switzerland')[0];
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
            
            List<Address__c> lstAddress = new List<Address__c>{ 
                new Address__c(Account__c =consumerAccts[0].Id,Type__c = 'Bill To', Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                    new Address__c(Account__c = consumerAccts[0].Id,Type__c = 'Ship To',Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                    };
                        insert lstAddress;
            
            Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCH(productIdToPriceMap, customPricebookId);
            Id rtIdFDCC = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
            Finance_Detail__c fd1= new Finance_Detail__c(Account__c=consumerAccts[0].Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='CHF',
                                                         Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=lstAddress[0].id, RecordTypeId=rtIdFDCC);
            insert fd1;
           Id chOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CH_Sales_Order').getRecordTypeId();
           
            ClsOrderTriggerStaticClass.isExecuting = false;
            Order newOrder = new Order();
            newOrder.AccountId = consumerAccts[0].Id;
            newOrder.RecordtypeId = chOrderRecdTypeId;
            newOrder.Type = 'CH STANDARD';
            newOrder.EffectiveDate = System.today();
            newOrder.Price_Book__c = customPricebookId;       
            newOrder.Status = 'Draft';
            newOrder.Payment_Terms__c = 'net0';
            newOrder.Need_To_Calculate_Tax__c = 'false';
            newOrder.Finance_Detail__c = fd1.Id;
            //newOrder.Count_Of_G6_Receivers__c = 1;
            insert newOrder;
            
            newOrder.Pricebook2Id = customPricebookId; 
            update newOrder;
        
            //List order line items
            List<SSIP_Rule__c> lstSSIPRule = new List<SSIP_Rule__c>();
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
            
       
        
       // --------Add Error Lines Coverd by Below Code ----------
       try{
            newOrder.Status = 'Activated'; 
            update newOrder;
        }catch(Exception ex){
            Boolean expectedExceptionThrown =  ex.getMessage().contains('Please authorize the Credit Card.') ? true : false;
            newOrder.Status = 'Draft'; 
            update newOrder;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        Test.stopTest();
        consumerAccts[0].Subscription_Pending_Payments__c = 1;
        update consumerAccts[0];
        delete orderItemList;
        
        
        try{
            newOrder.Status = 'Activated'; 
            update newOrder;
        }catch(Exception ex){
            //System.debug('**ex--'+ex+'**--'+ex.getLineNumber());
            String errorToCover = 'There are pending subscription payments. They should be paid before this Order can be processed.';
            Boolean expectedExceptionThrown =  ex.getMessage().contains(errorToCover) ? true : false;
            newOrder.Status = 'Draft'; 
            update newOrder;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        System.debug('**newOrder'+newOrder.status);
        

        
        
    }
    @isTest static void TestOrderCreationAndUpdateCH2Exceptionv1(){
        
        Test.startTest();
        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CH Consumer', 'Switzerland');
        
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
         
         List<Address__c> lstAddress = new List<Address__c>{ 
             new Address__c(Account__c =consumerAccts[0].Id,Type__c = 'Bill To', Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
             new Address__c(Account__c = consumerAccts[0].Id,Type__c = 'Ship To',Country__c = 'Switzerland', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
             };
             insert lstAddress;
         
            Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCH(productIdToPriceMap, customPricebookId);
            Id rtIdFDCC = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
            Finance_Detail__c fd1= new Finance_Detail__c(Account__c=consumerAccts[0].Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='CHF',
                                                         Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=lstAddress[0].id, RecordTypeId=rtIdFDCC);
            insert fd1;
         Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CH Payor', 'Switzerland')[0];
         Fund__c Fd = new Fund__c();
         Fd.PO_Reference_Number__c ='87666787';
         Fd.Limit_Type__c ='Quantity';        
         Fd.Payor__c = consumerAccts[0].Id;
         Fd.Amount_Limit__c = 100000;
         Fd.Auth_End_Date__c = Date.today().addDays(100);
         Fd.Auth_Start_Date__c = Date.today();
         Fd.Receiver_Qty_Limit__c = 100; 
         Fd.Sensor_Limit__c = 100; 
         Fd.Transmitter_Qty_Limit__c = 100 ;
         
         insert Fd ; 
        
            Id chOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CH_Sales_Order').getRecordTypeId();
           
            ClsOrderTriggerStaticClass.isExecuting = false;
            Order newOrder = new Order();
            newOrder.AccountId = consumerAccts[0].Id;
            newOrder.RecordtypeId = chOrderRecdTypeId;
            newOrder.Type = 'CH STANDARD';
            newOrder.EffectiveDate = System.today();
            newOrder.Price_Book__c = customPricebookId;       
            newOrder.Status = 'Draft';
            newOrder.Payment_Terms__c = 'net0';
            newOrder.Need_To_Calculate_Tax__c = 'false';
            newOrder.Finance_Detail__c = fd1.Id;
        
            insert newOrder;
            
            newOrder.Pricebook2Id = customPricebookId; 
            update newOrder;
        
            //List order line items
            List<SSIP_Rule__c> lstSSIPRule = new List<SSIP_Rule__c>();
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
       
      
       // Scenario 1 - Add Error
       try{
           newOrder.Payment_Id__c = '123456';
           newOrder.CC_Auth_Amount__c = 890;
           newOrder.Status = 'SHIPPING HOLD'; 
           update newOrder;
        }catch(Exception ex){
            Boolean expectedExceptionThrown =  ex.getMessage().contains('Credit Card is authorized for') ? true : false;
            
            System.AssertEquals(expectedExceptionThrown, true);
        }
       Test.stopTest();

         
    }
    
}