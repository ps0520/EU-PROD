trigger ContentVersionTrigger on ContentVersion (after insert,after update) {
/*******************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 10/07/2018
@Description    : Trigger invokes handler class for Content Version
********************************************************************************************************************/    
    if(trigger.isAfter)
    {
		//Process custom metadata update on insert and update of the Content Version
		if(trigger.isInsert || trigger.isUpdate)
        {
           	System.debug('-----ContentVersionTrigger After Insert or Update Fired');
            ClsContentVersionTriggerHandler.ProcessContentMetaData(trigger.new);
        }
	}
}