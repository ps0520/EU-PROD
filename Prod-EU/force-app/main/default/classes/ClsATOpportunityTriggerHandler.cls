/****************************************************************************************************************************************************
@Description    : Class used to process Opportunity records to create Schedule Shipment and its line item entries as per the product schedule for AT
*****************************************************************************************************************************************************/
public class ClsATOpportunityTriggerHandler
{
    static Set<Id> opptyIdsToProcess = new Set<Id>();//Set of Opportunities Ids to be processed
    
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
        
		Id orderRecTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('AT Sales Order').getRecordTypeId();
		Id ssipRuleRecTypeId = Schema.SObjectType.SSIP_Rule__c.getRecordTypeInfosByName().get('AT SSIP Rule').getRecordTypeId();

		//Get the Opportunity and line details to process further
        for(Opportunity oppty : [SELECT Id, AccountId, Pricebook2Id, Type, Payor__c, (Select OpportunityId, PricebookEntryId, PriceBookEntry.PriceBook2Id, PriceBookEntry.Product2Id, PriceBookEntry.Product2.Name, Quantity, 
                                        UnitPrice, Repeat_after_in_Days__c, Repeat_Quantity__c, Repeat_End_Date__c, First_Repeat_Order_Lead_Days__c FROM OpportunityLineItems) FROM Opportunity WHERE Id IN : opptyIdsToProcess])
        {
            opptyMap.put(oppty.Id, oppty);
			oppToLinesMap.put(oppty.Id, oppty.OpportunityLineItems);
            accountIdSet.add(oppty.AccountId);
            if (oppty.Payor__c != null) payorIdSet.add(oppty.Payor__c);
        }
        
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
            List<Address__c> payorAddList = [Select Id, Account__c, Address_Line_1__c, City__c, State__c, Postal_Code__c, Country__c FROM Address__c WHERE Account__c in :payorIdSet AND Primary_Flag__c = TRUE AND Type__c = 'Bill To'];
            for (Address__c a : payorAddList) payorAddMap.put(a.Account__c, a);
        }
       
        //For each opportunity create entries for Order 
        for(Opportunity currOppty : opptyMap.values())
        {
			List<OpportunityLineItem> oppLinesList = oppToLinesMap.get(currOppty.Id);//Get all the opportnity lines tied to the current Opportunity
			String externalIdValue = currOppty.Id + '|' + system.today();
			String accountId = currOppty.AccountId;                
			Address__c billToAddress = accountId != null ? accntIdToBillToAddressMap.get(accountId) : null;
			Address__c shipToAddress = accountId != null ? accntIdToShipToAddressMap.get(accountId) : null;
			//Prepare Order Header record entry
			Order orderToBeCreated = new Order();
			orderToBeCreated.AccountId = accountId;               
			//orderToBeCreated.Customer_Bill_To_Address__c = billToAddress.Id;
			orderToBeCreated.Customer_Ship_To_Address__c = shipToAddress.Id; 
			//orderToBeCreated.BillingStreet = billToAddress.Address_Line_1__c;
			//orderToBeCreated.BillingCity = billToAddress.City__c;
			//orderToBeCreated.BillingState = billToAddress.State__c;
			//orderToBeCreated.BillingPostalCode = billToAddress.Postal_Code__c;
			//orderToBeCreated.BillingCountry = billToAddress.Country__c;
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
			orderToBeCreated.Type = 'AT STANDARD';
			orderToBeCreated.CurrencyIsoCode = 'EUR';
			orderToBeCreated.RecordTypeId = orderRecTypeId;
            //Add the Payor and Payor's Primary Bill to Address to the Order
            if (currOppty.Payor__c != null) {
                orderToBeCreated.Payor__c = currOppty.Payor__c;
                if (payorAddMap.containsKey(currOppty.Payor__c)) {
                    orderToBeCreated.Payor_Bill_To_Address__c = payorAddMap.get(currOppty.Payor__c).id;
                    orderToBeCreated.BillingStreet = payorAddMap.get(currOppty.Payor__c).Address_Line_1__c;
                    orderToBeCreated.BillingCity = payorAddMap.get(currOppty.Payor__c).City__c;
                    orderToBeCreated.BillingState = payorAddMap.get(currOppty.Payor__c).State__c;
                    orderToBeCreated.BillingPostalCode = payorAddMap.get(currOppty.Payor__c).Postal_Code__c;
                    orderToBeCreated.BillingCountry = payorAddMap.get(currOppty.Payor__c).Country__c;
                }
            } else {
                orderToBeCreated.Customer_Bill_To_Address__c = billToAddress.Id;
                orderToBeCreated.BillingStreet = billToAddress.Address_Line_1__c;
                orderToBeCreated.BillingCity = billToAddress.City__c;
                orderToBeCreated.BillingState = billToAddress.State__c;
                orderToBeCreated.BillingPostalCode = billToAddress.Postal_Code__c;
                orderToBeCreated.BillingCountry = billToAddress.Country__c;
            }
			//Add the order to the list that will be used to create the Orders
			ordersToAdd.add(orderToBeCreated);
			//Prepare the order reference
			Order orderRef = new Order(External_Id__c = externalIdValue);
			//Associate the Order referece to the Opportunity		
			currOppty.Associated_Order__r = orderRef;
			//Create the Order lines corresponding to the Opportunity lines
			for(OpportunityLineItem oli : oppLinesList)
			{
				//Make entries based on what is there on the Opportunity and not overwrite with book entries
				OrderItem orderItemToBeCreated = new OrderItem ();
				orderItemToBeCreated.Order = orderRef;
				orderItemToBeCreated.PricebookEntryId = oli.PricebookEntryId;
				orderItemToBeCreated.Quantity = oli.Quantity;
				orderItemToBeCreated.UnitPrice = oli.UnitPrice;
				orderItemsToAdd.add(orderItemToBeCreated);
				//If the Opp lines have the SSIP details filled in then the SSIP Rules should be created for each Opportunity lines
				if((oli.Repeat_Quantity__c != null && oli.Repeat_Quantity__c > 0 && oli.Repeat_after_in_Days__c != null && oli.Repeat_after_in_Days__c > 0))
				{
					//Make entries to SSIP Rule when the Repeat fields are filled in
					SSIP_Rule__c ssipRuleToBeCreated = new SSIP_Rule__c();
                    ssipRuleToBeCreated.Account__c = accountId;
                    ssipRuleToBeCreated.Country__c = 'Austria';
                    ssipRuleToBeCreated.CurrencyIsoCode = 'EUR';
                    ssipRuleToBeCreated.Frequency_In_Days__c = oli.Repeat_after_in_Days__c;
                    ssipRuleToBeCreated.Payment_Term__c = 'net30';
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