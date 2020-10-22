/****************************************************************************************************************
@Author        : Anuj Patel
@Date Created    : 05/19/2017
@Description    : Test Class covering methods from ContentDocumentLinkTrigger 
****************************************************************************************************************/
@isTest
public class ClsTestContentDocumentLinkTriggerHandler {

    @isTest Static void testInsertCDL(){
        test.startTest();
        List<ContentDocumentLink> AddCDL = new List<ContentDocumentLink>();
        list <Opportunity> oppList = new list <Opportunity>();
        
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
        /** This will create an Benefit Records  **/ 
        List<Benefit__c> bnf = new List<Benefit__c>();
        bnf =  ClsTestDataBuilder.getBenefits(AccObj.Id, Payor.Id, 1, 'Primary');
        insert bnf;
        bnf[0].account__c = AccObj.Id;
        AccObj.Benefit__c = bnf[0].id; 
        
        ContentVersion CvObj = ClsTestDataBuilder.testContentVersion();
		insert CvObj;
		CvObj = [SELECT ContentDocumentId FROM ContentVersion where Id = :CvObj.Id]; 
        ContentDocumentLink newFileShare = new ContentDocumentLink();
		newFileShare.ShareType = 'V' ;
		newFileShare.Visibility = 'AllUsers' ; 
        newFileShare.contentdocumentid = CvObj.contentdocumentid;
        newFileShare.LinkedEntityId = AccObj.Id;
		system.debug('Linked entity id is ' + newFileShare.LinkedEntityId);
        ClsCheckRecursive.run = true ;
        insert newFileShare;
      //  AddCDL.add(newFileShare);  // account inserted
         
        
        /** This will create an Opportunity and add a document on Opportunity **/    
        oppList = ClsTestDataBuilder.getOpportunityList(2, AccObj.Id, Payor.Id,Prescriber.Id, MedFac.Id, bnf[0].Id ); // Integer recLimit, Id acc, Id payor, ID Prescriber
        insert oppList;
	    ContentVersion CvObj2 = ClsTestDataBuilder.testContentVersion();
		insert CvObj2;
		CvObj2 = [SELECT ContentDocumentId FROM ContentVersion where Id = :CvObj2.Id]; 
        ContentDocumentLink newFileShare2 = new ContentDocumentLink();
		newFileShare2.ShareType = 'V' ;
		newFileShare2.Visibility = 'AllUsers' ; 
        newFileShare2.contentdocumentid = CvObj2.contentdocumentid;
        newFileShare2.LinkedEntityId = OppList[0].Id;
        AddCDL.add(newFileShare2);
        
		ContentVersion CvObj3 = ClsTestDataBuilder.testContentVersion();
		insert CvObj3;
		CvObj3 = [SELECT ContentDocumentId FROM ContentVersion where Id = :CvObj3.Id];
        ContentDocumentLink newFileShare3 = new ContentDocumentLink();
		newFileShare3.ShareType = 'V' ;
		newFileShare3.Visibility = 'AllUsers' ; 
        newFileShare3.contentdocumentid = CvObj3.contentdocumentid;
        newFileShare3.LinkedEntityId = OppList[1].Id;
        AddCDL.add(newFileShare3);
        ClsCheckRecursive.run = true ;
        insert AddCDL;
        
      /** 	List<ContentDocumentLink> newCDLs = [Select ID, contentdocumentid from ContentDocumentLink where ID In :AddCDL ];
        for(ContentDocumentLink c: newCDLs){
            System.assertEquals('V', c.ShareType);
        } **/
        for(ContentDocumentLink c: AddCDL){
        System.assertEquals('V', c.ShareType);
        System.assertEquals('AllUsers', c.Visibility);
        
        }
        List<Content_Metadata__c> ConMet = [Select Id, Name, Content_Document_Id__c, Linked_Objects__c, Document_Type__c, Owned_By_User__c, Document_Created_By_User__c, Document_Created_Date__c, Content_Size__c from Content_Metadata__c];
        ConMet[0].File_Type__c = 'SNOTE' ;
        update ConMet ;
        List<ContentDocument> ConDoc = [Select Id from ContentDocument];        
        delete ConDoc ;
        List<ContentDocument> ConDo = [Select Id from ContentDocument];        
        delete ConDo ;
        test.stopTest();
    }
}