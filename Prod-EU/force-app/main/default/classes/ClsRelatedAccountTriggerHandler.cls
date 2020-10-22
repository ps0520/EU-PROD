/*******************************************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 5/01/2017
@Description    : Class used in to process all Related Account logic to set the correct primary Prescriber to Medical Facility relationship
********************************************************************************************************************************************/
public class ClsRelatedAccountTriggerHandler
{
    //Method unsets the primary flag for other Related Account records sets the Primary for the inserted record
    public static void processRelatedAccounts(List<Related_Account__c> relAccnts, Map<Id, Related_Account__c> newTriggerRelatedAccounts, Map<Id, Related_Account__c> oldTriggerRelatedAccounts)
    {
        
		List<Id> prescriberAccountIdsToProcess = new List<Id>();//List of Accounts to be processed for Med Fac to Prescriber association
		List<Related_Account__c> prescriberRelatedAccountsToProcess = new List<Related_Account__c>();//List of Related Accounts to be processed for Med Fac to Prescriber association

		List<Id> medFacParentPayorAccountIdsToProcess = new List<Id>();//List of Accounts to be processed for Payor to Med Fac association 
		List<Related_Account__c> medFacParentPayorRelatedAccountsToProcess = new List<Related_Account__c>();//List of Related Accounts to be processed for Payor to Med Fac association
		
		List<Id> medFacParentMedFacAccountIdsToProcess = new List<Id>();//List of Accounts to be processed for Med Fac to Med Fac association 
		List<Related_Account__c> medFacParentMedFacRelatedAccountsToProcess = new List<Related_Account__c>();//List of Related Accounts to be processed for Med Fac to Med Fac association
		
		List<Id> pharmParentPharmAccountIdsToProcess = new List<Id>();//List of Accounts to be processed for Pharmacy to Pharmacy association 
		List<Related_Account__c> pharmParentPharmRelatedAccountsToProcess = new List<Related_Account__c>();//List of Related Accounts to be processed for Pharmacy to Pharmacy association
		
		List<Related_Account__c> processNonPrimaryList = new List<Related_Account__c>();//List will hold the accounts, which have the Primary flag removed

		//Find the related accounts, which have the primary flag set
        for(Related_Account__c relAccnt : relAccnts)
        {
			if((newTriggerRelatedAccounts == null && relAccnt.Primary_Flag__c) || 
				(newTriggerRelatedAccounts != null && 
					(((oldTriggerRelatedAccounts.get(relAccnt.Id).Primary_Flag__c != relAccnt.Primary_Flag__c) && relAccnt.Primary_Flag__c) || 
					(oldTriggerRelatedAccounts.get(relAccnt.Id).Payor_Billing_Address__c != relAccnt.Payor_Billing_Address__c))))
			{
				if(relAccnt.Parent_Relation_Type__c == 'Medical Facility' && relAccnt.Child_Relation_Type__c == 'Prescriber')
				{
					prescriberAccountIdsToProcess.add(relAccnt.Child_Account__c);
					prescriberRelatedAccountsToProcess.add(relAccnt);
				}
				if(relAccnt.Parent_Relation_Type__c == 'Payor' && relAccnt.Child_Relation_Type__c == 'Medical Facility')
				{
					medFacParentPayorAccountIdsToProcess.add(relAccnt.Child_Account__c);
					medFacParentPayorRelatedAccountsToProcess.add(relAccnt);
				}
				if(relAccnt.Parent_Relation_Type__c == 'Medical Facility' && relAccnt.Child_Relation_Type__c == 'Medical Facility')
				{
					medFacParentMedFacAccountIdsToProcess.add(relAccnt.Child_Account__c);
					medFacParentMedFacRelatedAccountsToProcess.add(relAccnt);
				}
				if(relAccnt.Parent_Relation_Type__c == 'Pharmacy' && relAccnt.Child_Relation_Type__c == 'Pharmacy')
				{
					pharmParentPharmAccountIdsToProcess.add(relAccnt.Child_Account__c);
					pharmParentPharmRelatedAccountsToProcess.add(relAccnt);
				}
            }
			else //Process when the Primary flag is removed
			if(newTriggerRelatedAccounts != null && ((oldTriggerRelatedAccounts.get(relAccnt.Id).Primary_Flag__c != relAccnt.Primary_Flag__c) && !relAccnt.Primary_Flag__c))
				processNonPrimaryList.add(relAccnt);

        }
        if(!prescriberRelatedAccountsToProcess.isEmpty()) processPrimaryRelatedAccounts(prescriberAccountIdsToProcess, prescriberRelatedAccountsToProcess, 'Medical Facility', 'Prescriber');
		if(!medFacParentPayorRelatedAccountsToProcess.isEmpty()) processPrimaryRelatedAccounts(medFacParentPayorAccountIdsToProcess, medFacParentPayorRelatedAccountsToProcess, 'Payor', 'Medical Facility');
		if(!medFacParentMedFacRelatedAccountsToProcess.isEmpty()) processPrimaryRelatedAccounts(medFacParentMedFacAccountIdsToProcess, medFacParentMedFacRelatedAccountsToProcess, 'Medical Facility', 'Medical Facility');
		if(!pharmParentPharmRelatedAccountsToProcess.isEmpty()) processPrimaryRelatedAccounts(pharmParentPharmAccountIdsToProcess, pharmParentPharmRelatedAccountsToProcess, 'Pharmacy', 'Pharmacy');
		if(!processNonPrimaryList.isEmpty()) processNonPrimaryAddress(processNonPrimaryList);
    }

	//Method, which will process the Related Account records for primary flag reset for Med Fac to Prescriber association
    public static void processPrimaryRelatedAccounts(List<Id> accountIdsToProcess, List<Related_Account__c> relatedAccountsToProcess, String parentRelationType, String childRelationType)
    {
        Map<Id, List<Related_Account__c>> accntIdRelatedAccountsMap = new Map<Id, List<Related_Account__c>>();//Map holds the List of related accounts tied to an account 
        List<Related_Account__c> removePrimaryRelatedAccountsList = new List<Related_Account__c>();//List holds the Related Account records to be updated to remove the primary flag
		List<Account> accountsToProcess = new List<Account>();//List of Account where the account information needs to be updated
        if(!relatedAccountsToProcess.isEmpty())
        {
            //Get the List of primary Related Account records
			accntIdRelatedAccountsMap = ClsRelatedAccountTriggerHandlerHelper.GetPrimaryRelatedAccountsTiedToAccount(accountIdsToProcess, relatedAccountsToProcess, parentRelationType, childRelationType);
            system.debug('The size of accntIdRelatedAccountsMap is '+accntIdRelatedAccountsMap.values().size());
        }
        for(Related_Account__c relAccntToProcess : relatedAccountsToProcess)
        {
            system.debug('---Related Account processing ' + relAccntToProcess.Id);
			List<Related_Account__c> tempRelAccntList;
			tempRelAccntList = (!accntIdRelatedAccountsMap.isEmpty()) ? accntIdRelatedAccountsMap.get(relAccntToProcess.Child_Account__c) : null;
			
			Account accntToBeUpdated = new Account(Id = relAccntToProcess.Child_Account__c);
			if(parentRelationType == 'Medical Facility' && childRelationType == 'Prescriber')
				accntToBeUpdated.Medical_Facility__c = relAccntToProcess.Parent_Account__c;
			if(parentRelationType == 'Payor' && childRelationType == 'Medical Facility')
			{
				accntToBeUpdated.Payor__c = relAccntToProcess.Parent_Account__c;
				accntToBeUpdated.Payor_Billing_Address__c = relAccntToProcess.Payor_Billing_Address__c;
			}
			if((parentRelationType == 'Medical Facility' && childRelationType == 'Medical Facility') || (parentRelationType == 'Pharmacy' && childRelationType == 'Pharmacy'))
				accntToBeUpdated.ParentId = relAccntToProcess.Parent_Account__c;
			accountsToProcess.add(accntToBeUpdated);

			if(tempRelAccntList != null) //This is to avoid null pointer exception otherwise just checking isEmpty is ok
			{
				if(!tempRelAccntList.isEmpty())
					removePrimaryRelatedAccountsList.addall(tempRelAccntList);
			}    
			system.debug('----Number of primary address to be inactivated ' + removePrimaryRelatedAccountsList.size());
        }
        //Update Related Account Records to reset the primary flag
        if(!removePrimaryRelatedAccountsList.isEmpty())
        {
            system.debug('-----Update list entered for Related Accounts');
            try{update removePrimaryRelatedAccountsList;}
            catch (DmlException de) {
                Integer numErrors = de.getNumDml();
                System.debug('getNumDml=' + numErrors);
                for(Integer i=0;i<numErrors;i++) {
                    System.debug('getDmlFieldNames=' + de.getDmlFieldNames(i));
                    System.debug('getDmlMessage=' + de.getDmlMessage(i));
                }
            }
        }
        
        //Update Prescriber account Records to set the Medical Facility
        if(!accountsToProcess.isEmpty())
        {
            system.debug('-----Update list entered for Accounts');
            ClsAccountAddressTriggerStaticClass.medFacChangedInvokedFromPrescriber = false;
            try{update accountsToProcess;}
            catch (DmlException de) {
                Integer numErrors = de.getNumDml();
                System.debug('getNumDml=' + numErrors);
                for(Integer i=0;i<numErrors;i++) {
                    System.debug('getDmlFieldNames=' + de.getDmlFieldNames(i));
                    System.debug('getDmlMessage=' + de.getDmlMessage(i));
                }
            }
        }
		
	}
    //Method will unset the Primary on the account
	public static void processNonPrimaryAddress(List<Related_Account__c> relatedAccountsToProcess)
    {
		List<Account> accountsToProcess = new List<Account>();//List of Account where the account information needs to be updated
		for(Related_Account__c relAccntToProcess : relatedAccountsToProcess){
			Account accntToBeUpdated = new Account(Id = relAccntToProcess.Child_Account__c);
			accntToBeUpdated.Payor__c = null;
			accntToBeUpdated.Payor_Billing_Address__c = null;
			accntToBeUpdated.ParentId = null;
			accountsToProcess.add(accntToBeUpdated);
		}
		//Update Prescriber account Records to set the Medical Facility
        if(!accountsToProcess.isEmpty())
        {
            system.debug('-----Update list entered for Accounts');
            ClsAccountAddressTriggerStaticClass.medFacChangedInvokedFromPrescriber = false;
            try{update accountsToProcess;}
            catch (DmlException de) {
                Integer numErrors = de.getNumDml();
                System.debug('getNumDml=' + numErrors);
                for(Integer i=0;i<numErrors;i++) {
                    System.debug('getDmlFieldNames=' + de.getDmlFieldNames(i));
                    System.debug('getDmlMessage=' + de.getDmlMessage(i));
                }
            }
        }
	}

    //Method to check if parent to child combination already exist
	public static void checkIfChildToParentRelationExists (List<Related_Account__c> relChildAccountIdsToProcess)
	{
		system.debug('---Process starts for Duplicate Check');
        //Prepare the set of Account Ids
        Set<Id> accountIds = new Set<Id>();
        //Set for duplicate check
        Set<String> parentToChildRelation = new Set<String>();
        //Get all the account Ids tied to the Related Accounts that are to be processed
        for(Related_Account__c relAccnt : relChildAccountIdsToProcess)
            accountIds.add(relAccnt.Child_Account__c);
 
		for(Related_Account__c relAccnt : [SELECT IQVIA_OneKeyId__c, Parent_Account__c, Child_Account__c, Parent_Account__r.Recordtype.Name, Child_Account__r.Recordtype.Name, Parent_Account__r.IQVIA_OneKeyId__c, Child_Account__r.IQVIA_OneKeyId__c FROM Related_Account__c WHERE Child_Account__c IN : accountIds])
 			parentToChildRelation.add(relAccnt.Child_Account__c+'-'+relAccnt.Parent_Account__c);
		for(Related_Account__c relAccnt : relChildAccountIdsToProcess)
		{
			system.debug('----Duplicate verification for ' + relAccnt.Child_Account__c+'-'+relAccnt.Parent_Account__c);
            if(relAccnt.IQVIA_OneKeyId__c == null){
                if(parentToChildRelation.contains(relAccnt.Child_Account__c+'-'+relAccnt.Parent_Account__c))
                {
                    system.debug('----Duplicate exist');
                    relAccnt.addError('Relation between this Parent and Child Accounts already exist');
                }
            }
		}
	}
}