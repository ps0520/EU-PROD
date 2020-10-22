public class ClsCCAuthAndSettlementResponse {    
   
    public string paymentId;
    public string settlementId;
    public string approvalCode;
    public decimal authorizedAmount;
    public enumStatus status;
    public string error;
    public string transStatus;
    public decimal refundAmount;
    public string refundRefNum;
    public DateTime refundDate;
    public ClsCCAuthAndSettlementResponse(){}	
	public enum enumStatus {NA, ERROR, SUCCESS }
}