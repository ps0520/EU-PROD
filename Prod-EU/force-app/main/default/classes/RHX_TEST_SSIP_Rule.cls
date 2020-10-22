@isTest(SeeAllData=true)
public class RHX_TEST_SSIP_Rule {
 static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
                   FROM SSIP_Rule__c ORDER BY LastModifiedDate DESC LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new SSIP_Rule__c()
            );
        }
      rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}