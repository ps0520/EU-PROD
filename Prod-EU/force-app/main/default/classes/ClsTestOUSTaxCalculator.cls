@isTest()
global class ClsTestOUSTaxCalculator {
    global class MockHttpResponseGenerator implements HttpCalloutMock {
        public Integer statusCode;
        public MockHttpResponseGenerator(Integer statusCode){
            this.statusCode = statusCode;
        }
        global HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{ "calculateTransactionTaxEstimateResponse" : {"result":[{"LineNumber" : "0", "TaxLine" : "1", "TaxRateCode":"DE I   STD", "TaxRate" : "19", "TaxAmount":"46.78", "Inclusive" : "N", "SelfAssessed" : "N", "TaxOnlyLine":"N", "TaxRegimeCode" : "DE Tax","Tax":"DE TAX", "TaxJurisdictionCode": "DE BMF", "TaxJurisdictionName":"Bundesministerium der Finanzen", "TaxPointBasis":"ACCOUNTING" }]}}');
            res.setStatusCode(statusCode);
            return res;
        }
    }
        
	@testSetup static void setup() {
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCPB(new List<String>{'DE Netto-Preis Cash', 'DE Return Replace', 'Barmer'}, 'CHF');
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'Product-01', 'Product-02', 'Product-03', 'DEX-SHIP-01'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>{mapProduct.values()[0] => 10, mapProduct.values()[1] => 10, mapProduct.values()[2] => 10 };
        Map<Id, Id> mapPBE = ClsTestDataFactory.CreateCPBEntries(productIdToPriceMap, mapPriceBook.get('DE Netto-Preis Cash'), 'CHF');
        Account objAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Consumer', 'Germany')[0];
    }
    
    @isTest private static void test(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
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
                                   RecordTypeId = rtId, CurrencyISOCode = 'CHF');
        insert objOrder;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        lstOrderItem.add(new OrderItem(PricebookEntryId = lstPBE[0].Id, OrderId = objOrder.Id, Quantity = 1, UnitPrice = 10));
        insert lstOrderItem;
        test.startTest();
        String response = ClsOUSTaxCalculator.calculateTax(objOrder.Id);
        test.stopTest();
    }
    
    @isTest private static void test1(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500));
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
                                   RecordTypeId = rtId, CurrencyISOCode = 'CHF');
        insert objOrder;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        lstOrderItem.add(new OrderItem(PricebookEntryId = lstPBE[0].Id, OrderId = objOrder.Id, Quantity = 1, UnitPrice = 10));
        insert lstOrderItem;
        test.startTest();
        String response = ClsOUSTaxCalculator.calculateTax(objOrder.Id);
        test.stopTest();
    }
}