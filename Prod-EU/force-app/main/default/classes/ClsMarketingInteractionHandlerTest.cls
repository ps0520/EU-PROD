@isTest
private class ClsMarketingInteractionHandlerTest {
    
    @isTest 
    private static void testClsMarketingInteractionHandler(){
		//Test the CA Marketing Interactions
		List<Account> accts = ClsTestDataFactory.createAccountsWithBillingAddress(5, 'CA Consumer', 'Canada');
        Test.startTest();
        ClsAccountAddressTriggerStaticClass.invokeMILogicOnlyOnce = true;
        //Test the interaction for communication tyep - CA - Customer Onboarding
		accts[0].Number_of_Orders__c = 1;
		//Test the interaction for communication tyep - CA - Reorder Reminder - G6 Starter Kit
		accts[0].G6_Starter_Kit_Ship_Date__c = System.Today();
		//Update Accounts
		//Test the interaction for communication tyep - CA - Product Onboarding - G6
		accts[1].G6_Transmitter_Ship_Date__c = System.Today();
		update accts;
		
		List<Marketing_Interaction__c> insertedMIs = [SELECT Id, Communication_Type__c FROM Marketing_Interaction__c WHERE Account__c IN : accts];
		System.assertEquals(insertedMIs.size(), 1);
		
		//Try to record a new order for an accountId__c
		accts[0].Number_of_Orders__c = 2;
		ClsAccountAddressTriggerStaticClass.invokeMILogicOnlyOnce = true;
		//Update Account, which will set the conversion flag
		update accts[0];
		List<Account> upatedAccount = [SELECT Id, G6_Starter_Kit_Conversion__c FROM Account WHERE Id = : accts[0].Id];
		System.assertEquals(upatedAccount[0].G6_Starter_Kit_Conversion__c, true);
		Test.stopTest();
	}
    
    @isTest 
    private static void testUKMISubscriptionUpsell(){
        
        List<Account> accountList;
        Set<Id> accountIds = new Set<Id>();
        
        Id gbConsumerId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('GB_Consumer').getRecordTypeId();
		Id ieConsumerId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IE_Consumer').getRecordTypeId();
        
        Test.startTest();
        
        Account a = new Account();
        a.FirstName = 'TestGB';
        a.LastName = 'Account';
        a.RecordTypeId = gbConsumerId;

        Account b = new Account();
        b.FirstName = 'TestIE';
        b.LastName = 'Account';
        b.RecordTypeId = ieConsumerId;
        
       	accountList = new List<Account>{a,b};
        insert accountList;
        
        for (Account acc : accountList){
            accountIds.add(acc.Id);
        }
        
        accountList = [SELECT Id, G6_Starter_Kit_Ship_Date__c FROM Account WHERE Id = :accountIds];

        ClsAccountAddressTriggerStaticClass.invokeMILogicOnlyOnce = true;       
        accountList[0].G6_Starter_Kit_Ship_Date__c = System.now().date();
        accountList[1].G6_Starter_Kit_Ship_Date__c = System.now().date();
        
        accountList = new List<Account>{accountList[0],accountList[1]};
        update accountList;        
        
        //This should not create a new Marketing Interaction
        ClsAccountAddressTriggerStaticClass.invokeMILogicOnlyOnce = true;
        accountList[0].G6_Starter_Kit_Ship_Date__c = Date.today().addDays(-1);        
        update accountList[0];
                 
        List<Marketing_Interaction__c> miList = [SELECT Id, Account__c, Communication_Type__c, Country__c 
                                                 FROM Marketing_Interaction__c];
        Test.stopTest();
        
    	System.assertEquals(2, miList.size());
        System.assert((miList[0].Country__c == 'United Kingdom') && (miList[0].Account__c == accountList[0].Id)
                      && (miList[0].Communication_Type__c == 'UKIE - Subscription Upsell - G6'));        
        System.assert((miList[1].Country__c == 'Ireland') && (miList[1].Account__c == accountList[1].Id) 
                      && (miList[1].Communication_Type__c == 'UKIE - Subscription Upsell - G6'));
    }
    
    @isTest
    private static void testUKMICustomerOnboarding(){       
        Product2 prodShip = new Product2(Name = 'DEX-SHIP-01');
        insert prodShip;
        
        List<Account> accountList;
        Set<Id> accountIds = new Set<Id>();
        
        Id gbConsumerId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('GB_Consumer').getRecordTypeId();
		Id ieConsumerId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IE_Consumer').getRecordTypeId();
        Id gbSalesOrderId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('GB_Sales_Order').getRecordTypeId();
		Id ieSalesOrderId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('IE_Sales_Order').getRecordTypeId();
        
        Test.startTest();
        
        Account a = new Account();
        a.FirstName = 'TestGB';
        a.LastName = 'Account';
        a.RecordTypeId = gbConsumerId;

        Account b = new Account();
        b.FirstName = 'TestIE';
        b.LastName = 'Account';
        b.RecordTypeId = ieConsumerId;
        
       	accountList = new List<Account>{a,b};
        insert accountList;        

        Product2 prodRecord = new Product2(Name = 'STT-GS-006');
        insert prodRecord;
        
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update pb;
        
        PricebookEntry pbe=new PricebookEntry(UnitPrice = 1,
                                              Product2Id = prodRecord.Id, 
                                              Pricebook2Id = pb.Id,
                                              IsActive = true);
        insert pbe;
        
        Order ord = new Order();
        ord.Name = 'Test Order 1';
        ord.Status = 'Draft';
        ord.EffectiveDate = Date.today();
        ord.AccountId = accountList[0].Id;
        ord.Pricebook2Id = pb.Id;
        ord.Price_Book__c = pb.Id;
        ord.RecordTypeId = gbSalesOrderId;
        ord.Type = 'GB STANDARD';
        ord.Shipping_Method__c = 'DPD Local|Ground|0|BS1';
        insert ord;
        
        Order ord2 = new Order();
        ord2.Name = 'Test Order 2';
        ord2.Status = 'Draft';
        ord2.EffectiveDate = Date.today();
        ord2.AccountId = accountList[1].Id;
        ord2.Pricebook2Id = pb.Id;
 		ord2.Price_Book__c = pb.Id;
        ord2.RecordTypeId = ieSalesOrderId;
        ord2.Type = 'IE STANDARD';
        ord2.Shipping_Method__c = 'DHL Express|Ground|IE0|BS1';
        insert ord2;
            
        OrderItem oItem = new OrderItem();
        oItem.OrderId = ord.Id;
        oItem.PricebookEntryId = pbe.Id;
        oItem.Quantity = 1;
        oItem.UnitPrice = 1;
        oItem.Tracking_Number__c = '12345';
        oItem.Product_Name__c = prodRecord.Name;
        oItem.Actual_Ship_Date__c = Date.today();        
        insert oItem;
        
        OrderItem oItem2 = new OrderItem();
        oItem2.OrderId = ord2.Id;
        oItem2.PricebookEntryId = pbe.Id;
        oItem2.Quantity = 1;
        oItem2.UnitPrice = 1;
        oItem2.Tracking_Number__c = '12345';
        oItem2.Product_Name__c = prodRecord.Name;
        oItem2.Actual_Ship_Date__c = Date.today();        
        insert oItem2;
        
        ord.Status = 'Closed';
        update ord;
        
  		ord2.Status = 'Closed';
        update ord2;

        for (Account acc : accountList){
            accountIds.add(acc.Id);
        }
        
        accountList = [SELECT Id, G6_Transmitter_Ship_Date__c FROM Account WHERE Id = :accountIds];

        ClsAccountAddressTriggerStaticClass.invokeMILogicOnlyOnce = true;       
        accountList[0].G6_Transmitter_Ship_Date__c = Date.today();
        accountList[1].G6_Transmitter_Ship_Date__c = Date.today();
        
        accountList = new List<Account>{accountList[0],accountList[1]};
        update accountList;        
        
        //This should not create a new Marketing Interaction
        ClsAccountAddressTriggerStaticClass.invokeMILogicOnlyOnce = true;
        accountList[0].G6_Transmitter_Ship_Date__c = Date.today().addDays(-1);        
        update accountList[0];
        
        Test.stopTest();
        
        List<Marketing_Interaction__c> miList = [SELECT Id, Account__c, Communication_Type__c, Country__c 
                                                 FROM Marketing_Interaction__c];
               
        Map<Id,List<Marketing_Interaction__c>> accountIdtoMiMap = new Map<Id,List<Marketing_Interaction__c>>();
        Map<String,List<Marketing_Interaction__c>> countryToMiMap = new Map<String,List<Marketing_Interaction__c>>();
        Map<String,List<Marketing_Interaction__c>> commTypeToMiMap = new Map<String,List<Marketing_Interaction__c>>();
               
        for (Marketing_Interaction__c mi : miList){
            if (!accountIdtoMiMap.containsKey(mi.Account__c)){
                accountIdtoMiMap.put(mi.Account__c, new List<Marketing_Interaction__c>());
            }
            accountIdtoMiMap.get(mi.Account__c).add(mi);
            
            if (!countryToMiMap.containsKey(mi.Country__c)){
                countryToMiMap.put(mi.Country__c, new List<Marketing_Interaction__c>());
            }
            countryToMiMap.get(mi.Country__c).add(mi);
            
            if (!commTypeToMiMap.containsKey(mi.Communication_Type__c)){
                commTypeToMiMap.put(mi.Communication_Type__c, new List<Marketing_Interaction__c>());
            }
            commTypeToMiMap.get(mi.Communication_Type__c).add(mi);
        }
        
        System.assertEquals(6,miList.size());        
        System.assertEquals(2,countryToMiMap.keySet().size());
        System.assertEquals(2,accountIdtoMiMap.keySet().size());
        System.assertEquals(3,countryToMiMap.get('United Kingdom').size());
        System.assertEquals(3,countryToMiMap.get('Ireland').size());
        System.assertEquals(2,commTypeToMiMap.get('UKIE - Customer Onboarding - G6').size());
        System.assertEquals(2,commTypeToMiMap.get('UKIE - Customer Review').size());
        System.assertEquals(2,commTypeToMiMap.get('UKIE - Warrior Recruitment').size());
        System.assertEquals(3,accountIdtoMiMap.get(accountList[0].Id).size());
        System.assertEquals(3,accountIdtoMiMap.get(accountList[1].Id).size());
        System.assertEquals(accountList[0].Id,countryToMiMap.get('United Kingdom')[0].Account__c);
        System.assertEquals(accountList[1].Id,countryToMiMap.get('Ireland')[0].Account__c);
    }	   
}