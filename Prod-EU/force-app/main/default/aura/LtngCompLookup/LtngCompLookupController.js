({
    doInit: function(component, event, helper) {
     
     	var ownerId = component.get("v.userOwnId");
         var action = component.get("c.searchUser");
                action.setParams({
                    "userId": ownerId
                });
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var result = response.getReturnValue();
                        component.set("v.selectedResult", result);
                        component.set("v.value", component.get("v.selectedResult.Id"));
                        $A.util.removeClass(component.find('lookup'), 'slds-is-open');
                    }else{
                        alert('Error Occured--');
                    }
                });
                $A.enqueueAction(action);
    },
    valueChange: function(component, event, helper) {
        if ($A.util.isEmpty(event.getParam("value"))) {
            return;
        }
        var action = component.get("c.loadDefault");
        action.setParams({
            "s": component.get("v.value"),
            "sObjectType": component.get("v.sObjectType")
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.selectedResult", response.getReturnValue());
                component.set("v.value", component.get("v.selectedResult.Id"));
            } else {
                console.log(response.getError());
                component.set("v.value", null);
            }
        });
        $A.enqueueAction(action);
        event.stopPropagation();
    },
    lookup_typeahead: function(component, event, helper) {
        var action = component.get("c.searchLookup");
        action.setAbortable();
        action.setParams({
            "s": component.find("searchInput").get("v.value"),
            "sObjectType": component.get("v.sObjectType")
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.searchResults", response.getReturnValue());
            } else {
                console.log(response.getError());
            }
        });
        $A.util.addClass(component.find('lookup'), 'slds-is-open');
        $A.enqueueAction(action);
    },
    
    lookup_show: function(component, event, helper) {
        $A.util.addClass(component.find('lookup'), 'slds-is-open');
    },
    lookup_hide: function(component, event, helper) {
        setTimeout(function() {
            $A.util.removeClass(component.find('lookup'), 'slds-is-open');
        }, 1);
    },
    
    lookup_select: function(component, event, helper) {
        component.set("v.selectedResult", component.get("v.searchResults["+event.currentTarget.id+"]"));
        component.set("v.value", component.get("v.selectedResult.Id"));
        $A.util.removeClass(component.find('lookup'), 'slds-is-open');
    },
    
    lookup_unselect: function(component, event, helper) {
        component.set("v.selectedResult", null);
        component.set("v.searchString", null);
        component.set("v.searchResults", null);
        component.set("v.value", null);
    }
})