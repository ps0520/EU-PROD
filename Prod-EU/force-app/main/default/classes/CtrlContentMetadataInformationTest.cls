@isTest
private class CtrlContentMetadataInformationTest {
    
     @isTest 
    private static void testClsMarketingInteractionHandler(){        
        
        Account Prescriber =  ClsTestDataBuilder.testPrescriberAccount();
        insert Prescriber;
		Account MedFac =  ClsTestDataBuilder.testMedFacAccount();
        insert MedFac;
        Account Payor =  ClsTestDataBuilder.testPayorAccount();
        insert Payor; 
        /** This will create an Account and add a document on Account **/ 
        Account AccObj = ClsTestDataBuilder.testAccount();
        AccObj.Prescriber__c = Prescriber.Id;
        AccObj.Medical_Facility__c = MedFac.Id;
        AccObj.Payor__c = Payor.Id;
        insert AccObj;
        
        Content_Metadata__c ConMet = new Content_Metadata__c();
        ConMet.Name = 'Test' ;
        ConMet.Account__c = AccObj.id;
        insert ConMet;
        
        Test.startTest();     
        CtrlContentMetadataInformation.getContentMetadata(AccObj.id);
        Test.stopTest();
        
        
    }

}