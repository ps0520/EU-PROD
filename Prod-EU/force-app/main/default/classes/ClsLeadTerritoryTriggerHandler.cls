/*******************************************************************************************************************
@Author        : Navneet
@Date Created    : 19/12/2019
@Description    : Trigger invokes handler class to process territory
********************************************************************************************************************/    
 
public class ClsLeadTerritoryTriggerHandler {
    
    static Map<ID,Schema.RecordTypeInfo> recordTypesMap = ClsApexUtil.getRecordTypeId('Lead');
    
    //Method invoked on Account insert
    public static void OnBeforeInsert(List<Lead> LeadsToProcess, String country){
        String batch;
        if(LeadsToProcess.size()>0){
            ZiptoAlignUpdate(LeadsToProcess,batch, country); //Finds the zip to align
            LeadTerritoryUpdate(LeadsToProcess,batch, country); //Leads territory fields are updated
        }
    }
    
    //Method invoked on Account before update
    public static void OnBeforeUpdate(List<Lead> Leads,Map <Id,Lead> LeadsOldMap, String country){
        List<Lead> leadList = New List<Lead>();
        String batch;
        for(Lead le: Leads) {   
            Lead OldLead = LeadsOldMap.get(le.ID);
            if(le.PostalCode != OldLead.PostalCode){
                   leadList.add(le); 
               }
        }
        if(leadList.size()>0){
            ZiptoAlignUpdate(leadList,batch, country);
            LeadTerritoryUpdate(leadList,batch, country);
        }
    }   

    //This Method finds the zip to align the lead    
    public static void ZiptoAlignUpdate(List<Lead> leadsToProcess,String batch, String country){
        system.debug('-----Leads to process - ' + leadsToProcess.size());
        List<Lead> leadList = new List<Lead>();
       
        Integer Ziplength = 0 ;
		switch on country {
			when 'DE' {
				Ziplength = 5;
			}
			when 'CA' {
				Ziplength = 3;
			}
			when 'CH' {
				Ziplength = 4;
			}
			when 'AT' {
				Ziplength = 4;
			}
		}

        system.debug('-country - ' + country);
        system.debug('-Ziplength - ' + Ziplength);
        for(Lead le: leadsToProcess) {
			String zipToProcess ;
			
			zipToProcess =   le.PostalCode ;
			
            //Do not proceed if Zip is null
			if(!String.isBlank(zipToProcess))
			{
				   if(country == 'GB' || country == 'IE')
					   {
						   le.Zip_To_Align__c = zipToProcess.substringBefore(' ');
						   leadList.add(le);
					   }
					   else
					   if(zipToProcess.length() >= Ziplength && zipToProcess.substring(0,Ziplength) != null){  
						   le.Zip_To_Align__c = zipToProcess.substring(0,Ziplength);
						   leadList.add(le);
						 }
				   
					system.debug('-----Zip for account id for processing  - ' + le.Id);   
					
			}
            
        } 
        //Perform DML Operation
        try{
            if((leadList.size()>0) && batch != null){             
                update leadList;
            }
        }catch(DMLException ex){
            system.debug('***ERROR UPDATE*** ' + ex.getMessage());
        }
    }
    //This method will update the territory alignment field on the Lead (Territory, Region and District)
    public static void LeadTerritoryUpdate(List<Lead> leadsToProcess,String batch, String country){
        set<string> zipcodes = new set<string>();  
        List<Lead> leadList = new List<Lead>(); 
        map<string,string> zipToTerMap = new map<string,string>();  
        map<string,string> zipToTerRegionMap = new map<string,string>();  
        map<string,string> zipToTerDistrictMap = new map<string,string>();  
        String countryName ; 
        Integer Ziplength = 0 ;
		switch on country {
			when 'DE' {
				Ziplength = 5;
				countryName = 'Germany';
			}
			when 'CA' {
				Ziplength = 3;
				countryName = 'Canada';
			}
			when 'CH' {
				Ziplength = 4;
				countryName = 'Switzerland';
			}
			when 'AT' {
				Ziplength = 4;
				countryName = 'Austria';
			}
			when 'GB' {
				countryName = 'United Kingdom';
			}
			when 'IE' {
				countryName = 'Ireland';
			}
		}
        system.debug('-country - ' + country);		
        system.debug('-Ziplength - ' + Ziplength);
        
         for (Lead le: leadsToProcess) {
			 system.debug('-le.Zip_To_Align__c - ' + le.Zip_To_Align__c);
            if(!String.isBlank(le.Zip_To_Align__c)){
				if((country == 'GB' || country == 'IE' ) && le.Zip_To_Align__c != null)
				{
					zipcodes.add(le.Zip_To_Align__c.substringBefore(' '));
					zipcodes.add(le.Zip_To_Align__c);
				}
				else		
                if(le.Zip_To_Align__c.length() >= Ziplength ){
                    zipcodes.add(le.Zip_To_Align__c.substring(0,Ziplength)); 
                }
            }
         }      
         system.debug('-zipcodes - ' + zipcodes);
        if(zipcodes.size()>0){
            //Query the Zip_to_Terr object to get the zipcode, Territory,District and Region values and put them in a map
            for(Zip_to_Terr__c zipToTerr : [Select name, Territory__c,District__c,Country__c,Region__c,State__c from Zip_to_Terr__c WHERE Country__c = :countryName and Name IN :zipcodes]){
                zipToTerMap.put (zipToTerr.name, zipToTerr.Territory__c);
                zipToTerRegionMap.put(zipToTerr.name,zipToTerr.Region__c);
                zipToTerDistrictMap.put(zipToTerr.name,zipToTerr.District__c); 
            }
            //Map the Territory, Region, District as per the zip to align field on the account
            for(Lead le: leadsToProcess) {
				String zipToAlign;	
                if(le.Zip_To_Align__c != null){
                    if(!zipToTerMap.isEmpty())
					{
						if(country == 'GB' || country == 'IE')
							zipToAlign = le.Zip_To_Align__c.substringBefore(' ');
						else
						if(le.Zip_To_Align__c.length() >= Ziplength && le.Zip_To_Align__c.substring(0,Ziplength) != null)  
					    zipToAlign = le.Zip_To_Align__c.substring(0,Ziplength);
						String territory = zipToTerMap.get(zipToAlign);
						String region = zipToTerRegionMap.get(zipToAlign);
						String district = zipToTerDistrictMap.get(zipToAlign);
						if(territory != null) {
							le.Territory__c = territory;
							le.Region__c = region;
							le.District__c = district; 
							leadList.add(le);
						}							
					}
				}
            }
        }          
		try{
			if((leadList.size()>0) && batch != null){             
				update leadList;
			}
		}catch(DMLException ex){
			system.debug('***ERROR UPDATE*** ' + ex.getMessage());
		}           
    }
}