({
	doInit : function(component, event, helper) {
		helper.calculateTax(component);
	},
    handleClose : function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
        $A.get('e.force:refreshView').fire();
	},
})