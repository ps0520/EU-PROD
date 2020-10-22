global class BclsMarketingInteractionCABatch implements database.Batchable<SObject>  {
 global Database.QueryLocator start(Database.BatchableContext bc){
     Date ninetyDate= date.today().adddays(-90);
         Date onehundredDate= date.today().adddays(-100);
       String accountBaseQuery = 'SELECT Id, PersonEmail, PersonContactID, ' + 
            'G6_Transmitter_Ship_Date__c, G6_Starter_Kit_Ship_Date__c ' + 
            'FROM Account ' + 
            'WHERE RecordType.DeveloperName =\'CA_Consumer\' AND G6_Transmitter_Ship_Date__c<:ninetyDate'+
           ' AND G6_Transmitter_Ship_Date__c>:onehundredDate';
     
     return Database.getQueryLocator(accountBaseQuery);
 }
     global void execute(Database.BatchableContext bc, List<SObject> scope){
         
         List<id> validDateId=new list<id>();
         map<id, account> idToAccount= new map<id,account>();
         
         for(Account a : (List<Account>)scope){
            // if(a.G6_Transmitter_Ship_Date__c<ninetyDate && a.G6_Transmitter_Ship_Date__c>onehundredDate){                 
                 validDateId.add(a.id);
                 idToAccount.put(a.id, a);
             //}
         }
         for(marketing_interaction__c mi: [SELECT id, Account__c FROM marketing_interaction__c WHERE account__c in :validDateId AND Communication_Type__c='CA - Subscription Upsell - G6']){
             if(idToAccount.containskey(mi.account__c)){
                 idToAccount.remove(mi.account__c);
             }
         }
         List<marketing_interaction__c> newMI = new list<marketing_interaction__c>();
         for(Account a :idToAccount.values()){
             marketing_interaction__c mi = new marketing_interaction__c();
             mi.Account__c=a.id;
             mi.Communication_Type__c='CA - Subscription Upsell - G6';
             mi.Source_Record_Id__c=a.id;
             if(a.G6_Transmitter_Ship_Date__c==a.G6_Starter_Kit_Ship_Date__c){
                 mi.Related_Information__c='True';
             }else{
                 mi.Related_Information__c='False';
             }
             mi.Country__c='Canada';
             newMI.add(mi);
         }
        insert newMI; 
     }
    
     global void finish(Database.BatchableContext bc){
     }
}