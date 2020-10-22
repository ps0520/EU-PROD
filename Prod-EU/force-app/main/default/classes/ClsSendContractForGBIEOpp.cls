global class ClsSendContractForGBIEOpp implements Schedulable {
    global Id oppId;
	global String countryCode;
    public ClsSendContractForGBIEOpp(Id oId, String countryCode){
        this.oppId=oId;
		this.countryCode=countryCode;
    }        
	global void execute(SchedulableContext ctx) {
        if(oppId!=null){
        	SendContractForGBIEOpp(oppId, countryCode);    
        }
    }
    //public static void SendContractForGBIEOpp(List<Id> lstOppId){
   
    public static void SendContractForGBIEOpp(Id oppId, String countryCode){
    	Id recId; recId=oppId; string emailSubject; string emailMessage;
        string templateId; Opportunity opp; string recepientName; string recepientEmail;
		Map<String, DocuSign_Templates__mdt> countryCodeDocuSignMap = new Map<String, DocuSign_Templates__mdt>();
        
        List<Opportunity> lstOpp=[SELECT Id, RecordType.DeveloperName, Name, Account.Name, Account.PersonEmail, Account.Id, Account.Organzation_Email__c, Account.isPersonAccount 
            FROM Opportunity Where Id=:recId AND StageName !='Cancelled'];
        if(!lstOpp.isEmpty()){
        	opp=lstOpp[0];    
        }
        
        if(opp !=null){
            recepientName=opp.Account.Name;
			Boolean isPerson=(boolean)opp.Account.isPersonAccount;
           if(isPerson){
               recepientEmail=(string)opp.Account.PersonEmail;
           } else{
               recepientEmail=(string)opp.Account.Organzation_Email__c;               
           }
		   for(DocuSign_Templates__mdt tmp : [Select Template_Id__c, Template_Name__c, Email_Subject__c, Email_Message__c, Record_Type__c 
          		From DocuSign_Templates__mdt Where Object__c='Opportunity' AND (Record_Type__c='GB_Opportunity' OR Record_Type__c='IE_Opportunity')  AND Active__c=True Order By Template_Name__c]){
            	if(tmp.Template_Name__c.contains('Subscription') && tmp.Template_Name__c.contains('11')){
					if(tmp.Record_Type__c == 'GB_Opportunity') countryCodeDocuSignMap.put('GB', tmp);
					if(tmp.Record_Type__c == 'IE_Opportunity') countryCodeDocuSignMap.put('IE', tmp);
             	}
        	}
            if(!countryCodeDocuSignMap.isEmpty()){
				DocuSign_Templates__mdt tmp = countryCodeDocuSignMap.get(countryCode);
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
            	CtrlDocuSignTemplateSel.SendDocument_GBIE(recId, templateId, recepientName, recepientEmail, emailSubject, emailMessage, recId);
            }
        } // opp !=null
    }
}