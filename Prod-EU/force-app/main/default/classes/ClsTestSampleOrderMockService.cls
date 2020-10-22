public class ClsTestSampleOrderMockService implements HttpCalloutMock{
protected Integer code;
  protected String status;
  protected String body;
  protected Map<String, String> responseHeaders;
  
  public ClsTestSampleOrderMockService(String status) {
    //String resBody = '{"TaxSummary":[{"TaxType":"GST","TaxRate":"5","TaxAmount":"0"},{"TaxType":"HST","TaxRate":"2","TaxAmount":"0"},{"TaxType":"PST","TaxRate":"3","TaxAmount":"0"}],"TaxDetails":[{"LineId":"'+LineId+'","ReferenceLineId":"","Price":"0","Quantity":"1","Sku":"STK-GF-013","TaxType":"GST","TaxAmount":"0"}],"ErrorMessage":""}';  
    String responseBody = '{"OCEOrderReference__c" : "01234sfsfgweer","OrderNumber__c" : "12314124213","OrderStatus__c" : "Created","TrackingUrl__c" : "","IntegrationStatus__c" = "","IntegrationErrorMessage__c" : ""}';
    this.status = status;
    this.body =responseBody;
    this.code = 200;
    
   // this.responseHeaders = responseHeaders;
  }
  public ClsTestSampleOrderMockService() {
        //String resBody = '{"TaxSummary":[{"TaxType":"GST","TaxRate":"5","TaxAmount":"0"},{"TaxType":"HST","TaxRate":"2","TaxAmount":"0"},{"TaxType":"PST","TaxRate":"3","TaxAmount":"0"}],"TaxDetails":[{"LineId":"'+LineId+'","ReferenceLineId":"","Price":"0","Quantity":"1","Sku":"STK-GF-013","TaxType":"GST","TaxAmount":"0"}],"ErrorMessage":""}';  
        String responseBody = '{"OCEOrderReference__c" : "01234sfsfgweer","OrderNumber__c" : "12314124213","OrderStatus__c" : "Created","TrackingUrl__c" : "","IntegrationStatus__c" = "","IntegrationErrorMessage__c" : ""}';
        this.status = 'OK';
        this.body =responseBody;
        this.code = 302;
        
        // this.responseHeaders = responseHeaders;
  }
  
  public HTTPResponse respond(HTTPRequest req) {
    HttpResponse res = new HttpResponse();
    res.setBody(String.valueOf(this.body));
    res.setStatusCode(this.code);
    res.setStatus(this.status);
    return res;
  }
}