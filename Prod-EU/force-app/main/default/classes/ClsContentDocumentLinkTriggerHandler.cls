/*******************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 10/07/2018
@Description    : CDL Trigger Handler
********************************************************************************************************************/ 
public class ClsContentDocumentLinkTriggerHandler {
    
    //Method will update the lookup relationship on the Content_Metadata__c object
    public static void ProcessContentDocumentLink(list<ContentDocumentLink> cdlsToProcess) 
    {
        //Initialize variable and collections
        Set<Id> contentDocumentIdSet = new Set<Id>();//Set holds unique list of ContentDocumentIds
        List<ContentDocumentLink> accountToBeLinkedList  = new List<ContentDocumentLink>(); //List of accounts to be linked   
        List<ContentDocumentLink> opptyToBeLinkedList  = new List<ContentDocumentLink>();//List of opportunities to be linked
        Map<String, ContentDocumentLink> cdlsToBeInsertedMap = new Map<String, ContentDocumentLink>();//Map holds the unique CDLs to be created
        Map<String, Content_Metadata__c> customMetadataToBeUpdatedMap = new Map<String, Content_Metadata__c>();//Map holds the content metadata that needs to be updated
        Map<Id, Id> contentDocumentIdToContentMetaDataIdMap = new Map<Id, Id>();//Map between the content document id and content metadata id
        Map<Id, Id> accountIdToContentDocumentIdMap = new Map<Id, Id>();
        Map<Id, Id> opptyIdToContentDocumentIdMap = new Map<Id, Id>();
        String objectId;
        String uniqueId;
        
        //Populate the collections for the processing to happen
        for(ContentDocumentLink cdl : cdlsToProcess)
        {
            contentDocumentIdSet.add(cdl.ContentDocumentId);
            
            //Prepare the collections to process the new CDL Inserts based on document linked entitiy
            objectId = string.valueOf(cdl.linkedentityid).substring(0,3);
            switch on objectId{
                when '001'{//Link Oppty to docment upon Account Insert
                    opptyToBeLinkedList.add(cdl);
                    accountIdToContentDocumentIdMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
                }
                when '006'{//Link Account to docment upon Oppty Insert
                    accountToBeLinkedList.add(cdl);
                    opptyIdToContentDocumentIdMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
                }
            }
        }
        
        //-------------START - Logic to insert the CDLs based on the Account or Opportunity CDL Inserts ------------------------
        //Process Opportunity CDLs
        if(opptyToBeLinkedList.size() > 0 && ClsCheckRecursive.runOnce())
        {
            
            //Link Oppty to docment upon Account CDL Insert
            for(Opportunity oppty: [SELECT Id, AccountId, name, OwnerId, Isclosed FROM Opportunity WHERE StageName != 'Cancelled' AND StageName != 'Closed - Complete' AND AccountId IN: accountIdToContentDocumentIdMap.keySet()])
            {
                ContentDocumentLink opptyCDL = new ContentDocumentLink();   
                opptyCDL.LinkedEntityId = oppty.Id;
                opptyCDL.ShareType = 'V';
                opptyCDL.Visibility = 'AllUsers'; 
                opptyCDL.ContentDocumentId = accountIdToContentDocumentIdMap.get(oppty.AccountId);
                uniqueId = opptyCDL.LinkedEntityId+'-'+opptyCDL.ContentDocumentId;
                cdlsToBeInsertedMap.put(uniqueId, opptyCDL);
            }
        }
        //Process Account CDLs
        if(accountToBeLinkedList.size() > 0 && ClsCheckRecursive.runOnce())
        {
            //Link Account to docment upon Oppty CDL Insert
            for(Opportunity oppty: [SELECT Id, AccountId, name, OwnerId, Isclosed FROM Opportunity WHERE Id IN: opptyIdToContentDocumentIdMap.keySet()])
            {
                ContentDocumentLink accountCDL = new ContentDocumentLink();   
                accountCDL.LinkedEntityId = oppty.AccountId;
                accountCDL.ShareType = 'V';
                accountCDL.Visibility = 'AllUsers';
                accountCDL.ContentDocumentId = opptyIdToContentDocumentIdMap.get(oppty.Id);
                uniqueId = accountCDL.LinkedEntityId+'-'+accountCDL.ContentDocumentId;
                cdlsToBeInsertedMap.put(uniqueId, accountCDL);
            }
        }
        //Insert CDLs
        if(!cdlsToBeInsertedMap.isEmpty())
        {
            try{
                Database.SaveResult[] createdCDLList = Database.insert(cdlsToBeInsertedMap.values(), false);
            }catch(DmlException e) { System.debug('Exception occurred on inserting the CDLs: ' + e.getMessage()); }
        }
        
        //-------------END - Logic to insert the CDLs based on the Account or Opportunity CDL Inserts ------------------------
        
        //-------------START - Logic to update the references to Content Metadata start --------------------------------------
        //Get the Custom Metadata records related to the ContentDocumentId inserted
        
        for(Content_Metadata__c cm : [SELECT Id, Content_Document_Id__c FROM Content_Metadata__c WHERE Content_Document_Id__c IN : contentDocumentIdSet])
        {
            contentDocumentIdToContentMetaDataIdMap.put(cm.Content_Document_Id__c, cm.Id);
        }
        
        for(ContentDocumentLink cdl : cdlsToProcess)
        {
            if(contentDocumentIdToContentMetaDataIdMap != null)//Avoid null pointer exception
            {
                if(contentDocumentIdToContentMetaDataIdMap.containsKey(cdl.ContentDocumentId))
                {
                    objectId = string.valueOf(cdl.linkedentityid).substring(0,3);
                    Content_Metadata__c contentMetadata = new Content_Metadata__c (Id = contentDocumentIdToContentMetaDataIdMap.get(cdl.ContentDocumentId));
                    switch on objectId{
                        when '001'{
                            contentMetadata.Account__c = cdl.LinkedEntityId;
                            customMetadataToBeUpdatedMap.put(cdl.ContentDocumentId, contentMetadata);
                        }
                        when '006'{
                            contentMetadata.Opportunity__c = cdl.LinkedEntityId;
                            customMetadataToBeUpdatedMap.put(cdl.ContentDocumentId, contentMetadata);
                        }
                        when '801'{
                            contentMetadata.Order__c = cdl.LinkedEntityId;
                            customMetadataToBeUpdatedMap.put(cdl.ContentDocumentId, contentMetadata);
                        }
                    }
                }
            }
        }
        
        if(!customMetadataToBeUpdatedMap.isEmpty())
        {
            try{
                update customMetadataToBeUpdatedMap.values();
            }catch(DmlException e) { System.debug('Exception occurred on Updating Content_Metadata__c: ' + e.getMessage()); }
        }
        //-------------END - Logic to update the references to Content Metadata start --------------------------------------
        
    }
    
}