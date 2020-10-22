public class ClsBenefitTriggerHandler {
    public static void onBeforeInsert(List<Benefit__c> lstBenefit){
        Map<Id, RecordType> mapRecordType = new Map<Id, RecordType>([SELECT Id, DeveloperName, Name FROM RecordType WHERE DeveloperName LIKE 'CA_%' AND SobjectType = 'Benefit__c']);
        for(Benefit__c objBenefit : lstBenefit){
            if(mapRecordType.containsKey(objBenefit.RecordTypeId) && mapRecordType.get(objBenefit.RecordTypeId).DeveloperName.startsWithIgnoreCase('CA_')){
                objBenefit.CurrencyIsoCode = 'CAD';
            }
        }   
    }
    public static void onAfterInsert(Map<Id, Benefit__c> newMap) {
        Id caOppRecType = [Select Id from RecordType where isActive = true AND SobjectType = 'Benefit__c' and DeveloperName = 'CA_Benefit'].Id;
        Map<ID, Benefit__c> caBenefitList = new Map<Id, Benefit__c>();
        for(Benefit__c b : newMap.values() ) if (b.RecordTypeId == caOppRecType) caBenefitList.put(b.id, b);
        if (caBenefitList.size() > 0) handleUniqueBenefitHierarchy(caBenefitList);
    }
    
    public static void onBeforeUpdate(Map<Id, Benefit__c> newMap, Map<Id, Benefit__c> oldMap) {
        Id caOppRecType = [Select Id from RecordType where isActive = true AND SobjectType = 'Benefit__c' and DeveloperName = 'CA_Benefit'].Id;
        Map<ID, Benefit__c> caBenefitList = new Map<Id, Benefit__c>();
        for(Benefit__c b : newMap.values() ) if (b.RecordTypeId == caOppRecType) caBenefitList.put(b.id, b);
        if (caBenefitList.size() > 0) doNotAllowChanges(caBenefitList, oldMap);
    }
    
    public static void onAfterUpdate(Map<Id, Benefit__c> newMap, Map<Id, Benefit__c> oldMap) {
        //To do
        Id caOppRecType = [Select Id from RecordType where isActive = true AND SobjectType = 'Benefit__c' and DeveloperName = 'CA_Benefit'].Id;
        Map<ID, Benefit__c> caBenefitList = new Map<Id, Benefit__c>();
        for(Benefit__c b : newMap.values() ) if (b.RecordTypeId == caOppRecType) caBenefitList.put(b.id, b);
        if (caBenefitList.size() > 0) changePayor(caBenefitList, oldMap);
    }
    
    public static void handleUniqueBenefitHierarchy(Map<Id, Benefit__c> newMap) {
        set<Id> accIds = new Set<Id>();
        set<String> hierTypes = new Set<String>();
        //Benefit__c> inactBen;
        for(Benefit__c b : newMap.values()) {accIds.add(b.Account__c); if (b.Benefit_Hierarchy__c != 'Other') hierTypes.add(b.Benefit_Hierarchy__c);}
        List<Benefit__c> existingBen = [Select Id, Account__c, Benefit_Hierarchy__c from Benefit__c where Account__c in :accIds AND Benefit_Hierarchy__c in :hierTypes AND Inactive__c = false];
        if (existingBen.size() < 1) return;  // nothing to do as no duplicates exist.
        List<Benefit__c> inactBens = new List<Benefit__c>();
        for(Benefit__c b : newMap.values()) {
            for(Benefit__c be : existingBen) {
                if (b.Account__c == be.Account__c && b.Benefit_Hierarchy__c == be.Benefit_Hierarchy__c && b.Id != be.Id) {
                    inactBens.add(new Benefit__c(id = be.Id, Inactive__c = true));
                }
            }
        }
        if (inactBens.size() > 0) {
            try {
                update inactBens;
            } catch (DmlException de) {
                system.debug('Unable to inactivate existing Benefits with the same Hierarchy. Error: ' + de.getMessage());
            }
        }
    }
    public static void doNotAllowChanges(Map<Id, Benefit__c> newMap, Map<Id, Benefit__c> oldMap) {
        //Don't permit changes on InActive Benefits
        boolean retTrue = false;
        for(Benefit__c b : newMap.values()) {
            if (oldMap.get(b.Id).Inactive__c == true) { retTrue = true; b.addError('You can\'t make changes on Inactive Benefits.'); }
        }
        if (retTrue) return;
        //If there are any Closed Opportunities associated with this Benefit, do not allow any changes other than IsActive__c being made false
        List<Opportunity> opps = [Select Id, Benefit__c from Opportunity where Benefit__c in :newMap.keyset() AND StageName = 'Closed - Complete'];
        if (opps.size() < 1) return; // No closed Opportunities with this Benefit
        Map<Id, Id> closedOpps = new Map<Id, Id>();
        for (Opportunity o : opps) closedOpps.put(o.Benefit__c, o.Id);
        for(Benefit__c b : newMap.values()) {
            if (closedOpps.containsKey(b.Id) ) {
                //Now validate what got changed - worry about Payor and Ids and if it was 
                if(dataChanged(b, oldMap.get(b.Id)))            
                    b.addError('A closed Opportunity with Id: ' + closedOpps.get(b.Id) + ' already exists. You can\'t change this Benefit. Inactivate this Benefit and create a new one instead.');
            }
        }
    }
    
    public static void changePayor(Map<Id, Benefit__c> newMap, Map<Id, Benefit__c> oldMap) {
        List<Opportunity> opps = [Select Id, Benefit__c from Opportunity where Benefit__c in :newMap.keyset() AND StageName Not in ('Closed - Complete', 'Cancelled')];
        if (opps.size() < 1) return; // No closed Opportunities with this Benefit
        Map<Id, Id> openOpps = new Map<Id, Id>();
        Opportunity opp;
        List<Opportunity> updOpps = new List<Opportunity>();
        for (Opportunity o : opps) openOpps.put(o.Benefit__c, o.Id);
        for(Benefit__c b : newMap.values()) { 
            if (openOpps.containsKey(b.Id) && b.Payor__c != oldMap.get(b.Id).Payor__c) {
                opp = new Opportunity(id = openOpps.get(b.Id), Payor__c = b.Payor__c);
                updOpps.add(opp);
            }
        }
        if (updOpps.size() > 0) {
            try {
                update updOpps;
             } catch (DmlException de) {
                 system.debug('Error in updating non-closed Opportunities associated with the Benefit after Payor is changed on the Benefit. Error: ' + de.getMessage());
             }
        }
    }
    
    private static boolean dataChanged(Benefit__c nb, Benefit__c ob) {
        boolean changed = false;
        if (nb.Account__c != ob.Account__c) return true;
        if (nb.Benefit_Hierarchy__c != ob.Benefit_Hierarchy__c) return true;
        if (nb.CurrencyIsoCode != ob.CurrencyIsoCode) return true;
        if (nb.Insurance_Holder_s_Relationship__c != ob.Insurance_Holder_s_Relationship__c) return true;
        if (nb.Member_Id__c != ob.Member_Id__c) return true;
        if (nb.Payor__c != ob.Payor__c) return true;
        if (nb.Primary_Policy_Holder_Birth_Date__c != ob.Primary_Policy_Holder_Birth_Date__c) return true;
        if (nb.Primary_Policy_Holder_Name__c != ob.Primary_Policy_Holder_Name__c) return true;
        if (nb.Policy_Number__c != ob.Policy_Number__c) return true;
        if (nb.Employer_Name__c!= ob.Employer_Name__c) return true;
        if (nb.Job_Title__c!= ob.Job_Title__c) return true;
        return changed;
    }
}