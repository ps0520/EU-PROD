/****************************************************************************************************************
@Author        : Pradeep Sadasivan
@Date Created    : 04/09/2020
@Description    : Test class for AccountChangeEvent IQVIA requiremnet- NS-743                  - 
****************************************************************************************************************/@isTest
private class ClsAccountValRequestTriggerHandlerTest{
     @testSetup
     //create Test data
     private static void setup(){
     Account prescriberAccount = new Account(FirstName = 'Joe',
                                       LastName  = 'Prescriber',
                                       Gender__c =  'Male',
                                       ShippingStreet = 'Street1',
                                       ShippingCity ='Petersburger',
                                       ShippingPostalCode = '10247',
                                       ShippingState = 'Berlin',
                                       ShippingCountry = 'Germany',
                                       Prescriber_Id__c = '23333333',
                                       BillingStreet = 'Street1',
                                       BillingCity ='Petersburger',
                                       BillingPostalCode = '10247',
                                       BillingState = 'Berlin',
                                       BillingCountry = 'Germany',
                                       OK_Status__c = 'Valid',    
                                       RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('DE Prescriber').getRecordTypeId());
    insert prescriberAccount ;
    Account medicalFacilityAccount = new Account(Name  = 'Medical facility',
                                                 ShippingStreet = 'Street1',
                                                 ShippingCity ='Petersburger',
                                                 ShippingPostalCode = '10247',
                                                 ShippingState = 'Berlin',
                                                 ShippingCountry = 'Germany',
                                                 BillingStreet = 'Street1',
                                                 BillingCity ='Petersburger',
                                                 BillingPostalCode = '10247',
                                                 BillingState = 'Berlin',
                                                 BillingCountry = 'Germany',
                                                 RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('DE Medical Facility').getRecordTypeId());
    insert medicalFacilityAccount;
    Related_Account__c childAccount = new Related_Account__c(Parent_Account__c = medicalFacilityAccount.Id,
                                       Child_Account__c = prescriberAccount.Id
                                      );
    insert childAccount;
    Address__c  addressShip = new Address__c (Address_Line_1__c  = 'Line1',
                                       Address_Line_2__c = 'Line2',
                                       Address_Line_3__c =  'Line3',
                                       City__c= 'Petersburger',
                                       Country__c = 'Germany',
                                       Postal_Code__c = '10247',
                                       Type__c ='Ship To',
                                       RecordTypeID = '0120Y000000Arkq',
                                       Account__c = prescriberAccount.Id );
    insert addressShip;
    Address__c  addressBill = new Address__c (Address_Line_1__c  = 'Line1',
                                       Address_Line_2__c = 'Line2',
                                       Address_Line_3__c =  'Line3',
                                       City__c= 'Petersburger',
                                       Country__c = 'Germany',
                                       Postal_Code__c = '10247',
                                       Type__c ='Bill To',
                                       RecordTypeID = '0120Y000000Arkq',
                                       Account__c = prescriberAccount.Id);
    insert addressBill;
	}         
    @isTest
    //Update Activity Account
    Static void creativeActivityValidationRequestActivity(){
   	Account acc =  [SELECT Id,LastName FROM Account WHERE LastName = 'Prescriber' LIMIT 1];    
    Test.enableChangeDataCapture();
    acc.LastName ='Test change';
   	acc.ShippingPostalCode = '46236';
    Test.startTest();
    update acc;
    Test.stopTest();
    }
    //Update Workplace Account
    @isTest
    Static void creativeActivityValidationRequestWorkplace(){
    Test.enableChangeDataCapture();
    Account acc =  [SELECT Id,Name,ShippingPostalCode FROM Account WHERE Name = 'Medical facility' LIMIT 1];
    acc.Name ='Facility level2';
    acc.ShippingPostalCode = '46236';
    Test.startTest();
    update acc;
    Test.stopTest();
    }
     @isTest
    //Update Activity Account
    Static void inactivateAccount(){
   	Account acc =  [SELECT Id,LastName,OK_Status__c FROM Account WHERE LastName = 'Prescriber' LIMIT 1];    
    Test.enableChangeDataCapture();
    acc.OK_Status__c = 'Invalid';
    Test.startTest();
    update acc;
    Test.stopTest();
    }
}