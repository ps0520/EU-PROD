global class SClsSendDistributorSOAAtt implements Schedulable {
    global void execute(SchedulableContext SC) {
        BClsSendDistributorSOAAtt sch = new BClsSendDistributorSOAAtt();
        Database.executebatch(sch, 1);        
    }
}