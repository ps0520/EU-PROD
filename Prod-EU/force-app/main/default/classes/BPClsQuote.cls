/****************************************************************************************************************
@Author        : Kumar Navneet
@Date Created    : 05/06/2019
@Description    : Created class for process builder(Quote) 
****************************************************************************************************************/
public with Sharing class BPClsQuote {
   
   // updates the quote line item numbers based on the sort order field on the quote line item record.
    public static String UpdateQuoteLineItemNumber(Map<Id, Quote> newQTMap) {
           
        for(Quote QT: newQTMap.values()) {           
                  Map<String, Object> params = new Map<String, Object>();
                  params.put('VarQuoteID', QT.id);                  
                  Flow.Interview.Update_Quote_Line_Item_Number_Flow OFlow = new Flow.Interview.Update_Quote_Line_Item_Number_Flow(params);
                  OFlow.start();              
        }        
           
    return 'OK';    
    
    }
    
}