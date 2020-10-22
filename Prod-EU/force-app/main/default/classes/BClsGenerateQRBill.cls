/************************************************************************************************************
Batch Class will be used to reach out to external API to get the QR Bill and associate the same to the Order
*************************************************************************************************************/
global class BClsGenerateQRBill implements Database.Batchable<sObject>, Database.AllowsCallouts {
    private String query; 

    global BClsGenerateQRBill (String soql){
        query = soql;
    }
    global Database.QueryLocator start(Database.BatchableContext info) {
        return Database.getQueryLocator(query);      
    }
    //Method to execute the batch Account Territory Alignment 
    global void execute(Database.BatchableContext info, List<Order> scope) {
        //Get the details about the QR Bill Metadata
        List<QR_Bill_Mapping__mdt> qrBillMappingList = new List<QR_Bill_Mapping__mdt>([SELECT URL__c, Payment_Reference_URL__c, Format_Payment_Reference__c, API_Token__c, Boundary_Lines__c, Boundary_Line_Scissors__c, Boundary_Line_Separation_Text__c, Font_Family__c, Page_Size__c, Resolution__c FROM QR_Bill_Mapping__mdt]);
        Map<String, ContentVersion> orderToQRBillMap = new Map<String, ContentVersion>();//Map the Order Id to the ContetVersion Document
        Map<Id, Order> ordersToBeUpatedWithQRFlagMap = new Map<Id, Order>();//Order map that will be used to update the QR Bill Generated flag on Order
        Set<Id> newContentVersionIds = new Set<Id>();//Set holds the Content Versions that were created
        List<ContentDocumentLink> contentDocLinkToBeCreatedList = new List<ContentDocumentLink>();//List of CDL that are to be inserted
        if(!qrBillMappingList.isEmpty()){
            //Prepare the URL to be invoked 
            QR_Bill_Mapping__mdt qrBillMap = qrBillMappingList[0];
            String finalURL;
            String finalPaymentRefURL;
            String url = qrBillMap.URL__c;
            String apiToken = qrBillMap.API_Token__c;
            Boolean boundaryLineScissors = qrBillMap.Boundary_Line_Scissors__c;
            Boolean boundaryLineSeparationText = qrBillMap.Boundary_Line_Separation_Text__c;
            Boolean boundaryLines = qrBillMap.Boundary_Lines__c;
            String fontFamily = qrBillMap.Font_Family__c;
            String pageSize = qrBillMap.Page_Size__c;
            String resolution = qrBillMap.Resolution__c;
            String preferredLangCode = 'de';//Default is Germany
            finalURL = url+'boundaryLineScissors='+boundaryLineScissors+'&boundaryLineSeparationText='+boundaryLineSeparationText+'&boundaryLines='+boundaryLines+'&fontFamily='+fontFamily+'&pageSize='+pageSize+'&resolution='+resolution+'&api_key='+apiToken;
            
            //Details required to retrieve the Payment Reference
            String paymentRefURL = qrBillMap.Payment_Reference_URL__c;
            Boolean formatQrReference = qrBillMap.Format_Payment_Reference__c;
            finalPaymentRefURL = paymentRefURL+'formatQrReference='+formatQrReference+'&api_key='+apiToken;
            
            //Get the details about the Dexcom Billing Address
            List<Dexcom_Invoice_Billing_Address__mdt> dxcmInvoiceBillingAddrList = new List<Dexcom_Invoice_Billing_Address__mdt>([SELECT DeveloperName, Company_Name__c, IBAN__c, Street__c, City__c, Postal_Code__c, Country_Code__c FROM Dexcom_Invoice_Billing_Address__mdt]);
            Map<String, Dexcom_Invoice_Billing_Address__mdt> dxcmInvoiceBillingAddrMap = new Map<String, Dexcom_Invoice_Billing_Address__mdt>();
            for(Dexcom_Invoice_Billing_Address__mdt recd : dxcmInvoiceBillingAddrList){
                if(recd.Country_Code__c == 'CH')
                    dxcmInvoiceBillingAddrMap.put('CH', recd);
            }

            //For each order in the scope, create the QR Bill
            for(Order orderRecd : scope){
                //Get the Preferred Language
                if(orderRecd.Preferred_Language__c != null)
                	preferredLangCode = preferredLangCode != null ? orderRecd.Preferred_Language__c.mid(0,2) : 'de';

                //Get the Invoice Address Details for the country the Order belongs to
                Dexcom_Invoice_Billing_Address__mdt invoiceAddrDetails = new Dexcom_Invoice_Billing_Address__mdt();
                invoiceAddrDetails = dxcmInvoiceBillingAddrMap.get(orderRecd.BillingCountryCode);

                //Begin -- Prepare the JSON Request Body
                ClsQRInvoiceReferenceRequest qrBillAPIRequest = new ClsQRInvoiceReferenceRequest();
                
                //Prepare the Creditor Information
                ClsQRInvoiceReferenceRequest.CreditorInformation credInfo = new ClsQRInvoiceReferenceRequest.CreditorInformation();
                if(invoiceAddrDetails != null){
                    //credInfo.iban = 'CH4431999123000889012';
                    credInfo.iban = invoiceAddrDetails.IBAN__c;
                    ClsQRInvoiceReferenceRequest.Creditor creditor = new ClsQRInvoiceReferenceRequest.Creditor();
                    creditor.addressType = 'STRUCTURED';
                    creditor.name = invoiceAddrDetails.Company_Name__c;
                    creditor.streetName = invoiceAddrDetails.Street__c; 
                    //creditor.houseNumber = '18';
                    creditor.postalCode = invoiceAddrDetails.Postal_Code__c;
                    creditor.city = invoiceAddrDetails.City__c;
                    creditor.country = invoiceAddrDetails.Country_Code__c;
                    credInfo.creditor = creditor;
                }
                
                //Prepare the Payment Info Information
                ClsQRInvoiceReferenceRequest.PaymentAmountInformation paymentInfo = new ClsQRInvoiceReferenceRequest.PaymentAmountInformation();
                paymentInfo.amount =orderRecd.Format_Total_Gross_Price__c ; //eg. 1949.75
                paymentInfo.currencyValue = orderRecd.CurrencyIsoCode;//'CHF'
                
                //Prepare the Debitor Information
                ClsQRInvoiceReferenceRequest.Creditor debitor = new ClsQRInvoiceReferenceRequest.Creditor();
                debitor.addressType = 'STRUCTURED';
                //debitor.name = (orderRecd.Payor__r.Name == null || orderRecd.Payor__r.Name == '' ) ? orderRecd.Account.Name : orderRecd.Payor__r.Name;//Take the Payor else take the customer account eg.'Pia-Maria Rutschmann-Schnyder'
                if(orderRecd.Payor__c != null) //Get Payor related information
                    debitor.name = orderRecd.Payor__r.Name;
                else{
                    String careOfDetails = orderRecd.Customer_Bill_To_Address__r.Address_Line_2__c;
                    debitor.name = careOfDetails == null ? orderRecd.Account.Name : (careOfDetails.startsWith('C/O') ? orderRecd.Account.Name + ' ' + careOfDetails : orderRecd.Account.Name);
                }
                debitor.streetName = orderRecd.BillingStreet;//'Grosse Marktgasse 28'
                debitor.city = orderRecd.BillingCity;//'Rorschach'
                debitor.postalCode = orderRecd.BillingPostalCode;//'9400'
                debitor.country = orderRecd.BillingCountryCode;//'CH'
                
                //Prepare the Payment Reference Information
                ClsQRInvoiceReferenceRequest.paymentReference paymentRef = new ClsQRInvoiceReferenceRequest.paymentReference();
                paymentRef.referenceType = 'QRR';
                //The QR-Reference has 27 digits, the last one is a check digit. So, 26 digits remain to be used 
                String referenceNumberToCheck;
                String possibleZeros = '0';//variable holds possible 0's that can be added in
                String accNo = orderRecd.Account.AccountNumber;
                String invNo = orderRecd.Invoice_Number__c;
                Integer remainingNumbers = 26-(accNo.length()+invNo.length());
                for(Integer i=1; i<remainingNumbers; i++) possibleZeros+=0;
                referenceNumberToCheck = accNo + possibleZeros + invNo;

                //paymentRef.reference = '210000000003139471430009017';
                //paymentRef.reference = orderRecd.Account.AccountNumber+' '+orderRecd.Invoice_Number__c;
                //paymentRef.reference = orderRecd.Account.AccountNumber + ' ' + orderRecd.Invoice_Number__c + ' ' + orderRecd.Invoice_Date__c;
                
                //Invoke the call to retrieve the check digit. This is based on the algorithm.
                HttpRequest payRefreq = new HttpRequest();
                payRefreq.setEndpoint(finalPaymentRefURL);
                payRefreq.setHeader('Content-Type', 'text/plain');
                payRefreq.setMethod('POST');
                payRefreq.setbody(referenceNumberToCheck);
                Http payRefHttp = new Http();
                HTTPResponse payRefResponse = payRefHttp.send(payRefreq);
                if (payRefResponse.getStatusCode() == 200) 
                   paymentRef.reference =  payRefResponse.getBody();
                else
                    system.debug('*****DEBUG LOG - Payment Reference ' + referenceNumberToCheck + ' Invocation Failed');
                
                //Consolidate all to one call
                qrBillAPIRequest.CreditorInformation = credInfo;
                qrBillAPIRequest.paymentAmountInformation = paymentInfo;
                qrBillAPIRequest.ultimateDebtor = debitor;
                qrBillAPIRequest.paymentReference = paymentRef;
                string jsonString = JSON.serialize(qrBillAPIRequest);
                jsonString = jsonString.replace('"currencyValue":', '"currency":');
                system.debug('*****DEBUG LOG - JSON String to be sent to the API call ' + jsonString);
                //End -- Prepare the JSON Request Body

                //Invoke the API to get the QR Bill Image file
                HttpRequest req = new HttpRequest();
                req.setEndpoint(finalURL);
                req.setHeader('Accept', 'image/png');
                req.setHeader('Accept-Language', preferredLangCode);                
                req.setHeader('Content-Type', 'application/json');
                req.setMethod('POST');
                req.setbody(jsonString);
                Http http = new Http();
                HTTPResponse response = http.send(req);
                if (response.getStatusCode() == 200){
                    Blob qrBillImage = response.getBodyAsBlob();//Response received as a Blob
                    //Store the response as a content
                    ContentVersion qrBillImageFile = new ContentVersion();
                    qrBillImageFile.VersionData = qrBillImage;
                    qrBillImageFile.Title = 'QR Bill'; 
                    qrBillImageFile.ContentLocation= 's';
                    qrBillImageFile.PathOnClient='QRBillFile.png';
                    qrBillImageFile.Description = orderRecd.Id + ';' + paymentRef.reference;
                    orderToQRBillMap.put(orderRecd.Id, qrBillImageFile);
                }else
                    system.debug('*****DEBUG LOG - QR Bill Invocation Failed');
            }
            //Insert the Content Version Documents
            if(!orderToQRBillMap.isEmpty()){
                Database.SaveResult[] cvList = Database.insert(orderToQRBillMap.values(), false);
                // Iterate through each returned result
                for (Database.SaveResult cv : cvList) {
                    if (cv.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        newContentVersionIds.add(cv.getId());
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error err : cv.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Account fields that affected this error: ' + err.getFields());
                        }
                    }
                }
            }
            //Update the Order QR Bill Flag based on the Content Versions that was inserted
            if(!newContentVersionIds.isEmpty())
            {
                for(ContentVersion insertedCV : [SELECT Description, ContentDocumentId FROM ContentVersion WHERE Id IN : newContentVersionIds]){
                    //Get the record id and payment refernece values Description value on the content version will be concatened with ID ; PAYMENT REF
                    String concatString = insertedCV.Description;
                    List<String> concatStringLst = concatString.split(';', 2);
                    
                    //Add the Content Document Link based on the ContentVersion that was created    
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.LinkedEntityId = concatStringLst[0];
                    cdl.ContentDocumentId = insertedCV.ContentDocumentId;
                    cdl.shareType = 'V';
                    contentDocLinkToBeCreatedList.add(cdl);
                    
                    //Update the QR_Bill_Generated__c field on Order 
                    Order updateOrder = new Order(Id = concatStringLst[0], Generate_QR_Bill__c  = false, QR_Bill_Generated__c = true, QR_Bill_Payment_Reference__c = concatStringLst[1]);
                    ordersToBeUpatedWithQRFlagMap.put(updateOrder.Id, updateOrder);
                }
            }

            //Insert the ContentDocumentLink Records
            if(!contentDocLinkToBeCreatedList.isEmpty())
                insert contentDocLinkToBeCreatedList;
            //Update the Orders
            if(!ordersToBeUpatedWithQRFlagMap.isEmpty())
                update(ordersToBeUpatedWithQRFlagMap.values());


        }
        
    }
    //Finish Method
    global void finish(Database.BatchableContext BC)
    {}    
}