global class SClsSendContractForGBIEOppScheduler implements Schedulable{
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BClsSendContractForGBIEOpp(null), 1); // set scope to 1 only.
    }
}