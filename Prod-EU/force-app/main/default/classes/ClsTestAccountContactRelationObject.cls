@isTest
private class ClsTestAccountContactRelationObject {
/****************************************************************
@Description    : Test class for AccountContactRelation logic
*****************************************************************/
    @isTest static void testRelatedAccountInsUpd(){
        //Insert 10 account records
        List<Account> accts = ClsTestDataFactory.createAccountsWithBillingAddress(10, 'DE Medical Facility', 'Germany');
        Test.startTest();
        //Get the first account, which was inserted
        Account a = accts[0];
        //Insert Contact
        Id deContactRecordtypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('DE Contact').getRecordTypeId();
        List<Contact> conList = new List<Contact>();
        for(Integer i=0; i<5 ; i++){
            Contact con = new Contact();
            con.RecordtypeId = deContactRecordtypeId;
            con.AccountId = accts[i].Id;
            con.FirstName = 'DE FirstName ' + i;
            con.LastName = 'DE LastName ' + i;
            conList.add(con);
        }
        insert conList;
        //Insert AccountContactRelation
        //Contact con = new Contact();
        ClsAccountRelatedContactTriggerHandler.executeRelatedContactTrigger = true;
        Contact con = new Contact();
        con.RecordtypeId = deContactRecordtypeId;
        con.AccountId = accts[5].Id;
        con.FirstName = 'DE FirstName ' + '5';
        con.LastName = 'DE LastName ' + '5';
        insert con;
        //Update Account on Contact
        ClsAccountRelatedContactTriggerHandler.executeRelatedContactTrigger = true;
		conList[3].AccountId = accts[5].Id;
        Update conList[3];
        Test.stopTest();
    }
}