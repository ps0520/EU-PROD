/****************************************************************************************************************
@Description    : Creating class for handling Country specific logic for Order Item
****************************************************************************************************************/

public class ClsOrderItemCountryHandler {
    
    public static void afterInsertHandler(List<Orderitem> newOrdsList , Map<Id, Orderitem> newOrditemMap) {
        system.debug('AfterInsertHandler');
        //Accumulate
        set<Id> OrderIDSet = new set<Id>();
        Map<Id, Orderitem> DEnewOIMap = new Map<Id, Orderitem>();
        Map<Id, Orderitem> CHnewOIMap = new Map<Id, Orderitem>();
		Map<Id, Orderitem> ATnewOIMap = new Map<Id, Orderitem>();
		Map<Id, Orderitem> GBnewOIMap = new Map<Id, Orderitem>();
		Map<Id, Orderitem> IEnewOIMap = new Map<Id, Orderitem>();
        Map<Id, Orderitem> DISTnewOIMap = new Map<Id, Orderitem>();
		
        Map<Id, Order> ordersMap = new Map<Id, Order>();
		//Get all recordtype id for the order record types
		Id deOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('DE_Sales_Order').getRecordTypeId();
		Id chOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CH_Sales_Order').getRecordTypeId();
		Id atOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('AT_Sales_Order').getRecordTypeId();
		Id gbOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('GB_Sales_Order').getRecordTypeId();
		Id ieOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('IE_Sales_Order').getRecordTypeId();
        Id distOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('DIST_Sales_Order').getRecordTypeId();
		
		
		
		//----TAX LOGIC---START//
		//Get Order Ids invovled in the processing	
        for(Orderitem opacID: newOrditemMap.values()) OrderIDSet.add(opacID.Orderid);
		
		//Update the tax logic
        List<Order> updTaxCalcReqOrderList = new List<Order>();
        for (Order ordd : [Select RecordTypeId , id, Need_To_Calculate_Tax__c from Order where id in :OrderIDSet ]) {
            ordersMap.put(ordd.Id, ordd);
            if ( ordd.Need_To_Calculate_Tax__c == 'False') updTaxCalcReqOrderList.add(new Order(id = ordd.Id, Need_To_Calculate_Tax__c = 'True'));
        }
        // Since new Order Items have been added, Tax should be recalculated. Set Need_To_Calculate_Tax__c to True
        if (updTaxCalcReqOrderList.size() > 0) update updTaxCalcReqOrderList;
        //----TAX LOGIC---END//
		
		// Adding records in Map for specific country processing
        for(Orderitem Od : newOrdsList) {
            if (OrdersMap.get(Od.Orderid).RecordTypeId == deOrd ) DEnewOIMap.put(Od.id, Od);
            else if (OrdersMap.get(Od.Orderid).RecordTypeId == chOrd ) CHnewOIMap.put(Od.id, Od);
				else if (OrdersMap.get(Od.Orderid).RecordTypeId == atOrd ) ATnewOIMap.put(Od.id, Od);
					else if (OrdersMap.get(Od.Orderid).RecordTypeId == gbOrd ) GBnewOIMap.put(Od.id, Od);
						else if (OrdersMap.get(Od.Orderid).RecordTypeId == ieOrd ) IEnewOIMap.put(Od.id, Od);
                              else if (OrdersMap.get(Od.Orderid).RecordTypeId == distOrd ) DISTnewOIMap.put(Od.id, Od);

				
        }
        //Country dispatcher to process QC Hold records
        if (DEnewOIMap.size() > 0) ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(DEnewOIMap, deOrd);
		if (CHnewOIMap.size() > 0)
        {
            ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(CHnewOIMap, chOrd);
           // ClsOrderItemTriggerHandler.InsertIFUOrderitem(CHnewOIMap);
        }
		if (ATnewOIMap.size() > 0) ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(ATnewOIMap, atOrd);
		if (GBnewOIMap.size() > 0) ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(GBnewOIMap, gbOrd);
		if (IEnewOIMap.size() > 0) ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(IEnewOIMap, ieOrd);
        if (DISTnewOIMap.size() > 0) ClsOrderItemTriggerHandler.InsertIFUOrderitem(DISTnewOIMap);
      //  if (CHnewOIMap.size() > 0) ClsOrderItemTriggerHandler.InsertIFUOrderitem(CHnewOIMap);
		
		
    }
    
     public static void afterUpdateHandler(List<Orderitem> newOrdsList , List<Orderitem> oldOrdsList, Map<Id, Orderitem> newOrditemMap, Map<Id, Orderitem> oldOrditemMap) {
        system.debug('AfterUpdateHandler');
		//Accumulate
		Set<Id> OrderIDSet = new Set<Id>();
		Map<Id, Orderitem> DEnewOIMap = new Map<Id, Orderitem>();
        Map<Id, Orderitem> CHnewOIMap = new Map<Id, Orderitem>();
		Map<Id, Orderitem> ATnewOIMap = new Map<Id, Orderitem>();
		Map<Id, Orderitem> GBnewOIMap = new Map<Id, Orderitem>();
		Map<Id, Orderitem> IEnewOIMap = new Map<Id, Orderitem>();
        Map<Id, Orderitem> DISTOLDOIMap = new Map<Id, Orderitem>();
        List<Orderitem> DISTnewOIList = new List<Orderitem>();
        Map<Id, Orderitem> CHOLDOIMap = new Map<Id, Orderitem>();
        List<Orderitem> CHnewOIList = new List<Orderitem>();
		
        Map<Id, Order> ordersMap = new Map<Id, Order>();
		Map<Id, Order> updTaxCalcReqOrderMap = new Map<Id, Order>(); 
        
		//Get all recordtype id for the order record types
		Id deOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('DE_Sales_Order').getRecordTypeId();
		Id chOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CH_Sales_Order').getRecordTypeId();
		Id atOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('AT_Sales_Order').getRecordTypeId();
		Id gbOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('GB_Sales_Order').getRecordTypeId();
		Id ieOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('IE_Sales_Order').getRecordTypeId();
        Id distOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('DIST_Sales_Order').getRecordTypeId();
		
		
		
		//----TAX LOGIC---START//
		//Get all the Order ids to be processed	
		for(Orderitem opacID: newOrditemMap.values()) OrderIDSet.add(opacID.Orderid);
        for (Order ordd : [Select RecordTypeId , id, Need_To_Calculate_Tax__c from Order where id in :OrderIDSet]) ordersMap.put(ordd.Id, ordd);
		for(Orderitem Od : newOrdsList) {
			// IF the Item Quantity is changed and Tax was already calculated, set Need_To_Calculate_Tax__c to True so that Tax recalculation is forced.
			if (od.Quantity != oldOrditemMap.get(od.Id).Quantity && ordersMap.get(od.OrderId).Need_To_Calculate_Tax__c == 'FALSE')
				updTaxCalcReqOrderMap.put(od.OrderId, new Order(id = od.OrderId, Need_To_Calculate_Tax__c = 'TRUE'));
		}
		// Set Needs Tax Calculation on the Order. 
		if (updTaxCalcReqOrderMap.size() > 0) update updTaxCalcReqOrderMap.values();
		//----TAX LOGIC---END//
		
		// Adding records in Map for specific country processing
        for(Orderitem Od : newOrdsList) {
            if (OrdersMap.get(Od.Orderid).RecordTypeId == deOrd ) DEnewOIMap.put(Od.id, Od);
            else if (OrdersMap.get(Od.Orderid).RecordTypeId == chOrd )
            {
                CHnewOIMap.put(Od.id, Od);
                CHnewOIList.add(Od);
            }
				else if (OrdersMap.get(Od.Orderid).RecordTypeId == atOrd ) ATnewOIMap.put(Od.id, Od);
					else if (OrdersMap.get(Od.Orderid).RecordTypeId == gbOrd ) GBnewOIMap.put(Od.id, Od);
						else if (OrdersMap.get(Od.Orderid).RecordTypeId == ieOrd ) IEnewOIMap.put(Od.id, Od);
                            else if (OrdersMap.get(Od.Orderid).RecordTypeId == distOrd ) DISTnewOIList.add(Od);

        }
         for(Orderitem Od : oldOrdsList) {
             if (OrdersMap.get(Od.Orderid).RecordTypeId == distOrd ) DISTOLDOIMap.put(Od.id, Od);
                  else   if (OrdersMap.get(Od.Orderid).RecordTypeId == chOrd ) CHOLDOIMap.put(Od.id, Od);
         }

        //Country dispatcher to process QC Hold records
        if (DEnewOIMap.size() > 0) ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(DEnewOIMap, deOrd);
		if (CHnewOIMap.size() > 0) ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(CHnewOIMap, chOrd);
		if (ATnewOIMap.size() > 0) ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(ATnewOIMap, atOrd);
		if (GBnewOIMap.size() > 0) ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(GBnewOIMap, gbOrd);
		if (IEnewOIMap.size() > 0) ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(IEnewOIMap, ieOrd);         
        if (DISTnewOIList.size() > 0) ClsOrderItemTriggerHandler.UpdateIFUOrderitem(DISTnewOIList, DISTOLDOIMap);
       // if (CHnewOIList.size() > 0) ClsOrderItemTriggerHandler.UpdateIFUOrderitem(CHnewOIList, CHOLDOIMap);
         
        
		
		
		//Update the tracking number on the order. This is applicable for all countries
		ClsOrderItemTriggerHandler.UpdateTrackingNumberOnOrder(newOrditemMap, oldOrditemMap);

     }
     public static void afterDeleteHandler(List<Orderitem> newOrdsList , Map<Id, Orderitem> newOrditemMap) {
        system.debug('AfterDeleteHandler');
        //Accumulate
        set<Id> OrderIDSet = new set<Id>();
        Map<Id, Orderitem> DEnewOIMap = new Map<Id, Orderitem>();
        Map<Id, Orderitem> CHnewOIMap = new Map<Id, Orderitem>();
		Map<Id, Orderitem> ATnewOIMap = new Map<Id, Orderitem>();
		Map<Id, Orderitem> GBnewOIMap = new Map<Id, Orderitem>();
		Map<Id, Orderitem> IEnewOIMap = new Map<Id, Orderitem>();       
        List<Orderitem> DISTnewOIList = new List<Orderitem>();
        List<Orderitem> CHnewOIList = new List<Orderitem>();
         

        Map<Id, Order> ordersMap = new Map<Id, Order>();
		
		//Get all recordtype id for the order record types
		Id deOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('DE_Sales_Order').getRecordTypeId();
		Id chOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('CH_Sales_Order').getRecordTypeId();
		Id atOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('AT_Sales_Order').getRecordTypeId();
		Id gbOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('GB_Sales_Order').getRecordTypeId();
		Id ieOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('IE_Sales_Order').getRecordTypeId();
        Id distOrd = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('DIST_Sales_Order').getRecordTypeId();
		
		
		//----TAX LOGIC---START//
		//Get all the Order ids to be processed
		for(Orderitem opacID: newOrditemMap.values()) OrderIDSet.add(opacID.Orderid);

        // List of Orders whose Taxes may need to be recalculated
        List<Order> updTaxCalcReqOrderList = new List<Order>();
        for (Order ordd : [Select RecordTypeId , id, Need_To_Calculate_Tax__c from Order where id in :OrderIDSet]) {
            ordersMap.put(ordd.Id, ordd);
            if ( ordd.Need_To_Calculate_Tax__c == 'False') updTaxCalcReqOrderList.add(new Order(id = ordd.Id, Need_To_Calculate_Tax__c = 'True'));
        }
        // Since new Order Items have been deleted, Tax should be recalculated. Set Need_To_Calculate_Tax__c to True
        if (updTaxCalcReqOrderList.size() > 0) update updTaxCalcReqOrderList;
		//----TAX LOGIC---END//
		
       // Adding records in Map for specific country processing
        for(Orderitem Od : newOrdsList) {
            if (OrdersMap.get(Od.Orderid).RecordTypeId == deOrd ) DEnewOIMap.put(Od.id, Od);
            else if (OrdersMap.get(Od.Orderid).RecordTypeId == chOrd )
            { 
                CHnewOIMap.put(Od.id, Od);
                CHnewOIList.add(Od);
            }
				else if (OrdersMap.get(Od.Orderid).RecordTypeId == atOrd ) ATnewOIMap.put(Od.id, Od);
					else if (OrdersMap.get(Od.Orderid).RecordTypeId == gbOrd ) GBnewOIMap.put(Od.id, Od);
						else if (OrdersMap.get(Od.Orderid).RecordTypeId == ieOrd ) IEnewOIMap.put(Od.id, Od);
                              else if (OrdersMap.get(Od.Orderid).RecordTypeId == distOrd ) DISTnewOIList.add(Od);
        }
         
        //Country dispatcher to process QC Hold records
        if (DEnewOIMap.size() > 0) ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(DEnewOIMap, deOrd);
		if (CHnewOIMap.size() > 0) ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(CHnewOIMap, chOrd);
		if (ATnewOIMap.size() > 0) ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(ATnewOIMap, atOrd);
		if (GBnewOIMap.size() > 0) ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(GBnewOIMap, gbOrd);
		if (IEnewOIMap.size() > 0) ClsOrderItemTriggerHandler.UpdateAuditTrackingonOrder(IEnewOIMap, ieOrd);
        if (DISTnewOIList.size() > 0) ClsOrderItemTriggerHandler.DeleteIFUOrderitem(DISTnewOIList);
     //   if (CHnewOIList.size() > 0) ClsOrderItemTriggerHandler.DeleteIFUOrderitem(CHnewOIList);
        
     }
}