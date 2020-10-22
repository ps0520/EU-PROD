/****************************************************************************************************************
@Author         : Shailendra Singh Lodhi
@Date Created   : 5/22/2019
@Description    : Creating class for process builder relatd to Order object
****************************************************************************************************************/
public class BPClsOrderHandler {
   
    public void onBeforeInsert(List<Order> lstOrder){
        //Process logic for Tech Support Orders
        updateTechSupportOrder(lstOrder);
        Map<Id, RecordType> mapRecordType = new Map<Id, RecordType>([SELECT Id, DeveloperName, Name FROM RecordType WHERE SobjectType = 'Order']);
        Set<Id> setOpportunityId = new Set<Id>();
        Set <Id> pbSet = new Set<Id>();
        Set<Id> actIdSet = new Set<Id>();
        List<Id> CAAccId = new List<Id>();
        //Sample price book for all country
         Map<String, PriceBook2> mapSamplepb = new Map<String, PriceBook2>();
        For(PriceBook2 PB :[Select Id, Name from PriceBook2 where Name like '%No Charge' limit 50])
        {
            mapSamplepb.put(PB.Name, PB) ;
        }
        //Sample price book for Slovenia
     //   List<PriceBook2> SamplepbList = [Select Id from PriceBook2 where Name like 'SI No Charge' limit 1];
     //   List<PriceBook2> CANSamplepbList = [Select Id from PriceBook2 where Name like 'CAN No Charge' limit 1];
        for(Order objOrder : lstOrder){
            if(mapRecordType.containsKey(objOrder.RecordTypeId) && mapRecordType.get(objOrder.RecordTypeId).DeveloperName.startsWithIgnoreCase('CA_')){
                objOrder.CurrencyIsoCode = 'CAD';
                CAAccId.add(objOrder.AccountId);
            }
            if(mapRecordType.containsKey(objOrder.RecordTypeId) && mapRecordType.get(objOrder.RecordTypeId).DeveloperName.startsWithIgnoreCase('CH_')){
                objOrder.CurrencyIsoCode = 'CHF';
            }
            if(mapRecordType.containsKey(objOrder.RecordTypeId) && mapRecordType.get(objOrder.RecordTypeId).DeveloperName.startsWithIgnoreCase('GB_') && objOrder.CurrencyIsoCode != 'GBP'){
                objOrder.CurrencyIsoCode = 'GBP';
            }
            if(mapRecordType.containsKey(objOrder.RecordTypeId) && (mapRecordType.get(objOrder.RecordTypeId).DeveloperName.startsWithIgnoreCase('IE_') || mapRecordType.get(objOrder.RecordTypeId).DeveloperName.startsWithIgnoreCase('SI_') || mapRecordType.get(objOrder.RecordTypeId).DeveloperName.startsWithIgnoreCase('BE_') || mapRecordType.get(objOrder.RecordTypeId).DeveloperName.startsWithIgnoreCase('LU_') || mapRecordType.get(objOrder.RecordTypeId).DeveloperName.startsWithIgnoreCase('NL_'))){
               objOrder.CurrencyIsoCode = 'EUR';
            }
            if(mapRecordType.containsKey(objOrder.RecordTypeId) && mapRecordType.get(objOrder.RecordTypeId).DeveloperName.startsWithIgnoreCase('DE_') && objOrder.OpportunityId != null){
                setOpportunityId.add(objOrder.OpportunityId);
            }
            pbSet.add(objOrder.Price_Book__c);
            actIdSet.add(objOrder.AccountId);
            //Set the PONumber on the Order if the Order has Fund association
            if (objOrder.Fund__c !=  null) objOrder.PONumber = ClsFundService.getPONumber(objOrder.Fund__c);
        }
        
        Map<Id, Benefit__c > mapBenefit = new Map<Id, Benefit__c>();    
        for(Benefit__c ben :[SELECT Id, Account__c, Payor__c, Payor__r.Price_Book__c, Member_Id__c  FROM Benefit__c where Account__c IN: CAAccId AND Benefit_Hierarchy__c =: 'Primary' AND Inactive__c = false] ) 
            mapBenefit.put(ben.Account__c, ben);    
        Map<Id, Opportunity> mapOpportunity = new Map<Id, Opportunity>([SELECT Id, Cash_Pay__c  FROM Opportunity WHERE Id IN: setOpportunityId]);
        for(Order objOrder : lstOrder){
            // Updating payor and pricebook from benefit for Canada 	
	            if (mapBenefit.size() > 0 && objOrder.Order_Sub_Type__c == 'Funded - Single' && mapBenefit.containskey(objOrder.AccountId)){  	
	                if(objOrder.Payor__c == null){    	
	                    objOrder.Payor__c = mapBenefit.get(objOrder.AccountId).Payor__c;
	                    objOrder.Price_Book__c = mapBenefit.get(objOrder.AccountId).Payor__r.Price_Book__c;                     	
	                }   	
	                objOrder.Member_Id__c = mapBenefit.get(objOrder.AccountId).Member_Id__c;                	
	            }
            if(mapRecordType.containsKey(objOrder.RecordTypeId) && mapRecordType.get(objOrder.RecordTypeId).DeveloperName.startsWithIgnoreCase('DE_') && objOrder.OpportunityId != null && mapOpportunity.containsKey(objOrder.OpportunityId)  && !mapOpportunity.get(objOrder.OpportunityId).Cash_Pay__c && objOrder.Type != 'DE RETURN & CREDIT'){
                objOrder.OMS_Action__c = 'placeInvoiceHold';
            }
        }
        
        //--------------VALIDATE IF CHOSEN PRICEBOOK IS CORRECT AS PER THE CONTEXT OF THE ACCOUNT TYPE -------------START ----//
        Map<Id, PriceBook2> pbMap = new Map<Id, PriceBook2>([Select Id, Name, IsSubscription__c, Price_List_Target__c from PriceBook2 where Id in :pbSet]);
        Map<Id, Account> mapAccount = new Map<Id, Account>([Select Id, RecordType.Name, CurrencyIsoCode from Account where Id in :actIdSet]);
        for(Order objOrder : lstOrder){
            //system.debug('origin' + objOrder.System_Of_Origin__c.containsIgnoreCase('ecom') + ', pb cond:' + pbMap.get(objOrder.Price_Book__c).Price_List_Target__c.containsIgnoreCase('ECOM'));
            //Commenting out the following line as we will accommodate Subscription Price Books. The Code is added after checking the Price Book Applicability so as not to waste effort
            // if(pbMap.containsKey(objOrder.Price_Book__c) && pbMap.get(objOrder.Price_Book__c).IsSubscription__c && objOrder.OpportunityId == NULL && !objOrder.Type.containsIgnoreCase('RETURN')) objOrder.addError('Order cannot be created using the subscription price book. Please select another Price Book.');
            if (objOrder.Price_Book__c != null && pbMap.containskey(objOrder.Price_Book__c) && String.isNotBlank(objOrder.Type) && !objOrder.Type.containsIgnoreCase('RETURN') && 
                        String.isNotBlank(pbMap.get(objOrder.Price_Book__c).Price_List_Target__c) 
                    && pbMap.get(objOrder.Price_Book__c).Price_List_Target__c!= null && !pbMap.get(objOrder.Price_Book__c).Price_List_Target__c.containsIgnoreCase('ALL') && 
                    !(objOrder.System_Of_Origin__c != null && objOrder.System_Of_Origin__c.containsIgnoreCase('ecom') && pbMap.get(objOrder.Price_Book__c).Price_List_Target__c.containsIgnoreCase('ECOM')) && 
                ((mapAccount.get(objOrder.AccountId).RecordType.Name.containsIgnoreCase('Consumer') && !pbMap.get(objOrder.Price_Book__c).Price_List_Target__c.contains('Consumer')) ||
                 (mapAccount.get(objOrder.AccountId).RecordType.Name.containsIgnoreCase('Payor') && !pbMap.get(objOrder.Price_Book__c).Price_List_Target__c.contains('Payor')) ||
                 (mapAccount.get(objOrder.AccountId).RecordType.Name.containsIgnoreCase('Medical') && !pbMap.get(objOrder.Price_Book__c).Price_List_Target__c.contains('Medical_Facility')) ||
                 (mapAccount.get(objOrder.AccountId).RecordType.Name.containsIgnoreCase('Prescriber') && !pbMap.get(objOrder.Price_Book__c).Price_List_Target__c.contains('Prescriber'))
                )){
                     objOrder.addError('Chosen price book is not applicable to this type of Account');
                     return;
                 }
            //The following needs to be moved to after insert as Order needs to be created before adding Order Items
           // if(pbMap.containsKey(objOrder.Price_Book__c) && pbMap.get(objOrder.Price_Book__c).IsSubscription__c) populateSubscriptionOrderItems(objOrder, pbMap.get(objOrder.Price_Book__c));
        }
        //--------------VALIDATE IF CHOSEN PRICEBOOK IS CORRECT AS PER THE CONTEXT OF THE ACCOUNT TYPE -------------END ----//
        //Now you can set the Currency Code for the Distributors
        for(Order objOrder : lstOrder){
             if(mapRecordType.containsKey(objOrder.RecordTypeId) && (mapRecordType.get(objOrder.RecordTypeId).DeveloperName.startsWithIgnoreCase('DIST_') || mapRecordType.get(objOrder.RecordTypeId).DeveloperName.containsIgnoreCase('clinic')) ){
                 objOrder.CurrencyIsoCode = mapAccount.get(objOrder.AccountId).CurrencyIsoCode;
            } 
             if((objOrder.Type == 'SI SALES SAMPLE' || objOrder.Type == 'BE SALES SAMPLE' || objOrder.Type == 'NL SALES SAMPLE' || objOrder.Type == 'LU SALES SAMPLE') && mapSamplepb.size() > 0)
            {
                String countryCode = mapRecordType.get(objOrder.RecordTypeId).DeveloperName.substring(0,2)+' No Charge';                
                if(mapSamplepb.get(countryCode).id != null)
                     objOrder.Pricebook2Id = mapSamplepb.get(countryCode).id ;
            }
            if(objOrder.Type == 'CA SALES SAMPLE' && mapSamplepb.size() > 0)
            {
                objOrder.Pricebook2Id = mapSamplepb.get('CAN No Charge').id ;
              //  objOrder.Pricebook2Id = CANSamplepbList[0].id ;
              //  objOrder.Price_Book__c = SamplepbList[0].id ;
            }
        }         
    }

    private void updateTechSupportOrder(List<Order> lstOrder){
        List<Order> lstOrderNew = new List<Order>();
        Set<Id> setAccountId = new Set<Id>();
        Set<String> setTechSupportType = new Set<String>();
        Map<String, PriceBook2> mapPriceBook = new Map<String, PriceBook2>();
        Map<String, RecordType> mapRecordType = new Map<String, RecordType>();
        Map<String, String> defaultValuesMap = new Map<String, String>();
        //Retrieve the possible default values for a tech support order
        for(Tech_Order_Default_Mapping__mdt wmdt: [SELECT MasterLabel, Warehouse__c, Default_Shipping_Method__c FROM Tech_Order_Default_Mapping__mdt]) {
            String possibleDefaultValues = wmdt.Warehouse__c+';'+wmdt.Default_Shipping_Method__c;
            defaultValuesMap.put(wmdt.MasterLabel, possibleDefaultValues);
        }   
        for(Order objOrder : lstOrder){
            if(objOrder.Tech_Support_Order_Type__c == null) continue;
            lstOrderNew.add(objOrder);
            setAccountId.add(objOrder.AccountId);
            setTechSupportType.add('%' +objOrder.Tech_Support_Order_Type__c);
        }
        for(PriceBook2 objPriceBook : [SELECT Id, Name FROM PriceBook2 WHERE (Name LIKE '%RETURN REPLACE' OR Name LIKE 'OUS Technical Support')]){
            mapPriceBook.put(objPriceBook.Name, objPriceBook);
        }
        for(RecordType objRecordType : [SELECT Id, Name FROM RecordType WHERE Name LIKE '%TECH SUPPORT%']){
            mapRecordType.put(objRecordType.Name, objRecordType);
        }
        Map<Id, Account> mapAccount = new Map<Id, Account>([SELECT Id, RecordType.DeveloperName FROM Account WHERE Id IN: setAccountId]);
        
        Set<Id> IntlClinicalAcctsSet = new Set<Id>();
        for(Account act : mapAccount.values()) if (act.RecordType.DeveloperName.startsWithIgnoreCase('INTL_CLINICAL')) IntlClinicalAcctsSet.add(act.Id);
        MAP<Id, Account> IntlClinicalDataMap = new MAP<Id, Account>();
        if (IntlClinicalAcctsSet.size() > 0) IntlClinicalDataMap = new Map<Id, Account>([Select Id, Warehouse__c from Account where Id in :IntlClinicalAcctsSet]);

        for(Order objOrder : lstOrderNew){
            String defaultStringValue = null;
            objOrder.Type = mapAccount.get(objOrder.AccountId).RecordType.DeveloperName.substring(0, 2) + ' ' + objOrder.Tech_Support_Order_Type__c;
            if (mapAccount.get(objOrder.AccountId).RecordType.DeveloperName.startsWithIgnoreCase('INTL_CLINICAL')) objOrder.Type = 'CLINICAL ' + objOrder.Tech_Support_Order_Type__c;
            String pbName = mapAccount.get(objOrder.AccountId).RecordType.DeveloperName.substring(0, 2) + ' Return Replace';
            if (mapAccount.get(objOrder.AccountId).RecordType.DeveloperName.startsWithIgnoreCase('INTL_CLINICAL'))  pbName = 'OUS Technical Support';
            if ( mapPriceBook.containsKey(pbName))  { objOrder.PriceBook2Id = mapPriceBook.get(pbName).Id; objOrder.Price_Book__c = mapPriceBook.get(pbName).Id; }
            String rtName = mapAccount.get(objOrder.AccountId).RecordType.DeveloperName.substring(0, 2) + ' Tech Support Order';
            if (mapAccount.get(objOrder.AccountId).RecordType.DeveloperName.startsWithIgnoreCase('INTL_CLINICAL')) rtName = 'International Clinic Tech Support Order';
            //International Clinic Tech Support Order: Type = CLINICAL TECH REPLACE, Price Book OUS Technical Support, Record Type Name: International Clinic Tech Support Order
            if (mapRecordType.containsKey(rtName))    objOrder.RecordTypeId = mapRecordType.get(rtName).Id;
            defaultStringValue = defaultValuesMap.get(mapAccount.get(objOrder.AccountId).RecordType.DeveloperName.substring(0, 2));
            //if (mapAccount.get(objOrder.AccountId).RecordType.DeveloperName.startsWithIgnoreCase('INTL_CLINICAL')) defaultStringValue = defaultValuesMap.get('CLINICAL');
            if(defaultStringValue != null){
                system.debug('Default values are ' + defaultStringValue);
                List<String> defaultString = defaultStringValue.split(';');//Split values are warehouse, default shipping method
                system.debug('Warehouse is ' + defaultString[0]);
                system.debug('Shipping Method is ' + defaultString[1]);
                
                objOrder.Warehouse__c = defaultString[0];
                objOrder.Shipping_Method__c = defaultString[1];             
            }
            if (mapAccount.get(objOrder.AccountId).RecordType.DeveloperName.startsWithIgnoreCase('INTL_CLINICAL')) {
                objOrder.Warehouse__c = IntlClinicalDataMap.get(objOrder.AccountId).Warehouse__c;
            }
        }

    }

    public void onAfterInsert(List<Order> lstOrder){
        processBuilder(lstOrder, new Map<Id, Order>());
        Set <Id> pbSet = new Set<Id>();
        List<Order> sooOrderUpdList = new List<Order>();
        List<Order> canadaEcomOrders = new List<Order>();
        Order o;
        for(Order objOrder : lstOrder) {
            pbSet.add(objOrder.Price_Book__c);
            if (String.isBlank(objOrder.System_Of_Origin__c)) {
                o = new Order(id=objOrder.Id);
                o.System_Of_Origin__c = 'crm';
                o.System_Of_Origin_ID__c = objOrder.Id;
                o.SOS_Unique_ID__c = 'crm'+objOrder.id;
                sooOrderUpdList.add(o);
            }
            if(objOrder.type.startswithIgnoreCase('CA Standard') && objOrder.System_Of_Origin__c != null && objOrder.System_Of_Origin__c.startswithIgnoreCase('ecom'))  
                    canadaEcomOrders.add(objOrder);
        }
        Map<Id, PriceBook2> pbMap = new Map<Id, PriceBook2>([Select Id, Name, IsSubscription__c, Price_List_Target__c from PriceBook2 where Id in :pbSet]);
        for(Order objOrder : lstOrder)
            if(pbMap.containsKey(objOrder.Price_Book__c) && pbMap.get(objOrder.Price_Book__c).IsSubscription__c && objOrder.OpportunityId == null  && 
                String.isNotBlank(objOrder.Type) && !objOrder.type.containsIgnoreCase('RETURN') ) populateSubscriptionOrderItems(objOrder, pbMap.get(objOrder.Price_Book__c));
        if (sooOrderUpdList.size() > 0) 
            update sooOrderUpdList; 
        if (canadaEcomOrders.size() > 0) tryToMatchAndUpdateOpportunities(canadaEcomOrders);
    }

    public void onBeforeUpdate(List<Order> lstOrder, Map<Id, Order> mapOrderOld){
        Map<Id, Order> mapOrder = new Map<Id, Order>([SELECT Id, RecordType.DeveloperName, Payment_Terms__c, Is_Cash_Order__c, Status, Shipping_Hold_Status__c, Total_Gross_Price__c, CC_Auth_Amount__c, Fund__c, Fund__r.Limit_Type__c, Final_Shipping_Charge__c, Count_of_Order_Line_Items__c, Account.Subscription_Pending_Payments__c, PriceBook2.Name  FROM Order WHERE Id IN: mapOrderOld.keySet()]);
        List<Audit_Tracker__c> lstAuditTrail = new List<Audit_Tracker__c>();
        Set<id> custBillShiptoids=new Set<id>();
        Set<Id> ccOrderSet = new Set<Id>();
        Map<String, ID> readOnlyRecTypesMap = new Map<String, ID>();
        List<RecordType> rts = [Select DeveloperName, Id from RecordType where isActive = true AND SobjectType = 'Order' AND DeveloperName like '%_Read_Only'];
        Id profileId=userinfo.getProfileId();
        List<Profile> prof=[Select Id,Name from Profile where Id=:profileId];
        for(RecordType rt : rts) { readOnlyRecTypesMap.put( rt.DeveloperName.substringBeforeLast('_Read_Only'), rt.Id); }
        for(Order objOrder : lstOrder){
            String profileName = '';
            if (prof.size() > 0) profileName = prof[0].Name; else profileName = 'autoproc';
            //Code to Set Status Coming from Fusion --updated by Pravin - 27May2020
            if(ProfileName.containsIgnoreCase('autoproc') && objOrder.Status == 'CANCELLED') objOrder.Order_Cancellation_Reason__c ='Cancelled in Fusion';
            // Code end-----
            
            string paymentTerm = mapOrder.get(objOrder.Id).Payment_Terms__c;
            if(mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('DE_') && !mapOrder.get(objOrder.Id).Is_Cash_Order__c && mapOrderOld.get(objOrder.Id).Invoice_Status__c != objOrder.Invoice_Status__c && objOrder.Invoice_Status__c  == 'Invoice Requested'){
                objOrder.OMS_Action__c = 'releaseInvoiceHold';
            }
            //Code to handle the Final Shipping Charge
            if(mapOrder.get(objOrder.Id).Final_Shipping_Charge__c != objOrder.Final_Shipping_Charge__c && objOrder.OMS_Action__c == 'chargeShippingAmount') { objOrder.addError('You can\'t change Final Shipping Charge.'); return;}
            if(mapOrder.get(objOrder.Id).Final_Shipping_Charge__c != objOrder.Final_Shipping_Charge__c && objOrder.OMS_Action__c != 'chargeShippingAmount') objOrder.OMS_Action__c = 'chargeShippingAmount';
            //--------------PREVENT ORDR STAGE SKIPPING -------------START ----//
            if(mapOrder.get(objOrder.Id).RecordType.DeveloperName.contains('Sales') && 
               !objOrder.Type.containsIgnoreCase('Sample') && 
               !objOrder.Type.containsIgnoreCase('RETURN') && 
               mapOrderOld.get(objOrder.id).Status == 'Draft' && 
               !(objOrder.Status == 'Draft' || objOrder.Status == 'SHIPPING HOLD' || objOrder.Status == 'CANCELLED' || objOrder.Status == 'CANCELED') && 
               profileName != 'System Administrator' && profileName != 'autoproc')
            {
                //Prevent GB/IE Cash or Prepaid Order to go through QC Hold
                if((mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('GB_') || mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('IE_') || 
                    mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('SI_') || mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('CA_')  || mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('BE_') || 
                    mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('NL_') || mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('LU_') ) 
                   && (paymentTerm == 'net0' || paymentTerm == 'net-1')){}
                //else if (mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('AT_')) {} 
                //else if (mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('DE_') && mapOrder.get(objOrder.Id).PriceBook2.Name.containsIgnoreCase('DE Netto') )  {}
                else if (mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('International_Clinic') && objOrder.Status == 'Activated')  {}
                else
                { objOrder.addError('Order Stage skipping is not permitted. Please choose either Shipping Hold or Cancelled stage.'); return; }
            }
            //--------------PREVENT ORDR STAGE SKIPPING -------------END ----//
            //--------------PREVENT ORDER STATUS CHANGE MANUALLY FROM SHIPPING HOLD AND BEYOND ------------BEGIN-----------//
            String oldStatus = mapOrderOld.get(objOrder.id).Status, newStatus = objOrder.Status;
            if (profileName != 'System Administrator' && profileName != 'autoproc' && newStatus != 'Cancelled' && !objOrder.Type.startsWithIgnoreCase('DE') && 
                ((oldStatus == 'Shipping Hold' && objOrder.Shipping_Hold_Status__c == 'In Progress' && !(newStatus == 'Shipping Hold' || newStatus == 'Draft')) || (objOrder.ActivatedDate != null && oldStatus != newStatus) ||
                 (objOrder.ActivatedDate == null && (newStatus == 'Booked' || newStatus == 'Shipped' || newStatus == 'Closed')) )) {
                     objOrder.addError('You are not allowed to change the Order Status. It will automatically progress.'); 
                     return; 
                 }                                                                      
            //--------------PREVENT ORDER STATUS CHANGE MANUALLY FROM SHIPPING HOLD AND BEYOND ------------END-----------//
                    
            //--------------PREVENT Subscription Orders from moving out of Draft Stage if there are pending Payments -------------START ----//
            if (objOrder.Payment_Terms__c == 'net0' && mapOrder.get(objOrder.Id).Account.Subscription_Pending_Payments__c != null && mapOrder.get(objOrder.Id).Account.Subscription_Pending_Payments__c > 0
                && objOrder.Status != 'Draft' &&  mapOrderOld.get(objOrder.id).Status == 'Draft' && objOrder.Total_Gross_Price__c == 0) {
                    objOrder.addError('There are pending subscription payments. They should be paid before this Order can be processed.');
                    return;
                }
            //--------------PREVENT Subscription Orders from moving out of Draft Stage if there are pending Payments -------------END ----//
                
                    
            //--------------CONFIRM IF THERE ARE ORDER ITEMS ASSOCIATED BEFORE MOVING FROM DRAFT TO SHIPPING HOLD -------------START ----//
            if (objOrder.Status == 'SHIPPING HOLD' && (objOrder.Count_of_Order_Line_Items__c == 0 || (objOrder.Count_of_Order_Line_Items__c == 1 && objOrder.Total_Gross_Price__c == objOrder.Shipping_Charges__c && objOrder.Total_Gross_Price__c > 0)))  
            { objOrder.addError('Please add products to the Order.'); return;}
            //--------------CONFIRM IF THERE ARE ORDER ITEMS ASSOCIATED BEFORE MOVING FROM DRAFT -------------END ----//

            //--------------TAX LOGIC -------------START ----//
            if (objOrder.Need_To_Calculate_Tax__c == 'False') evaluateTaxCalcReqs(lstOrder, mapOrderOld);
            //Make sure that the tax is calculated before the status is changed for Order with type contains Return or Order or the ones, which are about to move to Shipping hold with the amount > 0                  
            if (!objOrder.Tax_Exempt__c && objOrder.Need_To_Calculate_Tax__c == 'True' && ((objOrder.Status == 'SHIPPING HOLD' && objOrder.Total_Gross_Price__c != 0.00) || (objOrder.Type.containsIgnoreCase('RETURN') && objOrder.Status == 'ACTIVATED'))) { objOrder.addError('Please calculate tax before changing the status'); return;}
            //If Credit Card payment term is chosen, make sure that there is an associated credit card.
            if (objOrder.Status == 'Draft' && objOrder.Payment_Terms__c == 'net0' && String.isBlank(objOrder.Finance_Detail__c) && profileName != 'System Administrator' && profileName != 'autoproc') {
                Map<Id, Order> tempOrdMap = new Map<Id, Order>();
                tempOrdMap.put(objOrder.Id, objOrder);
                ClsOrderEntryHandler.checkForCreditCard(tempOrdMap); 
            }
            //--------------TAX LOGIC -------------END ----//
                    
            //--------------CREDIT CARD AUTHORIZATION AND SETTLMENT LOGIC -------------START ----//
            if (mapOrderOld.get(objOrder.id).Status == 'Draft' && (objOrder.Status == 'SHIPPING HOLD' || objOrder.Status == 'ACTIVATED') 
                && objOrder.Payment_Terms__c == 'net0' && (objOrder.Payment_Id__c == null || objOrder.CC_Auth_Amount__c == null) /*CC*/ && objOrder.Total_Gross_Price__c > 0.00 /*CC End*/  ) 
            { objOrder.addError('Please authorize the Credit Card.'); return; } //ClsOrderEntryHandler.authorizeCreditCard(objOrder.Id);
            // Make sure that CC Auth Amount is the same as Order Gross Amount.
            if (mapOrderOld.get(objOrder.id).Status == 'Draft' && objOrder.Status == 'SHIPPING HOLD' && objOrder.Payment_Terms__c == 'net0' && 
                objOrder.Payment_Id__c != null && objOrder.Total_Gross_Price__c != objOrder.CC_Auth_Amount__c)
            { objOrder.addError('Credit Card is authorized for ' + objOrder.CC_Auth_Amount__c + ', Total Order Amount is ' + objOrder.Total_Gross_Price__c + '. Either adjust the Order to match Authorized Amount or Cancel the Order and re-create another Order.'); return; }
            // Please re-authorize the Credit Card. Earlier Authorization was for a different amount.'); //ClsOrderEntryHandler.authorizeCreditCard(objOrder.Id);
            if (mapOrderOld.get(objOrder.id).Status == 'SHIPPING HOLD' && objOrder.Status == 'ACTIVATED' && objOrder.Payment_Terms__c == 'net0' && objOrder.Settlement_Id__c == null && !objOrder.Type.containsIgnoreCase('Credit') && objOrder.Total_Gross_Price__c > 0.00) {
                objOrder.addError('Credit Card payment hasn\'t yet been received.'); //ClsOrderEntryHandler.CCsettlePayment(objOrder.Id);
                return;
            }
            if (mapOrderOld.get(objOrder.id).Status == 'Draft' && objOrder.Status == 'SHIPPING HOLD' && objOrder.Payment_Terms__c == 'net0' && objOrder.Total_Gross_Price__c == 0.00  && objOrder.Type.containsIgnoreCase('Standard') && !objOrder.Type.startsWithIgnoreCase('CH')) objOrder.Status = 'Activated'; // If the CC Order with 0 Amount comes into Shipping Hold, We activate the Order
            //--------------CREDIT CARD AUTHORIZATION AND SETTLMENT LOGIC -------------END ----//
            
            //--------------FUND PROCESSING LOGIC -------------START ----//
            //Update the latest PO If the Fund changes
            string fundType = mapOrder.get(objOrder.Id).Fund__r.Limit_Type__c;
            if (mapOrderOld.get(objOrder.id).Fund__c !=  objOrder.Fund__c && objOrder.Fund__c != null) objOrder.PONumber = ClsFundService.getPONumber(objOrder.Fund__c);
            
            //Check Fund Balance if there is a limit type restriction
            if (((mapOrderOld.get(objOrder.id).Status == 'Draft' && objOrder.Status == 'SHIPPING HOLD') || (objOrder.Status == 'ACTIVATED' && mapOrderOld.get(objOrder.id).Status == 'Draft'  && objOrder.type.containsIgnoreCase('CLINIC'))) && objOrder.Fund__c != null && String.isNotBlank(fundType)){
                String message = ClsFundService.checkFundBalance(objOrder.Id);
                if(message != 'Success') objOrder.addError(message);
            }
            //Charge the Fund
            if (((mapOrderOld.get(objOrder.id).Status == 'SHIPPING HOLD' && objOrder.Status == 'ACTIVATED') || (objOrder.Status == 'ACTIVATED' && mapOrderOld.get(objOrder.id).Status == 'Draft'  && objOrder.type.containsIgnoreCase('CLINIC')) ) && objOrder.Fund__c != null){
                String message = ClsFundService.chargeFund(objOrder.Id);
                if(message != 'Success') objOrder.addError(message);
            }
            //--------------FUND PROCESSING LOGIC -------------END ----//
                    
            //--------------ORDER AUDIT ENTRY LOGIC -------------START ----//
            if (objOrder.Status == 'SHIPPING HOLD'  && mapOrder.get(objOrder.Id).Shipping_Hold_Status__c == null && !objOrder.Type.containsIgnoreCase('Sample') && !objOrder.Type.containsIgnoreCase('RETURN')) {
                //Prevent GB/IE Cash or Prepaid Order to go through QC Hold
                if((mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('GB_') || mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('IE_')) && 
                   (paymentTerm == 'net0' || paymentTerm == 'net-1')){ objOrder.Status='Activated'; }
                //else if(mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('AT_')) { objOrder.Status='Activated'; }
                //else if (mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('DE_') && mapOrder.get(objOrder.Id).PriceBook2.Name.containsIgnoreCase('DE Netto') )  {objOrder.Status='Activated';}
                else
                {
                    objOrder.Shipping_Hold_Status__c = 'In Progress';
                    // Code to enter audit records
                    if (readOnlyRecTypesMap.containsKey(mapOrder.get(objOrder.Id).RecordType.DeveloperName)) objOrder.RecordTypeId = readOnlyRecTypesMap.get(mapOrder.get(objOrder.Id).RecordType.DeveloperName);
                    lstAuditTrail.addAll(new List<Audit_Tracker__c>{    new Audit_Tracker__c(Audit_Field_Name__c = 'Approval', Field_Verified__c = false, Object_Id__c = objOrder.Id),
                        new Audit_Tracker__c(Audit_Field_Name__c = 'Payor', Field_Verified__c = false, Object_Id__c = objOrder.Id)
                        });
                    if ( !mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('CA_')) {
                        lstAuditTrail.add(new Audit_Tracker__c(Audit_Field_Name__c = 'Products', Field_Verified__c = false, Object_Id__c = objOrder.Id));
                        lstAuditTrail.add(new Audit_Tracker__c(Audit_Field_Name__c = 'Price', Field_Verified__c = false, Object_Id__c = objOrder.Id));
                    } else {
                        lstAuditTrail.add(new Audit_Tracker__c(Audit_Field_Name__c = 'Address', Field_Verified__c = false, Object_Id__c = objOrder.Id));
                        lstAuditTrail.add(new Audit_Tracker__c(Audit_Field_Name__c = 'Payment Terms', Field_Verified__c = false, Object_Id__c = objOrder.Id));
                    }
                    if ( mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('AT_')) {
                        lstAuditTrail.add(new Audit_Tracker__c(Audit_Field_Name__c = 'Original Prescription', Field_Verified__c = false, Object_Id__c = objOrder.Id));
                        lstAuditTrail.add(new Audit_Tracker__c(Audit_Field_Name__c = 'Documents Previous Order', Field_Verified__c = false, Object_Id__c = objOrder.Id));
                    }
                }
            }
            //--------------ORDER AUDIT ENTRY LOGIC -------------END ----//
                     
            //NS-1376 auto update shipTo billTo address from customer billTo/shipto            
            if(objOrder.Customer_Bill_To_Address__c!= null && (mapOrderOld.get(objOrder.Id).Customer_Bill_To_Address__c != objOrder.Customer_Bill_To_Address__c)){
                custBillShiptoids.add(objOrder.Customer_Bill_To_Address__c);
            }
            if(objOrder.Customer_Ship_To_Address__c!= null && (mapOrderOld.get(objOrder.Id).Customer_Ship_To_Address__c != objOrder.Customer_Ship_To_Address__c)){
                custBillShiptoids.add(objOrder.Customer_Ship_To_Address__c);
            }
            if(objOrder.Payor_Bill_To_Address__c != null && (mapOrderOld.get(objOrder.Id).Payor_Bill_To_Address__c != objOrder.Payor_Bill_To_Address__c)){	
		                custBillShiptoids.add(objOrder.Payor_Bill_To_Address__c);	
            }
        }		// End of For objOrder Loop
        if(custBillShiptoids.size()>0){
            Map<id,Address__c> addressMap=new Map<id,Address__c>();
            for(Address__c add:[select id,type__c,City__c,Address_Line_1__c,State__c,Country__c,Postal_Code__c from Address__c where id IN : custBillShiptoids ]){
                 addressMap.put(add.id,add);
            }
            for(Order objOrder : lstOrder){
                  if(addressMap.containskey(objOrder.Customer_Bill_To_Address__c)){
                      Address__c add=addressMap.get(objOrder.Customer_Bill_To_Address__c);
                      objOrder.BillingCity=add.City__c;
                      objOrder.BillingStreet=add.Address_Line_1__c;
                      objOrder.BillingState=add.State__c;
                      objOrder.BillingCountry=add.Country__c;
                      objOrder.BillingPostalCode=add.Postal_Code__c;
                  }
                   if(addressMap.containskey(objOrder.Customer_Ship_To_Address__c)){
                      Address__c add=addressMap.get(objOrder.Customer_Ship_To_Address__c);
                      objOrder.ShippingCity=add.City__c;
                      objOrder.ShippingStreet=add.Address_Line_1__c;
                      objOrder.ShippingState=add.State__c;
                      objOrder.ShippingCountry=add.Country__c;
                      objOrder.ShippingPostalCode=add.Postal_Code__c;
                  }
            }
        }
        //End  NS-1376 auto update shipTo billTo address from customer billTo/shipto
        if (lstAuditTrail.size() > 0) insert lstAuditTrail;
        if (ccOrderSet.size() > 0) ClsCreditCardProcessing.obtainPayment(ccOrderSet);
    }
    public void evaluateTaxCalcReqs(List<Order> lstOrder, Map<Id, Order> mapOrderOld){
        for(Order objOrder : lstOrder){
            // if(objOrder.TotalAmount !=  mapOrderOld.get(objOrder.Id).TotalAmount) objOrder.Need_To_Calculate_Tax__c = 'True';   // This does not work. TotalAmount is internally calculated by Changes to Order Items.
            if(objOrder.ShippingPostalCode !=  mapOrderOld.get(objOrder.Id).ShippingPostalCode || objOrder.ShippingCountryCode !=  mapOrderOld.get(objOrder.Id).ShippingCountryCode) objOrder.Need_To_Calculate_Tax__c = 'True';
        }

    }
    public void onAfterUpdate(List<Order> lstOrder, Map<Id, Order> mapOrderOld){
        processBuilder(lstOrder, mapOrderOld);
        Map<Id, Order> mapOrder = new Map<Id, Order>([SELECT Id,Status,Total_Gross_Price__c, RecordType.DeveloperName, Payment_Terms__c, Is_Cash_Order__c, 
                                                      Payor__c, Final_Shipping_Charge__c, Payor__r.Name, Payor_Bill_To_Address__c, OMS_Action__c
                                                      FROM Order WHERE Id IN: mapOrderOld.keySet()]);
        Map<Id, Order> mapNonCancelledOrders = new Map<Id, Order>();
       
       List<String> lstStndRefundOrder = new List<String>();
       List<String> lstCreditRefundOrder = new List<String>();
        
        Set<String> setOrderId = new Set<String>();
        Set<String> setOrderUpdateId = new Set<String>();
        Set<Id> setOrderIdToUpdateSSIP = new Set<Id>();
        Set<Id> processCHG6ReceiversSetOnInsert = new Set<Id>();
        Set<Id> processCHG6ReceiversSetOnDelete = new Set<Id>();
        List<Opportunity> lstOpportunity = new List<Opportunity>();
        // Identify all the Price Books where we have to Create Opportunities automatically - mostly for GB & IE
        List<PriceBook2> pbsWithAutoOppList = [Select Id from PriceBook2 where IsSubscription__c = true and Create_New_Opportunity__c = true];
        Set<Id> pbIdSet = new Set<Id>();
        for(PriceBook2 pb : pbsWithAutoOppList) pbIdSet.add(pb.Id);
        List<Order> oppCreateList = new List<Order>();
        // Identify all the Price Books where we have to Create Opportunities automatically - mostly for GB & IE
        List<PriceBook2> pbsWithAutoFutureOrderList = [Select Id from PriceBook2 where Future_Order_Gap__c != null AND Future_Order_Gap__c > 0 AND Future_Order_Price_Book__c != null];
        Set<Id> pbFutureOrderIdSet = new Set<Id>();
        for(PriceBook2 pb : pbsWithAutoFutureOrderList) pbFutureOrderIdSet.add(pb.Id);
        List<Order> FutueOrderCreateList = new List<Order>();
        for(Order objOrder : lstOrder){
            
            // OCEevent Publish After order Activated,Booked Or Closed 
            System.debug('**OCE--OrderReference--'+objOrder.OCE_Order_Ref__c);
            if(((objOrder.Status =='Booked' && mapOrderOld.get(objOrder.Id).Status != objOrder.Status) || (objOrder.Status =='Closed' && mapOrderOld.get(objOrder.Id).Status != objOrder.Status)) && !(String.isBlank(objOrder.OCE_Order_Ref__c))){
                String IntegrationMessage = objOrder.Status =='Booked' ? 'Order is Booked in Oracle': objOrder.Status =='Closed' ? 'Order is closed' : ''; 
                String IntegrationStatus = IntegrationMessage == '' ? 'Error' : 'Success';
               // PEClsHandlerOCEEvent.publishOCEOrderEvent(objOrder.OCEOrderReference__c, IntegrationMessage, IntegrationStatus);
                PEClsHandlerOCEEvent.publishOCEAccOrderEvent(objOrder.OCE_Order_Ref__c , objOrder.OrderNumber, objOrder.Status, objOrder.Tracking_Number__c, IntegrationStatus, IntegrationMessage); 
            }
            
            // Refund Order Functionality added by Pravin
            // 1. Standard Order Refund
            System.debug('**Status--'+ mapOrder.get(objOrder.Id).Status);
            
            if(objOrder.Status =='CANCELLED' && mapOrderOld.get(objOrder.Id).Status != objOrder.Status  && objOrder.Payment_Terms__c == 'net0' && objOrder.CC_Auth_Amount__c != null 
               && objOrder.Settlement_Id__c !=null){
                lstStndRefundOrder.add(objOrder.Id);
            }
            // 2. Credit Order Refund
            system.debug('**Obj Status: ' + objOrder.Status + ', Old Order Status: ' + mapOrderOld.get(objOrder.Id).Status + ',  Payment Terms: ' + objOrder.Payment_Terms__c + 
                         ', Type: ' + objORder.Type + ', meets Credit condition: ' + objOrder.Type.containsIgnoreCase('Credit') + ', Gross Price: ' + objOrder.Total_Gross_Price__c);
            if( objOrder.Status == 'Closed' && mapOrderOld.get(objOrder.Id).Status != objOrder.Status && objOrder.Payment_Terms__c == 'net0'
               && objOrder.Type.containsIgnoreCase('Credit') && objOrder.Total_Gross_Price__c != null ){ 
                   lstCreditRefundOrder.add(objOrder.Id);
               }
            
            string paymentTerm = mapOrder.get(objOrder.Id).Payment_Terms__c;
            //For CH Order when Receiver SKU is added or removed corresponding IFUs need to be added or removed
            if(mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('CH_') && mapOrderOld.get(objOrder.Id).Count_Of_G6_Receivers__c != objOrder.Count_Of_G6_Receivers__c && objOrder.Type.containsIgnoreCase('STANDARD')){
                if(objOrder.Count_Of_G6_Receivers__c > 0) processCHG6ReceiversSetOnInsert.add(objOrder.Id);
                if(objOrder.Count_Of_G6_Receivers__c == 0) processCHG6ReceiversSetOnDelete.add(objOrder.Id);
            }   
            if(!mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('DE_') && objOrder.OpportunityId != null && objOrder.Status == 'Closed' && objOrder.Status != mapOrderOld.get(objOrder.Id).Status){
                lstOpportunity.add(new Opportunity(Id = objOrder.OpportunityId, StageName = 'Closed - Complete'));
            }
            if(objOrder.Shipped_Date__c != mapOrderOld.get(objOrder.Id).Shipped_Date__c || (objOrder.Status == 'Closed' && objOrder.Status != mapOrderOld.get(objOrder.Id).Status)){
                setOrderIdToUpdateSSIP.add(objOrder.Id);
            }
            //Find if the Price Book associated to the Order has create Opportunity set and then add it to the list to create Opportunities
            if(pbIdSet.contains(objOrder.Price_Book__c) && objOrder.Status == 'Activated' && mapOrderOld.get(objOrder.ID).Status != 'Activated') oppCreateList.add(objOrder);
            System.debug('=====setOrderIdToUpdateSSIP==='+setOrderIdToUpdateSSIP);
            //Find if the Price Book associated to the Order has create Future Order value, then add it to the list of Orders that need to be processed
            if(pbFutureOrderIdSet.contains(objOrder.Price_Book__c) && objOrder.Status == 'Activated' && mapOrderOld.get(objOrder.ID).Status != 'Activated') FutueOrderCreateList.add(objOrder);
            if(!mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('DE_') && mapOrder.get(objOrder.Id).Payor__c != null && !mapOrder.get(objOrder.Id).Payor__r.Name.containsIgnoreCase('CASH PAYOR') && mapOrder.get(objOrder.Id).Payor_Bill_To_Address__c == null){
                objOrder.addError('Payor Bill to address is missing!');
                continue;
            }
            if(mapOrderOld.get(objOrder.Id).Status != objOrder.Status && (objOrder.Status == 'Activated' || 
                (objOrder.Status == 'Shipping Hold' && !objOrder.Type.containsIgnoreCase('RETURN') &&( /*(mapOrder.get(objOrder.Id).Is_Cash_Order__c && mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('DE_'))  || */
                  (objOrder.Type.containsIgnoreCase('SAMPLE') &&
                   !(objOrder.Type.StartsWithIgnoreCase('GB') || objOrder.Type.StartsWithIgnoreCase('IE') || objOrder.Type.StartsWithIgnoreCase('SI') || objOrder.Type.StartsWithIgnoreCase('CA') )) ||
                  (((mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('GB_') || mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('IE_')) && (paymentTerm == 'net0' || paymentTerm == 'net-1'))))
                )
               )
              ) 
                setOrderId.add(objOrder.Id);
            if(objOrder.Status == 'Activated' || objOrder.Status == 'Shipping Hold') mapNonCancelledOrders.put(objOrder.Id, objOrder);
            if(mapOrder.get(objOrder.Id).RecordType.DeveloperName.startsWithIgnoreCase('DE_') && !mapOrder.get(objOrder.Id).Is_Cash_Order__c && mapOrderOld.get(objOrder.Id).Invoice_Status__c != objOrder.Invoice_Status__c && objOrder.Invoice_Status__c  == 'Invoice Requested'){
                setOrderUpdateId.add(objOrder.Id);
            }
            //Code to handle the Final Shipping Charge. Send update Event. VA Mar 02, 2020
            system.debug('Old Shipping Charge: ' + mapOrderOld.get(objOrder.Id).Final_Shipping_Charge__c + ' , New Shipping Charge: ' + objOrder.Final_Shipping_Charge__c);
            if (objOrder.Final_Shipping_Charge__c != mapOrderOld.get(objOrder.Id).Final_Shipping_Charge__c ) {
                setOrderUpdateId.add(objOrder.Id);
            }
        } 
        
        if((!setOrderId.isEmpty() || !setOrderUpdateId.isEmpty() || !mapNonCancelledOrders.isEmpty()) && ClsOrderHandlerStatic.runOrderEventTriggerv11()){
            if(setOrderId.size()>0) 	 PEClsHandleOrderEvents_V11.publishOrderEvent(setOrderId, new Set<String>(), 'create');
            if(!setOrderUpdateId.isEmpty()) PEClsHandleOrderEvents_V11.publishOrderEvent(setOrderUpdateId, new Set<String>(), 'update');
            //Lock the address records if needed
            if(!mapNonCancelledOrders.isEmpty()){
                Set<String> addressIds = new Set<String>();
                for(Order nonCancelledOrder : mapNonCancelledOrders.values()){
                    addressIds.add(nonCancelledOrder.Customer_Bill_To_Address__c);
                    addressIds.add(nonCancelledOrder.Payor_Bill_To_Address__c);
                    addressIds.add(nonCancelledOrder.Customer_Ship_To_Address__c);
                }
                //Get all the unlcoked addresses tied to the orders in scope
                Map<Id, Address__c> addressMap = new Map<Id, Address__c>([SELECT Id FROM Address__c WHERE Id IN: addressIds AND IsLocked__c = false]);
                LIst<Record_Updater__c> updAddList = new List<Record_Updater__c>();
                if(!addressMap.isEmpty()) {
                    //lockAddressesTiedToOrder(addressMap.keySet());
                    for(Id addId : addressMap.keySet())
                        updAddList.add(new Record_Updater__c(Name='Address__c', Id__c = addId, Action__c='Update',  FieldName__c = 'IsLocked__c', Field_Type__c = 'Checkbox', Value__c = 'true'));
                    insert updAddList;
                }
            }
        }
        if(!setOrderIdToUpdateSSIP.isEmpty()){
            updateSSIPShipmentDate(setOrderIdToUpdateSSIP);
        }
        if(!lstOpportunity.isEmpty()){
            update lstOpportunity;
        }
        if(!processCHG6ReceiversSetOnInsert.isEmpty()){
            ClsCHProcessIFUsForOrders.handleG6ReceiverIFUsOnInsert(processCHG6ReceiversSetOnInsert);
        }
        if(!processCHG6ReceiversSetOnDelete.isEmpty()){
            ClsCHProcessIFUsForOrders.handleG6ReceiverIFUsOnDelete(processCHG6ReceiversSetOnDelete);
        }
        //Call method to populate Opportunities
        if (oppCreateList.size() > 0) autoCreateOppsOnOrderActivation(oppCreateList);
        if (FutueOrderCreateList.size() > 0) ClsOrderBasedAutomation.createFutureOrderAndSSIPRules(FutueOrderCreateList);
        
        // Call method to refund Appropriate Order
        if(lstStndRefundOrder.size()>0)  refundStndOrders(lstStndRefundOrder);
        if(lstCreditRefundOrder.size()>0) refundCreditOrders(lstCreditRefundOrder);
        
    }
    //Future method will be invoked when certain addresses tied to the Order need to be locked
    @future
    public static void lockAddressesTiedToOrder(Set<Id> addressIds) {
        Map<Id, Address__c> mapLockAddresses = new Map<Id, Address__c>();
        for(Address__c addr : [SELECT Id, IsLocked__c FROM Address__c WHERE Id IN: addressIds])
        {
            addr.IsLocked__c = true;
            mapLockAddresses.put(addr.Id, addr);
        }
        if(!mapLockAddresses.isEmpty())
            update mapLockAddresses.values();
    }

    private void processBuilder(List<Order> lstOrder, Map<Id, Order> mapOrderOld){
        if(ClsOrderHandlerStatic.runOrderTrigger()){
            Map<Id, Order> mapOrder = new Map<Id, Order>([SELECT Id, Account.FirstName, Account.LastName, Account.Name, Account.PersonEmail, Account.PersonHasOptedOutOfEmail, Account.IsPersonAccount, RecordType.DeveloperName, Type, Is_Cash_Order__c,
                                                                 Account.RecordType.Name, Account.PersonContactId, Account.Territory__c, Opportunity.Consumer_Email__c, Opportunity.Type, Opportunity.Cash_Pay__c, CreatedBy.Alias, CreatedBy.Name, Count_of_Order_Line_Items__c ,
                                                                 (SELECT Id, Audit_Field_Name__c FROM Audit_Order__r WHERE Field_Verified__c = true AND Audit_Field_Name__c = 'Payor')
                                                            FROM Order WHERE Id IN: lstOrder]);
            Map<String, BP_Process_Builder_Customization__c> customSetting = BP_Process_Builder_Customization__c.getall();
            Map<Id, Order> mapOrderToUpdate = new Map<Id, Order>();
            mapOrderToUpdate = BPClsOrder.updateAddressOnOrder(lstOrder, mapOrderOld, mapOrderToUpdate, mapOrder, customSetting);
            mapOrderToUpdate = BPClsOrder.updateOrderAttributes(lstOrder, mapOrderOld, mapOrderToUpdate, mapOrder, customSetting);
            mapOrderToUpdate = BPClsOrder.mcOrderEmails(lstOrder, mapOrderOld, mapOrderToUpdate, mapOrder, customSetting);
            mapOrderToUpdate = BPClsOrder.sdocsJobforWebsiteOrders(lstOrder, mapOrderOld, mapOrderToUpdate, mapOrder, customSetting);
            mapOrderToUpdate = BPClsOrder.createAuditRecordsInsuranceOrders(lstOrder, mapOrderOld, mapOrderToUpdate, mapOrder, customSetting);
            mapOrderToUpdate = BPClsOrder.updateAuditRecordsOnOrderChange(lstOrder, mapOrderOld, mapOrderToUpdate, mapOrder, customSetting);
            //mapOrderToUpdate = BPClsOrder.updateWarehouseForBusingenOrders(lstOrder, mapOrderOld, mapOrderToUpdate, mapOrder, customSetting);
            mapOrderToUpdate = BPClsOrder.updateDistributorBillToAddress(lstOrder, mapOrderOld, mapOrderToUpdate, mapOrder, customSetting);         
            if(!mapOrderToUpdate.isEmpty())
                update mapOrderToUpdate.values();
            
        }
    }
    public static void updateSSIPShipmentDate(Set<Id> setOrderId){
        List<SSIP_Rule__c> lstSSIPRule = new List<SSIP_Rule__c>();
        List<SSIP_Schedule__c> lstSSIPSchedule = new List<SSIP_Schedule__c>();
        for(Order objOrder : [SELECT Id, Fund__c, Shipped_Date__c, Customer_Ship_To_Address__c, Payment_Terms__c, Payor__c, PONumber, Shipping_Method__c, CurrencyIsoCode, (SELECT Id, First_Shipment_Date__c FROM SSIP_Rule__r WHERE First_Shipment_Date__c = null), (SELECT Id FROM SSIP_Schedule__r) FROM Order WHERE Id IN: setOrderId]){
            if(!objOrder.SSIP_Rule__r.isEmpty()){
                String isFundedCheck = objOrder.Fund__c != null ? 'True' : null;
                String isPayorExistCheck = (objOrder.Fund__c == null && objOrder.Payor__c != null) ? 'True' : null;
                Date shippedDate = objOrder.Shipped_Date__c != null ? objOrder.Shipped_Date__c : date.today();
                for(SSIP_Rule__c ssipRule : objOrder.SSIP_Rule__r){
                    lstSSIPRule.add(new SSIP_Rule__c(Id = ssipRule.Id, First_Shipment_Date__c = shippedDate, Shipping_Method__c = objOrder.Shipping_Method__c, Payment_Term__c = objOrder.Payment_Terms__c, CurrencyIsoCode = objOrder.CurrencyIsoCode,Payor_Exist__c = isPayorExistCheck, PO_Number__c = objOrder.PONumber, Is_Funded__c = isFundedCheck));
                }
            }else if(!objOrder.SSIP_Schedule__r.isEmpty()){
                for(SSIP_Schedule__c ssipSchedule : objOrder.SSIP_Schedule__r){
                    lstSSIPSchedule.add(new SSIP_Schedule__c(Id = ssipSchedule.Id, Status__c = 'Closed'));
                }
            }
        }
        update lstSSIPRule;
        update lstSSIPSchedule;
    }
    // Method to populate the Mandatory Subscription Items.
    public static void populateSubscriptionOrderItems(Order objOrder, PriceBook2 pbook) {
        PriceBook2 disallow = [Select Disallow_Direct_Orders__c from PriceBook2 where id = :pbook.id];
        String profileName = '';
        Id profileId=userinfo.getProfileId();
        List<Profile> prof=[Select Id,Name from Profile where Id=:profileId];
        if (prof.size() > 0) profileName = prof[0].Name; else profileName = 'autoproc';
        if (disallow.Disallow_Direct_Orders__c && profileName != 'System Administrator' && profileName != 'autoproc') {
            objOrder.addError('Can not use this price book to create an Order. You need to go through Opportunity Process.');
            return;
        }
        List<OrderItem> oiList = new List<OrderItem>();
        OrderItem oi;
        Double diffQty = 0;
        List<PricebookEntry> pbeList = [SELECT ID, SSIP_Periodic_Order_Quantity__c, First_Order_Variation_Qty__c, UnitPrice 
                                        FROM PricebookEntry WHERE Pricebook2Id = :pbook.Id AND IsActive = True AND Optional_Subscription_Item__c = false AND SSIP_Periodic_Order_Quantity__c > 0];
        for(PriceBookEntry pbe : pbeList) {
            oi = new OrderItem();
            oi.OrderId = objOrder.Id;
            oi.PricebookEntryId = pbe.Id;
            if (pbe.First_Order_Variation_Qty__c == null) diffQty = 0; else diffQty = pbe.First_Order_Variation_Qty__c;
            oi.Quantity = pbe.SSIP_Periodic_Order_Quantity__c + diffQty;
            oi.UnitPrice = pbe.UnitPrice;
            oi.Order_Item_Added_by_Admin__c = true;
            if(oi.Quantity > 0) oiList.add(oi);//added by Shailendra on 23/MAR/2020
        }
        if (oiList.size() > 0) 
            insert oiList;
        system.debug('Added OrderItems');
    }
    // Method to create Opportunities
    public static void autoCreateOppsOnOrderActivation(List<Order> oppCreateList) {
        Id gbOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('GB_Opportunity').getRecordTypeId();
        Id ieOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('IE_Opportunity').getRecordTypeId();
        List<Opportunity> oppToAdd = new List<Opportunity>();
        Set<ID> ordAccSet = new Set<Id>();
        Set<ID> pbUsedIdSet = new Set<Id>();
        Map<String, Id> futurePBMap = new Map<String, Id>();
        Map<Id, Id> curToFutPBMap = new Map<Id, Id>();
        for(Order o : oppCreateList) {ordAccSet.add(o.AccountId); pbUsedIdSet.add(o.Pricebook2Id); }
        Map<Id, Account> accMap = new Map<Id, Account>([Select Id, Name, Territory__c, Medical_Facility__c, Payor__c, Prescriber__c, Country__c, CurrencyIsoCode from Account where id in :ordAccSet ]);
        Map<Id, Account> ordToActMap = new Map<Id, Account>();
        for(Order o : oppCreateList) ordToActMap.put(o.id, accMap.get(o.AccountId));
        
        //****************Logic to map from Price Book's Opp Use Price Book Name to real Price Book Id *************** BEGIN ***************
        List<PriceBook2> currentPBList = [Select Id, New_Opportunity_Price_Book__c from PriceBook2 where id in :pbUsedIdSet];
        Set<String> toBeUsedPriceBooksSet = new Set<String>();
        for(PriceBook2 pb : currentPBList) toBeUsedPriceBooksSet.add(pb.New_Opportunity_Price_Book__c);
        if(!toBeUsedPriceBooksSet.isEmpty()){
            List<PriceBook2> toBeUsedPriceBooksList = [Select Id, Name from PriceBook2 where Name in :toBeUsedPriceBooksSet];
            for(PriceBook2 pb : toBeUsedPriceBooksList) futurePBMap.put(pb.Name, pb.Id);
            for(PriceBook2 curPB : currentPBList) {
                if (futurePBMap.containsKey(curPB.New_Opportunity_Price_Book__c)) curToFutPBMap.put(curPB.Id, futurePBMap.get(curPB.New_Opportunity_Price_Book__c));
            }
        }
        //****************Logic to map from Price Book's Opp Use Price Book Name to real Price Book Id *************** END ***************
        if(!curToFutPBMap.isEmpty()){
            Opportunity opp;
            String terrString = '';
            for(Order o : oppCreateList) {
                if (!curToFutPBMap.containsKey(o.Pricebook2Id)) continue;    // No Price Book that needs to be used in creating the new Opp is found. So, sorry, no Opportunity can be created!!!!!
                opp = new Opportunity();
                if (ordToActMap.get(o.id).country__c == 'United Kingdom') opp.RecordTypeId = gbOppRecordtypeId;
                else if (ordToActMap.get(o.id).country__c == 'Ireland') opp.RecordTypeId = ieOppRecordtypeId;
                opp.AccountId = o.AccountId;
                if (String.isNotBlank(ordToActMap.get(o.id).Territory__c)) terrString = ordToActMap.get(o.id).Territory__c + ' - '; else terrString = '';
                opp.Name = ordToActMap.get(o.id).Name + ' - ' + terrString + Date.TODAY().day() + '.' + Date.today().Month() + '.'  + Date.TODAY().year();
                opp.CloseDate =  Date.today().addDays(30);
                opp.Medical_Facility__c = ordToActMap.get(o.id).Medical_Facility__c;
                opp.Payor__c = ordToActMap.get(o.id).Payor__c;
                opp.Prescriber__c = ordToActMap.get(o.id).Prescriber__c;
                opp.StageName = 'New Opportunity';
                opp.Type = 'Subscription';
                opp.Pricebook2Id = curToFutPBMap.get(o.Pricebook2Id);
                opp.Country__c = ordToActMap.get(o.id).Country__c;
                opp.CurrencyIsoCode = ordToActMap.get(o.id).CurrencyIsoCode;
                opp.Fund__c = o.Fund__c;
                opp.Referral_Order__c = o.Id;
                oppToAdd.add(opp);
            }
            if (oppToAdd.size() > 0)
                insert oppToAdd;
        }
    }
    
    //Cancelled Order Refund
    public Static void refundStndOrders(List<String> lstOrderIds){
        System.debug('**lstOrderIds--'+lstOrderIds.size());
        if(lstOrderIds.size()>0){
            database.executeBatch(new BclsHandleOrderRefund(lstOrderIds,''),1);
        }
    }
    //RGA Order Refund
    public void refundCreditOrders(List<String> lstOrderIds){
       if(lstOrderIds.size()>0){
            database.executeBatch(new BclsHandleOrderRefund(lstOrderIds,'RGA'),1);
        }
    }
    public void tryToMatchAndUpdateOpportunities(List<Order> canadaEcomOrders) {    
        // To do    
        Map<Id, Id> actToOrdMap = new Map<Id, Id>();    
        for(Order o : canadaEcomOrders) actToOrdMap.put(o.AccountId, o.Id); 
        List<Opportunity> openOpps = [Select Id, AccountId from Opportunity where AccountID in :actToOrdMap.keyset() AND StageName = 'Order Fulfillment' AND Ordering_Process__c = 'ECOM' order by LastModifiedDate];   
        Map<Id, Opportunity> orderToOppForUpdateMap = new Map<Id, Opportunity>();   
        for(Opportunity opp : openOpps) {   
            orderToOppForUpdateMap.put(actToOrdMap.get(opp.AccountId), new Opportunity(id=opp.Id, StageName = 'Closed - Complete', Associated_Order__c = actToOrdMap.get(opp.AccountId))); 
        }   
        if (orderToOppForUpdateMap.size() > 0) update orderToOppForUpdateMap.values();  
    }
}