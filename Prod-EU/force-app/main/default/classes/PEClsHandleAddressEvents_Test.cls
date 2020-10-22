@isTest
public class PEClsHandleAddressEvents_Test {

    @isTest static void sfdcAddressCreateAndUpdate() {
        id recId = [Select id from recordType where DeveloperName = 'CA_Consumer' AND isActive = true].id;
        id caAddRecId = [Select id from recordType where DeveloperName = 'CA_Address' AND isActive = true].id;
        Account a = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId);
        
        insert a;
        
        Address__c add = new Address__c(Account__c = a.id, Address_Line_1__c = '7511 Lucas Rd', city__c = 'Richmond', Country__c = 'Canada', RecordTypeId = caAddRecId,
                                       State__C = 'British Columbia', Postal_Code__c = 'V6Y 1G1', Type__c = 'Bill To', Primary_Flag__c = true);
        
        insert add;
        //This should automatically publish an address and should exercise the publishing code
        
        Address__c addUpd = new Address__c(id = add.id, Primary_Flag__c = false);
        
        update addUpd;
    }
    
    @isTest static void sfccCreateAddress() {
        id recId = [Select id from recordType where DeveloperName = 'CA_Consumer' AND isActive = true].id;
        id caAddRecId = [Select id from recordType where DeveloperName = 'CA_Address' AND isActive = true].id;
        Account a = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId);
        
        insert a;
        
         CRM_Address_Event__e  inkEvent = new CRM_Address_Event__e(version__c = '1.0',   eventDate__c = String.valueOf(System.now()), entityType__c = 'address', eventSource__c = 'ts', eventSourceID__c = 'MN-123', 
                                 operation__c = 'create', stage__c = 'pending', systemOfOrigin__c = 'ts', systemOfOriginID__c = 'MN-123', parentSystemOfOriginID__c = null, 
                                                                   accountID__c=a.id, addressID__c = null, isActive__c = true, isLocked__c = false, addressType__c = 'shipping', address1__c = '2322 Main St.',
                                                                  city__c = 'San Diego', stateProvince__c = 'CA', postalCode__c = '92121', country__c ='CA'); 
        
        Test.startTest();
        
        // Publish test event
        Database.SaveResult sr = EventBus.publish(inkEvent);
            
        Test.stopTest();
    }
    
     @isTest static void sfccCreateAddress_v1() {       
        
        Id recId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('CA_Consumer').getRecordTypeId();
         Id caAddRecId = SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        Account acc = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId);
        
        insert acc;
         
         List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Account__c = acc.Id,RecordTypeId=caAddRecId,SOS_Unique_ID__c='tsMN-1233',Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = acc.Id,RecordTypeId=caAddRecId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                                                          };
        insert lstAddress;
        
         
         
        CRM_Address_Event__e  inkEvent = new CRM_Address_Event__e(version__c = '1.0',   eventDate__c = String.valueOf(System.now()), entityType__c = 'address', eventSource__c = 'ts', eventSourceID__c = 'MN-123', 
                                 operation__c = 'create', stage__c = 'pending', systemOfOrigin__c = 'ts', systemOfOriginID__c = 'MN-123', parentSystemOfOriginID__c = 'testt', 
                                                                   accountID__c=acc.Id, addressID__c = lstAddress[0].Id, isActive__c = true, isLocked__c = false, addressType__c = 'shipping', address1__c = '2322 Main St.',
                                                                  city__c = 'San Diego', stateProvince__c = 'CA', postalCode__c = '92121', countryCode__c ='CA'); 
        
        Test.startTest();        
        // Publish test event
        Database.SaveResult sr = EventBus.publish(inkEvent);            
        Test.stopTest();
    }
    @isTest static void sfccCreateAddress_Exception() {
        
        Id recId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('CA_Consumer').getRecordTypeId();
         Id caAddRecId = SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        Account acc = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId);
        
        insert acc;
         
         List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Account__c = acc.Id,RecordTypeId=caAddRecId,SOS_Unique_ID__c='tsMN-1233',Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = acc.Id,RecordTypeId=caAddRecId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                                                          };
        insert lstAddress;
        
         
         
        CRM_Address_Event__e  inkEvent = new CRM_Address_Event__e(version__c = '1.0',   eventDate__c = String.valueOf(System.now()), entityType__c = 'address', eventSource__c = 'ts', eventSourceID__c = 'MN-123', 
                                 operation__c = 'create', stage__c = 'pending', systemOfOrigin__c = 'ts', systemOfOriginID__c = 'MN-123', parentSystemOfOriginID__c = 'null', 
                                                                   accountID__c='', addressID__c = lstAddress[0].Id, isActive__c = true, isLocked__c = false, addressType__c = 'shipping', address1__c = '2322 Main St.',
                                                                  city__c = 'San Diego', stateProvince__c = 'CA', postalCode__c = '92121', countryCode__c ='CA'); 
        
        Test.startTest();        
        // Publish test event
        Database.SaveResult sr = EventBus.publish(inkEvent);            
        Test.stopTest();
    }
     @isTest static void sfccCreateAddress_ExceptionV1() {
        
        Id recId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('CA_Consumer').getRecordTypeId();
         Id caAddRecId = SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        Account acc = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId);
        
        insert acc;
         
         List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Account__c = acc.Id,RecordTypeId=caAddRecId,SOS_Unique_ID__c='tsMN-123',Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = acc.Id,RecordTypeId=caAddRecId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                                                          };
        insert lstAddress;
        
         
         
        CRM_Address_Event__e  inkEvent = new CRM_Address_Event__e(version__c = '1.0',   eventDate__c = String.valueOf(System.now()), entityType__c = 'address', eventSource__c = 'ts', eventSourceID__c = 'MN-123', 
                                 operation__c = 'create', stage__c = 'pending', systemOfOrigin__c = 'ts', systemOfOriginID__c = 'MN-123', parentSystemOfOriginID__c = 'tesgssv', 
                                                                   accountID__c=acc.Id, addressID__c = lstAddress[0].Id, isActive__c = true, isLocked__c = false, addressType__c = 'shipping', address1__c = '2322 Main St.',
                                                                  city__c = 'San Diego', stateProvince__c = 'CA', postalCode__c = '92121', countryCode__c ='CA'); 
        
        Test.startTest();        
        // Publish test event
        Database.SaveResult sr = EventBus.publish(inkEvent);            
        Test.stopTest();
    }
    @isTest static void sfccCreateAddress_v2() {       
        
        Id recId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('CA_Consumer').getRecordTypeId();
         Id caAddRecId = SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        Account acc = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId);
        
        insert acc;
         
         List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Account__c = acc.Id,RecordTypeId=caAddRecId,SOS_Unique_ID__c='tsMN-1233',Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = acc.Id,RecordTypeId=caAddRecId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                                                          };
        insert lstAddress;
        
         
         
        CRM_Address_Event__e  inkEvent = new CRM_Address_Event__e(version__c = '1.0',   eventDate__c = String.valueOf(System.now()), entityType__c = 'address', eventSource__c = 'ts', eventSourceID__c = 'MN-123', 
                                 operation__c = 'create', stage__c = 'pending', systemOfOrigin__c = 'ts', systemOfOriginID__c = '', parentSystemOfOriginID__c = '', 
                                                                   accountID__c='', addressID__c = lstAddress[0].Id, isActive__c = true, isLocked__c = false, addressType__c = 'shipping', address1__c = '2322 Main St.',
                                                                  city__c = 'San Diego', stateProvince__c = 'CA', postalCode__c = '92121', countryCode__c ='CA'); 
        
        Test.startTest();        
        // Publish test event
        Database.SaveResult sr = EventBus.publish(inkEvent);            
        Test.stopTest();
    }
     @isTest static void sfccCreateAddress_v3() {       
        
        Id recId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('CA_Consumer').getRecordTypeId();
         Id caAddRecId = SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        Account acc = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId);
        
        insert acc;
         
         List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Account__c = acc.Id,RecordTypeId=caAddRecId,SOS_Unique_ID__c='tsMN-1233',Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = acc.Id,RecordTypeId=caAddRecId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                                                          };
        insert lstAddress;
        
         
         
        CRM_Address_Event__e  inkEvent = new CRM_Address_Event__e(version__c = '1.0',   eventDate__c = String.valueOf(System.now()), entityType__c = 'address', eventSource__c = 'ts', eventSourceID__c = 'MN-123', 
                                 operation__c = 'create', stage__c = 'pending', systemOfOrigin__c = 'ts', systemOfOriginID__c = 'MN-123', parentSystemOfOriginID__c = 'test', 
                                                                   accountID__c=acc.Id, addressID__c = lstAddress[0].Id, isActive__c = true, isLocked__c = false, addressType__c = '', address1__c = '2322 Main St.',
                                                                  city__c = 'San Diego', stateProvince__c = 'CA', postalCode__c = '92121', countryCode__c ='CA'); 
        
        Test.startTest();        
        // Publish test event
        Database.SaveResult sr = EventBus.publish(inkEvent);            
        Test.stopTest();
    }
     @isTest static void sfccCreateAddress_v4() {       
        
        Id recId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('CA_Consumer').getRecordTypeId();
         Id caAddRecId = SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        Account acc = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId);
        
        insert acc;
         
         List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Account__c = acc.Id,RecordTypeId=caAddRecId,SOS_Unique_ID__c='tsMN-1233',Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = acc.Id,RecordTypeId=caAddRecId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                                                          };
        insert lstAddress;
        
         
         
        CRM_Address_Event__e  inkEvent = new CRM_Address_Event__e(version__c = '1.0',   eventDate__c = String.valueOf(System.now()), entityType__c = 'address', eventSource__c = 'ts', eventSourceID__c = 'MN-123', 
                                 operation__c = 'create', stage__c = 'pending', systemOfOrigin__c = 'ts', systemOfOriginID__c = 'MN-123', parentSystemOfOriginID__c = 'test', 
                                                                   accountID__c=acc.Id, addressID__c = lstAddress[0].Id, isActive__c = true, isLocked__c = false, addressType__c = 'shipping', address1__c = '2322 Main St.',
                                                                  city__c = 'San Diego', stateProvince__c = 'CA', postalCode__c = '92121', countryCode__c ='',country__c=''); 
        
        Test.startTest();        
        // Publish test event
        Database.SaveResult sr = EventBus.publish(inkEvent);            
        Test.stopTest();
    }
    @isTest static void sfccCreateAddress_v5() {       
        
        Id recId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('CA_Consumer').getRecordTypeId();
         Id caAddRecId = SObjectType.Address__c.getRecordTypeInfosByDeveloperName().get('CA_Address').getRecordTypeId();
        Account acc = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId);
        
        insert acc;
         
         List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Account__c = acc.Id,RecordTypeId=caAddRecId,SOS_Unique_ID__c='tsMN-1233',Type__c = 'Bill To', Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = acc.Id,RecordTypeId=caAddRecId,Type__c = 'Ship To',Country__c = 'Canada', City__c = 'Rosemont', Address_Line_1__c = 'W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                                                          };
        insert lstAddress;
        
         
         
        CRM_Address_Event__e  inkEvent = new CRM_Address_Event__e(version__c = '1.0',   eventDate__c = String.valueOf(System.now()), entityType__c = 'address', eventSource__c = 'ts', eventSourceID__c = 'MN-123', 
                                 operation__c = 'create', stage__c = 'pending', systemOfOrigin__c = 'ts', systemOfOriginID__c = 'MN-123', parentSystemOfOriginID__c = 'test', 
                                                                   accountID__c=acc.Id, addressID__c = lstAddress[0].Id, isActive__c = true, isLocked__c = false, addressType__c = 'shipping', address1__c = '2322 Main St.',
                                                                  city__c = 'San Diego', stateProvince__c = 'CA', postalCode__c = '92121', countryCode__c ='ASDGH'); 
        
        Test.startTest();        
        // Publish test event
        Database.SaveResult sr = EventBus.publish(inkEvent);            
        Test.stopTest();
    }
    
     @isTest static void sfccUpdateAddress() {
        id recId = [Select id from recordType where DeveloperName = 'CA_Consumer' AND isActive = true].id;
        id caAddRecId = [Select id from recordType where DeveloperName = 'CA_Address' AND isActive = true].id;
        Account a = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId);
        
        insert a;
         
        Address__c add = new Address__c(Account__c = a.id, Address_Line_1__c = '7511 Lucas Rd', city__c = 'Richmond', Country__c = 'Canada', RecordTypeId = caAddRecId,
                                       State__C = 'British Columbia', Postal_Code__c = 'V6Y 1G1', Type__c = 'Ship To', Primary_Flag__c = true);
        
        insert add;
        CRM_Address_Event__e  inkEvent = new CRM_Address_Event__e(version__c = '1.0',   eventDate__c = String.valueOf(System.now()), entityType__c = 'address', eventSource__c = 'ts', eventSourceID__c = 'MN-123', 
                                 operation__c = 'update', stage__c = 'pending', systemOfOrigin__c = 'ts', systemOfOriginID__c = 'MN-123', parentSystemOfOriginID__c = null, 
                                                                  accountID__c=a.id, addressID__c = add.Id, isActive__c = true, isLocked__c = false, addressType__c = 'shipping', address1__c = '2322 Main St.',
                                                                  city__c = 'San Diego', stateProvince__c = 'CA', postalCode__c = '92121', countryCode__c ='CA'); 
        add.Primary_Flag__c= true;
        add.Postal_Code__c= 'V6Y 1G2';
         update add;
        add.Primary_Flag__c= true;
        add.Postal_Code__c= 'V6Y 1G3';
         update add;
        Test.startTest();
        
        // Publish test event
        Database.SaveResult sr = EventBus.publish(inkEvent);
            
        Test.stopTest(); 
     }
    @isTest static void sfccUpdateAddress_v1() {
        id recId = [Select id from recordType where DeveloperName = 'CA_Consumer' AND isActive = true].id;
        id caAddRecId = [Select id from recordType where DeveloperName = 'CA_Address' AND isActive = true].id;
        Account a = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId);
        
        insert a;
         
        Address__c add = new Address__c(Account__c = a.id, Address_Line_1__c = '7511 Lucas Rd', city__c = 'Richmond', Country__c = 'Canada', RecordTypeId = caAddRecId,
                                       State__C = 'British Columbia', Postal_Code__c = 'V6Y 1G1', Type__c = 'Ship To', Primary_Flag__c = true);
        
        insert add;
        CRM_Address_Event__e  inkEvent = new CRM_Address_Event__e(version__c = '1.0',   eventDate__c = String.valueOf(System.now()), entityType__c = 'address', eventSource__c = 'ts', eventSourceID__c = 'MN-123', 
                                 operation__c = 'update', stage__c = 'pending', systemOfOrigin__c = 'ts', systemOfOriginID__c = 'MN-123', parentSystemOfOriginID__c = 'Tests', 
                                                                  accountID__c=a.id, addressID__c = add.Id, isActive__c = true, isLocked__c = false, addressType__c = 'shipping', address1__c = '2322 Main St.',
                                                                  city__c = 'San Diego', stateProvince__c = 'CA', postalCode__c = '92121', countryCode__c ='CSDFA',country__c='null'); 
        add.Primary_Flag__c= true;
        add.Postal_Code__c= 'V6Y 1G2';
         update add;
        add.Primary_Flag__c= true;
        add.Postal_Code__c= 'V6Y 1G3';
         update add;
        Test.startTest();
        
        // Publish test event
        Database.SaveResult sr = EventBus.publish(inkEvent);
            
        Test.stopTest(); 
     }
    @isTest static void sfccCreateAddressWithPsoo() {
        id recId = [Select id from recordType where DeveloperName = 'CA_Consumer' AND isActive = true].id;
        id caAddRecId = [Select id from recordType where DeveloperName = 'CA_Address' AND isActive = true].id;
        Account a = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId, system_of_Origin__c = 'crm', system_of_Origin_Id__c='10423343');
        
        insert a;
        
         CRM_Address_Event__e  inkEvent = new CRM_Address_Event__e(version__c = '1.0',   eventDate__c = String.valueOf(System.now()), entityType__c = 'address', eventSource__c = 'ts', eventSourceID__c = 'MN-123', 
                                 operation__c = 'create', stage__c = 'pending', systemOfOrigin__c = 'ts', systemOfOriginID__c = 'MN-123', parentSystemOfOriginID__c = '10423343', 
                                                                  addressID__c = null, isActive__c = true, isLocked__c = false, addressType__c = 'shipping', address1__c = '2322 Main St.',
                                                                  city__c = 'San Diego', stateProvince__c = 'CA', postalCode__c = '92121', countryCode__c ='CA'); 
        
        Test.startTest();
        
        // Publish test event
        Database.SaveResult sr = EventBus.publish(inkEvent);
            
        Test.stopTest();
    }

}