@isTest
public class ClsTestApexUtil {

    @isTest
    private static void testOrgWideEmailAddressTest() {
        system.debug('Germany Org Wide Admin Id: ' + ClsApexUtil.GetOrgWideEmailAddrId('de.info@dexcom.com'));
        system.debug('Germany Country Admin: ' + ClsApexUtil.GetCountryAdmin('DE'));
    }
}