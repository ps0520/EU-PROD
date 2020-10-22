@isTest class ClsTPSOTTest {
	@testSetup static void setup() {
        Map<String,String> RTIds = new Map<String,String>();    	
        for(RecordType rt: [Select sObjectType, DeveloperName, Id From RecordType where sObjectType IN ('Account','Address__c','Order') and isActive=true]){
        	RTIds.put(rt.sObjectType + '_' + rt.DeveloperName,rt.Id);    
        }
    	Account a= new Account(RecordTypeId=RTIds.get('Account_CH_Consumer'), LastName='ClsTPSOTTestLN1', FirstName='ClsTPSOTTestFN1');
        a.BillingStreet = 'Zürichstrasse 92'; a.BillingCity = 'Küsnacht'; a.BillingPostalCode = '8700'; a.BillingCountryCode = 'CH';
        insert a;
        System.Debug('**** TPS:EH Test1 1.1 Account a=' + a);
        
        List<Address__c> lstAddress = new List<Address__c>{
         	new Address__c(Account__c = a.Id,Type__c = 'Bill To', Country__c = 'Switzerland', City__c = 'Küsnacht', Address_Line_1__c = 'Zürichstrasse 92', Postal_Code__c = '8700', Primary_Flag__c = true, RecordTypeId=RTids.get('Address__c_CH_Address'), System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
            new Address__c(Account__c = a.Id,Type__c = 'Ship To', Country__c = 'Switzerland', City__c = 'Küsnacht', Address_Line_1__c = 'Zürichstrasse 92', Postal_Code__c = '8700', Primary_Flag__c = true, RecordTypeId=RTids.get('Address__c_CH_Address'), System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
        };
        insert lstAddress;
        
        Map<String, Id> mapCPB = ClsTestDataFactory.createCPB(new List <String>{'CH Cash'}, 'CHF');
        Id  cpbId = mapCPB.get('CH Cash');
		System.Debug('**** TPS:EH Test1 1.2 cpbId=' + cpbId);
        
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GS-013', 'DEX-SHIP-01','MT25313','MT25315','MT25311','STK-GS-109','MT25314','MT25316','MT25332'});
        
        
        Product2 virtualProd = [SELECT Id, Is_Virtual_Product__c FROM Product2 WHERE NAME = 'DEX-SHIP-01'];
        virtualProd.Is_Virtual_Product__c = true;
        update virtualProd;		
		System.Debug('**** TPS:EH Test1 1.3 products=' + products);        
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
        {	
			if(productName.startsWithIgnoreCase('MT'))
				productIdToPriceMap.put(products.get(productName), 0);
			else
				productIdToPriceMap.put(products.get(productName), 125.00);
        }
        System.Debug('**** TPS:EH Test1 1.4 productIdToPriceMap=' + productIdToPriceMap);
        
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesCH(productIdToPriceMap, cpbId);
        System.Debug('**** TPS:EH Test1 1.5 productIdToPbeId=' + productIdToPbeId);        
        
        Order o = new Order(AccountId = a.Id, EffectiveDate = Date.today(), Status = 'Draft', RecordTypeId=RTIds.get('Order_CH_Sales_Order'), Type='CH STANDARD', 
                            Price_Book__c = cpbId, Pricebook2Id = cpbId, CurrencyISOCode='CHF');
        insert o;
        System.Debug('**** TPS:EH Test1 1.6 Order o=' + o);
        
        test.startTest();
        Id p013Id=products.get('STK-GS-013');
        ID pbe013Id=productIdToPbeId.get(p013Id);
        
        List<OrderItem> lstOI = new List<OrderItem>();
        OrderItem oi1= new OrderItem(OrderId = o.Id, Product2Id=p013Id, PricebookEntryId = pbe013Id, Quantity=1, UnitPrice=125.00,Tracking_Number__c='12345', Product_Name__c='STK-GS-013');
        lstOI.Add(oi1);
        System.Debug('**** TPS:EH Test1 1.7 lstOI=' + lstOI);
        insert lstOI;
        System.Debug('**** TPS:EH Test1 1.8 Order o.Count_Of_G6_Receivers__c=' + o.Count_Of_G6_Receivers__c);
        delete oi1;
        test.stopTest();
    }
    
    @isTest static void DeleteOI(){
    	//Account a =[Select Id, Name, LastName  from Account Where LastName='ClsTPSOTTestLN1' Limit 1][0];
        
    }
}