global class PEBatchOrderEvent implements Database.batchable<Sobject>, Database.AllowsCallouts {
    
    private static final Map<String, String> mapRecordTypeNameToID;
    private static final Map<String, String> mapAddressRecordTypeNameToID;
    private static final Map<String, String> mapCountry;
    private static final Map<String, String> mapState;
    private static final Map<String, Order_Event_Setting__mdt> mapOrderEventSetting;
    private static final Map<String, String> mapTimeZone;
    private List<CRM_Order_Event_V1__e> lstOrderEvent;
    static{
        mapCountry = PEBatchOrderEvent.getPicklistValues('Account', 'ShippingCountryCode');
        mapState = PEBatchOrderEvent.getPicklistValues('Account', 'ShippingStateCode');
        mapRecordTypeNameToID = new Map<String, String>();  
        mapAddressRecordTypeNameToID = new Map<String, String>();
        mapOrderEventSetting = new Map<String, Order_Event_Setting__mdt>();
        mapTimeZone = new Map<String, String>();
        for(Manage_Time_Zone__mdt timeZone : [SELECT Id, Country_Code__c, Time_Zone__c FROM Manage_Time_Zone__mdt]){
            mapTimeZone.put(timeZone.Country_Code__c, timeZone.Time_Zone__c);
        }
        for(Schema.RecordTypeInfo rtInfo : Schema.SObjectType.Order.getRecordTypeInfosByName().values()){
            mapRecordTypeNameToID.put(rtInfo.getName().toLowerCase(), rtInfo.getRecordTypeId());
        }  
        for(Schema.RecordTypeInfo rtInfo : Schema.SObjectType.Address__c.getRecordTypeInfosByName().values()){
            mapAddressRecordTypeNameToID.put(rtInfo.getDeveloperName().toLowerCase(), rtInfo.getRecordTypeId());
        }
        for(Order_Event_Setting__mdt oEventSetting : [SELECT Id, Label, DeveloperName, MasterLabel, SFDC_ORDER_TYPE__c, SFDC_RECORD_TYPE__c, EBS_ORDER_TYPE__c, FUSION_ORDER_TYPE__c FROM Order_Event_Setting__mdt]){
            mapOrderEventSetting.put(oEventSetting.Label.toLowerCase(), oEventSetting);
        }
    }
    
    
    global PEBatchOrderEvent(List<CRM_Order_Event_V1__e> lstOrderEvent){
        this.lstOrderEvent = lstOrderEvent;
    }
    
    global Iterable<Sobject> start(Database.BatchableContext BC){
        return new ObjectIterator(lstOrderEvent);
    }
    
    global void execute(Database.BatchableContext BC, List<CRM_Order_Event_V1__e> lstOEvent){
        if(lstOEvent.size() == 0 || lstOEvent.size() > 1){
            ErrorUtility.LogError('Consume', 'PEBatchOrderEvent', 'Internal Salesforce Error.', 'order', 'crm', 'Batch Size is: ' + lstOEvent.size() + '. It should be 1.', '','Fatal Error - Bailing out');
            return;
        }
        if((lstOEvent[0].creditCardAuthorizationCode__c == null || lstOEvent[0].creditCardAuthorizationCode__c == 'null' || lstOEvent[0].creditCardAuthorizationCode__c == '') && lstOEvent[0].paymentTerm__c == 'net0' && lstOEvent[0].eventSource__c.containsIgnoreCase('ECOM')){
            ErrorUtility.LogErrorWithEvent('Consume', 'PEBatchOrderEvent', 'Missing CC Authorization code', 'order', lstOEvent[0].eventSourceID__c, 'AuthorizationCode is required for Order processing.', lstOEvent[0].eventSourceID__c, 'Fatal Error - Bailing out', String.valueOf(lstOEvent[0]));
            return;
        }
        String uniqueKey = lstOEvent[0].systemOfOrigin__c != null && lstOEvent[0].systemOfOriginID__c != null ? lstOEvent[0].systemOfOrigin__c.trim() + lstOEvent[0].systemOfOriginID__c.trim() : '';
        List<Order> lstOrder = [SELECT Id FROM Order WHERE SOS_Unique_ID__c =: uniqueKey];
        if(!lstOrder.isEmpty()){
            //String action, String classNMethodName, String errorMsg, String eventType, String eventSource, String exceptionError, String externalID, String severity,
            ErrorUtility.LogErrorWithEvent('Consume', 'PEBatchOrderEvent', 'Duplicate Order', 'Order', lstOEvent[0].eventSourceID__c, 'Duplicate order with record id:'+lstOrder[0].Id, lstOEvent[0].eventSourceID__c, 'Fatal Error - Bailing out', String.valueOf(lstOEvent[0]));
            return;
        }
        /*
        if(lstOEvent[0].creditCardAuthorizationCode__c == null || lstOEvent[0].creditCardAuthorizationCode__c == 'null' || lstOEvent[0].creditCardAuthorizationCode__c == ''){
            ErrorUtility.LogErrorWithEvent('Consume', 'PEBatchOrderEvent', 'Missing CC Authorization code', 'order', lstOEvent[0].eventSourceID__c, 'AuthorizationCode is required for Order processing.', lstOEvent[0].eventSourceID__c, 'Fatal Error - Bailing out', String.valueOf(lstOEvent[0]));
            return;
        }
		*/
        List<Platform_Event_Error_Log__c> lstErrorLog = new List<Platform_Event_Error_Log__c>();
        Map<String, String> mapSKUProduct = new Map<String, String>();
        Map<String, String> mapProductToPBE = new Map<String, String>();
        Set<String> setProductName = new Set<String>();
        Map<String, Address__c> mapAddress = new Map<String, Address__c>();
        String priceBookId = null;
        Boolean subPB = false;
        Map<String, Account> mapAccount = new Map<String, Account>([SELECT Id, Name, RecordType.DeveloperName, RecordType.Name FROM Account WHERE Id =: lstOEvent[0].accountID__c OR Id =: lstOEvent[0].shippingAddressId__c OR Id =: lstOEvent[0].billingAddressId__c]);
        if(lstOEvent[0].orderType__c == null || lstOEvent[0].orderType__c == 'null'){
            ErrorUtility.LogErrorWithEvent('Consume', 'PEBatchOrderEvent', 'Missing Order Type', 'Order', lstOEvent[0].eventSourceID__c, 'Order Type is null', lstOEvent[0].eventSourceID__c, 'Fatal Error - Bailing out', String.valueOf(lstOEvent[0]));
            return;
        }
        if(!mapAccount.containsKey(lstOEvent[0].accountID__c)){
            ErrorUtility.LogErrorWithEvent('Consume', 'PEBatchOrderEvent', 'Unknown Account', 'Order', lstOEvent[0].eventSourceID__c, 'Account Id not found in salesforce with Id: '+lstOEvent[0].accountID__c, lstOEvent[0].eventSourceID__c, 'Fatal Error - Bailing out', String.valueOf(lstOEvent[0]));
            return;
        }        
        for(Address__c objAddress : [SELECT Id, Oracle_Cust_Site_Id__c, Business_Name__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, City__c, Country__c, First_Name__c, Last_Name__c, Postal_Code__c, Primary_Phone__c, State__c, SOS_Unique_ID__c, Type__c, Account__c, Inactive__c, IsLocked__c 
                                       FROM Address__c WHERE (Id =: lstOEvent[0].shippingAddressId__c OR Id =: lstOEvent[0].billingAddressId__c OR Oracle_Cust_Site_Id__c =: lstOEvent[0].shippingAddressId__c  OR Oracle_Cust_Site_Id__c =: lstOEvent[0].billingAddressId__c) AND Account__c IN: mapAccount.keySet() AND InActive__c = false]){
            mapAddress.put(objAddress.Id, objAddress);
            if(objAddress.Oracle_Cust_Site_Id__c != null && objAddress.Account__c != null) mapAddress.put(objAddress.Account__c +'_'+ objAddress.Oracle_Cust_Site_Id__c, objAddress);
            if(objAddress.Oracle_Cust_Site_Id__c != null) mapAddress.put(objAddress.Oracle_Cust_Site_Id__c, objAddress);
        }
        
        List<OrderLineItem> lstOrderItem = new List<OrderLineItem>();
        if (lstOEvent[0].Line_Items__c != null && lstOEvent[0].Line_Items__c != 'null') {
            lstOrderItem = (List<OrderLineItem>)JSON.deserialize(lstOEvent[0].Line_Items__c, List<OrderLineItem>.class);
            for(OrderLineItem oli : lstOrderItem){
                setProductName.add(oli.sku);
                if(oli.skuBundle != null && oli.skuBundle != 'null') mapSKUProduct.put(oli.skuBundle, null); 
            }
        }
        for(PricebookEntry pbe : [SELECT Id, Product2.Name, Pricebook2Id, Pricebook2.Name, PriceBook2.IsSubscription__c, PriceBook2.Price_List_Target__c FROM PricebookEntry WHERE Product2.Name IN: setProductName AND Pricebook2.Name =: lstOEvent[0].pricebookName__c]) {
            priceBookId = pbe.Pricebook2Id;
            subPB = pbe.PriceBook2.IsSubscription__c;
            mapProductToPBE.put(pbe.Product2.Name, pbe.Id);
        }
        if (priceBookId == null) {
            PriceBook2 pb2 = [Select id from PriceBook2 where name =: lstOEvent[0].pricebookName__c];
            priceBookId = pb2.Id;
        }
        for(Product2 objProduct : [SELECT Id, Name FROM Product2 WHERE Name IN: mapSKUProduct.keySet()]) mapSKUProduct.put(objProduct.Name, objProduct.Id);
        List<Finance_Detail__c> lstFD = new List<Finance_Detail__c>();
        if (!(lstOEvent[0].creditCardToken__c == null || String.isBlank(lstOEvent[0].creditCardToken__c) || lstOEvent[0].creditCardToken__c == 'null'))
        	lstFD = [SELECT Id, Token__c, Expiry_Date__c, Account__c FROM Finance_Detail__c WHERE Token__c =:lstOEvent[0].creditCardToken__c AND Account__c IN: mapAccount.keySet()];
        System.debug('=====lstFD======'+lstFD);
        List<User> lstUser = [SELECT Id, Name FROM User WHERE FirstName = 'Salesforce' AND LastName = 'Admin' AND Profile.Name LIKE 'System Administrator' LIMIT 1];
        Order objOrder = PEBatchOrderEvent.createOrder(lstOEvent[0], mapAccount, mapAddress, lstOrderItem, mapProductToPBE, mapSKUProduct, lstFD.isEmpty() ? new Finance_Detail__c() : lstFD[0], lstUser.isEmpty() ? null: lstUser[0].Id, priceBookId, lstErrorLog);
        if(objOrder != null && objOrder.Id != null){
            objOrder = [SELECT Id, AccountId, Account.RecordType.Name, Pricebook2.Name, Pricebook2Id, PriceBook2.IsSubscription__c, BillingCountry, CurrencyIsoCode, Status, Payment_Terms__c, Signature_Required__c, Total_Gross_Price__c FROM Order WHERE Id =: objOrder.Id];
            if(objOrder.Pricebook2.Name.containsIgnoreCase('SUBSCRIPTION') && lstOEvent[0].eventSource__c != null && lstOEvent[0].eventSource__c.containsIgnoreCase('ECOM')  && objOrder.Pricebook2.IsSubscription__c == true )createSSIPRules(objOrder, lstOEvent[0].paymentTerm__c, lstErrorLog);
            if (!objOrder.Pricebook2.Name.containsIgnoreCase('SUBSCRIPTION') && !subPB) {
                if((lstOEvent[0].paymentTerm__c == 'net0' || lstOEvent[0].paymentTerm__c == 'Credit Card') && objOrder.Total_Gross_Price__c != 0.00 ){
                    system.debug('No of Queued Jobs: ' + Limits.getQueueableJobs());
                	if (Limits.getQueueableJobs() < 1) System.enqueueJob(new SettlePaymentQueueable(objOrder.Id, objOrder.Account.RecordType.Name.substring(0,2)));
                }else if(objOrder.Payment_Terms__c == 'net-1' || (objOrder.Payment_Terms__c == 'net0' && objOrder.Total_Gross_Price__c == 0.00)){
                    objOrder.Status = 'Activated';
                }else{
                    objOrder.Status = 'Shipping Hold';
                }
            } else {
                system.debug('No of Queued Jobs: ' + Limits.getQueueableJobs());
                if (Limits.getQueueableJobs() < 1) System.enqueueJob(new CalculateTaxQueueable(objOrder.Id, lstOEvent[0].paymentTerm__c, objOrder.Account.RecordType.Name.substring(0,2)));
            }
        }
        if(objOrder != null && objOrder.Id != null && (objOrder.Status == 'Activated' || objOrder.Status == 'Shipping Hold')){
            Database.SaveResult[] urList = Database.update(new List<Order>{objOrder}, false);
            if(!urList[0].isSuccess()){
                String error = '';
                for(Database.Error err : urList[0].getErrors()) {
                    error += error == '' ? err.getMessage() : ', ' + err.getMessage();
                }
                lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEBatchOrderEvent', 'Error while updating the status on order', 'order', 'crm', error, objOrder.Id, 'Recoverable Error - Published/Consumed',''));
            }
        }
        System.debug('=====lstOEvent===='+lstErrorLog);// prepaid -> activate.
        insert lstErrorLog;
        
    }
    global void finish(Database.BatchableContext BC){ }
    
    private static void createSSIPRules(Order objOrder, String paymentTerm, List<Platform_Event_Error_Log__c> lstErrorLog){
        List<SSIP_Rule__c> lstSSIPRuleToInsert = new List<SSIP_Rule__c>();
        String rt = objOrder.Account.RecordType.Name.substring(0, 2) + '%';
        List<RecordType> lstRecordType = [SELECT Id FROM RecordType WHERE Name LIKE: rt AND SObjectType = 'SSIP_Rule__c' LIMIT 1];
        for(PricebookEntry pbe : [SELECT Id, Product2Id, Product2.Name, First_Repeat_Order_Lead_Days__c, First_Order_Variation_Qty__c, SSIP_Next_Order_In_Days__c, SSIP_Periodic_Order_Quantity__c, Number_of_Repeat_Orders__c, PriceBook2.Subscription_Period_in_Days__c
                                    FROM PriceBookEntry WHERE Pricebook2Id =: objOrder.Pricebook2Id AND SSIP_Periodic_Order_Quantity__c != null AND SSIP_Periodic_Order_Quantity__c > 0]){
            Integer days = Integer.valueOf((pbe.Number_of_Repeat_Orders__c * pbe.SSIP_Next_Order_In_Days__c) - pbe.First_Repeat_Order_Lead_Days__c + 1); 
                                        if (rt.StartsWithIgnoreCase('CA') && pbe.Number_of_Repeat_Orders__c != null && pbe.Number_of_Repeat_Orders__c != 0) {
                                            if (pbe.Product2.Name.StartsWithIgnoreCase('MT')) days = 360;
                                            else days = 348;
                                        }
            lstSSIPRuleToInsert.add(new SSIP_Rule__c(Account__c = objOrder.AccountId, Country__c = objOrder.BillingCountry, CurrencyIsoCode = objOrder.CurrencyIsoCode,
                                                     Payment_Term__c = paymentTerm, Price_Book__c = objOrder.PriceBook2Id, Product__c = pbe.Product2Id, Product_Name__c = pbe.Product2.Name,
                                                     Quantity__c = pbe.SSIP_Periodic_Order_Quantity__c, Rule_Start_Date__c = Date.today(), PriceBookEntryId__c = pbe.Id, 
                                                     RecordTypeId = lstRecordType.isEmpty() ? null : lstRecordType[0].Id, First_Order__c = objOrder.Id, Is_Signature_Required__c = objOrder.Signature_Required__c,
                                                     Frequency_In_Days__c = pbe.SSIP_Next_Order_In_Days__c, First_Repeat_Order_Lead_Days__c = pbe.First_Repeat_Order_Lead_Days__c,
                                                     Rule_End_Date__c = /*(rt.StartsWithIgnoreCase('CA') && pbe.Number_of_Repeat_Orders__c != null && pbe.Number_of_Repeat_Orders__c != 0 ) ? Date.today().addDays(360) : */
                                                     	(pbe.Number_of_Repeat_Orders__c != null && pbe.Number_of_Repeat_Orders__c != 0) ? Date.today().addDays(days) : null,
                                                     Renewal_Date__c = (pbe.Pricebook2.Subscription_Period_in_Days__c != null && pbe.Pricebook2.Subscription_Period_in_Days__c > 1) ? Date.today().addDays((INTEGER)pbe.Pricebook2.Subscription_Period_in_Days__c) : 
                                                     (pbe.Pricebook2.Subscription_Period_in_Days__c != null && pbe.Pricebook2.Subscription_Period_in_Days__c < 0) ? null : 
                                                     /* (rt.StartsWithIgnoreCase('CA') && pbe.Pricebook2.Subscription_Period_in_Days__c != null && pbe.Pricebook2.Subscription_Period_in_Days__c == 1) ? Date.today().addYears(1) : */ Date.today().addDays(360) ));
            
        }
        if (lstSSIPRuleToInsert.size() > 0) {
            Database.SaveResult[]  srList = Database.insert(lstSSIPRuleToInsert, false);
            if(!srList[0].isSuccess()){
                String error = '';
                for(Database.Error err : srList[0].getErrors()) {
                    System.debug('=======error====='+err.getFields());
                    error += error == '' ? 'Order Error  :' + err.getMessage() : ', ' + err.getMessage();
                }
                lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEBatchOrderEvent.createSSIPRules', 'Error while creating SSIP Rules', 'order', objOrder.Id, error, objOrder.Id, 'Recoverable Error - Published/Consumed', ''));
                System.debug('=====error=Order====='+error);
            } else {
                update new Account(id=objOrder.AccountId, Number_of_Active_SSIP_Rules__c=lstSSIPRuleToInsert.size());
                PEClsHandleAccountEventsStatic.accountPublish=true;
                PEClsHandleAccountEvents.publishAccountEvents(new Set<Id> {objOrder.AccountId}, 'update');
            }
        }
    }
    
     public class CalculateTaxQueueable implements Queueable, Database.AllowsCallouts{
        public String orderId;
        public String paymentType;
        public String countryCode;
        public CalculateTaxQueueable(String orderId, String paymentType, String countryCode){
            this.orderId = orderId;
            this.paymentType = paymentType;
            this.countryCode = countryCode;
        }
        public void execute(QueueableContext context) {
            Double OrderAmt = [Select Total_Gross_Price__c from Order where id = :orderId Limit 1].Total_Gross_Price__c;
            try{
                String recordTypeName = countryCode + ' Sales Order Read Only';
                String result = '';	
                if (OrderAmt != 0.00)	
                    result = ClsOUSTaxCalculator.calculateTax(orderId);
                if(result.containsIgnoreCase('VAT/TAX Calculation Failed')) {
					ErrorUtility.LogError('Consume', 'PEBatchOrderEvent.CalculateTaxQueueable', 'Error in Calculating Tax', 'order', 'crm', result, orderId , 'Informational');
                    return;
                } else {
                 	if (paymentType == 'net0' && !Test.isRunningTest())
                    	System.enqueueJob(new SettlePaymentQueueable(orderId, countryCode));
                	else {
                        if(Schema.SObjectType.Order.getRecordTypeInfosByName().containsKey(recordTypeName)){
                            update new Order(Id = orderId, Status = 'Shipping Hold', recordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId());
                        }
                    }
                }
            }catch(Exception ex){
               ErrorUtility.LogError('Consume', 'PEBatchOrderEvent.CalculateTaxQueueable', 'Exception Error in Calculating Tax', 'order', 'crm', ex.getMessage(), orderId , 'Informational');
            }
        }
    }
    
    public class SettlePaymentQueueable implements Queueable, Database.AllowsCallouts{
        public String orderId;
        public String countryCode;
        
        public SettlePaymentQueueable(String orderId, String countryCode){
            this.orderId = orderId;
            this.countryCode = countryCode;
        }
        public void execute(QueueableContext context) {
            String recordTypeName = countryCode + ' Sales Order Read Only';
            Map<Id, ClsCCAuthAndSettlementResponse> mapResponse = ClsCCAuthAndSettlementService.settlePayment(orderId);
            System.debug('=======mapResponse1======'+mapResponse);
            if(mapResponse.containsKey(orderId) && mapResponse.get(orderId).Status == ClsCCAuthAndSettlementResponse.enumStatus.SUCCESS){
                System.debug('=======mapResponse2======'+mapResponse);
                if(Schema.SObjectType.Order.getRecordTypeInfosByName().containsKey(recordTypeName)){
                    System.debug('=======mapResponse3======'+mapResponse);
                    try{
                        System.debug('=======mapResponse4======'+mapResponse);
                        ClsOrderHandlerStatic.executeOrderEventTriggerv11 = true;
                        update new Order(Id = orderId, Status = 'Activated', recordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId());
                    }catch(Exception ex){
                        ErrorUtility.LogError('Consume', 'PEBatchOrderEvent.SettlePaymentQueueable', 'Exception Error while Settling CC Payment', 'order', 'crm', ex.getMessage(), orderId , 'Informational');
                    }
                }
            }
        }
    }
    
    
    private static Order createOrder(CRM_Order_Event_V1__e oEvent, Map<String, Account> mapAccount, Map<String, Address__c> mapAddress, List<OrderLineItem> lstOrderLineItem, Map<String, String> mapProductToPBE, Map<String, String> mapSKUProduct, Finance_Detail__c fd, String userId, String priceBookId, List<Platform_Event_Error_Log__c> lstErrorLog){
        PEClsHandleAccountEventsStatic.accountPublish = false;
        try{
            List<OrderItem> lstOrderItem = new List<OrderItem>();
            Map<String, Address__c> mapAddressToInsert = new Map<String, Address__c>();
            Map<String, Address__c> mapAddressToUpsert = new Map<String, Address__c>();
            Map<String, Address__c> mapAddressToLocked = new Map<String, Address__c>();
            String recordTypeName = oEvent.orderType__c.containsIgnoreCase('CA Tech Replacement') ? 'ca tech support order' : 
            		oEvent.orderType__c.containsIgnoreCase('TECH REPLACE') ? mapAccount.get(oEvent.accountID__c).RecordType.DeveloperName.substring(0,2).toLowerCase() + ' tech support order' : 
            		mapAccount.get(oEvent.accountID__c).RecordType.DeveloperName.substring(0,2).toLowerCase() + ' sales order';
            String errorMsg  = priceBookId == null ? 'PriceBook is not found in Salesforce with Name: ' +oEvent.pricebookName__c : '';
                   errorMsg += String.isEmpty(errorMsg) && !mapRecordTypeNameToID.containsKey(recordTypeName) ? 'RecordType is not found in Salesforce with Name: ' + recordTypeName : String.isNotBlank(errorMsg) && !mapRecordTypeNameToID.containsKey(recordTypeName) ? ', RecordType is not found in Salesforce with Name: ' + recordTypeName : '';
                   //errorMsg += String.isEmpty(errorMsg) && oEvent.billingAddressId__c != null && oEvent.billingAddressId__c != 'null' && !mapAddress.containsKey(oEvent.billingAddressId__c) ? 'Billing Address not found in salesforce with ID ' + oEvent.billingAddressId__c : oEvent.billingAddressId__c != null && oEvent.billingAddressId__c != 'null' && !mapAddress.containsKey(oEvent.billingAddressId__c)? ', Biiling Address not found in salesforce with ID ' +oEvent.billingAddressId__c : '';
                   //errorMsg += String.isEmpty(errorMsg) && oEvent.shippingAddressId__c != null && oEvent.shippingAddressId__c != 'null' && !mapAddress.containsKey(oEvent.shippingAddressId__c) ?   'Shipping Address not found in Salesforce with ID : ' + oEvent.shippingAddressId__c : oEvent.shippingAddressId__c != null && oEvent.shippingAddressId__c != 'null' && !mapAddress.containsKey(oEvent.shippingAddressId__c) ? ', Shipping Address not found in Salesforce with ID: ' + oEvent.shippingAddressId__c : '';
                   errorMsg += String.isEmpty(errorMsg) && userId == null ? 'Could not get Salesforce Admin Id. Can\'t processing Create Operations' : userId == null ? 'Could not get Salesforce Admin Id. Can\'t processing Create Operations' : '';
            if(String.isNotBlank(errorMsg) || String.isNotEmpty(errorMsg)){
                ErrorUtility.LogError('Consume', 'PEBatchOrderEvent.createOrder', 'Incorrect Data from source', 'order', oEvent.eventSource__c, errorMsg, oEvent.eventSourceID__c, 'Fatal Error - Bailing out');
                return null;
            }
            for(OrderLineItem oli : lstOrderLineItem){
                if(mapProductToPBE.containsKey(oli.sku)){
                    lstOrderItem.add(PEBatchOrderEvent.orderItemMapping(mapProductToPBE.get(oli.sku), oli, null, new OrderItem(), mapSKUProduct, oEvent.eventSource__c));
                }else{ 
                    lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEBatchOrderEvent.createOrder', 'Price Book Issue', 'order', oEvent.eventSource__c, 'Price Book Entry not found to create the Order Item for product : ' + oli.sku,  oEvent.eventSourceID__c, 'Fatal Error - Bailing out', String.valueOf(oEvent)));
                }
            }
            if(lstOrderItem.size() != lstOrderLineItem.size()) return null; 
            String addRecordTypeName =  mapAccount.get(oEvent.accountID__c).RecordType.DeveloperName.substring(0,2) == 'IE' || mapAccount.get(oEvent.accountID__c).RecordType.DeveloperName.substring(0,2) == 'GB' 
                                        ? 'uk_address' : mapAccount.get(oEvent.accountID__c).RecordType.DeveloperName.substring(0,2).toLowerCase() +'_address'.toLowerCase();
            String billingAddressID = null;
            String shippingAddressID = null;
            // ***** OMS Orders are not being handled *****
            if(oEvent.eventSource__c.containsIgnoreCase('OMS')){
                Boolean isBASalesforceId = oEvent.billingAddressId__c != null && Pattern.compile( '[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}' ).matcher(oEvent.billingAddressId__c).matches();
                Boolean isSASalesforceId = oEvent.shippingAddressId__c != null && Pattern.compile( '[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}' ).matcher(oEvent.shippingAddressId__c).matches();
                
                billingAddressID = (isBASalesforceId && mapAddress.containsKey(oEvent.billingAddressId__c)) ? mapAddress.get(oEvent.billingAddressId__c).Id : (oEvent.billingAddressId__c != null && mapAddress.containsKey(oEvent.billingAddressAccountID__c+'_'+oEvent.billingAddressId__c)) ?  mapAddress.get(oEvent.billingAddressAccountID__c+'_'+oEvent.billingAddressId__c).Id : null;
                shippingAddressID = (isSASalesforceId && mapAddress.containsKey(oEvent.shippingAddressId__c)) ? mapAddress.get(oEvent.shippingAddressId__c).Id : (oEvent.shippingAddressId__c != null && mapAddress.containsKey(oEvent.shippingAddressAccountID__c+'_'+oEvent.shippingAddressId__c)) ?  mapAddress.get(oEvent.shippingAddressAccountID__c+'_'+oEvent.shippingAddressId__c).Id : null;
                
                if(billingAddressID == null){
                    Address__c address = addressMapping(oEvent, null, mapAddressRecordTypeNameToID.get(addRecordTypeName), 'BillTo');
                    address.Oracle_Cust_Site_Id__c = oEvent.billingAddressId__c == null || mapAddress.containsKey(oEvent.billingAddressId__c) || oEvent.billingAddressId__c == 'null' ? null :  oEvent.billingAddressId__c;
                    mapAddressToInsert.put('BillTo', address);
                }
                
                if(shippingAddressID == null){
                    Address__c address = addressMapping(oEvent, null, mapAddressRecordTypeNameToID.get(addRecordTypeName), 'ShipTo');
                    address.Oracle_Cust_Site_Id__c = oEvent.shippingAddressId__c == null || mapAddress.containsKey(oEvent.shippingAddressId__c) ||  oEvent.shippingAddressId__c == 'null' ? null :  oEvent.shippingAddressId__c;
                    mapAddressToInsert.put('ShipTo', address);
                }
                
                if(mapAddress.containsKey(oEvent.billingAddressId__c) && !mapAddress.get(oEvent.billingAddressId__c).isLocked__c){
                    mapAddressToLocked.put(mapAddress.get(oEvent.billingAddressId__c).Id, new Address__c(Id = mapAddress.get(oEvent.billingAddressId__c).Id, isLocked__c = true));
                }
                if(mapAddress.containsKey(oEvent.shippingAddressId__c) && !mapAddress.get(oEvent.shippingAddressId__c).isLocked__c){
                    mapAddressToLocked.put(mapAddress.get(oEvent.shippingAddressId__c).Id, new Address__c(Id = mapAddress.get(oEvent.shippingAddressId__c).Id, isLocked__c = true));
                }
            }else{
       		// it was commentd out till here.  
                if(mapAddress.containsKey(oEvent.billingAddressId__c) && !mapAddress.get(oEvent.billingAddressId__c).isLocked__c && isBillingAddressChanged(mapAddress.get(oEvent.billingAddressId__c), oEvent)){
                    mapAddressToUpsert.put('BillTo', addressMapping(oEvent, mapAddress.get(oEvent.billingAddressId__c).Id, mapAddressRecordTypeNameToID.get(addRecordTypeName), 'BillTo'));
                }else if(!mapAddress.containsKey(oEvent.billingAddressId__c) || (mapAddress.containsKey(oEvent.billingAddressId__c) && mapAddress.get(oEvent.billingAddressId__c).isLocked__c && isBillingAddressChanged(mapAddress.get(oEvent.billingAddressId__c), oEvent))){
                    mapAddressToInsert.put('BillTo', addressMapping(oEvent, null, mapAddressRecordTypeNameToID.get(addRecordTypeName), 'BillTo'));
                }
                //note need to add condition if Address is locked then create new address...
                if(mapAddress.containsKey(oEvent.shippingAddressId__c) && !mapAddress.get(oEvent.shippingAddressId__c).isLocked__c && isBillingAddressChanged(mapAddress.get(oEvent.shippingAddressId__c), oEvent)){
                    mapAddressToUpsert.put('ShipTo', addressMapping(oEvent, mapAddress.get(oEvent.shippingAddressId__c).Id, mapAddressRecordTypeNameToID.get(addRecordTypeName), 'ShipTo'));
                }else if(!mapAddress.containsKey(oEvent.shippingAddressId__c) || (mapAddress.containsKey(oEvent.shippingAddressId__c) && !mapAddress.get(oEvent.shippingAddressId__c).isLocked__c && isBillingAddressChanged(mapAddress.get(oEvent.shippingAddressId__c), oEvent))){
                    mapAddressToInsert.put('ShipTo', addressMapping(oEvent, null, mapAddressRecordTypeNameToID.get(addRecordTypeName), 'ShipTo'));
                }
                billingAddressID = mapAddress.containsKey(oEvent.billingAddressId__c) && !isBillingAddressChanged(mapAddress.get(oEvent.billingAddressId__c), oEvent) ? mapAddress.get(oEvent.billingAddressId__c).Id : null;
                shippingAddressID= mapAddress.containsKey(oEvent.shippingAddressId__c) && !isShippingAddressChanged(mapAddress.get(oEvent.shippingAddressId__c), oEvent) ? mapAddress.get(oEvent.shippingAddressId__c).Id: null;
            }
            fd = fd.Id != null && oEvent.creditCardExpirationDate__c != null && oEvent.creditCardExpirationDate__c != 'null' && fd.Expiry_Date__c != oEvent.creditCardExpirationDate__c ? new Finance_Detail__c(Id = fd.Id, Expiry_Date__c = oEvent.creditCardExpirationDate__c) : 
                 fd.Id == null && oEvent.creditCardToken__c != null && oEvent.creditCardToken__c != 'null' ? PEBatchOrderEvent.mappingFinancialDetail(oEvent, new Order()) : fd;
            System.debug('====fd====='+fd);
            //(CRM_Order_Event_V1__e oEvent, String recordTypeID, String priceBookId, String shippingAddressID, String billingAddressID, String fdId, Order newOrder, String ownerId, String orderType)
            Order newOrder = PEBatchOrderEvent.orderMapping(oEvent, mapRecordTypeNameToID.get(recordTypeName), priceBookId, shippingAddressID, billingAddressID, fd != null ? fd.Id : null, new Order(), userId, oEvent.orderType__c);
            Map<String, String> mapDuplicateAddressIds = PEBatchOrderEvent.findDuplicateAddress(mapAddressToInsert);
            Map<String, Address__c> mapDuplicateAddress = new Map<String, Address__c>([SELECT Id, isLocked__c FROM Address__c WHERE Id IN: mapDuplicateAddressIds.values() AND InActive__c = false]);
            for(String key : mapAddressToInsert.keySet()){
                if(mapDuplicateAddressIds.containsKey(key)) {
                    if(oEvent != null && oEvent.eventSource__c.containsIgnoreCase('OMS')){
                        if(key == 'BillTo' && !mapDuplicateAddress.get(mapDuplicateAddressIds.get(key)).isLocked__c){
                            newOrder.Customer_Bill_To_Address__c = mapDuplicateAddressIds.get(key); 
                            mapAddressToLocked.put(mapDuplicateAddressIds.get(key), new Address__c(Id = mapDuplicateAddressIds.get(key), isLocked__c = true, Oracle_Cust_Site_Id__c = oEvent.billingAddressId__c));
                        }else if(key == 'ShipTo' && !mapDuplicateAddress.get(mapDuplicateAddressIds.get(key)).isLocked__c){
                            newOrder.Customer_Ship_To_Address__c = mapDuplicateAddressIds.get(key);
                            mapAddressToLocked.put(mapDuplicateAddressIds.get(key), new Address__c(Id = mapDuplicateAddressIds.get(key), isLocked__c = true, Oracle_Cust_Site_Id__c = oEvent.shippingAddressId__c));
                        }else{
                            mapAddressToUpsert.put(key, mapAddressToInsert.get(key));
                        }
                        
                    }else{
                        if(key == 'BillTo'){
                            newOrder.Customer_Bill_To_Address__c = mapDuplicateAddressIds.get(key); 
                        }else if(key == 'ShipTo'){
                            newOrder.Customer_Ship_To_Address__c = mapDuplicateAddressIds.get(key);
                        }
                        if(!mapDuplicateAddress.get(mapDuplicateAddressIds.get(key)).isLocked__c){
                            mapAddressToLocked.put(mapDuplicateAddressIds.get(key), new Address__c(Id = mapDuplicateAddressIds.get(key), isLocked__c = true));
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
                if(mapAddressToUpsert.get(key).Id != null ) setAddressId.add(mapAddressToUpsert.get(key).Id);
            }
            
            Database.UpsertResult[] urList = Database.upsert(lstAddress, false);
            boolean failed = false;
            String addError = '';
            for(Integer i = 0; i < urList.size(); i++){
                String key = lstAddressKey[i];
                if(urList[i].isSuccess()){
                    if (urList[i].isCreated() == false) mapAddressToLocked.put(urList[i].getId(), new Address__c(Id = urList[i].getId(), isLocked__c = true));
                    if(key == 'BillTo'){
                        newOrder.Customer_Bill_To_Address__c = urList[i].getId(); 
                    }else if(key == 'ShipTo'){
                        newOrder.Customer_Ship_To_Address__c = urList[i].getId();
                    }
                }else {
                    for(Database.Error err : urList[i].getErrors()) {
                        addError += addError == '' ? 'Address Error with ' + key + ': ' +err.getMessage() : ', ' + err.getMessage();
                        failed = true;
                    }
                }
            }
            if (failed) {
                addError += '. Order can\'t be created.';
                lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEBatchOrderEvent.createOrder',  'Incorrect Address Issue',  'order', oEvent.eventSource__c, addError, oEvent.eventSourceID__c, 'Recoverable Error - Published/Consumed', ''));
                return null;
            }
            //system.debug('Financial Detail\'s Account ID: ' + fd.Account__c);
            if(fd.Account__c != null){
                fd.CC_Address__c = newOrder.Customer_Bill_To_Address__c;
                urList = Database.upsert(new List<Finance_Detail__c>{fd}, false);
                if(urList[0].isSuccess()){
                    System.debug('===fd@@@==='+urList[0].getId());
                    newOrder.Finance_Detail__c = urList[0].getId();
                }else{
                    String error = '';
                    for(Database.Error err : urList[0].getErrors()) {
                        error += error == '' ? 'Address Error line no 256: ' +err.getMessage() : ', ' + err.getMessage();
                    }
                    lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEBatchOrderEvent.createOrder',  'Issue with CC Address' , 'order', oEvent.eventSource__c, error, oEvent.eventSourceID__c, 'Recoverable Error - Published/Consumed', ''));
                }
            }
            List<Order> lstOrder = new List<Order>{newOrder};
            Database.SaveResult[]  srList = Database.insert(lstOrder, false);
            
            if(srList[0].isSuccess()){
                newOrder = lstOrder[0];
                for(OrderItem ordItm : lstOrderItem){
                    ordItm.OrderId = newOrder.Id;
                }
            }else{
                String error = '';
                for(Database.Error err : srList[0].getErrors()) {
                    error += error == '' ? 'Order Error  :' + err.getMessage() : ', ' + err.getMessage();
                }
                lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEBatchOrderEvent.createOrder',  'Error while Saving Order.',  'order', oEvent.eventSource__c, error, oEvent.eventSourceID__c, 'Recoverable Error - Published/Consumed', ''));
                return null;
            }
            
            srList = Database.insert(lstOrderItem, false);
            Boolean isError = false;
            for(Integer i = 0; i < srList.size(); i++){    
                if(srList[i].isSuccess()){
                    newOrder.Status = oEvent != null && oEvent.stage__c == 'pending' && oEvent.operation__c == 'update' && oEvent.eventSource__c.containsIgnoreCase('OMS') && oEvent.status__c != null ? oEvent.status__c :
                                      oEvent != null && oEvent.stage__c == 'pending' && oEvent.operation__c == 'update' && oEvent.eventSource__c.containsIgnoreCase('OMS') && oEvent.status__c == null ? newOrder.Status : 
                                      oEvent != null && oEvent.stage__c == 'pending' && oEvent.operation__c == 'create' && oEvent.eventSource__c != null && oEvent.eventSource__c.containsIgnoreCase('ECOM') ? 'Activated' : 'Booked';
                }else {
                    isError = true;
                    String error = '';
                    for(Database.Error err : srList[i].getErrors()) {
                        error += error == '' ? 'OrderItem Error  :' + err.getMessage() : ', ' + err.getMessage();
                    }
                    lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEBatchOrderEvent.createOrder',  'Error while saving Order Line Items' , 'order', oEvent.eventSource__c, error, oEvent.eventSourceID__c, 'Recoverable Error - Published/Consumed', ''));
                    System.debug('=====error=OrderItem====='+error);
                }
            }
            if(isError) {  delete newOrder; return null; }
             if (mapAddressToLocked.size() > 0) update mapAddressToLocked.values();
            return newOrder;
        }catch(Exception ex){
            lstErrorLog.add(ErrorUtility.prepareErroLog('Consume', 'PEBatchOrderEvent.createOrder',  'Exception Error while Saving Order', 'order', oEvent.eventSource__c, ex.getMessage()+' at line no: '+ ex.getLineNumber(), oEvent.eventSourceID__c, 'Recoverable Error - Published/Consumed', ''));
        }
        return null;
    }
    
    @TestVisible private static Order orderMapping(CRM_Order_Event_V1__e oEvent, String recordTypeID, String priceBookId, String shippingAddressID, String billingAddressID, String fdId, Order newOrder, String ownerId, String orderType){
        Order orderIn = new Order(Id = newOrder.Id, RecordTypeId = recordTypeID != null ? recordTypeID : newOrder.RecordTypeId, AccountId = oEvent.accountId__c != null ? oEvent.accountId__c : newOrder.AccountId, 
                         Invoice_Date__c = oEvent.invoiceDate__c != 'null' && !String.isBlank(oEvent.invoiceDate__c) ? Date.valueOf(oEvent.invoiceDate__c) : newOrder.Invoice_Date__c, PriceBook2Id = priceBookId, 
                         Ecom_Confirmation_Number__c = (oEvent.eventSource__c == 'ecom' && oEvent.eventSourceID__c != null) ? oEvent.eventSourceID__c : newOrder.Ecom_Confirmation_Number__c,
                         Invoice_Number__c = oEvent.invoiceNumber__c != 'null' ? oEvent.invoiceNumber__c : newOrder.Invoice_Number__c, Type = orderType != 'null' ? orderType : newOrder.Type, 
                         Status = oEvent.status__c != null && newOrder.Id != null ? oEvent.status__c  : 'Draft', System_Of_Origin__c = oEvent.systemOfOrigin__c != null ? oEvent.systemOfOrigin__c : newOrder.System_Of_Origin__c,
                         System_Of_Origin_ID__c = oEvent.systemOfOriginID__c != null ? oEvent.systemOfOriginID__c : newOrder.System_Of_Origin_ID__c, 
                         /* Warehouse__c = oEvent.warehouse__c != null && oEvent.warehouse__c != 'null'? oEvent.warehouse__c : newOrder.Warehouse__c,  ----- To let the warehouse be defaulted to the record type*/
                         Credit_Card_Authorization_Code__c = oEvent.creditCardAuthorizationCode__c != 'null' ? oEvent.creditCardAuthorizationCode__c : newOrder.Credit_Card_Authorization_Code__c,
                         Payment_Id__c = oEvent.creditCardTransactionID__c != 'null' ? oEvent.creditCardTransactionID__c : newOrder.Payment_Id__c, CC_Auth_Amount__c = oEvent.totalAmount__c,
                         Customer_Bill_To_Address__c = billingAddressID != 'null' ? billingAddressID : newOrder.Customer_Bill_To_Address__c, 
                         Customer_Ship_To_Address__c = shippingAddressID != 'null' ? shippingAddressID : newOrder.Customer_Ship_To_Address__c, 
                         // Finance_Detail__c = fdId != 'null' ? fdId : newOrder.Finance_Detail__c, EffectiveDate = PEBatchOrderEvent.getCurrentDate(mapTimeZone.get(ordertype.left(2)) /*'America/Los_Angeles' */), OwnerId = ownerId == null ? newOrder.OwnerId : ownerId,  // Commented this out and added the following line with a slight change VA 8/24/2020
                         Finance_Detail__c = fdId != null ? fdId : newOrder.Finance_Detail__c, EffectiveDate = PEBatchOrderEvent.getCurrentDate(mapTimeZone.get(ordertype.left(2)) /*'America/Los_Angeles' */), OwnerId = ownerId == null ? newOrder.OwnerId : ownerId,
                         Signature_Required__c = oEvent.isSignatureRequired__c, Shipping_Method__c = oEvent.shippingMethod__c, Price_Book__c = priceBookId,/*CurrencyIsoCode = 'CAD',*/
                         SOS_Unique_ID__c = oEvent.systemOfOrigin__c+oEvent.systemOfOriginID__c, Ecom_Parent_Order__c = oEvent.parentSystemOfOriginID__c,
                         OMS_Order_Number__c = oEvent != null && (oEvent.stage__c == 'pending'|| oEvent.stage__c == 'confirmed') && oEvent.operation__c == 'create' && oEvent.eventSource__c != null && oEvent.eventSource__c.containsIgnoreCase('OMS') && oEvent.eventSourceId__c != null ? oEvent.eventSourceId__c : null,
                         Payment_Terms__c = oEvent.paymentTerm__c != null && oEvent.paymentTerm__c != 'null' ? oEvent.paymentTerm__c : oEvent.orderType__c.containsIgnoreCase('CA Tech Replacement') ? 'net-1' : oEvent.eventSource__c == 'ecom' && oEvent.totalAmount__c == 0.0 ? 'net0' : null, //Made a change in this line too. VA 8/24/2020
                         Tax_Exempt__c = oEvent.orderType__c.StartsWithIgnoreCase('GB') ? oEvent.billingTaxExempt__c : oEvent.shippingTaxExempt__c, Shipping_Instructions__c = oEvent.shippingNotes__c);
        if (oEvent.warehouse__c != null && oEvent.warehouse__c != 'null') orderIn.Warehouse__c = oEvent.warehouse__c;
        List<TaxDetails> taxDetailslist = new List<TaxDetails>();
		if (String.isNotBlank(oEvent.tax__c) && !OEvent.tax__c.equalsIgnoreCase('null') ) taxDetailslist = (List<TaxDetails>)JSON.deserialize(OEvent.tax__c, List<TaxDetails>.class);
        for(TaxDetails td : taxDetailslist) {
            if (td.type.equalsIgnoreCase('GST')) {orderIn.CA_GST_Tax_Rate__c = td.rate; orderIn.CA_GST_Tax_Amount__c = td.amount; }
            if (td.type.equalsIgnoreCase('HST')) {orderIn.CA_HST_Tax_Rate__c = td.rate; orderIn.CA_HST_Tax_Amount__c = td.amount; }
            if (td.type.equalsIgnoreCase('PST')) {orderIn.CA_PST_Tax_Rate__c = td.rate; orderIn.CA_PST_Tax_Amount__c = td.amount; }
        }
        return orderIn;
    }
    private static Date getCurrentDate(String timeZone){
        return Date.valueOf(System.now().format('yyyy-MM-dd', timeZone));
    }
    @TestVisible private static Boolean isBillingAddressChanged(Address__c address, CRM_Order_Event_V1__e oEvent){
        return (address.Business_Name__c != oEvent.billingAddressBusinessName__c || address.Address_Line_1__c != oEvent.billingAddress1__c || address.Address_Line_2__c != oEvent.billingAddress2__c ||
                address.Address_Line_3__c != oEvent.billingAddress3__c || address.City__c != oEvent.billingAddressCity__c || address.Country__c != oEvent.billingAddressCountry__c ||
                address.First_Name__c != oEvent.billingAddressFirstName__c || address.Last_Name__c != oEvent.billingAddressLastName__c || address.Postal_Code__c != oEvent.billingAddressPostalCode__c ||
                address.Primary_Phone__c != oEvent.billingAddressPrimaryPhone__c || address.State__c != oEvent.billingAddressStateProvince__c);
    }
    
    @TestVisible private static Boolean isShippingAddressChanged(Address__c address, CRM_Order_Event_V1__e oEvent){
        return (address.Business_Name__c != oEvent.shippingAddressBusinessName__c || address.Address_Line_1__c != oEvent.shippingAddress1__c || address.Address_Line_2__c != oEvent.shippingAddress2__c ||
                address.Address_Line_3__c != oEvent.shippingAddress3__c || address.City__c != oEvent.shippingAddressCity__c || address.Country__c != oEvent.shippingAddressCountry__c ||
                address.First_Name__c != oEvent.shippingAddressFirstName__c || address.Last_Name__c != oEvent.shippingAddressLastName__c || address.Postal_Code__c != oEvent.shippingAddressPostalCode__c ||
                address.Primary_Phone__c != oEvent.shippingAddressPrimaryPhone__c || address.State__c != oEvent.shippingAddressStateProvince__c);
    }
    @TestVisible private static Address__c addressMapping(CRM_Order_Event_V1__e oEvent, String recordId, String recordTypeID, String addressType){
        String billingCountry = oEvent.billingAddressCountry__c != 'null' && oEvent.billingAddressCountry__c != null ? oEvent.billingAddressCountry__c : oEvent.billingAddressCountryCode__c != null && mapCountry.containsKey(oEvent.billingAddressCountryCode__c) ? mapCountry.get(oEvent.billingAddressCountryCode__c) : null;
        String shippingCounty = oEvent.shippingAddressCountry__c != 'null' && oEvent.shippingAddressCountry__c != null ? oEvent.shippingAddressCountry__c : oEvent.shippingAddressCountryCode__c != null && mapCountry.containsKey(oEvent.shippingAddressCountryCode__c) ? mapCountry.get(oEvent.shippingAddressCountryCode__c) : null;
        String billingState = oEvent.billingAddressStateProvince__c != null && oEvent.billingAddressStateProvince__c  != 'null' && oEvent.billingAddressStateProvince__c.length() == 2 &&  mapState.containsKey(oEvent.billingAddressStateProvince__c) ? mapState.get(oEvent.billingAddressStateProvince__c) : oEvent.billingAddressStateProvince__c != 'null' && oEvent.billingAddressStateProvince__c != null && oEvent.billingAddressStateProvince__c.length() > 2 ? oEvent.billingAddressStateProvince__c : null; 
        String shippingState = oEvent.shippingAddressStateProvince__c != null && oEvent.shippingAddressStateProvince__c  != 'null' && oEvent.shippingAddressStateProvince__c.length() == 2 &&  mapState.containsKey(oEvent.shippingAddressStateProvince__c) ? mapState.get(oEvent.shippingAddressStateProvince__c) : oEvent.shippingAddressStateProvince__c != 'null' && oEvent.shippingAddressStateProvince__c != null && oEvent.shippingAddressStateProvince__c.length() > 2 ? oEvent.shippingAddressStateProvince__c : null; 
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
                                            Primary_Flag__c = true/*, System_Of_Origin__c = oEvent.systemOfOrigin__c, System_Of_Origin_Id__c = oEvent.systemOfOriginID__c */);
        if(recordId == null) {
            address.Account__c = addressType == 'BillTo' && oEvent.billingAddressAccountID__c != null && oEvent.billingAddressAccountID__c != 'null' ? oEvent.billingAddressAccountID__c : addressType == 'ShipTo' && oEvent.shippingAddressAccountID__c != null && oEvent.shippingAddressAccountID__c != 'null' ? oEvent.shippingAddressAccountID__c : oEvent.accountId__c;
            //address.SOS_Unique_ID__c = addressType +'_'+oEvent.systemOfOrigin__c+'_'+oEvent.systemOfOriginID__c;
            address.isLocked__c = true;	
            address.System_Of_Origin__c = oEvent.systemOfOrigin__c;
            address.System_Of_Origin_Id__c = oEvent.systemOfOriginID__c;
        }
        if (oEvent.pricebookName__c.containsIgnoreCase('Cash')) {	//Order is using Cash List Price
            String addType = addressType == 'BillTo' ?  'Bill To' : 'Ship To';
            if(recordId == null) {		// New address
                List<Address__c> existingPrimAddress = [Select id from Address__c where Account__c = :oEvent.accountID__c and Type__c = :addType and Primary_Flag__c = true AND InActive__c = false];
                if (existingPrimAddress.size() > 0) address.Primary_Flag__c = false; // There is already a primary address, so don't make this address as Primary
            } else {	// Exsiting Address
                List<Address__c> existingPrimAddress = [Select id from Address__c where Account__c = :oEvent.accountID__c and Type__c = :addType and Primary_Flag__c = true AND id != :recordId AND InActive__c = false];
                if (existingPrimAddress.size() > 0) address.Primary_Flag__c = false;     // Some other Address is primary, so don't make this address as Primary          
            }
        }
        return address;
    }
    @TestVisible private static OrderItem orderItemMapping(String pbeId, OrderLineItem oli, String orderID, OrderItem oItem, Map<String, String> mapSKUProduct, String eventSource){
        //TaxDetails td = (TaxDetails) JSON.deserializeStrict(oli.tax, TaxDetails.class);
        return new OrderItem(PriceBookEntryId = pbeId,  Quantity = oli.quantity != null ? oli.quantity : oItem.Quantity, 
                             skuBundle__c = oli.skuBundle != null && oli.skuBundle != 'null' && mapSKUProduct.containsKey(oli.skuBundle) ? mapSKUProduct.get(oli.skuBundle) : oItem.skuBundle__c,
                             orderID = orderID, UnitPrice = oli.price != null ? oli.price : oItem.UnitPrice, isBundle__c = oli.isBundle != null ?  oli.isBundle : oItem.isBundle__c, 
                             isBundleItem__c = oli.isBundleItem != null ? oli.isBundleItem : oItem.isBundleItem__c, 
							 External_Id__c = (eventSource.containsIgnoreCase('OMS') && oli.itemID != 'null') ? oli.itemID : null,
                             Item_VAT_TAX__c = (oli.tax != null && oli.tax.amount != null) ? oli.tax.amount : 0, 
                             Tax_Rate__c = (oli.tax != null && oli.tax.rate != null) ? oli.tax.rate : 0,
                             Tax_Source__c = (oli.tax != null && oli.tax.source != null) ? oli.tax.source : '');
    }
    
    @TestVisible private static Finance_Detail__c mappingFinancialDetail(CRM_Order_Event_V1__e oEvent, Order newOrder){
        String fType = oEvent.paymentTerm__c == 'net0' || oEvent.paymentTerm__c == 'Credit Card' ? 'Credit Card' : 'Bank';
        String recordTypeId = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByName().get(fType).getRecordTypeId();
        return new Finance_Detail__c(Id = newOrder.Finance_Detail__c, Account__c = oEvent.accountId__c != null ? oEvent.accountId__c : newOrder.AccountId,
                                     Finance_Type__c = fType == 'Credit Card' ? fType : null, recordTypeId = recordTypeId,
                                     Token__c = oEvent.creditCardToken__c != 'null' ? oEvent.creditCardToken__c : newOrder.Finance_Detail__r.Token__c, 
                                     Card_Type__c = oEvent.creditCardType__c != 'null' ? oEvent.creditCardType__c : newOrder.Finance_Detail__r.Card_Type__c, 
                                     Expiry_Date__c = oEvent.creditCardExpirationDate__c != 'null' ? oEvent.creditCardExpirationDate__c : newOrder.Finance_Detail__r.Expiry_Date__c, Primary__c = true,
                                     InActive__c = false, Last_4_Digits__c = oEvent.creditCardToken__c != 'null' ? oEvent.creditCardToken__c.right(4) : newOrder.Finance_Detail__r.Last_4_Digits__c);
    }
    
    @TestVisible private static Map<String, String> findDuplicateAddress(Map<String, Address__c> mapAddress){
        if(mapAddress.isEmpty()) return new Map<String, String>();
        Map<String, String> mapKeyToAddressID = new Map<String, String>();
        Map<String, List<String>> mapAddressUniqueToKeys = new Map<String, List<String>>();
        Set<String> setAccountID = new Set<String>();
        for(String key : mapAddress.keySet()){
            String uniqueKey = PEBatchOrderEvent.createUniqueKey(mapAddress.get(key));
            if(!mapAddressUniqueToKeys.containsKey(uniqueKey))mapAddressUniqueToKeys.put(uniqueKey, new List<String>());
            mapAddressUniqueToKeys.get(uniqueKey).add(key);
            setAccountID.add(mapAddress.get(key).Account__c);
        }
        for(Address__c address : [SELECT Id, Business_Name__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, City__c, Country__c, First_Name__c, Last_Name__c, Postal_Code__c, Primary_Phone__c, State__c, SOS_Unique_ID__c, Type__c, Account__c, Inactive__c, IsLocked__c
                                    FROM Address__c WHERE Account__c IN: setAccountID AND InActive__c = false] ){
            String uniqueKey = PEBatchOrderEvent.createUniqueKey(address);
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
            ErrorUtility.LogError('Consume', 'PEBatchOrderEvent.getPicklistValues', 'Error while getting the Country and State Picklist information',  'order', null, ex.getMessage(), '', 'Informational');
        }
        return mapPicklist;
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
        public TaxDetails tax;
        public String total;
    }
    
    public class TaxDetails{
        public String source;
        public String type; // Added to the structure. It was commented out earlier. Vijay Adusumilli Aug 6, 2020
        public Decimal rate;
        public Decimal amount;
    }
    
    global class ObjectIterator implements Iterator<Sobject>, Iterable<Sobject>{
        global List<Sobject> lstObject; Integer i = 0;
        global ObjectIterator(List<Sobject> lstObject){  this.lstObject = lstObject; i = 0; }  
        global Boolean hasNext(){ return (i >= lstObject.size()) ? false : true; } 
        global Sobject next(){ if(i < lstObject.size()){ i++; return lstObject[i-1]; } return null;}  
        global Iterator<Sobject> iterator() { return this;  } 
    }
}