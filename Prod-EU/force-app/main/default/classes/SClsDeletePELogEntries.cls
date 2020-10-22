/*
@Author        : Kumar Navneet
@Date Created    : 09/10/2019
@Description    : Schedular class for calling BatchDeleteRecord class for deletion of records
****************************************************************************************/
Global class SClsDeletePELogEntries implements Schedulable{
    global void execute(SchedulableContext sc){
        String query = 'select id from Platform_Event_Error_Log__c where CreatedDate != LAST_N_DAYS:3';
        BClsDeletePELogEntries delBatch = new BClsDeletePELogEntries(query);
        Id BatchProcessId = Database.ExecuteBatch(delBatch);   
    }
}