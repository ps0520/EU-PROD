@isTest()
private class PEClsHandleOrderEvents_Test { 

    @testSetup static void setup() {
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCustomPricebook(new List<String>{'DE Netto-Preis Cash', 'DE Return Replace', 'Barmer'});
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'Product-01', 'Product-02', 'Product-03', 'DEX-SHIP-01'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>{mapProduct.values()[0] => 10, mapProduct.values()[1] => 10, mapProduct.values()[2] => 10 };
        Map<Id, Id> mapPBE = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, mapPriceBook.get('DE Netto-Preis Cash'));
        Account objAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Consumer', 'Germany')[0];
        
    }
    
    @isTest private static void testCreateECOM(){
        List<PEClsHandleOrderEvents.OrderLineItem> lstOLI = new List<PEClsHandleOrderEvents.OrderLineItem>();
        for(Product2 product : [SELECT Id, Name FROM Product2]){
            lstOLI.add(new PEClsHandleOrderEvents.OrderLineItem(product.Name, 1, 10));
        }
        List<Product2> lstProduct = [SELECT Id, Name FROM Product2];
        List<Account> lstAccount = [SELECT Id, Name FROM Account];
        
         //Query for the Address record types
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                               where sObjectType='Address__c' and isActive=true];
    
        //Create a map between the Record Type Name and Id 
        Map<String,String> addRecordTypes = new Map<String,String>();
        for(RecordType rt: rtypes) {
        addRecordTypes.put(rt.Name,rt.Id);
        }     	
        String recordTypeId = addRecordTypes.get('DE Address');
        List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Account__c = lstAccount[0].Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = lstAccount[0].Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                                                          };
        insert lstAddress;
        
        CRM_Order_Event__e oEvent = new CRM_Order_Event__e(version__c = '1.0',orderType__c = 'Sales_Order', operation__c = 'create',stage__c = 'pending',eventSource__c = 'ECOM',
                                                           systemOfOrigin__c = '12345', systemOfOriginID__c = 'abcdefg', accountId__c = lstAccount[0].Id, 
                                                           billingAddress1__c = '10255 W Higgins Rd', billingAddress2__c = '', billingAddress3__c = '', 
                                                           billingAddressAccountID__c = lstAccount[0].Id, billingAddressBusinessName__c = 'Test', billingAddressCity__c = 'Rosemont',
                                                           billingAddressCountry__c = 'Germany', billingAddressCountryCode__c = 'DE', billingAddressFirstName__c = 'Test', 
                                                           billingAddressIsLocked__c = false, billingAddressLastName__c = 'Test', billingAddressPostalCode__c = '60089',
                                                           billingAddressPrimaryPhone__c = '9876543210', billingAddressStateProvince__c = '', creditCardAuthorizationCode__c = '12356890qwertyuiosd',
                                                           creditCardExpirationDate__c = '0421',creditCardId__c = '', creditCardToken__c = '1234567890qwetyuio',
                                                           creditCardType__c = 'Visa',entityType__c = 'order', eventDate__c = '', eventSourceID__c = '123456',
                                                           invoiceDate__c = String.ValueOf(Date.today().addMonths(2)), isSignatureRequired__c = false, Line_Items__c = JSON.serialize(lstOLI),
                                                           orderNumber__c = '', paymentTerm__c = '', pricebookName__c = 'DE Netto-Preis Cash',
                                                           rgaNumber__c = '', scheduledShipDate__c = '', shippingAddress1__c = '10255 W Higgins Rd',
                                                           shippingAddress2__c = '', shippingAddress3__c = '', shippingAddressAccountId__c = lstAccount[0].Id, 
                                                           shippingAddressBusinessName__c = 'test@1231', shippingAddressCity__c = 'Rosemont',
                                                           shippingAddressCountry__c = 'Germany', shippingAddressCountryCode__c = 'DE',
                                                           shippingAddressFirstName__c = 'test', shippingAddressIsLocked__c = false, shippingAddressLastName__c = 'Test1',
                                                           shippingAddressPostalCode__c = '60099', shippingAddressPrimaryPhone__c = '1111',
                                                           shippingAddressStateProvince__c = '', shippingMethod__c = 'NA',
                                                           shippingNotes__c = '', status__c = '',
                                                           statusMessage__c = '', billingAddressId__c = lstAddress[0].Id,shippingAddressId__c = lstAddress[1].Id);
        System.debug('====oEvent===='+JSON.serialize(oEvent));
        Test.startTest();
            Database.SaveResult sr = EventBus.publish(oEvent);
        Test.stopTest();
        System.assertEquals(true, sr.isSuccess());
        List<Order> orders = [SELECT Id FROM Order];
        system.debug('=======orders====='+orders);
       // System.assertEquals(1, orders.size());
    }
    @isTest private static void testCreateECOMError(){
        List<Account> lstAccount = [SELECT Id, Name FROM Account];
        List<PEClsHandleOrderEvents.OrderLineItem> lstOLI = new List<PEClsHandleOrderEvents.OrderLineItem>();
        for(Product2 product : [SELECT Id, Name FROM Product2]){
            lstOLI.add(new PEClsHandleOrderEvents.OrderLineItem(product.Id, 1, 10));
        }
        
         //Query for the Address record types
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                               where sObjectType='Address__c' and isActive=true];
    
        //Create a map between the Record Type Name and Id 
        Map<String,String> addRecordTypes = new Map<String,String>();
        for(RecordType rt: rtypes) {
        addRecordTypes.put(rt.Name,rt.Id);
        }     	
        String recordTypeId = addRecordTypes.get('DE Address');
        List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Account__c = lstAccount[0].Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = lstAccount[0].Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                                                          };
        insert lstAddress;
        
        CRM_Order_Event__e oEvent = new CRM_Order_Event__e(version__c = '1.0',orderType__c = 'Sales_Order', operation__c = 'create',stage__c = 'pending',eventSource__c = 'ECOM',
                                                           systemOfOrigin__c = '12345', systemOfOriginID__c = 'abcdefg', accountId__c = lstAccount[0].Id, 
                                                           billingAddress1__c = '10255 W Higgins Rd1', billingAddress2__c = '10255 W Higgins Rd1', billingAddress3__c = '10255 W Higgins Rd1', 
                                                           billingAddressAccountID__c = lstAccount[0].Id, billingAddressBusinessName__c = 'Test@@@', billingAddressCity__c = 'Rosemont@@',
                                                           billingAddressCountry__c = 'Germany', billingAddressCountryCode__c = 'D!E', billingAddressFirstName__c = 'Test1', 
                                                           billingAddressIsLocked__c = false, billingAddressLastName__c = 'Test', billingAddressPostalCode__c = '60099',
                                                           billingAddressPrimaryPhone__c = '9876543220', billingAddressStateProvince__c = '', creditCardAuthorizationCode__c = '12356890qwertyuiosd',
                                                           creditCardExpirationDate__c = '0421',creditCardId__c = '', creditCardToken__c = '1234567890qwetyuio',
                                                           creditCardType__c = 'Visa',entityType__c = 'order', eventDate__c = '', eventSourceID__c = '123456',
                                                           invoiceDate__c = String.ValueOf(Date.today().addMonths(2)), isSignatureRequired__c = false, Line_Items__c = JSON.serialize(lstOLI),
                                                           orderNumber__c = '', paymentTerm__c = '', pricebookName__c = 'DE Netto-Preis Cash',
                                                           rgaNumber__c = '', scheduledShipDate__c = '', shippingAddress1__c = '10255 W Higgins Rd1',
                                                           shippingAddress2__c = '10255 W Higgins Rd1', shippingAddress3__c = '10255 W Higgins Rd1', shippingAddressAccountId__c = lstAccount[0].Id, 
                                                           shippingAddressBusinessName__c = 'test@1231', shippingAddressCity__c = 'Rosemont1',
                                                           shippingAddressCountry__c = 'Germany', shippingAddressCountryCode__c = 'DE1',
                                                           shippingAddressFirstName__c = 'test1', shippingAddressIsLocked__c = false, shippingAddressLastName__c = 'Test1',
                                                           shippingAddressPostalCode__c = '60089', shippingAddressPrimaryPhone__c = '1234567890',
                                                           shippingAddressStateProvince__c = '', shippingMethod__c = 'NA',shippingNotes__c = '', status__c = '', statusMessage__c = '');
        Test.startTest();
            Database.SaveResult sr = EventBus.publish(oEvent);
        Test.stopTest();
    }
    @isTest private static void testCreateOMS(){
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Payor', 'Germany')[0];
        List<Account> lstAccount = [SELECT Id, Name FROM Account];
        List<PEClsHandleOrderEvents.OrderLineItem> lstOLI = new List<PEClsHandleOrderEvents.OrderLineItem>();
        for(Product2 product : [SELECT Id, Name FROM Product2]){
            lstOLI.add(new PEClsHandleOrderEvents.OrderLineItem(product.Id, 1, 10));
        }
        
        List<Product2> lstProduct = [SELECT Id, Name FROM Product2];
         //Query for the Address record types
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                               where sObjectType='Address__c' and isActive=true];
    
        //Create a map between the Record Type Name and Id 
        Map<String,String> addRecordTypes = new Map<String,String>();
        for(RecordType rt: rtypes) {
        addRecordTypes.put(rt.Name,rt.Id);
        }     	
        String recordTypeId = addRecordTypes.get('DE Address');
        List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Account__c = lstAccount[0].Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = lstAccount[0].Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                                                          };
        insert lstAddress;
        List<PricebookEntry> lstPBE = [SELECT Id, Pricebook2Id FROM PricebookEntry WHERE Pricebook2.Name = 'DE Netto-Preis Cash'];
        Order objOrder = new Order(AccountId = lstAccount[0].Id, EffectiveDate = Date.today(), Status = 'Draft', Type = 'DE STANDARD', Payor__c = payorAccount.Id, Pricebook2Id = lstPBE[0].Pricebook2Id, Price_Book__c = lstPBE[0].Pricebook2Id);
        insert objOrder;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        for(PricebookEntry pbe : lstPBE){
            lstOrderItem.add(new OrderItem(PricebookEntryId = pbe.Id, OrderId = objOrder.Id, Quantity = 1, UnitPrice = 10));
        }
        insert lstOrderItem;
        List<Order> lstOrder = [SELECT Id, OrderNumber FROM Order]; 
        CRM_Order_Event__e oEvent = new CRM_Order_Event__e(version__c = '1.0',orderType__c = 'Sales_Order', operation__c = 'create',stage__c = 'confirmed',eventSource__c = 'OMS',
                                                           systemOfOrigin__c = '12345', systemOfOriginID__c = 'abcdefg', accountId__c = lstAccount[0].Id, 
                                                           billingAddress1__c = '10255 W Higgins Rd', billingAddress2__c = '10255 W Higgins Rd', billingAddress3__c = '10255 W Higgins Rd', 
                                                           billingAddressAccountID__c = lstAccount[0].Id, billingAddressBusinessName__c = 'Test', billingAddressCity__c = 'Rosemont1',
                                                           billingAddressCountry__c = 'Germany', billingAddressCountryCode__c = 'DE', billingAddressFirstName__c = 'Test', 
                                                           billingAddressIsLocked__c = false, billingAddressLastName__c = 'Test', billingAddressPostalCode__c = '60089',
                                                           billingAddressPrimaryPhone__c = '9876543210', billingAddressStateProvince__c = '', creditCardAuthorizationCode__c = '12356890qwertyuiosd',
                                                           billingAddressId__c = lstAddress[0].Id,shippingAddressId__c = lstAddress[1].Id,
                                                           creditCardExpirationDate__c = '0421',creditCardId__c = '', creditCardToken__c = '1234567890qwetyuio',
                                                           creditCardType__c = 'Visa',entityType__c = 'order', eventDate__c = '', eventSourceID__c = '123456',
                                                           invoiceDate__c = String.ValueOf(Date.today().addMonths(2)), invoiceNumber__c = '', isSignatureRequired__c = false, Line_Items__c = JSON.serialize(lstOLI),
                                                           orderNumber__c = lstOrder[0].OrderNumber, paymentTerm__c = '', pricebookName__c = 'DE Netto-Preis Cash',
                                                           rgaNumber__c = '', scheduledShipDate__c = '', shippingAddress1__c = '10255 W Higgins Rd',
                                                           shippingAddress2__c = '10255 W Higgins Rd', shippingAddress3__c = '10255 W Higgins Rd', shippingAddressAccountId__c = lstAccount[0].Id, 
                                                           shippingAddressBusinessName__c = 'test@123', shippingAddressCity__c = 'Rosemont1',
                                                           shippingAddressCountry__c = 'Germany', shippingAddressCountryCode__c = 'DE',shippingAddressFirstName__c = 'test', 
                                                           shippingAddressIsLocked__c = false, shippingAddressLastName__c = 'Test',
                                                           shippingAddressPostalCode__c = '60089', shippingAddressPrimaryPhone__c = '1234567890',
                                                           shippingAddressStateProvince__c = '', shippingMethod__c = 'NA',
                                                           shippingNotes__c = '', status__c = '',
                                                           statusMessage__c = '');
        Test.startTest(); 
        Database.SaveResult sr = EventBus.publish(oEvent);
        Test.stopTest();
    }
    @isTest private static void testUpdateOMS(){
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Payor', 'Germany')[0];
        List<Account> lstAccount = [SELECT Id, Name FROM Account];
        List<PEClsHandleOrderEvents.OrderLineItem> lstOLI = new List<PEClsHandleOrderEvents.OrderLineItem>();
        for(Product2 product : [SELECT Id, Name FROM Product2]){
            lstOLI.add(new PEClsHandleOrderEvents.OrderLineItem(product.Id, 1, 10));
        }
        List<Product2> lstProduct = [SELECT Id, Name FROM Product2];
         //Query for the Address record types
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                               where sObjectType='Address__c' and isActive=true];
    
        //Create a map between the Record Type Name and Id 
        Map<String,String> addRecordTypes = new Map<String,String>();
        for(RecordType rt: rtypes) {
        addRecordTypes.put(rt.Name,rt.Id);
        }     	
        String recordTypeId = addRecordTypes.get('DE Address');
        List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Account__c = lstAccount[0].Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = lstAccount[0].Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                                                          };
        insert lstAddress;
        List<PricebookEntry> lstPBE = [SELECT Id, Pricebook2Id FROM PricebookEntry WHERE Pricebook2.Name = 'DE Netto-Preis Cash'];
        Order objOrder = new Order(AccountId = lstAccount[0].Id, EffectiveDate = Date.today(), Status = 'Draft', Type = 'DE STANDARD', Payor__c = payorAccount.Id, Pricebook2Id = lstPBE[0].Pricebook2Id, Price_Book__c = lstPBE[0].Pricebook2Id);
        insert objOrder;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        for(PricebookEntry pbe : lstPBE){
            lstOrderItem.add(new OrderItem(PricebookEntryId = pbe.Id, OrderId = objOrder.Id, Quantity = 1, UnitPrice = 10));
        }
        insert lstOrderItem;
        List<Order> lstOrder = [SELECT Id, OrderNumber FROM Order]; 
        CRM_Order_Event__e oEvent = new CRM_Order_Event__e(version__c = '1.0',orderType__c = 'Sales_Order', operation__c = 'update',stage__c = 'pending',eventSource__c = 'OMS',
                                                           systemOfOrigin__c = '12345', systemOfOriginID__c = 'abcdefg', accountId__c = lstAccount[0].Id, 
                                                           billingAddress1__c = '10255 W Higgins Rd', billingAddress2__c = '10255 W Higgins Rd', billingAddress3__c = '10255 W Higgins Rd', 
                                                           billingAddressAccountID__c = lstAccount[0].Id, billingAddressBusinessName__c = 'Test', billingAddressCity__c = 'Rosemont1',
                                                           billingAddressCountry__c = 'Germany', billingAddressCountryCode__c = 'DE', billingAddressFirstName__c = 'Test', 
                                                           billingAddressIsLocked__c = false, billingAddressLastName__c = 'Test', billingAddressPostalCode__c = '60089',
                                                           billingAddressPrimaryPhone__c = '9876543210', billingAddressStateProvince__c = '', creditCardAuthorizationCode__c = '12356890qwertyuiosd',
                                                           billingAddressId__c = lstAddress[0].Id,shippingAddressId__c = lstAddress[1].Id,
                                                           creditCardExpirationDate__c = '0421',creditCardId__c = '', creditCardToken__c = '1234567890qwetyuio',
                                                           creditCardType__c = 'Visa',entityType__c = 'order', eventDate__c = '', eventSourceID__c = '123456',
                                                           invoiceDate__c = String.ValueOf(Date.today().addMonths(2)), invoiceNumber__c = '', isSignatureRequired__c = false, Line_Items__c = JSON.serialize(lstOLI),
                                                           orderNumber__c = lstOrder[0].OrderNumber, paymentTerm__c = '', pricebookName__c = 'DE Netto-Preis Cash',
                                                           rgaNumber__c = '', scheduledShipDate__c = '', shippingAddress1__c = '10255 W Higgins Rd',
                                                           shippingAddress2__c = '10255 W Higgins Rd', shippingAddress3__c = '10255 W Higgins Rd', shippingAddressAccountId__c = lstAccount[0].Id, 
                                                           shippingAddressBusinessName__c = 'test@123', shippingAddressCity__c = 'Rosemont1',
                                                           shippingAddressCountry__c = 'Germany', shippingAddressCountryCode__c = 'DE',
                                                           shippingAddressFirstName__c = 'test', shippingAddressIsLocked__c = false, shippingAddressLastName__c = 'Test',
                                                           shippingAddressPostalCode__c = '60089', shippingAddressPrimaryPhone__c = '1234567890',
                                                           shippingAddressStateProvince__c = '', shippingMethod__c = 'NA', shippingNotes__c = '');
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(oEvent);
        Test.stopTest();
    }
    
    @isTest private static void test(){
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Payor', 'Germany')[0];
        List<Account> lstAccount = [SELECT Id, Name FROM Account];
        List<PEClsHandleOrderEvents.OrderLineItem> lstOLI = new List<PEClsHandleOrderEvents.OrderLineItem>();
        for(Product2 product : [SELECT Id, Name FROM Product2]){
            lstOLI.add(new PEClsHandleOrderEvents.OrderLineItem(product.Id, 1, 10));
        }
        List<Product2> lstProduct = [SELECT Id, Name FROM Product2];
         //Query for the Address record types
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                               where sObjectType='Address__c' and isActive=true];
    
        //Create a map between the Record Type Name and Id 
        Map<String,String> addRecordTypes = new Map<String,String>();
        for(RecordType rt: rtypes) {
        addRecordTypes.put(rt.Name,rt.Id);
        }     	
        String recordTypeId = addRecordTypes.get('DE Address');
        List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Primary_Phone__c = '9876543210',RecordTypeId = recordTypeId, Business_Name__c = 'Test', Account__c = lstAccount[0].Id,Type__c = 'Bill To', First_Name__c = 'Test', Last_Name__c = 'Test', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Primary_Phone__c = '1234567890', RecordTypeId = recordTypeId,Business_Name__c = 'Test', Account__c = lstAccount[0].Id,Type__c = 'Ship To', First_Name__c = 'Test', Last_Name__c = 'Test', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = payorAccount.Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                                                          };
        insert lstAddress;
        List<PricebookEntry> lstPBE = [SELECT Id, Pricebook2Id FROM PricebookEntry WHERE Pricebook2.Name = 'DE Netto-Preis Cash'];
        Order objOrder = new Order(AccountId = lstAccount[0].Id, EffectiveDate = Date.today(), Status = 'Draft', Type = 'DE STANDARD', Payor__c = payorAccount.Id, Pricebook2Id = lstPBE[0].Pricebook2Id, Price_Book__c = lstPBE[0].Pricebook2Id);
        insert objOrder;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        for(PricebookEntry pbe : lstPBE){
            lstOrderItem.add(new OrderItem(PricebookEntryId = pbe.Id, OrderId = objOrder.Id, Quantity = 1, UnitPrice = 10));
        }
        insert lstOrderItem;
        List<Order> lstOrder = [SELECT Id, OrderNumber FROM Order]; 
        CRM_Order_Event__e oEvent = new CRM_Order_Event__e(version__c = '1.0',orderType__c = 'Sales_Order', operation__c = 'update',stage__c = 'pending',eventSource__c = 'OMS',
                                                           systemOfOrigin__c = '12345', systemOfOriginID__c = 'abcdefg', accountId__c = lstAccount[0].Id, 
                                                           billingAddress1__c = '10255 W Higgins Rd', billingAddress2__c = null, billingAddress3__c = null, 
                                                           billingAddressAccountID__c = lstAccount[0].Id, billingAddressBusinessName__c = 'Test', billingAddressCity__c = 'Rosemont',
                                                           billingAddressCountry__c = 'Germany', billingAddressCountryCode__c = 'DE', billingAddressFirstName__c = 'Test', 
                                                           billingAddressIsLocked__c = false, billingAddressLastName__c = 'Test', billingAddressPostalCode__c = '60089',
                                                           billingAddressPrimaryPhone__c = '9876543210', billingAddressStateProvince__c = '', creditCardAuthorizationCode__c = '12356890qwertyuiosd',
                                                           billingAddressId__c = lstAddress[0].Id,shippingAddressId__c = lstAddress[1].Id,
                                                           creditCardExpirationDate__c = '0421',creditCardId__c = '', creditCardToken__c = '1234567890qwetyuio',
                                                           creditCardType__c = 'Visa',entityType__c = 'order', eventDate__c = '', eventSourceID__c = '123456',
                                                           invoiceDate__c = String.ValueOf(Date.today().addMonths(2)), invoiceNumber__c = '', isSignatureRequired__c = false, Line_Items__c = JSON.serialize(lstOLI),
                                                           orderNumber__c = lstOrder[0].OrderNumber, paymentTerm__c = '', pricebookName__c = 'DE Netto-Preis Cash',
                                                           rgaNumber__c = '', scheduledShipDate__c = '', shippingAddress1__c = '10255 W Higgins Rd',
                                                           shippingAddress2__c = null, shippingAddress3__c = null, shippingAddressAccountId__c = lstAccount[0].Id, 
                                                           shippingAddressBusinessName__c = 'Test', shippingAddressCity__c = 'Rosemont',
                                                           shippingAddressCountry__c = 'Germany', shippingAddressCountryCode__c = 'DE',
                                                           shippingAddressFirstName__c = 'test', shippingAddressIsLocked__c = false, shippingAddressLastName__c = 'Test',
                                                           shippingAddressPostalCode__c = '60089', shippingAddressPrimaryPhone__c = '1234567890',
                                                           shippingAddressStateProvince__c = '', shippingMethod__c = 'NA', shippingNotes__c = '');
        PEClsHandleOrderEvents.parseValue('');
        PEClsHandleOrderEvents.createUniqueKey(lstAddress[0]);
        PEClsHandleOrderEvents.findDuplicateAddress(new Map<String, Address__c>{'12345abcdefg' => lstAddress[0]});
        lstOrder = PEClsHandleOrderEvents.getOrders(new Set<String>{objOrder.Id}, new Set<String>(), new Set<String>());
        PEClsHandleOrderEvents.parseOrderType('Test', 'OMS');
        PEClsHandleOrderEvents.mappingOrderEvent(lstOrder[0], null, null, 'completed', 'update');
        PEClsHandleOrderEvents.publishOrderEvent(new Set<String>{objOrder.Id}, new Set<String>(), 'update');
        PEClsHandleOrderEvents.mappingFinancialDetail(oEvent, new Order());
        PEClsHandleOrderEvents.addressMapping(oEvent, null, null, 'BillTo');
        PEClsHandleOrderEvents.isShippingAddressChanged(lstAddress[0], oEvent);
        PEClsHandleOrderEvents.isBillingAddressChanged(lstAddress[0], oEvent);
        PEClsHandleOrderEvents.orderMapping(oEvent, null, null, null, null, null, new Order(), null, 'CA STANDARD', 'create');
    }

}