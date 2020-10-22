public class ClsAccountFundTriggerHandler {
    public void onBeforeInsert(List<Account_Fund__c> lstAF){
        //Need to populate these text fields to be used in Duplicate rule
        for(Account_Fund__c sf:lstAF){
            //Need to populate these entries for duplicate rule check
            sf.Account_18_Digit_Id__c = sf.Account__c;
            sf.Fund_18_Digit_Id__c = sf.Fund__c;
        }
    }
    public void onAfterInsert(List<Account_Fund__c> lstAF){
        UpdateAccountFundInfo(lstAF, null);
    }
	public void onAfterUpdate(List<Account_Fund__c> lstAF, Map<Id, Account_Fund__c> mapOldAF){
        UpdateAccountFundInfo(lstAF, mapOldAF);    	               
    }
    
    //Gather the Fund Ids that are to be processed. If primary is updated or new primary relation is added then process.
    public void UpdateAccountFundInfo(List<Account_Fund__c> lstAF, Map<Id, Account_Fund__c> mapOldAF){
    	set<Id> setAFId= new set<Id>(); 
        for(Account_Fund__c sf:lstAF){
            if(mapOldAF!= null){
            	if(sf.Primary_Flag__c && sf.Primary_Flag__c != mapOldAF.get(sf.id).Primary_Flag__c){
            		setAFId.Add(sf.Id);    
            	}     
            }else {
            	if(sf.Primary_Flag__c) setAFId.Add(sf.Id);    
            }
        }
        UpdateAccWithFund(setAFId);
    }
    //Update the account with the Primary fund and its payor info
    public void UpdateAccWithFund(set<Id> setAFId){
    	Map<Id, Account_Fund__c> mapAF= new Map<Id, Account_Fund__c>([Select Id, Fund__c, Fund__r.Payor__c,Account__c, Account__r.Fund__c, 
                Account__r.Payor__c From Account_Fund__c Where ID IN :setAFId]);
        set<Id> setAccId=new set<Id>();
        List<Account> lstAccUpd= new List<Account>();
        for(Account_Fund__c af : mapAF.values()){
        	Account a = new Account(Id=af.Account__c, Fund__c=af.Fund__c, Payor__c=af.Fund__r.Payor__c);
            lstAccUpd.Add(a); setAccId.Add(af.Account__c);
        }            
        if(lstAccUpd.size()>0){
        	update lstAccUpd;    
        } 
        if(setAFId.size() > 0 && setAccId.size()>0){
        	UpdateAccFundAsNonPrimary(setAFId, setAccId)   ;
        }
    }
    
    //For the accounts processed in method UpdateAccWithFund remove the old primary, if there is one exist already
    public void UpdateAccFundAsNonPrimary(set<Id> setAFId, set<Id> setAccId){
        Map<Id, Account_Fund__c> mapAF= new Map<Id, Account_Fund__c>([Select Id, Fund__c,Account__c, Primary_Flag__c
        	From Account_Fund__c Where Primary_Flag__c=True AND Account__c IN :setAccId AND Id NOT IN:setAFId]);
       
        List<Account_Fund__c> lstAFUpd= new List<Account_Fund__c>();
        for(Account_Fund__c af : mapAF.values()){
            af.Primary_Flag__c=false;
            lstAFUpd.Add(af); 
        }            
        if(lstAFUpd.size()>0){
        	update lstAFUpd;    
        } 
    }
}