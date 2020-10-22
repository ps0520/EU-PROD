public class ClsFundTriggerHandler {
    public void onBeforeInsert(List<Fund__c> lstFund){
        //Set the Currency Code on the Fund upon insert
        Set<Id> setAccountId = new Set<Id>();
        for(Fund__c fund : lstFund) setAccountId.add(fund.Payor__c);
        Map<Id, Account> mapAccount = new Map<Id, Account>([SELECT Id, RecordType.DeveloperName FROM Account WHERE Id IN: setAccountId]);
        for(Fund__c fund : lstFund){
            String recordTypeDName = mapAccount.get(fund.Payor__c).RecordType.DeveloperName;
            String currencyCode = recordTypeDName.startsWithIgnoreCase('CA_') ? 'CAD' : recordTypeDName.startsWithIgnoreCase('CH_') ? 'CHF' : 
                                  recordTypeDName.startsWithIgnoreCase('GB_') ? 'GBP' : recordTypeDName.startsWithIgnoreCase('IE_') ? 'EUR' : 
                                  recordTypeDName.startsWithIgnoreCase('INTL_') ? 'USD' : 'EUR';
            if(String.isNotBlank(currencyCode) && String.isNotEmpty(currencyCode)) fund.CurrencyIsoCode = currencyCode;
        }
    }
    
    public void onAfterUpdate(List<Fund__C> newList,Map<id,Fund__C> oldMap){
        Id recordTypeId = Schema.SObjectType.Fund__c.getRecordTypeInfosByDeveloperName().get('Purchase_Order').getRecordTypeId();
        Map<Id,Id> mapOfFundToSuccFund=new Map<Id,Id>();
        //Prepare a map between the Fund and Succeeding fund to be passed on to the Batch class
        for(Fund__C fund:newList){
             system.debug('fund.Succeeding_Fund__c'+fund.Succeeding_Fund__c+'>>'+fund.recordtypeid+'<>'+recordTypeId);
             if(fund.Succeeding_Fund__c !=null && fund.recordtypeid==recordTypeId && fund.Succeeding_Fund__c != oldMap.get(fund.id).Succeeding_Fund__c){
                mapOfFundToSuccFund.put(fund.id,fund.Succeeding_Fund__c);
             }
        }
        if(!mapOfFundToSuccFund.isEmpty())
            database.executeBatch(new BclsHandleAccountFundBatch(mapOfFundToSuccFund),10);
    }
}