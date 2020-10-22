/*******************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 10/08/2018
@Description    : Handles the trigger logic for Content_Metadata__c object
********************************************************************************************************************/   
trigger ContentMetadataTrigger on Content_Metadata__c (after update) {

    if(trigger.isAfter)
    {
        //Delete Note Metadata after update on File type. The reason we do is we cannot distinguish the Note vs Files in ContentDocument object, so we let it to create from the ContentDocument trigger and then delete the same from here
        if(trigger.isUpdate)
        {
            System.debug('-----ContentMetadataTrigger After Insert Fired');
            ClsContentMetadataTriggerHandler.ProcessContentMetadataDeletes(trigger.new);
        }
    }
}