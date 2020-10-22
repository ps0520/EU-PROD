trigger FinancialDetailUpdatePrimary on Finance_Detail__c (after insert, after update) {
    if(Trigger.isAfter) {
        List<Finance_Detail__c> lstFDUpdToPrimary= new List<Finance_Detail__c>();
        for(Finance_Detail__c fd: Trigger.New){            
            if(fd.Primary__c && (Trigger.isInsert || (Trigger.isUpdate && Trigger.OldMap.get(fd.Id).Primary__c !=fd.Primary__c))){
                lstFDUpdToPrimary.Add(fd);    
            }
        }
        if(!lstFDUpdToPrimary.isEmpty()){
            ClsJobMarkCardsNonPrimary jobUpdateCC = new ClsJobMarkCardsNonPrimary(lstFDUpdToPrimary);                
        }
        
    }
}