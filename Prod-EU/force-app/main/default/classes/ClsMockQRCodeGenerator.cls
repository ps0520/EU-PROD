/********************************************************************************
@Description    : Mock class used to test CH QR Bill Functionality
*********************************************************************************/
@isTest
global class ClsMockQRCodeGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
         HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"qrcode":{"id":1,"name":"dummy","value":"dummy"}}');
        response.setStatusCode(200);
        return response;
    }
}