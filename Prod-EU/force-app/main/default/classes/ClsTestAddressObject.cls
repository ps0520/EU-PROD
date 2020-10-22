/********************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 08/12/2017
@Description    : Test class to test the scenarios involved in Address object
*********************************************************************************/
@isTest
private class ClsTestAddressObject {
    @isTest static void TestAccountAddress(){
        //Insert 1 account record
        List<Account> accts = ClsTestDataFactory.createAccountsWithBillingAddress(2, 'DE Consumer', 'Germany');
        Test.startTest();
		ClsAccountAddressTriggerStaticClass.addressChangeInvokedFromAddress = TRUE;
		ClsAccountAddressTriggerStaticClass.addressChangeInvokedFromAccount = FALSE;
		//Get the first account, which was inserted
		Account a = accts[0];
		String street = a.BillingStreet;
        a.Copy_Billing_To_Shipping__c = true ;
     //   a.Copy_Shipping_To_Billing__c = true ;        
		update a ;
        
       //Query for the Address record types
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                               where sObjectType='Address__c' and isActive=true];
    
        //Create a map between the Record Type Name and Id 
        Map<String,String> addRecordTypes = new Map<String,String>();
        for(RecordType rt: rtypes) {
        addRecordTypes.put(rt.Name,rt.Id);
        }     	
        String recordTypeId = addRecordTypes.get('DE Address');
        
		//Insert new Bill To and Ship To address records
		List<Address__c> addrListToBeInserted = new List<Address__c>();
		Address__c newBillToAddr = new Address__c();
		newBillToAddr.Account__c = a.Id;
        newBillToAddr.RecordTypeId = recordTypeId;
		newBillToAddr.Address_Line_1__c = '3 Main Street';
		newBillToAddr.City__c = 'San Diego';
		newBillToAddr.Postal_Code__c = '92121';
		newBillToAddr.Country__c = 'Germany';
		newBillToAddr.Type__c = 'Bill To';
		newBillToAddr.Primary_Flag__c = TRUE;
		addrListToBeInserted.add(newBillToAddr);

        Address__c newShipToAddr = new Address__c();
		newShipToAddr.Account__c = a.Id;
        newShipToAddr.RecordTypeId = recordTypeId;
		newShipToAddr.Address_Line_1__c = '3 Main Street';
		newShipToAddr.City__c = 'San Diego';
		newShipToAddr.Postal_Code__c = '92123';
		newShipToAddr.Country__c = 'Germany';
		newShipToAddr.Type__c = 'Ship To';
		newShipToAddr.Primary_Flag__c = TRUE;
		addrListToBeInserted.add(newShipToAddr);
		insert addrListToBeInserted;
				
		//Process to make existing address as Primary
		List<Address__c> addrListToBeUpdated = new List<Address__c>();
		//Query for original billing primary address and make it as primary
		Address__c billToAddrToBeMadePrimary = [SELECT Id FROM Address__c WHERE Address_Line_1__c = :street AND Account__c = :a.Id AND Type__c = 'Bill To'];
		billToAddrToBeMadePrimary.Primary_Flag__c = TRUE;
		addrListToBeUpdated.add(billToAddrToBeMadePrimary);
		//Query for original shipping primary address and make it as primary
		Address__c shipToAddrToBeMadePrimary = [SELECT Id FROM Address__c WHERE Address_Line_1__c = :street AND Account__c = :a.Id AND Type__c = 'Ship To'];
		shipToAddrToBeMadePrimary.Primary_Flag__c = TRUE;
		addrListToBeUpdated.add(shipToAddrToBeMadePrimary);
		update addrListToBeUpdated;
		addrListToBeUpdated.clear();
		
		//Alter existing primary address attributes
		//Query for original billing primary address and make it as primary
		Address__c billToPrimaryAddr = [SELECT Id FROM Address__c WHERE Account__c = :a.Id AND Type__c = 'Bill To' AND Primary_Flag__c = TRUE];
		billToPrimaryAddr.Address_Line_1__c = 'Street Address Changed';
		addrListToBeUpdated.add(billToPrimaryAddr);
		Address__c shipToPrimaryAddr = [SELECT Id FROM Address__c WHERE Account__c = :a.Id AND Type__c = 'Ship To' AND Primary_Flag__c = TRUE];
		shipToPrimaryAddr.Address_Line_1__c = 'Street Address Changed';
		addrListToBeUpdated.add(shipToPrimaryAddr);
		Update addrListToBeUpdated;
       
               
        
        Account acc = [SELECT Id FROM Account limit 1];
        delete acc;
		
		Test.stopTest();
	}
}