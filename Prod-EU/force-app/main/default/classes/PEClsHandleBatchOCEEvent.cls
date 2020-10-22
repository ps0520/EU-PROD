global class PEClsHandleBatchOCEEvent implements Database.batchable<Sobject>, Database.AllowsCallouts,Database.RaisesPlatformEvents  {//
   
    private List<Sample_Order_Request_Event__e> lstOCEAccEvent;
    global PEClsHandleBatchOCEEvent(List<Sample_Order_Request_Event__e> lstOCEEvent){
        this.lstOCEAccEvent = lstOCEEvent;
    }
    
    global Iterable<Sobject> start(Database.BatchableContext BC){
        return new ObjectIterator(lstOCEAccEvent);
    }
    
    global void execute(Database.BatchableContext BC, List<Sample_Order_Request_Event__e> lstOCEOEvent){
        Sample_Order_Request_Event__e OCEevt= lstOCEOEvent[0];
        Map<String,String> sampleOrderResultedMap = new Map<String,String>();
        
        Boolean eventMandateFieldFlag = validateEventMandate(OCEevt);
        System.debug('**SPE--MissingMandate--'+eventMandateFieldFlag);
        if(!eventMandateFieldFlag) return;
        try{
            if(eventMandateFieldFlag){
                Map<Id, Address__c> accntIdToBillToAddressMap = new Map<Id, Address__c>();
                Map<Id, Address__c> accntIdToShipToAddressMap = new Map<Id, Address__c>();
                List<Account> lstAccount = new List<Account>();
                Account accountOneKey = null;
                String oneKeyId = OCEevt.AccountOnekeyId__c;
                String addrsOneKey = OCEevt.AddressOneKeyId__c;
                Set<String> oneKeyAddrs = new Set<String>();
                Set<String> oneKeyAacc = new Set<String>();
                oneKeyAddrs.add(addrsOneKey);
                oneKeyAacc.add(oneKeyId);
                lstAccount = [Select id,IQVIA_OneKeyId__c from Account where IQVIA_OneKeyId__c =:oneKeyId ];
                accountOneKey = lstAccount.size()==0 ? null : lstAccount[0];
                Address__c ShipToAddrs = null;
                Address__c BillToAddrs = null;
                Boolean primaryShipToExists = false;
                if(accountOneKey != null){
                    System.debug('**SPE--accountOneKey--'+accountOneKey.Id);
                    for(Address__c addr : [Select id,Account__c,Account__r.IQVIA_OneKeyId__c,IQVIA_OneKeyId__c,Type__c,Primary_Flag__c, Address_Line_1__c, Address_Line_2__c, 
                                           Address_Line_3__c, City__c, Postal_Code__c, State__c, State_Code__c, RecordTypeId
                                           from Address__c where  Account__c = :accountOneKey.Id]){ 
                                               if(addr.Type__c == 'Bill To' && addr.Primary_Flag__c == true)
                                                   accntIdToBillToAddressMap.put(addr.Account__c, addr);
                                               else if(addr.Type__c == 'Ship To' && addr.IQVIA_OneKeyId__c == OCEevt.AddressOneKeyId__c )
                                                   accntIdToShipToAddressMap.put(addr.Account__c, addr);
                                               if (addr.Type__c == 'Ship To' && addr.Primary_Flag__c == true)
                                                   primaryShipToExists = true;
                                           }
                    System.debug('**SPE--accntIdToBillToAddressMap--'+accntIdToBillToAddressMap);
                    System.debug('**SPE--accntIdToShipToAddressMap--'+accntIdToShipToAddressMap);
                    if(accntIdToShipToAddressMap.get(accountOneKey.Id) != null && accntIdToBillToAddressMap.get(accountOneKey.Id) == null  ){
                        ShipToAddrs = accntIdToShipToAddressMap.get(accountOneKey.Id);
                        Address__c billToAddressCreate = new Address__c();
                        billToAddressCreate.RecordTypeId = ShipToAddrs.RecordTypeId;
                        billToAddressCreate.Account__c = ShipToAddrs.Account__c;
                        billToAddressCreate.Address_Line_1__c = ShipToAddrs.Address_Line_1__c;
                        billToAddressCreate.Address_Line_2__c = ShipToAddrs.Address_Line_2__c;
                        billToAddressCreate.Address_Line_3__c = ShipToAddrs.Address_Line_3__c;
                        billToAddressCreate.Type__c = 'Bill To';
                        billToAddressCreate.City__c = ShipToAddrs.City__c;
                        billToAddressCreate.Postal_Code__c = ShipToAddrs.Postal_Code__c;
                        billToAddressCreate.State__c = ShipToAddrs.State__c;
                        billToAddressCreate.State_Code__c = ShipToAddrs.State_Code__c;
                        billToAddressCreate.Primary_Flag__c = true;
                        insert billToAddressCreate;
                        BillToAddrs = billToAddressCreate;
                    } 
                    if(accntIdToShipToAddressMap.get(accountOneKey.Id) == null ){
                        if (accntIdToBillToAddressMap.get(accountOneKey.Id) != null) BillToAddrs = accntIdToBillToAddressMap.get(accountOneKey.Id); 
                        	else BillToAddrs = createBothToAddress(accountOneKey.Id,OCEevt,'Bill To', true);
                        ShipToAddrs = createBothToAddress(accountOneKey.Id,OCEevt,'Ship To', primaryShipToExists == true ? false : true);
                       
                    }
                    
                    
                    if(accntIdToShipToAddressMap.get(accountOneKey.Id) != null && accntIdToBillToAddressMap.get(accountOneKey.Id) != null){
                        ShipToAddrs = accntIdToShipToAddressMap.get(accountOneKey.Id); 
                        BillToAddrs = accntIdToBillToAddressMap.get(accountOneKey.Id);
                    }
                    System.debug('**SPE--1'+accountOneKey.Id);
                    System.debug('**SPE--2'+OCEevt.ProgramType__c);
                    System.debug('**SPE--3'+ShipToAddrs.Id);
                    Double QuantitytoBeProcess = OCEevt.Quantity__c == 0 ? 1 : OCEevt.Quantity__c ; 
                    
                    sampleOrderResultedMap = ClsSampleProgramHandler.createOrder(accountOneKey.Id,OCEevt.ProgramType__c, ShipToAddrs.Id,QuantitytoBeProcess,OCEevt.OCEOrderReference__c);
                    System.debug('**SPE--sampleOrderResultedMap--'+sampleOrderResultedMap);
                    if(sampleOrderResultedMap.containsKey('Failed')){
                        ErrorUtility.LogErrorWithEvent('Consume', 'ClsSampleProgramHandler', String.valueOf(sampleOrderResultedMap.get('Failed')), 'Order', OCEevt.AccountOnekeyId__c, 'Failed to Create Order', OCEevt.OCEOrderReference__c, 'Fatal Error - Bailing out', String.valueOf(OCEevt));
                    	PEClsHandlerOCEEvent.publishOCEAccOrderEvent(OCEevt.OCEOrderReference__c, '', '', '', 'Error', sampleOrderResultedMap.get('Failed')); 
                    }else{
                        PEClsHandlerOCEEvent.publishOCEAccOrderEvent(OCEevt.OCEOrderReference__c, sampleOrderResultedMap.get('Success'), 'Created', null,'Success', 'Order Successfully created in Salesforce');
					}
                    
                }else{
                    Account accTofrmOCE = new Account();
                    Boolean  accCreateFlag = validateAccountReqField(OCEevt);
                    if(accCreateFlag){
                        Map<String,String> mapPrefLang = new Map<String,String>();
                        String cntry = getCountry(OCEevt.AccCountryCode__c);
                        accTofrmOCE.RecordTypeId = getAccountRecordType(OCEevt); 
                        accTofrmOCE.Country__c = cntry;
                        if (String.isnotBlank(OCEevt.Email__c)) accTofrmOCE.PersonEmail = OCEevt.Email__c; //A default Email will be added when Account is created for a CA Prescriber.
                        accTofrmOCE.LastName = OCEevt.LastName__c;
                        accTofrmOCE.Preferred_Language__c = OCEevt.Preferred_Language__c.equalsIgnoreCase('fr') && OCEevt.AccCountryCode__c.equalsIgnoreCase('CA') ? 'fr_CA' : 'en_CA';
                        accTofrmOCE.Phone = OCEevt.WorkPhone__c;
                        accTofrmOCE.PersonMobilePhone =OCEevt.Mobile__c;
                        accTofrmOCE.PersonHomePhone =OCEevt.HomePhone__c;
                        accTofrmOCE.PersonOtherPhone =OCEevt.OtherPhone__c;
                        accTofrmOCE.IQVIA_OneKeyId__c =  OCEevt.AccountOnekeyId__c;
                        accTofrmOCE.FirstName = OCEevt.FirstName__c; //'Sample Test'; 
                        accTofrmOCE.CurrencyIsoCode = 'CAD';
                        insert accTofrmOCE;
                        System.debug('**SPE--accTofrmOCE--'+accTofrmOCE);
                        // Address Insertion
                        Boolean  addressNewCreateFlag = validateAddressReqField(OCEevt);
                        if(addressNewCreateFlag)  BillToAddrs = createBothToAddress(accTofrmOCE.Id,OCEevt,'Bill To',true);
                        if(addressNewCreateFlag)  ShipToAddrs = createBothToAddress(accTofrmOCE.Id,OCEevt,'Ship To',true);
                        Double QuantitytoBeProcess1 = OCEevt.Quantity__c == 0 ? 1 : OCEevt.Quantity__c ; 
                        // Map<String,String> createOrder(Id accountId,String SampleType, Id shipToAddressId,Double OrdQuantity,String OCEOrdRef)
                        sampleOrderResultedMap =  ClsSampleProgramHandler.createOrder(accTofrmOCE.Id,OCEevt.ProgramType__c, ShipToAddrs.Id,QuantitytoBeProcess1,OCEevt.OCEOrderReference__c);
                        System.debug('**SPE--sampleOrderResultedMap--'+sampleOrderResultedMap);
                        if(sampleOrderResultedMap.containsKey('Failed')){ 
                            ErrorUtility.LogErrorWithEvent('Consume', 'ClsSampleProgramHandler', String.valueOf(sampleOrderResultedMap.get('Failed')), 'Order', OCEevt.AccountOnekeyId__c, 'Failed to Create Order', OCEevt.OCEOrderReference__c, 'Fatal Error - Bailing out', String.valueOf(OCEevt));
                            PEClsHandlerOCEEvent.publishOCEAccOrderEvent(OCEevt.OCEOrderReference__c, '', '', '', 'Error', sampleOrderResultedMap.get('Failed')); 
                        }else{
                            PEClsHandlerOCEEvent.publishOCEAccOrderEvent(OCEevt.OCEOrderReference__c, sampleOrderResultedMap.get('Success'), 'Created', null,'Success', 'Order Successfully created in Salesforce');
                        }
                    }
                }
            }
        }catch(Exception ex){
            System.debug('**SPE--Exception--'+ex);
            System.debug('**SPE--ErrLine--'+ex.getLineNumber());
        }
        
    }
    
    global void finish(Database.BatchableContext BC){}
    global static Address__c createBothToAddress(String accId,Sample_Order_Request_Event__e OCEevt,String addrsType, Boolean makeItPrimary){
        Address__c SBAddrs = new Address__c();
        SBAddrs.Account__c = accId;
        SBAddrs.RecordTypeId = getAddressRecordType(OCEevt.AccCountryCode__c);// Need to implement function '0121n0000015w5hAAA'; 
        SBAddrs.Address_Line_1__c = OCEevt.AddressLine1__c;
        SBAddrs.Address_Line_2__c = OCEevt.AddressLine2__c;
        SBAddrs.Address_Line_3__c = OCEevt.AddressLine3__c;
        SBAddrs.Type__c = addrsType;
        SBAddrs.City__c = OCEevt.City__c;
        SBAddrs.Postal_Code__c = OCEevt.PostalCode__c;
        if (OCEevt.StateProvince__c.length() == 2) SBAddrs.State_Code__c = OCEevt.StateProvince__c; else SBAddrs.State__c = OCEevt.StateProvince__c;
        if (addrsType == 'Ship To') SBAddrs.IQVIA_OneKeyId__c = OCEevt.AddressOneKeyId__c;
        if (makeItPrimary == true) SBAddrs.Primary_Flag__c = true;
        insert SBAddrs;
        return SBAddrs;
    }  
    global static boolean validateEventMandate(Sample_Order_Request_Event__e oceEvnt){
        Boolean evtflag = true;
        
        if(String.isBlank(oceEvnt.AccountOnekeyId__c)){
            evtflag = false;
            ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleBatchOCEEvent', 'Missing Account OneKey Id', 'Account', oceEvnt.AccountOnekeyId__c, 'Account Field  IQVIA_OneKeyId__c required for Account Creation', oceEvnt.AccountOnekeyId__c, 'Fatal Error - Bailing out', String.valueOf(oceEvnt));
            PEClsHandlerOCEEvent.publishOCEAccOrderEvent(oceEvnt.OCEOrderReference__c, '', '', '', 'Failed', 'Missing Account OneKey Id');
            return evtflag;
        }else if(String.isBlank(oceEvnt.AddressOneKeyId__c) ){
            evtflag = false;
            ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleBatchOCEEvent', 'Missing Address OneKey Id', 'Order', oceEvnt.AccountOnekeyId__c, 'Address Field IQVIA_OneKeyId__c is required for Order Creation', oceEvnt.AccountOnekeyId__c, 'Fatal Error - Bailing out', String.valueOf(oceEvnt));
            PEClsHandlerOCEEvent.publishOCEAccOrderEvent(oceEvnt.OCEOrderReference__c, '', '', '', 'Failed', 'Missing Address OneKey Id');
            return evtflag;
        }else if(String.isBlank(oceEvnt.ProgramType__c)){
            evtflag = false;
            ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleBatchOCEEvent', 'Missing Program Type', 'Account', oceEvnt.AccountOnekeyId__c, 'Program Type is required for Account & Address Creation', oceEvnt.AccountOnekeyId__c, 'Fatal Error - Bailing out', String.valueOf(oceEvnt));
            PEClsHandlerOCEEvent.publishOCEAccOrderEvent(oceEvnt.OCEOrderReference__c, '', '', '', 'Failed', 'Missing Program Type');
            return evtflag; 
        }else if(String.isBlank(oceEvnt.OCEOrderReference__c)){
            System.debug('***SPE--OCERefBlank--'+oceEvnt.OCEOrderReference__c);
            evtflag = false;
            ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleBatchOCEEvent', 'Missing OrderReference', 'Order', oceEvnt.AccountOnekeyId__c, 'Order Field OrderReference is required for Order Creation', oceEvnt.AccountOnekeyId__c, 'Fatal Error - Bailing out', String.valueOf(oceEvnt));
            PEClsHandlerOCEEvent.publishOCEAccOrderEvent(oceEvnt.OCEOrderReference__c, '', '', '', 'Failed', 'Missing OCE OrderReference');
            return evtflag; 
        }
        System.debug('**SPE--MandateFlag--'+evtflag );
        return evtflag;
    }
    global static boolean validateAddressReqField(Sample_Order_Request_Event__e oceEvnt){
        Boolean addrsFlag = true;
        if(String.isBlank(oceEvnt.AddressLine1__c)){ // || String.isBlank(oceEvnt.AddressLine2__c) || String.isBlank(oceEvnt.AddressLine3__c)
            addrsFlag = false;
            ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleBatchOCEEvent', 'Missing Address Lines', 'Account', oceEvnt.AccountOnekeyId__c, 'Address Line is required for Account & Address Creation', oceEvnt.AccountOnekeyId__c, 'Fatal Error - Bailing out', String.valueOf(oceEvnt));
            PEClsHandlerOCEEvent.publishOCEAccOrderEvent(oceEvnt.OCEOrderReference__c, '', '', '', 'Failed', 'Missing Address Lines from 1/2/3');
            return addrsFlag;
         
        } else if(String.isBlank(oceEvnt.PostalCode__c )){
            addrsFlag = false;
            ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleBatchOCEEvent', 'Missing Address PostalCode', 'Address__c', oceEvnt.AccountOnekeyId__c, 'Address Postal Code is required for Account & Address Creation', oceEvnt.AccountOnekeyId__c, 'Fatal Error - Bailing out', String.valueOf(oceEvnt));
            PEClsHandlerOCEEvent.publishOCEAccOrderEvent(oceEvnt.OCEOrderReference__c, '', '', '', 'Failed', 'Missing Address PostalCode');
            return addrsFlag; 
        }else if(String.isBlank(oceEvnt.City__c)){
            addrsFlag = false;
            ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleBatchOCEEvent', 'Missing Address City', 'Address__c', oceEvnt.AccountOnekeyId__c, 'Address City is required for Account & Address Creation', oceEvnt.AccountOnekeyId__c, 'Fatal Error - Bailing out', String.valueOf(oceEvnt));
            PEClsHandlerOCEEvent.publishOCEAccOrderEvent(oceEvnt.OCEOrderReference__c, '', '', '', 'Failed', 'Missing Address City');
            return addrsFlag; 
        }else if(String.isBlank(oceEvnt.StateProvince__c)){
            addrsFlag = false;
            ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleBatchOCEEvent', 'Missing StateProvince', 'Address__c', oceEvnt.AccountOnekeyId__c, 'Address StateProvince is required for Account & Address Creation', oceEvnt.AccountOnekeyId__c, 'Fatal Error - Bailing out', String.valueOf(oceEvnt));
            PEClsHandlerOCEEvent.publishOCEAccOrderEvent(oceEvnt.OCEOrderReference__c, '', '', '', 'Failed', 'Missing StateProvince');
            return addrsFlag; 
        }
        return addrsFlag;
    } 
    global static boolean validateAccountReqField(Sample_Order_Request_Event__e oceEvnt){
        Boolean accflag = true;
        if(String.isBlank(oceEvnt.AccCountryCode__c)){
            accflag = false;
            ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleBatchOCEEvent', 'Missing Account country code', 'Account', oceEvnt.AccountOnekeyId__c, 'Account Field country code required for Account Creation', oceEvnt.AccountOnekeyId__c, 'Fatal Error - Bailing out', String.valueOf(oceEvnt));
            PEClsHandlerOCEEvent.publishOCEAccOrderEvent(oceEvnt.OCEOrderReference__c, '', '', '', 'Failed', 'Missing Account country code');
            return accflag;       
        }else if(String.isBlank(oceEvnt.FirstName__c)){
            accflag = false;
            ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleBatchOCEEvent', 'Missing Account First Name', 'Account', oceEvnt.AccountOnekeyId__c, 'Account Field LastName is required for Account Creation', oceEvnt.AccountOnekeyId__c, 'Fatal Error - Bailing out', String.valueOf(oceEvnt));
             PEClsHandlerOCEEvent.publishOCEAccOrderEvent(oceEvnt.OCEOrderReference__c, '', '', '', 'Failed', 'Missing Account First Name');
            return accflag;
        }else if(String.isBlank(oceEvnt.LastName__c)){
            accflag = false;
            ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleBatchOCEEvent', 'Missing Account Last Name', 'Account', oceEvnt.AccountOnekeyId__c, 'Account Field LastName is required for Account Creation', oceEvnt.AccountOnekeyId__c, 'Fatal Error - Bailing out', String.valueOf(oceEvnt));
             PEClsHandlerOCEEvent.publishOCEAccOrderEvent(oceEvnt.OCEOrderReference__c, '', '', '', 'Failed', 'Missing Account Last Name');
            return accflag;
        }
        return accflag;
    }
    
    global static String getAddressRecordType(String countryCode){        
        String recName = countryCode + ' Address';
        Id addressRecType = Schema.SObjectType.Address__c.getRecordTypeInfosByName().get(recName).getRecordTypeId();
		return addressRecType;

    }
    //Ask Vijay About - Aalways need to check PersonAccount Record type?? or Account Record type we need to check
    global static String getAccountRecordType(Sample_Order_Request_Event__e oceEvnt){
       // String accRecTypeId = '';
        String recName = oceEvnt.AccCountryCode__c +' '+ oceEvnt.AccountType__c;
        Id accRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recName).getRecordTypeId();
     
        return accRecTypeId;
    }
    global static String getCountry(String countryCode){
        String addrsCountry = '';
        if(countryCode.containsIgnoreCase('CA')){
            addrsCountry = 'Canada';
        }/*else if(countryCode.containsIgnoreCase('DE')){
            addrsCountry = 'Germany';
        }else if(countryCode.containsIgnoreCase('AT')){
            addrsCountry = 'Austria';
        }else if(countryCode.containsIgnoreCase('CH')){
            addrsCountry = 'Switzerland';
        }else if(countryCode.containsIgnoreCase('GB')){
            addrsCountry = 'United Kingdom';
        }else if(countryCode.containsIgnoreCase('IE')){
            addrsCountry = 'Ireland';
        }else if(countryCode.containsIgnoreCase('INTL')){
           addrsCountry = 'Switzerland'; 					// ASk about Country Name
        }else if(countryCode.containsIgnoreCase('SI')){
            addrsCountry = 'Slovenia';
        }*/
        return addrsCountry;
    }
   /* global static Map<String,String> getPreferedLanguage(){
        Map<String,String> mapOfPreferedLang = new Map<String,String>();        
        Schema.DescribeFieldResult fieldResult = Account.Preferred_Language__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();        
        for( Schema.PicklistEntry f : ple)mapOfPreferedLang.put( f.getLabel(),f.getValue());
        return mapOfPreferedLang;
    }*/
    
    global class ObjectIterator implements Iterator<Sobject>, Iterable<Sobject>{
        global List<Sobject> lstObject; Integer i = 0;
        global ObjectIterator(List<Sobject> lstObject){  this.lstObject = lstObject; i = 0; }  
        global Boolean hasNext(){ return (i >= lstObject.size()) ? false : true; } 
        global Sobject next(){ if(i < lstObject.size()){ i++; return lstObject[i-1]; } return null;}  
        global Iterator<Sobject> iterator() { return this;  } 
    }

}