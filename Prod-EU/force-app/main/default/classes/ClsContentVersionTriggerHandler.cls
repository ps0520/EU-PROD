/*******************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 10/07/2018
@Description    : Trigger handler invokes the logic for Content Version
********************************************************************************************************************/
public class ClsContentVersionTriggerHandler {
    
    //This method will upsert the Content_Metadata__c based on the ContentDocumentId 
    public static void ProcessContentMetaData (List<ContentVersion> contentVersionsToBeProcessed)
    {
        List<Content_Metadata__c> customMetadataToBeUpsertedList = new List<Content_Metadata__c>();//Content Metadata List to be upserted 
        
        for(ContentVersion cv : contentVersionsToBeProcessed)
        {
            //For the regular Files uploaded, sync up the Content_Metadata__c record
            //if(cv.FileType != 'SNOTE')
            //{
            Content_Metadata__c contentMetadata = new Content_Metadata__c (Content_Document_Id__c = cv.ContentDocumentId);
            contentMetadata.Name = cv.Title;
            contentMetadata.Content_Document_Id__c = cv.ContentDocumentId;
            contentMetadata.Latest_Content_Version_Id__c = cv.Id;
            contentMetadata.Document_Created_By__c = cv.CreatedById;
            contentMetadata.Document_Created_Date__c = cv.CreatedDate;
            contentMetadata.Document_Type__c = cv.Document_Type__c;
            contentMetadata.OwnerId = cv.OwnerId;
            contentMetadata.File_Type__c = cv.FileType;
            contentMetadata.File_Extension__c = cv.FileExtension;
            contentMetadata.Content_Size__c = cv.ContentSize;
            contentMetadata.Source__c = cv.Source__c;
            customMetadataToBeUpsertedList.add(contentMetadata);
            //}	
        }
        if(!customMetadataToBeUpsertedList.isEmpty())
        {
            try{
                upsert customMetadataToBeUpsertedList Content_Document_Id__c;
            }catch(DmlException e) { System.debug('Exception occurred on Upserting Content_Metadata__c: ' + e.getMessage()); }
        }
    }
}