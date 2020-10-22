/*************************************************************************************************
Apex Class Name : AccountResponseWrapper
Version : 0.1
Created Date :  24 April, 2018
Function :  This is a wrapper class to helpful to prepare Rest Request
-------------------------------------------------------------------------------------------------------------------------------------------------
* Developer  Priyanka Kajawe                     Date 24 April,2018                           	
*************************************************************************************************/
global class AccountRequestWrapper {
    public String requestType;
    public String email;
    public String guid;
    public String accountId;
    public String username;
    public String patientFirstName;
    public String patientLastName;
    public String patientDOB;
    public String patientPhone;
    public String country;
    public String addressLine1;
    public String addressLine2;
    public String city;
    public String state;
   	public String postalCode;
    public String last4OfReceiverSN;
    public String code;
    public String token;
    
    global AccountRequestWrapper(){
        requestType = '';
        email = '';
        guid = '';
        accountId = '';
        username = '';
        patientFirstName = '';
        patientLastName = '';
        country = '';
        addressLine1 = '';
        addressLine2 = '';
        city = '';
        state = '';
        postalCode = '';
        last4OfReceiverSN = '';
        code = '';
        token = '';
    }
}