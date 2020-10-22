/****************************************************************************************************************
@Author        : Kumar Navneet
@Date Created    : 27/11/2019
@Description    : Test class for TrgCRMErrorEventIn 
****************************************************************************************************************/
@isTest()
private class ClsTestTrgCRMErrorEventIn  {
	
    @isTest private static void test(){
        
        List<Platform_Event_Error_Log__c> platfrm= new List<Platform_Event_Error_Log__c>();
        for(Integer i=0 ;i <200;i++)
        {
            Platform_Event_Error_Log__c pfe = new Platform_Event_Error_Log__c();
            pfe.Exception_Error__c ='Logging incoming Event'+i;
           
            platfrm.add(pfe);
        }
        
        insert platfrm;
        List<CRM_Error_Event_In__e> lstEvnt = new List<CRM_Error_Event_In__e>();
        CRM_Error_Event_In__e  oEvent = new CRM_Error_Event_In__e (code__c = 'Test',entityType__c = 'Sales_Order', eventSource__c = 'update', payload__c ='Test',
                                                        		  message__c = 'ESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTEST');
        lstEvnt.add(oEvent); 
        ClsPlatformEventErrorLogHandler.handleInboundErrors(lstEvnt);
        System.debug('====oEvent===='+JSON.serialize(oEvent));
        Test.startTest();        	
            Database.SaveResult sr = EventBus.publish(oEvent);
        Test.stopTest();
    }
     @isTest private static void testAddressErr(){
        List<CRM_Error_Event_In__e> lstEvnt = new List<CRM_Error_Event_In__e>();
         Account payorAccount = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'DE Payor', 'Germany')[0];
        List<Account> lstAccount = [SELECT Id, Name FROM Account];
        Id recordTypeId = Schema.SObjectType.Address__c.getRecordTypeInfosByName().get('DE Address').getRecordTypeId(); 
        //String recordTypeId = addRecordTypes.get('DE Address');
        List<Address__c> lstAddress = new List<Address__c>{
                                                            new Address__c(Account__c = lstAccount[0].Id,RecordTypeId = recordTypeId,Type__c = 'Bill To', Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg'),
                                                            new Address__c(Account__c = lstAccount[0].Id,RecordTypeId = recordTypeId,Type__c = 'Ship To',Country__c = 'Germany', City__c = 'Rosemont', Address_Line_1__c = '10255 W Higgins Rd', Postal_Code__c = '60089', Primary_Flag__c = true, System_Of_Origin__c = '12345', System_Of_Origin_Id__c = 'abcdefg')
                                                          };
        insert lstAddress;
        CRM_Error_Event_In__e  oEvent = new CRM_Error_Event_In__e (code__c = 'Test',entityType__c = 'address', eventSource__c = 'update', payload__c ='Test',
                                                        		   key__c = lstAddress[0].Id,
                                                                   message__c = 'ESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTEST');
        lstEvnt.add(oEvent); 
        ClsPlatformEventErrorLogHandler.handleInboundErrors(lstEvnt);
         lstEvnt.clear();
         CRM_Error_Event_In__e  oEvent1 = new CRM_Error_Event_In__e (code__c = 'Test',entityType__c = 'account', eventSource__c = 'update', payload__c ='Test',
                                                        		   key__c = lstAccount[0].Id,
                                                                   message__c = 'ESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTEST');
        lstEvnt.add(oEvent1); 
        ClsPlatformEventErrorLogHandler.handleInboundErrors(lstEvnt);
        
    }
   
}