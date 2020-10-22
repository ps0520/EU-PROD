/**
 * BclsDailyDoubleOptInEmailBatch
 * Batch to check the current Marketing Cloud subscription status to keep Confirmations and Opt-outs synced with Sales Cloud daily 
 * @author Craig Johnson(Sundog)
 * @date 06/13/2019
 */

global class BclsDailyDoubleOptInEmailBatch implements database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts  {
    global enum BatchType{
        DE_LEAD,
        DE_ACCOUNT,
        CA_LEAD,
        CA_ACCOUNT,
        GB_IE_LEAD,
        GB_IE_ACCOUNT,
        AT_CH_LEAD,
        AT_CH_ACCOUNT
    }
    global BatchType bt { get; set; }

    global BclsDailyDoubleOptInEmailBatch() {
        bt = BatchType.DE_LEAD;
    }
    global BclsDailyDoubleOptInEmailBatch(BatchType bt) {
        this.bt = bt;
    }
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query;
        Set<String> recordTypeNames = new Set<String>();
        String leadBaseQuery = 'SELECT Id, Email, ConvertedAccountId, ' + 
                'Email_Pending_Opt_In__c, Email_Opt_In_List__c, Email_Double_Opt_In_Subscriber__c ' + 
                'FROM Lead ' + 
                'WHERE (Email != null AND Email_Double_Opt_In_Subscriber__c != null) AND RecordType.DeveloperName IN :recordTypeNames';
        String accountBaseQuery = 'SELECT Id, PersonEmail, PersonContactID, ' + 
            'Email_Pending_Opt_In__c, Email_Opt_In_List__c, Email_Double_Opt_In_Subscriber__c ' + 
            'FROM Account ' + 
            'WHERE (PersonEmail != null AND Email_Double_Opt_In_Subscriber__c != null) AND RecordType.DeveloperName IN :recordTypeNames';
        if (bt == BatchType.DE_LEAD) {
            query = leadBaseQuery;
            recordTypeNames.add('DE_Person_Lead');
        } else if(bt == BatchType.DE_ACCOUNT){
            query = accountBaseQuery;
            recordTypeNames.add('DE_Consumer');
        } else if(bt == BatchType.CA_LEAD){
            query = leadBaseQuery;
            recordTypeNames.add('CA_Person_Lead');
        } else if(bt == BatchType.CA_ACCOUNT){
            query = accountBaseQuery;
            recordTypeNames.add('CA_Consumer');
        }else if(bt == BatchType.GB_IE_LEAD){
            query = leadBaseQuery;
            recordTypeNames.add('GB_Person_Lead');
            recordTypeNames.add('IE_Person_Lead');
        } else if(bt == BatchType.GB_IE_ACCOUNT){
            query = accountBaseQuery;
            recordTypeNames.add('GB_Consumer');
            recordTypeNames.add('IE_Consumer');
        }else if(bt == BatchType.AT_CH_LEAD){
            query = leadBaseQuery;
            recordTypeNames.add('AT_Person_Lead');
            recordTypeNames.add('CH_Person_Lead');
        } else if(bt == BatchType.AT_CH_ACCOUNT){
            query = accountBaseQuery;
            recordTypeNames.add('AT_Consumer');
            recordTypeNames.add('CH_Consumer');
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<SObject> scope){
        System.debug(scope.size());
        for(sobject s : scope){
            system.debug(scope);
        }
        Map<String, ClsMarketingCloudHelperEmail.SubscriberStatus> subscriberMap = ClsMarketingCloudHelperEmail.retrieveSubscribersForObjects(scope, false);
        Map<String, ClsMarketingCloudHelperEmail.SubscriberStatus> listSubscriberMap = ClsMarketingCloudHelperEmail.retrieveSubscribersForObjects(scope, true);
        System.debug('BatchType: ' + bt);
        System.debug('scopeSize: ' + scope.size());
        System.debug('subscriberMapDebug');
        System.debug(subscriberMap);
        System.debug('listSubscriberDebug');
        System.debug(listSubscriberMap);

        if (bt == BatchType.DE_LEAD || bt == BatchType.CA_LEAD || bt == BatchType.GB_IE_LEAD || bt == BatchType.AT_CH_LEAD ) {
            Set<Id> convertedAccountIds = new Set<Id>();
            List<Lead> leadsToUpdate = new List<Lead>();
            List<Account> accountsToUpdate = new List<Account>();

            for(Lead l : (List<Lead>)scope){
                if (l.ConvertedAccountId != null) {
                    convertedAccountIds.add(l.ConvertedAccountId);
                }
            }

            Map<Id, Account> accountsMap = new Map<Id, Account>([SELECT Id, PersonContactID, PersonEmail, Email_Pending_Opt_In__c,Email_Opt_In_List__c 
                FROM Account 
                WHERE Id = :convertedAccountIds]);

            for(Lead l : (List<Lead>)scope){
                System.debug(l);
                String key = l.Id;
                if (subscriberMap.containsKey(key)) {
                    ClsMarketingCloudHelperEmail.SubscriberStatus subscriber = subscriberMap.get(key);
                    ClsMarketingCloudHelperEmail.SubscriberStatus listSubscriber = null;

                    if (listSubscriberMap.containsKey(key)) {
                        listSubscriber = listSubscriberMap.get(key);
                    }

                    if (l.ConvertedAccountId != null && accountsMap.containsKey(l.ConvertedAccountId)) {
                        Account a = accountsMap.get(l.ConvertedAccountId);
                        System.debug('l.ConvertedAccountId:' + l.ConvertedAccountId);
                        System.debug(a);
                        Account updateIfNotNull = ClsMarketingCloudHelperEmail.processSubscriber(a, subscriber, listSubscriber);
                        if (updateIfNotNull != null) {
                            accountsToUpdate.add(updateIfNotNull);
                        }
                    } else {
                        Lead updateIfNotNull = ClsMarketingCloudHelperEmail.processSubscriber(l, subscriber, listSubscriber);
                        if (updateIfNotNull != null) {
                            leadsToUpdate.add(updateIfNotNull);
                        }
                    }
                }
                else{
                    System.debug('no key in subscriber list');
                    System.debug(subscriberMap.keySet());
                }
            }

            ClsMarketingCloudHelperEmail.RUN_TRIGGER_LOGIC = false;
            update leadsToUpdate;
            update accountsToUpdate;
            ClsMarketingCloudHelperEmail.RUN_TRIGGER_LOGIC = true;
        } else {
            List<Account> accountsToUpdate = new List<Account>();

            for(Account a : (List<Account>)scope){
                
                String key = a.PersonContactID;
                if (subscriberMap.containsKey(key)) {
                    ClsMarketingCloudHelperEmail.SubscriberStatus subscriber = subscriberMap.get(key);
                    ClsMarketingCloudHelperEmail.SubscriberStatus listSubscriber = null;

                    if (listSubscriberMap.containsKey(key)) {
                        listSubscriber = listSubscriberMap.get(key);
                    }

                    Account updateIfNotNull = ClsMarketingCloudHelperEmail.processSubscriber(a, subscriber, listSubscriber);

                    if (updateIfNotNull != null) {
                        accountsToUpdate.add(updateIfNotNull);
                    }
                }
            }

            ClsMarketingCloudHelperEmail.RUN_TRIGGER_LOGIC = false;
            update accountsToUpdate;
            ClsMarketingCloudHelperEmail.RUN_TRIGGER_LOGIC = true;
        }
    }
    global void finish(Database.BatchableContext bc){
        if (bt == BatchType.DE_LEAD && !Test.isRunningTest()) {
            Database.executeBatch(new BclsDailyDoubleOptInEmailBatch(BatchType.DE_ACCOUNT), 100);
        } else if(bt == BatchType.DE_ACCOUNT && !Test.isRunningTest()){
             Database.executeBatch(new BclsDailyDoubleOptInEmailBatch(BatchType.CA_LEAD), 100);
        } else if(bt == BatchType.CA_LEAD && !Test.isRunningTest()){
             Database.executeBatch(new BclsDailyDoubleOptInEmailBatch(BatchType.CA_ACCOUNT), 100);
        }else if(bt == BatchType.CA_ACCOUNT && !Test.isRunningTest()){
             Database.executeBatch(new BclsDailyDoubleOptInEmailBatch(BatchType.GB_IE_LEAD), 100);
        }else if(bt == BatchType.GB_IE_LEAD && !Test.isRunningTest()){
             Database.executeBatch(new BclsDailyDoubleOptInEmailBatch(BatchType.GB_IE_ACCOUNT), 100);
        }else if(bt == BatchType.GB_IE_ACCOUNT && !Test.isRunningTest()){
             Database.executeBatch(new BclsDailyDoubleOptInEmailBatch(BatchType.AT_CH_LEAD), 100);
        }else if(bt == BatchType.AT_CH_LEAD && !Test.isRunningTest()){
             Database.executeBatch(new BclsDailyDoubleOptInEmailBatch(BatchType.AT_CH_ACCOUNT), 100);
        }

        
    }
}