@isTest public class ClsCustomerFeedbackConTest {
    @testSetup static void setup() {
        Account objAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'GB Consumer', 'United Kingdom')[0];
        Customer_Feedback__c custFeedback = ClsTestDataFactory.createCustomerFeedback();
    }
    
    @isTest static void TestgetAccDetail(){        
        
        Account acc =[Select Id, Name, LastName  from Account Limit 1][0];          
        Customer_Feedback__c custFeedbackObj = [Select id,Name,Account__c,High_Level_Feedback_Box__c,
                                                Note_Box__c,Type__c,Resolution_Box__c
                                                from Customer_Feedback__c Limit 1][0];
        CLSCustomerFeedbackCon.getAccountDetails(acc.Id);
        CLSCustomerFeedbackCon.getCFTypePicklist();
        CLSCustomerFeedbackCon.saveCustfeedbackDetails(custFeedbackObj);
        CLSCustomerFeedbackCon.updateCustfeedbackDetails(custFeedbackObj,custFeedbackObj.Id);
        CLSCustomerFeedbackCon.getCustomerFeedbackDetails(acc.Id);
        
    }
}