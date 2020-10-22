/****************************************************************************************************************
@Author        : Kumar Navneet
@Date Created    : 4/23/2019
@Description    : Creating class for process builder 
****************************************************************************************************************/

public with Sharing class BPClsOpportunityDE {

    //Sets Opporrunity Stage based on the field values on Opportunity
    public static String UpdateOpportunityStageToOnHoldOrCloseComplete(Map<Id, Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
        
       //Variable and Collection Declarations
        Map<Id, Opportunity> oppsToBeUpdatedMap = new Map<Id, Opportunity>();        
        Map<Id, Order> ordersMap = new Map<Id, Order>();        
        Map<Id, Order> ordsToBeUpdatedMap = new Map<Id, Order>();
        
		//Prepare order map with the order details for the order involved for Processing
        for (Order ordd : [Select opportunityId, id,  Schedule__c, Status from Order where Schedule__c = 1 and Status = 'Draft' and opportunityId in :newOpps.keySet()]) {
            ordersMap.put(ordd.opportunityId, ordd);
        }
        //Loop through all Opportunity records involved in Processing and update the relevant Opportunity and orders records      
        for(Opportunity op: newOpps.values()) {
            Opportunity o = new Opportunity(id=op.id);
            Order ord = new Order();  
            
           // Opportunity stage and orders status are updating when doc collection status change and cashpay true 
           if (op.Doc_Collection_Status__c != oldOpps.get(op.id).Doc_Collection_Status__c /* && op.Cash_Pay__c */&& 
               op.StageName == 'Order Fulfillment' && op.Doc_Collection_Status__c.startsWithIgnoreCase('Pending')) 
           {
               o.StageName = 'On Hold'; 
               oppsToBeUpdatedMap.put(o.Id, o);                 
                if (ordersMap.size() > 0 && ordersMap.get(op.id).Schedule__c == 1 && ordersMap.get(op.id).Status == 'Draft') 
                  {                    
                        ord.id = ordersMap.get(op.id).id; 
                        // ord.Status = 'Activated'; ------- VA Changed on Sept 30, 2020.
                        ord.Status = 'Shipping Hold';
                        ordsToBeUpdatedMap.put(ord.Id, ord);                                                 
                   }
                    
             }
            /* ------ Even Cash Pay Orders are to go through QC Process. Vijay Adusumilli Sept 30, 2020.
              // Opportunity stage and order status are updating when doc collection status change and cashpay false
             if (op.Doc_Collection_Status__c != oldOpps.get(op.id).Doc_Collection_Status__c && !op.Cash_Pay__c && 
               op.StageName == 'Order Fulfillment' && op.Doc_Collection_Status__c.startsWithIgnoreCase('Pending')) 
             {
               o.StageName = 'On Hold'; 
               oppsToBeUpdatedMap.put(o.Id, o);                
                if (ordersMap.size() > 0 && ordersMap.get(op.id).Schedule__c == 1 && ordersMap.get(op.id).Status == 'Draft') 
                  {                    
                        ord.id = ordersMap.get(op.id).id; 
                        ord.Status = 'Shipping Hold';
                        ordsToBeUpdatedMap.put(ord.Id, ord);                                                 
                   }
                    
             }
			*/
               // Opportunity stage and order status are updating when doc collection status change and cashpay true
            if (op.Doc_Collection_Status__c != oldOpps.get(op.id).Doc_Collection_Status__c && op.Cash_Pay__c && 
               (op.StageName == 'Order Fulfillment' || op.StageName == 'On Hold') && !op.Doc_Collection_Status__c.startsWithIgnoreCase('Pending')) 
            {
               o.StageName = 'Closed - Complete';
               oppsToBeUpdatedMap.put(o.Id, o);
               
                    if (ordersMap.size() > 0 && ordersMap.get(op.id).Schedule__c == 1 && ordersMap.get(op.id).Status == 'Draft') 
                     {                    
                        ord.id = ordersMap.get(op.id).id; 
                        ord.Status = 'Activated';
                        ordsToBeUpdatedMap.put(ord.Id, ord);                                                 
                       }
                    
             }
             // Opportunity stage and order status are updating when doc collection status change and cashpay false
             if (op.Doc_Collection_Status__c != oldOpps.get(op.id).Doc_Collection_Status__c && !op.Cash_Pay__c && 
               (op.StageName == 'Order Fulfillment' || op.StageName == 'On Hold') && !op.Doc_Collection_Status__c.startsWithIgnoreCase('Pending')) 
             {
               o.StageName = 'Closed - Complete';
               oppsToBeUpdatedMap.put(o.Id, o);  
               
                    if (ordersMap.size() > 0 && ordersMap.get(op.id).Schedule__c == 1 && ordersMap.get(op.id).Status == 'Draft') 
                     {                    
                        ord.id = ordersMap.get(op.id).id; 
                        ord.Status = 'Shipping Hold';
                        ordsToBeUpdatedMap.put(ord.Id, ord);                                                 
                       }
                    
             }
        }  
       // update opportunity
        if (oppsToBeUpdatedMap.size() > 0) {
            try { update oppsToBeUpdatedMap.values();
                } catch (DmlException de) {
                    system.debug(de);
                    return de.getMessage();
                }
        }
        // update Order   
        if (ordsToBeUpdatedMap.size() > 0) {
            try { update ordsToBeUpdatedMap.values();
                } catch (DmlException de) {
                    system.debug(de);
                    return de.getMessage();
                }
        }
        return 'OK';
    }
    
    //Update Pricebook information on Non-Rejected Quotes when the Pricebook information is changed on the Opportunity
    public static String UpdatePricebooksOnNonRejectedQuotes(Map<Id, Opportunity> newOpps, Map<Id, Opportunity> oldOpps) { 
        
        //Variable and Collection Declarations                    
        Map<Id, Quote> quotesMap = new Map<Id, Quote>();
        MAp<Id, Quote> quoteToBeUpdatedMap = new Map<Id, Quote>();
        
        //Prepare Quote map with the Quote details for the Quote involved for Processing
        for (Quote Quo : [Select opportunityId, id, Status from Quote where Status != 'Rejected' and opportunityId in :newOpps.keySet()]) {
            quotesMap.put(Quo.id, Quo);      
        }        
         //Loop through all Opportunity records involved in Processing and update the relevant quote records      
        for(Opportunity op: newOpps.values()) {
            Opportunity o = new Opportunity(id=op.id);
            Quote Qt = new Quote ();
            // If pricebookid is changed and Count_Of_Non_Rejected_Quotes__c is greater than 0 then update the quote
            if (oldOpps.get(op.id) != Null && op.Pricebook2Id  != oldOpps.get(op.id).Pricebook2Id && op.Count_Of_Non_Rejected_Quotes__c > 0) 
             {                    
                   for(Quote QTFor: quotesMap.values()) { 
                    //Update quotes when quote status is not rejected 
                    if (QTFor.opportunityId == op.id && QTFor.Status != 'Rejected') 
                    { 
                        Qt.id = QTFor.id;                         
                        Qt.Pricebook2Id = op.Pricebook2Id ;                          
                        quoteToBeUpdatedMap.put(Qt.id, Qt);
                    }
                   }
            }
        }     
        // Update Quote
        if (quoteToBeUpdatedMap.size() > 0) {
            try { update quoteToBeUpdatedMap.values();
                } catch (DmlException de) {
                    system.debug(de);
                    return de.getMessage();
                }
        }         
    return 'OK';
    
    }
    
    // Create new Benefit on New Opportunity creation
    public static String CreateBenefitONewOpportunityCreation(Map<Id, Opportunity> newOpps, Map<Id, Opportunity> oldOpps) { 
       
        //Variable and Collection Declarations
        Map<Id, Opportunity> oppsToBeUpdatedMap = new Map<Id, Opportunity>(); 
        Map<Id, Account> accountsMap = new Map<Id, Account>();
        Map<Id, String> recordTypeStore = new Map<Id, string>();
        set<Id> accountIDSet = new set<Id>();
        List<Opportunity> olList = [Select id, recordTypeId, recordType.Developername from Opportunity where Id in : newOpps.keySet()];
        //Prepare the record type map
        for(Opportunity oprr : olList){
            recordTypeStore.put(oprr.recordTypeId, oprr.Recordtype.DeveloperName);
        } 
        //Collect all the account Ids involved for Processing
        for(Opportunity opacID: newOpps.values()) {
            accountIDSet.add(opacID.Accountid);
        }
        //Prepare account map with the account details for the accounts involved for Processing
        for (Account Acc: [Select id, benefit_member_Id__c, benefit_insurant_status__c, benefit_customer_Service_Phone__c, benefit_provider_Service_Phone__c from Account where Id IN : accountIDSet  ]) {
            accountsMap.put(Acc.id, Acc);
        }  
		Id deBenefitRecTypeId = [Select Id from RecordType where isActive = true AND DeveloperName = 'DE_Benefit'].Id;
        //Loop through all Opportunity records involved in Processing and update the relevant Opportunity records and call the flow for benefit creation
        for(Opportunity op: newOpps.values()) {
            Opportunity o = new Opportunity(id=op.id);
            system.debug('Pricebook name = '+op.Price_Book_Name__c);
            // updating Benefit_EGEKO_Kopftext__c when pricebook is 'DE Netto-Preis Cash' and recordtype is DE(germany)
            if(op.Cash_Pay__c != True && op.Price_Book_Name__c =='DE Netto-Preis Cash' && recordTypeStore.get(op.RecordTypeId) == 'DE_Opportunity') 
             {  
                        system.debug('Inside = ') ;
                        o.Benefit_EGEKO_Kopftext__c = 'Bitte beachten Sie die Dexcom Leistungs- und Lieferkonditionen' ;                          
                        oppsToBeUpdatedMap.put(o.Id, o); 
             }      
            system.debug('Parent_opportunity__c  = null ') ;
            // Creating benefit when parent opportunity is null for Germany
               if(op.Parent_opportunity__c == null && recordTypeStore.get(op.RecordTypeId) == 'DE_Opportunity')
               {
                  system.debug('op.id = '+op.id) ;
                  Map<String, Object> params = new Map<String, Object>();
                  params.put('varId', op.id);
                  params.put('accountId', op.AccountId);
                  params.put('payorId', op.payor__c);
                  params.put('memberId', accountsMap.get(op.Accountid).benefit_member_Id__c); 
                  params.put('insurantStatus', accountsMap.get(op.Accountid).benefit_insurant_status__c);
                  params.put('customerServicePhone', accountsMap.get(op.Accountid).benefit_customer_Service_Phone__c);
                  params.put('providerServicePhone', accountsMap.get(op.Accountid).benefit_provider_Service_Phone__c );
                  params.put('rxWrittenDate', op.rx_date_Written__c);
                  params.put('kopftext', op.benefit_EGEKO_kopftext__c);
                  params.put('recTypeId', deBenefitRecTypeId);    // Adding this as we have different Benefit Types. Vijay 07/30/2019.
                  system.debug('params  = '+ params) ;
                  Flow.Interview.Create_And_Associate_Benefit_On_New_Opportunity_Creation OFlow = new Flow.Interview.Create_And_Associate_Benefit_On_New_Opportunity_Creation(params);
                  OFlow.start();
               }             
        }        
        // Update opportunity 
        if (oppsToBeUpdatedMap.size() > 0) {
            try { update oppsToBeUpdatedMap.values();
                } catch (DmlException de) {
                    system.debug(de);
                    return de.getMessage();
                }
        }         
    return 'OK';    
    }
    
    // Mocking Marketing Cloud to send out emails based on Stage changes.
     public static String MCOpportunityEmails(Map<Id, Opportunity> newOpps, Map<Id, Opportunity> oldOpps, String aftInsertFlag) { 
       //Variable and Collection Declarations
        Map<Id, Opportunity> mapOpportunity = new Map<Id, Opportunity>([SELECT Id, Payor__r.Name, (SELECT Id FROM Orders LIMIT 1) FROM Opportunity WHERE Id IN: newOpps.keySet()]);//added by Shailendra on 28/JAN/2020..
        Map<Id, Opportunity> oppsToBeUpdatedMap = new Map<Id, Opportunity>(); 
        List<Task> tskList = new List<Task>();
        Map<Id, Account> accountsMap = new Map<Id, Account>();
        set<Id> accountIDSet = new set<Id>(); 
        Map<String, EmailTemplate> emailTempMap = new Map<String, EmailTemplate>();
        List<OrgWideEmailAddress> owa = [select id, Address, DisplayName from OrgWideEmailAddress];
         //Fetching email template
        List<EmailTemplate> emailTempList = [SELECT Id, name, Body, Subject from EmailTemplate where Name = 'Stage3-moving_out_of_Cost_Estimate' or name= 'Stage1-moving_out_of_New_Opportunity' ];
        for(EmailTemplate ETemp: emailTempList) {
            emailTempMap.put(ETemp.name, ETemp);
        }              
         
        //Collect all the account Ids involved for Processing 
        for(Opportunity opacID: newOpps.values()) {
            accountIDSet.add(opacID.Accountid);
        }
       //Prepare account map with the account details for the accounts involved for Processing
        for (Account Acc: [Select id, PersonEmail, PersonHasOptedOutOfEmail , PersonContactid, firstname, Lastname from Account where Id IN : accountIDSet  ]) {
            accountsMap.put(Acc.id, Acc);
        }   
       //Loop through all Opportunity records involved in Processing and update the relevant Opportunity and Creating Task       
        for(Opportunity op: newOpps.values()) {
            Opportunity o = new Opportunity(id=op.id);
            //Do not enter the block if Opp is with Cash Payor or Cash Pay flag
            if(mapOpportunity.get(op.Id).Payor__r.Name != 'CASH PAYOR' && !op.Cash_Pay__c )
            {
                Task Ta = new Task();  
                // updating opportunity's consumer email with account's personemail if its get mismatch
                if(accountsMap.get(op.Accountid).PersonEmail != op.Consumer_Email__c ) 
                {                              
                            system.debug('MCOPP .') ;   
                            o.Consumer_Email__c = accountsMap.get(op.Accountid).PersonEmail ;                          
                            oppsToBeUpdatedMap.put(o.Id, o);                                                                  
                }   
                // Sending mail and creating Task
                if( aftInsertFlag == 'True' && op.DexTracker_Email__c == 'Yes' 
                && accountsMap.get(op.Accountid).PersonHasOptedOutOfEmail != True 
                && accountsMap.get(op.Accountid).PersonEmail != '' && accountsMap.get(op.Accountid).PersonEmail != null && op.Email_Stage__c == null  ) 
                {             
                        system.debug('MCOPP if emailstagenull .') ;                  
                            // Stage1_moving_out_of_New_Opportunity;                        
                        //  List<EmailTemplate> lstEmailTemplates = [SELECT Id, name, Body, Subject from EmailTemplate where Name = 'Stage1-moving_out_of_New_Opportunity'];
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setTemplateId(emailTempMap.get('Stage1-moving_out_of_New_Opportunity').Id);
                        mail.setSaveAsActivity(false);
                        List<String> Tomail = new list<string>();                      
                        Tomail.add(accountsMap.get(op.Accountid).PersonEmail);                      
                        for(OrgWideEmailAddress OWDmail : owa) {
                            if(OWDmail.Address.contains('de.info@dexcom.com')) 
                            mail.setOrgWideEmailAddressId(OWDmail.id); }
                        mail.setTargetObjectId(accountsMap.get(op.Accountid).PersonContactid);
                        Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                            
                            Ta.ActivityDate = Date.Today() ;     
                            Ta.Description = 'Sehr geehrte/r Herr / Frau) " & ' +accountsMap.get(op.Accountid).FirstName + ' & " " & ' +accountsMap.get(op.Accountid).LastName+ ' & " , " &  "----" & "vielen herzlichen Dank, dass Sie sich für unsere Dexcom rtCGM-Produkte entschieden haben." & "----" & "Wir haben Ihr Rezept über eine Folgeversorgung dankend erhalten. Wir werden Ihr Rezept schnellstmöglich bearbeiten." & "----" & Mit freundlichen Grüßen," & "----" & "Ihr Dexcom Deutschland Team' ; 
                            Ta.priority = 'Normal' ; 
                            Ta.Status = 'Completed' ;                         
                            Ta.Subject = 'Dexcom Deutschland informiert: Ihr Rezept ist bei uns eingetroffen' ; 
                            Ta.Type = 'Dextracker Email' ;                                     
                            Ta.WhoId = accountsMap.get(op.Accountid).PersonContactid ; 
                            Ta.WhatId = op.Id ;  
                            tskList.add(Ta) ;                         
                }
                // updating email stage
                if(aftInsertFlag == 'True' ) 
                {                                  
                    o.Email_Stage__c = 1 ; 
                    oppsToBeUpdatedMap.put(o.Id, o);                                                                  
                }
                else{
                // updating email stage, creating task and sending mail to account personmail
                if(mapOpportunity.get(op.Id).Orders.isEmpty() && (op.EGEKO_out__c == True || op.Hard_copy_out__c == True) && op.Consumer_Email__c != Null 
                && accountsMap.get(op.Accountid).PersonHasoptedoutofEmail != True && op.Email_Stage__c == 1
                && op.DexTracker_Email__c == 'Yes' && accountsMap.get(op.Accountid).PersonEmail != '' && accountsMap.get(op.Accountid).PersonEmail != null && op.Email_Stage__c != null && 
                (op.Type == 'Reorder' || op.Type == 'New')) 
                {
                        //Stage3_moving_out_of_Cost_Estimate                    
                        // List<EmailTemplate> lstEmailTemplates = [SELECT Id, name, Body, Subject from EmailTemplate where Name = 'Stage3-moving_out_of_Cost_Estimate'];
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setTemplateId(emailTempMap.get('Stage3-moving_out_of_Cost_Estimate').Id);
                        mail.setSaveAsActivity(false);
                        List<String> Tomail = new list<string>();
                        Tomail.add(accountsMap.get(op.Accountid).PersonEmail);
                        mail.setToAddresses(Tomail);
                        mail.setTargetObjectId(accountsMap.get(op.Accountid).PersonContactid);
                        for(OrgWideEmailAddress OWDmail : owa) {
                        if(OWDmail.Address.contains('de.info@dexcom.com')) 
                            mail.setOrgWideEmailAddressId(OWDmail.id); }
                        Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                            
                            o.Email_Stage__c = 2 ;                        
                            Ta.ActivityDate = Date.Today() ;     
                            Ta.Description = 'Sehr geehrte/r Herr / Frau) " & ' +accountsMap.get(op.Accountid).FirstName + ' & " " & ' +accountsMap.get(op.Accountid).LastName+ ' & " , " &  "----" & "wir haben Ihr Rezept zusammen mit einem Kostenvoranschlag bei Ihrer Krankenkasse zur Genehmigung eingereicht. Bitte beachten Sie, dass die Bearbeitungszeit für Rezepte über alle Beteiligten (Kostenträger, MDK, Leistungserbringer) bis zu 4 Wochen in Anspruch nehmen kann." & "----" & "Bitte wenden Sie sich für Informationen zum Bearbeitungsstand direkt an Ihre Krankenkasse." & "----" & Mit freundlichen Grüßen," & "----" & "Ihr Dexcom Deutschland Team' ; 
                        
                            Ta.priority = 'Normal' ; 
                            Ta.Status = 'Completed' ;                         
                            Ta.Subject = 'Dexcom Deutschland informiert: Ihr Rezept ist in Bearbeitung' ; 
                            Ta.Type = 'Dextracker Email' ; 
                            Ta.WhatId = op.Id ;                                     
                            Ta.WhoId = accountsMap.get(op.Accountid).PersonContactid ; 
                            
                            oppsToBeUpdatedMap.put(o.Id, o); 
                            tskList.add(Ta) ;              
                }
                else{
                    
                    //Updating email stage when type is reorder , EGEKO_out__c or Hard_copy_out__c is true 
                        if(op.Type == 'Reorder' && (op.EGEKO_out__c == True || op.Hard_copy_out__c == True) 
                        && op.Email_Stage__c != 2 && op.Email_Stage__c != Null)
                        {
                        o.Email_Stage__c = 2 ;
                        oppsToBeUpdatedMap.put(o.Id, o);                     
                        }               
                }
                }                
            }
        } 
        // Insert Task
        if (tskList.size() > 0) {
            try { insert tskList;
                } catch (DmlException de) {
                    system.debug(de);
                    return de.getMessage();
                }
        }  
        // Update opportunity         
        if (oppsToBeUpdatedMap.size() > 0) {
        try { update oppsToBeUpdatedMap.values();
            } catch (DmlException de) {
                system.debug(de);
                return de.getMessage();
            }
        }      
        return 'OK';    
    }
    
    // Method handles Cash Pay flag setting, Training Date, Contact Doc and Cancel Reason logic.
    public static String UpdateOpportunityDataUponEditing(Map<Id, Opportunity> newOpps, Map<Id, Opportunity> oldOpps, String aftInsertFlag) { 
      
        //Variable and Collection Declarations 
        Datetime CDate = Datetime.newInstance(2018, 3, 27, 3, 30, 0);       
        set<Id> accountIDSet = new set<Id>();
        Map<Id, Account> accountsToBeUpdatedMap = new Map<Id, Account>();  
        Map<Id, Opportunity> oppsToBeUpdatedMap = new Map<Id, Opportunity>();
        Map<Id, Benefit__c> benefitsMap= new Map<Id, Benefit__c>();
      //  Map<Id, String> recordTypeStore = new Map<Id, string>();
        Map<Id, Account> accountsMap = new Map<Id, Account>();
        List<Benefit__c> updBenList = new List<Benefit__c>();
        List<Opportunity> insertoppsList = new List<Opportunity>();           
        List<Opportunity> olList = [Select id, recordTypeId, recordType.Developername from Opportunity where Id in : newOpps.keySet()];
        List<Pricebook2> Prbk = new List<Pricebook2>([SELECT Id FROM Pricebook2 where Name = 'DE Netto-Preis Cash' limit 1]);  
        List<Account> Aco = new List<Account>([SELECT Id FROM account where Name = 'CASH PAYOR' limit 1 ]);
        String Acccash = '';
        String pb = '';
        if (Prbk.size() > 0) pb = Prbk[0].id ;
        if (Aco.size() > 0) Acccash = Aco[0].Id ;       
        //Collect all the account Ids involved for Processing
        for(Opportunity opacID: newOpps.values()) {
            accountIDSet.add(opacID.Accountid);
        }
        //Prepare account map with the account details for the accounts involved for Processing
        for (Account Acc: [Select id, Firstname, Lastname, Territory__c, Consent_From_Patient_data__c , Training_date__c, Payor__r.Price_book__c, Payor__c from Account where Id IN : accountIDSet ]) {
            accountsMap.put(Acc.id, Acc);
        } 
        //Prepare the record type map
       // for(Opportunity oprr : olList){
       //     recordTypeStore.put(oprr.recordTypeId, oprr.Recordtype.DeveloperName);
       // }   
        //Prepare the map to look at Benefits tied to the accounts involved for Processing
        for (Benefit__c Ben: [Select id from Benefit__c where Account__c in : accountsMap.keySet()  ]) {
            benefitsMap.put(Ben.id, Ben);
        } 
        //Loop through all Opportunity records involved in Processing and update the relevant Opportunity, Account and Benefit records
        for(Opportunity op: newOpps.values()) {
            Opportunity o = new Opportunity(id=op.id);            
            Opportunity inso = new Opportunity(); 
               Account Ac = new Account(); 
               Ac.id = accountsMap.get(op.Accountid).id; 
               Benefit__c OPPben = new Benefit__c(); 
               If(op.Benefit__c != null)
                 OPPben.id = benefitsMap.get(op.Benefit__c).id; 
               
               system.debug('Count_Of_Opportunity_Products__c=' +op.Count_Of_Opportunity_Products__c );
              //  system.debug('recordtype.developername =' +recordTypeStore.get(op.RecordTypeId));
              //Clear out Opportunity Products when the Opportunity is updated to Cash Pay
               if(aftInsertFlag == 'False' && op.Count_Of_Opportunity_Products__c > 0 && op.Cash_pay__c != oldOpps.get(op.id).Cash_pay__c &&  op.Cash_pay__c != false)
               {
                  system.debug('Matched 1 condtion' +op.Count_Of_Opportunity_Products__c );
                  Map<String, Object> params = new Map<String, Object>();
                  params.put('varOpptyId', op.id);
                  Flow.Interview.Clear_Opportunity_Product_For_Cash_Pay OFlow = new Flow.Interview.Clear_Opportunity_Product_For_Cash_Pay(params);
                  OFlow.start();
               } 
                //If the Opportunity is associated to Cash Pay then associate the CASH PAYOR and Cash Pricebook to the Opp
                if(aftInsertFlag == 'False' && op.Cash_pay__c != oldOpps.get(op.id).Cash_pay__c &&  op.Cash_pay__c != false)
               {
                     system.debug('Matched 2 condtion'  );
                      if(pb != '')
                      o.Pricebook2Id = pb ;
                   if(Acccash != '')
                      o.Payor__c = Acccash ; 
                      oppsToBeUpdatedMap.put(o.Id, o);  
               }
             //If Opportunity training date changed then update the account's training date field value 
               if(aftInsertFlag == 'False' && op.Training_date__c != oldOpps.get(op.id).Training_date__c)
               {  
                   system.debug('Matched 3 condtion'  );                
                   Ac.Training_date__c = op.Training_date__c;
                   accountsToBeUpdatedMap.put(Ac.Id, Ac); 
               }
            //If Opportunity training confirmation channel is changed then update the account's training received value
                if(aftInsertFlag == 'False' && op.Training_confirmation_channel__c != oldOpps.get(op.id).Training_confirmation_channel__c)
               {
                 system.debug('Matched 4 condtion'  );  
                  Ac.Training_Received__c = op.Training_confirmation_channel__c ;
                  accountsToBeUpdatedMap.put(Ac.Id, Ac);
               }
               //If Opportunity customer doc received is changed then update the account's Consent from patient data value
               if(aftInsertFlag == 'False' && op.Contact_Doc_received__c != oldOpps.get(op.id).Contact_Doc_received__c )
               {
                  system.debug('Matched 5 condtion'  );  
                  Ac.Consent_From_Patient_data__c = op.Contact_Doc_received__c ;
                  accountsToBeUpdatedMap.put(Ac.Id, Ac);
               }
              //If Opportunity stage isn't cancelled and Cancel Reason is filled in then the value need to be cleared. Cancel Reason is applicable only for Cancelled Opp
               if(aftInsertFlag == 'False' && op.Cancel_reason__c != Null && op.Stagename != oldOpps.get(op.id).Stagename  &&  op.Stagename != 'Cancelled')
               {
                 system.debug('Matched 6 condtion'  );  
                  o.Cancel_reason__c = Null; 
                  oppsToBeUpdatedMap.put(o.Id, o);
               }
               //When a Reorder Opp is created then stage = Customer Doc Collection, Customer Doc Received and Contact Letter Sent should get value from Account's Consent from patient data		          
               if(aftInsertFlag == 'True' &&  op.Type == 'Reorder')
               {
                  system.debug('Matched 7 condtion'  );                                      
                  o.Stagename = 'Customer Doc Collection'; 
                  o.Contact_Doc_Received__c = accountsMap.get(op.Accountid).Consent_From_Patient_data__c ;
                  o.Contact_Letter_Sent__c = accountsMap.get(op.Accountid).Consent_From_Patient_data__c ;
                  oppsToBeUpdatedMap.put(o.Id, o);                  
               } 
             //When a new Opp is created then mark the Dextracker email to Yes
               if(aftInsertFlag == 'True' && op.Type == 'New')
               {
                 system.debug('Matched 8 condtion'  );        
                  o.DexTracker_Email__c = 'Yes';
                  oppsToBeUpdatedMap.put(o.Id, o);
                  
               }   
             //When any Benefit info changes on Opp update the Benefit accordingly
               if( aftInsertFlag == 'False' && OPPben.id != null &&  (op.benefit_coverage__c != oldOpps.get(op.id).benefit_coverage__c 
               || op.benefit_Auth_start_date__c != oldOpps.get(op.id).benefit_Auth_start_date__c 
               || op.benefit_Auth_end_date__c != oldOpps.get(op.id).benefit_Auth_end_date__c 
               || op.benefit_Authorization_number__c != oldOpps.get(op.id).benefit_Authorization_number__c 
               || op.benefit_Co_pay__c != oldOpps.get(op.id).benefit_Co_pay__c 
               || op.benefit_EGEKO_Effective_date__c != oldOpps.get(op.id).benefit_EGEKO_Effective_date__c 
               || op.benefit_EGEKO_kopftext__c != oldOpps.get(op.id).benefit_EGEKO_kopftext__c                 
               || op.benefit_prior_auth_denied_or_approved__c != oldOpps.get(op.id).benefit_prior_auth_denied_or_approved__c 
               || op.Rx_date_written__c != oldOpps.get(op.id).Rx_date_written__c )
               && op.Createddate >= CDate )           
               {
                  system.debug('Matched 9 condtion'  ); 
                 
                  OPPben.Auth_End_Date__c = op.benefit_Auth_end_date__c ;
                  OPPben.Auth_start_date__c =  op.benefit_Auth_start_date__c ; 
                  OPPben.Authorization_number__c =  op.benefit_Authorization_number__c ;                 
                  OPPben.Co_pay__c =  op.benefit_Co_pay__c ;                  
                  OPPben.coverage__c = op.benefit_coverage__c ;                  
                  OPPben.Effective_Date__c =  op.benefit_EGEKO_Effective_date__c ;                  
                  OPPben.EGEKO_kopftext__c =  op.benefit_EGEKO_kopftext__c ;
                  OPPben.Rx_date_written__c =  op.Rx_date_written__c ;                 
                  OPPben.Prior_Auth_Denied_or_Approved__c =  op.benefit_prior_auth_denied_or_approved__c ;  
                  updBenList.add(OPPben);                 
               }            
		   //At the time of cancelling the opp when the user wants to create a new Opp then below logic will be executed
               if(aftInsertFlag == 'False' && op.Stagename != oldOpps.get(op.id).Stagename  &&  op.Stagename == 'Cancelled' && op.Create_New_Opportunity__c == true )
               {
                  system.debug('Matched 10 condtion'  );  
                  inso.CloseDate = Date.Today() + 30; 
                  inso.name =  accountsMap.get(op.Accountid).Firstname +' '+ accountsMap.get(op.Accountid).Lastname +'-'+ accountsMap.get(op.Accountid).Territory__c+'-'+Date.Today().day()+'-'+Date.Today().month()+'-'+Date.Today().year(); 
                  inso.Stagename = 'New Opportunity'; 
                  inso.AccountID= op.AccountId ;  
                  inso.benefit_Auth_end_date__c = op.benefit_Auth_end_date__c ;  
                  inso.benefit_Auth_start_date__c = op.benefit_Auth_start_date__c ;                  
                  inso.benefit_Authorization_number__c = op.benefit_Authorization_number__c ;  
                  inso.benefit_Co_pay__c = op.benefit_Co_pay__c ; 
                  inso.benefit_coverage__c = op.benefit_coverage__c ;  
                  inso.benefit_EGEKO_Effective_date__c = op.benefit_EGEKO_Effective_date__c ;                  
                  inso.benefit_EGEKO_kopftext__c = op.benefit_EGEKO_kopftext__c ;  
                  inso.benefit_prior_auth_denied_or_approved__c  = op.benefit_prior_auth_denied_or_approved__c ; 
                  inso.benefit__c = op.benefit__c ;  
                  inso.Cash_pay__c = op.Cash_pay__c ;                  
                  inso.DexTracker_email__c = op.DexTracker_email__c ;  
                  inso.ForecastCategoryName = 'Pipeline'; 
                  inso.Medical_Facility__c = op.Medical_Facility__c ;  
                  inso.Parent_Opportunity__c = op.Id ;                  
                  inso.Payor__c = accountsMap.get(op.Accountid).Payor__c;  
                  inso.Prescriber__c = op.Prescriber__c ;                                    
                  inso.Pricebook2Id = accountsMap.get(op.Accountid).Payor__r.Price_book__c ;    
                  inso.Rx_date_Received__c = op.Rx_date_Received__c ;                  
                  inso.Rx_date_written__c = op.Rx_date_written__c ;  
                  inso.type = op.type ; 
                  insertoppsList.add(inso);                   
               }                                                
        }   
       //Insert Opps
        if (insertoppsList.size() > 0) {
            try { insert insertoppsList;
                } catch (DmlException de) {
                    system.debug(de);
                    return de.getMessage();
                }
        } 
        //Update Accounts
        if (accountsToBeUpdatedMap.size() > 0) {
            try { update accountsToBeUpdatedMap.values();
                } catch (DmlException de) {
                    system.debug(de);
                    return de.getMessage();
                }
        } 
         //Update Benefits
        if (updBenList.size() > 0) {
            try { update updBenList;
                } catch (DmlException de) {
                    system.debug(de);
                    return de.getMessage();
                }
        } 
        //Udate Opps
        system.debug('oppsToBeUpdatedMap.size()= '+oppsToBeUpdatedMap.size());           
        if (oppsToBeUpdatedMap.size() > 0) {
            try { update oppsToBeUpdatedMap.values();
                } catch (DmlException de) {
                    system.debug(de);
                    return de.getMessage();
                }
        }         
    return 'OK';    
    }
    
}