//Batch will run when succeeding fund added to any fund.
//This process will copy all customers who are associated to the old fund and copy to the succeeding fund 
global class BclsHandleAccountFundBatch implements Database.Batchable<sObject>{
   public Map<Id, Id> mapOfFundToSuccFund;
   //Constructor to get the map of the Fund to Succeeding Fund to process
    global BclsHandleAccountFundBatch(Map<Id, Id> mapOfFundToSuccFund){
       this.mapOfFundToSuccFund=mapOfFundToSuccFund;
   }
   
   global Database.QueryLocator start( Database.BatchableContext BC ) {
        System.debug('*******BclsHandleAccountFundBatch DEBUG - SOQL Execution starts');
        System.debug('*******BclsHandleAccountFundBatch DEBUG - Query the fund ' + mapOfFundToSuccFund.keyset());
        return DataBase.getQueryLocator([SELECT Id, Primary_Flag__c, Fund__c, Account__c FROM Account_Fund__c WHERE Primary_Flag__c = true AND Fund__c IN : mapOfFundToSuccFund.keyset()]);
   } 
    global void execute(Database.BatchableContext bc, List<Account_Fund__c> scope){
        System.debug('*******BclsHandleAccountFundBatch DEBUG - Entered Execute Method');
        Set<Id> accountIds = new Set<Id>();
        Map<String, Id> existingAccntFundRelToId = new Map<String, Id>();  
        Map<Id, Account_Fund__c> accountFundsToUpdate = new Map<Id, Account_Fund__c>();
        List<Account_Fund__c> accountFundsToInsert = new List<Account_Fund__c>();
        

        //Process the accounts that are to be associated to the new fund
        for(Account_Fund__c accntFund: scope)
            accountIds.add(accntFund.Account__c);

        //Prepare map of existing AccountFund relation to the Primary flag
        for(Account_Fund__c accntFund : [SELECT Id, Primary_Flag__c, Fund__c, Account__c FROM Account_Fund__c WHERE Account__c != null AND Fund__c != null AND Account__c IN :accountIds]){
            String relId = accntFund.Account__c + '-' + accntFund.Fund__c;
            existingAccntFundRelToId.put(relId, accntFund.Id);
        }
        //Process the account to reparent to associate to the succeeding fund 
        for(Account_Fund__c oldAccntFund : scope){
            System.debug('*******BclsHandleAccountFundBatch DEBUG - Processing starts');
            String succedingFund = mapOfFundToSuccFund.get(oldAccntFund.Fund__c);
            String newRel = oldAccntFund.Account__c + '-' + succedingFund;
            System.debug('*******BclsHandleAccountFundBatch DEBUG - succeedingFund ' + succedingFund);
            System.debug('*******BclsHandleAccountFundBatch DEBUG - newRelation ' + newRel);
            //Find if the account to succeeding fund relation already exist, if so, update the Primary 
            if(existingAccntFundRelToId.containskey(newRel)){
                Account_Fund__c existingFund = new Account_Fund__c(Id = existingAccntFundRelToId.get(newRel));
                existingFund.Primary_Flag__c = true;
                accountFundsToUpdate.put(existingAccntFundRelToId.get(newRel), existingFund);
                System.debug('*******BclsHandleAccountFundBatch DEBUG - Found existing relation already Account Fund Id is ' + oldAccntFund);
            }else{//else create a new relation and updated the primary on old relation if it is a primary
                Account_Fund__c newAccntFund = new Account_Fund__c();
                newAccntFund.Account__c = oldAccntFund.Account__c;
                newAccntFund.Fund__c = succedingFund;
                newAccntFund.Primary_Flag__c = true;
                accountFundsToInsert.add(newAccntFund);   
                System.debug('*******BclsHandleAccountFundBatch DEBUG - New Account Relation created ');
                if (oldAccntFund.Primary_Flag__c){
                    oldAccntFund.Primary_Flag__c = false;
                    accountFundsToUpdate.put(oldAccntFund.Id, oldAccntFund);
                    System.debug('*******BclsHandleAccountFundBatch DEBUG - Old Account Fund Primary is removed');
                }
            }
        }

        //Perform the DML Operations
        //Insert newly created Account Fund records  
        if(!accountFundsToInsert.isEmpty()){   
            Database.SaveResult[] srList = Database.Insert(accountFundsToInsert,false);
            for(Integer i = 0; i < srList.size(); i++){            
                if(srList[i].isSuccess()){
                    System.debug('*******BclsHandleAccountFundBatch DEBUG - Insert Succeedued properly');
                }
                else {
                    String error = '';
                    for(Database.Error err : srList[i].getErrors()) {
                        error += error == '' ? 'Fund ' + err.getMessage() : ', ' + err.getMessage();
                    }
                    ErrorUtility.LogError('Batch', 'BclsHandleAccountFundBatch', error, 'BclsHandleAccountFundBatch', 'crm', '', 'Account ID: ' + scope[i].Account__c+' Fund ID: ' + scope[i].Fund__C,'Fatal Error - Bailing out');
                }
            }
        }
        //Update newly created Account Fund records  
        if(!accountFundsToUpdate.isEmpty()){   
            Database.SaveResult[] srList = Database.Update(accountFundsToUpdate.values(),false);
            for(Integer i = 0; i < srList.size(); i++){            
                if(srList[i].isSuccess()){
                    System.debug('*******BclsHandleAccountFundBatch DEBUG - Update Succeedued properly');
                }
                else {
                    String error = '';
                    for(Database.Error err : srList[i].getErrors()) {
                        error += error == '' ? 'Fund ' + err.getMessage() : ', ' + err.getMessage();
                    }
                    ErrorUtility.LogError('Batch', 'BclsHandleAccountFundBatch', error, 'BclsHandleAccountFundBatch', 'crm', '', 'Account ID: ' + scope[i].Account__c+' Fund ID: ' + scope[i].Fund__C,'Fatal Error - Bailing out');
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc){
        system.debug('BclsHandleAccountFundBatch excecution ends ');       
    }
   
}