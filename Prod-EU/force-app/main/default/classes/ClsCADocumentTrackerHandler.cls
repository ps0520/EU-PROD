public class ClsCADocumentTrackerHandler {
    
    public static void afterOpportunityInsert(Map<Id, Opportunity> newOpps){
        
        try{
            System.Debug('**afterOpportunityInsert'+newOpps);
            String docsRequired = '';
            List<String> lstDocTypeReq = new List<String>();
            Map<String,Patient_Document__c> mapPatientDocs = new Map<String,Patient_Document__c>();
            List<Patient_Document__c> lstPatientDocs = new List<Patient_Document__c>();
            Map<String, Pdoc_To_Opportunity__c> oppLinkMap = new Map<String, Pdoc_To_Opportunity__c>();
            Map<String,Opportunity> mapOpportunityUpdate = new Map<String,Opportunity>();
            Set<String> reqdDocsSet = new Set<String>();
            List<String> lststrCheck = new List<String>();
            Map<String,String> mapReqDocs = new Map<String,String>();
            
            List<Opportunity> lstNewOpporunity = [Select id,Payor__c,AccountId from opportunity where id IN:newOpps.keySet()]; 
            System.debug('**lstNewOpporunity'+lstNewOpporunity[0].Payor__c);
            Map<String,List<String>> mapPdc = new Map<String,List<String>>();
            if(lstNewOpporunity.size()<200){
                for(Opportunity opp : lstNewOpporunity){
                    // As per vijay Confirmation we have added the SOQL in for loop
                    List<Account> lstPayor = [Select id,CA_Docs_Required__c from Account where id =:opp.Payor__c AND CA_Docs_Required__c !=null];
                    System.debug('**lstPayor'+lstPayor);
                    for(Account objAcc : lstPayor){
                        docsRequired = '';
                        docsRequired = String.valueOf(objAcc.CA_Docs_Required__c);                        
                        lstDocTypeReq = docsRequired.split(';');
                        System.debug('**lstDocTypeReq'+lstDocTypeReq);
                        reqdDocsSet.clear();
                        for(String docKey : lstDocTypeReq){
                            //String str = '\''+docKey+'\'';
                            reqdDocsSet.add(docKey);
                            //mapReqDocs.put(docKey,docKey);
                        }
                    }                   
                    System.debug('**reqdDocsSet--'+reqdDocsSet); 
                    for(Patient_Document__c Pdc :[Select id,Account__c,Account__r.Id,Doc_Type__c,Status__c from Patient_Document__c 
                                                  where Account__c = :opp.AccountId and Doc_Type__c IN:reqdDocsSet order by LastModifiedDate]){
                        mapPatientDocs.put(pdc.Doc_Type__c,Pdc);
                    }
                    
                    System.Debug('##mapPatientDocs'+mapPatientDocs.KeySet());
                    
                    for(String doc : reqdDocsSet) {
                        if (mapPatientDocs.containsKey(doc)){
                            oppLinkMap.put(doc, new PDoc_To_Opportunity__c (Patient_Document__c = mapPatientDocs.get(doc).Id, Opportunity__c = opp.Id));                   
                            
                        }else{
                            lstPatientDocs.add(new Patient_Document__c(Account__c = opp.AccountId, Doc_Type__c = doc, Collect_From__c = '', Status__c = 'Not Sent', Sent_Date__c = null, Received_Date__c = null));
                        }
                    }
                    if (lstPatientDocs.size() > 0) {
                        insert lstPatientDocs;
                        for(Patient_Document__c pdoc : lstPatientDocs) {
                            oppLinkMap.put(pdoc.Doc_Type__c, new PDoc_To_Opportunity__c (Patient_Document__c = pdoc.Id, Opportunity__c = opp.Id));                    
                        }
                    }
                }
                System.debug('**oppLinkMap'+oppLinkMap);
                if (oppLinkMap.size() > 0){
                  insert oppLinkMap.values();  
                }else{
                    System.debug('Else Executed--');
                    Opportunity oppUpdate = new Opportunity();
                    oppUpdate.Id =lstNewOpporunity[0].Id;
                    oppUpdate.CA_Customer_Docs_Collection_Status__c = 'Not Required';
                    oppUpdate.CA_Prescriber_Docs_Collection_Status__c = 'Not Required';
                    update oppUpdate;
                } 
                
            }else{
                //As per Vijay info we are inserting single doc through component screen
            }
        }catch(Exception ex){
            System.Debug('**afterOpportunityInsert Error at Line-->'+ex.getLineNumber());
            System.Debug('**afterOpportunityInsert Error-->'+ex.getMessage());
        }
        // Also need to update the CA_DOC collection status fields based on the document status.
    }
    
    public static void afterOpportunityUpdate(Map<Id, Opportunity> newOppsMap, Map<Id, Opportunity> oldOppsMap){
        
        
        try{
            System.debug('***afterOpportunityUpdate'+oldOppsMap);
            Map<Id, Opportunity> newNonNullOppsPyor = new Map<Id, Opportunity>();
            Map<Id, Opportunity> oldNonNullOppsPyor = new Map<Id, Opportunity>();
            for(Opportunity opp : newOppsMap.values()){
                If(opp.Payor__c != null){
                    newNonNullOppsPyor.put(opp.id, opp);
                    oldNonNullOppsPyor.put(opp.id, oldOppsMap.get(opp.Id));               
                }
            }
            System.debug('**NewOppsize--'+newNonNullOppsPyor.keySet());
            if(newNonNullOppsPyor.size()<=0){
                System.debug('**ExitProgram--');
                return;
            }
            
            // Ask Vijay IS ther any chances where bulk opportunity is Updated??
            List<Patient_Document__c> lstPatientDoc = new List<Patient_Document__c>();
            List<PDoc_To_Opportunity__c> lstPtDocOppTodel = new List<PDoc_To_Opportunity__c>();
            Map<Id, Opportunity> newOppsPyor = new Map<Id, Opportunity>();
            Set<Id> setPatientDocs = new Set<Id>();
            
            
            List<PDoc_To_Opportunity__c>  lstPdoc = [SELECT Id, Opportunity__c,Opportunity__r.Payor__c, Patient_Document__c FROM PDoc_To_Opportunity__c 
                                                     where Opportunity__c IN :newNonNullOppsPyor.keySet()]; 
            
            if(lstPdoc.size()>0){
                for(PDoc_To_Opportunity__c pdcObj :  lstPdoc){
                    System.debug('***NewPayor---'+newNonNullOppsPyor.get(pdcObj.Opportunity__c).Payor__c);
                    System.debug('***OldPayor---'+oldNonNullOppsPyor.get(pdcObj.Opportunity__c).Payor__c);
                    if(newNonNullOppsPyor.get(pdcObj.Opportunity__c).Payor__c != oldNonNullOppsPyor.get(pdcObj.Opportunity__c).Payor__c ){
                        lstPtDocOppTodel.add(pdcObj);
                        newOppsPyor.put(pdcObj.Opportunity__c,newNonNullOppsPyor.get(pdcObj.Opportunity__c)); 
                    } 
                }
                
                if(lstPtDocOppTodel.size()>0){
                    delete lstPtDocOppTodel;
                }
                
                if(newOppsPyor.size()>0){
                    System.debug('***newOppsPyor---'+newOppsPyor);
                    afterOpportunityInsert(newNonNullOppsPyor);
                }
            }else{
                afterOpportunityInsert(newNonNullOppsPyor);
            }
            
        }catch(Exception ex){
            System.Debug('**afterOpportunityUpdate Error at Line-->'+ex.getLineNumber());
            System.Debug('**afterOpportunityUpdate Error-->'+ex.getMessage());
        }
    }
}