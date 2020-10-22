/********************************************************************************
@ Author: P Saini
@ Date: July, 2019
@ Version: 1.0
@ Description: Controller class for lightning component LtngCompDocuSignTemplateSel
@ Function: DocuSign template selection tool needs to be launched from Opportunity/Account page.
            Tool needs to be dynamic so there is 1 version for both opportunity and account.
            Tool needs to context aware of page from which it is launched. 
            This class dynamically queries opportunity/accoutn fields and prepares a wrapper class for consumption by tool.
            A custom meta data setting named DocuSign_Templates__mdt needs to be set up that stores a list of applicable docusign templates for opportunity/account.
            End user using this tool sees a a drop down list of DocuSign templates that are applicable to that specific record from which this tool is launched.
            This list is driven by a custom setting DocuSign_Templates__mdt.
*******************************************************************************/

public class CtrlDocuSignTemplateSel{
    /* Purpose: Prepares a collection of wrapper class for consumption by lightnign component.
       DocuSign templates need to be set up and template id need to be stored in custom setting [DocuSign_Templates__mdt]
       This function queries object schema for which record id was sent and figues record type id. 
       It then uses object name and record type to query custom meta data settings to find appropriate templates.
       Currently supports Opportunity and Account objects but can be extended to other objects as well.
       Version: 1.0, P Saini, July 2019
    */
    @AuraEnabled
    public static DSTemplateWrapper getRecordDataType(Id recordId){
        DSTemplateWrapper dsCls = new DSTemplateWrapper();
        List<DocuSign_Templates__mdt> lstDT= new List<DocuSign_Templates__mdt>();        
        Schema.DescribeSObjectResult dr = recordId.getSobjectType().getDescribe();
        string objName=dr.getName();  dsCls.sObjectName = objName;
        
        String queryString = 'SELECT Id, RecordType.DeveloperName, Name FROM ' + dr.getName() + ' WHERE Id=\'' + recordId + '\''; 
        if(objName=='Opportunity'){
            queryString = 'SELECT Id, RecordType.DeveloperName, Name, Account.Name, Account.PersonEmail, Account.Id, Account.Organzation_Email__c,  Account.isPersonAccount FROM ' + dr.getName() + ' WHERE Id=\'' + recordId + '\''; 
        } else if(objName=='Account'){
            queryString = 'SELECT Id, RecordType.DeveloperName, Name, PersonEmail, isPersonAccount, Organzation_Email__c FROM Account WHERE Id=\'' + recordId + '\''; 
        } 
              
        sObject[] objDBList = Database.query(queryString);
        string RTId=(string)objDBList[0].get('RecordTypeId');
        dsCls.sObjectRecordName =(string)objDBList[0].get('Name');        
        dsCls.RecepientName=dsCls.sObjectRecordName;
         
        
        if(objName=='Opportunity'){
            
           dsCls.RecepientName=(string)objDBList[0].getSobject('Account').get('Name');           
           dsCls.AccountId=(string)objDBList[0].getSobject('Account').get('Id');
           
           Boolean isPerson=(boolean)objDBList[0].getSobject('Account').get('isPersonAccount');
           if(isPerson){
               dsCls.RecepientEmail=(string)objDBList[0].getSobject('Account').get('PersonEmail');
           } else{
               dsCls.RecepientEmail=(string)objDBList[0].getSobject('Account').get('Organzation_Email__c');
           }
           
        } else if(objName=='Account'){
            if((boolean)objDBList[0].get('isPersonAccount')){
                dsCls.RecepientEmail=(string)objDBList[0].get('PersonEmail');
            } else {
                dsCls.RecepientEmail=(string)objDBList[0].get('Organzation_Email__c');            
            }
            
        }      
        
        string recordType=null; recordType=(string)objDBList[0].getSobject('RecordType').get('DeveloperName');
        if(objName != null && recordType!= null){
            dsCls.lstDSConfig = new List<DocuSign_Templates__mdt>([Select Template_Id__c, Template_Name__c, Email_Subject__c, Email_Message__c From DocuSign_Templates__mdt Where Object__c=:objName 
            AND Record_Type__c=:recordType AND Active__c=True Order By Template_Name__c]);
        }        
        return dsCls;        
    }
    
   /* Purpose: Wrapper class to be consumed by lightning component.       
      Version: 1.0, P Saini, July 2019
  */  
  public class DSTemplateWrapper {
    @AuraEnabled
    public list<DocuSign_Templates__mdt> lstDSConfig {get;set;}    
    @AuraEnabled
    public string sObjectName {get; set;}
    @AuraEnabled    
    public string sObjectRTName {get; set;}
    @AuraEnabled    
    public string sObjectRecordName {get; set;}
    @AuraEnabled    
    public string RecepientName {get; set;}
    @AuraEnabled    
    public string RecepientEmail {get; set;}
    @AuraEnabled    
    public string AccountId {get; set;}
    
    public DSTemplateWrapper(){
        this.lstDSConfig =new  list<DocuSign_Templates__mdt>();   
    }
  }
  
  /* Purpose: Creates a DocuSign envelope with custom email message and template.
     Please refer to DocuSign api documentation for changes and usage of this function.
     EntityId is record id (Account/Opportunity)
     Recepient Id is email address on account record from where tool is launched.       
     This function accepts a Salesforce record Id and recepient email address and prepares a dynamic DocuSign envelope with customized email subject and email message.
     It then sends this envelope to DocuSign servcie which sends it to recepient.  
     Version: 1.0, P Saini, July 2019
  */
  @AuraEnabled  
  public static void SendDocument1(Id entityId, string templateId, string recipientName, string recepientEmail, string emailSubject, string emailMessage, string recepientId){
    
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
  
  @AuraEnabled
  @future (callout=true)
  public static void SendDocument_GBIE(Id entityId, string templateId, string recipientName, string recepientEmail, string emailSubject, string emailMessage, string recepientId){
    List<Opportunity> lstOpp=new List<Opportunity>([Select Id from Opportunity Where Id=:entityId AND Contract_Sent_Date__c = null
                         AND Contract_Request_Date__c != null AND StageName !='Cancelled']);
     if(!lstOpp.isEmpty()){
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
        System.Debug('*** TOS:EH 1.1 Sent' + myEnvelope);   
     }
  }
  /* Purpose: Gets status info on DocuSign envelope that was previously sent.
     Lignthing component will use this status and check if status ='sent'. If so, component will close tool and display success message.
     Version: 1.0, P Saini, July 2019
  */
  @AuraEnabled
  public static List<dfsle.Envelope.Status> GetDocumentStatus(Id entityId){
    List<dfsle.Envelope.Status> myStatus = dfsle.StatusService.getStatus(
    new Set<Id> { entityId }, 1); // Maximum number of records to return.
    System.Debug('*** TOS:EH 2.1 status=' + myStatus);     
    return myStatus; 
  }    

}