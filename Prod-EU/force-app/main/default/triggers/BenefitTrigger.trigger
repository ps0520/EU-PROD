trigger BenefitTrigger on Benefit__c (before insert, after insert, before update, after Update) {
    if(Trigger.isBefore && Trigger.isInsert) ClsBenefitTriggerHandler.onBeforeInsert(Trigger.new);
    if (Trigger.isBefore && Trigger.isUpdate) ClsBenefitTriggerHandler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
    if (Trigger.isAfter) 
        if (Trigger.isInsert) ClsBenefitTriggerHandler.onAfterInsert(Trigger.newMap);
        else if (Trigger.isUpdate) ClsBenefitTriggerHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
}