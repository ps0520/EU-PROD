global class BClsSSIPRuleDeactivate implements Database.Batchable<Sobject>{
	private final Date sdt;
    private final Date edt;
    public BClsSSIPRuleDeactivate(){
        this.sdt = Date.today();
        this.edt = Date.today();
    }
    public BClsSSIPRuleDeactivate(Date sdt, Date edt){
        this.sdt = sdt;
        this.edt = edt == null ? sdt : edt;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id, Status__c, Renewal_date__c, Rule_End_Date__c FROM SSIP_Rule__c WHERE Status__c = \'Active\' AND ((Rule_End_Date__c >=:sdt AND Rule_End_Date__c <=: edt) or ( renewal_date__c >= :sdt AND Renewal_Date__c <= :edt))');
    }
    global void execute(Database.BatchableContext BC, List<SSIP_Rule__c> scope){
        for(SSIP_Rule__c ssipRule : scope){
            if (ssipRule.Rule_End_Date__c >= sdt && ssipRule.Rule_End_Date__c <= edt)   ssipRule.Status__c = 'Inactive';
            else if (ssipRule.Renewal_date__c >= sdt && ssipRule.Renewal_date__c <= edt)   ssipRule.Renewal_date__c = ssipRule.Renewal_date__c + 360;
        }
        update scope;
    }
    global void finish(Database.BatchableContext BC){
        
    }
}