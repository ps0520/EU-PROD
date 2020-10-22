@isTest
public class CtrlCanadianPayorMatrixTest {

    @isTest
    public static void testgetAccountId() {
        Map<String, Id> recTypesMap = ClsTestDataFactory.getRecordTypeMap();
        Account payorAcc = new Account(Name='Payor Account', RecordTypeId = recTypesMap.get('CA Payor') , BillingStreet = '1121 Main St.', BillingCity='Toronto',  BillingState= 'Ontario', BillingPostalCode='M4G 3L2',BillingStateCode='ON', BillingCountryCode='CA' );
        insert payorAcc;
        Account conAcc = new Account(firstname='Test', lastName='Consumer', personEmail='test@tester.com',RecordTypeId = recTypesMap.get('CA Consumer') );
		insert conAcc;
        Benefit__c ben = new Benefit__c(Account__c = conAcc.Id, Benefit_Hierarchy__c = 'Primary', Payor__c=payorAcc.Id,  Insurance_Holder_s_Relationship__c='Self',Policy_Number__c = '23228232', InActive__c = false);
        insert ben;
        ID oppRecType = [Select Id from RecordType where isActive = true AND Sobjecttype = 'Opportunity' and DeveloperName = 'CA_Opportunity'].id;
        Opportunity opp = new Opportunity(Name='Test Opp', CloseDate=System.today(), StageName='New Opportunity', AccountId = conAcc.Id, Benefit__c = ben.Id, RecordTypeId = oppRecType);
        insert opp;
        String benPayorId = CtrlCanadianPayorMatrix.getAccountId(opp.id);
        system.assertEquals(payorAcc.Id, benPayorId);
        Account a = CtrlCanadianPayorMatrix.getReqDocs(benPayorId);
        system.assertEquals(payorAcc.Id, a.Id);
    }
}