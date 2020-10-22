({
	doInit : function(component, event, helper){
        var recordid = component.get("v.recordId");
        if(!$A.util.isUndefined(recordid) && !$A.util.isEmpty(recordid) 
           && recordid.length > 0){ 
            if(recordid.substr(0,3) == '006'){
            //    alert('account');
                component.set("v.isOppRec",true);
                helper.getPayor(component);
        	}  else {
                component.set("v.isOppRec",false);
                return
            }
        }
    },
})