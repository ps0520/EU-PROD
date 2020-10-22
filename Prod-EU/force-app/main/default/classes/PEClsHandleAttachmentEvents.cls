public class PEClsHandleAttachmentEvents {
    public static void handleIncomingEvents(List<CRM_Attachment_Event__e> attachmentList) {
        
        List<ContentVersion> ListNewDocs = new List<ContentVersion>();
        Set<String> SetOrdNums = new Set<String>();
        Set<String> SetDocNames = new Set<String>();
       	Map<String, ContentVersion> MapExistingDocs = new Map<String, ContentVersion>();
        Map<String, Id> MapExistingOrders = new Map<String, Id>();
        List<Platform_Event_Error_Log__c> ListPlatErrLog = new List<Platform_Event_Error_Log__c>();
        List<ContentDocumentLink> ListOrdUpdate = new List<ContentDocumentLink>();
        Map<String, String> MapDocToOrder = new Map<String, String>();
        for(CRM_Attachment_Event__e att : attachmentList) {
            System.debug('**att.referenceNumberValue__c--'+att.referenceNumberValue__c);
            SetOrdNums.add(att.referenceNumberValue__c);
            SetDocNames.add(att.referenceNumberValue__c + '-' + att.name__c);
            MapDocToOrder.put(att.name__c, att.referenceNumberValue__c);
        }
        for(ContentVersion existingDoc : [Select Id, ContentDocumentId, Title, CreatedDate from ContentVersion where Title in :SetDocNames])
            MapExistingDocs.put(existingDoc.Title, existingDoc);
        for(Order ord : [Select Id, OrderNumber from Order where OrderNumber in :SetOrdNums])
            MapExistingOrders.put(ord.OrderNumber, ord.Id);
        
        for(CRM_Attachment_Event__e att : attachmentList) {
            if (!MapExistingOrders.containsKey(att.referenceNumberValue__c)) {
                ListPlatErrLog.add(ErrorUtility.prepareErroLog('consume', 'PEClsHandleAttachmentEvents.handleIncomingEvents', 'Order listed in Attachment not found', 'attachment', att.eventSource__c, 'Order Number: ' + att.referenceNumberValue__c + ' not found.', att.eventSourceID__c, 'Informational', ''));
				continue;
            }
            if (MapExistingDocs.containsKey(att.name__c)) {
                ListPlatErrLog.add(ErrorUtility.prepareErroLog('consume', 'PEClsHandleAttachmentEvents.handleIncomingEvents', 'Duplicate Document Received', 'attachment', att.eventSource__c, 'Atacchment was already received on ' + MapExistingDocs.get(att.name__c).CreatedDate, att.eventSourceID__c, 'Informational', ''));
				continue;
            }
            // Call here @Future Method
            loadContentFile(att.referenceNumberValue__c, att.content__c, att.name__c, att.eventSource__c, att.eventSourceID__c, MapExistingOrders.get( att.referenceNumberValue__c));
        }
    }
    
    @Future (callout=true)
    public static void loadContentFile(String referenceNumberValue, String content, String name, String eventSource, String eventSourceID, Id orderId) {
        //Get the Access Token. If it is not available, we will call a queueable job.
        System.debug('**GoogleAuthentication.READ_SCOPE--'+GoogleAuthentication.READ_SCOPE);
        GoogleAuthentication.AuthenticationResponse response = GoogleAuthentication.getAccessToken(GoogleAuthentication.READ_SCOPE);
        if (response.requiresAjaxCall == true ) {
            System.enqueueJob(new LoadFileQueuable(referenceNumberValue, content, name, eventSource, eventSourceID, orderId));
            return;
        } else {
            LoadFilecontent(referenceNumberValue, content, name, eventSource, eventSourceID, orderId, response);
            return;
        }
        
    }
    public static void LoadFilecontent(String referenceNumberValue, String content, String name, String eventSource, String eventSourceID, Id orderId, GoogleAuthentication.AuthenticationResponse response) {
        List<ContentVersion> ListNewDocs = new List<ContentVersion>();
        List<ContentDocumentLink> ListOrdUpdate = new List<ContentDocumentLink>();
        ContentVersion doc = new ContentVersion();
        doc.ContentLocation = 'S';
        doc.PathOnClient = referenceNumberValue + '.pdf';
        doc.Title = referenceNumberValue + '-' + name;
        Blob blobContent = FetchFromGoogleStorage.getGoogleDoc(content.subString(4), response.accessToken);
        if (blobContent == null) {
            ErrorUtility.LogError('Consume', 'PEClsHandleAttachmentEvents.handleIncomingEvents', 'Error in Consuming Attachment Create Operations.', 'Attachment', eventSource, 
                                  'Could not get access to the content - Bailing out.' , eventSourceID, 'Informational') ;
            return;
        }
        doc.VersionData = blobContent;
        doc.Description = referenceNumberValue;
        ListNewDocs.add(doc);
        Set<Id> ListInsertedFileIds = new set<id>();
        if (ListNewDocs.size() > 0) {
            Database.SaveResult[] ListDsr = Database.Insert(ListNewDocs, False);
            Integer i = 0;
            String ErrorString = '';
            for(Database.SaveResult dsr : ListDsr) {
                if (dsr.isSuccess()) { 
                    ListInsertedFileIds.add(dsr.getId());
                } else {
                    ErrorString = '';
                    for(Database.Error err : dsr.getErrors()) ErrorString += err + '; ';
                   //ErrorUtility.LogError(action, classNMethodName, errorMsg, eventType, eventSource, exceptionError, externalID, severity)
                    ErrorUtility.LogError('consume', 'PEClsHandleAttachmentEvents.handleIncomingEvents', 'Error in Creating a Doc in Salesforce', 'attachment', eventSource, ErrorString, eventSourceID, 'Informational');
                }
            }
        }
        If (ListInsertedFileIds.size() > 0) {
            List<ContentVersion> ListInsertedFiles = [SELECT ContentDocumentId FROM ContentVersion WHERE Id in :ListInsertedFileIds];
            for(ContentVersion cv : ListInsertedFiles) {
                ContentDocumentLink conDocLink = New ContentDocumentLink();
                conDocLink.LinkedEntityId = orderId;
                conDocLink.ContentDocumentId = cv.ContentDocumentId;
                conDocLink.shareType = 'V';
                ListOrdUpdate.add(conDocLink);
            }
        }
        Set<Id> addedContentDocLinks = new Set<Id>();
        if (ListOrdUpdate.size() > 0) {
            Database.SaveResult[] ListDsr = Database.insert(ListOrdUpdate, False);
            Integer i = 0;
            String ErrorString = '';
            for(Database.SaveResult dsr : ListDsr) {
                if (!dsr.isSuccess()) {
                    ErrorString = '';
                    for(Database.Error err : dsr.getErrors()) ErrorString += err + '; ';
                    ErrorUtility.LogError('consume', 'PEClsHandleAttachmentEvents.handleIncomingEvents', 'Error setting up a relationship between Doc & Order', 'attachment', eventSource, ErrorString, eventSourceID, 'Informational');
                } else addedContentDocLinks.add(dsr.getId());
            }
        }
        if (addedContentDocLinks.size() > 0) {
            List<Order> orderPODUpdateList = new List<Order>();
            List<ContentDocumentLink> sucessfulCDLList = [Select LinkedEntityId from ContentDocumentLink where id in :addedContentDocLinks];
            for(ContentDocumentLink cdl : sucessfulCDLList) orderPODUpdateList.add(new Order(id=cdl.LinkedEntityId, POD_Received__c = true));
            Database.SaveResult[] ListDsr = Database.Update(orderPODUpdateList, False);
            Integer i = 0;
            String ErrorString = '';
            for(Database.SaveResult dsr : ListDsr) {
                if (!dsr.isSuccess()) {
                    ErrorString = '';
                    for(Database.Error err : dsr.getErrors()) ErrorString += err + '; ';
                    ErrorUtility.LogError('consume', 'PEClsHandleAttachmentEvents.handleIncomingEvents', 'Error updating Order with POD Delivery Status', 'attachment', eventSource, ErrorString, eventSourceID, 'Informational');
                }
            }
        }
    }
    
    public class LoadFileQueuable implements Queueable, Database.AllowsCallouts{
        public String referenceNumberValue;
        public String content;
        public String name;
        public String eventSource;
        public String eventSourceID;
        public Id orderId;
        public LoadFileQueuable(String referenceNumberValue, String content, String name, String eventSource, String eventSourceID, Id orderId){
            this.referenceNumberValue = referenceNumberValue;
            this.content = content;
            this.name = name;
            this.eventSource = eventSource;
            this.eventSourceID = eventSourceID;
            this.orderId = orderId;
        }
        public void execute(QueueableContext context) {
            GoogleAuthentication.AuthenticationResponse response =
                    GoogleAuthentication.getAccessToken(GoogleAuthentication.READ_SCOPE);
            if (response.requiresAjaxCall == true ) {
                ErrorUtility.LogError('Consume', 'PEClsHandleAttachmentEvents.LoadFileQueuable', 'Error in getting the AccessToken.', 'Attachment', eventSource, 
                                      'Could not get the AccessToken in Queuable Job too. - Bailing out.' , eventSourceID, 'Informational') ;
                //System.enqueueJob(new LoadFileQueuable(referenceNumberValue, content, name, eventSource, eventSourceID, orderId));
                return;
            } else {
                PEClsHandleAttachmentEvents.LoadFilecontent(referenceNumberValue, content, name, eventSource, eventSourceID, orderId, response);
                return;
            }
        }        
    }
}