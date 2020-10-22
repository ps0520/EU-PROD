/*************************************************************************************************
Apex Class Name : AccountResponseWrapper
Version : 0.1
Created Date :  24 April, 2018
Function :  This is a wrapper class to helpful to prepare Rest Response
---------------------------------------------------------------------------------------------------
* Developer  Priyanka Kajawe                     Date 24 April,2018                           	
**************************************************************************************************/
global class AccountResponseWrapper {
    public String message;
   // public Integer statusCode;
	public String result;
    public String accountId;
    public String email;
    
    global AccountResponseWrapper(){
        message = '';
      //  statusCode = 0;
        result = '';
        accountId = '';
        email = '';
     }
}