/********************************************************************************
@Author         : Pravin Jagadale
@Date Created   : 14/07/2020
@Description    : Class will Cover - EBS Tax Calculation  - REST API Call 
*********************************************************************************/
public class ClsCAEBSReqTaxCalculation {
    
    public class RequestWrapper{
        
        public List<TaxLines> TaxLines;
        public TaxHeader TaxHeader; 
        public RequestWrapper(Order objOrder){            
            this.TaxLines = new List<TaxLines>();
            for(Integer i = 1; i <= objOrder.OrderItems.size(); i++){ 
                TaxLines.add(new TaxLines(objOrder.OrderItems[i-1]));
            }
            this.TaxHeader = new TaxHeader(objOrder);
        }
    }
    // For EBS Request Serialization 
    public class TaxLines {
        
        public string Sku;
        public string Quantity;
        public string ReferenceLineId;
        public string Price;
        public string LineId;
        
        public TaxLines(OrderItem Olitem){
            this.Sku = String.valueOf(Olitem.Product_Name__c);
            this.Quantity = String.valueOf(Olitem.Quantity);
            if(Olitem.Parent_Order_Line_Id__c != null){
                this.ReferenceLineId = String.valueOf(Olitem.Parent_Order_Line_Id__c);
            }else{
                this.ReferenceLineId = '';
            }
            
            this.Price = String.valueOf(Olitem.Unitprice);
            this.LineId = String.valueOf(Olitem.Id);
        }
    }
    
    public class TaxHeader{
        
        public string CurrencyCode;
        public string OrderSource;
        public string ShipToProvince;
        public string BillToAccountReference;
        public string ShipToAccountReference;
        
        public TaxHeader(Order objOrder){
            System.debug('**EBS--TaxHeader======'+objOrder);
            this.CurrencyCode = objOrder.CurrencyIsoCode; 
            this.OrderSource = 'Ecom-CA'; // objOrder.System_Of_Origin__c;
            this.ShipToProvince = getProvinceCode(String.valueOf(objOrder.Customer_Ship_To_Address__r.State__c)); 
            this.BillToAccountReference = objOrder.Payor__c != null ? objOrder.Payor__c :   objOrder.Customer_Bill_To_Address__r.Account__c;
            this.ShipToAccountReference = objOrder.Customer_Ship_To_Address__r.Account__c;
        }
        
        public String getProvinceCode(String stateProvince){
            String ShipToProvinceCode = '';
            if (stateProvince.equalsIgnoreCase('Alberta')) ShipToProvinceCode = 'AB';
            if (stateProvince.equalsIgnoreCase('British Columbia')) ShipToProvinceCode = 'BC';
            if (stateProvince.equalsIgnoreCase('Manitoba')) ShipToProvinceCode = 'MB';
            if (stateProvince.equalsIgnoreCase('New Brunswick')) ShipToProvinceCode = 'NB';
            if (stateProvince.equalsIgnoreCase('Newfoundland and Labrador')) ShipToProvinceCode = 'NL';
            if (stateProvince.equalsIgnoreCase('Northwest Territories')) ShipToProvinceCode = 'NT';
            if (stateProvince.equalsIgnoreCase('Nova Scotia')) ShipToProvinceCode = 'NS';
            if (stateProvince.equalsIgnoreCase('Nunavut')) ShipToProvinceCode = 'NU';
            if (stateProvince.equalsIgnoreCase('Ontario')) ShipToProvinceCode = 'ON';
            if (stateProvince.equalsIgnoreCase('Prince Edward Island')) ShipToProvinceCode = 'PE';
            if (stateProvince.equalsIgnoreCase('Quebec')) ShipToProvinceCode = 'QC';
            if (stateProvince.equalsIgnoreCase('Saskatchewan')) ShipToProvinceCode = 'SK';
            if (stateProvince.equalsIgnoreCase('Yukon Territories')) ShipToProvinceCode = 'YT';
            if (stateProvince.equalsIgnoreCase('Yukon')) ShipToProvinceCode = 'YT';
            return ShipToProvinceCode;
        }
    }
    
    
    // Reponse Parse Classes ----  
    public class EBSResponseWrapper {        
        public List<TaxSummary> TaxSummary;
        public List<TaxDetails> TaxDetails;
        public String ErrorMessage;
    }
    
    public class TaxDetails {
        public String LineId;
        public String Price;
        public String Quantity;
        //public String ReferenceLineId;
        public String Sku;
        public String TaxType;
        public String TaxAmount;
    }
    
    public class TaxSummary {
        public String TaxType;
        public String TaxRate;
        public String TaxAmount;
    }
    
    // Callout Method for Canada Tax API Call
    public static String makeEBSCallOut(Order objOrder){
        try{
            //String requestBody = JSON.serialize(new RequestWrapper(objOrder));
            string requestBody=Json.serialize(new RequestWrapper(objOrder), true).replace('"CurrencyCode"','"Currency"');
            system.debug('**EBS--Request Body is-->' + requestBody);
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:EBSTaxCalculatorNC');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
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
            System.debug('**makeEBSCallOut-ErrLine--'+ex.getLineNumber());
            System.debug('**ErrMsg--'+ex.getMessage());
            return 'ERROR';
        }
    }
}