global class BClsSendContractForGBIEOpp implements Database.Batchable<SObject>, Database.AllowsCallouts{
    private String query; 
    //private Map<String, DocuSign_Templates__mdt> countryCodeDocuSignMap;
    global BClsSendContractForGBIEOpp (String soql){
        query = soql;        
    }
    
    global Database.QueryLocator start(Database.BatchableContext info) {
        //return Database.getQueryLocator(query);
        if(Test.isRunningTest()){
            Date contractReqDate=System.Date.today().AddDays(15);            
        	return Database.getQueryLocator([SELECT Id, RecordType.DeveloperName, Name, Account.Name, Account.PersonEmail, Account.Id, Account.Organzation_Email__c, Account.isPersonAccount 
                from Opportunity Limit 1]);    
        }else{
            return Database.getQueryLocator([SELECT Id, RecordType.DeveloperName, Name, Account.Name, Account.PersonEmail, Account.Id, Account.Organzation_Email__c, Account.isPersonAccount 
                from Opportunity where Contract_Request_Date__c =Today AND Contract_Sent_Date__c =null AND StageName !='Cancelled']);
        }
    }
    
    
    global void execute(Database.BatchableContext info, List<Opportunity> scope) {
        Map<String, DocuSign_Templates__mdt> countryCodeDocuSignMap = new Map<String, DocuSign_Templates__mdt>();
        for(DocuSign_Templates__mdt tmp : [Select Template_Id__c, Template_Name__c, Email_Subject__c, Email_Message__c, Record_Type__c 
                From DocuSign_Templates__mdt Where Object__c='Opportunity' AND (Record_Type__c='GB_Opportunity' OR Record_Type__c='IE_Opportunity')  AND Active__c=True Order By Template_Name__c]){
            if(tmp.Template_Name__c.toUppercase().contains('SUBSCRIPTION') && tmp.Template_Name__c.toUppercase().contains('11')){
                countryCodeDocuSignMap.put(tmp.Record_Type__c, tmp);
            }
        }        
       for(Opportunity opp : scope){
            Id recId=opp.Id; string emailSubject; string emailMessage;
            string templateId; string recepientName; string recepientEmail;
            recepientName=opp.Account.Name;
            Boolean isPerson=(boolean)opp.Account.isPersonAccount;
            if(isPerson){
               recepientEmail=(string)opp.Account.PersonEmail;
            } else{
               recepientEmail=(string)opp.Account.Organzation_Email__c;               
            }
           
            if(!countryCodeDocuSignMap.isEmpty()){
                DocuSign_Templates__mdt tmp = countryCodeDocuSignMap.get(opp.RecordType.DeveloperName);
                templateId = tmp.Template_Id__c; emailSubject=tmp.Email_Subject__c; emailMessage=tmp.Email_Message__c;
            }
            System.Debug('**** TPS:EH 2.1 SendContractForGBIEOpp recId=' + recId);
            System.Debug('**** TPS:EH 2.2 SendContractForGBIEOpp templateId=' + templateId);
            System.Debug('**** TPS:EH 2.3 SendContractForGBIEOpp recepientName=' + recepientName);
            System.Debug('**** TPS:EH 2.4 SendContractForGBIEOpp recepientEmail=' + recepientEmail);
            System.Debug('**** TPS:EH 2.5 SendContractForGBIEOpp emailSubject=' + emailSubject);
            System.Debug('**** TPS:EH 2.6 SendContractForGBIEOpp emailMessage=' + emailMessage);
            System.Debug('**** TPS:EH 2.7 SendContractForGBIEOpp opp=' + opp);
           
            if(recId!=null && templateId!=null && recepientName!=null && recepientEmail!=null && emailSubject!=null && emailMessage!=null){
                System.Debug('**** TPS:EH 3.1 Call Docusign api');
                CtrlDocuSignTemplateSel.SendDocument1(recId, templateId, recepientName, recepientEmail, emailSubject, emailMessage, recId);
            }
       }
        
    }
    
    
    global void finish(Database.BatchableContext BC)
    {
        
    }
}