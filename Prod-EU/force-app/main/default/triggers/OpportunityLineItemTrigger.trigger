trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, before update, after insert,after update,before delete,after delete){
/*******************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 09/13/2017
@Description    : Trigger invokes handler class to sync Quote line items with Opportunity products
********************************************************************************************************************/    
 if(trigger.isBefore){
        
        //Create Quote line items
        if(trigger.isInsert){           
           ClsOpportunityLineItemCountryHandler.beforeInsertHandler(trigger.new); 
        }
 }
    if(trigger.isAfter){
        
        //Create Quote line items
        if(trigger.isInsert){           
           ClsOpportunityLineItemCountryHandler.afterInsertUpdateHandler(trigger.new, trigger.newmap, 'Insert'); 
        }
        //Update Quote line items
        if(trigger.isUpdate){
           ClsOpportunityLineItemCountryHandler.afterInsertUpdateHandler(trigger.new, trigger.newmap, 'Update'); 
        }
        //Delete the quote line items
        if(trigger.isDelete){
           ClsOpportunityLineItemCountryHandler.afterDeleteHandler(trigger.old, trigger.oldmap); 

        }
    }
}