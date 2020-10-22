trigger TrgOrderEvent on CRM_Order_Event__e (after Insert) {
    for(CRM_Order_Event__e  e : trigger.new) {
        //system.debug('Received Order Event Source: ' + e.eventSource__c + ', eventSource ID: ' + e.eventSourceID__c +
          //  ', Operation: ' + e.operation__c + ', Stage: ' + e.stage__c);
        // system.debug('Event: ' + e);
        ErrorUtility.LogErrorWithEvent('Consume', 'CRM_Order_Event__e.Trigger', 'Logging incoming Event', 'Order', e.eventSourceID__c, 
                                  'Logging' , e.eventSourceID__c, 'Success Log', String.valueOf(e));
    }
    PEClsHandleOrderEvents.onAfterInsert(Trigger.new);
}