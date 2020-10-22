public class ClsOUSTaxCalculator {
    
    @auraEnabled
    public static String calculateTax(Id OrderId) {
        //Call the Fusion Rest Service to get Taxes
        Order o = [SELECT TotalAmount, Type, Shipping_Charges__c, Id, Count_of_Order_Line_Items__c,Parent_Order__r.EffectiveDate, Need_To_Calculate_Tax__c, Tax_Exempt__c, Tax_Registration_Number__c, Payor__c, Payor_Bill_To_Address__c,
                   Customer_Bill_To_Address__r.Account__c, Customer_Bill_To_Address__c, Customer_Ship_To_Address__r.Account__c, Customer_Ship_To_Address__c,
                   Customer_Ship_To_Address__r.Country__c, Warehouse__c, CurrencyIsoCode, OrderNumber, Payor__r.Tax_Registration_Number__c, Payor__r.Tax_Exempt__c,
                   Payor_Bill_To_Address__r.Country__c,Customer_Bill_To_Address__r.CurrencyIsoCode, CA_GST_Tax_Rate__c,CA_PST_Tax_Rate__c, 
                   System_Of_Origin__c,Customer_Ship_To_Address__r.State__c,Customer_Ship_To_Address__r.CurrencyIsoCode, Total_Gross_Price__c,
                   (SELECT Id, Unitprice, Quantity,Product_Name__c,CA_GST_Tax_Amount__c,CA_PST_Tax_Amount__c,Parent_Order_Line_Id__c,
                    TotalPrice FROM OrderItems) 
                   FROM Order WHERE Id = :OrderId];
        //System.debug('**EBS--ShipToCode======'+o.Customer_Ship_To_Address__r.CurrencyIsoCode);
        //System.debug('**EBS--Order======'+o.CurrencyIsoCode);
        if (String.isNotBlank(o.Payor__c) && String.isBlank(o.Payor_Bill_To_Address__c)) return 'There is a Payor, please add Payor\'s Billing Address to the Order.';
        if (o.Need_To_Calculate_Tax__c != 'True' || (o.Tax_Exempt__c && !(String.isNotBlank(o.Payor__c) && (o.type.startsWithIgnoreCase('GB') || o.type.startsWithIgnoreCase('IE'))))) return 'No need to calculate Tax';
        if ((o.TotalAmount == 0.00 && o.Count_of_Order_Line_Items__c == 0) || (o.Count_of_Order_Line_Items__c == 1 && o.Total_Gross_Price__c == o.Shipping_Charges__c && o.Total_Gross_Price__c > 0))  return 'Please add a Product before Calculating Tax';
		
        if(o.Customer_Ship_To_Address__r.Country__c == 'Canada'){
            String returnValue = calculateEBSTax(o);
            if(returnValue == 'Succeeded'){ 
                System.debug('**EBS--Succeeded======');
                return 'Exact VAT/TAX Calculated from EBS System';
            }else{
				return returnValue + ' - Please contact IT if you need further assistance.';                
            }
        }else{
            if(calculateTaxRemote(o) == 'Succeeded')        
                return 'Exact VAT/TAX Calculated from Fusion System';
            else {
                return 'Fusion Tax service is not reachable or encountered an error. Please retry 3 times if possible with a gap in between. If it still continues to be an issue, please report it.';
            }    
        }
    }

	public static String calculateTaxRemote(Order o) {
        /*For now commenting this out as response is not yet coming. --- Please uncomment when not needed.*/
	    /*List<Order> lstOrder = [SELECT Id, Customer_Bill_To_Address__r.Account__c, Customer_Bill_To_Address__c, Customer_Ship_To_Address__r.Account__c, Customer_Ship_To_Address__c,
	                                   Customer_Ship_To_Address__r.Country__c, Warehouse__c, CurrencyIsoCode, OrderNumber, Tax_Registration_Number__c, 
	                                   (SELECT Id, Unitprice, Quantity, TotalPrice FROM OrderItems) 
	                             FROM Order WHERE Id =: OrderId];*/
	   
	    String responseBody = ClsOUSTaxCalculatorUtility.makeCallOut(o);
	    System.debug('==========responseBody======'+responseBody);
	    if(responseBody.containsIgnoreCase('ERROR')){
	        return 'Failed';
	    }else{
	        try{
    	        ClsOUSTaxCalculatorUtility.ResponseWrapper response = (ClsOUSTaxCalculatorUtility.ResponseWrapper)JSON.deserialize(responseBody, ClsOUSTaxCalculatorUtility.ResponseWrapper.class);
    	        System.debug('==========response======'+response);
    	        List<OrderItem> lstOrderItem = new List<OrderItem>();
    	        for(Integer i = 0; i < o.OrderItems.size(); i++){
    		        ClsOUSTaxCalculatorUtility.ResultW result  = response.calculateTransactionTaxEstimateResponse.result[i];
    		        lstOrderItem.add(new OrderItem(Id = o.OrderItems[i].Id, Tax_Rate__c = Decimal.valueOf(result.TaxRate), Item_VAT_TAX__c = Decimal.valueOf(result.TaxAmount), Tax_Source__c = 'Fusion'));
    		    }
    		    System.debug('==========lstOrderItem======'+lstOrderItem);
    		    update lstOrderItem;
    		    update new Order(Id = o.Id, Need_To_Calculate_Tax__c = 'False');
    		    return 'Succeeded';
	        }catch(Exception ex){ 
	             return 'Failed';
	        }
	    }
    }
  
  // Method added for EBSTax calculation -- By Pravin on - 20/07/2020  
   public static String calculateEBSTax(Order o) {
        
	    String responseBody = ClsCAEBSReqTaxCalculation.makeEBSCallOut(o);
      
	    System.debug('**EBS--ResponseBody======'+responseBody);
	    /*if(responseBody.containsIgnoreCase('ERROR')){
	        return 'Failed';
	    }else{*/
       try{
           ClsCAEBSReqTaxCalculation.EBSResponseWrapper res = (ClsCAEBSReqTaxCalculation.EBSResponseWrapper)JSON.deserialize(responseBody, ClsCAEBSReqTaxCalculation.EBSResponseWrapper.class);
           System.debug('**EBS--deserialize-->'+res);
           String ErrorMessage = String.valueOf(res.ErrorMessage);
           System.debug('**EBS--ErrorMessage-->'+ErrorMessage);
           if(ErrorMessage == '' || ErrorMessage == null){
               System.debug('**EBS--SuccessBlock-->');
               
               Order ord = new Order();
               ord.Id = o.Id;
               for(ClsCAEBSReqTaxCalculation.TaxSummary taxsummaryDetail : res.TaxSummary){
                   
                   if(taxsummaryDetail.TaxType.containsIgnoreCase('GST') ){
                       System.debug('**EBS--res.TaxSummary--CA GST');
                       
                       ord.CA_GST_Tax_Rate__c = Decimal.valueOf(taxsummaryDetail.TaxRate);
                       ord.CA_GST_Tax_Amount__c = Decimal.valueOf(taxsummaryDetail.TaxAmount);
                       // Amount is getting stored in new two fields --
                   }
                   if(taxsummaryDetail.TaxType.containsIgnoreCase('HST') ){
                       System.debug('**EBS--res.TaxSummary--CA HST');
                       
                       ord.CA_HST_Tax_Rate__c = Decimal.valueOf(taxsummaryDetail.TaxRate);
                       ord.CA_HST_Tax_Amount__c = Decimal.valueOf(taxsummaryDetail.TaxAmount);
                       // Amount is getting stored in new two fields --
                   }
                   if(taxsummaryDetail.TaxType.containsIgnoreCase('PST') ){
                       //ord.Id = o.Id;
                       ord.CA_PST_Tax_Rate__c = Decimal.valueOf(taxsummaryDetail.TaxRate);
                       ord.CA_PST_Tax_Amount__c = Decimal.valueOf(taxsummaryDetail.TaxAmount);
                   }
               }
               ord.Need_To_Calculate_Tax__c = 'false';
               System.debug('**EBS--res.TaxDetails--'+res.TaxDetails);
               //System.debug('**o.CA_PST_Tax_Rate__c--'+o.CA_PST_Tax_Rate__c);
               
               List<OrderItem> lstOrderItem = new List<OrderItem>();
               Map<Id,OrderItem> mapOrderItem = new Map<Id,OrderItem>();
               //List<ClsCAEBSReqTaxCalculation.TaxDetails> childResult = res.TaxDetails;
               if(res.TaxDetails != null){
                   
                   for(Integer i = 0; i < res.TaxDetails.size(); i++){
                       ClsCAEBSReqTaxCalculation.TaxDetails result  = res.TaxDetails[i];
                       //Item_VAT_TAX__c
                       if(mapOrderItem.ContainsKey(result.LineId)){
                               OrderItem oLi = mapOrderItem.get(result.LineId); 
                               oLi.Item_VAT_TAX__c += Decimal.valueOf(result.TaxAmount);
                               mapOrderItem.put(result.LineId,oLi);
                           }else{
                               OrderItem oLi = new orderItem();
                               oLi.Id =result.LineId;                           
                               //oLi.Unitprice = Decimal.valueOf(result.Price);
                               //oLi.Product_Name__c = String.valueOf(result.Sku);
                               oLi.Item_VAT_TAX__c = Decimal.valueOf(result.TaxAmount);
                               mapOrderItem.put(result.LineId,oLi);
                           }  
                     
                   update mapOrderItem.values();
               	   }
               }              
               update ord;
               return 'Succeeded';
           }
           else return ErrorMessage;
       }catch(Exception ex){
           System.debug('**ErrLine--'+ex.getLineNumber());
           System.debug('**ErrMsg--'+ex.getMessage());
           //return 'Failed';
           return 'Error at: ' + ex.getLineNumber() + ': ' + ex.getMessage();
       }
	   // }
	   //return 'Failed';
    }
	
}