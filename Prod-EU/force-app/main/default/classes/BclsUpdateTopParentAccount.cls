/****************************************************************************************************************
@Author        : Pradeep Sadasivan
@Date Created    : 25/08/2020
@Description    :Batch apex to update Top Parent Account on an Account- IQVIA requirement - NS-743
****************************************************************************************************************/
global class BclsUpdateTopParentAccount implements Database.Batchable <SObject> {
    global Database.QueryLocator start(Database.BatchableContext bc){
        String Query='Select id,ParentID,OK_Top_Level_Parent__c,OK_Top_Level_ParentID__c,IQVIA_OneKeyId__c from Account Where IQVIA_OneKeyId__c!=Null AND OK_Top_Level_ParentID__c != Null AND ParentID != Null';
        return Database.getQueryLocator(Query);
            }
    global void execute(Database.BatchableContext bc, List<Account> accList){
        List<Account> accountToUpdate = new List<Account>();
        if(!accList.isEmpty()){
        	for(Account acc: accList){
            	acc.OK_Top_Level_Parent__c= acc.OK_Top_Level_ParentID__c;
                accountToUpdate.add(acc);
            
        	}
        }
        if(!accountToUpdate.isEmpty()){ 
            Database.update(accountToUpdate, false);
        }
    }
    global void finish(Database.BatchableContext bc){
        Id job= bc.getJobId();
        System.debug(job);
    }
}