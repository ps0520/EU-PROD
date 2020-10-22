/***************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 09/13/2017
@Description    : Trigger handler handles logic for Opportunity Line Item changes
****************************************************************************************/
/***************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 11/13/2017
@Description    : Added logic to accomodate Medical Advice Feature changes
****************************************************************************************/
public class ClsOpportunityLineItemTriggerHandler {
    
    //Method invoked on Opportunity line items insert
    public static void OnAfterInsertUpdate(List<OpportunityLineItem> opptyLineItemsToProcess, String insertOrUpdate){
        system.debug('Entering the process for ' + insertOrUpdate);
        
        //Map Opportunity Id to its Line items that are to be processed
        Map<Id, List<OpportunityLineItem>> opptyToLineItemsMap = new Map<Id, List<OpportunityLineItem>>();
        
        //Find Opportunities, which have quotes either in Draft or Approved status 
        for(OpportunityLineItem oli : opptyLineItemsToProcess)
        {
            if(oli.Count_Of_Non_Rejected_Quotes__c > 0)
            {
                System.debug('Found items to be processed for inserts');
                //Create a map between Opportunity and Opportunity line items 
                if(opptyToLineItemsMap.containsKey(oli.OpportunityId))
                {
                    List<OpportunityLineItem> opptyItemsList = opptyToLineItemsMap.get(oli.OpportunityId);
                    opptyItemsList.add(oli);
                    opptyToLineItemsMap.put(oli.OpportunityId, opptyItemsList);
                }
                else
                {
                    opptyToLineItemsMap.put(oli.OpportunityId, new List<OpportunityLineItem> {oli});
                }
                
            }
        }
        System.debug('Oppty Items ' + opptyToLineItemsMap.size());
        
        //Proceed if there are quotes that are neeed to be altered to match Opportunity
        if(opptyToLineItemsMap.size() > 0)
        {
            //List to insert or update quote line items
			List<QuoteLineItem> quoteLineItemsToBeInserted = new List<QuoteLineItem>();
            List<QuoteLineItem> quoteLineItemsToBeUpdated = new List<QuoteLineItem>();
            
			//Map Opportunity Id to its Line items that are to be processed
            Map<String, Quotelineitem> quoteLineItemsMap = new Map<String, Quotelineitem>();
            
            if(insertOrUpdate == 'Update')
            {
                //Create a map between 	for possiblle Quote line items 
                for(Quotelineitem qli : [SELECT Id, Product2Id, QuoteId, Quantity, UnitPrice, Medical_Advice_Feature_Code__c FROM Quotelineitem WHERE Quote.OpportunityId IN : opptyToLineItemsMap.keySet()])
                {
                    String externalId = qli.QuoteId + '-' + qli.Product2Id;
                    if(!quoteLineItemsMap.containsKey(externalId))
                    {
                        quoteLineItemsMap.put(externalId, qli);
                    }
                }	
            }
            //For each non-rejected quote tied to the Opportunity prepare the quote line item records that are to be inserted or updated
            for(Quote q : [SELECT Id, OpportunityId FROM Quote WHERE Status != 'Rejected' AND OpportunityId IN : opptyToLineItemsMap.keySet()])
            {
                //Loop through the Opportunity line items and create quote line items
                for(OpportunityLineItem oli : opptyToLineItemsMap.get(q.OpportunityId))
                {
                    //If the operation is insert then insert the quote line items
                    if(insertOrUpdate == 'Insert')
                    {
                        QuoteLineItem qli = new QuoteLineItem();
                        qli.QuoteId = q.Id;
                        qli.PricebookEntryId = oli.PricebookEntryId;
                        //qli.Quantity = String.isBlank(oli.Split_Qty__c.toPlainString()) ? oli.Quantity : oli.Split_Qty__c;
                        qli.Quantity = oli.Split_Qty__c == null ? oli.Quantity : oli.Split_Qty__c;
                        //qli.UnitPrice = String.isBlank(oli.Split_Price__c.toPlainString()) ? oli.UnitPrice : oli.Split_Price__c;
                        qli.UnitPrice = oli.Split_Price__c == null ? oli.UnitPrice : oli.Split_Price__c;
						qli.Medical_Advice_Feature_Code__c = oli.Is_Medical_Advice_Numbered_Product__c == true ? oli.Medical_Advice_Feature__c : '';
                        qli.Description = 'Created via Apex';
                        quoteLineItemsToBeInserted.add(qli);
                        system.debug('Qli quote id is ' + qli.QuoteId);
                        system.debug('Qli Quantity is ' + oli.Split_Qty__c);
                        system.debug('Qli UnitPrice is ' + oli.Split_Price__c);
						system.debug('Qli Medical_Advice_Feature_Code__c is ' + qli.Medical_Advice_Feature_Code__c);
						
                    }
                    //If the operation is update then update the Price and Qty for corresponding quote line items
                    if(insertOrUpdate == 'Update' && quoteLineItemsMap.size() > 0)
                    {
                        String qliExternalId = q.Id + '-' + oli.Product2Id;
                        QuoteLineItem qli = quoteLineItemsMap.get(qliExternalId);
                        qli.Quantity = oli.Split_Qty__c == null ? oli.Quantity : oli.Split_Qty__c;
                        qli.UnitPrice = oli.Split_Price__c == null ? oli.UnitPrice : oli.Split_Price__c;
						qli.Medical_Advice_Feature_Code__c = oli.Is_Medical_Advice_Numbered_Product__c == true ? oli.Medical_Advice_Feature__c : '';
                        quoteLineItemsToBeUpdated.add(qli);
                        system.debug('Qli Quantity is ' + qli.Quantity);
                        system.debug('Qli UnitPrice is ' + qli.UnitPrice);
                    }
                    
                }
            }
            //If there are quote items to be inserted then insert them
            if(!quoteLineItemsToBeInserted.isEmpty())
            {
                try{
                    insert quoteLineItemsToBeInserted;
                }catch(DMLException ex){
                    system.debug('***ERROR IN INSERTING QUOTE LINE ITEMS*** ' + ex.getMessage());
                }
            }
            //If there are quote items to be updated then update them
            if(!quoteLineItemsToBeUpdated.isEmpty())
            {
                try{
                    update quoteLineItemsToBeUpdated;
                }catch(DMLException ex){
                    system.debug('***ERROR IN UPDATING QUOTE LINE ITEMS*** ' + ex.getMessage());
                }
            }
        }
        
    }	
    
    //Method invoked on Opportunity line items delete
    public static void OnAfterDelete(List<OpportunityLineItem> opptyLineItemsToProcess){
        system.debug('Entering the process after delete');
        Set<Id> productIds = new Set<Id>();
        Set<Id> opptyIds = new Set<Id>();
        
        //Get all the products, which are deleted
        for(OpportunityLineItem oli : opptyLineItemsToProcess)
        {
            productIds.add(oli.Product2Id);
            opptyIds.add(oli.OpportunityId);
        }
        system.debug('Size of productIds' + productIds.size());
        system.debug('Size of opptyIds' + opptyIds.size());
        
        
        //Get all the quote line items, which are referencing the products in productIds set
        List<QuoteLineItem> quoteLineItemsList = new List<QuoteLineItem> ([SELECT Id FROM QuoteLineItem WHERE Quote.Status != 'Rejected'AND Quote.Opportunity.Id IN : opptyIds AND Product2Id IN : productIds]);
        
        system.debug('Size of quoteLineItemsList' + quoteLineItemsList.size());
        
        //If there are quote items found then delete them
        if(!quoteLineItemsList.isEmpty())
        {
            try{
                delete quoteLineItemsList;
            }catch(DMLException ex){
                system.debug('***ERROR IN DELETE*** ' + ex.getMessage());
            }
        }
        
    }
}