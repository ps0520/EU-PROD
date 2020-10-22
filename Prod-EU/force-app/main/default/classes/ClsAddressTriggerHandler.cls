/*******************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 4/30/2017
@Description    : Class used in to process all Address related logic for Address object upon inserting and updating
********************************************************************************************************************/
public class ClsAddressTriggerHandler
{
    
    static List<Id> accountIdsToProcess = new List<Id>();//List of Accounts to be processed
    static List<Address__c> addressToProcess = new List<Address__c>();//List of Addresses to be processed
	static Map<Id, Account> accountsToProcess = new Map<Id, Account>();//Map Accounts to be updated with Bill To or Ship To address information
    static Boolean billToExist = false;//Check if Bill To Address exist
    static Boolean shipToExist = false;//Check if Ship To Address exist
    
    //Method unsets the primary flag for other Bill To or Ship To addresses provided the inserted address record has primary flag checked
    public static void ProcessAddressInsert(List<Address__c> addresses)
    {
        //Find the addresses, which have the primary flag set
        for(Address__c addr : addresses)
        {
            system.debug('----Address Id to Process ' + addr.Id);
            system.debug('----Account Id to Process ' + addr.Account__c);
            
            if(addr.Primary_Flag__c)
            {
                accountIdsToProcess.add(addr.Account__c);
                addressToProcess.add(addr);
                if(addr.Type__c == 'Bill To')
                    billToExist = true;
                else
                    if(addr.Type__c == 'Ship To')
                    shipToExist = true;
            }
        }
        if(addressToProcess != null)
        {
            ProcessPrimaryAddress();
        }
        
    }
    
    //Method unsets the primary flag for other Bill To or Ship To addresses provided the updated address record has primary flag checked
    public static void ProcessAddressUpdate(Map<Id, Address__c> newTriggerAddresses, Map<Id, Address__c> oldTriggerAddresses)
    {
        addressToProcess.clear();
        
		//Check if any address got updated with primary flag and then proceeed
        for(Address__c newAddr : newTriggerAddresses.values())
        {
            Address__c oldAddr = oldTriggerAddresses.get(newAddr.Id);
            //Check if the primary flag is changed with a true value
            if((oldAddr.Primary_Flag__c != newAddr.Primary_Flag__c) && newAddr.Primary_Flag__c)
            {
                system.debug('----Primary flag was updated on the address, so entering the block');
                accountIdsToProcess.add(newAddr.Account__c);
                addressToProcess.add(newAddr);
                if(newAddr.Type__c == 'Bill To')
                    billToExist = true;
                else
                    if(newAddr.Type__c == 'Ship To')
                    shipToExist = true;
            }
			//Check for existing Primary address any of the address related informamtion has been changed
			if((oldAddr.Primary_Flag__c == newAddr.Primary_Flag__c) && newAddr.Primary_Flag__c &&
				(oldAddr.Address_Line_1__c != newAddr.Address_Line_1__c || oldAddr.City__c != newAddr.City__c || oldAddr.State__c != newAddr.State__c || oldAddr.Postal_Code__c != newAddr.Postal_Code__c || oldAddr.Country__c != newAddr.Country__c))
			{
				Account accntToBeUpdated = new Account(Id = newAddr.Account__c);
				system.debug('----Found mismatch in address information');
				if(newAddr.Type__c == 'Bill To')
				{
					accntToBeUpdated.BillingStreet = newAddr.Address_Line_1__c;
					accntToBeUpdated.BillingCity = newAddr.City__c;
					accntToBeUpdated.BillingState = newAddr.State__c;
					accntToBeUpdated.BillingPostalCode = newAddr.Postal_Code__c;
					accntToBeUpdated.BillingCountry = newAddr.Country__c;
					accountsToProcess.put(newAddr.Account__c, accntToBeUpdated);
					system.debug('----Account, which will be updated is ' + newAddr.Account__c);
				}
				else
				if(newAddr.Type__c == 'Ship To')
				{
					accntToBeUpdated.ShippingStreet = newAddr.Address_Line_1__c;
					accntToBeUpdated.ShippingCity = newAddr.City__c;
					accntToBeUpdated.ShippingState = newAddr.State__c;
					accntToBeUpdated.ShippingPostalCode = newAddr.Postal_Code__c;
					accntToBeUpdated.ShippingCountry = newAddr.Country__c;
					accountsToProcess.put(newAddr.Account__c, accntToBeUpdated);
					system.debug('----Account, which will be updated is ' + newAddr.Account__c);
				}
				
			}
        }
		//If there are changes to Primary address then account's primary should be updated accordingly
        if(!addressToProcess.isEmpty())
        {
            ProcessPrimaryAddress();
        }
		//If there are changes to any address attributes on the Primary addresss then corresponding account's primary address should be updated accordingly
		if(!accountsToProcess.isEmpty())
        {
			UpdateAccounts(accountsToProcess.values());
		}
        
    }
    
    //Helper class, which will process the address records for primary flag reset
    public static void ProcessPrimaryAddress()
    {
        Map<Id, List<Address__c>> accntIdBillToPrimaryAddressMap = new Map<Id, List<Address__c>>();//Map holds the List of Bill To address tied to an account 
        Map<Id, List<Address__c>> accntIdShipToPrimaryAddressMap = new Map<Id, List<Address__c>>();//Map holds the List of Ship To address tied to an account 
        List<Address__c> removePrimaryAddressList = new List<Address__c>();//List holds the address records to be updated to remove the primary flag
		
        if(!addressToProcess.isEmpty())
        {
            //Get the List of Primary Bill To and Ship To address tied to the account record
            if(billToExist)
			{
                accntIdBillToPrimaryAddressMap = ClsAddressTriggerHandlerHelper.GetPrimaryAddressesTiedToAccount('Bill To', accountIdsToProcess, addressToProcess);
				system.debug('----The size of accntIdBillToPrimaryAddressMap is '+accntIdBillToPrimaryAddressMap.values().size());
            }
			if(shipToExist)
			{
                accntIdShipToPrimaryAddressMap = ClsAddressTriggerHandlerHelper.GetPrimaryAddressesTiedToAccount('Ship To', accountIdsToProcess, addressToProcess);
				system.debug('----The size of accntIdShipToPrimaryAddressMap is '+accntIdShipToPrimaryAddressMap.values().size());
			}
        }
        for(Address__c addrToProcess : addressToProcess)
        {
            system.debug('----Address processing ' + addrToProcess.Id);
            Account accntToBeUpdated;
			if(accountsToProcess.get(addrToProcess.Account__c) != null)
				accntToBeUpdated = accountsToProcess.get(addrToProcess.Account__c);
			else
				accntToBeUpdated = new Account(Id = addrToProcess.Account__c);
            List<Address__c> tempAddrList;
            if(addrToProcess.Type__c == 'Bill To')
            {
                tempAddrList = (!accntIdBillToPrimaryAddressMap.isEmpty()) ? accntIdBillToPrimaryAddressMap.get(addrToProcess.Account__c) : null;
                accntToBeUpdated.BillingStreet = addrToProcess.Address_Line_1__c;
                accntToBeUpdated.BillingCity = addrToProcess.City__c;
                accntToBeUpdated.BillingState = addrToProcess.State__c;
                accntToBeUpdated.BillingPostalCode = addrToProcess.Postal_Code__c;
                accntToBeUpdated.BillingCountry = addrToProcess.Country__c;
                accountsToProcess.put(addrToProcess.Account__c, accntToBeUpdated);
				system.debug('----Account, which will be updated is ' + addrToProcess.Account__c);
                
            }
            else if (addrToProcess.Type__c == 'Ship To')
            {
                tempAddrList = (!accntIdShipToPrimaryAddressMap.isEmpty()) ? accntIdShipToPrimaryAddressMap.get(addrToProcess.Account__c) : null;
                accntToBeUpdated.ShippingStreet = addrToProcess.Address_Line_1__c;
                accntToBeUpdated.ShippingCity = addrToProcess.City__c;
                accntToBeUpdated.ShippingState = addrToProcess.State__c;
                accntToBeUpdated.ShippingPostalCode = addrToProcess.Postal_Code__c;
                accntToBeUpdated.ShippingCountry = addrToProcess.Country__c;
                accountsToProcess.put(addrToProcess.Account__c, accntToBeUpdated);
				system.debug('----Account, which will be updated is ' + addrToProcess.Account__c);
            }
            if(tempAddrList != null) //This is to avoid null pointer exception otherwise just checking isEmpty is ok
            {
                if(!tempAddrList.isEmpty())
                    removePrimaryAddressList.addall(tempAddrList);
            }    
            system.debug('----Number of primary address to be inactivated ' + removePrimaryAddressList.size());
        }
        //Update Address Records to reset the primary flag
        if(!removePrimaryAddressList.isEmpty())
        {
            system.debug('-----Update list entered for Addresses');
            Map<Id, Address__c> removePrimaryAddressMap = new Map<Id, Address__c>();
            for(Address__c addr : removePrimaryAddressList) removePrimaryAddressMap.put(addr.Id, addr);
            try{update removePrimaryAddressMap.values();}
            catch (DmlException de) {
                Integer numErrors = de.getNumDml();
                System.debug('getNumDml=' + numErrors);
                for(Integer i=0;i<numErrors;i++) {
                    System.debug('getDmlFieldNames=' + de.getDmlFieldNames(i));
                    System.debug('getDmlMessage=' + de.getDmlMessage(i));
                }
            }
        }
        
        //Update Account Records to set Billing and Shipping address
        if(!accountsToProcess.isEmpty())
        {
            UpdateAccounts(accountsToProcess.values());
        }
    }
	//Method updates accounts
    public static void UpdateAccounts(List<Account> accountsToBeUpdated)
    {
		system.debug('-----Update list entered for Accounts');
		ClsAccountAddressTriggerStaticClass.addressChangeInvokedFromAccount = false;
		try{update accountsToProcess.values();}
		catch (DmlException de) {
			Integer numErrors = de.getNumDml();
			System.debug('getNumDml=' + numErrors);
			for(Integer i=0;i<numErrors;i++) {
				System.debug('getDmlFieldNames=' + de.getDmlFieldNames(i));
				System.debug('getDmlMessage=' + de.getDmlMessage(i));
			}
		}
	}
    //Method to handle Publishing of addresses
    public static void handleAddressCreatePublish(List<Address__c> addresses){
        //At this time have to handle addresses pertaining to Canada only 
        Set<Id> caAds = new Set<Id>();
        for(Address__c add : addresses) {
            if(add.IQVIA_OneKeyId__c == null) //Stop the IQVIA address publishing on create  
            	caAds.add(add.Id);
        }
        if (caAds.size() > 0) PEClsHandleAddressEvents.sendCreatedAddresses(caAds);
    }
    //Method to handle Publishing of addres update
    public static void handleAddressUpdatePublish(Map<Id, Address__c> newTriggerAddresses, Map<Id, Address__c> oldTriggerAddresses){
        Set<Id> caAds = new Set<Id>();
        for(Address__c a : newTriggerAddresses.values() ) {
            if (oldTriggerAddresses.size() == 0) caAds.add(a.Id);
            else {
                //if ( a.System_Of_Origin__c ==  oldTriggerAddresses.get(a.Id).System_Of_Origin__c ) // Item is not being published because system of origin changed.
                	//{caAds.add(a.Id); continue;}
                if ( a.Inactive__c !=  oldTriggerAddresses.get(a.Id).Inactive__c ) {caAds.add(a.Id); continue;}
                if ( a.Primary_Flag__c !=  oldTriggerAddresses.get(a.Id).Primary_Flag__c ) {caAds.add(a.Id); continue;}
                if ( a.isLocked__c !=  oldTriggerAddresses.get(a.Id).isLocked__c ) {caAds.add(a.Id); continue;}
                if ( a.Type__c !=  oldTriggerAddresses.get(a.Id).Type__c ) {caAds.add(a.Id); continue;}
                if ( a.Business_Name__c !=  oldTriggerAddresses.get(a.Id).Business_Name__c ) {caAds.add(a.Id); continue;}
                if ( a.First_Name__c !=  oldTriggerAddresses.get(a.Id).First_Name__c ) {caAds.add(a.Id); continue;}
                if ( a.Last_Name__c !=  oldTriggerAddresses.get(a.Id).Last_Name__c ) {caAds.add(a.Id); continue;}
                if ( a.Address_Line_1__c !=  oldTriggerAddresses.get(a.Id).Address_Line_1__c ) {caAds.add(a.Id); continue;}
                if ( a.Address_Line_2__c !=  oldTriggerAddresses.get(a.Id).Address_Line_2__c ) {caAds.add(a.Id); continue;}
                if ( a.Address_Line_3__c !=  oldTriggerAddresses.get(a.Id).Address_Line_3__c ) {caAds.add(a.Id); continue;}
                if ( a.City__c !=  oldTriggerAddresses.get(a.Id).City__c ) {caAds.add(a.Id); continue;}
                if ( a.State__c !=  oldTriggerAddresses.get(a.Id).State__c ) {caAds.add(a.Id); continue;}
                if ( a.Postal_Code__c !=  oldTriggerAddresses.get(a.Id).Postal_Code__c ) {caAds.add(a.Id); continue;}
                if ( a.Country__c !=  oldTriggerAddresses.get(a.Id).Country__c ) {caAds.add(a.Id); continue;}
                if ( a.Primary_Phone__c !=  oldTriggerAddresses.get(a.Id).Primary_Phone__c ) {caAds.add(a.Id); continue;}
            }
        }
		if (caAds.size() > 0) PEClsHandleAddressEvents.sendUpdatedAddresses(caAds);
    }
    //Method to set the System Of Origin related information for Addresses created here. 
	public static void processSystemOfOriginOnAddressCreate(List<Address__c> addressList) {
        List<Address__c> updAddresses = new List<Address__c>();
        for(Address__c add : addressList) {
            Address__c updAdd = new Address__c(id = add.Id);
            if (String.isBlanK(add.System_Of_Origin__c)) {
                updAdd.System_Of_Origin__c = 'crm'; 
                updAdd.System_Of_Origin_Id__c = add.Id; 
            	updAdd.SOS_Unique_ID__c = 'crm'+add.Id; 
                updAddresses.add(updAdd);
            }
        }
        
        if (updAddresses.size() > 0) {
            Map<Id, Address__c> updAddressesMap = new Map<Id, Address__c>();//Created to avoid duplicate value in the List
            for(Address__c addr : updAddresses) updAddressesMap.put(addr.Id, addr);
            try{update updAddressesMap.values();}
            catch (DmlException de) {
                system.debug('Error in updating the System of Origin related data during Account Creation. Error: ' + de.getMessage());
            }
        }
    }
    //Process OneKey Address Inserts/Updates
    public static void processOneKeyAddress(List<Address__c> addresses, String isBeforeAfterInsert)
    {
        //Noticed for CA Address when IQVIA is inserting the address, the CREATE change event is not getting published instead only the UPDATE event is published,so we have to force from here
        if(isBeforeAfterInsert == 'AfterInsert'){
            Set<String> oneKeyAddressIds = new Set<String>();
            Set<String> accountIds = new Set<String>();
            for(Address__c addr : addresses)
            {
                if(addr.Country__c == 'Canada' && addr.IQVIA_OneKeyId__c != null){
                    oneKeyAddressIds.add(addr.Id);
                    accountIds.add(addr.Account__c);
                }
            }
            if(!oneKeyAddressIds.isEmpty() && !accountIds.isEmpty())
               ClsAddressChangeEventTriggerHandler.processOneKeyAddresses(oneKeyAddressIds, accountIds); 
        }else
        if(isBeforeAfterInsert == 'BeforeInsert')
        {
            Boolean processCAOneKeyAddr = false;
            //Check for CA OneKey Address to process
            for(Address__c addr : addresses)
            {
                if(addr.Country__c == 'Canada' && (addr.State_Code__c != null || addr.OK_PO_Box_Label__c != null))
                    processCAOneKeyAddr = true;
            }
            if(processCAOneKeyAddr){
                //Get the CA State codes
                Map<String, String> caStateCodeMap =  stateCodeMapping('CA');
                if(!caStateCodeMap.isEmpty()){
                    for(Address__c addr : addresses)
                    {
                        if(addr.Country__c == 'Canada' && addr.State_Code__c != null){
                            if(caStateCodeMap.containsKey(addr.State_Code__c))
                                addr.State__c = caStateCodeMap.get(addr.State_Code__c);
                        }
                        if(addr.Country__c == 'Canada' && addr.OK_PO_Box_Label__c != null && addr.Address_Line_1__c == null){
                                addr.Address_Line_1__c = addr.OK_PO_Box_Label__c;
                        }
                    }
                }
            }
        }
    }

    //Retrieve the Custom Metadata Definition to map State code values
    public static Map<String, String> stateCodeMapping (String countryCode)
    {
        Map<String, String> stateCodeMapping = new Map<String, String>();
        for (State_Code_Mapping__mdt stateCodeEntry : [SELECT MasterLabel,Country_Code__c,State_Code__c,State_Value__c FROM State_Code_Mapping__mdt WHERE Country_Code__c = :countryCode])
            stateCodeMapping.put(stateCodeEntry.State_Code__c, stateCodeEntry.State_Value__c);
        return stateCodeMapping;
    }

}