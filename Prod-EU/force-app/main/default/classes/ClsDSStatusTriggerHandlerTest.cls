@isTest
public class ClsDSStatusTriggerHandlerTest {
    @testSetup static void setup(){
        List<Account> accountsToBeUpdated = new List<Account>();
        List<Account> accts = new List<Account>();
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('DE Consumer').getRecordTypeId();
		Account a = new Account();
        a.CurrencyIsoCode = 'EUR';
        a.RecordTypeId = devRecordTypeId;
        a.FirstName='TestConsumerFirstName';
        a.LastName='TestConsumerLastName';
        a.BillingStreet = 'Grüner Weg';
        a.BillingCity = 'Friedberg';
        a.BillingPostalCode = '61169';
        a.BillingCountryCode = 'DE';
        a.PersonEmail = 'Tesdt@gmail.com';
        a.PersonHasOptedOutOfEmail = false;
        accts.add(a);                                                
       
        insert accts;  
        
        
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebook(new List <String>{'Barmer'});
        String customPricebookId = customPricebookMap.get('Barmer');
        accts[0].Price_Book__c = customPricebookId;
        accountsToBeUpdated.add(accts[0]);
        Update accountsToBeUpdated;    
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'STK-GF-013', 'STT-GF-004', 'DEX-SHIP-01'});
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet()){
            productIdToPriceMap.put(products.get(productName), 125.00);
            if(productName == 'DEX-SHIP-01'){
                ClsTestDataFactory.createProductSchedule (products.get(productName), products.get('STK-GF-013'), customPricebookId);
            }
            
        }
        
        
        //Create new Opportunity
        Id oppRecTypeGermany = [Select Id from RecordType Where isActive = true AND DeveloperName = 'DE_Opportunity'].id;
        Opportunity newOpp = new Opportunity();
        newOpp.RecordTypeId = oppRecTypeGermany;
        newOpp.Name = 'New Opportunity For Testing';
        newOpp.CurrencyIsoCode = 'EUR';
        newOpp.AccountId = accts[0].Id;
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
        newOpp.Training_Date__c = Date.today()+3;
        //newOpp.Doc_Collection_Status__c = 'Docs On File - Pending' ;        
        newOpp.Email_Stage__c = null ; 
        newOpp.DexTracker_Email__c = 'Yes';
        newOpp.Consumer_Email__c = 'Tesdt@gmail.com';       
        insert newOpp;
        
        
            
        dfsle__EnvelopeStatus__c objEnevp = new dfsle__EnvelopeStatus__c(); 
        objEnevp.dfsle__DocuSignId__c = '9796E97C-CC80-4DE6-9162-CF99205BB5C6';
        objEnevp.dfsle__EmailSubject__c = 'Dexcom Patient Information and Authorization Form - VAT Exemption Signature Needed Test:';
        objEnevp.dfsle__SenderEmail__c = 'Tesdt@gmail.com'; 
        objEnevp.dfsle__Status__c = 'Delivered';
        objEnevp.dfsle__SourceId__c = accts[0].Id ;
        objEnevp.Opportunity__c = newOpp.Id;
        insert objEnevp;
        
                                     
		 dfsle__EnvelopeStatus__c objEnevpPdf = new dfsle__EnvelopeStatus__c(); 
        objEnevpPdf.dfsle__DocuSignId__c = '9796E97C-CC80-4DE6-9162-CF99205BB5C8';
        objEnevpPdf.dfsle__EmailSubject__c = 'Please DocuSign: Green Shield CGM Authorization Form.pdf';
        objEnevpPdf.dfsle__SenderEmail__c = 'Tesdt@gmail.com'; 
        objEnevpPdf.dfsle__Status__c = 'Sent';
        objEnevpPdf.dfsle__SourceId__c = accts[0].Id ;
        objEnevpPdf.Opportunity__c = newOpp.Id;
        insert objEnevpPdf;        
        
    }
    
    @isTest
    public static void onafterUpdateTest(){
        Test.startTest();
        dfsle__EnvelopeStatus__c objEnevp =[select id,dfsle__Status__c,
                                            name from dfsle__EnvelopeStatus__c where dfsle__Status__c='Delivered'  ];
        
        objEnevp.dfsle__Status__c = 'Completed';
        update objEnevp;
        Test.stopTest();
        
    }
    @isTest
    public static void onafterUpdatePDFTest(){
        Test.startTest();
        dfsle__EnvelopeStatus__c objEnevp =[select id,dfsle__Status__c,dfsle__DocuSignId__c,
                                            name from dfsle__EnvelopeStatus__c 
                                            where dfsle__Status__c='Sent'];
        
        objEnevp.dfsle__Status__c = 'Delivered';
        update objEnevp;
        objEnevp.dfsle__Status__c = 'Completed';
        update objEnevp;
        Test.stopTest();
        
    }
    
}