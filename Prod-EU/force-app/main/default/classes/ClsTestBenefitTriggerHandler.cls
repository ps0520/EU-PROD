/********************************************************************************
@Author        : Navneet
@Date Created    : 06/14/2019
@Description    : Test class to test the Benefit trigger handler
*********************************************************************************/
@isTest
private class ClsTestBenefitTriggerHandler {
    @isTest static void TestBenefit(){
       
        //Create accounts required for Opportunity creation
        List<Account> accountsToBeUpdated = new List<Account>();
        
        /*
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(2, 'DE Consumer', 'Germany');
        //Insert 1 MedicalFacility account record
        List<Account> medFacAccts = ClsTestDataFactory.createAccountsWithBillingAddress(2, 'DE Medical Facility', 'Germany');
        //Insert 1 Payor account record
        List<Account> payorAccts = ClsTestDataFactory.createAccountsWithBillingAddress(2, 'DE Payor', 'Germany');
        //Insert 1 Prescriber account record
        List<Account> prescriberAccts = ClsTestDataFactory.createAccountsWithBillingAddress(2, 'DE Prescriber', 'Germany');
*/
            List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Account' and isActive=true];
        
        //Create a map between the Record Type Name and Id 
        Map<String,String> accountRecordTypes = new Map<String,String>();
        for(RecordType rt: rtypes)
            accountRecordTypes.put(rt.Name,rt.Id);
        List<Account> accts = new List<Account>();
        
        String recordTypeId = accountRecordTypes.get('CA Consumer');
        Account a = new Account();
        a.CurrencyIsoCode = 'CAD';
        a.RecordTypeId = recordTypeId;
        a.FirstName='TestConsumerFirstName';
        a.LastName='TestConsumerLastName';
        a.BillingStreet = 'Grüner Weg';
        a.BillingCity = 'Friedberg';
        a.BillingPostalCode = 'V7J 3H5';
        a.BillingCountryCode = 'CA';
        a.BillingStateCode = 'AB';
        a.PersonEmail = 'Tesdt@gmail.com';
        a.PersonHasOptedOutOfEmail = false;
        accts.add(a);    
        a = new Account();
        recordTypeId = accountRecordTypes.get('CA Prescriber');
        a.CurrencyIsoCode = 'CAD';
        a.RecordTypeId = recordTypeId;
        a.FirstName='TestPrescFirstName';
        a.LastName='TestPrescLastName';
		a.Prescriber_Id__c = String.valueOf(Integer.valueOf('1000'));
        a.BillingStreet = 'Grüner Weg';
        a.BillingCity = 'Friedberg';
        a.BillingPostalCode = 'V7J 3H5';
        a.BillingCountryCode = 'CA';
        a.BillingStateCode = 'AB';
        a.BillingState = 'Alberta';
        accts.add(a);
        a = new Account();
        recordTypeId = accountRecordTypes.get('CA Payor');
        a.CurrencyIsoCode = 'CAD';
        a.RecordTypeId = recordTypeId;
       	a.Name = 'TestAccount';
		a.Insurance_Company_Identification_Number__c = '9876567';
        a.BillingStreet = 'Grüner Weg';
        a.BillingCity = 'Friedberg';
        a.BillingPostalCode = 'V7J 3H5';
        a.BillingCountryCode = 'CA';
        a.BillingStateCode = 'AB';
        a.BillingState = 'Alberta';
        accts.add(a);    
        a = new Account();
        recordTypeId = accountRecordTypes.get('CA Medical Facility');
        a.CurrencyIsoCode = 'CAD';
        a.RecordTypeId = recordTypeId;
       	a.Name = 'TestAccount';
        a.BillingStreet = 'Grüner Weg';
        a.BillingCity = 'Friedberg';
        a.BillingPostalCode = 'V7J 3H5';
        a.BillingCountryCode = 'CA';
        a.BillingStateCode = 'AB';
        a.BillingState = 'Alberta';
        accts.add(a);
        //payor 2
        a = new Account();
        recordTypeId = accountRecordTypes.get('CA Payor');
        a.CurrencyIsoCode = 'CAD';
        a.RecordTypeId = recordTypeId;
       	a.Name = 'Test Payor 2';
		a.Insurance_Company_Identification_Number__c = '1223444';
        a.BillingStreet = 'Grüner Weg';
        a.BillingCity = 'Friedberg';
        a.BillingPostalCode = 'V7J 3H5';
        a.BillingCountryCode = 'CA';
        a.BillingStateCode = 'AB';
        a.BillingState = 'Alberta';
        accts.add(a);    
    insert accts;      
    
    //accts[0].Medical_Facility__c = accts[3].Id;
    //accts[0].Prescriber__c = accts[1].Id;
    //accts[0].PersonBirthDate = Date.newInstance(1960, 2, 17);
    //accts.add(accts[0]);
    
        
        accts[0].Medical_Facility__c = accts[3].Id;
        accts[0].Prescriber__c = accts[1].Id;
        accts[0].PersonBirthDate = Date.newInstance(1960, 2, 17);
        accountsToBeUpdated.add(accts[0]);
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCPB(new List <String>{'Barmer'}, 'CAD');
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
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, customPricebookId);
        Id caOppRecType = [Select Id from RecordType where isActive = true AND SobjectType = 'Benefit__c' and DeveloperName = 'CA_Benefit'].Id;
        
        //Create new Benefit and associate it to the payor
        Benefit__c primaryBenefit = new Benefit__c();
        primaryBenefit.RecordTypeId = caOppRecType;
        primaryBenefit.Account__c = accts[0].Id;
        primaryBenefit.Member_Id__c = '1789657890';
        primaryBenefit.Payor__c = accts[2].Id;
        primaryBenefit.Benefit_Hierarchy__c = 'Primary';
        insert primaryBenefit;
        
       //Create new Benefit and associate it to the payor
        Benefit__c Ben = new Benefit__c();
        Ben.Account__c = accts[0].Id;
        Ben.Member_Id__c = '1789657890';
        Ben.Payor__c = accts[2].Id;
        Ben.Benefit_Hierarchy__c = 'Other';
        insert Ben;
        List<opportunity> opps = new List<Opportunity>();       
        //Create new Opportunity
        Opportunity newOpp = new Opportunity();
        newOpp.Name = 'New Opportunity For Testing';
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
        // insert newOpp;   
       opps.add(newOpp);    
                    
        Opportunity newOpp1 = new Opportunity();
        newOpp1.Name = 'New Opportunity For Testing';
        newOpp1.AccountId = accts[0].Id;
        newOpp1.Benefit__c = primaryBenefit.Id;
        newOpp1.Medical_Facility__c = accts[3].Id;
        newOpp1.Prescriber__c = accts[1].Id;
        newOpp1.Payor__c = accts[4].Id;
        newOpp1.Type = 'New';
        newOpp1.Pricebook2Id = customPricebookId;
        newOpp1.CloseDate = Date.Today().addDays(30);
        newOpp1.Contact_Letter_Sent__c = true;
        newOpp1.Contact_Doc_Received__c = true;
        newOpp1.Insurance_Doc_Received__c = true;
        newOpp1.Hard_Copy_Out__c = true;
        newOpp1.Hard_Copy_In__c = true;
        newOpp1.Training_Letter_Sent__c = true;
        newOpp1.Training_Letter_Sent_Date__c = Date.Today();
        newOpp1.StageName = 'New Opportunity';
        ClsCheckRecursive.run = true ;
        //insert newOpp1;  
        opps.add(newOpp1); 
        insert opps;
        
        Test.startTest();       
        
        primaryBenefit.Member_Id__c = '1789657891';
           update primaryBenefit ; 
        
           newOpp1.Payor__c = accts[2].Id;
           newOpp1.StageName = 'Closed - Complete';
            newOpp1.CA_Coverage_Confirmed__c = true; 
           newOpp1.Estimate_To_Payor_Status__c = 'Received';
           newOpp1.CA_Estimate_to_Patient_Status__c = 'Received';
           newOpp1.Benefit_Prior_Auth_Denied_or_Approved__c = 'APPROVED';
           ClsOpportunityTriggerStaticClass.isExecuting = false;
            ClsCheckRecursive.run = true ;
           update newOpp1; 
            
         /*   newOpp.StageName = 'Closed - Complete';
           newOpp.CA_Coverage_Confirmed__c = true; 
           ClsOpportunityTriggerStaticClass.isExecuting = false;
            ClsCheckRecursive.run = true ;
           update newOpp;    

            
           Ben.Member_Id__c = '1789657891';
           update Ben ;   */     
           primaryBenefit.Member_Id__c = '1789657891';
           update primaryBenefit ;      
          
        
        Test.stopTest();
    }
}