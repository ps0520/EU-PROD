@isTest
public class PEClsHandleBatchOCEEvent_Test {
    
    @isTest
    public static void publishOCEEventNonAccExist(){
        
        
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCPB(new List<String>{'CAN No Charge'},'CAD');
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'STP-GS-113','STS-GS-008'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(Id productId : mapProduct.values()){
            productIdToPriceMap.put(productId, 10); 
        }
        Map<Id, Id> mapPBE = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, mapPriceBook.get('CAN No Charge'));
        Account objAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada')[0];
        //String Sampletype= 'Stage 1';
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Payor', 'Canada')[0];
        Id AddId=[Select Id from RecordType Where sObjectType='Address__c' AND Name='CA Address' Limit 1].Id;
        
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = objAccount.Id,RecordTypeId = AddId, Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = 'H0H 0H0', Primary_Flag__c = true),
                new Address__c(Account__c = objAccount.Id,RecordTypeId = AddId, Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = 'H0H 0H0', Primary_Flag__c = true),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = AddId, Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = 'H0H 0H0', Primary_Flag__c = true),
                new Address__c(Account__c = payorAccount.Id,RecordTypeId = AddId, Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = 'H0H 0H0', Primary_Flag__c = true)
                };
                    insert lstAddress;
        
        Sample_Order_Request_Event__e oce = new Sample_Order_Request_Event__e();
        oce.AccCountryCode__c = 'CA';
        oce.AccountType__c = 'Prescriber';
        oce.AccountOnekeyId__c = 'WDEM011910112';
        oce.AddressOneKeyId__c  = 'WDEE00030931WDE000000539PTTL';
        oce.AddressLine1__c = '420-210 Ave P S';
        oce.AddressLine2__c = '420';
        oce.AddressLine3__c = '';
        oce.OCEOrderReference__c = '1231242183';
        oce.ProgramType__c = 'CA Prescriber Sample';
        oce.BirthDate__c = System.today() - 4000;
        oce.CareOf_AddressFirstName__c = 'OCE';
        oce.CareOf_AddressLastName__c = 'Test';
        oce.Address_Phone_Number__c = '';
        oce.City__c = 'Saskatoon';
        oce.Email__c = 'oceEvntTest@dexcom9.invalid.com';
        oce.HomePhone__c = '1223412242';
        oce.LastName__c = 'OCE Sample';
        oce.FirstName__c = 'Account';
        oce.Mobile__c = '';
        oce.OtherPhone__c = '';
        oce.PostalCode__c = 'S7M 2W2';
        oce.Preferred_Language__c = 'en';
        oce.StateProvince__c = 'Alberta';
        oce.WorkPhone__c = '';
        oce.Quantity__c = 0;
        Test.startTest();
        Database.SaveResult svrs = EventBus.publish(oce);
        // ClsSampleProgramHandler.creteSampleOpportunity(objAccount.Id, '');
        Test.stopTest();
        System.debug('svrs--'+svrs);
    }
    @isTest
    public static void publishOCEEventAccExist(){
        
        
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCPB(new List<String>{'CAN No Charge'},'CAD');
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'STP-GS-113','STS-GS-008'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(Id productId : mapProduct.values()){
            productIdToPriceMap.put(productId, 10); 
        }
        Map<Id, Id> mapPBE = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, mapPriceBook.get('CAN No Charge'));
        Id accRectype=[Select Id from RecordType Where sObjectType='Account' AND Name='CA Consumer' Limit 1].Id;
        
        Account objAccount = new Account();
        objAccount.RecordTypeId = accRectype;
        objAccount.LastName ='LastName';
        objAccount.FirstName = 'OCE';
        objAccount.IQVIA_OneKeyId__c = 'WDEM011910112';
        objAccount.CurrencyIsoCode = 'CAD';
        insert objAccount;
        //Account objAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada')[0];
        //objAccount.IQVIA_OneKeyId__c = 'WDEM011910112';
        //update objAccount;
        //String Sampletype= 'Stage 1';
        //Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Payor', 'Canada')[0];
        Id AddId=[Select Id from RecordType Where sObjectType='Address__c' AND Name='CA Address' Limit 1].Id;
        
        List<Address__c> lstAddress = new List<Address__c>{
            // new Address__c(Account__c = objAccount.Id,RecordTypeId = AddId, Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = 'H0H 0H0', Primary_Flag__c = true),
            new Address__c(Account__c = objAccount.Id,IQVIA_OneKeyId__c = 'WDEE00030931WDE000000539PTTL',RecordTypeId = AddId, Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = 'H0H 0H0', Primary_Flag__c = true)
                //new Address__c(Account__c = payorAccount.Id,RecordTypeId = AddId, Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = 'H0H 0H0', Primary_Flag__c = true),
                // new Address__c(Account__c = payorAccount.Id,RecordTypeId = AddId, Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = 'H0H 0H0', Primary_Flag__c = true)
                };
                    insert lstAddress;
        
        List<PricebookEntry> lstPBE = [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2.Name = 'CAN No Charge'];
        
        Sample_Order_Request_Event__e oce = new Sample_Order_Request_Event__e();
        oce.AccCountryCode__c = 'CA';
        oce.AccountType__c = 'Prescriber';
        oce.AccountOnekeyId__c = 'WDEM011910112';
        oce.AddressOneKeyId__c  = 'WDEE00030931WDE000000539PTTL';
        oce.AddressLine1__c = '420-210 Ave P S';
        oce.AddressLine2__c = '420';
        oce.AddressLine3__c = '';
        oce.OCEOrderReference__c = '1231242183';
        oce.ProgramType__c = 'CA Prescriber Sample';
        oce.BirthDate__c = System.today() - 4000;
        oce.CareOf_AddressFirstName__c = 'OCE';
        oce.CareOf_AddressLastName__c = 'Test';
        oce.Address_Phone_Number__c = '';
        oce.City__c = 'Saskatoon';
        oce.Email__c = 'oceEvntTest@dexcom9.invalid.com';
        oce.HomePhone__c = '1223412242';
        oce.LastName__c = 'OCE Sample';
        oce.FirstName__c = 'Account';
        oce.Mobile__c = '';
        oce.OtherPhone__c = '';
        oce.PostalCode__c = 'S7M 2W2';
        oce.Preferred_Language__c = 'en';
        oce.StateProvince__c = 'Alberta';
        oce.WorkPhone__c = '';
        oce.Quantity__c = 0;
        Test.startTest();
        Database.SaveResult svrs = EventBus.publish(oce);
        // ClsSampleProgramHandler.creteSampleOpportunity(objAccount.Id, '');
        Test.stopTest();
        System.debug('svrs--'+svrs);
    }
    @isTest
    public static void publishOCEEventException_OCEOrderRef(){
        
        
        Map<String, String> mapPriceBook = ClsTestDataFactory.createCPB(new List<String>{'CAN No Charge'},'CAD');
        Map<String, Id> mapProduct = ClsTestDataFactory.createProducts(new List<String>{'STP-GS-113','STS-GS-008'});
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(Id productId : mapProduct.values()){
            productIdToPriceMap.put(productId, 10); 
        }
        Map<Id, Id> mapPBE = ClsTestDataFactory.createCustomPricebookEntriesCA(productIdToPriceMap, mapPriceBook.get('CAN No Charge'));
        Account objAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Consumer', 'Canada')[0];
        objAccount.IQVIA_OneKeyId__c = 'WDEM011910112';
        update objAccount;
        //String Sampletype= 'Stage 1';
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'CA Payor', 'Canada')[0];
        Id AddId=[Select Id from RecordType Where sObjectType='Address__c' AND Name='CA Address' Limit 1].Id;
        
        List<Address__c> lstAddress = new List<Address__c>{
            new Address__c(Account__c = objAccount.Id,IQVIA_OneKeyId__c = 'WDEE00030931WDE000000539PTTL',RecordTypeId = AddId, Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = 'H0H 0H0', Primary_Flag__c = true)
                //new Address__c(Account__c = objAccount.Id,IQVIA_OneKeyId__c = 'WDEE00030931WDE000000539PTTL',RecordTypeId = AddId, Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = 'H0H 0H0', Primary_Flag__c = true),
                //new Address__c(Account__c = payorAccount.Id,RecordTypeId = AddId, Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = 'H0H 0H0', Primary_Flag__c = true),
                //new Address__c(Account__c = payorAccount.Id,RecordTypeId = AddId, Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = 'H0H 0H0', Primary_Flag__c = true)
                };
                    //  insert lstAddress;
                    
                    
                    
                    Sample_Order_Request_Event__e oce = new Sample_Order_Request_Event__e();
        oce.AccCountryCode__c = 'CA';
        oce.AccountType__c = 'Prescriber';
        oce.AccountOnekeyId__c = 'WDEM011910112';
        oce.AddressOneKeyId__c  = 'WDEE00030931WDE000000539PTTL';
        oce.AddressLine1__c = '420-210 Ave P S';
        oce.AddressLine2__c = '420';
        oce.AddressLine3__c = '';
        oce.OCEOrderReference__c = '';
        oce.ProgramType__c = 'CA Prescriber Sample';
        oce.BirthDate__c = System.today() - 4000;
        oce.CareOf_AddressFirstName__c = 'OCE';
        oce.CareOf_AddressLastName__c = 'Test';
        oce.Address_Phone_Number__c = '';
        oce.City__c = 'Saskatoon';
        oce.Email__c = 'oceEvntTest@dexcom9.invalid.com';
        oce.HomePhone__c = '1223412242';
        oce.LastName__c = 'OCE Sample';
        oce.FirstName__c = 'Account';
        oce.Mobile__c = '';
        oce.OtherPhone__c = '';
        oce.PostalCode__c = 'S7M 2W2';
        oce.Preferred_Language__c = 'en';
        oce.StateProvince__c = 'Alberta';
        oce.WorkPhone__c = '';
        oce.Quantity__c = 0;
        Test.startTest();
        Database.SaveResult svrs = EventBus.publish(oce);
        
        Test.stopTest();
        System.debug('svrs--'+svrs);
    }
    
    @isTest
    public static void OCEEventNonAccExist_ADDRESS(){
        
        
        Sample_Order_Request_Event__e oce = new Sample_Order_Request_Event__e();
        oce.AccCountryCode__c = 'CA';
        oce.AccountType__c = 'Prescriber';
        oce.AccountOnekeyId__c = 'WDEM011910112';
        oce.AddressOneKeyId__c  = 'WDEE00030931WDE000000539PTTL';
        oce.AddressLine1__c = '';
        oce.AddressLine2__c = '420';
        oce.AddressLine3__c = '';
        oce.OCEOrderReference__c = '1231242183';
        oce.ProgramType__c = 'CA Prescriber Sample';
        oce.BirthDate__c = System.today() - 4000;
        oce.CareOf_AddressFirstName__c = 'OCE';
        oce.CareOf_AddressLastName__c = 'Test';
        oce.Address_Phone_Number__c = '';
        oce.City__c = 'Saskatoon';
        oce.Email__c = 'oceEvntTest@dexcom9.invalid.com';
        oce.HomePhone__c = '1223412242';
        oce.LastName__c = 'OCE Sample';
        oce.FirstName__c = 'Account';
        oce.Mobile__c = '';
        oce.OtherPhone__c = '';
        oce.PostalCode__c = 'S7M 2W2';
        oce.Preferred_Language__c = 'en';
        oce.StateProvince__c = 'Alberta';
        oce.WorkPhone__c = '';
        oce.Quantity__c = 0;
        Test.startTest();
        Database.SaveResult svrs = EventBus.publish(oce);
        // ClsSampleProgramHandler.creteSampleOpportunity(objAccount.Id, '');
        Test.stopTest();
        System.debug('svrs--'+svrs);
    }
    @isTest
    public static void OCEEventNonAccExist_POSTALCODE(){
        
        
        Sample_Order_Request_Event__e oce = new Sample_Order_Request_Event__e();
        oce.AccCountryCode__c = 'CA';
        oce.AccountType__c = 'Prescriber';
        oce.AccountOnekeyId__c = 'WDEM011910112';
        oce.AddressOneKeyId__c  = 'WDEE00030931WDE000000539PTTL';
        oce.AddressLine1__c = '420-210 Ave P S';
        oce.AddressLine2__c = '420';
        oce.AddressLine3__c = '';
        oce.OCEOrderReference__c = '1231242183';
        oce.ProgramType__c = 'CA Prescriber Sample';
        oce.BirthDate__c = System.today() - 4000;
        oce.CareOf_AddressFirstName__c = 'OCE';
        oce.CareOf_AddressLastName__c = 'Test';
        oce.Address_Phone_Number__c = '';
        oce.City__c = 'Saskatoon';
        oce.Email__c = 'oceEvntTest@dexcom9.invalid.com';
        oce.HomePhone__c = '1223412242';
        oce.LastName__c = 'OCE Sample';
        oce.FirstName__c = 'Account';
        oce.Mobile__c = '';
        oce.OtherPhone__c = '';
        oce.PostalCode__c = '';
        oce.Preferred_Language__c = 'en';
        oce.StateProvince__c = 'Alberta';
        oce.WorkPhone__c = '';
        oce.Quantity__c = 0;
        Test.startTest();
        Database.SaveResult svrs = EventBus.publish(oce);
        // ClsSampleProgramHandler.creteSampleOpportunity(objAccount.Id, '');
        Test.stopTest();
        System.debug('svrs--'+svrs);
    }
    @isTest
    public static void OCEEventNonAccExist_CITY(){
        
        Sample_Order_Request_Event__e oce = new Sample_Order_Request_Event__e();
        oce.AccCountryCode__c = 'CA';
        oce.AccountType__c = 'Prescriber';
        oce.AccountOnekeyId__c = 'WDEM011910112';
        oce.AddressOneKeyId__c  = 'WDEE00030931WDE000000539PTTL';
        oce.AddressLine1__c = '420-210 Ave P S';
        oce.AddressLine2__c = '420';
        oce.AddressLine3__c = '';
        oce.OCEOrderReference__c = '1231242183';
        oce.ProgramType__c = 'CA Prescriber Sample';
        oce.BirthDate__c = System.today() - 4000;
        oce.CareOf_AddressFirstName__c = 'OCE';
        oce.CareOf_AddressLastName__c = 'Test';
        oce.Address_Phone_Number__c = '';
        oce.City__c = '';
        oce.Email__c = 'oceEvntTest@dexcom9.invalid.com';
        oce.HomePhone__c = '1223412242';
        oce.LastName__c = 'OCE Sample';
        oce.FirstName__c = 'Account';
        oce.Mobile__c = '';
        oce.OtherPhone__c = '';
        oce.PostalCode__c = 'S7M 2W2';
        oce.Preferred_Language__c = 'en';
        oce.StateProvince__c = 'Alberta';
        oce.WorkPhone__c = '';
        oce.Quantity__c = 0;
        Test.startTest();
        Database.SaveResult svrs = EventBus.publish(oce);
        // ClsSampleProgramHandler.creteSampleOpportunity(objAccount.Id, '');
        Test.stopTest();
        System.debug('svrs--'+svrs);
    }
    @isTest
    public static void OCEEventNonAccExist_STATE(){
        
        Sample_Order_Request_Event__e oce = new Sample_Order_Request_Event__e();
        oce.AccCountryCode__c = 'CA';
        oce.AccountType__c = 'Prescriber';
        oce.AccountOnekeyId__c = 'WDEM011910112';
        oce.AddressOneKeyId__c  = 'WDEE00030931WDE000000539PTTL';
        oce.AddressLine1__c = '420-210 Ave P S';
        oce.AddressLine2__c = '420';
        oce.AddressLine3__c = '';
        oce.OCEOrderReference__c = '1231242183';
        oce.ProgramType__c = 'CA Prescriber Sample';
        oce.BirthDate__c = System.today() - 4000;
        oce.CareOf_AddressFirstName__c = 'OCE';
        oce.CareOf_AddressLastName__c = 'Test';
        oce.Address_Phone_Number__c = '';
        oce.City__c = 'Saskatoon';
        oce.Email__c = 'oceEvntTest@dexcom9.invalid.com';
        oce.HomePhone__c = '1223412242';
        oce.LastName__c = 'OCE Sample';
        oce.FirstName__c = 'Account';
        oce.Mobile__c = '';
        oce.OtherPhone__c = '';
        oce.PostalCode__c = 'S7M 2W2';
        oce.Preferred_Language__c = 'en';
        oce.StateProvince__c = '';
        oce.WorkPhone__c = '';
        oce.Quantity__c = 0;
        Test.startTest();
        Database.SaveResult svrs = EventBus.publish(oce);
        // ClsSampleProgramHandler.creteSampleOpportunity(objAccount.Id, '');
        Test.stopTest();
        System.debug('svrs--'+svrs);
    }
    @isTest
    public static void OCEEventNonAccExist_ACCOUNTKEY(){
        
        Sample_Order_Request_Event__e oce = new Sample_Order_Request_Event__e();
        oce.AccCountryCode__c = '';
        oce.AccountType__c = 'Prescriber';
        oce.AccountOnekeyId__c = 'WDEM011910112';
        oce.AddressOneKeyId__c  = 'WDEE00030931WDE000000539PTTL';
        oce.AddressLine1__c = '420-210 Ave P S';
        oce.AddressLine2__c = '420';
        oce.AddressLine3__c = '';
        oce.OCEOrderReference__c = '1231242183';
        oce.ProgramType__c = 'CA Prescriber Sample';
        oce.BirthDate__c = System.today() - 4000;
        oce.CareOf_AddressFirstName__c = 'OCE';
        oce.CareOf_AddressLastName__c = 'Test';
        oce.Address_Phone_Number__c = '';
        oce.City__c = 'Saskatoon';
        oce.Email__c = 'oceEvntTest@dexcom9.invalid.com';
        oce.HomePhone__c = '1223412242';
        oce.LastName__c = 'OCE Sample';
        oce.FirstName__c = 'Account';
        oce.Mobile__c = '';
        oce.OtherPhone__c = '';
        oce.PostalCode__c = 'S7M 2W2';
        oce.Preferred_Language__c = 'en';
        oce.StateProvince__c = 'Alberta';
        oce.WorkPhone__c = '';
        oce.Quantity__c = 0;
        Test.startTest();
        Database.SaveResult svrs = EventBus.publish(oce);
        // ClsSampleProgramHandler.creteSampleOpportunity(objAccount.Id, '');
        Test.stopTest();
        System.debug('svrs--'+svrs);
    }
    @isTest
    public static void OCEEventNonAccExist_ACCLASTNAME(){
        
        Sample_Order_Request_Event__e oce = new Sample_Order_Request_Event__e();
        oce.AccCountryCode__c = 'CA';
        oce.AccountType__c = 'Prescriber';
        oce.AccountOnekeyId__c = 'WDEM011910112';
        oce.AddressOneKeyId__c  = 'WDEE00030931WDE000000539PTTL';
        oce.AddressLine1__c = '420-210 Ave P S';
        oce.AddressLine2__c = '420';
        oce.AddressLine3__c = '';
        oce.OCEOrderReference__c = '1231242183';
        oce.ProgramType__c = 'CA Prescriber Sample';
        oce.BirthDate__c = System.today() - 4000;
        oce.CareOf_AddressFirstName__c = 'OCE';
        oce.CareOf_AddressLastName__c = 'Test';
        oce.Address_Phone_Number__c = '';
        oce.City__c = 'Saskatoon';
        oce.Email__c = 'oceEvntTest@dexcom9.invalid.com';
        oce.HomePhone__c = '1223412242';
        oce.LastName__c = '';
        oce.FirstName__c = 'Account';
        oce.Mobile__c = '';
        oce.OtherPhone__c = '';
        oce.PostalCode__c = 'S7M 2W2';
        oce.Preferred_Language__c = 'en';
        oce.StateProvince__c = 'Alberta';
        oce.WorkPhone__c = '';
        oce.Quantity__c = 0;
        Test.startTest();
        Database.SaveResult svrs = EventBus.publish(oce);
        // ClsSampleProgramHandler.creteSampleOpportunity(objAccount.Id, '');
        Test.stopTest();
        System.debug('svrs--'+svrs);
    }
    @isTest
    public static void OCEEventNonAccExist_ACCFIRSTNAME(){
        Sample_Order_Request_Event__e oce = new Sample_Order_Request_Event__e();
        oce.AccCountryCode__c = 'CA';
        oce.AccountType__c = 'Prescriber';
        oce.AccountOnekeyId__c = 'WDEM011910112';
        oce.AddressOneKeyId__c  = 'WDEE00030931WDE000000539PTTL';
        oce.AddressLine1__c = '420-210 Ave P S';
        oce.AddressLine2__c = '420';
        oce.AddressLine3__c = '';
        oce.OCEOrderReference__c = '1231242183';
        oce.ProgramType__c = 'CA Prescriber Sample';
        oce.BirthDate__c = System.today() - 4000;
        oce.CareOf_AddressFirstName__c = 'OCE';
        oce.CareOf_AddressLastName__c = 'Test';
        oce.Address_Phone_Number__c = '';
        oce.City__c = 'Saskatoon';
        oce.Email__c = 'oceEvntTest@dexcom9.invalid.com';
        oce.HomePhone__c = '1223412242';
        oce.LastName__c = 'Account';
        oce.FirstName__c = '';
        oce.Mobile__c = '';
        oce.OtherPhone__c = '';
        oce.PostalCode__c = 'S7M 2W2';
        oce.Preferred_Language__c = 'en';
        oce.StateProvince__c = 'Alberta';
        oce.WorkPhone__c = '';
        oce.Quantity__c = 0;
        Test.startTest();
        Database.SaveResult svrs = EventBus.publish(oce);
        // ClsSampleProgramHandler.creteSampleOpportunity(objAccount.Id, '');
        Test.stopTest();
        System.debug('svrs--'+svrs);
    }
    
    @isTest
    public static void OCE_OUTEvent(){
        
        Sample_Order_Request_Event__e oce = new Sample_Order_Request_Event__e();
        
        Sample_Order_Response_Event__e oceOut = new Sample_Order_Response_Event__e();
        oceOut.OrderStatus__c ='Created';
        oceOut.OCEOrderReference__c ='a01wewewewedgwer';
        //oceOut.IntegrationErrorMessage__c ='';
        //oceOut.IntegrationStatus__c = '';
        oceOut.OrderNumber__c = '1223213141';
        ClsTestSampleOrderMockService mocksample = new ClsTestSampleOrderMockService('OK');
        Test.setMock(HttpCalloutMock.class, mocksample);  
        
        Test.startTest();
        Database.SaveResult svrs = EventBus.publish(oceOut);
        // ClsSampleProgramHandler.creteSampleOpportunity(objAccount.Id, '');
        Test.stopTest();
        System.debug('svrs--'+svrs);
    }
    @isTest
    public static void OCE_OUTEvent_302(){        
        Sample_Order_Request_Event__e oce = new Sample_Order_Request_Event__e();        
        Sample_Order_Response_Event__e oceOut = new Sample_Order_Response_Event__e();
        oceOut.OrderStatus__c ='Created';
        oceOut.OCEOrderReference__c ='a01wewewewedgwer';
        //oceOut.IntegrationErrorMessage__c ='';
        //oceOut.IntegrationStatus__c = '';
        oceOut.OrderNumber__c = '1223213141';
        ClsTestSampleOrderMockService mocksample = new ClsTestSampleOrderMockService();
        Test.setMock(HttpCalloutMock.class, mocksample);  
        
        Test.startTest();
        Database.SaveResult svrs = EventBus.publish(oceOut);
        // ClsSampleProgramHandler.creteSampleOpportunity(objAccount.Id, '');
        Test.stopTest();
        System.debug('svrs--'+svrs);
    }
}