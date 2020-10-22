public class SSIPScheduleTriggerHandler {
    
    public Map<Id, SSIP_Rule__c> mapRule = new Map<Id, SSIP_Rule__c>();
    public void onAfterUpdate(List<SSIP_Schedule__c> lstSSIPScheduleNew, Map<Id, SSIP_Schedule__c> mapScheduleOld){
        List<SSIP_Schedule__c> lstSSIPSchedule = new List<SSIP_Schedule__c>();
        List<SSIP_Schedule__c> lstSSIPScheduleFilter = new List<SSIP_Schedule__c>();
        List<SSIP_Schedule__c> lstCASSIPScheduleFilter = new List<SSIP_Schedule__c>();
        Set<Id> setSSIPRuleIds = new Set<Id>();
        for(SSIP_Schedule__c ssipRule : lstSSIPScheduleNew){
            
            String prdName = ssipRule.Product_Name__c;
            
            if( (ssipRule.Status__c == 'In Progress' || ssipRule.Status__c == 'In Draft') && ssipRule.Status__c != mapScheduleOld.get(ssipRule.Id).Status__c && ssipRule.Country__c != 'Canada' && !prdName.startsWith('MT')){
                setSSIPRuleIds.add(ssipRule.SSIP_Rule__c);
                lstSSIPScheduleFilter.add(ssipRule);
            }
            
            if(ssipRule.Country__c == 'Canada' && prdName.startsWith('MT') && (ssipRule.Status__c == 'In Progress' || ssipRule.Status__c == 'In Draft') && ssipRule.Status__c != mapScheduleOld.get(ssipRule.Id).Status__c ){
                lstCASSIPScheduleFilter.add(ssipRule);
                
            }
        }
        mapRule = new Map<Id, SSIP_Rule__c>([SELECT Id, Rule_End_Date__c, Frequency_In_Days__c, Payment_Term__c, Shipping_Address__c, Shipping_Method__c, (SELECT Id, Schedule_Date__c FROM SSIP_Schedule__r ORDER BY Schedule_Date__c DESC LIMIT 1) FROM SSIP_Rule__c WHERE Id IN: setSSIPRuleIds]);
        for(SSIP_Schedule__c ssipSchedule : lstSSIPScheduleFilter){
            if(mapRule.containsKey(ssipSchedule.SSIP_Rule__c) && mapRule.get(ssipSchedule.SSIP_Rule__c).Frequency_In_Days__c != null){
                SSIP_Rule__c rule = mapRule.get(ssipSchedule.SSIP_Rule__c);
                Date scheduleDate = rule.SSIP_Schedule__r.size() > 0 ? rule.SSIP_Schedule__r[0].Schedule_Date__c.addDays(Integer.valueOf(rule.Frequency_In_Days__c)) : Date.today().addDays(Integer.valueOf(rule.Frequency_In_Days__c));
                if(rule.Rule_End_Date__c == null || scheduleDate <= rule.Rule_End_Date__c){
                    lstSSIPSchedule.add(new SSIP_Schedule__c(Account__c = ssipSchedule.Account__c, Country__c = ssipSchedule.Country__c, Payment_Term__c = rule.Payment_Term__c,
                                                             Shipping_Address__c = rule.Shipping_Address__c, Shipping_Method__c = rule.Shipping_Method__c, 
                                                             SSIP_Rule__c = ssipSchedule.SSIP_Rule__c, Status__c = 'Open', Fund__c = ssipSchedule.Fund__c, Schedule_Date__c = scheduleDate));
                }
            }
        }
        if(lstSSIPSchedule.size()>0){
            insert lstSSIPSchedule; 
        }
        if(lstCASSIPScheduleFilter.size()>0){
            scheduleCanadaRules(lstCASSIPScheduleFilter);
        }
        
    }
    
    public void scheduleCanadaRules(List<SSIP_Schedule__c> lstCASSIPScheduleFilter){
        System.debug('scheduleCanadaRules--');
        List<SSIP_Schedule__c> lstSSIPSchedule = new List<SSIP_Schedule__c>();
        Set<Id> setSSIPRuleIds = new Set<Id>();
        for(SSIP_Schedule__c ssipRule : lstCASSIPScheduleFilter) setSSIPRuleIds.add(ssipRule.SSIP_Rule__c);
        mapRule = new Map<Id, SSIP_Rule__c>([SELECT Id, Rule_End_Date__c, Frequency_In_Days__c, Payment_Term__c, Shipping_Address__c, Shipping_Method__c, (SELECT Id, Schedule_Date__c FROM SSIP_Schedule__r ORDER BY Schedule_Date__c DESC LIMIT 1) FROM SSIP_Rule__c WHERE Id IN: setSSIPRuleIds]);
        for(SSIP_Schedule__c ssipSchedule : lstCASSIPScheduleFilter){
            if(mapRule.containsKey(ssipSchedule.SSIP_Rule__c)){
                
                SSIP_Rule__c rule = mapRule.get(ssipSchedule.SSIP_Rule__c);
                Date scheduleDate = rule.SSIP_Schedule__r.size() > 0 ? rule.SSIP_Schedule__r[0].Schedule_Date__c.addMonths(1) : Date.today().addMonths(1);
                Integer dayofMonth = scheduleDate.day();
                System.debug('rule.Rule_End_Date__c--'+rule.Rule_End_Date__c);
                System.debug('scheduleDate--'+scheduleDate);
                if(rule.Rule_End_Date__c == null || scheduleDate <= rule.Rule_End_Date__c){
                    if(dayofMonth <= 28){
                        lstSSIPSchedule.add(new SSIP_Schedule__c(Account__c = ssipSchedule.Account__c, Country__c = ssipSchedule.Country__c, Payment_Term__c = rule.Payment_Term__c,
                                                                 Shipping_Address__c = rule.Shipping_Address__c, Shipping_Method__c = rule.Shipping_Method__c, 
                                                                 SSIP_Rule__c = ssipSchedule.SSIP_Rule__c, Status__c = 'Open', Fund__c = ssipSchedule.Fund__c, Schedule_Date__c = scheduleDate));
                        
                    }else if(dayofMonth > 28){
                        date myDate = scheduleDate;
                        date newDate = myDate.addMonths(1);
                        date expectedDate = newDate.toStartOfMonth();
                        lstSSIPSchedule.add(new SSIP_Schedule__c(Account__c = ssipSchedule.Account__c, Country__c = ssipSchedule.Country__c, Payment_Term__c = rule.Payment_Term__c,
                                                                 Shipping_Address__c = rule.Shipping_Address__c, Shipping_Method__c = rule.Shipping_Method__c, 
                                                                 SSIP_Rule__c = ssipSchedule.SSIP_Rule__c, Status__c = 'Open', Fund__c = ssipSchedule.Fund__c,
                                                                 Schedule_Date__c = expectedDate));
                        
                    }
                }
            }
        }
        if(lstSSIPSchedule.size()>0){
            insert lstSSIPSchedule; 
        }
        
    }
}