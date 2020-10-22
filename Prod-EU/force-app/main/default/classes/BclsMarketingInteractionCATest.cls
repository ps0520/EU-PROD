@isTest()
public class BclsMarketingInteractionCATest {
@isTest
    static void testHourlyEmailScheduledJob() {
        //insert TestDataBuilder.testURLExpiryVal();

        List<Account> accountList= new List<Account>();
        Date ninetyDate= date.today().adddays(-95);
        Account testAccount = TestUtils.testCAConsumerAccount();
        testAccount.PersonEmail='jane.smith@sundog.net';
        testAccount.Email_Opt_In_Method__c = 'Via Email';
        testAccount.G6_Transmitter_Ship_Date__c=ninetyDate;
        
            
        insert testAccount;
        
        Test.startTest();
        String jobId = System.schedule('testScheduled', '0 0 0 3 9 ? 2052', new SclsMarketingInteractionCASchedule());
        
        BclsMarketingInteractionCABatch sbatch = new BclsMarketingInteractionCABatch();
        Id batchInstanceId = Database.executeBatch(sbatch, 1);
        
        Test.stopTest();
        
        List<marketing_interaction__c> m= [SELECT id, Account__c FROM marketing_interaction__c WHERE account__c = :testAccount.Id 
                                           AND Communication_Type__c='CA - Subscription Upsell - G6'];
        
        System.assertEquals(1, m.size());
        
    }
        
        
}