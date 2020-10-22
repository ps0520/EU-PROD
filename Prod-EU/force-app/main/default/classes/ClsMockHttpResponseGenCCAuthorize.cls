@isTest global class  ClsMockHttpResponseGenCCAuthorize implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
    	// Create a fake response
    	HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"clientReferenceInformation":{"code":"00319750"},"id":"5743030750216526004001","orderInformation":{"amountDetails":{"authorizedAmount":"10.00","currency":"CHF"}},"paymentAccountInformation":{"card":{"type":"001"}},"paymentInformation":{"tokenizedCard":{"type":"001"}},"processorInformation":{"merchantNumber":"000123456789012","approvalCode":"831000","transactionId":"016150703802094","transactionID":"016150703802094","responseCode":"00","avs":{"code":"Y","codeRaw":"Y"}},"reconciliationId":"RKSA92YU9KO9","status":"AUTHORIZED","submitTimeUtc":"2019-11-21T02:24:35Z","_links":{"self":{"href":"/pts/v2/payments/5743030750216526004001","method":"GET"},"authReversal":{"href":"/pts/v2/payments/5743030750216526004001/reversals","method":"POST"},"capture":{"href":"/pts/v2/payments/5743030750216526004001/captures","method":"POST"},"refund":{"href":"/pts/v2/payments/5743030750216526004001/refunds","method":"POST"},"void":{"href":"/pts/v2/payments/5743030750216526004001/voids","method":"POST"}}}');
        res.setStatusCode(200);
        return res;
    }
}