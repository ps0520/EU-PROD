/*******************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 10/07/2018
@Description    : Trigger invokes handler class for ContentDocumentLink
********************************************************************************************************************/  
trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
  
	if(trigger.isAfter)
    {
		//Process custom metadata entitiy association on CDL Insert
		if(trigger.isInsert)
        {
           	System.debug('-----ContentDocumentLinkTrigger After Insert fired');
            ClsContentDocumentLinkTriggerHandler.ProcessContentDocumentLink(trigger.new);
        }
	}
	
}