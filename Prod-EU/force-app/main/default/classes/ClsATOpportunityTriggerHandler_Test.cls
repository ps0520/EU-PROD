@isTest
public class ClsATOpportunityTriggerHandler_Test {
	
    @isTest 
    static void InsertTestDataAT(){        
        
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Account' and isActive=true];
        //Create a map between the Record Type Name and Id 
        Map<String,String> accountRecordTypes = new Map<String,String>();
        for(RecordType rt: rtypes)
            accountRecordTypes.put(rt.Name,rt.Id);
        List<Account> accts = new List<Account>();
        Map<Id, Opportunity> newTriggerOpportunities = new Map<Id, Opportunity>();
        Map<Id, Opportunity> oldTriggerOpportunities = new Map<Id, Opportunity>();
        
        String recordTypeIdAT = accountRecordTypes.get('AT Consumer');
        Account ATacc = new Account();
        ATacc.CurrencyIsoCode = 'EUR';
        ATacc.RecordTypeId = recordTypeIdAT;
        ATacc.FirstName='TestConsumerFirstName';
        ATacc.LastName='TestConsumerLastName';
        ATacc.BillingStreet = 'Grüner Weg';
        ATacc.BillingCity = 'Friedberg';
        ATacc.BillingPostalCode = '1234';
        ATacc.BillingCountryCode = 'AT';
        ATacc.PersonEmail = 'Tesdt@gmail.com';
        ATacc.PersonHasOptedOutOfEmail = false;
        insert ATacc; 
        
        String recordTypeIdMed = accountRecordTypes.get('AT Medical Facility');
        Account ATaccMed = new Account();
        ATaccMed.CurrencyIsoCode = 'EUR';
        ATaccMed.RecordTypeId = recordTypeIdMed;
        ATaccMed.name = 'Med';
        ATaccMed.Phone = '1234567891' ;
        ATaccMed.BillingStreet = 'Grüner Weg';
        ATaccMed.BillingCity = 'Friedberg';
        ATaccMed.BillingPostalCode = '1244';
        ATaccMed.BillingCountryCode = 'AT';
        insert ATaccMed; 
        
        ATacc.Medical_Facility__c = ATaccMed.id;
        update ATacc ;
        
        account accPayor = new Account();
        String recordTypeId = accountRecordTypes.get('AT Payor');
        accPayor.CurrencyIsoCode = 'EUR';
        accPayor.RecordTypeId = recordTypeId;
       	accPayor.Name = 'Test Payor 2';
		accPayor.Insurance_Company_Identification_Number__c = '1223444';
        accPayor.BillingStreet = 'Grüner Weg';
        accPayor.BillingCity = 'Friedberg';
        accPayor.BillingPostalCode = 'V7J 3H5';
        accPayor.BillingCountryCode = 'CA';
        accPayor.BillingStateCode = 'AB';
        accPayor.BillingState = 'Alberta';
        insert accPayor;
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCPB(new List <String>{'AT_Pricebook'}, 'EUR');
        String customPricebookId = customPricebookMap.get('AT_Pricebook');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004'/*, 'DEX-SHIP-01'*/});
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
            productIdToPriceMap.put(products.get(productName), 125.00);

        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, customPricebookId);

        Id oppRecTypeAT = [Select Id from RecordType Where isActive = true AND DeveloperName = 'AT_Opportunity'].id;
        Opportunity newOppAT = new Opportunity();
        newOppAT.RecordTypeId = oppRecTypeAT;
        newOppAT.Name = 'New Opportunity For Testing';
        newOppAT.CurrencyIsoCode = 'EUR';
        newOppAT.AccountId = ATacc.Id;
        newOppAT.Payor__c = accPayor.Id;
        newOppAT.Type = 'New';
        newOppAT.Contact_Letter_Sent__c = true;
        newOppAT.Contact_Doc_Received__c = true;
        newOppAT.Insurance_Doc_Received__c = true;
        newOppAT.Hard_Copy_Out__c = true;
        newOppAT.Hard_Copy_In__c = true;
        newOppAT.Training_Letter_Sent__c = true;
        newOppAT.Training_Letter_Sent_Date__c = Date.Today();
        newOppAT.StageName = 'New Opportunity';
        newOppAT.Training_Date__c = Date.today()+3;
        newOppAT.Doc_Collection_Status__c = 'Docs On File - Pending' ;        
        newOppAT.Email_Stage__c = null ; 
        newOppAT.DexTracker_Email__c = 'Yes';
        newOppAT.Consumer_Email__c = 'Tesdt@gmail.com';     
        newOppAT.CloseDate = Date.Today().addDays(30);
        newOppAT.Pricebook2Id = customPricebookId;
        insert newOppAT;
        
        //Insert Opportunity Products
        List<OpportunityLineItem> lineItemsToBeInserted = new List<OpportunityLineItem>();
        for(String productName : products.keySet()) {
            OpportunityLineItem newItem = new OpportunityLineItem();
            newItem.OpportunityId = newOppAT.Id;
			newItem.Quantity  = 2;
			newItem.UnitPrice = 125;
            newItem.Repeat_Quantity__c = 12;
            newItem.Repeat_after_in_Days__c = 90;
            newItem.PricebookEntryId = productIdToPbeId.get(products.get(productName));
            lineItemsToBeInserted.add(newItem);
        }
        insert lineItemsToBeInserted;
		oldTriggerOpportunities.put(newOppAT.Id,newOppAT);
        ClsCheckRecursive.run = true ;
        newOppAT.Health_Insurance_Approval__c = 'Not Required';
        newOppAT.CA_Customer_Docs_Collection_Status__c = 'Not Required';
        newOppAT.Stagename = 'Order Fulfillment'; 
        update newOppAT ;
        // update lineItemsToBeInserted;
        newTriggerOpportunities.put(newOppAT.Id,newOppAT);
        ClsATOpportunityTriggerHandler.processOpportunityForScheduleShipments(newTriggerOpportunities, oldTriggerOpportunities);
    }
    @isTest 
    static void InsertTestDataATWithoutPayor(){        
        Test.startTest();
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Account' and isActive=true];
        //Create a map between the Record Type Name and Id 
        Map<String,String> accountRecordTypes = new Map<String,String>();
        for(RecordType rt: rtypes)
            accountRecordTypes.put(rt.Name,rt.Id);
        List<Account> accts = new List<Account>();
        Map<Id, Opportunity> newTriggerOpportunities = new Map<Id, Opportunity>();
        Map<Id, Opportunity> oldTriggerOpportunities = new Map<Id, Opportunity>();
        
        String recordTypeIdAT = accountRecordTypes.get('AT Consumer');
        Account ATacc = new Account();
        ATacc.CurrencyIsoCode = 'EUR';
        ATacc.RecordTypeId = recordTypeIdAT;
        ATacc.FirstName='TestConsumerFirstName';
        ATacc.LastName='TestConsumerLastName';
        ATacc.BillingStreet = 'Grüner Weg';
        ATacc.BillingCity = 'Friedberg';
        ATacc.BillingPostalCode = '1234';
        ATacc.BillingCountryCode = 'AT';
        ATacc.PersonEmail = 'Tesdt@gmail.com';
        ATacc.PersonHasOptedOutOfEmail = false;
        insert ATacc; 
        
        String recordTypeIdMed = accountRecordTypes.get('AT Medical Facility');
        Account ATaccMed = new Account();
        ATaccMed.CurrencyIsoCode = 'EUR';
        ATaccMed.RecordTypeId = recordTypeIdMed;
        ATaccMed.name = 'Med';
        ATaccMed.Phone = '1234567891' ;
        ATaccMed.BillingStreet = 'Grüner Weg';
        ATaccMed.BillingCity = 'Friedberg';
        ATaccMed.BillingPostalCode = '1244';
        ATaccMed.BillingCountryCode = 'AT';
        insert ATaccMed; 
        
        ATacc.Medical_Facility__c = ATaccMed.id;
        update ATacc ;
        
        account accPayor = new Account();
        String recordTypeId = accountRecordTypes.get('AT Payor');
        accPayor.CurrencyIsoCode = 'EUR';
        accPayor.RecordTypeId = recordTypeId;
       	accPayor.Name = 'Test Payor 2';
		accPayor.Insurance_Company_Identification_Number__c = '1223444';
        accPayor.BillingStreet = 'Grüner Weg';
        accPayor.BillingCity = 'Friedberg';
        accPayor.BillingPostalCode = 'V7J 3H5';
        accPayor.BillingCountryCode = 'CA';
        accPayor.BillingStateCode = 'AB';
        accPayor.BillingState = 'Alberta';
        insert accPayor;
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCPB(new List <String>{'AT_Pricebook'}, 'EUR');
        String customPricebookId = customPricebookMap.get('AT_Pricebook');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'DEX-SHIP-01'});
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
            productIdToPriceMap.put(products.get(productName), 125.00);

        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, customPricebookId);
		test.stopTest();
        Id oppRecTypeAT = [Select Id from RecordType Where isActive = true AND DeveloperName = 'AT_Opportunity'].id;
        Opportunity newOppAT = new Opportunity();
        newOppAT.RecordTypeId = oppRecTypeAT;
        newOppAT.Name = 'New Opportunity For Testing';
        newOppAT.CurrencyIsoCode = 'EUR';
        newOppAT.AccountId = ATacc.Id;
        //newOppAT.Payor__c = accPayor.Id;
        newOppAT.Type = 'New';
        newOppAT.Contact_Letter_Sent__c = true;
        newOppAT.Contact_Doc_Received__c = true;
        newOppAT.Insurance_Doc_Received__c = true;
        newOppAT.Hard_Copy_Out__c = true;
        newOppAT.Hard_Copy_In__c = true;
        newOppAT.Training_Letter_Sent__c = true;
        newOppAT.Training_Letter_Sent_Date__c = Date.Today();
        newOppAT.StageName = 'New Opportunity';
        newOppAT.Training_Date__c = Date.today()+3;
        newOppAT.Doc_Collection_Status__c = 'Docs On File - Pending' ;        
        newOppAT.Email_Stage__c = null ; 
        newOppAT.DexTracker_Email__c = 'Yes';
        newOppAT.Consumer_Email__c = 'Tesdt@gmail.com';     
        newOppAT.CloseDate = Date.Today().addDays(30);
        newOppAT.Pricebook2Id = customPricebookId;
        insert newOppAT;
        
        //Insert Opportunity Products
        List<OpportunityLineItem> lineItemsToBeInserted = new List<OpportunityLineItem>();
        for(String productName : products.keySet()) {
            OpportunityLineItem newItem = new OpportunityLineItem();
            newItem.OpportunityId = newOppAT.Id;
			newItem.Quantity  = 2;
			newItem.UnitPrice = 125;
            newItem.Repeat_Quantity__c = 12;
            newItem.Repeat_after_in_Days__c = 90;
            newItem.PricebookEntryId = productIdToPbeId.get(products.get(productName));
            lineItemsToBeInserted.add(newItem);
        }
        insert lineItemsToBeInserted;
		oldTriggerOpportunities.put(newOppAT.Id,newOppAT);
        ClsCheckRecursive.run = true ;
        newOppAT.Health_Insurance_Approval__c = 'Not Required';
        newOppAT.CA_Customer_Docs_Collection_Status__c = 'Not Required';
        newOppAT.Stagename = 'Order Fulfillment'; 
        update newOppAT ;
        // update lineItemsToBeInserted;
        newTriggerOpportunities.put(newOppAT.Id,newOppAT);
        ClsATOpportunityTriggerHandler.processOpportunityForScheduleShipments(newTriggerOpportunities, oldTriggerOpportunities);
        
    }
    
}