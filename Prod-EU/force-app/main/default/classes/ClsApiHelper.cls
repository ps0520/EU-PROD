public class ClsApiHelper {
    public static VATAPIRes VatNumCheck(string vatNum){
        for(VATApi__mdt setAPI : [Select Id, endPoint__c, API_Key__c from VATApi__mdt Where Label='vat-number-check' Limit 1]){
			Http http = new Http();
            HttpRequest request = new HttpRequest();
            string endPoint=setAPI.endPoint__c;
            endPoint=endPoint.replace('{0}', vatNum);
            request.setEndpoint(endPoint);
            request.setMethod('GET');
            string apiKey=setAPI.API_Key__c;
    
            request.setHeader('x-api-key',apiKey);
            System.Debug('** 1. x-api-key=' + request.getHeader('x-api-key'));
            VATAPIRes clsRes;       
            HttpResponse response = http.send(request);
            System.debug('**** TPS:EH 2.1 response=' + response.getBody());
            clsRes=VATAPIRes.parse(response.getBody());
            
            System.Debug('** TPS:EH 3.1 VATAPIRes=' + clsRes);
            System.Debug('** TPS:EH 3.2 validation.valid=' + clsRes.validation.valid);
            System.Debug('** TPS:EH 3.3 validation.status=' + clsRes.validation.status);
            System.Debug('** TPS:EH 3.4 status=' + clsRes.status);
            System.Debug('** TPS:EH 3.5 message=' + clsRes.message);
            return clsRes;            
        }
        return null;
    }
}