/*******************************************************************************************************************
@Description    : OrderItem trigger handler to process orderitem updates
********************************************************************************************************************/   
public class ClsOrderItemTriggerHandler{
    
    //Map, which will be used for updates on Order object
    static Map<Id, Order> orderIdToOrderMap = new Map<Id, Order>();
    static Map<Id, OrderItem> orderItemIdToOrderItemMap = new Map<Id, OrderItem>();
    static boolean isExecuting = false;

    // This Method Updates Related Audit Records If any Changes are made to OrderItems                
    public static void UpdateAuditTrackingonOrder(map<Id,OrderItem> OrderItems, String recordTypeId){
		Set<Id> orderIds = new set<Id>();
        List<Audit_Tracker__c> lstUpdOrderAudits = new List<Audit_Tracker__c>();
		for(OrderItem oi : [SELECT Id,OrderId FROM OrderItem WHERE Id IN :OrderItems.keyset() AND Order.Shipping_Hold_status__c = 'In Progress']) orderIds.add(oi.Orderid);
		if(!orderIds.isEmpty()){
			//Look out for all audit trackers which have Product as verified and then we have to un-verify them
			for(Audit_Tracker__c at: [SELECT Id, Audit_Field_Name__c, Field_Verified__c FROM Audit_Tracker__c WHERE  Object_Id__c in : orderIds AND Audit_Field_Name__c = 'Products'AND Field_Verified__c = true]){
				at.Field_Verified__c = false;
				lstUpdOrderAudits.add(at);
			}
		}
		if(!lstUpdOrderAudits.isEmpty()) update lstUpdOrderAudits;  	
    }
    
     // This Method insert Orderitem Records If any SKU OrderItems added               
    public static void InsertIFUOrderitem(map<Id,OrderItem> OrderItems){
        Set<Id> orderIds = new set<Id>();
		Set<Id> PBIds = new set<Id>();
        List<String> OItemProductList = new List<String>();             
        List<OrderItem> NewOItemList = new List<OrderItem>();
        List<PricebookEntry> PBEItemList = new List<PricebookEntry>();        
        Map<id, String> allPBName = new Map<id, String>();       
        for(OrderItem oi : [SELECT Id, OrderId, Order.Pricebook2Id, Product2.name FROM OrderItem WHERE Id IN :OrderItems.keyset() ])
        {
            OItemProductList.add(oi.Product2.name) ;
            PBIds.add(oi.Order.Pricebook2Id); 
            orderIds.add(oi.OrderId); 
        }
         //Fetching all the PB name associated with the Order(s). 
        for(Order ord:[Select Id, Pricebook2.name from Order where id in :orderIds] ){
            allPBName.put(ord.id, ord.Pricebook2.name);
        }
        List<IFU_Mapping__mdt> IFUList = [SELECT IFU__c, SKU__c, Type__c, Pricebook__c FROM IFU_Mapping__mdt where SKU__c IN : OItemProductList];  
        for(PricebookEntry pbe : [select id, Name, UnitPrice, Pricebook2Id from PricebookEntry where Pricebook2Id IN :PBIds] )   PBEItemList.add(pbe); 
        for(OrderItem oi : [SELECT Id, OrderId, Order.type, Order.Pricebook2Id, Product_Name__c, Quantity, Product2.name FROM OrderItem WHERE Id IN :OrderItems.keyset() ]) 
        {            
            for(PricebookEntry PBE :PBEItemList){
                if(PBE.Pricebook2Id == oi.Order.Pricebook2Id)
                {
                    for(IFU_Mapping__mdt ifu :IFUList)
                    {
                        if(ifu.IFU__c == PBE.Name && ifu.SKU__c == oi.Product2.name && ifu.Type__c == oi.Order.type && ifu.Pricebook__c == allPBName.get(oi.OrderId) )
                        {
                            OrderItem item = new OrderItem();
                            item.Product2Id = PBE.Id ;
                            item.OrderId = oi.OrderId ;
                            item.Quantity = oi.Quantity ;
                            item.UnitPrice = PBE.UnitPrice;
                            NewOItemList.add(item);
                        }  
                    }
                }                
            }
        }
        if(!NewOItemList.isEmpty()) insert NewOItemList;  	
    }
    
    // This Method update IFU Orderitem Records If sku items are updated 
    public static void UpdateIFUOrderitem(List<OrderItem> NewOrdIList, map<Id,OrderItem> OldOrderItems){
		Set<Id> orderIds = new set<Id>();   
        List<OrderItem> updateOItemList = new List<OrderItem>();
        List<String> OItemProductList = new List<String>();  
        Map<id, String> allPBName = new Map<id, String>();
        for(OrderItem oi : NewOrdIList) 
        { 
            OItemProductList.add(oi.Product_Name__c) ;
            orderIds.add(oi.OrderId); 
        }    
         //Fetching all the PB name associated with the Order(s). 
        for(Order ord:[Select Id, Pricebook2.name from Order where id in :orderIds] ){
            allPBName.put(ord.id, ord.Pricebook2.name);
        }
        //Fetching all the lineItems associated with the Order(s). 
        List<OrderItem> allLineItems = [Select Id, Product_Name__c, Quantity, OrderId from OrderItem where orderid in :orderIds];
        List<IFU_Mapping__mdt> IFUList = [SELECT IFU__c, SKU__c, Type__c, Pricebook__c FROM IFU_Mapping__mdt where SKU__c IN : OItemProductList];         
        for(OrderItem oi : NewOrdIList) 
        {            
            if(oi.Quantity != OldOrderItems.get(oi.id).Quantity)
            {
                for(IFU_Mapping__mdt ifu :IFUList)
                {
                    if(ifu.SKU__c == oi.Product_Name__c && ifu.Pricebook__c == allPBName.get(oi.OrderId))
                    {
                        for(OrderItem ordi: allLineItems) {
                            if ( ordi.Product_Name__c == ifu.IFU__c && ordi.OrderId == oi.OrderId)
                            {
                                if((OldOrderItems.get(oi.id).Quantity - oi.Quantity) > 0)
                                {
                                    ordi.Quantity = ordi.Quantity - (OldOrderItems.get(oi.id).Quantity - oi.Quantity) ;
                                }else
                                {
                                    ordi.Quantity = ordi.Quantity + (oi.Quantity - OldOrderItems.get(oi.id).Quantity) ;
                                }
                                updateOItemList.add(ordi);
                            }
                        }
                    }
                }
            }
        }
        if(!updateOItemList.isEmpty()) update updateOItemList;  	
    }
    
    // This Method delete IFU Orderitem Records              
    public static void DeleteIFUOrderitem(List<OrderItem> NewOrderIList){
		Set<Id> orderIds = new set<Id>();     
        List<String> OItemProductList = new List<String>(); 
        Map<id, String> allPBName = new Map<id, String>();
        for(OrderItem oi : NewOrderIList) 
        { 
            OItemProductList.add(oi.Product_Name__c) ;
            orderIds.add(oi.OrderId);
        }   
        //Fetching all the lineItems associated with the Order(s). 
        List<OrderItem> allLineItems = [Select Id, Product_Name__c, Quantity, OrderId from OrderItem where orderid in :orderIds];
        List<IFU_Mapping__mdt> IFUList = [SELECT IFU__c, SKU__c, Type__c, Pricebook__c FROM IFU_Mapping__mdt where SKU__c IN :OItemProductList];
        List<OrderItem> DelOItemList = new List<OrderItem>(); 
         //Fetching all the PB name associated with the Order(s). 
        for(Order ord:[Select Id, Pricebook2.name from Order where id in :orderIds] ){
            allPBName.put(ord.id, ord.Pricebook2.name);
        }
        for(OrderItem oi : NewOrderIList) 
        {  
            for(IFU_Mapping__mdt ifu :IFUList)
            {
                if(ifu.SKU__c == oi.Product_Name__c  && ifu.Pricebook__c == allPBName.get(oi.OrderId))
                {
                    for(OrderItem ordi: allLineItems) {
                        if ( ordi.Product_Name__c == ifu.IFU__c && ordi.OrderId == oi.OrderId)
                        {
                            DelOItemList.add(ordi);
                        }
                    }
                }
            }            
        }
        if(!DelOItemList.isEmpty()) delete DelOItemList;  	
    }
    
    //Method will group the Order by Id and updates the tracking number
    public static void UpdateTrackingNumberOnOrder (Map<Id, OrderItem> newTriggerOrderItems, Map<Id, OrderItem> oldTriggerOrderItems)
    {
        // Avoid Recursion - If this logic was executed during the same context  
        if(ClsOrderTriggerStaticClass.isExecuting)
            return;
        ClsOrderTriggerStaticClass.isExecuting = true;
        
        //Loop through each order items and find the ones where there was a change in Tracking number and then group the orders to do a final update
        for(OrderItem newOrderItem : newTriggerOrderItems.values())
        {
            Id orderId = newOrderItem.OrderId;
            Order parentOrder = new Order(id=orderId);
            OrderItem oldOrderItem = oldTriggerOrderItems.get(newOrderItem.Id);
            if(oldOrderItem.Tracking_Number__c != newOrderItem.Tracking_Number__c && newOrderItem.Is_Virtual_Product__c == false)
            {
                system.debug('*******************Tracking number time');
                parentOrder.Tracking_Number__c = newOrderItem.Tracking_Number__c;
                orderIdToOrderMap.put(orderId, parentOrder);
            }
            if(oldOrderItem.Serial_Number__c != newOrderItem.Serial_Number__c && newOrderItem.Product_Name__c != null && newOrderItem.Product_Name__c.contains('STK') )
           {
                system.debug('*******************Serial number time');
                parentOrder.Serial_Number__c = newOrderItem.Serial_Number__c;
                if(newOrderItem.Serial_Number__c != null)
                {
                
                    orderIdToOrderMap.put(orderId, parentOrder);
            
                }
            }    
        }
        //Update virtual SKUs if any exist for the Orders
        for(OrderItem virtualItem : [SELECT Id, OrderId, Tracking_Number__c FROM OrderItem WHERE OrderId IN : orderIdToOrderMap.keySet() AND Is_Virtual_Product__c = True])
        {
            virtualItem.Tracking_Number__c = orderIdToOrderMap.get(virtualItem.OrderId).Tracking_Number__c;
            orderItemIdToOrderItemMap.put(virtualItem.Id, virtualItem);
            system.debug('virutalItem Id is ' + virtualItem.Id);
        }
        //Update the Virtual order lines
        system.debug('Entering process to update the Virutal items');
        if(!orderItemIdToOrderItemMap.isEmpty())
        {
            try{update orderItemIdToOrderItemMap.values();}
            catch(DMLException de)
            {
                Integer numErrors = de.getNumDML();
                System.debug('getNumDml=' + numErrors);
                for(Integer i=0; i<numErrors; i++)
                {
                    System.debug('getDMLFieldNames=' + de.getDMLFieldNames(i));
                    System.debug('getDMLFieldNames=' + de.getDMLMessage(i));
                }
            }
        }
        
        //Update the Orders
        system.debug('Entering process to update the Orders');
        if(!orderIdToOrderMap.isEmpty())
        {
            try{update orderIdToOrderMap.values();}
            catch(DMLException de)
            {
                Integer numErrors = de.getNumDML();
                System.debug('getNumDml=' + numErrors);
                for(Integer i=0; i<numErrors; i++)
                {
                    System.debug('getDMLFieldNames=' + de.getDMLFieldNames(i));
                    System.debug('getDMLFieldNames=' + de.getDMLMessage(i));
                }
            }
        }
    }
}