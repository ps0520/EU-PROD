/****************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 5/01/2017
@Description    : Class used in to process Prescriber to Medical Facility relationship
****************************************************************************************************************/
public class ClsAccountRelatedAccountTriggerHandler
{
    static Map<ID,Schema.RecordTypeInfo> recordTypesMap = ClsApexUtil.getRecordTypeId('Account');
	static List<Account> accountsToProcess = new List<Account>();
	
	//Method creates a new entry for Prescriber to Med Fac combination in the Related Accounts object
    public static void ProcessAccountRelatedAccountOnAccountInsert(List<Account> accounts)
    {
		accountsToProcess.clear();
		//Loop through all accounts and to see if Medical Facility information is populated on newly created accounts
        for(Account accnt : accounts)
        {
            //if(recordTypesMap.get(accnt.recordTypeID).getName().containsIgnoreCase('Prescriber') && accnt.Medical_Facility__c != null && accnt.Medical_Facility__c != '')
            if(recordTypesMap.get(accnt.recordTypeID).getName().containsIgnoreCase('Prescriber') && !String.isBlank(accnt.Medical_Facility__c) && accnt.IQVIA_OneKeyId__c == null)
            {
                accountsToProcess.add(accnt);
            }
        }
		
		if(!accountsToProcess.isEmpty())
		{
			system.debug('----Entered process to create new Related Account records');
			CreateRelatedAccounts(accountsToProcess);
		}
    }
	// The following method is defunct.
    public static void processSystemOfOriginOnAccountCreate(List<Account> accounts) {
        List<Account> updAccounts = new List<Account>();
        for(Account accnt : accounts) {
            
            if (String.isBlanK(accnt.System_Of_Origin__c) || ( accnt.Record_Type_Name__c == 'CH Consumer' && (accnt.PersonEmail == '' || accnt.PersonEmail == null) ) ) 
            {  
              Account Acc = New Account();
              Acc.id =accnt.Id; 
              if (String.isBlanK(accnt.System_Of_Origin__c)){
                  Acc.System_Of_Origin__c = 'crm';
                  Acc.System_Of_Origin_Id__c = accnt.Id ;
                }
              if( accnt.Record_Type_Name__c == 'CH Consumer' && (accnt.PersonEmail == '' || accnt.PersonEmail == null) ){                           
                  String madeUpEmail = accnt.FirstName+'.'+ accnt.LastName+ '.invalid@dexcom.com'; 
                  //Remove any blank space to avoid inavlid email format
                  madeUpEmail = madeUpEmail.replaceAll( '\\s+', '');
                  madeUpEmail = ClsRemoveAccents.removeDiacritics(madeUpEmail);
                  Acc.PersonEmail = madeUpEmail;
                }
                updAccounts.add(Acc);
               // updAccounts.add(New Account(id=accnt.Id, System_Of_Origin__c = 'crm', System_Of_Origin_Id__c = accnt.Id));
           }
        }
        if (updAccounts.size() > 0) {
            //try {
                update updAccounts;
            //} catch (DmlException de) {
              //  system.debug('Error in updating the System of Origin related data during Account Creation. Error: ' + de.getMessage());
            // }
        }
    }
    
    // Do this in BeforeInsert to avoid update firing again
    public static void processSoSOnAccountCreate(List<Account> accounts) {
        // List<Account> updAccounts = new List<Account>();
        for(Account accnt : accounts) {
            if (String.isBlanK(accnt.System_Of_Origin__c)){
                accnt.System_Of_Origin__c = 'crm';
                // accnt.System_Of_Origin_Id__c = accnt.Id ;     ----- In Before Insert, Account Id is unknown so no point in setting it. This is not an issue as Event publsher defaults it.
            }
            if( accnt.Record_Type_Name__c == 'CH Consumer' && (accnt.PersonEmail == '' || accnt.PersonEmail == null) ){                           
                String madeUpEmail = accnt.FirstName+'.'+ accnt.LastName+ '.invalid@dexcom.com'; 
                //Remove any blank space to avoid inavlid email format
                madeUpEmail = madeUpEmail.replaceAll( '\\s+', '');
                madeupEmail = ClsRemoveAccents.removeDiacritics(madeupEmail);
                accnt.PersonEmail = madeUpEmail;
            }
            if (accnt.Record_Type_Name__c == 'CA Prescriber' && (accnt.PersonEmail == '' || accnt.PersonEmail == null)) {
                String madeUpEmail = accnt.FirstName+'.'+ accnt.LastName+ '.CA_Prescriber.invalid@dexcom.com'; 
                //Remove any blank space to avoid inavlid email format
                madeUpEmail = madeUpEmail.replaceAll( '\\s+', '');
                madeupEmail = ClsRemoveAccents.removeDiacritics(madeupEmail);
                accnt.PersonEmail = madeUpEmail;
            }
        }
    }
	//Method creates or updates an entry for Prescriber to Med Fac combination in the Related Accounts object
    public static void ProcessAccountRelatedAccountOnAccountUpdate(Map<Id, Account> newTriggerAccount, Map<Id, Account> oldTriggerAccount)
    {
        accountsToProcess.clear();
		Set<Id> prescriberIds = new Set<Id> ();
		//Check if any Med Fac is changed for any of the prescriber account
        for(Account newAccnt : newTriggerAccount.values())
        {
            if (recordTypesMap.get(newAccnt.recordTypeID).getName().containsIgnoreCase('Prescriber') || newAccnt.IQVIA_OneKeyId__c == null)
			{
				Account oldAccnt = oldTriggerAccount.get(newAccnt.Id);
				//Check if the Med Fac information is updated
				system.debug('oldAccnt Medical Facility ' + oldAccnt.Medical_Facility__c);
                system.debug('newAccnt Medical Facility ' + newAccnt.Medical_Facility__c);
                
				//if((oldAccnt.Medical_Facility__c != newAccnt.Medical_Facility__c) && newAccnt.Medical_Facility__c != null && newAccnt.Medical_Facility__c != '')
				if(newAccnt.Medical_Facility__c != null && (oldAccnt.Medical_Facility__c != newAccnt.Medical_Facility__c))
				{
					system.debug('----There was a change made for Med Fac field on Prescriber');
					accountsToProcess.add(newAccnt);
					prescriberIds.add(newAccnt.Id);
				}
			}
		}

		if(!accountsToProcess.isEmpty())
		{
			ProcessRelatedAccounts(accountsToProcess, prescriberIds);
		}			
    }
	
	//Method will check if Related Account record already exist for Prescriber to Med Fac combination
	public static void ProcessRelatedAccounts(List<Account> accounts, Set<Id> prescriberIds)
	{
		Map<Id, List<Related_Account__c>> accntToRelAccntMap = new Map<Id, List<Related_Account__c>>();
		List<Related_Account__c> relAccountsToBeUpdated = new List<Related_Account__c>();
		List<Account> relAccountsToBeCreatedForAccounts = new List<Account>();
		
		//Create a map between prescriber (child account) and medical facility (parent account) from junction object Related Account
		for(Related_Account__c relAccnt : [SELECT Parent_Account__c, Child_Account__c, Primary_Flag__c FROM Related_Account__c WHERE Child_Account__c IN : prescriberIds])
		{
			if(accntToRelAccntMap.containsKey(relAccnt.Child_Account__c))
			{
				List<Related_Account__c> relAccntList = accntToRelAccntMap.get(relAccnt.Child_Account__c);
				relAccntList.add(relAccnt);
				accntToRelAccntMap.put(relAccnt.Child_Account__c, relAccntList);
			}
			else
			{
				accntToRelAccntMap.put(relAccnt.Child_Account__c, new List<Related_Account__c> {relAccnt});
			}
		}
		//Remove all primaries and check if Prescriber to Med Fac combination already exist
		for(Account accntToProcess : accounts)
		{
			Boolean prescriberToMedFacExist = false; //Flag to check if prescriber to medical facility combination already exist in Related Accounts
			if(accntToRelAccntMap != null)
			{
				if(!accntToRelAccntMap.isEmpty())
				{
					List<Related_Account__c> relAccntListToBeProcessed = accntToRelAccntMap.get(accntToProcess.Id);//Get all Related Accounts for a given account
					if(!relAccntListToBeProcessed.isEmpty())
					{
						for(Related_Account__c relAccnt : relAccntListToBeProcessed)
						{
							//Check if prescriber to medical facility combination and if so mark it as primary
							if(relAccnt.Parent_Account__c == accntToProcess.Medical_Facility__c)
							{
								system.debug('----Prescriber to Medical Facility combination exist ' + relAccnt.Id);
								relAccnt.Primary_Flag__c = true;
								prescriberToMedFacExist = true;
								relAccountsToBeUpdated.add(relAccnt);
								
							}
							else if(relAccnt.Primary_Flag__c)
							{
								system.debug('----Resetting existing Primary ' + relAccnt.Id);
								relAccnt.Primary_Flag__c = false;
								relAccountsToBeUpdated.add(relAccnt);
							}	
						}		
					}
				}
			}
			if(!prescriberToMedFacExist)
				relAccountsToBeCreatedForAccounts.add(accntToProcess);
		}
		//Update Related Accounts
        if(!relAccountsToBeUpdated.isEmpty())
        {
            system.debug('-----Update list entered for Related Accounts');
            ClsAccountAddressTriggerStaticClass.medFacChangedInvokedFromRelatedAccount = false;
            try{update relAccountsToBeUpdated;}
            catch (DmlException de) {
                Integer numErrors = de.getNumDml();
                System.debug('getNumDml=' + numErrors);
                for(Integer i=0;i<numErrors;i++) {
                    System.debug('getDmlFieldNames=' + de.getDmlFieldNames(i));
                    System.debug('getDmlMessage=' + de.getDmlMessage(i));
                }
            }
        }
		
		//Create Related Accounts
		if(!relAccountsToBeCreatedForAccounts.isEmpty())
        {
			system.debug('----Entered process to create new Related Account records');
			CreateRelatedAccounts(relAccountsToBeCreatedForAccounts);
		}
	}
	

	//Method called to create Related Account record for a Prescriber to Med Fac combination
	public static void CreateRelatedAccounts (List<Account> accounts)
	{
		List<Related_Account__c> relatedAccountsToBeInserted = new List<Related_Account__c>();
		for(Account accnt : accounts)
		{
			Related_Account__c relAccount = new Related_Account__c(Parent_Account__c = accnt.Medical_Facility__c, Child_Account__c = accnt.Id, Primary_Flag__c = true);
			relatedAccountsToBeInserted.add(relAccount);
		}
		//Insert Related Account Records
        if(!relatedAccountsToBeInserted.isEmpty())
        {
            system.debug('-----Insert list entered for Related Accounts');
            ClsAccountAddressTriggerStaticClass.medFacChangedInvokedFromRelatedAccount = false;
            try{insert relatedAccountsToBeInserted;}
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
    //Method to handle the publishing of Events. 
    public static void handlePublish(List<Account> acs, String action, Map<Id, Account> oldAcs) {
        Set<Id> pubActs = new Set<Id>();
        Set<Id> addActs = new Set<Id>();
        //Set<Id> allowedRecTypes = new Set<Id>();
        //List<RecordType> rs = [SELECT Id FROM RecordType where SobjectType= 'Account' AND isactive = true and (developername like 'CA%' or developerName like 'DE%') ];
        //for (RecordType r : rs) allowedRecTypes.add(r.Id);
        
        for (Account a : acs) {
            //if (allowedRecTypes.contains(a.RecordTypeId)) {
            if (action == 'create') {
                if(a.IQVIA_OneKeyId__c != null) PEClsHandleAccountEventsStatic.accountPublish = true;//Force the publish for IQVIA Accounts
                pubActs.add(a.Id);
            }
                else if (action == 'update') {
                    if (a.PersonBirthdate != oldAcs.get(a.Id).PersonBirthdate) {pubActs.add(a.id); continue;}
                    if (a.Name != oldAcs.get(a.Id).Name) {pubActs.add(a.id); continue;}
                    if (a.Organzation_Email__c != oldAcs.get(a.Id).Organzation_Email__c) {pubActs.add(a.id); continue;}
                    //if (a.BillingCountryCode != oldAcs.get(a.Id).BillingCountryCode) {pubActs.add(a.id); continue;}
                    //if (a.BillingCountry != oldAcs.get(a.Id).BillingCountry) {pubActs.add(a.id); continue;}
                    if (a.Fax != oldAcs.get(a.Id).Fax) {pubActs.add(a.id); continue;}
                    if (a.FirstName != oldAcs.get(a.Id).FirstName) {pubActs.add(a.id); continue;}
                    if (a.Gender__c != oldAcs.get(a.Id).Gender__c) {pubActs.add(a.id); continue;}
                    if (a.Inactive__c != oldAcs.get(a.Id).Inactive__c) {pubActs.add(a.id); continue;}
                    if (a.LastName != oldAcs.get(a.Id).LastName) {pubActs.add(a.id); continue;}
                    if (a.MiddleName != oldAcs.get(a.Id).MiddleName) {pubActs.add(a.id); continue;}
                    if (a.PersonMobilePhone != oldAcs.get(a.Id).PersonMobilePhone) {pubActs.add(a.id); continue;}
                    if (a.Phone != oldAcs.get(a.Id).Phone) {pubActs.add(a.id); continue;}
                    if (a.PersonOtherPhone != oldAcs.get(a.Id).PersonOtherPhone) {pubActs.add(a.id); continue;}
                    if (a.PersonHomePhone != oldAcs.get(a.Id).PersonHomePhone) {pubActs.add(a.id); continue;}
                    if (a.PersonEmail != oldAcs.get(a.Id).PersonEmail) {pubActs.add(a.id); continue;}
                    if (a.Prescriber_Id__c != oldAcs.get(a.Id).Prescriber_Id__c) {pubActs.add(a.id); continue;}
                    if (a.Preferred_Language__c != oldAcs.get(a.Id).Preferred_Language__c) {pubActs.add(a.id); continue;}
                    if (a.Email_Opt_In_List__c != oldAcs.get(a.Id).Email_Opt_In_List__c) {pubActs.add(a.id); continue;}
                    if (a.Phone_Opt_In_List__c != oldAcs.get(a.Id).Phone_Opt_In_List__c) {pubActs.add(a.id); continue;}
                    if (a.SMS_Opt_In_List__c != oldAcs.get(a.Id).SMS_Opt_In_List__c) {pubActs.add(a.id); continue;}
                    if (a.Mail_Opt_In_List__c != oldAcs.get(a.Id).Mail_Opt_In_List__c) {pubActs.add(a.id); continue;}
                    if (a.Payor__c != oldAcs.get(a.Id).Payor__c) {pubActs.add(a.id); continue;}
                    if (a.SFCC_Login_Enabled__c != oldAcs.get(a.Id).SFCC_Login_Enabled__c) {pubActs.add(a.id); continue;}
                    if (a.Parent_Guardian_First_Name__c != oldAcs.get(a.Id).Parent_Guardian_First_Name__c) {pubActs.add(a.id); continue;}
                    if (a.Parent_Guardian_Last_Name__c != oldAcs.get(a.Id).Parent_Guardian_Last_Name__c) {pubActs.add(a.id); continue;}
                    if (a.Dexcom_ID__c != oldAcs.get(a.Id).Dexcom_ID__c) {pubActs.add(a.id); continue;}
                    if (a.Pump_Manufacturer__c != oldAcs.get(a.Id).Pump_Manufacturer__c) {pubActs.add(a.id); continue;}
                    if (a.Nickname__c != oldAcs.get(a.Id).Nickname__c) {pubActs.add(a.id); continue;}
                    if (a.G6_Instructions_Shipped__c != oldAcs.get(a.Id).G6_Instructions_Shipped__c) {pubActs.add(a.id); continue;}
                    if (a.G6_Starter_Kit_Ship_Date__c != oldAcs.get(a.Id).G6_Starter_Kit_Ship_Date__c) {pubActs.add(a.id); continue;}
                    if (a.Number_of_Active_SSIP_Rules__c  != oldAcs.get(a.Id).Number_of_Active_SSIP_Rules__c ) {pubActs.add(a.id); continue;}
                    if (a.Subscription_Pending_Payments__c != oldAcs.get(a.Id).Subscription_Pending_Payments__c) {pubActs.add(a.id); continue;}
                    if (a.Send_To_Oracle__c != oldAcs.get(a.Id).Send_To_Oracle__c && a.Send_To_Oracle__c == true) {pubActs.add(a.id); continue;} //Per Jagan's request on Sept 3, 2019.
                    //if (a.Tax_Registration_Number__c != oldAcs.get(a.Id).Tax_Registration_Number__c) {addActs.add(a.id); continue;} //publish all addresses belonging to the account whose Tax Registration number has changed
                    //if (a.Tax_Exempt__c != oldAcs.get(a.Id).Tax_Exempt__c) {/*2.0 Canonical needs publishing of Account too*/ pubActs.add(a.id); /* addActs.add(a.id); */ continue;} //publish all addresses belonging to the account whose Tax Registration number has changed
                    if (a.Credit_Hold__c != oldAcs.get(a.Id).Credit_Hold__c) {pubActs.add(a.id); continue;}
                    if (a.CA_First_Nation_ID__c != oldAcs.get(a.Id).CA_First_Nation_ID__c) {pubActs.add(a.id); continue;}
                    if (a.CA_GST_HST_Registration_Number__c != oldAcs.get(a.Id).CA_GST_HST_Registration_Number__c) {pubActs.add(a.id); continue;}
                    if (a.CA_BC_State_PST_Registration_Number__c != oldAcs.get(a.Id).CA_BC_State_PST_Registration_Number__c) {pubActs.add(a.id); continue;}
                    if (a.CA_MB_State_PST_Registration_Number__c != oldAcs.get(a.Id).CA_MB_State_PST_Registration_Number__c) {pubActs.add(a.id); continue;}
                    if (a.CA_QC_State_PST_Registration_Number__c != oldAcs.get(a.Id).CA_QC_State_PST_Registration_Number__c) {pubActs.add(a.id); continue;}
                    if (a.CA_SK_State_PST_Registration_Number__c != oldAcs.get(a.Id).CA_SK_State_PST_Registration_Number__c) {pubActs.add(a.id); continue;}
                    if (a.Sub_Type__c != oldAcs.get(a.Id).Sub_Type__c) {pubActs.add(a.id); continue;}
                }
            //}
        }
        if (pubActs.size() > 0) PEClsHandleAccountEvents.publishAccountEvents(pubActs, action);
        /*
        if (addActs.size() > 0) {
            List<Address__c> addressList = [Select Id from Address__c where Account__c in :addActs AND Inactive__c = false];
            if (addressList.size() > 0) {
                Set<Id> addsToBePublished = new set<Id>();
                for(Address__c add : addressList) addsToBePublished.add(add.Id);
                PEClsHandleAddressEvents.publishAddresses(addsToBePublished, 'update');
            }
        }*/
    }
}