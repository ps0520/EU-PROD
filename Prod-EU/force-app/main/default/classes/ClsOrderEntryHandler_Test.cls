@isTest
public class ClsOrderEntryHandler_Test {

    @isTest static void TestOrderCreationAndUpdateCA(){
        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Payor', 'Canada')[0];
        
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
        
        Id recordTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                };
                    insert lstAddress;
        
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
        
        Id caOppRecType = Schema.SObjectType.Benefit__c.getRecordTypeInfosByDeveloperName().get('CA_Benefit').getRecordTypeId();
        // [Select Id from RecordType where isActive = true AND SobjectType = 'Benefit__c' and DeveloperName = 'CA_Benefit'].Id;
        
        //Create new Benefit and associate it to the payor
        Benefit__c primaryBenefit = new Benefit__c();
        primaryBenefit.RecordTypeId = caOppRecType;
        primaryBenefit.Account__c = consumerAccts[0].Id;
        primaryBenefit.Member_Id__c = '1789657890';
        primaryBenefit.Payor__c =payorAccount.Id;
        primaryBenefit.Benefit_Hierarchy__c = 'Primary';
        // insert primaryBenefit;
        
        payorAccount.Price_Book__c = customPricebookMap.get('CA Cash');
        update payorAccount; 
        System.debug('**payorAccount--'+payorAccount);
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
        
        Id rtIdFDCC = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
        Finance_Detail__c fd1= new Finance_Detail__c(Account__c=payorAccount.Id,Token__c='1112', Card_Type__c='Mastercard',CC_CUR__c='CHF',
                                                     Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=lstAddress[0].id, RecordTypeId=rtIdFDCC);
        insert fd1;
        
        //Create Order record
        ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = payorAccount.Id;
        newOrder.RecordtypeId = caOrderRecdTypeId;
        newOrder.Type = 'CA STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;
        newOrder.Pricebook2Id = customPricebookId; 
        newOrder.Status = 'Draft';
        newOrder.Need_To_Calculate_Tax__c= 'true';
        newOrder.Tax_Exempt__c = true;
        newOrder.Payment_Terms__c = 'net0';
        //newOrder.Shipping_Method__c = 'DPD Local|Ground|1138|BSN';
        //newOrder.Fund__c = fd.Id;
        //newOrder.CC_Auth_Amount__c = 1233;
        //newOrder.Payment_Id__c = 'afascasADWAS3145T3224';
        newOrder.Finance_Detail__c = fd1.id;
        insert newOrder;        
        
        Map<Id,Order> mapnew = new Map<Id,Order>();
        mapnew.put(newOrder.Id, newOrder);
        Map<Id,Order> mapOld = new Map<Id,Order>();
        newOrder.Fund__c = fd.Id;
        mapOld.put(newOrder.Id, newOrder);
        
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
        
        
        Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGenCCAuthorize());
        Test.startTest();
        ClsOrderEntryHandler.calculateShippingCharge(mapnew, mapOld);
        //checkForCreditCard
        ClsOrderEntryHandler.checkForCreditCard(mapOld);
        ClsOrderEntryHandler.ccAuthorizeAndSettlePayment(newOrder.Id);
        ClsOrderEntryHandler.authorizeCreditCard(newOrder.Id);
        ClsOrderEntryHandler.CCsettlePayment(newOrder.Id);
        //handlePendingSubscriptionPayments
        ClsOrderEntryHandler.handlePendingSubscriptionPayments(newOrder.Id);  
        ClsOrderEntryHandler.captureCCpayment(newOrder.Id);
        //
        Set<Id> setAddressId = new Set<Id>();
        for(Address__c addr : lstAddress){
            setAddressId.add(addr.Id);
        }
        System.enqueueJob(new ClsOrderEntryHandler.LockAddressQueueable(setAddressId) );
        
        
        Test.stopTest();
    }
    @isTest static void TestOrderCreationAndUpdateCA1(){
        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Payor', 'Canada')[0];
        
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
        
        Id recordTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                };
                    insert lstAddress;
        
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
        
        Id caOppRecType = Schema.SObjectType.Benefit__c.getRecordTypeInfosByDeveloperName().get('CA_Benefit').getRecordTypeId();
        // [Select Id from RecordType where isActive = true AND SobjectType = 'Benefit__c' and DeveloperName = 'CA_Benefit'].Id;
        
        //Create new Benefit and associate it to the payor
        Benefit__c primaryBenefit = new Benefit__c();
        primaryBenefit.RecordTypeId = caOppRecType;
        primaryBenefit.Account__c = consumerAccts[0].Id;
        primaryBenefit.Member_Id__c = '1789657890';
        primaryBenefit.Payor__c =payorAccount.Id;
        primaryBenefit.Benefit_Hierarchy__c = 'Primary';
        // insert primaryBenefit;
        
        payorAccount.Price_Book__c = customPricebookMap.get('CA Cash');
        update payorAccount; 
        System.debug('**payorAccount--'+payorAccount);
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
        
        Id rtIdFDCC = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
        Finance_Detail__c fd1= new Finance_Detail__c(Account__c=payorAccount.Id,Token__c='1112', Card_Type__c='Mastercard',CC_CUR__c='CHF',
                                                     Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=lstAddress[0].id, RecordTypeId=rtIdFDCC);
        insert fd1;
        
        //Create Order record
        ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = payorAccount.Id;
        newOrder.RecordtypeId = caOrderRecdTypeId;
        newOrder.Type = 'CA STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;
        newOrder.Pricebook2Id = customPricebookId; 
        newOrder.Status = 'Draft';
        newOrder.Need_To_Calculate_Tax__c= 'true';
        newOrder.Tax_Exempt__c = true;
        newOrder.Payment_Terms__c = 'net0';
        //newOrder.Shipping_Method__c = 'DPD Local|Ground|1138|BSN';
        //newOrder.Fund__c = fd.Id;
        //newOrder.CC_Auth_Amount__c = 1233;
        //newOrder.Payment_Id__c = 'afascasADWAS3145T3224';
        newOrder.Finance_Detail__c = fd1.id;
        insert newOrder;        
        
        Map<Id,Order> mapnew = new Map<Id,Order>();
        mapnew.put(newOrder.Id, newOrder);
        Map<Id,Order> mapOld = new Map<Id,Order>();
        newOrder.Fund__c = fd.Id;
        mapOld.put(newOrder.Id, newOrder);
        
        //List order line items
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values()){
            OrderItem oi = new OrderItem();
            oi.OrderId = newOrder.Id;
            oi.PricebookEntryId = pbeId;
            oi.Quantity = 1;
            oi.UnitPrice = 0.00;
            oi.Tracking_Number__c = '12345';
            oi.Product_Name__c = 'STK-GF-109' ;
            orderItemList.add(oi);
        }
        insert orderItemList;
        
        
        Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGenCCAuthorize());
        Test.startTest();
        ClsOrderEntryHandler.calculateShippingCharge(mapnew, mapOld);
        //checkForCreditCard
        ClsOrderEntryHandler.validateEmail('asd@dexcom.invalid.com');
        ClsOrderEntryHandler.validatePhone('345345345');
        ClsOrderEntryHandler.checkForCreditCard(mapOld);
        ClsOrderEntryHandler.ccAuthorizeAndSettlePayment(newOrder.Id);
        //ClsOrderEntryHandler.authorizeCreditCard(newOrder.Id);
        //ClsOrderEntryHandler.CCsettlePayment(newOrder.Id);
        //handlePendingSubscriptionPayments
        ClsOrderEntryHandler.handlePendingSubscriptionPayments(newOrder.Id);  
        ClsOrderEntryHandler.captureCCpayment(newOrder.Id);
        //
        Set<Id> setAddressId = new Set<Id>();
        for(Address__c addr : lstAddress){
            setAddressId.add(addr.Id);
        }
        System.enqueueJob(new ClsOrderEntryHandler.LockAddressQueueable(setAddressId) );
        
        
        Test.stopTest();
        
        //ClsOrderEntryHandler.ccAuthorizeAndSettlePayment(newOrder.Id);
    }
    @isTest static void TestOrderCreationAndUpdateCA2(){
        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Payor', 'Canada')[0];
        
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
        
        Id recordTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                };
                    insert lstAddress;
        
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
        
        Id caOppRecType = Schema.SObjectType.Benefit__c.getRecordTypeInfosByDeveloperName().get('CA_Benefit').getRecordTypeId();
        // [Select Id from RecordType where isActive = true AND SobjectType = 'Benefit__c' and DeveloperName = 'CA_Benefit'].Id;
        
        //Create new Benefit and associate it to the payor
        Benefit__c primaryBenefit = new Benefit__c();
        primaryBenefit.RecordTypeId = caOppRecType;
        primaryBenefit.Account__c = consumerAccts[0].Id;
        primaryBenefit.Member_Id__c = '1789657890';
        primaryBenefit.Payor__c =payorAccount.Id;
        primaryBenefit.Benefit_Hierarchy__c = 'Primary';
        // insert primaryBenefit;
        
        payorAccount.Price_Book__c = customPricebookMap.get('CA Cash');
        update payorAccount; 
        System.debug('**payorAccount--'+payorAccount);
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
        
        Id rtIdFDCC = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
        Finance_Detail__c fd1= new Finance_Detail__c(Account__c=payorAccount.Id,Token__c='1112', Card_Type__c='Mastercard',CC_CUR__c='CHF',
                                                     Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=lstAddress[0].id, RecordTypeId=rtIdFDCC);
        insert fd1;
        
        //Create Order record
        ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = payorAccount.Id;
        newOrder.RecordtypeId = caOrderRecdTypeId;
        newOrder.Type = 'CA STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;
        newOrder.Pricebook2Id = customPricebookId; 
        newOrder.Status = 'Draft';
        newOrder.Need_To_Calculate_Tax__c= 'true';
        newOrder.Tax_Exempt__c = true;
        newOrder.Payment_Terms__c = 'net0';
        //newOrder.Shipping_Method__c = 'DPD Local|Ground|1138|BSN';
        //newOrder.Fund__c = fd.Id;
        //newOrder.CC_Auth_Amount__c = 1233;
        //newOrder.Payment_Id__c = 'afascasADWAS3145T3224';
        newOrder.Finance_Detail__c = fd1.id;
        insert newOrder;        
        
        Map<Id,Order> mapnew = new Map<Id,Order>();
        mapnew.put(newOrder.Id, newOrder);
        Map<Id,Order> mapOld = new Map<Id,Order>();
        newOrder.Fund__c = fd.Id;
        mapOld.put(newOrder.Id, newOrder);
        
        //List order line items
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values()){
            OrderItem oi = new OrderItem();
            oi.OrderId = newOrder.Id;
            oi.PricebookEntryId = pbeId;
            oi.Quantity = 1;
            oi.UnitPrice = 0.00;
            oi.Tracking_Number__c = '12345';
            oi.Product_Name__c = 'STK-GF-109' ;
            orderItemList.add(oi);
        }
        // insert orderItemList;
        
        
        Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGenCCAuthorize());
        Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGenCCSettle());
        Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGenCCAuthorize());
        Test.startTest();
        ClsOrderEntryHandler.calculateShippingCharge(mapnew, mapOld);
        //checkForCreditCard
        ClsOrderEntryHandler.validateEmail('asd@dexcom.invalid.com');
        ClsOrderEntryHandler.validatePhone('345345345');
        ClsOrderEntryHandler.checkForCreditCard(mapOld);
        ClsOrderEntryHandler.ccAuthorizeAndSettlePayment(newOrder.Id);
        ClsOrderEntryHandler.authorizeCreditCard(newOrder.Id);
        //ClsOrderEntryHandler.CCsettlePayment(newOrder.Id);
        //handlePendingSubscriptionPayments
        ClsOrderEntryHandler.handlePendingSubscriptionPayments(newOrder.Id);  
        ClsOrderEntryHandler.captureCCpayment(newOrder.Id);
        //
        Set<Id> setAddressId = new Set<Id>();
        for(Address__c addr : lstAddress){
            setAddressId.add(addr.Id);
        }
        System.enqueueJob(new ClsOrderEntryHandler.LockAddressQueueable(setAddressId) );
        
        
        Test.stopTest();
        
        //ClsOrderEntryHandler.ccAuthorizeAndSettlePayment(newOrder.Id);
    }
    @isTest static void TestOrderCreationMissignToken(){
        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Payor', 'Canada')[0];
        
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
        
        Id recordTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                };
                    insert lstAddress;
        
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
        
        Id caOppRecType = Schema.SObjectType.Benefit__c.getRecordTypeInfosByDeveloperName().get('CA_Benefit').getRecordTypeId();
        // [Select Id from RecordType where isActive = true AND SobjectType = 'Benefit__c' and DeveloperName = 'CA_Benefit'].Id;
        
        //Create new Benefit and associate it to the payor
        Benefit__c primaryBenefit = new Benefit__c();
        primaryBenefit.RecordTypeId = caOppRecType;
        primaryBenefit.Account__c = consumerAccts[0].Id;
        primaryBenefit.Member_Id__c = '1789657890';
        primaryBenefit.Payor__c =payorAccount.Id;
        primaryBenefit.Benefit_Hierarchy__c = 'Primary';
        // insert primaryBenefit;
        
        payorAccount.Price_Book__c = customPricebookMap.get('CA Cash');
        update payorAccount; 
        System.debug('**payorAccount--'+payorAccount);
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
        
        Id rtIdFDCC = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
        Finance_Detail__c fd1= new Finance_Detail__c(Account__c=payorAccount.Id,Token__c=null, Card_Type__c='Mastercard',CC_CUR__c='CHF',
                                                     Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=lstAddress[0].id, RecordTypeId=rtIdFDCC);
        insert fd1;
        
        //Create Order record
        ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = payorAccount.Id;
        newOrder.RecordtypeId = caOrderRecdTypeId;
        newOrder.Type = 'CA STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;
        newOrder.Pricebook2Id = customPricebookId; 
        newOrder.Status = 'Draft';
        newOrder.Need_To_Calculate_Tax__c= 'true';
        newOrder.Tax_Exempt__c = true;
        newOrder.Payment_Terms__c = 'net0';
        //newOrder.Shipping_Method__c = 'DPD Local|Ground|1138|BSN';
        //newOrder.Fund__c = fd.Id;
        //newOrder.CC_Auth_Amount__c = 1233;
        //newOrder.Payment_Id__c = 'afascasADWAS3145T3224';
        newOrder.Finance_Detail__c = fd1.id;
        insert newOrder;        
        
        Map<Id,Order> mapnew = new Map<Id,Order>();
        mapnew.put(newOrder.Id, newOrder);
        Map<Id,Order> mapOld = new Map<Id,Order>();
        newOrder.Fund__c = fd.Id;
        mapOld.put(newOrder.Id, newOrder);
        
        //List order line items
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values()){
            OrderItem oi = new OrderItem();
            oi.OrderId = newOrder.Id;
            oi.PricebookEntryId = pbeId;
            oi.Quantity = 1;
            oi.UnitPrice = 0.00;
            oi.Tracking_Number__c = '12345';
            oi.Product_Name__c = 'STK-GF-109' ;
            orderItemList.add(oi);
        }
        insert orderItemList;
        
        
        Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGenCCAuthorize());
        Test.startTest();
        
        ClsOrderEntryHandler.calculateShippingCharge(mapnew, mapOld);
        //checkForCreditCard
        ClsOrderEntryHandler.validateEmail('asd@dexcom.invalid.com');
        ClsOrderEntryHandler.validatePhone('345345345');
        ClsOrderEntryHandler.checkForCreditCard(mapOld);
        ClsOrderEntryHandler.ccAuthorizeAndSettlePayment(newOrder.Id);
        ClsOrderEntryHandler.authorizeCreditCard(newOrder.Id);
        ClsOrderEntryHandler.CCsettlePayment(newOrder.Id);
        //handlePendingSubscriptionPayments
        ClsOrderEntryHandler.handlePendingSubscriptionPayments(newOrder.Id);  
        ClsOrderEntryHandler.captureCCpayment(newOrder.Id);
        //
        Set<Id> setAddressId = new Set<Id>();
        for(Address__c addr : lstAddress){
            setAddressId.add(addr.Id);
        }
        System.enqueueJob(new ClsOrderEntryHandler.LockAddressQueueable(setAddressId) );
        
        
        Test.stopTest();
        
        //ClsOrderEntryHandler.ccAuthorizeAndSettlePayment(newOrder.Id);
    }
    @isTest static void TestOrderCreationMissignDates(){
        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Payor', 'Canada')[0];
        
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
        
        Id recordTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                };
                    insert lstAddress;
        
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
        
        Id caOppRecType = Schema.SObjectType.Benefit__c.getRecordTypeInfosByDeveloperName().get('CA_Benefit').getRecordTypeId();
        // [Select Id from RecordType where isActive = true AND SobjectType = 'Benefit__c' and DeveloperName = 'CA_Benefit'].Id;
        
        //Create new Benefit and associate it to the payor
        Benefit__c primaryBenefit = new Benefit__c();
        primaryBenefit.RecordTypeId = caOppRecType;
        primaryBenefit.Account__c = consumerAccts[0].Id;
        primaryBenefit.Member_Id__c = '1789657890';
        primaryBenefit.Payor__c =payorAccount.Id;
        primaryBenefit.Benefit_Hierarchy__c = 'Primary';
        // insert primaryBenefit;
        
        payorAccount.Price_Book__c = customPricebookMap.get('CA Cash');
        update payorAccount; 
        System.debug('**payorAccount--'+payorAccount);
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
        
        Id rtIdFDCC = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
        Finance_Detail__c fd1= new Finance_Detail__c(Account__c=payorAccount.Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='CHF',
                                                     Expiry_Date__c=null, Primary__c=true, CC_Address__c=lstAddress[0].id, RecordTypeId=rtIdFDCC);
        insert fd1;
        
        //Create Order record
        ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = payorAccount.Id;
        newOrder.RecordtypeId = caOrderRecdTypeId;
        newOrder.Type = 'CA STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;
        newOrder.Pricebook2Id = customPricebookId; 
        newOrder.Status = 'Draft';
        newOrder.Need_To_Calculate_Tax__c= 'true';
        newOrder.Tax_Exempt__c = true;
        newOrder.Payment_Terms__c = 'net0';
        //newOrder.Shipping_Method__c = 'DPD Local|Ground|1138|BSN';
        //newOrder.Fund__c = fd.Id;
        //newOrder.CC_Auth_Amount__c = 1233;
        //newOrder.Payment_Id__c = 'afascasADWAS3145T3224';
        newOrder.Finance_Detail__c = fd1.id;
        insert newOrder;        
        
        Map<Id,Order> mapnew = new Map<Id,Order>();
        mapnew.put(newOrder.Id, newOrder);
        Map<Id,Order> mapOld = new Map<Id,Order>();
        newOrder.Fund__c = fd.Id;
        mapOld.put(newOrder.Id, newOrder);
        
        //List order line items
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values()){
            OrderItem oi = new OrderItem();
            oi.OrderId = newOrder.Id;
            oi.PricebookEntryId = pbeId;
            oi.Quantity = 1;
            oi.UnitPrice = 0.00;
            oi.Tracking_Number__c = '12345';
            oi.Product_Name__c = 'STK-GF-109' ;
            orderItemList.add(oi);
        }
        insert orderItemList;
        
        
        Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGenCCAuthorize());
        Test.startTest();
        
        ClsOrderEntryHandler.calculateShippingCharge(mapnew, mapOld);
        //checkForCreditCard
        ClsOrderEntryHandler.validateEmail('asd@dexcom.invalid.com');
        ClsOrderEntryHandler.validatePhone('345345345');
        ClsOrderEntryHandler.checkForCreditCard(mapOld);
        ClsOrderEntryHandler.ccAuthorizeAndSettlePayment(newOrder.Id);
        ClsOrderEntryHandler.authorizeCreditCard(newOrder.Id);
        ClsOrderEntryHandler.CCsettlePayment(newOrder.Id);
        //handlePendingSubscriptionPayments
        ClsOrderEntryHandler.handlePendingSubscriptionPayments(newOrder.Id);  
        ClsOrderEntryHandler.captureCCpayment(newOrder.Id);
        //
        Set<Id> setAddressId = new Set<Id>();
        for(Address__c addr : lstAddress){
            setAddressId.add(addr.Id);
        }
        System.enqueueJob(new ClsOrderEntryHandler.LockAddressQueueable(setAddressId) );
        
        
        Test.stopTest();
        
        //ClsOrderEntryHandler.ccAuthorizeAndSettlePayment(newOrder.Id);
    }
    @isTest static void TestOrderCreationMissignAddress(){
        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Payor', 'Canada')[0];
        
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
        
        Id recordTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                };
                    insert lstAddress;
        
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
        
        Id caOppRecType = Schema.SObjectType.Benefit__c.getRecordTypeInfosByDeveloperName().get('CA_Benefit').getRecordTypeId();
        // [Select Id from RecordType where isActive = true AND SobjectType = 'Benefit__c' and DeveloperName = 'CA_Benefit'].Id;
        
        //Create new Benefit and associate it to the payor
        Benefit__c primaryBenefit = new Benefit__c();
        primaryBenefit.RecordTypeId = caOppRecType;
        primaryBenefit.Account__c = consumerAccts[0].Id;
        primaryBenefit.Member_Id__c = '1789657890';
        primaryBenefit.Payor__c =payorAccount.Id;
        primaryBenefit.Benefit_Hierarchy__c = 'Primary';
        // insert primaryBenefit;
        
        payorAccount.Price_Book__c = customPricebookMap.get('CA Cash');
        update payorAccount; 
        System.debug('**payorAccount--'+payorAccount);
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
        
        Id rtIdFDCC = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
        Finance_Detail__c fd1= new Finance_Detail__c(Account__c=payorAccount.Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='CHF',
                                                     Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=null, RecordTypeId=rtIdFDCC);
        insert fd1;
        
        //Create Order record
        ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = payorAccount.Id;
        newOrder.RecordtypeId = caOrderRecdTypeId;
        newOrder.Type = 'CA STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;
        newOrder.Pricebook2Id = customPricebookId; 
        newOrder.Status = 'Draft';
        newOrder.Need_To_Calculate_Tax__c= 'true';
        newOrder.Tax_Exempt__c = true;
        newOrder.Payment_Terms__c = 'net0';
        //newOrder.Shipping_Method__c = 'DPD Local|Ground|1138|BSN';
        //newOrder.Fund__c = fd.Id;
        //newOrder.CC_Auth_Amount__c = 1233;
        //newOrder.Payment_Id__c = 'afascasADWAS3145T3224';
        newOrder.Finance_Detail__c = fd1.id;
        insert newOrder;        
        
        Map<Id,Order> mapnew = new Map<Id,Order>();
        mapnew.put(newOrder.Id, newOrder);
        Map<Id,Order> mapOld = new Map<Id,Order>();
        newOrder.Fund__c = fd.Id;
        mapOld.put(newOrder.Id, newOrder);
        
        //List order line items
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values()){
            OrderItem oi = new OrderItem();
            oi.OrderId = newOrder.Id;
            oi.PricebookEntryId = pbeId;
            oi.Quantity = 1;
            oi.UnitPrice = 0.00;
            oi.Tracking_Number__c = '12345';
            oi.Product_Name__c = 'STK-GF-109' ;
            orderItemList.add(oi);
        }
        insert orderItemList;
        
        
        Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGenCCAuthorize());
        Test.startTest();
        
        ClsOrderEntryHandler.calculateShippingCharge(mapnew, mapOld);
        //checkForCreditCard
        ClsOrderEntryHandler.validateEmail('asd@dexcom.invalid.com');
        ClsOrderEntryHandler.validatePhone('345345345');
        ClsOrderEntryHandler.checkForCreditCard(mapOld);
        ClsOrderEntryHandler.ccAuthorizeAndSettlePayment(newOrder.Id);
        ClsOrderEntryHandler.authorizeCreditCard(newOrder.Id);
        ClsOrderEntryHandler.CCsettlePayment(newOrder.Id);
        //handlePendingSubscriptionPayments
        ClsOrderEntryHandler.handlePendingSubscriptionPayments(newOrder.Id);  
        ClsOrderEntryHandler.captureCCpayment(newOrder.Id);
        //
        Set<Id> setAddressId = new Set<Id>();
        for(Address__c addr : lstAddress){
            setAddressId.add(addr.Id);
        }
        System.enqueueJob(new ClsOrderEntryHandler.LockAddressQueueable(setAddressId) );
        
        
        Test.stopTest();
        
        //ClsOrderEntryHandler.ccAuthorizeAndSettlePayment(newOrder.Id);
    }
    @isTest static void TestOrderCreationMissignFD(){
        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Payor', 'Canada')[0];
        
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
        
        Id recordTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                };
                    insert lstAddress;
        
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
        
        Id caOppRecType = Schema.SObjectType.Benefit__c.getRecordTypeInfosByDeveloperName().get('CA_Benefit').getRecordTypeId();
        // [Select Id from RecordType where isActive = true AND SobjectType = 'Benefit__c' and DeveloperName = 'CA_Benefit'].Id;
        
        //Create new Benefit and associate it to the payor
        Benefit__c primaryBenefit = new Benefit__c();
        primaryBenefit.RecordTypeId = caOppRecType;
        primaryBenefit.Account__c = consumerAccts[0].Id;
        primaryBenefit.Member_Id__c = '1789657890';
        primaryBenefit.Payor__c =payorAccount.Id;
        primaryBenefit.Benefit_Hierarchy__c = 'Primary';
        // insert primaryBenefit;
        
        payorAccount.Price_Book__c = customPricebookMap.get('CA Cash');
        update payorAccount; 
        System.debug('**payorAccount--'+payorAccount);
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
        
        Id rtIdFDCC = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
        Finance_Detail__c fd1= new Finance_Detail__c(Account__c=payorAccount.Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='CHF',
                                                     Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=null, RecordTypeId=rtIdFDCC);
        insert fd1;
        
        //Create Order record
        ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = payorAccount.Id;
        newOrder.RecordtypeId = caOrderRecdTypeId;
        newOrder.Type = 'CA STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;
        newOrder.Pricebook2Id = customPricebookId; 
        newOrder.Status = 'Draft';
        newOrder.Need_To_Calculate_Tax__c= 'true';
        newOrder.Tax_Exempt__c = true;
        newOrder.Payment_Terms__c = 'net0';
        //newOrder.Shipping_Method__c = 'DPD Local|Ground|1138|BSN';
        //newOrder.Fund__c = fd.Id;
        //newOrder.CC_Auth_Amount__c = 1233;
        //newOrder.Payment_Id__c = 'afascasADWAS3145T3224';
        //newOrder.Finance_Detail__c = fd1.id;
        insert newOrder;        
        
        Map<Id,Order> mapnew = new Map<Id,Order>();
        mapnew.put(newOrder.Id, newOrder);
        Map<Id,Order> mapOld = new Map<Id,Order>();
        newOrder.Fund__c = fd.Id;
        mapOld.put(newOrder.Id, newOrder);
        
        //List order line items
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values()){
            OrderItem oi = new OrderItem();
            oi.OrderId = newOrder.Id;
            oi.PricebookEntryId = pbeId;
            oi.Quantity = 1;
            oi.UnitPrice = 0.00;
            oi.Tracking_Number__c = '12345';
            oi.Product_Name__c = 'STK-GF-109' ;
            orderItemList.add(oi);
        }
        insert orderItemList;
        
        
        Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGenCCAuthorize());
        Test.startTest();
        
        ClsOrderEntryHandler.calculateShippingCharge(mapnew, mapOld);
        //checkForCreditCard
        ClsOrderEntryHandler.validateEmail('asd@dexcom.invalid.com');
        ClsOrderEntryHandler.validatePhone('345345345');
        ClsOrderEntryHandler.checkForCreditCard(mapOld);
        ClsOrderEntryHandler.ccAuthorizeAndSettlePayment(newOrder.Id);
        ClsOrderEntryHandler.authorizeCreditCard(newOrder.Id);
        ClsOrderEntryHandler.CCsettlePayment(newOrder.Id);
        //handlePendingSubscriptionPayments
        ClsOrderEntryHandler.handlePendingSubscriptionPayments(newOrder.Id);  
        ClsOrderEntryHandler.captureCCpayment(newOrder.Id);
        //
        Set<Id> setAddressId = new Set<Id>();
        for(Address__c addr : lstAddress){
            setAddressId.add(addr.Id);
        }
        System.enqueueJob(new ClsOrderEntryHandler.LockAddressQueueable(setAddressId) );
        
        
        Test.stopTest();
        
        //ClsOrderEntryHandler.ccAuthorizeAndSettlePayment(newOrder.Id);
    }
    @isTest static void TestOrderCreationPaymentIdErr(){
        
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada');
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Payor', 'Canada')[0];
        
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
        
        Id recordTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = consumerAccts[0].Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                };
                    insert lstAddress;
        
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CA_Sales_Order').getRecordTypeId();
        
        Id caOppRecType = Schema.SObjectType.Benefit__c.getRecordTypeInfosByDeveloperName().get('CA_Benefit').getRecordTypeId();
        // [Select Id from RecordType where isActive = true AND SobjectType = 'Benefit__c' and DeveloperName = 'CA_Benefit'].Id;
        
        //Create new Benefit and associate it to the payor
        Benefit__c primaryBenefit = new Benefit__c();
        primaryBenefit.RecordTypeId = caOppRecType;
        primaryBenefit.Account__c = consumerAccts[0].Id;
        primaryBenefit.Member_Id__c = '1789657890';
        primaryBenefit.Payor__c =payorAccount.Id;
        primaryBenefit.Benefit_Hierarchy__c = 'Primary';
        // insert primaryBenefit;
        
        payorAccount.Price_Book__c = customPricebookMap.get('CA Cash');
        update payorAccount; 
        System.debug('**payorAccount--'+payorAccount);
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
        
        Id rtIdFDCC = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
        Finance_Detail__c fd1= new Finance_Detail__c(Account__c=payorAccount.Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='CHF',
                                                     Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=lstAddress[0].Id , RecordTypeId=rtIdFDCC);
        insert fd1;
        
        //Create Order record
        ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = payorAccount.Id;
        newOrder.RecordtypeId = caOrderRecdTypeId;
        newOrder.Type = 'CA STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;
        newOrder.Pricebook2Id = customPricebookId; 
        newOrder.Status = 'Draft';
        newOrder.Need_To_Calculate_Tax__c= 'true';
        newOrder.Tax_Exempt__c = true;
        newOrder.Payment_Terms__c = 'net0';
        //newOrder.Shipping_Method__c = 'DPD Local|Ground|1138|BSN';
        // newOrder.Fund__c = fd.Id;
        //newOrder.CC_Auth_Amount__c = 1233;
        //newOrder.Payment_Id__c = 'afascasADWAS3145T3224';
        newOrder.Finance_Detail__c = fd1.id;
        insert newOrder;        
        
        Map<Id,Order> mapnew = new Map<Id,Order>();
        mapnew.put(newOrder.Id, newOrder);
        Map<Id,Order> mapOld = new Map<Id,Order>();
        newOrder.Fund__c = fd.Id;
        mapOld.put(newOrder.Id, newOrder);
        
        //List order line items
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values()){
            OrderItem oi = new OrderItem();
            oi.OrderId = newOrder.Id;
            oi.PricebookEntryId = pbeId;
            oi.Quantity = 1;
            oi.UnitPrice = 0.00;
            oi.Tracking_Number__c = '12345';
            oi.Product_Name__c = 'STK-GF-109' ;
            orderItemList.add(oi);
        }
        insert orderItemList;
        
        
        Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGenCCAuthorize());
        Test.startTest();
        
        ClsOrderEntryHandler.calculateShippingCharge(mapnew, mapOld);
        //checkForCreditCard
        ClsOrderEntryHandler.validateEmail('asd@dexcom.invalid.com');
        ClsOrderEntryHandler.validatePhone('345345345');
        ClsOrderEntryHandler.checkForCreditCard(mapOld);
        
        ClsOrderEntryHandler.authorizeCreditCard(newOrder.Id);
        ClsOrderEntryHandler.CCsettlePayment(newOrder.Id);
        ClsOrderEntryHandler.ccAuthorizeAndSettlePayment(newOrder.Id);
        //handlePendingSubscriptionPayments
        ClsOrderEntryHandler.handlePendingSubscriptionPayments(newOrder.Id);  
        ClsOrderEntryHandler.captureCCpayment(newOrder.Id);
        //
        Set<Id> setAddressId = new Set<Id>();
        for(Address__c addr : lstAddress){
            setAddressId.add(addr.Id);
        }
        System.enqueueJob(new ClsOrderEntryHandler.LockAddressQueueable(setAddressId) );
        
        
        Test.stopTest();
        
        //ClsOrderEntryHandler.ccAuthorizeAndSettlePayment(newOrder.Id);
    }
}