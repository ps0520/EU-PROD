/*************************************************************************************************
Apex Class Name : WClsTestDEWebStoreService
Version : 0.1
Created Date :  9 May, 2018
Function :  This is a test class to a rest service class : WClsDEWebStoreService
--------------------------------------------------------------------------------------------------
* Developer  Priyanka Kajawe                     
*************************************************************************************************/
@isTest
public class WClsTestDEWebStoreService {
    public static Account thisAccount;
    public static List<Account_Token__c> accountTokenList;
    /*
     * @Description: Method will check if test code email can be sent
     */
    public static testMethod void getCanSendLinkAccountsEmailTest() {
        testDataSetup();
        Test.startTest();
        // with no email address
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/accounts'; 
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        AccountResponseWrapper result1 = WClsDEWebStoreService.getCanSendLinkAccountsEmail();
        
        //with email address
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.requestURI = '/services/apexrest/accounts/Test@testmail.com'; 
        request.httpMethod = 'GET';
        request.addHeader('Content-Type', 'application/json'); 
        RestContext.request = request;
        RestContext.response = response;
        AccountResponseWrapper result2 = WClsDEWebStoreService.getCanSendLinkAccountsEmail();
        Test.stopTest();
    }
    /*
     * @Description: Method will send test code email
     */
    public static testMethod void sendLinkAccountsByCodeEmailTest() {
        List<AccountRequestWrapper> thisList = new List<AccountRequestWrapper>();
        thisList = getRequest(System.Label.Account_Token_Code_Email);
        
        //invalid request type
        List<AccountRequestWrapper> thisInvalidList = new List<AccountRequestWrapper>();
        thisInvalidList = getRequest('Invalid_request_type');
        thisList.addall(thisInvalidList);
        
        Test.startTest();
        //--------------------------callout---------------------
        for(AccountRequestWrapper thisCallout : thisList){
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/accounts'; 
            req.httpMethod = 'POST';
            
            String JsonMsg1=JSON.serialize(thisCallout);
            
            req.requestBody = Blob.valueof(JsonMsg1);
            req.addHeader('Content-Type', 'application/json');
            RestContext.request = req;
            RestContext.response = res;
            AccountResponseWrapper result1 = WClsDEWebStoreService.processAccountLinkRequest();
        }
        Test.stopTest();
    }
    /*
     * @Description: Method will link accounts by code
     */
    public static testMethod void accountLinkByCode(){
        
        Test.startTest();
        List<AccountRequestWrapper> tokenValidationList = new List<AccountRequestWrapper>();
        tokenValidationList = getRequest(System.Label.Account_Link_By_Code);
        //--------------------------callout1---------------------
        Integer count = 0;
        
        for(AccountRequestWrapper thisCallout: tokenValidationList){
            if(count==1){
                
                accountTokenList = new List<Account_Token__c>([SELECT Id, Dexcom_Account__c, Expiration_Time__c, 
                                                               Account__c, Verification_Code__c
                                                               from Account_Token__c 
                                                               where Dexcom_Account__c =: '123456' limit 10]);
               // System.debug('list >> '+accountTokenList );
            }
            if(count==0){
                thisCallout.requestType = System.Label.Account_Token_Code_Email;
            }else{
                thisCallout.code =   String.valueOf(accountTokenList[0].Verification_Code__c);
            }
            count++;
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/accounts'; 
            req.httpMethod = 'POST';
            
            String JsonMsg1=JSON.serialize(thisCallout);
            
            req.requestBody = Blob.valueof(JsonMsg1);
            req.addHeader('Content-Type', 'application/json');
            RestContext.request = req;
            RestContext.response = res;
            AccountResponseWrapper result = WClsDEWebStoreService.processAccountLinkRequest();
        } 
        Test.stopTest();
    }
    /*
     * @Description: Method will try to match account by info
     */
    public static testMethod void matchAccountByInfo(){
        
        Test.startTest();
        List<AccountRequestWrapper> tokenValidationList = new List<AccountRequestWrapper>();
        tokenValidationList = getRequest(System.Label.Match_Account_By_Info);
        
        //--------------------------callouts----------------------
        Integer recordCount = 0;
        for(AccountRequestWrapper scenario : tokenValidationList){
            if(recordCount ==0){
                scenario.requestType = System.Label.Account_Token_Code_Email;
            }
            if(recordCount == 1){
                accountTokenList = new List<Account_Token__c>([SELECT Id, Dexcom_Account__c, Expiration_Time__c, 
                                                               Account__c, Verification_Code__c
                                                               from Account_Token__c 
                                                               where Dexcom_Account__c =: '111111' limit 10]);
              //  System.debug('list >> '+accountTokenList );
                
                scenario.code =   String.valueOf(accountTokenList[0].Verification_Code__c);
                scenario.requestType = System.Label.Account_Link_By_Code;
            }
            recordCount++;
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/accounts'; 
            req.httpMethod = 'POST';
            
            String JsonMsg1=JSON.serialize(scenario);
            
            req.requestBody = Blob.valueof(JsonMsg1);
            req.addHeader('Content-Type', 'application/json');
            RestContext.request = req;
            RestContext.response = res;
            AccountResponseWrapper result1 = WClsDEWebStoreService.processAccountLinkRequest();
        }
        
        Test.stopTest();
    }	
    /*
     * @Description: Method will generate Account token and link accounts by token
     */
    public static testMethod void sendAndLinkAccountToken(){
        testDataSetup();
        Test.startTest();
        ClsDEWebStoreServiceHelper.sendTokenEmail(thisAccount.id, 'Test@testmail.com');
        Account resultAccount = ClsDEWebStoreServiceHelper.getAccount(thisAccount.id);
        Boolean checkSandbox = ClsDEWebStoreServiceHelper.runningInASandbox();
        
        List<AccountRequestWrapper> tokenRequestList = new List<AccountRequestWrapper>();
        tokenRequestList = getRequest(System.Label.Account_Link_By_Token);
        accountTokenList = new List<Account_Token__c>([SELECT Id, Dexcom_Account__c, Expiration_Time__c, 
                                                       Account__c, Token__c
                                                       from Account_Token__c 
                                                       where Account__c =: thisAccount.id limit 10]);
       // System.debug('list >> '+accountTokenList );
        for(AccountRequestWrapper thisCallout :tokenRequestList){
            thisCallout.token =   String.valueOf(accountTokenList[0].Token__c);
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/accounts'; 
            req.httpMethod = 'POST';
            
            String JsonMsg1=JSON.serialize(thisCallout);
            
            req.requestBody = Blob.valueof(JsonMsg1);
            req.addHeader('Content-Type', 'application/json');
            RestContext.request = req;
            RestContext.response = res;
            AccountResponseWrapper result1 = WClsDEWebStoreService.processAccountLinkRequest(); 
        }
        
        Test.stopTest();
    }
    /*
     * @Description: Method will generate test data
     */
    public static void testDataSetup(){
        if(thisAccount == null){
            thisAccount = ClsTestDataBuilder.testAccount();
            thisAccount.PersonBirthdate = Date.valueof('1967-05-03');
            thisAccount.Latest_Serial_Number__c = '3214';
            insert thisAccount;
        }
    }
    /*
     * @Description: Method will generate test payloads
     */
    public static List<AccountRequestWrapper> getRequest(String requestType){
        testDataSetup();
        List<AccountRequestWrapper> thisList = new List<AccountRequestWrapper>();
        AccountRequestWrapper requestWrapper1;
        AccountRequestWrapper requestWrapper2;
        AccountRequestWrapper requestWrapper3;
        AccountRequestWrapper requestWrapper4;
        AccountRequestWrapper requestWrapper5;
        AccountRequestWrapper requestWrapper6;
        
        if(requestType.equalsIgnoreCase(System.Label.Account_Token_Code_Email)){
            //valid request
            requestWrapper1 = new AccountRequestWrapper();
            requestWrapper1.requestType =  requestType;
            requestWrapper1.email =  String.valueOf(thisAccount.PersonEmail);
            requestWrapper1.guid =  '111111';
            requestWrapper1.accountId = String.valueOf(thisAccount.id);
            thisList.add(requestWrapper1);
            //missing field
            requestWrapper2= new AccountRequestWrapper();
            requestWrapper2.requestType =  requestType;
            requestWrapper2.email =  String.valueOf(thisAccount.PersonEmail);
            requestWrapper2.accountId = String.valueOf(thisAccount.id);
            thisList.add(requestWrapper2);
            //invalid email address
            requestWrapper3= new AccountRequestWrapper();
            requestWrapper3.requestType =  requestType;
            requestWrapper3.email =  'test.test.com';
            requestWrapper3.guid =  '111111';
            requestWrapper3.accountId = String.valueOf(thisAccount.id);
            thisList.add(requestWrapper3);
        }else if(requestType.equalsIgnoreCase(System.Label.Account_Link_By_Code)){
            //valid request
            requestWrapper1 = new AccountRequestWrapper();
            requestWrapper1.requestType =  requestType;
            requestWrapper1.email =  String.valueOf(thisAccount.PersonEmail);
            requestWrapper1.guid =  '123456';
            requestWrapper1.accountId = String.valueOf(thisAccount.id);
            thisList.add(requestWrapper1);
            //missing field
            requestWrapper2= new AccountRequestWrapper();
            requestWrapper2.requestType =  requestType;
            requestWrapper2.guid =  '123456';
            requestWrapper2.username = 'testUser';
            thisList.add(requestWrapper2);
            //invalid guid
            requestWrapper3= new AccountRequestWrapper();
            requestWrapper3.requestType =  requestType;
            requestWrapper3.guid =  '222222';
            requestWrapper3.username = 'testUser';
            thisList.add(requestWrapper3);
        }else if(requestType.equalsIgnoreCase(System.Label.Match_Account_By_Info)){
            //valid request
            requestWrapper1 = new AccountRequestWrapper();
            requestWrapper1.requestType =  requestType;
            requestWrapper1.email =  String.valueOf(thisAccount.PersonEmail);
            requestWrapper1.guid =  '111111';
            requestWrapper1.accountId = String.valueOf(thisAccount.id);
            thisList.add(requestWrapper1);
            //missing field
            requestWrapper2= new AccountRequestWrapper();
            requestWrapper2.requestType =  requestType;
            requestWrapper2.username = 'testUser';
            thisList.add(requestWrapper2);
            //scenario 1
            requestWrapper3 = new AccountRequestWrapper();
            requestWrapper3.requestType =  requestType;
            requestWrapper3.patientLastName =  thisAccount.LastName;
            requestWrapper3.patientDOB =  String.valueOf(thisAccount.PersonBirthdate);
            requestWrapper3.last4OfReceiverSN = thisAccount.Latest_Serial_Number__c;
            thisList.add(requestWrapper3);
            //scenario 2
            requestWrapper4 = new AccountRequestWrapper();
            requestWrapper4.requestType =  requestType;
            requestWrapper4.patientLastName =  thisAccount.LastName;
            requestWrapper4.patientDOB =  String.valueOf(thisAccount.PersonBirthdate);
            requestWrapper4.patientPhone = thisAccount.Phone;
            requestWrapper4.addressLine1 = thisAccount.ShippingStreet;
            thisList.add(requestWrapper4);
            //scenario 3
            requestWrapper5 = new AccountRequestWrapper();
            requestWrapper5.requestType =  requestType;
            requestWrapper5.patientPhone = thisAccount.Phone;
            thisList.add(requestWrapper5);
            //scenario 4
            requestWrapper6 = new AccountRequestWrapper();
            requestWrapper6.requestType =  requestType;
            requestWrapper6.guid = '106493901';
            requestWrapper6.username = 'jperiya';
            requestWrapper6.patientFirstName = 'Jack';
            requestWrapper6.patientLastName = 'Mor';
            requestWrapper6.patientDOB = '1967-05-03';
            requestWrapper6.last4OfReceiverSN = '3214';
            requestWrapper6.addressLine1 = 'Wallstraße';
            requestWrapper6.addressLine2 = 'Wallstraße';
            requestWrapper6.city = 'Düsseldorf';
            requestWrapper6.postalcode = '40213';
            requestWrapper6.patientPhone = '9999999989';
            thisList.add(requestWrapper6);
        }else if(requestType.equalsIgnoreCase(System.Label.Account_Link_By_Token)){
            //valid request
            requestWrapper1 = new AccountRequestWrapper();
            requestWrapper1.requestType =  requestType;
            requestWrapper1.guid =  '111111';
            requestWrapper1.username = 'testUser';
            thisList.add(requestWrapper1); 
            //missing field
            requestWrapper2= new AccountRequestWrapper();
            requestWrapper2.requestType =  requestType;
            requestWrapper2.username = 'testUser';
            thisList.add(requestWrapper2);
        }else{
            requestWrapper1 = new AccountRequestWrapper();
            requestWrapper1.requestType =  requestType;
            requestWrapper1.guid =  '111111';
            requestWrapper1.username = 'testUser';
            thisList.add(requestWrapper1); 
        }	
        return thisList;
    }
    public static testMethod void deleteExpiredAccountTokens(){
        
        List<Account_Token__c> tokenList = new List<Account_Token__c>();
        
        testDataSetup();
        
        for(Integer count=0 ; count < 10 ; count++){
            Account_Token__c accountTokenEntry = new Account_Token__c();
            accountTokenEntry.Dexcom_Account__c = '100100';
            accountTokenEntry.Expiration_Time__c = System.now().addHours(-48);
            accountTokenEntry.Account__c = thisAccount.id;
            accountTokenEntry.Verification_Code__c = '7eF3Jl';
            System.debug('time > '+accountTokenEntry.Expiration_Time__c);
            tokenList.add(accountTokenEntry);
        }
        insert(tokenList);
        Test.startTest();
        ID batchprocessid = Database.executeBatch(new BClsDeleteExpiredAccountTokens());
        Test.stopTest();
    }
}