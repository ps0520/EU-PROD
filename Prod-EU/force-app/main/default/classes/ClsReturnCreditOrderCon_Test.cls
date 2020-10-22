/********************************************************************************
@Author         : P Saini
@Date Created   : May/06/2020
@Description    : Test class for ClsReturnCreditOrderCon, return and credit order function.
*********************************************************************************/
@isTest
private class ClsReturnCreditOrderCon_Test {
    
    @isTest static void Test_SaveReturnQty(){
        //Insert 1 consumer account record
        List<Account> consumerAccts = ClsTestDataFactory.createAccountsWithBillingAddress(1, 'International Distributor', 'Netherlands');
        
        //Create Pricebook
        Map<String, Id> customPricebookMap = ClsTestDataFactory.createCustomPricebookDIST(new List <String>{'DIST Pricebook'});
        String customPricebookId = customPricebookMap.get('DIST Pricebook');
        
        //Create Products
        Map<String, Id> products = ClsTestDataFactory.createProducts(new List<String> {'MT21255', 'STS-GS-002', 'DEX-SHIP-01'});
        
        //Create Pricebook EntryPair
        Map<Id, Decimal> productIdToPriceMap = new Map<Id, Decimal>();
        for(String productName : products.keySet())
        {
            productIdToPriceMap.put(products.get(productName), 125.00);
            
        }
        Map<Id, Id> productIdToPbeId = ClsTestDataFactory.createCustomPricebookEntriesDIST(productIdToPriceMap, customPricebookId);
        Id chOrderRecdTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('DIST_Sales_Order').getRecordTypeId();
        //Create Order record
        ClsOrderTriggerStaticClass.isExecuting = false;
        Order newOrder = new Order();
        newOrder.AccountId = consumerAccts[0].Id;
        newOrder.RecordtypeId = chOrderRecdTypeId;
        newOrder.Type = 'DIST STANDARD';
        newOrder.EffectiveDate = System.today();
        newOrder.Price_Book__c = customPricebookId;
        newOrder.PriceBook2Id = customPricebookId;
        newOrder.Status = 'Draft';
        insert newOrder;
        
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values())
        {
            OrderItem oi = new OrderItem();
            oi.OrderId = newOrder.Id;
            oi.PricebookEntryId = pbeId;
            oi.Quantity = 1;
            oi.UnitPrice = 125.00;
            oi.Tracking_Number__c = '12345';
            oi.Product_Name__c = 'STS-GS-002' ;
            orderItemList.add(oi);
        }
        insert orderItemList;
        Id oParentOI0Id=orderItemList[0].Id;	Id oParentOI1Id=orderItemList[1].Id;
        
        Test.startTest();
        
        newOrder.Status = 'Closed';
        update newOrder;
        
        Order oReturn = new Order();
        oReturn.AccountId = consumerAccts[0].Id;
        oReturn.RecordtypeId = chOrderRecdTypeId;
        oReturn.Parent_Order__c = newOrder.id;
        oReturn.Type = 'DIST RETURN';
        oReturn.EffectiveDate = System.today();
        oReturn.Price_Book__c = customPricebookId;
        oReturn.PriceBook2Id = customPricebookId;
        oReturn.Status = 'Draft';
        insert oReturn;
        
        List<OrderItem> lstOIChild = new List<OrderItem>();
        for(Id pbeId : productIdToPbeId.values())
        {
            OrderItem oi = new OrderItem();
            oi.OrderId = oReturn.Id;
            oi.PricebookEntryId = pbeId;
            oi.Quantity = -1;
            oi.UnitPrice = 125.00;
            oi.Tracking_Number__c = '12345';
            oi.Product_Name__c = 'STS-GS-002' ;
            oi.Return_Reason__c='Discontinuation';
            lstOIChild.add(oi);
        }
        insert lstOIChild;
        Id oChildOI0Id=lstOIChild[0].Id;	Id pbe0Id=productIdToPbeId.values()[0];
        Id oChildOI1Id=lstOIChild[1].Id;	Id pbe1Id=productIdToPbeId.values()[1];
        
        ClsReturnCreditOrderCon.getReturnProducts(oReturn.id);        
        System.Assert(ClsReturnCreditOrderCon.getReturnReasonsList('GB') != null);
        string srcData='[{"AvailableQty":1,"errorQTY":"No","errorRR":"No","Id":"' + oParentOI0Id + '","OIId":"' + oChildOI0Id + '","PBEId":"' + pbe0Id + '","ProductCode":"STT-GS-003","ProductId":"01t1n00000B6UjMAAV","ReturnQty":1,"ReturnReason":"Internal Processing Error","UnitPrice":125}';
        srcData+=',{"AvailableQty":1,"errorQTY":"No","errorRR":"No","Id":"' + oParentOI1Id + '","OIId":"' + oChildOI1Id + '","PBEId":"' + pbe1Id + '","ProductCode":"STT-GS-003","ProductId":"01t1n00000B6UjMAAV","ReturnQty":0,"ReturnReason":"Internal Processing Error","UnitPrice":125}]';
        ClsReturnCreditOrderCon.SaveReturnQty(srcData, oReturn.id);
        Test.stopTest();
    }
 
}