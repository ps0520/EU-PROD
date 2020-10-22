/* Function: When VAT exempt document is completed by a customer, sets field Account.Tax Exempt to true.
*/
trigger DSStatusTrigger on dfsle__EnvelopeStatus__c (after Update) {
     if(trigger.isAfter && trigger.isUpdate){
         System.debug('***DSS--trigger.new'+trigger.new);
         List<dfsle__EnvelopeStatus__c>  lstenvelopStatus = new List<dfsle__EnvelopeStatus__c>();
         List<Account> lstAccUpd= new List<Account>();
         for(dfsle__EnvelopeStatus__c newStatus: trigger.new){
             dfsle__EnvelopeStatus__c oldStatus=trigger.oldMap.get(newStatus.Id);
             if(newStatus.dfsle__Status__c != oldStatus.dfsle__Status__c && newStatus.dfsle__Status__c=='Completed'){
                
                  lstenvelopStatus.add(newStatus);
                 if(newStatus.dfsle__SourceId__c != null){
                     if(newStatus.dfsle__EmailSubject__c.contains('VAT') && newStatus.dfsle__EmailSubject__c.contains('Exemption')){
                         if(newStatus.dfsle__SourceId__c.startsWith('001')){
                         	Account a = new Account(Id=newStatus.dfsle__SourceId__c, Tax_Exempt__c=true); 
                         	lstAccUpd.Add(a);    
                         }  
                     }
                 }
             }
         }
         
         if(!lstAccUpd.isEmpty()){
             Database.Update(lstAccUpd);
         }
         if(lstenvelopStatus.size()>0){
              System.debug('***DSS--ClsDSStatusTriggerHandler Called');
            ClsDSStatusTriggerHandler.onafterUpdate(lstenvelopStatus);
         }
     }
}