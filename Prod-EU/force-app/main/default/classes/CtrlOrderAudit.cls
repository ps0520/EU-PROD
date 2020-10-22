/*************************************************************************************************
Apex Class Name : OrderAudit
Version : 0.1
Created Date :  13 Dec, 2018
Function :  This is a server-side class for Order_Audit Component. 
---------------------------------------------------------------------------------------------------
* Developer  LTI                     Date 13 Dec, 2018                           	
**************************************************************************************************/
public class CtrlOrderAudit {
    // Class to Throw Custom exception
    public class applicationException extends Exception {}
    
    // This method Returns the Visibility and Access level indicators through a Wrapper Class
    @auraenabled
    public static wrapperClass getaccessibility(string recid){
        list<RecordType> lstrt = new list<RecordType>();
        set<string> srid = new set<string>();
        wrapperClass returnwrapperClass = new  wrapperClass ();
        returnwrapperClass.hasAccess=false;
        returnwrapperClass.isEditable=false;
        returnwrapperClass.iscomplete=false;
        list<Audit_Tracker__c> lstAt = new list<Audit_Tracker__c> ();
        
        list<order> lstorder= [select id,status,shipping_hold_status__c 
                               from order
                               where id=:recid]; 
        if(lstorder.size() > 0){
            returnwrapperClass.hasAccess=true;
            returnwrapperClass.Shipholdstatus=lstorder[0].shipping_hold_status__c;
            if(lstorder[0].shipping_hold_status__c == 'completed'){
                returnwrapperClass.iscomplete=true;   			      
            }
            Boolean canAudit = (FeatureManagement.checkPermission('DE_Can_Audit_Orders') || FeatureManagement.checkPermission('Can_Audit_Orders'));
            if(lstorder[0].status.equalsIgnoreCase('shipping hold') && canAudit == true){
                returnwrapperClass.isEditable=true;
            }    
        }
        //}
        return returnwrapperClass;
    }
    // This method Returns the Related Audit records
    @auraenabled
    public static Map<string,list<Audit_Tracker__c>> inithelpermethod(string recid){
        
        list<Audit_Tracker__c> lstAt = new list<Audit_Tracker__c> ();
        Map<string,list<Audit_Tracker__c>> mresult = new Map<string,list<Audit_Tracker__c>>();
        
        try{
            lstAt= [select id, Audit_Field_Name__c,Field_Verified__c,Object_id__c 
                    from Audit_Tracker__c
                    where Object_id__c != null
                    and Object_id__c=:recid
                   ];            
            if(lstAt.size() > 0){
                mresult.put('Success',lstAt);
            }  
        }catch (Exception e){
            mresult.put('Error-'+e.getMessage(),lstAt);
            throw new AuraHandledException('Error :  ' + e.getMessage());    
        }
        return mresult;
    }
    // This Method Saves the updated Audit Records
    @auraenabled
    public static string saveaudit(list<Audit_Tracker__c> auditrecs){
        String showerror = 'success';
        try{
            update auditrecs;
        } catch (Exception e){
            showerror = 'Error-'+e.getMessage();
            throw new AuraHandledException('Error :  ' + e.getMessage()); 
        }
        return showerror;
    }
    // This Method Submits the updated Audit Records. If all records are Audited, Order is Activated.
    // Else, Status is changed to 'Draft'
    @auraenabled
    public static string submitaudit(string  recordId,list<Audit_Tracker__c> lstaudit){
        //if (!ClsOrderHandlerStatic.runSubmitOrder()) return 'Submit is already being processed';
        String showerror = 'success';
        order o1 = new order();
        try{
            boolean auditincomplete = false;
            o1= [select id,status,ownerid,recordtypeid,shipping_hold_status__c, Payment_Id__c, Settlement_Id__c,
                 Payment_Terms__c, recordType.DeveloperName , Account.PersonContactId
                 from order 
                 where id =:recordId];
            for(Audit_Tracker__c at: lstaudit) {
                if(at.Field_Verified__c == false){
                    auditincomplete = true;
                }
            }
            System.debug('auditincomplete--'+auditincomplete);
            if(auditincomplete == true){
                System.debug('o1.ownerid--'+o1.ownerid);
                string result= CtrlOrderAudit.updateorder('draft',o1);
                update lstaudit; 
                
                Id tskQCRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('QC Hold').getRecordTypeId();
                task t = new task();
                System.debug('**RecordtypeName--'+o1.recordType.DeveloperName);
                if(o1.recordType.DeveloperName.startswithIgnoreCase('DE_')) {
                    t.subject = 'Please update Order Information and then, Change the status to Shipping Hold';
	               	t.ownerid=o1.ownerid;
	               	t.whatid=o1.id;
	               	insert t; 
                } else {
                    t.ownerid=o1.ownerid;
                    t.RecordTypeId = tskQCRecordTypeId;
                    t.whatid=o1.id;
                    t.WhoId = O1.Account.PersonContactId;
                    t.Type = 'QC Hold';
                    String Taskdata = 'Task'+'-'+JSON.serialize(t); 
                    return Taskdata; 
                }
            } else {
                System.debug('****Payment'+o1.Payment_Terms__c);
                if (o1.Payment_Terms__c == 'net0') { // Credit card is to be used
                    String recName = o1.RecordType.DeveloperName.removeEndIgnoreCase('_Read_Only');
                    Id recId = [Select Id from RecordType where SobjectType='Order' AND isActive=true AND DeveloperName = :recName].Id;
                    
                    if (String.isNotBlank(o1.Payment_Id__c)){
                        String result = ClsOrderEntryHandler.CCsettlePayment(o1.id);
                        if (result.startsWith('Error')) {
                            Order updOrd = new Order(Id = o1.Id, Status = 'Draft', RecordTypeID = recId, Settlement_Error__c = result,
                                                     Payment_Id__c = null);
                            update updOrd;
                            return result;
                        }
                    } else {
                        String result = ClsOrderEntryHandler.captureCCpayment(o1.id);
                        if (result.startsWith('Error')) {
                           Order updOrd = new Order(Id = o1.Id, Status = 'Draft', RecordTypeID = recId, Settlement_Error__c = result,
                                                     Payment_Id__c = null);
                            update updOrd;
                            return result;
                        }
                    }
                }
                
                ClsOrderHandlerStatic.executeOrderEventTriggerv11 = true;
                o1.Shipping_Hold_Status__c='completed';
                string result= CtrlOrderAudit.updateorder('activated',o1);
                update lstaudit;
            }
        } catch(DMLException e){
            showerror = 'Error-'+e.getMessage();
            throw new AuraHandledException('Error :  ' + e.getMessage()); 
        }   
        return showerror;
    }
    @auraEnabled
    public static string updateTask(String tskRecId,String tskSubjectInfo,String tskDueDate,String tskAssignTo,String recordId,String tskCmt){
        
        Order Ord= [select id, Account.PersonContactId from order where id =:recordId];
       
        Id tskQCRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('QC Hold').getRecordTypeId();
        Task tsk = new Task();
        tsk.Subject = tskSubjectInfo;
        tsk.RecordTypeId = tskQCRecordTypeId;
        tsk.Type = 'QC Hold';
        tsk.ActivityDate = Date.valueOf(tskDueDate);
        tsk.OwnerId = Id.valueOf(tskAssignTo);
        tsk.WhatId = recordId;
        tsk.Description = tskCmt;
        
        tsk.WhoId = Ord.Account.PersonContactId;
        insert tsk;
        System.debug('Task updated---'+tsk.Id);
        return 'Success';
    }
    // This Method Updates the Order Status and Record Type
    @auraenabled
    public static string updateorder(string status,order o1){
        string result='';
        String recName = o1.RecordType.DeveloperName.removeEndIgnoreCase('_Read_Only');
        Id recId = [Select Id from RecordType where SobjectType='Order' AND isActive=true AND DeveloperName = :recName].Id;
        try{
            o1.Status = status;
            if (recId != null) o1.RecordTypeId = recId;
            update o1;
            result= 'success';
        }catch(Exception e){
            if(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                result = e.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
                Pattern pattern = Pattern.compile('[^a-z A-Z]');
                Matcher matcher = pattern.matcher(result);
                result = matcher.replaceAll('');
            }
            AuraHandledException ex = new AuraHandledException(result);
            ex.setMessage(result);
            throw ex;
        }   
        return result;   
    }
    
    @AuraEnabled    
    public Static Map<String,String> getTaskSubject(){
        Map<String,String> options = new Map<String,String>();
        
        /*Schema.DescribeFieldResult fieldResult = Task.Subject.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {*/
            options.put('Data Migration Issue','Data Migration Issue');
            options.put('Sales Request','Sales Request');
            options.put('Incorrect Address','Incorrect Address');
            options.put('PO/Patient ID Incorrect/Missing','PO/Patient ID Incorrect/Missing');
            options.put('Further Clarification Required','Further Clarification Required');
            options.put('VAT Issue','VAT Issue');
            options.put('Other','Other');
       // }
        
        
        return options;
    }
    
    @AuraEnabled
    public static String searchUser(String userId){
        User userinfo=new User();
        userinfo=[SELECT id From User where id=:userId and isActive = true limit 1]; // Removed ,name,isActive from selection list and added isActive to Where Claused. VA Sept 30, 2020
        return userinfo.Id;
    }
    
    
    // This is a Wrapper Class for Visibility and Access Indicators
    public class wrapperClass{
        @AuraEnabled public Boolean hasAccess{get;set;}
        @AuraEnabled public Boolean isEditable{get;set;}
        @AuraEnabled public Boolean iscomplete{get;set;}
        @AuraEnabled public string Shipholdstatus{get;set;}
    }
}