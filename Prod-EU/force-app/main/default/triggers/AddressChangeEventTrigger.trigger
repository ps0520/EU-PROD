trigger AddressChangeEventTrigger on Address__ChangeEvent (after insert) {
/*******************************************************************************************************
@Description    : Trigger to process  Address__ChangeEvent and invokes ClsAddressChangeEventTriggerHandler
********************************************************************************************************/
    // Iterate through each event message.
    List<Address__ChangeEvent> addressChanges = Trigger.new;
    Set<String> oneKeyAddressIds = new Set<String>();
    Set<String> accountIds = new Set<String>();
    for (Address__ChangeEvent event : addressChanges) {
        EventBus.ChangeEventHeader header = event.ChangeEventHeader;
        //If the address is created by OneKey then add them to set for further processing
        if (header.changetype == 'CREATE') {
            if(event.IQVIA_OneKeyId__c != null)
            {
                List<String> recordIds = event.ChangeEventHeader.getRecordIds();
                accountIds.add(event.Account__c);
                oneKeyAddressIds.addAll(recordIds);
                system.debug('*******ADDRHGEVT - Found OneKey Address Inserted for ' + recordIds);
                system.debug('*******ACCCIDS - AccountIds affeceted  ' + accountIds);
            }
        }
    }
    //Process OneKey Address Insert
    if(!oneKeyAddressIds.isEmpty())
        ClsAddressChangeEventTriggerHandler.processOneKeyAddresses(oneKeyAddressIds, accountIds);
}