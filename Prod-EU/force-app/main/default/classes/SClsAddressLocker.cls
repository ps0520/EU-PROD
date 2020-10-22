global class SClsAddressLocker implements Schedulable {
    global void execute(SchedulableContext SC) {
        BClsAddressLocker sch = new BClsAddressLocker();
        Database.executebatch(sch, 10);
    }
}