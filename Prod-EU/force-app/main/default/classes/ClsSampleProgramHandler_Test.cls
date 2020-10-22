@isTest
public class ClsSampleProgramHandler_Test {
    
    @isTest static void SamplePrgTest(){
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCustomPricebook(new List<String>{'DE No Charge'});
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'STS-GS-002', 'STT-GS-003'});
       Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
       for(Id productId : mapProduct.values()){
            productIdToPriceMap.put(productId, 10); 
        }
    	Map<Id, Id> mapPBE = ClsTestDataFactory.createCustomPricebookEntries(productIdToPriceMap, mapPriceBook.get('DE No Charge'));
        Account objAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Consumer', 'Germany')[0];
        String Sampletype= 'Stage 1';
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Payor', 'Germany')[0];
        Id AddId=[Select Id from RecordType Where sObjectType='Address__c' AND Name='DE Address' Limit 1].Id;
        
        List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Account__c = objAccount.Id,RecordTypeId = AddId, Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true),
                                                            new Address__c(Account__c = objAccount.Id,RecordTypeId = AddId, Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true),
                                                            new Address__c(Account__c = payorAccount.Id,RecordTypeId = AddId, Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true),
                                                            new Address__c(Account__c = payorAccount.Id,RecordTypeId = AddId, Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true)
                                                          };
        insert lstAddress;
        Test.startTest();
        ClsSampleProgramHandler.createOrder(objAccount.Id, SampleType, lstAddress[1].Id);
        ClsSampleProgramHandler.creteSampleOpportunity(objAccount.Id, SampleType);
        Test.stopTest();
    }
    
}