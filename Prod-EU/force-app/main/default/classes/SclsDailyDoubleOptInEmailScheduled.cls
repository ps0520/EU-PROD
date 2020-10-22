/**
 * SclsDailyDoubleOptInEmailScheduled
 * @author Craig Johnson(Sundog)
 * @date 06/13/2019
 */
global class SclsDailyDoubleOptInEmailScheduled implements Schedulable{
    public static String CRON_EXP = '0 0 1 * * ?'; //currently set for 1 AM daily

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BclsDailyDoubleOptInEmailBatch(), 10);
    }

    // to kick off the job without using the UI, execute following in an anonymous window:
    // System.schedule('BclsDailyDoubleOptInEmailBatch', SclsDailyDoubleOptInEmailScheduled.CRON_EXP, new SclsDailyDoubleOptInEmailScheduled());
}