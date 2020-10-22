/*******************************************************************************************************************************************
@Author        : Kumar Navneet
@Date Created    : 20/09/2019
@Description    : Class used to process Opportunity records to create Schedule Shipment and its line item entries as per the product schedule
********************************************************************************************************************************************/
public class ClsCHOpportunityTriggerHandler
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
        
        Id orderRecTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('CH Sales Order').getRecordTypeId();
        Id ssipRuleRecTypeId = Schema.SObjectType.SSIP_Rule__c.getRecordTypeInfosByName().get('CH SSIP Rule').getRecordTypeId();
        
        //Get the Opportunity and line details to process further
        for(Opportunity oppty : [SELECT Id, AccountId, Pricebook2Id, Type, Payment_Terms__c, (Select OpportunityId, PricebookEntryId, PriceBookEntry.PriceBook2Id, PriceBookEntry.Product2Id, PriceBookEntry.Product2.Name, Quantity, 
                                                                            UnitPrice, Repeat_after_in_Days__c, Repeat_Quantity__c, Repeat_End_Date__c, First_Repeat_Order_Lead_Days__c FROM OpportunityLineItems) FROM Opportunity WHERE Id IN : opptyIdsToProcess])
        {
            opptyMap.put(oppty.Id, oppty);
            oppToLinesMap.put(oppty.Id, oppty.OpportunityLineItems);
            accountIdSet.add(oppty.AccountId);
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
            orderToBeCreated.Customer_Bill_To_Address__c = billToAddress.Id;
            orderToBeCreated.Customer_Ship_To_Address__c = shipToAddress.Id; 
            orderToBeCreated.BillingStreet = billToAddress.Address_Line_1__c;
            orderToBeCreated.BillingCity = billToAddress.City__c;
            orderToBeCreated.BillingState = billToAddress.State__c;
            orderToBeCreated.BillingPostalCode = billToAddress.Postal_Code__c;
            orderToBeCreated.BillingCountry = billToAddress.Country__c;
            orderToBeCreated.ShippingStreet = shipToAddress.Address_Line_1__c;
            orderToBeCreated.ShippingCity = shipToAddress.City__c;
            orderToBeCreated.ShippingState = shipToAddress.State__c;
            orderToBeCreated.ShippingPostalCode = shipToAddress.Postal_Code__c;
            orderToBeCreated.ShippingCountry = shipToAddress.Country__c;
            orderToBeCreated.OpportunityId = currOppty.Id;
            if(currOppty.Payment_Terms__c != null)
            orderToBeCreated.Payment_Terms__c = currOppty.Payment_Terms__c ;
            orderToBeCreated.Status = 'Draft';
            orderToBeCreated.Price_Book__c = currOppty.Pricebook2Id;
            orderToBeCreated.EffectiveDate = system.today(); 
            orderToBeCreated.External_Id__c = externalIdValue;
            orderToBeCreated.Type = 'CH STANDARD';
            orderToBeCreated.CurrencyIsoCode = 'CHF';
            orderToBeCreated.RecordTypeId = orderRecTypeId;
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
                    ssipRuleToBeCreated.Country__c = 'Switzerland';
                    ssipRuleToBeCreated.CurrencyIsoCode = 'CHF';
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
            try { 
                result= 'success';
                insert ordersToAdd;
            } catch (DmlException de) {
                if(de.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) result = de.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').substringBefore('[');
                return result;
            }
        }
        
        //Insert Order lines Records
        if (orderItemsToAdd.size() > 0) {
            string result;
            try { 
                result= 'success';
                insert orderItemsToAdd;
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
        
        /* if(ssipRuleList.size() > 0){
string result;
System.debug('*****Entered ssip processing');
Database.SaveResult[] srList = Database.insert(ssipRuleList, false);
for (Database.SaveResult sr : srList) {
if (!sr.isSuccess()){
System.debug('*****Entered ssip processing - Failure');
// Insertion failed due to duplicate detected
for(Database.Error duplicateError : sr.getErrors()){
if (duplicateError instanceof Database.DuplicateError) {
System.debug('*****Entered ssip processing - Duplicate error');
Datacloud.DuplicateResult duplicateResult = 
((Database.DuplicateError)duplicateError).getDuplicateResult();
System.debug('*****Entered ssip processing - duplicateResult.getErrorMessage()');
System.debug('*****Duplicate records have been detected by ' + 
duplicateResult.getDuplicateRule());
System.debug(duplicateResult.getErrorMessage());
result = duplicateResult.getErrorMessage();
}
}
}
}
return result;
}*/
        return 'OK';
    }
    
    //This method will add in the SSIP Opportunity Products upon Subscription Opportunity Insert
    public static void processSubscriptionOpportunityProductCreation(List<Opportunity> newOppList){
        //Instantiating the collections
        List<Opportunity> subscriptionOppList = new List<Opportunity>();
        List<OpportunityLineitem> oppItemsToInsertList = new List<OpportunityLineitem>();
        List<Id> chPricebookList = new List<Id>();
        Map<Id, List<PricebookEntry>> chPBEMap = new Map<Id, List<PricebookEntry>>();
        List<PricebookEntry> chPricebookEntList = new List<PricebookEntry>();
        
        //Gather the Opps that are part of the Subscription
        for(Opportunity op :newOppList){
            if(op.Type == 'Subscription'){
                subscriptionOppList.add(op); 
                chPricebookList.add(op.Pricebook2Id);  
            }				
        }
        //Proceed if there are any subscription opps to be processed
        if(!subscriptionOppList.isEmpty()){
            //Prepare the map between the Subscription Pricebook and the Pricebook entries	
            for(PricebookEntry pbe : [SELECT ID, Pricebook2Id, SSIP_Periodic_Order_Quantity__c, SSIP_Next_Order_In_Days__c, UnitPrice, First_Repeat_Order_Lead_Days__c FROM PricebookEntry WHERE Pricebook2Id In :chPricebookList AND IsActive = True AND Productcode != 'DEX-SHIP-01'])
            {
                if(chPBEMap.containsKey(pbe.Pricebook2Id)){
                    List<PricebookEntry> pbeList = chPBEMap.get(pbe.Pricebook2Id);
                    pbeList.add(pbe);
                    chPBEMap.put(pbe.Pricebook2Id, pbeList);
                }
                else
                    chPBEMap.put(pbe.Pricebook2Id, new List<PricebookEntry> {pbe});
            }
            //If there are PBEs then go ahead and create the lines
            if(!chPBEMap.isEmpty())
            {
                //For every Subscription Opp insert the Subscription SKUs based on the Pricelistentry tied to the Subscription Pricebook
                for(Opportunity opo :subscriptionOppList){     
                    List<PricebookEntry> oppPBEs = chPBEMap.get(opo.Pricebook2Id);
                    for(PricebookEntry insertPBE : oppPBEs)
                    {
                        OpportunityLineitem ol = new OpportunityLineitem();
                        ol.opportunityID = opo.Id;
                        ol.PricebookEntryId = insertPBE.Id;
                        ol.Quantity = insertPBE.SSIP_Periodic_Order_Quantity__c;
                        ol.UnitPrice = insertPBE.UnitPrice;
                        ol.Repeat_after_in_Days__c = insertPBE.SSIP_Next_Order_In_Days__c;
                        ol.Repeat_Quantity__c = insertPBE.SSIP_Periodic_Order_Quantity__c;
                        ol.First_Repeat_Order_Lead_Days__c = insertPBE.First_Repeat_Order_Lead_Days__c;
                        ol.Product_Added_By_Admin__c = true;
                        oppItemsToInsertList.add(Ol);
                    }
                }
            }
            //Insert Opp Lines
            if(!oppItemsToInsertList.isEmpty())
                insert oppItemsToInsertList;
        }
    }
}