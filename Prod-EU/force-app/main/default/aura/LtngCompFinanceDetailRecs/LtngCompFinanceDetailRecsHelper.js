({
	getCCData : function(component, event, helper) {
        console.log('**** recId=' + component.get("v.recordId"));
        var action = component.get("c.getCCData");
        action.setParams({ 'accId' : component.get("v.recordId")
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var rows = response.getReturnValue();
                rows.forEach(function(record){
                    record.linkName = '/'+record.Id;
					if (record.Primary__c) record.primaryIconName = 'action:approval';
                });
				component.set("v.data", rows);
            }
        });
        $A.enqueueAction(action);
    },
})