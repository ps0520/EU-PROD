/**
 * BclsDailyDoubleOptInEmailBatchTest
 * Test for BclsDailyDoubleOptInEmailBatch
 * @author Craig Johnson(Sundog)
 * @date 06/13/19
 */

@isTest
public class BclsDailyDoubleOptInEmailBatchTest {
    
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
        insert u;
    }
    
    // Test for daily job Scheduler
    @isTest
    static void testDailyEmailScheduledJob() {
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        //insert TestDataBuilder.testURLExpiryVal();

        List<Account> accountList= new List<Account>();
        
        Account testAccount = TestUtils.testDEConsumerAccount();
        testAccount.PersonEmail='jane.smith@sundog.net';
        testAccount.Email_Opt_In_Language__c = 'German';
        testAccount.Preferred_Language__c = 'de_DE';
        testAccount.Email_Opt_In_Method__c = 'Via Email';
		testAccount.Email_Pending_Opt_In__c = true;        
            
        accountList.add(testAccount); 
        
        Account testAccount2 = TestUtils.testDEConsumerAccount();
        testAccount2.PersonEmail='john.smith@sundog.net';
        testAccount2.Email_Opt_In_Language__c = 'German';
        testAccount2.Preferred_Language__c = 'de_DE';
        testAccount2.Email_Opt_In_Method__c = 'Via Email';
        testAccount2.Email_Pending_Opt_In__c = true;
        
        accountList.add(testAccount2);
        insert accountList;
        
        List<Lead> leadList= new List<Lead>();
        Lead testLead = TestUtils.testDEPersonLead();
        testLead.Email='jane.smith@sundog.net';
        testLead.Email_Opt_In_Language__c = 'German';
        testLead.Preferred_Language__c = 'de_DE';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Pending_Opt_In__c = true;
        leadList.add(testLead); 
        
        Lead testlead2 = TestUtils.testDEPersonLead();
        testLead2.Email_Opt_In_Language__c = 'German';
        testLead2.Preferred_Language__c = 'de_DE';
        testLead2.Email_Opt_In_Method__c = 'Via Email';
        testlead2.Email='john.smith@sundog.net';
        testlead2.Email_Pending_Opt_In__c = true;
        leadList.add(testlead2);
        insert leadList;
        
        Test.startTest();
        String jobId = System.schedule('testEmailScheduled', '0 0 0 3 9 ? 2052',
                new SclsDailyDoubleOptInEmailScheduled());
        Test.stopTest();
        
        System.assertEquals(false, String.isBlank(jobId));
    }
    
    @isTest
    static void testDEAccountOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Accounts to put trigger in bulk mode
        List<Account> accountList= new List<Account>();
        Account testAccount = TestUtils.testDEConsumerAccount();
        testAccount.PersonEmail = 'jane.smith@sundog.net';
        testAccount.Email_Pending_Opt_In__c = true;
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testAccount.Email_Opt_In_Language__c = 'German';
        testAccount.Preferred_Language__c = 'de_DE';
        testAccount.Email_Opt_In_Method__c = 'Via Web Form';
        accountList.add(testAccount);
        Account testAccount2 = TestUtils.testDEConsumerAccount();
        testAccount2.PersonEmail = 'jane.smith2@sundog.net';
        testAccount2.Email_Pending_Opt_In__c = true;
        testAccount2.Email_Opt_In_Language__c = 'German';
        testAccount2.Preferred_Language__c = 'de_DE';
        testAccount2.Email_Opt_In_Method__c = 'Via Web Form';
        accountList.add(testAccount2);
        Account testAccount3 = TestUtils.testDEConsumerAccount();
        testAccount3.PersonEmail = 'jane.smith3@sundog.net';
        testAccount3.Email_Pending_Opt_In__c = true;
        testAccount3.Email_Opt_In_Language__c = 'German';
        testAccount3.Preferred_Language__c = 'de_DE';
        testAccount3.Email_Opt_In_Method__c = 'Via Web Form';
        accountList.add(testAccount3);
        insert accountList;


        // query account record where double opt in pending is true
        Account resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Email_Pending_Opt_In__c = true and PersonEmail = 'jane.smith@sundog.net'];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultAccount1.PersonContactID));

        //Email_Opt_In_List__c field should be false at this point
        System.assertEquals(null, resultAccount1.Email_Opt_In_List__c);

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.DE_ACCOUNT);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 100);
        Test.stopTest();

        resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Id = :resultAccount1.Id];

        //Email_Pending_Opt_In__c field should be set to false at this point
        System.assertEquals(false, resultAccount1.Email_Pending_Opt_In__c);
        System.assertEquals('True', resultAccount1.Email_Opt_In_List__c);
    }

    @isTest
    static void testDELeadOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Leads to put trigger in bulk mode
        List<Lead> leadList= new List<Lead>();
        Lead testLead = TestUtils.testDEPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_Language__c = 'German';
        testLead.Preferred_Language__c = 'de_DE';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Pending_Opt_In__c = true;
        leadList.add(testLead);

        insert leadList;

        //query account record where double opt in penbding is true
        Lead resultLead1 = [SELECT id,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Lead where Email_Pending_Opt_In__c = true];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id));

        //Email_Opt_In_List__c field should be false at this point
        System.assertEquals(null,resultLead1.Email_Opt_In_List__c );

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.DE_Lead);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 2);
        Test.stopTest();

        resultLead1 = [SELECT Id,Email_Pending_Opt_In__c,Email_Opt_In_List__c, Email_Double_Opt_In_Subscriber__c FROM Lead where Id = :resultLead1.Id];

        //Email_Pending_Opt_In__c field should be set to false at this point
        System.assertEquals(false, resultLead1.Email_Pending_Opt_In__c);
        System.assertEquals('True', resultLead1.Email_Opt_In_List__c);


        //System.assertNotEquals(null, resultLead1.Email_Double_Opt_In_Subscriber__c);
    }

    @isTest
    static void testDEConvertedLead(){
        User salesUser = [SELECT Id FROM User WHERE Username = 'test@sundogtest.com'];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        Lead testLead = TestUtils.testDEPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Pending_Opt_In__c = true;
        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testLead.Email_Opt_In_Language__c = 'German';
        testLead.Preferred_Language__c = 'de_DE';
        testLead.Email_Opt_In_Method__c = 'Via Web Form';
        testLead.OwnerId = salesUser.Id;
        insert testLead;


        Database.LeadConvert lc;


        lc = new database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.convertedStatus = 'Qualified';
        lc.setDoNotCreateOpportunity(true);
        lc.setOwnerId(salesUser.Id);
        Database.LeadConvertResult lcr = Database.convertLead(lc, false);
        for(Database.Error e : lcr.getErrors()){
            System.debug(e);
        }
        //System.assertEquals(null, lcr.getErrors());
        System.assert(lcr.isSuccess());


        //query account record where double opt in penbding is true
        Lead resultLead1 = [SELECT Id, Email_Pending_Opt_In__c, Email_Opt_In_List__c, ConvertedAccountId FROM Lead where Email_Pending_Opt_In__c = true];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id));

        //Email_Opt_In_List__c field should be false at this point
        System.assertEquals(null,resultLead1.Email_Opt_In_List__c);
        System.assertNotEquals(null,resultLead1.ConvertedAccountId);

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.DE_LEAD);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 1);
        Test.stopTest();

        resultLead1 = [SELECT Id,Email_Pending_Opt_In__c,Email_Opt_In_List__c, ConvertedAccount.Email_Pending_Opt_In__c, ConvertedAccount.Email_Opt_In_List__c FROM Lead where Id = :resultLead1.Id];

        System.assertEquals(false, resultLead1.ConvertedAccount.Email_Pending_Opt_In__c);
        System.assertEquals('True', resultLead1.ConvertedAccount.Email_Opt_In_List__c);

    }

    @isTest
    static void testDELeadOptOut(){

        Lead testLead = TestUtils.testDEPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_List__c = 'True';
        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        insert testLead;

        //query account record where double opt in penbding is true
        Lead resultLead1 = [SELECT Id, Email_Pending_Opt_In__c, Email_Opt_In_List__c FROM Lead WHERE Id = :testLead.Id];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id, 'Unsubscribed'));

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.DE_LEAD);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 1);
        Test.stopTest();

        resultLead1 = [SELECT Id,Email_Pending_Opt_In__c,Email_Opt_In_List__c,Email_Double_Opt_In_Subscriber__c FROM Lead WHERE Id = :resultLead1.Id];

        System.assertEquals('False', resultLead1.Email_Opt_In_List__c);
        System.assertEquals(false, resultLead1.Email_Pending_Opt_In__c);
        System.assertEquals(null, resultLead1.Email_Double_Opt_In_Subscriber__c);
    }

    @isTest
    static void testDEAccountOptOut(){

        Account testAccount = TestUtils.testDEConsumerAccount();
        testAccount.PersonEmail = 'jane.smith@sundog.net';
        testAccount.Email_Opt_In_List__c = 'True';
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testAccount.Email_Opt_In_Language__c = 'German';
        testAccount.Preferred_Language__c = 'de_DE';
        testAccount.Email_Opt_In_Method__c = 'Via Web Form';

        insert testAccount;

        // query account record where double opt in penbding is true
        Account resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Id = :testAccount.Id];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultAccount1.PersonContactID, 'Unsubscribed'));

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.DE_ACCOUNT);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 100);
        Test.stopTest();

        resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c,Email_Double_Opt_In_Subscriber__c FROM Account where Id = :resultAccount1.Id];

        System.assertEquals('False', resultAccount1.Email_Opt_In_List__c);
        System.assertEquals(false, resultAccount1.Email_Pending_Opt_In__c);
        System.assertEquals(null, resultAccount1.Email_Double_Opt_In_Subscriber__c);
    }

    @isTest
    static void testCAAccountOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Accounts to put trigger in bulk mode
        List<Account> accountList= new List<Account>();
        Account testAccount = TestUtils.testCAConsumerAccount();
        testAccount.PersonEmail = 'jane.smith@sundog.net';
        testAccount.Email_Pending_Opt_In__c = true;
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testAccount.Email_Opt_In_Language__c = 'English';
        testAccount.Preferred_Language__c = 'en_CA';
        testAccount.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount);
        accountList.add(testAccount);
        Account testAccount2 = TestUtils.testCAConsumerAccount();
        testAccount2.PersonEmail = 'jane.smith2@sundog.net';
        testAccount2.Email_Pending_Opt_In__c = true;
        testAccount2.Email_Opt_In_Language__c = 'English';
        testAccount2.Preferred_Language__c = 'en_CA';
        testAccount2.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount2);
        accountList.add(testAccount2);
        Account testAccount3 = TestUtils.testCAConsumerAccount();
        testAccount3.PersonEmail = 'jane.smith3@sundog.net';
        testAccount3.Email_Pending_Opt_In__c = true;
        testAccount3.Email_Opt_In_Language__c = 'English';
        testAccount3.Preferred_Language__c = 'en_CA';
        testAccount3.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount3);
        accountList.add(testAccount3);
        insert accountList;


        // query account record where double opt in pending is true
        Account resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Email_Pending_Opt_In__c = true and PersonEmail = 'jane.smith@sundog.net'];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultAccount1.PersonContactID));

        //Email_Opt_In_List__c field should be false at this point
        System.assertEquals(null, resultAccount1.Email_Opt_In_List__c);

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.CA_ACCOUNT);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 100);
        Test.stopTest();

        resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Id = :resultAccount1.Id];

        //Email_Pending_Opt_In__c field should be set to false at this point
        System.assertEquals(false, resultAccount1.Email_Pending_Opt_In__c);
        System.assertEquals('True', resultAccount1.Email_Opt_In_List__c);
    }

    @isTest
    static void testCALeadOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Leads to put trigger in bulk mode
        List<Lead> leadList= new List<Lead>();
        Lead testLead = TestUtils.testCAPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Preferred_Language__c = 'en_CA';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Pending_Opt_In__c = true;
        leadList.add(testLead);

        insert leadList;

        //query account record where double opt in pending is true
        Lead resultLead1 = [SELECT id,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Lead where Email_Pending_Opt_In__c = true];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id));

        //Email_Opt_In_List__c field should be false at this point
        System.assertEquals(null,resultLead1.Email_Opt_In_List__c );

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.CA_LEAD);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 2);
        Test.stopTest();

        resultLead1 = [SELECT Id,Email_Pending_Opt_In__c,Email_Opt_In_List__c, Email_Double_Opt_In_Subscriber__c FROM Lead where Id = :resultLead1.Id];

        //Email_Pending_Opt_In__c field should be set to false at this point
        System.assertEquals(false, resultLead1.Email_Pending_Opt_In__c);
        System.assertEquals('True', resultLead1.Email_Opt_In_List__c);


        //System.assertNotEquals(null, resultLead1.Email_Double_Opt_In_Subscriber__c);
    }

//    @isTest
//    static void testCAConvertedLead(){
//        User salesUser = [SELECT Id FROM User WHERE Username = 'test@sundogtest.com'];
//        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
//        Lead testLead = TestUtils.testCAPersonLead();
//        testLead.Email = 'jane.smith@sundog.net';
//        testLead.Email_Pending_Opt_In__c = true;
//        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
//        testLead.Email_Opt_In_Language__c = 'English';
//        testLead.Email_Opt_In_Method__c = 'Via Web Form';
//        testLead.OwnerId = salesUser.Id;
//        insert testLead;
//
//
//        Database.LeadConvert lc;
//
//
//        lc = new database.LeadConvert();
//        lc.setLeadId(testLead.Id);
//        lc.convertedStatus = 'Qualified';
//        lc.setDoNotCreateOpportunity(true);
//        lc.setOwnerId(salesUser.Id);
//        Database.LeadConvertResult lcr = Database.convertLead(lc, false);
//        for(Database.Error e : lcr.getErrors()){
//            System.debug(e);
//        }
//        //System.assertEquals(null, lcr.getErrors());
//        System.assert(lcr.isSuccess());
//
//
//        //query account record where double opt in pending is true
//        Lead resultLead1 = [SELECT Id, Email_Pending_Opt_In__c, Email_Opt_In_List__c, ConvertedAccountId FROM Lead where Email_Pending_Opt_In__c = true];
//        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id));
//
//        //Email_Opt_In_List__c field should be false at this point
//        System.assertEquals(null,resultLead1.Email_Opt_In_List__c);
//        System.assertNotEquals(null,resultLead1.ConvertedAccountId);
//
//        //Run batch job
//        Test.startTest();
//        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.CA_LEAD);
//        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 1);
//        Test.stopTest();
//
//        resultLead1 = [SELECT Id,Email_Pending_Opt_In__c,Email_Opt_In_List__c, ConvertedAccount.Email_Pending_Opt_In__c, ConvertedAccount.Email_Opt_In_List__c FROM Lead where Id = :resultLead1.Id];
//
//        System.assertEquals(false, resultLead1.ConvertedAccount.Email_Pending_Opt_In__c);
//        System.assertEquals('True', resultLead1.ConvertedAccount.Email_Opt_In_List__c);
//
//    }

    @isTest
    static void testCALeadOptOut(){

        Lead testLead = TestUtils.testCAPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_List__c = 'True';
        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        insert testLead;

        //query account record where double opt in penbding is true
        Lead resultLead1 = [SELECT Id, Email_Pending_Opt_In__c, Email_Opt_In_List__c FROM Lead WHERE Id = :testLead.Id];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id, 'Unsubscribed'));

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.CA_LEAD);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 1);
        Test.stopTest();

        resultLead1 = [SELECT Id,Email_Pending_Opt_In__c,Email_Opt_In_List__c,Email_Double_Opt_In_Subscriber__c FROM Lead WHERE Id = :resultLead1.Id];

        System.assertEquals('False', resultLead1.Email_Opt_In_List__c);
        System.assertEquals(false, resultLead1.Email_Pending_Opt_In__c);
        System.assertEquals(null, resultLead1.Email_Double_Opt_In_Subscriber__c);
    }

    @isTest
    static void testCAAccountOptOut(){

        Account testAccount = TestUtils.testCAConsumerAccount();
        testAccount.PersonEmail = 'jane.smith@sundog.net';
        testAccount.Email_Opt_In_List__c = 'True';
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testAccount.Email_Opt_In_Language__c = 'English';
        testAccount.Preferred_Language__c = 'en_CA';
        testAccount.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount);

        insert testAccount;

        // query account record where double opt in penbding is true
        Account resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Id = :testAccount.Id];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultAccount1.PersonContactID, 'Unsubscribed'));

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.CA_ACCOUNT);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 100);
        Test.stopTest();

        resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c,Email_Double_Opt_In_Subscriber__c FROM Account where Id = :resultAccount1.Id];

        System.assertEquals('False', resultAccount1.Email_Opt_In_List__c);
        System.assertEquals(false, resultAccount1.Email_Pending_Opt_In__c);
        System.assertEquals(null, resultAccount1.Email_Double_Opt_In_Subscriber__c);
    }

    
    
     @isTest
    static void testGBAccountOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Accounts to put trigger in bulk mode
        List<Account> accountList= new List<Account>();
        Account testAccount = TestUtils.testGBConsumerAccount();
        testAccount.PersonEmail = 'jane.smith@sundog.net';
        testAccount.Email_Pending_Opt_In__c = true;
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testAccount.Email_Opt_In_Language__c = 'English';
        testAccount.Preferred_Language__c = 'en_GB';
        testAccount.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount);
        accountList.add(testAccount);
        Account testAccount2 = TestUtils.testGBConsumerAccount();
        testAccount2.PersonEmail = 'jane.smith2@sundog.net';
        testAccount2.Email_Pending_Opt_In__c = true;
        testAccount2.Email_Opt_In_Language__c = 'English';
        testAccount2.Preferred_Language__c = 'en_GB';
        testAccount2.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount2);
        accountList.add(testAccount2);
        Account testAccount3 = TestUtils.testGBConsumerAccount();
        testAccount3.PersonEmail = 'jane.smith3@sundog.net';
        testAccount3.Email_Pending_Opt_In__c = true;
        testAccount3.Email_Opt_In_Language__c = 'English';
        testAccount3.Preferred_Language__c = 'en_GB';
        testAccount3.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount3);
        accountList.add(testAccount3);
        insert accountList;


        // query account record where double opt in pending is true
        Account resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Email_Pending_Opt_In__c = true and PersonEmail = 'jane.smith@sundog.net'];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultAccount1.PersonContactID));

        //Email_Opt_In_List__c field should be false at this point
        System.assertEquals(null, resultAccount1.Email_Opt_In_List__c);

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.GB_IE_ACCOUNT);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 100);
        Test.stopTest();

        resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Id = :resultAccount1.Id];

        //Email_Pending_Opt_In__c field should be set to false at this point
        System.assertEquals(false, resultAccount1.Email_Pending_Opt_In__c);
        System.assertEquals('True', resultAccount1.Email_Opt_In_List__c);
    }

    @isTest
    static void testGBLeadOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Leads to put trigger in bulk mode
        List<Lead> leadList= new List<Lead>();
        Lead testLead = TestUtils.testGBPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Preferred_Language__c = 'en_GB';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Pending_Opt_In__c = true;
        leadList.add(testLead);

        insert leadList;

        //query account record where double opt in pending is true
        Lead resultLead1 = [SELECT id,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Lead where Email_Pending_Opt_In__c = true];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id));

        //Email_Opt_In_List__c field should be false at this point
        System.assertEquals(null,resultLead1.Email_Opt_In_List__c );

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.GB_IE_LEAD);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 2);
        Test.stopTest();

        resultLead1 = [SELECT Id,Email_Pending_Opt_In__c,Email_Opt_In_List__c, Email_Double_Opt_In_Subscriber__c FROM Lead where Id = :resultLead1.Id];

        //Email_Pending_Opt_In__c field should be set to false at this point
        System.assertEquals(false, resultLead1.Email_Pending_Opt_In__c);
        System.assertEquals('True', resultLead1.Email_Opt_In_List__c);


        //System.assertNotEquals(null, resultLead1.Email_Double_Opt_In_Subscriber__c);
    }


    @isTest
    static void testGBLeadOptOut(){

        Lead testLead = TestUtils.testGBPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_List__c = 'True';
        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        insert testLead;

        //query account record where double opt in penbding is true
        Lead resultLead1 = [SELECT Id, Email_Pending_Opt_In__c, Email_Opt_In_List__c FROM Lead WHERE Id = :testLead.Id];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id, 'Unsubscribed'));

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.GB_IE_LEAD);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 1);
        Test.stopTest();

        resultLead1 = [SELECT Id,Email_Pending_Opt_In__c,Email_Opt_In_List__c,Email_Double_Opt_In_Subscriber__c FROM Lead WHERE Id = :resultLead1.Id];

        System.assertEquals('False', resultLead1.Email_Opt_In_List__c);
        System.assertEquals(false, resultLead1.Email_Pending_Opt_In__c);
        System.assertEquals(null, resultLead1.Email_Double_Opt_In_Subscriber__c);
    }

    @isTest
    static void testGBAccountOptOut(){

        Account testAccount = TestUtils.testGBConsumerAccount();
        testAccount.PersonEmail = 'jane.smith@sundog.net';
        testAccount.Email_Opt_In_List__c = 'True';
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testAccount.Email_Opt_In_Language__c = 'English';
        testAccount.Preferred_Language__c = 'en_GB';
        testAccount.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount);

        insert testAccount;

        // query account record where double opt in penbding is true
        Account resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Id = :testAccount.Id];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultAccount1.PersonContactID, 'Unsubscribed'));

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.GB_IE_ACCOUNT);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 100);
        Test.stopTest();

        resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c,Email_Double_Opt_In_Subscriber__c FROM Account where Id = :resultAccount1.Id];

        System.assertEquals('False', resultAccount1.Email_Opt_In_List__c);
        System.assertEquals(false, resultAccount1.Email_Pending_Opt_In__c);
        System.assertEquals(null, resultAccount1.Email_Double_Opt_In_Subscriber__c);
    }
    
    
    
    
         @isTest
    static void testIEAccountOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Accounts to put trigger in bulk mode
        List<Account> accountList= new List<Account>();
        Account testAccount = TestUtils.testIEConsumerAccount();
        testAccount.PersonEmail = 'jane.smith@sundog.net';
        testAccount.Email_Pending_Opt_In__c = true;
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testAccount.Email_Opt_In_Language__c = 'English';
        testAccount.Preferred_Language__c = 'en_IE';
        testAccount.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount);
        accountList.add(testAccount);
        Account testAccount2 = TestUtils.testIEConsumerAccount();
        testAccount2.PersonEmail = 'jane.smith2@sundog.net';
        testAccount2.Email_Pending_Opt_In__c = true;
        testAccount2.Email_Opt_In_Language__c = 'English';
        testAccount2.Preferred_Language__c = 'en_IE';
        testAccount2.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount2);
        accountList.add(testAccount2);
        Account testAccount3 = TestUtils.testIEConsumerAccount();
        testAccount3.PersonEmail = 'jane.smith3@sundog.net';
        testAccount3.Email_Pending_Opt_In__c = true;
        testAccount3.Email_Opt_In_Language__c = 'English';
        testAccount3.Preferred_Language__c = 'en_IE';
        testAccount3.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount3);
        accountList.add(testAccount3);
        insert accountList;


        // query account record where double opt in pending is true
        Account resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Email_Pending_Opt_In__c = true and PersonEmail = 'jane.smith@sundog.net'];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultAccount1.PersonContactID));

        //Email_Opt_In_List__c field should be false at this point
        System.assertEquals(null, resultAccount1.Email_Opt_In_List__c);

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.GB_IE_ACCOUNT);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 100);
        Test.stopTest();

        resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Id = :resultAccount1.Id];

        //Email_Pending_Opt_In__c field should be set to false at this point
        System.assertEquals(false, resultAccount1.Email_Pending_Opt_In__c);
        System.assertEquals('True', resultAccount1.Email_Opt_In_List__c);
    }

    @isTest
    static void testIELeadOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Leads to put trigger in bulk mode
        List<Lead> leadList= new List<Lead>();
        Lead testLead = TestUtils.testIEPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Preferred_Language__c = 'en_IE';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Pending_Opt_In__c = true;
        leadList.add(testLead);

        insert leadList;

        //query account record where double opt in pending is true
        Lead resultLead1 = [SELECT id,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Lead where Email_Pending_Opt_In__c = true];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id));

        //Email_Opt_In_List__c field should be false at this point
        System.assertEquals(null,resultLead1.Email_Opt_In_List__c );

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.GB_IE_LEAD);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 2);
        Test.stopTest();

        resultLead1 = [SELECT Id,Email_Pending_Opt_In__c,Email_Opt_In_List__c, Email_Double_Opt_In_Subscriber__c FROM Lead where Id = :resultLead1.Id];

        //Email_Pending_Opt_In__c field should be set to false at this point
        System.assertEquals(false, resultLead1.Email_Pending_Opt_In__c);
        System.assertEquals('True', resultLead1.Email_Opt_In_List__c);


        //System.assertNotEquals(null, resultLead1.Email_Double_Opt_In_Subscriber__c);
    }


    @isTest
    static void testIELeadOptOut(){

        Lead testLead = TestUtils.testIEPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_List__c = 'True';
        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        insert testLead;

        //query account record where double opt in penbding is true
        Lead resultLead1 = [SELECT Id, Email_Pending_Opt_In__c, Email_Opt_In_List__c FROM Lead WHERE Id = :testLead.Id];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id, 'Unsubscribed'));

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.GB_IE_LEAD);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 1);
        Test.stopTest();

        resultLead1 = [SELECT Id,Email_Pending_Opt_In__c,Email_Opt_In_List__c,Email_Double_Opt_In_Subscriber__c FROM Lead WHERE Id = :resultLead1.Id];

        System.assertEquals('False', resultLead1.Email_Opt_In_List__c);
        System.assertEquals(false, resultLead1.Email_Pending_Opt_In__c);
        System.assertEquals(null, resultLead1.Email_Double_Opt_In_Subscriber__c);
    }

    @isTest
    static void testIEAccountOptOut(){

        Account testAccount = TestUtils.testIEConsumerAccount();
        testAccount.PersonEmail = 'jane.smith@sundog.net';
        testAccount.Email_Opt_In_List__c = 'True';
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testAccount.Email_Opt_In_Language__c = 'English';
        testAccount.Preferred_Language__c = 'en_IE';
        testAccount.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount);

        insert testAccount;

        // query account record where double opt in penbding is true
        Account resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Id = :testAccount.Id];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultAccount1.PersonContactID, 'Unsubscribed'));

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.GB_IE_ACCOUNT);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 100);
        Test.stopTest();

        resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c,Email_Double_Opt_In_Subscriber__c FROM Account where Id = :resultAccount1.Id];

        System.assertEquals('False', resultAccount1.Email_Opt_In_List__c);
        System.assertEquals(false, resultAccount1.Email_Pending_Opt_In__c);
        System.assertEquals(null, resultAccount1.Email_Double_Opt_In_Subscriber__c);
    }
    
    
       
     @isTest
    static void testATAccountOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Accounts to put trigger in bulk mode
        List<Account> accountList= new List<Account>();
        Account testAccount = TestUtils.testATConsumerAccount();
        testAccount.PersonEmail = 'jane.smith@sundog.net';
        testAccount.Email_Pending_Opt_In__c = true;
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testAccount.Email_Opt_In_Language__c = 'German';
        testAccount.Preferred_Language__c = 'de_AT';
        testAccount.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount);
        accountList.add(testAccount);
        Account testAccount2 = TestUtils.testATConsumerAccount();
        testAccount2.PersonEmail = 'jane.smith2@sundog.net';
        testAccount2.Email_Pending_Opt_In__c = true;
        testAccount2.Email_Opt_In_Language__c = 'German';
        testAccount2.Preferred_Language__c = 'de_AT';
        testAccount2.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount2);
        accountList.add(testAccount2);
        Account testAccount3 = TestUtils.testATConsumerAccount();
        testAccount3.PersonEmail = 'jane.smith3@sundog.net';
        testAccount3.Email_Pending_Opt_In__c = true;
        testAccount3.Email_Opt_In_Language__c = 'German';
        testAccount3.Preferred_Language__c = 'de_AT';
        testAccount3.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount3);
        accountList.add(testAccount3);
        insert accountList;


        // query account record where double opt in pending is true
        Account resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Email_Pending_Opt_In__c = true and PersonEmail = 'jane.smith@sundog.net'];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultAccount1.PersonContactID));

        //Email_Opt_In_List__c field should be false at this point
        System.assertEquals(null, resultAccount1.Email_Opt_In_List__c);

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.AT_CH_ACCOUNT);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 100);
        Test.stopTest();

        resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Id = :resultAccount1.Id];

        //Email_Pending_Opt_In__c field should be set to false at this point
        System.assertEquals(false, resultAccount1.Email_Pending_Opt_In__c);
        System.assertEquals('True', resultAccount1.Email_Opt_In_List__c);
    }

    @isTest
    static void testATLeadOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Leads to put trigger in bulk mode
        List<Lead> leadList= new List<Lead>();
        Lead testLead = TestUtils.testATPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Preferred_Language__c = 'de_AT';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Pending_Opt_In__c = true;
        leadList.add(testLead);

        insert leadList;

        //query account record where double opt in pending is true
        Lead resultLead1 = [SELECT id,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Lead where Email_Pending_Opt_In__c = true];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id));

        //Email_Opt_In_List__c field should be false at this point
        System.assertEquals(null,resultLead1.Email_Opt_In_List__c );

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.AT_CH_LEAD);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 2);
        Test.stopTest();

        resultLead1 = [SELECT Id,Email_Pending_Opt_In__c,Email_Opt_In_List__c, Email_Double_Opt_In_Subscriber__c FROM Lead where Id = :resultLead1.Id];

        //Email_Pending_Opt_In__c field should be set to false at this point
        System.assertEquals(false, resultLead1.Email_Pending_Opt_In__c);
        System.assertEquals('True', resultLead1.Email_Opt_In_List__c);


        //System.assertNotEquals(null, resultLead1.Email_Double_Opt_In_Subscriber__c);
    }


    @isTest
    static void testATLeadOptOut(){

        Lead testLead = TestUtils.testATPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_List__c = 'True';
        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        insert testLead;

        //query account record where double opt in penbding is true
        Lead resultLead1 = [SELECT Id, Email_Pending_Opt_In__c, Email_Opt_In_List__c FROM Lead WHERE Id = :testLead.Id];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id, 'Unsubscribed'));

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.AT_CH_LEAD);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 1);
        Test.stopTest();

        resultLead1 = [SELECT Id,Email_Pending_Opt_In__c,Email_Opt_In_List__c,Email_Double_Opt_In_Subscriber__c FROM Lead WHERE Id = :resultLead1.Id];

        System.assertEquals('False', resultLead1.Email_Opt_In_List__c);
        System.assertEquals(false, resultLead1.Email_Pending_Opt_In__c);
        System.assertEquals(null, resultLead1.Email_Double_Opt_In_Subscriber__c);
    }

    @isTest
    static void testATAccountOptOut(){

        Account testAccount = TestUtils.testATConsumerAccount();
        testAccount.PersonEmail = 'jane.smith@sundog.net';
        testAccount.Email_Opt_In_List__c = 'True';
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testAccount.Email_Opt_In_Language__c = 'German';
        testAccount.Preferred_Language__c = 'de_AT';
        testAccount.Email_Opt_In_Method__c = 'Via Web Form';
        setAddress(testAccount);

        insert testAccount;

        // query account record where double opt in penbding is true
        Account resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Id = :testAccount.Id];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultAccount1.PersonContactID, 'Unsubscribed'));

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.AT_CH_ACCOUNT);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 100);
        Test.stopTest();

        resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c,Email_Double_Opt_In_Subscriber__c FROM Account where Id = :resultAccount1.Id];

        System.assertEquals('False', resultAccount1.Email_Opt_In_List__c);
        System.assertEquals(false, resultAccount1.Email_Pending_Opt_In__c);
        System.assertEquals(null, resultAccount1.Email_Double_Opt_In_Subscriber__c);
    }
    
    
    
    
         @isTest
    static void testCHAccountOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Accounts to put trigger in bulk mode
        List<Account> accountList= new List<Account>();
        Account testAccount = TestUtils.testCHConsumerAccount();
        testAccount.PersonEmail = 'jane.smith@sundog.net';
        testAccount.Email_Pending_Opt_In__c = true;
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testAccount.Email_Opt_In_Language__c = 'German';
        testAccount.Preferred_Language__c = 'de_CH';
        testAccount.Email_Opt_In_Method__c = 'Via Web Form';
        accountList.add(testAccount);
        Account testAccount2 = TestUtils.testCHConsumerAccount();
        testAccount2.PersonEmail = 'jane.smith2@sundog.net';
        testAccount2.Email_Pending_Opt_In__c = true;
        testAccount2.Email_Opt_In_Language__c = 'German';
        testAccount.Preferred_Language__c = 'de_CH';
        testAccount2.Email_Opt_In_Method__c = 'Via Web Form';
        accountList.add(testAccount2);
        Account testAccount3 = TestUtils.testCHConsumerAccount();
        testAccount3.PersonEmail = 'jane.smith3@sundog.net';
        testAccount3.Email_Pending_Opt_In__c = true;
        testAccount3.Email_Opt_In_Language__c = 'German';
        testAccount3.Preferred_Language__c = 'de_CH';
        testAccount3.Email_Opt_In_Method__c = 'Via Web Form';
        accountList.add(testAccount3);
        insert accountList;


        // query account record where double opt in pending is true
        Account resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Email_Pending_Opt_In__c = true and PersonEmail = 'jane.smith@sundog.net'];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultAccount1.PersonContactID));

        //Email_Opt_In_List__c field should be false at this point
        System.assertEquals(null, resultAccount1.Email_Opt_In_List__c);

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.AT_CH_ACCOUNT);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 100);
        Test.stopTest();

        resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Id = :resultAccount1.Id];

        //Email_Pending_Opt_In__c field should be set to false at this point
        System.assertEquals(false, resultAccount1.Email_Pending_Opt_In__c);
        System.assertEquals('True', resultAccount1.Email_Opt_In_List__c);
    }

    @isTest
    static void testCHLeadOptIn(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());

        //Create 2 Test Leads to put trigger in bulk mode
        List<Lead> leadList= new List<Lead>();
        Lead testLead = TestUtils.testCHPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_Language__c = 'German';
        testLead.Preferred_Language__c = 'de_CH';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Pending_Opt_In__c = true;
        leadList.add(testLead);

        insert leadList;

        //query account record where double opt in pending is true
        Lead resultLead1 = [SELECT id,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Lead where Email_Pending_Opt_In__c = true];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id));

        //Email_Opt_In_List__c field should be false at this point
        System.assertEquals(null,resultLead1.Email_Opt_In_List__c );

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.AT_CH_LEAD);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 2);
        Test.stopTest();

        resultLead1 = [SELECT Id,Email_Pending_Opt_In__c,Email_Opt_In_List__c, Email_Double_Opt_In_Subscriber__c FROM Lead where Id = :resultLead1.Id];

        //Email_Pending_Opt_In__c field should be set to false at this point
        System.assertEquals(false, resultLead1.Email_Pending_Opt_In__c);
        System.assertEquals('True', resultLead1.Email_Opt_In_List__c);


        //System.assertNotEquals(null, resultLead1.Email_Double_Opt_In_Subscriber__c);
    }


    @isTest
    static void testCHLeadOptOut(){

        Lead testLead = TestUtils.testCHPersonLead();
        testLead.Email = 'jane.smith@sundog.net';
        testLead.Email_Opt_In_List__c = 'True';
        testLead.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        insert testLead;

        //query account record where double opt in penbding is true
        Lead resultLead1 = [SELECT Id, Email_Pending_Opt_In__c, Email_Opt_In_List__c FROM Lead WHERE Id = :testLead.Id];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultLead1.Id, 'Unsubscribed'));

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.AT_CH_LEAD);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 1);
        Test.stopTest();

        resultLead1 = [SELECT Id,Email_Pending_Opt_In__c,Email_Opt_In_List__c,Email_Double_Opt_In_Subscriber__c FROM Lead WHERE Id = :resultLead1.Id];

        System.assertEquals('False', resultLead1.Email_Opt_In_List__c);
        System.assertEquals(false, resultLead1.Email_Pending_Opt_In__c);
        System.assertEquals(null, resultLead1.Email_Double_Opt_In_Subscriber__c);
    }

    @isTest
    static void testCHAccountOptOut(){

        Account testAccount = TestUtils.testCHConsumerAccount();
        testAccount.PersonEmail = 'jane.smith@sundog.net';
        testAccount.Email_Opt_In_List__c = 'True';
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        testAccount.Email_Opt_In_Language__c = 'German';
        testAccount.Preferred_Language__c = 'de_CH';
        testAccount.Email_Opt_In_Method__c = 'Via Web Form';

        insert testAccount;

        // query account record where double opt in penbding is true
        Account resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c FROM Account where Id = :testAccount.Id];
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock(resultAccount1.PersonContactID, 'Unsubscribed'));

        //Run batch job
        Test.startTest();
        BclsDailyDoubleOptInEmailBatch dailyEmailBatch = new BclsDailyDoubleOptInEmailBatch(BclsDailyDoubleOptInEmailBatch.BatchType.AT_CH_ACCOUNT);
        Id batchInstanceId = Database.executeBatch(dailyEmailBatch, 100);
        Test.stopTest();

        resultAccount1 = [SELECT PersonContactID,Email_Pending_Opt_In__c,Email_Opt_In_List__c,Email_Double_Opt_In_Subscriber__c FROM Account where Id = :resultAccount1.Id];

        System.assertEquals('False', resultAccount1.Email_Opt_In_List__c);
        System.assertEquals(false, resultAccount1.Email_Pending_Opt_In__c);
        System.assertEquals(null, resultAccount1.Email_Double_Opt_In_Subscriber__c);
    }
    private static void setAddress(Account account) {
        account.BillingPostalCode = 'V6B 4E1';
        account.ShippingPostalCode = 'V6B 4E1';
    }
}