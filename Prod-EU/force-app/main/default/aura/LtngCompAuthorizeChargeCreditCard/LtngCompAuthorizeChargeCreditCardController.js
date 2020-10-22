({
	doInit : function(component, event, helper) {
		helper.authorizeChargeCC(component, event);
	},
    handleClose : function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
        $A.get('e.force:refreshView').fire();
	},
})