trigger OrderTrigger on Order(before insert, before update, after insert, after update) {
    
    if(Trigger.isInsert){
        if(Trigger.isBefore) new BPClsOrderHandler().onBeforeInsert(Trigger.new);
        if(Trigger.isAfter) new BPClsOrderHandler().onAfterInsert(Trigger.new); 
    }
    
   
    if(Trigger.isUpdate){
        if(Trigger.isBefore) new BPClsOrderHandler().onBeforeUpdate(Trigger.new, Trigger.oldMap);  
        if(Trigger.isAfter){
            ClsOrderEntryHandler.calculateShippingCharge(trigger.newMap, trigger.oldMap);
            new BPClsOrderHandler().onAfterUpdate(Trigger.new, Trigger.oldMap); 
            //ClsOrderHandler.verifyAndPublishUpdates(Trigger.new, Trigger.oldMap);
        }  
    } 
    
}