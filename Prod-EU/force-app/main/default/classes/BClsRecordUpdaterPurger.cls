global class BClsRecordUpdaterPurger implements Database.Batchable<Sobject> {
	global Database.QueryLocator start(Database.BatchableContext BC){
        //((STATUS__c = 'OPEN') OR (STATUS__c = 'IN ERROR' AND TRY_TO_CREATE_OREDER__c = TRUE))
        String query = 'Select Id from Record_Updater__c where  Acted_On__c = true';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Record_Updater__c> scope){
        delete scope;
    }
    global void finish(Database.BatchableContext BC){
        
    }
}