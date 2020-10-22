public class ClsAccountChangeEventTriggerHandler
{
    //Method will make the chosen Contact on the account as Primary on the AccountContactRelation object
    public static void processRelatedContact(Set<String> accountIdsForRelContactUpdates)
    {
        system.debug('*******ACCCHGEVT - Entered the method processRelatedContact');
        Map<Id, Id> accountIdToContactIdMap = new Map<Id, Id>();//Holds list of account to contact to process
        List<AccountContactRelation> createRelatedContactList = new List<AccountContactRelation>();//List used to create the related contacts
        List<AccountContactRelation> updateRelatedContactList = new List<AccountContactRelation>();//List used to update the related contacts        
        //Prepare the account contact map that need to be worked on
        for(Account acc : [SELECT Id, Contact__c FROM Account WHERE Id IN : accountIdsForRelContactUpdates])
            accountIdToContactIdMap.put(acc.Id, acc.Contact__c);
        if(!accountIdToContactIdMap.isEmpty())
        {
            system.debug('*******ACCCHGEVT - accountIdToContactIdMap found  ' + accountIdToContactIdMap);
            Map<String, String> existingAccIdToContactIdMap = new Map<String, String>();//Map stores the account id to contact id combination
            //Get all existing Account Contact Relations that exist already  
            for(AccountContactRelation relContact : [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE AccountId IN : accountIdToContactIdMap.keySet()])
            {
                String accToConId = relContact.AccountId + '-' + relContact.ContactId;
                existingAccIdToContactIdMap.put(accToConId, relContact.Id);
                system.debug('*******ACCCHGEVT - existingAccIdToContactIdMap found  ' + existingAccIdToContactIdMap);
            }
            for(Id accId : accountIdToContactIdMap.keySet())
            {
                String accToConId = accId + '-' + accountIdToContactIdMap.get(accId);
                system.debug('*******ACCCHGEVT - Processing Account Contact Id ' + accToConId);
                //Find if there is existing relation and if so, make it as Primary else create a new record
                if(existingAccIdToContactIdMap != null && existingAccIdToContactIdMap.containsKey(accToConId))
                {
                    system.debug('*******ACCCHGEVT - Found existing relation ' + existingAccIdToContactIdMap.containsKey(accToConId));
                    AccountContactRelation relContact = new AccountContactRelation (Id = existingAccIdToContactIdMap.get(accToConId));
                    relContact.Primary__c = true;
                    updateRelatedContactList.add(relContact);
                }else{
                    system.debug('*******ACCCHGEVT - New relation added');
                    AccountContactRelation relContact = new AccountContactRelation ();
                    relContact.AccountId = accId;
                    relContact.ContactId = accountIdToContactIdMap.get(accId);
                    relContact.Primary__c = true;
                    createRelatedContactList.add(relContact);
                }
            }
        }
        if(!updateRelatedContactList.isEmpty())
        {
            update updateRelatedContactList;
            system.debug('*******ACCCHGEVT - Update Relation');
        }
        if(!createRelatedContactList.isEmpty())
        {
            insert createRelatedContactList;
            system.debug('*******ACCCHGEVT - Insert Relation');
        }
    }

    //Method will make the chosen Fund on the account as Primary on the AccountFund object
    public static void processAccountFund(Set<String> accountsToProcessForFundChanges)
    {
        system.debug('*******ACCCHGEVT - Entered the method processAccountFund');
        Map<Id, Id> accountIdToFundIdMap = new Map<Id, Id>();//Holds list of account to fund to process
        List<Account_Fund__c> createAccountFundList = new List<Account_Fund__c>();//List used to create the account funds
        List<Account_Fund__c> updateAccountFundList = new List<Account_Fund__c>();//List used to update the account funds       
        //Prepare the account fund map that need to be worked on
        for(Account acc : [SELECT Id, Fund__c FROM Account WHERE Id IN : accountsToProcessForFundChanges])
            accountIdToFundIdMap.put(acc.Id, acc.Fund__c);
        if(!accountIdToFundIdMap.isEmpty())
        {
            system.debug('*******ACCCHGEVT - accountIdToFundIdMap found  ' + accountIdToFundIdMap);
            Map<String, String> existingAccIdToFundIdMap = new Map<String, String>();//Map stores the account id to fund id combination
            //Get all existing Account Funds that exist already  
            for(Account_Fund__c accntFund : [SELECT Id, Account_18_Digit_Id__c, Fund_18_Digit_Id__c FROM Account_Fund__c WHERE Account_18_Digit_Id__c IN : accountIdToFundIdMap.keySet()])
            {
                String accToFundId = accntFund.Account_18_Digit_Id__c + '-' + accntFund.Fund_18_Digit_Id__c;
                existingAccIdToFundIdMap.put(accToFundId, accntFund.Id);
                system.debug('*******ACCCHGEVT - existingAccIdToFundMap found  ' + existingAccIdToFundIdMap);
            }
            for(Id accId : accountIdToFundIdMap.keySet())
            {
                String accToFundId = accId + '-' + accountIdToFundIdMap.get(accId);
                system.debug('*******ACCCHGEVT - Processing Account Fund Id ' + accToFundId);
                //Find if there is existing relation and if so, make it as Primary else create a new record
                if(existingAccIdToFundIdMap != null && existingAccIdToFundIdMap.containsKey(accToFundId))
                {
                    system.debug('*******ACCCHGEVT - Found existing account fund record ' + existingAccIdToFundIdMap.containsKey(accToFundId));
                    Account_Fund__c accntFund = new Account_Fund__c (Id = existingAccIdToFundIdMap.get(accToFundId));
                    accntFund.Primary_Flag__c = true;
                    updateAccountFundList.add(accntFund);
                }else{
                    system.debug('*******ACCCHGEVT - New account fund added');
                    Account_Fund__c accntFund = new Account_Fund__c ();
                    accntFund.Account__c = accId;
                    accntFund.Fund__c = accountIdToFundIdMap.get(accId);
                    accntFund.Primary_Flag__c = true;
                    createAccountFundList.add(accntFund);
                }
            }
        }
        if(!updateAccountFundList.isEmpty())
        {
            update updateAccountFundList;
            system.debug('*******ACCCHGEVT - Update Account Fund');
        }
        if(!createAccountFundList.isEmpty())
        {
            insert createAccountFundList;
            system.debug('*******ACCCHGEVT - Insert Account Fund');
        }
    }
}