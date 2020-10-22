@isTest
private class ClsAccountDoubleOptInTriggerHandlerTest {
    
    @isTest
    static void testDoubleOptInResetDE(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        Account testAccount = TestUtils.testDEConsumerAccount();
        testAccount.Email_Opt_In_Language__c = 'German';
        testAccount.Email_Opt_In_Method__c = 'Via Email';
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        
        insert testAccount;
        
        //email address change
        testAccount.PersonEmail='Test2@gmail.com';
        
        Test.startTest();
        update testAccount;
        Account resultAccount=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Account];
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In__c);
        System.assertEquals(null,resultAccount.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In_Reset__c);
        Test.stopTest();
        
        resultAccount=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Account];
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In__c);
        System.assertNotEquals(null,resultAccount.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false,resultAccount.Email_Pending_Opt_In_Reset__c);
        
    }

     @isTest
    static void testDoubleOptInResetCA(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        Account testAccount = TestUtils.testCAConsumerAccount();
        testAccount.Email_Opt_In_Language__c = 'English';
        testAccount.Email_Opt_In_Method__c = 'Via Email';
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        
        insert testAccount;
        
        //email address change
        testAccount.PersonEmail='Test2@gmail.com';
        
        Test.startTest();
        update testAccount;
        Account resultAccount=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Account];
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In__c);
        System.assertEquals(null,resultAccount.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In_Reset__c);
        Test.stopTest();
        
        resultAccount=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Account];
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In__c);
        System.assertNotEquals(null,resultAccount.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false,resultAccount.Email_Pending_Opt_In_Reset__c);
    }
    @isTest
    static void testDoubleOptInResetGB(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        Account testAccount = TestUtils.testGBConsumerAccount();
        testAccount.Email_Opt_In_Language__c = 'English';
        testAccount.Email_Opt_In_Method__c = 'Via Email';
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        
        insert testAccount;
        
        //email address change
        testAccount.PersonEmail='Test2@gmail.com';
        
        Test.startTest();
        update testAccount;
        Account resultAccount=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Account];
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In__c);
        System.assertEquals(null,resultAccount.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In_Reset__c);
        Test.stopTest();
        
        resultAccount=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Account];
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In__c);
        System.assertNotEquals(null,resultAccount.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false,resultAccount.Email_Pending_Opt_In_Reset__c);
    }
    @isTest
    static void testDoubleOptInResetIE(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        Account testAccount = TestUtils.testIEConsumerAccount();
        testAccount.Email_Opt_In_Language__c = 'English';
        testAccount.Email_Opt_In_Method__c = 'Via Email';
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        
        insert testAccount;
        
        //email address change
        testAccount.PersonEmail='Test2@gmail.com';
        
        Test.startTest();
        update testAccount;
        Account resultAccount=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Account];
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In__c);
        System.assertEquals(null,resultAccount.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In_Reset__c);
        Test.stopTest();
        
        resultAccount=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Account];
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In__c);
        System.assertNotEquals(null,resultAccount.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false,resultAccount.Email_Pending_Opt_In_Reset__c);
    }
    
    @isTest
    static void testDoubleOptInResetAT(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        Account testAccount = TestUtils.testATConsumerAccount();
        testAccount.Email_Opt_In_Language__c = 'German';
        testAccount.Email_Opt_In_Method__c = 'Via Email';
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        
        insert testAccount;
        
        //email address change
        testAccount.PersonEmail='Test2@gmail.com';
        
        Test.startTest();
        update testAccount;
        Account resultAccount=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Account];
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In__c);
        System.assertEquals(null,resultAccount.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In_Reset__c);
        Test.stopTest();
        
        resultAccount=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Account];
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In__c);
        System.assertNotEquals(null,resultAccount.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false,resultAccount.Email_Pending_Opt_In_Reset__c);
    }
    @isTest
    static void testDoubleOptInResetCH(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        Account testAccount = TestUtils.testCHConsumerAccount();
        testAccount.Email_Opt_In_Language__c = 'German';
        testAccount.Email_Opt_In_Method__c = 'Via Email';
        testAccount.Email_Double_Opt_In_Subscriber__c = Datetime.now();
        
        insert testAccount;
        
        //email address change
        testAccount.PersonEmail='Test2@gmail.com';
        
        Test.startTest();
        update testAccount;
        Account resultAccount=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Account];
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In__c);
        System.assertEquals(null,resultAccount.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In_Reset__c);
        Test.stopTest();
        
        resultAccount=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Account];
        System.assertEquals(true,resultAccount.Email_Pending_Opt_In__c);
        System.assertNotEquals(null,resultAccount.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false,resultAccount.Email_Pending_Opt_In_Reset__c);
    }
}