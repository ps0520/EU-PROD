/****************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 5/01/2017
@Description    : Class used in as a helper class for ClsRelatedAccountTriggerHandler
****************************************************************************************************************/
public class ClsRelatedAccountTriggerHandlerHelper{
    
    public static Map<Id, List<Related_Account__c>> GetPrimaryRelatedAccountsTiedToAccount(List<Id> accountIdsToProcess, List<Related_Account__c> primaryRelatedAccounts, String parentRelationType, String childRelationType)
    {
        
        Map<Id, List<Related_Account__c>> accntIdPrimaryRelatedAccountMap = new Map<Id, List<Related_Account__c>>();//Map holds the List of primary related accounts tied to an account
        
        //Create a map between account id and list of primary related accounts
		for(Related_Account__c relAccnt : [SELECT Parent_Account__c, Child_Account__c, Primary_Flag__c FROM Related_Account__c WHERE Primary_Flag__c = true AND Child_Account__c IN : accountIdsToProcess AND Id NOT IN : primaryRelatedAccounts AND Parent_Relation_Type__c =: parentRelationType AND Child_Relation_Type__c =: childRelationType])	
        {
            system.debug('----Entering the process of GetPrimaryRelatedAccountsTiedToAccount');
            system.debug('----Related Account Id is ' + relAccnt.Id);
			//Remove the primary flag
			relAccnt.Primary_Flag__c = false;
			//Map the account id to its possible primary related accounts, which are to be reset
			if(accntIdPrimaryRelatedAccountMap.containsKey(relAccnt.Child_Account__c)) 
			{
				List<Related_Account__c> relAccntList = accntIdPrimaryRelatedAccountMap.get(relAccnt.Child_Account__c);
				relAccntList.add(relAccnt);
				accntIdPrimaryRelatedAccountMap.put(relAccnt.Child_Account__c, relAccntList);
			}
			else
			{
				accntIdPrimaryRelatedAccountMap.put(relAccnt.Child_Account__c, new List<Related_Account__c> {relAccnt});
			}
        }
        system.debug('----Ending the process of GetPrimaryRelatedAccountsTiedToAccount');
		return(accntIdPrimaryRelatedAccountMap);
    }
}