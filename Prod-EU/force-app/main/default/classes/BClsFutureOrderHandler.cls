/*
@Author        : Kumar Navneet
@Date Created    : 09/01/2020
@Description    : Batch class 
****************************************************************************************/
global class BClsFutureOrderHandler implements Database.Batchable<Sobject>, Database.AllowsCallouts {
    private final Date sdt;
    private final Date edt;
    private String country;
    private Set<Id> OrdIDSet = new Set<Id>();
    private Set<String> OrdNoSet = new Set<String>();
	private id recTypeId; 
    
    public BClsFutureOrderHandler(Date sdt, Date edt, String country, Set<Id> OrdIDSet, Set<String> OrdNoSet){
        this.sdt = sdt;
        this.edt = edt == null ? sdt : edt;
        this.country = country;
        this.OrdIDSet = OrdIDSet;
        this.OrdNoSet = OrdNoSet;
		this.recTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get(country+' Sales Order Read Only').getRecordTypeId();
    }    
    global BClsFutureOrderHandler(){ 
        this.sdt = Date.today();
        this.edt = Date.today();               
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        String orderType = String.isNotBlank(country) && String.isNotEmpty(country) ? country + '%' : '';
        String query = 'SELECT id, EffectiveDate, payment_terms__c, total_gross_Price__c, type, Account.RecordType.Name, accountId , Account.Subscription_Pending_Payments__c, Count_of_Order_Line_Items__c from order ';
               query+= ' where status = \'Draft\'' ; 
               query+= ' and Account.Credit_Hold__c = false AND EffectiveDate >= :sdt AND EffectiveDate <= :edt ' ;  
               query+= ' AND Future_Order__c = true';
 			    query+= OrdIDSet != null && !OrdIDSet.isEmpty() ? ' AND ID in :OrdIDSet ' : '';
                query+= OrdNoSet != null && !OrdNoSet.isEmpty() ? ' AND OrderNumber in :OrdNoSet ' : '';
        	    query+= String.isNotBlank(orderType) && String.isNotEmpty(orderType) ? ' AND Type LIKE: orderType ': '';
        system.debug('start' + query);                
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Order> scope){ 
        for(Order o : scope){
            if (o.payment_terms__c == 'net30') {
                if(ClsOUSTaxCalculator.calculateTax(o.id).containsignorecase('VAT/TAX Calculation Failed')) {
                    continue;
                } else {
                    update new Order(Id = o.id, Status = 'Shipping Hold', recordTypeId = recTypeId);
                }
            } else if (o.payment_terms__c == 'net0' && o.total_gross_Price__c == 0) {
                if (ClsOUSTaxCalculator.calculateTax(o.id).containsignorecase('VAT/TAX Calculation Failed')) {
                    continue;
                } else {
                    ClsOrderHandlerStatic.executeOrderEventTriggerv11 = true;
                    update new Order(Id = o.Id, Status = 'Activated', recordTypeId = recTypeId); 
                }
            } else {
                System.enqueueJob(new SSIPScheduleJobUtiltiy.CalculateTaxQueueable(String.valueof(o.Id), o.payment_terms__c, o.Account.RecordType.Name.substring(0,2), (Integer) o.Count_of_Order_Line_Items__c , (Integer) o.Account.Subscription_Pending_Payments__c , o.accountId, false));
            } 
        }    update scope;
    }
    global void finish(Database.BatchableContext BC){
        system.debug('Order Finish: ');    }
}