/*******************************************************************************************
@Author        : 	P Saini
@Date Created    :  Mar 06, 2019
@Description    : 	Test class for ClsAccountFundTriggerHandler
*********************************************************************************************/
@isTest
private class ClsAccountFundTriggerHandler_Test {
    @isTest static void TestAccountFundTriggerHandler(){
    	List<Account> lstGBAcc = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'GB Consumer', 'United Kingdom');
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'GB Payor', 'United Kingdom')[0];
        
        Fund__c Fd = new Fund__c();
        Fd.PO_Reference_Number__c ='87666787';
        Fd.Limit_Type__c ='Quantity';        
        Fd.Payor__c = payorAccount.Id;
        Fd.Amount_Limit__c = 100000;
        Fd.Auth_End_Date__c = Date.today().addDays(100);
        Fd.Auth_Start_Date__c = Date.today();
        Fd.Receiver_Qty_Limit__c = 100; 
        Fd.Sensor_Limit__c = 100; 
        Fd.Transmitter_Qty_Limit__c = 100 ;        
        insert Fd ;
        
        Fund__c Fd1 = new Fund__c();
        Fd1.PO_Reference_Number__c ='87666711';
        Fd1.Limit_Type__c ='Quantity';        
        Fd1.Payor__c = payorAccount.Id;
        Fd1.Amount_Limit__c = 100000;
        Fd1.Auth_End_Date__c = Date.today().addDays(100);
        Fd1.Auth_Start_Date__c = Date.today();
        Fd1.Receiver_Qty_Limit__c = 100; 
        Fd1.Sensor_Limit__c = 100; 
        Fd1.Transmitter_Qty_Limit__c = 100 ;        
        insert Fd1 ;
        
        Account_Fund__c af= new Account_Fund__c(Account__c=lstGBAcc[0].Id, Fund__c=fd.Id, Primary_Flag__c=false);        
        insert af;
        af.Primary_Flag__c=true; update af;
        
        Account_Fund__c af1= new Account_Fund__c(Account__c=lstGBAcc[0].Id, Fund__c=fd1.Id, Primary_Flag__c=true);
        insert af1;
    }
}