global class SClsIEFutureOrderScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        BClsFutureOrderHandler sch = new BClsFutureOrderHandler(Date.Today(), Date.Today(),'IE',null,null);
        Database.executebatch(sch, 1);
    }
}