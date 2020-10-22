/**
 * SclsHourlyDoubleOptInScheduled
 * @author Craig Johnson(Sundog)
 * @date 06/13/2019
 */
global class SclsHourlyDoubleOptInScheduled implements Schedulable{
    public static String CRON_EXP = '0 0 * * * ?'; //currently set to run on the hour

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BclsHourlyDoubleOptInBatch(), 5);
    }

    // to kick off the job without using the UI, execute following in an anonymous window:
    // System.schedule('BclsHourlyDoubleOptInBatch', SclsHourlyDoubleOptInScheduled.CRON_EXP, new SclsHourlyDoubleOptInScheduled());

}