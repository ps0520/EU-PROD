/*******************************************************************************************************************
@Author         : Shailendra Singh Lodhi
@Date Created   : 13/6/2019
@Description    : Trigger invokes handler class to process Currency
********************************************************************************************************************/    
trigger ContactTrigger on Contact (before insert) {
    if(Trigger.isBefore && Trigger.isInsert){
        new BPClsContactHandler().onBeforeInsert(Trigger.new);
    }
}