global class SClsCASSIPBatchScheduler implements Schedulable {    
	global void execute(SchedulableContext SC) {
        BClsSSIPSchedule sch = new BClsSSIPSchedule(Date.Today(), Date.Today(),'Canada',null);
        Database.executebatch(sch, 1);
    }
}