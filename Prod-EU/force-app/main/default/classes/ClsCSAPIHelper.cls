public class ClsCSAPIHelper{

public string getCCToken(string cardNum, string currISOCode){
    // TODO: Read CurrencyIsoCode__c from Order CurrencyIsoCode    
    CyberSource_API__mdt setAPI= [Select Id, Label, CurrencyIsoCode__c, endPoint__c, Enviornment__c, host__c, keyid__c, merchant_id__c, profile_id__c, reqBody__c, secretKey__c
		from CyberSource_API__mdt Where CurrencyIsoCode__c=:currISOCode AND Label='TokenizeCard' Limit 1];
    System.Debug('**** TPS:EH 1.1 setAPI=' + setAPI);
if(setAPI !=null){ 
    string endPoint=setAPI.endPoint__c; // 'https://apitest.cybersource.com/tms/v1/instrumentidentifiers';
    string keyid=setAPI.keyid__c; // '8bb78528-3c56-4de4-9fc9-7320625fe3d2';
    string secretKey=setAPI.secretKey__c; //'UVASMQwkf4wC+bhdqgAen4oxXw8gWprTOpzCHx4mNKk=';
    string reqBody=setAPI.reqBody__c; // '{"card":{"number":"{0}"}}'; // 411111111111112
    string profile_id =setAPI.profile_id__c; // 'BB35D3D1-2546-4A9F-A69A-56E7FC6A2772';
    string v_c_merchant_id=setAPI.merchant_id__c; // 'dxcm_gbp';
    string host=setAPI.host__c; // 'apitest.cybersource.com';
    reqBody=reqBody.replace('{0}', cardNum);
    System.Debug('*** reqBody=' + reqBody);
    
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint(endPoint);
    request.setMethod('POST');
    request.setHeader('v-c-merchant-id',v_c_merchant_id);
    System.Debug('** 1. v-c-merchant-id=' + request.getHeader('v-c-merchant-id'));
    
    request.setHeader('Date', DateTime.Now().formatGMT('EEE, dd MMM yyyy HH:mm:ss') + ' GMT');
    System.Debug('** 2. Date=' + request.getHeader('Date'));
    
    request.setHeader('Host',host);
    System.Debug('** 3. Host=' + request.getHeader('Host'));
    
    
    request.setHeader('Digest', 'SHA-256=' + EncodingUtil.base64Encode(Crypto.generateDigest('SHA-256', Blob.valueOf(reqBody)))); 
    System.Debug('** 4. Digest=' + request.getHeader('Digest'));
    
    string kvp='host: ' + host +  '\n' ;
    kvp+='date: ' + request.getHeader('Date') +  '\n' ;
    kvp+='(request-target): post /tms/v1/instrumentidentifiers' +  '\n' ;
    kvp+='digest: ' + request.getHeader('Digest') +  '\n' ;
    kvp+='v-c-merchant-id: ' + request.getHeader('v-c-merchant-id');
    System.Debug('*** kvp=' + kvp);
    
    string kvpAsHex = EncodingUtil.convertToHex(Blob.valueOf(kvp));
    Blob kvpAsBlob = EncodingUtil.convertFromHex(kvpAsHex);
    Blob hmacData = Crypto.generateMac('HmacSHA256', kvpAsBlob, EncodingUtil.base64Decode(secretKey));
    System.Debug('*** hmacData=' + hmacData);
    
    string signStr='keyid="{0}", algorithm="HmacSHA256", headers="host date (request-target) digest v-c-merchant-id", signature="{1}"';
    signStr=signStr.replace('{0}',keyid);
    signStr=signStr.replace('{1}',EncodingUtil.base64Encode(hmacData));    
    request.setHeader('Signature', signStr);
    System.Debug('** 5. Signature=' + request.getHeader('Signature'));
    
    request.setHeader('key-id',keyid);
    request.setHeader('shared-secret',secretKey);
    request.setHeader('profile-id', profile_id);
    request.setHeader('Content-Type','application/json');
    request.setBody(reqBody);
    
    HttpResponse response = http.send(request);
	    
    System.debug('**** TPS:EH 2.1 response=' + response);
    if(string.valueOf(response).contains('StatusCode=400')){
    	System.debug('**** TPS:EH 2.2 Status code 400');
        return 'ERROR:BAD_REQUEST';
    } 
    System.debug('**** TPS:EH 2.3 response=' + response.getBody());
    string cardToken=ClsCSResInstrumentIdentifier.parse(response.getBody()).Id;
    System.debug('**** TPS:EH 3.1 Token=' + cardToken);
    return cardToken;
}
    return null;
}

}