({
	getCustFeedback : function(component, event, helper) {
		var action = component.get("c.getCustomerFeedbackDetails");
        action.setParams({ 'accRecordId' : component.get("v.recordId")
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var rows = response.getReturnValue();
                 /*rows.forEach(function(record){
                     
                     var editRecordEvent = $A.get("e.force:editRecord");
                     editRecordEvent.setParams({
                         "recordId": record.id
                     });
                     editRecordEvent.fire();
                });*/
				component.set("v.data", rows);
            }
        });
        $A.enqueueAction(action);
	}
})