@isTest
public class CtrlOrderAuditTest {
     
     public static id TestOrderCreationAndUpdate(){
         
          Id ATrectypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('AT Sales Order').getRecordTypeId();
          Id recordTypeIdCA = Schema.SObjectType.Account.getRecordTypeInfosByName().get('AT Consumer').getRecordTypeId();
        Account CHacc = new Account();
        CHacc.CurrencyIsoCode = 'EUR';
        CHacc.RecordTypeId = recordTypeIdCA;
        CHacc.FirstName='TestConsumerFirstName';
        CHacc.LastName='TestConsumerLastName';
        CHacc.BillingStreet = 'Grüner Weg';
        CHacc.BillingCity = 'Friedberg';
        CHacc.BillingPostalCode = '1234';
        CHacc.BillingCountryCode = 'AT';
        CHacc.PersonEmail = 'Tesdt@gmail.com';
        CHacc.PersonHasOptedOutOfEmail = false;
        insert CHacc;
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'AT Cash'});
        String customPricebookId = customPricebookMap.get('AT Cash');

        //Create Products
         Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'VIRTUAL_SKU', 'DEX-SHIP-01'});
         Set<String> prdtName = new Set<String>();
         prdtName.add('DEX-SHIP-01');
         prdtName.add('VIRTUAL_SKU');
         
         List<Product2> lstProd = new List<Product2>();
         lstProd = [SELECT Id, Is_Virtual_Product__c FROM Product2 WHERE NAME IN:prdtName];
         for(Product2 virtualProd :lstProd){
             virtualProd.Is_Virtual_Product__c = true; 
         }
         update lstProd;
         
         //Create Pricebook EntryPair
         Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
         for(String productName : products.keySet()){
             productIdToPriceMap.put(products.get(productName), 125.00);
             
         }
         Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, customPricebookId);
        
        //Create Order record
		ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = CHacc.Id;
        newOrder.Type = 'AT STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;
        newOrder.RecordTypeId = ATrectypeId; 
        //newOrder.Pricebook2Id = customPricebookId;//added by Shailendra to resolve the issue..
        newOrder.Status = 'Draft';
        newOrder.CurrencyIsoCode = 'EUR';
         //Payment_Terms__c = 'net0';
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
         return newOrder.Id;
        
    }
    
    @isTest
    public static void testGetaccessibility() {
        
        Id oid = TestOrderCreationAndUpdate();
        Test.startTest();
        update new Order(id=oid, shipping_hold_status__c = 'completed');
        CtrlOrderAudit.getaccessibility((String) oid);
        Test.stopTest();
        //
    } 
    @isTest
    public static void testInithelpermethod() {
        Id oid = TestOrderCreationAndUpdate();
        Test.startTest();
        List<Audit_Tracker__c> lstAuditTrail = new List<Audit_Tracker__c>();
        lstAuditTrail.addAll(new List<Audit_Tracker__c>{    new Audit_Tracker__c(Audit_Field_Name__c = 'Approval', Field_Verified__c = false, Object_Id__c = oid),
                             new Audit_Tracker__c(Audit_Field_Name__c = 'Price', Field_Verified__c = false, Object_Id__c = oid),
                             new Audit_Tracker__c(Audit_Field_Name__c = 'Payor', Field_Verified__c = false, Object_Id__c = oid)
                             });
        if (lstAuditTrail.size() > 0) insert lstAuditTrail;
        CtrlOrderAudit.inithelpermethod((String) oid);
        test.stopTest();
        //
    }
    @isTest
    public static void testSaveaudit() {
        Id oid = TestOrderCreationAndUpdate();
        Test.startTest();
        
        //ClsOusTaxCalculator.calculateTaxLocally(oid);
        update new Order(id=oid,Need_To_Calculate_Tax__c='false',Tax_Exempt__c=false, Status='Shipping Hold');
        List<Audit_Tracker__c> lstAuditTrail = new List<Audit_Tracker__c>();
        lstAuditTrail.addAll(new List<Audit_Tracker__c>{    new Audit_Tracker__c(Audit_Field_Name__c = 'Approval', Field_Verified__c = false, Object_Id__c = oid),
                             new Audit_Tracker__c(Audit_Field_Name__c = 'Price', Field_Verified__c = false, Object_Id__c = oid),
                             new Audit_Tracker__c(Audit_Field_Name__c = 'Payor', Field_Verified__c = false, Object_Id__c = oid)
                             });
        if (lstAuditTrail.size() > 0) insert lstAuditTrail;
        List<Audit_Tracker__c> auditrecs = [Select Id, Audit_Field_Name__c, Field_Verified__c FROM Audit_Tracker__c /*WHERE Object_Id__c = :oid */];
        if (auditrecs.size() > 0) {
            String retVal = CtrlOrderAudit.saveaudit(auditrecs);
    	}
        Test.stopTest();
    }
   
      @isTest
    public static void testSubmitaudit() {
         Id oid = TestOrderCreationAndUpdate();
        Test.startTest();
       // ClsOusTaxCalculator.calculateTaxLocally(oid);
       // Id rectypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('GB Sales Order').getRecordTypeId();
        update new Order(id=oid,Need_To_Calculate_Tax__c='false',Tax_Exempt__c=false, Status='Shipping Hold');
        
        List<Audit_Tracker__c> lstAuditTrail = new List<Audit_Tracker__c>();
        lstAuditTrail.addAll(new List<Audit_Tracker__c>{    new Audit_Tracker__c(Audit_Field_Name__c = 'Approval', Field_Verified__c = false, Object_Id__c = oid),
                             new Audit_Tracker__c(Audit_Field_Name__c = 'Price', Field_Verified__c = false, Object_Id__c = oid),
                             new Audit_Tracker__c(Audit_Field_Name__c = 'Payor', Field_Verified__c = false, Object_Id__c = oid)
                             });
        if (lstAuditTrail.size() > 0) insert lstAuditTrail;
        List<Audit_Tracker__c> auditrecs = [Select Id, Audit_Field_Name__c, Field_Verified__c FROM Audit_Tracker__c /*WHERE Object_Id__c = :oid */];
        if (auditrecs.size() > 0) {
            String retVal = CtrlOrderAudit.submitaudit((String) oid, auditrecs);
    	}
        
        Test.stopTest();
        
    }
    
     @isTest
    public static void testSubmitauditDE() {
         Id oid = TestOrderCreationAndUpdate();
         Id rectypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('DE Sales Order').getRecordTypeId();
        Order upOrder = new Order();
        upOrder.id = oid;
        upOrder.Need_To_Calculate_Tax__c='false';
        upOrder.Tax_Exempt__c=false;
        upOrder.RecordTypeId = rectypeId;
        update upOrder;
        oid = upOrder.id; 
        Test.startTest();
        //ClsOusTaxCalculator.calculateTaxLocally(oid);
        
       
        
        
        update new Order(id=oid, Status='Shipping Hold');
        
        List<Audit_Tracker__c> lstAuditTrail = new List<Audit_Tracker__c>();
        lstAuditTrail.addAll(new List<Audit_Tracker__c>{    new Audit_Tracker__c(Audit_Field_Name__c = 'Approval', Field_Verified__c = false, Object_Id__c = oid),
                             new Audit_Tracker__c(Audit_Field_Name__c = 'Price', Field_Verified__c = false, Object_Id__c = oid),
                             new Audit_Tracker__c(Audit_Field_Name__c = 'Payor', Field_Verified__c = false, Object_Id__c = oid)
                             });
        if (lstAuditTrail.size() > 0) insert lstAuditTrail;
        List<Audit_Tracker__c> auditrecs = [Select Id, Audit_Field_Name__c, Field_Verified__c FROM Audit_Tracker__c /*WHERE Object_Id__c = :oid */];
        if (auditrecs.size() > 0) {
            String retVal = CtrlOrderAudit.submitaudit((String) oid, auditrecs);
    	}
        
        Test.stopTest();
        
    }
    
    @isTest
    public static void testSubmitauditPaymentTerm() {
         Id oid = TestOrderCreationAndUpdate();
        Test.startTest();
        //ClsOusTaxCalculator.calculateTaxLocally(oid);
        Order objOrder= new Order(id=oid, Status='Shipping Hold',Payment_Terms__c = 'net0',Payment_Id__c='12412',CC_Auth_Amount__c=600);
        //update objOrder;
        List<Audit_Tracker__c> lstAuditTrail = new List<Audit_Tracker__c>();
        lstAuditTrail.addAll(new List<Audit_Tracker__c>{    new Audit_Tracker__c(Audit_Field_Name__c = 'Approval', Field_Verified__c = true, Object_Id__c = objOrder.Id),
                             new Audit_Tracker__c(Audit_Field_Name__c = 'Price', Field_Verified__c = true, Object_Id__c = objOrder.Id),
                             new Audit_Tracker__c(Audit_Field_Name__c = 'Payor', Field_Verified__c = false, Object_Id__c = objOrder.Id)
                             });
        if (lstAuditTrail.size() > 0) insert lstAuditTrail;
        List<Audit_Tracker__c> auditrecs = [Select Id, Audit_Field_Name__c, Field_Verified__c FROM Audit_Tracker__c /*WHERE Object_Id__c = :oid */];
        
        if (auditrecs.size() > 0) {
            for(Audit_Tracker__c audit :auditrecs){
                audit.Field_Verified__c = true;
            }
            update auditrecs;
            String retVal = CtrlOrderAudit.submitaudit((String) oid, auditrecs);
            
    	} 
        
        Test.stopTest();
        
    }
   
     @isTest
    public static void testCreateTask() { 
        Id oid = TestOrderCreationAndUpdate();
        Test.startTest();
         
        String userId = UserInfo.getUserId();
         CtrlOrderAudit.getTaskSubject();
         CtrlOrderAudit.searchUser(userId);
        Task tsk =  ClsTestDataFactory.createTask();
        tsk.WhatId= oid; 
        insert tsk;
        CtrlOrderAudit.updateTask(String.valueOf(tsk.Id),String.valueOf(tsk.Subject),String.valueOf(tsk.ActivityDate),String.valueOf(tsk.OwnerId),String.valueOf(tsk.WhatId),tsk.Description);
        ClsInputLookupCtrl.loadDefault('Tom Tom', 'User');
        ClsInputLookupCtrl.searchLookup('Tom Tom', 'User');
        ClsInputLookupCtrl.searchUser( UserInfo.getUserId());
        ClsInputLookupCtrl.searchLookup('', '');
        Test.stopTest();
    }

}