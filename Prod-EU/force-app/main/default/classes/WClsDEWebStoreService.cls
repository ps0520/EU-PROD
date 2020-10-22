/*************************************************************************************************
Apex Class Name : WClsDEWebStoreService
Version : 0.1
Created Date :  24 April, 2018
Function :  This is a rest service class will be helpful to check if salesforce account is present with the given email address.
---------------------------------------------------------------------------------------------------------------------------------
* Developer  Priyanka Kajawe                     Date 24 April,2018                           	
*************************************************************************************************/
@RestResource(urlMapping='/accounts/*')
global with sharing class WClsDEWebStoreService {
    /*
     * @Description: Method will check if Account present in SF with given email address
     * @param: N/A
     * @return: AccountResponseWrapper
     */
    @HttpGet
    global static AccountResponseWrapper getCanSendLinkAccountsEmail() {
        AccountResponseWrapper responseWrapper = new AccountResponseWrapper();
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = Integer.valueOf(System.Label.StatusCode_Error);
		responseWrapper.result = System.Label.Result_False;
        
        String emailAddress = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        System.debug('Request data >' + emailAddress);
        
        //if request does not contain email address or not a valid email address
        if(String.isEmpty(emailAddress) || !ClsDEWebStoreServiceHelper.validateEmailAddress(emailAddress)){ 
            responseWrapper.message = System.Label.Invalid_Email_Address;
            return responseWrapper;
        }
        //Query Accounts from SF with given email address
        List<Account> accountList = new List<Account>([SELECT Id, Name, PersonEmail  
                                                       from Account 
                                                       where PersonEmail  = :emailAddress limit 10]);
        
        //if account is not found
        responseWrapper.message = accountList.isEmpty() ? System.Label.Account_Not_Found : 
        													(accountList.size()>1 ? System.Label.Multiple_Accounts_Exist : '');
            
        if(accountList.size() == 1){ //if valid only account is found
            responseWrapper.result = System.Label.Result_True;
           // responseWrapper.statusCode = 200;
            responseWrapper.accountId = accountList[0].id;
            res.statusCode = Integer.valueOf(System.Label.StatusCode_OK);
        }
        return responseWrapper;
    }
    
    /*
     * @Description: Method will check request type and invoke respective POST Call
     * @param: AccountRequestWrapper
     * @return: AccountResponseWrapper
     */
    @HttpPost
    global static AccountResponseWrapper processAccountLinkRequest() {
		
        //deserialise request 
        String jsonStr = null;
        if (null != RestContext.request.requestBody) {
            jsonStr = RestContext.request.requestBody.toString();
        }
        System.debug(LoggingLevel.ERROR, 'jsonStr ===> ' + jsonStr); 
        AccountRequestWrapper requestWrapper = (AccountRequestWrapper)System.JSON.deserialize(jsonStr, AccountRequestWrapper.class);
        
        System.debug('Request>> '+ requestWrapper);
        RestResponse restResponse = RestContext.response;
		restResponse.statusCode = Integer.valueOf(System.Label.StatusCode_Error);
		
        AccountResponseWrapper responseWrapper = new AccountResponseWrapper();
        responseWrapper.result = System.Label.Result_False;
        Map<Integer, AccountResponseWrapper> resultMap = new Map<Integer, AccountResponseWrapper>();
        Integer statusCode;
        
        if(requestWrapper.requestType.equalsIgnoreCase(System.Label.Account_Token_Code_Email)){
            //check if required information is missing from request 
            if(String.isEmpty(requestWrapper.email) || String.isEmpty(requestWrapper.guid) || String.isEmpty(requestWrapper.accountId)){
                responseWrapper.message = System.Label.Request_Data_Missing;
                 restResponse.statusCode = Integer.valueOf(System.Label.StatusCode_Error);
                return responseWrapper;            
            }
			//check if valid email address provided in Rest Request            
			if(!ClsDEWebStoreServiceHelper.validateEmailAddress(requestWrapper.email)){ 
                responseWrapper.message = System.Label.Invalid_Email_Address;
                 restResponse.statusCode = Integer.valueOf(System.Label.StatusCode_Error);
                return responseWrapper;
            }
            //invoke method to process Rest
           	resultMap = ClsDEWebStoreServiceHelper.sendLinkAccountsByCodeEmail(requestWrapper);
            statusCode = new List<Integer>(resultMap.keySet())[0];
            responseWrapper = resultMap.get(statusCode);
            System.debug('response >> ' + responseWrapper);
            
        }else if(requestWrapper.requestType.equalsIgnoreCase(System.Label.Account_Link_By_Code)){
            //check if required information is missing from request 
            if(String.isEmpty(requestWrapper.guid) || String.isEmpty(requestWrapper.code) || String.isEmpty(requestWrapper.username)){
                responseWrapper.message = System.Label.Request_Data_Missing;
                restResponse.statusCode = Integer.valueOf(System.Label.StatusCode_Error);
                return responseWrapper;            
            } 
            //invoke method to process Rest
            resultMap = ClsDEWebStoreServiceHelper.linkAccountsByCode(requestWrapper);
            statusCode = new List<Integer>(resultMap.keySet())[0];
            responseWrapper = resultMap.get(statusCode);
            
        }else if(requestWrapper.requestType.equalsIgnoreCase(System.Label.Account_Link_By_Token)){
            //check if required information is missing from request 
            if(String.isEmpty(requestWrapper.guid) || String.isEmpty(requestWrapper.token) || String.isEmpty(requestWrapper.username)){
                responseWrapper.message = System.Label.Request_Data_Missing;
                restResponse.statusCode = Integer.valueOf(System.Label.StatusCode_Error);
                return responseWrapper;            
            } 
            //invoke method to process Rest
            resultMap = ClsDEWebStoreServiceHelper.linkAccountsByToken(requestWrapper);
            statusCode = new List<Integer>(resultMap.keySet())[0];
            responseWrapper = resultMap.get(statusCode);
            
        }else if(requestWrapper.requestType.equalsIgnoreCase(System.Label.Match_Account_By_Info)){
            //invoke method to process Rest
            resultMap = ClsDEWebStoreServiceHelper.matchAccountsByInfo(requestWrapper);
            statusCode = new List<Integer>(resultMap.keySet())[0];
            responseWrapper = resultMap.get(statusCode);
            
        }else{
            responseWrapper.message = System.Label.Request_Type_Incorrect;
            restResponse.statusCode = Integer.valueOf(System.Label.StatusCode_Error);
            return responseWrapper;
        }
        //set Rest response status code
        restResponse.statusCode = statusCode;
        return responseWrapper;
    } 
}