/****************************************************************************************
@Description : Class handles all logic related to Marketing Interactions for all countries
******************************************************************************************/

public class ClsMarketingInteractionHandler {
    
    //Method evaluates changes for Account updates to create the MIs
    //Method segregates the country specific records
    public static void handleMIsForAccountUpdates(Map<Id, Account> newTriggerAccount, Map<Id, Account> oldTriggerAccount) {
        ClsAccountAddressTriggerStaticClass.invokeMILogicOnlyOnce = false;
        //CA Interactions collection
        Map<Id, Account> newCATriggerAccount = new Map<Id, Account>();
        Map<Id, Account> oldCATriggerAccount = new Map<Id, Account>();
        //GB/IE Interactions collections
        Map<Id, Account> newUKTriggerAccount = new Map<Id, Account>();
        Map<Id, Account> oldUKTriggerAccount = new Map<Id, Account>();
        
        for(Account newAccnt : newTriggerAccount.values())
        {
            String recdTypeDeveloperName = Schema.SObjectType.Account.getRecordTypeInfosById().get(newAccnt.RecordTypeId).getDeveloperName();
            //Route the logic to CA specific method
            if(recdTypeDeveloperName.startsWithIgnoreCase('CA_'))
            {
                Account oldAccnt = oldTriggerAccount.get(newAccnt.Id);
                newCATriggerAccount.put(newAccnt.Id, newAccnt);
                oldCATriggerAccount.put(oldAccnt.Id, oldAccnt);
            }
            //Route the logic to GB specific method
            if(recdTypeDeveloperName.startsWithIgnoreCase('GB_') || recdTypeDeveloperName.startsWithIgnoreCase('IE_'))
            {
                Account oldAccnt = oldTriggerAccount.get(newAccnt.Id);
                newUKTriggerAccount.put(newAccnt.Id, newAccnt);
                oldUKTriggerAccount.put(oldAccnt.Id, oldAccnt);
            }
        }
        if(!newCATriggerAccount.isEmpty() && !oldCATriggerAccount.isEmpty()){
            handleCAMIsForAccountUpdates(newCATriggerAccount, oldCATriggerAccount);
        }
        if(!newUKTriggerAccount.isEmpty() && !oldUKTriggerAccount.isEmpty()){
            handleUKMIsForAccountUpdates(newUKTriggerAccount, oldUKTriggerAccount);
        }
    }
    //Method evaluates changes for UK Account updates to create the MIs
    public static void handleUKMIsForAccountUpdates(Map<Id,Account> newTriggerAccount, Map<Id,Account> oldTriggerAccount) {
        system.debug('***ENTERED THE METHOD handleUKMIsForAccountUpdates');
        Set<String> accountsToProcessForMIsSet = new Set<String>(); //Reason for the concatenated set is same account may be involved in multiple MIs
        Set<Id> g6ProdOnBoardAccnts = new Set<Id>();
        Set<Id> g6SubUpsellAccnts = new Set<Id>();
        List<Marketing_Interaction__c> newMIsListToBeCreated = new List<Marketing_Interaction__c> (); //List of MIs to be created
        for (Account newAccnt: newTriggerAccount.values()) {
            //Get Account before update for Reference
            Account oldAccnt = oldTriggerAccount.get(newAccnt.Id);
            //Find if there are any new Starter Kit for the account
            system.debug('****oldAccnt.G6_Transmitter_Ship_Date__c ' + oldAccnt.G6_Transmitter_Ship_Date__c);
            system.debug('****newAccnt.G6_Transmitter_Ship_Date__c ' + newAccnt.G6_Transmitter_Ship_Date__c);
            system.debug('****Date.Today() ' + Date.Today());
            if ((oldAccnt.G6_Transmitter_Ship_Date__c != newAccnt.G6_Transmitter_Ship_Date__c) && newAccnt.G6_Transmitter_Ship_Date__c != null && Date.Today() >= newAccnt.G6_Transmitter_Ship_Date__c){
                g6ProdOnBoardAccnts.add(newAccnt.Id);
                accountsToProcessForMIsSet.add(newAccnt.Id + '|' + 'UKIE - Customer Onboarding - G6');
                system.debug('***FOUND ENTRY FOR UK/IE CUSTOMER ONBOARDING');
            }
            
            if (newAccnt.G6_Starter_Kit_Ship_Date__c != null && (newAccnt.G6_Starter_Kit_Ship_Date__c != oldAccnt.G6_Starter_Kit_Ship_Date__c) && Date.Today() >= newAccnt.G6_Starter_Kit_Ship_Date__c.date()){
                g6SubUpsellAccnts.add(newAccnt.Id);
                accountsToProcessForMIsSet.add(newAccnt.Id + '|' + 'UKIE - Subscription Upsell - G6');
                System.debug('***FOUND ENTRY FOR UK/IE SUBSCRIPTION UPSELL');
            }
            
        }
        //Find if there are any MIs to be processed
        if (!accountsToProcessForMIsSet.isEmpty()) {
            system.debug('***ENTERED THE METHOD TO PROCESS THE LOGIC');
            Set<Id> accountIdSet = new Set<Id>();
            Set<Id> ukieOnboardingSet = new Set<Id>();
            Set<Id> ukieSubUpsellSet = new Set<Id>();
            Map<Id,String> accntToG6XmerOrderMap = new Map<Id,String>();
            Map<Id,String> accountIdToCountry = new Map<Id,String>();
            
            //Get all the account Ids involved for processing			
            for (String str: accountsToProcessForMIsSet) {
                List<String> accntIdToTypeList = str.split('\\|');
                accountIdSet.add(accntIdToTypeList[0]);
            }
            
            //Get all MIs tied the accounts involved in processing, we need to use this to verify before we create the MIs
            Map <Id, Marketing_Interaction__c> miMap = new Map <Id, Marketing_Interaction__c> ([SELECT Id, Account__c, Communication_Type__c FROM Marketing_Interaction__c WHERE Account__c IN: accountIdSet]);
            for (Marketing_Interaction__c mi: miMap.values()) {
                system.debug('***EXISTING MEARKETING INTERACTIONS FOUND ');
                if (mi.Communication_Type__c == 'UKIE - Customer Onboarding - G6') {
                    ukieOnboardingSet.add(mi.Account__c);
                } else if (mi.Communication_Type__c == 'UKIE - Subscription Upsell - G6'){
                    ukieSubUpsellSet.add(mi.Account__c);
                }
            }
            //If there are new G6 customers then process below logic to retrieve the latest G6 Xmer Order tied to the customer
            if (!g6ProdOnBoardAccnts.isEmpty()) {
                system.debug('***ENTERED THE LOGIC FOR involvesG6ReorderReminder');
                for (Account accnt: [SELECT Id,
                                     (SELECT Id, Shipping_Method__c, Recordtype.Name FROM Orders WHERE Latest_G6_Transmitter_Ship_Date__c != null AND Status = 'Closed'
                                      AND(Recordtype.Name = 'GB Sales Order'
                                          OR Recordtype.Name = 'IE Sales Order'
                                          OR Recordtype.Name = 'GB Sales Order Read Only'
                                          OR Recordtype.Name = 'IE Sales Order Read Only') ORDER BY Createddate DESC LIMIT 1)
                                     FROM Account WHERE Id IN: g6ProdOnBoardAccnts
                                    ]) {
                                        List<Order> ordList = accnt.Orders;
                                        //Find if there are any orders and then proceed
                                        if (!ordList.isEmpty()) {
                                            String madeupString = ordList[0].Id + '|' + ordList[0].Shipping_Method__c;
                                            accntToG6XmerOrderMap.put(accnt.Id, madeupString);
                                            if (ordList[0].Recordtype.Name == 'GB Sales Order' || ordList[0].Recordtype.Name == 'GB Sales Order Read Only') {
                                                accountIdToCountry.put(accnt.Id, 'United Kingdom');
                                            } else if (ordList[0].Recordtype.Name == 'IE Sales Order' || ordList[0].Recordtype.Name == 'IE Sales Order Read Only') {
                                                accountIdToCountry.put(accnt.Id, 'Ireland');
                                            }
                                        }
                                    }
            }
            
                            /*for(OrderItem oi : [SELECT Id, Order.Id, Order.AccountId, Order.Shipping_Method__c, Order.Recordtype.Name FROM OrderItem WHERE Order.AccountId IN : g6ProdOnBoardAccnts AND Product_Name__c = 'STT-GS-003' AND (Order.Recordtype.Name = 'GB Sales Order' OR Order.Recordtype.Name = 'IE Sales Order' OR Order.Recordtype.Name = 'GB Sales Order Read Only' OR Order.Recordtype.Name = 'IE Sales Order Read Only')  AND Order.Status = 'Closed' ORDER BY Order.AccountId, Order.Createddate DESC LIMIT 1])
{
system.debug('***FOUND ORDER WITH STT-GS-003');
String madeupString = oi.Order.Id + '|' + oi.Order.Shipping_Method__c;
accntToG6XmerOrderMap.put(oi.Order.AccountId, madeupString);
if(oi.Order.Recordtype.Name == 'GB Sales Order' || oi.Order.Recordtype.Name == 'GB Sales Order Read Only') 
accountIdToCountry.put(oi.Order.AccountId, 'United Kingdom');
else if(oi.Order.Recordtype.Name == 'IE Sales Order' || oi.Order.Recordtype.Name == 'IE Sales Order Read Only') 
accountIdToCountry.put(oi.Order.AccountId, 'Ireland');
}*/
            
            //Prepare the required sets required for analysis
            Map<Id,Account> gbSubUpsellAccntMap = new Map<Id,Account>([SELECT Id, RecordTypeId FROM Account WHERE Id IN :g6SubUpsellAccnts]);
            for (String str: accountsToProcessForMIsSet) {
                List<String> accntIdToTypeList = str.split('\\|');
                Id accntId = accntIdToTypeList[0];
                
                //Check if the communication type is UKIE - Customer Onboarding - G6 and equivalent MI doesn't exist before then proceed
                if (accntIdToTypeList[1] == 'UKIE - Customer Onboarding - G6' && !ukieOnboardingSet.contains(accntId) && !accntToG6XmerOrderMap.isEmpty() && !accountIdToCountry.isEmpty()) {
                    if (accntToG6XmerOrderMap.containsKey(accntId)) {
                        system.debug('***PROCESING UKIE - Customer Onboarding - G6');
                        //Get reference to the latest Xmer order to pass in the order information in the MI
                        String miReferenceFields = accntToG6XmerOrderMap.get(accntId);
                        List<String> g6XmerOrderRefValues = miReferenceFields.split('\\|'); //This will split the string with the Order Id and its shipping method
                        //Construct information to create the MI
                        newMIsListToBeCreated.add(createMI(accntId, g6XmerOrderRefValues[0], 'UKIE - Customer Onboarding - G6', g6XmerOrderRefValues[1], accountIdToCountry.get(accntId)));
                        newMIsListToBeCreated.add(createMI(accntId, g6XmerOrderRefValues[0], 'UKIE - Customer Review', g6XmerOrderRefValues[1], accountIdToCountry.get(accntId)));
                        newMIsListToBeCreated.add(createMI(accntId, g6XmerOrderRefValues[0], 'UKIE - Warrior Recruitment', g6XmerOrderRefValues[1], accountIdToCountry.get(accntId)));
                    }
                }
                
                if (accntIdToTypeList[1] == 'UKIE - Subscription Upsell - G6' && !ukieSubUpsellSet.contains(accntId)) { 
                    system.debug('***PROCESING UKIE - Subscription Upsell - G6');
                    Id gbConsumerId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('GB_Consumer').getRecordTypeId();
                    Id ieConsumerId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IE_Consumer').getRecordTypeId();
                    String countryString;
                    Account gbSubUpsellAcct = gbSubUpsellAccntMap.get(accntId);
                    if (gbSubUpsellAcct.RecordTypeId == gbConsumerId){
                        countryString = 'United Kingdom';
                    } else if (gbSubUpsellAcct.RecordTypeId == ieConsumerId){
                        countryString = 'Ireland';
                    }
                    if(String.isNotBlank(countryString)){
                        newMIsListToBeCreated.add(createMI(accntId, null, 'UKIE - Subscription Upsell - G6', null, countryString));
                    }
                }
            }           
        }
        // Insert marketing interaction
        if (newMIsListToBeCreated.size() > 0) {
            system.debug('********Enter process to create new MIs');
            try {
                insert newMIsListToBeCreated;
            } catch (DmlException de) {
                system.debug(de);
            }
        }
    }
    
    //Method evaluates changes for CA Account updates to create the MIs
    public static void handleCAMIsForAccountUpdates(Map<Id, Account> newTriggerAccount, Map<Id, Account> oldTriggerAccount) {
        system.debug('***ENTERED THE METHOD handleCAMIsForAccountUpdates');
        Set<String> accountsToProcessForMIsSet = new Set<String>();//Reason for the concatenated set is same account may be involved in multiple MIs
        Set<Id> accountsWithG6ConvFlgSet = new Set<Id>();//Set holds the Account Ids, which have the G6_Starter_Kit_Conversion__c set
        List<Marketing_Interaction__c> newMIsListToBeCreated = new List<Marketing_Interaction__c>();//List of MIs to be created
        List<Account> accntToBeUpdatedWithG6ConvFlag = new List<Account>();//List of accounts to be updated with G6 Converstion Flag
        Set<Id> g6ProdOnBoardAccnts = new Set<Id>();
        Set<Id> g6ReordRemindAccnts = new Set<Id>();
        
        for(Account newAccnt : newTriggerAccount.values())
        {	
            //Get Account before update for Reference
            Account oldAccnt = oldTriggerAccount.get(newAccnt.Id);
            //Find if there are any new Closed Orders for the account
            if((oldAccnt.Number_of_Orders__c != newAccnt.Number_of_Orders__c) && (oldAccnt.Number_of_Orders__c == null || oldAccnt.Number_of_Orders__c == 0) && newAccnt.Number_of_Orders__c == 1)
            {
                system.debug('***FOUND ENTRY FOR THE CA CUSTOMER ONBOARDING FLOW');
                accountsToProcessForMIsSet.add(newAccnt.Id + '|' + 'CA - Customer Onboarding');
            }
            system.debug('newAccnt.G6_Transmitter_Ship_Date__c' + newAccnt.G6_Transmitter_Ship_Date__c);
            //Find if there are any new G6 Transmitter shipped for the customer
            if((oldAccnt.G6_Transmitter_Ship_Date__c != newAccnt.G6_Transmitter_Ship_Date__c) && oldAccnt.G6_Transmitter_Ship_Date__c == null && newAccnt.G6_Transmitter_Ship_Date__c != null && Date.Today() >= newAccnt.G6_Transmitter_Ship_Date__c)
            {
                g6ProdOnBoardAccnts.add(newAccnt.Id);
                accountsToProcessForMIsSet.add(newAccnt.Id + '|' + 'CA - Product Onboarding - G6');
                system.debug('***FOUND ENTRY FOR CA PRODUCT ONBOARDING G6');
            }
            system.debug('newAccnt.G6_Starter_Kit_Ship_Date__c' + newAccnt.G6_Starter_Kit_Ship_Date__c);
            //Find if there are any new Starter Kit for the account
            if((oldAccnt.G6_Starter_Kit_Ship_Date__c != newAccnt.G6_Starter_Kit_Ship_Date__c) && newAccnt.G6_Starter_Kit_Ship_Date__c != null && Date.Today() >= newAccnt.G6_Starter_Kit_Ship_Date__c)
            {
                g6ReordRemindAccnts.add(newAccnt.Id);
                accountsToProcessForMIsSet.add(newAccnt.Id + '|' + 'CA - Reorder Reminder - G6 Starter Kit');
                system.debug('***FOUND ENTRY FOR CA REORDER REMINDER G6 STARTER KIT');
            }
            //Find if account has the starter kit order and now has ordered a new product
            if((oldAccnt.Number_of_Orders__c != newAccnt.Number_of_Orders__c) && newAccnt.Number_of_Orders__c != null && newAccnt.Number_of_Orders__c > 1 && oldAccnt.G6_Starter_Kit_Ship_Date__c != null && newAccnt.G6_Starter_Kit_Conversion__c == false )
            {
                system.debug('***FOUND ENTRY FOR NEW ORDER AFTER STARTER KIT TO SET THE CONVERTED FLAG');
                accountsToProcessForMIsSet.add(newAccnt.Id + '|' + 'CA - Set Converted Flag');
            }
            //Prepare the set of Account Ids with G6_Starter_Kit_Conversion__c
            if(newAccnt.G6_Starter_Kit_Conversion__c){
                accountsWithG6ConvFlgSet.add(newAccnt.Id);
            }
        }
        //Find if there are any MIs to be processed
        if(!accountsToProcessForMIsSet.isEmpty())
        {
            system.debug('***ENTERED THE METHOD TO PROCESS THE LOGIC');
            Set<Id> accountIdSet = new Set<Id>();
            Set<Id> caOnboardingSet = new Set<Id>();
            Set<Id> caG6ProductOnboardingSet = new Set<Id>();
            Set<Id> caG6ReorderSet = new Set<Id>();
            Map<Id, String> accntToG6XmerOrderMap = new Map<Id, String>();
            Map<Id, String> accntToG6StarterKitOrderMap = new Map<Id, String>();			
            
            //Get all the account Ids involved for processing			
            for(String str : accountsToProcessForMIsSet)
            {
                List<String> accntIdToTypeList = str.split('\\|');
                accountIdSet.add(accntIdToTypeList[0]);
            }
            
            //Get all MIs tied the accounts involved in processing, we need to use this to verify before we create the MIs
            Map<Id, Marketing_Interaction__c> miMap = new Map<Id, Marketing_Interaction__c>([SELECT Id, Account__c, Communication_Type__c FROM Marketing_Interaction__c WHERE Account__c IN : accountIdSet]);
            for(Marketing_Interaction__c mi : miMap.values())
            {
                system.debug('***EXISTING MEARKETING INTERACTIONS FOUND ');
                if(mi.Communication_Type__c == 'CA - Customer Onboarding') {caOnboardingSet.add(mi.Account__c);}
                if(mi.Communication_Type__c == 'CA - Product Onboarding - G6') {caG6ProductOnboardingSet.add(mi.Account__c);}
                if(mi.Communication_Type__c == 'CA - Reorder Reminder - G6 Starter Kit') {caG6ReorderSet.add(mi.Account__c);}
            }
            
            //If involvesG6ProductOnboarding = true then process below logic
            if(!g6ProdOnBoardAccnts.isEmpty())
            {
                system.debug('***ENTERED THE LOGIC FOR involvesG6ProductOnboarding');
                for (Account accnt : [SELECT Id,
                                      (SELECT Id, Shipping_Method__c FROM Orders WHERE Latest_G6_Transmitter_Ship_Date__c != null AND Status = 'Closed' AND Recordtype.Name = 'CA Sales Order' ORDER BY Createddate DESC LIMIT 1)
                                      FROM Account WHERE Id IN : g6ProdOnBoardAccnts])
                {
                    List<Order> ordList = accnt.Orders;
                    //Find if there are any orders and then proceed
                    if(!ordList.isEmpty()){
                        String madeupString = ordList[0].Id + '|' + ordList[0].Shipping_Method__c;
                        accntToG6XmerOrderMap.put(accnt.Id, madeupString);
                    }
                }
                /*
for(OrderItem oi : [SELECT Id, Order.Id, Order.AccountId, Order.Shipping_Method__c FROM OrderItem WHERE Product_Name__c = 'STT-GS-006' AND Order.Recordtype.Name = 'CA Sales Order' AND Order.Status = 'Closed' AND Order.AccountId IN : g6ProdOnBoardAccnts ORDER BY Order.AccountId, Order.Createddate DESC LIMIT 1])
{
system.debug('***FOUND ORDER WITH STT-GS-006');
String madeupString = oi.Order.Id + '|' + oi.Order.Shipping_Method__c;
accntToG6XmerOrderMap.put(oi.Order.AccountId, madeupString);
}
*/
            }
            //If involvesG6ReorderReminder = true then process below logic
            if(!g6ReordRemindAccnts.isEmpty())
            {
                system.debug('***ENTERED THE LOGIC FOR involvesG6ReorderReminder');
                for (Account accnt : [SELECT Id,
                                      (SELECT Id, Shipping_Method__c FROM Orders WHERE Count_Of_Starter_Kit__c > 0 AND Status = 'Closed' AND Recordtype.Name = 'CA Sales Order' ORDER BY Createddate DESC LIMIT 1)
                                      FROM Account WHERE Id IN : g6ReordRemindAccnts])
                {
                    List<Order> ordList = accnt.Orders;
                    //Find if there are any orders and then proceed
                    if(!ordList.isEmpty()){
                        String madeupString = ordList[0].Id + '|' + ordList[0].Shipping_Method__c;
                        accntToG6StarterKitOrderMap.put(accnt.Id, madeupString);
                    }
                }
                /*
for(OrderItem oi : [SELECT Id, Order.Id, Order.AccountId, Order.Shipping_Method__c FROM OrderItem WHERE Order.AccountId IN : g6ReordRemindAccnts AND Product_Name__c = 'CASTARTERKITG6' AND Order.Recordtype.Name = 'CA Sales Order' AND Order.Status = 'Closed' ORDER BY Order.AccountId, Order.Createddate DESC LIMIT 1])
{
system.debug('***FOUND ORDER WITH CASTARTERKITG6');
String madeupString = oi.Order.Id + '|' + oi.Order.Shipping_Method__c;
accntToG6StarterKitOrderMap.put(oi.Order.AccountId, madeupString);
}*/
            }
            //Prepare the required sets required for analysis	
            for(String str : accountsToProcessForMIsSet)
            {
                List<String> accntIdToTypeList = str.split('\\|');
                Id accntId = accntIdToTypeList[0];
                //Check if the communication type is CA - Product Onboarding - G6 and equivalent MI doesn't exist before then proceed
                if(accntIdToTypeList[1] == 'CA - Product Onboarding - G6' && !caG6ProductOnboardingSet.contains(accntId) && !accntToG6XmerOrderMap.isEmpty())
                {
                    if(accntToG6XmerOrderMap.containsKey(accntId)){
                        system.debug('***PROCESING CA - Product Onboarding - G6');
                        //Get reference to the latest Xmer order to pass in the order information in the MI
                        String miReferenceFields = accntToG6XmerOrderMap.get(accntId);
                        List<String> g6XmerOrderRefValues = miReferenceFields.split('\\|');//This will split the string with the Order Id and its shipping method
                        //Construct information to create the MI
                        newMIsListToBeCreated.add(createMI(accntId, g6XmerOrderRefValues[0], 'CA - Product Onboarding - G6', g6XmerOrderRefValues[1], 'Canada'));
                    }
                }
                //Check if the communication type is CA - Reorder Reminder - G6 Starter Kit and equivalent MI doesn't exist before then proceed
                if(accntIdToTypeList[1] == 'CA - Reorder Reminder - G6 Starter Kit' && !caG6ReorderSet.contains(accntId) && !accntToG6StarterKitOrderMap.isEmpty())
                {
                    if(accntToG6StarterKitOrderMap.containsKey(accntId)){
                        system.debug('***PROCESING CA - Reorder Reminder - G6 Starter Kit');
                        //Get reference to the latest Xmer order to pass in the order information in the MI
                        String miReferenceFields = accntToG6StarterKitOrderMap.get(accntId);
                        List<String> g6StarterKitOrderRefValues = miReferenceFields.split('\\|');//This will split the string with the Order Id and its shipping method
                        //Construct information to create the MI
                        newMIsListToBeCreated.add(createMI(accntId, g6StarterKitOrderRefValues[0], 'CA - Reorder Reminder - G6 Starter Kit', g6StarterKitOrderRefValues[1], 'Canada'));
                    }
                }
                //Check the communication type and make sure there aren't any other interaction exist of the same type for the same account
                if((accntIdToTypeList[1] == 'CA - Customer Onboarding' && !caOnboardingSet.contains(accntId)))
                {
                    system.debug('***PROCESING CA - Customer Onboarding');
                    newMIsListToBeCreated.add(createMI(accntId, accntId, 'CA - Customer Onboarding', null, 'Canada'));
                }
                //For Communication type 'CA - Reorder Reminder - G6 Starter Kit' remove the conversion flag if it is already set	
                if(accntIdToTypeList[1] == 'CA - Reorder Reminder - G6 Starter Kit' && accountsWithG6ConvFlgSet.contains(accntId))
                {
                    system.debug('***SET G6_Starter_Kit_Conversion__c TO FALSE');
                    accntToBeUpdatedWithG6ConvFlag.add(new Account (Id = accntId, G6_Starter_Kit_Conversion__c = false));
                }
                //For the customer who have the Starter Kit order, when a new order is placed, we need to set the conversion flag to exit the journey
                if(accntIdToTypeList[1] == 'CA - Set Converted Flag')
                {
                    system.debug('***SET G6_Starter_Kit_Conversion__c TO TRUE');
                    accntToBeUpdatedWithG6ConvFlag.add(new Account (Id = accntId, G6_Starter_Kit_Conversion__c = true));
                }
            }
        }
        // Insert marketing interaction
        if (newMIsListToBeCreated.size() > 0) {
            system.debug('********Enter process to create new MIs');
            try { insert newMIsListToBeCreated;
                } catch (DmlException de) {
                    system.debug(de);                    
                }
        }
        // Accounts to be updated
        if (accntToBeUpdatedWithG6ConvFlag.size() > 0) {
            system.debug('********Enter process to update with G6 Conversion flag');
            try { update accntToBeUpdatedWithG6ConvFlag;
                } catch (DmlException de) {
                    system.debug(de);                    
                }
        }
    }
    
    //Method to create the Marketing Interaction structure
    private static Marketing_Interaction__c createMI(Id accntId, String sourceRecordId, String communicationType, String relatedInformation, String country)
    {
        Marketing_Interaction__c mi = new Marketing_Interaction__c();               
        mi.Account__c = accntId;
        mi.Source_Record_Id__c = sourceRecordId;
        mi.Communication_Type__c = communicationType;
        mi.Related_Information__c = relatedInformation;	
        mi.Country__c = country;
        return mi;
    }
}