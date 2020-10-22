public class ClsConstants {

    //Account Record Types
    public static final string ACCOUNT_DE_PRESCRIBER_RECORDTYPE_NAME = Label.Account_DE_Prescriber_RecordType_Name;
    public static final string ACCOUNT_CA_PRESCRIBER_RECORDTYPE_NAME = Label.Account_CA_Prescriber_RecordType_Name;
    public static final string ACCOUNT_DE_MEDICAL_FACILITY_RECORDTYPE_NAME = Label.Account_DE_Medical_Facility_RecordType_Name;
    public static final string ACCOUNT_CA_MEDICAL_FACILITY_RECORDTYPE_NAME = Label.Account_CA_Medical_Facility_RecordType_Name;
   
    public static final string ACCOUNT_DE_PRESCRIBER_RECORDTYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.Account_DE_Prescriber_RecordType_Name).getRecordTypeId();
    public static final string ACCOUNT_DE_MEDICAL_FACILITY_RECORDTYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.Account_DE_Medical_Facility_RecordType_Name).getRecordTypeId(); 
    
    //Validation Request Record Types
    public static final string VALIDATION_REQUEST_ACTIVITY_RECORDTYPE_NAME = Schema.SObjectType.QIDC__Validation_Request_ims__c.getRecordTypeInfosByName().get('Activity').getRecordTypeId();
    public static final string VALIDATION_REQUEST_WORKPLACE_RECORDTYPE_NAME = Schema.SObjectType.QIDC__Validation_Request_ims__c.getRecordTypeInfosByName().get('Workplace').getRecordTypeId();  
    
    //Country codes
    public static final string GERMANY_COUNTRY_CODE = Label.Germany_Country_Code;
    public static final string CANADA_COUNTRY_CODE = Label.Canada_Country_Code;
    
    //VR Request Types
    public static final string REQUEST_TYPE_NEW = Label.New;
    public static final string REQUEST_TYPE_UPDATE = Label.Update;
}