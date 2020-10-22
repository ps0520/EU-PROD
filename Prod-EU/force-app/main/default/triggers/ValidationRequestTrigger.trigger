/*******************************************************
@Description    : Validation Request Trigger
Author          : Pradeep Sadasivan
********************************************************/ 
trigger ValidationRequestTrigger on QIDC__Validation_Request_ims__c (before insert, after update) {
	List<Account> accountsToUpdate = new List<Account>();
    if(trigger.isBefore){
        	ClsValRequestAccountTriggerHandler.populateVRRequestType(Trigger.New);//populate country code and Request Type
    	}
    if(trigger.isAfter && trigger.isUpdate){
    	ClsValRequestAccountTriggerHandler.updateAccountOneKeyId(Trigger.New);// update OnekeyId on Account
    }
}