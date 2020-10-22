({
    handleSelect : function (component, event, helper) {     
        
        
        var stepName = event.getParam("detail").value;
        component.set("v.picklistField.Invoice_Status__c",stepName);

        component.find("record").saveRecord($A.getCallback(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                component.find('notifLib').showToast({
                    "variant": "success",
                    "message": "Record was updated sucessfully",
                    "mode" : "pester"
                });
            } else {
                component.find('notifLib').showToast({
                    "variant": "error",
                    "message": "You cannot perform this action.",
                    "mode" : "pester"
                });
            }
        }));
        
    },
    recordUpdated : function(component, event, helper) {
        
        var changeType = event.getParams().changeType;
        
        if (changeType === "ERROR") { /* handle error; do this first! */ }
        else if (changeType === "LOADED") { /* handle record load */ }
            else if (changeType === "REMOVED") { /* handle record removal */ }
                else if (changeType === "CHANGED") { 
                    /* handle record change; reloadRecord will cause you to lose your current record, including any changes you’ve made */ 
                    component.find("record").reloadRecord();
                }
    }
    
    
    
})