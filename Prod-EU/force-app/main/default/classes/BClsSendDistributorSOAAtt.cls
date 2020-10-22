/*
@Author         : Pravin Jagadale
@Date Created   : 22/09/2020
@Description    : 1 - When the order is placed under an account with the country- Korea, Australia, New Zealand - 
					  we would like the Distributor - APAC SOA (Order Acknowledgement) document to be sent to the Order Owner.
				  2 - Any other order placed under an account anywhere else, we would like the Distributor -
					  EMEA SOA document to be sent to the Order Owner.
Story Id		:NS-1491
****************************************************************************************/
global class BClsSendDistributorSOAAtt implements Database.Batchable<Sobject>{
	private List<SDOC__SDJob__c> jobList = new List<SDOC__SDJob__c> {};
    private Map<String, String> mapETemId = new Map<String, String>();
    private Map<String, String> mapPDFTemId = new Map<String, String>();
    private String country;
    global BClsSendDistributorSOAAtt(){
        //this.country = country;
        Set<String> sdocTemp = new Set<String>();
        sdocTemp.add('Distributor - APAC SOA');
        sdocTemp.add('Distributor - EMEA SOA');
        sdocTemp.add('SOA Doc To Order Owner Email Template');        
        //String recordTypeName = String.isNotBlank(country) && String.isNotEmpty(country) ? country + '%' : '';
        String templateQuery = 'Select Id, Name from SDOC__SDTemplate__c Where Name IN:sdocTemp';
        system.debug('Template Query is ' + templateQuery);
        for(SDOC__SDTemplate__c Sd : Database.query(templateQuery)){
            this.mapETemId.put(Sd.Name, Sd.Id);
        }
        
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
      
        String query = 'SELECT Id,Account.Country__c, Status,Payor__r.RecordType.name, Account.RecordType.Name, Owner.Email FROM Order ';
        query+= ' where Status = \'Closed\'' ; 
        system.debug('Start Query is' + query);                
        return Database.getQueryLocator(query);
       
    }
    global void execute(Database.BatchableContext BC, List<Order> scope){
        System.debug('scope--'+scope.size());
        for(Order objOrder : scope){
            System.debug('objOrder--'+objOrder);            
            String accCountry = objOrder.Account.Country__c;
            String accRecordType = objOrder.Payor__r.RecordType.name == null ? objOrder.Account.RecordType.Name : objOrder.Payor__r.RecordType.name;
            String strPDFTemplateId = accCountry.containsIgnoreCase('Korea') || accCountry.containsIgnoreCase('New Zealand') || accCountry.containsIgnoreCase('Australia') ? mapETemId.get('Distributor - APAC SOA') : mapETemId.get('Distributor - EMEA SOA');
            String strHTMLTemplateId = mapETemId.get('SOA Doc To Order Owner Email Template') ;     
            List<String> lstTemplateIds = new List<String>();
            if(String.isNotEmpty(strPDFTemplateId) && String.isNotBlank(strPDFTemplateId)) lstTemplateIds.add(strPDFTemplateId);
            if(String.isNotEmpty(strHTMLTemplateId) && String.isNotBlank(strHTMLTemplateId)) lstTemplateIds.add(strHTMLTemplateId);
            if(!lstTemplateIds.isEmpty()){                
                jobList.add(new SDOC__SDJob__c(SDOC__Start__c = true,  SDOC__Oid__c = objOrder.Id, SDOC__ObjApiName__c = 'Order', SDOC__SendEmail__c = '1', SDOC__Doclist__c = String.join(lstTemplateIds, ','))); 
            }   
                
        }
        System.debug('**jobList--'+jobList.size()); 
        if(!jobList.isEmpty())insert jobList;
        
    }
    global void finish(Database.BatchableContext BC){
        System.debug('Finish--');
    }
}