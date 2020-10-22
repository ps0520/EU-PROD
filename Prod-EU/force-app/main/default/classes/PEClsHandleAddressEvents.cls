public class PEClsHandleAddressEvents {
    public static final String version = '2.0';  // version of the canonical
    public static void handleIncomingEvents(List<CRM_Address_Event__e> incEvs) {
        List<CRM_Address_Event__e> consumeCreateAddList = new List<CRM_Address_Event__e>();
        List<CRM_Address_Event__e> consumeUpdateAddList = new List<CRM_Address_Event__e>();
        for (CRM_Address_Event__e ev : incEvs) {
            //For debugging purposes - next line
            system.debug('Incoming Address Event: ' + ev);
            if ( ev.operation__c.containsIgnoreCase('CREATE') && ev.stage__c.containsIgnoreCase('PENDING')  )
                consumeCreateAddList.add(ev); 
            if ( ev.operation__c.containsIgnoreCase('UPDATE') && ev.stage__c.containsIgnoreCase('PENDING')  )
                consumeUpdateAddList.add(ev); 
        }
        if (consumeCreateAddList.size() > 0) consumeAddressCreate(consumeCreateAddList, 'create');
        if (consumeUpdateAddList.size() > 0) consumeAddressUpdate(consumeUpdateAddList, 'update');
    }
        
    public static void sendUpdatedAddresses(set<Id> ids) {
        	publishAddresses(ids, 'update');
    }
    
    public static void sendCreatedAddresses(set<Id> ids) {
        	publishAddresses(ids, 'create');
    }

	public static void consumeAddressCreate(List<CRM_Address_Event__e> consumeEvs, String op) {
        List<Address__c> adds = new List<Address__c>();
        Address__c add = new Address__c();
        List<String> actSosIds = new List<String>();
        Map<String,ID> dupAddresses = new Map<String, ID>();
        Set<String> uniqueSO = new Set<String>();
        for(CRM_Address_Event__e ev : consumeEvs) {
            if (String.isBlank(ev.accountID__c) || ev.accountID__c == 'null' ) {
                if (!String.isBlank(ev.systemOfOrigin__c) && !String.isBlank(ev.parentSystemOfOriginID__c)) actSosIds.add(ev.systemOfOrigin__c.trim() + ev.parentSystemOfOriginID__c.trim());
                    else {  // Publish an error message as this address can't be related to any account as the Origin data is missing
                    ErrorUtility.LogError('Consume', 'PEClsHandleAddressEvents.consumeAddressCreate', 'Error in Consuming Address Create Operations.', 'address', consumeEvs[0].eventSourceID__c, 
                                          'Unable to create an Address as there is no associated Account or related SoS info. eventSource: ' + ev.eventSource__c + ', eventSourceID: ' + ev.eventSourceID__c + ' Will not be processed.' , 
                                          consumeEvs[0].eventSourceID__c, 'Informational');
                    }
            } 
            uniqueSO.add(ev.systemOfOrigin__c.trim() + ev.systemOfOriginID__c.trim() );
        }
        List<Address__c> existingAddresses = [Select ID, SOS_Unique_ID__c from Address__c Where SOS_Unique_ID__c in :uniqueSO];
        if (existingAddresses.size() > 0) {
            for(Address__c a : existingAddresses) {
                dupAddresses.put(a.SOS_Unique_ID__c, a.Id);
                  	ErrorUtility.LogError('Consume', 'PEClsHandleAddressEvents.consumeAddressCreate', 'Error in Consuming Address Create Operations.', 'address', consumeEvs[0].eventSourceID__c, 
                                          'Duplicate messages: ' + a.SOS_Unique_ID__c + ' Will not be processed.' , consumeEvs[0].eventSourceID__c, 'Informational');
            }
        }
        if (existingAddresses.size() == uniqueSO.size()) { 		// all duplicate Addresses. Write error message and exit
            //write error message
            if (existingAddresses.size() > 1) ErrorUtility.LogError('Consume', 'PEClsHandleAddressEvents.consumeAddressCreate', 'Error in Consuming Address Create Operations.', 'address', consumeEvs[0].eventSourceID__c, 
                      'Received all duplicate message(s). No Addresses event(s) will be processed.' , consumeEvs[0].eventSourceID__c, 'Fatal Error - Bailing out');
            system.debug('All duplicate addresses received. Can\'t create them. Bailing out...');
            return;
        }
        List<Account> acts = new List<Account>();
        Map<String, ID> sosActMap = new Map<String, ID>();
        if (actSosIds.size() > 0 ) {
            acts = [Select SOS_Unique_ID__c, ID from Account where SOS_Unique_ID__c in :actSosIds];
            for (Account a: acts) sosActMap.put(a.SOS_Unique_ID__c, a.Id);
        }
        map<String, Id> recTypeMap = new map<String, Id>();
        List<RecordType> rs = [SELECT Id, developerName FROM RecordType where SobjectType= 'Address__c' AND isactive = true ]; // Will have to be updated
        for (RecordType r : rs) recTypeMap.put(r.developerName, r.Id);
        for(CRM_Address_Event__e ev : consumeEvs) {
            if ( dupAddresses.size() > 0 && dupAddresses.containsKey(ev.systemOfOrigin__c.trim()+ev.systemOfOriginID__c.trim())) {
                //write dup error message
                ErrorUtility.LogError('Consume', 'PEClsHandleAddressEvents.consumeAddressCreate', 'Error in Consuming Address Create Operations.', 'address', consumeEvs[0].eventSourceID__c, 
                     'Duplicate message with systemOfOrigin: ' + ev.systemOfOrigin__c.trim() + ', systemOfOriginID: '+ ev.systemOfOriginID__c.trim() + ' Will not be processed.' , consumeEvs[0].eventSourceID__c, 'Informational');
                system.debug('Duplicate Address. Event: ' + ev);
                continue;
            }
            if ( (String.isBlank(ev.accountID__c) || ev.accountID__c == 'null') && !(sosActMap.containsKey(ev.systemOfOrigin__c.trim()+ev.parentSystemOfOriginID__c.trim()))) {
                if (EventBus.TriggerContext.currentContext().retries < 5) {
                    // Condition isn't met, so try again later.
                    throw new EventBus.RetryableException('Error happened, so retrying the trigger again.');
                } else {
                    ErrorUtility.LogError('Consume', 'PEClsHandleAddressEvents.consumeAddressCreate', 'Error in Consuming Address Create Operations.', 'address', consumeEvs[0].eventSourceID__c, 
                         'No way to Identify the Account related to this address. parentSystemOfOriginId: ' + ev.parentSystemOfOriginID__c + ' may not exist. systemOfOrigin: ' + ev.systemOfOrigin__c.trim() + ', systemOfOriginID: '+ ev.systemOfOriginID__c.trim() + ' Will not be processed.' , consumeEvs[0].eventSourceID__c, 'Informational');
                    continue;
                }
            }
            add = new Address__c();
            if (!(String.isBlank(ev.accountID__c) || ev.accountID__c == 'null'))   add.Account__c = ev.accountID__c;
            else add.Account__c = sosActMap.get(ev.systemOfOrigin__c.trim()+ev.parentSystemOfOriginID__c.trim());
            if (!(String.isBlank(ev.address1__c) || ev.address1__c == 'null')) add.Address_Line_1__c = ev.address1__c;
            if (!(String.isBlank(ev.address2__c) || ev.address2__c == 'null')) add.Address_Line_2__c = ev.address2__c;
            if (!(String.isBlank(ev.address3__c) || ev.address3__c == 'null')) add.Address_Line_3__c = ev.address3__c;
            if (ev.addressType__c == 'billing') add.Type__c = 'Bill To'; else if (ev.addressType__c == 'shipping') add.Type__c = 'Ship To'; else { 
                //write error - don't know what type of address.
                ErrorUtility.LogError('Consume', 'PEClsHandleAddressEvents.consumeAddressCreate', 'Error in Consuming Address Create Operations.', 'address', consumeEvs[0].eventSourceID__c, 
                     'Can\'t handle Address type of: ' + ev.addressType__c + ' from eventSource: '  + ev.eventSource__c + ', eventSourceID: '+ ev.eventSourceID__c + ' Will not be processed.' , consumeEvs[0].eventSourceID__c, 'Informational');                continue;
            }
            
            if (!(String.isBlank(ev.city__c) || ev.city__c == 'null')) add.City__c = ev.city__c;
            if (!(String.isBlank(ev.country__c) || ev.country__c == 'null')) add.Country__c = ev.country__c;
            else {
                if(ev.countryCode__c == 'null' || String.isBlank(ev.countryCode__c)) {
                    //write error - Both Country and countryCode are null
                     ErrorUtility.LogError('Consume', 'PEClsHandleAddressEvents.consumeAddressCreate', 'Error in Consuming Address Create Operations.', 'address', consumeEvs[0].eventSourceID__c, 
                         'There is no Country in the event from eventSource: '  + ev.eventSource__c + ', eventSourceID: '+ ev.eventSourceID__c + ' Will not be processed.' , consumeEvs[0].eventSourceID__c, 'Informational');
                   	continue;
                } else {
                    if      (ev.countryCode__c == 'DE') add.Country__c = 'Germany'; 
                    else if (ev.countryCode__c == 'CA') add.Country__c = 'Canada'; 
                    else if (ev.countryCode__c == 'IE') add.Country__c = 'Ireland'; 
                    else if (ev.countryCode__c == 'GB') add.Country__c = 'United Kingdom'; 
                    else if (ev.countryCode__c == 'CH') add.Country__c = 'Switzerland';
                    else if (ev.countryCode__c == 'LI') add.Country__c = 'Liechtenstein';
                    else if (ev.countryCode__c == 'AT') add.Country__c = 'Austria'; 
					else if  (ev.countryCode__c == 'AE' ) add.Country__c = 'United Arab Emirates';
                    else if  (ev.countryCode__c == 'BH' ) add.Country__c = 'Bahrain'; 
                    else if  (ev.countryCode__c == 'CL' ) add.Country__c = 'Chile'; 
                    else if  (ev.countryCode__c == 'CZ' ) add.Country__c = 'Czech Republic'; 
                    else if  (ev.countryCode__c == 'DK' ) add.Country__c = 'Denmark'; 
                    else if  (ev.countryCode__c == 'ES' ) add.Country__c = 'Spain'; 
                    else if  (ev.countryCode__c == 'FI' ) add.Country__c = 'Finland'; 
                    else if  (ev.countryCode__c == 'FR' )  add.Country__c = 'France'; 
                    else if  (ev.countryCode__c == 'HK' ) add.Country__c = 'Hong Kong'; 
                    else if  (ev.countryCode__c == 'HU' ) add.Country__c = 'Hungary'; 
                    else if  (ev.countryCode__c == 'IL' ) add.Country__c = 'Israel'; 
                    else if  (ev.countryCode__c == 'IN' ) add.Country__c = 'India'; 
                    else if  (ev.countryCode__c == 'IT' ) add.Country__c = 'Italy'; 
                    else if  (ev.countryCode__c == 'JO' ) add.Country__c = 'Jordan'; 
                    else if  (ev.countryCode__c == 'JP' ) add.Country__c = 'Japan'; 
                    else if  (ev.countryCode__c == 'KR' ) add.Country__c = 'Korea'; 
                    else if  (ev.countryCode__c == 'KW' ) add.Country__c = 'Kuwait'; 
                    else if  (ev.countryCode__c == 'LB' ) add.Country__c = 'Lebanon'; 
                    else if  (ev.countryCode__c == 'NL' ) add.Country__c = 'Netherlands'; 
                    else if  (ev.countryCode__c == 'NO' ) add.Country__c = 'Norway'; 
                    else if  (ev.countryCode__c == 'NZ' ) add.Country__c = 'New Zealand'; 
                    else if  (ev.countryCode__c == 'OM' ) add.Country__c = 'Oman'; 
                    else if  (ev.countryCode__c == 'PL' ) add.Country__c = 'Poland'; 
                    else if  (ev.countryCode__c == 'QA' ) add.Country__c = 'Qatar'; 
                    else if  (ev.countryCode__c == 'SA' ) add.Country__c = 'Saudi Arabia'; 
                    else if  (ev.countryCode__c == 'SE' ) add.Country__c = 'Sweden'; 
                    else if  (ev.countryCode__c == 'SI' ) add.Country__c = 'Slovenia'; 
                    else if  (ev.countryCode__c == 'TR' ) add.Country__c = 'Turkey'; 
                    else if  (ev.countryCode__c == 'ZA' ) add.Country__c = 'South Africa'; 
                    else if  (ev.countryCode__c == 'BE' ) add.Country__c = 'Belgium';  
                    else if  (ev.countryCode__c == 'RU' ) add.Country__c = 'Russian Federation';  
                    else if  (ev.countryCode__c == 'MT' ) add.Country__c = 'Malta';  
                    else if  (ev.countryCode__c == 'LU' ) add.Country__c = 'Luxembourg';  
                    else {
                        // add.Country__c = 'Unknown';
                        ErrorUtility.LogError('Consume', 'PEClsHandleAddressEvents.consumeAddressCreate', 'Error in Consuming Address Create Operations.', 'address', consumeEvs[0].eventSourceID__c, 
                            'Don\'t know how to process the countryCode: ' + ev.countryCode__c + ' in the event from eventSource: '  + ev.eventSource__c + ', eventSourceID: '+ ev.eventSourceID__c + ' Will not be processed.' , 
                                              consumeEvs[0].eventSourceID__c, 'Informational');
                        continue;
                	}
                }
            }
            String mappedCC = ev.countryCode__c;
            if (mappedCC == 'LI') mappedCC = 'CH'; 	//There is no separate Address Record type for Lichtenstein
            if (mappedCC == 'IE') mappedCC = 'UK';	//There is no separate Address Record type for Ireland
            if (mappedCC == 'GB') mappedCC = 'UK';	//There is no separate Address Record type for GB - UK!!!
            if (recTypeMap.containsKey(mappedCC +'_Address')) 
                    add.RecordTypeId = recTypeMap.get(mappedCC +'_Address');
            else if (String.isNotBlank(add.Country__c)) add.RecordTypeId = recTypeMap.get('DIST_Address');
            else {                   //acc.RecordTypeId = caConsumerRecordType; //Should actually throw error.
                ErrorUtility.LogError('Consume', 'PEClsHandleAddressEvents.consumeAddressCreate', 'Error in Consuming Address.', 'address', ev.eventSourceID__c, 
                                      'Received an Address Create event without a proper way to determine record type. eventSource: ' + ev.eventSource__c + ' eventSourceID: ' + ev.eventSourceID__c + '. Will not be processed.', 
                                      ev.eventSourceID__c, 'Informational');
                system.debug('Don\'t know how to handle the type of Operation: ' + op + ' Not processing this item: ' + ev);
                continue;
            }
            add.Inactive__c = !ev.isActive__c;
            add.Primary_Flag__c = ev.isPrimary__c;
            if (!(String.isBlank(ev.postalCode__c) || ev.postalCode__c == 'null')) add.Postal_Code__c = ev.postalCode__c;
            if (!(String.isBlank(ev.stateProvince__c) || ev.stateProvince__c == 'null')) add.State__c = ev.stateProvince__c;
            if (!(String.isBlank(ev.systemOfOrigin__c) || ev.systemOfOrigin__c == 'null')) add.System_Of_Origin__c = ev.systemOfOrigin__c;
            if (!(String.isBlank(ev.systemOfOriginID__c) || ev.systemOfOriginID__c == 'null')) add.System_Of_Origin_Id__c = ev.systemOfOriginID__c;
			add.SOS_Unique_ID__c = ev.systemOfOrigin__c.trim() + ev.systemOfOriginID__c.trim();
            add.isLocked__c = ev.isLocked__c;
            if (!(String.isBlank(ev.businessName__c) || ev.businessName__c == 'null')) add.Business_Name__c = ev.businessName__c;
            if (!(String.isBlank(ev.firstName__c) || ev.firstName__c == 'null')) add.First_Name__c = ev.firstName__c;
            if (!(String.isBlank(ev.lastName__c) || ev.lastName__c == 'null')) add.Last_Name__c = ev.lastName__c;
            if (!(String.isBlank(ev.primaryPhone__c) || ev.primaryPhone__c == 'null')) add.Primary_Phone__c = ev.primaryPhone__c;
            adds.add(add);
        }
        
        if (adds.size() > 0) {
            try {
                insert adds;
                for(Address__c a : adds)
                ErrorUtility.LogError('Consume', 'PEClsHandleAddressEvents.consumeAddressCreate', 'Successfully Added Address.',  'address', consumeEvs[0].eventSourceID__c, 
                     'Address Id: ' + a.Id, consumeEvs[0].eventSourceID__c, 'Success Log');
            }
            catch(DmlException de) {
                system.debug(de.getMessage());
                ErrorUtility.LogError('Consume', 'PEClsHandleAddressEvents.consumeAddressCreate', 'Error in Consuming Address Create Operations.', 'address', consumeEvs[0].eventSourceID__c, 
                     de.getMessage(), consumeEvs[0].eventSourceID__c, 'Fatal Error - Bailing out');
            }
        }
        //Set the SetResumeCheckpoint to the highest replayId
        String hrid = '';
        for(CRM_Address_Event__e ev : consumeEvs) if (hrid < ev.ReplayId) hrid = ev.ReplayId;
        system.debug('Setting the SetResumeChekpoint to ReplayId: ' + hrid);
        EventBus.TriggerContext.currentContext().setResumeCheckpoint(hrid);

    }
    
    public static void consumeAddressUpdate(List<CRM_Address_Event__e> consumeEvs, String op) {
        List<Address__c> adds = new List<Address__c>();
        Address__c add = new Address__c();
        List<String> addressSooIds = new List<String>();
        for(CRM_Address_Event__e ev : consumeEvs) {
            // Need addressID to update an address. If Address is not there, search based on systemOfOriginID of address.
            if (!(String.isBlank(ev.addressID__c) || ev.addressID__c == 'null') ) {
					if ( !(String.isBlank(ev.systemOfOrigin__c) || ev.systemOfOrigin__c == 'null') && !(String.isBlank(ev.systemOfOriginID__c) || ev.systemOfOriginID__c == 'null')) 
                        	addressSooIds.add(ev.systemOfOrigin__c.trim() + ev.systemOfOriginID__c.trim());
                    else {  // Publish an error message as this address can't be related to any account as the Origin data is missing
                        ErrorUtility.LogError('Consume', 'PEClsHandleAddressEvents.consumeAddressUpdate', 'Error in Consuming Address Update Operations.', 'address', consumeEvs[0].eventSourceID__c, 
                                          'Unable to update an Address as there is no associated Address Id or related SoS info. eventSource: ' + ev.eventSource__c + ', eventSourceID: ' + ev.eventSourceID__c + ' Will not be processed.' , 
                                          consumeEvs[0].eventSourceID__c, 'Informational');
                    }
            } 
        }
        List<Address__c> addressList = new List<Address__c>(); 
        Map<String, ID> sooAddressMap = new Map<String, ID>();
        if (addressSooIds.size() > 0 ) {
            addressList = [Select SOS_Unique_ID__c, ID from Address__c where SOS_Unique_ID__c in :addressSooIds];
            for (Address__c a: addressList) sooAddressMap.put(a.SOS_Unique_ID__c, a.Id);
        }
        for(CRM_Address_Event__e ev : consumeEvs) {
            add = new Address__c();
            if (ev.addressID__c == null && !(sooAddressMap.containsKey(ev.systemOfOrigin__c.trim()+ev.systemOfOriginID__c.trim()))) {
                //write error;
                continue;
            }
            if (ev.addressID__c != null)   add.Id = ev.addressID__c;
            else add.Id = sooAddressMap.get(ev.systemOfOrigin__c.trim()+ev.systemOfOriginID__c.trim());
            if (ev.address1__c != 'null') add.Address_Line_1__c = ev.address1__c;
            if (ev.address2__c != 'null') add.Address_Line_2__c = ev.address2__c;
            if (ev.address3__c != 'null') add.Address_Line_3__c = ev.address3__c;
            // Will ignore updates to Address Type.
            // if (ev.addressType__c == 'billing') add.Type__c = 'Bill To'; else if (ev.addressType__c == 'shipping') add.Type__c = 'Ship To';
            
            if (ev.city__c != 'null') add.City__c = ev.city__c;
            if (ev.country__c != 'null') add.Country__c = ev.country__c;
            else {
                if(ev.countryCode__c != 'null') {
                    if      (ev.countryCode__c == 'DE') add.Country__c = 'Germany'; 
                    else if (ev.countryCode__c == 'CA') add.Country__c = 'Canada'; 
                    else if (ev.countryCode__c == 'IE') add.Country__c = 'Ireland'; 
                    else if (ev.countryCode__c == 'GB') add.Country__c = 'United Kingdom'; 
                    else if (ev.countryCode__c == 'CH') add.Country__c = 'Switzerland'; 
					else if (ev.countryCode__c == 'LI') add.Country__c = 'Liechtenstein';
                    else if (ev.countryCode__c == 'AT') add.Country__c = 'Austria'; 
					else if  (ev.countryCode__c == 'AE' ) add.Country__c = 'United Arab Emirates';
                    else if  (ev.countryCode__c == 'BH' ) add.Country__c = 'Bahrain'; 
                    else if  (ev.countryCode__c == 'CL' ) add.Country__c = 'Chile'; 
                    else if  (ev.countryCode__c == 'CZ' ) add.Country__c = 'Czech Republic'; 
                    else if  (ev.countryCode__c == 'DK' ) add.Country__c = 'Denmark'; 
                    else if  (ev.countryCode__c == 'ES' ) add.Country__c = 'Spain'; 
                    else if  (ev.countryCode__c == 'FI' ) add.Country__c = 'Finland'; 
                    else if  (ev.countryCode__c == 'FR' )  add.Country__c = 'France'; 
                    else if  (ev.countryCode__c == 'HK' ) add.Country__c = 'Hong Kong'; 
                    else if  (ev.countryCode__c == 'HU' ) add.Country__c = 'Hungary'; 
                    else if  (ev.countryCode__c == 'IL' ) add.Country__c = 'Israel'; 
                    else if  (ev.countryCode__c == 'IN' ) add.Country__c = 'India'; 
                    else if  (ev.countryCode__c == 'IT' ) add.Country__c = 'Italy'; 
                    else if  (ev.countryCode__c == 'JO' ) add.Country__c = 'Jordan'; 
                    else if  (ev.countryCode__c == 'JP' ) add.Country__c = 'Japan'; 
                    else if  (ev.countryCode__c == 'KR' ) add.Country__c = 'Korea'; 
                    else if  (ev.countryCode__c == 'KW' ) add.Country__c = 'Kuwait'; 
                    else if  (ev.countryCode__c == 'LB' ) add.Country__c = 'Lebanon'; 
                    else if  (ev.countryCode__c == 'NL' ) add.Country__c = 'Netherlands'; 
                    else if  (ev.countryCode__c == 'NO' ) add.Country__c = 'Norway'; 
                    else if  (ev.countryCode__c == 'NZ' ) add.Country__c = 'New Zealand'; 
                    else if  (ev.countryCode__c == 'OM' ) add.Country__c = 'Oman'; 
                    else if  (ev.countryCode__c == 'PL' ) add.Country__c = 'Poland'; 
                    else if  (ev.countryCode__c == 'QA' ) add.Country__c = 'Qatar'; 
                    else if  (ev.countryCode__c == 'SA' ) add.Country__c = 'Saudi Arabia'; 
                    else if  (ev.countryCode__c == 'SE' ) add.Country__c = 'Sweden'; 
                    else if  (ev.countryCode__c == 'SI' ) add.Country__c = 'Slovenia'; 
                    else if  (ev.countryCode__c == 'TR' ) add.Country__c = 'Turkey'; 
                    else if  (ev.countryCode__c == 'ZA' ) add.Country__c = 'South Africa'; 
                    else if  (ev.countryCode__c == 'BE' ) add.Country__c = 'Belgium'; 
                    else if  (ev.countryCode__c == 'MT' ) add.Country__c = 'Malta'; 
                    else if  (ev.countryCode__c == 'LU' ) add.Country__c = 'Luxembourg'; 
                    else if  (ev.countryCode__c == 'RU' ) add.Country__c = 'Russian Federation'; 
                   else {
                        //add.Country__c = 'Unknown';
                        ErrorUtility.LogError('Consume', 'PEClsHandleAddressEvents.consumeAddressUpdate', 'Error in Consuming Address Update Operations.', 'address', consumeEvs[0].eventSourceID__c, 
                            'Don\'t know how to use the countryCode: ' + ev.countryCode__c + ' in the event from eventSource: '  + ev.eventSource__c + ', eventSourceID: '+ ev.eventSourceID__c + ' Not changing the existing country.' , 
                                              consumeEvs[0].eventSourceID__c, 'Informational');
                    }
                }
            }
            add.Inactive__c = !ev.isActive__c;
            add.Primary_Flag__c = ev.isPrimary__c;
            if (ev.postalCode__c != 'null') add.Postal_Code__c = ev.postalCode__c;
            if (ev.stateProvince__c != 'null') add.State__c = ev.stateProvince__c;
            // Not updating SoO in Update events.
            //if (ev.isPrimary__c != null) add.System_Of_Origin__c = ev.systemOfOrigin__c;
            //add.System_Of_Origin_Id__c = ev.systemOfOriginID__c;
            add.isLocked__c = ev.isLocked__c;
            if (ev.businessName__c != 'null') add.Business_Name__c = ev.businessName__c;
            if (ev.firstName__c != 'null') add.First_Name__c = ev.firstName__c;
            if (ev.lastName__c != 'null') add.Last_Name__c = ev.lastName__c;
            if (ev.primaryPhone__c != 'null') add.Primary_Phone__c = ev.primaryPhone__c;
            adds.add(add);
        }
        
        if (adds.size() > 0) {
            try {
                update adds;
                for(Address__c a : adds)
                ErrorUtility.LogError('Consume', 'PEClsHandleAddressEvents.consumeAddressUpdate', 'Successfully Updated Address.',  'address', consumeEvs[0].eventSourceID__c, 
                     'Address Id: ' + a.Id, consumeEvs[0].eventSourceID__c, 'Success Log');
            }
            catch(DmlException de) {
                system.debug(de.getMessage());
                ErrorUtility.LogError('Consume', 'PEClsHandleAddressEvents.consumeAddressUpdate', 'Error in Consuming Address Update Operations.', 'address', consumeEvs[0].eventSourceID__c, 
                     de.getMessage(), consumeEvs[0].eventSourceID__c, 'Fatal Error - Bailing out');
            }
        }
        //Set the SetResumeCheckpoint to the highest replayId
        String hrid = '';
        for(CRM_Address_Event__e ev : consumeEvs) if (hrid < ev.ReplayId) hrid = ev.ReplayId;
        system.debug('Setting the SetResumeChekpoint to ReplayId: ' + hrid);
        EventBus.TriggerContext.currentContext().setResumeCheckpoint(hrid);

    }
    	
    public static void publishAddresses(set<Id> id, String op) {

        //if (!PEClsHandleAddressEventsStatic.firstEventPublish()) return;
        List<CRM_Account_Address_Event_Out__e> adds = new List<CRM_Account_Address_Event_Out__e>();
        for(Address__c a : [ select Account__c, ID, Type__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, city__c, country__c,
            Postal_Code__c, State__c, Inactive__c, LastModifiedBy.Name, LastModifiedDate, Primary_Flag__c,  System_Of_Origin_Id__c, System_Of_Origin__c, 
            Business_Name__c,   isLocked__c,  Record_Type_Name__c, Primary_Phone__c, First_Name__c , Last_Name__c, Account__r.System_Of_Origin_Id__c,
            Account__r.Tax_Exempt__c, Account__r.Tax_Registration_Number__c
            from Address__c where Id in :id /* AND Country__c in ('Canada', 'Switzerland', 'Austria') */]) {
            	CRM_Account_Address_Event_Out__e ae = new CRM_Account_Address_Event_Out__e();
                // Header
                ae.version__c = version;
                //ae.eventDate__c =  String.valueOf(a.LastModifiedDate); //String.valueOf(System.now());
                ae.eventDate__c =  String.valueOf(a.LastModifiedDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
                ae.entityType__c = 'address';
                ae.eventSource__c = 'crm';
                ae.eventSourceID__c = a.Id;
                ae.operation__c = op;
                ae.stage__c = 'confirmed';
                ae.systemOfOrigin__c = a.System_Of_Origin__c != null ? a.System_Of_Origin__c : 'crm';   // Handling it this way so that when Address is added on SF it does not go as null
                ae.systemOfOriginID__c = a.System_Of_Origin_Id__c != null ? a.System_Of_Origin_Id__c : a.Id;
                //ae.parentSystemOfOriginID__c = /* a.Account__r.System_Of_Origin_Id__c; */ String.isBlank(a.Account__r.System_Of_Origin_Id__c) ?   a.Account__c : a.Account__r.System_Of_Origin_Id__c; ****** Seems to be a Salesforce Bug
                String psosid = '';
                if (String.isBlank(a.Account__r.System_Of_Origin_Id__c))
                    psosid = a.Account__c;
                else psosid = a.Account__r.System_Of_Origin_Id__c;
                ae.parentSystemOfOriginID__c = psosid; //a.Account__r.System_Of_Origin_Id__c; 
                ae.author__c = a.LastModifiedBy.Name;
                //End of Header
            	ae.accountId__c = a.Account__c;
                ae.addressId__c = a.Id;
                ae.taxExempt__c = a.Account__r.Tax_Exempt__c;
                ae.taxRegistrationNumber__c = a.Account__r.Tax_Registration_Number__c;
                ae.isActive__c = !a.Inactive__c;
                ae.isPrimary__c = a.Primary_Flag__c;
                ae.isLocked__c = a.isLocked__c;
                if (a.Type__c == 'Bill To') ae.addressType__c = 'billing'; else if (a.Type__c == 'Ship To') ae.addressType__c = 'shipping';
                ae.businessName__c = a.Business_Name__c;
                ae.firstName__c = a.First_Name__c;
                ae.lastName__c = a.Last_Name__c;
                ae.address1__c = a.Address_Line_1__c;
                ae.address2__c = a.Address_Line_2__c;
                ae.address3__c = a.Address_Line_3__c;
                ae.city__c = a.City__c;
                ae.stateProvince__c = a.State__c != 'None' ? a.State__c : null;    // Kafka and/OSC can't handle None as a value for state. Vijay July 26, 2019.
                ae.postalCode__c = a.Postal_Code__c;
                if          (a.Country__c == 'Germany') ae.countryCode__c = 'DE'; 
                    else if (a.Country__c == 'Canada') ae.countryCode__c = 'CA'; 
                    else if (a.Country__c == 'Ireland') ae.countryCode__c = 'IE';
                    else if (a.Country__c == 'United Kingdom') ae.countryCode__c = 'GB';
                    else if (a.Country__c == 'Switzerland') ae.countryCode__c = 'CH';
					else if (a.Country__c == 'Liechtenstein') ae.countryCode__c = 'LI';
                    else if (a.Country__c == 'Austria') ae.countryCode__c = 'AT'; 
                    else if (a.Country__c == 'United Arab Emirates') ae.countryCode__c = 'AE'; 
                    else if (a.Country__c == 'Bahrain') ae.countryCode__c = 'BH'; 
                    else if (a.Country__c == 'Chile') ae.countryCode__c = 'CL'; 
                    else if (a.Country__c == 'Czech Republic') ae.countryCode__c = 'CZ'; 
                    else if (a.Country__c == 'Denmark') ae.countryCode__c = 'DK'; 
                    else if (a.Country__c == 'Spain') ae.countryCode__c = 'ES'; 
                    else if (a.Country__c == 'Finland') ae.countryCode__c = 'FI'; 
                    else if (a.Country__c == 'France') ae.countryCode__c = 'FR'; 
                    else if (a.Country__c == 'Hong Kong') ae.countryCode__c = 'HK'; 
                    else if (a.Country__c == 'Hungary') ae.countryCode__c = 'HU'; 
                    else if (a.Country__c == 'Israel') ae.countryCode__c = 'IL'; 
                    else if (a.Country__c == 'India') ae.countryCode__c = 'IN'; 
                    else if (a.Country__c == 'Italy') ae.countryCode__c = 'IT'; 
                    else if (a.Country__c == 'Jordan') ae.countryCode__c = 'JO'; 
                    else if (a.Country__c == 'Japan') ae.countryCode__c = 'JP'; 
                    else if (a.Country__c == 'Korea') ae.countryCode__c = 'KR'; 
                    else if (a.Country__c == 'Kuwait') ae.countryCode__c = 'KW'; 
                    else if (a.Country__c == 'Lebanon') ae.countryCode__c = 'LB'; 
                    else if (a.Country__c == 'Netherlands') ae.countryCode__c = 'NL'; 
                    else if (a.Country__c == 'Norway') ae.countryCode__c = 'NO'; 
                    else if (a.Country__c == 'New Zealand') ae.countryCode__c = 'NZ'; 
                    else if (a.Country__c == 'Oman') ae.countryCode__c = 'OM'; 
                    else if (a.Country__c == 'Poland') ae.countryCode__c = 'PL'; 
                    else if (a.Country__c == 'Qatar') ae.countryCode__c = 'QA'; 
                    else if (a.Country__c == 'Saudi Arabia') ae.countryCode__c = 'SA'; 
                    else if (a.Country__c == 'Sweden') ae.countryCode__c = 'SE'; 
                    else if (a.Country__c == 'Slovenia') ae.countryCode__c = 'SI'; 
                    else if (a.Country__c == 'Turkey') ae.countryCode__c = 'TR'; 
                    else if (a.Country__c == 'South Africa') ae.countryCode__c = 'ZA'; 
                    else if (a.Country__c == 'Belgium') ae.countryCode__c = 'BE'; 
                    else if (a.Country__c == 'Malta') ae.countryCode__c = 'MT'; 
                    else if (a.Country__c == 'Luxembourg') ae.countryCode__c = 'LU';                 	
                    else if (a.Country__c == 'Russian Federation') ae.countryCode__c = 'RU'; 
                    else ae.countryCode__c = 'ZZ';
                if (ae.countryCode__c == 'CA' && String.isNotBlank(ae.stateProvince__c)) {
                    if (ae.stateProvince__c.equalsIgnoreCase('Alberta')) ae.stateProvince__c = 'AB';
                    if (ae.stateProvince__c.equalsIgnoreCase('British Columbia')) ae.stateProvince__c = 'BC';
                    if (ae.stateProvince__c.equalsIgnoreCase('Manitoba')) ae.stateProvince__c = 'MB';
                    if (ae.stateProvince__c.equalsIgnoreCase('New Brunswick')) ae.stateProvince__c = 'NB';
                    if (ae.stateProvince__c.equalsIgnoreCase('Newfoundland and Labrador')) ae.stateProvince__c = 'NL';
                    if (ae.stateProvince__c.equalsIgnoreCase('Northwest Territories')) ae.stateProvince__c = 'NT';
                    if (ae.stateProvince__c.equalsIgnoreCase('Nova Scotia')) ae.stateProvince__c = 'NS';
                    if (ae.stateProvince__c.equalsIgnoreCase('Nunavut')) ae.stateProvince__c = 'NU';
                    if (ae.stateProvince__c.equalsIgnoreCase('Ontario')) ae.stateProvince__c = 'ON';
                    if (ae.stateProvince__c.equalsIgnoreCase('Prince Edward Island')) ae.stateProvince__c = 'PE';
                    if (ae.stateProvince__c.equalsIgnoreCase('Quebec')) ae.stateProvince__c = 'QC';
                    if (ae.stateProvince__c.equalsIgnoreCase('Saskatchewan')) ae.stateProvince__c = 'SK';
                    if (ae.stateProvince__c.equalsIgnoreCase('Yukon Territories')) ae.stateProvince__c = 'YT';
                    if (ae.stateProvince__c.equalsIgnoreCase('Yukon')) ae.stateProvince__c = 'YT';
                }
                ae.country__c = a.Country__c;
                ae.primaryPhone__c = a.Primary_Phone__c;
                adds.add(ae);
        }
        if (adds.size() > 0) {
            List<Database.SaveResult> svrs = EventBus.publish(adds);
            Integer i = -1; 
        	for (Database.SaveResult svr : svrs) {
                i++;
                if (svr.isSuccess()) {
                    ErrorUtility.LogErrorWithEvent('Publish', 'PEClsHandleAddressEvents.publishAddresses', 'Successfully published Address Event.',  'address', adds[i].eventSourceID__c, 
                     'Address Id: ' + adds[i].eventSourceID__c, adds[i].eventSourceID__c, 'Success Log', String.valueOf(adds[i]));
                } else {
                    ErrorUtility.LogError('Publish', 'PEClsHandleAddressEvents.publishAddresses', 'Error in publishing Address Event.',  'address', adds[i].eventSourceID__c, 
                     'Address Id: ' + adds[i].eventSourceID__c +' could not be published. Error: ' + svr.getErrors(), adds[i].eventSourceID__c, 'Informational');
                }
            }
         }
    }
}