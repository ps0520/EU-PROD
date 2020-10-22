global class BClsSSIPSchedule implements Database.Batchable<Sobject>, Database.RaisesPlatformEvents{
    private final Date sdt;
    private final Date edt;
    private String country;
    private String accountID;
    private static final Map<String, String> mapTimeZone;
    private static final Map<String, String> mapRecordType;
    static{
        mapTimeZone = new Map<String, String>();
        mapRecordType = new Map<String, String>();
        for(Manage_Time_Zone__mdt timeZone : [SELECT Id, Country_Code__c, Time_Zone__c FROM Manage_Time_Zone__mdt]){
            mapTimeZone.put(timeZone.Country_Code__c, timeZone.Time_Zone__c);
        }
        for(RecordType rt : [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Order']){
            mapRecordType.put(rt.Name, rt.Id);
        }
    }
    
    public BClsSSIPSchedule(){
        this.sdt = Date.today();
        this.edt = Date.today();
    }
    
    public BClsSSIPSchedule(Date sdt, Date edt, String country, String accountID){
        this.sdt = sdt;
        this.edt = edt == null ? sdt : edt;
        this.country = country;
        this.accountID = accountID;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        //((STATUS__c = 'OPEN') OR (STATUS__c = 'IN ERROR' AND TRY_TO_CREATE_OREDER__c = TRUE))
        String query = 'SELECT Account__c, Country__c, IsDeleted, Name, Payment_Term__c,Schedule_Date__c, Shipping_Address__c, Billing_Address__c, Shipping_Method__c, SSIP_Rule__c, Status__c, SSIP_Rule__r.Price_Book__c,';
               query+= 'SSIP_Rule__r.Product__c, SSIP_Rule__r.First_Order__c ,Error_Message__c, Try_to_Create_Order__c,SSIP_Rule__r.Quantity__c, SSIP_Rule__r.Is_Funded__c, Rescheduled_Shipment_Date__c, SSIP_Rule__r.Is_Signature_Required__c ';
               query+= 'FROM SSIP_Schedule__c WHERE ((Schedule_Date__c >=: sdt AND Schedule_Date__c <=: edt) OR (Rescheduled_Shipment_Date__c >=:sdt AND Rescheduled_Shipment_Date__c <=: edt)) ';
               query+= 'AND ((Status__c = \'Open\') OR (Status__c = \'In Error\' AND Try_to_Create_Order__c = true)) AND SSIP_Rule__r.Status__c = \'Active\'';
               query+= String.isNotBlank(country) && String.isNotEmpty(country) ? ' AND Country__c =:country' : '';
               query+= String.isNotBlank(accountID) && String.isNotEmpty(accountID) ? ' AND Account__c =:accountID' : '';
        
        System.debug('**query--'+query);
        System.debug('**AccountID--'+accountID);
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<SSIP_Schedule__c> scope){
        System.debug('***Batch Execution Starts with Size--'+scope.size());
        Set<Id> setAccountId = new Set<Id>();
        for(SSIP_Schedule__c ssipSchedule : scope) setAccountId.add(ssipSchedule.Account__c);
        Map<String, Order> mapOrder = new Map<String, Order>();
        Map<String, List<OrderItem>> mapOrderItems = new Map<String, List<OrderItem>>();
        Map<String, PricebookEntry> mapPriceBookEntry = new Map<String, PricebookEntry>();
        Map<String, List<SSIP_Schedule__c>> mapSSIPSchedule = new Map<String, List<SSIP_Schedule__c>>();
        Map<String,SSIP_Schedule__c> mapSSIPScheduleUpdate=  new Map<String,SSIP_Schedule__c>();
        Map<Id, Order> ordersToProcessForShipmentMap = new Map<Id, Order>();
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        List<SSIP_Schedule__c> lstSSIPSchedule = new List<SSIP_Schedule__c>();
        Set<Id> setProductId = new Set<Id>();
        Set<Id> setPriceBookId = new Set<Id>();
        Set<Id> setParentOrderId = new Set<Id>();
        Boolean sign_reqd = false;
        SSIP_Schedule__c tempSched = new SSIP_Schedule__c();
        String query = 'SELECT Account__c, Country__c, IsDeleted, Name, Payment_Term__c, Schedule_Date__c, Shipping_Address__c, Billing_Address__c, Shipping_Method__c, SSIP_Rule__c, Status__c, SSIP_Rule__r.Price_Book__c,';
               query+= 'SSIP_Rule__r.Product__c, SSIP_Rule__r.Is_Funded__c, SSIP_Rule__r.First_Order__c , SSIP_Rule__r.Quantity__c, Rescheduled_Shipment_Date__c, SSIP_Rule__r.Effective_Payor__c, SSIP_Rule__r.SSIP_Fund__c, SSIP_Rule__r.Account__r.Fund__c, SSIP_Rule__r.Is_Signature_Required__c,';
               query+= 'SSIP_Rule__r.Effective_PO_Number__c,Error_Message__c, Try_to_Create_Order__c, SSIP_Rule__r.Effective_Tax_Exempt_Flag__c, SSIP_Rule__r.Effective_Tax_Registration_Number__c, SSIP_Rule__r.Shipping_Method__c, SSIP_Rule__r.Payment_Term__c, Account__r.Credit_Hold__c ';
               query+= 'FROM SSIP_Schedule__c WHERE ((Schedule_Date__c >=: sdt AND Schedule_Date__c <=: edt) OR (Rescheduled_Shipment_Date__c >=:sdt AND Rescheduled_Shipment_Date__c <=: edt)) AND ((Status__c = \'Open\') OR (Status__c = \'In Error\' AND Try_to_Create_Order__c = true)) AND SSIP_Rule__r.Status__c = \'Active\' AND Account__c IN: setAccountId';
        system.debug('--Formed SOQL--'+query);
        List<SSIP_Schedule__c> lstNewSSIPSchedule = Database.query(query);
        System.debug('--lstNewSSIPSchedule'+lstNewSSIPSchedule);
        for(SSIP_Schedule__c ssipSchedule : lstNewSSIPSchedule){
            
            if(ssipSchedule.Rescheduled_Shipment_Date__c != null && ssipSchedule.Rescheduled_Shipment_Date__c > edt) continue;
            setProductId.add(ssipSchedule.SSIP_Rule__r.Product__c);
            setPriceBookId.add(ssipSchedule.SSIP_Rule__r.Price_Book__c);
            setAccountId.add(ssipSchedule.Account__c);
            setParentOrderId.add(ssipSchedule.SSIP_Rule__r.First_Order__c);
            sign_reqd = ssipSchedule.SSIP_Rule__r.Is_Signature_Required__c == true ? true : sign_reqd;
        }
        System.debug('**setParentOrderId=='+setParentOrderId);
        Map<Id, Account> mapAccount = new Map<Id, Account>([SELECT Id, Name, RecordType.DeveloperName, Tax_Exempt__c, Tax_Registration_Number__c,
                                                            (SELECT Id, Type__c FROM Addresses__r WHERE Primary_Flag__c = true LIMIT 2),
                                                            (SELECT Id FROM Finance_Details__r WHERE Primary__c = true AND RecordType.Name = 'Credit Card' LIMIT 1) FROM Account WHERE Id IN: setAccountId]);
        
        Map<Id, Order> mapFirstOrder = new Map<Id, Order>([SELECT Id, RecordTypeId, Fund__c, Payor__c, Payment_Terms__c, Shipping_Method__c FROM Order WHERE Id IN: setParentOrderId]);
        System.debug('**mapFirstOrder--'+mapFirstOrder);
        for(PricebookEntry pbe : [SELECT Discount_Amount__c,Pricebook2Id,Product2Id,Split_Price__c,Split_Qty__c,SSIP_Next_Order_In_Days__c,SSIP_Periodic_Order_Quantity__c,UnitPrice FROM PricebookEntry WHERE Pricebook2Id IN: setPriceBookId AND Product2Id IN: setProductId]) mapPriceBookEntry.put(pbe.Pricebook2Id +'_'+ pbe.Product2Id, pbe);  
        for(SSIP_Schedule__c ssipSchedule : lstNewSSIPSchedule){
            System.debug('**CreditHold--'+ssipSchedule.Account__r.Credit_Hold__c);
            if(ssipSchedule.Account__r.Credit_Hold__c) {
                if(mapSSIPScheduleUpdate.containsKey(ssipSchedule.Id)) tempSched = mapSSIPScheduleUpdate.get(ssipSchedule.Id); else tempSched = ssipSchedule;
                tempSched.Error_Message__c = 'Account is on Credit Hold';
                tempSched.Status__c = 'In Error';
                mapSSIPScheduleUpdate.put(ssipSchedule.Id,tempSched);
                //ErrorUtility.LogError('Consume', 'SSIPScheduleBatch', 'Account is on Credit Hold', 'SSIPScheduleBatch', 'crm', 'Account ID: ' + ssipSchedule.Account__c, ssipSchedule.Id, 'Fatal Error - Bailing out');
                continue;
            }
                
            String recordTypeName = mapAccount.get(ssipSchedule.Account__c).RecordType.DeveloperName.substring(0, 2) + ' Sales Order';
            if(ssipSchedule.Rescheduled_Shipment_Date__c != null && ssipSchedule.Rescheduled_Shipment_Date__c > edt) continue;
            String uniqueKey = ssipSchedule.Account__c +'_'+ ssipSchedule.SSIP_Rule__r.Price_Book__c;
            if(!mapSSIPSchedule.containsKey(uniqueKey)) mapSSIPSchedule.put(uniqueKey, new List<SSIP_Schedule__c>());
            mapSSIPSchedule.get(uniqueKey).add(ssipSchedule);
            String shipToAddress = mapAccount.get(ssipSchedule.Account__c).Addresses__r.size() >= 1 && mapAccount.get(ssipSchedule.Account__c).Addresses__r[0].Type__c == 'Ship To' ? mapAccount.get(ssipSchedule.Account__c).Addresses__r[0].Id : 
                                   mapAccount.get(ssipSchedule.Account__c).Addresses__r.size() == 2 && mapAccount.get(ssipSchedule.Account__c).Addresses__r[1].Type__c == 'Ship To' ? mapAccount.get(ssipSchedule.Account__c).Addresses__r[1].Id : null;
                                   
            String billToAddress = mapAccount.get(ssipSchedule.Account__c).Addresses__r.size() >= 1 && mapAccount.get(ssipSchedule.Account__c).Addresses__r[0].Type__c == 'Bill To' ? mapAccount.get(ssipSchedule.Account__c).Addresses__r[0].Id : 
                                   mapAccount.get(ssipSchedule.Account__c).Addresses__r.size() == 2 && mapAccount.get(ssipSchedule.Account__c).Addresses__r[1].Type__c == 'Bill To' ? mapAccount.get(ssipSchedule.Account__c).Addresses__r[1].Id : null;
                                   
            String financialDetail =  mapAccount.get(ssipSchedule.Account__c).Finance_Details__r.isEmpty() ? null :  mapAccount.get(ssipSchedule.Account__c).Finance_Details__r[0].Id;
            System.debug('***financialDetail'+financialDetail);
            if((shipToAddress == null && ssipSchedule.Shipping_Address__c == null) || (billToAddress == null && ssipSchedule.Billing_Address__c == null && ssipSchedule.SSIP_Rule__r.Effective_Payor__c == null ) || (financialDetail == null && ssipSchedule.Payment_Term__c == 'net0') || !mapRecordType.containsKey(recordTypeName)){
                String error = (shipToAddress == null && ssipSchedule.Shipping_Address__c == null) ? 'Shipping Address is missing.' : '';
                       error = error + ( (billToAddress == null && ssipSchedule.Billing_Address__c == null && ssipSchedule.SSIP_Rule__r.Effective_Payor__c == null)  ? ' Billing Address is missing.' : '');
                       error = error + ( (financialDetail == null && ssipSchedule.Payment_Term__c == 'net0') ? 'Financial Detail is missing!' : '' );
                       error = error + (!mapRecordType.containsKey(recordTypeName) ? ' Record Type Name is missing with name : '+recordTypeName : '');
                       error = error + ((String.isNotBlank(error)) ? ' - on SSIP Record with Id ' + ssipSchedule.Id : 'Shipping Address, Billing Address, Finanacial Detail or RecordType is missing on SSIP Record with Id ' + ssipSchedule.Id);
                if(mapSSIPScheduleUpdate.containsKey(ssipSchedule.Id)) tempSched = mapSSIPScheduleUpdate.get(ssipSchedule.Id); else tempSched = ssipSchedule;
                //mapAccount.get(ssipSchedule.Account__c).Finance_Details__r.isEmpty() ? null :  mapAccount.get(ssipSchedule.Account__c).Finance_Details__r[0].Id;
                if((String.isNotBlank(error))){
                  tempSched.Error_Message__c =+ error;
                }
                //tempSched.Error_Message__c +=  error == null ? '' : error;
                tempSched.Status__c = 'In Error'; 
                 mapSSIPScheduleUpdate.put(tempSched.Id,tempSched);
                System.debug('====error====='+error);
                continue;
            }
            mapOrder.put(uniqueKey, orderMapping(mapAccount.get(ssipSchedule.Account__c), mapFirstOrder.get(ssipSchedule.SSIP_Rule__r.First_Order__c), ssipSchedule.SSIP_Rule__r.Price_Book__c, ssipSchedule, mapRecordType.get(recordTypeName), shipToAddress, billToAddress, financialDetail, sign_reqd));
            if(!mapOrderItems.containsKey(uniqueKey)) mapOrderItems.put(uniqueKey, new List<OrderItem>());
            mapOrderItems.get(uniqueKey).add(orderItemMapping(mapPriceBookEntry.get(ssipSchedule.SSIP_Rule__r.Price_Book__c +'_'+ ssipSchedule.SSIP_Rule__r.Product__c), ssipSchedule));
        }
        System.debug('====mapOrder====='+mapOrder);
        List<String> lstUniqueKey = new List<String>();
        List<Order> lstOrder = new List<Order>();
        for(String uniqueKey : mapOrder.keySet()){
            lstUniqueKey.add(uniqueKey); 
            lstOrder.add(mapOrder.get(uniqueKey));
        }
        
        
        Map<Id, Order> mapOrderNew = new Map<Id, Order>();
        Database.SaveResult[] srList = Database.insert(lstOrder, false);
        for(Integer i = 0; i < srList.size(); i++){
            String uniqueKey = lstUniqueKey[i];
            if(srList[i].isSuccess()){
                mapOrderNew.put(lstOrder[i].Id, lstOrder[i]);
                for(OrderItem oi : mapOrderItems.get(uniqueKey)){
                    oi.OrderId = lstOrder[i].Id;
                    lstOrderItem.add(oi);
                }
            }else {
                String error = '';
                for(Database.Error err : srList[i].getErrors()) {
                    error += error == '' ? 'Order ' + err.getMessage() : ', ' + err.getMessage();
                }
                ErrorUtility.LogError('Consume', 'SSIPScheduleBatch', error, 'SSIPScheduleBatch', 'crm', '', 'Account ID: ' + lstOrder[i].AccountId,
                                      'Fatal Error - Bailing out');
                System.debug('====error in order====='+error);
            }
        }

        
        List<Order> lstOrderToDelete = new List<Order>();
        srList = Database.insert(lstOrderItem, false);
        for(Integer i = 0; i < srList.size(); i++){
            if(srList[i].isSuccess()){
                
            }else {
                if(mapOrderNew.containsKey(lstOrderItem[i].OrderId)){
                    lstOrderToDelete.add(mapOrderNew.remove(lstOrderItem[i].OrderId));
                }
                String error = '';
                for(Database.Error err : srList[i].getErrors()) {
                    error += error == '' ? 'Order ' + err.getMessage() : ', ' + err.getMessage();
                }
                ErrorUtility.LogError('Consume', 'SSIPScheduleBatch', error, 'SSIPScheduleBatch', 'crm', '', 'Product ID: ' + lstOrderItem[i].Product2Id, 'Fatal Error - Bailing out');
                System.debug('====error in orderitem====='+error);
            }
        }
        
        
        for(Integer i = 0; i < lstOrder.size(); i++){
            String uniqueKey = lstUniqueKey[i];
            if(!mapOrderNew.containsKey(lstOrder[i].Id)) continue;
            for(SSIP_Schedule__c ssipSchedule : mapSSIPSchedule.get(uniqueKey)){
                ssipSchedule.Order__c = lstOrder[i].Id;
                if(mapSSIPScheduleUpdate.containsKey(ssipSchedule.Id)) tempSched = mapSSIPScheduleUpdate.get(ssipSchedule.Id); else tempSched = ssipSchedule;
                tempSched.Status__c = 'In Progress';
                if(tempSched.Try_to_Create_Order__c) tempSched.Try_to_Create_Order__c = false; 
                mapSSIPScheduleUpdate.put(tempSched.Id,tempSched);
                System.debug('**ssipSchedule--'+ssipSchedule);
                ordersToProcessForShipmentMap.put(lstOrder[i].Id, lstOrder[i]);
            }
        }
        
        //update lstSSIPSchedule;
        delete lstOrderToDelete;
        if(!ordersToProcessForShipmentMap.isEmpty()) ClsOrderEntryHandler.calculateShippingCharge(ordersToProcessForShipmentMap, null);
        Boolean paymentOnly = false;
        List<Order> OrdersToStatusChange = new List<Order>();
        List<SSIP_Schedule__c> lstSSIPScheduleErrupdate = new List<SSIP_Schedule__c>();
        Set<Id> orderIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        //if(!Test.isRunningTest()){
            System.debug('--Tests---');
            for(Order objOrder : [SELECT Id, Account.RecordType.Name, Payment_Terms__c, Finance_Detail__c, 
                                  Account.Subscription_Pending_Payments__c, Count_of_Order_Line_Items__c, AccountId,
                                  total_gross_Price__c, (select id from OrderItems where product2.name like 'MTR%')
                                  FROM Order WHERE Id IN: lstOrder]){
                                      
                // If there are pending Subscription Payments, leave the Order in Draft status  
                if (objOrder.Payment_Terms__c == 'net0' && objOrder.Account.Subscription_Pending_Payments__c != null &&
                    objOrder.Account.Subscription_Pending_Payments__c > 0 &&  objOrder.Total_Gross_Price__c == 0){
                            
                            if(!mapOrderNew.containsKey(objOrder.Id)) continue;
                            for(SSIP_Schedule__c ssipSchedule : lstNewSSIPSchedule){
                                String uniqueKey = ssipSchedule.Account__c +'_'+ ssipSchedule.SSIP_Rule__r.Price_Book__c;
                                for(SSIP_Schedule__c ssipScheduleObj : mapSSIPSchedule.get(uniqueKey)){
                                    if(mapSSIPScheduleUpdate.containsKey(ssipSchedule.Id)) tempSched = mapSSIPScheduleUpdate.get(ssipSchedule.Id); else tempSched = ssipSchedule;
                                    tempSched.Status__c = 'In Draft';
                                    tempSched.Error_Message__c = 'There are pending payments from this customer.';
                                    System.debug('--SSIPSchdeule in Draft--');
                                    mapSSIPScheduleUpdate.put(tempSched.id,tempSched);
                                }
                            }
                            continue;   
                        } 
                    if (objOrder.OrderItems.size() > 0) paymentOnly = true; else paymentOnly = false;   
                    // If the Order Amount is 0; there is no point in trying to calculate tax or trying to process credit card payments, so immediately set them on their merry way!    
                    if (objOrder.Total_Gross_Price__c == 0) {
                        system.debug('--Gross Total is 0--');
                        orderIds.add(objOrder.Id);
                        accIds.add(objOrder.AccountId);
                        if (objOrder.Payment_Terms__c == 'net0' || objOrder.Payment_Terms__c == 'net-1') OrdersToStatusChange.add(new Order(id=objOrder.Id, Status = 'Activated')); 
                        else OrdersToStatusChange.add(new Order(id=objOrder.Id, Status = 'Shipping Hold')); 
                        continue;   
                    } else {
                        
                        if(!Test.isRunningTest()){
                                System.enqueueJob(new SSIPScheduleJobUtiltiy.CalculateTaxQueueable(objOrder.Id, objOrder.Payment_Terms__c, objOrder.Account.RecordType.Name.substring(0,2), (Integer) objOrder.Count_of_Order_Line_Items__c,    
                                                                                                            (Integer) objOrder.Account.Subscription_Pending_Payments__c, objOrder.AccountId, paymentOnly)); 
                    
                        //System.enqueueJob(new SSIPScheduleJobUtiltiy.CalculateTaxQueueable(objOrder.Id, objOrder, objOrder.Account.RecordType.Name.substring(0,2), (Integer) objOrder.Count_of_Order_Line_Items__c,(Integer) objOrder.Account.Subscription_Pending_Payments__c, objOrder.AccountId, paymentOnly));    
                        }
                    }
            }
       // }
        update mapSSIPScheduleUpdate.values();
       
        try{
            if (OrdersToStatusChange.size() > 0) update OrdersToStatusChange;
        }catch(Exception ex){
           System.debug('**ErorMessage--'+ex);
           System.debug('**ErorLine--'+ex.getLineNumber());
            lstSSIPScheduleErrupdate = [Select id,Account__c,Account__r.Name,Order__c,Error_Message__c,Status__c 
                              from SSIP_Schedule__c 
                              where Account__c IN:accIds 
                              AND Order__c IN:orderIds];
                for(SSIP_Schedule__c ssip : lstSSIPScheduleErrupdate){
                    ssip.Error_Message__c = 'Order can not be preocessed due to Inactive account';
                    ssip.Status__c = 'In Draft'; 
                }
                update lstSSIPScheduleErrupdate;
            
        }
        
        //Need to logic for to handle the error using platform events..
    }
    
    private Order orderMapping(Account objAccount, Order firstOrder, String priceBookId, SSIP_Schedule__c ssipSchedule, String recordTypeId, String shippingAddressId, String billingAddressId, String financialDetailId, Boolean sign_reqd){
        String timeZone = mapTimeZone.containsKey(objAccount.RecordType.DeveloperName.substring(0, 2)) ? mapTimeZone.get(objAccount.RecordType.DeveloperName.substring(0, 2)) : 'America/Los_Angeles';
        Date effDt = ssipSchedule.Rescheduled_Shipment_Date__c != null ? ssipSchedule.Rescheduled_Shipment_Date__c : ssipSchedule.Schedule_Date__c;
        return new Order(AccountId = objAccount.Id, RecordTypeId = recordTypeId, 
                         Customer_Ship_To_Address__c = ssipSchedule.Shipping_Address__c != null ? ssipSchedule.Shipping_Address__c : shippingAddressId, 
                         Pricebook2Id = priceBookId, Type = objAccount.RecordType.DeveloperName.substring(0, 2) + ' STANDARD', 
                         EffectiveDate = Date.valueOf(DateTime.newInstance(effDt.year(), effDt.month(), effDt.day()).format('yyyy-MM-dd', timeZone)), 
                         Status = 'Draft', 
                         Customer_Bill_To_Address__c = ssipSchedule.SSIP_Rule__r.Effective_Payor__c != null ? null : (ssipSchedule.Billing_Address__c != null ? ssipSchedule.Billing_Address__c : billingAddressId),
                         Finance_Detail__c = ssipSchedule.Payment_Term__c == 'net0' ? financialDetailId : null, 
                         Shipping_Method__c = ssipSchedule.Shipping_Method__c != null ? ssipSchedule.Shipping_Method__c : (ssipSchedule.SSIP_Rule__r.Shipping_Method__c != null ? ssipSchedule.SSIP_Rule__r.Shipping_Method__c : firstOrder != null ? firstOrder.Shipping_Method__c : ''),
                         Payment_Terms__c = ssipSchedule.SSIP_Rule__r.Payment_Term__c != null ? ssipSchedule.SSIP_Rule__r.Payment_Term__c :(firstOrder != null ? firstOrder.Payment_Terms__c : 'net30'),
                         Fund__c = (ssipSchedule.SSIP_Rule__r.Is_Funded__c == 'True' && ssipSchedule.SSIP_Rule__r.Account__r.Fund__c != null) ? ssipSchedule.SSIP_Rule__r.Account__r.Fund__c : (firstOrder != null ? firstOrder.Fund__c : null), 
                         Payor__c = ssipSchedule.SSIP_Rule__r.Effective_Payor__c,
                         PONumber = ssipSchedule.SSIP_Rule__r.Effective_PO_Number__c,
                         Signature_Required__c = sign_reqd,
                         Tax_Exempt__c = ssipSchedule.SSIP_Rule__r.Effective_Tax_Exempt_Flag__c, Tax_Registration_Number__c = ssipSchedule.SSIP_Rule__r.Effective_Tax_Registration_Number__c);
    }
    
    private OrderItem orderItemMapping(PricebookEntry pbe, SSIP_Schedule__c ssipSchedule){
        return new OrderItem(PricebookEntryId = pbe.Id, UnitPrice = pbe.UnitPrice, Quantity = ssipSchedule.SSIP_Rule__r.Quantity__c);
    } 
    
    global void finish(Database.BatchableContext BC){
        
    }
}