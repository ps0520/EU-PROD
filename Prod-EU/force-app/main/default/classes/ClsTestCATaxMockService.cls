@isTest
public class ClsTestCATaxMockService implements HttpCalloutMock {
  protected Integer code;
  protected String status;
  protected String body;
  protected Map<String, String> responseHeaders;
  //To Cover Happy Path
  public ClsTestCATaxMockService(Integer code, String status, String body, Map<String, String> responseHeaders,String LineId) {
    String resBody = '{"TaxSummary":[{"TaxType":"GST","TaxRate":"5","TaxAmount":"0"},{"TaxType":"HST","TaxRate":"2","TaxAmount":"0"},{"TaxType":"PST","TaxRate":"3","TaxAmount":"0"}],"TaxDetails":[{"LineId":"'+LineId+'","ReferenceLineId":"","Price":"0","Quantity":"1","Sku":"STK-GF-013","TaxType":"GST","TaxAmount":"0"}],"ErrorMessage":""}';  
    this.code = code;
    this.status = status;
    this.body =resBody;
    this.responseHeaders = responseHeaders;
  }
  // To Cover ErrorMessage
  public ClsTestCATaxMockService(Integer code, String status, String body, Map<String, String> responseHeaders,String LineId,String errorMsg) {
    String resBody = '{"TaxSummary":[{"TaxType":"GST","TaxRate":"5","TaxAmount":"0"},{"TaxType":"HST","TaxRate":"2","TaxAmount":"0"},{"TaxType":"PST","TaxRate":"3","TaxAmount":"0"}],"TaxDetails":[{"LineId":"8020Q0000020r4KQAQ","ReferenceLineId":"","Price":"0","Quantity":"1","Sku":"STK-GF-013","TaxType":"GST","TaxAmount":"0"}],"ErrorMessage":""}';  
    this.code = code;
    this.status = status;
    this.body =resBody;
    this.responseHeaders = responseHeaders;
  }  
    
  public HTTPResponse respond(HTTPRequest req) {
    HttpResponse res = new HttpResponse();
    for (String key : this.responseHeaders.keySet()) {
      res.setHeader(key, this.responseHeaders.get(key));
    }
    res.setBody(String.valueOf(this.body));
    res.setStatusCode(this.code);
    res.setStatus(this.status);
    return res;
  }
}