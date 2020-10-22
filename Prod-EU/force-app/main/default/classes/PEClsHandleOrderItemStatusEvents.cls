public class PEClsHandleOrderItemStatusEvents {/********************************
	public static final String version = '1.0';  // version of the canonical
    public static void handleIncomingEvents(List<CRM_OrderItemStatus_Event__e > incEvs) {
        List<CRM_OrderItemStatus_Event__e > consumeUpdateOIList = new List<CRM_OrderItemStatus_Event__e >();
        for (CRM_OrderItemStatus_Event__e  ev : incEvs) {
            //For debugging purposes - next line
            system.debug('Incoming OrderItem Event: ' + ev);
            if ( ev.operation__c.containsIgnoreCase('UPDATE') && ev.stage__c.containsIgnoreCase('PENDING') && ev.eventSource__c.containsIgnoreCase('OMS') )
                consumeUpdateOIList.add(ev); 
            else if (ev.eventSource__c.containsIgnoreCase('CRM')){
                System.debug('Ignoring an event from Self');
            } else {
                ErrorUtility.LogError('Consume', 'PEClsHandleOrderItemStatusEvents.handleIncomingEvents', 'Error in Consuming OrderItem Event', 'orderItem', incEvs[0].eventSourceID__c, 
                                          'Unable to process an incoming orderItem event - Don\'t know how to handle it. eventSource: ' + ev.eventSource__c + ', eventSourceID: ' + ev.eventSourceID__c + ' Will not be processed.' , 
                                          incEvs[0].eventSourceID__c, 'Informational');
            }
        }
        if (consumeUpdateOIList.size() > 0) consumeOrderItemUpdate(consumeUpdateOIList, 'update');
    }
    public static void consumeOrderItemUpdate(List<CRM_OrderItemStatus_Event__e > oiEvents, String op) {
        // To do
        List<OrderItem> ois = new List<OrderItem>();
        OrderItem oi = new OrderItem();
        Set<String> oiSet = new Set<String>();
        Set<String> eIdSet = new Set<String>();
       	Map<Id, OrderItem> ordToOrdItemMap = new Map<Id, OrderItem>();
        for(CRM_OrderItemStatus_Event__e  ev : oiEvents) {
            // Need OrderItem ID to update an OrderItem. 
            if (String.isBlank(ev.itemID__c) || ev.itemID__c == 'null')  {
				// Publish an error message as this OrderItem can't be updated!
                ErrorUtility.LogError('Consume', 'PEClsHandleOrderItemStatusEvents.consumeOrderItemUpdate', 'Error in Consuming OrderItem Update Events.', 'orderItem', ev.eventSourceID__c, 
                                      'Unable to consume an OrderItem Update. Order Item Id is not found in the incoming Event. eventSource: ' + ev.eventSource__c + ', eventSourceID: ' + ev.eventSourceID__c + ' Will not be processed.' , 
                                      ev.eventSourceID__c, 'Informational');
            } else { if (ev.itemID__c.length() == 18 &&  ev.itemID__c.startsWith('802')) {
                		oiSet.add(ev.itemID__c); 
                		eIdSet.add(ev.itemID__c);      // Adding it to the External Id set too just in case it is there with the same pattern as the OrderItem.Id.
            		} else {
                        eIdSet.add(ev.itemID__c);
                        /*   Will use the itemID against External_Id__c
                		ErrorUtility.LogError('Consume', 'PEClsHandleOrderItemStatusEvents.consumeOrderItemUpdate', 'Error in Consuming OrderItem Update Events.', 'orderItem', ev.eventSourceID__c, 
                                      'Unable to consume an OrderItem Update. Unknown Item Id - ' + ev.itemID__c + ' - is found in the incoming Event. eventSource: ' + ev.eventSource__c + ', eventSourceID: ' + ev.eventSourceID__c + ' Will not be processed.' , 
                                      ev.eventSourceID__c, 'Informational');
						*//********************************
            		}/********************************
            }/********************************
        } /********************************
        Map<String, OrderItem> orderItemMap = new Map<String, OrderItem>();
        Map<String, OrderItem> orderExternalIdMap = new Map<String, OrderItem>();
        if (oiSet.size() > 0 || eIdSet.size() > 0 ) {
            List<OrderItem> orderItemsList = [Select ID, order.OrderNumber, OrderId, External_Id__c from OrderItem where (Id in :oiSet or External_Id__c in :eIdSet)];
            for (OrderItem a: orderItemsList) {orderItemMap.put(a.Id, a); orderExternalIdMap.put(a.External_Id__c, a); }
        } else { return; }
        
        for(CRM_OrderItemStatus_Event__e  ev : oiEvents) {
            ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleOrderItemStatusEvents.consumeOrderItemUpdate', 'Logging incoming Event', 'orderItemStatus', ev.eventSourceID__c, 
                                  'Logging' , ev.eventSourceID__c, 'Success Log', String.valueOf(ev));
            oi = new OrderItem();
            if (String.isBlank(ev.itemID__c) || ev.itemID__c == 'null') {
                continue;
            }
            if (orderItemMap.containsKey(ev.itemID__c))   { 
                oi.id = ev.itemID__c; 
                if (!ordToOrdItemMap.containsKey(orderItemMap.get(ev.itemID__c).orderId) && (String.isNotBlank(ev.invoiceDate__c) || String.isNotBlank(ev.invoiceNumber__c)))  // If this condition is not met, record already exists or not needed
                    ordToOrdItemMap.put(orderItemMap.get(ev.itemID__c).orderId, new OrderItem(id = ev.itemID__c, Invoice_Number__c = ev.invoiceNumber__c, Invoice_Date__c = ev.invoiceDate__c) );
            } else if (orderExternalIdMap.containsKey(ev.itemID__c)) {
                oi.id = orderExternalIdMap.get(ev.itemID__c).Id;
                if (!ordToOrdItemMap.containsKey(orderExternalIdMap.get(ev.itemID__c).orderId) && (String.isNotBlank(ev.invoiceDate__c) || String.isNotBlank(ev.invoiceNumber__c)))
                    ordToOrdItemMap.put(orderExternalIdMap.get(ev.itemID__c).orderId, new OrderItem(id = orderExternalIdMap.get(ev.itemID__c).Id, Invoice_Number__c = ev.invoiceNumber__c, Invoice_Date__c = ev.invoiceDate__c) );
            }
            else {
                    ErrorUtility.LogError('Consume', 'PEClsHandleOrderItemStatusEvents.consumeOrderItemUpdate', 'Error in Consuming OrderItem Update Events.', 'orderItem', ev.eventSourceID__c, 
                                          'Unable to consume an OrderItem Update. Unknown Item Id is found in the incoming Event. eventSource: ' + ev.eventSource__c + ', eventSourceID: ' + ev.eventSourceID__c + ' Will not be processed.' , 
                                          ev.eventSourceID__c, 'Informational');
                    continue;
            }
            if (ev.status__c != 'null' && !String.isBlank(ev.status__c))  oi.Status__c = ev.status__c;  // probably will need mapping .....*************************
            /*    Not necessary to validate the Order
            if (ev.orderNumber__c != 'null' && !String.isBlank(ev.orderNumber__c) && orderItemMap.get(ev.itemID__c).order.OrderNumber != ev.orderNumber__c)   {
                				ErrorUtility.LogError('Consume', 'PEClsHandleOrderItemStatusEvents.consumeOrderItemUpdate', 'Error in Consuming OrderItem Update Events.', 'orderItem', ev.eventSourceID__c, 
                                      'Unable to consume an OrderItem Update. Order Number does not correspond to the Order Item in the incoming Event. eventSource: ' + ev.eventSource__c + ', eventSourceID: ' + ev.eventSourceID__c + ' Will not be processed.' , 
                                      ev.eventSourceID__c, 'Informational');
                continue;
            }
			*/
			/********************************
            if (ev.shippingProvider__c != 'null' && !String.isBlank(ev.shippingProvider__c))   oi.Shipping_Provider__c = ev.shippingProvider__c;  // May need mapping.
            if (ev.trackingNumber__c != 'null' && !String.isBlank(ev.trackingNumber__c))   oi.Tracking_Number__c = ev.trackingNumber__c;  
            if (ev.deliveryNumber__c != 'null' && !String.isBlank(ev.deliveryNumber__c))   oi.Delivery_Number__c = ev.deliveryNumber__c;  
            if (ev.shippedDate__c != 'null' && !String.isBlank(ev.shippedDate__c))   oi.Actual_Ship_Date__c = Date.valueOf(ev.shippedDate__c); 
            if (ev.shippedQuantity__c != null)   oi.Shipped_Qty__c = ev.shippedQuantity__c;
            if (ev.serialNumber__c != 'null' && !String.isBlank(ev.serialNumber__c))   oi.Serial_Number__c = ev.serialNumber__c;  
            if (ev.lotNumber__c != 'null' && !String.isBlank(ev.lotNumber__c))   oi.Lot_Number__c = ev.lotNumber__c;  
            if (ev.lotExpirationDate__c != 'null' && !String.isBlank(ev.lotExpirationDate__c))   oi.Lot_Expiration_Date__c = ev.lotExpirationDate__c;
            if (ev.invoiceDate__c != 'null' && !String.isBlank(ev.invoiceDate__c)) oi.Invoice_Date__c = ev.invoiceDate__c;
            if (ev.invoiceNumber__c != 'null' && !String.isBlank(ev.invoiceNumber__c)) oi.Invoice_Number__c = ev.invoiceNumber__c;

			ois.add(oi);
        }
        /* This is already been done in Trigger
        integer hrid = 0;
        for(CRM_OrderItemStatus_Event__e ev : oiEvents) if (hrid < Integer.valueOf(ev.ReplayId)) hrid = Integer.valueOf(ev.ReplayId);
        system.debug('Setting the SetResumeChekpoint to ReplayId: ' + hrid);
        EventBus.TriggerContext.currentContext().setResumeCheckpoint(String.valueOf(hrid));
		*/
		/********************************
        if (ois.size() > 0) {
            Database.SaveResult[] dsrs = Database.update(ois, true);
            integer i = -1;
            boolean failed = false;
            for(Database.SaveResult dsr : dsrs) {
                i++;
                if (dsr.isSuccess())
               		 ErrorUtility.LogError('Consume', 'PEClsHandleOrderItemStatusEvents.consumeOrderItemUpdate', 'Successfully Updated Order Item Status.',  'OrderItemStatus', oiEvents[i].eventSourceID__c, 
                     	'Order Number: ' + oiEvents[i].orderNumber__c + ', Line Item Id: ' + oiEvents[i].itemID__c, oiEvents[i].itemID__c, 'Success Log');
           		else {
                    system.debug(dsr.getErrors());
                    ErrorUtility.LogError('Consume', 'PEClsHandleOrderItemStatusEvents.consumeOrderItemUpdate', 'Error in Consuming Order Item Status Update Operations.', 'OrderItemStatus', oiEvents[i].eventSourceID__c, 
                         'Errors: ' + dsr.getErrors(), oiEvents[i].itemID__c, 'Fatal Error - Bailing out');
                    failed = true;
                }
            }

            if (failed) return;
        }
        if (ordToOrdItemMap.size() > 0) ClsOrderHandler.updateInvoiceDetails(ordToOrdItemMap);   // Update the Order's Invoice Details.
        Set<Id> oitemSet = new Set<Id>();
		publishOrderItemUpdate(oitemSet, 'update');
    }
    public static void publishOrderItemUpdate(Set<Id> oiSet, String op) {
        List<CRM_OrderItemStatus_Event_Out__e> adds = new List<CRM_OrderItemStatus_Event_Out__e>();
        for(OrderItem a : [ select  Status__c, ID, order.OrderNumber, Tracking_Number__c, order.System_Of_Origin__c, order.System_Of_Origin_Id__c, Delivery_Number__c, Actual_Ship_Date__c , Shipped_Qty__c, Serial_Number__c,
                       			Lot_Number__c, Lot_Expiration_Date__c, LastModifiedDate, LastModifiedBy.Name, Shipping_Provider__c, Invoice_Number__c, Invoice_Date__c      
            from OrderItem where Id in :oiSet]) {
            	CRM_OrderItemStatus_Event_Out__e ae = new CRM_OrderItemStatus_Event_Out__e();
                // Header
                ae.version__c = version;
                //ae.eventDate__c =  String.valueOf(a.LastModifiedDate); //String.valueOf(System.now());
                ae.eventDate__c =  String.valueOf(a.LastModifiedDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
                ae.entityType__c = 'orderItemStatus';
                ae.eventSource__c = 'crm';
                ae.eventSourceID__c = a.Id;
                ae.operation__c = op;
                ae.stage__c = 'confirmed';
                ae.systemOfOrigin__c = a.order.System_Of_Origin__c;
                ae.systemOfOriginID__c = a.order.System_Of_Origin_Id__c;
                ae.parentSystemOfOriginID__c = a.order.OrderNumber;    
                ae.author__c = a.LastModifiedBy.Name;
                ae.status__c =  a.Status__c != null ? a.Status__c.toLowerCase():a.Status__c;     
                ae.orderNumber__c = a.order.OrderNumber;
                ae.itemID__c = a.Id;
                ae.invoiceDate__c = a.Invoice_Date__c;
                ae.invoiceNumber__c = a.Invoice_Number__c;
                ae.shippingProvider__c = a.Shipping_Provider__c;
                ae.trackingNumber__c = a.Tracking_Number__c;
                ae.deliveryNumber__c = a.Delivery_Number__c;
                ae.shippedDate__c = String.valueOf(a.Actual_Ship_Date__c);
                ae.shippedQuantity__c = a.Shipped_Qty__c;
                ae.serialNumber__c = a.Serial_Number__c;
                ae.lotNumber__c = a.Lot_Number__c;
                ae.lotExpirationDate__c = a.Lot_Expiration_Date__c;
                ae.parentSystemOfOriginID__c = a.order.OrderNumber;
                adds.add(ae);
        }
        if (adds.size() > 0) {
            List<Database.SaveResult> svrs = EventBus.publish(adds);
            integer i = -1;
        	for (Database.SaveResult svr : svrs) {
                i++;
                if (!svr.isSuccess()) {
                    ErrorUtility.LogError('Publish', 'PEClsHandleOrderItemStatusEvents.publishOrderItemUpdate', 'Error in Publishing OrderItem Event', 'orderItem', '', 
                                          'Unable to publish an orderItem Event. Error: ' + svr.getErrors(), 
                                          '', 'Informational');
                }
                else {
                    ErrorUtility.LogErrorWithEvent('Publish', 'PEClsHandleOrderItemStatusEvents.publishOrderItemUpdate', 'Successfully published Order Item Status Event.',  'OrderItemStatus', adds[i].eventSourceID__c, 
                     'Order Id: ' +adds[i].orderNumber__c, adds[i].itemID__c, 'Success Log', String.valueOf(adds[i]));
                }
            }
          }
    }/********************************/
}