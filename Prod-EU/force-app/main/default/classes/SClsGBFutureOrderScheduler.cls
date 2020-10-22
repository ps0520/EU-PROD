global class SClsGBFutureOrderScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        BClsFutureOrderHandler sch = new BClsFutureOrderHandler(Date.Today(), Date.Today(),'GB',null,null);
        Database.executebatch(sch, 1);
    }
}