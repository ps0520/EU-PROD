/*******************************************************
@Author        : Priyanka Kajawe 
@Date Created    : 5/08/2018
@Description    : Delete Expired Account Tokens
*******************************************************/
global class BClsDeleteExpiredAccountTokens implements Database.Batchable<sObject> {
    DateTime twentyFourHoursAgo = System.now().addHours(-24);
    
    global Database.QueryLocator start(Database.BatchableContext info) {
        return Database.getQueryLocator([SELECT Id, Account__c from Account_Token__c where Expiration_Time__c <= :twentyFourHoursAgo]);      
    }
    //Method to execute the batch  
    global void execute(Database.BatchableContext info, List<Account_Token__c> scope) {
        Database.delete(scope);
    }
    
    //Finish Method
    global void finish(Database.BatchableContext BC)
    {
        
    }    
}