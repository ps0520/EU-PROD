/**
 * MarketingCloudHelper
 * Helper class to run lead and account records through Double Opt In process with Marketing Cloud
 * @author Craig Johnson(Sundog), Kristen Anderson (Sundog)
 * @date 6/20/19
 
 */
public class ClsMarketingCloudHelper {    
    //Get Marketing_Cloud_Connection__mdt object
    private static Marketing_Cloud_Connection__mdt MCC = null;
    
    private static final String AUTH_BASE_URI = '.auth.marketingcloudapis.com/v2/token';
    
    private static final String REST_BASE_URI = '.rest.marketingcloudapis.com/';
    
    public static final String SOAP_BASE_URI = '.soap.marketingcloudapis.com/Service.asmx';
    
    public static Map<String, String> recordTypeToMCCPrefixMap = new Map<String, String>();
    
    public static Map<String, String> setRecordTypeToMCCPrefixMap(){
        if(!recordTypeToMCCPrefixMap.isEmpty()){
            return recordTypeToMCCPrefixMap;
        }
        
        recordTypeToMCCPrefixMap.put('DE_Consumer', 'DE_');
        recordTypeToMCCPrefixMap.put('CA_Consumer', 'CA_');
        recordTypeToMCCPrefixMap.put('GB_Consumer', 'GB_IE_');
        recordTypeToMCCPrefixMap.put('IE_Consumer', 'GB_IE_');
        recordTypeToMCCPrefixMap.put('AT_Consumer', 'AT_CH_');
        recordTypeToMCCPrefixMap.put('CH_Consumer', 'AT_CH_');
        recordTypeToMCCPrefixMap.put('DE_Person_Lead', 'DE_');
        recordTypeToMCCPrefixMap.put('CA_Person_Lead', 'CA_');
        recordTypeToMCCPrefixMap.put('GB_Person_Lead', 'GB_IE_');
        recordTypeToMCCPrefixMap.put('IE_Person_Lead', 'GB_IE_');
        recordTypeToMCCPrefixMap.put('AT_Person_Lead', 'AT_CH_');
        recordTypeToMCCPrefixMap.put('CH_Person_Lead', 'AT_CH_');
        return recordTypeToMCCPrefixMap;
    }
    
    public static String getRecordTypePrefix(Id recordId){
        Boolean isAccount = (recordId.getSobjectType() == Schema.Account.SObjectType) ? true : false;
        String recordTypeName = isAccount ? [SELECT RecordType.DeveloperName FROM Account WHERE Id = :recordId].RecordType.DeveloperName : [SELECT RecordType.DeveloperName FROM Lead WHERE Id = :recordId].RecordType.DeveloperName;
        return ClsMarketingCloudHelper.setRecordTypeToMCCPrefixMap().get(recordTypeName);
    }
	
    public static Marketing_Cloud_Connection__mdt getConnectionRecord(){
        if (MCC != null) {
            return MCC;
        }
        
        //Get and set all the marketing cloud connection info
        Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];
        String masterLabel = org.IsSandbox ? 'Connection Details Dev' : 'Connection Details Production';
		
        MCC = [SELECT DE_Client_Id__c, DE_Client_Secret__c, DE_List_DoubleOptIn__c, DE_API_Subdomain__c, 
                CA_Client_Id__c, CA_Client_Secret__c, CA_List_DoubleOptIn__c, CA_API_Subdomain__c, 
                GB_IE_Client_Id__c, GB_IE_Client_Secret__c, GB_IE_List_DoubleOptIn__c, GB_IE_API_Subdomain__c, 
                AT_CH_Client_Id__c, AT_CH_Client_Secret__c, AT_CH_List_DoubleOptIn__c, AT_CH_API_Subdomain__c
                FROM Marketing_Cloud_Connection__mdt 
                WHERE MasterLabel = :masterLabel LIMIT 1];
        
        return MCC;
    }
	/*
    @Future(Callout=true)
    public static void sendSMSMessageFuture(String phoneNumber, Id accountId, Integer whichCall, id personid){
        //get the records that are still in a pending state
        Set<String> pendingNumbers = updateOptInValues(true);
        System.debug(pendingNumbers);
        Set<String> formattedPendingNumbers = new Set<String>();
        for(String pending : pendingNumbers){
            String formattedPhoneNumberPending='';
            System.debug(pending);
        formattedPhoneNumberPending = pending.replaceAll(' ','');
        formattedPhoneNumberPending = formattedPhoneNumberPending.replace('(','');
        formattedPhoneNumberPending = formattedPhoneNumberPending.replace(')','');
        formattedPhoneNumberPending = formattedPhoneNumberPending.replaceAll('-','');
            System.debug(formattedPhoneNumberPending);
            formattedPendingNumbers.add(formattedPhoneNumberPending);
        }
        System.debug(formattedPendingNumbers);
        
        //format the phone number we are sending the SMS
        String formattedPhoneNumber='';
        formattedPhoneNumber = phoneNumber.replaceAll(' ','');
        formattedPhoneNumber = formattedPhoneNumber.replace('(','');
        formattedPhoneNumber = formattedPhoneNumber.replace(')','');
        formattedPhoneNumber = formattedPhoneNumber.replaceAll('-','');
        if(formattedPhoneNumber.length()==10){
            System.debug(formattedPhoneNumber);
            if(!formattedPendingNumbers.contains(formattedPhoneNumber) && whichCall==2){
                return;
            }
            else{
                sendSMSMessage('1'+formattedPhoneNumber, accountId, whichCall, personid);
            }
        }
        
    }
    
    @Future(Callout=true)
    public static void dooptincallFuture(){
        doOptInCall();
    }
    
    public static void sendSMSMessage(String phoneNumber, Id accountId, Integer whichCall, id personid){
        //Get and set all the marketing cloud connection info
        Marketing_Cloud_Connection__mdt mcc = getConnectionRecord();
        
        String shortCode=mcc.Short_Code__c;
        String messageText=mcc.Message__c;
        String moUrl=mcc.MO_Url__c;
        
        //retrieve the auth token 
        //String authToken = getAuthToken(mcc.Client_Id__c, mcc.Client_Secret__c, mcc.Token_Url__c);   
        String authToken = getAuthToken(mcc.DE_Client_Id__c, mcc.DE_Client_Secret__c, mcc.Token_Url__c);     
        System.debug(authToken);
        
        if(authToken != null){
            
            //create the json body for the callout to marketing cloud
            JSONGenerator gen = JSON.createGenerator(false);
            
            gen.writeStartObject();
            gen.writeFieldName('subscribers');
            gen.writeStartArray();
            gen.writeStartObject();
            gen.writeStringField('mobilenumber', phoneNumber);
            gen.writeStringField('subscriberkey', personid);
            gen.writeEndObject();
            gen.writeEndArray();
            gen.writeStringField('shortCode', shortCode);
            gen.writeStringField('messageText', messageText);
            gen.writeEndObject();
            
            //form the request headers
            HttpRequest request = new HttpRequest();
            request.setEndpoint(moUrl);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json'); // x-www-form-urlencoded 
            request.setHeader('Authorization', 'Bearer ' + authToken);
            String bodyValue = gen.getAsString();
            request.setHeader('content-length', String.valueOf(bodyValue.length()));
            request.setBody(bodyValue);
            
            //send the request
            Http http = new Http();            
            HttpResponse response = http.send(request);    
            
            //correct response example: 202 Accepted
            
			/*
            {
                "results": [
                    {
                        "identifier": "cTQ4TEI5NHpHa0daYmM2bEdQakI2QTo3Njow",
                        "mobileNumber": "17014290378",
                        "result": "OK"
                    }
                ]
            }*/
            
            /*
            //for a good respoxe we want to set what time it was set atand uncheck the send checkbox for the second SMS
            if(response.getStatusCode() == 202){                
                Account accountSentSMS= new Account();
                accountSentSMS.Id=accountId;
                if(whichCall==1){
                    accountSentSMS.SMS_Opt_In_Sent__c=dateTime.now();
                }else if (whichCall==2){
                    accountSentSMS.SMS_Opt_In_2_Sent__c=dateTime.now();
                    accountSentSMS.SMS_Send_Opt_In_2__c=false;
               
                }
                update accountSentSMS;
            }
            else{
                //If the call fails we want to make sure all the times are null to make sure it will try and send again
                Account accoutSentFailed= new Account();
                accoutSentFailed.Id=accountId;
                 if(whichCall==1){
                    accoutSentFailed.SMS_Opt_In_Sent__c=null;
                    accoutSentFailed.SMS_Opt_In_2_Sent__c=null;   
                }else if (whichCall==2){
                    accoutSentFailed.SMS_Opt_In_2_Sent__c=null;                                         
                }
                update accoutSentFailed;
            }
        }
    }
	*/
    private static String AUTH_TOKEN = null;

    public static String getAuthToken(String clientId, String clientSecret, String subdomain){
        if (AUTH_TOKEN != null){
            return AUTH_TOKEN;
        }

        HttpRequest request = new HttpRequest();
        
        //create json for the auth call
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();   
        gen.writeStringField('client_id', clientId);
        gen.writeStringField('client_secret', clientSecret);
        gen.writeStringField('grant_type', 'client_credentials');
        
        gen.writeEndObject();
        
        //form the request headers
        //request.setEndpoint(tokenUrl);
        request.setEndpoint('https://' + subdomain + AUTH_BASE_URI);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(gen.getAsString());
        
        
        
        //send the request
        Http http = new Http();        
        HttpResponse response = http.send(request);
        
        // if it is a good response parse out the accesstoken and return it
        System.debug(response.getBody());
        if(response.getStatusCode() == 200){
            Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            //System.debug(parsedResponse.get('scope').toString());
            AUTH_TOKEN = parsedResponse.get('access_token').toString();
            return AUTH_TOKEN;
        }else{
            return null;
        }
    }
    
    private static String makeOptInCallBody(String DEV_USERNAME, String DEV_PASSWORD){        
        // make the body of the soap call
        String startOfBody='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema"'
            +' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
            +'<soapenv:Header> <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
            +'<wsse:UsernameToken wsu:Id="UsernameToken-24440876" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">';        
        String usernameSection = '<wsse:Username>'+DEV_USERNAME+'</wsse:Username>';
        String passwordSection ='<wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">'+DEV_PASSWORD+'</wsse:Password>';
        String middleOfBody=' </wsse:UsernameToken> </wsse:Security> </soapenv:Header> <soapenv:Body> '
            +'<RetrieveRequestMsg xmlns="http://exacttarget.com/wsdl/partnerAPI"> <RetrieveRequest>';        
        String objectAndFields=' <ObjectType>DataExtensionObject[Subscriber_Management_Mobile_Subscription]</ObjectType> <Properties>MobileNumber</Properties><Properties>OptInStatusID</Properties>'
            +'<Properties>OptOutStatusID</Properties>';
        String endOfBody='</RetrieveRequest> </RetrieveRequestMsg> </soapenv:Body></soapenv:Envelope>';
        String entireBody = startOfBody + usernameSection+passwordSection+middleOfBody+objectAndFields+endOfBody;
        return entireBody;
        
    }
          
    public static String getMarketingCloudEndpointUrl(String marketingCloudInstance){
        //Depending the the instance of the marketing cloud the url needs to change slightly
        String url = '';
        if(String.isBlank(marketingCloudInstance)){
            url = 'https://webservice.exacttarget.com/Service.asmx';
        }else{
            url = 'https://webservice.' + marketingCloudInstance.toLowerCase() + '.exacttarget.com/Service.asmx';
        }
        return url;
    }
    
    /*
    public static String doOptInCall(){
        //Get and set all the marketing cloud connection info
        Marketing_Cloud_Connection__mdt mcc = getConnectionRecord();
        
        //Form the body for the SOAP call
        String bodyToSend=makeOptInCallBody(mcc.Username__c, mcc.Password__c);
      
        //Formt he requst and headers for the request
        Http http = new Http();
        System.debug('Send Body: ' + bodyToSend);
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Content-Type','text/xml');
        request.setHeader('SOAPAction', 'Retrieve');
        request.setBody(bodyToSend);
        request.setTimeout(120000); //120,000 is the max
        //request.setEndpoint(getMarketingCloudEndpointUrl(mcc.Marketing_cloud_instance__c));
     	request.setEndpoint('https://' + mcc.DE_API_Subdomain__c + SOAP_BASE_URI);
     	
        //make the call
        HttpResponse response = http.send(request);
        //Retrieve the body from the response
        String responseBody = response.getBody();
        System.debug('Response status: ' + response.getStatus());
        System.debug('Response status code: ' + response.getStatusCode());
        System.debug('Response Body: ' + responseBody);
        return responseBody;
    }
    
    @Future(Callout=true)
    Public static void futureupdateOptInValues(){
        updateOptInValues(false);
    }
    
    public static Set<String> updateOptInValues(boolean GettingPending){
        //get the respose from the callout that gets the opt statuses
        String response=doOptInCall();

        Set<String> pendingSet=new Set<String>();
        Map<String,String> optInMap=new Map<String,String>();
        Map<String,String> optOutMap=new Map<String,String>();

        // Get the status of the callout if Error we don't do anything otherwise we update as needed
        String resultStatus = ClsXmlUtils.getStringValueFromXML(response, 'StatusCode');       
        if(resultStatus == 'Error'){
        }else{
            //since the response is good we need to go through and parse the reults
            List<String> resultList= ClsXmlUtils.retrieveListBySplit( response,'Results', true);
             
            for(String oneResult :resultList){
                List<String> propertyList= ClsXmlUtils.retrieveListBySplit( oneResult, 'Property', true);
                //We need to get out the mobile phone number, opt in and opt out status
                String formattedMobilePhoneNumber='';
                String optInStatus ='';
                String optOutStatus='';
                for(String oneProperty : propertyList){
                    if(oneProperty.contains('MobileNumber')){
                        String mobilePhoneNumber=ClsXmlUtils.getStringValueFromXML(oneProperty, 'Value');
                        if(mobilePhoneNumber.startsWith('1')){
                            mobilePhoneNumber= mobilePhoneNumber.substring(1);
                        }
                        formattedMobilePhoneNumber ='('+mobilePhoneNumber.substring(0, 3)+') '+mobilePhoneNumber.substring(3,6)+'-'+mobilePhoneNumber.substring(6);
                    } 
                    else if(oneProperty.contains('OptInStatusID')){
                        optInStatus=ClsXmlUtils.getStringValueFromXML(oneProperty, 'Value');
                    }
                    else if(oneProperty.contains('OptOutStatusID')){
                        optOutStatus=ClsXmlUtils.getStringValueFromXML(oneProperty, 'Value');
                    }
                }
                // add the values to a map to key out of later
                if(!string.isBlank(formattedMobilePhoneNumber)){
                    optInMap.put(formattedMobilePhoneNumber, optInStatus);
                    optOutMap.put(formattedMobilePhoneNumber, optOutStatus);
                }
            }
            //System.debug( optInMap.keyset().size() );
            if(optInMap.keyset().size()==0){
                return pendingSet;
            }else{
            //retireve all records from the database that have to do with one of the records returned from the api call
            List<Account> accountsWithNumbersReturned =[SELECT PersonMobilePhone, SMS_Opt_in_List__c, SMS_Opt_Out_List__c, SMS_pending_opt_in__c, id 
                                      FROM Account 
                                      WHERE PersonMobilePhone in :optInMap.keySet()];
            
            List<Account> changedAccounts=new List<Account>();
            
            //For each account we need to check if it has changed and then update correctly if it has
            for(Account correspondingAccount : accountsWithNumbersReturned){
                Boolean accountChanged=false;
                //Check all the opt in info
                if(optInMap.get(correspondingAccount.PersonMobilePhone)=='2' && (correspondingAccount.SMS_Opt_in_List__c!='True' ||  correspondingAccount.SMS_pending_opt_in__c!=false)){
                    correspondingAccount.SMS_Opt_in_List__c='True';
                    correspondingAccount.SMS_pending_opt_in__c=false;
                    accountChanged=true;
                }else if(optInMap.get(correspondingAccount.PersonMobilePhone)=='1' && correspondingAccount.SMS_pending_opt_in__c!=true){
                    correspondingAccount.SMS_pending_opt_in__c=true;
                    accountChanged=true;
                }else if (optInMap.get(correspondingAccount.PersonMobilePhone)=='0' && (correspondingAccount.SMS_Opt_in_List__c!='False' ||  correspondingAccount.SMS_pending_opt_in__c!=false)){
                    correspondingAccount.SMS_Opt_in_List__c='False';
                    correspondingAccount.SMS_pending_opt_in__c=false;
                    accountChanged=true;
                }
                
                //Check all the opt out values
                if(optOutMap.get(correspondingAccount.PersonMobilePhone)=='0'&& correspondingAccount.SMS_Opt_Out_List__c!='False' ){
                    correspondingAccount.SMS_Opt_Out_List__c='False';
                    accountChanged=true;
                }else if(optOutMap.get(correspondingAccount.PersonMobilePhone)=='1'&& correspondingAccount.SMS_Opt_Out_List__c!='True') {
                    accountChanged=true;
                    correspondingAccount.SMS_Opt_Out_List__c='True';
                } 
                
                //Make a list of all the currently pending records no matter if they have changed or not
                if(optInMap.get(correspondingAccount.PersonMobilePhone)=='1' ){
                    pendingSet.add(correspondingAccount.PersonMobilePhone);
                }
                
                //if they have changed add to a list so we can update just those
                if(accountChanged){
                    changedAccounts.add(correspondingAccount);
                }
            }
            //update the accounts that have changes
                if(!gettingPending){
                    update changedAccounts;
                }
        }
        }
        //return the pending phone numbers
        return pendingSet;      
    }
    */
}