/*******************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 08/13/2017
@Description    : Test class to test the scenarios involved in Opportunity object
@Author        : Jagan Periyakaruppan
@Date Created    : 05/03/2018
@Description    : Added condition to accomodate the static class to avoid recursive trigger
*********************************************************************************************/
@isTest
private class ClsTestOpportunityObject {
    @isTest private static void InsertTestDataDE() {   
                //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'Barmer'});
        String customPricebookId = customPricebookMap.get('Barmer');
       // accts[2].
        //Create accounts required for Opportunity creation
        List<Account> accountsToBeUpdated = new List<Account>();
       /* List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Account' and isActive=true];*/
        
        //Create a map between the Record Type Name and Id 
        Map<String,String> accountRecordTypes = new Map<String,String>();
        /*
        for(Schema.RecordTypeInfo rti : Schema.SObjectType.Account.getRecordTypeInfosById().values()){
            accountRecordTypes.put(rti.getName(),rti.getRecordTypeId());
        }
*/
        for(RecordType rti : [Select Name, ID from RecordType where sobjecttype = 'Account' and IsActive=true])
            accountRecordTypes.put(rti.Name,rti.Id);
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
        a.PersonEmail = 'Tesdt@gmail.com';
        a.Benefit_Member_Id__c='1234567899';
        a.PersonHasOptedOutOfEmail = false;
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
        a.Benefit_Member_Id__c='1234567899';
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
        a.Price_Book__c = customPricebookId;
        a.Benefit_Member_Id__c='1234567899';
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
        a.Benefit_Member_Id__c='1234567899';
        
        accts.add(a);    
        insert accts;      
        
        accts[0].Medical_Facility__c = accts[3].Id;
        accts[0].Prescriber__c = accts[1].Id;
        accts[0].PersonBirthDate = Date.newInstance(1960, 2, 17);
        accts[0].Benefit_Member_Id__c='1234567899';
     
        

        accts[0].payor__C=accts[2].id;
        
        
        

        accountsToBeUpdated.add(accts[0]);
        Update accountsToBeUpdated;    
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'DEX-SHIP-01'});
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
        {
            productIdToPriceMap.put(products.get(productName), 125.00);
            if(productName == 'DEX-SHIP-01')
            {
                ClsTestDataFactory.createProductSchedule (products.get(productName), products.get('STK-GF-013'), customPricebookId);
            }
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, customPricebookId);
        
        //Create new Benefit and associate it to the payor
        Id benRecType = Schema.SObjectType.Benefit__c.getRecordTypeInfosByDeveloperName().get('DE_Benefit').getRecordTypeId();
            //[Select Id from RecordType  where sObjectType='Benefit__c' and isActive=true AND DeveloperName = 'DE_Benefit'].Id;
        Benefit__c primaryBenefit = new Benefit__c();
        primaryBenefit.RecordTypeId = benRecType;
        primaryBenefit.Account__c = accts[0].Id;
        primaryBenefit.Member_Id__c = '1789657890';
        primaryBenefit.Payor__c = accts[2].Id;
        primaryBenefit.Benefit_Hierarchy__c = 'Primary';
        primaryBenefit.Inactive__c = false;    
        insert primaryBenefit;
        
        //Create new Opportunity
        Id oppRecTypeGermany = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DE_Opportunity').getRecordTypeId();
            //[Select Id from RecordType Where isActive = true AND DeveloperName = 'DE_Opportunity'].id;
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
        //newOpp.Contact_Doc_Received__c = true;
       // newOpp.Insurance_Doc_Received__c = true;
       // newOpp.Hard_Copy_Out__c = true;
        //newOpp.Hard_Copy_In__c = true;
        newOpp.Training_Letter_Sent__c = true;
        newOpp.Training_Letter_Sent_Date__c = Date.Today();
        newOpp.StageName = 'New Opportunity';
        newOpp.Training_Date__c = Date.today()+3;
        //newOpp.Doc_Collection_Status__c = 'Docs On File - Pending' ;        
        newOpp.Email_Stage__c = null ; 
        newOpp.DexTracker_Email__c = 'Yes';
        newOpp.Cash_Pay__c=true;
        newOpp.Consumer_Email__c = 'Tesdt@gmail.com';       
        insert newOpp;     
        
        //Insert Opportunity Products
        List<OpportunityLineItem> lineItemsToBeInserted = new List<OpportunityLineItem>();
        for(String productName : products.keySet())
        {
            OpportunityLineItem newItem = new OpportunityLineItem();
            newItem.OpportunityId = newOpp.Id;
            if(productName != 'STK-GF-013'){
                if(productName == 'DEX-SHIP-01')
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
        }
        insert lineItemsToBeInserted;
        
        //Insert Quotes
        Quote newQuote = new Quote();
        newQuote.OpportunityId = newOpp.Id;
        newQuote.Name = newOpp.Name;
        newQuote.Type__c = 'Customer Quote';
        newQuote.Status = 'Draft';
        newQuote.Pricebook2Id = customPricebookId;
        insert newQuote;
        //Insert Quote Products
        List<QuoteLineItem> quoteLineItemsToBeInserted = new List<QuoteLineItem>();
        for(String productName : products.keySet())
        {
            QuoteLineItem quoteLineItem = new QuoteLineItem();
            quoteLineItem.QuoteId = newQuote.Id;
            if(productName != 'STK-GF-013'){
                if(productName == 'DEX-SHIP-01')
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
        }
        insert quoteLineItemsToBeInserted;                   
        newQuote.Status = 'Approved';    
        update newQuote;
        lineItemsToBeInserted[0].Quantity  = 4;
        update lineItemsToBeInserted;
        Test.startTest();
        /*
        ClsCheckRecursive.run = true ;
        newOpp.Training_Letter_Sent_Date__c = Date.Today();
        newOpp.Cash_Pay__c = false ;
        newOpp.Doc_Collection_Status__c = 'Pending Docs To Bill' ;
        newOpp.StageName = 'Order Fulfillment' ;        
        update newOpp ;  
        */
        ClsCheckRecursive.run = true ;       
        newOpp.benefit_Auth_start_date__c = Date.today();      
        newOpp.Stagename = 'Cancelled'; 
        newOpp.Create_New_Opportunity__c = true ;        
        newOpp.Training_Date__c = Date.today()+4;
        newOpp.Doc_Collection_Status__c = 'Docs On File - Pending' ;        
        newOpp.Email_Stage__c = 1 ; 
        newOpp.DexTracker_Email__c = 'Yes';
        newOpp.Consumer_Email__c = 'Teshdt@gmail.com';   
        newOpp.Training_Confirmation_Channel__c = 'Sales Rep';
        newOpp.Contact_Doc_Received__c = false;
        newOpp.Type = 'Reorder';    
        //update newOpp ;   
        
        //Pricebook2 newPricebook = [Select Id, Cash_Pay__c from Pricebook2 limit 1];
        //newPricebook.Cash_Pay__c = True;
        //update newPricebook;
        
        Delete newQuote;
        Delete lineItemsToBeInserted ;
        
        
        Test.stopTest();
        
    }   
    @isTest static void InsertTestDataCA(){
        
        //  Adding Individual Accounts seems to be consuming too many SOQL Queries. Observed value 57. So, consolidating them into a single DML here!!!!
        //
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Account' and isActive=true];
        //Create a map between the Record Type Name and Id 
        Map<String,String> accountRecordTypes = new Map<String,String>();
        for(RecordType rt: rtypes)
            accountRecordTypes.put(rt.Name,rt.Id);
        List<Account> accts = new List<Account>();
        
        String recordTypeIdCA = accountRecordTypes.get('CA Consumer');
        Account CAacc = new Account();
        CAacc.CurrencyIsoCode = 'CAD';
        CAacc.RecordTypeId = recordTypeIdCA;
        CAacc.FirstName='TestConsumerFirstName';
        CAacc.LastName='TestConsumerLastName';
        CAacc.BillingStreet = 'Grüner Weg';
        CAacc.BillingCity = 'Friedberg';
        CAacc.BillingPostalCode = 'V7J 3H5';
        CAacc.BillingCountryCode = 'CA';
        CAacc.BillingStateCode = 'AB';        
        CAacc.PersonEmail = 'Tesdt@gmail.com';
        CAacc.PersonHasOptedOutOfEmail = false;
        insert CAacc; 
        
        Id oppRecTypeCA = [Select Id from RecordType Where isActive = true AND DeveloperName = 'CA_Opportunity'].id;
        Opportunity newOppCA = new Opportunity();
        newOppCA.RecordTypeId = oppRecTypeCA;
        newOppCA.Name = 'New Opportunity For Testing';
        newOppCA.CurrencyIsoCode = 'CAD';
        newOppCA.AccountId = CAacc.Id;
        newOppCA.Type = 'New';
        newOppCA.Contact_Letter_Sent__c = true;
        newOppCA.Contact_Doc_Received__c = true;
        newOppCA.Insurance_Doc_Received__c = true;
        newOppCA.Hard_Copy_Out__c = true;
        newOppCA.Hard_Copy_In__c = true;
        newOppCA.Training_Letter_Sent__c = true;
        newOppCA.Training_Letter_Sent_Date__c = Date.Today();
        newOppCA.StageName = 'New Opportunity';
        newOppCA.Training_Date__c = Date.today()+3;
        newOppCA.Doc_Collection_Status__c = 'Docs On File - Pending' ;        
        newOppCA.Email_Stage__c = null ; 
        newOppCA.DexTracker_Email__c = 'Yes';
        newOppCA.Consumer_Email__c = 'Tesdt@gmail.com';     
        newOppCA.CloseDate = Date.Today().addDays(30);
        insert newOppCA;
        
        ClsCheckRecursive.run = true ; 
        newOppCA.Create_New_Opportunity__c = true;
        newOppCA.StageName = 'Cancelled';
        newOppCA.CA_Cancelled_Reason__c='Other';
       // newOppCA.benefit_Auth_start_date__c = Date.today(); 
        update newOppCA;
        List<Opportunity> OppCAList = new List<Opportunity>();
        OppCAList.add(newOppCA);
        ClsCAOpportunityTriggerHandler.doNotAllowMultipleOpenOpps(OppCAList);
        
    }
    @isTest static void InsertTestDataCH(){        
        
       /* List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Account' and isActive=true];*/
        //Create a map between the Record Type Name and Id 
        Map<String,String> accountRecordTypes = new Map<String,String>();
        for(Schema.RecordTypeInfo rti : Schema.SObjectType.Account.getRecordTypeInfosById().values()){
            accountRecordTypes.put(rti.getName(),rti.getRecordTypeId());
        }
        List<Account> accts = new List<Account>();
        
        String recordTypeIdCH = accountRecordTypes.get('CH Consumer');
        Account CHacc = new Account();
        CHacc.CurrencyIsoCode = 'CHF';
        CHacc.RecordTypeId = recordTypeIdCH;
        CHacc.FirstName='TestConsumerFirstName';
        CHacc.LastName='TestConsumerLastName';
        CHacc.BillingStreet = 'Grüner Weg';
        CHacc.BillingCity = 'Friedberg';
        CHacc.BillingPostalCode = '1214';
        CHacc.BillingCountryCode = 'CH';
        //CHacc.PersonEmail = 'Tesdt@gmail.com';
        CHacc.PersonHasOptedOutOfEmail = false;
        CHacc.Preferred_Language__c='de_CH';
               insert CHacc;
             Id RTIdAddDE =[Select Id From RecordType where sObjectType='Address__c' and isActive=true AND DeveloperName='CH_Address' Limit 1][0].Id; 
          List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = CHacc.Id,Type__c = 'Bill To', Country__c = 'Switzerland',  City__c = 'Rosemont', Address_Line_1__c = 'gins Rd', Postal_Code__c = 'D02 AF30', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE),
            new Address__c(Account__c = CHacc.Id,Type__c = 'Ship To',Country__c = 'Switzerland',  City__c = 'Rosemont', Address_Line_1__c = 'Higgins Rd', Postal_Code__c = 'D02 AF30', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE)
        };
        insert lstAddress; 
        
        String recordTypeIdMed = accountRecordTypes.get('CH Medical Facility');
        Account CHaccMed = new Account();
        CHaccMed.CurrencyIsoCode = 'CHF';
        CHaccMed.RecordTypeId = recordTypeIdMed;
        CHaccMed.name = 'Med';
        CHaccMed.Phone = '1234567891' ;
        CHaccMed.BillingStreet = 'Grüner Weg';
        CHaccMed.BillingCity = 'Friedberg';
        CHaccMed.BillingPostalCode = '1244';
        CHaccMed.BillingCountryCode = 'CH';
        insert CHaccMed; 
        
        String recordTypeIdPres = accountRecordTypes.get('CH Prescriber');
        Account CHaccPres = new Account();
        CHaccPres.CurrencyIsoCode = 'CHF';
        CHaccPres.RecordTypeId = recordTypeIdPres;
        CHaccPres.FirstName='TestPresFirstName';
        CHaccPres.LastName='TestPresrLastName';
        CHaccPres.BillingStreet = 'Grüner Weg';
        CHaccPres.BillingCity = 'Friedberg';
        CHaccPres.BillingPostalCode = '1224';
        CHaccPres.BillingCountryCode = 'CH';
        CHaccPres.PersonEmail = 'TesdtT@gmail.com';
        CHaccPres.PersonHasOptedOutOfEmail = false;
        CHaccPres.Medical_Facility__c = CHaccMed.id ;
        insert CHaccPres;     
        CHacc.Medical_Facility__c = CHaccMed.id;
        CHacc.Prescriber__c = CHaccPres.id ;
        update CHacc ;
 
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCPB(new List <String>{'CH_Pricebook'}, 'CHF');
        String customPricebookId = customPricebookMap.get('CH_Pricebook');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'DEX-SHIP-01'});
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
            productIdToPriceMap.put(products.get(productName), 125.00);

        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCH(productIdToPriceMap, customPricebookId);

        Id oppRecTypeCH = [Select Id from RecordType Where isActive = true AND DeveloperName = 'CH_Opportunity'].id;
        Opportunity newOppCH = new Opportunity();
        newOppCH.RecordTypeId = oppRecTypeCH;
        newOppCH.Name = 'New Opportunity For Testing';
        newOppCH.CurrencyIsoCode = 'CHF';
        newOppCH.AccountId = CHacc.Id;
        newOppCH.Type = 'New';
        newOppCH.Contact_Letter_Sent__c = true;
        newOppCH.Contact_Doc_Received__c = true;
        newOppCH.Insurance_Doc_Received__c = true;
        newOppCH.Hard_Copy_Out__c = true;
        newOppCH.Hard_Copy_In__c = true;
        newOppCH.Training_Letter_Sent__c = true;
        newOppCH.Training_Letter_Sent_Date__c = Date.Today();
        newOppCH.StageName = 'New Opportunity';
        newOppCH.Training_Date__c = Date.today()+3;
        newOppCH.Doc_Collection_Status__c = 'Docs On File - Pending' ;        
        newOppCH.Email_Stage__c = null ; 
        newOppCH.DexTracker_Email__c = 'Yes';
        newOppCH.Consumer_Email__c = 'Tesdt@gmail.com';     
        newOppCH.CloseDate = Date.Today().addDays(30);
        insert newOppCH;
        
        
        //Insert Opportunity Products
        List<OpportunityLineItem> lineItemsToBeInserted = new List<OpportunityLineItem>();
        for(String productName : products.keySet())
        {
            OpportunityLineItem newItem = new OpportunityLineItem();
            newItem.OpportunityId = newOppCH.Id;
            newItem.Repeat_Quantity__c = 2;
            newItem.Repeat_after_in_Days__c = 2 ;
            newItem.Quantity  = 1;
            newItem.UnitPrice = 125;
            newItem.PricebookEntryId = productIdToPbeId.get(products.get(productName));
            lineItemsToBeInserted.add(newItem);
        }
        insert lineItemsToBeInserted;
        Test.startTest();
        lineItemsToBeInserted[0].Quantity  = 1;
        lineItemsToBeInserted[0].Repeat_Quantity__c = 2;
        update lineItemsToBeInserted;
        
        ClsCheckRecursive.run = true ;
        newOppCH.Health_Insurance_Approval__c = 'Not Required';
        newOppCH.CA_Customer_Docs_Collection_Status__c = 'Not Required';
        newOppCH.Health_Insurance_Approval__c = 'Not Required';
        newOppCH.Stagename = 'Order Fulfillment'; 
        newOppCH.Type = 'Subscription' ;
        update newOppCH ;  
        
        Test.stopTest();
      
    }
    @isTest static void InsertTestDataAT(){        
        
        /*List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Account' and isActive=true];*/
        //Create a map between the Record Type Name and Id 
        Map<String,String> accountRecordTypes = new Map<String,String>();
        for(Schema.RecordTypeInfo rti : Schema.SObjectType.Account.getRecordTypeInfosById().values()){
            accountRecordTypes.put(rti.getName(),rti.getRecordTypeId());
        }
        List<Account> accts = new List<Account>();
        
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
            Id RTIdAddDE =[Select Id From RecordType where sObjectType='Address__c' and isActive=true AND DeveloperName='AT_Address' Limit 1][0].Id; 
          List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = ATacc.Id,Type__c = 'Bill To', Country__c = 'Austria',  City__c = 'Rosemont', Address_Line_1__c = 'gins Rd', Postal_Code__c = 'D02 AF30', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE),
            new Address__c(Account__c = ATacc.Id,Type__c = 'Ship To',Country__c = 'Austria',  City__c = 'Rosemont', Address_Line_1__c = 'Higgins Rd', Postal_Code__c = 'D02 AF30', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE)
        };
        insert lstAddress;
        
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

        Id oppRecTypeAT = [Select Id from RecordType Where isActive = true AND DeveloperName = 'AT_Opportunity'].id;
        Opportunity newOppAT = new Opportunity();
        newOppAT.RecordTypeId = oppRecTypeAT;
        newOppAT.Name = 'New Opportunity For Testing';
        newOppAT.CurrencyIsoCode = 'EUR';
        newOppAT.AccountId = ATacc.Id;
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
        for(String productName : products.keySet())
        {
            OpportunityLineItem newItem = new OpportunityLineItem();
            newItem.OpportunityId = newOppAT.Id;
            newItem.Quantity  = 2;
            newItem.UnitPrice = 125;
            newItem.PricebookEntryId = productIdToPbeId.get(products.get(productName));
            lineItemsToBeInserted.add(newItem);
        }
        insert lineItemsToBeInserted;

        ClsCheckRecursive.run = true ;
        newOppAT.Health_Insurance_Approval__c = 'Not Required';
        newOppAT.CA_Customer_Docs_Collection_Status__c = 'Not Required';
        newOppAT.Stagename = 'Order Fulfillment'; 
        update newOppAT ;   
    }
    @isTest static void InsertTestDataIE(){        
        
        /*List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Account' and isActive=true];*/
        //Create a map between the Record Type Name and Id 
        Map<String,String> accountRecordTypes = new Map<String,String>();
       for(Schema.RecordTypeInfo rti : Schema.SObjectType.Account.getRecordTypeInfosById().values()){
            accountRecordTypes.put(rti.getName(),rti.getRecordTypeId());
        }
        List<Account> accts = new List<Account>();
        
        String recordTypeIdIE = accountRecordTypes.get('IE Consumer');
        Account IEacc = new Account();
        IEacc.CurrencyIsoCode = 'EUR';
        IEacc.RecordTypeId = recordTypeIdIE;
        IEacc.FirstName='TestConsumerFirstName';
        IEacc.LastName='TestConsumerLastName';
        IEacc.BillingStreet = 'Grüner Weg';
        IEacc.BillingCity = 'Friedberg';
        IEacc.BillingPostalCode = '1234';
        IEacc.BillingCountryCode = 'IE';
        IEacc.PersonEmail = 'Tesdt@gmail.com';
        IEacc.Payment_terms__C='net30';
        IEacc.PersonHasOptedOutOfEmail = false;
        insert IEacc; 
        Id RTIdAddDE =[Select Id From RecordType where sObjectType='Address__c' and isActive=true AND DeveloperName='UK_Address' Limit 1][0].Id;        
        
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = IEacc.Id,Type__c = 'Bill To', Country__c = 'Ireland',  City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '6089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE),
            new Address__c(Account__c = IEacc.Id,Type__c = 'Ship To',Country__c = 'Ireland',  City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '6089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE)
        };
        insert lstAddress;
        Finance_Detail__c fd1= new Finance_Detail__c(Account__c=IEacc.Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='EUR', Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=lstAddress[0].id);
        insert fd1;
                
        String recordTypeIdMed = accountRecordTypes.get('IE Medical Facility');
        Account IEaccMed = new Account();
        IEaccMed.CurrencyIsoCode = 'EUR';
        IEaccMed.RecordTypeId = recordTypeIdMed;
        IEaccMed.name = 'Med';
        IEaccMed.Phone = '1234567891' ;
        IEaccMed.BillingStreet = 'Grüner Weg';
        IEaccMed.BillingCity = 'Friedberg';
        IEaccMed.BillingPostalCode = '1244';
        IEaccMed.BillingCountryCode = 'IE';
        insert IEaccMed; 
        
        IEacc.Medical_Facility__c = IEaccMed.id;
        update IEacc ;
        
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCPB(new List <String>{'IE_Pricebook'}, 'EUR');
        String customPricebookId = customPricebookMap.get('IE_Pricebook');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'DEX-SHIP-01'});
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
            productIdToPriceMap.put(products.get(productName), 125.00);

        
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, customPricebookId);

        Id oppRecTypeIE = [Select Id from RecordType Where isActive = true AND DeveloperName = 'IE_Opportunity'].id;
        Opportunity newOppIE = new Opportunity();
        newOppIE.RecordTypeId = oppRecTypeIE;
        newOppIE.Name = 'New Opportunity For Testing';
        newOppIE.CurrencyIsoCode = 'EUR';
        newOppIE.AccountId = IEacc.Id;
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
        
        //Insert Opportunity Products
        List<OpportunityLineItem> lineItemsToBeInserted = new List<OpportunityLineItem>();
        for(String productName : products.keySet())
        {
            OpportunityLineItem newItem = new OpportunityLineItem();
            newItem.OpportunityId = newOppIE.Id;
            newItem.Quantity  = 2;
            newItem.UnitPrice = 125;
            newItem.PricebookEntryId = productIdToPbeId.get(products.get(productName));
            lineItemsToBeInserted.add(newItem);
        }
        insert lineItemsToBeInserted;
        
        ClsCheckRecursive.run = true ;
        newOppIE.Health_Insurance_Approval__c = 'Not Required';
        newOppIE.CA_Customer_Docs_Collection_Status__c = 'Not Required';
        newOppIE.Stagename = 'Order Fulfillment'; 
        update newOppIE ;   
        
    }
    @isTest static void InsertTestDataGB(){        
        
        /*List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Account' and isActive=true];*/
        //Create a map between the Record Type Name and Id 
        Map<String,String> accountRecordTypes = new Map<String,String>();
        for(Schema.RecordTypeInfo rti : Schema.SObjectType.Account.getRecordTypeInfosById().values()){
            accountRecordTypes.put(rti.getName(),rti.getRecordTypeId());
        }
        List<Account> accts = new List<Account>();
        
        String recordTypeIdGB = accountRecordTypes.get('GB Consumer');
        Account GBacc = new Account();
        GBacc.CurrencyIsoCode = 'GBP';
        GBacc.RecordTypeId = recordTypeIdGB;
        GBacc.FirstName='TestConsumerFirstName';
        GBacc.LastName='TestConsumerLastName';
        GBacc.BillingStreet = 'Grüner Weg';
        GBacc.BillingCity = 'Friedberg';
        GBacc.BillingPostalCode = '1234';
        GBacc.BillingCountryCode = 'GB';
        GBacc.PersonEmail = 'Tesdt@gmail.com';
        GBacc.PersonHasOptedOutOfEmail = false;
        GBacc.payment_terms__C='net30';
        insert GBacc; 
        
        Id RTIdAddDE =[Select Id From RecordType where sObjectType='Address__c' and isActive=true AND DeveloperName='UK_Address' Limit 1][0].Id;        
        
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = GBacc.Id,Type__c = 'Bill To', Country__c = 'United Kingdom',  City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = 'D02 AF30', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE),
            new Address__c(Account__c = GBacc.Id,Type__c = 'Ship To',Country__c = 'United Kingdom',  City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = 'D02 AF30', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE)
        };
        insert lstAddress;
        Finance_Detail__c fd1= new Finance_Detail__c(Account__c=GBacc.Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='GBP', Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=lstAddress[0].id);
        insert fd1;
        
        String recordTypeIdMed = accountRecordTypes.get('GB Medical Facility');
        Account GBaccMed = new Account();
        GBaccMed.CurrencyIsoCode = 'GBP';
        GBaccMed.RecordTypeId = recordTypeIdMed;
        GBaccMed.name = 'Med';
        GBaccMed.Phone = '1234567891' ;
        GBaccMed.BillingStreet = 'Grüner Weg';
        GBaccMed.BillingCity = 'Friedberg';
        GBaccMed.BillingPostalCode = '1244';
        GBaccMed.BillingCountryCode = 'GB';
        insert GBaccMed; 
        
        GBacc.Medical_Facility__c = GBaccMed.id;
        update GBacc ;
        
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCPB(new List <String>{'UK_Pricebook'}, 'GBP');
        String customPricebookId = customPricebookMap.get('UK_Pricebook');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'DEX-SHIP-01'});
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
            productIdToPriceMap.put(products.get(productName), 125.00);
 
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.CreateCPBEntries(productIdToPriceMap, customPricebookId, 'GBP');
        
        Id oppRecTypeGB = [Select Id from RecordType Where isActive = true AND DeveloperName = 'GB_Opportunity'].id;
        Opportunity newOppGB = new Opportunity();
        newOppGB.RecordTypeId = oppRecTypeGB;
        newOppGB.Name = 'New Opportunity For Testing';
        newOppGB.CurrencyIsoCode = 'GBP';
        newOppGB.AccountId = GBacc.Id;
        newOppGB.Type = 'New';
        newOppGB.Contact_Letter_Sent__c = true;
        newOppGB.Contact_Doc_Received__c = true;
        newOppGB.Insurance_Doc_Received__c = true;
        newOppGB.Hard_Copy_Out__c = true;
        newOppGB.Hard_Copy_In__c = true;
        newOppGB.Training_Letter_Sent__c = true;
        newOppGB.Training_Letter_Sent_Date__c = Date.Today();
        newOppGB.StageName = 'New Opportunity';
        newOppGB.Training_Date__c = Date.today()+3;
        newOppGB.Doc_Collection_Status__c = 'Docs On File - Pending' ;        
        newOppGB.Email_Stage__c = null ; 
        newOppGB.DexTracker_Email__c = 'Yes';
        newOppGB.Consumer_Email__c = 'Tesdt@gmail.com';     
        newOppGB.CloseDate = Date.Today().addDays(30);
        newOppGB.Pricebook2Id = customPricebookId;
        insert newOppGB;
        
        //Insert Opportunity Products
        List<OpportunityLineItem> lineItemsToBeInserted = new List<OpportunityLineItem>();
        for(String productName : products.keySet())
        {
            OpportunityLineItem newItem = new OpportunityLineItem();
            newItem.OpportunityId = newOppGB.Id;
            newItem.Quantity  = 2;
            newItem.UnitPrice = 125;
            newItem.PricebookEntryId = productIdToPbeId.get(products.get(productName));
            lineItemsToBeInserted.add(newItem);
        }
        insert lineItemsToBeInserted;
        
        ClsCheckRecursive.run = true ;
        newOppGB.Health_Insurance_Approval__c = 'Not Required';
        newOppGB.CA_Customer_Docs_Collection_Status__c = 'Not Required';
        newOppGB.Stagename = 'Order Fulfillment'; 
        update newOppGB ;   
    }
    @isTest private static void InsertTestDataDE_Part2(){   
          Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'Barmer'});
        String customPricebookId = customPricebookMap.get('Barmer');
        //Create accounts required for Opportunity creation
        List<Account> accountsToBeUpdated = new List<Account>();
       /* List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Account' and isActive=true];*/
        
        //Create a map between the Record Type Name and Id 
        Map<String,String> accountRecordTypes = new Map<String,String>();
        /*
        for(Schema.RecordTypeInfo rti : Schema.SObjectType.Account.getRecordTypeInfosById().values()){
            accountRecordTypes.put(rti.getName(),rti.getRecordTypeId());
        }
*/
        for(RecordType rti : [Select Name, ID from RecordType where sobjecttype = 'Account' and IsActive=true])
            accountRecordTypes.put(rti.Name,rti.Id);
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
        a.PersonEmail = 'Tesdt@gmail.com';
        a.PersonHasOptedOutOfEmail = false;
        a.Benefit_Member_Id__c='1234567899';
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
        a.Benefit_Member_Id__c='1234567899';
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
        a.Benefit_Member_Id__c='1234567899';
        a.Price_Book__c = customPricebookId;
       
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
        a.Benefit_Member_Id__c='1234567899';
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
        a.Benefit_Member_Id__c='1234567899';
        accts.add(a);  
        insert accts;      
        
        accts[0].Medical_Facility__c = accts[3].Id;
        accts[0].Prescriber__c = accts[1].Id;
        accts[0].PersonBirthDate = Date.newInstance(1960, 2, 17);
        accts[0].Benefit_Member_Id__c='1234567899';
        accts[0].payor__C=accts[2].id;
        
        //Create Pricebook
      
       // accts[2].Price_Book__c = customPricebookId;
        
        accountsToBeUpdated.add(accts[0]);
        Update accountsToBeUpdated; 
        
  
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'DEX-SHIP-01'});
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
        {
            productIdToPriceMap.put(products.get(productName), 125.00);
            if(productName == 'DEX-SHIP-01')
            {
                ClsTestDataFactory.createProductSchedule (products.get(productName), products.get('STK-GF-013'), customPricebookId);
            }
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, customPricebookId);
        
        //Create new Benefit and associate it to the payor
        Id benRecType = Schema.SObjectType.Benefit__c.getRecordTypeInfosByDeveloperName().get('DE_Benefit').getRecordTypeId();
            //[Select Id from RecordType  where sObjectType='Benefit__c' and isActive=true AND DeveloperName = 'DE_Benefit'].Id;
        Benefit__c primaryBenefit = new Benefit__c();
        primaryBenefit.RecordTypeId = benRecType;
        primaryBenefit.Account__c = accts[0].Id;
        primaryBenefit.Member_Id__c = '1789657890';
        primaryBenefit.Payor__c = accts[2].Id;
        primaryBenefit.Benefit_Hierarchy__c = 'Primary';
        primaryBenefit.Inactive__c = false;    
        insert primaryBenefit;
        system.debug('accts[2]>>>>>>'+accts[2].Price_book__C);
        //Create new Opportunity
        Id oppRecTypeGermany = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DE_Opportunity').getRecordTypeId();
            //[Select Id from RecordType Where isActive = true AND DeveloperName = 'DE_Opportunity'].id;
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
        //newOpp.Contact_Doc_Received__c = true;
        //newOpp.Insurance_Doc_Received__c = true;
        //newOpp.Hard_Copy_Out__c = true;
        //newOpp.Hard_Copy_In__c = true;
        newOpp.Training_Letter_Sent__c = true;
        newOpp.Training_Letter_Sent_Date__c = Date.Today();
        newOpp.StageName = 'New Opportunity';
        newOpp.Training_Date__c = Date.today()+3;
        //newOpp.Doc_Collection_Status__c = 'Docs On File - Pending' ;        
        newOpp.Email_Stage__c = null ; 
        newOpp.Cash_Pay__c=true;
        newOpp.DexTracker_Email__c = 'Yes';
        newOpp.Consumer_Email__c = 'Tesdt@gmail.com';  
                 system.debug('accts[1]>>>>>>'+accts[2].Price_book__C);   
         system.debug('accts[2]>>>>>>'+newOpp.Medical_Facility__c);   
         system.debug('accts[3]>>>>>>'+newopp.Prescriber__c);   
         system.debug('accts[4]>>>>>>'+newopp.Payor__c);      
        insert newOpp;     
        
        //Insert Opportunity Products
        List<OpportunityLineItem> lineItemsToBeInserted = new List<OpportunityLineItem>();
        for(String productName : products.keySet())
        {
            OpportunityLineItem newItem = new OpportunityLineItem();
            newItem.OpportunityId = newOpp.Id;
            if(productName != 'STK-GF-013'){
                if(productName == 'DEX-SHIP-01')
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
        }
        insert lineItemsToBeInserted;
        
        //Insert Quotes
        Quote newQuote = new Quote();
        newQuote.OpportunityId = newOpp.Id;
        newQuote.Name = newOpp.Name;
        newQuote.Type__c = 'Customer Quote';
        newQuote.Status = 'Draft';
        newQuote.Pricebook2Id = customPricebookId;
        insert newQuote;
        //Insert Quote Products
        List<QuoteLineItem> quoteLineItemsToBeInserted = new List<QuoteLineItem>();
        for(String productName : products.keySet())
        {
            QuoteLineItem quoteLineItem = new QuoteLineItem();
            quoteLineItem.QuoteId = newQuote.Id;
            if(productName != 'STK-GF-013'){
                if(productName == 'DEX-SHIP-01')
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
        }
        insert quoteLineItemsToBeInserted;                   
        newQuote.Status = 'Approved';    
        update newQuote;
        lineItemsToBeInserted[0].Quantity  = 4;
        update lineItemsToBeInserted;
        Test.startTest();
        
        ClsCheckRecursive.run = true ;
        newOpp.Training_Letter_Sent_Date__c = Date.Today();
        newOpp.Cash_Pay__c = false ;
        newOpp.Doc_Collection_Status__c = 'Pending Docs To Bill' ;
        newOpp.StageName = 'Order Fulfillment' ;        
       // update newOpp ;  
        /*
        ClsCheckRecursive.run = true ;       
        newOpp.benefit_Auth_start_date__c = Date.today();      
        newOpp.Stagename = 'Cancelled'; 
        newOpp.Create_New_Opportunity__c = true ;        
        newOpp.Training_Date__c = Date.today()+4;
        newOpp.Doc_Collection_Status__c = 'Docs On File - Pending' ;        
        newOpp.Email_Stage__c = 1 ; 
        newOpp.DexTracker_Email__c = 'Yes';
        newOpp.Consumer_Email__c = 'Teshdt@gmail.com';   
        newOpp.Training_Confirmation_Channel__c = 'Sales Rep';
        newOpp.Contact_Doc_Received__c = false;
        newOpp.Type = 'Reorder';    
        update newOpp ;   
        */
        //Pricebook2 newPricebook = [Select Id, Cash_Pay__c from Pricebook2 limit 1];
        //newPricebook.Cash_Pay__c = True;
        //update newPricebook;
        
        Delete newQuote;
        Delete lineItemsToBeInserted ;
        
        
        Test.stopTest();
        
    } 
    @isTest static void InsertTestClsSSIPUtilities(){        
        
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Account' and isActive=true];
        //Create a map between the Record Type Name and Id 
        Map<String,String> accountRecordTypes = new Map<String,String>();
        for(RecordType rt: rtypes)
            accountRecordTypes.put(rt.Name,rt.Id);
        List<Account> accts = new List<Account>();
        
        String recordTypeIdIE = accountRecordTypes.get('IE Consumer');
        Account IEacc = new Account();
        IEacc.CurrencyIsoCode = 'EUR';
        IEacc.RecordTypeId = recordTypeIdIE;
        IEacc.FirstName='TestConsumerFirstName';
        IEacc.LastName='TestConsumerLastName';
        IEacc.BillingStreet = 'Grüner Weg';
        IEacc.BillingCity = 'Friedberg';
        IEacc.BillingPostalCode = '1234';
        IEacc.BillingCountryCode = 'IE';
        IEacc.PersonEmail = 'Tesdt@gmail.com';
        IEacc.PersonHasOptedOutOfEmail = false;
        insert IEacc; 
        Id RTIdAddDE =[Select Id From RecordType where sObjectType='Address__c' and isActive=true AND DeveloperName='UK_Address' Limit 1][0].Id;        
        
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = IEacc.Id,Type__c = 'Bill To', Country__c = 'Ireland',  City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '6089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE),
            new Address__c(Account__c = IEacc.Id,Type__c = 'Ship To',Country__c = 'Ireland',  City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '6089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE)
        };
        insert lstAddress;
        Finance_Detail__c fd1= new Finance_Detail__c(Account__c=IEacc.Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='EUR', Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=lstAddress[0].id);
        insert fd1;
                
        String recordTypeIdMed = accountRecordTypes.get('IE Medical Facility');
        Account IEaccMed = new Account();
        IEaccMed.CurrencyIsoCode = 'EUR';
        IEaccMed.RecordTypeId = recordTypeIdMed;
        IEaccMed.name = 'Med';
        IEaccMed.Phone = '1234567891' ;
        IEaccMed.BillingStreet = 'Grüner Weg';
        IEaccMed.BillingCity = 'Friedberg';
        IEaccMed.BillingPostalCode = '1244';
        IEaccMed.BillingCountryCode = 'IE';
        insert IEaccMed; 
        
        IEacc.Medical_Facility__c = IEaccMed.id;
        update IEacc ;
        
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCPB(new List <String>{'IE_Pricebook'}, 'EUR');
        String customPricebookId = customPricebookMap.get('IE_Pricebook');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'DEX-SHIP-01'});
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
            productIdToPriceMap.put(products.get(productName), 125.00);

        
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, customPricebookId);
        Test.StartTest();
        PriceBook2 pb2=[select id,IsSubscription__c from Pricebook2 where id=:customPricebookId];
        pb2.IsSubscription__c=true;
        update pb2;
        List<pricebookentry> pbeList=new List<PriceBookentry>();
        for(PriceBookEntry pbe:[select id,Optional_Subscription_Item__c,isactive from pricebookentry]){
           pbe.Optional_Subscription_Item__c=false;
           pbe.SSIP_Periodic_Order_Quantity__c=2;
           pbe.SSIP_Next_Order_In_Days__c=3;
           pbe.First_Repeat_Order_Lead_Days__c=3;
           pbe.isactive=true;
          
           pbeList.add(pbe);
        }
        update pbelist;
        system.debug('pbelist>>>'+pbelist);
        
        Id oppRecTypeIE = [Select Id from RecordType Where isActive = true AND DeveloperName = 'IE_Opportunity'].id;
        Opportunity newOppIE = new Opportunity();
        newOppIE.RecordTypeId = oppRecTypeIE;
        newOppIE.Name = 'New Opportunity For Testing';
        newOppIE.CurrencyIsoCode = 'EUR';
        newOppIE.AccountId = IEacc.Id;
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
       
       
        Test.stopTest();  
        
    } 
    @isTest static void InsertTestDataCA2(){
        
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Account' and isActive=true];
        //Create a map between the Record Type Name and Id 
        Map<String,String> accountRecordTypes = new Map<String,String>();
        for(RecordType rt: rtypes)
            accountRecordTypes.put(rt.Name,rt.Id);
        List<Account> accts = new List<Account>();
        
        String recordTypeIdCA = accountRecordTypes.get('CA Consumer');
        Account CAacc = new Account();
        CAacc.CurrencyIsoCode = 'CAD';
        CAacc.RecordTypeId = recordTypeIdCA;
        CAacc.FirstName='TestConsumerFirstName';
        CAacc.LastName='TestConsumerLastName';
        CAacc.BillingStreet = 'Grüner Weg';
        CAacc.BillingCity = 'Friedberg';
        CAacc.BillingPostalCode = 'V7J 3H5';
        CAacc.BillingCountryCode = 'CA';
        CAacc.BillingStateCode = 'AB';        
        CAacc.PersonEmail = 'Tesdt@gmail.com';
        CAacc.PersonHasOptedOutOfEmail = false;
        insert CAacc; 
        
        Id RTIdAddDE =[Select Id From RecordType where sObjectType='Address__c' and isActive=true AND DeveloperName='CA_Address' Limit 1][0].Id; 
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = CAacc.Id,Type__c = 'Bill To', Country__c = 'Canada',  City__c = 'Rosemont', Address_Line_1__c = 'gins Rd', Postal_Code__c = 'V7J 3H5', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE),
                new Address__c(Account__c = CAacc.Id,Type__c = 'Ship To',Country__c = 'Canada',  City__c = 'Rosemont', Address_Line_1__c = 'Higgins Rd', Postal_Code__c = 'V7J 3H5', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE)
                };
                    insert lstAddress;
        
        String recordTypeIdMed = accountRecordTypes.get('CA Medical Facility');
        Account CAaccMed = new Account();
        CAaccMed.CurrencyIsoCode = 'CAD';
        CAaccMed.RecordTypeId = recordTypeIdMed;
        CAaccMed.name = 'Med';
        CAaccMed.Phone = '1234567891' ;
        CAaccMed.BillingStreet = 'Grüner Weg';
        CAaccMed.BillingCity = 'Friedberg';
        CAaccMed.BillingPostalCode = 'V7J 3H5';
        CAaccMed.BillingCountryCode = 'CA';
        CAaccMed.BillingState ='Alberta';
        
        insert CAaccMed; 
        
        String recordTypeIdPres = accountRecordTypes.get('CA Prescriber');
        Account CAaccPres = new Account();
        CAaccPres.CurrencyIsoCode = 'CAD';
        CAaccPres.RecordTypeId = recordTypeIdPres;
        CAaccPres.FirstName='TestPresFirstName';
        CAaccPres.LastName='TestPresrLastName';
        CAaccPres.BillingStreet = 'Grüner Weg';
        CAaccPres.BillingCity = 'Friedberg';
        CAaccPres.BillingPostalCode = 'V7J 3H5';
        CAaccPres.BillingCountryCode = 'CA';
        CAaccPres.PersonEmail = 'TesdtT@gmail.com';
        CAaccPres.PersonHasOptedOutOfEmail = false;
        CAaccPres.Medical_Facility__c = CAaccMed.id ;
        CAaccPres.BillingState = 'Alberta';
        insert CAaccPres;  	
        
        
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCPB(new List <String>{'CA_Pricebook'}, 'CAD');
        String customPricebookId = customPricebookMap.get('CA_Pricebook');
        
        Account a = new Account();
        String recordTypeId = accountRecordTypes.get('CA Payor');
        a.CurrencyIsoCode = 'CAD';
        a.RecordTypeId = recordTypeId;
        a.Name = 'TestAccount';
        a.Insurance_Company_Identification_Number__c = '9876567';
        a.BillingStreet = 'Grüner Weg';
        a.BillingCity = 'Friedberg';
        a.BillingPostalCode = 'V7J 3H5';
        a.BillingCountryCode = 'CA';
        a.Price_Book__c = customPricebookId;
        a.BillingState = 'Alberta';
        a.Benefit_Member_Id__c='1234567899';
        insert a;  
        
      
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'DEX-SHIP-01'});
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
            productIdToPriceMap.put(products.get(productName), 125.00);
        
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCH(productIdToPriceMap, customPricebookId);		
        test.startTest();
        
        
        Id oppRecTypeCA = [Select Id from RecordType Where isActive = true AND DeveloperName = 'CA_Opportunity'].id;
        Opportunity newOppCA = new Opportunity();
        newOppCA.RecordTypeId = oppRecTypeCA;
        newOppCA.Name = 'New Opportunity For Testing';
        newOppCA.CurrencyIsoCode = 'CAD';
        newOppCA.AccountId = CAacc.Id;
        newOppCA.Type = 'New';
        newOppCA.Contact_Letter_Sent__c = true;
        newOppCA.Contact_Doc_Received__c = true;
        newOppCA.Insurance_Doc_Received__c = true;
        newOppCA.Hard_Copy_Out__c = true;
        newOppCA.Hard_Copy_In__c = true;
        newOppCA.Training_Letter_Sent__c = true;
        newOppCA.Training_Letter_Sent_Date__c = Date.Today();
        newOppCA.StageName = 'New Opportunity';
        newOppCA.Training_Date__c = Date.today()+3;
        newOppCA.Doc_Collection_Status__c = 'Docs On File - Pending' ;        
        newOppCA.Email_Stage__c = null ; 
        newOppCA.DexTracker_Email__c = 'Yes';
        newOppCA.Consumer_Email__c = 'Tesdt@gmail.com';     
        newOppCA.CloseDate = Date.Today().addDays(30);
        insert newOppCA;
        
        
        //Insert Opportunity Products
        List<OpportunityLineItem> lineItemsToBeInserted = new List<OpportunityLineItem>();
        for(String productName : products.keySet())
        {
            OpportunityLineItem newItem = new OpportunityLineItem();
            newItem.OpportunityId = newOppCA.Id;
            newItem.Repeat_Quantity__c = 2;
            newItem.Repeat_after_in_Days__c = 2 ;
            newItem.Quantity  = 1;
            newItem.UnitPrice = 125;
            newItem.PricebookEntryId = productIdToPbeId.get(products.get(productName));
            lineItemsToBeInserted.add(newItem);
        }
       // insert lineItemsToBeInserted;
        
        ClsCheckRecursive.run = true ;
        newOppCA.Payor__c = a.Id;
        newOppCA.CA_Insurance_Coverage__c = 200;
        newOppCA.Benefit_Auth_Start_Date__c = System.today();
        newOppCA.Benefit_Auth_End_Date__c = system.today()+100;
        newOppCA.Pricebook2Id =customPricebookId;
        newOppCA.Health_Insurance_Approval__c = 'Not Required';
        newOppCA.CA_Customer_Docs_Collection_Status__c = 'Not Required';
        newOppCA.Health_Insurance_Approval__c = 'Not Required';
        newOppCA.Determination_Status__c = 'Received via Email';
        newOppCA.Benefit_Prior_Auth_Denied_or_Approved__c = 'APPROVED';
        
        newOppCA.Determination_Received_Date__c = system.today();
        newOppCA.Stagename = 'Order Fulfillment'; 
		newOppCA.Create_Fund__c =True;
        newOppCA.Type = 'Subscription' ;
        update newOppCA ;  
        
        
        
        newOppCA.StageName = 'Closed - Complete';
        newOppCA.Medical_Facility__c = CAaccMed.id;
        newOppCA.Prescriber__c = CAaccPres.id ;
        
        update newOppCA;
        test.stopTest();
        
    }
    @isTest static void InsertTestDataCAMedfac(){
        
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Account' and isActive=true];
        //Create a map between the Record Type Name and Id 
        Map<String,String> accountRecordTypes = new Map<String,String>();
        for(RecordType rt: rtypes)
            accountRecordTypes.put(rt.Name,rt.Id);
        List<Account> accts = new List<Account>();
        
        String recordTypeIdCA = accountRecordTypes.get('CA Consumer');
        Account CAacc = new Account();
        CAacc.CurrencyIsoCode = 'CAD';
        CAacc.RecordTypeId = recordTypeIdCA;
        CAacc.FirstName='TestConsumerFirstName';
        CAacc.LastName='TestConsumerLastName';
        CAacc.BillingStreet = 'Grüner Weg';
        CAacc.BillingCity = 'Friedberg';
        CAacc.BillingPostalCode = 'V7J 3H5';
        CAacc.BillingCountryCode = 'CA';
        CAacc.BillingStateCode = 'AB';        
        CAacc.PersonEmail = 'Tesdt@gmail.com';
        CAacc.PersonHasOptedOutOfEmail = false;
        insert CAacc; 
        
        Id RTIdAddDE =[Select Id From RecordType where sObjectType='Address__c' and isActive=true AND DeveloperName='CA_Address' Limit 1][0].Id; 
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = CAacc.Id,Type__c = 'Bill To', Country__c = 'Canada',  City__c = 'Rosemont', Address_Line_1__c = 'gins Rd', Postal_Code__c = 'V7J 3H5', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE),
                new Address__c(Account__c = CAacc.Id,Type__c = 'Ship To',Country__c = 'Canada',  City__c = 'Rosemont', Address_Line_1__c = 'Higgins Rd', Postal_Code__c = 'V7J 3H5', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE)
                };
                    insert lstAddress;
        
        String recordTypeIdMed = accountRecordTypes.get('CA Medical Facility');
        Account CAaccMed = new Account();
        CAaccMed.CurrencyIsoCode = 'CAD';
        CAaccMed.RecordTypeId = recordTypeIdMed;
        CAaccMed.name = 'Med';
        CAaccMed.Phone = '1234567891' ;
        CAaccMed.BillingStreet = 'Grüner Weg';
        CAaccMed.BillingCity = 'Friedberg';
        CAaccMed.BillingPostalCode = 'V7J 3H5';
        CAaccMed.BillingCountryCode = 'CA';
        CAaccMed.BillingState ='Alberta';
        
        insert CAaccMed; 
        
        String recordTypeIdPres = accountRecordTypes.get('CA Prescriber');
        Account CAaccPres = new Account();
        CAaccPres.CurrencyIsoCode = 'CAD';
        CAaccPres.RecordTypeId = recordTypeIdPres;
        CAaccPres.FirstName='TestPresFirstName';
        CAaccPres.LastName='TestPresrLastName';
        CAaccPres.BillingStreet = 'Grüner Weg';
        CAaccPres.BillingCity = 'Friedberg';
        CAaccPres.BillingPostalCode = 'V7J 3H5';
        CAaccPres.BillingCountryCode = 'CA';
        CAaccPres.PersonEmail = 'TesdtT@gmail.com';
        CAaccPres.PersonHasOptedOutOfEmail = false;
        CAaccPres.Medical_Facility__c = CAaccMed.id ;
        CAaccPres.BillingState = 'Alberta';
        insert CAaccPres;  	
        
        
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCPB(new List <String>{'CA_Pricebook'}, 'CAD');
        String customPricebookId = customPricebookMap.get('CA_Pricebook');
        
        Account a = new Account();
        String recordTypeId = accountRecordTypes.get('CA Payor');
        a.CurrencyIsoCode = 'CAD';
        a.RecordTypeId = recordTypeId;
        a.Name = 'TestAccount';
        a.Insurance_Company_Identification_Number__c = '9876567';
        a.BillingStreet = 'Grüner Weg';
        a.BillingCity = 'Friedberg';
        a.BillingPostalCode = 'V7J 3H5';
        a.BillingCountryCode = 'CA';
        a.Price_Book__c = customPricebookId;
        a.BillingState = 'Alberta';
        a.Benefit_Member_Id__c='1234567899';
        insert a;  
        
      
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'DEX-SHIP-01'});
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
            productIdToPriceMap.put(products.get(productName), 125.00);
        
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCH(productIdToPriceMap, customPricebookId);		
        test.startTest();
        
        
        Id oppRecTypeCA = [Select Id from RecordType Where isActive = true AND DeveloperName = 'CA_Opportunity'].id;
        Opportunity newOppCA = new Opportunity();
        newOppCA.RecordTypeId = oppRecTypeCA;
        newOppCA.Name = 'New Opportunity For Testing';
        newOppCA.CurrencyIsoCode = 'CAD';
        newOppCA.AccountId = CAacc.Id;
        newOppCA.Type = 'New';
        newOppCA.Contact_Letter_Sent__c = true;
        newOppCA.Contact_Doc_Received__c = true;
        newOppCA.Insurance_Doc_Received__c = true;
        newOppCA.Hard_Copy_Out__c = true;
        newOppCA.Hard_Copy_In__c = true;
        newOppCA.Training_Letter_Sent__c = true;
        newOppCA.Training_Letter_Sent_Date__c = Date.Today();
        newOppCA.StageName = 'New Opportunity';
        newOppCA.Training_Date__c = Date.today()+3;
        newOppCA.Doc_Collection_Status__c = 'Docs On File - Pending' ;        
        newOppCA.Email_Stage__c = null ; 
        newOppCA.DexTracker_Email__c = 'Yes';
        newOppCA.Consumer_Email__c = 'Tesdt@gmail.com';     
        newOppCA.CloseDate = Date.Today().addDays(30);
        insert newOppCA;
        
        
        //Insert Opportunity Products
        List<OpportunityLineItem> lineItemsToBeInserted = new List<OpportunityLineItem>();
        for(String productName : products.keySet())
        {
            OpportunityLineItem newItem = new OpportunityLineItem();
            newItem.OpportunityId = newOppCA.Id;
            newItem.Repeat_Quantity__c = 2;
            newItem.Repeat_after_in_Days__c = 2 ;
            newItem.Quantity  = 1;
            newItem.UnitPrice = 125;
            newItem.PricebookEntryId = productIdToPbeId.get(products.get(productName));
            lineItemsToBeInserted.add(newItem);
        }
       // insert lineItemsToBeInserted;
        
        ClsCheckRecursive.run = true ;
             
        newOppCA.StageName = 'Closed - Complete';
        newOppCA.Medical_Facility__c = CAaccMed.id;
        newOppCA.Prescriber__c = CAaccPres.id ;
        
        update newOppCA;
        test.stopTest();
        
    }
    
}