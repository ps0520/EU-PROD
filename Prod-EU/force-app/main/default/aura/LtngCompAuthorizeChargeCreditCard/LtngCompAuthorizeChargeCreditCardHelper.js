({
	authorizeChargeCC : function(component, event) {
        component.set("v.isLoading", true);
        var action = component.get("c.ccAuthorizeAndSettlePayment");
        action.setParams({ oId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            console.log('QueryAccess Response: ' + response);
            var state = response.getState();
            console.log('state: ' + state);
            if (state === "SUCCESS") {
                var message = response.getReturnValue();
                var className = message.toLowerCase().indexOf("error") !== -1 ? 'slds-theme_error' : 'slds-theme_success';
                component.set("v.className", className);
                component.set("v.message", message);
            }else{
                component.set("v.className", 'slds-theme_error');
                component.set("v.message",'Error! Please contact System Admin!');
            }  
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(action);
	},
})