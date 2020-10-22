/****************************************************************************************************************
@Author        : Jagan Periyakaruppan
@Date Created    : 4/30/2017
@Description    : Static class used in the address update trigger to control the address change from Account and Address objects
****************************************************************************************************************/
public class ClsAccountAddressTriggerStaticClass {
    public static boolean addressChangeInvokedFromAccount = true;
    public static boolean addressChangeInvokedFromAddress = true;
    public static boolean medFacChangedInvokedFromPrescriber = true;
    public static boolean medFacChangedInvokedFromRelatedAccount = true;
    public static boolean invokeMILogicOnlyOnce = true;
}