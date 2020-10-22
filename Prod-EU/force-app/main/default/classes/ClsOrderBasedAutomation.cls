public class ClsOrderBasedAutomation {
    public static void createFutureOrderAndSSIPRules(List<Order> ordList) {
        // TO DO
        // Create New Order including Line Items based on the Target Price Book and Add SSIP Rules 
        //Id gbOppRecordtypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('GB_Sales_Order').getRecordTypeId();
		//Id ieOppRecordtypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('IE_Sales_Order').getRecordTypeId();
		List<Order> OrderToAdd = new List<Order>();
        Set<ID> ordAccSet = new Set<Id>();
        Set<ID> pbUsedIdSet = new Set<Id>();
        List<Order> ordersToAdd = new List<Order>();
        List<OrderItem> oiList = new List<OrderItem>();
        List<SSIP_Rule__c> ssipRuleList = new List<SSIP_Rule__c>();
		Map<String, Id> futurePBMap = new Map<String, Id>();
		Map<Id, Id> curToFutPBMap = new Map<Id, Id>();
        for(Order o : ordList) {ordAccSet.add(o.AccountId); pbUsedIdSet.add(o.Pricebook2Id); }
        Map<Id, Account> accMap = new Map<Id, Account>([Select Id, Name, Territory__c, Medical_Facility__c, Payor__c, Prescriber__c, Country__c, CurrencyIsoCode from Account where id in :ordAccSet ]);
        Map<Id, Account> ordToActMap = new Map<Id, Account>();
        Map<Id, PriceBook2> currentPBMap = new Map<Id, PriceBook2>([Select Id, Future_Order_Gap__c, Future_Order_Price_Book__c from PriceBook2 where id in :pbUsedIdSet]);
        for(Order o : ordList) ordToActMap.put(o.id, accMap.get(o.AccountId));
        Double diffQty = 0;
        Integer orderLength = 0;
        //id ssipRuleRecTypeId = '';
        Id gbssipRuleRecTypeId = Schema.SObjectType.SSIP_Rule__c.getRecordTypeInfosByDeveloperName().get('GB_SSIP_Rule').getRecordTypeId();
		Id iessipRuleRecTypeId = Schema.SObjectType.SSIP_Rule__c.getRecordTypeInfosByDeveloperName().get('IE_SSIP_Rule').getRecordTypeId();
        
        //****************Logic to map from Price Book's Opp Use Price Book Name to real Price Book Id *************** BEGIN ***************
        //List<PriceBook2> currentPBList = [Select Id, Future_Order_Gap__c, Future_Order_Price_Book__c from PriceBook2 where id in :pbUsedIdSet];
        Set<String> toBeUsedPriceBooksSet = new Set<String>();
        for(PriceBook2 pb : currentPBMap.values()){
            toBeUsedPriceBooksSet.add(pb.Future_Order_Price_Book__c);
        }
		if(!toBeUsedPriceBooksSet.isEmpty()){
			List<PriceBook2> toBeUsedPriceBooksList = [Select Id, Name from PriceBook2 where Name in :toBeUsedPriceBooksSet];
            for(PriceBook2 pb : toBeUsedPriceBooksList) {
                futurePBMap.put(pb.Name, pb.Id);
            }
			for(PriceBook2 curPB : currentPBMap.values()) {
				if (futurePBMap.containsKey(curPB.Future_Order_Price_Book__c)) 
                    
                    curToFutPBMap.put(curPB.Id, futurePBMap.get(curPB.Future_Order_Price_Book__c));
			}
		}
        Map<Id, PriceBookEntry> pbeMap = new Map<Id, PriceBookEntry>([Select Id, First_Order_Variation_Qty__c, First_Repeat_Order_Lead_Days__c, UnitPrice, Number_of_Repeat_Orders__c, PriceBook2Id, SSIP_Next_Order_In_Days__c,
                                                                      SSIP_Periodic_Order_Quantity__c, Product2Id, Product2.Name
                                                                      from PriceBookEntry 
                                                                      where PriceBook2.Name in :toBeUsedPriceBooksSet AND Optional_Subscription_Item__c = false]);
        if(!curToFutPBMap.isEmpty()){
            // TO DO
            // 
            // Copy the Current Order except for EffectiveDate - Current Date + Future_Order_Gap__c
            // Line Items are going to be driven from the Price Book
          for(Order o : ordList) {
        	Order orderToBeCreated = new Order();
			orderToBeCreated.AccountId = o.accountId;          
			orderToBeCreated.Customer_Ship_To_Address__c = o.Customer_Ship_To_Address__c; 
			orderToBeCreated.ShippingStreet = o.ShippingStreet;
			orderToBeCreated.ShippingCity = o.ShippingCity;
			orderToBeCreated.ShippingState = o.ShippingState;
			orderToBeCreated.ShippingPostalCode = o.ShippingPostalCode;
			orderToBeCreated.ShippingCountry = o.ShippingCountry;
			orderToBeCreated.OpportunityId = o.OpportunityId;
			orderToBeCreated.Status = 'Draft';
			orderToBeCreated.Price_Book__c =  curToFutPBMap.get(o.PriceBook2Id);  //currOppty.Pricebook2Id;
            orderToBeCreated.Pricebook2Id = curToFutPBMap.get(o.PriceBook2Id);
			orderToBeCreated.EffectiveDate = system.today() + (Integer) currentPBMap.get(o.PriceBook2Id).Future_Order_Gap__c;
            orderToBeCreated.Future_Order__c = true;
			orderToBeCreated.External_Id__c = o.Id + 'Future Order'; //External_Id__c;
			orderToBeCreated.Type = o.type; //'GB STANDARD';
			orderToBeCreated.CurrencyIsoCode = o.CurrencyIsoCode; // 'GBP';
            orderToBeCreated.Tax_Exempt__c = o.Tax_Exempt__c; // paymentTermsMap.get(accountId).Tax_Exempt__c;
			/* If (String.isNotBlank(paymentTermsMap.get(accountId).Tax_Registration_Number__c)) */ orderToBeCreated.Tax_Registration_Number__c = o.Tax_Registration_Number__c; //paymentTermsMap.get(accountId).Tax_Registration_Number__c;			           
            /* If (String.isNotBlank(paymentTermsMap.get(accountId).Payment_Terms__c)) */ orderToBeCreated.Payment_Terms__c = o.Payment_Terms__c; // paymentTermsMap.get(accountId).Payment_Terms__c;
			orderToBeCreated.RecordTypeId = o.RecordTypeId;
			orderToBeCreated.Fund__c = o.Fund__c;
            //orderToBeCreated.PONumber = currOppty.Fund__c != null ? currOppty.Fund__r.PO_Reference_Number__c : null;
            orderToBeCreated.PONumber = o.PONumber;
            //Add the Payor and Payor's Primary Bill to Address to the Order
            if (o.Payor__c != null) {
                orderToBeCreated.Payor__c = o.Payor__c;
                //if (payorAddMap.containsKey(currOppty.Payor__c)) {
                    orderToBeCreated.Payor_Bill_To_Address__c = o.Payor_Bill_To_Address__c; // payorAddMap.get(currOppty.Payor__c).id;
                    orderToBeCreated.BillingStreet = o.BillingStreet; // payorAddMap.get(currOppty.Payor__c).Address_Line_1__c;
                    orderToBeCreated.BillingCity = o.BillingCity; // payorAddMap.get(currOppty.Payor__c).City__c;
                    orderToBeCreated.BillingState = o.BillingState; //payorAddMap.get(currOppty.Payor__c).State__c;
                    orderToBeCreated.BillingPostalCode = o.BillingPostalCode; // payorAddMap.get(currOppty.Payor__c).Postal_Code__c;
                    orderToBeCreated.BillingCountry = o.BillingCountry; // payorAddMap.get(currOppty.Payor__c).Country__c;
                    //if (String.isnotBlank(payorAddMap.get(currOppty.Payor__c).Account__r.Payment_Terms__c)) orderToBeCreated.Payment_Terms__c = payorAddMap.get(currOppty.Payor__c).Account__r.Payment_Terms__c;
                    	//else orderToBeCreated.Payment_Terms__c = 'net30';
                    orderToBeCreated.Payment_Terms__c = o.Payment_Terms__c;
                // }
            } else {
                // if (o.billToAddress == null || String.isBlank(o.billToAddress.Id)) return 'No Primary Bill To Address is present for this User. Please add it on the Account and Retry.';
                orderToBeCreated.Customer_Bill_To_Address__c = o.Customer_Bill_To_Address__c; //billToAddress.Id;
                orderToBeCreated.BillingStreet = o.BillingStreet; // billToAddress.Address_Line_1__c;
                orderToBeCreated.BillingCity = o.BillingCity; // billToAddress.City__c;
                orderToBeCreated.BillingState = o.BillingState; // billToAddress.State__c;
                orderToBeCreated.BillingPostalCode = o.BillingPostalCode; // billToAddress.Postal_Code__c;
                orderToBeCreated.BillingCountry = o.BillingCountry; //billToAddress.Country__c;
            }
            
            //if (orderToBeCreated.Payment_Terms__c == 'net0' && currOppty.Account.Primary_Card_Last_4__c == 0) {
                // currOppty.addError('No Primary Credit Card is present for this User. Please add it on the Account and Retry.'); 
                //return 'No Primary Credit Card is present for this User. Please add it on the Account and Retry.'; 
            //}
			//Add the order to the list that will be used to create the Orders
			ordersToAdd.add(orderToBeCreated);
			//Prepare the order reference
			Order orderRef = new Order(External_Id__c = o.Id + 'Future Order');
			//Associate the Order reference to the Opportunity		
			//currOppty.Associated_Order__r = orderRef;

			//Create the Order lines corresponding to the Opportunity lines
			for(PriceBookEntry pbe : pbeMap.values()) {
                if (pbe.PriceBook2id != curToFutPBMap.get(o.Pricebook2Id)) continue;
                if (pbe.First_Order_Variation_Qty__c == null) diffQty = 0; else diffQty = pbe.First_Order_Variation_Qty__c;
                if ((pbe.SSIP_Periodic_Order_Quantity__c + diffQty) != 0) {
                    OrderItem oi = new OrderItem();
                    oi.Order = orderRef;
                    oi.PricebookEntryId = pbe.Id;
                    // if (pbe.First_Order_Variation_Qty__c == null) diffQty = 0; else diffQty = pbe.First_Order_Variation_Qty__c;
                    oi.Quantity = pbe.SSIP_Periodic_Order_Quantity__c + diffQty;
                    oi.UnitPrice = pbe.UnitPrice;
                    oi.Order_Item_Added_by_Admin__c = true;
                    oiList.add(oi);
                }
       		// }
             
				//If the Opp lines have the SSIP details filled in then the SSIP Rules should be created for each Opportunity lines
				if((pbe.SSIP_Periodic_Order_Quantity__c != null && pbe.SSIP_Periodic_Order_Quantity__c > 0 && pbe.SSIP_Next_Order_In_Days__c != null && pbe.SSIP_Next_Order_In_Days__c > 0))
				{
					//Make entries to SSIP Rule when the Repeat fields are filled in
					SSIP_Rule__c ssipRuleToBeCreated = new SSIP_Rule__c();
                    ssipRuleToBeCreated.Account__c = o.accountId;
                    ssipRuleToBeCreated.Country__c = o.Type.StartsWithIgnoreCase('IE') ? 'Ireland' : 'United Kingdom';
                    ssipRuleToBeCreated.CurrencyIsoCode = o.Type.StartsWithIgnoreCase('IE') ? 'EUR' : 'GBP';
                    ssipRuleToBeCreated.Frequency_In_Days__c = pbe.SSIP_Next_Order_In_Days__c;
                    ssipRuleToBeCreated.Payment_Term__c = orderToBeCreated.Payment_Terms__c; // 'net30';
                    //If (String.isNotBlank(paymentTermsMap.get(accountId).Payment_Terms__c)) ssipRuleToBeCreated.Payment_Term__c = paymentTermsMap.get(accountId).Payment_Terms__c;
                    ssipRuleToBeCreated.Price_Book__c = pbe.PriceBook2Id;
                    ssipRuleToBeCreated.Product__c = pbe.Product2Id;
                    ssipRuleToBeCreated.Product_Name__c = pbe.Product2.Name;                    
                    ssipRuleToBeCreated.First_Order__r = orderRef;
                    ssipRuleToBeCreated.Quantity__c = pbe.SSIP_Periodic_Order_Quantity__c;
                    ssipRuleToBeCreated.RecordTypeId = o.Type.StartsWithIgnoreCase('IE') ? iessipRuleRecTypeId : gbssipRuleRecTypeId; // ssipRuleRecTypeId;
                    ssipRuleToBeCreated.Rule_Start_Date__c = system.date.today();
                    //ssipRuleToBeCreated.Rule_End_Date__c = oli.Repeat_End_Date__c;
                    ssipRuleToBeCreated.PriceBookEntryId__c = pbe.Id;
                    ssipRuleToBeCreated.First_Repeat_Order_Lead_Days__c = pbe.First_Repeat_Order_Lead_Days__c;
                    ssipRuleToBeCreated.Status__c = 'Active';
                    
                    if (pbe.Number_of_Repeat_Orders__c != null && pbe.Number_of_Repeat_Orders__c > 0) {
                         orderLength =Integer.valueOf((pbe.Number_of_Repeat_Orders__c * pbe.SSIP_Next_Order_In_Days__c) - pbe.First_Repeat_Order_Lead_Days__c + 1 + currentPBMap.get(o.PriceBook2Id).Future_Order_Gap__c );
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
                //return result;
            }
        }
		
		//Insert Order lines Records
        if (oiList.size() > 0) {
			string result;
            try { insert oiList;
                } catch (DmlException de) {
                if(de.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) result = de.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').substringBefore('[');
                //return result;
            }
        }
		
		//Insert SSIP Rule Records
        if (ssipRuleList.size() > 0) {
			string result;
            try { insert ssipRuleList;
                } catch (DmlException de) {
                    if(de.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) result = de.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').substringBefore('[');
                    if(de.getMessage().contains('DUPLICATES_DETECTED')) result = 'SSIP Rule for the same Product already exist, only one rule can be active for a Product.';
//                    return result;
                }
        }
		//return 'OK';
	
      }
    }
}