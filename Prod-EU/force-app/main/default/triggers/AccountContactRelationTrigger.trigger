trigger AccountContactRelationTrigger on AccountContactRelation (after update, after insert) {
/**************************************************************************************
@Description    : Trigger invokes handler class to process AccountContactRelation logic
***************************************************************************************/
    if(trigger.isAfter)
        ClsAccountRelatedContactTriggerHandler.processPrimaryContact(trigger.newMap, trigger.oldMap);
}