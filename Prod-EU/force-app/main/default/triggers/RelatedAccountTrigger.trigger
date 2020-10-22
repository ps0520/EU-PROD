trigger RelatedAccountTrigger on Related_Account__c (before insert, before update, after insert,after update) {
/*******************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 5/01/2017
@Description    : Trigger invokes handler class to update Related Account information on parent Account
********************************************************************************************************************/    
    if(trigger.isBefore)
    {
      	//Check duplicates. Duplicate management cannot be used because of multiple lookups, so we are taking this trigger approach      
		if(trigger.isInsert)
        {
            ClsRelatedAccountTriggerHandler.checkIfChildToParentRelationExists(trigger.new);
        }  
    }
    
    
    if(trigger.isAfter)
    {
        //Proceed to make changes to Related Account object only when the change happened from Related Account object       
		if(trigger.isInsert)
        {
            if(ClsAccountAddressTriggerStaticClass.medFacChangedInvokedFromRelatedAccount)
            	ClsRelatedAccountTriggerHandler.processRelatedAccounts(trigger.new, null, null);
        }
        if(trigger.isUpdate)
        {
            if(ClsAccountAddressTriggerStaticClass.medFacChangedInvokedFromRelatedAccount)
            	ClsRelatedAccountTriggerHandler.processRelatedAccounts(trigger.new, trigger.newmap, trigger.oldmap);
        }
    }
    
}