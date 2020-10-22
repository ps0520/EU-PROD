@isTest public class ClsFinanceDetailsConTest {
    @testSetup static void setup() {
                
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCustomPricebook(new List<String>{'DE Netto-Preis Cash'});
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'Product-01', 'DEX-SHIP-01', 'Product-03'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>{mapProduct.values()[0] => 10, mapProduct.values()[1] => 10, mapProduct.values()[2] => 10 };
        Map<Id, Id> mapPBE = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, mapPriceBook.get('DE Netto-Preis Cash'));
        Account objAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Consumer', 'Germany')[0];
        Id RTIdAddDE =[Select Id From RecordType where sObjectType='Address__c' and isActive=true AND DeveloperName='DE_Address' Limit 1][0].Id;        
        
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = objAccount.Id,Type__c = 'Bill To', Country__c = 'Germany', State__c='Hamburg', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE),
            new Address__c(Account__c = objAccount.Id,Type__c = 'Ship To',Country__c = 'Germany', State__c='Hamburg', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg', RecordTypeId=RTIdAddDE)
        };
        insert lstAddress;
        Finance_Detail__c fd1= new Finance_Detail__c(Account__c=objAccount.Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='GBP', Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=lstAddress[0].id);
        insert fd1;
        
        Id orderRTId=[Select Id from RecordType Where sObjectType='Order' AND RecordType.DeveloperName='DE_Sales_Order' Limit 1].Id;        
        List<PricebookEntry> lstPBE = [SELECT Id, Pricebook2Id FROM PricebookEntry WHERE Pricebook2.Name = 'DE Netto-Preis Cash'];
        Order objOrder = new Order(AccountId = objAccount.Id, EffectiveDate = Date.today(),Type = 'CH STANDARD', Status = 'Draft', Finance_Detail__c = fd1.Id, RecordTypeId=orderRTId, Pricebook2Id = lstPBE[0].Pricebook2Id);
        insert objOrder;
    }
    
    @isTest static void TestgetAccName(){        
        Account a =[Select Id, Name, LastName  from Account Limit 1][0];
        System.Debug('*** TPS:EH  a=' + a.id);
        Order o=[Select Id, OrderNumber, AccountId,EffectiveDate, Status,type, Finance_Detail__c from Order Where AccountId=:a.Id Limit 1][0];
        System.Debug('***** TPS:EH o=' + o);
        ClsFinanceDetailsCon.getAccName(o.Id);        
        ClsFinanceDetailsCon.getCCData(a.Id);
        ClsFinanceDetailsCon.getCCData(o.Id);
        //ClsFinanceDetailsCon.AddIbanNum('xx',a.Id); 
        //ClsFinanceDetailsCon.getIBanData(a.Id); ClsFinanceDetailsCon.getIBanData('xx');
        ClsFinanceDetailsCon.getVATData(a.Id); ClsFinanceDetailsCon.getVATData('xx');        
        ClsFinanceDetailsCon.getAccBTAddr(o.Id);
        
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGenVATNumCheck());
            ClsFinanceDetailsCon.ValidateVATNum('12345',a.Id);
        Test.stopTest();        
    }
    
    @isTest static void TestgetCCNumberToken(){
        Finance_Detail__c fd1=[Select Id,Account__c,Token__c,Card_Type__c, CC_CUR__c, Expiry_Date__c, Primary__c, CC_Address__c from Finance_Detail__c Limit 1][0];
        Finance_Detail__c fd2=fd1.clone();
        
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGenCCNumToken());
            ClsFinanceDetailsCon.getCCNumberToken(fd2,'1111');
        Test.stopTest();
        fd1.Primary__c=false; update fd1;
        fd1.Primary__c=true; update fd1;
    }
      @isTest static void TestgetCCNumberToken2(){
        Account objAccount=[select id from account limit 1];
        List<Address__c> lstAddress=[select id from Address__c];
        Finance_Detail__c fd1= new Finance_Detail__c(Account__c=objAccount.Id,Token__c='1111', Card_Type__c='Mastercard',CC_CUR__c='GBP', Expiry_Date__c='1112/21', Primary__c=true, CC_Address__c=lstAddress[0].id);
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ClsMockHttpResponseGenCCNumToken());
            ClsFinanceDetailsCon.getCCNumberToken(fd1,'1111');
        Test.stopTest();
      
       
    }
}