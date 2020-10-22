trigger TrgAddressPlatfromEvents on CRM_Address_Event__e (AFTER INSERT) {
    for(CRM_Address_Event__e  e : trigger.new)
    system.debug('Received Address Event: ' + e);
       PEClsHandleAddressEvents.handleIncomingEvents(trigger.new);
}