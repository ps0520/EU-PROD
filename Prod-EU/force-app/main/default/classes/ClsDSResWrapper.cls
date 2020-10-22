/*************************************************************************************************
Apex Class Name : ClsDSResWrapper
Version : 1.1
Created Date :  Feb 25, 2020
Function :  This is a wrapper class to helpful to prepare Rest Response
---------------------------------------------------------------------------------------------------
* Developer  P Saini Feb 25, 2020                          	
**************************************************************************************************/
global with sharing class ClsDSResWrapper {
    public String message;   
	public String result;   
    
    global ClsDSResWrapper(){
        message = '';      
        result = '';        
     }
}