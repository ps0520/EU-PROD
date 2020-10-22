public class CtrlCanadianPayorMatrix {
	@AuraEnabled
    public static string getAccountId(string recid){
       string accid=null;
        // Id caPayor = [Select ID from RecordType where SObjecttype = 'Account' AND isActive = true AND DeveloperName = 'CA_Opportunity'].Id;
   		opportunity oOpp= [select id, Benefit__r.Payor__c from opportunity
         where  id =:recid Limit 1];
       if(oOpp != null && oOpp.Benefit__r.Payor__c != null ){
           accid=oOpp.Benefit__r.Payor__c;
       }
       return accid;
    }
    
    @AuraEnabled
    public static Account getReqDocs(string recid){
    	return [Select CA_Docs_Required__c, CA_Coverage_Details__c, CA_Determination_Response_Sent_To__c, CA_Response_Communication_Method__c, Name, Parent.Name  from Account where id = :recId Limit 1];
        //return reqDocs;
    }
}