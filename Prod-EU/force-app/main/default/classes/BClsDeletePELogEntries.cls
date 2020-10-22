/*
@Author        : Kumar Navneet
@Date Created    : 09/10/2019
@Description    : Batch class for Deletion of records
****************************************************************************************/
Global class BClsDeletePELogEntries Implements Database.batchable<sobject>{
      global final string query;
     global BClsDeletePELogEntries(string q){         
          query=q;
     }   
     global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
     }
     global  void execute(Database.BatchableContext BC,List<SObject> scope){
         delete scope;    
    }
    global void finish(Database.BatchableContext BC){
    }

 }