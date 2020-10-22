/***********************************************************************************************************
@Description : Class handles all logic related to adding IFUs for the Orders having Receiver or Transmitter
************************************************************************************************************/
public class ClsCHProcessIFUsForOrders {
    /****************************************
List of IFUs by Receiver for CH
STK-GS-013	G6 OUS Receiver Kit mg/dl	
MT25313
MT25315
MT25311
STK-GS-109	G6 OUS Receiver Kit mmol/l	
MT25314
MT25316
MT25332	
****************************************/
    //Method will process the Order for inserting the relevant IFUs
    public static void handleG6ReceiverIFUsOnInsert(Set<Id> orderIds) {
        Map<Id, Id> orderIdToPbIdMap = new Map<Id, Id>(); 
        Map<String, String> pbProductToPBEId = new Map<String, String>();
        List<OrderItem> orderItemsToBeInserted = new List<OrderItem>();
        Set<Id> mgOrderSet = new Set<Id>();
        Set<Id> MT25313_ordSet = new Set<Id>();
        Set<Id> MT25315_ordSet = new Set<Id>();
        Set<Id> MT25311_ordSet = new Set<Id>();
        Set<Id> mmolOrderSet = new Set<Id>();
        Set<Id> MT25314_ordSet = new Set<Id>();
        Set<Id> MT25316_ordSet = new Set<Id>();
        Set<Id> MT25332_ordSet = new Set<Id>();
        
        //Find all Order lines tied the Orders that are to be processed
        for(OrderItem oli : [SELECT Id, OrderId, Order.Pricebook2Id, Product_Name__c, Pricebookentryid FROM OrderItem WHERE OrderId IN : orderIds]){
            system.debug('******Enter process to handle the Orders');
            //mg/dl related logic to verify if relevant IFUs are already present in the Order, so we dont insert it again
            if(oli.Product_Name__c == 'STK-GS-013') mgOrderSet.add(oli.OrderId);
            if(oli.Product_Name__c == 'MT25313') MT25313_ordSet.add(oli.OrderId);
            if(oli.Product_Name__c == 'MT25315') MT25315_ordSet.add(oli.OrderId);
            if(oli.Product_Name__c == 'MT25311') MT25311_ordSet.add(oli.OrderId);
            //mmol/l related logic to verify if relevant IFUs are already present in the Order, so we dont insert it again
            if(oli.Product_Name__c == 'STK-GS-109') mmolOrderSet.add(oli.OrderId);
            if(oli.Product_Name__c == 'MT25314') MT25314_ordSet.add(oli.OrderId);
            if(oli.Product_Name__c == 'MT25316') MT25316_ordSet.add(oli.OrderId);
            if(oli.Product_Name__c == 'MT25332') MT25332_ordSet.add(oli.OrderId);
            //map to hold Order Id to Pricebook mapping
            orderIdToPbIdMap.put(oli.OrderId, oli.Order.Pricebook2Id);
        }
        //If there are any orders, which have Receiver SKUs to be processed then proceed
        if(!mgOrderSet.isEmpty() || !mmolOrderSet.isEmpty()){
            List<String> ifus = new list<String> { 'MT25313' , 'MT25315' , 'MT25311', 'MT25314' , 'MT25316' , 'MT25332'};//List of IFUs to lookout
                for(PricebookEntry pbe : [SELECT Id, Pricebook2Id, Product2.Name FROM PricebookEntry WHERE Pricebook2.Id IN :orderIdToPbIdMap.values() AND Product2.Name IN : ifus]){
                    pbProductToPBEId.put(pbe.Pricebook2Id+'-'+pbe.Product2.Name, pbe.Id);//Prepare the map between PBId+SKU to PBEId
                }
            //Process inserts for mg/dl Receiver
            for(Id mgId : mgOrderSet){
                if(!MT25313_ordSet.contains(mgId)){
                    if(orderIdToPbIdMap.get(mgId)+'-MT25313' != null){
                        OrderItem MT25313_ordItem = new OrderItem(OrderId = mgId, Pricebookentryid = pbProductToPBEId.get(orderIdToPbIdMap.get(mgId)+'-MT25313'), Quantity=1, UnitPrice=0, Product_Added_By_Admin__c = true);
                        orderItemsToBeInserted.add(MT25313_ordItem);
                    }
                }
                if(!MT25315_ordSet.contains(mgId)){
                    if(orderIdToPbIdMap.get(mgId)+'-MT25315' != null){
                        OrderItem MT25315_ordItem = new OrderItem(OrderId = mgId, Pricebookentryid = pbProductToPBEId.get(orderIdToPbIdMap.get(mgId)+'-MT25315'), Quantity=1, UnitPrice=0, Product_Added_By_Admin__c = true);
                        orderItemsToBeInserted.add(MT25315_ordItem);
                    }
                }
                if(!MT25311_ordSet.contains(mgId)){
                    if(orderIdToPbIdMap.get(mgId)+'-MT25311' != null){
                        OrderItem MT25311_ordItem = new OrderItem(OrderId = mgId, Pricebookentryid = pbProductToPBEId.get(orderIdToPbIdMap.get(mgId)+'-MT25311'), Quantity=1, UnitPrice=0, Product_Added_By_Admin__c = true);
                        orderItemsToBeInserted.add(MT25311_ordItem);
                    }
                }
            }
            //Process inserts for mg/dl Receiver
            for(Id mgId : mmolOrderSet){
                if(!MT25314_ordSet.contains(mgId)){
                    if(orderIdToPbIdMap.get(mgId)+'-MT25314' != null){
                        system.debug('******orderIdToPbIdMap.get(mgId)+-MT25314' + orderIdToPbIdMap.get(mgId)+'-MT25314');
                        OrderItem MT25314_ordItem = new OrderItem(OrderId = mgId, Pricebookentryid = pbProductToPBEId.get(orderIdToPbIdMap.get(mgId)+'-MT25314'), Quantity=1, UnitPrice=0, Product_Added_By_Admin__c = true);
                        orderItemsToBeInserted.add(MT25314_ordItem);
                    }
                }
                if(!MT25316_ordSet.contains(mgId)){
                    system.debug('******orderIdToPbIdMap.get(mgId)+-MT25316_ordSet' + orderIdToPbIdMap.get(mgId)+'-MT25316_ordSet');
                    if(orderIdToPbIdMap.get(mgId)+'-MT25316' != null){
                        OrderItem MT25316_ordItem = new OrderItem(OrderId = mgId, Pricebookentryid = pbProductToPBEId.get(orderIdToPbIdMap.get(mgId)+'-MT25316'), Quantity=1, UnitPrice=0, Product_Added_By_Admin__c = true);
                        orderItemsToBeInserted.add(MT25316_ordItem);
                    }
                }
                if(!MT25332_ordSet.contains(mgId)){
                     system.debug('******orderIdToPbIdMap.get(mgId)+-MT25332_ordSet' + orderIdToPbIdMap.get(mgId)+'-MT25332_ordSet');
                    if(orderIdToPbIdMap.get(mgId)+'-MT25332' != null){
                        OrderItem MT25332_ordItem = new OrderItem(OrderId = mgId, Pricebookentryid = pbProductToPBEId.get(orderIdToPbIdMap.get(mgId)+'-MT25332'), Quantity=1, UnitPrice=0, Product_Added_By_Admin__c = true);
                        orderItemsToBeInserted.add(MT25332_ordItem);
                    }
                }
            }
            //Insert Order Lines
            if (!orderItemsToBeInserted.isEmpty()) insert orderItemsToBeInserted;
            
        }
    }
    
    //Method will process the Order for inserting the relevant IFUs
    public static void handleG6ReceiverIFUsOnDelete(Set<Id> orderIds) {
        List<OrderItem> orderItemsToBeDeleted = new List<OrderItem>();
        List<String> ifus = new list<String> { 'MT25313' , 'MT25315' , 'MT25311', 'MT25314' , 'MT25316' , 'MT25332'};//List of IFUs to lookout
            for(OrderItem oli : [SELECT Id FROM OrderItem WHERE OrderId IN : orderIds AND Product_Name__c IN : ifus]) orderItemsToBeDeleted.add(oli);
        //Delete Order Lines
        if (!orderItemsToBeDeleted.isEmpty()) delete orderItemsToBeDeleted;
    }
}