@isTest
public class ClsPlatformErrorEventObjectTest {

    @isTest
    private static void PEErrorObjectTest() {
        Test.startTest();
        ErrorUtility.LogError('Consume', 'PEClsHandleOrderEvents.updateOrderOMS', 'PriceBook is not present in Salesforce with name ', 'order', 
                              '0343433', 'Incorrect pricebook.  Will not be processed.', '0343433', 'Informational');
        Test.stopTest();
    }
    @isTest
    private static void PEErrorObjectTestwithEvent() {
        Test.startTest();
        ErrorUtility.LogErrorWithEvent('Consume', 'PEClsHandleOrderEvents.updateOrderOMS', 'PriceBook is not present in Salesforce with name ', 'order', 
                              '0343433', 'Incorrect pricebook.  Will not be processed.', '0343433', 'Informational', 'An Event with Structure');
        Test.stopTest();
    }
	@isTest
    private static void PEErrorObjectTestwithEventFail() {
        Test.startTest();
        ErrorUtility.LogErrorWithEvent('gibberish', 'PEClsHandleOrderEvents.updateOrderOMS', 'PriceBook is not present in Salesforce with name ', 'order', 
                              '0343433', 'Incorrect pricebook.  Will not be processed.', '0343433', 'Informational','Random');
        Test.stopTest();
    }
    @isTest
    private static void PEErrorObjectTestFail() {
        Test.startTest();
        ErrorUtility.LogError('gibberish', 'PEClsHandleOrderEvents.updateOrderOMS', 'PriceBook is not present in Salesforce with name ', 'order', 
                              '0343433', 'Incorrect pricebook.  Will not be processed.', '0343433', 'Informational');
        Test.stopTest();
    }
}