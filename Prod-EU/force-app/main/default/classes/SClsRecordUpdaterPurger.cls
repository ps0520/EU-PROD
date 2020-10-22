global class SClsRecordUpdaterPurger implements Schedulable {
    global void execute(SchedulableContext SC) {
        BClsRecordUpdaterPurger sch = new BClsRecordUpdaterPurger();
        Database.executebatch(sch, 100);
    }
}