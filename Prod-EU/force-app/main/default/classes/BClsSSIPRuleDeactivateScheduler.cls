global class BClsSSIPRuleDeactivateScheduler implements Schedulable{
	global void execute(SchedulableContext SC) {
        Database.executeBatch(new BClsSSIPRuleDeactivate(), 100);
    }
}