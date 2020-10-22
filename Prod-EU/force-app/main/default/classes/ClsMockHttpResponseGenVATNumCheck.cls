@isTest global class  ClsMockHttpResponseGenVATNumCheck implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
    	// Create a fake response
    	HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status":200,"message":"success","country_code":"AT","vat_number":"U43666001","requester_country_code":null,"requester_vat_number":null,"validation":{"status":"ok","fault_string":null,"valid":true,"request_date":"2019-11-18+01:00","consultation_number":null,"consultation_authority":"EU VIES","company_name":"Trotec Laser GmbH","company_address":"Linzer"}}');
        res.setStatusCode(200);
        return res;
    }
}