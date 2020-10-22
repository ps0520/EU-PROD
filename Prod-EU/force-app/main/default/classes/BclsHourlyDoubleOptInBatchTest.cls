/**
 * HourlyDoubleOptInBatchTest
 * Tests for BclsHourlyDoubleOptInBatch
 * @author Craig Johnson(Sundog)
 * @date 06/13/19
 */
@isTest()
public class BclsHourlyDoubleOptInBatchTest {
    
    @testSetup
    static void testSetup(){
        // Username, LastName, Email, Alias, CommunityNickname, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey
        User u = new User(
            Username = 'test@sundogtest.com',
            LastName = 'Sundog',
            Email = 'test@sundog.net',
            Alias = 'SDOG',
            CommunityNickname = 'test.156356',
            TimeZoneSidKey = 'Europe/Berlin',
            LocaleSidKey = 'de_DE_EURO',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DE Field Sales User'].Id
        );

        User u2 = new User(
                Username = 'test_ca@sundogtest.com',
                LastName = 'Sundog',
                Email = 'test@sundog.net',
                Alias = 'SDOG2',
                CommunityNickname = 'test.1563564',
                TimeZoneSidKey = 'Europe/Berlin',
                LocaleSidKey = 'de_DE_EURO',
                EmailEncodingKey = 'ISO-8859-1',
                LanguageLocaleKey = 'en_US',
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'CA Inside Sales User'].Id
        );
        insert new List<User> {u, u2};
    }
    
    // Test for hourly job Scheduler
    @isTest
    static void testHourlyEmailScheduledJob() {
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        //insert TestDataBuilder.testURLExpiryVal();

        List<Account> accountList= new List<Account>();
        
        Account testAccount = TestUtils.testDEConsumerAccount();
        testAccount.PersonEmail='jane.smith@sundog.net';
        testAccount.Email_Opt_In_Language__c = 'German';
        testAccount.Email_Opt_In_Method__c = 'Via Email';
		testAccount.Email_Pending_Opt_In__c = true;        
            
        accountList.add(testAccount); 
        
        Account testAccount2 = TestUtils.testDEConsumerAccount();
        testAccount2.PersonEmail='john.smith@sundog.net';
        testAccount2.Email_Opt_In_Language__c = 'German';
        testAccount2.Email_Opt_In_Method__c = 'Via Email';
        testAccount2.Email_Pending_Opt_In__c = true;
        
        accountList.add(testAccount2);
        insert accountList;
        
        List<Lead> leadList= new List<Lead>();
        Lead testLead = TestUtils.testDEPersonLead();
        testLead.Email='jane.smith@sundog.net';
        testLead.Email_Opt_In_Language__c = 'German';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Pending_Opt_In__c = true;
        leadList.add(testLead); 
        
        Lead testlead2 = TestUtils.testDEPersonLead();
        testLead2.Email_Opt_In_Language__c = 'German';
        testLead2.Email_Opt_In_Method__c = 'Via Email';
        testlead2.Email='john.smith@sundog.net';
        testlead2.Email_Pending_Opt_In__c = true;
        leadList.add(testlead2);
        insert leadList;
        
        Test.startTest();
        String jobId = System.schedule('testEmailScheduled', '0 0 0 3 9 ? 2052', new SclsHourlyDoubleOptInScheduled());
        Test.stopTest();
        
        System.assertEquals(false, String.isBlank(jobId));
    }
    
    // Tests for batch job on Account from Germany
    @isTest
    static void testDEAccountOptIn() {
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        
        //Create 2 Test Accounts to put trigger in bulk mode
        List<Account> accountList= new List<Account>();
        Account testAccount = TestUtils.testDEConsumerAccount();
        testAccount.PersonEmail = 'jane.smith@sundog.net';
        testAccount.Email_Pending_Opt_In__c = true;
        testAccount.Email_Opt_In_Language__c = 'German';
        testAccount.Email_Opt_In_Method__c = 'Via Email';
        accountList.add(testAccount);
        
        Account testAccount2 = TestUtils.testDEConsumerAccount();
        testAccount2.Email_Pending_Opt_In__c = false;
        testAccount2.Email_Opt_In_Language__c = 'German';
        testAccount2.Email_Opt_In_Method__c = 'Via Email';
        accountList.add(testAccount2);
        insert accountList;
        
        Account resultAccount = [SELECT Email_Double_Opt_In_Subscriber__c FROM Account where Email_Pending_Opt_In__c = true];
        System.assertEquals(null, resultAccount.Email_Double_Opt_In_Subscriber__c);

        //Run batch job
        Test.startTest();
        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch(BclsHourlyDoubleOptInBatch.BatchType.ACCOUNT);
        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
        Test.stopTest();

        resultAccount = [SELECT Email_Double_Opt_In_Subscriber__c FROM Account where Email_Pending_Opt_In__c = true];
        
        System.assertNotEquals(null, resultAccount.Email_Double_Opt_In_Subscriber__c);
    }
    
    @isTest
    static void testDEAccountOptOut(){
        User salesUser = [SELECT Id FROM User WHERE Username = 'test@sundogtest.com'];
        Lead testLead = TestUtils.testDEPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Pending_Opt_Out__c = true;
        testLead.Email_Opt_In_List__c = 'True';
        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testLead.Email_Opt_In_Language__c = 'German';
        testLead.Email_Opt_In_Method__c = 'Via Web Form';
        testLead.OwnerId = salesUser.Id;
        insert testLead;
        
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.convertedStatus = 'Qualified';
        lc.setDoNotCreateOpportunity(true);
        Database.LeadConvertResult lcr = Database.convertLead(lc, false);
        //System.assertEquals(null, lcr.getErrors());
        for(Database.Error e : lcr.getErrors()){
            System.debug(e);
        }
        System.assert(lcr.isSuccess());
        
        //query account record where double opt in penbding is true
        Lead resultLead1 = [SELECT Id, Email_Opt_In_List__c, ConvertedAccountId FROM Lead where Id = :testLead.Id];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id));
        
        Account resultAccount = [SELECT RecordTypeId, Email_Pending_Opt_Out__c, PersonContactId, Email_Double_Opt_In_Subscriber__c FROM Account where Id = :resultLead1.ConvertedAccountId];
        System.assertNotEquals(null, resultAccount.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(true, resultAccount.Email_Pending_Opt_Out__c);

        resultAccount.RecordTypeId = [SELECT Id FROM RecordType WHERE (DeveloperName = 'DE_Consumer') AND SobjectType = 'Account'].Id;
        update resultAccount;
        
        //the normal process flow would only result in the customer being in MC 1 time under lead or account
        //but we test to support the case that they are in as both
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(new List<String>{ testLead.Id, resultAccount.PersonContactId }, 'Active'));

        //Run batch job
        Test.startTest();
        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch(BclsHourlyDoubleOptInBatch.BatchType.ACCOUNT);
        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
        Test.stopTest();

        resultAccount = [SELECT Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_Out__c, Email_Opt_In_List__c FROM Account where Id = :resultAccount.Id];
        
        System.assertEquals(null, resultAccount.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false, resultAccount.Email_Pending_Opt_Out__c);
        System.assertEquals('False', resultAccount.Email_Opt_In_List__c);
    }
    
    // Tests for batch job on Lead
    @isTest
    static void testDELeadOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        
        //Create 2 Test Leads to put trigger in bulk mode
        List<Lead> leadList= new List<Lead>();
        Lead testLead = TestUtils.testDEPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_Language__c = 'German';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Pending_Opt_In__c = true;
        leadList.add(testLead);
        
        Lead testLead2 = TestUtils.testDEPersonLead();
        testLead2.Email_Pending_Opt_In__c = false;
        leadList.add(testLead2); 
        
        insert leadList;

        Lead resultLead = [SELECT Email_Double_Opt_In_Subscriber__c FROM Lead where Email_Pending_Opt_In__c = true];
        System.assertEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);
        
        //Run batch job
        Test.startTest(); 
        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch();
        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
        Test.stopTest();
        
        resultLead = [SELECT Email_Double_Opt_In_Subscriber__c FROM Lead where Email_Pending_Opt_In__c = true];
        
        System.assertNotEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);
    }
    
    @isTest
    static void testDELeadOptOut(){
        Lead testLead = TestUtils.testDEPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Pending_Opt_Out__c = true;
        testLead.Email_Opt_In_List__c = 'True';
        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testLead.Email_Opt_In_Language__c = 'German';
        testLead.Email_Opt_In_Method__c = 'Via Web Form';
        
        insert testLead;
        
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Run batch job
        Test.startTest();
        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch(BclsHourlyDoubleOptInBatch.BatchType.LEAD);
        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
        Test.stopTest();

        Lead resultLead = [SELECT Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_Out__c, Email_Opt_In_List__c FROM Lead where Id = :testLead.Id];
        
        System.assertEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false, resultLead.Email_Pending_Opt_Out__c);
        System.assertEquals('False', resultLead.Email_Opt_In_List__c);
    }

    // Tests for batch job on Account from Canada
    @isTest
    static void testCAAccountOptIn() {
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Accounts to put trigger in bulk mode
        List<Account> accountList= new List<Account>();
        Account testAccount = TestUtils.testCAConsumerAccount();
        testAccount.PersonEmail = 'jane.smith@sundog.net';
        testAccount.Email_Pending_Opt_In__c = true;
        testAccount.Email_Opt_In_Language__c = 'English';
        testAccount.Email_Opt_In_Method__c = 'Via Email';
        setAddress(testAccount);
        accountList.add(testAccount);

        Account testAccount2 = TestUtils.testCAConsumerAccount();
        testAccount2.Email_Pending_Opt_In__c = false;
        testAccount2.Email_Opt_In_Language__c = 'English';
        testAccount2.Email_Opt_In_Method__c = 'Via Email';
        setAddress(testAccount2);
        accountList.add(testAccount2);
        insert accountList;

        Account resultAccount = [SELECT Email_Double_Opt_In_Subscriber__c FROM Account where Email_Pending_Opt_In__c = true];
        System.assertEquals(null, resultAccount.Email_Double_Opt_In_Subscriber__c);

        //Run batch job
        Test.startTest();
        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch(BclsHourlyDoubleOptInBatch.BatchType.ACCOUNT);
        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
        Test.stopTest();

        resultAccount = [SELECT Email_Double_Opt_In_Subscriber__c FROM Account where Email_Pending_Opt_In__c = true];

        System.assertNotEquals(null, resultAccount.Email_Double_Opt_In_Subscriber__c);
    }

//    @isTest
//    static void testCAAccountOptOut(){
//        User salesUser = [SELECT Id FROM User WHERE Username = 'test_ca@sundogtest.com'];
//        Lead testLead = TestUtils.testCAPersonLead();
//        testLead.Email = 'jane.smith@sundog.net';
//        testLead.Email_Pending_Opt_Out__c = true;
//        testLead.Email_Opt_In_List__c = 'True';
//        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
//        testLead.Email_Opt_In_Language__c = 'English';
//        testLead.Email_Opt_In_Method__c = 'Via Web Form';
//        testLead.OwnerId = salesUser.Id;
//        insert testLead;
//
//        Database.LeadConvert lc = new database.LeadConvert();
//        lc.setLeadId(testLead.Id);
//        lc.convertedStatus = 'Qualified';
//        lc.setDoNotCreateOpportunity(true);
//        Database.LeadConvertResult lcr = Database.convertLead(lc, false);
//        //System.assertEquals(null, lcr.getEr rors());
//        for(Database.Error e : lcr.getErrors()){
//            System.debug(e);
//        }
//        System.assert(lcr.isSuccess());
//
//        //query account record where double opt in penbding is true
//        Lead resultLead1 = [SELECT Id, Email_Opt_In_List__c, ConvertedAccountId FROM Lead where Id = :testLead.Id];
//        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id));
//
//        Account resultAccount = [SELECT RecordTypeId, Email_Pending_Opt_Out__c, PersonContactId, Email_Double_Opt_In_Subscriber__c FROM Account where Id = :resultLead1.ConvertedAccountId];
//        System.assertNotEquals(null, resultAccount.Email_Double_Opt_In_Subscriber__c);
//        System.assertEquals(true, resultAccount.Email_Pending_Opt_Out__c);
//
//        resultAccount.RecordTypeId = [SELECT Id FROM RecordType WHERE (DeveloperName = 'CA_Consumer') AND SobjectType = 'Account'].Id;
//        update resultAccount;
//
//        //the normal process flow would only result in the customer being in MC 1 time under lead or account
//        //but we test to support the case that they are in as both
//        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(new List<String>{ testLead.Id, resultAccount.PersonContactId }, 'Active'));
//
//        //Run batch job
//        Test.startTest();
//        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch(BclsHourlyDoubleOptInBatch.BatchType.ACCOUNT);
//        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
//        Test.stopTest();
//
//        resultAccount = [SELECT Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_Out__c, Email_Opt_In_List__c FROM Account where Id = :resultAccount.Id];
//
//        System.assertEquals(null, resultAccount.Email_Double_Opt_In_Subscriber__c);
//        System.assertEquals(false, resultAccount.Email_Pending_Opt_Out__c);
//        System.assertEquals('False', resultAccount.Email_Opt_In_List__c);
//    }

    // Tests for batch job on Lead
    @isTest
    static void testCALeadOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Leads to put trigger in bulk mode
        List<Lead> leadList= new List<Lead>();
        Lead testLead = TestUtils.testCAPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Pending_Opt_In__c = true;
        leadList.add(testLead);

        Lead testLead2 = TestUtils.testCAPersonLead();
        testLead2.Email_Pending_Opt_In__c = false;
        leadList.add(testLead2);

        insert leadList;

        Lead resultLead = [SELECT Email_Double_Opt_In_Subscriber__c FROM Lead where Email_Pending_Opt_In__c = true];
        System.assertEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);

        //Run batch job
        Test.startTest();
        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch();
        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
        Test.stopTest();

        resultLead = [SELECT Email_Double_Opt_In_Subscriber__c FROM Lead where Email_Pending_Opt_In__c = true];

        System.assertNotEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);
    }

    @isTest
    static void testCALeadOptOut(){
        Lead testLead = TestUtils.testCAPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Pending_Opt_Out__c = true;
        testLead.Email_Opt_In_List__c = 'True';
        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Email_Opt_In_Method__c = 'Via Web Form';

        insert testLead;

        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Run batch job
        Test.startTest();
        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch(BclsHourlyDoubleOptInBatch.BatchType.LEAD);
        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
        Test.stopTest();

        Lead resultLead = [SELECT Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_Out__c, Email_Opt_In_List__c FROM Lead where Id = :testLead.Id];

        System.assertEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false, resultLead.Email_Pending_Opt_Out__c);
        System.assertEquals('False', resultLead.Email_Opt_In_List__c);
    }

    private static void setAddress(Account account) {
        account.BillingPostalCode = 'V6B 4E1';
        account.ShippingPostalCode = 'V6B 4E1';
    }
    
      @isTest
    static void testGBLeadOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Leads to put trigger in bulk mode
        List<Lead> leadList= new List<Lead>();
        Lead testLead = TestUtils.testGBPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Pending_Opt_In__c = true;
        leadList.add(testLead);

        Lead testLead2 = TestUtils.testGBPersonLead();
        testLead2.Email_Pending_Opt_In__c = false;
        leadList.add(testLead2);

        insert leadList;

        Lead resultLead = [SELECT Email_Double_Opt_In_Subscriber__c FROM Lead where Email_Pending_Opt_In__c = true];
        System.assertEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);

        //Run batch job
        Test.startTest();
        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch();
        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
        Test.stopTest();

        resultLead = [SELECT Email_Double_Opt_In_Subscriber__c FROM Lead where Email_Pending_Opt_In__c = true];

        System.assertNotEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);
    }

    @isTest
    static void testGBLeadOptOut(){
        Lead testLead = TestUtils.testGBPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Pending_Opt_Out__c = true;
        testLead.Email_Opt_In_List__c = 'True';
        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Email_Opt_In_Method__c = 'Via Web Form';

        insert testLead;

        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Run batch job
        Test.startTest();
        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch(BclsHourlyDoubleOptInBatch.BatchType.LEAD);
        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
        Test.stopTest();

        Lead resultLead = [SELECT Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_Out__c, Email_Opt_In_List__c FROM Lead where Id = :testLead.Id];

        System.assertEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false, resultLead.Email_Pending_Opt_Out__c);
        System.assertEquals('False', resultLead.Email_Opt_In_List__c);
    }
 
      @isTest
    static void testIELeadOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Leads to put trigger in bulk mode
        List<Lead> leadList= new List<Lead>();
        Lead testLead = TestUtils.testIEPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Pending_Opt_In__c = true;
        leadList.add(testLead);

        Lead testLead2 = TestUtils.testIEPersonLead();
        testLead2.Email_Pending_Opt_In__c = false;
        leadList.add(testLead2);

        insert leadList;

        Lead resultLead = [SELECT Email_Double_Opt_In_Subscriber__c FROM Lead where Email_Pending_Opt_In__c = true];
        System.assertEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);

        //Run batch job
        Test.startTest();
        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch();
        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
        Test.stopTest();

        resultLead = [SELECT Email_Double_Opt_In_Subscriber__c FROM Lead where Email_Pending_Opt_In__c = true];

        System.assertNotEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);
    }

    @isTest
    static void testIELeadOptOut(){
        Lead testLead = TestUtils.testIEPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Pending_Opt_Out__c = true;
        testLead.Email_Opt_In_List__c = 'True';
        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Email_Opt_In_Method__c = 'Via Web Form';

        insert testLead;

        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Run batch job
        Test.startTest();
        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch(BclsHourlyDoubleOptInBatch.BatchType.LEAD);
        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
        Test.stopTest();

        Lead resultLead = [SELECT Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_Out__c, Email_Opt_In_List__c FROM Lead where Id = :testLead.Id];

        System.assertEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false, resultLead.Email_Pending_Opt_Out__c);
        System.assertEquals('False', resultLead.Email_Opt_In_List__c);
    }
    
    
    @isTest
    static void testATLeadOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Leads to put trigger in bulk mode
        List<Lead> leadList= new List<Lead>();
        Lead testLead = TestUtils.testATPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Pending_Opt_In__c = true;
        leadList.add(testLead);

        Lead testLead2 = TestUtils.testATPersonLead();
        testLead2.Email_Pending_Opt_In__c = false;
        leadList.add(testLead2);

        insert leadList;

        Lead resultLead = [SELECT Email_Double_Opt_In_Subscriber__c FROM Lead where Email_Pending_Opt_In__c = true];
        System.assertEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);

        //Run batch job
        Test.startTest();
        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch();
        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
        Test.stopTest();

        resultLead = [SELECT Email_Double_Opt_In_Subscriber__c FROM Lead where Email_Pending_Opt_In__c = true];

        System.assertNotEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);
    }

    @isTest
    static void testATLeadOptOut(){
        Lead testLead = TestUtils.testATPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Pending_Opt_Out__c = true;
        testLead.Email_Opt_In_List__c = 'True';
        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Email_Opt_In_Method__c = 'Via Web Form';

        insert testLead;

        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Run batch job
        Test.startTest();
        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch(BclsHourlyDoubleOptInBatch.BatchType.LEAD);
        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
        Test.stopTest();

        Lead resultLead = [SELECT Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_Out__c, Email_Opt_In_List__c FROM Lead where Id = :testLead.Id];

        System.assertEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false, resultLead.Email_Pending_Opt_Out__c);
        System.assertEquals('False', resultLead.Email_Opt_In_List__c);
    }
 
      @isTest
    static void testCHLeadOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Leads to put trigger in bulk mode
        List<Lead> leadList= new List<Lead>();
        Lead testLead = TestUtils.testCHPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Pending_Opt_In__c = true;
        leadList.add(testLead);

        Lead testLead2 = TestUtils.testCHPersonLead();
        testLead2.Email_Pending_Opt_In__c = false;
        leadList.add(testLead2);

        insert leadList;

        Lead resultLead = [SELECT Email_Double_Opt_In_Subscriber__c FROM Lead where Email_Pending_Opt_In__c = true];
        System.assertEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);

        //Run batch job
        Test.startTest();
        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch();
        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
        Test.stopTest();

        resultLead = [SELECT Email_Double_Opt_In_Subscriber__c FROM Lead where Email_Pending_Opt_In__c = true];

        System.assertNotEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);
    }

    @isTest
    static void testCHLeadOptOut(){
        Lead testLead = TestUtils.testCHPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Pending_Opt_Out__c = true;
        testLead.Email_Opt_In_List__c = 'True';
        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Email_Opt_In_Method__c = 'Via Web Form';

        insert testLead;

        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Run batch job
        Test.startTest();
        BclsHourlyDoubleOptInBatch emailbatch = new BclsHourlyDoubleOptInBatch(BclsHourlyDoubleOptInBatch.BatchType.LEAD);
        Id batchInstanceId = Database.executeBatch(emailbatch, 1);
        Test.stopTest();

        Lead resultLead = [SELECT Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_Out__c, Email_Opt_In_List__c FROM Lead where Id = :testLead.Id];

        System.assertEquals(null, resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false, resultLead.Email_Pending_Opt_Out__c);
        System.assertEquals('False', resultLead.Email_Opt_In_List__c);
    }
    
}