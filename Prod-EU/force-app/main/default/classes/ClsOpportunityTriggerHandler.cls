/*******************************************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 5/10/2017
@Description    : Class used to process Opportunity records to create Schedule Shipment and its line item entries as per the product schedule
@Author        : Jagan Periyakaruppan
@Date Created    : 9/04/2017
@Description    : Updated the logic to accomodate Cash pay on the Opportunity
@Author        : Jagan Periyakaruppan
@Date Created    : 1/08/2018
@Description    : Updated the logic to accomodate populating Supply period start and end date on Orders
@Author        : Jagan Periyakaruppan
@Date Created    : 05/03/2018
@Description    : Added recursive condition logic to avoid the update trigger running twice
********************************************************************************************************************************************/
public class ClsOpportunityTriggerHandler
{
    static List<Id> opptyIdsToProcess = new List<Id>();//List of Opportunities to be processed
    
    //Method checks if the Opportunity product has a schedule and then it will record the schedule shipments relating to Opportunity
    public static void ProcessOpportunityForScheduleShipments(Map<Id, Opportunity> newTriggerOpportunities, Map<Id, Opportunity> oldTriggerOpportunities)
    {
        // Avoid Recursion - If this logic was executed during the same context 
        if(ClsOpportunityTriggerStaticClass.isExecuting)
            return;
        ClsOpportunityTriggerStaticClass.isExecuting = true;
        
        system.debug('----Entering Process to find Opportunity for processing');
        //Check if any Opportunity has been set to 'Order Fulfillment' stage and is a non cash pay Opportunity
        for(Opportunity newOppty : newTriggerOpportunities.values())
        {
            Opportunity oldOppty = oldTriggerOpportunities.get(newOppty.Id);
            //Check if the stage name has changed to 'Order Fulfillment' and it not a cash pay opportunity
            if(((oldOppty.StageName != newOppty.StageName) && newOppty.StageName == 'Order Fulfillment'))
            {
                system.debug('----Opportunity records found for processing');
                opptyIdsToProcess.add(newOppty.Id);
            }
        }
        system.debug('----Completed Process to find Opportunity for processing');
        if(opptyIdsToProcess != null)
        {
            //Process opportunity records for scheduled shipments
            ProcessOpportunityRecords();
            system.debug('----Opportunity records found for processing');
        }
        
    }
    
    public static void ProcessOpportunityRecords()
    {
        system.debug('----Entering Process to Process Opportunity records for Schedule Shipments');
        Map<Id, List<OpportunityLineItem>> opptyToLineItemsMap = new Map<Id, List<OpportunityLineItem>>();//Map Opportunity to its list of opportunity products
        Map<Id, List<Id>> opptyToProductIdsMap = new Map<Id, List<Id>>();//Map Opportunity to its list of product Ids
        Map<Id, Map<Id, List<Product_Schedule__c>>> pricebookToProductScheduleMap = new Map<Id, Map<Id, List<Product_Schedule__c>>>();//Map Pricebook Id to the product schedule for each Medical Advice Number tied to the pricebook
        Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity>();////Create a map between Opportunity Id and Opportunity record
        Map<Id, Map<Id, Id>> pricebookToProdPricebookEntryIdMap = new Map<Id, Map<Id, Id>>();
        Map<Id, Id> opptyIdToQuoteIdMap = new Map<Id, Id>();//Map between Opportunity Id and Approved Quote Id
        Map<String, String> productToMedAdvFeatureCode = new Map<String, String>();//Map between Opportunity product and chosen medical advice feature
        List<Order> ordersToAdd = new List<Order>();//Order records to be added
        List<OrderItem> orderItemsToAdd = new List<OrderItem>();//Order item records to be added
        List<OpportunityLineItem> opptyProducts = new List<OpportunityLineItem>([SELECT Id, Product2Id, ProductCode, OpportunityId, PricebookEntryId, Quantity, UnitPrice, TotalPrice, Medical_Advice_Feature__c FROM OpportunityLineItem WHERE OpportunityId IN : opptyIdsToProcess]);//List holds the opportunity products associated to the Opportunity records
        Set<Id> productIds = new Set<Id>();//Set holds list of product ids tied to Opportunity products
        Set<Id> accountIdSet = new Set<Id>();//Set of account ids to get the bill to and ship to addr information
        Set<Id> payorAccountIdSet = new Set<Id>();//Set of payor account ids to get the bill to and ship to addr information
        Set<Id> allAccountIds = new Set<Id>();//Set of all accounts for which we have to look at the Primary Billing and Shipping address
        Set<Id> pricebookIds = new Set<Id>();//Set holds list of Pricebook Ids
        Set<Id> cashPricebookIds = new Set<Id>();//Set holds list of Pricebook Ids

        system.debug('----Entering the process to create Maps required for Order creation process');
        //Create the Opportunity map and account id set
        for(Opportunity oppty : [SELECT Id, AccountId, Payor__c, Calculated_Copay__c, Pricebook2Id, Cash_Pay__c, benefit__r.Auth_Start_Date__c, benefit__r.Auth_End_Date__c, Pricebook2.Supply_Period_Split__c FROM Opportunity WHERE Id IN : opptyIdsToProcess])
        {
            opptyMap.put(oppty.Id, oppty);
            accountIdSet.add(oppty.AccountId);
            payorAccountIdSet.add(oppty.Payor__c);
            pricebookIds.add(oppty.Pricebook2Id);
            
        }
        allAccountIds.addAll(accountIdSet);
        allAccountIds.addAll(payorAccountIdSet);
        //Get the Ids for all cash pay pricebook
        for(Pricebook2 priceBook : [SELECT Id FROM Pricebook2 WHERE Cash_Pay__c = true])
        {
            cashPricebookIds.add(priceBook.Id);
        }
        
        //Create a map between Opportunity Id and approved Quote, which will be used in order creation process
        for(Quote q : [SELECT Id, OpportunityId FROM Quote WHERE Status = 'Approved' and OpportunityId IN : opptyIdsToProcess])
        {
            opptyIdToQuoteIdMap.put(q.OpportunityId, q.Id);
        }
        
        //Create a map between Account Id and Address (BillTo and ShipTo) objects
        Map<Id, Address__c> accntIdToBillToAddressMap = new Map<Id, Address__c>();
        Map<Id, Address__c> accntIdToShipToAddressMap = new Map<Id, Address__c>();
        if(opptyMap.size() > 0)
        {
            for(Address__c addr : [SELECT Id, Account__c, Address_Line_1__c, City__c, State__c, Postal_Code__c, Country__c, Type__c FROM Address__c WHERE Primary_Flag__c = TRUE AND Account__c IN : allAccountIds]) 
            {
                if(addr.Type__c == 'Bill To')
                    accntIdToBillToAddressMap.put(addr.Account__c, addr);
                else if(addr.Type__c == 'Ship To')
                    accntIdToShipToAddressMap.put(addr.Account__c, addr);
            }
        }

        //Create a map between Pricebook Id and (Product to Pricebookentry Id map) map
        for(PricebookEntry pbe : [SELECT Id,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Pricebook2Id IN : pricebookIds])
        {
            if(pricebookToProdPricebookEntryIdMap.containsKey(pbe.Pricebook2Id))
            {
                Map<Id, Id> productToPricebookEntryIdMap = pricebookToProdPricebookEntryIdMap.get(pbe.Pricebook2Id);
                productToPricebookEntryIdMap.put(pbe.Product2Id, pbe.Id);
                pricebookToProdPricebookEntryIdMap.put(pbe.Pricebook2Id, productToPricebookEntryIdMap);
            }
            else
            {
                Map<Id, Id> tempProductToPricebookEntryIdMap = new Map<Id, Id>();
                tempProductToPricebookEntryIdMap.put(pbe.Product2Id, pbe.Id);
                pricebookToProdPricebookEntryIdMap.put(pbe.Pricebook2Id, tempProductToPricebookEntryIdMap);
            }
        }
        system.debug('----Completing the process to create Maps required for Order creation process');
        
        //Map the Opportunity Id to its list of Opportunity Products
        if(!opptyProducts.isEmpty())
        {
            system.debug('----Entering the process to Map the Opportunity Id to its list of Opportunity Products');
            for(OpportunityLineItem opptyLineItem : opptyProducts)
            {
                system.debug('----Opportunity Product Id is ' + opptyLineItem.Product2Id);
                productIds.add(opptyLineItem.Product2Id);
                if(opptyToLineItemsMap.containsKey(opptyLineItem.OpportunityId))
                {
                    List<OpportunityLineItem> tempOpptyLineItemsList = opptyToLineItemsMap.get(opptyLineItem.OpportunityId);
                    tempOpptyLineItemsList.add(opptyLineItem);
                    opptyToLineItemsMap.put(opptyLineItem.OpportunityId, tempOpptyLineItemsList);
                }
                else
                {
                    opptyToLineItemsMap.put(opptyLineItem.OpportunityId, new List<OpportunityLineItem> {opptyLineItem});
                }
            }
            system.debug('----Completing the process to Map the Opportunity Id to its list of Opportunity Products');

        }
        //Map the PricebookId to Medical Advice Number and its Product Schedules
        if(!productIds.isEmpty())
        {
            system.debug('----Entering the process to map the PricebookId to Medical Advice Number and its Product Schedules');
            //Create a map between the Pricebook Id to Medical Advice Number and its product schedules
            for(Product_Schedule__c prodSchedule : [SELECT Id, Medical_Advice_Number_Id__c, Quantity__c, Product__c, Admin_Price__c, Total_Price__c, Unit_Price__c, Sequence__c, Number_Of_Days_Between_Orders__c, Product__r.Product__c, Product__r.Price_Book__c FROM Product_Schedule__c WHERE Medical_Advice_Number_Id__c IN : productIds AND Product__r.Price_Book__c IN : pricebookIds ORDER BY Sequence__c])
            {
                String pricebookId = prodSchedule.Product__r.Price_Book__c;
                String medicalAdviceNumber = prodSchedule.Medical_Advice_Number_Id__c;
                if(pricebookToProductScheduleMap.containsKey(pricebookId))
                {
                    Map<Id, List<Product_Schedule__c>> tempProdSchedMap = pricebookToProductScheduleMap.get(pricebookId);
                    if(tempProdSchedMap.containsKey(medicalAdviceNumber))
                    {
                        List<Product_Schedule__c> tempProdSchedList = tempProdSchedMap.get(medicalAdviceNumber);
                        tempProdSchedList.add(prodSchedule);
                        tempProdSchedMap.put(medicalAdviceNumber, tempProdSchedList);
                    }
                    else
                    {
                        tempProdSchedMap.put(medicalAdviceNumber, new List<Product_Schedule__c> {prodSchedule});
                    }
                }
                else
                {
                    Map<Id, List<Product_Schedule__c>> newTempProdSchedMap = new Map<Id, List<Product_Schedule__c>>();
                    newTempProdSchedMap.put(medicalAdviceNumber, new List<Product_Schedule__c> {prodSchedule});
                    pricebookToProductScheduleMap.put(pricebookId, newTempProdSchedMap);
                }                   
            }
            system.debug('----Completing the process to map the PricebookId to Medical Advice Number and its Product Schedules');
        }
        
        //Check if all the oppty products have schedules and if not add the products to the product to product schedule map
        for(Id opptyId : opptyToLineItemsMap.keySet())
        {
            system.debug('----Entering the process to Check if all the oppty products have schedule and if not add the products to the product to product schedule map');
            //Get the Pricebook Id of the Opportunity
            String opptyPricebookId = opptyMap.get(opptyId).Pricebook2Id;
            //Get the product schedule map for the pricebook
            Map<Id, List<Product_Schedule__c>> tempProductToproductScheduleMap =  new Map<Id, List<Product_Schedule__c>>();//Instantiating a new map to avoid null pointer exception
            if(pricebookToProductScheduleMap.get(opptyPricebookId) != null)
                tempProductToproductScheduleMap.putAll(pricebookToProductScheduleMap.get(opptyPricebookId));
            
            for(OpportunityLineItem oli : opptyToLineItemsMap.get(opptyId))
            {
                Boolean canCreateProduct = false;
                String medAdvFeature = oli.Medical_Advice_Feature__c != null ? oli.Medical_Advice_Feature__c : null;
                productToMedAdvFeatureCode.put(oli.ProductCode, medAdvFeature);
                System.debug('Med adv feature is ' + medAdvFeature);
                //Added the if block to avoid map null pointer exception
                if(tempProductToproductScheduleMap != null)
                {   
                    if(!tempProductToproductScheduleMap.containsKey(oli.Product2Id))    
                        canCreateProduct = true;
                }
                else if(tempProductToproductScheduleMap == null)
                {
                    canCreateProduct = true;
                }
                if(canCreateProduct)
                {
                    system.debug('----Add the non med device number product ' + oli.Product2Id);
                    Product_Schedule__c oliProdSchedule = new Product_Schedule__c();
                    oliProdSchedule.Product__c = oli.Product2Id;
                    oliProdSchedule.Quantity__c = oli.Quantity;
                    oliProdSchedule.Admin_Price__c = oli.UnitPrice;                 
                    oliProdSchedule.Number_Of_Days_Between_Orders__c = 0;
                    oliProdSchedule.Sequence__c = '1';
                    tempProductToproductScheduleMap.put(oli.Product2Id, new List<Product_Schedule__c> {oliProdSchedule});
                    pricebookToProductScheduleMap.put(opptyPricebookId, tempProductToproductScheduleMap);
                }
                //Prepare a map between the list of Opportunity Ids and its Product Ids
                if(opptyToProductIdsMap.containsKey(oli.OpportunityId))
                {
                    List<Id> tempProdIds = opptyToProductIdsMap.get(oli.OpportunityId);
                    tempProdIds.add(oli.Product2Id);
                    opptyToProductIdsMap.put(oli.OpportunityId, tempProdIds);
                }
                else
                {
                    opptyToProductIdsMap.put(oli.OpportunityId, new List<Id> {oli.Product2Id}); 
                }
            }
            system.debug('----Completing the process to Check if all the oppty products have schedule and if not add the products to the product to product schedule map');
           
        }
        
        //For each opportunity create entries for Order and Order Line Item entries for different date entries as per the product schedule
        for(Id opptyId : opptyIdsToProcess)
        {
            system.debug('----Entering the process to create Schedule Shipment entries for Oppty ' + opptyId);
            Opportunity currOppty = opptyMap.get(opptyId);
            Map<Id, Id> prodToPricebookEntryIdMap = pricebookToProdPricebookEntryIdMap.get(currOppty.Pricebook2Id); //Retrieve the Product Id to PBE Id map
            //Get the product schedule map for the pricebook
            Map<Id, List<Product_Schedule__c>> tempProductToproductScheduleMap =  new Map<Id, List<Product_Schedule__c>>();//Instantiating a new map to avoid null pointer exception
            //Get the product schedule map for the pricebook
            if(pricebookToProductScheduleMap.get(currOppty.Pricebook2Id) != null)
                tempProductToproductScheduleMap.putAll(pricebookToProductScheduleMap.get(currOppty.Pricebook2Id));
            
            Map<Date, Map<String, String>> shipDateToProdScheduleMap = new Map<Date, Map<String, String>>();//Format will be like  Map<Date, Map<Date|ProductId, Qty|Price>>
            List<Date> shipDateList = new List<Date>();//List used to sort Date values in ascending order
            Integer scheduleNumber = 0;
            Decimal copay = 0;
            
            //Get all the product schedule for the products associated to the Opportunity in Opportunity products
            List<Product_Schedule__c> opptyProdSchedules = new List<Product_Schedule__c>();
            for(Id productId :  opptyToProductIdsMap.get(opptyId))
            {
                if(tempProductToproductScheduleMap.get(productId) != null)//check to avoid null pointer exception
                {
                    opptyProdSchedules.addall(tempProductToproductScheduleMap.get(productId));
                }
                system.debug('----Product Id to add to the schedule list is ' + productId);
            }
            system.debug('----Total schedules to process ' + opptyProdSchedules.size());
            //Group the product schedule entries by ship date and its products. Note: For the same ship date, if we have the same product entry more than once then we need to combine the Quantity, so we record only one entry for the product for a particular ship date.
            for(Product_Schedule__c prodSchedule : opptyProdSchedules)
            {
                Date shipmentDate = System.Today().addDays(prodSchedule.Number_Of_Days_Between_Orders__c.intValue());
                system.debug('----Date of the shipment '+shipmentDate);
                //Find the product and unit price for non-medical advice number products
                String productId = prodSchedule.Unit_Price__c == null ? prodSchedule.Product__c : prodSchedule.Product__r.Product__c;
                system.debug('----Processing schedule shipment for product  ' + productId);
                Decimal unitPrice = prodSchedule.Unit_Price__c == null ? prodSchedule.Admin_Price__c : prodSchedule.Unit_Price__c;
                system.debug('----Unit price is ' + unitPrice);
                //Prepare Key Value pair
                String key = String.ValueOf(shipmentDate) + '|' + productId;//Date|ProductId
                system.debug('----Key Format is '+key);
                Decimal priceValue = unitPrice;
                string value = prodSchedule.Quantity__c + '|' + priceValue;//Qty|UnitPrice
                system.debug('----Value Format is '+value);
                
                if(shipDateToProdScheduleMap.containsKey(shipmentDate))
                {
                    Map<String, String> dateProdToQtyPriceMap = shipDateToProdScheduleMap.get(shipmentDate);
                    //If there is already a product to be shipped for the same date then we combine the quantity to make as one shipment
                    if(dateProdToQtyPriceMap.containsKey(key))
                    {
                        system.debug('----Found product to be shipped on the same date ' + key);
                        Integer qty;
                        value = dateProdToQtyPriceMap.get(key);
                        List<String> qtyPriceList = value.split('\\|');
                        if(!qtyPriceList.isEmpty())
                        {
                            qty = Integer.valueOf(qtyPriceList[0]);
                        }
                        qty = qty + prodSchedule.Quantity__c.intValue();
                        value = String.valueOf(qty) + '|' + String.valueOf(unitPrice);
                        system.debug('----Changed Quantity|Price is '+ value);
                    }
                    dateProdToQtyPriceMap.put(key, value);
                    shipDateToProdScheduleMap.put(shipmentDate, dateProdToQtyPriceMap);
                }
                else
                {
                    system.debug('----No entry for the shipment date, so creating a new entry in Map');
                    Map<String, String> dateProdToQtyPriceMap = new Map<String, String>();
                    dateProdToQtyPriceMap.put(key, value);
                    shipDateToProdScheduleMap.put(shipmentDate, dateProdToQtyPriceMap);
                }
            }
            //Sort by date ascending
            shipDateList.addAll(shipDateToProdScheduleMap.keySet());    
            shipDateList.sort();
            //Depending on number of shipments split the copay amount
            copay = currOppty.Calculated_Copay__c != null ? (currOppty.Calculated_Copay__c)/(shipDateList.size()) : 0;
            System.debug('Co-Pay to be charged in each shipment is ' + copay);
            
            //Calculate the Supply period start and end date
            Date authPeriodStartDt = currOppty.benefit__r.Auth_Start_Date__c;
            system.debug('authPeriodStartDt is ' + authPeriodStartDt);
            Date authPeriodEndDt = currOppty.benefit__r.Auth_End_Date__c;
            system.debug('authPeriodEndDt is ' + authPeriodEndDt);
            Integer splitDurationInMonths = currOppty.Pricebook2.Supply_Period_Split__c == null ? 3 : (currOppty.Pricebook2.Supply_Period_Split__c).intValue();
            
            Map<Date, List<Date>> supplyPeriodDateMap = new Map<Date, List<Date>>();
            Date lastEndDt;
            if(authPeriodStartDt != null && authPeriodEndDt != null)
            {
                for(Integer i=0; i<shipDateList.size(); i++)
                {
                    system.debug('Integer value is  ' + i);
                    List<Date> supplyDateList = new List<Date>();
                    Date startDt = null;
                    Date endDt = null;
                    if(i==0)
                        startDt = authPeriodStartDt;//Always set the first date to be Auth start date
                    else
                        startDt = lastEndDt == null ? null : lastEndDt + 1; //If last end date equals authenddate then the start date should be null otherwise add 1 day to the last end date
                    if(startDt != null)
                        endDt = startDt.addMonths(splitDurationInMonths) - 1 > authPeriodEndDt ? authPeriodEndDt : startDt.addMonths(splitDurationInMonths) - 1;
                    if(endDt != null)
                    {
                        if(endDt.isSameDay(authPeriodEndDt))
                            lastEndDt = null;
                        else
                            lastEndDt = endDt;
                        
                    }
                    system.debug('startDt is ' + startDt);
                    system.debug('endDt is ' + authPeriodEndDt);
                    system.debug('lastEndDt is ' + lastEndDt);
                    if(startDt != null)
                    {
                        supplyDateList.add(startDt);
                        supplyDateList.add(endDt);
                    }
                    supplyPeriodDateMap.put(shipDateList[i], supplyDateList);
                }
            }   
            //Add the Schedule Shipment and Shipment Line Item entries
            for(Date dateValue : shipDateList)
            {
                String shipToAccountId = currOppty.AccountId;
                //Jagan 09/04/2017 - Changed the cash pay logic to look at the Opportunity
                //String billToAccountId = cashPricebookIds.contains(currOppty.Pricebook2Id) ? currOppty.AccountId : currOppty.Payor__c;
                List<Date> supplyStartEndDateList = supplyPeriodDateMap.get(dateValue);
                Date supplyStartDt = null;
                Date supplyEndDt = null;
                if(supplyStartEndDateList != null && !supplyStartEndDateList.isEmpty())
                {
                    supplyStartDt = supplyStartEndDateList[0];
                    system.debug('supplyStartDt : ' + supplyStartDt);
                    supplyEndDt = supplyStartEndDateList[1];
                    system.debug('supplyEndDt : ' + supplyEndDt);
                    
                }
                String billToAccountId = currOppty.Cash_Pay__c == true ? currOppty.AccountId : currOppty.Payor__c;
                System.debug('----billToAccountId is ' + billToAccountId);
                Address__c billToAddress = billToAccountId != null ? accntIdToBillToAddressMap.get(billToAccountId) : null;
                Address__c shipToAddress = shipToAccountId != null ? accntIdToShipToAddressMap.get(shipToAccountId) : null;
                String externalIdValue = opptyId + '|' + Date.valueOf(dateValue);
                scheduleNumber = scheduleNumber + 1;
                //Prepare Order Header record entry
                Order orderToBeCreated = new Order();
                orderToBeCreated.AccountId = shipToAccountId;
                orderToBeCreated.Payor__c = currOppty.Payor__c;
                //orderToBeCreated.Payor_Bill_To_Address__c = cashPricebookIds.contains(currOppty.Pricebook2Id) ? null : billToAddress.Id;
                orderToBeCreated.Payor_Bill_To_Address__c = currOppty.Cash_Pay__c == true ? null : billToAddress.Id;
                System.debug('----Payor_Bill_To_Address__c is ' + billToAddress.Id);                
                //orderToBeCreated.Customer_Bill_To_Address__c = cashPricebookIds.contains(currOppty.Pricebook2Id) ? billToAddress.Id : null; 
                orderToBeCreated.Customer_Bill_To_Address__c = currOppty.Cash_Pay__c == true ? billToAddress.Id : null;
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
                orderToBeCreated.OpportunityId = opptyId;
                orderToBeCreated.QuoteId = opptyIdToQuoteIdMap.get(opptyId);
                orderToBeCreated.EffectiveDate = dateValue;
                orderToBeCreated.Status = 'Draft';
                orderToBeCreated.Price_Book__c = currOppty.Pricebook2Id;
                orderToBeCreated.Schedule__c = scheduleNumber;
                orderToBeCreated.Co_Pay__c = copay;
                orderToBeCreated.External_Id__c = externalIdValue;
                orderToBeCreated.Type = 'DE STANDARD';  
                if(supplyStartDt != null)
                    orderToBeCreated.Supply_Period_Start_Date__c = supplyStartDt;
                if(supplyEndDt != null)
                    orderToBeCreated.Supply_Period_End_Date__c = supplyEndDt;               
                ordersToAdd.add(orderToBeCreated);
                //Prepare the order reference
                Order orderRef = new Order(External_Id__c = externalIdValue);
                Map<String, String> schedShipLineItemDetailsMap = shipDateToProdScheduleMap.get(dateValue);
                //Prepare Order Line Items record entry
                for(String s : schedShipLineItemDetailsMap.keySet())
                {
                    system.debug('---- Key Date|ProductId is ' + s);
                    system.debug('----Value Qty|Price is ' + schedShipLineItemDetailsMap.get(s));
                    List<String> keySplit = s.split('\\|');
                    system.debug('----keySplit size is ' + keySplit.size());
                    List<String> valSplit = schedShipLineItemDetailsMap.get(s).split('\\|');
                    OrderItem orderItemToBeCreated = new OrderItem ();
                    orderItemToBeCreated.Order = orderRef;
                    orderItemToBeCreated.Quantity = Decimal.valueOf(valSplit[0]);
                    orderItemToBeCreated.UnitPrice = Decimal.valueOf(valSplit[1]);
                    orderItemToBeCreated.PricebookEntryId = prodToPricebookEntryIdMap.get(keySplit[1]);
                    orderItemsToAdd.add(orderItemToBeCreated);
                }
            }
            system.debug('----ordersToAdd size is ' + ordersToAdd.size());
            system.debug('----orderItemsToAdd size is ' + orderItemsToAdd.size());
        }
        //Insert Order Records
        if(!ordersToAdd.isEmpty())
        {
            system.debug('-----Insert Order Record list entered');
            try{insert ordersToAdd;}
            catch (DmlException de) {
                Integer numErrors = de.getNumDml();
                System.debug('getNumDml=' + numErrors);
                for(Integer i=0;i<numErrors;i++) {
                    System.debug('getDmlFieldNames=' + de.getDmlFieldNames(i));
                    System.debug('getDmlMessage=' + de.getDmlMessage(i));
                }
            }
        }
        
        //Insert Order Item Records
        if(!orderItemsToAdd.isEmpty())
        {
            system.debug('-----Insert Order Record list entered');
            try{insert orderItemsToAdd;}
            catch (DmlException de) {
                Integer numErrors = de.getNumDml();
                System.debug('getNumDml=' + numErrors);
                for(Integer i=0;i<numErrors;i++) {
                    System.debug('getDmlFieldNames=' + de.getDmlFieldNames(i));
                    System.debug('getDmlMessage=' + de.getDmlMessage(i));
                }
            }
        }
        
        List<OrderItem> orderItemsToBeUpdated = new List<OrderItem>();
        //Update Order line items with the Medical advice feature
        for(OrderItem oi : [SELECT Id, Product2.Name, Medical_Advice_Number__c FROM OrderItem where Id IN : orderItemsToAdd])
        {
            system.debug('Order Item ' + oi.Product2.Name + ' - Medical advice number is ' + oi.Medical_Advice_Number__c);
            if(productToMedAdvFeatureCode != null)
            {
                if(productToMedAdvFeatureCode.get(oi.Medical_Advice_Number__c) != null)
                {
                    system.debug('Medical advice feature is ' + productToMedAdvFeatureCode.get(oi.Medical_Advice_Number__c));
                    oi.Medical_Advice_Feature__c = productToMedAdvFeatureCode.get(oi.Medical_Advice_Number__c);
                    orderItemsToBeUpdated.add(oi);
                }
            }
        }
        //Update Order Item Records
        if(!orderItemsToBeUpdated.isEmpty())
        {
            system.debug('-----Update Order items with medical advice feature value');
            try{update orderItemsToBeUpdated;}
            catch (DmlException de) {
                Integer numErrors = de.getNumDml();
                System.debug('getNumDml=' + numErrors);
                for(Integer i=0;i<numErrors;i++) {
                    System.debug('getDmlFieldNames=' + de.getDmlFieldNames(i));
                    System.debug('getDmlMessage=' + de.getDmlMessage(i));
                }
            }
        }
        
    }
    
    //Method updates the Opportunity owner upon Opportunity insert
    public static void OpportunityOwnerupdate(List<Opportunity> newOpptyList, String country){
        List<String> terrCodes = new List<String>(); 
        List<Account> accountList = new List<Account>();
        Set<Id> accntIds = new Set<Id>(); 
        Map<String,Id> territorymap =  new map<String,Id>();
        Map<Id, String> accountIdToTerrMap = new Map<Id, String>();
        Map<Id,Id> insideSalesUserTerritoryMap =  new map<Id,Id>(); 
        String SalesType = 'Inside';
        String caCountryAdmin ;
        String deCountryAdmin ;    
        String chCountryAdmin ;    
        String atCountryAdmin ;    
        String gbCountryAdmin ;
		String ieCountryAdmin ;		
		if(country == 'DE') deCountryAdmin = ClsApexUtil.GetCountryAdmin('DE');
		else if(country == 'CA') caCountryAdmin = ClsApexUtil.GetCountryAdmin('CA');
		else if(country == 'CH') chCountryAdmin = ClsApexUtil.GetCountryAdmin('CH');
		else if(country == 'AT') atCountryAdmin = ClsApexUtil.GetCountryAdmin('AT');
		else if(country == 'GB') gbCountryAdmin = ClsApexUtil.GetCountryAdmin('GB');
		else if(country == 'IE') ieCountryAdmin = ClsApexUtil.GetCountryAdmin('IE');
        
        //Get all the account Ids tied to the Opportunity records
        for (Opportunity oppty: newOpptyList) {
            if(oppty.AccountId != null){ 
                accntIds.add(oppty.AccountId);
            }    
        }
        
        //Get all the territories tied to the account, which are tied to the Opportunity records
        for(Account accnt: [SELECT Id, Territory__c FROM Account WHERE ID IN :accntIds]) {
            if(accnt.Territory__c != null){
                terrcodes.add(accnt.Territory__c);
                accountIdToTerrMap.put(accnt.Id, accnt.Territory__c);
            }    
        }

        //Invoke the utility class to get the Territory Name to Id map and User Territory map for field sales
        territorymap = ClsApexUtil.GetTerritoryMap(terrCodes);
        insideSalesUserTerritoryMap = ClsApexUtil.GetUserTerritoryMap(terrCodes,salesType, country);

        //Find he owner id for Opportunity based on the account territory value
        for(Opportunity oppty: newOpptyList){
            if(!insideSalesUserTerritoryMap.isEmpty()){
                Id terrId  = territorymap.get(accountIdToTerrMap.get(oppty.AccountId));
                Id ownerId  = insideSalesUserTerritoryMap.get(terrId);
                if(ownerId != null) oppty.ownerId = ownerId;
				else{
					if(country == 'DE') oppty.ownerId = deCountryAdmin;
					else if(country == 'CA') oppty.ownerId = caCountryAdmin;
					else if(country == 'CH') oppty.ownerId = chCountryAdmin;
					else if(country == 'AT') oppty.ownerId = atCountryAdmin;
					else if(country == 'GB') oppty.ownerId = gbCountryAdmin;
					else if(country == 'IE') oppty.ownerId = ieCountryAdmin;
				} 
            }  
        }
    }
    
    public static void OpportunityAddContentDocument(List<Opportunity> NewOpp){
        Set<id> setOfAccountId = new Set<Id>(); 
        List<ContentDocumentLink> CDL = new List<ContentDocumentLink>();     
        List<ContentDocumentLink>  CDLToInsert = new List<ContentDocumentLink>();
        Map<ID,ID> AccountcontentMap = new Map<ID,ID>();
        for(Opportunity Opp:NewOpp){
            setOfAccountId.add(Opp.AccountId);   
        }        
        CDL = [SELECT ID,ContentDocumentId,ShareType,Visibility,LinkedEntityId FROM ContentDocumentLink where LinkedEntityId IN :setOfAccountId ];
        System.debug('Total CDl = ' +CDL.size());
        for(Opportunity O : NewOpp){ 
            for(ContentDocumentLink C: CDL){
                CDLToInsert.add(new ContentDocumentLink(LinkedEntityId =O.Id,
                                                        ContentDocumentId = c.ContentDocumentId,
                                                        ShareType = 'V',
                                                        Visibility = 'AllUsers'
                                                       )  
                               );     
            }            
            System.debug('Total CDLToInsert = ' +CDLToInsert.size());
        }    
            try{  
                Insert CDLToInsert;
            }
            Catch(DmlException e){
                System.debug('An unexpected error has occurred: ' + e.getMessage());  
            } 
        
        
    }     
}