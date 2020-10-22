/*******************************************************************************************************************
@Author        : Navneet
@Date Created    : 13/6/2019
@Description    : Trigger invokes handler class to process Currency
********************************************************************************************************************/    
 
trigger LeadTrigger on Lead (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
     if(trigger.isBefore){
          if (trigger.isInsert) 
                 ClsLeadCountryHandler.beforeInsertHandler(trigger.new); 
          if(trigger.isUpdate){
             // ClsLeadCountryHandler.beforeUpdateHandler(trigger.new,trigger.oldMap);
            ClsLeadTriggerHandler.doubleOptInBefore(trigger.new,trigger.oldMap);
        }
     }
     if(trigger.isAfter){
        if(trigger.isUpdate){
            ClsLeadTriggerHandler.doubleOptInAfter(trigger.new,trigger.oldMap);
          //  ClsLeadTriggerHandler.SdocCreationAfter(trigger.new);
        }
        if(trigger.isInsert){
            ClsLeadTriggerHandler.doubleOptInAfter(trigger.new,trigger.oldMap);
             ClsLeadTriggerHandler.SdocCreationAfter(trigger.new);
        }
    }
}