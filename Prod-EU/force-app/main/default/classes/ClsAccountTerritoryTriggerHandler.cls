/**********************************************************
@Description    : Added logic for country specific zipcode 
**********************************************************/
public class ClsAccountTerritoryTriggerHandler {
    
    static Map<ID,Schema.RecordTypeInfo> recordTypesMap = ClsApexUtil.getRecordTypeId('Account');
    
    //Method invoked on Account insert
    public static void OnBeforeInsert(List<Account> accountsToProcess, String country){
        String batch;
        if(accountsToProcess.size()>0){
            ZiptoAlignUpdate(accountsToProcess,batch, country); //Finds the zip to align
            AccountTerritoryUpdate(accountsToProcess,batch, country); //Account territory fields are updated
            AccountOwnerUpdate(accountsToProcess, batch, country); //Account owner is updated based on the territory
        }
    }
    
    //Method invoked on Account before update
    public static void OnBeforeUpdate(List<Account> Accounts,Map <Id,Account> AccountsOldMap, String country){
        List<Account> accountList = New List<Account>();
        String batch;
        for(Account accnt: Accounts) {   
            Account OldAccount = AccountsOldMap.get(accnt.ID);
            if(accnt.ShippingPostalCode != OldAccount.ShippingPostalCode|| accnt.BillingPostalCode != OldAccount.BillingPostalCode||
               accnt.Medical_Facility__c != OldAccount.Medical_Facility__c || accnt.Prescriber__c != OldAccount.Prescriber__c){
                   accountList.add(accnt); 
               }
        }
        if(accountList.size()>0){
            ZiptoAlignUpdate(accountList,batch, country);
            AccountTerritoryUpdate(accountList,batch, country);
            AccountOwnerUpdate(accountList, batch, country);
        }
    }   
 
   
    public static void OnAfterUpdate(List<Account> Accounts,Map <Id,Account> AccountsOldMap , String country){
        List<Account> consumerTerritoryToBeUpdatedList = new List<Account>();
        Set<Id> medFacIdSet = new Set<Id>();
        Set<Id> prescriberIdSet = new Set<Id>();
        String batch = 'Update';
        for(Account accnt: Accounts) {   
            Account OldAccount = AccountsOldMap.get(accnt.ID);
            if((recordTypesMap.get(accnt.recordTypeID).getName().containsIgnoreCase('Facility') ||
            recordTypesMap.get(accnt.recordTypeID).getName().containsIgnoreCase('Prescriber')) && 
            accnt.ShippingPostalCode != OldAccount.ShippingPostalCode|| accnt.BillingPostalCode != OldAccount.BillingPostalCode){
                   //Add the Med Fac or Prescriber Id to set, so the consumers who are tied those accounts can be updated
                    if(recordTypesMap.get(accnt.recordTypeID).getName().containsIgnoreCase('Facility')){
                        medFacIdSet.add(accnt.Id);
                    }
                    else if (recordTypesMap.get(accnt.recordTypeID).getName().containsIgnoreCase('Prescriber')){
                        prescriberIdSet.add(accnt.Id);
                    }                       
               }
        }
        
        //Get all the consumers who are tied to the Medical Facility or Prescribers which had an address change
        if(medFacIdSet.size()>0 || prescriberIdSet.size()>0){
         //   Id deConsumerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('DE Consumer').getRecordTypeId();
         //   system.debug('Consumer recordtype id is ' + deConsumerRecordTypeId);         
          //  consumerTerritoryToBeUpdatedList = [SELECT Id, Firstname, Lastname, Country__c, RecordtypeID, Territory__c, District__c, Region__c, Medical_Facility__c, ShippingPostalCode, BillingPostalCode, Prescriber__c, Zip_To_Align__c FROM Account WHERE RecordTypeId = :deConsumerRecordTypeId AND (Medical_Facility__c IN : medFacIdSet OR Prescriber__c IN : prescriberIdSet)];

            consumerTerritoryToBeUpdatedList = [SELECT Id, Firstname, Lastname, Country__c, RecordtypeID, 
                                                Territory__c, District__c, Region__c, Medical_Facility__c, 
                                                ShippingPostalCode, BillingPostalCode, Prescriber__c, Zip_To_Align__c 
                                                FROM Account WHERE (Medical_Facility__c IN : medFacIdSet 
                                                     OR Prescriber__c IN : prescriberIdSet)];
            system.debug('Number of consumers to be updated is ' + consumerTerritoryToBeUpdatedList.size());
        }
        
        //Update all the consumers, which were triggered from the Medical Facility or Prescriber address changed
        if(consumerTerritoryToBeUpdatedList.size()>0){
            ZiptoAlignUpdate(consumerTerritoryToBeUpdatedList, batch, country);
            AccountTerritoryUpdate(consumerTerritoryToBeUpdatedList, batch, country);
            AccountOwnerUpdate(consumerTerritoryToBeUpdatedList, batch, country);
        }
        
    }   
    
    //This Method finds the zip to align the account    
    public static void ZiptoAlignUpdate(List<Account> accountsToProcess,String batch, String country){
        system.debug('-----Accounts to process - ' + accountsToProcess.size());
        Set<string> zipcodes = new Set<string>();
        Set<Id> accntIds = new Set<Id>();
        List<Account> accountList = new List<Account>();
        Map<ID,Schema.RecordTypeInfo> recordTypesMap = ClsApexUtil.GetRecordTypeId('Account');
        
        //Get the Medical Facilities and Prescribers tied to the account, which is under processing
        for(Account accnt: accountsToProcess) {   
            if((!String.isBlank(accnt.Medical_Facility__c) || !String.isBlank(accnt.Prescriber__c))){
                accntIds.add(accnt.Medical_Facility__c);
                accntIds.add(accnt.Prescriber__c);    
            }
        }
        
        Map<Id,Account> relatedAccounts = new Map<Id,Account>([SELECT Id, Name, Is_Admin_Account__c, ShippingPostalCode FROM Account WHERE Id IN :accntIds]);
        Integer Ziplength = 0 ;
		switch on country {
			when 'DE' {
				Ziplength = 5;
			}
			when 'CA' {
				Ziplength = 3;
			}
			when 'CH' {
				Ziplength = 4;
			}
			when 'AT' {
				Ziplength = 4;
			}
             when 'SI' {
				Ziplength = 4;
			}
		}

        system.debug('-country - ' + country);
        system.debug('-Ziplength - ' + Ziplength);
        for(Account accnt: accountsToProcess) {
			String zipToProcess ;
			zipToProcess =   accnt.ShippingPostalCode == null ? accnt.BillingPostalCode : accnt.ShippingPostalCode;
			if(country == 'CA'){
			zipToProcess =   accnt.BillingPostalCode == null ? accnt.ShippingPostalCode : accnt.BillingPostalCode;
			}
            //Do not proceed if Zip is null
			if(!String.isBlank(zipToProcess))
			{
				//For Non consumers get the shipping zip, if shipping zip is blank then get the billing zip
				if(recordTypesMap.get(accnt.recordTypeID).getName().containsIgnoreCase('Facility') 
				   || recordTypesMap.get(accnt.recordTypeID).getName().containsIgnoreCase('Payor')
				   || recordTypesMap.get(accnt.recordTypeID).getName().containsIgnoreCase('Hospital')
				   || recordTypesMap.get(accnt.recordTypeID).getName().containsIgnoreCase('Prescriber')
                   || recordTypesMap.get(accnt.recordTypeID).getName().containsIgnoreCase('Pharmacy'))
				   {
					   if(country == 'GB' || country == 'IE')
					   {
						   accnt.Zip_To_Align__c = zipToProcess.substringBefore(' ');
						   accountList.add(accnt);
					   }
					   else
					   if(zipToProcess.length() >= Ziplength && zipToProcess.substring(0,Ziplength) != null){  
						   accnt.Zip_To_Align__c = zipToProcess.substring(0,Ziplength);
						   accountList.add(accnt);
						 }
				   }
					system.debug('-----Zip for account id for processing  - ' + accnt.Id);   
					//For consumers first look at the Medical Facility's Zip, if it is blank then look at the Prescriber's zip.
					//If prescriber's zip is blank then take the zip from the consumer account
					if(recordTypesMap.get(accnt.recordTypeID).getName().containsIgnoreCase('Consumer')){ 
						Account relatedMedAccount = relatedAccounts.get(accnt.Medical_Facility__c);
						Account relatedPrescriberAccount = relatedAccounts.get(accnt.Prescriber__c);

						if(country == 'CH'){
							if(relatedPrescriberAccount != null && !relatedPrescriberAccount.Is_Admin_Account__c && String.isNotBlank(relatedPrescriberAccount.ShippingPostalCode)){
								accnt.Zip_To_Align__c = relatedPrescriberAccount.ShippingPostalCode.substring(0,Ziplength);
								accountList.add(accnt);
							}else 
							if(relatedMedAccount != null && !relatedMedAccount.Is_Admin_Account__c && String.isNotBlank(relatedMedAccount.ShippingPostalCode)){
								accnt.Zip_To_Align__c = relatedMedAccount.ShippingPostalCode.substring(0,Ziplength);
								accountList.add(accnt);                        
							}else if(zipToProcess.substring(0,Ziplength) != null){  
								accnt.Zip_To_Align__c = zipToProcess.substring(0,Ziplength);
								accountList.add(accnt);
							}
						}else
						if(country == 'GB' || country == 'IE'){
							if(relatedMedAccount != null && !relatedMedAccount.Is_Admin_Account__c && String.isNotBlank(relatedMedAccount.ShippingPostalCode)){
								accnt.Zip_To_Align__c = relatedMedAccount.ShippingPostalCode.substringBefore(' ');
								accountList.add(accnt);
							}else 
							if(relatedPrescriberAccount != null && !relatedPrescriberAccount.Is_Admin_Account__c && String.isNotBlank(relatedPrescriberAccount.ShippingPostalCode)){
								accnt.Zip_To_Align__c = relatedPrescriberAccount.ShippingPostalCode.substringBefore(' ');
								accountList.add(accnt);
							}else 
							if(zipToProcess != null){  
								accnt.Zip_To_Align__c = zipToProcess.substringBefore(' ');
								accountList.add(accnt);
							}	
						}
						else{                    
							if(relatedMedAccount != null && !relatedMedAccount.Is_Admin_Account__c && String.isNotBlank(relatedMedAccount.ShippingPostalCode)){
								accnt.Zip_To_Align__c = relatedMedAccount.ShippingPostalCode.substring(0,Ziplength);
								accountList.add(accnt);
							}else 
							if(relatedPrescriberAccount   != null && !relatedPrescriberAccount.Is_Admin_Account__c && String.isNotBlank(relatedPrescriberAccount.ShippingPostalCode)){
								accnt.Zip_To_Align__c = relatedPrescriberAccount.ShippingPostalCode.substring(0,Ziplength);
								accountList.add(accnt);
							}else 
							if(zipToProcess.substring(0,Ziplength) != null){  
								accnt.Zip_To_Align__c = zipToProcess.substring(0,Ziplength);
								accountList.add(accnt);
							}
						}
					system.debug('-----Zip for account id  - ' + accnt.Id + ' is ' + accnt.Zip_To_Align__c);    
					}
			}
            
        } 
        //Perform DML Operation
        try{
            if((accountList.size()>0) && batch != null){             
                update accountList;
            }
        }catch(DMLException ex){
            system.debug('***ERROR UPDATE*** ' + ex.getMessage());
        }
    }
    //This method will update the territory alignment field on the account (Territory, Region and District)
    public static void AccountTerritoryUpdate(List<Account> accountsToProcess,String batch, String country){
        set<string> zipcodes = new set<string>();  
        List<Account> accountList = new List<Account>(); 
        map<string,string> zipToTerMap = new map<string,string>();  
        map<string,string> zipToTerRegionMap = new map<string,string>();  
        map<string,string> zipToTerDistrictMap = new map<string,string>();  
        String countryName ; 
        Integer Ziplength = 0 ;
		switch on country {
			when 'DE' {
				Ziplength = 5;
				countryName = 'Germany';
			}
			when 'CA' {
				Ziplength = 3;
				countryName = 'Canada';
			}
			when 'CH' {
				Ziplength = 4;
				countryName = 'Switzerland';
			}
			when 'AT' {
				Ziplength = 4;
				countryName = 'Austria';
			}
			when 'GB' {
				countryName = 'United Kingdom';
			}
			when 'IE' {
				countryName = 'Ireland';
			}
            when 'SI' {
                Ziplength = 4;
				countryName = 'Slovenia';
			}
		}
        system.debug('-country - ' + country);
		
        system.debug('-Ziplength - ' + Ziplength);
         for (Account accnt: accountsToProcess) {
			 system.debug('-accnt.Zip_To_Align__c - ' + accnt.Zip_To_Align__c);
            if(!String.isBlank(accnt.Zip_To_Align__c)){
				if((country == 'GB' || country == 'IE' ) && accnt.Zip_To_Align__c != null)
				{
					zipcodes.add(accnt.Zip_To_Align__c.substringBefore(' '));
					zipcodes.add(accnt.Zip_To_Align__c);
				}
				else		
                if(accnt.Zip_To_Align__c.length() >= Ziplength ){
                    zipcodes.add(accnt.Zip_To_Align__c.substring(0,Ziplength)); 
                }
            }
         }      
         system.debug('-zipcodes - ' + zipcodes);
        if(zipcodes.size()>0){
            //Query the Zip_to_Terr object to get the zipcode, Territory,District and Region values and put them in a map
            for(Zip_to_Terr__c zipToTerr : [Select name, Territory__c,District__c,Country__c,Region__c,State__c from Zip_to_Terr__c WHERE Country__c = :countryName and Name IN :zipcodes]){
                zipToTerMap.put (zipToTerr.name, zipToTerr.Territory__c);
                zipToTerRegionMap.put(zipToTerr.name,zipToTerr.Region__c);
                zipToTerDistrictMap.put(zipToTerr.name,zipToTerr.District__c); 
            }
            //Map the Territory, Region, District as per the zip to align field on the account
            for(Account accnt: accountsToProcess) {
				String zipToAlign;	
                if(accnt.Zip_To_Align__c != null){
                    if(!zipToTerMap.isEmpty())
					{
						if(country == 'GB' || country == 'IE')
							zipToAlign = accnt.Zip_To_Align__c.substringBefore(' ');
						else
						if(accnt.Zip_To_Align__c.length() >= Ziplength && accnt.Zip_To_Align__c.substring(0,Ziplength) != null)  
							zipToAlign = accnt.Zip_To_Align__c.substring(0,Ziplength);
						String territory = zipToTerMap.get(zipToAlign);
						String region = zipToTerRegionMap.get(zipToAlign);
						String district = zipToTerDistrictMap.get(zipToAlign);
						if(territory != null) {
							accnt.Territory__c = territory;
							accnt.Region__c = region;
							accnt.District__c = district; 
							accountList.add(accnt);
						}							
					}
				}
            }
        }          
		try{
			if((accountList.size()>0) && batch != null){             
				update accountList;
			}
		}catch(DMLException ex){
			system.debug('***ERROR UPDATE*** ' + ex.getMessage());
		}           
    }
    //This method will update the Account owner based on the Territory value stamped on the Account
    public static void AccountOwnerUpdate(List<Account> accountsToProcess, String batch, String country){
		List<String> terrCodes = new List<String>(); 
		Set<Id> accntIds = new Set<Id>();
		List<Account> accountList = new List<Account>(); 
		List<Opportunity> opptyToBeUpdatedList = new List<Opportunity>();
		Map<Id, Account> accountMap = new Map<Id, Account>();
		Map<String,ID> territorymap =  new Map<String,Id>();
		Map<Id,Id> insideSalesUserTerritoryMap =  new Map<Id,Id>(); 
		Map<Id,Id> fieldSalesUserTerritoryMap =  new Map<Id,Id>(); 
		String salesType = 'Field';
		String CountryAdmin ='';
		switch on country {
			when 'DE' {
				CountryAdmin = ClsApexUtil.GetCountryAdmin('DE');
			}
			when 'CA' {
				CountryAdmin = ClsApexUtil.GetCountryAdmin('CA');
			}
			when 'CH' {
				CountryAdmin = ClsApexUtil.GetCountryAdmin('CH');
			}
			when 'AT' {
				CountryAdmin = ClsApexUtil.GetCountryAdmin('AT');
			}
			when 'GB' {
				CountryAdmin = ClsApexUtil.GetCountryAdmin('GB');
			}
			when 'IE' {
				CountryAdmin = ClsApexUtil.GetCountryAdmin('IE');
			}
            when 'SI' {
				CountryAdmin = ClsApexUtil.GetCountryAdmin('SI');
			}
		}
        //Find accounts, which have Territory populated in them
        for (Account accnt: accountsToProcess) {
            if(accnt.Territory__c != null) {
                terrCodes.add(accnt.Territory__c);
                accntIds.add(accnt.id);
                accountMap.put(accnt.id, accnt);
            }    
        }  
        //Invoke the utility class to get the Territory Name to Id map and User Territory map for field sales
        territorymap = ClsApexUtil.GetTerritoryMap(terrCodes);
        fieldSalesUserTerritoryMap = ClsApexUtil.GetUserTerritoryMap(terrCodes,salesType, country);
        
        //Update account owner field
        for (Account accnt: accountsToProcess) {
            if(accnt.Territory__c != null){
                if(!fieldSalesUserTerritoryMap.isEmpty() && !territorymap.isEmpty() && accnt.Territory__c !=null){
                    Id terrId  = territorymap.get(accnt.Territory__c);
                    Id ownerId  = fieldSalesUserTerritoryMap.get(terrId);
                    if(ownerId != null) {
                        accnt.ownerId = ownerId;
                    }
					else
						accnt.ownerId = CountryAdmin;
                    accountList.add(accnt);
                }  
            }
        }
        
        if(accntIds.size()>0){
            salesType = 'Inside';
            insideSalesUserTerritoryMap = ClsApexUtil.GetUserTerritoryMap(terrCodes,salesType, country);// Get the user territory map for inside sales
            List<Opportunity> opptyList = [SELECT Id, AccountID, name, OwnerID, Isclosed FROM Opportunity WHERE Isclosed = false AND AccountID IN: accntIds];    
            
            //Update Opportunity owner based on Inside sales user who is aligned to the territory
            if(opptyList.size()>0){
                for(Opportunity oppty : opptyList){   
                    if(!insideSalesUserTerritoryMap.isEmpty() && !territorymap.isEmpty() ){
                        Account accnt = accountMap.get(oppty.AccountID); 
                        Id terrId  = territorymap.get(accnt.Territory__c);
                        Id ownerId  = insideSalesUserTerritoryMap.get(terrId);    
                        if(ownerId != null) {
                            oppty.ownerId = ownerId;
                        }
						else
							oppty.ownerId = CountryAdmin;//Assign it to the country admin
						opptyToBeUpdatedList.add(oppty);
                    }
                }
            }   

            //Update the account records
            try{
                if((accountList.size()>0) && batch != null){             
                    update accountList;
                }
            }catch(DMLException ex){
                system.debug('***ERROR UPDATE*** ' + ex.getMessage());
            }
            
            //Update the Opportunity records      
            try{
                if(!opptyToBeUpdatedList.isEmpty()){          
                    update opptyToBeUpdatedList;
                }
            }catch(DMLException ex){
                system.debug('***ERROR UPDATE*** ' + ex.getMessage());
            }
        }
    }

    //This method will wipe out existing territory alignment fields before we run a batch alignment.
    public static void AccountTerritoryBlank(List<Account> accountsToProcess,String batch){
        System.debug('***accountsToProcess'+ accountsToProcess.size());
        List<Account> accountList = new List<Account>();     
        for(Account accnt: accountsToProcess) {  
            if(accnt.Territory__c != null || accnt.Zip_To_Align__c != null){
                accnt.Territory__c = null;
                accnt.Region__c = null;
                accnt.District__c = null;  
                accnt.Zip_To_Align__c = null;
            }
            accountList.add(accnt); 
        }
        //update the Account records   
        System.debug('***accountList'+accountList.size());
        try{
            if((accountList.size()>0) && batch != null){             
                update accountList;
            }
        }catch(DMLException ex){
            system.debug('***ERROR UPDATE*** ' + ex.getMessage());
        }  
    }   
}