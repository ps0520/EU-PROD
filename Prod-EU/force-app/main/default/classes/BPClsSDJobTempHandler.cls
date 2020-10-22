public class BPClsSDJobTempHandler {
    public void onAfterUpdate(List<SDJob_Temp__c> lstSDJobTemp, Map<Id, SDJob_Temp__c> mapSDJobTempOld){
        List<String> lstSDJobsId = new List<String>();
        List<SDOC__SDJob__c> lstSDJobs = new List<SDOC__SDJob__c>();
        List<Order> lstOrder = new List<Order>();
        for(SDJob_Temp__c objSchedule : lstSDJobTemp){
            if(!objSchedule.Create_SDJob__c || mapSDJobTempOld.get(objSchedule.Id).Create_SDJob__c == objSchedule.Create_SDJob__c) continue;
            lstSDJobsId.add(objSchedule.Id);
            lstSDJobs.add(new SDOC__SDJob__c(SDOC__Doclist__c = objSchedule.Doclist__c, SDOC__ObjApiName__c = objSchedule.Sobject_Name__c, SDOC__Oid__c = objSchedule.Sobject_Id__c, SDOC__SendEmail__c = '1', SDOC__Start__c = true));
            lstOrder.add(new Order(Id = objSchedule.Sobject_Id__c, Web_Order_Confirmation_Status__c = 'Sent'));
        }
        insert lstSDJobs;
        update lstOrder;
        deleteSDJobsPostSDocCreation(lstSDJobsId);
    }
    
    @future private static void deleteSDJobsPostSDocCreation(List<String> lstSDJobsId){   
        delete [SELECT Id FROM SDJob_Temp__c WHERE Id IN: lstSDJobsId];
    }
}