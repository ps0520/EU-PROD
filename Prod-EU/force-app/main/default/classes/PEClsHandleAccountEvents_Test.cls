@isTest
public class PEClsHandleAccountEvents_Test {
    @isTest static void sfccPublishEvent() {
        // Create a test event instance
        CRM_Account_Event__e inkEvent = new CRM_Account_Event__e(accountID__c='MN-123', 
                                            accountType__c ='Consumer', eventDate__c = String.valueOf(System.now()), eventSource__c = 'ecom', eventSourceID__c = 'MN-123', lastName__c = 'Test', 
                                            firstName__c= 'First', middleName__c = 'Old', personalemail__c = 'testingPEs@tester.com',  countryCode__c = 'CA',
                                            systemOfOrigin__c = 'ecom', systemOfOriginID__c = 'MN-123', operation__c = 'create', stage__c = 'pending',
                                            version__c = '1.0', entityType__c = 'account', isActive__c = true);
        Test.startTest();
            // Publish test event
            Database.SaveResult sr = EventBus.publish(inkEvent);
        Test.stopTest();
        System.assertEquals(true, sr.isSuccess());
        List<Account> acts = [SELECT Id FROM Account];
        system.debug('Account Id: ' + acts[0].id);
        System.assertEquals(1, acts.size());
    }
    
    @isTest static void sfccUpdateEvent() {
        id recId = [Select id from recordType where DeveloperName = 'CA_Consumer' AND isActive = true].id;
        Account a = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId);
        insert a;
        List<Account> acts = [SELECT Id FROM Account];
        system.debug('Account Id: ' + acts[0].id);
        CRM_Account_Event__e  inkEvent = new CRM_Account_Event__e(accountID__c=a.id, middleName__c= 'New', 
                                accountType__c ='Consumer', eventDate__c = String.valueOf(System.now()), eventSource__c = 'ts', eventSourceID__c = 'MN-123', lastName__c= 'Test', firstName__c = 'null',
                                countryCode__c = 'CA', operation__c = 'update', stage__c = 'pending', isActive__c = true,
                                                                version__c = '1.0', entityType__c = 'account', emailOptin__c = 'True' ); 
        Test.startTest();
            // Publish test event
            Database.SaveResult sr = EventBus.publish(inkEvent);
        Test.stopTest();
        acts = [SELECT Id FROM Account where middlename = 'New'];
        System.assertEquals(1, acts.size());
    }
    
    @isTest static void oraRegisterEvent() {
        id recId = [Select id from recordType where DeveloperName = 'CA_Consumer' AND isActive = true].id;
        Account a = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId);
        insert a;
        List<Account> acts = [SELECT Id FROM Account];
        system.debug('Account Id: ' + acts[0].id);
        CRM_Account_Event__e  inkEvent = new CRM_Account_Event__e(accountID__c=a.id, middleName__c = 'New', 
                                accountType__c ='Consumer', eventDate__c = String.valueOf(System.now()), eventSource__c = 'oms', eventSourceID__c = 'MN-123', lastName__c = 'Test',
                                systemOfOriginID__c = a.id, systemOfOrigin__c = 'crm',   countryCode__c = 'CA', operation__c = 'create', stage__c = 'confirmed', firstName__c = 'null', isActive__c = true,
                                                                version__c = '1.0', entityType__c = 'account'); 
        
        Test.startTest();
            // Publish test event
            Database.SaveResult sr = EventBus.publish(inkEvent);
        	Test.getEventBus().deliver();
        Test.stopTest();
        acts = [SELECT Id FROM Account where sync_status__c = 'Created'];
       // System.assertEquals(1, acts.size());
    }
    @isTest static void ecomAccountConfirmedEvent() {
        id recId = [Select id from recordType where DeveloperName = 'CA_Consumer' AND isActive = true].id;
        Account a = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId);
        insert a;
        List<Account> acts = [SELECT Id FROM Account];
        system.debug('Account Id: ' + acts[0].id);
        CRM_Account_Event__e  inkEvent = new CRM_Account_Event__e(accountID__c=a.id, middleName__c = 'New', 
                                accountType__c ='Consumer', eventDate__c = String.valueOf(System.now()), eventSource__c = 'ecom', eventSourceID__c = 'MN-123', lastName__c = 'Test',
                                systemOfOriginID__c = a.id, systemOfOrigin__c = 'crm',   countryCode__c = 'CA', operation__c = 'create', stage__c = 'confirmed', firstName__c = 'null', isActive__c = true,
                                                                version__c = '1.0', entityType__c = 'account'); 
        Test.startTest();
            // Publish test event
            Database.SaveResult sr = EventBus.publish(inkEvent);
        Test.stopTest();
        acts = [SELECT Id FROM Account where SFCC_Account_Id__c = 'MN-123'];
        System.assertEquals(1, acts.size());
    }
    
    @isTest static void ecomCreateAndUpdateEvent() {
        // Create a test event instance
        List<CRM_Account_Event__e> inkEvents = new List<CRM_Account_Event__e>();
        CRM_Account_Event__e inkEvent = new CRM_Account_Event__e(accountID__c='MN-123', 
                                            accountType__c ='Consumer', eventDate__c = String.valueOf(System.now()), eventSource__c = 'ecom', eventSourceID__c = 'MN-123', lastName__c = 'Test', 
                                            firstName__c= 'First', middleName__c = 'Old', personalemail__c = 'testingPEs@tester.com', countryCode__c = 'CA',
                                            systemOfOrigin__c = 'ecom', systemOfOriginID__c = 'MN-123', operation__c = 'create', stage__c = 'pending',
                                            version__c = '1.0', entityType__c = 'account', isActive__c = true);
        inkEvents.add(inkEvent);
        inkEvent = new CRM_Account_Event__e(accountID__c='', 
                                            accountType__c ='Consumer', eventDate__c = String.valueOf(System.now()), eventSource__c = 'ecom', eventSourceID__c = 'MN-123', lastName__c = 'Test', 
                                            firstName__c= 'First', middleName__c = 'New', personalemail__c = 'testingPEs@tester.com',  countryCode__c = 'CA',
                                            systemOfOrigin__c = 'ecom', systemOfOriginID__c = 'MN-123', operation__c = 'update', stage__c = 'pending',
                                            version__c = '1.0', entityType__c = 'account', isActive__c = true);
        inkEvents.add(inkEvent);
        Test.startTest();
            // Publish test event
            List<Database.SaveResult> sr = EventBus.publish(inkEvents);
        Test.stopTest();
        System.assertEquals(true, sr[0].isSuccess());
        System.assertEquals(true, sr[1].isSuccess());
        List<Account> acts = [SELECT Id, MiddleName FROM Account];
        system.debug('Middle Name: '+ acts[0].MiddleName);
        System.assertEquals(1, acts.size());
    }
    @isTest static void sfdcTestAccountPublishUpdate() {
        id recId = [Select id from recordType where DeveloperName = 'CA_Consumer' AND isActive = true].id;
        Account a = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId);
        insert a;
        List<Account> acts = [SELECT Id FROM Account];
        a.FirstName = 'Brand New';
        Test.startTest();
        	update a;
            PEClsHandleAccountEventsStatic.firstEventPublish();
        Test.stopTest();
        //System.assert(PEClsHandleAccountEvents.eventList.size() == 1, 'Matching whether an update event got created');
        system.debug('Event List Size: ' + PEClsHandleAccountEvents.eventList.size());
    }
	@isTest static void sfdcTestAccountNotPublishUpdate() {
        id recId = [Select id from recordType where DeveloperName = 'CA_Consumer' AND isActive = true].id;
        Account a = new Account(firstname = 'New',
                                lastname = 'test', recordtypeId = recId, Blind__c = true);
        insert a;
        List<Account> acts = [SELECT Id FROM Account];
        a.Blind__c = false;
        Test.startTest();
        	update a;
        PEClsHandleAccountEventsStatic.firstEventPublish();
        Test.stopTest();
        System.assert(PEClsHandleAccountEvents.eventList.size() == 0, 'Matching whether an update event got created');
        //system.debug('Event List Size: ' + PEClsHandleAccountEvents.eventList.size());
    }
}