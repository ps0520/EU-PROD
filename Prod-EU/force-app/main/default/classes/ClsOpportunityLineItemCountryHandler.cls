/****************************************************************************************************************
@Author        : Kumar Navneet
@Date Created    : 12/6/2019
@Description    : Creating class for handling Country specific things
****************************************************************************************************************/

public class ClsOpportunityLineItemCountryHandler {
    //Purpose of the following method is to copy the Repeat Quantity and Period if present in the price book Entry
    public static void beforeInsertHandler(List<OpportunityLineItem> newOplineItemList) {
        system.debug('BeforeInsertHandler');
        set<Id> pbeIdSet = new Set<Id>();
        for (OpportunityLineItem oli : newOplineItemList) pbeIdSet.add(oli.PricebookEntryId);
        Map<Id, PriceBookEntry> pbeRepeatMap = new Map<Id, PriceBookEntry>([Select Id, SSIP_Periodic_Order_Quantity__c, SSIP_Next_Order_In_Days__c, First_Repeat_Order_Lead_Days__c from PriceBookEntry where Id in :pbeIdSet ]);
        for (OpportunityLineItem oli : newOplineItemList) {
            oli.Repeat_Quantity__c = pbeRepeatMap.get(oli.PricebookEntryId).SSIP_Periodic_Order_Quantity__c;
            oli.Repeat_after_in_Days__c = pbeRepeatMap.get(oli.PricebookEntryId).SSIP_Next_Order_In_Days__c;
            oli.First_Repeat_Order_Lead_Days__c = pbeRepeatMap.get(oli.PricebookEntryId).First_Repeat_Order_Lead_Days__c;
        } 
    }
            
    public static void afterInsertUpdateHandler(List<OpportunityLineItem> newOplineItemList , Map<Id, OpportunityLineItem> newOplineItemMap, String event) {
        system.debug('AfterInsertHandler');
        //Accumulate
        set<Id> oppIDSet = new set<Id>();
        List<OpportunityLineItem> DEnewOliList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> CAnewOliList = new List<OpportunityLineItem>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Id caOpp = [Select ID from RecordType where isActive = true and sobjecttype = 'Opportunity' and DeveloperName = 'CA_Opportunity'].id;
        Id deOpp = [Select ID from RecordType where isActive = true and sobjecttype = 'Opportunity' and DeveloperName = 'DE_Opportunity'].id;        
        for(OpportunityLineItem opLineID: newOplineItemMap.values()) {
            oppIDSet.add(opLineID.Opportunityid);
        }          
        for (Opportunity opp : [Select RecordTypeId , id from Opportunity where id in :oppIDSet ]) {
            oppMap.put(opp.Id, opp);
        }      
        // Adding records in Map for specific country
        for(OpportunityLineItem Oli : newOplineItemList) {
            system.debug('Product is ' + oli.Product2Id);            
            system.debug('List price is '+ oli.ListPrice);
            system.debug('Unit price is '+ oli.UnitPrice);
            
            
			if(oli.ListPrice - oli.UnitPrice !=0) oli.addError('\'Sales Price\' cannot be altered.');
            if (oppMap.get(Oli.Opportunityid).RecordTypeId == caOpp ) CAnewOliList.add(Oli);
            else if (oppMap.get(Oli.Opportunityid).RecordTypeId == deOpp ) DEnewOliList.add(Oli);
        }
        
        //Country dispatcher
        if (DEnewOliList.size() > 0) {                   
                      ClsOpportunityLineItemTriggerHandler.OnAfterInsertUpdate(DEnewOliList, event);          
        }
        if (CAnewOliList.size() > 0) {
            
        }
    }
   
       public static void afterDeleteHandler(List<OpportunityLineItem> oldOplineItemList , Map<Id, OpportunityLineItem> oldOplineItemMap) {

        system.debug('afterDeleteHandler');           
                //Accumulate
        set<Id> oppIDSet = new set<Id>();
        List<OpportunityLineItem> DEoldOliList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> CAoldOliList = new List<OpportunityLineItem>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Id caOpp = [Select ID from RecordType where isActive = true and sobjecttype = 'Opportunity' and DeveloperName = 'CA_Opportunity'].id;
        Id deOpp = [Select ID from RecordType where isActive = true and sobjecttype = 'Opportunity' and DeveloperName = 'DE_Opportunity'].id;        
        for(OpportunityLineItem opLineID: oldOplineItemMap.values()) {
            oppIDSet.add(opLineID.Opportunityid);
        }          
        for (Opportunity opp : [Select RecordTypeId , id from Opportunity where id in :oppIDSet ]) {
            oppMap.put(opp.Id, opp);
        }      
        // Adding records in Map for specific country
        for(OpportunityLineItem Oli : oldOplineItemList) {
            if (oppMap.get(Oli.Opportunityid).RecordTypeId == caOpp ) CAoldOliList.add(Oli);
            else if (oppMap.get(Oli.Opportunityid).RecordTypeId == deOpp ) DEoldOliList.add(Oli);
        }
        
        //Country dispatcher
        if (DEoldOliList.size() > 0) {
            ClsOpportunityLineItemTriggerHandler.OnAfterDelete(DEoldOliList); 
        }
        if (CAoldOliList.size() > 0) {
            
        }

       }
}