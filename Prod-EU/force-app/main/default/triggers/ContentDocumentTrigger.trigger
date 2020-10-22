trigger ContentDocumentTrigger on ContentDocument (before delete, after insert, after Update) {
    /*******************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 10/08/2018
@Description    : Handles the trigger logic for ContentDocument object
********************************************************************************************************************/   
    if(trigger.isBefore)
    {
        //Process custom metadata entitiy association on ContentDocument delete
        if(trigger.isDelete)
        {
            System.debug('-----ContentDocumentTrigger Before Delete fired');
            ClsContentDocumentTriggerHandler.ProcessContentDocumentDeletes(trigger.oldmap);
        }
    }
    if(trigger.isAfter)
    {
        //Process custom metadata entitiy association on ContentDocument Insert
        if(trigger.isInsert)
        {
            System.debug('-----ContentDocumentTrigger After Insert fired');
            ClsContentDocumentTriggerHandler.ProcessContentDocumentInserts(trigger.newmap);
        }
        //INC0293745 update description in content metadata Object
        if(trigger.isUpdate)
        {
            ClsContentDocumentTriggerHandler.ProcessContentDocumentUpdate(trigger.new);
        }
    }
    
}