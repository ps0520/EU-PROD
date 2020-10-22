public class PEClsHandleAccountEventsStatic {
	public static boolean accountPublish = true;
    public static boolean firstEventPublish() {
        if (accountPublish) {accountPublish = false; return true;} else return false;
    }
}