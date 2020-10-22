trigger SSIPScheduleTrigger on SSIP_Schedule__c (after update) {
    if(Trigger.isUpdate && Trigger.isAfter){
        new SSIPScheduleTriggerHandler().onAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}