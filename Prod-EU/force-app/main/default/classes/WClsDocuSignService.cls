/*************************************************************************************************
Apex Class Name : WClsDocuSignService
Version : 1.1
Created Date :  Feb 25, 2020
Function :  Rest servcie for sendign docusing related services
---------------------------------------------------------------------------------------------------------------------------------
* Developer  P Saini                     Feb 25, 2020                           	
*************************************************************************************************/
@RestResource(urlMapping='/DocuSignSvc/*')
global with sharing class WClsDocuSignService {
	/*
     * @Description: Method gets email template subject an dbody from custom metadata settigns and using Docusign classes, sends document to customer. 
     * @param: account id, recepient email, template name , country code.
     * @return: ClsDSResWrapper
     */
    @HttpGet
    global static ClsDSResWrapper getSendDocuSignEmail() {
        ClsDSResWrapper cls= new ClsDSResWrapper();
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = Integer.valueOf(System.Label.StatusCode_Error);
		cls.result = System.Label.Result_False;
        
        String AccountId = req.params.get(ClsDCConstantVariable.PRM_ACCOUNT_ID);
        String RecepientEmail = req.params.get(ClsDCConstantVariable.PRM_Email);
        String TemplateName = req.params.get(ClsDCConstantVariable.PRM_TMP_NAME);
        String CountryCode = req.params.get(ClsDCConstantVariable.PRM_COUNTRY_CODE);
        Account acc= new Account();
        System.debug('**** TPS:EH 1.1 AccountId=' + AccountId + '  emailAddr=' + RecepientEmail);
        
        //if request does not contain email address or not a valid email address
        if(String.isEmpty(AccountId)){ 
            cls.message = 'Invalid Account Id';
            return cls; 
        } else {
        	List<Account> lstAcc= new List<Account>([Select Id, Name from Account Where Id=:AccountId Limit 1]);
            if(!lstAcc.isEmpty()){
                acc=lstAcc[0];
            }else{
            	cls.message = 'Could not find an account with ID: ' + AccountId;
                return cls;
            }
        }
        
        //if request does not contain email address or not a valid email address
        if(String.isEmpty(RecepientEmail) || !ClsDEWebStoreServiceHelper.validateEmailAddress(RecepientEmail)){ 
            cls.message = System.Label.Invalid_Email_Address;
            return cls; 
        }
        //if request does not contain email address or not a valid email address
        if(String.isEmpty(TemplateName)){ 
            cls.message = System.Label.DS_Svc_Invalid_Template_Name;           
            return cls; 
        }
        //if request does not contain email address or not a valid email address
        if(String.isEmpty(CountryCode)){ 
            cls.message = System.Label.DS_Svc_Invalid_country_code;
            return cls; 
        }
        string accRT=CountryCode + '_Consumer';
        List<DocuSign_Templates__mdt> lstTmp= new List<DocuSign_Templates__mdt>([Select Template_Id__c, Template_Name__c, Email_Subject__c, Email_Message__c 
            From DocuSign_Templates__mdt Where Object__c='Account' AND Record_Type__c=:accRT AND Active__c=True AND DeveloperName=:TemplateName Limit 1]);
        if(!lstTmp.isEmpty()){
        	DocuSign_Templates__mdt t =lstTmp[0];
            string entityId=AccountId;
            string templateId=t.Template_Id__c;
            string recipientName=acc.Name;
            string recpEmail=RecepientEmail;
            string emailSubject=t.Email_Subject__c;
            string emailMessage=t.Email_Message__c;
            string recepientId=AccountId;
            
            SendDS(entityId, templateId, recipientName, recpEmail, emailSubject, emailMessage, entityId);
            res.statusCode = Integer.valueOf(System.Label.StatusCode_OK);
            cls.message = System.Label.DS_Svc_Document_sent;  cls.result=System.Label.StatusCode_OK;
            
        } else {
            string msg=System.Label.DS_Svc_Template_Not_Found.replace('[CountryCode]', CountryCode).replace('[TemplateName]', TemplateName);
        	cls.message = msg;
            return cls;     
        }
        return cls;
    }
    
    @HttpPost
    global static ClsDSResWrapper postSendDocuSignEmail(string AccountId, string RecepientEmail, string TemplateName, string CountryCode) {
        ClsDSResWrapper cls= new ClsDSResWrapper();
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = Integer.valueOf(System.Label.StatusCode_Error);
		cls.result = System.Label.Result_False;
        
        Account acc= new Account();
        System.debug('**** TPS:EH 1.1 AccountId=' + AccountId + '  emailAddr=' + RecepientEmail);
        
        //if request does not contain email address or not a valid email address
        if(String.isEmpty(AccountId)){ 
            cls.message = 'Invalid Account Id';
            return cls; 
        } else {
        	List<Account> lstAcc= new List<Account>([Select Id, Name from Account Where Id=:AccountId Limit 1]);
            if(!lstAcc.isEmpty()){
                acc=lstAcc[0];
            }else{
            	cls.message = 'Could not find an account with ID: ' + AccountId;
                return cls;
            }
        }
        
        //if request does not contain email address or not a valid email address
        if(String.isEmpty(RecepientEmail) || !ClsDEWebStoreServiceHelper.validateEmailAddress(RecepientEmail)){ 
            cls.message = System.Label.Invalid_Email_Address;
            return cls; 
        }
        //if request does not contain email address or not a valid email address
        if(String.isEmpty(TemplateName)){ 
            cls.message = System.Label.DS_Svc_Invalid_Template_Name;           
            return cls; 
        }
        //if request does not contain email address or not a valid email address
        if(String.isEmpty(CountryCode)){ 
            cls.message = System.Label.DS_Svc_Invalid_country_code;
            return cls; 
        }
        string accRT=CountryCode + '_Consumer';
        List<DocuSign_Templates__mdt> lstTmp= new List<DocuSign_Templates__mdt>([Select Template_Id__c, Template_Name__c, Email_Subject__c, Email_Message__c 
            From DocuSign_Templates__mdt Where Object__c='Account' AND Record_Type__c=:accRT AND Active__c=True AND DeveloperName=:TemplateName Limit 1]);
        if(!lstTmp.isEmpty()){
        	DocuSign_Templates__mdt t =lstTmp[0];
            string entityId=AccountId;
            string templateId=t.Template_Id__c;
            string recipientName=acc.Name;
            string recpEmail=RecepientEmail;
            string emailSubject=t.Email_Subject__c + ' for ' + acc.Name;
            string emailMessage=t.Email_Message__c;
            string recepientId=AccountId;
            
            SendDS(entityId, templateId, recipientName, recpEmail, emailSubject, emailMessage, entityId);
            res.statusCode = Integer.valueOf(System.Label.StatusCode_OK);
            cls.message = System.Label.DS_Svc_Document_sent;  cls.result=System.Label.StatusCode_OK;
            
        } else {
        	string msg=System.Label.DS_Svc_Template_Not_Found.replace('[CountryCode]', CountryCode).replace('[TemplateName]', TemplateName);
        	cls.message = msg;   
        }
        return cls;
    }
    
  public static void SendDS(Id entityId, string templateId, string recipientName, string recepientEmail, string emailSubject, string emailMessage, string recepientId){
    
    dfsle.Recipient myRecipient = dfsle.Recipient.fromSource(recipientName,recepientEmail, null, 'Signer 1', new dfsle.Entity(recepientId));
    dfsle.UUID myTemplateId = dfsle.UUID.parse(templateId);
    dfsle.Document myDocument =dfsle.Document.fromTemplate(myTemplateId, 'myTemplate');
    dfsle.Entity myEntity = new dfsle.Entity(entityId);
    dfsle.Envelope myEnvelope = new dfsle.Envelope(
                               null,
                               null,
                               null,
                               null,
                               new List<dfsle.Document> { myDocument },
                               null,
                               null,
                               null,
                               emailSubject,
                               emailMessage,
                               myEntity,
                               null);     
    myEnvelope = myEnvelope.withRecipients(new List<dfsle.Recipient> { myRecipient });
    
    if (!Test.isRunningTest()) myEnvelope = dfsle.EnvelopeService.sendEnvelope(myEnvelope, true);
    //myEnvelope = dfsle.EnvelopeService.sendEnvelope(myEnvelope, true); 
    System.Debug('*** TOS:EH 1.1 Sent' + myEnvelope);
  }  
}