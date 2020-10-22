/********************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 08/12/2017
@Description    : Test class to test the batch territory assignment
*********************************************************************************/
@isTest 
public class BClsTestAccountTerritoryAlignment 
{
    @isTest static void TestAccountBatchAssignment()
    {
		List<Account> accts = ClsTestDataFactory.createAccountsWithBillingAddress(10, 'DE Consumer', 'Germany');
 		Test.startTest();
		BClsAccountTerritoryAlignment batchClass = new BClsAccountTerritoryAlignment('SELECT Id, Firstname, Lastname, Country__c, RecordtypeID, Territory__c, District__c, Region__c, Medical_Facility__c, ShippingPostalCode, BillingPostalCode, Prescriber__c, Zip_To_Align__c FROM Account WHERE Country__c = \'Germany\'', 'DE');
		Database.executeBatch(batchClass, 10);
		Test.stopTest();
    }
}