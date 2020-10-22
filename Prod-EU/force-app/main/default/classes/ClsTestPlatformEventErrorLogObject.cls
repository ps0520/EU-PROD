/****************************************************************************************************************
@Author        : Kumar Navneet
@Date Created    : 13/11/2019
@Description    : Test class for BClsDeletePELogEntries
****************************************************************************************************************/
@isTest
private class ClsTestPlatformEventErrorLogObject {
    @isTest
    static void testPlatformEventError() 
    {
        List<Platform_Event_Error_Log__c> platfrm= new List<Platform_Event_Error_Log__c>();
        for(Integer i=0 ;i <200;i++)
        {
            Platform_Event_Error_Log__c pfe = new Platform_Event_Error_Log__c();
            pfe.Exception_Error__c ='Logging incoming Event'+i;
            platfrm.add(pfe);
        }
        
        insert platfrm;
        
        Test.startTest();
        SClsDeletePELogEntries sh = new SClsDeletePELogEntries();
        String sch = '0 0 23 * * ?'; system.schedule('Test Check', sch, sh); 
        String query = 'select id from Platform_Event_Error_Log__c ';
        BClsDeletePELogEntries obj = new BClsDeletePELogEntries(query);
        DataBase.executeBatch(obj);  
            
        Test.stopTest();
    }
}