/*
@Author        : Kumar Navneet
@Date Created    : 17/02/2020
@Description    : Batch class for GB and IE Email Invoice Automation
****************************************************************************************/
global class BClsSendSdocInvoiceEmail implements Database.Batchable<Sobject> {    
    private List<SDOC__SDJob__c> jobList = new List<SDOC__SDJob__c> {};
    private Map<String, String> mapETemId = new Map<String, String>(); 
    private String country;
    
    global BClsSendSdocInvoiceEmail(String country){ 
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
               query+= ' AND Email_Invoice_Opt_In__c = true ' ; 
               query+= String.isNotBlank(orderType) && String.isNotEmpty(orderType) ? (' AND Type LIKE \'' + orderType + '\'') : '';
        system.debug('Start Query is' + query);                
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Order> scope){ 
        for(Order objOrder : scope){   
            if(objOrder.Invoice_Number__c != null && objOrder.Invoice_Number__c != ''){ 
            String accRecordType = objOrder.Payor__r.RecordType.name == null ? objOrder.Account.RecordType.Name : objOrder.Payor__r.RecordType.name;            
            String strPDFTemplateId = (accRecordType.startsWithIgnoreCase('IE Consumer') || accRecordType.startsWithIgnoreCase('IE Medical Facility')) && mapETemId.containsKey('IE Consumer Invoice') ? mapETemId.get('IE Consumer Invoice') : 
                                      accRecordType.startsWithIgnoreCase('IE Payor') && mapETemId.containsKey('IE Payor Invoice') ? mapETemId.get('IE Payor Invoice') :
                                      accRecordType.startsWithIgnoreCase('IE Pharmacy') && mapETemId.containsKey('IE Pharmacy Invoice') ? mapETemId.get('IE Pharmacy Invoice') :
                                      accRecordType.startsWithIgnoreCase('GB Consumer') && mapETemId.containsKey('UK Consumer Invoice') ? mapETemId.get('UK Consumer Invoice') :
                                      (accRecordType.startsWithIgnoreCase('GB Payor') || accRecordType.startsWithIgnoreCase('GB Medical Facility') || accRecordType.startsWithIgnoreCase('GB Pharmacy')) && mapETemId.containsKey('UK Payor Invoice') ? mapETemId.get('UK Payor Invoice') : '';
            
            String strHTMLTemplateId = (accRecordType.startsWithIgnoreCase('IE Consumer') || accRecordType.startsWithIgnoreCase('IE Medical Facility') || accRecordType.startsWithIgnoreCase('IE Pharmacy')) && mapETemId.containsKey('IE Consumer Email') ? mapETemId.get('IE Consumer Email') : 
                                       accRecordType.startsWithIgnoreCase('IE Payor') && mapETemId.containsKey('IE Payor Email') ? mapETemId.get('IE Payor Email') :
                                       accRecordType.startsWithIgnoreCase('GB Consumer') && mapETemId.containsKey('UK Consumer Email') ? mapETemId.get('UK Consumer Email') :
                                       (accRecordType.startsWithIgnoreCase('GB Payor') || accRecordType.startsWithIgnoreCase('GB Medical Facility') || accRecordType.startsWithIgnoreCase('GB Pharmacy')) && mapETemId.containsKey('UK Payor Email') ? mapETemId.get('UK Payor Email') : '';     
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