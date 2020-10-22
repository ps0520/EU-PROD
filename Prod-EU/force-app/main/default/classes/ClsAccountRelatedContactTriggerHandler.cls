public class ClsAccountRelatedContactTriggerHandler
{	
/****************************************************************
@Description    : Handler class for AccountContactRelation logic
*****************************************************************/
    //Static variable
    public static boolean executeRelatedContactTrigger = true;
    //Method creates a new entry for Prescriber to Med Fac combination in the Related Accounts object
    public static void processPrimaryContact(Map<Id, AccountContactRelation> newTriggerRelatedContact, Map<Id, AccountContactRelation> oldTriggerRelatedContact)
    {
        if(executeRelatedContactTrigger)
        {
            system.debug('*******RELACC - Entered processPrimaryContact Method');
            executeRelatedContactTrigger = false;
            Map<Id, Id> accountToContactMap = new Map<Id, Id>();//Map holds the account to contact map
            Set<Id> relContactIdSet = new Set<Id>();//Set used to remove old Primary 
            //Process inserts
            if(oldTriggerRelatedContact == null)
            {
                system.debug('*******RELACC - Entered Insert Logic');
                for(AccountContactRelation relContact : newTriggerRelatedContact.values())
                {
                    if(relContact.Primary__c){
                        accountToContactMap.put(relContact.AccountId, relContact.ContactId);
                        system.debug('*******RELACC - Added the relation ' + relContact.AccountId + '-' + relContact.ContactId + ' to Process');
                    }
                }
            //Process updates
            }else{
                for(AccountContactRelation relContact : newTriggerRelatedContact.values())
                {
                    system.debug('*******RELACC - Entered Update Logic');
                    AccountContactRelation oldRelContact = oldTriggerRelatedContact.get(relContact.Id);
                    if(relContact.Primary__c != oldRelContact.Primary__c && relContact.Primary__c)
                    {
                        accountToContactMap.put(relContact.AccountId, relContact.ContactId);
                        system.debug('*******RELACC - Primary Changed - Added the relation ' + relContact.AccountId + '-' + relContact.ContactId + ' to Process');
                    }
                }
            }
            //Remove the old Primary Relations
            if(!accountToContactMap.isEmpty())
            {
                system.debug('*******RELACC - Remove existing old Primary relation');
                for(AccountContactRelation relContact : [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE Primary__c = true AND AccountId IN : accountToContactMap.keySet()])
                {
                    if(accountToContactMap.get(relContact.AccountId) != relContact.ContactId)
                    {
                        relContactIdSet.add(relContact.Id);
                        system.debug('*******RELACC - Added the Id ' +relContact.Id + ' to remove Primary');
                    }
                }
            }
            //Perform the DML Operation
            if(!accountToContactMap.isEmpty())
            {
                List<Account> accntList = new List<Account>();
                Map<Id, Contact> contactsMap = new Map<Id, Contact>([SELECT Id, FirstName, LastName FROM Contact WHERE Id IN : accountToContactMap.values()]);
                for(Id accntId : accountToContactMap.keySet())
                {
                    Account accnt = new Account (id = accntId);
                    Contact cont = contactsMap.get(accountToContactMap.get(accntId));
                    if(cont != null) 
                    {
                        accnt.Contact_Details__c = cont.Firstname + ' ' + cont.LastName;
                        accnt.Contact__c = accountToContactMap.get(accntId);
                        accntList.add(accnt);
                    }
                }
                if(!accntList.isEmpty()){
                    update accntList;
                    system.debug('*******RELACC - Update Account Contact__c and Contact_Details__c');
                }
            }
            if(!relContactIdSet.isEmpty())
            {
                List<Id> relContactIds = new List<Id>(relContactIdSet);
                List<AccountContactRelation> updateRelContactList = new List<AccountContactRelation>();
                for(Id relContactId : relContactIds )
                {
                    AccountContactRelation relContact = new AccountContactRelation (Id = relContactId);
                    relContact.Primary__c = false;
                    updateRelContactList.add(relContact);
                }
                if(!updateRelContactList.isEmpty())
                {
                    update updateRelContactList;
                    system.debug('*******RELACC - Update Primary__c = False for old primary relation');
                }
            }
        }
    }
}