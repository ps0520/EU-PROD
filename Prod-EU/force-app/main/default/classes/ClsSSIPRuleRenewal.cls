/************************************************************************
* Author - Pravin Jagadale.
* Description - Class will create the Open Schedule Based on Rule End Date Change * 
* NS-1482
* Date - 16/09/2020
***************************************************************************/

public class ClsSSIPRuleRenewal {
    
    public static void handleSSIPRuleRenwal(List<SSIP_Rule__c> lstSSIPRuleNew, Map<Id, SSIP_Rule__c> mapSSIPRuleOld){
        try{
            if( ClsCheckRecursive.runOnce()){  
                System.debug('**handleSSIPRuleRenwal--');
                List<SSIP_Rule__c> lstSSIPUpdate = new List<SSIP_Rule__c>();
                List<SSIP_Schedule__c> lstSSIPScheduleUpdate = new List<SSIP_Schedule__c>();
                List<SSIP_Schedule__c> lstSSIPScheduleUpdate2 = new List<SSIP_Schedule__c>();
                List<SSIP_Schedule__c> lstScheduleInsert = new List<SSIP_Schedule__c>();
                Map<Id, Id> ruleToFundMap = new Map<Id, Id>();
                Set<Id> setSSIPSchedule = new Set<Id>();
                map<Id,List<SSIP_Schedule__c>> mapSSIPSchedule = new Map<Id,List<SSIP_Schedule__c>>();
                List<SSIP_Rule__c> ssipruleLst = [Select id,Renewal_Date__c,Last_Renewed_Date__c,Country__c ,Frequency_In_Days__c,
                                                  Rule_End_Date__c,Rule_Re_schedule_Date__c,Account__c,Payment_Term__c,Shipping_Address__c,
                                                  Shipping_Method__c,Schedule_Count__c,First_Repeat_Order_Lead_Days__c
                                                  from SSIP_rule__c where Id IN:lstSSIPRuleNew];
                
                List<SSIP_Schedule__c> lstSSIPSchedule = [Select id,Schedule_Date__c,SSIP_Rule__c,SSIP_Rule__r.Id,status__c,Product_Name__c
                                                          from SSIP_Schedule__c 
                                                          where SSIP_Rule__c IN:ssipruleLst order by Schedule_Date__c desc ];
                
                for(SSIP_Schedule__c ssipSch: lstSSIPSchedule){
                    if(mapSSIPSchedule.containsKey(ssipSch.SSIP_Rule__c)){
                        List<SSIP_Schedule__c> lst = mapSSIPSchedule.get(ssipSch.SSIP_Rule__c);
                        lst.add(ssipSch);
                        mapSSIPSchedule.put(ssipSch.SSIP_Rule__c,lst);  
                    }else{
                        List<SSIP_Schedule__c> lstadd = new List<SSIP_Schedule__c>();
                        lstadd.add(ssipSch);
                        mapSSIPSchedule.put(ssipSch.SSIP_Rule__c,lstadd);
                    }               
                }
                
                for(SSIP_Rule__c objSSIPRule : [SELECT Id, First_Order__r.Fund__c FROM SSIP_Rule__c WHERE First_Order__c != null AND Id IN: ssipruleLst]){
                    if(objSSIPRule.First_Order__r.Fund__c != null)
                        ruleToFundMap.put(objSSIPRule.Id, objSSIPRule.First_Order__r.Fund__c);
                } 
                for(SSIP_Rule__c ssipIt: ssipruleLst){
                    System.debug('---Processed-ssipIt--'+ssipIt);
                    if (ssipIt.Rule_End_Date__c <= mapSSIPRuleOld.get(ssipIt.Id).Rule_End_Date__c) continue;
                    if(Trigger.isUpdate && ssipIt.Rule_End_Date__c != null && ssipIt.Rule_End_Date__c != mapSSIPRuleOld.get(ssipIt.Id).Rule_End_Date__c){
                        //List<SSIP_Schedule__c> lstRuleScheules = mapSSIPSchedule.get(ssipIt.Id);
                        System.debug('--schedule--'+ssipIt.Schedule_Count__c);
                        Integer scheduleCount = ssipIt.Schedule_Count__c == null ? 3 : Integer.valueOf(ssipIt.Schedule_Count__c);
                        // ssipIt.Schedule_Count__c != 0 || ssipIt.Schedule_Count__c != null ? Integer.valueOf(ssipIt.Schedule_Count__c) : 3;
                        System.debug('--scheduleCount--'+scheduleCount);
                        Integer firstRepeatOrderLeadDays = ssipIt.First_Repeat_Order_Lead_Days__c != null ? Integer.valueOf(ssipIt.First_Repeat_Order_Lead_Days__c) : 0;
                        List<SSIP_Schedule__c> lstSchedules = new List<SSIP_Schedule__c>(); 
                        List<SSIP_Schedule__c> lstopenSchedules = new List<SSIP_Schedule__c>();
                        lstSchedules =  mapSSIPSchedule.get(ssipIt.Id);
                        System.debug('lstScheules--'+lstSchedules);
                        if(lstSchedules != null){
                            lstopenSchedules = checkOpenScheule(lstSchedules);
                        }
                        //List<SSIP_Schedule__c> lstopenScheules = lstScheules.size()>0 ? checkOpenScheule(lstScheules) : new List<SSIP_Schedule__c>();
                        Integer presentOpenSchCount = lstopenSchedules!= null ? lstopenSchedules.size() : 0;
                        System.debug('**presentOpenSchCount--'+presentOpenSchCount);
                        if(presentOpenSchCount > 0 && presentOpenSchCount < scheduleCount){
                            
                            //Find Last Scheudle Date
                            SSIP_Schedule__c scheduleObj = 	findLastShippedDate(lstopenSchedules);
                            Date nexScheduleDate = System.today();
                            System.debug('***scheduleObj.Schedule_Date__c--'+scheduleObj.Schedule_Date__c);
                            Integer daystoAdd = Integer.valueOf(ssipIt.Frequency_In_Days__c);
                            nexScheduleDate = scheduleObj.Schedule_Date__c;//.addDays(daystoAdd);                            
                            Integer dayofMonth = scheduleObj.Schedule_Date__c.Day();
                            String Prdname = scheduleObj.Product_Name__c; 
                            if(ssipIt.Rule_End_Date__c == null || scheduleObj.Schedule_Date__c <= ssipIt.Rule_End_Date__c){
                                if(ssipIt.Country__c == 'Canada' && prdName.startsWith('MT')){
                                    
                                    System.debug('**Canada--');
                                    if(dayofMonth <= 28){
                                        for(Integer i = presentOpenSchCount; i < scheduleCount; i++){ 
                                            lstScheduleInsert.add(new SSIP_Schedule__c(Account__c = ssipIt.Account__c, Country__c = ssipIt.Country__c, Payment_Term__c = ssipIt.Payment_Term__c, Shipping_Address__c = ssipIt.Shipping_Address__c,
                                                                                       Shipping_Method__c = ssipIt.Shipping_Method__c, SSIP_Rule__c = ssipIt.Id, Status__c = 'Open',
                                                                                       Fund__c = !ruleToFundMap.isEmpty() ? ruleToFundMap.get(ssipIt.Id) : null,     
                                                                                       Schedule_Date__c = nexScheduleDate.addMonths(1 * i)));
                                        }
                                    }else if(dayofMonth > 28){
                                        //date myDate = ssipIt.First_Shipment_Date__c; 
                                        date newDate = nexScheduleDate.addMonths(1);
                                        date expectedDate = newDate.toStartOfMonth();
                                        for(Integer i = presentOpenSchCount; i < scheduleCount; i++){
                                            lstScheduleInsert.add(new SSIP_Schedule__c(Account__c = ssipIt.Account__c, Country__c = ssipIt.Country__c, Payment_Term__c = ssipIt.Payment_Term__c, Shipping_Address__c = ssipIt.Shipping_Address__c,
                                                                                       Shipping_Method__c = ssipIt.Shipping_Method__c, SSIP_Rule__c = ssipIt.Id, Status__c = 'Open',
                                                                                       Fund__c = !ruleToFundMap.isEmpty() ? ruleToFundMap.get(ssipIt.Id) : null,     
                                                                                       Schedule_Date__c = expectedDate.addMonths(1 * i)));
                                        }
                                    } 
                                    
                                }else{
                                    System.debug('**Non-Canada--');
                                    for(Integer i = presentOpenSchCount; i < scheduleCount; i++){
                                        lstScheduleInsert.add(new SSIP_Schedule__c(Account__c = ssipIt.Account__c, Country__c = ssipIt.Country__c, Payment_Term__c = ssipIt.Payment_Term__c, Shipping_Address__c = ssipIt.Shipping_Address__c,
                                                                                   Shipping_Method__c = ssipIt.Shipping_Method__c, SSIP_Rule__c = ssipIt.Id, Status__c = 'Open',
                                                                                   Fund__c = !ruleToFundMap.isEmpty() ? ruleToFundMap.get(ssipIt.Id) : null,     
                                                                                   Schedule_Date__c = nexScheduleDate.addDays(Integer.valueOf(ssipIt.Frequency_In_Days__c) * i)));
                                    }
                                }
                            }
                            
                        }
                        if(presentOpenSchCount == 0 ){
                            System.debug('**presentOpenSchCount---'+0);
                            
                            SSIP_Schedule__c scheduleObj = 	findNonOpenLastShippedDate(ssipIt);
                            Date latestScheduled = System.today();
                            Date todaysDate = System.today();
                            if(scheduleObj != null){                                
                                Integer daystoAdd = Integer.valueOf(ssipIt.Frequency_In_Days__c);                            
                                latestScheduled = scheduleObj.Schedule_Date__c;                                
                                //latestScheduled = latestScheduled.addDays(daystoAdd);
                            }else{
                                SSIP_Rule__c rule = (SSIP_Rule__c)trigger.newMap.get(ssipIt.id);
                                rule.addError('Can not add the new schedules as no valid previous schedules found, please create new Subscription'); return;
                                // latestScheduled = System.today().addDays(1);
                            }
                            /*
if(latestScheduled.format() == todaysDate.format()){
latestScheduled = latestScheduled.addDays(1);
}
*/
                            if(scheduleObj.Schedule_Date__c.addDays(Integer.valueOf(ssipIt.Frequency_In_Days__c)) < todaysDate.addDays(1)){
                                SSIP_Rule__c rule = (SSIP_Rule__c)trigger.newMap.get(ssipIt.id);
                                rule.addError('Can not add the new schedules, please create new Subscription'); return;
                            }else{
                                System.debug('**Else Part to inset 3 Open Schedules');
                                Integer dayofMonth = scheduleObj.Schedule_Date__c.Day();
                                System.debug('**dayofMonth--'+dayofMonth);
                                String Prdname = scheduleObj.Product_Name__c;
                                
                                if(ssipIt.Rule_End_Date__c == null || scheduleObj.Schedule_Date__c <= ssipIt.Rule_End_Date__c){
                                    if(ssipIt.Country__c == 'Canada' && prdName.startsWith('MT')){
                                        System.debug('**Canada--');
                                        if(dayofMonth <= 28){
                                            for(Integer i = 0;i<scheduleCount;i++){
                                                lstScheduleInsert.add(new SSIP_Schedule__c(Account__c = ssipIt.Account__c, Country__c = ssipIt.Country__c, Payment_Term__c = ssipIt.Payment_Term__c, Shipping_Address__c = ssipIt.Shipping_Address__c,
                                                                                           Shipping_Method__c = ssipIt.Shipping_Method__c, SSIP_Rule__c = ssipIt.Id, Status__c = 'Open',
                                                                                           Fund__c = !ruleToFundMap.isEmpty() ? ruleToFundMap.get(ssipIt.Id) : null,     
                                                                                           Schedule_Date__c = latestScheduled.addDays(Integer.valueOf(ssipIt.Frequency_In_Days__c) * (i+1) )));
                                            }
                                        } else if(dayofMonth > 28){
                                            //date myDate = ssipIt.First_Shipment_Date__c; 
                                            date newDate = latestScheduled.addMonths(1);
                                            date expectedDate = newDate.toStartOfMonth();
                                            for(Integer i = 0;i<scheduleCount;i++){
                                                lstScheduleInsert.add(new SSIP_Schedule__c(Account__c = ssipIt.Account__c, Country__c = ssipIt.Country__c, Payment_Term__c = ssipIt.Payment_Term__c, Shipping_Address__c = ssipIt.Shipping_Address__c,
                                                                                           Shipping_Method__c = ssipIt.Shipping_Method__c, SSIP_Rule__c = ssipIt.Id, Status__c = 'Open',
                                                                                           Fund__c = !ruleToFundMap.isEmpty() ? ruleToFundMap.get(ssipIt.Id) : null,     
                                                                                           Schedule_Date__c = expectedDate.addDays(Integer.valueOf(ssipIt.Frequency_In_Days__c) * (i+1) )));
                                            }
                                        }
                                    }else{
                                        System.debug('**Non-Canada--');
                                        for(Integer i = 0; i < scheduleCount; i++){
                                            lstScheduleInsert.add(new SSIP_Schedule__c(Account__c = ssipIt.Account__c, Country__c = ssipIt.Country__c, Payment_Term__c = ssipIt.Payment_Term__c, Shipping_Address__c = ssipIt.Shipping_Address__c,
                                                                                       Shipping_Method__c = ssipIt.Shipping_Method__c, SSIP_Rule__c = ssipIt.Id, Status__c = 'Open',
                                                                                       Fund__c = !ruleToFundMap.isEmpty() ? ruleToFundMap.get(ssipIt.Id) : null,     
                                                                                       Schedule_Date__c = latestScheduled.addDays(Integer.valueOf(ssipIt.Frequency_In_Days__c) * (i+1))));
                                        }
                                    }
                                }
                                
                                
                                
                            }
                        }// Main If Ends
                    }
                }// For Loop Ends
                
                if(lstScheduleInsert.size()>0){
                    System.debug('**--Size--'+lstScheduleInsert.size());
                    insert lstScheduleInsert;
                }
            }
        }catch(Exception ex){
            System.debug('ErrLine--'+ex.getLineNumber());
            System.debug('Err--'+ex);
        }        
    }
    
    public static SSIP_Schedule__c findLastShippedDate(List<SSIP_Schedule__c> lstScheIt){
        
        //List<Object> someList = new List<Object>{1,2,3,4,5};
        List<SSIP_Schedule__c> reversed = new List<SSIP_Schedule__c>();
        for(Integer i = lstScheIt.size() - 1; i >= 0; i--){
            reversed.add(lstScheIt[i]);
        }
        //System.debug('**Schedule--'+reversed[0]);
        return reversed[0];
    }
    
    public static SSIP_Schedule__c findNonOpenLastShippedDate(SSIP_Rule__c ssipRule){
        
        List<SSIP_Schedule__c> lstSSIPSchedule = [Select id,Schedule_Date__c,SSIP_Rule__c,SSIP_Rule__r.Id,status__c,Product_Name__c
                                                  from SSIP_Schedule__c 
                                                  where SSIP_Rule__c =:ssipRule.id order by Schedule_Date__c desc ];
        if(lstSSIPSchedule.size()>0){
            return lstSSIPSchedule[0];
        }
        return null;
    }
    
    public static List<SSIP_Schedule__c> checkOpenScheule(List<SSIP_Schedule__c> lstScheIt){
        List<SSIP_Schedule__c> lstOpenSchedule = new List<SSIP_Schedule__c>();
        if(lstScheIt.size()>0){           
            for(SSIP_Schedule__c sch : lstScheIt ){
                if(sch.Status__c == 'Open'){
                    lstOpenSchedule.add(sch);
                }	    
            }
        }
        return lstOpenSchedule;  
    }
    
    
}