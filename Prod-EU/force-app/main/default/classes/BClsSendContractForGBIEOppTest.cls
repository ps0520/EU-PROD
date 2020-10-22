/*
@Author        : Kumar Navneet
@Date Created    : 22/04/2020
@Description    : Test class for BClsSendContractForGBIEOpp Batch class 
****************************************************************************************/
@isTest()
private class BClsSendContractForGBIEOppTest {
    @isTest static void TestOrderCreation(){
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
        
     
        test.startTest();
        DataBase.executeBatch(new BClsSendContractForGBIEOpp(null),1);
        test.stopTest();
        
        
        
    }
}