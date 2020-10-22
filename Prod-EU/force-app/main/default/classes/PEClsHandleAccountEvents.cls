/****************************************************************************************************************
@Author        : Vijay Adusumilli
@Date Created    : 7/30/2019
@Description    : Class to handle Account Platform Events
****************************************************************************************************************/

public class PEClsHandleAccountEvents {
    @testVisible private static List<CRM_Account_Event_Out__e> eventList = new List<CRM_Account_Event_Out__e>();
    public static final String version = '2.0';  // version of the canonical
    
    // Method to handle all incoming events. Based on the type of event, add them into different buckets and call the appropriate method to handle those events.
    public static void handleIncomingEvents(List<CRM_Account_Event__e> incEvs) {
        List<CRM_Account_Event__e> createList = new List<CRM_Account_Event__e>();
        List<CRM_Account_Event__e> updateList = new List<CRM_Account_Event__e>();
        List<CRM_Account_Event__e> ecomConfirmedList = new List<CRM_Account_Event__e>();
        List<CRM_Account_Event__e> omsConfirmedList = new List<CRM_Account_Event__e>();
        for (CRM_Account_Event__e ev : incEvs) {
            //if (ev.version__c != version) {
                //write error that an incorrect version message is delivered and don't know how to handle it.
                //continue;
            //}
            // The following should never happen - incorrect entity
            if (ev.entityType__c != 'account') {
                //write error that an incorrect type of message is delivered and don't know how to handle it.
                continue;
            }
            if ( ev.stage__c == 'pending' && ev.operation__c == 'create' && (ev.eventSource__c.containsIgnoreCase('ECOM') || ev.eventSource__c.containsIgnoreCase('TS') ) ) { 
                createList.add(ev);
            }
            else if (ev.stage__c == 'confirmed' && ev.operation__c == 'create' && ev.eventSource__c != null && ev.eventSource__c.containsIgnoreCase('OMS')  )
            {
                omsConfirmedList.add(ev); 
            }
            else if (ev.stage__c == 'confirmed' && ev.operation__c == 'create' && ev.eventSource__c != null && ev.eventSource__c.containsIgnoreCase('ECOM') && 
                     ev.systemOfOrigin__c != null && !ev.systemOfOrigin__c.containsIgnoreCase('ECOM'))
            {
               ecomConfirmedList.add(ev); 
            }
            else if ( ev.stage__c == 'pending' && ev.operation__c == 'update' && (ev.eventSource__c.containsIgnoreCase('ECOM') || ev.eventSource__c.containsIgnoreCase('TS') ) ) { //|| ev.externalSource__c.containsIgnoreCase('osc'))) {
                updateList.add(ev);
            }
            else {
                system.debug('Received an event that is being ignored. Source: ' + ev.eventSource__c + ', Operation: ' + ev.operation__c + ', Stage: ' + ev.stage__c);
                System.debug('Event: ' + ev);
            }
        }
        if (createList.size() > 0) consumeAccount(createList, 'create');
        if (updateList.size() > 0) consumeAccount(updateList, 'update');
        if (omsConfirmedList.size() > 0) updateAccountStatus(omsConfirmedList);
        if (ecomConfirmedList.size() > 0) updateSFCCId(ecomConfirmedList);
    }
    
    public static void updateAccountStatus(List<CRM_Account_Event__e> consumeEvents) {
        // Publish Register Event for consumption by Kafka/Splunk
        consumeAccount(consumeEvents, 'registered');
    }
    public static void updateSFCCId(List<CRM_Account_Event__e> consumeEvents) {
        List<Account> updActs = new List<Account>();
        for(CRM_Account_Event__e ev : consumeEvents) updActs.add(new Account(id=ev.accountID__c, SFCC_Account_Id__c = ev.eventSourceID__c));
        try {
            update updActs;
        } catch (DmlException e) {
            System.debug('Error in Updating Account with SFCC Account ID. Error: ' + e.getMessage());
            return;
        }
    }
    // Method to consume incoming Events.
    public static void consumeAccount(List<CRM_Account_Event__e> consumeEvents, String op) {
        // Need the SysAdmin Id to change the Ownership of the record so that Sharing Rules Calculation gets executed.
        Id sysAdminId;
        if (op == 'create') {
            Id profileId = [Select Id from Profile where Name like 'System Administrator' Limit 1].Id;
            sysAdminId = [Select ID, Name from User where firstname = 'Salesforce' AND Lastname = 'Admin' AND profileId = :profileId AND IsActive = true Limit 1 ].Id;
            if (sysAdminId == null) {
                ErrorUtility.LogError('Consume', 'PEClsHandleAccountEvents.consumeAccount', 'Error in Consuming Account Create Operations.', 'account', consumeEvents[0].eventSourceID__c, 
                                              'Could not get Salesforce Admin Id. Can\'t processing Create Operations' , consumeEvents[0].eventSourceID__c, 'Fatal Error - Bailing out');
                return;
            }
        }
        // The following code looks for duplicate Account create operation.
        Map<String,ID> dupAccounts = new Map<String, ID>();
        if (op == 'create') {
            Set<String> uniqueSO = new Set<String>();
            for (CRM_Account_Event__e e : consumeEvents) uniqueSO.add(e.systemOfOrigin__c.trim() + e.systemOfOriginID__c.trim() );
            //Find if any dups exist
            List<Account> existingAccounts = [Select ID, SOS_Unique_ID__c from Account Where SOS_Unique_ID__c in :uniqueSO];
            if (existingAccounts.size() > 0) {
                for(Account a : existingAccounts) {
                    dupAccounts.put(a.SOS_Unique_ID__c, a.Id);
                    ErrorUtility.LogError('Consume', 'PEClsHandleAccountEvents.consumeAccount', 'Error in Consuming Account Create Operations.', 'account', consumeEvents[0].eventSourceID__c, 
                                          'Duplicate messages: ' + a.SOS_Unique_ID__c + ' Will not be processed.' , consumeEvents[0].eventSourceID__c, 'Informational');
                }

            }
            if (existingAccounts.size() == uniqueSO.size()) { 		// all duplicate Accounts. Write error message and exit
                if (existingAccounts.size() > 1) {
                    ErrorUtility.LogError('Consume', 'PEClsHandleAccountEvents.consumeAccount', 'Error in Consuming Account Create Operations.', 'account', consumeEvents[0].eventSourceID__c, 
                                      'Received all duplicate message(s). No Account event(s) will be processed.' , consumeEvents[0].eventSourceID__c, 'Fatal Error - Bailing out');
                }
				system.debug('All duplicate Accounts received for creation. Bailing out...');
                return;
            }
        }
        
        // If the accountId is not known and the op is update, try to get the Account Ids using SystemOfOrigin info
        List<String> accountSooIds = new List<String>();
        Set<ID> actList = new Set<ID>();
        Map<String, ID> sooAccountsMap = new Map<String, ID>();
        if (op == 'update' || op == 'registered') {
            for(CRM_Account_Event__e ev : consumeEvents) {
                // Need Account ID to update an Account. If Account Id is not there, search based on systemOfOriginID of Account.
                if ((String.isBlank(ev.accountID__c) || ev.accountID__c == 'null') ) {
                        if ( !(String.isBlank(ev.systemOfOrigin__c) || ev.systemOfOrigin__c == 'null') && !(String.isBlank(ev.systemOfOriginID__c) || ev.systemOfOriginID__c == 'null')) 
                                accountSooIds.add(ev.systemOfOrigin__c.trim() + ev.systemOfOriginID__c.trim());
                        else {  // Publish an error message as this Account can't be updated
                			ErrorUtility.LogError('Consume', 'PEClsHandleAccountEvents.consumeAccount', 'Error in Consuming Account Update Operations.', 'account', consumeEvents[0].eventSourceID__c, 
                                      'Received an update Event without Account ID and SoS information. eventSource: ' + ev.eventSource__c + ' eventSourceID: ' + ev.eventSourceID__c + '. Will not be processed.', 
                                                  consumeEvents[0].eventSourceID__c, 'Informational');
                        }
                } 
            }
            List<Account> accountList = new List<Account>(); 
            if (accountSooIds.size() > 0 ) {
                accountList = [Select ID, SOS_Unique_ID__c from Account where SOS_Unique_ID__c in :accountSooIds];
                for (Account a: accountList) { 
                    actList.add(a.Id);
                	sooAccountsMap.put(a.SOS_Unique_ID__c, a.Id);
                }
            }
        }
        
        //Get the existing Account details to handle optins
        Map<ID,Account> existAccountsMap = new Map<ID,Account>();
        if ((op == 'update' || op == 'registered')) {
            for (CRM_Account_Event__e e : consumeEvents) if ( !String.isBlank(e.accountID__c) && e.accountID__c != 'null') actList.add(e.accountID__c);
            //Find if any dups exist
            List<Account> existingAccountsList = [Select ID, Email_Opt_In_List__c, Email_Pending_Opt_In__c, Email_Opt_Out_List__c, Email_Pending_Opt_Out__c  from Account Where Id in :actList];
            if (existingAccountsList.size() > 0) {
                existAccountsMap.putAll(existingAccountsList);
                system.debug('Existing Accounts Size: ' + existAccountsMap.size());
                system.debug('Incoming Events Size: ' + consumeEvents.size());
            } else {
                // write error - No existing Accounts to update
                ErrorUtility.LogError('Consume', 'PEClsHandleAccountEvents.consumeAccount', 'Error in Consuming Accounts.', 'account', consumeEvents[0].eventSourceID__c, 
                                      'Received an Account event without an account id. Account Id in event: ' + consumeEvents[0].accountID__c + '. eventSource: ' + consumeEvents[0].eventSource__c + ' eventSourceID: ' + consumeEvents[0].eventSourceID__c + '. Will not be processed.', 
                                                  consumeEvents[0].eventSourceID__c, 'Informational');
                return;
            }
        }
        List<Account> accs = new List<Account>();
        system.debug('Consume Operation Type: ' + op);
        Account acc;
        String refId = '';
        Id caConsumerRecordType = [select id from recordtype where DeveloperName = 'CA_Consumer' and IsActive = true Limit 1 ].id;  // Being used for unknown record types.
        
        map<String, Id> recTypeMap = new map<String, Id>();
        List<RecordType> rs = [SELECT Id, developerName FROM RecordType where SobjectType= 'Account' AND isactive = true ]; // Will have to be updated
        for (RecordType r : rs) recTypeMap.put(r.developerName, r.Id);
        
        for (CRM_Account_Event__e ev : consumeEvents ) {
            ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleAccountEvents.consumeAccount', 'Logging incoming Event', 'account', ev.eventSourceID__c, 
                                  'Logging' , ev.eventSourceID__c, 'Success Log', String.valueOf(ev));

            //dup event check
            if (op == 'create' && dupAccounts.size() > 0 && dupAccounts.containsKey(ev.systemOfOrigin__c.trim()+ev.systemOfOriginID__c.trim())) {
                //write dup error message
                system.debug('Duplicate Message: ' + ev);
                continue;
            }
            if ((op == 'update' || op == 'registered') && !(existAccountsMap.containsKey(ev.accountID__c) || sooAccountsMap.containsKey(ev.systemOfOrigin__c.trim()+ev.systemOfOriginID__c.trim())) ) {
                // write account does not exist to update.
                continue;
            } 
            system.debug('Event: ' + ev);
            if (op == 'create')  acc = new Account();
            else if (op == 'update' || op == 'registered') { if (existAccountsMap.containsKey(ev.accountID__c)) acc = new Account(id = ev.accountID__c); 
                                           else acc = new Account(id = sooAccountsMap.get(ev.systemOfOrigin__c.trim()+ev.systemOfOriginID__c.trim())); 
                                     }
                    else { //don't know how to handle this operation
                        ErrorUtility.LogError('Consume', 'PEClsHandleAccountEvents.consumeAccount', 'Error in Consuming Accounts.', 'account', consumeEvents[0].eventSourceID__c, 
                                      'Received an Account event without a proper stage: ' + ev.stage__c + '. eventSource: ' + ev.eventSource__c + ' eventSourceID: ' + ev.eventSourceID__c + '. Will not be processed.', 
                                                  consumeEvents[0].eventSourceID__c, 'Informational');
                        system.debug('Don\'t know how to handle the type of Operation: ' + op + ' Not processing this item: ' + ev);
                        continue;
                    }
            if (op == 'registered') {
                acc.Sync_Status__c = 'created';
                acc.AccountNumber = (ev.referenceNumber__c != null && ev.referenceNumber__c != 'null') ? ev.referenceNumber__c : ev.eventSourceID__c;
                acc.Customer_Id__c = ev.eventSourceID__c;
                accs.add(acc);
                continue;
            }
            if (op == 'create') { 
                if (recTypeMap.containsKey(ev.countryCode__c +'_'+ ev.accountType__c.capitalize() )) 
                    acc.RecordTypeId = recTypeMap.get(ev.countryCode__c +'_'+ ev.accountType__c.capitalize());
                else {
                    ErrorUtility.LogError('Consume', 'PEClsHandleAccountEvents.consumeAccount', 'Error in Consuming Accounts.', 'account', consumeEvents[0].eventSourceID__c, 
                                          'Received an Account Create event without a proper way to determine record type. eventSource: ' + ev.eventSource__c + ' eventSourceID: ' + ev.eventSourceID__c + '. Will not be processed.', 
                                          consumeEvents[0].eventSourceID__c, 'Informational');
                    system.debug('Don\'t know how to handle the type of Operation: ' + op + ' Not processing this item: ' + ev);
                    continue;
            	}
            }
            acc.Inactive__c = !ev.isActive__c;
            if (op == 'create') acc.OwnerId = sysAdminId;
            if (op == 'create' && ev.systemOfOrigin__c != 'null') acc.System_Of_Origin__c = ev.systemOfOrigin__c;
            if (op == 'create' && ev.systemOfOriginID__c != 'null') acc.System_Of_Origin_Id__c = ev.systemOfOriginID__c;
            if (op == 'create') acc.SOS_Unique_ID__c  = ev.systemOfOrigin__c.trim() + ev.systemOfOriginID__c.trim() ; 
            if (!String.isBlank(ev.businessName__c) && ev.businessName__c != 'null') acc.Name = ev.businessName__c;
            if (ev.firstName__c != 'null' ) acc.FirstName = ev.firstName__c;
            if(ev.middleName__c != 'null') acc.MiddleName = ev.middleName__c;
            if(ev.lastName__c != 'null') acc.LastName = ev.lastName__c;
            if(ev.nickName__c != 'null') acc.Nickname__c = ev.nickName__c;
            if(ev.personalemail__c != 'null') acc.PersonEmail = ev.personalemail__c;
            if (ev.businessEmail__c != 'null') acc.Organzation_Email__c = ev.businessEmail__c;
            if (ev.homePhone__c != 'null') acc.PersonHomePhone = ev.homePhone__c;
            if (ev.mobilePhone__c != 'null') acc.PersonMobilePhone = ev.mobilePhone__c;
            if (ev.workPhone__c != 'null' ) acc.Phone = ev.workPhone__c;
            if (ev.otherPhone__c != 'null') acc.PersonOtherPhone = ev.otherPhone__c;
            if (ev.fax__c != 'null') acc.Fax = ev.fax__c;
            if (ev.birthDate__c != null) acc.PersonBirthdate = ev.birthDate__c;
            if (ev.gender__c != 'null') acc.Gender__c = ev.gender__c;
            if (ev.languageCode__c != 'null') acc.Preferred_Language__c = ev.languageCode__c;
            // if (ev.countryCode__c != 'null') acc.BillingCountryCode = ev.countryCode__c;  **** Don't set the country code. It's unnecessarily showing up as an address.
            if (ev.dexcomID__c != 'null') acc.Dexcom_ID__c = ev.dexcomID__c;
            if (ev.pumpManufacturer__c != 'null') acc.Pump_Manufacturer__c = ev.pumpManufacturer__c;
            // if (ev.payorName__c != 'null') acc.Payor_Name__c = ev.payorName__c;      -- Payor Name will not be taken in. Will only be published.
            if (ev.guardianFirstName__c != 'null') acc.Parent_Guardian_First_Name__c = ev.guardianFirstName__c;
            if (ev.guardianLastName__c != 'null') acc.Parent_Guardian_Last_Name__c = ev.guardianLastName__c;
            if (ev.eventSource__c.equalsIgnoreCase('ECOM')) acc.SFCC_Account_Id__c = ev.eventSourceID__c;
            if (ev.metadata__c != 'null' && String.isNotBlank(ev.metadata__c)) {
                try {
                    MetaData md = (Metadata) JSON.deserialize(ev.metadata__c, Metadata.class);
                    for (metadataEntry mde : md.entries) {
                        if (mde.name.equalsIgnoreCase('onCreditHold')) acc.Credit_Hold__c = mde.value.equalsIgnoreCase('true') ? TRUE : FALSE;
                    }
                } catch (JSONException excep) {
                    system.debug('Deserializing incoming Metadata threw Error: ' + excep.getMessage() ) ;
                }
            }
                            
            //if (ev.emailOptin__c != null) acc.Email_Opt_In_List__c = ev.emailOptin__c;
            if (op == 'create' && !String.isBlank(ev.emailOptin__c) && ev.emailOptin__c != 'null') {
                if (ev.emailOptin__c.equalsIgnoreCase('TRUE')) {
                    acc.Email_Pending_Opt_In__c = true;
                    acc.Email_Opt_In_Method__c = 'Via Web Form';
                        string lang = ev.languageCode__c.left(2) != null ?  ev.languageCode__c.left(2) : 'en';
                        acc.Email_Opt_In_Language__c = lang == 'en' ? 'English' : lang == 'fr' ? 'French' : lang == 'de' ? 'German' : lang == 'it' ? 'Italian' : 'English' ;      //  This is how the picklist values are set-up in production.
                }
                if (ev.emailOptin__c.equalsIgnoreCase('FALSE')) acc.Email_Pending_Opt_Out__c = true;
            }
            if (op == 'update' && !String.isBlank(ev.emailOptin__c) && ev.emailOptin__c != 'null') {
                if (ev.emailOptin__c.equalsIgnoreCase('TRUE') && // existAccountsMap.get(ev.accountID__c).Email_Opt_In_List__c != null && 
                    !(existAccountsMap.get(ev.accountID__c).Email_Opt_In_List__c == 'True' || existAccountsMap.get(ev.accountID__c).Email_Pending_Opt_In__c == true)) {
                   		acc.Email_Pending_Opt_In__c = true;
                        acc.Email_Opt_In_Method__c = 'Via Web Form';
                        String lang = 'en';
                        if (String.isNotBlank(ev.languageCode__c) && ev.languageCode__c.length() > 1)  lang = ev.languageCode__c.left(2);
                        acc.Email_Opt_In_Language__c = lang == 'en' ? 'English' : lang == 'fr' ? 'French' : lang == 'de' ? 'German' : lang == 'it' ? 'Italian' : 'English' ;      //  This is how the picklist values are set-up in production.
                 } else {
                     if (ev.emailOptin__c.equalsIgnoreCase('FALSE') && // existAccountsMap.get(ev.accountID__c).Email_Opt_Out_List__c != null &&
                         !(existAccountsMap.get(ev.accountID__c).Email_Opt_Out_List__c == 'True' || existAccountsMap.get(ev.accountID__c).Email_Pending_Opt_Out__c == true) ) {
                             acc.Email_Pending_Opt_Out__c = true;
                     }
                 }
            }
            if (!String.isBlank(ev.smsOptin__c) && ev.smsOptin__c != 'null') 
            acc.SMS_Opt_In_List__c = ev.smsOptin__c.equalsIgnoreCase('TRUE') ? 'True' : ev.smsOptin__c.equalsIgnoreCase('FALSE') ? 'False' : '';
            if (!String.isBlank(ev.mailOptin__c) && ev.mailOptin__c != 'null') 
            acc.Mail_Opt_In_List__c = ev.mailOptin__c.equalsIgnoreCase('TRUE') ? 'True' : ev.mailOptin__c.equalsIgnoreCase('FALSE') ? 'False' : '';
            if (!String.isBlank(ev.phoneOptin__c) && ev.phoneOptin__c != 'null') 
            acc.Phone_Opt_In_List__c = ev.phoneOptin__c.equalsIgnoreCase('TRUE') ? 'True' : ev.phoneOptin__c.equalsIgnoreCase('FALSE') ? 'False' : '';
            acc.SFCC_Login_Enabled__c = !(ev.loginEnabled__c);    // The Label has been changed to SFCC Account Locked.
            if (ev.eventSource__c.equalsIgnoreCase('ECOM')) acc.Tax_Exempt__c = ev.taxExempt__c;
            accs.add(acc);
        }
        if (accs.size() > 0 && op == 'create') 
            try {
                insert accs;
                for (Account a : accs) {
                    ErrorUtility.LogError('Consume', 'PEClsHandleAccountEvents.consumeAccount', 'Successfully created Account.',  'account', consumeEvents[0].eventSourceID__c, 
                     'Account Id: ' + a.Id, consumeEvents[0].eventSourceID__c, 'Success Log');
                }
            } catch (DmlException de) {
                system.debug('Error in Consuming Account Create Operations. Error Msg: ' + de.getMessage());
                ErrorUtility.LogError('Consume', 'PEClsHandleAccountEvents.consumeAccount', 'Error in Consuming Account Create Operations.', 'account', consumeEvents[0].eventSourceID__c, 
                                      de.getMessage() , consumeEvents[0].eventSourceID__c, 'Fatal Error - Bailing out');
                return;
            }
        if (accs.size() > 0 && (op == 'update' || op == 'registered')) 
            try {
                update accs;
                for (Account a : accs) {
                    ErrorUtility.LogError('Consume', 'PEClsHandleAccountEvents.consumeAccount', 'Successfully ' + op + ' Account.',  'account', consumeEvents[0].eventSourceID__c, 
                     'Account Id: ' + a.Id, consumeEvents[0].eventSourceID__c, 'Success Log');
                }
                if (op == 'registered') {
                    Set<Id> actIdSet = new Set<Id>();
                    Set<String> actIdStringSet = new Set<String>();
                    for (Account a : accs) { actIdSet.add(a.id); actIdStringSet.add(a.Id); }
                    //PEClsHandleOrderEvents.publishOrderEvent(null, actIdStringSet, 'create');
                    publishAccountEvents(actIdSet, 'registered');
                }
            } catch (DmlException de) {
                system.debug('Error in Consuming Account Update Operations. Error Msg: ' + de.getMessage());
                ErrorUtility.LogError('Consume', 'PEClsHandleAccountEvents.consumeAccount', 'Error in Consuming Account Update Operations.', 'account', consumeEvents[0].eventSourceID__c, 
                                      de.getMessage() , consumeEvents[0].eventSourceID__c, 'Fatal Error - Bailing out');
                return;
            }
        //Set the SetResumeCheckpoint to the highest replayId
        /*
        String hrid = '';
        for(CRM_Account_Event__e ev : consumeEvents) if (hrid < ev.ReplayId) hrid = ev.ReplayId;
        system.debug('Setting the SetResumeChekpoint to ReplayId: ' + hrid);
        EventBus.TriggerContext.currentContext().setResumeCheckpoint(hrid);
		*/
        integer hrid = 0;
        for(CRM_Account_Event__e ev : consumeEvents) if (hrid < Integer.valueOf(ev.ReplayId)) hrid = Integer.valueOf(ev.ReplayId);
        system.debug('Setting the SetResumeChekpoint to ReplayId: ' + hrid);
        EventBus.TriggerContext.currentContext().setResumeCheckpoint(String.valueOf(hrid));
    }
    public static void publishAccountEvents(Set<Id> accountIds, String action) {
        publishAccountEventswithMerge(accountIds, action, null);
    }
    
    // Method to publish Account Events. Typically called in the After Insance of Trigger on Account. Could also be used to republish failed to be consumed Events. Called for Publishing 'registered' events from within this class.
    public static void publishAccountEventswithMerge(Set<Id> accountIds, String action, map<Id, Id> accountsMergeMap) {
        if(accountsMergeMap != null) {
            accountIds.clear();
            for(Id i : accountsMergeMap.values())  accountIds.add(i);
        }
        if (!Test.isRunningTest())  if (!PEClsHandleAccountEventsStatic.firstEventPublish()) return;
        List<CRM_Account_Address_Event_Out__e> eventList = new List<CRM_Account_Address_Event_Out__e>();     ////// changed event structure
        List<Account> accts = [Select Id, IsPersonAccount, Record_Type_Name__c, PersonBirthdate, Name, Organzation_Email__c, BillingCountryCode, BillingCountry, LastModifiedBy.Name, LastModifiedDate,
                                Fax, FirstName, Gender__c, PersonHomePhone, Inactive__c, LastName, MiddleName, PersonMobilePhone, Phone, PersonOtherPhone, PersonEmail, Prescriber_Id__c,
                                Preferred_Language__c, System_Of_Origin__c, System_Of_Origin_Id__c, Email_Opt_In_List__c, Phone_Opt_In_List__c, SMS_Opt_In_List__c, Mail_Opt_In_List__c, Payor__r.Name,
                                SFCC_Login_Enabled__c, Parent_Guardian_First_Name__c, Parent_Guardian_Last_Name__c, Dexcom_ID__c, Pump_Manufacturer__c, Nickname__c, Sub_Type__c/* ,  Payor_Name__c */, 
                                Lead_Birth_Date__c, AccountNumber, G6_Starter_Kit_Ship_Date__c, G6_Instructions_Shipped__c, Tax_Exempt__c, Number_of_Active_SSIP_Rules__c, Subscription_Pending_Payments__c,
                                Credit_Hold__c, CA_First_Nation_ID__c, CA_BC_State_PST_Registration_Number__c, CA_GST_HST_Registration_Number__c, CA_MB_State_PST_Registration_Number__c,
                                CA_QC_State_PST_Registration_Number__c, CA_SK_State_PST_Registration_Number__c
                                FROM Account where Id in :accountIds/*:pds.keySet() *//* AND (Record_Type_Name__c like 'CA%' OR Record_Type_Name__c like 'CH%'
                                                                                           OR Record_Type_Name__c like 'AT%') */];
        for(Account ac : accts) {
            String value = '';
            CRM_Account_Address_Event_Out__e ev = new CRM_Account_Address_Event_Out__e();    ////// changed event structure
            List<metaDataEntry> mdtList = new List<metaDataEntry>();
            Boolean pac = ac.IsPersonAccount;
            ev.version__c = version;
            ev.eventDate__c =  String.valueOf(ac.LastModifiedDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ')); //String.valueOf(System.now());
            ev.entityType__c = 'account';
            ev.eventSource__c = 'crm';
            ev.eventSourceID__c = ac.Id;
            ev.operation__c = action == 'registered' ? 'create' : action;      // Kludge to handle the unusual structure of registered events.
            ev.stage__c = action == 'registered' ? 'registered' : 'confirmed';
            ev.systemOfOrigin__c = ac.System_Of_Origin__c != null ? ac.System_Of_Origin__c : ev.eventSource__c;
            ev.systemOfOriginID__c = ac.System_Of_Origin_Id__c != null ? ac.System_Of_Origin_Id__c : ev.eventSourceID__c;
            ev.parentSystemOfOriginID__c = '';   
            ev.author__c = ac.LastModifiedBy.Name;
            if (ac.Record_Type_Name__c.startsWithIgnoreCase('DE') || ac.Record_Type_Name__c.startsWithIgnoreCase('GB') || ac.Record_Type_Name__c.startsWithIgnoreCase('IE') ||
                ac.Record_Type_Name__c.startsWithIgnoreCase('CH') || ac.Record_Type_Name__c.startsWithIgnoreCase('AT') || ac.Record_Type_Name__c.startsWithIgnoreCase('CA') || 
                ac.Record_Type_Name__c.startsWithIgnoreCase('BE') || ac.Record_Type_Name__c.startsWithIgnoreCase('SI') || ac.Record_Type_Name__c.startsWithIgnoreCase('NL') ||
                ac.Record_Type_Name__c.startsWithIgnoreCase('LU')) 
                ev.accountType__c = ac.Record_Type_Name__c.substring(3).toLowerCase(); 
            else if (ac.Record_Type_Name__c.startsWithIgnoreCase('International Distributor')) ev.accountType__c = 'distributor';
            else if (ac.Record_Type_Name__c.startsWithIgnoreCase('INTL Payor')) ev.accountType__c = 'payor';
            else if (ac.Record_Type_Name__c.containsIgnoreCase('clinic')) ev.accountType__c = 'clinic';
            else ev.accountType__c = ac.Record_Type_Name__c.toLowerCase();
            ev.isActive__c = !ac.Inactive__c;
            ev.accountID__c= ac.Id;
            ev.referenceNumber__c = ac.AccountNumber;
			ev.accountSubType__c = ac.Sub_Type__c != null ? ac.Sub_Type__c.toLowerCase():ac.Sub_Type__c;   // Made it lower case to match
            if (!pac) ev.businessName__c= ac.Name;
            if (pac) ev.firstName__c= ac.FirstName;
            if (pac) ev.middleName__c= ac.MiddleName;
            if (pac) ev.lastName__c = ac.LastName;
            if (pac) ev.nickName__c = ac.Nickname__c;
            if (!pac) ev.businessEmail__c = ac.Organzation_Email__c;
            if (pac) ev.personalemail__c = ac.PersonEmail;
            ev.workPhone__c = ac.Phone;
            if (pac) ev.homePhone__c = ac.PersonHomePhone;
            if (pac) ev.mobilePhone__c = ac.PersonMobilePhone;
            if (pac) ev.otherPhone__c= ac.PersonOtherPhone;
            ev.fax__c = ac.Fax;
            
            if (pac) ev.birthDate__c = ac.PersonBirthdate == null && action == 'create' && ac.Lead_Birth_Date__c != null ? 
                ac.Lead_Birth_Date__c.year()+'-'+String.valueOf(ac.Lead_Birth_Date__c.month()).leftpad(2,'0')+'-'+String.valueOf(ac.Lead_Birth_Date__c.day()).leftpad(2,'0') :
            	ac.PersonBirthdate != null ? ac.PersonBirthdate.year()+'-'+String.valueOf(ac.PersonBirthdate.month()).leftpad(2,'0')+'-'+String.valueOf(ac.PersonBirthdate.day()).leftpad(2,'0') : null;
            //ev.birthDate__c = ev.birthDate__c.format();			// To get the date in YYYY-MM-DD format and suppressing 00:00:00. Vijay Adusumilli 09/20/2019
            if (pac) ev.gender__c = String.isBlank(ac.Gender__c) ? null : ac.Gender__c.toLowerCase();
            if (pac) ev.languageCode__c = ac.Preferred_Language__c;    // Preferred_Language is being mapped.
            // 2.0 Canonical Addition -- BEGIN
            ev.taxExempt__c = ac.Tax_Exempt__c;
            //Metadata 
            if (pac) {
                value = ac.G6_Instructions_Shipped__c == true ? 'true' : 'false';  mdtList.add(new metaDataEntry('g6ifuSent', value));
                value = ac.G6_Starter_Kit_Ship_Date__c != null ? ac.G6_Starter_Kit_Ship_Date__c.formatGMT('yyyy-MM-dd') : '';  mdtList.add(new metaDataEntry('g6StarterKitPurchaseDate', value));
                value = (ac.Number_of_Active_SSIP_Rules__c  == null || ac.Number_of_Active_SSIP_Rules__c  == 0) ? 'inactive' : 
                		(ac.Number_of_Active_SSIP_Rules__c  > 0) && (ac.Subscription_Pending_Payments__c == null || ac.Subscription_Pending_Payments__c == 0) ? 'active' : 
                		(ac.Subscription_Pending_Payments__c != null && ac.Subscription_Pending_Payments__c > 0) ? 'suspended' : 'unknown'; 
                		mdtList.add(new metaDataEntry('g6SubscriptionStatus', value));
                value = (ac.Credit_Hold__c == true) ? 'true' : 'false'; mdtList.add(new metaDataEntry('onCreditHold', value));
                if (String.isNotBlank(ac.CA_First_Nation_ID__c))  mdtList.add(new metaDataEntry('CA_First_Nation_ID', ac.CA_First_Nation_ID__c));
                ev.metadata__c = JSON.serialize(mdtList);
            } else if (ac.Record_Type_Name__c.startsWithIgnoreCase('CA') && !pac && (String.isNotBlank(ac.CA_BC_State_PST_Registration_Number__c) || String.isNotBlank(ac.CA_MB_State_PST_Registration_Number__c) ||
                                                            String.isNotBlank(ac.CA_QC_State_PST_Registration_Number__c) || String.isNotBlank(ac.CA_SK_State_PST_Registration_Number__c) ||
                                                            String.isNotBlank(ac.CA_GST_HST_Registration_Number__c)) )
                {
                    value = String.isNotBlank(ac.CA_BC_State_PST_Registration_Number__c) ? ac.CA_BC_State_PST_Registration_Number__c : 'null';  mdtList.add(new metaDataEntry('CA_BC_State_PST_ID', value));
                    value = String.isNotBlank(ac.CA_MB_State_PST_Registration_Number__c) ? ac.CA_MB_State_PST_Registration_Number__c : 'null';  mdtList.add(new metaDataEntry('CA_MB_State_PST_ID', value));
                    value = String.isNotBlank(ac.CA_QC_State_PST_Registration_Number__c) ? ac.CA_QC_State_PST_Registration_Number__c : 'null';  mdtList.add(new metaDataEntry('CA_QC_State_PST_ID', value));
                    value = String.isNotBlank(ac.CA_SK_State_PST_Registration_Number__c) ? ac.CA_SK_State_PST_Registration_Number__c : 'null';  mdtList.add(new metaDataEntry('CA_SK_State_PST_ID', value));
                    value = String.isNotBlank(ac.CA_GST_HST_Registration_Number__c) ? ac.CA_GST_HST_Registration_Number__c : 'null';  mdtList.add(new metaDataEntry('CA_GST_HST_ID', value));
                    ev.metadata__c = JSON.serialize(mdtList);
                }
            else
                ev.metadata__c = null;
            // 2.0 Canonical Addition -- END
            ev.countryCode__c = ac.BillingCountryCode != null ? ac.BillingCountryCode : ac.Record_Type_Name__c.left(2) ;
            ev.country__c = ac.BillingCountry;
            ev.dexcomID__c = ac.Dexcom_ID__c;
            ev.prescriberID__c = ac.Prescriber_Id__c;
            ev.pumpManufacturer__c = ac.Pump_Manufacturer__c;
            if (pac) ev.payorName__c = ac.Payor__r.Name;
            ev.guardianFirstName__c = ac.Parent_Guardian_First_Name__c;
            ev.guardianLastName__c = ac.Parent_Guardian_Last_Name__c;
            ev.emailOptin__c = String.isBlank(ac.Email_Opt_In_List__c) ? '' : ac.Email_Opt_In_List__c == 'True' ? 'true' : ac.Email_Opt_In_List__c == 'False' ? 'false' : '';
            ev.smsOptin__c = String.isBlank(ac.SMS_Opt_In_List__c) ? '' : ac.SMS_Opt_In_List__c == 'True' ? 'true' : ac.SMS_Opt_In_List__c == 'False' ? 'false' : '';
            ev.mailOptin__c = String.isBlank(ac.Mail_Opt_In_List__c) ? '' : ac.Mail_Opt_In_List__c == 'True' ? 'true' : ac.Mail_Opt_In_List__c == 'False' ? 'false' : '';
            ev.phoneOptin__c = String.isBlank(ac.Phone_Opt_In_List__c) ? '' : ac.Phone_Opt_In_List__c == 'True' ? 'true' : ac.Phone_Opt_In_List__c == 'False' ? 'false' : '';
            ev.loginEnabled__c  = !ac.SFCC_Login_Enabled__c;
            if(accountsMergeMap != null) {
                set<id> lostAccountIdsSet = new Set<Id>();
                for(Id lostAccId : accountsMergeMap.keyset()) {
                    if (accountsMergeMap.get(lostAccId) == ac.Id) lostAccountIdsSet.add(lostAccId);
                }
                List<Id> lostAccountIdsList = new List<Id>(lostAccountIdsSet);
                if (lostAccountIdsSet.size() > 1) {
                    Integer element = 0;
                    for(Id lostAccs : lostAccountIdsSet) {
                        if (element == 0) {
                            ev.accountIDToMergeTo__c = lostAccountIdsList[0];
                    		eventList.add(ev);
                            element = 1;
                        } else {
                            CRM_Account_Address_Event_Out__e evAdd = ev  ;
                            evAdd.accountIDToMergeTo__c = lostAccountIdsList[0];
                    		eventList.add(evAdd);
                        }
                    }
                } else {
                    ev.accountIDToMergeTo__c = lostAccountIdsList[0];
                    eventList.add(ev);
                }
                // ev.accountIDToMergeTo__c = accountsMergeMap.get(ac.Id);
            } else {
                eventList.add(ev);
            }
        }
        List<Account> updAccts = new List<Account>();
        Set<ID> updIds = new Set<ID>();
        if (eventList.size() > 0) {
            List<Database.SaveResult> svrs;
            if (Test.isRunningTest()  && action != 'registered') {
                List<CRM_Account_Address_Event_Out__e> evList = new List<CRM_Account_Address_Event_Out__e> {eventList[0]};
                svrs = EventBus.publish(evList);
            }
            else 	svrs = EventBus.publish(eventList);
            Integer i = -1; 
            for (Database.SaveResult svr : svrs) {
                i++;
                if (svr.isSuccess()) {
                    updIds.add(eventList[i].accountID__c);
                    
                    ErrorUtility.LogErrorWithEvent('Publish', 'PEClsHandleAccountEvents.publishAccountEvents', 'Successfully published Account Event.',  'account', eventList[i].eventSourceID__c, 
                     'Account Id: ' + eventList[i].eventSourceID__c, eventList[i].eventSourceID__c, 'Success Log', String.valueOf(eventList[i]));
                } else {
                    // write error msg
                  ErrorUtility.LogErrorWithEvent('Publish', 'PEClsHandleAccountEvents.publishAccountEvents', 'Error in publishing Account Event.',  'account', eventList[i].eventSourceID__c, 
                     'Account Id: ' + eventList[i].eventSourceID__c +' could not be published. Error: ' + svr.getErrors(), eventList[i].eventSourceID__c, 'Informational', String.valueOf(eventList[i]));
                  system.debug('Error in publishing Account Event. Error: ' + svr.getErrors());
                    system.debug('Id: ' + svr.getId());
                    system.debug('Op: ' + eventList[i].operation__c + ', Stage: ' +   eventList[i].stage__c);
                }
        }
        }
    }
    public class metaDataEntry{
        public String name;
        public String value;
        public metaDataEntry(String name, String value){
            this.name =  name;
            this.value = value;
        }
    }
    public class MetaData {
        public metaDataEntry[] entries;
    }
}