@isTest
public class ClsValRequestAccountTriggerHandlerTest {
    @isTest(SeeAllData=true)
    public Static void createValidationRequestActivity(){
        Test.enableChangeDataCapture();
        Account acc =  [SELECT Id,FirstName,MiddleName,Salutation,PersonTitle,Gender__c,OK_Ind_Type__c,
                        LastName,OK_Specialty_1__c,Medical_Facility__r.Name,OK_Main_Category__c,ShippingStreet,ShippingCity,ShippingPostalCode,ShippingState FROM Account WHERE FirstName = 'NO' AND LastName = 'PRESCRIBER' AND Country__c = 'Germany' LIMIT 1];
        acc.IQVIA_OneKeyId__c = 'W87876';
        acc.FirstName = 'NO - Modified';
        Test.startTest();
        update acc;
        Test.stopTest();
    }
}