public class ClsSSIPUtilities {
	//This method will add in the SSIP Opportunity Products upon Subscription Opportunity Insert
    public static void processSubscriptionOpportunityProductCreation(List<Opportunity> newOppList){
        //Instantiating the collections
        List<Opportunity> subscriptionOppList = new List<Opportunity>();
        List<OpportunityLineitem> oppItemsToInsertList = new List<OpportunityLineitem>();
        Set<Id> chPricebookSet = new Set<Id>();
        Map<Id, List<PricebookEntry>> chPBEMap = new Map<Id, List<PricebookEntry>>();
        List<PricebookEntry> chPricebookEntList = new List<PricebookEntry>();
        
        //Gather the Opps that are part of the Subscription
        for(Opportunity op :newOppList){
            //if(op.Type == 'Subscription'){
                //subscriptionOppList.add(op); 
                chPricebookSet.add(op.Pricebook2Id);  
            //}				
        }
        Map<Id, PriceBook2> pbMap = new Map<Id, PriceBook2>([Select id, IsSubscription__c from PriceBook2 Where IsSubscription__c = true AND Id in :chPricebookSet]);
        
       
        //Proceed if there are any subscription opps to be processed
        if(!chPricebookSet.isEmpty()){
            //Prepare the map between the Subscription Pricebook and the Pricebook entries	
            for(PricebookEntry pbe : [SELECT ID, Pricebook2Id, SSIP_Periodic_Order_Quantity__c, SSIP_Next_Order_In_Days__c, UnitPrice, First_Repeat_Order_Lead_Days__c 
                                      FROM PricebookEntry WHERE Pricebook2Id In :pbMap.keySet() AND IsActive = True AND Optional_Subscription_Item__c = false])
            {
                if(chPBEMap.containsKey(pbe.Pricebook2Id)){
                    List<PricebookEntry> pbeList = chPBEMap.get(pbe.Pricebook2Id);
                    pbeList.add(pbe);
                    chPBEMap.put(pbe.Pricebook2Id, pbeList);
                }
                else
                    chPBEMap.put(pbe.Pricebook2Id, new List<PricebookEntry> {pbe});
            }
            //If there are PBEs then go ahead and create the lines
            if(!chPBEMap.isEmpty())
            {
                //For every Subscription Opp insert the Subscription SKUs based on the Pricelistentry tied to the Subscription Pricebook
                for(Opportunity opo :newOppList){ 
                    if (!chPricebookSet.contains(opo.Pricebook2Id)) continue;
                    List<PricebookEntry> oppPBEs = chPBEMap.get(opo.Pricebook2Id);
                    for(PricebookEntry insertPBE : oppPBEs)
                    {
                        OpportunityLineitem ol = new OpportunityLineitem();
                        ol.opportunityID = opo.Id;
                        ol.PricebookEntryId = insertPBE.Id;
                        ol.Quantity = insertPBE.SSIP_Periodic_Order_Quantity__c;
                        ol.UnitPrice = insertPBE.UnitPrice;
                        ol.Repeat_after_in_Days__c = insertPBE.SSIP_Next_Order_In_Days__c;
                        ol.Repeat_Quantity__c = insertPBE.SSIP_Periodic_Order_Quantity__c;
                        ol.First_Repeat_Order_Lead_Days__c = insertPBE.First_Repeat_Order_Lead_Days__c;
                        ol.Product_Added_By_Admin__c = true;
                        oppItemsToInsertList.add(Ol);
                    }
                }
            }
            //Insert Opp Lines
            if(!oppItemsToInsertList.isEmpty())
                insert oppItemsToInsertList;
        }
    }
}