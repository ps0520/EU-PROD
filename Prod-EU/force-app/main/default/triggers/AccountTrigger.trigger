trigger AccountTrigger on Account (before insert, before update, after insert,after update,before delete,after delete){
/*******************************************************
@Description    : Handles all Account level interactions
********************************************************/    
    if(trigger.isBefore){
        if(trigger.isInsert){             
            // Added for country specific changes
            ClsAccountCountryHandler.beforeInsertHandler(trigger.new); 
            //Method populates Account Shipping Address from Account Billing Address if the shipping address information is blank
            ClsAccountAddressTriggerHandler.ProcessAccountShippingAddressOnAccountInsert(trigger.new);
            ClsAccountRelatedAccountTriggerHandler.processSoSonAccountCreate(trigger.new);
            //Method to populate Top level Parent for an Account-IQVIA requirement-25-Aug-2020
            ClsAccountValRequestTriggerHandler.updateTopParentAccount(Trigger.new);//NS-743
        }
        if(trigger.isUpdate){       
              //Set the Shipping address when the Copy Billing to Shipping check box is selected
              ClsAccountAddressTriggerHandler.ProcessAccountRelatedAddressOnAccountUpdate(trigger.new);
              //Added for country specific changes 
              ClsAccountCountryHandler.beforeUpdateHandler(trigger.new,trigger.oldmap);              
              //Handle double opt in logic
              ClsAccountDoubleOptInTriggerHandler.doubleOptInBefore(trigger.new,trigger.oldMap);
            //Method to populate Top level Parent for an Account-IQVIA requirement-25-Aug-2020
              ClsAccountValRequestTriggerHandler.updateTopParentAccount(Trigger.new);//NS-743
        } 
        if(trigger.isDelete){
             //After account merge, mapping loosing accounts id to related addresses Loosing Account Id Field
            ClsAccountAddressTriggerHandler.storeAccountRelatedData(trigger.oldMap.Keyset());            
         }
    }
    if(trigger.isAfter)
    {
        if(trigger.isInsert)
        {
            // Publish Create Platform Event
            ClsAccountRelatedAccountTriggerHandler.handlePublish(trigger.new, 'create', trigger.oldMap);
            //Handle double opt in logic
            ClsAccountDoubleOptInTriggerHandler.doubleOptInAfter(trigger.new,trigger.oldMap);
            //Proceed to make changes to Address object only when the address change (Bill To or Ship To) happened from Account object       
            if(ClsAccountAddressTriggerStaticClass.addressChangeInvokedFromAccount)
                ClsAccountAddressTriggerHandler.ProcessAccountRelatedAddressOnAccountInsert(trigger.new);
            //Proceed to make changes to Related Accounts only when the Medical Facility to Prescriber change happened from Account object
            if(ClsAccountAddressTriggerStaticClass.medFacChangedInvokedFromPrescriber)
                ClsAccountRelatedAccountTriggerHandler.processAccountRelatedAccountOnAccountInsert(trigger.new);
            }
        if(trigger.isUpdate)
        {
            //Handle double opt in logic
            ClsAccountDoubleOptInTriggerHandler.doubleOptInAfter(trigger.new,trigger.oldMap);
            //Proceed to make changes to Address object only when the address change (Bill To or Ship To) happened from Account object 
            if(ClsAccountAddressTriggerStaticClass.addressChangeInvokedFromAccount)
                ClsAccountAddressTriggerHandler.ProcessAccountRelatedAddressOnAccountUpdate(trigger.newmap, trigger.oldmap); 
            //Proceed to make changes to Related Accounts only when the Medical Facility to Prescriber change happened from Account object
            if(ClsAccountAddressTriggerStaticClass.medFacChangedInvokedFromPrescriber)
               ClsAccountRelatedAccountTriggerHandler.processAccountRelatedAccountOnAccountUpdate(trigger.newmap, trigger.oldmap);            
            // Publish Update Platform Event
            ClsAccountRelatedAccountTriggerHandler.handlePublish(trigger.new, 'update', trigger.oldMap);  
            //Method to handle territory updates based on Medical Facility, Prescriber and Consumer address information    
            ClsAccountCountryHandler.afterUpdateHandler(trigger.new, trigger.newmap, trigger.oldmap);
            //Method to handle all Marketing Interactions
            if(ClsAccountAddressTriggerStaticClass.invokeMILogicOnlyOnce)
             ClsMarketingInteractionHandler.handleMIsForAccountUpdates(trigger.newmap, trigger.oldmap);
            
        }       
        if(trigger.isDelete){
            //After account merge, Inactivate loosing accounts addresses
            ClsAccountAddressTriggerHandler.processAccountMerge(trigger.old);
        }
    }
}