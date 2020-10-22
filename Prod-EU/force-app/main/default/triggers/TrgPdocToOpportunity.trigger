trigger TrgPdocToOpportunity on PDoc_To_Opportunity__c (after insert) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            System.debug('***after Insert TrgPdocToOppTrigger trigger***');
            ClsPdocHandler.afterPdocOpportunityInsert(trigger.new);
        }
    }
}