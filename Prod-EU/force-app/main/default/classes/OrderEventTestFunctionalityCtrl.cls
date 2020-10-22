public class OrderEventTestFunctionalityCtrl {
    
    
    public static void testOrderEventFunctionality(){
        List<CRM_Order_Event_V1__e> lstOEvent = new List<CRM_Order_Event_V1__e>();
        List<Order> OrdList = new List<Order>();
       /*  OrdList = [SELECT Id, OrderNumber, Status FROM Order WHERE Status = 'Open' and  type like 'IE%' ] ;
       Set<Id> records = new Set<Id>{ '8011n00000KIZcTAAX','8011n00000SVOkwAAH','8011n00000KIZaEAAX','8011n00000SVOyXAAX','8011n00000KIZgwAAH',
            '8011n00000LvcEZAAZ','8011n00000PWynPAAT','8011n00000LxISqAAN','8011n00000LxIUxAAN','8011n00000KIZujAAH','8011n00000KIZxTAAX','8011n00000KIa0cAAD','8011n00000Pu6QbAAJ','8011n00000KIceTAAT','8011n00000PwZXRAA3'};
             
        List<Order> OrdList1 = new List<Order>();
        OrdList1 = [SELECT Id, OrderNumber, Status FROM Order WHERE Status = 'Open' and  type like 'DE%' and ID IN :records ] ;
        OrdList.addall(OrdList1); */
       OrdList = [SELECT Id, OrderNumber, Status FROM Order WHERE ID= '8011n00000EibbLAAR' ] ; 
        for(Order objOrder : OrdList){
            lstOEvent.add(new CRM_Order_Event_V1__e(entityType__c = 'order', version__c = '2.0', stage__c = 'pending', operation__c = 'update', eventSource__c = 'OMS', status__c = 'Activated', orderNumber__c = objOrder.OrderNumber, eventSourceID__c = objOrder.Id));
        }
                /* for(Order objOrder : [SELECT Id, OrderNumber, RecordType.Name, Status,Invoice_Status__c FROM Order WHERE Status = 'Open' LIMIT 1]){
            lstOEvent.add(new CRM_Order_Event_V1__e(entityType__c = 'order', version__c = '1.1', stage__c = 'pending', operation__c = 'update', eventSource__c = 'OMS', status__c = 'Activated', orderNumber__c = objOrder.OrderNumber, eventSourceID__c = objOrder.Id));
        } */
        List<Database.SaveResult> svrs = EventBus.publish(lstOEvent);  
        for(Integer i = 0; i < svrs.size(); i++){
            if(svrs[i].isSuccess()){
                System.debug('=========sussess===='+lstOEvent[i]);
            }else{
                System.debug('=========error===='+svrs[i].getErrors());
                ErrorUtility.LogErrorWithEvent('Publish', 'PEClsHandleOrderEvents_V12.publishOrderEvent', 'Error in publishing Order Event.',  'Order', lstOEvent[i].eventSourceID__c, 
                                               'Order Id: ' + lstOEvent[i].eventSourceID__c +' could not be published. Error: ' + svrs[i].getErrors(), lstOEvent[i].eventSourceID__c, 'Success Log', String.valueOf(lstOEvent[i]));
            }
        }
    }
    
    public static void testOrderEventupdateOrderOMS(){
        List<CRM_Order_Event_V1__e> lstOEvent = new List<CRM_Order_Event_V1__e>();
        
        for(Order objOrder : [SELECT Id, OrderNumber, RecordType.Name, Status,Invoice_Status__c FROM Order WHERE Status = 'Draft' LIMIT 2]){
            lstOEvent.add(new CRM_Order_Event_V1__e(entityType__c = 'order', version__c = '1.1', stage__c = 'confirmed', operation__c = 'create', eventSource__c = 'OMS', systemOfOrigin__c = 'crm', status__c = 'Activated', orderNumber__c = objOrder.OrderNumber, eventSourceID__c = objOrder.Id));
          system.debug('Order Event>>'+objOrder.OrderNumber);
        }
        List<Database.SaveResult> svrs = EventBus.publish(lstOEvent);  
        for(Integer i = 0; i < svrs.size(); i++){
            if(svrs[i].isSuccess()){
                System.debug('=========sussess===='+lstOEvent[i]);
            }else{
                ErrorUtility.LogErrorWithEvent('Publish', 'PEClsHandleOrderEvents_V12.publishOrderEvent', 'Error in publishing Order Event.',  'Order', lstOEvent[i].eventSourceID__c, 
                                               'Order Id: ' + lstOEvent[i].eventSourceID__c +' could not be published. Error: ' + svrs[i].getErrors(), lstOEvent[i].eventSourceID__c, 'Success Log', String.valueOf(lstOEvent[i]));
            }
        }
    }
    public static void testBulkOrderClosure(){
        List<CRM_Order_Event_V1__e> lstOEvent = new List<CRM_Order_Event_V1__e>();
        
        for(Order objOrder : [SELECT Id, OrderNumber, RecordType.Name, Status,Invoice_Status__c FROM Order WHERE Status = 'Closed' AND ((NOT RecordType.Name like 'CA%') AND (NOT RecordType.Name like 'DE%')) Order by OrderNumber LIMIT 355]){
            lstOEvent.add(new CRM_Order_Event_V1__e(entityType__c = 'order', version__c = '3.0', stage__c = 'pending', operation__c = 'update', eventSource__c = 'OMS', systemOfOrigin__c = 'crm', systemOfOriginID__c = objOrder.OrderNumber, status__c = 'closed', orderNumber__c = objOrder.OrderNumber, eventSourceID__c = objOrder.OrderNumber));
        }
        system.debug('lstOEvent size>>'+lstOEvent.size());
        List<Database.SaveResult> svrs = EventBus.publish(lstOEvent);  
        for(Integer i = 0; i < svrs.size(); i++){
            if(svrs[i].isSuccess()){
                System.debug('=========sussess===='+lstOEvent[i]);
            }else{
                system.debug('Error in publish>>'+String.valueOf(lstOEvent[i]));
                ErrorUtility.LogErrorWithEvent('Publish', 'PEClsHandleOrderEvents_V12.publishOrderEvent', 'Error in publishing Order Event.',  'Order', lstOEvent[i].eventSourceID__c, 
                                               'Order Id: ' + lstOEvent[i].eventSourceID__c +' could not be published. Error: ' + svrs[i].getErrors(), lstOEvent[i].eventSourceID__c, 'Success Log', String.valueOf(lstOEvent[i]));
            }
        }
    }
    
        public static void testBulkMixOrders(){
        List<CRM_Order_Event__e> lstOEvent = new List<CRM_Order_Event__e>();
        
       // for(Order objOrder : [SELECT Id, OrderNumber, RecordType.Name, Status,Invoice_Status__c FROM Order WHERE Status = 'Draft' AND RecordType.Name like 'CA%' Order by OrderNumber LIMIT 3]){
          
           for(Order objOrder : [SELECT Id, OrderNumber, RecordType.Name, Status,Invoice_Status__c FROM Order WHERE Status = 'Draft' AND invoice_number__C=null and invoice_date__c=null and recordtype.name like 'CA%' limit 2]){
           lstOEvent.add(new CRM_Order_Event__e(entityType__c = 'order', version__c = '1.0', stage__c = 'pending', operation__c = 'update', eventSource__c = 'OMS', systemOfOrigin__c = 'crm', systemOfOriginID__c = objOrder.OrderNumber, status__c = 'closed', orderNumber__c = objOrder.OrderNumber, eventSourceID__c = objOrder.OrderNumber));
        }
         
        for(Order objOrder : [SELECT Id, OrderNumber, RecordType.Name, Status,Invoice_Status__c FROM Order WHERE Status = 'Draft' AND RecordType.Name like 'CA%' LIMIT 2]){
            lstOEvent.add(new CRM_Order_Event__e(entityType__c = 'order', version__c = '1.0', stage__c = 'confirmed', operation__c = 'create', eventSource__c = 'OMS', systemOfOrigin__c = 'crm', status__c = 'Activated', orderNumber__c = objOrder.OrderNumber, eventSourceID__c = objOrder.Id));
          system.debug('Order Event>>'+objOrder.OrderNumber);
        }
        system.debug('lstOEvent size>>'+lstOEvent.size());
        List<Database.SaveResult> svrs = EventBus.publish(lstOEvent);  
        for(Integer i = 0; i < svrs.size(); i++){
            if(svrs[i].isSuccess()){
                System.debug('=========sussess===='+lstOEvent[i]);
            }else{
                system.debug('Error in publish>>'+String.valueOf(lstOEvent[i]));
                ErrorUtility.LogErrorWithEvent('Publish', 'PEClsHandleOrderEvents_V12.publishOrderEvent', 'Error in publishing Order Event.',  'Order', lstOEvent[i].eventSourceID__c, 
                                               'Order Id: ' + lstOEvent[i].eventSourceID__c +' could not be published. Error: ' + svrs[i].getErrors(), lstOEvent[i].eventSourceID__c, 'Success Log', String.valueOf(lstOEvent[i]));
            }
        }
    }
}