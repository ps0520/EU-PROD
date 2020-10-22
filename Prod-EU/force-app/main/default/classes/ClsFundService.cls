/*****************************************************************************
@Description    : Fund service provide methods for all Fund related operations
*******************************************************************************/
public class ClsFundService {
    
	//Method checks if there are sufficient fund
    public static String getPONumber(Id fundId){
		return [SELECT PO_Reference_Number__c FROM Fund__c WHERE Id = : fundId].PO_Reference_Number__c;
	}
	
	//Method checks if there are sufficient fund
    public static String checkFundBalance(Id orderId){
		String message = 'Success';
		//Get the Order reference
		Order o = [SELECT Id, Total_Gross_Price__c, Fund__c, Fund__r.Is_Fund_Active__c, Fund__r.Limit_Type__c, Fund__r.Sensor_Qty_Remaining__c, Fund__r.Transmitter_Qty_Remaining__c, Fund__r.Receiver_Qty_Remaining__c, Fund__r.Amount_Remaining__c, (SELECT Id, Product_Name__c, Quantity FROM OrderItems) FROM Order Where Id = : orderId];
		System.debug('**fund--'+o.Fund__r.Is_Fund_Active__c);
        //Check if fund is active
		if(!o.Fund__r.Is_Fund_Active__c) return 'Fund is not active, please choose a valid Fund';
		
		//Go over the Products associated to the Order and check if there are enough qty available
		for(OrderItem oi : o.OrderItems){
			//If the limit type is enforce as Quantity at the fund level then check below conditions
			if(o.Fund__r.Limit_Type__c == 'Quantity')
			{
                //Check for Sensor
				if(oi.Product_Name__c.startsWithIgnoreCase('STS') && o.Fund__r.Sensor_Qty_Remaining__c < oi.Quantity) message = 'Fund does not have sufficient Sensor Qty availble';
				//Check for Transmitter
				if(oi.Product_Name__c.startsWithIgnoreCase('STT') && o.Fund__r.Transmitter_Qty_Remaining__c < oi.Quantity) message = 'Fund does not have sufficient Transmitter Qty availble';
				//Check for Sensor
				if(oi.Product_Name__c.startsWithIgnoreCase('STK') && o.Fund__r.Receiver_Qty_Remaining__c < oi.Quantity) message = 'Fund does not have sufficient Receiver Qty availble';
			}
			//If the limit type is enforce as Amount at the fund level then check below conditions
			if(o.Fund__r.Limit_Type__c == 'Amount')
				if(o.Fund__r.Amount_Remaining__c < o.Total_Gross_Price__c) message = 'Fund does not have sufficient amount availble';
		}
		return message;
	}
	//Method charges the fund
    public static String chargeFund(Id orderId){
		String message = 'Success';
		//Get the Order reference
		Order o = [SELECT Id, Total_Gross_Price__c, Fund__c, Fund__r.Limit_Type__c, Fund__r.Sensor_Qty_Used__c, Fund__r.Transmitter_Qty_Used__c, Fund__r.Receiver_Qty_Used__c, Fund__r.Amount_Used__c, (SELECT Id, Product_Name__c, Quantity FROM OrderItems) FROM Order Where Id = : orderId];
		//Fund to be updated
		Fund__c f = new Fund__c(Id = o.Fund__c);
		//Go over the Products associated to the Order and deduct the corresponding qty
		for(OrderItem oi : o.OrderItems){
			//Increase the used qty of sensor
			if(oi.Product_Name__c.startsWithIgnoreCase('STS')) {
                Integer calculatedQty = oi.Product_Name__c == 'STS-GS-003' ? Integer.ValueOf(oi.Quantity*3) : Integer.ValueOf(oi.Quantity);
                f.Sensor_Qty_Used__c = o.Fund__r.Sensor_Qty_Used__c == null ? calculatedQty : o.Fund__r.Sensor_Qty_Used__c + calculatedQty;
            }
			//Increase the used qty of transmitter
			if(oi.Product_Name__c.startsWithIgnoreCase('STT')) f.Transmitter_Qty_Used__c = o.Fund__r.Transmitter_Qty_Used__c == null ? oi.Quantity : o.Fund__r.Transmitter_Qty_Used__c + oi.Quantity;
			//Increase the used qty of receiver
			if(oi.Product_Name__c.startsWithIgnoreCase('STK')) f.Receiver_Qty_Used__c = o.Fund__r.Receiver_Qty_Used__c == null ? oi.Quantity : o.Fund__r.Receiver_Qty_Used__c + oi.Quantity;
		}
		//Deduct the amount
		f.Amount_Used__c = o.Fund__r.Amount_Used__c == null ? o.Total_Gross_Price__c : (o.Fund__r.Amount_Used__c + o.Total_Gross_Price__c);

		//Update Fund
		try { update f;
			} catch (DmlException de) {
				if(de.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) message = de.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').substringBefore('[');
				return message;
			}
        return message;
	}
}