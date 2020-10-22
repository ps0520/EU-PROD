public class PEClsHandleOrderEvents {
    public static final String version = '1.0';  // version of the canonical
    public static final Map<String, String> mapRecordTypeNameToID;
    public static final Map<String, String> mapAddressRecordTypeNameToID;
    public static final Map<String, Order_Event_Setting__mdt> mapOrderEventSetting;
    public static final Map<String, String> mapCountry;
    public static final Map<String, String> mapState;
    public static final Map<String, String> mapOrderTypeENUM;
    static{
        mapCountry = PEClsHandleOrderEvents.getPicklistValues('Account', 'ShippingCountryCode');
        mapState = PEClsHandleOrderEvents.getPicklistValues('Account', 'ShippingStateCode');
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
        for(Order_Event_Setting__mdt oEventSetting : [SELECT Id, Label, DeveloperName, MasterLabel, SFDC_ORDER_TYPE__c, SFDC_RECORD_TYPE__c, EBS_ORDER_TYPE__c, FUSION_ORDER_TYPE__c FROM Order_Event_Setting__mdt]){
            mapOrderEventSetting.put(oEventSetting.Label.toLowerCase(), oEventSetting);
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
        
        public OrderLineItem(String sku, Decimal quantity, Decimal price){
            this.sku =  sku;
            this.quantity = quantity;
            this.price = price;
        }
        public OrderLineItem(OrderItem oli){
            this.itemID = oli.External_Id__c != null ? oli.External_Id__c : oli.Id;
            this.sku = oli.Product2.Name;
            this.quantity = oli.Quantity;
            this.price = oli.UnitPrice;
            this.isBundle = oli.isBundle__c;
            this.isBundleItem = oli.isBundleItem__c;
            this.skuBundle = oli.SkuBundle__r.Name;
            this.url = '';
        }
        
    }
    public static void onAfterInsert(List<CRM_Order_Event__e> lstOrderEvent){
        try{
            Map<String, List<OrderLineItem>> mapOrderToOrderItems = new Map<String, List<OrderLineItem>>();
            Map<String, CRM_Order_Event__e> mapOrderEvent = new Map<String, CRM_Order_Event__e>();
            Map<String, CRM_Order_Event__e> mapOrderEventCreate = new Map<String, CRM_Order_Event__e>();
            Map<String, CRM_Order_Event__e> mapOrderEventUpdate = new Map<String, CRM_Order_Event__e>();
            Map<String, String> mapPriceBook = new Map<String, String>();
            Map<String, Order> mapDuplicateOrder = new Map<String, Order>();
            Map<String, String> mapProductPriceBookToPriceBookEntry = new Map<String, String>();
            Map<String, Finance_Detail__c> mapFinanceDetail = new Map<String, Finance_Detail__c>();
            Map<String, String> mapSKUProduct = new Map<String, String>();
            Set<String> setUniqueSOS = new Set<String>();
            Set<String> setPriceBookName = new Set<String>();
            Set<String> setAccountId = new Set<String>();
            Set<String> setProductId = new Set<String>();
            Set<String> setCardToken = new Set<String>();
            Set<String> setAddressId = new Set<String>();
            Set<String> setSKUProduct = new Set<String>();

            for(CRM_Order_Event__e oEvent : lstOrderEvent){
                if (oEvent.eventSource__c.containsIgnoreCase('crm')) {
                    system.debug('Received an event from Self. Ignoring it. Event: ' + oEvent);   // Not an error. Just seeing self published event. Vijay Adusumilli July 23, 2019.
                    continue;
                }
                String uniqueKey = oEvent.systemOfOrigin__c != null && oEvent.systemOfOriginID__c != null ? oEvent.systemOfOrigin__c.trim() + oEvent.systemOfOriginID__c.trim() : '';
                if(oEvent.version__c != version || oEvent.entityType__c == null || !oEvent.entityType__c.containsIgnoreCase('order')){
                    ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.onAfterInsert', 'Incorrect version, current version is '+version, 'order', oEvent.eventSourceID__c, 'Incorrect verion. eventSource: ' + oEvent.eventSource__c + ' eventSourceID: ' + oEvent.eventSourceID__c + '. Will not be processed.', oEvent.eventSourceID__c, 'Informational');
                    continue;
                }
                setUniqueSOS.add(uniqueKey);
                setPriceBookName.add(oEvent.pricebookName__c);
                setAccountId.add(oEvent.accountID__c);

                if(oEvent.creditCardToken__c != null && oEvent.creditCardToken__c != 'null') setCardToken.add(oEvent.creditCardToken__c); 
                if(oEvent.shippingAddressId__c != null && oEvent.shippingAddressId__c != 'null' ) setAddressId.add(oEvent.shippingAddressId__c);
                if(oEvent.billingAddressId__c != null && oEvent.billingAddressId__c != 'null') setAddressId.add(oEvent.billingAddressId__c);
                
                if(oEvent.shippingAddressAccountID__c != null && oEvent.shippingAddressAccountID__c != 'null' ) setAccountId.add(oEvent.shippingAddressAccountID__c);
                if(oEvent.billingAddressAccountID__c != null && oEvent.billingAddressAccountID__c != 'null') setAccountId.add(oEvent.billingAddressAccountID__c); 
                
                if((oEvent.stage__c == 'pending' ||oEvent.stage__c == 'confirmed' ) && (oEvent.operation__c == 'create'|| oEvent.operation__c == 'update') && ((oEvent.eventSource__c != null && oEvent.eventSource__c.containsIgnoreCase('ECOM')) || (oEvent.eventSource__c != null && oEvent.eventSource__c.containsIgnoreCase('OMS')))){
                    if(oEvent.stage__c == 'pending' && oEvent.operation__c == 'update' && oEvent.eventSource__c.containsIgnoreCase('OMS')){
                        uniqueKey = oEvent.orderNumber__c;
                        mapOrderEventUpdate.put(oEvent.orderNumber__c, oEvent);
                    }else if(oEvent.stage__c == 'confirmed' && oEvent.operation__c == 'create' && oEvent.eventSource__c != null && oEvent.eventSource__c.containsIgnoreCase('OMS')){
                        uniqueKey = oEvent.orderNumber__c;
                        mapOrderEvent.put(oEvent.orderNumber__c, oEvent);
                    }else {
                        uniqueKey = oEvent.systemOfOrigin__c.trim() + oEvent.systemOfOriginID__c.trim();
                        mapOrderEventCreate.put(uniqueKey, oEvent);
                    }
                    if(oEvent.Line_Items__c != null) {
                        mapOrderToOrderItems.put(uniqueKey, (List<OrderLineItem>)JSON.deserialize(oEvent.Line_Items__c, List<OrderLineItem>.class));
                        for(OrderLineItem oli : mapOrderToOrderItems.get(uniqueKey)){
                            setProductId.add(oli.sku);
                            if(oli.skuBundle != null && oli.skuBundle != 'null'){
                                setSKUProduct.add(oli.skuBundle); 
                            }
                        }
                    }
                }
            }
            Map<String, Account> mapAccount = new Map<String, Account>([SELECT Id, Name, RecordType.DeveloperName, Sync_Status__c FROM Account WHERE Id IN: setAccountId]);
            Map<String, Address__c> mapAddress = new Map<String, Address__c>();
            for(Address__c objAddress : [SELECT Id, Oracle_Cust_Site_Id__c, Business_Name__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, City__c, Country__c, First_Name__c, Last_Name__c, Postal_Code__c, Primary_Phone__c, State__c, SOS_Unique_ID__c, Type__c, Account__c, Inactive__c, IsLocked__c FROM Address__c WHERE (Id IN: setAddressId OR Oracle_Cust_Site_Id__c IN: setAddressId) AND Account__c IN: setAccountId]){
                mapAddress.put(objAddress.Id, objAddress);
                if(objAddress.Oracle_Cust_Site_Id__c != null && objAddress.Account__c != null) mapAddress.put(objAddress.Account__c +'_'+ objAddress.Oracle_Cust_Site_Id__c, objAddress);
                if(objAddress.Oracle_Cust_Site_Id__c != null) mapAddress.put(objAddress.Oracle_Cust_Site_Id__c, objAddress);
            }
            
            for(Product2 product : [SELECT Id, Name FROM Product2 WHERE Name IN: setSKUProduct]) mapSKUProduct.put(product.Name, product.Id);
            for(Pricebook2 priceBook : [SELECT Id, Name FROM Pricebook2 WHERE Name IN: setPriceBookName]) mapPriceBook.put(priceBook.Name, priceBook.Id);
            for(PricebookEntry pbe : [SELECT Id, Product2.Name, Pricebook2Id, Pricebook2.Name FROM PricebookEntry WHERE Product2.Name IN: setProductId AND Pricebook2Id IN: mapPriceBook.values()]) {
                mapProductPriceBookToPriceBookEntry.put(pbe.Product2.Name +'_'+ pbe.Pricebook2Id, pbe.Id);
            }
            for(Finance_Detail__c fd : [SELECT Id, Token__c, Expiry_Date__c FROM Finance_Detail__c WHERE Token__c IN: setCardToken AND Account__c IN: mapAccount.keySet()]) mapFinanceDetail.put(fd.Token__c, fd);
            List<User> lstUser = [SELECT Id, Name FROM User WHERE FirstName = 'Salesforce' AND LastName = 'Admin' AND Profile.Name LIKE 'System Administrator' LIMIT 1];
            
            if(!mapOrderEventCreate.isEmpty()){
                for(Order objOrder: [SELECT Id, SOS_Unique_ID__c FROM Order WHERE SOS_Unique_ID__c IN: setUniqueSOS]) mapDuplicateOrder.put(objOrder.SOS_Unique_ID__c, objOrder);
                createOrder(mapAccount, mapPriceBook, mapDuplicateOrder, mapOrderToOrderItems, mapProductPriceBookToPriceBookEntry, mapFinanceDetail, mapAddress, mapOrderEventCreate, lstUser.isEmpty() ? null : lstUser[0].Id, mapSKUProduct);
            }
            if(!mapOrderEvent.isEmpty()){
              
                updateOrderStatus(mapAccount, mapPriceBook, mapDuplicateOrder, mapOrderToOrderItems, mapProductPriceBookToPriceBookEntry, mapFinanceDetail, mapAddress, mapOrderEvent);
               
            }
            if(!mapOrderEventUpdate.isEmpty()){
                
                updateOrderOMS(mapAccount, mapPriceBook, mapDuplicateOrder, mapOrderToOrderItems, mapProductPriceBookToPriceBookEntry, mapFinanceDetail, mapAddress, mapOrderEventUpdate, mapSKUProduct);
            }
        }catch(Exception ex){
            ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.onAfterInsert', 'Error: '+ex.getMessage()+' @ line no: '+ ex.getLineNumber(), 'order', null, 'Incorrect data.', '', 'Informational');
        }
        
        Integer hrid = 0;
        for(CRM_Order_Event__e ev : lstOrderEvent) if (hrid < Integer.valueOf(ev.ReplayId)) hrid = Integer.valueOf(ev.ReplayId);
        system.debug('Setting the SetResumeChekpoint to ReplayId: ' + hrid);
        EventBus.TriggerContext.currentContext().setResumeCheckpoint(String.valueOf(hrid));
    }
    private static void updateOrderStatus(Map<String, Account> mapAccount, Map<String, String> mapPriceBook, Map<String, Order> mapDuplicateOrder, Map<String, List<OrderLineItem>> mapOrderToOrderItems, Map<String, String> mapProductPriceBookToPriceBookEntry, Map<String, Finance_Detail__c> mapFinanceDetail, Map<String, Address__c> mapAddress, Map<String, CRM_Order_Event__e> mapOrderEvent){
        //need to add orderitem logic...
        List<Order> lstOrder = new List<Order>();
        List<Id> lstOrderId = new List<Id>();
        Map<String, Order> mapOrder = new Map<String, Order>();
        for(Order objOrder: [SELECT Id, OrderNumber, Status, OMS_Order_Number__c FROM Order WHERE OrderNumber IN: mapOrderEvent.keySet() OR OMS_Order_Number__c IN: mapOrderEvent.keySet()]) {
            mapOrder.put(objOrder.OrderNumber, objOrder);
            if(objOrder.OMS_Order_Number__c != null) mapOrder.put(objOrder.OMS_Order_Number__c, objOrder);
        }
        for(String uniqueKey : mapOrderEvent.keySet()){
            if(!mapOrder.containsKey(uniqueKey)){
                ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.updateOrderStatus', 'Order is not present in Salesforce with OrderNumber' + mapOrderEvent.get(uniqueKey).orderNumber__c, 'order', mapOrderEvent.get(uniqueKey).eventSourceID__c, 'Incorrect order number. eventSource: ' + mapOrderEvent.get(uniqueKey).eventSource__c + ' eventSourceID: ' + mapOrderEvent.get(uniqueKey).eventSourceID__c + '. Will not be processed.', mapOrderEvent.get(uniqueKey).eventSourceID__c, 'Informational');
                continue;
            }
            lstOrder.add(new Order(Id = mapOrder.get(uniqueKey).Id, Status = 'Booked', OMS_Order_Number__c = mapOrderEvent.get(uniqueKey).eventSourceId__c));
            lstOrderId.add(mapOrder.get(uniqueKey).Id);
        }
        //update lstOrder;
        List<Platform_Event_Error_Log__c> lstErrorLog = new List<Platform_Event_Error_Log__c>();
        List<Order> lstOrderErrorLog = new List<Order>();
        Set<String> setOrderId = new Set<String>();
        Database.SaveResult [] updateResult = Database.update(lstOrder, false);
        for(Integer i = 0; i < updateResult.size(); i++){
            if(updateResult[i].isSuccess()){
                setOrderId.add(lstOrder[i].Id);
                // lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEClsHandleOrderEvents.updateOrderStatus', 'Status updated successfully', 'order', 'OMS', 'Update Success. Order Id is: '+ lstOrder[i].Id +' Event Source Id:'+mapOrderEvent.get(lstOrder[i].OrderNumber).eventSourceID__c, mapOrderEvent.get(lstOrder[i].OrderNumber).eventSourceID__c,'Success log', ''));
            }else{
                String error = '';
                for(Database.Error err : updateResult[i].getErrors()) {
                    error += error == '' ? err.getMessage() : ', ' + err.getMessage();
                }
                lstOrderErrorLog.add(new Order(Id = lstOrder[i].Id, Integration_Error_Message__c = error.length() > 500 ? error.substring(0, 500) : error));
                lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEClsHandleOrderEvents.updateOrderStatus', 'Error while updating the Order Status', 'order', 'OMS', 'Update Failed. Order Id is: '+ lstOrder[i].Id +', Error: ' + error, 'Unknown', 'Recoverable Error - Published/Consumed', ''));
            }
        }
        Database.insert(lstErrorLog, false);
        Database.update(lstOrderErrorLog, false);
        publishOrderEvent(setOrderId,new Set<String>(), mapOrderEvent);//need to check this once again...
    }
    private static void updateOrderOMS(Map<String, Account> mapAccount, Map<String, String> mapPriceBook, Map<String, Order> mapDuplicateOrder, Map<String, List<OrderLineItem>> mapOrderToOrderItems, Map<String, String> mapProductPriceBookToPriceBookEntry, Map<String, Finance_Detail__c> mapFinanceDetail, Map<String, Address__c> mapAddress, Map<String, CRM_Order_Event__e> mapOrderEvent, Map<String, String> mapSKUProduct){
        List<OrderItem> lstOrderItemToDelete = new List<OrderItem>();
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        Map<String, Order> mapOrderNew = new Map<String, Order>();
        Map<String, Order> mapOrder = new Map<String, Order>();
        List<Id> lstOrderId = new List<Id>();
        for(Order objOrder : getOrders(new Set<String>(), mapOrderEvent.keySet(), new Set<String>())) {
            mapOrderNew.put(objOrder.OrderNumber, objOrder);
            if(objOrder.OMS_Order_Number__c != null) mapOrderNew.put(objOrder.OMS_Order_Number__c, objOrder);
        }
        for(String uniqueKey : mapOrderEvent.keySet()){
            if(!mapOrderNew.containsKey(uniqueKey)){
                ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.updateOrderOMS', 'Order is not present in salesforce with  OMS Order Number' + uniqueKey, 'order', mapOrderEvent.get(uniqueKey).eventSourceID__c, 'Incorrect pricebook. eventSource: ' + mapOrderEvent.get(uniqueKey).eventSource__c + ' eventSourceID: ' + mapOrderEvent.get(uniqueKey).eventSourceID__c + '. Will not be processed.', mapOrderEvent.get(uniqueKey).eventSourceID__c, 'Informational');
            }else{
                 mapOrder.put(mapOrderNew.get(uniqueKey).Id, orderMapping(mapOrderEvent.get(uniqueKey), null, mapPriceBook.get(mapOrderEvent.get(uniqueKey).pricebookName__c), null, null, null, mapOrderNew.get(uniqueKey), null, null, 'update'));
                 lstOrderId.add(mapOrderNew.get(uniqueKey).Id);
            }
            
            /*if(!mapOrderNew.containsKey(uniqueKey) && ((oEvent.pricebookName__c != null && !mapPriceBook.containsKey(oEvent.pricebookName__c)) || oEvent.pricebookName__c == 'null')){
                ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.updateOrderOMS', 'PriceBook is not present in Salesforce with name ' + oEvent.pricebookName__c, 'order', oEvent.eventSourceID__c, 'Incorrect pricebook. eventSource: ' + oEvent.eventSource__c + ' eventSourceID: ' + oEvent.eventSourceID__c + '. Will not be processed.', oEvent.eventSourceID__c, 'Informational');
            }else{
                Map<String, OrderItem> mapOINew = new Map<String, OrderItem>();
                if(oEvent.pricebookName__c != null && mapOrderNew.get(uniqueKey).PriceBook2.Name != oEvent.pricebookName__c){
                    lstOrderItemToDelete.addAll(mapOrderNew.get(uniqueKey).OrderItems);
                }else{
                    mapOINew = new Map<String, OrderItem>(mapOrderNew.get(uniqueKey).OrderItems);
                }
                Integer counter = 0;
                for(OrderLineItem oli : mapOrderToOrderItems.get(uniqueKey)){
                    String priceBookEntryKey = oli.sku+'_'+mapPriceBook.get(mapOrderEvent.get(uniqueKey).pricebookName__c);
                    if(mapProductPriceBookToPriceBookEntry.containsKey(priceBookEntryKey)){
                        counter++;
                        lstOrderItem.add(PEClsHandleOrderEvents.orderItemMapping(mapProductPriceBookToPriceBookEntry.get(priceBookEntryKey), oli, mapOrderNew.get(uniqueKey).Id, mapOINew.containsKey(oli.itemID) ? mapOINew.get(oli.itemID) : new OrderItem(), mapSKUProduct));
                    }else{
                        ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.updateOrderOMS', 'PricebookEntry is not present in Salesforce with sku ' + oli.sku, 'order', oEvent.eventSourceID__c, 'Incorrect product. eventSource: ' + oEvent.eventSource__c + ' eventSourceID: ' + oEvent.eventSourceID__c + '. Will not be processed.', oEvent.eventSourceID__c, 'Informational');
                    }
                }
                if(counter == mapOrderToOrderItems.get(uniqueKey).size()){
                    mapOrder.put(mapOrderNew.get(uniqueKey).Id, orderMapping(oEvent, null, mapPriceBook.get(oEvent.pricebookName__c), null, null, null, mapOrderNew.get(uniqueKey), null, null, 'update'));
                }else{
                    ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.updateOrderOMS', 'Order Item are missing due to not having pricebook for Order Number' + uniqueKey, 'order', oEvent.eventSourceID__c, 'Incorrect product. eventSource: ' + oEvent.eventSource__c + ' eventSourceID: ' + oEvent.eventSourceID__c + '. Will not be processed.', oEvent.eventSourceID__c, 'Informational');
                }
            }*/
        }
        //update mapOrder.values();
        List<Platform_Event_Error_Log__c> lstErrorLog = new List<Platform_Event_Error_Log__c>();
        List<Order> lstOrderErrorLog = new List<Order>();
        List<Order> lstOrder = mapOrder.values();
        Set<String> setOrderId = new Set<String>();
        Database.SaveResult [] updateResult = Database.update(lstOrder, false);
        for(Integer i = 0; i < updateResult.size(); i++){
            if(updateResult[i].isSuccess()){
                setOrderId.add(lstOrder[i].Id);
                //lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEClsHandleOrderEvents.updateOrderOMS', 'Status updated successfully', 'order', 'OMS', 'Update Success.Order Id is: '+ lstOrder[i].Id +' Event Source Id:'+mapOrderEvent.get(lstOrder[i].OrderNumber).eventSourceID__c, mapOrderEvent.get(lstOrder[i].OrderNumber).eventSourceID__c, 'Success log', ''));
            }else{
                String error = '';
                for(Database.Error err : updateResult[i].getErrors()) {
                    error += error == '' ? err.getMessage() : ', ' + err.getMessage();
                }
                lstOrderErrorLog.add(new Order(Id = lstOrder[i].Id, Integration_Error_Message__c = error.length() > 500 ? error.substring(0, 500) : error));
                lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEClsHandleOrderEvents.updateOrderOMS', 'Error while updating the Order Status: '+error +' Order Id'+lstOrder[i].Id, 'order', 'OMS', 'Update Failed Order Id is: '+ lstOrder[i].Id +' Event Source Id: Unknown','','Recoverable Error - Published/Consumed', ''));
            }
        }
        Database.update(lstOrderErrorLog, false);
        Database.insert(lstErrorLog, false);
        publishOrderEvent(setOrderId, new Set<String>(), mapOrderEvent);
    }
    private static void createOrder(Map<String, Account> mapAccount, Map<String, String> mapPriceBook, Map<String, Order> mapDuplicateOrder, Map<String, List<OrderLineItem>> mapOrderToOrderItems, Map<String, String> mapProductPriceBookToPriceBookEntry, Map<String, Finance_Detail__c> mapFinanceDetail, Map<String, Address__c> mapAddress, Map<String, CRM_Order_Event__e> mapOrderEvent, String ownerId, Map<String, String> mapSKUProduct){
        Map<String, Order> mapOrder = new Map<String, Order>();
        Map<String, Order> mapOrderNew = new Map<String, Order>();
        Map<String, List<OrderItem>> mapListOrderItem = new Map<String, List<OrderItem>>();
        Map<String, Finance_Detail__c> mapFinanceDetailToInsert = new Map<String,Finance_Detail__c>();
        Map<String, Address__c> mapAddressToInsert = new Map<String, Address__c>();
        Map<String, Address__c> mapAddressToUpsert = new Map<String, Address__c>();
        Map<String, CRM_Order_Event__e> mapOrderEventToErrorHandle = new Map<string, CRM_Order_Event__e>();
        Map<Id, Order> mapOrderToUpdate = new Map<Id, Order>();
        Set<String> setOrderId = new Set<String>();
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        Map<String, Address__c> mapAddressToLocked = new Map<String, Address__c>();
        for(CRM_Order_Event__e oEvent : mapOrderEvent.values()){
            //Added this condition on 09/05/2019 as per new request for source as OMS bu Vijay  
            /*if(oEvent.eventSource__c.containsIgnoreCase('OMS') && (oEvent.billingAddressId__c == null || !mapAddress.containsKey(oEvent.billingAddressId__c) || oEvent.shippingAddressId__c  == null || !mapAddress.containsKey(oEvent.shippingAddressId__c) || !mapAccount.containsKey(oEvent.billingAddressAccountID__c) || !mapAccount.containsKey(oEvent.shippingAddressAccountID__c))){
                ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.createOrder', 'Address Id or Address Account Id is not available in Salesforce. Please check Canonical' + oEvent.systemOfOriginID__c, 'order', oEvent.eventSourceID__c, 'Address information is not correct tocreate the order. eventSource: ' + oEvent.eventSource__c + ' eventSourceID: ' + oEvent.eventSourceID__c + '. Will not be processed.', oEvent.eventSourceID__c, 'Informational');
                continue;
            }*/

            String uniqueKey = oEvent.systemOfOrigin__c.trim() + oEvent.systemOfOriginID__c.trim();
            //Calculate Order Amount as there is no direct field on Canonical that provides the value
            double orderValue = 0.0; // Vijay Adusumilli March 17, 2020
            for(OrderLineItem oi : mapOrderToOrderItems.get(uniqueKey)) orderValue += oi.price * oi.quantity;  // Vijay Adusumilli March 17, 2020
            if(orderValue != null && orderValue > 0.0 && (oEvent.creditCardAuthorizationCode__c == null || oEvent.creditCardAuthorizationCode__c == 'null' || oEvent.creditCardAuthorizationCode__c == '') && !oEvent.eventSource__c.containsIgnoreCase('OMS') ){
                ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleOrderEvents.createOrder', 'AuthorizationCode is required for Order processing.', 'order', oEvent.eventSourceID__c, 'Incorrect data. eventSource: ' + oEvent.eventSource__c + ' eventSourceID: ' + oEvent.eventSourceID__c + '. Will not be processed.', oEvent.eventSourceID__c, 'Informational', String.valueOf(oEvent));
                continue;
            }
            String countryCode = oEvent.shippingAddressCountryCode__c != null ? oEvent.shippingAddressCountryCode__c.trim(): mapAccount.containsKey(oEvent.accountID__c) ? mapAccount.get(oEvent.accountID__c).RecordType.DeveloperName.substring(0,2) : '';
            String recordTypeName = Test.isRunningTest() ? 'de sales order' : oEvent.orderType__c != null && mapOrderEventSetting.containsKey(oEvent.orderType__c.toLowerCase()) && mapOrderEventSetting.get(oEvent.orderType__c.toLowerCase()).SFDC_RECORD_TYPE__c != null ? mapOrderEventSetting.get(oEvent.orderType__c.toLowerCase()).SFDC_RECORD_TYPE__c.toLowerCase() : '';
            String orderType = Test.isRunningTest() ? 'DE STANDARD' : oEvent.orderType__c;
            
            if(oEvent.eventSource__c.containsIgnoreCase('OMS') && (mapDuplicateOrder.containsKey(uniqueKey) || !mapAccount.containsKey(oEvent.accountID__c) || !mapPriceBook.containsKey(oEvent.pricebookName__c) || !mapRecordTypeNameToID.containsKey(recordTypeName) || ownerId == null)){
                String errorMsg = !mapAccount.containsKey(oEvent.accountID__c) ? 'Account Id is missing in Salesforce : '+ oEvent.accountID__c : '';
                errorMsg += String.isEmpty(errorMsg) && mapDuplicateOrder.containsKey(uniqueKey) ? 'Duplicate Order found in Salesforce with SF ID: ' +mapDuplicateOrder.get(uniqueKey).Id : String.isNotBlank(errorMsg) && mapDuplicateOrder.containsKey(uniqueKey) ?  ', Duplicate Order found in Salesforce with SF ID: ' +mapDuplicateOrder.get(uniqueKey).Id : '';
                errorMsg += String.isEmpty(errorMsg) && !mapPriceBook.containsKey(oEvent.pricebookName__c) ? 'PriceBook is not found in Salesforce with Name: ' +oEvent.pricebookName__c : String.isNotBlank(errorMsg) && !mapPriceBook.containsKey(oEvent.pricebookName__c) ? ', PriceBook is not found in Salesforce with Name: ' +oEvent.pricebookName__c : '';
                errorMsg += String.isEmpty(errorMsg) && !mapRecordTypeNameToID.containsKey(recordTypeName) ? 'RecordType is not found in Salesforce with Name: ' + recordTypeName : String.isNotBlank(errorMsg) && !mapRecordTypeNameToID.containsKey(recordTypeName) ? ', RecordType is not found in Salesforce with Name: ' + recordTypeName : '';
                errorMsg += String.isEmpty(errorMsg) && ownerId == null ? 'Could not get Salesforce Admin Id. Can\'t processing Create Operations' : ownerId == null ? 'Could not get Salesforce Admin Id. Can\'t processing Create Operations' : '';
                ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.createOrder', errorMsg, 'order', oEvent.eventSourceID__c, 'Incorrect data. eventSource: ' + oEvent.eventSource__c + ' eventSourceID: ' + oEvent.eventSourceID__c + '. Will not be processed.', oEvent.eventSourceID__c, 'Informational');
                continue;
            }else if(!oEvent.eventSource__c.containsIgnoreCase('OMS') && (mapDuplicateOrder.containsKey(uniqueKey) || !mapAccount.containsKey(oEvent.accountID__c) || !mapPriceBook.containsKey(oEvent.pricebookName__c) || !mapRecordTypeNameToID.containsKey(recordTypeName) 
                || (oEvent.billingAddressId__c != null && oEvent.billingAddressId__c != 'null' && !mapAddress.containsKey(oEvent.billingAddressId__c)) || (oEvent.shippingAddressId__c != null && oEvent.shippingAddressId__c != 'null' && !mapAddress.containsKey(oEvent.shippingAddressId__c)) || ownerId == null)){
                String errorMsg = !mapAccount.containsKey(oEvent.accountID__c) ? 'Account Id is missing in Salesforce : '+ oEvent.accountID__c : '';
                errorMsg += String.isEmpty(errorMsg) && mapDuplicateOrder.containsKey(uniqueKey) ? 'Duplicate Order found in Salesforce with SF ID: ' +mapDuplicateOrder.get(uniqueKey).Id : String.isNotBlank(errorMsg) && mapDuplicateOrder.containsKey(uniqueKey) ?  ', Duplicate Order found in Salesforce with SF ID: ' +mapDuplicateOrder.get(uniqueKey).Id : '';
                errorMsg += String.isEmpty(errorMsg) && !mapPriceBook.containsKey(oEvent.pricebookName__c) ? 'PriceBook is not found in Salesforce with Name: ' +oEvent.pricebookName__c : String.isNotBlank(errorMsg) && !mapPriceBook.containsKey(oEvent.pricebookName__c) ? ', PriceBook is not found in Salesforce with Name: ' +oEvent.pricebookName__c : '';
                errorMsg += String.isEmpty(errorMsg) && !mapRecordTypeNameToID.containsKey(recordTypeName) ? 'RecordType is not found in Salesforce with Name: ' + recordTypeName : String.isNotBlank(errorMsg) && !mapRecordTypeNameToID.containsKey(recordTypeName) ? ', RecordType is not found in Salesforce with Name: ' + recordTypeName : '';
                errorMsg += String.isEmpty(errorMsg) && oEvent.billingAddressId__c != null && oEvent.billingAddressId__c != 'null' && !mapAddress.containsKey(oEvent.billingAddressId__c) ? 'Billing Address not found in salesforce with ID ' + oEvent.billingAddressId__c : oEvent.billingAddressId__c != null && oEvent.billingAddressId__c != 'null' && !mapAddress.containsKey(oEvent.billingAddressId__c)? ', Biiling Address not found in salesforce with ID ' +oEvent.billingAddressId__c : '';
                errorMsg += String.isEmpty(errorMsg) && oEvent.shippingAddressId__c != null && oEvent.shippingAddressId__c != 'null' && !mapAddress.containsKey(oEvent.shippingAddressId__c) ?   'Shipping Address not found in Salesforce with ID : ' + oEvent.shippingAddressId__c : oEvent.shippingAddressId__c != null && oEvent.shippingAddressId__c != 'null' && !mapAddress.containsKey(oEvent.shippingAddressId__c) ? ', Shipping Address not found in Salesforce with ID: ' + oEvent.shippingAddressId__c : '';
                errorMsg += String.isEmpty(errorMsg) && ownerId == null ? 'Could not get Salesforce Admin Id. Can\'t processing Create Operations' : ownerId == null ? 'Could not get Salesforce Admin Id. Can\'t processing Create Operations' : '';
                ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.createOrder', errorMsg, 'order', oEvent.eventSourceID__c, 'Incorrect data. eventSource: ' + oEvent.eventSource__c + ' eventSourceID: ' + oEvent.eventSourceID__c + '. Will not be processed.', oEvent.eventSourceID__c, 'Informational');
                continue;
            }
            mapListOrderItem.put(uniqueKey, new List<OrderItem>());
            for(OrderLineItem oli : mapOrderToOrderItems.get(uniqueKey)){
                String priceBookEntryKey = oli.sku+'_'+mapPriceBook.get(oEvent.pricebookName__c);
                if(mapProductPriceBookToPriceBookEntry.containsKey(priceBookEntryKey)){
                    mapListOrderItem.get(uniqueKey).add(PEClsHandleOrderEvents.orderItemMapping(mapProductPriceBookToPriceBookEntry.get(priceBookEntryKey),oli, null, new OrderItem(), mapSKUProduct, oEvent.eventSource__c));
                }else{ 
                    ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.createOrder', 'Price Book Entry not found to create the Order Item for product : ' + oli.sku, 'order', oEvent.eventSourceID__c, 'Incorrect data. eventSource: ' + oEvent.eventSource__c + ' eventSourceID: ' + oEvent.eventSourceID__c + '. Will not be processed.', oEvent.eventSourceID__c, 'Informational');
                }
            }
            if(mapListOrderItem.get(uniqueKey).size() == mapOrderToOrderItems.get(uniqueKey).size()){
                String billingAddressID = null;
                String shippingAddressID = null;
                //added if condition for OMS as suggested by Vijay.
                String addRecordTypeName = oEvent.shippingAddressCountryCode__c != null ? oEvent.shippingAddressCountryCode__c.trim().toLowerCase() +'_address' : mapAccount.containsKey(oEvent.accountID__c) ? mapAccount.get(oEvent.accountID__c).RecordType.DeveloperName.substring(0,1) +'_address':'';
                if(oEvent.eventSource__c.containsIgnoreCase('OMS')){
                    Boolean isBASalesforceId = oEvent.billingAddressId__c != null && Pattern.compile( '[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}' ).matcher(oEvent.billingAddressId__c).matches();
                    Boolean isSASalesforceId = oEvent.shippingAddressId__c != null && Pattern.compile( '[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}' ).matcher(oEvent.shippingAddressId__c).matches();
                    
                    billingAddressID = (isBASalesforceId && mapAddress.containsKey(oEvent.billingAddressId__c)) ? mapAddress.get(oEvent.billingAddressId__c).Id : (oEvent.billingAddressId__c != null && mapAddress.containsKey(oEvent.billingAddressAccountID__c+'_'+oEvent.billingAddressId__c)) ?  mapAddress.get(oEvent.billingAddressAccountID__c+'_'+oEvent.billingAddressId__c).Id : null;
                    shippingAddressID = (isSASalesforceId && mapAddress.containsKey(oEvent.shippingAddressId__c)) ? mapAddress.get(oEvent.shippingAddressId__c).Id : (oEvent.shippingAddressId__c != null && mapAddress.containsKey(oEvent.shippingAddressAccountID__c+'_'+oEvent.shippingAddressId__c)) ?  mapAddress.get(oEvent.shippingAddressAccountID__c+'_'+oEvent.shippingAddressId__c).Id : null;
                    
                    if(billingAddressID == null){
                        Address__c address = addressMapping(oEvent, null, mapAddressRecordTypeNameToID.get(addRecordTypeName), 'BillTo');
                        address.Oracle_Cust_Site_Id__c = oEvent.billingAddressId__c == null || mapAddress.containsKey(oEvent.billingAddressId__c) || oEvent.billingAddressId__c == 'null' ? null :  oEvent.billingAddressId__c;
                        mapAddressToInsert.put(uniqueKey+'_BillTo', address);
                    }
                    
                    if(shippingAddressID == null){
                        Address__c address = addressMapping(oEvent, null, mapAddressRecordTypeNameToID.get(addRecordTypeName), 'ShipTo');
                        address.Oracle_Cust_Site_Id__c = oEvent.shippingAddressId__c == null || mapAddress.containsKey(oEvent.shippingAddressId__c) ||  oEvent.shippingAddressId__c == 'null' ? null :  oEvent.shippingAddressId__c;
                        mapAddressToInsert.put(uniqueKey+'_ShipTo', address);
                    }
                    
                    if(mapAddress.containsKey(oEvent.billingAddressId__c) && !mapAddress.get(oEvent.billingAddressId__c).isLocked__c){
                        mapAddressToLocked.put(mapAddress.get(oEvent.billingAddressId__c).Id, new Address__c(Id = mapAddress.get(oEvent.billingAddressId__c).Id, isLocked__c = true));
                    }
                    if(mapAddress.containsKey(oEvent.shippingAddressId__c) && !mapAddress.get(oEvent.shippingAddressId__c).isLocked__c){
                        mapAddressToLocked.put(mapAddress.get(oEvent.shippingAddressId__c).Id, new Address__c(Id = mapAddress.get(oEvent.shippingAddressId__c).Id, isLocked__c = true));
                    }
                }else{
                    
                    if(mapAddress.containsKey(oEvent.billingAddressId__c) && !mapAddress.get(oEvent.billingAddressId__c).isLocked__c && isBillingAddressChanged(mapAddress.get(oEvent.billingAddressId__c), oEvent)){
                        mapAddressToUpsert.put(uniqueKey+'_BillTo', addressMapping(oEvent, mapAddress.get(oEvent.billingAddressId__c).Id, mapAddressRecordTypeNameToID.get(addRecordTypeName), 'BillTo'));
                    }else if(!mapAddress.containsKey(oEvent.billingAddressId__c) || (mapAddress.containsKey(oEvent.billingAddressId__c) && mapAddress.get(oEvent.billingAddressId__c).isLocked__c && isBillingAddressChanged(mapAddress.get(oEvent.billingAddressId__c), oEvent))){
                        mapAddressToInsert.put(uniqueKey+'_BillTo', addressMapping(oEvent, null, mapAddressRecordTypeNameToID.get(addRecordTypeName), 'BillTo'));
                    }
                    //note need to add condition if Address is locked then create new address...
                    if(mapAddress.containsKey(oEvent.shippingAddressId__c) && !mapAddress.get(oEvent.shippingAddressId__c).isLocked__c && isBillingAddressChanged(mapAddress.get(oEvent.shippingAddressId__c), oEvent)){
                        mapAddressToUpsert.put(uniqueKey+'_ShipTo', addressMapping(oEvent, mapAddress.get(oEvent.shippingAddressId__c).Id, mapAddressRecordTypeNameToID.get(addRecordTypeName), 'ShipTo'));
                    }else if(!mapAddress.containsKey(oEvent.shippingAddressId__c) || (mapAddress.containsKey(oEvent.shippingAddressId__c) && !mapAddress.get(oEvent.shippingAddressId__c).isLocked__c && isBillingAddressChanged(mapAddress.get(oEvent.shippingAddressId__c), oEvent))){
                        mapAddressToInsert.put(uniqueKey+'_ShipTo', addressMapping(oEvent, null, mapAddressRecordTypeNameToID.get(addRecordTypeName), 'ShipTo'));
                    }
                    billingAddressID = mapAddress.containsKey(oEvent.billingAddressId__c) && !isBillingAddressChanged(mapAddress.get(oEvent.billingAddressId__c), oEvent) ? mapAddress.get(oEvent.billingAddressId__c).Id : null;
                    shippingAddressID= mapAddress.containsKey(oEvent.shippingAddressId__c) && !isShippingAddressChanged(mapAddress.get(oEvent.shippingAddressId__c), oEvent) ? mapAddress.get(oEvent.shippingAddressId__c).Id: null;
                }
                String fdId = mapFinanceDetail.containsKey(oEvent.creditCardToken__c) ? mapFinanceDetail.get(oEvent.creditCardToken__c).Id : null;
                mapOrder.put(uniqueKey, orderMapping(oEvent, mapRecordTypeNameToID.get(recordTypeName), mapPriceBook.get(oEvent.pricebookName__c), shippingAddressID, billingAddressID, fdId, new Order(), ownerId, orderType, 'create'));
                if(fdId != null && mapFinanceDetail.get(oEvent.creditCardToken__c).Expiry_Date__c != oEvent.creditCardExpirationDate__c) mapFinanceDetailToInsert.put(uniqueKey, new Finance_Detail__c(Id = fdId, Expiry_Date__c = oEvent.creditCardExpirationDate__c));
                if(fdId == null && oEvent.creditCardToken__c != null && oEvent.creditCardToken__c != 'null') mapFinanceDetailToInsert.put(uniqueKey, PEClsHandleOrderEvents.mappingFinancialDetail(oEvent, new Order()));
            }
        }
        Map<String, String> mapDuplicateAddressIds = PEClsHandleOrderEvents.findDuplicateAddress(mapAddressToInsert);
        Map<String, Address__c> mapDuplicateAddress = new Map<String, Address__c>([SELECT Id, isLocked__c FROM Address__c WHERE Id IN: mapDuplicateAddressIds.values()]);
        for(String key : mapAddressToInsert.keySet()){
            if(mapDuplicateAddressIds.containsKey(key)) {
                CRM_Order_Event__e oEvent = mapOrderEvent.get(key.split('_')[0]);
                if(oEvent != null && oEvent.eventSource__c.containsIgnoreCase('OMS')){
                    if(mapOrder.containsKey(key.split('_')[0]) && key.split('_')[1] == 'BillTo' && !mapDuplicateAddress.get(mapDuplicateAddressIds.get(key)).isLocked__c){
                        mapOrder.get(key.split('_')[0]).Customer_Bill_To_Address__c = mapDuplicateAddressIds.get(key); 
                        mapAddressToLocked.put(mapDuplicateAddressIds.get(key), new Address__c(Id = mapDuplicateAddressIds.get(key), isLocked__c = true, Oracle_Cust_Site_Id__c = oEvent.billingAddressId__c));
                    }else if(mapOrder.containsKey(key.split('_')[0]) && key.split('_')[1] == 'ShipTo' && !mapDuplicateAddress.get(mapDuplicateAddressIds.get(key)).isLocked__c){
                        mapOrder.get(key.split('_')[0]).Customer_Ship_To_Address__c = mapDuplicateAddressIds.get(key);
                        mapAddressToLocked.put(mapDuplicateAddressIds.get(key), new Address__c(Id = mapDuplicateAddressIds.get(key), isLocked__c = true, Oracle_Cust_Site_Id__c = oEvent.shippingAddressId__c));
                    }else{
                        mapAddressToUpsert.put(key, mapAddressToInsert.get(key));
                    }
                    
                }else{
                    if(mapOrder.containsKey(key.split('_')[0]) && key.split('_')[1] == 'BillTo'){
                        mapOrder.get(key.split('_')[0]).Customer_Bill_To_Address__c = mapDuplicateAddressIds.get(key); 
                    }else if(mapOrder.containsKey(key.split('_')[0]) && key.split('_')[1] == 'ShipTo'){
                        mapOrder.get(key.split('_')[0]).Customer_Ship_To_Address__c = mapDuplicateAddressIds.get(key);
                    }
                    if(!mapDuplicateAddress.get(mapDuplicateAddressIds.get(key)).isLocked__c){
                        mapAddressToLocked.put(mapDuplicateAddressIds.get(key), new Address__c(Id = mapDuplicateAddressIds.get(key), isLocked__c = true));
                        //mapAddressToUpsert.put(key, new Address__c(Id = mapDuplicateAddressIds.get(key), isLocked__c = true));
                    }
                }
            }
            else {
                mapAddressToUpsert.put(key, mapAddressToInsert.get(key));
            }
        }
        List<String> lstAddressKey = new List<String>();
        List<Address__c> lstAddress = new List<Address__c>();
        Map<String, String> mapErrors = new Map<String, String>();
        Set<String> setAddressId = new Set<String>();
        for(String key : mapAddressToUpsert.keySet()){
            if(mapAddressToUpsert.get(key).Id != null && setAddressId.contains(mapAddressToUpsert.get(key).Id)) continue;
            lstAddressKey.add(key);
            lstAddress.add(mapAddressToUpsert.get(key));
            if(mapAddressToUpsert.get(key).Id != null )setAddressId.add(mapAddressToUpsert.get(key).Id);
        }
        
        Database.UpsertResult[] urList = Database.upsert(lstAddress, false);
        for(Integer i = 0; i < urList.size(); i++){
            String key = lstAddressKey[i];
            if(urList[i].isSuccess()){
                mapAddressToLocked.put(urList[i].getId(), new Address__c(Id = urList[i].getId(), isLocked__c = true));
                if(mapOrder.containsKey(key.split('_')[0]) && key.split('_')[1] == 'BillTo'){
                    mapOrder.get(key.split('_')[0]).Customer_Bill_To_Address__c = urList[i].getId(); 
                }else if(mapOrder.containsKey(key.split('_')[0]) && key.split('_')[1] == 'ShipTo'){
                    mapOrder.get(key.split('_')[0]).Customer_Ship_To_Address__c = urList[i].getId();
                }
                
            }else {
                String error = mapErrors.containsKey(key.split('_')[0]) ? mapErrors.get(key.split('_')[0]) : '';
                for(Database.Error err : urList[i].getErrors()) {
                    error += error == '' ? 'Address Error line no 256: ' +err.getMessage() : ', ' + err.getMessage();
                }
                mapErrors.put(key.split('_')[0], error);
            }
        }
        List<String> lstFDKey = new List<String>();
        List<Finance_Detail__c> lstFinanceDetail = new List<Finance_Detail__c>();
        for(String key : mapFinanceDetailToInsert.keySet()){
            lstFDKey.add(key);
            lstFinanceDetail.add(mapFinanceDetailToInsert.get(key));
        }

        urList = Database.upsert(lstFinanceDetail, false);
        for(Integer i = 0; i < urList.size(); i++){
            String key = lstFDKey[i];
            if(urList[i].isSuccess()){
                mapOrder.get(key).Finance_Detail__c = urList[i].getId(); 
            }else {
                String error = mapErrors.containsKey(key) ? mapErrors.get(key) + '@line no 273 Financial Detail Error : ' : '';
                for(Database.Error err : urList[i].getErrors()) {
                    error += error == '' ? '@line no 273 Financial Detail Error ' + err.getMessage() : ', ' + err.getMessage();
                }
                mapErrors.put(key, error);
            }
        }
        for(String key : mapErrors.keySet()){
            if(!mapOrder.containsKey(key)) continue;
            mapOrder.remove(key);
            CRM_Order_Event__e oEvent = mapOrderEvent.get(key);
            ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.createOrder', mapErrors.get(key), 'order', oEvent.eventSourceID__c, 'Incorrect data. eventSource: ' + oEvent.eventSource__c + ' eventSourceID: ' + oEvent.eventSourceID__c + '. Will not be processed.', oEvent.eventSourceID__c, 'Informational');
        }
        List<String> lstOrderKey = new List<String>();
        List<Order> lstOrder = new List<Order>();
        for(String key : mapOrder.keySet()){
            lstOrderKey.add(key);
            lstOrder.add(mapOrder.get(key));
        }   
        System.debug('======lstOrder======='+lstOrder);
        Database.SaveResult[]  srList = Database.insert(lstOrder, false);
        for(Integer i = 0; i < srList.size(); i++){
            String key = lstOrderKey[i];
            if(srList[i].isSuccess()){
                mapOrderEventToErrorHandle.put(srList[i].getId(), mapOrderEvent.get(key));
                mapOrderNew.put(srList[i].getId(), lstOrder[i]);
                if(!mapListOrderItem.containsKey(key)) continue;
                for(OrderItem ordItm : mapListOrderItem.get(key)){
                    ordItm.OrderId = srList[i].getId();
                    lstOrderItem.add(ordItm);
                }
            }else {
                String error = '';
                for(Database.Error err : srList[i].getErrors()) {
                    error += error == '' ? 'Order Error @Line no 422 :' + err.getMessage() : ', ' + err.getMessage();
                    error = error +  '; Status Code: ' + err.getStatusCode() + '; fields that affected this error: ' + err.getFields();
                }
                System.debug('======error======='+error);
                CRM_Order_Event__e oEvent = mapOrderEvent.get(key);
                ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.createOrder', 'Error while creating the order : '+error, 'order', oEvent.eventSourceID__c, 'Incorrect data. eventSource: ' + oEvent.eventSource__c + ' eventSourceID: ' + oEvent.eventSourceID__c + '. Will not be processed.', oEvent.eventSourceID__c, 'Informational');
            }
        }
        srList = Database.insert(lstOrderItem, false);
        Map<Id, Order> mapOrderToDelete = new Map<Id, Order>();        
        for(Integer i = 0; i < srList.size(); i++){    
            String key = lstOrderItem[i].OrderId;
            CRM_Order_Event__e oEvent = mapOrderEventToErrorHandle.get(key);
            if(srList[i].isSuccess()){
                if(mapOrderToDelete.containsKey(key)) continue;
                oEvent = mapOrderEventToErrorHandle.get(key);
                Order newOrder = mapOrderNew.get(key);
                newOrder.Status = oEvent != null && oEvent.stage__c == 'pending' && oEvent.operation__c == 'update' && oEvent.eventSource__c.containsIgnoreCase('OMS') && oEvent.status__c != null ? oEvent.status__c :
                                  oEvent != null && oEvent.stage__c == 'pending' && oEvent.operation__c == 'update' && oEvent.eventSource__c.containsIgnoreCase('OMS') && oEvent.status__c == null ? newOrder.Status : 
                                  oEvent != null && oEvent.stage__c == 'pending' && oEvent.operation__c == 'create' && oEvent.eventSource__c != null && oEvent.eventSource__c.containsIgnoreCase('ECOM') ? 'Activated' : 'Booked';
                mapOrderToUpdate.put(key, newOrder);
            }else {
                mapOrderToDelete.put(key, new Order(Id = key));
                mapOrderToUpdate.remove(key);
                String error = '';
                for(Database.Error err : srList[i].getErrors()) {
                    error += error == '' ? 'OrderItem Error @Line no 326 :' + err.getMessage() : ', ' + err.getMessage();
                }
                ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.createOrder', 'Error while creating the order item : '+error, 'order', oEvent.eventSourceID__c, 'Incorrect data. eventSource: ' + oEvent.eventSource__c + ' eventSourceID: ' + oEvent.eventSourceID__c + '. Will not be processed.', oEvent.eventSourceID__c, 'Informational');
            }
        }
        lstOrder = mapOrderToUpdate.values(); 
        delete mapOrderToDelete.values();
        mapOrderNew = new Map<String, Order>();
        srList = Database.update(lstOrder, false);
        for(Integer i = 0; i < srList.size(); i++){
            Order newOrder = lstOrder[i];
            if(srList[i].isSuccess()){
                ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.createOrder', 'Successfully created Order.',  'Order', mapOrderEventToErrorHandle.get(newOrder.Id).eventSourceID__c, 
                                      'Order Id: ' + newOrder.Id, mapOrderEventToErrorHandle.get(newOrder.Id).eventSourceID__c, 'Success Log');
                if(newOrder != null && mapAccount.containsKey(newOrder.AccountId) /* && mapAccount.get(newOrder.AccountId).Sync_Status__c.equalsIgnoreCase('created') */){       // Currently removing this while OMS is being set-up.
                    setOrderId.add(newOrder.Id);
                }
            }else {
                mapOrderNew.put(newOrder.Id, newOrder);
                String error = '';
                for(Database.Error err : srList[i].getErrors()) {
                    error += error == '' ? 'Order Update Error @Line no 344 :' +  err.getMessage() : ', ' + err.getMessage();
                }
                CRM_Order_Event__e orEvent = mapOrderEvent.get(newOrder.Id);
                ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.createOrder', 'Error while creating the order : '+error, 'order', orEvent.eventSourceID__c, 'Incorrect data. eventSource: ' + orEvent.eventSource__c + ' eventSourceID: ' + orEvent.eventSourceID__c + '. Will not be processed.', orEvent.eventSourceID__c, 'Informational');
            }
        }
        delete mapOrderNew.values();
        
        //finally locked the address record...  
        update mapAddressToLocked.values();
        
        if(!setOrderId.isEmpty())PEClsHandleOrderEvents.publishOrderEvent(setOrderId, new Set<String>(), mapOrderEvent);
        
    }
    
    private static Date getCurrentDate(String timeZone){
        return Date.valueOf(System.now().format('yyyy-MM-dd', timeZone));
    }
    @TestVisible private static Order orderMapping(CRM_Order_Event__e oEvent, String recordTypeID, String priceBookId, String shippingAddressID, String billingAddressID, String fdId, Order newOrder, String ownerId, String orderType, String action){
        if(action == 'create'){
            return new Order(Id = newOrder.Id, RecordTypeId = recordTypeID != null ? recordTypeID : newOrder.RecordTypeId, AccountId = oEvent.accountId__c != null ? oEvent.accountId__c : newOrder.AccountId, 
                             Invoice_Date__c = oEvent.invoiceDate__c != 'null' && !String.isBlank(oEvent.invoiceDate__c) ? Date.valueOf(oEvent.invoiceDate__c) : newOrder.Invoice_Date__c, PriceBook2Id = priceBookId, 
                             Ecom_Confirmation_Number__c = (oEvent.eventSource__c == 'ecom' && oEvent.eventSourceID__c != null) ? oEvent.eventSourceID__c : newOrder.Ecom_Confirmation_Number__c,
                             Invoice_Number__c = oEvent.invoiceNumber__c != 'null' ? oEvent.invoiceNumber__c : newOrder.Invoice_Number__c, Type = orderType != 'null' ? orderType : newOrder.Type, 
                             Status = oEvent.status__c != null && newOrder.Id != null ? oEvent.status__c  : 'Draft', System_Of_Origin__c = oEvent.systemOfOrigin__c != null ? oEvent.systemOfOrigin__c : newOrder.System_Of_Origin__c,
                             System_Of_Origin_ID__c = oEvent.systemOfOriginID__c != null ? oEvent.systemOfOriginID__c : newOrder.System_Of_Origin_ID__c, 
                             Warehouse__c = oEvent.warehouse__c != null && oEvent.warehouse__c != 'null'? oEvent.warehouse__c : newOrder.Warehouse__c,
                             Credit_Card_Authorization_Code__c = oEvent.creditCardAuthorizationCode__c != 'null' ? oEvent.creditCardAuthorizationCode__c : newOrder.Credit_Card_Authorization_Code__c,
                             Payment_Id__c = oEvent.creditCardTransactionID__c  != 'null' ? oEvent.creditCardTransactionID__c  : newOrder.Payment_Id__c,
                             Customer_Bill_To_Address__c = billingAddressID != 'null' ? billingAddressID : newOrder.Customer_Bill_To_Address__c, 
                             Customer_Ship_To_Address__c = shippingAddressID != 'null' ? shippingAddressID : newOrder.Customer_Ship_To_Address__c, 
                             Finance_Detail__c = fdId != 'null' ? fdId : newOrder.Finance_Detail__c, EffectiveDate = PEClsHandleOrderEvents.getCurrentDate('America/Los_Angeles'), OwnerId = ownerId == null ? newOrder.OwnerId : ownerId,
                             Signature_Required__c = oEvent.isSignatureRequired__c, Shipping_Method__c = oEvent.shippingMethod__c, Price_Book__c = priceBookId,CurrencyIsoCode = 'CAD',
                             SOS_Unique_ID__c = oEvent.systemOfOrigin__c+oEvent.systemOfOriginID__c, Ecom_Parent_Order__c = oEvent.parentSystemOfOriginID__c,
                             OMS_Order_Number__c = oEvent != null && (oEvent.stage__c == 'pending'|| oEvent.stage__c == 'confirmed') && oEvent.operation__c == 'create' && oEvent.eventSource__c != null && oEvent.eventSource__c.containsIgnoreCase('OMS') && oEvent.eventSourceId__c != null ? oEvent.eventSourceId__c : null);
        }else
            return new Order(Id = newOrder.Id, Status = oEvent.status__c != null && newOrder.Id != null ? oEvent.status__c  : 'Draft', 
                             Invoice_Date__c = oEvent.invoiceDate__c != 'null' && !String.isBlank(oEvent.invoiceDate__c) ? Date.valueOf(oEvent.invoiceDate__c) : newOrder.Invoice_Date__c, 
                             Invoice_Number__c = oEvent.invoiceNumber__c != 'null' ? oEvent.invoiceNumber__c : newOrder.Invoice_Number__c);     
    }
    @TestVisible private static Boolean isBillingAddressChanged(Address__c address, CRM_Order_Event__e oEvent){
        return (address.Business_Name__c != oEvent.billingAddressBusinessName__c || address.Address_Line_1__c != oEvent.billingAddress1__c || address.Address_Line_2__c != oEvent.billingAddress2__c ||
                address.Address_Line_3__c != oEvent.billingAddress3__c || address.City__c != oEvent.billingAddressCity__c || address.Country__c != oEvent.billingAddressCountry__c ||
                address.First_Name__c != oEvent.billingAddressFirstName__c || address.Last_Name__c != oEvent.billingAddressLastName__c || address.Postal_Code__c != oEvent.billingAddressPostalCode__c ||
                address.Primary_Phone__c != oEvent.billingAddressPrimaryPhone__c || address.State__c != oEvent.billingAddressStateProvince__c);
    }
    
    @TestVisible private static Boolean isShippingAddressChanged(Address__c address, CRM_Order_Event__e oEvent){
        return (address.Business_Name__c != oEvent.shippingAddressBusinessName__c || address.Address_Line_1__c != oEvent.shippingAddress1__c || address.Address_Line_2__c != oEvent.shippingAddress2__c ||
                address.Address_Line_3__c != oEvent.shippingAddress3__c || address.City__c != oEvent.shippingAddressCity__c || address.Country__c != oEvent.shippingAddressCountry__c ||
                address.First_Name__c != oEvent.shippingAddressFirstName__c || address.Last_Name__c != oEvent.shippingAddressLastName__c || address.Postal_Code__c != oEvent.shippingAddressPostalCode__c ||
                address.Primary_Phone__c != oEvent.shippingAddressPrimaryPhone__c || address.State__c != oEvent.shippingAddressStateProvince__c);
    }
    @TestVisible private static Address__c addressMapping(CRM_Order_Event__e oEvent, String recordId, String recordTypeID, String addressType){
        String billingCountry = oEvent.billingAddressCountry__c != 'null' && oEvent.billingAddressCountry__c != null ? oEvent.billingAddressCountry__c : oEvent.billingAddressCountryCode__c != null && mapCountry.containsKey(oEvent.billingAddressCountryCode__c) ? mapCountry.get(oEvent.billingAddressCountryCode__c) : null;
        String shippingCounty = oEvent.shippingAddressCountry__c != 'null' && oEvent.shippingAddressCountry__c != null ? oEvent.shippingAddressCountry__c : oEvent.shippingAddressCountryCode__c != null && mapCountry.containsKey(oEvent.shippingAddressCountryCode__c) ? mapCountry.get(oEvent.shippingAddressCountryCode__c) : null;
        String billingState = oEvent.billingAddressStateProvince__c  != 'null' && oEvent.billingAddressStateProvince__c.length() == 2 &&  mapState.containsKey(oEvent.billingAddressStateProvince__c) ? mapState.get(oEvent.billingAddressStateProvince__c) : oEvent.billingAddressStateProvince__c != 'null' && oEvent.billingAddressStateProvince__c != null && oEvent.billingAddressStateProvince__c.length() > 2 ? oEvent.billingAddressStateProvince__c : null; 
        String shippingState = oEvent.shippingAddressStateProvince__c  != 'null' && oEvent.billingAddressStateProvince__c.length() == 2 &&  mapState.containsKey(oEvent.shippingAddressStateProvince__c) ? mapState.get(oEvent.shippingAddressStateProvince__c) : oEvent.shippingAddressStateProvince__c != 'null' && oEvent.shippingAddressStateProvince__c != null && oEvent.shippingAddressStateProvince__c.length() > 2 ? oEvent.shippingAddressStateProvince__c : null; 
        Address__c address = new Address__c(Id = recordId, recordTypeID = recordTypeID, 
                                            Business_Name__c = addressType == 'BillTo' && oEvent.billingAddressBusinessName__c != 'null'? oEvent.billingAddressBusinessName__c : addressType == 'ShipTo' && oEvent.shippingAddressBusinessName__c != 'null' ? oEvent.shippingAddressBusinessName__c : null, 
                                            Address_Line_1__c = addressType == 'BillTo' && oEvent.billingAddress1__c != 'null' ? oEvent.billingAddress1__c : addressType == 'ShipTo' && oEvent.shippingAddress1__c != 'null' ? oEvent.shippingAddress1__c : null, 
                                            Address_Line_2__c = addressType == 'BillTo' && oEvent.billingAddress2__c != 'null' ? oEvent.billingAddress2__c : addressType == 'ShipTo' && oEvent.shippingAddress2__c != 'null' ? oEvent.shippingAddress2__c : null, 
                                            Address_Line_3__c = addressType == 'BillTo' && oEvent.billingAddress3__c != 'null' ? oEvent.billingAddress3__c : addressType == 'ShipTo' && oEvent.shippingAddress3__c != 'null' ? oEvent.shippingAddress3__c : null,
                                            City__c = addressType == 'BillTo' && oEvent.billingAddressCity__c != 'null' ? oEvent.billingAddressCity__c : addressType == 'ShipTo' && oEvent.shippingAddressCity__c != null ? oEvent.shippingAddressCity__c : null, 
                                            Country__c = addressType == 'BillTo' ? billingCountry : shippingCounty, State__c = addressType == 'BillTo' ?  billingState : shippingState,
                                            Type__c = addressType == 'BillTo' ?  'Bill To' : 'Ship To', 
                                            First_Name__c = addressType == 'BillTo' && oEvent.billingAddressFirstName__c != 'null' ? oEvent.billingAddressFirstName__c : addressType == 'ShipTo' && oEvent.shippingAddressFirstName__c != 'null' ? oEvent.shippingAddressFirstName__c : null, 
                                            Last_Name__c = addressType == 'BillTo' && oEvent.billingAddressLastName__c != 'null' ? oEvent.billingAddressLastName__c : addressType == 'ShipTo' && oEvent.shippingAddressLastName__c != 'null' ? oEvent.shippingAddressLastName__c : null,
                                            Postal_Code__c = addressType == 'BillTo' && oEvent.billingAddressPostalCode__c != 'null'? oEvent.billingAddressPostalCode__c : addressType == 'ShipTo' && oEvent.shippingAddressPostalCode__c != 'null' ? oEvent.shippingAddressPostalCode__c : null,
                                            Primary_Phone__c = addressType == 'BillTo' && oEvent.billingAddressPrimaryPhone__c != 'null' ? oEvent.billingAddressPrimaryPhone__c : addressType == 'ShipTo' && oEvent.shippingAddressPrimaryPhone__c != 'null' ? oEvent.shippingAddressPrimaryPhone__c : null,
                                            Primary_Flag__c = true, System_Of_Origin__c = oEvent.systemOfOrigin__c, System_Of_Origin_Id__c = oEvent.systemOfOriginID__c);
        if(recordId == null) {
            address.Account__c = addressType == 'BillTo' && oEvent.billingAddressAccountID__c != null && oEvent.billingAddressAccountID__c != 'null' ? oEvent.billingAddressAccountID__c : addressType == 'ShipTo' && oEvent.shippingAddressAccountID__c != null && oEvent.shippingAddressAccountID__c != 'null' ? oEvent.shippingAddressAccountID__c : oEvent.accountId__c;
            //address.SOS_Unique_ID__c = addressType +'_'+oEvent.systemOfOrigin__c+'_'+oEvent.systemOfOriginID__c;
        }
        return address;
    }
    @TestVisible private static OrderItem orderItemMapping(String pbeId, OrderLineItem oli, String orderID, OrderItem oItem, Map<String, String> mapSKUProduct, String eventSource){
        return new OrderItem(PriceBookEntryId = pbeId,  Quantity = oli.quantity != null ? oli.quantity : oItem.Quantity, 
                             skuBundle__c = oli.skuBundle != null && oli.skuBundle != 'null' && mapSKUProduct.containsKey(oli.skuBundle) ? mapSKUProduct.get(oli.skuBundle) : oItem.skuBundle__c,
                             orderID = orderID, UnitPrice = oli.price != null ? oli.price : oItem.UnitPrice, isBundle__c = oli.isBundle != null ?  oli.isBundle : oItem.isBundle__c, 
                             isBundleItem__c = oli.isBundleItem != null ? oli.isBundleItem : oItem.isBundleItem__c, 
                             External_Id__c = (eventSource.containsIgnoreCase('OMS') && oli.itemID != 'null') ? oli.itemID : null);
    }
    
    @TestVisible private static Finance_Detail__c mappingFinancialDetail(CRM_Order_Event__e oEvent, Order newOrder){
        return new Finance_Detail__c(Id = newOrder.Finance_Detail__c, Account__c = oEvent.accountId__c != null ? oEvent.accountId__c : newOrder.AccountId, Finance_Type__c = 'Credit Card',
                                     Token__c = oEvent.creditCardToken__c != 'null' ? oEvent.creditCardToken__c : newOrder.Finance_Detail__r.Token__c, 
                                     Card_Type__c = oEvent.creditCardType__c != 'null' ? oEvent.creditCardType__c : newOrder.Finance_Detail__r.Card_Type__c, 
                                     Expiry_Date__c = oEvent.creditCardExpirationDate__c != 'null' ? oEvent.creditCardExpirationDate__c : newOrder.Finance_Detail__r.Expiry_Date__c, 
                                     InActive__c = false, Last_4_Digits__c = oEvent.creditCardToken__c != 'null' ? oEvent.creditCardToken__c.right(4) : newOrder.Finance_Detail__r.Last_4_Digits__c);
    }
    
    
    //method that can be called from Console, Batch Class and Trigger to publish the Order Event or from Account trigger
    public static void publishOrderEvent(Set<String> setOrderId, Set<String> setAccountId, String action){
        PEClsHandleOrderEvents.publishOrderEvent(setOrderId, new Set<String>(), new Map<String, CRM_Order_Event__e>(), setAccountId, action);
    }
    @TestVisible private static void publishOrderEvent(Set<String> setOrderId, Set<String> setOrderNumber, Map<String, CRM_Order_Event__e> mapOrderEvent){
        PEClsHandleOrderEvents.publishOrderEvent(setOrderId, setOrderNumber, mapOrderEvent, new Set<String>(), null);
    }
    
    @TestVisible private static void publishOrderEvent(Set<String> setOrderId, Set<String> setOrderNumber, Map<String, CRM_Order_Event__e> mapOrderEvent, Set<String> setAccountID, String action){
        List<CRM_Order_Event_Out__e> lstOEvent = new List<CRM_Order_Event_Out__e>();
        List<Order> lstOrder = new List<Order>();
        for(Order objOrder : getOrders(setOrderId, setOrderNumber, setAccountID)){
            List<OrderLineItem> lstOLI = new List<OrderLineItem>();
            for(OrderItem oli : objOrder.OrderItems) lstOLI.add(new OrderLineItem(oli));
            String uniqueKey = objOrder.System_Of_Origin__c != null && objOrder.System_Of_Origin_ID__c != null ? objOrder.System_Of_Origin__c + objOrder.System_Of_Origin_ID__c : '';
            CRM_Order_Event__e oEvent = mapOrderEvent.containsKey(objOrder.SOS_Unique_ID__c) ? mapOrderEvent.get(objOrder.SOS_Unique_ID__c) : mapOrderEvent.containsKey(objOrder.OrderNumber) ? mapOrderEvent.get(objOrder.OrderNumber) : mapOrderEvent.get(uniqueKey);
            lstOEvent.add(mappingOrderEvent(objOrder, lstOLI, oEvent, oEvent != null && oEvent.stage__c == 'confirmed' && oEvent.operation__c == 'create' && oEvent.eventSource__c != null && oEvent.eventSource__c.containsIgnoreCase('OMS') ? 'registered' : 'confirmed', action));
            lstOrder.add(objOrder);
        }
        publishPlatformEvents(lstOEvent, lstOrder);
    }
    @TestVisible private static void publishPlatformEvents(List<CRM_Order_Event_Out__e> lstOEvent, List<Order> lstOrder){
        List<Order> lstOrderToUpdate = new List<Order>();
        List<Database.SaveResult> svrs = EventBus.publish(lstOEvent); 
        for(Integer i = 0; i < svrs.size(); i++){
            if(svrs[i].isSuccess()){
                lstOrderToUpdate.add(new Order(Id = lstOrder[i].Id, Order_Send_to_EBS_Date__c = Date.today(), Last_Sync_Date_With_Oracle__c = Date.today()));
                ErrorUtility.LogErrorWithEvent('Publish', 'PEClsHandleOrderEvents.publishOrderEvent', 'Successfully published Order Event.',  'Order', lstOEvent[i].eventSourceID__c, 
                                               'Order Id: ' + lstOEvent[i].eventSourceID__c, lstOEvent[i].eventSourceID__c, 'Success Log', String.valueOf(lstOEvent[i]));
            }else{
                ErrorUtility.LogErrorWithEvent('Publish', 'PEClsHandleOrderEvents.publishOrderEvent', 'Error in publishing Order Event.',  'Order', lstOEvent[i].eventSourceID__c, 
                                               'Order Id: ' + lstOEvent[i].eventSourceID__c +' could not be published. Error: ' + svrs[i].getErrors(), lstOEvent[i].eventSourceID__c, 'Success Log', String.valueOf(lstOEvent[i]));
            }
        }
        update lstOrderToUpdate;
    }
    @TestVisible private static CRM_Order_Event_Out__e mappingOrderEvent(Order objOrder, List<OrderLineItem> lstOLI, CRM_Order_Event__e oEvent, String stage, String action){
        return new CRM_Order_Event_Out__e(version__c = version, stage__c = stage, accountId__c = objOrder.AccountId, eventDate__c = String.valueOf(objOrder.LastModifiedDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ')), invoiceDate__c = String.valueOf(objOrder.Invoice_Date__c), invoiceNumber__c = objOrder.Invoice_Number__c, warehouse__c = objOrder.Warehouse__c,pricebookName__c = objOrder.PriceBook2.Name,
                                          operation__c = oEvent != null && oEvent.operation__c != 'null'? oEvent.operation__c : action != null ? action : 'update', systemOfOrigin__c = objOrder.System_Of_Origin__c,systemOfOriginID__c = objOrder.System_Of_Origin_ID__c, billingAddressBusinessName__c = objOrder.Customer_Bill_To_Address__r.Business_Name__c, billingAddressId__c = objOrder.Customer_Bill_To_Address__c, billingAddress1__c = objOrder.Customer_Bill_To_Address__r.Address_Line_1__c,
                                          billingAddress2__c = objOrder.Customer_Bill_To_Address__r.Address_Line_2__c, billingAddress3__c = objOrder.Customer_Bill_To_Address__r.Address_Line_3__c, billingAddressCity__c = objOrder.Customer_Bill_To_Address__r.City__c, billingAddressCountry__c = objOrder.Customer_Bill_To_Address__r.Country__c, billingAddressFirstName__c = objOrder.Customer_Bill_To_Address__r.First_Name__c, 
                                          billingAddressLastName__c = objOrder.Customer_Bill_To_Address__r.Last_Name__c, billingAddressPostalCode__c = objOrder.Customer_Bill_To_Address__r.Postal_Code__c, billingAddressIsLocked__c = objOrder.Customer_Bill_To_Address__r.isLocked__c, billingAddressPrimaryPhone__c = objOrder.Customer_Bill_To_Address__r.Primary_Phone__c, 
                                          shippingAddressBusinessName__c = objOrder.Customer_Ship_To_Address__r.Business_Name__c, shippingAddress1__c = objOrder.Customer_Ship_To_Address__r.Address_Line_1__c, shippingAddress2__c = objOrder.Customer_Ship_To_Address__r.Address_Line_2__c, 
                                          shippingAddress3__c = objOrder.Customer_Ship_To_Address__r.Address_Line_3__c, shippingAddressCity__c = objOrder.Customer_Ship_To_Address__r.City__c, shippingAddressCountry__c = objOrder.Customer_Ship_To_Address__r.Country__c, shippingAddressFirstName__c = objOrder.Customer_Ship_To_Address__r.First_Name__c, shippingAddressId__c = objOrder.Customer_Ship_To_Address__c,
                                          shippingAddressLastName__c = objOrder.Customer_Ship_To_Address__r.Last_Name__c, shippingAddressPostalCode__c = objOrder.Customer_Ship_To_Address__r.Postal_Code__c, shippingAddressIsLocked__c = objOrder.Customer_Ship_To_Address__r.isLocked__c, shippingAddressPrimaryPhone__c = objOrder.Customer_Ship_To_Address__r.Primary_Phone__c, 
                                          Line_Items__c = JSON.serialize(lstOLI),  
                                          creditCardAuthorizationCode__c = objOrder.Credit_Card_Authorization_Code__c, creditCardToken__c = objOrder.Finance_Detail__r.Token__c, creditCardType__c = objOrder.Finance_Detail__r.Card_Type__c, 
                                          creditCardTransactionID__c  = objOrder.Payment_Id__c, 
                                          creditCardExpirationDate__c = objOrder.Finance_Detail__r.Expiry_Date__c, orderNumber__c = objOrder.OrderNumber, creditCardId__c = objOrder.Finance_Detail__c,
                                          isSignatureRequired__c = objOrder.Signature_Required__c, shippingMethod__c = objOrder.Shipping_Method__c, billingAddressAccountID__c = objOrder.AccountId,
                                          billingAddressCountryCode__c = mapCountry.containsKey(objOrder.Customer_Bill_To_Address__r.Country__c) ? mapCountry.get(objOrder.Customer_Bill_To_Address__r.Country__c) : 'XX',
                                          shippingAddressCountryCode__c = mapCountry.containsKey(objOrder.Customer_Ship_To_Address__r.Country__c) ? mapCountry.get(objOrder.Customer_Ship_To_Address__r.Country__c) : 'XX',
                                          shippingAddressStateProvince__c = mapState.containsKey(objOrder.Customer_Ship_To_Address__r.State__c) ? mapState.get(objOrder.Customer_Ship_To_Address__r.State__c) : 'XX',
                                          billingAddressStateProvince__c = mapState.containsKey(objOrder.Customer_Bill_To_Address__r.State__c) ? mapState.get(objOrder.Customer_Bill_To_Address__r.State__c) : 'XX',
                                          shippingAddressAccountID__c = objOrder.AccountId, eventSource__c = 'crm', entityType__c = 'order', eventSourceID__c = objOrder.Id,
                                          totalAmount__c = objOrder.TotalAmount, status__c = objOrder.Status.toLowerCase(), orderType__c = objOrder.Type, parentSystemOfOriginID__c = objOrder.Ecom_Parent_Order__c);
    }
    @TestVisible private static String parseOrderType(String orderType, String origin){
        if(String.isEmpty(orderType) || String.isBlank(orderType)) return orderType;
        List<String> lstOrderType = orderType.split(' ');
        String countryCode = lstOrderType.remove(0);
        String newOrderType = String.join(lstOrderType, ' ').toUpperCase().trim();
        if(mapOrderTypeENUM.containsKey(newOrderType)){
            return origin.containsIgnoreCase('ECOM') && mapOrderEventSetting.get(mapOrderTypeENUM.get(newOrderType)).EBS_ORDER_TYPE__c != null ? countryCode +' '+ mapOrderEventSetting.get(mapOrderTypeENUM.get(newOrderType)).EBS_ORDER_TYPE__c : 
                   origin.containsIgnoreCase('CRM') && mapOrderEventSetting.get(mapOrderTypeENUM.get(newOrderType)).FUSION_ORDER_TYPE__c != null ? countryCode +' '+ mapOrderEventSetting.get(mapOrderTypeENUM.get(newOrderType)).FUSION_ORDER_TYPE__c : orderType;
        }
        return orderType;
    }
    @TestVisible private static List<Order> getOrders(Set<String> setOrderId, Set<String> setOrderNumber, Set<String> setAccountID){
       /*  If (setOrderNumber.size() > 0) */
        return [SELECT Id, Payment_Id__c, AccountId, LastModifiedDate, Invoice_Date__c, Invoice_Number__c, Type, Warehouse__c, PriceBook2.Name, System_Of_Origin__c, System_Of_Origin_ID__c, Customer_Bill_To_Address__r.Business_Name__c, Customer_Bill_To_Address__r.Address_Line_1__c, Customer_Bill_To_Address__r.Address_Line_2__c,
                       Customer_Bill_To_Address__r.Address_Line_3__c, Customer_Bill_To_Address__r.City__c, Customer_Bill_To_Address__r.Country__c, Customer_Bill_To_Address__r.First_Name__c, Customer_Bill_To_Address__r.Last_Name__c, Customer_Bill_To_Address__r.Postal_Code__c,Customer_Bill_To_Address__c,
                       Customer_Bill_To_Address__r.isLocked__c, Customer_Bill_To_Address__r.Primary_Phone__c,Customer_Bill_To_Address__r.State__c, Customer_Ship_To_Address__r.Business_Name__c, Customer_Ship_To_Address__r.Address_Line_1__c,Customer_Ship_To_Address__r.State__c,Customer_Ship_To_Address__c,
                       Customer_Ship_To_Address__r.Address_Line_2__c, Customer_Ship_To_Address__r.Address_Line_3__c, Customer_Ship_To_Address__r.City__c, Customer_Ship_To_Address__r.Country__c, Customer_Ship_To_Address__r.First_Name__c, Customer_Ship_To_Address__r.Last_Name__c,
                       Customer_Ship_To_Address__r.Postal_Code__c, Customer_Ship_To_Address__r.isLocked__c, Customer_Ship_To_Address__r.Primary_Phone__c, Credit_Card_Authorization_Code__c,  Finance_Detail__c, Finance_Detail__r.Token__c, Finance_Detail__r.Card_Type__c, Finance_Detail__r.Expiry_Date__c,
                       SOS_Unique_ID__c, Status, OrderNumber, RecordTypeId, OwnerId, Signature_Required__c, Shipping_Method__c,TotalAmount, Account.Sync_Status__c, Ecom_Confirmation_Number__c,OMS_Order_Number__c,Ecom_Parent_Order__c,
                       (SELECT Id, Product2Id, Product2.Name, Quantity, UnitPrice, isBundle__c, isBundleItem__c, SkuBundle__c, SkuBundle__r.Name, External_Id__c FROM OrderItems)
                  FROM Order WHERE (OrderNumber IN: setOrderNumber OR OMS_Order_Number__c in :setOrderNumber OR Id IN: setOrderId OR AccountID IN: setAccountID)];
       /* else {
            return [SELECT Id, AccountId, LastModifiedDate, Invoice_Date__c, Invoice_Number__c, Type, Warehouse__c, PriceBook2.Name, System_Of_Origin__c, System_Of_Origin_ID__c, Customer_Bill_To_Address__r.Business_Name__c, Customer_Bill_To_Address__r.Address_Line_1__c, Customer_Bill_To_Address__r.Address_Line_2__c,
                       Customer_Bill_To_Address__r.Address_Line_3__c, Customer_Bill_To_Address__r.City__c, Customer_Bill_To_Address__r.Country__c, Customer_Bill_To_Address__r.First_Name__c, Customer_Bill_To_Address__r.Last_Name__c, Customer_Bill_To_Address__r.Postal_Code__c,Customer_Bill_To_Address__c,
                       Customer_Bill_To_Address__r.isLocked__c, Customer_Bill_To_Address__r.Primary_Phone__c,Customer_Bill_To_Address__r.State__c, Customer_Ship_To_Address__r.Business_Name__c, Customer_Ship_To_Address__r.Address_Line_1__c,Customer_Ship_To_Address__r.State__c,Customer_Ship_To_Address__c,
                       Customer_Ship_To_Address__r.Address_Line_2__c, Customer_Ship_To_Address__r.Address_Line_3__c, Customer_Ship_To_Address__r.City__c, Customer_Ship_To_Address__r.Country__c, Customer_Ship_To_Address__r.First_Name__c, Customer_Ship_To_Address__r.Last_Name__c,
                       Customer_Ship_To_Address__r.Postal_Code__c, Customer_Ship_To_Address__r.isLocked__c, Customer_Ship_To_Address__r.Primary_Phone__c, Credit_Card_Authorization_Code__c,  Finance_Detail__c, Finance_Detail__r.Token__c, Finance_Detail__r.Card_Type__c, Finance_Detail__r.Expiry_Date__c,
                       SOS_Unique_ID__c, Status, OrderNumber, RecordTypeId, OwnerId, Signature_Required__c, Shipping_Method__c,TotalAmount, Account.Sync_Status__c, Ecom_Confirmation_Number__c,OMS_Order_Number__c,
                       (SELECT Id, Product2Id, Product2.Name, Quantity, UnitPrice, isBundle__c, isBundleItem__c, SkuBundle__c, SkuBundle__r.Name, External_Id__c FROM OrderItems)
                  FROM Order WHERE (Id IN: setOrderId OR AccountID IN: setAccountID)]; 
        } */
    }
    
    @TestVisible private static Map<String, String> findDuplicateAddress(Map<String, Address__c> mapAddress){
        if(mapAddress.isEmpty()) return new Map<String, String>();
        Map<String, String> mapKeyToAddressID = new Map<String, String>();
        Map<String, List<String>> mapAddressUniqueToKeys = new Map<String, List<String>>();
        Set<String> setAccountID = new Set<String>();
        for(String key : mapAddress.keySet()){
            String uniqueKey = PEClsHandleOrderEvents.createUniqueKey(mapAddress.get(key));
            if(!mapAddressUniqueToKeys.containsKey(uniqueKey))mapAddressUniqueToKeys.put(uniqueKey, new List<String>());
            mapAddressUniqueToKeys.get(uniqueKey).add(key);
            setAccountID.add(mapAddress.get(key).Account__c);
        }
        for(Address__c address : [SELECT Id, Business_Name__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, City__c, Country__c, First_Name__c, Last_Name__c, Postal_Code__c, Primary_Phone__c, State__c, SOS_Unique_ID__c, Type__c, Account__c, Inactive__c, IsLocked__c
                                    FROM Address__c WHERE Account__c IN: setAccountID]){
            String uniqueKey = PEClsHandleOrderEvents.createUniqueKey(address);
            if(!mapAddressUniqueToKeys.containsKey(uniqueKey)) continue;
            for(String key : mapAddressUniqueToKeys.get(uniqueKey)) mapKeyToAddressID.put(key, address.Id);
        }
        return mapKeyToAddressID;
    }
    
    @TestVisible private static String createUniqueKey(Address__c address){
        return //parseValue(address.Business_Name__c) +'_'+ parseValue(address.First_Name__c)+'_'+ parseValue(address.Last_Name__c)+'_'+ 
               parseValue(address.Address_Line_1__c)+'_'+ parseValue(address.Address_Line_2__c)+'_'+ parseValue(address.Address_Line_3__c)+'_'+ 
               parseValue(address.City__c)+'_'+ parseValue(address.State__c)+'_'+ parseValue(address.Postal_Code__c)+'_'+ 
               parseValue(address.Country__c)+'_'+ parseValue(address.Type__c)+'_'+ parseValue(address.Account__c)+'_'+ parseValue(address.Primary_Phone__c);
    }
    
    @TestVisible private static String parseValue(String value){
        return value == null || value == 'null' ? '' : value.replaceAll( '\\s+', '');
    }
    public static Map<String, String> getPicklistValues(String objectAPI,String fieldAPI){   
        Map<String, String> mapPicklist = new Map<String, String>();
        try{
            for(Schema.PicklistEntry sObjPickListEntry : Schema.getGlobalDescribe().get(objectAPI).newSObject().getSObjectType().getDescribe().fields.getMap().get(fieldAPI).getDescribe().getPickListValues()){
                mapPicklist.put(sObjPickListEntry.getValue(), sObjPickListEntry.getLabel());
                mapPicklist.put(sObjPickListEntry.getLabel(), sObjPickListEntry.getValue());
            }
        }catch(Exception ex){
            ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.getPicklistValues', 'Error while getting the Country and State Piclist information: '+ex.getMessage(), 'order', null, 'Incorrect data.', '', 'Informational');
        }
        return mapPicklist;
    }
}