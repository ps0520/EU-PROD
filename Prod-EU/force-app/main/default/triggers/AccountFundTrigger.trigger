trigger AccountFundTrigger on Account_Fund__c (before insert, after insert, after update) {

if(Trigger.isInsert){
    if(Trigger.isBefore) new ClsAccountFundTriggerHandler().onBeforeInsert(Trigger.new); 
    if(Trigger.isAfter) new ClsAccountFundTriggerHandler().onAfterInsert(Trigger.new); 
}

if(Trigger.isUpdate){
    if(Trigger.isAfter) new ClsAccountFundTriggerHandler().onAfterUpdate(Trigger.new, Trigger.oldMap);
}

}