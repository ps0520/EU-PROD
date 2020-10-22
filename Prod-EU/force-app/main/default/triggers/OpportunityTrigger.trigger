trigger OpportunityTrigger on Opportunity (before insert, before update, after insert,after update){
/*****************************************************************************
@Description    : Trigger invokes handler class to process Opportunity logic
******************************************************************************/    
    if(trigger.isBefore){
         if(trigger.isInsert){          
             ClsOpportunityBPHandler.beforeInsertHandler(trigger.new); 
          
         } else if(Trigger.isUpdate) {
             ClsOpportunityBPHandler.beforeUpdateHandler(trigger.new, trigger.oldmap);
         }
    }
    
    if(trigger.isAfter){
        if(trigger.isInsert)
        {
            if(ClsCheckRecursive.runOnce()) ClsOpportunityBPHandler.afterInsertHandler(trigger.new, trigger.newmap, trigger.oldmap);                  
        }     
        if(trigger.isUpdate)
        {
          if(ClsCheckRecursive.runOnce()) ClsOpportunityBPHandler.afterUpdateHandler(trigger.newmap, trigger.oldmap);
		}       
    }
}