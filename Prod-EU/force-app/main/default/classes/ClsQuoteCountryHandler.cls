/****************************************************************************************************************
@Author        : Kumar Navneet
@Date Created    : 12/6/2019
@Description    : Creating class for handling Country specific things
****************************************************************************************************************/

public class ClsQuoteCountryHandler {
    
    public static void afterInsertUpdateHandler(List<quote> newquoteList , Map<Id, quote> NewquoteMap) {
        system.debug('afterInsertUpdateHandler');
        //Accumulate
        set<Id> OppIDSet = new set<Id>();
        Map<id, quote> DEnewquoteMap = new Map<id, quote>();
        Map<id, quote> CAnewquoteMap = new Map<id, quote>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Id caOpp = [Select ID from RecordType where isActive = true and sobjecttype = 'Opportunity' and DeveloperName = 'CA_Opportunity'].id;
        Id deOpp = [Select ID from RecordType where isActive = true and sobjecttype = 'Opportunity' and DeveloperName = 'DE_Opportunity'].id;        
        
        for(quote qt: NewquoteMap.values()) {
            OppIDSet.add(qt.Opportunityid);
        }          
        for (Opportunity opp : [Select RecordTypeId , id from Opportunity where id in :OppIDSet ]) {
            oppMap.put(opp.Id, opp);
        }      
        // Adding records in Map for specific country
        for(quote quo : newquoteList) {
            if (oppMap.get(quo.Opportunityid).RecordTypeId == caOpp ) CAnewquoteMap.put(quo.id, quo);
            else if (oppMap.get(quo.Opportunityid).RecordTypeId == deOpp ) DEnewquoteMap.put(quo.id, quo);
        }
        
        //Country dispatcher
        if (DEnewquoteMap.size() > 0) { 
             BPClsQuote.UpdateQuoteLineItemNumber(DEnewquoteMap);   
        }
        if (CAnewquoteMap.size() > 0) {
            
        }
    }
   
}