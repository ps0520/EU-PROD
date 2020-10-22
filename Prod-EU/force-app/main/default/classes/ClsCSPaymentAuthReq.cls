public class ClsCSPaymentAuthReq{
        public paymentInformation paymentInformation{get;set;}
        public processingInformation processingInformation{get;set;}
        public orderInformation orderInformation{get;set;}
        public clientReferenceInformation clientReferenceInformation{get;set;}
    public class tokenizedCard{
        public String expirationYear{get;set;}
        public String expirationMonth{get;set;}
    }
    public class processingInformation{
        public String commerceIndicator{get;set;}
        public boolean capture{get;set;}
    }
    public class paymentInformation{
        public tokenizedCard tokenizedCard{get;set;}
        public customer customer{get;set;}
    }
    public class orderInformation{
        public amountDetails amountDetails{get;set;}
        public billTo billTo{get;set;}
    }
    public class customer{
        public String customerId{get;set;}
    }
    public class clientReferenceInformation{
        public String code{get;set;}
    }
    public class billTo{
        public String address1{get;set;}
        public String administrativeArea{get;set;}
        public String locality{get;set;}
        public String postalCode{get;set;}
        public String lastName{get;set;}
        public String country{get;set;}
        public String firstName{get;set;}
        public String email{get;set;}
        public String phoneNumber{get;set;}
    }
    public class amountDetails{
        public String currToRep{get;set;}
        public String totalAmount{get;set;}
    }
}