@isTest
public class ClsDocuSignTemplateSelTest {
@isTest 
static void TestDataGB(){ 
	List<RecordType> rtypes = [Select Name, Id From RecordType where sObjectType IN('Account','Opportunity') and isActive=true];        
    Map<String,String> accountRecordTypes = new Map<String,String>();
    for(RecordType rt: rtypes){
    	accountRecordTypes.put(rt.Name,rt.Id);    
    }
    
    Pricebook2 pbGBSub = new Pricebook2();
	pbGBSub.Name = 'UK G6 SUBSCRIPTION 11MOS';
	pbGBSub.IsActive = true;
    pbGBSub.CurrencyIsoCode = 'GBP' ; 
	pbGBSub.IsSubscription__c=true;
    insert pbGBSub;
    
    	String recordTypeIdMed = accountRecordTypes.get('GB Medical Facility');
        Account ATaccMed = new Account();
        ATaccMed.CurrencyIsoCode = 'GBP';
        ATaccMed.RecordTypeId = recordTypeIdMed;
        ATaccMed.name = 'Med';
        ATaccMed.Phone = '1234567891' ;
        ATaccMed.BillingStreet = 'Grüner Weg';
        ATaccMed.BillingCity = 'Friedberg';
        ATaccMed.BillingPostalCode = '1244';
        ATaccMed.BillingCountryCode = 'GB';
      //  CHaccMed.PersonEmail = 'TesdtS@gmail.com';
       // CHaccMed.PersonHasOptedOutOfEmail = false;
        insert ATaccMed; 
    
    	String recordTypeIdCA = accountRecordTypes.get('GB Consumer');
        Account accGB = new Account();
        accGB.CurrencyIsoCode = 'GBP';
        accGB.RecordTypeId = recordTypeIdCA;
        accGB.FirstName='TestConsumerFirstName';
        accGB.LastName='TestConsumerLastName';
        accGB.BillingStreet = 'Grüner Weg';
        accGB.BillingCity = 'Friedberg';
        accGB.BillingPostalCode = '1234';
        accGB.BillingCountryCode = 'GB';
        accGB.PersonEmail = 'TestDexcom@gmail.com';
        accGB.PersonHasOptedOutOfEmail = false;
    	accGB.Medical_Facility__c = ATaccMed.id;
        insert accGB;
    	System.Debug('** TPS:EH 1.1 accGB=' + accGB);
        
   	Id rtOppGB = [Select Id from RecordType Where isActive = true AND DeveloperName = 'GB_Opportunity'].id;
    Opportunity oppGB = new Opportunity();
    oppGB.RecordTypeId = rtOppGB;
    oppGB.Name = 'New Opportunity For Testing';
    oppGB.CurrencyIsoCode = 'GBP';
    oppGB.AccountId = accGB.Id;
    oppGB.Type = 'New';
   // oppGB.Contact_Letter_Sent__c = true;
    //oppGB.Contact_Doc_Received__c = true;
    //oppGB.Insurance_Doc_Received__c = true;
    //oppGB.Hard_Copy_Out__c = true;
    //oppGB.Hard_Copy_In__c = true;
    //oppGB.Training_Letter_Sent__c = true;
    //oppGB.Training_Letter_Sent_Date__c = Date.Today();
    oppGB.StageName = 'New Opportunity';
    //oppGB.Training_Date__c = Date.today()+3;
    //oppGB.Doc_Collection_Status__c = 'Docs On File - Pending' ;        
    oppGB.Email_Stage__c = null ; 
    //oppGB.DexTracker_Email__c = 'Yes';
    oppGB.Consumer_Email__c = 'Tesdt@gmail.com';     
    oppGB.CloseDate = Date.Today().addDays(30);
    oppGB.Pricebook2Id = pbGBSub.Id;
    Test.startTest();
    insert oppGB; System.Debug('** TPS:EH 1.2 oppGB=' + oppGB);
    
    Opportunity oppGB1=[Select Id,Name, RecordType.DeveloperName, Pricebook2.Name, Contract_Request_Date__c from Opportunity Where Id=:oppGB.Id Limit 1];
    System.Debug('** TPS:EH 1.2 oppGB1=' + oppGB1);
    
    CtrlDocuSignTemplateSel.getRecordDataType(accGB.Id);
    CtrlDocuSignTemplateSel.getRecordDataType(oppGB.Id);
    
    string emailSubject; string emailMessage; string templateId; string recepientName; string recepientEmail;
    for(DocuSign_Templates__mdt tmp : [Select Template_Id__c, Template_Name__c, Email_Subject__c, Email_Message__c, Record_Type__c 
        From DocuSign_Templates__mdt Where Object__c='Opportunity' AND (Record_Type__c='GB_Opportunity') AND Active__c=True Order By Template_Name__c]){
    	if(tmp.Template_Name__c.contains('Subscription') && tmp.Template_Name__c.contains('11')){
			templateId = tmp.Template_Id__c; emailSubject=tmp.Email_Subject__c; emailMessage=tmp.Email_Message__c;
        }	
    }
    recepientName='test'; recepientEmail='TestDataGB@dexcom.com';
    if(templateId!=null && recepientName!=null && recepientEmail!=null && emailSubject!=null && emailMessage!=null){    	
        CtrlDocuSignTemplateSel.SendDocument1(oppGB.id, templateId, recepientName, recepientEmail, emailSubject, emailMessage, oppGB.Id);
        CtrlDocuSignTemplateSel.SendDocument_GBIE(oppGB.id, templateId, recepientName, recepientEmail, emailSubject, emailMessage, oppGB.Id);
        dfsle__EnvelopeStatus__c dsStatus= new dfsle__EnvelopeStatus__c(dfsle__EmailSubject__c='Dexcom VAT Exemption - Signature Needed');
        dsStatus.dfsle__Sent__c=Date.Today(); dsStatus.dfsle__SourceId__c=accGB.Id; dsStatus.dfsle__Status__c ='Sent';
        insert dsStatus;
        dsStatus.dfsle__Status__c='Completed';  update dsStatus;
    }
    Test.stopTest();
    
    
}
}