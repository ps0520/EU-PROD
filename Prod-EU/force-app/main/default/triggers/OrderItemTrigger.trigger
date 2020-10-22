trigger OrderItemTrigger on OrderItem (after insert, after update, after delete) 
// Changed By LTI
// trigger OrderItemTrigger on OrderItem (after update) 
{
/*******************************************************************************************************************
@Author         : Jagan Periyakaruppan
@Date Created   : 03/05/2018
@Description    : Trigger invokes handler class to handle OrderItem updates
********************************************************************************************************************/ 
    if(trigger.isAfter)
    {
        if(trigger.isUpdate)
        {
           // ClsOrderItemTriggerHandler.UpdateTrackingNumberOnOrder(trigger.newmap, trigger.oldmap);
          //  ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(trigger.newmap);
             ClsOrderItemCountryHandler.afterUpdateHandler(trigger.new , trigger.old, trigger.newmap, trigger.oldmap);
        }
        // Added by LTI - START
        if(trigger.isInsert)
        {
           // ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(trigger.newmap);
           ClsOrderItemCountryHandler.afterInsertHandler(trigger.new, trigger.newmap);
        }
        if(trigger.isDelete)
        {
           // ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(trigger.oldmap);
           ClsOrderItemCountryHandler.afterDeleteHandler(trigger.old, trigger.oldmap);
        }
        // Added by LTI - END
    }    
}