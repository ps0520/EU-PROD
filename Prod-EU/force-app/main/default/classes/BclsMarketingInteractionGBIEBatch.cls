global class BclsMarketingInteractionGBIEBatch implements database.Batchable<SObject>  {
 global Database.QueryLocator start(Database.BatchableContext bc){
          
     Date sixtyDate= date.today().adddays(60);
     Date todayDate= date.today();
       String SSIPQuery = 'SELECT Id, Account__c, Account__r.Id, Renewal_Date__c, ' + 
            'Product__c, Product__r.Name, Account__r.RecordType.DeveloperName ' + 
            'FROM SSIP_Rule__c'
            +' WHERE Status__c=\'Active\' AND ((Account__r.RecordType.DeveloperName =\'GB_Consumer\' OR Account__r.RecordType.DeveloperName =\'IE_Consumer\')' +
            'AND (Product__r.Name =\'MTRNTG611MOS\' OR Product__r.Name =\'MTRNTG612MOS\') AND (Renewal_Date__c<:sixtyDate AND Renewal_Date__c>:todayDate))';
     
     return Database.getQueryLocator(SSIPQuery);
 }
     global void execute(Database.BatchableContext bc, List<SObject> scope){
         Date sixDate= date.today();
         if(runningInASandbox()){
             sixdate=sixdate.addDays(-2);
         }
         else{
             sixdate=sixdate.addmonths(-6);
         }
         
         List<id> validDateId=new list<id>();
         map<id, SSIP_Rule__c> idToSSIP= new map<id,SSIP_Rule__c>();
         
         for(SSIP_Rule__c a : (List<SSIP_Rule__c>)scope){
             if(string.isNotBlank(a.Renewal_Date__c.format())){              
                     validDateId.add(a.Account__r.Id);
                     idToSSIP.put(a.Account__r.Id, a);
             }
         }
         for(marketing_interaction__c mi: [SELECT id, Account__c, CreatedDate FROM marketing_interaction__c WHERE account__c in :validDateId AND 
                                           Communication_Type__c='UKIE - Subscription Renewal - G6' ]){
             if(mi.CreatedDate>sixDate){
                 if(idToSSIP.containskey(mi.account__c)){
                     idToSSIP.remove(mi.account__c);
                 }
             }
         }
         List<marketing_interaction__c> newMI = new list<marketing_interaction__c>();
         for(SSIP_Rule__c a :idToSSIP.values()){
             marketing_interaction__c mi = new marketing_interaction__c();
             mi.Account__c=a.Account__r.Id;
             mi.Communication_Type__c='UKIE - Subscription Renewal - G6';
             mi.Source_Record_Id__c=a.id;
             mi.Related_Information__c=a.Renewal_Date__c.format();
             if(a.Account__r.RecordType.DeveloperName =='GB_Consumer'){
                 mi.Country__c='United Kingdom';
             }else{
                 mi.Country__c='Ireland';
             }
             newMI.add(mi);
         }
        insert newMI; 
     }
    public static Boolean runningInASandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
    
     global void finish(Database.BatchableContext bc){
     }
}