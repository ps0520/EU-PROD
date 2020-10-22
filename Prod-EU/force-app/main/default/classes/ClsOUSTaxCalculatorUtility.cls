public class ClsOUSTaxCalculatorUtility {
    private static Map<String, String> mapCountryCode;
    static{
        mapCountryCode = ClsOUSTaxCalculatorUtility.getPicklistValues('Account', 'ShippingCountryCode');
    }
    public class RequestWrapper{
        public TransactionRowW transactionRow;
        public RequestWrapper(Order objOrder){
            this.transactionRow = new TransactionRowW(objOrder);
        }
    }
    
    public class TransactionRowW {
		public String ShipToCountryCode;//DE
		public String ShipToExemptStatus; //true/false
		public String ShipToHasTaxReg; //true/false
		public String BillToHasTaxReg; //true/false
		public String BillToCountryCode;	//DE
		public String BillToExemptStatus; //true/false
		public String Warehouse;	//HLNL
		public TaxableTransactionLineW[] TaxableTransactionLine;
		public String TrxCurrencyCode;	//EUR
		public String TrxDate;	//2019-10-16
		public String TrxNumber;	//00319755
        
		
		public TransactionRowW(Order objOrder){
			String countryCode = mapCountryCode.get(objOrder.Customer_Ship_To_Address__r.Country__c) == 'GB' ? 'UK' : mapCountryCode.get(objOrder.Customer_Ship_To_Address__r.Country__c);
		    this.ShipToCountryCode = countryCode;
			this.ShipToExemptStatus = 'false';//We will invoke API only when there is no tax exempt, so it is safe to assume this as false
			this.ShipToHasTaxReg = objOrder.Tax_Registration_Number__c == null ? 'false' : 'true';//We base this flag based on the Tax Registration Number 
			this.BillToHasTaxReg = this.hasTaxReg(objOrder);//objOrder.Tax_Registration_Number__c == null ? 'false' : 'true';//We base this flag based on the Tax Registration Number
			this.BillToCountryCode = countryCode;//Reason we are still keeping the same as Ship to is because we don't have a situation where we will bill to a different country and we have complexity in looking at Customer Bill to vs Payor bill to, so keeping it simple. This is a requirement for API to work.
			this.BillToExemptStatus = this.exemptStatus(objOrder);//'false';//We will invoke API only when there is no tax exempt, so it is safe to assume this as false
		    this.Warehouse = objOrder.Warehouse__c;
		    this.TrxCurrencyCode = objOrder.CurrencyIsoCode;
		    this.TrxNumber = objOrder.OrderNumber;
            
            if(objOrder.Type.containsIgnoreCase('Return')){
                this.TrxDate = String.valueOf(objOrder.Parent_Order__r.EffectiveDate);
            }else{
                this.TrxDate = String.valueOf(Date.today());
            }
		    
		    this.TaxableTransactionLine = new List<TaxableTransactionLineW>();
		    for(Integer i = 1; i <= objOrder.OrderItems.size(); i++){
		        TaxableTransactionLine.add(new TaxableTransactionLineW(objOrder.OrderItems[i-1], i));
		    }
		}
        
        private String hasTaxReg(Order o){
			return String.isNotBlank(o.Payor__c) && (o.type.startsWithIgnoreCase('GB') || o.type.startsWithIgnoreCase('IE')) 
                   && o.Payor__r.Tax_Registration_Number__c != null ? 'true' : String.isNotBlank(o.Payor__c) && (o.type.startsWithIgnoreCase('GB') || o.type.startsWithIgnoreCase('IE')) 
                   && o.Payor__r.Tax_Registration_Number__c == null ? 'false' : o.Tax_Registration_Number__c == null ? 'false' : 'true';
        }
        
        private String exemptStatus(Order o){
            return String.isNotBlank(o.Payor__c) && (o.type.startsWithIgnoreCase('GB') || o.type.startsWithIgnoreCase('IE')) 
                   && o.Payor__r.Tax_Exempt__c == true ? 'true' : String.isNotBlank(o.Payor__c) && (o.type.startsWithIgnoreCase('GB') || o.type.startsWithIgnoreCase('IE')) 
                   && o.Payor__r.Tax_Exempt__c == false ? 'false' : o.Tax_Exempt__c == false ? 'false' : 'true';
        }
	}
	public class TaxableTransactionLineW {
		public String LineAmount;	//246.22
		public String TrxLineDescription;	//8024E000001gFAtQAM
		public String TrxLineNumber;	//1
		public String TrxLineQuantity;	//1
		public String UOMCode;	//EA
		public String UnitPrice;	//246.22
		
		public TaxableTransactionLineW(OrderItem oItem, Integer index){
		    this.LineAmount = String.valueOf(oItem.TotalPrice);
		    this.TrxLineDescription = oItem.Id;
		    this.TrxLineNumber = String.valueOf(index);
		    this.TrxLineQuantity = String.valueOf(oItem.Quantity);
		    this.UOMCode = 'EA';
		    this.UnitPrice = String.valueOf(oItem.UnitPrice);
		}
	}
	
	public class ResponseWrapper{
	    public CalculateTransactionTaxEstimateResponseW calculateTransactionTaxEstimateResponse;
	}
	
	public class CalculateTransactionTaxEstimateResponseW {
		public ResultW[] result;
	}
	public class ResultW {
		public String LineNumber;	//0
		public String TaxLine;	//1
		public String TaxRateCode;	//DE I   STD
		public String TaxRate;	//19
		public String TaxAmount;	//46.78
		public String Inclusive;	//N
		public String SelfAssessed;	//N
		public String TaxOnlyLine;	//N
		public String TaxRegimeCode;	//DE TAX
		public String Tax;	//DE TAX
		public String TaxJurisdictionCode;	//DE BMF
		public String TaxJurisdictionName;	//Bundesministerium der Finanzen
		public String TaxPointBasis;	//ACCOUNTING
	}
	public static Map<String, String> getPicklistValues(String objectAPI,String fieldAPI){ 
        Map<String, String> mapPicklist = new Map<String, String>();
        for(Schema.PicklistEntry sObjPickListEntry : Schema.getGlobalDescribe().get(objectAPI).newSObject().getSObjectType().getDescribe().fields.getMap().get(fieldAPI).getDescribe().getPickListValues()){
            mapPicklist.put(sObjPickListEntry.getLabel(), sObjPickListEntry.getValue());
        }
        return mapPicklist;
    }
    
	public static String makeCallOut(Order objOrder){
        try{
            String requestBody = JSON.serialize(new RequestWrapper(objOrder));
            system.debug('Request body is ' + requestBody);
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:OUSTaxCalculatorNamedCredential');
            request.setMethod('POST');
            request.setHeader('Content-Type', ' application/json');
            request.setBody(requestBody);
            request.setTimeout(20000); 
            HttpResponse response = http.send(request);
            System.debug('======body======='+response.getBody());
            if(response.getStatusCode() == 200){
                return response.getBody();
            }else{
                return 'ERROR';        
            }
        }catch(Exception ex){
            return 'ERROR';
        }
	}
}