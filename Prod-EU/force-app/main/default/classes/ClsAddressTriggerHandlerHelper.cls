/****************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 4/28/2017
@Description    : Class used in as a helper class for ClsAddressTriggerHandler
****************************************************************************************************************/
public class ClsAddressTriggerHandlerHelper{
    
    public static Map<Id, List<Address__c>> GetPrimaryAddressesTiedToAccount(String addressType, List<Id> accountIdsToProcess, List<Address__c> primaryAddresses)
    {
        
        Map<Id, List<Address__c>> accntIdPrimaryAddressMap = new Map<Id, List<Address__c>>();//Map holds the List of primary addresses tied to an account for a given type
        
        //Create a map between account id and list of primary addresses
        for(Address__c addr : [SELECT ID, Account__c, Address_Line_1__c, City__c, State__c, Postal_Code__c, Country__c, Primary_Flag__c FROM Address__c WHERE Primary_Flag__c = true AND Type__c = :addressType AND Account__c IN : accountIdsToProcess AND Id NOT IN : primaryAddresses])
        {
           
			//Remove the primary flag
			addr.Primary_Flag__c = false;
			//Map the account id to its possible primary addresses, which are to be reset
			if(accntIdPrimaryAddressMap.containsKey(addr.Account__c)) 
			{
				List<Address__c> addrList = accntIdPrimaryAddressMap.get(addr.Account__c);
				addrList.add(addr);
				accntIdPrimaryAddressMap.put(addr.Account__c, addrList);
			}
			else
			{
				accntIdPrimaryAddressMap.put(addr.Account__c, new List<Address__c> {addr});
			}
        }
        system.debug('----Ending the process of GetPrimaryAddressesTiedToAccount');
		return(accntIdPrimaryAddressMap);
    }
}