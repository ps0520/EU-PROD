public class ClsOrderEntryHandler {
/****************************************************************************************************************
@Description    : This method will maintain the logic to accomodate Shipping Charges for NewCo Orders
****************************************************************************************************************/
    public static void calculateShippingCharge(Map<Id, Order> newOrderMap, Map<Id, Order> oldOrderMap) {
        //The below is set-up this way to accommodate Test Classes where they don't always create both Freight Charge and DEX-SHIP-01 products.
        //Id fcId = [Select Id from Product2 where Name = 'DEX-SHIP-01'].id;
        //Id cafcId = [Select Id from Product2 where Name = 'FREIGHT CHARGE'].id;
        List<PriceBookEntry> pbeList = new List<PriceBookEntry>();
        List<OrderItem> oiList = new List<OrderItem>();
        String fcId = ''; 
        List<Product2> pdship   = [Select Id from Product2 where Name = 'DEX-SHIP-01'];
        if (pdship.size() > 0) fcId = pdship[0].Id;
        
        String cafcId = '';
        List<Product2> pdcharge = [Select Id from Product2 where Name = 'FREIGHT CHARGE'];
        if (pdcharge.size() > 0) cafcId = pdcharge[0].Id;
        System.debug('**cafcId--'+cafcId);
        
        Map<String, PriceBookEntry> pbesMap = new Map<String, PriceBookEntry>();
        if(fcId != '' && cafcId !=''){
            pbeList = [Select PriceBook2Id, Id, UnitPrice, PriceBook2.Name, Product2.Name from PriceBookEntry where (Product2Id = :fcId or Product2Id = :cafcId)];
            oiList = [Select OrderId, id from OrderItem where OrderId in :newOrderMap.keyset() AND (Product2Id = :fcId or Product2Id = :cafcId) ];
        }else if(fcId != '' && cafcId ==''){
            pbeList = [Select PriceBook2Id, Id, UnitPrice, PriceBook2.Name, Product2.Name from PriceBookEntry where (Product2Id = :fcId)];
            oiList = [Select OrderId, id from OrderItem where OrderId in :newOrderMap.keyset() AND (Product2Id = :fcId) ];
        }else if(cafcId != '' && fcId == '' ){
            pbeList = [Select PriceBook2Id, Id, UnitPrice, PriceBook2.Name, Product2.Name from PriceBookEntry where (Product2Id = :cafcId)];
            oiList = [Select OrderId, id from OrderItem where OrderId in :newOrderMap.keyset() AND (Product2Id = :cafcId) ];
        }
        //System.debug('**pbeList--'+pbeList.size());
       // System.debug('**oiList--'+oiList.size());
        if (pbeList.size() < 1) return;
        for(PriceBookEntry pbe : pbeList) {
            System.debug('**pbe.PriceBook2.Name--'+pbe.PriceBook2.Name);
            if(pbe.PriceBook2.Name != null){
                
                if ((pbe.PriceBook2.Name.startsWithIgnoreCase('CA') && pbe.Product2.Name.startswithIgnoreCase('FREIGHT CHARGE')) || 
                (!pbe.PriceBook2.Name.startsWithIgnoreCase('CA') && pbe.Product2.Name.startswithIgnoreCase('DEX-SHIP-01')) )
                pbesMap.put(pbe.PriceBook2Id, Pbe);
            }
            
        }
        Map<String, Shipping_Charges__mdt> shipChargeMap = new Map<String, Shipping_Charges__mdt>();
        List<Shipping_Charges__mdt> mdtEntries = [Select Shipping_Method__c, Charge__c FROM Shipping_Charges__mdt];
        for(Shipping_Charges__mdt mdtEntry : mdtEntries) shipChargeMap.put(mdtEntry.Shipping_Method__c.trim(), mdtEntry);
        //for(Shipping_Charges__mdt mdt : shipChargeMap.values()) system.debug('Shipping Method: ' + mdt.Shipping_Method__c + ', Charge: ' + mdt.Charge__c);
        Map<Id, OrderItem> olMap = new Map<Id, OrderItem>();
       // List<OrderItem> oiList = [Select OrderId, id from OrderItem where OrderId in :newOrderMap.keyset() AND (Product2Id = :fcId or Product2Id = :cafcId) ];
        for(OrderItem oiEntry : oiList) olMap.put(oiEntry.OrderId, oiEntry);
        List<OrderItem> oisInsert = new List<OrderItem>();
        List<OrderItem> oisUpdate = new List<OrderItem>();
        List<OrderItem> oisDelete = new List<OrderItem>();
        List<Order> ordersToUpdate = new List<Order>();
        Order tbaOrder = new Order();
        for(Order o : newOrderMap.values()) {
            if (o.Type!= null && (o.Type.containsIgnoreCase('RETURN') || o.Type.startsWithIgnoreCase('DIST'))) continue; //Shouldn't add any price for return or Dist orders.
             //system.debug('New Shipping Method: ' + o.Shipping_Method__c + ', Old Shipping Method: ' + oldOrderMap.get(o.Id).Shipping_Method__c);
            if (oldOrderMap == null || (oldOrderMap!= null && o.Shipping_Method__c != oldOrderMap.get(o.Id).Shipping_Method__c)) {
                if (shipChargeMap.containsKey(o.Shipping_Method__c.trim())){
                    tbaOrder = new Order(id=o.id, Shipping_Charges__c = shipChargeMap.get(o.Shipping_Method__c).Charge__c);
                    if(String.isNotBlank(o.Need_To_Calculate_Tax__c)) tbaOrder.Need_To_Calculate_Tax__c = 'True';
                    ordersToUpdate.add(tbaOrder);
                    if(pbesMap.containsKey(o.Pricebook2Id)) { 
                        if(!olMap.containsKey(o.Id)) {
                            oisInsert.add(new OrderItem(orderId = o.id, Quantity = shipChargeMap.get(o.Shipping_Method__c).Charge__c, PricebookEntryId= pbesMap.get(o.Pricebook2Id).Id, 
                                                        UnitPrice =pbesMap.get(o.Pricebook2Id).UnitPrice )); 
                            continue; 
                        }
                        if(olMap.containsKey(o.Id)) {oisUpdate.add(new OrderItem(id=olMap.get(o.Id).Id, Quantity = shipChargeMap.get(o.Shipping_Method__c).Charge__c)); continue;}
                    }
                } else {
                    ordersToUpdate.add(new Order(id=o.id, Shipping_Charges__c = 0.00));
                    if(olMap.containsKey(o.Id)) 
                    	oisDelete.add(new OrderItem(id=olMap.get(o.Id).Id));	
                }
            }
        }
        if (oisInsert.size() > 0) insert oisInsert;
        if (oisUpdate.size() > 0) update oisUpdate;
        if (oisDelete.size() > 0) delete oisDelete;
        if (ordersToUpdate.size() > 0) update ordersToUpdate;

    }
    // Method to set default Primary Card as Finance Detail if Payment Terms of Credit Card is Chosen and No Card is set or raise error if no primary card exists.
    public static void checkForCreditCard(Map<Id, Order> updatedOrdersMap) {
    	Map<Id, Id> orderToaccountMap = new Map<Id, Id>();
        for (Order o : updatedOrdersMap.values()) {
            if (o.Payment_Terms__c == 'net0' && o.Total_Gross_Price__c != 0.0 && String.isBlank(o.Finance_Detail__c)) //need to add credit card details
                orderToaccountMap.put(o.Id, o.AccountId);
        }
       List<Finance_Detail__c> fdList = [Select Account__c, Id, Last_4_Digits__c from Finance_Detail__c 
                                                                           where InActive__c = false AND  RecordType.Name = 'Credit Card' AND Primary__c = true AND Account__c in :orderToaccountMap.values()];
        Map<Id, Finance_Detail__c> accountTofdMap = new Map<Id, Finance_Detail__c>();
        for (Finance_Detail__c fd : fdList) accountTofdMap.put(fd.Account__c, fd);
        for(Id o : orderToaccountMap.keyset()) {
            if(accountTofdMap.containsKey(orderToaccountMap.get(o))) updatedOrdersMap.get(o).Finance_Detail__c = accountTofdMap.get(orderToaccountMap.get(o)).Id;
            else updatedOrdersMap.get(o).addError('No Primary Credit Card exists for this payer. Please add a Primary Credit Card before changing the Payment Terms or Choose a Card that is set-up on Account.');
        }
    }
    @auraEnabled
    public static String authorizeCreditCard(ID oId) {
        Order ord = [Select Id, TotalAmount, Shipping_Charges__c, Total_Gross_Price__c, CC_Auth_Amount__c, Payment_Id__c, Need_To_Calculate_Tax__c, Payment_Terms__c, Tax_Exempt__c,
                     Finance_Detail__c, Finance_Detail__r.Token__c, Finance_Detail__r.Expiry_Date__c, Finance_Detail__r.CC_Address__c, Count_of_Order_Line_Items__c
                     from Order where Id = :oId];
        if (ord.Need_To_Calculate_Tax__c == 'True' && !ord.Tax_Exempt__c) {return 'Please Calculate Tax before Authorizing Credit Card';}
        if (ord.Payment_Terms__c != 'net0') {return 'Payment Term is not Credit Card, so this action cannot be performed';}
        if (ord.Count_of_Order_Line_Items__c == 0 || (ord.Count_of_Order_Line_Items__c == 1 && ord.Total_Gross_Price__c == ord.Shipping_Charges__c && ord.Total_Gross_Price__c > 0))
        /* if (ord.TotalAmount == 0.00 || ord.TotalAmount == ord.Shipping_Charges__c)  */ {return 'Please add a Product before Authorizing Credit Card';}
        if (ord.Finance_Detail__c !=null){	
            if(ord.Finance_Detail__r.Token__c==null){	
            	System.Debug('*** TPS:EH Token missing on related finance detail record for an order id:' + oId);	
        		return 'Error: Token missing on related finance detail record.';	
            }            	
            if(ord.Finance_Detail__r.Expiry_Date__c==null){	
            	System.Debug('*** TPS:EH Credit card expiry date is missing on related finance detail record for an order id:' + oId);	
        		return 'Error: Credit card expiry date is missing on related finance detail record.';	
            }	
            if(ord.Finance_Detail__r.CC_Address__c==null){	
            	System.Debug('*** TPS:EH Address is missing on related finance detail record for an order id:' + oId);	
        		return 'Error: Address is missing on related finance detail record.';	
            }            	
        } else {	
        	System.Debug('*** TPS:EH Finance detail is null for an order id:' + oId);	
        	return 'Error: This order is missing link to a Finance Detail record.';		
        }        
        
        System.Debug('*** TPS:EH authorizeCreditCard Order=' + ord);
        if (ord.Payment_Id__c!=null && ord.CC_Auth_Amount__c!=null){
            System.Debug('*** TPS:EH authorizeCreditCard Authorization already completed for ord.CC_Auth_Amount__c=' + ord.CC_Auth_Amount__c);
        	return 'Card is already authorized and cannot be re-authorized. Authorization has already been completed for Order Amount: '  + ord.CC_Auth_Amount__c;
        }  
        
        Map<Id, ClsCCAuthAndSettlementResponse> aResp = ClsCCAuthAndSettlementService.authorize(oId);
        if (aResp.get(oId).status != ClsCCAuthAndSettlementResponse.enumStatus.SUCCESS) { 
            Order o = new Order(id = oId);
            o.addError('');
            return 'Unable to authorize Credit Card. Returned Error: ' + aResp.get(oId).error;
       	}
        else return 'Credit Card has been authorized';
        
    }
    @auraEnabled
    public static String CCsettlePayment(ID oId) {
        Map<String, String> retMsg = new Map<String, String>();
        Map<Id, ClsCCAuthAndSettlementResponse> sResp = ClsCCAuthAndSettlementService.settlePayment(oId);
        if (sResp.get(oId).status != ClsCCAuthAndSettlementResponse.enumStatus.SUCCESS) {
            Order o = new Order(id = oId);
            // o.addError('');
            //retMsg.put('Error', 'Unable to Charge Credit Card. Returned Error: ' + sResp.get(oId).error);
            return 'Error - Unable to Charge Credit Card. Returned Error: ' + sResp.get(oId).error;
        }
        else {
            //retMsg.put('OK', 'Credit Card has been charged');
            return 'OK - Credit Card has been charged';
        }
    }
    @auraEnabled
    public static String captureCCpayment(ID oId) {
        Map<String, String> retMsg = new Map<String, String>();
        Map<Id, ClsCCAuthAndSettlementResponse> sResp = ClsCCAuthAndSettlementService.authorizeAndSettlePayment(oId);
        if (sResp.get(oId).status != ClsCCAuthAndSettlementResponse.enumStatus.SUCCESS) {
            Order o = new Order(id = oId);
            // o.addError('');
            //retMsg.put('Error', 'Unable to Charge Credit Card. Returned Error: ' + sResp.get(oId).error);
            return 'Error - Unable to Charge Credit Card. Returned Error: ' + sResp.get(oId).error;
        }
        else {
            //retMsg.put('OK', 'Credit Card has been charged');
            return 'OK - Credit Card has been charged';
        }
    }
    @auraEnabled public static String ccAuthorizeAndSettlePayment(ID oId){
        Order ord = [Select Id, TotalAmount, Shipping_Charges__c, Total_Gross_Price__c, CC_Auth_Amount__c, Payment_Id__c, Need_To_Calculate_Tax__c, Payment_Terms__c, Tax_Exempt__c, 
                     Finance_Detail__c, Finance_Detail__r.Token__c, Finance_Detail__r.Expiry_Date__c, Finance_Detail__r.CC_Address__c, Account.Inactive__c, Account.Credit_Hold__c, Account.Efficacy_Status__c, Count_of_Order_Line_Items__c from Order where Id = :oId];
        if (ord.Need_To_Calculate_Tax__c == 'True' && !ord.Tax_Exempt__c) {return 'Please Calculate Tax before Authorizing Credit Card';}
        if (ord.Payment_Terms__c != 'net0') {return 'Payment Term is not Credit Card, so this action cannot be performed';}
        if (ord.Count_of_Order_Line_Items__c == 0 || (ord.Count_of_Order_Line_Items__c == 1 && ord.Total_Gross_Price__c == ord.Shipping_Charges__c && ord.Total_Gross_Price__c > 0))
        /*if (ord.TotalAmount == 0.00 || ord.TotalAmount == ord.Shipping_Charges__c) */  {return 'Please add a Product before Charging Credit Card';}
        
        if (ord.Finance_Detail__c !=null){	
            if(ord.Finance_Detail__r.Token__c==null){	
            	System.Debug('*** TPS:EH Token missing on related finance detail record for an order id:' + oId);	
        		return 'Error: Token missing on related finance detail record.';	
            }            	
            if(ord.Finance_Detail__r.Expiry_Date__c==null){	
            	System.Debug('*** TPS:EH Credit card expiry date is missing on related finance detail record for an order id:' + oId);	
        		return 'Error: Credit card expiry date is missing on related finance detail record.';	
            }	
            if(ord.Finance_Detail__r.CC_Address__c==null){	
            	System.Debug('*** TPS:EH Address is missing on related finance detail record for an order id:' + oId);	
        		return 'Error: Address is missing on related finance detail record.';	
            }            	
        } else {	
        	System.Debug('*** TPS:EH Finance detail is null for an order id:' + oId);	
        	return 'Error: This order is missing link to a Finance Detail record.';		
        }
        
        System.Debug('*** TPS:EH authorizeCreditCard Order='+ ord);
        if (ord.Payment_Id__c!=null && ord.CC_Auth_Amount__c!=null){
            System.Debug('*** TPS:EH authorizeCreditCard Authorization already completed for ord.CC_Auth_Amount__c=' + ord.CC_Auth_Amount__c);
        	return 'Card is already authorized and cannot be re-authorized. Authorization has already been completed for Order Amount: '  + ord.CC_Auth_Amount__c;
        } 
		//Check Account Credit Hold
		if (ord.Account.Credit_Hold__c) return 'Customer is on Credit Hold, so this action cannot be performed.';
		//Check Account Efficacy Status
		if (ord.Account.Efficacy_Status__c == 'Training Hold') return 'The customer\'s Efficacy Status is \'Training Hold\', so this action cannot be performed.';
		//Check if Account is Inactive
		if (ord.Account.Inactive__c == True) return 'The customer\'s Account is Inactive, so this action cannot be performed.';
        if (ord.Total_Gross_Price__c == 0 ) {
            try { 
                update new Order(Id = oId, Status = 'Activated'); 
                return 'Credit Card is not Charged as the Order Amount is 0';
            }
            catch (DmlException de) {
                if(de.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) 
                    return de.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').substringBefore('[');
                else
                    return 'ERROR! '+de.getMessage();
            }		
            catch(Exception ex){
                return 'ERROR! '+ex.getMessage();
            }
        } else {
            try{
                Map<Id, ClsCCAuthAndSettlementResponse> mapResponse = ClsCCAuthAndSettlementService.authorizeAndSettlePayment(oId);  
                if(mapResponse.containsKey(oId) && mapResponse.get(oId).Status == ClsCCAuthAndSettlementResponse.enumStatus.SUCCESS){
                    ClsOrderHandlerStatic.executeOrderEventTriggerv11 = true;//Added this line to force the Order publishing execution
                    update new Order(Id = oId, Status = 'Activated');
                    ClsOrderEntryHandler.handlePendingSubscriptionPayments(oid);
                }
                return  mapResponse.containsKey(oId) ? mapResponse.get(oId).Status != ClsCCAuthAndSettlementResponse.enumStatus.SUCCESS ? 'Error! ' + mapResponse.get(oId).Error : 'Success! Credit Card has been Charged' : 'ERROR! Credit Card charging failed.';	
                //update the order to activate
            }
            catch (DmlException de) {
                if(de.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) 
                    return de.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').substringBefore('[');
                else
                    return 'ERROR! '+de.getMessage();
            }		
            catch(Exception ex){
                return 'ERROR! '+ex.getMessage();
            }
        }
	}
    
    public static void handlePendingSubscriptionPayments (Id oid) {
        Order o = [Select AccountId, Total_Gross_Price__c, Payment_Terms__c, Account.Subscription_Pending_Payments__c, Count_of_Order_Line_Items__c, PriceBook2.Name, (select id from OrderItems where product2.name like 'MTR%') from Order where Id = :oid limit 1];
        if (o.Count_of_Order_Line_Items__c == 1 && o.Total_Gross_Price__c > 0 && o.Account.Subscription_Pending_Payments__c > 0 && o.PriceBook2.Name.containsIgnoreCase('SUB') && o.OrderItems.size() > 0)
            update new Account(id=o.AccountId, Subscription_Pending_Payments__c = o.Account.Subscription_Pending_Payments__c - 1 );
    }
    
    public static Boolean validateEmail(String email){
        if(String.isEmpty(email) || String.isBlank(email)) return false;
        return Pattern.compile('^[a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$').matcher(email).matches();
    }
    
    public static Boolean validatePhone(String phone){
        if(String.isEmpty(phone) || String.isBlank(phone)) return false;
        return Pattern.compile('^[+0-9a-zA-Z .,()#-:]*$').matcher(phone).matches();
    }
    
    public class LockAddressQueueable implements Queueable, Database.AllowsCallouts{
        Set<Id> setAddressId = new Set<Id>();
        public LockAddressQueueable(Set<Id> setAddressId){
            this.setAddressId = setAddressId;
        }
        public void execute(QueueableContext context){
            Map<Id, Address__c> mapLockAddresses = new Map<Id, Address__c>();
            for(Address__c addr : [SELECT Id, IsLocked__c FROM Address__c WHERE Id IN: setAddressId]){
                addr.IsLocked__c = true;
                mapLockAddresses.put(addr.Id, addr);
            }
            if(!mapLockAddresses.isEmpty()) update mapLockAddresses.values();
        } 
    }   
}