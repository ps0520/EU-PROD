trigger TrgOCEAccountPlatformEvents on Sample_Order_Request_Event__e (after insert) {
    System.debug('*****Total records to process ' + trigger.new.size());
    Integer counter = 0;
    List<Sample_Order_Request_Event__e > batchEventsList = new List<Sample_Order_Request_Event__e >();
    for(Sample_Order_Request_Event__e ev: trigger.new) {
        counter++;        
        if (counter > 200){ 
            break;
        }else{
            batchEventsList.add(ev);
            EventBus.TriggerContext.currentContext().setResumeCheckpoint(ev.ReplayId);
        }
    }    
    if(!batchEventsList.isEmpty()) DataBase.executeBatch(new PEClsHandleBatchOCEEvent(batchEventsList), 1);
}