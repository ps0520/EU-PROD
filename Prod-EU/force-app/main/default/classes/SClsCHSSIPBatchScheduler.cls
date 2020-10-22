global class SClsCHSSIPBatchScheduler implements Schedulable {    
    global void execute(SchedulableContext SC) {
        BClsSSIPSchedule sch = new BClsSSIPSchedule(Date.Today(), Date.Today(),'Switzerland',null);
        Database.executebatch(sch, 1);
    }
}