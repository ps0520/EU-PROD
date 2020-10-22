global class SClsCleanDuplicateOkRelAccnts implements Schedulable {
    global void execute(SchedulableContext SC) {
        BClsClearDuplicateChildAccounts batchClass = new BClsClearDuplicateChildAccounts();
        Database.executebatch(batchClass, 200);
    }
}