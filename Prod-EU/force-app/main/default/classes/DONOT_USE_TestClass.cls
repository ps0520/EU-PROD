@isTest
public class DONOT_USE_TestClass {
    /*
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
        
    }*/

 /* @isTest static void BPClsTest3(){
        //Insert 1 consumer account record
         List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'GB Consumer', 'United Kingdom');
         Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'GB Pharmacy', 'United Kingdom')[0];
         List<Account> UKpayorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'GB Payor', 'United Kingdom');
         //List<Account> prescribersWithMedFac = ClsTestDataFactory.createAccountsWithPrescriberToMedFacAssociation(2, 'United Kingdom');
        //Account prescriberAccnt = prescriberAccts[0];
        List<Account> prescribersWithMedFac = ClsTestDataFactory.createAccountsWithBillingAddress(5, 'GB Prescriber', 'United Kingdom');
        List<Account> medFacAccts = ClsTestDataFactory.createAccountsWithBillingAddress(5, 'GB Medical Facility', 'United Kingdom');
        List<Account> pahrmacyAcc = ClsTestDataFactory.createAccountsWithBillingAddress(5, 'GB Pharmacy', 'United Kingdom');
         
         payorAccount.Medical_Facility__c = medFacAccts[1].Id; 
         payorAccount.Prescriber__c = prescribersWithMedFac[0].Id;
         //consumerAccts[0].Payor__c =payorAccount.id;
         //consumerAccts[0].ParentId =medFacAccts[3].Id;
        // update consumerAccts;
        
         payorAccount.ParentId = pahrmacyAcc[0].Id;
         update payorAccount;
         //Account cnt = new Account();
       //cnt.ParentId
      Id RTIdAddDE =[Select Id From RecordType where sObjectType='Address__c' and isActive=true AND DeveloperName='UK_Address' Limit 1][0].Id; 
      List<Address__c> lstAddress = new List<Address__c>{
          new Address__c(Account__c = consumerAccts[0].Id,Type__c = 'Bill To', Country__c = 'United Kingdom',  City__c = 'Rosemont', Address_Line_1__c = 'gins Rd', Postal_Code__c = 'SY3 7FA', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE),
              new Address__c(Account__c = consumerAccts[0].Id,Type__c = 'Ship To',Country__c = 'United Kingdom',  City__c = 'Rosemont', Address_Line_1__c = 'Higgins Rd', Postal_Code__c = 'SY3 7FA', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE)
              };
                  insert lstAddress; 
      
      
      Related_Account__c relAcc = new Related_Account__c();
      relAcc.Parent_Account__c = payorAccount.Id;
      relAcc.Child_Account__c = pahrmacyAcc[0].Id; 
      //relAcc.Medical_Facility__c = medFacAccts[1].Id;
      //relAcc.Child_Account__c = medFacAccts[0].Id;
      
      insert relAcc;
      
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'GB Cash'});
        String customPricebookId = customPricebookMap.get('GB Cash');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'DEX-SHIP-01','FREIGHT CHARGE'});
        
        //Update the virtual sku productIdToPbeId
        Product2 virtualProd = [SELECT Id, Is_Virtual_Product__c FROM Product2 WHERE NAME = 'DEX-SHIP-01'];
        virtualProd.Is_Virtual_Product__c = true;
        update virtualProd;
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
        {
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        
        
        Fund__c Fd = new Fund__c();
        Fd.PO_Reference_Number__c ='87666787';
        Fd.Limit_Type__c ='Quantity';        
        Fd.Payor__c = payorAccount.Id;
        Fd.Amount_Limit__c = 100000;
        Fd.Auth_End_Date__c = Date.today().addDays(100);
        Fd.Auth_Start_Date__c = Date.today();
        Fd.Receiver_Qty_Limit__c = 100; 
        Fd.Sensor_Limit__c = 100; 
        Fd.Transmitter_Qty_Limit__c = 100 ;
        fd.Receiver_Qty_Used__c=50;
        fd.Transmitter_Qty_Used__c=10;
        
        insert Fd ; 
        Test.startTest();
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.CreateCPBEntries(productIdToPriceMap, customPricebookId, 'GBP');
        Id chOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('GB_Sales_Order').getRecordTypeId();
        UKpayorAccount[0].Price_Book__c = customPricebookId;   
        update UKpayorAccount ;
        
        //Create Order record
          ClsOrderTriggerStaticClass.isExecuting = false;
          Order newOrder = new Order();
          newOrder.AccountId = consumerAccts[0].Id;
          newOrder.RecordtypeId = chOrderRecdTypeId;
          newOrder.Type = 'GB STANDARD';
          newOrder.EffectiveDate = System.today();
          newOrder.Price_Book__c = customPricebookId;       
          newOrder.Status = 'Draft';
          //newOrder.Payor__c = UKpayorAccount[0].Id ;
          //newOrder.Fund__c = Fd.id;
         // newOrder.Payor_Bill_To_Address__c =lstAddress[0].Id;
          newOrder.Customer_Ship_To_Address__c = lstAddress[1].Id;
          newOrder.Customer_Bill_To_Address__c = lstAddress[0].Id;
          insert newOrder;
        
        newOrder.Pricebook2Id = customPricebookId;
        
        update newOrder;
        
        
        //List order line items
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values())
        {
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
        
        //Update tracking number information
        ClsOrderTriggerStaticClass.isExecuting = false;
        
		Test.stopTest();
       
    } */
    
    static testMethod void test() {
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCustomPricebook(new List<String>{'DE Netto-Preis Cash', 'DE Return Replace', 'Barmer'});
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'Product-01', 'Product-02', 'DEX-SHIP-01'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(Id productId : mapProduct.values()){
            productIdToPriceMap.put(productId, 10); 
        }
        Map<Id, Id> mapPBE = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, mapPriceBook.get('DE Netto-Preis Cash'));
        Account objAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Consumer', 'Germany')[0];
        objAccount.PersonEmail = 'test@gmail.com';
        objAccount.PersonHasOptedOutOfEmail = false;
        //objAccount.IsPersonAccount = true;
        update objAccount;
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Payor', 'Germany')[0];
        Account payorAccount2 = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Payor', 'Germany')[0];
        
        Id AddId=[Select Id from RecordType Where sObjectType='Address__c' AND Name='DE Address' Limit 1].Id;
        
        List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Account__c = objAccount.Id,RecordTypeId = AddId, Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true),
                                                            new Address__c(Account__c = objAccount.Id,RecordTypeId = AddId, Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true),
                                                            new Address__c(Account__c = payorAccount.Id,RecordTypeId = AddId, Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true),
                                                            new Address__c(Account__c = payorAccount.Id,RecordTypeId = AddId, Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true)
                                                          };
        insert lstAddress;
        Benefit__c primaryBenefit = new Benefit__c(Account__c = objAccount.Id, Member_Id__c = '1789657890', Payor__c = payorAccount.Id, Benefit_Hierarchy__c = 'Primary');
		insert primaryBenefit;
        Opportunity newOpp = new Opportunity(Name = 'New Opportunity For Testing', AccountId = objAccount.Id, Benefit__c = primaryBenefit.Id,Type = 'Reorder', Consumer_Email__c = 'test@gmail.com',
                                             Payor__c = payorAccount.Id, Pricebook2Id = mapPriceBook.get('Barmer'), CloseDate = Date.Today().addDays(30),
                                             Cash_Pay__c=true,Contact_Letter_Sent__c = true, Contact_Doc_Received__c = true, Insurance_Doc_Received__c = true, Hard_Copy_Out__c = true,
                                             Hard_Copy_In__c = true, Training_Letter_Sent__c = true, Training_Letter_Sent_Date__c = Date.Today(), StageName = 'New Opportunity');
        insert newOpp;
        
        insert new BP_Process_Builder_Customization__c(Name = 'DE_Sales_Order', PriceBook__c = mapPriceBook.get('DE Return Replace'));
       // Order objOrder = new Order(AccountId = objAccount.Id, EffectiveDate = Date.today(), Status = 'Draft', Type = 'DE TECH RETURN', Payor__c = payorAccount.Id);
       // insert objOrder;
       // objOrder.Payor_Bill_To_Address__c = lstAddress[2].Id;
      //  update objOrder;
        //objAccount.PersonEmail = 'MADMI@GMAIL.COM';
        //update objAccount;
        Test.startTest();
        Order objOrder1 = new Order(AccountId = objAccount.Id, EffectiveDate = Date.today(), Status = 'Draft', Type = 'DE STANDARD',  OpportunityId = newOpp.Id, CurrencyIsoCode = 'EUR'); //Price_Book__c = mapPriceBook.get('DE Netto-Preis Cash'), PriceBook2Id = mapPriceBook.get('DE Netto-Preis Cash'),
        //payorAccount2.Payor__c = payorAccount2.Id;
        //objOrder1.Status = 'OPEN';
        objOrder1.Email_Stage__c = 1;
        objOrder1.Delivery_Note_Received__c = false;
        objOrder1.Consumer_Email__c = null;
        objOrder1.Payor__c = payorAccount2.Id;
        insert objOrder1;
        //objOrder1.Payor__c = payorAccount.Id;
        //update objOrder1;
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        for(Id pbeId : mapPBE.values()){
            lstOrderItem.add(new OrderItem(PricebookEntryId = pbeId, OrderId = objOrder1.Id, Quantity = 1, UnitPrice = 10));
        }
        //insert lstOrderItem; 
        
       List<OrgWideEmailAddress> lstOWEA = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'de.info@dexcom.com' LIMIT 1];
        BPClsOrder.prepareEmailMessage(null,'test@gmail.com',objAccount.Id,objOrder1.Id,'Test Subject',lstOWEA[0].id);
        SDJob_Temp__c objTemp = new SDJob_Temp__c(Doclist__c = null, Sobject_Name__c = 'Order', Sobject_Id__c = objOrder1.Id, Create_SDJob__c = false);
        insert objTemp;
        objTemp.Create_SDJob__c = true;
        update objTemp;
        Test.stopTest();
	}
     
}