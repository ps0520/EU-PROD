/*************************************************************************************************
Apex Class Name : ClsDEWebStoreServiceHelper
Version : 0.1
Created Date :  2 May, 2018
Function :  This is a helper class to a rest service class : WClsDEWebStoreService
--------------------------------------------------------------------------------------------------
* Developer  Priyanka Kajawe                     
*************************************************************************************************/
global class ClsDEWebStoreServiceHelper {

    /*
     * @Description: Method will send email with token and verification code generated
     * @param: AccountRequestWrapper
     * @return: AccountResponseWrapper
     */
    global static Map<Integer,AccountResponseWrapper> sendLinkAccountsByCodeEmail(AccountRequestWrapper requestWrapper) {
        AccountResponseWrapper responseWrapper = new AccountResponseWrapper();
        String emailAddress = requestWrapper.email;
        String accountGUID = requestWrapper.guid;
        String salesforceAccountId = requestWrapper.accountId;
		String emailFromAddressId;
        Integer statusCode;
        try{
            //send email with above values
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage ();
			//Get the org wide email address id
			emailFromAddressId = ClsApexUtil.GetOrgWideEmailAddrId('de.info@dexcom.com');
            //Query Contact data
            Account thisAccount = [SELECT Id, PersonContactId from Account where id = :salesforceAccountId limit 1];
            
            //Query Template
            EmailTemplate codeEmailTemplate = [SELECT Id, Name, body, htmlValue from EmailTemplate where Name Like :'Account Link Code Email Template' limit 1];
            email.setSubject('ACCOUNT VERIFICATION DETAILS');
            String verificationCode = generateRandomKey(6);
            
            String htmlBody = codeEmailTemplate.htmlValue;
            htmlBody = htmlBody.replace('{!Account_Token__c.Verification_Code__c}', verificationCode);
            email.setHtmlBody(htmlBody);
            
            email.setTemplateId(codeEmailTemplate.id);
            email.setToAddresses(new String[]{emailAddress});
			email.setOrgWideEmailAddressId(emailFromAddressId);
            
          /*  if(!runningInASandbox())
                email.setToAddresses(new String[]{emailAddress}); 
             else 
                 email.setToAddresses(new String[]{System.Label.Sandbox_Generic_Email_Address}); */
            
            email.setTargetObjectId(thisAccount.PersonContactId); 
            email.setTreatTargetObjectAsRecipient(false);
            
            //insert data in Account Token if email send successfully
            Account_Token__c accountTokenEntry = new Account_Token__c();
            accountTokenEntry.Dexcom_Account__c = accountGUID;
            accountTokenEntry.Expiration_Time__c = System.now().addHours(24);
            accountTokenEntry.Account__c = salesforceAccountId;
            accountTokenEntry.Verification_Code__c = verificationCode;  
            
            System.debug('accountTokenEntry>> '+accountTokenEntry);
            Database.insert(accountTokenEntry);
            //send email
            email.whatid = accountTokenEntry.id;
            emails.add(email);
           // System.debug('email>> '+email);
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails);
          //  System.debug('results>> '+results);
            
            //after successfull email sending and adding entry
            responseWrapper.result = System.Label.Result_True;
            statusCode = Integer.valueOf(System.Label.StatusCode_Created); // status code = 201
        }catch(Exception ex){
            responseWrapper.message = System.Label.Request_Processing_Failed_With + ex;
            responseWrapper.result = System.Label.Result_False;
            statusCode = Integer.valueOf(System.Label.StatusCode_Error);  // status code = 400
        }
        Map<Integer,AccountResponseWrapper> resultMap = new Map<Integer,AccountResponseWrapper>();
        resultMap.put(statusCode,responseWrapper);
        return resultMap;
    }
    /*
     * @Description: Method will link Accounts with verification code provided
     * @param: AccountRequestWrapper
     * @return: AccountResponseWrapper
     */
    global static Map<Integer,AccountResponseWrapper> linkAccountsByCode(AccountRequestWrapper requestWrapper) {
        AccountResponseWrapper responseWrapper = new AccountResponseWrapper();
        String accountGUID = requestWrapper.guid;
        String verificationCode = requestWrapper.code;
        String userName = requestWrapper.username;
        responseWrapper.result = System.Label.Result_False;
        Integer statusCode;
        //query data from Account Token for given data
        List<Account_Token__c> accountTokenList = new List<Account_Token__c>([SELECT Id, Dexcom_Account__c, Expiration_Time__c, 
                                                                            Account__c, Verification_Code__c
                                                                           from Account_Token__c 
                                                                            where Dexcom_Account__c =: accountGUID and 
                                                                              Verification_Code__c = :verificationCode limit 10]);
         if(accountTokenList.isEmpty()){ //if account token is not found
            responseWrapper.message = System.Label.Account_Token_Does_Not_Exist;
         }else{
                //check if code is expired or valid
                 System.debug('System.now()>> '+System.now());
                if(accountTokenList[0].Expiration_Time__c >= System.now()){
                    try{
                        //validated information, add Account link Entry
                        Account_Link__c accountLinkEntry = new Account_Link__c();
                        accountLinkEntry.Dexcom_Account_Id__c = accountGUID;
                        accountLinkEntry.Account__c = accountTokenList[0].Account__c;
                        accountLinkEntry.Username__c = userName;
                        System.debug('accountLinkEntry>> '+accountLinkEntry);
                         Database.insert(accountLinkEntry);
                        //after successful Account Link creation
                        responseWrapper.result = System.Label.Result_True;
                        //delete account token
                        Database.delete(accountTokenList[0].id);
                        statusCode = Integer.valueOf(System.Label.StatusCode_Created); // status code = 201
                    }catch(Exception ex){
                        responseWrapper.message = System.Label.Request_Processing_Failed_With + ex;
                        statusCode = Integer.valueOf(System.Label.StatusCode_Error);  // status code = 400
                     }                    
                }else{
                    responseWrapper.message = System.Label.Verification_Code_Expired;
                    statusCode = Integer.valueOf(System.Label.StatusCode_Error);  // status code = 400
                }                
            }
        Map<Integer,AccountResponseWrapper> resultMap = new Map<Integer,AccountResponseWrapper>();
        resultMap.put(statusCode,responseWrapper);
        return resultMap;
    } 
    /*
     * @Description: Method will link Accounts with token provided
     * @param: AccountRequestWrapper
     * @return: AccountResponseWrapper
     */
    global static Map<Integer,AccountResponseWrapper> linkAccountsByToken(AccountRequestWrapper requestWrapper) {
        AccountResponseWrapper responseWrapper = new AccountResponseWrapper();
        String accountGUID = requestWrapper.guid;
        String token = requestWrapper.token;
        String userName = requestWrapper.username;
        responseWrapper.result = System.Label.Result_False;
        Integer statusCode;
      
        //query data from Account Token for given data
        List<Account_Token__c> accountTokenList = new List<Account_Token__c>([SELECT Id, Dexcom_Account__c, Expiration_Time__c, 
                                                                            Account__c, Token__c
                                                                           from Account_Token__c 
                                                                            where Token__c =:token limit 10]);
         if(accountTokenList.isEmpty()){ //if account token is not found
            responseWrapper.message = System.Label.Account_Token_Does_Not_Exist;
            statusCode = Integer.valueOf(System.Label.StatusCode_Error);  // status code = 400
         }else{
                //check if code is expired or valid
                if(accountTokenList[0].Expiration_Time__c >= System.now()){
                    try{
                        //validated information, add Account link Entry
                        Account_Link__c accountLinkEntry = new Account_Link__c();
                        accountLinkEntry.Dexcom_Account_Id__c = accountGUID;
                        accountLinkEntry.Account__c = accountTokenList[0].Account__c;
                        accountLinkEntry.Username__c = userName;
                        System.debug('accountLinkEntry>> '+accountLinkEntry);
                        Database.insert(accountLinkEntry);
                        //after successful Account Link creation
                        responseWrapper.result = System.Label.Result_True;
                        //delete account token
                        Database.delete(accountTokenList[0].id);
                        statusCode = Integer.valueOf(System.Label.StatusCode_Created); // status code = 201
                    }catch(Exception ex){
                        responseWrapper.message = System.Label.Request_Processing_Failed_With + ex;
                        statusCode = Integer.valueOf(System.Label.StatusCode_Error);  // status code = 400
                     }                    
                }else{
                    responseWrapper.message = System.Label.Token_Expired;
                    statusCode = Integer.valueOf(System.Label.StatusCode_Error);  // status code = 400
                }                
            }
        Map<Integer,AccountResponseWrapper> resultMap = new Map<Integer,AccountResponseWrapper>();
        resultMap.put(statusCode,responseWrapper);
        return resultMap;
    }
    /*
     * @Description: Method will send email with token and verification code generated
     * @param: AccountRequestWrapper
     * @return: AccountResponseWrapper
     */
    global static Map<Integer,AccountResponseWrapper> matchAccountsByInfo(AccountRequestWrapper requestWrapper) {
        AccountResponseWrapper responseWrapper = new AccountResponseWrapper();
        List<Account> accountList = new List<Account>();
        Boolean missingData= false; 
        Boolean multipleEntries= false; 
        Boolean accountFound = false;
        String last4OfSN  = '';
        Account thisAccount = new Account();
        Map<Integer,AccountResponseWrapper> resultMap = new Map<Integer,AccountResponseWrapper>();
        
        System.debug('request >> ' + requestWrapper);
        //first criteria : LastName,PersonBirthdate,last4OfReceiverSN
        if(!String.isEmpty(requestWrapper.patientLastName) && !String.isEmpty(requestWrapper.patientDOB)
             && !String.isEmpty(requestWrapper.last4OfReceiverSN)){
                 Date patientDateOfBirth = Date.valueOf(requestWrapper.patientDOB);
                 last4OfSN = '%' + requestWrapper.last4OfReceiverSN; // expecting only last 4 digits                                             
                 accountList = new List<Account>([SELECT Id, Name, PersonEmail  
                                                  from Account 
                                                  where LastName =: requestWrapper.patientLastName AND
                                                  PersonBirthdate = :patientDateOfBirth AND
                                                  Latest_Serial_Number__c LIKE :last4OfSN limit 10]);
           System.debug('1: accountList >> ' + accountList);
             }
          
        //second criteria : LastName,PersonBirthdate,Phone,ShippingStreet
       
        String mailingAddress =  !String.isEmpty(requestWrapper.addressLine2) ? requestWrapper.addressLine1 + ' ; '+ requestWrapper.addressLine2 : 
                                                                                requestWrapper.addressLine1;
        mailingAddress = mailingAddress.left(30); //consider only first 30 characters while saving on newly created account
        if(accountList.isEmpty() && !String.isEmpty(requestWrapper.patientLastName) 
                                      && !String.isEmpty(requestWrapper.patientDOB)
                                      && !String.isEmpty(requestWrapper.patientPhone) 
                                      && !String.isEmpty(mailingAddress)){
                String firstFourOfAddress = mailingAddress.left(4) +'%';
                Date patientDateOfBirth = Date.valueOf(requestWrapper.patientDOB);
                accountList = new List<Account>([SELECT Id, Name, PersonEmail 
                                                 from Account 
                                                 where LastName =: requestWrapper.patientLastName AND
                                                 PersonBirthdate = :patientDateOfBirth AND 
                                                 (Phone =:requestWrapper.patientPhone OR 
												 PersonAssistantPhone =:requestWrapper.patientPhone OR
                                                 PersonHomePhone =:requestWrapper.patientPhone OR
                                                 PersonMobilePhone =:requestWrapper.patientPhone OR
                                                 PersonOtherPhone =:requestWrapper.patientPhone) AND 
                                                 ShippingStreet like :firstFourOfAddress limit 10]); 
               System.debug('2: accountList >> ' + accountList);
              }
        
        if(accountList.isEmpty() && (!String.isEmpty(requestWrapper.patientPhone) || 
                                    (!String.isEmpty(requestWrapper.patientLastName) 
                                      && !String.isEmpty(requestWrapper.patientDOB)))){
            //third criteria: Phone OR (Last Name and DOB)
			//If both LastName and DOB present in the request payload then check for Phone or (LastName + DOB) condition
			if(!String.isEmpty(requestWrapper.patientLastName) && !String.isEmpty(requestWrapper.patientDOB))
			{
				Date patientDateOfBirth = Date.valueOf(requestWrapper.patientDOB);
				accountList = new List<Account>([SELECT Id, Name, PersonEmail 
												 from Account 
												 where Phone =:requestWrapper.patientPhone OR 
												 PersonAssistantPhone =:requestWrapper.patientPhone OR
												 PersonHomePhone =:requestWrapper.patientPhone OR
												 PersonMobilePhone =:requestWrapper.patientPhone OR
												 PersonOtherPhone =:requestWrapper.patientPhone OR
													 (LastName =: requestWrapper.patientLastName AND
													 PersonBirthdate = :patientDateOfBirth) limit 10]);
			
				System.debug('3: accountList >> ' + accountList);
				accountFound = accountList.isEmpty() ? false : true;
			}
			else {
				//If either LastName or DOB is null in the payload then do the check only for the phone
				accountList = new List<Account>([SELECT Id, Name, PersonEmail 
												 from Account 
												 where Phone =:requestWrapper.patientPhone OR 
												 PersonAssistantPhone =:requestWrapper.patientPhone OR
												 PersonHomePhone =:requestWrapper.patientPhone OR
												 PersonMobilePhone =:requestWrapper.patientPhone OR
												 PersonOtherPhone =:requestWrapper.patientPhone limit 10]);
			
				System.debug('3: accountList >> ' + accountList);
				accountFound = accountList.isEmpty() ? false : true;
			}
				
        }
        if(accountList.isEmpty()){ 
            //fifth Criteria: create SF Account
            try{
                thisAccount.FirstName = requestWrapper.patientFirstName;
                thisAccount.LastName = requestWrapper.patientLastName;
                thisAccount.PersonBirthdate = Date.valueOf(requestWrapper.patientDOB);
                thisAccount.PersonEmail = requestWrapper.email;
                thisAccount.Phone = requestWrapper.patientPhone;
               // thisAccount.Latest_Serial_Number__c = last4OfSN;
                thisAccount.BillingStreet = mailingAddress;
                thisAccount.PersonEmail = requestWrapper.email;
                thisAccount.BillingCity = requestWrapper.city;
                thisAccount.BillingCountry = 'Germany'; 
                thisAccount.BillingCountryCode = 'DE';
                thisAccount.BillingState = requestWrapper.state;
                thisAccount.BillingPostalCode = requestWrapper.postalCode;
                thisAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('DE Consumer').getRecordTypeId();
                System.debug('Creating: thisAccount >> ' + thisAccount);
                Database.insert(thisAccount);
                //after insert, add entry in Account Link
                Account_Link__c accountLinkEntry = new Account_Link__c();
                accountLinkEntry.Dexcom_Account_Id__c = requestWrapper.guid;
                accountLinkEntry.Account__c = thisAccount.Id;
                accountLinkEntry.Username__c = requestWrapper.username;
                System.debug('accountLinkEntry>> '+accountLinkEntry);
                Database.insert(accountLinkEntry);
                //return response
                responseWrapper.result = System.Label.Result_True;
                responseWrapper.accountId = thisAccount.id;
                resultMap.put( Integer.valueOf(System.Label.StatusCode_Created),responseWrapper); //Status code = 201
                return resultMap;
            }catch(Exception ex){
                responseWrapper.result = System.Label.Result_False;
                responseWrapper.message = ex.getMessage().containsIgnoreCase('Duplicate') ? System.Label.Account_Duplicate_Found :
                                                System.Label.Request_Processing_Failed_With + ex;
                resultMap.put( Integer.valueOf(System.Label.StatusCode_Error),responseWrapper); //Status code = 400
                return resultMap;
            }
            
        }
       
        if(accountFound){ // if account found with last criteria- phone number only, can't confirm uniqueness
          responseWrapper.result = System.Label.Result_False; 
          responseWrapper.message = System.Label.Uniqueness_Not_Confirmed;  
          resultMap.put( Integer.valueOf(System.Label.StatusCode_Error),responseWrapper); //Status code = 400
          return resultMap;          
        }
        if(accountList.size() ==1){ // account found with other criterias
            thisAccount = accountList[0];  
            if(String.isEmpty(thisAccount.PersonEmail)){ 
                responseWrapper.result = System.Label.Result_False;
                responseWrapper.message = System.Label.Account_Found_Without_Email;
                resultMap.put( Integer.valueOf(System.Label.StatusCode_Error),responseWrapper); //Status code = 400
            }else{
                responseWrapper.result = System.Label.Result_True;
                responseWrapper.accountId = thisAccount.id;
                responseWrapper.email = thisAccount.PersonEmail;
                resultMap.put( Integer.valueOf(System.Label.StatusCode_OK),responseWrapper); //Status code = 200
            }
            return resultMap; 
        } 
        if(accountList.size() > 1){
            responseWrapper.result = System.Label.Result_False;
            responseWrapper.message = System.Label.Multiple_Accounts_Exist;
            resultMap.put( Integer.valueOf(System.Label.StatusCode_Error),responseWrapper); //Status code = 400
            return resultMap; 
        }
        return resultMap;
    }   
     /*
     * @Description: Method will validate the given email address
     * @param: String
     * @return: Boolean
     */
    global static Boolean validateEmailAddress(String emailaddress){
        Boolean result = true;
        
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
        Pattern ePattern = Pattern.compile(emailRegex);
        Matcher eMatcher = ePattern.matcher(emailaddress);
        
        if (!eMatcher.matches()) 
            result = false;
        return result;  
    }
    /*
     * @Description: Method will generate random token and verification code generated
     * @param: AccountRequestWrapper
     * @return: AccountResponseWrapper
     */
    global static String generateRandomKey(Integer KEY_LENGTH){
        
        Blob aes = Crypto.generateAesKey(128);
        String randomValue = EncodingUtil.convertToHex(aes).left(KEY_LENGTH); //generate random value for Token or Code
        
        return randomValue;
    }
    /*
     * @Description: Method will help to send token email
     * @param: Account Id, PersonEmail
     * @return: Message
     */
    @AuraEnabled
    public static String sendTokenEmail(String accountId, String personEmailAddress) {
        System.debug(' values >> ' + accountId + '<< and >> ' + personEmailAddress);
        String message;
		String emailFromAddressId;
         try{
            //send email with above values
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage ();
            //Get the org wide email address id
			emailFromAddressId = ClsApexUtil.GetOrgWideEmailAddrId('de.info@dexcom.com');
			
            //Query Contact data
            Account thisAccount = [SELECT Id, PersonContactId from Account where id = :accountId limit 1];
            
            //Query Template
            EmailTemplate codeEmailTemplate = [SELECT Id, Name, body, htmlValue from EmailTemplate where Name Like :'Account Link Token Email Template' limit 1];
            email.setSubject('ACCOUNT VERIFICATION DETAILS');
            String token = generateRandomKey(25);
            
            String htmlBody = codeEmailTemplate.htmlValue;
            htmlBody = htmlBody.replace('{!Account_Token__c.Token__c}', token);
            email.setHtmlBody(htmlBody);
            
            email.setTemplateId(codeEmailTemplate.id);
            email.setToAddresses(new String[]{personEmailAddress}); 
			email.setOrgWideEmailAddressId(emailFromAddressId);			
             
         /*   if(!runningInASandbox())
                email.setToAddresses(new String[]{personEmailAddress}); 
             else 
                 email.setToAddresses(new String[]{System.Label.Sandbox_Generic_Email_Address}); */
            
            email.setTargetObjectId(thisAccount.PersonContactId); 
            email.setTreatTargetObjectAsRecipient(false);
             
            //insert data in Account Token
            Account_Token__c accountTokenEntry = new Account_Token__c();
            accountTokenEntry.Expiration_Time__c = System.now().addHours(24);
            accountTokenEntry.Account__c = accountId;
            accountTokenEntry.Token__c = token;  
            
            System.debug('accountTokenEntry>> '+accountTokenEntry);
            Database.insert(accountTokenEntry);
             
            //send email
            email.whatid = accountTokenEntry.id;
            emails.add(email);
           // System.debug('email>> '+email);
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails);
           // System.debug('results>> '+results);
             
            //after successful email sending and adding entry
            message = 'Email sent successfully!';
        }catch(Exception ex){
             message = 'Error in sending email :'+ ex;
        }
        return message;
    }
    /*
     * @Description: Method will help to get Account data
     * @param: Account Id
     * @return: Account
     */
     @AuraEnabled
    public static Account getAccount(Id accountId) {
        return [SELECT Name, PersonEmail FROM Account WHERE Id = :accountId];
    }
    /*
     * @Description: Method will help to check if current org is sandbox
     * @param: NA
     * @return: Boolean
     */
    public static Boolean runningInASandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
}