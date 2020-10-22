@isTest global class  ClsMockHttpResponseGenCCSettle implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
    	// Create a fake response
    	HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"clientReferenceInformation":{"code":"1574305483265"},"id":"5743054832936976804005","orderInformation":{"amountDetails":{"totalAmount":"10.00","currency":"CHF"}},"reconciliationId":"75946761","status":"PENDING","submitTimeUtc":"2019-11-21T03:04:43Z","_links":{"self":{"href":"/pts/v2/captures/5743054832936976804005","method":"GET"},"refund":{"href":"/pts/v2/captures/5743054832936976804005/refunds","method":"POST"},"void":{"href":"/pts/v2/captures/5743054832936976804005/voids","method":"POST"}}}');
        res.setStatusCode(200);
        return res;
    }
}