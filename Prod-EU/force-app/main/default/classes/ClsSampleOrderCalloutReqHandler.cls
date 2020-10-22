public class ClsSampleOrderCalloutReqHandler  {//implements Queueable, Database.AllowsCallouts
   
    private String jsonOutEvtString;
    //public  Sample_Order_Response_Event__e OCESampleRequest;
    public ClsSampleOrderCalloutReqHandler(List<Sample_Order_Response_Event__e> lstOCEevt){
        //String jsonStr = JSON.serialize(LstOCEevt[0]);
        //String jsonStr = JSON.serialize(new WrapSampleOutEvnt(lstOCEevt[0]));
        String jsonStr = createJson(lstOCEevt[0]);
        System.debug('**OCE--jsonStr-->'+jsonStr);
        this.jsonOutEvtString = jsonStr;
        //makeOCECallOut(jsonStr);
        System.enqueueJob(new makeOCECallOut(jsonStr));
        return;
    }
    String createJson(Sample_Order_Response_Event__e evt) {
        String js = '{';
        if (String.isNotBlank(evt.OCEOrderReference__c)) js = jsonField(js, 'OCEOrderReference__c', evt.OCEOrderReference__c);
        if (String.isNotBlank(evt.OrderNumber__c)) js = jsonField(js+', ', 'OrderNumber__c', evt.OrderNumber__c);
        if (String.isNotBlank(evt.OrderStatus__c)) js = jsonField(js+', ', 'OrderStatus__c', evt.OrderStatus__c);
        if (String.isNotBlank(evt.TrackingUrl__c)) js = jsonField(js+', ', 'TrackingUrl__c', evt.TrackingUrl__c);
        if (String.isNotBlank(evt.IntegrationStatus__c)) js = jsonField(js+', ', 'IntegrationStatus__c', evt.IntegrationStatus__c);
        if (String.isNotBlank(evt.IntegrationErrorMessage__c)) js = jsonField(js+', ', 'IntegrationErrorMessage__c', evt.IntegrationErrorMessage__c);
        js = js + '}';
        return js;
    }
    String jsonField(String inString, String field, String value) {
        return ( inString + '\"'+ field +'\":\"' + value + '\"');
    }
    public class makeOCECallOut implements Queueable, Database.AllowsCallouts{
        public String OCESampleRequest;
        public makeOCECallOut(String OCESampleRequest){
            this.OCESampleRequest = OCESampleRequest;
        }
        public void execute(QueueableContext context) {
            String responsebody = '';
            try{
                System.debug('**OCE--Request Body is-->' + OCESampleRequest);
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:OCEOrderInfo/services/data/v49.0/sobjects/OCE_DTP_INBOUND__e');
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('Authorization', 'BASIC {!$Credential.AuthorizationHeaderValue}');
                request.setBody(OCESampleRequest);
                request.setTimeout(20000); 
                HttpResponse response = http.send(request);
                System.debug('**OCE-response======='+response);
                if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
                    responsebody =  response.getBody();
                    ErrorUtility.LogErrorwithEvent('Publish', 'ClsSampleOrderCalloutReqHandler', 'Publishing response to OCE', 'Order', 'crm', 'Published Order status with Response Code 200/201', '', 'Informational', OCESampleRequest);
                }else if(response.getStatusCode() == 302){
                    System.debug('**OCE--Header--'+response.getHeader('Location'));
                    ErrorUtility.LogError('Publish', 'ClsSampleOrderCalloutReqHandler', 'Publishing response to OCE', 'Order', 'crm', 'Published Order status received response code 302. Will retry.', '', 'Success Log');
                    request.setEndpoint(response.getHeader('Location'));
                    response = new Http().send(request); 
                    if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
                        responsebody =  response.getBody();
                        ErrorUtility.LogError('Publish', 'ClsSampleOrderCalloutReqHandler', 'Publishing response to OCE', 'Order', 'crm', 'Published Order status after 302 and received Response Code 200.', '', 'Success Log');
                    } else {
                        ErrorUtility.LogErrorwithEvent('Publish', 'ClsSampleOrderCalloutReqHandler', 'Error in publishing response to OCE', 'Order', 'crm', 'Received Response after 302 redirection: ' + response.getStatus(), '', 'Fatal Error - Bailing out', OCESampleRequest);
                    }
                }else{
                    ErrorUtility.LogErrorwithEvent('Publish', 'ClsSampleOrderCalloutReqHandler', 'Error in publishing response to OCE', 'Order', 'crm', 'Received Response when performed a http post: ' + response.getStatus() + ', Response Code: '  + response.getStatusCode() + ', Response body: ' + response.getBody(), '', 'Fatal Error - Bailing out', OCESampleRequest);
                    return;
                }
                
                
            }catch(Exception ex){
                System.debug('****OCE--ErrLine--'+ex.getLineNumber());
                System.debug('****OCE--ErrMsg--'+ex.getMessage());
                ErrorUtility.LogErrorwithEvent('Publish', 'ClsSampleOrderCalloutReqHandler', 'Error in publishing response to OCE', 'Order', 'crm', ex.getMessage(), '', 'Fatal Error - Bailing out', OCESampleRequest);
            }
        }
    }
}