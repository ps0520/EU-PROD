public class ClsOrderHandlerStatic {
    public static Boolean executeOrderTrigger = true;
    public static Boolean executeOrderEventTriggerv11 = true;
    public static Boolean executeOrderEventTriggerv10 = true;
    public static Boolean submitOrder = true;
    
    public static Boolean runOrderTrigger(){
        if(executeOrderTrigger){
            executeOrderTrigger = false;
            return true;
        }else{
            return executeOrderTrigger;
        }
    }
    
    public static Boolean runOrderEventTriggerv11(){
        if(executeOrderEventTriggerv11){
            executeOrderEventTriggerv11 = false;
            return true;
        }else{
            return executeOrderEventTriggerv11;
        }
    }
    
    public static Boolean runOrderEventTriggerv10(){
        if(executeOrderEventTriggerv10){
            executeOrderEventTriggerv10 = false;
            return true;
        }else{
            return executeOrderEventTriggerv10;
        }
    }

    public static Boolean runSubmitOrder(){
        if(submitOrder){
            submitOrder = false;
            return true;
        }else{
            return submitOrder;
        }
    }
    
}