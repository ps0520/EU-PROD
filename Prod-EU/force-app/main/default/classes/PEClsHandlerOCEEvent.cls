public class PEClsHandlerOCEEvent {
    public static void publishOCEAccOrderEvent(String OCEOrderRefNumber,String OrderNumber,String ordStatus,String OrdtrackingNumber,String IntegrationStatus,String IntegrationMsg){
        System.debug('**SPEOUT--OCE OutEvent Publish Method Call--');
        try{
            Sample_Order_Response_Event__e evtOut = new Sample_Order_Response_Event__e();            
            evtOut.OCEOrderReference__c = OCEOrderRefNumber;
            evtOut.OrderNumber__c = OrderNumber;
            evtOut.OrderStatus__c = ordStatus;                        
            evtOut.TrackingUrl__c = OrdtrackingNumber;
            evtOut.IntegrationErrorMessage__c = IntegrationMsg;
            evtOut.IntegrationStatus__c = IntegrationStatus;            
            Database.SaveResult svrs = EventBus.publish(evtOut);
            if(svrs.isSuccess()){
                System.debug('**SPEOUT--Event Published Successfully');
                ErrorUtility.LogError('Publish', 'PEClsHandlerOCEEvent', 'Writing Event into OCE Out Channel', 'Order', 'crm', 'Succesfully published Event', evtOut.OCEOrderReference__c, 'Success Log');
            }else{
                System.debug('**SPEOUT--Event Failed to Published ');
                ErrorUtility.LogErrorWithEvent('Publish', 'PEClsHandlerOCEEvent','Writing Event into OCE Out Channel', 'Order', 'crm', 'Failed to Publish Event. Error: ' + svrs.getErrors(), evtOut.OrderNumber__c, 'Fatal Error - Bailing out', String.valueOf(evtOut));
            }
        }catch(Exception ex){
            System.debug('**SPEOUT--Error--'+ex);
            System.debug('**SPEOUT--ErrorLine--'+ex.getLineNumber());            
        }       
    }
}