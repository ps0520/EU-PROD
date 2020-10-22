/********************************************************************************
@author P Saini
@date July 26, 2019
@description: Test class for CtrlDocuSignTemplateSel
*******************************************************************************/
@istest
private class CtrlDocuSignTemplateSelTest{
    @testSetup
    private static void testSetup(){        
      
            Account a1= new Account();
            a1.Name = 'CtrlDocuSignTemplateSelTest';
            a1.Phone = '123456789';
            //a1.Price_Book__c = pbId;
            a1.Insurance_Company_Identification_Number__c = '123456789';
            a1.RecordtypeID = Schema.SObjectType.account.getRecordTypeInfosByName().get('CA Payor').getRecordTypeId();
            a1.BillingStreet = 'no St';
            a1.BillingCity = 'XYZ';
            a1.BillingState = 'Ontario';
            a1.BillingPostalCode = 'M4X 1A1';
            a1.BillingCountry='Canada';

            a1.ShippingStreet = 'no St';
            a1.ShippingCity = 'XYZ';
            a1.ShippingState = 'Ontario';
            a1.ShippingPostalCode = 'M4X 1A1';
            a1.ShippingCountry='Canada';
                       
            insert a1;
       
       
            Opportunity opp = new Opportunity();
            opp.Name = 'CtrlDocuSignTemplateSelTest';
            opp.AccountId = a1.Id;
            opp.StageName = 'New Opportunity';
            opp.CloseDate = date.today();
            opp.Type = 'NEW SYSTEM';
            insert opp;
           
    }
    
    @isTest
    private static void getRecordDataTypeTest(){
        Account a1= [Select Id, Name from Account Where Name='CtrlDocuSignTemplateSelTest' Limit 1];
        CtrlDocuSignTemplateSel.getRecordDataType(a1.Id);
        List<DocuSign_Templates__mdt> lstDsTmp = [SELECT Id, Template_Id__c FROM DocuSign_Templates__mdt 
            WHERE Object__c='Opportunity' AND Template_Id__c != null AND Active__c=true LIMIT 1];
        if(!lstDsTmp.IsEmpty()){
            System.Debug('****lstDsTmp =' + lstDsTmp );
            // An error might be thrown if Docusign is not setup.
            try{
                CtrlDocuSignTemplateSel.SendDocument1(a1.Id, lstDsTmp[0].Template_Id__c,'getRecordDataTypeTest','getRecordDataTypeTest@gmail.com', 
                'getRecordDataTypeTest','getRecordDataTypeTest',a1.Id);                
            } catch (Exception e){               
                System.Debug('**** e=' + e);               
                
            }
            
            
            
        }
     
    }

}