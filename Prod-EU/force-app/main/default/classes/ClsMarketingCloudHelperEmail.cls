/**
 * MarketingCloudHelperEmail
 * Helper methods related to marketing cloud email subscriptions
 * @author Craig Johnson(Sundog)
 * @date 03/3/19
 */
public class ClsMarketingCloudHelperEmail {

    public static Boolean RUN_TRIGGER_LOGIC = true;

    private static Set<Id> validLeadRecordTypeIds = null;

    public static Set<Id> getValidLeadRecordTypeIds() {
        if (validLeadRecordTypeIds != null) {
            return validLeadRecordTypeIds;
        }

        Set<Id> result = new Set<Id>();
        for (RecordType rt : [select Id from RecordType where (DeveloperName = 'DE_Person_Lead' or DeveloperName = 'CA_Person_Lead' or 
                                                               DeveloperName = 'GB_Person_Lead' or DeveloperName = 'IE_Person_Lead' or 
                                                               DeveloperName = 'AT_Person_Lead' or DeveloperName = 'CH_Person_Lead') and SobjectType = 'Lead']) {
            result.add(rt.Id);
        }
        validLeadRecordTypeIds = result;
        return result;
    }

    private static Set<Id> validAccountRecordTypeIds = null;

    public static Set<Id> getValidAccountRecordTypeIds() {
        if (validAccountRecordTypeIds != null) {
            return validAccountRecordTypeIds;
        }

        Set<Id> result = new Set<Id>();
        for (RecordType rt : [select Id from RecordType where (DeveloperName = 'DE_Consumer' or DeveloperName = 'CA_Consumer' or 
                                                               DeveloperName = 'GB_Consumer' or DeveloperName = 'IE_Consumer' or 
                                                               DeveloperName = 'AT_Consumer' or DeveloperName = 'CH_Consumer') and SobjectType = 'Account']) {
            result.add(rt.Id);
        }
        validAccountRecordTypeIds = result;
        return result;
    }

    @future(Callout=true)
    public static void sendDoubleOptInFuture(Id recordId){
        sendDoubleOptIn(recordId, true);
    }

    //Call out to marketing cloud
    //recordId can be a leadId or accountId
    //makes 2 callouts per call
    public static SObject sendDoubleOptIn(Id recordId, Boolean updateRecord){
        // get record type prefix
        String prefix = ClsMarketingCloudHelper.getRecordTypePrefix(recordId);
        
        //Marketing_Cloud_Connection__mdt mcc = ClsMarketingCloudHelper.getConnectionRecord(recordTypeName);
        Marketing_Cloud_Connection__mdt mcc = ClsMarketingCloudHelper.getConnectionRecord();
        
        
        //String tokenUrl = mcc.Token_Url__c;
        String clientId = (String) mcc.get(prefix + 'Client_Id__c');
        String clientSecret = (String) mcc.get(prefix + 'Client_Secret__c');
        String listId = (String) mcc.get(prefix + 'List_DoubleOptIn__c');
        String subdomain = (String) mcc.get(prefix + 'API_Subdomain__c');
        
       //String authToken = ClsMarketingCloudHelper.getAuthToken(clientId, clientSecret, tokenUrl);
        String authToken = ClsMarketingCloudHelper.getAuthToken(clientId, clientSecret, subdomain);
        
        System.debug(authToken);
        
        if(authToken != null){
            SObject record = null;
            String requestXML = null;
            String triggeredSendId = 'Double Opt-in Triggered Send';

            if (recordId.getSobjectType() == Schema.Lead.SObjectType) {
                record = [SELECT Id, Email, Email_Double_Opt_In_Subscriber__c FROM Lead WHERE Id = :recordId];
                if (record.get('Email_Double_Opt_In_Subscriber__c') == null) {
                    requestXML = createSubscriberAndTriggerSendXML(authToken, (String)record.get('Email'), (String)record.get('Id'), listId, triggeredSendId);
                	System.debug(requestXML);
                }
            } else if (recordId.getSobjectType() == Schema.Account.SObjectType) {
                //regardless of previous entry in MC as a lead id, we always send this as a person contact id
                Account account = [SELECT Id, PersonContactId, PersonEmail, Email_Double_Opt_In_Subscriber__c FROM Account WHERE Id = :recordId];
                //we do not want to attempt to send the user another opt in email if we know we have put them on the list already
                if (account.Email_Double_Opt_In_Subscriber__c == null) {
                    //Regardless of previous converted lead id existence in Marketing Cloud, push the pending opt-in as the Account.PersonContactId
                    requestXML = createSubscriberAndTriggerSendXML(authToken, account.PersonEmail, account.PersonContactId, listId, triggeredSendId);
                }

                record = account;
            }
            
            if (requestXML == null) {
                return null;
            }
            
            //HttpResponse response = processSoapCallout(mcc.Marketing_cloud_instance__c, 'POST', 'Create', requestXML);
            HttpResponse response = processSoapCallout(mcc, 'POST', 'Create', requestXML);
            System.debug(response.getStatusCode() + ': ' + response.getStatus());
            //for a good response we want to set the date for Email_Double_Opt_In_Subscriber__c
            if(response.getStatusCode() == 200) {
                record.put('Email_Double_Opt_In_Subscriber__c', DateTime.now());
                record.put('Email_Pending_Opt_In_Reset__c', false);
                if (updateRecord) {
                    update record;
                }
                return record;
            }
        }
        return null;
    }

    //recordId can be a leadId or accountId
    //up to 4 callouts per method call
    public static SObject sendOptOut(Id recordId, Boolean updateRecord){
        // get record type prefix
        String prefix = ClsMarketingCloudHelper.getRecordTypePrefix(recordId);
        
        Marketing_Cloud_Connection__mdt mcc = ClsMarketingCloudHelper.getConnectionRecord();
                        
        //String tokenUrl = mcc.Token_Url__c;
        String clientId = (String) mcc.get(prefix + 'Client_Id__c');
        String clientSecret = (String) mcc.get(prefix + 'Client_Secret__c');
        String listId = (String) mcc.get(prefix + 'List_DoubleOptIn__c');
        String subdomain = (String) mcc.get(prefix + 'API_Subdomain__c');
        
       //String authToken = ClsMarketingCloudHelper.getAuthToken(clientId, clientSecret, tokenUrl);
        String authToken = ClsMarketingCloudHelper.getAuthToken(clientId, clientSecret, subdomain);
        
        System.debug(authToken);
        
        if(authToken != null){
            String requestXML = null;

            if (recordId.getSobjectType() == Schema.Lead.SObjectType) {
                Lead leadToUpdate = [SELECT Id, Email FROM Lead WHERE Id = :recordId];
                requestXML = createOptOutSubscriberXML(authToken, leadToUpdate.Email, leadToUpdate.Id);

                //HttpResponse response = processSoapCallout(mcc.Marketing_cloud_instance__c, 'POST', 'Create', requestXML);
                HttpResponse response = processSoapCallout(mcc, 'POST', 'Create', requestXML);
                if(response.getStatusCode() == 200) {
                    leadToUpdate.Email_Double_Opt_In_Subscriber__c = null;
                    leadToUpdate.Email_Pending_Opt_Out__c = false;
                    leadToUpdate.Email_Opt_In_List__c = 'False';
                    if (updateRecord){
                        update leadToUpdate;
                    }
                    return leadToUpdate;
                }
            } else if (recordId.getSobjectType() == Schema.Account.SObjectType) {
                //get converted lead if we had one
                Lead convertedLead = null;
                for (Lead l : [SELECT Id FROM Lead WHERE ConvertedAccountId = :recordId]) {
                    convertedLead = l;
                }

                Account accountToUpdate = [SELECT Id, PersonContactId, PersonEmail FROM Account WHERE Id = :recordId];

                //check if subscriberKey is Lead or Contact
                List<SObject> records = new List<SObject>();
                records.add(accountToUpdate);
                if (convertedLead != null) {
                    records.add(convertedLead);
                }
                Map<String, ClsMarketingCloudHelperEmail.SubscriberStatus> subscriberMap = retrieveSubscribersForObjects(records, false);
                System.debug('subscriberMap');
                System.debug(records);
                System.debug(subscriberMap);
                Boolean hasError = false;
                Boolean callCompleted = false;
                if (convertedLead != null && subscriberMap.containsKey(convertedLead.Id)) {
                    requestXML = createOptOutSubscriberXML(authToken, accountToUpdate.PersonEmail, convertedLead.Id);

                    //HttpResponse response = processSoapCallout(mcc.Marketing_cloud_instance__c, 'POST', 'Create', requestXML);
                    HttpResponse response = processSoapCallout(mcc, 'POST', 'Create', requestXML);
                    System.debug(response);
                    if(response.getStatusCode() == 200) {
                        callCompleted = true;
                    } else {
                        hasError = true;
                    }
                }

                //Regardless of the contactId already existing in Marketing Cloud as a subscriber, we will push the opt-out
                requestXML = createOptOutSubscriberXML(authToken, accountToUpdate.PersonEmail, accountToUpdate.PersonContactId);

                //HttpResponse response = processSoapCallout(mcc.Marketing_cloud_instance__c, 'POST', 'Create', requestXML);
                HttpResponse response = processSoapCallout(mcc, 'POST', 'Create', requestXML);
                if(response.getStatusCode() == 200) {
                    callCompleted = true;
                } else {
                    hasError = true;
                }

                if (!hasError && callCompleted) {
                    accountToUpdate.Email_Double_Opt_In_Subscriber__c = null;
                    accountToUpdate.Email_Pending_Opt_Out__c = false;
                    accountToUpdate.Email_Opt_In_List__c = 'False';
                    if (updateRecord){
                        update accountToUpdate;
                    }
                    return accountToUpdate;
                }
            }
        }
        return null;
    }

    private static HttpResponse processSoapCallout(Marketing_Cloud_Connection__mdt mcc, String method, String soapAction, String requestXML) {
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setHeader('Content-Type','text/xml');
        request.setHeader('SOAPAction', soapAction);
        request.setBody(requestXML);
        request.setTimeout(120000);
        //request.setEndpoint(ClsMarketingCloudHelper.getMarketingCloudEndpointUrl(instance));
        request.setEndpoint('https://' + mcc.DE_API_Subdomain__c + ClsMarketingCloudHelper.SOAP_BASE_URI);

        //send the request
        Http http = new Http();
        HttpResponse response = http.send(request);
        return response;
    }

    /*supports a mixed List of Lead and Account Sobjects to return the Subscriber or ListSubscriber for each if it exists*/
    public static Map<String, SubscriberStatus> retrieveSubscribersForObjects(List<SObject> records, Boolean callListSubscribers){
        // get record type prefix
        String prefix = ClsMarketingCloudHelper.getRecordTypePrefix(records[0].Id);
       
        Marketing_Cloud_Connection__mdt mcc = ClsMarketingCloudHelper.getConnectionRecord();
        
        //String tokenUrl = mcc.Token_Url__c;
        String clientId = (String) mcc.get(prefix + 'Client_Id__c');
        String clientSecret = (String) mcc.get(prefix + 'Client_Secret__c');
        String listId = (String) mcc.get(prefix + 'List_DoubleOptIn__c');
        String subdomain = (String) mcc.get(prefix + 'API_Subdomain__c');
        
       //String authToken = ClsMarketingCloudHelper.getAuthToken(clientId, clientSecret, tokenUrl);
        String authToken = ClsMarketingCloudHelper.getAuthToken(clientId, clientSecret, subdomain);
        
        List<String> subscriberKeys = new List<String>();
            
        if(authToken != null){
            for (SObject record : records) {
                Id recordId = (Id)record.get('Id');
                if (recordId.getSobjectType() == Schema.Lead.SObjectType) {
                    subscriberKeys.add((String)record.get('Id'));
                } else if (recordId.getSobjectType() == Schema.Account.SObjectType) {
                    subscriberKeys.add((String)record.get('PersonContactId'));
                }
            }

            String requestXML = null;
            System.debug('retrieveSubscribersForObjects:subscriberKeys');
            System.debug(subscriberKeys);

            if (callListSubscribers) {
                requestXML = retrieveListSubscribersXML(authToken, subscriberKeys, listId);
            } else {
                requestXML = retrieveSubscribersXML(authToken, subscriberKeys);
            }

            //HttpResponse response = processSoapCallout(mcc.Marketing_cloud_instance__c, 'GET', 'Retrieve', requestXML);
            HttpResponse response = processSoapCallout(mcc, 'GET', 'Retrieve', requestXML);

            String responseBody = response.getBody();
            System.debug('responseBody:' + responseBody);

            XmlStreamReader reader = new XmlStreamReader(responseBody); 
            Map<String, SubscriberStatus> resultMap = parseSubscribers(reader, listId);
            return resultMap;
        }
        return null;
     }
   
    public class SubscriberStatus {
        public String subscriberKey {get;set;}
        public String status {get;set;}
        public String emailAddress {get;set;}
        public String listId {get;set;}
    }

    //**XML Request Methods
    private static String openSoapBody(String accesstoken) {
        return '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema"'
            +' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
            +'<soapenv:Header><fueloauth xmlns="http://exacttarget.com">' + accessToken + '</fueloauth></soapenv:Header>'
            +'<soapenv:Body>';
    }

    private static String closeSoapBody() {
        return '</soapenv:Body></soapenv:Envelope>';
    }
    
   //transaction is in upsert mode in case the subscriber key already exists
   //subscriber will be set as active
   //listsubscriber will be set as unsubscribed
   //triggered send tells marketing cloud to send the email confirmation
   private static String createSubscriberAndTriggerSendXML(String accessToken, String emailAddress, String subscriberkey, String listId, String triggeredSendId){  
        String body = '<CreateRequest xmlns="http://exacttarget.com/wsdl/partnerAPI">'
            +'<Options><SaveOptions>'
            +'<SaveOption><PropertyName>*</PropertyName><SaveAction>UpdateAdd</SaveAction></SaveOption>'
            +'</SaveOptions></Options>'
            +'<Objects xsi:type="Subscriber">'
            +'<PartnerKey xsi:nil="true"></PartnerKey>'
            +'<ObjectID xsi:nil="true"></ObjectID>'
            +'<EmailAddress>' + emailAddress + '</EmailAddress>'
            +'<SubscriberKey>' + subscriberkey + '</SubscriberKey>'
            +'<EmailTypePreference>HTML</EmailTypePreference>'
            +'<Lists><partnerkey xsi:nil="true"></partnerkey><ID>' + listId + '</ID>'
            +'<ObjectID xsi:nil="true"></ObjectID><Status>Unsubscribed</Status></Lists>'
            +'<Status>Active</Status>'
            +'</Objects>'
            +'<Objects xsi:type="TriggeredSend">'
            +'<PartnerKey xsi:nil="true"></PartnerKey>'
            +'<ObjectID xsi:nil="true"></ObjectID>'
            +'<TriggeredSendDefinition>'
            +'<PartnerKey xsi:nil="true"></PartnerKey>'
            +'<ObjectID xsi:nil="true"></ObjectID>'
            +'<CustomerKey>' + triggeredSendId + '</CustomerKey>'
            +'</TriggeredSendDefinition>'
            +'<Subscribers>'
            +'<PartnerKey xsi:nil="true"></PartnerKey>'
            +'<ObjectID xsi:nil="true"></ObjectID>'
            +'<EmailAddress>' + emailAddress + '</EmailAddress>'
            +'<SubscriberKey>' + subscriberkey + '</SubscriberKey>'
            +'</Subscribers>'
            +'</Objects>'
            +'</CreateRequest>';
 
        return openSoapBody(accesstoken) + body + closeSoapBody();
    }

    //transaction is in upsert mode in case the subscriber key already exists
    //subscriber will be set as unsubscribed
    //listsubscriber is not set and remains in previous state
    private static String createOptOutSubscriberXML(String accessToken, String emailAddress, String subscriberkey){
        String body = '<CreateRequest xmlns="http://exacttarget.com/wsdl/partnerAPI">'
            +'<Options><SaveOptions>'
            +'<SaveOption><PropertyName>*</PropertyName><SaveAction>UpdateAdd</SaveAction></SaveOption>'
            +'</SaveOptions></Options>'
            +'<Objects xsi:type="Subscriber">'
            +'<PartnerKey xsi:nil="true"></PartnerKey>'
            +'<ObjectID xsi:nil="true"></ObjectID>'
            +'<EmailAddress>' + emailAddress + '</EmailAddress>'
            +'<SubscriberKey>' + subscriberkey + '</SubscriberKey>'
            +'<EmailTypePreference>HTML</EmailTypePreference>'
            +'<Status>Unsubscribed</Status>'
            +'</Objects>'
            +'</CreateRequest>';
 
        return openSoapBody(accesstoken) + body + closeSoapBody();
    }

    private static String retrieveSubscribersXML(String accessToken, List<String> subscriberKeys){  
        //https://developer.salesforce.com/docs/atlas.en-us.noversion.mc-apis.meta/mc-apis/subscriber.htm
        String body = '<RetrieveRequestMsg xmlns="http://exacttarget.com/wsdl/partnerAPI">'
            +'<RetrieveRequest>'
            +'<ObjectType>Subscriber</ObjectType>'
            +'<Properties>CreatedDate</Properties>'
            +'<Properties>EmailAddress</Properties>'
            +'<Properties>SubscriberKey</Properties>'
            +'<Properties>Status</Properties>'
            +'<Filter xsi:type="SimpleFilterPart">'
            +'<Property>SubscriberKey</Property>';

        if (subscriberKeys.size() > 1) {
            body += '<SimpleOperator>IN</SimpleOperator>';
        } else {
            body += '<SimpleOperator>equals</SimpleOperator>';
        }

        //Status Unsubscribed is an opt out
        for (String subscriberKey : subscriberKeys){
            body += '<Value>' + subscriberKey + '</Value>';
        }

        body +='</Filter>'
            +'</RetrieveRequest>'
            +'</RetrieveRequestMsg>';
     
        return openSoapBody(accesstoken) + body + closeSoapBody();
    }
    
    private static String retrieveListSubscribersXML(String accessToken, List<String> subscriberKeys, String listId){  
        //https://developer.salesforce.com/docs/atlas.en-us.noversion.mc-apis.meta/mc-apis/listsubscriber.htm
        //https://developer.salesforce.com/docs/atlas.en-us.noversion.mc-apis.meta/mc-apis/simplefilterpart.htm
        String body = '<RetrieveRequestMsg xmlns="http://exacttarget.com/wsdl/partnerAPI">'
            +'<RetrieveRequest>'
            +'<ObjectType>ListSubscriber</ObjectType>'
            +'<Properties>CreatedDate</Properties>'
            +'<Properties>ListID</Properties>'
            +'<Properties>SubscriberKey</Properties>'
            +'<Properties>Status</Properties>'

            /*complex type was not working with IN
            +'<Filter xsi:type="par:ComplexFilterPart">'
            +'<LeftOperand xsi:type="par:SimpleFilterPart">'
            +'<Property>ListID</Property>'
            +'<SimpleOperator>equals</SimpleOperator>'
            +'<Value>' + listId + '</Value>'
            +'</LeftOperand>'
            +'<LogicalOperator>AND</LogicalOperator>'
            +'<RightOperand xsi:type="par:SimpleFilterPart">'
            +'<Property>SubscriberKey</Property>'
            +'<SimpleOperator>IN</SimpleOperator>';*/
            
            +'<Filter xsi:type="SimpleFilterPart">'
            +'<Property>SubscriberKey</Property>';
            
        if (subscriberKeys.size() > 1) {
            body += '<SimpleOperator>IN</SimpleOperator>';
        } else {
            body += '<SimpleOperator>equals</SimpleOperator>';
        }

        for (String subscriberKey : subscriberKeys){
            body += '<Value>' + subscriberkey + '</Value>';
        }

        //body +='</RightOperand>';

        body +='</Filter>'
            +'</RetrieveRequest>'
            +'</RetrieveRequestMsg>';

        return openSoapBody(accesstoken) + body + closeSoapBody();
    }

    //**XML Response Read Methods

    /*designed to parse subscribers and listsubscribers*/
    private static Map<String, SubscriberStatus> parseSubscribers(XmlStreamReader reader, String listId) {
        
        Map<String, SubscriberStatus> subscriberMap = new Map<String, SubscriberStatus>();
        Boolean isSafeToGetNextXmlElement = true;
        SubscriberStatus subscriber = null;
        
        while(isSafeToGetNextXmlElement) {
            
            if (reader.getEventType() == XmlTag.START_ELEMENT) {
                String localName = reader.getLocalName();

                if (localName == 'Results') {
                    //if listId was set, it must equal our supplied listId, else let it go through if null for subscriber call
                    if (subscriber != null && (subscriber.listId == null || subscriber.listId == listId)) {
                        subscriberMap.put(subscriber.subscriberKey, subscriber);
                    }
                    subscriber = new SubscriberStatus();
                } else if (localName == 'Status') {
                    subscriber.status = parseValue(reader);
                } else if (localName == 'SubscriberKey') {
                    subscriber.subscriberKey = parseValue(reader);
                } else if (localName == 'EmailAddress') {
                    subscriber.emailAddress = parseValue(reader);
                } else if (localName == 'ListID') {
                    subscriber.listId = parseValue(reader);
                }
            }
            if (reader.hasNext()) {
                reader.next();
            } else {
                isSafeToGetNextXmlElement = false;
                break;
            }
        }
        if (subscriber != null && (subscriber.listId == null || subscriber.listId == listId)) {
            subscriberMap.put(subscriber.subscriberKey, subscriber);
        }

        return subscriberMap;
    }

   
    private static String parseValue(XmlStreamReader reader) {
        boolean isSafeToGetNextXmlElement = true;
        while(isSafeToGetNextXmlElement) {
            if (reader.getEventType() == XmlTag.END_ELEMENT) {
                break;
            } else if (reader.getEventType() == XmlTag.CHARACTERS) {
                return reader.getText();
            }
            if (reader.hasNext()) {
                reader.next();
            } else {
                isSafeToGetNextXmlElement = false;
                break;
            }
        }
        return null;
    }

    //**Batch processing helper methods against current subscriber status in marketing cloud

    public static Lead processSubscriber(Lead l, SubscriberStatus subscriber, SubscriberStatus listSubscriber) {
        Boolean fieldUpdate = false;

        //if marketing cloud email does not match, we assume that the user updated their email address in MC and Sales cloud must sync
        if (l.Email != subscriber.emailAddress) {
            l.Email = subscriber.emailAddress;
            fieldUpdate = true;
        }

        if (listSubscriber != null && l.Email_Pending_Opt_In__c){
            if (listSubscriber.status == 'Active'){
                l.Email_Opt_In_List__c = 'True';
                l.Email_Pending_Opt_In__c = false;
                fieldUpdate = true;
            }
        }

        if (l.Email_Opt_In_List__c == 'True'){ 
            if (subscriber.status == 'Unsubscribed'){
                l.Email_Opt_In_List__c = 'False';
                l.Email_Pending_Opt_In__c = false;
                l.Email_Double_Opt_In_Subscriber__c = null;
                fieldUpdate = true;
            }
        }

        if (fieldUpdate) {
            return l;
        }
        return null;
    }

    public static Account processSubscriber(Account a, SubscriberStatus subscriber, SubscriberStatus listSubscriber) {
        Boolean fieldUpdate = false;

        //if marketing cloud email does not match, we assume that the user updated their email address in MC and Sales cloud must sync
        if (a.PersonEmail != subscriber.emailAddress) {
            a.PersonEmail = subscriber.emailAddress;
            fieldUpdate = true;
        }

        if (listSubscriber != null && a.Email_Pending_Opt_In__c){
            if (listSubscriber.status == 'Active'){
                a.Email_Opt_In_List__c = 'True';
                a.Email_Pending_Opt_In__c = false;
                fieldUpdate = true;
            }
        }

        if (a.Email_Opt_In_List__c == 'True'){ 
            if (subscriber.status == 'Unsubscribed'){
                a.Email_Opt_In_List__c = 'False';
                a.Email_Pending_Opt_In__c = false;
                a.Email_Double_Opt_In_Subscriber__c = null;
                fieldUpdate = true;
            }
        }

        if (fieldUpdate) {
            return a;
        }
        return null;
    }
}