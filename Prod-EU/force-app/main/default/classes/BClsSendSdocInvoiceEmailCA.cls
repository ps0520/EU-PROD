/*
@Author        : Kumar Navneet
@Date Created    : 14/07/2020
@Description    : Batch class for CA Email Invoice Automation
****************************************************************************************/
global class BClsSendSdocInvoiceEmailCA implements Database.Batchable<Sobject> {    
    private List<SDOC__SDJob__c> jobList = new List<SDOC__SDJob__c> {};
    private Map<String, String> mapETemId = new Map<String, String>(); 
    private String country;
    private List<String> OrderID;
    
    global BClsSendSdocInvoiceEmailCA(String country, List<String> OrderID){ 
        this.country = country;
        this.OrderID = OrderID;
        //Get all the invoice templates that are required for processing
        String recordTypeName = String.isNotBlank(country) && String.isNotEmpty(country) ? country + '%' : '';
        String templateQuery = 'Select Id, Name from SDOC__SDTemplate__c Where SDOC__Document_Category__c = \'Invoice\'';
        templateQuery+= String.isNotBlank(recordTypeName) && String.isNotEmpty(recordTypeName) ? (' AND Recordtype.Name LIKE \'' + recordTypeName + '\'') : '';
        templateQuery+= OrderID.size() > 0 && !OrderID.isempty() ? ' AND ID in :OrderID' : '';
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
            String accRecordType = objOrder.Payor__r.RecordType.name == null ? objOrder.Account.RecordType.Name : objOrder.Payor__r.RecordType.name;            
          //  String strPDFTemplateId = (accRecordType.startsWithIgnoreCase('CA Consumer') || accRecordType.startsWithIgnoreCase('CA Payor'))  && mapETemId.containsKey('CA Consumer Invoice') ? mapETemId.get('CA Consumer Invoice') : ''; 
                
            String strPDFTemplateId = accRecordType.startsWithIgnoreCase('CA Consumer')  && mapETemId.containsKey('CA Consumer Invoice') ? mapETemId.get('CA Consumer Invoice') :                                      
                                        accRecordType.startsWithIgnoreCase('CA Payor')  && mapETemId.containsKey('CA Payor Invoice') ? mapETemId.get('CA Payor Invoice') : '';              
            String strHTMLTemplateId = (accRecordType.startsWithIgnoreCase('CA Consumer') || accRecordType.startsWithIgnoreCase('CA Payor')) && mapETemId.containsKey('CA Consumer Email') ? mapETemId.get('CA Consumer Email') : '';     
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