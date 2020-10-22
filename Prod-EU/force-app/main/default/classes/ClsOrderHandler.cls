public class ClsOrderHandler {
    // This method changes the Order Status to shipped if all the line items are "Shipped" or in certain other statuses
    public static void verifyAndPublishUpdates(List<Order> newOrderList, Map<Id, Order> oldOrderMap) {
        Set<String> publishIdSet = new Set<String>();
        List<RecordType> CAOrderTypes = [Select Id from Recordtype where SobjectType = 'Order' AND isActive = true and DeveloperName like 'CA%'];
        Set<Id> CAOrderRecTypes = new Set<Id>();
        for(RecordType rt : CAOrderTypes) CAOrderRecTypes.add(rt.Id);
        for(Order ord : newOrderList) {
            if (ord.Count_of_Shipped_Line_Items__c!= oldOrderMap.get(ord.Id).Count_of_Shipped_Line_Items__c && ord.Count_of_Shipped_Line_Items__c == ord.Count_of_Order_Line_Items__c &&  CAOrderRecTypes.contains(Ord.RecordTypeId) )
                publishIdSet.add(ord.Id);
        }
        if (publishIdSet.size() > 0) {
            List<Order> updateOrders = new List<Order>();
            Boolean errorExit = false;
            for (String s : publishIdSet) updateOrders.add(new Order(Id = ID.valueOf(s), Status='shipped'));
            Database.SaveResult[] svrs = Database.update(updateOrders, true);
            for (Database.SaveResult svr : svrs) {
                if (!svr.isSuccess()) {
                    system.debug('Error in updating Order Status when Order Item got shipped. Error: ' + svr.getErrors());
                    errorExit = true;
                }
            }
            if (errorExit) return;
            system.debug('Requesting Order Update Event publish with Shipped status. No of Orders to be included: ' + publishIdSet.size());
        }
    }
    
    // The following method will be called from PEClsHandleOrderItemStatusEvents. It will update the Invoice Number and date if they are null.
    public static void updateInvoiceDetails(Map<Id, OrderItem> ordToOrdItemMap) {
		List<Order> ordDetails = [Select Id, Invoice_Number__c, Invoice_Date__c, Invoice_Status__c, Is_Cash_Order__c from Order where Id in :ordToOrdItemMap.keyset()];
		Map<Id, Order> ordUpdateMap = new Map<Id, Order>();
        for(Order o : ordDetails)  {
            if (o.Invoice_Date__c == null && String.isNotBlank(ordToOrdItemMap.get(o.Id).Invoice_Date__c) && ordToOrdItemMap.get(o.Id).Invoice_Date__c != 'null' ) {
                if (ordUpdateMap.containsKey(o.id)) ordUpdateMap.get(o.id).Invoice_Date__c = Date.valueOf(ordToOrdItemMap.get(o.Id).Invoice_Date__c); 
                else ordUpdateMap.put(o.id, new Order(id = o.id, Invoice_Status__c = o.Invoice_Status__c, Invoice_Date__c = Date.valueOf(ordToOrdItemMap.get(o.Id).Invoice_Date__c)));
            }
            if (String.isBlank(o.Invoice_Number__c) && String.isNotBlank(ordToOrdItemMap.get(o.Id).Invoice_Number__c) && ordToOrdItemMap.get(o.Id).Invoice_Number__c != 'null' ) {
                if (ordUpdateMap.containsKey(o.id)) ordUpdateMap.get(o.id).Invoice_Number__c = ordToOrdItemMap.get(o.Id).Invoice_Number__c; 
               else ordUpdateMap.put(o.id, new Order(id = o.id, Invoice_Status__c = o.Invoice_Status__c, Invoice_Number__c = ordToOrdItemMap.get(o.Id).Invoice_Number__c));
            }
        }
        if (ordUpdateMap.size() > 0 ) {
            for(Order orderRecord : ordUpdateMap.values()) if(orderRecord.Invoice_Status__c == 'Invoice Requested')orderRecord.Invoice_Status__c = 'Invoice Created';
            Database.SaveResult[] dsrs = Database.update(ordUpdateMap.values());
            for(Database.SaveResult dsr : dsrs) {
                if (!dsr.isSuccess()) {
                    
                    //ErrorUtility.LogError(action, classNMethodName, errorMsg, eventType, eventSource, exceptionError, externalID, severity)
                    ErrorUtility.LogError('Consume', 'ClsOrderHandler.updateInvoiceDetails', 'Error in Updating Invoice Details', 'orderItemStatus', dsr.getId(), 
                                          'Unable to update an Order\'s Invoice Details based on OrderLineStatus update for Order ' + dsr.getId() + '. Errors: ' + dsr.getErrors(), 
                                          dsr.getId(), 'Success Log');

                }
            }
        }
    }
}