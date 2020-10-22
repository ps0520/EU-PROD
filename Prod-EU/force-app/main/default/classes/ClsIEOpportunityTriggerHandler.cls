/*******************************************************************************************************************************************
@Description    : Class used to process IE Opportunity records to create Schedule Shipment and its line item entries as per the product schedule
********************************************************************************************************************************************/
public class ClsIEOpportunityTriggerHandler{
        static Set<Id> opptyIdsToProcess = new Set<Id>(); //Set of Opportunities Ids to be processed

	//Method checks if the Opportunity product has a schedule and then it will record the schedule shipments relating to Opportunity
    public static String processOpportunityForScheduleShipments(Map<Id, Opportunity> newTriggerOpportunities, Map<Id, Opportunity> oldTriggerOpportunities)
    {
        
		String returnMsg = 'OK';
		// Avoid Recursion - If this logic was executed during the same context 
        if(ClsOpportunityTriggerStaticClass.isExecuting)
            return returnMsg;
        ClsOpportunityTriggerStaticClass.isExecuting = true;
        
        system.debug('----Entering Process to find Opportunity for processing');
        for(Opportunity newOppty : newTriggerOpportunities.values())
        {
            Opportunity oldOppty = oldTriggerOpportunities.get(newOppty.Id);
            if(((oldOppty.StageName != newOppty.StageName) && newOppty.StageName == 'Order Fulfillment'))
            {
                opptyIdsToProcess.add(newOppty.Id);
            }
        }       
		//Process opportunity records for scheduled shipments
		if(opptyIdsToProcess != null) returnMsg = processOpportunityRecords();
		return returnMsg;
    }
    
    public static String processOpportunityRecords()
    {
        system.debug('----Entering Process to Process Opportunity records');
        Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity>();//Create a map between Opportunity Id and Opportunity record
		Map<Id, List<OpportunityLineItem>> oppToLinesMap = new Map<Id, List<OpportunityLineItem>>();//Map holds the reference between an Opp Id to its lines
        List<Order> ordersToAdd = new List<Order>();//Order records to be added
		List<OrderItem> orderItemsToAdd = new List<OrderItem>();//Order item records to be added
		List<SSIP_Rule__c> ssipRuleList = new List<SSIP_Rule__c>();//SSIP Rules List will be used to create the SSIP Rule
        Set<Id> accountIdSet = new Set<Id>();//Set of account ids to get the bill to and ship to addr information
        Set<Id> payorIdSet = new Set<Id>();//Set of account ids to get the bill to and ship to addr information
        
		Id orderRecTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('IE Sales Order').getRecordTypeId();
		Id ssipRuleRecTypeId = Schema.SObjectType.SSIP_Rule__c.getRecordTypeInfosByName().get('IE SSIP Rule').getRecordTypeId();
		Set<Id> pbIdSet = new Set<Id>();
        
		//Get the Opportunity and line details to process further
        for(Opportunity oppty : [SELECT Id, AccountId, Account.Primary_Card_Last_4__c, Account.Personemail, Account.Organzation_Email__c, PO_Number__c, Fund__c, Pricebook2Id, Type, Payor__c, (Select OpportunityId, PricebookEntryId, PriceBookEntry.PriceBook2Id, PriceBookEntry.Product2Id, PriceBookEntry.Product2.Name, Quantity, 
                                        UnitPrice, Repeat_after_in_Days__c, Repeat_Quantity__c, Repeat_End_Date__c, First_Repeat_Order_Lead_Days__c FROM OpportunityLineItems) FROM Opportunity WHERE Id IN : opptyIdsToProcess])
        {
            opptyMap.put(oppty.Id, oppty);
			oppToLinesMap.put(oppty.Id, oppty.OpportunityLineItems);
            accountIdSet.add(oppty.AccountId);
            pbIdSet.add(oppty.Pricebook2Id);
            if (oppty.Payor__c != null) payorIdSet.add(oppty.Payor__c);
        }
         //Use the following map to adjust the first order Qty and when to end the rule	
        Map<Id, PriceBookEntry> pbeMap = new Map<Id, PriceBookEntry>([Select Id, First_Order_Variation_Qty__c, Number_of_Repeat_Orders__c, PriceBook2.Subscription_Period_In_Days__c from PriceBookEntry where Pricebook2Id in :pbIdSet AND Optional_Subscription_Item__c = false]);	
		//Use the following map to set the Payment_Terms on the Order and on SSIP rules if applicable.	
		Map<Id, Account> paymentTermsMap = new Map<Id, Account>([Select Id, Payment_Terms__c, Tax_Exempt__c,Tax_Registration_Number__c from Account where id in :accountIdSet]);
		//Create a map between Account Id and Address (BillTo and ShipTo) objects
        Map<Id, Address__c> accntIdToBillToAddressMap = new Map<Id, Address__c>();
        Map<Id, Address__c> accntIdToShipToAddressMap = new Map<Id, Address__c>();
        if(opptyMap.size() > 0)
        {
            for(Address__c addr : [SELECT Id, Account__c, Address_Line_1__c, City__c, State__c, Postal_Code__c, Country__c, Type__c FROM Address__c WHERE Primary_Flag__c = TRUE AND Account__c IN : accountIdSet]) 
            {
                if(addr.Type__c == 'Bill To')
                    accntIdToBillToAddressMap.put(addr.Account__c, addr);
                else if(addr.Type__c == 'Ship To')
                    accntIdToShipToAddressMap.put(addr.Account__c, addr);
            }
        }
        Map<Id, Address__c> payorAddMap = new Map<Id, Address__c>();
        if (payorIdSet.size() > 0) {
            List<Address__c> payorAddList = [Select Id, Account__c, Address_Line_1__c, City__c, State__c, Postal_Code__c, Country__c, Account__r.Payment_Terms__c FROM Address__c WHERE Account__c in :payorIdSet AND Primary_Flag__c = TRUE AND Type__c = 'Bill To'];
            for (Address__c a : payorAddList) payorAddMap.put(a.Account__c, a);
        }
       
        //For each opportunity create entries for Order 
        for(Opportunity currOppty : opptyMap.values())
        {
			List<OpportunityLineItem> oppLinesList = oppToLinesMap.get(currOppty.Id);//Get all the opportunity lines tied to the current Opportunity
			String externalIdValue = currOppty.Id + '|' + system.today();
			String accountId = currOppty.AccountId;                
			Address__c billToAddress = accountId != null ? accntIdToBillToAddressMap.get(accountId) : null;
			Address__c shipToAddress = accountId != null ? accntIdToShipToAddressMap.get(accountId) : null;
			//Prepare Order Header record entry
			Order orderToBeCreated = new Order();
			orderToBeCreated.AccountId = accountId;
            if (shipToAddress == null || String.isBlank(shipToAddress.Id)) return 'No Primary Ship To Address is present for this User. Please add it on the Account and Retry.';
			orderToBeCreated.Customer_Ship_To_Address__c = shipToAddress.Id; 
			orderToBeCreated.ShippingStreet = shipToAddress.Address_Line_1__c;
			orderToBeCreated.ShippingCity = shipToAddress.City__c;
			orderToBeCreated.ShippingState = shipToAddress.State__c;
			orderToBeCreated.ShippingPostalCode = shipToAddress.Postal_Code__c;
			orderToBeCreated.ShippingCountry = shipToAddress.Country__c;
			orderToBeCreated.OpportunityId = currOppty.Id;
			orderToBeCreated.Status = 'Draft';
			orderToBeCreated.Price_Book__c = currOppty.Pricebook2Id;
			orderToBeCreated.EffectiveDate = system.today(); 
			orderToBeCreated.External_Id__c = externalIdValue;
			orderToBeCreated.Type = 'IE STANDARD';
			orderToBeCreated.CurrencyIsoCode = 'EUR';
			orderToBeCreated.Invoice_Email__c = currOppty.Payor__c != null ? null : (currOppty.Account.Personemail != null ? currOppty.Account.Personemail : currOppty.Account.Organzation_Email__c);
            orderToBeCreated.RecordTypeId = orderRecTypeId;
            orderToBeCreated.Tax_Exempt__c = paymentTermsMap.get(accountId).Tax_Exempt__c;
			If (String.isNotBlank(paymentTermsMap.get(accountId).Tax_Registration_Number__c)) orderToBeCreated.Tax_Registration_Number__c = paymentTermsMap.get(accountId).Tax_Registration_Number__c;			                       
            If (String.isNotBlank(paymentTermsMap.get(accountId).Payment_Terms__c)) orderToBeCreated.Payment_Terms__c = paymentTermsMap.get(accountId).Payment_Terms__c;
            orderToBeCreated.Fund__c = currOppty.Fund__c;
            //orderToBeCreated.PONumber = currOppty.Fund__c != null ? currOppty.Fund__r.PO_Reference_Number__c : null;
            orderToBeCreated.PONumber = currOppty.PO_Number__c;
            //Add the Payor and Payor's Primary Bill to Address to the Order
            if (currOppty.Payor__c != null) {
                orderToBeCreated.Payor__c = currOppty.Payor__c;
                if (payorAddMap.containsKey(currOppty.Payor__c)) {
                    /*--NS-543-This is not needed as there is existing logic in Order object, which will populate the correct Payor address
                    orderToBeCreated.Payor_Bill_To_Address__c = payorAddMap.get(currOppty.Payor__c).id;
                    orderToBeCreated.BillingStreet = payorAddMap.get(currOppty.Payor__c).Address_Line_1__c;
                    orderToBeCreated.BillingCity = payorAddMap.get(currOppty.Payor__c).City__c;
                    orderToBeCreated.BillingState = payorAddMap.get(currOppty.Payor__c).State__c;
                    orderToBeCreated.BillingPostalCode = payorAddMap.get(currOppty.Payor__c).Postal_Code__c;
                    orderToBeCreated.BillingCountry = payorAddMap.get(currOppty.Payor__c).Country__c;*/
                    if (String.isnotBlank(payorAddMap.get(currOppty.Payor__c).Account__r.Payment_Terms__c)) orderToBeCreated.Payment_Terms__c = payorAddMap.get(currOppty.Payor__c).Account__r.Payment_Terms__c;
                    	else orderToBeCreated.Payment_Terms__c = 'net30';
                }
            } else {
                if (billToAddress == null || String.isBlank(billToAddress.Id)) return 'No Primary Bill To Address is present for this User. Please add it on the Account and Retry.';
                orderToBeCreated.Customer_Bill_To_Address__c = billToAddress.Id;
                orderToBeCreated.BillingStreet = billToAddress.Address_Line_1__c;
                orderToBeCreated.BillingCity = billToAddress.City__c;
                orderToBeCreated.BillingState = billToAddress.State__c;
                orderToBeCreated.BillingPostalCode = billToAddress.Postal_Code__c;
                orderToBeCreated.BillingCountry = billToAddress.Country__c;
            	orderToBeCreated.Tax_Exempt__c = paymentTermsMap.get(accountId).Tax_Exempt__c; // Should only be set if Account is being billed rather than a Payor. VA 02/28/2020
            }
            if (orderToBeCreated.Payment_Terms__c == 'net0' && currOppty.Account.Primary_Card_Last_4__c == 0) {
                // currOppty.addError('No Primary Credit Card is present for this User. Please add it on the Account and Retry.'); 
                return 'No Primary Credit Card is present for this User. Please add it on the Account and Retry.'; 
            }
			//Add the order to the list that will be used to create the Orders
			ordersToAdd.add(orderToBeCreated);
			//Prepare the order reference
			Order orderRef = new Order(External_Id__c = externalIdValue);
			//Associate the Order reference to the Opportunity		
			currOppty.Associated_Order__r = orderRef;
			//Create the Order lines corresponding to the Opportunity lines
			Double diffQty = 0;	
            Integer orderLength = 0;
			for(OpportunityLineItem oli : oppLinesList)
			{
				if (pbeMap.containsKey(oli.PricebookEntryId) && pbeMap.get(oli.PricebookEntryId).First_Order_Variation_Qty__c != null) diffQty = pbeMap.get(oli.PricebookEntryId).First_Order_Variation_Qty__c; else diffQty = 0;	
                if (oli.Quantity + diffQty > 0) {  // Make Order Line entries only if the Order quantity > 0
                    //Make entries based on what is there on the Opportunity and not overwrite with book entries
                    OrderItem orderItemToBeCreated = new OrderItem ();
                    orderItemToBeCreated.Order = orderRef;
                    orderItemToBeCreated.PricebookEntryId = oli.PricebookEntryId;
                    orderItemToBeCreated.Quantity = oli.Quantity + diffQty;
                    orderItemToBeCreated.UnitPrice = oli.UnitPrice;
                    orderItemsToAdd.add(orderItemToBeCreated);
                }
				//If the Opp lines have the SSIP details filled in then the SSIP Rules should be created for each Opportunity lines
				if((oli.Repeat_Quantity__c != null && oli.Repeat_Quantity__c > 0 && oli.Repeat_after_in_Days__c != null && oli.Repeat_after_in_Days__c > 0))
				{
					//Make entries to SSIP Rule when the Repeat fields are filled in
					SSIP_Rule__c ssipRuleToBeCreated = new SSIP_Rule__c();
                    ssipRuleToBeCreated.Account__c = accountId;
                    ssipRuleToBeCreated.Country__c = 'Ireland';
                    ssipRuleToBeCreated.CurrencyIsoCode = 'EUR';
                    ssipRuleToBeCreated.Frequency_In_Days__c = oli.Repeat_after_in_Days__c;
                    ssipRuleToBeCreated.Payment_Term__c = orderToBeCreated.Payment_Terms__c; // 'net30';
                    //If (String.isNotBlank(paymentTermsMap.get(accountId).Payment_Terms__c)) ssipRuleToBeCreated.Payment_Term__c = paymentTermsMap.get(accountId).Payment_Terms__c;//Commented this line for Story NS-537
                    ssipRuleToBeCreated.Price_Book__c = oli.PriceBookEntry.PriceBook2Id;
                    ssipRuleToBeCreated.Product__c = oli.PriceBookEntry.Product2Id;
                    ssipRuleToBeCreated.Product_Name__c = oli.PriceBookEntry.Product2.Name;                    
                    ssipRuleToBeCreated.First_Order__r = orderRef;
                    ssipRuleToBeCreated.Quantity__c = oli.Repeat_Quantity__c;
                    ssipRuleToBeCreated.RecordTypeId = ssipRuleRecTypeId;
                    ssipRuleToBeCreated.Rule_Start_Date__c = system.date.today();
                    ssipRuleToBeCreated.Rule_End_Date__c = oli.Repeat_End_Date__c;
                    ssipRuleToBeCreated.PriceBookEntryId__c = oli.PricebookEntryId;
                    ssipRuleToBeCreated.First_Repeat_Order_Lead_Days__c = oli.First_Repeat_Order_Lead_Days__c;
                    ssipRuleToBeCreated.Status__c = 'Active';
                    if (pbeMap.get(oli.PricebookEntryId).PriceBook2.Subscription_Period_In_Days__c != null && pbeMap.get(oli.PricebookEntryId).PriceBook2.Subscription_Period_In_Days__c > 0)
                        	ssipRuleToBeCreated.Renewal_Date__c = system.date.today() + (Integer) pbeMap.get(oli.PricebookEntryId).PriceBook2.Subscription_Period_In_Days__c;
                    if (pbeMap.get(oli.PricebookEntryId).Number_of_Repeat_Orders__c != null && pbeMap.get(oli.PricebookEntryId).Number_of_Repeat_Orders__c > 0 && oli.Repeat_End_Date__c == null) {	
                         orderLength =Integer.valueOf((pbeMap.get(oli.PricebookEntryId).Number_of_Repeat_Orders__c * oli.Repeat_after_in_Days__c) - oli.First_Repeat_Order_Lead_Days__c + 1);	
                         ssipRuleToBeCreated.Rule_End_Date__c = ssipRuleToBeCreated.Rule_Start_Date__c + orderLength;	
                    }
                    ssipRuleList.add(ssipRuleToBeCreated);
				}
			}
			
        }
		//Insert Order Records
        if (ordersToAdd.size() > 0) {
			string result;
            try { insert ordersToAdd;
                } catch (DmlException de) {
                if(de.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) result = de.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').substringBefore('[');
                return result;
            }
        }
		
		//Insert Order lines Records
        if (orderItemsToAdd.size() > 0) {
			string result;
            try { insert orderItemsToAdd;
                } catch (DmlException de) {
                if(de.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) result = de.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').substringBefore('[');
                return result;
            }
        }
		//Update Opportunity records with Order reference
        if (ordersToAdd.size() > 0) {
			string result;
            try { update opptyMap.values();
                } catch (DmlException de) {
                    if(de.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) result = de.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').substringBefore('[');
                    return result;
                }
        }
		//Insert SSIP Rule Records
        if (ssipRuleList.size() > 0) {
			string result;
            try { insert ssipRuleList;
                } catch (DmlException de) {
                    if(de.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) result = de.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').substringBefore('[');
                    if(de.getMessage().contains('DUPLICATES_DETECTED')) result = 'SSIP Rule for the same Product already exist, only one rule can be active for a Product.';
                    return result;
                }
        }
		return 'OK';
    } 
}