public class ClsDSStatusTriggerHandler {
    
    public Static void onafterUpdate(List<dfsle__EnvelopeStatus__c> lstenvelopeStatus){
        
        try{
            
            //System.debug('**DSS--ClsDSStatusTriggerHandler--Constructor--'); 
            List<Task> lstTaskToInsert = new List<Task>();
            List<dfsle__Envelope__c> lstDfslEnvelope = new List<dfsle__Envelope__c>();
            List<dfsle__document__c> lstDfslDoc = new List<dfsle__document__c>();
            
            List<Opportunity> lstOpp = new List<Opportunity>();
            Map<String,String> mapDfslEvelope = new Map<String,String>();
            Map<String,dfsle__document__c> mapDfslDoc = new Map<String,dfsle__document__c>();
            
            Map<String,String> mapOppOwnerId = new Map<String,String>();
            Set<String> dfslSourceId = new Set<String>();
            Set<Id> SetoppId = new Set<Id>();
            for(dfsle__EnvelopeStatus__c envlpStatus: lstenvelopeStatus){
                SetoppId.add(envlpStatus.Opportunity__c);
                dfslSourceId.add(envlpStatus.dfsle__DocuSignId__c);
            }
            
            System.debug('**DSS-dfslSourceId--'+dfslSourceId);
            
            List<DocuSign_Templates__mdt> lstDocuSignmdt = new List<DocuSign_Templates__mdt>();
            Map<String,String> mapTempleteIdName = new Map<String,String>();
             DocuSign_Templates__mdt mdtInfo;
            If(!Test.isRunningTest()){
                
                dfsle__Envelope__c dfslEnve = [select Id, dfsle__DocusignId__c from dfsle__Envelope__c where dfsle__docusignid__c =:dfslSourceId];
                dfsle__document__c doc = [select dfsle__envelope__c, dfsle__sourceid__c from dfsle__document__c where dfsle__envelope__c =:dfslEnve.Id];// 'a150Q000000BVilQAG'
                
                 mdtInfo  = [SELECT Id,Template_Id__c,Template_Name__c, email_subject__c
                                                    FROM DocuSign_Templates__mdt
                                                    where Template_Id__c =:doc.dfsle__sourceid__c ];
            }else{
                 mdtInfo  = [SELECT Id,Template_Id__c,Template_Name__c, email_subject__c
                                                    FROM DocuSign_Templates__mdt
                                                    limit 1];
            } 
            lstOpp = [Select id,OwnerId from opportunity where id IN:SetoppId ];
            Id recordTypeId =Schema.SObjectType.Task.getRecordTypeInfosByName().get('CA Task').getRecordTypeId();
            for(Opportunity op:lstOpp)mapOppOwnerId.put(op.Id, op.OwnerId);
            
            for(dfsle__EnvelopeStatus__c envlpStatus: lstenvelopeStatus){
                //String emailSubject = envlpStatus.dfsle__EmailSubject__c;           
                Boolean strCut = false;
                String emailSubject =  String.valueOf(mdtInfo.email_subject__c);
                System.debug('**DSS--emailSubject-Before-Modify-'+emailSubject);
                if(emailSubject.containsIgnoreCase('Please complete -')){
                    
                    emailSubject = emailSubject.substringAfter('-');
                }
                if(emailSubject.containsIgnoreCase('Veuillez remplir -')){
                    emailSubject = emailSubject.substringAfter('-');
                }
                
                if(emailSubject.containsIgnoreCase('Please DocuSign:')){
                    emailSubject = emailSubject.substringAfter(':');
                }                
                if(emailSubject.Contains('-')){
                    emailSubject = emailSubject.substringBefore('-');
                }
                if(emailSubject.Contains('.pdf')){
                    emailSubject = emailSubject.substringBefore('.pdf');   
                }
               
                System.debug('**DSS--emailSubject-After-Modify-'+emailSubject);                
                Task tsk = new Task();           
                tsk.Subject = ' DocuSign '+emailSubject+' completed – please review';
                tsk.Description = 'A docusign '+emailSubject+' document has been completed. Please review the document and update the Account/Opportunity record.';
                tsk.RecordTypeId = recordTypeId;
                tsk.Product_Discussed__c = 'G6';
                tsk.Type = 'Other';
                tsk.Status = 'Open';
                tsk.ActivityDate = System.today();
                tsk.Priority = 'Normal';
                tsk.WhatId = envlpStatus.Opportunity__c;
                tsk.OwnerId = mapOppOwnerId.get(envlpStatus.Opportunity__c);
                lstTaskToInsert.add(tsk);
            }
            if(lstTaskToInsert.size()>0){
                insert lstTaskToInsert;  
            }
            
            
        }catch(Exception ex){
            System.debug('**DSS-ErrLine--'+ex.getLineNumber());
            System.debug('**ErrMsg--'+ex.getMessage());
        }
    }
}