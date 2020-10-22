/****************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 4/25/2017
@Description    : Class used in to process all Address related logic for Account upon inserting and updating
****************************************************************************************************************/
public class ClsAccountAddressTriggerHandler
{
    //Method populates Account Shipping Address from Account Billing Address if the shipping address information is blank
    public static void ProcessAccountShippingAddressOnAccountInsert(List<Account> Accounts)
    {
        //Loop through all accounts and find if Shipping information is null and then populate the shipping  address values from billing address
        for(Account accnt : Accounts)
        {
			//If Billing address is filled in only then copy over the address values to Shipping address
			if((!String.isBlank(accnt.BillingStreet) && String.isBlank(accnt.ShippingStreet) && String.isBlank(accnt.ShippingCity) && String.isBlank(accnt.ShippingState) && String.isBlank(accnt.ShippingPostalCode)) || accnt.Copy_Billing_To_Shipping__c)
			{
				system.debug('----Entering the process to update the Shipping address as it was blank or Copy_Billing_To_Shipping__c is checked');
				accnt.ShippingCountryCode = accnt.BillingCountryCode;
				accnt.ShippingStreet = accnt.BillingStreet;
				accnt.ShippingCity = accnt.BillingCity;
				accnt.ShippingPostalCode = accnt.BillingPostalCode;
				// Added the following line to make the code work for the countries that support States too. Vijay Adusumilli May 07, 2019.
                if (String.isNotBlank(accnt.BillingStateCode)) accnt.ShippingStateCode = accnt.BillingStateCode;
				
			}
			//If Shipping address is filled in only then copy over the address values to Billing address
			if((!String.isBlank(accnt.ShippingStreet) && String.isBlank(accnt.BillingStreet) && String.isBlank(accnt.BillingCity) && String.isBlank(accnt.BillingState) && String.isBlank(accnt.BillingPostalCode)) || accnt.Copy_Shipping_To_Billing__c)
			{
				system.debug('----Entering the process to update the Billing address as it was blank or Copy_Shipping_To_Billing__c is checked');
				accnt.BillingCountryCode = accnt.ShippingCountryCode;
				accnt.BillingStreet = accnt.ShippingStreet;
				accnt.BillingCity = accnt.ShippingCity;
				accnt.BillingPostalCode = accnt.ShippingPostalCode;
                if (String.isNotBlank(accnt.ShippingStateCode)) accnt.BillingStateCode = accnt.ShippingStateCode;
				
			}

        }
    }
    
    //Method will create Bill To and Ship To address for account. This will be used when an account is inserted
    public static void ProcessAccountRelatedAddressOnAccountInsert(List<Account> Accounts)
    {
        List<Address__c> addressToCreateList = new List<Address__c>();//List holds the address records to be created
        
        //Get the map between the country code to its  recordtype id for Address__c object
        Map<String, Id> addressRecordTypeMap = ClsAccountAddressTriggerHandlerHelper.getAddressRecordTypeMap();
        
        //Loop through all accounts and create a primary Bill To and primary Ship To
        for(Account accnt : Accounts)
        {
            
            if(!String.isBlank(accnt.BillingStreet))
			{
                String billingRecordTypeId = (accnt.BillingCountryCode == 'GB' || accnt.BillingCountryCode == 'IE') ? addressRecordTypeMap.get('UK') : addressRecordTypeMap.get(accnt.BillingCountryCode);                    
                Address__c billToAddr = ClsAccountAddressTriggerHandlerHelper.CreateAddress(accnt.Id, accnt.BillingStreet, accnt.BillingCity, accnt.BillingState, accnt.BillingPostalCode, accnt.BillingCountry, 'Bill To', billingRecordTypeId);
                addressToCreateList.add(billToAddr);
            }
            if(!String.isBlank(accnt.ShippingStreet))
            {
                String shippingRecordTypeId = (accnt.ShippingCountryCode == 'GB' || accnt.ShippingCountryCode == 'IE') ? addressRecordTypeMap.get('UK') : addressRecordTypeMap.get(accnt.ShippingCountryCode);            
                Address__c shipToAddr = ClsAccountAddressTriggerHandlerHelper.CreateAddress(accnt.Id, accnt.ShippingStreet, accnt.ShippingCity, accnt.ShippingState, accnt.ShippingPostalCode, accnt.ShippingCountry, 'Ship To', shippingRecordTypeId);
                addressToCreateList.add(shipToAddr);
			}
        }
        //Insert Address Records
        if(!addressToCreateList.isEmpty())
        {
            system.debug('----Entering the process to create Bill To and Ship To Address tied to this account');
            ClsAccountAddressTriggerStaticClass.addressChangeInvokedFromAddress = false; //Set the static variable, so the code in Address object will not fire.
            try{insert addressToCreateList;}
            catch (DmlException de) {
                Integer numErrors = de.getNumDml();
                System.debug('getNumDml=' + numErrors);
                for(Integer i=0;i<numErrors;i++) {
                    System.debug('getDmlFieldNames=' + de.getDmlFieldNames(i));
                    System.debug('getDmlMessage=' + de.getDmlMessage(i));
                }
            }
        }
    }
	
	//Set the Shipping address when the Copy Billing to Shipping check box is selected
    public static void ProcessAccountRelatedAddressOnAccountUpdate(List<Account> Accounts)
    {
		for(Account accnt : Accounts)
        {
			if(accnt.Copy_Billing_To_Shipping__c)
			{
				system.debug('----Entering the process to update the Shipping address as Copy_Billing_To_Shipping__c is checked');
				accnt.ShippingStreet = accnt.BillingStreet;
				accnt.ShippingCity = accnt.BillingCity;
				accnt.ShippingPostalCode = accnt.BillingPostalCode;
				if (String.isNotBlank(accnt.BillingStateCode)) accnt.ShippingStateCode = accnt.BillingStateCode;
				accnt.ShippingCountryCode = accnt.BillingCountryCode;
					
			}
			if(accnt.Copy_Shipping_To_Billing__c)
			{
				system.debug('----Entering the process to update the Billing address as Copy_Shipping_To_Billing__c is checked');
				accnt.BillingStreet = accnt.ShippingStreet;
				accnt.BillingCity = accnt.ShippingCity;
				accnt.BillingPostalCode = accnt.ShippingPostalCode;
				if (String.isNotBlank(accnt.ShippingStateCode)) accnt.BillingStateCode = accnt.ShippingStateCode;
				accnt.BillingCountryCode = accnt.ShippingCountryCode;
				
			}
			accnt.Copy_Billing_To_Shipping__c = false;		
			accnt.Copy_Shipping_To_Billing__c = false;
		}
	}
    
    //Method will be called from account trigger after the record is updated. This will process the records in address object for the account and sets correct primary Bill To and Ship To
    public static void ProcessAccountRelatedAddressOnAccountUpdate(Map<Id, Account> newTriggerAccnts, Map<Id, Account> oldTriggerAccnts)
    {
        //Invoke the below block of code only when the address change happened from the Account rather than the Address object
        if(ClsAccountAddressTriggerStaticClass.addressChangeInvokedFromAccount)
        {
            List<Account> billToAccountsToProcess = new List<Account>();//Holds list of accounts that are to be processed for Bill To address change
            List<Account> shipToAccountsToProcess = new List<Account>();//Holds list of accounts that are to be processed for Ship To address change
            //Check if any account's bill to address got updated and then proceed
            for(Account newAccnt : newTriggerAccnts.values())
            {
                Account oldAccnt = oldTriggerAccnts.get(newAccnt.Id);
                if(oldAccnt.BillingStreet != newAccnt.BillingStreet || oldAccnt.BillingCity != newAccnt.BillingCity || oldAccnt.BillingState != newAccnt.BillingState || oldAccnt.BillingPostalCode != newAccnt.BillingPostalCode || oldAccnt.BillingCountryCode != newAccnt.BillingCountryCode)
                {
                    system.debug('----Found mismatch in Billing address information');
                    billToAccountsToProcess.add(newAccnt);
                    
                }
                if(oldAccnt.ShippingStreet != newAccnt.ShippingStreet || oldAccnt.ShippingCity != newAccnt.ShippingCity || oldAccnt.ShippingState != newAccnt.ShippingState || oldAccnt.ShippingPostalCode != newAccnt.ShippingPostalCode || oldAccnt.ShippingCountryCode != newAccnt.ShippingCountryCode)
                {
                    system.debug('----Found mismatch in Shipping address information');
                    shipToAccountsToProcess.add(newAccnt);
                }
            }
            
            //If there are records to be processed for Bill To change then go in to the loop
            if(!billToAccountsToProcess.isEmpty())
            {
                system.debug('----Entering the process to handle Bill To Address changes');
                ClsAccountAddressTriggerStaticClass.addressChangeInvokedFromAddress = false; //Set the static variable, so the code in Address object will not fire.
                ClsAccountAddressTriggerHandlerHelper.ProcessAddressRecords('Bill To', billToAccountsToProcess);
            }
            //If there are records to be processed for Ship To change then go in to the loop
            if(!shipToAccountsToProcess.isEmpty())
            {
                system.debug('----Entering the process to handle Ship To Address changes');
                ClsAccountAddressTriggerStaticClass.addressChangeInvokedFromAddress = false;//Set the static variable, so the code in Address object will not fire.
                ClsAccountAddressTriggerHandlerHelper.ProcessAddressRecords('Ship To', shipToAccountsToProcess);
            }
        }	
    }  
    
    //Static List of Wrapper Class that will help to store data between before and after delete trigger
    public static Map<String,List<Account_Merge_Update__mdt>> UpdateObjectFieldsMap = new Map<String,List<Account_Merge_Update__mdt>>();
    public static List<sObject> accountRelatedDeleteData = new List<sObject>();
    public static List<sObject> accountRelatedUpdateData = new List<sObject>();
    public static Map<String, String> objectToAccountFieldMap = new Map<String, String>();
    /***********************************************************************************
@Method to store Data from Before Delete Trigger
@Param : Account Ids targeted for delete
************************************************************************************/
    public static void storeAccountRelatedData(Set<Id> oldTriggerIds){        
        
        List<String> queryList = new List<String>();
        List<String> deleteQueryList = new List<String>();
        List<sObject> accountRelatedData = new List<sObject>();
        
        Map<ID,Account_Merge_Delete__mdt> accountMergeDeleteObjects = new Map<ID,Account_Merge_Delete__mdt>([SELECT Account_Field_API_Name__c, Object_API_Name__c from Account_Merge_Delete__mdt where Active__c = true]);
        
        Map<ID,Account_Merge_Update__mdt> accountMergeUpdateObjects = new Map<ID,Account_Merge_Update__mdt>([SELECT Object_API_Name__c, Reference_Field_API_Name__c, Target_Field_API_Name__c, Target_Field_Data_Type__c, Target_Field_Value__c from Account_Merge_Update__mdt where Active__c = true]);
        
        for(Account_Merge_Delete__mdt mdtRecord : accountMergeDeleteObjects.values()){
            objectToAccountFieldMap.put(mdtRecord.Object_API_Name__c , mdtRecord.Account_Field_API_Name__c);
        }   
        
        for(Account_Merge_Update__mdt mdtUpdateRecord : accountMergeUpdateObjects.values()){
            objectToAccountFieldMap.put(mdtUpdateRecord.Object_API_Name__c , mdtUpdateRecord.Reference_Field_API_Name__c);
            
            if(UpdateObjectFieldsMap.Keyset().Contains(mdtUpdateRecord.Object_API_Name__c) && UpdateObjectFieldsMap.get(mdtUpdateRecord.Object_API_Name__c).size() > 0) //seperate as per Object Name
                UpdateObjectFieldsMap.get(mdtUpdateRecord.Object_API_Name__c).add(mdtUpdateRecord);
            else
                UpdateObjectFieldsMap.put(mdtUpdateRecord.Object_API_Name__c, new List<Account_Merge_Update__mdt>{mdtUpdateRecord});
            
        }   
        
        
        for(String objRecord : objectToAccountFieldMap.KeySet()){            
            
            String query = 'SELECT Id, '+ objectToAccountFieldMap.get(objRecord);
            
            if(UpdateObjectFieldsMap.KeySet().Contains(objRecord)){ //If Update, query all other fields that will get updated
                for(Account_Merge_Update__mdt mdtRecord : UpdateObjectFieldsMap.get(objRecord)){
                    query = query + ', ' + mdtRecord.Target_Field_API_Name__c;
                }   
            }
            query = query + ' from ' + objRecord + ' where ' + objectToAccountFieldMap.get(objRecord) + ' IN : oldTriggerIds';
            queryList.add(query);
            System.debug('Delete query >>' + query);
        }
        System.debug('queryList >>' + queryList);
        
        Integer SOQLLimit = 0;
        for(String thisQuery : queryList){
            if(SOQLLimit < 10){ //To take care SOQL Limits
                List<sObject> relatedData = new List<sObject>();
                relatedData = Database.query(thisQuery); //store all account related records
                System.debug('relatedData>> '+ relatedData); 
                
                accountRelatedData.addAll(relatedData);
                SOQLLimit++;
            }else{
                break;
                System.debug('******************* SOQL LIMIT REACHED *******************');
            }   
        }
        System.debug('accountRelatedData>> '+ accountRelatedData); 
        
        //segregate data to delete and update
        for(sObject deleteRecord : accountRelatedData){ 
            for(Account_Merge_Delete__mdt mdtRecord : accountMergeDeleteObjects.values()){
                if(deleteRecord.getSObjectType().getDescribe().getName() == mdtRecord.Object_API_Name__c){
                    accountRelatedDeleteData.add(deleteRecord);
                    break;
                }   
            }   
        }
        System.debug('accountRelatedDeleteData>> '+ accountRelatedDeleteData); 
        for(sObject updateRecord : accountRelatedData){ 
            for(Account_Merge_Update__mdt mdtRecord : accountMergeUpdateObjects.values()){
                if(updateRecord.getSObjectType().getDescribe().getName() == mdtRecord.Object_API_Name__c){
                    accountRelatedUpdateData.add(updateRecord);
                    break;
                }   
            }   
        }   
        System.debug('accountRelatedUpdateData>> '+ accountRelatedUpdateData);   
    }
    /*********************************************************************************
@Method : Process Account Merge : Loosing Account Related Records Update/Delete
@Param : List of Accounts
**********************************************************************************/
    public static void processAccountMerge(List<Account> oldTrigger){
        Set<Id> mergedLoosingAccounts = new Set<Id>(); //loosing account ids
        List<sObject> updateObjectsList = new  List<sObject>(); // identified loosing accounts addresses        
        Map<String, List<sObject>> updateObjects = new  Map<String, List<sObject>>(); //final list to update addresses
        List<sObject> deletesObjects = new  List<sObject>(); // List to store loosing account benefits
        //    List<Marketing_Account__c> deleteMarketingAccounts = new  List<Marketing_Account__c>(); // List to store loosing account Marketing Accounts
        
        for(Account thisAccount: oldTrigger){
            if(thisAccount.MasterRecordId != null)
                mergedLoosingAccounts.add(thisAccount.Id); //Merged Loosing Account Ids 
        }
        system.debug('mergedLoosingAccounts>>'+mergedLoosingAccounts);
        
        //update related records
        if(!accountRelatedUpdateData.isEmpty()){
            //identify data related to loosing Account
            for(sObject updateRecord : accountRelatedUpdateData){
                String objectAPIName = updateRecord.getSObjectType().getDescribe().getName();
                for(Id thisAccountId : mergedLoosingAccounts){
                    if(updateRecord.get(objectToAccountFieldMap.get(objectAPIName)) == thisAccountId){ // identify loosing account
                        if(updateObjects.Keyset().Contains(objectAPIName) && updateObjects.get(objectAPIName).size() > 0) //seperate as per Object Name
                            updateObjects.get(objectAPIName).add(updateRecord);
                        else
                            updateObjects.put(objectAPIName, new List<sObject>{updateRecord});
                    }
                }
            }
            System.debug('updateObjects>> '+ updateObjects);
            if(!updateObjects.isEmpty()){
                for(String updateObject : updateObjects.keySet()){ //process object one by one
                    for(sObject updateObjectRecord : updateObjects.get(updateObject)){ //processs all records related to object
                        
                        SObjectType objToken = Schema.getGlobalDescribe().get(updateObject);
                        DescribeSObjectResult objDef = objToken.getDescribe();
                        Map<String, SObjectField> fields = objDef.fields.getMap();
                        
                        
                        sObject thisSObject = Schema.getGlobalDescribe().get(updateObject).newSObject() ;
                        thisSObject.put(fields.get('id'),updateObjectRecord.id);
                        for(Account_Merge_Update__mdt mdtRecord : UpdateObjectFieldsMap.get(updateObject)){ //populate all fields
                            System.debug('mdtRecord>> '+ mdtRecord);
                            if(mdtRecord.Target_Field_Data_Type__c == 'Checkbox'){
								thisSObject.put(fields.get(mdtRecord.Target_Field_API_Name__c), Boolean.valueOf(mdtRecord.Target_Field_Value__c));                            }
                        }
                        updateObjectsList.add(thisSObject);
                        System.debug('thisSObject>> '+ thisSObject);
                    }
                }  
                System.debug('updateObjectsList>> '+ updateObjectsList); 
            }   
        }  
        
        //delete related records
        if(!accountRelatedDeleteData.isEmpty()){
            //identify data related to loosing Account
            for(sObject deleteRecord : accountRelatedDeleteData){
                String objectAPIName = deleteRecord.getSObjectType().getDescribe().getName();
                for(Id thisAccountId : mergedLoosingAccounts){
                    if(deleteRecord.get(objectToAccountFieldMap.get(objectAPIName)) == thisAccountId){ // identify loosing account
                        sObject thisSObject = Schema.getGlobalDescribe().get(objectAPIName).newSObject(deleteRecord.id) ;
                        deletesObjects.add(thisSObject);
                    }
                }
            }
            System.debug('deletesObjects>> '+ deletesObjects);
        } 
        try{
            if(!updateObjectsList.isEmpty()) {update(updateObjectsList);}  //Update records
            if(!deletesObjects.isEmpty()) {delete(deletesObjects);} //delete records
        }catch(Exception Ex){
            System.debug('Update Failed >>' + EX);
        }
        
    }    
}