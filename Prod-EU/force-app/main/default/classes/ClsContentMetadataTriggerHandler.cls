/*******************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 10/07/2018
@Description    : Content_Metadata__c Trigger handler
********************************************************************************************************************/ 
public class ClsContentMetadataTriggerHandler {
    
    //Method deletes Content Metadata for Notes 
    public static void ProcessContentMetadataDeletes(List<Content_Metadata__c> contentMetadataToBeProcessedForDelete) 
    {
        Set<Id> contentMetadataDeleteSet = new Set<Id>();//Content Metadata List to be deleted
        
        //Loop through the Content Metadata records and delete the ones, which are Notes
        for(Content_Metadata__c cm : contentMetadataToBeProcessedForDelete)
        {
            if(cm.File_Type__c == 'SNOTE')
                contentMetadataDeleteSet.add(cm.Id);
        }
        //Delete the CustomMetaData
        if(!contentMetadataDeleteSet.isEmpty())
            DeleteContentMetadata(contentMetadataDeleteSet);
        
    }
    //Make a future call to delete the Content Metadata for Notes to avoid any trigger context errors
    @future
    public static void DeleteContentMetadata (Set<Id> contentMetadataDeleteSet)
    {
        List<Content_Metadata__c> contentMetataToBeDeleted = [SELECT Id FROM Content_Metadata__c WHERE Id IN : contentMetadataDeleteSet];
        try{
            delete contentMetataToBeDeleted;
        }catch(DmlException e) { System.debug('Exception occurred on deleting Content_Metadata__c: ' + e.getMessage()); }
    }
}