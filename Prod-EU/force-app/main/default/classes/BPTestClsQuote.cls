/****************************************************************************************************************
@Author        : Kumar Navneet
@Date Created    : 05/06/2019
@Description    : Test class of BPCls_Quote 
****************************************************************************************************************/
@isTest
public class BPTestClsQuote {
    @testSetup
    private static void InsertTestQuote() {   
        
        //Create accounts required for Opportunity creation
        List<Account> accountsToBeUpdated = new List<Account>();
        
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Account' and isActive=true];
        //Create a map between the Record Type Name and Id 
        Map<String,String> accountRecordTypes = new Map<String,String>();
        for(RecordType rt: rtypes)
            accountRecordTypes.put(rt.Name,rt.Id);
        List<Account> accts = new List<Account>();
        String recordTypeId = accountRecordTypes.get('DE Consumer');
        Account a = new Account();
        a.CurrencyIsoCode = 'EUR';
        a.RecordTypeId = recordTypeId;
        a.FirstName='TestConsumerFirstName';
        a.LastName='TestConsumerLastName';
        a.BillingStreet = 'Grüner Weg';
        a.BillingCity = 'Friedberg';
        a.BillingPostalCode = '61169';
        a.BillingCountryCode = 'DE';
        accts.add(a);                                                
        a = new Account();
        recordTypeId = accountRecordTypes.get('DE Prescriber');
        a.CurrencyIsoCode = 'EUR';
        a.RecordTypeId = recordTypeId;
        a.FirstName='TestPrescFirstName';
        a.LastName='TestPrescLastName';
        a.Prescriber_Id__c = String.valueOf(Integer.valueOf('1000'));
        a.BillingStreet = 'Grüner Weg';
        a.BillingCity = 'Friedberg';
        a.BillingPostalCode = '61169';
        a.BillingCountryCode = 'DE';
        accts.add(a);
        a = new Account();
        recordTypeId = accountRecordTypes.get('DE Payor');
        a.CurrencyIsoCode = 'EUR';
        a.RecordTypeId = recordTypeId;
        a.Name = 'TestAccount';
        a.Insurance_Company_Identification_Number__c = '9876567';
        a.BillingStreet = 'Grüner Weg';
        a.BillingCity = 'Friedberg';
        a.BillingPostalCode = '61169';
        a.BillingCountryCode = 'DE';
        accts.add(a);    
        a = new Account();
        recordTypeId = accountRecordTypes.get('DE Medical Facility');
        a.CurrencyIsoCode = 'EUR';
        a.RecordTypeId = recordTypeId;
        a.Name = 'TestAccount';
        a.BillingStreet = 'Grüner Weg';
        a.BillingCity = 'Friedberg';
        a.BillingPostalCode = '61169';
        a.BillingCountryCode = 'DE';
        accts.add(a);    
        insert accts;      
        // End of moved code from TestFactory to create Accounts. 
        accts[0].Medical_Facility__c = accts[3].Id;
        accts[0].Prescriber__c = accts[1].Id;
        accts[0].PersonBirthDate = Date.newInstance(1960, 2, 17);
        accts.add(accts[0]);
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'Barmer'});
        String customPricebookId = customPricebookMap.get('Barmer');
        accts[2].Price_Book__c = customPricebookId;
        accountsToBeUpdated.add(accts[2]);
        Update accountsToBeUpdated;
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', '21.34.03.2004 (G5 Xmer)'});
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
        {
            productIdToPriceMap.put(products.get(productName), 125.00);
            if(productName == '21.34.03.2004 (G5 Xmer)')
            {
                ClsTestDataFactory.createProductSchedule (products.get(productName), products.get('STK-GF-013'), customPricebookId);
            }
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, customPricebookId);
        Id benRecType = [Select Id from RecordType  where sObjectType='Benefit__c' and isActive=true AND DeveloperName = 'DE_Benefit'].Id;
        //Create new Benefit and associate it to the payor
        Benefit__c primaryBenefit = new Benefit__c();
        primaryBenefit.Account__c = accts[0].Id;
        primaryBenefit.RecordTypeId = benRecType;
        primaryBenefit.Member_Id__c = '1789657890';
        primaryBenefit.Payor__c = accts[2].Id;
        primaryBenefit.Benefit_Hierarchy__c = 'Primary';
        primaryBenefit.Inactive__c = false;    
        insert primaryBenefit;
        //Create new Opportunity
        Id oppRecTypeGermany = [Select Id from RecordType Where isActive = true AND DeveloperName = 'DE_Opportunity'].id;
        Opportunity newOpp = new Opportunity();
        newOpp.RecordTypeId = oppRecTypeGermany;
        newOpp.Name = 'New Opportunity For Testing';
        newOpp.CurrencyIsoCode = 'EUR';
        newOpp.AccountId = accts[0].Id;
        newOpp.Benefit__c = primaryBenefit.Id;
        newOpp.Medical_Facility__c = accts[3].Id;
        newOpp.Prescriber__c = accts[1].Id;
        newOpp.Payor__c = accts[2].Id;
        newOpp.Type = 'New';
        newOpp.Pricebook2Id = customPricebookId;
        newOpp.CloseDate = Date.Today().addDays(30);
        newOpp.Contact_Letter_Sent__c = true;
        newOpp.Contact_Doc_Received__c = true;
        newOpp.Insurance_Doc_Received__c = true;
        newOpp.Hard_Copy_Out__c = true;
        newOpp.Hard_Copy_In__c = true;
        newOpp.Training_Letter_Sent__c = true;
        newOpp.Training_Letter_Sent_Date__c = Date.Today();
        newOpp.StageName = 'New Opportunity';
        newOpp.Training_Date__c = Date.today()+1;
        
        insert newOpp;
        system.debug('Opportunity Currency Code: ' + newOpp.CurrencyIsoCode);
        //Insert Opportunity Products
        List<OpportunityLineItem> lineItemsToBeInserted = new List<OpportunityLineItem>();
        for(String productName : products.keySet())
        {
            OpportunityLineItem newItem = new OpportunityLineItem();
            newItem.OpportunityId = newOpp.Id;
            if(productName == '21.34.03.2004 (G5 Xmer)')
            {
                newItem.Quantity  = 1;
                newItem.UnitPrice = 125;
            }
            else
            {
                newItem.Quantity  = 1;
                newItem.UnitPrice = 125;
            }
            
            newItem.PricebookEntryId = productIdToPbeId.get(products.get(productName));
            lineItemsToBeInserted.add(newItem);
        }
        insert lineItemsToBeInserted;
        newOpp.StageName = 'Order Fulfillment';
        ClsOpportunityTriggerStaticClass.isExecuting = false;
        update newOpp;
        
        //Insert Quotes
        Quote newQuote = new Quote();
        newQuote.OpportunityId = newOpp.Id;
        newQuote.Name = newOpp.Name;
        newQuote.Type__c = 'Cost Estimate';
        newQuote.Status = 'Draft';
        newQuote.Pricebook2Id = customPricebookId;
        insert newQuote;
        //Insert Quote Products
        List<QuoteLineItem> quoteLineItemsToBeInserted = new List<QuoteLineItem>();
        for(String productName : products.keySet())
        {
            QuoteLineItem quoteLineItem = new QuoteLineItem();
            quoteLineItem.QuoteId = newQuote.Id;
            if(productName == '21.34.03.2004 (G5 Xmer)')
            {
                quoteLineItem.Quantity  = 1;
                quoteLineItem.UnitPrice = 125;
            }
            else
            {
                quoteLineItem.Quantity  = 1;
                quoteLineItem.UnitPrice = 125;
            }
            
            quoteLineItem.PricebookEntryId = productIdToPbeId.get(products.get(productName));
            quoteLineItemsToBeInserted.add(quoteLineItem);
        }
        insert quoteLineItemsToBeInserted;  
        
    }
    
    @isTest
    private static void UpdateOpportunity_ChangeTracked_ProcessFired() {
        Map<Id, Quote> newQuote = new Map<Id, Quote>();
        Map<Id, Quote> oldQuote = new Map<Id, Quote>();
        for (Quote Qot : [SELECT Id, Name FROM Quote]) {
            newQuote.put(Qot.Id, Qot );
        } 
        
        test.startTest();
        BPClsQuote.UpdateQuoteLineItemNumber(newQuote );     
        test.stopTest();       
        
    }
    
}