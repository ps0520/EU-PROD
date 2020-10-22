/*******************************************************************************************
@Author        : Pravin jagadale
@Date Created  : 07/03/2020
@Description   : Test class to test the scenarios involved in Document Tracker object
*********************************************************************************************/
@isTest
public class ClsDocumentTrackerCtrl_Test { 

    @testSetup static void setup() {
        Id recordTypeIdCA = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Consumer').getRecordTypeId();
        Id recordTypeIdCAPayor = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Payor').getRecordTypeId();
        
        Account CAacc = new Account();
        CAacc.CurrencyIsoCode = 'CAD';
        CAacc.RecordTypeId = recordTypeIdCA;
        CAacc.FirstName='TestConsumerFirstName';
        CAacc.LastName='TestConsumerLastName';
        CAacc.BillingStreet = 'Grüner Weg';
        CAacc.BillingCity = 'Friedberg';
        CAacc.BillingPostalCode = 'V7J 3H5';
        CAacc.BillingCountryCode = 'CA';
        CAacc.BillingStateCode = 'AB'; 
        CAacc.PersonEmail = 'Tesdt@gmail.com';
        CAacc.PersonHasOptedOutOfEmail = false;
        insert CAacc; 
        
        // Insert Payor
        Account accPayor = new Account(Name='Payor Account',CA_Docs_Required__c='PIAF', RecordTypeId = recordTypeIdCAPayor, BillingStreet = '1121 Main St.', BillingCity='Toronto',  BillingState= 'Ontario', BillingPostalCode='M4G 3L2',BillingStateCode = 'ON', BillingCountryCode='CA' );
        insert accPayor;
        
        Id oppRecTypeCA = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CA_Opportunity').getRecordTypeId();

        Opportunity newOppCA = new Opportunity();
        newOppCA.RecordTypeId = oppRecTypeCA;
        newOppCA.Name = 'DocTracker';
        newOppCA.CurrencyIsoCode = 'CAD';
        newOppCA.AccountId = CAacc.Id;
        newOppCA.Type = 'New';
        newOppCA.Contact_Letter_Sent__c = true;
        newOppCA.Contact_Doc_Received__c = true;
        newOppCA.Insurance_Doc_Received__c = true;
        newOppCA.Hard_Copy_Out__c = true;
        newOppCA.Hard_Copy_In__c = true;
        newOppCA.Training_Letter_Sent__c = true;
        newOppCA.Training_Letter_Sent_Date__c = Date.Today();
        newOppCA.StageName = 'New Opportunity';
        newOppCA.Training_Date__c = Date.today()+3;
        newOppCA.Doc_Collection_Status__c = 'Docs On File - Pending' ;        
        newOppCA.Email_Stage__c = null ; 
        newOppCA.DexTracker_Email__c = 'Yes';
        newOppCA.Consumer_Email__c = 'Tesdt@gmail.com';     
        newOppCA.CloseDate = Date.Today().addDays(30);
        newOppCA.Payor__c = accPayor.Id;
        insert newOppCA;
        
    }
    @isTest
    private static void TestDocumentTracker(){ 
    	
		//Get the Opportunity
		Opportunity opp = [Select id,name,Payor__c,AccountId from Opportunity where name='DocTracker'];   
         
        // Patient Document Insert 
        Patient_Document__c pdc = new Patient_Document__c();
        pdc.Doc_Type__c = 'PIAF';
        pdc.Status__c = 'Sent';
        pdc.Collect_From__c ='';
        pdc.Account__c = opp.AccountId;
        pdc.Sent_Date__c = null;
        pdc.Received_Date__c = null;
         //ClsDocumentTrackerCtrl.savePatientDocs(pdc, opp.id);
        insert pdc;
        
         // Patient Document Insert 
        Patient_Document__c pdc2 = new Patient_Document__c();
        pdc2.Doc_Type__c = 'PIAF';
        pdc2.Status__c = 'Sent';
        pdc2.Collect_From__c ='';
        pdc2.Account__c = opp.AccountId;
        pdc2.Sent_Date__c = null;
        pdc2.Received_Date__c = null;
         //ClsDocumentTrackerCtrl.savePatientDocs(pdc, opp.id);
        insert pdc2;
        
       
        
        PDoc_To_Opportunity__c pd = new PDoc_To_Opportunity__c(); 
        pd.Opportunity__c = opp.Id;
        pd.Patient_Document__c = pdc.Id;
        insert pd;
        
        PDoc_To_Opportunity__c pd2 = new PDoc_To_Opportunity__c(); 
        pd2.Opportunity__c = opp.Id;
        pd2.Patient_Document__c = pdc2.Id;
        insert pd2;
        
        ClsDocumentTrackerCtrl.fetchAccId(opp.id);
        ClsDocumentTrackerCtrl.fetchRequiredDoc(opp.id);
        ClsDocumentTrackerCtrl.fetchPatientRec(pdc.Id);
        ClsDocumentTrackerCtrl.getCLFPicklist();
        ClsDocumentTrackerCtrl.getDocStatusPicklist();
        ClsDocumentTrackerCtrl.getDocTypePicklist();
        ClsDocumentTrackerCtrl.updatePatientDocs(pdc,pdc.Id,opp.Id);
        ClsDocumentTrackerCtrl.deletePdocToOpppRec(pdc.Id, opp.Id);
        ClsDocumentTrackerCtrl.opportunityStageCheck(opp.Id);
    }
     @isTest
    private static void TestDocumentTrackerInsert(){ 
    	
		//Get the Opportunity
		Opportunity opp = [Select id,name,Payor__c from Opportunity where name='DocTracker'];   
         
        // Patient Document Insert 
        Patient_Document__c pdc = new Patient_Document__c();
        pdc.Doc_Type__c = 'PIAF';
        pdc.Status__c = 'Sent';
        pdc.Collect_From__c ='';
        pdc.Account__c = opp.Payor__c;
        pdc.Sent_Date__c = null;
        pdc.Received_Date__c = null;
       ClsDocumentTrackerCtrl.savePatientDocs(pdc, opp.id);
       
    }
    
     @isTest
    private static void TestDocumentTrackerException(){ 
    	
		//Get the Opportunity
		Opportunity opp = [Select id,name,Payor__c from Opportunity where name='DocTracker'];   
         
        // Patient Document Insert 
        Patient_Document__c pdc = new Patient_Document__c();
        pdc.Doc_Type__c = 'PIAF';
        pdc.Status__c = 'Sent';
        pdc.Collect_From__c ='';
        pdc.Account__c = opp.Payor__c;
        pdc.Sent_Date__c = null;
        pdc.Received_Date__c = null;
         
        insert pdc;
                
        PDoc_To_Opportunity__c pd = new PDoc_To_Opportunity__c();
        pd.Opportunity__c = opp.Id;
        pd.Patient_Document__c = pdc.Id;
        insert pd;
        
        ClsDocumentTrackerCtrl.updatePatientDocs(pdc,pdc.Id,opp.Id);
        ClsDocumentTrackerCtrl.savePatientDocs(pdc,opp.id);
    }
    
    	
}