global class SClsSSIPBatchScheduler implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new BClsSSIPSchedule(), 10);
    }
}