trigger TrgCRMErrorEventIn on CRM_Error_Event_In__e (after insert) {
    ClsPlatformEventErrorLogHandler.handleInboundErrors(trigger.new);
}