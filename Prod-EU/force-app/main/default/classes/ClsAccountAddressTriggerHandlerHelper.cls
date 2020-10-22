/****************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 4/28/2017
@Description    : Class used in as a helper class for ClsAccountAddressTriggerHandler
****************************************************************************************************************/
public class ClsAccountAddressTriggerHandlerHelper{ 
    
    public static void ProcessAddressRecords(String addressType, List<Account> accountsToProcess)
    {
        
        system.debug('----The address type to process is ' + addressType);
        Map<Id, List<Address__c>> accntIdToAddressMap = new Map<Id, List<Address__c>>();//Map holds the List of address tied to an account based on the addressType requested
        List<Address__c> addressToCreateList = new List<Address__c>();//List holds the address records to be created
        Map<Id, Address__c> addressIdToAddressMap = new Map<Id, Address__c>();//Map holds the Id to Address to its address object
        
        //Get the map between the country code to its  recordtype id for Address__c object
		Map<String, Id> addressRecordTypeMap = ClsAccountAddressTriggerHandlerHelper.getAddressRecordTypeMap();
		
        //Create a map between account id and list of addresses
        for(Address__c addr : [SELECT ID, Account__c, Address_Line_1__c, City__c, State__c, Postal_Code__c, Country__c, Primary_Flag__c FROM Address__c WHERE Type__c = :addressType AND Account__c IN : accountsToProcess])
        {
            system.debug('----There are address tied the account');
            if(accntIdToAddressMap.containsKey(addr.Account__c)) 
            {
                List<Address__c> addrList = accntIdToAddressMap.get(addr.Account__c);
                addrList.add(addr);
                accntIdToAddressMap.put(addr.Account__c, addrList);
            }
            else
            {
                accntIdToAddressMap.put(addr.Account__c, new List<Address__c> {addr});
            }
            
        }
        for(Account accnt : accountsToProcess)
        {
            Boolean existingAddrFound = false;
            Address__c existingAddrToBeUpdated;            
            List<Address__c> tempAddrList = accntIdToAddressMap.get(accnt.Id);//Store all Address for the Account for a given type            
            String billingRecordTypeId = (accnt.BillingCountryCode == 'GB' || accnt.BillingCountryCode == 'IE') ? addressRecordTypeMap.get('UK') : addressRecordTypeMap.get(accnt.BillingCountryCode);
            String shippingRecordTypeId = (accnt.ShippingCountryCode == 'GB' || accnt.ShippingCountryCode == 'IE') ? addressRecordTypeMap.get('UK') : addressRecordTypeMap.get(accnt.ShippingCountryCode);
            			
		//	String shippingRecordTypeId = addressRecordTypeMap.get(accnt.ShippingCountryCode);
            //Process Address logic
            if(tempAddrList != null)
            {
                if(!tempAddrList.isEmpty())
                {
                    //Remove the primary flag for existing addresses
                    for(Address__c primaryAddr : tempAddrList)
                    {
                        
                        if(primaryAddr.Primary_Flag__c)
                        {
                            system.debug('----Primary Address exist and the Id is ' + primaryAddr.Id);
							system.debug('----Set Primary flag to false');
                            primaryAddr.Primary_Flag__c = false;
                            addressIdToAddressMap.put(primaryAddr.Id, primaryAddr);
                        }
                    }
                    
                    //Process the address list tied to the account to add or create address record
                    for(Address__c addrToUpdate : tempAddrList)
                    {
                        
                        //Check if the Address tied to the account already exist in the address object for this account
                        system.debug('----Street addr to check if it matches with the account address -- ' + addrToUpdate.Address_Line_1__c);
                        if(addressType == 'Bill To')
                        {   
                            if(accnt.BillingStreet == addrToUpdate.Address_Line_1__c &&
                               accnt.BillingCity == addrToUpdate.City__c &&
                               accnt.BillingState == addrToUpdate.State__c &&
                               accnt.BillingPostalCode == addrToUpdate.Postal_Code__c &&
                               accnt.BillingCountry == addrToUpdate.Country__c)
                            {
                                system.debug('----Billing address matched');
                                existingAddrFound = true;
                                existingAddrToBeUpdated = addrToUpdate;
                            }
                        }
                        else if(addressType == 'Ship To')
                        {
                            
                            if(accnt.ShippingStreet == addrToUpdate.Address_Line_1__c &&
                               accnt.ShippingCity == addrToUpdate.City__c &&
                               accnt.ShippingState == addrToUpdate.State__c &&
                               accnt.ShippingPostalCode == addrToUpdate.Postal_Code__c &&
                               accnt.ShippingCountry == addrToUpdate.Country__c)
                            {
                                system.debug('----Shipping address matched');
                                existingAddrFound = true;
                                existingAddrToBeUpdated = addrToUpdate;
                            }
                        }   
                        
                    }
                    //If existing address is found then update the primary flag
                    if(existingAddrFound)
                    {
                        system.debug('----Update the primary for the matched address');
						if(addressIdToAddressMap.containsKey(existingAddrToBeUpdated.Id))
                        {
                            system.debug('-----Entering the process where the address exist in the map');
                            Address__c addr = addressIdToAddressMap.get(existingAddrToBeUpdated.Id);
                            addr.Primary_Flag__c = true;
                            addressIdToAddressMap.put(addr.Id, addr);
                        }
                        else
                        {
                            system.debug('-----Entering the process where the address does not exist in the map');
                            existingAddrToBeUpdated.Primary_Flag__c = true;
                            addressIdToAddressMap.put(existingAddrToBeUpdated.Id, existingAddrToBeUpdated);
                        }
                        
                    }
                    //If no address is found create a new address record
                    if(!existingAddrFound)
                    {
                        //Create a new Bill To Address record
						system.debug('----Create a new primary address');
                        Address__c addrToCreate;
                        if(addressType == 'Bill To')
                            addrToCreate = CreateAddress(accnt.Id, accnt.BillingStreet, accnt.BillingCity, accnt.BillingState, accnt.BillingPostalCode, accnt.BillingCountry, addressType, billingRecordTypeId);
                        if(addressType == 'Ship To')
                            addrToCreate = CreateAddress(accnt.Id, accnt.ShippingStreet, accnt.ShippingCity, accnt.ShippingState, accnt.ShippingPostalCode, accnt.ShippingCountry, addressType, shippingRecordTypeId);
                        addressToCreateList.add(addrToCreate);
                    }   
                    
                }
            }
			//If there isn't any address records in the system already for the account then create new entries
			else
			{
				//Create a new Bill To and Ship To Address record
				system.debug('----Create a new primary address');
				Address__c billtoAddrToCreate;
				Address__c shiptoAddrToCreate;
				if(addressType == 'Bill To' && accnt.BillingStreet != null){
					billtoAddrToCreate = CreateAddress(accnt.Id, accnt.BillingStreet, accnt.BillingCity, accnt.BillingState, accnt.BillingPostalCode, accnt.BillingCountry, addressType, billingRecordTypeId);
					system.debug('billtoAddrToCreate is ' + billtoAddrToCreate);
					addressToCreateList.add(billtoAddrToCreate);
				}
				if(addressType == 'Ship To' && accnt.ShippingStreet != null){
					shiptoAddrToCreate = CreateAddress(accnt.Id, accnt.ShippingStreet, accnt.ShippingCity, accnt.ShippingState, accnt.ShippingPostalCode, accnt.ShippingCountry, addressType, shippingRecordTypeId);
					system.debug('shiptoAddrToCreate is ' + shiptoAddrToCreate);
					addressToCreateList.add(shiptoAddrToCreate);
				}
			} 
        }
        //Update Address Records
        if(!addressIdToAddressMap.values().isEmpty())
        {
            system.debug('-----Update list entered');
            try{update addressIdToAddressMap.values();}
            catch (DmlException de) {
                Integer numErrors = de.getNumDml();
                System.debug('getNumDml=' + numErrors);
                for(Integer i=0;i<numErrors;i++) {
                    System.debug('getDmlFieldNames=' + de.getDmlFieldNames(i));
                    System.debug('getDmlMessage=' + de.getDmlMessage(i));
                }
            }
        }          
        //Insert Address Records
        if(!addressToCreateList.isEmpty())
        {
            system.debug('-----Insert list entered');
             system.debug('-----Insert list entered'+ addressToCreateList);
            try{insert addressToCreateList;}
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
    //Method creates a new address for a given type
    public static Address__c CreateAddress (Id accountId, String street, String city, String state, String zip, String country, String type, String recordTypeId)
    {
        //Get Address record type for the Country__c
		Address__c addressToCreate = new Address__c ();
        addressToCreate.Account__c = accountId;
        addressToCreate.Address_Line_1__c = street;
        addressToCreate.City__c = city;
        addressToCreate.State__c = state;
        addressToCreate.Postal_Code__c = zip;
        addressToCreate.Country__c = country;
        addressToCreate.Type__c = type;
		addressToCreate.RecordtypeId = recordTypeId; // -- Will be defaulted from Profile
        addressToCreate.Primary_Flag__c = true;
        system.debug('recordTypeId='+recordTypeId);
        return addressToCreate;
    }

	//Create map between the country code to its  recordtype id for Address__c object
	 public static Map<String, Id> getAddressRecordTypeMap ()
	{
		Map<String, Id> addressRecordTypeMap = new Map<String, Id>();
		for(RecordType rt : [SELECT Id, Developername FROM RecordType WHERE SobjectType = 'Address__c'])
		{
			String countryCode = rt.Developername.substring(0,2);
			addressRecordTypeMap.put(countryCode, rt.Id);
            system.debug('countryCode='+countryCode);
		}
        
		return addressRecordTypeMap;
	}	
}