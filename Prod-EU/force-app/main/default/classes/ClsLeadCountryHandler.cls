/****************************************************************************************************************
@Author        : Kumar Navneet
@Date Created    : 12/6/2019
@Description    : Creating class for handling Country specific things and updating currency
****************************************************************************************************************/

public class ClsLeadCountryHandler {
    
    public static void beforeInsertHandler(List<Lead> newleadList) {
        system.debug('beforeInsertHandler- Lead');
        //Accumulate        
        Id caLeadRecordtypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('CA_Person_Lead').getRecordTypeId();
        Id chLeadRecordtypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('CH_Person_Lead').getRecordTypeId();
        Id GBLeadRecordtypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('GB_Person_Lead').getRecordTypeId();
        Id IELeadRecordtypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('IE_Person_Lead').getRecordTypeId();
        Id SILeadRecordtypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('SI_Person_Lead').getRecordTypeId();
        List<Lead> GBnewLeadsList = new List<Lead>();
        List<Lead> IEnewLeadsList = new List<Lead>();       
        // Adding records in Map for specific country
        for(Lead Le : newleadList) {
            system.debug('for Lead');
            Le.Lead_Convert__c = True ;
            if (Le.RecordTypeId == caLeadRecordtypeId ) {
                system.debug('if Lead');
                Le.CurrencyIsoCode = 'CAD';
            }else
            {
                if (Le.RecordTypeId == chLeadRecordtypeId ) {
                    Le.CurrencyIsoCode = 'CHF';
                }
                else
                {
                    if (Le.RecordTypeId == GBLeadRecordtypeId ) {
                        Le.CurrencyIsoCode = 'GBP';
                        GBnewLeadsList.add(Le);
                    }
                    else
                    {
                        if (Le.RecordTypeId == IELeadRecordtypeId ) {
                            Le.CurrencyIsoCode = 'EUR';
                            IEnewLeadsList.add(Le);
                        }
                        else
                        {
                            if (Le.RecordTypeId == SILeadRecordtypeId ) {
                                Le.CurrencyIsoCode = 'EUR';                            
                            }
                        }
                    }
                }
            }
        }      
        if (GBnewLeadsList.size() > 0) {
            system.debug('inside GB- GBnewLeadsList.size() = '+GBnewLeadsList.size());
            ClsLeadTerritoryTriggerHandler.OnBeforeInsert(GBnewLeadsList, 'GB');             
        }
        if (IEnewLeadsList.size() > 0) {
            system.debug('inside IE- IEnewLeadsList.size() = '+IEnewLeadsList.size());
            ClsLeadTerritoryTriggerHandler.OnBeforeInsert(IEnewLeadsList, 'IE');             
        }
    }
    public static void beforeUpdateHandler(List<Lead> newleadList, Map<Id, Lead> oldleadMap) {
        system.debug('beforeUpdateHandler- Lead');
        //Accumulate        
        List<Lead> GBnewLeads = new List<Lead>();
        List<Lead> IEnewLeads = new List<Lead>();        
        Map<Id, Lead> GBoldLeads = new Map<Id, Lead>();     
        Map<Id, Lead> IEoldLeads = new Map<Id, Lead>();
        
        Id GBLeadRecordtypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('GB_Person_Lead').getRecordTypeId();
        Id IELeadRecordtypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('IE_Person_Lead').getRecordTypeId();
        
        // Adding records in list for specific country
        for(Lead Le : newleadList) {
            if (Le.RecordTypeId == GBLeadRecordtypeId) GBnewLeads.add(Le);
            else if (Le.RecordTypeId == IELeadRecordtypeId) IEnewLeads.add(Le);
        }
        // Adding old records in list for specific country
        for(Lead Le : oldleadMap.values()) {
            if (Le.RecordTypeId == GBLeadRecordtypeId) GBoldLeads.put(Le.id, Le);
            else if (Le.RecordTypeId == IELeadRecordtypeId) IEoldLeads.put(Le.id, Le);
        }          
        
        //Country dispatcher
        if (GBnewLeads.size() > 0) {
            system.debug('inside GB- GBnewLeads.size() = '+GBnewLeads.size());
            ClsLeadTerritoryTriggerHandler.OnBeforeUpdate(GBnewLeads, GBoldLeads, 'GB');
        }
        if (IEnewLeads.size() > 0) {
            system.debug('inside IE- IEnewLeads.size() = '+IEnewLeads.size());
            ClsLeadTerritoryTriggerHandler.OnBeforeUpdate(IEnewLeads, IEoldLeads, 'IE');
        }
    }
}