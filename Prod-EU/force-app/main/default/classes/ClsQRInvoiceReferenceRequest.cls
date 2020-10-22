public class ClsQRInvoiceReferenceRequest {
/***********************************************************************
@Description    : Prepares the request to invoke the CH QR Bill Service
************************************************************************/

	public class AdditionalInformation {
		public String unstructuredMessage;
		public String billInformation;
	}

	public class PaymentReference {
		public String referenceType;
		public String reference;
		public AdditionalInformation additionalInformation;
	}

	public CreditorInformation creditorInformation;
	public PaymentAmountInformation paymentAmountInformation;
	public Creditor ultimateDebtor;
	public PaymentReference paymentReference;
	public AlternativeSchemes alternativeSchemes;

	public class CreditorInformation {
		public String iban;
		public Creditor creditor;
	}

	public class Creditor {
		public String addressType;
		public String name;
		public String streetName;
		public String houseNumber;
		public String postalCode;
		public String city;
		public String country;
	}

	public class PaymentAmountInformation {
		public Double amount;
		public String currencyValue;
	}

	public class AlternativeSchemes {
		public List<String> alternativeSchemeParameters;
	}

	
	public static ClsQRInvoiceReferenceRequest parse(String json) {
		return (ClsQRInvoiceReferenceRequest) System.JSON.deserialize(json, ClsQRInvoiceReferenceRequest.class);
	}
}