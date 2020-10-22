@isTest
public class ClsLeadObjectTest {
	
    @isTest
    private static void testLeadObject() {
      	Id leadRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName LIKE 'CA_%' AND SobjectType = 'Lead'].Id ;
        insert new Lead(Status = 'New', RecordTypeId = leadRecordTypeId, FirstName = 'Canada', LastName='Lead');
        System.assertNotEquals(Null, Lead.Id);
    }
    
   @isTest
    private static void testLeadObjectIE() {
      	Id leadRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName LIKE 'IE_%' AND SobjectType = 'Lead'].Id ;
        insert new Zip_to_Terr__c (name = 'P36', Territory__c = 'IE020101', District__c = 'IE020100', Country__c='Ireland', Region__c='IE020000');
        Lead Le =  new Lead(Status = 'New', RecordTypeId = leadRecordTypeId, FirstName = 'Ireland', LastName='Lead', PostalCode='P36', Street='test',  City='test', Country='Ireland');
        insert Le;
      //  Le.PostalCode = 'P37';
      //  update Le ;        
        System.assertNotEquals(Null, Lead.Id);
    }
    
    @isTest
    private static void testLeadObjectCA() {
      	Id leadRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName LIKE 'CA_%' AND SobjectType = 'Lead'].Id ;
        insert new Zip_to_Terr__c (name = 'P38', Territory__c = 'CA020101', District__c = 'CA020100', Country__c='Canada', Region__c='CA020000');
        Lead Le =  new Lead(Status = 'New', RecordTypeId = leadRecordTypeId, FirstName = 'Canada', LastName='Lead', PostalCode='P38', Street='test',  City='test', Country='Canada');
        insert Le;
              
        System.assertNotEquals(Null, Lead.Id);
    }
    
    @isTest
    private static void testLeadObjectGB() {
      	Id leadRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName LIKE 'GB_%' AND SobjectType = 'Lead'].Id ;
        insert new Zip_to_Terr__c (name = 'P39', Territory__c = 'GB020101', District__c = 'GB020100', Country__c='United Kingdom', Region__c='GB020000');
        Lead Le =  new Lead(Status = 'New', RecordTypeId = leadRecordTypeId, FirstName = 'United Kingdom', LastName='Lead', PostalCode='P39', Street='test',  City='test', Country='United Kingdom');
        insert Le;
              
        System.assertNotEquals(Null, Lead.Id);
    }
     @isTest
    private static void testLeadObjectDE() {
        List<Lead> lstLead = new List<Lead>();
        List<Lead> lstLeadNew = new List<Lead>();
        
        Map<Id,Lead> mapNewLead = new Map<Id,Lead>();
        Map<Id,Lead> mapOldLead = new Map<Id,Lead>();
      	Id leadRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName LIKE 'DE_%' AND SobjectType = 'Lead'].Id ;
        insert new Zip_to_Terr__c (name = 'P44', Territory__c = 'DE020101', District__c = 'DE020100', Country__c='Germany', Region__c='DE020000');
        Lead Le =  new Lead(Status = 'New', RecordTypeId = leadRecordTypeId, FirstName = 'Germany', LastName='Lead', PostalCode='P39', Street='test',  City='test', Country='Germany');
        insert Le;
        mapOldLead.put(Le.Id,le);
        lstLead.add(le);
        String leadCountry = Le.Country ;
        ClsLeadTerritoryTriggerHandler.OnBeforeInsert(lstLead, leadCountry);
              
        //System.assertNotEquals(Null, Lead.Id);
    }
    
    //ClsLeadTerritoryTriggerHandler
    @isTest
    private static void testCountryHandlerMethods() {
        List<Lead> lstLead = new List<Lead>();
        List<Lead> lstLeadNew = new List<Lead>();
        
        Map<Id,Lead> mapNewLead = new Map<Id,Lead>();
        Map<Id,Lead> mapOldLead = new Map<Id,Lead>();
      	Id leadRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName LIKE 'GB_%' AND SobjectType = 'Lead'].Id ;
        insert new Zip_to_Terr__c (name = 'P39', Territory__c = 'GB020101', District__c = 'GB020100', Country__c='United Kingdom', Region__c='GB020000');
        Lead Le =  new Lead(Status = 'New', RecordTypeId = leadRecordTypeId, FirstName = 'United Kingdom', LastName='Lead', PostalCode='P39', Street='test',  City='test', Country='United Kingdom');
        insert Le;
        mapOldLead.put(Le.Id,le);
        lstLead.add(le);
        String leadCountry = Le.Country ;
        ClsLeadTerritoryTriggerHandler.OnBeforeInsert(lstLead, leadCountry);
        le.FirstName = 'UK';
        le.PostalCode = 'P40';
        update le;
        lstLeadNew.add(le);
        mapNewLead.put(le.Id,le);
        ClsLeadTerritoryTriggerHandler.OnBeforeUpdate(lstLead, mapOldLead, leadCountry);
        //OnBeforeUpdate
       
    }
    
    
}