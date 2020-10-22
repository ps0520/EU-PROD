public class ClsPlatformEventErrorLogHandler {
    public static void handleInsert(List<Platform_Event_Error_Log__c> errors) {
        List<CRM_Error_Event__e> errEventsList = new List<CRM_Error_Event__e>();
        CRM_Error_Event__e  event;
        string str;
        for(Platform_Event_Error_Log__c error : errors) {
            if (error.Severity__c == 'Success Log' || error.Severity__c == 'Error-in') continue;    // Don't publish these events as it is not an error.
            event = new CRM_Error_Event__e();
            event.code__c = '400';
            event.eventDate__c = String.valueOf(error.LastModifiedDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
            event.eventSource__c = error.EventSource__c ;
            event.entityType__c= error.Event__c;
            //event.keyName__c = 'systemOfOriginID';
            event.key__c = error.ExternalID__c;
            str = error.Error_Message__c + ' ' + error.Exception_Error__c;  
            event.message__c = str.left(255);
            event.payload__c = error.Event_String__c;
            errEventsList.add(event);
        }
        if (errEventsList.size() > 0) {
            List<Database.SaveResult> svrs = EventBus.publish(errEventsList);
            for (Database.SaveResult svr : svrs) {
                if (!svr.isSuccess()) {
                  system.debug('Error in publishing Account Event. Error: ' + svr.getErrors());
                }
            }
        }
    }
    public static void handleInboundErrors(List<CRM_Error_Event_In__e> errors) {
        List<Platform_Event_Error_Log__c> pees = new List<Platform_Event_Error_Log__c>();
        Platform_Event_Error_Log__c pee;
        List<Address__c> ListAddresses = new List<Address__c>();
        List<Account> ListAccounts = new List<Account>();
        List<Order> ListOrders = new List<Order>();
        Map<String, String> MapOrderErrors = new Map<String, String>();
        for (CRM_Error_Event_In__e inev : errors) {
            //SFDC publishes only the following 3 Event types. So, need to ignore other reported errors.
            if (!(inev.entityType__c.startsWithIgnoreCase('address') || inev.entityType__c.startsWithIgnoreCase('account') || inev.entityType__c.startsWithIgnoreCase('order'))) continue;
            pee = new Platform_Event_Error_Log__c();
            pee.Event__c = inev.entityType__c.left(40);   // Label Object
            pee.EventSource__c = inev.key__c.left(40);    // Label EventSource
            pee.Error_Message__c = inev.message__c.left(255);  // Label Message 
            pee.Action__c = 'consume'; // Label Action
            pee.Error_Handling_Status__c = 'New';  // Not displayed
            pee.Severity__c = 'Error-In';
            pee.Class_And_Method__c = 'Incoming Error';
            pee.Exception_Error__c = inev.code__c.left(100);
            pee.Event_String__c = inev.payload__c;
            pees.add(pee);
            //Logic to write data into the actual events
            if(inev.entityType__c.startsWithIgnoreCase('address')) {
                ListAddresses.add(new Address__c(id = inev.key__c, Integration_Error_Message__c=inev.message__c.left(500)));
            }
            if(inev.entityType__c.startsWithIgnoreCase('account')) {
                ListAccounts.add(new Account(id = inev.key__c, Integration_Error_Message__c=inev.message__c.left(500)));//
            }
            if(inev.entityType__c.startsWithIgnoreCase('order')) {
                MapOrderErrors.put(inev.key__c, inev.message__c.left(500));
                //ListOrders.add(new Order(id = inev.key__c, Integration_Error_Message__c=inev.message__c.left(500)));
            }
        }
        insert pees;
        if (ListAddresses.size() > 0) update ListAddresses;
        if (ListAccounts.size() > 0) update ListAccounts;
        if (MapOrderErrors.size() > 0) {
            Map<String, ID> MapOrderNumberToId = new Map<String, Id>();
            for(Order o : [Select Id, OrderNumber from Order where OrderNumber in :MapOrderErrors.keySet()]) MapOrderNumberToId.put(o.OrderNumber, o.Id);
            for(String onum : MapOrderErrors.keyset()) {
                ListOrders.add(new Order(id = MapOrderNumberToId.get(onum), Integration_Error_Message__c=MapOrderErrors.get(onum)));
            }
            if (ListOrders.size() > 0) update ListOrders;
        }
    }
}