public class ClsCAOpportunityTriggerHandler {
    
    //This method will be called in Before Insert context. The purpose is not to allow insertion on Opportunities on Accounts that have non-Closed Opportunitites.
    public static void doNotAllowMultipleOpenOpps(List<Opportunity> newOppsList) {
        set<ID> newOpsAccIds = new Set<Id>();
        for (Opportunity o : newOppsList) newOpsAccIds.add(o.AccountId);
        List<Opportunity> otherOpenOpps = [Select Id, AccountId from Opportunity where AccountId in :newOpsAccIds AND StageName Not in ('Closed - Complete', 'Cancelled')];
        if (otherOpenOpps.size() < 1) return; // No duplicate Open opps exist.
        Map<Id, Opportunity> existOpps = new Map<Id, Opportunity>();
        for(Opportunity o : otherOpenOpps) existOpps.put(o.AccountId, o);
        for(Opportunity o : newOppsList) {
            if (existOpps.containsKey(o.AccountId)) o.addError('An Open Opportunity with Id: ' + existOpps.get(o.AccountId).Id + ' already exists. Can\'t create a new one.');
        }
    } 
    //Calling the following method in Before Insert or Before Update Trigger Context. It's to Copy the Payor's Name based on the Benefit Payor. 
    public static void setBenfitAndPayor(List<Opportunity> newOppsList) {
        //If there is no Benefit associated with the Opportunity, copy the Primary Beneficiary to the new Opportunity
        if (Trigger.isInsert ) {
            Set<Id> noBenAccountIds = new Set<Id>();
            for (Opportunity o : newOppsList) if (o.Benefit__c == null && o.Parent_Opportunity__c == null ) noBenAccountIds.add(o.AccountId);
            if (noBenAccountIds.size() > 0) {
            	List<Benefit__c> primeBenefits = [Select Id, Account__c from Benefit__c where Account__c in :noBenAccountIds AND Benefit_Hierarchy__c = 'Primary' AND Inactive__c = false];
                Map<Id, Benefit__c> benefitMap = new Map<Id, Benefit__c>();
                for (Benefit__c b : primeBenefits) benefitMap.put(b.Account__c, b);
                for(Opportunity o : newOppsList) {
                    if (o.Benefit__c == null && o.Parent_Opportunity__c == null && benefitMap.containsKey(o.AccountId)) o.Benefit__c = benefitMap.get(o.AccountId).Id;
                }
            }
        }
        Set<ID> benefitIds = new Set<Id>();
        for(Opportunity o : newOppsList) if (o.Benefit__c != null) benefitIds.add(o.Benefit__c);           
		if (benefitIds.size() < 1) return;
        List<Benefit__c> benefitRecs = [Select Id, Payor__c from Benefit__c where id in :benefitIds];
        Map<Id, Benefit__c> benefitMap = new Map<Id, Benefit__c>();
        benefitMap.putAll(benefitRecs);
        for(Opportunity o : newOppsList) {
            if (o.Benefit__c != null) o.Payor__c = benefitMap.get(o.Benefit__c).Payor__c;
        }
        
        
    }
    
    //The following method will be called in after Update context. It's purpose is to create a new opportunity after 'Cancelling' an existing Opportunity.
    public static void createNewOpportunity(List<Opportunity> newOppsList, Map<id, Opportunity> oldOppMap) {
        System.debug('**createNewOpportunity');
        Opportunity oldOpp = new Opportunity();
        Opportunity newOpp = new Opportunity();
        List<Opportunity> newOpps = new List<Opportunity>();
        Set<Id> oppAccIds = new Set<id>();
        for (Opportunity o: newOppsList) oppAccIds.add(o.AccountId);
        List<Account> accountInfo = [Select Id, Name, Territory__c from Account where id in :oppAccIds];
        Map<Id, Account> accountInfoMap = new Map<Id, Account>();
        accountInfoMap.putAll(accountInfo);
        Set<Id> OppsExist = findExistingOpps(newOppsList);
        for(Opportunity o : newOppsList) {
            oldOpp = oldOppMap.get(o.Id);
            if (oldOpp.Create_New_Opportunity__c == false && o.Create_New_Opportunity__c == true && o.StageName == 'Cancelled' && 
                	(oppsExist.size() == 0 || (oppsExist.size()>0 && !oppsExist.contains(o.AccountId)))) {
                   newOpp = new Opportunity();
                		newOpp.Parent_Opportunity__c = o.Id;
                        newOpp.AccountId = o.AccountId;
                        newOpp.CA_Docs_Received__c = o.CA_Docs_Received__c;
                        newOpp.CA_Docs_Sent_Out__c = o.CA_Docs_Sent_Out__c;
                        newOpp.Competitor__c = o.Competitor__c;
                        newOpp.Cash_Pay__c  = o.Cash_Pay__c;
                        newOpp.Medical_Facility__c = o.Medical_Facility__c;
                        newOpp.CurrencyIsoCode = o.CurrencyIsoCode;
                        //newOpp.Name = o.AccountId + String.valueOf(Date.today());
                        newOpp.Name = accountInfoMap.get(o.AccountId).Name + ' - ' + accountInfoMap.get(o.AccountId).Territory__c + ' - ' + String.valueOf(Date.today().month()) + '/' + 
                            String.valueOf(Date.today().day()) + '/' + String.valueOf(Date.today().year());
                        newOpp.OwnerId = o.OwnerId;
                        newOpp.Prescriber__c = o.Prescriber__c;
                       //  system.debug('o.Country__c='+o.Country__c);
                        newOpp.Country__c = o.Country__c;
                        newOpp.Type = o.Type;
                        newOpp.CloseDate = Date.today() + 30;
                        newOpp.RecordTypeId = o.RecordTypeId;
                        newOpp.StageName = 'New Opportunity';
                   newOpps.add(newOpp); 
            }	
        }
        if (newOpps.size() > 0) {
            insert newOpps;
        } 
    }
    private static Set<Id> findExistingOpps(List<Opportunity> newOppsList) {
        Set<Id> accsWithOpenOpps = new Set<Id>();
        //To do
        set<ID> newOpsAccIds = new Set<Id>();
        for (Opportunity o : newOppsList) newOpsAccIds.add(o.AccountId);
        List<Opportunity> otherOpenOpps = [Select Id, AccountId from Opportunity where AccountId in :newOpsAccIds AND StageName Not in ('Closed - Complete', 'Cancelled')];
        if (otherOpenOpps.size() < 1) return accsWithOpenOpps;
        for(Opportunity o : otherOpenOpps) accsWithOpenOpps.add(o.AccountId);
        return accsWithOpenOpps;
    }
    // Method called from ClsOpportunityBPHandler to Update the MedFac & Prescriber on Account if an Opportunity is Closed for Canada. Vijay Adusumilli Sept 5, 2019
    public static void updAccountMedFacPrescriber(List<Opportunity> updAccountOps) {
        set<Id> acIds = new Set<Id>();
        for(Opportunity opp : updAccountOps) acIds.add(opp.AccountId);
        Map<Id, Account> acctToVerifyMap = new Map<Id, Account> ([Select Id, Medical_Facility__c, Prescriber__c from Account where Id in :acIds]);
        List<Account> updAccList = new List<Account>();
        for(Opportunity op : updAccountOps) {
            Account updAcc = new Account(id=op.AccountId);
            if (op.Medical_Facility__c != null && acctToVerifyMap.get(op.AccountId).Medical_Facility__c != op.Medical_Facility__c) updAcc.Medical_Facility__c = op.Medical_Facility__c;
            if (op.Prescriber__c != null && acctToVerifyMap.get(op.AccountId).Prescriber__c != op.Prescriber__c) updAcc.Prescriber__c = op.Prescriber__c;
            updAccList.add(updAcc);
        }
        Update updAccList;
    }
    
    //Create fund for CA
    public Static void createFund(List<Opportunity> newOppsList){ 
        Map<Id, Opportunity> newOppsMap = new Map<Id, Opportunity>(newOppsList);
        List<ID> AccIdList = new List<ID>();
        List<ID> PayorIdList = new List<ID>(); 
        List<Fund__c> FdList = new List<Fund__c>();         
        List<Opportunity> OppList = new List<Opportunity>();       
        List<Account> AcList = new List<Account>();
       // Map<Id, Id> FundPayorMap = new Map<Id, Id>();
        Map<Id, Id> FundAccountMap = new Map<Id, Id>();
        Map<String, Id> MemberIdToFundMap = new Map<String, Id>();
        Set<Id> OppIdSet = new Set<Id>();
        for (Opportunity o : newOppsList) OppIdSet.add(o.Id);
        List<Opportunity> OppDetailsList = [Select Id, AccountId, Payor__c, Benefit__r.Member_Id__c, CA_Insurance_Coverage__c, Benefit_Auth_End_Date__c, Benefit_Auth_Start_Date__c, Fund__c, Account.Fund__c, Benefit_Prior_Auth_Denied_or_Approved__c
                                           from Opportunity where id in :OppIdSet];
        
        for(Opportunity Opp : OppDetailsList) {  
            if (Opp.CA_Insurance_Coverage__c == null || Opp.Benefit_Auth_End_Date__c == null || Opp.Benefit_Auth_Start_Date__c == null || Opp.Payor__c == null || Opp.Benefit_Prior_Auth_Denied_or_Approved__c == null ) {
                newOppsMap.get(opp.Id).addError('Insurance Coverage Approval, Auth Start Date, End Date, Approved Amount and Payor are required to create Fund. Please enter them and retry to create Fund.'); return;
            }
            if(Opp.fund__c == '' || Opp.Fund__c == null)
            {
                if(Opp.Account.fund__c == null)
                {
                    AccIdList.add(Opp.AccountId);
                    PayorIdList.add(Opp.Payor__c);
                }                
                Fund__c Fd = new Fund__c();
                Fd.Country__c = 'Canada';
                Fd.PO_Reference_Number__c = Opp.Benefit__r.Member_Id__c ;           
                Fd.Limit_Type__c ='Amount';        
                Fd.Payor__c = Opp.Payor__c;
                Fd.Amount_Limit__c = Opp.CA_Insurance_Coverage__c;
                Fd.Auth_End_Date__c = Opp.Benefit_Auth_End_Date__c;
                Fd.Auth_Start_Date__c = Opp.Benefit_Auth_Start_Date__c;                  
                FdList.add(Fd);  
            }
        }
        
        if (FdList.size() > 0)
            insert FdList;	       
        for(Fund__c f : FdList) { MemberIdToFundMap.put(f.PO_Reference_Number__c, f.ID);}
        /*
        for(Fund__c fd : [Select id, Payor__c from Fund__c where Payor__c IN :PayorIdList]){
            FundPayorMap.put(fd.Payor__c, fd.id);
        }  
		*/
        for(Opportunity Opp : OppDetailsList) { 
            Opportunity Op = new Opportunity(Id = Opp.id) ;
            Account act = new Account(id=Opp.AccountId, Fund__c = MemberIdToFundMap.get(Opp.Benefit__r.Member_Id__c));
            AcList.add(act);
            Op.Fund__c = MemberIdToFundMap.get(Opp.Benefit__r.Member_Id__c);
            OppList.add(Op);
        }
        if (OppList.size() > 0)
            Update OppList;
        /*
        for(Opportunity op : [Select id, AccountId, Fund__c from Opportunity where AccountId IN :AccIdList]){
            FundAccountMap.put(op.AccountId, op.Fund__c);
        }
        for(Account Ac : [Select id, Fund__c from Account where Id IN :AccIdList]) { 
            Ac.Fund__c = FundAccountMap.get(Ac.Id);
            AcList.add(Ac);
        }
		*/
        if (AcList.size() > 0)
            Update AcList;
        
        
    }
    
    static Set<Id> opptyIdsToProcess = new Set<Id>(); //Set of Opportunities Ids to be processed

	//Method checks if the Opportunity product has a schedule and then it will record the schedule shipments relating to Opportunity
    public static String processOpportunityForScheduleShipments(Map<Id, Opportunity> newTriggerOpportunities, Map<Id, Opportunity> oldTriggerOpportunities){
        
		String returnMsg = 'OK';
		// Avoid Recursion - If this logic was executed during the same context 
        if(ClsOpportunityTriggerStaticClass.isExecuting)
            return returnMsg;
        ClsOpportunityTriggerStaticClass.isExecuting = true;
        
        system.debug('----Entering Process to find Opportunity for processing');
        for(Opportunity newOppty : newTriggerOpportunities.values()) {
            Opportunity oldOppty = oldTriggerOpportunities.get(newOppty.Id);
            if((newOppty.Ordering_Process__c == 'Local' || newOppty.Ordering_Process__c == 'Payor') && ((oldOppty.StageName != newOppty.StageName) && newOppty.StageName == 'Order Fulfillment')){
               opptyIdsToProcess.add(newOppty.Id);
               system.debug('opptyIdsToProcess'+ opptyIdsToProcess);
            }
        }       
		//Process opportunity records for scheduled shipments
		if(opptyIdsToProcess != null) returnMsg = processOpportunityRecords();
		return returnMsg;
    }
    
    public static String processOpportunityRecords(){
        system.debug('----Entering Process to Process Opportunity records');
        Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity>();//Create a map between Opportunity Id and Opportunity record
		Map<Id, List<OpportunityLineItem>> oppToLinesMap = new Map<Id, List<OpportunityLineItem>>();//Map holds the reference between an Opp Id to its lines
        List<Order> ordersToAdd = new List<Order>();//Order records to be added
		List<OrderItem> orderItemsToAdd = new List<OrderItem>();//Order item records to be added
		List<SSIP_Rule__c> ssipRuleList = new List<SSIP_Rule__c>();//SSIP Rules List will be used to create the SSIP Rule
        Set<Id> accountIdSet = new Set<Id>();//Set of account ids to get the bill to and ship to addr information
        Set<Id> payorIdSet = new Set<Id>();//Set of account ids to get the bill to and ship to addr information
        
		Id orderRecTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('CA Sales Order').getRecordTypeId();
		Id ssipRuleRecTypeId = Schema.SObjectType.SSIP_Rule__c.getRecordTypeInfosByName().get('CA SSIP Rule').getRecordTypeId();
		Set<Id> pbIdSet = new Set<Id>();
        
		//Get the Opportunity and line details to process further
        for(Opportunity oppty : [SELECT Id, AccountId, Account.Primary_Card_Last_4__c, PO_Number__c, Fund__c, Pricebook2Id, Type, Payor__c, Ordering_Process__c, Number_of_Approved_Orders__c, Payment_Terms__c,  (Select OpportunityId, PricebookEntryId, PriceBookEntry.PriceBook2Id, PriceBookEntry.Product2Id, PriceBookEntry.Product2.Name, Quantity, 
                                        UnitPrice, Repeat_after_in_Days__c, Repeat_Quantity__c, Repeat_End_Date__c, First_Repeat_Order_Lead_Days__c FROM OpportunityLineItems) FROM Opportunity WHERE Id IN : opptyIdsToProcess])
        {
            opptyMap.put(oppty.Id, oppty);
			oppToLinesMap.put(oppty.Id, oppty.OpportunityLineItems);
            accountIdSet.add(oppty.AccountId);
            pbIdSet.add(oppty.Pricebook2Id);
            if (oppty.Payor__c != null) payorIdSet.add(oppty.Payor__c);
        }
         //Use the following map to adjust the first order Qty and when to end the rule	
        Map<Id, PriceBookEntry> pbeMap = new Map<Id, PriceBookEntry>([Select Id, First_Order_Variation_Qty__c, First_Order_Variation_Amt__c, Number_of_Repeat_Orders__c, PriceBook2.Subscription_Period_In_Days__c, PriceBook2.IsSubscription__c from PriceBookEntry where Pricebook2Id in :pbIdSet AND Optional_Subscription_Item__c = false]);	
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
            if (currOppty.Payor__c == null && (currOppty.Fund__c != null || currOppty.Ordering_Process__c == 'Payor')) { currOppty.addError('Payor is not known and a Payor Order is required. Please fix it.'); continue; }
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
           // orderToBeCreated.Fund__c = currOppty.Fund__c;
			orderToBeCreated.Status = 'Draft';
			orderToBeCreated.Price_Book__c = currOppty.Pricebook2Id;
			orderToBeCreated.EffectiveDate = system.today(); 
			orderToBeCreated.External_Id__c = externalIdValue;
			orderToBeCreated.Type = 'CA STANDARD';
			orderToBeCreated.CurrencyIsoCode = 'CAD';
			orderToBeCreated.RecordTypeId = orderRecTypeId;
            orderToBeCreated.Tax_Exempt__c = paymentTermsMap.get(accountId).Tax_Exempt__c;
			If (String.isNotBlank(paymentTermsMap.get(accountId).Tax_Registration_Number__c)) orderToBeCreated.Tax_Registration_Number__c = paymentTermsMap.get(accountId).Tax_Registration_Number__c;			                       
            If (String.isNotBlank(paymentTermsMap.get(accountId).Payment_Terms__c)) orderToBeCreated.Payment_Terms__c = paymentTermsMap.get(accountId).Payment_Terms__c;
            if (currOppty.Payment_Terms__c != null ) orderToBeCreated.Payment_Terms__c = currOppty.Payment_Terms__c; // If Payment Terms is set at the Opp level, that value taking precedenc over the Account Level Payment Terms
            orderToBeCreated.Fund__c = currOppty.Fund__c;
            //orderToBeCreated.PONumber = currOppty.Fund__c != null ? currOppty.Fund__r.PO_Reference_Number__c : null;
            orderToBeCreated.PONumber = currOppty.PO_Number__c;
             
            //Add the Payor and Payor's Primary Bill to Address to the Order
            if (currOppty.Payor__c != null && (currOppty.Fund__c != null || currOppty.Ordering_Process__c == 'Payor')) {
                orderToBeCreated.Payor__c = currOppty.Payor__c;
                if (payorAddMap.containsKey(currOppty.Payor__c)) {
                    orderToBeCreated.Payor_Bill_To_Address__c = payorAddMap.get(currOppty.Payor__c).id;
                    orderToBeCreated.BillingStreet = payorAddMap.get(currOppty.Payor__c).Address_Line_1__c;
                    orderToBeCreated.BillingCity = payorAddMap.get(currOppty.Payor__c).City__c;
                    orderToBeCreated.BillingState = payorAddMap.get(currOppty.Payor__c).State__c;
                    orderToBeCreated.BillingPostalCode = payorAddMap.get(currOppty.Payor__c).Postal_Code__c;
                    orderToBeCreated.BillingCountry = payorAddMap.get(currOppty.Payor__c).Country__c;
                    if (String.isnotBlank(payorAddMap.get(currOppty.Payor__c).Account__r.Payment_Terms__c)) orderToBeCreated.Payment_Terms__c = payorAddMap.get(currOppty.Payor__c).Account__r.Payment_Terms__c;
                    	else orderToBeCreated.Payment_Terms__c = 'net45';
                }
            } else {
                if (billToAddress == null || String.isBlank(billToAddress.Id)) return 'No Primary Bill To Address is present for this User. Please add it on the Account and Retry.';
                orderToBeCreated.Customer_Bill_To_Address__c = billToAddress.Id;
                orderToBeCreated.BillingStreet = billToAddress.Address_Line_1__c;
                orderToBeCreated.BillingCity = billToAddress.City__c;
                orderToBeCreated.BillingState = billToAddress.State__c;
                orderToBeCreated.BillingPostalCode = billToAddress.Postal_Code__c;
                orderToBeCreated.BillingCountry = billToAddress.Country__c;
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
            Double diffAmt = 0;
            Integer orderLength = 0;
			for(OpportunityLineItem oli : oppLinesList){
                 system.debug('----First_Order_Variation_Qty__c'+pbeMap.get(oli.PricebookEntryId).First_Order_Variation_Qty__c);
				if (pbeMap.containsKey(oli.PricebookEntryId) && pbeMap.get(oli.PricebookEntryId).First_Order_Variation_Qty__c != null) diffQty = pbeMap.get(oli.PricebookEntryId).First_Order_Variation_Qty__c; else diffQty = 0;	
				if (pbeMap.containsKey(oli.PricebookEntryId) && pbeMap.get(oli.PricebookEntryId).First_Order_Variation_Amt__c != null) diffAmt = pbeMap.get(oli.PricebookEntryId).First_Order_Variation_Amt__c; else diffAmt = 0;	
                if (oli.Quantity + diffQty > 0) {  // Make Order Line entries only if the Order quantity > 0
                    //Make entries based on what is there on the Opportunity and not overwrite with book entries
                    system.debug('----inside OrderItem loop ');
                    OrderItem orderItemToBeCreated = new OrderItem ();
                    orderItemToBeCreated.Order = orderRef;
                    orderItemToBeCreated.PricebookEntryId = oli.PricebookEntryId;
                    orderItemToBeCreated.Quantity = oli.Quantity + diffQty;
                    orderItemToBeCreated.UnitPrice = oli.UnitPrice + diffAmt;
                    orderItemsToAdd.add(orderItemToBeCreated);
                }
				//If the Opp lines have the SSIP details filled in then the SSIP Rules should be created for each Opportunity lines
                if((oli.Repeat_Quantity__c != null && oli.Repeat_Quantity__c > 0 && oli.Repeat_after_in_Days__c != null && oli.Repeat_after_in_Days__c > 0)) {
                    if(pbeMap.get(oli.PricebookEntryId).PriceBook2.IsSubscription__c && (currOppty.Number_of_Approved_Orders__c == null || (currOppty.Number_of_Approved_Orders__c != null && currOppty.Number_of_Approved_Orders__c > 1))) {
                        system.debug('----SSIP == '+pbeMap.get(oli.PricebookEntryId).PriceBook2.IsSubscription__c);
                        //Make entries to SSIP Rule when the Repeat fields are filled in
                        SSIP_Rule__c ssipRuleToBeCreated = new SSIP_Rule__c();
                        ssipRuleToBeCreated.Account__c = accountId;
                        ssipRuleToBeCreated.Country__c = 'Canada';
                        ssipRuleToBeCreated.CurrencyIsoCode = 'CAD';
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
                        ssipRuleToBeCreated.Is_Funded__c = currOppty.Fund__c != null ? 'True' : null;
                        if (currOppty.Payor__c != null) {ssipRuleToBeCreated.Payor_Exist__c = 'True';  }
                        if (pbeMap.get(oli.PricebookEntryId).PriceBook2.Subscription_Period_In_Days__c != null && pbeMap.get(oli.PricebookEntryId).PriceBook2.Subscription_Period_In_Days__c > 1)
                                ssipRuleToBeCreated.Renewal_Date__c = system.date.today() + (Integer) pbeMap.get(oli.PricebookEntryId).PriceBook2.Subscription_Period_In_Days__c; 
                        else if (pbeMap.get(oli.PricebookEntryId).PriceBook2.Subscription_Period_In_Days__c != null && pbeMap.get(oli.PricebookEntryId).PriceBook2.Subscription_Period_In_Days__c < 0)
                                ssipRuleToBeCreated.Renewal_Date__c = null;
                        /* else if (pbeMap.get(oli.PricebookEntryId).PriceBook2.Subscription_Period_In_Days__c != null && pbeMap.get(oli.PricebookEntryId).PriceBook2.Subscription_Period_In_Days__c == 1)
                                ssipRuleToBeCreated.Renewal_Date__c = system.date.today().addYears(1); */
                        else ssipRuleToBeCreated.Renewal_Date__c = system.date.today().addDays(360);
                        if (pbeMap.get(oli.PricebookEntryId).Number_of_Repeat_Orders__c != null && pbeMap.get(oli.PricebookEntryId).Number_of_Repeat_Orders__c > 0 && oli.Repeat_End_Date__c == null) {	
                            if (oli.PriceBookEntry.Product2.Name.startsWithIgnoreCase('MT')) orderLength = 360;
                            else orderLength = 348;
                            //orderLength =Integer.valueOf((pbeMap.get(oli.PricebookEntryId).Number_of_Repeat_Orders__c * oli.Repeat_after_in_Days__c) - oli.First_Repeat_Order_Lead_Days__c + 1);	
                            ssipRuleToBeCreated.Rule_End_Date__c = ssipRuleToBeCreated.Rule_Start_Date__c + orderLength;
                            //ssipRuleToBeCreated.Rule_End_Date__c = ssipRuleToBeCreated.Rule_Start_Date__c.addYears(1).addDays(-1); // + orderLength;	
                        } 
                        ssipRuleList.add(ssipRuleToBeCreated);
                        system.debug('----ssipRuleList == '+ssipRuleList);
                    }/*  else {
                        if (!pbeMap.get(oli.PricebookEntryId).PriceBook2.IsSubscription__c) {                
                            return 'Please select Subscription pricebook'; 
                        }
                    } */
                }
                
                
			}
			
        }
        
        system.debug('ordersToAdd.size()'+ ordersToAdd.size());
		//Insert Order Records
        if (ordersToAdd.size() > 0) {
			string result;
            try { 
                system.debug('ordersToAdd.size()'+ ordersToAdd.size());
                insert ordersToAdd;
                
                } catch (DmlException de) {
                    system.debug('bug.size()'+ ordersToAdd.size());
                    if(de.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) result = de.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').substringBefore('[');
                        else result = de.getMessage();    
                    system.debug('bug.size()'+ result);
                    system.debug('de.getMessage()'+ de.getMessage());
                    return result;
            }
        }
		
		//Insert Order lines Records
        if (orderItemsToAdd.size() > 0) {
			string result;
            try { insert orderItemsToAdd;
                } catch (DmlException de) {
                if(de.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) result = de.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').substringBefore('[');
                else result = de.getMessage();
                return result;
            }
        }
		//Update Opportunity records with Order reference
        if (ordersToAdd.size() > 0) {
			string result;
            try { update opptyMap.values();
                } catch (DmlException de) {
                    if(de.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) result = de.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').substringBefore('[');
                    else result = de.getMessage();
                    return result;
                }
        }
        
		//Insert SSIP Rule Records
        if (ssipRuleList.size() > 0) {
			string result;
            try { 
                insert ssipRuleList;
                system.debug('----in try ssipRuleList == ');
                } catch (DmlException de) {
                    system.debug('----Catch == ');
                    system.debug('----de == '+de);
                    system.debug('----de.getMessage() == '+de.getMessage());
                    if(de.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) result = de.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').substringBefore('[');
                    if(de.getMessage().contains('DUPLICATES_DETECTED')) result = 'SSIP Rule for the same Product already exist, only one rule can be active for a Product.';
                    if (String.isBlank(result)) result = de.getMessage();
                    return result;
                }
        } 
		return 'OK';
    }
}