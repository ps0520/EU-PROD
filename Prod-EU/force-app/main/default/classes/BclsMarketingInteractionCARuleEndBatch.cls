global class BclsMarketingInteractionCARuleEndBatch implements database.Batchable<SObject>  { 
    global Database.QueryLocator start(Database.BatchableContext bc){
        Date CANoRuleEndNxt90Date = date.today().adddays(90); 
        Date CANoRuleRenwlNxt85Date = date.today().adddays(85);
        Date CANoRuleRenwlNxt95Date = date.today().adddays(95);
        String SSIPQuery = 'SELECT Id, Account__c, Account__r.Id, Renewal_Date__c,Rule_End_Date__c, ' ;
        SSIPQuery += ' Product__c, Product__r.Name, Account__r.RecordType.DeveloperName,Price_Book__r.Name ';
        SSIPQuery += ' from SSIP_Rule__c' ;
        SSIPQuery += ' WHERE (Status__c=\'Active\') AND (Account__r.RecordType.DeveloperName =\'CA_Consumer\')';
        //SSIPQuery += ' AND (Product__r.Name =\'MTRNTCAGS-12MOS\')';
        SSIPQuery += ' AND (Product__r.Name =\'MTRNTCAGS-12MOS\') AND (Rule_End_Date__c>=:CANoRuleRenwlNxt85Date AND Rule_End_Date__c<=:CANoRuleRenwlNxt95Date)';
        SSIPQuery += ' AND (Price_Book__r.Name =\'CAN G6 SUBSCRIPTION 12MOS NO Renewal\')';
        
        System.debug('--SSIPQuery--'+SSIPQuery);
        return Database.getQueryLocator(SSIPQuery);
   }
     global void execute(Database.BatchableContext bc, List<SObject> scope){
         
        System.debug('**scope--'+scope.size()); 
        Date sixDate= date.today();
        sixdate=sixdate.addmonths(-6);
        
        List<id> validDateId=new list<id>();
        map<id, SSIP_Rule__c> idToSSIP= new map<id,SSIP_Rule__c>();
        
        for(SSIP_Rule__c a : (List<SSIP_Rule__c>)scope){
            if(string.isNotBlank(a.Rule_End_Date__c.format())){              
                validDateId.add(a.Account__r.Id);
                idToSSIP.put(a.Account__r.Id, a);
            }
        }
        for(marketing_interaction__c mi: [SELECT id, Account__c, CreatedDate FROM marketing_interaction__c WHERE account__c in :validDateId AND 
                                          Communication_Type__c='CA - Subscription Renewal - Signature' ]){
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
            mi.Communication_Type__c='CA - Subscription Renewal - Signature';
            mi.Source_Record_Id__c=a.id;
            mi.Related_Information__c=a.Rule_End_Date__c.format();
            if(a.Account__r.RecordType.DeveloperName =='CA_Consumer'){
                mi.Country__c='Canada';
            }
            newMI.add(mi);
        }
        insert newMI;
        //System.debug('**MI Records To Insert-->'+newMI); 
    }
    global void finish(Database.BatchableContext bc){
        System.debug('BClsMIRuleEndBatch_V1 -- Batch Execution Finished!!!');
    }
}