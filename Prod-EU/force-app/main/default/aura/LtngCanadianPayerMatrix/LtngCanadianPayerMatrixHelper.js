({
	getPayor : function(component) {
		var recordid = component.get("v.recordId");
        var action = component.get("c.getAccountId");
        action.setParams({ "recid" : recordid
                         });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var result=response.getReturnValue();
                if (result != null) {
                    component.set("v.accountId",result);
                    component.set("v.isAccRecKnown", true);
                }
            }
        });
        $A.enqueueAction(action);
	}
})