public class CtrlContentMetadataInformation {
    @AuraEnabled
    //Method will retrieve the contentmetadata for the documents attached to a particular salesforce record
    public static List<Object> getContentMetadata  (String recordId) {
        //Find if the recordId is Opportunity or Account
        String oppAccntId;
        List<Object> accountList = new List<Object>();
        //If objectName is Opportunity then get the accountId corresponding to the Opp
        if(String.valueOf(recordId).substring(0,3) == '006'){
            List<Opportunity> oppList = new List<Opportunity>([SELECT Id, AccountId FROM Opportunity WHERE Id = : recordId]);
            if(!oppList.isEmpty()) oppAccntId = oppList[0].AccountId;
        }
 
        //Get the list of Content Metadata Types if the object referred to is only Account
        if(oppAccntId == null){
            accountList = [Select Id, Name, Content_Document_Id__c, Linked_Objects__c, Document_Type__c, Owned_By_User__c, Document_Created_By_User__c, Document_Created_Date__c, Content_Size__c from Content_Metadata__c Where Id = :recordId OR Account__c = :recordId OR Opportunity__c = :recordId OR Order__c = :recordId OR Opportunity_Account__c = :recordId OR Order_Account__c = :recordId Order by Document_Created_Date__c desc];
        }else //Get the list of Content Metadata Types if the object referred to Opportunity. In this case get both documents attached to Account and Opportunity object
        {
            accountList = [Select Id, Name, Content_Document_Id__c, Linked_Objects__c, Document_Type__c, Owned_By_User__c, Document_Created_By_User__c, Document_Created_Date__c, Content_Size__c from Content_Metadata__c Where Id = :recordId OR Account__c = :recordId OR Opportunity__c = :recordId OR Order__c = :recordId OR Opportunity_Account__c = :recordId OR Order_Account__c = :recordId OR Id = :oppAccntId OR Account__c = :oppAccntId OR Opportunity__c = :oppAccntId OR Order__c = :oppAccntId OR Opportunity_Account__c = :oppAccntId OR Order_Account__c = :oppAccntId Order by Document_Created_Date__c desc];
        }
        return accountList;
    }
}