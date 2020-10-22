/******************************************************
@Author        : Abhishek Parghi, Jagan Periyakaruppan 
@Date Created    : 4/10/2017
@Description    : Apex Utility class.
*******************************************************/
public class ClsApexUtil{
    
    // Get the record type information for a given SObject
    public static  Map<Id, schema.recordtypeinfo> GetRecordTypeId(String objType){
        SObject obj;
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objType);
        if(targetType != null){
            obj = targetType.newSObject();
            Schema.DescribeSObjectResult result = obj.getSObjectType().getDescribe();
            if(result != null){
                Map<Id, schema.recordtypeinfo> recordTypeMap = result.getRecordTypeInfosById();
                if (recordTypeMap != null){
                    return recordTypeMap;
                }
            }
        }
        return null;
    }
    
    //Returns the user to territory map based on InsIde sales or Field sales request via Sales type
    public static Map<Id, Id> GetuserTerritoryMap(List<String> terrcodes, String salestype, String country){
        Map<Id, Id> userTerritoryMap = new Map<Id, Id>();
        List<UserTerritory> userTerrList = new List<UserTerritory>();
        Set<Id> terrIds = new Set<Id>(); 
        List<Territory> terrList = [SELECT Id,Name From Territory WHERE Name IN :terrcodes];    
        if(terrList.size() > 0){ 
            for(Territory terr: terrList) { 
                terrIds.add(terr.Id); 
            }
        }
        if(salestype == 'Field')
            userTerrList = [SELECT Id, TerritoryId, UserId, ISActive from UserTerritory WHERE TerritoryId IN :terrIds AND Isactive = true AND UserId in (Select Id From User WHERE Profile.Name like '%Field%')];
        else
            if(salestype == 'Inside'){                
                if(country == 'DE'){
                    userTerrList = [SELECT Id, TerritoryId, UserId, ISActive from UserTerritory WHERE TerritoryId IN :terrIds AND Isactive = true AND UserId in (Select Id From User WHERE Profile.Name like '%Inside%' and User_Type__c = 'CSR')];
                }else{
                    if(country == 'CA'){
                        userTerrList = [SELECT Id, TerritoryId, UserId, ISActive from UserTerritory WHERE TerritoryId IN :terrIds AND Isactive = true AND UserId in (Select Id From User WHERE Profile.Name like '%Inside%' and User_Type__c = 'ISR')];
                    } 
                    else{
                        if(country == 'CH'){
                            userTerrList = [SELECT Id, TerritoryId, UserId, ISActive from UserTerritory WHERE TerritoryId IN :terrIds AND Isactive = true AND UserId in (Select Id From User WHERE Profile.Name like '%Inside%' and User_Type__c = 'CSR')];
                        } 
                        else{
                            if(country == 'AT'){
                                userTerrList = [SELECT Id, TerritoryId, UserId, ISActive from UserTerritory WHERE TerritoryId IN :terrIds AND Isactive = true AND UserId in (Select Id From User WHERE Profile.Name like '%Inside%' and User_Type__c = 'CSR')];
                            } 
                            else{
                                if(country == 'GB'){
                                    userTerrList = [SELECT Id, TerritoryId, UserId, ISActive from UserTerritory WHERE TerritoryId IN :terrIds AND Isactive = true AND UserId in (Select Id From User WHERE Profile.Name like '%Inside%' and User_Type__c = 'CSR')];
                                } 
                                else{
                                    if(country == 'IE'){
                                        userTerrList = [SELECT Id, TerritoryId, UserId, ISActive from UserTerritory WHERE TerritoryId IN :terrIds AND Isactive = true AND UserId in (Select Id From User WHERE Profile.Name like '%Inside%' and User_Type__c = 'CSR')];
                                    } 
                                    else{
                                        if(country == 'SI'){
                                            userTerrList = [SELECT Id, TerritoryId, UserId, ISActive from UserTerritory WHERE TerritoryId IN :terrIds AND Isactive = true AND UserId in (Select Id From User WHERE Profile.Name like '%Inside%' and User_Type__c = 'CSR')];
                                        } 
                                    }   
                                }   
                            }   
                        }         
                    }   
                }   
                
            }
        if(!userTerrList.isEmpty())
        {
            for(UserTerritory userTerr: userTerrList){
                userTerritoryMap.put (userTerr.TerritoryId, userTerr.UserId);
            } 
        }		
        return userTerritoryMap;  
    }
    
    //Returns map between Territory Name to its Id	
    public static Map<String, Id> GetTerritoryMap(List<String> terrcodes){
        Map<String,Id> territorymap =  new Map<String,Id>();
        List<Territory> terrList = [SELECT Id,Name From Territory WHERE Name IN :terrcodes];    
        if(terrList.size() > 0){ 
            for(Territory terr: terrList) { 
                territorymap.put (terr.name, terr.Id);
            }
        }
        return territorymap;
    } 
    
    //Returns the country admin for a given country
    public static String GetCountryAdmin(String country){
        Country_Admin__c countryAdmin = Country_Admin__c.getInstance(country);
        if(countryAdmin != null)
            return countryAdmin.User_Id__c;
        else
            return null;
    } 
    
    //For a given email address the method will return the Org wide email address Id
    public static String GetOrgWideEmailAddrId (String emailAddress){
        String orgWideEmailAddrId;
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =:emailAddress];
        if ( owea.size() > 0 )
            orgWideEmailAddrId = owea.get(0).Id;
        return orgWideEmailAddrId;
    }
}