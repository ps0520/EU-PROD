/**********************************************************************
@Description    : Class will dispatch Country specific handling
***********************************************************************/

public class ClsOpportunityBPHandler {

  	public static void beforeInsertHandler(List<Opportunity> newOppsList) {

		//Collections to hold records for Processing
		List<Opportunity> deNewOppsList = new List<Opportunity>();
		List<Opportunity> caNewOppsList = new List<Opportunity>();
		List<Opportunity> chNewOppsList = new List<Opportunity>();
        List<Opportunity> atNewOppsList = new List<Opportunity>();
		List<Opportunity> gbNewOppsList = new List<Opportunity>();
		List<Opportunity> ieNewOppsList = new List<Opportunity>();
		

		//Get all the Opp record type Ids
		Id caOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CA_Opportunity').getRecordTypeId();
		Id deOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DE_Opportunity').getRecordTypeId();
		Id chOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CH_Opportunity').getRecordTypeId();
		Id atOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('AT_Opportunity').getRecordTypeId();
		Id gbOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('GB_Opportunity').getRecordTypeId();
		Id ieOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('IE_Opportunity').getRecordTypeId();

		//Get the Price book Information
		Map<Id, Pricebook2> chPricebookMap = new Map<Id, Pricebook2>([Select ID, IsSubscription__c from Pricebook2 where Name like 'CH%']);
        List<PriceBook2> starterKits = [Select ID, Name from Pricebook2 where Name like '%Starter%' AND IsSubscription__c = true];
      	Id gbStarterKitId;
        Id ieStarterKitId;
      for(PriceBook2 pb : starterKits) {
          if (pb.Name.startsWithIgnoreCase('UK')) gbStarterKitId = pb.Id;
          if (pb.Name.startsWithIgnoreCase('IE')) ieStarterKitId = pb.Id;
      }
		
		//Adding Opp records in list for specific country
        for(Opportunity o : newOppsList){
            //Process CA Logic
			if (o.RecordTypeId == caOppRecordtypeId ){
                o.CurrencyIsoCode = 'CAD';
                caNewOppsList.add(o);
            }
			//Process GB Logic
			else if (o.RecordTypeId == gbOppRecordtypeId ){
                o.CurrencyIsoCode = 'GBP';
                gbNewOppsList.add(o);
                if(o.Created_From_Lead__c) o.Pricebook2Id = gbStarterKitId;
            }
			//Procss DE Logic
            else if (o.RecordTypeId == deOppRecordtypeId ) deNewOppsList.add(o);
			//Process CH Logic
			else if (o.RecordTypeId == chOppRecordtypeId ){ 
				if(o.Type == 'Subscription' && o.Pricebook2Id != null){
					//Validate the Price book chosen is of SSIP type or not. If not raise error and return
					if(chPricebookMap.get(o.Pricebook2Id) == null  || chPricebookMap.get(o.Pricebook2Id).IsSubscription__c == false){
						o.addError('Please choose a valid Subscription Pricebook as Opportunity is of type \'Subscription\'.');
						return;                              
					}
				}else if((o.Type == 'New' || o.Type == 'Reorder') && o.Pricebook2Id != null ){
					//Validate the Price book chosen is Not of SSIP type. If not raise error and return
					 if(chPricebookMap.get(o.Pricebook2Id) == null  || chPricebookMap.get(o.Pricebook2Id).IsSubscription__c == true){
						o.addError('Subscription Pricebook can only be chosen for \'Subscription\' Opportunity type.');
						return;                              
					  }
				}
				o.CurrencyIsoCode = 'CHF';
				chNewOppsList.add(o);
			}
			else if (o.RecordTypeId == atOppRecordtypeId ) atNewOppsList.add(o);
            //Process IE Logic
            else if (o.RecordTypeId == ieOppRecordtypeId ) {
				o.CurrencyIsoCode = 'EUR';				
                ieNewOppsList.add(o);
                if(o.Created_From_Lead__c) o.Pricebook2Id = ieStarterKitId;
            }
        }
        //Country dispatcher
		if (deNewOppsList.size() > 0){ 
			ClsOpportunityTriggerHandler.OpportunityOwnerupdate(deNewOppsList, 'DE'); 
		}
        
        if (caNewOppsList.size() > 0){
            ClsOpportunityTriggerHandler.OpportunityOwnerupdate(caNewOppsList, 'CA'); 
            ClsCAOpportunityTriggerHandler.setBenfitAndPayor(caNewOppsList);
        }
		if (chNewOppsList.size() > 0) ClsOpportunityTriggerHandler.OpportunityOwnerupdate(chNewOppsList, 'CH'); 
		if (atNewOppsList.size() > 0) ClsOpportunityTriggerHandler.OpportunityOwnerupdate(atNewOppsList, 'AT'); 
		if (gbNewOppsList.size() > 0) ClsOpportunityTriggerHandler.OpportunityOwnerupdate(gbNewOppsList, 'GB'); 
		if (ieNewOppsList.size() > 0) ClsOpportunityTriggerHandler.OpportunityOwnerupdate(ieNewOppsList, 'IE'); 
    }

    public static void beforeUpdateHandler(List<Opportunity> newOppsList, Map<Id, Opportunity> oldOppsMap) {
        
		//Collections to hold records for Processing       
        List<Opportunity> deNewOppsList = new List<Opportunity>();
        List<Opportunity> caNewOppsList = new List<Opportunity>();
		List<Opportunity> chNewOppsList = new List<Opportunity>();
        List<Opportunity> atNewOppsList = new List<Opportunity>();  
        List<Opportunity> gbNewOppsList = new List<Opportunity>();  
        List<Opportunity> ieNewOppsList = new List<Opportunity>();  
		
		//Get all the Opp record type Ids
        Id caOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CA_Opportunity').getRecordTypeId();
		Id deOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DE_Opportunity').getRecordTypeId();
		Id chOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CH_Opportunity').getRecordTypeId();
		Id atOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('AT_Opportunity').getRecordTypeId();
		List<Id> OppCAId = new List<Id>();
        Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity>();
        
        for(Opportunity o : newOppsList) {
            if (o.RecordTypeId == caOppRecordtypeId ) {
                OppCAId.add(o.id);
            }
        }
        for(Opportunity oppty : [SELECT Id, Payor__r.Subscription_Price_Book__c, Payor__r.Price_Book__c FROM Opportunity WHERE Id IN : OppCAId])
        {
            opptyMap.put(oppty.Id, oppty);
        }
        
        // Adding records in list for specific country
        for(Opportunity o : newOppsList) {
            
            // update closed reason and CloseDate - NS-1025
           if(o.StageName != null && o.StageName != oldOppsMap.get(o.Id).StageName && (o.StageName == 'Closed - Complete' || o.StageName == 'Cancelled')){
                if(o.CA_Closed_Reason__c == ''){
                    o.CA_Closed_Reason__c = 'Manual Order Entry';
               }
                o.CloseDate = system.today() ; 
            }
            
            if (o.RecordTypeId == caOppRecordtypeId ) {
                if (o.Benefit__c != oldOppsMap.get(o.Id).Benefit__c)  caNewOppsList.add(o);
                //Reason for following is that if Fund is to be used for Order, ECOM does not support it. Similarly if there are multiple Orders involved, SSIP Rules need to be created.
                if (o.StageName == 'Order Fulfillment' && oldOppsMap.get(o.Id).StageName != 'Order Fulfillment' &&  (o.Create_Fund__c == TRUE || o.Number_of_Approved_Orders__c > 1) && o.Ordering_Process__c != 'Local') o.Ordering_Process__c = 'Payor'; 
                if (o.StageName == 'Order Fulfillment' && oldOppsMap.get(o.Id).StageName != 'Order Fulfillment' && o.Number_of_Approved_Orders__c > 1 && o.Pricebook2Id == null) o.Pricebook2Id = opptyMap.get(o.id).Payor__r.Subscription_Price_Book__c; 
                if (o.StageName == 'Order Fulfillment' && oldOppsMap.get(o.Id).StageName != 'Order Fulfillment' && o.Create_Fund__c == TRUE && (o.Number_of_Approved_Orders__c == 1 || o.Number_of_Approved_Orders__c == null) && o.Pricebook2Id == null) o.Pricebook2Id = opptyMap.get(o.id).Payor__r.Price_Book__c;
                if (o.StageName == 'Order Fulfillment' && oldOppsMap.get(o.Id).StageName != 'Order Fulfillment' && o.Ordering_Process__c == 'Local' && o.Pricebook2Id == null) { o.addError('You need to specify a price book and optionally products before creating an Order'); return; }
                if (o.StageName == 'Order Fulfillment' && oldOppsMap.get(o.Id).StageName != 'Order Fulfillment' && o.Ordering_Process__c == 'Payor' && o.Pricebook2Id == null) {
                	if (opptyMap.get(o.Id).Payor__r.Price_Book__c == null) {
                        o.addError('No price book is assoicated to the Payor and no price book is set on the Opportunity. You can\'t create a Payor Order.'); return; 
                    }  else o.Pricebook2Id = opptyMap.get(o.Id).Payor__r.Price_Book__c; 
                }             
            }
            else if (o.RecordTypeId == deOppRecordtypeId ) deNewOppsList.add(o);
        }
        // if (caOppPriceBookChanged.size() > 0) ClsSSIPUtilities.processSubscriptionOpportunityProductCreation(caOppPriceBookChanged);

        //Country dispatcher
        if (caNewOppsList.size() > 0) {
            //ClsOpportunityTriggerHandler.OpportunityOwnerupdate(caNewOppsList, 'CA'); 

            //ClsOpportunityTriggerHandler.OpportunityOwnerupdate(caNewOppsList, 'CA'); 
            ClsCAOpportunityTriggerHandler.setBenfitAndPayor(caNewOppsList);
        }
		if (chNewOppsList.size() > 0) {}
        if (atNewOppsList.size() > 0) {}
    }

    public static void afterInsertHandler(List<Opportunity> newOppsList, Map<Id, Opportunity> newOppsMap, Map<Id, Opportunity> oldOppsMap) {
        system.debug('afterInsertHandler');
        String AftInsertFlag = 'True';
        //Collections to hold records for Processing  
        Map<Id, Opportunity> deNewOppsMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> deOldOppsMap = new Map<Id, Opportunity>();
		Map<Id, Opportunity> caNewOppsMap = new Map<Id, Opportunity>();
		Map<Id, Opportunity> mapDocuSignOpp= new Map<Id, Opportunity>();
        List<Opportunity> deNewOppsList = new List<Opportunity>();
        List<Opportunity> caNewOppsList = new List<Opportunity>();
		List<Opportunity> chNewOppsList = new List<Opportunity>();
        List<Opportunity> atNewOppsList = new List<Opportunity>();  
        List<Opportunity> gbNewOppsList = new List<Opportunity>();  
        List<Opportunity> ieNewOppsList = new List<Opportunity>();  

        //Get all the Opp record type Ids
        Id caOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CA_Opportunity').getRecordTypeId();
		Id deOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DE_Opportunity').getRecordTypeId();
		Id chOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CH_Opportunity').getRecordTypeId();
		Id atOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('AT_Opportunity').getRecordTypeId();
		Id gbOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('GB_Opportunity').getRecordTypeId();
		Id ieOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('IE_Opportunity').getRecordTypeId();
        system.debug('**newOppsMap'+newOppsMap);
        //Added by Pravin - Document tracker Functionality --25 June 2020 --
        // ClsCADocumentTrackerHandler.afterOpportunityInsert(newOppsMap);
        //Added by Pravin - Document tracker Functionality Ended --
        for(Opportunity o : newOppsList){
            system.debug('o.Created_From_Lead__c'+o.Created_From_Lead__c);
            if (o.Created_From_Lead__c != false && o.RecordTypeId == deOppRecordtypeId) {
                system.debug('o.Created_From_Lead__c if  '+o.Created_From_Lead__c);
                o.addError('Opportunity creation from Lead conversion is not Permitted');  
                return ;
            }
        } 

		// Adding records in map for specific country
        for(Opportunity o : newOppsMap.values()) {
            //if (o.RecordTypeId == caOppRecordtypeId ) caNewOppsMap.put(o.id, o);
            /* else */ if (o.RecordTypeId == deOppRecordtypeId ) deNewOppsMap.put(o.id, o);
            
            if((o.RecordTypeId==gbOppRecordtypeId || o.RecordTypeId==ieOppRecordtypeId) && o.Contract_Request_Date__c!=null ){
            	System.Debug('**TPS:EH 1.1 Opp afterUpdateHandler o=' + o); 
                //mapDocuSignOpp.put(o.Id, o);
            }
        }
		
        for(Opportunity o : newOppsList) {
            if (o.RecordTypeId == caOppRecordtypeId ) caNewOppsList.add(o);
            else if (o.RecordTypeId == deOppRecordtypeId ) deNewOppsList.add(o);
            else if (o.RecordTypeId == chOppRecordtypeId ) chNewOppsList.add(o);
            else if (o.RecordTypeId == atOppRecordtypeId ) atNewOppsList.add(o);
            else if (o.RecordTypeId == gbOppRecordtypeId ) gbNewOppsList.add(o);
            else if (o.RecordTypeId == ieOppRecordtypeId ) ieNewOppsList.add(o);
        }
        
        if (caNewOppsList.size() > 0) { Map<Id, Opportunity> newCAOppsMap = new Map<Id, Opportunity>(NewOppsList); ClsCADocumentTrackerHandler.afterOpportunityInsert(newCAOppsMap); }

        //Country dispatcher
		//Process DE Specific Processing
        if (deNewOppsMap.size() > 0) {
            ClsOpportunityTriggerHandler.OpportunityAddContentDocument(deNewOppsList); 
            String errorMsg = BPClsOpportunityDE.CreateBenefitONewOpportunityCreation(deNewOppsMap, deOldOppsMap);
            if(!errorMsg.containsIgnoreCase('ok')){
                deNewOppsMap.values()[0].addError(errorMsg);
                return;
            }
            errorMsg = BPClsOpportunityDE.UpdateOpportunityDataUponEditing(deNewOppsMap, deOldOppsMap, AftInsertFlag ); 
            if(!errorMsg.containsIgnoreCase('ok')){
                deNewOppsMap.values()[0].addError(errorMsg);
                return;
            }
            errorMsg = BPClsOpportunityDE.MCOpportunityEmails(deNewOppsMap, deOldOppsMap, AftInsertFlag );
            if(!errorMsg.containsIgnoreCase('ok')){
                deNewOppsMap.values()[0].addError(errorMsg);
                return;
            }
        }
		//Perform SSIP Specific processing
		if (chNewOppsList.size() > 0) ClsCHOpportunityTriggerHandler.processSubscriptionOpportunityProductCreation(chNewOppsList);
		if (gbNewOppsList.size() > 0) ClsSSIPUtilities.processSubscriptionOpportunityProductCreation(gbNewOppsList);
		if (ieNewOppsList.size() > 0) ClsSSIPUtilities.processSubscriptionOpportunityProductCreation(ieNewOppsList);
        if (caNewOppsList.size() > 0) ClsSSIPUtilities.processSubscriptionOpportunityProductCreation(caNewOppsList);
		
		/**** Start sending GB/IE contracts **/
        if(mapDocuSignOpp.size()>0){
            System.Debug('**TPS:EH 2.1 mapDocuSignOpp o=' + mapDocuSignOpp);
            for(Id oppId : mapDocuSignOpp.keySet()){
                System.Debug('**TPS:EH 2.2 oppId=' + oppId);                
                Opportunity o=mapDocuSignOpp.get(oppId);
				String jobID;
				string jobName;
                if(o.Contract_Request_Date__c!=null){
                    string min=String.valueOf(o.Contract_Request_Date__c.minute());
                    string hr=String.valueOf(o.Contract_Request_Date__c.hour());
                    string sec=String.valueOf(o.Contract_Request_Date__c.hour());
                    string dd=String.valueOf(o.Contract_Request_Date__c.Day());
                    string mm=String.valueOf(o.Contract_Request_Date__c.Month());
                    string yy=String.valueOf(o.Contract_Request_Date__c.Year());
                    
                    String sch = sec + ' ' + min + ' ' + hr + ' ' + dd + ' ' + mm + ' ? ' + yy;
                    System.Debug('**TPS:EH 2.3 sch=' + sch);                    
					if(o.RecordTypeId==gbOppRecordtypeId){
						jobName='GB Opp Contract Sch-' + oppId + '-' + System.DateTime.Now();
						jobID = System.schedule(jobName, sch, new ClsSendContractForGBIEOpp(oppId, 'GB'));
					}else
					if(o.RecordTypeId==ieOppRecordtypeId){
						jobName='IE Opp Contract Sch-' + oppId + '-' + System.DateTime.Now();
						jobID = System.schedule(jobName, sch, new ClsSendContractForGBIEOpp(oppId, 'IE'));
					}						
                	System.Debug('**TPS:EH 2.3 jobID=' + jobID);    
                }
            }    
        }
        /**** End sending GB/IE contracts **/
    }
    
    public static void afterUpdateHandler(Map<Id, Opportunity> newOppsMap, Map<Id, Opportunity> oldOppsMap) {
        system.debug('afterUpdateHandler');
        String AftInsertFlag = 'False';
        //Accumulate
        Map<Id, Opportunity> deNewOppsMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> deOldOppsMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> caNewOppsMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> caOldOppsMap = new Map<Id, Opportunity>();
		Map<Id, Opportunity> chNewOppsMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> chOldOppsMap = new Map<Id, Opportunity>();
		Map<Id, Opportunity> atNewOppsMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> atOldOppsMap = new Map<Id, Opportunity>();
		Map<Id, Opportunity> gbNewOppsMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> gbOldOppsMap = new Map<Id, Opportunity>();
		Map<Id, Opportunity> ieNewOppsMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> ieOldOppsMap = new Map<Id, Opportunity>();

        //Get all the Opp record type Ids
		Id caOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CA_Opportunity').getRecordTypeId();
		Id deOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DE_Opportunity').getRecordTypeId();
		Id chOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CH_Opportunity').getRecordTypeId();
		Id atOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('AT_Opportunity').getRecordTypeId();
		Id gbOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('GB_Opportunity').getRecordTypeId();
		Id ieOppRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('IE_Opportunity').getRecordTypeId();
        

        
		// Adding records in map for specific country
        for(Opportunity o : newOppsMap.values()) {           
            
            if(o.CloseDate != null && o.CloseDate != oldOppsMap.get(o.Id).CloseDate &&  (o.StageName == oldOppsMap.get(o.Id).StageName && (o.StageName == 'Closed - Complete' || o.StageName == 'Cancelled'))){
                String errorMsg = 'Close date is locked.';
                if(errorMsg != null && !errorMsg.containsIgnoreCase('ok')){
                    o.addError(errorMsg);
                    return;
                }
            }            
            if (o.RecordTypeId == caOppRecordtypeId ) caNewOppsMap.put(o.id, o);
				else if (o.RecordTypeId == deOppRecordtypeId ) deNewOppsMap.put(o.id, o);
					else if (o.RecordTypeId == chOppRecordtypeId  ) chNewOppsMap.put(o.id, o);
						else if (o.RecordTypeId == atOppRecordtypeId ) atNewOppsMap.put(o.id, o);
							else if (o.RecordTypeId == gbOppRecordtypeId ) gbNewOppsMap.put(o.id, o);
								else if (o.RecordTypeId == ieOppRecordtypeId ) ieNewOppsMap.put(o.id, o);
						
        }
        // Adding records in map for specific country
        for(Opportunity o : oldOppsMap.values()) {
            if (o.RecordTypeId == caOppRecordtypeId ) caOldOppsMap.put(o.id, o);
				else if (o.RecordTypeId == deOppRecordtypeId ) deOldOppsMap.put(o.id, o);
					else if (o.RecordTypeId == chOppRecordtypeId  ) chOldOppsMap.put(o.id, o);
						else if (o.RecordTypeId == atOppRecordtypeId ) atOldOppsMap.put(o.id, o);
							else if (o.RecordTypeId == gbOppRecordtypeId ) gbOldOppsMap.put(o.id, o);
								else if (o.RecordTypeId == ieOppRecordtypeId ) ieOldOppsMap.put(o.id, o);
						
						
        }            
        //Country dispatcher
		//Process DE Specific Processing
        if (deNewOppsMap.size() > 0) {
            ClsOpportunityTriggerHandler.ProcessOpportunityForScheduleShipments(deNewOppsMap, deOldOppsMap ); 
            String errorMsg = BPClsOpportunityDE.UpdateOpportunityStageToOnHoldOrCloseComplete(deNewOppsMap, deOldOppsMap ); 
            if(errorMsg != null && !errorMsg.containsIgnoreCase('ok')){
                deNewOppsMap.values()[0].addError(errorMsg);
                return;
            }
            errorMsg = BPClsOpportunityDE.UpdatePricebooksOnNonRejectedQuotes(deNewOppsMap, deOldOppsMap);
            if(errorMsg != null && !errorMsg.containsIgnoreCase('ok')){
                deNewOppsMap.values()[0].addError(errorMsg);
                return;
            }
            errorMsg = BPClsOpportunityDE.UpdateOpportunityDataUponEditing(deNewOppsMap, deOldOppsMap, AftInsertFlag ); 
            if(errorMsg != null && !errorMsg.containsIgnoreCase('ok')){
                deNewOppsMap.values()[0].addError(errorMsg);
                return;
            }
            errorMsg = BPClsOpportunityDE.MCOpportunityEmails(deNewOppsMap, deOldOppsMap, AftInsertFlag );
            if(errorMsg != null && !errorMsg.containsIgnoreCase('ok')){
                deNewOppsMap.values()[0].addError(errorMsg);
                return;
            }
        }
		//Process CA Specific Processing
        if (caNewOppsMap.size() > 0) { 
        	ClsCADocumentTrackerHandler.afterOpportunityUpdate(caNewOppsMap,caOldOppsMap);
            List<Opportunity> caOppPriceBookChanged = new List<Opportunity>();
            for(Opportunity o : caNewOppsMap.values()) {
                if (o.Pricebook2Id != caOldOppsMap.get(o.Id).PriceBook2ID)caOppPriceBookChanged.add(o);
            }
            if (caOppPriceBookChanged.size() > 0) ClsSSIPUtilities.processSubscriptionOpportunityProductCreation(caOppPriceBookChanged);
            
            ClsCAOpportunityTriggerHandler.createNewOpportunity(caNewOppsMap.values(), caOldOppsMap);
            //Update the MedFac & Prescriber on Account if an Opportunity is Closed for Canada. Vijay Adusumilli Sept 5, 2019
            List<Opportunity> updAccMedFacPrescriber = new List<Opportunity>();
            List<Opportunity> OppForFund = new List<Opportunity>();
            for(Opportunity updOpp : caNewOppsMap.values()) {
                System.debug('**updOpp'+updOpp.StageName);
                System.debug('**updOldOpp'+caOldOppsMap.get(updOpp.ID).StageName);
                System.debug('**updOppPres'+updOpp.Prescriber__c);
                System.debug('**updOppMedic'+updOpp.Medical_Facility__c);
                if (updOpp.StageName == 'Closed - Complete' && 
                   		updOpp.StageName != caOldOppsMap.get(updOpp.ID).StageName &&
                   		(updOpp.Prescriber__c != null || updOpp.Medical_Facility__c != null))
                    updAccMedFacPrescriber.add(updOpp);
                
                // need to add condition for Particual CA Account - F-01296
                if (updOpp.StageName != caOldOppsMap.get(updOpp.ID).StageName && updOpp.Create_Fund__c == True && updOpp.StageName == 'Order Fulfillment')
                    OppForFund.add(updOpp);                    
            }           
            if (OppForFund.size() > 0) 
            	ClsCAOpportunityTriggerHandler.createFund(OppForFund); 
            
            if (updAccMedFacPrescriber.size() > 0) 
                ClsCAOpportunityTriggerHandler.updAccountMedFacPrescriber(caNewOppsMap.values());
            
             String errorMsg = ClsCAOpportunityTriggerHandler.processOpportunityForScheduleShipments(caNewOppsMap, caOldOppsMap);
            if(errorMsg != null && !errorMsg.containsIgnoreCase('OK')){
                caNewOppsMap.values()[0].addError(errorMsg);
                return;
            }
        }
        Map<Id, Opportunity> newPBOppsMap = new Map<Id, Opportunity>(); 

		//Process CH Specific Processing
		if (chNewOppsMap.size() > 0) {
            String errorMsg = ClsCHOpportunityTriggerHandler.processOpportunityForScheduleShipments(chNewOppsMap, chOldOppsMap);
            if(errorMsg != null && !errorMsg.containsIgnoreCase('ok')){
                chNewOppsMap.values()[0].addError(errorMsg);
                return;
            }
            newPBOppsMap.clear();          
            for(Opportunity opp: chNewOppsMap.values()) if ((chOldOppsMap.get(opp.id).PriceBook2Id != opp.PriceBook2Id) && (opp.StageName != 'Order Fulfillment' || opp.StageName != 'Closed')) {
                    newPBOppsMap.put(opp.id, chNewOppsMap.get(opp.id));
            }
            if (newPBOppsMap.size() > 0) {
                ClsCHOpportunityTriggerHandler.processSubscriptionOpportunityProductCreation(newPBOppsMap.values()); 
        	}
		}
		//Process AT Specific Processing
		if (atNewOppsMap.size() > 0) {
			String errorMsg = ClsATOpportunityTriggerHandler.processOpportunityForScheduleShipments(atNewOppsMap, atOldOppsMap ); 
			if(errorMsg != null && !errorMsg.containsIgnoreCase('ok')){
                atNewOppsMap.values()[0].addError(errorMsg);
                return;
            }
		}
		//Process GB Specific Processing
		if (gbNewOppsMap.size() > 0) {
			String errorMsg = ClsGBOpportunityTriggerHandler.processOpportunityForScheduleShipments(gbNewOppsMap, gbOldOppsMap ); 
			if(errorMsg != null && !errorMsg.containsIgnoreCase('ok')){
                gbNewOppsMap.values()[0].addError(errorMsg);
                return;
            }
            newPBOppsMap.clear();          
            for(Opportunity opp: gbNewOppsMap.values()) if ((gbOldOppsMap.get(opp.id).PriceBook2Id != opp.PriceBook2Id) && (opp.StageName != 'Order Fulfillment' || opp.StageName != 'Closed')) {
                    newPBOppsMap.put(opp.id, gbNewOppsMap.get(opp.id));
            }
            if (newPBOppsMap.size() > 0) {
                ClsSSIPUtilities.processSubscriptionOpportunityProductCreation(newPBOppsMap.values());
        	}
		}
		//Process IE Specific Processing
		if (ieNewOppsMap.size() > 0) {
			String errorMsg = ClsIEOpportunityTriggerHandler.processOpportunityForScheduleShipments(ieNewOppsMap, ieOldOppsMap ); 
			if(errorMsg != null && !errorMsg.containsIgnoreCase('ok')){
                ieNewOppsMap.values()[0].addError(errorMsg);
                return;
            }
            newPBOppsMap.clear();          
            for(Opportunity opp: ieNewOppsMap.values()) if ((ieOldOppsMap.get(opp.id).PriceBook2Id != opp.PriceBook2Id) && (opp.StageName != 'Order Fulfillment' || opp.StageName != 'Closed')) {
                    newPBOppsMap.put(opp.id, ieNewOppsMap.get(opp.id));
            }
            if (newPBOppsMap.size() > 0) {
                ClsSSIPUtilities.processSubscriptionOpportunityProductCreation(newPBOppsMap.values());
        	}
		}
    }
}