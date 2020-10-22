/*******************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 10/07/2018
@Description    : CDL Trigger Handler
********************************************************************************************************************/ 
public class ClsContentDocumentTriggerHandler {
    
    //Method handles the ContentDocument Inserts
    //There is no way to tell if the inserted file is a Note or not, so we let it to insert and then delete it afterwards based on the trigger on Content_Metadata__c object
    public static void ProcessContentDocumentInserts(Map<Id, ContentDocument> contentDocumentsToInsertMap) 
    {
        List<Content_Metadata__c> contentMetadataToBeInsertedList = new List<Content_Metadata__c>();//Content Metadata List to be inserted
        
        //For each ContentDocument inserted create a new Content Metadata record. Notes should be ignored
        for(ContentDocument cd : contentDocumentsToInsertMap.values())
        {
            Content_Metadata__c contentMetadata = new Content_Metadata__c();
            contentMetadata.Content_Document_Id__c = cd.Id;
            contentMetadata.Name = cd.Title;
            contentMetadata.Description__c = cd.Description;
            
            contentMetadataToBeInsertedList.add(contentMetadata);
        }
        //Upsert the CustomMetaData
        if(!contentMetadataToBeInsertedList.isEmpty())
        {
            try{
                upsert contentMetadataToBeInsertedList Content_Document_Id__c;
            }catch(DmlException e) { System.debug('Exception occurred on Upserting Content_Metadata__c: ' + e.getMessage()); }
        }
    }
    //INC0293745- Method to update Content Metdata Description when Content document Description is updated 
    public static void ProcessContentDocumentUpdate(List<ContentDocument> contentDocumentsToUpdateList){
        Set<String> listIds = new Set<String>();
        if(!contentDocumentsToUpdateList.isEmpty()){   
        	for (ContentDocument cont : contentDocumentsToUpdateList){
        		listIds.add(cont.id) ;         
        	}
        }
        if(!listIds.isEmpty() && listIds!=null){
            List<Content_Metadata__c> contentMetadata = [Select id,Description__c,Content_Document_Id__c from Content_Metadata__c where Content_Document_Id__c IN:listIds ];        
        	//For each ContentDocument Description Update the Content Metadata record is updated.
       		 if(!contentMetadata.isEmpty()){
        		for(ContentDocument cd : contentDocumentsToUpdateList){
                    for(Content_Metadata__c c : contentMetadata){
                       c.Description__c = cd.Description;    
            		}
                }
        		//Update the CustomMetaData
				try{
                    System.debug('@@@@@@@@@Line-56@@@@@@ - ' + contentMetadata);
        			update contentMetadata;
				}catch(DmlException e) { System.debug('Exception occurred on Upserting Content_Metadata__c: ' + e.getMessage()); }
        	}
        }
    }
    //Method handles the ContentDocument Deletes
    public static void ProcessContentDocumentDeletes(Map<Id, ContentDocument> contentDocumentsToDeleteMap) 
    {
        List<Content_Metadata__c> contentMetadataToBeDeletedList = new List<Content_Metadata__c>();//Content Metadata List to be Deleted
        //Look for the Content Metadata corresponding the ContentDocument, which is deleted and then delete the Content Metadata record
        for(Content_Metadata__c contentMetadata : [SELECT Id FROM Content_Metadata__c WHERE Content_Document_Id__c IN : contentDocumentsToDeleteMap.keySet()])
            contentMetadataToBeDeletedList.add(contentMetadata);
        
        //Delete the CustomMetaData
        if(!contentMetadataToBeDeletedList.isEmpty())
        {
            try{
                delete contentMetadataToBeDeletedList;
            }catch(DmlException e) { System.debug('Exception occurred on deleting Content_Metadata__c: ' + e.getMessage()); }
        }
    }
    
}