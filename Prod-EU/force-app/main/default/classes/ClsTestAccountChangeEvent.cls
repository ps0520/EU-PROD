@isTest
public class ClsTestAccountChangeEvent {
    /****************************************************************
@Description    : Test class for AccountChnageEvent logic
*****************************************************************/
  @isTest static void testContactChangeOnAccount() {
    // Enable all Change Data Capture entities for notifications.
    Test.enableChangeDataCapture();
    //Insert an account records
    List<Account> accts = ClsTestDataFactory.createAccountsWithBillingAddress(5, 'DE Medical Facility', 'Germany');
    //Insert Contact
    Id deContactRecordtypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('DE Contact').getRecordTypeId();
    List<Contact> conList = new List<Contact>();
    for(Integer i=0; i<5 ; i++){
        Contact con = new Contact();
        con.RecordtypeId = deContactRecordtypeId;
        con.AccountId = accts[0].Id;
        con.FirstName = 'DE FirstName ' + i;
        con.LastName = 'DE LastName ' + i;
        conList.add(con);
    }
    insert conList;
    //Update Contact on the Account
    conList[3].AccountId = accts[2].Id;
    update conList[3];
    Account updAcc = new Account(Id = accts[2].Id);
    updAcc.Contact__c = conList[3].Id;
    update updAcc;
    Test.getEventBus().deliver();
  }
}