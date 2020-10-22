trigger TrgPEOrderItemStatus on CRM_OrderItemStatus_Event__e (after insert) {
    system.debug('*****Total records to process ' + trigger.new.size());
    Integer counter = 0;//Counter to count the number of records
    List<CRM_OrderItemStatus_Event__e> batchEventsList = new List<CRM_OrderItemStatus_Event__e>();//Temp list, which holds data in 200 count    
    for(CRM_OrderItemStatus_Event__e ev: trigger.new) {
         counter++;
         // Resume after the last successfully processed event message after the trigger stops running. Exit for loop.
        if (counter > 200){ 
            break;
        }
        else
        {
            batchEventsList.add(ev);
            EventBus.TriggerContext.currentContext().setResumeCheckpoint(ev.ReplayId);
        }
    }
    system.debug('*****Counter is ' + counter + ' -- Entering the class PEClsHandleBatchOrderItemStatusEvents for processing the batch');
    if(!batchEventsList.isEmpty()) PEClsHandleBatchOrderItemStatusEvents.handleIncomingEvents(batchEventsList);// Many item status updates are coming in one go and failing. This Batch process is supposed to handle them.
}