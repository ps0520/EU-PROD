@isTest()
private class PEClsHandleOrderEvents_V11_Test {
	@testSetup static void setup() {
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCPB(new List<String>{'DE Netto-Preis Cash', 'DE Return Replace', 'Barmer'}, 'CHF');
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'Product-01', 'Product-02', 'Product-03', 'DEX-SHIP-01'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>{mapProduct.values()[0] => 10, mapProduct.values()[1] => 10, mapProduct.values()[2] => 10 };
        Map<Id, Id> mapPBE = ClsTestDataFactory.CreateCPBEntries(productIdToPriceMap, mapPriceBook.get('DE Netto-Preis Cash'), 'CHF');
        Account objAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Consumer', 'Germany')[0];
    }
    
    @isTest private static void test(){
		Id rtId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('CH Sales Order').getRecordTypeId();        
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
        Order objOrder = new Order(AccountId = lstAccount[0].Id, EffectiveDate = Date.today(), Status = 'Draft', Type = 'CH STANDARD', Payor__c = payorAccount.Id, Pricebook2Id = lstPBE[0].Pricebook2Id,
                                   RecordTypeId = rtId, CurrencyISOCode = 'CHF', Tax_Exempt__c = true);
        insert objOrder;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        for(PricebookEntry pbe : lstPBE){
            lstOrderItem.add(new OrderItem(PricebookEntryId = pbe.Id, OrderId = objOrder.Id, Quantity = 1, UnitPrice = 10));
        }
        insert lstOrderItem;
        List<Order> lstOrder = [SELECT Id, OrderNumber FROM Order];
        
        update new Order(id=lstOrder[0].id, Status='Activated');
        
        CRM_Order_Event_V1__e oEvent = new CRM_Order_Event_V1__e(version__c = '3.0',orderType__c = 'Sales_Order', operation__c = 'update',stage__c = 'pending',eventSource__c = 'OMS',
                                                           		 systemOfOrigin__c = '12345', systemOfOriginID__c = 'abcdefg',entityType__c = 'order',
                                                           		 orderNumber__c = lstOrder[0].OrderNumber, Status__c = 'booked');
        System.debug('====oEvent===='+JSON.serialize(oEvent));
        Test.startTest();
        	ClsOrderHandlerStatic.executeOrderEventTriggerv11 = true;
            Database.SaveResult sr = EventBus.publish(oEvent);
        Test.stopTest();
    }
    @isTest private static void test1(){
		Id rtId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('CH Sales Order').getRecordTypeId();        
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
        Order objOrder = new Order(AccountId = lstAccount[0].Id, EffectiveDate = Date.today(), Status = 'Draft', Type = 'CH STANDARD',
                                   Payor__c = payorAccount.Id, Pricebook2Id = lstPBE[0].Pricebook2Id,
                                   RecordTypeId = rtId, CurrencyISOCode = 'CHF');
        
        insert objOrder;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        for(PricebookEntry pbe : lstPBE){
            lstOrderItem.add(new OrderItem(PricebookEntryId = pbe.Id, OrderId = objOrder.Id, Quantity = 1, UnitPrice = 10));
        }
        insert lstOrderItem;
        List<Order> lstOrder = [SELECT Id, OrderNumber FROM Order];
        
        CRM_Order_Event_V1__e oEvent = new CRM_Order_Event_V1__e(version__c = '3.0',orderType__c = 'Sales_Order', operation__c = 'create',stage__c = 'confirmed',eventSource__c = 'OMS',
                                                           		 systemOfOrigin__c = 'crm', systemOfOriginID__c = 'abcdefg',entityType__c = 'order',
                                                           		 orderNumber__c = lstOrder[0].OrderNumber, Status__c = 'Activated');
        System.debug('====oEvent===='+JSON.serialize(oEvent));
        Test.startTest();
        	ClsOrderHandlerStatic.executeOrderEventTriggerv11 = true;
            Database.SaveResult sr = EventBus.publish(oEvent);
        Test.stopTest();
        
        //for(Order ord : lstOrder){
          //  ord.Shipping_Method__c = 'Priority (DHL Express)';
        //}
       //update lstOrder;
        
    }
    @isTest private static void createTest(){
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCPB(new List<String>{'UK G6 SUBSCRIPTION 12MOS'}, 'GBP');
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'MTLYCHARGE', 'Transmitter', 'Sensor'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>{mapProduct.values()[0] => 159, mapProduct.values()[1] => 0, mapProduct.values()[2] => 0 };
        Map<Id, Id> mapPBE = ClsTestDataFactory.CreateCPBEntries(productIdToPriceMap, mapPriceBook.get('UK G6 SUBSCRIPTION 12MOS'), 'GBP');
        List<PriceBookEntry> pbes = [Select product2.Name, Id from PriceBookEntry where pricebook2.Name = 'UK G6 SUBSCRIPTION 12MOS'];
        update new PriceBook2(Id=mapPriceBook.get('UK G6 SUBSCRIPTION 12MOS'),IsSubscription__c = true);
        for (PriceBookEntry pbe : pbes) {
            if (pbe.product2.name == 'MTLYCHARGE') {
                pbe.First_Order_Variation_Qty__c = 0;
                pbe.First_Repeat_Order_Lead_Days__c = 0;
                pbe.Number_of_Repeat_Orders__c = 12;
                pbe.SSIP_Next_Order_In_Days__c = 30;
                pbe.SSIP_Periodic_Order_Quantity__c = 1;
            }
            if (pbe.product2.name == 'Transmitter') {
                pbe.First_Order_Variation_Qty__c = 0;
                pbe.First_Repeat_Order_Lead_Days__c = 10;
                pbe.Number_of_Repeat_Orders__c = 4;
                pbe.SSIP_Next_Order_In_Days__c = 90;
                pbe.SSIP_Periodic_Order_Quantity__c = 1;
            }
            if (pbe.product2.name == 'Sensor') {
                pbe.First_Order_Variation_Qty__c = 0;
                pbe.First_Repeat_Order_Lead_Days__c = 10;
                pbe.Number_of_Repeat_Orders__c = 4;
                pbe.SSIP_Next_Order_In_Days__c = 90;
                pbe.SSIP_Periodic_Order_Quantity__c = 3;
            }
        }
        update pbes;    
            
        Account consumerAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'GB Consumer', 'United Kingdom')[0];
        CRM_Order_Event_V1__e oEvent = new CRM_Order_Event_V1__e (entityType__c='order',
            eventDate__c='2020-04-06T17:09:52.316Z',
            eventSource__c='ecom',
            eventSourceID__c='UK20000614',
            stage__c='pending',
            operation__c='create',
            systemOfOrigin__c='ecom',
            systemOfOriginID__c='UK20000614',
            parentSystemOfOriginID__c='UK00000613',
            version__c='3.0',
            author__c='null',
            metadata__c='null',
            accountID__c=consumerAccount.id,
            orderNumber__c='UK10000614',
            orderType__c='GBSTANDARD',
            status__c='booked',
            statusMessage__c='null',
            action__c='null',
            invoiceNumber__c='null',
            poNumber__c='null',
            invoiceDate__c='null',
            isSignatureRequired__c=null,
            scheduledShipDate__c='null',
            shippingAmount__c=0.0,
            shippingMethod__c='DPD Local|Ground|0|BS1',
            shippingNotes__c='null',
            shippingEmail__c='zSUBtestUK14@mailinator.com',
            shippingAddressID__c='null',
            shippingAddressAccountID__c=consumerAccount.id,
            shippingAddressIsLocked__c=false,
            shippingAddressIsPrimary__c=null,
            shippingAddressBusinessName__c='null',
            shippingAddressFirstName__c='SUB14',
            shippingAddressLastName__c='Test',
            shippingAddress1__c='451 Alexandra Avenue',
            shippingAddress2__c='null',
            shippingAddress3__c='null',
            shippingAddressCity__c='Harrow',
            shippingAddressStateProvince__c='null',
            shippingAddressPostalCode__c='HA2 9SE',
            shippingAddressCountryCode__c='GB',
            shippingAddressCountry__c='null',
            shippingAddressPrimaryPhone__c='22233334444',
            shippingTaxRegistrationNumber__c='null',
            shippingTaxExempt__c=false,
            billingAddressID__c='null',
            billingAddressAccountID__c=consumerAccount.id,
            billingAddressIsLocked__c=null,
            billingAddressIsPrimary__c=null,
            billingAddressBusinessName__c='null',
            billingAddressFirstName__c='SUB14',
            billingAddressLastName__c='Test',
            billingAddress1__c='451 Alexandra Avenue',
            billingAddress2__c='null',
            billingAddress3__c='null',
            billingAddressCity__c='Harrow',
            billingAddressStateProvince__c='null',
            billingAddressPostalCode__c='HA2 9SE',
            billingAddressCountryCode__c='GB',
            billingAddressCountry__c='null',
            billingAddressPrimaryPhone__c='22233334444',
            billingTaxRegistrationNumber__c='null',
            billingTaxExempt__c=false,
            paymentMethod__c='null',
            paymentTerm__c='net0',
            creditCardID__c='null',
            creditCardType__c='Visa',
            creditCardExpirationDate__c='07/2025',
            creditCardToken__c='7010000000055671111',
            creditCardAuthorizationCode__c='831000',
            creditCardTransactionID__c='5861928563596251804009',
            bankID__c='null',
            bankName__c='null',
            branchName__c='null',
            bic__c='null',
            iban__c='null',
            bankAccountName__c='null',
            bankAccountNumber__c='null',
            bankCurrencyCode__c='null',
            bankCountryCode__c='null',
            currencyCode__c='null',
            rgaNumber__c='null',
            warehouse__c='HLUK',
            pricebookName__c='UK G6 SUBSCRIPTION 12MOS',
            totalAmount__c=190.8,
            deliveryTerm__c='null',
            tax__c='null');
        
        	//Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGenCCSettle());
        Test.startTest();
        	ClsOrderHandlerStatic.executeOrderEventTriggerv11 = true;
        	EventBus.publish(oEvent);
        //System.enqueueJob(new PEBatchOrderEvent.SettlePaymentQueueable() );
        Test.stopTest();
            
    }
    @isTest private static void createTest2(){
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCPB(new List<String>{'UK Cash List Price'}, 'GBP');
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'MT22754', 'DEX-SHIP-01-01'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>{mapProduct.values()[0] => 12.59, mapProduct.values()[1] => 1};
        Map<Id, Id> mapPBE = ClsTestDataFactory.CreateCPBEntries(productIdToPriceMap, mapPriceBook.get('UK Cash List Price'), 'GBP');
        Account consumerAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'GB Consumer', 'United Kingdom')[0];
        CRM_Order_Event_V1__e oEvent = new CRM_Order_Event_V1__e (  entityType__c='order',
           eventDate__c='2020-04-01T21:45:02.198Z',
           eventSource__c='OMS',
           eventSourceID__c='50001155', 
           stage__c='pending',
           operation__c='update',
           systemOfOrigin__c='OMS',
           systemOfOriginID__c='50001155',
           parentSystemOfOriginID__c=null,
           version__c='3.1',
           author__c='null',
           metadata__c='null',
           accountID__c=consumerAccount.id,
           orderNumber__c='D8UK00001155',
           orderType__c='GB STANDARD',
           status__c='booked',
           statusMessage__c='null',
           action__c='null',
           invoiceNumber__c='null',
           poNumber__c='null',
           invoiceDate__c='null',
           isSignatureRequired__c=true,
           scheduledShipDate__c='null',
           shippingAmount__c=11.38,
           shippingMethod__c='DPD Local|Ground|1138|BSN',
           shippingNotes__c='true',
           shippingEmail__c='false',
           shippingAddressID__c='null',
           shippingAddressAccountID__c=consumerAccount.id,
           shippingAddressIsLocked__c=false,
           shippingAddressIsPrimary__c=null,
           shippingAddressBusinessName__c='null',
           shippingAddressFirstName__c='Josh',
           shippingAddressLastName__c='George',
           shippingAddress1__c='2 Valleywood Dr',
           shippingAddress2__c='null',
           shippingAddress3__c='null',
           shippingAddressCity__c='Markham',
           shippingAddressStateProvince__c='null',
           shippingAddressPostalCode__c='A11 1AA',
           shippingAddressCountryCode__c='GB',
           shippingAddressCountry__c='null',
           shippingAddressPrimaryPhone__c='55555555555',
           shippingTaxRegistrationNumber__c='null',
           shippingTaxExempt__c=true,
           billingAddressID__c='null',
           billingAddressAccountID__c=consumerAccount.id,
           billingAddressIsLocked__c=null,
           billingAddressIsPrimary__c=null,
           billingAddressBusinessName__c='null',
           billingAddressFirstName__c='Josh',
           billingAddressLastName__c='George',
           billingAddress1__c='2 Valleywood Dr',
           billingAddress2__c='null',
           billingAddress3__c='null',
           billingAddressCity__c='Markham',
           billingAddressStateProvince__c='null',
           billingAddressPostalCode__c='A11 1AA',
           billingAddressCountryCode__c='GB',
           billingAddressCountry__c='null',
           billingAddressPrimaryPhone__c='55555555555',
           billingTaxRegistrationNumber__c='null',
           billingTaxExempt__c=true,
           paymentMethod__c='null',
           paymentTerm__c='net0',
           creditCardID__c='null',
           creditCardType__c='Visa',
           creditCardExpirationDate__c='08/2025',
           creditCardToken__c='7010000000055671111',
           creditCardAuthorizationCode__c='831000',
           creditCardTransactionID__c='5857775016956017804008',
           bankID__c='null',
           bankName__c='null',
           branchName__c='null',
           bic__c='null',
           iban__c='null',
           bankAccountName__c='null',
           bankAccountNumber__c='null',
           bankCurrencyCode__c='null',
           bankCountryCode__c='null',
           currencyCode__c='null',
           rgaNumber__c='null',
           warehouse__c='HLUK',
           pricebookName__c='UK Cash List Price',
           totalAmount__c=23.97,
		   Line_Items__c='[{\"itemID\":\"MT22754\",\"sku\":\"MT22754\",\"quantity\":1.0,\"price\":12.59,\"isBundle\":false,\"isBundleItem\":false,\"skuBundle\":null,\"total\":null,\"tax\":{\"source\":\"ecom\",\"type\":\"VAT\",\"amount\":0.0,\"rate\":0.0}},{\"itemID\":\"DEX-SHIP-01\",\"sku\":\"DEX-SHIP-01\",\"quantity\":11.38,\"price\":1.0,\"isBundle\":null,\"isBundleItem\":null,\"skuBundle\":null,\"total\":11.38,\"tax\":{\"source\":\"ecom\",\"type\":\"VAT\",\"amount\":0.0,\"rate\":0.0}}]',           
           tax__c='null'  
        );
        Test.startTest();
        	ClsOrderHandlerStatic.executeOrderEventTriggerv11 = true;
        	EventBus.publish(oEvent);
        Test.stopTest();
    }
    @isTest private static void createTestForConfirmed(){
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCPB(new List<String>{'UK Cash List Price'}, 'GBP');
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'MT22754', 'DEX-SHIP-01-01'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>{mapProduct.values()[0] => 12.59, mapProduct.values()[1] => 1};
        Map<Id, Id> mapPBE = ClsTestDataFactory.CreateCPBEntries(productIdToPriceMap, mapPriceBook.get('UK Cash List Price'), 'GBP');
        Account consumerAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'GB Consumer', 'United Kingdom')[0];
        CRM_Order_Event_V1__e oEvent = new CRM_Order_Event_V1__e (  entityType__c='order',
           eventDate__c='2020-04-01T21:45:02.198Z',
           eventSource__c='OMS',
           eventSourceID__c='50001155', 
           stage__c='confirmed',
           operation__c='create',
           systemOfOrigin__c='crm',
           systemOfOriginID__c='50001155',
           parentSystemOfOriginID__c=null,
           version__c='3.1',
           author__c='null',
           metadata__c='null',
           accountID__c=consumerAccount.id,
           orderNumber__c='D8UK00001155',
           orderType__c='GB STANDARD',
           status__c='booked',
           statusMessage__c='null',
           action__c='null',
           invoiceNumber__c='null',
           poNumber__c='null',
           invoiceDate__c='null',
           isSignatureRequired__c=true,
           scheduledShipDate__c='null',
           shippingAmount__c=11.38,
           shippingMethod__c='DPD Local|Ground|1138|BSN',
           shippingNotes__c='true',
           shippingEmail__c='false',
           shippingAddressID__c='null',
           shippingAddressAccountID__c=consumerAccount.id,
           shippingAddressIsLocked__c=false,
           shippingAddressIsPrimary__c=null,
           shippingAddressBusinessName__c='null',
           shippingAddressFirstName__c='Josh',
           shippingAddressLastName__c='George',
           shippingAddress1__c='2 Valleywood Dr',
           shippingAddress2__c='null',
           shippingAddress3__c='null',
           shippingAddressCity__c='Markham',
           shippingAddressStateProvince__c='null',
           shippingAddressPostalCode__c='A11 1AA',
           shippingAddressCountryCode__c='GB',
           shippingAddressCountry__c='null',
           shippingAddressPrimaryPhone__c='55555555555',
           shippingTaxRegistrationNumber__c='null',
           shippingTaxExempt__c=true,
           billingAddressID__c='null',
           billingAddressAccountID__c=consumerAccount.id,
           billingAddressIsLocked__c=null,
           billingAddressIsPrimary__c=null,
           billingAddressBusinessName__c='null',
           billingAddressFirstName__c='Josh',
           billingAddressLastName__c='George',
           billingAddress1__c='2 Valleywood Dr',
           billingAddress2__c='null',
           billingAddress3__c='null',
           billingAddressCity__c='Markham',
           billingAddressStateProvince__c='null',
           billingAddressPostalCode__c='A11 1AA',
           billingAddressCountryCode__c='GB',
           billingAddressCountry__c='null',
           billingAddressPrimaryPhone__c='55555555555',
           billingTaxRegistrationNumber__c='null',
           billingTaxExempt__c=true,
           paymentMethod__c='null',
           paymentTerm__c='net0',
           creditCardID__c='null',
           creditCardType__c='Visa',
           creditCardExpirationDate__c='08/2025',
           creditCardToken__c='7010000000055671111',
           creditCardAuthorizationCode__c='831000',
           creditCardTransactionID__c='5857775016956017804008',
           bankID__c='null',
           bankName__c='null',
           branchName__c='null',
           bic__c='null',
           iban__c='null',
           bankAccountName__c='null',
           bankAccountNumber__c='null',
           bankCurrencyCode__c='null',
           bankCountryCode__c='null',
           currencyCode__c='null',
           rgaNumber__c='null',
           warehouse__c='HLUK',
           pricebookName__c='UK Cash List Price',
           totalAmount__c=23.97,
		   Line_Items__c='[{\"itemID\":\"MT22754\",\"sku\":\"MT22754\",\"quantity\":1.0,\"price\":12.59,\"isBundle\":false,\"isBundleItem\":false,\"skuBundle\":null,\"total\":null,\"tax\":{\"source\":\"ecom\",\"type\":\"VAT\",\"amount\":0.0,\"rate\":0.0}},{\"itemID\":\"DEX-SHIP-01\",\"sku\":\"DEX-SHIP-01\",\"quantity\":11.38,\"price\":1.0,\"isBundle\":null,\"isBundleItem\":null,\"skuBundle\":null,\"total\":11.38,\"tax\":{\"source\":\"ecom\",\"type\":\"VAT\",\"amount\":0.0,\"rate\":0.0}}]',           
           tax__c='null'  
        );
        Test.startTest();
        	ClsOrderHandlerStatic.executeOrderEventTriggerv11 = true;
        	EventBus.publish(oEvent);
        Test.stopTest();
    }
    @isTest private static void createTestForInvalidVersion(){
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCPB(new List<String>{'UK Cash List Price'}, 'GBP');
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'MT22754', 'DEX-SHIP-01-01'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>{mapProduct.values()[0] => 12.59, mapProduct.values()[1] => 1};
        Map<Id, Id> mapPBE = ClsTestDataFactory.CreateCPBEntries(productIdToPriceMap, mapPriceBook.get('UK Cash List Price'), 'GBP');
        Account consumerAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'GB Consumer', 'United Kingdom')[0];
        CRM_Order_Event_V1__e oEvent = new CRM_Order_Event_V1__e (  entityType__c='',
           eventDate__c='2020-04-01T21:45:02.198Z',
           eventSource__c='OMS',
           eventSourceID__c='50001155', 
           stage__c='confirmed',
           operation__c='create',
           systemOfOrigin__c='crm',
           systemOfOriginID__c='50001155',
           parentSystemOfOriginID__c=null,
           version__c='33.0',
           author__c='null',
           metadata__c='null',
           accountID__c=consumerAccount.id,
           orderNumber__c='D8UK00001155',
           orderType__c='GB STANDARD',
           status__c='booked',
           statusMessage__c='null',
           action__c='null',
           invoiceNumber__c='null',
           poNumber__c='null',
           invoiceDate__c='null',
           isSignatureRequired__c=true,
           scheduledShipDate__c='null',
           shippingAmount__c=11.38,
           shippingMethod__c='DPD Local|Ground|1138|BSN',
           shippingNotes__c='true',
           shippingEmail__c='false',
           shippingAddressID__c='null',
           shippingAddressAccountID__c=consumerAccount.id,
           shippingAddressIsLocked__c=false,
           shippingAddressIsPrimary__c=null,
           shippingAddressBusinessName__c='null',
           shippingAddressFirstName__c='Josh',
           shippingAddressLastName__c='George',
           shippingAddress1__c='2 Valleywood Dr',
           shippingAddress2__c='null',
           shippingAddress3__c='null',
           shippingAddressCity__c='Markham',
           shippingAddressStateProvince__c='null',
           shippingAddressPostalCode__c='A11 1AA',
           shippingAddressCountryCode__c='GB',
           shippingAddressCountry__c='null',
           shippingAddressPrimaryPhone__c='55555555555',
           shippingTaxRegistrationNumber__c='null',
           shippingTaxExempt__c=true,
           billingAddressID__c='null',
           billingAddressAccountID__c=consumerAccount.id,
           billingAddressIsLocked__c=null,
           billingAddressIsPrimary__c=null,
           billingAddressBusinessName__c='null',
           billingAddressFirstName__c='Josh',
           billingAddressLastName__c='George',
           billingAddress1__c='2 Valleywood Dr',
           billingAddress2__c='null',
           billingAddress3__c='null',
           billingAddressCity__c='Markham',
           billingAddressStateProvince__c='null',
           billingAddressPostalCode__c='A11 1AA',
           billingAddressCountryCode__c='GB',
           billingAddressCountry__c='null',
           billingAddressPrimaryPhone__c='55555555555',
           billingTaxRegistrationNumber__c='null',
           billingTaxExempt__c=true,
           paymentMethod__c='null',
           paymentTerm__c='net0',
           creditCardID__c='null',
           creditCardType__c='Visa',
           creditCardExpirationDate__c='08/2025',
           creditCardToken__c='7010000000055671111',
           creditCardAuthorizationCode__c='831000',
           creditCardTransactionID__c='5857775016956017804008',
           bankID__c='null',
           bankName__c='null',
           branchName__c='null',
           bic__c='null',
           iban__c='null',
           bankAccountName__c='null',
           bankAccountNumber__c='null',
           bankCurrencyCode__c='null',
           bankCountryCode__c='null',
           currencyCode__c='null',
           rgaNumber__c='null',
           warehouse__c='HLUK',
           pricebookName__c='UK Cash List Price',
           totalAmount__c=23.97,
		   Line_Items__c='[{\"itemID\":\"MT22754\",\"sku\":\"MT22754\",\"quantity\":1.0,\"price\":12.59,\"isBundle\":false,\"isBundleItem\":false,\"skuBundle\":null,\"total\":null,\"tax\":{\"source\":\"ecom\",\"type\":\"VAT\",\"amount\":0.0,\"rate\":0.0}},{\"itemID\":\"DEX-SHIP-01\",\"sku\":\"DEX-SHIP-01\",\"quantity\":11.38,\"price\":1.0,\"isBundle\":null,\"isBundleItem\":null,\"skuBundle\":null,\"total\":11.38,\"tax\":{\"source\":\"ecom\",\"type\":\"VAT\",\"amount\":0.0,\"rate\":0.0}}]',           
           tax__c='null'  
        );
        Test.startTest();
        	ClsOrderHandlerStatic.executeOrderEventTriggerv11 = true;
        	EventBus.publish(oEvent);
        Test.stopTest();
    }
   
    
}