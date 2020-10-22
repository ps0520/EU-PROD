/********************************************************
**Description: Account trigger handler Class. All the CRUD events are handled here.
**Author:      Sundog
**Date Created:    JUNE.12.2019
*******************************************************/

public class ClsAccountDoubleOptInTriggerHandler {
    
    /*********************************************************
	**@Author Sundog
	**@Date: 6/12/2019
	**@Reason Add Email Double Opt-In logic
	*********************************************************/
    public static void doubleOptInBefore(List<Account> accounts, Map<Id, Account> oldMap){
        Set<Id> recordTypeIds = ClsMarketingCloudHelperEmail.getValidAccountRecordTypeIds();
        //process email address change
        if (ClsMarketingCloudHelperEmail.RUN_TRIGGER_LOGIC) {
            for(Account a : accounts){
                if (recordTypeIds.contains(a.RecordTypeId) 
                    && a.PersonEmail != oldMap.get(a.Id).PersonEmail
                    && a.Email_Double_Opt_In_Subscriber__c != null) {
                    a.Email_Pending_Opt_In_Reset__c = true;
                }
            }

            for(Account a : accounts){
                if (a.Email_Pending_Opt_In_Reset__c) {
                    a.Email_Double_Opt_In_Subscriber__c = null;
                    a.Email_Pending_Opt_In__c = true;
                }
            }
        }
    }
    
    /*********************************************************
	**@Author Sundog
	**@Date: 6/12/2019
	**@Reason Add Email Double Opt-In logic
	*********************************************************/
    public static void doubleOptInAfter(List<Account> accounts, Map<Id, Account> oldMap){
        Set<Id> recordTypeIds = ClsMarketingCloudHelperEmail.getValidAccountRecordTypeIds();

        if(accounts.size() == 1){
            for(Account a : accounts){
                if(a.PersonEmail != null && recordTypeIds.contains(a.RecordTypeId)) {
                    if (a.Email_Double_Opt_In_Subscriber__c == null 
                        && ((a.Email_Pending_Opt_In__c && (oldMap == null || !oldMap.get(a.Id).Email_Pending_Opt_In__c))
                        || (a.Email_Pending_Opt_In_Reset__c && (oldMap == null || !oldMap.get(a.Id).Email_Pending_Opt_In_Reset__c)))) {
                        ClsMarketingCloudHelperEmail.sendDoubleOptInFuture(a.Id);
                    }
                }
            }
        }
    }

}