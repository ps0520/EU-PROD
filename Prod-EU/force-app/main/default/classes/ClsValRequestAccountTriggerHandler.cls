/****************************************************************************************************************
@Author        : Pradeep Sadasivan
@Date Created    : 29/07/2020
@Description    : Validation Request Trigger Handler class.
****************************************************************************************************************/
public class ClsValRequestAccountTriggerHandler {
    public static Boolean firstRunComplete = false;
    //method to update Request Type and Country code on new VR's for DE and CA.
    public static void populateVRRequestType(List<QIDC__Validation_Request_ims__c> newVRList){
    for(QIDC__Validation_Request_ims__c newVR : newVRList){
            if(newVR.OK_Country_Code__c == ClsConstants.GERMANY_COUNTRY_CODE || newVR.OK_Workplace_Country_Code__c == ClsConstants.GERMANY_COUNTRY_CODE){
                newVR.QIDC__Country_ISO_Code_ims__c = ClsConstants.GERMANY_COUNTRY_CODE;
            }
            if(newVR.OK_Country_Code__c == ClsConstants.CANADA_COUNTRY_CODE || newVR.OK_Workplace_Country_Code__c == ClsConstants.CANADA_COUNTRY_CODE){
                newVR.QIDC__Country_ISO_Code_ims__c = ClsConstants.CANADA_COUNTRY_CODE;
            }   
    	}
    }
    //method to update Onekeyid on VR Approval of new Precriber Account
    public static void updateAccountOneKeyId(List<QIDC__Validation_Request_ims__c> updateVRList){
         if(firstRunComplete) return;
			firstRunComplete = true; 
    	List<Account> accountsToUpdate = new List<Account>();
    	Map<ID,QIDC__Validation_Request_ims__c> accountVrMap = new Map<ID,QIDC__Validation_Request_ims__c>();
        for(QIDC__Validation_Request_ims__c childIter :updateVRList ){
        	if(childIter.OK_Request_Type__c == 'New'){   
            	accountVrMap.put(childIter.QIDC__Individual_ims__c,childIter);
            }
        }
        Map<ID,Account> accountMap = new Map<ID,Account>([Select id,IQVIA_OneKeyId__c from Account where ID IN:accountVrMap.keyset()]);
        if(!accountMap.isEmpty()){
        	for(Account accIter : accountMap.values()){
            	QIDC__Validation_Request_ims__c  vr = accountVrMap.get(accIter.id);
             	accIter.IQVIA_OneKeyId__c = vr.QIDC__Validated_Ind_OneKeyID_ims__c;
             	accountsToUpdate.add(accIter);
             }
             try{
                 if(!accountsToUpdate.isEmpty())
                      System.debug('Line 38' + accountsToUpdate);
        	 	 	update accountsToUpdate;
        	}catch(system.DmlException de){
                System.debug('The following exception has occurred: ' + de.getMessage());
            }       
		}
    }
}