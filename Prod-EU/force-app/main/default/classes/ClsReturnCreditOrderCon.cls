/****************************************************************************
*@Description   : Gets all product SKU that are eligible for return for a return order.
Function: 1. When a return order is created, it gets all products on parent order. 
2. Gets all return orders for that parent order.
3. Calculates available quantity for each of products on original order, base don all return orders for a parent order.
4. Wraps up uinformaiton in a custom class and sends it back to caller.
****************************************************************************/
public class ClsReturnCreditOrderCon {   
	/*@AuraEnabled(Cacheable = true)
    public static List<ReturnProduct> getReturnProducts_x (String recordId) {
        List<ReturnProduct> retPrds= new List<ReturnProduct>();
    	List<Order> lstOrd=new List<Order>([Select Id, OrderNumber, RecordType.Name, Type, Status,Parent_Order__c, (Select Id, Quantity,Product2Id, Return_Reason__c, Parent_Order_Line_Id__c from OrderItems) 
        	from Order Where Id=:recordId AND Parent_Order__c !=null AND ActivatedDate = null And Type Like '%RETURN%']);
        if(!lstOrd.isEmpty()){
            Order o=lstOrd[0];
            Map<Id, OrderItem> parentOrderLines = new Map<Id, OrderItem>([Select Id, Product2Id, Product2.ProductCode, Quantity, UnitPrice, PricebookEntryId,    Return_Reason__c from OrderItem Where OrderId=:o.Parent_Order__c LIMIT 1000]);
            System.Debug('**** TPS:EH 1.1 getReturnProducts Order o=' + o);            
            //Map<Id, decimal> mapAvailableQty = getReturnedQtyByProductByOrder(o.Parent_Order__c, parentOrderLines);
            Map<String, decimal> mapAvailableQty = getReturnedQtyByProductByOrder(o.Parent_Order__c);
            System.Debug('**** TPS:EH 1.2 mapAvailableQty=' + mapAvailableQty);
            for(OrderItem oi : parentOrderLines.values()){
            	ReturnProduct rp = new ReturnProduct();
                rp.Id=oi.Id; rp.productCode=oi.Product2.ProductCode; rp.ProductId=oi.Product2Id; 
                rp.UnitPrice=oi.UnitPrice; rp.PBEId=oi.PricebookEntryId; rp.ErrorQTY='No'; rp.ErrorRR='No'; rp.ReturnReason=''; rp.ReturnQty=0;
                if(mapAvailableQty.containsKey(oi.Id)){
                	rp.AvailableQty=mapAvailableQty.get(oi.Id);   
                }
                if(o.OrderItems != null){
                    for(OrderItem oid : o.OrderItems){
                        if(oi.Id==oid.Parent_Order_Line_Id__c){
                        	rp.ReturnQty=Math.Abs(oid.Quantity);
                            rp.ReturnReason=oid.Return_Reason__c;
                            rp.OIId=oid.Id;
                        }
                    }
                }
                retPrds.Add(rp);
                System.Debug('**** TPS:EH 1.4 getReturnProducts oi=' + oi);
            }
            
        }
		System.Debug('**** TPS:EH 1.3 retPrds=' + retPrds);
        return retPrds;
    }*/
    
    @AuraEnabled(Cacheable = true)
    public static List<ReturnProduct> getReturnProducts (String recordId) {
        List<ReturnProduct> retPrds= new List<ReturnProduct>();
    	List<Order> lstOrd=new List<Order>([Select Id, OrderNumber, RecordType.Name, Type, Status,Parent_Order__c, (Select Id, Quantity,Product2Id, Return_Reason__c, Parent_Order_Line_Id__c from OrderItems) 
        	from Order Where Id=:recordId AND Parent_Order__c !=null And Type Like '%RETURN%']);
        if(!lstOrd.isEmpty()){
            Order o=lstOrd[0];
            System.Debug('**** TPS:EH 1.1 getReturnProducts Order o=' + o);            
            Map<String, decimal> mapAvailableQty = getReturnedQtyByProductByOrder(o.Parent_Order__c);
            System.Debug('**** TPS:EH 1.2 mapAvailableQty=' + mapAvailableQty);
            
            for(OrderItem oi : [Select Id, Parent_Order_Line_Id__c, Product2Id, Product2.ProductCode, Quantity, UnitPrice, PricebookEntryId, Return_Reason__c 
                                from OrderItem Where OrderId=:o.Parent_Order__c LIMIT 1000]){
            	ReturnProduct rp = new ReturnProduct();
                rp.Id=oi.Id; rp.productCode=oi.Product2.ProductCode; rp.ProductId=oi.Product2Id; 
                rp.UnitPrice=oi.UnitPrice; rp.PBEId=oi.PricebookEntryId; rp.ErrorQTY='No'; rp.ErrorRR='No'; rp.ReturnReason=''; rp.ReturnQty=0;
                rp.AvailableQty=oi.Quantity;
                string key=oi.Id + '-' + oi.Product2Id;
                if(mapAvailableQty.containsKey(key)){
                	rp.AvailableQty=oi.Quantity - mapAvailableQty.get(key);   
                }
                if(o.OrderItems != null){
                    for(OrderItem oid : o.OrderItems){
                        if(oi.Product2Id==oid.Product2Id && oi.Id==oid.Parent_Order_Line_Id__c){                        	
                            rp.ReturnQty=Math.Abs(oid.Quantity);
                            rp.ReturnReason=oid.Return_Reason__c;
                            rp.OIId=oid.Id;
                        }
                    }
                }
                retPrds.Add(rp);
                System.Debug('**** TPS:EH 1.4 getReturnProducts oi=' + oi);
            }
            
        }
		System.Debug('**** TPS:EH 1.3 retPrds=' + retPrds);
        return retPrds;
    }
    
    @AuraEnabled    
    public static List<String> getReturnReasonsList (string countryCode) {
    	List<String> lstRR= new List<String>();
        for(Order_Return_Reason__mdt rr : [Select Id, Return_Reason__c from Order_Return_Reason__mdt Where Country__c=:countryCode LIMIT 1]){
            if(rr.Return_Reason__c != null){
            	lstRR=	rr.Return_Reason__c.split(';');
            }
        }
        System.Debug('** TPS:EH getReturnReasonsList=' + lstRR);
        return lstRR;
    }
    
    /*private static Map<Id, decimal> getReturnedQtyByProductByOrder_x(Id orderId, Map<Id, OrderItem> parentOrderLines){
    	Map<Id, decimal> aggregatedLinesMap= new Map<Id, decimal>();
        Map<Id, decimal> returnMap = new Map<Id, decimal>();
        //Prepare the aggregated map for all the lines that are already returned
        for(AggregateResult aggregatedOrderDetail : [Select Parent_Order_Line_Id__c , SUM(Quantity)
            from OrderItem Where (Order.Parent_Order__c=:orderId OR OrderId=:orderId) 
            AND Order.ActivatedDate != null AND Order.Status!='Cancelled' Group By Parent_Order_Line_Id__c]){
                
            String parentOLIId = (String)aggregatedOrderDetail.get('Parent_Order_Line_Id__c');
            decimal qty = (Decimal)aggregatedOrderDetail.get('expr0');
            System.debug('## parentOLIId=' + parentOLIId);
            System.debug('## qty=' + qty );
            aggregatedLinesMap.put(parentOLIId, qty);
		}
        //For each lines included in the Parent Order find if there are any return lines already, if not, return the original qty
        for(OrderItem oi : parentOrderLines.values())
        {
            if(aggregatedLinesMap.containsKey(oi.Id))
                returnMap.put(oi.Id, oi.Quantity-Math.Abs(aggregatedLinesMap.get(oi.Id)));
            else
                returnMap.put(oi.Id, oi.Quantity);
        }
        return returnMap;
    }*/
    
    private static Map<string, decimal> getReturnedQtyByProductByOrder(Id orderId){
    	Map<string, decimal> mapRet= new Map<string, decimal>();
        for(AggregateResult aggregatedOrderDetail : [Select Parent_Order_Line_Id__c, product2Id , SUM(Quantity)
            from OrderItem Where (Order.Parent_Order__c=:orderId) 
            AND Order.ActivatedDate != null AND Order.Status!='Cancelled' AND Order.Type Like '%RETURN%' Group By Parent_Order_Line_Id__c, product2Id]){
            
            String parentOLId = (String)aggregatedOrderDetail.get('Parent_Order_Line_Id__c');    
            String productId = (String)aggregatedOrderDetail.get('product2Id');
            Decimal qty = Math.Abs((Decimal)aggregatedOrderDetail.get('expr0'));
            System.debug('## productId=' + productId);	System.debug('## parentOLId=' + parentOLId); System.debug('## qty=' + qty ); 
            string key=parentOLId + '-' + productId;
            mapRet.put(key, qty);         
		}
        return mapRet;
    }
    
    @AuraEnabled
    public static List<ReturnProduct> SaveReturnQty(string srcCCData, Id orderId){        
        List<ReturnProduct> lstSrc= (List<ReturnProduct>)System.JSON.deserialize(string.valueOf(srcCCData), List<ReturnProduct>.Class);
        Map<Id, ReturnProduct> mapData=new Map<Id, ReturnProduct>();
        for(ReturnProduct rp : lstSrc){
        	mapData.put(rp.Id, rp);
        }
        System.Debug('**** TPS:EH 1.1 SaveReturnQty mapData=' + mapData);       
        
        List<OrderItem> lstOI= new List<OrderItem>();	List<OrderItem> lstOIDel= new List<OrderItem>();
        set<string> setOIDel= new set<string>(); set<Id> setQtyToRemove= new set<Id>();
        for(Id oiId : mapData.KeySet()){
        	ReturnProduct rp=mapData.get(oiId);
            System.Debug('**** TPS:EH 1.2 SaveReturnQty rp=' + rp);
            decimal retQty=rp.AvailableQty - Math.Abs(rp.ReturnQty);
            if(retQty>=0){
            	OrderItem oi=new OrderItem();   
                oi.OrderId=orderId; 
                if(rp.OIId!= null){
                	oi.Id=rp.OIId;   
                }                 
                oi.Quantity=-Math.Abs(rp.ReturnQty);
                oi.UnitPrice=rp.UnitPrice;
                if(oi.Id== null){
                	oi.Product2Id=rp.ProductId;
                    oi.PricebookEntryId=rp.PBEId;
                }
                oi.Return_Reason__c=rp.ReturnReason;
                oi.Parent_Order_Line_Id__c=oiId;
                
                if(Math.Abs(rp.ReturnQty)>0){
                	lstOI.Add(oi);    
                }
                System.Debug('**** TPS:EH 1.3 SaveReturnQty oi=' + oi);
            }
                
            /* If a user send return qty=0, then delete that order item record. */
            if(rp.ReturnQty==0 && rp.OIId!=null){
            	setOIDel.Add(rp.OIId);
                setQtyToRemove.Add(oiId);
            }
        }
        
        System.Debug('**** TPS:EH 1.4 SaveReturnQty setOIDel=' + setOIDel);
        if(setOIDel.size()>0){
            Map<Id, OrderItem> mapOIDel= new Map<Id, OrderItem>([Select Id from OrderItem Where Id IN :setOIDel]);
            System.Debug('**** TPS:EH 1.5 SaveReturnQty mapOIDel=' + mapOIDel);
            Database.Delete(mapOIDel.values());
            for(Id idRemove : setQtyToRemove){
            	mapData.get(idRemove).ReturnQty=0;
            }
        }
        
        System.Debug('**** TPS:EH 1.6 SaveReturnQty lstOI=' + lstOI);
        try{            
        	upsert lstOI;
            for(OrderItem oi : lstOI){
                for(ReturnProduct rp : mapData.Values()){
                    if(oi.Id!= null){
                    	rp.OIId=oi.Id;    
                    }  
                }
            }
        } catch (DmlException e) {
        	throw new RGAException(e.getMessage());    
        }
        
        /*Schema.SObjectField f = OrderItem.Fields.External_Id__c;		
        Database.UpsertResult[] srList = Database.upsert(lstOI, f, false);
        for (Database.UpsertResult sr : srList) {
        	if (sr.isSuccess()) {
            	return mapData.values();    
            }else {
            	for(Database.Error err : sr.getErrors()) {
                	System.debug('fields that affected this error: ' + err.getFields());                    
                    throw new RGAException(err.getMessage());
                }
            }
        }*/
    	//return mapData.values();
        return getReturnProducts(orderId);
    }    
   
    public class ReturnProduct {
        @AuraEnabled public Boolean selected;
        @AuraEnabled public Id Id;
		@AuraEnabled public String ProductCode;
		@AuraEnabled public Id ProductId;        
		@AuraEnabled public decimal AvailableQty;
		@AuraEnabled public decimal ReturnQty;
        @AuraEnabled public decimal UnitPrice;
        @AuraEnabled public Id PBEId;
        @AuraEnabled public Id OIId;
		@AuraEnabled public String ReturnReason;
        @AuraEnabled public String errorQTY;
        @AuraEnabled public String errorRR;
        public ReturnProduct(){}
	}
	public class RGAException extends Exception {}

}