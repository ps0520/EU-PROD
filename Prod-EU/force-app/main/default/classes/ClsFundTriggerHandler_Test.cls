@isTest()
private class ClsFundTriggerHandler_Test {
    @isTest private static void test(){
        Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Payor', 'Germany')[0];
        Fund__c fund = new Fund__c(Payor__c = payorAccount.Id, Amount_Limit__c = 100000, Auth_End_Date__c = Date.today().addDays(100), Auth_Start_Date__c = Date.today(), 
                                   Receiver_Qty_Limit__c = 100, Sensor_Limit__c = 100, Transmitter_Qty_Limit__c = 100);
        insert fund;
    }
    
    @isTest static void TestFundTriggerHandler(){
       List<Account> lstGBAcc = ClsTestDataFactory.createAccountsWithBillingAddress(2, 'GB Consumer', 'United Kingdom');
      Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'GB Payor', 'United Kingdom')[0];
        Recordtype recType=[select id from recordtype where developername='Purchase_Order'];
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
        fd.recordtypeid=recType.id;
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
        fd1.recordtypeid=recType.id;        
        insert Fd1 ;
        lstGBAcc[0].fund__C=fd.id;
        Account_Fund__c af= new Account_Fund__c(Account__c=lstGBAcc[0].Id, Fund__c=fd.Id, Primary_Flag__c=true);        
        insert af;
        Account_Fund__c af1= new Account_Fund__c(Account__c=lstGBAcc[1].Id, Fund__c=fd.Id, Primary_Flag__c=true);        
        insert af1;
        Account_Fund__c af2= new Account_Fund__c(Account__c=lstGBAcc[0].Id, Fund__c=fd1.Id, Primary_Flag__c=false);        
        insert af2;
        
        
        
        
        test.starttest();
          fd.Succeeding_Fund__c=fd1.id;
          update fd;
        test.stoptest();
    }
}