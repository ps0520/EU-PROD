@isTest
public class ClsContactObjectTest {

    @isTest
    private static void testContactObject() {
        Map<String, Id> recTypesMap = ClsTestDataFactory.getRecordTypeMap();
        Account payorAcc = new Account(Name='Payor Account', RecordTypeId = recTypesMap.get('CA Payor') , BillingStreet = '1121 Main St.', BillingCity='Toronto',  BillingState= 'Ontario', BillingPostalCode='M4G 3L2', BillingStateCode='ON', BillingCountryCode='CA' );
        insert payorAcc;
        insert new Contact(AccountId = payorAcc.Id, LastName = 'Contact');
        system.assertNotEquals(Null, Contact.Id);
    }
}