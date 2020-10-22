({
	getVATData : function(component, event, helper) {
    	console.log('**** recId=' + component.get("v.recordId"));
        var action = component.get("c.getVATData");
        action.setParams({ 'accId' : component.get("v.recordId")
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var acc = response.getReturnValue();
                console.log('*** acc=' + JSON.stringify(acc));
				component.set("v.isValid", acc.VAT_Valid__c); component.set("v.VatNum", acc.Tax_Registration_Number__c);                
            }
        });
        $A.enqueueAction(action);
    },
})