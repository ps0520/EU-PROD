/****************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 8/10/2017
@Description    : Test generates data required for test data classes
@Date Created    : 3/07/2018
@Description    : add Is_Virtual_Product__c default on product creation
****************************************************************************************************************/
@isTest
public class ClsTestDataFactory {
    
    //Method returns the map between Recordtypename and RecordtypeId
	public static Map<String, String> getRecordTypeMap(){
    //Query for the Account record types
    List<RecordType> rtypes = [Select Name, Id From RecordType 
                               where sObjectType='Account' and isActive=true];
    
    //Create a map between the Record Type Name and Id 
    Map<String,String> accountRecordTypes = new Map<String,String>();
    for(RecordType rt: rtypes)
        accountRecordTypes.put(rt.Name,rt.Id);	
     	return accountRecordTypes;
    }
    
    //Method creates accounts based on a particular record type
    public static List<Account> createAccountsWithBillingAddress(Integer numAccts, String accountType, String country) {
        Map<String,String> accountRecordTypes = ClsTestDataFactory.getRecordTypeMap();
		List<Account> accts = new List<Account>();
        String recordTypeId = accountRecordTypes.get(accountType);
        for(Integer i=0;i<numAccts;i++) {
            Account a = new Account();
           // a.CurrencyIsoCode = 'EUR';
            a.RecordTypeId = recordTypeId;
            if(accountType.Contains('Consumer') || accountType.Contains('Prescriber'))
            {
                if(accountType.Contains('Prescriber'))
				{
					a.FirstName='TestPrescFirstName' + i;
					a.LastName='TestPrescLastName' + i;
					a.Prescriber_Id__c = String.valueOf(Integer.valueOf('1000') + i);
				}
				else
				if(accountType.Contains('Consumer'))
				{
					a.FirstName='TestConsumerFirstName' + i;
					a.LastName='TestConsumercLastName' + i;
				}	
                
            }
            else
            {
                a.Name = 'TestAccount' + i;
				if(accountType.Contains('Payor'))
					a.Insurance_Company_Identification_Number__c = '9876567' + i;
            }
            
            if(country == 'Germany')
            {
                a.BillingStreet = 'Grüner Weg' + i;
                a.BillingCity = 'Friedberg';
                a.BillingPostalCode = '61169';
                a.BillingCountryCode = 'DE';
            }
            if(country == 'Canada')
            {
                a.BillingStreet = '10 Main Street' + i;
                a.BillingCity = 'Victoria';
                a.BillingPostalCode = 'V5Z 2M9';
                a.BillingStateCode = 'BC';
                a.BillingCountryCode = 'CA';
            }
            if(country == 'Switzerland')
            {
                a.BillingStreet = 'Main Street' + i;
                a.BillingCity = 'Victoria';
                a.BillingPostalCode = '1234';
               // a.BillingStateCode = 'BC';
                a.BillingCountryCode = 'CH';
            }
            if(country == 'United Kingdom')
            {
                a.BillingStreet = 'Main Street' + i;
                a.BillingCity = 'Victoria';
                a.BillingPostalCode = '12345';
               // a.BillingStateCode = 'BC';
                a.BillingCountryCode = 'GB';
            }
            if(country == 'Netherlands')
            {
                a.BillingStreet = 'Main Street' + i;
                a.BillingCity = 'Victoria';
                a.BillingPostalCode = '6135';
               // a.BillingStateCode = 'BC';
                a.BillingCountryCode = 'NL';
                 a.CurrencyIsoCode = 'USD';
            }
            
            accts.add(a);
        }
        insert accts;
        return accts;
    }
    public static void createCashPayor() {
        Map<String,String> accountRecordTypes = ClsTestDataFactory.getRecordTypeMap();
        Account a = new Account();
        String recordTypeId = accountRecordTypes.get('DE Payor');
      //  a.CurrencyIsoCode = 'EUR';
        a.RecordTypeId = recordTypeId;
        a.Name = 'CASH PAYOR';
        a.Insurance_Company_Identification_Number__c = '9876567';
        a.BillingStreet = 'Grüner Weg';
        a.BillingCity = 'Friedberg';
        a.BillingPostalCode = '61169';
        a.BillingCountryCode = 'DE';
        insert a;
    }
    //Method creates a Medical facility and adds Prescriber associations based on the parameter numPrescribers count
    public static List<Account> createAccountsWithPrescriberToMedFacAssociation(Integer numPrescribers, String country) {
        
        String prescriberTypeRecordTypeId;
        String medFacTypeRecordTypeId;
        Map<String,String> accountRecordTypes = ClsTestDataFactory.getRecordTypeMap();
		
        if(country == 'Germany')
        {
            prescriberTypeRecordTypeId = accountRecordTypes.get('DE Prescriber');
            medFacTypeRecordTypeId = accountRecordTypes.get('DE Medical Facility');
        }	
        //Create a Medical Facility account
        Account medFac = new Account();
        medFac.Name = 'Medical Facility';
        medFac.RecordtypeId = medFacTypeRecordTypeId;
        medFac.BillingStreet = 'Grüner Weg';
        medFac.BillingCity = 'Friedberg';
        medFac.BillingPostalCode = '61169';
        medFac.BillingCountryCode = 'DE';
       // medFac.CurrencyIsoCode = 'EUR';
        insert medFac;
        
        //Create Prescriber Accounts along with its associations	
        List<Account> prescriberList = new List<Account>();
        for(Integer i=0;i<numPrescribers;i++) {
            Account prescriber = new Account();
            prescriber.RecordTypeId = prescriberTypeRecordTypeId;
            prescriber.FirstName='TestPresFirstNameWithMedFac' + i;
            prescriber.LastName='TestPresLastNameWithMedFac' + i;
            prescriber.Prescriber_Id__c = String.valueOf(Integer.valueOf('1000') + i);
            //prescriber.CurrencyIsoCode = 'EUR';
            prescriber.Medical_Facility__c = medFac.Id;
            prescriber.BillingStreet = 'Schaustra Weg' + i;
            prescriber.BillingCity = 'Friedberg';
            prescriber.BillingPostalCode = '61169';
            prescriber.BillingCountryCode = 'DE';
            prescriberList.add(prescriber);
        }
        insert prescriberList;
        return prescriberList;
    }
	//Method creates Products for given product lists
    public static Map<String, Id> createProducts(List<String> prodNames) {
        
        List<Product2> productsToBeAdded = new List<Product2>();
		Map<String, Id> productNameToIdMap = new Map<String, Id>();
		for(String prodName : prodNames)
		{
			Product2 newProd = new Product2();
			newProd.Name = prodName;
			newProd.ProductCode = prodName;
			newProd.IsActive = true;
			newProd.External_Id__c = prodName;
			newProd.Is_Virtual_Product__c = false;
            //newProd.CurrencyIsoCode = 'EUR' ; 
			productsToBeAdded.add(newProd);
		}
		insert productsToBeAdded;
		for(Product2 prod : productsToBeAdded)
		{
			productNameToIdMap.put(prod.Name, prod.Id);
		}
		return productNameToIdMap;
	}
	//Method creates custom pricebook
    public static Map<String, Id> createCustomPricebook(List<String> pricebookNames) {
        return createCPB(pricebookNames, 'EUR');
    }
    public static Map<String, Id> createCustomPricebookDIST(List<String> pricebookNames) {
        return createCPB(pricebookNames, 'USD');
    }
    
   public static Map<String, Id> createCPB(List<String> pricebookNames, String cur) {     
        List<Pricebook2> pricebooksToBeAdded = new List<Pricebook2>();
		Map<String, Id> pricebookNameToIdMap = new Map<String, Id>();
		for(String pricebookName : pricebookNames)
		{
			Pricebook2 newPricebook = new Pricebook2();
			newPricebook.Name = pricebookName;
			newPricebook.IsActive = true;
            newPricebook.CurrencyIsoCode = cur ; 
			pricebooksToBeAdded.add(newPricebook);
		}
		insert pricebooksToBeAdded;
		for(Pricebook2 priceBook : pricebooksToBeAdded)
		{
			pricebookNameToIdMap.put(priceBook.Name, priceBook.Id);
		}
		return pricebookNameToIdMap;
	}
	//Method creates pricebook entries and returns ProductId to Pricebookentry Id
    public static Map<Id, Id> createCustomPricebookEntries(Map<Id, Decimal> productIdToPriceMap, Id customPricebookId) {
        return CreateCPBEntries(productIdToPriceMap, customPricebookId, 'EUR');
    }
    
    //Method creates pricebook entries and returns ProductId to Pricebookentry Id
    public static Map<Id, Id> createCustomPricebookEntriesCH(Map<Id, Decimal> productIdToPriceMap, Id customPricebookId) {
        return CreateCPBEntries(productIdToPriceMap, customPricebookId, 'CHF');
    }
    //Method creates pricebook entries and returns ProductId to Pricebookentry Id
    public static Map<Id, Id> createCustomPricebookEntriesDIST(Map<Id, Decimal> productIdToPriceMap, Id customPricebookId) {
        return CreateCPBEntries(productIdToPriceMap, customPricebookId, 'USD');
    }
     //Method creates pricebook entries and returns ProductId to Pricebookentry Id
    public static Map<Id, Id> createCustomPricebookEntriesCA(Map<Id, Decimal> productIdToPriceMap, Id customPricebookId) {
        return CreateCPBEntries(productIdToPriceMap, customPricebookId, 'CAD');
    }
    public static Map<Id, Id> CreateCPBEntries(Map<Id, Decimal> productIdToPriceMap, Id customPricebookId, String cur) {

    // Get standard price book ID.
        Id standardPricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>();
		List<PricebookEntry> customPricebookEntries = new List<PricebookEntry>();
		Map<Id, Id> productIdToPbeId = new Map<Id, Id>();
		//Insert the products to the standard pricebook
		for(Id productId : productIdToPriceMap.keySet())
		{
			// Insert a price book entry for the standard price book.
			PricebookEntry standardPriceBookEntry = new PricebookEntry(
			Pricebook2Id = standardPricebookId, Product2Id = productId,
			UnitPrice = 1, IsActive = true, CurrencyIsoCode = cur );
			standardPricebookEntries.add(standardPriceBookEntry);
		}
		try{
			insert standardPricebookEntries;
		}
		catch (Exception e) {}
		//Insert the products to custom pricebook
		for(Id productId : productIdToPriceMap.keySet())
		{
			// Insert a price book entry for the standard price book.
			PricebookEntry customPriceBookEntry = new PricebookEntry(
			Pricebook2Id = customPricebookId, Product2Id = productId,
			UnitPrice = productIdToPriceMap.get(productId), IsActive = true, CurrencyIsoCode = cur);
			customPricebookEntries.add(customPriceBookEntry);
		}
		try{
			insert customPricebookEntries;
		}
		catch (Exception e) {}
		for(PricebookEntry pe : customPricebookEntries)
		{
			productIdToPbeId.put(pe.Product2Id, pe.Id);
            system.debug('Custom Price Book Entry Currency Code: ' + pe.CurrencyIsoCode  + ', Price: ' + pe.UnitPrice );
		}
		return productIdToPbeId;
	}
	//Method creates Related Product entries for a Medical Advice Numbered product
    public static void createProductSchedule (Id medicalAdviceNumberId, Id productId, Id pricebookId) {
		// For each Medical Advice number product add all the products
		//Insert Related Product
		Related_Product__c relProd = new Related_Product__c();
		relProd.Medical_Advice_Number__c = medicalAdviceNumberId;
		relProd.Quantity__c = 4;
		relProd.Price__c = 125;
        relProd.Product__c = productId;
		relProd.Valid_Period__c = '12 Months';
        relProd.Price_Book__c = pricebookId;
		insert relProd;
		//Insert product schedule
		Product_Schedule__c prodSched = new Product_Schedule__c();
		prodSched.Number_Of_Days_Between_Orders__c = 0;
		prodSched.Product__c = relProd.Id;
		prodSched.Quantity__c = 4;
		prodSched.Sequence__c = '1';
		insert prodSched;
	}
	//Method creates a user reocrd
	public static User createTestUser(Id roleId, Id profID, String fName, String lName)
    {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
       
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User tuser = new User(  firstname = fName,
                                lastName = lName,
                                email = uniqueName + '@test' + orgId + '.org',
                                Username = uniqueName + '@test' + orgId + '.org',
                                EmailEncodingKey = 'ISO-8859-1',
                                Alias = uniqueName.substring(18, 23),
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US',
                                ProfileId = profId,
								User_Type__c = 'IT Admin',
                                UserRoleId = roleId);
        return tuser;
    }
    //Method creates a CustomerFeedback reocrd
	public static Customer_Feedback__c createCustomerFeedback(){
        Account objAccount = createAccountsWithBillingAddress(1, 'GB Payor', 'Canada')[0];
        Customer_Feedback__c custFeedback = new Customer_Feedback__c();
        custFeedback.Account__c = objAccount.Id;
        custFeedback.High_Level_Feedback_Box__c = 'High Level Feedback';
        custFeedback.Note_Box__c = 'Custom Note';
        custFeedback.Type__c = 'Code 400 Data Entry';
        custFeedback.Resolution_Box__c='Need Code Backup';
        //ClsTestDataFactory.createCustomerFeedback();
        insert custFeedback;
        return custFeedback;
    }
    // Task Creation for QC Hold
    public static Task createTask(){
        Id tskQCRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('QC Hold').getRecordTypeId();
        Task tsk = new Task();      
        tsk.Subject = 'Data Migration Issue';
        tsk.RecordTypeId = tskQCRecordTypeId;
        tsk.Type = 'QC Hold';
        tsk.ActivityDate = System.today();
        tsk.OwnerId = UserInfo.getUserId();
        tsk.Description = 'Comments goes here';
       // tsk.WhatId = recordId;
        //insert tsk;
        return tsk;
    }
    
}