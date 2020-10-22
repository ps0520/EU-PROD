public class PEClsHandleOrderEvents_V11{  
    public static final String version = '3.1';  // version of the canonical
    public static final Map<String, String> mapRecordTypeNameToID;
    public static final Map<String, String> mapAddressRecordTypeNameToID;
    public static final Map<String, Order_Event_Setting__mdt> mapOrderEventSetting;
    public static final Map<String, String> mapCountry;
    public static final Map<String, String> mapState;
    public static final Map<String, String> mapOrderTypeENUM;
    static{
        mapCountry = PEClsHandleOrderEvents_V11.getPicklistValues('Account', 'ShippingCountryCode');
        mapState = PEClsHandleOrderEvents_V11.getPicklistValues('Account', 'ShippingStateCode');
        mapRecordTypeNameToID = new Map<String, String>();
        mapAddressRecordTypeNameToID = new Map<String, String>();
        mapOrderTypeENUM = new Map<String, String>();
        mapOrderEventSetting = new Map<String, Order_Event_Setting__mdt>();
        for(Schema.RecordTypeInfo rtInfo : Schema.SObjectType.Order.getRecordTypeInfosByName().values()){
            mapRecordTypeNameToID.put(rtInfo.getName().toLowerCase(), rtInfo.getRecordTypeId());
        }
        for(Schema.RecordTypeInfo rtInfo : Schema.SObjectType.Address__c.getRecordTypeInfosByName().values()){
            mapAddressRecordTypeNameToID.put(rtInfo.getDeveloperName().toLowerCase(), rtInfo.getRecordTypeId());
        }
        for(Order_Event_Setting__mdt oEventSetting : [SELECT Id, DeveloperName, MasterLabel, SFDC_ORDER_TYPE__c, SFDC_RECORD_TYPE__c, EBS_ORDER_TYPE__c, FUSION_ORDER_TYPE__c FROM Order_Event_Setting__mdt]){
            mapOrderEventSetting.put(oEventSetting.DeveloperName , oEventSetting);
            mapOrderTypeENUM.put(oEventSetting.SFDC_ORDER_TYPE__c.toUpperCase(), oEventSetting.DeveloperName);
        } 
    }
    public class OrderLineItem{
        public String itemID;
        public String sku;
        public Decimal quantity;
        public Decimal price;
        public Boolean isBundle;
        public Boolean isBundleItem;
        public String skuBundle;
        public String url; 
        public Decimal total;
        public String parentItemID;
        
        public OrderLineItem(String sku, Decimal quantity, Decimal price){
            this.sku =  sku;
            this.quantity = quantity;
            this.price = price;
        }
        public OrderLineItem(OrderItem oli){
            this.itemID = oli.Id;
            this.sku = oli.Product2.Name;
            this.quantity = oli.Quantity;
            this.price = oli.UnitPrice;
            this.isBundle = oli.isBundle__c;
            this.isBundleItem = oli.isBundleItem__c;
            this.skuBundle = oli.SkuBundle__r.Name;
            this.url = '';
            this.total = oli.TotalPrice != null ? oli.TotalPrice : 0.0;
            this.parentItemID=oli.Parent_Order_Line_Id__c;
        }
        
    } 
    public static void onAfterInsert(List<CRM_Order_Event_V1__e> lstOrderEvent){
        Map<String, CRM_Order_Event_V1__e> mapOrderEventToUpdate = new Map<String, CRM_Order_Event_V1__e>();
        Map<String, CRM_Order_Event_V1__e> mapOrderEventToCreate = new Map<String, CRM_Order_Event_V1__e>();
        Map<String, CRM_Order_Event_V1__e> mapOrderEventToUpdateStatus = new Map<String, CRM_Order_Event_V1__e>();
        
        for(CRM_Order_Event_V1__e oEvent : lstOrderEvent){
            if( /*oEvent.version__c != version || *** Eliminating Version Check *** */ oEvent.entityType__c == null || !oEvent.entityType__c.containsIgnoreCase('order')){
                ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleOrderEvents_V11.onAfterInsert', 'Incorrect version, current version is '+version, 'order', oEvent.eventSourceID__c, 'Incorrect verion. eventSource: ' + oEvent.eventSource__c + ' eventSourceID: ' + oEvent.eventSourceID__c + '. Will not be processed.', oEvent.eventSourceID__c, 'Fatal Error - Bailing out', String.valueOf(oEvent));
                continue;
            }
            String uniqueKey = oEvent.systemOfOrigin__c != null && oEvent.systemOfOriginID__c != null ? oEvent.systemOfOrigin__c.trim() + oEvent.systemOfOriginID__c.trim() : '';
            if(oEvent.stage__c == 'pending' && oEvent.operation__c == 'create' && oEvent.eventSource__c != null && (oEvent.eventSource__c.containsIgnoreCase('OMS') || oEvent.eventSource__c.containsIgnoreCase('ECOM') || oEvent.eventSource__c.containsIgnoreCase('TS') )){
                //to create the order, we don't create and account address it should be available in salesforce else log the error
                //create and confirmed and order status should be booked and full order field mapping 
                mapOrderEventToCreate.put(uniqueKey, oEvent);
            }else if(oEvent.stage__c == 'confirmed' && oEvent.operation__c == 'create' && oEvent.eventSource__c != null && oEvent.eventSource__c.containsIgnoreCase('OMS') && oEvent.systemOfOrigin__c != null && (oEvent.systemOfOrigin__c.containsIgnoreCase('crm') || oEvent.systemOfOrigin__c.containsIgnoreCase('ecom'))){
                //marked as booked and publish registered event not other field mapping required..
                mapOrderEventToUpdateStatus.put(oEvent.orderNumber__c, oEvent);
            }else if(oEvent.stage__c == 'pending' && oEvent.operation__c == 'update' && oEvent.eventSource__c != null && oEvent.eventSource__c.containsIgnoreCase('OMS')){
                mapOrderEventToUpdate.put(oEvent.orderNumber__c, oEvent);
                //update the order...
                //update confirmed, status and other fields should taken from order event.
            }
        }
        
        if(!mapOrderEventToUpdateStatus.isEmpty()){
            ClsOrderHandlerStatic.executeOrderEventTriggerv11=true;
            updateOrderStatus(mapOrderEventToUpdateStatus);
        }
        if(!mapOrderEventToUpdate.isEmpty()){
            ClsOrderHandlerStatic.executeOrderEventTriggerv11=true;
            updateOrderOMS(mapOrderEventToUpdate);
        }
        if(!mapOrderEventToCreate.isEmpty()){
            Database.executeBatch(new PEBatchOrderEvent(mapOrderEventToCreate.values()), 1);
        }
    }
    
    private static void updateOrderOMS(Map<String, CRM_Order_Event_V1__e> mapOrderEvent ){
        List<Platform_Event_Error_Log__c> lstErrorLog = new List<Platform_Event_Error_Log__c>();
        if(ClsOrderHandlerStatic.runOrderEventTriggerv11()){
            Map<String, Order> mapOrder = new Map<String, Order>();
            Map<String, Order> mapOrderToUpdate = new Map<String, Order>();
            // Changes in the following 3 lines to accommodate EBS Order Numbers in Update Events.
            for(Order objOrder : [SELECT Id, OrderNumber, OMS_Order_Number__c, RecordType.DeveloperName,Invoice_Status__c FROM Order WHERE OrderNumber IN: mapOrderEvent.keySet() or OMS_Order_Number__c in :mapOrderEvent.keySet()]) {
                	if (mapOrderEvent.containsKey(objOrder.OMS_Order_Number__c)) mapOrder.put(objOrder.OMS_Order_Number__C, objOrder);
                    else    mapOrder.put(objOrder.OrderNumber, objOrder);
            }
            for(CRM_Order_Event_V1__e oEvent : mapOrderEvent.values()){
                if(!mapOrder.containsKey(oEvent.orderNumber__c)){
                    lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEClsHandleOrderEvents_V11.updateOrderOMS', 'Order is not present in Salesforce with OrderNumber' + oEvent.orderNumber__c, 'order', 'OMS', 'Order Not found.', oEvent.eventSourceID__c, 'Fatal Error - Bailing out', String.valueOf(oEvent)));
                    continue; 
                }
				Order orderToUpdate = mapOrder.get(oEvent.orderNumber__c);
                //If this is a DE Insurance Order where the Invoice Status is filled in then don't update the Order status otherwise go ahead and update the status as we receive from Fusion
				if(oEvent.status__c != null && ((orderToUpdate.RecordType.DeveloperName.startsWithIgnoreCase('DE') && orderToUpdate.Invoice_Status__c == null) || !orderToUpdate.RecordType.DeveloperName.startsWithIgnoreCase('DE'))){
                    orderToUpdate.Status = oEvent.status__c;
					mapOrderToUpdate.put(oEvent.orderNumber__c, orderToUpdate);
				}
            }
            List<Order> lstOrder = mapOrderToUpdate.values();
            List<Order> lstOrderErrorLog = new List<Order>();
            Set<String> setOrderId = new Set<String>();
            Boolean retryLogicApplicable = false;
            /* The following is the possible recoverable solution
             Database.SaveResult [] updateResult = Database.update(lstOrder, TRUE);
             if (EventBus.TriggerContext.currentContext().retries < 5) {
                    // Condition isn't met, so try again later.
                    throw new EventBus.RetryableException('Error happened, so retrying the trigger again.');
			*/
           	Database.SaveResult [] updateResult = Database.update(lstOrder, false);
            for(Integer i = 0; i < updateResult.size(); i++){
                if(updateResult[i].isSuccess()){
                    setOrderId.add(lstOrder[i].Id);
					//lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEClsHandleOrderEvents_V11.updateOrderOMS', 'Status updated successfully', 'order', 'OMS', 'Update Success. Order Id is: '+ lstOrder[i].Id +' Event Source Id:'+mapOrderEvent.get(lstOrder[i].OrderNumber).eventSourceID__c, mapOrderEvent.get(lstOrder[i].OrderNumber).eventSourceID__c, 'Success log', ''));
                }else{
                    String error = '';
                    for(Database.Error err : updateResult[i].getErrors()) {
                        error += error == '' ? err.getMessage() : ', ' + err.getMessage();
                    }
                    if (error.containsIgnoreCase('unable to obtain exclusive access to this record')) retryLogicApplicable = true;
                    lstOrderErrorLog.add(new Order(Id = lstOrder[i].Id, Integration_Error_Message__c = error.left(500)));
                    lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEClsHandleOrderEvents_V11.updateOrderOMS', 'Error while updating the Order Status: '+error, 'order', 'OMS', 'Update Failed. Order Id is: '+ lstOrder[i].Id +' Event Source Id:'+mapOrderEvent.get(lstOrder[i].OrderNumber).eventSourceID__c, mapOrderEvent.get(lstOrder[i].OrderNumber).eventSourceID__c, 'Recoverable Error - Published/Consumed', ''));
                }
            }
            if (retryLogicApplicable == true && EventBus.TriggerContext.currentContext().retries < 5) {
                throw new EventBus.RetryableException('Could not obtain exclusive lock to update data.');
            } else {
                Database.update(lstOrderErrorLog, false);
                Database.insert(lstErrorLog, false);
                PEClsHandleOrderEvents_V11.publishOrderEvent(setOrderId, new Set<String>(), mapOrderEvent, new Set<String>(), 'update');
            }
        }
    }
    
    private static void updateOrderStatus(Map<String, CRM_Order_Event_V1__e> mapOrderEvent){
        if(ClsOrderHandlerStatic.runOrderEventTriggerv11()){
            List<Platform_Event_Error_Log__c> lstErrorLog = new List<Platform_Event_Error_Log__c>();
            Map<String, Order> mapOrder = new Map<String, Order>();
            Map<String, Order> mapOrderToUpdate = new Map<String, Order>();
            for(Order objOrder : [SELECT Id, OrderNumber, RecordType.Name, Type, Payor__c FROM Order WHERE OrderNumber IN : mapOrderEvent.keySet()]) mapOrder.put(objOrder.OrderNumber, objOrder);
            for(CRM_Order_Event_V1__e oEvent : mapOrderEvent.values()){
                if(!mapOrder.containsKey(oEvent.orderNumber__c)){
                    lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEClsHandleOrderEvents_V11.updateOrder', 'Order is not present in Salesforce with OrderNumber' + oEvent.orderNumber__c, 'order', oEvent.eventSourceID__c, 'Incorrect order number. eventSource: ' + oEvent.eventSource__c + ' eventSourceID: ' + oEvent.eventSourceID__c + '. Will not be processed.', oEvent.eventSourceID__c, 'Fatal Error - Bailing out', String.valueOf(oEvent)));
                    continue; 
                }
                mapOrderToUpdate.put(oEvent.orderNumber__c, new Order(Id = mapOrder.get(oEvent.orderNumber__c).Id, 
                                                                      Status = mapOrder.get(oEvent.orderNumber__c).Payor__c != null && 
                                                                      mapOrder.get(oEvent.orderNumber__c).RecordType.Name.startsWithIgnoreCase('DE') &&//Added this condition VA 11/20/2019
																	  !mapOrder.get(oEvent.orderNumber__c).Type.containsIgnoreCase('RETURN')
                                                                      && oEvent.status__c == 'booked' ? 'On-Hold' : mapOrder.get(oEvent.orderNumber__c).Type.StartsWithIgnoreCase('CA') ? 'Booked' : 'Open'));
            }
			List<Order> lstOrder = mapOrderToUpdate.values();
            Set<String> setOrderId = new Set<String>();
           	Database.SaveResult [] updateResult = Database.update(lstOrder, false);
            List<Order> lstOrderErrorLog = new List<Order>();
            for(Integer i = 0; i < updateResult.size(); i++){
                if(updateResult[i].isSuccess()){
                    setOrderId.add(lstOrder[i].Id);
					//lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEClsHandleOrderEvents_V11.UpdateOrderStatus', 'Status updated successfully', 'order', 'OMS', 'Update Success. Order Id is: '+ lstOrder[i].Id, '', 'Success log', ''));
                }else{
                    String error = '';
                    for(Database.Error err : updateResult[i].getErrors()) {
                        error += error == '' ? err.getMessage() : ', ' + err.getMessage();
                    }
                    lstOrderErrorLog.add(new Order(Id = lstOrder[i].Id, Integration_Error_Message__c = error.left(500)));
                    lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEClsHandleOrderEvents_V11.UpdateOrderStatus', 'Error while updating the Order Status: '+error +' Order Id'+lstOrder[i].Id, 'order', 'OMS', 'Update Failed Order Id is: '+ lstOrder[i].Id, '', 'Recoverable Error - Published/Consumed', ''));
                }
            }
            Database.update(lstOrderErrorLog, false);
            Database.insert(lstErrorLog, false);
            PEClsHandleOrderEvents_V11.publishOrderEvent(setOrderId, new Set<String>(), mapOrderEvent, new Set<String>(), 'update');
        }
    }
    
    
    private static OrderItem orderItemMapping(String pbeId, OrderLineItem oli, String orderID, OrderItem oItem, Map<String, String> mapSKUProduct){
        return new OrderItem(PriceBookEntryId = pbeId,  Quantity = oli.quantity != null ? oli.quantity : oItem.Quantity, 
                             skuBundle__c = oli.skuBundle != null && oli.skuBundle != 'null' && mapSKUProduct.containsKey(oli.skuBundle) ? mapSKUProduct.get(oli.skuBundle) : oItem.skuBundle__c,
                             orderID = orderID, UnitPrice = oli.price != null ? oli.price : oItem.UnitPrice, isBundle__c = oli.isBundle != null ?  oli.isBundle : oItem.isBundle__c, 
                             isBundleItem__c = oli.isBundleItem != null ? oli.isBundleItem : oItem.isBundleItem__c);

    }
    
    public static CRM_Order_Event_Out_V1__e mappingOrderEvent(Order objOrder, List<OrderLineItem> lstOLI, CRM_Order_Event_V1__e oEvent, String stage, String action, String billingAddressPrimaryPhone, String shippingAddressPrimaryPhone){
        String billingState =  objOrder.Payor__c != null && objOrder.Payor_Bill_To_Address__r.State__c != null && mapState.containsKey(objOrder.Payor_Bill_To_Address__r.State__c) ? mapState.get(objOrder.Payor_Bill_To_Address__r.State__c):
                               objOrder.Customer_Bill_To_Address__r.State__c != null && mapState.containsKey(objOrder.Customer_Bill_To_Address__r.State__c) ? mapState.get(objOrder.Customer_Bill_To_Address__r.State__c) : null;
        String billingCountry = objOrder.Payor__c != null && objOrder.Payor_Bill_To_Address__r.Country__c != null && mapCountry.containsKey(objOrder.Payor_Bill_To_Address__r.Country__c) ? mapCountry.get(objOrder.Payor_Bill_To_Address__r.Country__c):
                                objOrder.Customer_Bill_To_Address__r.Country__c != null && mapCountry.containsKey(objOrder.Customer_Bill_To_Address__r.Country__c) ? mapCountry.get(objOrder.Customer_Bill_To_Address__r.Country__c) : null;
        boolean cc = objOrder.Type.startsWithIgnoreCase('CA') ? true : false;
                                
        return new CRM_Order_Event_Out_V1__e(version__c = version, stage__c = stage, accountId__c = objOrder.AccountId, eventDate__c = String.valueOf(objOrder.LastModifiedDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS'))+'Z', invoiceDate__c = String.valueOf(objOrder.Invoice_Date__c), invoiceNumber__c = objOrder.Invoice_Number__c, 
                                             warehouse__c = /*CC*/ (objOrder.Warehouse__c == 'DESD') ? 'HLNL' : /*CCEND*/ objOrder.Warehouse__c, pricebookName__c = objOrder.PriceBook2.Name,
                                             operation__c = oEvent != null && oEvent.operation__c != 'null'? oEvent.operation__c : action != null ? action : 'update', 
                                             systemOfOrigin__c = /*CC*/ String.isBlank(objOrder.System_Of_Origin__c) ? 'crm' : /*CCEnd*/ objOrder.System_Of_Origin__c, systemOfOriginID__c = /*CC*/ String.isBlank(objOrder.System_Of_Origin_ID__c) ? String.valueof(objOrder.id) : /*CCEnd*/ objOrder.System_Of_Origin_ID__c, 
                                             billingAddressAccountID__c = objOrder.Payor__c != null ? objOrder.Payor_Bill_To_Address__r.Account__c : objOrder.Customer_Bill_To_Address__r.Account__c,
                                             billingAddressBusinessName__c = objOrder.Payor__c!= null ? (cc ? ClsRemoveAccents.removeDiacritics(objOrder.Customer_Bill_To_Address__r.Business_Name__c): objOrder.Payor_Bill_To_Address__r.Business_Name__c) : (cc ? ClsRemoveAccents.removeDiacritics(objOrder.Customer_Bill_To_Address__r.Business_Name__c) : objOrder.Customer_Bill_To_Address__r.Business_Name__c), 
                                             billingAddressId__c = objOrder.Payor__c!= null ? objOrder.Payor_Bill_To_Address__c :  objOrder.Customer_Bill_To_Address__c, 
                                             billingAddress1__c = objOrder.Payor__c!= null ? (cc ? ClsRemoveAccents.removeDiacritics( objOrder.Payor_Bill_To_Address__r.Address_Line_1__c) : objOrder.Payor_Bill_To_Address__r.Address_Line_1__c) :(cc ? ClsRemoveAccents.removeDiacritics(objOrder.Customer_Bill_To_Address__r.Address_Line_1__c) : objOrder.Customer_Bill_To_Address__r.Address_Line_1__c),
                                             billingAddress2__c = objOrder.Payor__c!= null ? (cc ? ClsRemoveAccents.removeDiacritics(objOrder.Payor_Bill_To_Address__r.Address_Line_2__c ) : objOrder.Payor_Bill_To_Address__r.Address_Line_2__c) :(cc ? ClsRemoveAccents.removeDiacritics(objOrder.Customer_Bill_To_Address__r.Address_Line_2__c) : objOrder.Customer_Bill_To_Address__r.Address_Line_2__c), 
                                             billingAddress3__c = objOrder.Payor__c!= null ? (cc ? ClsRemoveAccents.removeDiacritics(objOrder.Payor_Bill_To_Address__r.Address_Line_3__c) : objOrder.Payor_Bill_To_Address__r.Address_Line_3__c) :  (cc ? ClsRemoveAccents.removeDiacritics(objOrder.Customer_Bill_To_Address__r.Address_Line_3__c) : objOrder.Customer_Bill_To_Address__r.Address_Line_3__c), 
                                             billingAddressCity__c = objOrder.Payor__c!= null ? (cc ? ClsRemoveAccents.removeDiacritics(objOrder.Payor_Bill_To_Address__r.City__c) : objOrder.Payor_Bill_To_Address__r.City__c) :  (cc ? ClsRemoveAccents.removeDiacritics(objOrder.Customer_Bill_To_Address__r.City__c) : objOrder.Customer_Bill_To_Address__r.City__c), 
                                             billingAddressCountry__c = objOrder.Payor__c!= null ? objOrder.Payor_Bill_To_Address__r.Country__c :  objOrder.Customer_Bill_To_Address__r.Country__c, 
                                             billingAddressFirstName__c = objOrder.Payor__c!= null ? (cc ? ClsRemoveAccents.removeDiacritics(objOrder.Payor_Bill_To_Address__r.First_Name__c) : objOrder.Payor_Bill_To_Address__r.First_Name__c) :  (cc ? ClsRemoveAccents.removeDiacritics(objOrder.Customer_Bill_To_Address__r.First_Name__c) : objOrder.Customer_Bill_To_Address__r.First_Name__c), 
                                             billingAddressLastName__c = objOrder.Payor__c!= null ? (cc ? ClsRemoveAccents.removeDiacritics(objOrder.Payor_Bill_To_Address__r.Last_Name__c) : objOrder.Payor_Bill_To_Address__r.Last_Name__c) :  (cc ? ClsRemoveAccents.removeDiacritics(objOrder.Customer_Bill_To_Address__r.Last_Name__c) : objOrder.Customer_Bill_To_Address__r.Last_Name__c), 
                                             billingAddressPostalCode__c = objOrder.Payor__c!= null ? objOrder.Payor_Bill_To_Address__r.Postal_Code__c :  objOrder.Customer_Bill_To_Address__r.Postal_Code__c, 
                                             billingAddressIsLocked__c = objOrder.Payor__c!= null ? objOrder.Payor_Bill_To_Address__r.isLocked__c :  objOrder.Customer_Bill_To_Address__r.isLocked__c, 
                                             billingAddressPrimaryPhone__c = billingAddressPrimaryPhone, shippingAddressPrimaryPhone__c = shippingAddressPrimaryPhone,
											 billingAddressIsPrimary__c = objOrder.Payor__c!= null ? objOrder.Payor_Bill_To_Address__r.Primary_Flag__c :  objOrder.Customer_Bill_To_Address__r.Primary_Flag__c, 
                                             billingAddressStateProvince__c = billingState, billingAddressCountryCode__c = billingCountry,
                                             shippingAddressBusinessName__c = cc ? ClsRemoveAccents.removeDiacritics(objOrder.Customer_Ship_To_Address__r.Business_Name__c) : objOrder.Customer_Ship_To_Address__r.Business_Name__c, 
                                             shippingAddress1__c = cc ? ClsRemoveAccents.removeDiacritics(objOrder.Customer_Ship_To_Address__r.Address_Line_1__c) : objOrder.Customer_Ship_To_Address__r.Address_Line_1__c, 
                                             shippingAddress2__c = cc ? ClsRemoveAccents.removeDiacritics(objOrder.Customer_Ship_To_Address__r.Address_Line_2__c) : objOrder.Customer_Ship_To_Address__r.Address_Line_2__c, 
                                             shippingAddress3__c = cc ? ClsRemoveAccents.removeDiacritics(objOrder.Customer_Ship_To_Address__r.Address_Line_3__c) : objOrder.Customer_Ship_To_Address__r.Address_Line_3__c, 
                                             shippingAddressCity__c = cc ? ClsRemoveAccents.removeDiacritics(objOrder.Customer_Ship_To_Address__r.City__c) : objOrder.Customer_Ship_To_Address__r.City__c, 
                                             shippingAddressCountry__c = objOrder.Customer_Ship_To_Address__r.Country__c, shippingAddressId__c = objOrder.Customer_Ship_To_Address__c,
                                             shippingAddressFirstName__c = cc ? ClsRemoveAccents.removeDiacritics(objOrder.Customer_Ship_To_Address__r.First_Name__c) : objOrder.Customer_Ship_To_Address__r.First_Name__c, 
                                             shippingAddressLastName__c = cc ? ClsRemoveAccents.removeDiacritics(objOrder.Customer_Ship_To_Address__r.Last_Name__c) : objOrder.Customer_Ship_To_Address__r.Last_Name__c, 
                                             shippingAddressPostalCode__c = objOrder.Customer_Ship_To_Address__r.Postal_Code__c, shippingAddressIsLocked__c = objOrder.Customer_Ship_To_Address__r.isLocked__c, shippingAddressIsPrimary__c = objOrder.Customer_Ship_To_Address__r.Primary_Flag__c, 
                                             Line_Items__c = JSON.serialize(lstOLI),  creditCardAuthorizationCode__c = objOrder.Credit_Card_Authorization_Code__c, creditCardToken__c = objOrder.Finance_Detail__r.Token__c, creditCardType__c = objOrder.Finance_Detail__r.Card_Type__c, 
                                             creditCardExpirationDate__c = objOrder.Finance_Detail__r.Expiry_Date__c, orderNumber__c = objOrder.OrderNumber, creditCardId__c = objOrder.Finance_Detail__c, creditCardTransactionID__c = objOrder.Type.StartsWithIgnoreCase('CA') ? objOrder.Settlement_Id__c : null,
                                             isSignatureRequired__c = objOrder.Signature_Required__c, shippingMethod__c = /*CC*/ (String.isBlank(objOrder.Shipping_Method__c) && billingCountry == 'DE') ? 'DHL Parcel|Ground|0|BS2' :  /*CCEnd*/ objOrder.Shipping_Method__c, 
                                             shippingAddressCountryCode__c = mapCountry.containsKey(objOrder.Customer_Ship_To_Address__r.Country__c) ? mapCountry.get(objOrder.Customer_Ship_To_Address__r.Country__c) : null,
                                             shippingAddressStateProvince__c = mapState.containsKey(objOrder.Customer_Ship_To_Address__r.State__c) ? mapState.get(objOrder.Customer_Ship_To_Address__r.State__c) : null,
                                             shippingAddressAccountID__c = objOrder.Customer_Ship_To_Address__r.Account__c, eventSource__c = 'crm', entityType__c = 'order', eventSourceID__c = objOrder.Id,
                                             totalAmount__c = objOrder.Total_Gross_Price__c == NULL ? 0.0 : objOrder.Total_Gross_Price__c, status__c = (objOrder.Status == 'Shipping Hold' && (objOrder.Is_Cash_Order__c || objOrder.Type.containsIgnoreCase('RETURN') || objOrder.Type.containsIgnoreCase('SAMPLE'))) ? 'activated' : 
											 (objOrder.Status == 'Open' || objOrder.Status == 'On-Hold') ? 'booked' : objOrder.Status.toLowerCase(), orderType__c = objOrder.Type,
                                             bankAccountName__c = objOrder.Finance_Detail__r.Bank_Account_Name__c, bankAccountNumber__c = objOrder.Finance_Detail__r.Bank_Account_Number__c, bankId__c = objOrder.Finance_Detail__r.Bank_Id__c, bankName__c = objOrder.Finance_Detail__r.Bank_Name__c, 
                                             bic__c= objOrder.Finance_Detail__r.Bank_Identifier_Code__c, branchName__c = objOrder.Finance_Detail__r.Branch_Name__c, 
                                             shippingEmail__c = ClsOrderEntryHandler.validateEmail(objOrder.Shipping_Contact_Email__c) ? objOrder.Shipping_Contact_Email__c : null,
                                             author__c = cc ? ClsRemoveAccents.removeDiacritics(objOrder.LastModifiedBy.Name) : objOrder.LastModifiedBy.Name, shippingNotes__c = objOrder.Shipping_Instructions__c, rgaNumber__c = objOrder.Display_RGA_Number__c, 
											 action__c = (stage == 'registered' || objOrder.Status == 'Closed' || objOrder.Status == 'Cancelled' || objOrder.Status == 'Canceled') ? null : objOrder.OMS_Action__c,
                                             currencyCode__c = objOrder.CurrencyIsoCode, paymentTerm__c= /* add start */ objOrder.Payment_Terms__c == null ? 'net30' : /* add end VA 1/2/20 */ objOrder.Payment_Terms__c, paymentMethod__c = objOrder.Payment_Method__c, scheduledShipDate__c = objOrder.Effectivedate != null ? String.valueOf(objOrder.Effectivedate) : String.valueOf(Date.today()),
                                             parentSystemOfOriginID__c = objOrder.Parent_Order__r.OrderNumber,deliveryTerm__c = objOrder.Delivery_Term__c, poNumber__c = String.isnotBlank(objOrder.PoNumber) ? objOrder.PoNumber.left(50) : '',
                                             billingtaxExempt__c = objOrder.Payor__c!= null ? objOrder.Payor_Bill_To_Address__r.Account__r.Tax_Exempt__c : objOrder.Account.Tax_Exempt__c, billingtaxRegistrationNumber__c = objOrder.Payor__c!= null ? objOrder.Payor_Bill_To_Address__r.Account__r.Tax_Registration_Number__c : objOrder.Account.Tax_Registration_Number__c, 
                                             shippingtaxExempt__c = objOrder.Account.Tax_Exempt__c, shippingtaxRegistrationNumber__c = objOrder.Account.Tax_Registration_Number__c, shippingAmount__c = objOrder.Final_Shipping_Charge__c == null ? 0.0 : objOrder.Final_Shipping_Charge__c, studyID__c = objOrder.Study_Id__c);
    }
    
    public static void publishOrderEvent(Set<String> setOrderId, Set<String> setAccountId, String action){
        PEClsHandleOrderEvents_V11.publishOrderEvent(setOrderId, new Set<String>(), new Map<String, CRM_Order_Event_V1__e>(), setAccountId, action);
    }
    public static void publishOrderEvent(Set<String> setOrderId, Set<String> setOrderNumber, Map<String, CRM_Order_Event_V1__e> mapOrderEvent, Set<String> setAccountID, String action){
        List<Platform_Event_Error_Log__c> lstErrorLog = new List<Platform_Event_Error_Log__c>();
        List<CRM_Order_Event_Out_V1__e> lstOEvent = new List<CRM_Order_Event_Out_V1__e>();
        List<Order> lstOrder = new List<Order>();
        for(Order objOrder : getOrders(setOrderId, setOrderNumber, setAccountID)){
            List<OrderLineItem> lstOLI = new List<OrderLineItem>();
            for(OrderItem oli : objOrder.OrderItems) lstOLI.add(new OrderLineItem(oli));
            String stage = 'confirmed';
            if(mapOrderEvent.containsKey(objOrder.OrderNumber)){
                CRM_Order_Event_V1__e oEvent = mapOrderEvent.get(objOrder.OrderNumber);
                stage = oEvent.stage__c == 'confirmed' && oEvent.operation__c == 'create' ? 'registered' : 
                        oEvent.stage__c == 'pending' && oEvent.operation__c == 'update' ? 'confirmed' : 'confirmed';
                action = oEvent.operation__c;
            }
            if(!ClsOrderEntryHandler.validateEmail(objOrder.Shipping_Contact_Email__c) && String.isNotBlank(objOrder.Shipping_Contact_Email__c)) {
            //String action, String classNMethodName, String errorMsg, String eventType, String eventSource, String exceptionError, String externalID, String severity,
                lstErrorLog.add(ErrorUtility.prepareErroLog('Publish', 'PEClsHandleOrderEvents_V11.publishOrderEvent', 'Invalid Shipping Contact Email - ' + objOrder.Shipping_Contact_Email__c + ' - for Order Id :'+objOrder.Id, 'order', 'crm', '', '', 'Informational', ''));
            }
            String billingAddressPrimaryPhone = objOrder.Payor__c!= null && objOrder.Payor_Bill_To_Address__r.Primary_Phone__c != null ? objOrder.Payor_Bill_To_Address__r.Primary_Phone__c :  objOrder.Customer_Bill_To_Address__r.Primary_Phone__c != null ?  
                objOrder.Customer_Bill_To_Address__r.Primary_Phone__c : objOrder.Account.IsPersonAccount == false ? String.valueOf(objOrder.Account.Phone) : objOrder.Account.Primary_Contact_Number__c;
            String shippingAddressPrimaryPhone = objOrder.Customer_Ship_To_Address__r.Primary_Phone__c != null ? objOrder.Customer_Ship_To_Address__r.Primary_Phone__c : objOrder.Account.IsPersonAccount == false ? String.valueOf(objOrder.Account.Phone) : objOrder.Account.Primary_Contact_Number__c;
          
            if(String.isNotBlank(billingAddressPrimaryPhone) && billingAddressPrimaryPhone != null && !ClsOrderEntryHandler.validatePhone(billingAddressPrimaryPhone)){
                lstErrorLog.add(ErrorUtility.prepareErroLog('Publish', 'PEClsHandleOrderEvents_V11.publishOrderEvent', 'Invalid Billing Primary Phone - ' + billingAddressPrimaryPhone + ' - for Order Id : '+objOrder.Id, 'Order', 'crm', 'Invalid Billing Primary Phone - ' + billingAddressPrimaryPhone + ' - for Order Id :'+objOrder.Id, 'Account ID: ' + objOrder.AccountId, 'Informational', ''));
            	billingAddressPrimaryPhone = null;	
            }
            if(String.isNotBlank(shippingAddressPrimaryPhone) && shippingAddressPrimaryPhone != null && !ClsOrderEntryHandler.validatePhone(shippingAddressPrimaryPhone)){
                lstErrorLog.add(ErrorUtility.prepareErroLog('Publish', 'PEClsHandleOrderEvents_V11.publishOrderEvent', 'Invalid Shipping Primary Phone - ' + shippingAddressPrimaryPhone + ' - for Order Id : '+objOrder.Id, 'order', 'crm', 'Invalid Shipping Primary Phone - ' + shippingAddressPrimaryPhone + ' - for Order Id :'+objOrder.Id, 'Account ID: ' + objOrder.AccountId, 'Informational', ''));
                shippingAddressPrimaryPhone = null;
            }
            CRM_Order_Event_Out_V1__e oEvent = mappingOrderEvent(objOrder, lstOLI, mapOrderEvent.get(objOrder.OrderNumber), stage, action, billingAddressPrimaryPhone, shippingAddressPrimaryPhone);
            if( (objOrder.RecordType.DeveloperName.startsWithIgnoreCase('DE_') && objOrder.Payor__c != null && objOrder.Payor__r.Name.containsIgnoreCase('CASH PAYOR') && objOrder.Payor_Bill_To_Address__c == null) || 
               (objOrder.RecordType.DeveloperName.startsWithIgnoreCase('DIST_') && objOrder.Payor__c != null) ) {
				oEvent.billingAddressAccountID__c =  objOrder.Customer_Bill_To_Address__r.Account__c;
                oEvent.billingAddressBusinessName__c =  objOrder.Customer_Bill_To_Address__r.Business_Name__c;
                oEvent.billingAddressId__c = objOrder.Customer_Bill_To_Address__c;
                oEvent.billingAddress1__c = objOrder.Customer_Bill_To_Address__r.Address_Line_1__c;
                oEvent.billingAddress2__c = objOrder.Customer_Bill_To_Address__r.Address_Line_2__c; 
                oEvent.billingAddress3__c = objOrder.Customer_Bill_To_Address__r.Address_Line_3__c; 
                oEvent.billingAddressCity__c = objOrder.Customer_Bill_To_Address__r.City__c;
                oEvent.billingAddressCountry__c = objOrder.Customer_Bill_To_Address__r.Country__c;
                oEvent.billingAddressFirstName__c = objOrder.Customer_Bill_To_Address__r.First_Name__c;
                oEvent.billingAddressLastName__c = objOrder.Customer_Bill_To_Address__r.Last_Name__c; 
                oEvent.billingAddressPostalCode__c = objOrder.Customer_Bill_To_Address__r.Postal_Code__c; 
                oEvent.billingAddressIsLocked__c = objOrder.Customer_Bill_To_Address__r.isLocked__c;
				oEvent.billingAddressIsPrimary__c = objOrder.Customer_Bill_To_Address__r.Primary_Flag__c;                      
            }
            lstOEvent.add(oEvent);
            lstOrder.add(objOrder);
        }
        insert lstErrorLog;
        PEClsHandleOrderEvents_V11.publishPlatformEvents(lstOEvent, lstOrder);
    } 
    private static void publishPlatformEvents(List<CRM_Order_Event_Out_V1__e> lstOEvent, List<Order> lstOrder){
        List<Order> lstOrderToUpdate = new List<Order>();
        List<Platform_Event_Error_Log__c> lstErrorLog = new List<Platform_Event_Error_Log__c>();
        List<Database.SaveResult> svrs = EventBus.publish(lstOEvent);  
        for(Integer i = 0; i < svrs.size(); i++){
            if(svrs[i].isSuccess()){
                lstOrderToUpdate.add(new Order(Id = lstOrder[i].Id, Order_Send_to_EBS_Date__c = Date.today(), Last_Sync_Date_With_Oracle__c = Date.today()));
                //lstErrorLog.add(ErrorUtility.prepareErroLog('Publish', 'PEClsHandleOrderEvents_V11.publishOrderEvent', 'Successfully published Order Event.',  'Order', lstOEvent[i].eventSourceID__c, 
                //                               				'Order Id: ' + lstOEvent[i].eventSourceID__c, lstOEvent[i].eventSourceID__c, 'Success Log', String.valueOf(lstOEvent[i])));
            }else{
                lstErrorLog.add(ErrorUtility.prepareErroLog('Publish', 'PEClsHandleOrderEvents_V11.publishOrderEvent', 'Error in publishing Order Event.',  'Order', lstOEvent[i].eventSourceID__c, 
                                               				'Order Id: ' + lstOEvent[i].eventSourceID__c +' could not be published. Error: ' + svrs[i].getErrors(), lstOEvent[i].eventSourceID__c, 'Recoverable Error - Published/Consumed', String.valueOf(lstOEvent[i])));
            }
        }
        update lstOrderToUpdate;
        insert lstErrorLog;
    }
    public static List<Order> getOrders(Set<String> setOrderId, Set<String> setOrderNumber, Set<String> setAccountID){
        return [SELECT Id, Effectivedate, AccountId, LastModifiedDate, Invoice_Date__c, Invoice_Number__c, Invoice_Status__c, Type, Warehouse__c, PriceBook2.Name, System_Of_Origin__c, System_Of_Origin_ID__c, Customer_Bill_To_Address__r.Business_Name__c, Customer_Bill_To_Address__r.Address_Line_1__c, Customer_Bill_To_Address__r.Address_Line_2__c,
                       Customer_Bill_To_Address__r.Address_Line_3__c, Customer_Bill_To_Address__r.City__c, Customer_Bill_To_Address__r.Country__c, Customer_Bill_To_Address__r.First_Name__c, Customer_Bill_To_Address__r.Last_Name__c, Customer_Bill_To_Address__r.Postal_Code__c,Customer_Bill_To_Address__c,
                       Customer_Bill_To_Address__r.isLocked__c, Customer_Bill_To_Address__r.Primary_Phone__c,Customer_Bill_To_Address__r.State__c, Customer_Bill_To_Address__r.Primary_Flag__c, 
					   Customer_Ship_To_Address__r.Business_Name__c, Customer_Ship_To_Address__r.Address_Line_1__c,Customer_Ship_To_Address__r.State__c,Customer_Ship_To_Address__c, RecordType.DeveloperName, Payor__r.Name, 
                       Customer_Ship_To_Address__r.Address_Line_2__c, Customer_Ship_To_Address__r.Address_Line_3__c, Customer_Ship_To_Address__r.City__c, Customer_Ship_To_Address__r.Country__c, Customer_Ship_To_Address__r.First_Name__c, Customer_Ship_To_Address__r.Last_Name__c,
                       Customer_Ship_To_Address__r.Postal_Code__c, Customer_Ship_To_Address__r.isLocked__c, Customer_Ship_To_Address__r.Primary_Phone__c, Customer_Ship_To_Address__r.Primary_Flag__c, Delivery_Term__c, PoNumber, 
					   Credit_Card_Authorization_Code__c,  Finance_Detail__c, Finance_Detail__r.Token__c, Finance_Detail__r.Card_Type__c, Finance_Detail__r.Expiry_Date__c,Account.Primary_Contact_Number__c, Account.IsPersonAccount, Account.Phone,
                       Finance_Detail__r.Bank_Account_Name__c, Finance_Detail__r.Bank_Account_Number__c, Finance_Detail__r.Bank_Id__c, Finance_Detail__r.Bank_Identifier_Code__c, Finance_Detail__r.Bank_Name__c, Finance_Detail__r.Branch_Name__c,Shipping_Contact_Email__c,Finance_Detail__r.Finance_Type__c,
                       SOS_Unique_ID__c, Status, OrderNumber, RecordTypeId, /* Adding this column VA 11/20/2019*/ RecordType.Name, OwnerId, Signature_Required__c, Shipping_Method__c,TotalAmount, Account.Sync_Status__c,LastModifiedBy.Name, Shipping_Instructions__c,Display_RGA_Number__c,Shipping_Email__c,OMS_Action__c,Is_Cash_Order__c,CurrencyIsoCode,Payor__c,
                       Payor_Bill_To_Address__r.Business_Name__c, Payor_Bill_To_Address__r.Address_Line_1__c, Payor_Bill_To_Address__r.Address_Line_2__c, Payor_Bill_To_Address__r.Address_Line_3__c, Payor_Bill_To_Address__r.City__c, Payor_Bill_To_Address__r.Country__c, Payor_Bill_To_Address__r.First_Name__c, 
                       Payor_Bill_To_Address__r.Last_Name__c, Payor_Bill_To_Address__r.Postal_Code__c,Payor_Bill_To_Address__c, Payor_Bill_To_Address__r.isLocked__c, Payor_Bill_To_Address__r.Primary_Phone__c,Payor_Bill_To_Address__r.State__c, Payor_Bill_To_Address__r.Primary_Flag__c, Payor_Bill_To_Address__r.Account__r.Tax_Exempt__c, Payor_Bill_To_Address__r.Account__r.Tax_Registration_Number__c,
                       Customer_Ship_To_Address__r.Account__c, Customer_Bill_To_Address__r.Account__c, Payor_Bill_To_Address__r.Account__c, Payment_Terms__c, Payment_Method__c, Parent_Order__r.OrderNumber, Account.Tax_Exempt__c, Account.Tax_Registration_Number__c,Total_Gross_Price__c, Final_Shipping_Charge__c, Study_Id__c, Settlement_Id__c,
                       (SELECT Id, Product2Id, Product2.Name, Quantity, UnitPrice, isBundle__c, isBundleItem__c, SkuBundle__c, SkuBundle__r.Name, TotalPrice, Total_Price__c, Parent_Order_Line_Id__c FROM OrderItems)
                  FROM Order WHERE (Id IN: setOrderId OR OrderNumber IN: setOrderNumber OR AccountID IN: setAccountID)];
    }
    
    public static Map<String, String> getPicklistValues(String objectAPI,String fieldAPI){ 
        Map<String, String> mapPicklist = new Map<String, String>();
        try{
            for(Schema.PicklistEntry sObjPickListEntry : Schema.getGlobalDescribe().get(objectAPI).newSObject().getSObjectType().getDescribe().fields.getMap().get(fieldAPI).getDescribe().getPickListValues()){
                mapPicklist.put(sObjPickListEntry.getValue(), sObjPickListEntry.getLabel());
                mapPicklist.put(sObjPickListEntry.getLabel(), sObjPickListEntry.getValue());
            }
        }catch(Exception ex){
            ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents_V11.getPicklistValues', 'Error while getting the Country and State Picklist information: '+ex.getMessage(), 'order', null, 'Incorrect data.', '', 'Informational');
        }
        return mapPicklist;
    }
}