public class ClsCustomerFeedbackCon {

	@AuraEnabled    
    public Static Account getAccountDetails(String accRecId){
        System.debug('accRecId--'+accRecId);
    	Account accObj = new Account();
        if(accRecId !=null){
            accObj = [Select Id,Name From account where Id=:accRecId Limit 1];
        }
        return accObj;
    } 
    
    @AuraEnabled    
    public Static Map<String,String> getCFTypePicklist(){
        Map<String,String> options = new Map<String,String>();
        Schema.DescribeFieldResult fieldResult = Customer_Feedback__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            options.put(p.getValue(),p.getLabel());
        }
        return options;
    }
    
     @AuraEnabled    
    public Static void saveCustfeedbackDetails(Customer_Feedback__c recCF){
        try{
            insert recCF;
            System.debug('Insertion Successful--'+recCF.Id);
        }catch(Exception ex){
           System.debug('Insert Error at Line -'+ ex.getLineNumber()); 
        }
    }
    
    @AuraEnabled    
    public Static void updateCustfeedbackDetails(Customer_Feedback__c recCF,String custFeedbackId){
        try{
           recCF.Id=  Id.valueOf( custFeedbackId);
            update recCF;
            System.debug('Update Succesful--'+recCF.Id);
        }catch(Exception ex){
           System.debug('Update Error at Line -'+ ex.getLineNumber());
        }
    }
    
     @AuraEnabled    
    public Static List<Customer_Feedback__c> getCustomerFeedbackDetails(String accRecordId){
        List<Customer_Feedback__c> lstCustFeedback=  new List<Customer_Feedback__c>();
        if(accRecordId != null){
            lstCustFeedback = [SELECT Id, Name, Type__c, High_Level_Feedback_Box__c, Note_Box__c, 
                               Resolution_Box__c, Account__c 
                               FROM Customer_Feedback__c
                               where Account__c=:accRecordId
                              ];
        }
        return lstCustFeedback;
    }
}