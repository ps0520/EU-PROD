global class SClsIESSIPBatchScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        BClsSSIPSchedule sch = new BClsSSIPSchedule(Date.Today(), Date.Today(),'Ireland',null);
        Database.executebatch(sch, 1);
    }
}