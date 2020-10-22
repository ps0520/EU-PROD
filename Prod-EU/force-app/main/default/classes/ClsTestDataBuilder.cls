/**********************************************
 * @author      : Anuj Patel
 * @date        : June 1 2017
 * @description : Test Data for test classes
**********************************************/
public class ClsTestDataBuilder {
    
   public static Id pbId = Test.getStandardPricebookID();
    
    public  static Account testPrescriberAccount(){
            system.debug('**************************************Test testPrescriberAccount was called' );
            Account testPrescriberAccount = new Account();
            testPrescriberAccount.FirstName = 'Prescriberfirstname';
            testPrescriberAccount.LastName = 'Prescriberlastname';
            testPrescriberAccount.Prescriber_Id__c = '12345';
            testPrescriberAccount.PersonEmail = 'Prescriber@testmail.com';
            testPrescriberAccount.Phone = '123456789';
            testPrescriberAccount.RecordtypeID = Schema.SObjectType.account.getRecordTypeInfosByName().get('DE Prescriber').getRecordTypeId();
            testPrescriberAccount.BillingStreet = 'no St';
            testPrescriberAccount.BillingCity = 'XYZ';
        	testPrescriberAccount.BillingStateCode = 'BB';
            testPrescriberAccount.BillingPostalCode = '95445';
         	testPrescriberAccount.BillingCountryCode='DE';
            testPrescriberAccount.BillingCountry='Germany';
            return testPrescriberAccount;
        }
    
    public  static Account testMedFacAccount(){
            system.debug('**************************************Test testMedFacAccount was called' );
            Account testMedFacAccount = new Account();
            testMedFacAccount.Name = 'MedFacfirstname';
            testMedFacAccount.Phone = '123456789';
            testMedFacAccount.RecordtypeID = Schema.SObjectType.account.getRecordTypeInfosByName().get('DE Medical Facility').getRecordTypeId();
            testMedFacAccount.BillingStreet = 'no St';
            testMedFacAccount.BillingCity = 'XYZ';
            testMedFacAccount.BillingState = 'Bremen';
            testMedFacAccount.BillingPostalCode = '95445';
            testMedFacAccount.BillingCountry='Germany';
            testMedFacAccount.ShippingStreet = 'no St';
            testMedFacAccount.ShippingCity = 'XYZ';
            testMedFacAccount.ShippingState = 'Bremen';
            testMedFacAccount.ShippingPostalCode = '95445';
            testMedFacAccount.ShippingCountry='Germany';
            testMedFacAccount.BillingCountry='Germany';
            return testMedFacAccount;
        }
        
     public  static Account testPayorAccount(){
            system.debug('**************************************Test testPayorAccount was called' );
            Account testPayorAccount = new Account();
            testPayorAccount.Name = 'Payorfirstname';
            testPayorAccount.Phone = '123456789';
        	testPayorAccount.Price_Book__c = pbId;
            testPayorAccount.Insurance_Company_Identification_Number__c = '123456789';
            testPayorAccount.RecordtypeID = Schema.SObjectType.account.getRecordTypeInfosByName().get('DE Payor').getRecordTypeId();
            testPayorAccount.BillingStreet = 'no St';
            testPayorAccount.BillingCity = 'XYZ';
            testPayorAccount.BillingState = 'Bremen';
            testPayorAccount.BillingPostalCode = '95445';
            testPayorAccount.BillingCountry='Germany';
            testPayorAccount.ShippingStreet = 'no St';
            testPayorAccount.ShippingCity = 'XYZ';
            testPayorAccount.ShippingState = 'Bremen';
            testPayorAccount.ShippingPostalCode = '95445';
            testPayorAccount.ShippingCountry='Germany';
            testPayorAccount.BillingCountry='Germany';
            return testPayorAccount;
        }
        // TestAccount will be a consumer account
     public  static Account testAccount(){  
        system.debug('**************************************Test account was called' );
         Account testAccount = new Account();
        testAccount.FirstName = 'Testfirstname';
        testAccount.LastName = 'Testlastname';
        testAccount.Price_Book__c = pbId;
        testAccount.PersonEmail = 'Test@testmail.com';
        testAccount.Phone = '123456789';
        testAccount.RecordtypeID = Schema.SObjectType.account.getRecordTypeInfosByName().get('DE Consumer').getRecordTypeId();
        testAccount.BillingStreet = 'no St';
        testAccount.BillingCity = 'XYZ';
        testAccount.BillingState = 'Bremen';
        testAccount.BillingPostalCode = '95445';
        testAccount.BillingCountry='Germany';
        testAccount.ShippingStreet = 'no St';
        testAccount.ShippingCity = 'XYZ';
        testAccount.ShippingState = 'Bremen';
        testAccount.ShippingPostalCode = '95445';
        testAccount.ShippingCountry='Germany';
        testAccount.BillingCountry='Germany';
        return testAccount;
    }
    
     public static List<Account> getAccountList(Integer recLimit, Id recId){
        List<Account> accList = new List<Account>();
        for(Integer i = 0; i < recLimit; i++){
            Account acc = new Account();
            acc.Name = 'Test Account Name' + i;
            acc.RecordTypeId = recId;
            accList.add(acc);
        }
        return accList;
    }
    public static List<Benefit__c> getBenefits(Id consumerId, Id payorId, Integer recLimit, String hierarchy){  // , Id recId
        List<Benefit__c> bnfList = new List<Benefit__c>();
        for(Integer i = 0; i < recLimit; i++){
            Benefit__c bnf = new Benefit__c();
                bnf.Account__c = consumerId;
                bnf.Payor__c = payorId;
                bnf.Benefit_Hierarchy__c = hierarchy;
            	bnf.EGEKO_Confirmation_Number__c = '123';
            	bnf.Member_Id__c = '1234567890';
           		bnfList.add(bnf);
        }   
        return bnfList;
    }
    public static List<Opportunity> getOpportunityList(Integer recLimit, Id acc, Id payor, ID Prescriber, ID Medical_Facility, ID Benefit){
        List<Opportunity> oppList = new List<Opportunity>();
        for(Integer i = 0; i < recLimit; i++){
           		Opportunity opp = new Opportunity();
                opp.Name = 'Test Opportunity Name' + i;
                opp.AccountId = acc;
                opp.StageName = 'New Opportunity';
                opp.CloseDate = date.today();
                opp.Type = 'NEW SYSTEM';
                opp.Payor__c = payor;
            	opp.Medical_Facility__c = Medical_Facility;
            	opp.Prescriber__c = Prescriber;
            	opp.Pricebook2Id = pbId;      
                opp.Benefit__c = Benefit;
                oppList.add(opp);
        }
        return oppList;
    }
    public  static ContentVersion testContentVersion(){
        string before = 'Testing base 64 encode';            
         Blob beforeblob = Blob.valueOf(before);
         ContentVersion cv = new ContentVersion();
         cv.title = 'test content trigger';      
         cv.PathOnClient ='test';           
         cv.VersionData =beforeblob;          
         return cv; 
    }
}