public class ClsJobMarkCardsNonPrimary {
    public ClsJobMarkCardsNonPrimary(List<Finance_Detail__c> lstFDUpdToPrimary) {
        system.debug('***ENTERED ClsJobMarkCardsNonPrimary ****');
        List<Finance_Detail__c> lstFDUpdToNonPrimary= new List<Finance_Detail__c>();
        for(Finance_Detail__c redFD : lstFDUpdToPrimary){
            for(Finance_Detail__c fd : [Select Id, Primary__C from Finance_Detail__c where Id !=:redFD.Id AND Account__c=:redFD.Account__c AND Primary__c=true]){
                system.debug('***ID TO SET NON PRIMARY IS ' + fd.Id  + ' ****');
                fd.Primary__c=false;
                lstFDUpdToNonPrimary.Add(fd);                
            }
        } 
        if(lstFDUpdToNonPrimary.size()>0){
            update lstFDUpdToNonPrimary;  
            system.debug('***UPDATE COMPLETED ****');
        }
      
    }
}