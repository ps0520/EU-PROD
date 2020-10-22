trigger TrgCRM_Account_Address_Event_Out on CRM_Account_Address_Event_Out__e (after insert) {
    for( CRM_Account_Address_Event_Out__e  ev: trigger.new) 
        ErrorUtility.LogErrorWithEvent('publish', 'PEClsHandleAccountEvents.consumeAccount', 'Logging Published Event', 'account or address', ev.eventSourceID__c, 
                                  'Logging' , ev.eventSourceID__c, 'Success Log', String.valueOf(ev));
}