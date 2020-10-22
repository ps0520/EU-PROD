trigger BPSDJobTempTrigger on SDJob_Temp__c (after update) {
    if(Trigger.isUpdate && Trigger.isAfter){
        new BPClsSDJobTempHandler().onAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}