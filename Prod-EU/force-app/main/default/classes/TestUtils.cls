/**
 * Test data creation methods for common sObjects
 * @author Kristen Anderson(Sundog)
 * @date 06/13/19
 */
public class TestUtils {
    
    public static Account testDEConsumerAccount(){
        return new Account(
            FirstName = 'Testfirstname',
            LastName = 'Testlastname',
            PersonEmail = 'Test@gmail.com',
            Phone = '123456789',
            BillingStreet = 'Test Street',
            BillingCity = 'Fargo',
            //BillingState = 'North Dakota',
            BillingCountry = 'Germany',
            BillingPostalCode = '12354',
            ShippingStreet = 'Test Street',
            ShippingCity = 'Fargo',
            //ShippingState = 'North Dakota',
            ShippingCountry = 'Germany',
            ShippingPostalCode = '12345',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'DE_Consumer' AND SObjectType = 'Account'].Id
        );
    }
    
    public static Lead testDEPersonLead(){
        return new Lead(
			FirstName = 'TestfirstName',
            LastName = 'TestlastName',
            Email = 'Test@gmail.com',
            Phone = '123456789',
            //State = 'North Dakota',
            City = 'Test City',
            Street = 'Test Street',
            PostalCode = '12345',
            Country = 'Germany',
            RecordTypeId = [SELECT Id 
            FROM RecordType 
            where DeveloperName = 'DE_Person_Lead' and SobjectType = 'Lead' limit 1].Id
        );
    }

    public static Account testCAConsumerAccount(){
        return new Account(
            FirstName = 'Testfirstname',
            LastName = 'Testlastname',
            PersonEmail = 'Test@gmail.com',
            Phone = '123456789',
            BillingStreet = 'Test Street',
            BillingCity = 'Fargo',
            BillingStateCode = 'AB',
            BillingCountry = 'Canada',
            BillingCountryCode = 'CA',
            BillingPostalCode = 'H0H 0H0',
            ShippingStreet = 'Test Street',
            ShippingCity = 'Fargo',
            ShippingStateCode = 'AB',
            ShippingCountry = 'Canada',
            ShippingCountryCode = 'CA',
            ShippingPostalCode = 'H0H 0H0',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CA_Consumer' AND SObjectType = 'Account'].Id
        );
    }
    
    public static Lead testCAPersonLead(){
        return new Lead(
			FirstName = 'TestfirstName',
            LastName = 'TestlastName',
            Email = 'Test@gmail.com',
            Phone = '123456789',
            //State = 'North Dakota',
            City = 'Test City',
            Street = 'Test Street',
            PostalCode = 'H0H 0H0',
            Country = 'Canada',
            RecordTypeId = [SELECT Id 
            FROM RecordType 
            where DeveloperName = 'CA_Person_Lead' and SobjectType = 'Lead' limit 1].Id
        );
    }
    
    
     public static Account testGBConsumerAccount(){
        return new Account(
            FirstName = 'Testfirstname',
            LastName = 'Testlastname',
            PersonEmail = 'Test@gmail.com',
            Phone = '123456789',
            BillingStreet = 'Test Street',
            BillingCity = 'Fargo',
            //BillingState = 'North Dakota',
            BillingCountry = 'United Kingdom',
            BillingPostalCode = 'H0H 0H0',
            ShippingStreet = 'Test Street',
            ShippingCity = 'Fargo',
            //ShippingState = 'North Dakota',
            ShippingCountry = 'United Kingdom',
            ShippingPostalCode = 'H0H 0H0',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'GB_Consumer' AND SObjectType = 'Account'].Id
        );
    }
    
    public static Lead testGBPersonLead(){
        return new Lead(
			FirstName = 'TestfirstName',
            LastName = 'TestlastName',
            Email = 'Test@gmail.com',
            Phone = '123456789',
            //State = 'North Dakota',
            City = 'Test City',
            Street = 'Test Street',
            PostalCode = 'H0H 0H0',
            Country = 'United Kingdom',
            RecordTypeId = [SELECT Id 
            FROM RecordType 
            where DeveloperName = 'GB_Person_Lead' and SobjectType = 'Lead' limit 1].Id
        );
    }
    
      public static Account testIEConsumerAccount(){
        return new Account(
            FirstName = 'Testfirstname',
            LastName = 'Testlastname',
            PersonEmail = 'Test@gmail.com',
            Phone = '123456789',
            BillingStreet = 'Test Street',
            BillingCity = 'Fargo',
            //BillingState = 'North Dakota',
            BillingCountry = 'Ireland',
            BillingPostalCode = 'H0H 0H0',
            ShippingStreet = 'Test Street',
            ShippingCity = 'Fargo',
            //ShippingState = 'North Dakota',
            ShippingCountry = 'Ireland',
            ShippingPostalCode = 'H0H 0H0',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'IE_Consumer' AND SObjectType = 'Account'].Id
        );
    }
    
    public static Lead testIEPersonLead(){
        return new Lead(
			FirstName = 'TestfirstName',
            LastName = 'TestlastName',
            Email = 'Test@gmail.com',
            Phone = '123456789',
            //State = 'North Dakota',
            City = 'Test City',
            Street = 'Test Street',
            PostalCode = 'H0H 0H0',
            Country = 'Ireland',
            RecordTypeId = [SELECT Id 
            FROM RecordType 
            where DeveloperName = 'IE_Person_Lead' and SobjectType = 'Lead' limit 1].Id
        );
    }
    
     public static Account testATConsumerAccount(){
        return new Account(
            FirstName = 'Testfirstname',
            LastName = 'Testlastname',
            PersonEmail = 'Test@gmail.com',
            Phone = '123456789',
            BillingStreet = 'Test Street',
            BillingCity = 'Fargo',
            //BillingState = 'North Dakota',
            BillingCountry = 'Austria',
            BillingPostalCode = 'H0H 0H0',
            ShippingStreet = 'Test Street',
            ShippingCity = 'Fargo',
            //ShippingState = 'North Dakota',
            ShippingCountry = 'Austria',
            ShippingPostalCode = 'H0H 0H0',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'AT_Consumer' AND SObjectType = 'Account'].Id
        );
    }
    
    public static Lead testATPersonLead(){
        return new Lead(
			FirstName = 'TestfirstName',
            LastName = 'TestlastName',
            Email = 'Test@gmail.com',
            Phone = '123456789',
            //State = 'North Dakota',
            City = 'Test City',
            Street = 'Test Street',
            PostalCode = 'H0H 0H0',
            Country = 'Austria',
            RecordTypeId = [SELECT Id 
            FROM RecordType 
            where DeveloperName = 'AT_Person_Lead' and SobjectType = 'Lead' limit 1].Id
        );
    }
    
      public static Account testCHConsumerAccount(){
        return new Account(
            FirstName = 'Testfirstname',
            LastName = 'Testlastname',
            PersonEmail = 'Test@gmail.com',
            Phone = '123456789',
            BillingStreet = 'Test Street',
            BillingCity = 'Fargo',
            //BillingState = 'North Dakota',
            BillingCountry = 'Switzerland',
            BillingPostalCode = '1234',
            ShippingStreet = 'Test Street',
            ShippingCity = 'Fargo',
            //ShippingState = 'North Dakota',
            ShippingCountry = 'Switzerland',
            ShippingPostalCode = '1234',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CH_Consumer' AND SObjectType = 'Account'].Id
        );
    }
    
    public static Lead testCHPersonLead(){
        return new Lead(
			FirstName = 'TestfirstName',
            LastName = 'TestlastName',
            Email = 'Test@gmail.com',
            Phone = '123456789',
            //State = 'North Dakota',
            City = 'Test City',
            Street = 'Test Street',
            PostalCode = '1234',
            Country = 'Switzerland',
            RecordTypeId = [SELECT Id 
            FROM RecordType 
            where DeveloperName = 'CH_Person_Lead' and SobjectType = 'Lead' limit 1].Id
        );
    }
}