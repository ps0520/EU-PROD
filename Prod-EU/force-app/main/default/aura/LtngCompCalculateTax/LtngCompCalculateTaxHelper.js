({
	calculateTax : function(cmp) {
        var action = cmp.get("c.calculateTax");
        action.setParams({ 
            OrderId : cmp.get("v.recordId")
        });
		action.setCallback(this, function(response) {
            console.log('QueryAccess Response: ' + response);
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('Tax Calculated');
               /* 
                var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'Tax Calculation Result',
                            message: response.getReturnValue(),
                            duration:'5000',
                            type: 'success',
                            mode: 'dismissible'
                        });
                toastEvent.fire();
                */
                cmp.set("v.isComplete", true);
                cmp.set("v.message",response.getReturnValue());
            }                
		});
        $A.enqueueAction(action);
    },
})