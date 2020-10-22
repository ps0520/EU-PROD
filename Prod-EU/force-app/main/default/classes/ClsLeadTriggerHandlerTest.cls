@isTest
private class ClsLeadTriggerHandlerTest {
    
    @isTest
    static void testDoubleOptInResetDE(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        Lead testLead = TestUtils.testDEPersonLead();
        testLead.Email_Opt_In_Language__c = 'German';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Double_Opt_In_Subscriber__c=Datetime.now();
        insert testLead;
        
        //email address change
        testLead.Email='Test2@gmail.com';
        
        Test.startTest();
        update testLead;
        Lead resultLead=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Lead];
        System.assertEquals(true,resultLead.Email_Pending_Opt_In__c);
        System.assertEquals(null,resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(true,resultLead.Email_Pending_Opt_In_Reset__c);
        Test.stopTest();
        
        resultLead=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Lead];
        System.assertEquals(true,resultLead.Email_Pending_Opt_In__c);
        System.assertNotEquals(null,resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false,resultLead.Email_Pending_Opt_In_Reset__c);
    }

    @isTest
    static void testDoubleOptInResetCA(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        Lead testLead = TestUtils.testCAPersonLead();
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Double_Opt_In_Subscriber__c=Datetime.now();
        insert testLead;
        
        //email address change
        testLead.Email='Test2@gmail.com';
        
        Test.startTest();
        update testLead;
        Lead resultLead=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Lead];
        System.assertEquals(true,resultLead.Email_Pending_Opt_In__c);
        System.assertEquals(null,resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(true,resultLead.Email_Pending_Opt_In_Reset__c);
        Test.stopTest();
        
        resultLead=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Lead];
        System.assertEquals(true,resultLead.Email_Pending_Opt_In__c);
        System.assertNotEquals(null,resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false,resultLead.Email_Pending_Opt_In_Reset__c);
    }
      @isTest
    static void testDoubleOptInResetGB(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        Lead testLead = TestUtils.testGBPersonLead();
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Double_Opt_In_Subscriber__c=Datetime.now();
        insert testLead;
        
        //email address change
        testLead.Email='Test2@gmail.com';
        
        Test.startTest();
        update testLead;
        Lead resultLead=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Lead];
        System.assertEquals(true,resultLead.Email_Pending_Opt_In__c);
        System.assertEquals(null,resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(true,resultLead.Email_Pending_Opt_In_Reset__c);
        Test.stopTest();
        
        resultLead=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Lead];
        System.assertEquals(true,resultLead.Email_Pending_Opt_In__c);
        System.assertNotEquals(null,resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false,resultLead.Email_Pending_Opt_In_Reset__c);
    }
     @isTest
    static void testDoubleOptInResetIE(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        Lead testLead = TestUtils.testIEPersonLead();
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Double_Opt_In_Subscriber__c=Datetime.now();
        insert testLead;
        
        //email address change
        testLead.Email='Test2@gmail.com';
        
        Test.startTest();
        update testLead;
        Lead resultLead=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Lead];
        System.assertEquals(true,resultLead.Email_Pending_Opt_In__c);
        System.assertEquals(null,resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(true,resultLead.Email_Pending_Opt_In_Reset__c);
        Test.stopTest();
        
        resultLead=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Lead];
        System.assertEquals(true,resultLead.Email_Pending_Opt_In__c);
        System.assertNotEquals(null,resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false,resultLead.Email_Pending_Opt_In_Reset__c);
    }
    
    
    @isTest
    static void testDoubleOptInResetAT(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        Lead testLead = TestUtils.testATPersonLead();
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Double_Opt_In_Subscriber__c=Datetime.now();
        insert testLead;
        
        //email address change
        testLead.Email='Test2@gmail.com';
        
        Test.startTest();
        update testLead;
        Lead resultLead=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Lead];
        System.assertEquals(true,resultLead.Email_Pending_Opt_In__c);
        System.assertEquals(null,resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(true,resultLead.Email_Pending_Opt_In_Reset__c);
        Test.stopTest();
        
        resultLead=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Lead];
        System.assertEquals(true,resultLead.Email_Pending_Opt_In__c);
        System.assertNotEquals(null,resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false,resultLead.Email_Pending_Opt_In_Reset__c);
    }
     @isTest
    static void testDoubleOptInResetCH(){
        Test.setMock(HttpCalloutMock.class, new ClsMarketingCloudHelperEmailMock());
        Lead testLead = TestUtils.testCHPersonLead();
        testLead.Email_Opt_In_Language__c = 'English';
        testLead.Email_Opt_In_Method__c = 'Via Email';
        testLead.Email_Double_Opt_In_Subscriber__c=Datetime.now();
        insert testLead;
        
        //email address change
        testLead.Email='Test2@gmail.com';
        
        Test.startTest();
        update testLead;
        Lead resultLead=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Lead];
        System.assertEquals(true,resultLead.Email_Pending_Opt_In__c);
        System.assertEquals(null,resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(true,resultLead.Email_Pending_Opt_In_Reset__c);
        Test.stopTest();
        
        resultLead=[SELECT Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c, Email_Pending_Opt_In_Reset__c FROM Lead];
        System.assertEquals(true,resultLead.Email_Pending_Opt_In__c);
        System.assertNotEquals(null,resultLead.Email_Double_Opt_In_Subscriber__c);
        System.assertEquals(false,resultLead.Email_Pending_Opt_In_Reset__c);
    }
}