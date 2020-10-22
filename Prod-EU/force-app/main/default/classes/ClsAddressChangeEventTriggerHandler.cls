public class ClsAddressChangeEventTriggerHandler
{
    //Method will process the inserted onekey id from onekey (Ship To) and creates a corresponding Bill To if there isn't one already
    public static void processOneKeyAddresses(Set<String> oneKeyAddressIds, Set<String> accountIds)
    {
        system.debug('*******ADDRCHGEVT - Entered the method processOneKeyAddresses');
        Set<Id> accountIdsWithBillTo = new Set<Id>();
        List<Address__c> billToAddressesToBeCreated = new List<Address__c>();

        //Populate the set with the accountIds that have already Billto association
        for(Address__c addr : [SELECT Id, Account__c FROM Address__c WHERE Account__c IN : accountIds AND Type__c = 'Bill To'])
            accountIdsWithBillTo.add(addr.Account__c);
        
        //For the addresses that are inserted by OneKey
        for(Address__c shipToAddr : [SELECT Id, Account__c, RecordTypeId, Createdby.Name, Address_Line_1__c, Address_Line_2__c, City__c, State__c, Postal_Code__c, Country__c, Primary_Flag__c FROM Address__c WHERE Id IN : oneKeyAddressIds])
        {
            system.debug('Createdby Name is ' + shipToAddr.Createdby.Name);
            //If there isn't any Billto associated to associated then create a bill to with the ship to details
            if(accountIdsWithBillTo!= null && !accountIdsWithBillTo.contains(shipToAddr.Account__c) && shipToAddr.Createdby.Name != 'Automated Process')
            {
                system.debug('*******ADDRCHGEVT - No Bill to exists for this account, so creating one');
                Address__c billToAddr = new Address__c();
                billToAddr.Account__c = shipToAddr.Account__c;
                billToAddr.Address_Line_1__c = shipToAddr.Address_Line_1__c;
                billToAddr.Address_Line_2__c = shipToAddr.Address_Line_2__c;
                billToAddr.City__c = shipToAddr.City__c;
                billToAddr.State__c = shipToAddr.State__c;
                billToAddr.Postal_Code__c = shipToAddr.Postal_Code__c;
                billToAddr.Country__c = shipToAddr.Country__c;
                billToAddr.Primary_Flag__c = shipToAddr.Primary_Flag__c;
                billToAddr.Type__c = 'Bill To';
                billToAddr.RecordTypeId = shipToAddr.RecordTypeId;
                billToAddressesToBeCreated.add(billToAddr);
            }

        }
        if(!billToAddressesToBeCreated.isEmpty()){
            system.debug('*******ADDRCHGEVT - Insert Billto list of addresses');
            ClsAccountAddressTriggerStaticClass.addressChangeInvokedFromAddress = true;
            insert billToAddressesToBeCreated;
        }
    }
}