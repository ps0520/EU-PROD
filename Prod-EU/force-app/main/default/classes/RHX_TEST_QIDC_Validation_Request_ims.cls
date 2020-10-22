@isTest(SeeAllData=true)
public class RHX_TEST_QIDC_Validation_Request_ims {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM QIDC__Validation_Request_ims__c ORDER BY LastModifiedDate DESC LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new QIDC__Validation_Request_ims__c()
            );
        }
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}