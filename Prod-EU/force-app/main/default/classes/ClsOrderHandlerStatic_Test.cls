@isTest()
private class ClsOrderHandlerStatic_Test {
    @isTest private static void test(){
        ClsOrderHandlerStatic.runOrderTrigger();
        ClsOrderHandlerStatic.runOrderTrigger();
        ClsOrderHandlerStatic.runOrderEventTriggerv11();
        ClsOrderHandlerStatic.runOrderEventTriggerv11();
        ClsOrderHandlerStatic.runOrderEventTriggerv10();
        ClsOrderHandlerStatic.runOrderEventTriggerv10();
        ClsOrderHandlerStatic.runSubmitOrder();
        ClsOrderHandlerStatic.runSubmitOrder();
    }	
}