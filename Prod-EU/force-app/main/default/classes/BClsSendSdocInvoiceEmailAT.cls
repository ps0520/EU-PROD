/*
@Author        : Kumar Navneet
@Date Created    : 26/05/2020
@Description    : Batch class for AT Email Invoice Automation
****************************************************************************************/
global class BClsSendSdocInvoiceEmailAT implements Database.Batchable<Sobject> {    
    private List<SDOC__SDJob__c> jobList = new List<SDOC__SDJob__c> {};
    private Map<String, String> mapETemId = new Map<String, String>(); 
    private String country;
    
    global BClsSendSdocInvoiceEmailAT(String country){ 
        this.country = country;
        //Get all the invoice templates that are required for processing
        String recordTypeName = String.isNotBlank(country) && String.isNotEmpty(country) ? country + '%' : '';
        String templateQuery = 'Select Id, Name from SDOC__SDTemplate__c Where SDOC__Document_Category__c = \'Invoice\'';
        templateQuery+= String.isNotBlank(recordTypeName) && String.isNotEmpty(recordTypeName) ? (' AND Recordtype.Name LIKE \'' + recordTypeName + '\'') : '';
        system.debug('Template Query is ' + templateQuery);
        for(SDOC__SDTemplate__c Sd : Database.query(templateQuery)){
            this.mapETemId.put(Sd.Name, Sd.Id);
        }
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        //If there is no country filter then query for all Orders that are to be processed for Email Invoicing
        String orderType = String.isNotBlank(country) && String.isNotEmpty(country) ? country + '%' : '';
        String query = 'SELECT Id, Payor__r.RecordType.name, Account.RecordType.Name, Invoice_Number__c FROM Order ';
               query+= ' where Invoice_Email_Status__c = \'Pending\'' ;                  
               query+= ' AND Email_Invoice_Opt_In__c = true';
               query+= String.isNotBlank(orderType) && String.isNotEmpty(orderType) ? (' AND Type LIKE \'' + orderType + '\'') : '';
        system.debug('Start Query is' + query);                
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Order> scope){ 
        for(Order objOrder : scope){   
            if(objOrder.Invoice_Number__c != null && objOrder.Invoice_Number__c != ''){ 
            String accRecordType = objOrder.Account.RecordType.Name;            
            String strPDFTemplateId = accRecordType.startsWithIgnoreCase('AT Consumer')  && mapETemId.containsKey('AT_Invoice-PP_Fusion') ? mapETemId.get('AT_Invoice-PP_Fusion') : '';            
            String strHTMLTemplateId = accRecordType.startsWithIgnoreCase('AT Consumer') && mapETemId.containsKey('AT Consumer Email') ? mapETemId.get('AT Consumer Email') : '';     
            List<String> lstTemplateIds = new List<String>();
            if(String.isNotEmpty(strPDFTemplateId) && String.isNotBlank(strPDFTemplateId)) lstTemplateIds.add(strPDFTemplateId);
            if(String.isNotEmpty(strHTMLTemplateId) && String.isNotBlank(strHTMLTemplateId)) lstTemplateIds.add(strHTMLTemplateId);
            if(!lstTemplateIds.isEmpty()){                
                jobList.add(new SDOC__SDJob__c(SDOC__Start__c = true,  SDOC__Oid__c = objOrder.Id, SDOC__ObjApiName__c = 'Order', SDOC__SendEmail__c = '1', SDOC__Doclist__c = String.join(lstTemplateIds, ','))); 
            }    
             update new Order(Id = objOrder.Id, Invoice_Email_Status__c = 'Sent'); 
        }  
    }
        
        if(!jobList.isEmpty())insert jobList;
        update scope;
    }
    global void finish(Database.BatchableContext BC){
        system.debug('Order Finish: ');    }
}