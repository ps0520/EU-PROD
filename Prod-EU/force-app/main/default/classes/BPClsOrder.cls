/****************************************************************************************************************
	@Author         : Shailendra Singh Lodhi
	@Date Created   : 5/22/2019
	@Description    : Creating class for process builder relatd to Order object
	****************************************************************************************************************/
	global class BPClsOrder {
		public static Map<Id, Order> updateAddressOnOrder(List<Order> lstOrder, Map<Id, Order> mapOrderOld, Map<Id, Order> mapOrderToUpdate, Map<Id, Order> mapOrder, Map<String, BP_Process_Builder_Customization__c> mapCustomization){
			system.debug('*****Entering the process to update address on Order');
			Map<String, List<Order>> mapAccountTolstOrder = new Map<String, List<Order>>();
			Map<Id, List<Order>> mapAddressToLstOrder = new Map<Id,List<Order>>();
			Set<Id> setAccountIdToFetchAddress = new Set<Id>();
			Set<String> setAddressType = new Set<String>();
			Set<Id> setAddress = new Set<Id>();
			Map<Id, String> accntIdToAddrMap = new Map<Id, String>();
			Map<Id, String> accntIdToEmailMap = new Map<Id, String>();

			//--------------LOGIC TO FIND THE ADDRESS RECORDED IN THE RELATED ACCOUNT OBJECT BETWEEN MED FAC AND PAYOR ASSOCIATION -------------START ----//
			system.debug('*****ENTERING PROCESS TO GET THE RELATIONSHIP ADDRESS');
			Set<Id> accountIds = new Set<Id>();
			for(Order objOrder : lstOrder){
				//For GB and IE Orders, which have Payor association, we need to find out the Related address
				system.debug('******Account Id to process ' + objOrder.AccountId);
                system.debug('******objOrder ' + objOrder);
                system.debug('******Type ' + objOrder.Type);
                system.debug('******Payor__c ' + objOrder.Payor__c);
				if(objOrder.Type != null && (objOrder.Type.startsWithIgnoreCase('GB') || objOrder.Type.startsWithIgnoreCase('IE')) && objOrder.Payor__c != null){
					system.debug('******Account Id to process ' + objOrder.AccountId);
					accountIds.add(objOrder.AccountId);
				}
			}
			if(!accountIds.isEmpty())
			{
				system.debug('*****ACCOUNT FOUND TO PROCESS, SO FURTHER PROCESSING');
				Set<Id> medFacAccountIds = new Set<Id>();
				Set<Id> payorAccountIds = new Set<Id>();
				Set<Id> parentPharmacyAccountIds = new Set<Id>();
				Set<Id> childPharmacyAccountIds = new Set<Id>();

				Map<String, String> accountRelationMap = new Map<String, String>();
				for(Account acc : [SELECT Id, Medical_Facility__c, Payor__c, ParentId, Recordtype.Name FROM Account WHERE Id IN : accountIds])
				{
                    System.debug('**TestCls-acc--'+acc.ParentId);
					String recordTypeName = acc.Recordtype.Name;
                    System.debug('**TestCls-recordTypeName--'+recordTypeName);
					//Concatenate string between the MedFac and Payor for an consumer account
					if(acc.Medical_Facility__c != null && acc.Payor__c != null && recordTypeName.containsIgnoreCase('Consumer')) {
						String concatMedFacPayor = acc.Payor__c + '|' + acc.Medical_Facility__c ;
						system.debug('*******CONCAT STRING IS ' + concatMedFacPayor);
						if(acc.Medical_Facility__c != null ) medFacAccountIds.add(acc.Medical_Facility__c);
						if(acc.Payor__c != null ) payorAccountIds.add(acc.Payor__c);
						accountRelationMap.put(concatMedFacPayor, acc.Id);
					}else	//Concatenate string between the Parent Pharmacy and Child Pharmacy accounts
					if((recordTypeName.containsIgnoreCase('Pharmacy') && acc.ParentId != null )) {
						String concatParentPharChildPhar = acc.ParentId + '|' + acc.Id;
						system.debug('*******CONCAT STRING IS ' + concatParentPharChildPhar);
						if(acc.ParentId != null ) parentPharmacyAccountIds.add(acc.ParentId);
						childPharmacyAccountIds.add(acc.Id);
						accountRelationMap.put(concatParentPharChildPhar, acc.Id);
					}else	//Concatenate string between the Parent Payor and Medfac
					if((recordTypeName.containsIgnoreCase('Facility') && acc.Payor__c != null )) {
						String concatParentPayorChildMedFac = acc.Payor__c + '|' + acc.Id;
						system.debug('*******CONCAT STRING IS ' + concatParentPayorChildMedFac);
						medFacAccountIds.add(acc.Id);
						if(acc.Payor__c != null ) payorAccountIds.add(acc.Payor__c);
						accountRelationMap.put(concatParentPayorChildMedFac, acc.Id);
					}
				}
				if(!accountRelationMap.isEmpty())
				{
					system.debug('*****accountRelationMap FOUND, SO FURTHER PROCESSING');
					//Get all related accounts where the Parent relation is a Payor or Pharmacy
					for(Related_Account__c relAccnt : [SELECT Id, Parent_Account__c, Child_Account__c, Parent_Relation_Type__c, Child_Relation_Type__c, Payor_Billing_Address__c, Preferred_Email__c FROM Related_Account__c WHERE
							(Parent_Account__c IN :payorAccountIds OR Child_Account__c IN :medFacAccountIds) OR
							(Parent_Account__c IN :parentPharmacyAccountIds OR Child_Account__c IN :childPharmacyAccountIds)]) {
						String parentPlusChild = relAccnt.Parent_Account__c+'|'+relAccnt.Child_Account__c;
						if(accountRelationMap.containsKey(parentPlusChild) && (relAccnt.Payor_Billing_Address__c != null || relAccnt.Preferred_Email__c != null)){
							if(relAccnt.Payor_Billing_Address__c != null) accntIdToAddrMap.put(accountRelationMap.get(parentPlusChild), relAccnt.Payor_Billing_Address__c);
							if(relAccnt.Preferred_Email__c != null) accntIdToEmailMap.put(accountRelationMap.get(parentPlusChild), relAccnt.Preferred_Email__c);
							system.debug('*******RELATIONSHIP ADDRESS EXIST ' + relAccnt.Payor_Billing_Address__c);
						}
					}
				}
			}
			//--------------LOGIC TO FIND THE ADDRESS RECORDED IN THE RELATED ACCOUNT OBJECT BETWEEN MED FAC AND PAYOR ASSOCIATION -------------END ----//
			for(Order objOrder : lstOrder){
				//Logic for update Bill to Address..
				//If there is no address or payor information populated then just take the customers bill to
				if(Trigger.isInsert && objOrder.Type != null && objOrder.Parent_Order__c == null && objOrder.OpportunityId == null && objOrder.Customer_Bill_To_Address__c == null && objOrder.Payor__c == null){
					system.debug('*****Order without any payor or billing address');
					setAccountIdToFetchAddress.add(objOrder.AccountId);
					setAddressType.add('Bill To');
					String key = objOrder.AccountId + 'BillTo';
					if(!mapAccountTolstOrder.containsKey(key)) mapAccountTolstOrder.put(key, new List<Order>());
					mapAccountTolstOrder.get(key).add(objOrder);
				}else
				if(Trigger.isInsert && objOrder.Payor__c != null && objOrder.Payor_Bill_To_Address__c == null && objOrder.Customer_Bill_To_Address__c == null){//If Order has Payor but no billing information
					system.debug('*****Order with Payor but without any billing address');
					if(!accntIdToAddrMap.isEmpty() && accntIdToAddrMap.containsKey(objOrder.AccountId)){
						if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
						mapOrderToUpdate.get(objOrder.Id).Payor_Bill_To_Address__c = accntIdToAddrMap.get(objOrder.AccountId);
						setAddress.add(accntIdToAddrMap.get(objOrder.AccountId));
					}else{
						setAccountIdToFetchAddress.add(objOrder.Payor__c);
						setAddressType.add('Bill To');
						String key = objOrder.Payor__c + 'BillTo';
						if(!mapAccountTolstOrder.containsKey(key)) mapAccountTolstOrder.put(key, new List<Order>());
						mapAccountTolstOrder.get(key).add(objOrder);
					}
					if(!accntIdToEmailMap.isEmpty() && accntIdToEmailMap.containsKey(objOrder.AccountId)){
						if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
						mapOrderToUpdate.get(objOrder.Id).Invoice_Email__c = accntIdToEmailMap.get(objOrder.AccountId);
					}
				}else
				if((Trigger.isInsert && objOrder.Customer_Bill_To_Address__c != null) || (Trigger.isUpdate && objOrder.Customer_Bill_To_Address__c != mapOrderOld.get(objOrder.Id).Customer_Bill_To_Address__c)){//If the customer bill to address populated or changed
					system.debug('*****Order with customer Billing address');
					setAddress.add(objOrder.Customer_Bill_To_Address__c);
				}
				else
				if((Trigger.isInsert && objOrder.Payor_Bill_To_Address__c != null) || (Trigger.isUpdate && objOrder.Payor_Bill_To_Address__c != mapOrderOld.get(objOrder.Id).Payor_Bill_To_Address__c)){//If the payor bill to address populated or changed
					system.debug('*****Order with Payor billing address');
					setAddress.add(objOrder.Payor_Bill_To_Address__c);
				}

				 //Logic for update Ship to Address..
				if(Trigger.isInsert && objOrder.Type != null  && objOrder.Parent_Order__c == null && objOrder.OpportunityId == null && objOrder.Customer_Ship_To_Address__c == null){
					system.debug('*****Order without any shipping address');
					setAccountIdToFetchAddress.add(objOrder.AccountId);
					setAddressType.add('Ship To');
					String key = objOrder.AccountId + 'ShipTo';
					if(!mapAccountTolstOrder.containsKey(key)) mapAccountTolstOrder.put(key, new List<Order>());
					mapAccountTolstOrder.get(key).add(objOrder);
				}
				else
				if((Trigger.isInsert && objOrder.Customer_Ship_To_Address__c  != null) || (Trigger.isUpdate && objOrder.Customer_Ship_To_Address__c != mapOrderOld.get(objOrder.Id).Customer_Ship_To_Address__c)){//If there is ship to address tied to the Order
					system.debug('*****Order with shipping address');
					setAddress.add(objOrder.Customer_Ship_To_Address__c);
				}
			}
			if(!setAccountIdToFetchAddress.isEmpty()){
				for(Address__c address : [SELECT Id, Account__c, Type__c, Address_Line_1__c, City__c, Country__c, Postal_Code__c, State__c FROM Address__c WHERE Account__c IN: setAccountIdToFetchAddress AND Type__c IN: setAddressType AND Primary_Flag__c = true]){
					String key = address.Account__c + (address.Type__c == 'Bill To' ? 'BillTo' : 'ShipTo');
					if(!mapAccountTolstOrder.containsKey(key)) continue;
					for(Order objOrder : mapAccountTolstOrder.get(key)){
						system.debug('*****Entering the process to update the address id and address fields');
						if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
						if(address.Type__c == 'Bill To'){
							system.debug('*****Entering the process to set correct billing address id');
							if(objOrder.Payor__c == address.Account__c)//If the address is tied to the payor then update the payor bill to address id else update customer bill to address id
								mapOrderToUpdate.get(objOrder.Id).Payor_Bill_To_Address__c = address.Id;
							else
								mapOrderToUpdate.get(objOrder.Id).Customer_Bill_To_Address__c = address.Id;
							mapOrderToUpdate.get(objOrder.Id).BillingStreet = address.Address_Line_1__c;
							mapOrderToUpdate.get(objOrder.Id).BillingCity = address.City__c;
							mapOrderToUpdate.get(objOrder.Id).BillingPostalCode = address.Postal_Code__c;
							mapOrderToUpdate.get(objOrder.Id).BillingState = address.State__c != 'None' && address.State__c != 'none' ? address.State__c : null;
							mapOrderToUpdate.get(objOrder.Id).BillingCountry = address.Country__c != 'None' && address.Country__c != 'none' ? address.Country__c : null;
						}else {
							mapOrderToUpdate.get(objOrder.Id).Customer_Ship_To_Address__c = address.Id;
							mapOrderToUpdate.get(objOrder.Id).ShippingStreet = address.Address_Line_1__c;
							mapOrderToUpdate.get(objOrder.Id).ShippingCity = address.City__c;
							mapOrderToUpdate.get(objOrder.Id).ShippingPostalCode = address.Postal_Code__c;
							mapOrderToUpdate.get(objOrder.Id).ShippingState = address.State__c != 'None' && address.State__c != 'none' ? address.State__c : null;
							mapOrderToUpdate.get(objOrder.Id).ShippingCountry = address.Country__c != 'None' && address.Country__c != 'none' ? address.Country__c : null;
						}
					}
				}
			}
			if(!setAddress.isEmpty()){
				Map<Id, Address__c> mapAddress = new Map<Id, Address__c>([SELECT Id, Address_Line_1__c, City__c, Country__c, Postal_Code__c, State__c FROM Address__c WHERE Id IN: setAddress]);
				if(!mapAddress.isEmpty()){
					for(Order objOrder : lstOrder){
						if(mapAddress.containsKey(objOrder.Customer_Ship_To_Address__c)){
							if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
							mapOrderToUpdate.get(objOrder.Id).ShippingStreet = mapAddress.get(objOrder.Customer_Ship_To_Address__c).Address_Line_1__c;
							mapOrderToUpdate.get(objOrder.Id).ShippingCity = mapAddress.get(objOrder.Customer_Ship_To_Address__c).City__c;
							mapOrderToUpdate.get(objOrder.Id).ShippingPostalCode = mapAddress.get(objOrder.Customer_Ship_To_Address__c).Postal_Code__c;
							mapOrderToUpdate.get(objOrder.Id).ShippingState = mapAddress.get(objOrder.Customer_Ship_To_Address__c).State__c != 'None' && mapAddress.get(objOrder.Customer_Ship_To_Address__c).State__c != 'none' ?   mapAddress.get(objOrder.Customer_Ship_To_Address__c).State__c : null;
							mapOrderToUpdate.get(objOrder.Id).ShippingCountry = mapAddress.get(objOrder.Customer_Ship_To_Address__c).Country__c != 'None' && mapAddress.get(objOrder.Customer_Ship_To_Address__c).Country__c != 'none' ? mapAddress.get(objOrder.Customer_Ship_To_Address__c).Country__c : null;
						}

						if(mapAddress.containsKey(objOrder.Customer_Bill_To_Address__c)){
							if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
							mapOrderToUpdate.get(objOrder.Id).BillingStreet = mapAddress.get(objOrder.Customer_Bill_To_Address__c).Address_Line_1__c;
							mapOrderToUpdate.get(objOrder.Id).BillingCity = mapAddress.get(objOrder.Customer_Bill_To_Address__c).City__c != 'None' && mapAddress.get(objOrder.Customer_Bill_To_Address__c).City__c != 'none' ? mapAddress.get(objOrder.Customer_Bill_To_Address__c).City__c : null;
							mapOrderToUpdate.get(objOrder.Id).BillingPostalCode = mapAddress.get(objOrder.Customer_Bill_To_Address__c).Postal_Code__c;
							mapOrderToUpdate.get(objOrder.Id).BillingState = mapAddress.get(objOrder.Customer_Bill_To_Address__c).State__c != 'None' && mapAddress.get(objOrder.Customer_Bill_To_Address__c).State__c != 'none' ? mapAddress.get(objOrder.Customer_Bill_To_Address__c).State__c : null;
							mapOrderToUpdate.get(objOrder.Id).BillingCountry = mapAddress.get(objOrder.Customer_Bill_To_Address__c).Country__c != 'None' && mapAddress.get(objOrder.Customer_Bill_To_Address__c).Country__c != 'none' ? mapAddress.get(objOrder.Customer_Bill_To_Address__c).Country__c : null;
						}
						if(mapAddress.containsKey(objOrder.Payor_Bill_To_Address__c)){
							if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
							mapOrderToUpdate.get(objOrder.Id).BillingStreet = mapAddress.get(objOrder.Payor_Bill_To_Address__c).Address_Line_1__c;
							mapOrderToUpdate.get(objOrder.Id).BillingCity = mapAddress.get(objOrder.Payor_Bill_To_Address__c).City__c != 'None' &&  mapAddress.get(objOrder.Payor_Bill_To_Address__c).City__c != 'none' ? mapAddress.get(objOrder.Payor_Bill_To_Address__c).City__c : null;
							mapOrderToUpdate.get(objOrder.Id).BillingPostalCode = mapAddress.get(objOrder.Payor_Bill_To_Address__c).Postal_Code__c;
							mapOrderToUpdate.get(objOrder.Id).BillingState = mapAddress.get(objOrder.Payor_Bill_To_Address__c).State__c != 'None' && mapAddress.get(objOrder.Payor_Bill_To_Address__c).State__c != 'none' ? mapAddress.get(objOrder.Payor_Bill_To_Address__c).State__c : null;
							mapOrderToUpdate.get(objOrder.Id).BillingCountry = mapAddress.get(objOrder.Payor_Bill_To_Address__c).Country__c != 'None' && mapAddress.get(objOrder.Payor_Bill_To_Address__c).Country__c != 'none' ? mapAddress.get(objOrder.Payor_Bill_To_Address__c).Country__c : null;

						}

						if(mapOrderToUpdate.containsKey(objOrder.Id) && mapOrderToUpdate.get(objOrder.Id).Payor_Bill_To_Address__c != null && mapAddress.containsKey(mapOrderToUpdate.get(objOrder.Id).Payor_Bill_To_Address__c)){
							Id payorAddrId = mapOrderToUpdate.get(objOrder.Id).Payor_Bill_To_Address__c;
							mapOrderToUpdate.get(objOrder.Id).BillingStreet = mapAddress.get(payorAddrId).Address_Line_1__c;
							mapOrderToUpdate.get(objOrder.Id).BillingCity = mapAddress.get(payorAddrId).City__c != 'None' &&  mapAddress.get(payorAddrId).City__c != 'none' ? mapAddress.get(payorAddrId).City__c : null;
							mapOrderToUpdate.get(objOrder.Id).BillingPostalCode = mapAddress.get(payorAddrId).Postal_Code__c;
							mapOrderToUpdate.get(objOrder.Id).BillingState = mapAddress.get(payorAddrId).State__c != 'None' && mapAddress.get(payorAddrId).State__c != 'none' ? mapAddress.get(payorAddrId).State__c : null;
							mapOrderToUpdate.get(objOrder.Id).BillingCountry = mapAddress.get(payorAddrId).Country__c != 'None' && mapAddress.get(payorAddrId).Country__c != 'none' ? mapAddress.get(payorAddrId).Country__c : null;

						}
					}
				}
			}
			return mapOrderToUpdate;
		}
		public static Map<Id, Order> updateOrderAttributes(List<Order> lstOrder, Map<Id, Order> mapOrderOld, Map<Id, Order> mapOrderToUpdate, Map<Id, Order> mapOrder, Map<String, BP_Process_Builder_Customization__c> mapCustomization){
			//If Order has just a Payor and no Pricebook associated then associate the Primary Payor from the Payor
			Set<Id> setPayorIds = new Set<Id>();
			Map<Id, Id> payorToPBMap = new Map<Id, Id>();
			for(Order objOrder : lstOrder){
				if(objOrder.Price_Book__c == null && objOrder.PriceBook2Id == null && objOrder.Payor__c != null){
					setPayorIds.add(objOrder.Payor__c);
				}
			}
			if(!setPayorIds.isEmpty()){
				for(Account acc : [SELECT Id, Price_Book__c FROM Account Where Id IN : setPayorIds])
					payorToPBMap.put(acc.Id, acc.Price_Book__c);
			}
			for(Order objOrder : lstOrder){
				BP_Process_Builder_Customization__c customization = mapCustomization.containsKey(mapOrder.get(objOrder.Id).RecordType.DeveloperName) ? mapCustomization.get(mapOrder.get(objOrder.Id).RecordType.DeveloperName) : new BP_Process_Builder_Customization__c();
				if(Trigger.isInsert){
					system.debug('----Enter insert operation ---');
					if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
					mapOrderToUpdate.get(objOrder.Id).Territory_Aligned_To_Customer__c = mapOrder.get(objOrder.Id).Account.Territory__c;
					//Logic to populate if Order just has Payor, but no Pricebook
					if(objOrder.Price_Book__c == null && objOrder.PriceBook2Id == null && objOrder.Payor__c != null && payorToPBMap != null){
						mapOrderToUpdate.get(objOrder.Id).PriceBook2Id = payorToPBMap.get(objOrder.Payor__c);
						mapOrderToUpdate.get(objOrder.Id).Price_Book__c = payorToPBMap.get(objOrder.Payor__c);
					}
				}
				if(payorToPBMap.isEmpty()){
					//need to check this again...
					if(objOrder.Type != null && objOrder.Type.startsWith('DE TECH') && objOrder.Price_Book__c == null && mapOrder.get(objOrder.Id).Count_of_Order_Line_Items__c == 0){
						if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
						mapOrderToUpdate.get(objOrder.Id).Price_Book__c = customization.PriceBook__c;
						mapOrderToUpdate.get(objOrder.Id).PriceBook2Id = customization.PriceBook__c;
					}else if(objOrder.Type != null && !objOrder.Type.startsWith('DE TECH') && objOrder.Price_Book__c != null && mapOrder.get(objOrder.Id).Count_of_Order_Line_Items__c == 0 && (Trigger.isInsert ||(Trigger.isUpdate && objOrder.Price_Book__c != mapOrderOld.get(objOrder.Id).Price_Book__c))){
						if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
						mapOrderToUpdate.get(objOrder.Id).PriceBook2Id = objOrder.Price_Book__c;
					}else if( objOrder.Type != null && !objOrder.Type.startsWith('DE TECH') && objOrder.PriceBook2Id != null && mapOrder.get(objOrder.Id).Count_of_Order_Line_Items__c == 0 && (Trigger.isInsert ||(Trigger.isUpdate && objOrder.PriceBook2Id != mapOrderOld.get(objOrder.Id).PriceBook2Id))){
						if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
						mapOrderToUpdate.get(objOrder.Id).Price_Book__c = objOrder.PriceBook2Id;
					}
				}
			}
			return mapOrderToUpdate;
		}
		public static Map<Id, Order> mcOrderEmails(List<Order> lstOrder, Map<Id, Order> mapOrderOld, Map<Id, Order> mapOrderToUpdate, Map<Id, Order> mapOrder, Map<String, BP_Process_Builder_Customization__c> mapCustomization){
			List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
			List<Task> lstTask = new List<Task>();
			List<OrgWideEmailAddress> lstOWEA = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'de.info@dexcom.com' LIMIT 1];
			Map<String, EmailTemplate> mapEmailTemplate = new Map<String, EmailTemplate>();
			for(EmailTemplate emailTempt : [SELECT Id, DeveloperName FROM EmailTemplate WHERE (DeveloperName ='Order_Status_Open_moving_out_of_Order_Fulfillment' OR DeveloperName ='Order_Delivery_Note_Received')]){
				mapEmailTemplate.put(emailTempt.DeveloperName, emailTempt);
			}
            for(Order objOrder : lstOrder){                
				if(Trigger.isUpdate && objOrder.Consumer_Email__c != mapOrder.get(objOrder.Id).Account.PersonEmail && objOrder.Status != mapOrderOld.get(objOrder.Id).Status && objOrder.Type == 'DE STANDARD'
					&& (objOrder.Status == 'Open' || objOrder.Status == 'On-Hold') && !mapOrder.get(objOrder.Id).Account.PersonHasOptedOutOfEmail && mapOrder.get(objOrder.Id).Account.IsPersonAccount && mapOrder.get(objOrder.Id).Account.RecordType.Name == 'DE Consumer'){
					if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
					mapOrderToUpdate.get(objOrder.Id).Consumer_Email__c = mapOrder.get(objOrder.Id).Account.PersonEmail;
				}

				if(Trigger.isUpdate && objOrder.OpportunityId != null && (objOrder.Status == 'Open' || objOrder.Status == 'On-Hold') && !mapOrder.get(objOrder.Id).Opportunity.Cash_Pay__c
					&& mapOrder.get(objOrder.Id).Opportunity.Consumer_Email__c != null && objOrder.Email_Stage__c == null && objOrder.Status != mapOrderOld.get(objOrder.Id).Status && mapOrder.get(objOrder.Id).Opportunity.Type == 'Reorder'
					&& (objOrder.Type != null && objOrder.Type == 'DE STANDARD')  && !mapOrderOld.get(objOrder.Id).Account.PersonHasOptedOutOfEmail && mapOrder.get(objOrder.Id).Account.IsPersonAccount && mapOrder.get(objOrder.Id).Account.RecordType.Name == 'DE Consumer' && objOrder.Consumer_Email__c != null){
					if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
					mapOrderToUpdate.get(objOrder.Id).Sent_to_Oracle_Date__c = Date.today();
					allmsg.add(prepareEmailMessage(mapEmailTemplate.get('Order_Status_Open_moving_out_of_Order_Fulfillment').Id, objOrder.Consumer_Email__c, objOrder.AccountId, mapOrder.get(objOrder.Id).Account.PersonContactId, 'Dexcom Deutschland informiert:  Ihr Dexcom-Paket ist unterwegs', lstOWEA.isEmpty() ? null : lstOWEA[0].Id));
					String desctn = 'Sehr geehrte/r Herr / Frau '+ mapOrder.get(objOrder.Id).Account.Name + ', ---- Ihre Genehmigung Ihrer Krankenkasse liegt vor. Wir übergeben das Paket nun an unseren Versanddienstleister. ---- Ihre Krankenkasse hat eine Versorgung für den Zeitraum vom '+objOrder.Benefit_Auth_Start_Date__c + ' bis zum' + objOrder.Benefit_Auth_End_Date__c +'genehmigt. '+ '----' + 'Falls Ihr genehmigter Versorgungszeitraum länger als 3 Monate umfasst, versenden wir Ihre Verbrauchsmaterialien in terminierten Teillieferungen.' + '----' + 'Vorab eingereichte Rezepte verlieren ihre gesetzlich festgelegte Gültigkeit.';
					lstTask.add(new Task(ActivityDate = Date.today(), Priority = 'Normal', Status = 'Completed', Subject = 'Dexcom Deutschland informiert:  Ihr Dexcom-Paket ist unterwegs', Type='Dextracker Email', WhoId = mapOrder.get(objOrder.Id).Account.PersonContactId, WhatId = objOrder.Id, Description = desctn));
				}

				if(Trigger.isUpdate && objOrder.Status != mapOrderOld.get(objOrder.Id).Status && (objOrder.Status == 'Open' || objOrder.Status == 'On-Hold') && objOrder.Email_Stage__c == null
					&& (objOrder.Type!= null && objOrder.Type == 'DE STANDARD') && mapOrder.get(objOrder.Id).Account.IsPersonAccount && mapOrder.get(objOrder.Id).Account.RecordType.Name == 'DE Consumer'){
					if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
					mapOrderToUpdate.get(objOrder.Id).Email_Stage__c = 0;
				}else if(Trigger.isInsert && objOrder.Email_Stage__c == 1 && !objOrder.Delivery_Note_Received__c && objOrder.AccountId != null && mapOrder.get(objOrder.Id).Account.IsPersonAccount &&  !mapOrder.get(objOrder.Id).Account.PersonHasOptedOutOfEmail
							&& objOrder.OpportunityId != null && !mapOrder.get(objOrder.Id).Opportunity.Cash_Pay__c && objOrder.Consumer_Email__c == null ){

					if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
					mapOrderToUpdate.get(objOrder.Id).Email_Stage__c = 2;
					mapOrderToUpdate.get(objOrder.Id).Delivery_Note_Printed__c = true;
					String desctn = 'Sehr geehrte/r Herr / Frau ' +mapOrder.get(objOrder.Id).Account.Name+ ', ----' + 'laut unseren Unterlagen ist die Empfangsbestätigung für Ihre Lieferung vom' + objOrder.ActivatedDate + ' noch nicht eingegangen.' + '----' + 'Diese Empfangsbestätigung benötigen wir für Ihre gesetzliche Krankenkasse. Bitte senden Sie uns die Empfangsbestätigung zu. Sollte sich diese Nachricht mit der Zusendung der Empfangsbestätigung überschnitten haben, beachten Sie bitte diese Nachricht als gegenstandslos. '+ '----'+ 'Wenn Ihnen die Empfangsbestätigung nicht mehr vorliegt, senden wir Ihnen diese gerne erneut zu. Senden Sie uns dafür eine E-Mail an de.info@dexcom.com. ';
					lstTask.add(new Task(ActivityDate = Date.today(), Priority = 'Normal', Status = 'Completed', Subject = ' Dexcom Deutschland benötigt Ihre Unterstützung: Zusendung Empfangsbestätigung', Type='Dextracker Email', WhoId = mapOrder.get(objOrder.Id).Account.PersonContactId, WhatId = objOrder.Id, Description = desctn));
					allmsg.add(prepareEmailMessage(mapEmailTemplate.get('Order_Delivery_Note_Received').Id, objOrder.Consumer_Email__c, objOrder.AccountId, mapOrder.get(objOrder.Id).Account.PersonContactId, 'Dexcom Deutschland benötigt Ihre Unterstützung: Zusendung Empfangsbestätigung', lstOWEA.isEmpty() ? null : lstOWEA[0].Id));
				}
			}

			if(!allmsg.isEmpty()){
				Messaging.sendEmail(allmsg, false);
			}
			if(!lstTask.isEmpty()){
				insert lstTask;
			}
			return mapOrderToUpdate;
		}

		@testvisible private static Messaging.SingleEmailMessage prepareEmailMessage(String emailTemplateId, String emailAddress, String whatId, String targetObjectId, String subject, String owdId){
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setTemplateId(emailTemplateId);
			mail.setToAddresses(new List<String>{emailAddress});
			mail.setSubject(subject);
			mail.setTargetObjectId(targetObjectId);
			mail.setWhatId(whatId);
			mail.setSaveAsActivity(false);
			if(String.isNotBlank(owdId) && String.isNotEmpty(owdId)){
				mail.setOrgWideEmailAddressId(owdId);
			}
			return mail;
		}

		public static Map<Id, Order> sdocsJobforWebsiteOrders(List<Order> lstOrder, Map<Id, Order> mapOrderOld, Map<Id, Order> mapOrderToUpdate, Map<Id, Order> mapOrder, Map<String, BP_Process_Builder_Customization__c> mapCustomization){
			System.debug('=======processBuilder=======');
			List<SDJob_Temp__c> lstSDJobTemp = new List<SDJob_Temp__c>();
			for(Order objOrder : lstOrder){
				BP_Process_Builder_Customization__c customization = mapCustomization.containsKey(objOrder.RecordType.DeveloperName) ? mapCustomization.get(objOrder.RecordType.DeveloperName) : new BP_Process_Builder_Customization__c();
				//mapOrder.get(objOrder.Id).Account.PersonEmail.containsIgnoreCase('MADMI')
				System.debug('========='+mapOrder.get(objOrder.Id).CreatedBy.Alias );
				if(mapOrder.get(objOrder.Id).Account.PersonEmail != null && mapOrder.get(objOrder.Id).CreatedBy.Alias == 'MADMI' && objOrder.Web_Order_Confirmation_Status__c == null){
					if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
					mapOrderToUpdate.get(objOrder.Id).Web_Order_Confirmation_Status__c = 'Initiated';
					lstSDJobTemp.add(new SDJob_Temp__c(Doclist__c = customization.Doc_List__c, Sobject_Name__c = 'Order', Sobject_Id__c = objOrder.Id, Create_SDJob__c = false));
				}
			}
			insert lstSDJobTemp;
			System.debug('=======lstSDJobTemp======='+lstSDJobTemp);
			return mapOrderToUpdate;
		}

		public static Map<Id, Order> createAuditRecordsInsuranceOrders(List<Order> lstOrder, Map<Id, Order> mapOrderOld, Map<Id, Order> mapOrderToUpdate, Map<Id, Order> mapOrder, Map<String, BP_Process_Builder_Customization__c> mapCustomization){
			List<Audit_Tracker__c> lstAuditTrail = new List<Audit_Tracker__c>();
			for(Order objOrder : lstOrder){
                //Cash Orders are also supposed to go through QC as per NS-1456. So, commented out Cash Order part from below. Vijay Adusumilli Sept 21, 2020.
				if(mapOrder.get(objOrder.Id).RecordType.DeveloperName == 'DE_Sales_Order' && (objOrder.Type!= null && objOrder.Type == 'DE STANDARD') && !objOrder.Is_Cash_Order__c  && objOrder.Shipping_Hold_Status__c == null){
					if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
					mapOrderToUpdate.get(objOrder.Id).Shipping_Hold_Status__c = 'Not Started';
					lstAuditTrail.addAll(new List<Audit_Tracker__c>{    new Audit_Tracker__c(Audit_Field_Name__c = 'Original Prescription', Field_Verified__c = false, Object_Id__c = objOrder.Id),
																		new Audit_Tracker__c(Audit_Field_Name__c = 'Approval', Field_Verified__c = false, Object_Id__c = objOrder.Id),
																		new Audit_Tracker__c(Audit_Field_Name__c = 'Documents Previous Order', Field_Verified__c = false, Object_Id__c = objOrder.Id),
																		new Audit_Tracker__c(Audit_Field_Name__c = 'Price', Field_Verified__c = false, Object_Id__c = objOrder.Id),
																		new Audit_Tracker__c(Audit_Field_Name__c = 'Payor', Field_Verified__c = false, Object_Id__c = objOrder.Id),
																		new Audit_Tracker__c(Audit_Field_Name__c = 'Products', Field_Verified__c = false, Object_Id__c = objOrder.Id)
																   });
				}
                if(mapOrder.get(objOrder.Id).RecordType.DeveloperName == 'DE_Sales_Order' && (objOrder.Type!= null && objOrder.Type == 'DE STANDARD') && objOrder.Is_Cash_Order__c && objOrder.Shipping_Hold_Status__c == null){
					if(!mapOrderToUpdate.containsKey(objOrder.Id)) mapOrderToUpdate.put(objOrder.Id, new Order(Id = objOrder.Id));
					mapOrderToUpdate.get(objOrder.Id).Shipping_Hold_Status__c = 'Not Started';
					lstAuditTrail.addAll(new List<Audit_Tracker__c>{    new Audit_Tracker__c(Audit_Field_Name__c = 'Payment', Field_Verified__c = false, Object_Id__c = objOrder.Id),
																		new Audit_Tracker__c(Audit_Field_Name__c = 'Order', Field_Verified__c = false, Object_Id__c = objOrder.Id),
																		new Audit_Tracker__c(Audit_Field_Name__c = 'Price', Field_Verified__c = false, Object_Id__c = objOrder.Id),
																		new Audit_Tracker__c(Audit_Field_Name__c = 'Payor', Field_Verified__c = false, Object_Id__c = objOrder.Id),
																		new Audit_Tracker__c(Audit_Field_Name__c = 'Products', Field_Verified__c = false, Object_Id__c = objOrder.Id)
																   });
				}
			}
			insert lstAuditTrail;
			return mapOrderToUpdate;
		}

		public static Map<Id, Order> updateAuditRecordsOnOrderChange(List<Order> lstOrder, Map<Id, Order> mapOrderOld, Map<Id, Order> mapOrderToUpdate, Map<Id, Order> mapOrder, Map<String, BP_Process_Builder_Customization__c> mapCustomization){
			List<Audit_Tracker__c> lstAuditTrail = new List<Audit_Tracker__c>();
			for(Order objOrder : lstOrder){
				if(Trigger.isUpdate && objOrder.Payor__c != mapOrderOld.get(objOrder.Id).Payor__c && mapOrder.get(objOrder.Id).RecordType.DeveloperName == 'DE_Sales_Order' && objOrder.Type == 'DE STANDARD' && !objOrder.Is_Cash_Order__c){
					for(Audit_Tracker__c auditTracker : mapOrder.get(objOrder.Id).Audit_Order__r){
						lstAuditTrail.add(new Audit_Tracker__c(Id = auditTracker.Id, Field_Verified__c = false));
					}
				}
			}
			update lstAuditTrail;
			return mapOrderToUpdate;
		}

		/*public static Map<Id, Order> updateWarehouseForBusingenOrders(List<Order> lstOrder, Map<Id, Order> mapOrderOld, Map<Id, Order> mapOrderToUpdate, Map<Id, Order> mapOrder, Map<String, BP_Process_Builder_Customization__c> mapCustomization){
			//For the Orders that are to be updated, make sure the billing city contains text Büsingen and if so, update the warehouse to HLCH
			for(Order objOrder : mapOrderToUpdate.values()){
				if(objOrder.Billingcity != null) if(objOrder.Billingcity.Contains('Büsingen')) objOrder.Warehouse__c = 'HLCH';
			}
			return mapOrderToUpdate;
		}*/
        
        public static Map<Id, Order> updateDistributorBillToAddress(List<Order> lstOrder, Map<Id, Order> mapOrderOld, Map<Id, Order> mapOrderToUpdate, Map<Id, Order> mapOrder, Map<String, BP_Process_Builder_Customization__c> mapCustomization){
            Set<Id> orderToUpdateSet = new Set<Id>();
            Set<Id> accountSet = new Set<Id>();
            map<Id, Id> orderToAcctMap = new Map<Id, Id>();
            for(Order o : lstOrder) {
                if (o.Type.startsWithIgnoreCase('DIST') && o.Payor__c != null && o.Customer_Bill_To_Address__c == null) { orderToUpdateSet.add(o.Id); accountSet.add(o.AccountId); orderToAcctMap.put(o.Id, o.AccountId);}
            }
            List<Address__c> billToAddressesList = new List<Address__c>();
            Map<Id, Address__C> accountToAddressMap = new Map<Id, Address__c>();
            List<Order> ordersToUpdate = new List<Order>();
            if (accountSet.size() > 0) { 
            	billToAddressesList = [Select Id, Account__c, Type__c, Address_Line_1__c, City__c, Country__c, Postal_Code__c, State__c FROM Address__c WHERE Account__c IN: accountSet AND Type__c = 'BILL TO' AND Primary_Flag__c = true];
                for(Address__c add : billToAddressesList) accountToAddressMap.put(add.Account__c, add);
                for(Id i : orderToUpdateSet) {
                    if(!mapOrderToUpdate.containsKey(i)) mapOrderToUpdate.put(i, new Order(Id = i));
                    mapOrderToUpdate.get(i).Customer_Bill_To_Address__c = accountToAddressMap.get(orderToAcctMap.get(i)).Id;  
                    mapOrderToUpdate.get(i).BillingStreet = accountToAddressMap.get(orderToAcctMap.get(i)).Address_Line_1__c;
                    mapOrderToUpdate.get(i).BillingCity = accountToAddressMap.get(orderToAcctMap.get(i)).City__c;
                    mapOrderToUpdate.get(i).BillingPostalCode = accountToAddressMap.get(orderToAcctMap.get(i)).Postal_Code__c;
                    mapOrderToUpdate.get(i).BillingState = accountToAddressMap.get(orderToAcctMap.get(i)).State__c != 'None' && accountToAddressMap.get(orderToAcctMap.get(i)).State__c != 'none' ? accountToAddressMap.get(orderToAcctMap.get(i)).State__c : null;
                    mapOrderToUpdate.get(i).BillingCountry = accountToAddressMap.get(orderToAcctMap.get(i)).Country__c != 'None' && accountToAddressMap.get(orderToAcctMap.get(i)).Country__c != 'none' ? accountToAddressMap.get(orderToAcctMap.get(i)).Country__c : null;
                }
            }
            return mapOrderToUpdate;
        }
	}