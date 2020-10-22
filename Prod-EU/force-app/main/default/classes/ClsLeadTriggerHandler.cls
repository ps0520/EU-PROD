/********************************************************
**Description: Lead trigger handler Class. All the CRUD events are handled here.
**Author:      Sundog
**Date Created:    JUNE.12.2019
*******************************************************/
public class ClsLeadTriggerHandler {
    
    /*********************************************************
	**@Author Sundog
	**@Date: 6/12/2019
	**@Reason Add Email Double Opt-In logic
	*********************************************************/
    public static void doubleOptInBefore(List<Lead> leads, Map<Id, Lead> oldMap){
    	Set<Id>recordTypeIds = ClsMarketingCloudHelperEmail.getValidLeadRecordTypeIds();
        if (ClsMarketingCloudHelperEmail.RUN_TRIGGER_LOGIC) {
            for(Lead l : leads){
                if (recordTypeIds.contains(l.RecordTypeId)
                    && l.Email != oldMap.get(l.Id).Email
                    && l.Email_Double_opt_In_Subscriber__c != null) {
                    l.Email_Pending_Opt_In_Reset__c = true;
                }
            }
           
        for(Lead l : leads){
        if (l.Email_Pending_Opt_In_Reset__c) {
                    l.Email_Double_Opt_In_Subscriber__c = null;
                    l.Email_Pending_Opt_In__c = true;
                }
            }
        }
    }
    
    /*********************************************************
	**@Author Sundog
	**@Date: 6/12/2019
	**@Reason Add Email Double Opt-In logic
	*********************************************************/
	public static void doubleOptInAfter(List<Lead> leads, Map<Id, Lead> oldMap){
        //because this org converts leads immediate, do not push into marketing cloud as a lead
        if(leads.size() == 1){
            Set<Id> recordTypeIds = ClsMarketingCloudHelperEmail.getValidLeadRecordTypeIds();
                for (Lead l : leads){
                if(l.Email != null && recordTypeIds.contains(l.RecordTypeId)) {
                    if (l.Email_Double_Opt_In_Subscriber__c == null
                        && ((l.Email_Pending_Opt_In__c && (oldMap == null || !oldMap.get(l.Id).Email_Pending_Opt_In__c))
                        || (l.Email_Pending_Opt_In_Reset__c && (oldMap == null || !oldMap.get(l.Id).Email_Pending_Opt_In_Reset__c)))) {
                            ClsMarketingCloudHelperEmail.sendDoubleOptInFuture(l.Id);
                    }
                }
            }
        }
    }
    
    /*********************************************************
	**@Author Navneet
	**@Date: 31/07/2020
	**@Reason S-doc creation on lead
	*********************************************************/
    public static void SdocCreationAfter(List<Lead> leads){
        List<String> lstTemplateIds = new List<String>();       
        List<SDOC__SDJob__c> jobList = new List<SDOC__SDJob__c>();
        Id caLeadRecordtypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('CA_Person_Lead').getRecordTypeId();
        lstTemplateIds.add([Select Id, Name from SDOC__SDTemplate__c Where Name like 'CA Lead Template'].Id) ;
        for (Lead l : leads){
            if (l.RecordTypeId == caLeadRecordtypeId ){
                if(!lstTemplateIds.isEmpty()){
                    jobList.add(new SDOC__SDJob__c(SDOC__Start__c = true,  SDOC__Oid__c = l.Id, SDOC__ObjApiName__c = 'Lead', SDOC__SendEmail__c = '1', SDOC__Doclist__c = lstTemplateIds[0] ));  
                }                          
            }
        }
        if(!jobList.isEmpty()) insert jobList;
    }
    
}