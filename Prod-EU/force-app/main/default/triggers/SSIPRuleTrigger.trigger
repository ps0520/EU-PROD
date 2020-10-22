trigger SSIPRuleTrigger on SSIP_Rule__c (before insert, before update,after insert, after update) {
    
    if(trigger.isBefore && trigger.isInsert){ 
        new SSIPRuleTriggerHandler().onBeforeInsert(trigger.new);
         SSIPRuleTriggerHandler.pricebookCheck(trigger.new,trigger.oldMap);
    
    }else if(trigger.isAfter && trigger.isInsert){
        new SSIPRuleTriggerHandler().onAfterInsert(trigger.new);
    }else if(trigger.isAfter && trigger.isUpdate){
        new SSIPRuleTriggerHandler().onAfterUpdate(trigger.new, trigger.oldMap);
        SSIPRuleTriggerHandler.pricebookCheck(trigger.new,trigger.oldMap);
    }
}