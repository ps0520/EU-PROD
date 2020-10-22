trigger FundTrigger on Fund__c (before insert,after update) {
    
    if(Trigger.isInsert && Trigger.isBefore){
        new ClsFundTriggerHandler().onBeforeInsert(Trigger.new);
    }
    if(Trigger.isAfter && Trigger.isUpdate){
         new ClsFundTriggerHandler().onAfterUpdate(Trigger.new,trigger.oldMap);
    } 
}