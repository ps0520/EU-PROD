/*
 * Description - BClsRecordUpdaterPurger_Test Class will cover Code Coverage 
 * for below Classes --
 * 
 * 1 - BClsRecordUpdaterPurger
 * 2 - BClsAddressLocker
 * 
*/

@isTest
public class BClsRecordUpdaterPurger_Test {

    @isTest static void TestRecordUpdater(){
        //Insert 1 account record
        List<Account> accts = ClsTestDataFactory.createAccountsWithBillingAddress(2, 'DE Consumer', 'Germany');
        
		Account a = accts[0];
		String street = a.BillingStreet;
        a.Copy_Billing_To_Shipping__c = true ;       
		update a ;
        Id recordTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByName().get('DE Address').getRecordTypeId();
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
				
		Record_Updater__c recUpdater = new Record_Updater__c();
		recUpdater.Acted_On__c = true;
        recUpdater.Action__c = 'Insert';
        recUpdater.Id__c = addrListToBeInserted[0].Id;
        insert recUpdater;
        
       Test.startTest();
        Database.executeBatch(new BClsRecordUpdaterPurger(), 1);
		Test.stopTest();
        
        // For Address Locker Batch Class
        Record_Updater__c recUpdater1 = new Record_Updater__c();
        recUpdater1.Name = 'Address__c';
		recUpdater1.Acted_On__c = false;
        recUpdater1.Action__c = 'Insert';
        recUpdater1.Id__c = addrListToBeInserted[0].Id;
        insert recUpdater1;
        
        recUpdater1.Action__c = 'Update';
        recUpdater1.Field_Type__c = 'Checkbox';
        recUpdater1.Value__c = 'true';
        recUpdater1.FieldName__c = 'IsLocked__c';
        update recUpdater1;
        Database.executeBatch(new BClsAddressLocker(), 1);

        

	}
}