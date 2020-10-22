trigger QuoteTrigger on Quote (after insert,after update){ 
/*******************************************************************************************************************
@Author        : Navneet
@Date Created    : 8/05/2019
@Description    : Trigger invokes handler class  (process builder)
********************************************************************************************************************/    
   if(trigger.isAfter){
      // invoking country handler
       ClsQuoteCountryHandler.afterInsertUpdateHandler(trigger.new, trigger.newmap); 
   }


}