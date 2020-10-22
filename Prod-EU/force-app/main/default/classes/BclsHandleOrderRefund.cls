global class BclsHandleOrderRefund implements Database.Batchable<sObject>,Database.stateful,Database.AllowsCallouts{
    
    public List<String> lstOrderIds ;
    public String OrderTypeVal ;
    
    global BclsHandleOrderRefund(){}
    global BclsHandleOrderRefund(List<String> lstRefundOrderIds,String orderType){
        this.lstOrderIds = lstRefundOrderIds;
        this.OrderTypeVal = orderType;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        String soqlQuery = 'Select id,OwnerId,Total_Gross_Price__c,CC_Auth_Amount__c,Settlement_Id__c,Parent_Order__c';
        soqlQuery +=  ' from Order where Id IN:lstOrderIds';
        System.debug('**soqlQuery'+soqlQuery);
        return Database.getQueryLocator(soqlQuery); 
    }
     
    global void execute(Database.BatchableContext bc, List<Order> scope){
        System.debug('**Batch Execution Starts'+scope.size());
        List<Task> lstRefunTask = new List<Task>();
        Map<Id, ClsCCAuthAndSettlementResponse> response = new Map<Id, ClsCCAuthAndSettlementResponse>();
        String OrderRecId = '';
        try{
        if(scope.size()>0){
            for(Order orderObj : scope){
                Id ordOwner = orderObj.OwnerId; 
                Double refundAmount = Double.valueOf(orderObj.CC_Auth_Amount__c);
                Double totAlGrossPrice = Double.valueOf(orderObj.Total_Gross_Price__c);
                String settlementId = String.valueOf(orderObj.Settlement_Id__c);
                System.debug('**refundAmount--'+refundAmount);
                System.debug('**totAlGrossPrice--'+totAlGrossPrice);
                System.debug('**OrderType--'+OrderTypeVal);
                
                    if(OrderTypeVal.containsIgnoreCase('RGA')){
                        totAlGrossPrice = (totAlGrossPrice * (-1)); 
                        System.debug('**RGAOrder---'+totAlGrossPrice);
                        if(totAlGrossPrice > 0){
                            response = ClsCCAuthAndSettlementService.RefundPayment(orderObj.Parent_Order__c, orderObj.Id, totAlGrossPrice);
                        }else{
                            System.debug('**Total Gross Price--'+totAlGrossPrice);  
                        }
                    }else{
                        if(refundAmount > 0){
                         response = ClsCCAuthAndSettlementService.RefundPayment(orderObj.Id, orderObj.Id, refundAmount);    
                        }else{
                            System.debug('**refundAmount'+refundAmount);
                        }
                    }
                    System.debug('**response--'+response); 
                    if(response!=null){
                        for(Id objId : response.keySet()){
                            OrderRecId = objId;
                            ClsCCAuthAndSettlementResponse.enumStatus statusRec = response.get(objId).status;
                            if(statusRec == ClsCCAuthAndSettlementResponse.enumStatus.ERROR){
                                Id recordTypeId =Schema.SObjectType.Task.getRecordTypeInfosByName().get('Refund Error').getRecordTypeId();
                                Task tsk = new Task();
                                tsk.RecordTypeId = recordTypeId;
                                tsk.Subject = 'Followup Required - Refund Failed';
                                tsk.WhatId = orderObj.Id;
                                tsk.ActivityDate = System.today();
                                tsk.Type = 'Other';
                                tsk.OwnerId = ordOwner;
                                System.debug('**ordOwner'+ordOwner+'**OrderId--'+orderObj.Id);
                                tsk.Description = response.get(objId).error;
                                lstRefunTask.add(tsk); 
                            }
                            /* applyRefund message does not need to be sent as Fusion does not require it any more. Vijay Adusumilli Aug 12 2020.
                            else{
                                if (OrderTypeVal.containsIgnoreCase('RGA')) {
                                    update new Order(id=orderObj.Id, OMS_Action__c = 'applyRefund');
                                    System.debug('**Order upadated--'+orderObj.Id);
                                    PEClsHandleOrderEvents_V11.publishOrderEvent(new Set<String>{orderObj.Id}, null, 'update');
                                }
                            }
                            */
                        }
                    }
            } 
            if(OrderRecId!= ''){
                Order orderObj = [Select id,OwnerId from Order where Id=:OrderRecId];
                for(Task tsk :lstRefunTask){
                    tsk.OwnerId = orderObj.OwnerId; 
                }  
            }else{
                System.debug('**Refund does not Processed');
            }
            
            insert lstRefunTask;
        }
    }Catch(Exception ex){
        System.debug('**ErrorLine--'+ex.getLineNumber());
        System.debug('**Errormessage--'+ex);
        
    }
    }
     
    global void finish(Database.BatchableContext bc){
        System.debug('**Batch Execution Finished--'); 
    }
}