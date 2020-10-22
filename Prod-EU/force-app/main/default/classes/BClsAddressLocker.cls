global class BClsAddressLocker implements Database.Batchable<Sobject> {
	global Database.QueryLocator start(Database.BatchableContext BC){
        //((STATUS__c = 'OPEN') OR (STATUS__c = 'IN ERROR' AND TRY_TO_CREATE_OREDER__c = TRUE))
        String query = 'Select Id, Id__c from Record_Updater__c where Name = \'Address__c\' AND Action__c=\'Update\' and FieldName__c = \'IsLocked__c\' AND Field_Type__c = \'Checkbox\' AND Value__c = \'true\' AND Acted_On__c = false';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Record_Updater__c> scope){
        List<Record_Updater__c> updRecList = new List<Record_Updater__c>();
        List<Address__c> updAddressList = new List<Address__c>();
        Map<String, Id> updRecMap = new Map<String, Id>();
        Map<Id, Address__c> updAddressMap = new Map<Id, Address__c>();
        Set<Id> addIds = new Set<Id>();
		for(Record_Updater__c rec : scope) addIds.add(rec.Id__c);        
        Map<Id, Address__c> lockedAddressMap = new Map<Id, Address__c>([Select Id from Address__c where id in :addIds AND IsLocked__c = true]);
        for(Record_Updater__c rec : scope) {
            if (!lockedAddressMap.containsKey(rec.Id__c)) { updAddressMap.put(rec.Id__c, new Address__c(id=rec.Id__c, IsLocked__c = true)); updRecMap.put(rec.Id__c, rec.Id); }
        }
        Boolean allSucceeded = true;
        if (updAddressMap.size() > 0) {
            updAddressList = updAddressMap.values();
            Database.SaveResult[] dsr = Database.update(updAddressList, false);
            for(Integer i = 0; i < dsr.size(); i++){
                if(dsr[i].isSuccess()){
                        updRecList.add(new Record_Updater__c(id = updRecMap.get(updAddressList[i].id), Acted_On__c = true));
                }else {
                    allSucceeded = false;
                    String error = '';
                    for(Database.Error err : dsr[i].getErrors()) {
                        error += error == '' ? 'Order ' + err.getMessage() : ', ' + err.getMessage();
                    }
                    //LogError(String action, String classNMethodName, String errorMsg, String eventType, String eventSource, String exceptionError, String externalID, String severity)
                    ErrorUtility.LogError('Consume', 'BClsAddressLocker.updateAddress__c', error, 'Address', 'crm', '', updAddressList[i].id, 'Informational');
                    System.debug('====error in order====='+error);
                }
            }
        }
        if (allSucceeded == true) {
            updRecList.clear();
            for(Record_Updater__c r : scope) updRecList.add(new Record_Updater__c(id = r.Id, Acted_On__c = true));
        }
        if (updRecList.size() > 0) {
            Database.SaveResult[] dsr = Database.update(updRecList, false);
            for(Integer i = 0; i < dsr.size(); i++){
                if(!dsr[i].isSuccess()){
                    String error = '';
                    for(Database.Error err : dsr[i].getErrors()) {
                        error += error == '' ? 'Order ' + err.getMessage() : ', ' + err.getMessage();
                    }
                    //LogError(String action, String classNMethodName, String errorMsg, String eventType, String eventSource, String exceptionError, String externalID, String severity)
                    ErrorUtility.LogError('Consume', 'BClsAddressLocker.updateRecord_Updater__c', error, 'Address', 'crm', '', updRecList[i].id, 'Informational');
                    System.debug('====error in order====='+error);
                }
            }
        }
    }
    global void finish(Database.BatchableContext BC){
        
    }
}