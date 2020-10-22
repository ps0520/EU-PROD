global class SClsGBSSIPBatchScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        BClsSSIPSchedule sch = new BClsSSIPSchedule(Date.Today(), Date.Today(),'United Kingdom',null);
        Database.executebatch(sch, 1);
    }
}