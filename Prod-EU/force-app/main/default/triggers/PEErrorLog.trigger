trigger PEErrorLog on Platform_Event_Error_Log__c (after insert) {
    ClsPlatformEventErrorLogHandler.handleInsert(trigger.new);
}