public class PEClsHandleAddressEventsStatic {
    public static boolean AddressPublish = true;
    public static boolean firstEventPublish() {
        if (AddressPublish) {AddressPublish = false; return true;} else return false;
    }
}