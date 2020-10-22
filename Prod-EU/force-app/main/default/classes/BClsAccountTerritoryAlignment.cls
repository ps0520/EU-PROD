/*******************************************************
@Author        : Abhishek Parghi, Jagan Periyakaruppan 
@Date Created    : 4/10/2017
@Description    : Apex Utility class.
*******************************************************/
global class BClsAccountTerritoryAlignment implements Database.Batchable<sObject>, Database.Stateful {
    private String query; 
    private String countryCode;
	Integer numberOfRecords = 0;

    global BClsAccountTerritoryAlignment (String soql, String country){
        query = soql;
        countryCode = country;
    }
    global Database.QueryLocator start(Database.BatchableContext info) {
        return Database.getQueryLocator(query);      
    }
    //Method to execute the batch Account Territory Alignment 
    global void execute(Database.BatchableContext info, List<Account> scope) {
		numberOfRecords = numberOfRecords + scope.size();
        system.debug('Value of countryCode is ' + countryCode);
        system.debug('Value of numberOfRecords is ' + numberOfRecords);
        
        String batch = 'Update';
        ClsAccountTerritoryTriggerHandler.AccountTerritoryBlank(scope,batch);
        ClsAccountTerritoryTriggerHandler.ZiptoAlignUpdate(scope,batch,countryCode);
        ClsAccountTerritoryTriggerHandler.AccountTerritoryUpdate(scope,batch,countryCode);
        ClsAccountTerritoryTriggerHandler.AccountOwnerUpdate(scope,batch,countryCode);
    }
    
    //Finish Method
    global void finish(Database.BatchableContext BC)
    {
        AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email from AsyncApexJob where Id =:BC.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
        mail.setSubject('Account Territory Alignment Run Status - ' + system.now().format('MMM') + ' ' + system.now().format('YYYY') + ' '  + a.Status );
        mail.setPlainTextBody('Records Processed with '+ a.NumberOfErrors + ' failures. Number of records processed -- ' + numberOfRecords);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }    
}