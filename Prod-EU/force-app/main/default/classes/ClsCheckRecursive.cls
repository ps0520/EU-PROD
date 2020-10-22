/****************************************************************************************************************
@Author        : Anuj Patel
@Date Created    : 05/19/2017
@Description    : Avoids recursive loop for Content logic
****************************************************************************************************************/
public Class ClsCheckRecursive {
    @TestVisible
    private static boolean run = true;
    public static boolean runOnce(){
    if(run){
     run=false;
     return true;
    }else{
        return run;
    }
    }
    
    public static string orderId;
    public static boolean isCSOrderUpdate=false;
}