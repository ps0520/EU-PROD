global class SClsSSIPRuleDeactivate implements Schedulable {
    global void execute(SchedulableContext SC) {
        BClsSSIPRuleDeactivate sch = new BClsSSIPRuleDeactivate(Date.today().addDays(-1), Date.Today());
        Database.executebatch(sch, 1);
    }
}