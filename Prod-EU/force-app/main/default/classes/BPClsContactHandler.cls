/*******************************************************************************************************************
@Author         : Shailendra Singh Lodhi
@Date Created   : 13/6/2019
@Description    : Trigger invokes handler class to process Currency
********************************************************************************************************************/   
public class BPClsContactHandler {
    public void onBeforeInsert(List<Contact> lstContact){
        Map<Id, RecordType> mapRecordType = new Map<Id, RecordType>([SELECT Id, DeveloperName, Name FROM RecordType WHERE DeveloperName LIKE 'CA_%' AND SobjectType = 'Contact']);
        for(Contact objContact : lstContact){
            if(mapRecordType.containsKey(objContact.RecordTypeId) && mapRecordType.get(objContact.RecordTypeId).DeveloperName.startsWithIgnoreCase('CA_')){
                objContact.CurrencyIsoCode = 'CAD';
            }
        }
    }
}