trigger TrgOrderEventV11 on CRM_Order_Event_V1__e (after insert) {
    system.debug('*****Total records to process ' + trigger.new.size());
    if (trigger.new.size() > 50)ErrorUtility.LogError('consume', 'CRM_Order_Event_V1__e', 'Debug: Event Logging from CRM_Order_Event_V1__e', 'Order', 'OMS', 'Trigger Fired for the batch of ' + trigger.new.size() + ' to be hanlded by V11', '', 'Success Log');
    Integer counter = 0;//Counter to count the number of records
    List<CRM_Order_Event_V1__e> batchEventsList = new List<CRM_Order_Event_V1__e>();//Temp list, which holds data. Setting size to 50
     
  
     for(CRM_Order_Event_V1__e ev: trigger.new) {
        counter++;
        // Resume after the last successfully processed event message after the trigger stops running. Exit for loop.
        if (counter > 50){ 
            break;
        }
        else
        {
            batchEventsList.add(ev);
            EventBus.TriggerContext.currentContext().setResumeCheckpoint(ev.ReplayId);
        }
    }
    
    if (batchEventsList.size() == 50) ErrorUtility.LogError('consume', 'CRM_Order_Event_V1__e', 'Debug: Event Logging from CRM_Order_Event_V1__e', 'Order', 'OMS', 'Created a batch of ' + batchEventsList.size() + ' to be hanlded by V11', '', 'Success Log');
    system.debug('*****Counter is ' + counter + ' -- Entering the class PEClsHandleOrderEvents_V11 for processing the batch');
    if(!batchEventsList.isEmpty()) PEClsHandleOrderEvents_V11.onAfterInsert(batchEventsList);// Many item status updates are coming in one go and failing. This Batch process is supposed to handle them.
}