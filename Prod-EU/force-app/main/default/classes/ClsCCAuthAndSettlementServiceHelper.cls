public class ClsCCAuthAndSettlementServiceHelper {
    public ClsCCAuthAndSettlementResponse AuthorizeHelper(string reqAuth, string CurrencyIsoCode, ClsCCAuthAndSettlementResponse clsSvc){        
        CyberSource_API__mdt setAPI= [Select Id, Label, CurrencyIsoCode__c, endPoint__c, Enviornment__c, host__c, keyid__c, merchant_id__c, profile_id__c, reqBody__c, secretKey__c
		from CyberSource_API__mdt Where CurrencyIsoCode__c=:CurrencyIsoCode AND Label='Authorize' Limit 1];
        
        string endPoint=setAPI.endPoint__c; // 'https://apitest.cybersource.com/pts/v2/payments';
        string keyid=setAPI.keyid__c; // '8bb78528-3c56-4de4-9fc9-7320625fe3d2';
        string secretKey=setAPI.secretKey__c; //'UVASMQwkf4wC+bhdqgAen4oxXw8gWprTOpzCHx4mNKk=';
        string profile_id =setAPI.profile_id__c; // 'BB35D3D1-2546-4A9F-A69A-56E7FC6A2772';
        string v_c_merchant_id=setAPI.merchant_id__c; //'dxcm_gbp';
        string host=setAPI.host__c; // 'apitest.cybersource.com';
        
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
        
        request.setHeader('Digest', 'SHA-256=' + EncodingUtil.base64Encode(Crypto.generateDigest('SHA-256', Blob.valueOf(reqAuth)))); 
    	System.Debug('** 4. Digest=' + request.getHeader('Digest'));
        
        string kvp='host: ' + host +  '\n' ;
        kvp+='date: ' + request.getHeader('Date') +  '\n' ;
        kvp+='(request-target): post /pts/v2/payments' +  '\n' ;
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
        request.setBody(reqAuth);        
       
        HttpResponse response = http.send(request);
        System.debug('**** TPS:EH 2.1 AuthorizeHelper response=' + response);
        System.debug('**** TPS:EH 2.2 AuthorizeHelper response=' + response.getBody());        
        
        JSONParser parser = JSON.createParser(response.getBody());        
        
        string errorMsg=''; string statusMsg=''; string errorInformation='';
		while (parser.nextToken() != null) {
        	if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'id')) {
            	parser.nextToken(); clsSvc.paymentId=parser.getText();
            }
            
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'errorInformation')) {
            	parser.nextToken(); errorInformation=parser.getText();
            }
            
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'reconciliationId')) {
            	parser.nextToken(); clsSvc.settlementId=parser.getText();
            }
            
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'authorizedAmount')) {
            	parser.nextToken(); clsSvc.authorizedAmount=decimal.valueOf(parser.getText());
            }
            
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'approvalCode')) {
            	parser.nextToken(); clsSvc.approvalCode=parser.getText();
            }
            
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'status')) {
            	parser.nextToken(); statusMsg=parser.getText(); clsSvc.transStatus=parser.getText();
            }
            
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'message')) {
            	parser.nextToken(); errorMsg=parser.getText();
            }
        }
        
        System.Debug('**** TPS:EH AuthorizeHelper Before clsSvc =' + clsSvc);
        clsSvc.status=ClsCCAuthAndSettlementResponse.enumStatus.ERROR;        
        if(statusMsg=='DECLINED' && errorMsg!=null) {
        	clsSvc.status=ClsCCAuthAndSettlementResponse.enumStatus.ERROR;
            clsSvc.error=statusMsg + ' ' + errorMsg;
            clsSvc.SettlementId=null;            
        } else if((statusMsg=='AUTHORIZED' || statusMsg=='PENDING') && string.isEmpty(errorMsg) && clsSvc.paymentId !=null && clsSvc.settlementId !=null && clsSvc.approvalCode != null) {
        	clsSvc.status=ClsCCAuthAndSettlementResponse.enumStatus.SUCCESS;
            clsSvc.error=null;            
        } else if(statusMsg=='AUTHORIZED' && string.isEmpty(errorMsg) && clsSvc.paymentId !=null && clsSvc.approvalCode != null && CurrencyIsoCode=='CAD' && clsSvc.authorizedAmount!= null) {
            /* For CAD transactions, settlementId is not returned. Use combinaiton of status='Authorized' and approval code to mark transactions as success */
        	clsSvc.status=ClsCCAuthAndSettlementResponse.enumStatus.SUCCESS;
            clsSvc.settlementId=clsSvc.paymentId;
            clsSvc.error=null;            
        }else{
        	clsSvc.status=ClsCCAuthAndSettlementResponse.enumStatus.ERROR;
            clsSvc.error=statusMsg + ' ' + errorMsg;
            clsSvc.SettlementId=null;
        }
        System.Debug('**** TPS:EH AuthorizeHelper After clsSvc =' + clsSvc);
    	return clsSvc;
    } 
    
	public ClsCCAuthAndSettlementResponse SettleHelper(string reqAuth, string paymentId, string CurrencyIsoCode, ClsCCAuthAndSettlementResponse clsSvc){
        CyberSource_API__mdt setAPI= [Select Id, Label, CurrencyIsoCode__c, endPoint__c, Enviornment__c, host__c, keyid__c, merchant_id__c, profile_id__c, reqBody__c, secretKey__c
		from CyberSource_API__mdt Where CurrencyIsoCode__c=:CurrencyIsoCode AND Label='Settle' Limit 1];
        
        string endPoint=setAPI.endPoint__c; // 'https://apitest.cybersource.com/pts/v2/payments/{PaymentId}/captures';
        endpoint=endpoint.replace('{PaymentId}', paymentId);
        string keyid=setAPI.keyid__c; // '8bb78528-3c56-4de4-9fc9-7320625fe3d2';
        string secretKey=setAPI.secretKey__c; // 'UVASMQwkf4wC+bhdqgAen4oxXw8gWprTOpzCHx4mNKk=';        
        string profile_id =setAPI.profile_id__c; //'BB35D3D1-2546-4A9F-A69A-56E7FC6A2772';
        string v_c_merchant_id=setAPI.merchant_id__c; //'dxcm_gbp';
        string host=setAPI.host__c; //'apitest.cybersource.com';
        
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
        
        request.setHeader('Digest', 'SHA-256=' + EncodingUtil.base64Encode(Crypto.generateDigest('SHA-256', Blob.valueOf(reqAuth)))); 
    	System.Debug('** 4. Digest=' + request.getHeader('Digest'));
        string postUrl='/pts/v2/payments/{PaymentId}/captures';
        postUrl=postUrl.replace('{PaymentId}', paymentId);
        
        string kvp='host: ' + host +  '\n' ;
        kvp+='date: ' + request.getHeader('Date') +  '\n' ;
        kvp+='(request-target): post ' + postUrl +  '\n' ;
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
        request.setBody(reqAuth);
           
        HttpResponse response = http.send(request);
        System.debug('**** TPS:EH 2.1 SettleHelper response=' + response);
        System.debug('**** TPS:EH 2.2 SettleHelper response=' + response.getBody());               
        JSONParser parser = JSON.createParser(response.getBody());        

        string errorMsg=''; string statusMsg=''; string errorInformation='';
		while (parser.nextToken() != null) {
        	if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'id')) {
            	parser.nextToken(); clsSvc.paymentId=parser.getText();
            }
            
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'errorInformation')) {
            	parser.nextToken(); errorInformation=parser.getText();
            }
            
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'reconciliationId')) {
            	parser.nextToken(); clsSvc.settlementId=parser.getText();
            }
            
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'authorizedAmount')) {
            	parser.nextToken(); clsSvc.authorizedAmount=decimal.valueOf(parser.getText());
            }
            
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'approvalCode')) {
            	parser.nextToken(); clsSvc.approvalCode=parser.getText();
            }
            
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'status')) {
            	parser.nextToken(); statusMsg=parser.getText(); clsSvc.transStatus=parser.getText();
            }
            
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'message')) {
            	parser.nextToken(); errorMsg=parser.getText();
            }            
        }
        
        System.Debug('**** TPS:EH SettleHelper clsSvc=' + clsSvc);
        clsSvc.status=ClsCCAuthAndSettlementResponse.enumStatus.ERROR;        
        if(statusMsg=='DECLINED' && errorMsg!=null) {
        	clsSvc.status=ClsCCAuthAndSettlementResponse.enumStatus.ERROR;
            clsSvc.error=statusMsg + ' ' + errorMsg;
            clsSvc.SettlementId=null;            
         } else if((statusMsg=='AUTHORIZED' || statusMsg=='PENDING') && string.isEmpty(errorMsg) && clsSvc.paymentId !=null && clsSvc.settlementId !=null) {
        	clsSvc.status=ClsCCAuthAndSettlementResponse.enumStatus.SUCCESS;
            clsSvc.error=null;
            if(CurrencyIsoCode=='CAD'){
            	clsSvc.settlementId=clsSvc.paymentId;   
            }
        } else{
        	clsSvc.status=ClsCCAuthAndSettlementResponse.enumStatus.ERROR;
            clsSvc.error=statusMsg + ' ' + errorMsg;
            clsSvc.SettlementId=null;
        }
    	return clsSvc;
    }
    
    public ClsCCAuthAndSettlementResponse RefundHelper(string reqAuth, string paymentId, string CurrencyIsoCode, ClsCCAuthAndSettlementResponse clsSvc){
        CyberSource_API__mdt setAPI= [Select Id, Label, CurrencyIsoCode__c, endPoint__c, Enviornment__c, host__c, keyid__c, merchant_id__c, profile_id__c, reqBody__c, secretKey__c
		from CyberSource_API__mdt Where CurrencyIsoCode__c=:CurrencyIsoCode AND Label='Refund' Limit 1];
        
        string endPoint=setAPI.endPoint__c;
        endpoint=endpoint.replace('{PaymentId}', paymentId);
        string keyid=setAPI.keyid__c;
        string secretKey=setAPI.secretKey__c;
        string profile_id =setAPI.profile_id__c;
        string v_c_merchant_id=setAPI.merchant_id__c;
        string host=setAPI.host__c;
        
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
        
        request.setHeader('Digest', 'SHA-256=' + EncodingUtil.base64Encode(Crypto.generateDigest('SHA-256', Blob.valueOf(reqAuth)))); 
    	System.Debug('** 4. Digest=' + request.getHeader('Digest'));
        string postUrl='';
        if(request.getEndpoint().contains('/pts/v2/payments/')){
            postUrl=request.getEndpoint().substring(request.getEndpoint().indexOf('/pts/v2/payments/'));        
        }        
    	
        string kvp='host: ' +  request.getHeader('Host') +  '\n' ;
        kvp+='date: ' + request.getHeader('Date') +  '\n' ;
        kvp+='(request-target): post ' + postUrl +  '\n' ;
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
        request.setBody(reqAuth);
           
        HttpResponse response = http.send(request);
        System.debug('**** TPS:EH 2.1 RefundHelper response=' + response);
        System.debug('**** TPS:EH 2.2 RefundHelper response=' + response.getBody());               
        JSONParser parser = JSON.createParser(response.getBody());        

        string errorMsg=''; string refundRefNum=''; string statusMsg=''; string errorInformation=''; decimal refundAmount;
        while (parser.nextToken() != null) {
        	if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'status')) {
            	parser.nextToken(); statusMsg=parser.getText(); clsSvc.transStatus=parser.getText();
            }
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'reconciliationId')) {
            	parser.nextToken(); refundRefNum=parser.getText();
            }
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'refundAmount')) {
                parser.nextToken(); if(parser.getText() != null){refundAmount=Decimal.ValueOf(parser.getText());}
            }
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'message')) {
            	parser.nextToken(); errorMsg=parser.getText();
            }
        }
        
        System.Debug('**** TPS:EH 2.3 RefundHelper clsSvc=' + clsSvc);
        clsSvc.status=ClsCCAuthAndSettlementResponse.enumStatus.ERROR;
        clsSvc.error=errorMsg;
        if(statusMsg.equals('PENDING')){
            clsSvc.status=ClsCCAuthAndSettlementResponse.enumStatus.SUCCESS;
            clsSvc.refundAmount=refundAmount;
            clsSvc.refundRefNum=refundRefNum;
            clsSvc.error=null;
            clsSvc.refundDate=System.Datetime.now();
        }        
    	return clsSvc;
    }
}