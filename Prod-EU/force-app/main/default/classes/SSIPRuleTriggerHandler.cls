/**********************************************************************
@Description    : Class will handle logic for SSIPRule object
***********************************************************************/
public class SSIPRuleTriggerHandler {
    
    
    public void onBeforeInsert(List<SSIP_Rule__c> lstSSIPRuleNew){
        //Collection variables
        Set<Id> productIds = new Set<Id>();
        Set<Id> PBIds = new set<Id>();
        Map<Id, String> productNameMap = new Map<Id, String>();
        List<PricebookEntry> PBEItemList = new List<PricebookEntry>();
        //Prepares the product map for the rules that need to be updated with Product Name
        for(SSIP_Rule__c objSSIPRule : lstSSIPRuleNew){
            if(objSSIPRule.Product__c != null && objSSIPRule.Product_Name__c == null) productIds.add(objSSIPRule.Product__c);
            
            PBIds.add(objSSIPRule.Price_Book__c); 
        }
        if(!productIds.isEmpty()){
            for(Product2 prod : [SELECT Id, Name FROM Product2 WHERE Id IN : productIds])
                productNameMap.put(prod.Id, prod.Name);
        }
        for(PricebookEntry pbe : [select id, Name, UnitPrice, Pricebook2Id, Product2Id from PricebookEntry where Pricebook2Id IN :PBIds] )   PBEItemList.add(pbe); 
        
        system.debug('PBEItemList'+PBEItemList);
        //For every rule update the 18 digit account id and Product name based on the chosen product
        for(SSIP_Rule__c objSSIPRule : lstSSIPRuleNew)
        {
            objSSIPRule.Account_18_Digit_Id__c = objSSIPRule.Account__c;
            Boolean Prodfound = false;
            for(PricebookEntry PBE :PBEItemList){  
                if(PBE.Pricebook2Id == objSSIPRule.Price_Book__c && PBE.Product2Id == objSSIPRule.Product__c){                    
                    Prodfound = True ;
                    objSSIPRule.Unit_Price__c = PBE.UnitPrice;
                    
                }
            }
            if(!Prodfound){
                objSSIPRule.addError('Wrong combination of Product and Pricbook.');
                return;
            }  
            if(!productNameMap.isEmpty() && objSSIPRule.Product__c != null && objSSIPRule.Product_Name__c == null && productNameMap.containsKey(objSSIPRule.Product__c))
                objSSIPRule.Product_Name__c = productNameMap.get(objSSIPRule.Product__c);
        }
    }
    
    public void onAfterInsert(List<SSIP_Rule__c> lstSSIPRuleNew){
        createSSIPScheduleRecord(lstSSIPRuleNew, new Map<Id,SSIP_Rule__c>());
    }
    
    public void onAfterUpdate(List<SSIP_Rule__c> lstSSIPRuleNew, Map<Id, SSIP_Rule__c> mapSSIPRuleOld){
        //NS-1619 - CA- Subscription Renewal Journeys for Perficient - Part -I
        List<SSIP_Rule__c> ssipRenewed = new List<SSIP_Rule__c>();
        List<SSIP_Rule__c> lstSSIP = [Select id,Name,Rule_End_Date__c,Account__r.Id,Account__r.RecordType.DeveloperName,
                                      Account__r.RecordType.Name,Price_Book__r.Name,Product_Name__c
                                      from SSIP_Rule__c where id IN:lstSSIPRuleNew];
        for(SSIP_Rule__c ssipRl : lstSSIP){
            String accRecName =  ssipRl.Account__r.RecordType.Name;
            String PBName = ssipRl.Price_Book__r.Name;
            String PrdName = ssipRl.Product_Name__c; 
            if((ssipRl.Rule_End_Date__c != null && ssipRl.Rule_End_Date__c != mapSSIPRuleOld.get(ssipRl.Id).Rule_End_Date__c) && (accRecName.containsIgnoreCase('CA Consumer')) 
               && (PBName.containsIgnoreCase('CAN G6 SUBSCRIPTION 12MOS NO Renewal')) || (PBName.containsIgnoreCase('CAN G6 SUBSCRIPTION 12MOS Auto Renewal')) 
               && (PrdName.containsIgnoreCase('MTRNTCAGS-12MOS'))){
                   ssipRenewed.add(ssipRl);
               }    
        }       
        
        createSSIPScheduleRecord(lstSSIPRuleNew, mapSSIPRuleOld); 
        ClsSSIPRuleRenewal.handleSSIPRuleRenwal(lstSSIPRuleNew, mapSSIPRuleOld); 
        if(ssipRenewed.size()>0){
            onUpdatecreateMIRecords(ssipRenewed);
        }
    }
    
    
    private void createSSIPScheduleRecord(List<SSIP_Rule__c> lstSSIPRuleNew, Map<Id, SSIP_Rule__c> mapSSIPRuleOld){
        Map<Id, SSIP_Rule__c> mapSSIPRuleNew = new Map<Id, SSIP_Rule__c>(lstSSIPRuleNew);
        Map<Id, Id> ruleToFundMap = new Map<Id, Id>();      
        Map<Id, List<SSIP_Schedule__c>> mapSSIPIdTolstSSIPSchedule = new Map<Id, List<SSIP_Schedule__c>>();
        List<SSIP_Schedule__c> lstSSIPSchedule = new List<SSIP_Schedule__c>();
        Set<SSIP_Schedule__c>  lstSSIPSet  = new Set<SSIP_Schedule__c>();        
        List<SSIP_Schedule__c> lstSSIPScheduleToDelete = new List<SSIP_Schedule__c>();
        Set<Id> setSSIPRuleId = new Set<Id>();
        
        
        //Find if the Rule has order association and prepare the map
        for(SSIP_Rule__c objSSIPRule : [SELECT Id, First_Order__r.Fund__c FROM SSIP_Rule__c WHERE First_Order__c != null AND Id IN: lstSSIPRuleNew]){
            if(objSSIPRule.First_Order__r.Fund__c != null)
                ruleToFundMap.put(objSSIPRule.Id, objSSIPRule.First_Order__r.Fund__c);
        }        
        
        //Process the SSIP Rule records to create Schedules
        for(SSIP_Rule__c objSSIPRule : lstSSIPRuleNew){
            System.debug('createSSIPScheduleRecord for loop');                
            
            Integer count = objSSIPRule.Schedule_Count__c != null ? Integer.valueOf(objSSIPRule.Schedule_Count__c) : 3;
            Integer firstRepeatOrderLeadDays = objSSIPRule.First_Repeat_Order_Lead_Days__c != null ? Integer.valueOf(objSSIPRule.First_Repeat_Order_Lead_Days__c) : 0;
            if((Trigger.isInsert && objSSIPRule.First_Shipment_Date__c != null) || (Trigger.isUpdate && mapSSIPRuleOld.get(objSSIPRule.Id).First_Shipment_Date__c == null && objSSIPRule.First_Shipment_Date__c != null) && objSSIPRule.Frequency_In_Days__c != null){
                // Code Added by Pravin  - NS-1357
                String Prdname = objSSIPRule.Product_Name__c;
                System.debug('**Country--'+objSSIPRule.Country__c);
                if(objSSIPRule.Country__c == 'Canada' && prdName.startsWith('MT')){
                    Integer dayofMonth = objSSIPRule.First_Shipment_Date__c.Day();
                    if(dayofMonth <= 28){
                        for(Integer i = 1; i <= count; i++){
                            lstSSIPSchedule.add(new SSIP_Schedule__c(Account__c = objSSIPRule.Account__c, Country__c = objSSIPRule.Country__c, Payment_Term__c = objSSIPRule.Payment_Term__c, Shipping_Address__c = objSSIPRule.Shipping_Address__c,
                                                                     Shipping_Method__c = objSSIPRule.Shipping_Method__c, SSIP_Rule__c = objSSIPRule.Id, Status__c = 'Open',
                                                                     Fund__c = !ruleToFundMap.isEmpty() ? ruleToFundMap.get(objSSIPRule.Id) : null,     
                                                                     Schedule_Date__c = objSSIPRule.First_Shipment_Date__c.addMonths(1 * i) - firstRepeatOrderLeadDays));
                        }
                    }else if(dayofMonth > 28){
                        date myDate = objSSIPRule.First_Shipment_Date__c; 
                        date newDate = myDate.addMonths(1);
                        date expectedDate = newDate.toStartOfMonth();
                        for(Integer i = 1; i <= count; i++){
                            lstSSIPSchedule.add(new SSIP_Schedule__c(Account__c = objSSIPRule.Account__c, Country__c = objSSIPRule.Country__c, Payment_Term__c = objSSIPRule.Payment_Term__c, Shipping_Address__c = objSSIPRule.Shipping_Address__c,
                                                                     Shipping_Method__c = objSSIPRule.Shipping_Method__c, SSIP_Rule__c = objSSIPRule.Id, Status__c = 'Open',
                                                                     Fund__c = !ruleToFundMap.isEmpty() ? ruleToFundMap.get(objSSIPRule.Id) : null,     
                                                                     Schedule_Date__c = expectedDate.addMonths(1 * i) - firstRepeatOrderLeadDays));
                        }
                    }
                }else{
                    
                    for(Integer i = 1; i <= count; i++){
                        lstSSIPSchedule.add(new SSIP_Schedule__c(Account__c = objSSIPRule.Account__c, Country__c = objSSIPRule.Country__c, Payment_Term__c = objSSIPRule.Payment_Term__c, Shipping_Address__c = objSSIPRule.Shipping_Address__c,
                                                                 Shipping_Method__c = objSSIPRule.Shipping_Method__c, SSIP_Rule__c = objSSIPRule.Id, Status__c = 'Open',
                                                                 Fund__c = !ruleToFundMap.isEmpty() ? ruleToFundMap.get(objSSIPRule.Id) : null,     
                                                                 Schedule_Date__c = objSSIPRule.First_Shipment_Date__c.addDays(Integer.valueOf(objSSIPRule.Frequency_In_Days__c) * i) - firstRepeatOrderLeadDays));
                    }
                }
                
                
            }                        
            if(Trigger.isUpdate && ((mapSSIPRuleOld.get(objSSIPRule.Id).First_Shipment_Date__c != null && objSSIPRule.Rule_End_Date__c != mapSSIPRuleOld.get(objSSIPRule.Id).Rule_End_Date__c) 
                                    || mapSSIPRuleOld.get(objSSIPRule.Id).Payment_Term__c != objSSIPRule.Payment_Term__c || mapSSIPRuleOld.get(objSSIPRule.Id).Shipping_Method__c != objSSIPRule.Shipping_Method__c
                                    /*|| (objSSIPRule.Rule_Re_schedule_Date__c != null && mapSSIPRuleOld.get(objSSIPRule.Id).Rule_Re_schedule_Date__c != objSSIPRule.Rule_Re_schedule_Date__c ) */)){
                                        
                                        system.debug('objSSIPRule.Id = '+ objSSIPRule.Id);
                                        setSSIPRuleId.add(objSSIPRule.Id);
                                    }
            if(Trigger.isUpdate && (objSSIPRule.Rule_Re_schedule_Date__c != null && mapSSIPRuleOld.get(objSSIPRule.Id).Rule_Re_schedule_Date__c != objSSIPRule.Rule_Re_schedule_Date__c ))
                handleScheduleChange(objSSIPRule);
        }
        //Set Payment Term, Shipping Method from the Rule to the schedule records. Also delete all schedules once the Rule End Date is set on the Rule
        for(SSIP_Schedule__c objSSIPSchedule : [SELECT Id, SSIP_Rule__c, SSIP_Rule__r.Rule_End_Date__c, Rescheduled_Shipment_Date__c, Schedule_Date__c FROM SSIP_Schedule__c WHERE SSIP_Rule__c IN: setSSIPRuleId AND Status__c = 'Open']){
            System.debug('createSSIPScheduleRecord for loop 2');                
            
            //Process deletion logic first and then go to update logic
            //If the Reschedued Shipment Date is populated on the SSIP Schedule that takes the precedence
            if(objSSIPSchedule.Rescheduled_Shipment_Date__c != null && (objSSIPSchedule.Rescheduled_Shipment_Date__c > objSSIPSchedule.SSIP_Rule__r.Rule_End_Date__c))
                lstSSIPScheduleToDelete.add(objSSIPSchedule);
            else
                if(objSSIPSchedule.Rescheduled_Shipment_Date__c == null && (objSSIPSchedule.Schedule_Date__c > objSSIPSchedule.SSIP_Rule__r.Rule_End_Date__c))
                lstSSIPScheduleToDelete.add(objSSIPSchedule);
            else{
                if(mapSSIPRuleNew.get(objSSIPSchedule.SSIP_Rule__c).Payment_Term__c != mapSSIPRuleOld.get(objSSIPSchedule.SSIP_Rule__c).Payment_Term__c){
                    objSSIPSchedule.Payment_Term__c = mapSSIPRuleNew.get(objSSIPSchedule.SSIP_Rule__c).Payment_Term__c;
                }
                if(mapSSIPRuleNew.get(objSSIPSchedule.SSIP_Rule__c).Shipping_Method__c != mapSSIPRuleOld.get(objSSIPSchedule.SSIP_Rule__c).Shipping_Method__c){
                    objSSIPSchedule.Shipping_Method__c = mapSSIPRuleNew.get(objSSIPSchedule.SSIP_Rule__c).Shipping_Method__c;
                }    
                
                lstSSIPSchedule.add(objSSIPSchedule);
            }
        }
        delete lstSSIPScheduleToDelete;
        upsert lstSSIPSchedule;
        
    }
    
    public Static void handleScheduleChange(SSIP_Rule__c objSSIPRule) {
        List<SSIP_Schedule__c> scheds = [Select Id, Schedule_Date__c from SSIP_Schedule__c where SSIP_Rule__c = :objSSIPRule.id and Status__c = 'OPEN'];
        Integer count = objSSIPRule.Schedule_Count__c != null ? Integer.valueOf(objSSIPRule.Schedule_Count__c) : 3;
        Integer firstRepeatOrderLeadDays = objSSIPRule.First_Repeat_Order_Lead_Days__c != null ? Integer.valueOf(objSSIPRule.First_Repeat_Order_Lead_Days__c) : 0;
        List<SSIP_Schedule__c> lstSSIPSchedule = new List<SSIP_Schedule__c>();
        integer schedCounter = 0;
        System.debug('**scheds--'+scheds.size());
        for(SSIP_Schedule__c sched : scheds) {
            if (schedCounter == 0 && (objSSIPRule.Rule_End_Date__c == null ||  objSSIPRule.Rule_Re_schedule_Date__c <= objSSIPRule.Rule_End_Date__c)){ 
                String prdNAme1 = objSSIPRule.Product_Name__c;
                if(objSSIPRule.Country__c =='Canada' && prdNAme1.StartsWith('MT')){
                    Integer dayofMonth = objSSIPRule.Rule_Re_schedule_Date__c.Day();
                    if(dayofMonth<=28){
                        lstSSIPSchedule.add(new SSIP_Schedule__c(id=sched.Id, Schedule_Date__c = objSSIPRule.Rule_Re_schedule_Date__c));
                    }else{
                        date myDate = objSSIPRule.Rule_Re_schedule_Date__c;
                        date newDate = myDate.addMonths(1);
                        date expectedDate = newDate.toStartOfMonth();
                        // lstSSIPSchedule.add(new SSIP_Schedule__c(id=sched.Id, Schedule_Date__c = expectedDate));
                        //  lstSSIPSchedule.add(new SSIP_Schedule__c(id=sched.Id, Schedule_Date__c = expectedDate.adddays((Integer) ((objSSIPRule.Frequency_In_Days__c * schedCounter) - firstRepeatOrderLeadDays))));
                        lstSSIPSchedule.add(new SSIP_Schedule__c(id=sched.Id, Schedule_Date__c = expectedDate.addMonths((Integer) ((1 * schedCounter) - firstRepeatOrderLeadDays))));
                        
                    }
                }else{
                    lstSSIPSchedule.add(new SSIP_Schedule__c(id=sched.Id, Schedule_Date__c = objSSIPRule.Rule_Re_schedule_Date__c));
                }
            }else if (objSSIPRule.Rule_End_Date__c == null  || objSSIPRule.Rule_Re_schedule_Date__c.adddays((Integer) ((objSSIPRule.Frequency_In_Days__c * schedCounter) - firstRepeatOrderLeadDays)) <= objSSIPRule.Rule_End_Date__c) {
                
                String prdNAme2 = objSSIPRule.Product_Name__c;
                if(objSSIPRule.Country__c =='Canada' && prdNAme2.StartsWith('MT')){
                    Integer dayofMonth = objSSIPRule.Rule_Re_schedule_Date__c.Day();
                    if(dayofMonth<=28){
                        //lstSSIPSchedule.add(new SSIP_Schedule__c(id=sched.Id, Schedule_Date__c = objSSIPRule.Rule_Re_schedule_Date__c.adddays((Integer) ((objSSIPRule.Frequency_In_Days__c * schedCounter) - firstRepeatOrderLeadDays))));
                        lstSSIPSchedule.add(new SSIP_Schedule__c(id=sched.Id, Schedule_Date__c = objSSIPRule.Rule_Re_schedule_Date__c.addMonths((1 * schedCounter) - firstRepeatOrderLeadDays)));
                        
                    }else{
                        date myDate = objSSIPRule.Rule_Re_schedule_Date__c;
                        date newDate = myDate.addMonths(1);
                        date expectedDate = newDate.toStartOfMonth();
                        System.debug('***ElseIfexpectedDate---'+expectedDate);
                        lstSSIPSchedule.add(new SSIP_Schedule__c(id=sched.Id, Schedule_Date__c = expectedDate.addMonths((Integer) ((1 * schedCounter) - firstRepeatOrderLeadDays))));
                        //lstSSIPSchedule.add(new SSIP_Schedule__c(id=sched.Id, Schedule_Date__c = objSSIPRule.Rule_Re_schedule_Date__c.adddays((Integer) ((objSSIPRule.Frequency_In_Days__c * schedCounter) - firstRepeatOrderLeadDays))));
                        //System.debug('***After-Calculation-expectedDate---'+expectedDate.adddays((Integer) ((objSSIPRule.Frequency_In_Days__c * schedCounter) - firstRepeatOrderLeadDays)));
                    }
                }else{ 
                    lstSSIPSchedule.add(new SSIP_Schedule__c(id=sched.Id, Schedule_Date__c = objSSIPRule.Rule_Re_schedule_Date__c.adddays((Integer) ((objSSIPRule.Frequency_In_Days__c * schedCounter) - firstRepeatOrderLeadDays))));
                }
            }
            schedCounter++;
        }
        System.debug('**count--'+count);
        System.debug('**schedCounter--'+schedCounter);
        If (count > schedCounter) {
            for(Integer i = schedCounter; i < count; i++){
                if (objSSIPRule.Rule_End_Date__c == null  || objSSIPRule.Rule_Re_schedule_Date__c.adddays((Integer) ((objSSIPRule.Frequency_In_Days__c * i) - firstRepeatOrderLeadDays)) <= objSSIPRule.Rule_End_Date__c){
                    String prdNAme = objSSIPRule.Product_Name__c;
                    if(objSSIPRule.Country__c =='Canada' && prdNAme.StartsWith('MT')){
                        Integer dayofMonth = objSSIPRule.Rule_Re_schedule_Date__c.Day();
                        if(dayofMonth<=28){
                            lstSSIPSchedule.add(new SSIP_Schedule__c(Account__c = objSSIPRule.Account__c, Country__c = objSSIPRule.Country__c, Payment_Term__c = objSSIPRule.Payment_Term__c, Shipping_Address__c = objSSIPRule.Shipping_Address__c,
                                                                     Shipping_Method__c = objSSIPRule.Shipping_Method__c, SSIP_Rule__c = objSSIPRule.Id, Status__c = 'Open',
                                                                     //Fund__c = !ruleToFundMap.isEmpty() ? ruleToFundMap.get(objSSIPRule.Id) : null,   
                                                                     //Schedule_Date__c = objSSIPRule.Rule_Re_schedule_Date__c.addDays(Integer.valueOf(objSSIPRule.Frequency_In_Days__c) * i) - firstRepeatOrderLeadDays));
                                                                     Schedule_Date__c = objSSIPRule.Rule_Re_schedule_Date__c.addMonths((1 * i) - firstRepeatOrderLeadDays)));
                        }else{
                            date myDate = objSSIPRule.Rule_Re_schedule_Date__c;
                            date newDate = myDate.addMonths(1);
                            date expectedDate = newDate.toStartOfMonth();
                            lstSSIPSchedule.add(new SSIP_Schedule__c(Account__c = objSSIPRule.Account__c, Country__c = objSSIPRule.Country__c, Payment_Term__c = objSSIPRule.Payment_Term__c, Shipping_Address__c = objSSIPRule.Shipping_Address__c,
                                                                     Shipping_Method__c = objSSIPRule.Shipping_Method__c, SSIP_Rule__c = objSSIPRule.Id, Status__c = 'Open',
                                                                     //Fund__c = !ruleToFundMap.isEmpty() ? ruleToFundMap.get(objSSIPRule.Id) : null,   
                                                                     Schedule_Date__c = expectedDate.addMonths((1 * i)  - firstRepeatOrderLeadDays)));
                            //Schedule_Date__c = expectedDate.addDays(Integer.valueOf(objSSIPRule.Frequency_In_Days__c) * i) - firstRepeatOrderLeadDays));
                        }
                    }else{
                        lstSSIPSchedule.add(new SSIP_Schedule__c(Account__c = objSSIPRule.Account__c, Country__c = objSSIPRule.Country__c, Payment_Term__c = objSSIPRule.Payment_Term__c, Shipping_Address__c = objSSIPRule.Shipping_Address__c,
                                                                 Shipping_Method__c = objSSIPRule.Shipping_Method__c, SSIP_Rule__c = objSSIPRule.Id, Status__c = 'Open',
                                                                 //Fund__c = !ruleToFundMap.isEmpty() ? ruleToFundMap.get(objSSIPRule.Id) : null,   
                                                                 Schedule_Date__c = objSSIPRule.Rule_Re_schedule_Date__c.addDays(Integer.valueOf(objSSIPRule.Frequency_In_Days__c) * i) - firstRepeatOrderLeadDays));
                    }
                }
            }
        }
        upsert lstSSIPSchedule;
        
    }
    //NS-1546 Check Same Price book configred for all SSIP rule under account 
    public static void pricebookCheck(List<SSIP_Rule__C> newList,Map<id,SSIP_Rule__C> oldMap){
        //Check if different pricebooks are there for same account in newList 
        Map<id,Set<Id>> actSSIPMap=new Map<id,Set<Id>>();
        for(SSIP_Rule__C ssip: newList){
            if(ssip.status__c=='Active'){
                if(!actSSIPMap.containsKey(ssip.account__C)){
                    actSSIPMap.put(ssip.account__C,new Set<id>{ssip.price_book__C});
                }else{
                    Set<id> priceIds=actSSIPMap.get(ssip.account__C);
                    priceIds.add(ssip.price_book__C);
                    actSSIPMap.put(ssip.account__C,priceIds);   
                }
            }
        }
        for(SSIP_Rule__C ssip: newList){
            if(actSSIPMap.containsKey(ssip.account__C) && ssip.status__C== 'Active' && actSSIPMap.get(ssip.account__C).size()>1){            
                ssip.addError('Different pricebooks cannot be used for single customer');
            }    
        }
        
        //Check if Pricebook is already configured in Active SSIP rule
        Map<id,Set<id>> mapActIdToPricebookId=new Map<id,Set<Id>>();
        if(actSSIPMap.keyset().size()>0){
            for(SSIP_Rule__C ssip : [select id,price_book__C,account__C from SSIP_Rule__C where status__C='Active' and account__C IN : actSSIPMap.keyset()]){                  
                if(!mapActIdToPricebookId.containsKey(ssip.account__C)){
                    mapActIdToPricebookId.put(ssip.account__C,new Set<id>{ssip.price_book__C});
                }else{
                    Set<id> priceIds=mapActIdToPricebookId.get(ssip.account__C);
                    priceIds.add(ssip.price_book__C);
                    mapActIdToPricebookId.put(ssip.account__C,priceIds);   
                } 
            }
            
            for(SSIP_Rule__C ssip: newList){
                if(ssip.status__c=='Active' && mapActIdToPricebookId.containsKey(ssip.account__C)){
                    if(mapActIdToPricebookId.get(ssip.account__C).size()>1 ){
                        ssip.addError('Active SSIP Rules cannot be created/updated with different pricebooks, please use same pricebook which is already configured in existing active SSIP Rule');
                    }else if(mapActIdToPricebookId.get(ssip.account__C).size()==1 && (new List<Id>( mapActIdToPricebookId.get(ssip.account__C ))[0]) != ssip.price_book__C){                    
                        ssip.addError('Active SSIP Rules cannot be created/updated with different pricebooks, please use same pricebook which is already configured in existing active SSIP Rule.');
                        
                    }
                }
            }   
            
        }  
        
    }
    
    //NS-1619 - CA- Subscription Renewal Journeys for Perficient
    public static void onUpdatecreateMIRecords(List<SSIP_Rule__c> lstRuleEndDateSSIP){
        List<marketing_interaction__c> newMI = new list<marketing_interaction__c>();
        for(SSIP_Rule__c ssRule :lstRuleEndDateSSIP){
            marketing_interaction__c mi = new marketing_interaction__c();
            mi.Account__c=ssRule.Account__r.Id;
            mi.Communication_Type__c='CA - Subscription Renewal - Updated';
            mi.Source_Record_Id__c=ssRule.id; 
            if(ssRule.Rule_End_Date__c != null){
                mi.Related_Information__c=ssRule.Rule_End_Date__c.format();
            }
            mi.Country__c='Canada';
            newMI.add(mi);
        }
        insert newMI;
        System.debug('--NS-1619--NewMI--'+newMI);
    }
}