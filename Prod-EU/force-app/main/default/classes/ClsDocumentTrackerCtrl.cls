/*******************************************************************************************
@Author        : Pravin jagadale
@Date Created  : 06/25/2020
@Description   : Covers Dcoument Tracker functionality
*********************************************************************************************/
public class ClsDocumentTrackerCtrl {
    
    @AuraEnabled
    public static List<PDoc_To_Opportunity__c> fetchRequiredDoc(String oppRecId){
		
        try{
            
            List<PDoc_To_Opportunity__c> lst = [Select id,Opportunity__c ,Patient_Document__r.Doc_type__c,
                                                Patient_Document__r.Status__c,
                                                Patient_Document__r.Received_Date__c,
                                                Patient_Document__r.Collect_From__c,
                                                Patient_Document__r.Sent_Date__c,
                                                Patient_Document__r.Account__c
                                                from PDoc_To_Opportunity__c
                                                where Opportunity__c =:oppRecId];
            System.debug('**fetchRequiredDoc'+lst);
            if(lst.size()>0){
                return lst;
            }
            return null;
        }catch(Exception ex){
            throw new AuraHandledException('Here is what fishy: '+ ex.getMessage());    
        }        
    }
    
    @AuraEnabled
    public static Boolean opportunityStageCheck(String oppRecId){
        
        boolean addDocsVisible = false;
        Opportunity opp = [Select id,Stagename from Opportunity
                          where Id=:oppRecId];
        if(opp.StageName == 'New Opportunity' || opp.StageName == 'Customer Doc Collection' ){
            addDocsVisible = true;
        }
        
        return addDocsVisible;
    }
    
    @AuraEnabled
    public static List<PDoc_To_Opportunity__c> deletePdocToOpppRec(String PdocId,String OpprecId){
        System.debug('***PdocId--'+PdocId);
        String accId = '';
        List<PDoc_To_Opportunity__c> pdocObj = [Select id,Opportunity__c,Opportunity__r.AccountId,Patient_Document__r.Id
                                          from PDoc_To_Opportunity__c
                                          where Patient_Document__r.Id =:PdocId AND Opportunity__c=:OpprecId ];
        accId = pdocObj[0].Opportunity__r.AccountId;
        delete pdocObj;
        
        //Opportunity Stage Update if all docs status is received
        List<String> lstStr = new List<String>();            
       // List<PDoc_To_Opportunity__c> lst = fetchRequiredDoc(OpprecId);
       // AccountId filter needs to be added in SOQL 
       List<PDoc_To_Opportunity__c> lst = [Select id,Opportunity__c ,Patient_Document__r.Doc_type__c,
                                                Patient_Document__r.Status__c,
                                                Patient_Document__r.Received_Date__c,
                                                Patient_Document__r.Collect_From__c,
                                                Patient_Document__r.Sent_Date__c,
                                                Patient_Document__r.Account__c
                                                from PDoc_To_Opportunity__c
                                                where Opportunity__c =:oppRecId AND Patient_Document__r.Account__c=:accId ];
        Opportunity opp = new Opportunity();
        opp.Id = OpprecId;
      
        if(lst.size()>0){
            
                Map<String,Integer> mapStatus = new Map<String,Integer>();
                mapStatus.put('Not Required',0);
                mapStatus.put('Received',1);
                mapStatus.put('Sent',2);
                mapStatus.put('Not Sent',3);
                
            Map<String,Integer> mapCollectfrm = new Map<String,Integer>();
            mapCollectfrm.put(null,-1);
            mapCollectfrm.put('Physician',0);
            mapCollectfrm.put('Patient',1);
            mapCollectfrm.put('Caseworker',2);
            mapCollectfrm.put('Online Form',3);
                
                opp.CA_Customer_Docs_Collection_Status__c = 'Not Required';
                opp.CA_Prescriber_Docs_Collection_Status__c = 'Not Required';
                Boolean pendingflag = false;
                for(PDoc_To_Opportunity__c pdc:  lst){
                    if(mapStatus.containskey(pdc.Patient_Document__r.Status__c)){
                        Integer key = mapStatus.get(pdc.Patient_Document__r.Status__c);
                        Integer cfKey = mapCollectfrm.get(pdc.Patient_Document__r.Collect_from__c);
                        
                        system.debug('**key--'+key+'--cfKey--'+cfKey);
                        if(key == 1 && cfKey >= 1 && pendingflag == false ){
                            opp.CA_Customer_Docs_Collection_Status__c = 'All Docs Received';
                            system.debug('**1 If');
                        }else if((key == 2 && cfKey >= 1) || (key==3 && cfKey >= 1) ){
                            opp.CA_Customer_Docs_Collection_Status__c = 'Pending';
                            pendingflag = true;
                            system.debug('**2 If');
                            
                        }else if(key == 1 && cfKey == 0 ){
                            opp.CA_Prescriber_Docs_Collection_Status__c = 'Docs Received';
                             system.debug('**3 If');
                            
                        }else if(key == 2 && cfKey == 0 ){
                             opp.CA_Prescriber_Docs_Collection_Status__c = 'Pending';
                             system.debug('**4 If');
                        }else if((key == 2 && cfKey == -1) || (key==3 && cfKey == -1)){
                            opp.CA_Customer_Docs_Collection_Status__c = 'Pending';
                            pendingflag = true;
                        }
                    }           
                }
                update opp; 
        }
        return lst;
        //return null;
        
    }
    
    @AuraEnabled
    public static Patient_Document__c fetchPatientRec(String Pdoc){        
        try{
            
            Patient_Document__c pdocObj =[SELECT Id, Doc_Type__c, Status__c, Collect_From__c, 
                                          Sent_Date__c, Received_Date__c, Account__c
                                          FROM Patient_Document__c where Id=:Pdoc];
            return pdocObj;
        }catch(Exception ex){            
            System.debug('***Error--'+ex.getLineNumber()); 
            return null;
        }
    }
	 @AuraEnabled    
    public Static void savePatientDocs(Patient_Document__c recCF,String oppId){
        try{
            String recFd ='';
            insert recCF;  
            
            PDoc_To_Opportunity__c pdOpp = new PDoc_To_Opportunity__c();            
            pdOpp.Patient_Document__c = recCF.Id; 
            pdOpp.Opportunity__c = oppId;
            insert pdOpp;
            System.debug('**pdOpp'+pdOpp);
            
            //Opportunity Docs Status Update if all docs status is received
            List<String> lstStr = new List<String>();            
            List<PDoc_To_Opportunity__c> lst = fetchRequiredDoc(oppId);
            Opportunity opp = new Opportunity();
            opp.Id = oppId;
            if(lst.size()>0){
                Map<String,Integer> mapStatus = new Map<String,Integer>();
                mapStatus.put('Not Required',0);
                mapStatus.put('Received',1);
                mapStatus.put('Sent',2);
                mapStatus.put('Not Sent',3);
                
                Map<String,Integer> mapCollectfrm = new Map<String,Integer>();
                mapCollectfrm.put(null,-1);
                mapCollectfrm.put('Physician',0);
                mapCollectfrm.put('Patient',1);
                mapCollectfrm.put('Caseworker',2);
                mapCollectfrm.put('Online Form',3);
                
                opp.CA_Customer_Docs_Collection_Status__c = 'Not Required';
                opp.CA_Prescriber_Docs_Collection_Status__c = 'Not Required';
                Boolean pendingflag = false;
                for(PDoc_To_Opportunity__c pdc:  lst){
                    if(mapStatus.containskey(pdc.Patient_Document__r.Status__c)){
                        Integer key = mapStatus.get(pdc.Patient_Document__r.Status__c);
                        Integer cfKey = mapCollectfrm.get(pdc.Patient_Document__r.Collect_from__c);
                        
                        system.debug('**key--'+key+'--cfKey--'+cfKey);
                        if(key == 1 && cfKey >= 1 && pendingflag == false ){
                            opp.CA_Customer_Docs_Collection_Status__c = 'All Docs Received';
                            system.debug('**1 If');
                        }else if((key == 2 && cfKey >= 1) || (key==3 && cfKey >= 1) ){
                            opp.CA_Customer_Docs_Collection_Status__c = 'Pending';
                            pendingflag = true;
                            system.debug('**2 If');
                            
                        }else if(key == 1 && cfKey == 0 ){
                            opp.CA_Prescriber_Docs_Collection_Status__c = 'Docs Received';
                             system.debug('**3 If');
                            
                        }else if(key == 2 && cfKey == 0 ){
                             opp.CA_Prescriber_Docs_Collection_Status__c = 'Pending';
                             system.debug('**4 If');
                        }else if((key == 2 && cfKey == -1) || (key==3 && cfKey == -1)){
                            opp.CA_Customer_Docs_Collection_Status__c = 'Pending';
                            pendingflag = true;
                        }
                    }           
                }
                update opp; 
            }
            System.debug('Insertion Successful--'+recCF.Id);
        }catch(Exception ex){
           System.debug('**Insert Error at Line -'+ ex.getLineNumber()); 
            System.debug('**Insert Error -'+ ex); 
        }
    }    
    
    @AuraEnabled
    public static void updatePatientDocs(Patient_Document__c recCF,String PDocRecId,String oppId){
        try{
            recCF.Id=  Id.valueOf(PDocRecId);
            update recCF;
            /*List<PDoc_To_Opportunity__c> lstPdOp = [Select Patient_Document__c,Opportunity__c 
                                                    from PDoc_To_Opportunity__c
                                                    where Patient_Document__c=:PDocRecId];*/
            //String OppId = lstPdOp[0].Opportunity__c;
            //Opportunity Stage Update if all docs status is received
            List<String> lstStr = new List<String>();            
            List<PDoc_To_Opportunity__c> lst = fetchRequiredDoc(OppId);
            System.debug('**lst--'+lst.size());
            System.debug('**OppId'+oppId);
            Opportunity opp = new Opportunity();
            opp.Id = oppId;
            if(lst.size()>0){
                
                Map<String,Integer> mapStatus = new Map<String,Integer>();
                mapStatus.put('Not Required',0);
                mapStatus.put('Received',1);
                mapStatus.put('Sent',2);
                mapStatus.put('Not Sent',3);
                
                Map<String,Integer> mapCollectfrm = new Map<String,Integer>();
                mapCollectfrm.put(null,-1);
                mapCollectfrm.put('Physician',0);
                mapCollectfrm.put('Patient',1);
                mapCollectfrm.put('Caseworker',2);
                mapCollectfrm.put('Online Form',3);
                
                opp.CA_Customer_Docs_Collection_Status__c = 'Not Required';
                opp.CA_Prescriber_Docs_Collection_Status__c = 'Not Required';
                Boolean pendingflag = false;
                for(PDoc_To_Opportunity__c pdc:  lst){
                    if(mapStatus.containskey(pdc.Patient_Document__r.Status__c)){
                        Integer key = mapStatus.get(pdc.Patient_Document__r.Status__c);
                        Integer cfKey = mapCollectfrm.get(pdc.Patient_Document__r.Collect_from__c);
                        
                        system.debug('**key--'+key+'--cfKey--'+cfKey);
                        if(key == 1 && cfKey >= 1 && pendingflag == false ){
                            opp.CA_Customer_Docs_Collection_Status__c = 'All Docs Received';
                            system.debug('**1 If');
                        }else if((key == 2 && cfKey >= 1) || (key==3 && cfKey >= 1) ){
                            opp.CA_Customer_Docs_Collection_Status__c = 'Pending';
                            pendingflag = true;
                            system.debug('**2 If');
                            
                        }else if(key == 1 && cfKey == 0 ){
                            opp.CA_Prescriber_Docs_Collection_Status__c = 'Docs Received';
                             system.debug('**3 If');
                            
                        }else if(key == 2 && cfKey == 0 ){
                             opp.CA_Prescriber_Docs_Collection_Status__c = 'Pending';
                             system.debug('**4 If');
                        }else if((key == 2 && cfKey == -1) || (key==3 && cfKey == -1)){
                            opp.CA_Customer_Docs_Collection_Status__c = 'Pending';
                            pendingflag = true;
                        }
                    }           
                }
                               
            }
             update opp; 
            System.debug('**opp--'+opp);
            System.debug('Update Succesful--'+recCF.Id);
        }catch(Exception ex){
            System.debug('**ErrorLine--'+ex.getLineNumber());
            System.debug('**ErrorMsg--'+ex);
            
            throw new AuraHandledException('Here is what fishy: '+ ex.getMessage());
           //System.debug('Update Error at Line -'+ ex.getLineNumber());
        }
    }
    @AuraEnabled
    public static String fetchAccId(String oppRecId){        
        try{
            
           Opportunity opp = [select id,AccountId from Opportunity where Id=:oppRecId];
            //system.debug('');
            return  opp.AccountId;
            
        }catch(Exception ex){            
            System.debug('***Error--'+ex.getLineNumber()); 
            return null;
        }
    }
       
    @AuraEnabled    
    public Static Map<String,String> getDocTypePicklist(){
        Map<String,String> options = new Map<String,String>();
        Schema.DescribeFieldResult fieldResult = Patient_Document__c.Doc_Type__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            options.put(p.getValue(),p.getLabel());
        }
        return options;
    }
    @AuraEnabled    
    public Static Map<String,String> getDocStatusPicklist(){
        Map<String,String> options = new Map<String,String>();
        Schema.DescribeFieldResult fieldResult = Patient_Document__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            options.put(p.getValue(),p.getLabel());
        }
        return options;
    }
    @AuraEnabled    
    public Static Map<String,String> getCLFPicklist(){
        Map<String,String> options = new Map<String,String>();
        Schema.DescribeFieldResult fieldResult = Patient_Document__c.Collect_From__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            options.put(p.getValue(),p.getLabel());
        }
        return options;
    }
}