public class ErrorUtility {
    public static String LogError(String action, String classNMethodName, String errorMsg, String eventType, String eventSource, String exceptionError, String externalID, String severity){
      	if (1 == 1 /*severity != 'Success Log' */) {
            try{
                insert new Platform_Event_Error_Log__c(Error_Handling_Status__c = 'New', Action__c = action, Class_And_Method__c = classNMethodName,
                                                       Error_Message__c = exceptionError.left(255), Event__c = eventType, EventSource__c = eventSource,
                                                       Exception_Error__c = errorMsg, ExternalID__c = externalID, Severity__c = severity);
                return 'Successfully!';
            }catch(Exception ex){
                return 'Error! ' + ex.getMessage();
            }
        } else return 'Ignored';
    }
    public static String LogErrorWithEvent(String action, String classNMethodName, String errorMsg, String eventType, String eventSource, String exceptionError, String externalID, String severity, String event){
      	if (severity != 'Success Log') {
            try{
     
                insert new Platform_Event_Error_Log__c(Error_Handling_Status__c = 'New', Action__c = action, Class_And_Method__c = classNMethodName,
                                                       Error_Message__c = exceptionError.left(255), Event__c = eventType, EventSource__c = eventSource,
                                                       Exception_Error__c = errorMsg, ExternalID__c = externalID, Severity__c = severity, Event_String__c = event);
                return 'Successfully!';
            }catch(Exception ex){
                return 'Error! ' + ex.getMessage();
            }
        } else return 'Ignored';
    }
    
    public static Platform_Event_Error_Log__c prepareErroLog(String action, String classNMethodName, String errorMsg, String eventType, String eventSource, String exceptionError, String externalID, String severity, String event){
        return new Platform_Event_Error_Log__c(Error_Handling_Status__c = 'New', Action__c = action, Class_And_Method__c = classNMethodName,
                                               Error_Message__c = exceptionError.left(255), Event__c = eventType, EventSource__c = eventSource,
                                               Exception_Error__c = errorMsg, ExternalID__c = externalID, Severity__c = severity, Event_String__c = event);
    }
}