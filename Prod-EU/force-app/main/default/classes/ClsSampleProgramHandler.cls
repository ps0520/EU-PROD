public class ClsSampleProgramHandler {
    
    public static Map<String,String> createOrder(Id accountId,String SampleType, Id shipToAddressId,Double OrdQuantity,String OCEOrdRef){
        System.debug('**SPE--createOrder--');
        Map<String,String> maptoReturnResult = new Map<String,String>();
        try{
               //ClsCheckRecursive.run = false;
                //If shipToAddressId is passed in i.e. not null, try to obtain the address with that id and accountId. If it exists, use that address. Vijay Aug 25, 2020 based on feedback from Jagan.
                Map<Id, Address__c> accntIdToBillToAddressMap = new Map<Id, Address__c>();
                List<Address__c> accntIdToShipToAddressList = new List<Address__c>();
                for(Address__c addr : [SELECT Id, Account__c, Address_Line_1__c, City__c, 
                                       State__c, Postal_Code__c, Country__c, Type__c, Primary_Flag__c
                                       FROM Address__c 
                                       WHERE /* Primary_Flag__c = TRUE 
                                       AND */ Account__c =: accountId]){                                       
                                           if(addr.Type__c == 'Bill To' && addr.Primary_Flag__c == true)
                                               accntIdToBillToAddressMap.put(addr.Account__c, addr);
                                           else if(addr.Type__c == 'Ship To')
                                               accntIdToShipToAddressList.add(addr);
                                       }
                
                Address__c billToAddress = accountId != null ? accntIdToBillToAddressMap.get(accountId) : null;
            	Address__c shipToAddress = new Address__c();
                for (Address__c shiptoAdd : accntIdToShipToAddressList) {
                    if (accountId != null && shipToAddressId == null && shiptoAdd.Primary_Flag__c == true) shipToAddress = shiptoAdd;
                    if (accountId != null && shipToAddressId != null && shiptoAdd.id == shipToAddressId) shipToAddress = shiptoAdd;
                }
                //Address__c shipToAddressDetail = accntIdToShipToAddressMap.get(accountId);
                //System.debug('**shipToAddressDetail--'+shipToAddressDetail);
                //System.debug('**shipToAddressId--'+shipToAddressId);
                
                Boolean validateShiptTo = shipToAddress != null ? true:false;
                System.debug('**validateShiptTo--'+validateShiptTo);
                if(validateShiptTo){
                    
                    Map<String,String> mapOfPBProducts = new Map<String,String>();
                    String countryCode;
                    Account acc = [Select id,Country__c,CurrencyIsoCode,RecordType.Name,RecordTypeId from account where id=:accountId];
                    countryCode = getCountryCode(acc.RecordTypeId);
                    
                    Sample_Program_Config__mdt[] sampleConfigmdt = [Select Id,Country_Code__c,Price_Book_Name__c,
                                                                    Quantity__c,Sample_Type__c,SKU__c
                                                                    from Sample_Program_Config__mdt
                                                                    where Sample_Type__c=:SampleType 
                                                                    and Country_Code__c =: countryCode];
                    
                    System.debug('**sampleConfigmdt--'+sampleConfigmdt);
                    Map<Id,Sample_Program_Config__mdt> mapSampleConfig = new Map<Id,Sample_Program_Config__mdt>();
                    Set<String> setOfPBNames = new Set<String>();
                    for(Sample_Program_Config__mdt mdt : sampleConfigmdt){
                        mapSampleConfig.put(mdt.Id,mdt);
                        setOfPBNames.add(mdt.Price_Book_Name__c);
                    }
                    Pricebook2 pb2 = [select Id, Name, IsActive from PriceBook2 where name IN:setOfPBNames LIMIT 1];
                    List<Pricebookentry> lstEntry = [SELECT Id,Name,unitprice,Pricebook2Id FROM PricebookEntry WHERE Pricebook2Id = :pb2.Id ]; 
                    Map<String,Pricebookentry> mapofProdcut = new Map<String,Pricebookentry>();
                    Map<String,Double> mapofProdcutQuant = new Map<String,Double>();
                    for(Sample_Program_Config__mdt mdt : mapSampleConfig.values()){
                        for(Pricebookentry entry : lstEntry){
                            String prdName = entry.Name;
                            if(prdName.containsIgnoreCase(mdt.SKU__c)){
                                mapofProdcut.put(entry.Id, entry);
                                mapofProdcutQuant.put(entry.Id, mdt.Quantity__c);
                            }   
                        }
                    }
                    
                    List<OrderItem> orderItemsToAdd = new List<OrderItem>();
                    List<Order> lstOrder = new List<Order>();//Order records to be added
                    Map<Id, Account> paymentTermsMap = new Map<Id, Account>([Select Id, Payment_Terms__c, Tax_Exempt__c,Tax_Registration_Number__c
                                                                             from Account
                                                                             where id=:accountId]);
                    
                    if(billToAddress == null){
                        maptoReturnResult.put('Failed','Bill To address not found');
                        return maptoReturnResult;
                    }
                    Order orderToBeCreated = new Order();
                    orderToBeCreated.AccountId = accountId; 
                    orderToBeCreated.Customer_Ship_To_Address__c = shipToAddress.Id; 
                    orderToBeCreated.ShippingStreet = shipToAddress.Address_Line_1__c;
                    orderToBeCreated.ShippingCity = shipToAddress.City__c;
                    orderToBeCreated.ShippingState = shipToAddress.State__c;
                    orderToBeCreated.ShippingPostalCode = shipToAddress.Postal_Code__c;
                    orderToBeCreated.ShippingCountry = shipToAddress.Country__c;
                    orderToBeCreated.OCE_Order_Ref__c=OCEOrdRef;
                    orderToBeCreated.Customer_Bill_To_Address__c = billToAddress.Id;
                    orderToBeCreated.BillingStreet = billToAddress.Address_Line_1__c;
                    orderToBeCreated.BillingCity = billToAddress.City__c;
                    orderToBeCreated.BillingState = billToAddress.State__c;
                    orderToBeCreated.BillingPostalCode = billToAddress.Postal_Code__c;
                    orderToBeCreated.BillingCountry = billToAddress.Country__c;        
                    
                    orderToBeCreated.Status = 'Draft';
                    orderToBeCreated.Price_Book__c = pb2.Id;
                    orderToBeCreated.EffectiveDate = system.today(); 
                    //countryCode = countryCode 
                    orderToBeCreated.Type = countryCode + ' SALES SAMPLE';
                    orderToBeCreated.CurrencyIsoCode = 'CAD';
                    orderToBeCreated.RecordTypeId = getOrdRecordtypeId(countryCode); 
                    orderToBeCreated.Reasons_For_Sample_Orders__c = '$Hello Dexcom';
                    orderToBeCreated.Payment_Terms__c = 'net0';
                    //orderToBeCreated.Order_Sub_Type__c = 'Sample';
                    insert orderToBeCreated;
                    for(String prd: mapofProdcut.keySet()){
                        OrderItem orderItemToBeCreated = new OrderItem ();
                        orderItemToBeCreated.OrderId = orderToBeCreated.Id; 
                        orderItemToBeCreated.Quantity = OrdQuantity == 0 ? mapofProdcutQuant.get(prd): Double.valueOf(OrdQuantity) ;
                        orderItemToBeCreated.UnitPrice = 0.00;
                        orderItemToBeCreated.PricebookEntryId = prd;
                        orderItemsToAdd.add(orderItemToBeCreated);
                    }
                    
                    insert orderItemsToAdd;
                    orderToBeCreated.Status = 'Activated';
                    Database.SaveResult sr = Database.update(orderToBeCreated, false);
                    
                    if(sr.isSuccess()){
                        
                        System.debug('Successfully inserted Order. Order ID: ' + sr.getId());
                        Order ord = [Select id,OrderNumber from Order where id =:orderToBeCreated.Id];
                        maptoReturnResult.put('Success',ord.OrderNumber);
                        return maptoReturnResult;
                    }else{
                        for(Database.Error err : sr.getErrors()) {
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Account/Order fields that affected this error: ' + err.getFields());
                            maptoReturnResult.put('Failed', err.getMessage());
                        }
                        return maptoReturnResult;
                    }
                    
                }else{
                    maptoReturnResult.put('Failed','Primary Shipto Address not found' );
                    return maptoReturnResult;
                }            
        }catch(Exception ex){
            System.debug('**SampleErr--'+ex);
            System.debug('**SampleErrLine--'+ex.getLineNumber());
            maptoReturnResult.put('Failed',ex.getMessage());
            return maptoReturnResult;
        }
    }
    
  /*  public static void creteSampleOpportunity(Id accId,String SampleType){
        System.debug('**SampleOpp--creteSampleOpportunity--');
        try{
            
            //var declaration
            List<Opportunity> newLstOpps = new List<Opportunity>();
            Set<Id> oppAccIds = new Set<id>();
            Map<Id, Account> accountInfoMap = new Map<Id, Account>();
            List<Account> accountInfo = [Select Id, Name,CurrencyIsoCode,OwnerId,Country__c,RecordType.Name,RecordTypeId, Territory__c from Account where id =:accId];
            accountInfoMap.putAll(accountInfo);
            String countryCode = getCountryCode(accountInfoMap.get(accId).RecordTypeId);
            Opportunity newOpp = new Opportunity();
            //newOpp.Parent_Opportunity__c = o.Id; // Confirm from Vijay
            newOpp.AccountId = accId;
            newOpp.CurrencyIsoCode = accountInfoMap.get(accId).CurrencyIsoCode;
            newOpp.Name = accountInfoMap.get(accId).Name + ' - ' + accountInfoMap.get(accId).Territory__c + ' - ' + String.valueOf(Date.today().month()) + '/' + 
                String.valueOf(Date.today().day()) + '/' + String.valueOf(Date.today().year());
            newOpp.OwnerId = accountInfoMap.get(accId).OwnerId;
            newOpp.Country__c = accountInfoMap.get(accId).Country__c;
            newOpp.Type = 'New'; // Need to Change
            newOpp.CloseDate = Date.today() + 30;
            newOpp.RecordTypeId = getOppRecordtypeId(countryCode);
            newOpp.StageName = 'New Opportunity';
            insert newOpp;
            
            
        }catch(Exception ex){
            System.debug('**SampleOpp--Err--'+ex);
            System.debug('**SampleOpp--ErrLine--'+ex.getLineNumber());
        }
        
    }//creteSampleOpportunity - Method End*/
    
    public static String getOrdRecordtypeId(String CountryCode){
        
        String recTypeName = CountryCode + ' Sales Order';
        System.debug('recTypeName--'+recTypeName);
        Id ordRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get(recTypeName).getRecordTypeId();
        
        return ordRecordTypeId;
    }
    
   /* public static String getOppRecordtypeId(String CountryCode){
        
        String recTypeName = CountryCode + ' Opportunity';
        system.debug('**recTypeName--'+recTypeName);
        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(recTypeName).getRecordTypeId();
        
        return oppRecordTypeId;
    }*/
    
    public static String getCountryCode(String RecordTypeId){
        String countryCode = '';
        
        Map<String,String> mapRecordTypes = new Map<String,String>();
        
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Account' and isActive=true and Id=:RecordTypeId];
        for(RecordType rt: rtypes)
            mapRecordTypes.put(rt.Name,rt.Id);	
        
        for(String recName : mapRecordTypes.KeySet()){
            if(recName.startsWith('CA')){
                countryCode = 'CA';
            }else if(recName.startsWith('DE')){
                countryCode = 'DE';
            }else if(recName.startsWith('AT')){
                countryCode = 'AT';
            }else if(recName.startsWith('CH')){
                countryCode = 'CH';
            }else if(recName.startsWith('GB')){
                countryCode = 'GB';
            }else if(recName.startsWith('IE')){
                countryCode = 'IE';
            }else if(recName.startsWith('INTL')){
                countryCode = 'INTL';
            }else if(recName.startsWith('SI')){
                countryCode = 'SI';
            }
        }
        return countryCode;
    }  
}