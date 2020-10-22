public class SSIPScheduleJobUtiltiy {
    
    public class CalculateTaxQueueable implements Queueable, Database.AllowsCallouts{
        public String orderId;
        public String paymentType;
        public String countryCode;
        public Integer Count_of_Order_Line_Items;
        public Integer Subscription_Pending_Payments;
        public id accountId;
        public Boolean paymentOnly;
        
        
        public CalculateTaxQueueable(String orderId, String paymentType, String countryCode, Integer Count_of_Order_Line_Items, Integer Subscription_Pending_Payments, Id accountId, Boolean paymentOnly){
            this.orderId = orderId;
            this.paymentType = paymentType;
            this.countryCode = countryCode;
            this.Count_of_Order_Line_Items = Count_of_Order_Line_Items;
            this.Subscription_Pending_Payments = Subscription_Pending_Payments;
            this.accountId = accountId;
            this.paymentOnly = paymentOnly;
        }
        public void execute(QueueableContext context) {
            List<SSIP_Schedule__c> lstSSIPSchdule = new List<SSIP_Schedule__c>();
            //SSIP_Schedule__c ssipSchedule = new SSIP_Schedule__c();
            lstSSIPSchdule = [Select id,Account__c,Order__c,Error_Message__c,Status__c 
                              from SSIP_Schedule__c 
                              where Account__c =:accountId 
                              AND Order__c =:orderId];
            try{
                String recordTypeName = countryCode + ' Sales Order Read Only';
                String result = ClsOUSTaxCalculator.calculateTax(orderId);
                System.debug('**result--'+result);
                System.debug('**paymentType--'+paymentType);
                
                if(!result.containsIgnoreCase('VAT/TAX Calculation Failed') && paymentType == 'net0' ){ // && !Test.isRunningTest()
                    
                    System.enqueueJob(new AuthorizeAndSettlePaymentQueueable(orderId, countryCode, Count_of_Order_Line_Items, Subscription_Pending_Payments, accountId, paymentOnly));
                   
                }else if(!result.containsIgnoreCase('VAT/TAX Calculation Failed')){
                    if(Schema.SObjectType.Order.getRecordTypeInfosByName().containsKey(recordTypeName)){
                        update new Order(Id = orderId, Status = 'Shipping Hold', recordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId());
					} 
                }else{
                    
                    System.debug('***Failure in Tax Calculation---');                    
                    for(SSIP_Schedule__c ssip : lstSSIPSchdule){                        
                        ssip.Error_Message__c = 'Failure in Tax Calculation.  Error: ' + result;
                        ssip.Status__c = 'In Error'; 
                    }
                    update lstSSIPSchdule;
                }
            }catch(Exception ex){
                System.debug('**Error at Line--'+ex.getLineNumber());
                System.debug('**Error Message--'+ex.getMessage());
                for(SSIP_Schedule__c ssip : lstSSIPSchdule){
                    ssip.Error_Message__c = ex.getMessage();
                    ssip.Status__c = 'In Error'; 
                }
                update lstSSIPSchdule;
                
                //ErrorUtility.LogError('Consume', 'SSIPScheduleJobUtiltiy', ex.getMessage(), 'SSIPScheduleJobUtiltiy', 'crm', '', orderId , 'Informational');
            }
        }
    }
    
    public class AuthorizeAndSettlePaymentQueueable implements Queueable, Database.AllowsCallouts{
        public String orderId;
        public String countryCode;
        public Integer Count_of_Order_Line_Items;
        public Integer Subscription_Pending_Payments;
        public id accountId;
        public Boolean paymentOnly;
        
        public AuthorizeAndSettlePaymentQueueable(String orderId, String countryCode, Integer Count_of_Order_Line_Items, Integer Subscription_Pending_Payments, Id accountId, Boolean paymentOnly){
            this.orderId = orderId;
            this.countryCode = countryCode;
            this.Count_of_Order_Line_Items = Count_of_Order_Line_Items;
            this.Subscription_Pending_Payments = Subscription_Pending_Payments;
            this.accountId = accountId;
            this.paymentOnly = paymentOnly;
        }
        public void execute(QueueableContext context) {
            String recordTypeName = countryCode + ' Sales Order Read Only';
            List<SSIP_Schedule__c> lstssipSchedule = new List<SSIP_Schedule__c>();
            //SSIP_Schedule__c ssipSchedule = new SSIP_Schedule__c();
            
            Map<Id, ClsCCAuthAndSettlementResponse> mapResponse = ClsCCAuthAndSettlementService.authorizeAndSettlePayment(orderId);
            System.debug('***Authorization Error***'+mapResponse);
            if(mapResponse.containsKey(orderId) && mapResponse.get(orderId).Status == ClsCCAuthAndSettlementResponse.enumStatus.SUCCESS){
                if(Schema.SObjectType.Order.getRecordTypeInfosByName().containsKey(recordTypeName)){
                    try{
                       
                        ClsOrderHandlerStatic.executeOrderEventTriggerv11 = true;
                        update new Order(Id = orderId, Status = 'Activated', recordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId());
                    	
                    
                    }catch(Exception ex){
                        System.debug('**Error Occured on Line--'+ex.getLineNumber()+'--With Account Id-->'+accountId+'--and OrderId-- '+orderId);
                         lstssipSchedule = [Select id,Account__c,Order__c,Error_Message__c,Status__c 
                                                         from SSIP_Schedule__c 
                                                         where Account__c =:accountId 
                                                         AND Order__c =:orderId];
                        for(SSIP_Schedule__c ssip : lstssipSchedule){
                            ssip.Error_Message__c = ex.getMessage();
                            ssip.Status__c = 'In Draft'; 
                        }
                        
                        update lstssipSchedule;
                        //ErrorUtility.LogError('Consume', 'SSIPScheduleJobUtiltiy', ex.getMessage(), 'SSIPScheduleJobUtiltiy', 'crm', '', orderId , 'Informational');
                    }
                }
            } else if(mapResponse.containsKey(orderId) && mapResponse.get(orderId).Status != ClsCCAuthAndSettlementResponse.enumStatus.SUCCESS && Count_of_Order_Line_Items == 1 && paymentOnly == true) {
                
                try{
                update new Account(id = accountId, Subscription_Pending_Payments__c = (Subscription_Pending_Payments == null ? 0 : Subscription_Pending_Payments )+ 1);
                System.debug('**Account update completed');
                }Catch(Exception ex){
                    ErrorUtility.LogError('Consume', 'SSIPScheduleJobUtiltiy', ex.getMessage(),
                                          'SSIPScheduleJobUtiltiy', 'crm', '', orderId , 'Informational');
                   System.debug('**Account update ErrorLine--'+ex.getLineNumber());
                }
                try{ 
                    System.debug('***Authorization Error---'+mapResponse.get(orderId).error);
                    String Error = mapResponse.get(orderId).error;
                    lstssipSchedule = [Select id,Account__c,Order__c,Error_Message__c,Status__c 
                                       from SSIP_Schedule__c 
                                       where Account__c =:accountId 
                                       AND Order__c =:orderId ];
                    for(SSIP_Schedule__c ssip : lstssipSchedule){    
                        ssip.Error_Message__c = Error;
                        ssip.Status__c = 'In Draft';
                    }
                    update lstssipSchedule;
                }catch(Exception ex){
                  
                        lstssipSchedule = [Select id,Account__c,Order__c,Error_Message__c,Status__c 
                                        from SSIP_Schedule__c 
                                        where Account__c =:accountId 
                                        AND Order__c =:orderId ];
                        
                        for(SSIP_Schedule__c ssip : lstssipSchedule){
                            ssip.Error_Message__c = 'There is an Error with Salesforce. Please Check Try to Create order to process again.' ;
                            ssip.Status__c = 'In Draft';
                        }
                        update lstssipSchedule;
                }
                    
            }else{
                try{
                 String Error = mapResponse.get(orderId).error;
                    lstssipSchedule = [Select id,Account__c,Order__c,Error_Message__c,Status__c 
                                       from SSIP_Schedule__c 
                                       where Account__c =:accountId 
                                       AND Order__c =:orderId ];
                    for(SSIP_Schedule__c ssip : lstssipSchedule){    
                        ssip.Error_Message__c = Error;
                        ssip.Status__c = 'In Draft';
                    }
                    update lstssipSchedule;
                }catch(Exception ex){
                    
                    System.debug('ErrorLine--'+ex.getLineNumber());
                    System.debug('Error--'+ex.getMessage());
                }
            }
        }
    }
}