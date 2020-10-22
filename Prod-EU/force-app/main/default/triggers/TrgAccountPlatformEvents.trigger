trigger TrgAccountPlatformEvents on CRM_Account_Event__e (AFTER INSERT) {
    PEClsHandleAccountEvents.handleIncomingEvents(trigger.new);
}