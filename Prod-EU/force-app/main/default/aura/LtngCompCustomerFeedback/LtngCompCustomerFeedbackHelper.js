({
	getAccData : function(component, event, helper) {
         var action = component.get("c.getAccountDetails");
        	action.setParams({ 'accRecId' : component.get("v.recordId")
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var acc = response.getReturnValue();
				component.set("v.accName", acc.Name); 
                component.set("v.accountId", acc.Id);
            }
        });
        $A.enqueueAction(action);
	},
    
    getCFPicklist : function(component, event, helper) {
        var action = component.get("c.getCFTypePicklist");
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();                
                var typeMap = [];
                for(var key in result ){
                    typeMap.push({key:key,value:result[key]});  
                }
                component.set("v.CFTypes", typeMap);
            }
        });
        $A.enqueueAction(action);
	}
})