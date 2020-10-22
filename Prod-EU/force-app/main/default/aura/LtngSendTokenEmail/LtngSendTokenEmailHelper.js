({
    doInit : function(component, event, helper) {
        var msgSpan = component.find('warningPanel'); 
        var inputPanel = component.find('confirmationPanel'); 
        var action = component.get("c.getAccount");
        action.setParams({"accountId": component.get("v.recordId")});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var responseValue = response.getReturnValue();
                component.set("v.personEmail",responseValue.PersonEmail);
                if(responseValue.PersonEmail == null){
                    
                    $A.util.addClass(msgSpan, 'showPanel');
                    $A.util.removeClass(msgSpan, 'hidePanel');
                    
                    $A.util.addClass(inputPanel, 'hidePanel');
                    $A.util.removeClass(inputPanel, 'showPanel');
                }else{
                    $A.util.addClass(inputPanel, 'showPanel');
                    $A.util.removeClass(inputPanel, 'hidePanel');
                    
                    $A.util.addClass(msgSpan, 'hidePanel');
                    $A.util.removeClass(msgSpan, 'showPanel');
                }
                
            } else {
                console.log('Problem getting account, response state: ' + state);
            }
        });
        $A.enqueueAction(action);
    },
    sendEmail : function(cmp,event) {
        var emailInput = cmp.get("v.personEmail");
        var action = cmp.get("c.sendTokenEmail");
        action.setParams({ accountId : cmp.get("v.recordId"),
                          personEmailAddress : emailInput});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // alert(response.getReturnValue());
                //   cmp.set("v.sendResult", response.getReturnValue());
                
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "type":"success",
                    "message": "Email sent successfully"
                });
                resultsToast.fire();
                
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
            }
            else if (state === "INCOMPLETE") {
                alert("Incomplete Call");
            }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                    
                    var errorToast = $A.get("e.force:showToast");
                    errorToast.setParams({
                        "type":"error",
                        "message": "Email sent failed"
                    });
                    errorToast.fire();
                    
                    var dismissPanel = $A.get("e.force:closeQuickAction");
                    dismissPanel.fire();
                }
        });
        $A.enqueueAction(action);
        
        
    }
})