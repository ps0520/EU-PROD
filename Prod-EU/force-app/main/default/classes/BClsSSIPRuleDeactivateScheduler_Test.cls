@isTest()
private class BClsSSIPRuleDeactivateScheduler_Test {
    @isTest private static void test(){
        test.startTest();
        system.schedule('Test', '0 0 23 * * ?', new BClsSSIPRuleDeactivateScheduler());
        test.stopTest();
    }
}