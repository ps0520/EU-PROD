@isTest global class  ClsMockHttpResponseGenCCNumToken implements HttpCalloutMock {
	// Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
    	// Create a fake response
    	HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"_links":{"self":{"href":"https://apitest.cybersource.com/tms/v1/instrumentidentifiers/7010000000063181111"},"paymentInstruments":{"href":"https://apitest.cybersource.com/tms/v1/instrumentidentifiers/7010000000063181111/paymentinstruments"}},"id":"7010000000063181111","object":"instrumentIdentifier","state":"ACTIVE","card":{"number":"411111XXXXXX1111"},"metadata":{"creator":"dxcm_chf"}}');
		res.setStatusCode(200);
        return res;
    }
}