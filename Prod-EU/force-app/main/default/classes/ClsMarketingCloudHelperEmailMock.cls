/**
* ClsMarketingCloudHelperEmailMock
* Mock class for tests hitting Marketing Cloud api calls
* @author Craig Johnson(Sundog)
* @date 03/16/19
*/
global class ClsMarketingCloudHelperEmailMock  implements HttpCalloutMock { 
    
    private List<ClsMarketingCloudHelperEmail.SubscriberStatus> subscribers = new List<ClsMarketingCloudHelperEmail.SubscriberStatus>();

    private ClsMarketingCloudHelperEmail.SubscriberStatus createSubscriber(String subscriberKey, String status) {
        ClsMarketingCloudHelperEmail.SubscriberStatus s = new ClsMarketingCloudHelperEmail.SubscriberStatus();
        s.subscriberKey = subscriberKey;
        s.status = status;
        s.emailAddress = 'test@gmail.com';
        return s;
    }

    global ClsMarketingCloudHelperEmailMock(){
        
    }
    global ClsMarketingCloudHelperEmailMock(String subscriberKey) {
        this.subscribers.add(createSubscriber(subscriberKey, 'Active'));
    }
    global ClsMarketingCloudHelperEmailMock(String subscriberKey, String status) {
        this.subscribers.add(createSubscriber(subscriberKey, status));
    }
    global ClsMarketingCloudHelperEmailMock(List<String> subscriberKeys, String status) {
        for (String subscriberKey : subscriberKeys){
             this.subscribers.add(createSubscriber(subscriberKey, status));
        }
    }
    
    global HTTPResponse respond(HttpRequest request) {
        //Mock response for pending for the email double opt in
        if(request.getHeader('SOAPAction')=='Retrieve'){
            HttpResponse response = new HttpResponse();
            
            String body = '<?xml version="1.0" encoding="utf-8"?> '+
                '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> ' +
                ' <soap:Header> '+
                '<wsa:Action>RetrieveResponse</wsa:Action>'+
                '<wsa:MessageID>urn:uuid:be039c5e-6f12-4246-a759-d4b2cc104297</wsa:MessageID>'+
                '<wsa:RelatesTo>urn:uuid:cb889a37-a3c9-4f81-822d-b1c7df11f22c</wsa:RelatesTo>'+
                '<wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To>'+
                '<wsse:Security>'+
                ' <wsu:Timestamp wsu:Id="Timestamp-8a6ba16b-c258-4fb4-a040-a8633a6a6d13">'+
                '<wsu:Created>2019-03-18T11:04:38Z</wsu:Created>'+
                ' <wsu:Expires>2019-03-18T11:09:38Z</wsu:Expires>'+
                ' </wsu:Timestamp>'+
                '</wsse:Security>'+
                '</soap:Header>'+
                '<soap:Body>'+
                '<RetrieveResponseMsg xmlns="http://exacttarget.com/wsdl/partnerAPI">'+
                '<OverallStatus>OK</OverallStatus>'+
                '<RequestID>561fc44d-a6ea-45c2-b0f6-449ce8022a42</RequestID>';
            
            for (ClsMarketingCloudHelperEmail.SubscriberStatus s : subscribers) {
                body += ' <Results xsi:type="ListSubscriber">'+
                        '  <ObjectID xsi:nil="true" />'+
                        '  <Status>' + s.status + '</Status>'+
                        '  <SubscriberKey>' + s.subscriberKey + '</SubscriberKey>'+
                        '  <EmailAddress>' + s.emailAddress + '</EmailAddress>'+
                        ' </Results>';
            }

            body += ' </RetrieveResponseMsg>'+
                    ' </soap:Body>'+
                    '</soap:Envelope>';

            System.debug('SOAPAction:Retrieve');
            System.debug(body);
            response.setBody(body);
            response.setStatusCode(200);
            return response;
        } else if (request.getHeader('SOAPAction')=='Create'){
            //add to list and send email call
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            return  response;
        }

        //DEFAULT - Mock response for the auth call
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"access_token": "7Tq6M8U8LHDyurIZ4Q9gTPtg","expiresIn": 3479, "scope": "read"}');
        response.setStatusCode(200);
        return  response;
    }
}