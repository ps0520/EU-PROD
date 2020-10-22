/*****************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Modified    : 09/02/2020
@Description    : This Batch class will be invoked on a regular interval to clear out the duplicate related accounts
					that were created as part of OneKey Implementation
********************************************************************************************************************/ 
global class BClsClearDuplicateChildAccounts implements Database.Batchable<sobject>{
    //Get all the child accounts, which are created by Veeva
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        String query = 'SELECT Id, Parent_Child_Id__c, OK_Status__c FROM Related_Account__c WHERE (IQVIA_OneKeyId__c = null OR OK_Status__c = \'Invalid\') AND Child_Account__r.Recordtype.Name IN (\'DE Prescriber\', \'DE Medical Facility\', \'CA Prescriber\', \'CA Medical Facility\')';
        //String query = 'SELECT Id, Parent_Child_Id__c, OK_Status__c FROM Related_Account__c WHERE (IQVIA_OneKeyId__c = null OR OK_Status__c = \'Invalid\') AND Child_Account__r.Recordtype.Name IN (\'DE Prescriber\', \'DE Medical Facility\', \'CA Prescriber\', \'CA Medical Facility\') and Id in(\'a040Q000005LQIh\')';
        return Database.getQueryLocator(query);
    }
    
    //Execute the Account records in batch
    global void execute(Database.BatchableContext BC, List<Related_Account__c> childAccountsToBeDeletedList)
    {
        //List of Child acccounts to be deleted
        Map<Id, Related_Account__c> deleteChildAccounts = new Map<Id, Related_Account__c> ();
        Set<String> parentChildIdsToSearch = new Set<String>();
        Set<String> parentChildIdsFound = new Set<String>();
        
        for(Related_Account__c childAccount : childAccountsToBeDeletedList)
            parentChildIdsToSearch.add(childAccount.Parent_Child_Id__c);
        //Get all the child accounts that was populated by IQVIA
        for(Related_Account__c oneKeyChildAccnts : [SELECT Id, Parent_Child_Id__c FROM Related_Account__c WHERE IQVIA_OneKeyId__c != null AND Parent_Child_Id__c IN : parentChildIdsToSearch])
            parentChildIdsFound.add(oneKeyChildAccnts.Parent_Child_Id__c);

        for(Related_Account__c childAccount : childAccountsToBeDeletedList)
        {
            system.debug('****Id is ' + childAccount.Id);
            if(parentChildIdsFound.contains(childAccount.Parent_Child_Id__c) || childAccount.OK_Status__c == 'Invalid'){
                system.debug('****Found Id for delete ' + childAccount.Id);
                deleteChildAccounts.put(childAccount.Id, childAccount) ;
            }
        }
        //Delete the child accounts
        if(!deleteChildAccounts.isEmpty())
        {
            system.debug('Found accounts to delete');
            try{
                delete deleteChildAccounts.values();
            }catch (Exception e){
                system.debug('***CHILD ACCOUNTS CANNOT BE DELETED ERROR = ' + e.getMessage());
            }
        }
	}
    
    //Finish Method
    global void finish(Database.BatchableContext BC)
    {
      
    }
}