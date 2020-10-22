global class SclsMarketingInteractionGBIEScheduled implements Schedulable{
    public static String CRON_EXP = '0 0 1 * * ?'; //currently set for 1 AM daily

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BclsMarketingInteractionGBIEBatch(), 10);
    }

    // to kick off the job without using the UI, execute following in an anonymous window:
    // System.schedule('BclsMarketingInteractionGBIEBatch', SclsMarketingInteractionGBIEScheduled.CRON_EXP, new SclsMarketingInteractionGBIEScheduled());
}