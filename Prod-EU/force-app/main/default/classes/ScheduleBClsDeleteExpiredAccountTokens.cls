global  class ScheduleBClsDeleteExpiredAccountTokens implements Schedulable {
   global void execute(SchedulableContext BCDeleteExpitedTokens) {
      BClsDeleteExpiredAccountTokens  deleteExpiredAccountTokens= new BClsDeleteExpiredAccountTokens();
      database.executeBatch(deleteExpiredAccountTokens);
   }
}