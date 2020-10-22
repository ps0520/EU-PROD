public class ClsFinanceDetailsCon {
	@AuraEnabled
    public static List<Finance_Detail__c> getCCData(string accId){
    	
        if(accId.startsWith('001')){
            System.Debug('**** Acc Id=' + accId);
        	return [Select Id, Token__c, Card_Type__c, Expiry_Date__c, Last_4_Digits__c, Primary__c, LastModifiedDate		
         		FROM Finance_Detail__c Where Account__c =:accId AND RecordType.DeveloperName='Credit_Card' And InActive__c=false Order By Primary__c desc, LastModifiedDate Desc LIMIT 200]; 	   
        } else{
        	Id aId=[Select AccountId from Order Where Id=:accId Limit 1][0].AccountId;
            if(aId!=null){
                System.Debug('**** Order Acc Id=' + aId);
            	return [Select Id, Token__c, Card_Type__c, Expiry_Date__c, Last_4_Digits__c, Primary__c, LastModifiedDate		
         		FROM Finance_Detail__c Where Account__c =:aId AND RecordType.DeveloperName='Credit_Card' And InActive__c=false Order By Primary__c desc, LastModifiedDate Desc LIMIT 200];    
            }
        }
        return null;
    }
    
    @AuraEnabled
    public static Account getAccName(string accId){
    	System.Debug('**** Acc Id=' + accId);
        if(!accId.startsWith('001')){
        	accId=[Select AccountId from Order Where Id=:accId Limit 1][0].AccountId;    
        }
        Account acc=[Select Id, Name, CurrencyISOCode from Account where ID=:accId Limit 1][0];
        return acc;
    }
    
    @AuraEnabled 
    public static Map<String, String> getAccBTAddr(Id accId){
        
        Map<String, String> mapAddrOptions = new Map<String, String>();
        if(!string.valueOf(accId).startsWith('001')){
        	accId=[Select AccountId from Order Where Id=:accId Limit 1][0].AccountId;    
        }
        for(Address__c addr : [Select Id, Account__r.Name, Address_Line_1__c, Address_Line_2__c, City__c, State__c, Postal_Code__c, Country__c,Type__c, Primary_Flag__c
                               from Address__c Where Account__c=:accId  AND Type__c='Bill To' AND Inactive__c=False ]){
    		string strAddr=(String.isBlank(addr.Address_Line_1__c)? '' : addr.Address_Line_1__c + ', ') + 
                (String.isBlank(addr.City__c)? '' : addr.City__c + ', ')  +
                (String.isBlank(addr.State__c)? '' : addr.State__c + ', ') + 
                (String.isBlank(addr.Postal_Code__c)? '' : addr.Postal_Code__c + ', ') + 
                (String.isBlank(addr.Country__c)? '' : addr.Country__c );
                
    		if(addr.Primary_Flag__c)
    			strAddr+= ' (Primary)';
            
            mapAddrOptions.put(addr.Id, strAddr);
        }
 		return mapAddrOptions;
    }
    
    @AuraEnabled 
    public static string getCCNumberToken(Finance_Detail__c recFD, string ccNum){
        if(recFD != null){
            boolean isPrimary=false;
        	clsCSAPIHelper cls= new clsCSAPIHelper();
            string currCode=(recFD.CC_CUR__c==null)? 'GBP' : recFD.CC_CUR__c; 
        	string ccToken=cls.getCCToken(ccNum, currCode);
			System.Debug('**** Token=' + ccToken);
            if(ccToken != null){
            	recFD.RecordTypeId= Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Credit_Card').getRecordTypeId();
            	recFD.Token__c=ccToken;                
                recFD.Last_4_Digits__c=ccToken.Right(4);
                isPrimary=recFD.Primary__c;
                string strIns= InsertFD(recFD);
                System.Debug('**** TPS:EH 2.1 ClsFinanceDetailsCon getCCNumberToken strIns=' + strIns);
                if(strIns!= null){
                	if(strIns.startsWith('ERROR:')){
                    	return strIns;
                	}    
                }
                
            }
            
            /* If a primary card is being saved then mark other cards for this account as non primary */
            if(recFD.Primary__c){
                clsJobMarkCardsNonPrimary jobUpdateCC = new clsJobMarkCardsNonPrimary(new List<Finance_Detail__c>{recFD});
				// Enqueue the job for later processing
				//ID jobID = System.enqueueJob(jobUpdateCC);	    
            }
        	return ccToken;    
        }
    	return null; 
    }
    
    static string InsertFD(Finance_Detail__c recFD){
    	Database.DMLOptions dml = new Database.DMLOptions();
        //dml.DuplicateRuleHeader.allowSave = false;
		//dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.SaveResult saveResult = Database.insert(recFD, false);
        System.Debug('**** TPS:EH 3.1 ClsFinanceDetailsCon InsertFD saveResult=' + saveResult);
        string errorReturn='ERROR: ';
        if(!saveResult.isSuccess()) {
        	for(Database.Error error : saveResult.getErrors()) {
            	System.Debug('**** TPS:EH 3.2 ClsFinanceDetailsCon InsertFD error=' + error);
                string errMsg=''; errMsg=error.getMessage();
                if(errMsg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION:')){
                    List<string> lstErrors=errMsg.split('FIELD_CUSTOM_VALIDATION_EXCEPTION:');
                    for(string e : errMsg.split('FIELD_CUSTOM_VALIDATION_EXCEPTION:')){
                        // Ignore errors related to error helper, is there are more than one custom validation errors.
                        if(!e.contains('Rollup Helper') && lstErrors.size()>1){
                        	errorReturn +=e;	    
                        }  
                    }
                    return errorReturn;
                }
                return 'ERROR: ' + error.getStatusCode() + ': ' + error.getMessage();
            }
        }
        return null;     
    }
   /* @AuraEnabled 
    public static Finance_Detail__c AddIbanNum(string ibanNum, string accId){
        map<string, string> mapReturn = new map<string, string>();
        System.Debug('**** TPS:EH 1.0 Starting AddIbanNum ibanNum=' + ibanNum + ' accId='+accId);
        if(ibanNum !=null && accId != null){
            System.Debug('**** TPS:EH 1.1 ibanNum=' + ibanNum + ' accId=' + accId);
        	Id recTypeId = Schema.SObjectType.Finance_Detail__c.getRecordTypeInfosByDeveloperName().get('Bank').getRecordTypeId();
            Finance_Detail__c fd=new Finance_Detail__c(Account__c=accId, IBan__c=ibanNum, Account_Num__c='Acc-'+ibanNum, BIC__c='BIC-' + ibanNum, Bank_Name__c='Bank-' + ibanNum);
            fd.RecordTypeId=recTypeId;
            System.Debug('**** TPS:EH 1.2 fd=' + fd);
            insert fd;
        }
        return null;
    } */
    
    /* @AuraEnabled
    public static List<Finance_Detail__c> getIBanData(string accId){    	
        if(accId.startsWith('001')){
            System.Debug('**** Acc Id=' + accId);
        	return [Select Id, Name,Primary__c, IBan__c, Account_Num__c, BIC__c, Bank_Name__c
         		FROM Finance_Detail__c Where Account__c =:accId AND RecordType.DeveloperName='Bank' Order By Primary__c desc, LastModifiedDate Desc LIMIT 100]; 	   
        } 
        return null;
    } */
    
    @AuraEnabled
    public static Account getVATData(string accId){    	
        if(accId.startsWith('001')){
            System.Debug('**** Acc Id=' + accId);
        	return [Select Id, Tax_Registration_Number__c, VAT_Valid__c from Account where Id=:accId Limit 1][0];
        } 
        return null;
    }
    
   @AuraEnabled 
    public static boolean ValidateVATNum(string vatNum, string accId){
        map<string, string> mapReturn = new map<string, string>();
        System.Debug('**** TPS:EH 1.0 Starting AddVATNum vatNum=' + vatNum + ' accId='+accId);
        if(vatNum !=null && accId != null){
            VATAPIRes clsRes=ClsApiHelper.VatNumCheck(vatNum);
            if(clsRes.status ==200 && clsRes.message=='success'){
                if(clsRes.validation.status=='ok' && clsRes.validation.valid){
                    Account a = new Account(Id=accId, Tax_Registration_Number__c=vatNum.toUppercase(), VAT_Valid__c=true);
                    update a;
                    
                    // Insert task to log results of vat validation call
                    Id recTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Service_Log').getRecordTypeId();
                    Task tLog= new Task(WhatId=accId, Subject='VAT # [' + vatNum + '] Validation', Description=JSON.serializePretty(clsRes), 
                    	Status='Completed', ActivityDate=Date.Today(), Priority='Normal', Type='Other');
                    insert tLog;
                    return true;
                }
            }
        }
        return false;
    }
}