/**
 * BclsHourlyDoubleOptInBatch
 * Batch to call marketing cloud for any pending opt-ins not processed by trigger logic
 * Batch also processes a pending opt-out
 * @author Craig Johnson(Sundog)
 * @date 06/13/2019
 */

global class BclsHourlyDoubleOptInBatch implements database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts  {
    global enum BatchType{
        LEAD,
        ACCOUNT
    }
    global BatchType bt { get; set; }

    global BclsHourlyDoubleOptInBatch() {
        bt = BatchType.LEAD;
    }
    global BclsHourlyDoubleOptInBatch(BatchType bt) {
        this.bt = bt;
    }
    global Database.QueryLocator start(Database.BatchableContext bc){
        //if a batch run is already processing, abort the job
        Id currentClassId = [SELECT Id FROM ApexClass WHERE Name = 'BclsHourlyDoubleOptInBatch' LIMIT 1].Id;
        List<AsyncApexJob> jobs = [SELECT Id, Status, ApexClassID FROM AsyncApexJob WHERE ApexClassID = :currentClassId and Status = 'Processing'];
        if (jobs.size() > 0) {
            System.abortJob(bc.getJobId());
        }
        
        if (bt == BatchType.LEAD) {
           Set<Id> recordTypeIds = ClsMarketingCloudHelperEmail.getValidLeadRecordTypeIds();
           return Database.getQueryLocator([SELECT Id,Email, Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c,Email_Pending_Opt_Out__c
                FROM Lead WHERE Email != null AND ConvertedAccountId = null AND 
                ((Email_Pending_Opt_In__c = true AND Email_Double_Opt_In_Subscriber__c = null) OR Email_Pending_Opt_Out__c = true) 
                AND RecordTypeId = :recordTypeIds AND Email_Opt_In_Method__c != null AND Email_Opt_In_Language__c != null]);
        } else {
            Set<Id> recordTypeIds = ClsMarketingCloudHelperEmail.getValidAccountRecordTypeIds();
            return Database.getQueryLocator([SELECT Id, PersonContactID,PersonEmail, Email_Pending_Opt_In__c, Email_Double_Opt_In_Subscriber__c,Email_Pending_Opt_Out__c
                FROM Account WHERE PersonEmail != null AND 
                ((Email_Pending_Opt_In__c = true AND Email_Double_Opt_In_Subscriber__c = null) OR Email_Pending_Opt_Out__c = true) 
                AND RecordTypeId = :recordTypeIds AND Email_Opt_In_Method__c != null AND Email_Opt_In_Language__c != null]);
        }
    }
    global void execute(Database.BatchableContext bc, List<SObject> scope){
        System.debug(scope.size());
        List<SObject> recordsToUpdate = new List<SObject>();

        if (bt == BatchType.LEAD) {
            for(Lead l : (List<Lead>)scope){
                SObject result = null;

                if (l.Email_Pending_Opt_Out__c) {
                    result = ClsMarketingCloudHelperEmail.sendOptOut(l.Id, false);
                } else if (l.Email_Pending_Opt_In__c && l.Email_Double_Opt_In_Subscriber__c == null) {
                    result = ClsMarketingCloudHelperEmail.sendDoubleOptIn(l.Id, false);
                }
                if (result != null) {
                    recordsToUpdate.add(result);
                }
            }
        } else {
            for(Account a : (List<Account>)scope){
                SObject result = null;

                if (a.Email_Pending_Opt_Out__c) {
                    result = ClsMarketingCloudHelperEmail.sendOptOut(a.Id, false);
                } else if (a.Email_Pending_Opt_In__c && a.Email_Double_Opt_In_Subscriber__c == null) {
                    result = ClsMarketingCloudHelperEmail.sendDoubleOptIn(a.Id, false);
                }
                if (result != null) {
                    recordsToUpdate.add(result);
                }
            }
        }

        Database.update(recordsToUpdate, false);
    }
    global void finish(Database.BatchableContext bc){
        if (bt == BatchType.LEAD && !Test.isRunningTest()) {
            Database.executeBatch(new BclsHourlyDoubleOptInBatch(BatchType.ACCOUNT), 4);
        } 
    }
}