/****************************************************************************************************************
@Author        : Kumar Navneet
@Date Created    : 5/30/2019
@Description    : Creating class for handling Country specific Zipcodes
****************************************************************************************************************/

public class ClsAccountCountryHandler {
    //Method invoked on Account before insert
    public static void beforeInsertHandler(List<Account> newAccsList) {
        system.debug('inside beforeInsertHandler');      
        //Accumulate
        List<Account> DEnewAccsList = new List<Account>();
        List<Account> CAnewAccsList = new List<Account>();
        List<Account> CHnewAccsList = new List<Account>();
        List<Account> ATnewAccsList = new List<Account>();
        List<Account> GBnewAccsList = new List<Account>();
        List<Account> IEnewAccsList = new List<Account>();
        // Adding records for specific country
        for(Account Ac : newAccsList) {
            if (Ac.Record_Type_Name__c.startswith('CA')) {
                Ac.CurrencyIsoCode = 'CAD';
              //NS-1101 start
                if(Ac.Lead_Birth_Date__c != null){
                   Ac.Primary_Phone_Contact__c='Home';
                   ac.PersonHomePhone=ac.phone;
                   ac.phone='';                  
                }
              //NS-1101 end
                CAnewAccsList.add(Ac);                
            }
            else if(Ac.Record_Type_Name__c.startswith('DE')){
                    if((Ac.PersonBirthdate != null && Ac.PersonBirthdate.addMonths(216) > Date.today()) || Ac.Pregnant_or_Planning_Pregnancy__c == True )
                    {
                        Ac.VIP__c = True;
                    }
                    DEnewAccsList.add(Ac);
            }
            else if(Ac.Record_Type_Name__c.startswith('CH')){
                    Ac.CurrencyIsoCode = 'CHF';
                    if(Ac.Home_phone__c != null ){
                        Ac.PersonHomePhone = Ac.Home_phone__c;
                        Ac.Home_phone__c = '';
                    }
                    CHnewAccsList.add(Ac);
            }
            else if(Ac.Record_Type_Name__c.startswith('AT')){
                    ATnewAccsList.add(Ac);
            }
            else if(Ac.Record_Type_Name__c.startswith('GB')){
                    Ac.CurrencyIsoCode = 'GBP';
                    if(String.isBlank(Ac.Personemail) && Ac.Record_Type_Name__c.startswith('GB Consumer'))
                    {
                        String todaydate = Datetime.now().format('MM-dd-yyyy');
                        String madeUpEmail = Ac.FirstName+'.'+Ac.LastName+'.'+todaydate+'.gb.invalid@dexcom.com';
                        //Remove any blank space to avoid inavlid email format
                        madeUpEmail = madeUpEmail.replaceAll( '\\s+', '');
                        madeUpEmail = ClsRemoveAccents.removeDiacritics(madeUpEmail);
                        Ac.PersonEmail = madeUpEmail;
                    }
                    if(Ac.PersonBirthdate != null && Ac.PersonBirthdate.addMonths(216) > Date.today())
                    {
                        if(String.isBlank(Ac.Parent_Guardian_First_Name__c)){
                            Ac.Parent_Guardian_First_Name__c = 'PARENT' ;
                        }
                        if(String.isBlank(Ac.Parent_Guardian_Last_Name__c)){
                            Ac.Parent_Guardian_Last_Name__c = 'GUARDIAN' ;
                        }
                    }
                    GBnewAccsList.add(Ac);
            }
            else if(Ac.Record_Type_Name__c.startswith('IE')){
                    Ac.CurrencyIsoCode = 'EUR'; 
                    IEnewAccsList.add(Ac);
            }
            else if(Ac.Record_Type_Name__c.startswith('BE') || Ac.Record_Type_Name__c.startswith('LU') || Ac.Record_Type_Name__c.startswith('NL')){
                    Ac.CurrencyIsoCode = 'EUR';                    
            }
            else if(Ac.Record_Type_Name__c.containsIgnoreCase('Clinic') || Ac.Record_Type_Name__c.startswithIgnoreCase('INTL PAYOR') )	
                    Ac.CurrencyIsoCode = 'USD'; 	
        }
        
        //Country dispatcher
        if (DEnewAccsList.size() > 0) {
            system.debug('inside DE- DEnewAccsList.size() = '+DEnewAccsList.size());
            ClsAccountTerritoryTriggerHandler.OnBeforeInsert(DEnewAccsList, 'DE'); 
            
        }
        if (CAnewAccsList.size() > 0) {
            system.debug('inside CA- CAnewAccsList.size() = '+CAnewAccsList.size());
            ClsAccountTerritoryTriggerHandler.OnBeforeInsert(CAnewAccsList, 'CA'); 
            
        }
        if (CHnewAccsList.size() > 0) {
            system.debug('inside CH- CHnewAccsList.size() = '+CHnewAccsList.size());
            ClsAccountTerritoryTriggerHandler.OnBeforeInsert(CHnewAccsList, 'CH'); 
            
        }
        if (ATnewAccsList.size() > 0) {
            system.debug('inside AT- ATnewAccsList.size() = '+ATnewAccsList.size());
            ClsAccountTerritoryTriggerHandler.OnBeforeInsert(ATnewAccsList, 'AT'); 
            
        }
        if (GBnewAccsList.size() > 0) {
            system.debug('inside GB- GBnewAccsList.size() = '+GBnewAccsList.size());
            ClsAccountTerritoryTriggerHandler.OnBeforeInsert(GBnewAccsList, 'GB'); 
            
        }
        if (IEnewAccsList.size() > 0) {
            system.debug('inside IE- IEnewAccsList.size() = '+IEnewAccsList.size());
            ClsAccountTerritoryTriggerHandler.OnBeforeInsert(IEnewAccsList, 'IE'); 
            
        }
        //Add Payor if Fund is associated to the account
        Map<String, String> fundToPayor = getAssociatedPayorToFund (newAccsList);
        for(Account accnt : newAccsList) {
            if(!fundToPayor.isEmpty() && fundToPayor.containsKey(accnt.Fund__c))
                accnt.Payor__c = fundToPayor.get(accnt.Fund__c);
        }

    }
   //Method to get the Payors associated to the Fund 
    public static Map<String, String> getAssociatedPayorToFund (List<Account> newAccsList){
        //Process Account Payor when Fund is associated
        Map<String, String> fundToPayor = new Map<String, String>();
        Set<Id> fundIds = new Set<Id>();
        for(Account accnt : newAccsList) {
            if(accnt.Fund__c != null) fundIds.add(accnt.Fund__c);
        }
        if(!fundIds.isEmpty()){
            for(Fund__c fund : [SELECT Id, Payor__c FROM Fund__c WHERE Payor__c != null AND Id IN : fundIds])
                fundToPayor.put(fund.Id, fund.Payor__c);
        }
        return fundToPayor;   
    }

    //Method invoked on Account before update
    public static void beforeUpdateHandler(List<Account> newAccs, Map<Id, Account> oldAccs) {
        system.debug('inside beforeUpdateHandler');    
        //Accumulate
        List<Account> DEnewAccs = new List<Account>();
        List<Account> CAnewAccs = new List<Account>();
        List<Account> CHnewAccs = new List<Account>();
        List<Account> ATnewAccs = new List<Account>();
        List<Account> GBnewAccs = new List<Account>();
        List<Account> IEnewAccs = new List<Account>();
        Map<Id, Account> DEoldAccs = new Map<Id, Account>();     
        Map<Id, Account> CAoldAccs = new Map<Id, Account>(); 
        Map<Id, Account> CHoldAccs = new Map<Id, Account>();     
        Map<Id, Account> AToldAccs = new Map<Id, Account>();
        Map<Id, Account> GBoldAccs = new Map<Id, Account>();     
        Map<Id, Account> IEoldAccs = new Map<Id, Account>();
        // Adding records in list for specific country
        for(Account Ac : newAccs) {
            if (Ac.Record_Type_Name__c.startswith('CA')) CAnewAccs.add(Ac);
            else if (Ac.Record_Type_Name__c.startswith('DE'))
            {
                if((Ac.PersonBirthdate != null && Ac.PersonBirthdate != oldAccs.get(Ac.Id).PersonBirthdate && Ac.PersonBirthdate.addMonths(216) > Date.today()) || (Ac.Pregnant_or_Planning_Pregnancy__c != oldAccs.get(Ac.Id).Pregnant_or_Planning_Pregnancy__c && Ac.Pregnant_or_Planning_Pregnancy__c == True ) )
                {
                    Ac.VIP__c = True;
                }
                DEnewAccs.add(Ac);
            }
            else if (Ac.Record_Type_Name__c.startswith('CH')) CHnewAccs.add(Ac);
            else if (Ac.Record_Type_Name__c.startswith('AT')) ATnewAccs.add(Ac);
            else if (Ac.Record_Type_Name__c.startswith('GB')){ 
                if(Ac.PersonBirthdate != null && Ac.PersonBirthdate != oldAccs.get(Ac.Id).PersonBirthdate && Ac.PersonBirthdate.addMonths(216) > Date.today())
                {
                    if(String.isBlank(Ac.Parent_Guardian_First_Name__c)){
                        Ac.Parent_Guardian_First_Name__c = 'PARENT' ;
                    }
                    if(String.isBlank(Ac.Parent_Guardian_Last_Name__c)){
                        Ac.Parent_Guardian_Last_Name__c = 'GUARDIAN' ;
                    }
                }                
                GBnewAccs.add(Ac);
                                                             }
            else if (Ac.Record_Type_Name__c.startswith('IE')) IEnewAccs.add(Ac);
        }
        // Adding old records in list for specific country
        for(Account Ac : oldAccs.values()) {
            if (Ac.Record_Type_Name__c.startswith('CA')) CAoldAccs.put(Ac.id, Ac);
            else if (Ac.Record_Type_Name__c.startswith('DE')) DEoldAccs.put(Ac.id, Ac);
            else if (Ac.Record_Type_Name__c.startswith('CH')) CHoldAccs.put(Ac.id, Ac);
            else if (Ac.Record_Type_Name__c.startswith('AT')) AToldAccs.put(Ac.id, Ac);
            else if (Ac.Record_Type_Name__c.startswith('GB')) GBoldAccs.put(Ac.id, Ac);
            else if (Ac.Record_Type_Name__c.startswith('IE')) IEoldAccs.put(Ac.id, Ac);
        }          
        
        //Country dispatcher
        if (DEnewAccs.size() > 0) {
            system.debug('inside DE- DEnewAccs.size() = '+DEnewAccs.size());
            ClsAccountTerritoryTriggerHandler.OnBeforeUpdate(DEnewAccs, DEoldAccs, 'DE'); 
        }
        if (CAnewAccs.size() > 0) {
            system.debug('inside CA- CAnewAccs.size() = '+CAnewAccs.size());
            ClsAccountTerritoryTriggerHandler.OnBeforeUpdate(CAnewAccs, CAoldAccs, 'CA');
        }
        if (CHnewAccs.size() > 0) {
            system.debug('inside CH- CHnewAccs.size() = '+CHnewAccs.size());
            ClsAccountTerritoryTriggerHandler.OnBeforeUpdate(CHnewAccs, CHoldAccs, 'CH');
        }
        if (ATnewAccs.size() > 0) {
            system.debug('inside AT- ATnewAccs.size() = '+ATnewAccs.size());
            ClsAccountTerritoryTriggerHandler.OnBeforeUpdate(ATnewAccs, AToldAccs, 'AT');
        }
         if (GBnewAccs.size() > 0) {
            system.debug('inside GB- GBnewAccs.size() = '+GBnewAccs.size());
            ClsAccountTerritoryTriggerHandler.OnBeforeUpdate(GBnewAccs, GBoldAccs, 'GB');
        }
        if (IEnewAccs.size() > 0) {
            system.debug('inside IE- IEnewAccs.size() = '+IEnewAccs.size());
            ClsAccountTerritoryTriggerHandler.OnBeforeUpdate(IEnewAccs, IEoldAccs, 'IE');
        }
        //Add Payor if Fund is associated to the account
        List<Account> accountsToProcessForFundChanges = new List<Account>();
        for(Account accnt : newAccs) {
            if(accnt.Fund__c != null && accnt.Fund__c != oldAccs.get(accnt.Id).Fund__c) accountsToProcessForFundChanges.add(accnt);
        }
        if(!accountsToProcessForFundChanges.isEmpty()){
            Map<String, String> fundToPayor = getAssociatedPayorToFund (accountsToProcessForFundChanges);
            for(Account accnt : newAccs) {
                if(accnt.Fund__c != null && !fundToPayor.isEmpty() && fundToPayor.containsKey(accnt.Fund__c))
                    accnt.Payor__c = fundToPayor.get(accnt.Fund__c);
            }
        }
    }
    
    
    //Method invoked on Account after update
    public static void afterUpdateHandler(List<Account> newAccsList, Map<Id, Account> newAccsMap, Map<Id, Account> oldAccsMap) {
        system.debug('inside afterUpdateHandler ');      
        //Accumulate
        List<Account> DEnewAccsList = new List<Account>();
        List<Account> CAnewAccsList = new List<Account>();           
        List<Account> CHnewAccsList = new List<Account>();
        List<Account> ATnewAccsList = new List<Account>();
        List<Account> GBnewAccsList = new List<Account>();
        List<Account> IEnewAccsList = new List<Account>();
        Map<Id, Account> CHoldAccsMap = new Map<Id, Account>();     
        Map<Id, Account> AToldAccsMap = new Map<Id, Account>(); 
        Map<Id, Account> CHNewAccsMap = new Map<Id, Account>();     
        Map<Id, Account> ATNewAccsMap = new Map<Id, Account>();           
        Map<Id, Account> DEoldAccsMap = new Map<Id, Account>();     
        Map<Id, Account> CAoldAccsMap = new Map<Id, Account>(); 
        Map<Id, Account> DENewAccsMap = new Map<Id, Account>();     
        Map<Id, Account> CANewAccsMap = new Map<Id, Account>();
        Map<Id, Account> GBoldAccsMap = new Map<Id, Account>();     
        Map<Id, Account> IEoldAccsMap = new Map<Id, Account>(); 
        Map<Id, Account> GBNewAccsMap = new Map<Id, Account>();     
        Map<Id, Account> IENewAccsMap = new Map<Id, Account>();
        Map<Id, Id> IEGBAccsPayorMap = new Map<Id, Id>();
        // Adding records in list for specific country
        for(Account Ac : newAccsList) {
            if (Ac.Record_Type_Name__c.startswith('CA')) CAnewAccsList.add(Ac);
            else if (Ac.Record_Type_Name__c.startswith('DE')) DEnewAccsList.add(Ac);
            else if (Ac.Record_Type_Name__c.startswith('CH')) CHnewAccsList.add(Ac);
            else if (Ac.Record_Type_Name__c.startswith('AT')) ATnewAccsList.add(Ac);
            else if (Ac.Record_Type_Name__c.startswith('GB')){                 
                if(Ac.Payor__c != null && Ac.Payor__c != oldAccsMap.get(Ac.Id).Payor__c)
                {
                    IEGBAccsPayorMap.put(Ac.id, Ac.Payor__c) ;
                }                  
                GBnewAccsList.add(Ac);
            }
            else if (Ac.Record_Type_Name__c.startswith('IE')) {
                if(Ac.Payor__c != null && Ac.Payor__c != oldAccsMap.get(Ac.Id).Payor__c)
                {
                    IEGBAccsPayorMap.put(Ac.id, Ac.Payor__c) ;
                }                  
                IEnewAccsList.add(Ac);
            }
        }
        // Adding New records in map for specific country
        for(Account Ac : newAccsMap.values()) {
            if (Ac.Record_Type_Name__c.startswith('CA')) CANewAccsMap.put(Ac.id, Ac);
            else if (Ac.Record_Type_Name__c.startswith('DE')) DENewAccsMap.put(Ac.id, Ac);
            else if (Ac.Record_Type_Name__c.startswith('CH')) CHNewAccsMap.put(Ac.id, Ac);
            else if (Ac.Record_Type_Name__c.startswith('AT')) ATNewAccsMap.put(Ac.id, Ac);
            else if (Ac.Record_Type_Name__c.startswith('GB')) GBNewAccsMap.put(Ac.id, Ac);
            else if (Ac.Record_Type_Name__c.startswith('IE')) IENewAccsMap.put(Ac.id, Ac);
        }   
        // Adding old records in map for specific country
        for(Account Ac : oldAccsMap.values()) {
            if (Ac.Record_Type_Name__c.startswith('CA')) CAoldAccsMap.put(Ac.id, Ac);
            else if (Ac.Record_Type_Name__c.startswith('DE')) DEoldAccsMap.put(Ac.id, Ac);
            else if (Ac.Record_Type_Name__c.startswith('CH')) CHoldAccsMap.put(Ac.id, Ac);
            else if (Ac.Record_Type_Name__c.startswith('AT')) AToldAccsMap.put(Ac.id, Ac);
            else if (Ac.Record_Type_Name__c.startswith('GB')) GBoldAccsMap.put(Ac.id, Ac);
            else if (Ac.Record_Type_Name__c.startswith('IE')) IEoldAccsMap.put(Ac.id, Ac);
        }          
        
        //Country dispatcher
        if (DEnewAccsList.size() > 0) {
            system.debug('inside DE- DEnewAccsList.size() = '+DEnewAccsList.size());
            ClsAccountTerritoryTriggerHandler.OnAfterUpdate(DEnewAccsList, DEoldAccsMap, 'DE'); 
            
        }
        if (CAnewAccsList.size() > 0) {
            system.debug('inside CA- CAnewAccsList.size() = '+CAnewAccsList.size());
            ClsAccountTerritoryTriggerHandler.OnAfterUpdate(CAnewAccsList, CAoldAccsMap, 'CA');
        }
        if (CHnewAccsList.size() > 0) {
            system.debug('inside CH- CHnewAccsList.size() = '+CHnewAccsList.size());
            ClsAccountTerritoryTriggerHandler.OnAfterUpdate(CHnewAccsList, CHoldAccsMap, 'CH');
        }    
        if (ATnewAccsList.size() > 0) {
            system.debug('inside AT- ATnewAccsList.size() = '+ATnewAccsList.size());
            ClsAccountTerritoryTriggerHandler.OnAfterUpdate(ATnewAccsList, AToldAccsMap, 'AT');
        }  
        if (GBnewAccsList.size() > 0) {
            system.debug('inside GB- GBnewAccsList.size() = '+GBnewAccsList.size());
            ClsAccountTerritoryTriggerHandler.OnAfterUpdate(GBnewAccsList, GBoldAccsMap, 'GB');
        }    
        if (IEnewAccsList.size() > 0) {
            system.debug('inside IE- IEnewAccsList.size() = '+IEnewAccsList.size());
            ClsAccountTerritoryTriggerHandler.OnAfterUpdate(IEnewAccsList, IEoldAccsMap, 'IE');
        }  
        if (IEGBAccsPayorMap.size() > 0) {            
            UpdateOpportunityPayor(IEGBAccsPayorMap);
        } 
    }
    
    // Updating opportinities payor .
    public static void UpdateOpportunityPayor( Map<Id, Id> AccsPayorMap) {
        List<Opportunity> OppList = new List<Opportunity>();
        for(opportunity opp: [Select id, Payor__c, AccountId from opportunity where StageName != 'Cancelled' and StageName != 'Closed - Complete' and Accountid = :AccsPayorMap.keyset() ]){
            opp.Payor__c = AccsPayorMap.get(opp.AccountId);
            OppList.add(opp);
        }
        if (OppList.size() > 0) 
            update OppList;
        
    }
    
}